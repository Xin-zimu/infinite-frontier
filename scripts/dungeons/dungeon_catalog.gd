class_name DungeonCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/dungeons.json"

var _valid := false
var _error_message := ""
var _generation: Dictionary = {}
var _features: Dictionary = {}
var _reset_rules: Dictionary = {}
var _chest_loot: Array[Dictionary] = []
var _item_catalog := ItemCatalog.new()


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_load_config(config_path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func generation_value(key: String, fallback: Variant) -> Variant:
	return _generation.get(key, fallback)


func feature_value(key: String, fallback: Variant) -> Variant:
	return _features.get(key, fallback)


func reset_value(key: String, fallback: Variant) -> Variant:
	return _reset_rules.get(key, fallback)


func trap_damage() -> float:
	return float(feature_value("trap_damage", 18.0))


func chest_loot(chest_key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_weight := 0.0
	for rule in _chest_loot:
		total_weight += float(rule["weight"])
	for draw in 2:
		var stable_hash := WorldSeed.from_text("%s|dungeon-chest-loot|%d" % [chest_key, draw])
		var cursor := float(stable_hash & 0xffffff) / 16777216.0 * total_weight
		var selected := _chest_loot[-1]
		for rule in _chest_loot:
			cursor -= float(rule["weight"])
			if cursor < 0.0:
				selected = rule
				break
		var minimum := int(selected["minimum"])
		var maximum := int(selected["maximum"])
		var quantity := minimum + posmod(int(stable_hash >> 24), maximum - minimum + 1)
		var item_id := StringName(selected["item_id"])
		var existing := -1
		for index in result.size():
			if result[index]["item_id"] == item_id:
				existing = index
				break
		if existing >= 0:
			result[existing]["quantity"] = int(result[existing]["quantity"]) + quantity
		else:
			result.append({"item_id": item_id, "quantity": quantity})
	return result


func _load_config(config_path: String) -> void:
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		_fail("无法打开地牢配置 %s：%s" % [config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("地牢配置必须是 JSON 对象")
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("地牢配置版本无效")
		return
	_generation = (root.get("generation", {}) as Dictionary).duplicate(true)
	_features = (root.get("features", {}) as Dictionary).duplicate(true)
	_reset_rules = (root.get("reset_rules", {}) as Dictionary).duplicate(true)
	var room_min := int(generation_value("room_count_minimum", 0))
	var room_max := int(generation_value("room_count_maximum", 0))
	var size_min := int(generation_value("room_size_minimum", 0))
	var size_max := int(generation_value("room_size_maximum", 0))
	if room_min < 4 or room_max < room_min or room_max > 9 or size_min < 4 or size_max < size_min or size_max > 10:
		_fail("地牢房间生成参数超出安全范围")
		return
	if int(feature_value("locked_doors", 0)) < 1 \
			or int(feature_value("keys", 0)) != int(feature_value("locked_doors", 0)) \
			or int(feature_value("traps", 0)) < 1 \
			or int(feature_value("chests", 0)) < 1 \
			or int(feature_value("elite_enemies", 0)) < 1 \
			or trap_damage() <= 0.0:
		_fail("地牢功能数量或陷阱伤害无效")
		return
	if not bool(reset_value("incomplete_resets_on_exit", false)) or not bool(reset_value("completed_state_persists", false)):
		_fail("V1.7 地牢必须显式配置未完成重置与完成持久化规则")
		return
	if not _item_catalog.is_valid():
		_fail("地牢依赖的物品目录无效")
		return
	for value in root.get("chest_loot", []) as Array:
		if not value is Dictionary:
			_fail("地牢宝箱掉落规则必须是对象")
			return
		var rule := (value as Dictionary).duplicate(true)
		var item_id := StringName(rule.get("item_id", ""))
		if not _item_catalog.has_item(item_id) or int(rule.get("minimum", 0)) < 1 \
				or int(rule.get("maximum", 0)) < int(rule.get("minimum", 0)) \
				or float(rule.get("weight", 0.0)) <= 0.0:
			_fail("地牢宝箱掉落规则无效：%s" % item_id)
			return
		_chest_loot.append(rule)
	if _chest_loot.is_empty():
		_fail("地牢宝箱掉落不能为空")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
