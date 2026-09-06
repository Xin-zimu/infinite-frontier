class_name AutomationCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/automation.json"
const REQUIRED_MACHINE_PIECES := [&"conveyor_belt", &"automatic_smelter", &"storage_link", &"item_sorter"]

var _valid := false
var _error_message := ""
var _tick_seconds := 0.0
var _connection_span_tiles := 0
var _max_machines := 0
var _max_operations_per_advance := 0
var _max_offline_ticks := 0
var _machines: Array[Dictionary] = []
var _machines_by_piece: Dictionary = {}
var _automatic_recipe_ids: Array[StringName] = []
var _sortable_item_ids: Array[StringName] = []


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_load_config(config_path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func tick_seconds() -> float:
	return _tick_seconds


func connection_span_tiles() -> int:
	return _connection_span_tiles


func max_machines() -> int:
	return _max_machines


func max_operations_per_advance() -> int:
	return _max_operations_per_advance


func max_offline_ticks() -> int:
	return _max_offline_ticks


func machine_piece_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _machines:
		result.append(StringName(definition["piece_id"]))
	return result


func machine(piece_id: StringName) -> Dictionary:
	return (_machines_by_piece.get(String(piece_id), {}) as Dictionary).duplicate(true)


func automatic_recipe_ids() -> Array[StringName]:
	return _automatic_recipe_ids.duplicate()


func sortable_item_ids() -> Array[StringName]:
	return _sortable_item_ids.duplicate()


func _load_config(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open automation configuration %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Automation configuration is not a JSON object: %s" % path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported automation schema version in %s" % path)
		return
	_tick_seconds = float(root.get("tick_seconds", 0.0))
	_connection_span_tiles = int(root.get("connection_span_tiles", 0))
	_max_machines = int(root.get("max_machines", 0))
	_max_operations_per_advance = int(root.get("max_operations_per_advance", 0))
	_max_offline_ticks = int(root.get("max_offline_ticks", 0))
	if _tick_seconds < 0.25 or _tick_seconds > 60.0 or _connection_span_tiles < 1 or _connection_span_tiles > 32 \
			or _max_machines < 1 or _max_machines > 1024 or _max_operations_per_advance < 1 \
			or _max_operations_per_advance > 1024 or _max_offline_ticks < 1 or _max_offline_ticks > 10000:
		_fail("Automation limits are invalid in %s" % path)
		return
	var building_catalog := BuildingCatalog.new()
	var processing_catalog := ProcessingCatalog.new()
	var item_catalog := ItemCatalog.new()
	for value in root.get("machine_definitions", []) as Array:
		if not value is Dictionary:
			_fail("Automation machine entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var piece_id := StringName(definition.get("piece_id", ""))
		var kind := StringName(definition.get("kind", ""))
		if piece_id.is_empty() or _machines_by_piece.has(String(piece_id)) or kind not in [&"transport", &"smelter", &"storage_link", &"sorter"] \
				or building_catalog.automation_kind(piece_id) != kind or String(definition.get("display_name", "")).is_empty() \
				or int(definition.get("throughput", 0)) < 1 or int(definition.get("throughput", 0)) > 16:
			_fail("Automation machine definition is invalid: %s" % piece_id)
			return
		_machines.append(definition)
		_machines_by_piece[String(piece_id)] = definition
	for piece_id in REQUIRED_MACHINE_PIECES:
		if not _machines_by_piece.has(String(piece_id)):
			_fail("Required automation machine is missing: %s" % piece_id)
			return
	for recipe_id_value in root.get("automatic_recipe_ids", []) as Array:
		var recipe_id := StringName(recipe_id_value)
		var recipe := processing_catalog.recipe(recipe_id)
		if recipe.is_empty() or StringName(recipe.get("station", "")) != &"smelter" or _automatic_recipe_ids.has(recipe_id):
			_fail("Automatic processing recipe is invalid: %s" % recipe_id)
			return
		_automatic_recipe_ids.append(recipe_id)
	for item_id_value in root.get("sortable_item_ids", []) as Array:
		var item_id := StringName(item_id_value)
		if not item_catalog.has_item(item_id) or _sortable_item_ids.has(item_id):
			_fail("Sortable automation item is invalid: %s" % item_id)
			return
		_sortable_item_ids.append(item_id)
	if _automatic_recipe_ids.is_empty() or _sortable_item_ids.is_empty():
		_fail("Automation requires recipes and sorter filters")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
