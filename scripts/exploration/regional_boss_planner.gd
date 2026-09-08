class_name RegionalBossPlanner
extends RefCounted

const ORIGIN_CHUNK := Vector2i(-1, -4)

var _world_seed: int
var _catalog: RegionalBossCatalog
var _terrain: TerrainGenerator
var _biomes := BiomeCatalog.new()
var _plans: Array[Dictionary] = []


func _init(world_seed: int, catalog := RegionalBossCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_terrain = TerrainGenerator.new(world_seed)


func plans() -> Array[Dictionary]:
	if _plans.is_empty():
		_build_plans()
	return _plans.duplicate(true)


func plan_for_id(boss_id: StringName) -> Dictionary:
	for plan in plans():
		if StringName(plan["id"]) == boss_id:
			return plan.duplicate(true)
	return {}


func candidates_near(chunk_position: Vector2i, radius_chunks: int, defeated_ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for plan in plans():
		if defeated_ids.has(String(plan["id"])):
			continue
		if ChunkStreamPlanner.chebyshev_distance(plan["chunk_position"] as Vector2i, chunk_position) > radius_chunks:
			continue
		result.append({
			"spawn_id": "regional_boss:%s" % plan["id"],
			"boss_id": StringName(plan["id"]),
			"enemy_id": StringName(plan["enemy_id"]),
			"world_layer": &"surface",
			"biome_id": StringName(plan["biome_id"]),
			"chunk_position": plan["chunk_position"],
			"world_tile": plan["world_tile"],
			"world_position": plan["world_position"],
		})
	return result


func _build_plans() -> void:
	if not _catalog.is_valid():
		return
	for definition in _catalog.bosses():
		var preferred := _find_candidate(definition, true)
		if preferred.is_empty():
			preferred = _find_candidate(definition, false)
		if preferred.is_empty():
			continue
		preferred["id"] = String(definition["id"])
		preferred["enemy_id"] = String(definition["enemy_id"])
		preferred["display_name"] = String(definition["display_name"])
		preferred["marker_color"] = String(definition.get("marker_color", "ffffff"))
		_plans.append(preferred)


func _find_candidate(definition: Dictionary, require_preferred: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_score := 0x7fffffffffffffff
	var minimum := int(definition["minimum_ring_chunks"])
	var maximum := int(definition["maximum_ring_chunks"])
	var preferred := definition["preferred_biomes"] as Array
	var aquatic := bool(definition.get("aquatic", false))
	for ring in range(minimum, maximum + 1):
		for offset_y in range(-ring, ring + 1):
			for offset_x in range(-ring, ring + 1):
				if maxi(absi(offset_x), absi(offset_y)) != ring:
					continue
				var chunk := ORIGIN_CHUNK + Vector2i(offset_x, offset_y)
				var stable := WorldSeed.from_text("%d|regional-boss|%s|%d|%d|generation:%d" % [_world_seed, definition["id"], chunk.x, chunk.y, GameVersion.GENERATION_VERSION])
				var local := Vector2i(5 + posmod(int(stable >> 8), 22), 5 + posmod(int(stable >> 32), 22))
				var world_tile := WorldCoordinates.chunk_local_to_tile(chunk, local)
				var terrain := _terrain.terrain_at(world_tile)
				if aquatic:
					# 水生 Boss 只锚定在开阔水域地块上。
					if terrain != ChunkData.Terrain.SHALLOW_WATER and terrain != ChunkData.Terrain.DEEP_WATER:
						continue
				elif terrain != ChunkData.Terrain.LAND or _terrain.water_feature_at(world_tile) != HydrologyGenerator.Feature.NONE:
					continue
				var biome_id := _biomes.id_for_code(_terrain.biome_at(world_tile))
				if require_preferred and not preferred.has(String(biome_id)):
					continue
				var score := stable & 0x7fffffffffffffff
				if score >= best_score:
					continue
				best_score = score
				best = {
					"chunk_position": chunk,
					"world_tile": world_tile,
					"world_position": WorldCoordinates.tile_to_world_pixel(world_tile, true),
					"biome_id": biome_id,
					"stable_score": score,
				}
	return best
