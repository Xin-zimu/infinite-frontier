class_name StructurePlanner
extends RefCounted

var _world_seed: int
var _catalog: StructureCatalog


func _init(world_seed: int, catalog := StructureCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func generate_for_chunk(chunk_position: Vector2i, terrain: TerrainGenerator) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _catalog.is_valid():
		return result
	var region_size := _catalog.region_size_tiles()
	var chunk_min := chunk_position * WorldCoordinates.CHUNK_SIZE
	var chunk_max := chunk_min + Vector2i.ONE * (WorldCoordinates.CHUNK_SIZE - 1)
	var region_min := Vector2i(
		floori(float(chunk_min.x - 32) / region_size),
		floori(float(chunk_min.y - 32) / region_size)
	)
	var region_max := Vector2i(
		floori(float(chunk_max.x + 32) / region_size),
		floori(float(chunk_max.y + 32) / region_size)
	)
	for region_y in range(region_min.y, region_max.y + 1):
		for region_x in range(region_min.x, region_max.x + 1):
			var plan := plan_region(Vector2i(region_x, region_y), terrain)
			if plan.is_empty():
				continue
			for cell in plan["cells"] as Array:
				var world_tile := cell["world_tile"] as Vector2i
				if WorldCoordinates.tile_to_chunk(world_tile) != chunk_position:
					continue
				var clipped := (cell as Dictionary).duplicate(true)
				clipped["local"] = WorldCoordinates.tile_to_local(world_tile)
				result.append(clipped)
	return result


func plan_region(region: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	var result := plan_land_region(region, terrain)
	var water_plan := plan_water_region(region, terrain)
	if not water_plan.is_empty():
		if result.is_empty():
			result = water_plan
		else:
			(result["cells"] as Array).append_array(water_plan["cells"] as Array)
	return result


func plan_land_region(region: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	var seed := WorldSeed.for_chunk(_world_seed, &"surface", region, &"structure_region")
	var chance_roll := float(posmod(seed, 10000)) / 10000.0
	if chance_roll >= _catalog.spawn_chance():
		return {}
	var definition := _catalog.choose(int(seed >> 16))
	if definition.is_empty():
		return {}
	var region_size := _catalog.region_size_tiles()
	var region_origin := region * region_size
	var anchor := region_origin + Vector2i(
		16 + posmod(int(seed >> 24), region_size - 48),
		16 + posmod(int(seed >> 40), region_size - 48)
	)
	var rotation := posmod(int(seed >> 8), 4)
	var mirrored := (seed & 1) == 1
	var preview := preview_instance(definition, anchor, rotation, mirrored, region)
	var bounds := preview["bounds"] as Rect2i
	for probe in [bounds.position, bounds.end - Vector2i.ONE, bounds.get_center()]:
		if terrain.terrain_at(probe) != ChunkData.Terrain.LAND or terrain.water_feature_at(probe) != HydrologyGenerator.Feature.NONE:
			return {}
	return preview


func plan_water_region(region: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	var seed := WorldSeed.for_chunk(_world_seed, &"surface", region, &"structure_region_water")
	var chance_roll := float(posmod(seed, 10000)) / 10000.0
	if chance_roll >= _catalog.water_spawn_chance():
		return {}
	var definition := _catalog.choose_water(int(seed >> 16))
	if definition.is_empty():
		return {}
	var region_size := _catalog.region_size_tiles()
	var region_origin := region * region_size
	var rotation := posmod(int(seed >> 8), 4)
	var mirrored := (seed & 1) == 1
	# 水域只占区域的一部分：从区域种子派生多个候选锚点，取第一个完全落水的实例，
	# 使含足够水域的区域总能稳定产出沉船或海上遗迹。
	for candidate_index in 8:
		var anchor_salt := 24 + candidate_index * 13
		var anchor := region_origin + Vector2i(
			16 + posmod(int(seed >> anchor_salt), region_size - 48),
			16 + posmod(int(seed >> (anchor_salt + 7)), region_size - 48)
		)
		var preview := preview_instance(definition, anchor, (rotation + candidate_index) % 4, mirrored != (candidate_index % 2 == 1), region)
		var bounds := preview["bounds"] as Rect2i
		var fits := true
		for probe in [bounds.position, bounds.end - Vector2i.ONE, bounds.get_center()]:
			var probe_terrain := terrain.terrain_at(probe)
			if probe_terrain != ChunkData.Terrain.SHALLOW_WATER and probe_terrain != ChunkData.Terrain.DEEP_WATER:
				fits = false
				break
		if fits:
			# 沉船与海上遗迹逐格校验，避免结构一半沉在水里一半悬在陆地上。
			for cell in preview["cells"] as Array:
				var cell_terrain := terrain.terrain_at(cell["world_tile"] as Vector2i)
				if cell_terrain != ChunkData.Terrain.SHALLOW_WATER and cell_terrain != ChunkData.Terrain.DEEP_WATER:
					fits = false
					break
		if fits:
			return preview
	return {}


func preview_instance(definition: Dictionary, anchor: Vector2i, rotation: int, mirrored: bool, region := Vector2i.ZERO) -> Dictionary:
	var transformed := transformed_cells(definition, rotation, mirrored)
	var cells: Array[Dictionary] = []
	var instance_key := "%s:%d:%d" % [definition["id"], region.x, region.y]
	for value in transformed["cells"] as Array:
		var cell := (value as Dictionary).duplicate(true)
		cell["world_tile"] = anchor + (cell["tile"] as Vector2i)
		cell["structure_code"] = int(definition["code"])
		cell["instance_key"] = instance_key
		cells.append(cell)
	return {
		"id": StringName(definition["id"]),
		"code": int(definition["code"]),
		"anchor": anchor,
		"rotation": posmod(rotation, 4),
		"mirrored": mirrored,
		"bounds": Rect2i(anchor, transformed["size"] as Vector2i),
		"cells": cells,
		"instance_key": instance_key,
	}


func transformed_cells(definition: Dictionary, rotation: int, mirrored: bool) -> Dictionary:
	var rows := definition["rows"] as Array
	var width := int(definition["width"])
	var height := int(definition["height"])
	var resolved_rotation := posmod(rotation, 4)
	var cells: Array[Dictionary] = []
	for y in height:
		var row := String(rows[y])
		for x in width:
			var glyph := row.substr(x, 1)
			if glyph == ".":
				continue
			var source_x := width - 1 - x if mirrored else x
			var target: Vector2i
			match resolved_rotation:
				1: target = Vector2i(height - 1 - y, source_x)
				2: target = Vector2i(width - 1 - source_x, height - 1 - y)
				3: target = Vector2i(y, width - 1 - source_x)
				_: target = Vector2i(source_x, y)
			cells.append({
				"tile": target,
				"tile_kind": StructureCatalog.tile_kind_for_glyph(glyph),
				"marker_kind": StructureCatalog.marker_kind_for_glyph(glyph),
			})
	var transformed_size := Vector2i(height, width) if resolved_rotation % 2 == 1 else Vector2i(width, height)
	return {"size": transformed_size, "cells": cells}
