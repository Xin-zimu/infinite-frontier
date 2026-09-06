class_name CaveGenerator
extends RefCounted

enum Cell {
	WALL,
	FLOOR,
}

enum Feature {
	NONE,
	ENTRANCE,
	EXIT,
	TORCH,
	CHEST,
}

var _world_seed: int
var _catalog: CaveCatalog
var _resource_catalog := ResourceCatalog.new()
var _biome_catalog := BiomeCatalog.new()
var _surface_terrain: TerrainGenerator
var _entrance_planner: CaveEntrancePlanner


func _init(world_seed: int, catalog := CaveCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_surface_terrain = TerrainGenerator.new(world_seed)
	_entrance_planner = CaveEntrancePlanner.new(world_seed, catalog)


func generate_chunk(chunk_position: Vector2i) -> ChunkData:
	var result := ChunkData.new()
	result.chunk_position = chunk_position
	result.world_layer = &"underground"
	result.world_seed = _world_seed
	var cell_count := WorldCoordinates.CHUNK_SIZE * WorldCoordinates.CHUNK_SIZE
	result.base_tiles.resize(cell_count)
	result.continental_map.resize(cell_count)
	result.elevation_map.resize(cell_count)
	result.erosion_map.resize(cell_count)
	result.temperature_map.resize(cell_count)
	result.moisture_map.resize(cell_count)
	result.biome_map.resize(cell_count)
	result.water_feature_map.resize(cell_count)
	result.village_feature_map.resize(cell_count)
	result.cave_feature_map.resize(cell_count)
	var entrances := _entrance_planner.entrances_for_chunk(chunk_position, _surface_terrain)
	var entrance_locals: Array[Vector2i] = []
	for entrance in entrances:
		entrance_locals.append((entrance as Dictionary)["local"] as Vector2i)
	result.cave_cell_map = _build_cells(chunk_position, entrance_locals)
	var mountain_code := _biome_catalog.code_for_id(&"mountain")
	for index in cell_count:
		var floor_cell := result.cave_cell_map[index] == Cell.FLOOR
		result.base_tiles[index] = ChunkData.Terrain.LAND if floor_cell else ChunkData.Terrain.DEEP_WATER
		result.continental_map[index] = 180 if floor_cell else 32
		result.elevation_map[index] = 96 if floor_cell else 224
		result.erosion_map[index] = 128
		result.temperature_map[index] = 86
		result.moisture_map[index] = 164
		result.biome_map[index] = mountain_code
	for local in entrance_locals:
		result.cave_feature_map[_index(local)] = Feature.EXIT
	_add_torches(result)
	_add_chest(result)
	_add_mineral_veins(result)
	result.finalize_checksum()
	return result


func cell_at(world_tile: Vector2i) -> Cell:
	var chunk := generate_chunk(WorldCoordinates.tile_to_chunk(world_tile))
	return chunk.cave_cell_at(WorldCoordinates.tile_to_local(world_tile))


func _build_cells(chunk_position: Vector2i, entrance_locals: Array[Vector2i]) -> PackedByteArray:
	var smoothing_steps := int(_catalog.generation_value("smoothing_steps", 5))
	var margin := smoothing_steps + 2
	var dimension := WorldCoordinates.CHUNK_SIZE + margin * 2
	var values := PackedByteArray()
	values.resize(dimension * dimension)
	var world_origin := chunk_position * WorldCoordinates.CHUNK_SIZE - Vector2i.ONE * margin
	for y in dimension:
		for x in dimension:
			values[y * dimension + x] = _initial_cell(world_origin + Vector2i(x, y))
	for _step in smoothing_steps:
		var next := values.duplicate()
		for y in range(1, dimension - 1):
			for x in range(1, dimension - 1):
				var wall_neighbors := _wall_neighbor_count(values, dimension, x, y)
				var current := int(values[y * dimension + x])
				if current == Cell.WALL:
					next[y * dimension + x] = Cell.WALL if wall_neighbors >= int(_catalog.generation_value("wall_survival_limit", 4)) else Cell.FLOOR
				else:
					next[y * dimension + x] = Cell.WALL if wall_neighbors >= int(_catalog.generation_value("wall_birth_limit", 5)) else Cell.FLOOR
		values = next
	var cells := PackedByteArray()
	cells.resize(WorldCoordinates.CHUNK_SIZE * WorldCoordinates.CHUNK_SIZE)
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			cells[y * WorldCoordinates.CHUNK_SIZE + x] = values[(y + margin) * dimension + x + margin]
	_carve_guaranteed_routes(cells, chunk_position)
	for local in entrance_locals:
		_carve_path(cells, local, Vector2i.ONE * (WorldCoordinates.CHUNK_SIZE / 2), true)
	_ensure_minimum_floor(cells)
	_repair_connectivity(cells, chunk_position)
	return cells


func _initial_cell(world_tile: Vector2i) -> Cell:
	var stable_hash := WorldSeed.from_text("%d|cave-cell|%d|%d" % [_world_seed, world_tile.x, world_tile.y])
	var roll := float(stable_hash & 0xffff) / 65536.0
	return Cell.WALL if roll < float(_catalog.generation_value("initial_wall_chance", 0.47)) else Cell.FLOOR


func _wall_neighbor_count(values: PackedByteArray, dimension: int, x: int, y: int) -> int:
	var result := 0
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			if values[(y + offset_y) * dimension + x + offset_x] == Cell.WALL:
				result += 1
	return result


func _carve_guaranteed_routes(cells: PackedByteArray, chunk_position: Vector2i) -> void:
	var middle := WorldCoordinates.CHUNK_SIZE / 2
	var horizontal_first := (WorldSeed.from_text("%d|cave-route|%d|%d" % [_world_seed, chunk_position.x, chunk_position.y]) & 1) == 0
	if horizontal_first:
		for x in WorldCoordinates.CHUNK_SIZE:
			_set_floor(cells, Vector2i(x, middle))
		for y in WorldCoordinates.CHUNK_SIZE:
			_set_floor(cells, Vector2i(middle, y))
	else:
		for y in WorldCoordinates.CHUNK_SIZE:
			_set_floor(cells, Vector2i(middle, y))
		for x in WorldCoordinates.CHUNK_SIZE:
			_set_floor(cells, Vector2i(x, middle))
	for offset in [-1, 1]:
		_set_floor(cells, Vector2i(0, middle + offset))
		_set_floor(cells, Vector2i(WorldCoordinates.CHUNK_SIZE - 1, middle + offset))
		_set_floor(cells, Vector2i(middle + offset, 0))
		_set_floor(cells, Vector2i(middle + offset, WorldCoordinates.CHUNK_SIZE - 1))


func _ensure_minimum_floor(cells: PackedByteArray) -> void:
	var target := ceili(float(cells.size()) * float(_catalog.generation_value("minimum_floor_ratio", 0.34)))
	var floor_count := cells.count(Cell.FLOOR)
	if floor_count >= target:
		return
	var center := Vector2i.ONE * (WorldCoordinates.CHUNK_SIZE / 2)
	for radius in range(1, WorldCoordinates.CHUNK_SIZE / 2):
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var local := Vector2i(x, y)
				if local.x < 1 or local.y < 1 or local.x >= WorldCoordinates.CHUNK_SIZE - 1 or local.y >= WorldCoordinates.CHUNK_SIZE - 1:
					continue
				if cells[_index(local)] == Cell.WALL:
					cells[_index(local)] = Cell.FLOOR
					floor_count += 1
					if floor_count >= target:
						return


func _repair_connectivity(cells: PackedByteArray, chunk_position: Vector2i) -> void:
	var center := Vector2i.ONE * (WorldCoordinates.CHUNK_SIZE / 2)
	_set_floor(cells, center)
	var visited := _flood_floor(cells, center)
	var floor_count := cells.count(Cell.FLOOR)
	var safety := 0
	while visited.size() < floor_count and safety < cells.size():
		var disconnected := Vector2i(-1, -1)
		for index in cells.size():
			if cells[index] == Cell.FLOOR and not visited.has(index):
				disconnected = Vector2i(index % WorldCoordinates.CHUNK_SIZE, index / WorldCoordinates.CHUNK_SIZE)
				break
		if disconnected.x < 0:
			break
		var stable_hash := WorldSeed.from_text("%d|cave-connect|%d|%d|%d|%d" % [_world_seed, chunk_position.x, chunk_position.y, disconnected.x, disconnected.y])
		_carve_path(cells, disconnected, center, (stable_hash & 1) == 0)
		visited = _flood_floor(cells, center)
		floor_count = cells.count(Cell.FLOOR)
		safety += 1


func _flood_floor(cells: PackedByteArray, start: Vector2i) -> Dictionary:
	var result := {}
	if cells[_index(start)] != Cell.FLOOR:
		return result
	var queue: Array[Vector2i] = [start]
	result[_index(start)] = true
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for neighbor in [current + Vector2i.LEFT, current + Vector2i.RIGHT, current + Vector2i.UP, current + Vector2i.DOWN]:
			if not _is_local_valid(neighbor):
				continue
			var index := _index(neighbor)
			if cells[index] != Cell.FLOOR or result.has(index):
				continue
			result[index] = true
			queue.append(neighbor)
	return result


func _carve_path(cells: PackedByteArray, from: Vector2i, to: Vector2i, horizontal_first: bool) -> void:
	var current := from
	_set_floor(cells, current)
	if horizontal_first:
		while current.x != to.x:
			current.x += signi(to.x - current.x)
			_set_floor(cells, current)
		while current.y != to.y:
			current.y += signi(to.y - current.y)
			_set_floor(cells, current)
	else:
		while current.y != to.y:
			current.y += signi(to.y - current.y)
			_set_floor(cells, current)
		while current.x != to.x:
			current.x += signi(to.x - current.x)
			_set_floor(cells, current)


func _add_torches(chunk: ChunkData) -> void:
	var spacing := int(_catalog.feature_value("torch_spacing_tiles", 12))
	var middle := WorldCoordinates.CHUNK_SIZE / 2
	var world_origin := chunk.chunk_position * WorldCoordinates.CHUNK_SIZE
	var torch_starts: Array[Vector2i] = [
		Vector2i(posmod(-world_origin.x, spacing), middle),
		Vector2i(middle, posmod(-world_origin.y, spacing)),
	]
	for local in torch_starts:
		var cursor: Vector2i = local
		while cursor.x < WorldCoordinates.CHUNK_SIZE and cursor.y < WorldCoordinates.CHUNK_SIZE:
			if cursor.x >= 2 and cursor.y >= 2 and chunk.cave_feature_at(cursor) == Feature.NONE:
				chunk.cave_feature_map[_index(cursor)] = Feature.TORCH
			if cursor.y == middle:
				cursor.x += spacing
			else:
				cursor.y += spacing


func _add_chest(chunk: ChunkData) -> void:
	var stable_hash := WorldSeed.from_text("%d|cave-chest|%d|%d" % [_world_seed, chunk.chunk_position.x, chunk.chunk_position.y])
	var roll := float(stable_hash & 0xffff) / 65536.0
	if roll >= float(_catalog.feature_value("chest_chunk_chance", 0.28)):
		return
	var preferred := Vector2i(3 + posmod(int(stable_hash >> 16), WorldCoordinates.CHUNK_SIZE - 6), 3 + posmod(int(stable_hash >> 32), WorldCoordinates.CHUNK_SIZE - 6))
	var local := _nearest_empty_floor(chunk, preferred)
	if local.x >= 0:
		chunk.cave_feature_map[_index(local)] = Feature.CHEST


func _add_mineral_veins(chunk: ChunkData) -> void:
	var occupied := {}
	var maximum := int(_catalog.feature_value("maximum_veins_per_chunk", 28))
	var cell_size := 4
	for cell_y in range(0, WorldCoordinates.CHUNK_SIZE, cell_size):
		for cell_x in range(0, WorldCoordinates.CHUNK_SIZE, cell_size):
			if occupied.size() >= maximum:
				return
			var world_cell := chunk.chunk_position * (WorldCoordinates.CHUNK_SIZE / cell_size) + Vector2i(cell_x / cell_size, cell_y / cell_size)
			var stable_hash := WorldSeed.from_text("%d|cave-vein|%d|%d" % [_world_seed, world_cell.x, world_cell.y])
			var resource_code := _catalog.vein_resource_code(float(stable_hash & 0xffff) / 65536.0)
			if resource_code < 0 or float((stable_hash >> 16) & 0xffff) / 65536.0 >= _catalog.vein_cluster_chance(resource_code):
				continue
			var center := Vector2i(cell_x + posmod(int(stable_hash >> 32), cell_size), cell_y + posmod(int(stable_hash >> 40), cell_size))
			var vein_offsets: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(-1, 0)]
			for offset in vein_offsets:
				var local: Vector2i = center + offset
				if occupied.size() >= maximum or not _is_local_valid(local) or occupied.has(local):
					continue
				if not chunk.is_cave_floor(local) or chunk.cave_feature_at(local) != Feature.NONE:
					continue
				occupied[local] = true
				chunk.add_resource(local, resource_code, posmod(int(stable_hash >> 48) + occupied.size(), 4))


func _nearest_empty_floor(chunk: ChunkData, preferred: Vector2i) -> Vector2i:
	for radius in range(0, WorldCoordinates.CHUNK_SIZE):
		for y in range(preferred.y - radius, preferred.y + radius + 1):
			for x in range(preferred.x - radius, preferred.x + radius + 1):
				var local := Vector2i(x, y)
				if not _is_local_valid(local) or chunk.cave_feature_at(local) != Feature.NONE:
					continue
				if chunk.is_cave_floor(local):
					return local
	return Vector2i(-1, -1)


func _set_floor(cells: PackedByteArray, local: Vector2i) -> void:
	if _is_local_valid(local):
		cells[_index(local)] = Cell.FLOOR


func _index(local: Vector2i) -> int:
	return local.y * WorldCoordinates.CHUNK_SIZE + local.x


func _is_local_valid(local: Vector2i) -> bool:
	return local.x >= 0 and local.y >= 0 and local.x < WorldCoordinates.CHUNK_SIZE and local.y < WorldCoordinates.CHUNK_SIZE
