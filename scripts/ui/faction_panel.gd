class_name FactionPanel
extends Control

var _stream_manager: ChunkStreamManager
var _modal: Control
var _summary_label: Label
var _faction_list: VBoxContainer
var _detail_title: Label
var _standing_label: Label
var _description_label: Label
var _relations_label: Label
var _shop_list: VBoxContainer
var _control_label: Label
var _event_label: Label
var _snapshot: Dictionary = {}
var _selected_id := ""


func _ready() -> void:
	name = "FactionPanel"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_modal()
	EventBus.faction_state_changed.connect(_on_faction_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_faction_state_changed(stream_manager.faction_snapshot())


func is_faction_open() -> bool:
	return _modal.visible


func toggle_factions() -> void:
	set_faction_open(not _modal.visible)


func set_faction_open(open: bool) -> void:
	_modal.visible = open
	if open and _stream_manager != null:
		_on_faction_state_changed(_stream_manager.faction_snapshot())
		EventBus.interaction_feedback.emit("阵营档案 · 声望、关系、商店与控制点 · F 关闭", true)


func _build_modal() -> void:
	_modal = Control.new()
	_modal.name = "FactionModal"
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("02070be6")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(shade)
	var window := PanelContainer.new()
	window.name = "FactionWindow"
	UiLayout.centered(window, Vector2(1040, 640))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101719fa")
	style.border_color = Color("a95b4f")
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
	title.text = "边境阵营档案"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f0c986"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_summary_label = Label.new()
	_summary_label.add_theme_color_override("font_color", Color("9fc2cf"))
	title_row.add_child(_summary_label)
	var close := Button.new()
	close.name = "CloseFactionPanel"
	close.text = "关闭 [F]"
	close.pressed.connect(func() -> void: set_faction_open(false))
	title_row.add_child(close)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(330, 0)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", _inner_style("62463e"))
	body.add_child(list_panel)
	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)
	_faction_list = VBoxContainer.new()
	_faction_list.name = "FactionList"
	_faction_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_faction_list.add_theme_constant_override("separation", 7)
	list_scroll.add_child(_faction_list)
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _inner_style("645c3b"))
	body.add_child(detail_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 9)
	detail_scroll.add_child(detail)
	_detail_title = Label.new()
	_detail_title.name = "FactionDetailTitle"
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color("f0c986"))
	detail.add_child(_detail_title)
	_standing_label = Label.new()
	_standing_label.name = "FactionStandingLabel"
	detail.add_child(_standing_label)
	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.custom_minimum_size = Vector2(0, 48)
	detail.add_child(_description_label)
	var relation_title := Label.new()
	relation_title.text = "阵营关系"
	relation_title.add_theme_color_override("font_color", Color("9fc2cf"))
	detail.add_child(relation_title)
	_relations_label = Label.new()
	_relations_label.name = "FactionRelationsLabel"
	_relations_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_relations_label)
	var shop_title := Label.new()
	shop_title.text = "声望商店"
	shop_title.add_theme_color_override("font_color", Color("9fc2cf"))
	detail.add_child(shop_title)
	_shop_list = VBoxContainer.new()
	_shop_list.name = "FactionShopList"
	_shop_list.add_theme_constant_override("separation", 5)
	detail.add_child(_shop_list)
	var control_title := Label.new()
	control_title.text = "控制点"
	control_title.add_theme_color_override("font_color", Color("9fc2cf"))
	detail.add_child(control_title)
	_control_label = Label.new()
	_control_label.name = "FactionControlLabel"
	_control_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_control_label)
	_event_label = Label.new()
	_event_label.name = "FactionRecentEventLabel"
	_event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_label.add_theme_color_override("font_color", Color("b3c1ba"))
	detail.add_child(_event_label)
	_modal.visible = false


func _inner_style(border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("091315e6")
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_faction_state_changed(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	var factions := snapshot.get("factions", []) as Array
	_summary_label.text = "阵营 %d · 控制点 %d · 发现 %d" % [
		factions.size(),
		(snapshot.get("control_points", []) as Array).size(),
		int(snapshot.get("discovery_count", 0)),
	]
	if _selected_id.is_empty() and not factions.is_empty():
		_selected_id = String((factions[0] as Dictionary).get("faction_id", ""))
	_rebuild_faction_list(factions)
	_apply_detail(_find_faction(_selected_id))


func _rebuild_faction_list(values: Array) -> void:
	for child in _faction_list.get_children():
		child.queue_free()
	for value in values:
		var view := value as Dictionary
		var button := Button.new()
		button.name = "FactionButton_%s" % String(view["faction_id"])
		button.text = "%s  %s  %+d" % [view["display_name"], view["tier_display_name"], int(view["standing"])]
		button.pressed.connect(_select_faction.bind(String(view["faction_id"])))
		_faction_list.add_child(button)


func _select_faction(faction_id: String) -> void:
	_selected_id = faction_id
	_apply_detail(_find_faction(faction_id))


func _find_faction(faction_id: String) -> Dictionary:
	for value in _snapshot.get("factions", []) as Array:
		if String((value as Dictionary).get("faction_id", "")) == faction_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _apply_detail(view: Dictionary) -> void:
	for child in _shop_list.get_children():
		child.queue_free()
	if view.is_empty():
		_detail_title.text = "选择一个阵营"
		_standing_label.text = ""
		_description_label.text = ""
		_relations_label.text = ""
		_control_label.text = ""
		_event_label.text = ""
		return
	_detail_title.text = String(view["display_name"])
	_standing_label.text = "声望 %+d · %s" % [int(view["standing"]), view["tier_display_name"]]
	_standing_label.add_theme_color_override("font_color", Color(String(view.get("tier_color", "9fc2cf"))))
	_description_label.text = String(view["description"])
	var relation_lines: Array[String] = []
	for value in view.get("relations", []) as Array:
		var relation := value as Dictionary
		relation_lines.append("%s  %+d" % [relation["display_name"], int(relation["value"])])
	_relations_label.text = " · ".join(relation_lines)
	for value in view.get("shop", []) as Array:
		var offer := value as Dictionary
		var row := HBoxContainer.new()
		row.name = "FactionShopRow_%s" % String(offer["item_id"])
		var label := Label.new()
		label.text = "%s ×%d · %d 币 · 需%s" % [offer["display_name"], int(offer["quantity"]), int(offer["price"]), offer["required_tier_display_name"]]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var buy := Button.new()
		buy.name = "FactionShopBuy_%s" % String(offer["item_id"])
		buy.text = "购买" if bool(offer["unlocked"]) else "未解锁"
		buy.disabled = not bool(offer["unlocked"])
		buy.pressed.connect(_buy_offer.bind(StringName(view["faction_id"]), StringName(offer["item_id"])))
		row.add_child(buy)
		_shop_list.add_child(row)
	var owned_points: Array[String] = []
	for point_value in _snapshot.get("control_points", []) as Array:
		var point := point_value as Dictionary
		if String(point.get("owner_faction_id", "")) == String(view["faction_id"]):
			owned_points.append("%s（影响力 %d）" % [point["point_id"], int(point["influence"])])
	_control_label.text = "暂无控制点" if owned_points.is_empty() else "\n".join(owned_points)
	var events := _snapshot.get("events", []) as Array
	var recent := {}
	for index in range(events.size() - 1, -1, -1):
		var candidate := events[index] as Dictionary
		if String(candidate.get("faction_id", "")) == String(view["faction_id"]):
			recent = candidate
			break
	_event_label.text = "最近变化：暂无" if recent.is_empty() else "最近变化：%+d · %s" % [int(recent["delta"]), String(recent["source"])]


func _buy_offer(faction_id: StringName, item_id: StringName) -> void:
	if _stream_manager != null:
		_stream_manager.buy_faction_item(faction_id, item_id)
