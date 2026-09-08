class_name BoatState
extends RefCounted

# 已部署船只的唯一世界状态所有者。船只 ID 即其稳定水面格坐标，
# 物理持久化归属所属地表区块差分；登船状态是会话状态，不做持久化。
const SCHEMA_VERSION := 1

var last_error := ""
var _boats: Dictionary = {}
var _ocean_catalog: OceanCatalog


func _init(catalog := OceanCatalog.new()) -> void:
	_ocean_catalog = catalog


func boat_count() -> int:
	return _boats.size()


func boats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _boats.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["boat_id"]) < String(b["boat_id"]))
	return result


func boat_at(world_tile: Vector2i) -> Dictionary:
	var key := _boat_id_for_tile(world_tile)
	return (_boats.get(key, {}) as Dictionary).duplicate(true)


func boat_definition_for_item(item_id: StringName) -> Dictionary:
	return _ocean_catalog.boat_for_item(item_id)


func can_deploy(item_id: StringName) -> bool:
	var definition := _ocean_catalog.boat_for_item(item_id)
	if definition.is_empty():
		last_error = "当前物品不是可部署的船只"
		return false
	var maximum := int(definition.get("maximum_count", 0))
	if _boats.size() >= maximum:
		last_error = "已达到该船只的全球部署上限（%d 艘）" % maximum
		return false
	last_error = ""
	return true


func deploy(world_tile: Vector2i, item_id: StringName) -> Dictionary:
	var definition := _ocean_catalog.boat_for_item(item_id)
	if definition.is_empty():
		last_error = "当前物品不是可部署的船只"
		return {}
	var key := _boat_id_for_tile(world_tile)
	if _boats.has(key):
		last_error = "该水面已经有船只停靠"
		return {}
	if _boats.size() >= int(definition.get("maximum_count", 0)):
		last_error = "已达到该船只的全球部署上限（%d 艘）" % int(definition.get("maximum_count", 0))
		return {}
	var record := {
		"boat_id": key,
		"item_id": String(item_id),
		"world_tile": [world_tile.x, world_tile.y],
	}
	_boats[key] = record
	last_error = ""
	return record.duplicate(true)


func remove_at(world_tile: Vector2i) -> Dictionary:
	var key := _boat_id_for_tile(world_tile)
	if not _boats.has(key):
		last_error = "该位置没有可收回的船只"
		return {}
	var record := (_boats[key] as Dictionary).duplicate(true)
	_boats.erase(key)
	last_error = ""
	return record


func relocate(boat_id: String, new_tile: Vector2i) -> bool:
	if not _boats.has(boat_id):
		return _fail("无法移动不存在的船只")
	var new_key := _boat_id_for_tile(new_tile)
	if new_key != boat_id and _boats.has(new_key):
		return _fail("目标水面已有船只停靠")
	var record := _boats[boat_id] as Dictionary
	_boats.erase(boat_id)
	record["boat_id"] = new_key
	record["world_tile"] = [new_tile.x, new_tile.y]
	_boats[new_key] = record
	last_error = ""
	return true


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"boats": boats(),
	}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_boats.clear()
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("boats", []) is Array:
		return _fail("船只状态格式无效")
	var restored: Dictionary = {}
	for record_value in value.get("boats", []) as Array:
		if not record_value is Dictionary:
			return _fail("船只记录必须是对象")
		var record := record_value as Dictionary
		var boat_id := String(record.get("boat_id", ""))
		var item_id := StringName(record.get("item_id", ""))
		var tile_value: Variant = record.get("world_tile", [])
		if tile_value is Array and (tile_value as Array).size() == 2:
			var expected_id := "surface:%d:%d" % [int((tile_value as Array)[0]), int((tile_value as Array)[1])]
			if boat_id != expected_id:
				return _fail("船只编号与坐标不一致")
		if boat_id.is_empty() or restored.has(boat_id) or _ocean_catalog.boat_for_item(item_id).is_empty() \
				or not tile_value is Array or (tile_value as Array).size() != 2:
			return _fail("船只记录无效：%s" % boat_id)
		restored[boat_id] = {
			"boat_id": boat_id,
			"item_id": String(item_id),
			"world_tile": [int((tile_value as Array)[0]), int((tile_value as Array)[1])],
		}
	_boats = restored
	last_error = ""
	return true


func _boat_id_for_tile(world_tile: Vector2i) -> String:
	return "surface:%d:%d" % [world_tile.x, world_tile.y]


func _fail(message: String) -> bool:
	last_error = message
	return false
