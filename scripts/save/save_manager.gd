extends Node

const SAVE_ROOT := "user://saves"
const DEFAULT_START_CHUNK := Vector2i(-1, -4)
const SUPPORTED_SAVE_VERSIONS := [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
const SUPPORTED_GENERATION_VERSIONS := [4, 5]

var last_error := ""
var last_save_duration_ms := 0.0

var _current_world_id := ""
var _metadata: Dictionary = {}
var _player_snapshot: Dictionary = {}
var _world_state_snapshot: Dictionary = {}
var _save_job: SaveWriteJob
var _save_task_id := -1
var _queued_request: Dictionary = {}
# 派发存档时用于校验探测的只读目录，按默认路径懒加载并复用，避免每次自动保存重复解析 JSON。
var _shared_item_catalog: ItemCatalog
var _shared_quest_catalog: QuestCatalog
var _shared_faction_catalog: FactionCatalog
var _shared_world_event_catalog: WorldEventCatalog
var _shared_progression_catalog: RegionProgressionCatalog
var _shared_survival_catalog: SurvivalCatalog
var _shared_equipment_catalog: EquipmentCatalog
var _shared_building_catalog: BuildingCatalog
var _shared_automation_catalog: AutomationCatalog
var _shared_homestead_catalog: HomesteadCatalog
var _shared_farming_catalog: FarmingCatalog
var _shared_husbandry_catalog: HusbandryCatalog


func _ready() -> void:
	var root_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	if root_error != OK:
		last_error = "无法创建存档目录：%s" % error_string(root_error)
		LogManager.error("SaveManager", last_error)


func _process(_delta: float) -> void:
	if _save_task_id >= 0 and WorkerThreadPool.is_task_completed(_save_task_id):
		_collect_completed_save()


func _exit_tree() -> void:
	flush_pending_save()


func create_world(world_name: String, seed_text: String) -> bool:
	flush_pending_save()
	last_error = ""
	var clean_name := world_name.strip_edges()
	var clean_seed := seed_text.strip_edges()
	if clean_name.is_empty() or clean_name.length() > 32:
		return _fail("世界名称必须为 1–32 个字符")
	if clean_seed.is_empty():
		clean_seed = clean_name
	var seed := WorldSeed.from_text(clean_seed)
	var unique_source := "%s|%s|%d|%d" % [clean_name, clean_seed, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var world_id := "world_%d" % WorldSeed.from_text(unique_source)
	var root_path := _world_root_absolute(world_id)
	var error := DirAccess.make_dir_recursive_absolute(root_path.path_join("chunks/surface"))
	if error != OK:
		return _fail("无法创建世界目录：%s" % error_string(error))
	error = DirAccess.make_dir_recursive_absolute(root_path.path_join("chunks/underground"))
	if error != OK:
		return _fail("无法创建地下区块目录：%s" % error_string(error))
	error = DirAccess.make_dir_recursive_absolute(root_path.path_join("backups"))
	if error != OK:
		return _fail("无法创建备份目录：%s" % error_string(error))
	var generator := TerrainGenerator.new(seed)
	var initial_chunk := generator.generate_chunk(DEFAULT_START_CHUNK)
	var spawn_tile := generator.find_land_near(initial_chunk)
	var spawn_position := WorldCoordinates.tile_to_world_pixel(spawn_tile, true)
	var initial_combat := PlayerCombatState.new()
	initial_combat.respawn_position = spawn_position
	var timestamp := Time.get_datetime_string_from_system(false, true)
	_metadata = {
		"save_version": GameVersion.SAVE_VERSION,
		"generation_version": GameVersion.GENERATION_VERSION,
		"game_version": GameVersion.VERSION,
		"world_id": world_id,
		"world_name": clean_name,
		"seed_text": clean_seed,
		"seed": seed,
		"created_at": timestamp,
		"last_played_at": timestamp,
		"game_time_seconds": 0.0,
		"weather_state": WeatherSystem.new(seed).persistence_snapshot(),
		"player_layer": "surface",
	}
	_player_snapshot = {
		"save_version": GameVersion.SAVE_VERSION,
		"position": [spawn_position.x, spawn_position.y],
		"health": 100.0,
		"maximum_health": 100.0,
		"stamina": 100.0,
		"maximum_stamina": 100.0,
		"active_tool": "hands",
		"inventory": InventoryModel.new().snapshot(),
		"crafting_state": CraftingSystem.new(InventoryModel.new()).persistence_snapshot(),
		"combat_state": initial_combat.persistence_snapshot(),
		"grave_state": GraveModel.new().persistence_snapshot(),
		"milestone_state": MilestoneState.new().persistence_snapshot(),
		"dungeon_state": DungeonRunState.new().persistence_snapshot(),
		"exploration_state": ExplorationMapState.new().persistence_snapshot(),
		"regional_boss_state": RegionalBossState.new().persistence_snapshot(),
		"npc_state": NpcWorldState.new().persistence_snapshot(),
		"relationship_state": RelationshipState.new().persistence_snapshot(),
		"quest_state": QuestState.new().persistence_snapshot(),
		"world_choice_state": WorldChoiceState.new().persistence_snapshot(),
		"faction_state": FactionState.new().persistence_snapshot(),
		"world_event_state": WorldEventState.new().persistence_snapshot(),
		"region_progression_state": RegionProgressionState.new().persistence_snapshot(),
		"survival_state": SurvivalState.new().persistence_snapshot(),
		"equipment_state": EquipmentState.new().persistence_snapshot(),
		"homestead_state": HomesteadState.new().persistence_snapshot(),
		"world_layer": "surface",
	}
	_world_state_snapshot = {
		"collected_resources": [],
		"inventory": _player_snapshot["inventory"],
		"crafting_state": _player_snapshot["crafting_state"],
		"grave_state": _player_snapshot["grave_state"],
		"milestone_state": _player_snapshot["milestone_state"],
		"dungeon_state": _player_snapshot["dungeon_state"],
		"exploration_state": _player_snapshot["exploration_state"],
		"regional_boss_state": _player_snapshot["regional_boss_state"],
		"npc_state": _player_snapshot["npc_state"],
		"relationship_state": _player_snapshot["relationship_state"],
		"quest_state": _player_snapshot["quest_state"],
		"world_choice_state": _player_snapshot["world_choice_state"],
		"faction_state": _player_snapshot["faction_state"],
		"world_event_state": _player_snapshot["world_event_state"],
		"region_progression_state": _player_snapshot["region_progression_state"],
		"survival_state": _player_snapshot["survival_state"],
		"equipment_state": _player_snapshot["equipment_state"],
		"homestead_state": _player_snapshot["homestead_state"],
		"building_state": BuildingState.new().persistence_snapshot(),
		"farming_state": FarmingState.new(seed).persistence_snapshot(),
		"husbandry_state": HusbandryState.new(seed).persistence_snapshot(),
		"opened_cave_chests": [],
		"world_layer": "surface",
		"active_tool": "hands",
	}
	var world_result := _write_initial_json(root_path.path_join("world.json"), _metadata)
	if not world_result:
		return false
	if not _write_initial_json(root_path.path_join("player.json"), _player_snapshot):
		return false
	_current_world_id = world_id
	LogManager.info("SaveManager", "Created world %s (%s)" % [clean_name, world_id])
	return true


func has_any_world() -> bool:
	var directory := DirAccess.open(ProjectSettings.globalize_path(SAVE_ROOT))
	if directory == null:
		return false
	for dirname in directory.get_directories():
		if FileAccess.file_exists(ProjectSettings.globalize_path(SAVE_ROOT.path_join(dirname).path_join("world.json"))):
			return true
	return false


func load_most_recent_world() -> bool:
	last_error = ""
	var directory := DirAccess.open(ProjectSettings.globalize_path(SAVE_ROOT))
	if directory == null:
		return _fail("存档目录不可读")
	var candidates: Array[Dictionary] = []
	var corrupt_errors: Array[String] = []
	for dirname in directory.get_directories():
		var read_result := _read_json(_world_root_absolute(dirname).path_join("world.json"))
		if not bool(read_result["ok"]):
			corrupt_errors.append("%s：%s" % [dirname, read_result["error"]])
			continue
		var metadata := read_result["data"] as Dictionary
		var validation_error := _validate_metadata(metadata)
		if not validation_error.is_empty():
			corrupt_errors.append("%s：%s" % [dirname, validation_error])
			continue
		candidates.append({"id": dirname, "last_played_at": String(metadata.get("last_played_at", ""))})
	if candidates.is_empty():
		if not corrupt_errors.is_empty():
			return _fail("存档损坏或不兼容：" + "；".join(corrupt_errors))
		return _fail("没有可以继续的世界")
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["last_played_at"]) > String(b["last_played_at"])
	)
	return load_world(String(candidates[0]["id"]))


func load_world(world_id: String) -> bool:
	flush_pending_save()
	last_error = ""
	var root_path := _world_root_absolute(world_id)
	var world_result := _read_json(root_path.path_join("world.json"))
	if not bool(world_result["ok"]):
		return _fail("存档损坏：%s" % world_result["error"])
	var metadata := world_result["data"] as Dictionary
	var metadata_error := _validate_metadata(metadata)
	if not metadata_error.is_empty():
		return _fail("存档损坏或不兼容：%s" % metadata_error)
	var player_result := _read_json(root_path.path_join("player.json"))
	if not bool(player_result["ok"]):
		return _fail("玩家存档损坏：%s" % player_result["error"])
	var player := player_result["data"] as Dictionary
	var player_error := _validate_player(player)
	if not player_error.is_empty():
		return _fail("玩家存档损坏：%s" % player_error)
	var loaded_save_version := int(metadata.get("save_version", 0))
	if loaded_save_version >= 8 and String(player.get("world_layer", "")) != String(metadata.get("player_layer", "")):
		return _fail("玩家存档损坏：玩家世界层与世界元数据不一致")
	if loaded_save_version == 2:
		var migrated_inventory := InventoryModel.new()
		if not migrated_inventory.restore_legacy_counts(player.get("inventory", {}) as Dictionary):
			return _fail("玩家存档迁移失败：%s" % migrated_inventory.last_error)
		player["inventory"] = migrated_inventory.snapshot()
	else:
		var normalized_inventory := InventoryModel.new()
		normalized_inventory.restore_snapshot(player["inventory"] as Dictionary)
		player["inventory"] = normalized_inventory.snapshot()
	if loaded_save_version < 4:
		player["crafting_state"] = CraftingSystem.new(InventoryModel.new()).persistence_snapshot()
	if loaded_save_version < 5:
		var fallback_position := player.get("position", [0.0, 0.0]) as Array
		var migrated_combat := PlayerCombatState.new()
		migrated_combat.respawn_position = Vector2(float(fallback_position[0]), float(fallback_position[1]))
		player["combat_state"] = migrated_combat.persistence_snapshot()
		player["grave_state"] = GraveModel.new().persistence_snapshot()
	if loaded_save_version < 6:
		player["milestone_state"] = MilestoneState.new().persistence_snapshot()
	if loaded_save_version < 7:
		metadata["weather_state"] = WeatherSystem.new(int(metadata.get("seed", 0))).persistence_snapshot()
	if loaded_save_version < 8:
		metadata["player_layer"] = "surface"
		player["world_layer"] = "surface"
	if loaded_save_version < 9:
		player["dungeon_state"] = DungeonRunState.new().persistence_snapshot()
	if loaded_save_version < 10:
		player["exploration_state"] = ExplorationMapState.new().persistence_snapshot()
		player["regional_boss_state"] = RegionalBossState.new().persistence_snapshot()
	if loaded_save_version < 11:
		player["npc_state"] = NpcWorldState.new().persistence_snapshot()
	if loaded_save_version < 12:
		player["relationship_state"] = RelationshipState.new().persistence_snapshot()
	if loaded_save_version < 13:
		player["quest_state"] = QuestState.new().persistence_snapshot()
	if loaded_save_version < 14:
		player["faction_state"] = FactionState.new().persistence_snapshot()
	if loaded_save_version < 15:
		player["world_event_state"] = WorldEventState.new().persistence_snapshot()
	if loaded_save_version < 16:
		player["region_progression_state"] = RegionProgressionState.new().persistence_snapshot()
	if loaded_save_version < 17:
		player["quest_state"] = QuestState.migrate_legacy_snapshot(player.get("quest_state", {}) as Dictionary)
		player["world_choice_state"] = WorldChoiceState.new().persistence_snapshot()
	if loaded_save_version < 18:
		player["survival_state"] = SurvivalState.new().persistence_snapshot()
	if loaded_save_version < 23:
		player["equipment_state"] = EquipmentState.new().persistence_snapshot()
	if loaded_save_version < 25:
		player["homestead_state"] = HomesteadState.new().persistence_snapshot()
	var normalized_weather := WeatherSystem.new(int(metadata.get("seed", 0)))
	if not normalized_weather.restore_snapshot(metadata.get("weather_state", {}) as Dictionary):
		return _fail("天气存档状态无效")
	metadata["weather_state"] = normalized_weather.persistence_snapshot()
	if loaded_save_version < GameVersion.SAVE_VERSION:
		player["save_version"] = GameVersion.SAVE_VERSION
		metadata["save_version"] = GameVersion.SAVE_VERSION
		metadata["generation_version"] = GameVersion.GENERATION_VERSION
		metadata["game_version"] = GameVersion.VERSION
		LogManager.info("SaveManager", "Migrated world %s from save format %d to %d" % [world_id, loaded_save_version, GameVersion.SAVE_VERSION])
	player["world_layer"] = String(metadata.get("player_layer", "surface"))
	var normalized_player_inventory := InventoryModel.new()
	normalized_player_inventory.restore_snapshot(player["inventory"] as Dictionary)
	var normalized_crafting := CraftingSystem.new(normalized_player_inventory)
	normalized_crafting.restore_snapshot(player.get("crafting_state", {}) as Dictionary)
	player["crafting_state"] = normalized_crafting.persistence_snapshot()
	var normalized_combat := PlayerCombatState.new()
	var player_position := player.get("position", [0.0, 0.0]) as Array
	normalized_combat.restore_snapshot(player.get("combat_state", {}) as Dictionary, Vector2(float(player_position[0]), float(player_position[1])))
	player["combat_state"] = normalized_combat.persistence_snapshot()
	var normalized_graves := GraveModel.new()
	normalized_graves.restore_snapshot(player.get("grave_state", {}) as Dictionary)
	player["grave_state"] = normalized_graves.persistence_snapshot()
	var normalized_milestones := MilestoneState.new()
	normalized_milestones.restore_snapshot(player.get("milestone_state", {}) as Dictionary)
	player["milestone_state"] = normalized_milestones.persistence_snapshot()
	var normalized_dungeons := DungeonRunState.new()
	if not normalized_dungeons.restore_snapshot(player.get("dungeon_state", {}) as Dictionary):
		return _fail("地牢进度损坏：%s" % normalized_dungeons.last_error)
	var loaded_layer := String(metadata.get("player_layer", "surface"))
	if (loaded_layer == "dungeon") != (not normalized_dungeons.current_dungeon_id().is_empty()):
		return _fail("地牢进度损坏：当前地牢与玩家世界层不一致")
	player["dungeon_state"] = normalized_dungeons.persistence_snapshot()
	var normalized_exploration := ExplorationMapState.new()
	if not normalized_exploration.restore_snapshot(player.get("exploration_state", {}) as Dictionary):
		return _fail("探索地图进度损坏：%s" % normalized_exploration.last_error)
	player["exploration_state"] = normalized_exploration.persistence_snapshot()
	var normalized_regional_bosses := RegionalBossState.new()
	if not normalized_regional_bosses.restore_snapshot(player.get("regional_boss_state", {}) as Dictionary):
		return _fail("区域首领进度损坏：%s" % normalized_regional_bosses.last_error)
	player["regional_boss_state"] = normalized_regional_bosses.persistence_snapshot()
	var normalized_npcs := NpcWorldState.new()
	if not normalized_npcs.restore_snapshot(player.get("npc_state", {}) as Dictionary):
		return _fail("NPC 状态损坏：%s" % normalized_npcs.last_error)
	player["npc_state"] = normalized_npcs.persistence_snapshot()
	var normalized_relationships := RelationshipState.new()
	if not normalized_relationships.restore_snapshot(player.get("relationship_state", {}) as Dictionary):
		return _fail("关系状态损坏：%s" % normalized_relationships.last_error)
	player["relationship_state"] = normalized_relationships.persistence_snapshot()
	var normalized_quests := QuestState.new()
	if not normalized_quests.restore_snapshot(player.get("quest_state", {}) as Dictionary, QuestCatalog.new()):
		return _fail("任务状态损坏：%s" % normalized_quests.last_error)
	player["quest_state"] = normalized_quests.persistence_snapshot()
	var normalized_world_choices := WorldChoiceState.new()
	if not normalized_world_choices.restore_snapshot(player.get("world_choice_state", {}) as Dictionary, QuestCatalog.new()):
		return _fail("世界选择状态损坏：%s" % normalized_world_choices.last_error)
	player["world_choice_state"] = normalized_world_choices.persistence_snapshot()
	var normalized_factions := FactionState.new()
	if not normalized_factions.restore_snapshot(player.get("faction_state", {}) as Dictionary, FactionCatalog.new()):
		return _fail("阵营状态损坏：%s" % normalized_factions.last_error)
	player["faction_state"] = normalized_factions.persistence_snapshot()
	var normalized_world_events := WorldEventState.new()
	if not normalized_world_events.restore_snapshot(player.get("world_event_state", {}) as Dictionary, WorldEventCatalog.new()):
		return _fail("世界事件状态损坏：%s" % normalized_world_events.last_error)
	player["world_event_state"] = normalized_world_events.persistence_snapshot()
	var normalized_region_progression := RegionProgressionState.new()
	if not normalized_region_progression.restore_snapshot(player.get("region_progression_state", {}) as Dictionary, RegionProgressionCatalog.new()):
		return _fail("区域进度状态损坏：%s" % normalized_region_progression.last_error)
	player["region_progression_state"] = normalized_region_progression.persistence_snapshot()
	var normalized_survival := SurvivalState.new()
	if not normalized_survival.restore_snapshot(player.get("survival_state", {}) as Dictionary):
		return _fail("生存状态损坏：%s" % normalized_survival.last_error)
	player["survival_state"] = normalized_survival.persistence_snapshot()
	var normalized_equipment := EquipmentState.new()
	if not normalized_equipment.restore_snapshot(player.get("equipment_state", {}) as Dictionary):
		return _fail("装备状态损坏：%s" % normalized_equipment.last_error)
	player["equipment_state"] = normalized_equipment.persistence_snapshot()
	var surface_result := _load_chunk_differences(root_path.path_join("chunks/surface"), &"surface")
	if not bool(surface_result["ok"]):
		return _fail("地表区块差异损坏：%s" % surface_result["error"])
	var underground_result := _load_chunk_differences(root_path.path_join("chunks/underground"), &"underground")
	if not bool(underground_result["ok"]):
		return _fail("地下区块差异损坏：%s" % underground_result["error"])
	var collected_resources := surface_result["collected_resources"] as Array
	collected_resources.append_array(underground_result["collected_resources"] as Array)
	collected_resources.sort()
	var opened_cave_chests := underground_result["opened_cave_chests"] as Array
	var placed_buildings := surface_result["placed_buildings"] as Array
	if not (underground_result["placed_buildings"] as Array).is_empty():
		return _fail("地下区块差异损坏：当前版本不允许地下玩家建筑")
	var normalized_buildings := BuildingState.new()
	if not normalized_buildings.restore_snapshot({"schema_version": BuildingState.SCHEMA_VERSION, "placements": placed_buildings}):
		return _fail("玩家建造差异损坏：%s" % normalized_buildings.last_error)
	var normalized_homestead := HomesteadState.new()
	if loaded_save_version < 25:
		if not normalized_homestead.restore_snapshot(player.get("homestead_state", {}) as Dictionary) \
				or not bool(normalized_homestead.synchronize_markers(normalized_buildings, float(metadata.get("game_time_seconds", 0.0))).get("ok", false)):
			return _fail("家园状态迁移失败：%s" % normalized_homestead.last_error)
	elif not normalized_homestead.restore_snapshot(player.get("homestead_state", {}) as Dictionary, normalized_buildings):
		return _fail("家园状态损坏：%s" % normalized_homestead.last_error)
	player["homestead_state"] = normalized_homestead.persistence_snapshot()
	var farming_plots := surface_result["farming_plots"] as Array
	if not (underground_result["farming_plots"] as Array).is_empty():
		return _fail("地下区块差异损坏：当前版本不允许地下耕地")
	var normalized_farming := FarmingState.new(int(metadata["seed"]))
	if not normalized_farming.restore_snapshot({"schema_version": FarmingState.SCHEMA_VERSION, "plots": farming_plots}):
		return _fail("农业差异损坏：%s" % normalized_farming.last_error)
	var husbandry_animals := surface_result["husbandry_animals"] as Array
	if not (underground_result["husbandry_animals"] as Array).is_empty():
		return _fail("地下区块差异损坏：当前版本不允许地下动物")
	var normalized_husbandry := HusbandryState.new(int(metadata["seed"]))
	if not normalized_husbandry.restore_snapshot({"schema_version": HusbandryState.SCHEMA_VERSION, "next_birth_id": 1, "animals": husbandry_animals}):
		return _fail("养殖差异损坏：%s" % normalized_husbandry.last_error)
	for animal_value in normalized_husbandry.persistence_snapshot().get("animals", []) as Array:
		var animal_record := animal_value as Dictionary
		var animal_tile_value := animal_record["world_tile"] as Array
		var animal_tile := Vector2i(int(animal_tile_value[0]), int(animal_tile_value[1]))
		if not normalized_farming.plot_at(animal_tile).is_empty() \
				or not normalized_buildings.placement_at(animal_tile, &"ground").is_empty() \
				or not normalized_buildings.placement_at(animal_tile, &"structure").is_empty() \
				or not normalized_buildings.placement_at(animal_tile, &"roof").is_empty():
			return _fail("养殖差异损坏：动物与建筑或耕地重叠")
	_current_world_id = world_id
	_metadata = metadata
	_player_snapshot = player
	_world_state_snapshot = {
		"collected_resources": collected_resources,
		"inventory": player.get("inventory", {}),
		"crafting_state": player.get("crafting_state", {}),
		"grave_state": player.get("grave_state", {}),
		"milestone_state": player.get("milestone_state", {}),
		"dungeon_state": player.get("dungeon_state", {}),
		"exploration_state": player.get("exploration_state", {}),
		"regional_boss_state": player.get("regional_boss_state", {}),
		"npc_state": player.get("npc_state", {}),
		"relationship_state": player.get("relationship_state", {}),
		"quest_state": player.get("quest_state", {}),
		"world_choice_state": player.get("world_choice_state", {}),
		"faction_state": player.get("faction_state", {}),
		"world_event_state": player.get("world_event_state", {}),
		"region_progression_state": player.get("region_progression_state", {}),
		"survival_state": player.get("survival_state", {}),
		"equipment_state": player.get("equipment_state", {}),
		"homestead_state": player.get("homestead_state", {}),
		"building_state": normalized_buildings.persistence_snapshot(),
		"farming_state": normalized_farming.persistence_snapshot(),
		"husbandry_state": normalized_husbandry.persistence_snapshot(),
		"opened_cave_chests": opened_cave_chests,
		"world_layer": String(metadata.get("player_layer", "surface")),
		"active_tool": String(player.get("active_tool", "hands")),
	}
	LogManager.info("SaveManager", "Loaded world %s (%s)" % [_metadata["world_name"], world_id])
	return true


func request_save(player: Dictionary, world_state: Dictionary, game_time_seconds: float, create_backup := false, weather_state := {}) -> bool:
	if _current_world_id.is_empty():
		return false
	var requested_layer := String(world_state.get("world_layer", "surface"))
	if requested_layer not in ["surface", "underground", "dungeon"]:
		return _fail("无法保存未知世界层")
	var dungeon_value: Variant = world_state.get("dungeon_state", {})
	if not dungeon_value is Dictionary:
		return _fail("无法保存无效地牢进度")
	var dungeon_probe := DungeonRunState.new()
	if not dungeon_probe.restore_snapshot(dungeon_value as Dictionary):
		return _fail("无法保存地牢进度：%s" % dungeon_probe.last_error)
	if (requested_layer == "dungeon") != (not dungeon_probe.current_dungeon_id().is_empty()):
		return _fail("无法保存世界层与当前地牢不一致的状态")
	var exploration_value: Variant = world_state.get("exploration_state", {})
	if not exploration_value is Dictionary:
		return _fail("无法保存无效探索地图进度")
	var exploration_probe := ExplorationMapState.new()
	if not exploration_probe.restore_snapshot(exploration_value as Dictionary):
		return _fail("无法保存探索地图进度：%s" % exploration_probe.last_error)
	var regional_value: Variant = world_state.get("regional_boss_state", {})
	if not regional_value is Dictionary:
		return _fail("无法保存无效区域首领进度")
	var regional_probe := RegionalBossState.new()
	if not regional_probe.restore_snapshot(regional_value as Dictionary):
		return _fail("无法保存区域首领进度：%s" % regional_probe.last_error)
	var npc_value: Variant = world_state.get("npc_state", {})
	if not npc_value is Dictionary:
		return _fail("无法保存无效 NPC 状态")
	var npc_probe := NpcWorldState.new()
	if not npc_probe.restore_snapshot(npc_value as Dictionary):
		return _fail("无法保存 NPC 状态：%s" % npc_probe.last_error)
	var relationship_value: Variant = world_state.get("relationship_state", {})
	if not relationship_value is Dictionary:
		return _fail("无法保存无效关系状态")
	var relationship_probe := RelationshipState.new()
	if not relationship_probe.restore_snapshot(relationship_value as Dictionary):
		return _fail("无法保存关系状态：%s" % relationship_probe.last_error)
	var quest_value: Variant = world_state.get("quest_state", {})
	if not quest_value is Dictionary:
		return _fail("无法保存无效任务状态")
	var quest_probe := QuestState.new()
	if not quest_probe.restore_snapshot(quest_value as Dictionary, _shared_quest_catalog_or_new()):
		return _fail("无法保存任务状态：%s" % quest_probe.last_error)
	var choice_value: Variant = world_state.get("world_choice_state", {})
	if not choice_value is Dictionary:
		return _fail("无法保存无效世界选择状态")
	var choice_probe := WorldChoiceState.new()
	if not choice_probe.restore_snapshot(choice_value as Dictionary, _shared_quest_catalog_or_new()):
		return _fail("无法保存世界选择状态：%s" % choice_probe.last_error)
	var faction_value: Variant = world_state.get("faction_state", {})
	if not faction_value is Dictionary:
		return _fail("无法保存无效阵营状态")
	var faction_probe := FactionState.new(_shared_faction_catalog_or_new())
	if not faction_probe.restore_snapshot(faction_value as Dictionary, FactionCatalog.new()):
		return _fail("无法保存阵营状态：%s" % faction_probe.last_error)
	var event_value: Variant = world_state.get("world_event_state", {})
	if not event_value is Dictionary:
		return _fail("无法保存无效世界事件状态")
	var event_probe := WorldEventState.new()
	if not event_probe.restore_snapshot(event_value as Dictionary, _shared_world_event_catalog_or_new()):
		return _fail("无法保存世界事件状态：%s" % event_probe.last_error)
	var progression_value: Variant = world_state.get("region_progression_state", {})
	if not progression_value is Dictionary:
		return _fail("无法保存无效区域进度状态")
	var progression_probe := RegionProgressionState.new()
	if not progression_probe.restore_snapshot(progression_value as Dictionary, _shared_progression_catalog_or_new()):
		return _fail("无法保存区域进度状态：%s" % progression_probe.last_error)
	var survival_value: Variant = world_state.get("survival_state", {})
	if not survival_value is Dictionary:
		return _fail("无法保存无效生存状态")
	var survival_probe := SurvivalState.new(_shared_survival_catalog_or_new())
	if not survival_probe.restore_snapshot(survival_value as Dictionary):
		return _fail("无法保存生存状态：%s" % survival_probe.last_error)
	var equipment_value: Variant = world_state.get("equipment_state", {})
	if not equipment_value is Dictionary:
		return _fail("无法保存无效装备状态")
	var equipment_probe := EquipmentState.new(_shared_equipment_catalog_or_new(), _shared_item_catalog_or_new())
	if not equipment_probe.restore_snapshot(equipment_value as Dictionary):
		return _fail("无法保存装备状态：%s" % equipment_probe.last_error)
	var building_value: Variant = world_state.get("building_state", {})
	if not building_value is Dictionary:
		return _fail("无法保存无效玩家建造状态")
	var building_probe := BuildingState.new(
		_shared_building_catalog_or_new(),
		_shared_item_catalog_or_new(),
		_shared_automation_catalog_or_new(),
		_shared_homestead_catalog_or_new()
	)
	if not building_probe.restore_snapshot(building_value as Dictionary):
		return _fail("无法保存玩家建造状态：%s" % building_probe.last_error)
	var homestead_value: Variant = world_state.get("homestead_state", {})
	if not homestead_value is Dictionary:
		return _fail("无法保存无效家园状态")
	var homestead_probe := HomesteadState.new(_shared_homestead_catalog_or_new())
	if not homestead_probe.restore_snapshot(homestead_value as Dictionary, building_probe):
		return _fail("无法保存家园状态：%s" % homestead_probe.last_error)
	var farming_value: Variant = world_state.get("farming_state", {})
	if not farming_value is Dictionary:
		return _fail("无法保存无效农业状态")
	var farming_probe := FarmingState.new(current_seed(), _shared_farming_catalog_or_new(), _shared_item_catalog_or_new())
	if not farming_probe.restore_snapshot(farming_value as Dictionary):
		return _fail("无法保存农业状态：%s" % farming_probe.last_error)
	var husbandry_value: Variant = world_state.get("husbandry_state", {})
	if not husbandry_value is Dictionary:
		return _fail("无法保存无效养殖状态")
	var husbandry_probe := HusbandryState.new(current_seed(), _shared_husbandry_catalog_or_new(), _shared_item_catalog_or_new())
	if not husbandry_probe.restore_snapshot(husbandry_value as Dictionary):
		return _fail("无法保存养殖状态：%s" % husbandry_probe.last_error)
	for animal_value in husbandry_probe.persistence_snapshot().get("animals", []) as Array:
		var animal_record := animal_value as Dictionary
		var animal_tile_value := animal_record["world_tile"] as Array
		var animal_tile := Vector2i(int(animal_tile_value[0]), int(animal_tile_value[1]))
		if not farming_probe.plot_at(animal_tile).is_empty() \
				or not building_probe.placement_at(animal_tile, &"ground").is_empty() \
				or not building_probe.placement_at(animal_tile, &"structure").is_empty() \
				or not building_probe.placement_at(animal_tile, &"roof").is_empty():
			return _fail("无法保存重叠的动物、建筑或耕地")
	# 探测校验过的文档会被下方的规范化快照整体替换，无需对它们做昂贵的深拷贝。
	var probe_normalized_keys := [
		"dungeon_state", "exploration_state", "regional_boss_state", "npc_state",
		"relationship_state", "quest_state", "world_choice_state", "faction_state",
		"world_event_state", "region_progression_state", "survival_state",
		"equipment_state", "homestead_state", "building_state", "farming_state",
		"husbandry_state",
	]
	var normalized_world_state := {}
	for state_key in world_state.keys():
		if probe_normalized_keys.has(String(state_key)):
			continue
		var state_value: Variant = world_state[state_key]
		if state_value is Dictionary or state_value is Array:
			normalized_world_state[state_key] = state_value.duplicate(true)
		else:
			normalized_world_state[state_key] = state_value
	normalized_world_state["dungeon_state"] = dungeon_probe.persistence_snapshot()
	normalized_world_state["exploration_state"] = exploration_probe.persistence_snapshot()
	normalized_world_state["regional_boss_state"] = regional_probe.persistence_snapshot()
	normalized_world_state["npc_state"] = npc_probe.persistence_snapshot()
	normalized_world_state["relationship_state"] = relationship_probe.persistence_snapshot()
	normalized_world_state["quest_state"] = quest_probe.persistence_snapshot()
	normalized_world_state["world_choice_state"] = choice_probe.persistence_snapshot()
	normalized_world_state["faction_state"] = faction_probe.persistence_snapshot()
	normalized_world_state["world_event_state"] = event_probe.persistence_snapshot()
	normalized_world_state["region_progression_state"] = progression_probe.persistence_snapshot()
	normalized_world_state["survival_state"] = survival_probe.persistence_snapshot()
	normalized_world_state["equipment_state"] = equipment_probe.persistence_snapshot()
	normalized_world_state["homestead_state"] = homestead_probe.persistence_snapshot()
	normalized_world_state["building_state"] = building_probe.persistence_snapshot()
	normalized_world_state["farming_state"] = farming_probe.persistence_snapshot()
	normalized_world_state["husbandry_state"] = husbandry_probe.persistence_snapshot()
	var request := {
		"player": player.duplicate(true),
		"world_state": normalized_world_state,
		"game_time_seconds": game_time_seconds,
		"create_backup": create_backup,
		"weather_state": (weather_state as Dictionary).duplicate(true),
	}
	if _save_task_id >= 0:
		_queued_request = request
		return true
	_start_save(request)
	return true


func _shared_item_catalog_or_new() -> ItemCatalog:
	if _shared_item_catalog == null:
		_shared_item_catalog = ItemCatalog.new()
	return _shared_item_catalog


func _shared_quest_catalog_or_new() -> QuestCatalog:
	if _shared_quest_catalog == null:
		_shared_quest_catalog = QuestCatalog.new()
	return _shared_quest_catalog


func _shared_faction_catalog_or_new() -> FactionCatalog:
	if _shared_faction_catalog == null:
		_shared_faction_catalog = FactionCatalog.new()
	return _shared_faction_catalog


func _shared_world_event_catalog_or_new() -> WorldEventCatalog:
	if _shared_world_event_catalog == null:
		_shared_world_event_catalog = WorldEventCatalog.new()
	return _shared_world_event_catalog


func _shared_progression_catalog_or_new() -> RegionProgressionCatalog:
	if _shared_progression_catalog == null:
		_shared_progression_catalog = RegionProgressionCatalog.new()
	return _shared_progression_catalog


func _shared_survival_catalog_or_new() -> SurvivalCatalog:
	if _shared_survival_catalog == null:
		_shared_survival_catalog = SurvivalCatalog.new()
	return _shared_survival_catalog


func _shared_equipment_catalog_or_new() -> EquipmentCatalog:
	if _shared_equipment_catalog == null:
		_shared_equipment_catalog = EquipmentCatalog.new(EquipmentCatalog.DEFAULT_CONFIG_PATH, _shared_item_catalog_or_new())
	return _shared_equipment_catalog


func _shared_building_catalog_or_new() -> BuildingCatalog:
	if _shared_building_catalog == null:
		_shared_building_catalog = BuildingCatalog.new()
	return _shared_building_catalog


func _shared_automation_catalog_or_new() -> AutomationCatalog:
	if _shared_automation_catalog == null:
		_shared_automation_catalog = AutomationCatalog.new()
	return _shared_automation_catalog


func _shared_homestead_catalog_or_new() -> HomesteadCatalog:
	if _shared_homestead_catalog == null:
		_shared_homestead_catalog = HomesteadCatalog.new()
	return _shared_homestead_catalog


func _shared_farming_catalog_or_new() -> FarmingCatalog:
	if _shared_farming_catalog == null:
		_shared_farming_catalog = FarmingCatalog.new()
	return _shared_farming_catalog


func _shared_husbandry_catalog_or_new() -> HusbandryCatalog:
	if _shared_husbandry_catalog == null:
		_shared_husbandry_catalog = HusbandryCatalog.new()
	return _shared_husbandry_catalog


func flush_pending_save() -> void:
	if _save_task_id < 0:
		return
	var error := WorkerThreadPool.wait_for_task_completion(_save_task_id)
	if error != OK:
		last_error = "等待存档线程失败：%s" % error_string(error)
		LogManager.error("SaveManager", last_error)
		_save_task_id = -1
		_save_job = null
		return
	_collect_completed_save(true)
	if _save_task_id >= 0:
		flush_pending_save()


func has_current_world() -> bool:
	return not _current_world_id.is_empty()


func current_world_id() -> String:
	return _current_world_id


func current_world_name() -> String:
	return String(_metadata.get("world_name", "临时世界"))


func current_seed_text() -> String:
	return String(_metadata.get("seed_text", WorldSeed.DEFAULT_TEXT))


func current_seed() -> int:
	return int(_metadata.get("seed", WorldSeed.from_text(WorldSeed.DEFAULT_TEXT)))


func current_game_time_seconds() -> float:
	return float(_metadata.get("game_time_seconds", 0.0))


func current_weather_state() -> Dictionary:
	return (_metadata.get("weather_state", {}) as Dictionary).duplicate(true)


func current_player_layer() -> StringName:
	return StringName(_metadata.get("player_layer", "surface"))


func loaded_player_snapshot() -> Dictionary:
	return _player_snapshot.duplicate(true)


func loaded_world_state_snapshot() -> Dictionary:
	return _world_state_snapshot.duplicate(true)


func current_world_root_absolute() -> String:
	return _world_root_absolute(_current_world_id) if not _current_world_id.is_empty() else ""


func clear_current_world() -> void:
	flush_pending_save()
	_current_world_id = ""
	_metadata.clear()
	_player_snapshot.clear()
	_world_state_snapshot.clear()
	last_error = ""


func _start_save(request: Dictionary) -> void:
	var player := request["player"] as Dictionary
	var world_state := request["world_state"] as Dictionary
	player["save_version"] = GameVersion.SAVE_VERSION
	player["active_tool"] = String(world_state.get("active_tool", "hands"))
	player["inventory"] = (world_state.get("inventory", {}) as Dictionary).duplicate(true)
	player["crafting_state"] = (world_state.get("crafting_state", {}) as Dictionary).duplicate(true)
	player["grave_state"] = (world_state.get("grave_state", {}) as Dictionary).duplicate(true)
	player["milestone_state"] = (world_state.get("milestone_state", {}) as Dictionary).duplicate(true)
	player["dungeon_state"] = (world_state.get("dungeon_state", {}) as Dictionary).duplicate(true)
	player["exploration_state"] = (world_state.get("exploration_state", {}) as Dictionary).duplicate(true)
	player["regional_boss_state"] = (world_state.get("regional_boss_state", {}) as Dictionary).duplicate(true)
	player["npc_state"] = (world_state.get("npc_state", {}) as Dictionary).duplicate(true)
	player["relationship_state"] = (world_state.get("relationship_state", {}) as Dictionary).duplicate(true)
	player["quest_state"] = (world_state.get("quest_state", {}) as Dictionary).duplicate(true)
	player["world_choice_state"] = (world_state.get("world_choice_state", {}) as Dictionary).duplicate(true)
	player["faction_state"] = (world_state.get("faction_state", {}) as Dictionary).duplicate(true)
	player["world_event_state"] = (world_state.get("world_event_state", {}) as Dictionary).duplicate(true)
	player["region_progression_state"] = (world_state.get("region_progression_state", {}) as Dictionary).duplicate(true)
	player["survival_state"] = (world_state.get("survival_state", {}) as Dictionary).duplicate(true)
	player["equipment_state"] = (world_state.get("equipment_state", {}) as Dictionary).duplicate(true)
	player["homestead_state"] = (world_state.get("homestead_state", {}) as Dictionary).duplicate(true)
	var world_layer := String(world_state.get("world_layer", "surface"))
	if not ["surface", "underground", "dungeon"].has(world_layer):
		world_layer = "surface"
	player["world_layer"] = world_layer
	_metadata["player_layer"] = world_layer
	_metadata["last_played_at"] = Time.get_datetime_string_from_system(false, true)
	_metadata["game_time_seconds"] = float(request["game_time_seconds"])
	var requested_weather := request.get("weather_state", {}) as Dictionary
	if not requested_weather.is_empty():
		_metadata["weather_state"] = requested_weather.duplicate(true)
	elif not _metadata.has("weather_state"):
		_metadata["weather_state"] = WeatherSystem.new(current_seed()).persistence_snapshot()
	_metadata["game_version"] = GameVersion.VERSION
	var chunk_differences := _group_chunk_differences(world_state)
	var snapshot := {
		"root_path": current_world_root_absolute(),
		"world": _metadata.duplicate(true),
		"player": player,
		"chunk_differences": chunk_differences,
		"create_backup": bool(request["create_backup"]),
	}
	_player_snapshot = player.duplicate(true)
	_world_state_snapshot = world_state.duplicate(true)
	_save_job = SaveWriteJob.new(snapshot)
	_save_task_id = WorkerThreadPool.add_task(_save_job.execute, true, "save_%s" % _current_world_id)
	EventBus.save_status_changed.emit("正在%s保存…" % ("手动" if bool(request["create_backup"]) else "自动"), true)


func _collect_completed_save(already_waited := false) -> void:
	if _save_task_id < 0 or _save_job == null:
		return
	if not already_waited:
		var error := WorkerThreadPool.wait_for_task_completion(_save_task_id)
		if error != OK:
			last_error = "存档线程失败：%s" % error_string(error)
			LogManager.error("SaveManager", last_error)
			EventBus.save_status_changed.emit(last_error, false)
			_save_task_id = -1
			_save_job = null
			return
	var completed_result := _save_job.result.duplicate(true)
	_save_task_id = -1
	_save_job = null
	last_save_duration_ms = float(completed_result.get("duration_usec", 0)) / 1000.0
	if bool(completed_result.get("ok", false)):
		last_error = ""
		var differences := int(completed_result.get("written_difference_files", 0))
		LogManager.info("SaveManager", "Saved world in %.2f ms (%d difference files)" % [last_save_duration_ms, differences])
		EventBus.save_status_changed.emit("保存完成 · %.1f ms · %d 个差异文件" % [last_save_duration_ms, differences], true)
	else:
		last_error = String(completed_result.get("error", "未知存档错误"))
		LogManager.error("SaveManager", last_error)
		EventBus.save_status_changed.emit("保存失败：%s" % last_error, false)
	if not _queued_request.is_empty():
		var next_request := _queued_request
		_queued_request = {}
		_start_save(next_request)


func _group_chunk_differences(world_state: Dictionary) -> Dictionary:
	var grouped := {}
	for value in world_state.get("collected_resources", []) as Array:
		var resource_key := String(value)
		var parts := resource_key.split(":")
		var layer := "surface"
		var coordinate_offset := 0
		if parts.size() == 4 and ["surface", "underground"].has(parts[0]):
			layer = parts[0]
			coordinate_offset = 1
		elif parts.size() != 3:
			continue
		if not parts[coordinate_offset].is_valid_int() \
				or not parts[coordinate_offset + 1].is_valid_int() \
				or not parts[coordinate_offset + 2].is_valid_int():
			continue
		var world_tile := Vector2i(int(parts[coordinate_offset]), int(parts[coordinate_offset + 1]))
		var chunk := WorldCoordinates.tile_to_chunk(world_tile)
		var chunk_key := "%s_%d_%d" % [layer, chunk.x, chunk.y]
		_ensure_difference_group(grouped, chunk_key, layer, chunk)
		(grouped[chunk_key]["removed_resources"] as Array).append(resource_key)
	for value in world_state.get("opened_cave_chests", []) as Array:
		var chest_key := String(value)
		var parts := chest_key.split(":")
		if parts.size() != 3 or parts[0] != "underground" \
				or not parts[1].is_valid_int() or not parts[2].is_valid_int():
			continue
		var world_tile := Vector2i(int(parts[1]), int(parts[2]))
		var chunk := WorldCoordinates.tile_to_chunk(world_tile)
		var chunk_key := "underground_%d_%d" % [chunk.x, chunk.y]
		_ensure_difference_group(grouped, chunk_key, "underground", chunk)
		(grouped[chunk_key]["opened_chests"] as Array).append(chest_key)
	var building_state := world_state.get("building_state", {}) as Dictionary
	for value in building_state.get("placements", []) as Array:
		var record := value as Dictionary
		var tile_value := record.get("world_tile", []) as Array
		if tile_value.size() != 2:
			continue
		var world_tile := Vector2i(int(tile_value[0]), int(tile_value[1]))
		var chunk := WorldCoordinates.tile_to_chunk(world_tile)
		var chunk_key := "surface_%d_%d" % [chunk.x, chunk.y]
		_ensure_difference_group(grouped, chunk_key, "surface", chunk)
		(grouped[chunk_key]["placed_buildings"] as Array).append(record.duplicate(true))
	var farming_state := world_state.get("farming_state", {}) as Dictionary
	for value in farming_state.get("plots", []) as Array:
		var record := value as Dictionary
		var tile_value := record.get("world_tile", []) as Array
		if tile_value.size() != 2:
			continue
		var world_tile := Vector2i(int(tile_value[0]), int(tile_value[1]))
		var chunk := WorldCoordinates.tile_to_chunk(world_tile)
		var chunk_key := "surface_%d_%d" % [chunk.x, chunk.y]
		_ensure_difference_group(grouped, chunk_key, "surface", chunk)
		(grouped[chunk_key]["farming_plots"] as Array).append(record.duplicate(true))
	var husbandry_state := world_state.get("husbandry_state", {}) as Dictionary
	for value in husbandry_state.get("animals", []) as Array:
		var record := value as Dictionary
		var tile_value := record.get("world_tile", []) as Array
		if tile_value.size() != 2:
			continue
		var world_tile := Vector2i(int(tile_value[0]), int(tile_value[1]))
		var chunk := WorldCoordinates.tile_to_chunk(world_tile)
		var chunk_key := "surface_%d_%d" % [chunk.x, chunk.y]
		_ensure_difference_group(grouped, chunk_key, "surface", chunk)
		(grouped[chunk_key]["husbandry_animals"] as Array).append(record.duplicate(true))
	for chunk_key in grouped:
		(grouped[chunk_key]["removed_resources"] as Array).sort()
		(grouped[chunk_key]["opened_chests"] as Array).sort()
		(grouped[chunk_key]["placed_buildings"] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("placement_id", "")) < String(b.get("placement_id", ""))
		)
		(grouped[chunk_key]["farming_plots"] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("plot_id", "")) < String(b.get("plot_id", ""))
		)
		(grouped[chunk_key]["husbandry_animals"] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("animal_id", "")) < String(b.get("animal_id", ""))
		)
	return grouped


func _ensure_difference_group(grouped: Dictionary, chunk_key: String, layer: String, chunk: Vector2i) -> void:
	if grouped.has(chunk_key):
		return
	grouped[chunk_key] = {
		"save_version": GameVersion.SAVE_VERSION,
		"generation_version": GameVersion.GENERATION_VERSION,
		"layer": layer,
		"chunk": [chunk.x, chunk.y],
		"removed_resources": [],
		"opened_chests": [],
		"placed_buildings": [],
		"farming_plots": [],
		"husbandry_animals": [],
	}


func _load_chunk_differences(chunks_path: String, expected_layer: StringName) -> Dictionary:
	var collected: Array[String] = []
	var opened_chests: Array[String] = []
	var placed_buildings: Array[Dictionary] = []
	var farming_plots: Array[Dictionary] = []
	var husbandry_animals: Array[Dictionary] = []
	var directory := DirAccess.open(chunks_path)
	if directory == null:
		return {"ok": true, "error": "", "collected_resources": collected, "opened_cave_chests": opened_chests, "placed_buildings": placed_buildings, "farming_plots": farming_plots, "husbandry_animals": husbandry_animals}
	for filename in directory.get_files():
		if not filename.ends_with(".json"):
			continue
		var read_result := _read_json(chunks_path.path_join(filename))
		if not bool(read_result["ok"]):
			return {"ok": false, "error": "%s：%s" % [filename, read_result["error"]], "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		var difference := read_result["data"] as Dictionary
		if not SUPPORTED_SAVE_VERSIONS.has(int(difference.get("save_version", 0))) \
				or not SUPPORTED_GENERATION_VERSIONS.has(int(difference.get("generation_version", 0))) \
				or StringName(difference.get("layer", "")) != expected_layer:
			return {"ok": false, "error": "%s 的版本或世界层无效" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		var chunk_value: Variant = difference.get("chunk", [])
		if not chunk_value is Array or (chunk_value as Array).size() != 2:
			return {"ok": false, "error": "%s 的区块坐标无效" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		var expected_chunk := Vector2i(int((chunk_value as Array)[0]), int((chunk_value as Array)[1]))
		var removed: Variant = difference.get("removed_resources", [])
		if not removed is Array:
			return {"ok": false, "error": "%s 的资源差异不是数组" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		for value in removed as Array:
			var key := String(value)
			var parts := key.split(":")
			var coordinate_offset := 0 if expected_layer == &"surface" else 1
			var valid_key := (parts.size() == 3 if expected_layer == &"surface" \
				else parts.size() == 4 and parts[0] == "underground") \
				and parts[coordinate_offset].is_valid_int() \
				and parts[coordinate_offset + 1].is_valid_int() \
				and parts[coordinate_offset + 2].is_valid_int()
			if not valid_key:
				return {"ok": false, "error": "%s 包含无效资源键" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
			if not collected.has(key):
				collected.append(key)
		var opened: Variant = difference.get("opened_chests", [])
		if not opened is Array:
			return {"ok": false, "error": "%s 的宝箱差异不是数组" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		for value in opened as Array:
			var key := String(value)
			var parts := key.split(":")
			if expected_layer != &"underground" or parts.size() != 3 or parts[0] != "underground" \
					or not parts[1].is_valid_int() or not parts[2].is_valid_int():
				return {"ok": false, "error": "%s 包含无效宝箱键" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
			if not opened_chests.has(key):
				opened_chests.append(key)
		var difference_save_version := int(difference.get("save_version", 0))
		var buildings_value: Variant = difference.get("placed_buildings", []) if difference_save_version >= 19 else []
		if not buildings_value is Array:
			return {"ok": false, "error": "%s 的玩家建筑差异不是数组" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		if expected_layer != &"surface" and not (buildings_value as Array).is_empty():
			return {"ok": false, "error": "%s 在地下包含玩家建筑" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
		for building_value in buildings_value as Array:
			if not building_value is Dictionary:
				return {"ok": false, "error": "%s 包含无效玩家建筑记录" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
			var record := building_value as Dictionary
			if difference_save_version < 24 and not BuildingCatalog.new().automation_kind(StringName(record.get("piece_id", ""))).is_empty():
				continue
			var tile_value: Variant = record.get("world_tile", [])
			if not tile_value is Array or (tile_value as Array).size() != 2:
				return {"ok": false, "error": "%s 包含无效玩家建筑坐标" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
			var building_tile := Vector2i(int((tile_value as Array)[0]), int((tile_value as Array)[1]))
			if WorldCoordinates.tile_to_chunk(building_tile) != expected_chunk:
				return {"ok": false, "error": "%s 的玩家建筑不属于声明区块" % filename, "collected_resources": [], "opened_cave_chests": [], "placed_buildings": []}
			placed_buildings.append(record.duplicate(true))
		var farming_value: Variant = difference.get("farming_plots", []) if difference_save_version >= 20 else []
		if not farming_value is Array:
			return {"ok": false, "error": "%s 的农业差异不是数组" % filename}
		if expected_layer != &"surface" and not (farming_value as Array).is_empty():
			return {"ok": false, "error": "%s 在地下包含耕地" % filename}
		for plot_value in farming_value as Array:
			if not plot_value is Dictionary:
				return {"ok": false, "error": "%s 包含无效耕地记录" % filename}
			var plot_record := plot_value as Dictionary
			var plot_tile_value: Variant = plot_record.get("world_tile", [])
			if not plot_tile_value is Array or (plot_tile_value as Array).size() != 2:
				return {"ok": false, "error": "%s 包含无效耕地坐标" % filename}
			var farming_tile := Vector2i(int((plot_tile_value as Array)[0]), int((plot_tile_value as Array)[1]))
			if WorldCoordinates.tile_to_chunk(farming_tile) != expected_chunk:
				return {"ok": false, "error": "%s 的耕地不属于声明区块" % filename}
			farming_plots.append(plot_record.duplicate(true))
		var husbandry_value: Variant = difference.get("husbandry_animals", []) if difference_save_version >= 21 else []
		if not husbandry_value is Array:
			return {"ok": false, "error": "%s 的养殖差异不是数组" % filename}
		if expected_layer != &"surface" and not (husbandry_value as Array).is_empty():
			return {"ok": false, "error": "%s 在地下包含动物" % filename}
		for animal_value in husbandry_value as Array:
			if not animal_value is Dictionary:
				return {"ok": false, "error": "%s 包含无效动物记录" % filename}
			var animal_record := animal_value as Dictionary
			var animal_tile_value: Variant = animal_record.get("world_tile", [])
			if not animal_tile_value is Array or (animal_tile_value as Array).size() != 2:
				return {"ok": false, "error": "%s 包含无效动物坐标" % filename}
			var animal_tile := Vector2i(int((animal_tile_value as Array)[0]), int((animal_tile_value as Array)[1]))
			if WorldCoordinates.tile_to_chunk(animal_tile) != expected_chunk:
				return {"ok": false, "error": "%s 的动物不属于声明区块" % filename}
			husbandry_animals.append(animal_record.duplicate(true))
	collected.sort()
	opened_chests.sort()
	placed_buildings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("placement_id", "")) < String(b.get("placement_id", ""))
	)
	farming_plots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("plot_id", "")) < String(b.get("plot_id", ""))
	)
	husbandry_animals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("animal_id", "")) < String(b.get("animal_id", ""))
	)
	return {"ok": true, "error": "", "collected_resources": collected, "opened_cave_chests": opened_chests, "placed_buildings": placed_buildings, "farming_plots": farming_plots, "husbandry_animals": husbandry_animals}


func _validate_metadata(metadata: Dictionary) -> String:
	if not SUPPORTED_SAVE_VERSIONS.has(int(metadata.get("save_version", 0))):
		return "存档版本 %s 不受 V%s 支持" % [metadata.get("save_version", "缺失"), GameVersion.VERSION]
	if not SUPPORTED_GENERATION_VERSIONS.has(int(metadata.get("generation_version", 0))):
		return "生成版本 %s 与当前版本 %d 不兼容" % [metadata.get("generation_version", "缺失"), GameVersion.GENERATION_VERSION]
	if int(metadata.get("save_version", 0)) == GameVersion.SAVE_VERSION and int(metadata.get("generation_version", 0)) != GameVersion.GENERATION_VERSION:
		return "当前存档必须使用生成版本 %d" % GameVersion.GENERATION_VERSION
	for key in ["world_id", "world_name", "seed_text", "seed", "created_at", "last_played_at"]:
		if not metadata.has(key) or str(metadata[key]).is_empty():
			return "世界元数据缺少 %s" % key
	if int(metadata.get("save_version", 0)) >= 7:
		var weather_value: Variant = metadata.get("weather_state", {})
		if not weather_value is Dictionary:
			return "天气存档状态必须是对象"
		var weather := WeatherSystem.new(int(metadata.get("seed", 0)))
		if not weather.restore_snapshot(weather_value as Dictionary):
			return "天气存档状态无效"
	var metadata_version := int(metadata.get("save_version", 0))
	var valid_layers := ["surface", "underground", "dungeon"] if metadata_version >= 9 else ["surface", "underground"]
	if metadata_version >= 8 and not valid_layers.has(String(metadata.get("player_layer", ""))):
		return "玩家世界层无效"
	return ""


func _validate_player(player: Dictionary) -> String:
	var player_save_version := int(player.get("save_version", 0))
	if not SUPPORTED_SAVE_VERSIONS.has(player_save_version):
		return "玩家存档版本无效"
	var position_value: Variant = player.get("position", [])
	if not position_value is Array or (position_value as Array).size() != 2:
		return "玩家位置必须包含两个坐标"
	for key in ["health", "maximum_health", "stamina", "maximum_stamina"]:
		if not player.has(key):
			return "玩家属性缺少 %s" % key
	var inventory_value: Variant = player.get("inventory", {})
	if not inventory_value is Dictionary:
		return "背包数据必须是对象"
	var validated_inventory: InventoryModel
	if player_save_version >= 3:
		if player_save_version == GameVersion.SAVE_VERSION and int((inventory_value as Dictionary).get("schema_version", 0)) != InventoryModel.SCHEMA_VERSION:
			return "背包格式不是当前版本"
		validated_inventory = InventoryModel.new()
		if not validated_inventory.restore_snapshot(inventory_value as Dictionary):
			return validated_inventory.last_error
	if player_save_version >= 4:
		var crafting_value: Variant = player.get("crafting_state", {})
		if not crafting_value is Dictionary:
			return "制作解锁数据必须是对象"
		var crafting := CraftingSystem.new(validated_inventory)
		if not crafting.restore_snapshot(crafting_value as Dictionary):
			return crafting.last_error
	if player_save_version == GameVersion.SAVE_VERSION:
		if not ["surface", "underground", "dungeon"].has(String(player.get("world_layer", ""))):
			return "玩家世界层无效"
		var combat_value: Variant = player.get("combat_state", {})
		if not combat_value is Dictionary:
			return "战斗状态必须是对象"
		var combat := PlayerCombatState.new()
		var position_array := position_value as Array
		if not combat.restore_snapshot(combat_value as Dictionary, Vector2(float(position_array[0]), float(position_array[1]))):
			return combat.last_error
		var grave_value: Variant = player.get("grave_state", {})
		if not grave_value is Dictionary:
			return "墓碑数据必须是对象"
		var graves := GraveModel.new()
		if not graves.restore_snapshot(grave_value as Dictionary):
			return graves.last_error
		var milestone_value: Variant = player.get("milestone_state", {})
		if not milestone_value is Dictionary:
			return "里程碑数据必须是对象"
		var milestones := MilestoneState.new()
		if not milestones.restore_snapshot(milestone_value as Dictionary):
			return milestones.last_error
		var dungeon_value: Variant = player.get("dungeon_state", {})
		if not dungeon_value is Dictionary:
			return "地牢进度必须是对象"
		var dungeons := DungeonRunState.new()
		if not dungeons.restore_snapshot(dungeon_value as Dictionary):
			return dungeons.last_error
		if (String(player.get("world_layer", "")) == "dungeon") != (not dungeons.current_dungeon_id().is_empty()):
			return "当前地牢与玩家世界层不一致"
		var exploration_value: Variant = player.get("exploration_state", {})
		if not exploration_value is Dictionary:
			return "探索地图进度必须是对象"
		var exploration := ExplorationMapState.new()
		if not exploration.restore_snapshot(exploration_value as Dictionary):
			return exploration.last_error
		var regional_value: Variant = player.get("regional_boss_state", {})
		if not regional_value is Dictionary:
			return "区域首领进度必须是对象"
		var regional := RegionalBossState.new()
		if not regional.restore_snapshot(regional_value as Dictionary):
			return regional.last_error
		var npc_value: Variant = player.get("npc_state", {})
		if not npc_value is Dictionary:
			return "NPC 状态必须是对象"
		var npcs := NpcWorldState.new()
		if not npcs.restore_snapshot(npc_value as Dictionary):
			return npcs.last_error
		var relationship_value: Variant = player.get("relationship_state", {})
		if not relationship_value is Dictionary:
			return "关系状态必须是对象"
		var relationships := RelationshipState.new()
		if not relationships.restore_snapshot(relationship_value as Dictionary):
			return relationships.last_error
		var quest_value: Variant = player.get("quest_state", {})
		if not quest_value is Dictionary:
			return "任务状态必须是对象"
		var quests := QuestState.new()
		if not quests.restore_snapshot(quest_value as Dictionary, QuestCatalog.new()):
			return quests.last_error
		var choice_value: Variant = player.get("world_choice_state", {})
		if not choice_value is Dictionary:
			return "世界选择状态必须是对象"
		var choices := WorldChoiceState.new()
		if not choices.restore_snapshot(choice_value as Dictionary, QuestCatalog.new()):
			return choices.last_error
		var faction_value: Variant = player.get("faction_state", {})
		if not faction_value is Dictionary:
			return "阵营状态必须是对象"
		var factions := FactionState.new()
		if not factions.restore_snapshot(faction_value as Dictionary, FactionCatalog.new()):
			return factions.last_error
		var event_value: Variant = player.get("world_event_state", {})
		if not event_value is Dictionary:
			return "世界事件状态必须是对象"
		var events := WorldEventState.new()
		if not events.restore_snapshot(event_value as Dictionary, WorldEventCatalog.new()):
			return events.last_error
		var progression_value: Variant = player.get("region_progression_state", {})
		if not progression_value is Dictionary:
			return "区域进度状态必须是对象"
		var progression := RegionProgressionState.new()
		if not progression.restore_snapshot(progression_value as Dictionary, RegionProgressionCatalog.new()):
			return progression.last_error
		var survival_value: Variant = player.get("survival_state", {})
		if not survival_value is Dictionary:
			return "生存状态必须是对象"
		var survival := SurvivalState.new()
		if not survival.restore_snapshot(survival_value as Dictionary):
			return survival.last_error
		var equipment_value: Variant = player.get("equipment_state", {})
		if not equipment_value is Dictionary:
			return "装备状态必须是对象"
		var equipment := EquipmentState.new()
		if not equipment.restore_snapshot(equipment_value as Dictionary):
			return equipment.last_error
		var homestead_value: Variant = player.get("homestead_state", {})
		if not homestead_value is Dictionary:
			return "家园状态必须是对象"
		var homestead := HomesteadState.new()
		if not homestead.restore_snapshot(homestead_value as Dictionary):
			return homestead.last_error
	return ""


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "无法读取 %s（%s）" % [path.get_file(), error_string(FileAccess.get_open_error())], "data": {}}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		return {"ok": false, "error": "%s 第 %d 行：%s" % [path.get_file(), parser.get_error_line(), parser.get_error_message()], "data": {}}
	if not parser.data is Dictionary:
		return {"ok": false, "error": "%s 根节点不是对象" % path.get_file(), "data": {}}
	return {"ok": true, "error": "", "data": parser.data}


func _write_initial_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("无法写入初始存档：%s" % error_string(FileAccess.get_open_error()))
	file.store_string(JSON.stringify(data, "\t", true, true) + "\n")
	file.flush()
	return true


func _world_root_absolute(world_id: String) -> String:
	return ProjectSettings.globalize_path(SAVE_ROOT.path_join(world_id))


func _fail(message: String) -> bool:
	last_error = message
	LogManager.warning("SaveManager", message)
	return false
