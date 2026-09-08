class_name RegionProgressionCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/region_progression.json"
const REQUIRED_SOURCE_IDS := [
	&"region_discovered",
	&"elite_defeated",
	&"quest_claimed",
	&"world_choice",
	&"world_event_completed",
	&"dungeon_completed",
	&"regional_boss_defeated",
]
const REQUIRED_BOSS_IDS := [&"grove_titan", &"dune_behemoth", &"frost_wyrm", &"tide_sovereign"]

var _valid := false
var _error_message := ""
var _region_size_chunks := 6
var _maximum_sources := 4096
var _tiers: Dictionary = {}
var _scaling: Dictionary = {}
var _gear_scores: Dictionary = {}
var _sources: Dictionary = {}
var _world_levels: Array[Dictionary] = []
var _boss_unlocks: Array[Dictionary] = []
var _items := ItemCatalog.new()


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func region_size_chunks() -> int:
	return _region_size_chunks


func maximum_sources() -> int:
	return _maximum_sources


func maximum_danger_level() -> int:
	return _tiers.size()


func danger_tier(level: int) -> Dictionary:
	return (_tiers.get(clampi(level, 1, maximum_danger_level()), {}) as Dictionary).duplicate(true)


func danger_level_for_region(region_coordinate: Vector2i) -> int:
	var ring := maxi(absi(region_coordinate.x), absi(region_coordinate.y))
	return clampi(1 + floori(float(ring) / 2.0), 1, maximum_danger_level())


func region_id(region_coordinate: Vector2i) -> String:
	return "region:%d:%d" % [region_coordinate.x, region_coordinate.y]


func parse_region_id(value: String) -> Vector2i:
	var parts := value.split(":")
	if parts.size() != 3 or parts[0] != "region" or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return Vector2i(0x7fffffff, 0x7fffffff)
	return Vector2i(int(parts[1]), int(parts[2]))


func scaling_value(key: StringName, fallback: float) -> float:
	return float(_scaling.get(String(key), fallback))


func elite_drop_multiplier() -> int:
	return int(_scaling.get("elite_drop_multiplier", 2))


func gear_score(inventory_snapshot: Dictionary) -> int:
	var best_by_slot := {}
	for value in inventory_snapshot.get("slots", []) as Array:
		if not value is Dictionary:
			continue
		var item_id := String((value as Dictionary).get("item_id", ""))
		if item_id.is_empty() or not _gear_scores.has(item_id):
			continue
		var score := _gear_scores[item_id] as Dictionary
		var slot := String(score["slot"])
		best_by_slot[slot] = maxi(int(best_by_slot.get(slot, 0)), int(score["score"]))
	var result := 0
	for value in best_by_slot.values():
		result += int(value)
	return result


func progress_source(source_id: StringName) -> Dictionary:
	return (_sources.get(String(source_id), {}) as Dictionary).duplicate(true)


func progress_points(source_id: StringName) -> int:
	return int(progress_source(source_id).get("points", 0))


func world_level(points: int) -> Dictionary:
	var result := _world_levels[0].duplicate(true) if not _world_levels.is_empty() else {}
	for value in _world_levels:
		if points >= int(value["minimum_points"]):
			result = value.duplicate(true)
	return result


func boss_unlock_views(points: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _boss_unlocks:
		var view := value.duplicate(true)
		view["unlocked"] = points >= int(view["required_points"])
		result.append(view)
	return result


func unlocked_boss_ids(points: int) -> Array[String]:
	var result: Array[String] = []
	for view in boss_unlock_views(points):
		if bool(view["unlocked"]):
			result.append(String(view["boss_id"]))
	return result


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open region progression configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Region progression configuration is not an object")
		return
	var root := parsed as Dictionary
	_region_size_chunks = int(root.get("region_size_chunks", 0))
	_maximum_sources = int(root.get("maximum_sources", 0))
	if int(root.get("schema_version", 0)) != 1 or _region_size_chunks < 3 or _region_size_chunks > 16 \
			or _maximum_sources < 128 or _maximum_sources > 16384:
		_fail("Region progression schema or bounds are invalid")
		return
	if not _load_tiers(root.get("danger_tiers", [])) or not _load_scaling(root.get("scaling", {})) \
			or not _load_gear(root.get("gear_scores", [])) or not _load_sources(root.get("progress_sources", [])) \
			or not _load_world_levels(root.get("world_levels", [])) or not _load_boss_unlocks(root.get("boss_unlocks", [])):
		return
	_valid = true


func _load_tiers(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 5:
		return _fail("Region progression requires exactly five danger tiers")
	var previous_max := 0
	for raw in value as Array:
		if not raw is Dictionary:
			return _fail("Danger tier must be an object")
		var tier := (raw as Dictionary).duplicate(true)
		var level := int(tier.get("level", 0))
		var minimum := int(tier.get("enemy_level_min", 0))
		var maximum := int(tier.get("enemy_level_max", 0))
		var rewards: Variant = tier.get("rewards", [])
		if level != _tiers.size() + 1 or minimum < 1 or maximum < minimum or minimum < previous_max \
				or int(tier.get("recommended_gear_score", -1)) < 0 \
				or float(tier.get("elite_chance", -1.0)) < 0.0 or float(tier.get("elite_chance", 1.0)) > 0.35 \
				or int(tier.get("reward_required_elites", -1)) < 0 \
				or int(tier.get("reward_progress_requirement", -1)) < 0 \
				or String(tier.get("display_name", "")).is_empty() or not rewards is Array or (rewards as Array).is_empty():
			return _fail("Danger tier fields are invalid")
		for reward_value in rewards as Array:
			if not reward_value is Dictionary:
				return _fail("Region reward entry must be an object")
			var reward := reward_value as Dictionary
			if not _items.has_item(StringName(reward.get("item_id", ""))) or int(reward.get("quantity", 0)) < 1:
				return _fail("Region reward item or quantity is invalid")
		previous_max = maximum
		_tiers[level] = tier
	return true


func _load_scaling(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("Enemy scaling configuration must be an object")
	_scaling = (value as Dictionary).duplicate(true)
	for key in ["health_per_level", "attack_per_level", "defense_per_level"]:
		if float(_scaling.get(key, -1.0)) < 0.0 or float(_scaling.get(key, 1.0)) > 0.20:
			return _fail("Per-level enemy scaling is outside supported bounds")
	for key in ["elite_health_multiplier", "elite_attack_multiplier", "elite_defense_multiplier"]:
		if float(_scaling.get(key, 0.0)) < 1.0 or float(_scaling.get(key, 0.0)) > 3.0:
			return _fail("Elite enemy scaling is outside supported bounds")
	if elite_drop_multiplier() < 1 or elite_drop_multiplier() > 4:
		return _fail("Elite drop multiplier is outside supported bounds")
	return true


func _load_gear(value: Variant) -> bool:
	if not value is Array or (value as Array).is_empty():
		return _fail("Gear-score mapping must not be empty")
	for raw in value as Array:
		if not raw is Dictionary:
			return _fail("Gear-score entry must be an object")
		var entry := (raw as Dictionary).duplicate(true)
		var item_id := String(entry.get("item_id", ""))
		if not _items.has_item(StringName(item_id)) or _gear_scores.has(item_id) \
				or String(entry.get("slot", "")).is_empty() or int(entry.get("score", 0)) < 1:
			return _fail("Gear-score entry is invalid or duplicated")
		_gear_scores[item_id] = entry
	return true


func _load_sources(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != REQUIRED_SOURCE_IDS.size():
		return _fail("World progress requires every source type")
	for raw in value as Array:
		if not raw is Dictionary:
			return _fail("World-progress source must be an object")
		var entry := (raw as Dictionary).duplicate(true)
		var source_id := StringName(entry.get("id", ""))
		if source_id not in REQUIRED_SOURCE_IDS or _sources.has(String(source_id)) \
				or String(entry.get("display_name", "")).is_empty() or int(entry.get("points", 0)) < 1:
			return _fail("World-progress source is invalid or duplicated")
		_sources[String(source_id)] = entry
	return true


func _load_world_levels(value: Variant) -> bool:
	if not value is Array or (value as Array).size() < 2:
		return _fail("World levels are incomplete")
	var previous_points := -1
	for raw in value as Array:
		if not raw is Dictionary:
			return _fail("World-level entry must be an object")
		var entry := (raw as Dictionary).duplicate(true)
		if int(entry.get("level", 0)) != _world_levels.size() + 1 \
				or int(entry.get("minimum_points", -1)) <= previous_points \
				or String(entry.get("display_name", "")).is_empty():
			return _fail("World-level sequence is invalid")
		previous_points = int(entry["minimum_points"])
		_world_levels.append(entry)
	return int(_world_levels[0]["minimum_points"]) == 0 or _fail("The first world level must begin at zero")


func _load_boss_unlocks(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != REQUIRED_BOSS_IDS.size():
		return _fail("Boss unlock configuration must contain exactly three regional Bosses")
	var seen := {}
	var regional_catalog := RegionalBossCatalog.new()
	for raw in value as Array:
		if not raw is Dictionary:
			return _fail("Boss unlock entry must be an object")
		var entry := (raw as Dictionary).duplicate(true)
		var boss_id := StringName(entry.get("boss_id", ""))
		if boss_id not in REQUIRED_BOSS_IDS or seen.has(String(boss_id)) or regional_catalog.boss(boss_id).is_empty() \
				or int(entry.get("required_points", -1)) < 0 or String(entry.get("display_name", "")).is_empty():
			return _fail("Boss unlock entry is invalid or duplicated")
		seen[String(boss_id)] = true
		_boss_unlocks.append(entry)
	return true


func _fail(message: String) -> bool:
	_error_message = message
	push_error(message)
	return false
