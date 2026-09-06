class_name ExplorationMapPanel
extends Control

var _stream_manager: ChunkStreamManager
var _map_canvas: ExplorationMapCanvas
var _summary_label: Label
var _layer_label: Label
var _travel_list: VBoxContainer


func _ready() -> void:
	name = "ExplorationMapPanel"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	visible = false
	EventBus.exploration_state_changed.connect(_on_exploration_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_exploration_state_changed(stream_manager.exploration_snapshot())


func is_map_open() -> bool:
	return visible


func toggle_map() -> void:
	set_map_open(not visible)


func set_map_open(open: bool) -> void:
	visible = open
	if open and _stream_manager != null:
		_on_exploration_state_changed(_stream_manager.exploration_snapshot())
		EventBus.interaction_feedback.emit("探索地图 · 已发现地点可快速旅行 · M 关闭", true)


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.name = "MapBackdrop"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("02070bd9")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var window := PanelContainer.new()
	window.name = "MapWindow"
	UiLayout.centered(window, Vector2(980, 620))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("09171df8")
	style.border_color = Color("66879a")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 18
	window.add_theme_stylebox_override("panel", style)
	add_child(window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "世界探索地图"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f3d58e"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_layer_label = Label.new()
	_layer_label.add_theme_color_override("font_color", Color("9fc2cf"))
	title_row.add_child(_layer_label)
	var close_button := Button.new()
	close_button.text = "关闭 [M]"
	close_button.pressed.connect(func() -> void: set_map_open(false))
	title_row.add_child(close_button)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_map_canvas = ExplorationMapCanvas.new()
	_map_canvas.name = "ExplorationMapCanvas"
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_map_canvas)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(270, 0)
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)
	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_color_override("font_color", Color("c7dce0"))
	side.add_child(_summary_label)
	var legend := Label.new()
	legend.text = "金色：玩家\n亮点：地点与首领\n暗色：已完成\n黑色：尚未探索"
	legend.add_theme_color_override("font_color", Color("89a5ad"))
	side.add_child(legend)
	var marker_button := Button.new()
	marker_button.name = "AddCustomMarkerButton"
	marker_button.text = "在当前位置添加标记"
	marker_button.pressed.connect(_on_add_marker_pressed)
	side.add_child(marker_button)
	var travel_title := Label.new()
	travel_title.text = "已解锁快速旅行点"
	travel_title.add_theme_font_size_override("font_size", 17)
	travel_title.add_theme_color_override("font_color", Color("f3d58e"))
	side.add_child(travel_title)
	var scroll := ScrollContainer.new()
	scroll.name = "TravelScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	_travel_list = VBoxContainer.new()
	_travel_list.name = "TravelPointList"
	_travel_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_travel_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_travel_list)


func _on_exploration_state_changed(snapshot: Dictionary) -> void:
	if _map_canvas == null:
		return
	_map_canvas.set_snapshot(snapshot)
	_layer_label.text = "当前位置：%s" % String(snapshot.get("world_layer_name", "地表"))
	_summary_label.text = "已发现区块：%d\n地点标记：%d\n传送点：%d\n区域首领：%d / 3" % [
		int(snapshot.get("discovered_chunks", 0)),
		int(snapshot.get("marker_count", 0)),
		int(snapshot.get("travel_point_count", 0)),
		int(snapshot.get("defeated_regional_bosses", 0)),
	]
	_rebuild_travel_points(snapshot.get("travel_points", []) as Array)


func _rebuild_travel_points(points: Array) -> void:
	for child in _travel_list.get_children():
		child.queue_free()
	if points.is_empty():
		var empty := Label.new()
		empty.text = "探索村庄、遗迹或地牢后解锁"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color("6f8990"))
		_travel_list.add_child(empty)
		return
	for point_value in points:
		if not point_value is Dictionary:
			continue
		var point := point_value as Dictionary
		var button := Button.new()
		button.text = String(point.get("display_name", "传送点"))
		button.tooltip_text = "快速旅行至此地点"
		button.pressed.connect(_on_travel_pressed.bind(String(point.get("id", ""))))
		_travel_list.add_child(button)


func _on_add_marker_pressed() -> void:
	if _stream_manager != null:
		_stream_manager.add_custom_map_marker()


func _on_travel_pressed(marker_id: String) -> void:
	if _stream_manager != null and _stream_manager.try_fast_travel(marker_id):
		set_map_open(false)
