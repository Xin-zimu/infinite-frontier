class_name CaveCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/caves.json"

var _valid := false
var _error_message := ""
var _generation: Dictionary = {}
var _features: Dictionary = {}
var _veins: Array[Dictionary] = []
var _chest_loot: Array[Dictionary] = []
var _resource_catalog := ResourceCatalog.new()
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


func entrance_region_chunks() -> int:
	return int(generation_value("entrance_region_chunks", 4))


func veins() -> Array[Dictionary]:
	return _veins.duplicate(true)


func vein_resource_code(roll: float) -> int:
	var total := 0.0
	for rule in _veins:
		total += float(rule["weight"])
	if total <= 0.0:
		return -1
	var cursor := clampf(roll, 0.0, 0.999999) * total
	for rule in _veins:
		cursor -= float(rule["weight"])
		if cursor < 0.0:
			return _resource_catalog.code_for_id(StringName(rule["resource_id"]))
	return _resource_catalog.code_for_id(StringName(_veins[-1]["resource_id"]))


func vein_cluster_chance(resource_code: int) -> float:
	var resource_id := _resource_catalog.id_for_code(resource_code)
	for rule in _veins:
		if StringName(rule["resource_id"]) == resource_id:
			return float(rule["cluster_chance"])
	return 0.0


func chest_loot(chest_key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_weight := 0.0
	for rule in _chest_loot:
		total_weight += float(rule["weight"])
	for draw in 2:
		var stable_hash := WorldSeed.from_text("%s|cave-chest-loot|%d" % [chest_key, draw])
		var cursor := (float(stable_hash & 0xffffff) / 16777216.0) * total_weight
		var selected: Dictionary = _chest_loot[-1]
		for rule in _chest_loot:
			cursor -= float(rule["weight"])
			if cursor < 0.0:
				selected = rule
				break
		var minimum := int(selected["minimum"])
		var maximum := int(selected["maximum"])
		var quantity := minimum + posmod(int(stable_hash >> 24), maximum - minimum + 1)
		var item_id := StringName(selected["item_id"])
		var merged := false
		for entry in result:
			if entry["item_id"] == item_id:
				entry["quantity"] = int(entry["quantity"]) + quantity
				merged = true
				break
		if not merged:
			result.append({"item_id": item_id, "quantity": quantity})
	return result


func _load_config(config_path: String) -> void:
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		_fail("无法打开洞穴配置 %s：%s" % [config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("洞穴配置必须是 JSON 对象")
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("洞穴配置版本无效")
		return
	_generation = (root.get("generation", {}) as Dictionary).duplicate(true)
	_features = (root.get("features", {}) as Dictionary).duplicate(true)
	var wall_chance := float(generation_value("initial_wall_chance", 0.0))
	var smoothing := int(generation_value("smoothing_steps", 0))
	var floor_ratio := float(generation_value("minimum_floor_ratio", 0.0))
	if wall_chance <= 0.2 or wall_chance >= 0.8 or smoothing < 1 or smoothing > 8 \
			or floor_ratio <= 0.2 or floor_ratio >= 0.8 or entrance_region_chunks() < 2:
		_fail("洞穴生成参数超出安全范围")
		return
	if not _resource_catalog.is_valid() or not _item_catalog.is_valid():
		_fail("洞穴依赖的资源或物品目录无效")
		return
	for value in root.get("veins", []) as Array:
		if not value is Dictionary:
			_fail("矿脉规则必须是对象")
			return
		var rule := (value as Dictionary).duplicate(true)
		var resource_id := StringName(rule.get("resource_id", ""))
		if not _resource_catalog.has_resource(resource_id) or not String(resource_id).ends_with("_vein") \
				or float(rule.get("weight", 0.0)) <= 0.0 \
				or float(rule.get("cluster_chance", 0.0)) <= 0.0 \
				or float(rule.get("cluster_chance", 0.0)) > 1.0:
			_fail("矿脉规则无效：%s" % resource_id)
			return
		_veins.append(rule)
	for value in root.get("chest_loot", []) as Array:
		if not value is Dictionary:
			_fail("地下宝箱掉落规则必须是对象")
			return
		var rule := (value as Dictionary).duplicate(true)
		var item_id := StringName(rule.get("item_id", ""))
		if not _item_catalog.has_item(item_id) or int(rule.get("minimum", 0)) < 1 \
				or int(rule.get("maximum", 0)) < int(rule.get("minimum", 0)) \
				or float(rule.get("weight", 0.0)) <= 0.0:
			_fail("地下宝箱掉落规则无效：%s" % item_id)
			return
		_chest_loot.append(rule)
	if _veins.is_empty() or _chest_loot.is_empty() \
			or int(feature_value("torch_spacing_tiles", 0)) < 6 \
			or float(feature_value("chest_chunk_chance", 0.0)) <= 0.0:
		_fail("洞穴内容配置不能为空")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
