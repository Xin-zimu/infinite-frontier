class_name RelationshipState
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_NPC_RECORDS := 2048
const MAX_VILLAGE_RECORDS := 512

var last_error := ""
var _npcs: Dictionary = {}
var _villages: Dictionary = {}


func affection(npc_id: String) -> int:
	return int((_npcs.get(npc_id, {}) as Dictionary).get("affection", 0))


func village_reputation(village_id: String) -> int:
	return int((_villages.get(village_id, {}) as Dictionary).get("reputation", 0))


func tier_id(npc_id: String, catalog: RelationshipCatalog) -> StringName:
	return catalog.tier_id(affection(npc_id))


func can_gift(npc_id: String, day: int) -> bool:
	return int((_npcs.get(npc_id, {}) as Dictionary).get("last_gift_day", 0)) != maxi(day, 1)


func apply_gift(
	npc_id: String,
	village_id: String,
	role_id: StringName,
	item_id: StringName,
	day: int,
	catalog: RelationshipCatalog
) -> Dictionary:
	if npc_id.is_empty() or village_id.is_empty() or not can_gift(npc_id, day):
		last_error = "今天已经给这位 NPC 送过礼物"
		return {"ok": false, "message": last_error}
	var npc := _npc_record(npc_id)
	var village := _village_record(village_id)
	var before := int(npc["affection"])
	var delta := catalog.gift_value(role_id, item_id)
	var after := clampi(before + delta, catalog.affection_minimum(), catalog.affection_maximum())
	npc["affection"] = after
	npc["last_gift_day"] = maxi(day, 1)
	npc["gift_count"] = int(npc["gift_count"]) + 1
	var reputation_delta := roundi(float(delta) / float(catalog.gift_reputation_divisor()))
	village["reputation"] = clampi(int(village["reputation"]) + reputation_delta, catalog.reputation_minimum(), catalog.reputation_maximum())
	var rewards: Array[Dictionary] = []
	var claimed := npc["claimed_rewards"] as Array
	for reward in catalog.rewards():
		var reward_id := String(reward["id"])
		if after >= int(reward["minimum_affection"]) and not claimed.has(reward_id):
			claimed.append(reward_id)
			rewards.append(reward)
	claimed.sort()
	_npcs[npc_id] = npc
	_villages[village_id] = village
	last_error = ""
	return {
		"ok": true,
		"affection_delta": after - before,
		"reputation_delta": reputation_delta,
		"tier_id": String(catalog.tier_id(after)),
		"rewards": rewards,
	}


func record_trade(npc_id: String, village_id: String, catalog: RelationshipCatalog) -> void:
	var npc := _npc_record(npc_id)
	var village := _village_record(village_id)
	npc["affection"] = clampi(int(npc["affection"]) + catalog.trade_affection(), catalog.affection_minimum(), catalog.affection_maximum())
	village["reputation"] = clampi(int(village["reputation"]) + catalog.trade_reputation(), catalog.reputation_minimum(), catalog.reputation_maximum())
	_npcs[npc_id] = npc
	_villages[village_id] = village


func status_snapshot(npc_id: String, village_id: String, catalog: RelationshipCatalog, day := 1) -> Dictionary:
	var affection_value := affection(npc_id)
	var tier_value := catalog.tier_id(affection_value)
	var definition := catalog.tier(tier_value)
	return {
		"npc_id": npc_id,
		"village_id": village_id,
		"affection": affection_value,
		"village_reputation": village_reputation(village_id),
		"tier_id": String(tier_value),
		"tier_display_name": String(definition.get("display_name", "中立")),
		"tier_color": String(definition.get("color", "9fc2cf")),
		"can_gift_today": can_gift(npc_id, day),
	}


func persistence_snapshot() -> Dictionary:
	var npcs: Array[Dictionary] = []
	for value in _npcs.values():
		npcs.append((value as Dictionary).duplicate(true))
	npcs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["npc_id"]) < String(b["npc_id"]))
	var villages: Array[Dictionary] = []
	for value in _villages.values():
		villages.append((value as Dictionary).duplicate(true))
	villages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["village_id"]) < String(b["village_id"]))
	return {"schema_version": SCHEMA_VERSION, "npcs": npcs, "villages": villages}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_npcs.clear()
		_villages.clear()
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("npcs", []) is Array or not value.get("villages", []) is Array:
		return _fail("关系状态格式无效")
	var npc_values := value.get("npcs", []) as Array
	var village_values := value.get("villages", []) as Array
	if npc_values.size() > MAX_NPC_RECORDS or village_values.size() > MAX_VILLAGE_RECORDS:
		return _fail("关系状态记录超过上限")
	var restored_npcs := {}
	for value_npc in npc_values:
		if not value_npc is Dictionary:
			return _fail("NPC 关系记录必须是对象")
		var npc := value_npc as Dictionary
		var npc_id := String(npc.get("npc_id", ""))
		var claimed_value: Variant = npc.get("claimed_rewards", [])
		if npc_id.is_empty() or restored_npcs.has(npc_id) or not claimed_value is Array \
				or int(npc.get("affection", -101)) < -100 or int(npc.get("affection", 101)) > 100 \
				or int(npc.get("last_gift_day", -1)) < 0 or int(npc.get("gift_count", -1)) < 0:
			return _fail("NPC 关系记录字段无效")
		var claimed: Array[String] = []
		for reward_value in claimed_value as Array:
			var reward_id := String(reward_value)
			if reward_id.is_empty() or claimed.has(reward_id):
				return _fail("NPC 关系奖励记录无效")
			claimed.append(reward_id)
		claimed.sort()
		restored_npcs[npc_id] = {
			"npc_id": npc_id,
			"affection": int(npc["affection"]),
			"last_gift_day": int(npc["last_gift_day"]),
			"gift_count": int(npc["gift_count"]),
			"claimed_rewards": claimed,
		}
	var restored_villages := {}
	for value_village in village_values:
		if not value_village is Dictionary:
			return _fail("村庄声望记录必须是对象")
		var village := value_village as Dictionary
		var village_id := String(village.get("village_id", ""))
		var reputation := int(village.get("reputation", -101))
		if village_id.is_empty() or restored_villages.has(village_id) or reputation < -100 or reputation > 100:
			return _fail("村庄声望记录字段无效")
		restored_villages[village_id] = {"village_id": village_id, "reputation": reputation}
	_npcs = restored_npcs
	_villages = restored_villages
	last_error = ""
	return true


func _npc_record(npc_id: String) -> Dictionary:
	return (_npcs.get(npc_id, {
		"npc_id": npc_id,
		"affection": 0,
		"last_gift_day": 0,
		"gift_count": 0,
		"claimed_rewards": [],
	}) as Dictionary).duplicate(true)


func _village_record(village_id: String) -> Dictionary:
	return (_villages.get(village_id, {"village_id": village_id, "reputation": 0}) as Dictionary).duplicate(true)


func _fail(message: String) -> bool:
	last_error = message
	return false
