class_name HomesteadState
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _catalog: HomesteadCatalog
var _building_catalog := BuildingCatalog.new()
var _bases: Dictionary = {}
var _active_base_id := ""
var _next_base_number := 1
var _last_teleport_seconds := -1.0


func _init(catalog := HomesteadCatalog.new()) -> void:
	_catalog = catalog


func base_count() -> int:
	return _bases.size()


func active_base_id() -> String:
	return _active_base_id


func active_base() -> Dictionary:
	return ((_bases.get(_active_base_id, {}) as Dictionary).duplicate(true))


func bases() -> Array[Dictionary]:
	return _sorted_records(_bases)


func base_for_tile(world_tile: Vector2i) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := _catalog.base_radius_tiles() + 1
	for value in _bases.values():
		var record := value as Dictionary
		var distance := _chebyshev_distance(world_tile, _tile_from_record(record))
		if distance > _catalog.base_radius_tiles():
			continue
		if distance < best_distance or (distance == best_distance and String(record["base_id"]) < String(best.get("base_id", ""))):
			best_distance = distance
			best = record.duplicate(true)
	return best


func synchronize_markers(buildings: BuildingState, established_seconds := 0.0) -> Dictionary:
	if buildings == null or not _catalog.is_valid():
		return _fail_result("家园配置或建筑状态不可用")
	var marker_placements := buildings.homestead_marker_placements()
	if marker_placements.size() > _catalog.max_bases():
		return _fail_result("家园数量超过配置上限")
	var marker_ids := {}
	for placement in marker_placements:
		marker_ids[String(placement["placement_id"])] = placement
	var changed := false
	for base_id_value in _bases.keys():
		var base_id := String(base_id_value)
		if marker_ids.has(base_id):
			continue
		_bases.erase(base_id)
		changed = true
	for placement in marker_placements:
		var base_id := String(placement["placement_id"])
		var tile := _tile_from_record(placement)
		if _bases.has(base_id):
			var existing := (_bases[base_id] as Dictionary).duplicate(true)
			if _tile_from_record(existing) != tile:
				existing["world_tile"] = [tile.x, tile.y]
				_bases[base_id] = existing
				changed = true
			continue
		var record := {
			"base_id": base_id,
			"display_name": _catalog.default_name(_next_base_number),
			"world_tile": [tile.x, tile.y],
			"established_seconds": maxf(0.0, established_seconds),
		}
		_bases[base_id] = record
		_next_base_number += 1
		changed = true
	if _bases.is_empty():
		if not _active_base_id.is_empty():
			_active_base_id = ""
			changed = true
	elif _active_base_id.is_empty() or not _bases.has(_active_base_id):
		_active_base_id = String(bases()[0]["base_id"])
		changed = true
	last_error = ""
	return {"ok": true, "changed": changed, "base_count": base_count(), "active_base_id": _active_base_id}


func set_active_home(base_id: String) -> Dictionary:
	if not _bases.has(base_id):
		return _fail_result("没有找到该基地")
	if _active_base_id == base_id:
		return {"ok": true, "changed": false, "message": "这里已经是当前家园", "base": active_base()}
	_active_base_id = base_id
	last_error = ""
	return {"ok": true, "changed": true, "message": "已设为当前家园：%s" % active_base()["display_name"], "base": active_base()}


func teleport_plan(game_seconds: float, world_layer: StringName, player_tile: Vector2i) -> Dictionary:
	if _active_base_id.is_empty() or not _bases.has(_active_base_id):
		return _fail_result("尚未建立家园；先在建造界面放置家园信标")
	if world_layer == &"dungeon":
		return _fail_result("地牢中不能使用家园传送")
	if not is_finite(game_seconds) or game_seconds < 0.0:
		return _fail_result("游戏时间无效")
	var remaining := cooldown_remaining(game_seconds)
	if remaining > 0.0:
		return _fail_result("家园传送冷却中：还需 %d 秒" % ceili(remaining))
	var home := active_base()
	var target_tile := _tile_from_record(home)
	if world_layer == &"surface" and _chebyshev_distance(player_tile, target_tile) <= 1:
		return _fail_result("你已经在当前家园")
	last_error = ""
	return {
		"ok": true,
		"message": "可以返回%s" % home["display_name"],
		"base_id": _active_base_id,
		"display_name": String(home["display_name"]),
		"world_tile": [target_tile.x, target_tile.y],
	}


func commit_home_teleport(game_seconds: float) -> bool:
	if not is_finite(game_seconds) or game_seconds < 0.0 or _active_base_id.is_empty():
		last_error = "无法提交家园传送时间"
		return false
	_last_teleport_seconds = game_seconds
	last_error = ""
	return true


func cooldown_remaining(game_seconds: float) -> float:
	if _last_teleport_seconds < 0.0 or not is_finite(game_seconds):
		return 0.0
	return maxf(0.0, _catalog.teleport_cooldown_seconds() - maxf(0.0, game_seconds - _last_teleport_seconds))


func status_snapshot(
	buildings: BuildingState,
	farming: FarmingState = null,
	husbandry: HusbandryState = null,
	game_seconds := 0.0,
	player_tile := Vector2i.ZERO,
	world_layer: StringName = &"surface"
) -> Dictionary:
	var base_views: Array[Dictionary] = []
	var inside := base_for_tile(player_tile) if world_layer == &"surface" else {}
	for base in bases():
		var base_id := String(base["base_id"])
		var asset_counts := _asset_counts(base_id, buildings, farming, husbandry)
		var steps := [
			{"id": "shelter", "display_name": "房屋", "complete": int(asset_counts["floors"]) > 0 and int(asset_counts["walls"]) > 0 and int(asset_counts["roofs"]) > 0},
			{"id": "storage", "display_name": "储物", "complete": int(asset_counts["storage_chests"]) > 0},
			{"id": "farming", "display_name": "农业", "complete": int(asset_counts["farm_plots"]) > 0},
			{"id": "husbandry", "display_name": "养殖", "complete": int(asset_counts["tamed_animals"]) > 0},
			{"id": "cooking", "display_name": "烹饪药水", "complete": int(asset_counts["cooking_pots"]) > 0},
			{"id": "smelting", "display_name": "冶炼", "complete": int(asset_counts["smelters"]) > 0},
			{"id": "enhancement", "display_name": "装备强化", "complete": int(asset_counts["workbenches"]) > 0 and int(asset_counts["smelters"]) > 0},
			{"id": "automation", "display_name": "基础自动化", "complete": int(asset_counts["automation_machines"]) > 0},
		]
		var completed := 0
		for step in steps:
			completed += 1 if bool((step as Dictionary)["complete"]) else 0
		var view := base.duplicate(true)
		view["radius_tiles"] = _catalog.base_radius_tiles()
		view["active"] = base_id == _active_base_id
		view["player_inside"] = String(inside.get("base_id", "")) == base_id
		view["distance_tiles"] = _chebyshev_distance(player_tile, _tile_from_record(base)) if world_layer == &"surface" else -1
		view["assets"] = asset_counts
		view["loop_steps"] = steps
		view["completed_steps"] = completed
		view["total_steps"] = steps.size()
		view["loop_complete"] = completed == steps.size()
		base_views.append(view)
	return {
		"schema_version": SCHEMA_VERSION,
		"base_count": base_count(),
		"base_limit": _catalog.max_bases(),
		"base_radius_tiles": _catalog.base_radius_tiles(),
		"minimum_spacing_tiles": _catalog.minimum_spacing_tiles(),
		"active_base_id": _active_base_id,
		"inside_base_id": String(inside.get("base_id", "")),
		"world_layer": String(world_layer),
		"teleport_cooldown_seconds": _catalog.teleport_cooldown_seconds(),
		"teleport_cooldown_remaining": cooldown_remaining(game_seconds),
		"bases": base_views,
	}


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"active_base_id": _active_base_id,
		"next_base_number": _next_base_number,
		"last_teleport_seconds": _last_teleport_seconds,
		"bases": bases(),
	}


func restore_snapshot(value: Dictionary, buildings: BuildingState = null) -> bool:
	if not _catalog.is_valid() or int(value.get("schema_version", 0)) != SCHEMA_VERSION \
			or not value.get("bases", []) is Array:
		return _restore_fail("家园状态格式无效")
	var next_number_value: Variant = value.get("next_base_number", 0)
	var last_seconds_value: Variant = value.get("last_teleport_seconds", -1.0)
	var active_id := String(value.get("active_base_id", ""))
	if not _is_integer_value(next_number_value) or int(next_number_value) < 1 or int(next_number_value) > 1000000 \
			or not (last_seconds_value is int or last_seconds_value is float) \
			or not is_finite(float(last_seconds_value)) or float(last_seconds_value) < -1.0:
		return _restore_fail("家园计数或传送时间无效")
	var base_values := value["bases"] as Array
	if base_values.size() > _catalog.max_bases():
		return _restore_fail("家园数量超过上限")
	var restored := {}
	var restored_tiles: Array[Vector2i] = []
	for base_value in base_values:
		if not base_value is Dictionary:
			return _restore_fail("家园记录必须是对象")
		var record := (base_value as Dictionary).duplicate(true)
		var base_id := String(record.get("base_id", ""))
		var display_name := String(record.get("display_name", "")).strip_edges()
		var tile_value: Variant = record.get("world_tile", [])
		var established_value: Variant = record.get("established_seconds", -1.0)
		if base_id.is_empty() or restored.has(base_id) or display_name.is_empty() or display_name.length() > 24 \
				or not tile_value is Array or (tile_value as Array).size() != 2 \
				or not _is_integer_value((tile_value as Array)[0]) or not _is_integer_value((tile_value as Array)[1]) \
				or not (established_value is int or established_value is float) \
				or not is_finite(float(established_value)) or float(established_value) < 0.0:
			return _restore_fail("家园记录字段无效")
		var tile := Vector2i(int((tile_value as Array)[0]), int((tile_value as Array)[1]))
		for previous_tile in restored_tiles:
			if _chebyshev_distance(tile, previous_tile) < _catalog.minimum_spacing_tiles():
				return _restore_fail("家园信标间距不足")
		restored_tiles.append(tile)
		restored[base_id] = {
			"base_id": base_id,
			"display_name": display_name,
			"world_tile": [tile.x, tile.y],
			"established_seconds": float(established_value),
		}
	if (restored.is_empty() and not active_id.is_empty()) or (not restored.is_empty() and not restored.has(active_id)):
		return _restore_fail("当前家园引用无效")
	if buildings != null:
		var marker_placements := buildings.homestead_marker_placements()
		if marker_placements.size() != restored.size():
			return _restore_fail("家园状态与信标建筑不一致")
		for placement in marker_placements:
			var marker_id := String(placement["placement_id"])
			if not restored.has(marker_id) or _tile_from_record(restored[marker_id] as Dictionary) != _tile_from_record(placement):
				return _restore_fail("家园状态缺少对应信标")
	_bases = restored
	_active_base_id = active_id
	_next_base_number = int(next_number_value)
	_last_teleport_seconds = float(last_seconds_value)
	last_error = ""
	return true


func _asset_counts(base_id: String, buildings: BuildingState, farming: FarmingState, husbandry: HusbandryState) -> Dictionary:
	var result := {
		"buildings": 0,
		"floors": 0,
		"walls": 0,
		"roofs": 0,
		"storage_chests": 0,
		"stored_items": 0,
		"workbenches": 0,
		"cooking_pots": 0,
		"smelters": 0,
		"automation_machines": 0,
		"farm_plots": 0,
		"mature_crops": 0,
		"animals": 0,
		"tamed_animals": 0,
		"ready_products": 0,
	}
	if buildings != null:
		for placement in buildings.placements():
			if String(base_for_tile(_tile_from_record(placement)).get("base_id", "")) != base_id:
				continue
			var piece_id := StringName(placement["piece_id"])
			if piece_id == _catalog.marker_piece_id():
				continue
			result["buildings"] = int(result["buildings"]) + 1
			var definition := _building_catalog.piece(piece_id)
			match StringName(definition.get("placement_slot", "")):
				&"ground": result["floors"] = int(result["floors"]) + 1
				&"roof": result["roofs"] = int(result["roofs"]) + 1
			if StringName(definition.get("category", "")) in [&"wall", &"door"]:
				result["walls"] = int(result["walls"]) + 1
			if StringName(definition.get("interactive", "")) == &"storage":
				result["storage_chests"] = int(result["storage_chests"]) + 1
				for entry in placement.get("storage", []) as Array:
					result["stored_items"] = int(result["stored_items"]) + int((entry as Dictionary).get("quantity", 0))
			match StringName(definition.get("station_kind", "")):
				&"workbench": result["workbenches"] = int(result["workbenches"]) + 1
				&"cooking_pot": result["cooking_pots"] = int(result["cooking_pots"]) + 1
				&"smelter": result["smelters"] = int(result["smelters"]) + 1
			if not StringName(definition.get("automation_kind", "")).is_empty():
				result["automation_machines"] = int(result["automation_machines"]) + 1
				if piece_id == &"automatic_smelter":
					result["smelters"] = int(result["smelters"]) + 1
	if farming != null:
		for plot in farming.plots():
			if String(base_for_tile(_tile_from_record(plot)).get("base_id", "")) != base_id:
				continue
			result["farm_plots"] = int(result["farm_plots"]) + 1
			result["mature_crops"] = int(result["mature_crops"]) + (1 if bool(plot.get("mature", false)) else 0)
	if husbandry != null:
		for animal in husbandry.animals():
			if String(base_for_tile(_tile_from_record(animal)).get("base_id", "")) != base_id:
				continue
			result["animals"] = int(result["animals"]) + 1
			result["tamed_animals"] = int(result["tamed_animals"]) + (1 if bool(animal.get("tamed", false)) else 0)
			result["ready_products"] = int(result["ready_products"]) + int(animal.get("product_ready", 0))
	return result


func _sorted_records(source: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in source.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(_base_less)
	return result


func _base_less(a: Dictionary, b: Dictionary) -> bool:
	var tile_a := _tile_from_record(a)
	var tile_b := _tile_from_record(b)
	if tile_a.y != tile_b.y:
		return tile_a.y < tile_b.y
	if tile_a.x != tile_b.x:
		return tile_a.x < tile_b.x
	return String(a["base_id"]) < String(b["base_id"])


func _tile_from_record(record: Dictionary) -> Vector2i:
	var value := record.get("world_tile", [0, 0]) as Array
	return Vector2i(int(value[0]), int(value[1]))


func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _is_integer_value(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(float(value), floorf(float(value))))


func _fail_result(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}


func _restore_fail(message: String) -> bool:
	last_error = message
	return false
