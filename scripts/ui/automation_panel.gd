class_name AutomationPanel
extends Control

var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _summary_label: Label
var _machine_list: VBoxContainer
var _status_label: Label
var _state: Dictionary = {}


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.automation_state_changed.connect(_on_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_state_changed(stream_manager.automation_state_snapshot())


func is_automation_open() -> bool:
	return _window != null and _window.visible


func toggle_automation() -> void:
	set_automation_open(not is_automation_open())


func set_automation_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_state_changed(_stream_manager.automation_state_snapshot())


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "AutomationWindow"
	UiLayout.centered(_window, Vector2(760, 530))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("09151df7")
	style.border_color = Color("5f9ba8")
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
	column.add_theme_constant_override("separation", 8)
	_window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "基础自动化"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("9ed2dc"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [Y]"
	close.pressed.connect(func() -> void: set_automation_open(false))
	title_row.add_child(close)
	_summary_label = Label.new()
	_summary_label.name = "AutomationSummaryLabel"
	_summary_label.add_theme_color_override("font_color", Color("a8c8ba"))
	column.add_child(_summary_label)
	var scroll := ScrollContainer.new()
	scroll.name = "AutomationMachineScroll"
	scroll.custom_minimum_size = Vector2(0, 370)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_machine_list = VBoxContainer.new()
	_machine_list.name = "AutomationMachineList"
	_machine_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_machine_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_machine_list)
	_status_label = Label.new()
	_status_label.name = "AutomationStatusLabel"
	_status_label.text = "储物箱 → 运输/分拣/熔炉 → 储物箱；R 旋转决定流向"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color("91a9b0"))
	column.add_child(_status_label)
	_window.visible = false


func _on_state_changed(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_refresh()


func _refresh() -> void:
	if _machine_list == null:
		return
	for child in _machine_list.get_children():
		_machine_list.remove_child(child)
		child.queue_free()
	_summary_label.text = "机器 %d/%d · 单次操作上限 %d · 卸载补算上限 %d tick" % [
		int(_state.get("machine_count", 0)), int(_state.get("machine_limit", 0)),
		int(_state.get("operation_limit", 0)), int(_state.get("offline_tick_limit", 0)),
	]
	for value in _state.get("machines", []) as Array:
		var view := value as Dictionary
		var panel := PanelContainer.new()
		panel.name = "AutomationMachine_%s" % String(view["placement_id"]).replace(":", "_")
		var style := StyleBoxFlat.new()
		style.bg_color = Color("14252b")
		style.border_color = Color("4d737b" if bool(view["enabled"]) else "555b61")
		style.set_border_width_all(1)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", style)
		_machine_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel.add_child(row)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(labels)
		var tile := view["world_tile"] as Array
		var name := Label.new()
		name.text = "%s · (%d, %d) · %d° · %s" % [view["display_name"], int(tile[0]), int(tile[1]), int(view["rotation"]), view["status_name"]]
		name.add_theme_color_override("font_color", Color("b8e0e4"))
		labels.add_child(name)
		var detail := Label.new()
		detail.add_theme_font_size_override("font_size", 12)
		detail.add_theme_color_override("font_color", Color("8fa6aa"))
		detail.text = _detail_text(view)
		labels.add_child(detail)
		var toggle := Button.new()
		toggle.name = "AutomationToggle_%s" % String(view["placement_id"]).replace(":", "_")
		toggle.text = "关闭" if bool(view["enabled"]) else "启动"
		toggle.pressed.connect(_toggle_machine.bind(String(view["placement_id"])))
		row.add_child(toggle)
		if StringName(view["kind"]) == &"smelter":
			var recipe := Button.new()
			recipe.name = "AutomationRecipe_%s" % String(view["placement_id"]).replace(":", "_")
			recipe.text = "换配方"
			recipe.pressed.connect(_cycle_recipe.bind(String(view["placement_id"])))
			row.add_child(recipe)
		elif StringName(view["kind"]) == &"sorter":
			var filter := Button.new()
			filter.name = "AutomationFilter_%s" % String(view["placement_id"]).replace(":", "_")
			filter.text = "换筛选"
			filter.pressed.connect(_cycle_filter.bind(String(view["placement_id"])))
			row.add_child(filter)
	if _machine_list.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "尚未放置自动化机器；先在 [K] 建造界面制作一条储物物流线。"
		empty.add_theme_color_override("font_color", Color("91a9b0"))
		_machine_list.add_child(empty)


func _detail_text(view: Dictionary) -> String:
	var parts: Array[String] = ["累计 %d 次" % int(view.get("cycles", 0))]
	if not String(view.get("recipe_name", "")).is_empty():
		parts.append("配方 %s" % view["recipe_name"])
		parts.append("燃料 %d/%d" % [int(view["fuel_units"]), int(view["fuel_capacity"])])
	if not String(view.get("filter_name", "")).is_empty():
		parts.append("仅通过 %s" % view["filter_name"])
	return " · ".join(parts)


func _toggle_machine(placement_id: String) -> void:
	_show_result(_stream_manager.toggle_automation_machine(placement_id) if _stream_manager != null else {})


func _cycle_recipe(placement_id: String) -> void:
	_show_result(_stream_manager.cycle_automation_recipe(placement_id) if _stream_manager != null else {})


func _cycle_filter(placement_id: String) -> void:
	_show_result(_stream_manager.cycle_automation_filter(placement_id) if _stream_manager != null else {})


func _show_result(result: Dictionary) -> void:
	_status_label.text = String(result.get("message", "自动化操作失败"))
	_status_label.add_theme_color_override("font_color", Color("8fd0a6") if bool(result.get("ok", false)) else Color("e58a82"))
