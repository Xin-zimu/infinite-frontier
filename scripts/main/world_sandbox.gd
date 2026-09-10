extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const START_CHUNK := Vector2i(-1, -4)
const AUTOSAVE_INTERVAL := 30.0

var _seed_text := WorldSeed.DEFAULT_TEXT
var _world_seed := WorldSeed.from_text(WorldSeed.DEFAULT_TEXT)
var _player: PlayerCharacter
var _stream_manager: ChunkStreamManager
var _generation_hud: GenerationHud
var _inventory_panel: InventoryPanel
var _crafting_panel: CraftingPanel
var _processing_panel: ProcessingPanel
var _equipment_panel: EquipmentPanel
var _automation_panel: AutomationPanel
var _homestead_panel: HomesteadPanel
var _exploration_panel: ExplorationMapPanel
var _npc_panel: NpcInteractionPanel
var _quest_panel: QuestJournalPanel
var _faction_panel: FactionPanel
var _world_event_panel: WorldEventPanel
var _region_progression_panel: RegionProgressionPanel
var _combat_controller: PlayerCombatController
var _survival_catalog := SurvivalCatalog.new()
var _survival_state: SurvivalState
var _survival_hud: SurvivalHud
var _building_panel: BuildingPanel
var _building_preview: BuildingPreview
var _building_rotation := 0
var _farming_panel: FarmingPanel
var _husbandry_panel: HusbandryPanel
var _latest_time_state: Dictionary = {}
var _latest_weather_state: Dictionary = {}
var _survival_emit_elapsed := 0.0
var _game_time_seconds := 0.0
var _autosave_elapsed := 0.0
var _exit_save_requested := false
var _day_night_cycle: DayNightCycle
var _day_night_overlay: DayNightOverlay
var _weather_system: WeatherSystem
var _weather_overlay: WeatherOverlay
var _terrain_generator: TerrainGenerator
var _ocean_catalog := OceanCatalog.new()
var _player_in_deep_water := false
var _player_in_terrain_water := false
var _season_state := SeasonState.new()
var _previous_season_id: StringName = &"spring"


func _ready() -> void:
	GameManager.current_state = GameManager.State.PLAYING
	GameManager.current_scene_path = GameManager.GAME_SCENE
	get_tree().auto_accept_quit = false
	if SaveManager.has_current_world():
		_seed_text = SaveManager.current_seed_text()
		_world_seed = SaveManager.current_seed()
		_game_time_seconds = SaveManager.current_game_time_seconds()
	EventBus.sleep_requested.connect(_on_sleep_requested)
	EventBus.settings_changed.connect(_on_setting_changed)
	_build_world()
	LogManager.info("WorldSandbox", "V%s survival-building loop ready: %s" % [GameVersion.VERSION, SaveManager.current_world_name() if SaveManager.has_current_world() else "temporary"])


func _process(delta: float) -> void:
	_game_time_seconds += delta
	if _player != null and _terrain_generator != null:
		_player.set_surface_feature(
			HydrologyGenerator.Feature.NONE if _stream_manager != null and _stream_manager.world_layer() != &"surface" \
			else _terrain_generator.water_feature_at(WorldCoordinates.world_pixel_to_tile(_player.global_position))
		)
		if _stream_manager != null:
			_apply_ocean_state(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	if _day_night_cycle != null:
		var time_state := _day_night_cycle.advance(delta)
		_latest_time_state = time_state
		_day_night_overlay.apply_time(time_state)
		if _stream_manager != null:
			_day_night_overlay.set_torch_enabled(
				_stream_manager.selected_item_id() == &"torch" \
						or _stream_manager.is_near_cave_torch() \
						or _stream_manager.is_near_player_heat_source()
			)
		EventBus.time_state_changed.emit(time_state)
		var season_day := maxi(1, int(time_state.get("day", 1)))
		if season_day != _season_state.day():
			_season_state.advance_to_day(season_day)
			if _terrain_generator != null:
				_terrain_generator.set_river_freezes(_season_state.river_freezes())
			if _stream_manager != null:
				_stream_manager.set_season_resource_multiplier(_season_state.resource_yield_multiplier())
				_stream_manager.set_season_population_multiplier(_season_state.enemy_population_multiplier())
				_stream_manager.set_season_crop_growth_multiplier(_season_state.crop_growth_multiplier())
			ChunkRenderer.set_season_plant_tint(_season_state.plant_tint())
			var new_season_id := _season_state.season_id()
			if new_season_id != _previous_season_id:
				_previous_season_id = new_season_id
				EventBus.season_state_changed.emit(_season_state.snapshot())
	if _weather_system != null and _weather_overlay != null and _player != null and _stream_manager != null:
		var event_weather := _stream_manager.world_event_weather_override()
		if not event_weather.is_empty():
			_weather_system.transition_to(event_weather)
		var weather_state := _weather_system.update(
			delta,
			WorldCoordinates.world_pixel_to_tile(_player.global_position),
			_stream_manager.current_biome_id(),
			_season_weather_weights()
		)
		_latest_weather_state = weather_state
		_weather_overlay.apply_weather(weather_state)
		_weather_overlay.visible = _stream_manager.world_layer() == &"surface"
		EventBus.weather_state_changed.emit(weather_state)
	_update_survival(delta)
	_update_building_preview()
	_update_farming_target()
	_update_husbandry_target()
	if not SaveManager.has_current_world():
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL:
		_autosave_elapsed = 0.0
		_request_save(false)


func _unhandled_input(event: InputEvent) -> void:
	if _homestead_panel != null and _homestead_panel.is_homestead_open():
		for action in [&"toggle_building", &"toggle_farming", &"toggle_husbandry", &"toggle_inventory", &"toggle_crafting", &"toggle_processing", &"toggle_equipment", &"toggle_automation", &"toggle_map", &"toggle_quests", &"toggle_factions", &"toggle_events", &"toggle_progression"]:
			if event.is_action_pressed(action):
				_homestead_panel.set_homestead_open(false)
				break
	if _automation_panel != null and _automation_panel.is_automation_open():
		for action in [&"toggle_building", &"toggle_farming", &"toggle_husbandry", &"toggle_inventory", &"toggle_crafting", &"toggle_processing", &"toggle_equipment", &"toggle_map", &"toggle_quests", &"toggle_factions", &"toggle_events", &"toggle_progression"]:
			if event.is_action_pressed(action):
				_automation_panel.set_automation_open(false)
				break
	if _equipment_panel != null and _equipment_panel.is_equipment_open():
		for action in [&"toggle_building", &"toggle_farming", &"toggle_husbandry", &"toggle_inventory", &"toggle_crafting", &"toggle_processing", &"toggle_automation", &"toggle_map", &"toggle_quests", &"toggle_factions", &"toggle_events", &"toggle_progression"]:
			if event.is_action_pressed(action):
				_equipment_panel.set_equipment_open(false)
				break
	if _husbandry_panel != null and _husbandry_panel.is_husbandry_open():
		for action in [&"toggle_building", &"toggle_farming", &"toggle_inventory", &"toggle_crafting", &"toggle_processing", &"toggle_equipment", &"toggle_automation", &"toggle_map", &"toggle_quests", &"toggle_factions", &"toggle_events", &"toggle_progression"]:
			if event.is_action_pressed(action):
				_husbandry_panel.set_husbandry_open(false)
				break
	if _processing_panel != null and _processing_panel.is_processing_open():
		for action in [&"toggle_building", &"toggle_farming", &"toggle_husbandry", &"toggle_inventory", &"toggle_crafting", &"toggle_equipment", &"toggle_automation", &"toggle_map", &"toggle_quests", &"toggle_factions", &"toggle_events", &"toggle_progression"]:
			if event.is_action_pressed(action):
				_processing_panel.set_processing_open(false)
				break
	if event.is_action_pressed("pause"):
		if _homestead_panel != null and _homestead_panel.is_homestead_open():
			_homestead_panel.set_homestead_open(false)
			return
		if _automation_panel != null and _automation_panel.is_automation_open():
			_automation_panel.set_automation_open(false)
			return
		if _equipment_panel != null and _equipment_panel.is_equipment_open():
			_equipment_panel.set_equipment_open(false)
			return
		if _processing_panel != null and _processing_panel.is_processing_open():
			_processing_panel.set_processing_open(false)
			return
		if _husbandry_panel != null and _husbandry_panel.is_husbandry_open():
			_husbandry_panel.set_husbandry_open(false)
			return
		if _farming_panel != null and _farming_panel.is_farming_open():
			_farming_panel.set_farming_open(false)
			return
		if _building_panel != null and _building_panel.is_building_open():
			_building_panel.set_building_open(false)
			_building_preview.hide_preview()
			return
		if _region_progression_panel != null and _region_progression_panel.is_progression_open():
			_region_progression_panel.set_progression_open(false)
			return
		if _world_event_panel != null and _world_event_panel.is_event_open():
			_world_event_panel.set_event_open(false)
			return
		if _faction_panel != null and _faction_panel.is_faction_open():
			_faction_panel.set_faction_open(false)
			return
		if _quest_panel != null and _quest_panel.is_quest_open():
			_quest_panel.set_quest_open(false)
			return
		if _npc_panel != null and _npc_panel.is_npc_open():
			_npc_panel.set_npc_open(false)
			return
		if _exploration_panel != null and _exploration_panel.is_map_open():
			_exploration_panel.set_map_open(false)
			return
		if _crafting_panel != null and _crafting_panel.is_crafting_open():
			_crafting_panel.set_crafting_open(false)
			return
		if _inventory_panel != null and _inventory_panel.is_inventory_open():
			_inventory_panel.set_inventory_open(false)
			return
		_request_save(true)
		_exit_save_requested = true
		GameManager.return_to_menu()
	elif event.is_action_pressed("toggle_noise_view"):
		_stream_manager.toggle_noise_view()
	elif event.is_action_pressed("toggle_chunk_borders"):
		_stream_manager.toggle_chunk_boundaries()
	elif event.is_action_pressed("interact"):
		if (_quest_panel != null and _quest_panel.is_quest_open()) or (_faction_panel != null and _faction_panel.is_faction_open()) or (_world_event_panel != null and _world_event_panel.is_event_open()) or (_region_progression_panel != null and _region_progression_panel.is_progression_open()):
			return
		if _npc_panel != null and _npc_panel.is_npc_open():
			_npc_panel.continue_dialogue()
		else:
			_stream_manager.interact()
	elif event.is_action_pressed("cycle_tool"):
		_stream_manager.cycle_active_tool()
	elif event.is_action_pressed("use_food"):
		_try_consume_food()
	elif event.is_action_pressed("toggle_building"):
		_farming_panel.set_farming_open(false)
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_building_panel.toggle_building()
		if not _building_panel.is_building_open():
			_building_preview.hide_preview()
	elif event.is_action_pressed("rotate_building") and _building_panel.is_building_open():
		_building_rotation = (_building_rotation + 90) % 360
		_update_building_preview()
	elif event.is_action_pressed("place_building") and _building_panel.is_building_open():
		_stream_manager.place_building(_building_panel.selected_piece_id(), _building_target_tile(), _building_rotation)
		_update_building_preview()
	elif event.is_action_pressed("demolish_building") and _building_panel.is_building_open():
		_stream_manager.demolish_building(_building_target_tile())
		_update_building_preview()
	elif event.is_action_pressed("toggle_farming"):
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_farming_panel.toggle_farming()
	elif event.is_action_pressed("farm_action") and _farming_panel.is_farming_open():
		_stream_manager.perform_farming_action(_farming_panel.selected_crop_id(), _farming_target_tile())
		_update_farming_target()
	elif event.is_action_pressed("farm_secondary") and _farming_panel.is_farming_open():
		_stream_manager.fertilize_farming_plot(_farming_target_tile())
		_update_farming_target()
	elif event.is_action_pressed("toggle_husbandry"):
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_farming_panel.set_farming_open(false)
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_husbandry_panel.toggle_husbandry()
	elif event.is_action_pressed("husbandry_action") and _husbandry_panel.is_husbandry_open():
		_stream_manager.perform_husbandry_action(_husbandry_panel.selected_animal_type(), _husbandry_target_tile())
		_update_husbandry_target()
	elif event.is_action_pressed("husbandry_secondary") and _husbandry_panel.is_husbandry_open():
		_stream_manager.breed_husbandry_animal(_husbandry_target_tile())
		_update_husbandry_target()
	elif event.is_action_pressed("attack") and not _building_panel.is_building_open() and not _farming_panel.is_farming_open() and not _husbandry_panel.is_husbandry_open() and not _inventory_panel.is_inventory_open() and not _crafting_panel.is_crafting_open() and not _processing_panel.is_processing_open() and not _equipment_panel.is_equipment_open() and not _automation_panel.is_automation_open() and not _homestead_panel.is_homestead_open() and not _exploration_panel.is_map_open() and not _npc_panel.is_npc_open() and not _quest_panel.is_quest_open() and not _faction_panel.is_faction_open() and not _world_event_panel.is_event_open() and not _region_progression_panel.is_progression_open():
		_combat_controller.request_attack()
	elif event.is_action_pressed("manual_save"):
		_request_save(true)
	elif event.is_action_pressed("toggle_inventory"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_inventory_panel.toggle_inventory()
	elif event.is_action_pressed("toggle_crafting"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_crafting_panel.toggle_crafting()
	elif event.is_action_pressed("toggle_processing"):
		_farming_panel.set_farming_open(false)
		_husbandry_panel.set_husbandry_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_processing_panel.toggle_processing()
	elif event.is_action_pressed("toggle_equipment"):
		_farming_panel.set_farming_open(false)
		_husbandry_panel.set_husbandry_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_processing_panel.set_processing_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_equipment_panel.toggle_equipment()
	elif event.is_action_pressed("toggle_automation"):
		_farming_panel.set_farming_open(false)
		_husbandry_panel.set_husbandry_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_processing_panel.set_processing_open(false)
		_equipment_panel.set_equipment_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_automation_panel.toggle_automation()
	elif event.is_action_pressed("toggle_homestead"):
		_farming_panel.set_farming_open(false)
		_husbandry_panel.set_husbandry_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_processing_panel.set_processing_open(false)
		_equipment_panel.set_equipment_open(false)
		_automation_panel.set_automation_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_homestead_panel.toggle_homestead()
	elif event.is_action_pressed("toggle_map"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_exploration_panel.toggle_map()
	elif event.is_action_pressed("toggle_quests"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_quest_panel.toggle_quests()
	elif event.is_action_pressed("toggle_factions"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.set_progression_open(false)
		_faction_panel.toggle_factions()
	elif event.is_action_pressed("toggle_events"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_region_progression_panel.set_progression_open(false)
		_world_event_panel.toggle_events()
	elif event.is_action_pressed("toggle_progression"):
		_farming_panel.set_farming_open(false)
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.set_crafting_open(false)
		_exploration_panel.set_map_open(false)
		_npc_panel.set_npc_open(false)
		_quest_panel.set_quest_open(false)
		_faction_panel.set_faction_open(false)
		_world_event_panel.set_event_open(false)
		_region_progression_panel.toggle_progression()
	elif event.is_action_pressed("inventory_sort") and _inventory_panel.is_inventory_open():
		_stream_manager.sort_inventory()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		if key >= KEY_1 and key <= KEY_8:
			_stream_manager.select_hotbar_slot(int(key - KEY_1))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_save(true)
		SaveManager.flush_pending_save()
		get_tree().quit()


func _exit_tree() -> void:
	get_tree().auto_accept_quit = true
	if SaveManager.has_current_world() and not _exit_save_requested and _player != null and _stream_manager != null:
		_request_save(false)


func _build_world() -> void:
	_terrain_generator = TerrainGenerator.new(_world_seed)
	var player_snapshot := SaveManager.loaded_player_snapshot() if SaveManager.has_current_world() else {}
	var start_chunk := START_CHUNK
	if player_snapshot.has("position") and (player_snapshot["position"] as Array).size() == 2:
		var saved_position := Vector2(float(player_snapshot["position"][0]), float(player_snapshot["position"][1]))
		start_chunk = WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(saved_position))
	var initial_chunk := _terrain_generator.generate_chunk(start_chunk)
	var initial_layer: StringName = SaveManager.current_player_layer() if SaveManager.has_current_world() else &"surface"
	if initial_layer == &"underground":
		initial_chunk = CaveGenerator.new(_world_seed).generate_chunk(start_chunk)
	elif initial_layer == &"dungeon":
		var restored_dungeons := DungeonRunState.new()
		restored_dungeons.restore_snapshot(SaveManager.loaded_world_state_snapshot().get("dungeon_state", {}) as Dictionary)
		var run := restored_dungeons.current_run()
		var anchor := run.get("anchor_chunk", [start_chunk.x, start_chunk.y]) as Array
		initial_chunk = DungeonGenerator.new(
			_world_seed,
			restored_dungeons.current_dungeon_id(),
			Vector2i(int(anchor[0]), int(anchor[1]))
		).generate_chunk(start_chunk)
	_player = PLAYER_SCENE.instantiate() as PlayerCharacter
	_survival_state = SurvivalState.new(_survival_catalog)
	if SaveManager.has_current_world() and not _survival_state.restore_snapshot(
		SaveManager.loaded_world_state_snapshot().get("survival_state", {}) as Dictionary
	):
		push_error("Unable to restore survival state: %s" % _survival_state.last_error)
	if SaveManager.has_current_world():
		var season_snapshot := SaveManager.loaded_world_state_snapshot().get("season_state", {}) as Dictionary
		if not season_snapshot.is_empty():
			_season_state.restore_snapshot(season_snapshot)
	else:
		_season_state.advance_to_day(1)
	_previous_season_id = _season_state.season_id()
	if _terrain_generator != null:
		_terrain_generator.set_river_freezes(_season_state.river_freezes())
	ChunkRenderer.set_season_plant_tint(_season_state.plant_tint())
	if player_snapshot.is_empty():
		var spawn_tile := _terrain_generator.find_land_near(initial_chunk)
		_player.position = WorldCoordinates.tile_to_world_pixel(spawn_tile, true)
	else:
		_player.restore_snapshot(player_snapshot)
	if _player.combat_state().respawn_position.is_zero_approx():
		_player.combat_state().respawn_position = _player.position
	var camera := _player.get_node("Camera2D") as PixelCamera
	camera.configure_unbounded()
	add_child(_player)
	_player.died.connect(_on_player_died)
	_building_preview = BuildingPreview.new()
	_building_preview.z_index = 50
	_building_preview.hide_preview()
	add_child(_building_preview)
	_day_night_cycle = DayNightCycle.new(_game_time_seconds)
	var lighting_canvas := CanvasLayer.new()
	lighting_canvas.name = "DayNightCanvas"
	lighting_canvas.layer = 10
	add_child(lighting_canvas)
	_day_night_overlay = DayNightOverlay.new()
	lighting_canvas.add_child(_day_night_overlay)
	_day_night_overlay.configure_player(_player)
	_day_night_overlay.set_world_layer(initial_layer)
	_latest_time_state = _day_night_cycle.snapshot()
	_day_night_overlay.apply_time(_latest_time_state)
	_weather_overlay = WeatherOverlay.new()
	lighting_canvas.add_child(_weather_overlay)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	canvas.add_child(GameplayHud.new())
	_survival_hud = SurvivalHud.new()
	canvas.add_child(_survival_hud)
	canvas.add_child(CombatHud.new())
	canvas.add_child(EnemyHud.new())
	canvas.add_child(DungeonHud.new())
	canvas.add_child(MilestoneHud.new())
	canvas.add_child(ResourceHud.new())
	_generation_hud = GenerationHud.new()
	canvas.add_child(_generation_hud)
	_generation_hud.configure(_seed_text, _world_seed, start_chunk, initial_chunk.checksum)
	canvas.add_child(DebugPanel.new())
	_stream_manager = ChunkStreamManager.new()
	_stream_manager.configure(_world_seed, _player, initial_chunk, initial_layer)
	_weather_system = WeatherSystem.new(_world_seed, SaveManager.current_weather_state() if SaveManager.has_current_world() else {})
	if SaveManager.has_current_world():
		_stream_manager.restore_persistence(SaveManager.loaded_world_state_snapshot())
	_stream_manager.set_season_resource_multiplier(_season_state.resource_yield_multiplier())
	_stream_manager.set_season_population_multiplier(_season_state.enemy_population_multiplier())
	_stream_manager.set_season_crop_growth_multiplier(_season_state.crop_growth_multiplier())
	_stream_manager.metrics_changed.connect(_generation_hud.update_streaming)
	EventBus.world_layer_changed.connect(_on_world_layer_changed)
	add_child(_stream_manager)
	add_child(AudioCuePlayer.new())
	_combat_controller = PlayerCombatController.new()
	_combat_controller.configure(_player, _stream_manager)
	_player.add_child(_combat_controller)
	_inventory_panel = InventoryPanel.new()
	canvas.add_child(_inventory_panel)
	_inventory_panel.configure(_stream_manager)
	_crafting_panel = CraftingPanel.new()
	canvas.add_child(_crafting_panel)
	_crafting_panel.configure(_stream_manager)
	_processing_panel = ProcessingPanel.new()
	canvas.add_child(_processing_panel)
	_processing_panel.configure(_stream_manager)
	_equipment_panel = EquipmentPanel.new()
	canvas.add_child(_equipment_panel)
	_equipment_panel.configure(_stream_manager)
	_automation_panel = AutomationPanel.new()
	canvas.add_child(_automation_panel)
	_automation_panel.configure(_stream_manager)
	_homestead_panel = HomesteadPanel.new()
	canvas.add_child(_homestead_panel)
	_homestead_panel.configure(_stream_manager)
	_exploration_panel = ExplorationMapPanel.new()
	canvas.add_child(_exploration_panel)
	_exploration_panel.configure(_stream_manager)
	_npc_panel = NpcInteractionPanel.new()
	canvas.add_child(_npc_panel)
	_npc_panel.configure(_stream_manager)
	_quest_panel = QuestJournalPanel.new()
	canvas.add_child(_quest_panel)
	_quest_panel.configure(_stream_manager)
	_faction_panel = FactionPanel.new()
	canvas.add_child(_faction_panel)
	_faction_panel.configure(_stream_manager)
	_world_event_panel = WorldEventPanel.new()
	canvas.add_child(_world_event_panel)
	_world_event_panel.configure(_stream_manager)
	_region_progression_panel = RegionProgressionPanel.new()
	canvas.add_child(_region_progression_panel)
	_region_progression_panel.configure(_stream_manager)
	_building_panel = BuildingPanel.new()
	canvas.add_child(_building_panel)
	_building_panel.configure(_stream_manager)
	_farming_panel = FarmingPanel.new()
	canvas.add_child(_farming_panel)
	_farming_panel.configure(_stream_manager)
	_husbandry_panel = HusbandryPanel.new()
	canvas.add_child(_husbandry_panel)
	_husbandry_panel.configure(_stream_manager)
	if "--noise-view" in OS.get_cmdline_user_args():
		_stream_manager.toggle_noise_view()
	if _player.combat_state().status == &"dead" or _player.health <= 0.0:
		_survival_state.recover_after_death()
		var respawn_position := _player.combat_state().respawn_position
		if _stream_manager.world_layer() != &"surface":
			_stream_manager.respawn_to_surface(respawn_position)
		_player.respawn_at(respawn_position)
	_emit_survival_state()


func _request_save(create_backup: bool) -> void:
	if not SaveManager.has_current_world() or _player == null or _stream_manager == null:
		return
	var world_state := _stream_manager.persistence_snapshot()
	world_state["survival_state"] = _survival_state.persistence_snapshot() if _survival_state != null else SurvivalState.new().persistence_snapshot()
	world_state["season_state"] = _season_state.persistence_snapshot()
	SaveManager.request_save(
		_player.persistence_snapshot(),
		world_state,
		_game_time_seconds,
		create_backup,
		_weather_system.persistence_snapshot() if _weather_system != null else {}
	)


func _on_player_died(death_position: Vector2) -> void:
	_stream_manager.create_death_grave(death_position)
	if _survival_state != null:
		_survival_state.recover_after_death()
		_emit_survival_state()
	var respawn_position := _player.combat_state().respawn_position
	if _stream_manager.world_layer() != &"surface":
		_stream_manager.respawn_to_surface(respawn_position)
	_player.respawn_at(respawn_position)
	_request_save(false)


func _on_world_layer_changed(snapshot: Dictionary) -> void:
	var layer := StringName(snapshot.get("layer", &"surface"))
	if _day_night_overlay != null:
		_day_night_overlay.set_world_layer(layer)
	if _weather_overlay != null:
		_weather_overlay.visible = layer == &"surface"
	if _npc_panel != null and layer != &"surface":
		_npc_panel.set_npc_open(false)
	if _faction_panel != null and layer != &"surface":
		_faction_panel.set_faction_open(false)
	if _building_panel != null and layer != &"surface":
		_building_panel.set_building_open(false)
		_building_preview.hide_preview()
	if _farming_panel != null and layer != &"surface":
		_farming_panel.set_farming_open(false)
	if _husbandry_panel != null and layer != &"surface":
		_husbandry_panel.set_husbandry_open(false)
	if _processing_panel != null and layer != &"surface":
		_processing_panel.set_processing_open(false)
	if _automation_panel != null and layer != &"surface":
		_automation_panel.set_automation_open(false)


func _on_sleep_requested(_npc_id: String, display_name: String) -> void:
	if _day_night_cycle == null or _player == null:
		return
	if _npc_panel != null:
		_npc_panel.set_npc_open(false)
	var elapsed := _day_night_cycle.advance_to_next_phase(&"DAWN")
	if elapsed <= 0.0:
		return
	_game_time_seconds = _day_night_cycle.total_seconds
	_player.heal(35.0)
	_player.restore_stamina(_player.maximum_stamina)
	if _survival_state != null:
		_survival_state.rest_at_inn()
		_emit_survival_state()
	var state := _day_night_cycle.snapshot()
	_day_night_overlay.apply_time(state)
	EventBus.time_state_changed.emit(state)
	EventBus.interaction_feedback.emit("在%s的旅店休息了 %.1f 小时 · 已到第 %d 天清晨" % [
		display_name,
		elapsed / (_day_night_cycle.cycle_seconds() / 24.0),
		int(state.get("day", 1)),
	], true)
	_request_save(false)


func survival_state() -> SurvivalState:
	return _survival_state


func _building_target_tile() -> Vector2i:
	return WorldCoordinates.world_pixel_to_tile(get_global_mouse_position())


func _farming_target_tile() -> Vector2i:
	return WorldCoordinates.world_pixel_to_tile(get_global_mouse_position())


func _husbandry_target_tile() -> Vector2i:
	return WorldCoordinates.world_pixel_to_tile(get_global_mouse_position())


func _update_building_preview() -> void:
	if _building_panel == null or _building_preview == null or _stream_manager == null \
			or not _building_panel.is_building_open():
		if _building_preview != null:
			_building_preview.hide_preview()
		return
	var target_tile := _building_target_tile()
	var preview := _stream_manager.building_preview(_building_panel.selected_piece_id(), target_tile, _building_rotation)
	_building_preview.update_preview(
		target_tile,
		bool(preview.get("valid", false)),
		String(preview.get("color", "d65f5f")),
		_building_rotation
	)
	_building_panel.update_preview_status(preview, _building_rotation)


func _update_farming_target() -> void:
	if _farming_panel == null or _stream_manager == null or not _farming_panel.is_farming_open():
		return
	_farming_panel.update_target_status(
		_stream_manager.farming_target_status(_farming_panel.selected_crop_id(), _farming_target_tile())
	)


func _update_husbandry_target() -> void:
	if _husbandry_panel == null or _stream_manager == null or not _husbandry_panel.is_husbandry_open():
		return
	_husbandry_panel.update_target_status(
		_stream_manager.husbandry_target_status(_husbandry_panel.selected_animal_type(), _husbandry_target_tile())
	)


func _apply_ocean_state(player_tile: Vector2i) -> void:
	if _stream_manager.world_layer() != &"surface":
		_player_in_deep_water = false
		_player_in_terrain_water = false
		_player.set_ocean_state(1.0, false, 0.0)
		return
	var terrain := _terrain_generator.terrain_at(player_tile)
	var deep := terrain == ChunkData.Terrain.DEEP_WATER
	var shallow := terrain == ChunkData.Terrain.SHALLOW_WATER
	_player_in_terrain_water = deep or shallow
	if not _stream_manager.boarded_boat_id().is_empty():
		# 登船期间由船只承载：船速航行，且深水不消耗氧气。
		_player_in_deep_water = false
		_player.set_ocean_state(_stream_manager.boarded_boat_speed(), false, 0.0)
		return
	_player_in_deep_water = deep
	if deep:
		_player.set_ocean_state(_ocean_catalog.deep_water_multiplier(), true, _ocean_catalog.swim_stamina_drain())
	elif shallow:
		_player.set_ocean_state(_ocean_catalog.shallow_water_multiplier(), true, _ocean_catalog.swim_stamina_drain())
	else:
		_player.set_ocean_state(1.0, false, 0.0)


func _season_weather_weights() -> Dictionary:
	var weights := {}
	for wid in [&"CLEAR", &"RAIN", &"SNOW", &"SANDSTORM"]:
		weights[String(wid)] = _season_state.weather_weight(wid)
	return weights


func _update_survival(delta: float) -> void:
	if _survival_state == null or _player == null or _stream_manager == null:
		return
	var enabled := bool(SettingsManager.get_value("gameplay/survival_enabled", true))
	var environment := {
		"world_layer": String(_stream_manager.world_layer()),
		"biome_id": String(_stream_manager.current_biome_id()),
		"weather_id": String(_latest_weather_state.get("weather_id", "CLEAR")),
		"phase": String(_latest_time_state.get("phase", "DAY")),
		"in_water": HydrologyGenerator.is_water(_player.surface_feature) or _player_in_terrain_water,
		"in_deep_water": _player_in_deep_water,
		"near_heat": _stream_manager.selected_item_id() == &"torch" \
				or _stream_manager.is_near_cave_torch() \
				or _stream_manager.is_near_player_heat_source(),
		"activity": _player.state_name(),
		"season_temperature_offset": _season_state.temperature_offset(),
	}
	var result := _survival_state.update(delta, environment, enabled)
	_player.set_survival_speed_multiplier(_survival_state.movement_multiplier(enabled))
	var damage := float(result.get("damage", 0.0))
	if damage > 0.0 and _player.health > 0.0:
		_player.receive_hit(damage, Vector2.ZERO, 0.0)
	for effect_id_value in result.get("new_effects", []) as Array:
		var definition := _survival_catalog.effect(StringName(effect_id_value))
		EventBus.interaction_feedback.emit("生存状态：%s" % definition.get("display_name", effect_id_value), false)
	_survival_emit_elapsed += maxf(delta, 0.0)
	if _survival_emit_elapsed >= 0.2 or damage > 0.0 or not (result.get("new_effects", []) as Array).is_empty():
		_survival_emit_elapsed = 0.0
		EventBus.survival_state_changed.emit(result.get("state", _survival_state.status_snapshot(enabled)) as Dictionary)


func _try_consume_food() -> void:
	if _survival_state == null or _stream_manager == null or _player == null:
		return
	if not bool(SettingsManager.get_value("gameplay/survival_enabled", true)):
		EventBus.interaction_feedback.emit("生存规则已关闭，无需使用恢复物品", false)
		return
	var item_id := _stream_manager.selected_item_id()
	var missing_health := _player.maximum_health - _player.health
	if not _survival_state.can_consume_food(item_id, missing_health):
		EventBus.interaction_feedback.emit(_survival_state.last_error, false)
		return
	if not _stream_manager.consume_selected_item(item_id, 1):
		EventBus.interaction_feedback.emit("快捷栏恢复物品消耗失败", false)
		return
	var result := _survival_state.consume_food(item_id, missing_health)
	_player.heal(float(result.get("health_restored", 0.0)))
	var details: Array[String] = []
	if float(result.get("hunger_restored", 0.0)) > 0.0:
		details.append("饥饿 +%d" % roundi(float(result["hunger_restored"])))
	if float(result.get("health_restored", 0.0)) > 0.0:
		details.append("生命 +%d" % roundi(float(result["health_restored"])))
	if not (result.get("cleared_effects", []) as Array).is_empty():
		details.append("清除状态")
	if not is_zero_approx(float(result.get("temperature_changed", 0.0))):
		details.append("体温 %+0.1f" % float(result["temperature_changed"]))
	EventBus.interaction_feedback.emit("使用%s · %s" % [
		ItemCatalog.new().display_name(item_id),
		" · ".join(details),
	], true)
	_emit_survival_state()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key != &"gameplay/survival_enabled" or _survival_state == null:
		return
	var enabled := bool(SettingsManager.get_value("gameplay/survival_enabled", true))
	if _player != null:
		_player.set_survival_speed_multiplier(_survival_state.movement_multiplier(enabled))
	_emit_survival_state()


func _emit_survival_state() -> void:
	if _survival_state != null:
		EventBus.survival_state_changed.emit(_survival_state.status_snapshot(
			bool(SettingsManager.get_value("gameplay/survival_enabled", true))
		))
