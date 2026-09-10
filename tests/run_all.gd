extends Node

var _failures: Array[String] = []
var _passes := 0


func _ready() -> void:
	print("=== Infinite Frontier test suite v%s ===" % GameVersion.VERSION)
	_test_project_resources()
	_test_version_contract()
	_test_event_bus_contract()
	_test_settings_round_trip()
	_test_scene_transition_contract()
	_test_player_motor_frame_independence()
	_test_world_seed_contract()
	_test_world_coordinate_contract()
	_test_biome_catalog_contract()
	_test_resource_catalog_contract()
	_test_item_catalog_contract()
	_test_inventory_model()
	_test_recipe_catalog_contract()
	_test_crafting_system()
	_test_tool_speed_and_durability()
	_test_weapon_catalog_contract()
	_test_attack_sequence_and_damage()
	_test_player_combat_state_and_graves()
	_test_enemy_catalog_and_state_machine()
	_test_enemy_spawn_planner()
	_test_milestone_models()
	_test_weather_models()
	_test_season_models()
	_test_survival_models()
	_test_building_models()
	_test_farming_models()
	_test_husbandry_models()
	_test_processing_models()
	_test_equipment_models()
	_test_automation_models()
	_test_homestead_models()
	_test_ocean_models()
	_test_ocean_generation_scan()
	_test_hydrology_models()
	_test_structure_models()
	_test_village_models()
	_test_npc_models()
	_test_quest_models()
	_test_faction_models()
	_test_world_event_models()
	_test_region_progression_models()
	_test_cave_models()
	_test_dungeon_models()
	_test_exploration_models()
	_test_deterministic_generation()
	_test_biome_regions()
	_test_resource_generation()
	_test_resource_harvest_state()
	await _test_save_system()
	_test_stream_planner()
	_test_chunk_seams()
	_test_background_generation()
	await _test_player_scene_contract()
	await _test_chunk_renderer()
	await _test_building_runtime()
	await _test_processing_runtime()
	await _test_equipment_runtime()
	await _test_automation_runtime()
	await _test_homestead_runtime()
	await _test_ocean_runtime()
	await _test_farming_runtime()
	await _test_husbandry_runtime()
	await _test_cave_runtime()
	await _test_dungeon_runtime()
	await _test_exploration_runtime_and_hud()
	await _test_npc_runtime_and_hud()
	await _test_world_event_runtime_and_hud()
	await _test_region_progression_runtime_and_hud()
	await _test_drop_pool()
	await _test_generation_hud_layout()
	await _test_resource_hud_layout()
	await _test_survival_hud_layout()
	await _test_building_panel_layout()
	await _test_farming_panel_layout()
	await _test_husbandry_panel_layout()
	await _test_processing_panel_layout()
	await _test_equipment_panel_layout()
	await _test_automation_panel_layout()
	await _test_homestead_panel_layout()
	await _test_inventory_panel_layout()
	await _test_crafting_panel_layout()
	await _test_combat_nodes_and_hud()
	await _test_enemy_runtime_and_hud()
	await _test_adventure_runtime_and_hud()
	await _test_main_menu_layout()
	await _test_responsive_ui_layouts()
	await get_tree().process_frame
	await get_tree().process_frame
	_finish()


func _test_project_resources() -> void:
	_assert_true(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/main/game.tscn"), "game scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/player/player.tscn"), "player scene exists")
	_assert_true(ResourceLoader.exists("res://assets/branding/icon.svg"), "application icon exists")
	var project_font := load("res://assets/fonts/NotoSansCJKsc-ProjectSubset.otf") as Font
	var required_v2_glyphs := "世界探索地图已发现区块地点标记传送区域首领自定义针叶林稀树草原花甸野猪冰霜精灵冠巨像沙海兽穹翼龙安全营地村长杂货商旅店老板农夫守卫探险家对话交易出售收购边境币休息次日清晨任务日志主线支线接取追踪放弃重试领取奖励失败护送会合阵营档案声望关系敌视中立尊敬同盟死敌灰烬斥候掠团村盟行商公会远路探盟控制点影响力夺取动摇动态事件商队经过袭击流星坠落资源爆发暴风雪遗迹开启临时救援时间表持久化预告失效危险等级装备评分精英解锁进度极境安定警戒凶险致命固定随机委托关键选择结果保存旗帜协定地平线未来生存属性饥饿体温湿润中毒燃烧冻伤伤害食物恢复环境影响状态关闭暂停寒冷炎热舒适正常食用快捷栏玩家建造木地板墙门基础屋顶桌储物箱落地火把工作站放置拆除返还旋转蓝图合法占用承载存入取回农业农园耕地开垦麦种小麦胡萝卜番茄苹果树苗肥料播种浇水成熟品质优质金质果树施肥天气减慢生长养殖牧场驯服动物喂食繁殖产出围栏睡眠休眠模拟鸡牛羊蛋奶毛亲密幼崽饲料烹饪炼制锅多材料配方药水恢复冶炉矿石锭装备燃料田园炖菜派丰盛早餐解毒暖身药剂清凉铜铁钢淬火板砌筑打造熔锻投入仓容量加工设备就绪附近使用自动化传送带连接器分拣工作限流筛选流向启动累计卸载补算家园基地信标范围管理返回冷却循环完成待建覆盖拓荒河谷前哨远境船屿氧溺帆礁藻珊瑚沉蛤潮汐君主泳骸鳍渊鳃烤鱼贝簇浮木生登部署靠近停泊靠岸深浅水域掠鱼巨口皇印"
	var font_complete := project_font != null
	for index in required_v2_glyphs.length():
		font_complete = font_complete and project_font.has_char(required_v2_glyphs.unicode_at(index))
	_assert_true(font_complete, "project font covers every V4.1 ocean, survival-building and homestead UI glyph")
	_assert_true(ResourceLoader.exists("res://data/weapons.json"), "weapon catalog exists")
	_assert_true(ResourceLoader.exists("res://data/enemies.json"), "enemy catalog exists")
	_assert_true(ResourceLoader.exists("res://data/milestones.json"), "milestone catalog exists")
	_assert_true(ResourceLoader.exists("res://data/weather.json"), "weather catalog exists")
	_assert_true(ResourceLoader.exists("res://data/structures.json"), "structure catalog exists")
	_assert_true(ResourceLoader.exists("res://data/villages.json"), "village catalog exists")
	_assert_true(ResourceLoader.exists("res://data/caves.json"), "cave catalog exists")
	_assert_true(ResourceLoader.exists("res://data/dungeons.json"), "dungeon catalog exists")
	_assert_true(ResourceLoader.exists("res://data/regional_bosses.json"), "regional Boss catalog exists")
	_assert_true(ResourceLoader.exists("res://data/npcs.json"), "NPC catalog exists")
	_assert_true(ResourceLoader.exists("res://data/relationships.json"), "relationship catalog exists")
	_assert_true(ResourceLoader.exists("res://data/quests.json"), "quest catalog exists")
	_assert_true(ResourceLoader.exists("res://data/factions.json"), "faction catalog exists")
	_assert_true(ResourceLoader.exists("res://data/world_events.json"), "world-event catalog exists")
	_assert_true(ResourceLoader.exists("res://data/region_progression.json"), "region-progression catalog exists")
	_assert_true(ResourceLoader.exists("res://data/survival.json"), "survival catalog exists")
	_assert_true(ResourceLoader.exists("res://data/buildings.json"), "building catalog exists")
	_assert_true(ResourceLoader.exists("res://data/farming.json"), "farming catalog exists")
	_assert_true(ResourceLoader.exists("res://data/husbandry.json"), "husbandry catalog exists")
	_assert_true(ResourceLoader.exists("res://data/processing.json"), "processing catalog exists")
	_assert_true(ResourceLoader.exists("res://data/equipment.json"), "equipment catalog exists")
	_assert_true(ResourceLoader.exists("res://data/automation.json"), "automation catalog exists")
	_assert_true(ResourceLoader.exists("res://data/homestead.json"), "homestead catalog exists")


func _test_version_contract() -> void:
	_assert_equal(GameVersion.VERSION, "4.1.0", "version constant")
	_assert_equal(GameVersion.SAVE_VERSION, 26, "V4.1 deployed boats and oxygen advance save format 26")
	_assert_equal(GameVersion.GENERATION_VERSION, 6, "V4.1 island biomes and water resources advance generation version 6")


func _test_survival_models() -> void:
	var catalog := SurvivalCatalog.new()
	_assert_true(catalog.is_valid(), "external survival configuration loads and validates")
	var effect_ids := catalog.effect_ids()
	_assert_true(effect_ids.size() == 5 and effect_ids.has(&"poison") and effect_ids.has(&"burning") and effect_ids.has(&"frostbite") and effect_ids.has(&"starvation") and effect_ids.has(&"drowning"), "poison, burning, frostbite, starvation and drowning effects are data-driven")
	var food_ids := catalog.food_ids()
	_assert_true(food_ids.size() == 11 and food_ids.has(&"berry") and food_ids.has(&"cooked_berries") and food_ids.has(&"vegetable_stew") and food_ids.has(&"apple_pie") and food_ids.has(&"hearty_breakfast") and food_ids.has(&"antidote_potion") and food_ids.has(&"warming_tonic") and food_ids.has(&"cooling_tonic") and food_ids.has(&"kelp") and food_ids.has(&"clam") and food_ids.has(&"cooked_fish"), "raw food, cooked meals, recovery potions and ocean foods expose explicit survival effects")
	var mild_environment := {"world_layer": "surface", "biome_id": "plains", "weather_id": "CLEAR", "phase": "DAY", "in_water": false, "near_heat": false, "activity": &"IDLE"}
	var cold_environment := {"world_layer": "surface", "biome_id": "snowfield", "weather_id": "SNOW", "phase": "NIGHT", "in_water": false, "near_heat": false, "activity": &"IDLE"}
	var hot_environment := {"world_layer": "surface", "biome_id": "desert", "weather_id": "SANDSTORM", "phase": "DAY", "in_water": false, "near_heat": false, "activity": &"RUN"}
	_assert_true(catalog.target_temperature(cold_environment) < catalog.target_temperature(mild_environment) and catalog.target_temperature(hot_environment) > catalog.target_temperature(mild_environment), "biome, weather and phase compose cold and hot environment targets")
	var disabled_state := SurvivalState.new(catalog)
	var disabled_before := disabled_state.persistence_snapshot()
	var disabled_result := disabled_state.update(600.0, hot_environment, false)
	_assert_true(disabled_state.persistence_snapshot() == disabled_before and float(disabled_result["damage"]) == 0.0, "disabled survival rules pause every attribute and damage effect")
	var idle_state := SurvivalState.new(catalog)
	var run_state := SurvivalState.new(catalog)
	idle_state.update(100.0, mild_environment)
	var running_environment := mild_environment.duplicate(true)
	running_environment["activity"] = &"RUN"
	run_state.update(100.0, running_environment)
	_assert_true(run_state.hunger < idle_state.hunger and idle_state.hunger < 100.0, "hunger drains over time and running consumes more than idling")
	var wet_state := SurvivalState.new(catalog)
	var rain_environment := mild_environment.duplicate(true)
	rain_environment["weather_id"] = "RAIN"
	rain_environment["in_water"] = true
	wet_state.update(10.0, rain_environment)
	_assert_true(wet_state.wetness > 20.0, "rain and standing water compose deterministic wetness gain")
	var cold_state := SurvivalState.new(catalog)
	_assert_true(cold_state.restore_snapshot({
		"schema_version": 2, "hunger": 80.0, "body_temperature": 34.0, "wetness": 10.0, "oxygen": 100.0, "effects": [],
		"exposures": {"poison": 0.0, "burning": 0.0, "frostbite": 17.5},
	}), "cold survival fixture restores")
	cold_state.update(1.0, cold_environment)
	_assert_true(cold_state.has_effect(&"frostbite") and cold_state.movement_multiplier() < 1.0, "sustained cold applies frostbite and an explicit movement penalty")
	var hot_state := SurvivalState.new(catalog)
	hot_state.restore_snapshot({
		"schema_version": 2, "hunger": 80.0, "body_temperature": 41.5, "wetness": 0.0, "oxygen": 100.0, "effects": [],
		"exposures": {"poison": 0.0, "burning": 14.5, "frostbite": 0.0},
	})
	hot_state.update(1.0, hot_environment)
	_assert_true(hot_state.has_effect(&"burning"), "sustained extreme heat applies burning")
	var poison_state := SurvivalState.new(catalog)
	poison_state.restore_snapshot({
		"schema_version": 2, "hunger": 80.0, "body_temperature": 37.0, "wetness": 80.0, "oxygen": 100.0, "effects": [],
		"exposures": {"poison": 24.5, "burning": 0.0, "frostbite": 0.0},
	})
	var swamp_environment := mild_environment.duplicate(true)
	swamp_environment["biome_id"] = "swamp"
	poison_state.update(1.0, swamp_environment)
	_assert_true(poison_state.has_effect(&"poison"), "wet swamp exposure applies poison without random rerolls")
	var starving_state := SurvivalState.new(catalog)
	starving_state.restore_snapshot({
		"schema_version": 2, "hunger": 0.0, "body_temperature": 37.0, "wetness": 0.0, "oxygen": 100.0, "effects": [],
		"exposures": {"poison": 0.0, "burning": 0.0, "frostbite": 0.0},
	})
	var starvation_result := starving_state.update(4.1, mild_environment)
	_assert_true(starving_state.has_effect(&"starvation") and float(starvation_result["damage"]) == 3.0, "zero hunger applies bounded periodic starvation damage")
	var food_state := SurvivalState.new(catalog)
	food_state.hunger = 50.0
	food_state.apply_effect(&"poison")
	var food_result := food_state.consume_food(&"cooked_berries", 20.0)
	_assert_true(bool(food_result["ok"]) and is_equal_approx(food_state.hunger, 84.0) and float(food_result["health_restored"]) == 6.0 and not food_state.has_effect(&"poison"), "cooked food restores hunger and health while clearing its configured effect")
	food_state.hunger = 100.0
	food_state.body_temperature = 33.0
	food_state.apply_effect(&"frostbite")
	var tonic_result := food_state.consume_food(&"warming_tonic")
	_assert_true(bool(tonic_result["ok"]) and is_equal_approx(food_state.body_temperature, 37.0) and not food_state.has_effect(&"frostbite"), "zero-hunger warming potion remains useful for temperature and status recovery")
	var persisted_survival := food_state.persistence_snapshot()
	var restored_survival := SurvivalState.new(catalog)
	_assert_true(restored_survival.restore_snapshot(persisted_survival) and restored_survival.persistence_snapshot() == persisted_survival, "survival attributes, effects and exposure timers round trip exactly")
	var invalid_survival := persisted_survival.duplicate(true)
	invalid_survival["wetness"] = 101.0
	_assert_true(not SurvivalState.new(catalog).restore_snapshot(invalid_survival), "survival persistence rejects out-of-range attributes")
	food_state.apply_effect(&"burning")
	food_state.rest_at_inn()
	_assert_true(food_state.wetness == 0.0 and is_equal_approx(food_state.body_temperature, 37.0) and (food_state.status_snapshot()["effects"] as Array).is_empty(), "inn rest normalizes temperature, dries the player and clears active effects")


func _test_building_models() -> void:
	var catalog := BuildingCatalog.new()
	_assert_true(catalog.is_valid(), "external player-building configuration loads and validates")
	var piece_ids := catalog.piece_ids()
	_assert_true(piece_ids.size() == 17 and piece_ids.has(&"wood_floor") and piece_ids.has(&"wood_wall") and piece_ids.has(&"wood_door") and piece_ids.has(&"basic_roof") and piece_ids.has(&"wood_table") and piece_ids.has(&"storage_chest") and piece_ids.has(&"placed_torch") and piece_ids.has(&"workbench") and piece_ids.has(&"campfire") and piece_ids.has(&"animal_fence") and piece_ids.has(&"cooking_pot") and piece_ids.has(&"smelter") and piece_ids.has(&"conveyor_belt") and piece_ids.has(&"automatic_smelter") and piece_ids.has(&"storage_link") and piece_ids.has(&"item_sorter") and piece_ids.has(&"homestead_beacon"), "building catalog includes processing, automation and the homestead beacon")
	_assert_true(catalog.max_placements() == 4096 and catalog.placement_range_tiles() == 6 and is_equal_approx(catalog.refund_ratio(), 0.5), "building limits, range and demolition refund are explicit")
	var inventory := InventoryModel.new()
	for entry in [
		[&"wood", 50], [&"stone", 50], [&"fiber", 50], [&"torch", 5],
		[&"workbench", 1], [&"campfire", 1], [&"berry", 5],
	]:
		inventory.add_item(entry[0] as StringName, int(entry[1]))
	var state := BuildingState.new(catalog)
	var clear_context := {
		"world_layer": &"surface",
		"player_tile": Vector2i.ZERO,
		"player_occupied": false,
		"in_water": false,
		"generated_overlay": false,
		"resource_occupied": false,
	}
	var water_context := clear_context.duplicate(true)
	water_context["in_water"] = true
	_assert_true(not bool(state.preview(&"wood_floor", Vector2i(2, 2), 0, water_context)["valid"]), "placement validation rejects water")
	var resource_context := clear_context.duplicate(true)
	resource_context["resource_occupied"] = true
	_assert_true(not bool(state.preview(&"wood_floor", Vector2i(2, 2), 0, resource_context)["valid"]), "placement validation rejects uncollected resources")
	var husbandry_context := clear_context.duplicate(true)
	husbandry_context["husbandry_occupied"] = true
	_assert_true(not bool(state.preview(&"animal_fence", Vector2i(2, 2), 0, husbandry_context)["valid"]), "placement validation rejects wild and interacted animal occupancy")
	_assert_true(not bool(state.preview(&"wood_wall", Vector2i(5, 5), 0, clear_context)["valid"]), "wall placement requires a player floor")
	_assert_true(not bool(state.preview(&"wood_floor", Vector2i(7, 0), 0, clear_context)["valid"]), "placement validation enforces the six-tile range")
	var wood_before := inventory.quantity(&"wood")
	_assert_true(bool(state.place(&"wood_floor", Vector2i(1, 0), 0, clear_context, inventory)["ok"]), "valid preview commits one player floor")
	_assert_equal(inventory.quantity(&"wood"), wood_before - 2, "floor placement deducts its exact material cost")
	_assert_true(bool(state.place(&"wood_wall", Vector2i(1, 0), 90, clear_context, inventory)["ok"]), "wall occupies the structure layer above a floor")
	var inventory_after_wall := inventory.snapshot()
	_assert_true(not bool(state.place(&"wood_table", Vector2i(1, 0), 0, clear_context, inventory)["ok"]) and inventory.snapshot() == inventory_after_wall, "occupied-layer placement rejects without consuming materials")
	_assert_true(bool(state.place(&"wood_floor", Vector2i(1, 1), 0, clear_context, inventory)["ok"]), "second floor supports a neighboring door")
	_assert_true(bool(state.place(&"wood_door", Vector2i(1, 1), 0, clear_context, inventory)["ok"]), "door placement requires and finds an adjacent wall")
	var door_result := state.toggle_nearest_door(Vector2i(1, 1))
	_assert_true(bool(door_result["ok"]) and bool((door_result["placement"] as Dictionary)["door_open"]), "player door toggles between closed collision and open state")
	_assert_true(bool(state.place(&"basic_roof", Vector2i(1, 0), 180, clear_context, inventory)["ok"]), "roof occupies its independent layer above floor and wall")
	_assert_true(bool(state.place(&"wood_floor", Vector2i(2, 0), 0, clear_context, inventory)["ok"]) and bool(state.place(&"wood_table", Vector2i(2, 0), 270, clear_context, inventory)["ok"]), "basic furniture places on a floor with stable rotation")
	_assert_true(bool(state.place(&"wood_floor", Vector2i(2, 1), 0, clear_context, inventory)["ok"]) and bool(state.place(&"storage_chest", Vector2i(2, 1), 0, clear_context, inventory)["ok"]), "functional storage chest places on a floor")
	_assert_true(bool(state.place(&"placed_torch", Vector2i(3, 0), 0, clear_context, inventory)["ok"]), "placed torch can stand outdoors and consumes its utility item")
	_assert_true(bool(state.place(&"wood_floor", Vector2i(3, 1), 0, clear_context, inventory)["ok"]) and bool(state.place(&"workbench", Vector2i(3, 1), 0, clear_context, inventory)["ok"]), "crafted workbench becomes a placed workstation")
	_assert_true(bool(state.place(&"campfire", Vector2i(4, 0), 0, clear_context, inventory)["ok"]), "crafted campfire becomes an outdoor workstation")
	var nearby_stations := state.nearby_station_ids(Vector2i(3, 1))
	_assert_true(nearby_stations.has(&"workbench") and nearby_stations.has(&"campfire") and state.is_near_heat(Vector2i(3, 0)), "placed workstations and heat sources expose bounded proximity queries")
	var berry_slot := -1
	for index in inventory.slot_count():
		if StringName(inventory.slot(index).get("item_id", "")) == &"berry":
			berry_slot = index
			break
	inventory.select_hotbar(berry_slot)
	var deposit_result := state.interact_nearest_storage(Vector2i(2, 1), inventory)
	_assert_true(bool(deposit_result["ok"]) and inventory.quantity(&"berry") == 0, "selected hotbar stack deposits atomically into the nearby chest")
	var withdraw_result := state.interact_nearest_storage(Vector2i(2, 1), inventory)
	_assert_true(bool(withdraw_result["ok"]) and inventory.quantity(&"berry") == 5, "empty selected slot withdraws stored chest contents without loss")
	var station_inventory := InventoryModel.new()
	station_inventory.add_item(&"branch", 3)
	station_inventory.add_item(&"stone", 5)
	station_inventory.add_item(&"fiber", 2)
	var crafting := CraftingSystem.new(station_inventory)
	crafting.refresh_discoveries()
	_assert_true(not crafting.station_available(&"workbench"), "unplaced and unowned workbench remains unavailable")
	crafting.set_external_stations([&"workbench"])
	_assert_true(crafting.station_available(&"workbench") and crafting.is_unlocked(&"stone_sword"), "nearby placed workstation unlocks its existing recipe family")
	var persisted := state.persistence_snapshot()
	var restored := BuildingState.new(catalog)
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted, "layered buildings, rotation, door and chest state round trip exactly")
	_assert_equal(restored.placements_for_chunk(Vector2i.ZERO).size(), restored.placement_count(), "player buildings partition into their signed chunk difference")
	var count_before_demolition := state.placement_count()
	var wood_before_refund := inventory.quantity(&"wood")
	var demolish_result := state.demolish_at(Vector2i(1, 0), inventory)
	_assert_true(bool(demolish_result["ok"]) and state.placement_count() == count_before_demolition - 1 and inventory.quantity(&"wood") == wood_before_refund + 1, "demolition removes the top layer and atomically refunds configured materials")
	var duplicated := persisted.duplicate(true)
	(duplicated["placements"] as Array).append((duplicated["placements"] as Array)[0])
	_assert_true(not BuildingState.new(catalog).restore_snapshot(duplicated), "building persistence rejects duplicate stable tile-layer IDs")
	var unsupported := persisted.duplicate(true)
	var filtered: Array[Dictionary] = []
	for value in unsupported["placements"] as Array:
		var record := value as Dictionary
		if String(record["placement_id"]) != "surface:1:0:ground":
			filtered.append(record)
	unsupported["placements"] = filtered
	_assert_true(not BuildingState.new(catalog).restore_snapshot(unsupported), "building persistence rejects upper layers without their supporting floor")


func _test_farming_models() -> void:
	var catalog := FarmingCatalog.new()
	_assert_true(catalog.is_valid(), "external farming configuration loads and validates")
	var crop_ids := catalog.crop_ids()
	_assert_true(crop_ids == [&"wheat", &"carrot", &"tomato", &"apple_tree"], "wheat, carrot, tomato and fruit tree use stable data-driven IDs")
	_assert_true(catalog.max_plots() == 4096 and catalog.interaction_range_tiles() == 6, "farming plot and interaction limits are explicit")
	_assert_true(catalog.weather_growth_multiplier(&"RAIN") > catalog.weather_growth_multiplier(&"CLEAR") and catalog.weather_growth_multiplier(&"SNOW") < 1.0 and catalog.weather_growth_multiplier(&"SANDSTORM") < 1.0, "rain accelerates growth while snow and sandstorms slow it")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wheat_seed", 3)
	inventory.add_item(&"apple_sapling", 1)
	inventory.add_item(&"basic_fertilizer", 3)
	var clear_context := {
		"world_layer": &"surface",
		"player_tile": Vector2i.ZERO,
		"player_occupied": false,
		"in_water": false,
		"generated_overlay": false,
		"resource_occupied": false,
		"building_occupied": false,
	}
	var state := FarmingState.new(4242, catalog)
	var water_context := clear_context.duplicate(true)
	water_context["in_water"] = true
	_assert_true(not bool(state.validate_till(Vector2i(1, 0), water_context)["valid"]), "land clearing rejects water")
	var building_context := clear_context.duplicate(true)
	building_context["building_occupied"] = true
	_assert_true(not bool(state.validate_till(Vector2i(1, 0), building_context)["valid"]), "land clearing rejects player buildings")
	var husbandry_context := clear_context.duplicate(true)
	husbandry_context["husbandry_occupied"] = true
	_assert_true(not bool(state.validate_till(Vector2i(1, 0), husbandry_context)["valid"]), "land clearing rejects wild and interacted animal occupancy")
	_assert_true(bool(state.till(Vector2i(1, 0), 1, clear_context)["ok"]), "valid dry surface tile becomes persistent tilled soil")
	var seed_before := inventory.quantity(&"wheat_seed")
	_assert_true(bool(state.plant(&"wheat", Vector2i(1, 0), 1, inventory)["ok"]) and inventory.quantity(&"wheat_seed") == seed_before - 1, "sowing atomically consumes exactly one selected crop seed")
	_assert_true(bool(state.fertilize(Vector2i(1, 0), &"basic_fertilizer", inventory)["ok"]), "basic fertilizer attaches one bounded growth and quality bonus")
	for day in range(1, 5):
		_assert_true(bool(state.water(Vector2i(1, 0), day)["ok"]), "crop accepts one watering on care day %d" % day)
		state.advance_to_day(day + 1, &"CLEAR")
	var mature_wheat := state.plot_at(Vector2i(1, 0))
	_assert_true(bool(mature_wheat["mature"]) and int(mature_wheat["stage"]) == 3, "watered crop advances through every stage to maturity")
	var harvest := state.harvest(Vector2i(1, 0), 5, inventory)
	_assert_true(bool(harvest["ok"]) and String(harvest["quality"]) == "gold" and String(harvest["item_id"]) == "gold_wheat", "care and fertilizer deterministically produce a gold-quality harvest item")
	_assert_true(inventory.quantity(&"gold_wheat") == int(harvest["quantity"]) and String(state.plot_at(Vector2i(1, 0))["crop_id"]).is_empty(), "annual harvest transfers exact produce and preserves reusable tilled soil")
	_assert_true(bool(state.till(Vector2i(2, 0), 1, clear_context)["ok"]) and bool(state.plant(&"apple_tree", Vector2i(2, 0), 1, inventory)["ok"]), "fruit-tree sapling plants on a separate tilled plot")
	var rain_result := state.advance_to_day(9, &"RAIN")
	_assert_true(bool(rain_result["changed"]) and bool(state.plot_at(Vector2i(2, 0))["mature"]), "rain automatically waters and matures a fruit tree across elapsed days")
	var apple_harvest := state.harvest(Vector2i(2, 0), 9, inventory)
	var regrowing_tree := state.plot_at(Vector2i(2, 0))
	_assert_true(bool(apple_harvest["ok"]) and bool(apple_harvest["regrows"]) and String(regrowing_tree["crop_id"]) == "apple_tree" and not bool(regrowing_tree["mature"]), "fruit tree remains planted and enters its configured regrowth cycle after harvest")
	var dry_state := FarmingState.new(9, catalog)
	var rain_state := FarmingState.new(9, catalog)
	for comparison_state in [dry_state, rain_state]:
		comparison_state.till(Vector2i(3, 0), 1, clear_context)
		var comparison_inventory := InventoryModel.new()
		comparison_inventory.add_item(&"wheat_seed", 1)
		comparison_state.plant(&"wheat", Vector2i(3, 0), 1, comparison_inventory)
	dry_state.advance_to_day(3, &"SNOW")
	rain_state.advance_to_day(3, &"RAIN")
	_assert_true(float(rain_state.plot_at(Vector2i(3, 0))["growth_points"]) > float(dry_state.plot_at(Vector2i(3, 0))["growth_points"]), "weather effects materially change crop growth without global randomness")
	var persisted := state.persistence_snapshot()
	var restored := FarmingState.new(4242, catalog)
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted, "tilled soil, stages, water, fertilizer, quality inputs and fruit-tree regrowth round trip exactly")
	_assert_equal(restored.plots_for_chunk(Vector2i.ZERO).size(), restored.plot_count(), "farming plots partition into their signed owning chunk")
	var duplicated := persisted.duplicate(true)
	(duplicated["plots"] as Array).append((duplicated["plots"] as Array)[0])
	_assert_true(not FarmingState.new(4242, catalog).restore_snapshot(duplicated), "farming persistence rejects duplicate stable plot IDs")


func _test_husbandry_models() -> void:
	var catalog := HusbandryCatalog.new()
	_assert_true(catalog.is_valid(), "external husbandry configuration loads and validates")
	_assert_true(catalog.animal_ids() == [&"chicken", &"cow", &"sheep"], "chicken, cow and sheep use stable data-driven IDs")
	_assert_true(catalog.max_interacted_animals() == 256 and catalog.interaction_range_tiles() == 6 and catalog.breeding_range_tiles() == 4 and catalog.fence_radius_tiles() == 4, "husbandry population, interaction, breeding and fence limits are explicit")
	_assert_true(catalog.is_sleep_phase(&"NIGHT") and not catalog.is_sleep_phase(&"DAY") and catalog.feed_reserve_days() == 2, "night sleep and the inactive-chunk feed reserve are data-driven")
	var seed := WorldSeed.from_text("V3.4-husbandry-models")
	var terrain := TerrainGenerator.new(seed)
	var planner := HusbandryPlanner.new(seed, catalog)
	var repeated_planner := HusbandryPlanner.new(seed, catalog)
	var planned_candidates: Array[Dictionary] = []
	var planned_chunk: ChunkData
	for chunk_y in range(-4, 5):
		for chunk_x in range(-4, 5):
			var chunk := terrain.generate_chunk(Vector2i(chunk_x, chunk_y))
			var candidates := planner.candidates_for_chunk(chunk)
			if not candidates.is_empty():
				planned_candidates = candidates
				planned_chunk = chunk
				break
		if not planned_candidates.is_empty():
			break
	_assert_true(not planned_candidates.is_empty(), "deterministic surface scan finds at least one biome-compatible wild animal")
	if planned_chunk != null:
		_assert_equal(planned_candidates, repeated_planner.candidates_for_chunk(planned_chunk), "wild animal identity, species, sex and tile repeat exactly for one world seed")
		var planned_tiles := {}
		var dry_and_unique := true
		for candidate in planned_candidates:
			var tile_value := candidate["world_tile"] as Array
			var world_tile := Vector2i(int(tile_value[0]), int(tile_value[1]))
			var local := WorldCoordinates.tile_to_local(world_tile)
			var tile_key := "%d:%d" % [world_tile.x, world_tile.y]
			dry_and_unique = dry_and_unique and not planned_tiles.has(tile_key) \
					and not HydrologyGenerator.is_water(planned_chunk.water_feature_at(local)) \
					and not planned_chunk.has_built_overlay_at(local)
			planned_tiles[tile_key] = true
		_assert_true(dry_and_unique, "wild animal planning avoids water, generated structures and duplicate tiles")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wheat_seed", 20)
	var state := HusbandryState.new(seed, catalog)
	var female := {"animal_id": "wild:test:female", "animal_type": "chicken", "world_tile": [1, 0], "sex": "female", "wild": true}
	var male := {"animal_id": "wild:test:male", "animal_type": "chicken", "world_tile": [3, 0], "sex": "male", "wild": true}
	_assert_true(bool(state.feed_candidate(female, 1, inventory)["ok"]) and bool(state.feed_candidate(male, 1, inventory)["ok"]), "first feed records two stable wild-animal interactions and consumes exact feed")
	var same_day_inventory := inventory.snapshot()
	_assert_true(not bool(state.feed("wild:test:female", 1, inventory)["ok"]) and inventory.snapshot() == same_day_inventory, "same-day duplicate feeding is rejected without consuming feed")
	state.advance_to_day(2)
	_assert_true(bool(state.feed("wild:test:female", 2, inventory)["tamed_now"]) and bool(state.feed("wild:test:male", 2, inventory)["tamed_now"]) and state.tamed_count() == 2, "configured daily feeding threshold tames both animals exactly once")
	state.advance_to_day(3)
	state.feed("wild:test:female", 3, inventory)
	state.feed("wild:test:male", 3, inventory)
	_assert_true(String(state.compatible_partner("wild:test:female").get("animal_id", "")) == "wild:test:male", "nearby tamed same-species opposite-sex animal resolves as a breeding partner")
	var sleeping := state.set_sleep_phase(&"NIGHT")
	_assert_true(bool(sleeping["changed"]) and state.sleeping_count() == 2, "night transition sleeps every tamed animal")
	state.set_sleep_phase(&"DAY")
	_assert_true(state.sleeping_count() == 0, "day transition wakes every sleeping animal")
	var breed_result := state.breed("wild:test:female", "wild:test:male", Vector2i(2, 1), 3, true)
	_assert_true(bool(breed_result["ok"]) and state.animal_count() == 3 and bool((breed_result["animal"] as Dictionary)["tamed"]) and int((breed_result["animal"] as Dictionary)["adult_day"]) == 5, "fenced compatible parents create one persistent tamed juvenile with a bounded growth day")
	var inactive_result := state.advance_to_day(5)
	_assert_true(bool(inactive_result["changed"]) and int(inactive_result["produced"]) > 0 and state.ready_product_count() > 0, "elapsed days simulate animal products while owning chunks are inactive")
	var ready_before := state.ready_product_count()
	var collect_result := state.collect_product("wild:test:female", inventory)
	_assert_true(bool(collect_result["ok"]) and String(collect_result["item_id"]) == "egg" and inventory.quantity(&"egg") == int(collect_result["quantity"]) and state.ready_product_count() < ready_before, "product collection transfers the exact configured item stack and clears only that animal")
	var persisted := state.persistence_snapshot()
	var restored := HusbandryState.new(seed, catalog)
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted, "taming, friendship, feed reserve, products, sleep, cooldown and juvenile growth round trip exactly")
	_assert_equal(restored.animals_for_chunk(Vector2i.ZERO).size(), restored.animal_count(), "interacted animals partition into their signed owning chunk")
	var duplicated := persisted.duplicate(true)
	(duplicated["animals"] as Array).append((duplicated["animals"] as Array)[0])
	_assert_true(not HusbandryState.new(seed, catalog).restore_snapshot(duplicated), "husbandry persistence rejects duplicate stable animal IDs and occupied tiles")


func _test_processing_models() -> void:
	var catalog := ProcessingCatalog.new()
	_assert_true(catalog.is_valid(), "external cooking and refining configuration loads and validates")
	_assert_true(catalog.station_ids() == [&"cooking_pot", &"smelter"] and catalog.recipes().size() == 10, "cooking pot, smelter and ten multi-material processing recipes are data-driven")
	_assert_true(catalog.fuel_units(&"coal") == 6 and catalog.fuel_units(&"wood") == 2 and catalog.interaction_radius_tiles() == 3, "wood and coal expose explicit fuel values inside a bounded station radius")
	var inventory := InventoryModel.new()
	for entry in [
		[&"wood", 20], [&"cooking_pot", 1], [&"smelter", 1], [&"coal", 3],
		[&"carrot", 1], [&"tomato", 1], [&"milk", 1], [&"copper_ore", 6],
	]:
		inventory.add_item(entry[0] as StringName, int(entry[1]))
	var buildings := BuildingState.new()
	var context := {
		"world_layer": &"surface", "player_tile": Vector2i.ZERO, "player_occupied": false,
		"in_water": false, "generated_overlay": false, "resource_occupied": false,
		"farming_occupied": false, "husbandry_occupied": false,
	}
	_assert_true(bool(buildings.place(&"wood_floor", Vector2i(1, 0), 0, context, inventory)["ok"]) and bool(buildings.place(&"cooking_pot", Vector2i(1, 0), 0, context, inventory)["ok"]), "crafted cooking pot places on a supported building tile")
	_assert_true(bool(buildings.place(&"wood_floor", Vector2i(2, 0), 0, context, inventory)["ok"]) and bool(buildings.place(&"smelter", Vector2i(2, 0), 90, context, inventory)["ok"]), "crafted smelter places with stable rotation and empty fuel state")
	var processing := ProcessingSystem.new(inventory, buildings, catalog)
	var pot_fuel := processing.add_fuel(&"cooking_pot", &"wood", Vector2i.ZERO)
	_assert_true(bool(pot_fuel["ok"]) and int(buildings.nearest_processor(Vector2i.ZERO, &"cooking_pot", 3)["fuel_units"]) == 2, "one wood item atomically supplies two persistent cooking fuel units")
	var stew_result := processing.process(&"vegetable_stew", Vector2i.ZERO)
	var pot_after := buildings.nearest_processor(Vector2i.ZERO, &"cooking_pot", 3)
	_assert_true(bool(stew_result["ok"]) and inventory.quantity(&"vegetable_stew") == 1 and inventory.quantity(&"carrot") == 0 and int(pot_after["fuel_units"]) == 0 and int(pot_after["processed_count"]) == 1, "multi-material meal transaction consumes exact inputs and fuel while producing one food")
	var smelter_fuel := processing.add_fuel(&"smelter", &"coal", Vector2i.ZERO)
	var ingot_result := processing.process(&"copper_ingot", Vector2i.ZERO)
	_assert_true(bool(smelter_fuel["ok"]) and bool(ingot_result["ok"]) and inventory.quantity(&"copper_ore") == 3 and inventory.quantity(&"copper_ingot") == 2 and int(buildings.nearest_processor(Vector2i.ZERO, &"smelter", 3)["fuel_units"]) == 4, "coal fuels ore-to-ingot refining with exact output and retained fuel")
	var inventory_before_failure := inventory.snapshot()
	var buildings_before_failure := buildings.persistence_snapshot()
	var failed_steel := processing.process(&"steel_ingot", Vector2i.ZERO)
	_assert_true(not bool(failed_steel["ok"]) and inventory.snapshot() == inventory_before_failure and buildings.persistence_snapshot() == buildings_before_failure, "missing processing materials leave both inventory and station fuel unchanged")
	var view := processing.state_snapshot(Vector2i.ZERO)
	_assert_true((view["stations"] as Array).size() == 2 and (view["recipes"] as Array).size() == 10 and (view["fuels"] as Array).size() == 2, "processing presentation snapshot exposes stations, recipes, fuel and current inventory quantities")
	var persisted := buildings.persistence_snapshot()
	var restored := BuildingState.new()
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted and int(restored.nearest_processor(Vector2i.ZERO, &"smelter", 3)["fuel_units"]) == 4, "processor fuel and completed-operation count round trip inside chunk-owned building records")
	var demolish_inventory := inventory.snapshot()
	_assert_true(not bool(buildings.demolish_at(Vector2i(2, 0), inventory)["ok"]) and inventory.snapshot() == demolish_inventory, "fueled processor cannot be demolished and lose retained energy")
	var invalid := persisted.duplicate(true)
	(invalid["placements"] as Array)[0]["fuel_units"] = 1
	_assert_true(not BuildingState.new().restore_snapshot(invalid), "non-processor building records reject injected fuel fields")


func _test_equipment_models() -> void:
	var catalog := EquipmentCatalog.new()
	_assert_true(catalog.is_valid(), "external equipment configuration loads and validates")
	_assert_equal(catalog.slot_ids(), [&"weapon", &"helmet", &"chest", &"boots", &"accessory_1", &"accessory_2"], "equipment exposes one weapon, three armor and two accessory slots")
	_assert_true(catalog.quality_ids().size() == 4 and catalog.rarity_ids().size() == 4 and catalog.affix_ids().size() == 5, "quality, rarity and random-affix pools are data-driven")
	_assert_true(catalog.equipment_item_ids().size() == 9 and catalog.maximum_enhancement() == 5, "nine equipment definitions and five enhancement levels are validated")
	var inventory := InventoryModel.new()
	for item_id in [&"copper_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots", &"explorer_charm"]:
		inventory.add_item(item_id, 1)
	inventory.add_item(&"tempered_plate", 4)
	inventory.add_item(&"iron_ingot", 10)
	var state := EquipmentState.new(catalog)
	for item_id in [&"copper_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots", &"explorer_charm"]:
		var slot_index := _find_item_slot(inventory, item_id)
		_assert_true(bool(state.import_inventory_slot(inventory, slot_index, 3606)["ok"]), "equipment import registers one stable %s instance" % item_id)
	_assert_true(state.records().size() == 5 and inventory.quantity(&"copper_sword") == 0, "equipment registration transfers items without duplication")
	var before_stats := state.stats_snapshot()
	_assert_true(float(before_stats["defense"]) >= 10.0 and float(before_stats["attack"]) >= 7.0 and ((before_stats["sets"] as Array)[0] as Dictionary)["pieces"] == 3, "three copper armor pieces activate exact set bonuses")
	var weapon := state.equipped_record(&"weapon")
	var weapon_id := int(weapon["instance_id"])
	var plates_before := inventory.quantity(&"tempered_plate")
	var enhance := state.enhance(weapon_id, inventory)
	_assert_true(bool(enhance["ok"]) and int(state.record(weapon_id)["enhance_level"]) == 1 and inventory.quantity(&"tempered_plate") == plates_before - 1, "enhancement consumes its exact material and raises one persistent level")
	var attack_after := float(state.stats_snapshot()["attack"])
	_assert_true(attack_after > float(before_stats["attack"]), "enhancement increases the composed equipment attack stat")
	var damaged := state.damage_equipped_weapon(37)
	var iron_before := inventory.quantity(&"iron_ingot")
	var repair := state.repair(weapon_id, inventory)
	_assert_true(bool(damaged["accepted"]) and bool(repair["ok"]) and int(state.record(weapon_id)["durability"]) == state.maximum_durability(state.record(weapon_id)) and inventory.quantity(&"iron_ingot") < iron_before, "repair consumes exact ingots and restores affix-aware maximum durability")
	var charm := state.records().back() as Dictionary
	var comparison := state.comparison(int(charm["instance_id"]))
	_assert_true(comparison.has("attack_delta") and comparison.has("defense_delta"), "candidate comparison reports signed stat differences against its active slot")
	var snapshot := state.persistence_snapshot()
	var restored := EquipmentState.new(catalog)
	_assert_true(restored.restore_snapshot(snapshot) and restored.persistence_snapshot() == snapshot, "equipment instances, slots, qualities, rarities, affixes, reinforcement and durability round trip exactly")
	var invalid := snapshot.duplicate(true)
	(invalid["equipped"] as Dictionary)["helmet"] = int((invalid["equipped"] as Dictionary)["weapon"])
	_assert_true(not EquipmentState.new(catalog).restore_snapshot(invalid), "one equipment instance cannot occupy multiple or mismatched slots")


func _test_automation_models() -> void:
	var catalog := AutomationCatalog.new()
	_assert_true(catalog.is_valid(), "external automation configuration loads and validates")
	_assert_equal(catalog.machine_piece_ids(), [&"conveyor_belt", &"automatic_smelter", &"storage_link", &"item_sorter"], "conveyor, automatic smelter, storage link and sorter use stable machine IDs")
	_assert_true(catalog.tick_seconds() == 5.0 and catalog.connection_span_tiles() == 12 and catalog.max_machines() == 128, "automation cadence, connection span and machine cap are explicit")
	_assert_true(catalog.max_operations_per_advance() == 64 and catalog.max_offline_ticks() == 720, "automation operations and offline catch-up have hard performance limits")
	_assert_equal(catalog.automatic_recipe_ids(), [&"copper_ingot", &"iron_ingot", &"steel_ingot", &"tempered_plate"], "automatic smelter recipes reuse the four validated refining transactions")
	_assert_true(catalog.sortable_item_ids().has(&"coal") and catalog.sortable_item_ids().has(&"tempered_plate"), "sorter filters expose bounded data-driven material IDs")

	var conveyor_state := BuildingState.new()
	_assert_true(conveyor_state.restore_snapshot(_automation_line_snapshot(&"conveyor_belt", [{"item_id": "stone", "quantity": 3}])), "conveyor line fixture validates with two connected storage chests")
	var conveyor := AutomationSystem.new(conveyor_state, catalog)
	_assert_true(bool(conveyor.advance_to(0.0)["ok"]), "first automation update initializes a stable time cursor")
	var conveyor_tick := conveyor.advance_to(5.0)
	var conveyor_source := conveyor_state.placement("surface:0:0:structure")
	var conveyor_target := conveyor_state.placement("surface:2:0:structure")
	_assert_true(bool(conveyor_tick["ok"]) and int(conveyor_tick["operations"]) == 1 and _storage_quantity_for_test(conveyor_source, &"stone") == 2 and _storage_quantity_for_test(conveyor_target, &"stone") == 1, "one conveyor tick transfers exactly one item in its rotation direction")
	_assert_true(int(conveyor_state.placement("surface:1:0:structure")["automation_cycles"]) == 1 and String(conveyor_state.placement("surface:1:0:structure")["automation_status"]) == "working", "machine work state and completed cycles persist on the building record")
	var conveyor_view := conveyor.state_snapshot(Vector2i.ZERO)
	_assert_true(int(conveyor_view["machine_count"]) == 1 and String(((conveyor_view["machines"] as Array)[0] as Dictionary)["status_name"]) == "工作中", "automation presentation reports machine capacity and localized live status")
	var disabled := conveyor.toggle_machine("surface:1:0:structure")
	var disabled_source_before := conveyor_state.placement("surface:0:0:structure")
	var disabled_target_before := conveyor_state.placement("surface:2:0:structure")
	var disabled_cycles_before := int(conveyor_state.placement("surface:1:0:structure")["automation_cycles"])
	conveyor.advance_to(10.0)
	_assert_true(bool(disabled["ok"]) and not bool(conveyor_state.placement("surface:1:0:structure")["automation_enabled"]) and conveyor_state.placement("surface:0:0:structure") == disabled_source_before and conveyor_state.placement("surface:2:0:structure") == disabled_target_before and int(conveyor_state.placement("surface:1:0:structure")["automation_cycles"]) == disabled_cycles_before, "disabled machines preserve storage and completed cycles across later ticks")

	var link_state := BuildingState.new()
	_assert_true(link_state.restore_snapshot(_automation_line_snapshot(&"storage_link", [{"item_id": "copper_ore", "quantity": 7}])), "automatic storage-link fixture validates")
	var link := AutomationSystem.new(link_state, catalog)
	link.advance_to(0.0)
	link.advance_to(5.0)
	_assert_true(_storage_quantity_for_test(link_state.placement("surface:0:0:structure"), &"copper_ore") == 3 and _storage_quantity_for_test(link_state.placement("surface:2:0:structure"), &"copper_ore") == 4, "storage connector moves its exact four-item throughput between linked chests")

	var sorter_snapshot := _automation_line_snapshot(&"item_sorter", [
		{"item_id": "iron_ore", "quantity": 2},
		{"item_id": "copper_ore", "quantity": 2},
	])
	var sorter_state := BuildingState.new()
	_assert_true(sorter_state.restore_snapshot(sorter_snapshot), "sorter fixture validates with mixed source storage")
	var sorter := AutomationSystem.new(sorter_state, catalog)
	var filter_result := sorter.cycle_filter("surface:1:0:structure")
	sorter.advance_to(0.0)
	sorter.advance_to(5.0)
	_assert_true(bool(filter_result["ok"]) and StringName(sorter_state.placement("surface:1:0:structure")["sort_filter_item_id"]) == &"copper_ore", "sorter filter cycles through the bounded material list")
	_assert_true(_storage_quantity_for_test(sorter_state.placement("surface:0:0:structure"), &"iron_ore") == 2 and _storage_quantity_for_test(sorter_state.placement("surface:2:0:structure"), &"copper_ore") == 2, "sorter transfers only its selected item and leaves unlike input untouched")

	var smelter_state := BuildingState.new()
	_assert_true(smelter_state.restore_snapshot(_automation_line_snapshot(&"automatic_smelter", [
		{"item_id": "copper_ore", "quantity": 3},
		{"item_id": "coal", "quantity": 1},
	])), "automatic-smelter fixture validates with input and fuel storage")
	var smelter := AutomationSystem.new(smelter_state, catalog)
	smelter.advance_to(0.0)
	var smelt_tick := smelter.advance_to(5.0)
	var smelter_record := smelter_state.placement("surface:1:0:structure")
	_assert_true(bool(smelt_tick["ok"]) and _storage_quantity_for_test(smelter_state.placement("surface:0:0:structure"), &"copper_ore") == 0 and _storage_quantity_for_test(smelter_state.placement("surface:2:0:structure"), &"copper_ingot") == 2, "automatic smelter pulls exact recipe inputs and pushes exact output to connected storage")
	_assert_true(int(smelter_record["automation_fuel_units"]) == 4 and int(smelter_record["automation_cycles"]) == 1, "automatic smelter refuels from coal, consumes energy and retains four fuel units")
	var recipe_result := smelter.cycle_recipe("surface:1:0:structure")
	_assert_true(bool(recipe_result["ok"]) and StringName(smelter_state.placement("surface:1:0:structure")["automation_recipe_id"]) == &"iron_ingot", "automatic smelter recipe selection cycles and persists")
	var smelter_before_demolition := smelter_state.persistence_snapshot()
	_assert_true(not bool(smelter_state.demolish_at(Vector2i(1, 0), InventoryModel.new())["ok"]) and smelter_state.persistence_snapshot() == smelter_before_demolition, "fueled automatic smelter cannot be demolished and lose retained energy")

	var offline_state := BuildingState.new()
	_assert_true(offline_state.restore_snapshot(_automation_line_snapshot(&"conveyor_belt", [])), "offline automation fixture validates without loaded input")
	var offline := AutomationSystem.new(offline_state, catalog)
	offline.advance_to(0.0)
	var offline_result := offline.advance_to(5000.0)
	_assert_true(int(offline_result["simulated_ticks"]) == catalog.max_offline_ticks() and int(offline_result["discarded_ticks"]) == 280, "unloaded-chunk automation catches up only the bounded offline tick window")

	var packed_storage: Array[Dictionary] = []
	for _slot in BuildingCatalog.new().chest_slot_count():
		packed_storage.append({"item_id": "stone", "quantity": 50})
	var throttled_state := BuildingState.new()
	_assert_true(throttled_state.restore_snapshot(_automation_line_snapshot(&"storage_link", packed_storage)), "performance-limit fixture validates a full source chest")
	var throttled := AutomationSystem.new(throttled_state, catalog)
	throttled.advance_to(0.0)
	var throttled_result := throttled.advance_to(500.0)
	_assert_true(int(throttled_result["operations"]) == catalog.max_operations_per_advance() and String(throttled_state.placement("surface:1:0:structure")["automation_status"]) == "throttled", "one advance never exceeds the global automation operation budget")

	var persisted := sorter_state.persistence_snapshot()
	var restored := BuildingState.new()
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted, "automation enablement, time cursor, cycles, status and sorter filter round trip exactly")
	var invalid_filter := persisted.duplicate(true)
	for value in invalid_filter["placements"] as Array:
		var record := value as Dictionary
		if String(record.get("piece_id", "")) == "item_sorter":
			record["sort_filter_item_id"] = "unknown_item"
	_assert_true(not BuildingState.new().restore_snapshot(invalid_filter), "automation persistence rejects an unknown sorter filter")
	var injected := persisted.duplicate(true)
	(injected["placements"] as Array)[0]["automation_enabled"] = true
	_assert_true(not BuildingState.new().restore_snapshot(injected), "non-automation building records reject injected machine state")


func _test_homestead_models() -> void:
	var catalog := HomesteadCatalog.new()
	_assert_true(catalog.is_valid(), "external homestead configuration loads and validates")
	_assert_true(catalog.marker_piece_id() == &"homestead_beacon" and catalog.base_radius_tiles() == 24 and catalog.max_bases() == 3, "homestead marker, management radius and base limit are explicit")
	_assert_true(catalog.minimum_spacing_tiles() == 32 and catalog.teleport_cooldown_seconds() == 120.0, "base spacing and home-teleport cooldown are bounded data")
	var placements: Array[Dictionary] = [
		{"placement_id": "surface:0:0:structure", "piece_id": "homestead_beacon", "world_tile": [0, 0], "rotation": 0},
		{"placement_id": "surface:40:0:structure", "piece_id": "homestead_beacon", "world_tile": [40, 0], "rotation": 0},
	]
	for x in range(1, 7):
		placements.append({"placement_id": "surface:%d:0:ground" % x, "piece_id": "wood_floor", "world_tile": [x, 0], "rotation": 0})
	placements.append_array([
		{"placement_id": "surface:1:0:structure", "piece_id": "wood_wall", "world_tile": [1, 0], "rotation": 0},
		{"placement_id": "surface:1:0:roof", "piece_id": "basic_roof", "world_tile": [1, 0], "rotation": 0},
		{"placement_id": "surface:2:0:structure", "piece_id": "storage_chest", "world_tile": [2, 0], "rotation": 0, "storage": [{"item_id": "stone", "quantity": 5}]},
		{"placement_id": "surface:3:0:structure", "piece_id": "cooking_pot", "world_tile": [3, 0], "rotation": 0, "fuel_units": 0, "processed_count": 1},
		{"placement_id": "surface:4:0:structure", "piece_id": "smelter", "world_tile": [4, 0], "rotation": 0, "fuel_units": 0, "processed_count": 1},
		{"placement_id": "surface:5:0:structure", "piece_id": "workbench", "world_tile": [5, 0], "rotation": 0},
		{"placement_id": "surface:6:0:structure", "piece_id": "conveyor_belt", "world_tile": [6, 0], "rotation": 90, "automation_enabled": true, "automation_last_seconds": 10.0, "automation_cycles": 2, "automation_status": "working"},
	])
	var buildings := BuildingState.new()
	_assert_true(buildings.restore_snapshot({"schema_version": BuildingState.SCHEMA_VERSION, "placements": placements}) and buildings.homestead_marker_count() == 2, "building state validates two spaced homestead beacons and keeps a constant-time count")
	var farming := FarmingState.new(4000)
	var farm_context := {"world_layer": &"surface", "player_tile": Vector2i(7, 0), "player_occupied": false, "in_water": false, "generated_overlay": false, "resource_occupied": false, "building_occupied": false, "husbandry_occupied": false}
	_assert_true(bool(farming.till(Vector2i(7, 0), 1, farm_context)["ok"]), "homestead coverage fixture creates a managed farm plot")
	var husbandry := HusbandryState.new(4000)
	var feed_inventory := InventoryModel.new()
	feed_inventory.add_item(&"wheat_seed", 2)
	var candidate := {"animal_id": "wild:homestead:chicken", "animal_type": "chicken", "world_tile": [8, 0], "sex": "female", "wild": true}
	_assert_true(bool(husbandry.feed_candidate(candidate, 1, feed_inventory)["ok"]) and bool(husbandry.feed("wild:homestead:chicken", 2, feed_inventory)["tamed_now"]), "homestead coverage fixture creates one tamed animal")
	var state := HomesteadState.new(catalog)
	var sync := state.synchronize_markers(buildings, 10.0)
	_assert_true(bool(sync["ok"]) and int(sync["base_count"]) == 2 and not state.active_base_id().is_empty(), "beacon synchronization establishes stable bases and selects the first home")
	var first_base_id := String(state.bases()[0]["base_id"])
	var second_base_id := String(state.bases()[1]["base_id"])
	var status := state.status_snapshot(buildings, farming, husbandry, 20.0, Vector2i(6, 0), &"surface")
	var first_view := (status["bases"] as Array)[0] as Dictionary
	_assert_true(String(status["inside_base_id"]) == first_base_id and bool(first_view["loop_complete"]) and int(first_view["completed_steps"]) == 8, "base management assigns nearby assets once and completes the eight-part survival-building loop")
	_assert_true(int((first_view["assets"] as Dictionary)["stored_items"]) == 5 and int((first_view["assets"] as Dictionary)["farm_plots"]) == 1 and int((first_view["assets"] as Dictionary)["tamed_animals"]) == 1 and int((first_view["assets"] as Dictionary)["automation_machines"]) == 1, "base overview composes storage, agriculture, husbandry and automation counts")
	_assert_true(bool(state.set_active_home(second_base_id)["ok"]), "any established base can become the active home")
	var plan := state.teleport_plan(100.0, &"surface", Vector2i.ZERO)
	_assert_true(bool(plan["ok"]) and (plan["world_tile"] as Array) == [40, 0] and state.commit_home_teleport(100.0), "active home exposes an exact surface teleport target and commits only after travel succeeds")
	var cooldown_plan := state.teleport_plan(150.0, &"underground", Vector2i.ZERO)
	_assert_true(not bool(cooldown_plan["ok"]) and ceili(state.cooldown_remaining(150.0)) == 70, "home teleport enforces its persisted game-time cooldown across world layers")
	_assert_true(not bool(state.teleport_plan(300.0, &"dungeon", Vector2i.ZERO)["ok"]), "dungeon runs cannot be escaped through home teleport")
	var persisted := state.persistence_snapshot()
	var restored := HomesteadState.new(catalog)
	_assert_true(restored.restore_snapshot(persisted, buildings) and restored.persistence_snapshot() == persisted, "base names, active home, establishment time and teleport cooldown round trip exactly")
	var mismatched := persisted.duplicate(true)
	((mismatched["bases"] as Array)[0] as Dictionary)["world_tile"] = [1, 1]
	_assert_true(not HomesteadState.new(catalog).restore_snapshot(mismatched, buildings), "homestead persistence rejects a base that does not match its chunk-owned beacon")
	var invalid_spacing := {"schema_version": BuildingState.SCHEMA_VERSION, "placements": [
		{"placement_id": "surface:0:0:structure", "piece_id": "homestead_beacon", "world_tile": [0, 0], "rotation": 0},
		{"placement_id": "surface:10:0:structure", "piece_id": "homestead_beacon", "world_tile": [10, 0], "rotation": 0},
	]}
	_assert_true(not BuildingState.new().restore_snapshot(invalid_spacing), "building persistence rejects overlapping base-marker ranges below minimum spacing")


func _test_ocean_models() -> void:
	var ocean_catalog := OceanCatalog.new()
	_assert_true(ocean_catalog.is_valid(), "external ocean configuration loads and validates")
	_assert_true(ocean_catalog.shallow_water_multiplier() < 1.0 and ocean_catalog.deep_water_multiplier() < ocean_catalog.shallow_water_multiplier(), "ocean swimming slows shallow and deep water at bounded data rates")
	var boat_definition := ocean_catalog.boat_for_item(&"rowboat")
	_assert_true(not boat_definition.is_empty() and is_equal_approx(float(boat_definition["speed_multiplier"]), 1.65) and int(boat_definition["maximum_count"]) == 16 and int(boat_definition["deploy_range_tiles"]) == 2, "rowboat exposes explicit speed, deployment cap and range")
	_assert_true(ocean_catalog.boat_for_item(&"wood").is_empty(), "non-boat items resolve no ocean boat definition")
	var biome_catalog := BiomeCatalog.new()
	_assert_true(biome_catalog.has_biome(&"island") and biome_catalog.biome_count() == 13, "island biome extends the data-driven biome catalog")
	_assert_equal(biome_catalog.classify_land(0.50, 0.50, 0.44, 0.50, 0.90), biome_catalog.code_for_id(&"island"), "high island mask with coastal elevation classifies the island biome")
	_assert_equal(biome_catalog.classify_land(0.50, 0.50, 0.44, 0.50, 0.30), biome_catalog.code_for_id(&"plains"), "low island mask keeps the existing land classification")
	_assert_equal(biome_catalog.classify_land(0.50, 0.50, 0.44, 0.50), biome_catalog.code_for_id(&"plains"), "callers without an island signal keep the exact V4.0 classification")
	_assert_equal(biome_catalog.classify_land(0.50, 0.50, 0.535, 0.50, 0.90), biome_catalog.code_for_id(&"coast"), "island biome fades into the coast across its transition band")
	var resource_catalog := ResourceCatalog.new()
	_assert_true(resource_catalog.is_valid(), "resource catalog validates the four ocean resources")
	_assert_equal(resource_catalog.water_candidate_code(ChunkData.Terrain.SHALLOW_WATER, 0.0, &"ocean"), resource_catalog.code_for_id(&"kelp"), "shallow ocean cells rank kelp first on the water channel")
	_assert_true(resource_catalog.water_candidate_code(ChunkData.Terrain.SHALLOW_WATER, 0.99, &"plains") == -1, "land biomes never rank water resources")
	_assert_true(resource_catalog.water_candidate_code(ChunkData.Terrain.DEEP_WATER, 0.0, &"ocean") == resource_catalog.code_for_id(&"driftwood_log"), "deep ocean rejects shallow-only resources and ranks driftwood first")
	var boat_state := BoatState.new(ocean_catalog)
	_assert_true(not boat_state.can_deploy(&"wood"), "boat deployment rejects non-boat items")
	var first_boat := boat_state.deploy(Vector2i(-90, 40), &"rowboat")
	_assert_true(not first_boat.is_empty() and String(first_boat["boat_id"]) == "surface:-90:40", "deploying a boat mints a tile-qualified stable record")
	_assert_true(boat_state.deploy(Vector2i(-90, 40), &"rowboat").is_empty(), "one water tile hosts at most one deployed boat")
	_assert_true(not boat_state.boat_at(Vector2i(-90, 40)).is_empty() and boat_state.boat_at(Vector2i(-90, 41)).is_empty(), "boat lookups resolve only the exact tile")
	_assert_true(bool(boat_state.relocate("surface:-90:40", Vector2i(-95, 45))) and boat_state.boat_at(Vector2i(-95, 45)).is_empty() == false and boat_state.boat_at(Vector2i(-90, 40)).is_empty(), "mooring relocates the boat identity to its final water tile")
	var removed := boat_state.remove_at(Vector2i(-95, 45))
	_assert_true(not removed.is_empty() and boat_state.boat_count() == 0, "retrieving a boat removes exactly one record and returns its item payload")
	for index in 16:
		_assert_true(not boat_state.deploy(Vector2i(-100 + index, 40), &"rowboat").is_empty(), "boat fixtures fill the deployment cap")
	_assert_true(not boat_state.can_deploy(&"rowboat") and boat_state.deploy(Vector2i(-200, 40), &"rowboat").is_empty(), "the sixteenth boat enforces the global deployment cap")
	var persisted := boat_state.persistence_snapshot()
	var restored := BoatState.new(ocean_catalog)
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted, "boat persistence round trips exactly")
	var tampered := persisted.duplicate(true)
	((tampered["boats"] as Array)[0] as Dictionary)["boat_id"] = "surface:0:0"
	_assert_true(not BoatState.new(ocean_catalog).restore_snapshot(tampered), "boat persistence rejects a record whose ID does not match its tile")
	var survival_oxygen := SurvivalState.new()
	survival_oxygen.update(10.0, {"world_layer": "surface", "in_deep_water": true})
	_assert_true(survival_oxygen.oxygen < 100.0 and not survival_oxygen.has_effect(&"drowning"), "deep water drains oxygen without instant drowning")
	survival_oxygen.update(30.0, {"world_layer": "surface", "in_deep_water": true})
	_assert_true(is_equal_approx(survival_oxygen.oxygen, 0.0) and survival_oxygen.has_effect(&"drowning"), "empty oxygen applies the data-driven drowning effect")
	var drowning_damage := survival_oxygen.update(2.0, {"world_layer": "surface", "in_deep_water": true})
	_assert_true(float(drowning_damage["damage"]) > 0.0, "drowning deals periodic damage while the player stays submerged")
	survival_oxygen.update(1.0, {"world_layer": "surface", "in_deep_water": false})
	_assert_true(not survival_oxygen.has_effect(&"drowning") and survival_oxygen.oxygen > 0.0, "surfacing clears drowning and recovers oxygen deterministically")


func _test_ocean_generation_scan() -> void:
	var seed := WorldSeed.from_text("V4.1-ocean-fixture")
	var terrain := TerrainGenerator.new(seed)
	var resource_generator := ResourceGenerator.new(seed)
	var water_resources := 0
	var land_resources := 0
	var ocean_center_chunk := Vector2i.ZERO
	var found_ocean := false
	for chunk_y in range(-7, 8):
		for chunk_x in range(-7, 8):
			var chunk_position := Vector2i(chunk_x, chunk_y)
			var center_tile := WorldCoordinates.chunk_local_to_tile(chunk_position, Vector2i(16, 16))
			if not found_ocean and terrain.terrain_at(center_tile) == ChunkData.Terrain.DEEP_WATER:
				ocean_center_chunk = chunk_position
				found_ocean = true
			var chunk := terrain.generate_chunk(chunk_position)
			for index in chunk.resource_count():
				var local := chunk.resource_local_at(index)
				var world_tile := WorldCoordinates.chunk_local_to_tile(chunk_position, local)
				var resource_terrain := terrain.terrain_at(world_tile)
				if resource_terrain == ChunkData.Terrain.SHALLOW_WATER or resource_terrain == ChunkData.Terrain.DEEP_WATER:
					water_resources += 1
					_assert_true(chunk.resource_code_at(index) >= 8, "ocean resources only occupy water tiles")
				else:
					land_resources += 1
					_assert_true(chunk.resource_code_at(index) <= 7, "beach and land resources keep their stable land codes")
	_assert_true(found_ocean, "deterministic scan finds deep ocean inside the origin region")
	_assert_true(water_resources >= 4, "ocean resources generate across the scanned water surface")
	_assert_true(land_resources > 0, "land resources remain part of the same deterministic scan")
	var repeated_chunk := terrain.generate_chunk(ocean_center_chunk)
	_assert_true(repeated_chunk.checksum == terrain.generate_chunk(ocean_center_chunk).checksum, "island-biome generation keeps chunk checksums deterministic")
	var structure_planner := StructurePlanner.new(seed)
	var water_structures := 0
	# 海洋只占世界的部分区域：围绕已发现的海洋区块所在的 384 格结构区域扫描。
	var ocean_region := Vector2i(
		floori(float(ocean_center_chunk.x * WorldCoordinates.CHUNK_SIZE) / 384.0),
		floori(float(ocean_center_chunk.y * WorldCoordinates.CHUNK_SIZE) / 384.0)
	)
	for region_y in range(ocean_region.y - 1, ocean_region.y + 2):
		for region_x in range(ocean_region.x - 1, ocean_region.x + 2):
			var plan := structure_planner.plan_water_region(Vector2i(region_x, region_y), terrain)
			if plan.is_empty():
				continue
			water_structures += 1
			for cell in plan["cells"] as Array:
				var cell_terrain := terrain.terrain_at(cell["world_tile"] as Vector2i)
				_assert_true(cell_terrain == ChunkData.Terrain.SHALLOW_WATER or cell_terrain == ChunkData.Terrain.DEEP_WATER, "water structures rest entirely on water terrain")
	_assert_true(water_structures >= 1, "deterministic scan places at least one shipwreck or sea ruin")
	var enemy_planner := EnemySpawnPlanner.new(seed)
	var enemy_catalog := EnemyCatalog.new()
	var aquatic_candidates := 0
	var land_candidates := 0
	for chunk_y in range(-8, 9):
		for chunk_x in range(-8, 9):
			for candidate in enemy_planner.candidates_for_chunk(Vector2i(chunk_x, chunk_y), &"", &"surface"):
				var definition := enemy_catalog.enemy(StringName(candidate["enemy_id"]))
				var candidate_terrain := terrain.terrain_at(candidate["world_tile"] as Vector2i)
				if definition != null and definition.aquatic:
					aquatic_candidates += 1
					_assert_true(candidate_terrain == ChunkData.Terrain.SHALLOW_WATER or candidate_terrain == ChunkData.Terrain.DEEP_WATER, "aquatic enemies spawn only in water")
				else:
					land_candidates += 1
					_assert_true(candidate_terrain == ChunkData.Terrain.LAND, "land enemies never spawn in water")
	_assert_true(aquatic_candidates >= 1 and land_candidates >= 1, "the scanned region hosts both aquatic and land enemy populations")


func _test_hydrology_models() -> void:
	var seed := WorldSeed.from_text("无尽边境水系")
	var hydrology := HydrologyGenerator.new(seed)
	var counts := PackedInt32Array()
	counts.resize(HydrologyGenerator.Feature.size())
	for y in range(-512, 513, 2):
		for x in range(-512, 513, 2):
			var tile := Vector2i(x, y)
			var feature := hydrology.feature_at(tile, ChunkData.Terrain.LAND, &"desert", 0.2 if y < 0 else 0.7, 0.58)
			counts[feature] += 1
	var fixture_tile := Vector2i(-257, 389)
	_assert_equal(hydrology.feature_at(fixture_tile, ChunkData.Terrain.LAND, &"plains", 0.6, 0.58), HydrologyGenerator.new(seed).feature_at(fixture_tile, ChunkData.Terrain.LAND, &"plains", 0.6, 0.58), "water feature is deterministic at signed world coordinates")
	_assert_true(counts[HydrologyGenerator.Feature.RIVER] > 0, "global channel field produces rivers")
	_assert_true(counts[HydrologyGenerator.Feature.BANK] > 0, "rivers produce a wider bank band")
	_assert_true(counts[HydrologyGenerator.Feature.BRIDGE] > 0, "stable short bridges cross some river cells")
	_assert_true(counts[HydrologyGenerator.Feature.LAKE] > 0 and counts[HydrologyGenerator.Feature.ICE_LAKE] > 0, "basins produce normal and frozen lakes")
	_assert_true(counts[HydrologyGenerator.Feature.OASIS] > 0, "hot desert basins produce oases")
	_assert_true(hydrology.movement_multiplier(HydrologyGenerator.Feature.RIVER) < 1.0 and hydrology.movement_multiplier(HydrologyGenerator.Feature.BRIDGE) == 1.0, "wading slows movement while bridges preserve land speed")


func _test_structure_models() -> void:
	var catalog := StructureCatalog.new()
	_assert_true(catalog.is_valid(), "external structure catalog loads and validates")
	_assert_equal(catalog.template_count(), 7, "catalog contains hut, camp, ruins, temple, dungeon entrance, shipwreck and sea ruin")
	for structure_id in [&"cabin", &"camp", &"ruins", &"temple", &"dungeon_entrance"]:
		_assert_true(not catalog.template_by_id(structure_id).is_empty(), "catalog contains stable structure ID %s" % structure_id)
	var planner := StructurePlanner.new(WorldSeed.from_text("结构测试"), catalog)
	var marker_counts := PackedInt32Array()
	marker_counts.resize(StructureCatalog.MarkerKind.size())
	for definition in catalog.templates():
		var original := planner.transformed_cells(definition, 0, false)
		var rotated := planner.transformed_cells(definition, 1, true)
		_assert_equal((original["cells"] as Array).size(), (rotated["cells"] as Array).size(), "%s rotation and mirror preserve every template cell" % definition["id"])
		_assert_equal(rotated["size"], Vector2i(int(definition["height"]), int(definition["width"])), "%s quarter-turn swaps template dimensions" % definition["id"])
		for cell in original["cells"] as Array:
			marker_counts[int((cell as Dictionary)["marker_kind"])] += 1
	_assert_true(marker_counts[StructureCatalog.MarkerKind.CHEST] > 0, "templates expose chest markers")
	_assert_true(marker_counts[StructureCatalog.MarkerKind.ENEMY_SPAWN] > 0, "templates expose enemy spawn markers")
	_assert_true(marker_counts[StructureCatalog.MarkerKind.DUNGEON_ENTRANCE] > 0, "templates expose a dungeon entrance marker")
	var terrain := TerrainGenerator.new(WorldSeed.from_text("跨区块建筑"))
	var selected_plan := {}
	for region_y in range(-12, 13):
		for region_x in range(-12, 13):
			selected_plan = planner.plan_region(Vector2i(region_x, region_y), terrain)
			if not selected_plan.is_empty():
				break
		if not selected_plan.is_empty():
			break
	_assert_true(not selected_plan.is_empty(), "deterministic region scan finds a valid surface structure")
	if not selected_plan.is_empty():
		var expected_tiles: Dictionary = {}
		for cell in selected_plan["cells"] as Array:
			expected_tiles[(cell as Dictionary)["world_tile"]] = true
		var actual_tiles: Dictionary = {}
		var bounds := selected_plan["bounds"] as Rect2i
		var first_chunk := WorldCoordinates.tile_to_chunk(bounds.position)
		var last_chunk := WorldCoordinates.tile_to_chunk(bounds.end - Vector2i.ONE)
		for chunk_y in range(first_chunk.y, last_chunk.y + 1):
			for chunk_x in range(first_chunk.x, last_chunk.x + 1):
				for cell in planner.generate_for_chunk(Vector2i(chunk_x, chunk_y), terrain):
					if String((cell as Dictionary)["instance_key"]) == String(selected_plan["instance_key"]):
						actual_tiles[(cell as Dictionary)["world_tile"]] = true
		_assert_equal(actual_tiles, expected_tiles, "cross-chunk planning clips and reconstructs one structure without seams")


func _test_village_models() -> void:
	var catalog := VillageCatalog.new()
	_assert_true(catalog.is_valid(), "external village configuration loads and validates")
	_assert_true(catalog.house_count_min() >= 4 and catalog.house_count_max() >= catalog.house_count_min(), "village house range is data-driven")
	var terrain := TerrainGenerator.new(WorldSeed.from_text("村庄道路测试"))
	var planner := VillagePlanner.new(WorldSeed.from_text("村庄道路测试"), catalog)
	var village := {}
	for region_y in range(-12, 13):
		for region_x in range(-12, 13):
			village = planner.village_for_region(Vector2i(region_x, region_y), terrain)
			if not village.is_empty(): break
		if not village.is_empty(): break
	_assert_true(not village.is_empty(), "deterministic region scan finds a valid village center")
	if village.is_empty():
		return
	var cells: Dictionary = {}
	var markers: Array[Dictionary] = []
	planner._add_village_layout(village, terrain, cells, markers)
	var feature_counts := PackedInt32Array()
	feature_counts.resize(VillagePlanner.Feature.size())
	for value in cells.values(): feature_counts[int(value)] += 1
	_assert_true(feature_counts[VillagePlanner.Feature.PLAZA] > 0 and feature_counts[VillagePlanner.Feature.ROAD] > 0, "village layout contains a center plaza and entrance roads")
	_assert_true(feature_counts[VillagePlanner.Feature.HOUSE] > 0 and feature_counts[VillagePlanner.Feature.SHOP] > 0, "village layout contains houses and a shop")
	_assert_true(feature_counts[VillagePlanner.Feature.WELL] == 1 and feature_counts[VillagePlanner.Feature.CAMPFIRE] == 1, "village center contains one well and one campfire")
	var marker_counts := PackedInt32Array()
	marker_counts.resize(VillagePlanner.Marker.size())
	for marker in markers: marker_counts[int((marker as Dictionary)["marker"])] += 1
	_assert_true(marker_counts[VillagePlanner.Marker.VILLAGE_CENTER] == 1 and marker_counts[VillagePlanner.Marker.NPC] > 0, "village exposes its center and NPC spawn markers")
	_assert_true(marker_counts[VillagePlanner.Marker.SHOP] == 1 and marker_counts[VillagePlanner.Marker.HOUSE_ENTRANCE] > 0, "building entrances connect shop and house markers")
	var regional_path := planner._orthogonal_path(Vector2i(-37, 19), Vector2i(84, -52), true)
	_assert_true(regional_path.front() == Vector2i(-37, 19) and regional_path.back() == Vector2i(84, -52), "regional road path joins exact signed-coordinate endpoints")
	_assert_equal(regional_path.size(), 193, "orthogonal regional road uses the exact Manhattan span")
	var water_tile := Vector2i.ZERO
	var found_water := false
	for y in range(-384, 385, 4):
		for x in range(-384, 385, 4):
			var probe := Vector2i(x, y)
			if HydrologyGenerator.is_water(terrain.water_feature_at(probe)):
				water_tile = probe
				found_water = true
				break
		if found_water: break
	_assert_true(found_water, "road fixture finds a river or lake crossing")
	if found_water:
		var crossing: Dictionary = {}
		planner._add_path(water_tile - Vector2i(3, 0), water_tile + Vector2i(3, 0), terrain, crossing)
		_assert_equal(int(crossing.get(water_tile, VillagePlanner.Feature.NONE)), VillagePlanner.Feature.BRIDGE, "roads convert water crossings into bridge tiles")


func _test_npc_models() -> void:
	var catalog := NpcCatalog.new()
	_assert_true(catalog.is_valid(), "external NPC configuration loads and validates")
	_assert_equal(catalog.role_ids(), [&"elder", &"merchant", &"innkeeper", &"farmer", &"guard", &"explorer"], "six stable NPC roles are data-driven")
	_assert_true(catalog.schedule_at(&"merchant", 0.10)["activity"] == "sleep" and catalog.schedule_at(&"merchant", 0.30)["activity"] == "trade", "NPC schedule resolves sleep and work from day progress")
	_assert_true(catalog.has_service(&"merchant", &"shop") and catalog.has_service(&"innkeeper", &"sleep"), "merchant and innkeeper services are explicit")
	_assert_true(not catalog.dialogue(&"elder", &"DAY", 0).is_empty() and catalog.dialogue(&"elder", &"DAY", 4) == catalog.dialogue(&"elder", &"DAY", 0), "phase dialogue selection cycles deterministically")
	var seed := WorldSeed.from_text("V2.1-NPC-fixture")
	var terrain := TerrainGenerator.new(seed)
	var planner := NpcPlanner.new(seed, catalog)
	var village_plan := {}
	for region_y in range(-12, 13):
		for region_x in range(-12, 13):
			village_plan = planner.plan_for_region(Vector2i(region_x, region_y), terrain)
			if not village_plan.is_empty(): break
		if not village_plan.is_empty(): break
	_assert_true(not village_plan.is_empty(), "NPC planner finds a deterministic generated village")
	if not village_plan.is_empty():
		var repeated := NpcPlanner.new(seed, catalog).plan_for_region((village_plan["village"] as Dictionary)["region"] as Vector2i, terrain)
		_assert_equal(village_plan["npcs"], repeated["npcs"], "same seed and village generate identical NPC identities")
		var role_set := {}
		var id_set := {}
		var merchant_plan := {}
		for value in village_plan["npcs"] as Array:
			var plan := value as Dictionary
			role_set[String(plan["role_id"])] = true
			id_set[String(plan["id"])] = true
			if String(plan["role_id"]) == "merchant": merchant_plan = plan
		_assert_true(role_set.has("elder") and role_set.has("merchant") and role_set.has("innkeeper"), "every village has elder, merchant and innkeeper roles")
		_assert_equal(id_set.size(), (village_plan["npcs"] as Array).size(), "procedural village NPC IDs are unique")
		var locations := merchant_plan.get("locations", {}) as Dictionary
		var road_path := NpcPathfinder.find_path(village_plan["cells"] as Dictionary, merchant_plan["home_tile"] as Vector2i, locations["shop"] as Vector2i)
		_assert_true(not road_path.is_empty() and road_path.front() == merchant_plan["home_tile"] and road_path.back() == locations["shop"], "NPC pathfinder connects a home to its scheduled workplace")
	var state := NpcWorldState.new()
	state.record_talk("village:0:0:npc:1", 2)
	state.record_trade("village:0:0:npc:1", &"buy", 6, 2)
	state.record_trade("village:0:0:npc:1", &"sell", 3, 3)
	var record := state.record_for("village:0:0:npc:1")
	_assert_true(int(record["talk_count"]) == 1 and int(record["trade_count"]) == 2 and int(record["coins_spent"]) == 6 and int(record["coins_earned"]) == 3, "NPC state records dialogue and both trade directions")
	var restored := NpcWorldState.new()
	_assert_true(restored.restore_snapshot(state.persistence_snapshot()) and restored.persistence_snapshot() == state.persistence_snapshot(), "NPC interaction state round trips exactly")
	var invalid := state.persistence_snapshot()
	(invalid["records"] as Array).append((invalid["records"] as Array)[0])
	_assert_true(not NpcWorldState.new().restore_snapshot(invalid), "NPC state validation rejects duplicate stable IDs")
	var relationship_catalog := RelationshipCatalog.new()
	_assert_true(relationship_catalog.is_valid(), "external relationship configuration loads and validates")
	_assert_true(relationship_catalog.tier_id(-30) == &"hostile" and relationship_catalog.tier_id(0) == &"neutral" and relationship_catalog.tier_id(60) == &"trusted", "five attitude tiers cover signed affection boundaries")
	_assert_true(relationship_catalog.gift_value(&"merchant", &"copper_ore") == 8 and relationship_catalog.gift_value(&"merchant", &"berry") == -7 and relationship_catalog.gift_value(&"merchant", &"wood") == 2, "role preferences resolve liked, disliked and neutral gifts")
	_assert_true(relationship_catalog.adjusted_buy_price(100, 60, 50) == 76 and relationship_catalog.adjusted_sell_price(100, 60, 50) == 124, "trusted attitude and village reputation adjust both sides of a trade")
	var relationships := RelationshipState.new()
	var first_gift := relationships.apply_gift("merchant:1", "village:1", &"merchant", &"copper_ore", 1, relationship_catalog)
	var duplicate_gift := relationships.apply_gift("merchant:1", "village:1", &"merchant", &"iron_ore", 1, relationship_catalog)
	_assert_true(bool(first_gift["ok"]) and int(first_gift["affection_delta"]) == 8 and not bool(duplicate_gift["ok"]), "gift transaction applies once per NPC per day")
	for day in range(2, 9):
		relationships.apply_gift("merchant:1", "village:1", &"merchant", &"copper_ore", day, relationship_catalog)
	var relationship_status := relationships.status_snapshot("merchant:1", "village:1", relationship_catalog, 8)
	_assert_true(int(relationship_status["affection"]) == 64 and int(relationship_status["village_reputation"]) == 32 and String(relationship_status["tier_id"]) == "trusted", "preferred gifts reach trusted attitude and village reputation deterministically")
	var claimed_rewards := ((relationships.persistence_snapshot()["npcs"] as Array)[0] as Dictionary)["claimed_rewards"] as Array
	_assert_equal(claimed_rewards, ["friendly_gift", "trusted_gift"], "relationship thresholds claim each configured reward exactly once")
	var restored_relationships := RelationshipState.new()
	_assert_true(restored_relationships.restore_snapshot(relationships.persistence_snapshot()) and restored_relationships.persistence_snapshot() == relationships.persistence_snapshot(), "relationship state round trips exactly")
	var invalid_relationships := relationships.persistence_snapshot()
	(invalid_relationships["villages"] as Array).append((invalid_relationships["villages"] as Array)[0])
	_assert_true(not RelationshipState.new().restore_snapshot(invalid_relationships), "relationship validation rejects duplicate village IDs")
	var cycle := DayNightCycle.new(300.0)
	var sleep_elapsed := cycle.advance_to_next_phase(&"DAWN")
	_assert_true(is_equal_approx(sleep_elapsed, 900.0) and cycle.snapshot()["phase"] == &"DAWN" and int(cycle.snapshot()["day"]) == 2, "sleep advances time once to the next dawn")


func _test_quest_models() -> void:
	var catalog := QuestCatalog.new()
	_assert_true(catalog.is_valid(), "external quest configuration loads and validates")
	_assert_equal(catalog.quest_ids().size(), 24, "quest catalog contains 10 main and 14 side fixed templates")
	var categories := {}
	var category_counts := {"main": 0, "side": 0}
	var objective_types := {}
	for quest_id in catalog.quest_ids():
		var definition := catalog.quest(quest_id)
		categories[String(definition["category"])] = true
		category_counts[String(definition["category"])] = int(category_counts.get(String(definition["category"]), 0)) + 1
		for value in definition.get("objectives", []) as Array:
			objective_types[String((value as Dictionary)["type"])] = true
	_assert_true(categories.has("main") and categories.has("side"), "quest catalog separates main and side categories")
	_assert_true(int(category_counts["main"]) == 10 and int(category_counts["side"]) == 14, "fixed template mix contains a complete main chain and broad side set")
	_assert_equal(objective_types.keys().size(), 4, "collect, defeat, explore and escort objectives are all data-driven")
	_assert_true(catalog.random_rule_ids().size() == 4 and catalog.random_offers_per_board() == 3 and catalog.maximum_generated_quests() == 96, "random board rules expose bounded deterministic offer limits")
	_assert_equal(catalog.world_choice_ids(), [&"core_destination", &"border_priority", &"frontier_future"], "three stable key world choices are data-driven")
	var state := QuestState.new()
	_assert_true(state.status(&"main_frontier_supplies", catalog) == &"available" and state.status(&"main_village_roads", catalog) == &"locked", "prerequisites expose only the first main quest")
	_assert_true(state.accept(&"main_frontier_supplies", catalog), "available main quest can be accepted")
	state.synchronize_collect({"wood": 9}, catalog)
	_assert_true(state.status(&"main_frontier_supplies", catalog) == &"active", "collect objective remains active below its exact quantity")
	state.synchronize_collect({"wood": 10}, catalog)
	_assert_true(state.status(&"main_frontier_supplies", catalog) == &"completed" and state.status(&"main_village_roads", catalog) == &"locked", "completed objective waits for reward claim before unlocking its successor")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood", 10)
	var claim := state.claim_reward(&"main_frontier_supplies", inventory, catalog)
	_assert_true(bool(claim["ok"]) and inventory.quantity(&"coin") == 6 and state.status(&"main_village_roads", catalog) == &"available", "atomic reward claim unlocks the next main quest")
	_assert_true(state.accept(&"main_village_roads", catalog), "unlocked exploration quest can be accepted")
	state.synchronize_explore({"village": 1}, catalog)
	_assert_true(state.status(&"main_village_roads", catalog) == &"completed", "landmark discovery completes an explore objective")
	_assert_true(state.accept(&"side_slime_hunt", catalog) and state.abandon(&"side_slime_hunt", catalog), "abandonable side quest enters a persisted failed state")
	_assert_true(state.status(&"side_slime_hunt", catalog) == &"failed" and state.accept(&"side_slime_hunt", catalog), "retryable failed quest resets its objectives")
	state.record_event(&"defeat", &"slime", 4, catalog)
	_assert_true(state.status(&"side_slime_hunt", catalog) == &"completed" and state.track(&"side_slime_hunt"), "defeat events complete and track a side quest")
	_assert_true(state.accept(&"side_trade_route", catalog), "escort-style side quest can be accepted")
	state.record_event(&"escort", &"merchant", 1, catalog)
	var full_inventory := InventoryModel.new()
	for _index in full_inventory.slot_count():
		full_inventory.add_item(&"wood_sword", 1)
	var full_before := full_inventory.snapshot()
	var blocked_claim := state.claim_reward(&"side_trade_route", full_inventory, catalog)
	_assert_true(not bool(blocked_claim["ok"]) and full_inventory.snapshot() == full_before and state.status(&"side_trade_route", catalog) == &"completed", "full inventory rolls back a quest reward without consuming completion")
	var persisted := state.persistence_snapshot()
	var restored := QuestState.new()
	_assert_true(restored.restore_snapshot(persisted, catalog) and restored.persistence_snapshot() == persisted, "quest status, failures, tracking and objective progress round trip exactly")
	var invalid := persisted.duplicate(true)
	(invalid["entries"] as Array).append((invalid["entries"] as Array)[0])
	_assert_true(not QuestState.new().restore_snapshot(invalid, catalog), "quest persistence rejects duplicate stable quest IDs")
	var generator_a := QuestGenerator.new(WorldSeed.from_text("V3.0-random-board"), catalog)
	var generator_b := QuestGenerator.new(WorldSeed.from_text("V3.0-random-board"), catalog)
	var day_three := generator_a.generate_board("region:-3:2", 3)
	var day_four := generator_a.generate_board("region:-3:2", 4)
	_assert_true(day_three.size() == 3 and day_three == generator_b.generate_board("region:-3:2", 3), "same seed, signed region and day produce the same three random offers")
	var generated_ids := {}
	var generated_types := {}
	for value in day_three:
		var generated := value as Dictionary
		generated_ids[String(generated["id"])] = true
		generated_types[String(((generated["objectives"] as Array)[0] as Dictionary)["type"])] = true
	_assert_true(generated_ids.size() == 3 and day_three != day_four, "random offer IDs are unique and the next day refreshes deterministically")
	_assert_true(generated_types.size() == 3, "one board selects three distinct generation rules")
	var random_state := QuestState.new()
	var board_ids := random_state.ensure_random_board(WorldSeed.from_text("V3.0-random-board"), "region:-3:2", 3, catalog)
	_assert_true(board_ids.size() == 3 and random_state.status(StringName(board_ids[0]), catalog) == &"available", "generated board offers enter normal quest availability")
	_assert_true(random_state.accept(StringName(board_ids[0]), catalog), "a deterministic random offer can be accepted")
	var random_definition := random_state.definition(StringName(board_ids[0]), catalog)
	var random_objective := (random_definition["objectives"] as Array)[0] as Dictionary
	var random_target := StringName(random_objective["target_id"])
	var random_quantity := int(random_objective["quantity"])
	match String(random_objective["type"]):
		"collect": random_state.synchronize_collect({String(random_target): random_quantity}, catalog)
		"defeat", "escort": random_state.record_event(StringName(random_objective["type"]), random_target, random_quantity, catalog)
		"explore": random_state.synchronize_explore({String(random_target): random_quantity}, catalog)
	_assert_true(random_state.status(StringName(board_ids[0]), catalog) == &"completed", "generated objectives use the same completion pipeline as fixed quests")
	var random_persisted := random_state.persistence_snapshot()
	var random_restored := QuestState.new()
	_assert_true(random_restored.restore_snapshot(random_persisted, catalog) and random_restored.persistence_snapshot() == random_persisted, "generated definitions, board origin and progress round trip exactly")
	var legacy_snapshot := {"schema_version": 1, "tracked_id": persisted["tracked_id"], "entries": (persisted["entries"] as Array).duplicate(true)}
	var migrated_legacy := QuestState.migrate_legacy_snapshot(legacy_snapshot)
	var migrated_state := QuestState.new()
	_assert_true(migrated_state.restore_snapshot(migrated_legacy, catalog) and (migrated_state.persistence_snapshot()["entries"] as Array).size() == (persisted["entries"] as Array).size(), "V2.6 quest schema migrates without losing fixed quest progress")
	var choice_quests := QuestState.new()
	var choice_inventory := InventoryModel.new()
	choice_quests.accept(&"main_frontier_supplies", catalog)
	choice_quests.synchronize_collect({"wood": 10}, catalog)
	choice_quests.claim_reward(&"main_frontier_supplies", choice_inventory, catalog)
	choice_quests.accept(&"main_village_roads", catalog)
	choice_quests.synchronize_explore({"village": 1}, catalog)
	choice_quests.claim_reward(&"main_village_roads", choice_inventory, catalog)
	choice_quests.accept(&"main_wild_threat", catalog)
	choice_quests.record_event(&"defeat", &"wolf", 3, catalog)
	choice_quests.claim_reward(&"main_wild_threat", choice_inventory, catalog)
	choice_quests.accept(&"main_dungeon_echo", catalog)
	choice_quests.synchronize_explore({"dungeon": 1}, catalog)
	choice_quests.claim_reward(&"main_dungeon_echo", choice_inventory, catalog)
	choice_quests.accept(&"main_warden_fall", catalog)
	choice_quests.record_event(&"defeat", &"dungeon_warden", 1, catalog)
	choice_quests.claim_reward(&"main_warden_fall", choice_inventory, catalog)
	var choices := WorldChoiceState.new()
	var factions := FactionState.new(FactionCatalog.new())
	var progression := RegionProgressionState.new()
	var choice_result := choices.resolve(&"core_destination", &"village_vault", 4, choice_quests, catalog, factions, FactionCatalog.new(), progression, RegionProgressionCatalog.new())
	_assert_true(bool(choice_result["ok"]) and factions.standing(&"frontier_union", FactionCatalog.new()) == 8 and factions.standing(&"merchant_guild", FactionCatalog.new()) == -2, "resolved key choice applies its exact faction consequences once")
	_assert_true(progression.world_progress_points() == 6 and not bool(choices.resolve(&"core_destination", &"guild_exchange", 4, choice_quests, catalog, factions, FactionCatalog.new(), progression, RegionProgressionCatalog.new())["ok"]), "key choice grants one world-progress source and cannot be overwritten")
	var choice_persisted := choices.persistence_snapshot()
	var choice_restored := WorldChoiceState.new()
	_assert_true(choice_restored.restore_snapshot(choice_persisted, catalog) and choice_restored.persistence_snapshot() == choice_persisted, "selected option and resolution day round trip exactly")


func _test_faction_models() -> void:
	var catalog := FactionCatalog.new()
	_assert_true(catalog.is_valid(), "external faction configuration loads and validates")
	_assert_equal(catalog.faction_ids(), [&"frontier_union", &"merchant_guild", &"pathfinders", &"ash_raiders"], "four stable faction IDs are data-driven")
	_assert_true(catalog.tier_id(-60) == &"enemy" and catalog.tier_id(-59) == &"hostile" and catalog.tier_id(0) == &"neutral" and catalog.tier_id(25) == &"respected" and catalog.tier_id(60) == &"allied", "five faction tiers cover every signed standing boundary")
	_assert_true(catalog.role_faction(&"merchant") == &"merchant_guild" and catalog.role_faction(&"guard") == &"frontier_union" and catalog.enemy_faction(&"bandit_scout") == &"ash_raiders", "NPC roles and hostile enemies map to one owning faction")
	_assert_true(catalog.relation(&"frontier_union", &"ash_raiders") == -100 and catalog.relation(&"ash_raiders", &"frontier_union") == -100 and catalog.relation(&"merchant_guild", &"pathfinders") == 25, "pairwise faction relations are complete and symmetric")
	var state := FactionState.new(catalog)
	_assert_true(state.standing(&"frontier_union", catalog) == 0 and state.standing(&"merchant_guild", catalog) == 0 and state.standing(&"pathfinders", catalog) == 0 and state.standing(&"ash_raiders", catalog) == -45, "new faction state initializes all four configured standings")
	var trade := state.record_trade(&"merchant", catalog)
	var quest := state.record_quest(&"merchant", catalog)
	_assert_true(bool(trade["changed"]) and bool(quest["changed"]) and state.standing(&"merchant_guild", catalog) == 6, "trade and quest actions grant exact owning-faction standing")
	var discovery := state.record_discovery("village:test", &"village", catalog)
	var repeated_discovery := state.record_discovery("village:test", &"village", catalog)
	_assert_true(bool(discovery["changed"]) and not bool(repeated_discovery["changed"]) and state.standing(&"pathfinders", catalog) == 2, "landmark standing is awarded once per stable marker")
	_assert_true(String(state.control_point("village:test")["owner_faction_id"]) == "frontier_union", "village discovery registers a frontier control point")
	state.record_defeat("spawn:test:bandit", &"bandit_scout", catalog)
	_assert_true(state.standing(&"ash_raiders", catalog) == -51 and state.standing(&"frontier_union", catalog) == 3, "defeating a hostile member lowers its standing and rewards its enemy")
	var merchant_offers := state.shop_offers(&"merchant_guild", catalog)
	_assert_true(bool(merchant_offers[0]["unlocked"]) and not bool(merchant_offers[1]["unlocked"]), "faction shop gates offers by standing tier")
	state.adjust(&"frontier_union", 22, "test:respected", catalog)
	var union_offers := state.shop_offers(&"frontier_union", catalog)
	_assert_true(bool(union_offers[1]["unlocked"]) and int(union_offers[1]["price"]) == 23, "respected standing unlocks stock and applies the configured discount")
	var first_contest := state.contest_control_point("village:test", &"ash_raiders", 50, catalog)
	var second_contest := state.contest_control_point("village:test", &"ash_raiders", 50, catalog)
	_assert_true(bool(first_contest["ok"]) and not bool(first_contest["captured"]) and bool(second_contest["captured"]) and String(state.control_point("village:test")["owner_faction_id"]) == "ash_raiders", "hostile influence captures a control point only after its defense reaches zero")
	var persisted := state.persistence_snapshot()
	var restored := FactionState.new(catalog)
	_assert_true(restored.restore_snapshot(persisted, catalog) and restored.persistence_snapshot() == persisted, "faction standings, discoveries, events and control points round trip exactly")
	var invalid := persisted.duplicate(true)
	(invalid["standings"] as Array).append((invalid["standings"] as Array)[0])
	_assert_true(not FactionState.new(catalog).restore_snapshot(invalid, catalog), "faction persistence rejects duplicate or incomplete standing records")


func _test_world_event_models() -> void:
	var catalog := WorldEventCatalog.new()
	_assert_true(catalog.is_valid(), "external world-event configuration loads and validates")
	_assert_equal(catalog.event_ids(), [&"caravan_passage", &"village_raid", &"meteor_fall", &"resource_surge", &"blizzard", &"ruin_opening", &"temporary_boss", &"rescue_operation"], "all eight roadmap world-event types use stable data-driven IDs")
	_assert_true(catalog.maximum_active() == 1 and catalog.timetable_horizon() == 6 and catalog.history_limit() == 48, "event concurrency, timetable horizon and bounded history are explicit")
	_assert_true(float(catalog.effect(&"resource_surge", &"resource_yield_multiplier", 0.0)) == 1.75 and StringName(catalog.effect(&"blizzard", &"weather_override", "")) == &"SNOW", "resource surges and blizzards expose gameplay effects")
	var seed := WorldSeed.from_text("V2.5-world-event-fixture")
	var planner := WorldEventPlanner.new(seed, catalog)
	var repeated := WorldEventPlanner.new(seed, catalog)
	var first_cycle := {}
	var deterministic := true
	for slot_index in catalog.event_ids().size():
		var plan := planner.plan_for_slot(slot_index)
		first_cycle[String(plan["event_id"])] = true
		deterministic = deterministic and plan == repeated.plan_for_slot(slot_index)
	_assert_true(deterministic and first_cycle.size() == 8, "same seed produces one deterministic permutation containing every event per eight slots")
	var first_plan := planner.plan_for_slot(0)
	var state := WorldEventState.new()
	var before := state.advance(float(first_plan["start_seconds"]) - 0.01, Vector2i(-4, 7), planner, catalog)
	var activation := state.advance(float(first_plan["start_seconds"]) + 0.01, Vector2i(-4, 7), planner, catalog)
	_assert_true(not bool(before["changed"]) and bool(activation["changed"]) and state.active_count() == 1, "world event starts exactly at its deterministic timetable boundary")
	var active := state.active_records()[0]
	_assert_equal(active["target_chunk"], [-4, 7], "new event anchors to the player's current signed chunk")
	var objective := catalog.objective(StringName(active["event_id"]))
	var target_id := StringName("fixture") if String(objective["target_id"]) == "*" else StringName(objective["target_id"])
	var completion := state.record_event(StringName(objective["type"]), target_id, int(objective["quantity"]), float(first_plan["start_seconds"]) + 1.0, catalog)
	_assert_true(bool(completion["changed"]) and (completion["completed"] as Array).size() == 1 and state.active_count() == 0 and String(state.history_records().back()["status"]) == "completed", "matching runtime progress resolves an active event exactly once")
	var persisted := state.persistence_snapshot()
	var restored := WorldEventState.new()
	_assert_true(restored.restore_snapshot(persisted, catalog) and restored.persistence_snapshot() == persisted, "event schedule cursor, active state and bounded history round trip exactly")
	var invalid := persisted.duplicate(true)
	(invalid["history"] as Array).append((invalid["history"] as Array)[0])
	_assert_true(not WorldEventState.new().restore_snapshot(invalid, catalog), "event persistence rejects duplicate stable instance IDs")
	var resource_slot := -1
	var blizzard_slot := -1
	for slot_index in 16:
		var event_id := String(planner.plan_for_slot(slot_index)["event_id"])
		if event_id == "resource_surge": resource_slot = slot_index
		if event_id == "blizzard": blizzard_slot = slot_index
	_assert_true(resource_slot >= 0 and blizzard_slot >= 0, "deterministic timetable exposes resource and weather fixtures")
	var resource_state := WorldEventState.new()
	var resource_plan := planner.plan_for_slot(resource_slot)
	resource_state.advance(float(resource_plan["start_seconds"]) + 0.01, Vector2i.ZERO, planner, catalog)
	_assert_true(resource_state.effect_multiplier(&"resource_yield_multiplier", catalog) == 1.75, "active resource burst applies its exact yield multiplier")
	var weather_state := WorldEventState.new()
	var blizzard_plan := planner.plan_for_slot(blizzard_slot)
	weather_state.advance(float(blizzard_plan["start_seconds"]) + 0.01, Vector2i.ZERO, planner, catalog)
	_assert_true(weather_state.weather_override(catalog) == &"SNOW", "active blizzard forces the configured snow weather")
	var long_running := WorldEventState.new()
	long_running.advance(1000000000.0, Vector2i(2, -3), planner, catalog)
	_assert_true(long_running.history_count() <= catalog.history_limit() and long_running.next_slot() > 1000000, "large time skips fast-forward without unbounded history growth")


func _test_region_progression_models() -> void:
	var catalog := RegionProgressionCatalog.new()
	_assert_true(catalog.is_valid(), "external region-progression configuration loads and validates")
	_assert_true(catalog.region_size_chunks() == 6 and catalog.maximum_danger_level() == 5, "world is partitioned into explicit 6×6 regions and five danger tiers")
	_assert_true(int(catalog.danger_tier(1)["enemy_level_min"]) == 1 and int(catalog.danger_tier(5)["enemy_level_max"]) == 21, "danger tiers expose the complete enemy level curve")
	_assert_true(float(catalog.danger_tier(5)["elite_chance"]) > float(catalog.danger_tier(1)["elite_chance"]), "elite chance rises monotonically from safe border to the extreme frontier")
	var seed := WorldSeed.from_text("V2.6-region-progression-fixture")
	var model := RegionProgressionModel.new(seed, catalog)
	_assert_equal(model.region_coordinate(Vector2i(-1, -4)), Vector2i(-1, -1), "signed chunk coordinates use floor division for stable region ownership")
	var safe_profile := model.region_profile(Vector2i(-1, -4))
	var extreme_profile := model.region_profile(Vector2i(48, 0))
	_assert_true(int(safe_profile["danger_level"]) == 1 and int(extreme_profile["danger_level"]) == 5, "distance bands resolve bounded regional danger levels")
	_assert_equal(model.region_profile(Vector2i(48, 0)), RegionProgressionModel.new(seed, catalog).region_profile(Vector2i(48, 0)), "regional danger profiles are deterministic across restarts")
	var normal_enemy := model.enemy_profile(Vector2i(48, 0), "fixture:boss", &"boss", &"surface")
	var elite_enemy := model.enemy_profile(Vector2i(48, 0), "fixture:elite", &"elite", &"surface")
	_assert_true(int(normal_enemy["level"]) >= 15 and int(normal_enemy["level"]) <= 21 and not bool(normal_enemy["elite"]), "enemy level stays inside the current regional range")
	_assert_true(bool(elite_enemy["elite"]) and float(elite_enemy["health_multiplier"]) > float(normal_enemy["health_multiplier"]) and int(elite_enemy["drop_multiplier"]) == 2, "elite enemies apply explicit health and drop multipliers")
	_assert_equal(elite_enemy, RegionProgressionModel.new(seed, catalog).enemy_profile(Vector2i(48, 0), "fixture:elite", &"elite", &"surface"), "enemy level and elite profile are stable for one seed and spawn ID")
	var inventory := InventoryModel.new()
	_assert_equal(catalog.gear_score(inventory.snapshot()), 0, "empty inventory has zero equipment score")
	for item_id in [&"wood_sword", &"wood_axe", &"wood_pickaxe"]:
		inventory.add_item(item_id, 1)
	_assert_equal(catalog.gear_score(inventory.snapshot()), 16, "best wood weapon and tools compose the expected equipment score")
	for item_id in [&"stone_sword", &"stone_axe", &"stone_pickaxe"]:
		inventory.add_item(item_id, 1)
	_assert_equal(catalog.gear_score(inventory.snapshot()), 32, "higher-tier items replace lower items within each equipment score slot")
	for item_id in [&"grove_sigil", &"dune_sigil", &"frost_sigil", &"tide_sigil"]:
		inventory.add_item(item_id, 1)
	_assert_equal(catalog.gear_score(inventory.snapshot()), 48, "four unique Boss sigils extend the complete equipment score to the final recommendation")
	var state := RegionProgressionState.new()
	var discovery := state.discover_region(safe_profile, catalog)
	_assert_true(bool(discovery["changed"]) and int(discovery["gained"]) == 2 and state.world_progress_points() == 2, "first regional discovery grants one exact world-progress source")
	_assert_true(not bool(state.discover_region(safe_profile, catalog)["changed"]) and state.world_progress_points() == 2, "repeat visits cannot duplicate regional progress")
	var reward_inventory := InventoryModel.new()
	var reward := state.claim_region_reward(String(safe_profile["region_id"]), reward_inventory, catalog)
	_assert_true(bool(reward["ok"]) and reward_inventory.quantity(&"coin") == 6 and reward_inventory.quantity(&"berry") == 2, "eligible region reward transfers every configured item atomically")
	_assert_true(not bool(state.claim_region_reward(String(safe_profile["region_id"]), reward_inventory, catalog)["ok"]), "region reward can be claimed only once")
	var tier_two := model.region_profile(Vector2i(12, 0))
	var challenge_state := RegionProgressionState.new()
	challenge_state.discover_region(tier_two, catalog)
	var elite_result := challenge_state.record_elite_defeat(tier_two, "spawn:elite:fixture", catalog)
	challenge_state.record_source(&"quest_claimed", "quest:fixture", catalog)
	_assert_true(bool(elite_result["changed"]) and challenge_state.elite_defeats(String(tier_two["region_id"])) == 1 and challenge_state.can_claim_region_reward(String(tier_two["region_id"]), catalog), "tier-two reward requires both one unique elite and the configured world progress")
	_assert_true(not bool(challenge_state.record_elite_defeat(tier_two, "spawn:elite:fixture", catalog)["changed"]), "same elite spawn cannot grant world progress twice")
	var unlock_state := RegionProgressionState.new()
	unlock_state.discover_region(safe_profile, catalog)
	unlock_state.record_source(&"regional_boss_defeated", "grove_titan", catalog)
	unlock_state.record_source(&"dungeon_completed", "dungeon:fixture", catalog)
	var unlock_view := unlock_state.status_snapshot(safe_profile, 16, catalog)
	_assert_true((unlock_view["unlocked_boss_ids"] as Array).has("dune_behemoth") and not (unlock_view["unlocked_boss_ids"] as Array).has("frost_wyrm") and not (unlock_view["unlocked_boss_ids"] as Array).has("tide_sovereign"), "world progress unlocks the second regional Boss while preserving the final gates")
	var persisted := challenge_state.persistence_snapshot()
	var restored := RegionProgressionState.new()
	_assert_true(restored.restore_snapshot(persisted, catalog) and restored.persistence_snapshot() == persisted, "regional discoveries, elite sources and reward state round trip exactly")
	var tampered := persisted.duplicate(true)
	(tampered["sources"] as Array)[0]["points"] = 999
	_assert_true(not RegionProgressionState.new().restore_snapshot(tampered, catalog), "progress persistence rejects a tampered source score")
	var full_inventory := InventoryModel.new()
	full_inventory.add_item(&"wood_axe", full_inventory.slot_count())
	var atomic_state := RegionProgressionState.new()
	atomic_state.discover_region(safe_profile, catalog)
	var before_full := full_inventory.snapshot()
	_assert_true(not bool(atomic_state.claim_region_reward(String(safe_profile["region_id"]), full_inventory, catalog)["ok"]) and full_inventory.snapshot() == before_full and atomic_state.can_claim_region_reward(String(safe_profile["region_id"]), catalog), "full inventory rolls back a region reward without consuming its one-time claim")


func _test_cave_models() -> void:
	var seed := WorldSeed.from_text("地下洞穴测试")
	var catalog := CaveCatalog.new()
	_assert_true(catalog.is_valid(), "external cave configuration loads and validates")
	_assert_true(catalog.veins().size() == 3 and catalog.entrance_region_chunks() == 4, "cave veins and entrance spacing are data-driven")
	var terrain := TerrainGenerator.new(seed)
	var entrance_planner := CaveEntrancePlanner.new(seed, catalog)
	var entrance := entrance_planner.entrance_for_region(Vector2i(-1, -1), terrain)
	var repeated_entrance := CaveEntrancePlanner.new(seed, catalog).entrance_for_region(Vector2i(-1, -1), terrain)
	_assert_equal(entrance, repeated_entrance, "surface cave entrance is deterministic across planner restarts")
	_assert_true(not entrance.is_empty() and terrain.terrain_at(entrance["world_tile"] as Vector2i) == ChunkData.Terrain.LAND, "surface cave entrance occupies stable dry land")
	var entrance_chunk_position := entrance["chunk_position"] as Vector2i
	var entrance_local := entrance["local"] as Vector2i
	var surface_chunk := terrain.generate_chunk(entrance_chunk_position)
	_assert_equal(surface_chunk.cave_feature_at(entrance_local), CaveGenerator.Feature.ENTRANCE, "surface chunk exposes the cave transition marker")
	var generator := CaveGenerator.new(seed, catalog)
	var cave_chunk := generator.generate_chunk(entrance_chunk_position)
	var repeated_chunk := CaveGenerator.new(seed, catalog).generate_chunk(entrance_chunk_position)
	_assert_true(cave_chunk.world_layer == &"underground" and cave_chunk.cave_cell_map.size() == 1024 and cave_chunk.cave_feature_map.size() == 1024, "underground chunk contains complete cave cell and feature maps")
	_assert_true(cave_chunk.checksum == repeated_chunk.checksum and cave_chunk.cave_cell_map == repeated_chunk.cave_cell_map, "cellular cave generation is byte-deterministic")
	var floor_count := cave_chunk.cave_cell_map.count(CaveGenerator.Cell.FLOOR)
	var wall_count := cave_chunk.cave_cell_map.count(CaveGenerator.Cell.WALL)
	_assert_true(floor_count >= ceili(1024.0 * float(catalog.generation_value("minimum_floor_ratio", 0.34))) and wall_count > 0, "cellular automata preserve both navigable floor and cave walls")
	_assert_true(_cave_floor_is_connected(cave_chunk), "cave connectivity repair joins every floor component")
	_assert_equal(cave_chunk.cave_feature_at(entrance_local), CaveGenerator.Feature.EXIT, "underground exit aligns exactly with its surface entrance")
	var right_chunk := generator.generate_chunk(entrance_chunk_position + Vector2i.RIGHT)
	_assert_true(cave_chunk.is_cave_floor(Vector2i(31, 16)) and right_chunk.is_cave_floor(Vector2i(0, 16)), "adjacent underground chunks share a guaranteed seam passage")
	var represented_veins := {}
	var chest_count := 0
	var torch_count := 0
	var underground_keys_valid := true
	for chunk_y in range(-5, 6):
		for chunk_x in range(-5, 6):
			var generated := generator.generate_chunk(Vector2i(chunk_x, chunk_y))
			chest_count += generated.cave_feature_count(CaveGenerator.Feature.CHEST)
			torch_count += generated.cave_feature_count(CaveGenerator.Feature.TORCH)
			for index in generated.resource_count():
				represented_veins[ResourceCatalog.new().id_for_code(generated.resource_code_at(index))] = true
				underground_keys_valid = underground_keys_valid and generated.resource_key_at(index).begins_with("underground:")
	_assert_true(represented_veins.has(&"coal_vein") and represented_veins.has(&"copper_vein") and represented_veins.has(&"iron_vein"), "broad underground scan contains all three mineral vein types")
	_assert_true(chest_count > 0 and torch_count > 0, "underground chunks contain deterministic chests and torch lighting")
	_assert_true(underground_keys_valid, "underground resource keys preserve their world layer")
	var chest_key := "underground:-17:29"
	_assert_equal(catalog.chest_loot(chest_key), CaveCatalog.new().chest_loot(chest_key), "underground chest loot is deterministic")
	var enemy_planner := EnemySpawnPlanner.new(seed)
	var cave_enemy_count := 0
	var cave_enemy_valid := true
	for chunk_y in range(-4, 5):
		for chunk_x in range(-4, 5):
			for candidate in enemy_planner.candidates_for_chunk(Vector2i(chunk_x, chunk_y), &"DAY", &"underground"):
				cave_enemy_count += 1
				cave_enemy_valid = cave_enemy_valid and candidate["enemy_id"] == &"cave_bat" and String(candidate["spawn_id"]).begins_with("underground:")
	_assert_true(cave_enemy_count > 0 and cave_enemy_valid, "underground planner spawns cave bats only on cave floors")


func _test_dungeon_models() -> void:
	var seed := WorldSeed.from_text("程序化地牢测试")
	var entrance_tile := Vector2i(-17, 29)
	var anchor_chunk := WorldCoordinates.tile_to_chunk(entrance_tile)
	var dungeon_id := DungeonGenerator.dungeon_id_for_entrance(entrance_tile)
	var catalog := DungeonCatalog.new()
	_assert_true(catalog.is_valid(), "external dungeon configuration loads and validates")
	_assert_true(int(catalog.generation_value("room_count_minimum", 0)) == 6 and int(catalog.generation_value("room_count_maximum", 0)) == 6, "dungeon room count is data-driven at six")
	_assert_true(int(catalog.feature_value("locked_doors", 0)) == 2 and int(catalog.feature_value("keys", 0)) == 2, "dungeon lock-and-key counts are balanced in data")
	_assert_true(bool(catalog.reset_value("incomplete_resets_on_exit", false)) and bool(catalog.reset_value("completed_state_persists", false)), "dungeon reset and completion rules are explicit")
	var generator := DungeonGenerator.new(seed, dungeon_id, anchor_chunk, catalog)
	var repeated_generator := DungeonGenerator.new(seed, dungeon_id, anchor_chunk, catalog)
	var chunk := generator.generate_chunk(anchor_chunk)
	var repeated_chunk := repeated_generator.generate_chunk(anchor_chunk)
	var layout := generator.layout_snapshot()
	_assert_true(chunk.world_layer == &"dungeon" and chunk.dungeon_cell_map.size() == 1024 and chunk.dungeon_feature_map.size() == 1024, "dungeon chunk contains complete cell and feature maps")
	_assert_true(chunk.checksum == repeated_chunk.checksum and chunk.dungeon_cell_map == repeated_chunk.dungeon_cell_map and chunk.dungeon_feature_map == repeated_chunk.dungeon_feature_map, "dungeon generation is byte-deterministic")
	var rooms := layout["rooms"] as Array
	var rooms_do_not_overlap := rooms.size() == 6
	for first_index in rooms.size():
		var first_rect := (rooms[first_index] as Dictionary)["rect"] as Rect2i
		rooms_do_not_overlap = rooms_do_not_overlap and Rect2i(0, 0, 32, 32).encloses(first_rect)
		for second_index in range(first_index + 1, rooms.size()):
			var second_rect := (rooms[second_index] as Dictionary)["rect"] as Rect2i
			rooms_do_not_overlap = rooms_do_not_overlap and not first_rect.intersects(second_rect)
	_assert_true(rooms_do_not_overlap, "six bounded procedural rooms never overlap")
	var connections := layout["connections"] as Array
	var corridors_are_continuous := connections.size() == rooms.size() - 1
	for connection_value in connections:
		var path := (connection_value as Dictionary)["path"] as Array
		corridors_are_continuous = corridors_are_continuous and not path.is_empty()
		for index in range(1, path.size()):
			var previous := path[index - 1] as Vector2i
			var current := path[index] as Vector2i
			corridors_are_continuous = corridors_are_continuous and absi(previous.x - current.x) + absi(previous.y - current.y) == 1
	_assert_true(corridors_are_continuous and _dungeon_floor_is_connected(chunk), "room corridors form one connected navigable dungeon")
	_assert_true(chunk.dungeon_feature_count(DungeonGenerator.Feature.EXIT) == 1 and chunk.dungeon_feature_count(DungeonGenerator.Feature.BOSS_SPAWN) == 1, "dungeon contains one aligned exit and one final Boss")
	_assert_true(chunk.dungeon_feature_count(DungeonGenerator.Feature.LOCKED_DOOR) == 2 and chunk.dungeon_feature_count(DungeonGenerator.Feature.KEY) == 2, "dungeon contains two locked doors and two obtainable keys")
	_assert_true(chunk.dungeon_feature_count(DungeonGenerator.Feature.TRAP) == 4 and chunk.dungeon_feature_count(DungeonGenerator.Feature.CHEST) == 2, "dungeon contains deterministic traps and treasure chests")
	_assert_true(chunk.dungeon_feature_count(DungeonGenerator.Feature.ELITE_SPAWN) == 2, "dungeon contains two elite encounter rooms")
	_assert_equal(generator.entry_world_tile(), WorldCoordinates.chunk_local_to_tile(anchor_chunk, layout["entry_local"] as Vector2i), "dungeon entry world coordinate matches its generated exit marker")
	_assert_equal(generator.boss_world_tile(), WorldCoordinates.chunk_local_to_tile(anchor_chunk, layout["boss_local"] as Vector2i), "Boss occupies the final generated room")
	var neighbor := generator.generate_chunk(anchor_chunk + Vector2i.RIGHT)
	_assert_equal(neighbor.dungeon_cell_map.count(DungeonGenerator.Cell.WALL), 1024, "finite dungeon seals every chunk outside its active room map")
	var planner := EnemySpawnPlanner.new(seed)
	var enemy_candidates := planner.candidates_for_dungeon(chunk, dungeon_id, {})
	var elite_candidates := 0
	var boss_candidates := 0
	for candidate_value in enemy_candidates:
		var candidate := candidate_value as Dictionary
		elite_candidates += 1 if candidate["enemy_id"] == &"dungeon_sentinel" else 0
		boss_candidates += 1 if candidate["enemy_id"] == &"dungeon_warden" else 0
	_assert_true(enemy_candidates.size() == 3 and elite_candidates == 2 and boss_candidates == 1, "dungeon feature map creates exactly two elite enemies and one Boss")
	var state := DungeonRunState.new()
	var first_run := state.begin(dungeon_id, anchor_chunk, Vector2(-512.0, 928.0))
	_assert_true(int(first_run["attempt_count"]) == 1 and not bool(first_run["completed"]), "first dungeon entry starts attempt one incomplete")
	var key_key := DungeonGenerator.feature_key(dungeon_id, DungeonGenerator.Feature.KEY, entrance_tile + Vector2i.RIGHT)
	var door_key := DungeonGenerator.feature_key(dungeon_id, DungeonGenerator.Feature.LOCKED_DOOR, entrance_tile + Vector2i(2, 0))
	var trap_key := DungeonGenerator.feature_key(dungeon_id, DungeonGenerator.Feature.TRAP, entrance_tile + Vector2i(3, 0))
	var chest_key := DungeonGenerator.feature_key(dungeon_id, DungeonGenerator.Feature.CHEST, entrance_tile + Vector2i(4, 0))
	_assert_true(state.collect_key(key_key) and state.unlock_door(door_key), "collected dungeon key unlocks exactly one locked door")
	_assert_true(state.trigger_trap(trap_key) and not state.trigger_trap(trap_key), "dungeon trap triggers at most once per attempt")
	_assert_true(state.open_chest(chest_key) and not state.open_chest(chest_key), "dungeon chest opens at most once per attempt")
	var elite_spawn_id := String(enemy_candidates[0]["spawn_id"])
	var boss_spawn_id := ""
	for candidate_value in enemy_candidates:
		var candidate := candidate_value as Dictionary
		if candidate["enemy_id"] == &"dungeon_warden":
			boss_spawn_id = String(candidate["spawn_id"])
		elif elite_spawn_id.is_empty() or not elite_spawn_id.contains("elite"):
			elite_spawn_id = String(candidate["spawn_id"])
	_assert_true(bool(state.defeat_enemy(elite_spawn_id, &"elite")["changed"]), "elite defeat enters dungeon run state")
	var completion := state.defeat_enemy(boss_spawn_id, &"boss")
	_assert_true(bool(completion["changed"]) and bool(completion["completed"]), "dungeon Boss defeat completes the run")
	var saved_state := state.persistence_snapshot()
	var restored := DungeonRunState.new()
	_assert_true(restored.restore_snapshot(saved_state) and restored.persistence_snapshot() == saved_state, "active completed dungeon state round trips exactly")
	var completed_attempts := int(restored.current_run()["attempt_count"])
	var completed_leave := restored.leave_current()
	restored.begin(dungeon_id, anchor_chunk, Vector2(-512.0, 928.0))
	_assert_true(not bool(completed_leave["reset"]) and int(restored.current_run()["attempt_count"]) == completed_attempts and bool(restored.current_run()["completed"]), "completed dungeon state persists across exit and re-entry")
	var incomplete := DungeonRunState.new()
	incomplete.begin("dungeon_8_-9", Vector2i.ZERO, Vector2.ZERO)
	incomplete.collect_key("dungeon_8_-9:key:1:1")
	incomplete.open_chest("dungeon_8_-9:chest:2:2")
	var incomplete_leave := incomplete.leave_current()
	var second_attempt := incomplete.begin("dungeon_8_-9", Vector2i.ZERO, Vector2.ZERO)
	_assert_true(bool(incomplete_leave["reset"]) and int(second_attempt["attempt_count"]) == 2 and int(second_attempt["key_count"]) == 0 and (second_attempt["opened_chests"] as Array).is_empty(), "leaving an incomplete dungeon resets transient progress before attempt two")
	var deterministic_loot := catalog.chest_loot(chest_key)
	_assert_true(not deterministic_loot.is_empty() and deterministic_loot == DungeonCatalog.new().chest_loot(chest_key), "dungeon chest loot is deterministic and data-driven")


func _test_exploration_models() -> void:
	var catalog := RegionalBossCatalog.new()
	_assert_true(catalog.is_valid() and catalog.bosses().size() == 4, "V4.1 regional Boss catalog validates exactly four encounters")
	var seed := WorldSeed.from_text("V2.0-exploration-fixture")
	var planner := RegionalBossPlanner.new(seed, catalog)
	var plans := planner.plans()
	_assert_equal(plans, RegionalBossPlanner.new(seed, catalog).plans(), "regional Boss plans are deterministic across restarts")
	_assert_equal(plans.size(), 4, "regional planner resolves all four Boss locations")
	var planned_ids := {}
	var planned_chunks := {}
	var terrain := TerrainGenerator.new(seed)
	for plan_value in plans:
		var plan := plan_value as Dictionary
		planned_ids[String(plan["id"])] = true
		planned_chunks[plan["chunk_position"]] = true
		if String(plan["id"]) == "tide_sovereign":
			var boss_terrain := terrain.terrain_at(plan["world_tile"] as Vector2i)
			_assert_true(boss_terrain == ChunkData.Terrain.SHALLOW_WATER or boss_terrain == ChunkData.Terrain.DEEP_WATER, "tide sovereign anchors in open water")
		else:
			_assert_true(terrain.terrain_at(plan["world_tile"] as Vector2i) == ChunkData.Terrain.LAND, "%s regional Boss occupies dry land" % plan["id"])
	_assert_true(planned_ids.size() == 4 and planned_chunks.size() == 4, "regional Boss IDs and locations are unique")
	var state := ExplorationMapState.new()
	var center := Vector2i(-3, 5)
	_assert_true(state.reveal_chunk(center, 1) and state.discovered_count() == 9, "exploration fog reveals a bounded 3×3 neighborhood")
	var center_tile := WorldCoordinates.chunk_local_to_tile(center, Vector2i(16, 16))
	_assert_true(state.register_marker("village:test", &"village", "测试村庄", center_tile, "e6c46a", true), "discovered landmark registers on the world map")
	_assert_true(not state.register_marker("hidden:test", &"ruin", "迷雾遗迹", Vector2i(9999, 9999)), "markers cannot leak through undiscovered fog")
	var custom_id := state.add_custom_marker(center_tile + Vector2i.ONE)
	_assert_true(not custom_id.is_empty() and state.custom_marker_count() == 1, "custom marker is created only inside discovered territory")
	_assert_true(state.travel_world_position("village:test").is_finite() and not state.travel_world_position(custom_id).is_finite(), "only explicit travel points expose fast-travel positions")
	_assert_true(state.mark_completed("village:test") and bool(state.marker("village:test")["completed"]), "landmark completion is stored independently from discovery")
	var restored := ExplorationMapState.new()
	_assert_true(restored.restore_snapshot(state.persistence_snapshot()) and restored.persistence_snapshot() == state.persistence_snapshot(), "fog, landmarks and custom markers round trip exactly")
	var duplicate_next_id := state.persistence_snapshot()
	duplicate_next_id["next_custom_id"] = 1
	_assert_true(not ExplorationMapState.new().restore_snapshot(duplicate_next_id), "exploration validation rejects a custom-marker ID that would be reused")
	_assert_true(restored.remove_custom_marker(custom_id) and restored.custom_marker_count() == 0, "custom marker can be removed without affecting landmarks")
	var boss_state := RegionalBossState.new()
	_assert_true(boss_state.defeat(&"grove_titan") and not boss_state.defeat(&"grove_titan"), "regional Boss completion is one-time")
	var restored_bosses := RegionalBossState.new()
	_assert_true(restored_bosses.restore_snapshot(boss_state.persistence_snapshot()) and restored_bosses.is_defeated(&"grove_titan"), "regional Boss completion round trips exactly")
	var scanner := WorldDiscoveryScanner.new(seed)
	var boss_markers := scanner.markers_for_chunk(plans[0]["chunk_position"] as Vector2i)
	var found_planned_boss := false
	for marker_value in boss_markers:
		var marker := marker_value as Dictionary
		if String(marker.get("id", "")) == "boss:%s" % plans[0]["id"]:
			found_planned_boss = true
	_assert_true(found_planned_boss, "world discovery scanner publishes the deterministic regional Boss marker")


func _test_event_bus_contract() -> void:
	_assert_true(EventBus.has_signal("scene_change_requested"), "scene signal exists")
	_assert_true(EventBus.has_signal("settings_changed"), "settings signal exists")
	_assert_true(EventBus.has_signal("notification_requested"), "notification signal exists")
	_assert_true(EventBus.has_signal("resource_prompt_changed"), "resource prompt signal exists")
	_assert_true(EventBus.has_signal("inventory_changed"), "inventory signal exists")
	_assert_true(EventBus.has_signal("inventory_state_changed"), "slot inventory signal exists")
	_assert_true(EventBus.has_signal("crafting_state_changed"), "crafting recipe-view signal exists")
	_assert_true(EventBus.has_signal("attack_started"), "attack lifecycle signal exists")
	_assert_true(EventBus.has_signal("combat_status_changed"), "combat status signal exists")
	_assert_true(EventBus.has_signal("combat_feedback"), "combat feedback signal exists")
	_assert_true(EventBus.has_signal("grave_state_changed"), "grave state signal exists")
	_assert_true(EventBus.has_signal("enemy_state_changed"), "enemy population signal exists")
	_assert_true(EventBus.has_signal("time_state_changed"), "time-cycle signal exists")
	_assert_true(EventBus.has_signal("weather_state_changed"), "weather-state signal exists")
	_assert_true(EventBus.has_signal("season_state_changed"), "season-state signal exists")
	_assert_true(EventBus.has_signal("world_layer_changed"), "world-layer signal exists")
	_assert_true(EventBus.has_signal("milestone_state_changed"), "milestone progression signal exists")
	_assert_true(EventBus.has_signal("dungeon_state_changed"), "dungeon progression signal exists")
	_assert_true(EventBus.has_signal("exploration_state_changed"), "exploration map signal exists")
	_assert_true(EventBus.has_signal("npc_interaction_requested") and EventBus.has_signal("npc_state_changed"), "NPC interaction signals exist")
	_assert_true(EventBus.has_signal("relationship_state_changed"), "relationship state signal exists")
	_assert_true(EventBus.has_signal("quest_state_changed"), "quest state signal exists")
	_assert_true(EventBus.has_signal("world_choice_state_changed"), "world-choice state signal exists")
	_assert_true(EventBus.has_signal("faction_state_changed"), "faction state signal exists")
	_assert_true(EventBus.has_signal("world_event_state_changed"), "world-event state signal exists")
	_assert_true(EventBus.has_signal("region_progression_state_changed"), "region-progression state signal exists")
	_assert_true(EventBus.has_signal("survival_state_changed"), "survival state signal exists")
	_assert_true(EventBus.has_signal("building_state_changed"), "building state signal exists")
	_assert_true(EventBus.has_signal("farming_state_changed"), "farming state signal exists")
	_assert_true(EventBus.has_signal("husbandry_state_changed"), "husbandry state signal exists")
	_assert_true(EventBus.has_signal("processing_state_changed"), "processing state signal exists")
	_assert_true(EventBus.has_signal("equipment_state_changed"), "equipment state signal exists")
	_assert_true(EventBus.has_signal("automation_state_changed"), "automation state signal exists")
	_assert_true(EventBus.has_signal("homestead_state_changed"), "homestead state signal exists")
	_assert_true(EventBus.has_signal("sleep_requested"), "sleep request signal exists")
	_assert_true(EventBus.has_signal("save_status_changed"), "save status signal exists")


func _test_settings_round_trip() -> void:
	var original: Variant = SettingsManager.get_value("accessibility/reduce_motion", false)
	SettingsManager.set_value("accessibility/reduce_motion", not bool(original), false)
	_assert_equal(SettingsManager.get_value("accessibility/reduce_motion"), not bool(original), "settings mutate")
	SettingsManager.set_value("accessibility/reduce_motion", original, false)
	var original_survival := bool(SettingsManager.get_value("gameplay/survival_enabled", true))
	SettingsManager.set_value("gameplay/survival_enabled", not original_survival, false)
	_assert_equal(SettingsManager.get_value("gameplay/survival_enabled"), not original_survival, "survival rules can be disabled in settings")
	SettingsManager.set_value("gameplay/survival_enabled", original_survival, false)
	_assert_true(SettingsManager.save_settings(), "settings save")


func _test_scene_transition_contract() -> void:
	_assert_true(ResourceLoader.exists(GameManager.MAIN_MENU_SCENE), "manager main scene path")
	_assert_true(ResourceLoader.exists(GameManager.GAME_SCENE), "manager game scene path")


func _test_player_motor_frame_independence() -> void:
	var direction := Vector2(1.0, 0.35)
	var at_30 := PlayerMotor.integrated_distance(direction, false, 30, 1.0)
	var at_60 := PlayerMotor.integrated_distance(direction, false, 60, 1.0)
	var at_120 := PlayerMotor.integrated_distance(direction, false, 120, 1.0)
	_assert_true(at_30.is_equal_approx(at_60) and at_60.is_equal_approx(at_120), "movement is frame-rate independent at 30/60/120 FPS")
	_assert_true(is_equal_approx(PlayerMotor.velocity_for(Vector2.ONE, false).length(), PlayerMotor.WALK_SPEED), "diagonal movement is normalized")
	_assert_true(PlayerMotor.velocity_for(Vector2.RIGHT, true).length() > PlayerMotor.velocity_for(Vector2.RIGHT, false).length(), "run speed exceeds walk speed")


func _test_world_seed_contract() -> void:
	var stable_seed := WorldSeed.from_text("无尽边境")
	_assert_equal(stable_seed, 6266252184503203218, "text seed has a platform-stable fixture")
	_assert_equal(WorldSeed.from_text("无尽边境"), stable_seed, "same text produces same 64-bit seed")
	_assert_equal(WorldSeed.from_text("-42"), -42, "numeric text preserves numeric seed")
	_assert_true(WorldSeed.derive(stable_seed, &"elevation") != WorldSeed.derive(stable_seed, &"detail"), "derived systems use independent seeds")
	_assert_true(WorldSeed.for_chunk(stable_seed, &"surface", Vector2i(-1, -1), &"terrain") != WorldSeed.for_chunk(stable_seed, &"surface", Vector2i(0, -1), &"terrain"), "coordinate seeds include signed chunk coordinates")


func _test_world_coordinate_contract() -> void:
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(31, 31)), Vector2i(0, 0), "positive tile maps to origin chunk")
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(-1, -1)), Vector2i(-1, -1), "negative edge maps with floor division")
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(-33, 64)), Vector2i(-2, 2), "negative multi-chunk coordinate maps correctly")
	_assert_equal(WorldCoordinates.tile_to_local(Vector2i(-1, -33)), Vector2i(31, 31), "negative tile has positive local coordinate")
	var tile := Vector2i(-65, 97)
	_assert_equal(WorldCoordinates.chunk_local_to_tile(WorldCoordinates.tile_to_chunk(tile), WorldCoordinates.tile_to_local(tile)), tile, "chunk/local conversion round trips")
	_assert_equal(WorldCoordinates.chunk_key(&"surface", Vector2i(-2, 3)), "surface_-2_3", "chunk key preserves layer and signs")


func _test_biome_catalog_contract() -> void:
	var catalog := BiomeCatalog.new()
	_assert_true(catalog.is_valid(), "external biome configuration loads and validates")
	_assert_equal(catalog.biome_count(), 13, "catalog contains eight land biomes, the island biome, coast and two ocean depths")
	for biome_id in BiomeCatalog.REQUIRED_IDS:
		_assert_true(catalog.has_biome(biome_id), "catalog contains stable biome ID %s" % biome_id)
	_assert_true(catalog.threshold("deep_water") < catalog.threshold("shallow_water") and catalog.threshold("shallow_water") < catalog.threshold("coast"), "data-driven terrain thresholds are ordered")
	_assert_equal(catalog.classify_land(0.12, 0.50, 0.52, 0.50), catalog.code_for_id(&"snowfield"), "temperature rule selects snowfield")
	_assert_equal(catalog.classify_land(0.80, 0.12, 0.52, 0.50), catalog.code_for_id(&"desert"), "hot dry rule selects desert")
	_assert_equal(catalog.classify_land(0.62, 0.82, 0.52, 0.50), catalog.code_for_id(&"swamp"), "warm wet lowland rule selects swamp")
	_assert_equal(catalog.classify_land(0.52, 0.78, 0.64, 0.72), catalog.code_for_id(&"forest"), "wet rule selects forest outside swamp")
	_assert_equal(catalog.classify_land(0.52, 0.42, 0.82, 0.40), catalog.code_for_id(&"mountain"), "high low-erosion rule selects mountain")
	_assert_equal(catalog.classify_land(0.70, 0.30, 0.52, 0.50), catalog.code_for_id(&"plains"), "transition band routes a biome edge through plains")


func _test_resource_catalog_contract() -> void:
	var catalog := ResourceCatalog.new()
	_assert_true(catalog.is_valid(), "external resource configuration loads and validates")
	_assert_equal(catalog.resource_count(), 12, "resource catalog contains five surface resources, three cave veins and four ocean resources")
	for resource_id in ResourceCatalog.REQUIRED_RESOURCE_IDS:
		_assert_true(catalog.has_resource(resource_id), "catalog contains stable resource ID %s" % resource_id)
	for resource_id in [&"coal_vein", &"copper_vein", &"iron_vein"]:
		_assert_true(catalog.has_resource(resource_id), "catalog contains cave resource ID %s" % resource_id)
	_assert_equal(catalog.tool_ids(), [&"hands", &"axe", &"pickaxe"], "tool order is data-driven and stable")
	_assert_equal(catalog.required_tool_for_code(catalog.code_for_id(&"tree")), &"axe", "trees require an axe")
	_assert_equal(catalog.required_tool_for_code(catalog.code_for_id(&"rock")), &"pickaxe", "rocks require a pickaxe")
	var flower_code := catalog.code_for_id(&"flower")
	_assert_true(catalog.available_in_phase(flower_code, &"NIGHT") and not catalog.available_in_phase(flower_code, &"DAY"), "moonflowers are collectible only at night")
	_assert_true(catalog.water_candidate_code(ChunkData.Terrain.DEEP_WATER, 0.0, &"deep_ocean") >= 0, "deep ocean exposes coral and driftwood on the water resource channel")
	_assert_true(catalog.drop_pool_capacity() == 32 and catalog.max_resources_per_chunk() == 128, "resource and drop limits come from configuration")


func _test_item_catalog_contract() -> void:
	var catalog := ItemCatalog.new()
	_assert_true(catalog.is_valid(), "external item configuration loads and validates")
	_assert_equal(catalog.slot_count(), 24, "inventory capacity is data-driven at 24 slots")
	_assert_equal(catalog.hotbar_slot_count(), 8, "hotbar exposes the first eight inventory slots")
	var ids := catalog.item_ids()
	_assert_equal(ids.size(), 81, "item catalog contains 81 unique exploration, production, equipment, automation and ocean item IDs")
	for item_id in ItemCatalog.REQUIRED_ITEM_IDS:
		_assert_true(ids.has(StringName(item_id)), "item catalog contains stable unique ID %s" % item_id)
	_assert_true(catalog.has_item(&"moonpetal"), "night-only moonpetal is a stable inventory item")
	_assert_true(catalog.has_item(&"coal") and catalog.has_item(&"copper_ore") and catalog.has_item(&"iron_ore"), "cave minerals are stable inventory items")
	_assert_equal(catalog.category_name(&"wood"), "材料", "wood exposes its item category")
	_assert_equal(catalog.category_name(&"berry"), "食物", "berry exposes its item category")
	_assert_true(catalog.maximum_stack(&"wood") == 50 and catalog.maximum_stack(&"berry") == 20, "stack limits come from item data resources")
	_assert_true(catalog.tool_kind(&"wood_axe") == &"axe" and catalog.tool_power(&"stone_axe") == 2, "wood and stone tool kinds/power are data-driven")
	_assert_true(catalog.maximum_durability(&"wood_pickaxe") == 30 and catalog.maximum_durability(&"stone_pickaxe") == 60, "tool durability comes from item resources")
	_assert_true(catalog.station_kind(&"workbench") == &"workbench" and catalog.station_kind(&"campfire") == &"campfire", "workbench and campfire are stable station items")
	_assert_true(catalog.maximum_stack(&"slime_gel") == 50 and catalog.has_item(&"wolf_pelt") and catalog.has_item(&"bat_wing"), "enemy drops are stable stackable item IDs")
	_assert_true(catalog.maximum_stack(&"ancient_core") == 10 and catalog.category_name(&"ancient_core") == "奖励", "Boss reward is a stable stackable item ID")
	_assert_true(catalog.maximum_stack(&"dungeon_relic") == 10 and catalog.category_name(&"dungeon_relic") == "奖励", "dungeon Boss relic is a stable stackable reward")
	_assert_true(catalog.has_item(&"grove_sigil") and catalog.has_item(&"dune_sigil") and catalog.has_item(&"frost_sigil"), "three regional Boss sigils are stable rewards")
	_assert_true(catalog.maximum_stack(&"coin") == 999 and catalog.category_name(&"coin") == "货币", "NPC economy uses a stable stackable currency item")
	_assert_true(catalog.has_item(&"wheat_seed") and catalog.has_item(&"apple_sapling") and catalog.has_item(&"basic_fertilizer"), "seed, sapling and fertilizer inputs are stable inventory items")
	_assert_true(catalog.has_item(&"wheat") and catalog.has_item(&"silver_carrot") and catalog.has_item(&"gold_apple"), "normal, silver and gold harvest outputs are stable inventory items")
	_assert_true(catalog.has_item(&"egg") and catalog.has_item(&"milk") and catalog.has_item(&"wool"), "egg, milk and wool are stable husbandry products")
	_assert_true(catalog.station_kind(&"cooking_pot") == &"cooking_pot" and catalog.station_kind(&"smelter") == &"smelter", "cooking pot and smelter are stable placeable processor items")
	_assert_true(catalog.category_name(&"antidote_potion") == "药水" and catalog.has_item(&"steel_ingot") and catalog.has_item(&"tempered_plate"), "processed recovery and equipment materials use stable inventory IDs")
	_assert_true(catalog.category_name(&"copper_helmet") == "护甲" and catalog.category_name(&"explorer_charm") == "饰品" and catalog.maximum_durability(&"iron_sword") == 160, "weapons, armor and accessories expose stable categories and durability")
	_assert_true(catalog.has_item(&"conveyor_belt") and catalog.has_item(&"automatic_smelter") and catalog.has_item(&"storage_link") and catalog.has_item(&"item_sorter"), "four automation machines are stable craftable inventory items")


func _test_inventory_model() -> void:
	var inventory := InventoryModel.new()
	var wood_result := inventory.add_item(&"wood", 55)
	_assert_true(int(wood_result["accepted"]) == 55 and int(wood_result["remainder"]) == 0, "inventory accepts a quantity across stack boundaries")
	_assert_true(int(inventory.slot(0)["quantity"]) == 50 and int(inventory.slot(1)["quantity"]) == 5, "wood stacks at its exact configured limit")
	inventory.add_item(&"stone", 3)
	var before_drag := inventory.count_snapshot()
	_assert_true(inventory.move_or_swap(1, 2), "drag operation swaps unlike occupied stacks")
	_assert_equal(inventory.count_snapshot(), before_drag, "drag swap preserves every item and quantity")
	_assert_true(inventory.split_stack(0, 3), "right-click split moves half a stack to an empty slot")
	_assert_true(int(inventory.slot(0)["quantity"]) == 25 and int(inventory.slot(3)["quantity"]) == 25, "stack split quantities are exact")
	_assert_true(inventory.move_or_swap(2, 3), "dragging like items combines into available stack space")
	_assert_equal(inventory.quantity(&"wood"), 55, "combine and split never duplicate or lose wood")
	_assert_true(inventory.select_hotbar(7), "eighth hotbar slot can be selected")
	var exact_snapshot := inventory.snapshot()
	var exact_checksum := inventory.checksum()
	var restored := InventoryModel.new()
	_assert_true(restored.restore_snapshot(exact_snapshot), "versioned slot snapshot validates and restores")
	_assert_equal(restored.snapshot(), exact_snapshot, "save/load restores identical slot order and quantities")
	_assert_equal(restored.checksum(), exact_checksum, "save/load inventory checksum is byte-stable")
	var removed := restored.discard(3, 7)
	_assert_true(String(removed.get("item_id", "")) == "wood" and int(removed.get("quantity", 0)) == 7, "discard returns the exact removed item stack")
	_assert_equal(restored.quantity(&"wood"), 48, "discard decrements the source without duplication")
	var counts_before_sort := restored.count_snapshot()
	restored.sort_inventory()
	_assert_equal(restored.count_snapshot(), counts_before_sort, "inventory sort preserves all item totals")
	var full_inventory := InventoryModel.new()
	var fill_result := full_inventory.add_item(&"wood", 24 * 50)
	var overflow := full_inventory.add_item(&"stone", 1)
	_assert_true(int(fill_result["remainder"]) == 0 and bool(overflow["full"]) and int(overflow["remainder"]) == 1, "full inventory returns an explicit unaccepted remainder")
	var invalid_snapshot := exact_snapshot.duplicate(true)
	(invalid_snapshot["slots"] as Array)[0] = {"item_id": "wood", "quantity": 51}
	_assert_true(not InventoryModel.new().restore_snapshot(invalid_snapshot), "invalid over-limit stack is rejected instead of silently coerced")
	var migrated := InventoryModel.new()
	_assert_true(migrated.restore_legacy_counts({"wood": 7, "stone": 3}), "V0.7 count dictionary migrates into V0.8 slots")
	_assert_true(migrated.quantity(&"wood") == 7 and migrated.quantity(&"stone") == 3, "legacy migration preserves exact item totals")


func _test_recipe_catalog_contract() -> void:
	var catalog := RecipeCatalog.new()
	_assert_true(catalog.is_valid(), "external recipe configuration loads and validates")
	_assert_equal(catalog.station_ids(), [&"hands", &"workbench", &"campfire"], "hands, workbench and campfire stations are data-driven")
	_assert_equal(catalog.recipes().size(), 30, "crafting catalog includes tools, stations, farming inputs, equipment, four automation recipes and ocean recipes")
	_assert_true(catalog.recipe(&"wood_axe") != null and catalog.recipe(&"stone_pickaxe") != null, "wooden and stone tool recipes use stable IDs")
	_assert_true(catalog.recipe(&"torch").output_quantity == 2, "torch recipe produces its configured output quantity")
	_assert_true(catalog.recipe(&"wheat_seed") != null and catalog.recipe(&"apple_sapling") != null and catalog.recipe(&"basic_fertilizer") != null, "seeds, fruit-tree sapling and fertilizer have playable crafting sources")
	_assert_true(catalog.recipe(&"smelter") != null and catalog.recipe(&"cooking_pot") != null, "both processing stations have playable workbench recipes")
	_assert_true(catalog.recipe(&"copper_sword") != null and catalog.recipe(&"copper_chestplate") != null and catalog.recipe(&"frost_ring") != null, "weapon, armor and accessory recipes are playable")
	_assert_true(catalog.recipe(&"conveyor_belt") != null and catalog.recipe(&"automatic_smelter") != null and catalog.recipe(&"storage_link") != null and catalog.recipe(&"item_sorter") != null, "all automation machines have playable workbench recipes")


func _test_crafting_system() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"branch", 2)
	inventory.add_item(&"fiber", 2)
	var crafting := CraftingSystem.new(inventory)
	crafting.refresh_discoveries()
	_assert_true(crafting.is_unlocked(&"wood_axe"), "discovering branch and fiber unlocks the wooden axe recipe")
	var before_insufficient := inventory.snapshot()
	var insufficient := crafting.craft(&"wood_axe")
	_assert_true(not bool(insufficient["ok"]) and "材料不足" in String(insufficient["message"]), "insufficient materials prevent crafting with an explicit reason")
	_assert_equal(inventory.snapshot(), before_insufficient, "failed crafting consumes no materials")
	inventory.add_item(&"branch", 1)
	var crafted_wood := crafting.craft(&"wood_axe")
	_assert_true(bool(crafted_wood["ok"]), "hands crafting creates a wooden axe after requirements are met")
	_assert_true(inventory.quantity(&"branch") == 0 and inventory.quantity(&"fiber") == 0, "successful crafting deducts the exact wooden-axe materials")
	var wood_axe_slot := _find_item_slot(inventory, &"wood_axe")
	_assert_true(wood_axe_slot >= 0 and int(inventory.slot(wood_axe_slot)["durability"]) == 30, "crafted wooden axe starts at full durability")
	_assert_true(not crafting.station_available(&"workbench") and not crafting.is_unlocked(&"stone_axe"), "stone tools stay locked without a workbench")
	inventory.add_item(&"workbench", 1)
	inventory.add_item(&"branch", 10)
	inventory.add_item(&"stone", 10)
	inventory.add_item(&"fiber", 10)
	crafting.refresh_discoveries()
	_assert_true(crafting.station_available(&"workbench") and crafting.is_unlocked(&"stone_axe"), "possessing a workbench and discovering stone unlocks stone tools")
	var branch_before := inventory.quantity(&"branch")
	var stone_before := inventory.quantity(&"stone")
	var fiber_before := inventory.quantity(&"fiber")
	_assert_true(bool(crafting.craft(&"stone_axe")["ok"]), "workbench crafts a stone axe")
	_assert_true(inventory.quantity(&"branch") == branch_before - 2 and inventory.quantity(&"stone") == stone_before - 4 and inventory.quantity(&"fiber") == fiber_before - 2, "stone axe deducts every material exactly once")
	var stone_axe_slot := _find_item_slot(inventory, &"stone_axe")
	_assert_true(stone_axe_slot >= 0 and int(inventory.slot(stone_axe_slot)["durability"]) == 60, "crafted stone axe starts at full durability")
	inventory.add_item(&"campfire", 1)
	inventory.add_item(&"berry", 3)
	crafting.refresh_discoveries()
	_assert_true(crafting.station_available(&"campfire") and bool(crafting.craft(&"cooked_berries")["ok"]), "campfire crafts the basic cooked-berry food")
	_assert_true(inventory.quantity(&"berry") == 0 and inventory.quantity(&"cooked_berries") == 1, "basic food recipe deducts berries and adds one output")
	var unlock_snapshot := crafting.persistence_snapshot()
	var restored_unlocks := CraftingSystem.new(InventoryModel.new())
	_assert_true(restored_unlocks.restore_snapshot(unlock_snapshot) and restored_unlocks.is_unlocked(&"wood_axe"), "discovery unlock conditions persist after materials are spent")
	var full_inventory := InventoryModel.new()
	for _index in 22:
		full_inventory.add_item(&"wood_sword", 1)
	full_inventory.add_item(&"wood", 50)
	full_inventory.add_item(&"fiber", 50)
	var full_crafting := CraftingSystem.new(full_inventory)
	full_crafting.refresh_discoveries()
	var full_counts := full_inventory.count_snapshot()
	var no_space := full_crafting.craft(&"torch")
	_assert_true(not bool(no_space["ok"]) and "空间不足" in String(no_space["message"]), "crafting rejects an output when no slot can receive it")
	_assert_equal(full_inventory.count_snapshot(), full_counts, "no-space crafting transaction deducts nothing")


func _test_tool_speed_and_durability() -> void:
	var resource_catalog := ResourceCatalog.new()
	var tree_code := resource_catalog.code_for_id(&"tree")
	var wood_state := ResourceHarvestState.new()
	var stone_state := ResourceHarvestState.new()
	var wood_hit := wood_state.hit("100:100:%d" % tree_code, tree_code, &"axe", resource_catalog, 1)
	var stone_hit := stone_state.hit("101:100:%d" % tree_code, tree_code, &"axe", resource_catalog, 2)
	_assert_true(int(wood_hit["remaining"]) == 2 and int(stone_hit["remaining"]) == 1, "stone tool power harvests the same resource faster than wood")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood_axe", 1)
	var tool_slot := _find_item_slot(inventory, &"wood_axe")
	for _index in 29:
		inventory.damage_tool_at(tool_slot, 1)
	_assert_equal(int(inventory.slot(tool_slot)["durability"]), 1, "tool durability decrements exactly once per accepted use")
	var broken := inventory.damage_tool_at(tool_slot, 1)
	_assert_true(bool(broken["broken"]) and inventory.slot(tool_slot).is_empty(), "tool is removed cleanly when durability reaches zero")
	var sort_inventory := InventoryModel.new()
	sort_inventory.add_item(&"stone_pickaxe", 1)
	var pickaxe_slot := _find_item_slot(sort_inventory, &"stone_pickaxe")
	sort_inventory.damage_tool_at(pickaxe_slot, 7)
	sort_inventory.add_item(&"wood", 4)
	sort_inventory.sort_inventory()
	pickaxe_slot = _find_item_slot(sort_inventory, &"stone_pickaxe")
	_assert_equal(int(sort_inventory.slot(pickaxe_slot)["durability"]), 53, "inventory sorting preserves individual tool durability")


func _test_weapon_catalog_contract() -> void:
	var catalog := WeaponCatalog.new()
	_assert_true(catalog.is_valid(), "external weapon configuration loads and validates")
	_assert_equal(catalog.weapon_ids(), [&"unarmed", &"wood_sword", &"stone_sword", &"copper_sword", &"iron_sword"], "five weapon IDs are unique, stable and data-driven")
	var unarmed := catalog.weapon(&"unarmed")
	var wooden := catalog.weapon(&"wood_sword")
	var stone := catalog.weapon(&"stone_sword")
	var iron := catalog.weapon(&"iron_sword")
	_assert_true(unarmed != null and wooden != null and stone != null and iron != null, "unarmed and four craftable sword definitions exist")
	_assert_true(stone.damage > wooden.damage and wooden.damage > unarmed.damage, "weapon damage progression increases by material tier")
	_assert_true(stone.attack_range > unarmed.attack_range and stone.knockback > wooden.knockback, "weapon range and knockback come from weapon data")
	_assert_equal(stone.combo_count(), 3, "stone sword exposes the planned three-hit combo")
	_assert_true(iron.damage > stone.damage and iron.attack_range > stone.attack_range, "refined-metal weapons extend damage and reach progression")


func _test_attack_sequence_and_damage() -> void:
	var definition := WeaponCatalog.new().weapon(&"wood_sword")
	var sequence := AttackSequenceModel.new()
	var first := sequence.request_attack(definition, Vector2.RIGHT)
	_assert_true(bool(first["ok"]) and int(first["combo_index"]) == 1, "normal attack starts the first combo step")
	_assert_true((first["direction"] as Vector2).is_equal_approx(Vector2.RIGHT), "attack direction follows normalized player facing")
	_assert_true((first["hitbox_position"] as Vector2).is_equal_approx(Vector2(definition.attack_range * 0.5, 0.0)) and is_zero_approx(float(first["hitbox_rotation"])), "directional hitbox is centered in front of the player")
	_assert_true(sequence.register_target_hit(101), "active attack accepts its first target hit")
	_assert_true(not sequence.register_target_hit(101), "same attack cannot hit the same target twice")
	_assert_true(not bool(sequence.request_attack(definition, Vector2.RIGHT)["ok"]), "attack cooldown rejects an early repeated input")
	sequence.tick(definition.cooldown() + 0.01)
	var second := sequence.request_attack(definition, Vector2.DOWN)
	_assert_true(bool(second["ok"]) and int(second["combo_index"]) == 2, "attack inside the combo window advances the chain")
	_assert_true(sequence.register_target_hit(101), "new attack ID may hit the same target again")
	sequence.tick(AttackSequenceModel.COMBO_RESET_SECONDS + 0.01)
	var reset := sequence.request_attack(definition, Vector2.LEFT)
	_assert_true(bool(reset["ok"]) and int(reset["combo_index"]) == 1, "expired combo window resets to the first attack")
	_assert_equal(DamageCalculator.calculate(20.0, 5.0), 17, "damage formula applies the documented defense coefficient")
	_assert_equal(DamageCalculator.calculate(2.0, 999.0), 1, "defense calculation preserves minimum one damage")


func _test_player_combat_state_and_graves() -> void:
	var combat := PlayerCombatState.new()
	combat.defense = 5.0
	combat.respawn_position = Vector2(-64.0, 96.0)
	var first_hit := combat.apply_hit(30.0, 100.0, 20.0, Vector2.RIGHT, 180.0)
	_assert_true(bool(first_hit["accepted"]) and int(first_hit["damage"]) == 17 and float(first_hit["health"]) == 13.0, "incoming hit applies attack, defense and health exactly")
	_assert_equal(first_hit["knockback"], Vector2(180.0, 0.0), "accepted hit applies directional knockback")
	var blocked := combat.apply_hit(13.0, 100.0, 20.0, Vector2.RIGHT, 180.0)
	_assert_true(not bool(blocked["accepted"]), "hit invulnerability rejects overlapping damage")
	combat.tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	var lethal := combat.apply_hit(13.0, 100.0, 99.0, Vector2.LEFT, 0.0)
	_assert_true(bool(lethal["died"]) and combat.status == &"dead" and combat.death_count == 1, "lethal damage enters death state exactly once")
	combat.respawn()
	_assert_true(combat.status == &"alive" and combat.invulnerability_remaining > 0.0, "respawn restores alive state with protection")
	var combat_snapshot := combat.persistence_snapshot()
	var restored_combat := PlayerCombatState.new()
	_assert_true(restored_combat.restore_snapshot(combat_snapshot) and restored_combat.persistence_snapshot() == combat_snapshot, "combat status round trip preserves defense, deaths and respawn position")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood", 7)
	inventory.add_item(&"stone_sword", 1)
	var sword_slot := _find_item_slot(inventory, &"stone_sword")
	inventory.damage_tool_at(sword_slot, 9)
	var graves := GraveModel.new()
	var grave := graves.deposit(Vector2(-128.0, 256.0), inventory)
	_assert_true(not grave.is_empty() and inventory.is_empty() and graves.grave_count() == 1, "death deposit moves the complete inventory into one grave")
	var grave_snapshot := graves.persistence_snapshot()
	var restored_graves := GraveModel.new()
	_assert_true(restored_graves.restore_snapshot(grave_snapshot), "grave state validates and restores")
	_assert_equal(String(restored_graves.graves()[0]["world_layer"]), "surface", "legacy-compatible grave deposits default to the surface layer")
	var underground_inventory := InventoryModel.new()
	underground_inventory.add_item(&"coal", 2)
	var underground_grave := restored_graves.deposit(Vector2(-128.0, 256.0), underground_inventory, &"underground")
	_assert_equal(int(restored_graves.nearest_grave(Vector2(-130.0, 255.0), 8.0)["id"]), int(grave["id"]), "nearest grave uses world-space distance")
	_assert_equal(int(restored_graves.nearest_grave(Vector2(-130.0, 255.0), 8.0, &"underground")["id"]), int(underground_grave["id"]), "grave lookup never crosses between surface and underground layers")
	var layered_graves := GraveModel.new()
	_assert_true(layered_graves.restore_snapshot(restored_graves.persistence_snapshot()) and String(layered_graves.graves()[1]["world_layer"]) == "underground", "grave persistence preserves its exact world layer")
	var dungeon_inventory := InventoryModel.new()
	dungeon_inventory.add_item(&"dungeon_relic", 1)
	var dungeon_grave := restored_graves.deposit(Vector2(-128.0, 256.0), dungeon_inventory, &"dungeon_-17_29")
	_assert_equal(int(restored_graves.nearest_grave(Vector2(-130.0, 255.0), 8.0, &"dungeon_-17_29")["id"]), int(dungeon_grave["id"]), "grave lookup scopes identical dungeon coordinates to one dungeon ID")
	_assert_true(restored_graves.nearest_grave(Vector2(-130.0, 255.0), 8.0, &"dungeon_8_-9").is_empty(), "grave lookup never leaks across different procedural dungeons")
	var reclaimed_inventory := InventoryModel.new()
	var reclaimed := restored_graves.reclaim(int(grave["id"]), reclaimed_inventory)
	var reclaimed_sword_slot := _find_item_slot(reclaimed_inventory, &"stone_sword")
	_assert_true(bool(reclaimed["complete"]) and restored_graves.grave_count() == 2, "grave reclaim removes only the selected layer-specific grave")
	_assert_true(reclaimed_inventory.quantity(&"wood") == 7 and int(reclaimed_inventory.slot(reclaimed_sword_slot)["durability"]) == 71, "grave reclaim preserves exact item counts and weapon durability")


func _test_enemy_catalog_and_state_machine() -> void:
	var catalog := EnemyCatalog.new()
	_assert_true(catalog.is_valid(), "external enemy configuration loads and validates")
	_assert_equal(catalog.enemy_ids(), [&"slime", &"wolf", &"cave_bat", &"wild_boar", &"frost_sprite", &"bandit_scout", &"dungeon_sentinel", &"dungeon_warden", &"grove_titan", &"dune_behemoth", &"frost_wyrm", &"reef_fin", &"abyss_maw", &"tide_sovereign"], "enemy IDs are unique, stable and data-driven")
	_assert_true(catalog.maximum_active() == 18 and catalog.maximum_per_chunk() == 3, "enemy population hard limits come from data")
	_assert_equal(catalog.maximum_active_for_phase(&"NIGHT"), 27, "night population cap increases from data")
	_assert_true(not catalog.enemy(&"slime").is_available_in_phase(&"NIGHT") and catalog.enemy(&"cave_bat").is_available_in_phase(&"NIGHT"), "night phase replaces daytime slime candidates while cave bats remain active underground")
	_assert_true(catalog.enemy(&"slime").biomes == [&"plains", &"forest"], "slime biome rule is explicit")
	_assert_true(catalog.enemy(&"wolf").biomes.has(&"forest") and catalog.enemy(&"wolf").biomes.has(&"snowfield"), "wolf forest and snowfield rules are explicit")
	_assert_true(catalog.enemy(&"cave_bat").biomes == [&"mountain"] and catalog.enemy(&"cave_bat").world_layers == [&"underground"], "cave bat is restricted to the underground world layer")
	_assert_true(catalog.enemy(&"dungeon_sentinel").role == &"elite" and catalog.enemy(&"dungeon_warden").role == &"boss", "dungeon enemies expose explicit elite and Boss roles")
	_assert_true(catalog.enemy(&"dungeon_sentinel").world_layers == [&"dungeon"] and catalog.enemy(&"dungeon_warden").world_layers == [&"dungeon"], "dungeon enemies never leak into surface or cave populations")
	_assert_true(catalog.enemy(&"wild_boar").role == &"normal" and catalog.enemy(&"frost_sprite").role == &"normal", "V2.0 adds two normal regional enemy types")
	_assert_true(catalog.enemy(&"bandit_scout").role == &"normal" and catalog.enemy(&"bandit_scout").biomes.has(&"desert"), "V2.4 adds a surface ash-raider member")
	_assert_true(catalog.enemy(&"grove_titan").role == &"boss" and catalog.enemy(&"dune_behemoth").role == &"boss" and catalog.enemy(&"frost_wyrm").role == &"boss", "three surface regional Boss definitions are explicit")
	_assert_equal(catalog.enemy_id_for_biome(&"coast", 0.5), &"", "beach coast hosts no enemy type")
	var ocean_roll := catalog.enemy_id_for_biome(&"ocean", 0.5)
	_assert_true(not ocean_roll.is_empty() and catalog.enemy(ocean_roll).aquatic, "open water rolls only aquatic enemy types")
	var slime := catalog.enemy(&"slime")
	var machine := EnemyStateMachine.new(slime)
	machine.tick(EnemyStateMachine.IDLE_DURATION + 0.01, 999.0, 0.0)
	_assert_equal(machine.state_name(), &"WANDER", "enemy state machine enters deterministic wander")
	machine.tick(0.01, slime.detection_range - 1.0, 0.0)
	_assert_equal(machine.state_name(), &"ALERT", "nearby player moves enemy into alert")
	machine.tick(EnemyStateMachine.ALERT_DURATION + 0.01, slime.detection_range - 1.0, 0.0)
	_assert_equal(machine.state_name(), &"CHASE", "alert transitions into chase")
	machine.tick(0.01, slime.attack_range - 1.0, 0.0)
	_assert_equal(machine.state_name(), &"ATTACK", "chase enters attack at configured range")
	var attack_result := machine.tick(slime.attack_windup + 0.01, slime.attack_range - 1.0, 0.0)
	_assert_true(bool(attack_result["attack_ready"]) and machine.cooldown_remaining > 0.0, "enemy attack triggers once after its windup and starts cooldown")
	var duplicate_attack := machine.tick(0.01, slime.attack_range - 1.0, 0.0)
	_assert_true(not bool(duplicate_attack["attack_ready"]), "one attack state cannot damage twice")
	machine.tick(slime.attack_recovery + 0.01, slime.attack_range + 10.0, 0.0)
	machine.hurt()
	_assert_equal(machine.state_name(), &"HURT", "accepted player hit enters enemy hurt state")
	machine.tick(EnemyStateMachine.HURT_DURATION + 0.01, 999.0, slime.return_distance + 1.0)
	_assert_equal(machine.state_name(), &"RETURN", "hurt enemy outside its activity area returns home")
	machine.tick(0.01, 999.0, 0.0)
	_assert_equal(machine.state_name(), &"IDLE", "return completes at the home position")
	machine.die()
	machine.tick(10.0, 0.0, 0.0)
	_assert_equal(machine.state_name(), &"DEAD", "dead is a terminal enemy state")
	var first_drops := catalog.resolve_drops(&"wolf", "fixture:wolf:1")
	var second_drops := catalog.resolve_drops(&"wolf", "fixture:wolf:1")
	_assert_equal(first_drops, second_drops, "enemy drops are deterministic for a stable spawn ID")
	_assert_true(not first_drops.is_empty() and StringName(first_drops[0]["item_id"]) == &"wolf_pelt" and int(first_drops[0]["quantity"]) >= 1 and int(first_drops[0]["quantity"]) <= 2, "wolf death resolves a bounded canonical drop")


func _test_enemy_spawn_planner() -> void:
	var seed := WorldSeed.from_text("enemy-planner-fixture")
	var catalog := EnemyCatalog.new()
	var first := EnemySpawnPlanner.new(seed, catalog)
	var second := EnemySpawnPlanner.new(seed, catalog)
	var biome_catalog := BiomeCatalog.new()
	var terrain := TerrainGenerator.new(seed)
	var seen_ids := {}
	var seen_spawn_ids := {}
	var candidate_total := 0
	var deterministic := true
	var per_chunk_bounded := true
	var unique_ids := true
	var land_only := true
	var water_aquatic_only := true
	var biome_correct := true
	for chunk_y in range(-10, 11):
		for chunk_x in range(-10, 11):
			var coordinate := Vector2i(chunk_x, chunk_y)
			var first_candidates := first.candidates_for_chunk(coordinate)
			var second_candidates := second.candidates_for_chunk(coordinate)
			deterministic = deterministic and first_candidates == second_candidates
			per_chunk_bounded = per_chunk_bounded and first_candidates.size() <= catalog.maximum_per_chunk()
			for candidate in first_candidates:
				candidate_total += 1
				var spawn_id := String(candidate["spawn_id"])
				var enemy_id := candidate["enemy_id"] as StringName
				var world_tile := candidate["world_tile"] as Vector2i
				var biome_id := biome_catalog.id_for_code(terrain.biome_at(world_tile))
				seen_ids[enemy_id] = true
				unique_ids = unique_ids and not seen_spawn_ids.has(spawn_id)
				seen_spawn_ids[spawn_id] = true
				var candidate_terrain := terrain.terrain_at(world_tile)
				var is_water := candidate_terrain == ChunkData.Terrain.SHALLOW_WATER or candidate_terrain == ChunkData.Terrain.DEEP_WATER
				land_only = land_only and (terrain.terrain_at(world_tile) == ChunkData.Terrain.LAND or is_water)
				if is_water:
					water_aquatic_only = water_aquatic_only and catalog.enemy(enemy_id).aquatic
				else:
					water_aquatic_only = water_aquatic_only and not catalog.enemy(enemy_id).aquatic
				biome_correct = biome_correct and catalog.enemy(enemy_id).biomes.has(biome_id)
	_assert_true(deterministic, "enemy candidates are deterministic across planner restarts")
	_assert_true(per_chunk_bounded, "enemy candidates obey the per-chunk cap")
	_assert_true(unique_ids, "enemy spawn IDs stay unique across signed chunks")
	_assert_true(land_only, "enemy candidates stay on land or open water terrain")
	_assert_true(water_aquatic_only, "water candidates are aquatic and land candidates are not")
	_assert_true(biome_correct, "enemy candidates match data-driven biome rules")
	_assert_true(candidate_total > 0, "broad deterministic region contains enemy candidates")
	_assert_true(seen_ids.has(&"slime") and seen_ids.has(&"wolf") and not seen_ids.has(&"cave_bat"), "surface planner excludes underground-only cave bats")
	first.retain_chunks([Vector2i.ZERO])
	_assert_equal(first.cache_size(), 1, "enemy candidate cache is pruned to the retained chunk set")


func _test_milestone_models() -> void:
	var catalog := MilestoneCatalog.new()
	_assert_true(catalog.is_valid(), "external milestone configuration loads and validates")
	_assert_true(catalog.reward_item_id() == &"ancient_core" and catalog.reward_quantity() == 1, "canonical Boss reward is data-driven")
	var cycle := DayNightCycle.new(0.0)
	_assert_true(cycle.is_valid(), "external four-phase time configuration loads and validates")
	_assert_equal(cycle.phase_ids(), [&"DAWN", &"DAY", &"DUSK", &"NIGHT"], "time cycle contains dawn, day, dusk and night in order")
	_assert_equal(cycle.snapshot()["phase"], &"DAWN", "new world begins at dawn")
	for phase_id in [&"DAY", &"DUSK", &"NIGHT"]:
		var phase_cycle := DayNightCycle.new(cycle.seconds_at_phase(phase_id) + 0.01)
		_assert_equal(phase_cycle.snapshot()["phase"], phase_id, "time cycle reaches %s deterministically" % phase_id)
	var dusk_start := cycle.seconds_at_phase(&"DUSK")
	var dusk_mid := DayNightCycle.new(dusk_start + 60.0).snapshot()
	var dusk_late := DayNightCycle.new(dusk_start + 115.0).snapshot()
	_assert_true((dusk_mid["overlay"] as Color) != (dusk_late["overlay"] as Color), "environment color changes smoothly near a phase transition")
	cycle.advance(cycle.cycle_seconds())
	_assert_equal(int(cycle.snapshot()["day"]), 2, "day counter advances after one complete cycle")
	var state := MilestoneState.new()
	_assert_true(state.discover_ruin() and state.defeat_boss() and state.claim_reward(), "milestone state completes discover, Boss and reward sequence")
	var restored := MilestoneState.new()
	_assert_true(restored.restore_snapshot(state.persistence_snapshot()) and restored.reward_claimed, "milestone progression round trips exactly")
	var invalid := MilestoneState.new()
	_assert_true(not invalid.restore_snapshot({"schema_version": 1, "ruin_discovered": false, "boss_defeated": false, "reward_claimed": true}), "milestone validation rejects reward-before-Boss state")
	var seed := WorldSeed.from_text("V1.0-ruin-fixture")
	var first := RuinPlanner.new(seed, catalog).plan()
	var second := RuinPlanner.new(seed, catalog).plan()
	_assert_equal(first, second, "canonical ruin is deterministic across planner restarts")
	var ruin_tile := first.get("world_tile", Vector2i.ZERO) as Vector2i
	var terrain := TerrainGenerator.new(seed)
	_assert_equal(terrain.terrain_at(ruin_tile), ChunkData.Terrain.LAND, "canonical ruin always occupies land")
	var ruin_chunk := first.get("chunk", Vector2i.ZERO) as Vector2i
	var radius := ChunkStreamPlanner.chebyshev_distance(ruin_chunk, RuinPlanner.ORIGIN_CHUNK)
	_assert_true(radius >= 3 and radius <= 6, "canonical ruin stays inside the planned discovery ring")
	var tone := AudioCuePlayer.synthesize_tone(440.0)
	_assert_true(tone.data.size() > 100 and tone.mix_rate == AudioCuePlayer.SAMPLE_RATE, "procedural basic sound cue contains valid PCM samples")


func _test_weather_models() -> void:
	var catalog := WeatherCatalog.new()
	_assert_true(catalog.is_valid(), "external weather configuration loads and validates")
	var ids: Array[StringName] = []
	for definition in catalog.definitions():
		ids.append(definition.weather_id)
	_assert_equal(ids, [&"CLEAR", &"RAIN", &"SNOW", &"SANDSTORM"], "clear, rain, snow and sandstorm are data-driven")
	_assert_true(catalog.definition(&"SNOW").weight_for_biome(&"snowfield") > 0.0 and catalog.definition(&"SNOW").weight_for_biome(&"desert") == 0.0, "snow is restricted to reasonable cold regions")
	_assert_true(catalog.definition(&"SANDSTORM").weight_for_biome(&"desert") > 0.0 and catalog.definition(&"SANDSTORM").weight_for_biome(&"snowfield") == 0.0, "sandstorms are restricted to desert regions")
	var seed := WorldSeed.from_text("weather-fixture")
	var first := WeatherSystem.new(seed)
	var second := WeatherSystem.new(seed)
	var tile := Vector2i(80, -40)
	var first_snapshot := first.update(0.0, tile, &"forest")
	var second_snapshot := second.update(0.0, tile, &"forest")
	_assert_equal(first_snapshot["weather_id"], second_snapshot["weather_id"], "same seed, region, segment and biome select the same weather")
	_assert_equal(first_snapshot["region"], second_snapshot["region"], "regional weather coordinates are deterministic")
	first.force_weather(&"CLEAR")
	_assert_true(first.transition_to(&"RAIN"), "valid weather begins a smooth transition")
	var transitioning := first.update(catalog.transition_seconds() * 0.5, tile, &"forest")
	_assert_true(float(transitioning["transition_progress"]) > 0.0 and float(transitioning["transition_progress"]) < 1.0, "weather transition exposes a non-instant intermediate blend")
	var persisted := first.persistence_snapshot()
	var restored := WeatherSystem.new(seed, persisted)
	_assert_equal(restored.persistence_snapshot(), persisted, "weather state round trips exactly without offline progress")
	first.force_weather(&"RAIN")
	var rain := first.snapshot()
	_assert_true(float(rain["resource_yield_multiplier"]) > 1.0 and float(rain["enemy_population_multiplier"]) > 1.0, "rain affects both resources and enemy population")
	var quantity_probe := ChunkStreamManager.new()
	quantity_probe._on_weather_state_changed(rain)
	_assert_equal(quantity_probe.adjusted_resource_quantity(4), 5, "rain resource multiplier changes resolved harvest yield")
	quantity_probe.set("_world_layer", &"underground")
	quantity_probe._on_weather_state_changed(rain)
	_assert_equal(quantity_probe.adjusted_resource_quantity(4), 4, "surface weather never modifies underground mineral yield")
	quantity_probe.free()
	_assert_true(AudioCuePlayer.synthesize_ambience(float(rain["ambient_frequency"]), &"RAIN").data.size() > 0, "weather ambience is generated fully offline")


func _test_season_models() -> void:
	var catalog := SeasonCatalog.new()
	_assert_true(catalog.is_valid(), "external season configuration loads and validates")
	_assert_equal(catalog.season_ids(), [&"spring", &"summer", &"autumn", &"winter"], "spring, summer, autumn, winter are data-driven")
	_assert_equal(catalog.season_duration_days(), 8, "season duration is eight days")
	_assert_equal(catalog.transition_days(), 1, "season transition is one day")
	var state := SeasonState.new(catalog, 1)
	_assert_equal(state.season_id(), &"spring", "day 1 is spring")
	state.advance_to_day(9)
	_assert_equal(state.season_id(), &"summer", "day 9 is summer")
	state.advance_to_day(17)
	_assert_equal(state.season_id(), &"autumn", "day 17 is autumn")
	state.advance_to_day(25)
	_assert_equal(state.season_id(), &"winter", "day 25 is winter")
	state.advance_to_day(33)
	_assert_equal(state.season_id(), &"spring", "day 33 cycles back to spring")
	_assert_true(is_equal_approx(catalog.temperature_offset(&"spring"), -1.5), "spring temperature offset is -1.5")
	_assert_true(is_equal_approx(catalog.temperature_offset(&"summer"), 3.0), "summer temperature offset is 3.0")
	_assert_true(is_equal_approx(catalog.temperature_offset(&"winter"), -6.0), "winter temperature offset is -6.0")
	_assert_true(catalog.river_freezes(&"winter"), "winter rivers freeze")
	_assert_true(not catalog.river_freezes(&"summer"), "summer rivers do not freeze")
	_assert_true(is_equal_approx(catalog.crop_growth_multiplier(&"summer"), 1.3), "summer crop growth multiplier is 1.3")
	_assert_true(is_equal_approx(catalog.crop_growth_multiplier(&"winter"), 0.3), "winter crop growth multiplier is 0.3")
	_assert_true(is_equal_approx(catalog.resource_yield_multiplier(&"summer"), 1.15), "summer resource yield multiplier is 1.15")
	_assert_true(is_equal_approx(catalog.enemy_population_multiplier(&"winter"), 0.85), "winter enemy population multiplier is 0.85")
	_assert_true(is_equal_approx(catalog.weather_weight(&"winter", &"SNOW"), 0.50), "winter snow weather weight is 0.50")
	_assert_true(is_equal_approx(catalog.weather_weight(&"summer", &"SANDSTORM"), 0.20), "summer sandstorm weather weight is 0.20")
	var round_trip := SeasonState.new(catalog, 1)
	round_trip.advance_to_day(20)
	var snapshot := round_trip.persistence_snapshot()
	var restored := SeasonState.new(catalog, 1)
	_assert_true(restored.restore_snapshot(snapshot), "season state restores from persistence snapshot")
	_assert_equal(restored.day(), 20, "restored season day matches day 20")
	_assert_equal(restored.season_id(), round_trip.season_id(), "restored season id matches original")


func _test_deterministic_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var first_generator := TerrainGenerator.new(seed)
	var showcase_chunk := Vector2i(-1, -4)
	var first := first_generator.generate_chunk(showcase_chunk)
	var repeated := TerrainGenerator.new(seed).generate_chunk(showcase_chunk)
	_assert_equal(first.checksum, repeated.checksum, "same seed and coordinate survive generator restart")
	_assert_true(first.base_tiles == repeated.base_tiles, "deterministic tile bytes match exactly")
	_assert_equal(first.base_tiles.size(), 1024, "chunk contains 32×32 base tiles")
	_assert_equal(first.continental_map.size(), 1024, "chunk contains 32×32 continental samples")
	_assert_equal(first.elevation_map.size(), 1024, "chunk contains 32×32 elevation samples")
	_assert_equal(first.erosion_map.size(), 1024, "chunk contains 32×32 erosion samples")
	_assert_equal(first.temperature_map.size(), 1024, "chunk contains 32×32 temperature samples")
	_assert_equal(first.moisture_map.size(), 1024, "chunk contains 32×32 moisture samples")
	_assert_equal(first.biome_map.size(), 1024, "chunk contains 32×32 biome samples")
	_assert_equal(first.water_feature_map.size(), 1024, "chunk contains 32×32 deterministic water-feature samples")
	_assert_equal(first.checksum, "6e1e7c071053a579", "generation v6 checksum fixture remains stable")
	var other_seed := TerrainGenerator.new(WorldSeed.from_text("另一片边境")).generate_chunk(showcase_chunk)
	_assert_true(first.checksum != other_seed.checksum, "different seeds produce different chunks")
	var chunk_a := Vector2i(-3, 2)
	var chunk_b := Vector2i(4, -5)
	var order_one := TerrainGenerator.new(seed)
	var a_then_b_a := order_one.generate_chunk(chunk_a).checksum
	var a_then_b_b := order_one.generate_chunk(chunk_b).checksum
	var order_two := TerrainGenerator.new(seed)
	var b_then_a_b := order_two.generate_chunk(chunk_b).checksum
	var b_then_a_a := order_two.generate_chunk(chunk_a).checksum
	_assert_true(a_then_b_a == b_then_a_a and a_then_b_b == b_then_a_b, "chunk generation is independent of request order")
	var counts := first.terrain_counts()
	_assert_equal(counts[0] + counts[1] + counts[2] + counts[3], 1024, "terrain histogram accounts for every tile")
	var represented_types := 0
	for count in counts:
		if count > 0:
			represented_types += 1
	if represented_types < 2:
		var nearby_counts := PackedInt32Array([0, 0, 0, 0])
		for offset_y in range(-1, 2):
			for offset_x in range(-1, 2):
				var nearby := first_generator.generate_chunk(showcase_chunk + Vector2i(offset_x, offset_y)).terrain_counts()
				for terrain_index in nearby_counts.size():
					nearby_counts[terrain_index] += nearby[terrain_index]
		represented_types = 0
		for count in nearby_counts:
			represented_types += 1 if count > 0 else 0
	_assert_true(represented_types >= 2, "start region contains a visible terrain transition")
	var isolated_tiles := 0
	for y in range(1, WorldCoordinates.CHUNK_SIZE - 1):
		for x in range(1, WorldCoordinates.CHUNK_SIZE - 1):
			var local := Vector2i(x, y)
			var terrain := first.tile_at(local)
			var matching_neighbors := 0
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					if offset_x == 0 and offset_y == 0:
						continue
					if first.tile_at(local + Vector2i(offset_x, offset_y)) == terrain:
						matching_neighbors += 1
			if matching_neighbors == 0:
				isolated_tiles += 1
	_assert_equal(isolated_tiles, 0, "coast cleanup removes isolated single-tile noise")


func _test_biome_regions() -> void:
	var catalog := BiomeCatalog.new()
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var broad_counts := PackedInt32Array()
	broad_counts.resize(catalog.biome_count())
	for y in range(-2048, 2049, 64):
		for x in range(-2048, 2049, 64):
			broad_counts[generator.biome_at(Vector2i(x, y))] += 1
	for biome_code in catalog.biome_count():
		_assert_true(broad_counts[biome_code] > 0, "broad deterministic scan contains %s" % catalog.display_name_for_code(biome_code))
	var origin := Vector2i(-96, -144)
	var side := 96
	var cells := PackedByteArray()
	cells.resize(side * side)
	for y in side:
		for x in side:
			cells[y * side + x] = generator.biome_at(origin + Vector2i(x, y))
	var matching_edges := 0
	var total_edges := 0
	var isolated_cells := 0
	for y in side:
		for x in side:
			var biome_code := cells[y * side + x]
			if x + 1 < side:
				total_edges += 1
				matching_edges += 1 if biome_code == cells[y * side + x + 1] else 0
			if y + 1 < side:
				total_edges += 1
				matching_edges += 1 if biome_code == cells[(y + 1) * side + x] else 0
			if x > 0 and y > 0 and x + 1 < side and y + 1 < side:
				var matching_neighbors := 0
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					matching_neighbors += 1 if biome_code == cells[(y + offset.y) * side + x + offset.x] else 0
				isolated_cells += 1 if matching_neighbors == 0 else 0
	_assert_true(float(matching_edges) / float(total_edges) > 0.90, "biomes form large continuous regions instead of random fragments")
	_assert_true(isolated_cells <= 4, "biome transition cleanup limits isolated single cells")


func _test_resource_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var generator := TerrainGenerator.new(seed)
	var catalog := ResourceCatalog.new()
	var chunks: Array[ChunkData] = []
	var represented := PackedInt32Array()
	represented.resize(catalog.resource_count())
	var keys := {}
	var water_safe := true
	var land_codes_only := true
	var capped := true
	for chunk_y in range(-5, 0):
		for chunk_x in range(-3, 2):
			var chunk := generator.generate_chunk(Vector2i(chunk_x, chunk_y))
			chunks.append(chunk)
			capped = capped and chunk.resource_count() <= catalog.max_resources_per_chunk()
			for index in chunk.resource_count():
				var local := chunk.resource_local_at(index)
				var terrain := chunk.tile_at(local)
				var on_water := terrain == ChunkData.Terrain.DEEP_WATER or terrain == ChunkData.Terrain.SHALLOW_WATER
				water_safe = water_safe and (not on_water or chunk.resource_code_at(index) >= 8)
				land_codes_only = land_codes_only and (on_water or chunk.resource_code_at(index) <= 7)
				represented[chunk.resource_code_at(index)] += 1
				keys[chunk.resource_key_at(index)] = true
	_assert_true(water_safe, "land resources never spawn in deep or shallow water")
	_assert_true(land_codes_only, "ocean resources never spawn on land or beach")
	_assert_true(capped, "resource counts remain under the configured per-chunk limit")
	for resource_id in ResourceCatalog.REQUIRED_RESOURCE_IDS:
		var resource_code := catalog.code_for_id(resource_id)
		_assert_true(represented[resource_code] > 0, "deterministic surface region contains %s" % catalog.display_name_for_code(resource_code))
	var all_spawns: Array[Dictionary] = []
	for chunk in chunks:
		for index in chunk.resource_count():
			all_spawns.append({"tile": chunk.resource_world_tile_at(index), "code": chunk.resource_code_at(index)})
	var spacing_valid := true
	for first_index in all_spawns.size():
		for second_index in range(first_index + 1, all_spawns.size()):
			var first := all_spawns[first_index]
			var second := all_spawns[second_index]
			var required := maxi(catalog.minimum_distance_for_code(int(first["code"])), catalog.minimum_distance_for_code(int(second["code"])))
			if (first["tile"] as Vector2i).distance_squared_to(second["tile"] as Vector2i) < required * required:
				spacing_valid = false
	_assert_true(spacing_valid, "minimum spacing holds within and across chunk borders")
	_assert_equal(keys.size(), all_spawns.size(), "resource world keys are unique across chunks")
	var showcase := generator.generate_chunk(Vector2i(-1, -4))
	var repeated := TerrainGenerator.new(seed).generate_chunk(Vector2i(-1, -4))
	_assert_true(showcase.resource_codes == repeated.resource_codes and showcase.resource_local_x == repeated.resource_local_x and showcase.resource_local_y == repeated.resource_local_y, "resource bytes are deterministic across generator restarts")
	var spawn := generator.find_land_near(showcase)
	_assert_true(not showcase.has_resource_at(WorldCoordinates.tile_to_local(spawn)), "initial player spawn avoids resource collision")


func _test_resource_harvest_state() -> void:
	var catalog := ResourceCatalog.new()
	var state := ResourceHarvestState.new()
	var tree_code := catalog.code_for_id(&"tree")
	var key := "-7:12:%d" % tree_code
	var wrong_tool := state.hit(key, tree_code, &"hands", catalog)
	_assert_true(not bool(wrong_tool["accepted"]) and String(wrong_tool["reason"]) == "wrong_tool", "wrong tool cannot damage a resource")
	var first_hit := state.hit(key, tree_code, &"axe", catalog)
	var second_hit := state.hit(key, tree_code, &"axe", catalog)
	var final_hit := state.hit(key, tree_code, &"axe", catalog)
	_assert_true(bool(first_hit["accepted"]) and not bool(first_hit["destroyed"]) and int(first_hit["remaining"]) == 2, "resource durability decreases by tool power")
	_assert_true((first_hit["drops"] as Array).is_empty() and (second_hit["drops"] as Array).is_empty(), "resource does not drop items before destruction")
	_assert_true(bool(final_hit["destroyed"]) and state.collected_resources.has(key), "final valid hit records the resource difference")
	var drops := final_hit["drops"] as Array
	_assert_equal(drops.size(), 1, "destroyed tree resolves one controlled drop stack")
	var tree_drop := drops[0] as Dictionary
	_assert_equal(tree_drop["item_id"], &"wood", "tree produces the correct item")
	_assert_true(int(tree_drop["quantity"]) >= 2 and int(tree_drop["quantity"]) <= 4, "tree drop quantity stays inside configured bounds")
	var duplicate := state.hit(key, tree_code, &"axe", catalog)
	_assert_true(not bool(duplicate["accepted"]) and (duplicate["drops"] as Array).is_empty(), "same resource cannot drop twice")
	state.collect_item(tree_drop["item_id"] as StringName, int(tree_drop["quantity"]))
	_assert_equal(state.quantity(&"wood"), int(tree_drop["quantity"]), "automatic pickup target inventory accepts resolved quantity")


func _test_save_system() -> void:
	SaveManager.clear_current_world()
	_assert_true(SaveManager.create_world("自动测试边境", "存档种子-070"), "world creation writes initial metadata and player state")
	var root := SaveManager.current_world_root_absolute()
	_assert_true(FileAccess.file_exists(root.path_join("world.json")) and FileAccess.file_exists(root.path_join("player.json")), "new world contains metadata and player documents")
	var metadata := _read_json_for_test(root.path_join("world.json"))
	_assert_equal(int(metadata.get("save_version", 0)), 26, "world metadata records save format 26")
	_assert_equal(int(metadata.get("generation_version", 0)), 6, "world metadata records generation format 6")
	_assert_equal(String(metadata.get("world_name", "")), "自动测试边境", "world metadata preserves the world name")
	_assert_equal(String(metadata.get("seed_text", "")), "存档种子-070", "world metadata preserves the text seed")
	var chunks_path := root.path_join("chunks/surface")
	var underground_chunks_path := root.path_join("chunks/underground")
	_assert_equal(_json_file_count(chunks_path), 0, "new unmodified world creates no chunk difference file")
	var initial_player := SaveManager.loaded_player_snapshot()
	var empty_inventory := InventoryModel.new()
	var empty_state := {
		"collected_resources": [],
		"inventory": empty_inventory.snapshot(),
		"crafting_state": CraftingSystem.new(empty_inventory).persistence_snapshot(),
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
		"building_state": BuildingState.new().persistence_snapshot(),
		"farming_state": FarmingState.new(int(metadata["seed"])).persistence_snapshot(),
		"husbandry_state": HusbandryState.new(int(metadata["seed"])).persistence_snapshot(),
		"opened_cave_chests": [],
		"world_layer": "surface",
		"active_tool": "hands",
	}
	_assert_true(SaveManager.request_save(initial_player, empty_state, 1.25, false), "automatic save request accepts an immutable snapshot")
	SaveManager.flush_pending_save()
	_assert_equal(_json_file_count(chunks_path), 0, "saving an unmodified world still creates no chunk difference file")
	var player := initial_player.duplicate(true)
	player["position"] = [-2048.5, 1024.25]
	player["health"] = 73.0
	player["stamina"] = 41.0
	var saved_combat := PlayerCombatState.new()
	saved_combat.defense = 4.0
	saved_combat.death_count = 2
	saved_combat.invulnerability_remaining = 0.25
	saved_combat.respawn_position = Vector2(-2016.0, 992.0)
	player["combat_state"] = saved_combat.persistence_snapshot()
	var removed_keys := ["-1:-129:0", "33:65:1", "underground:-17:-129:5"]
	var opened_chest_key := "underground:-17:-129"
	var changed_inventory := InventoryModel.new()
	changed_inventory.add_item(&"wood", 7)
	changed_inventory.add_item(&"stone", 3)
	changed_inventory.add_item(&"wood_axe", 1)
	var saved_tool_slot := _find_item_slot(changed_inventory, &"wood_axe")
	changed_inventory.damage_tool_at(saved_tool_slot, 7)
	changed_inventory.select_hotbar(saved_tool_slot)
	var changed_inventory_snapshot := changed_inventory.snapshot()
	var changed_crafting := CraftingSystem.new(changed_inventory)
	changed_crafting.refresh_discoveries()
	var changed_crafting_snapshot := changed_crafting.persistence_snapshot()
	var grave_inventory := InventoryModel.new()
	grave_inventory.add_item(&"branch", 4)
	grave_inventory.add_item(&"stone_sword", 1)
	var grave_sword_slot := _find_item_slot(grave_inventory, &"stone_sword")
	grave_inventory.damage_tool_at(grave_sword_slot, 11)
	var changed_graves := GraveModel.new()
	changed_graves.deposit(Vector2(-1990.0, 1004.0), grave_inventory)
	var changed_grave_snapshot := changed_graves.persistence_snapshot()
	var changed_milestones := MilestoneState.new()
	changed_milestones.discover_ruin()
	changed_milestones.defeat_boss()
	changed_milestones.claim_reward()
	var changed_milestone_snapshot := changed_milestones.persistence_snapshot()
	var saved_weather_system := WeatherSystem.new(int(metadata["seed"]))
	saved_weather_system.force_weather(&"SNOW")
	var changed_weather_snapshot := saved_weather_system.persistence_snapshot()
	var changed_exploration := ExplorationMapState.new()
	var explored_chunk := Vector2i(-2, 1)
	changed_exploration.reveal_chunk(explored_chunk, 1)
	var explored_tile := WorldCoordinates.chunk_local_to_tile(explored_chunk, Vector2i(8, 8))
	changed_exploration.register_marker("village:save-test", &"village", "存档村庄", explored_tile, "e6c46a", true)
	changed_exploration.add_custom_marker(explored_tile + Vector2i.ONE, "存档标记")
	var changed_exploration_snapshot := changed_exploration.persistence_snapshot()
	var changed_regional_bosses := RegionalBossState.new()
	changed_regional_bosses.defeat(&"grove_titan")
	var changed_regional_boss_snapshot := changed_regional_bosses.persistence_snapshot()
	var changed_npcs := NpcWorldState.new()
	changed_npcs.record_talk("village:save-test:npc:1", 2)
	changed_npcs.record_trade("village:save-test:npc:1", &"sell", 3, 2)
	var changed_npc_snapshot := changed_npcs.persistence_snapshot()
	var changed_relationships := RelationshipState.new()
	var relationship_catalog := RelationshipCatalog.new()
	changed_relationships.apply_gift("village:save-test:npc:1", "village:save-test", &"merchant", &"copper_ore", 2, relationship_catalog)
	changed_relationships.record_trade("village:save-test:npc:1", "village:save-test", relationship_catalog)
	var changed_relationship_snapshot := changed_relationships.persistence_snapshot()
	var changed_quests := QuestState.new()
	var quest_catalog := QuestCatalog.new()
	changed_quests.accept(&"side_slime_hunt", quest_catalog)
	changed_quests.record_event(&"defeat", &"slime", 2, quest_catalog)
	changed_quests.track(&"side_slime_hunt")
	var changed_quest_snapshot := changed_quests.persistence_snapshot()
	var changed_choices := WorldChoiceState.new()
	changed_choices.restore_snapshot({
		"schema_version": WorldChoiceState.SCHEMA_VERSION,
		"records": [{"choice_id": "core_destination", "option_id": "village_vault", "resolved_day": 2}],
	}, quest_catalog)
	var changed_choice_snapshot := changed_choices.persistence_snapshot()
	var faction_catalog := FactionCatalog.new()
	var changed_factions := FactionState.new(faction_catalog)
	changed_factions.record_trade(&"merchant", faction_catalog)
	changed_factions.record_discovery("village:save-test", &"village", faction_catalog)
	changed_factions.record_defeat("spawn:save-test:bandit", &"bandit_scout", faction_catalog)
	var changed_faction_snapshot := changed_factions.persistence_snapshot()
	var event_catalog := WorldEventCatalog.new()
	var event_planner := WorldEventPlanner.new(int(metadata["seed"]), event_catalog)
	var changed_events := WorldEventState.new()
	var scheduled_event := event_planner.plan_for_slot(0)
	changed_events.advance(float(scheduled_event["start_seconds"]) + 1.0, explored_chunk, event_planner, event_catalog)
	var changed_event_snapshot := changed_events.persistence_snapshot()
	var progression_catalog := RegionProgressionCatalog.new()
	var progression_profile := RegionProgressionModel.new(int(metadata["seed"]), progression_catalog).region_profile(explored_chunk)
	var changed_progression := RegionProgressionState.new()
	changed_progression.discover_region(progression_profile, progression_catalog)
	changed_progression.record_source(&"regional_boss_defeated", "grove_titan", progression_catalog)
	var changed_progression_snapshot := changed_progression.persistence_snapshot()
	var changed_survival := SurvivalState.new()
	_assert_true(changed_survival.restore_snapshot({
		"schema_version": SurvivalState.SCHEMA_VERSION,
		"hunger": 62.0,
		"body_temperature": 35.2,
		"wetness": 78.0,
		"oxygen": 45.0,
		"effects": [{"effect_id": "poison", "remaining_seconds": 20.0, "tick_elapsed": 1.0}],
		"exposures": {"poison": 5.0, "burning": 0.0, "frostbite": 1.0},
	}), "changed survival save fixture validates")
	var changed_survival_snapshot := changed_survival.persistence_snapshot()
	var equipment_inventory := InventoryModel.new()
	for item_id in [&"copper_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots"]:
		equipment_inventory.add_item(item_id, 1)
	equipment_inventory.add_item(&"tempered_plate", 2)
	var changed_equipment := EquipmentState.new()
	for item_id in [&"copper_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots"]:
		changed_equipment.import_inventory_slot(equipment_inventory, _find_item_slot(equipment_inventory, item_id), int(metadata["seed"]))
	var saved_equipment_weapon := changed_equipment.equipped_record(&"weapon")
	changed_equipment.enhance(int(saved_equipment_weapon["instance_id"]), equipment_inventory)
	changed_equipment.damage_equipped_weapon(9)
	var changed_equipment_snapshot := changed_equipment.persistence_snapshot()
	_assert_true((changed_equipment_snapshot["records"] as Array).size() == 4, "changed equipment save fixture preserves four rolled and equipped instances")
	var changed_buildings := BuildingState.new()
	_assert_true(changed_buildings.restore_snapshot({
		"schema_version": BuildingState.SCHEMA_VERSION,
		"placements": [
			{"placement_id": "surface:320:320:ground", "piece_id": "wood_floor", "world_tile": [320, 320], "rotation": 0},
			{"placement_id": "surface:320:320:structure", "piece_id": "wood_wall", "world_tile": [320, 320], "rotation": 90},
			{"placement_id": "surface:321:320:ground", "piece_id": "wood_floor", "world_tile": [321, 320], "rotation": 0},
			{"placement_id": "surface:321:320:structure", "piece_id": "smelter", "world_tile": [321, 320], "rotation": 0, "fuel_units": 4, "processed_count": 3},
			{"placement_id": "surface:322:320:ground", "piece_id": "wood_floor", "world_tile": [322, 320], "rotation": 0},
			{"placement_id": "surface:322:320:structure", "piece_id": "storage_chest", "world_tile": [322, 320], "rotation": 0, "storage": [{"item_id": "stone", "quantity": 5}]},
			{"placement_id": "surface:323:320:ground", "piece_id": "wood_floor", "world_tile": [323, 320], "rotation": 0},
			{"placement_id": "surface:323:320:structure", "piece_id": "conveyor_belt", "world_tile": [323, 320], "rotation": 90, "automation_enabled": true, "automation_last_seconds": 40.0, "automation_cycles": 2, "automation_status": "working"},
			{"placement_id": "surface:324:320:ground", "piece_id": "wood_floor", "world_tile": [324, 320], "rotation": 0},
			{"placement_id": "surface:324:320:structure", "piece_id": "storage_chest", "world_tile": [324, 320], "rotation": 0, "storage": [{"item_id": "stone", "quantity": 2}]},
			{"placement_id": "surface:325:320:structure", "piece_id": "homestead_beacon", "world_tile": [325, 320], "rotation": 0},
		],
	}), "changed building save fixture validates")
	var changed_building_snapshot := changed_buildings.persistence_snapshot()
	var changed_homestead := HomesteadState.new()
	_assert_true(bool(changed_homestead.synchronize_markers(changed_buildings, 42.0)["ok"]) and changed_homestead.commit_home_teleport(42.0), "changed homestead save fixture binds one active home to its beacon")
	var changed_homestead_snapshot := changed_homestead.persistence_snapshot()
	var changed_farming := FarmingState.new(int(metadata["seed"]))
	var farming_context := {
		"world_layer": &"surface", "player_tile": Vector2i(352, 320), "player_occupied": false,
		"in_water": false, "generated_overlay": false, "resource_occupied": false, "building_occupied": false,
	}
	var farming_inventory := InventoryModel.new()
	farming_inventory.add_item(&"wheat_seed", 1)
	farming_inventory.add_item(&"basic_fertilizer", 1)
	_assert_true(bool(changed_farming.till(Vector2i(352, 320), 1, farming_context)["ok"]) and bool(changed_farming.plant(&"wheat", Vector2i(352, 320), 1, farming_inventory)["ok"]), "changed farming save fixture opens and sows an owning-chunk plot")
	changed_farming.fertilize(Vector2i(352, 320), &"basic_fertilizer", farming_inventory)
	for farming_day in range(1, 5):
		changed_farming.water(Vector2i(352, 320), farming_day)
		changed_farming.advance_to_day(farming_day + 1, &"CLEAR")
	var changed_farming_snapshot := changed_farming.persistence_snapshot()
	_assert_true(bool(((changed_farming_snapshot["plots"] as Array)[0] as Dictionary)["mature"]), "changed farming save fixture preserves a mature quality-ready crop")
	var changed_husbandry := HusbandryState.new(int(metadata["seed"]))
	var husbandry_inventory := InventoryModel.new()
	husbandry_inventory.add_item(&"wheat_seed", 3)
	var husbandry_candidate := {
		"animal_id": "wild:save:chicken", "animal_type": "chicken",
		"world_tile": [384, 320], "sex": "female", "wild": true,
	}
	_assert_true(bool(changed_husbandry.feed_candidate(husbandry_candidate, 1, husbandry_inventory)["ok"]), "changed husbandry save fixture records its first wild-animal feed")
	changed_husbandry.advance_to_day(2)
	_assert_true(bool(changed_husbandry.feed("wild:save:chicken", 2, husbandry_inventory)["tamed_now"]), "changed husbandry save fixture reaches its exact taming threshold")
	changed_husbandry.advance_to_day(3)
	changed_husbandry.set_sleep_phase(&"NIGHT")
	var changed_husbandry_snapshot := changed_husbandry.persistence_snapshot()
	_assert_true(int(((changed_husbandry_snapshot["animals"] as Array)[0] as Dictionary)["product_ready"]) > 0 and bool(((changed_husbandry_snapshot["animals"] as Array)[0] as Dictionary)["sleeping"]), "changed husbandry save fixture preserves inactive-day product and sleep state")
	var changed_boats := BoatState.new()
	_assert_true(not changed_boats.deploy(Vector2i(230, 230), &"rowboat").is_empty() and not changed_boats.deploy(Vector2i(232, 231), &"rowboat").is_empty(), "changed world deploys two deterministic rowboats")
	var changed_boat_snapshot := changed_boats.persistence_snapshot()
	var changed_state := {
		"collected_resources": removed_keys,
		"inventory": changed_inventory_snapshot,
		"crafting_state": changed_crafting_snapshot,
		"grave_state": changed_grave_snapshot,
		"milestone_state": changed_milestone_snapshot,
		"dungeon_state": DungeonRunState.new().persistence_snapshot(),
		"exploration_state": changed_exploration_snapshot,
		"regional_boss_state": changed_regional_boss_snapshot,
		"npc_state": changed_npc_snapshot,
		"relationship_state": changed_relationship_snapshot,
		"quest_state": changed_quest_snapshot,
		"world_choice_state": changed_choice_snapshot,
		"faction_state": changed_faction_snapshot,
		"world_event_state": changed_event_snapshot,
		"region_progression_state": changed_progression_snapshot,
		"survival_state": changed_survival_snapshot,
		"equipment_state": changed_equipment_snapshot,
		"homestead_state": changed_homestead_snapshot,
		"building_state": changed_building_snapshot,
		"farming_state": changed_farming_snapshot,
		"husbandry_state": changed_husbandry_snapshot,
		"boat_state": changed_boat_snapshot,
		"opened_cave_chests": [opened_chest_key],
		"world_layer": "underground",
		"active_tool": "axe",
	}
	var dispatch_started := Time.get_ticks_usec()
	_assert_true(SaveManager.request_save(player, changed_state, 42.5, false, changed_weather_snapshot), "changed world dispatches an autosave")
	var dispatch_ms := float(Time.get_ticks_usec() - dispatch_started) / 1000.0
	_assert_true(dispatch_ms < 50.0, "autosave snapshot dispatch does not block the main thread")
	SaveManager.flush_pending_save()
	_assert_true(SaveManager.last_save_duration_ms < 500.0, "background save completes without a visible-length stall")
	_assert_equal(_json_file_count(chunks_path), 6, "two resource chunks plus one building, farming, husbandry and boat chunk create exact surface differences")
	_assert_equal(_json_file_count(underground_chunks_path), 1, "underground resources and chests share one layer-specific difference file")
	var building_difference_path := chunks_path.path_join("10_10.json")
	var building_difference := _read_json_for_test(building_difference_path)
	_assert_true(FileAccess.file_exists(building_difference_path) and (building_difference.get("placed_buildings", []) as Array).size() == 11 and int(((building_difference.get("placed_buildings", []) as Array)[3] as Dictionary).get("fuel_units", 0)) == 4 and int(((building_difference.get("placed_buildings", []) as Array)[7] as Dictionary).get("automation_cycles", 0)) == 2, "player buildings, processor fuel, automation state and home beacon persist only in their owning signed chunk difference")
	_assert_true(not _read_json_for_test(root.path_join("player.json")).has("building_state"), "player document does not duplicate chunk-owned building state")
	var player_homestead_document := _read_json_for_test(root.path_join("player.json"))["homestead_state"] as Dictionary
	var normalized_player_homestead := HomesteadState.new()
	_assert_true(normalized_player_homestead.restore_snapshot(player_homestead_document, changed_buildings) and normalized_player_homestead.persistence_snapshot() == changed_homestead_snapshot, "player document stores only validated home selection and teleport state while referencing the chunk-owned beacon")
	var farming_difference_path := chunks_path.path_join("11_10.json")
	var farming_difference := _read_json_for_test(farming_difference_path)
	_assert_true(FileAccess.file_exists(farming_difference_path) and (farming_difference.get("farming_plots", []) as Array).size() == 1, "farming plots persist only in their owning signed chunk difference")
	_assert_true(not _read_json_for_test(root.path_join("player.json")).has("farming_state"), "player document does not duplicate chunk-owned farming state")
	var husbandry_difference_path := chunks_path.path_join("12_10.json")
	var husbandry_difference := _read_json_for_test(husbandry_difference_path)
	_assert_true(FileAccess.file_exists(husbandry_difference_path) and (husbandry_difference.get("husbandry_animals", []) as Array).size() == 1, "interacted animals persist only in their owning signed surface-chunk difference")
	_assert_true(not _read_json_for_test(root.path_join("player.json")).has("husbandry_state"), "player document does not duplicate chunk-owned husbandry state")
	var boat_difference_path := chunks_path.path_join("7_7.json")
	var boat_difference := _read_json_for_test(boat_difference_path)
	_assert_true(FileAccess.file_exists(boat_difference_path) and (boat_difference.get("deployed_boats", []) as Array).size() == 2 and String(((boat_difference.get("deployed_boats", []) as Array)[0] as Dictionary).get("boat_id", "")) == "surface:230:230", "deployed boats persist only in their owning signed surface-chunk difference")
	_assert_true(not _read_json_for_test(root.path_join("player.json")).has("boat_state"), "player document does not duplicate chunk-owned boat state")
	var world_id := SaveManager.current_world_id()
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "saved world reloads after manager state is cleared")
	var restored_player := SaveManager.loaded_player_snapshot()
	_assert_equal(restored_player["position"], [-2048.5, 1024.25], "player position restores exactly")
	_assert_equal(float(restored_player["health"]), 73.0, "player health restores exactly")
	_assert_equal(float(restored_player["stamina"]), 41.0, "player stamina restores exactly")
	_assert_equal(restored_player["combat_state"], saved_combat.persistence_snapshot(), "player defense, invulnerability, death count and respawn point restore exactly")
	var restored_world_state := SaveManager.loaded_world_state_snapshot()
	var restored_removed := restored_world_state["collected_resources"] as Array
	_assert_true(restored_removed.has(removed_keys[0]) and restored_removed.has(removed_keys[1]) and restored_removed.has(removed_keys[2]), "surface and underground resources restore from layer-specific differences")
	_assert_equal(restored_world_state["inventory"], changed_inventory_snapshot, "V0.8 slot order and stack quantities restore identically")
	var restored_inventory_model := InventoryModel.new()
	restored_inventory_model.restore_snapshot(restored_world_state["inventory"] as Dictionary)
	var restored_tool_slot := _find_item_slot(restored_inventory_model, &"wood_axe")
	_assert_true(restored_tool_slot == saved_tool_slot and int(restored_inventory_model.slot(restored_tool_slot)["durability"]) == 23, "selected hotbar tool and individual durability restore exactly")
	_assert_equal(restored_world_state["crafting_state"], changed_crafting_snapshot, "V0.9 recipe discoveries restore identically")
	_assert_equal(restored_world_state["grave_state"], changed_grave_snapshot, "V0.10 grave position, contents and durability restore identically")
	_assert_equal(restored_world_state["milestone_state"], changed_milestone_snapshot, "V1.0 ruin, Boss and reward progression restore identically")
	_assert_equal(SaveManager.current_weather_state(), changed_weather_snapshot, "V1.2 weather state restores exactly")
	_assert_true(SaveManager.current_player_layer() == &"underground" and String(restored_world_state["world_layer"]) == "underground", "current underground layer restores exactly")
	_assert_true((restored_world_state["opened_cave_chests"] as Array).has(opened_chest_key), "opened underground chest state restores exactly")
	_assert_true(int((restored_world_state["dungeon_state"] as Dictionary).get("schema_version", 0)) == DungeonRunState.SCHEMA_VERSION, "non-dungeon saves still preserve an explicit empty dungeon schema")
	_assert_equal(restored_world_state["exploration_state"], changed_exploration_snapshot, "V2.0 fog and world markers restore identically")
	_assert_equal(restored_world_state["regional_boss_state"], changed_regional_boss_snapshot, "V2.0 regional Boss completion restores identically")
	_assert_equal(restored_world_state["npc_state"], changed_npc_snapshot, "V2.1 NPC dialogue and trade state restores identically")
	_assert_equal(restored_world_state["relationship_state"], changed_relationship_snapshot, "V2.2 affection and village reputation restore identically")
	_assert_equal(restored_world_state["quest_state"], changed_quest_snapshot, "V2.3 quest tracking, status and progress restore identically")
	_assert_equal(restored_world_state["world_choice_state"], changed_choice_snapshot, "V3.0 key world choice and selected result restore identically")
	_assert_equal(restored_world_state["faction_state"], changed_faction_snapshot, "V2.4 standings, events and control points restore identically")
	_assert_equal(restored_world_state["world_event_state"], changed_event_snapshot, "V2.5 timetable cursor, active event and history restore identically")
	_assert_equal(restored_world_state["region_progression_state"], changed_progression_snapshot, "V2.6 regional discoveries and deduplicated world-progress sources restore identically")
	_assert_equal(restored_world_state["survival_state"], changed_survival_snapshot, "V3.1 hunger, temperature, wetness and effects restore identically")
	_assert_equal(restored_world_state["equipment_state"], changed_equipment_snapshot, "V3.6 equipment slots, quality, rarity, affixes, reinforcement and durability restore identically")
	_assert_equal(restored_world_state["building_state"], changed_building_snapshot, "V3.7 layered buildings and automation machine state restore identically")
	_assert_equal(restored_world_state["homestead_state"], changed_homestead_snapshot, "V4.0 base identity, active home and teleport time restore identically")
	_assert_equal(restored_world_state["farming_state"], changed_farming_snapshot, "V3.3 tilled, watered, fertilized and mature farming differences restore identically")
	_assert_equal(restored_world_state["husbandry_state"], changed_husbandry_snapshot, "V3.4 taming, feed reserve, product and sleeping differences restore identically")
	_assert_equal(restored_world_state["boat_state"], changed_boat_snapshot, "V4.1 deployed boat identities and tiles restore identically")
	_assert_equal(String(restored_world_state["active_tool"]), "axe", "active tool restores with player attributes")
	var restored_harvest := ResourceHarvestState.new()
	_assert_true(restored_harvest.restore_snapshot(restored_removed, restored_world_state["inventory"]), "restored inventory snapshot passes schema validation")
	_assert_true(restored_harvest.collected_resources.has(removed_keys[0]), "restored collected key prevents a generated resource from reappearing")
	_assert_true(restored_harvest.quantity(&"wood") == 7 and restored_harvest.quantity(&"stone") == 3, "restored inventory exposes exact item totals")
	var without_buildings := restored_world_state.duplicate(true)
	without_buildings["building_state"] = BuildingState.new().persistence_snapshot()
	without_buildings["homestead_state"] = HomesteadState.new().persistence_snapshot()
	_assert_true(SaveManager.request_save(restored_player, without_buildings, 43.0, false), "demolished building snapshot dispatches a compacting save")
	SaveManager.flush_pending_save()
	_assert_true(not FileAccess.file_exists(building_difference_path) and _json_file_count(chunks_path) == 5, "removing the last building cleans its stale building-only chunk difference")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 43.5, false), "building fixture can be restored after stale-difference coverage")
	SaveManager.flush_pending_save()
	_assert_true(FileAccess.file_exists(building_difference_path) and _json_file_count(chunks_path) == 6, "restored building state recreates exactly one owning chunk difference")
	var without_farming := restored_world_state.duplicate(true)
	without_farming["farming_state"] = FarmingState.new(int(metadata["seed"])).persistence_snapshot()
	_assert_true(SaveManager.request_save(restored_player, without_farming, 43.75, false), "cleared farming snapshot dispatches a compacting save")
	SaveManager.flush_pending_save()
	_assert_true(not FileAccess.file_exists(farming_difference_path) and _json_file_count(chunks_path) == 5, "removing the last farm cleans its stale farming-only chunk difference")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 43.9, false), "farming fixture can be restored after stale-difference coverage")
	SaveManager.flush_pending_save()
	_assert_true(FileAccess.file_exists(farming_difference_path) and _json_file_count(chunks_path) == 6, "restored farming state recreates exactly one owning chunk difference")
	var without_husbandry := restored_world_state.duplicate(true)
	without_husbandry["husbandry_state"] = HusbandryState.new(int(metadata["seed"])).persistence_snapshot()
	_assert_true(SaveManager.request_save(restored_player, without_husbandry, 43.95, false), "cleared husbandry snapshot dispatches a compacting save")
	SaveManager.flush_pending_save()
	_assert_true(not FileAccess.file_exists(husbandry_difference_path) and _json_file_count(chunks_path) == 5, "removing the last interacted animal cleans its stale husbandry-only chunk difference")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 43.99, false), "husbandry fixture can be restored after stale-difference coverage")
	SaveManager.flush_pending_save()
	_assert_true(FileAccess.file_exists(husbandry_difference_path) and _json_file_count(chunks_path) == 6, "restored husbandry state recreates exactly one owning chunk difference")
	var without_boats := restored_world_state.duplicate(true)
	without_boats["boat_state"] = BoatState.new().persistence_snapshot()
	_assert_true(SaveManager.request_save(restored_player, without_boats, 44.0, false), "cleared boat snapshot dispatches a compacting save")
	SaveManager.flush_pending_save()
	_assert_true(not FileAccess.file_exists(boat_difference_path) and _json_file_count(chunks_path) == 5, "retrieving the final boat cleans its stale boat-only chunk difference")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 44.0, false), "boat fixture can be restored after stale-difference coverage")
	SaveManager.flush_pending_save()
	_assert_true(FileAccess.file_exists(boat_difference_path) and _json_file_count(chunks_path) == 6, "restored boat state recreates exactly one owning chunk difference")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 44.0, true), "manual save requests a backup")
	SaveManager.flush_pending_save()
	_assert_true(_directory_count(root.path_join("backups")) >= 1, "manual save creates a recoverable backup directory")
	_assert_true(DirAccess.dir_exists_absolute(root.path_join("backups").path_join((DirAccess.open(root.path_join("backups")).get_directories() as PackedStringArray)[0]).path_join("chunks/underground")), "manual backup includes the underground difference directory")
	var active_dungeons := DungeonRunState.new()
	var saved_dungeon_id := "dungeon_-17_29"
	active_dungeons.begin(saved_dungeon_id, Vector2i(-1, 0), Vector2(-544.0, 944.0))
	active_dungeons.collect_key("dungeon_-17_29:key:-15:30")
	active_dungeons.trigger_trap("dungeon_-17_29:trap:-14:30")
	var active_dungeon_snapshot := active_dungeons.persistence_snapshot()
	var dungeon_world_state := restored_world_state.duplicate(true)
	dungeon_world_state["world_layer"] = "dungeon"
	dungeon_world_state["dungeon_state"] = active_dungeon_snapshot
	_assert_true(SaveManager.request_save(restored_player, dungeon_world_state, 44.5, false), "active dungeon run dispatches a format-9 save")
	SaveManager.flush_pending_save()
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "active dungeon save reloads through the normal world loader")
	var restored_dungeon_state := SaveManager.loaded_world_state_snapshot()["dungeon_state"] as Dictionary
	var restored_dungeon_probe := DungeonRunState.new()
	_assert_true(SaveManager.current_player_layer() == &"dungeon" and restored_dungeon_probe.restore_snapshot(restored_dungeon_state), "active dungeon reload restores the third world layer and validates its run")
	_assert_true(restored_dungeon_probe.current_dungeon_id() == saved_dungeon_id and int(restored_dungeon_probe.current_run()["key_count"]) == 1 and (restored_dungeon_probe.current_run()["triggered_traps"] as Array).size() == 1, "active dungeon reload preserves exact key and trap progress")
	var normalized_underground_state := SaveManager.loaded_world_state_snapshot()
	normalized_underground_state["world_layer"] = "underground"
	normalized_underground_state["dungeon_state"] = DungeonRunState.new().persistence_snapshot()
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), normalized_underground_state, 44.75, false), "test world can leave its active dungeon before legacy migration coverage")
	SaveManager.flush_pending_save()
	var legacy_metadata := _read_json_for_test(root.path_join("world.json"))
	legacy_metadata["save_version"] = 2
	var legacy_player := _read_json_for_test(root.path_join("player.json"))
	legacy_player["save_version"] = 2
	legacy_player["inventory"] = {"wood": 7, "stone": 3}
	_write_json_for_test(root.path_join("world.json"), legacy_metadata)
	_write_json_for_test(root.path_join("player.json"), legacy_player)
	var difference_directory := DirAccess.open(chunks_path)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var legacy_difference := _read_json_for_test(chunks_path.path_join(filename))
			legacy_difference["save_version"] = 2
			_write_json_for_test(chunks_path.path_join(filename), legacy_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.7 save format loads through the explicit V0.10 migration path")
	var migrated_state := SaveManager.loaded_world_state_snapshot()
	var migrated_inventory := InventoryModel.new()
	_assert_true(migrated_inventory.restore_snapshot(migrated_state["inventory"] as Dictionary), "migrated legacy counts produce a valid slot inventory")
	_assert_true(migrated_inventory.quantity(&"wood") == 7 and migrated_inventory.quantity(&"stone") == 3, "save migration preserves legacy item totals exactly")
	_assert_true(SaveManager.current_player_layer() == &"surface", "legacy save migration initializes the surface world layer")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_state, 45.0, false), "migrated world can be committed as current save format")
	SaveManager.flush_pending_save()
	_assert_equal(int(_read_json_for_test(root.path_join("world.json")).get("save_version", 0)), 26, "next save commits V0.7 world metadata as format 26")
	_assert_equal(int(_read_json_for_test(root.path_join("player.json")).get("save_version", 0)), 26, "next save commits V0.7 player inventory as format 26")
	var v08_metadata := _read_json_for_test(root.path_join("world.json"))
	v08_metadata["save_version"] = 3
	var v08_player := _read_json_for_test(root.path_join("player.json"))
	v08_player["save_version"] = 3
	(v08_player["inventory"] as Dictionary)["schema_version"] = 1
	v08_player.erase("crafting_state")
	_write_json_for_test(root.path_join("world.json"), v08_metadata)
	_write_json_for_test(root.path_join("player.json"), v08_player)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var v08_difference := _read_json_for_test(chunks_path.path_join(filename))
			v08_difference["save_version"] = 3
			_write_json_for_test(chunks_path.path_join(filename), v08_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.8 save format 3 migrates to dungeon-capable format 9")
	_assert_equal(int(SaveManager.loaded_player_snapshot().get("save_version", 0)), 26, "V0.8 migration normalizes player save version in memory")
	_assert_equal(int((SaveManager.loaded_world_state_snapshot()["inventory"] as Dictionary).get("schema_version", 0)), 2, "V0.8 inventory schema upgrades from 1 to 2")
	_assert_true((SaveManager.loaded_world_state_snapshot()["crafting_state"] as Dictionary).has("discovered_items"), "V0.8 migration initializes crafting discovery state")
	_assert_true((SaveManager.loaded_player_snapshot()["combat_state"] as Dictionary).has("respawn_position") and (SaveManager.loaded_world_state_snapshot()["grave_state"] as Dictionary).has("graves"), "V0.8 migration initializes combat and grave state")
	var v09_metadata := _read_json_for_test(root.path_join("world.json"))
	v09_metadata["save_version"] = 4
	var v09_player := SaveManager.loaded_player_snapshot()
	v09_player["save_version"] = 4
	var v09_crafting_snapshot := (v09_player["crafting_state"] as Dictionary).duplicate(true)
	v09_player.erase("combat_state")
	v09_player.erase("grave_state")
	_write_json_for_test(root.path_join("world.json"), v09_metadata)
	_write_json_for_test(root.path_join("player.json"), v09_player)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var v09_difference := _read_json_for_test(chunks_path.path_join(filename))
			v09_difference["save_version"] = 4
			_write_json_for_test(chunks_path.path_join(filename), v09_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.9 save format 4 migrates to dungeon-capable format 9")
	_assert_equal(SaveManager.loaded_world_state_snapshot()["crafting_state"], v09_crafting_snapshot, "V0.9 migration preserves the exact crafting-state object")
	_assert_true((SaveManager.loaded_player_snapshot()["combat_state"] as Dictionary).has("death_count") and (SaveManager.loaded_world_state_snapshot()["grave_state"] as Dictionary).has("next_id"), "V0.9 migration initializes combat status and an empty grave list")
	_assert_true((SaveManager.loaded_world_state_snapshot()["milestone_state"] as Dictionary).has("ruin_discovered"), "legacy migration initializes incomplete V1.0 milestone state")
	var v010_metadata := _read_json_for_test(root.path_join("world.json"))
	v010_metadata["save_version"] = 5
	var v010_player := SaveManager.loaded_player_snapshot()
	v010_player["save_version"] = 5
	v010_player.erase("milestone_state")
	_write_json_for_test(root.path_join("world.json"), v010_metadata)
	_write_json_for_test(root.path_join("player.json"), v010_player)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var v010_difference := _read_json_for_test(chunks_path.path_join(filename))
			v010_difference["save_version"] = 5
			_write_json_for_test(chunks_path.path_join(filename), v010_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.10/V0.11 save format 5 migrates to V1.7 format 9")
	var migrated_milestone := SaveManager.loaded_world_state_snapshot()["milestone_state"] as Dictionary
	_assert_true(not bool(migrated_milestone["ruin_discovered"]) and not bool(migrated_milestone["boss_defeated"]), "format-5 migration starts the new milestone incomplete")
	_assert_true((SaveManager.current_weather_state() as Dictionary).has("current_id"), "legacy migration initializes deterministic clear weather state")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), SaveManager.loaded_world_state_snapshot(), 46.0, false), "legacy milestone save can be normalized before V1.1 migration coverage")
	SaveManager.flush_pending_save()
	var v110_metadata := _read_json_for_test(root.path_join("world.json"))
	v110_metadata["save_version"] = 6
	v110_metadata.erase("weather_state")
	var v110_player := _read_json_for_test(root.path_join("player.json"))
	v110_player["save_version"] = 6
	_write_json_for_test(root.path_join("world.json"), v110_metadata)
	_write_json_for_test(root.path_join("player.json"), v110_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V1.0/V1.1 save format 6 migrates to dungeon-capable format 9")
	_assert_equal(int(SaveManager.loaded_player_snapshot().get("save_version", 0)), 26, "format-6 migration normalizes the player save version")
	_assert_true((SaveManager.current_weather_state() as Dictionary).has("target_id"), "format-6 migration initializes a valid regional weather state")
	var v120_metadata := _read_json_for_test(root.path_join("world.json"))
	v120_metadata["save_version"] = 7
	v120_metadata["weather_state"] = SaveManager.current_weather_state()
	v120_metadata.erase("player_layer")
	var v120_player := SaveManager.loaded_player_snapshot()
	v120_player["save_version"] = 7
	v120_player.erase("world_layer")
	_write_json_for_test(root.path_join("world.json"), v120_metadata)
	_write_json_for_test(root.path_join("player.json"), v120_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V1.2–V1.5 save format 7 migrates to dungeon-capable format 9")
	_assert_true(SaveManager.current_player_layer() == &"surface" and int(SaveManager.loaded_player_snapshot()["save_version"]) == 26, "format-7 migration initializes a valid surface layer")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), SaveManager.loaded_world_state_snapshot(), 47.0, false), "migrated format-7 world can be normalized before corruption coverage")
	SaveManager.flush_pending_save()
	var v160_metadata := _read_json_for_test(root.path_join("world.json"))
	v160_metadata["save_version"] = 8
	var v160_player := _read_json_for_test(root.path_join("player.json"))
	v160_player["save_version"] = 8
	v160_player.erase("dungeon_state")
	_write_json_for_test(root.path_join("world.json"), v160_metadata)
	_write_json_for_test(root.path_join("player.json"), v160_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V1.6 save format 8 migrates to dungeon-capable format 9")
	var migrated_dungeon_state := SaveManager.loaded_world_state_snapshot()["dungeon_state"] as Dictionary
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and String(migrated_dungeon_state.get("current_dungeon_id", "")).is_empty() and (migrated_dungeon_state.get("runs", []) as Array).is_empty(), "format-8 migration initializes a valid empty dungeon state")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), SaveManager.loaded_world_state_snapshot(), 47.5, false), "migrated format-8 world normalizes before current-format corruption coverage")
	SaveManager.flush_pending_save()
	var v170_metadata := _read_json_for_test(root.path_join("world.json"))
	v170_metadata["save_version"] = 9
	v170_metadata["generation_version"] = 4
	v170_metadata["game_version"] = "1.7.0"
	var v170_player := _read_json_for_test(root.path_join("player.json"))
	v170_player["save_version"] = 9
	v170_player.erase("exploration_state")
	v170_player.erase("regional_boss_state")
	_write_json_for_test(root.path_join("world.json"), v170_metadata)
	_write_json_for_test(root.path_join("player.json"), v170_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v170_directory := DirAccess.open(difference_path)
		for filename in v170_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v170_difference := _read_json_for_test(difference_path.path_join(filename))
			v170_difference["save_version"] = 9
			v170_difference["generation_version"] = 4
			_write_json_for_test(difference_path.path_join(filename), v170_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V1.7 save format 9 and generation 4 migrate to V2.0")
	var migrated_v2_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and int((migrated_v2_state["exploration_state"] as Dictionary)["schema_version"]) == ExplorationMapState.SCHEMA_VERSION and (migrated_v2_state["regional_boss_state"] as Dictionary)["defeated_ids"] == [] and (migrated_v2_state["npc_state"] as Dictionary)["records"] == [] and (migrated_v2_state["relationship_state"] as Dictionary)["npcs"] == [] and (migrated_v2_state["quest_state"] as Dictionary)["entries"] == [] and (migrated_v2_state["faction_state"] as Dictionary)["control_points"] == [] and (migrated_v2_state["world_event_state"] as Dictionary)["active"] == [] and (migrated_v2_state["region_progression_state"] as Dictionary)["sources"] == [] and is_equal_approx(float((migrated_v2_state["survival_state"] as Dictionary)["hunger"]), 100.0), "format-9 migration initializes valid empty exploration, civilization, events, region progress and survival")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v2_state, 48.0, false), "migrated V1.7 world can commit current generation metadata")
	SaveManager.flush_pending_save()
	var v200_metadata := _read_json_for_test(root.path_join("world.json"))
	v200_metadata["save_version"] = 10
	v200_metadata["generation_version"] = 5
	v200_metadata["game_version"] = "2.0.0"
	var v200_player := _read_json_for_test(root.path_join("player.json"))
	v200_player["save_version"] = 10
	v200_player.erase("npc_state")
	_write_json_for_test(root.path_join("world.json"), v200_metadata)
	_write_json_for_test(root.path_join("player.json"), v200_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v200_directory := DirAccess.open(difference_path)
		for filename in v200_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v200_difference := _read_json_for_test(difference_path.path_join(filename))
			v200_difference["save_version"] = 10
			v200_difference["generation_version"] = 5
			_write_json_for_test(difference_path.path_join(filename), v200_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.0 save format 10 migrates to V2.1")
	var migrated_v21_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and int((migrated_v21_state["npc_state"] as Dictionary)["schema_version"]) == NpcWorldState.SCHEMA_VERSION and (migrated_v21_state["npc_state"] as Dictionary)["records"] == [] and (migrated_v21_state["relationship_state"] as Dictionary)["npcs"] == [] and (migrated_v21_state["quest_state"] as Dictionary)["entries"] == [] and (migrated_v21_state["faction_state"] as Dictionary)["events"] == [] and (migrated_v21_state["world_event_state"] as Dictionary)["history"] == [] and (migrated_v21_state["region_progression_state"] as Dictionary)["regions"] == [], "format-10 migration initializes valid empty NPC, relationship, quest, faction, event and region state")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v21_state, 48.5, false), "migrated V2.0 world commits save format 25")
	SaveManager.flush_pending_save()
	var v210_metadata := _read_json_for_test(root.path_join("world.json"))
	v210_metadata["save_version"] = 11
	v210_metadata["game_version"] = "2.1.0"
	var v210_player := _read_json_for_test(root.path_join("player.json"))
	v210_player["save_version"] = 11
	v210_player.erase("relationship_state")
	_write_json_for_test(root.path_join("world.json"), v210_metadata)
	_write_json_for_test(root.path_join("player.json"), v210_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.1 save format 11 migrates to V2.2")
	var migrated_v22_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v22_state["relationship_state"] as Dictionary)["npcs"] == [] and (migrated_v22_state["relationship_state"] as Dictionary)["villages"] == [] and (migrated_v22_state["quest_state"] as Dictionary)["entries"] == [] and (migrated_v22_state["faction_state"] as Dictionary)["events"] == [] and (migrated_v22_state["world_event_state"] as Dictionary)["active"] == [], "format-11 migration initializes valid empty relationship, quest, faction and world-event state")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v22_state, 49.0, false), "migrated V2.1 world commits save format 25")
	SaveManager.flush_pending_save()
	var v220_metadata := _read_json_for_test(root.path_join("world.json"))
	v220_metadata["save_version"] = 12
	v220_metadata["game_version"] = "2.2.0"
	var v220_player := _read_json_for_test(root.path_join("player.json"))
	v220_player["save_version"] = 12
	v220_player.erase("quest_state")
	_write_json_for_test(root.path_join("world.json"), v220_metadata)
	_write_json_for_test(root.path_join("player.json"), v220_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.2 save format 12 migrates to V2.3")
	var migrated_v23_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v23_state["quest_state"] as Dictionary)["entries"] == [] and String((migrated_v23_state["quest_state"] as Dictionary)["tracked_id"]).is_empty() and (migrated_v23_state["faction_state"] as Dictionary)["events"] == [] and (migrated_v23_state["world_event_state"] as Dictionary)["history"] == [], "format-12 migration initializes valid empty quest, faction and world-event state")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v23_state, 49.5, false), "migrated V2.2 world commits save format 25")
	SaveManager.flush_pending_save()
	var v230_metadata := _read_json_for_test(root.path_join("world.json"))
	v230_metadata["save_version"] = 13
	v230_metadata["game_version"] = "2.3.0"
	var v230_player := _read_json_for_test(root.path_join("player.json"))
	v230_player["save_version"] = 13
	v230_player.erase("faction_state")
	_write_json_for_test(root.path_join("world.json"), v230_metadata)
	_write_json_for_test(root.path_join("player.json"), v230_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.3 save format 13 migrates to V2.4")
	var migrated_v24_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v24_state["faction_state"] as Dictionary)["standings"].size() == 4 and (migrated_v24_state["faction_state"] as Dictionary)["events"] == [] and (migrated_v24_state["world_event_state"] as Dictionary)["active"] == [], "format-13 migration initializes all default factions and an empty event timetable without fabricating history")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v24_state, 49.75, false), "migrated V2.3 world commits save format 25")
	SaveManager.flush_pending_save()
	var v240_metadata := _read_json_for_test(root.path_join("world.json"))
	v240_metadata["save_version"] = 14
	v240_metadata["game_version"] = "2.4.0"
	var v240_player := _read_json_for_test(root.path_join("player.json"))
	v240_player["save_version"] = 14
	v240_player.erase("world_event_state")
	_write_json_for_test(root.path_join("world.json"), v240_metadata)
	_write_json_for_test(root.path_join("player.json"), v240_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.4 save format 14 migrates to V2.5")
	var migrated_v25_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and int((migrated_v25_state["world_event_state"] as Dictionary)["schema_version"]) == WorldEventState.SCHEMA_VERSION and (migrated_v25_state["world_event_state"] as Dictionary)["active"] == [] and (migrated_v25_state["world_event_state"] as Dictionary)["history"] == [], "format-14 migration initializes an empty deterministic timetable without fabricating outcomes")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v25_state, 50.0, false), "migrated V2.4 world commits save format 25")
	SaveManager.flush_pending_save()
	var v250_metadata := _read_json_for_test(root.path_join("world.json"))
	v250_metadata["save_version"] = 15
	v250_metadata["game_version"] = "2.5.0"
	var v250_player := _read_json_for_test(root.path_join("player.json"))
	v250_player["save_version"] = 15
	v250_player.erase("region_progression_state")
	_write_json_for_test(root.path_join("world.json"), v250_metadata)
	_write_json_for_test(root.path_join("player.json"), v250_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.5 save format 15 migrates to V2.6")
	var migrated_v26_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and int((migrated_v26_state["region_progression_state"] as Dictionary)["schema_version"]) == RegionProgressionState.SCHEMA_VERSION and (migrated_v26_state["region_progression_state"] as Dictionary)["sources"] == [] and (migrated_v26_state["region_progression_state"] as Dictionary)["regions"] == [], "format-15 migration initializes empty region progress without fabricating discoveries or rewards")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v26_state, 50.25, false), "migrated V2.5 world commits save format 25")
	SaveManager.flush_pending_save()
	var v260_metadata := _read_json_for_test(root.path_join("world.json"))
	v260_metadata["save_version"] = 16
	v260_metadata["game_version"] = "2.6.0"
	var v260_player := _read_json_for_test(root.path_join("player.json"))
	v260_player["save_version"] = 16
	v260_player["quest_state"] = {
		"schema_version": 1,
		"tracked_id": changed_quest_snapshot["tracked_id"],
		"entries": (changed_quest_snapshot["entries"] as Array).duplicate(true),
	}
	v260_player.erase("world_choice_state")
	_write_json_for_test(root.path_join("world.json"), v260_metadata)
	_write_json_for_test(root.path_join("player.json"), v260_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V2.6 save format 16 migrates to V3.0")
	var migrated_v30_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and int((migrated_v30_state["quest_state"] as Dictionary)["schema_version"]) == QuestState.SCHEMA_VERSION and (migrated_v30_state["quest_state"] as Dictionary)["entries"] == changed_quest_snapshot["entries"] and (migrated_v30_state["world_choice_state"] as Dictionary)["records"] == [], "format-16 migration preserves fixed quest progress and initializes no fabricated world choices")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v30_state, 50.5, false), "migrated V2.6 world commits save format 25")
	SaveManager.flush_pending_save()
	var v300_metadata := _read_json_for_test(root.path_join("world.json"))
	v300_metadata["save_version"] = 17
	v300_metadata["game_version"] = "3.0.0"
	var v300_player := _read_json_for_test(root.path_join("player.json"))
	v300_player["save_version"] = 17
	v300_player.erase("survival_state")
	_write_json_for_test(root.path_join("world.json"), v300_metadata)
	_write_json_for_test(root.path_join("player.json"), v300_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.0 save format 17 migrates to V3.1")
	var migrated_v31_state := SaveManager.loaded_world_state_snapshot()
	var migrated_survival := migrated_v31_state["survival_state"] as Dictionary
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and is_equal_approx(float(migrated_survival["hunger"]), 100.0) and is_equal_approx(float(migrated_survival["body_temperature"]), 37.0) and is_equal_approx(float(migrated_survival["oxygen"]), 100.0) and (migrated_survival["effects"] as Array).is_empty(), "format-17 migration initializes neutral survival state without fabricated effects")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v31_state, 50.75, false), "migrated V3.0 world commits save format 25")
	SaveManager.flush_pending_save()
	var v310_metadata := _read_json_for_test(root.path_join("world.json"))
	v310_metadata["save_version"] = 18
	v310_metadata["game_version"] = "3.1.0"
	var v310_player := _read_json_for_test(root.path_join("player.json"))
	v310_player["save_version"] = 18
	_write_json_for_test(root.path_join("world.json"), v310_metadata)
	_write_json_for_test(root.path_join("player.json"), v310_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v310_directory := DirAccess.open(difference_path)
		for filename in v310_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v310_difference := _read_json_for_test(difference_path.path_join(filename))
			v310_difference["save_version"] = 18
			v310_difference.erase("placed_buildings")
			_write_json_for_test(difference_path.path_join(filename), v310_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.1 save format 18 migrates to V3.2")
	var migrated_v32_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v32_state["building_state"] as Dictionary)["placements"] == [], "format-18 migration initializes empty player-building differences without fabricating structures")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v32_state, 51.0, false), "migrated V3.1 world commits save format 25")
	SaveManager.flush_pending_save()
	var v320_metadata := _read_json_for_test(root.path_join("world.json"))
	v320_metadata["save_version"] = 19
	v320_metadata["game_version"] = "3.2.0"
	var v320_player := _read_json_for_test(root.path_join("player.json"))
	v320_player["save_version"] = 19
	_write_json_for_test(root.path_join("world.json"), v320_metadata)
	_write_json_for_test(root.path_join("player.json"), v320_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v320_directory := DirAccess.open(difference_path)
		for filename in v320_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v320_difference := _read_json_for_test(difference_path.path_join(filename))
			v320_difference["save_version"] = 19
			v320_difference.erase("farming_plots")
			_write_json_for_test(difference_path.path_join(filename), v320_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.2 save format 19 migrates to V3.3")
	var migrated_v33_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v33_state["farming_state"] as Dictionary)["plots"] == [], "format-19 migration initializes empty farming differences without fabricating crops")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v33_state, 51.25, false), "migrated V3.2 world commits save format 25")
	SaveManager.flush_pending_save()
	var v330_metadata := _read_json_for_test(root.path_join("world.json"))
	v330_metadata["save_version"] = 20
	v330_metadata["game_version"] = "3.3.0"
	var v330_player := _read_json_for_test(root.path_join("player.json"))
	v330_player["save_version"] = 20
	_write_json_for_test(root.path_join("world.json"), v330_metadata)
	_write_json_for_test(root.path_join("player.json"), v330_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v330_directory := DirAccess.open(difference_path)
		for filename in v330_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v330_difference := _read_json_for_test(difference_path.path_join(filename))
			v330_difference["save_version"] = 20
			v330_difference.erase("husbandry_animals")
			_write_json_for_test(difference_path.path_join(filename), v330_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.3 save format 20 migrates to V3.4")
	var migrated_v34_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v34_state["husbandry_state"] as Dictionary)["animals"] == [], "format-20 migration initializes empty husbandry differences without fabricating animals")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v34_state, 51.5, false), "migrated V3.3 world commits save format 25")
	SaveManager.flush_pending_save()
	var v340_metadata := _read_json_for_test(root.path_join("world.json"))
	v340_metadata["save_version"] = 21
	v340_metadata["game_version"] = "3.4.0"
	var v340_player := _read_json_for_test(root.path_join("player.json"))
	v340_player["save_version"] = 21
	_write_json_for_test(root.path_join("world.json"), v340_metadata)
	_write_json_for_test(root.path_join("player.json"), v340_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v340_directory := DirAccess.open(difference_path)
		for filename in v340_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v340_difference := _read_json_for_test(difference_path.path_join(filename))
			v340_difference["save_version"] = 21
			var legacy_placements: Array[Dictionary] = []
			for placement_value in v340_difference.get("placed_buildings", []) as Array:
				var placement := placement_value as Dictionary
				if StringName(placement.get("piece_id", "")) in [&"cooking_pot", &"smelter"]:
					continue
				placement.erase("fuel_units")
				placement.erase("processed_count")
				legacy_placements.append(placement)
			v340_difference["placed_buildings"] = legacy_placements
			_write_json_for_test(difference_path.path_join(filename), v340_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.4 save format 21 migrates to V3.5")
	var migrated_v35_state := SaveManager.loaded_world_state_snapshot()
	var migrated_processors_clean := true
	for placement_value in (migrated_v35_state["building_state"] as Dictionary).get("placements", []) as Array:
		var placement := placement_value as Dictionary
		migrated_processors_clean = migrated_processors_clean and StringName(placement.get("piece_id", "")) not in [&"cooking_pot", &"smelter"] \
				and not placement.has("fuel_units") and not placement.has("processed_count")
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and migrated_processors_clean, "format-21 migration preserves prior buildings without fabricating processors or fuel")
	_assert_true((migrated_v35_state["equipment_state"] as Dictionary)["records"] == [] and (migrated_v35_state["equipment_state"] as Dictionary)["equipped"] == {}, "format-21 migration also initializes no fabricated equipment")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v35_state, 51.75, false), "migrated V3.4 world commits save format 25")
	SaveManager.flush_pending_save()
	var v350_metadata := _read_json_for_test(root.path_join("world.json"))
	v350_metadata["save_version"] = 22
	v350_metadata["game_version"] = "3.5.0"
	var v350_player := _read_json_for_test(root.path_join("player.json"))
	v350_player["save_version"] = 22
	v350_player.erase("equipment_state")
	_write_json_for_test(root.path_join("world.json"), v350_metadata)
	_write_json_for_test(root.path_join("player.json"), v350_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v350_directory := DirAccess.open(difference_path)
		for filename in v350_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v350_difference := _read_json_for_test(difference_path.path_join(filename))
			v350_difference["save_version"] = 22
			_write_json_for_test(difference_path.path_join(filename), v350_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.5 save format 22 migrates to V3.6")
	var migrated_v36_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v36_state["equipment_state"] as Dictionary)["records"] == [] and (migrated_v36_state["equipment_state"] as Dictionary)["equipped"] == {}, "format-22 migration initializes no fabricated equipment instances or slots")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v36_state, 52.0, false), "migrated V3.5 world commits save format 25")
	SaveManager.flush_pending_save()
	var v360_metadata := _read_json_for_test(root.path_join("world.json"))
	v360_metadata["save_version"] = 23
	v360_metadata["game_version"] = "3.6.0"
	var v360_player := _read_json_for_test(root.path_join("player.json"))
	v360_player["save_version"] = 23
	_write_json_for_test(root.path_join("world.json"), v360_metadata)
	_write_json_for_test(root.path_join("player.json"), v360_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v360_directory := DirAccess.open(difference_path)
		for filename in v360_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v360_difference := _read_json_for_test(difference_path.path_join(filename))
			v360_difference["save_version"] = 23
			if difference_path == chunks_path and filename == "10_10.json":
				(v360_difference["placed_buildings"] as Array).append({
					"placement_id": "surface:323:320:structure", "piece_id": "conveyor_belt",
					"world_tile": [323, 320], "rotation": 90,
					"automation_enabled": true, "automation_last_seconds": 40.0,
					"automation_cycles": 2, "automation_status": "working",
				})
			_write_json_for_test(difference_path.path_join(filename), v360_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.6 save format 23 migrates to V3.7")
	var migrated_v37_state := SaveManager.loaded_world_state_snapshot()
	var migrated_automation_clean := true
	for placement_value in (migrated_v37_state["building_state"] as Dictionary).get("placements", []) as Array:
		var placement := placement_value as Dictionary
		migrated_automation_clean = migrated_automation_clean and BuildingCatalog.new().automation_kind(StringName(placement.get("piece_id", ""))).is_empty() \
				and not placement.has("automation_enabled") and not placement.has("automation_last_seconds") and not placement.has("automation_cycles")
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and migrated_automation_clean, "format-23 migration preserves prior buildings without fabricating automation machines or work state")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v37_state, 52.25, false), "migrated V3.6 world commits save format 25")
	SaveManager.flush_pending_save()
	var v370_metadata := _read_json_for_test(root.path_join("world.json"))
	v370_metadata["save_version"] = 24
	v370_metadata["game_version"] = "3.7.0"
	var v370_player := _read_json_for_test(root.path_join("player.json"))
	v370_player["save_version"] = 24
	v370_player.erase("homestead_state")
	_write_json_for_test(root.path_join("world.json"), v370_metadata)
	_write_json_for_test(root.path_join("player.json"), v370_player)
	for difference_path in [chunks_path, underground_chunks_path]:
		var v370_directory := DirAccess.open(difference_path)
		for filename in v370_directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var v370_difference := _read_json_for_test(difference_path.path_join(filename))
			v370_difference["save_version"] = 24
			_write_json_for_test(difference_path.path_join(filename), v370_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V3.7 save format 24 migrates to V4.0")
	var migrated_v40_state := SaveManager.loaded_world_state_snapshot()
	_assert_true(int(SaveManager.loaded_player_snapshot()["save_version"]) == 26 and (migrated_v40_state["homestead_state"] as Dictionary)["bases"] == [] and String((migrated_v40_state["homestead_state"] as Dictionary)["active_base_id"]).is_empty(), "format-24 migration initializes no fabricated base, beacon or active home")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_v40_state, 52.5, false), "migrated V3.7 world commits save format 25")
	SaveManager.flush_pending_save()
	var valid_layered_player := _read_json_for_test(root.path_join("player.json"))
	var mismatched_layered_player := valid_layered_player.duplicate(true)
	mismatched_layered_player["world_layer"] = "underground"
	_write_json_for_test(root.path_join("player.json"), mismatched_layered_player)
	SaveManager.clear_current_world()
	_assert_true(not SaveManager.load_world(world_id) and "不一致" in SaveManager.last_error, "format-25 rejects mismatched player and world layer metadata")
	_write_json_for_test(root.path_join("player.json"), valid_layered_player)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "restoring matching layer metadata recovers the valid world")
	var corrupt_file := FileAccess.open(root.path_join("world.json"), FileAccess.WRITE)
	corrupt_file.store_string("{broken save")
	corrupt_file.flush()
	corrupt_file = null
	SaveManager.clear_current_world()
	_assert_true(not SaveManager.load_world(world_id), "corrupted world metadata is rejected")
	_assert_true("损坏" in SaveManager.last_error and "world.json" in SaveManager.last_error, "corrupted save reports a clear file-specific error")
	SaveManager.clear_current_world()
	_remove_test_save_tree(root)


func _test_stream_planner() -> void:
	var center := Vector2i(-12, 7)
	_assert_equal(ChunkStreamPlanner.coordinates_in_radius(center, ChunkStreamPlanner.ACTIVE_RADIUS).size(), 25, "active radius contains at most 25 chunks")
	_assert_equal(ChunkStreamPlanner.coordinates_in_radius(center, ChunkStreamPlanner.PRELOAD_RADIUS).size(), 49, "preload radius contains at most 49 chunks")
	var ahead := center + Vector2i(3, 0)
	var behind := center + Vector2i(-3, 0)
	_assert_true(ChunkStreamPlanner.priority_score(ahead, center, Vector2i.RIGHT) < ChunkStreamPlanner.priority_score(behind, center, Vector2i.RIGHT), "movement direction receives queue priority")
	var simulated_cache: Array[Vector2i] = []
	var peak_cache := 0
	for minute_step in 1800:
		var simulated_center := Vector2i(minute_step - 900, -17)
		for coordinate in ChunkStreamPlanner.coordinates_in_radius(simulated_center, ChunkStreamPlanner.PRELOAD_RADIUS):
			if not simulated_cache.has(coordinate):
				simulated_cache.append(coordinate)
		simulated_cache = ChunkStreamPlanner.trim_to_cache_radius(simulated_cache, simulated_center)
		peak_cache = maxi(peak_cache, simulated_cache.size())
	_assert_true(peak_cache <= 81 and simulated_cache.size() <= 81, "30-minute traversal simulation keeps cache bounded to 9×9")


func _test_chunk_seams() -> void:
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var left_coordinate := Vector2i(-1, -4)
	var right_coordinate := Vector2i(0, -4)
	var left := generator.generate_chunk(left_coordinate)
	var right := generator.generate_chunk(right_coordinate)
	var seam_coordinates_correct := true
	var samples_match_global_field := true
	var biome_samples_match_global_field := true
	for y in WorldCoordinates.CHUNK_SIZE:
		var left_world := WorldCoordinates.chunk_local_to_tile(left_coordinate, Vector2i(31, y))
		var right_world := WorldCoordinates.chunk_local_to_tile(right_coordinate, Vector2i(0, y))
		seam_coordinates_correct = seam_coordinates_correct and left_world + Vector2i.RIGHT == right_world
		var left_expected := clampi(roundi(generator.elevation_at(left_world) * 255.0), 0, 255)
		var right_expected := clampi(roundi(generator.elevation_at(right_world) * 255.0), 0, 255)
		samples_match_global_field = samples_match_global_field and left.elevation_map[y * 32 + 31] == left_expected and right.elevation_map[y * 32] == right_expected
		biome_samples_match_global_field = biome_samples_match_global_field and left.biome_at(Vector2i(31, y)) == generator.biome_at(left_world) and right.biome_at(Vector2i(0, y)) == generator.biome_at(right_world)
	_assert_true(seam_coordinates_correct, "adjacent chunk border tiles are consecutive world coordinates")
	_assert_true(samples_match_global_field, "both sides of a seam sample the same global noise field")
	_assert_true(biome_samples_match_global_field, "both sides of a seam sample the same global biome field")
	var original_checksum := left.checksum
	generator.generate_chunk(Vector2i(120, -75))
	_assert_equal(generator.generate_chunk(left_coordinate).checksum, original_checksum, "evicted region regenerates identically on return")


func _test_background_generation() -> void:
	var job := ChunkGenerationJob.new(WorldSeed.from_text("线程边境"), Vector2i(-9, 11))
	var task_id := WorkerThreadPool.add_task(job.execute, false, "test_chunk_generation")
	var error := WorkerThreadPool.wait_for_task_completion(task_id)
	_assert_equal(error, OK, "background chunk task completes successfully")
	_assert_equal(job.worker_task_id, task_id, "chunk data was generated on the worker pool")
	_assert_true(job.result is ChunkData and not job.result.has_method("add_child"), "background task returns pure ChunkData without scene-tree APIs")
	var dungeon_id := "dungeon_-17_29"
	var dungeon_job := ChunkGenerationJob.new(WorldSeed.from_text("线程地牢"), Vector2i(-1, 0), &"dungeon", dungeon_id, Vector2i(-1, 0))
	var dungeon_task_id := WorkerThreadPool.add_task(dungeon_job.execute, false, "test_dungeon_generation")
	var dungeon_error := WorkerThreadPool.wait_for_task_completion(dungeon_task_id)
	_assert_equal(dungeon_error, OK, "background dungeon task completes successfully")
	_assert_true(dungeon_job.result is ChunkData and dungeon_job.result.world_layer == &"dungeon" and dungeon_job.result.dungeon_cell_map.size() == 1024, "background dungeon task returns complete pure chunk data")


func _test_chunk_renderer() -> void:
	var renderer := ChunkRenderer.new()
	add_child(renderer)
	await get_tree().process_frame
	var chunk := TerrainGenerator.new(WorldSeed.from_text("无尽边境")).generate_chunk(Vector2i(-1, -4))
	var building_origin := chunk.chunk_position * WorldCoordinates.CHUNK_SIZE + Vector2i(10, 10)
	var rendered_buildings: Array[Dictionary] = [
		{"placement_id": "fixture:floor", "piece_id": "wood_floor", "world_tile": [building_origin.x, building_origin.y], "rotation": 0},
		{"placement_id": "fixture:wall", "piece_id": "wood_wall", "world_tile": [building_origin.x, building_origin.y], "rotation": 90},
		{"placement_id": "fixture:roof", "piece_id": "basic_roof", "world_tile": [building_origin.x, building_origin.y], "rotation": 180},
		{"placement_id": "fixture:door", "piece_id": "wood_door", "world_tile": [building_origin.x + 1, building_origin.y], "rotation": 270, "door_open": true},
	]
	renderer.set_player_buildings(rendered_buildings)
	var rendered_farming: Array[Dictionary] = [
		{"plot_id": "fixture:farm:1", "world_tile": [building_origin.x + 2, building_origin.y], "last_simulated_day": 4, "watered_day": 4, "crop_id": "wheat", "stage": 3, "mature": true},
		{"plot_id": "fixture:farm:2", "world_tile": [building_origin.x + 3, building_origin.y], "last_simulated_day": 4, "watered_day": -1, "crop_id": "", "stage": 0, "mature": false},
	]
	renderer.set_farming_plots(rendered_farming)
	var rendered_wild_animals: Array[Dictionary] = [
		{"animal_id": "wild:renderer", "animal_type": "cow", "world_tile": [building_origin.x + 4, building_origin.y], "sex": "female", "wild": true},
	]
	var rendered_interacted_animals: Array[Dictionary] = [
		{"animal_id": "wild:renderer:tamed", "animal_type": "chicken", "world_tile": [building_origin.x + 5, building_origin.y], "sex": "male", "tamed": true, "sleeping": true, "last_simulated_day": 4, "adult_day": 1, "product_ready": 1},
	]
	renderer.set_husbandry_animals(rendered_wild_animals, rendered_interacted_animals)
	renderer.apply_chunk(chunk)
	_assert_equal(renderer.get_used_cells().size(), 1024, "TileMapLayer renders every chunk tile")
	_assert_equal(renderer.get_used_rect(), Rect2i(0, 0, 32, 32), "chunk renderer uses bounded local TileMap coordinates")
	_assert_equal(renderer.position, WorldCoordinates.tile_to_world_pixel(Vector2i(-32, -128)), "chunk renderer node carries the world offset")
	_assert_true(renderer.visible_player_building_count() == 4 and renderer.solid_player_building_count() == 1, "player building renderer batches three layers and removes collision from an open door")
	_assert_true(renderer.visible_farming_plot_count() == 2 and renderer.mature_farming_crop_count() == 1, "farming renderer batches tilled, watered, growing and mature plot presentation")
	_assert_true(renderer.visible_husbandry_animal_count() == 2 and renderer.tamed_husbandry_animal_count() == 1 and renderer.sleeping_husbandry_animal_count() == 1, "animal renderer distinguishes deterministic wild, tamed, product-ready and sleeping presentation")
	var player_building_layer: PlayerBuildingLayer
	for child in renderer.get_children():
		if child is PlayerBuildingLayer:
			player_building_layer = child as PlayerBuildingLayer
			break
	var player_structure_layer := player_building_layer.find_child("PlayerBuildingStructure", true, false) as TileMapLayer if player_building_layer != null else null
	var open_door_local := WorldCoordinates.tile_to_local(building_origin + Vector2i.RIGHT)
	var open_door_collision_count := -1
	if player_structure_layer != null:
		var open_door_source := player_structure_layer.tile_set.get_source(player_structure_layer.get_cell_source_id(open_door_local)) as TileSetAtlasSource
		var open_door_data := open_door_source.get_tile_data(player_structure_layer.get_cell_atlas_coords(open_door_local), 0)
		open_door_collision_count = open_door_data.get_collision_polygons_count(0)
	_assert_true(player_building_layer != null and player_structure_layer != null and open_door_collision_count == 0, "open player door uses a collision-free rendered tile variant")
	(rendered_buildings[3] as Dictionary)["door_open"] = false
	renderer.set_player_buildings(rendered_buildings)
	_assert_true(renderer.solid_player_building_count() == 2, "closing the player door restores its solid collision state")
	var expected_visible_resources := 0
	for resource_index in chunk.resource_count():
		if not chunk.has_built_overlay_at(chunk.resource_local_at(resource_index)):
			expected_visible_resources += 1
	_assert_equal(renderer.visible_resource_count(), expected_visible_resources, "resource TileMapLayer hides resources covered by structures")
	var resource_layer: ResourceChunkLayer
	var structure_layer: StructureChunkLayer
	var village_layer: VillageChunkLayer
	var cave_layer: CaveChunkLayer
	var dungeon_layer: DungeonChunkLayer
	for child in renderer.get_children():
		if child is ResourceChunkLayer:
			resource_layer = child as ResourceChunkLayer
		elif child is StructureChunkLayer:
			structure_layer = child as StructureChunkLayer
		elif child is VillageChunkLayer:
			village_layer = child as VillageChunkLayer
		elif child is CaveChunkLayer:
			cave_layer = child as CaveChunkLayer
		elif child is DungeonChunkLayer:
			dungeon_layer = child as DungeonChunkLayer
	_assert_true(resource_layer != null and resource_layer.tile_set.get_physics_layers_count() == 1, "resource TileMapLayer owns a shared collision layer")
	_assert_true(structure_layer != null and structure_layer.tile_set.get_physics_layers_count() == 1, "structure TileMapLayer owns a shared wall-collision layer")
	_assert_true(village_layer != null, "village roads and buildings use a dedicated batched TileMap layer")
	_assert_true(cave_layer != null and cave_layer.tile_set.get_physics_layers_count() == 1, "cave overlay owns a dedicated wall-collision layer")
	_assert_true(dungeon_layer != null and dungeon_layer.tile_set.get_physics_layers_count() == 1, "dungeon overlay owns a dedicated wall-and-door collision layer")
	var solid_collision_found := false
	if resource_layer != null:
		var catalog := ResourceCatalog.new()
		for index in chunk.resource_count():
			if not catalog.is_solid(chunk.resource_code_at(index)):
				continue
			var local := chunk.resource_local_at(index)
			var source := resource_layer.tile_set.get_source(resource_layer.get_cell_source_id(local)) as TileSetAtlasSource
			var tile_data := source.get_tile_data(resource_layer.get_cell_atlas_coords(local), 0)
			solid_collision_found = tile_data.get_collision_polygons_count(0) > 0
			break
	_assert_true(solid_collision_found, "solid trees, rocks or berry bushes expose physical collision polygons")
	var collectible_index := -1
	for resource_index in chunk.resource_count():
		if not chunk.has_built_overlay_at(chunk.resource_local_at(resource_index)):
			collectible_index = resource_index
			break
	if collectible_index >= 0:
		var collected := {chunk.resource_key_at(collectible_index): true}
		renderer.set_collected_resources(collected)
		_assert_equal(renderer.visible_resource_count(), expected_visible_resources - 1, "collected resource remains hidden when a chunk renderer refreshes")
	var structure_fixture := ChunkData.new()
	structure_fixture.base_tiles.resize(1024)
	structure_fixture.add_structure_cell(Vector2i(3, 3), 0, StructureCatalog.TileKind.FLOOR, StructureCatalog.MarkerKind.NONE)
	structure_fixture.add_structure_cell(Vector2i(4, 3), 0, StructureCatalog.TileKind.WALL, StructureCatalog.MarkerKind.NONE)
	structure_fixture.add_structure_cell(Vector2i(5, 3), 0, StructureCatalog.TileKind.CHEST, StructureCatalog.MarkerKind.CHEST)
	structure_layer.apply_chunk(structure_fixture)
	_assert_equal(structure_layer.get_used_cells().size(), 3, "structure layer batches template cells without per-cell nodes")
	_assert_equal(structure_layer.marker_count(StructureCatalog.MarkerKind.CHEST), 1, "structure layer preserves interactive chest markers")
	var wall_source := structure_layer.tile_set.get_source(structure_layer.get_cell_source_id(Vector2i(4, 3))) as TileSetAtlasSource
	var wall_data := wall_source.get_tile_data(structure_layer.get_cell_atlas_coords(Vector2i(4, 3)), 0)
	_assert_true(wall_data.get_collision_polygons_count(0) == 1, "structure walls expose physical collision")
	var village_fixture := ChunkData.new()
	village_fixture.base_tiles.resize(1024)
	village_fixture.village_feature_map.resize(1024)
	village_fixture.village_feature_map[3 * 32 + 3] = VillagePlanner.Feature.ROAD
	village_fixture.village_feature_map[3 * 32 + 4] = VillagePlanner.Feature.BRIDGE
	village_fixture.village_feature_map[3 * 32 + 5] = VillagePlanner.Feature.SHOP
	village_fixture.add_village_marker(Vector2i(5, 3), VillagePlanner.Marker.SHOP)
	village_layer.apply_chunk(village_fixture)
	_assert_equal(village_layer.get_used_cells().size(), 3, "village layer batches roads, bridges and buildings without per-cell nodes")
	_assert_equal(village_layer.marker_count(VillagePlanner.Marker.SHOP), 1, "village layer preserves shop markers")
	var cave_fixture := ChunkData.new()
	cave_fixture.world_layer = &"underground"
	cave_fixture.chunk_position = Vector2i(-2, 3)
	cave_fixture.base_tiles.resize(1024)
	cave_fixture.biome_map.resize(1024)
	cave_fixture.temperature_map.resize(1024)
	cave_fixture.moisture_map.resize(1024)
	cave_fixture.elevation_map.resize(1024)
	cave_fixture.cave_cell_map.resize(1024)
	cave_fixture.cave_cell_map.fill(CaveGenerator.Cell.FLOOR)
	cave_fixture.cave_feature_map.resize(1024)
	cave_fixture.cave_cell_map[3 * 32 + 3] = CaveGenerator.Cell.WALL
	cave_fixture.cave_feature_map[3 * 32 + 4] = CaveGenerator.Feature.TORCH
	cave_fixture.cave_feature_map[3 * 32 + 5] = CaveGenerator.Feature.CHEST
	renderer.apply_chunk(cave_fixture)
	_assert_true(cave_layer.wall_count() == 1 and cave_layer.feature_count(CaveGenerator.Feature.TORCH) == 1 and cave_layer.feature_count(CaveGenerator.Feature.CHEST) == 1, "cave layer batches walls, torches and unopened chests")
	var cave_wall_source := cave_layer.tile_set.get_source(cave_layer.get_cell_source_id(Vector2i(3, 3))) as TileSetAtlasSource
	var cave_wall_data := cave_wall_source.get_tile_data(cave_layer.get_cell_atlas_coords(Vector2i(3, 3)), 0)
	_assert_true(cave_wall_data.get_collision_polygons_count(0) == 1, "cave wall cells expose physical collision")
	renderer.set_opened_cave_chests({"underground:-59:99": true})
	_assert_equal(cave_layer.feature_count(CaveGenerator.Feature.CHEST), 0, "opened underground chest stays hidden when its chunk refreshes")
	var dungeon_id := "dungeon_-17_29"
	var dungeon_anchor := Vector2i(-1, 0)
	var dungeon_chunk := DungeonGenerator.new(WorldSeed.from_text("renderer-dungeon"), dungeon_id, dungeon_anchor).generate_chunk(dungeon_anchor)
	var door_local := _first_dungeon_feature_local(dungeon_chunk, DungeonGenerator.Feature.LOCKED_DOOR)
	var chest_local := _first_dungeon_feature_local(dungeon_chunk, DungeonGenerator.Feature.CHEST)
	var wall_local := _first_dungeon_wall_local(dungeon_chunk)
	renderer.set_dungeon_state(dungeon_id, {})
	renderer.apply_chunk(dungeon_chunk)
	_assert_true(dungeon_layer.wall_count() > 0 and dungeon_layer.feature_count(DungeonGenerator.Feature.LOCKED_DOOR) == 2 and dungeon_layer.feature_count(DungeonGenerator.Feature.CHEST) == 2, "dungeon layer batches walls, locks and unopened chests")
	var dungeon_wall_source := dungeon_layer.tile_set.get_source(dungeon_layer.get_cell_source_id(wall_local)) as TileSetAtlasSource
	var dungeon_wall_data := dungeon_wall_source.get_tile_data(dungeon_layer.get_cell_atlas_coords(wall_local), 0)
	var dungeon_door_source := dungeon_layer.tile_set.get_source(dungeon_layer.get_cell_source_id(door_local)) as TileSetAtlasSource
	var dungeon_door_data := dungeon_door_source.get_tile_data(dungeon_layer.get_cell_atlas_coords(door_local), 0)
	_assert_true(dungeon_wall_data.get_collision_polygons_count(0) == 1 and dungeon_door_data.get_collision_polygons_count(0) == 1, "dungeon walls and locked doors expose physical collision")
	var door_world_tile := WorldCoordinates.chunk_local_to_tile(dungeon_anchor, door_local)
	var chest_world_tile := WorldCoordinates.chunk_local_to_tile(dungeon_anchor, chest_local)
	renderer.set_dungeon_state(dungeon_id, {
		"unlocked_doors": [DungeonGenerator.feature_key(dungeon_id, DungeonGenerator.Feature.LOCKED_DOOR, door_world_tile)],
		"opened_chests": [DungeonGenerator.feature_key(dungeon_id, DungeonGenerator.Feature.CHEST, chest_world_tile)],
	})
	_assert_true(dungeon_layer.feature_count(DungeonGenerator.Feature.LOCKED_DOOR) == 1 and dungeon_layer.feature_count(DungeonGenerator.Feature.CHEST) == 1, "resolved dungeon door and chest remain hidden after renderer refresh")
	renderer.set_debug_options(ChunkRenderer.ViewMode.BIOME, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "biome debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.CLIMATE, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "climate debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.ELEVATION, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "elevation debug view preserves cell coverage")
	renderer.queue_free()


func _test_building_runtime() -> void:
	var seed := WorldSeed.from_text("V3.2-building-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	var player_tile := terrain.find_land_near(initial_chunk)
	player.position = WorldCoordinates.tile_to_world_pixel(player_tile, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	for entry in [[&"wood", 40], [&"stone", 10], [&"fiber", 10], [&"workbench", 1], [&"campfire", 1]]:
		inventory.add_item(entry[0] as StringName, int(entry[1]))
	var build_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-5, 6):
		for offset_x in range(-5, 6):
			var candidate := player_tile + Vector2i(offset_x, offset_y)
			if candidate == player_tile or WorldCoordinates.tile_to_chunk(candidate) != start_chunk:
				continue
			if bool(manager.building_preview(&"wood_floor", candidate, 0).get("valid", false)):
				build_tile = candidate
				break
		if build_tile.x != 2147483647:
			break
	_assert_true(build_tile.x != 2147483647, "runtime building fixture finds a dry, empty loaded tile inside placement range")
	if build_tile.x == 2247483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	var wood_before := inventory.quantity(&"wood")
	var floor_result := manager.place_building(&"wood_floor", build_tile, 0)
	var wall_result := manager.place_building(&"wood_wall", build_tile, 90)
	_assert_true(bool(floor_result["ok"]) and bool(wall_result["ok"]) and inventory.quantity(&"wood") == wood_before - 5, "runtime placement validates and atomically deducts exact floor and wall materials")
	var owning_renderer: ChunkRenderer
	for child in manager.get_children():
		if not child is ChunkRenderer:
			continue
		var renderer := child as ChunkRenderer
		var renderer_chunk := WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(renderer.global_position))
		if renderer_chunk == start_chunk:
			owning_renderer = renderer
			break
	_assert_true(owning_renderer != null and owning_renderer.visible_player_building_count() == 2 and owning_renderer.solid_player_building_count() == 1, "runtime placement refreshes the owning chunk's layered collision renderer immediately")
	var demolition := manager.demolish_building(build_tile)
	_assert_true(bool(demolition["ok"]) and inventory.quantity(&"wood") == wood_before - 4 and owning_renderer.visible_player_building_count() == 1, "runtime demolition removes the top layer and commits its configured refund")
	var workbench_result := manager.place_building(&"workbench", build_tile, 180)
	player.global_position = WorldCoordinates.tile_to_world_pixel(build_tile, true)
	manager._update_building_context()
	var stone_sword_view: Dictionary = {}
	for view_value in manager.crafting_views():
		var view := view_value as Dictionary
		if String(view["recipe_id"]) == "stone_sword":
			stone_sword_view = view
			break
	_assert_true(bool(workbench_result["ok"]) and bool(stone_sword_view.get("unlocked", false)) and inventory.quantity(&"workbench") == 0, "placed workbench supplies the existing nearby crafting station after its inventory item is consumed")
	var campfire_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-5, 6):
		for offset_x in range(-5, 6):
			var candidate := build_tile + Vector2i(offset_x, offset_y)
			if candidate == build_tile or WorldCoordinates.tile_to_chunk(candidate) != start_chunk:
				continue
			if bool(manager.building_preview(&"campfire", candidate, 0).get("valid", false)):
				campfire_tile = candidate
				break
		if campfire_tile.x != 2147483647:
			break
	_assert_true(campfire_tile.x != 2147483647 and bool(manager.place_building(&"campfire", campfire_tile, 0)["ok"]), "runtime fixture places a separate outdoor campfire on a valid loaded tile")
	player.global_position = WorldCoordinates.tile_to_world_pixel(campfire_tile, true)
	manager._update_building_context()
	_assert_true(manager.is_near_player_heat_source(), "placed campfire contributes to runtime lighting and survival heat proximity")
	var runtime_buildings := manager.persistence_snapshot()["building_state"] as Dictionary
	_assert_true((runtime_buildings["placements"] as Array).size() == 3 and owning_renderer.visible_player_building_count() == 3 and int(manager.metrics_snapshot()["player_buildings"]) == 3, "runtime building state, renderer and streaming metrics share one exact placement count")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_processing_runtime() -> void:
	var seed := WorldSeed.from_text("V3.5-processing-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	var player_tile := terrain.find_land_near(initial_chunk)
	player.position = WorldCoordinates.tile_to_world_pixel(player_tile, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	for entry in [[&"wood", 4], [&"cooking_pot", 1], [&"carrot", 1], [&"tomato", 1], [&"milk", 1]]:
		inventory.add_item(entry[0] as StringName, int(entry[1]))
	var processor_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-5, 6):
		for offset_x in range(-5, 6):
			var candidate := player_tile + Vector2i(offset_x, offset_y)
			if candidate == player_tile or WorldCoordinates.tile_to_chunk(candidate) != start_chunk:
				continue
			if bool(manager.building_preview(&"wood_floor", candidate, 0).get("valid", false)):
				processor_tile = candidate
				break
		if processor_tile.x != 2147483647:
			break
	_assert_true(processor_tile.x != 2147483647, "runtime processing fixture finds one supported dry station tile")
	if processor_tile.x == 2147483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	_assert_true(bool(manager.place_building(&"wood_floor", processor_tile, 0)["ok"]) and bool(manager.place_building(&"cooking_pot", processor_tile, 0)["ok"]), "runtime fixture places a persistent cooking pot on its floor")
	player.global_position = WorldCoordinates.tile_to_world_pixel(processor_tile, true)
	var fuel_result := manager.add_processing_fuel(&"cooking_pot", &"wood")
	var cook_result := manager.process_recipe(&"vegetable_stew")
	var processing_state := manager.processing_state_snapshot()
	var cooking_station := (processing_state["stations"] as Array)[0] as Dictionary
	_assert_true(bool(fuel_result["ok"]) and bool(cook_result["ok"]) and inventory.quantity(&"vegetable_stew") == 1 and inventory.quantity(&"wood") == 1, "runtime manager commits one exact fuel-and-multi-material cooking transaction")
	_assert_true(bool(cooking_station["available"]) and int(cooking_station["fuel_units"]) == 0 and int(cooking_station["processed_count"]) == 1, "runtime processing view reflects nearest device fuel and completed-operation count")
	var persisted := manager.persistence_snapshot()["building_state"] as Dictionary
	var processor_record := (persisted["placements"] as Array)[1] as Dictionary
	_assert_true(String(processor_record["piece_id"]) == "cooking_pot" and int(processor_record["processed_count"]) == 1, "runtime processor state enters the chunk-owned building save snapshot")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_equipment_runtime() -> void:
	var seed := WorldSeed.from_text("V3.6-equipment-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(terrain.find_land_near(initial_chunk), true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	for item_id in [&"copper_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots"]:
		inventory.add_item(item_id, 1)
	inventory.add_item(&"tempered_plate", 2)
	inventory.add_item(&"iron_ingot", 4)
	for item_id in [&"copper_sword", &"copper_helmet", &"copper_chestplate", &"copper_boots"]:
		_assert_true(bool(manager.import_equipment_slot(_find_item_slot(inventory, item_id))["ok"]), "runtime manager imports %s without duplication" % item_id)
	var equipment_state := manager.equipment_state_snapshot()
	_assert_true((equipment_state["owned"] as Array).size() == 4 and manager.active_weapon_id() == &"copper_sword", "runtime equipment owns four instances and overrides the hotbar weapon")
	_assert_true(manager.equipment_attack_bonus() > 0.0 and player.combat_state().effective_defense() > player.combat_state().defense, "runtime equipment applies attack and armor defense to combat")
	var weapon_record := ((equipment_state["slots"] as Array)[0] as Dictionary)["record"] as Dictionary
	var weapon_instance_id := int(weapon_record["instance_id"])
	var before_bonus := manager.equipment_attack_bonus()
	var enhance := manager.enhance_equipment(weapon_instance_id)
	_assert_true(bool(enhance["ok"]) and manager.equipment_attack_bonus() > before_bonus, "runtime enhancement consumes inventory material and refreshes combat stats")
	manager.consume_selected_weapon_durability()
	var repair := manager.repair_equipment(weapon_instance_id)
	_assert_true(bool(repair["ok"]), "runtime repair restores equipment durability through the manager path")
	var persisted := manager.persistence_snapshot()["equipment_state"] as Dictionary
	_assert_true((persisted["records"] as Array).size() == 4 and int(persisted["next_instance_id"]) == 5 and (persisted["equipped"] as Dictionary).size() == 4, "runtime equipment instances and slots enter player-owned persistence")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_automation_runtime() -> void:
	var seed := WorldSeed.from_text("V3.7-automation-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(terrain.find_land_near(initial_chunk), true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var fixture := _automation_line_snapshot(&"conveyor_belt", [{"item_id": "stone", "quantity": 2}])
	_assert_true(manager._building_state.restore_snapshot(fixture), "runtime manager accepts one automation line in an unloaded surface chunk")
	manager._on_time_state_changed({"day": 1, "phase": "DAY", "total_seconds": 0.0})
	manager._on_time_state_changed({"day": 1, "phase": "DAY", "total_seconds": 5.0})
	var runtime_view := manager.automation_state_snapshot()
	var machine_view := (runtime_view["machines"] as Array)[0] as Dictionary
	_assert_true(_storage_quantity_for_test(manager._building_state.placement("surface:0:0:structure"), &"stone") == 1 and _storage_quantity_for_test(manager._building_state.placement("surface:2:0:structure"), &"stone") == 1, "runtime time events advance automation independently of chunk renderer loading")
	_assert_true(int(runtime_view["machine_count"]) == 1 and int(manager.metrics_snapshot()["automation_machines"]) == 1 and String(machine_view["status"]) == "working", "runtime automation view and streaming metrics expose the same machine state")
	var toggle := manager.toggle_automation_machine(String(machine_view["placement_id"]))
	_assert_true(bool(toggle["ok"]) and not bool(manager._building_state.placement("surface:1:0:structure")["automation_enabled"]), "runtime automation controls commit through the stream-manager API")
	var persisted := manager.persistence_snapshot()["building_state"] as Dictionary
	var restored := BuildingState.new()
	_assert_true(restored.restore_snapshot(persisted) and restored.persistence_snapshot() == persisted, "runtime automation state enters chunk-owned world persistence exactly")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_homestead_runtime() -> void:
	var seed := WorldSeed.from_text("V4.0-homestead-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	var player_tile := terrain.find_land_near(initial_chunk)
	player.position = WorldCoordinates.tile_to_world_pixel(player_tile, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	for entry in [[&"wood", 8], [&"stone", 8], [&"iron_ingot", 2]]:
		inventory.add_item(entry[0] as StringName, int(entry[1]))
	var marker_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-5, 6):
		for offset_x in range(-5, 6):
			var candidate := player_tile + Vector2i(offset_x, offset_y)
			if candidate == player_tile or WorldCoordinates.tile_to_chunk(candidate) != start_chunk:
				continue
			if bool(manager.building_preview(&"homestead_beacon", candidate, 0).get("valid", false)):
				marker_tile = candidate
				break
		if marker_tile.x != 2147483647:
			break
	_assert_true(marker_tile.x != 2147483647, "runtime homestead fixture finds a dry loaded beacon tile")
	if marker_tile.x == 2147483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	var placement := manager.place_building(&"homestead_beacon", marker_tile, 0)
	var home_view := manager.homestead_state_snapshot()
	_assert_true(bool(placement["ok"]) and int(home_view["base_count"]) == 1 and int(manager.metrics_snapshot()["homestead_bases"]) == 1, "runtime beacon placement atomically establishes one managed base and metric")
	player.global_position = WorldCoordinates.tile_to_world_pixel(marker_tile + Vector2i(8, 0), true)
	manager._on_time_state_changed({"day": 1, "phase": "DAY", "total_seconds": 500.0})
	var travel := manager.try_home_teleport()
	_assert_true(bool(travel["ok"]) and WorldCoordinates.world_pixel_to_tile(player.global_position) == marker_tile, "runtime home travel safely rebuilds streaming state at the exact beacon tile")
	_assert_true(float(manager.homestead_state_snapshot()["teleport_cooldown_remaining"]) > 119.0, "runtime home travel starts its persisted cooldown only after relocation")
	var persisted_world := manager.persistence_snapshot()
	var restored_buildings := BuildingState.new()
	var restored_home := HomesteadState.new()
	_assert_true(restored_buildings.restore_snapshot(persisted_world["building_state"] as Dictionary) and restored_home.restore_snapshot(persisted_world["homestead_state"] as Dictionary, restored_buildings), "runtime base and marker snapshots validate together without a second building owner")
	var demolition := manager.demolish_building(marker_tile)
	_assert_true(bool(demolition["ok"]) and int(manager.homestead_state_snapshot()["base_count"]) == 0, "demolishing the final beacon removes its base and active home immediately")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_ocean_runtime() -> void:
	var seed := WorldSeed.from_text("V4.1-ocean-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	var player_tile := terrain.find_land_near(initial_chunk)
	player.position = WorldCoordinates.tile_to_world_pixel(player_tile, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	inventory.add_item(&"rowboat", 1)
	var boat_slot := _find_item_slot(inventory, &"rowboat")
	_assert_true(boat_slot >= 0 and manager.select_hotbar_slot(boat_slot), "runtime fixture equips the crafted rowboat")
	var water_tile := Vector2i(2147483647, 2147483647)
	var stand_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-6, 7):
		for offset_x in range(-6, 7):
			var candidate := player_tile + Vector2i(offset_x, offset_y)
			var candidate_terrain := terrain.terrain_at(candidate)
			if candidate_terrain != ChunkData.Terrain.SHALLOW_WATER and candidate_terrain != ChunkData.Terrain.DEEP_WATER:
				continue
			water_tile = candidate
			break
		if water_tile.x != 2147483647:
			break
	_assert_true(water_tile.x != 2147483647, "runtime ocean fixture finds a water tile near the shore")
	if water_tile.x == 2147483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	var delta := water_tile - player_tile
	if absi(delta.x) >= absi(delta.y):
		stand_tile = water_tile + Vector2i(1 if delta.x <= 0 else -1, 0)
	else:
		stand_tile = water_tile + Vector2i(0, 1 if delta.y <= 0 else -1)
	player.global_position = WorldCoordinates.tile_to_world_pixel(stand_tile, true)
	player.facing = Vector2(water_tile - stand_tile)
	var deployed := manager.try_interact_boat()
	_assert_true(deployed and not manager.boat_state().boat_at(water_tile).is_empty() and inventory.quantity(&"rowboat") == 0, "interacting with a rowboat deploys it onto the facing water tile and consumes the item")
	var boarded := manager.try_interact_boat()
	_assert_true(boarded and not manager.boarded_boat_id().is_empty(), "a second interaction boards the adjacent deployed boat")
	var sail_tile := water_tile + (Vector2i(1, 0) if absi(delta.x) >= absi(delta.y) else Vector2i(0, 1))
	var sail_water := terrain.terrain_at(sail_tile) == ChunkData.Terrain.SHALLOW_WATER or terrain.terrain_at(sail_tile) == ChunkData.Terrain.DEEP_WATER
	if sail_water:
		player.global_position = WorldCoordinates.tile_to_world_pixel(sail_tile, true)
		manager._update_boat_follow()
		_assert_true(not manager.boarded_boat_id().is_empty(), "sailing across water keeps the session boarding state")
	var shore_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-4, 5):
		for offset_x in range(-4, 5):
			var candidate := (sail_tile if sail_water else water_tile) + Vector2i(offset_x, offset_y)
			if terrain.terrain_at(candidate) == ChunkData.Terrain.LAND or terrain.terrain_at(candidate) == ChunkData.Terrain.BEACH:
				shore_tile = candidate
				break
		if shore_tile.x != 2147483647:
			break
	_assert_true(shore_tile.x != 2147483647, "runtime ocean fixture finds a shore tile near the moored boat")
	if shore_tile.x != 2147483647:
		player.global_position = WorldCoordinates.tile_to_world_pixel(shore_tile, true)
		manager._update_boat_follow()
		var moor_tile := sail_tile if sail_water else water_tile
		_assert_true(manager.boarded_boat_id().is_empty() and not manager.boat_state().boat_at(moor_tile).is_empty(), "reaching dry land moors the boat at its last water tile and disembarks automatically")
	var persisted_world := manager.persistence_snapshot()
	var restored_boats := BoatState.new()
	_assert_true(restored_boats.restore_snapshot(persisted_world["boat_state"] as Dictionary) and restored_boats.boat_count() >= 1, "runtime boat state persists into the world snapshot")
	player.set_ocean_state(0.55, true, 5.0)
	_assert_true(is_equal_approx(player.terrain_speed_multiplier, 0.55) and player.in_terrain_water, "player ocean state composes swim speed and water flags")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_farming_runtime() -> void:
	var seed := WorldSeed.from_text("V3.3-farming-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var initial_chunk := terrain.generate_chunk(start_chunk)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	var player_tile := terrain.find_land_near(initial_chunk)
	player.position = WorldCoordinates.tile_to_world_pixel(player_tile, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	inventory.add_item(&"wheat_seed", 2)
	inventory.add_item(&"basic_fertilizer", 1)
	var farm_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-5, 6):
		for offset_x in range(-5, 6):
			var candidate := player_tile + Vector2i(offset_x, offset_y)
			if candidate == player_tile or WorldCoordinates.tile_to_chunk(candidate) != start_chunk:
				continue
			if bool(manager.farming_target_status(&"wheat", candidate).get("valid", false)):
				farm_tile = candidate
				break
		if farm_tile.x != 2147483647:
			break
	_assert_true(farm_tile.x != 2147483647, "runtime farming fixture finds a dry, empty loaded tile inside interaction range")
	if farm_tile.x == 2247483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	var till_result := manager.perform_farming_action(&"wheat", farm_tile)
	var seed_before := inventory.quantity(&"wheat_seed")
	var plant_result := manager.perform_farming_action(&"wheat", farm_tile)
	_assert_true(bool(till_result["ok"]) and bool(plant_result["ok"]) and inventory.quantity(&"wheat_seed") == seed_before - 1, "runtime action cycle opens land then atomically sows the selected seed")
	_assert_true(not bool(manager.building_preview(&"wood_floor", farm_tile, 0)["valid"]), "building placement cannot overlap a persistent farming plot")
	var fertilize_result := manager.fertilize_farming_plot(farm_tile)
	var water_result := manager.perform_farming_action(&"wheat", farm_tile)
	_assert_true(bool(fertilize_result["ok"]) and bool(water_result["ok"]) and inventory.quantity(&"basic_fertilizer") == 0, "runtime watering and fertilizer mutate one plot and exact inventory inputs")
	manager._on_weather_state_changed({"weather_id": "RAIN", "resource_yield_multiplier": 1.0})
	manager._on_time_state_changed({"day": 5, "phase": "DAWN", "total_seconds": 1200.0})
	var mature_snapshot := manager.persistence_snapshot()["farming_state"] as Dictionary
	_assert_true(bool(((mature_snapshot["plots"] as Array)[0] as Dictionary)["mature"]), "runtime rain and elapsed day events advance crop stages to maturity")
	var owning_renderer: ChunkRenderer
	for child in manager.get_children():
		if not child is ChunkRenderer:
			continue
		var renderer := child as ChunkRenderer
		if WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(renderer.global_position)) == start_chunk:
			owning_renderer = renderer
			break
	_assert_true(owning_renderer != null and owning_renderer.visible_farming_plot_count() == 1 and owning_renderer.mature_farming_crop_count() == 1, "runtime stage changes refresh the owning chunk farming renderer")
	var harvest_result := manager.perform_farming_action(&"wheat", farm_tile)
	_assert_true(bool(harvest_result["ok"]) and String(harvest_result["quality"]) in ["normal", "silver", "gold"] and inventory.quantity(StringName(harvest_result["item_id"])) == int(harvest_result["quantity"]), "runtime harvest transfers one deterministic quality stack without duplication")
	var runtime_farming := manager.persistence_snapshot()["farming_state"] as Dictionary
	_assert_true((runtime_farming["plots"] as Array).size() == 1 and owning_renderer.visible_farming_plot_count() == 1 and int(manager.metrics_snapshot()["farming_plots"]) == 1, "runtime farming state, renderer and streaming metrics share one exact plot count")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_husbandry_runtime() -> void:
	var seed := WorldSeed.from_text("V3.4-husbandry-runtime")
	var terrain := TerrainGenerator.new(seed)
	var catalog := HusbandryCatalog.new()
	var planner := HusbandryPlanner.new(seed, catalog)
	var start_chunk := Vector2i.ZERO
	var initial_chunk: ChunkData
	var wild_candidate: Dictionary = {}
	for chunk_y in range(-4, 5):
		for chunk_x in range(-4, 5):
			var candidate_chunk := terrain.generate_chunk(Vector2i(chunk_x, chunk_y))
			var candidates := planner.candidates_for_chunk(candidate_chunk)
			if not candidates.is_empty():
				start_chunk = candidate_chunk.chunk_position
				initial_chunk = candidate_chunk
				wild_candidate = (candidates[0] as Dictionary).duplicate(true)
				break
		if not wild_candidate.is_empty():
			break
	_assert_true(initial_chunk != null and not wild_candidate.is_empty(), "runtime husbandry fixture finds a deterministic wild animal")
	if initial_chunk == null or wild_candidate.is_empty():
		return
	var animal_tile_value := wild_candidate["world_tile"] as Array
	var animal_tile := Vector2i(int(animal_tile_value[0]), int(animal_tile_value[1]))
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	var player_tile := animal_tile + Vector2i.LEFT
	player.position = WorldCoordinates.tile_to_world_pixel(player_tile, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, initial_chunk, &"surface")
	add_child(manager)
	await get_tree().process_frame
	var inventory := manager.harvest_state().inventory_model()
	var animal_type := StringName(wild_candidate["animal_type"])
	var definition := catalog.animal(animal_type)
	var feed_id := StringName(definition["feed_item_id"])
	var product_id := StringName(definition["product_item_id"])
	inventory.add_item(feed_id, 20)
	_assert_true(bool(manager.husbandry_target_status(animal_type, animal_tile)["valid"]), "runtime target status discovers the selected wild species and available feed")
	var breed_friendship := int(definition["breed_friendship"])
	var collected_during_taming := 0
	for day in range(1, breed_friendship + 1):
		if day > 1:
			manager._on_time_state_changed({"day": day, "phase": "DAY", "total_seconds": float(day * 300)})
		var action := manager.perform_husbandry_action(animal_type, animal_tile)
		if action.has("item_id"):
			collected_during_taming += int(action["quantity"])
			action = manager.perform_husbandry_action(animal_type, animal_tile)
		_assert_true(bool(action.get("ok", false)), "runtime feeding commits care day %d without losing a ready product" % day)
	var husbandry_snapshot := manager.persistence_snapshot()["husbandry_state"] as Dictionary
	var first_record := ((husbandry_snapshot["animals"] as Array)[0] as Dictionary).duplicate(true)
	_assert_true(bool(first_record["tamed"]) and int(first_record["friendship"]) == breed_friendship and inventory.quantity(feed_id) == 20 - breed_friendship, "runtime daily care reaches taming and breeding friendship with exact feed consumption")
	_assert_true(not bool(manager.building_preview(&"animal_fence", animal_tile, 0)["valid"]) and not bool(manager.farming_target_status(&"wheat", animal_tile)["valid"]), "runtime building and farming validation cannot overlap the interacted animal")
	var partner_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-3, 4):
		for offset_x in range(-3, 4):
			var candidate_tile := animal_tile + Vector2i(offset_x, offset_y)
			if candidate_tile == animal_tile or candidate_tile == player_tile:
				continue
			var candidate_chunk := manager._cache.get(WorldCoordinates.tile_to_chunk(candidate_tile)) as ChunkData
			if candidate_chunk == null:
				continue
			var local := WorldCoordinates.tile_to_local(candidate_tile)
			if HydrologyGenerator.is_water(candidate_chunk.water_feature_at(local)) or candidate_chunk.has_built_overlay_at(local) \
					or manager._resource_occupied_at(candidate_chunk, local) or not manager._wild_candidate_at(candidate_tile).is_empty():
				continue
			partner_tile = candidate_tile
			break
		if partner_tile.x != 2147483647:
			break
	_assert_true(partner_tile.x != 2147483647, "runtime fixture finds a dry nearby partner tile")
	if partner_tile.x == 2247483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	var partner := first_record.duplicate(true)
	partner["animal_id"] = "wild:runtime:partner"
	partner["world_tile"] = [partner_tile.x, partner_tile.y]
	partner["sex"] = "male" if String(first_record["sex"]) == "female" else "female"
	partner["product_ready"] = 0
	partner["sleeping"] = false
	(husbandry_snapshot["animals"] as Array).append(partner)
	_assert_true(manager._husbandry_state.restore_snapshot(husbandry_snapshot), "runtime fixture restores a compatible same-species partner through the production persistence validator")
	for coordinate in [WorldCoordinates.tile_to_chunk(animal_tile), WorldCoordinates.tile_to_chunk(partner_tile)]:
		manager._refresh_husbandry_animals(coordinate)
	inventory.add_item(&"wood", 4)
	inventory.add_item(&"fiber", 2)
	var fence_tile := Vector2i(2147483647, 2147483647)
	for offset_y in range(-3, 4):
		for offset_x in range(-3, 4):
			var candidate_tile := animal_tile + Vector2i(offset_x, offset_y)
			if ChunkStreamPlanner.chebyshev_distance(candidate_tile, partner_tile) > catalog.fence_radius_tiles():
				continue
			if bool(manager.building_preview(&"animal_fence", candidate_tile, 0).get("valid", false)):
				fence_tile = candidate_tile
				break
		if fence_tile.x != 2147483647:
			break
	_assert_true(fence_tile.x != 2147483647 and bool(manager.place_building(&"animal_fence", fence_tile, 0)["ok"]), "runtime fixture places a persistent fence within range of both parents")
	if fence_tile.x == 2247483647:
		manager.queue_free()
		player.queue_free()
		await get_tree().process_frame
		return
	var breed_result := manager.breed_husbandry_animal(animal_tile)
	var after_breed := manager.persistence_snapshot()["husbandry_state"] as Dictionary
	_assert_true(bool(breed_result["ok"]) and (after_breed["animals"] as Array).size() == 3 and String((breed_result["animal"] as Dictionary)["animal_id"]).begins_with("bred:"), "runtime right-click breeding creates one stable juvenile after fence and partner validation")
	var future_day := breed_friendship + 2
	manager._on_time_state_changed({"day": future_day, "phase": "NIGHT", "total_seconds": float(future_day * 300)})
	var night_status := manager.husbandry_state_snapshot()
	var sleeping_rendered := 0
	for child in manager.get_children():
		if child is ChunkRenderer:
			sleeping_rendered += (child as ChunkRenderer).sleeping_husbandry_animal_count()
	_assert_true(int(night_status["sleeping_count"]) == 3 and sleeping_rendered == 3 and int(night_status["ready_products"]) > 0, "runtime night and elapsed-day events refresh sleeping animals and offline products in owning renderers")
	manager._on_time_state_changed({"day": future_day, "phase": "DAY", "total_seconds": float(future_day * 300 + 1)})
	var product_before := inventory.quantity(product_id)
	var collect_result := manager.perform_husbandry_action(animal_type, animal_tile)
	var metrics := manager.metrics_snapshot()
	_assert_true(bool(collect_result["ok"]) and String(collect_result["item_id"]) == String(product_id) and inventory.quantity(product_id) > product_before, "runtime product collection wakes the animal and transfers its configured product")
	_assert_true(int(metrics["husbandry_animals"]) == 3 and int(metrics["tamed_animals"]) == 3 and int(manager.husbandry_state_snapshot()["sleeping_count"]) == 0, "runtime state, renderer events and streaming metrics share one exact animal population")
	_assert_true(collected_during_taming > 0, "runtime care loop preserves products collected before breeding friendship is reached")
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_cave_runtime() -> void:
	var seed := WorldSeed.from_text("洞穴运行时测试")
	var terrain := TerrainGenerator.new(seed)
	var entrance := CaveEntrancePlanner.new(seed).entrance_for_region(Vector2i.ZERO, terrain)
	var entrance_tile := entrance["world_tile"] as Vector2i
	var entrance_chunk := entrance["chunk_position"] as Vector2i
	var player := load("res://scenes/player/player.tscn").instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(entrance_tile, true)
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, terrain.generate_chunk(entrance_chunk), &"surface")
	add_child(manager)
	await get_tree().process_frame
	_assert_true(manager.world_layer() == &"surface" and manager.try_use_cave_transition(), "surface entrance switches the active stream to underground")
	_assert_true(manager.is_underground() and manager.enemy_director().world_layer() == &"underground", "world-layer switch retargets underground chunks and cave enemies")
	_assert_true(not manager.ruin_encounter().visible and not manager.ruin_encounter().is_processing(), "surface ruin and Boss simulation pause while underground")
	_assert_true(String(manager.persistence_snapshot()["world_layer"]) == "underground", "active underground layer is present in the persistence snapshot")
	_assert_true(manager.try_use_cave_transition() and manager.world_layer() == &"surface", "aligned underground exit returns the stream to the surface")
	_assert_true(manager.ruin_encounter().visible and manager.ruin_encounter().is_processing(), "surface ruin simulation resumes after returning above ground")
	var cave_generator := CaveGenerator.new(seed)
	var chest_chunk: ChunkData
	var chest_local := Vector2i(-1, -1)
	for chunk_y in range(-4, 5):
		for chunk_x in range(-4, 5):
			var candidate_chunk := cave_generator.generate_chunk(Vector2i(chunk_x, chunk_y))
			for y in WorldCoordinates.CHUNK_SIZE:
				for x in WorldCoordinates.CHUNK_SIZE:
					if candidate_chunk.cave_feature_at(Vector2i(x, y)) == CaveGenerator.Feature.CHEST:
						chest_chunk = candidate_chunk
						chest_local = Vector2i(x, y)
						break
				if chest_local.x >= 0:
					break
			if chest_local.x >= 0:
				break
		if chest_local.x >= 0:
			break
	_assert_true(chest_chunk != null, "runtime cave fixture finds a deterministic underground chest")
	if chest_chunk != null:
		var chest_tile := WorldCoordinates.chunk_local_to_tile(chest_chunk.chunk_position, chest_local)
		manager.switch_world_layer(&"underground", WorldCoordinates.tile_to_world_pixel(chest_tile, true))
		var before_items := manager.harvest_state().inventory_model().count_snapshot()
		_assert_true(manager.try_open_nearest_cave_chest() and manager.opened_cave_chest_count() == 1, "underground chest opens once through normal interaction")
		_assert_true(manager.harvest_state().inventory_model().count_snapshot() != before_items, "opening an underground chest transfers deterministic loot")
		_assert_true((manager.persistence_snapshot()["opened_cave_chests"] as Array).size() == 1, "opened chest state enters the underground save snapshot")
		var torch_local := Vector2i(-1, -1)
		for y in WorldCoordinates.CHUNK_SIZE:
			for x in WorldCoordinates.CHUNK_SIZE:
				if chest_chunk.cave_feature_at(Vector2i(x, y)) == CaveGenerator.Feature.TORCH:
					torch_local = Vector2i(x, y)
					break
			if torch_local.x >= 0:
				break
		if torch_local.x >= 0:
			player.global_position = WorldCoordinates.tile_to_world_pixel(WorldCoordinates.chunk_local_to_tile(chest_chunk.chunk_position, torch_local), true)
			_assert_true(manager.is_near_cave_torch(), "static cave torch activates local underground lighting range")
	var overlay := DayNightOverlay.new()
	add_child(overlay)
	await get_tree().process_frame
	overlay.set_world_layer(&"underground")
	overlay.set_torch_enabled(true)
	overlay.apply_time({"overlay": Color.TRANSPARENT})
	_assert_true(overlay.color.a > 0.8 and overlay.torch_enabled(), "underground presentation stays dark while torch lighting remains active")
	overlay.queue_free()
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_dungeon_runtime() -> void:
	var seed := WorldSeed.from_text("地牢运行时测试")
	var entrance_tile := Vector2i(-17, 29)
	var anchor_chunk := WorldCoordinates.tile_to_chunk(entrance_tile)
	var dungeon_id := DungeonGenerator.dungeon_id_for_entrance(entrance_tile)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(entrance_tile, true)
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, TerrainGenerator.new(seed).generate_chunk(anchor_chunk), &"surface")
	add_child(manager)
	await get_tree().process_frame
	_assert_true(manager._enter_dungeon(entrance_tile), "surface dungeon entrance starts a procedural dungeon run")
	_assert_true(manager.is_dungeon() and manager.enemy_director().world_layer() == &"dungeon", "dungeon transition retargets chunks and enemy population to the third world layer")
	_assert_true(not manager.ruin_encounter().visible and not manager.ruin_encounter().is_processing(), "surface ruin simulation fully pauses inside a dungeon")
	var run := manager.dungeon_state().current_run()
	_assert_true(manager.dungeon_state().current_dungeon_id() == dungeon_id and int(run["attempt_count"]) == 1, "runtime dungeon binds a stable entrance-derived ID and attempt count")
	_assert_true(String(manager.persistence_snapshot()["world_layer"]) == "dungeon" and String((manager.persistence_snapshot()["dungeon_state"] as Dictionary)["current_dungeon_id"]) == dungeon_id, "active dungeon and run state enter the persistence snapshot")
	var generator := DungeonGenerator.new(seed, dungeon_id, anchor_chunk)
	var dungeon_chunk := generator.generate_chunk(anchor_chunk)
	var key_local := _first_dungeon_feature_local(dungeon_chunk, DungeonGenerator.Feature.KEY)
	var door_local := _first_dungeon_feature_local(dungeon_chunk, DungeonGenerator.Feature.LOCKED_DOOR)
	var chest_local := _first_dungeon_feature_local(dungeon_chunk, DungeonGenerator.Feature.CHEST)
	var trap_local := _first_dungeon_feature_local(dungeon_chunk, DungeonGenerator.Feature.TRAP)
	player.global_position = WorldCoordinates.tile_to_world_pixel(WorldCoordinates.chunk_local_to_tile(anchor_chunk, key_local), true)
	_assert_true(manager.try_collect_nearest_dungeon_key() and int(manager.dungeon_state().current_run()["key_count"]) == 1, "runtime interaction collects a generated dungeon key")
	player.global_position = WorldCoordinates.tile_to_world_pixel(WorldCoordinates.chunk_local_to_tile(anchor_chunk, door_local), true)
	_assert_true(manager.try_unlock_nearest_dungeon_door() and int(manager.dungeon_state().current_run()["key_count"]) == 0, "runtime interaction consumes one key and removes one locked-door collision")
	var inventory_before := manager.harvest_state().inventory_model().count_snapshot()
	player.global_position = WorldCoordinates.tile_to_world_pixel(WorldCoordinates.chunk_local_to_tile(anchor_chunk, chest_local), true)
	_assert_true(manager.try_open_nearest_dungeon_chest(), "runtime interaction opens a generated dungeon chest")
	_assert_true(manager.harvest_state().inventory_model().count_snapshot() != inventory_before and (manager.dungeon_state().current_run()["opened_chests"] as Array).size() == 1, "dungeon chest transfers deterministic loot and persists its opened state")
	var health_before := player.health
	player.combat_state().tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	player.global_position = WorldCoordinates.tile_to_world_pixel(WorldCoordinates.chunk_local_to_tile(anchor_chunk, trap_local), true)
	manager._process_dungeon_trap()
	_assert_true(player.health < health_before and (manager.dungeon_state().current_run()["triggered_traps"] as Array).size() == 1, "stepping on a dungeon trap applies configured damage exactly once")
	var health_after_trap := player.health
	manager._process_dungeon_trap()
	_assert_equal(player.health, health_after_trap, "resolved dungeon trap cannot damage the player twice in one attempt")
	var enemy_candidates := EnemySpawnPlanner.new(seed).candidates_for_dungeon(dungeon_chunk, dungeon_id, manager.dungeon_state().current_run())
	var boss_spawn_id := ""
	var elite_spawn_id := ""
	for candidate_value in enemy_candidates:
		var candidate := candidate_value as Dictionary
		if candidate["enemy_id"] == &"dungeon_warden":
			boss_spawn_id = String(candidate["spawn_id"])
		elif elite_spawn_id.is_empty():
			elite_spawn_id = String(candidate["spawn_id"])
	manager._on_dungeon_enemy_defeated(elite_spawn_id, &"elite")
	_assert_true((manager.dungeon_state().current_run()["defeated_elites"] as Array).has(elite_spawn_id), "runtime elite defeat is recorded by stable spawn ID")
	manager._on_dungeon_enemy_defeated(boss_spawn_id, &"boss")
	_assert_true(bool(manager.dungeon_state().current_run()["completed"]) and bool(manager.dungeon_state().current_run()["boss_defeated"]), "runtime Boss defeat permanently completes the dungeon")
	var completed_attempts := int(manager.dungeon_state().current_run()["attempt_count"])
	player.global_position = WorldCoordinates.tile_to_world_pixel(generator.entry_world_tile(), true)
	_assert_true(manager.try_use_dungeon_transition() and manager.world_layer() == &"surface", "generated dungeon exit returns to the exact surface entrance")
	_assert_true(manager.ruin_encounter().visible and manager.ruin_encounter().is_processing(), "surface ruin simulation resumes after leaving a dungeon")
	_assert_true(bool(manager.dungeon_state().run_snapshot(dungeon_id)["completed"]), "completed dungeon remains persisted while inactive on the surface")
	_assert_true(manager._enter_dungeon(entrance_tile), "completed dungeon can be revisited from its entrance")
	_assert_true(int(manager.dungeon_state().current_run()["attempt_count"]) == completed_attempts and (manager.dungeon_state().current_run()["opened_chests"] as Array).size() == 1, "completed dungeon revisit preserves attempt and resolved feature state")
	var hud := DungeonHud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.update_state(manager.dungeon_state().status_snapshot())
	var panel := hud.find_child("DungeonPanel", true, false) as Control
	var status_label := hud.find_child("DungeonStatusLabel", true, false) as Label
	var objective_label := hud.find_child("DungeonObjectiveLabel", true, false) as Label
	_assert_true(panel != null and panel.visible and status_label != null and objective_label != null, "dungeon HUD exposes visible status and objective nodes during a run")
	_assert_true("第 1 次" in status_label.text and "地牢已完成" in objective_label.text, "dungeon HUD reflects persisted completion and attempt state")
	_assert_true(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "dungeon HUD remains inside the 1280×720 viewport")
	var overlay := DayNightOverlay.new()
	add_child(overlay)
	await get_tree().process_frame
	overlay.set_world_layer(&"dungeon")
	overlay.apply_time({"overlay": Color.TRANSPARENT})
	_assert_true(overlay.color.a > 0.8, "dungeon presentation keeps a persistent underground darkness overlay")
	manager._leave_dungeon()
	hud.update_state(manager.dungeon_state().status_snapshot())
	_assert_true(not panel.visible, "dungeon HUD hides immediately after returning to the surface")
	overlay.queue_free()
	hud.queue_free()
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_exploration_runtime_and_hud() -> void:
	var seed := WorldSeed.from_text("V2.0-map-runtime")
	var start_chunk := Vector2i(-1, -4)
	var terrain := TerrainGenerator.new(seed)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(terrain.find_land_near(terrain.generate_chunk(start_chunk)), true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, terrain.generate_chunk(start_chunk), &"surface")
	add_child(manager)
	await get_tree().process_frame
	var first_snapshot := manager.exploration_snapshot()
	_assert_true(int(first_snapshot["discovered_chunks"]) == 9 and int(first_snapshot["travel_point_count"]) >= 1, "runtime stream reveals local fog and registers the safe-camp travel point")
	var custom_id := manager.add_custom_map_marker("运行时标记")
	_assert_true(not custom_id.is_empty() and manager.exploration_state().custom_marker_count() == 1, "runtime map manager adds a custom marker at the player")
	var before_position := player.global_position
	player.global_position += Vector2(96, 64)
	_assert_true(manager.try_fast_travel("home:respawn") and player.global_position == before_position, "fast travel returns the player to an unlocked stable world position")
	var first_boss := RegionalBossPlanner.new(seed).plans()[0] as Dictionary
	manager.exploration_state().reveal_chunk(first_boss["chunk_position"] as Vector2i, 0)
	for marker_value in WorldDiscoveryScanner.new(seed).markers_for_chunk(first_boss["chunk_position"] as Vector2i):
		var marker := marker_value as Dictionary
		manager.exploration_state().register_marker(String(marker["id"]), StringName(marker["type"]), String(marker["display_name"]), marker["world_tile"] as Vector2i, String(marker["color"]), bool(marker["travel_enabled"]))
	manager._on_regional_boss_defeated(StringName(first_boss["id"]))
	_assert_true(manager.regional_boss_state().defeated_count() == 1 and bool(manager.exploration_state().marker("boss:%s" % first_boss["id"])["completed"]), "runtime regional Boss defeat completes its map marker and persistent world state")
	var panel := ExplorationMapPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel.configure(manager)
	panel.set_map_open(true)
	await get_tree().process_frame
	var window := panel.find_child("MapWindow", true, false) as Control
	var map_canvas := panel.find_child("ExplorationMapCanvas", true, false) as ExplorationMapCanvas
	var travel_list := panel.find_child("TravelPointList", true, false) as VBoxContainer
	_assert_true(panel.is_map_open() and window != null and map_canvas != null and travel_list != null, "exploration map exposes fog canvas, travel list and modal state")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()), "exploration map stays inside the 1280×720 viewport")
	_assert_true((manager.persistence_snapshot()["exploration_state"] as Dictionary) == manager.exploration_state().persistence_snapshot() and (manager.persistence_snapshot()["regional_boss_state"] as Dictionary) == manager.regional_boss_state().persistence_snapshot(), "runtime exploration and regional Boss states enter the world save snapshot")
	panel.set_map_open(false)
	_assert_true(not panel.is_map_open(), "exploration map closes without mutating world state")
	panel.queue_free()
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_npc_runtime_and_hud() -> void:
	var seed := WorldSeed.from_text("V2.2-NPC-runtime")
	var terrain := TerrainGenerator.new(seed)
	var planner := NpcPlanner.new(seed)
	var village_plan := {}
	for region_y in range(-12, 13):
		for region_x in range(-12, 13):
			village_plan = planner.plan_for_region(Vector2i(region_x, region_y), terrain)
			if not village_plan.is_empty(): break
		if not village_plan.is_empty(): break
	_assert_true(not village_plan.is_empty(), "runtime NPC fixture resolves a deterministic village")
	if village_plan.is_empty():
		return
	var merchant_plan := {}
	var innkeeper_plan := {}
	for value in village_plan["npcs"] as Array:
		var plan := value as Dictionary
		if String(plan["role_id"]) == "merchant": merchant_plan = plan
		if String(plan["role_id"]) == "innkeeper": innkeeper_plan = plan
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(merchant_plan["home_tile"] as Vector2i, true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var start_chunk := WorldCoordinates.tile_to_chunk(merchant_plan["home_tile"] as Vector2i)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, terrain.generate_chunk(start_chunk), &"surface")
	add_child(manager)
	await get_tree().process_frame
	manager._on_time_state_changed({"phase": &"DAY", "progress": 0.30, "day": 1})
	manager.npc_director().refresh_now()
	var merchant := manager.npc_director().actor(String(merchant_plan["id"]))
	var innkeeper := manager.npc_director().actor(String(innkeeper_plan["id"]))
	_assert_true(merchant != null and innkeeper != null and manager.npc_director().active_count() >= 3, "runtime director activates deterministic villagers near the player")
	_assert_true(merchant.activity() == &"trade" and not merchant.is_sleeping(), "day schedule moves merchant into active trade state")
	var panel := NpcInteractionPanel.new()
	add_child(panel)
	var quest_panel := QuestJournalPanel.new()
	add_child(quest_panel)
	var faction_panel := FactionPanel.new()
	add_child(faction_panel)
	await get_tree().process_frame
	panel.configure(manager)
	quest_panel.configure(manager)
	faction_panel.configure(manager)
	_assert_true(manager.accept_quest(&"side_trade_route"), "runtime quest API accepts an available escort objective")
	manager.harvest_state().inventory_model().add_item(&"wood", 10)
	manager.harvest_state().inventory_model().add_item(&"copper_ore", 1)
	player.global_position = merchant.global_position
	_assert_true(manager.npc_director().try_interact(), "nearby awake NPC opens a normal interaction")
	await get_tree().process_frame
	_assert_true(manager.quest_state().status(&"side_trade_route", manager.quest_catalog()) == &"completed", "talking to the target NPC completes the active escort objective")
	var window := panel.find_child("NpcWindow", true, false) as Control
	_assert_true(panel.is_npc_open() and window != null and panel.find_child("NpcDialogueLabel", true, false) != null and panel.find_child("NpcRelationshipLabel", true, false) != null and panel.find_child("GiftList", true, false) != null, "NPC panel exposes identity, dialogue, relationship, gifts and modal state")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()), "NPC dialogue and shop stay inside the 1280×720 viewport")
	var first_sale := manager.sell_to_current_npc(&"wood")
	var second_sale := manager.sell_to_current_npc(&"wood")
	var purchase := manager.buy_from_current_npc(&"cooked_berries")
	var inventory := manager.harvest_state().inventory_model()
	_assert_true(bool(first_sale["ok"]) and bool(second_sale["ok"]) and bool(purchase["ok"]), "merchant completes validated sell and buy transactions")
	_assert_true(inventory.quantity(&"wood") == 0 and inventory.quantity(&"coin") == 1 and inventory.quantity(&"cooked_berries") == 1, "shop transactions transfer exact items and currency without duplication")
	var gift := manager.gift_to_current_npc(&"copper_ore")
	var repeated_gift := manager.gift_to_current_npc(&"cooked_berries")
	_assert_true(bool(gift["ok"]) and not bool(repeated_gift["ok"]) and inventory.quantity(&"copper_ore") == 0, "runtime preferred gift transfers once and enforces the daily NPC limit")
	var relationship := manager.relationship_state().status_snapshot(String(merchant_plan["id"]), String(merchant_plan["village_id"]), RelationshipCatalog.new(), 1)
	_assert_true(int(relationship["affection"]) == 11 and int(relationship["village_reputation"]) == 7 and not bool(relationship["can_gift_today"]), "three trades and one preferred gift update affection and village reputation")
	var merchant_record := manager.npc_state().record_for(String(merchant_plan["id"]))
	_assert_true(int(merchant_record["talk_count"]) == 1 and int(merchant_record["trade_count"]) == 3, "runtime dialogue and three trades enter persistent NPC state")
	_assert_true(manager.faction_state().standing(&"merchant_guild", manager.faction_catalog()) == 3, "three completed NPC trades grant exact merchant-guild standing")
	_assert_equal(manager.persistence_snapshot()["npc_state"], manager.npc_state().persistence_snapshot(), "runtime NPC state enters the world save snapshot")
	_assert_equal(manager.persistence_snapshot()["relationship_state"], manager.relationship_state().persistence_snapshot(), "runtime relationship state enters the world save snapshot")
	quest_panel.set_quest_open(true)
	await get_tree().process_frame
	var quest_window := quest_panel.find_child("QuestJournalWindow", true, false) as Control
	var runtime_quest_snapshot := manager.quest_snapshot()
	_assert_true(quest_panel.is_quest_open() and quest_window != null and quest_panel.find_child("QuestJournalList", true, false) != null and quest_panel.find_child("QuestTrackerLabel", true, false) != null, "quest journal exposes available entries, details and an always-on tracker")
	_assert_true(int(runtime_quest_snapshot["fixed_template_count"]) == 24 and int(runtime_quest_snapshot["random_offer_count"]) == 3 and quest_panel.find_child("WorldChoicePanel", true, false) != null and quest_panel.find_child("WorldChoiceOptionList", true, false) != null, "runtime journal combines 24 fixed templates, three deterministic offers and key choices")
	_assert_true(get_viewport().get_visible_rect().encloses(quest_window.get_global_rect()), "quest journal stays inside the 1280×720 viewport")
	var quest_claim := manager.claim_quest_reward(&"side_trade_route")
	_assert_true(bool(quest_claim["ok"]) and inventory.quantity(&"coin") == 5 and manager.quest_state().status(&"side_trade_route", manager.quest_catalog()) == &"claimed", "runtime quest reward is delivered exactly once")
	_assert_true(manager.faction_state().standing(&"merchant_guild", manager.faction_catalog()) == 8, "claiming a merchant quest grants its exact faction standing once")
	_assert_equal(manager.persistence_snapshot()["quest_state"], manager.quest_state().persistence_snapshot(), "runtime quest state enters the world save snapshot")
	_assert_equal(manager.persistence_snapshot()["world_choice_state"], manager.world_choice_state().persistence_snapshot(), "runtime world-choice results enter the world save snapshot")
	quest_panel.set_quest_open(false)
	faction_panel.set_faction_open(true)
	faction_panel._select_faction("merchant_guild")
	await get_tree().process_frame
	var faction_window := faction_panel.find_child("FactionWindow", true, false) as Control
	var faction_buy := faction_panel.find_child("FactionShopBuy_torch", true, false) as Button
	_assert_true(faction_panel.is_faction_open() and faction_window != null and faction_panel.find_child("FactionList", true, false) != null and faction_buy != null and not faction_buy.disabled, "faction panel exposes standings, relations and tier-gated shop stock")
	_assert_true(get_viewport().get_visible_rect().encloses(faction_window.get_global_rect()), "faction panel stays inside the 1280×720 viewport")
	faction_buy.pressed.emit()
	await get_tree().process_frame
	_assert_true(inventory.quantity(&"coin") == 0 and inventory.quantity(&"torch") == 2 and manager.faction_state().standing(&"merchant_guild", manager.faction_catalog()) == 9, "faction shop transfers exact stock, currency and one trade-standing event")
	_assert_equal(manager.persistence_snapshot()["faction_state"], manager.faction_state().persistence_snapshot(), "runtime faction standings, discoveries and control points enter the world save snapshot")
	faction_panel.set_faction_open(false)
	panel.set_npc_open(false)
	player.global_position = innkeeper.global_position
	_assert_true(manager.npc_director().try_interact(), "innkeeper exposes a separate interaction service")
	var sleep_events: Array[Dictionary] = []
	var sleep_listener := func(npc_id: String, display_name: String) -> void:
		sleep_events.append({"npc_id": npc_id, "display_name": display_name})
	EventBus.sleep_requested.connect(sleep_listener)
	var sleep_requested := manager.request_sleep_at_current_npc()
	EventBus.sleep_requested.disconnect(sleep_listener)
	_assert_true(sleep_requested and sleep_events.size() == 1 and String(sleep_events[0]["npc_id"]) == String(innkeeper_plan["id"]), "innkeeper emits one validated sleep request")
	manager.npc_director().set_world_layer(&"underground")
	_assert_true(manager.npc_director().active_count() == 0, "NPC simulation sleeps completely outside the surface layer")
	panel.queue_free()
	quest_panel.queue_free()
	faction_panel.queue_free()
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_world_event_runtime_and_hud() -> void:
	var seed := WorldSeed.from_text("V2.5-world-event-runtime")
	var terrain := TerrainGenerator.new(seed)
	var start_chunk := Vector2i(-1, -4)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(terrain.find_land_near(terrain.generate_chunk(start_chunk)), true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, terrain.generate_chunk(start_chunk), &"surface")
	add_child(manager)
	await get_tree().process_frame
	var catalog := manager.world_event_catalog()
	var planner := WorldEventPlanner.new(seed, catalog)
	var resource_slot := -1
	for slot_index in 16:
		if String(planner.plan_for_slot(slot_index)["event_id"]) == "resource_surge":
			resource_slot = slot_index
			break
	var resource_plan := planner.plan_for_slot(resource_slot)
	manager._on_time_state_changed({"total_seconds": float(resource_plan["start_seconds"]) + 1.0, "phase": &"DAY", "progress": 0.5, "day": 1})
	_assert_true(manager.world_event_state().active_count() == 1 and String(manager.world_event_state().active_records()[0]["event_id"]) == "resource_surge", "runtime manager activates the scheduled event at the current region")
	_assert_equal(manager.adjusted_resource_quantity(4), 7, "runtime resource collection combines the active event yield deterministically")
	manager._record_world_event(&"harvest", &"tree", 3)
	_assert_true(manager.world_event_state().active_count() == 0 and String(manager.world_event_state().history_records().back()["status"]) == "completed", "runtime harvest progress completes and records the resource event")
	var raid_slot := -1
	for slot_index in range(resource_slot + 1, resource_slot + 17):
		if String(planner.plan_for_slot(slot_index)["event_id"]) == "village_raid":
			raid_slot = slot_index
			break
	var raid_plan := planner.plan_for_slot(raid_slot)
	manager._on_time_state_changed({"total_seconds": float(raid_plan["start_seconds"]) + 1.0, "phase": &"DAY", "progress": 0.5, "day": 2})
	var raid_enemy_count := 0
	for enemy_snapshot in manager.enemy_director().active_snapshots():
		var enemy_view := enemy_snapshot as Dictionary
		if String(enemy_view["spawn_id"]).begins_with("event-enemy:") and enemy_view["enemy_id"] == &"bandit_scout":
			raid_enemy_count += 1
	_assert_equal(raid_enemy_count, 3, "village-raid event materializes three stable ash-raider encounters around the current region")
	var blizzard_slot := -1
	for slot_index in range(raid_slot + 1, raid_slot + 17):
		if String(planner.plan_for_slot(slot_index)["event_id"]) == "blizzard":
			blizzard_slot = slot_index
			break
	var blizzard_plan := planner.plan_for_slot(blizzard_slot)
	manager._on_time_state_changed({"total_seconds": float(blizzard_plan["start_seconds"]) + 1.0, "phase": &"DAY", "progress": 0.5, "day": 2})
	_assert_true(manager.world_event_weather_override() == &"SNOW", "runtime blizzard overrides surface weather while active")
	var panel := WorldEventPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel.configure(manager)
	panel.set_event_open(true)
	await get_tree().process_frame
	var window := panel.find_child("WorldEventWindow", true, false) as Control
	var tracker := panel.find_child("WorldEventTracker", true, false) as Control
	_assert_true(panel.is_event_open() and window != null and tracker != null and panel.find_child("ActiveWorldEventList", true, false) != null and panel.find_child("UpcomingWorldEventList", true, false) != null, "world-event UI exposes active status, bounded timetable, history and tracker")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()) and get_viewport().get_visible_rect().encloses(tracker.get_global_rect()), "world-event window and tracker stay inside the 1280×720 viewport")
	var boss_slot := -1
	for slot_index in range(blizzard_slot + 1, blizzard_slot + 17):
		if String(planner.plan_for_slot(slot_index)["event_id"]) == "temporary_boss":
			boss_slot = slot_index
			break
	var boss_plan := planner.plan_for_slot(boss_slot)
	manager._on_time_state_changed({"total_seconds": float(boss_plan["start_seconds"]) + 1.0, "phase": &"DAY", "progress": 0.5, "day": 3})
	var event_boss_count := 0
	for enemy_snapshot in manager.enemy_director().active_snapshots():
		var enemy_view := enemy_snapshot as Dictionary
		if String(enemy_view["spawn_id"]).begins_with("event-enemy:") and enemy_view["enemy_id"] == &"grove_titan":
			event_boss_count += 1
	_assert_equal(event_boss_count, 1, "temporary-Boss event materializes one stable defeatable regional Boss encounter")
	_assert_equal(manager.persistence_snapshot()["world_event_state"], manager.world_event_state().persistence_snapshot(), "runtime event cursor, progress and history enter the world save snapshot")
	panel.set_event_open(false)
	panel.queue_free()
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_region_progression_runtime_and_hud() -> void:
	var seed := WorldSeed.from_text("V2.6-region-progression-runtime")
	var terrain := TerrainGenerator.new(seed)
	var start_chunk := Vector2i(-1, -4)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = WorldCoordinates.tile_to_world_pixel(terrain.find_land_near(terrain.generate_chunk(start_chunk)), true)
	player.combat_state().respawn_position = player.position
	add_child(player)
	var manager := ChunkStreamManager.new()
	manager.configure(seed, player, terrain.generate_chunk(start_chunk), &"surface")
	add_child(manager)
	await get_tree().process_frame
	var initial := manager.region_progression_snapshot()
	var region := initial["current_region"] as Dictionary
	_assert_true(int(region["danger_level"]) == 1 and int(initial["world_progress_points"]) == 2 and int(initial["discovered_regions"]) == 1, "runtime manager discovers the current stable region and grants one progress source")
	_assert_true((initial["unlocked_boss_ids"] as Array) == ["grove_titan"], "fresh runtime unlocks only the first regional Boss")
	for item_id in [&"wood_sword", &"wood_axe", &"wood_pickaxe"]:
		manager.harvest_state().inventory_model().add_item(item_id, 1)
	manager._emit_tool_and_inventory()
	_assert_equal(int(manager.region_progression_snapshot()["gear_score"]), 16, "runtime inventory mutations refresh the composed equipment score")
	var spawned := manager.enemy_director().ensure_world_event_enemy(
		"progression-fixture",
		"event-enemy:progression:elite",
		&"dungeon_sentinel",
		player.global_position + Vector2(-128, 0)
	)
	var elite_enemy: EnemyBase
	for child in manager.enemy_director().get_children():
		if child is EnemyBase and (child as EnemyBase).stable_spawn_id == "event-enemy:progression:elite":
			elite_enemy = child as EnemyBase
			break
	_assert_true(spawned and elite_enemy != null and elite_enemy.elite and elite_enemy.combat_level >= 1 and elite_enemy.combat_level <= 3 and elite_enemy.maximum_health > elite_enemy.definition.maximum_health, "runtime elite receives regional level, health scaling and explicit elite identity")
	if elite_enemy != null:
		elite_enemy.receive_attack({"damage": 9999.0, "direction": Vector2.RIGHT, "knockback": 0.0})
	var after_elite := manager.region_progression_snapshot()
	_assert_true(int(after_elite["region_elite_defeats"]) == 1 and int(after_elite["world_progress_points"]) == 4, "runtime elite defeat grants one deduplicated regional progress source")
	var panel := RegionProgressionPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel.configure(manager)
	panel.set_progression_open(true)
	await get_tree().process_frame
	var window := panel.find_child("RegionProgressionWindow", true, false) as Control
	var tracker := panel.find_child("RegionProgressionTracker", true, false) as Control
	var reward_button := panel.find_child("ClaimRegionRewardButton", true, false) as Button
	_assert_true(panel.is_progression_open() and window != null and tracker != null and reward_button != null and panel.find_child("BossUnlockListLabel", true, false) != null, "region-progression UI exposes danger, gear, rewards, Boss gates and tracker")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()) and get_viewport().get_visible_rect().encloses(tracker.get_global_rect()), "region-progression window and tracker stay inside the 1280×720 viewport")
	var coin_before := manager.harvest_state().inventory_model().quantity(&"coin")
	reward_button.pressed.emit()
	await get_tree().process_frame
	_assert_true(manager.harvest_state().inventory_model().quantity(&"coin") == coin_before + 6 and bool(manager.region_progression_snapshot()["reward_claimed"]), "runtime region reward button transfers its one-time items")
	_assert_equal(manager.persistence_snapshot()["region_progression_state"], manager.region_progression_state().persistence_snapshot(), "runtime world progress, discoveries, elite sources and reward claims enter the world save snapshot")
	panel.set_progression_open(false)
	panel.queue_free()
	manager.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_drop_pool() -> void:
	var pool := WorldDropPool.new()
	pool.configure(2)
	add_child(pool)
	await get_tree().process_frame
	_assert_true(pool.spawn_drop(&"wood", 2, Vector2(10, 10)), "drop pool activates a free object")
	_assert_true(pool.spawn_drop(&"stone", 1, Vector2(80, 10)), "drop pool activates a second free object")
	_assert_true(not pool.spawn_drop(&"berry", 1, Vector2(150, 10)), "drop pool refuses an unmergeable overflow")
	_assert_true(pool.spawn_drop(&"wood", 3, Vector2(12, 10)), "full pool merges a matching item stack")
	_assert_equal(pool.active_count(), 2, "drop object count remains capped at pool capacity")
	pool._process(0.25)
	var blocked := pool.transfer_near(Vector2(10, 10), 24.0, func(_item_id: StringName, _quantity: int, _metadata: Dictionary) -> int:
		return 0
	)
	_assert_true((blocked["transferred"] as Array).is_empty() and not (blocked["blocked"] as Array).is_empty(), "full inventory refuses pickup explicitly")
	_assert_equal(pool.active_quantity(&"wood"), 5, "refused pickup remains on the ground without loss or duplication")
	var pickup := pool.collect_near(Vector2(10, 10), 24.0)
	_assert_equal(pickup.size(), 1, "automatic pickup collects only nearby mature drops")
	_assert_equal(int((pickup[0] as Dictionary)["quantity"]), 5, "merged drop stack preserves total quantity")
	_assert_equal(pool.active_count(), 1, "picked-up object returns to the pool")
	_assert_true(pool.spawn_drop(&"wood_axe", 1, Vector2(12, 10), {"durability": 11}), "discarded damaged tool enters a free ground-drop slot")
	pool._process(0.25)
	var tool_pickup := pool.collect_near(Vector2(12, 10), 24.0)
	var found_tool_durability := false
	for stack in tool_pickup:
		if StringName((stack as Dictionary).get("item_id", "")) == &"wood_axe":
			found_tool_durability = int((stack as Dictionary).get("durability", 0)) == 11
	_assert_true(found_tool_durability, "discard and pickup preserve individual tool durability metadata")
	pool.queue_free()


func _test_player_scene_contract() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	add_child(player)
	await get_tree().physics_frame
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	_assert_true(collision != null and collision.shape != null, "player has physical collision")
	_assert_true(camera != null and camera.position_smoothing_enabled, "camera smoothing enabled")
	player.take_damage(25.0)
	_assert_equal(player.health, 75.0, "player damage updates health")
	player.heal(10.0)
	_assert_equal(player.health, 85.0, "player healing clamps correctly")
	player.restore_snapshot({"position": [-96.5, 160.25], "health": 64.0, "maximum_health": 120.0, "stamina": 33.0, "maximum_stamina": 80.0})
	_assert_equal(player.position, Vector2(-96.5, 160.25), "player restore applies signed position")
	_assert_true(player.health == 64.0 and player.maximum_health == 120.0 and player.stamina == 33.0 and player.maximum_stamina == 80.0, "player restore applies health and stamina attributes")
	player.combat_state().tick(2.0)
	player.combat_state().respawn_position = Vector2(-64.0, 96.0)
	var lethal := player.receive_hit(999.0, Vector2.LEFT, 100.0)
	_assert_true(bool(lethal["died"]) and player.health == 0.0 and player.combat_state().status == &"dead", "player enters a valid death state after lethal damage")
	player.respawn_at(player.combat_state().respawn_position)
	_assert_true(player.health == player.maximum_health and player.global_position == Vector2(-64.0, 96.0) and player.combat_state().status == &"alive", "player death can complete a normal safe-position respawn")
	_assert_true((player.persistence_snapshot()["combat_state"] as Dictionary).has("death_count"), "player persistence includes combat status")
	player.queue_free()


func _test_generation_hud_layout() -> void:
	var hud := GenerationHud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.configure("无尽边境", WorldSeed.from_text("无尽边境"), Vector2i(-1, -4), "47c1e52c4fe80f9c")
	hud.update_streaming({
		"current_chunk": Vector2i(-1, -4),
		"current_checksum": "47c1e52c4fe80f9c",
		"view_mode": "群系",
		"biome_name": "森林",
		"temperature": 0.48,
		"moisture": 0.73,
		"elevation": 0.57,
		"erosion": 0.41,
		"active": 25,
		"preload": 24,
		"cache": 49,
		"peak_cache": 49,
	})
	await get_tree().process_frame
	var panel := hud.find_child("GenerationPanel", true, false) as Control
	var world_label := hud.find_child("WorldLabel", true, false) as Label
	var stream_label := hud.find_child("StreamLabel", true, false) as Label
	_assert_true(panel != null and world_label != null and stream_label != null, "generation HUD diagnostic nodes exist")
	if panel != null and world_label != null and stream_label != null:
		_assert_true(panel.get_global_rect().encloses(world_label.get_global_rect()), "biome and climate diagnostics stay inside generation panel")
		_assert_true(panel.get_global_rect().encloses(stream_label.get_global_rect()), "stream diagnostics stay inside generation panel")
	hud.queue_free()


func _test_resource_hud_layout() -> void:
	var hud := ResourceHud.new()
	add_child(hud)
	await get_tree().process_frame
	EventBus.active_tool_changed.emit(&"axe", "斧头")
	EventBus.inventory_changed.emit({"wood": 4, "stone": 2, "fiber": 1})
	EventBus.resource_prompt_changed.emit("[E] 采集树木 · 耐久 3")
	await get_tree().process_frame
	var panel := hud.find_child("ResourcePanel", true, false) as Control
	var tool_label := hud.find_child("ToolLabel", true, false) as Label
	var inventory_label := hud.find_child("InventoryLabel", true, false) as Label
	var prompt_label := hud.find_child("ResourcePromptLabel", true, false) as Label
	_assert_true(panel != null and tool_label != null and inventory_label != null and prompt_label != null, "resource HUD tool, inventory and prompt nodes exist")
	if panel != null and tool_label != null and inventory_label != null:
		_assert_true(panel.get_global_rect().encloses(tool_label.get_global_rect()), "active tool stays inside resource panel")
		_assert_true(panel.get_global_rect().encloses(inventory_label.get_global_rect()), "inventory summary stays inside resource panel")
	hud.queue_free()


func _test_survival_hud_layout() -> void:
	var hud := SurvivalHud.new()
	add_child(hud)
	await get_tree().process_frame
	EventBus.survival_state_changed.emit({
		"enabled": true,
		"hunger": 48.0,
		"hunger_maximum": 100.0,
		"body_temperature": 33.4,
		"temperature_state": "寒冷",
		"wetness": 82.0,
		"wetness_maximum": 100.0,
		"oxygen": 35.0,
		"oxygen_maximum": 100.0,
		"effects": [{"effect_id": "frostbite", "display_name": "冻伤", "remaining_seconds": 24.0, "color": "91cbea"}],
	})
	await get_tree().process_frame
	var panel := hud.find_child("SurvivalPanel", true, false) as Control
	var hunger_fill := hud.find_child("HungerFill", true, false) as ColorRect
	var wetness_fill := hud.find_child("WetnessFill", true, false) as ColorRect
	var oxygen_fill := hud.find_child("OxygenFill", true, false) as ColorRect
	var temperature := hud.find_child("BodyTemperatureLabel", true, false) as Label
	var effects := hud.find_child("StatusEffectsLabel", true, false) as Label
	var mode := hud.find_child("SurvivalModeLabel", true, false) as Label
	_assert_true(panel != null and hunger_fill != null and wetness_fill != null and oxygen_fill != null and temperature != null and effects != null and mode != null, "survival HUD exposes hunger, temperature, wetness, oxygen, effects and mode nodes")
	_assert_true(is_equal_approx(hunger_fill.scale.x, 0.48) and is_equal_approx(wetness_fill.scale.x, 0.82) and is_equal_approx(oxygen_fill.scale.x, 0.35) and "寒冷" in temperature.text and "冻伤" in effects.text, "survival HUD reflects exact attributes and active effects")
	_assert_true(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "survival HUD remains inside the 1280×720 viewport")
	EventBus.survival_state_changed.emit({"enabled": false, "hunger": 48.0, "hunger_maximum": 100.0, "body_temperature": 33.4, "temperature_state": "寒冷", "wetness": 82.0, "wetness_maximum": 100.0, "oxygen": 100.0, "oxygen_maximum": 100.0, "effects": []})
	await get_tree().process_frame
	_assert_true("已关闭" in mode.text, "survival HUD makes the disabled rule state explicit")
	hud.queue_free()


func _test_building_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood", 10)
	inventory.add_item(&"stone", 8)
	var panel := BuildingPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_building_state_changed(BuildingState.new().status_snapshot(inventory))
	panel.set_building_open(true)
	panel.update_preview_status({"valid": true, "reason": "可以放置"}, 90)
	await get_tree().process_frame
	var window := panel.find_child("BuildingWindow", true, false) as Control
	var piece_list := panel.find_child("BuildingPieceList", true, false) as VBoxContainer
	var count_label := panel.find_child("BuildingCountLabel", true, false) as Label
	var status_label := panel.find_child("BuildingPreviewStatus", true, false) as Label
	var help_label := panel.find_child("BuildingHelpLabel", true, false) as Label
	_assert_true(window != null and piece_list != null and count_label != null and status_label != null and help_label != null, "building panel exposes blueprint list, count, preview status and storage help")
	_assert_equal(panel.find_children("BuildingPiece_*", "", true, false).size(), 17, "building panel renders seventeen data-driven blueprints including automation and the home beacon")
	_assert_true("0/4096" in count_label.text and "90°" in status_label.text and "可以放置" in status_label.text, "building panel reflects placement capacity, rotation and live validation")
	_assert_true(panel.is_building_open() and get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open building panel remains inside the 1280×720 viewport")
	panel.set_building_open(false)
	_assert_true(not panel.is_building_open(), "building panel closes without mutating its selected blueprint")
	panel.queue_free()


func _test_farming_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"wheat_seed", 3)
	var panel := FarmingPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_farming_state_changed(FarmingState.new().status_snapshot(inventory))
	panel.set_farming_open(true)
	panel.update_target_status({"valid": true, "description": "小麦已成熟 · 左键收获"})
	await get_tree().process_frame
	var window := panel.find_child("FarmingWindow", true, false) as Control
	var crop_list := panel.find_child("FarmingCropList", true, false) as VBoxContainer
	var count_label := panel.find_child("FarmingCountLabel", true, false) as Label
	var status_label := panel.find_child("FarmingTargetStatus", true, false) as Label
	var help_label := panel.find_child("FarmingHelpLabel", true, false) as Label
	_assert_true(window != null and crop_list != null and count_label != null and status_label != null and help_label != null, "farming panel exposes crop list, plot count, target status and weather help")
	_assert_equal(panel.find_children("FarmingCrop_*", "", true, false).size(), 4, "farming panel renders exactly four data-driven crop rows")
	_assert_true("0/4096" in count_label.text and "成熟" in status_label.text and "雨天" in help_label.text, "farming panel reflects capacity, live crop state and weather behavior")
	_assert_true(panel.is_farming_open() and get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open farming panel remains inside the 1280×720 viewport")
	panel.set_farming_open(false)
	_assert_true(not panel.is_farming_open() and panel.selected_crop_id() == &"wheat", "farming panel closes without mutating its selected crop")
	panel.queue_free()


func _test_husbandry_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"wheat_seed", 3)
	var panel := HusbandryPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_husbandry_state_changed(HusbandryState.new().status_snapshot(inventory))
	panel.set_husbandry_open(true)
	panel.update_target_status({"valid": true, "description": "鸡待收鸡蛋 ×2 · 左键收取"})
	await get_tree().process_frame
	var window := panel.find_child("HusbandryWindow", true, false) as Control
	var animal_list := panel.find_child("HusbandryAnimalList", true, false) as VBoxContainer
	var count_label := panel.find_child("HusbandryCountLabel", true, false) as Label
	var status_label := panel.find_child("HusbandryTargetStatus", true, false) as Label
	var help_label := panel.find_child("HusbandryHelpLabel", true, false) as Label
	_assert_true(window != null and animal_list != null and count_label != null and status_label != null and help_label != null, "husbandry panel exposes species list, animal count, target status and simulation help")
	_assert_equal(panel.find_children("HusbandryAnimal_*", "", true, false).size(), 3, "husbandry panel renders exactly three data-driven species rows")
	_assert_true("0/256" in count_label.text and "鸡蛋" in status_label.text and "夜间" in help_label.text and "卸载区块" in help_label.text, "husbandry panel reflects capacity, live product target, sleep and inactive-chunk simulation")
	_assert_true(panel.is_husbandry_open() and get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open husbandry panel remains inside the 1280×720 viewport")
	panel.set_husbandry_open(false)
	_assert_true(not panel.is_husbandry_open() and panel.selected_animal_type() == &"chicken", "husbandry panel closes without mutating its selected species")
	panel.queue_free()


func _test_processing_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood", 2)
	var state := ProcessingSystem.new(inventory, BuildingState.new()).state_snapshot(Vector2i.ZERO)
	var panel := ProcessingPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_processing_state_changed(state)
	panel.set_processing_open(true)
	await get_tree().process_frame
	var window := panel.find_child("ProcessingWindow", true, false) as Control
	var tabs := panel.find_child("ProcessingStationTabs", true, false) as HBoxContainer
	var fuel_row := panel.find_child("ProcessingFuelRow", true, false) as HBoxContainer
	var list := panel.find_child("ProcessingRecipeList", true, false) as VBoxContainer
	var station_status := panel.find_child("ProcessingStationStatus", true, false) as Label
	_assert_true(window != null and tabs != null and fuel_row != null and list != null and station_status != null, "processing panel exposes window, station tabs, fuel controls, recipes and live device status")
	_assert_equal(tabs.get_child_count(), 2, "processing UI exposes cooking-pot and smelter tabs")
	_assert_equal(panel.find_children("ProcessingRecipe_*", "", true, false).size(), 6, "cooking-pot tab renders six meal and potion recipes")
	_assert_true(panel.find_child("ProcessingFuel_wood", true, false) != null and panel.find_child("ProcessingFuel_coal", true, false) != null and "附近没有烹饪锅" in station_status.text, "fuel buttons remain visible while missing-device feedback is explicit")
	panel._select_station(&"smelter")
	_assert_equal(panel.find_children("ProcessingRecipe_*", "", true, false).size(), 4, "smelter tab renders four ore and equipment-material recipes")
	_assert_true(panel.is_processing_open() and get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open processing panel remains inside the 1280×720 viewport")
	panel.set_processing_open(false)
	_assert_true(not panel.is_processing_open(), "processing panel closes without consuming inventory")
	panel.queue_free()


func _test_equipment_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"copper_sword", 1)
	inventory.add_item(&"tempered_plate", 2)
	inventory.add_item(&"iron_ingot", 3)
	var state := EquipmentState.new()
	state.import_inventory_slot(inventory, _find_item_slot(inventory, &"copper_sword"), 3606)
	var panel := EquipmentPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_state_changed(state.status_snapshot(inventory))
	panel.set_equipment_open(true)
	await get_tree().process_frame
	var window := panel.find_child("EquipmentWindow", true, false) as Control
	var slots := panel.find_child("EquipmentSlotList", true, false) as VBoxContainer
	var owned := panel.find_child("EquipmentOwnedList", true, false) as VBoxContainer
	var stats := panel.find_child("EquipmentStatsLabel", true, false) as Label
	var compare := panel.find_child("EquipmentCompareLabel", true, false) as Label
	var materials := panel.find_child("EquipmentMaterialLabel", true, false) as Label
	_assert_true(window != null and slots != null and owned != null and stats != null and compare != null and materials != null, "equipment panel exposes slots, owned instances, totals, comparison and materials")
	_assert_equal(panel.find_children("EquipmentSlot_*", "", true, false).size(), 6, "equipment UI renders six explicit character slots")
	_assert_equal(panel.find_children("EquipmentOwned_*", "", true, false).size(), 1, "equipment UI renders one quality-and-rarity instance row")
	_assert_true("攻击" in stats.text and "强化材料" in materials.text and panel.is_equipment_open(), "equipment UI reports combat totals and reinforcement resources")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open equipment panel remains inside the 1280×720 viewport")
	panel.set_equipment_open(false)
	_assert_true(not panel.is_equipment_open(), "equipment panel closes without mutating instances")
	panel.queue_free()


func _test_automation_panel_layout() -> void:
	var buildings := BuildingState.new()
	_assert_true(buildings.restore_snapshot(_automation_line_snapshot(&"automatic_smelter", [
		{"item_id": "copper_ore", "quantity": 3},
		{"item_id": "coal", "quantity": 1},
	])), "automation panel fixture validates")
	var system := AutomationSystem.new(buildings)
	system.advance_to(0.0)
	system.advance_to(5.0)
	var panel := AutomationPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_state_changed(system.state_snapshot(Vector2i.ZERO))
	panel.set_automation_open(true)
	await get_tree().process_frame
	var window := panel.find_child("AutomationWindow", true, false) as Control
	var summary := panel.find_child("AutomationSummaryLabel", true, false) as Label
	var list := panel.find_child("AutomationMachineList", true, false) as VBoxContainer
	var status := panel.find_child("AutomationStatusLabel", true, false) as Label
	_assert_true(window != null and summary != null and list != null and status != null, "automation panel exposes window, limits, machine list and connection help")
	_assert_equal(panel.find_children("AutomationMachine_*", "", true, false).size(), 1, "automation panel renders one stable machine row")
	_assert_true("1/128" in summary.text and "64" in summary.text and "720" in summary.text and panel.find_children("AutomationRecipe_*", "", true, false).size() == 1, "automation UI reports performance limits and an automatic-smelter recipe control")
	_assert_true(panel.is_automation_open() and get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open automation panel remains inside the 1280×720 viewport")
	panel.set_automation_open(false)
	_assert_true(not panel.is_automation_open(), "automation panel closes without mutating machine state")
	panel.queue_free()


func _test_homestead_panel_layout() -> void:
	var buildings := BuildingState.new()
	_assert_true(buildings.restore_snapshot({"schema_version": BuildingState.SCHEMA_VERSION, "placements": [
		{"placement_id": "surface:0:0:structure", "piece_id": "homestead_beacon", "world_tile": [0, 0], "rotation": 0},
	]}), "homestead panel beacon fixture validates")
	var state := HomesteadState.new()
	state.synchronize_markers(buildings, 12.0)
	var panel := HomesteadPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_state_changed(state.status_snapshot(buildings, FarmingState.new(), HusbandryState.new(), 20.0, Vector2i(30, 0), &"surface"))
	panel.set_homestead_open(true)
	await get_tree().process_frame
	var window := panel.find_child("HomesteadWindow", true, false) as Control
	var summary := panel.find_child("HomesteadSummaryLabel", true, false) as Label
	var list := panel.find_child("HomesteadBaseList", true, false) as VBoxContainer
	var status := panel.find_child("HomesteadStatusLabel", true, false) as Label
	_assert_true(window != null and summary != null and list != null and status != null, "homestead panel exposes limits, base list, loop progress and action feedback")
	_assert_equal(panel.find_children("HomesteadBase_*", "", true, false).size(), 1, "homestead panel renders one stable beacon-owned base row")
	_assert_true("1/3" in summary.text and "24" in summary.text and "32" in summary.text and panel.find_children("HomesteadTeleport_*", "", true, false).size() == 1, "homestead UI reports management limits and exposes the active-home travel control")
	_assert_true(panel.is_homestead_open() and get_viewport().get_visible_rect().encloses(window.get_global_rect()), "open homestead panel remains inside the 1280×720 viewport")
	panel.set_homestead_open(false)
	_assert_true(not panel.is_homestead_open(), "homestead panel closes without mutating base state")
	panel.queue_free()


func _test_inventory_panel_layout() -> void:
	var panel := InventoryPanel.new()
	add_child(panel)
	await get_tree().process_frame
	var window := panel.find_child("InventoryWindow", true, false) as Control
	var hotbar := panel.find_child("Hotbar", true, false) as Control
	var grid := panel.find_child("InventoryGrid", true, false) as GridContainer
	var split_button := panel.find_child("SplitStackButton", true, false) as Button
	var discard_button := panel.find_child("DiscardItemButton", true, false) as Button
	var sort_button := panel.find_child("SortInventoryButton", true, false) as Button
	_assert_true(window != null and hotbar != null and grid != null, "inventory window, 8-slot hotbar and grid exist")
	_assert_equal(panel.find_children("InventorySlot*", "", true, false).size(), 24, "inventory UI creates exactly 24 drag-capable slots")
	_assert_equal(panel.find_children("HotbarSlot*", "", true, false).size(), 8, "hotbar UI mirrors exactly eight inventory slots")
	_assert_true(split_button != null and discard_button != null and sort_button != null, "split, discard and category-sort controls exist")
	panel.set_inventory_open(true)
	await get_tree().process_frame
	_assert_true(panel.is_inventory_open(), "inventory can be opened and captures its own UI state")
	var viewport_rect := get_viewport().get_visible_rect()
	_assert_true(viewport_rect.encloses(window.get_global_rect()), "open inventory window remains inside the 1280×720 viewport")
	_assert_true(viewport_rect.encloses(hotbar.get_global_rect()), "always-visible hotbar remains inside the 1280×720 viewport")
	panel.set_inventory_open(false)
	_assert_true(not panel.is_inventory_open(), "inventory can close without changing gameplay state")
	panel.queue_free()


func _test_crafting_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"branch", 4)
	inventory.add_item(&"fiber", 3)
	var crafting := CraftingSystem.new(inventory)
	crafting.refresh_discoveries()
	var panel := CraftingPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_crafting_state_changed(crafting.recipe_views())
	var window := panel.find_child("CraftingWindow", true, false) as Control
	var tabs := panel.find_child("CraftingStationTabs", true, false) as HBoxContainer
	var list := panel.find_child("CraftingRecipeList", true, false) as VBoxContainer
	var status := panel.find_child("CraftingStatusLabel", true, false) as Label
	_assert_true(window != null and tabs != null and list != null and status != null, "crafting window, station tabs, recipe list and status exist")
	_assert_equal(tabs.get_child_count(), 3, "crafting UI exposes hands, workbench and campfire tabs")
	_assert_true(panel.find_child("Recipe_wood_axe", true, false) != null and panel.find_child("Craft_wood_axe", true, false) != null, "unlocked wooden-axe recipe has a data-driven row and action")
	panel.set_crafting_open(true)
	await get_tree().process_frame
	_assert_true(panel.is_crafting_open(), "crafting panel can be opened independently")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()), "crafting window remains inside the 1280×720 viewport")
	panel.set_crafting_open(false)
	_assert_true(not panel.is_crafting_open(), "crafting panel closes without mutating recipes")
	panel.queue_free()


func _test_responsive_ui_layouts() -> void:
	var resolutions := [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3440, 1440),
	]
	for resolution in resolutions:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var canvas := Control.new()
		canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(canvas)
		var gameplay := GameplayHud.new()
		var generation := GenerationHud.new()
		var combat := CombatHud.new()
		var enemy := EnemyHud.new()
		var milestone := MilestoneHud.new()
		var resource := ResourceHud.new()
		var survival := SurvivalHud.new()
		var building := BuildingPanel.new()
		var farming := FarmingPanel.new()
		var husbandry := HusbandryPanel.new()
		var processing := ProcessingPanel.new()
		var equipment := EquipmentPanel.new()
		var automation := AutomationPanel.new()
		var homestead := HomesteadPanel.new()
		var inventory := InventoryPanel.new()
		for hud in [gameplay, generation, combat, enemy, milestone, resource, survival, building, farming, husbandry, processing, equipment, automation, homestead, inventory]:
			canvas.add_child(hud)
		await get_tree().process_frame
		building._on_building_state_changed(BuildingState.new().status_snapshot())
		building.set_building_open(true)
		farming._on_farming_state_changed(FarmingState.new().status_snapshot())
		farming.set_farming_open(true)
		husbandry._on_husbandry_state_changed(HusbandryState.new().status_snapshot())
		husbandry.set_husbandry_open(true)
		processing._on_processing_state_changed(ProcessingSystem.new(InventoryModel.new(), BuildingState.new()).state_snapshot(Vector2i.ZERO))
		processing.set_processing_open(true)
		equipment._on_state_changed(EquipmentState.new().status_snapshot(InventoryModel.new()))
		equipment.set_equipment_open(true)
		automation._on_state_changed(AutomationSystem.new(BuildingState.new()).state_snapshot())
		automation.set_automation_open(true)
		homestead._on_state_changed(HomesteadState.new().status_snapshot(BuildingState.new(), FarmingState.new(), HusbandryState.new()))
		homestead.set_homestead_open(true)
		EventBus.resource_prompt_changed.emit("[E] 采集树木 · 耐久 3")
		await get_tree().process_frame
		var visible := Rect2(Vector2.ZERO, Vector2(resolution))
		var controls := [
			gameplay.find_child("GameplayPanel", true, false) as Control,
			gameplay.find_child("ControlHintsLabel", true, false) as Control,
			generation.find_child("GenerationPanel", true, false) as Control,
			combat.find_child("CombatPanel", true, false) as Control,
			combat.find_child("CombatFeedbackLabel", true, false) as Control,
			enemy.find_child("EnemyPanel", true, false) as Control,
			milestone.find_child("MilestonePanel", true, false) as Control,
			resource.find_child("ResourcePanel", true, false) as Control,
			resource.find_child("ResourcePromptLabel", true, false) as Control,
			survival.find_child("SurvivalPanel", true, false) as Control,
			building.find_child("BuildingWindow", true, false) as Control,
			farming.find_child("FarmingWindow", true, false) as Control,
			husbandry.find_child("HusbandryWindow", true, false) as Control,
			processing.find_child("ProcessingWindow", true, false) as Control,
			equipment.find_child("EquipmentWindow", true, false) as Control,
			automation.find_child("AutomationWindow", true, false) as Control,
			homestead.find_child("HomesteadWindow", true, false) as Control,
			inventory.find_child("Hotbar", true, false) as Control,
		]
		var all_inside := true
		for control in controls:
			all_inside = all_inside and control != null and visible.encloses(control.get_global_rect())
		_assert_true(all_inside, "all HUD controls stay inside %d×%d" % [resolution.x, resolution.y])
		var prompt := resource.find_child("ResourcePromptLabel", true, false) as Control
		var hotbar := inventory.find_child("Hotbar", true, false) as Control
		var hints := gameplay.find_child("ControlHintsLabel", true, false) as Control
		_assert_true(
			prompt != null and hotbar != null and hints != null
			and not prompt.get_global_rect().intersects(hotbar.get_global_rect())
			and not hints.get_global_rect().intersects(prompt.get_global_rect())
			and not hints.get_global_rect().intersects(hotbar.get_global_rect()),
			"interaction prompt, hints and hotbar keep safe spacing at %d×%d" % [resolution.x, resolution.y]
		)
		viewport.queue_free()
		await get_tree().process_frame


func _test_combat_nodes_and_hud() -> void:
	var controller := PlayerCombatController.new()
	add_child(controller)
	var dummy := CombatTargetDummy.new()
	dummy.position = Vector2(120, 120)
	add_child(dummy)
	var hazard := TrainingHazard.new()
	hazard.position = Vector2(180, 120)
	add_child(hazard)
	var hud := CombatHud.new()
	add_child(hud)
	await get_tree().physics_frame
	await get_tree().process_frame
	var hitbox := controller.find_child("PlayerAttackHitbox", true, false) as Area2D
	var hit_shape := controller.find_child("AttackCollisionShape2D", true, false) as CollisionShape2D
	_assert_true(hitbox != null and hit_shape != null and hitbox.collision_mask == 8, "player attack uses a short-lived Area2D enemy hitbox")
	_assert_true(dummy.collision_layer == 8 and hazard.collision_mask == 2, "training target and hazard use isolated enemy/player collision layers")
	var dummy_hit := dummy.receive_attack({"attack_id": 7, "damage": 12.0, "direction": Vector2.RIGHT, "knockback": 170.0})
	_assert_true(bool(dummy_hit["accepted"]) and int(dummy_hit["damage"]) == 10, "training target applies defense-adjusted melee damage")
	_assert_true((dummy.debug_snapshot()["knockback"] as Vector2).x > 0.0, "training target receives directional knockback")
	EventBus.combat_status_changed.emit({"weapon_name": "石剑", "combo_index": 2, "combo_count": 3, "cooldown_remaining": 0.2, "cooldown_total": 0.4})
	EventBus.grave_state_changed.emit({"count": 1, "graves": []})
	EventBus.combat_feedback.emit("石剑 · 第 2 段", true)
	await get_tree().process_frame
	var panel := hud.find_child("CombatPanel", true, false) as Control
	var weapon_label := hud.find_child("CombatWeaponLabel", true, false) as Label
	var combo_label := hud.find_child("CombatComboLabel", true, false) as Label
	var grave_label := hud.find_child("CombatGraveLabel", true, false) as Label
	var feedback_label := hud.find_child("CombatFeedbackLabel", true, false) as Label
	_assert_true(panel != null and weapon_label != null and combo_label != null and grave_label != null and feedback_label != null, "combat HUD exposes weapon, combo, cooldown, grave and feedback nodes")
	_assert_true("石剑" in weapon_label.text and "2/3" in combo_label.text and "1" in grave_label.text, "combat HUD reflects weapon combo and grave state")
	_assert_true(get_viewport().get_visible_rect().encloses(panel.get_global_rect()) and get_viewport().get_visible_rect().encloses(feedback_label.get_global_rect()), "combat HUD remains inside the 1280×720 viewport")
	var integration_player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	integration_player.position = Vector2(-2048.0, -4096.0)
	add_child(integration_player)
	var integration_chunk := TerrainGenerator.new(WorldSeed.from_text("combat-integration")).generate_chunk(Vector2i(-2, -4))
	var integration_stream := ChunkStreamManager.new()
	integration_stream.configure(WorldSeed.from_text("combat-integration"), integration_player, integration_chunk)
	add_child(integration_stream)
	await get_tree().physics_frame
	var integration_inventory := integration_stream.harvest_state().inventory_model()
	integration_inventory.add_item(&"wood_sword", 1)
	var integration_sword_slot := _find_item_slot(integration_inventory, &"wood_sword")
	integration_inventory.select_hotbar(integration_sword_slot)
	var integration_controller := PlayerCombatController.new()
	integration_controller.configure(integration_player, integration_stream)
	integration_player.add_child(integration_controller)
	var integration_dummy := CombatTargetDummy.new()
	integration_dummy.position = integration_player.position + Vector2.RIGHT * 30.0
	add_child(integration_dummy)
	await get_tree().physics_frame
	var started := integration_controller.request_attack()
	var first_contact := integration_controller._attempt_hit(integration_dummy)
	var repeated_contact := integration_controller._attempt_hit(integration_dummy)
	_assert_true(bool(started["ok"]) and first_contact and not repeated_contact and integration_dummy.hit_count == 1, "real attack controller applies one hit per target for each attack ID")
	_assert_equal(int(integration_inventory.slot(integration_sword_slot)["durability"]), 39, "one successful swing consumes weapon durability exactly once")
	controller.queue_free()
	dummy.queue_free()
	hazard.queue_free()
	hud.queue_free()
	integration_dummy.queue_free()
	integration_stream.queue_free()
	integration_player.queue_free()


func _test_enemy_runtime_and_hud() -> void:
	var catalog := EnemyCatalog.new()
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = Vector2.ZERO
	add_child(player)
	var far_enemy := EnemyBase.new()
	far_enemy.configure(catalog.enemy(&"slime"), player, "test:far:slime", Vector2(1000.0, 0.0), 500.0)
	add_child(far_enemy)
	await get_tree().physics_frame
	var sleeping_ticks := far_enemy.complex_tick_count()
	_assert_true(far_enemy.sleeping and sleeping_ticks == 0, "far enemy sleeps without running complex state logic")
	player.position = Vector2(900.0, 0.0)
	await get_tree().physics_frame
	_assert_true(not far_enemy.sleeping and far_enemy.complex_tick_count() > sleeping_ticks, "nearby player wakes a sleeping enemy")
	var defeat_events: Array = []
	far_enemy.defeated.connect(func(spawn_id: String, enemy_id: StringName, world_position: Vector2, drops: Array) -> void:
		defeat_events.append({"spawn_id": spawn_id, "enemy_id": enemy_id, "position": world_position, "drops": drops})
	)
	var lethal := far_enemy.receive_attack({"damage": 999.0, "direction": Vector2.RIGHT, "knockback": 30.0})
	_assert_true(bool(lethal["accepted"]) and bool(lethal["died"]) and far_enemy.state_name() == &"DEAD", "lethal player hit completes enemy death state")
	_assert_true(defeat_events.size() == 1 and not (defeat_events[0]["drops"] as Array).is_empty(), "enemy death emits one complete drop transaction")
	var attack_enemy := EnemyBase.new()
	attack_enemy.configure(catalog.enemy(&"wolf"), player, "test:attack:wolf", player.position + Vector2(20.0, 0.0), 500.0)
	add_child(attack_enemy)
	var health_before_attack := player.health
	attack_enemy._attack_player()
	_assert_true(player.health < health_before_attack, "enemy attack applies configured damage to the player")
	player.combat_state().tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 8
	wall.position = Vector2(55.0, 0.0)
	var wall_shape := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(20.0, 2000.0)
	wall_shape.shape = wall_rectangle
	wall.add_child(wall_shape)
	add_child(wall)
	player.position = Vector2(120.0, 0.0)
	var wall_enemy := EnemyBase.new()
	wall_enemy.configure(catalog.enemy(&"wolf"), player, "test:wall:wolf", Vector2.ZERO, 500.0)
	add_child(wall_enemy)
	for _frame in 150:
		wall_enemy._physics_process(1.0 / 60.0)
	_assert_true(wall_enemy.global_position.x < 43.0, "ground enemy collision prevents continuous movement through a wall")
	var hud := EnemyHud.new()
	add_child(hud)
	await get_tree().process_frame
	EventBus.enemy_state_changed.emit({"active": 12, "maximum": 18, "sleeping": 5, "counts": {"slime": 5, "wolf": 4, "cave_bat": 3}, "states": {"CHASE": 2, "ATTACK": 1}})
	await get_tree().process_frame
	var enemy_panel := hud.find_child("EnemyPanel", true, false) as Control
	var population_label := hud.find_child("EnemyPopulationLabel", true, false) as Label
	var types_label := hud.find_child("EnemyTypesLabel", true, false) as Label
	var states_label := hud.find_child("EnemyStatesLabel", true, false) as Label
	_assert_true(enemy_panel != null and population_label != null and types_label != null and states_label != null, "enemy HUD exposes population, type and state nodes")
	_assert_true("12/18" in population_label.text and "史莱姆 5" in types_label.text and "ATTACK 1" in states_label.text, "enemy HUD reflects bounded population and active states")
	_assert_true(get_viewport().get_visible_rect().encloses(enemy_panel.get_global_rect()), "enemy HUD remains inside the 1280×720 viewport")
	var director_player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	director_player.position = Vector2(8192.0, -4096.0)
	add_child(director_player)
	var drop_pool := WorldDropPool.new()
	drop_pool.configure(32, ResourceCatalog.new())
	add_child(drop_pool)
	var director := EnemyDirector.new()
	director.configure(WorldSeed.from_text("enemy-director-fixture"), director_player, drop_pool)
	add_child(director)
	await get_tree().process_frame
	for _step in 24:
		director.population_step()
	_assert_true(director.active_count() > 0 and director.active_count() <= director.maximum_active(), "repeated population updates never exceed the active-enemy hard cap")
	director._on_weather_state_changed({"enemy_population_multiplier": 1.2})
	_assert_equal(director.maximum_active(), 22, "weather multiplier changes the runtime enemy population cap")
	var all_offscreen := true
	var spawn_minimum_held := true
	for snapshot in director.active_snapshots():
		var world_position := snapshot["position"] as Vector2
		var screen_position := get_viewport().get_canvas_transform() * world_position
		all_offscreen = all_offscreen and not Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(96.0).has_point(screen_position)
		spawn_minimum_held = spawn_minimum_held and world_position.distance_to(director_player.global_position) >= float(catalog.population_value("spawn_minimum_distance_pixels", 760.0))
	_assert_true(all_offscreen and spawn_minimum_held, "new enemies appear outside the visible screen and minimum spawn radius")
	director._on_enemy_defeated("test:drop:slime", &"slime", director_player.position + Vector2(20.0, 0.0), catalog.resolve_drops(&"slime", "test:drop:slime"))
	_assert_true(drop_pool.active_quantity(&"slime_gel") >= 1, "enemy director sends canonical death drops through the bounded object pool")
	director.set_world_layer(&"underground")
	director._on_weather_state_changed({"enemy_population_multiplier": 1.2})
	_assert_true(director.world_layer() == &"underground" and director.maximum_active() == 18, "surface weather never modifies underground enemy population")
	far_enemy.queue_free()
	attack_enemy.queue_free()
	wall_enemy.queue_free()
	wall.queue_free()
	hud.queue_free()
	director.queue_free()
	drop_pool.queue_free()
	director_player.queue_free()
	player.queue_free()


func _test_adventure_runtime_and_hud() -> void:
	var catalog := MilestoneCatalog.new()
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = Vector2.ZERO
	add_child(player)
	var state := MilestoneState.new()
	var encounter := RuinEncounter.new()
	encounter.configure({"id": "test_ruin", "world_position": Vector2.ZERO, "biome_id": "desert"}, player, state, catalog)
	add_child(encounter)
	var hud := MilestoneHud.new()
	add_child(hud)
	var overlay := DayNightOverlay.new()
	add_child(overlay)
	var weather_overlay := WeatherOverlay.new()
	add_child(weather_overlay)
	var audio := AudioCuePlayer.new()
	add_child(audio)
	await get_tree().process_frame
	encounter._process(0.0)
	var guardian := encounter.guardian()
	_assert_true(state.ruin_discovered and guardian != null, "entering the canonical ruin discovers it and activates one Boss")
	encounter.set_world_layer(&"underground")
	_assert_true(not encounter.visible and not encounter.is_processing() and not guardian.is_physics_processing() and guardian.collision_layer == 0, "ruin and active Boss fully deactivate on the underground layer")
	encounter.set_world_layer(&"surface")
	_assert_true(encounter.visible and encounter.is_processing() and guardian.is_physics_processing() and guardian.collision_layer == 8, "ruin and active Boss restore their surface simulation state")
	var health_before := player.health
	guardian._attack_player()
	_assert_true(player.health < health_before, "small Boss applies its data-driven attack to the player")
	player.combat_state().tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	var lethal := guardian.receive_attack({"damage": 999.0, "direction": Vector2.RIGHT, "knockback": 40.0})
	_assert_true(bool(lethal["died"]) and state.boss_defeated, "lethal player attack completes the ruin Boss encounter once")
	var inventory := InventoryModel.new()
	_assert_true(encounter.try_interact(inventory), "ruin core handles nearby reward interaction")
	_assert_true(state.reward_claimed and inventory.quantity(&"ancient_core") == 1, "Boss reward enters inventory and completes the survival loop")
	encounter.try_interact(inventory)
	_assert_equal(inventory.quantity(&"ancient_core"), 1, "completed ruin cannot duplicate its one-time reward")
	var night_snapshot := DayNightCycle.new(DayNightCycle.new().seconds_at_phase(&"NIGHT") + 1.0).snapshot()
	EventBus.time_state_changed.emit(night_snapshot)
	EventBus.milestone_state_changed.emit({"objective": state.objective_text(), "reward_claimed": true, "boss_defeated": true})
	overlay.apply_time(night_snapshot)
	await get_tree().process_frame
	var panel := hud.find_child("MilestonePanel", true, false) as Control
	var time_label := hud.find_child("TimeLabel", true, false) as Label
	var objective_label := hud.find_child("ObjectiveLabel", true, false) as Label
	var boss_label := hud.find_child("BossLabel", true, false) as Label
	_assert_true(panel != null and time_label != null and objective_label != null and boss_label != null, "milestone HUD exposes time, objective and Boss nodes")
	_assert_true("夜晚" in time_label.text and "继续探索" in objective_label.text and "核心已领取" in boss_label.text, "milestone HUD reflects the completed flow and persisted time")
	_assert_true(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "milestone HUD remains inside the 1280×720 viewport")
	_assert_true(overlay.color.a > 0.0, "night phase applies a visible basic lighting overlay")
	overlay.configure_player(player)
	overlay.set_torch_enabled(true)
	_assert_true(overlay.torch_enabled() and overlay.material is ShaderMaterial, "selected torch activates a player-following shader light")
	var night_resource_chunk := ChunkData.new()
	night_resource_chunk.chunk_position = Vector2i.ZERO
	night_resource_chunk.add_resource(Vector2i(4, 4), ResourceCatalog.new().code_for_id(&"flower"), 0)
	var night_resource_layer := ResourceChunkLayer.new()
	add_child(night_resource_layer)
	night_resource_layer.apply_chunk(night_resource_chunk, {})
	EventBus.time_state_changed.emit(DayNightCycle.new().snapshot())
	await get_tree().process_frame
	_assert_equal(night_resource_layer.visible_resource_count(), 0, "moonflower is hidden outside the night phase")
	EventBus.time_state_changed.emit(night_snapshot)
	await get_tree().process_frame
	_assert_equal(night_resource_layer.visible_resource_count(), 1, "moonflower appears during the night phase")
	var weather_probe := WeatherSystem.new(WorldSeed.from_text("weather-runtime"))
	weather_probe.force_weather(&"RAIN")
	var rain_snapshot := weather_probe.snapshot()
	weather_overlay.apply_weather(rain_snapshot)
	EventBus.weather_state_changed.emit(rain_snapshot)
	await get_tree().process_frame
	var weather_label := hud.find_child("WeatherLabel", true, false) as Label
	_assert_true(weather_overlay.particle_style() == &"rain" and weather_overlay.particle_count() > 0, "rain presentation renders data-driven screen particles")
	_assert_true(weather_label != null and "降雨" in weather_label.text, "weather HUD reflects the active weather")
	_assert_equal(audio.ambient_weather, &"RAIN", "weather event switches the procedural ambient audio")
	_assert_true(audio.played_cues > 0 or audio.play_cue(&"success"), "combat and milestone events drive a playable basic sound cue")
	encounter.queue_free()
	hud.queue_free()
	overlay.queue_free()
	weather_overlay.queue_free()
	night_resource_layer.queue_free()
	audio.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_main_menu_layout() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var menu_scene := packed.instantiate() as Control
	add_child(menu_scene)
	await get_tree().process_frame
	var panel := menu_scene.find_child("MenuPanel", true, false) as Control
	var version_label := menu_scene.find_child("VersionLabel", true, false) as Control
	var footer := menu_scene.find_child("OfflineFooter", true, false) as Control
	var world_panel := menu_scene.find_child("WorldCreationPanel", true, false) as Control
	var world_name := menu_scene.find_child("WorldNameInput", true, false) as LineEdit
	var seed_input := menu_scene.find_child("SeedInput", true, false) as LineEdit
	var continue_button := menu_scene.find_child("ContinueButton", true, false) as Button
	var survival_toggle := menu_scene.find_child("SurvivalEnabledToggle", true, false) as CheckButton
	_assert_true(panel != null and version_label != null and footer != null, "menu layout nodes exist")
	_assert_true(world_panel != null and world_name != null and seed_input != null and continue_button != null and survival_toggle != null, "world creation, continue and survival-setting controls exist")
	if panel != null and version_label != null and footer != null:
		_assert_true(panel.get_global_rect().encloses(version_label.get_global_rect()), "version label stays inside menu panel")
		_assert_true(panel.get_global_rect().encloses(footer.get_global_rect()), "footer stays inside menu panel")
	menu_scene.queue_free()


func _read_json_for_test(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _cave_floor_is_connected(chunk: ChunkData) -> bool:
	var start := Vector2i(-1, -1)
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			if chunk.is_cave_floor(Vector2i(x, y)):
				start = Vector2i(x, y)
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return false
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var neighbors: Array[Vector2i] = [current + Vector2i.LEFT, current + Vector2i.RIGHT, current + Vector2i.UP, current + Vector2i.DOWN]
		for neighbor in neighbors:
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= WorldCoordinates.CHUNK_SIZE or neighbor.y >= WorldCoordinates.CHUNK_SIZE:
				continue
			if visited.has(neighbor) or not chunk.is_cave_floor(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return visited.size() == chunk.cave_cell_map.count(CaveGenerator.Cell.FLOOR)


func _dungeon_floor_is_connected(chunk: ChunkData) -> bool:
	var start := Vector2i(-1, -1)
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			if chunk.is_dungeon_floor(Vector2i(x, y)):
				start = Vector2i(x, y)
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return false
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for neighbor in [current + Vector2i.LEFT, current + Vector2i.RIGHT, current + Vector2i.UP, current + Vector2i.DOWN]:
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= WorldCoordinates.CHUNK_SIZE or neighbor.y >= WorldCoordinates.CHUNK_SIZE:
				continue
			if visited.has(neighbor) or not chunk.is_dungeon_floor(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return visited.size() == chunk.dungeon_cell_map.count(DungeonGenerator.Cell.FLOOR)


func _first_dungeon_feature_local(chunk: ChunkData, feature: int) -> Vector2i:
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			if chunk.dungeon_feature_at(local) == feature:
				return local
	return Vector2i(-1, -1)


func _first_dungeon_wall_local(chunk: ChunkData) -> Vector2i:
	for y in WorldCoordinates.CHUNK_SIZE:
		for x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(x, y)
			if chunk.dungeon_cell_at(local) == DungeonGenerator.Cell.WALL:
				return local
	return Vector2i(-1, -1)


func _write_json_for_test(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t", true, true) + "\n")
		file.flush()


func _automation_line_snapshot(machine_piece_id: StringName, source_storage: Array, target_storage: Array = []) -> Dictionary:
	var placements: Array[Dictionary] = []
	for x in 3:
		placements.append({
			"placement_id": "surface:%d:0:ground" % x,
			"piece_id": "wood_floor",
			"world_tile": [x, 0],
			"rotation": 0,
		})
	placements.append({
		"placement_id": "surface:0:0:structure",
		"piece_id": "storage_chest",
		"world_tile": [0, 0],
		"rotation": 0,
		"storage": source_storage.duplicate(true),
	})
	var machine := {
		"placement_id": "surface:1:0:structure",
		"piece_id": String(machine_piece_id),
		"world_tile": [1, 0],
		"rotation": 90,
		"automation_enabled": true,
		"automation_last_seconds": -1.0,
		"automation_cycles": 0,
		"automation_status": "idle",
	}
	if machine_piece_id == &"automatic_smelter":
		machine["automation_fuel_units"] = 0
		machine["automation_recipe_id"] = "copper_ingot"
	elif machine_piece_id == &"item_sorter":
		machine["sort_filter_item_id"] = "coal"
	placements.append(machine)
	placements.append({
		"placement_id": "surface:2:0:structure",
		"piece_id": "storage_chest",
		"world_tile": [2, 0],
		"rotation": 0,
		"storage": target_storage.duplicate(true),
	})
	return {"schema_version": BuildingState.SCHEMA_VERSION, "placements": placements}


func _storage_quantity_for_test(storage_record: Dictionary, item_id: StringName) -> int:
	var result := 0
	for value in storage_record.get("storage", []) as Array:
		var entry := value as Dictionary
		if StringName(entry.get("item_id", "")) == item_id:
			result += int(entry.get("quantity", 0))
	return result


func _find_item_slot(inventory: InventoryModel, item_id: StringName) -> int:
	for index in inventory.slot_count():
		if StringName(inventory.slot(index).get("item_id", "")) == item_id:
			return index
	return -1


func _json_file_count(path: String) -> int:
	var directory := DirAccess.open(path)
	if directory == null:
		return 0
	var result := 0
	for filename in directory.get_files():
		result += 1 if filename.ends_with(".json") else 0
	return result


func _directory_count(path: String) -> int:
	var directory := DirAccess.open(path)
	return directory.get_directories().size() if directory != null else 0


func _remove_test_save_tree(path: String) -> void:
	var saves_root := ProjectSettings.globalize_path(SaveManager.SAVE_ROOT)
	if not path.begins_with(saves_root.path_join("world_")):
		push_error("Refusing to remove a path outside the test save root: %s" % path)
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		DirAccess.remove_absolute(path.path_join(filename))
	for dirname in directory.get_directories():
		_remove_test_save_tree(path.path_join(dirname))
	DirAccess.remove_absolute(path)


func _assert_true(value: bool, label: String) -> void:
	if value:
		_passes += 1
		print("PASS | %s" % label)
	else:
		_failures.append(label)
		printerr("FAIL | %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (expected=%s actual=%s)" % [label, expected, actual])


func _finish() -> void:
	print("=== %d passed, %d failed ===" % [_passes, _failures.size()])
	if not _failures.is_empty():
		printerr("Failures: %s" % ", ".join(_failures))
		get_tree().quit(1)
	else:
		get_tree().quit(0)
