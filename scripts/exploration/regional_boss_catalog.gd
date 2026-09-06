class_name RegionalBossCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/regional_bosses.json"

var _valid := false
var _error_message := ""
var _discovery_radius_chunks := 2
var _bosses: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _enemy_catalog := EnemyCatalog.new()
var _biome_catalog := BiomeCatalog.new()


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_load_config(config_path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func discovery_radius_chunks() -> int:
	return _discovery_radius_chunks


func bosses() -> Array[Dictionary]:
	return _bosses.duplicate(true)


func boss(boss_id: StringName) -> Dictionary:
	return (_by_id.get(String(boss_id), {}) as Dictionary).duplicate(true)


func boss_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for value in _bosses:
		result.append(StringName(value["id"]))
	return result


func _load_config(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("无法打开区域 Boss 配置 %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int((parsed as Dictionary).get("schema_version", 0)) != 1:
		_fail("区域 Boss 配置必须是版本 1 JSON 对象")
		return
	if not _enemy_catalog.is_valid() or not _biome_catalog.is_valid():
		_fail("区域 Boss 依赖的敌人或群系目录无效")
		return
	var root := parsed as Dictionary
	_discovery_radius_chunks = int(root.get("discovery_radius_chunks", 0))
	if _discovery_radius_chunks < 1 or _discovery_radius_chunks > 4:
		_fail("区域 Boss 探索半径无效")
		return
	for value in root.get("bosses", []) as Array:
		if not value is Dictionary:
			_fail("区域 Boss 条目必须是对象")
			return
		var definition := (value as Dictionary).duplicate(true)
		var boss_id := String(definition.get("id", ""))
		var enemy_id := StringName(definition.get("enemy_id", ""))
		var enemy := _enemy_catalog.enemy(enemy_id)
		var minimum := int(definition.get("minimum_ring_chunks", 0))
		var maximum := int(definition.get("maximum_ring_chunks", 0))
		var biomes := definition.get("preferred_biomes", []) as Array
		if boss_id.is_empty() or _by_id.has(boss_id) or enemy == null or enemy.role != &"boss" \
				or not enemy.world_layers.has(&"surface") or minimum < 3 or maximum < minimum or biomes.is_empty():
			_fail("区域 Boss 定义无效：%s" % boss_id)
			return
		for biome_value in biomes:
			if not _biome_catalog.has_biome(StringName(biome_value)):
				_fail("区域 Boss %s 引用了未知群系 %s" % [boss_id, biome_value])
				return
		_bosses.append(definition)
		_by_id[boss_id] = definition
	if _bosses.size() != 3:
		_fail("V2.0 必须配置三个区域 Boss")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
