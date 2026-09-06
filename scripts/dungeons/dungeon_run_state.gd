class_name DungeonRunState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _current_dungeon_id := ""
var _runs: Dictionary = {}


func begin(dungeon_id: String, anchor_chunk: Vector2i, return_position: Vector2) -> Dictionary:
	if not _is_valid_dungeon_id(dungeon_id):
		return _fail("地牢 ID 无效")
	var run := (_runs.get(dungeon_id, _empty_run(dungeon_id, anchor_chunk, return_position)) as Dictionary).duplicate(true)
	if _current_dungeon_id != dungeon_id:
		if not bool(run["completed"]):
			_reset_transient(run)
			run["attempt_count"] = int(run["attempt_count"]) + 1
	run["anchor_chunk"] = [anchor_chunk.x, anchor_chunk.y]
	run["return_position"] = [return_position.x, return_position.y]
	_runs[dungeon_id] = run
	_current_dungeon_id = dungeon_id
	last_error = ""
	return run.duplicate(true)


func leave_current() -> Dictionary:
	if _current_dungeon_id.is_empty() or not _runs.has(_current_dungeon_id):
		return {"left": false, "reset": false, "completed": false, "dungeon_id": ""}
	var dungeon_id := _current_dungeon_id
	var run := (_runs[dungeon_id] as Dictionary).duplicate(true)
	var reset := not bool(run["completed"])
	if reset:
		_reset_transient(run)
	_runs[dungeon_id] = run
	_current_dungeon_id = ""
	return {"left": true, "reset": reset, "completed": bool(run["completed"]), "dungeon_id": dungeon_id}


func current_dungeon_id() -> String:
	return _current_dungeon_id


func current_run() -> Dictionary:
	return run_snapshot(_current_dungeon_id)


func run_snapshot(dungeon_id: String) -> Dictionary:
	return (_runs.get(dungeon_id, {}) as Dictionary).duplicate(true)


func collect_key(feature_key: String) -> bool:
	var run := _mutable_current_run()
	if run.is_empty() or (run["collected_keys"] as Array).has(feature_key):
		return false
	(run["collected_keys"] as Array).append(feature_key)
	(run["collected_keys"] as Array).sort()
	run["key_count"] = int(run["key_count"]) + 1
	_store_current(run)
	return true


func unlock_door(feature_key: String) -> bool:
	var run := _mutable_current_run()
	if run.is_empty() or (run["unlocked_doors"] as Array).has(feature_key) or int(run["key_count"]) <= 0:
		return false
	(run["unlocked_doors"] as Array).append(feature_key)
	(run["unlocked_doors"] as Array).sort()
	run["key_count"] = int(run["key_count"]) - 1
	_store_current(run)
	return true


func trigger_trap(feature_key: String) -> bool:
	return _record_unique("triggered_traps", feature_key)


func open_chest(feature_key: String) -> bool:
	return _record_unique("opened_chests", feature_key)


func defeat_enemy(spawn_id: String, role: StringName) -> Dictionary:
	var run := _mutable_current_run()
	if run.is_empty():
		return {"changed": false, "completed": false}
	if role == &"boss":
		if bool(run["boss_defeated"]):
			return {"changed": false, "completed": bool(run["completed"])}
		run["boss_defeated"] = true
		run["completed"] = true
	elif role == &"elite":
		if (run["defeated_elites"] as Array).has(spawn_id):
			return {"changed": false, "completed": bool(run["completed"])}
		(run["defeated_elites"] as Array).append(spawn_id)
		(run["defeated_elites"] as Array).sort()
	else:
		return {"changed": false, "completed": bool(run["completed"])}
	_store_current(run)
	return {"changed": true, "completed": bool(run["completed"])}


func persistence_snapshot() -> Dictionary:
	var runs: Array[Dictionary] = []
	var ids: Array[String] = []
	for dungeon_id_value in _runs.keys():
		ids.append(String(dungeon_id_value))
	ids.sort()
	for dungeon_id in ids:
		runs.append((_runs[dungeon_id] as Dictionary).duplicate(true))
	return {"schema_version": SCHEMA_VERSION, "current_dungeon_id": _current_dungeon_id, "runs": runs}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_current_dungeon_id = ""
		_runs.clear()
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		last_error = "地牢进度版本无效"
		return false
	var runs_value: Variant = value.get("runs", [])
	if not runs_value is Array:
		last_error = "地牢进度列表必须是数组"
		return false
	var restored := {}
	for run_value in runs_value as Array:
		if not run_value is Dictionary:
			last_error = "地牢进度条目必须是对象"
			return false
		var normalized := _normalize_run(run_value as Dictionary)
		if normalized.is_empty():
			return false
		var dungeon_id := String(normalized["dungeon_id"])
		if restored.has(dungeon_id):
			last_error = "地牢进度 ID 重复"
			return false
		restored[dungeon_id] = normalized
	var current := String(value.get("current_dungeon_id", ""))
	if not current.is_empty() and not restored.has(current):
		last_error = "当前地牢进度不存在"
		return false
	_runs = restored
	_current_dungeon_id = current
	last_error = ""
	return true


func status_snapshot() -> Dictionary:
	var run := current_run()
	if run.is_empty():
		return {"active": false, "dungeon_id": "", "completed": false, "attempt_count": 0, "key_count": 0, "objective": ""}
	var objective := "地牢已完成 · 返回入口" if bool(run["completed"]) else "击败地牢守卫"
	if not bool(run["completed"]) and int(run["key_count"]) > 0:
		objective = "寻找锁门 · 钥匙 %d" % int(run["key_count"])
	return {
		"active": true,
		"dungeon_id": _current_dungeon_id,
		"completed": bool(run["completed"]),
		"attempt_count": int(run["attempt_count"]),
		"key_count": int(run["key_count"]),
		"opened_chests": (run["opened_chests"] as Array).size(),
		"defeated_elites": (run["defeated_elites"] as Array).size(),
		"boss_defeated": bool(run["boss_defeated"]),
		"objective": objective,
	}


func _record_unique(field: String, feature_key: String) -> bool:
	var run := _mutable_current_run()
	if run.is_empty() or (run[field] as Array).has(feature_key):
		return false
	(run[field] as Array).append(feature_key)
	(run[field] as Array).sort()
	_store_current(run)
	return true


func _mutable_current_run() -> Dictionary:
	return (_runs.get(_current_dungeon_id, {}) as Dictionary).duplicate(true)


func _store_current(run: Dictionary) -> void:
	_runs[_current_dungeon_id] = run


func _empty_run(dungeon_id: String, anchor_chunk: Vector2i, return_position: Vector2) -> Dictionary:
	return {
		"dungeon_id": dungeon_id,
		"anchor_chunk": [anchor_chunk.x, anchor_chunk.y],
		"return_position": [return_position.x, return_position.y],
		"attempt_count": 0,
		"completed": false,
		"boss_defeated": false,
		"key_count": 0,
		"collected_keys": [],
		"unlocked_doors": [],
		"triggered_traps": [],
		"opened_chests": [],
		"defeated_elites": [],
	}


func _reset_transient(run: Dictionary) -> void:
	run["boss_defeated"] = false
	run["key_count"] = 0
	for field in ["collected_keys", "unlocked_doors", "triggered_traps", "opened_chests", "defeated_elites"]:
		run[field] = []


func _normalize_run(value: Dictionary) -> Dictionary:
	var dungeon_id := String(value.get("dungeon_id", ""))
	var anchor: Variant = value.get("anchor_chunk", [])
	var return_position: Variant = value.get("return_position", [])
	var attempts := int(value.get("attempt_count", 0))
	if not _is_valid_dungeon_id(dungeon_id) or not anchor is Array or (anchor as Array).size() != 2 \
			or not return_position is Array or (return_position as Array).size() != 2 or attempts < 1:
		last_error = "地牢 ID、入口或尝试次数无效"
		return {}
	var normalized := _empty_run(
		dungeon_id,
		Vector2i(int((anchor as Array)[0]), int((anchor as Array)[1])),
		Vector2(float((return_position as Array)[0]), float((return_position as Array)[1]))
	)
	normalized["attempt_count"] = attempts
	normalized["completed"] = bool(value.get("completed", false))
	normalized["boss_defeated"] = bool(value.get("boss_defeated", false))
	if bool(normalized["completed"]) != bool(normalized["boss_defeated"]):
		last_error = "地牢完成状态必须与 Boss 状态一致"
		return {}
	for field in ["collected_keys", "unlocked_doors", "triggered_traps", "opened_chests", "defeated_elites"]:
		var values: Variant = value.get(field, [])
		if not values is Array:
			last_error = "地牢字段 %s 必须是数组" % field
			return {}
		var strings: Array[String] = []
		for item in values as Array:
			var text := String(item)
			if text.is_empty() or strings.has(text):
				last_error = "地牢字段 %s 包含空值或重复项" % field
				return {}
			strings.append(text)
		strings.sort()
		normalized[field] = strings
	var key_count := int(value.get("key_count", 0))
	if key_count < 0 or key_count + (normalized["unlocked_doors"] as Array).size() != (normalized["collected_keys"] as Array).size():
		last_error = "地牢钥匙数量与锁门状态不一致"
		return {}
	normalized["key_count"] = key_count
	return normalized


func _is_valid_dungeon_id(dungeon_id: String) -> bool:
	return dungeon_id.begins_with("dungeon_") and dungeon_id.length() > 8


func _fail(message: String) -> Dictionary:
	last_error = message
	return {}
