class_name BuildingState
extends RefCounted

const SCHEMA_VERSION := 1
const ROTATIONS := [0, 90, 180, 270]
const SLOT_ORDER := {"ground": 0, "structure": 1, "roof": 2}

var last_error := ""
var _catalog: BuildingCatalog
var _item_catalog: ItemCatalog
var _automation_catalog: AutomationCatalog
var _homestead_catalog: HomesteadCatalog
var _placements: Dictionary = {}
var _automation_count := 0
var _homestead_count := 0


func _init(
	catalog := BuildingCatalog.new(),
	item_catalog := ItemCatalog.new(),
	automation_catalog := AutomationCatalog.new(),
	homestead_catalog := HomesteadCatalog.new()
) -> void:
	_catalog = catalog
	_item_catalog = item_catalog
	_automation_catalog = automation_catalog
	_homestead_catalog = homestead_catalog


func placement_count() -> int:
	return _placements.size()


func automation_count() -> int:
	return _automation_count


func homestead_marker_count() -> int:
	return _homestead_count


func placement(placement_id: String) -> Dictionary:
	return (_placements.get(placement_id, {}) as Dictionary).duplicate(true)


func placements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _placements.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(_placement_less)
	return result


func automation_placements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _placements.values():
		var record := value as Dictionary
		if not _catalog.automation_kind(StringName(record["piece_id"])).is_empty():
			result.append(record.duplicate(true))
	result.sort_custom(_placement_less)
	return result


func homestead_marker_placements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _placements.values():
		var record := value as Dictionary
		if StringName(record.get("piece_id", "")) == _homestead_catalog.marker_piece_id():
			result.append(record.duplicate(true))
	result.sort_custom(_placement_less)
	return result


func placements_for_chunk(chunk_coordinate: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _placements.values():
		var record := value as Dictionary
		var tile := _tile_from_record(record)
		if WorldCoordinates.tile_to_chunk(tile) == chunk_coordinate:
			result.append(record.duplicate(true))
	result.sort_custom(_placement_less)
	return result


func placement_at(world_tile: Vector2i, placement_slot: StringName) -> Dictionary:
	return placement(_placement_id(world_tile, placement_slot))


func preview(piece_id: StringName, world_tile: Vector2i, rotation: int, context: Dictionary) -> Dictionary:
	var definition := _catalog.piece(piece_id)
	if definition.is_empty():
		return _preview_failure(piece_id, world_tile, rotation, "未知建造蓝图")
	if not ROTATIONS.has(rotation):
		return _preview_failure(piece_id, world_tile, rotation, "旋转角度无效")
	if StringName(context.get("world_layer", &"surface")) != &"surface":
		return _preview_failure(piece_id, world_tile, rotation, "当前版本只能在地表建造")
	var player_tile := context.get("player_tile", world_tile) as Vector2i
	if _chebyshev_distance(world_tile, player_tile) > _catalog.placement_range_tiles():
		return _preview_failure(piece_id, world_tile, rotation, "超出建造距离")
	if bool(context.get("player_occupied", false)):
		return _preview_failure(piece_id, world_tile, rotation, "不能在玩家所在格放置")
	if bool(context.get("in_water", false)):
		return _preview_failure(piece_id, world_tile, rotation, "水面不能承载该建筑")
	if bool(context.get("generated_overlay", false)):
		return _preview_failure(piece_id, world_tile, rotation, "生成建筑或道路占用了该格")
	if bool(context.get("resource_occupied", false)):
		return _preview_failure(piece_id, world_tile, rotation, "请先清理该格资源")
	if bool(context.get("farming_occupied", false)):
		return _preview_failure(piece_id, world_tile, rotation, "耕地占用了该格")
	if bool(context.get("husbandry_occupied", false)):
		return _preview_failure(piece_id, world_tile, rotation, "动物占用了该格")
	var placement_slot := StringName(definition["placement_slot"])
	if not placement_at(world_tile, placement_slot).is_empty():
		return _preview_failure(piece_id, world_tile, rotation, "该建造层已有物件")
	if bool(definition.get("requires_floor", false)) and placement_at(world_tile, &"ground").is_empty():
		return _preview_failure(piece_id, world_tile, rotation, "需要先铺设木地板")
	if StringName(definition.get("category", "")) == &"door" and not _has_adjacent_wall(world_tile):
		return _preview_failure(piece_id, world_tile, rotation, "木门需要邻接至少一段木墙")
	if placement_count() >= _catalog.max_placements():
		return _preview_failure(piece_id, world_tile, rotation, "建筑数量已达到上限")
	if not _catalog.automation_kind(piece_id).is_empty() and automation_count() >= _automation_catalog.max_machines():
		return _preview_failure(piece_id, world_tile, rotation, "自动化机器数量已达到性能上限")
	if piece_id == _homestead_catalog.marker_piece_id():
		if homestead_marker_count() >= _homestead_catalog.max_bases():
			return _preview_failure(piece_id, world_tile, rotation, "家园信标数量已达到上限")
		for marker in homestead_marker_placements():
			if _chebyshev_distance(world_tile, _tile_from_record(marker)) < _homestead_catalog.minimum_spacing_tiles():
				return _preview_failure(piece_id, world_tile, rotation, "距离其他家园信标过近")
	return {
		"valid": true,
		"reason": "可以放置",
		"piece_id": String(piece_id),
		"display_name": String(definition["display_name"]),
		"world_tile": world_tile,
		"rotation": rotation,
		"placement_slot": String(placement_slot),
		"color": String(definition["color"]),
	}


func place(piece_id: StringName, world_tile: Vector2i, rotation: int, context: Dictionary, inventory: InventoryModel) -> Dictionary:
	var placement_preview := preview(piece_id, world_tile, rotation, context)
	if not bool(placement_preview["valid"]):
		return _fail_result(String(placement_preview["reason"]))
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()):
		return _fail_result("无法创建建造事务")
	var costs := _catalog.costs(piece_id)
	for item_id_value in costs.keys():
		var item_id := StringName(item_id_value)
		var required := int(costs[item_id_value])
		if simulation.quantity(item_id) < required:
			return _fail_result("材料不足：%s %d/%d" % [_item_catalog.display_name(item_id), simulation.quantity(item_id), required])
	for item_id_value in costs.keys():
		if not simulation.remove_item(StringName(item_id_value), int(costs[item_id_value])):
			return _fail_result("建造事务扣除材料失败")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交建造材料事务")
	var definition := _catalog.piece(piece_id)
	var placement_slot := StringName(definition["placement_slot"])
	var placement_id := _placement_id(world_tile, placement_slot)
	var record := {
		"placement_id": placement_id,
		"piece_id": String(piece_id),
		"world_tile": [world_tile.x, world_tile.y],
		"rotation": rotation,
	}
	if StringName(definition.get("interactive", "")) == &"door":
		record["door_open"] = false
	elif StringName(definition.get("interactive", "")) == &"storage":
		record["storage"] = []
	if bool(definition.get("processor", false)):
		record["fuel_units"] = 0
		record["processed_count"] = 0
	var automation_kind := StringName(definition.get("automation_kind", ""))
	if not automation_kind.is_empty():
		record["automation_enabled"] = true
		record["automation_last_seconds"] = -1.0
		record["automation_cycles"] = 0
		record["automation_status"] = "idle"
		if automation_kind == &"smelter":
			record["automation_fuel_units"] = 0
			record["automation_recipe_id"] = String(_automation_catalog.automatic_recipe_ids()[0])
		elif automation_kind == &"sorter":
			record["sort_filter_item_id"] = String(_automation_catalog.sortable_item_ids()[0])
	_placements[placement_id] = record
	if not automation_kind.is_empty():
		_automation_count += 1
	if piece_id == _homestead_catalog.marker_piece_id():
		_homestead_count += 1
	last_error = ""
	return {
		"ok": true,
		"message": "已建造%s" % definition["display_name"],
		"placement": record.duplicate(true),
		"costs": costs,
	}


func demolish_at(world_tile: Vector2i, inventory: InventoryModel) -> Dictionary:
	var target := _top_placement_at(world_tile)
	if target.is_empty():
		return _fail_result("该格没有玩家建筑")
	var target_slot := _catalog.placement_slot(StringName(target["piece_id"]))
	if target_slot == &"ground" and (not placement_at(world_tile, &"structure").is_empty() or not placement_at(world_tile, &"roof").is_empty()):
		return _fail_result("请先拆除地板上方的物件")
	if not (target.get("storage", []) as Array).is_empty():
		return _fail_result("储物箱非空，取出物品后才能拆除")
	if int(target.get("fuel_units", 0)) > 0:
		return _fail_result("加工设备仍有燃料，用尽后才能拆除")
	if int(target.get("automation_fuel_units", 0)) > 0:
		return _fail_result("自动化机器仍有燃料，用尽后才能拆除")
	var refund := _catalog.refund_for(StringName(target["piece_id"]))
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()):
		return _fail_result("无法创建拆除返还事务")
	for item_id_value in refund.keys():
		var add_result := simulation.add_item(StringName(item_id_value), int(refund[item_id_value]))
		if int(add_result["remainder"]) > 0:
			return _fail_result("背包空间不足，建筑未拆除")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交拆除返还事务")
	_placements.erase(String(target["placement_id"]))
	if not _catalog.automation_kind(StringName(target["piece_id"])).is_empty():
		_automation_count -= 1
	if StringName(target["piece_id"]) == _homestead_catalog.marker_piece_id():
		_homestead_count -= 1
	last_error = ""
	return {
		"ok": true,
		"message": "已拆除%s并返还材料" % _catalog.display_name(StringName(target["piece_id"])),
		"placement": target,
		"refund": refund,
	}


func toggle_nearest_door(origin_tile: Vector2i, radius_tiles := 2) -> Dictionary:
	var nearest := _nearest_interactive(origin_tile, &"door", radius_tiles)
	if nearest.is_empty():
		return _fail_result("附近没有玩家建造的门")
	var record := nearest.duplicate(true)
	record["door_open"] = not bool(record.get("door_open", false))
	_placements[String(record["placement_id"])] = record
	last_error = ""
	return {
		"ok": true,
		"message": "木门已%s" % ("打开" if bool(record["door_open"]) else "关闭"),
		"placement": record.duplicate(true),
	}


func interact_nearest_storage(origin_tile: Vector2i, inventory: InventoryModel, radius_tiles := 2) -> Dictionary:
	var nearest := _nearest_interactive(origin_tile, &"storage", radius_tiles)
	if nearest.is_empty():
		return _fail_result("附近没有玩家储物箱")
	var selected := inventory.slot(inventory.selected_hotbar_slot())
	if not selected.is_empty():
		return _deposit_selected(nearest, inventory, selected)
	return _withdraw_storage(nearest, inventory)


func nearest_interaction(origin_tile: Vector2i, radius_tiles := 2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius_tiles + 1
	for value in _placements.values():
		var record := value as Dictionary
		var interaction := StringName(_catalog.piece(StringName(record["piece_id"])).get("interactive", ""))
		if interaction.is_empty():
			continue
		var distance := _chebyshev_distance(origin_tile, _tile_from_record(record))
		if distance > radius_tiles or distance >= best_distance:
			continue
		best_distance = distance
		best = record.duplicate(true)
		best["interaction"] = String(interaction)
	return best


func nearby_station_ids(origin_tile: Vector2i) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in _placements.values():
		var record := value as Dictionary
		var definition := _catalog.piece(StringName(record["piece_id"]))
		var station_kind := StringName(definition.get("station_kind", ""))
		if station_kind.is_empty() or _chebyshev_distance(origin_tile, _tile_from_record(record)) > _catalog.station_radius_tiles():
			continue
		if not result.has(station_kind):
			result.append(station_kind)
	result.sort()
	return result


func nearest_processor(origin_tile: Vector2i, station_id: StringName, radius_tiles: int) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := maxi(0, radius_tiles) + 1
	for record in placements():
		var definition := _catalog.piece(StringName(record["piece_id"]))
		if not bool(definition.get("processor", false)) or StringName(definition.get("station_kind", "")) != station_id:
			continue
		var distance := _chebyshev_distance(origin_tile, _tile_from_record(record))
		if distance > radius_tiles or distance >= best_distance:
			continue
		best_distance = distance
		best = record.duplicate(true)
		best["fuel_capacity"] = int(definition.get("fuel_capacity", 0))
	return best


func add_processor_fuel(placement_id: String, fuel_units: int) -> Dictionary:
	if fuel_units < 1:
		return _fail_result("燃料单位必须为正数")
	var record := placement(placement_id)
	if record.is_empty():
		return _fail_result("加工设备不存在")
	var definition := _catalog.piece(StringName(record["piece_id"]))
	if not bool(definition.get("processor", false)):
		return _fail_result("目标建筑不是加工设备")
	var capacity := int(definition.get("fuel_capacity", 0))
	var current := int(record.get("fuel_units", 0))
	if current + fuel_units > capacity:
		return _fail_result("加工设备燃料仓容量不足")
	record["fuel_units"] = current + fuel_units
	_placements[placement_id] = record
	last_error = ""
	return {"ok": true, "message": "已补充燃料", "placement": record.duplicate(true)}


func consume_processor_fuel(placement_id: String, fuel_units: int) -> Dictionary:
	if fuel_units < 1:
		return _fail_result("燃料消耗必须为正数")
	var record := placement(placement_id)
	if record.is_empty():
		return _fail_result("加工设备不存在")
	var definition := _catalog.piece(StringName(record["piece_id"]))
	if not bool(definition.get("processor", false)):
		return _fail_result("目标建筑不是加工设备")
	var current := int(record.get("fuel_units", 0))
	if current < fuel_units:
		return _fail_result("加工设备燃料不足")
	record["fuel_units"] = current - fuel_units
	record["processed_count"] = int(record.get("processed_count", 0)) + 1
	_placements[placement_id] = record
	last_error = ""
	return {"ok": true, "message": "加工燃料已结算", "placement": record.duplicate(true)}


func is_near_heat(origin_tile: Vector2i) -> bool:
	for value in _placements.values():
		var record := value as Dictionary
		var definition := _catalog.piece(StringName(record["piece_id"]))
		if bool(definition.get("heat_source", false)) and _chebyshev_distance(origin_tile, _tile_from_record(record)) <= _catalog.heat_radius_tiles():
			return true
	return false


func is_near_piece(origin_tile: Vector2i, piece_id: StringName, radius_tiles: int) -> bool:
	for value in _placements.values():
		var record := value as Dictionary
		if StringName(record.get("piece_id", "")) == piece_id \
				and _chebyshev_distance(origin_tile, _tile_from_record(record)) <= maxi(0, radius_tiles):
			return true
	return false


func status_snapshot(inventory: InventoryModel = null) -> Dictionary:
	var views: Array[Dictionary] = []
	for definition in _catalog.pieces():
		var costs := definition["costs"] as Dictionary
		var cost_parts: Array[String] = []
		var affordable := inventory != null
		for item_id_value in costs.keys():
			var item_id := StringName(item_id_value)
			var required := int(costs[item_id_value])
			var current := inventory.quantity(item_id) if inventory != null else 0
			cost_parts.append("%s %d/%d" % [_item_catalog.display_name(item_id), current, required])
			affordable = affordable and current >= required
		views.append({
			"piece_id": String(definition["id"]),
			"display_name": String(definition["display_name"]),
			"category": String(definition["category"]),
			"placement_slot": String(definition["placement_slot"]),
			"color": String(definition["color"]),
			"cost_text": " · ".join(cost_parts),
			"affordable": affordable,
		})
	return {
		"schema_version": SCHEMA_VERSION,
		"placement_count": placement_count(),
		"placement_limit": _catalog.max_placements(),
		"automation_count": automation_count(),
		"automation_limit": _automation_catalog.max_machines(),
		"homestead_count": homestead_marker_count(),
		"homestead_limit": _homestead_catalog.max_bases(),
		"pieces": views,
	}


func persistence_snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "placements": placements()}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_placements.clear()
		_automation_count = 0
		_homestead_count = 0
		last_error = ""
		return true
	if not _catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("placements", []) is Array:
		return _restore_fail("建造状态格式无效")
	var placement_values := value["placements"] as Array
	if placement_values.size() > _catalog.max_placements():
		return _restore_fail("玩家建筑数量超过上限")
	var restored := {}
	var occupied_slots := {}
	var automation_count := 0
	var homestead_count := 0
	var homestead_tiles: Array[Vector2i] = []
	for placement_value in placement_values:
		if not placement_value is Dictionary:
			return _restore_fail("玩家建筑记录必须是对象")
		var record := (placement_value as Dictionary).duplicate(true)
		var piece_id := StringName(record.get("piece_id", ""))
		var definition := _catalog.piece(piece_id)
		var tile_value: Variant = record.get("world_tile", [])
		var rotation := int(record.get("rotation", -1))
		if definition.is_empty() or not tile_value is Array or (tile_value as Array).size() != 2 or not ROTATIONS.has(rotation):
			return _restore_fail("玩家建筑记录字段无效")
		var tile_array := tile_value as Array
		if not _is_integer_value(tile_array[0]) or not _is_integer_value(tile_array[1]):
			return _restore_fail("玩家建筑坐标必须是整数")
		var world_tile := Vector2i(int(tile_array[0]), int(tile_array[1]))
		var placement_slot := StringName(definition["placement_slot"])
		var expected_id := _placement_id(world_tile, placement_slot)
		if String(record.get("placement_id", "")) != expected_id or restored.has(expected_id) or occupied_slots.has(expected_id):
			return _restore_fail("玩家建筑稳定 ID 重复或无效")
		var interaction := StringName(definition.get("interactive", ""))
		if interaction == &"door":
			if not (record.get("door_open", false) is bool):
				return _restore_fail("木门开关状态无效")
			record["door_open"] = bool(record.get("door_open", false))
		elif record.has("door_open"):
			return _restore_fail("非门建筑包含门状态")
		if interaction == &"storage":
			var storage_value: Variant = record.get("storage", [])
			if not storage_value is Array:
				return _restore_fail("储物箱内容必须是数组")
			var normalized_storage := _normalize_storage(storage_value as Array)
			if normalized_storage.is_empty() and not (storage_value as Array).is_empty():
				return false
			record["storage"] = normalized_storage
		elif record.has("storage"):
			return _restore_fail("非储物箱建筑包含储物内容")
		var processor := bool(definition.get("processor", false))
		if processor:
			var fuel_units := int(record.get("fuel_units", 0))
			var processed_count := int(record.get("processed_count", 0))
			if not _is_integer_value(record.get("fuel_units", 0)) or fuel_units < 0 \
					or fuel_units > int(definition.get("fuel_capacity", 0)) \
					or not _is_integer_value(record.get("processed_count", 0)) or processed_count < 0:
				return _restore_fail("加工设备燃料或计数无效")
			record["fuel_units"] = fuel_units
			record["processed_count"] = processed_count
		elif record.has("fuel_units") or record.has("processed_count"):
			return _restore_fail("非加工建筑包含燃料状态")
		var automation_kind := StringName(definition.get("automation_kind", ""))
		if not automation_kind.is_empty():
			automation_count += 1
			if automation_count > _automation_catalog.max_machines():
				return _restore_fail("自动化机器数量超过性能上限")
			var enabled_value: Variant = record.get("automation_enabled", true)
			var last_seconds_value: Variant = record.get("automation_last_seconds", -1.0)
			var cycles_value: Variant = record.get("automation_cycles", 0)
			var status := String(record.get("automation_status", "idle"))
			if not enabled_value is bool or not (last_seconds_value is int or last_seconds_value is float) \
					or not is_finite(float(last_seconds_value)) or float(last_seconds_value) < -1.0 \
					or not _is_integer_value(cycles_value) or int(cycles_value) < 0 \
					or status not in ["idle", "disabled", "working", "linked", "waiting_connection", "input_blocked", "output_blocked", "no_fuel", "throttled"]:
				return _restore_fail("自动化机器状态无效")
			record["automation_enabled"] = bool(enabled_value)
			record["automation_last_seconds"] = float(last_seconds_value)
			record["automation_cycles"] = int(cycles_value)
			record["automation_status"] = status
			if automation_kind == &"smelter":
				var automation_fuel_value: Variant = record.get("automation_fuel_units", 0)
				var recipe_id := StringName(record.get("automation_recipe_id", ""))
				if not _is_integer_value(automation_fuel_value) or int(automation_fuel_value) < 0 \
						or int(automation_fuel_value) > int(definition.get("automation_fuel_capacity", 0)) \
						or recipe_id not in _automation_catalog.automatic_recipe_ids():
					return _restore_fail("自动熔炉燃料或配方无效")
				record["automation_fuel_units"] = int(automation_fuel_value)
				record["automation_recipe_id"] = String(recipe_id)
			elif record.has("automation_fuel_units") or record.has("automation_recipe_id"):
				return _restore_fail("非熔炉自动化机器包含燃料或配方")
			if automation_kind == &"sorter":
				var filter_item_id := StringName(record.get("sort_filter_item_id", ""))
				if filter_item_id not in _automation_catalog.sortable_item_ids():
					return _restore_fail("分拣器过滤物品无效")
				record["sort_filter_item_id"] = String(filter_item_id)
			elif record.has("sort_filter_item_id"):
				return _restore_fail("非分拣器包含过滤物品")
		else:
			for automation_field in ["automation_enabled", "automation_last_seconds", "automation_cycles", "automation_status", "automation_fuel_units", "automation_recipe_id", "sort_filter_item_id"]:
				if record.has(automation_field):
					return _restore_fail("非自动化建筑包含机器状态")
		if piece_id == _homestead_catalog.marker_piece_id():
			homestead_count += 1
			if homestead_count > _homestead_catalog.max_bases():
				return _restore_fail("家园信标数量超过上限")
			for previous_tile in homestead_tiles:
				if _chebyshev_distance(world_tile, previous_tile) < _homestead_catalog.minimum_spacing_tiles():
					return _restore_fail("家园信标间距不足")
			homestead_tiles.append(world_tile)
		record["placement_id"] = expected_id
		record["piece_id"] = String(piece_id)
		record["world_tile"] = [world_tile.x, world_tile.y]
		record["rotation"] = rotation
		restored[expected_id] = record
		occupied_slots[expected_id] = true
	for value_record in restored.values():
		var restored_record := value_record as Dictionary
		var restored_definition := _catalog.piece(StringName(restored_record["piece_id"]))
		if bool(restored_definition.get("requires_floor", false)):
			var tile := _tile_from_record(restored_record)
			if not restored.has(_placement_id(tile, &"ground")):
				return _restore_fail("需要地板的玩家建筑失去支撑")
	_placements = restored
	_automation_count = automation_count
	_homestead_count = homestead_count
	last_error = ""
	return true


func _deposit_selected(record: Dictionary, inventory: InventoryModel, selected: Dictionary) -> Dictionary:
	var storage := (record.get("storage", []) as Array).duplicate(true)
	var quantity := int(selected.get("quantity", 0))
	var result := _add_to_storage(storage, selected)
	if int(result["accepted"]) != quantity:
		return _fail_result("储物箱空间不足，物品未转移")
	var removed := inventory.discard(inventory.selected_hotbar_slot(), quantity)
	if int(removed.get("quantity", 0)) != quantity:
		return _fail_result("快捷栏物品转移失败")
	var updated := record.duplicate(true)
	updated["storage"] = result["storage"]
	_placements[String(record["placement_id"])] = updated
	last_error = ""
	return {"ok": true, "message": "已存入%s ×%d" % [_item_catalog.display_name(StringName(selected["item_id"])), quantity], "placement": updated}


func _withdraw_storage(record: Dictionary, inventory: InventoryModel) -> Dictionary:
	var storage := record.get("storage", []) as Array
	if storage.is_empty():
		return _fail_result("储物箱为空；选中快捷栏物品再交互可存入")
	var simulation := InventoryModel.new(inventory.catalog())
	if not simulation.restore_snapshot(inventory.snapshot()):
		return _fail_result("无法创建储物取回事务")
	var remaining: Array[Dictionary] = []
	var transferred := 0
	for value in storage:
		var entry := (value as Dictionary).duplicate(true)
		var quantity := int(entry["quantity"])
		var add_result := simulation.add_item(StringName(entry["item_id"]), quantity, int(entry.get("durability", -1)))
		var accepted := int(add_result["accepted"])
		transferred += accepted
		if accepted < quantity:
			entry["quantity"] = quantity - accepted
			remaining.append(entry)
	if transferred <= 0:
		return _fail_result("背包空间不足，储物箱未改变")
	if not inventory.restore_snapshot(simulation.snapshot()):
		return _fail_result("无法提交储物取回事务")
	var updated := record.duplicate(true)
	updated["storage"] = remaining
	_placements[String(record["placement_id"])] = updated
	last_error = ""
	return {"ok": true, "message": "已从储物箱取回 %d 件物品" % transferred, "placement": updated}


func _add_to_storage(storage_value: Array, entry_value: Dictionary) -> Dictionary:
	var storage: Array[Dictionary] = []
	for value in storage_value:
		storage.append((value as Dictionary).duplicate(true))
	var item_id := StringName(entry_value["item_id"])
	var remaining := int(entry_value["quantity"])
	var maximum := _item_catalog.maximum_stack(item_id)
	var durability := int(entry_value.get("durability", -1))
	for index in storage.size():
		var current := storage[index]
		if StringName(current.get("item_id", "")) != item_id or int(current.get("durability", -1)) != durability:
			continue
		var moved := mini(maximum - int(current["quantity"]), remaining)
		if moved <= 0:
			continue
		current["quantity"] = int(current["quantity"]) + moved
		storage[index] = current
		remaining -= moved
	for _index in range(storage.size(), _catalog.chest_slot_count()):
		if remaining <= 0:
			break
		var moved := mini(maximum, remaining)
		var next := {"item_id": String(item_id), "quantity": moved}
		if durability > 0:
			next["durability"] = durability
		storage.append(next)
		remaining -= moved
	return {"accepted": int(entry_value["quantity"]) - remaining, "storage": storage}


func _normalize_storage(storage_value: Array) -> Array[Dictionary]:
	if storage_value.size() > _catalog.chest_slot_count():
		_restore_fail("储物箱格数超过上限")
		return []
	var result: Array[Dictionary] = []
	for value in storage_value:
		if not value is Dictionary:
			_restore_fail("储物箱物品记录无效")
			return []
		var entry := value as Dictionary
		var item_id := StringName(entry.get("item_id", ""))
		var quantity := int(entry.get("quantity", 0))
		if not _item_catalog.has_item(item_id) or quantity < 1 or quantity > _item_catalog.maximum_stack(item_id):
			_restore_fail("储物箱包含未知或越界物品")
			return []
		var normalized := {"item_id": String(item_id), "quantity": quantity}
		if _item_catalog.is_durable(item_id):
			var durability := int(entry.get("durability", 0))
			if quantity != 1 or durability < 1 or durability > _item_catalog.maximum_durability(item_id):
				_restore_fail("储物箱工具耐久无效")
				return []
			normalized["durability"] = durability
		elif entry.has("durability"):
			_restore_fail("普通储物物品包含耐久")
			return []
		result.append(normalized)
	return result


func _top_placement_at(world_tile: Vector2i) -> Dictionary:
	for slot in [&"roof", &"structure", &"ground"]:
		var record := placement_at(world_tile, slot)
		if not record.is_empty():
			return record
	return {}


func _nearest_interactive(origin_tile: Vector2i, interaction: StringName, radius_tiles: int) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius_tiles + 1
	for value in _placements.values():
		var record := value as Dictionary
		var definition := _catalog.piece(StringName(record["piece_id"]))
		if StringName(definition.get("interactive", "")) != interaction:
			continue
		var distance := _chebyshev_distance(origin_tile, _tile_from_record(record))
		if distance > radius_tiles or distance >= best_distance:
			continue
		best_distance = distance
		best = record.duplicate(true)
	return best


func _has_adjacent_wall(world_tile: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor := placement_at(world_tile + offset, &"structure")
		if StringName(neighbor.get("piece_id", "")) == &"wood_wall":
			return true
	return false


func _placement_id(world_tile: Vector2i, placement_slot: StringName) -> String:
	return "surface:%d:%d:%s" % [world_tile.x, world_tile.y, placement_slot]


func _tile_from_record(record: Dictionary) -> Vector2i:
	var value := record.get("world_tile", [0, 0]) as Array
	return Vector2i(int(value[0]), int(value[1]))


func _preview_failure(piece_id: StringName, world_tile: Vector2i, rotation: int, reason: String) -> Dictionary:
	return {"valid": false, "reason": reason, "piece_id": String(piece_id), "world_tile": world_tile, "rotation": rotation, "color": "d65f5f"}


func _fail_result(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}


func _restore_fail(message: String) -> bool:
	last_error = message
	return false


func _placement_less(a: Dictionary, b: Dictionary) -> bool:
	var tile_a := _tile_from_record(a)
	var tile_b := _tile_from_record(b)
	if tile_a.y != tile_b.y:
		return tile_a.y < tile_b.y
	if tile_a.x != tile_b.x:
		return tile_a.x < tile_b.x
	return int(SLOT_ORDER.get(String(_catalog.placement_slot(StringName(a["piece_id"]))), 99)) \
			< int(SLOT_ORDER.get(String(_catalog.placement_slot(StringName(b["piece_id"]))), 99))


func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _is_integer_value(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(float(value), floorf(float(value))))
