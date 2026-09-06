class_name SurvivalCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/survival.json"
const REQUIRED_EFFECT_IDS := [&"poison", &"burning", &"frostbite", &"starvation"]
const REQUIRED_BIOME_IDS := [
	&"deep_ocean", &"ocean", &"coast", &"plains", &"forest", &"desert",
	&"snowfield", &"swamp", &"mountain", &"taiga", &"savanna", &"meadow",
]
const REQUIRED_WEATHER_IDS := [&"CLEAR", &"RAIN", &"SNOW", &"SANDSTORM"]
const REQUIRED_PHASE_IDS := [&"DAWN", &"DAY", &"DUSK", &"NIGHT"]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _ranges: Dictionary = {}
var _defaults: Dictionary = {}
var _rates: Dictionary = {}
var _thresholds: Dictionary = {}
var _environment: Dictionary = {}
var _foods: Dictionary = {}
var _effects: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func range_value(key: StringName, fallback := 0.0) -> float:
	return float(_ranges.get(String(key), fallback))


func default_value(key: StringName, fallback := 0.0) -> float:
	return float(_defaults.get(String(key), fallback))


func rate(key: StringName, fallback := 0.0) -> float:
	return float(_rates.get(String(key), fallback))


func threshold(key: StringName, fallback := 0.0) -> float:
	return float(_thresholds.get(String(key), fallback))


func food_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for value in _foods.keys():
		result.append(StringName(value))
	result.sort()
	return result


func food(item_id: StringName) -> Dictionary:
	return (_foods.get(String(item_id), {}) as Dictionary).duplicate(true)


func effect_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for value in _effects.keys():
		result.append(StringName(value))
	result.sort()
	return result


func effect(effect_id: StringName) -> Dictionary:
	return (_effects.get(String(effect_id), {}) as Dictionary).duplicate(true)


func target_temperature(environment: Dictionary) -> float:
	var layer := String(environment.get("world_layer", "surface"))
	var base := 37.0
	if layer == "surface":
		base = float((_environment.get("biome_temperature", {}) as Dictionary).get(String(environment.get("biome_id", "plains")), 37.0))
		base += float((_environment.get("weather_temperature_offset", {}) as Dictionary).get(String(environment.get("weather_id", "CLEAR")), 0.0))
		base += float((_environment.get("phase_temperature_offset", {}) as Dictionary).get(String(environment.get("phase", "DAY")), 0.0))
	else:
		base = float((_environment.get("layer_temperature", {}) as Dictionary).get(layer, 33.0))
	if bool(environment.get("near_heat", false)):
		base += float(_environment.get("near_heat_temperature_bonus", 0.0))
	return clampf(base, range_value(&"temperature_min"), range_value(&"temperature_max"))


func wetness_rate(environment: Dictionary) -> float:
	var layer := String(environment.get("world_layer", "surface"))
	var gain := 0.0
	if layer == "surface":
		if String(environment.get("weather_id", "CLEAR")) == "RAIN":
			gain += rate(&"wetness_rain_per_second")
		if bool(environment.get("in_water", false)):
			gain += rate(&"wetness_water_per_second")
		if String(environment.get("biome_id", "")) == "swamp":
			gain += rate(&"wetness_swamp_per_second")
	var drying := rate(&"dry_base_per_second")
	if target_temperature(environment) >= range_value(&"temperature_comfort_max"):
		drying += rate(&"dry_hot_bonus_per_second")
	if bool(environment.get("near_heat", false)):
		drying += rate(&"dry_heat_source_bonus_per_second")
	return gain - drying


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open survival configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Survival configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported survival schema version in %s" % _config_path)
		return
	for key in ["ranges", "defaults", "rates", "thresholds", "environment"]:
		if not root.get(key, {}) is Dictionary:
			_fail("Survival section '%s' must be an object" % key)
			return
	_ranges = (root["ranges"] as Dictionary).duplicate(true)
	_defaults = (root["defaults"] as Dictionary).duplicate(true)
	_rates = (root["rates"] as Dictionary).duplicate(true)
	_thresholds = (root["thresholds"] as Dictionary).duplicate(true)
	_environment = (root["environment"] as Dictionary).duplicate(true)
	if not _validate_scalars() or not _validate_environment():
		return
	var item_catalog := ItemCatalog.new()
	for value in root.get("foods", []) as Array:
		if not value is Dictionary:
			_fail("Survival food entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var item_id := StringName(definition.get("item_id", ""))
		var item := item_catalog.item(item_id)
		var hunger_restore := float(definition.get("hunger_restore", -1.0))
		var health_restore := float(definition.get("health_restore", -1.0))
		var temperature_delta := float(definition.get("temperature_delta", 0.0))
		var clear_effects_value: Variant = definition.get("clear_effects", [])
		if item_id.is_empty() or _foods.has(String(item_id)) or item == null or item.category_id not in [&"food", &"potion"] \
				or hunger_restore < 0.0 or health_restore < 0.0 or not clear_effects_value is Array \
				or (hunger_restore <= 0.0 and health_restore <= 0.0 and is_zero_approx(temperature_delta) \
						and (clear_effects_value as Array).is_empty()):
			_fail("Survival food definition is invalid: %s" % item_id)
			return
		_foods[String(item_id)] = definition
	for required_food in [
		&"berry", &"cooked_berries", &"vegetable_stew", &"apple_pie", &"hearty_breakfast",
		&"antidote_potion", &"warming_tonic", &"cooling_tonic",
	]:
		if not _foods.has(String(required_food)):
			_fail("Survival food is missing: %s" % required_food)
			return
	for value in root.get("effects", []) as Array:
		if not value is Dictionary:
			_fail("Survival effect entry must be an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var effect_id := StringName(definition.get("id", ""))
		if effect_id.is_empty() or _effects.has(String(effect_id)) or String(definition.get("display_name", "")).is_empty() \
				or float(definition.get("duration_seconds", 0.0)) <= 0.0 or float(definition.get("tick_seconds", 0.0)) <= 0.0 \
				or float(definition.get("damage_per_tick", -1.0)) < 0.0 \
				or float(definition.get("movement_multiplier", 0.0)) < 0.4 or float(definition.get("movement_multiplier", 0.0)) > 1.0 \
				or not Color.html_is_valid(String(definition.get("color", ""))):
			_fail("Survival effect definition is invalid: %s" % effect_id)
			return
		_effects[String(effect_id)] = definition
	for required_effect in REQUIRED_EFFECT_IDS:
		if not _effects.has(String(required_effect)):
			_fail("Survival effect is missing: %s" % required_effect)
			return
	for food_value in _foods.values():
		for cleared in (food_value as Dictionary).get("clear_effects", []) as Array:
			if not _effects.has(String(cleared)):
				_fail("Survival food references unknown effect: %s" % cleared)
				return
	_valid = true


func _validate_scalars() -> bool:
	var hunger_min := range_value(&"hunger_min")
	var hunger_max := range_value(&"hunger_max")
	var temperature_min := range_value(&"temperature_min")
	var temperature_max := range_value(&"temperature_max")
	var comfort_min := range_value(&"temperature_comfort_min")
	var comfort_max := range_value(&"temperature_comfort_max")
	var wetness_min := range_value(&"wetness_min")
	var wetness_max := range_value(&"wetness_max")
	if hunger_min != 0.0 or hunger_max <= hunger_min or temperature_max <= temperature_min \
			or comfort_min <= temperature_min or comfort_max <= comfort_min or comfort_max >= temperature_max \
			or wetness_min != 0.0 or wetness_max <= wetness_min:
		_fail("Survival ranges are invalid")
		return false
	if default_value(&"hunger") < hunger_min or default_value(&"hunger") > hunger_max \
			or default_value(&"body_temperature") < comfort_min or default_value(&"body_temperature") > comfort_max \
			or default_value(&"wetness") < wetness_min or default_value(&"wetness") > wetness_max:
		_fail("Survival defaults are outside configured ranges")
		return false
	for key in ["hunger_idle_per_second", "temperature_response_per_second", "dry_base_per_second"]:
		if rate(StringName(key), -1.0) <= 0.0:
			_fail("Survival rate must be positive: %s" % key)
			return false
	if threshold(&"low_hunger") <= hunger_min or threshold(&"low_hunger") >= hunger_max \
			or threshold(&"frostbite_temperature") <= temperature_min or threshold(&"frostbite_temperature") >= comfort_min \
			or threshold(&"burning_temperature") <= comfort_max or threshold(&"burning_temperature") >= temperature_max \
			or threshold(&"poison_wetness") <= wetness_min or threshold(&"poison_wetness") >= wetness_max:
		_fail("Survival thresholds are invalid")
		return false
	return true


func _validate_environment() -> bool:
	for key in ["biome_temperature", "layer_temperature", "weather_temperature_offset", "phase_temperature_offset"]:
		if not _environment.get(key, {}) is Dictionary:
			_fail("Survival environment map is invalid: %s" % key)
			return false
	var biomes := _environment["biome_temperature"] as Dictionary
	for biome_id in REQUIRED_BIOME_IDS:
		if not biomes.has(String(biome_id)):
			_fail("Survival environment is missing biome: %s" % biome_id)
			return false
	var layers := _environment["layer_temperature"] as Dictionary
	for layer in [&"underground", &"dungeon"]:
		if not layers.has(String(layer)):
			_fail("Survival environment is missing layer: %s" % layer)
			return false
	var weather := _environment["weather_temperature_offset"] as Dictionary
	for weather_id in REQUIRED_WEATHER_IDS:
		if not weather.has(String(weather_id)):
			_fail("Survival environment is missing weather: %s" % weather_id)
			return false
	var phases := _environment["phase_temperature_offset"] as Dictionary
	for phase_id in REQUIRED_PHASE_IDS:
		if not phases.has(String(phase_id)):
			_fail("Survival environment is missing phase: %s" % phase_id)
			return false
	return true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
