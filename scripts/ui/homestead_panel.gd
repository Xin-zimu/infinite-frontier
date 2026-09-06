class_name HomesteadPanel
extends Control

var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _summary_label: Label
var _base_list: VBoxContainer
var _status_label: Label
var _state: Dictionary = {}
var _refresh_elapsed := 0.0


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.homestead_state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if not is_homestead_open() or _stream_manager == null:
		return
	_refresh_elapsed += maxf(0.0, delta)
	if _refresh_elapsed >= 1.0:
		_refresh_elapsed = 0.0
		_on_state_changed(_stream_manager.homestead_state_snapshot())


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_state_changed(stream_manager.homestead_state_snapshot())


func is_homestead_open() -> bool:
	return _window != null and _window.visible


func toggle_homestead() -> void:
	set_homestead_open(not is_homestead_open())


func set_homestead_open(open: bool) -> void:
	_window.visible = open
	_refresh_elapsed = 0.0
	if open and _stream_manager != null:
		_on_state_changed(_stream_manager.homestead_state_snapshot())


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "HomesteadWindow"
	UiLayout.centered(_window, Vector2(820, 560))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101612f7")
	style.border_color = Color("d8bd68")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_window.add_theme_stylebox_override("panel", style)
	_window.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	_window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "家园与基地"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f1d889"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [X]"
	close.pressed.connect(func() -> void: set_homestead_open(false))
	title_row.add_child(close)
	_summary_label = Label.new()
	_summary_label.name = "HomesteadSummaryLabel"
	_summary_label.add_theme_color_override("font_color", Color("b7c9ad"))
	column.add_child(_summary_label)
	var scroll := ScrollContainer.new()
	scroll.name = "HomesteadBaseScroll"
	scroll.custom_minimum_size = Vector2(0, 390)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_base_list = VBoxContainer.new()
	_base_list.name = "HomesteadBaseList"
	_base_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_base_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_base_list)
	_status_label = Label.new()
	_status_label.name = "HomesteadStatusLabel"
	_status_label.text = "在 [K] 建造界面放置信标；每座基地自动管理范围内的长期建设循环。"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color("98aa91"))
	column.add_child(_status_label)
	_window.visible = false


func _on_state_changed(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_refresh()


func _refresh() -> void:
	if _base_list == null:
		return
	for child in _base_list.get_children():
		_base_list.remove_child(child)
		child.queue_free()
	var remaining := ceili(float(_state.get("teleport_cooldown_remaining", 0.0)))
	_summary_label.text = "基地 %d/%d · 管理半径 %d 格 · 信标间距至少 %d 格 · 传送%s" % [
		int(_state.get("base_count", 0)), int(_state.get("base_limit", 0)),
		int(_state.get("base_radius_tiles", 0)), int(_state.get("minimum_spacing_tiles", 0)),
		("冷却 %d 秒" % remaining) if remaining > 0 else "就绪",
	]
	for value in _state.get("bases", []) as Array:
		_add_base_row(value as Dictionary)
	if _base_list.get_child_count() == 0:
		var empty := Label.new()
		empty.name = "HomesteadEmptyLabel"
		empty.text = "尚未建立基地。准备 8 木材、8 石材和 2 铁锭，再放置一座家园信标。"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color("9eae98"))
		_base_list.add_child(empty)


func _add_base_row(view: Dictionary) -> void:
	var base_id := String(view["base_id"])
	var panel := PanelContainer.new()
	panel.name = "HomesteadBase_%s" % base_id.replace(":", "_")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263224") if bool(view.get("active", false)) else Color("182319")
	style.border_color = Color("d8bd68") if bool(view.get("active", false)) else Color("4d684c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	_base_list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 3)
	row.add_child(labels)
	var tile := view["world_tile"] as Array
	var title := Label.new()
	title.text = "%s%s · (%d, %d) · 半径 %d" % [
		String(view["display_name"]), " · 当前家园" if bool(view.get("active", false)) else "",
		int(tile[0]), int(tile[1]), int(view.get("radius_tiles", 0)),
	]
	title.add_theme_color_override("font_color", Color("f0d68a"))
	labels.add_child(title)
	var assets := view.get("assets", {}) as Dictionary
	var detail := Label.new()
	detail.text = "建筑 %d · 储物箱 %d（物品 %d）· 农田 %d（成熟 %d）· 驯养 %d（待收 %d）· 机器 %d" % [
		int(assets.get("buildings", 0)), int(assets.get("storage_chests", 0)), int(assets.get("stored_items", 0)),
		int(assets.get("farm_plots", 0)), int(assets.get("mature_crops", 0)), int(assets.get("tamed_animals", 0)),
		int(assets.get("ready_products", 0)), int(assets.get("automation_machines", 0)),
	]
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", Color("a5b6a0"))
	labels.add_child(detail)
	var progress := Label.new()
	var completed_names: Array[String] = []
	var pending_names: Array[String] = []
	for step_value in view.get("loop_steps", []) as Array:
		var step := step_value as Dictionary
		(completed_names if bool(step["complete"]) else pending_names).append(String(step["display_name"]))
	progress.text = "循环 %d/%d · 已完成：%s%s" % [
		int(view.get("completed_steps", 0)), int(view.get("total_steps", 0)),
		"、".join(completed_names) if not completed_names.is_empty() else "无",
		(" · 待建：" + "、".join(pending_names)) if not pending_names.is_empty() else " · 全部完成",
	]
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress.add_theme_font_size_override("font_size", 12)
	progress.add_theme_color_override("font_color", Color("8fd0a6") if bool(view.get("loop_complete", false)) else Color("c5b67b"))
	labels.add_child(progress)
	if bool(view.get("player_inside", false)):
		var inside := Label.new()
		inside.text = "玩家位于此基地范围内"
		inside.add_theme_font_size_override("font_size", 12)
		inside.add_theme_color_override("font_color", Color("8fd0a6"))
		labels.add_child(inside)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	row.add_child(actions)
	if not bool(view.get("active", false)):
		var activate := Button.new()
		activate.name = "HomesteadActivate_%s" % base_id.replace(":", "_")
		activate.text = "设为家园"
		activate.pressed.connect(_set_active.bind(base_id))
		actions.add_child(activate)
	else:
		var teleport := Button.new()
		teleport.name = "HomesteadTeleport_%s" % base_id.replace(":", "_")
		teleport.text = "返回家园"
		teleport.disabled = float(_state.get("teleport_cooldown_remaining", 0.0)) > 0.0 \
				or StringName(_state.get("world_layer", "surface")) == &"dungeon" \
				or bool(view.get("player_inside", false))
		teleport.pressed.connect(_teleport_home)
		actions.add_child(teleport)


func _set_active(base_id: String) -> void:
	_show_result(_stream_manager.set_active_home(base_id) if _stream_manager != null else {})


func _teleport_home() -> void:
	var result := _stream_manager.try_home_teleport() if _stream_manager != null else {}
	_show_result(result)
	if bool(result.get("ok", false)):
		set_homestead_open(false)


func _show_result(result: Dictionary) -> void:
	_status_label.text = String(result.get("message", "家园操作失败"))
	_status_label.add_theme_color_override("font_color", Color("8fd0a6") if bool(result.get("ok", false)) else Color("e58a82"))
