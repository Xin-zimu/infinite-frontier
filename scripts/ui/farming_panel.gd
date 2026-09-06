class_name FarmingPanel
extends Control

signal selection_changed(crop_id: StringName)

var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _crop_list: VBoxContainer
var _status_label: Label
var _count_label: Label
var _selected_crop_id: StringName = &"wheat"
var _latest_state: Dictionary = {}


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.farming_state_changed.connect(_on_farming_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_farming_state_changed(stream_manager.farming_state_snapshot())


func is_farming_open() -> bool:
	return _window != null and _window.visible


func toggle_farming() -> void:
	set_farming_open(not is_farming_open())


func set_farming_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_farming_state_changed(_stream_manager.farming_state_snapshot())
		selection_changed.emit(_selected_crop_id)


func selected_crop_id() -> StringName:
	return _selected_crop_id


func update_target_status(status: Dictionary) -> void:
	if _status_label == null:
		return
	_status_label.text = String(status.get("description", "移动鼠标选择世界格"))
	_status_label.add_theme_color_override("font_color", Color("8fd0a6") if bool(status.get("valid", false)) else Color("e58a82"))


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "FarmingWindow"
	UiLayout.top_right(_window, Vector2(410, 520), Vector2(UiLayout.EDGE_MARGIN, 84))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("071319f2")
	style.border_color = Color("7eaf62")
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
	title.text = "边境农园"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("a9d47f"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [H]"
	close.pressed.connect(func() -> void: set_farming_open(false))
	title_row.add_child(close)
	_count_label = Label.new()
	_count_label.name = "FarmingCountLabel"
	_count_label.text = "耕地 0/0 · 成熟 0"
	_count_label.add_theme_color_override("font_color", Color("a8c0b2"))
	column.add_child(_count_label)
	var scroll := ScrollContainer.new()
	scroll.name = "FarmingCropScroll"
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_crop_list = VBoxContainer.new()
	_crop_list.name = "FarmingCropList"
	_crop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crop_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_crop_list)
	_status_label = Label.new()
	_status_label.name = "FarmingTargetStatus"
	_status_label.text = "左键：开垦/播种/浇水/收获"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 42)
	_status_label.add_theme_color_override("font_color", Color("a9c7b5"))
	column.add_child(_status_label)
	var help := Label.new()
	help.name = "FarmingHelpLabel"
	help.text = "右键使用基础肥料；雨天会自动浇水，雪与沙尘会减慢生长。"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("849a8e"))
	column.add_child(help)
	_window.visible = false


func _on_farming_state_changed(state: Dictionary) -> void:
	_latest_state = state.duplicate(true)
	if _count_label != null:
		_count_label.text = "耕地 %d/%d · 成熟 %d" % [
			int(state.get("plot_count", 0)),
			int(state.get("plot_limit", 0)),
			int(state.get("mature_count", 0)),
		]
	_refresh_crop_list()


func _refresh_crop_list() -> void:
	if _crop_list == null:
		return
	for child in _crop_list.get_children():
		_crop_list.remove_child(child)
		child.queue_free()
	for value in _latest_state.get("crops", []) as Array:
		var view := value as Dictionary
		var crop_id := StringName(view["crop_id"])
		var row := PanelContainer.new()
		row.name = "FarmingCrop_%s" % crop_id
		var style := StyleBoxFlat.new()
		style.bg_color = Color("21372d") if crop_id == _selected_crop_id else Color("12231d")
		style.border_color = Color("91bd70") if crop_id == _selected_crop_id else Color("496556")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		row.add_theme_stylebox_override("panel", style)
		_crop_list.add_child(row)
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
		name_label.text = "%s%s · %d 天" % [view["display_name"], "（果树）" if bool(view["fruit_tree"]) else "", int(view["days_to_mature"])]
		name_label.add_theme_color_override("font_color", Color("dbe9b7"))
		labels.add_child(name_label)
		var seed_label := Label.new()
		seed_label.text = "%s ×%d" % [view["seed_display_name"], int(view["seed_quantity"])]
		seed_label.add_theme_font_size_override("font_size", 12)
		seed_label.add_theme_color_override("font_color", Color("8fd0a6") if int(view["seed_quantity"]) > 0 else Color("d77c74"))
		labels.add_child(seed_label)
		var choose := Button.new()
		choose.text = "已选" if crop_id == _selected_crop_id else "选择"
		choose.disabled = crop_id == _selected_crop_id
		choose.pressed.connect(_select_crop.bind(crop_id))
		content.add_child(choose)


func _select_crop(crop_id: StringName) -> void:
	_selected_crop_id = crop_id
	_refresh_crop_list()
	selection_changed.emit(crop_id)
