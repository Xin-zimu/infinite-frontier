class_name ExplorationMapCanvas
extends Control

var _snapshot: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(590, 480)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	queue_redraw()


func _draw() -> void:
	var background := Rect2(Vector2.ZERO, size)
	draw_rect(background, Color("071014"), true)
	draw_rect(background.grow(-1.0), Color("355063"), false, 2.0)
	var chunks_value: Variant = _snapshot.get("chunks", [])
	if not chunks_value is Array or (chunks_value as Array).is_empty():
		return
	var chunks: Array[Vector2i] = []
	for value in chunks_value as Array:
		if value is Vector2i:
			chunks.append(value as Vector2i)
		elif value is Array and (value as Array).size() == 2:
			chunks.append(Vector2i(int((value as Array)[0]), int((value as Array)[1])))
	if chunks.is_empty():
		return
	var minimum := chunks[0]
	var maximum := chunks[0]
	for chunk in chunks:
		minimum.x = mini(minimum.x, chunk.x)
		minimum.y = mini(minimum.y, chunk.y)
		maximum.x = maxi(maximum.x, chunk.x)
		maximum.y = maxi(maximum.y, chunk.y)
	var player_chunk := _vector2i_from(_snapshot.get("player_chunk", Vector2i.ZERO))
	minimum.x = mini(minimum.x, player_chunk.x)
	minimum.y = mini(minimum.y, player_chunk.y)
	maximum.x = maxi(maximum.x, player_chunk.x)
	maximum.y = maxi(maximum.y, player_chunk.y)
	var map_rect := Rect2(Vector2(18, 18), size - Vector2(36, 36))
	var grid_size := Vector2i(maximum.x - minimum.x + 1, maximum.y - minimum.y + 1)
	var cell_size := minf(map_rect.size.x / float(maxi(1, grid_size.x)), map_rect.size.y / float(maxi(1, grid_size.y)))
	cell_size = clampf(cell_size, 4.0, 32.0)
	var rendered_size := Vector2(grid_size) * cell_size
	var origin := map_rect.position + (map_rect.size - rendered_size) * 0.5
	for chunk in chunks:
		var cell := Rect2(origin + Vector2(chunk - minimum) * cell_size, Vector2.ONE * cell_size)
		draw_rect(cell.grow(-0.75), Color("243d43"), true)
		draw_rect(cell.grow(-0.75), Color("48666d"), false, 1.0)
	for marker_value in _snapshot.get("markers", []) as Array:
		if not marker_value is Dictionary:
			continue
		var marker := marker_value as Dictionary
		var tile_value: Variant = marker.get("world_tile", [])
		if not tile_value is Array or (tile_value as Array).size() != 2:
			continue
		var marker_chunk := WorldCoordinates.tile_to_chunk(Vector2i(int((tile_value as Array)[0]), int((tile_value as Array)[1])))
		var center := origin + (Vector2(marker_chunk - minimum) + Vector2(0.5, 0.5)) * cell_size
		var marker_color := Color(String(marker.get("color", "ffffff")))
		if bool(marker.get("completed", false)):
			marker_color = marker_color.darkened(0.55)
		draw_circle(center, clampf(cell_size * 0.22, 2.5, 6.0), marker_color)
	var player_center := origin + (Vector2(player_chunk - minimum) + Vector2(0.5, 0.5)) * cell_size
	draw_circle(player_center, clampf(cell_size * 0.31, 3.0, 8.0), Color("fff2bd"))
	draw_circle(player_center, clampf(cell_size * 0.15, 1.5, 4.0), Color("24313a"))


func _vector2i_from(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value as Vector2i
	if value is Array and (value as Array).size() == 2:
		return Vector2i(int((value as Array)[0]), int((value as Array)[1]))
	return Vector2i.ZERO
