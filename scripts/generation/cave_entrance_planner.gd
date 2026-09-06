class_name CaveEntrancePlanner
extends RefCounted

var _world_seed: int
var _catalog: CaveCatalog


func _init(world_seed: int, catalog := CaveCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func entrance_for_region(region: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	var region_chunks := _catalog.entrance_region_chunks()
	var span := region_chunks * WorldCoordinates.CHUNK_SIZE
	var origin := region * span
	var stable_hash := WorldSeed.from_text("%d|cave-entrance|%d|%d" % [_world_seed, region.x, region.y])
	var preferred := origin + Vector2i(
		12 + posmod(int(stable_hash), span - 24),
		12 + posmod(int(stable_hash >> 24), span - 24)
	)
	var tile := _nearest_valid_surface_tile(preferred, origin, span, terrain)
	if tile == Vector2i(2147483647, 2147483647):
		return {}
	return {
		"entrance_id": "cave:%d:%d" % [region.x, region.y],
		"region": region,
		"world_tile": tile,
		"chunk_position": WorldCoordinates.tile_to_chunk(tile),
		"local": WorldCoordinates.tile_to_local(tile),
	}


func entrances_for_chunk(chunk_position: Vector2i, terrain: TerrainGenerator) -> Array[Dictionary]:
	var region_size := _catalog.entrance_region_chunks()
	var region := Vector2i(_floor_div(chunk_position.x, region_size), _floor_div(chunk_position.y, region_size))
	var entrance := entrance_for_region(region, terrain)
	if entrance.is_empty() or entrance["chunk_position"] != chunk_position:
		return []
	return [entrance]


func _nearest_valid_surface_tile(preferred: Vector2i, origin: Vector2i, span: int, terrain: TerrainGenerator) -> Vector2i:
	for radius in range(0, 49):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if radius > 0 and absi(x) != radius and absi(y) != radius:
					continue
				var tile := preferred + Vector2i(x, y)
				if tile.x < origin.x + 2 or tile.y < origin.y + 2 \
						or tile.x >= origin.x + span - 2 or tile.y >= origin.y + span - 2:
					continue
				if terrain.terrain_at(tile) != ChunkData.Terrain.LAND:
					continue
				if HydrologyGenerator.is_water(terrain.water_feature_at(tile)):
					continue
				return tile
	return Vector2i(2147483647, 2147483647)


func _floor_div(value: int, divisor: int) -> int:
	@warning_ignore("integer_division")
	var quotient: int = value / divisor
	if value < 0 and value % divisor != 0:
		quotient -= 1
	return quotient
