class_name DungeonGenerator
extends RefCounted

enum Cell {
	WALL,
	FLOOR,
}

enum Feature {
	NONE,
	EXIT,
	LOCKED_DOOR,
	KEY,
	TRAP,
	CHEST,
	ELITE_SPAWN,
	BOSS_SPAWN,
}

var _world_seed: int
var _dungeon_id: String
var _anchor_chunk: Vector2i
var _catalog: DungeonCatalog
var _biome_catalog := BiomeCatalog.new()
var _layout: Dictionary = {}


func _init(world_seed: int, dungeon_id: String, anchor_chunk: Vector2i, catalog := DungeonCatalog.new()) -> void:
	_world_seed = world_seed
	_dungeon_id = dungeon_id
	_anchor_chunk = anchor_chunk
	_catalog = catalog


func generate_chunk(chunk_position: Vector2i) -> ChunkData:
	var result := ChunkData.new()
	result.chunk_position = chunk_position
	result.world_layer = &"dungeon"
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
	result.dungeon_cell_map.resize(cell_count)
	result.dungeon_feature_map.resize(cell_count)
	var layout := _layout_snapshot_internal()
	if chunk_position == _anchor_chunk:
		result.dungeon_cell_map = (layout["cells"] as PackedByteArray).duplicate()
		result.dungeon_feature_map = (layout["features"] as PackedByteArray).duplicate()
	else:
		result.dungeon_cell_map.fill(Cell.WALL)
	var mountain_code := _biome_catalog.code_for_id(&"mountain")
	for index in cell_count:
		var floor_cell := result.dungeon_cell_map[index] == Cell.FLOOR
		result.base_tiles[index] = ChunkData.Terrain.LAND if floor_cell else ChunkData.Terrain.DEEP_WATER
		result.continental_map[index] = 192 if floor_cell else 24
		result.elevation_map[index] = 96 if floor_cell else 232
		result.erosion_map[index] = 128
		result.temperature_map[index] = 72
		result.moisture_map[index] = 112
		result.biome_map[index] = mountain_code
	result.finalize_checksum()
	return result


func layout_snapshot() -> Dictionary:
	return _layout_snapshot_internal().duplicate(true)


func entry_world_tile() -> Vector2i:
	var local := _layout_snapshot_internal()["entry_local"] as Vector2i
	return WorldCoordinates.chunk_local_to_tile(_anchor_chunk, local)


func boss_world_tile() -> Vector2i:
	var local := _layout_snapshot_internal()["boss_local"] as Vector2i
	return WorldCoordinates.chunk_local_to_tile(_anchor_chunk, local)


static func dungeon_id_for_entrance(world_tile: Vector2i) -> String:
	return "dungeon_%d_%d" % [world_tile.x, world_tile.y]


static func feature_key(dungeon_id: String, feature: int, world_tile: Vector2i) -> String:
	return "%s:%s:%d:%d" % [dungeon_id, feature_name(feature), world_tile.x, world_tile.y]


static func feature_name(feature: int) -> String:
	match feature:
		Feature.EXIT: return "exit"
		Feature.LOCKED_DOOR: return "door"
		Feature.KEY: return "key"
		Feature.TRAP: return "trap"
		Feature.CHEST: return "chest"
		Feature.ELITE_SPAWN: return "elite"
		Feature.BOSS_SPAWN: return "boss"
		_: return "none"


func _layout_snapshot_internal() -> Dictionary:
	if _layout.is_empty():
		_layout = _build_layout()
	return _layout


func _build_layout() -> Dictionary:
	var cells := PackedByteArray()
	var features := PackedByteArray()
	cells.resize(WorldCoordinates.CHUNK_SIZE * WorldCoordinates.CHUNK_SIZE)
	features.resize(cells.size())
	cells.fill(Cell.WALL)
	var rooms: Array[Dictionary] = []
	var minimum_size := int(_catalog.generation_value("room_size_minimum", 5))
	var maximum_size := int(_catalog.generation_value("room_size_maximum", 8))
	for row in 2:
		for column in 3:
			var slot := row * 3 + column
			var width := minimum_size + posmod(int(_stable_hash("room-width", slot)), maximum_size - minimum_size + 1)
			var height := minimum_size + posmod(int(_stable_hash("room-height", slot)), maximum_size - minimum_size + 1)
			var cell_origin := Vector2i(1 + column * 10, 1 + row * 15)
			var horizontal_slack := maxi(0, 9 - width)
			var vertical_slack := maxi(0, 13 - height)
			var position := cell_origin + Vector2i(
				posmod(int(_stable_hash("room-x", slot)), horizontal_slack + 1),
				posmod(int(_stable_hash("room-y", slot)), vertical_slack + 1)
			)
			var rect := Rect2i(position, Vector2i(width, height))
			var center := rect.position + rect.size / 2
			rooms.append({"index": slot, "rect": rect, "center": center})
			_carve_room(cells, rect)
	var entry_room := rooms[4]
	var boss_room := rooms[1]
	var sequence: Array[Dictionary] = [entry_room]
	var remaining: Array[Dictionary] = []
	for room in rooms:
		if int(room["index"]) not in [int(entry_room["index"]), int(boss_room["index"])]:
			remaining.append(room)
	while not remaining.is_empty():
		var current := sequence[-1]
		var best_index := 0
		var best_score := 1 << 30
		for index in remaining.size():
			var distance := _manhattan(current["center"] as Vector2i, remaining[index]["center"] as Vector2i)
			var tie_breaker := int(_stable_hash("room-order", int(remaining[index]["index"])) & 0xff)
			var score := distance * 256 + tie_breaker
			if score < best_score:
				best_score = score
				best_index = index
		sequence.append(remaining.pop_at(best_index))
	sequence.append(boss_room)
	var connections: Array[Dictionary] = []
	for index in range(sequence.size() - 1):
		var from := sequence[index]["center"] as Vector2i
		var to := sequence[index + 1]["center"] as Vector2i
		var horizontal_first := (_stable_hash("corridor", index) & 1) == 0
		var path := _orthogonal_path(from, to, horizontal_first)
		for local in path:
			_set_cell(cells, local, Cell.FLOOR)
		connections.append({
			"from_room": int(sequence[index]["index"]),
			"to_room": int(sequence[index + 1]["index"]),
			"path": path,
		})
	var occupied := {}
	var entry_local := entry_room["center"] as Vector2i
	var boss_local := boss_room["center"] as Vector2i
	_place_feature(features, occupied, entry_local, Feature.EXIT)
	_place_feature(features, occupied, boss_local, Feature.BOSS_SPAWN)
	var lock_count := mini(int(_catalog.feature_value("locked_doors", 2)), connections.size() - 1)
	for lock_index in lock_count:
		var connection_index := clampi(
			floori(float(lock_index + 1) * float(connections.size()) / float(lock_count + 1)),
			1,
			connections.size() - 1
		)
		var connection := connections[connection_index]
		var corridor_tiles := _corridor_only_tiles(connection["path"] as Array, rooms)
		var door_local := _first_available_near(corridor_tiles, corridor_tiles.size() / 2, occupied)
		_place_feature(features, occupied, door_local, Feature.LOCKED_DOOR)
		var key_room := sequence[connection_index]
		var key_local := _available_room_tile(key_room["rect"] as Rect2i, key_room["center"] as Vector2i, occupied, lock_index + 1)
		_place_feature(features, occupied, key_local, Feature.KEY)
	var chest_count := mini(int(_catalog.feature_value("chests", 2)), sequence.size() - 2)
	for chest_index in chest_count:
		var room := sequence[1 + chest_index]
		var local := _available_room_tile(room["rect"] as Rect2i, room["center"] as Vector2i, occupied, chest_index + 3)
		_place_feature(features, occupied, local, Feature.CHEST)
	var elite_count := mini(int(_catalog.feature_value("elite_enemies", 2)), sequence.size() - 2)
	for elite_index in elite_count:
		var room := sequence[sequence.size() - 2 - elite_index]
		var local := _available_room_tile(room["rect"] as Rect2i, room["center"] as Vector2i, occupied, elite_index + 5)
		_place_feature(features, occupied, local, Feature.ELITE_SPAWN)
	var trap_count := int(_catalog.feature_value("traps", 4))
	for trap_index in trap_count:
		var connection := connections[trap_index % connections.size()]
		var corridor_tiles := _corridor_only_tiles(connection["path"] as Array, rooms)
		var preferred := (trap_index + 1) * corridor_tiles.size() / (trap_count + 1)
		var local := _first_available_near(corridor_tiles, preferred, occupied)
		if local.x < 0:
			local = _available_room_tile(sequence[1 + trap_index % (sequence.size() - 2)]["rect"] as Rect2i, sequence[1 + trap_index % (sequence.size() - 2)]["center"] as Vector2i, occupied, trap_index + 7)
		_place_feature(features, occupied, local, Feature.TRAP)
	return {
		"dungeon_id": _dungeon_id,
		"anchor_chunk": _anchor_chunk,
		"rooms": rooms,
		"room_sequence": sequence,
		"connections": connections,
		"cells": cells,
		"features": features,
		"entry_local": entry_local,
		"boss_local": boss_local,
	}


func _carve_room(cells: PackedByteArray, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_set_cell(cells, Vector2i(x, y), Cell.FLOOR)


func _orthogonal_path(from: Vector2i, to: Vector2i, horizontal_first: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = [from]
	var current := from
	if horizontal_first:
		while current.x != to.x:
			current.x += signi(to.x - current.x)
			result.append(current)
		while current.y != to.y:
			current.y += signi(to.y - current.y)
			result.append(current)
	else:
		while current.y != to.y:
			current.y += signi(to.y - current.y)
			result.append(current)
		while current.x != to.x:
			current.x += signi(to.x - current.x)
			result.append(current)
	return result


func _corridor_only_tiles(path: Array, rooms: Array[Dictionary]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for local_value in path:
		var local := local_value as Vector2i
		var inside_room := false
		for room in rooms:
			if (room["rect"] as Rect2i).has_point(local):
				inside_room = true
				break
		if not inside_room:
			result.append(local)
	if result.is_empty():
		for local_value in path:
			result.append(local_value as Vector2i)
	return result


func _available_room_tile(rect: Rect2i, center: Vector2i, occupied: Dictionary, salt: int) -> Vector2i:
	var offsets: Array[Vector2i] = [
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
	]
	var start := posmod(int(_stable_hash("room-feature", salt)), offsets.size())
	for offset_index in offsets.size():
		var local := center + offsets[posmod(start + offset_index, offsets.size())]
		if rect.has_point(local) and not occupied.has(local):
			return local
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var local := Vector2i(x, y)
			if not occupied.has(local):
				return local
	return Vector2i(-1, -1)


func _first_available_near(values: Array[Vector2i], preferred: int, occupied: Dictionary) -> Vector2i:
	if values.is_empty():
		return Vector2i(-1, -1)
	for radius in values.size():
		for index in [preferred - radius, preferred + radius]:
			if index >= 0 and index < values.size() and not occupied.has(values[index]):
				return values[index]
	return Vector2i(-1, -1)


func _place_feature(features: PackedByteArray, occupied: Dictionary, local: Vector2i, feature: int) -> void:
	if local.x < 0 or local.y < 0:
		return
	features[_index(local)] = feature
	occupied[local] = true


func _set_cell(cells: PackedByteArray, local: Vector2i, cell: int) -> void:
	if local.x < 0 or local.y < 0 or local.x >= WorldCoordinates.CHUNK_SIZE or local.y >= WorldCoordinates.CHUNK_SIZE:
		return
	cells[_index(local)] = cell


func _stable_hash(label: String, index: int) -> int:
	return WorldSeed.from_text("%d|%s|%s|%d|%d|%d" % [_world_seed, _dungeon_id, label, _anchor_chunk.x, _anchor_chunk.y, index])


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _index(local: Vector2i) -> int:
	return local.y * WorldCoordinates.CHUNK_SIZE + local.x
