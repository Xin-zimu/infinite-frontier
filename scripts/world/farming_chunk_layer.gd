class_name FarmingChunkLayer
extends Node2D

var _plots: Array[Dictionary] = []
var _catalog := FarmingCatalog.new()


func _ready() -> void:
	z_index = 7
	queue_redraw()


func apply_plots(values: Array[Dictionary]) -> void:
	_plots.clear()
	for value in values:
		_plots.append((value as Dictionary).duplicate(true))
	queue_redraw()


func visible_plot_count() -> int:
	return _plots.size()


func mature_crop_count() -> int:
	var result := 0
	for record in _plots:
		if bool(record.get("mature", false)):
			result += 1
	return result


func _draw() -> void:
	for record in _plots:
		var tile_value := record.get("world_tile", [0, 0]) as Array
		var world_tile := Vector2i(int(tile_value[0]), int(tile_value[1]))
		var local := WorldCoordinates.tile_to_local(world_tile)
		var origin := Vector2(local * WorldCoordinates.TILE_SIZE)
		var wet := int(record.get("watered_day", -1)) >= int(record.get("last_simulated_day", 0))
		var soil_color := Color("75543d") if wet else Color("866347")
		draw_rect(Rect2(origin + Vector2(2, 2), Vector2.ONE * float(WorldCoordinates.TILE_SIZE - 4)), soil_color, true)
		for line_index in 3:
			var line_y := origin.y + 8.0 + float(line_index) * 8.0
			draw_line(Vector2(origin.x + 4.0, line_y), Vector2(origin.x + 28.0, line_y), Color("4f392d"), 1.0)
		var crop_id := StringName(record.get("crop_id", ""))
		if crop_id.is_empty():
			continue
		var crop := _catalog.crop(crop_id)
		var stage_count := maxi(2, int(crop.get("stage_count", 2)))
		var progress := float(int(record.get("stage", 0)) + 1) / float(stage_count)
		var crop_color := _catalog.crop_color(crop_id)
		var radius := 3.0 + progress * (9.0 if bool(crop.get("fruit_tree", false)) else 6.0)
		var center := origin + Vector2.ONE * float(WorldCoordinates.TILE_SIZE) * 0.5
		if bool(crop.get("fruit_tree", false)):
			draw_rect(Rect2(center + Vector2(-2.0, 1.0), Vector2(4.0, 11.0)), Color("6f4b32"), true)
		draw_circle(center - Vector2(0.0, 2.0), radius, crop_color)
		if bool(record.get("mature", false)):
			draw_arc(center - Vector2(0.0, 2.0), radius + 2.0, 0.0, TAU, 20, Color("f0d56a"), 2.0)
