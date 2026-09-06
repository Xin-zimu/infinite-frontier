class_name WorldEventState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _next_slot := 0
var _active: Dictionary = {}
var _history: Array[Dictionary] = []


func next_slot() -> int:
	return _next_slot


func active_count() -> int:
	return _active.size()


func history_count() -> int:
	return _history.size()


func active_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _active.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["start_seconds"]) < float(b["start_seconds"])
	)
	return result


func history_records() -> Array[Dictionary]:
	return _history.duplicate(true)


func advance(total_seconds: float, current_chunk: Vector2i, planner: WorldEventPlanner, catalog: WorldEventCatalog) -> Dictionary:
	var now := maxf(0.0, total_seconds)
	var started: Array[Dictionary] = []
	var finished: Array[Dictionary] = []
	for instance_id_value in _active.keys():
		var instance_id := String(instance_id_value)
		var record := _active[instance_id] as Dictionary
		if now < float(record["end_seconds"]):
			continue
		var objective := catalog.objective(StringName(record["event_id"]))
		var status := &"completed" if StringName(objective.get("type", "")) == &"survive" else &"expired"
		if status == &"completed":
			record["progress"] = int(record["goal"])
		finished.append(_finish(instance_id, status, now, catalog))
	var last_due_slot := planner.slot_at_or_before(now)
	var retained_start := maxi(0, last_due_slot - catalog.history_limit() + 1)
	if _next_slot < retained_start:
		_next_slot = retained_start
	while _next_slot <= last_due_slot:
		var plan := planner.plan_for_slot(_next_slot)
		_next_slot += 1
		if plan.is_empty():
			continue
		var record := _record_from_plan(plan, current_chunk, catalog)
		if float(record["end_seconds"]) <= now:
			record["status"] = "expired"
			record["resolved_seconds"] = now
			_append_history(record, catalog)
			finished.append(record.duplicate(true))
			continue
		if _active.size() >= catalog.maximum_active():
			var oldest := active_records()[0]
			finished.append(_finish(String(oldest["instance_id"]), &"expired", now, catalog))
		_active[String(record["instance_id"])] = record
		started.append(record.duplicate(true))
	return {"changed": not started.is_empty() or not finished.is_empty(), "started": started, "finished": finished}


func record_event(action: StringName, target_id: StringName, quantity: int, total_seconds: float, catalog: WorldEventCatalog) -> Dictionary:
	if quantity <= 0:
		return {"changed": false, "completed": []}
	var completed: Array[Dictionary] = []
	var changed := false
	for record_value in active_records():
		var record := record_value as Dictionary
		var objective := catalog.objective(StringName(record["event_id"]))
		if StringName(objective.get("type", "")) != action:
			continue
		var required_target := String(objective.get("target_id", ""))
		if required_target != "*" and required_target != String(target_id):
			continue
		var instance_id := String(record["instance_id"])
		var stored := _active[instance_id] as Dictionary
		stored["progress"] = mini(int(stored["goal"]), int(stored["progress"]) + quantity)
		changed = true
		if int(stored["progress"]) >= int(stored["goal"]):
			completed.append(_finish(instance_id, &"completed", total_seconds, catalog))
	return {"changed": changed, "completed": completed}


func effect_multiplier(key: StringName, catalog: WorldEventCatalog) -> float:
	var result := 1.0
	for record in _active.values():
		result *= float(catalog.effect(StringName((record as Dictionary)["event_id"]), key, 1.0))
	return clampf(result, 0.25, 4.0)


func weather_override(catalog: WorldEventCatalog) -> StringName:
	for record in active_records():
		var weather_id := StringName(catalog.effect(StringName(record["event_id"]), &"weather_override", ""))
		if not weather_id.is_empty():
			return weather_id
	return &""


func status_snapshot(total_seconds: float, planner: WorldEventPlanner, catalog: WorldEventCatalog) -> Dictionary:
	var now := maxf(0.0, total_seconds)
	var active_views: Array[Dictionary] = []
	for record in active_records():
		active_views.append(_view(record, now, catalog))
	var upcoming: Array[Dictionary] = []
	for plan_value in planner.timetable(_next_slot, catalog.timetable_horizon()):
		var plan := plan_value as Dictionary
		plan["starts_in_seconds"] = maxf(0.0, float(plan["start_seconds"]) - now)
		upcoming.append(plan)
	var history_views: Array[Dictionary] = []
	var first := maxi(0, _history.size() - 8)
	for index in range(_history.size() - 1, first - 1, -1):
		history_views.append(_view(_history[index], now, catalog))
	return {
		"schema_version": SCHEMA_VERSION,
		"active_count": active_views.size(),
		"active": active_views,
		"upcoming": upcoming,
		"history": history_views,
		"history_count": _history.size(),
		"next_slot": _next_slot,
	}


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"next_slot": _next_slot,
		"active": active_records(),
		"history": _history.duplicate(true),
	}


func restore_snapshot(value: Dictionary, catalog := WorldEventCatalog.new()) -> bool:
	last_error = ""
	if not catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION \
			or not value.get("active", []) is Array or not value.get("history", []) is Array:
		return _fail("世界事件存档结构无效")
	var next_value := int(value.get("next_slot", -1))
	var active_values := value["active"] as Array
	var history_values := value["history"] as Array
	if next_value < 0 or active_values.size() > catalog.maximum_active() \
			or history_values.size() > catalog.history_limit():
		return _fail("世界事件存档数量或时间表游标无效")
	var restored_active := {}
	var restored_history: Array[Dictionary] = []
	var seen := {}
	for value_record in active_values:
		var record := _validated_record(value_record, true, catalog)
		if record.is_empty() or seen.has(String(record.get("instance_id", ""))):
			return _fail("活动世界事件记录无效或重复")
		seen[String(record["instance_id"])] = true
		restored_active[String(record["instance_id"])] = record
	for value_record in history_values:
		var record := _validated_record(value_record, false, catalog)
		if record.is_empty() or seen.has(String(record.get("instance_id", ""))):
			return _fail("历史世界事件记录无效或重复")
		seen[String(record["instance_id"])] = true
		restored_history.append(record)
	_next_slot = next_value
	_active = restored_active
	_history = restored_history
	return true


func _record_from_plan(plan: Dictionary, current_chunk: Vector2i, catalog: WorldEventCatalog) -> Dictionary:
	var objective := catalog.objective(StringName(plan["event_id"]))
	return {
		"instance_id": String(plan["instance_id"]),
		"event_id": String(plan["event_id"]),
		"start_seconds": float(plan["start_seconds"]),
		"end_seconds": float(plan["end_seconds"]),
		"target_chunk": [current_chunk.x, current_chunk.y],
		"progress": 0,
		"goal": int(objective["quantity"]),
		"status": "active",
	}


func _finish(instance_id: String, status: StringName, total_seconds: float, catalog: WorldEventCatalog) -> Dictionary:
	if not _active.has(instance_id):
		return {}
	var record := (_active[instance_id] as Dictionary).duplicate(true)
	_active.erase(instance_id)
	record["status"] = String(status)
	record["resolved_seconds"] = maxf(float(record["start_seconds"]), total_seconds)
	_append_history(record, catalog)
	return record.duplicate(true)


func _append_history(record: Dictionary, catalog: WorldEventCatalog) -> void:
	_history.append(record.duplicate(true))
	while _history.size() > catalog.history_limit():
		_history.pop_front()


func _view(record: Dictionary, total_seconds: float, catalog: WorldEventCatalog) -> Dictionary:
	var result := record.duplicate(true)
	var event_id := StringName(record["event_id"])
	var definition := catalog.event(event_id)
	var objective := catalog.objective(event_id)
	result["display_name"] = String(definition.get("display_name", event_id))
	result["description"] = String(definition.get("description", ""))
	result["category"] = String(definition.get("category", ""))
	result["objective_display_name"] = String(objective.get("display_name", ""))
	result["seconds_remaining"] = maxf(0.0, float(record["end_seconds"]) - total_seconds)
	return result


func _validated_record(value: Variant, active: bool, catalog: WorldEventCatalog) -> Dictionary:
	if not value is Dictionary:
		return {}
	var record := (value as Dictionary).duplicate(true)
	var instance_id := String(record.get("instance_id", "")).strip_edges()
	var event_id := StringName(record.get("event_id", ""))
	var start_seconds := float(record.get("start_seconds", -1.0))
	var end_seconds := float(record.get("end_seconds", -1.0))
	var target: Variant = record.get("target_chunk", [])
	var progress := int(record.get("progress", -1))
	var goal := int(record.get("goal", 0))
	var status := StringName(record.get("status", ""))
	var expected_goal := int(catalog.objective(event_id).get("quantity", 0))
	if instance_id.is_empty() or not instance_id.begins_with("world-event:") or not catalog.has_event(event_id) \
			or start_seconds < 0.0 or end_seconds <= start_seconds \
			or not target is Array or (target as Array).size() != 2 \
			or goal != expected_goal or progress < 0 or progress > goal:
		return {}
	if active:
		if status != &"active" or progress >= goal or record.has("resolved_seconds"):
			return {}
	else:
		if status not in [&"completed", &"expired"] or not record.has("resolved_seconds") \
				or float(record["resolved_seconds"]) < start_seconds \
				or (status == &"completed" and progress != goal) \
				or (status == &"expired" and progress >= goal):
			return {}
	record["instance_id"] = instance_id
	record["event_id"] = String(event_id)
	record["start_seconds"] = start_seconds
	record["end_seconds"] = end_seconds
	record["target_chunk"] = [int((target as Array)[0]), int((target as Array)[1])]
	record["progress"] = progress
	record["goal"] = goal
	record["status"] = String(status)
	if not active:
		record["resolved_seconds"] = float(record["resolved_seconds"])
	return record


func _fail(message: String) -> bool:
	last_error = message
	return false
