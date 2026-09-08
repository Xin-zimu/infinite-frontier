class_name BoatLayer
extends Node2D

# 少量已部署船只的表现层：每艘船一次多边形绘制，不使用独立节点。
var _boats: Array[Dictionary] = []
var _boarded_id := ""
var _item_catalog := ItemCatalog.new()


func set_boats(boat_records: Array[Dictionary], boarded_id := "") -> void:
	_boats = boat_records
	_boarded_id = boarded_id
	visible = not _boats.is_empty()
	queue_redraw()


func _draw() -> void:
	for record in _boats:
		var tile_value: Array = record.get("world_tile", [0, 0])
		var origin := WorldCoordinates.tile_to_world_pixel(Vector2i(int(tile_value[0]), int(tile_value[1])), true)
		var item_id := StringName(record.get("item_id", "rowboat"))
		var hull := Color("a97c50")
		if _item_catalog.has_item(item_id):
			hull = _item_catalog.item_color(item_id)
		var boarded := String(record.get("boat_id", "")) == _boarded_id
		_draw_boat(origin, hull, boarded)


func _draw_boat(origin: Vector2, hull: Color, boarded: bool) -> void:
	var trim := Color("6e5138")
	var interior := Color("d9c3a0")
	if boarded:
		trim = Color("f2ecdc")
	var points := PackedVector2Array([
		origin + Vector2(-10, -2),
		origin + Vector2(10, -2),
		origin + Vector2(6, 7),
		origin + Vector2(-6, 7),
	])
	draw_colored_polygon(points, hull)
	var deck := PackedVector2Array([
		origin + Vector2(-7, -1),
		origin + Vector2(7, -1),
		origin + Vector2(4, 4),
		origin + Vector2(-4, 4),
	])
	draw_colored_polygon(deck, interior)
	draw_line(origin + Vector2(-10, -2), origin + Vector2(10, -2), trim, 1.0)
	draw_line(origin + Vector2(0, -6), origin + Vector2(0, -2), trim, 1.5)
	draw_rect(Rect2(origin + Vector2(-1, -8), Vector2(2, 2)), trim)
