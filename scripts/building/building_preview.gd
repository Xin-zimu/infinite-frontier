class_name BuildingPreview
extends Node2D

var _valid := false
var _color := Color("d65f5f80")
var _rotation_degrees := 0


func update_preview(world_tile: Vector2i, valid: bool, color_html: String, rotation: int) -> void:
	position = WorldCoordinates.tile_to_world_pixel(world_tile, true)
	_valid = valid
	_color = Color(color_html) if Color.html_is_valid(color_html) else Color("d65f5f")
	_color.a = 0.62 if valid else 0.48
	_rotation_degrees = rotation
	visible = true
	queue_redraw()


func hide_preview() -> void:
	visible = false


func _draw() -> void:
	var outline := Color("8ff0a8") if _valid else Color("ff6b6b")
	draw_rect(Rect2(-16, -16, 32, 32), _color, true)
	draw_rect(Rect2(-16, -16, 32, 32), outline, false, 2.0)
	var direction := Vector2.UP.rotated(deg_to_rad(float(_rotation_degrees)))
	draw_line(Vector2.ZERO, direction * 12.0, outline, 3.0)
