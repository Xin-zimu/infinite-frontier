class_name RegionalBossState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _defeated: Dictionary = {}
var _catalog := RegionalBossCatalog.new()


func defeat(boss_id: StringName) -> bool:
	if _catalog.boss(boss_id).is_empty() or _defeated.has(String(boss_id)):
		return false
	_defeated[String(boss_id)] = true
	return true


func is_defeated(boss_id: StringName) -> bool:
	return _defeated.has(String(boss_id))


func defeated_ids() -> Array[String]:
	var result: Array[String] = []
	for value in _defeated.keys():
		result.append(String(value))
	result.sort()
	return result


func defeated_count() -> int:
	return _defeated.size()


func persistence_snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "defeated_ids": defeated_ids()}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_defeated.clear()
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("defeated_ids", []) is Array:
		last_error = "区域 Boss 进度格式无效"
		return false
	var restored := {}
	for id_value in value.get("defeated_ids", []) as Array:
		var boss_id := StringName(id_value)
		if _catalog.boss(boss_id).is_empty() or restored.has(String(boss_id)):
			last_error = "区域 Boss 进度包含未知或重复 ID"
			return false
		restored[String(boss_id)] = true
	_defeated = restored
	last_error = ""
	return true
