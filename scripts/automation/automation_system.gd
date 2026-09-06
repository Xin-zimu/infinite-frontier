class_name AutomationSystem
extends RefCounted

const STATUS_NAMES := {
	"idle": "待机", "disabled": "已关闭", "working": "工作中", "linked": "已连接",
	"waiting_connection": "等待连接", "input_blocked": "缺少输入", "output_blocked": "输出已满",
	"no_fuel": "缺少燃料", "throttled": "性能限流",
}

var last_error := ""
var _buildings: BuildingState
var _catalog: AutomationCatalog
var _building_catalog: BuildingCatalog
var _processing_catalog: ProcessingCatalog
var _item_catalog: ItemCatalog


func _init(
	building_state: BuildingState,
	catalog := AutomationCatalog.new(),
	building_catalog := BuildingCatalog.new(),
	processing_catalog := ProcessingCatalog.new(),
	item_catalog := ItemCatalog.new()
) -> void:
	_buildings = building_state
	_catalog = catalog
	_building_catalog = building_catalog
	_processing_catalog = processing_catalog
	_item_catalog = item_catalog


func catalog() -> AutomationCatalog:
	return _catalog


func advance_to(total_seconds: float) -> Dictionary:
	if not _catalog.is_valid() or not is_finite(total_seconds) or total_seconds < 0.0:
		return _fail("自动化时间或配置无效")
	var before := _buildings.persistence_snapshot()
	var records := _record_map(before.get("placements", []) as Array)
	var machine_ids: Array[String] = []
	for placement_id_value in records.keys():
		var placement_id := String(placement_id_value)
		var record := records[placement_id] as Dictionary
		if not _building_catalog.automation_kind(StringName(record["piece_id"])).is_empty():
			machine_ids.append(placement_id)
	machine_ids.sort()
	var operations := 0
	var simulated_ticks := 0
	var discarded_ticks := 0
	for placement_id in machine_ids:
		var record := records[placement_id] as Dictionary
		var last_seconds := float(record.get("automation_last_seconds", -1.0))
		if last_seconds < 0.0:
			record["automation_last_seconds"] = total_seconds
			record["automation_status"] = "idle" if bool(record.get("automation_enabled", true)) else "disabled"
			records[placement_id] = record
			continue
		if total_seconds < last_seconds:
			record["automation_last_seconds"] = total_seconds
			record["automation_status"] = "idle"
			records[placement_id] = record
			continue
		var raw_ticks := floori((total_seconds - last_seconds) / _catalog.tick_seconds())
		if raw_ticks <= 0:
			continue
		var due_ticks := mini(raw_ticks, _catalog.max_offline_ticks())
		simulated_ticks += due_ticks
		discarded_ticks += maxi(0, raw_ticks - due_ticks)
		for _tick in due_ticks:
			record = records[placement_id] as Dictionary
			if not bool(record.get("automation_enabled", true)):
				record["automation_status"] = "disabled"
				records[placement_id] = record
				break
			if operations >= _catalog.max_operations_per_advance():
				record["automation_status"] = "throttled"
				records[placement_id] = record
				break
			var result := _run_machine(records, placement_id)
			if bool(result.get("operation", false)):
				operations += 1
			else:
				break
		record = records[placement_id] as Dictionary
		record["automation_last_seconds"] = total_seconds if raw_ticks > due_ticks or String(record.get("automation_status", "")) == "throttled" \
				else last_seconds + float(raw_ticks) * _catalog.tick_seconds()
		records[placement_id] = record
	var normalized: Array[Dictionary] = []
	for value in records.values():
		normalized.append((value as Dictionary).duplicate(true))
	if not _buildings.restore_snapshot({"schema_version": BuildingState.SCHEMA_VERSION, "placements": normalized}):
		return _fail("自动化事务校验失败：%s" % _buildings.last_error)
	var after := _buildings.persistence_snapshot()
	var changed_chunks := _changed_chunks(before.get("placements", []) as Array, after.get("placements", []) as Array)
	last_error = ""
	return {
		"ok": true,
		"changed": before != after,
		"operations": operations,
		"simulated_ticks": simulated_ticks,
		"discarded_ticks": discarded_ticks,
		"machine_count": machine_ids.size(),
		"changed_chunks": changed_chunks,
	}


func toggle_machine(placement_id: String) -> Dictionary:
	var record := _buildings.placement(placement_id)
	if record.is_empty() or _building_catalog.automation_kind(StringName(record["piece_id"])).is_empty():
		return _fail("自动化机器不存在")
	record["automation_enabled"] = not bool(record.get("automation_enabled", true))
	record["automation_status"] = "idle" if bool(record["automation_enabled"]) else "disabled"
	return _replace_machine(record, "机器已%s" % ("启动" if bool(record["automation_enabled"]) else "关闭"))


func cycle_recipe(placement_id: String) -> Dictionary:
	var record := _buildings.placement(placement_id)
	if _building_catalog.automation_kind(StringName(record.get("piece_id", ""))) != &"smelter":
		return _fail("目标不是自动熔炉")
	var ids := _catalog.automatic_recipe_ids()
	var current := ids.find(StringName(record.get("automation_recipe_id", "")))
	var next_id := ids[(current + 1) % ids.size()]
	record["automation_recipe_id"] = String(next_id)
	record["automation_status"] = "idle"
	return _replace_machine(record, "自动配方已切换为%s" % _processing_catalog.recipe(next_id).get("display_name", next_id))


func cycle_filter(placement_id: String) -> Dictionary:
	var record := _buildings.placement(placement_id)
	if _building_catalog.automation_kind(StringName(record.get("piece_id", ""))) != &"sorter":
		return _fail("目标不是物品分拣器")
	var ids := _catalog.sortable_item_ids()
	var current := ids.find(StringName(record.get("sort_filter_item_id", "")))
	var next_id := ids[(current + 1) % ids.size()]
	record["sort_filter_item_id"] = String(next_id)
	record["automation_status"] = "idle"
	return _replace_machine(record, "分拣目标已切换为%s" % _item_catalog.display_name(next_id))


func state_snapshot(origin_tile := Vector2i.ZERO) -> Dictionary:
	var views: Array[Dictionary] = []
	var status_counts: Dictionary = {}
	for record in _buildings.automation_placements():
		var piece_id := StringName(record["piece_id"])
		var machine := _catalog.machine(piece_id)
		var tile := _tile(record)
		var status := String(record.get("automation_status", "idle"))
		status_counts[status] = int(status_counts.get(status, 0)) + 1
		var recipe_id := StringName(record.get("automation_recipe_id", ""))
		var filter_id := StringName(record.get("sort_filter_item_id", ""))
		views.append({
			"placement_id": String(record["placement_id"]),
			"piece_id": String(piece_id),
			"kind": String(machine.get("kind", "")),
			"display_name": String(machine.get("display_name", piece_id)),
			"world_tile": [tile.x, tile.y],
			"distance": maxi(absi(tile.x - origin_tile.x), absi(tile.y - origin_tile.y)),
			"rotation": int(record.get("rotation", 0)),
			"enabled": bool(record.get("automation_enabled", true)),
			"status": status,
			"status_name": String(STATUS_NAMES.get(status, status)),
			"cycles": int(record.get("automation_cycles", 0)),
			"fuel_units": int(record.get("automation_fuel_units", 0)),
			"fuel_capacity": int(_building_catalog.piece(piece_id).get("automation_fuel_capacity", 0)),
			"recipe_id": String(recipe_id),
			"recipe_name": String(_processing_catalog.recipe(recipe_id).get("display_name", "")),
			"filter_item_id": String(filter_id),
			"filter_name": _item_catalog.display_name(filter_id) if not filter_id.is_empty() else "",
		})
	views.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["distance"]) < int(b["distance"]) if int(a["distance"]) != int(b["distance"]) \
				else String(a["placement_id"]) < String(b["placement_id"])
	)
	if views.size() > 32:
		views.resize(32)
	return {
		"schema_version": 1,
		"machine_count": _buildings.automation_count(),
		"machine_limit": _catalog.max_machines(),
		"operation_limit": _catalog.max_operations_per_advance(),
		"offline_tick_limit": _catalog.max_offline_ticks(),
		"tick_seconds": _catalog.tick_seconds(),
		"status_counts": status_counts,
		"machines": views,
	}


func _run_machine(records: Dictionary, placement_id: String) -> Dictionary:
	var record := records[placement_id] as Dictionary
	var kind := _building_catalog.automation_kind(StringName(record["piece_id"]))
	if kind == &"smelter":
		return _run_smelter(records, placement_id)
	return _run_transfer(records, placement_id, kind)


func _run_transfer(records: Dictionary, placement_id: String, kind: StringName) -> Dictionary:
	var machine := records[placement_id] as Dictionary
	var direction := _direction(int(machine["rotation"]))
	var immediate_front := _structure_at(records, _tile(machine) + direction)
	if immediate_front.is_empty():
		machine["automation_status"] = "waiting_connection"
		records[placement_id] = machine
		return {"operation": false}
	if StringName(immediate_front.get("piece_id", "")) != &"storage_chest":
		if not _building_catalog.automation_kind(StringName(immediate_front.get("piece_id", ""))).is_empty():
			machine["automation_status"] = "linked"
		else:
			machine["automation_status"] = "waiting_connection"
		records[placement_id] = machine
		return {"operation": false}
	var source := _find_storage(records, _tile(machine), -direction)
	if source.is_empty():
		machine["automation_status"] = "waiting_connection"
		records[placement_id] = machine
		return {"operation": false}
	var source_storage := (source.get("storage", []) as Array).duplicate(true)
	var filter_id := StringName(machine.get("sort_filter_item_id", "")) if kind == &"sorter" else &""
	var selected_index := _first_storage_index(source_storage, filter_id)
	if selected_index < 0:
		machine["automation_status"] = "input_blocked"
		records[placement_id] = machine
		return {"operation": false}
	var entry := (source_storage[selected_index] as Dictionary).duplicate(true)
	var throughput := int(_catalog.machine(StringName(machine["piece_id"])).get("throughput", 1))
	entry["quantity"] = mini(int(entry["quantity"]), throughput)
	var add_result := _add_storage(immediate_front.get("storage", []) as Array, entry)
	var accepted := int(add_result["accepted"])
	if accepted <= 0:
		machine["automation_status"] = "output_blocked"
		records[placement_id] = machine
		return {"operation": false}
	_remove_storage_quantity(source_storage, selected_index, accepted)
	source["storage"] = source_storage
	immediate_front["storage"] = add_result["storage"]
	machine["automation_cycles"] = int(machine.get("automation_cycles", 0)) + 1
	machine["automation_status"] = "working"
	records[String(source["placement_id"])] = source
	records[String(immediate_front["placement_id"])] = immediate_front
	records[placement_id] = machine
	return {"operation": true}


func _run_smelter(records: Dictionary, placement_id: String) -> Dictionary:
	var machine := records[placement_id] as Dictionary
	var direction := _direction(int(machine["rotation"]))
	var source := _find_storage(records, _tile(machine), -direction)
	var target := _find_storage(records, _tile(machine), direction)
	if source.is_empty() or target.is_empty() or String(source["placement_id"]) == String(target["placement_id"]):
		machine["automation_status"] = "waiting_connection"
		records[placement_id] = machine
		return {"operation": false}
	var recipe := _processing_catalog.recipe(StringName(machine.get("automation_recipe_id", "")))
	var source_storage := (source.get("storage", []) as Array).duplicate(true)
	for item_id_value in (recipe.get("inputs", {}) as Dictionary).keys():
		if _storage_quantity(source_storage, StringName(item_id_value)) < int((recipe["inputs"] as Dictionary)[item_id_value]):
			machine["automation_status"] = "input_blocked"
			records[placement_id] = machine
			return {"operation": false}
	var output := recipe.get("output", {}) as Dictionary
	var output_entry := {"item_id": String(output.get("item_id", "")), "quantity": int(output.get("quantity", 0))}
	var output_result := _add_storage(target.get("storage", []) as Array, output_entry)
	if int(output_result["accepted"]) != int(output_entry["quantity"]):
		machine["automation_status"] = "output_blocked"
		records[placement_id] = machine
		return {"operation": false}
	var fuel_cost := int(recipe.get("fuel_cost", 0))
	var fuel_units := int(machine.get("automation_fuel_units", 0))
	if fuel_units < fuel_cost:
		var refueled := false
		var fuel_ids := _processing_catalog.fuel_item_ids()
		fuel_ids.reverse()
		for fuel_id in fuel_ids:
			var reserved := int((recipe.get("inputs", {}) as Dictionary).get(String(fuel_id), 0))
			if _storage_quantity(source_storage, fuel_id) <= reserved:
				continue
			var gained := _processing_catalog.fuel_units(fuel_id)
			var capacity := int(_building_catalog.piece(StringName(machine["piece_id"])).get("automation_fuel_capacity", 0))
			if fuel_units + gained > capacity:
				continue
			_remove_storage_item(source_storage, fuel_id, 1)
			fuel_units += gained
			refueled = true
			break
		machine["automation_fuel_units"] = fuel_units
		if fuel_units < fuel_cost:
			source["storage"] = source_storage
			machine["automation_status"] = "no_fuel"
			records[String(source["placement_id"])] = source
			records[placement_id] = machine
			return {"operation": refueled}
	for item_id_value in (recipe["inputs"] as Dictionary).keys():
		_remove_storage_item(source_storage, StringName(item_id_value), int((recipe["inputs"] as Dictionary)[item_id_value]))
	source["storage"] = source_storage
	target["storage"] = output_result["storage"]
	machine["automation_fuel_units"] = fuel_units - fuel_cost
	machine["automation_cycles"] = int(machine.get("automation_cycles", 0)) + 1
	machine["automation_status"] = "working"
	records[String(source["placement_id"])] = source
	records[String(target["placement_id"])] = target
	records[placement_id] = machine
	return {"operation": true}


func _replace_machine(record: Dictionary, message: String) -> Dictionary:
	var snapshot := _buildings.persistence_snapshot()
	var placements := snapshot.get("placements", []) as Array
	var replaced := false
	for index in placements.size():
		if String((placements[index] as Dictionary).get("placement_id", "")) == String(record["placement_id"]):
			placements[index] = record.duplicate(true)
			replaced = true
			break
	if not replaced or not _buildings.restore_snapshot(snapshot):
		return _fail("机器配置提交失败")
	last_error = ""
	return {"ok": true, "message": message, "placement": record.duplicate(true)}


func _record_map(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		var record := (value as Dictionary).duplicate(true)
		result[String(record["placement_id"])] = record
	return result


func _structure_at(records: Dictionary, tile: Vector2i) -> Dictionary:
	return (records.get("surface:%d:%d:structure" % [tile.x, tile.y], {}) as Dictionary).duplicate(true)


func _find_storage(records: Dictionary, origin: Vector2i, direction: Vector2i) -> Dictionary:
	for step in range(1, _catalog.connection_span_tiles() + 1):
		var record := _structure_at(records, origin + direction * step)
		if record.is_empty():
			return {}
		if StringName(record.get("piece_id", "")) == &"storage_chest":
			return record
		var kind := _building_catalog.automation_kind(StringName(record.get("piece_id", "")))
		if kind not in [&"transport", &"storage_link", &"sorter"]:
			return {}
	return {}


func _direction(rotation: int) -> Vector2i:
	match rotation:
		90: return Vector2i.RIGHT
		180: return Vector2i.DOWN
		270: return Vector2i.LEFT
		_: return Vector2i.UP


func _tile(record: Dictionary) -> Vector2i:
	var value := record.get("world_tile", [0, 0]) as Array
	return Vector2i(int(value[0]), int(value[1]))


func _first_storage_index(storage: Array, filter_id: StringName) -> int:
	for index in storage.size():
		if filter_id.is_empty() or StringName((storage[index] as Dictionary).get("item_id", "")) == filter_id:
			return index
	return -1


func _storage_quantity(storage: Array, item_id: StringName) -> int:
	var total := 0
	for value in storage:
		var entry := value as Dictionary
		if StringName(entry.get("item_id", "")) == item_id:
			total += int(entry.get("quantity", 0))
	return total


func _remove_storage_item(storage: Array, item_id: StringName, quantity: int) -> void:
	var remaining := quantity
	for index in range(storage.size() - 1, -1, -1):
		var entry := storage[index] as Dictionary
		if StringName(entry.get("item_id", "")) != item_id:
			continue
		var moved := mini(int(entry["quantity"]), remaining)
		entry["quantity"] = int(entry["quantity"]) - moved
		remaining -= moved
		if int(entry["quantity"]) <= 0:
			storage.remove_at(index)
		else:
			storage[index] = entry
		if remaining <= 0:
			return


func _remove_storage_quantity(storage: Array, index: int, quantity: int) -> void:
	var entry := storage[index] as Dictionary
	entry["quantity"] = int(entry["quantity"]) - quantity
	if int(entry["quantity"]) <= 0:
		storage.remove_at(index)
	else:
		storage[index] = entry


func _add_storage(storage_value: Array, entry_value: Dictionary) -> Dictionary:
	var storage: Array[Dictionary] = []
	for value in storage_value:
		storage.append((value as Dictionary).duplicate(true))
	var item_id := StringName(entry_value.get("item_id", ""))
	var remaining := int(entry_value.get("quantity", 0))
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
	for _slot in range(storage.size(), _building_catalog.chest_slot_count()):
		if remaining <= 0:
			break
		var moved := mini(maximum, remaining)
		var next := {"item_id": String(item_id), "quantity": moved}
		if durability > 0:
			next["durability"] = durability
		storage.append(next)
		remaining -= moved
	return {"accepted": int(entry_value.get("quantity", 0)) - remaining, "storage": storage}


func _changed_chunks(before_values: Array, after_values: Array) -> Array[Vector2i]:
	var before := _record_map(before_values)
	var after := _record_map(after_values)
	var changed: Dictionary = {}
	var ids := before.keys()
	for id in after.keys():
		if not ids.has(id):
			ids.append(id)
	for id in ids:
		if before.get(id, {}) == after.get(id, {}):
			continue
		var record := (after.get(id, before.get(id, {})) as Dictionary)
		if not record.is_empty():
			changed[WorldCoordinates.tile_to_chunk(_tile(record))] = true
	var result: Array[Vector2i] = []
	for coordinate in changed.keys():
		result.append(coordinate as Vector2i)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	return result


func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "changed": false, "message": message, "changed_chunks": []}
