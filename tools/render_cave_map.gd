extends SceneTree

const START_CHUNK := Vector2i(-3, -3)
const REGION_CHUNKS := Vector2i(6, 4)
const PIXELS_PER_TILE := 3
const DEFAULT_OUTPUT := "res://releases/v1.6.0/screenshots/cave-preview.png"


func _initialize() -> void:
	var output_path := DEFAULT_OUTPUT
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_path = String(user_args[0])
	var seed := WorldSeed.from_text("无尽边境-洞穴预览")
	var generator := CaveGenerator.new(seed)
	var resources := ResourceCatalog.new()
	var width_tiles := REGION_CHUNKS.x * WorldCoordinates.CHUNK_SIZE
	var height_tiles := REGION_CHUNKS.y * WorldCoordinates.CHUNK_SIZE
	var image := Image.create(width_tiles * PIXELS_PER_TILE, height_tiles * PIXELS_PER_TILE, false, Image.FORMAT_RGBA8)
	for chunk_y in REGION_CHUNKS.y:
		for chunk_x in REGION_CHUNKS.x:
			var chunk := generator.generate_chunk(START_CHUNK + Vector2i(chunk_x, chunk_y))
			for local_y in WorldCoordinates.CHUNK_SIZE:
				for local_x in WorldCoordinates.CHUNK_SIZE:
					var local := Vector2i(local_x, local_y)
					var map_tile := Vector2i(chunk_x * WorldCoordinates.CHUNK_SIZE + local_x, chunk_y * WorldCoordinates.CHUNK_SIZE + local_y)
					var color := Color("171a22") if chunk.cave_cell_at(local) == CaveGenerator.Cell.WALL else Color("343741")
					match chunk.cave_feature_at(local):
						CaveGenerator.Feature.EXIT: color = Color("6f92a8")
						CaveGenerator.Feature.TORCH: color = Color("ffb347")
						CaveGenerator.Feature.CHEST: color = Color("d8ac55")
					_fill_tile(image, map_tile, color)
			for index in chunk.resource_count():
				var resource_tile := Vector2i(chunk_x * WorldCoordinates.CHUNK_SIZE, chunk_y * WorldCoordinates.CHUNK_SIZE) + chunk.resource_local_at(index)
				_fill_tile(image, resource_tile, resources.color_for_code(chunk.resource_code_at(index)).lightened(0.18))
	_draw_chunk_guides(image)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Unable to save cave preview: %s" % error_string(error))
		quit(1)
		return
	print("CAVE_MAP | chunks=%dx%d origin=%s output=%s" % [REGION_CHUNKS.x, REGION_CHUNKS.y, START_CHUNK, output_path])
	quit(0)


func _fill_tile(image: Image, tile: Vector2i, color: Color) -> void:
	var origin := tile * PIXELS_PER_TILE
	for y in PIXELS_PER_TILE:
		for x in PIXELS_PER_TILE:
			image.set_pixelv(origin + Vector2i(x, y), color)


func _draw_chunk_guides(image: Image) -> void:
	var step := WorldCoordinates.CHUNK_SIZE * PIXELS_PER_TILE
	var guide := Color("d4bf7880")
	for x in range(0, image.get_width(), step):
		for y in image.get_height():
			image.set_pixel(x, y, guide)
	for y in range(0, image.get_height(), step):
		for x in image.get_width():
			image.set_pixel(x, y, guide)
