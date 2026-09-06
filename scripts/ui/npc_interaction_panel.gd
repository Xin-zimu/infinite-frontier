class_name NpcInteractionPanel
extends Control

var _stream_manager: ChunkStreamManager
var _name_label: Label
var _activity_label: Label
var _relationship_label: Label
var _dialogue_label: Label
var _coin_label: Label
var _offers: VBoxContainer
var _buys: VBoxContainer
var _gifts: VBoxContainer
var _sleep_button: Button
var _current_npc_id := ""


func _ready() -> void:
	name = "NpcInteractionPanel"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	visible = false
	EventBus.npc_interaction_requested.connect(_on_interaction_requested)
	EventBus.npc_state_changed.connect(_on_npc_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager


func is_npc_open() -> bool:
	return visible


func set_npc_open(open: bool) -> void:
	visible = open
	if not open:
		_current_npc_id = ""
		if _stream_manager != null:
			_stream_manager.close_npc_interaction()


func continue_dialogue() -> void:
	if _stream_manager != null and visible:
		var snapshot := _stream_manager.continue_npc_dialogue()
		if not snapshot.is_empty():
			_apply_snapshot(snapshot)


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.name = "NpcBackdrop"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("02070bc7")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var window := PanelContainer.new()
	window.name = "NpcWindow"
	UiLayout.centered(window, Vector2(1040, 590))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("11191cf8")
	style.border_color = Color("c89b5e")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	window.add_theme_stylebox_override("panel", style)
	add_child(window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	window.add_child(column)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	column.add_child(title_row)
	_name_label = Label.new()
	_name_label.name = "NpcNameLabel"
	_name_label.add_theme_font_size_override("font_size", 25)
	_name_label.add_theme_color_override("font_color", Color("f1cf86"))
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_name_label)
	_activity_label = Label.new()
	_activity_label.name = "NpcActivityLabel"
	_activity_label.add_theme_color_override("font_color", Color("9fc2cf"))
	title_row.add_child(_activity_label)
	_relationship_label = Label.new()
	_relationship_label.name = "NpcRelationshipLabel"
	title_row.add_child(_relationship_label)
	var close := Button.new()
	close.text = "关闭 [Esc]"
	close.pressed.connect(func() -> void: set_npc_open(false))
	title_row.add_child(close)
	_dialogue_label = Label.new()
	_dialogue_label.name = "NpcDialogueLabel"
	_dialogue_label.custom_minimum_size = Vector2(0, 72)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 18)
	_dialogue_label.add_theme_color_override("font_color", Color("e5ece7"))
	column.add_child(_dialogue_label)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	body.add_child(_make_trade_column("商店出售", "OfferList", true))
	body.add_child(_make_trade_column("收购材料", "BuyList", false))
	body.add_child(_make_gift_column())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	column.add_child(footer)
	_coin_label = Label.new()
	_coin_label.name = "NpcCoinLabel"
	_coin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coin_label.add_theme_color_override("font_color", Color("e8c65a"))
	footer.add_child(_coin_label)
	var talk_button := Button.new()
	talk_button.name = "ContinueDialogueButton"
	talk_button.text = "继续交谈 [E]"
	talk_button.pressed.connect(continue_dialogue)
	footer.add_child(talk_button)
	_sleep_button = Button.new()
	_sleep_button.name = "SleepUntilDawnButton"
	_sleep_button.text = "休息到次日清晨"
	_sleep_button.pressed.connect(_on_sleep_pressed)
	footer.add_child(_sleep_button)


func _make_trade_column(title_text: String, list_name: String, offers_side: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0a2527c0")
	style.border_color = Color("426b68")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("f1cf86"))
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = list_name
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	if offers_side:
		_offers = list
	else:
		_buys = list
	return panel


func _make_gift_column() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1e1625c0")
	style.border_color = Color("735c80")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "赠送礼物（每日一次）"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("dfb5e8"))
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_gifts = VBoxContainer.new()
	_gifts.name = "GiftList"
	_gifts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gifts.add_theme_constant_override("separation", 6)
	scroll.add_child(_gifts)
	return panel


func _on_interaction_requested(snapshot: Dictionary) -> void:
	_apply_snapshot(snapshot)
	visible = true
	EventBus.interaction_feedback.emit("NPC 对话 · E 继续 · Esc 关闭", true)


func _on_npc_state_changed(snapshot: Dictionary) -> void:
	if not visible or not snapshot.has("npc_id") or String(snapshot.get("npc_id", "")) != _current_npc_id:
		return
	_apply_snapshot(snapshot)


func _apply_snapshot(snapshot: Dictionary) -> void:
	_current_npc_id = String(snapshot.get("npc_id", ""))
	_name_label.text = "%s · %s" % [snapshot.get("display_name", "村民"), snapshot.get("role_display_name", "村民")]
	_activity_label.text = "日程：%s" % String(snapshot.get("activity_display", "等待"))
	var relationship := snapshot.get("relationship", {}) as Dictionary
	_relationship_label.text = "%s · 好感 %+d · 声望 %+d" % [
		relationship.get("tier_display_name", "中立"),
		int(relationship.get("affection", 0)),
		int(relationship.get("village_reputation", 0)),
	]
	_relationship_label.add_theme_color_override("font_color", Color(String(relationship.get("tier_color", "9fc2cf"))))
	_dialogue_label.text = "“%s”" % String(snapshot.get("dialogue", "……"))
	_coin_label.text = "边境币：%d" % int(snapshot.get("coin_count", 0))
	_sleep_button.visible = (snapshot.get("services", []) as Array).has("sleep")
	_rebuild_offers(snapshot.get("offers", []) as Array)
	_rebuild_buys(snapshot.get("buys", []) as Array)
	_rebuild_gifts(snapshot.get("gifts", []) as Array)


func _rebuild_offers(values: Array) -> void:
	_clear_list(_offers)
	if values.is_empty():
		_add_empty(_offers, "此人不经营商店")
		return
	for value in values:
		var offer := value as Dictionary
		var button := Button.new()
		button.text = "%s ×%d · %d 币" % [offer["display_name"], offer["quantity"], offer["price"]]
		button.disabled = not bool(offer.get("can_trade", false))
		button.pressed.connect(_on_buy_pressed.bind(StringName(offer["item_id"])))
		_offers.add_child(button)


func _rebuild_buys(values: Array) -> void:
	_clear_list(_buys)
	if values.is_empty():
		_add_empty(_buys, "此人不收购材料")
		return
	for value in values:
		var buy := value as Dictionary
		var button := Button.new()
		button.text = "%s ×%d · 得 %d 币（有 %d）" % [buy["display_name"], buy["quantity"], buy["price"], buy["owned"]]
		button.disabled = not bool(buy.get("can_trade", false))
		button.pressed.connect(_on_sell_pressed.bind(StringName(buy["item_id"])))
		_buys.add_child(button)


func _rebuild_gifts(values: Array) -> void:
	_clear_list(_gifts)
	if values.is_empty():
		_add_empty(_gifts, "背包中没有可赠物品")
		return
	for value in values:
		var gift := value as Dictionary
		var button := Button.new()
		button.text = "%s（有 %d）· 好感 %+d" % [gift["display_name"], gift["owned"], gift["affection_delta"]]
		button.disabled = not bool(gift.get("can_gift", false))
		button.pressed.connect(_on_gift_pressed.bind(StringName(gift["item_id"])))
		_gifts.add_child(button)


func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()


func _add_empty(list: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("71898c"))
	list.add_child(label)


func _on_buy_pressed(item_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.buy_from_current_npc(item_id)
		if bool(result.get("ok", false)):
			_apply_snapshot(result.get("state", {}) as Dictionary)


func _on_sell_pressed(item_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.sell_to_current_npc(item_id)
		if bool(result.get("ok", false)):
			_apply_snapshot(result.get("state", {}) as Dictionary)


func _on_gift_pressed(item_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.gift_to_current_npc(item_id)
		if bool(result.get("ok", false)):
			_apply_snapshot(result.get("state", {}) as Dictionary)


func _on_sleep_pressed() -> void:
	if _stream_manager != null and _stream_manager.request_sleep_at_current_npc():
		visible = false
		_current_npc_id = ""
