class_name BuildingPanel
extends Control

signal selection_changed(piece_id: StringName)

var _stream_manager: ChunkStreamManager
var _catalog := BuildingCatalog.new()
var _window: PanelContainer
var _piece_list: VBoxContainer
var _status_label: Label
var _count_label: Label
var _selected_piece_id: StringName = &"wood_floor"
var _piece_buttons: Dictionary = {}
var _latest_state: Dictionary = {}


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.building_state_changed.connect(_on_building_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_building_state_changed(stream_manager.building_state_snapshot())


func is_building_open() -> bool:
	return _window != null and _window.visible


func toggle_building() -> void:
	set_building_open(not is_building_open())


func set_building_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_building_state_changed(_stream_manager.building_state_snapshot())
		selection_changed.emit(_selected_piece_id)


func selected_piece_id() -> StringName:
	return _selected_piece_id


func update_preview_status(preview: Dictionary, rotation: int) -> void:
	if _status_label == null:
		return
	_status_label.text = "%s · %d° · %s" % [
		_catalog.display_name(_selected_piece_id),
		rotation,
		String(preview.get("reason", "移动鼠标选择世界格")),
	]
	_status_label.add_theme_color_override("font_color", Color("8fd0a6") if bool(preview.get("valid", false)) else Color("e58a82"))


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "BuildingWindow"
	UiLayout.top_right(_window, Vector2(420, 610), Vector2(UiLayout.EDGE_MARGIN, 70))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("071319f2")
	style.border_color = Color("d49a55")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.content_margin_left = 18
	style.content_margin_right = 18
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
	title.text = "玩家建造"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f0bd75"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [K]"
	close.pressed.connect(func() -> void: set_building_open(false))
	title_row.add_child(close)
	_count_label = Label.new()
	_count_label.name = "BuildingCountLabel"
	_count_label.text = "玩家建筑 0/0"
	_count_label.add_theme_color_override("font_color", Color("a8c0b2"))
	column.add_child(_count_label)
	var scroll := ScrollContainer.new()
	scroll.name = "BuildingPieceScroll"
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_piece_list = VBoxContainer.new()
	_piece_list.name = "BuildingPieceList"
	_piece_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_piece_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_piece_list)
	_status_label = Label.new()
	_status_label.name = "BuildingPreviewStatus"
	_status_label.text = "左键放置 · 右键拆除 · R 旋转"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 40)
	_status_label.add_theme_color_override("font_color", Color("a9c7b5"))
	column.add_child(_status_label)
	var help := Label.new()
	help.name = "BuildingHelpLabel"
	help.text = "空手对储物箱交互取回；选中快捷栏物品交互存入。"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("849a8e"))
	column.add_child(help)
	_window.visible = false


func _on_building_state_changed(state: Dictionary) -> void:
	_latest_state = state.duplicate(true)
	if _count_label != null:
		_count_label.text = "玩家建筑 %d/%d" % [int(state.get("placement_count", 0)), int(state.get("placement_limit", 0))]
	_refresh_piece_list()


func _refresh_piece_list() -> void:
	if _piece_list == null:
		return
	for child in _piece_list.get_children():
		_piece_list.remove_child(child)
		child.queue_free()
	_piece_buttons.clear()
	for value in _latest_state.get("pieces", []) as Array:
		var view := value as Dictionary
		var row := PanelContainer.new()
		row.name = "BuildingPiece_%s" % view["piece_id"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color("21372d") if StringName(view["piece_id"]) == _selected_piece_id else Color("12231d")
		style.border_color = Color("d49a55") if StringName(view["piece_id"]) == _selected_piece_id else Color("496556")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		row.add_theme_stylebox_override("panel", style)
		_piece_list.add_child(row)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		row.add_child(content)
		var swatch := ColorRect.new()
		swatch.color = Color(String(view["color"]))
		swatch.custom_minimum_size = Vector2(18, 38)
		content.add_child(swatch)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(labels)
		var name_label := Label.new()
		name_label.text = "%s · %s" % [view["display_name"], _category_name(StringName(view["category"]))]
		name_label.add_theme_color_override("font_color", Color("f1d195"))
		labels.add_child(name_label)
		var cost := Label.new()
		cost.text = String(view["cost_text"])
		cost.add_theme_font_size_override("font_size", 12)
		cost.add_theme_color_override("font_color", Color("8fd0a6") if bool(view["affordable"]) else Color("d77c74"))
		labels.add_child(cost)
		var choose := Button.new()
		choose.text = "已选" if StringName(view["piece_id"]) == _selected_piece_id else "选择"
		choose.disabled = StringName(view["piece_id"]) == _selected_piece_id
		var piece_id := StringName(view["piece_id"])
		choose.pressed.connect(_select_piece.bind(piece_id))
		content.add_child(choose)
		_piece_buttons[String(piece_id)] = choose


func _select_piece(piece_id: StringName) -> void:
	_selected_piece_id = piece_id
	_refresh_piece_list()
	selection_changed.emit(piece_id)


func _category_name(category: StringName) -> String:
	match category:
		&"floor": return "地面"
		&"wall": return "墙体"
		&"door": return "门"
		&"roof": return "屋顶"
		&"furniture": return "家具"
		&"chest": return "储物"
		&"light": return "照明"
		&"station": return "工作站"
		&"automation": return "自动化"
		&"homestead": return "家园"
		_: return String(category)
