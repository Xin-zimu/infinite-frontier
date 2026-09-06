class_name BuildingCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/buildings.json"
const REQUIRED_PIECE_IDS := [
	&"wood_floor", &"wood_wall", &"wood_door", &"basic_roof", &"wood_table",
	&"storage_chest", &"placed_torch", &"workbench", &"campfire",
	&"animal_fence",
	&"cooking_pot", &"smelter",
	&"conveyor_belt", &"automatic_smelter", &"storage_link", &"item_sorter",
	&"homestead_beacon",
]
const VALID_CATEGORIES := [&"floor", &"wall", &"door", &"roof", &"furniture", &"chest", &"light", &"station", &"fence", &"automation", &"homestead"]
const VALID_SLOTS := [&"ground", &"structure", &"roof"]
const VALID_INTERACTIONS := [&"", &"door", &"storage"]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _max_placements := 0
var _placement_range_tiles := 0
var _station_radius_tiles := 0
var _heat_radius_tiles := 0
var _chest_slot_count := 0
var _refund_ratio := 0.0
var _pieces: Array[Dictionary] = []
var _pieces_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func max_placements() -> int:
	return _max_placements


func placement_range_tiles() -> int:
	return _placement_range_tiles


func station_radius_tiles() -> int:
	return _station_radius_tiles


func heat_radius_tiles() -> int:
	return _heat_radius_tiles


func chest_slot_count() -> int:
	return _chest_slot_count


func refund_ratio() -> float:
	return _refund_ratio


func piece_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _pieces:
		result.append(StringName(definition["id"]))
	return result


func pieces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in _pieces:
		result.append(definition.duplicate(true))
	return result


func piece(piece_id: StringName) -> Dictionary:
	return (_pieces_by_id.get(String(piece_id), {}) as Dictionary).duplicate(true)


func display_name(piece_id: StringName) -> String:
	return String((_pieces_by_id.get(String(piece_id), {}) as Dictionary).get("display_name", piece_id))


func placement_slot(piece_id: StringName) -> StringName:
	return StringName((_pieces_by_id.get(String(piece_id), {}) as Dictionary).get("placement_slot", ""))


func automation_kind(piece_id: StringName) -> StringName:
	return StringName((_pieces_by_id.get(String(piece_id), {}) as Dictionary).get("automation_kind", ""))


func costs(piece_id: StringName) -> Dictionary:
	return ((_pieces_by_id.get(String(piece_id), {}) as Dictionary).get("costs", {}) as Dictionary).duplicate(true)


func refund_for(piece_id: StringName) -> Dictionary:
	var result := {}
	for item_id_value in costs(piece_id).keys():
		var item_id := String(item_id_value)
		var quantity := int(costs(piece_id)[item_id_value])
		result[item_id] = maxi(1, floori(float(quantity) * _refund_ratio))
	return result


func color(piece_id: StringName) -> Color:
	var html := String((_pieces_by_id.get(String(piece_id), {}) as Dictionary).get("color", "ffffff"))
	return Color(html) if Color.html_is_valid(html) else Color.WHITE


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open building configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Building configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported building schema version in %s" % _config_path)
		return
	_max_placements = int(root.get("max_placements", 0))
	_placement_range_tiles = int(root.get("placement_range_tiles", 0))
	_station_radius_tiles = int(root.get("station_radius_tiles", 0))
	_heat_radius_tiles = int(root.get("heat_radius_tiles", 0))
	_chest_slot_count = int(root.get("chest_slot_count", 0))
	_refund_ratio = float(root.get("refund_ratio", -1.0))
	if _max_placements < 1 or _max_placements > 16384 or _placement_range_tiles < 1 or _placement_range_tiles > 12 \
			or _station_radius_tiles < 1 or _heat_radius_tiles < 1 or _chest_slot_count < 1 or _chest_slot_count > 24 \
			or _refund_ratio <= 0.0 or _refund_ratio > 1.0:
		_fail("Building limits are invalid in %s" % _config_path)
		return
	var item_catalog := ItemCatalog.new()
	for value in root.get("pieces", []) as Array:
		if not value is Dictionary:
			_fail("Building piece entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var piece_id := StringName(definition.get("id", ""))
		var category := StringName(definition.get("category", ""))
		var placement_slot_value := StringName(definition.get("placement_slot", ""))
		var interaction := StringName(definition.get("interactive", ""))
		var costs_value: Variant = definition.get("costs", {})
		if piece_id.is_empty() or _pieces_by_id.has(String(piece_id)) or String(definition.get("display_name", "")).is_empty() \
				or not VALID_CATEGORIES.has(category) or not VALID_SLOTS.has(placement_slot_value) \
				or not VALID_INTERACTIONS.has(interaction) or not Color.html_is_valid(String(definition.get("color", ""))) \
				or not costs_value is Dictionary or (costs_value as Dictionary).is_empty():
			_fail("Building piece definition is invalid: %s" % piece_id)
			return
		for item_id_value in (costs_value as Dictionary).keys():
			var item_id := StringName(item_id_value)
			if not item_catalog.has_item(item_id) or int((costs_value as Dictionary)[item_id_value]) < 1:
				_fail("Building piece %s has invalid cost %s" % [piece_id, item_id])
				return
		var station_kind := StringName(definition.get("station_kind", ""))
		if not station_kind.is_empty() and station_kind not in [&"workbench", &"campfire", &"cooking_pot", &"smelter"]:
			_fail("Building piece %s has invalid station kind" % piece_id)
			return
		var processor := bool(definition.get("processor", false))
		var fuel_capacity := int(definition.get("fuel_capacity", 0))
		if processor != (station_kind in [&"cooking_pot", &"smelter"]) or (processor and (fuel_capacity < 1 or fuel_capacity > 999)) \
				or (not processor and definition.has("fuel_capacity")):
			_fail("Building piece %s has invalid processor configuration" % piece_id)
			return
		var automation_kind_value := StringName(definition.get("automation_kind", ""))
		var automation_fuel_capacity := int(definition.get("automation_fuel_capacity", 0))
		if automation_kind_value not in [&"", &"transport", &"smelter", &"storage_link", &"sorter"] \
				or (category == &"automation") != (not automation_kind_value.is_empty()) \
				or (automation_kind_value == &"smelter" and (automation_fuel_capacity < 1 or automation_fuel_capacity > 999)) \
				or (automation_kind_value != &"smelter" and definition.has("automation_fuel_capacity")):
			_fail("Building piece %s has invalid automation configuration" % piece_id)
			return
		if interaction == &"door" and category != &"door":
			_fail("Only a door piece can use the door interaction")
			return
		if interaction == &"storage" and category != &"chest":
			_fail("Only a chest piece can use the storage interaction")
			return
		_pieces.append(definition)
		_pieces_by_id[String(piece_id)] = definition
	for required_id in REQUIRED_PIECE_IDS:
		if not _pieces_by_id.has(String(required_id)):
			_fail("Required building piece is missing: %s" % required_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
