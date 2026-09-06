class_name DungeonChunkLayer
extends TileMapLayer

const WALL_TILE := 0
const EXIT_TILE := 1
const DOOR_TILE := 2
const KEY_TILE := 3
const TRAP_TILE := 4
const CHEST_TILE := 5
const ELITE_TILE := 6
const BOSS_TILE := 7

static var _shared_tile_set: TileSet
static var _shared_source_id := -1

var _chunk: ChunkData
var _dungeon_id := ""
var _run_state: Dictionary = {}


func _ready() -> void:
	z_index = 4
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set


func apply_chunk(chunk: ChunkData, dungeon_id := "", run_state := {}) -> void:
	_chunk = chunk
	_dungeon_id = dungeon_id
	_run_state = (run_state as Dictionary).duplicate(true)
	clear()
	if _shared_source_id < 0 or chunk.world_layer != &"dungeon":
		return
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			if chunk.dungeon_cell_at(local) == DungeonGenerator.Cell.WALL:
				set_cell(local, _shared_source_id, Vector2i(WALL_TILE, 0), 0)
				continue
			var feature := chunk.dungeon_feature_at(local)
			if feature == DungeonGenerator.Feature.NONE or _is_resolved(feature, _feature_key(local, feature)):
				continue
			set_cell(local, _shared_source_id, Vector2i(_tile_for_feature(feature), 0), 0)


func wall_count() -> int:
	return _chunk.dungeon_cell_map.count(DungeonGenerator.Cell.WALL) if _chunk != null and _chunk.world_layer == &"dungeon" else 0


func feature_count(feature := -1) -> int:
	if _chunk == null or _chunk.world_layer != &"dungeon":
		return 0
	var result := 0
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			var current := _chunk.dungeon_feature_at(local)
			if current == DungeonGenerator.Feature.NONE or (feature >= 0 and current != feature):
				continue
			if not _is_resolved(current, _feature_key(local, current)):
				result += 1
	return result


func _feature_key(local: Vector2i, feature: int) -> String:
	var world_tile := WorldCoordinates.chunk_local_to_tile(_chunk.chunk_position, local)
	return DungeonGenerator.feature_key(_dungeon_id, feature, world_tile)


func _is_resolved(feature: int, feature_key: String) -> bool:
	match feature:
		DungeonGenerator.Feature.LOCKED_DOOR:
			return (_run_state.get("unlocked_doors", []) as Array).has(feature_key)
		DungeonGenerator.Feature.KEY:
			return (_run_state.get("collected_keys", []) as Array).has(feature_key)
		DungeonGenerator.Feature.TRAP:
			return (_run_state.get("triggered_traps", []) as Array).has(feature_key)
		DungeonGenerator.Feature.CHEST:
			return (_run_state.get("opened_chests", []) as Array).has(feature_key)
		DungeonGenerator.Feature.ELITE_SPAWN:
			return (_run_state.get("defeated_elites", []) as Array).has(feature_key)
		DungeonGenerator.Feature.BOSS_SPAWN:
			return bool(_run_state.get("boss_defeated", false))
		_:
			return false


func _tile_for_feature(feature: int) -> int:
	match feature:
		DungeonGenerator.Feature.EXIT: return EXIT_TILE
		DungeonGenerator.Feature.LOCKED_DOOR: return DOOR_TILE
		DungeonGenerator.Feature.KEY: return KEY_TILE
		DungeonGenerator.Feature.TRAP: return TRAP_TILE
		DungeonGenerator.Feature.CHEST: return CHEST_TILE
		DungeonGenerator.Feature.ELITE_SPAWN: return ELITE_TILE
		DungeonGenerator.Feature.BOSS_SPAWN: return BOSS_TILE
		_: return EXIT_TILE


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_tile_set.add_physics_layer(0)
	_shared_tile_set.set_physics_layer_collision_layer(0, 1)
	_shared_tile_set.set_physics_layer_collision_mask(0, 2)
	var image := Image.create(WorldCoordinates.TILE_SIZE * 8, WorldCoordinates.TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_paint_wall(image, Vector2i.ZERO)
	_paint_exit(image, Vector2i(WorldCoordinates.TILE_SIZE, 0))
	_paint_door(image, Vector2i(WorldCoordinates.TILE_SIZE * 2, 0))
	_paint_key(image, Vector2i(WorldCoordinates.TILE_SIZE * 3, 0))
	_paint_trap(image, Vector2i(WorldCoordinates.TILE_SIZE * 4, 0))
	_paint_chest(image, Vector2i(WorldCoordinates.TILE_SIZE * 5, 0))
	_paint_spawn(image, Vector2i(WorldCoordinates.TILE_SIZE * 6, 0), Color("d66d73"), false)
	_paint_spawn(image, Vector2i(WorldCoordinates.TILE_SIZE * 7, 0), Color("b98ce8"), true)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_source_id = _shared_tile_set.add_source(atlas)
	for tile_index in 8:
		atlas.create_tile(Vector2i(tile_index, 0))
	for solid_tile in [WALL_TILE, DOOR_TILE]:
		var tile_data := atlas.get_tile_data(Vector2i(solid_tile, 0), 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
		]))


static func _paint_wall(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin, Vector2i.ONE * 32, Color("15131d"))
	_fill_rect(image, origin + Vector2i(2, 3), Vector2i(28, 26), Color("30283d"))
	_fill_rect(image, origin + Vector2i(4, 5), Vector2i(12, 3), Color("463853"))
	_fill_rect(image, origin + Vector2i(18, 18), Vector2i(9, 3), Color("211b2a"))


static func _paint_exit(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin + Vector2i(5, 5), Vector2i(22, 24), Color("27212f"))
	_fill_rect(image, origin + Vector2i(8, 8), Vector2i(16, 18), Color("74628b"))
	for step in 4:
		_fill_rect(image, origin + Vector2i(9, 10 + step * 4), Vector2i(14, 2), Color("c1a6d7").darkened(step * 0.08))


static func _paint_door(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin + Vector2i(5, 2), Vector2i(22, 29), Color("49374f"))
	_fill_rect(image, origin + Vector2i(8, 5), Vector2i(16, 25), Color("78536c"))
	_fill_rect(image, origin + Vector2i(14, 13), Vector2i(5, 7), Color("e0ba54"))


static func _paint_key(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin + Vector2i(13, 12), Vector2i(14, 4), Color("f0ca58"))
	_fill_rect(image, origin + Vector2i(21, 15), Vector2i(4, 8), Color("f0ca58"))
	_fill_rect(image, origin + Vector2i(7, 8), Vector2i(10, 10), Color("f0ca58"))
	_fill_rect(image, origin + Vector2i(10, 11), Vector2i(4, 4), Color("34283c"))


static func _paint_trap(image: Image, origin: Vector2i) -> void:
	for x in [5, 12, 19, 26]:
		_fill_rect(image, origin + Vector2i(x, 13), Vector2i(2, 15), Color("aa515a"))
	_fill_rect(image, origin + Vector2i(3, 27), Vector2i(27, 2), Color("593542"))


static func _paint_chest(image: Image, origin: Vector2i) -> void:
	_fill_rect(image, origin + Vector2i(5, 12), Vector2i(22, 15), Color("63402c"))
	_fill_rect(image, origin + Vector2i(7, 8), Vector2i(18, 8), Color("9b633d"))
	_fill_rect(image, origin + Vector2i(14, 14), Vector2i(5, 8), Color("cab45d"))


static func _paint_spawn(image: Image, origin: Vector2i, color: Color, boss: bool) -> void:
	draw_circle_on_image(image, origin + Vector2i(16, 17), 10 if boss else 7, color)
	_fill_rect(image, origin + Vector2i(14, 4), Vector2i(5, 8), color.lightened(0.25))
	if boss:
		_fill_rect(image, origin + Vector2i(7, 27), Vector2i(19, 3), color.darkened(0.25))


static func draw_circle_on_image(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				image.set_pixelv(center + Vector2i(x, y), color)


static func _fill_rect(image: Image, origin: Vector2i, size: Vector2i, color: Color) -> void:
	for y in size.y:
		for x in size.x:
			image.set_pixelv(origin + Vector2i(x, y), color)
