class_name QuestJournalPanel
extends Control

var _stream_manager: ChunkStreamManager
var _modal: Control
var _tracker_panel: PanelContainer
var _tracker_label: Label
var _summary_label: Label
var _quest_list: VBoxContainer
var _detail_title: Label
var _detail_status: Label
var _detail_description: Label
var _objective_list: VBoxContainer
var _reward_label: Label
var _primary_button: Button
var _track_button: Button
var _abandon_button: Button
var _choice_panel: PanelContainer
var _choice_title: Label
var _choice_description: Label
var _choice_options: HBoxContainer
var _snapshot: Dictionary = {}
var _selected_id := ""


func _ready() -> void:
	name = "QuestJournalPanel"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_tracker()
	_build_modal()
	EventBus.quest_state_changed.connect(_on_quest_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_quest_state_changed(stream_manager.quest_snapshot())


func is_quest_open() -> bool:
	return _modal.visible


func toggle_quests() -> void:
	set_quest_open(not _modal.visible)


func set_quest_open(open: bool) -> void:
	_modal.visible = open
	if open and _stream_manager != null:
		_on_quest_state_changed(_stream_manager.quest_snapshot())
		EventBus.interaction_feedback.emit("任务日志 · 固定/随机委托与关键选择 · L 关闭", true)


func _build_tracker() -> void:
	_tracker_panel = PanelContainer.new()
	_tracker_panel.name = "QuestTrackerHud"
	UiLayout.top_right(_tracker_panel, Vector2(340, 114), Vector2(24, 176))
	_tracker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102126d9")
	style.border_color = Color("6d9384")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	_tracker_panel.add_theme_stylebox_override("panel", style)
	add_child(_tracker_panel)
	_tracker_label = Label.new()
	_tracker_label.name = "QuestTrackerLabel"
	_tracker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_label.add_theme_color_override("font_color", Color("d9eadf"))
	_tracker_panel.add_child(_tracker_label)


func _build_modal() -> void:
	_modal = Control.new()
	_modal.name = "QuestJournalModal"
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("02070bd9")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(shade)
	var window := PanelContainer.new()
	window.name = "QuestJournalWindow"
	UiLayout.centered(window, Vector2(1040, 660))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d191af8")
	style.border_color = Color("89ae78")
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
	title.text = "任务日志"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f2d589"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_summary_label = Label.new()
	_summary_label.add_theme_color_override("font_color", Color("9fc2cf"))
	title_row.add_child(_summary_label)
	var close := Button.new()
	close.text = "关闭 [L]"
	close.pressed.connect(func() -> void: set_quest_open(false))
	title_row.add_child(close)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(360, 0)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", _inner_style("253d39"))
	body.add_child(list_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(scroll)
	_quest_list = VBoxContainer.new()
	_quest_list.name = "QuestJournalList"
	_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_quest_list)
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _inner_style("4f5431"))
	body.add_child(detail_panel)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	detail_panel.add_child(detail)
	_detail_title = Label.new()
	_detail_title.name = "QuestDetailTitle"
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color("f2d589"))
	detail.add_child(_detail_title)
	_detail_status = Label.new()
	detail.add_child(_detail_status)
	_detail_description = Label.new()
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.custom_minimum_size = Vector2(0, 64)
	detail.add_child(_detail_description)
	var objective_title := Label.new()
	objective_title.text = "目标"
	objective_title.add_theme_color_override("font_color", Color("9fc2cf"))
	detail.add_child(objective_title)
	_objective_list = VBoxContainer.new()
	_objective_list.name = "QuestObjectiveList"
	_objective_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_objective_list)
	_reward_label = Label.new()
	_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_label.add_theme_color_override("font_color", Color("e8c65a"))
	detail.add_child(_reward_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	detail.add_child(actions)
	_primary_button = Button.new()
	_primary_button.name = "QuestPrimaryButton"
	_primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_primary_button.pressed.connect(_on_primary_pressed)
	actions.add_child(_primary_button)
	_track_button = Button.new()
	_track_button.name = "TrackQuestButton"
	_track_button.text = "追踪"
	_track_button.pressed.connect(_on_track_pressed)
	actions.add_child(_track_button)
	_abandon_button = Button.new()
	_abandon_button.name = "AbandonQuestButton"
	_abandon_button.text = "放弃"
	_abandon_button.pressed.connect(_on_abandon_pressed)
	actions.add_child(_abandon_button)
	_choice_panel = PanelContainer.new()
	_choice_panel.name = "WorldChoicePanel"
	_choice_panel.custom_minimum_size = Vector2(0, 116)
	_choice_panel.add_theme_stylebox_override("panel", _inner_style("8a6f45"))
	detail.add_child(_choice_panel)
	var choice_column := VBoxContainer.new()
	choice_column.add_theme_constant_override("separation", 5)
	_choice_panel.add_child(choice_column)
	_choice_title = Label.new()
	_choice_title.name = "WorldChoiceTitle"
	_choice_title.add_theme_color_override("font_color", Color("f2d589"))
	choice_column.add_child(_choice_title)
	_choice_description = Label.new()
	_choice_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_column.add_child(_choice_description)
	_choice_options = HBoxContainer.new()
	_choice_options.name = "WorldChoiceOptionList"
	_choice_options.add_theme_constant_override("separation", 6)
	choice_column.add_child(_choice_options)
	_modal.visible = false


func _inner_style(border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("091416d9")
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_quest_state_changed(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	var choice_snapshot := snapshot.get("world_choices", {}) as Dictionary
	_summary_label.text = "固定 %d · 今日委托 %d · 选择可用 %d" % [
		snapshot.get("fixed_template_count", 0),
		snapshot.get("random_offer_count", 0),
		choice_snapshot.get("available_count", 0),
	]
	_apply_tracker(snapshot.get("tracked", {}) as Dictionary)
	_rebuild_list(snapshot.get("quests", []) as Array)
	_apply_world_choices(choice_snapshot)
	if _selected_id.is_empty() and not (snapshot.get("quests", []) as Array).is_empty():
		_selected_id = String(((snapshot["quests"] as Array)[0] as Dictionary)["quest_id"])
	_apply_detail(_find_view(_selected_id))


func _apply_tracker(view: Dictionary) -> void:
	_tracker_panel.visible = not view.is_empty()
	if view.is_empty():
		_tracker_label.text = ""
		return
	var lines: Array[String] = ["任务 · %s" % String(view["display_name"])]
	for value in view.get("objectives", []) as Array:
		var objective := value as Dictionary
		lines.append("%s %d/%d" % [objective["display_name"], objective["current"], objective["quantity"]])
	_tracker_label.text = "\n".join(lines)


func _rebuild_list(values: Array) -> void:
	for child in _quest_list.get_children():
		child.queue_free()
	for value in values:
		var view := value as Dictionary
		var button := Button.new()
		button.text = "%s  %s %s" % [_status_text(String(view["status"])), _category_text(String(view["category"])), view["display_name"]]
		button.disabled = String(view["status"]) == "locked"
		button.pressed.connect(_select_quest.bind(String(view["quest_id"])))
		_quest_list.add_child(button)


func _select_quest(quest_id: String) -> void:
	_selected_id = quest_id
	_apply_detail(_find_view(quest_id))


func _find_view(quest_id: String) -> Dictionary:
	for value in _snapshot.get("quests", []) as Array:
		if String((value as Dictionary).get("quest_id", "")) == quest_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _apply_detail(view: Dictionary) -> void:
	if view.is_empty():
		_detail_title.text = "选择一个任务"
		_detail_status.text = ""
		_detail_description.text = ""
		_reward_label.text = ""
		return
	var status_value := String(view["status"])
	_detail_title.text = String(view["display_name"])
	_detail_status.text = "%s · %s" % [_status_text(status_value), _category_text(String(view["category"]))]
	_detail_description.text = String(view["description"])
	for child in _objective_list.get_children():
		child.queue_free()
	for value in view.get("objectives", []) as Array:
		var objective := value as Dictionary
		var label := Label.new()
		label.text = "%s %s · %d/%d" % ["✓" if bool(objective["complete"]) else "○", objective["display_name"], objective["current"], objective["quantity"]]
		label.add_theme_color_override("font_color", Color("79b879") if bool(objective["complete"]) else Color("d9e4df"))
		_objective_list.add_child(label)
	var rewards: Array[String] = []
	for value in view.get("rewards", []) as Array:
		var reward := value as Dictionary
		rewards.append("%s ×%d" % [reward["display_name"], reward["quantity"]])
	_reward_label.text = "奖励：" + "、".join(rewards)
	_primary_button.visible = ["available", "completed", "failed"].has(status_value)
	_primary_button.disabled = status_value == "failed" and not bool(view.get("retryable", false))
	_primary_button.text = "领取奖励" if status_value == "completed" else ("重试任务" if status_value == "failed" else "接取任务")
	_track_button.visible = ["active", "completed"].has(status_value)
	_track_button.disabled = bool(view.get("tracked", false))
	_track_button.text = "正在追踪" if bool(view.get("tracked", false)) else "追踪"
	_abandon_button.visible = status_value == "active" and bool(view.get("can_abandon", false))


func _apply_world_choices(snapshot: Dictionary) -> void:
	for child in _choice_options.get_children():
		child.queue_free()
	var choices := snapshot.get("choices", []) as Array
	_choice_panel.visible = not choices.is_empty()
	if choices.is_empty():
		return
	var selected := choices[choices.size() - 1] as Dictionary
	for status_value in ["available", "locked", "resolved"]:
		var found := false
		for value in choices:
			var choice := value as Dictionary
			if String(choice.get("status", "")) == status_value:
				selected = choice
				found = true
				break
		if found:
			break
	var choice_status := String(selected.get("status", "locked"))
	_choice_title.text = "关键世界选择 · %s · %s" % [
		{"available": "可以决定", "locked": "主线未解锁", "resolved": "结果已保存"}.get(choice_status, choice_status),
		selected.get("display_name", ""),
	]
	_choice_description.text = String(selected.get("description", ""))
	if choice_status == "locked":
		_choice_description.text += "（需要完成：%s）" % String(selected.get("prerequisite_display_name", ""))
	for value in selected.get("options", []) as Array:
		var option := value as Dictionary
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s%s" % ["✓ " if bool(option.get("selected", false)) else "", option.get("display_name", "")]
		button.tooltip_text = String(option.get("description", ""))
		button.disabled = choice_status != "available"
		button.pressed.connect(_on_choice_pressed.bind(
			StringName(selected.get("choice_id", "")),
			StringName(option.get("id", ""))
		))
		_choice_options.add_child(button)


func _category_text(category: String) -> String:
	return {"main": "[主线]", "side": "[支线]", "random": "[委托]"}.get(category, "[任务]")


func _status_text(status_value: String) -> String:
	return {"locked": "未解锁", "available": "可接取", "active": "进行中", "completed": "待领取", "claimed": "已完成", "failed": "已失败"}.get(status_value, status_value)


func _on_primary_pressed() -> void:
	if _stream_manager == null or _selected_id.is_empty():
		return
	var view := _find_view(_selected_id)
	if String(view.get("status", "")) == "completed":
		_stream_manager.claim_quest_reward(StringName(_selected_id))
	else:
		_stream_manager.accept_quest(StringName(_selected_id))


func _on_track_pressed() -> void:
	if _stream_manager != null:
		_stream_manager.track_quest(StringName(_selected_id))


func _on_abandon_pressed() -> void:
	if _stream_manager != null:
		_stream_manager.abandon_quest(StringName(_selected_id))


func _on_choice_pressed(choice_id: StringName, option_id: StringName) -> void:
	if _stream_manager != null:
		_stream_manager.resolve_world_choice(choice_id, option_id)
