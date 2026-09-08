class_name SurvivalState
extends RefCounted

const SCHEMA_VERSION := 2
const EXPOSURE_IDS := [&"poison", &"burning", &"frostbite"]

var last_error := ""
var hunger := 100.0
var body_temperature := 37.0
var wetness := 0.0
var oxygen := 100.0

var _catalog: SurvivalCatalog
var _effects: Dictionary = {}
var _exposures: Dictionary = {}


func _init(catalog := SurvivalCatalog.new()) -> void:
	_catalog = catalog
	_reset()


func update(delta: float, environment: Dictionary, enabled := true) -> Dictionary:
	var elapsed := maxf(delta, 0.0)
	if not enabled or elapsed <= 0.0 or not _catalog.is_valid():
		return {
			"changed": false,
			"damage": 0.0,
			"damage_sources": [],
			"new_effects": [],
			"expired_effects": [],
			"state": status_snapshot(enabled),
		}
	var before := persistence_snapshot()
	var activity := StringName(environment.get("activity", &"IDLE"))
	var hunger_rate := _catalog.rate(&"hunger_idle_per_second")
	if activity == &"WALK":
		hunger_rate += _catalog.rate(&"hunger_walk_bonus_per_second")
	elif activity in [&"RUN", &"ROLL"]:
		hunger_rate += _catalog.rate(&"hunger_run_bonus_per_second")
	hunger = clampf(
		hunger - hunger_rate * elapsed,
		_catalog.range_value(&"hunger_min"),
		_catalog.range_value(&"hunger_max")
	)
	body_temperature = move_toward(
		body_temperature,
		_catalog.target_temperature(environment),
		_catalog.rate(&"temperature_response_per_second") * elapsed
	)
	body_temperature = clampf(
		body_temperature,
		_catalog.range_value(&"temperature_min"),
		_catalog.range_value(&"temperature_max")
	)
	wetness = clampf(
		wetness + _catalog.wetness_rate(environment) * elapsed,
		_catalog.range_value(&"wetness_min"),
		_catalog.range_value(&"wetness_max")
	)
	var new_effects: Array[String] = []
	# 氧气仅在表面层的深水中消耗；离水后立即回升，触底则进入溺水状态。
	var in_deep_water := String(environment.get("world_layer", "surface")) == "surface" \
			and bool(environment.get("in_deep_water", false))
	if in_deep_water:
		oxygen = clampf(
			oxygen - _catalog.rate(&"oxygen_deep_water_drain_per_second") * elapsed,
			_catalog.range_value(&"oxygen_min"),
			_catalog.range_value(&"oxygen_max")
		)
	else:
		oxygen = clampf(
			oxygen + _catalog.rate(&"oxygen_recovery_per_second") * elapsed,
			_catalog.range_value(&"oxygen_min"),
			_catalog.range_value(&"oxygen_max")
		)
	if in_deep_water and oxygen <= _catalog.range_value(&"oxygen_min") + 0.001:
		if not _effects.has("drowning"):
			apply_effect(&"drowning")
			new_effects.append("drowning")
		elif float((_effects["drowning"] as Dictionary).get("remaining_seconds", 0.0)) <= 1.0:
			apply_effect(&"drowning")
	elif not in_deep_water and _effects.has("drowning"):
		clear_effect(&"drowning")
	_update_exposure(
		&"frostbite",
		body_temperature <= _catalog.threshold(&"frostbite_temperature"),
		_catalog.threshold(&"frostbite_delay_seconds"),
		elapsed,
		new_effects
	)
	_update_exposure(
		&"burning",
		body_temperature >= _catalog.threshold(&"burning_temperature"),
		_catalog.threshold(&"burning_delay_seconds"),
		elapsed,
		new_effects
	)
	_update_exposure(
		&"poison",
		String(environment.get("world_layer", "surface")) == "surface" \
				and String(environment.get("biome_id", "")) == "swamp" \
				and wetness >= _catalog.threshold(&"poison_wetness"),
		_catalog.threshold(&"poison_delay_seconds"),
		elapsed,
		new_effects
	)
	if hunger <= _catalog.range_value(&"hunger_min") + 0.001:
		if not _effects.has("starvation"):
			apply_effect(&"starvation")
			new_effects.append("starvation")
		elif float((_effects["starvation"] as Dictionary).get("remaining_seconds", 0.0)) <= 1.0:
			apply_effect(&"starvation")
	var effect_result := _tick_effects(elapsed)
	return {
		"changed": before != persistence_snapshot(),
		"damage": float(effect_result["damage"]),
		"damage_sources": effect_result["damage_sources"],
		"new_effects": new_effects,
		"expired_effects": effect_result["expired_effects"],
		"state": status_snapshot(true),
	}


func apply_effect(effect_id: StringName, duration_seconds := -1.0) -> bool:
	var definition := _catalog.effect(effect_id)
	if definition.is_empty():
		last_error = "未知生存状态：%s" % effect_id
		return false
	var duration := float(definition["duration_seconds"]) if duration_seconds <= 0.0 else minf(duration_seconds, float(definition["duration_seconds"]))
	var current := (_effects.get(String(effect_id), {}) as Dictionary).duplicate(true)
	_effects[String(effect_id)] = {
		"effect_id": String(effect_id),
		"remaining_seconds": maxf(duration, float(current.get("remaining_seconds", 0.0))),
		"tick_elapsed": float(current.get("tick_elapsed", 0.0)),
	}
	last_error = ""
	return true


func clear_effect(effect_id: StringName) -> bool:
	var existed := _effects.erase(String(effect_id))
	if _exposures.has(String(effect_id)):
		_exposures[String(effect_id)] = 0.0
	return existed


func has_effect(effect_id: StringName) -> bool:
	return _effects.has(String(effect_id))


func can_consume_food(item_id: StringName, missing_health := 0.0) -> bool:
	var definition := _catalog.food(item_id)
	if definition.is_empty():
		last_error = "当前物品不是可食用食物"
		return false
	var hunger_restore := float(definition.get("hunger_restore", 0.0))
	var temperature_delta := float(definition.get("temperature_delta", 0.0))
	var useful := (hunger_restore > 0.0 and hunger < _catalog.range_value(&"hunger_max") - 0.001) \
			or (missing_health > 0.001 and float(definition.get("health_restore", 0.0)) > 0.0) \
			or (temperature_delta > 0.0 and body_temperature < _catalog.default_value(&"body_temperature") - 0.001) \
			or (temperature_delta < 0.0 and body_temperature > _catalog.default_value(&"body_temperature") + 0.001)
	for effect_id in definition.get("clear_effects", []) as Array:
		useful = useful or has_effect(StringName(effect_id))
	last_error = "当前状态不需要使用该食物或药水" if not useful else ""
	return useful


func consume_food(item_id: StringName, missing_health := 0.0) -> Dictionary:
	if not can_consume_food(item_id, missing_health):
		return {"ok": false, "message": last_error}
	var definition := _catalog.food(item_id)
	var before_hunger := hunger
	var before_temperature := body_temperature
	hunger = clampf(
		hunger + float(definition.get("hunger_restore", 0.0)),
		_catalog.range_value(&"hunger_min"),
		_catalog.range_value(&"hunger_max")
	)
	body_temperature = clampf(
		body_temperature + float(definition.get("temperature_delta", 0.0)),
		_catalog.range_value(&"temperature_min"),
		_catalog.range_value(&"temperature_max")
	)
	var cleared: Array[String] = []
	for effect_id_value in definition.get("clear_effects", []) as Array:
		var effect_id := StringName(effect_id_value)
		if clear_effect(effect_id):
			cleared.append(String(effect_id))
	last_error = ""
	return {
		"ok": true,
		"item_id": String(item_id),
		"hunger_restored": hunger - before_hunger,
		"temperature_changed": body_temperature - before_temperature,
		"health_restored": minf(maxf(missing_health, 0.0), float(definition.get("health_restore", 0.0))),
		"cleared_effects": cleared,
	}


func rest_at_inn() -> void:
	hunger = maxf(_catalog.range_value(&"hunger_min"), hunger - 8.0)
	body_temperature = _catalog.default_value(&"body_temperature")
	wetness = _catalog.default_value(&"wetness")
	oxygen = _catalog.default_value(&"oxygen")
	_effects.clear()
	for effect_id in EXPOSURE_IDS:
		_exposures[String(effect_id)] = 0.0


func recover_after_death() -> void:
	hunger = maxf(50.0, hunger)
	body_temperature = _catalog.default_value(&"body_temperature")
	wetness = _catalog.default_value(&"wetness")
	oxygen = _catalog.default_value(&"oxygen")
	_effects.clear()
	for effect_id in EXPOSURE_IDS:
		_exposures[String(effect_id)] = 0.0


func movement_multiplier(enabled := true) -> float:
	if not enabled:
		return 1.0
	var result := 0.90 if hunger <= _catalog.threshold(&"low_hunger") else 1.0
	for effect_id_value in _effects.keys():
		var definition := _catalog.effect(StringName(effect_id_value))
		result *= float(definition.get("movement_multiplier", 1.0))
	return clampf(result, 0.50, 1.0)


func status_snapshot(enabled := true) -> Dictionary:
	var effects: Array[Dictionary] = []
	for effect_value in _effects.values():
		var record := effect_value as Dictionary
		var definition := _catalog.effect(StringName(record.get("effect_id", "")))
		effects.append({
			"effect_id": String(record["effect_id"]),
			"display_name": String(definition.get("display_name", record["effect_id"])),
			"remaining_seconds": float(record["remaining_seconds"]),
			"color": String(definition.get("color", "ffffff")),
		})
	effects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["effect_id"]) < String(b["effect_id"]))
	var temperature_state := "舒适"
	if body_temperature < _catalog.range_value(&"temperature_comfort_min"):
		temperature_state = "寒冷"
	elif body_temperature > _catalog.range_value(&"temperature_comfort_max"):
		temperature_state = "炎热"
	return {
		"schema_version": SCHEMA_VERSION,
		"enabled": enabled,
		"hunger": hunger,
		"hunger_maximum": _catalog.range_value(&"hunger_max"),
		"body_temperature": body_temperature,
		"temperature_state": temperature_state,
		"wetness": wetness,
		"wetness_maximum": _catalog.range_value(&"wetness_max"),
		"oxygen": oxygen,
		"oxygen_maximum": _catalog.range_value(&"oxygen_max"),
		"movement_multiplier": movement_multiplier(enabled),
		"effects": effects,
	}


func persistence_snapshot() -> Dictionary:
	var effects: Array[Dictionary] = []
	for value in _effects.values():
		effects.append((value as Dictionary).duplicate(true))
	effects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["effect_id"]) < String(b["effect_id"]))
	var exposures := {}
	for effect_id in EXPOSURE_IDS:
		exposures[String(effect_id)] = float(_exposures.get(String(effect_id), 0.0))
	return {
		"schema_version": SCHEMA_VERSION,
		"hunger": hunger,
		"body_temperature": body_temperature,
		"wetness": wetness,
		"oxygen": oxygen,
		"effects": effects,
		"exposures": exposures,
	}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_reset()
		last_error = ""
		return true
	if not _catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION \
			or not value.get("effects", []) is Array or not value.get("exposures", {}) is Dictionary:
		return _fail("生存状态格式无效")
	var restored_hunger := float(value.get("hunger", -1.0))
	var restored_temperature := float(value.get("body_temperature", -1.0))
	var restored_wetness := float(value.get("wetness", -1.0))
	var restored_oxygen := float(value.get("oxygen", -1.0))
	if not is_finite(restored_hunger) or restored_hunger < _catalog.range_value(&"hunger_min") or restored_hunger > _catalog.range_value(&"hunger_max") \
			or not is_finite(restored_temperature) or restored_temperature < _catalog.range_value(&"temperature_min") or restored_temperature > _catalog.range_value(&"temperature_max") \
			or not is_finite(restored_wetness) or restored_wetness < _catalog.range_value(&"wetness_min") or restored_wetness > _catalog.range_value(&"wetness_max") \
			or not is_finite(restored_oxygen) or restored_oxygen < _catalog.range_value(&"oxygen_min") or restored_oxygen > _catalog.range_value(&"oxygen_max"):
		return _fail("生存属性超出范围")
	var restored_effects := {}
	for effect_value in value.get("effects", []) as Array:
		if not effect_value is Dictionary:
			return _fail("生存状态效果必须是对象")
		var record := effect_value as Dictionary
		var effect_id := StringName(record.get("effect_id", ""))
		var definition := _catalog.effect(effect_id)
		var remaining := float(record.get("remaining_seconds", -1.0))
		var tick_elapsed := float(record.get("tick_elapsed", -1.0))
		if definition.is_empty() or restored_effects.has(String(effect_id)) or not is_finite(remaining) or remaining <= 0.0 \
				or remaining > float(definition["duration_seconds"]) or not is_finite(tick_elapsed) or tick_elapsed < 0.0 \
				or tick_elapsed >= float(definition["tick_seconds"]):
			return _fail("生存状态效果记录无效")
		restored_effects[String(effect_id)] = {
			"effect_id": String(effect_id),
			"remaining_seconds": remaining,
			"tick_elapsed": tick_elapsed,
		}
	var exposure_value := value.get("exposures", {}) as Dictionary
	var restored_exposures := {}
	for effect_id in EXPOSURE_IDS:
		var exposure := float(exposure_value.get(String(effect_id), -1.0))
		var limit := _catalog.threshold(StringName("%s_delay_seconds" % effect_id))
		if not is_finite(exposure) or exposure < 0.0 or exposure > limit:
			return _fail("生存环境暴露记录无效")
		restored_exposures[String(effect_id)] = exposure
	hunger = restored_hunger
	body_temperature = restored_temperature
	wetness = restored_wetness
	oxygen = restored_oxygen
	_effects = restored_effects
	_exposures = restored_exposures
	last_error = ""
	return true


func _update_exposure(effect_id: StringName, active: bool, delay: float, elapsed: float, new_effects: Array[String]) -> void:
	var key := String(effect_id)
	var exposure := float(_exposures.get(key, 0.0))
	if active:
		exposure = minf(delay, exposure + elapsed)
		if exposure >= delay and not _effects.has(key):
			apply_effect(effect_id)
			new_effects.append(key)
	else:
		exposure = maxf(0.0, exposure - elapsed * 2.0)
	_exposures[key] = exposure


func _tick_effects(elapsed: float) -> Dictionary:
	var damage := 0.0
	var damage_sources: Array[String] = []
	var expired_effects: Array[String] = []
	for effect_id_value in _effects.keys().duplicate():
		var effect_id := String(effect_id_value)
		var definition := _catalog.effect(StringName(effect_id))
		var record := (_effects[effect_id] as Dictionary).duplicate(true)
		record["remaining_seconds"] = float(record["remaining_seconds"]) - elapsed
		var tick_seconds := float(definition["tick_seconds"])
		var tick_elapsed := float(record["tick_elapsed"]) + elapsed
		var ticks := floori(tick_elapsed / tick_seconds)
		if ticks > 0:
			damage += float(ticks) * float(definition["damage_per_tick"])
			damage_sources.append(effect_id)
			tick_elapsed = fposmod(tick_elapsed, tick_seconds)
		record["tick_elapsed"] = tick_elapsed
		if float(record["remaining_seconds"]) <= 0.0:
			_effects.erase(effect_id)
			expired_effects.append(effect_id)
		else:
			_effects[effect_id] = record
	return {"damage": damage, "damage_sources": damage_sources, "expired_effects": expired_effects}


func _reset() -> void:
	hunger = _catalog.default_value(&"hunger", 100.0)
	body_temperature = _catalog.default_value(&"body_temperature", 37.0)
	wetness = _catalog.default_value(&"wetness", 0.0)
	oxygen = _catalog.default_value(&"oxygen", 100.0)
	_effects.clear()
	_exposures.clear()
	for effect_id in EXPOSURE_IDS:
		_exposures[String(effect_id)] = 0.0


func _fail(message: String) -> bool:
	last_error = message
	return false
