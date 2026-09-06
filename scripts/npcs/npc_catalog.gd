class_name NpcCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/npcs.json"
const VALID_SERVICES := ["dialogue", "shop", "sleep"]
const VALID_LOCATIONS := ["home", "center", "shop", "well", "campfire", "outskirts"]
const PHASES := ["DAWN", "DAY", "DUSK", "NIGHT"]

var _valid := false
var _error_message := ""
var _active_radius_tiles := 128
var _interaction_radius_pixels := 82.0
var _movement_speed_pixels := 54.0
var _roles: Dictionary = {}
var _role_order: Array[StringName] = []
var _item_catalog := ItemCatalog.new()


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func active_radius_tiles() -> int:
	return _active_radius_tiles


func interaction_radius_pixels() -> float:
	return _interaction_radius_pixels


func movement_speed_pixels() -> float:
	return _movement_speed_pixels


func role_ids() -> Array[StringName]:
	return _role_order.duplicate()


func role(role_id: StringName) -> Dictionary:
	return (_roles.get(String(role_id), {}) as Dictionary).duplicate(true)


func role_exists(role_id: StringName) -> bool:
	return _roles.has(String(role_id))


func schedule_at(role_id: StringName, day_progress: float) -> Dictionary:
	var definition := _roles.get(String(role_id), {}) as Dictionary
	var progress := clampf(day_progress, 0.0, 0.999999)
	for value in definition.get("schedule", []) as Array:
		var entry := value as Dictionary
		if progress >= float(entry["from"]) and progress < float(entry["to"]):
			return entry.duplicate(true)
	return {}


func dialogue(role_id: StringName, phase: StringName, index: int) -> String:
	var definition := _roles.get(String(role_id), {}) as Dictionary
	var dialogues := definition.get("dialogues", {}) as Dictionary
	var lines := dialogues.get(String(phase), []) as Array
	if lines.is_empty():
		lines = dialogues.get("DAY", []) as Array
	return String(lines[posmod(index, lines.size())]) if not lines.is_empty() else "……"


func has_service(role_id: StringName, service: StringName) -> bool:
	var definition := _roles.get(String(role_id), {}) as Dictionary
	return (definition.get("services", []) as Array).has(String(service))


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open NPC configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("NPC configuration is not an object")
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported NPC schema version")
		return
	_active_radius_tiles = int(root.get("active_radius_tiles", 0))
	_interaction_radius_pixels = float(root.get("interaction_radius_pixels", 0.0))
	_movement_speed_pixels = float(root.get("movement_speed_pixels", 0.0))
	if _active_radius_tiles < 32 or _interaction_radius_pixels < 32.0 or _movement_speed_pixels <= 0.0:
		_fail("NPC range or movement configuration is invalid")
		return
	for value in root.get("roles", []) as Array:
		if not value is Dictionary or not _validate_role(value as Dictionary):
			return
		var definition := (value as Dictionary).duplicate(true)
		var role_id := String(definition["id"])
		_roles[role_id] = definition
		_role_order.append(StringName(role_id))
	for required in ["elder", "merchant", "innkeeper", "farmer", "guard", "explorer"]:
		if not _roles.has(required):
			_fail("NPC configuration is missing role %s" % required)
			return
	_valid = true


func _validate_role(definition: Dictionary) -> bool:
	var role_id := String(definition.get("id", ""))
	if role_id.is_empty() or _roles.has(role_id) or String(definition.get("display_name", "")).is_empty():
		return _fail("NPC role IDs and display names must be unique")
	var names := definition.get("names", []) as Array
	if names.is_empty():
		return _fail("NPC role %s requires at least one name" % role_id)
	for service in definition.get("services", []) as Array:
		if not VALID_SERVICES.has(String(service)):
			return _fail("NPC role %s contains an invalid service" % role_id)
	var dialogues := definition.get("dialogues", {}) as Dictionary
	for phase in PHASES:
		if not dialogues.get(phase, []) is Array or (dialogues.get(phase, []) as Array).is_empty():
			return _fail("NPC role %s is missing dialogue phase %s" % [role_id, phase])
	var schedule := definition.get("schedule", []) as Array
	if schedule.is_empty():
		return _fail("NPC role %s has no schedule" % role_id)
	var cursor := 0.0
	for value in schedule:
		if not value is Dictionary:
			return _fail("NPC schedule entries must be objects")
		var entry := value as Dictionary
		var from := float(entry.get("from", -1.0))
		var to := float(entry.get("to", -1.0))
		if not is_equal_approx(from, cursor) or to <= from or to > 1.0 \
				or String(entry.get("activity", "")).is_empty() \
				or String(entry.get("activity_display", "")).is_empty() \
				or not VALID_LOCATIONS.has(String(entry.get("location", ""))):
			return _fail("NPC role %s has a discontinuous or invalid schedule" % role_id)
		cursor = to
	if not is_equal_approx(cursor, 1.0):
		return _fail("NPC role %s schedule must cover one complete day" % role_id)
	for key in ["offers", "buys"]:
		for value in definition.get(key, []) as Array:
			if not value is Dictionary:
				return _fail("NPC trade entries must be objects")
			var trade := value as Dictionary
			if not _item_catalog.has_item(StringName(trade.get("item_id", ""))) \
					or int(trade.get("quantity", 0)) < 1 or int(trade.get("price", 0)) < 1:
				return _fail("NPC role %s has an invalid trade entry" % role_id)
	return true


func _fail(message: String) -> bool:
	_valid = false
	_error_message = message
	push_error(message)
	return false
