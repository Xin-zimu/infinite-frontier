class_name StructureChunkLayer
extends TileMapLayer

static var _shared_tile_set: TileSet
static var _shared_source_id := -1

var _chunk: ChunkData


func _ready() -> void:
	z_index = 3
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set


func apply_chunk(chunk: ChunkData) -> void:
	_chunk = chunk
	clear()
	if _shared_source_id < 0:
		return
	for index in chunk.structure_cell_count():
		set_cell(
			chunk.structure_local_at(index),
			_shared_source_id,
			Vector2i(chunk.structure_tile_kind_at(index), chunk.structure_code_at(index)),
			0
		)


func marker_count(marker_kind: int) -> int:
	return _chunk.structure_marker_count(marker_kind) if _chunk != null else 0


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	var catalog := StructureCatalog.new()
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_tile_set.add_physics_layer(0)
	_shared_tile_set.set_physics_layer_collision_layer(0, 1)
	_shared_tile_set.set_physics_layer_collision_mask(0, 2)
	var kinds := StructureCatalog.TileKind.size()
	var image := Image.create(
		WorldCoordinates.TILE_SIZE * kinds,
		WorldCoordinates.TILE_SIZE * catalog.template_count(),
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(Color.TRANSPARENT)
	for structure_code in catalog.template_count():
		for tile_kind in kinds:
			_paint_tile(image, Vector2i(tile_kind, structure_code), catalog.color_for_code(structure_code), tile_kind)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_source_id = _shared_tile_set.add_source(atlas)
	for structure_code in catalog.template_count():
		for tile_kind in kinds:
			var coordinate := Vector2i(tile_kind, structure_code)
			atlas.create_tile(coordinate)
			if tile_kind == StructureCatalog.TileKind.WALL:
				var tile_data := atlas.get_tile_data(coordinate, 0)
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
				]))


static func _paint_tile(image: Image, atlas: Vector2i, base: Color, tile_kind: int) -> void:
	var origin := atlas * WorldCoordinates.TILE_SIZE
	var color := base
	match tile_kind:
		StructureCatalog.TileKind.FLOOR: color = base.darkened(0.24)
		StructureCatalog.TileKind.WALL: color = base.lightened(0.08)
		StructureCatalog.TileKind.DOOR: color = Color("6f462a")
		StructureCatalog.TileKind.CHEST: color = Color("d7a13b")
		StructureCatalog.TileKind.ENEMY_SPAWN: color = base.darkened(0.34)
		StructureCatalog.TileKind.ALTAR: color = Color("d8c892")
		StructureCatalog.TileKind.ENTRANCE: color = Color("292832")
		StructureCatalog.TileKind.CAMPFIRE: color = Color("e96d32")
	for y in WorldCoordinates.TILE_SIZE:
		for x in WorldCoordinates.TILE_SIZE:
			var pixel := color
			if tile_kind == StructureCatalog.TileKind.FLOOR and posmod(x + y, 8) == 0:
				pixel = color.lightened(0.07)
			elif tile_kind == StructureCatalog.TileKind.WALL and (x < 3 or y < 3):
				pixel = color.lightened(0.12)
			elif tile_kind == StructureCatalog.TileKind.CHEST and (x < 5 or x > 26 or y < 8 or y > 24):
				pixel = Color.TRANSPARENT
			elif tile_kind == StructureCatalog.TileKind.ENEMY_SPAWN and (x - 16) * (x - 16) + (y - 16) * (y - 16) > 45:
				pixel = Color.TRANSPARENT
			image.set_pixelv(origin + Vector2i(x, y), pixel)
