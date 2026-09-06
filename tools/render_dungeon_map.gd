extends SceneTree

const DUNGEON_ID := "dungeon_-17_29"
const ANCHOR_CHUNK := Vector2i(-1, 0)
const PIXELS_PER_TILE := 12
const DEFAULT_OUTPUT := "res://releases/v1.7.0/screenshots/dungeon-preview.png"


func _initialize() -> void:
	var output_path := DEFAULT_OUTPUT
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_path = String(user_args[0])
	var generator := DungeonGenerator.new(WorldSeed.from_text("无尽边境-地牢预览"), DUNGEON_ID, ANCHOR_CHUNK)
	var chunk := generator.generate_chunk(ANCHOR_CHUNK)
	var image_size := WorldCoordinates.CHUNK_SIZE * PIXELS_PER_TILE
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			var color := Color("17131f") if chunk.dungeon_cell_at(local) == DungeonGenerator.Cell.WALL else Color("39323f")
			match chunk.dungeon_feature_at(local):
				DungeonGenerator.Feature.EXIT: color = Color("79a8c7")
				DungeonGenerator.Feature.LOCKED_DOOR: color = Color("9c627a")
				DungeonGenerator.Feature.KEY: color = Color("f3d56b")
				DungeonGenerator.Feature.TRAP: color = Color("cc5963")
				DungeonGenerator.Feature.CHEST: color = Color("c88b4d")
				DungeonGenerator.Feature.ELITE_SPAWN: color = Color("e47b7f")
				DungeonGenerator.Feature.BOSS_SPAWN: color = Color("bd8bea")
			_fill_tile(image, local, color)
			if chunk.dungeon_cell_at(local) == DungeonGenerator.Cell.WALL:
				_draw_wall_detail(image, local)
	_draw_border(image)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Unable to save dungeon preview: %s" % error_string(error))
		quit(1)
		return
	print("DUNGEON_MAP | id=%s anchor=%s checksum=%s output=%s" % [DUNGEON_ID, ANCHOR_CHUNK, chunk.checksum, output_path])
	quit(0)


func _fill_tile(image: Image, tile: Vector2i, color: Color) -> void:
	var origin := tile * PIXELS_PER_TILE
	for y in PIXELS_PER_TILE:
		for x in PIXELS_PER_TILE:
			var pixel := color
			if (x + y) % 9 == 0:
				pixel = color.lightened(0.06)
			image.set_pixelv(origin + Vector2i(x, y), pixel)


func _draw_wall_detail(image: Image, tile: Vector2i) -> void:
	var origin := tile * PIXELS_PER_TILE
	var accent := Color("2b2333")
	for x in range(1, PIXELS_PER_TILE - 1):
		image.set_pixelv(origin + Vector2i(x, 2), accent)
		image.set_pixelv(origin + Vector2i(x, PIXELS_PER_TILE - 2), accent)


func _draw_border(image: Image) -> void:
	var border := Color("d5b9e5")
	for x in image.get_width():
		image.set_pixel(x, 0, border)
		image.set_pixel(x, image.get_height() - 1, border)
	for y in image.get_height():
		image.set_pixel(0, y, border)
		image.set_pixel(image.get_width() - 1, y, border)
