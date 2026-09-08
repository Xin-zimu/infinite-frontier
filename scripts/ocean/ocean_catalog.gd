class_name OceanCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/ocean.json"

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _shallow_multiplier := 1.0
var _deep_multiplier := 1.0
var _swim_stamina_drain := 0.0
var _boats: Array[Dictionary] = []
var _boats_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH, item_catalog: ItemCatalog = null) -> void:
	_config_path = config_path
	_load_config(item_catalog if item_catalog != null else ItemCatalog.new())


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func shallow_water_multiplier() -> float:
	return _shallow_multiplier


func deep_water_multiplier() -> float:
	return _deep_multiplier


func swim_stamina_drain() -> float:
	return _swim_stamina_drain


func boat_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _boats:
		result.append(StringName((definition as Dictionary)["id"]))
	result.sort()
	return result


func boat(boat_id: StringName) -> Dictionary:
	return (_boats_by_id.get(String(boat_id), {}) as Dictionary).duplicate(true)


func boat_for_item(item_id: StringName) -> Dictionary:
	for definition_value in _boats:
		var definition := definition_value as Dictionary
		if String(definition.get("item_id", "")) == String(item_id):
			return definition.duplicate(true)
	return {}


func _load_config(item_catalog: ItemCatalog) -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open ocean configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Ocean configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported ocean schema version in %s" % _config_path)
		return
	var swimming := root.get("swimming", {}) as Dictionary
	if swimming.is_empty():
		_fail("Ocean swimming section is missing in %s" % _config_path)
		return
	_shallow_multiplier = float(swimming.get("shallow_water_multiplier", -1.0))
	_deep_multiplier = float(swimming.get("deep_water_multiplier", -1.0))
	_swim_stamina_drain = float(swimming.get("stamina_drain_per_second", -1.0))
	if _shallow_multiplier <= 0.0 or _shallow_multiplier >= 1.0 \
			or _deep_multiplier <= 0.0 or _deep_multiplier >= _shallow_multiplier \
			or _swim_stamina_drain <= 0.0:
		_fail("Ocean swimming values are invalid in %s" % _config_path)
		return
	var boats := root.get("boats", []) as Array
	if boats.is_empty():
		_fail("Ocean boat list must not be empty in %s" % _config_path)
		return
	for value in boats:
		if not value is Dictionary:
			_fail("Ocean boat entry must be an object in %s" % _config_path)
			return
		var definition := (value as Dictionary).duplicate(true)
		var boat_id := String(definition.get("id", ""))
		var item_id := StringName(definition.get("item_id", ""))
		var speed := float(definition.get("speed_multiplier", -1.0))
		var maximum := int(definition.get("maximum_count", -1))
		var deploy_range := int(definition.get("deploy_range_tiles", -1))
		var item := item_catalog.item(item_id)
		if boat_id.is_empty() or _boats_by_id.has(boat_id) or item == null \
				or speed <= 1.0 or speed > 3.0 or maximum < 1 or maximum > 64 \
				or deploy_range < 1 or deploy_range > 6 \
				or String(definition.get("display_name", "")).is_empty():
			_fail("Ocean boat definition is invalid: %s" % boat_id)
			return
		_boats_by_id[boat_id] = definition
		_boats.append(definition)
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
