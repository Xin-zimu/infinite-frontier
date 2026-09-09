class_name SeasonState
extends RefCounted

const SCHEMA_VERSION := 1

var _catalog: SeasonCatalog
var _day := 1


func _init(catalog := SeasonCatalog.new(), initial_day := 1) -> void:
	_catalog = catalog
	_day = maxi(1, initial_day)


func catalog() -> SeasonCatalog:
	return _catalog


func day() -> int:
	return _day


func advance_days(days: int) -> Dictionary:
	_day = maxi(1, _day + maxi(days, 0))
	return snapshot()


func advance_to_day(day: int) -> Dictionary:
	_day = maxi(1, day)
	return snapshot()


func season_id() -> StringName:
	return _catalog.season_id_for_day(_day)


func season_index() -> int:
	return _catalog.season_index_for_day(_day)


func temperature_offset() -> float:
	return _catalog.temperature_offset(season_id())


func plant_tint() -> Color:
	return _catalog.plant_tint(season_id())


func river_freezes() -> bool:
	return _catalog.river_freezes(season_id())


func crop_growth_multiplier() -> float:
	return _catalog.crop_growth_multiplier(season_id())


func resource_yield_multiplier() -> float:
	return _catalog.resource_yield_multiplier(season_id())


func enemy_population_multiplier() -> float:
	return _catalog.enemy_population_multiplier(season_id())


func weather_weight(weather_id: StringName) -> float:
	return _catalog.weather_weight(season_id(), weather_id)


func snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"day": _day,
		"season_id": String(season_id()),
		"season_index": season_index(),
		"temperature_offset": temperature_offset(),
		"plant_tint": plant_tint(),
		"river_freezes": river_freezes(),
		"crop_growth_multiplier": crop_growth_multiplier(),
		"resource_yield_multiplier": resource_yield_multiplier(),
		"enemy_population_multiplier": enemy_population_multiplier(),
	}


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"day": _day,
	}


func restore_snapshot(value: Dictionary) -> bool:
	if not _catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		return _fail("Season state schema version mismatch")
	var restored_day := int(value.get("day", 0))
	if restored_day < 1:
		return _fail("Season day must be positive")
	_day = restored_day
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
