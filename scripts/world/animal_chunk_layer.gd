class_name AnimalChunkLayer
extends Node2D

var _wild_animals: Array[Dictionary] = []
var _interacted_animals: Array[Dictionary] = []
var _catalog := HusbandryCatalog.new()


func _ready() -> void:
	z_index = 15
	queue_redraw()


func apply_animals(wild_values: Array[Dictionary], interacted_values: Array[Dictionary]) -> void:
	_wild_animals.clear()
	_interacted_animals.clear()
	for value in wild_values:
		_wild_animals.append((value as Dictionary).duplicate(true))
	for value in interacted_values:
		_interacted_animals.append((value as Dictionary).duplicate(true))
	queue_redraw()


func visible_animal_count() -> int:
	return _wild_animals.size() + _interacted_animals.size()


func tamed_animal_count() -> int:
	var total := 0
	for record in _interacted_animals:
		if bool(record.get("tamed", false)):
			total += 1
	return total


func sleeping_animal_count() -> int:
	var total := 0
	for record in _interacted_animals:
		if bool(record.get("sleeping", false)):
			total += 1
	return total


func _draw() -> void:
	for record in _wild_animals:
		_draw_animal(record, true)
	for record in _interacted_animals:
		_draw_animal(record, false)


func _draw_animal(record: Dictionary, wild: bool) -> void:
	var tile_value := record.get("world_tile", [0, 0]) as Array
	var world_tile := Vector2i(int(tile_value[0]), int(tile_value[1]))
	var local := WorldCoordinates.tile_to_local(world_tile)
	var center := Vector2(local * WorldCoordinates.TILE_SIZE) + Vector2(16, 18)
	var animal_type := StringName(record.get("animal_type", "chicken"))
	var definition := _catalog.animal(animal_type)
	var base := _catalog.color(animal_type)
	var adult := not record.has("adult_day") or int(record.get("last_simulated_day", 1)) >= int(record.get("adult_day", 1))
	var size := 7.0 if animal_type == &"chicken" else (11.0 if adult else 7.0)
	if bool(record.get("sleeping", false)):
		base = base.darkened(0.25)
		draw_string(ThemeDB.fallback_font, center + Vector2(7, -9), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b8c9dc"))
	draw_circle(center, size, base)
	draw_circle(center + Vector2(size * 0.65, -size * 0.45), size * 0.55, base.lightened(0.06))
	var eye := center + Vector2(size * 0.9, -size * 0.55)
	draw_circle(eye, 1.2, Color("20252a"))
	if wild:
		draw_arc(center, size + 2.0, 0.0, TAU, 18, Color("d8b56f"), 1.5)
	elif bool(record.get("tamed", false)):
		draw_arc(center, size + 2.0, 0.0, TAU, 18, Color("79c993"), 2.0)
	if int(record.get("product_ready", 0)) > 0:
		draw_circle(center + Vector2(-size, -size), 3.0, Color("f0d56a"))
