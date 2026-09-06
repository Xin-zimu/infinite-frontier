class_name HusbandryPlanner
extends RefCounted

var _world_seed := 0
var _catalog: HusbandryCatalog
var _biome_catalog := BiomeCatalog.new()


func _init(world_seed: int, catalog := HusbandryCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func candidates_for_chunk(chunk: ChunkData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if chunk == null or chunk.world_layer != &"surface" or not _catalog.is_valid():
		return result
	var cell_size := _catalog.wild_cell_size()
	var cells_per_chunk := WorldCoordinates.CHUNK_SIZE / cell_size
	var chunk_origin := chunk.chunk_position * WorldCoordinates.CHUNK_SIZE
	var first_cell := Vector2i(floori(float(chunk_origin.x) / float(cell_size)), floori(float(chunk_origin.y) / float(cell_size)))
	for cell_y_offset in cells_per_chunk:
		for cell_x_offset in cells_per_chunk:
			var cell := first_cell + Vector2i(cell_x_offset, cell_y_offset)
			var score := WorldSeed.from_text("husbandry|%d|%d|%d" % [_world_seed, cell.x, cell.y])
			if posmod(score, 100) >= _catalog.wild_spawn_percent():
				continue
			var inner_span := cell_size - 4
			var world_tile := cell * cell_size + Vector2i(
				2 + posmod(score / 101, inner_span),
				2 + posmod(score / 1009, inner_span)
			)
			if WorldCoordinates.tile_to_chunk(world_tile) != chunk.chunk_position:
				continue
			var local := WorldCoordinates.tile_to_local(world_tile)
			if HydrologyGenerator.is_water(chunk.water_feature_at(local)) or chunk.has_built_overlay_at(local) or _has_resource_at(chunk, local):
				continue
			var biome_id := _biome_catalog.id_for_code(chunk.biome_at(local))
			var species := _catalog.species_for_biome(biome_id)
			if species.is_empty():
				continue
			var animal_type := species[posmod(score / 7919, species.size())]
			result.append({
				"animal_id": "wild:%d:%d" % [cell.x, cell.y],
				"animal_type": String(animal_type),
				"world_tile": [world_tile.x, world_tile.y],
				"sex": "female" if posmod(score / 65537, 2) == 0 else "male",
				"wild": true,
			})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["animal_id"]) < String(b["animal_id"])
	)
	return result


func _has_resource_at(chunk: ChunkData, local: Vector2i) -> bool:
	for index in chunk.resource_count():
		if chunk.resource_local_at(index) == local:
			return true
	return false
