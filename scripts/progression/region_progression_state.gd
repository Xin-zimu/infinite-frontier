class_name RegionProgressionState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _sources: Dictionary = {}
var _regions: Dictionary = {}


func world_progress_points() -> int:
	var result := 0
	for value in _sources.values():
		result += int((value as Dictionary)["points"])
	return result


func source_count() -> int:
	return _sources.size()


func region_count() -> int:
	return _regions.size()


func record_source(source_type: StringName, source_id: String, catalog: RegionProgressionCatalog) -> Dictionary:
	var definition := catalog.progress_source(source_type)
	var clean_id := source_id.strip_edges()
	if definition.is_empty() or clean_id.is_empty() or clean_id.length() > 192:
		return {"changed": false, "points": world_progress_points()}
	var key := "%s:%s" % [source_type, clean_id]
	if _sources.has(key) or _sources.size() >= catalog.maximum_sources():
		return {"changed": false, "points": world_progress_points()}
	_sources[key] = {
		"source_type": String(source_type),
		"source_id": clean_id,
		"points": int(definition["points"]),
	}
	return {"changed": true, "points": world_progress_points(), "gained": int(definition["points"])}


func discover_region(profile: Dictionary, catalog: RegionProgressionCatalog) -> Dictionary:
	var region_id := String(profile.get("region_id", ""))
	var danger := int(profile.get("danger_level", 0))
	if not _is_valid_region(region_id, danger, catalog):
		return {"changed": false, "points": world_progress_points()}
	if _regions.has(region_id):
		return {"changed": false, "points": world_progress_points(), "gained": 0}
	var source_result := record_source(&"region_discovered", region_id, catalog)
	if not bool(source_result.get("changed", false)):
		return source_result
	_regions[region_id] = {"region_id": region_id, "danger_level": danger, "reward_claimed": false}
	return {
		"changed": true,
		"points": world_progress_points(),
		"gained": int(source_result.get("gained", 0)),
	}


func record_elite_defeat(profile: Dictionary, spawn_id: String, catalog: RegionProgressionCatalog) -> Dictionary:
	var discovery := discover_region(profile, catalog)
	var region_id := String(profile.get("region_id", ""))
	if not _regions.has(region_id):
		return {"changed": false, "points": world_progress_points()}
	var elite_result := record_source(&"elite_defeated", "%s|%s" % [region_id, spawn_id], catalog)
	return {
		"changed": bool(discovery.get("changed", false)) or bool(elite_result.get("changed", false)),
		"points": world_progress_points(),
		"gained": int(discovery.get("gained", 0)) + int(elite_result.get("gained", 0)),
	}


func elite_defeats(region_id: String) -> int:
	var prefix := "%s|" % region_id
	var result := 0
	for value in _sources.values():
		var source := value as Dictionary
		if String(source["source_type"]) == "elite_defeated" and String(source["source_id"]).begins_with(prefix):
			result += 1
	return result


func can_claim_region_reward(region_id: String, catalog: RegionProgressionCatalog) -> bool:
	var record := _regions.get(region_id, {}) as Dictionary
	if record.is_empty() or bool(record.get("reward_claimed", false)):
		return false
	var tier := catalog.danger_tier(int(record["danger_level"]))
	return elite_defeats(region_id) >= int(tier["reward_required_elites"]) \
		and world_progress_points() >= int(tier["reward_progress_requirement"])


func claim_region_reward(region_id: String, inventory: InventoryModel, catalog: RegionProgressionCatalog) -> Dictionary:
	if not can_claim_region_reward(region_id, catalog):
		return {"ok": false, "message": "区域奖励条件尚未完成"}
	var record := _regions[region_id] as Dictionary
	var tier := catalog.danger_tier(int(record["danger_level"]))
	var before := inventory.snapshot()
	for value in tier["rewards"] as Array:
		var reward := value as Dictionary
		var result := inventory.add_item(StringName(reward["item_id"]), int(reward["quantity"]))
		if int(result.get("remainder", 0)) > 0:
			inventory.restore_snapshot(before)
			return {"ok": false, "message": "背包空间不足，区域奖励未领取"}
	record["reward_claimed"] = true
	return {"ok": true, "message": "区域奖励已领取", "rewards": (tier["rewards"] as Array).duplicate(true)}


func status_snapshot(current_profile: Dictionary, gear_score: int, catalog: RegionProgressionCatalog) -> Dictionary:
	var points := world_progress_points()
	var world_level := catalog.world_level(points)
	var region_id := String(current_profile.get("region_id", ""))
	var record := _regions.get(region_id, {}) as Dictionary
	var required_elites := int(current_profile.get("reward_required_elites", 0))
	var required_points := int(current_profile.get("reward_progress_requirement", 0))
	return {
		"schema_version": SCHEMA_VERSION,
		"current_region": current_profile.duplicate(true),
		"gear_score": maxi(0, gear_score),
		"gear_ready": gear_score >= int(current_profile.get("recommended_gear_score", 0)),
		"world_progress_points": points,
		"world_level": int(world_level.get("level", 1)),
		"world_level_display_name": String(world_level.get("display_name", "初抵边境")),
		"source_count": _sources.size(),
		"discovered_regions": _regions.size(),
		"region_elite_defeats": elite_defeats(region_id),
		"reward_required_elites": required_elites,
		"reward_required_points": required_points,
		"reward_claimed": bool(record.get("reward_claimed", false)),
		"reward_available": can_claim_region_reward(region_id, catalog),
		"boss_unlocks": catalog.boss_unlock_views(points),
		"unlocked_boss_ids": catalog.unlocked_boss_ids(points),
	}


func persistence_snapshot() -> Dictionary:
	var sources: Array[Dictionary] = []
	for value in _sources.values():
		sources.append((value as Dictionary).duplicate(true))
	sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return "%s:%s" % [a["source_type"], a["source_id"]] < "%s:%s" % [b["source_type"], b["source_id"]]
	)
	var regions: Array[Dictionary] = []
	for value in _regions.values():
		regions.append((value as Dictionary).duplicate(true))
	regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["region_id"]) < String(b["region_id"]))
	return {"schema_version": SCHEMA_VERSION, "sources": sources, "regions": regions}


func restore_snapshot(value: Dictionary, catalog := RegionProgressionCatalog.new()) -> bool:
	last_error = ""
	if not catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION \
			or not value.get("sources", []) is Array or not value.get("regions", []) is Array:
		return _fail("区域进度存档结构无效")
	var source_values := value["sources"] as Array
	var region_values := value["regions"] as Array
	if source_values.size() > catalog.maximum_sources() or region_values.size() > catalog.maximum_sources():
		return _fail("区域进度存档数量超出上限")
	var restored_sources := {}
	for raw in source_values:
		if not raw is Dictionary:
			return _fail("世界进度来源记录无效")
		var source := raw as Dictionary
		var source_type := StringName(source.get("source_type", ""))
		var source_id := String(source.get("source_id", "")).strip_edges()
		var definition := catalog.progress_source(source_type)
		var key := "%s:%s" % [source_type, source_id]
		if definition.is_empty() or source_id.is_empty() or source_id.length() > 192 or restored_sources.has(key) \
				or int(source.get("points", -1)) != int(definition.get("points", 0)):
			return _fail("世界进度来源未知、重复或分值被篡改")
		restored_sources[key] = {"source_type": String(source_type), "source_id": source_id, "points": int(definition["points"])}
	var restored_regions := {}
	for raw in region_values:
		if not raw is Dictionary:
			return _fail("区域发现记录无效")
		var region := raw as Dictionary
		var region_id := String(region.get("region_id", ""))
		var danger := int(region.get("danger_level", 0))
		if restored_regions.has(region_id) or not _is_valid_region(region_id, danger, catalog) \
				or not restored_sources.has("region_discovered:%s" % region_id):
			return _fail("区域发现记录未知、重复或缺少来源")
		restored_regions[region_id] = {"region_id": region_id, "danger_level": danger, "reward_claimed": bool(region.get("reward_claimed", false))}
	for source in restored_sources.values():
		if String((source as Dictionary)["source_type"]) != "elite_defeated":
			continue
		var source_id := String((source as Dictionary)["source_id"])
		var separator := source_id.find("|")
		if separator <= 0 or not restored_regions.has(source_id.left(separator)):
			return _fail("精英击败来源没有对应区域")
	_sources = restored_sources
	_regions = restored_regions
	return true


func _is_valid_region(region_id: String, danger: int, catalog: RegionProgressionCatalog) -> bool:
	var coordinate := catalog.parse_region_id(region_id)
	return coordinate.x != 0x7fffffff and danger == catalog.danger_level_for_region(coordinate)


func _fail(message: String) -> bool:
	last_error = message
	return false
