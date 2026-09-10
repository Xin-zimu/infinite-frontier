class_name ChunkStreamManager
extends Node

signal metrics_changed(metrics: Dictionary)

const MAX_CONCURRENT_JOBS := 4

var _world_seed := 0
var _player: PlayerCharacter
var _current_chunk := Vector2i.ZERO
var _movement_direction := Vector2i.ZERO
var _cache: Dictionary = {}
var _renderers: Dictionary = {}
var _queue: Array[Vector2i] = []
var _jobs: Dictionary = {}
var _task_ids: Dictionary = {}
var _preload_targets: Dictionary = {}
var _catalog := BiomeCatalog.new()
var _resource_catalog := ResourceCatalog.new()
var _item_catalog := ItemCatalog.new()
var _weapon_catalog := WeaponCatalog.new()
var _harvest_state := ResourceHarvestState.new()
var _tool_ids: Array[StringName] = []
var _crafting_system: CraftingSystem
var _grave_model := GraveModel.new()
var _grave_markers: Dictionary = {}
var _drop_pool: WorldDropPool
var _enemy_director: EnemyDirector
var _milestone_catalog := MilestoneCatalog.new()
var _milestone_state := MilestoneState.new()
var _ruin_encounter: RuinEncounter
var _pending_persistence: Dictionary = {}
var _view_mode := ChunkRenderer.ViewMode.TERRAIN
var _show_boundaries := true
var _completed_total := 0
var _unloaded_total := 0
var _peak_cache := 0
var _peak_memory_mb := 0.0
var _metrics_elapsed := 0.0
var _prompt_elapsed := 0.0
var _time_phase: StringName = &"DAWN"
var _weather_resource_multiplier := 1.0
var _world_event_resource_multiplier := 1.0
var _season_resource_multiplier := 1.0
var _season_crop_growth_multiplier := 1.0
var _world_event_time_seconds := 0.0
var _world_event_display_second := -1
var _world_layer: StringName = &"surface"
var _opened_cave_chests: Dictionary = {}
var _cave_catalog := CaveCatalog.new()
var _dungeon_catalog := DungeonCatalog.new()
var _dungeon_state := DungeonRunState.new()
var _exploration_state := ExplorationMapState.new()
var _discovery_scanner: WorldDiscoveryScanner
var _regional_boss_state := RegionalBossState.new()
var _regional_boss_planner: RegionalBossPlanner
var _npc_state := NpcWorldState.new()
var _relationship_state := RelationshipState.new()
var _npc_director: NpcDirector
var _quest_catalog := QuestCatalog.new()
var _quest_state := QuestState.new()
var _world_choice_state := WorldChoiceState.new()
var _quest_day := 1
var _faction_catalog := FactionCatalog.new()
var _faction_state := FactionState.new(_faction_catalog)
var _world_event_catalog := WorldEventCatalog.new()
var _world_event_planner: WorldEventPlanner
var _world_event_state := WorldEventState.new()
var _region_progression_catalog := RegionProgressionCatalog.new()
var _region_progression_model: RegionProgressionModel
var _region_progression_state := RegionProgressionState.new()
var _building_catalog := BuildingCatalog.new()
var _building_state := BuildingState.new(_building_catalog, _item_catalog)
var _nearby_building_stations: Array[StringName] = []
var _farming_catalog := FarmingCatalog.new()
var _farming_state := FarmingState.new(0, _farming_catalog, _item_catalog)
var _current_weather_id: StringName = &"CLEAR"
var _husbandry_catalog := HusbandryCatalog.new()
var _husbandry_state := HusbandryState.new(0, _husbandry_catalog, _item_catalog)
var _husbandry_planner: HusbandryPlanner
var _processing_catalog := ProcessingCatalog.new()
var _processing_system: ProcessingSystem
var _automation_catalog := AutomationCatalog.new()
var _automation_system: AutomationSystem
var _homestead_catalog := HomesteadCatalog.new()
var _homestead_state := HomesteadState.new(_homestead_catalog)
var _equipment_catalog := EquipmentCatalog.new()
var _equipment_state := EquipmentState.new(_equipment_catalog, _item_catalog)
var _ocean_catalog := OceanCatalog.new()
var _boat_state := BoatState.new(_ocean_catalog)
var _boat_layer: BoatLayer
var _boarded_boat_id := ""
var _boat_last_water_tile := Vector2i.ZERO


func configure(world_seed: int, player: PlayerCharacter, initial_chunk: ChunkData = null, world_layer: StringName = &"surface") -> void:
	_world_seed = world_seed
	_farming_state = FarmingState.new(_world_seed, _farming_catalog, _item_catalog)
	_husbandry_state = HusbandryState.new(_world_seed, _husbandry_catalog, _item_catalog)
	_husbandry_planner = HusbandryPlanner.new(_world_seed, _husbandry_catalog)
	_player = player
	_world_layer = world_layer
	_world_event_planner = WorldEventPlanner.new(_world_seed, _world_event_catalog)
	_region_progression_model = RegionProgressionModel.new(_world_seed, _region_progression_catalog)
	_current_chunk = WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(player.global_position))
	if initial_chunk != null:
		_cache[initial_chunk.chunk_position] = initial_chunk


func _ready() -> void:
	if _player == null:
		push_error("ChunkStreamManager requires a configured player before entering the scene tree.")
		set_process(false)
		return
	_tool_ids = _resource_catalog.tool_ids()
	_discovery_scanner = WorldDiscoveryScanner.new(_world_seed)
	_regional_boss_planner = RegionalBossPlanner.new(_world_seed)
	if _world_event_planner == null:
		_world_event_planner = WorldEventPlanner.new(_world_seed, _world_event_catalog)
	if _region_progression_model == null:
		_region_progression_model = RegionProgressionModel.new(_world_seed, _region_progression_catalog)
	if _husbandry_planner == null:
		_husbandry_planner = HusbandryPlanner.new(_world_seed, _husbandry_catalog)
	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.weather_state_changed.connect(_on_weather_state_changed)
	_crafting_system = CraftingSystem.new(_harvest_state.inventory_model())
	_processing_system = ProcessingSystem.new(_harvest_state.inventory_model(), _building_state, _processing_catalog)
	_automation_system = AutomationSystem.new(_building_state, _automation_catalog, _building_catalog, _processing_catalog, _item_catalog)
	_restore_pending_persistence()
	_update_building_context()
	_drop_pool = WorldDropPool.new()
	_drop_pool.configure(_resource_catalog.drop_pool_capacity(), _resource_catalog)
	add_child(_drop_pool)
	_boat_layer = BoatLayer.new()
	_boat_layer.z_index = 3
	add_child(_boat_layer)
	_refresh_boat_layer()
	_enemy_director = EnemyDirector.new()
	_enemy_director.configure(_world_seed, _player, _drop_pool, _world_layer, _dungeon_context())
	_enemy_director.update_regional_boss_state(_regional_boss_state.persistence_snapshot())
	_enemy_director.update_region_progression_state(region_progression_snapshot())
	_enemy_director.dungeon_enemy_defeated.connect(_on_dungeon_enemy_defeated)
	_enemy_director.regional_boss_defeated.connect(_on_regional_boss_defeated)
	_enemy_director.enemy_defeated.connect(_on_enemy_defeated_for_quest)
	_enemy_director.progression_enemy_defeated.connect(_on_progression_enemy_defeated)
	add_child(_enemy_director)
	_apply_world_event_effects()
	_npc_director = NpcDirector.new()
	_npc_director.configure(
		_world_seed,
		_player,
		_harvest_state.inventory_model(),
		TerrainGenerator.new(_world_seed),
		_npc_state,
		_relationship_state,
		_world_layer
	)
	_npc_director.inventory_mutated.connect(_emit_tool_and_inventory)
	_npc_director.npc_talked.connect(_on_npc_talked_for_quest)
	_npc_director.trade_completed.connect(_on_npc_trade_completed)
	_npc_director.sleep_requested.connect(func(npc_id: String, display_name: String) -> void:
		EventBus.sleep_requested.emit(npc_id, display_name)
	)
	add_child(_npc_director)
	var ruin_plan := RuinPlanner.new(_world_seed, _milestone_catalog).plan()
	if ruin_plan.is_empty():
		push_error("Unable to plan the canonical ruin: %s" % _milestone_catalog.error_message())
	else:
		_ruin_encounter = RuinEncounter.new()
		_ruin_encounter.configure(ruin_plan, _player, _milestone_state, _milestone_catalog)
		_ruin_encounter.milestone_changed.connect(func(_snapshot: Dictionary) -> void: _emit_metrics())
		add_child(_ruin_encounter)
		_ruin_encounter.set_world_layer(_world_layer)
	_refresh_grave_markers()
	_refresh_targets()
	_update_exploration()
	_update_building_context()
	_emit_building_state()
	_emit_farming_state()
	_emit_husbandry_state()
	_emit_processing_state()
	_emit_automation_state()
	_apply_equipment_effects()
	_emit_equipment_state()
	_emit_metrics()
	_emit_tool_and_inventory()


func _process(delta: float) -> void:
	_collect_completed_jobs()
	_collect_nearby_drops()
	var next_chunk := WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	var next_direction := _direction_from_velocity(_player.velocity)
	var chunk_changed := next_chunk != _current_chunk
	var targets_changed := chunk_changed
	if next_direction != Vector2i.ZERO and next_direction != _movement_direction:
		_movement_direction = next_direction
		targets_changed = true
	if next_chunk != _current_chunk:
		_current_chunk = next_chunk
	if targets_changed:
		_refresh_targets()
	if chunk_changed:
		_update_exploration()
	_dispatch_jobs()
	_metrics_elapsed += delta
	if _metrics_elapsed >= 0.2:
		_metrics_elapsed = 0.0
		_emit_metrics()
	_prompt_elapsed += delta
	if _prompt_elapsed >= 0.10:
		_prompt_elapsed = 0.0
		_update_building_context()
		_update_resource_prompt()
	_process_dungeon_trap()
	_update_boat_follow()


func _exit_tree() -> void:
	_wait_for_all_jobs()


func toggle_noise_view() -> void:
	_view_mode = (_view_mode + 1) % (ChunkRenderer.ViewMode.ELEVATION + 1)
	_update_renderer_debug_options()
	_emit_metrics()


func toggle_chunk_boundaries() -> void:
	_show_boundaries = not _show_boundaries
	_update_renderer_debug_options()
	_emit_metrics()


func cycle_active_tool() -> void:
	var inventory := _harvest_state.inventory_model()
	var start := inventory.selected_hotbar_slot()
	for offset in range(1, inventory.hotbar_slot_count() + 1):
		var candidate := posmod(start + offset, inventory.hotbar_slot_count())
		var value := inventory.slot(candidate)
		if value.is_empty():
			continue
		var kind := _item_catalog.tool_kind(StringName(value["item_id"]))
		if kind.is_empty():
			continue
		inventory.select_hotbar(candidate)
		_emit_tool_and_inventory()
		EventBus.interaction_feedback.emit("已切换到%s" % active_tool_display_name(), true)
		_update_resource_prompt()
		return
	EventBus.interaction_feedback.emit("快捷栏中没有可以切换的工具", false)


func active_tool_id() -> StringName:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty():
		return &"hands"
	var kind := _item_catalog.tool_kind(StringName(value["item_id"]))
	return kind if not kind.is_empty() else &"hands"


func selected_item_id() -> StringName:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	return StringName(value.get("item_id", "")) if not value.is_empty() else &""


func consume_selected_item(expected_item_id: StringName, quantity := 1) -> bool:
	var inventory := _harvest_state.inventory_model()
	var index := inventory.selected_hotbar_slot()
	var selected := inventory.slot(index)
	if quantity <= 0 or StringName(selected.get("item_id", "")) != expected_item_id or int(selected.get("quantity", 0)) < quantity:
		return false
	var removed := inventory.discard(index, quantity)
	if int(removed.get("quantity", 0)) != quantity:
		return false
	_emit_tool_and_inventory()
	_update_resource_prompt()
	return true


func building_preview(piece_id: StringName, world_tile: Vector2i, rotation: int) -> Dictionary:
	var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
	var chunk := _cache.get(coordinate) as ChunkData
	if chunk == null:
		return {
			"valid": false,
			"reason": "目标区块尚未载入",
			"piece_id": String(piece_id),
			"world_tile": world_tile,
			"rotation": rotation,
			"color": "d65f5f",
		}
	return _building_state.preview(piece_id, world_tile, rotation, _building_context(world_tile, chunk))


func place_building(piece_id: StringName, world_tile: Vector2i, rotation: int) -> Dictionary:
	var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
	var chunk := _cache.get(coordinate) as ChunkData
	if chunk == null:
		var unavailable := {"ok": false, "message": "目标区块尚未载入"}
		EventBus.interaction_feedback.emit(unavailable["message"], false)
		return unavailable
	var result := _building_state.place(
		piece_id,
		world_tile,
		rotation,
		_building_context(world_tile, chunk),
		_harvest_state.inventory_model()
	)
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	if bool(result["ok"]):
		_sync_homestead_markers()
		_refresh_player_buildings(coordinate)
		_emit_tool_and_inventory()
		_update_building_context()
		_emit_building_state()
		_emit_automation_state()
	return result


func demolish_building(world_tile: Vector2i) -> Dictionary:
	var result := _building_state.demolish_at(world_tile, _harvest_state.inventory_model())
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	if bool(result["ok"]):
		_sync_homestead_markers()
		_refresh_player_buildings(WorldCoordinates.tile_to_chunk(world_tile))
		_emit_tool_and_inventory()
		_update_building_context()
		_emit_building_state()
		_emit_automation_state()
	return result


func try_interact_player_building(radius_tiles := 2) -> bool:
	if _world_layer != &"surface" or _player == null:
		return false
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	var target := _building_state.nearest_interaction(player_tile, radius_tiles)
	if target.is_empty():
		return false
	var interaction := StringName(target.get("interaction", ""))
	var result: Dictionary
	if interaction == &"door":
		result = _building_state.toggle_nearest_door(player_tile, radius_tiles)
	else:
		result = _building_state.interact_nearest_storage(player_tile, _harvest_state.inventory_model(), radius_tiles)
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	if bool(result["ok"]):
		var placement := result.get("placement", {}) as Dictionary
		if not placement.is_empty():
			var tile_value := placement["world_tile"] as Array
			_refresh_player_buildings(WorldCoordinates.tile_to_chunk(Vector2i(int(tile_value[0]), int(tile_value[1]))))
		_emit_tool_and_inventory()
		_emit_building_state()
		_emit_automation_state()
	return true


func building_state_snapshot() -> Dictionary:
	return _building_state.status_snapshot(_harvest_state.inventory_model())


func farming_state_snapshot() -> Dictionary:
	return _farming_state.status_snapshot(_harvest_state.inventory_model())


func husbandry_state_snapshot() -> Dictionary:
	return _husbandry_state.status_snapshot(_harvest_state.inventory_model())


func farming_target_status(crop_id: StringName, world_tile: Vector2i) -> Dictionary:
	var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
	var chunk := _cache.get(coordinate) as ChunkData
	if chunk == null:
		return {"valid": false, "description": "目标区块尚未载入"}
	var context := _farming_context(world_tile, chunk)
	var plot := _farming_state.plot_at(world_tile)
	if plot.is_empty():
		var validation := _farming_state.validate_till(world_tile, context)
		return {"valid": bool(validation["valid"]), "description": "%s · 左键开垦" % validation["reason"]}
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if _world_layer != &"surface" or ChunkStreamPlanner.chebyshev_distance(player_tile, world_tile) > _farming_catalog.interaction_range_tiles():
		return {"valid": false, "description": "超出耕作距离"}
	var planted_id := StringName(plot.get("crop_id", ""))
	if planted_id.is_empty():
		var definition := _farming_catalog.crop(crop_id)
		var seed_id := StringName(definition.get("seed_item_id", ""))
		var has_seed := _harvest_state.inventory_model().quantity(seed_id) > 0
		return {"valid": has_seed, "description": "%s · 左键播种%s" % ["种子充足" if has_seed else "缺少%s" % _item_catalog.display_name(seed_id), definition.get("display_name", crop_id)]}
	if bool(plot.get("mature", false)):
		return {"valid": true, "description": "%s已成熟 · 左键收获" % _farming_catalog.crop_display_name(planted_id)}
	if int(plot.get("watered_day", -1)) == _quest_day:
		return {"valid": false, "description": "%s第 %d 阶段 · 今日已浇水 · 右键施肥" % [_farming_catalog.crop_display_name(planted_id), int(plot.get("stage", 0)) + 1]}
	return {"valid": true, "description": "%s第 %d 阶段 · 左键浇水 · 右键施肥" % [_farming_catalog.crop_display_name(planted_id), int(plot.get("stage", 0)) + 1]}


func perform_farming_action(crop_id: StringName, world_tile: Vector2i) -> Dictionary:
	var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
	var chunk := _cache.get(coordinate) as ChunkData
	if chunk == null:
		return _farming_feedback({"ok": false, "message": "目标区块尚未载入"})
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if _world_layer != &"surface" or ChunkStreamPlanner.chebyshev_distance(player_tile, world_tile) > _farming_catalog.interaction_range_tiles():
		return _farming_feedback({"ok": false, "message": "超出耕作距离"})
	var plot := _farming_state.plot_at(world_tile)
	var result: Dictionary
	if plot.is_empty():
		result = _farming_state.till(world_tile, _quest_day, _farming_context(world_tile, chunk))
	elif String(plot.get("crop_id", "")).is_empty():
		result = _farming_state.plant(crop_id, world_tile, _quest_day, _harvest_state.inventory_model())
	elif bool(plot.get("mature", false)):
		result = _farming_state.harvest(world_tile, _quest_day, _harvest_state.inventory_model())
	else:
		result = _farming_state.water(world_tile, _quest_day)
	if bool(result.get("ok", false)):
		_refresh_farming_plots(coordinate)
		_emit_tool_and_inventory()
		_emit_farming_state()
	return _farming_feedback(result)


func fertilize_farming_plot(world_tile: Vector2i, fertilizer_id: StringName = &"basic_fertilizer") -> Dictionary:
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if _world_layer != &"surface" or ChunkStreamPlanner.chebyshev_distance(player_tile, world_tile) > _farming_catalog.interaction_range_tiles():
		return _farming_feedback({"ok": false, "message": "超出耕作距离"})
	var result := _farming_state.fertilize(world_tile, fertilizer_id, _harvest_state.inventory_model())
	if bool(result.get("ok", false)):
		_refresh_farming_plots(WorldCoordinates.tile_to_chunk(world_tile))
		_emit_tool_and_inventory()
		_emit_farming_state()
	return _farming_feedback(result)


func husbandry_target_status(animal_type: StringName, world_tile: Vector2i) -> Dictionary:
	if _world_layer != &"surface" or _player == null:
		return {"valid": false, "description": "只能在地表照料动物"}
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if ChunkStreamPlanner.chebyshev_distance(player_tile, world_tile) > _husbandry_catalog.interaction_range_tiles():
		return {"valid": false, "description": "超出照料距离"}
	var record := _husbandry_state.animal_at(world_tile)
	var candidate := record if not record.is_empty() else _wild_candidate_at(world_tile)
	if candidate.is_empty() or StringName(candidate.get("animal_type", "")) != animal_type:
		return {"valid": false, "description": "此处没有%s" % _husbandry_catalog.display_name(animal_type)}
	if bool(record.get("sleeping", false)):
		return {"valid": false, "description": "%s正在睡眠" % _husbandry_catalog.display_name(animal_type)}
	if int(record.get("product_ready", 0)) > 0:
		var product_id := StringName(_husbandry_catalog.animal(animal_type)["product_item_id"])
		return {"valid": true, "description": "%s待收%s ×%d · 左键收取" % [
			_husbandry_catalog.display_name(animal_type), _item_catalog.display_name(product_id), int(record["product_ready"]),
		]}
	var definition := _husbandry_catalog.animal(animal_type)
	var feed_id := StringName(definition["feed_item_id"])
	var has_feed := _harvest_state.inventory_model().quantity(feed_id) > 0
	if not record.is_empty() and int(record.get("last_fed_day", -1)) == _quest_day:
		return {"valid": false, "description": "%s今天已喂食 · 右键尝试繁殖" % definition["display_name"]}
	var progress := int(record.get("friendship", 0)) if not record.is_empty() else 0
	var state_text := "已驯服" if bool(record.get("tamed", false)) else "驯服 %d/%d" % [progress, int(definition["tame_feed_count"])]
	return {
		"valid": has_feed,
		"description": "%s · %s · %s%s" % [
			definition["display_name"], state_text,
			"左键喂食 " if has_feed else "缺少",
			_item_catalog.display_name(feed_id),
		],
	}


func perform_husbandry_action(animal_type: StringName, world_tile: Vector2i) -> Dictionary:
	if _world_layer != &"surface" or _player == null:
		return _husbandry_feedback({"ok": false, "message": "只能在地表照料动物"})
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if ChunkStreamPlanner.chebyshev_distance(player_tile, world_tile) > _husbandry_catalog.interaction_range_tiles():
		return _husbandry_feedback({"ok": false, "message": "超出照料距离"})
	var record := _husbandry_state.animal_at(world_tile)
	var candidate := record if not record.is_empty() else _wild_candidate_at(world_tile)
	if candidate.is_empty() or StringName(candidate.get("animal_type", "")) != animal_type:
		return _husbandry_feedback({"ok": false, "message": "此处没有%s" % _husbandry_catalog.display_name(animal_type)})
	if bool(record.get("sleeping", false)):
		return _husbandry_feedback({"ok": false, "message": "动物正在睡眠"})
	var result: Dictionary
	if not record.is_empty() and bool(record.get("tamed", false)) and int(record.get("product_ready", 0)) > 0:
		result = _husbandry_state.collect_product(String(record["animal_id"]), _harvest_state.inventory_model())
	elif record.is_empty():
		result = _husbandry_state.feed_candidate(candidate, _quest_day, _harvest_state.inventory_model())
	else:
		result = _husbandry_state.feed(String(record["animal_id"]), _quest_day, _harvest_state.inventory_model())
	if bool(result.get("ok", false)):
		_refresh_husbandry_animals(WorldCoordinates.tile_to_chunk(world_tile))
		_emit_tool_and_inventory()
		_emit_husbandry_state()
	return _husbandry_feedback(result)


func breed_husbandry_animal(world_tile: Vector2i) -> Dictionary:
	if _world_layer != &"surface" or _player == null:
		return _husbandry_feedback({"ok": false, "message": "只能在地表繁殖动物"})
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if ChunkStreamPlanner.chebyshev_distance(player_tile, world_tile) > _husbandry_catalog.interaction_range_tiles():
		return _husbandry_feedback({"ok": false, "message": "超出照料距离"})
	var first := _husbandry_state.animal_at(world_tile)
	if first.is_empty():
		return _husbandry_feedback({"ok": false, "message": "请指向已互动动物"})
	var partner := _husbandry_state.compatible_partner(String(first["animal_id"]))
	if partner.is_empty():
		return _husbandry_feedback({"ok": false, "message": "附近没有同种异性伙伴"})
	var first_tile := _record_world_tile(first)
	var second_tile := _record_world_tile(partner)
	var fenced := _building_state.is_near_piece(first_tile, &"animal_fence", _husbandry_catalog.fence_radius_tiles()) \
			and _building_state.is_near_piece(second_tile, &"animal_fence", _husbandry_catalog.fence_radius_tiles())
	var offspring_tile := _find_husbandry_offspring_tile(first_tile, second_tile)
	var result := _husbandry_state.breed(
		String(first["animal_id"]), String(partner["animal_id"]), offspring_tile, _quest_day, fenced
	)
	if bool(result.get("ok", false)):
		for coordinate in [WorldCoordinates.tile_to_chunk(first_tile), WorldCoordinates.tile_to_chunk(second_tile), WorldCoordinates.tile_to_chunk(offspring_tile)]:
			_refresh_husbandry_animals(coordinate)
		_emit_husbandry_state()
	return _husbandry_feedback(result)


func is_near_player_heat_source() -> bool:
	return _world_layer == &"surface" and _player != null \
			and _building_state.is_near_heat(WorldCoordinates.world_pixel_to_tile(_player.global_position))


func active_tool_power() -> int:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty():
		return 1
	var power := _item_catalog.tool_power(StringName(value["item_id"]))
	return power if power > 0 else 1


func active_tool_display_name() -> String:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty() or _item_catalog.tool_kind(StringName(value["item_id"])).is_empty():
		return _resource_catalog.tool_display_name(&"hands")
	return _item_catalog.display_name(StringName(value["item_id"]))


func active_weapon_id() -> StringName:
	var equipped_id := _equipment_state.equipped_weapon_item_id()
	if not equipped_id.is_empty() and _weapon_catalog.weapon(equipped_id) != null:
		return equipped_id
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty():
		return &"unarmed"
	var item_id := StringName(value["item_id"])
	return item_id if _item_catalog.tool_kind(item_id) == &"sword" and _weapon_catalog.weapon(item_id) != null else &"unarmed"


func consume_selected_weapon_durability() -> Dictionary:
	if not _equipment_state.equipped_weapon_item_id().is_empty():
		var equipped_result := _equipment_state.damage_equipped_weapon(1)
		_apply_equipment_effects()
		_emit_equipment_state()
		if bool(equipped_result.get("broken", false)):
			EventBus.combat_feedback.emit("%s耐久耗尽，请修理" % _item_catalog.display_name(StringName(equipped_result.get("item_id", ""))), false)
		return equipped_result
	var inventory := _harvest_state.inventory_model()
	var index := inventory.selected_hotbar_slot()
	var value := inventory.slot(index)
	if value.is_empty():
		return {"accepted": false, "broken": false}
	var item_id := StringName(value["item_id"])
	if _item_catalog.tool_kind(item_id) != &"sword":
		return {"accepted": false, "broken": false}
	var result := inventory.damage_tool_at(index, 1)
	_emit_tool_and_inventory()
	if bool(result.get("broken", false)):
		EventBus.combat_feedback.emit("%s已损坏" % _item_catalog.display_name(item_id), false)
	return result


func interact() -> void:
	if try_use_dungeon_transition():
		return
	if _world_layer == &"dungeon":
		if try_collect_nearest_dungeon_key():
			return
		if try_unlock_nearest_dungeon_door():
			return
		if try_open_nearest_dungeon_chest():
			return
	if try_use_cave_transition():
		return
	if try_open_nearest_cave_chest():
		return
	if _world_layer == &"surface" and try_interact_boat():
		return
	if try_interact_player_building():
		return
	if _npc_director != null and _npc_director.try_interact():
		return
	if _world_layer == &"surface" and _ruin_encounter != null and _ruin_encounter.try_interact(_harvest_state.inventory_model()):
		_emit_tool_and_inventory()
		_record_world_event(&"explore", &"ruins")
		return
	if try_reclaim_nearest_grave():
		return
	interact_with_nearest_resource()


func boarded_boat_id() -> String:
	return _boarded_boat_id


func boarded_boat_speed() -> float:
	if _boarded_boat_id.is_empty():
		return 1.0
	for record in _boat_state.boats():
		if String(record["boat_id"]) == _boarded_boat_id:
			var definition := _ocean_catalog.boat_for_item(StringName(record["item_id"]))
			if definition.is_empty():
				return 1.0
			return float(definition.get("speed_multiplier", 1.0))
	return 1.0


func boat_state() -> BoatState:
	return _boat_state


func ocean_catalog() -> OceanCatalog:
	return _ocean_catalog


func try_interact_boat() -> bool:
	if _player == null:
		return false
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	if not _boarded_boat_id.is_empty():
		return _disembark_boat(player_tile)
	var nearby := _nearest_boat_record(player_tile, 1)
	if not nearby.is_empty():
		return _board_boat(nearby)
	var selected := selected_item_id()
	var definition := _ocean_catalog.boat_for_item(selected)
	if definition.is_empty():
		return false
	return _deploy_boat(player_tile, selected, definition)


func _deploy_boat(player_tile: Vector2i, item_id: StringName, definition: Dictionary) -> bool:
	var dir := _cardinal_facing()
	var deploy_range := int(definition.get("deploy_range_tiles", 2))
	for distance in range(1, deploy_range + 1):
		var target := player_tile + dir * distance
		var terrain := _surface_terrain_at(target)
		if terrain != ChunkData.Terrain.SHALLOW_WATER and terrain != ChunkData.Terrain.DEEP_WATER:
			continue
		if not _boat_state.boat_at(target).is_empty():
			continue
		if _water_resource_occupied(target):
			EventBus.interaction_feedback.emit("该水面有海洋资源，无法停船", false)
			return true
		if not _boat_state.can_deploy(item_id):
			EventBus.interaction_feedback.emit(_boat_state.last_error, false)
			return true
		if not consume_selected_item(item_id, 1):
			EventBus.interaction_feedback.emit("快捷栏中没有可部署的船只", false)
			return true
		var record := _boat_state.deploy(target, item_id)
		if record.is_empty():
			EventBus.interaction_feedback.emit(_boat_state.last_error, false)
			return true
		_refresh_boat_layer()
		_emit_tool_and_inventory()
		EventBus.interaction_feedback.emit("已部署%s，靠近后按 E 登船" % String(definition.get("display_name", "小木船")), true)
		return true
	EventBus.interaction_feedback.emit("附近没有可以停泊的水面", false)
	return true


func _board_boat(record: Dictionary) -> bool:
	var boat_tile_value: Array = record["world_tile"]
	var boat_tile := Vector2i(int(boat_tile_value[0]), int(boat_tile_value[1]))
	_boarded_boat_id = String(record["boat_id"])
	_boat_last_water_tile = boat_tile
	_player.global_position = WorldCoordinates.tile_to_world_pixel(boat_tile, true)
	_refresh_boat_layer()
	EventBus.interaction_feedback.emit("已登船，按 E 下船，驶向岸边即可靠岸", true)
	return true


func _disembark_boat(player_tile: Vector2i) -> bool:
	var terrain := _surface_terrain_at(player_tile)
	if terrain == ChunkData.Terrain.SHALLOW_WATER or terrain == ChunkData.Terrain.DEEP_WATER:
		var target := player_tile + _cardinal_facing()
		var target_terrain := _surface_terrain_at(target)
		if target_terrain == ChunkData.Terrain.LAND or target_terrain == ChunkData.Terrain.BEACH:
			_finish_disembark()
			return true
		EventBus.interaction_feedback.emit("需要驶向岸边或面向陆地按 E 才能下船", false)
		return true
	_finish_disembark()
	return true


func _finish_disembark() -> void:
	if not _boat_state.relocate(_boarded_boat_id, _boat_last_water_tile):
		push_warning("Unable to relocate boat: %s" % _boat_state.last_error)
	_boarded_boat_id = ""
	_refresh_boat_layer()
	EventBus.interaction_feedback.emit("已下船", true)


func _update_boat_follow() -> void:
	if _boarded_boat_id.is_empty() or _player == null or _world_layer != &"surface":
		return
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	var terrain := _surface_terrain_at(player_tile)
	if terrain == ChunkData.Terrain.SHALLOW_WATER or terrain == ChunkData.Terrain.DEEP_WATER:
		_boat_last_water_tile = player_tile
		_refresh_boat_layer()
	else:
		if not _boat_state.relocate(_boarded_boat_id, _boat_last_water_tile):
			push_warning("Unable to moor boat: %s" % _boat_state.last_error)
		_boarded_boat_id = ""
		_refresh_boat_layer()
		EventBus.interaction_feedback.emit("已靠岸下船", true)


func _nearest_boat_record(player_tile: Vector2i, radius: int) -> Dictionary:
	for offset_y in range(-radius, radius + 1):
		for offset_x in range(-radius, radius + 1):
			var record := _boat_state.boat_at(player_tile + Vector2i(offset_x, offset_y))
			if not record.is_empty():
				return record
	return {}


func _refresh_boat_layer() -> void:
	if _boat_layer == null:
		return
	var records := _boat_state.boats()
	if _world_layer != &"surface":
		_boat_layer.set_boats([], "")
		return
	if not _boarded_boat_id.is_empty():
		for record in records:
			if String(record["boat_id"]) == _boarded_boat_id:
				record["world_tile"] = [_boat_last_water_tile.x, _boat_last_water_tile.y]
	_boat_layer.set_boats(records, _boarded_boat_id)


func _cardinal_facing() -> Vector2i:
	var facing := _player.facing if _player != null else Vector2.DOWN
	if absf(facing.x) >= absf(facing.y):
		return Vector2i(1, 0) if facing.x > 0.0 else Vector2i(-1, 0)
	return Vector2i(0, 1) if facing.y > 0.0 else Vector2i(0, -1)


func _surface_terrain_at(world_tile: Vector2i) -> int:
	if _world_layer != &"surface":
		return -1
	var chunk := _cache.get(WorldCoordinates.tile_to_chunk(world_tile)) as ChunkData
	if chunk == null:
		return -1
	return int(chunk.tile_at(WorldCoordinates.tile_to_local(world_tile)))


func _water_resource_occupied(world_tile: Vector2i) -> bool:
	var chunk := _cache.get(WorldCoordinates.tile_to_chunk(world_tile)) as ChunkData
	if chunk == null:
		return false
	return chunk.has_resource_at(WorldCoordinates.tile_to_local(world_tile))


func create_death_grave(world_position: Vector2) -> Dictionary:
	var grave := _grave_model.deposit(world_position, _harvest_state.inventory_model(), _grave_scope())
	if grave.is_empty():
		EventBus.combat_feedback.emit("背包为空，没有生成墓碑", false)
		return {}
	_refresh_grave_markers()
	_emit_tool_and_inventory()
	EventBus.combat_feedback.emit("物品已保存在墓碑中", false)
	return grave


func try_reclaim_nearest_grave(radius := 68.0) -> bool:
	if _player == null:
		return false
	var grave := _grave_model.nearest_grave(_player.global_position, radius, _grave_scope())
	if grave.is_empty():
		return false
	var result := _grave_model.reclaim(int(grave["id"]), _harvest_state.inventory_model())
	if not bool(result.get("ok", false)):
		EventBus.combat_feedback.emit(_grave_model.last_error, false)
		return true
	_refresh_grave_markers()
	_emit_tool_and_inventory()
	EventBus.combat_feedback.emit(
		"已取回墓碑中的 %d 件物品" % int(result["transferred"]) if bool(result["complete"]) else _grave_model.last_error,
		bool(result["complete"])
	)
	return true


func interact_with_nearest_resource() -> void:
	var target := nearest_resource(_resource_catalog.interaction_radius_pixels())
	if target.is_empty():
		EventBus.interaction_feedback.emit("附近没有可以采集的资源", false)
		return
	var resource_code := int(target["resource_code"])
	var resource_key := String(target["resource_key"])
	var result := _harvest_state.hit(resource_key, resource_code, active_tool_id(), _resource_catalog, active_tool_power())
	if not bool(result["accepted"]):
		if String(result.get("reason", "")) == "wrong_tool":
			var required_tool := StringName(result["required_tool"])
			EventBus.interaction_feedback.emit("需要%s才能采集%s" % [
				_resource_catalog.tool_display_name(required_tool),
				_resource_catalog.display_name_for_code(resource_code),
			], false)
		return
	var broken_tool := _consume_active_tool_durability()
	var renderer := _renderers.get(target["chunk_position"]) as ChunkRenderer
	var destroyed := bool(result["destroyed"])
	if renderer != null:
		renderer.play_resource_hit(resource_key, destroyed)
	if not destroyed:
		var progress_message := "采集中：%s  %d/%d" % [
			_resource_catalog.display_name_for_code(resource_code),
			int(result["remaining"]),
			int(result["maximum"]),
		]
		if not broken_tool.is_empty():
			progress_message += " · %s已损坏" % broken_tool
		EventBus.interaction_feedback.emit(progress_message, true)
		return
	var drop_position := target["world_position"] as Vector2
	var drop_index := 0
	for drop_value in result["drops"] as Array:
		var drop := drop_value as Dictionary
		var offset := Vector2((drop_index - 1) * 12, 5 + posmod(drop_index, 2) * 6)
		var weather_quantity := adjusted_resource_quantity(int(drop["quantity"]))
		if not _drop_pool.spawn_drop(drop["item_id"] as StringName, weather_quantity, drop_position + offset):
			LogManager.warning("ResourceInteraction", "Drop pool full; unable to spawn %s" % drop["item_id"])
		drop_index += 1
	_record_world_event(&"harvest", _resource_catalog.id_for_code(resource_code))
	var destroyed_message := "%s已采集，掉落物将自动拾取" % _resource_catalog.display_name_for_code(resource_code)
	if not broken_tool.is_empty():
		destroyed_message += " · %s已损坏" % broken_tool
	EventBus.interaction_feedback.emit(destroyed_message, true)
	_update_resource_prompt()
	_emit_metrics()


func nearest_resource(radius_pixels: float) -> Dictionary:
	if _player == null:
		return {}
	var best: Dictionary = {}
	var best_distance_squared := radius_pixels * radius_pixels
	for coordinate_value in _renderers.keys():
		var coordinate := coordinate_value as Vector2i
		var chunk := _cache.get(coordinate) as ChunkData
		if chunk == null:
			continue
		for index in chunk.resource_count():
			if chunk.has_built_overlay_at(chunk.resource_local_at(index)):
				continue
			if not _resource_catalog.available_in_phase(chunk.resource_code_at(index), _time_phase):
				continue
			var resource_key := chunk.resource_key_at(index)
			if _harvest_state.collected_resources.has(resource_key):
				continue
			var world_position := WorldCoordinates.tile_to_world_pixel(chunk.resource_world_tile_at(index), true)
			var distance_squared := _player.global_position.distance_squared_to(world_position)
			if distance_squared > best_distance_squared:
				continue
			best_distance_squared = distance_squared
			best = {
				"chunk_position": coordinate,
				"resource_index": index,
				"resource_key": resource_key,
				"resource_code": chunk.resource_code_at(index),
				"world_position": world_position,
				"distance_squared": distance_squared,
			}
	return best


func try_use_dungeon_transition(radius_pixels := 72.0) -> bool:
	if _world_layer == &"surface":
		var entrance := _nearest_structure_marker(StructureCatalog.MarkerKind.DUNGEON_ENTRANCE, radius_pixels)
		if entrance.is_empty():
			return false
		return _enter_dungeon(entrance["world_tile"] as Vector2i)
	if _world_layer == &"dungeon":
		var exit_target := _nearest_dungeon_feature(DungeonGenerator.Feature.EXIT, radius_pixels)
		if exit_target.is_empty():
			return false
		return _leave_dungeon()
	return false


func _enter_dungeon(entrance_world_tile: Vector2i) -> bool:
	var dungeon_id := DungeonGenerator.dungeon_id_for_entrance(entrance_world_tile)
	var anchor_chunk := WorldCoordinates.tile_to_chunk(entrance_world_tile)
	var return_position := WorldCoordinates.tile_to_world_pixel(entrance_world_tile, true)
	_dungeon_state.begin(dungeon_id, anchor_chunk, return_position)
	var generator := DungeonGenerator.new(_world_seed, dungeon_id, anchor_chunk, _dungeon_catalog)
	var target_position := WorldCoordinates.tile_to_world_pixel(generator.entry_world_tile(), true)
	var changed := _switch_world_layer_internal(&"dungeon", target_position)
	_emit_dungeon_state()
	return changed


func _leave_dungeon() -> bool:
	var run := _dungeon_state.current_run()
	if run.is_empty():
		return false
	var return_value := run["return_position"] as Array
	var return_position := Vector2(float(return_value[0]), float(return_value[1]))
	var leave_result := _dungeon_state.leave_current()
	var changed := _switch_world_layer_internal(&"surface", return_position)
	if changed and bool(leave_result.get("reset", false)):
		EventBus.interaction_feedback.emit("未完成地牢已按规则重置", false)
	_emit_dungeon_state()
	return changed


func respawn_to_surface(target_position: Vector2) -> bool:
	if _world_layer == &"surface":
		return false
	if _world_layer == &"dungeon":
		_dungeon_state.leave_current()
	var changed := _switch_world_layer_internal(&"surface", target_position)
	_emit_dungeon_state()
	return changed


func try_use_cave_transition(radius_pixels := 72.0) -> bool:
	if _world_layer not in [&"surface", &"underground"]:
		return false
	var feature := CaveGenerator.Feature.EXIT if _world_layer == &"underground" else CaveGenerator.Feature.ENTRANCE
	var target := _nearest_cave_feature(feature, radius_pixels)
	if target.is_empty():
		return false
	var target_layer: StringName = &"surface" if _world_layer == &"underground" else &"underground"
	var world_tile := target["world_tile"] as Vector2i
	return switch_world_layer(target_layer, WorldCoordinates.tile_to_world_pixel(world_tile, true))


func switch_world_layer(target_layer: StringName, target_position: Vector2) -> bool:
	if _world_layer == &"dungeon" or target_layer == &"dungeon":
		return false
	return _switch_world_layer_internal(target_layer, target_position)


func _switch_world_layer_internal(target_layer: StringName, target_position: Vector2) -> bool:
	if target_layer == _world_layer or not [&"surface", &"underground", &"dungeon"].has(target_layer):
		return false
	if target_layer == &"dungeon" and _dungeon_state.current_dungeon_id().is_empty():
		return false
	_wait_for_all_jobs()
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		if is_instance_valid(renderer):
			renderer.queue_free()
	_renderers.clear()
	_cache.clear()
	_queue.clear()
	_preload_targets.clear()
	_world_layer = target_layer
	_player.global_position = target_position
	_player.velocity = Vector2.ZERO
	_movement_direction = Vector2i.ZERO
	_boarded_boat_id = ""
	_current_chunk = WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(target_position))
	var initial_chunk := _generate_chunk(_current_chunk)
	_cache[_current_chunk] = initial_chunk
	_weather_resource_multiplier = 1.0
	if _enemy_director != null:
		_enemy_director.set_world_layer(_world_layer, _dungeon_context())
	_apply_world_event_effects()
	if _npc_director != null:
		_npc_director.set_world_layer(_world_layer)
	if _ruin_encounter != null:
		_ruin_encounter.set_world_layer(_world_layer)
	_refresh_grave_markers()
	_refresh_targets()
	_update_exploration()
	_emit_metrics()
	_update_resource_prompt()
	EventBus.world_layer_changed.emit({
		"layer": _world_layer,
		"display_name": _world_layer_display_name(),
		"position": target_position,
	})
	var message := "已返回地表"
	if _world_layer == &"underground":
		message = "已进入地下洞穴"
	elif _world_layer == &"dungeon":
		message = "已进入程序化地牢"
	EventBus.interaction_feedback.emit(message, true)
	return true


func try_open_nearest_cave_chest(radius_pixels := 68.0) -> bool:
	if _world_layer != &"underground":
		return false
	var target := _nearest_cave_feature(CaveGenerator.Feature.CHEST, radius_pixels)
	if target.is_empty():
		return false
	var chest_key := String(target["feature_key"])
	if _opened_cave_chests.has(chest_key):
		return false
	var inventory := _harvest_state.inventory_model()
	var before := inventory.snapshot()
	var loot := _cave_catalog.chest_loot(chest_key)
	var messages: Array[String] = []
	for entry in loot:
		var item_id := (entry as Dictionary)["item_id"] as StringName
		var quantity := int((entry as Dictionary)["quantity"])
		var add_result := inventory.add_item(item_id, quantity)
		if int(add_result.get("remainder", quantity)) > 0:
			inventory.restore_snapshot(before)
			EventBus.interaction_feedback.emit("背包空间不足，宝箱保持未开启", false)
			return true
		messages.append("%s ×%d" % [_resource_catalog.item_display_name(item_id), quantity])
	_opened_cave_chests[chest_key] = true
	for renderer_value in _renderers.values():
		(renderer_value as ChunkRenderer).set_opened_cave_chests(_opened_cave_chests)
	_emit_tool_and_inventory()
	EventBus.interaction_feedback.emit("打开地下宝箱：" + "、".join(messages), true)
	_update_resource_prompt()
	return true


func try_collect_nearest_dungeon_key(radius_pixels := 58.0) -> bool:
	if _world_layer != &"dungeon":
		return false
	var target := _nearest_dungeon_feature(DungeonGenerator.Feature.KEY, radius_pixels)
	if target.is_empty():
		return false
	var feature_key := String(target["feature_key"])
	if (_dungeon_state.current_run().get("collected_keys", []) as Array).has(feature_key):
		return false
	if not _dungeon_state.collect_key(feature_key):
		return false
	_refresh_dungeon_renderers()
	_emit_dungeon_state()
	EventBus.interaction_feedback.emit("获得地牢钥匙 · 当前 %d 把" % int(_dungeon_state.current_run()["key_count"]), true)
	_update_resource_prompt()
	return true


func try_unlock_nearest_dungeon_door(radius_pixels := 62.0) -> bool:
	if _world_layer != &"dungeon":
		return false
	var target := _nearest_dungeon_feature(DungeonGenerator.Feature.LOCKED_DOOR, radius_pixels)
	if target.is_empty():
		return false
	var feature_key := String(target["feature_key"])
	var run := _dungeon_state.current_run()
	if (run.get("unlocked_doors", []) as Array).has(feature_key):
		return false
	if int(run.get("key_count", 0)) <= 0:
		EventBus.interaction_feedback.emit("锁门需要一把地牢钥匙", false)
		return true
	if not _dungeon_state.unlock_door(feature_key):
		return true
	_refresh_dungeon_renderers()
	_emit_dungeon_state()
	EventBus.interaction_feedback.emit("地牢锁门已开启", true)
	_update_resource_prompt()
	return true


func try_open_nearest_dungeon_chest(radius_pixels := 62.0) -> bool:
	if _world_layer != &"dungeon":
		return false
	var target := _nearest_dungeon_feature(DungeonGenerator.Feature.CHEST, radius_pixels)
	if target.is_empty():
		return false
	var feature_key := String(target["feature_key"])
	if (_dungeon_state.current_run().get("opened_chests", []) as Array).has(feature_key):
		return false
	var inventory := _harvest_state.inventory_model()
	var before := inventory.snapshot()
	var messages: Array[String] = []
	for entry in _dungeon_catalog.chest_loot(feature_key):
		var item_id := (entry as Dictionary)["item_id"] as StringName
		var quantity := int((entry as Dictionary)["quantity"])
		var add_result := inventory.add_item(item_id, quantity)
		if int(add_result.get("remainder", quantity)) > 0:
			inventory.restore_snapshot(before)
			EventBus.interaction_feedback.emit("背包空间不足，地牢宝箱保持未开启", false)
			return true
		messages.append("%s ×%d" % [_resource_catalog.item_display_name(item_id), quantity])
	_dungeon_state.open_chest(feature_key)
	_refresh_dungeon_renderers()
	_emit_dungeon_state()
	_emit_tool_and_inventory()
	EventBus.interaction_feedback.emit("打开地牢宝箱：" + "、".join(messages), true)
	_update_resource_prompt()
	return true


func _process_dungeon_trap() -> void:
	if _world_layer != &"dungeon" or _player == null or _player.combat_state().status == &"dead":
		return
	var target := _nearest_dungeon_feature(DungeonGenerator.Feature.TRAP, 18.0)
	if target.is_empty():
		return
	var feature_key := String(target["feature_key"])
	if (_dungeon_state.current_run().get("triggered_traps", []) as Array).has(feature_key):
		return
	if not _dungeon_state.trigger_trap(feature_key):
		return
	_refresh_dungeon_renderers()
	_emit_dungeon_state()
	var direction := (target["world_position"] as Vector2).direction_to(_player.global_position)
	var result := _player.receive_hit(_dungeon_catalog.trap_damage(), direction, 95.0)
	if bool(result.get("accepted", false)):
		EventBus.combat_feedback.emit("触发地牢陷阱", false)


func _on_dungeon_enemy_defeated(spawn_id: String, role: StringName) -> void:
	if _world_layer != &"dungeon":
		return
	var result := _dungeon_state.defeat_enemy(spawn_id, role)
	if not bool(result.get("changed", false)):
		return
	if _enemy_director != null:
		_enemy_director.update_dungeon_state(_dungeon_state.current_run())
	_refresh_dungeon_renderers()
	_emit_dungeon_state()
	if bool(result.get("completed", false)):
		_record_world_progress(&"dungeon_completed", _dungeon_state.current_dungeon_id())
		EventBus.combat_feedback.emit("地牢 Boss 已击败 · 完成状态永久保存", true)


func _on_regional_boss_defeated(boss_id: StringName) -> void:
	if not _regional_boss_state.defeat(boss_id):
		return
	_exploration_state.mark_completed("boss:%s" % boss_id)
	if _enemy_director != null:
		_enemy_director.update_regional_boss_state(_regional_boss_state.persistence_snapshot())
	_emit_exploration_state()
	_record_world_event(&"defeat_boss", boss_id)
	_record_world_progress(&"regional_boss_defeated", String(boss_id))
	EventBus.combat_feedback.emit("区域首领已击败 · 世界进度永久保存", true)


func _nearest_dungeon_feature(feature: int, radius_pixels: float) -> Dictionary:
	if _world_layer != &"dungeon" or _player == null:
		return {}
	var best: Dictionary = {}
	var best_distance_squared := radius_pixels * radius_pixels
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	var tile_radius := ceili(radius_pixels / float(WorldCoordinates.TILE_SIZE)) + 1
	for world_y in range(player_tile.y - tile_radius, player_tile.y + tile_radius + 1):
		for world_x in range(player_tile.x - tile_radius, player_tile.x + tile_radius + 1):
			var world_tile := Vector2i(world_x, world_y)
			var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
			if not _renderers.has(coordinate):
				continue
			var chunk := _cache.get(coordinate) as ChunkData
			if chunk == null:
				continue
			var local := WorldCoordinates.tile_to_local(world_tile)
			if chunk.dungeon_feature_at(local) != feature:
				continue
			var world_position := WorldCoordinates.tile_to_world_pixel(world_tile, true)
			var distance_squared := _player.global_position.distance_squared_to(world_position)
			if distance_squared > best_distance_squared:
				continue
			best_distance_squared = distance_squared
			best = {
				"chunk_position": coordinate,
				"local": local,
				"world_tile": world_tile,
				"world_position": world_position,
				"feature": feature,
				"feature_key": DungeonGenerator.feature_key(_dungeon_state.current_dungeon_id(), feature, world_tile),
			}
	return best


func _nearest_structure_marker(marker_kind: int, radius_pixels: float) -> Dictionary:
	if _world_layer != &"surface" or _player == null:
		return {}
	var best: Dictionary = {}
	var best_distance_squared := radius_pixels * radius_pixels
	for coordinate_value in _renderers.keys():
		var coordinate := coordinate_value as Vector2i
		var chunk := _cache.get(coordinate) as ChunkData
		if chunk == null:
			continue
		for index in chunk.structure_cell_count():
			if chunk.structure_marker_kind_at(index) != marker_kind:
				continue
			var local := chunk.structure_local_at(index)
			var world_tile := WorldCoordinates.chunk_local_to_tile(coordinate, local)
			var world_position := WorldCoordinates.tile_to_world_pixel(world_tile, true)
			var distance_squared := _player.global_position.distance_squared_to(world_position)
			if distance_squared > best_distance_squared:
				continue
			best_distance_squared = distance_squared
			best = {"chunk_position": coordinate, "local": local, "world_tile": world_tile, "world_position": world_position}
	return best


func _refresh_dungeon_renderers() -> void:
	var dungeon_id := _dungeon_state.current_dungeon_id()
	var run := _dungeon_state.current_run()
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		if is_instance_valid(renderer):
			renderer.set_dungeon_state(dungeon_id, run)


func _nearest_cave_feature(feature: int, radius_pixels: float) -> Dictionary:
	if _player == null:
		return {}
	var best: Dictionary = {}
	var best_distance_squared := radius_pixels * radius_pixels
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	var tile_radius := ceili(radius_pixels / float(WorldCoordinates.TILE_SIZE)) + 1
	for world_y in range(player_tile.y - tile_radius, player_tile.y + tile_radius + 1):
		for world_x in range(player_tile.x - tile_radius, player_tile.x + tile_radius + 1):
			var world_tile := Vector2i(world_x, world_y)
			var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
			if not _renderers.has(coordinate):
				continue
			var chunk := _cache.get(coordinate) as ChunkData
			if chunk == null:
				continue
			var local := WorldCoordinates.tile_to_local(world_tile)
			if chunk.cave_feature_at(local) != feature:
				continue
			var world_position := WorldCoordinates.tile_to_world_pixel(world_tile, true)
			var distance_squared := _player.global_position.distance_squared_to(world_position)
			if distance_squared > best_distance_squared:
				continue
			best_distance_squared = distance_squared
			best = {
				"chunk_position": coordinate,
				"local": local,
				"world_tile": world_tile,
				"world_position": world_position,
				"feature": feature,
				"feature_key": "underground:%d:%d" % [world_tile.x, world_tile.y],
			}
	return best


func _on_time_state_changed(snapshot: Dictionary) -> void:
	var previous_quest_day := _quest_day
	_quest_day = maxi(1, int(snapshot.get("day", _quest_day)))
	if _quest_day != previous_quest_day:
		var farming_result := _farming_state.advance_to_day(_quest_day, _current_weather_id, _season_crop_growth_multiplier)
		for coordinate_value in farming_result.get("changed_chunks", []) as Array:
			var farming_coordinate: Vector2i = coordinate_value
			_refresh_farming_plots(farming_coordinate)
		if bool(farming_result.get("changed", false)):
			_emit_farming_state()
		if int(farming_result.get("matured", 0)) > 0:
			EventBus.interaction_feedback.emit("%d 块作物已经成熟" % int(farming_result["matured"]), true)
		var husbandry_result := _husbandry_state.advance_to_day(_quest_day)
		for coordinate_value in husbandry_result.get("changed_chunks", []) as Array:
			var husbandry_coordinate: Vector2i = coordinate_value
			_refresh_husbandry_animals(husbandry_coordinate)
		if bool(husbandry_result.get("changed", false)):
			_emit_husbandry_state()
		if int(husbandry_result.get("produced", 0)) > 0:
			EventBus.interaction_feedback.emit("休眠区块模拟完成 · 新增 %d 份畜产品" % int(husbandry_result["produced"]), true)
	_time_phase = StringName(snapshot.get("phase", &"DAWN"))
	var sleep_result := _husbandry_state.set_sleep_phase(_time_phase)
	for coordinate_value in sleep_result.get("changed_chunks", []) as Array:
		var sleep_coordinate: Vector2i = coordinate_value
		_refresh_husbandry_animals(sleep_coordinate)
	if bool(sleep_result.get("changed", false)):
		_emit_husbandry_state()
	_world_event_time_seconds = maxf(0.0, float(snapshot.get("total_seconds", _world_event_time_seconds)))
	if _automation_system != null:
		var automation_result := _automation_system.advance_to(_world_event_time_seconds)
		for coordinate_value in automation_result.get("changed_chunks", []) as Array:
			_refresh_player_buildings(coordinate_value as Vector2i)
		if bool(automation_result.get("changed", false)):
			_emit_building_state()
			_emit_automation_state()
	var event_result := _world_event_state.advance(
		_world_event_time_seconds,
		_current_chunk,
		_world_event_planner,
		_world_event_catalog
	)
	_apply_world_event_effects()
	for value in event_result.get("started", []) as Array:
		var record := value as Dictionary
		var definition := _world_event_catalog.event(StringName(record["event_id"]))
		EventBus.interaction_feedback.emit("世界事件开始：%s · [V] 查看时间表" % definition.get("display_name", record["event_id"]), true)
	for value in event_result.get("finished", []) as Array:
		var record := value as Dictionary
		if String(record.get("status", "")) == "completed":
			_record_world_progress(&"world_event_completed", String(record["instance_id"]))
	if _npc_director != null:
		_npc_director.update_time(snapshot)
	var display_second := floori(_world_event_time_seconds)
	if bool(event_result.get("changed", false)) or display_second != _world_event_display_second:
		_world_event_display_second = display_second
		_sync_world_event_encounters()
		_emit_world_event_state()
	if _quest_day != previous_quest_day:
		_emit_quest_state()
	_update_resource_prompt()


func _on_weather_state_changed(snapshot: Dictionary) -> void:
	_current_weather_id = StringName(snapshot.get("weather_id", snapshot.get("current_id", _current_weather_id)))
	_weather_resource_multiplier = 1.0 if _world_layer != &"surface" \
		else clampf(float(snapshot.get("resource_yield_multiplier", 1.0)), 0.25, 3.0)


func adjusted_resource_quantity(base_quantity: int) -> int:
	return maxi(1, roundi(float(base_quantity) * _weather_resource_multiplier * _world_event_resource_multiplier * _season_resource_multiplier))


func set_season_resource_multiplier(multiplier: float) -> void:
	_season_resource_multiplier = clampf(multiplier, 0.25, 3.0)


func set_season_population_multiplier(multiplier: float) -> void:
	if _enemy_director != null:
		_enemy_director.set_season_population_multiplier(multiplier)


func set_season_crop_growth_multiplier(multiplier: float) -> void:
	_season_crop_growth_multiplier = clampf(multiplier, 0.0, 3.0)


func current_biome_id() -> StringName:
	if _world_layer != &"surface":
		return &"mountain"
	var current_data := _cache.get(_current_chunk) as ChunkData
	if current_data == null or _player == null:
		return &"plains"
	var local := WorldCoordinates.tile_to_local(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	return _catalog.id_for_code(current_data.biome_at(local))


func harvest_state() -> ResourceHarvestState:
	return _harvest_state


func enemy_director() -> EnemyDirector:
	return _enemy_director


func ruin_encounter() -> RuinEncounter:
	return _ruin_encounter


func milestone_state() -> MilestoneState:
	return _milestone_state


func world_layer() -> StringName:
	return _world_layer


func is_underground() -> bool:
	return _world_layer == &"underground"


func is_dungeon() -> bool:
	return _world_layer == &"dungeon"


func dungeon_state() -> DungeonRunState:
	return _dungeon_state


func exploration_state() -> ExplorationMapState:
	return _exploration_state


func regional_boss_state() -> RegionalBossState:
	return _regional_boss_state


func npc_director() -> NpcDirector:
	return _npc_director


func npc_state() -> NpcWorldState:
	return _npc_state


func relationship_state() -> RelationshipState:
	return _relationship_state


func quest_catalog() -> QuestCatalog:
	return _quest_catalog


func quest_state() -> QuestState:
	return _quest_state


func quest_snapshot() -> Dictionary:
	var snapshot := _quest_state.status_snapshot(
		_quest_catalog,
		_current_quest_board_id(),
		_quest_day,
		_world_seed
	)
	snapshot["world_choices"] = _world_choice_state.status_snapshot(_quest_state, _quest_catalog)
	return snapshot


func world_choice_state() -> WorldChoiceState:
	return _world_choice_state


func world_choice_snapshot() -> Dictionary:
	return _world_choice_state.status_snapshot(_quest_state, _quest_catalog)


func faction_catalog() -> FactionCatalog:
	return _faction_catalog


func faction_state() -> FactionState:
	return _faction_state


func faction_snapshot() -> Dictionary:
	return _faction_state.status_snapshot(_faction_catalog)


func world_event_catalog() -> WorldEventCatalog:
	return _world_event_catalog


func world_event_state() -> WorldEventState:
	return _world_event_state


func world_event_snapshot() -> Dictionary:
	return _world_event_state.status_snapshot(_world_event_time_seconds, _world_event_planner, _world_event_catalog)


func region_progression_catalog() -> RegionProgressionCatalog:
	return _region_progression_catalog


func region_progression_model() -> RegionProgressionModel:
	return _region_progression_model


func region_progression_state() -> RegionProgressionState:
	return _region_progression_state


func region_progression_snapshot() -> Dictionary:
	if _region_progression_model == null:
		return {}
	return _region_progression_state.status_snapshot(
		_region_progression_model.region_profile(_current_chunk),
		_region_progression_catalog.gear_score(_harvest_state.inventory_model().snapshot()),
		_region_progression_catalog
	)


func claim_current_region_reward() -> Dictionary:
	var snapshot := region_progression_snapshot()
	var current := snapshot.get("current_region", {}) as Dictionary
	var result := _region_progression_state.claim_region_reward(
		String(current.get("region_id", "")),
		_harvest_state.inventory_model(),
		_region_progression_catalog
	)
	if not bool(result.get("ok", false)):
		EventBus.interaction_feedback.emit(String(result.get("message", "区域奖励领取失败")), false)
		return result
	_emit_tool_and_inventory()
	EventBus.interaction_feedback.emit(String(result["message"]), true)
	return result


func world_event_weather_override() -> StringName:
	return _world_event_state.weather_override(_world_event_catalog) if _world_layer == &"surface" else &""


func accept_quest(quest_id: StringName) -> bool:
	if not _quest_state.accept(quest_id, _quest_catalog):
		EventBus.interaction_feedback.emit(_quest_state.last_error, false)
		return false
	_quest_state.synchronize_collect(_harvest_state.inventory_model().count_snapshot(), _quest_catalog)
	_synchronize_quest_exploration()
	_emit_quest_state()
	EventBus.interaction_feedback.emit("已接取任务：%s" % String(_quest_catalog.quest(quest_id).get("display_name", quest_id)), true)
	return true


func track_quest(quest_id: StringName) -> bool:
	if not _quest_state.track(quest_id):
		EventBus.interaction_feedback.emit(_quest_state.last_error, false)
		return false
	_emit_quest_state()
	return true


func abandon_quest(quest_id: StringName) -> bool:
	if not _quest_state.abandon(quest_id, _quest_catalog):
		EventBus.interaction_feedback.emit(_quest_state.last_error, false)
		return false
	_emit_quest_state()
	EventBus.interaction_feedback.emit("任务已标记失败，可从日志重试", false)
	return true


func claim_quest_reward(quest_id: StringName) -> Dictionary:
	var result := _quest_state.claim_reward(quest_id, _harvest_state.inventory_model(), _quest_catalog)
	if not bool(result.get("ok", false)):
		EventBus.interaction_feedback.emit(String(result.get("message", "奖励领取失败")), false)
		return result
	_emit_tool_and_inventory()
	_emit_quest_state()
	var definition := _quest_state.definition(quest_id, _quest_catalog)
	if not definition.is_empty():
		var faction_result := _faction_state.record_quest(StringName(definition.get("giver_role", "")), _faction_catalog)
		if bool(faction_result.get("changed", false)):
			_emit_faction_state()
	_record_world_progress(&"quest_claimed", String(quest_id))
	EventBus.interaction_feedback.emit(String(result["message"]), true)
	return result


func resolve_world_choice(choice_id: StringName, option_id: StringName) -> Dictionary:
	var result := _world_choice_state.resolve(
		choice_id,
		option_id,
		_quest_day,
		_quest_state,
		_quest_catalog,
		_faction_state,
		_faction_catalog,
		_region_progression_state,
		_region_progression_catalog
	)
	if not bool(result.get("ok", false)):
		EventBus.interaction_feedback.emit(String(result.get("message", "世界选择失败")), false)
		return result
	_emit_quest_state()
	_emit_faction_state()
	_emit_region_progression_state()
	EventBus.world_choice_state_changed.emit(world_choice_snapshot())
	EventBus.interaction_feedback.emit(String(result["message"]), true)
	return result


func buy_faction_item(faction_id: StringName, item_id: StringName) -> Dictionary:
	var selected := {}
	for offer in _faction_state.shop_offers(faction_id, _faction_catalog):
		if StringName(offer.get("item_id", "")) == item_id:
			selected = offer
			break
	if selected.is_empty() or not bool(selected.get("unlocked", false)):
		var locked_message := "当前阵营等级尚未解锁该物资"
		EventBus.interaction_feedback.emit(locked_message, false)
		return {"ok": false, "message": locked_message}
	var inventory := _harvest_state.inventory_model()
	var price := int(selected["price"])
	if inventory.quantity(&"coin") < price:
		var coin_message := "边境币不足"
		EventBus.interaction_feedback.emit(coin_message, false)
		return {"ok": false, "message": coin_message}
	var before := inventory.snapshot()
	inventory.remove_item(&"coin", price)
	var add_result := inventory.add_item(item_id, int(selected["quantity"]))
	if int(add_result["remainder"]) > 0:
		inventory.restore_snapshot(before)
		var space_message := "背包空间不足，交易已撤销"
		EventBus.interaction_feedback.emit(space_message, false)
		return {"ok": false, "message": space_message}
	_faction_state.adjust(faction_id, _faction_catalog.action_value(&"trade"), "faction_shop:%s" % item_id, _faction_catalog)
	_emit_tool_and_inventory()
	_emit_faction_state()
	var message := "从%s购得%s ×%d" % [
		String(_faction_catalog.faction(faction_id).get("display_name", faction_id)),
		_item_catalog.display_name(item_id),
		int(selected["quantity"]),
	]
	EventBus.interaction_feedback.emit(message, true)
	return {"ok": true, "message": message, "price": price}


func contest_faction_control_point(point_id: String, faction_id: StringName, amount: int) -> Dictionary:
	var result := _faction_state.contest_control_point(point_id, faction_id, amount, _faction_catalog)
	if bool(result.get("ok", false)):
		_emit_faction_state()
		EventBus.interaction_feedback.emit("控制点已被夺取" if bool(result.get("captured", false)) else "控制点影响力正在动摇", true)
	else:
		EventBus.interaction_feedback.emit(String(result.get("message", "无法争夺控制点")), false)
	return result


func continue_npc_dialogue() -> Dictionary:
	return _npc_director.continue_current_dialogue() if _npc_director != null else {}


func close_npc_interaction() -> void:
	if _npc_director != null:
		_npc_director.close_interaction()


func buy_from_current_npc(item_id: StringName) -> Dictionary:
	return _npc_director.buy_current(item_id) if _npc_director != null else {"ok": false}


func sell_to_current_npc(item_id: StringName) -> Dictionary:
	return _npc_director.sell_current(item_id) if _npc_director != null else {"ok": false}


func gift_to_current_npc(item_id: StringName) -> Dictionary:
	return _npc_director.gift_current(item_id) if _npc_director != null else {"ok": false}


func request_sleep_at_current_npc() -> bool:
	return _npc_director.request_sleep_current() if _npc_director != null else false


func exploration_snapshot() -> Dictionary:
	var snapshot := _exploration_state.status_snapshot()
	snapshot["player_chunk"] = _current_chunk
	snapshot["world_layer"] = String(_world_layer)
	snapshot["world_layer_name"] = _world_layer_display_name()
	snapshot["travel_points"] = _exploration_state.travel_points()
	snapshot["defeated_regional_bosses"] = _regional_boss_state.defeated_count()
	return snapshot


func add_custom_map_marker(display_name := "自定义标记") -> String:
	if _world_layer != &"surface" or _player == null:
		EventBus.interaction_feedback.emit("只能在地表添加探索标记", false)
		return ""
	var marker_id := _exploration_state.add_custom_marker(
		WorldCoordinates.world_pixel_to_tile(_player.global_position),
		display_name
	)
	if marker_id.is_empty():
		EventBus.interaction_feedback.emit("无法添加标记：该区域未发现或标记已达上限", false)
		return ""
	_emit_exploration_state()
	EventBus.interaction_feedback.emit("已在当前位置添加地图标记", true)
	return marker_id


func remove_custom_map_marker(marker_id: String) -> bool:
	if not _exploration_state.remove_custom_marker(marker_id):
		return false
	_emit_exploration_state()
	return true


func try_fast_travel(marker_id: String) -> bool:
	if _world_layer != &"surface" or _player == null or _player.combat_state().status == &"dead":
		EventBus.interaction_feedback.emit("当前状态无法快速旅行", false)
		return false
	var target_position := _exploration_state.travel_world_position(marker_id)
	if not target_position.is_finite():
		EventBus.interaction_feedback.emit("该地点尚未解锁快速旅行", false)
		return false
	if not _relocate_within_current_layer(target_position):
		EventBus.interaction_feedback.emit("快速旅行失败", false)
		return false
	EventBus.interaction_feedback.emit("快速旅行完成", true)
	return true


func _relocate_within_current_layer(target_position: Vector2) -> bool:
	if _player == null or not target_position.is_finite():
		return false
	_wait_for_all_jobs()
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		if is_instance_valid(renderer):
			renderer.queue_free()
	_renderers.clear()
	_cache.clear()
	_queue.clear()
	_preload_targets.clear()
	_player.global_position = target_position
	_player.velocity = Vector2.ZERO
	_current_chunk = WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(target_position))
	_cache[_current_chunk] = _generate_chunk(_current_chunk)
	if _enemy_director != null:
		_enemy_director.reset_for_relocation()
	_refresh_grave_markers()
	_refresh_targets()
	_update_exploration()
	_emit_metrics()
	return true


func opened_cave_chest_count() -> int:
	return _opened_cave_chests.size()


func is_near_cave_torch(radius_pixels := 240.0) -> bool:
	return _world_layer == &"underground" and not _nearest_cave_feature(CaveGenerator.Feature.TORCH, radius_pixels).is_empty()


func restore_persistence(snapshot: Dictionary) -> void:
	_pending_persistence = snapshot.duplicate(true)
	if is_inside_tree() and not _tool_ids.is_empty():
		_restore_pending_persistence()
		_refresh_grave_markers()


func persistence_snapshot() -> Dictionary:
	var snapshot := _harvest_state.persistence_snapshot()
	snapshot["active_tool"] = String(active_tool_id())
	snapshot["crafting_state"] = _crafting_system.persistence_snapshot() if _crafting_system != null else {}
	snapshot["grave_state"] = _grave_model.persistence_snapshot()
	snapshot["milestone_state"] = _milestone_state.persistence_snapshot()
	snapshot["world_layer"] = String(_world_layer)
	snapshot["opened_cave_chests"] = _opened_cave_chests.keys()
	(snapshot["opened_cave_chests"] as Array).sort()
	snapshot["dungeon_state"] = _dungeon_state.persistence_snapshot()
	snapshot["exploration_state"] = _exploration_state.persistence_snapshot()
	snapshot["regional_boss_state"] = _regional_boss_state.persistence_snapshot()
	snapshot["npc_state"] = _npc_state.persistence_snapshot()
	snapshot["relationship_state"] = _relationship_state.persistence_snapshot()
	snapshot["quest_state"] = _quest_state.persistence_snapshot()
	snapshot["world_choice_state"] = _world_choice_state.persistence_snapshot()
	snapshot["faction_state"] = _faction_state.persistence_snapshot()
	snapshot["world_event_state"] = _world_event_state.persistence_snapshot()
	snapshot["region_progression_state"] = _region_progression_state.persistence_snapshot()
	snapshot["building_state"] = _building_state.persistence_snapshot()
	snapshot["farming_state"] = _farming_state.persistence_snapshot()
	snapshot["husbandry_state"] = _husbandry_state.persistence_snapshot()
	snapshot["homestead_state"] = _homestead_state.persistence_snapshot()
	snapshot["equipment_state"] = _equipment_state.persistence_snapshot()
	snapshot["boat_state"] = _boat_state.persistence_snapshot()
	return snapshot


func inventory_state_snapshot() -> Dictionary:
	return _harvest_state.inventory_state_snapshot()


func move_inventory_slot(from_index: int, to_index: int) -> bool:
	var changed := _harvest_state.move_inventory_slot(from_index, to_index)
	if changed:
		_emit_inventory_state()
	else:
		EventBus.interaction_feedback.emit(_harvest_state.inventory_model().last_error, false)
	return changed


func split_inventory_stack(from_index: int, to_index: int, quantity := -1) -> bool:
	var changed := _harvest_state.split_inventory_stack(from_index, to_index, quantity)
	if changed:
		_emit_inventory_state()
	else:
		EventBus.interaction_feedback.emit(_harvest_state.inventory_model().last_error, false)
	return changed


func discard_inventory_slot(index: int, quantity := -1) -> bool:
	var removed := _harvest_state.discard_inventory_slot(index, quantity)
	if removed.is_empty():
		EventBus.interaction_feedback.emit(_harvest_state.inventory_model().last_error, false)
		return false
	var item_id := StringName(removed["item_id"])
	var amount := int(removed["quantity"])
	var metadata := {}
	if removed.has("durability"):
		metadata["durability"] = int(removed["durability"])
	if _drop_pool == null or not _drop_pool.spawn_drop(item_id, amount, _player.global_position + Vector2(18, 10), metadata):
		_harvest_state.inventory_model().add_item(item_id, amount, int(removed.get("durability", -1)))
		EventBus.interaction_feedback.emit("地面掉落池已满，物品已退回背包", false)
		_emit_inventory_state()
		return false
	EventBus.interaction_feedback.emit("已丢弃%s ×%d" % [_resource_catalog.item_display_name(item_id), amount], true)
	_emit_inventory_state()
	return true


func sort_inventory() -> void:
	_harvest_state.sort_inventory()
	_emit_inventory_state()
	EventBus.interaction_feedback.emit("背包已按分类整理", true)


func select_hotbar_slot(index: int) -> bool:
	var changed := _harvest_state.select_hotbar_slot(index)
	if changed:
		_emit_tool_and_inventory()
		_update_resource_prompt()
	return changed


func crafting_views() -> Array[Dictionary]:
	return _crafting_system.recipe_views() if _crafting_system != null else []


func craft_recipe(recipe_id: StringName) -> Dictionary:
	if _crafting_system == null:
		return {"ok": false, "message": "制作系统尚未就绪"}
	var result := _crafting_system.craft(recipe_id)
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	_emit_tool_and_inventory()
	return result


func processing_state_snapshot() -> Dictionary:
	if _processing_system == null or _player == null:
		return {"schema_version": 1, "stations": [], "fuels": [], "recipes": []}
	return _processing_system.state_snapshot(
		WorldCoordinates.world_pixel_to_tile(_player.global_position),
		_world_layer == &"surface"
	)


func add_processing_fuel(station_id: StringName, fuel_item_id: StringName) -> Dictionary:
	if _processing_system == null or _player == null:
		return {"ok": false, "message": "加工系统尚未就绪"}
	if _world_layer != &"surface":
		return {"ok": false, "message": "加工设备只能在地表使用"}
	var result := _processing_system.add_fuel(
		station_id,
		fuel_item_id,
		WorldCoordinates.world_pixel_to_tile(_player.global_position)
	)
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	if bool(result["ok"]):
		var placement := result["placement"] as Dictionary
		var tile_value := placement["world_tile"] as Array
		_refresh_player_buildings(WorldCoordinates.tile_to_chunk(Vector2i(int(tile_value[0]), int(tile_value[1]))))
	_emit_tool_and_inventory()
	_emit_processing_state()
	return result


func process_recipe(recipe_id: StringName) -> Dictionary:
	if _processing_system == null or _player == null:
		return {"ok": false, "message": "加工系统尚未就绪"}
	if _world_layer != &"surface":
		return {"ok": false, "message": "加工设备只能在地表使用"}
	var result := _processing_system.process(recipe_id, WorldCoordinates.world_pixel_to_tile(_player.global_position))
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	if bool(result["ok"]):
		var placement := result["placement"] as Dictionary
		var tile_value := placement["world_tile"] as Array
		_refresh_player_buildings(WorldCoordinates.tile_to_chunk(Vector2i(int(tile_value[0]), int(tile_value[1]))))
	_emit_tool_and_inventory()
	_emit_processing_state()
	return result


func automation_state_snapshot() -> Dictionary:
	if _automation_system == null or _player == null:
		return {"schema_version": 1, "machine_count": 0, "machine_limit": _automation_catalog.max_machines(), "machines": []}
	return _automation_system.state_snapshot(WorldCoordinates.world_pixel_to_tile(_player.global_position))


func homestead_state_snapshot() -> Dictionary:
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position) if _player != null else Vector2i.ZERO
	return _homestead_state.status_snapshot(
		_building_state,
		_farming_state,
		_husbandry_state,
		_world_event_time_seconds,
		player_tile,
		_world_layer
	)


func set_active_home(base_id: String) -> Dictionary:
	var result := _homestead_state.set_active_home(base_id)
	EventBus.interaction_feedback.emit(String(result.get("message", "无法设置家园")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_emit_homestead_state()
	return result


func try_home_teleport() -> Dictionary:
	if _player == null or _player.combat_state().status == &"dead":
		var unavailable := {"ok": false, "message": "当前状态无法返回家园"}
		EventBus.interaction_feedback.emit(unavailable["message"], false)
		return unavailable
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	var plan := _homestead_state.teleport_plan(_world_event_time_seconds, _world_layer, player_tile)
	if not bool(plan.get("ok", false)):
		EventBus.interaction_feedback.emit(String(plan.get("message", "无法返回家园")), false)
		return plan
	var tile_value := plan["world_tile"] as Array
	var target_position := WorldCoordinates.tile_to_world_pixel(Vector2i(int(tile_value[0]), int(tile_value[1])), true)
	var relocated := _relocate_within_current_layer(target_position) if _world_layer == &"surface" \
			else _switch_world_layer_internal(&"surface", target_position)
	if not relocated or not _homestead_state.commit_home_teleport(_world_event_time_seconds):
		var failed := {"ok": false, "message": "家园传送未能完成"}
		EventBus.interaction_feedback.emit(failed["message"], false)
		return failed
	var result := {
		"ok": true,
		"message": "已返回家园：%s" % plan["display_name"],
		"base_id": String(plan["base_id"]),
		"world_tile": plan["world_tile"],
	}
	_emit_homestead_state()
	EventBus.interaction_feedback.emit(result["message"], true)
	return result


func toggle_automation_machine(placement_id: String) -> Dictionary:
	return _automation_action(_automation_system.toggle_machine(placement_id) if _automation_system != null else {})


func cycle_automation_recipe(placement_id: String) -> Dictionary:
	return _automation_action(_automation_system.cycle_recipe(placement_id) if _automation_system != null else {})


func cycle_automation_filter(placement_id: String) -> Dictionary:
	return _automation_action(_automation_system.cycle_filter(placement_id) if _automation_system != null else {})


func _automation_action(result: Dictionary) -> Dictionary:
	EventBus.interaction_feedback.emit(String(result.get("message", "自动化操作失败")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		var placement := result.get("placement", {}) as Dictionary
		if not placement.is_empty():
			var tile_value := placement.get("world_tile", []) as Array
			_refresh_player_buildings(WorldCoordinates.tile_to_chunk(Vector2i(int(tile_value[0]), int(tile_value[1]))))
		_emit_building_state()
	_emit_automation_state()
	return result


func equipment_state_snapshot() -> Dictionary:
	return _equipment_state.status_snapshot(_harvest_state.inventory_model())


func equipment_persistence_snapshot() -> Dictionary:
	return _equipment_state.persistence_snapshot()


func equipment_attack_bonus() -> float:
	return float(_equipment_state.stats_snapshot().get("attack", 0.0))


func equipment_comparison(instance_id: int) -> Dictionary:
	return _equipment_state.comparison(instance_id)


func import_equipment_slot(slot_index: int) -> Dictionary:
	var result := _equipment_state.import_inventory_slot(_harvest_state.inventory_model(), slot_index, _world_seed)
	EventBus.interaction_feedback.emit(String(result.get("message", "装备登记失败")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_apply_equipment_effects()
		_emit_tool_and_inventory()
	_emit_equipment_state()
	return result


func equip_equipment_instance(instance_id: int, preferred_slot: StringName = &"") -> Dictionary:
	var result := _equipment_state.equip(instance_id, preferred_slot)
	EventBus.interaction_feedback.emit(String(result.get("message", "装备失败")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_apply_equipment_effects()
	_emit_equipment_state()
	return result


func unequip_equipment_slot(slot_id: StringName) -> Dictionary:
	var result := _equipment_state.unequip(slot_id)
	EventBus.interaction_feedback.emit(String(result.get("message", "卸下失败")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_apply_equipment_effects()
	_emit_equipment_state()
	return result


func enhance_equipment(instance_id: int) -> Dictionary:
	var result := _equipment_state.enhance(instance_id, _harvest_state.inventory_model())
	EventBus.interaction_feedback.emit(String(result.get("message", "强化失败")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_apply_equipment_effects()
		_emit_tool_and_inventory()
	_emit_equipment_state()
	return result


func repair_equipment(instance_id: int) -> Dictionary:
	var result := _equipment_state.repair(instance_id, _harvest_state.inventory_model())
	EventBus.interaction_feedback.emit(String(result.get("message", "修理失败")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_apply_equipment_effects()
		_emit_tool_and_inventory()
	_emit_equipment_state()
	return result


func _building_context(world_tile: Vector2i, chunk: ChunkData) -> Dictionary:
	var local := WorldCoordinates.tile_to_local(world_tile)
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	return {
		"world_layer": _world_layer,
		"player_tile": player_tile,
		"player_occupied": player_tile == world_tile,
		"in_water": chunk.world_layer == &"surface" and HydrologyGenerator.is_water(chunk.water_feature_at(local)),
		"generated_overlay": chunk.has_built_overlay_at(local),
		"resource_occupied": _resource_occupied_at(chunk, local),
		"farming_occupied": not _farming_state.plot_at(world_tile).is_empty(),
		"husbandry_occupied": _husbandry_occupied_at(world_tile),
	}


func _farming_context(world_tile: Vector2i, chunk: ChunkData) -> Dictionary:
	var local := WorldCoordinates.tile_to_local(world_tile)
	var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
	return {
		"world_layer": _world_layer,
		"player_tile": player_tile,
		"player_occupied": player_tile == world_tile,
		"in_water": chunk.world_layer == &"surface" and HydrologyGenerator.is_water(chunk.water_feature_at(local)),
		"generated_overlay": chunk.has_built_overlay_at(local),
		"resource_occupied": _resource_occupied_at(chunk, local),
		"building_occupied": not _building_state.placement_at(world_tile, &"ground").is_empty() \
			or not _building_state.placement_at(world_tile, &"structure").is_empty() \
			or not _building_state.placement_at(world_tile, &"roof").is_empty(),
		"husbandry_occupied": _husbandry_occupied_at(world_tile),
	}


func _husbandry_occupied_at(world_tile: Vector2i) -> bool:
	return not _husbandry_state.animal_at(world_tile).is_empty() or not _wild_candidate_at(world_tile).is_empty()


func _wild_candidate_at(world_tile: Vector2i) -> Dictionary:
	if _world_layer != &"surface" or _husbandry_planner == null:
		return {}
	var coordinate := WorldCoordinates.tile_to_chunk(world_tile)
	var chunk := _cache.get(coordinate) as ChunkData
	if chunk == null:
		return {}
	for value in _husbandry_planner.candidates_for_chunk(chunk):
		var candidate := value as Dictionary
		if _record_world_tile(candidate) == world_tile:
			return candidate.duplicate(true)
	return {}


func _wild_candidates_for_chunk(coordinate: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _world_layer != &"surface" or _husbandry_planner == null:
		return result
	var chunk := _cache.get(coordinate) as ChunkData
	if chunk == null:
		return result
	for value in _husbandry_planner.candidates_for_chunk(chunk):
		var candidate := value as Dictionary
		if not _husbandry_state.animal_by_id(String(candidate["animal_id"])).is_empty():
			continue
		var tile := _record_world_tile(candidate)
		if not _farming_state.plot_at(tile).is_empty() \
				or not _building_state.placement_at(tile, &"ground").is_empty() \
				or not _building_state.placement_at(tile, &"structure").is_empty() \
				or not _building_state.placement_at(tile, &"roof").is_empty():
			continue
		result.append(candidate.duplicate(true))
	return result


func _record_world_tile(record: Dictionary) -> Vector2i:
	var tile_value := record.get("world_tile", [0, 0]) as Array
	return Vector2i(int(tile_value[0]), int(tile_value[1]))


func _find_husbandry_offspring_tile(first_tile: Vector2i, second_tile: Vector2i) -> Vector2i:
	var center := Vector2i(floori(float(first_tile.x + second_tile.x) * 0.5), floori(float(first_tile.y + second_tile.y) * 0.5))
	for offset in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var target: Vector2i = center + (offset as Vector2i)
		if not _husbandry_state.animal_at(target).is_empty() or not _wild_candidate_at(target).is_empty() \
				or not _farming_state.plot_at(target).is_empty() \
				or not _building_state.placement_at(target, &"ground").is_empty() \
				or not _building_state.placement_at(target, &"structure").is_empty() \
				or not _building_state.placement_at(target, &"roof").is_empty():
			continue
		var chunk := _cache.get(WorldCoordinates.tile_to_chunk(target)) as ChunkData
		if chunk == null:
			continue
		var local := WorldCoordinates.tile_to_local(target)
		if HydrologyGenerator.is_water(chunk.water_feature_at(local)) or chunk.has_built_overlay_at(local) or _resource_occupied_at(chunk, local):
			continue
		return target
	return first_tile


func _resource_occupied_at(chunk: ChunkData, local: Vector2i) -> bool:
	for index in chunk.resource_count():
		if chunk.resource_local_at(index) != local:
			continue
		if not _harvest_state.collected_resources.has(chunk.resource_key_at(index)):
			return true
	return false


func _refresh_player_buildings(coordinate: Vector2i) -> void:
	var renderer := _renderers.get(coordinate) as ChunkRenderer
	if renderer == null:
		return
	var placements: Array[Dictionary] = []
	if _world_layer == &"surface":
		placements = _building_state.placements_for_chunk(coordinate)
	renderer.set_player_buildings(placements)


func _refresh_farming_plots(coordinate: Vector2i) -> void:
	var renderer := _renderers.get(coordinate) as ChunkRenderer
	if renderer == null:
		return
	var plots: Array[Dictionary] = []
	if _world_layer == &"surface":
		plots = _farming_state.plots_for_chunk(coordinate)
	renderer.set_farming_plots(plots)


func _refresh_husbandry_animals(coordinate: Vector2i) -> void:
	var renderer := _renderers.get(coordinate) as ChunkRenderer
	if renderer == null:
		return
	var wild_animals: Array[Dictionary] = []
	var interacted_animals: Array[Dictionary] = []
	if _world_layer == &"surface":
		wild_animals = _wild_candidates_for_chunk(coordinate)
		interacted_animals = _husbandry_state.animals_for_chunk(coordinate)
	renderer.set_husbandry_animals(wild_animals, interacted_animals)


func _update_building_context() -> void:
	if _crafting_system == null or _player == null:
		return
	var stations: Array[StringName] = []
	if _world_layer == &"surface":
		stations = _building_state.nearby_station_ids(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	if stations == _nearby_building_stations:
		return
	_nearby_building_stations = stations
	_crafting_system.set_external_stations(stations)
	EventBus.crafting_state_changed.emit(_crafting_system.recipe_views())


func _emit_building_state() -> void:
	EventBus.building_state_changed.emit(building_state_snapshot())
	_emit_homestead_state()


func _emit_farming_state() -> void:
	EventBus.farming_state_changed.emit(farming_state_snapshot())
	_emit_homestead_state()


func _emit_husbandry_state() -> void:
	EventBus.husbandry_state_changed.emit(husbandry_state_snapshot())
	_emit_homestead_state()


func _emit_processing_state() -> void:
	EventBus.processing_state_changed.emit(processing_state_snapshot())


func _emit_automation_state() -> void:
	EventBus.automation_state_changed.emit(automation_state_snapshot())


func _emit_homestead_state() -> void:
	EventBus.homestead_state_changed.emit(homestead_state_snapshot())


func _sync_homestead_markers() -> void:
	var result := _homestead_state.synchronize_markers(_building_state, _world_event_time_seconds)
	if not bool(result.get("ok", false)):
		push_error("Unable to synchronize homestead markers: %s" % _homestead_state.last_error)


func _farming_feedback(result: Dictionary) -> Dictionary:
	EventBus.interaction_feedback.emit(String(result.get("message", "农业操作失败")), bool(result.get("ok", false)))
	return result


func _husbandry_feedback(result: Dictionary) -> Dictionary:
	EventBus.interaction_feedback.emit(String(result.get("message", "养殖操作失败")), bool(result.get("ok", false)))
	return result


func metrics_snapshot() -> Dictionary:
	var preload_ready := 0
	var sleeping := 0
	for coordinate in _cache.keys():
		var distance := ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk)
		if distance > ChunkStreamPlanner.ACTIVE_RADIUS and distance <= ChunkStreamPlanner.PRELOAD_RADIUS:
			preload_ready += 1
		elif distance > ChunkStreamPlanner.PRELOAD_RADIUS:
			sleeping += 1
	var current_data := _cache.get(_current_chunk) as ChunkData
	var biome_name := "生成中"
	var temperature := 0.0
	var moisture := 0.0
	var elevation := 0.0
	var erosion := 0.0
	var active_resources := 0
	for renderer_value in _renderers.values():
		active_resources += (renderer_value as ChunkRenderer).visible_resource_count()
	if current_data != null:
		var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
		var local := WorldCoordinates.tile_to_local(player_tile)
		biome_name = _catalog.display_name_for_code(current_data.biome_at(local))
		temperature = current_data.temperature_at(local)
		moisture = current_data.moisture_at(local)
		elevation = current_data.elevation_at(local)
		erosion = current_data.erosion_at(local)
	return {
		"current_chunk": _current_chunk,
		"current_checksum": current_data.checksum if current_data != null else "生成中",
		"active": _renderers.size(),
		"preload": preload_ready,
		"sleeping": sleeping,
		"cache": _cache.size(),
		"queued": _queue.size(),
		"generating": _task_ids.size(),
		"completed_total": _completed_total,
		"unloaded_total": _unloaded_total,
		"peak_cache": _peak_cache,
		"peak_memory_mb": _peak_memory_mb,
		"view_mode": ChunkRenderer.view_mode_name(_view_mode),
		"boundaries": _show_boundaries,
		"biome_name": biome_name,
		"temperature": temperature,
		"moisture": moisture,
		"elevation": elevation,
		"erosion": erosion,
		"active_resources": active_resources,
		"collected_resources": _harvest_state.collected_resources.size(),
		"active_drops": _drop_pool.active_count() if _drop_pool != null else 0,
		"active_enemies": _enemy_director.active_count() if _enemy_director != null else 0,
		"sleeping_enemies": _enemy_director.sleeping_count() if _enemy_director != null else 0,
		"ruin_discovered": _milestone_state.ruin_discovered,
		"boss_defeated": _milestone_state.boss_defeated,
		"reward_claimed": _milestone_state.reward_claimed,
		"drop_pool_capacity": _resource_catalog.drop_pool_capacity(),
		"active_tool": active_tool_id(),
		"world_layer": _world_layer,
		"world_layer_name": _world_layer_display_name(),
		"opened_cave_chests": _opened_cave_chests.size(),
		"near_cave_torch": is_near_cave_torch(),
		"dungeon_id": _dungeon_state.current_dungeon_id(),
		"dungeon_completed": bool(_dungeon_state.current_run().get("completed", false)),
		"discovered_chunks": _exploration_state.discovered_count(),
		"map_markers": _exploration_state.markers().size(),
		"regional_bosses_defeated": _regional_boss_state.defeated_count(),
		"active_npcs": _npc_director.active_count() if _npc_director != null else 0,
		"sleeping_npcs": _npc_director.sleeping_count() if _npc_director != null else 0,
		"active_quests": _quest_state.active_count(),
		"faction_control_points": (_faction_state.status_snapshot(_faction_catalog).get("control_points", []) as Array).size(),
		"active_world_events": _world_event_state.active_count(),
		"world_progress_points": _region_progression_state.world_progress_points(),
		"discovered_regions": _region_progression_state.region_count(),
		"gear_score": _region_progression_catalog.gear_score(_harvest_state.inventory_model().snapshot()),
		"player_buildings": _building_state.placement_count(),
		"automation_machines": _building_state.automation_count(),
		"homestead_bases": _homestead_state.base_count(),
		"nearby_building_stations": _nearby_building_stations.size(),
		"farming_plots": _farming_state.plot_count(),
		"mature_crops": _farming_state.mature_count(),
		"husbandry_animals": _husbandry_state.animal_count(),
		"tamed_animals": _husbandry_state.tamed_count(),
		"ready_animal_products": _husbandry_state.ready_product_count(),
		"near_player_heat": is_near_player_heat_source(),
	}


func cached_checksum(coordinate: Vector2i) -> String:
	var data := _cache.get(coordinate) as ChunkData
	return data.checksum if data != null else ""


func _refresh_targets() -> void:
	var active_targets := ChunkStreamPlanner.coordinates_in_radius(_current_chunk, ChunkStreamPlanner.ACTIVE_RADIUS)
	var active_set := _coordinate_set(active_targets)
	var preload_targets := ChunkStreamPlanner.coordinates_in_radius(_current_chunk, ChunkStreamPlanner.PRELOAD_RADIUS)
	_preload_targets = _coordinate_set(preload_targets)
	var filtered_queue: Array[Vector2i] = []
	for coordinate in _queue:
		if _preload_targets.has(coordinate):
			filtered_queue.append(coordinate)
	_queue = filtered_queue
	for coordinate in preload_targets:
		if not _cache.has(coordinate) and not _task_ids.has(coordinate) and not _queue.has(coordinate):
			_queue.append(coordinate)
	_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return ChunkStreamPlanner.priority_score(a, _current_chunk, _movement_direction) < ChunkStreamPlanner.priority_score(b, _current_chunk, _movement_direction)
	)
	for coordinate in _renderers.keys():
		if not active_set.has(coordinate):
			var renderer := _renderers[coordinate] as ChunkRenderer
			renderer.queue_free()
			_renderers.erase(coordinate)
	for coordinate in _cache.keys():
		if ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) > ChunkStreamPlanner.CACHE_RADIUS:
			_cache.erase(coordinate)
			_unloaded_total += 1
	for coordinate in active_targets:
		_activate_cached_chunk(coordinate)
	_peak_cache = maxi(_peak_cache, _cache.size())


func _dispatch_jobs() -> void:
	while _task_ids.size() < MAX_CONCURRENT_JOBS and not _queue.is_empty():
		var coordinate: Vector2i = _queue.pop_front()
		if _cache.has(coordinate) or _task_ids.has(coordinate):
			continue
		var context := _dungeon_context()
		var job := ChunkGenerationJob.new(
			_world_seed,
			coordinate,
			_world_layer,
			String(context.get("dungeon_id", "")),
			context.get("anchor_chunk", Vector2i.ZERO) as Vector2i
		)
		var high_priority := ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) <= 1
		var task_id := WorkerThreadPool.add_task(job.execute, high_priority, "chunk_%d_%d" % [coordinate.x, coordinate.y])
		_jobs[coordinate] = job
		_task_ids[coordinate] = task_id


func _collect_completed_jobs() -> void:
	for coordinate in _task_ids.keys():
		var task_id: int = _task_ids[coordinate]
		if not WorkerThreadPool.is_task_completed(task_id):
			continue
		var error := WorkerThreadPool.wait_for_task_completion(task_id)
		var job := _jobs[coordinate] as ChunkGenerationJob
		_task_ids.erase(coordinate)
		_jobs.erase(coordinate)
		if error != OK:
			push_error("Chunk generation task failed for %s: %s" % [coordinate, error_string(error)])
			continue
		if job.result == null:
			push_error("Chunk generation task returned no data for %s" % coordinate)
			continue
		_completed_total += 1
		if ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) <= ChunkStreamPlanner.CACHE_RADIUS:
			_cache[coordinate] = job.result
			_activate_cached_chunk(coordinate)
		else:
			_unloaded_total += 1
	_peak_cache = maxi(_peak_cache, _cache.size())


func _activate_cached_chunk(coordinate: Vector2i) -> void:
	if _renderers.has(coordinate) or not _cache.has(coordinate):
		return
	if ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) > ChunkStreamPlanner.ACTIVE_RADIUS:
		return
	var renderer := ChunkRenderer.new()
	add_child(renderer)
	renderer.set_collected_resources(_harvest_state.collected_resources)
	renderer.set_opened_cave_chests(_opened_cave_chests)
	renderer.set_dungeon_state(_dungeon_state.current_dungeon_id(), _dungeon_state.current_run())
	var player_buildings: Array[Dictionary] = []
	if _world_layer == &"surface":
		player_buildings = _building_state.placements_for_chunk(coordinate)
	renderer.set_player_buildings(player_buildings)
	var farming_plots: Array[Dictionary] = []
	if _world_layer == &"surface":
		farming_plots = _farming_state.plots_for_chunk(coordinate)
	renderer.set_farming_plots(farming_plots)
	var wild_animals: Array[Dictionary] = []
	var interacted_animals: Array[Dictionary] = []
	if _world_layer == &"surface":
		wild_animals = _wild_candidates_for_chunk(coordinate)
		interacted_animals = _husbandry_state.animals_for_chunk(coordinate)
	renderer.set_husbandry_animals(wild_animals, interacted_animals)
	renderer.apply_chunk(_cache[coordinate] as ChunkData)
	renderer.set_debug_options(_view_mode, _show_boundaries)
	_renderers[coordinate] = renderer


func _update_renderer_debug_options() -> void:
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		renderer.set_debug_options(_view_mode, _show_boundaries)


func _emit_metrics() -> void:
	_peak_memory_mb = maxf(_peak_memory_mb, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	metrics_changed.emit(metrics_snapshot())


func _collect_nearby_drops() -> void:
	if _drop_pool == null or _player == null:
		return
	var transfer := _drop_pool.transfer_near(
		_player.global_position,
		_resource_catalog.pickup_radius_pixels(),
		func(item_id: StringName, quantity: int, metadata: Dictionary) -> int:
			var result := _harvest_state.inventory_model().add_item(item_id, quantity, int(metadata.get("durability", -1)))
			return int(result["accepted"])
	)
	var pickups := transfer["transferred"] as Array
	var blocked := transfer["blocked"] as Array
	if pickups.is_empty() and blocked.is_empty():
		return
	var messages: Array[String] = []
	for value in pickups:
		var pickup := value as Dictionary
		var item_id := pickup["item_id"] as StringName
		var quantity := int(pickup["quantity"])
		messages.append("%s ×%d" % [_resource_catalog.item_display_name(item_id), quantity])
	_emit_inventory_state()
	if not blocked.is_empty():
		EventBus.interaction_feedback.emit("背包已满，未拾取的物品仍留在地面", false)
	elif not messages.is_empty():
		EventBus.interaction_feedback.emit("拾取 " + "、".join(messages), true)


func _update_resource_prompt() -> void:
	if _world_layer == &"surface":
		var dungeon_entrance := _nearest_structure_marker(StructureCatalog.MarkerKind.DUNGEON_ENTRANCE, 72.0)
		if not dungeon_entrance.is_empty():
			EventBus.resource_prompt_changed.emit("[E] 进入程序化地牢")
			return
	if _world_layer == &"dungeon":
		if not _nearest_dungeon_feature(DungeonGenerator.Feature.EXIT, 72.0).is_empty():
			EventBus.resource_prompt_changed.emit("[E] 离开地牢")
			return
		var key_target := _nearest_dungeon_feature(DungeonGenerator.Feature.KEY, 58.0)
		if not key_target.is_empty() and not (_dungeon_state.current_run().get("collected_keys", []) as Array).has(String(key_target["feature_key"])):
			EventBus.resource_prompt_changed.emit("[E] 拾取地牢钥匙")
			return
		var door_target := _nearest_dungeon_feature(DungeonGenerator.Feature.LOCKED_DOOR, 62.0)
		if not door_target.is_empty() and not (_dungeon_state.current_run().get("unlocked_doors", []) as Array).has(String(door_target["feature_key"])):
			EventBus.resource_prompt_changed.emit("[E] 开锁 · 钥匙 %d" % int(_dungeon_state.current_run().get("key_count", 0)))
			return
		var dungeon_chest := _nearest_dungeon_feature(DungeonGenerator.Feature.CHEST, 62.0)
		if not dungeon_chest.is_empty() and not (_dungeon_state.current_run().get("opened_chests", []) as Array).has(String(dungeon_chest["feature_key"])):
			EventBus.resource_prompt_changed.emit("[E] 打开地牢宝箱")
			return
	else:
		var transition := _nearest_cave_feature(
			CaveGenerator.Feature.EXIT if _world_layer == &"underground" else CaveGenerator.Feature.ENTRANCE,
			72.0
		)
		if not transition.is_empty():
			EventBus.resource_prompt_changed.emit("[E] 返回地表" if _world_layer == &"underground" else "[E] 进入地下洞穴")
			return
		var chest := _nearest_cave_feature(CaveGenerator.Feature.CHEST, 68.0)
		if not chest.is_empty() and not _opened_cave_chests.has(String(chest["feature_key"])):
			EventBus.resource_prompt_changed.emit("[E] 打开地下宝箱")
			return
	if _world_layer == &"surface" and _player != null:
		var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
		var building_target := _building_state.nearest_interaction(player_tile, 2)
		if not building_target.is_empty():
			var interaction := StringName(building_target.get("interaction", ""))
			if interaction == &"door":
				EventBus.resource_prompt_changed.emit("[E] 打开/关闭玩家木门")
			else:
				var selected := _harvest_state.inventory_model().slot(_harvest_state.inventory_model().selected_hotbar_slot())
				EventBus.resource_prompt_changed.emit("[E] 取回储物箱物品" if selected.is_empty() else "[E] 将选中物品存入储物箱")
			return
	if _world_layer == &"surface" and _npc_director != null:
		var npc_prompt := _npc_director.prompt_text()
		if not npc_prompt.is_empty():
			EventBus.resource_prompt_changed.emit(npc_prompt)
			return
	if _world_layer == &"surface" and _ruin_encounter != null:
		var ruin_prompt := _ruin_encounter.prompt_text()
		if not ruin_prompt.is_empty():
			EventBus.resource_prompt_changed.emit(ruin_prompt)
			return
	var nearby_grave := _grave_model.nearest_grave(_player.global_position, 68.0, StringName(_grave_scope())) if _player != null else {}
	if not nearby_grave.is_empty():
		EventBus.resource_prompt_changed.emit("[E] 取回墓碑物品")
		return
	var target := nearest_resource(_resource_catalog.interaction_radius_pixels())
	if target.is_empty():
		EventBus.resource_prompt_changed.emit("")
		return
	var resource_code := int(target["resource_code"])
	var required_tool := _resource_catalog.required_tool_for_code(resource_code)
	var name := _resource_catalog.display_name_for_code(resource_code)
	if active_tool_id() != required_tool:
		EventBus.resource_prompt_changed.emit("[E] %s · 需要%s（当前%s）" % [
			name,
			_resource_catalog.tool_display_name(required_tool),
			active_tool_display_name(),
		])
	else:
		var remaining := _harvest_state.remaining_durability(String(target["resource_key"]), resource_code, _resource_catalog)
		EventBus.resource_prompt_changed.emit("[E] 采集%s · 耐久 %d" % [name, remaining])


func _emit_tool_and_inventory() -> void:
	var tool_id := active_tool_id()
	EventBus.active_tool_changed.emit(tool_id, active_tool_display_name())
	_emit_inventory_state()


func _emit_inventory_state() -> void:
	EventBus.inventory_changed.emit(_harvest_state.inventory_snapshot())
	EventBus.inventory_state_changed.emit(_harvest_state.inventory_state_snapshot())
	if _quest_state.synchronize_collect(_harvest_state.inventory_model().count_snapshot(), _quest_catalog):
		_emit_quest_state()
	if _crafting_system != null:
		_crafting_system.refresh_discoveries()
		EventBus.crafting_state_changed.emit(_crafting_system.recipe_views())
	_emit_region_progression_state()
	_emit_building_state()
	_emit_farming_state()
	_emit_husbandry_state()
	_emit_processing_state()
	_emit_automation_state()
	_emit_equipment_state()


func _restore_pending_persistence() -> void:
	if _pending_persistence.is_empty():
		return
	_harvest_state.restore_snapshot(
		_pending_persistence.get("collected_resources", []) as Array,
		_pending_persistence.get("inventory", {})
	)
	if _crafting_system != null and not _crafting_system.restore_snapshot(_pending_persistence.get("crafting_state", {}) as Dictionary):
		push_error("Unable to restore crafting state: %s" % _crafting_system.last_error)
	if not _grave_model.restore_snapshot(_pending_persistence.get("grave_state", {}) as Dictionary):
		push_error("Unable to restore grave state: %s" % _grave_model.last_error)
	if not _milestone_state.restore_snapshot(_pending_persistence.get("milestone_state", {}) as Dictionary):
		push_error("Unable to restore milestone state: %s" % _milestone_state.last_error)
	if not _dungeon_state.restore_snapshot(_pending_persistence.get("dungeon_state", {}) as Dictionary):
		push_error("Unable to restore dungeon state: %s" % _dungeon_state.last_error)
	if not _exploration_state.restore_snapshot(_pending_persistence.get("exploration_state", {}) as Dictionary):
		push_error("Unable to restore exploration state: %s" % _exploration_state.last_error)
	if not _regional_boss_state.restore_snapshot(_pending_persistence.get("regional_boss_state", {}) as Dictionary):
		push_error("Unable to restore regional boss state: %s" % _regional_boss_state.last_error)
	if not _npc_state.restore_snapshot(_pending_persistence.get("npc_state", {}) as Dictionary):
		push_error("Unable to restore NPC state: %s" % _npc_state.last_error)
	if not _relationship_state.restore_snapshot(_pending_persistence.get("relationship_state", {}) as Dictionary):
		push_error("Unable to restore relationship state: %s" % _relationship_state.last_error)
	if not _quest_state.restore_snapshot(_pending_persistence.get("quest_state", {}) as Dictionary, _quest_catalog):
		push_error("Unable to restore quest state: %s" % _quest_state.last_error)
	if not _world_choice_state.restore_snapshot(_pending_persistence.get("world_choice_state", {}) as Dictionary, _quest_catalog):
		push_error("Unable to restore world-choice state: %s" % _world_choice_state.last_error)
	if not _faction_state.restore_snapshot(_pending_persistence.get("faction_state", {}) as Dictionary, _faction_catalog):
		push_error("Unable to restore faction state: %s" % _faction_state.last_error)
	if not _world_event_state.restore_snapshot(_pending_persistence.get("world_event_state", {}) as Dictionary, _world_event_catalog):
		push_error("Unable to restore world-event state: %s" % _world_event_state.last_error)
	var progression_value := _pending_persistence.get(
		"region_progression_state",
		RegionProgressionState.new().persistence_snapshot()
	) as Dictionary
	if not _region_progression_state.restore_snapshot(progression_value, _region_progression_catalog):
		push_error("Unable to restore region-progression state: %s" % _region_progression_state.last_error)
	var building_value := _pending_persistence.get(
		"building_state",
		BuildingState.new(_building_catalog, _item_catalog).persistence_snapshot()
	) as Dictionary
	if not _building_state.restore_snapshot(building_value):
		push_error("Unable to restore building state: %s" % _building_state.last_error)
	var homestead_value := _pending_persistence.get(
		"homestead_state",
		HomesteadState.new(_homestead_catalog).persistence_snapshot()
	) as Dictionary
	if not _homestead_state.restore_snapshot(homestead_value, _building_state):
		push_error("Unable to restore homestead state: %s" % _homestead_state.last_error)
		_homestead_state = HomesteadState.new(_homestead_catalog)
		_sync_homestead_markers()
	var farming_value := _pending_persistence.get(
		"farming_state",
		FarmingState.new(_world_seed, _farming_catalog, _item_catalog).persistence_snapshot()
	) as Dictionary
	if not _farming_state.restore_snapshot(farming_value):
		push_error("Unable to restore farming state: %s" % _farming_state.last_error)
	var husbandry_value := _pending_persistence.get(
		"husbandry_state",
		HusbandryState.new(_world_seed, _husbandry_catalog, _item_catalog).persistence_snapshot()
	) as Dictionary
	if not _husbandry_state.restore_snapshot(husbandry_value):
		push_error("Unable to restore husbandry state: %s" % _husbandry_state.last_error)
	var equipment_value := _pending_persistence.get(
		"equipment_state",
		EquipmentState.new(_equipment_catalog, _item_catalog).persistence_snapshot()
	) as Dictionary
	if not _equipment_state.restore_snapshot(equipment_value):
		push_error("Unable to restore equipment state: %s" % _equipment_state.last_error)
	var boat_value := _pending_persistence.get(
		"boat_state",
		BoatState.new(_ocean_catalog).persistence_snapshot()
	) as Dictionary
	if not _boat_state.restore_snapshot(boat_value):
		push_error("Unable to restore boat state: %s" % _boat_state.last_error)
	_opened_cave_chests.clear()
	for value in _pending_persistence.get("opened_cave_chests", []) as Array:
		var chest_key := String(value)
		if chest_key.begins_with("underground:"):
			_opened_cave_chests[chest_key] = true
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		if is_instance_valid(renderer):
			renderer.set_opened_cave_chests(_opened_cave_chests)
			renderer.set_dungeon_state(_dungeon_state.current_dungeon_id(), _dungeon_state.current_run())
			var renderer_coordinate := WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(renderer.global_position))
			var player_buildings: Array[Dictionary] = []
			if _world_layer == &"surface":
				player_buildings = _building_state.placements_for_chunk(renderer_coordinate)
			renderer.set_player_buildings(player_buildings)
			var farming_plots: Array[Dictionary] = []
			if _world_layer == &"surface":
				farming_plots = _farming_state.plots_for_chunk(renderer_coordinate)
			renderer.set_farming_plots(farming_plots)
			var wild_animals: Array[Dictionary] = []
			var interacted_animals: Array[Dictionary] = []
			if _world_layer == &"surface":
				wild_animals = _wild_candidates_for_chunk(renderer_coordinate)
				interacted_animals = _husbandry_state.animals_for_chunk(renderer_coordinate)
			renderer.set_husbandry_animals(wild_animals, interacted_animals)
	_pending_persistence.clear()
	if _enemy_director != null:
		_enemy_director.update_regional_boss_state(_regional_boss_state.persistence_snapshot())
		_enemy_director.update_region_progression_state(region_progression_snapshot())
	_emit_dungeon_state()
	_emit_exploration_state()
	_emit_quest_state()
	_emit_faction_state()
	_emit_world_event_state()
	_emit_region_progression_state()
	_update_building_context()
	_emit_building_state()
	_emit_farming_state()
	_emit_husbandry_state()
	_emit_processing_state()
	_emit_automation_state()
	_emit_homestead_state()
	_apply_equipment_effects()
	_emit_equipment_state()


func _apply_equipment_effects() -> void:
	if _player == null:
		return
	_player.combat_state().set_equipment_defense(float(_equipment_state.stats_snapshot().get("defense", 0.0)))


func _emit_equipment_state() -> void:
	EventBus.equipment_state_changed.emit(equipment_state_snapshot())


func _update_exploration() -> void:
	if _world_layer != &"surface" or _discovery_scanner == null:
		_emit_exploration_state()
		_emit_region_progression_state()
		return
	var region_profile := _region_progression_model.region_profile(_current_chunk)
	var region_result := _region_progression_state.discover_region(region_profile, _region_progression_catalog)
	if bool(region_result.get("changed", false)):
		EventBus.interaction_feedback.emit("发现%s · 世界进度 +%d" % [region_profile["display_name"], int(region_result.get("gained", 0))], true)
	_exploration_state.reveal_chunk(_current_chunk, 1)
	for y in range(_current_chunk.y - 1, _current_chunk.y + 2):
		for x in range(_current_chunk.x - 1, _current_chunk.x + 2):
			var chunk := Vector2i(x, y)
			for marker_value in _discovery_scanner.markers_for_chunk(chunk):
				var marker := marker_value as Dictionary
				_exploration_state.register_marker(
					String(marker["id"]),
					StringName(marker["type"]),
					String(marker["display_name"]),
					marker["world_tile"] as Vector2i,
					String(marker["color"]),
					bool(marker["travel_enabled"])
				)
	var home_tile := WorldCoordinates.world_pixel_to_tile(_player.combat_state().respawn_position)
	if _exploration_state.is_chunk_discovered(WorldCoordinates.tile_to_chunk(home_tile)):
		_exploration_state.register_marker("home:respawn", &"home", "安全营地", home_tile, "fff0a8", true)
	for boss_id in _regional_boss_state.defeated_ids():
		_exploration_state.mark_completed("boss:%s" % boss_id)
	_synchronize_quest_exploration()
	_emit_exploration_state()
	_emit_region_progression_state()


func _emit_exploration_state() -> void:
	EventBus.exploration_state_changed.emit(exploration_snapshot())


func _on_enemy_defeated_for_quest(spawn_id: String, enemy_id: StringName) -> void:
	if _quest_state.record_event(&"defeat", enemy_id, 1, _quest_catalog):
		_emit_quest_state()
	var faction_result := _faction_state.record_defeat(spawn_id, enemy_id, _faction_catalog)
	if bool(faction_result.get("changed", false)):
		_emit_faction_state()
	_record_world_event(&"defeat", enemy_id)
	var definition := _enemy_director.catalog().enemy(enemy_id) if _enemy_director != null else null
	if spawn_id.begins_with("event-enemy:") and definition != null and definition.role == &"boss":
		_record_world_event(&"defeat_boss", enemy_id)


func _on_progression_enemy_defeated(spawn_id: String, _enemy_id: StringName, region_id: String, _level: int, elite: bool) -> void:
	if not elite or region_id.is_empty():
		return
	var coordinate := _region_progression_catalog.parse_region_id(region_id)
	if coordinate.x == 0x7fffffff:
		return
	var profile := {
		"region_id": region_id,
		"danger_level": _region_progression_catalog.danger_level_for_region(coordinate),
	}
	var result := _region_progression_state.record_elite_defeat(profile, spawn_id, _region_progression_catalog)
	if bool(result.get("changed", false)):
		EventBus.combat_feedback.emit("击败区域精英 · 世界进度 +%d" % int(result.get("gained", 0)), true)
		_emit_region_progression_state()


func _on_npc_talked_for_quest(_npc_id: String, role_id: StringName) -> void:
	if _quest_state.record_event(&"escort", role_id, 1, _quest_catalog):
		_emit_quest_state()
	_record_world_event(&"talk", role_id)


func _on_npc_trade_completed(role_id: StringName) -> void:
	var result := _faction_state.record_trade(role_id, _faction_catalog)
	if bool(result.get("changed", false)):
		_emit_faction_state()
	_record_world_event(&"trade", role_id)


func _synchronize_quest_exploration() -> void:
	var counts := {}
	var faction_changed := false
	for marker in _exploration_state.markers():
		var marker_type := String(marker.get("type", ""))
		counts[marker_type] = int(counts.get(marker_type, 0)) + 1
		if marker_type not in ["custom", "home"]:
			var result := _faction_state.record_discovery(String(marker.get("id", "")), StringName(marker_type), _faction_catalog)
			faction_changed = faction_changed or bool(result.get("changed", false))
			_record_world_event(&"explore", StringName(marker_type))
	if _quest_state.synchronize_explore(counts, _quest_catalog):
		_emit_quest_state()
	if faction_changed:
		_emit_faction_state()


func _emit_quest_state() -> void:
	EventBus.quest_state_changed.emit(quest_snapshot())


func _current_quest_board_id() -> String:
	if _region_progression_model == null:
		return "region:%d:%d" % [_current_chunk.x, _current_chunk.y]
	return String(_region_progression_model.region_profile(_current_chunk).get("region_id", "region:0:0"))


func _emit_faction_state() -> void:
	EventBus.faction_state_changed.emit(_faction_state.status_snapshot(_faction_catalog))


func _record_world_event(action: StringName, target_id: StringName, quantity := 1) -> void:
	var result := _world_event_state.record_event(action, target_id, quantity, _world_event_time_seconds, _world_event_catalog)
	if not bool(result.get("changed", false)):
		return
	_apply_world_event_effects()
	_sync_world_event_encounters()
	_emit_world_event_state()
	for value in result.get("completed", []) as Array:
		var record := value as Dictionary
		var definition := _world_event_catalog.event(StringName(record["event_id"]))
		_record_world_progress(&"world_event_completed", String(record["instance_id"]))
		EventBus.interaction_feedback.emit("世界事件完成：%s" % definition.get("display_name", record["event_id"]), true)


func _apply_world_event_effects() -> void:
	_world_event_resource_multiplier = 1.0 if _world_layer != &"surface" \
		else _world_event_state.effect_multiplier(&"resource_yield_multiplier", _world_event_catalog)
	if _enemy_director != null:
		_enemy_director.set_world_event_population_multiplier(
			_world_event_state.effect_multiplier(&"enemy_population_multiplier", _world_event_catalog) if _world_layer == &"surface" else 1.0
		)


func _sync_world_event_encounters() -> void:
	if _enemy_director == null:
		return
	var active_instance_ids: Array[String] = []
	var active_records := _world_event_state.active_records()
	for record in active_records:
		active_instance_ids.append(String(record["instance_id"]))
	_enemy_director.retain_world_event_instances(active_instance_ids)
	if _world_layer != &"surface" or _player == null:
		return
	for record in active_records:
		var instance_id := String(record["instance_id"])
		match StringName(record["event_id"]):
			&"village_raid":
				var raid_offsets := [Vector2(760, 0), Vector2(-760, 0), Vector2(0, 620)]
				for index in raid_offsets.size():
					_enemy_director.ensure_world_event_enemy(
						instance_id,
						"event-enemy:%s:raider:%d" % [instance_id, index],
						&"bandit_scout",
						_player.global_position + raid_offsets[index]
					)
			&"temporary_boss":
				_enemy_director.ensure_world_event_enemy(
					instance_id,
					"event-enemy:%s:boss" % instance_id,
					&"grove_titan",
					_player.global_position + Vector2(720, 240)
				)


func _emit_world_event_state() -> void:
	if _world_event_planner != null:
		EventBus.world_event_state_changed.emit(world_event_snapshot())


func _record_world_progress(source_type: StringName, source_id: String) -> void:
	var result := _region_progression_state.record_source(source_type, source_id, _region_progression_catalog)
	if not bool(result.get("changed", false)):
		return
	_emit_region_progression_state()


func _emit_region_progression_state() -> void:
	if _region_progression_model == null:
		return
	var snapshot := region_progression_snapshot()
	if _enemy_director != null:
		_enemy_director.update_region_progression_state(snapshot)
	EventBus.region_progression_state_changed.emit(snapshot)


func _consume_active_tool_durability() -> String:
	var inventory := _harvest_state.inventory_model()
	var index := inventory.selected_hotbar_slot()
	var value := inventory.slot(index)
	if value.is_empty():
		return ""
	var item_id := StringName(value["item_id"])
	if not _item_catalog.is_durable(item_id):
		return ""
	var result := inventory.damage_tool_at(index, 1)
	_emit_tool_and_inventory()
	return _item_catalog.display_name(item_id) if bool(result.get("broken", false)) else ""


func _refresh_grave_markers() -> void:
	for marker_value in _grave_markers.values():
		(marker_value as GraveMarker).queue_free()
	_grave_markers.clear()
	for grave in _grave_model.graves():
		if String(grave.get("world_layer", "surface")) != _grave_scope():
			continue
		var position_value := grave["position"] as Array
		var marker := GraveMarker.new()
		marker.configure(int(grave["id"]), Vector2(float(position_value[0]), float(position_value[1])))
		add_child(marker)
		_grave_markers[int(grave["id"])] = marker
	_emit_grave_state()


func _emit_grave_state() -> void:
	EventBus.grave_state_changed.emit({"count": _grave_model.grave_count(), "graves": _grave_model.graves()})


func _emit_dungeon_state() -> void:
	EventBus.dungeon_state_changed.emit(_dungeon_state.status_snapshot())


func _generate_chunk(coordinate: Vector2i) -> ChunkData:
	if _world_layer == &"dungeon":
		var context := _dungeon_context()
		return DungeonGenerator.new(
			_world_seed,
			String(context.get("dungeon_id", "")),
			context.get("anchor_chunk", Vector2i.ZERO) as Vector2i,
			_dungeon_catalog
		).generate_chunk(coordinate)
	if _world_layer == &"underground":
		return CaveGenerator.new(_world_seed).generate_chunk(coordinate)
	return TerrainGenerator.new(_world_seed).generate_chunk(coordinate)


func _dungeon_context() -> Dictionary:
	var run := _dungeon_state.current_run()
	if run.is_empty():
		return {}
	var anchor := run.get("anchor_chunk", [0, 0]) as Array
	return {
		"dungeon_id": _dungeon_state.current_dungeon_id(),
		"anchor_chunk": Vector2i(int(anchor[0]), int(anchor[1])),
		"run_state": run,
	}


func _grave_scope() -> String:
	return _dungeon_state.current_dungeon_id() if _world_layer == &"dungeon" else String(_world_layer)


func _world_layer_display_name() -> String:
	match _world_layer:
		&"underground": return "地下洞穴"
		&"dungeon": return "程序化地牢"
		_: return "地表"


func _coordinate_set(coordinates: Array[Vector2i]) -> Dictionary:
	var result := {}
	for coordinate in coordinates:
		result[coordinate] = true
	return result


func _direction_from_velocity(velocity: Vector2) -> Vector2i:
	if velocity.length_squared() < 1.0:
		return Vector2i.ZERO
	return Vector2i(roundi(signf(velocity.x)), roundi(signf(velocity.y)))


func _wait_for_all_jobs() -> void:
	for coordinate in _task_ids.keys():
		var task_id: int = _task_ids[coordinate]
		var error := WorkerThreadPool.wait_for_task_completion(task_id)
		if error != OK:
			push_error("Unable to await chunk task %s: %s" % [coordinate, error_string(error)])
	_task_ids.clear()
	_jobs.clear()
