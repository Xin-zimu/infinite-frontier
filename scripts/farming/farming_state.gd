class_name FarmingState
extends RefCounted

const SCHEMA_VERSION := 1
const QUALITY_NAMES := {"normal": "普通", "silver": "优质", "gold": "金质"}

var last_error := ""
var _world_seed := 0
var _catalog: FarmingCatalog
var _item_catalog: ItemCatalog
var _plots: Dictionary = {}


func _init(world_seed := 0, catalog := FarmingCatalog.new(), item_catalog := ItemCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_item_catalog = item_catalog


func plot_count() -> int:
	return _plots.size()


func mature_count() -> int:
	var result := 0
	for value in _plots.values():
		if bool((value as Dictionary).get("mature", false)):
			result += 1
	return result


func plot_at(world_tile: Vector2i) -> Dictionary:
	return ((_plots.get(_plot_id(world_tile), {}) as Dictionary).duplicate(true))


func plots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _plots.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(_plot_less)
	return result


func plots_for_chunk(chunk_coordinate: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _plots.values():
		var record := value as Dictionary
		if WorldCoordinates.tile_to_chunk(_tile_from_record(record)) == chunk_coordinate:
			result.append(record.duplicate(true))
	result.sort_custom(_plot_less)
	return result


func till(world_tile: Vector2i, day: int, context: Dictionary) -> Dictionary:
	var validation := validate_till(world_tile, context)
	if not bool(validation["valid"]):
		return _fail_result(String(validation["reason"]))
	var normalized_day := maxi(1, day)
	var record := {
		"plot_id": _plot_id(world_tile),
		"world_tile": [world_tile.x, world_tile.y],
		"tilled_day": normalized_day,
		"last_simulated_day": normalized_day,
		"watered_day": -1,
		"crop_id": "",
		"growth_points": 0.0,
		"care_days": 0,
		"stage": 0,
		"mature": false,
		"fertilizer_id": "",
		"harvest_count": 0,
	}
	_plots[String(record["plot_id"])] = record
	last_error = ""
	return {"ok": true, "message": "已开垦耕地", "plot": record.duplicate(true)}


func validate_till(world_tile: Vector2i, context: Dictionary) -> Dictionary:
	if StringName(context.get("world_layer", &"surface")) != &"surface":
		return _validation_failure("只能在地表开垦")
	var player_tile := context.get("player_tile", world_tile) as Vector2i
	if _chebyshev_distance(world_tile, player_tile) > _catalog.interaction_range_tiles():
		return _validation_failure("超出耕作距离")
	if bool(context.get("player_occupied", false)):
		return _validation_failure("不能开垦玩家所在格")
	if bool(context.get("in_water", false)):
		return _validation_failure("水面不能开垦")
	if bool(context.get("generated_overlay", false)):
		return _validation_failure("道路或生成建筑占用了该格")
	if bool(context.get("resource_occupied", false)):
		return _validation_failure("请先清理该格资源")
	if bool(context.get("building_occupied", false)):
		return _validation_failure("玩家建筑占用了该格")
	if bool(context.get("husbandry_occupied", false)):
		return _validation_failure("动物占用了该格")
	if not plot_at(world_tile).is_empty():
		return _validation_failure("该格已经是耕地")
	if plot_count() >= _catalog.max_plots():
		return _validation_failure("耕地数量已达到上限")
	return {"valid": true, "reason": "可以开垦"}


func plant(crop_id: StringName, world_tile: Vector2i, day: int, inventory: InventoryModel) -> Dictionary:
	var definition := _catalog.crop(crop_id)
	var record := plot_at(world_tile)
	if definition.is_empty():
		return _fail_result("未知作物")
	if record.is_empty():
		return _fail_result("请先开垦土地")
	if not String(record.get("crop_id", "")).is_empty():
		return _fail_result("该耕地已有作物")
	var seed_item_id := StringName(definition["seed_item_id"])
	if inventory.quantity(seed_item_id) < 1:
		return _fail_result("缺少%s" % _item_catalog.display_name(seed_item_id))
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()) or not simulation.remove_item(seed_item_id, 1):
		return _fail_result("播种事务失败")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交播种事务")
	var normalized_day := maxi(int(record.get("last_simulated_day", 1)), maxi(1, day))
	record["crop_id"] = String(crop_id)
	record["planted_day"] = normalized_day
	record["last_simulated_day"] = normalized_day
	record["watered_day"] = -1
	record["growth_points"] = 0.0
	record["care_days"] = 0
	record["stage"] = 0
	record["mature"] = false
	record["fertilizer_id"] = ""
	_plots[String(record["plot_id"])] = record
	last_error = ""
	return {"ok": true, "message": "已播种%s" % definition["display_name"], "plot": record.duplicate(true)}


func water(world_tile: Vector2i, day: int) -> Dictionary:
	var record := plot_at(world_tile)
	if record.is_empty():
		return _fail_result("该格不是耕地")
	var normalized_day := maxi(1, day)
	if int(record.get("watered_day", -1)) == normalized_day:
		return _fail_result("今天已经浇过水")
	record["watered_day"] = normalized_day
	_plots[String(record["plot_id"])] = record
	last_error = ""
	return {"ok": true, "message": "耕地已浇水", "plot": record.duplicate(true)}


func fertilize(world_tile: Vector2i, fertilizer_id: StringName, inventory: InventoryModel) -> Dictionary:
	var record := plot_at(world_tile)
	var definition := _catalog.fertilizer(fertilizer_id)
	if record.is_empty() or String(record.get("crop_id", "")).is_empty():
		return _fail_result("播种后才能施肥")
	if definition.is_empty():
		return _fail_result("未知肥料")
	if not String(record.get("fertilizer_id", "")).is_empty():
		return _fail_result("本轮作物已经施肥")
	if inventory.quantity(fertilizer_id) < 1:
		return _fail_result("缺少%s" % _item_catalog.display_name(fertilizer_id))
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()) or not simulation.remove_item(fertilizer_id, 1):
		return _fail_result("施肥事务失败")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交施肥事务")
	record["fertilizer_id"] = String(fertilizer_id)
	_plots[String(record["plot_id"])] = record
	last_error = ""
	return {"ok": true, "message": "已使用%s" % definition["display_name"], "plot": record.duplicate(true)}


func advance_to_day(day: int, weather_id: StringName, season_growth_multiplier: float = 1.0) -> Dictionary:
	var target_day := maxi(1, day)
	var changed_chunks := {}
	var matured := 0
	var season_multiplier := maxf(0.0, season_growth_multiplier)
	for key_value in _plots.keys():
		var key := String(key_value)
		var record := (_plots[key] as Dictionary).duplicate(true)
		var crop_id := StringName(record.get("crop_id", ""))
		var previous_day := int(record.get("last_simulated_day", record.get("tilled_day", target_day)))
		if target_day <= previous_day:
			continue
		var elapsed_days := target_day - previous_day
		if not crop_id.is_empty() and not bool(record.get("mature", false)):
			var wet_days := elapsed_days if weather_id == &"RAIN" else (1 if int(record.get("watered_day", -1)) >= previous_day and int(record.get("watered_day", -1)) < target_day else 0)
			var dry_days := elapsed_days - wet_days
			var fertilizer := _catalog.fertilizer(StringName(record.get("fertilizer_id", "")))
			var fertilizer_growth := float(fertilizer.get("growth_bonus", 0.0))
			var weather_multiplier := _catalog.weather_growth_multiplier(weather_id)
			var growth_delta := (float(wet_days) + float(dry_days) * _catalog.dry_growth_multiplier()) * weather_multiplier
			growth_delta += float(elapsed_days) * fertilizer_growth
			growth_delta *= season_multiplier
			record["growth_points"] = float(record.get("growth_points", 0.0)) + growth_delta
			record["care_days"] = int(record.get("care_days", 0)) + wet_days
			var crop := _catalog.crop(crop_id)
			var days_to_mature := float(crop["days_to_mature"])
			var stage_count := int(crop["stage_count"])
			var next_stage := mini(stage_count - 1, floori(float(record["growth_points"]) / days_to_mature * float(stage_count)))
			record["stage"] = maxi(0, next_stage)
			if float(record["growth_points"]) >= days_to_mature:
				record["growth_points"] = days_to_mature
				record["stage"] = stage_count - 1
				record["mature"] = true
				matured += 1
		if weather_id == &"RAIN":
			record["watered_day"] = target_day
		record["last_simulated_day"] = target_day
		_plots[key] = record
		changed_chunks[WorldCoordinates.tile_to_chunk(_tile_from_record(record))] = true
	return {"changed": not changed_chunks.is_empty(), "changed_chunks": changed_chunks.keys(), "matured": matured}


func harvest(world_tile: Vector2i, day: int, inventory: InventoryModel) -> Dictionary:
	var record := plot_at(world_tile)
	var crop_id := StringName(record.get("crop_id", ""))
	if record.is_empty() or crop_id.is_empty() or not bool(record.get("mature", false)):
		return _fail_result("作物尚未成熟")
	var crop := _catalog.crop(crop_id)
	var harvest_index := int(record.get("harvest_count", 0))
	var stable_roll := WorldSeed.from_text("farm|%d|%d|%d|%s|%d" % [_world_seed, world_tile.x, world_tile.y, crop_id, harvest_index])
	var elapsed := maxi(1, int(record.get("last_simulated_day", day)) - int(record.get("planted_day", day)))
	var care_ratio := clampf(float(record.get("care_days", 0)) / float(elapsed), 0.0, 1.0)
	var fertilizer := _catalog.fertilizer(StringName(record.get("fertilizer_id", "")))
	var quality_score := floori(care_ratio * 65.0) + int(fertilizer.get("quality_bonus", 0)) + int(stable_roll % 16)
	var quality_id := &"gold" if quality_score >= 90 else (&"silver" if quality_score >= 70 else &"normal")
	var output_id := _catalog.quality_output(crop_id, quality_id)
	var quantity_range := int(crop["yield_max"]) - int(crop["yield_min"]) + 1
	var quantity := int(crop["yield_min"]) + int((stable_roll / 17) % quantity_range)
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()):
		return _fail_result("无法创建收获事务")
	var add_result := simulation.add_item(output_id, quantity)
	if int(add_result["remainder"]) > 0:
		return _fail_result("背包空间不足，作物未收获")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交收获事务")
	record["harvest_count"] = harvest_index + 1
	record["fertilizer_id"] = ""
	record["care_days"] = 0
	record["watered_day"] = -1
	record["last_simulated_day"] = maxi(1, day)
	var regrow_days := int(crop.get("regrow_days", 0))
	if regrow_days > 0:
		record["growth_points"] = maxf(0.0, float(crop["days_to_mature"]) - float(regrow_days))
		record["stage"] = mini(
			int(crop["stage_count"]) - 1,
			floori(float(record["growth_points"]) / float(crop["days_to_mature"]) * float(crop["stage_count"]))
		)
		record["mature"] = false
		record["planted_day"] = maxi(1, day)
	else:
		record["crop_id"] = ""
		record["growth_points"] = 0.0
		record["stage"] = 0
		record["mature"] = false
		record.erase("planted_day")
	_plots[String(record["plot_id"])] = record
	last_error = ""
	return {
		"ok": true,
		"message": "收获%s%s ×%d" % [QUALITY_NAMES[String(quality_id)], crop["display_name"], quantity],
		"plot": record.duplicate(true),
		"crop_id": String(crop_id),
		"item_id": String(output_id),
		"quantity": quantity,
		"quality": String(quality_id),
		"quality_score": quality_score,
		"regrows": regrow_days > 0,
	}


func status_snapshot(inventory: InventoryModel = null) -> Dictionary:
	var crop_views: Array[Dictionary] = []
	for definition in _catalog.crops():
		var seed_id := StringName(definition["seed_item_id"])
		crop_views.append({
			"crop_id": String(definition["id"]),
			"display_name": String(definition["display_name"]),
			"seed_item_id": String(seed_id),
			"seed_display_name": _item_catalog.display_name(seed_id),
			"seed_quantity": inventory.quantity(seed_id) if inventory != null else 0,
			"days_to_mature": int(definition["days_to_mature"]),
			"fruit_tree": bool(definition.get("fruit_tree", false)),
			"color": String(definition["color"]),
		})
	return {
		"schema_version": SCHEMA_VERSION,
		"plot_count": plot_count(),
		"plot_limit": _catalog.max_plots(),
		"mature_count": mature_count(),
		"crops": crop_views,
		"fertilizer_ids": _catalog.fertilizer_ids(),
	}


func persistence_snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "plots": plots()}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_plots.clear()
		last_error = ""
		return true
	if not _catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("plots", []) is Array:
		return _restore_fail("农业状态格式无效")
	var plot_values := value["plots"] as Array
	if plot_values.size() > _catalog.max_plots():
		return _restore_fail("耕地数量超过上限")
	var restored := {}
	for plot_value in plot_values:
		if not plot_value is Dictionary:
			return _restore_fail("耕地记录必须是对象")
		var record := (plot_value as Dictionary).duplicate(true)
		var tile_value: Variant = record.get("world_tile", [])
		if not tile_value is Array or (tile_value as Array).size() != 2 \
				or not _is_integer_value((tile_value as Array)[0]) or not _is_integer_value((tile_value as Array)[1]):
			return _restore_fail("耕地坐标无效")
		var world_tile := Vector2i(int((tile_value as Array)[0]), int((tile_value as Array)[1]))
		var expected_id := _plot_id(world_tile)
		if String(record.get("plot_id", "")) != expected_id or restored.has(expected_id):
			return _restore_fail("耕地稳定 ID 重复或无效")
		var tilled_day := int(record.get("tilled_day", 0))
		var last_day := int(record.get("last_simulated_day", 0))
		var watered_day := int(record.get("watered_day", -1))
		var crop_id := StringName(record.get("crop_id", ""))
		var fertilizer_id := StringName(record.get("fertilizer_id", ""))
		if tilled_day < 1 or last_day < tilled_day or watered_day < -1 or watered_day > last_day \
				or (not fertilizer_id.is_empty() and _catalog.fertilizer(fertilizer_id).is_empty()) \
				or int(record.get("harvest_count", -1)) < 0:
			return _restore_fail("耕地日期或肥料状态无效")
		if crop_id.is_empty():
			if not fertilizer_id.is_empty() or bool(record.get("mature", false)) or float(record.get("growth_points", 0.0)) != 0.0:
				return _restore_fail("空耕地包含作物状态")
			record["growth_points"] = 0.0
			record["stage"] = 0
			record["care_days"] = 0
			record["mature"] = false
			record.erase("planted_day")
		else:
			var crop := _catalog.crop(crop_id)
			var planted_day := int(record.get("planted_day", 0))
			var growth := float(record.get("growth_points", -1.0))
			var care_days := int(record.get("care_days", -1))
			if crop.is_empty() or planted_day < tilled_day or planted_day > last_day or growth < 0.0 \
					or growth > float(crop["days_to_mature"]) or care_days < 0 or care_days > last_day - planted_day:
				return _restore_fail("作物生长状态无效")
			var expected_mature := is_equal_approx(growth, float(crop["days_to_mature"]))
			if bool(record.get("mature", false)) != expected_mature:
				return _restore_fail("作物成熟状态与生长值不一致")
			var expected_stage := int(crop["stage_count"]) - 1 if expected_mature else mini(int(crop["stage_count"]) - 1, floori(growth / float(crop["days_to_mature"]) * float(crop["stage_count"])))
			if int(record.get("stage", -1)) != expected_stage:
				return _restore_fail("作物生长阶段无效")
			record["planted_day"] = planted_day
			record["growth_points"] = growth
			record["care_days"] = care_days
			record["stage"] = expected_stage
			record["mature"] = expected_mature
		record["plot_id"] = expected_id
		record["world_tile"] = [world_tile.x, world_tile.y]
		record["tilled_day"] = tilled_day
		record["last_simulated_day"] = last_day
		record["watered_day"] = watered_day
		record["harvest_count"] = int(record.get("harvest_count", 0))
		record["crop_id"] = String(crop_id)
		record["fertilizer_id"] = String(fertilizer_id)
		restored[expected_id] = record
	_plots = restored
	last_error = ""
	return true


func _plot_id(world_tile: Vector2i) -> String:
	return "surface:%d:%d:farm" % [world_tile.x, world_tile.y]


func _tile_from_record(record: Dictionary) -> Vector2i:
	var value := record.get("world_tile", [0, 0]) as Array
	return Vector2i(int(value[0]), int(value[1]))


func _plot_less(a: Dictionary, b: Dictionary) -> bool:
	var tile_a := _tile_from_record(a)
	var tile_b := _tile_from_record(b)
	return tile_a.y < tile_b.y or (tile_a.y == tile_b.y and tile_a.x < tile_b.x)


func _validation_failure(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason}


func _fail_result(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}


func _restore_fail(message: String) -> bool:
	last_error = message
	return false


func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _is_integer_value(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(float(value), floorf(float(value))))
