class_name EquipmentCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/equipment.json"
const REQUIRED_SLOT_IDS := [&"weapon", &"helmet", &"chest", &"boots", &"accessory_1", &"accessory_2"]
const REQUIRED_ITEM_IDS := [&"wood_sword", &"stone_sword", &"copper_sword", &"iron_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots", &"explorer_charm", &"frost_ring"]
const VALID_STATS := [&"attack", &"defense", &"health", &"stamina", &"durability"]

var _valid := false
var _error_message := ""
var _slots: Array[Dictionary] = []
var _slot_by_id: Dictionary = {}
var _qualities: Array[Dictionary] = []
var _quality_by_id: Dictionary = {}
var _rarities: Array[Dictionary] = []
var _rarity_by_id: Dictionary = {}
var _affixes: Array[Dictionary] = []
var _affix_by_id: Dictionary = {}
var _items: Array[Dictionary] = []
var _item_by_id: Dictionary = {}
var _sets: Dictionary = {}
var _enhancement: Dictionary = {}
var _repair: Dictionary = {}


func _init(path := DEFAULT_CONFIG_PATH, item_catalog: ItemCatalog = null) -> void:
	_load(path, item_catalog if item_catalog != null else ItemCatalog.new())


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func slot_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _slots:
		result.append(StringName(definition["id"]))
	return result


func slot_display_name(slot_id: StringName) -> String:
	return String((_slot_by_id.get(String(slot_id), {}) as Dictionary).get("display_name", slot_id))


func quality_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _qualities:
		result.append(StringName(definition["id"]))
	return result


func rarity_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _rarities:
		result.append(StringName(definition["id"]))
	return result


func affix_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _affixes:
		result.append(StringName(definition["id"]))
	return result


func equipment_item_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _items:
		result.append(StringName(definition["item_id"]))
	return result


func has_item(item_id: StringName) -> bool:
	return _item_by_id.has(String(item_id))


func item(item_id: StringName) -> Dictionary:
	return (_item_by_id.get(String(item_id), {}) as Dictionary).duplicate(true)


func quality(quality_id: StringName) -> Dictionary:
	return (_quality_by_id.get(String(quality_id), {}) as Dictionary).duplicate(true)


func rarity(rarity_id: StringName) -> Dictionary:
	return (_rarity_by_id.get(String(rarity_id), {}) as Dictionary).duplicate(true)


func affix(affix_id: StringName) -> Dictionary:
	return (_affix_by_id.get(String(affix_id), {}) as Dictionary).duplicate(true)


func set_definition(set_id: StringName) -> Dictionary:
	return (_sets.get(String(set_id), {}) as Dictionary).duplicate(true)


func maximum_enhancement() -> int:
	return int(_enhancement.get("maximum_level", 0))


func enhancement_material_id() -> StringName:
	return StringName(_enhancement.get("material_item_id", ""))


func enhancement_cost(next_level: int) -> int:
	var costs := _enhancement.get("costs", []) as Array
	return int(costs[next_level - 1]) if next_level >= 1 and next_level <= costs.size() else 0


func enhancement_stat_per_level() -> float:
	return float(_enhancement.get("stat_per_level", 0.0))


func repair_material_id() -> StringName:
	return StringName(_repair.get("material_item_id", ""))


func repair_durability_per_item() -> int:
	return int(_repair.get("durability_per_item", 0))


func roll_weighted(definitions: Array[Dictionary], roll: int) -> StringName:
	var total := 0
	for definition in definitions:
		total += int(definition.get("weight", 0))
	if total <= 0:
		return &""
	var cursor := posmod(roll, total)
	for definition in definitions:
		cursor -= int(definition.get("weight", 0))
		if cursor < 0:
			return StringName(definition["id"])
	return StringName(definitions.back()["id"])


func roll_quality(roll: int) -> StringName:
	return roll_weighted(_qualities, roll)


func roll_rarity(roll: int) -> StringName:
	return roll_weighted(_rarities, roll)


func _load(path: String, item_catalog: ItemCatalog) -> void:
	if not item_catalog.is_valid():
		_fail("Item catalog is invalid: %s" % item_catalog.error_message())
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open equipment configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int((parsed as Dictionary).get("schema_version", 0)) != 1:
		_fail("Equipment configuration must use schema version 1")
		return
	var root := parsed as Dictionary
	if not _load_named(root.get("slots", []) as Array, _slots, _slot_by_id, false):
		return
	if not _load_named(root.get("qualities", []) as Array, _qualities, _quality_by_id, true):
		return
	if not _load_named(root.get("rarities", []) as Array, _rarities, _rarity_by_id, true):
		return
	if not _load_named(root.get("affixes", []) as Array, _affixes, _affix_by_id, false):
		return
	for affix_definition in _affixes:
		if StringName(affix_definition.get("stat", "")) not in VALID_STATS or float(affix_definition.get("value", 0.0)) <= 0.0:
			_fail("Equipment affix has an invalid stat or value")
			return
	_enhancement = (root.get("enhancement", {}) as Dictionary).duplicate(true)
	_repair = (root.get("repair", {}) as Dictionary).duplicate(true)
	var maximum_level := maximum_enhancement()
	var costs := _enhancement.get("costs", []) as Array
	if maximum_level < 1 or costs.size() != maximum_level or enhancement_stat_per_level() <= 0.0 \
			or not item_catalog.has_item(enhancement_material_id()):
		_fail("Equipment enhancement configuration is invalid")
		return
	for cost in costs:
		if int(cost) < 1:
			_fail("Equipment enhancement costs must be positive")
			return
	if repair_durability_per_item() < 1 or not item_catalog.has_item(repair_material_id()):
		_fail("Equipment repair configuration is invalid")
		return
	for set_value in root.get("sets", []) as Array:
		if not set_value is Dictionary:
			_fail("Equipment set entry is not an object")
			return
		var set_definition := (set_value as Dictionary).duplicate(true)
		var set_id := String(set_definition.get("id", ""))
		if set_id.is_empty() or _sets.has(set_id):
			_fail("Equipment set IDs must be unique")
			return
		for bonus_value in set_definition.get("bonuses", []) as Array:
			var bonus := bonus_value as Dictionary
			if int(bonus.get("pieces", 0)) < 2 or StringName(bonus.get("stat", "")) not in VALID_STATS or float(bonus.get("value", 0.0)) <= 0.0:
				_fail("Equipment set bonus is invalid")
				return
		_sets[set_id] = set_definition
	for value in root.get("items", []) as Array:
		if not value is Dictionary:
			_fail("Equipment item entry is not an object")
			return
		var definition := (value as Dictionary).duplicate(true)
		var item_id := String(definition.get("item_id", ""))
		var slot_kind := String(definition.get("slot_kind", ""))
		var set_id := String(definition.get("set_id", ""))
		if item_id.is_empty() or _item_by_id.has(item_id) or not item_catalog.has_item(StringName(item_id)) \
				or not item_catalog.is_durable(StringName(item_id)):
			_fail("Equipment item ID must reference one unique durable inventory item")
			return
		if slot_kind != "accessory" and not _slot_by_id.has(slot_kind):
			_fail("Equipment item '%s' has an invalid slot" % item_id)
			return
		if not set_id.is_empty() and not _sets.has(set_id):
			_fail("Equipment item '%s' references an unknown set" % item_id)
			return
		for stat_key in ["base_attack", "base_defense", "base_health", "base_stamina"]:
			if float(definition.get(stat_key, -1.0)) < 0.0:
				_fail("Equipment item '%s' has an invalid base stat" % item_id)
				return
		_items.append(definition)
		_item_by_id[item_id] = definition
	for slot_id in REQUIRED_SLOT_IDS:
		if not _slot_by_id.has(String(slot_id)):
			_fail("Missing required equipment slot '%s'" % slot_id)
			return
	for item_id in REQUIRED_ITEM_IDS:
		if not _item_by_id.has(String(item_id)):
			_fail("Missing required equipment item '%s'" % item_id)
			return
	_valid = true


func _load_named(values: Array, destination: Array[Dictionary], index: Dictionary, weighted: bool) -> bool:
	for value in values:
		if not value is Dictionary:
			_fail("Named equipment entry is not an object")
			return false
		var definition := (value as Dictionary).duplicate(true)
		var key := String(definition.get("id", ""))
		if key.is_empty() or String(definition.get("display_name", "")).is_empty() or index.has(key):
			_fail("Named equipment IDs must be unique and named")
			return false
		if weighted and (int(definition.get("weight", 0)) < 1 or float(definition.get("multiplier", 0.0)) <= 0.0):
			_fail("Weighted equipment entry is invalid")
			return false
		destination.append(definition)
		index[key] = definition
	return not destination.is_empty()


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
