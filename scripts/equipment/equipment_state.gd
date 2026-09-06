class_name EquipmentState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _catalog: EquipmentCatalog
var _item_catalog: ItemCatalog
var _next_instance_id := 1
var _records: Dictionary = {}
var _equipped: Dictionary = {}


func _init(catalog: EquipmentCatalog = null, item_catalog: ItemCatalog = null) -> void:
	_item_catalog = item_catalog if item_catalog != null else ItemCatalog.new()
	_catalog = catalog if catalog != null else EquipmentCatalog.new(EquipmentCatalog.DEFAULT_CONFIG_PATH, _item_catalog)


func catalog() -> EquipmentCatalog:
	return _catalog


func records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids := _records.keys()
	ids.sort()
	for instance_id in ids:
		result.append((_records[instance_id] as Dictionary).duplicate(true))
	return result


func record(instance_id: int) -> Dictionary:
	return (_records.get(instance_id, {}) as Dictionary).duplicate(true)


func equipped_record(slot_id: StringName) -> Dictionary:
	return record(int(_equipped.get(String(slot_id), 0)))


func equipped_weapon_item_id() -> StringName:
	var weapon := equipped_record(&"weapon")
	return StringName(weapon.get("item_id", "")) if int(weapon.get("durability", 0)) > 0 else &""


func import_inventory_slot(inventory: InventoryModel, slot_index: int, roll_seed: int) -> Dictionary:
	var stack := inventory.slot(slot_index)
	if stack.is_empty():
		return _fail("该背包格没有可登记装备")
	var item_id := StringName(stack.get("item_id", ""))
	if not _catalog.has_item(item_id):
		return _fail("该物品不是可装备物品")
	var removed := inventory.discard(slot_index, 1)
	if removed.is_empty():
		return _fail("装备登记失败")
	var instance_id := _next_instance_id
	_next_instance_id += 1
	var quality_id := _catalog.roll_quality(int(WorldSeed.from_text("quality|%d|%d|%s" % [roll_seed, instance_id, item_id])))
	var rarity_id := _catalog.roll_rarity(int(WorldSeed.from_text("rarity|%d|%d|%s" % [roll_seed, instance_id, item_id])))
	var rarity := _catalog.rarity(rarity_id)
	var affixes: Array[String] = []
	var candidates := _catalog.affix_ids()
	var offset := posmod(int(WorldSeed.from_text("affix|%d|%d|%s" % [roll_seed, instance_id, item_id])), candidates.size())
	for index in mini(int(rarity.get("affix_count", 0)), candidates.size()):
		affixes.append(String(candidates[(offset + index) % candidates.size()]))
	var new_record := {
		"instance_id": instance_id,
		"item_id": String(item_id),
		"quality_id": String(quality_id),
		"rarity_id": String(rarity_id),
		"durability": int(removed.get("durability", _item_catalog.maximum_durability(item_id))),
		"enhance_level": 0,
		"affixes": affixes,
	}
	_records[instance_id] = new_record
	var slot_id := _first_slot_for_item(item_id)
	if not slot_id.is_empty() and not _equipped.has(String(slot_id)):
		_equipped[String(slot_id)] = instance_id
	last_error = ""
	return {"ok": true, "message": "已登记%s" % _item_catalog.display_name(item_id), "record": new_record.duplicate(true), "slot_id": String(slot_id)}


func equip(instance_id: int, preferred_slot: StringName = &"") -> Dictionary:
	var equipment := record(instance_id)
	if equipment.is_empty():
		return _fail("装备实例不存在")
	var item_id := StringName(equipment["item_id"])
	var definition := _catalog.item(item_id)
	var slot_kind := StringName(definition.get("slot_kind", ""))
	var target_slot := preferred_slot
	if slot_kind == &"accessory":
		if target_slot not in [&"accessory_1", &"accessory_2"]:
			target_slot = &"accessory_1" if not _equipped.has("accessory_1") else &"accessory_2"
	elif target_slot.is_empty():
		target_slot = slot_kind
	if target_slot.is_empty() or (slot_kind != &"accessory" and target_slot != slot_kind):
		return _fail("装备槽位不匹配")
	for slot_key in _equipped.keys():
		if int(_equipped[slot_key]) == instance_id:
			_equipped.erase(slot_key)
	_equipped[String(target_slot)] = instance_id
	last_error = ""
	return {"ok": true, "message": "已装备%s" % _item_catalog.display_name(item_id), "slot_id": String(target_slot)}


func unequip(slot_id: StringName) -> Dictionary:
	if not _equipped.has(String(slot_id)):
		return _fail("该槽位没有装备")
	_equipped.erase(String(slot_id))
	last_error = ""
	return {"ok": true, "message": "已卸下装备"}


func enhance(instance_id: int, inventory: InventoryModel) -> Dictionary:
	var equipment := record(instance_id)
	if equipment.is_empty():
		return _fail("装备实例不存在")
	var current_level := int(equipment.get("enhance_level", 0))
	if current_level >= _catalog.maximum_enhancement():
		return _fail("装备已达到强化上限")
	var next_level := current_level + 1
	var material_id := _catalog.enhancement_material_id()
	var cost := _catalog.enhancement_cost(next_level)
	if inventory.quantity(material_id) < cost:
		return _fail("强化需要%s ×%d" % [_item_catalog.display_name(material_id), cost])
	if not inventory.remove_item(material_id, cost):
		return _fail("强化材料扣除失败")
	equipment["enhance_level"] = next_level
	_records[instance_id] = equipment
	last_error = ""
	return {"ok": true, "message": "强化成功 · +%d" % next_level, "record": equipment.duplicate(true)}


func repair(instance_id: int, inventory: InventoryModel) -> Dictionary:
	var equipment := record(instance_id)
	if equipment.is_empty():
		return _fail("装备实例不存在")
	var item_id := StringName(equipment["item_id"])
	var maximum := maximum_durability(equipment)
	var missing := maximum - int(equipment.get("durability", 0))
	if missing <= 0:
		return _fail("装备耐久已满")
	var material_id := _catalog.repair_material_id()
	var cost := ceili(float(missing) / float(_catalog.repair_durability_per_item()))
	if inventory.quantity(material_id) < cost:
		return _fail("修理需要%s ×%d" % [_item_catalog.display_name(material_id), cost])
	if not inventory.remove_item(material_id, cost):
		return _fail("修理材料扣除失败")
	equipment["durability"] = maximum
	_records[instance_id] = equipment
	last_error = ""
	return {"ok": true, "message": "%s已修复" % _item_catalog.display_name(item_id), "record": equipment.duplicate(true)}


func damage_equipped_weapon(amount := 1) -> Dictionary:
	var instance_id := int(_equipped.get("weapon", 0))
	var equipment := record(instance_id)
	if equipment.is_empty() or amount <= 0:
		return {"accepted": false, "broken": false}
	var remaining := maxi(0, int(equipment.get("durability", 0)) - amount)
	equipment["durability"] = remaining
	_records[instance_id] = equipment
	return {"accepted": true, "broken": remaining == 0, "remaining": remaining, "item_id": equipment["item_id"], "instance_id": instance_id}


func maximum_durability(equipment: Dictionary) -> int:
	var item_id := StringName(equipment.get("item_id", ""))
	var base := _item_catalog.maximum_durability(item_id)
	var extra := 0
	for affix_id_value in equipment.get("affixes", []) as Array:
		var affix := _catalog.affix(StringName(affix_id_value))
		if StringName(affix.get("stat", "")) == &"durability":
			extra += roundi(float(affix.get("value", 0.0)))
	return base + extra


func stats_snapshot() -> Dictionary:
	var stats := {"attack": 0.0, "defense": 0.0, "health": 0.0, "stamina": 0.0}
	var set_counts: Dictionary = {}
	for slot_id in _catalog.slot_ids():
		var equipment := equipped_record(slot_id)
		if equipment.is_empty() or int(equipment.get("durability", 0)) <= 0:
			continue
		var definition := _catalog.item(StringName(equipment["item_id"]))
		var multiplier := float(_catalog.quality(StringName(equipment["quality_id"])).get("multiplier", 1.0)) \
				* float(_catalog.rarity(StringName(equipment["rarity_id"])).get("multiplier", 1.0)) \
				* (1.0 + float(equipment.get("enhance_level", 0)) * _catalog.enhancement_stat_per_level())
		for stat_id in [&"attack", &"defense", &"health", &"stamina"]:
			stats[String(stat_id)] = float(stats[String(stat_id)]) + float(definition.get("base_%s" % stat_id, 0.0)) * multiplier
		for affix_id_value in equipment.get("affixes", []) as Array:
			var affix := _catalog.affix(StringName(affix_id_value))
			var stat := StringName(affix.get("stat", ""))
			if stats.has(String(stat)):
				stats[String(stat)] = float(stats[String(stat)]) + float(affix.get("value", 0.0))
		var set_id := String(definition.get("set_id", ""))
		if not set_id.is_empty():
			set_counts[set_id] = int(set_counts.get(set_id, 0)) + 1
	var active_sets: Array[Dictionary] = []
	for set_id in set_counts.keys():
		var set_definition := _catalog.set_definition(StringName(set_id))
		var pieces := int(set_counts[set_id])
		var active_bonus_count := 0
		for bonus_value in set_definition.get("bonuses", []) as Array:
			var bonus := bonus_value as Dictionary
			if pieces < int(bonus.get("pieces", 0)):
				continue
			var stat := String(bonus.get("stat", ""))
			if stats.has(stat):
				stats[stat] = float(stats[stat]) + float(bonus.get("value", 0.0))
				active_bonus_count += 1
		active_sets.append({"set_id": String(set_id), "display_name": set_definition.get("display_name", set_id), "pieces": pieces, "active_bonuses": active_bonus_count})
	stats["attack"] = snappedf(float(stats["attack"]), 0.01)
	stats["defense"] = snappedf(float(stats["defense"]), 0.01)
	stats["health"] = snappedf(float(stats["health"]), 0.01)
	stats["stamina"] = snappedf(float(stats["stamina"]), 0.01)
	stats["sets"] = active_sets
	return stats


func comparison(instance_id: int) -> Dictionary:
	var candidate := record(instance_id)
	if candidate.is_empty():
		return {}
	var definition := _catalog.item(StringName(candidate["item_id"]))
	var slot_kind := StringName(definition.get("slot_kind", ""))
	var slot_id := slot_kind
	if slot_kind == &"accessory":
		slot_id = &"accessory_1"
	var equipped := equipped_record(slot_id)
	return {
		"candidate": _record_view(candidate),
		"equipped": _record_view(equipped),
		"attack_delta": _single_record_stat(candidate, &"attack") - _single_record_stat(equipped, &"attack"),
		"defense_delta": _single_record_stat(candidate, &"defense") - _single_record_stat(equipped, &"defense"),
		"health_delta": _single_record_stat(candidate, &"health") - _single_record_stat(equipped, &"health"),
		"stamina_delta": _single_record_stat(candidate, &"stamina") - _single_record_stat(equipped, &"stamina"),
	}


func status_snapshot(inventory: InventoryModel) -> Dictionary:
	var slots: Array[Dictionary] = []
	for slot_id in _catalog.slot_ids():
		var equipment := equipped_record(slot_id)
		slots.append({
			"slot_id": String(slot_id),
			"display_name": _catalog.slot_display_name(slot_id),
			"record": _record_view(equipment),
		})
	var owned: Array[Dictionary] = []
	for equipment in records():
		owned.append(_record_view(equipment))
	var importable: Array[Dictionary] = []
	for index in inventory.slot_count():
		var stack := inventory.slot(index)
		var item_id := StringName(stack.get("item_id", ""))
		if not stack.is_empty() and _catalog.has_item(item_id):
			importable.append({"slot_index": index, "item_id": String(item_id), "display_name": _item_catalog.display_name(item_id), "durability": int(stack.get("durability", 0))})
	return {
		"schema_version": SCHEMA_VERSION,
		"slots": slots,
		"owned": owned,
		"importable": importable,
		"stats": stats_snapshot(),
		"enhancement_material": String(_catalog.enhancement_material_id()),
		"enhancement_material_quantity": inventory.quantity(_catalog.enhancement_material_id()),
		"repair_material": String(_catalog.repair_material_id()),
		"repair_material_quantity": inventory.quantity(_catalog.repair_material_id()),
	}


func persistence_snapshot() -> Dictionary:
	var equipped := {}
	for slot_id in _catalog.slot_ids():
		if _equipped.has(String(slot_id)):
			equipped[String(slot_id)] = int(_equipped[String(slot_id)])
	return {"schema_version": SCHEMA_VERSION, "next_instance_id": _next_instance_id, "records": records(), "equipped": equipped}


func restore_snapshot(value: Dictionary) -> bool:
	last_error = ""
	if value.is_empty():
		_next_instance_id = 1
		_records.clear()
		_equipped.clear()
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		last_error = "装备状态版本无效"
		return false
	var record_values: Variant = value.get("records", [])
	var equipped_values: Variant = value.get("equipped", {})
	if not record_values is Array or not equipped_values is Dictionary:
		last_error = "装备记录或槽位数据无效"
		return false
	var restored_records: Dictionary = {}
	var greatest_id := 0
	for record_value in record_values as Array:
		if not record_value is Dictionary:
			last_error = "装备记录不是对象"
			return false
		var equipment := (record_value as Dictionary).duplicate(true)
		var instance_id := int(equipment.get("instance_id", 0))
		var item_id := StringName(equipment.get("item_id", ""))
		var quality_id := StringName(equipment.get("quality_id", ""))
		var rarity_id := StringName(equipment.get("rarity_id", ""))
		var durability := int(equipment.get("durability", -1))
		var enhance_level := int(equipment.get("enhance_level", -1))
		var affix_values: Variant = equipment.get("affixes", [])
		if instance_id < 1 or restored_records.has(instance_id) or not _catalog.has_item(item_id) \
				or _catalog.quality(quality_id).is_empty() or _catalog.rarity(rarity_id).is_empty() \
				or enhance_level < 0 or enhance_level > _catalog.maximum_enhancement() or not affix_values is Array:
			last_error = "装备实例字段无效"
			return false
		var normalized_affixes: Array[String] = []
		for affix_id_value in affix_values as Array:
			var affix_id := StringName(affix_id_value)
			if _catalog.affix(affix_id).is_empty() or normalized_affixes.has(String(affix_id)):
				last_error = "装备词条无效或重复"
				return false
			normalized_affixes.append(String(affix_id))
		var normalized := {"instance_id": instance_id, "item_id": String(item_id), "quality_id": String(quality_id), "rarity_id": String(rarity_id), "durability": durability, "enhance_level": enhance_level, "affixes": normalized_affixes}
		if durability < 0 or durability > maximum_durability(normalized):
			last_error = "装备耐久无效"
			return false
		restored_records[instance_id] = normalized
		greatest_id = maxi(greatest_id, instance_id)
	var restored_equipped: Dictionary = {}
	var used_instances: Dictionary = {}
	for slot_key in (equipped_values as Dictionary).keys():
		var slot_id := StringName(slot_key)
		var instance_id := int((equipped_values as Dictionary)[slot_key])
		if slot_id not in _catalog.slot_ids() or not restored_records.has(instance_id) or used_instances.has(instance_id):
			last_error = "已装备槽位引用无效"
			return false
		var definition := _catalog.item(StringName((restored_records[instance_id] as Dictionary)["item_id"]))
		var slot_kind := StringName(definition.get("slot_kind", ""))
		if (slot_kind == &"accessory" and slot_id not in [&"accessory_1", &"accessory_2"]) or (slot_kind != &"accessory" and slot_kind != slot_id):
			last_error = "已装备实例与槽位不匹配"
			return false
		restored_equipped[String(slot_id)] = instance_id
		used_instances[instance_id] = true
	var next_id := int(value.get("next_instance_id", 0))
	if next_id <= greatest_id:
		last_error = "下一装备实例编号无效"
		return false
	_records = restored_records
	_equipped = restored_equipped
	_next_instance_id = next_id
	return true


func _first_slot_for_item(item_id: StringName) -> StringName:
	var slot_kind := StringName(_catalog.item(item_id).get("slot_kind", ""))
	if slot_kind != &"accessory":
		return slot_kind
	if not _equipped.has("accessory_1"):
		return &"accessory_1"
	if not _equipped.has("accessory_2"):
		return &"accessory_2"
	return &"accessory_1"


func _record_view(equipment: Dictionary) -> Dictionary:
	if equipment.is_empty():
		return {}
	var item_id := StringName(equipment["item_id"])
	var quality := _catalog.quality(StringName(equipment["quality_id"]))
	var rarity := _catalog.rarity(StringName(equipment["rarity_id"]))
	var affix_names: Array[String] = []
	for affix_id_value in equipment.get("affixes", []) as Array:
		affix_names.append(String(_catalog.affix(StringName(affix_id_value)).get("display_name", affix_id_value)))
	var result := equipment.duplicate(true)
	result["display_name"] = _item_catalog.display_name(item_id)
	result["quality_name"] = quality.get("display_name", equipment["quality_id"])
	result["rarity_name"] = rarity.get("display_name", equipment["rarity_id"])
	result["rarity_color"] = rarity.get("color", "ffffff")
	result["maximum_durability"] = maximum_durability(equipment)
	result["affix_names"] = affix_names
	return result


func _single_record_stat(equipment: Dictionary, stat_id: StringName) -> float:
	if equipment.is_empty() or int(equipment.get("durability", 0)) <= 0:
		return 0.0
	var definition := _catalog.item(StringName(equipment["item_id"]))
	var multiplier := float(_catalog.quality(StringName(equipment["quality_id"])).get("multiplier", 1.0)) \
			* float(_catalog.rarity(StringName(equipment["rarity_id"])).get("multiplier", 1.0)) \
			* (1.0 + int(equipment.get("enhance_level", 0)) * _catalog.enhancement_stat_per_level())
	var value := float(definition.get("base_%s" % stat_id, 0.0)) * multiplier
	for affix_id_value in equipment.get("affixes", []) as Array:
		var affix := _catalog.affix(StringName(affix_id_value))
		if StringName(affix.get("stat", "")) == stat_id:
			value += float(affix.get("value", 0.0))
	return snappedf(value, 0.01)


func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}
