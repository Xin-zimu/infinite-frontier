class_name SurvivalHud
extends Control

var _panel: PanelContainer
var _hunger_fill: ColorRect
var _wetness_fill: ColorRect
var _temperature_label: Label
var _effects_label: Label
var _mode_label: Label


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	EventBus.survival_state_changed.connect(update_survival)


func update_survival(snapshot: Dictionary) -> void:
	if _panel == null:
		return
	var enabled := bool(snapshot.get("enabled", true))
	var hunger_maximum := maxf(1.0, float(snapshot.get("hunger_maximum", 100.0)))
	var wetness_maximum := maxf(1.0, float(snapshot.get("wetness_maximum", 100.0)))
	_hunger_fill.scale.x = clampf(float(snapshot.get("hunger", hunger_maximum)) / hunger_maximum, 0.0, 1.0)
	_wetness_fill.scale.x = clampf(float(snapshot.get("wetness", 0.0)) / wetness_maximum, 0.0, 1.0)
	_temperature_label.text = "体温  %.1f°C · %s" % [
		float(snapshot.get("body_temperature", 37.0)),
		String(snapshot.get("temperature_state", "舒适")),
	]
	var effect_names: Array[String] = []
	for value in snapshot.get("effects", []) as Array:
		var effect := value as Dictionary
		effect_names.append("%s %.0fs" % [effect.get("display_name", effect.get("effect_id", "状态")), float(effect.get("remaining_seconds", 0.0))])
	_effects_label.text = "状态  %s" % ("正常" if effect_names.is_empty() else " · ".join(effect_names))
	_mode_label.text = "生存规则：开启 · [G] 食用快捷栏食物" if enabled else "生存规则：已关闭（属性与伤害暂停）"
	_mode_label.add_theme_color_override("font_color", Color("7fc99a") if enabled else Color("8fa29a"))
	_panel.modulate = Color.WHITE if enabled else Color(0.75, 0.78, 0.76, 1.0)


func _build_hud() -> void:
	_panel = PanelContainer.new()
	_panel.name = "SurvivalPanel"
	UiLayout.top_left(_panel, Vector2(310, 158), Vector2(UiLayout.EDGE_MARGIN, 150))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08171ee8")
	style.border_color = Color("547f72")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	_panel.add_child(column)
	var title := Label.new()
	title.text = "生存状态"
	title.add_theme_color_override("font_color", Color("dce9df"))
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)
	column.add_child(_make_bar_row("饥饿", Color("d2a75d"), &"hunger"))
	column.add_child(_make_bar_row("湿润", Color("6ca8d6"), &"wetness"))
	_temperature_label = Label.new()
	_temperature_label.name = "BodyTemperatureLabel"
	_temperature_label.text = "体温  37.0°C · 舒适"
	_temperature_label.add_theme_color_override("font_color", Color("b9d9cf"))
	column.add_child(_temperature_label)
	_effects_label = Label.new()
	_effects_label.name = "StatusEffectsLabel"
	_effects_label.text = "状态  正常"
	_effects_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_effects_label.add_theme_color_override("font_color", Color("efc980"))
	column.add_child(_effects_label)
	_mode_label = Label.new()
	_mode_label.name = "SurvivalModeLabel"
	_mode_label.text = "生存规则：开启 · [G] 食用快捷栏食物"
	_mode_label.add_theme_font_size_override("font_size", 12)
	_mode_label.add_theme_color_override("font_color", Color("7fc99a"))
	column.add_child(_mode_label)


func _make_bar_row(label_text: String, color: Color, kind: StringName) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 16)
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(36, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("c9d8d1"))
	row.add_child(label)
	var track := ColorRect.new()
	track.color = Color("15231f")
	track.custom_minimum_size = Vector2(225, 10)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(track)
	var fill := ColorRect.new()
	fill.name = "HungerFill" if kind == &"hunger" else "WetnessFill"
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if kind == &"hunger":
		_hunger_fill = fill
	else:
		_wetness_fill = fill
	return row
