class_name PlayerBuildingLayer
extends Node2D

static var _shared_tile_set: TileSet
static var _shared_source_id := -1
static var _piece_codes: Dictionary = {}

var _catalog := BuildingCatalog.new()
var _ground_layer: TileMapLayer
var _structure_layer: TileMapLayer
var _roof_layer: TileMapLayer
var _placements: Array[Dictionary] = []


func _ready() -> void:
	_ensure_shared_tile_set()
	_ground_layer = _make_layer("PlayerBuildingGround", 4)
	_structure_layer = _make_layer("PlayerBuildingStructure", 8)
	_roof_layer = _make_layer("PlayerBuildingRoof", 12)
	add_child(_ground_layer)
	add_child(_structure_layer)
	add_child(_roof_layer)
	_render()


func apply_placements(placements: Array[Dictionary]) -> void:
	_placements.clear()
	for value in placements:
		_placements.append((value as Dictionary).duplicate(true))
	if is_inside_tree():
		_render()


func visible_placement_count() -> int:
	return _placements.size()


func solid_placement_count() -> int:
	var total := 0
	for record in _placements:
		var definition := _catalog.piece(StringName(record["piece_id"]))
		if bool(definition.get("collision", false)) and not bool(record.get("door_open", false)):
			total += 1
	return total


func _make_layer(layer_name: String, layer_z: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.z_index = layer_z
	layer.tile_set = _shared_tile_set
	return layer


func _render() -> void:
	if _ground_layer == null or _shared_source_id < 0:
		return
	_ground_layer.clear()
	_structure_layer.clear()
	_roof_layer.clear()
	for record in _placements:
		var piece_id := StringName(record["piece_id"])
		var definition := _catalog.piece(piece_id)
		var tile_value := record["world_tile"] as Array
		var local := WorldCoordinates.tile_to_local(Vector2i(int(tile_value[0]), int(tile_value[1])))
		var variant := int(record.get("rotation", 0)) / 90
		if StringName(definition.get("interactive", "")) == &"door" and bool(record.get("door_open", false)):
			variant = 4
		var atlas := Vector2i(int(_piece_codes[String(piece_id)]), variant)
		var target := _structure_layer
		match StringName(definition["placement_slot"]):
			&"ground": target = _ground_layer
			&"roof": target = _roof_layer
		target.set_cell(local, _shared_source_id, atlas, 0)


func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_tile_set.add_physics_layer(0)
	_shared_tile_set.set_physics_layer_collision_layer(0, 1)
	_shared_tile_set.set_physics_layer_collision_mask(0, 2)
	var piece_ids := _catalog.piece_ids()
	var variant_count := 5
	var image := Image.create(
		WorldCoordinates.TILE_SIZE * piece_ids.size(),
		WorldCoordinates.TILE_SIZE * variant_count,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(Color.TRANSPARENT)
	for code in piece_ids.size():
		var piece_id := piece_ids[code]
		_piece_codes[String(piece_id)] = code
		for variant in variant_count:
			_paint_piece(image, Vector2i(code, variant), piece_id, variant)
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = ImageTexture.create_from_image(image)
	atlas_source.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_source_id = _shared_tile_set.add_source(atlas_source)
	for code in piece_ids.size():
		var definition := _catalog.piece(piece_ids[code])
		for variant in variant_count:
			var coordinate := Vector2i(code, variant)
			atlas_source.create_tile(coordinate)
			var open_door := StringName(definition.get("interactive", "")) == &"door" and variant == 4
			if bool(definition.get("collision", false)) and not open_door:
				var tile_data := atlas_source.get_tile_data(coordinate, 0)
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
				]))


func _paint_piece(image: Image, atlas: Vector2i, piece_id: StringName, variant: int) -> void:
	var definition := _catalog.piece(piece_id)
	var category := StringName(definition["category"])
	var base := _catalog.color(piece_id)
	if category == &"roof":
		base.a = 0.68
	var origin := atlas * WorldCoordinates.TILE_SIZE
	for y in WorldCoordinates.TILE_SIZE:
		for x in WorldCoordinates.TILE_SIZE:
			var pixel := base
			var border := x < 3 or x > 28 or y < 3 or y > 28
			match category:
				&"floor":
					if posmod(x + y, 8) == 0: pixel = base.lightened(0.08)
				&"wall":
					if border or y % 9 == 0: pixel = base.lightened(0.10)
				&"door":
					if variant == 4 and x > 8: pixel = Color.TRANSPARENT
					elif border: pixel = base.darkened(0.20)
				&"roof":
					if posmod(x + y, 7) < 2: pixel = base.lightened(0.09)
				&"furniture":
					if x < 5 or x > 26 or y < 8 or y > 23: pixel = Color.TRANSPARENT
				&"chest":
					if x < 4 or x > 27 or y < 8 or y > 25: pixel = Color.TRANSPARENT
					elif y == 16: pixel = base.darkened(0.22)
				&"light":
					if absi(x - 16) > 3 and y > 8: pixel = Color.TRANSPARENT
					elif y < 10 and Vector2(x - 16, y - 8).length() > 7.0: pixel = Color.TRANSPARENT
				&"station":
					if piece_id == &"campfire" and Vector2(x - 16, y - 17).length() > 11.0: pixel = Color.TRANSPARENT
					elif piece_id == &"workbench" and (x < 3 or x > 28 or y < 8 or y > 25): pixel = Color.TRANSPARENT
					elif piece_id == &"cooking_pot":
						if Vector2(x - 16, y - 16).length() > 12.0: pixel = Color.TRANSPARENT
						elif Vector2(x - 16, y - 16).length() < 7.0: pixel = base.darkened(0.18)
					elif piece_id == &"smelter":
						if x < 4 or x > 27 or y < 4 or y > 28: pixel = Color.TRANSPARENT
						elif x > 10 and x < 22 and y > 13 and y < 25: pixel = Color("e47b42")
				&"fence":
					if y < 10 or y > 24 or (y > 13 and y < 20 and x % 12 > 3): pixel = Color.TRANSPARENT
				&"automation":
					if piece_id == &"automatic_smelter":
						if x < 4 or x > 27 or y < 4 or y > 28: pixel = Color.TRANSPARENT
						elif x > 10 and x < 22 and y > 13 and y < 25: pixel = Color("f0904f")
					else:
						if y < 9 or y > 23: pixel = Color.TRANSPARENT
						elif posmod(x, 8) < 2: pixel = base.lightened(0.18)
				&"homestead":
					var center := Vector2(x - 16, y - 16)
					if center.length() > 13.0: pixel = Color.TRANSPARENT
					elif center.length() < 6.0: pixel = base.lightened(0.25)
					elif absi(x - 16) < 2 or absi(y - 16) < 2: pixel = base.darkened(0.22)
			if variant < 4 and category in [&"door", &"furniture", &"chest", &"station"]:
				var direction: Vector2i = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][variant]
				var marker: Vector2i = Vector2i(16, 16) + direction * 9
				if Vector2i(x, y).distance_squared_to(marker) <= 3:
					pixel = base.lightened(0.35)
			if variant < 4 and category == &"automation":
				var flow: Vector2i = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][variant]
				var arrow: Vector2i = Vector2i(16, 16) + flow * 7
				if Vector2i(x, y).distance_squared_to(arrow) <= 5:
					pixel = base.lightened(0.42)
			image.set_pixelv(origin + Vector2i(x, y), pixel)
