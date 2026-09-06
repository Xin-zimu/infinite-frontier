class_name FactionState
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_CONTROL_POINTS := 512
const MAX_DISCOVERIES := 4096

var last_error := ""
var _standings: Dictionary = {}
var _control_points: Dictionary = {}
var _discoveries: Dictionary = {}
var _events: Array[Dictionary] = []
var _next_event_id := 1
var _item_catalog := ItemCatalog.new()


func _init(catalog := FactionCatalog.new()) -> void:
	_reset(catalog)


func standing(faction_id: StringName, catalog: FactionCatalog) -> int:
	return int(_standings.get(String(faction_id), catalog.default_standing(faction_id)))


func tier_id(faction_id: StringName, catalog: FactionCatalog) -> StringName:
	return catalog.tier_id(standing(faction_id, catalog))


func adjust(faction_id: StringName, delta: int, source: String, catalog: FactionCatalog) -> Dictionary:
	if not catalog.is_valid() or not catalog.has_faction(faction_id) or delta == 0 or source.strip_edges().is_empty():
		last_error = "阵营声望变更参数无效"
		return {"ok": false, "changed": false, "message": last_error}
	var before := standing(faction_id, catalog)
	var after := clampi(before + delta, catalog.standing_minimum(), catalog.standing_maximum())
	_standings[String(faction_id)] = after
	var actual_delta := after - before
	if actual_delta != 0:
		_append_event(faction_id, actual_delta, before, after, source.strip_edges(), catalog)
	last_error = ""
	return {
		"ok": true,
		"changed": actual_delta != 0,
		"faction_id": String(faction_id),
		"before": before,
		"after": after,
		"delta": actual_delta,
		"tier_id": String(catalog.tier_id(after)),
	}


func record_trade(role_id: StringName, catalog: FactionCatalog) -> Dictionary:
	var faction_id := catalog.role_faction(role_id)
	if faction_id.is_empty():
		return {"ok": false, "changed": false, "message": "该 NPC 不属于已知阵营"}
	return adjust(faction_id, catalog.action_value(&"trade"), "trade:%s" % role_id, catalog)


func record_quest(role_id: StringName, catalog: FactionCatalog) -> Dictionary:
	var faction_id := catalog.role_faction(role_id)
	if faction_id.is_empty():
		return {"ok": false, "changed": false, "message": "任务发布者不属于已知阵营"}
	return adjust(faction_id, catalog.action_value(&"quest"), "quest:%s" % role_id, catalog)


func record_discovery(marker_id: String, marker_type: StringName, catalog: FactionCatalog) -> Dictionary:
	var clean_id := marker_id.strip_edges()
	if clean_id.is_empty() or String(marker_type).is_empty():
		last_error = "探索标记无效"
		return {"ok": false, "changed": false, "message": last_error}
	if _discoveries.has(clean_id):
		last_error = ""
		return {"ok": true, "changed": false, "message": "探索声望已记录"}
	if _discoveries.size() >= MAX_DISCOVERIES:
		last_error = "探索声望记录超过上限"
		return {"ok": false, "changed": false, "message": last_error}
	_discoveries[clean_id] = String(marker_type)
	if marker_type == &"village":
		register_control_point(clean_id, marker_type, &"frontier_union", 100, catalog)
	var result := adjust(&"pathfinders", catalog.action_value(&"discovery"), "discovery:%s:%s" % [marker_type, clean_id], catalog)
	result["changed"] = true
	result["discovery_recorded"] = true
	return result


func record_defeat(spawn_id: String, enemy_id: StringName, catalog: FactionCatalog) -> Dictionary:
	var faction_id := catalog.enemy_faction(enemy_id)
	if faction_id.is_empty():
		return {"ok": true, "changed": false, "changes": []}
	var changes: Array[Dictionary] = []
	changes.append(adjust(faction_id, catalog.action_value(&"member_defeat"), "defeat:%s:%s" % [enemy_id, spawn_id], catalog))
	if catalog.relation(faction_id, &"frontier_union") < 0:
		changes.append(adjust(&"frontier_union", catalog.action_value(&"hostile_defeat"), "hostile_defeat:%s:%s" % [enemy_id, spawn_id], catalog))
	return {"ok": true, "changed": true, "changes": changes}


func register_control_point(
	point_id: String,
	marker_type: StringName,
	owner_faction_id: StringName,
	influence: int,
	catalog: FactionCatalog
) -> bool:
	var clean_id := point_id.strip_edges()
	if clean_id.is_empty() or String(marker_type).is_empty() or not catalog.has_faction(owner_faction_id) \
			or influence < 0 or influence > 100:
		last_error = "控制点参数无效"
		return false
	if _control_points.has(clean_id):
		last_error = ""
		return true
	if _control_points.size() >= MAX_CONTROL_POINTS:
		last_error = "控制点数量超过上限"
		return false
	_control_points[clean_id] = {
		"point_id": clean_id,
		"marker_type": String(marker_type),
		"owner_faction_id": String(owner_faction_id),
		"challenger_faction_id": "",
		"influence": influence,
	}
	last_error = ""
	return true


func control_point(point_id: String) -> Dictionary:
	return (_control_points.get(point_id, {}) as Dictionary).duplicate(true)


func contest_control_point(point_id: String, faction_id: StringName, amount: int, catalog: FactionCatalog) -> Dictionary:
	if not _control_points.has(point_id) or not catalog.has_faction(faction_id) or amount < 1 or amount > 100:
		last_error = "控制点争夺参数无效"
		return {"ok": false, "captured": false, "message": last_error}
	var point := (_control_points[point_id] as Dictionary).duplicate(true)
	var owner_id := StringName(point["owner_faction_id"])
	if owner_id == faction_id:
		point["influence"] = mini(100, int(point["influence"]) + amount)
		if int(point["influence"]) == 100:
			point["challenger_faction_id"] = ""
		_control_points[point_id] = point
		last_error = ""
		return {"ok": true, "captured": false, "point": point.duplicate(true)}
	if catalog.relation(owner_id, faction_id) >= 0:
		last_error = "友好阵营不能争夺该控制点"
		return {"ok": false, "captured": false, "message": last_error}
	if StringName(point.get("challenger_faction_id", "")) != faction_id:
		point["challenger_faction_id"] = String(faction_id)
		point["influence"] = 100
	var remaining := maxi(0, int(point["influence"]) - amount)
	var captured := remaining == 0
	if captured:
		point["owner_faction_id"] = String(faction_id)
		point["challenger_faction_id"] = ""
		point["influence"] = 100
	else:
		point["influence"] = remaining
	_control_points[point_id] = point
	last_error = ""
	return {"ok": true, "captured": captured, "point": point.duplicate(true)}


func shop_offers(faction_id: StringName, catalog: FactionCatalog) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current_standing := standing(faction_id, catalog)
	var current_rank := catalog.tier_rank(catalog.tier_id(current_standing))
	for value in catalog.shop_offers(faction_id):
		var offer := value.duplicate(true)
		var required_tier := StringName(offer["required_tier"])
		offer["base_price"] = int(offer["price"])
		offer["price"] = catalog.adjusted_shop_price(int(offer["price"]), current_standing)
		offer["display_name"] = _item_catalog.display_name(StringName(offer["item_id"]))
		offer["required_tier_display_name"] = String(catalog.tier(required_tier).get("display_name", required_tier))
		offer["unlocked"] = current_rank >= catalog.tier_rank(required_tier)
		result.append(offer)
	return result


func status_snapshot(catalog: FactionCatalog) -> Dictionary:
	var faction_views: Array[Dictionary] = []
	for faction_id in catalog.faction_ids():
		var definition := catalog.faction(faction_id)
		var standing_value := standing(faction_id, catalog)
		var tier_value := catalog.tier_id(standing_value)
		var tier_definition := catalog.tier(tier_value)
		var relations: Array[Dictionary] = []
		for other_id in catalog.faction_ids():
			if other_id == faction_id:
				continue
			relations.append({
				"faction_id": String(other_id),
				"display_name": String(catalog.faction(other_id).get("display_name", other_id)),
				"value": catalog.relation(faction_id, other_id),
			})
		faction_views.append({
			"faction_id": String(faction_id),
			"display_name": String(definition.get("display_name", faction_id)),
			"description": String(definition.get("description", "")),
			"color": String(definition.get("color", "9fc2cf")),
			"standing": standing_value,
			"tier_id": String(tier_value),
			"tier_display_name": String(tier_definition.get("display_name", tier_value)),
			"tier_color": String(tier_definition.get("color", "9fc2cf")),
			"relations": relations,
			"shop": shop_offers(faction_id, catalog),
		})
	var points: Array[Dictionary] = []
	for value in _control_points.values():
		points.append((value as Dictionary).duplicate(true))
	points.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["point_id"]) < String(b["point_id"]))
	return {
		"factions": faction_views,
		"control_points": points,
		"events": _events.duplicate(true),
		"discovery_count": _discoveries.size(),
	}


func persistence_snapshot() -> Dictionary:
	var standings: Array[Dictionary] = []
	for faction_id in _standings.keys():
		standings.append({"faction_id": String(faction_id), "standing": int(_standings[faction_id])})
	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["faction_id"]) < String(b["faction_id"]))
	var points: Array[Dictionary] = []
	for value in _control_points.values():
		points.append((value as Dictionary).duplicate(true))
	points.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["point_id"]) < String(b["point_id"]))
	var discoveries: Array[String] = []
	for marker_id in _discoveries.keys():
		discoveries.append(String(marker_id))
	discoveries.sort()
	return {
		"schema_version": SCHEMA_VERSION,
		"standings": standings,
		"control_points": points,
		"discoveries": discoveries,
		"events": _events.duplicate(true),
		"next_event_id": _next_event_id,
	}


func restore_snapshot(value: Dictionary, catalog: FactionCatalog) -> bool:
	if value.is_empty():
		_reset(catalog)
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		return _fail("阵营状态格式无效")
	for key in ["standings", "control_points", "discoveries", "events"]:
		if not value.get(key, []) is Array:
			return _fail("阵营状态列表格式无效")
	var standing_values := value["standings"] as Array
	if standing_values.size() != catalog.faction_ids().size():
		return _fail("阵营声望记录不完整")
	var restored_standings := {}
	for standing_value in standing_values:
		if not standing_value is Dictionary:
			return _fail("阵营声望记录必须是对象")
		var record := standing_value as Dictionary
		var faction_id := StringName(record.get("faction_id", ""))
		var amount := int(record.get("standing", catalog.standing_minimum() - 1))
		if not catalog.has_faction(faction_id) or restored_standings.has(String(faction_id)) \
				or amount < catalog.standing_minimum() or amount > catalog.standing_maximum():
			return _fail("阵营声望记录字段无效")
		restored_standings[String(faction_id)] = amount
	var point_values := value["control_points"] as Array
	if point_values.size() > MAX_CONTROL_POINTS:
		return _fail("控制点数量超过上限")
	var restored_points := {}
	for point_value in point_values:
		if not point_value is Dictionary:
			return _fail("控制点记录必须是对象")
		var point := point_value as Dictionary
		var point_id := String(point.get("point_id", "")).strip_edges()
		var marker_type := String(point.get("marker_type", "")).strip_edges()
		var owner := StringName(point.get("owner_faction_id", ""))
		var challenger := StringName(point.get("challenger_faction_id", ""))
		var influence := int(point.get("influence", -1))
		if point_id.is_empty() or marker_type.is_empty() or restored_points.has(point_id) \
				or not catalog.has_faction(owner) or (not challenger.is_empty() and (not catalog.has_faction(challenger) or challenger == owner)) \
				or influence < 0 or influence > 100 \
				or (challenger.is_empty() and influence != 100) \
				or (not challenger.is_empty() and (influence <= 0 or influence >= 100)):
			return _fail("控制点记录字段无效")
		restored_points[point_id] = {
			"point_id": point_id,
			"marker_type": marker_type,
			"owner_faction_id": String(owner),
			"challenger_faction_id": String(challenger),
			"influence": influence,
		}
	var discovery_values := value["discoveries"] as Array
	if discovery_values.size() > MAX_DISCOVERIES:
		return _fail("探索声望记录超过上限")
	var restored_discoveries := {}
	for discovery_value in discovery_values:
		var marker_id := String(discovery_value).strip_edges()
		if marker_id.is_empty() or restored_discoveries.has(marker_id):
			return _fail("探索声望记录字段无效")
		restored_discoveries[marker_id] = "restored"
	var event_values := value["events"] as Array
	if event_values.size() > catalog.event_log_limit():
		return _fail("阵营事件记录超过上限")
	var restored_events: Array[Dictionary] = []
	var previous_event_id := 0
	for event_value in event_values:
		if not event_value is Dictionary:
			return _fail("阵营事件记录必须是对象")
		var event := event_value as Dictionary
		var event_id := int(event.get("event_id", 0))
		var faction_id := StringName(event.get("faction_id", ""))
		var before := int(event.get("before", catalog.standing_minimum() - 1))
		var after := int(event.get("after", catalog.standing_minimum() - 1))
		var delta := int(event.get("delta", 0))
		if event_id <= previous_event_id or not catalog.has_faction(faction_id) or delta == 0 \
				or before < catalog.standing_minimum() or before > catalog.standing_maximum() \
				or after < catalog.standing_minimum() or after > catalog.standing_maximum() \
				or after - before != delta or String(event.get("source", "")).strip_edges().is_empty():
			return _fail("阵营事件记录字段无效")
		previous_event_id = event_id
		restored_events.append({
			"event_id": event_id,
			"faction_id": String(faction_id),
			"delta": delta,
			"before": before,
			"after": after,
			"source": String(event["source"]),
		})
	var requested_next := int(value.get("next_event_id", previous_event_id + 1))
	if requested_next <= previous_event_id:
		return _fail("阵营事件序号无效")
	_standings = restored_standings
	_control_points = restored_points
	_discoveries = restored_discoveries
	_events = restored_events
	_next_event_id = requested_next
	last_error = ""
	return true


func _reset(catalog: FactionCatalog) -> void:
	_standings.clear()
	_control_points.clear()
	_discoveries.clear()
	_events.clear()
	_next_event_id = 1
	if catalog != null and catalog.is_valid():
		for faction_id in catalog.faction_ids():
			_standings[String(faction_id)] = catalog.default_standing(faction_id)


func _append_event(
	faction_id: StringName,
	delta: int,
	before: int,
	after: int,
	source: String,
	catalog: FactionCatalog
) -> void:
	_events.append({
		"event_id": _next_event_id,
		"faction_id": String(faction_id),
		"delta": delta,
		"before": before,
		"after": after,
		"source": source,
	})
	_next_event_id += 1
	while _events.size() > catalog.event_log_limit():
		_events.pop_front()


func _fail(message: String) -> bool:
	last_error = message
	return false
