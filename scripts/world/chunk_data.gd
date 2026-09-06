class_name ChunkData
extends RefCounted

enum Terrain {
	DEEP_WATER,
	SHALLOW_WATER,
	BEACH,
	LAND,
}

var chunk_position := Vector2i.ZERO
var world_layer: StringName = &"surface"
var generation_version := GameVersion.GENERATION_VERSION
var world_seed := 0
var base_tiles := PackedByteArray()
var continental_map := PackedByteArray()
var elevation_map := PackedByteArray()
var erosion_map := PackedByteArray()
var temperature_map := PackedByteArray()
var moisture_map := PackedByteArray()
var biome_map := PackedByteArray()
var water_feature_map := PackedByteArray()
var resource_codes := PackedByteArray()
var resource_local_x := PackedByteArray()
var resource_local_y := PackedByteArray()
var resource_variants := PackedByteArray()
var structure_codes := PackedByteArray()
var structure_local_x := PackedByteArray()
var structure_local_y := PackedByteArray()
var structure_tile_kinds := PackedByteArray()
var structure_marker_kinds := PackedByteArray()
var village_feature_map := PackedByteArray()
var village_marker_local_x := PackedByteArray()
var village_marker_local_y := PackedByteArray()
var village_marker_kinds := PackedByteArray()
var cave_cell_map := PackedByteArray()
var cave_feature_map := PackedByteArray()
var dungeon_cell_map := PackedByteArray()
var dungeon_feature_map := PackedByteArray()
var checksum := ""


func tile_at(local: Vector2i) -> Terrain:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds: %s" % local)
		return Terrain.DEEP_WATER
	return base_tiles[_index(local)] as Terrain


func elevation_at(local: Vector2i) -> float:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds: %s" % local)
		return 0.0
	return float(elevation_map[_index(local)]) / 255.0


func continental_at(local: Vector2i) -> float:
	return _sample_map(continental_map, local, "continental")


func erosion_at(local: Vector2i) -> float:
	return _sample_map(erosion_map, local, "erosion")


func temperature_at(local: Vector2i) -> float:
	return _sample_map(temperature_map, local, "temperature")


func moisture_at(local: Vector2i) -> float:
	return _sample_map(moisture_map, local, "moisture")


func biome_at(local: Vector2i) -> int:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds: %s" % local)
		return 0
	return int(biome_map[_index(local)])


func water_feature_at(local: Vector2i) -> int:
	if not _is_local_valid(local) or _index(local) >= water_feature_map.size():
		return HydrologyGenerator.Feature.NONE
	return int(water_feature_map[_index(local)])


func terrain_counts() -> PackedInt32Array:
	var counts := PackedInt32Array([0, 0, 0, 0])
	for terrain_value in base_tiles:
		counts[terrain_value] += 1
	return counts


func biome_counts(biome_count: int) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(biome_count)
	for biome_value in biome_map:
		if biome_value < biome_count:
			counts[biome_value] += 1
	return counts


func resource_count() -> int:
	return resource_codes.size()


func add_resource(local: Vector2i, resource_code: int, variant: int) -> void:
	if not _is_local_valid(local):
		push_error("Cannot add resource outside 32×32 chunk bounds: %s" % local)
		return
	resource_codes.append(resource_code)
	resource_local_x.append(local.x)
	resource_local_y.append(local.y)
	resource_variants.append(variant)


func resource_local_at(index: int) -> Vector2i:
	if index < 0 or index >= resource_count():
		push_error("Resource index is outside chunk resource array: %d" % index)
		return Vector2i.ZERO
	return Vector2i(resource_local_x[index], resource_local_y[index])


func resource_world_tile_at(index: int) -> Vector2i:
	return WorldCoordinates.chunk_local_to_tile(chunk_position, resource_local_at(index))


func resource_code_at(index: int) -> int:
	if index < 0 or index >= resource_count():
		push_error("Resource index is outside chunk resource array: %d" % index)
		return 0
	return int(resource_codes[index])


func resource_variant_at(index: int) -> int:
	if index < 0 or index >= resource_count():
		push_error("Resource index is outside chunk resource array: %d" % index)
		return 0
	return int(resource_variants[index])


func has_resource_at(local: Vector2i) -> bool:
	for index in resource_count():
		if resource_local_x[index] == local.x and resource_local_y[index] == local.y:
			return true
	return false


func resource_key_at(index: int) -> String:
	var world_tile := resource_world_tile_at(index)
	if world_layer != &"surface":
		return "%s:%d:%d:%d" % [world_layer, world_tile.x, world_tile.y, resource_code_at(index)]
	return "%d:%d:%d" % [world_tile.x, world_tile.y, resource_code_at(index)]


func structure_cell_count() -> int:
	return structure_codes.size()


func add_structure_cell(local: Vector2i, structure_code: int, tile_kind: int, marker_kind: int) -> void:
	if not _is_local_valid(local):
		push_error("Cannot add structure cell outside 32×32 chunk bounds: %s" % local)
		return
	structure_codes.append(structure_code)
	structure_local_x.append(local.x)
	structure_local_y.append(local.y)
	structure_tile_kinds.append(tile_kind)
	structure_marker_kinds.append(marker_kind)


func structure_local_at(index: int) -> Vector2i:
	if index < 0 or index >= structure_cell_count():
		return Vector2i.ZERO
	return Vector2i(structure_local_x[index], structure_local_y[index])


func structure_code_at(index: int) -> int:
	return int(structure_codes[index]) if index >= 0 and index < structure_cell_count() else -1


func structure_tile_kind_at(index: int) -> int:
	return int(structure_tile_kinds[index]) if index >= 0 and index < structure_cell_count() else StructureCatalog.TileKind.FLOOR


func structure_marker_kind_at(index: int) -> int:
	return int(structure_marker_kinds[index]) if index >= 0 and index < structure_cell_count() else StructureCatalog.MarkerKind.NONE


func structure_marker_count(marker_kind: int) -> int:
	var total := 0
	for value in structure_marker_kinds:
		if int(value) == marker_kind:
			total += 1
	return total


func has_structure_at(local: Vector2i) -> bool:
	for index in structure_cell_count():
		if structure_local_x[index] == local.x and structure_local_y[index] == local.y:
			return true
	return false


func village_feature_at(local: Vector2i) -> int:
	if not _is_local_valid(local) or _index(local) >= village_feature_map.size():
		return VillagePlanner.Feature.NONE
	return int(village_feature_map[_index(local)])


func add_village_marker(local: Vector2i, marker_kind: int) -> void:
	if not _is_local_valid(local):
		return
	village_marker_local_x.append(local.x)
	village_marker_local_y.append(local.y)
	village_marker_kinds.append(marker_kind)


func village_marker_count(marker_kind := -1) -> int:
	if marker_kind < 0:
		return village_marker_kinds.size()
	var total := 0
	for value in village_marker_kinds:
		if int(value) == marker_kind:
			total += 1
	return total


func cave_cell_at(local: Vector2i) -> int:
	if not _is_local_valid(local) or _index(local) >= cave_cell_map.size():
		return CaveGenerator.Cell.FLOOR
	return int(cave_cell_map[_index(local)])


func cave_feature_at(local: Vector2i) -> int:
	if not _is_local_valid(local) or _index(local) >= cave_feature_map.size():
		return CaveGenerator.Feature.NONE
	return int(cave_feature_map[_index(local)])


func cave_feature_count(feature := -1) -> int:
	var total := 0
	for value in cave_feature_map:
		if feature < 0:
			if int(value) != CaveGenerator.Feature.NONE:
				total += 1
		elif int(value) == feature:
			total += 1
	return total


func is_cave_floor(local: Vector2i) -> bool:
	return world_layer == &"underground" and cave_cell_at(local) == CaveGenerator.Cell.FLOOR


func dungeon_cell_at(local: Vector2i) -> int:
	if not _is_local_valid(local) or _index(local) >= dungeon_cell_map.size():
		return DungeonGenerator.Cell.WALL
	return int(dungeon_cell_map[_index(local)])


func dungeon_feature_at(local: Vector2i) -> int:
	if not _is_local_valid(local) or _index(local) >= dungeon_feature_map.size():
		return DungeonGenerator.Feature.NONE
	return int(dungeon_feature_map[_index(local)])


func dungeon_feature_count(feature := -1) -> int:
	var total := 0
	for value in dungeon_feature_map:
		if feature < 0:
			if int(value) != DungeonGenerator.Feature.NONE:
				total += 1
		elif int(value) == feature:
			total += 1
	return total


func is_dungeon_floor(local: Vector2i) -> bool:
	return world_layer == &"dungeon" and dungeon_cell_at(local) == DungeonGenerator.Cell.FLOOR


func has_built_overlay_at(local: Vector2i) -> bool:
	return has_structure_at(local) \
		or village_feature_at(local) != VillagePlanner.Feature.NONE \
		or cave_feature_at(local) != CaveGenerator.Feature.NONE \
		or dungeon_feature_at(local) != DungeonGenerator.Feature.NONE


func finalize_checksum() -> void:
	var context := HashingContext.new()
	var error := context.start(HashingContext.HASH_SHA256)
	if error != OK:
		push_error("Unable to initialize chunk checksum: %s" % error_string(error))
		checksum = "invalid"
		return
	context.update(("%d|%s|%d|%d|%d|" % [
		world_seed,
		world_layer,
		chunk_position.x,
		chunk_position.y,
		generation_version,
	]).to_utf8_buffer())
	context.update(base_tiles)
	context.update(continental_map)
	context.update(elevation_map)
	context.update(erosion_map)
	context.update(temperature_map)
	context.update(moisture_map)
	context.update(biome_map)
	# HashingContext rejects zero-length buffers. Empty resource arrays still have a
	# stable representation: they contribute no bytes before the layer overlay.
	if not resource_codes.is_empty():
		context.update(resource_codes)
	if not resource_local_x.is_empty():
		context.update(resource_local_x)
	if not resource_local_y.is_empty():
		context.update(resource_local_y)
	if not resource_variants.is_empty():
		context.update(resource_variants)
	if world_layer == &"underground":
		context.update(cave_cell_map)
		context.update(cave_feature_map)
	elif world_layer == &"dungeon":
		context.update(dungeon_cell_map)
		context.update(dungeon_feature_map)
	checksum = context.finish().hex_encode().substr(0, 16)


func _sample_map(values: PackedByteArray, local: Vector2i, map_name: String) -> float:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds for %s map: %s" % [map_name, local])
		return 0.0
	return float(values[_index(local)]) / 255.0


func _index(local: Vector2i) -> int:
	return local.y * WorldCoordinates.CHUNK_SIZE + local.x


func _is_local_valid(local: Vector2i) -> bool:
	return local.x >= 0 and local.y >= 0 and local.x < WorldCoordinates.CHUNK_SIZE and local.y < WorldCoordinates.CHUNK_SIZE
