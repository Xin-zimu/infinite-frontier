class_name HusbandryState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _world_seed := 0
var _catalog: HusbandryCatalog
var _item_catalog: ItemCatalog
var _animals: Dictionary = {}
var _next_birth_id := 1


func _init(world_seed := 0, catalog := HusbandryCatalog.new(), item_catalog := ItemCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_item_catalog = item_catalog


func animal_count() -> int:
	return _animals.size()


func tamed_count() -> int:
	var total := 0
	for value in _animals.values():
		if bool((value as Dictionary).get("tamed", false)):
			total += 1
	return total


func sleeping_count() -> int:
	var total := 0
	for value in _animals.values():
		if bool((value as Dictionary).get("sleeping", false)):
			total += 1
	return total


func ready_product_count() -> int:
	var total := 0
	for value in _animals.values():
		total += int((value as Dictionary).get("product_ready", 0))
	return total


func animal_by_id(animal_id: String) -> Dictionary:
	return ((_animals.get(animal_id, {}) as Dictionary).duplicate(true))


func animal_at(world_tile: Vector2i) -> Dictionary:
	for value in _animals.values():
		var record := value as Dictionary
		if _tile_from_record(record) == world_tile:
			return record.duplicate(true)
	return {}


func animals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _animals.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(_animal_less)
	return result


func animals_for_chunk(chunk_coordinate: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _animals.values():
		var record := value as Dictionary
		if WorldCoordinates.tile_to_chunk(_tile_from_record(record)) == chunk_coordinate:
			result.append(record.duplicate(true))
	result.sort_custom(_animal_less)
	return result


func feed_candidate(candidate: Dictionary, day: int, inventory: InventoryModel) -> Dictionary:
	var animal_id := String(candidate.get("animal_id", ""))
	var animal_type := StringName(candidate.get("animal_type", ""))
	var tile_value: Variant = candidate.get("world_tile", [])
	if animal_id.is_empty() or _catalog.animal(animal_type).is_empty() or not tile_value is Array \
			or (tile_value as Array).size() != 2 or String(candidate.get("sex", "")) not in ["female", "male"]:
		return _fail_result("野生动物记录无效")
	if _animals.has(animal_id):
		return feed(animal_id, day, inventory)
	if animal_count() >= _catalog.max_interacted_animals():
		return _fail_result("已互动动物数量达到上限")
	var normalized_day := maxi(1, day)
	var definition := _catalog.animal(animal_type)
	var adult_days := int(definition["adult_days"])
	var record := {
		"animal_id": animal_id,
		"animal_type": String(animal_type),
		"world_tile": [int((tile_value as Array)[0]), int((tile_value as Array)[1])],
		"sex": String(candidate["sex"]),
		"tamed": false,
		"friendship": 0,
		"birth_day": maxi(1, normalized_day - adult_days),
		"adult_day": normalized_day,
		"last_simulated_day": normalized_day,
		"last_fed_day": -1,
		"fed_until_day": -1,
		"last_product_day": normalized_day,
		"product_ready": 0,
		"breeding_cooldown_until": 0,
		"sleeping": false,
		"generation": 0,
	}
	_animals[animal_id] = record
	var result := feed(animal_id, normalized_day, inventory)
	if not bool(result.get("ok", false)):
		_animals.erase(animal_id)
	return result


func feed(animal_id: String, day: int, inventory: InventoryModel) -> Dictionary:
	var record := animal_by_id(animal_id)
	if record.is_empty():
		return _fail_result("没有找到该动物")
	var normalized_day := maxi(1, day)
	if int(record.get("last_fed_day", -1)) == normalized_day:
		return _fail_result("今天已经喂过这只动物")
	var animal_type := StringName(record["animal_type"])
	var definition := _catalog.animal(animal_type)
	var feed_id := StringName(definition["feed_item_id"])
	if inventory.quantity(feed_id) < 1:
		return _fail_result("缺少%s" % _item_catalog.display_name(feed_id))
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()) or not simulation.remove_item(feed_id, 1):
		return _fail_result("喂食事务失败")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交喂食事务")
	var was_tamed := bool(record.get("tamed", false))
	record["friendship"] = mini(100, int(record.get("friendship", 0)) + 1)
	record["tamed"] = was_tamed or int(record["friendship"]) >= int(definition["tame_feed_count"])
	record["last_fed_day"] = normalized_day
	record["fed_until_day"] = maxi(int(record.get("fed_until_day", -1)), normalized_day + _catalog.feed_reserve_days())
	record["last_simulated_day"] = maxi(int(record.get("last_simulated_day", normalized_day)), normalized_day)
	_animals[animal_id] = record
	last_error = ""
	var message := "%s已驯服" % definition["display_name"] if not was_tamed and bool(record["tamed"]) \
			else "已喂食%s · 亲密 %d" % [definition["display_name"], int(record["friendship"])]
	return {"ok": true, "message": message, "animal": record.duplicate(true), "tamed_now": not was_tamed and bool(record["tamed"])}


func advance_to_day(day: int) -> Dictionary:
	var target_day := maxi(1, day)
	var changed_chunks := {}
	var produced := 0
	for key_value in _animals.keys():
		var animal_id := String(key_value)
		var record := (_animals[animal_id] as Dictionary).duplicate(true)
		var previous_day := int(record.get("last_simulated_day", target_day))
		if target_day <= previous_day:
			continue
		var definition := _catalog.animal(StringName(record["animal_type"]))
		var interval := int(definition["product_interval_days"])
		var quantity := int(definition["product_quantity"])
		for simulated_day in range(previous_day + 1, target_day + 1):
			if not bool(record.get("tamed", false)) or simulated_day < int(record.get("adult_day", simulated_day)) \
					or simulated_day > int(record.get("fed_until_day", -1)):
				continue
			if simulated_day - int(record.get("last_product_day", previous_day)) < interval:
				continue
			var before := int(record.get("product_ready", 0))
			record["product_ready"] = mini(_catalog.max_ready_products(), before + quantity)
			record["last_product_day"] = simulated_day
			produced += int(record["product_ready"]) - before
		record["last_simulated_day"] = target_day
		_animals[animal_id] = record
		changed_chunks[WorldCoordinates.tile_to_chunk(_tile_from_record(record))] = true
	return {"changed": not changed_chunks.is_empty(), "changed_chunks": changed_chunks.keys(), "produced": produced}


func set_sleep_phase(phase: StringName) -> Dictionary:
	var should_sleep := _catalog.is_sleep_phase(phase)
	var changed_chunks := {}
	for key_value in _animals.keys():
		var animal_id := String(key_value)
		var record := (_animals[animal_id] as Dictionary).duplicate(true)
		var next_sleeping := should_sleep and bool(record.get("tamed", false))
		if bool(record.get("sleeping", false)) == next_sleeping:
			continue
		record["sleeping"] = next_sleeping
		_animals[animal_id] = record
		changed_chunks[WorldCoordinates.tile_to_chunk(_tile_from_record(record))] = true
	return {"changed": not changed_chunks.is_empty(), "changed_chunks": changed_chunks.keys()}


func collect_product(animal_id: String, inventory: InventoryModel) -> Dictionary:
	var record := animal_by_id(animal_id)
	var quantity := int(record.get("product_ready", 0))
	if record.is_empty() or not bool(record.get("tamed", false)) or quantity <= 0:
		return _fail_result("这只动物暂无可收取产出")
	var definition := _catalog.animal(StringName(record["animal_type"]))
	var product_id := StringName(definition["product_item_id"])
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()):
		return _fail_result("无法创建收取事务")
	var add_result := simulation.add_item(product_id, quantity)
	if int(add_result["remainder"]) > 0:
		return _fail_result("背包空间不足，产出仍保留")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交收取事务")
	record["product_ready"] = 0
	_animals[animal_id] = record
	last_error = ""
	return {
		"ok": true,
		"message": "收取%s ×%d" % [_item_catalog.display_name(product_id), quantity],
		"animal": record.duplicate(true),
		"item_id": String(product_id),
		"quantity": quantity,
	}


func compatible_partner(animal_id: String) -> Dictionary:
	var source := animal_by_id(animal_id)
	if source.is_empty():
		return {}
	var best: Dictionary = {}
	var best_distance := _catalog.breeding_range_tiles() + 1
	for value in _animals.values():
		var candidate := value as Dictionary
		if String(candidate["animal_id"]) == animal_id or String(candidate["animal_type"]) != String(source["animal_type"]) \
				or String(candidate["sex"]) == String(source["sex"]) or not bool(candidate.get("tamed", false)):
			continue
		var distance := _chebyshev_distance(_tile_from_record(source), _tile_from_record(candidate))
		if distance > _catalog.breeding_range_tiles() or distance >= best_distance:
			continue
		best_distance = distance
		best = candidate.duplicate(true)
	return best


func breed(first_id: String, second_id: String, offspring_tile: Vector2i, day: int, fenced: bool) -> Dictionary:
	var first := animal_by_id(first_id)
	var second := animal_by_id(second_id)
	var normalized_day := maxi(1, day)
	if first.is_empty() or second.is_empty() or first_id == second_id:
		return _fail_result("需要两只不同动物")
	if String(first["animal_type"]) != String(second["animal_type"]) or String(first["sex"]) == String(second["sex"]):
		return _fail_result("繁殖需要同种异性动物")
	if not bool(first.get("tamed", false)) or not bool(second.get("tamed", false)):
		return _fail_result("只有已驯服动物可以繁殖")
	if not fenced:
		return _fail_result("繁殖需要两只动物都在围栏附近")
	if _chebyshev_distance(_tile_from_record(first), _tile_from_record(second)) > _catalog.breeding_range_tiles():
		return _fail_result("两只动物距离过远")
	var definition := _catalog.animal(StringName(first["animal_type"]))
	var friendship_required := int(definition["breed_friendship"])
	if int(first.get("friendship", 0)) < friendship_required or int(second.get("friendship", 0)) < friendship_required:
		return _fail_result("动物亲密度不足")
	if normalized_day < int(first.get("adult_day", normalized_day)) or normalized_day < int(second.get("adult_day", normalized_day)):
		return _fail_result("幼年动物不能繁殖")
	if normalized_day < int(first.get("breeding_cooldown_until", 0)) or normalized_day < int(second.get("breeding_cooldown_until", 0)):
		return _fail_result("动物仍在繁殖冷却中")
	if not animal_at(offspring_tile).is_empty() or animal_count() >= _catalog.max_interacted_animals():
		return _fail_result("没有可用的幼崽位置")
	var child_id := "bred:%d:%d" % [normalized_day, _next_birth_id]
	_next_birth_id += 1
	var sex_roll := WorldSeed.from_text("husbandry-child|%d|%s" % [_world_seed, child_id])
	var child := {
		"animal_id": child_id,
		"animal_type": String(first["animal_type"]),
		"world_tile": [offspring_tile.x, offspring_tile.y],
		"sex": "female" if posmod(sex_roll, 2) == 0 else "male",
		"tamed": true,
		"friendship": 0,
		"birth_day": normalized_day,
		"adult_day": normalized_day + int(definition["adult_days"]),
		"last_simulated_day": normalized_day,
		"last_fed_day": -1,
		"fed_until_day": -1,
		"last_product_day": normalized_day,
		"product_ready": 0,
		"breeding_cooldown_until": 0,
		"sleeping": false,
		"generation": maxi(int(first.get("generation", 0)), int(second.get("generation", 0))) + 1,
	}
	var cooldown := normalized_day + int(definition["breeding_cooldown_days"])
	first["breeding_cooldown_until"] = cooldown
	second["breeding_cooldown_until"] = cooldown
	_animals[first_id] = first
	_animals[second_id] = second
	_animals[child_id] = child
	last_error = ""
	return {"ok": true, "message": "%s幼崽出生" % definition["display_name"], "animal": child.duplicate(true), "parents": [first_id, second_id]}


func status_snapshot(inventory: InventoryModel = null) -> Dictionary:
	var views: Array[Dictionary] = []
	for definition in _catalog.animals():
		var feed_id := StringName(definition["feed_item_id"])
		views.append({
			"animal_type": String(definition["id"]),
			"display_name": String(definition["display_name"]),
			"feed_item_id": String(feed_id),
			"feed_display_name": _item_catalog.display_name(feed_id),
			"feed_quantity": inventory.quantity(feed_id) if inventory != null else 0,
			"product_item_id": String(definition["product_item_id"]),
			"product_display_name": _item_catalog.display_name(StringName(definition["product_item_id"])),
			"color": String(definition["color"]),
		})
	return {
		"schema_version": SCHEMA_VERSION,
		"animal_count": animal_count(),
		"animal_limit": _catalog.max_interacted_animals(),
		"tamed_count": tamed_count(),
		"sleeping_count": sleeping_count(),
		"ready_products": ready_product_count(),
		"animals": views,
	}


func persistence_snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "next_birth_id": _next_birth_id, "animals": animals()}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_animals.clear()
		_next_birth_id = 1
		last_error = ""
		return true
	if not _catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION \
			or not value.get("animals", []) is Array or int(value.get("next_birth_id", 0)) < 1:
		return _restore_fail("养殖状态格式无效")
	var animal_values := value["animals"] as Array
	if animal_values.size() > _catalog.max_interacted_animals():
		return _restore_fail("动物数量超过上限")
	var restored := {}
	var occupied := {}
	for animal_value in animal_values:
		if not animal_value is Dictionary:
			return _restore_fail("动物记录必须是对象")
		var record := (animal_value as Dictionary).duplicate(true)
		var animal_id := String(record.get("animal_id", ""))
		var animal_type := StringName(record.get("animal_type", ""))
		var tile_value: Variant = record.get("world_tile", [])
		if animal_id.is_empty() or restored.has(animal_id) or _catalog.animal(animal_type).is_empty() \
				or not tile_value is Array or (tile_value as Array).size() != 2 \
				or not _is_integer_value((tile_value as Array)[0]) or not _is_integer_value((tile_value as Array)[1]):
			return _restore_fail("动物身份或坐标无效")
		var world_tile := Vector2i(int((tile_value as Array)[0]), int((tile_value as Array)[1]))
		var tile_key := "%d:%d" % [world_tile.x, world_tile.y]
		if occupied.has(tile_key):
			return _restore_fail("多只动物占用同一格")
		var sex := String(record.get("sex", ""))
		var friendship := int(record.get("friendship", -1))
		var birth_day := int(record.get("birth_day", 0))
		var adult_day := int(record.get("adult_day", 0))
		var last_day := int(record.get("last_simulated_day", 0))
		var last_fed := int(record.get("last_fed_day", -1))
		var fed_until := int(record.get("fed_until_day", -1))
		var last_product := int(record.get("last_product_day", 0))
		var product_ready := int(record.get("product_ready", -1))
		var cooldown := int(record.get("breeding_cooldown_until", -1))
		var generation := int(record.get("generation", -1))
		if sex not in ["female", "male"] or friendship < 0 or friendship > 100 \
				or birth_day < 1 or adult_day < birth_day or last_day < birth_day \
				or last_fed < -1 or last_fed > last_day or fed_until < last_fed \
				or last_product < birth_day or last_product > last_day or product_ready < 0 \
				or product_ready > _catalog.max_ready_products() or cooldown < 0 or generation < 0:
			return _restore_fail("动物日期或进度无效")
		if animal_id.begins_with("wild:") and bool(record.get("tamed", false)) \
				!= (friendship >= int(_catalog.animal(animal_type)["tame_feed_count"])):
			return _restore_fail("野生动物驯服状态无效")
		if animal_id.begins_with("bred:") and not bool(record.get("tamed", false)):
			return _restore_fail("繁殖幼崽必须保持驯服")
		record["animal_id"] = animal_id
		record["animal_type"] = String(animal_type)
		record["world_tile"] = [world_tile.x, world_tile.y]
		record["sex"] = sex
		record["tamed"] = bool(record.get("tamed", false))
		record["friendship"] = friendship
		record["birth_day"] = birth_day
		record["adult_day"] = adult_day
		record["last_simulated_day"] = last_day
		record["last_fed_day"] = last_fed
		record["fed_until_day"] = fed_until
		record["last_product_day"] = last_product
		record["product_ready"] = product_ready
		record["breeding_cooldown_until"] = cooldown
		record["sleeping"] = bool(record.get("sleeping", false))
		record["generation"] = generation
		restored[animal_id] = record
		occupied[tile_key] = true
	_animals = restored
	var derived_next_birth_id := 1
	for animal_id_value in restored.keys():
		var animal_id := String(animal_id_value)
		var parts := animal_id.split(":")
		if parts.size() == 3 and parts[0] == "bred" and parts[2].is_valid_int():
			derived_next_birth_id = maxi(derived_next_birth_id, int(parts[2]) + 1)
	_next_birth_id = maxi(int(value["next_birth_id"]), derived_next_birth_id)
	last_error = ""
	return true


func _tile_from_record(record: Dictionary) -> Vector2i:
	var value := record.get("world_tile", [0, 0]) as Array
	return Vector2i(int(value[0]), int(value[1]))


func _animal_less(a: Dictionary, b: Dictionary) -> bool:
	var tile_a := _tile_from_record(a)
	var tile_b := _tile_from_record(b)
	return tile_a.y < tile_b.y or (tile_a.y == tile_b.y and tile_a.x < tile_b.x) \
			or (tile_a == tile_b and String(a["animal_id"]) < String(b["animal_id"]))


func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _fail_result(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}


func _restore_fail(message: String) -> bool:
	last_error = message
	return false


func _is_integer_value(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(float(value), floorf(float(value))))
