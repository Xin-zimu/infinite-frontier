class_name NpcWorldState
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_RECORDS := 2048

var last_error := ""
var _records: Dictionary = {}


func record_talk(npc_id: String, day: int) -> void:
	var record := _record(npc_id)
	record["talk_count"] = int(record["talk_count"]) + 1
	record["last_talk_day"] = maxi(day, 1)
	_records[npc_id] = record


func record_trade(npc_id: String, trade_kind: StringName, coin_amount: int, day: int) -> void:
	var record := _record(npc_id)
	record["trade_count"] = int(record["trade_count"]) + 1
	if trade_kind == &"buy":
		record["coins_spent"] = int(record["coins_spent"]) + maxi(coin_amount, 0)
	else:
		record["coins_earned"] = int(record["coins_earned"]) + maxi(coin_amount, 0)
	record["last_trade_day"] = maxi(day, 1)
	_records[npc_id] = record


func record_for(npc_id: String) -> Dictionary:
	return (_records.get(npc_id, _default_record(npc_id)) as Dictionary).duplicate(true)


func record_count() -> int:
	return _records.size()


func persistence_snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for value in _records.values():
		records.append((value as Dictionary).duplicate(true))
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["npc_id"]) < String(b["npc_id"]))
	return {"schema_version": SCHEMA_VERSION, "records": records}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_records.clear()
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("records", []) is Array:
		return _fail("NPC 状态格式无效")
	var restored := {}
	var records := value.get("records", []) as Array
	if records.size() > MAX_RECORDS:
		return _fail("NPC 状态记录超过上限")
	for value_record in records:
		if not value_record is Dictionary:
			return _fail("NPC 状态记录必须是对象")
		var record := value_record as Dictionary
		var npc_id := String(record.get("npc_id", ""))
		if npc_id.is_empty() or restored.has(npc_id):
			return _fail("NPC 状态包含无效或重复 ID")
		for key in ["talk_count", "trade_count", "coins_spent", "coins_earned", "last_talk_day", "last_trade_day"]:
			if int(record.get(key, -1)) < 0:
				return _fail("NPC 状态计数无效")
		restored[npc_id] = {
			"npc_id": npc_id,
			"talk_count": int(record["talk_count"]),
			"trade_count": int(record["trade_count"]),
			"coins_spent": int(record["coins_spent"]),
			"coins_earned": int(record["coins_earned"]),
			"last_talk_day": int(record["last_talk_day"]),
			"last_trade_day": int(record["last_trade_day"]),
		}
	_records = restored
	last_error = ""
	return true


func _record(npc_id: String) -> Dictionary:
	if npc_id.is_empty():
		return _default_record("invalid")
	return (_records.get(npc_id, _default_record(npc_id)) as Dictionary).duplicate(true)


func _default_record(npc_id: String) -> Dictionary:
	return {
		"npc_id": npc_id,
		"talk_count": 0,
		"trade_count": 0,
		"coins_spent": 0,
		"coins_earned": 0,
		"last_talk_day": 0,
		"last_trade_day": 0,
	}


func _fail(message: String) -> bool:
	last_error = message
	return false
