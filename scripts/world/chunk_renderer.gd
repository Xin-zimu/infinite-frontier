class_name ChunkRenderer
extends TileMapLayer

enum ViewMode {
	TERRAIN,
	BIOME,
	CLIMATE,
	ELEVATION,
}

const FIELD_STEPS := 16
const CLIMATE_STEPS := 8

static var _shared_tile_set: TileSet
static var _shared_source_id := -1
static var _biome_count := 0
static var _biome_debug_offset := 0
static var _elevation_offset := 0
static var _climate_offset := 0
static var _water_feature_offset := 0
static var _cave_floor_offset := 0
static var _season_plant_tint := Color.WHITE

var _chunk: ChunkData
var _view_mode := ViewMode.TERRAIN
var _show_boundary := true
var _boundary_overlay: ChunkBoundaryOverlay
var _resource_layer: ResourceChunkLayer
var _structure_layer: StructureChunkLayer
var _village_layer: VillageChunkLayer
var _cave_layer: CaveChunkLayer
var _dungeon_layer: DungeonChunkLayer
var _player_building_layer: PlayerBuildingLayer
var _farming_layer: FarmingChunkLayer
var _animal_layer: AnimalChunkLayer
var _collected_resources: Dictionary = {}
var _opened_cave_chests: Dictionary = {}
var _dungeon_id := ""
var _dungeon_run_state: Dictionary = {}
var _player_buildings: Array[Dictionary] = []
var _farming_plots: Array[Dictionary] = []
var _wild_animals: Array[Dictionary] = []
var _interacted_animals: Array[Dictionary] = []


func _ready() -> void:
	z_index = -20
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set
	_boundary_overlay = ChunkBoundaryOverlay.new()
	add_child(_boundary_overlay)
	_village_layer = VillageChunkLayer.new()
	add_child(_village_layer)
	_structure_layer = StructureChunkLayer.new()
	add_child(_structure_layer)
	_cave_layer = CaveChunkLayer.new()
	add_child(_cave_layer)
	_dungeon_layer = DungeonChunkLayer.new()
	add_child(_dungeon_layer)
	_player_building_layer = PlayerBuildingLayer.new()
	add_child(_player_building_layer)
	_farming_layer = FarmingChunkLayer.new()
	add_child(_farming_layer)
	_animal_layer = AnimalChunkLayer.new()
	add_child(_animal_layer)
	_resource_layer = ResourceChunkLayer.new()
	add_child(_resource_layer)


func apply_chunk(chunk: ChunkData) -> void:
	_chunk = chunk
	position = WorldCoordinates.tile_to_world_pixel(chunk.chunk_position * WorldCoordinates.CHUNK_SIZE)
	_render()
	if _village_layer != null:
		_village_layer.apply_chunk(chunk)
	if _structure_layer != null:
		_structure_layer.apply_chunk(chunk)
	if _cave_layer != null:
		_cave_layer.apply_chunk(chunk, _opened_cave_chests)
	if _dungeon_layer != null:
		_dungeon_layer.apply_chunk(chunk, _dungeon_id, _dungeon_run_state)
	if _player_building_layer != null:
		_player_building_layer.apply_placements(_player_buildings)
	if _farming_layer != null:
		_farming_layer.apply_plots(_farming_plots)
	if _animal_layer != null:
		_animal_layer.apply_animals(_wild_animals, _interacted_animals)
	if _resource_layer != null:
		_resource_layer.apply_chunk(chunk, _collected_resources)


func set_collected_resources(collected_resources: Dictionary) -> void:
	_collected_resources = collected_resources
	if _resource_layer != null and _chunk != null:
		_resource_layer.apply_chunk(_chunk, _collected_resources)


func set_opened_cave_chests(opened_chests: Dictionary) -> void:
	_opened_cave_chests = opened_chests
	if _cave_layer != null and _chunk != null:
		_cave_layer.apply_chunk(_chunk, _opened_cave_chests)


func set_dungeon_state(dungeon_id: String, run_state: Dictionary) -> void:
	_dungeon_id = dungeon_id
	_dungeon_run_state = run_state.duplicate(true)
	if _dungeon_layer != null and _chunk != null:
		_dungeon_layer.apply_chunk(_chunk, _dungeon_id, _dungeon_run_state)


func set_player_buildings(placements: Array[Dictionary]) -> void:
	_player_buildings.clear()
	for value in placements:
		_player_buildings.append((value as Dictionary).duplicate(true))
	if _player_building_layer != null:
		_player_building_layer.apply_placements(_player_buildings)


func visible_player_building_count() -> int:
	return _player_building_layer.visible_placement_count() if _player_building_layer != null else 0


func solid_player_building_count() -> int:
	return _player_building_layer.solid_placement_count() if _player_building_layer != null else 0


func set_farming_plots(plots: Array[Dictionary]) -> void:
	_farming_plots.clear()
	for value in plots:
		_farming_plots.append((value as Dictionary).duplicate(true))
	if _farming_layer != null:
		_farming_layer.apply_plots(_farming_plots)


func visible_farming_plot_count() -> int:
	return _farming_layer.visible_plot_count() if _farming_layer != null else 0


func mature_farming_crop_count() -> int:
	return _farming_layer.mature_crop_count() if _farming_layer != null else 0


func set_husbandry_animals(wild_animals: Array[Dictionary], interacted_animals: Array[Dictionary]) -> void:
	_wild_animals.clear()
	_interacted_animals.clear()
	for value in wild_animals:
		_wild_animals.append((value as Dictionary).duplicate(true))
	for value in interacted_animals:
		_interacted_animals.append((value as Dictionary).duplicate(true))
	if _animal_layer != null:
		_animal_layer.apply_animals(_wild_animals, _interacted_animals)


func visible_husbandry_animal_count() -> int:
	return _animal_layer.visible_animal_count() if _animal_layer != null else 0


func tamed_husbandry_animal_count() -> int:
	return _animal_layer.tamed_animal_count() if _animal_layer != null else 0


func sleeping_husbandry_animal_count() -> int:
	return _animal_layer.sleeping_animal_count() if _animal_layer != null else 0


func play_resource_hit(resource_key: String, destroyed: bool) -> void:
	if _resource_layer != null:
		_resource_layer.play_hit(resource_key, destroyed)


func visible_resource_count() -> int:
	return _resource_layer.visible_resource_count() if _resource_layer != null else 0


func set_debug_options(view_mode: ViewMode, show_boundary: bool) -> void:
	var mode_changed := _view_mode != view_mode
	_view_mode = view_mode
	_show_boundary = show_boundary
	if _boundary_overlay != null:
		_boundary_overlay.visible = _show_boundary
	if mode_changed:
		_render()


static func view_mode_name(view_mode: ViewMode) -> String:
	match view_mode:
		ViewMode.BIOME:
			return "群系"
		ViewMode.CLIMATE:
			return "气候"
		ViewMode.ELEVATION:
			return "海拔"
		_:
			return "地形"


func _render() -> void:
	clear()
	if _chunk == null or _shared_source_id < 0:
		return
	for local_y in WorldCoordinates.CHUNK_SIZE:
		for local_x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(local_x, local_y)
			var atlas_index := _atlas_index_for(local)
			set_cell(local, _shared_source_id, Vector2i(atlas_index, 0), 0)


func _atlas_index_for(local: Vector2i) -> int:
	if _chunk.world_layer != &"surface":
		return _cave_floor_offset
	match _view_mode:
		ViewMode.BIOME:
			return _biome_debug_offset + _chunk.biome_at(local)
		ViewMode.CLIMATE:
			var temperature_step := mini(int(_chunk.temperature_at(local) * CLIMATE_STEPS), CLIMATE_STEPS - 1)
			var moisture_step := mini(int(_chunk.moisture_at(local) * CLIMATE_STEPS), CLIMATE_STEPS - 1)
			return _climate_offset + temperature_step * CLIMATE_STEPS + moisture_step
		ViewMode.ELEVATION:
			return _elevation_offset + mini(int(_chunk.elevation_at(local) * FIELD_STEPS), FIELD_STEPS - 1)
		_:
			var feature := _chunk.water_feature_at(local)
			if feature != HydrologyGenerator.Feature.NONE:
				return _water_feature_offset + feature - 1
			return _chunk.biome_at(local)


static func set_season_plant_tint(color: Color) -> void:
	_season_plant_tint = color


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	var catalog := BiomeCatalog.new()
	_biome_count = catalog.biome_count()
	_biome_debug_offset = _biome_count
	_elevation_offset = _biome_debug_offset + _biome_count
	_climate_offset = _elevation_offset + FIELD_STEPS
	_water_feature_offset = _climate_offset + CLIMATE_STEPS * CLIMATE_STEPS
	_cave_floor_offset = _water_feature_offset + HydrologyGenerator.Feature.size() - 1
	var tile_count := _cave_floor_offset + 1
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	var image := Image.create(WorldCoordinates.TILE_SIZE * tile_count, WorldCoordinates.TILE_SIZE, false, Image.FORMAT_RGBA8)
	for tile_index in tile_count:
		var base_color: Color
		var patterned := false
		if tile_index < _biome_count:
			base_color = catalog.color_for_code(tile_index)
			base_color = Color(
				base_color.r * (1.0 - 0.35) + _season_plant_tint.r * 0.35,
				base_color.g * (1.0 - 0.35) + _season_plant_tint.g * 0.35,
				base_color.b * (1.0 - 0.35) + _season_plant_tint.b * 0.35,
				base_color.a
			)
			patterned = true
		elif tile_index < _elevation_offset:
			base_color = catalog.color_for_code(tile_index - _biome_debug_offset, true)
		elif tile_index < _climate_offset:
			var elevation_value := float(tile_index - _elevation_offset) / float(FIELD_STEPS - 1)
			base_color = Color(elevation_value, elevation_value, elevation_value)
		elif tile_index < _water_feature_offset:
			var climate_index := tile_index - _climate_offset
			var temperature := float(climate_index / CLIMATE_STEPS) / float(CLIMATE_STEPS - 1)
			var moisture := float(climate_index % CLIMATE_STEPS) / float(CLIMATE_STEPS - 1)
			base_color = _climate_color(temperature, moisture)
		elif tile_index < _cave_floor_offset:
			base_color = _water_feature_color(tile_index - _water_feature_offset + 1)
			patterned = true
		else:
			base_color = Color("30323b")
			patterned = true
		_paint_tile(image, tile_index, base_color, patterned)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	for tile_index in tile_count:
		atlas.create_tile(Vector2i(tile_index, 0))
	_shared_source_id = _shared_tile_set.add_source(atlas)


static func _paint_tile(image: Image, tile_index: int, base_color: Color, patterned: bool) -> void:
	var origin_x := tile_index * WorldCoordinates.TILE_SIZE
	for y in WorldCoordinates.TILE_SIZE:
		for x in WorldCoordinates.TILE_SIZE:
			var color := base_color
			if patterned:
				var pattern := posmod(x * 3 + y * 5 + tile_index * 7, 23)
				if pattern == 0 or (tile_index <= 1 and y % 11 == 3):
					color = base_color.lightened(0.09)
				elif pattern == 11:
					color = base_color.darkened(0.07)
			image.set_pixel(origin_x + x, y, color)


static func _climate_color(temperature: float, moisture: float) -> Color:
	var dry_wet := Color("c7a267").lerp(Color("39745d"), moisture)
	var cold_hot := Color("7198c5").lerp(Color("ce7650"), temperature)
	return dry_wet.lerp(cold_hot, 0.42)


static func _water_feature_color(feature: int) -> Color:
	match feature:
		HydrologyGenerator.Feature.RIVER: return Color("3d86c6")
		HydrologyGenerator.Feature.LAKE: return Color("3279b8")
		HydrologyGenerator.Feature.ICE_LAKE: return Color("9dd7e5")
		HydrologyGenerator.Feature.OASIS: return Color("39a6a0")
		HydrologyGenerator.Feature.BANK: return Color("b99362")
		HydrologyGenerator.Feature.BRIDGE: return Color("875b35")
		_: return Color("ff00ff")
