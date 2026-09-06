class_name HusbandryPanel
extends Control

signal selection_changed(animal_type: StringName)

var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _animal_list: VBoxContainer
var _status_label: Label
var _count_label: Label
var _selected_animal_type: StringName = &"chicken"
var _latest_state: Dictionary = {}


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.husbandry_state_changed.connect(_on_husbandry_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_husbandry_state_changed(stream_manager.husbandry_state_snapshot())


func is_husbandry_open() -> bool:
	return _window != null and _window.visible


func toggle_husbandry() -> void:
	set_husbandry_open(not is_husbandry_open())


func set_husbandry_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_husbandry_state_changed(_stream_manager.husbandry_state_snapshot())
		selection_changed.emit(_selected_animal_type)


func selected_animal_type() -> StringName:
	return _selected_animal_type


func update_target_status(status: Dictionary) -> void:
	if _status_label == null:
		return
	_status_label.text = String(status.get("description", "移动鼠标寻找动物"))
	_status_label.add_theme_color_override("font_color", Color("8fd0a6") if bool(status.get("valid", false)) else Color("e58a82"))


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "HusbandryWindow"
	UiLayout.top_right(_window, Vector2(410, 500), Vector2(UiLayout.EDGE_MARGIN, 84))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10131af2")
	style.border_color = Color("b38b58")
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
	title.text = "边境牧场"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("e1ba7c"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [U]"
	close.pressed.connect(func() -> void: set_husbandry_open(false))
	title_row.add_child(close)
	_count_label = Label.new()
	_count_label.name = "HusbandryCountLabel"
	_count_label.text = "互动 0/0 · 驯服 0 · 待收 0"
	_count_label.add_theme_color_override("font_color", Color("c6b69d"))
	column.add_child(_count_label)
	var scroll := ScrollContainer.new()
	scroll.name = "HusbandryAnimalScroll"
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_animal_list = VBoxContainer.new()
	_animal_list.name = "HusbandryAnimalList"
	_animal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_animal_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_animal_list)
	_status_label = Label.new()
	_status_label.name = "HusbandryTargetStatus"
	_status_label.text = "左键：喂食/驯服/收取"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 42)
	_status_label.add_theme_color_override("font_color", Color("c8b89f"))
	column.add_child(_status_label)
	var help := Label.new()
	help.name = "HusbandryHelpLabel"
	help.text = "右键让同种异性动物在围栏附近繁殖；夜间动物会睡眠，卸载区块仍按游戏日模拟。"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("958b7d"))
	column.add_child(help)
	_window.visible = false


func _on_husbandry_state_changed(state: Dictionary) -> void:
	_latest_state = state.duplicate(true)
	if _count_label != null:
		_count_label.text = "互动 %d/%d · 驯服 %d · 待收 %d" % [
			int(state.get("animal_count", 0)),
			int(state.get("animal_limit", 0)),
			int(state.get("tamed_count", 0)),
			int(state.get("ready_products", 0)),
		]
	_refresh_animal_list()


func _refresh_animal_list() -> void:
	if _animal_list == null:
		return
	for child in _animal_list.get_children():
		_animal_list.remove_child(child)
		child.queue_free()
	for value in _latest_state.get("animals", []) as Array:
		var view := value as Dictionary
		var animal_type := StringName(view["animal_type"])
		var row := PanelContainer.new()
		row.name = "HusbandryAnimal_%s" % animal_type
		var style := StyleBoxFlat.new()
		style.bg_color = Color("3a3025") if animal_type == _selected_animal_type else Color("241e19")
		style.border_color = Color("d0a86d") if animal_type == _selected_animal_type else Color("665544")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		row.add_theme_stylebox_override("panel", style)
		_animal_list.add_child(row)
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
		name_label.text = "%s · 产出%s" % [view["display_name"], view["product_display_name"]]
		labels.add_child(name_label)
		var feed_label := Label.new()
		feed_label.text = "饲料 %s ×%d" % [view["feed_display_name"], int(view["feed_quantity"])]
		feed_label.add_theme_font_size_override("font_size", 12)
		feed_label.add_theme_color_override("font_color", Color("a99d8b"))
		labels.add_child(feed_label)
		var select := Button.new()
		select.text = "已选择" if animal_type == _selected_animal_type else "寻找"
		select.disabled = animal_type == _selected_animal_type
		select.pressed.connect(func() -> void: _select_animal(animal_type))
		content.add_child(select)


func _select_animal(animal_type: StringName) -> void:
	_selected_animal_type = animal_type
	_refresh_animal_list()
	selection_changed.emit(animal_type)
