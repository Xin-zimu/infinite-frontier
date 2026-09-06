class_name RegionProgressionModel
extends RefCounted

var _world_seed := 0
var _catalog: RegionProgressionCatalog


func _init(world_seed: int, catalog := RegionProgressionCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func region_coordinate(chunk_position: Vector2i) -> Vector2i:
	var size := _catalog.region_size_chunks()
	return Vector2i(floori(float(chunk_position.x) / float(size)), floori(float(chunk_position.y) / float(size)))


func region_profile(chunk_position: Vector2i) -> Dictionary:
	var coordinate := region_coordinate(chunk_position)
	var danger := _catalog.danger_level_for_region(coordinate)
	var tier := _catalog.danger_tier(danger)
	return {
		"region_id": _catalog.region_id(coordinate),
		"region_coordinate": coordinate,
		"display_name": "边境区 %+d, %+d" % [coordinate.x, coordinate.y],
		"danger_level": danger,
		"danger_display_name": String(tier["display_name"]),
		"enemy_level_min": int(tier["enemy_level_min"]),
		"enemy_level_max": int(tier["enemy_level_max"]),
		"recommended_gear_score": int(tier["recommended_gear_score"]),
		"elite_chance": float(tier["elite_chance"]),
		"reward_required_elites": int(tier["reward_required_elites"]),
		"reward_progress_requirement": int(tier["reward_progress_requirement"]),
		"rewards": (tier["rewards"] as Array).duplicate(true),
	}


func enemy_profile(chunk_position: Vector2i, spawn_id: String, role: StringName, world_layer: StringName) -> Dictionary:
	var region := region_profile(chunk_position)
	var minimum := int(region["enemy_level_min"])
	var maximum := int(region["enemy_level_max"])
	if world_layer == &"underground":
		minimum += 1
		maximum += 1
	elif world_layer == &"dungeon":
		minimum += 2
		maximum += 2
	var stable := WorldSeed.from_text("%d|enemy-progression|%s|v1" % [_world_seed, spawn_id])
	var level := minimum + int(stable % maxi(1, maximum - minimum + 1))
	var roll := float((stable >> 16) & 0xffff) / 65535.0
	var elite := role == &"elite" or (role == &"normal" and roll < float(region["elite_chance"]))
	var health_multiplier := 1.0 + float(level - 1) * _catalog.scaling_value(&"health_per_level", 0.0)
	var attack_multiplier := 1.0 + float(level - 1) * _catalog.scaling_value(&"attack_per_level", 0.0)
	var defense_multiplier := 1.0 + float(level - 1) * _catalog.scaling_value(&"defense_per_level", 0.0)
	if elite:
		health_multiplier *= _catalog.scaling_value(&"elite_health_multiplier", 1.0)
		attack_multiplier *= _catalog.scaling_value(&"elite_attack_multiplier", 1.0)
		defense_multiplier *= _catalog.scaling_value(&"elite_defense_multiplier", 1.0)
	return {
		"region_id": String(region["region_id"]),
		"danger_level": int(region["danger_level"]),
		"level": level,
		"elite": elite,
		"health_multiplier": health_multiplier,
		"attack_multiplier": attack_multiplier,
		"defense_multiplier": defense_multiplier,
		"drop_multiplier": _catalog.elite_drop_multiplier() if elite else 1,
	}
