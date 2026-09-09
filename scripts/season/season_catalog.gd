class_name SeasonCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/season.json"
const SEASON_IDS := [&"spring", &"summer", &"autumn", &"winter"]

var _valid := false
var _error_message := ""
var _season_duration_days := 8
var _transition_days := 1
var _seasons: Array[Dictionary] = []


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_load_config(config_path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func season_duration_days() -> int:
	return _season_duration_days


func transition_days() -> int:
	return _transition_days


func season_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for season in _seasons:
		result.append(season["id"] as StringName)
	return result


func season_count() -> int:
	return _seasons.size()


func season_index_for_day(day: int) -> int:
	if _seasons.is_empty():
		return 0
	var cycle_length := _seasons.size() * _season_duration_days
	if cycle_length <= 0:
		return 0
	var day_in_cycle := posmod(day - 1, cycle_length)
	return day_in_cycle / _season_duration_days


func season_id_for_day(day: int) -> StringName:
	var index := season_index_for_day(day)
	if index < 0 or index >= _seasons.size():
		return &"spring"
	return _seasons[index]["id"] as StringName


func definition(season_id: StringName) -> Dictionary:
	for season in _seasons:
		if season["id"] == season_id:
			return season
	return {}


func temperature_offset(season_id: StringName) -> float:
	return float(definition(season_id).get("temperature_offset", 0.0))


func plant_tint(season_id: StringName) -> Color:
	return Color(String(definition(season_id).get("plant_tint", "ffffff00")))


func river_freezes(season_id: StringName) -> bool:
	return bool(definition(season_id).get("river_freezes", false))


func crop_growth_multiplier(season_id: StringName) -> float:
	return float(definition(season_id).get("crop_growth_multiplier", 1.0))


func resource_yield_multiplier(season_id: StringName) -> float:
	return float(definition(season_id).get("resource_yield_multiplier", 1.0))


func enemy_population_multiplier(season_id: StringName) -> float:
	return float(definition(season_id).get("enemy_population_multiplier", 1.0))


func weather_weight(season_id: StringName, weather_id: StringName) -> float:
	var weights := definition(season_id).get("weather_weights", {}) as Dictionary
	return float(weights.get(String(weather_id), 0.0))


func _load_config(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open season configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Season configuration is not a JSON object: %s" % path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported season schema version in %s" % path)
		return
	_season_duration_days = int(root.get("season_duration_days", 0))
	_transition_days = int(root.get("transition_days", 0))
	if _season_duration_days <= 0 or _transition_days < 0:
		_fail("Season duration must be positive and transition non-negative")
		return
	var seen := {}
	for value in root.get("seasons", []) as Array:
		if not value is Dictionary:
			_fail("Season entry is not an object")
			return
		var source := value as Dictionary
		var season_id := StringName(source.get("id", ""))
		if season_id.is_empty() or seen.has(season_id):
			_fail("Season entries require unique IDs")
			return
		seen[season_id] = true
		var weather_weights := source.get("weather_weights", {}) as Dictionary
		var weight_sum := 0.0
		for weight_value in weather_weights.values():
			weight_sum += float(weight_value)
		if weight_sum <= 0.0:
			_fail("Season %s must have positive weather weights" % season_id)
			return
		_seasons.append({
			"id": season_id,
			"display_name": String(source.get("display_name", season_id)),
			"temperature_offset": float(source.get("temperature_offset", 0.0)),
			"plant_tint": String(source.get("plant_tint", "ffffff00")),
			"river_freezes": bool(source.get("river_freezes", false)),
			"crop_growth_multiplier": float(source.get("crop_growth_multiplier", 1.0)),
			"resource_yield_multiplier": float(source.get("resource_yield_multiplier", 1.0)),
			"enemy_population_multiplier": float(source.get("enemy_population_multiplier", 1.0)),
			"weather_weights": weather_weights,
		})
	if _seasons.size() != 4:
		_fail("Season configuration must contain exactly four seasons")
		return
	for required_id in SEASON_IDS:
		if not seen.has(required_id):
			_fail("Missing required season: %s" % required_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
