class_name FarmingCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/farming.json"
const REQUIRED_CROP_IDS := [&"wheat", &"carrot", &"tomato", &"apple_tree"]
const VALID_QUALITY_IDS := [&"normal", &"silver", &"gold"]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _max_plots := 0
var _interaction_range_tiles := 0
var _dry_growth_multiplier := 0.0
var _weather_multipliers := {}
var _crops: Array[Dictionary] = []
var _crops_by_id: Dictionary = {}
var _fertilizers: Array[Dictionary] = []
var _fertilizers_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func max_plots() -> int:
	return _max_plots


func interaction_range_tiles() -> int:
	return _interaction_range_tiles


func dry_growth_multiplier() -> float:
	return _dry_growth_multiplier


func weather_growth_multiplier(weather_id: StringName) -> float:
	return float(_weather_multipliers.get(String(weather_id), 1.0))


func crop_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _crops:
		result.append(StringName(definition["id"]))
	return result


func crops() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in _crops:
		result.append(definition.duplicate(true))
	return result


func crop(crop_id: StringName) -> Dictionary:
	return (_crops_by_id.get(String(crop_id), {}) as Dictionary).duplicate(true)


func crop_display_name(crop_id: StringName) -> String:
	return String((_crops_by_id.get(String(crop_id), {}) as Dictionary).get("display_name", crop_id))


func crop_color(crop_id: StringName) -> Color:
	var html := String((_crops_by_id.get(String(crop_id), {}) as Dictionary).get("color", "ffffff"))
	return Color(html) if Color.html_is_valid(html) else Color.WHITE


func fertilizer_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _fertilizers:
		result.append(StringName(definition["id"]))
	return result


func fertilizer(fertilizer_id: StringName) -> Dictionary:
	return (_fertilizers_by_id.get(String(fertilizer_id), {}) as Dictionary).duplicate(true)


func quality_output(crop_id: StringName, quality_id: StringName) -> StringName:
	var outputs := crop(crop_id).get("quality_outputs", {}) as Dictionary
	return StringName(outputs.get(String(quality_id), outputs.get("normal", "")))


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open farming configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Farming configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported farming schema version in %s" % _config_path)
		return
	_max_plots = int(root.get("max_plots", 0))
	_interaction_range_tiles = int(root.get("interaction_range_tiles", 0))
	_dry_growth_multiplier = float(root.get("dry_growth_multiplier", -1.0))
	_weather_multipliers = {
		"CLEAR": 1.0,
		"RAIN": float(root.get("rain_growth_multiplier", 0.0)),
		"SNOW": float(root.get("snow_growth_multiplier", 0.0)),
		"SANDSTORM": float(root.get("sandstorm_growth_multiplier", 0.0)),
	}
	if _max_plots < 1 or _max_plots > 16384 or _interaction_range_tiles < 1 or _interaction_range_tiles > 12 \
			or _dry_growth_multiplier <= 0.0 or _dry_growth_multiplier > 1.0:
		_fail("Farming limits are invalid in %s" % _config_path)
		return
	for multiplier in _weather_multipliers.values():
		if float(multiplier) <= 0.0 or float(multiplier) > 3.0:
			_fail("Farming weather multiplier is invalid in %s" % _config_path)
			return
	var item_catalog := ItemCatalog.new()
	for value in root.get("fertilizers", []) as Array:
		if not value is Dictionary:
			_fail("Fertilizer entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var fertilizer_id := StringName(definition.get("id", ""))
		if fertilizer_id.is_empty() or _fertilizers_by_id.has(String(fertilizer_id)) \
				or not item_catalog.has_item(fertilizer_id) or String(definition.get("display_name", "")).is_empty() \
				or int(definition.get("quality_bonus", -1)) < 0 or int(definition.get("quality_bonus", 0)) > 100 \
				or float(definition.get("growth_bonus", -1.0)) < 0.0 or float(definition.get("growth_bonus", 0.0)) > 2.0:
			_fail("Fertilizer definition is invalid: %s" % fertilizer_id)
			return
		_fertilizers.append(definition)
		_fertilizers_by_id[String(fertilizer_id)] = definition
	for value in root.get("crops", []) as Array:
		if not value is Dictionary:
			_fail("Crop entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var crop_id := StringName(definition.get("id", ""))
		var seed_item_id := StringName(definition.get("seed_item_id", ""))
		var outputs_value: Variant = definition.get("quality_outputs", {})
		if crop_id.is_empty() or _crops_by_id.has(String(crop_id)) or String(definition.get("display_name", "")).is_empty() \
				or not item_catalog.has_item(seed_item_id) or int(definition.get("days_to_mature", 0)) < 1 \
				or int(definition.get("stage_count", 0)) < 2 or int(definition.get("stage_count", 0)) > 8 \
				or int(definition.get("yield_min", 0)) < 1 or int(definition.get("yield_max", 0)) < int(definition.get("yield_min", 0)) \
				or int(definition.get("regrow_days", -1)) < 0 or not Color.html_is_valid(String(definition.get("color", ""))) \
				or not outputs_value is Dictionary:
			_fail("Crop definition is invalid: %s" % crop_id)
			return
		for quality_id in VALID_QUALITY_IDS:
			var output_id := StringName((outputs_value as Dictionary).get(String(quality_id), ""))
			if not item_catalog.has_item(output_id):
				_fail("Crop %s has invalid %s quality output" % [crop_id, quality_id])
				return
		_crops.append(definition)
		_crops_by_id[String(crop_id)] = definition
	for required_id in REQUIRED_CROP_IDS:
		if not _crops_by_id.has(String(required_id)):
			_fail("Required crop is missing: %s" % required_id)
			return
	if _fertilizers.is_empty():
		_fail("At least one fertilizer is required")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
