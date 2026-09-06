class_name NpcActor
extends Node2D

var _plan: Dictionary = {}
var _path: Array[Vector2i] = []
var _path_index := 0
var _speed := 54.0
var _activity := &"idle"
var _activity_display := "等待"
var _sleeping := false
var _body_color := Color.WHITE


func configure(plan: Dictionary, movement_speed: float) -> void:
	_plan = plan.duplicate(true)
	_speed = maxf(movement_speed, 1.0)
	_body_color = Color(String(_plan.get("color", "ffffff")))
	name = "NPC_%s" % String(_plan.get("id", "unknown")).replace(":", "_")
	global_position = WorldCoordinates.tile_to_world_pixel(_plan.get("home_tile", Vector2i.ZERO) as Vector2i, true)
	queue_redraw()


func npc_id() -> String:
	return String(_plan.get("id", ""))


func plan() -> Dictionary:
	return _plan.duplicate(true)


func activity() -> StringName:
	return _activity


func activity_display_name() -> String:
	return _activity_display


func is_sleeping() -> bool:
	return _sleeping


func current_world_tile() -> Vector2i:
	return WorldCoordinates.world_pixel_to_tile(global_position)


func set_schedule(entry: Dictionary, path: Array[Vector2i]) -> void:
	_activity = StringName(entry.get("activity", "idle"))
	_activity_display = String(entry.get("activity_display", "等待"))
	_sleeping = _activity == &"sleep"
	_path = path.duplicate()
	_path_index = 1 if _path.size() > 1 else 0
	queue_redraw()


func _process(delta: float) -> void:
	if _path.is_empty() or _path_index >= _path.size():
		return
	var target := WorldCoordinates.tile_to_world_pixel(_path[_path_index], true)
	global_position = global_position.move_toward(target, _speed * maxf(delta, 0.0))
	if global_position.distance_squared_to(target) <= 1.0:
		global_position = target
		_path_index += 1


func _draw() -> void:
	var color := _body_color.darkened(0.45) if _sleeping else _body_color
	draw_rect(Rect2(-7, -10, 14, 18), Color("172126"), true)
	draw_rect(Rect2(-6, -9, 12, 16), color, true)
	draw_rect(Rect2(-4, -13, 8, 6), color.lightened(0.18), true)
	if _sleeping:
		draw_circle(Vector2(7, -13), 2.0, Color("9fc2cf"))
	else:
		draw_circle(Vector2(-2, -11), 1.0, Color("152027"))
		draw_circle(Vector2(2, -11), 1.0, Color("152027"))
