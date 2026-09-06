class_name ProcessingPanel
extends Control

var _catalog := ProcessingCatalog.new()
var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _station_tabs: HBoxContainer
var _station_status: Label
var _fuel_row: HBoxContainer
var _recipe_list: VBoxContainer
var _status_label: Label
var _selected_station: StringName = &"cooking_pot"
var _state: Dictionary = {}


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.processing_state_changed.connect(_on_processing_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_processing_state_changed(stream_manager.processing_state_snapshot())


func is_processing_open() -> bool:
	return _window != null and _window.visible


func toggle_processing() -> void:
	set_processing_open(not is_processing_open())


func set_processing_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_processing_state_changed(_stream_manager.processing_state_snapshot())


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "ProcessingWindow"
	UiLayout.centered(_window, Vector2(650, 560))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0a1519f7")
	style.border_color = Color("b9794b")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_window.add_theme_stylebox_override("panel", style)
	_window.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	_window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "烹饪与炼制"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f0bc79"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [T]"
	close.pressed.connect(func() -> void: set_processing_open(false))
	title_row.add_child(close)
	_station_tabs = HBoxContainer.new()
	_station_tabs.name = "ProcessingStationTabs"
	_station_tabs.add_theme_constant_override("separation", 8)
	column.add_child(_station_tabs)
	for station_id in _catalog.station_ids():
		var button := Button.new()
		button.name = "ProcessingStation_%s" % station_id
		button.text = _catalog.station_display_name(station_id)
		button.pressed.connect(_select_station.bind(station_id))
		_station_tabs.add_child(button)
	_station_status = Label.new()
	_station_status.name = "ProcessingStationStatus"
	_station_status.add_theme_color_override("font_color", Color("c5d2ca"))
	column.add_child(_station_status)
	_fuel_row = HBoxContainer.new()
	_fuel_row.name = "ProcessingFuelRow"
	_fuel_row.add_theme_constant_override("separation", 8)
	column.add_child(_fuel_row)
	var fuel_caption := Label.new()
	fuel_caption.text = "投入燃料："
	_fuel_row.add_child(fuel_caption)
	for definition in _catalog.fuels():
		var item_id := StringName(definition["item_id"])
		var button := Button.new()
		button.name = "ProcessingFuel_%s" % item_id
		button.text = "%s +%d" % [definition["display_name"], int(definition["fuel_units"])]
		button.pressed.connect(_request_fuel.bind(item_id))
		_fuel_row.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.name = "ProcessingRecipeScroll"
	scroll.custom_minimum_size = Vector2(0, 365)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_recipe_list = VBoxContainer.new()
	_recipe_list.name = "ProcessingRecipeList"
	_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_recipe_list)
	_status_label = Label.new()
	_status_label.name = "ProcessingStatusLabel"
	_status_label.text = "靠近已放置的加工设备并投入燃料"
	_status_label.add_theme_color_override("font_color", Color("a9c7b5"))
	column.add_child(_status_label)
	_window.visible = false


func _on_processing_state_changed(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_refresh()


func _refresh() -> void:
	if _recipe_list == null:
		return
	var station: Dictionary = {}
	for value in _state.get("stations", []) as Array:
		var view := value as Dictionary
		if StringName(view.get("station_id", "")) == _selected_station:
			station = view
			break
	var available := bool(station.get("available", false))
	_station_status.text = "%s · 燃料 %d/%d · 已加工 %d 次" % [
		"设备就绪" if available else "附近没有%s" % _catalog.station_display_name(_selected_station),
		int(station.get("fuel_units", 0)),
		int(station.get("fuel_capacity", 0)),
		int(station.get("processed_count", 0)),
	]
	var fuel_views := _state.get("fuels", []) as Array
	for button_value in _fuel_row.get_children():
		var button := button_value as Control
		if not button is Button or not String(button.name).begins_with("ProcessingFuel_"):
			continue
		var item_id := StringName(String(button.name).trim_prefix("ProcessingFuel_"))
		var quantity := 0
		var units := _catalog.fuel_units(item_id)
		for fuel_value in fuel_views:
			var fuel := fuel_value as Dictionary
			if StringName(fuel.get("item_id", "")) == item_id:
				quantity = int(fuel.get("quantity", 0))
				break
		(button as Button).disabled = not available or quantity < 1 \
				or int(station.get("fuel_units", 0)) + units > int(station.get("fuel_capacity", 0))
	for child in _recipe_list.get_children():
		_recipe_list.remove_child(child)
		child.queue_free()
	var visible_count := 0
	for value in _state.get("recipes", []) as Array:
		var view := value as Dictionary
		if StringName(view.get("station_id", "")) != _selected_station:
			continue
		visible_count += 1
		var row := PanelContainer.new()
		row.name = "ProcessingRecipe_%s" % view["recipe_id"]
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color("172521")
		row_style.border_color = Color("5f7568")
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(4)
		row_style.content_margin_left = 12
		row_style.content_margin_right = 12
		row_style.content_margin_top = 8
		row_style.content_margin_bottom = 8
		row.add_theme_stylebox_override("panel", row_style)
		_recipe_list.add_child(row)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 12)
		row.add_child(content)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(labels)
		var name_label := Label.new()
		name_label.text = String(view["display_name"])
		name_label.add_theme_color_override("font_color", Color("f1d195"))
		labels.add_child(name_label)
		var materials := Label.new()
		materials.text = "%s · 燃料 %d" % [view["materials"], int(view["fuel_cost"])]
		materials.add_theme_font_size_override("font_size", 12)
		materials.add_theme_color_override("font_color", Color("a8c0b2"))
		labels.add_child(materials)
		var process_button := Button.new()
		process_button.name = "Process_%s" % view["recipe_id"]
		process_button.text = "加工 ×%d" % int(view["output_quantity"])
		process_button.disabled = not bool(view["craftable"])
		process_button.pressed.connect(_request_recipe.bind(StringName(view["recipe_id"])))
		content.add_child(process_button)
	if visible_count == 0:
		var empty := Label.new()
		empty.text = "该设备目前没有加工配方"
		_recipe_list.add_child(empty)


func _select_station(station_id: StringName) -> void:
	_selected_station = station_id
	_refresh()


func _request_fuel(item_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.add_processing_fuel(_selected_station, item_id)
		_status_label.text = String(result.get("message", "燃料操作失败"))


func _request_recipe(recipe_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.process_recipe(recipe_id)
		_status_label.text = String(result.get("message", "加工失败"))
