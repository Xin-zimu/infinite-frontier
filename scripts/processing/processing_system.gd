class_name ProcessingSystem
extends RefCounted

var last_error := ""
var _inventory: InventoryModel
var _building_state: BuildingState
var _catalog: ProcessingCatalog
var _item_catalog: ItemCatalog


func _init(inventory: InventoryModel, building_state: BuildingState, catalog := ProcessingCatalog.new()) -> void:
	_inventory = inventory
	_building_state = building_state
	_catalog = catalog
	_item_catalog = inventory.catalog()


func catalog() -> ProcessingCatalog:
	return _catalog


func add_fuel(station_id: StringName, fuel_item_id: StringName, origin_tile: Vector2i) -> Dictionary:
	var units := _catalog.fuel_units(fuel_item_id)
	if units <= 0:
		return _fail("该物品不能作为加工燃料")
	var processor := _building_state.nearest_processor(origin_tile, station_id, _catalog.interaction_radius_tiles())
	if processor.is_empty():
		return _fail("附近没有%s" % _catalog.station_display_name(station_id))
	var capacity := int(processor.get("fuel_capacity", 0))
	var current := int(processor.get("fuel_units", 0))
	if current + units > capacity:
		return _fail("燃料仓容量不足：%d/%d" % [current, capacity])
	if _inventory.quantity(fuel_item_id) < 1:
		return _fail("缺少燃料：%s" % _item_catalog.display_name(fuel_item_id))
	var before := _inventory.snapshot()
	var simulation := InventoryModel.new(_item_catalog)
	if not simulation.restore_snapshot(before) or not simulation.remove_item(fuel_item_id, 1):
		return _fail("无法创建燃料事务")
	if not _inventory.restore_snapshot(simulation.snapshot()):
		return _fail("无法提交燃料事务")
	var update := _building_state.add_processor_fuel(String(processor["placement_id"]), units)
	if not bool(update.get("ok", false)):
		_inventory.restore_snapshot(before)
		return _fail(String(update.get("message", "燃料提交失败")))
	last_error = ""
	return {
		"ok": true,
		"message": "投入%s · 燃料 %d/%d" % [_item_catalog.display_name(fuel_item_id), current + units, capacity],
		"placement": update["placement"],
	}


func process(recipe_id: StringName, origin_tile: Vector2i) -> Dictionary:
	var definition := _catalog.recipe(recipe_id)
	if definition.is_empty():
		return _fail("未知加工配方：%s" % recipe_id)
	var station_id := StringName(definition["station"])
	var processor := _building_state.nearest_processor(origin_tile, station_id, _catalog.interaction_radius_tiles())
	if processor.is_empty():
		return _fail("附近没有%s" % _catalog.station_display_name(station_id))
	var fuel_cost := int(definition["fuel_cost"])
	if int(processor.get("fuel_units", 0)) < fuel_cost:
		return _fail("燃料不足：%d/%d" % [int(processor.get("fuel_units", 0)), fuel_cost])
	var inputs := definition["inputs"] as Dictionary
	for item_id_value in inputs.keys():
		var item_id := StringName(item_id_value)
		var required := int(inputs[item_id_value])
		if _inventory.quantity(item_id) < required:
			return _fail("材料不足：%s %d/%d" % [_item_catalog.display_name(item_id), _inventory.quantity(item_id), required])
	var before := _inventory.snapshot()
	var simulation := InventoryModel.new(_item_catalog)
	if not simulation.restore_snapshot(before):
		return _fail("无法创建加工事务")
	for item_id_value in inputs.keys():
		if not simulation.remove_item(StringName(item_id_value), int(inputs[item_id_value])):
			return _fail("加工事务扣除材料失败")
	var output := definition["output"] as Dictionary
	var output_id := StringName(output["item_id"])
	var output_quantity := int(output["quantity"])
	if int(simulation.add_item(output_id, output_quantity)["remainder"]) > 0:
		return _fail("背包空间不足，加工未消耗材料或燃料")
	if not _inventory.restore_snapshot(simulation.snapshot()):
		return _fail("无法提交加工事务")
	var fuel_result := _building_state.consume_processor_fuel(String(processor["placement_id"]), fuel_cost)
	if not bool(fuel_result.get("ok", false)):
		_inventory.restore_snapshot(before)
		return _fail(String(fuel_result.get("message", "燃料提交失败")))
	last_error = ""
	return {
		"ok": true,
		"recipe_id": String(recipe_id),
		"item_id": String(output_id),
		"quantity": output_quantity,
		"message": "加工完成：%s ×%d" % [_item_catalog.display_name(output_id), output_quantity],
		"placement": fuel_result["placement"],
	}


func state_snapshot(origin_tile: Vector2i, available_layer := true) -> Dictionary:
	var stations: Array[Dictionary] = []
	for station_id in _catalog.station_ids():
		var processor := _building_state.nearest_processor(origin_tile, station_id, _catalog.interaction_radius_tiles()) if available_layer else {}
		stations.append({
			"station_id": String(station_id),
			"display_name": _catalog.station_display_name(station_id),
			"available": not processor.is_empty(),
			"fuel_units": int(processor.get("fuel_units", 0)),
			"fuel_capacity": int(processor.get("fuel_capacity", 0)),
			"processed_count": int(processor.get("processed_count", 0)),
		})
	var fuels: Array[Dictionary] = []
	for definition in _catalog.fuels():
		var fuel_item_id := StringName(definition["item_id"])
		var view := definition.duplicate(true)
		view["quantity"] = _inventory.quantity(fuel_item_id)
		fuels.append(view)
	var recipe_views: Array[Dictionary] = []
	for definition in _catalog.recipes():
		var station_id := StringName(definition["station"])
		var processor := _building_state.nearest_processor(origin_tile, station_id, _catalog.interaction_radius_tiles()) if available_layer else {}
		var material_parts: Array[String] = []
		var has_materials := true
		for item_id_value in (definition["inputs"] as Dictionary).keys():
			var item_id := StringName(item_id_value)
			var required := int((definition["inputs"] as Dictionary)[item_id_value])
			var current := _inventory.quantity(item_id)
			material_parts.append("%s %d/%d" % [_item_catalog.display_name(item_id), current, required])
			has_materials = has_materials and current >= required
		var output := definition["output"] as Dictionary
		var fuel_cost := int(definition["fuel_cost"])
		recipe_views.append({
			"recipe_id": String(definition["id"]),
			"display_name": String(definition["display_name"]),
			"station_id": String(station_id),
			"materials": " · ".join(material_parts),
			"fuel_cost": fuel_cost,
			"output_name": _item_catalog.display_name(StringName(output["item_id"])),
			"output_quantity": int(output["quantity"]),
			"craftable": not processor.is_empty() and int(processor.get("fuel_units", 0)) >= fuel_cost and has_materials,
		})
	return {"schema_version": 1, "stations": stations, "fuels": fuels, "recipes": recipe_views}


func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}
