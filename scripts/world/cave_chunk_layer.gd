class_name CaveChunkLayer
extends TileMapLayer

const WALL_TILE := 0
const ENTRANCE_TILE := 1
const EXIT_TILE := 2
const TORCH_TILE := 3
const CHEST_TILE := 4

static var _shared_tile_set: TileSet
static var _shared_source_id := -1

var _chunk: ChunkData
var _opened_chests: Dictionary = {}


func _ready() -> void:
	z_index = 3
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set


func apply_chunk(chunk: ChunkData, opened_chests := {}) -> void:
	_chunk = chunk
	_opened_chests = (opened_chests as Dictionary)
	clear()
	if _shared_source_id < 0:
		return
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			if chunk.world_layer == &"underground" and chunk.cave_cell_at(local) == CaveGenerator.Cell.WALL:
				set_cell(local, _shared_source_id, Vector2i(WALL_TILE, 0), 0)
				continue
			var feature := chunk.cave_feature_at(local)
			if feature == CaveGenerator.Feature.CHEST and _opened_chests.has(_feature_key(local)):
				continue
			if feature != CaveGenerator.Feature.NONE:
				set_cell(local, _shared_source_id, Vector2i(_tile_for_feature(feature), 0), 0)


func wall_count() -> int:
	if _chunk == null or _chunk.world_layer != &"underground":
		return 0
	return _chunk.cave_cell_map.count(CaveGenerator.Cell.WALL)


func feature_count(feature := -1) -> int:
	if _chunk == null:
		return 0
	if feature != CaveGenerator.Feature.CHEST:
		return _chunk.cave_feature_count(feature)
	var result := 0
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			if _chunk.cave_feature_at(local) == feature and not _opened_chests.has(_feature_key(local)):
				result += 1
	return result


func _feature_key(local: Vector2i) -> String:
	var world_tile := WorldCoordinates.chunk_local_to_tile(_chunk.chunk_position, local)
	return "underground:%d:%d" % [world_tile.x, world_tile.y]


func _tile_for_feature(feature: int) -> int:
	match feature:
		CaveGenerator.Feature.ENTRANCE: return ENTRANCE_TILE
		CaveGenerator.Feature.EXIT: return EXIT_TILE
		CaveGenerator.Feature.TORCH: return TORCH_TILE
		CaveGenerator.Feature.CHEST: return CHEST_TILE
		_: return ENTRANCE_TILE


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_tile_set.add_physics_layer(0)
	_shared_tile_set.set_physics_layer_collision_layer(0, 1)
	_shared_tile_set.set_physics_layer_collision_mask(0, 2)
	var image := Image.create(WorldCoordinates.TILE_SIZE * 5, WorldCoordinates.TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_paint_wall(image, Vector2i.ZERO)
	_paint_transition(image, Vector2i(WorldCoordinates.TILE_SIZE, 0), Color("6f92a8"), false)
	_paint_transition(image, Vector2i(WorldCoordinates.TILE_SIZE * 2, 0), Color("c5a56b"), true)
	_paint_torch(image, Vector2i(WorldCoordinates.TILE_SIZE * 3, 0))
	_paint_chest(image, Vector2i(WorldCoordinates.TILE_SIZE * 4, 0))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_source_id = _shared_tile_set.add_source(atlas)
	for tile_index in 5:
		atlas.create_tile(Vector2i(tile_index, 0))
	var wall_data := atlas.get_tile_data(Vector2i(WALL_TILE, 0), 0)
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
	]))


static func _paint_wall(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin, Vector2i.ONE * WorldCoordinates.TILE_SIZE, Color("171a22"))
	_fill_rect(image, origin + Vector2i(2, 3), Vector2i(28, 26), Color("292d38"))
	_fill_rect(image, origin + Vector2i(4, 5), Vector2i(10, 3), Color("3a3e4b"))
	_fill_rect(image, origin + Vector2i(18, 15), Vector2i(9, 3), Color("20232c"))


static func _paint_transition(image: Image, origin: Vector2i, color: Color, upward: bool) -> void:
	_fill_rect(image, origin + Vector2i(6, 7), Vector2i(20, 21), Color("242831"))
	_fill_rect(image, origin + Vector2i(8, 9), Vector2i(16, 17), color.darkened(0.35))
	for step in 4:
		var y := 11 + step * 4
		_fill_rect(image, origin + Vector2i(10, y), Vector2i(12, 2), color.lightened(0.08 * step))
	var arrow_y := 3 if upward else 27
	_fill_rect(image, origin + Vector2i(14, arrow_y), Vector2i(5, 3), color)


static func _paint_torch(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin + Vector2i(15, 13), Vector2i(3, 15), Color("7b4d2b"))
	_fill_rect(image, origin + Vector2i(11, 5), Vector2i(11, 10), Color("e57632"))
	_fill_rect(image, origin + Vector2i(14, 3), Vector2i(6, 9), Color("ffd166"))


static func _paint_chest(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin + Vector2i(6, 12), Vector2i(20, 15), Color("6e4326"))
	_fill_rect(image, origin + Vector2i(7, 9), Vector2i(18, 7), Color("a66a32"))
	_fill_rect(image, origin + Vector2i(14, 14), Vector2i(5, 8), Color("e0ba54"))


static func _fill_rect(image: Image, origin: Vector2i, size: Vector2i, color: Color) -> void:
	for y in size.y:
		for x in size.x:
			image.set_pixelv(origin + Vector2i(x, y), color)
