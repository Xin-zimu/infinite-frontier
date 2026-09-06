class_name WorldEventCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/world_events.json"
const REQUIRED_IDS := [
	&"caravan_passage",
	&"village_raid",
	&"meteor_fall",
	&"resource_surge",
	&"blizzard",
	&"ruin_opening",
	&"temporary_boss",
	&"rescue_operation",
]
const OBJECTIVE_TYPES := [&"trade", &"defeat", &"harvest", &"survive", &"explore", &"defeat_boss", &"talk"]
const CATEGORIES := [&"civilian", &"combat", &"exploration", &"resource", &"weather", &"boss"]

var _valid := false
var _error_message := ""
var _config: Dictionary = {}
var _events: Dictionary = {}
var _event_order: Array[StringName] = []


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func day_seconds() -> float:
	return float(_config.get("day_seconds", 1200.0))


func first_event_seconds() -> float:
	return float(_config.get("first_event_seconds", 90.0))


func event_interval_seconds() -> float:
	return float(_config.get("event_interval_seconds", 300.0))


func timetable_horizon() -> int:
	return int(_config.get("timetable_horizon", 6))


func maximum_active() -> int:
	return int(_config.get("maximum_active", 1))


func history_limit() -> int:
	return int(_config.get("history_limit", 48))


func event_ids() -> Array[StringName]:
	return _event_order.duplicate()


func has_event(event_id: StringName) -> bool:
	return _events.has(String(event_id))


func event(event_id: StringName) -> Dictionary:
	return (_events.get(String(event_id), {}) as Dictionary).duplicate(true)


func objective(event_id: StringName) -> Dictionary:
	return (event(event_id).get("objective", {}) as Dictionary).duplicate(true)


func effect(event_id: StringName, key: StringName, fallback: Variant) -> Variant:
	return (event(event_id).get("effects", {}) as Dictionary).get(String(key), fallback)


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open world-event configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("World-event configuration is not an object")
		return
	_config = (parsed as Dictionary).duplicate(true)
	if int(_config.get("schema_version", 0)) != 1 \
			or day_seconds() <= 0.0 or first_event_seconds() < 0.0 \
			or event_interval_seconds() < 60.0 \
			or timetable_horizon() < 1 or timetable_horizon() > 16 \
			or maximum_active() < 1 or maximum_active() > 4 \
			or history_limit() < 8 or history_limit() > 128:
		_fail("World-event schedule bounds or schema are invalid")
		return
	var event_values: Variant = _config.get("events", [])
	if not event_values is Array or (event_values as Array).size() != REQUIRED_IDS.size():
		_fail("World-event catalog must contain exactly eight required events")
		return
	for value in event_values as Array:
		if not value is Dictionary:
			_fail("World-event definitions must be objects")
			return
		var definition := (value as Dictionary).duplicate(true)
		var event_id := StringName(definition.get("id", ""))
		var event_key := String(event_id)
		var duration := float(definition.get("duration_seconds", 0.0))
		var category := StringName(definition.get("category", ""))
		if event_id not in REQUIRED_IDS or _events.has(event_key) \
				or String(definition.get("display_name", "")).is_empty() \
				or String(definition.get("description", "")).is_empty() \
				or category not in CATEGORIES or duration <= 0.0 \
				or duration > event_interval_seconds() * float(maximum_active()):
			_fail("World-event identity, category or duration is invalid")
			return
		if not _validate_objective(definition.get("objective", {})) \
				or not _validate_effects(definition.get("effects", {})):
			return
		_events[event_key] = definition
		_event_order.append(event_id)
	for required_id in REQUIRED_IDS:
		if not _events.has(String(required_id)):
			_fail("Required world event %s is missing" % required_id)
			return
	_valid = true


func _validate_objective(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("World-event objective must be an object")
	var objective_value := value as Dictionary
	var objective_type := StringName(objective_value.get("type", ""))
	var target_id := String(objective_value.get("target_id", "")).strip_edges()
	var quantity := int(objective_value.get("quantity", 0))
	if objective_type not in OBJECTIVE_TYPES or target_id.is_empty() \
			or quantity < 1 or quantity > 99 \
			or String(objective_value.get("display_name", "")).is_empty():
		return _fail("World-event objective fields are invalid")
	return true


func _validate_effects(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("World-event effects must be an object")
	var effects := value as Dictionary
	for multiplier_key in ["enemy_population_multiplier", "resource_yield_multiplier"]:
		var amount := float(effects.get(multiplier_key, 0.0))
		if amount < 0.25 or amount > 3.0:
			return _fail("World-event effect multiplier is outside supported bounds")
	var weather_id := StringName(effects.get("weather_override", ""))
	if not weather_id.is_empty() and WeatherCatalog.new().definition(weather_id) == null:
		return _fail("World-event weather override is unknown")
	return true


func _fail(message: String) -> bool:
	_error_message = message
	push_error(message)
	return false
