class_name EquipmentPanel
extends Control

var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _slot_list: VBoxContainer
var _owned_list: VBoxContainer
var _import_list: VBoxContainer
var _stats_label: Label
var _compare_label: Label
var _material_label: Label
var _status_label: Label
var _selected_instance_id := 0
var _state: Dictionary = {}


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.equipment_state_changed.connect(_on_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_state_changed(stream_manager.equipment_state_snapshot())


func is_equipment_open() -> bool:
	return _window != null and _window.visible


func toggle_equipment() -> void:
	set_equipment_open(not is_equipment_open())


func set_equipment_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_state_changed(_stream_manager.equipment_state_snapshot())


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "EquipmentWindow"
	UiLayout.centered(_window, Vector2(740, 520))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b121cf7")
	style.border_color = Color("8f75bd")
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
	title.text = "装备与强化"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("d6b4f0"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [O]"
	close.pressed.connect(func() -> void: set_equipment_open(false))
	title_row.add_child(close)
	_stats_label = Label.new()
	_stats_label.name = "EquipmentStatsLabel"
	_stats_label.add_theme_color_override("font_color", Color("9fd7c1"))
	column.add_child(_stats_label)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(225, 0)
	body.add_child(left)
	var slot_title := Label.new()
	slot_title.text = "已装备槽位"
	slot_title.add_theme_color_override("font_color", Color("f0d58d"))
	left.add_child(slot_title)
	_slot_list = VBoxContainer.new()
	_slot_list.name = "EquipmentSlotList"
	left.add_child(_slot_list)
	var import_title := Label.new()
	import_title.text = "背包可登记装备"
	import_title.add_theme_color_override("font_color", Color("f0d58d"))
	left.add_child(import_title)
	var import_scroll := ScrollContainer.new()
	import_scroll.custom_minimum_size = Vector2(0, 92)
	import_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(import_scroll)
	_import_list = VBoxContainer.new()
	_import_list.name = "EquipmentImportList"
	_import_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_scroll.add_child(_import_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var owned_title := Label.new()
	owned_title.text = "装备库 · 品质 / 稀有度 / 随机词条"
	owned_title.add_theme_color_override("font_color", Color("f0d58d"))
	right.add_child(owned_title)
	var owned_scroll := ScrollContainer.new()
	owned_scroll.custom_minimum_size = Vector2(0, 230)
	owned_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(owned_scroll)
	_owned_list = VBoxContainer.new()
	_owned_list.name = "EquipmentOwnedList"
	_owned_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_owned_list.add_theme_constant_override("separation", 6)
	owned_scroll.add_child(_owned_list)
	_compare_label = Label.new()
	_compare_label.name = "EquipmentCompareLabel"
	_compare_label.text = "选择装备后显示与当前槽位的属性对比"
	_compare_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compare_label.add_theme_color_override("font_color", Color("b7c3d6"))
	right.add_child(_compare_label)
	_material_label = Label.new()
	_material_label.name = "EquipmentMaterialLabel"
	_material_label.add_theme_color_override("font_color", Color("a9c7b5"))
	column.add_child(_material_label)
	_status_label = Label.new()
	_status_label.name = "EquipmentStatusLabel"
	_status_label.text = "先从背包登记装备，再选择装备、强化或修理"
	_status_label.add_theme_color_override("font_color", Color("c5b3da"))
	column.add_child(_status_label)
	_window.visible = false


func _on_state_changed(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_refresh()


func _refresh() -> void:
	if _slot_list == null:
		return
	_clear(_slot_list)
	_clear(_owned_list)
	_clear(_import_list)
	var stats := _state.get("stats", {}) as Dictionary
	_stats_label.text = "总加成  攻击 +%.1f · 防御 +%.1f · 生命 +%.1f · 体力 +%.1f" % [
		float(stats.get("attack", 0.0)), float(stats.get("defense", 0.0)),
		float(stats.get("health", 0.0)), float(stats.get("stamina", 0.0)),
	]
	for slot_value in _state.get("slots", []) as Array:
		var slot := slot_value as Dictionary
		var equipment := slot.get("record", {}) as Dictionary
		var row := HBoxContainer.new()
		row.name = "EquipmentSlot_%s" % slot["slot_id"]
		_slot_list.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s：%s" % [slot["display_name"], _short_record(equipment) if not equipment.is_empty() else "空"]
		row.add_child(label)
		var unequip := Button.new()
		unequip.text = "卸下"
		unequip.disabled = equipment.is_empty()
		unequip.pressed.connect(_request_unequip.bind(StringName(slot["slot_id"])))
		row.add_child(unequip)
	for import_value in _state.get("importable", []) as Array:
		var importable := import_value as Dictionary
		var button := Button.new()
		button.name = "EquipmentImport_%d" % int(importable["slot_index"])
		button.text = "登记 %s · 耐久 %d" % [importable["display_name"], int(importable["durability"])]
		button.pressed.connect(_request_import.bind(int(importable["slot_index"])))
		_import_list.add_child(button)
	if _import_list.get_child_count() == 0:
		var empty_import := Label.new()
		empty_import.text = "背包内暂无可登记装备"
		_import_list.add_child(empty_import)
	var selected_exists := false
	for record_value in _state.get("owned", []) as Array:
		var equipment := record_value as Dictionary
		var instance_id := int(equipment["instance_id"])
		selected_exists = selected_exists or instance_id == _selected_instance_id
		var row := PanelContainer.new()
		row.name = "EquipmentOwned_%d" % instance_id
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color("251d31" if instance_id == _selected_instance_id else "171c29")
		row_style.border_color = Color(String(equipment.get("rarity_color", "6a7182")))
		row_style.set_border_width_all(1)
		row_style.content_margin_left = 8
		row_style.content_margin_right = 8
		row_style.content_margin_top = 5
		row_style.content_margin_bottom = 5
		row.add_theme_stylebox_override("panel", row_style)
		_owned_list.add_child(row)
		var content := HBoxContainer.new()
		row.add_child(content)
		var select := Button.new()
		select.text = _short_record(equipment)
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.pressed.connect(_select_instance.bind(instance_id))
		content.add_child(select)
		var equip_button := Button.new()
		equip_button.text = "装备"
		equip_button.pressed.connect(_request_equip.bind(instance_id))
		content.add_child(equip_button)
		var enhance_button := Button.new()
		enhance_button.text = "强化"
		enhance_button.pressed.connect(_request_enhance.bind(instance_id))
		content.add_child(enhance_button)
		var repair_button := Button.new()
		repair_button.text = "修理"
		repair_button.pressed.connect(_request_repair.bind(instance_id))
		content.add_child(repair_button)
	if not selected_exists:
		_selected_instance_id = 0
	if _owned_list.get_child_count() == 0:
		var empty_owned := Label.new()
		empty_owned.text = "装备库为空"
		_owned_list.add_child(empty_owned)
	_material_label.text = "强化材料 %s ×%d · 修理材料 %s ×%d" % [
		_state.get("enhancement_material", "tempered_plate"), int(_state.get("enhancement_material_quantity", 0)),
		_state.get("repair_material", "iron_ingot"), int(_state.get("repair_material_quantity", 0)),
	]
	_refresh_comparison()


func _refresh_comparison() -> void:
	if _selected_instance_id <= 0 or _stream_manager == null:
		_compare_label.text = "选择装备后显示与当前槽位的属性对比"
		return
	var comparison := _stream_manager.equipment_comparison(_selected_instance_id)
	if comparison.is_empty():
		_compare_label.text = "无法读取装备对比"
		return
	_compare_label.text = "对比当前槽位  攻击 %+0.1f · 防御 %+0.1f · 生命 %+0.1f · 体力 %+0.1f" % [
		float(comparison.get("attack_delta", 0.0)), float(comparison.get("defense_delta", 0.0)),
		float(comparison.get("health_delta", 0.0)), float(comparison.get("stamina_delta", 0.0)),
	]


func _short_record(equipment: Dictionary) -> String:
	if equipment.is_empty():
		return "空"
	var affixes := equipment.get("affix_names", []) as Array
	return "%s · %s%s +%d · 耐久 %d/%d%s" % [
		equipment.get("rarity_name", "普通"), equipment.get("quality_name", "标准"), equipment.get("display_name", "装备"),
		int(equipment.get("enhance_level", 0)), int(equipment.get("durability", 0)), int(equipment.get("maximum_durability", 0)),
		" · " + "/".join(affixes) if not affixes.is_empty() else "",
	]


func _select_instance(instance_id: int) -> void:
	_selected_instance_id = instance_id
	_refresh()


func _request_import(slot_index: int) -> void:
	if _stream_manager != null:
		var result := _stream_manager.import_equipment_slot(slot_index)
		_status_label.text = String(result.get("message", "登记失败"))


func _request_equip(instance_id: int) -> void:
	if _stream_manager != null:
		var result := _stream_manager.equip_equipment_instance(instance_id)
		_status_label.text = String(result.get("message", "装备失败"))


func _request_unequip(slot_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.unequip_equipment_slot(slot_id)
		_status_label.text = String(result.get("message", "卸下失败"))


func _request_enhance(instance_id: int) -> void:
	if _stream_manager != null:
		var result := _stream_manager.enhance_equipment(instance_id)
		_status_label.text = String(result.get("message", "强化失败"))


func _request_repair(instance_id: int) -> void:
	if _stream_manager != null:
		var result := _stream_manager.repair_equipment(instance_id)
		_status_label.text = String(result.get("message", "修理失败"))


func _clear(container: Control) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
