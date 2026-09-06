class_name RegionProgressionPanel
extends Control

var _stream_manager: ChunkStreamManager
var _modal: Control
var _tracker_label: Label
var _world_label: Label
var _region_label: Label
var _gear_label: Label
var _enemy_label: Label
var _reward_label: Label
var _reward_button: Button
var _boss_label: Label


func _ready() -> void:
	name = "RegionProgressionPanel"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_tracker()
	_build_modal()
	EventBus.region_progression_state_changed.connect(_on_region_progression_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_region_progression_state_changed(stream_manager.region_progression_snapshot())


func is_progression_open() -> bool:
	return _modal.visible


func toggle_progression() -> void:
	set_progression_open(not _modal.visible)


func set_progression_open(open: bool) -> void:
	_modal.visible = open
	if open and _stream_manager != null:
		_on_region_progression_state_changed(_stream_manager.region_progression_snapshot())
		EventBus.interaction_feedback.emit("区域进度 · 危险、装备、奖励与 Boss 解锁 · P 关闭", true)


func _build_tracker() -> void:
	var panel := PanelContainer.new()
	panel.name = "RegionProgressionTracker"
	panel.z_index = -1
	UiLayout.top_right(panel, Vector2(298, 98), Vector2(UiLayout.EDGE_MARGIN, 588))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141b16e8")
	style.border_color = Color("d0a95d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_tracker_label = Label.new()
	_tracker_label.name = "RegionProgressionTrackerLabel"
	_tracker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_label.add_theme_color_override("font_color", Color("f0ddb0"))
	panel.add_child(_tracker_label)


func _build_modal() -> void:
	_modal = Control.new()
	_modal.name = "RegionProgressionModal"
	_modal.z_index = 100
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("02070be6")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(shade)
	var window := PanelContainer.new()
	window.name = "RegionProgressionWindow"
	UiLayout.centered(window, Vector2(920, 600))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111813fa")
	style.border_color = Color("d0a95d")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 17
	style.content_margin_bottom = 19
	window.add_theme_stylebox_override("panel", style)
	_modal.add_child(window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "区域等级与世界进度"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f0d18a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_world_label = Label.new()
	_world_label.name = "WorldProgressSummaryLabel"
	_world_label.add_theme_color_override("font_color", Color("9fc2cf"))
	title_row.add_child(_world_label)
	var close := Button.new()
	close.name = "CloseRegionProgressionPanel"
	close.text = "关闭 [P]"
	close.pressed.connect(func() -> void: set_progression_open(false))
	title_row.add_child(close)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var region_panel := PanelContainer.new()
	region_panel.custom_minimum_size = Vector2(430, 0)
	region_panel.add_theme_stylebox_override("panel", _inner_style("657347"))
	body.add_child(region_panel)
	var region_column := VBoxContainer.new()
	region_column.add_theme_constant_override("separation", 13)
	region_panel.add_child(region_column)
	_region_label = _section_label("CurrentRegionLabel", 22, "f0d18a")
	region_column.add_child(_region_label)
	_gear_label = _section_label("GearScoreLabel", 18, "d9e5d0")
	region_column.add_child(_gear_label)
	_enemy_label = _section_label("EnemyLevelRangeLabel", 17, "b7d5df")
	_enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	region_column.add_child(_enemy_label)
	var divider := HSeparator.new()
	region_column.add_child(divider)
	_reward_label = _section_label("RegionRewardLabel", 17, "d9c58f")
	_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	region_column.add_child(_reward_label)
	_reward_button = Button.new()
	_reward_button.name = "ClaimRegionRewardButton"
	_reward_button.text = "领取当前区域奖励"
	_reward_button.pressed.connect(_claim_reward)
	region_column.add_child(_reward_button)
	var boss_panel := PanelContainer.new()
	boss_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_panel.add_theme_stylebox_override("panel", _inner_style("775b3c"))
	body.add_child(boss_panel)
	var boss_column := VBoxContainer.new()
	boss_column.add_theme_constant_override("separation", 12)
	boss_panel.add_child(boss_column)
	var boss_title := Label.new()
	boss_title.text = "区域 Boss 解锁"
	boss_title.add_theme_font_size_override("font_size", 22)
	boss_title.add_theme_color_override("font_color", Color("e8c16d"))
	boss_column.add_child(boss_title)
	_boss_label = Label.new()
	_boss_label.name = "BossUnlockListLabel"
	_boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boss_column.add_child(_boss_label)
	var explanation := Label.new()
	explanation.text = "世界进度来自首次发现区域、击败精英、完成任务/事件/地牢及区域 Boss。每个来源只记一次。"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_color_override("font_color", Color("9caea2"))
	boss_column.add_child(explanation)
	_modal.visible = false


func _section_label(node_name: String, font_size: int, color: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(color))
	return label


func _inner_style(border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("09120de8")
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style


func _on_region_progression_state_changed(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var region := snapshot.get("current_region", {}) as Dictionary
	var danger := int(region.get("danger_level", 1))
	var gear := int(snapshot.get("gear_score", 0))
	var recommended := int(region.get("recommended_gear_score", 0))
	_world_label.text = "世界 Lv.%d · %d 点" % [int(snapshot.get("world_level", 1)), int(snapshot.get("world_progress_points", 0))]
	_region_label.text = "%s\n危险 %d/5 · %s" % [region.get("display_name", "未知区域"), danger, region.get("danger_display_name", "")]
	_gear_label.text = "装备评分 %d / 建议 %d · %s" % [gear, recommended, "达标" if bool(snapshot.get("gear_ready", false)) else "风险偏高"]
	_enemy_label.text = "敌人等级 Lv.%d–%d\n精英出现率 %d%% · 精英属性与掉落提升" % [
		int(region.get("enemy_level_min", 1)),
		int(region.get("enemy_level_max", 1)),
		roundi(float(region.get("elite_chance", 0.0)) * 100.0),
	]
	var elites := int(snapshot.get("region_elite_defeats", 0))
	var required_elites := int(snapshot.get("reward_required_elites", 0))
	var points := int(snapshot.get("world_progress_points", 0))
	var required_points := int(snapshot.get("reward_required_points", 0))
	if bool(snapshot.get("reward_claimed", false)):
		_reward_label.text = "区域奖励：已领取\n条件进度：精英 %d/%d · 世界 %d/%d" % [elites, required_elites, points, required_points]
		_reward_button.text = "奖励已领取"
		_reward_button.disabled = true
	else:
		_reward_label.text = "区域奖励条件\n精英 %d/%d · 世界进度 %d/%d" % [elites, required_elites, points, required_points]
		_reward_button.text = "领取当前区域奖励" if bool(snapshot.get("reward_available", false)) else "奖励条件未完成"
		_reward_button.disabled = not bool(snapshot.get("reward_available", false))
	var boss_lines: Array[String] = []
	for value in snapshot.get("boss_unlocks", []) as Array:
		var boss := value as Dictionary
		boss_lines.append("%s  %s\n  需要 %d 世界进度" % ["◆" if bool(boss["unlocked"]) else "◇", boss["display_name"], int(boss["required_points"])])
	_boss_label.text = "\n\n".join(boss_lines)
	_tracker_label.text = "区域进度 [P]\n危险 %d · 敌人 Lv.%d–%d\n装备 %d/%d · 世界 %d" % [
		danger,
		int(region.get("enemy_level_min", 1)),
		int(region.get("enemy_level_max", 1)),
		gear,
		recommended,
		points,
	]


func _claim_reward() -> void:
	if _stream_manager != null:
		_stream_manager.claim_current_region_reward()
