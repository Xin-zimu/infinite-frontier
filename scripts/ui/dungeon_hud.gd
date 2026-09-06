class_name DungeonHud
extends Control

var _panel: PanelContainer
var _status_label: Label
var _progress_label: Label
var _objective_label: Label


func _ready() -> void:
	name = "DungeonHud"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel()
	EventBus.dungeon_state_changed.connect(update_state)
	update_state({"active": false})


func update_state(snapshot: Dictionary) -> void:
	if _panel == null:
		return
	_panel.visible = bool(snapshot.get("active", false))
	if not _panel.visible:
		return
	_status_label.text = "地牢挑战 · 第 %d 次" % int(snapshot.get("attempt_count", 1))
	_progress_label.text = "钥匙 %d  ·  宝箱 %d  ·  精英 %d" % [
		int(snapshot.get("key_count", 0)),
		int(snapshot.get("opened_chests", 0)),
		int(snapshot.get("defeated_elites", 0)),
	]
	_objective_label.text = "目标：%s" % String(snapshot.get("objective", "击败地牢守卫"))
	_objective_label.add_theme_color_override("font_color", Color("8ee0a4") if bool(snapshot.get("completed", false)) else Color("d8c5e8"))


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DungeonPanel"
	UiLayout.top_left(_panel, Vector2(310, 116), Vector2(UiLayout.EDGE_MARGIN, 298))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17101fe8")
	style.border_color = Color("9a6fb2")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_panel.add_child(column)
	_status_label = Label.new()
	_status_label.name = "DungeonStatusLabel"
	_status_label.add_theme_color_override("font_color", Color("e7c8f5"))
	column.add_child(_status_label)
	_progress_label = Label.new()
	_progress_label.name = "DungeonProgressLabel"
	_progress_label.add_theme_font_size_override("font_size", 13)
	_progress_label.add_theme_color_override("font_color", Color("c1afcc"))
	column.add_child(_progress_label)
	_objective_label = Label.new()
	_objective_label.name = "DungeonObjectiveLabel"
	_objective_label.add_theme_font_size_override("font_size", 12)
	column.add_child(_objective_label)
