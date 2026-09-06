class_name WorldChoiceState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _records: Dictionary = {}


func is_resolved(choice_id: StringName) -> bool:
	return _records.has(String(choice_id))


func selected_option_id(choice_id: StringName) -> StringName:
	return StringName((_records.get(String(choice_id), {}) as Dictionary).get("option_id", ""))


func resolve(
	choice_id: StringName,
	option_id: StringName,
	day: int,
	quest_state: QuestState,
	quest_catalog: QuestCatalog,
	faction_state: FactionState,
	faction_catalog: FactionCatalog,
	progress_state: RegionProgressionState,
	progress_catalog: RegionProgressionCatalog
) -> Dictionary:
	var choice := quest_catalog.world_choice(choice_id)
	var option := quest_catalog.choice_option(choice_id, option_id)
	if choice.is_empty() or option.is_empty() or day < 1:
		return _failure("世界选择参数无效")
	if is_resolved(choice_id):
		return _failure("这个世界选择已经生效")
	var prerequisite := StringName(choice.get("prerequisite_quest_id", ""))
	if quest_state.status(prerequisite, quest_catalog) != &"claimed":
		return _failure("完成并领取前置主线奖励后才能决定")
	var faction_before := faction_state.persistence_snapshot()
	var progress_before := progress_state.persistence_snapshot()
	var faction_results: Array[Dictionary] = []
	for value in option.get("faction_changes", []) as Array:
		var change := value as Dictionary
		var result := faction_state.adjust(
			StringName(change["faction_id"]),
			int(change["delta"]),
			"world_choice:%s:%s" % [choice_id, option_id],
			faction_catalog
		)
		if not bool(result.get("ok", false)):
			faction_state.restore_snapshot(faction_before, faction_catalog)
			progress_state.restore_snapshot(progress_before, progress_catalog)
			return _failure("世界选择的阵营结果无法应用")
		faction_results.append(result)
	var progress_result := progress_state.record_source(
		&"world_choice",
		"%s|%s" % [choice_id, option_id],
		progress_catalog
	)
	if not bool(progress_result.get("changed", false)):
		faction_state.restore_snapshot(faction_before, faction_catalog)
		progress_state.restore_snapshot(progress_before, progress_catalog)
		return _failure("世界选择进度无法安全记录")
	var record := {
		"choice_id": String(choice_id),
		"option_id": String(option_id),
		"resolved_day": day,
	}
	_records[String(choice_id)] = record
	last_error = ""
	return {
		"ok": true,
		"message": "世界选择已生效：%s" % String(option["display_name"]),
		"record": record.duplicate(true),
		"faction_results": faction_results,
		"world_progress_gained": int(progress_result.get("gained", 0)),
	}


func status_snapshot(quest_state: QuestState, quest_catalog: QuestCatalog) -> Dictionary:
	var views: Array[Dictionary] = []
	var available_count := 0
	for choice_id in quest_catalog.world_choice_ids():
		var choice := quest_catalog.world_choice(choice_id)
		var record := _records.get(String(choice_id), {}) as Dictionary
		var prerequisite := StringName(choice.get("prerequisite_quest_id", ""))
		var status := "resolved" if not record.is_empty() else (
			"available" if quest_state.status(prerequisite, quest_catalog) == &"claimed" else "locked"
		)
		available_count += 1 if status == "available" else 0
		var options: Array[Dictionary] = []
		for value in choice.get("options", []) as Array:
			var option := (value as Dictionary).duplicate(true)
			option["selected"] = String(option["id"]) == String(record.get("option_id", ""))
			options.append(option)
		views.append({
			"choice_id": String(choice_id),
			"display_name": String(choice["display_name"]),
			"description": String(choice["description"]),
			"prerequisite_quest_id": String(prerequisite),
			"prerequisite_display_name": String(quest_catalog.quest(prerequisite).get("display_name", prerequisite)),
			"status": status,
			"selected_option_id": String(record.get("option_id", "")),
			"resolved_day": int(record.get("resolved_day", 0)),
			"options": options,
		})
	return {
		"schema_version": SCHEMA_VERSION,
		"resolved_count": _records.size(),
		"available_count": available_count,
		"choices": views,
	}


func persistence_snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for value in _records.values():
		records.append((value as Dictionary).duplicate(true))
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["choice_id"]) < String(b["choice_id"]))
	return {"schema_version": SCHEMA_VERSION, "records": records}


func restore_snapshot(value: Dictionary, quest_catalog := QuestCatalog.new()) -> bool:
	if value.is_empty():
		_records.clear()
		last_error = ""
		return true
	if not quest_catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION \
			or not value.get("records", []) is Array:
		return _fail("世界选择状态格式无效")
	var records := value.get("records", []) as Array
	if records.size() > quest_catalog.world_choice_ids().size():
		return _fail("世界选择记录超过上限")
	var restored := {}
	for value_record in records:
		if not value_record is Dictionary:
			return _fail("世界选择记录必须是对象")
		var record := value_record as Dictionary
		var choice_id := StringName(record.get("choice_id", ""))
		var option_id := StringName(record.get("option_id", ""))
		if quest_catalog.world_choice(choice_id).is_empty() or quest_catalog.choice_option(choice_id, option_id).is_empty() \
				or restored.has(String(choice_id)) or int(record.get("resolved_day", 0)) < 1:
			return _fail("世界选择记录字段无效")
		restored[String(choice_id)] = {
			"choice_id": String(choice_id),
			"option_id": String(option_id),
			"resolved_day": int(record["resolved_day"]),
		}
	_records = restored
	last_error = ""
	return true


func _failure(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}


func _fail(message: String) -> bool:
	last_error = message
	return false
