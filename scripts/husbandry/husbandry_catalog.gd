class_name HusbandryCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/husbandry.json"
const REQUIRED_ANIMAL_IDS := [&"chicken", &"cow", &"sheep"]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _limits := {}
var _sleep_phases: Array[StringName] = []
var _animals: Array[Dictionary] = []
var _animals_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func max_interacted_animals() -> int:
	return int(_limits.get("max_interacted_animals", 0))


func interaction_range_tiles() -> int:
	return int(_limits.get("interaction_range_tiles", 0))


func breeding_range_tiles() -> int:
	return int(_limits.get("breeding_range_tiles", 0))


func fence_radius_tiles() -> int:
	return int(_limits.get("fence_radius_tiles", 0))


func feed_reserve_days() -> int:
	return int(_limits.get("feed_reserve_days", 0))


func max_ready_products() -> int:
	return int(_limits.get("max_ready_products", 0))


func wild_cell_size() -> int:
	return int(_limits.get("wild_cell_size", 0))


func wild_spawn_percent() -> int:
	return int(_limits.get("wild_spawn_percent", 0))


func is_sleep_phase(phase: StringName) -> bool:
	return _sleep_phases.has(phase)


func animal_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _animals:
		result.append(StringName(definition["id"]))
	return result


func animals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in _animals:
		result.append(definition.duplicate(true))
	return result


func animal(animal_id: StringName) -> Dictionary:
	return (_animals_by_id.get(String(animal_id), {}) as Dictionary).duplicate(true)


func display_name(animal_id: StringName) -> String:
	return String((_animals_by_id.get(String(animal_id), {}) as Dictionary).get("display_name", animal_id))


func color(animal_id: StringName) -> Color:
	var html := String((_animals_by_id.get(String(animal_id), {}) as Dictionary).get("color", "ffffff"))
	return Color(html) if Color.html_is_valid(html) else Color.WHITE


func species_for_biome(biome_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _animals:
		if (definition.get("biomes", []) as Array).has(String(biome_id)):
			result.append(StringName(definition["id"]))
	return result


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open husbandry configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Husbandry configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported husbandry schema version in %s" % _config_path)
		return
	for key in ["max_interacted_animals", "interaction_range_tiles", "breeding_range_tiles", "fence_radius_tiles", "feed_reserve_days", "max_ready_products", "wild_cell_size", "wild_spawn_percent"]:
		_limits[key] = int(root.get(key, 0))
	if max_interacted_animals() < 1 or max_interacted_animals() > 4096 \
			or interaction_range_tiles() < 1 or interaction_range_tiles() > 12 \
			or breeding_range_tiles() < 1 or breeding_range_tiles() > 12 \
			or fence_radius_tiles() < 1 or fence_radius_tiles() > 12 \
			or feed_reserve_days() < 1 or feed_reserve_days() > 30 \
			or max_ready_products() < 1 or max_ready_products() > 99 \
			or wild_cell_size() < 8 or wild_cell_size() > 32 \
			or WorldCoordinates.CHUNK_SIZE % wild_cell_size() != 0 \
			or wild_spawn_percent() < 1 or wild_spawn_percent() > 100:
		_fail("Husbandry limits are invalid in %s" % _config_path)
		return
	for value in root.get("sleep_phases", []) as Array:
		var phase := StringName(value)
		if phase not in [&"DAWN", &"DAY", &"DUSK", &"NIGHT"] or _sleep_phases.has(phase):
			_fail("Husbandry sleep phase is invalid: %s" % phase)
			return
		_sleep_phases.append(phase)
	if _sleep_phases.is_empty():
		_fail("At least one animal sleep phase is required")
		return
	var item_catalog := ItemCatalog.new()
	var biome_catalog := BiomeCatalog.new()
	for value in root.get("animals", []) as Array:
		if not value is Dictionary:
			_fail("Husbandry animal entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var animal_id := StringName(definition.get("id", ""))
		var feed_id := StringName(definition.get("feed_item_id", ""))
		var product_id := StringName(definition.get("product_item_id", ""))
		var biomes_value: Variant = definition.get("biomes", [])
		if animal_id.is_empty() or _animals_by_id.has(String(animal_id)) \
				or String(definition.get("display_name", "")).is_empty() \
				or not item_catalog.has_item(feed_id) or not item_catalog.has_item(product_id) \
				or int(definition.get("tame_feed_count", 0)) < 1 \
				or int(definition.get("breed_friendship", 0)) < int(definition.get("tame_feed_count", 0)) \
				or int(definition.get("adult_days", 0)) < 1 \
				or int(definition.get("breeding_cooldown_days", 0)) < 1 \
				or int(definition.get("product_quantity", 0)) < 1 \
				or int(definition.get("product_interval_days", 0)) < 1 \
				or not Color.html_is_valid(String(definition.get("color", ""))) \
				or not biomes_value is Array or (biomes_value as Array).is_empty():
			_fail("Husbandry animal definition is invalid: %s" % animal_id)
			return
		for biome_value in biomes_value as Array:
			if not biome_catalog.has_biome(StringName(biome_value)):
				_fail("Animal %s references an unknown biome" % animal_id)
				return
		_animals.append(definition)
		_animals_by_id[String(animal_id)] = definition
	for required_id in REQUIRED_ANIMAL_IDS:
		if not _animals_by_id.has(String(required_id)):
			_fail("Required husbandry animal is missing: %s" % required_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
