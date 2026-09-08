class_name VillagePlanner
extends RefCounted

enum Feature { NONE, ROAD, PLAZA, BRIDGE, HOUSE, SHOP, WELL, CAMPFIRE }
enum Marker { NONE, VILLAGE_CENTER, HOUSE_ENTRANCE, SHOP, NPC, WELL }

var _world_seed: int
var _catalog: VillageCatalog


func _init(world_seed: int, catalog := VillageCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func generate_for_chunk(chunk_position: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	var chunk_min := chunk_position * WorldCoordinates.CHUNK_SIZE
	var chunk_max := chunk_min + Vector2i.ONE * (WorldCoordinates.CHUNK_SIZE - 1)
	var region_size := _catalog.region_size_tiles()
	var center_region := Vector2i(floori(float(chunk_min.x) / region_size), floori(float(chunk_min.y) / region_size))
	var cells: Dictionary = {}
	var markers: Array[Dictionary] = []
	var relevant: Dictionary = {}
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			var region := center_region + Vector2i(offset_x, offset_y)
			var village := village_for_region(region, terrain)
			if not village.is_empty():
				relevant[region] = village
	for village in relevant.values():
		_add_village_layout(village as Dictionary, terrain, cells, markers)
	for region_value in relevant.keys():
		var region := region_value as Vector2i
		var origin := relevant[region] as Dictionary
		for direction_value in [Vector2i.RIGHT, Vector2i.DOWN]:
			var direction := direction_value as Vector2i
			var neighbor_region: Vector2i = region + direction
			var neighbor := relevant.get(neighbor_region, {}) as Dictionary
			if neighbor.is_empty():
				neighbor = village_for_region(neighbor_region, terrain)
			if neighbor.is_empty():
				continue
			_add_path(origin["center"] as Vector2i, neighbor["center"] as Vector2i, terrain, cells)
	var clipped_cells: Array[Dictionary] = []
	for tile_value in cells.keys():
		var world_tile := tile_value as Vector2i
		if world_tile.x < chunk_min.x or world_tile.y < chunk_min.y or world_tile.x > chunk_max.x or world_tile.y > chunk_max.y:
			continue
		clipped_cells.append({"local": WorldCoordinates.tile_to_local(world_tile), "world_tile": world_tile, "feature": int(cells[world_tile])})
	var clipped_markers: Array[Dictionary] = []
	for marker in markers:
		var world_tile := marker["world_tile"] as Vector2i
		if WorldCoordinates.tile_to_chunk(world_tile) != chunk_position:
			continue
		var clipped := marker.duplicate(true)
		clipped["local"] = WorldCoordinates.tile_to_local(world_tile)
		clipped_markers.append(clipped)
	return {"cells": clipped_cells, "markers": clipped_markers}


func village_for_region(region: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	if not _catalog.is_valid():
		return {}
	var seed := WorldSeed.for_chunk(_world_seed, &"surface", region, &"village_region")
	if float(posmod(seed, 10000)) / 10000.0 >= _catalog.spawn_chance():
		return {}
	var region_size := _catalog.region_size_tiles()
	var origin := region * region_size
	var center := origin + Vector2i(
		64 + posmod(int(seed >> 16), region_size - 128),
		64 + posmod(int(seed >> 32), region_size - 128)
	)
	if terrain.terrain_at(center) != ChunkData.Terrain.LAND or terrain.water_feature_at(center) != HydrologyGenerator.Feature.NONE:
		return {}
	var house_count := _catalog.house_count_min() + posmod(int(seed >> 48), _catalog.house_count_max() - _catalog.house_count_min() + 1)
	return {"region": region, "center": center, "seed": seed, "house_count": house_count, "key": "village:%d:%d" % [region.x, region.y]}


func layout_for_village(village: Dictionary, terrain: TerrainGenerator) -> Dictionary:
	var cells: Dictionary = {}
	var markers: Array[Dictionary] = []
	if village.is_empty():
		return {"cells": cells, "markers": markers}
	_add_village_layout(village, terrain, cells, markers)
	return {"cells": cells, "markers": markers}


func _add_village_layout(village: Dictionary, terrain: TerrainGenerator, cells: Dictionary, markers: Array[Dictionary]) -> void:
	var center := village["center"] as Vector2i
	var seed := int(village["seed"])
	for y in range(-2, 3):
		for x in range(-2, 3):
			cells[center + Vector2i(x, y)] = Feature.PLAZA
	cells[center] = Feature.WELL
	cells[center + Vector2i(2, 2)] = Feature.CAMPFIRE
	markers.append({"world_tile": center, "marker": Marker.VILLAGE_CENTER, "village_key": village["key"]})
	markers.append({"world_tile": center, "marker": Marker.WELL, "village_key": village["key"]})
	markers.append({
		"world_tile": center + Vector2i(1, 0),
		"marker": Marker.NPC,
		"village_key": village["key"],
		"npc_index": 0,
		"home_tile": center + Vector2i(1, 0),
	})
	var house_count := int(village["house_count"])
	var house_entrances: Array[Vector2i] = []
	for index in house_count:
		var angle := TAU * float(index) / float(house_count) + float(posmod(seed, 31)) * 0.01
		var radius_range := _catalog.house_radius_max() - _catalog.house_radius_min() + 1
		var radius := _catalog.house_radius_min() + posmod(int(seed >> posmod(index * 7, 48)), radius_range)
		var house_center := center + Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius))
		if terrain.terrain_at(house_center) != ChunkData.Terrain.LAND:
			continue
		var feature := Feature.SHOP if index == 0 else Feature.HOUSE
		for y in range(-2, 2):
			for x in range(-3, 4):
				cells[house_center + Vector2i(x, y)] = feature
		var entrance_direction := Vector2i(signi(center.x - house_center.x), signi(center.y - house_center.y))
		if abs(center.x - house_center.x) > abs(center.y - house_center.y):
			entrance_direction.y = 0
		else:
			entrance_direction.x = 0
		var entrance: Vector2i = house_center + entrance_direction * 3
		markers.append({"world_tile": entrance, "marker": Marker.SHOP if index == 0 else Marker.HOUSE_ENTRANCE, "village_key": village["key"]})
		markers.append({
			"world_tile": house_center,
			"marker": Marker.NPC,
			"village_key": village["key"],
			"npc_index": index + 1,
			"house_index": index,
			"home_tile": house_center,
			"entrance_tile": entrance,
		})
		house_entrances.append(entrance)
	# 两阶段布局：先写全部地板，再铺路。道路天然跳过既有地板，
	# 因此后建房屋的地板不会再切断先建房屋的道路，村庄恒定连通。
	for entrance in house_entrances:
		_add_path(center, entrance, terrain, cells)


func _add_path(from: Vector2i, to: Vector2i, terrain: TerrainGenerator, cells: Dictionary) -> void:
	var horizontal_first := _orthogonal_path(from, to, true)
	var vertical_first := _orthogonal_path(from, to, false)
	var path := horizontal_first if _path_cost(horizontal_first, terrain) <= _path_cost(vertical_first, terrain) else vertical_first
	# 密集村庄中其他房屋的地板可能截断正交路；此时围绕地板做确定性 BFS 绕行，
	# 保证每条房屋道路都真正接入广场，村庄道路网恒定连通。
	if _path_is_blocked(path, cells):
		var detour := _detour_path(from, to, cells)
		if not detour.is_empty():
			path = detour
	for tile in path:
		if cells.has(tile) and int(cells[tile]) >= Feature.PLAZA:
			continue
		var water := terrain.water_feature_at(tile)
		cells[tile] = Feature.BRIDGE if HydrologyGenerator.is_water(water) else Feature.ROAD


func _path_is_blocked(path: Array[Vector2i], cells: Dictionary) -> bool:
	for index in range(1, path.size() - 1):
		var tile := path[index]
		# 广场可自由穿过；只有房屋地板（含商店、水井、火堆）才算道路障碍。
		if cells.has(tile) and int(cells[tile]) >= Feature.HOUSE:
			return true
	return false


func _detour_path(from: Vector2i, to: Vector2i, cells: Dictionary) -> Array[Vector2i]:
	var open: Array[Vector2i] = [from]
	var came_from := {}
	var seen := {from: true}
	while not open.is_empty() and seen.size() < 4096:
		var best_index := 0
		var best := open[0]
		var best_score := _manhattan(best, to)
		for index in range(1, open.size()):
			var candidate := open[index]
			var score := _manhattan(candidate, to)
			if score < best_score or (score == best_score and _precedes(candidate, best)):
				best_index = index
				best = candidate
				best_score = score
		open.remove_at(best_index)
		if best == to:
			var result: Array[Vector2i] = []
			var cursor := to
			while cursor != from:
				result.append(cursor)
				cursor = came_from[cursor]
			result.append(from)
			result.reverse()
			return result
		for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor: Vector2i = best + direction
			if seen.has(neighbor):
				continue
			if neighbor != to and cells.has(neighbor) and int(cells[neighbor]) >= Feature.HOUSE:
				continue
			seen[neighbor] = true
			came_from[neighbor] = best
			open.append(neighbor)
	return []


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _precedes(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)


func _orthogonal_path(from: Vector2i, to: Vector2i, horizontal_first: bool) -> Array[Vector2i]:
	var corner := Vector2i(to.x, from.y) if horizontal_first else Vector2i(from.x, to.y)
	var result: Array[Vector2i] = []
	_append_axis_segment(result, from, corner)
	_append_axis_segment(result, corner, to)
	return result


func _append_axis_segment(result: Array[Vector2i], from: Vector2i, to: Vector2i) -> void:
	var cursor := from
	var direction := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	if direction == Vector2i.ZERO:
		if not result.has(cursor): result.append(cursor)
		return
	while cursor != to:
		if not result.has(cursor): result.append(cursor)
		cursor += direction
	if not result.has(to): result.append(to)


func _path_cost(path: Array[Vector2i], terrain: TerrainGenerator) -> float:
	var total := 0.0
	var previous_elevation := -1.0
	for tile in path:
		var base_terrain := terrain.terrain_at(tile)
		var water := terrain.water_feature_at(tile)
		var elevation := terrain.elevation_at(tile)
		total += 45.0 if base_terrain < ChunkData.Terrain.BEACH else 1.0
		if HydrologyGenerator.is_water(water): total += 12.0
		if previous_elevation >= 0.0: total += absf(elevation - previous_elevation) * 28.0
		previous_elevation = elevation
	return total
