class_name WorldEventPanel
extends Control

var _stream_manager: ChunkStreamManager
var _modal: Control
var _tracker_panel: PanelContainer
var _tracker_label: Label
var _summary_label: Label
var _active_list: VBoxContainer
var _upcoming_list: VBoxContainer
var _history_label: Label


func _ready() -> void:
	name = "WorldEventPanel"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_tracker()
	_build_modal()
	EventBus.world_event_state_changed.connect(_on_world_event_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_world_event_state_changed(stream_manager.world_event_snapshot())


func is_event_open() -> bool:
	return _modal.visible


func toggle_events() -> void:
	set_event_open(not _modal.visible)


func set_event_open(open: bool) -> void:
	_modal.visible = open
	if open and _stream_manager != null:
		_on_world_event_state_changed(_stream_manager.world_event_snapshot())
		EventBus.interaction_feedback.emit("世界事件时间表 · 当前、预告与历史状态 · V 关闭", true)


func _build_tracker() -> void:
	_tracker_panel = PanelContainer.new()
	_tracker_panel.name = "WorldEventTracker"
	UiLayout.top_right(_tracker_panel, Vector2(298, 108), Vector2(UiLayout.EDGE_MARGIN, 470))
	_tracker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("161524df")
	style.border_color = Color("9d79bd")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	_tracker_panel.add_theme_stylebox_override("panel", style)
	add_child(_tracker_panel)
	_tracker_label = Label.new()
	_tracker_label.name = "WorldEventTrackerLabel"
	_tracker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_label.add_theme_color_override("font_color", Color("eadff2"))
	_tracker_panel.add_child(_tracker_label)


func _build_modal() -> void:
	_modal = Control.new()
	_modal.name = "WorldEventModal"
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("02070be6")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(shade)
	var window := PanelContainer.new()
	window.name = "WorldEventWindow"
	UiLayout.centered(window, Vector2(960, 610))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("11131dfa")
	style.border_color = Color("9d79bd")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 18
	window.add_theme_stylebox_override("panel", style)
	_modal.add_child(window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "世界事件时间表"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("e7cbff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_summary_label = Label.new()
	_summary_label.name = "WorldEventSummaryLabel"
	_summary_label.add_theme_color_override("font_color", Color("9fc2cf"))
	title_row.add_child(_summary_label)
	var close := Button.new()
	close.name = "CloseWorldEventPanel"
	close.text = "关闭 [V]"
	close.pressed.connect(func() -> void: set_event_open(false))
	title_row.add_child(close)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var active_panel := PanelContainer.new()
	active_panel.custom_minimum_size = Vector2(430, 0)
	active_panel.add_theme_stylebox_override("panel", _inner_style("744d8e"))
	body.add_child(active_panel)
	var active_column := VBoxContainer.new()
	active_column.add_theme_constant_override("separation", 9)
	active_panel.add_child(active_column)
	var active_title := Label.new()
	active_title.text = "当前事件"
	active_title.add_theme_font_size_override("font_size", 20)
	active_title.add_theme_color_override("font_color", Color("e7cbff"))
	active_column.add_child(active_title)
	_active_list = VBoxContainer.new()
	_active_list.name = "ActiveWorldEventList"
	_active_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_active_list.add_theme_constant_override("separation", 8)
	active_column.add_child(_active_list)
	var history_title := Label.new()
	history_title.text = "最近结果"
	history_title.add_theme_color_override("font_color", Color("9fc2cf"))
	active_column.add_child(history_title)
	_history_label = Label.new()
	_history_label.name = "WorldEventHistoryLabel"
	_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_history_label.custom_minimum_size = Vector2(0, 115)
	active_column.add_child(_history_label)
	var schedule_panel := PanelContainer.new()
	schedule_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_panel.add_theme_stylebox_override("panel", _inner_style("485e77"))
	body.add_child(schedule_panel)
	var schedule_column := VBoxContainer.new()
	schedule_column.add_theme_constant_override("separation", 8)
	schedule_panel.add_child(schedule_column)
	var schedule_title := Label.new()
	schedule_title.text = "后续预告"
	schedule_title.add_theme_font_size_override("font_size", 20)
	schedule_title.add_theme_color_override("font_color", Color("b8ddf0"))
	schedule_column.add_child(schedule_title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	schedule_column.add_child(scroll)
	_upcoming_list = VBoxContainer.new()
	_upcoming_list.name = "UpcomingWorldEventList"
	_upcoming_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upcoming_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_upcoming_list)
	_modal.visible = false


func _inner_style(border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("091016e8")
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_world_event_state_changed(snapshot: Dictionary) -> void:
	var active := snapshot.get("active", []) as Array
	var upcoming := snapshot.get("upcoming", []) as Array
	_summary_label.text = "进行中 %d · 历史 %d" % [active.size(), int(snapshot.get("history_count", 0))]
	_rebuild_active(active)
	_rebuild_upcoming(upcoming)
	_apply_history(snapshot.get("history", []) as Array)
	_apply_tracker(active, upcoming)


func _rebuild_active(values: Array) -> void:
	for child in _active_list.get_children():
		child.queue_free()
	if values.is_empty():
		var empty := Label.new()
		empty.text = "当前区域暂时平静。"
		empty.add_theme_color_override("font_color", Color("8fa79b"))
		_active_list.add_child(empty)
		return
	for value in values:
		var view := value as Dictionary
		var label := Label.new()
		label.name = "ActiveWorldEvent_%s" % String(view["event_id"])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%s · 剩余 %s\n%s\n目标：%s  %d/%d" % [
			view["display_name"],
			_format_duration(float(view["seconds_remaining"])),
			view["description"],
			view["objective_display_name"],
			int(view["progress"]),
			int(view["goal"]),
		]
		label.add_theme_color_override("font_color", Color("f0ddff"))
		_active_list.add_child(label)


func _rebuild_upcoming(values: Array) -> void:
	for child in _upcoming_list.get_children():
		child.queue_free()
	for value in values:
		var plan := value as Dictionary
		var label := Label.new()
		label.name = "UpcomingWorldEvent_%s" % String(plan["instance_id"])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "第 %d 天 %02d:%02d · %s\n%s后开始" % [
			int(plan["day"]),
			int(floor(float(plan["hour"]))),
			int(round(fposmod(float(plan["hour"]), 1.0) * 60.0)),
			plan["display_name"],
			_format_duration(float(plan["starts_in_seconds"])),
		]
		label.add_theme_color_override("font_color", Color("c9dce8"))
		_upcoming_list.add_child(label)


func _apply_history(values: Array) -> void:
	if values.is_empty():
		_history_label.text = "尚无已结束事件。"
		return
	var lines: Array[String] = []
	for value in values.slice(0, mini(4, values.size())):
		var view := value as Dictionary
		lines.append("%s  ·  %s" % [view["display_name"], "已完成" if String(view["status"]) == "completed" else "已失效"])
	_history_label.text = "\n".join(lines)


func _apply_tracker(active: Array, upcoming: Array) -> void:
	if not active.is_empty():
		var view := active[0] as Dictionary
		_tracker_label.text = "世界事件 [V]\n%s · %s\n%s  %d/%d" % [
			view["display_name"],
			_format_duration(float(view["seconds_remaining"])),
			view["objective_display_name"],
			int(view["progress"]),
			int(view["goal"]),
		]
		return
	if not upcoming.is_empty():
		var plan := upcoming[0] as Dictionary
		_tracker_label.text = "世界事件 [V]\n下一项：%s\n%s后开始" % [plan["display_name"], _format_duration(float(plan["starts_in_seconds"]))]
		return
	_tracker_label.text = "世界事件 [V]\n时间表尚未生成"


func _format_duration(seconds: float) -> String:
	var whole := maxi(0, ceili(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]
