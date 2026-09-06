class_name NpcDirector
extends Node

signal inventory_mutated
signal sleep_requested(npc_id: String, display_name: String)
signal npc_talked(npc_id: String, role_id: StringName)
signal trade_completed(role_id: StringName)

var _world_seed := 0
var _player: PlayerCharacter
var _inventory: InventoryModel
var _terrain: TerrainGenerator
var _world_state: NpcWorldState
var _relationship_state: RelationshipState
var _relationship_catalog: RelationshipCatalog
var _catalog: NpcCatalog
var _planner: NpcPlanner
var _item_catalog := ItemCatalog.new()
var _world_layer: StringName = &"surface"
var _actors: Dictionary = {}
var _layouts: Dictionary = {}
var _schedule_keys: Dictionary = {}
var _time_state := {"phase": &"DAWN", "progress": 0.0, "day": 1}
var _refresh_elapsed := 0.0
var _current_npc_id := ""


func configure(
	world_seed: int,
	player: PlayerCharacter,
	inventory: InventoryModel,
	terrain: TerrainGenerator,
	world_state: NpcWorldState,
	relationship_state: RelationshipState,
	world_layer: StringName = &"surface",
	catalog := NpcCatalog.new(),
	relationship_catalog := RelationshipCatalog.new()
) -> void:
	_world_seed = world_seed
	_player = player
	_inventory = inventory
	_terrain = terrain
	_world_state = world_state
	_relationship_state = relationship_state
	_relationship_catalog = relationship_catalog
	_world_layer = world_layer
	_catalog = catalog
	_planner = NpcPlanner.new(world_seed, catalog)


func _ready() -> void:
	if _player == null or _inventory == null or _terrain == null or _world_state == null \
			or _relationship_state == null or _relationship_catalog == null or not _relationship_catalog.is_valid() \
			or _catalog == null or not _catalog.is_valid():
		push_error("NpcDirector requires valid configuration before entering the scene tree")
		set_process(false)
		return
	refresh_now()


func _process(delta: float) -> void:
	_refresh_elapsed += maxf(delta, 0.0)
	if _refresh_elapsed >= 0.5:
		_refresh_elapsed = 0.0
		refresh_now()


func catalog() -> NpcCatalog:
	return _catalog


func world_state() -> NpcWorldState:
	return _world_state


func active_count() -> int:
	return _actors.size()


func sleeping_count() -> int:
	var count := 0
	for value in _actors.values():
		count += 1 if (value as NpcActor).is_sleeping() else 0
	return count


func actor(npc_id: String) -> NpcActor:
	return _actors.get(npc_id) as NpcActor


func actor_ids() -> Array[String]:
	var ids: Array[String] = []
	for value in _actors.keys():
		ids.append(String(value))
	ids.sort()
	return ids


func update_time(snapshot: Dictionary) -> void:
	_time_state = snapshot.duplicate(true)
	for npc_id in _actors.keys():
		_apply_schedule(String(npc_id), false)
	EventBus.npc_state_changed.emit(status_snapshot())


func set_world_layer(layer: StringName) -> void:
	if layer == _world_layer:
		return
	_world_layer = layer
	if _world_layer != &"surface":
		_clear_actors()
	else:
		refresh_now()
	close_interaction()


func refresh_now() -> void:
	if _world_layer != &"surface" or _player == null:
		_clear_actors()
		return
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	var center_region := _planner.region_for_tile(player_tile)
	var desired := {}
	for y in range(center_region.y - 1, center_region.y + 2):
		for x in range(center_region.x - 1, center_region.x + 2):
			var plan := _planner.plan_for_region(Vector2i(x, y), _terrain)
			if plan.is_empty():
				continue
			var village := plan["village"] as Dictionary
			var village_id := String(village["key"])
			_layouts[village_id] = (plan.get("cells", {}) as Dictionary).duplicate()
			for value in plan.get("npcs", []) as Array:
				var npc_plan := value as Dictionary
				var home := npc_plan["home_tile"] as Vector2i
				if maxi(absi(home.x - player_tile.x), absi(home.y - player_tile.y)) > _catalog.active_radius_tiles():
					continue
				var npc_id := String(npc_plan["id"])
				desired[npc_id] = true
				if not _actors.has(npc_id):
					_spawn_actor(npc_plan)
	for npc_id in _actors.keys():
		if desired.has(npc_id):
			continue
		var old_actor := _actors[npc_id] as NpcActor
		old_actor.queue_free()
		_actors.erase(npc_id)
		_schedule_keys.erase(npc_id)
	if not _current_npc_id.is_empty() and not _actors.has(_current_npc_id):
		close_interaction()


func prompt_text() -> String:
	var target := nearest_actor()
	if target == null:
		return ""
	var plan := target.plan()
	if target.is_sleeping():
		return "%s正在休息" % String(plan.get("display_name", "村民"))
	return "[E] 与%s交谈 · %s" % [String(plan.get("display_name", "村民")), target.activity_display_name()]


func nearest_actor(radius_pixels := -1.0) -> NpcActor:
	if _world_layer != &"surface" or _player == null:
		return null
	var radius := _catalog.interaction_radius_pixels() if radius_pixels < 0.0 else radius_pixels
	var best: NpcActor
	var best_distance := radius * radius
	for value in _actors.values():
		var candidate := value as NpcActor
		var distance := _player.global_position.distance_squared_to(candidate.global_position)
		if distance > best_distance:
			continue
		best = candidate
		best_distance = distance
	return best


func try_interact() -> bool:
	var target := nearest_actor()
	if target == null:
		return false
	var plan := target.plan()
	if target.is_sleeping():
		EventBus.interaction_feedback.emit("%s正在休息，稍后再来" % String(plan.get("display_name", "村民")), false)
		return true
	_current_npc_id = target.npc_id()
	_world_state.record_talk(_current_npc_id, int(_time_state.get("day", 1)))
	npc_talked.emit(_current_npc_id, StringName(plan.get("role_id", "")))
	var snapshot := current_interaction_snapshot()
	EventBus.npc_interaction_requested.emit(snapshot)
	EventBus.npc_state_changed.emit(snapshot)
	return true


func continue_current_dialogue() -> Dictionary:
	if _current_npc_id.is_empty() or not _actors.has(_current_npc_id):
		return {}
	_world_state.record_talk(_current_npc_id, int(_time_state.get("day", 1)))
	var snapshot := current_interaction_snapshot()
	EventBus.npc_state_changed.emit(snapshot)
	return snapshot


func close_interaction() -> void:
	_current_npc_id = ""


func current_interaction_snapshot() -> Dictionary:
	var target := _actors.get(_current_npc_id) as NpcActor
	if target == null:
		return {}
	var plan := target.plan()
	var role_id := StringName(plan.get("role_id", ""))
	var role := _catalog.role(role_id)
	var record := _world_state.record_for(_current_npc_id)
	var phase := StringName(_time_state.get("phase", &"DAY"))
	var village_id := String(plan.get("village_id", ""))
	var day := int(_time_state.get("day", 1))
	var relationship := _relationship_state.status_snapshot(_current_npc_id, village_id, _relationship_catalog, day)
	var affection := int(relationship["affection"])
	var reputation := int(relationship["village_reputation"])
	var hostile := String(relationship["tier_id"]) == "hostile"
	var offers: Array[Dictionary] = []
	for value in ([] if hostile else role.get("offers", [])) as Array:
		var offer := (value as Dictionary).duplicate(true)
		var item_id := StringName(offer["item_id"])
		offer["base_price"] = int(offer["price"])
		offer["price"] = _relationship_catalog.adjusted_buy_price(int(offer["price"]), affection, reputation)
		offer["display_name"] = _item_catalog.display_name(item_id)
		offer["can_trade"] = _inventory.quantity(&"coin") >= int(offer["price"])
		offers.append(offer)
	var buys: Array[Dictionary] = []
	for value in ([] if hostile else role.get("buys", [])) as Array:
		var buy := (value as Dictionary).duplicate(true)
		var item_id := StringName(buy["item_id"])
		buy["base_price"] = int(buy["price"])
		buy["price"] = _relationship_catalog.adjusted_sell_price(int(buy["price"]), affection, reputation)
		buy["display_name"] = _item_catalog.display_name(item_id)
		buy["owned"] = _inventory.quantity(item_id)
		buy["can_trade"] = int(buy["owned"]) >= int(buy["quantity"])
		buys.append(buy)
	var gifts: Array[Dictionary] = []
	var counts := _inventory.count_snapshot()
	var gift_ids: Array[String] = []
	for item_value in counts.keys():
		var gift_id := String(item_value)
		if gift_id != "coin" and int(counts[item_value]) > 0 and not _item_catalog.is_durable(StringName(gift_id)):
			gift_ids.append(gift_id)
	gift_ids.sort()
	for gift_id in gift_ids:
		gifts.append({
			"item_id": gift_id,
			"display_name": _item_catalog.display_name(StringName(gift_id)),
			"owned": int(counts[gift_id]),
			"affection_delta": _relationship_catalog.gift_value(role_id, StringName(gift_id)),
			"can_gift": bool(relationship["can_gift_today"]),
		})
	var base_dialogue := _catalog.dialogue(role_id, phase, maxi(0, int(record["talk_count"]) - 1))
	var relationship_dialogue := _relationship_catalog.dialogue(StringName(relationship["tier_id"]), int(record["talk_count"]))
	var services := ["dialogue"] if hostile else (role.get("services", []) as Array).duplicate()
	return {
		"open": true,
		"npc_id": _current_npc_id,
		"display_name": String(plan.get("display_name", "村民")),
		"role_id": String(role_id),
		"role_display_name": String(plan.get("role_display_name", "村民")),
		"activity": String(target.activity()),
		"activity_display": target.activity_display_name(),
		"dialogue": relationship_dialogue if hostile else "%s %s" % [relationship_dialogue, base_dialogue],
		"services": services,
		"offers": offers,
		"buys": buys,
		"gifts": gifts,
		"relationship": relationship,
		"coin_count": _inventory.quantity(&"coin"),
		"record": record,
	}


func buy_current(item_id: StringName) -> Dictionary:
	var trade := _trade_entry("offers", item_id)
	if trade.is_empty():
		return _trade_failure("这件商品当前不出售")
	var price := int(trade["price"])
	if _inventory.quantity(&"coin") < price:
		return _trade_failure("边境币不足")
	var before := _inventory.snapshot()
	_inventory.remove_item(&"coin", price)
	var add_result := _inventory.add_item(item_id, int(trade["quantity"]))
	if int(add_result["remainder"]) > 0:
		_inventory.restore_snapshot(before)
		return _trade_failure("背包空间不足，交易已撤销")
	_world_state.record_trade(_current_npc_id, &"buy", price, int(_time_state.get("day", 1)))
	_record_relationship_trade()
	inventory_mutated.emit()
	EventBus.interaction_feedback.emit("购买%s ×%d" % [_item_catalog.display_name(item_id), int(trade["quantity"])], true)
	return _trade_success()


func sell_current(item_id: StringName) -> Dictionary:
	var trade := _trade_entry("buys", item_id)
	if trade.is_empty():
		return _trade_failure("这件物品当前不收购")
	var quantity := int(trade["quantity"])
	if _inventory.quantity(item_id) < quantity:
		return _trade_failure("物品数量不足")
	var before := _inventory.snapshot()
	_inventory.remove_item(item_id, quantity)
	var add_result := _inventory.add_item(&"coin", int(trade["price"]))
	if int(add_result["remainder"]) > 0:
		_inventory.restore_snapshot(before)
		return _trade_failure("背包空间不足，交易已撤销")
	_world_state.record_trade(_current_npc_id, &"sell", int(trade["price"]), int(_time_state.get("day", 1)))
	_record_relationship_trade()
	inventory_mutated.emit()
	EventBus.interaction_feedback.emit("出售%s ×%d" % [_item_catalog.display_name(item_id), quantity], true)
	return _trade_success()


func request_sleep_current() -> bool:
	var target := _actors.get(_current_npc_id) as NpcActor
	if target == null:
		return false
	var plan := target.plan()
	if _relationship_state.tier_id(_current_npc_id, _relationship_catalog) == &"hostile":
		EventBus.interaction_feedback.emit("对方拒绝为你提供服务", false)
		return false
	if not _catalog.has_service(StringName(plan.get("role_id", "")), &"sleep"):
		return false
	sleep_requested.emit(_current_npc_id, String(plan.get("display_name", "旅店老板")))
	close_interaction()
	return true


func gift_current(item_id: StringName) -> Dictionary:
	var target := _actors.get(_current_npc_id) as NpcActor
	if target == null or target.is_sleeping() or item_id == &"coin" or _item_catalog.is_durable(item_id):
		return _trade_failure("这件物品不能作为礼物")
	if _inventory.quantity(item_id) < 1:
		return _trade_failure("背包中没有这件礼物")
	var plan := target.plan()
	var before_inventory := _inventory.snapshot()
	var before_relationship := _relationship_state.persistence_snapshot()
	_inventory.remove_item(item_id, 1)
	var result := _relationship_state.apply_gift(
		_current_npc_id,
		String(plan.get("village_id", "")),
		StringName(plan.get("role_id", "")),
		item_id,
		int(_time_state.get("day", 1)),
		_relationship_catalog
	)
	if not bool(result.get("ok", false)):
		_inventory.restore_snapshot(before_inventory)
		return _trade_failure(String(result.get("message", "赠礼失败")))
	var reward_names: Array[String] = []
	for value in result.get("rewards", []) as Array:
		var reward := value as Dictionary
		var reward_id := StringName(reward["item_id"])
		var add_result := _inventory.add_item(reward_id, int(reward["quantity"]))
		if int(add_result["remainder"]) > 0:
			_inventory.restore_snapshot(before_inventory)
			_relationship_state.restore_snapshot(before_relationship)
			return _trade_failure("背包空间不足，赠礼与奖励已撤销")
		reward_names.append("%s ×%d" % [_item_catalog.display_name(reward_id), int(reward["quantity"])])
	inventory_mutated.emit()
	var message := "赠送%s，好感 %+d" % [_item_catalog.display_name(item_id), int(result["affection_delta"])]
	if not reward_names.is_empty():
		message += " · 获得 " + "、".join(reward_names)
	EventBus.interaction_feedback.emit(message, true)
	var state := current_interaction_snapshot()
	EventBus.relationship_state_changed.emit(state.get("relationship", {}) as Dictionary)
	EventBus.npc_state_changed.emit(state)
	return {"ok": true, "message": message, "state": state}


func status_snapshot() -> Dictionary:
	return {
		"open": not _current_npc_id.is_empty(),
		"active_count": active_count(),
		"sleeping_count": sleeping_count(),
		"record_count": _world_state.record_count() if _world_state != null else 0,
		"world_layer": String(_world_layer),
	}


func _record_relationship_trade() -> void:
	var target := _actors.get(_current_npc_id) as NpcActor
	if target == null:
		return
	var role_id := StringName(target.plan().get("role_id", ""))
	_relationship_state.record_trade(_current_npc_id, String(target.plan().get("village_id", "")), _relationship_catalog)
	EventBus.relationship_state_changed.emit(
		_relationship_state.status_snapshot(
			_current_npc_id,
			String(target.plan().get("village_id", "")),
			_relationship_catalog,
			int(_time_state.get("day", 1))
		)
	)
	trade_completed.emit(role_id)


func _spawn_actor(plan: Dictionary) -> void:
	var actor := NpcActor.new()
	actor.configure(plan, _catalog.movement_speed_pixels())
	add_child(actor)
	_actors[String(plan["id"])] = actor
	_apply_schedule(String(plan["id"]), true)


func _apply_schedule(npc_id: String, force := false) -> void:
	var actor_value := _actors.get(npc_id) as NpcActor
	if actor_value == null:
		return
	var plan := actor_value.plan()
	var entry := _catalog.schedule_at(StringName(plan.get("role_id", "")), float(_time_state.get("progress", 0.0)))
	if entry.is_empty():
		return
	var schedule_key := "%s|%s" % [entry.get("activity", "idle"), entry.get("location", "home")]
	if not force and String(_schedule_keys.get(npc_id, "")) == schedule_key:
		return
	_schedule_keys[npc_id] = schedule_key
	var locations := plan.get("locations", {}) as Dictionary
	var target := locations.get(String(entry.get("location", "home")), plan["home_tile"]) as Vector2i
	var passable := _layouts.get(String(plan.get("village_id", "")), {}) as Dictionary
	var path := NpcPathfinder.find_path(passable, actor_value.current_world_tile(), target)
	if path.is_empty():
		path = [actor_value.current_world_tile(), target]
	actor_value.set_schedule(entry, path)


func _trade_entry(key: String, item_id: StringName) -> Dictionary:
	var target := _actors.get(_current_npc_id) as NpcActor
	if target == null or target.is_sleeping():
		return {}
	var role := _catalog.role(StringName(target.plan().get("role_id", "")))
	if not (role.get("services", []) as Array).has("shop"):
		return {}
	if _relationship_state.tier_id(_current_npc_id, _relationship_catalog) == &"hostile":
		return {}
	var plan := target.plan()
	var village_id := String(plan.get("village_id", ""))
	var affection := _relationship_state.affection(_current_npc_id)
	var reputation := _relationship_state.village_reputation(village_id)
	for value in role.get(key, []) as Array:
		if StringName((value as Dictionary).get("item_id", "")) == item_id:
			var trade := (value as Dictionary).duplicate(true)
			trade["base_price"] = int(trade["price"])
			trade["price"] = _relationship_catalog.adjusted_buy_price(int(trade["price"]), affection, reputation) \
				if key == "offers" else _relationship_catalog.adjusted_sell_price(int(trade["price"]), affection, reputation)
			return trade
	return {}


func _trade_failure(message: String) -> Dictionary:
	EventBus.interaction_feedback.emit(message, false)
	return {"ok": false, "message": message, "state": current_interaction_snapshot()}


func _trade_success() -> Dictionary:
	var state := current_interaction_snapshot()
	EventBus.npc_state_changed.emit(state)
	return {"ok": true, "message": "交易完成", "state": state}


func _clear_actors() -> void:
	for value in _actors.values():
		(value as NpcActor).queue_free()
	_actors.clear()
	_layouts.clear()
	_schedule_keys.clear()
