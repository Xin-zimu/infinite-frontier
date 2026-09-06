class_name QuestState
extends RefCounted

const SCHEMA_VERSION := 2
const VALID_STATUSES := ["active", "completed", "claimed", "failed"]

var last_error := ""
var _entries: Dictionary = {}
var _tracked_id := ""
var _generated: Dictionary = {}
var _boards: Dictionary = {}
var _item_catalog := ItemCatalog.new()


static func migrate_legacy_snapshot(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return QuestState.new().persistence_snapshot()
	if int(value.get("schema_version", 0)) == SCHEMA_VERSION:
		return value.duplicate(true)
	if int(value.get("schema_version", 0)) != 1:
		return value.duplicate(true)
	return {
		"schema_version": SCHEMA_VERSION,
		"tracked_id": String(value.get("tracked_id", "")),
		"entries": (value.get("entries", []) as Array).duplicate(true),
		"generated_quests": [],
		"boards": [],
	}


func definition(quest_id: StringName, catalog: QuestCatalog) -> Dictionary:
	var fixed := catalog.quest(quest_id)
	if not fixed.is_empty():
		return fixed
	return (_generated.get(String(quest_id), {}) as Dictionary).duplicate(true)


func ensure_random_board(world_seed: int, board_id: String, day: int, catalog: QuestCatalog) -> Array[String]:
	var generator := QuestGenerator.new(world_seed, catalog)
	var key := generator.board_key(board_id, day)
	if _boards.has(key):
		return _string_array((_boards[key] as Dictionary).get("quest_ids", []) as Array)
	var generated := generator.generate_board(board_id, day)
	if generated.is_empty():
		_fail("无法生成当前区域委托")
		return []
	if not _prune_generated_for_capacity(generated.size(), catalog):
		_fail("随机委托记录已达安全上限")
		return []
	var ids: Array[String] = []
	for value in generated:
		var generated_quest := value as Dictionary
		var quest_id := String(generated_quest["id"])
		if ids.has(quest_id) or _generated.has(quest_id) or catalog.has_quest(StringName(quest_id)):
			_fail("随机委托稳定 ID 冲突")
			return []
		ids.append(quest_id)
	for value in generated:
		var generated_quest := value as Dictionary
		_generated[String(generated_quest["id"])] = generated_quest.duplicate(true)
	_boards[key] = {"board_id": board_id.strip_edges(), "day": day, "quest_ids": ids.duplicate()}
	last_error = ""
	return ids


func accept(quest_id: StringName, catalog: QuestCatalog) -> bool:
	var definition_value := definition(quest_id, catalog)
	if definition_value.is_empty():
		return _fail("任务不存在")
	var existing := _entries.get(String(quest_id), {}) as Dictionary
	if not existing.is_empty() and String(existing.get("status", "")) != "failed":
		return _fail("任务已经接取")
	if not existing.is_empty() and not bool(definition_value.get("retryable", false)):
		return _fail("这个任务不能重试")
	if not _prerequisites_claimed(definition_value):
		return _fail("前置任务尚未完成并领取奖励")
	if active_count() >= catalog.maximum_active():
		return _fail("同时追踪的任务已达上限")
	var progress: Array[Dictionary] = []
	for value in definition_value.get("objectives", []) as Array:
		progress.append({"objective_id": String((value as Dictionary)["id"]), "current": 0})
	_entries[String(quest_id)] = {
		"quest_id": String(quest_id),
		"status": "active",
		"progress": progress,
		"failure_count": int(existing.get("failure_count", 0)),
	}
	if _tracked_id.is_empty():
		_tracked_id = String(quest_id)
	last_error = ""
	return true


func abandon(quest_id: StringName, catalog: QuestCatalog) -> bool:
	var definition_value := definition(quest_id, catalog)
	var entry := _entries.get(String(quest_id), {}) as Dictionary
	if definition_value.is_empty() or String(entry.get("status", "")) != "active" or not bool(definition_value.get("can_abandon", false)):
		return _fail("这个任务当前不能放弃")
	entry["status"] = "failed"
	entry["failure_count"] = int(entry.get("failure_count", 0)) + 1
	_entries[String(quest_id)] = entry
	if _tracked_id == String(quest_id):
		_tracked_id = _first_active_id()
	last_error = ""
	return true


func track(quest_id: StringName) -> bool:
	var entry := _entries.get(String(quest_id), {}) as Dictionary
	if not ["active", "completed"].has(String(entry.get("status", ""))):
		return _fail("只能追踪进行中或待领取任务")
	_tracked_id = String(quest_id)
	last_error = ""
	return true


func record_event(objective_type: StringName, target_id: StringName, amount: int, catalog: QuestCatalog) -> bool:
	if amount <= 0 or not ["defeat", "escort"].has(String(objective_type)):
		return false
	var changed := false
	for quest_id_value in _entries.keys():
		var entry := _entries[quest_id_value] as Dictionary
		if String(entry.get("status", "")) != "active":
			continue
		var definition_value := definition(StringName(quest_id_value), catalog)
		var objectives := definition_value.get("objectives", []) as Array
		var progress := entry.get("progress", []) as Array
		for index in objectives.size():
			var objective := objectives[index] as Dictionary
			if StringName(objective.get("type", "")) != objective_type or StringName(objective.get("target_id", "")) != target_id:
				continue
			var current := int((progress[index] as Dictionary).get("current", 0))
			var next := mini(int(objective["quantity"]), current + amount)
			if next != current:
				(progress[index] as Dictionary)["current"] = next
				changed = true
		entry["progress"] = progress
		_entries[quest_id_value] = entry
		if _complete_if_ready(String(quest_id_value), definition_value):
			changed = true
	return changed


func synchronize_collect(counts: Dictionary, catalog: QuestCatalog) -> bool:
	return _synchronize_type(&"collect", counts, catalog)


func synchronize_explore(type_counts: Dictionary, catalog: QuestCatalog) -> bool:
	return _synchronize_type(&"explore", type_counts, catalog)


func claim_reward(quest_id: StringName, inventory: InventoryModel, catalog: QuestCatalog) -> Dictionary:
	var entry := _entries.get(String(quest_id), {}) as Dictionary
	var definition_value := definition(quest_id, catalog)
	if definition_value.is_empty() or String(entry.get("status", "")) != "completed":
		return {"ok": false, "message": "任务奖励尚不可领取"}
	var before := inventory.snapshot()
	var rewards: Array[Dictionary] = []
	for value in definition_value.get("rewards", []) as Array:
		var reward := value as Dictionary
		var item_id := StringName(reward["item_id"])
		var quantity := int(reward["quantity"])
		var result := inventory.add_item(item_id, quantity)
		if int(result["remainder"]) > 0:
			inventory.restore_snapshot(before)
			return {"ok": false, "message": "背包空间不足，奖励领取已撤销"}
		rewards.append({"item_id": String(item_id), "display_name": _item_catalog.display_name(item_id), "quantity": quantity})
	entry["status"] = "claimed"
	_entries[String(quest_id)] = entry
	if _tracked_id == String(quest_id):
		_tracked_id = _first_active_id()
	last_error = ""
	return {"ok": true, "message": "任务奖励已领取", "rewards": rewards}


func status(quest_id: StringName, catalog: QuestCatalog) -> StringName:
	var entry := _entries.get(String(quest_id), {}) as Dictionary
	if not entry.is_empty():
		return StringName(entry.get("status", "failed"))
	var definition_value := definition(quest_id, catalog)
	return &"available" if not definition_value.is_empty() and _prerequisites_claimed(definition_value) else &"locked"


func active_count() -> int:
	var count := 0
	for value in _entries.values():
		count += 1 if String((value as Dictionary).get("status", "")) == "active" else 0
	return count


func completed_count() -> int:
	var count := 0
	for value in _entries.values():
		count += 1 if ["completed", "claimed"].has(String((value as Dictionary).get("status", ""))) else 0
	return count


func tracked_id() -> String:
	return _tracked_id


func quest_view(quest_id: StringName, catalog: QuestCatalog) -> Dictionary:
	var definition_value := definition(quest_id, catalog)
	if definition_value.is_empty():
		return {}
	var entry := _entries.get(String(quest_id), {}) as Dictionary
	var progress_values := entry.get("progress", []) as Array
	var objectives: Array[Dictionary] = []
	for index in (definition_value.get("objectives", []) as Array).size():
		var objective := ((definition_value["objectives"] as Array)[index] as Dictionary).duplicate(true)
		objective["current"] = int((progress_values[index] as Dictionary).get("current", 0)) if index < progress_values.size() else 0
		objective["complete"] = int(objective["current"]) >= int(objective["quantity"])
		objectives.append(objective)
	var rewards: Array[Dictionary] = []
	for value in definition_value.get("rewards", []) as Array:
		var reward := (value as Dictionary).duplicate(true)
		reward["display_name"] = _item_catalog.display_name(StringName(reward["item_id"]))
		rewards.append(reward)
	return {
		"quest_id": String(quest_id),
		"category": String(definition_value["category"]),
		"display_name": String(definition_value["display_name"]),
		"description": String(definition_value["description"]),
		"giver_role": String(definition_value["giver_role"]),
		"status": String(status(quest_id, catalog)),
		"tracked": _tracked_id == String(quest_id),
		"can_abandon": bool(definition_value.get("can_abandon", false)),
		"retryable": bool(definition_value.get("retryable", false)),
		"failure_count": int(entry.get("failure_count", 0)),
		"objectives": objectives,
		"rewards": rewards,
		"random": (definition_value.get("random", {}) as Dictionary).duplicate(true),
	}


func status_snapshot(catalog: QuestCatalog, board_id := "", day := 1, world_seed := 0) -> Dictionary:
	var board_ids: Array[String] = []
	if not board_id.strip_edges().is_empty():
		board_ids = ensure_random_board(world_seed, board_id, day, catalog)
	var visible_ids: Array[String] = []
	var included := {}
	for quest_id in catalog.quest_ids():
		visible_ids.append(String(quest_id))
		included[String(quest_id)] = true
	for quest_id in board_ids:
		if not included.has(quest_id):
			visible_ids.append(quest_id)
			included[quest_id] = true
	var historical_random: Array[String] = []
	for quest_id_value in _entries.keys():
		var quest_id := String(quest_id_value)
		if _generated.has(quest_id) and not included.has(quest_id):
			historical_random.append(quest_id)
	historical_random.sort()
	visible_ids.append_array(historical_random)
	var views: Array[Dictionary] = []
	for quest_id in visible_ids:
		views.append(quest_view(StringName(quest_id), catalog))
	return {
		"schema_version": SCHEMA_VERSION,
		"tracked_id": _tracked_id,
		"active_count": active_count(),
		"completed_count": completed_count(),
		"maximum_active": catalog.maximum_active(),
		"fixed_template_count": catalog.quest_ids().size(),
		"board_id": board_id,
		"board_day": day,
		"random_offer_count": board_ids.size(),
		"quests": views,
		"tracked": quest_view(StringName(_tracked_id), catalog) if not _tracked_id.is_empty() else {},
	}


func persistence_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for value in _entries.values():
		entries.append((value as Dictionary).duplicate(true))
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["quest_id"]) < String(b["quest_id"]))
	var generated_quests: Array[Dictionary] = []
	for value in _generated.values():
		generated_quests.append((value as Dictionary).duplicate(true))
	generated_quests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	var boards: Array[Dictionary] = []
	for value in _boards.values():
		boards.append((value as Dictionary).duplicate(true))
	boards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["board_id"]) < String(b["board_id"]) \
				or (String(a["board_id"]) == String(b["board_id"]) and int(a["day"]) < int(b["day"]))
	)
	return {
		"schema_version": SCHEMA_VERSION,
		"tracked_id": _tracked_id,
		"entries": entries,
		"generated_quests": generated_quests,
		"boards": boards,
	}


func restore_snapshot(value: Dictionary, catalog := QuestCatalog.new()) -> bool:
	if value.is_empty():
		_reset()
		return true
	if not catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		return _fail("任务状态格式无效")
	for key in ["entries", "generated_quests", "boards"]:
		if not value.get(key, []) is Array:
			return _fail("任务状态列表格式无效")
	var generated_values := value.get("generated_quests", []) as Array
	if generated_values.size() > catalog.maximum_generated_quests():
		return _fail("随机委托记录超过上限")
	var restored_generated := {}
	for generated_value in generated_values:
		if not generated_value is Dictionary:
			return _fail("随机委托必须是对象")
		var generated_quest := generated_value as Dictionary
		var quest_id := String(generated_quest.get("id", ""))
		if quest_id.is_empty() or restored_generated.has(quest_id) or catalog.has_quest(StringName(quest_id)) \
				or not catalog.validate_generated_quest(generated_quest):
			return _fail("随机委托记录无效")
		restored_generated[quest_id] = generated_quest.duplicate(true)
	var restored_boards := {}
	var referenced_generated := {}
	for board_value in value.get("boards", []) as Array:
		if not board_value is Dictionary:
			return _fail("随机委托板记录必须是对象")
		var board := board_value as Dictionary
		var board_id := String(board.get("board_id", "")).strip_edges()
		var day := int(board.get("day", 0))
		var quest_ids_value: Variant = board.get("quest_ids", [])
		var key := "%s|%d" % [board_id, day]
		if board_id.is_empty() or day < 1 or restored_boards.has(key) or not quest_ids_value is Array \
				or (quest_ids_value as Array).size() != catalog.random_offers_per_board():
			return _fail("随机委托板字段无效")
		var quest_ids: Array[String] = []
		for quest_id_value in quest_ids_value as Array:
			var quest_id := String(quest_id_value)
			var generated_quest := restored_generated.get(quest_id, {}) as Dictionary
			var metadata := generated_quest.get("random", {}) as Dictionary
			if generated_quest.is_empty() or referenced_generated.has(quest_id) or String(metadata.get("board_id", "")) != board_id \
					or int(metadata.get("day", 0)) != day:
				return _fail("随机委托板引用无效")
			referenced_generated[quest_id] = true
			quest_ids.append(quest_id)
		restored_boards[key] = {"board_id": board_id, "day": day, "quest_ids": quest_ids}
	if referenced_generated.size() != restored_generated.size():
		return _fail("随机委托缺少所属委托板")
	var restored_entries := {}
	var active_total := 0
	for entry_value in value.get("entries", []) as Array:
		if not entry_value is Dictionary:
			return _fail("任务记录必须是对象")
		var entry := entry_value as Dictionary
		var quest_id := String(entry.get("quest_id", ""))
		var definition_value := catalog.quest(StringName(quest_id))
		if definition_value.is_empty():
			definition_value = (restored_generated.get(quest_id, {}) as Dictionary).duplicate(true)
		var status_value := String(entry.get("status", ""))
		if definition_value.is_empty() or restored_entries.has(quest_id) or not VALID_STATUSES.has(status_value) or int(entry.get("failure_count", -1)) < 0:
			return _fail("任务记录字段无效")
		var progress_value: Variant = entry.get("progress", [])
		if not progress_value is Array or (progress_value as Array).size() != (definition_value.get("objectives", []) as Array).size():
			return _fail("任务目标进度数量无效")
		var normalized_progress: Array[Dictionary] = []
		var complete := true
		for index in (definition_value.get("objectives", []) as Array).size():
			var objective := (definition_value["objectives"] as Array)[index] as Dictionary
			var progress_entry: Variant = (progress_value as Array)[index]
			if not progress_entry is Dictionary:
				return _fail("任务目标进度必须是对象")
			var progress := progress_entry as Dictionary
			var current := int(progress.get("current", -1))
			if String(progress.get("objective_id", "")) != String(objective["id"]) or current < 0 or current > int(objective["quantity"]):
				return _fail("任务目标进度字段无效")
			normalized_progress.append({"objective_id": String(objective["id"]), "current": current})
			complete = complete and current >= int(objective["quantity"])
		if ["completed", "claimed"].has(status_value) != complete:
			return _fail("任务完成状态与目标进度不一致")
		if status_value == "failed" and not bool(definition_value.get("can_abandon", false)):
			return _fail("不可放弃任务不能处于失败状态")
		active_total += 1 if status_value == "active" else 0
		restored_entries[quest_id] = {"quest_id": quest_id, "status": status_value, "progress": normalized_progress, "failure_count": int(entry["failure_count"])}
	if active_total > catalog.maximum_active():
		return _fail("进行中任务超过上限")
	for entry_key in restored_entries.keys():
		var definition_value := catalog.quest(StringName(entry_key))
		if definition_value.is_empty():
			definition_value = restored_generated.get(String(entry_key), {}) as Dictionary
		for prerequisite in definition_value.get("prerequisite_ids", []) as Array:
			if String((restored_entries.get(String(prerequisite), {}) as Dictionary).get("status", "")) != "claimed":
				return _fail("已接取任务缺少已领取的前置任务")
	var restored_tracked := String(value.get("tracked_id", ""))
	if not restored_tracked.is_empty() and not ["active", "completed"].has(String((restored_entries.get(restored_tracked, {}) as Dictionary).get("status", ""))):
		return _fail("追踪任务状态无效")
	_entries = restored_entries
	_generated = restored_generated
	_boards = restored_boards
	_tracked_id = restored_tracked
	last_error = ""
	return true


func _synchronize_type(objective_type: StringName, counts: Dictionary, catalog: QuestCatalog) -> bool:
	var changed := false
	for quest_id_value in _entries.keys():
		var entry := _entries[quest_id_value] as Dictionary
		if String(entry.get("status", "")) != "active":
			continue
		var definition_value := definition(StringName(quest_id_value), catalog)
		var objectives := definition_value.get("objectives", []) as Array
		var progress := entry.get("progress", []) as Array
		for index in objectives.size():
			var objective := objectives[index] as Dictionary
			if StringName(objective.get("type", "")) != objective_type:
				continue
			var next := mini(int(objective["quantity"]), maxi(0, int(counts.get(String(objective["target_id"]), 0))))
			if next != int((progress[index] as Dictionary).get("current", 0)):
				(progress[index] as Dictionary)["current"] = next
				changed = true
		entry["progress"] = progress
		_entries[quest_id_value] = entry
		if _complete_if_ready(String(quest_id_value), definition_value):
			changed = true
	return changed


func _complete_if_ready(quest_id: String, definition_value: Dictionary) -> bool:
	var entry := _entries[quest_id] as Dictionary
	if String(entry.get("status", "")) != "active":
		return false
	var progress := entry.get("progress", []) as Array
	var objectives := definition_value.get("objectives", []) as Array
	for index in objectives.size():
		if int((progress[index] as Dictionary).get("current", 0)) < int((objectives[index] as Dictionary)["quantity"]):
			return false
	entry["status"] = "completed"
	_entries[quest_id] = entry
	return true


func _prerequisites_claimed(definition_value: Dictionary) -> bool:
	for prerequisite in definition_value.get("prerequisite_ids", []) as Array:
		if String((_entries.get(String(prerequisite), {}) as Dictionary).get("status", "")) != "claimed":
			return false
	return true


func _prune_generated_for_capacity(required: int, catalog: QuestCatalog) -> bool:
	var maximum := catalog.maximum_generated_quests()
	if _generated.size() + required <= maximum:
		return true
	var candidates: Array[Dictionary] = []
	for board_key_value in _boards.keys():
		var board_key := String(board_key_value)
		var board := _boards[board_key] as Dictionary
		var ids := _string_array(board.get("quest_ids", []) as Array)
		var removable := true
		for quest_id in ids:
			var entry := _entries.get(quest_id, {}) as Dictionary
			if not entry.is_empty() and not ["claimed", "failed"].has(String(entry.get("status", ""))):
				removable = false
				break
		if removable:
			candidates.append({"board_key": board_key, "day": int(board.get("day", 0)), "quest_ids": ids})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["day"]) < int(b["day"]) or (int(a["day"]) == int(b["day"]) and String(a["board_key"]) < String(b["board_key"]))
	)
	for candidate in candidates:
		if _generated.size() + required <= maximum:
			break
		for quest_id in candidate["quest_ids"] as Array:
			_generated.erase(String(quest_id))
			_entries.erase(String(quest_id))
		_boards.erase(String(candidate["board_key"]))
	return _generated.size() + required <= maximum


func _first_active_id() -> String:
	var ids: Array[String] = []
	for key in _entries.keys():
		if String((_entries[key] as Dictionary).get("status", "")) == "active":
			ids.append(String(key))
	ids.sort()
	return ids[0] if not ids.is_empty() else ""


func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _reset() -> void:
	_entries.clear()
	_generated.clear()
	_boards.clear()
	_tracked_id = ""
	last_error = ""


func _fail(message: String) -> bool:
	last_error = message
	return false
