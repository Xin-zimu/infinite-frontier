class_name VillageChunkLayer
extends TileMapLayer

static var _shared_tile_set: TileSet
static var _shared_source_id := -1

var _chunk: ChunkData


func _ready() -> void:
	z_index = 2
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set


func apply_chunk(chunk: ChunkData) -> void:
	_chunk = chunk
	clear()
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			var feature := chunk.village_feature_at(local)
			if feature != VillagePlanner.Feature.NONE:
				set_cell(local, _shared_source_id, Vector2i(feature - 1, 0), 0)


func marker_count(marker_kind := -1) -> int:
	return _chunk.village_marker_count(marker_kind) if _chunk != null else 0


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	var catalog := VillageCatalog.new()
	var count := VillagePlanner.Feature.size() - 1
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	var image := Image.create(WorldCoordinates.TILE_SIZE * count, WorldCoordinates.TILE_SIZE, false, Image.FORMAT_RGBA8)
	for feature in range(1, VillagePlanner.Feature.size()):
		var color_name := "road"
		match feature:
			VillagePlanner.Feature.PLAZA: color_name = "plaza"
			VillagePlanner.Feature.BRIDGE: color_name = "bridge"
			VillagePlanner.Feature.HOUSE: color_name = "house"
			VillagePlanner.Feature.SHOP: color_name = "shop"
			VillagePlanner.Feature.WELL: color_name = "well"
			VillagePlanner.Feature.CAMPFIRE: color_name = "campfire"
		var color := catalog.color(color_name)
		for y in WorldCoordinates.TILE_SIZE:
			for x in WorldCoordinates.TILE_SIZE:
				var pixel := color.lightened(0.06) if posmod(x * 3 + y * 5, 19) == 0 else color
				image.set_pixel((feature - 1) * WorldCoordinates.TILE_SIZE + x, y, pixel)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	for feature in range(1, VillagePlanner.Feature.size()):
		atlas.create_tile(Vector2i(feature - 1, 0))
	_shared_source_id = _shared_tile_set.add_source(atlas)
