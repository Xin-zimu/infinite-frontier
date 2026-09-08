class_name EnemySpawnPlanner
extends RefCounted

var _world_seed: int
var _catalog: EnemyCatalog
var _biome_catalog := BiomeCatalog.new()
var _terrain_generator: TerrainGenerator
var _resource_generator: ResourceGenerator
var _cave_generator: CaveGenerator
var _cache: Dictionary = {}


func _init(world_seed: int, catalog := EnemyCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_terrain_generator = TerrainGenerator.new(world_seed)
	_resource_generator = ResourceGenerator.new(world_seed)
	_cave_generator = CaveGenerator.new(world_seed)


func candidates_for_chunk(chunk_position: Vector2i, phase_id: StringName = &"", world_layer: StringName = &"surface") -> Array[Dictionary]:
	if world_layer == &"dungeon":
		return []
	var cache_key := "%s:%d:%d:%s" % [world_layer, chunk_position.x, chunk_position.y, phase_id]
	if _cache.has(cache_key):
		return (_cache[cache_key] as Array).duplicate(true)
	var result: Array[Dictionary] = []
	var occupied_tiles := {}
	var cave_chunk := _cave_generator.generate_chunk(chunk_position) if world_layer == &"underground" else null
	var cave_resources := {}
	if cave_chunk != null:
		for resource_index in cave_chunk.resource_count():
			cave_resources[cave_chunk.resource_world_tile_at(resource_index)] = true
	for slot in _catalog.candidate_slots_per_chunk():
		var stable_hash := WorldSeed.from_text("%d|enemy-spawn|%s|%d|%d|%d" % [_world_seed, world_layer, chunk_position.x, chunk_position.y, slot])
		var spawn_roll := float(stable_hash & 0xffff) / 65536.0
		if spawn_roll >= _catalog.spawn_chance():
			continue
		var local := Vector2i(2 + posmod(int(stable_hash >> 16), WorldCoordinates.CHUNK_SIZE - 4), 2 + posmod(int(stable_hash >> 32), WorldCoordinates.CHUNK_SIZE - 4))
		var world_tile := WorldCoordinates.chunk_local_to_tile(chunk_position, local)
		if occupied_tiles.has(world_tile):
			continue
		var biome_id: StringName
		var enemy_roll := float((stable_hash >> 48) & 0xffff) / 65536.0
		if world_layer == &"underground":
			if cave_chunk == null or not cave_chunk.is_cave_floor(local) or cave_resources.has(world_tile) \
					or cave_chunk.cave_feature_at(local) != CaveGenerator.Feature.NONE:
				continue
			biome_id = &"mountain"
			var underground_enemy := _catalog.enemy_id_for_biome_phase_layer(biome_id, enemy_roll, phase_id, world_layer)
			if underground_enemy.is_empty():
				continue
			occupied_tiles[world_tile] = true
			result.append({
				"spawn_id": "%s:%d:%d:%s" % [world_layer, world_tile.x, world_tile.y, underground_enemy],
				"enemy_id": underground_enemy,
				"world_layer": world_layer,
				"biome_id": biome_id,
				"chunk_position": chunk_position,
				"world_tile": world_tile,
				"world_position": WorldCoordinates.tile_to_world_pixel(world_tile, true),
			})
			if result.size() >= _catalog.maximum_per_chunk():
				break
		else:
			var terrain := _terrain_generator.terrain_at(world_tile)
			biome_id = _biome_catalog.id_for_code(_terrain_generator.biome_at(world_tile))
			var enemy_id := _catalog.enemy_id_for_biome_phase_layer(biome_id, enemy_roll, phase_id, world_layer)
			if enemy_id.is_empty():
				continue
			var definition := _catalog.enemy(enemy_id)
			if terrain == ChunkData.Terrain.LAND:
				# 陆地候选拒绝水生敌人，避免它们搁浅在岛上。
				if definition != null and definition.aquatic:
					continue
				if not _resource_generator.candidate_at_world_tile(world_tile, _terrain_generator).is_empty():
					continue
			elif terrain == ChunkData.Terrain.SHALLOW_WATER or terrain == ChunkData.Terrain.DEEP_WATER:
				# 水生敌人只落在允许的水域，且不与海洋资源重叠。
				if definition == null or not definition.aquatic:
					continue
				if not _resource_generator.candidate_at_world_tile(world_tile, _terrain_generator).is_empty():
					continue
			else:
				continue
			occupied_tiles[world_tile] = true
			result.append({
				"spawn_id": "%s:%d:%d:%s" % [world_layer, world_tile.x, world_tile.y, enemy_id],
				"enemy_id": enemy_id,
				"world_layer": world_layer,
				"biome_id": biome_id,
				"chunk_position": chunk_position,
				"world_tile": world_tile,
				"world_position": WorldCoordinates.tile_to_world_pixel(world_tile, true),
			})
			if result.size() >= _catalog.maximum_per_chunk():
				break
	_cache[cache_key] = result.duplicate(true)
	return result


func candidates_for_dungeon(chunk: ChunkData, dungeon_id: String, run_state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if chunk == null or chunk.world_layer != &"dungeon":
		return result
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			var feature := chunk.dungeon_feature_at(local)
			if feature not in [DungeonGenerator.Feature.ELITE_SPAWN, DungeonGenerator.Feature.BOSS_SPAWN]:
				continue
			var world_tile := WorldCoordinates.chunk_local_to_tile(chunk.chunk_position, local)
			var spawn_id := DungeonGenerator.feature_key(dungeon_id, feature, world_tile)
			if feature == DungeonGenerator.Feature.ELITE_SPAWN and (run_state.get("defeated_elites", []) as Array).has(spawn_id):
				continue
			if feature == DungeonGenerator.Feature.BOSS_SPAWN and bool(run_state.get("boss_defeated", false)):
				continue
			var enemy_id: StringName = &"dungeon_sentinel" if feature == DungeonGenerator.Feature.ELITE_SPAWN else &"dungeon_warden"
			result.append({
				"spawn_id": spawn_id,
				"enemy_id": enemy_id,
				"world_layer": &"dungeon",
				"biome_id": &"mountain",
				"chunk_position": chunk.chunk_position,
				"world_tile": world_tile,
				"world_position": WorldCoordinates.tile_to_world_pixel(world_tile, true),
			})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["spawn_id"]) < String(b["spawn_id"]))
	return result


func cache_size() -> int:
	return _cache.size()


func retain_chunks(coordinates: Array[Vector2i], world_layer: StringName = &"surface") -> void:
	var keep_prefixes: Array[String] = []
	for coordinate in coordinates:
		keep_prefixes.append("%s:%d:%d:" % [world_layer, coordinate.x, coordinate.y])
	for coordinate_value in _cache.keys():
		var keep := false
		for prefix in keep_prefixes:
			if String(coordinate_value).begins_with(prefix):
				keep = true
				break
		if not keep:
			_cache.erase(coordinate_value)
