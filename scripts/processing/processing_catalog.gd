class_name ProcessingCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/processing.json"
const REQUIRED_STATIONS := [&"cooking_pot", &"smelter"]
const REQUIRED_RECIPES := [
	&"vegetable_stew", &"apple_pie", &"hearty_breakfast",
	&"antidote_potion", &"warming_tonic", &"cooling_tonic",
	&"copper_ingot", &"iron_ingot", &"steel_ingot", &"tempered_plate",
]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _interaction_radius_tiles := 0
var _stations: Array[Dictionary] = []
var _stations_by_id: Dictionary = {}
var _fuels: Array[Dictionary] = []
var _fuels_by_item: Dictionary = {}
var _recipes: Array[Dictionary] = []
var _recipes_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func interaction_radius_tiles() -> int:
	return _interaction_radius_tiles


func station_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _stations:
		result.append(StringName(definition["id"]))
	return result


func station_display_name(station_id: StringName) -> String:
	return String((_stations_by_id.get(String(station_id), {}) as Dictionary).get("display_name", station_id))


func fuel_item_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _fuels:
		result.append(StringName(definition["item_id"]))
	return result


func fuel_units(item_id: StringName) -> int:
	return int((_fuels_by_item.get(String(item_id), {}) as Dictionary).get("fuel_units", 0))


func fuels() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in _fuels:
		result.append(definition.duplicate(true))
	return result


func recipes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in _recipes:
		result.append(definition.duplicate(true))
	return result


func recipe(recipe_id: StringName) -> Dictionary:
	return (_recipes_by_id.get(String(recipe_id), {}) as Dictionary).duplicate(true)


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open processing configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Processing configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported processing schema version in %s" % _config_path)
		return
	_interaction_radius_tiles = int(root.get("interaction_radius_tiles", 0))
	if _interaction_radius_tiles < 1 or _interaction_radius_tiles > 12:
		_fail("Processing interaction radius is invalid")
		return
	var item_catalog := ItemCatalog.new()
	for value in root.get("stations", []) as Array:
		if not value is Dictionary:
			_fail("Processing station entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var station_id := StringName(definition.get("id", ""))
		if station_id.is_empty() or _stations_by_id.has(String(station_id)) or String(definition.get("display_name", "")).is_empty():
			_fail("Processing station definition is invalid: %s" % station_id)
			return
		_stations.append(definition)
		_stations_by_id[String(station_id)] = definition
	for station_id in REQUIRED_STATIONS:
		if not _stations_by_id.has(String(station_id)):
			_fail("Required processing station is missing: %s" % station_id)
			return
	for value in root.get("fuels", []) as Array:
		if not value is Dictionary:
			_fail("Processing fuel entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var item_id := StringName(definition.get("item_id", ""))
		if item_id.is_empty() or _fuels_by_item.has(String(item_id)) or not item_catalog.has_item(item_id) \
				or String(definition.get("display_name", "")).is_empty() or int(definition.get("fuel_units", 0)) < 1:
			_fail("Processing fuel definition is invalid: %s" % item_id)
			return
		_fuels.append(definition)
		_fuels_by_item[String(item_id)] = definition
	if _fuels.is_empty():
		_fail("Processing requires at least one fuel")
		return
	for value in root.get("recipes", []) as Array:
		if not value is Dictionary:
			_fail("Processing recipe entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var recipe_id := StringName(definition.get("id", ""))
		var station_id := StringName(definition.get("station", ""))
		var inputs_value: Variant = definition.get("inputs", {})
		var output_value: Variant = definition.get("output", {})
		if recipe_id.is_empty() or _recipes_by_id.has(String(recipe_id)) or String(definition.get("display_name", "")).is_empty() \
				or not _stations_by_id.has(String(station_id)) or int(definition.get("fuel_cost", 0)) < 1 \
				or not inputs_value is Dictionary or (inputs_value as Dictionary).size() < 1 \
				or not output_value is Dictionary:
			_fail("Processing recipe definition is invalid: %s" % recipe_id)
			return
		for input_id_value in (inputs_value as Dictionary).keys():
			var input_id := StringName(input_id_value)
			if not item_catalog.has_item(input_id) or int((inputs_value as Dictionary)[input_id_value]) < 1:
				_fail("Processing recipe %s has invalid input %s" % [recipe_id, input_id])
				return
		var output := output_value as Dictionary
		var output_id := StringName(output.get("item_id", ""))
		if not item_catalog.has_item(output_id) or int(output.get("quantity", 0)) < 1:
			_fail("Processing recipe %s has an invalid output" % recipe_id)
			return
		_recipes.append(definition)
		_recipes_by_id[String(recipe_id)] = definition
	for recipe_id in REQUIRED_RECIPES:
		if not _recipes_by_id.has(String(recipe_id)):
			_fail("Required processing recipe is missing: %s" % recipe_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
