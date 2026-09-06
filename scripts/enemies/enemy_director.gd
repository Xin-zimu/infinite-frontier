class_name EnemyDirector
extends Node2D

signal dungeon_enemy_defeated(spawn_id: String, role: StringName)
signal regional_boss_defeated(boss_id: StringName)
signal enemy_defeated(spawn_id: String, enemy_id: StringName)
signal progression_enemy_defeated(spawn_id: String, enemy_id: StringName, region_id: String, level: int, elite: bool)

var _world_seed := 0
var _player: PlayerCharacter
var _drop_pool: WorldDropPool
var _catalog := EnemyCatalog.new()
var _planner: EnemySpawnPlanner
var _active: Dictionary = {}
var _cooldowns: Dictionary = {}
var _world_event_instances: Dictionary = {}
var _enemy_progression: Dictionary = {}
var _population_elapsed := 0.0
var _spawn_cursor := 0
var _time_phase: StringName = &"DAWN"
var _weather_population_multiplier := 1.0
var _world_event_population_multiplier := 1.0
var _world_layer: StringName = &"surface"
var _dungeon_id := ""
var _dungeon_anchor_chunk := Vector2i.ZERO
var _dungeon_run_state: Dictionary = {}
var _regional_boss_planner: RegionalBossPlanner
var _defeated_regional_bosses: Array = []
var _region_progression_catalog := RegionProgressionCatalog.new()
var _region_progression_model: RegionProgressionModel
var _unlocked_regional_bosses: Array[String] = []


func configure(world_seed: int, player: PlayerCharacter, drop_pool: WorldDropPool, world_layer: StringName = &"surface", dungeon_context := {}) -> void:
	_world_seed = world_seed
	_player = player
	_drop_pool = drop_pool
	_world_layer = world_layer
	_weather_population_multiplier = 1.0
	_world_event_population_multiplier = 1.0
	_apply_dungeon_context(dungeon_context as Dictionary)
	_planner = EnemySpawnPlanner.new(world_seed, _catalog)
	_regional_boss_planner = RegionalBossPlanner.new(world_seed)
	_region_progression_model = RegionProgressionModel.new(world_seed, _region_progression_catalog)
	_unlocked_regional_bosses = _region_progression_catalog.unlocked_boss_ids(0)


func update_regional_boss_state(state: Dictionary) -> void:
	_defeated_regional_bosses = (state.get("defeated_ids", []) as Array).duplicate()


func update_region_progression_state(state: Dictionary) -> void:
	var values: Variant = state.get("unlocked_boss_ids", [])
	if not values is Array:
		return
	var normalized: Array[String] = []
	for value in values as Array:
		var boss_id := String(value)
		if boss_id in RegionProgressionCatalog.REQUIRED_BOSS_IDS and not normalized.has(boss_id):
			normalized.append(boss_id)
	normalized.sort()
	if normalized == _unlocked_regional_bosses:
		return
	_unlocked_regional_bosses = normalized
	population_step()


func reset_for_relocation() -> void:
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active.clear()
	_cooldowns.clear()
	_world_event_instances.clear()
	_enemy_progression.clear()
	_spawn_cursor = 0
	population_step()


func _ready() -> void:
	name = "EnemyDirector"
	z_index = 6
	if _player == null or _drop_pool == null or not _catalog.is_valid():
		push_error("EnemyDirector requires a player, drop pool and valid enemy catalog.")
		set_process(false)
		return
	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.weather_state_changed.connect(_on_weather_state_changed)
	population_step()


func _process(delta: float) -> void:
	for spawn_id_value in _cooldowns.keys():
		var spawn_id := String(spawn_id_value)
		_cooldowns[spawn_id] = maxf(0.0, float(_cooldowns[spawn_id]) - delta)
		if float(_cooldowns[spawn_id]) <= 0.0:
			_cooldowns.erase(spawn_id)
	_population_elapsed += delta
	if _population_elapsed >= float(_catalog.population_value("population_tick_seconds", 0.45)):
		_population_elapsed = 0.0
		population_step()


func population_step() -> void:
	if _player == null or _planner == null:
		return
	_despawn_far_enemies()
	if _active.size() < maximum_active():
		_spawn_from_nearby_chunks()
	_emit_metrics()


func active_count() -> int:
	return _active.size()


func sleeping_count() -> int:
	var result := 0
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if is_instance_valid(enemy) and enemy.sleeping:
			result += 1
	return result


func maximum_active() -> int:
	if _world_layer == &"dungeon":
		return 6
	return maxi(1, roundi(float(_catalog.maximum_active_for_phase(_time_phase)) * _weather_population_multiplier * _world_event_population_multiplier))


func set_world_event_population_multiplier(value: float) -> void:
	var normalized := clampf(value, 0.25, 4.0) if _world_layer == &"surface" else 1.0
	if is_equal_approx(normalized, _world_event_population_multiplier):
		return
	_world_event_population_multiplier = normalized
	population_step()


func ensure_world_event_enemy(instance_id: String, spawn_id: String, enemy_id: StringName, world_position: Vector2) -> bool:
	if _world_layer != &"surface" or instance_id.is_empty() or not spawn_id.begins_with("event-enemy:") \
			or _catalog.enemy(enemy_id) == null:
		return false
	if _active.has(spawn_id):
		return true
	if _cooldowns.has(spawn_id):
		return false
	var enemy := _spawn_enemy({"spawn_id": spawn_id, "enemy_id": enemy_id, "world_position": world_position})
	if enemy == null:
		return false
	_world_event_instances[spawn_id] = instance_id
	return true


func retain_world_event_instances(instance_ids: Array[String]) -> void:
	var retained := {}
	for instance_id in instance_ids:
		retained[instance_id] = true
	var changed := false
	for spawn_id_value in _world_event_instances.keys():
		var spawn_id := String(spawn_id_value)
		if retained.has(String(_world_event_instances[spawn_id])):
			continue
		if _active.has(spawn_id):
			var enemy := _active[spawn_id] as EnemyBase
			if is_instance_valid(enemy):
				enemy.queue_free()
			_active.erase(spawn_id)
			_cooldowns.erase(spawn_id)
		_world_event_instances.erase(spawn_id)
		_enemy_progression.erase(spawn_id)
		changed = true
	if changed:
		_emit_metrics()


func active_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if is_instance_valid(enemy):
			result.append(enemy.debug_snapshot())
	return result


func catalog() -> EnemyCatalog:
	return _catalog


func set_world_layer(world_layer: StringName, dungeon_context := {}) -> void:
	var context := dungeon_context as Dictionary
	var next_dungeon_id := String(context.get("dungeon_id", ""))
	if world_layer == _world_layer and (world_layer != &"dungeon" or next_dungeon_id == _dungeon_id):
		if world_layer == &"dungeon":
			_apply_dungeon_context(context)
		return
	_world_layer = world_layer
	_weather_population_multiplier = 1.0
	_world_event_population_multiplier = 1.0
	_apply_dungeon_context(context)
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active.clear()
	_cooldowns.clear()
	_world_event_instances.clear()
	_enemy_progression.clear()
	_spawn_cursor = 0
	population_step()


func world_layer() -> StringName:
	return _world_layer


func update_dungeon_state(run_state: Dictionary) -> void:
	_dungeon_run_state = run_state.duplicate(true)


func _spawn_from_nearby_chunks() -> void:
	if _world_layer == &"dungeon":
		_spawn_dungeon_encounters()
		return
	var current_chunk := WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	_spawn_regional_bosses(current_chunk)
	if _active.size() >= maximum_active():
		return
	var chunk_coordinates := ChunkStreamPlanner.coordinates_in_radius(current_chunk, ChunkStreamPlanner.PRELOAD_RADIUS)
	_planner.retain_chunks(chunk_coordinates, _world_layer)
	var candidates: Array[Dictionary] = []
	for coordinate in chunk_coordinates:
		candidates.append_array(_planner.candidates_for_chunk(coordinate, _time_phase, _world_layer))
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["spawn_id"]) < String(b["spawn_id"])
	)
	var start := posmod(_spawn_cursor, candidates.size())
	_spawn_cursor += 1
	for offset in candidates.size():
		if _active.size() >= maximum_active():
			break
		var candidate := candidates[posmod(start + offset, candidates.size())]
		var spawn_id := String(candidate["spawn_id"])
		if _active.has(spawn_id) or _cooldowns.has(spawn_id):
			continue
		var world_position := candidate["world_position"] as Vector2
		var distance := world_position.distance_to(_player.global_position)
		if distance < float(_catalog.population_value("spawn_minimum_distance_pixels", 760.0)) \
				or distance > float(_catalog.population_value("spawn_maximum_distance_pixels", 1450.0)) \
				or _is_on_screen(world_position, 96.0):
			continue
		_spawn_enemy(candidate)


func _spawn_regional_bosses(current_chunk: Vector2i) -> void:
	if _regional_boss_planner == null:
		return
	for candidate in _regional_boss_planner.candidates_near(current_chunk, 1, _defeated_regional_bosses):
		if _active.size() >= maximum_active():
			return
		var spawn_id := String(candidate["spawn_id"])
		if not _unlocked_regional_bosses.has(String(candidate.get("boss_id", ""))):
			continue
		if _active.has(spawn_id) or _cooldowns.has(spawn_id):
			continue
		if (candidate["world_position"] as Vector2).distance_to(_player.global_position) > 1120.0:
			continue
		_spawn_enemy(candidate)


func _spawn_dungeon_encounters() -> void:
	if _dungeon_id.is_empty():
		return
	var chunk := DungeonGenerator.new(_world_seed, _dungeon_id, _dungeon_anchor_chunk).generate_chunk(_dungeon_anchor_chunk)
	for candidate in _planner.candidates_for_dungeon(chunk, _dungeon_id, _dungeon_run_state):
		if _active.size() >= maximum_active():
			break
		var spawn_id := String(candidate["spawn_id"])
		if _active.has(spawn_id):
			continue
		_spawn_enemy(candidate)


func _spawn_enemy(candidate: Dictionary) -> EnemyBase:
	var definition := _catalog.enemy(candidate["enemy_id"] as StringName)
	if definition == null:
		return null
	var enemy := EnemyBase.new()
	var spawn_id := String(candidate["spawn_id"])
	var world_position := candidate["world_position"] as Vector2
	var chunk_position := candidate.get(
		"chunk_position",
		WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(world_position))
	) as Vector2i
	var progression := _region_progression_model.enemy_profile(chunk_position, spawn_id, definition.role, _world_layer) \
		if _region_progression_model != null else {}
	enemy.configure(
		definition,
		_player,
		spawn_id,
		world_position,
		float(_catalog.population_value("logic_sleep_distance_pixels", 920.0)),
		progression
	)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	_active[spawn_id] = enemy
	_enemy_progression[spawn_id] = progression.duplicate(true)
	return enemy


func _despawn_far_enemies() -> void:
	var maximum_distance := float(_catalog.population_value("despawn_distance_pixels", 1700.0))
	for spawn_id_value in _active.keys():
		var spawn_id := String(spawn_id_value)
		var enemy := _active[spawn_id] as EnemyBase
		if not is_instance_valid(enemy):
			_active.erase(spawn_id)
			_enemy_progression.erase(spawn_id)
			continue
		if enemy.global_position.distance_to(_player.global_position) <= maximum_distance:
			continue
		_active.erase(spawn_id)
		_world_event_instances.erase(spawn_id)
		_enemy_progression.erase(spawn_id)
		_cooldowns[spawn_id] = 2.0
		enemy.queue_free()


func _on_enemy_defeated(spawn_id: String, enemy_id: StringName, world_position: Vector2, drops: Array) -> void:
	var progression := (_enemy_progression.get(spawn_id, {}) as Dictionary).duplicate(true)
	_active.erase(spawn_id)
	_world_event_instances.erase(spawn_id)
	_enemy_progression.erase(spawn_id)
	_cooldowns[spawn_id] = float(_catalog.population_value("respawn_cooldown_seconds", 18.0))
	var drop_index := 0
	for drop_value in drops:
		var drop := drop_value as Dictionary
		var offset := Vector2((drop_index - 1) * 11, 5 + posmod(drop_index, 2) * 5)
		if not _drop_pool.spawn_drop(drop["item_id"] as StringName, int(drop["quantity"]), world_position + offset):
			LogManager.warning("EnemyDirector", "掉落池已满，无法生成 %s" % drop["item_id"])
		drop_index += 1
	EventBus.combat_feedback.emit("击败%s，掉落已生成" % _catalog.enemy(enemy_id).display_name, true)
	enemy_defeated.emit(spawn_id, enemy_id)
	progression_enemy_defeated.emit(
		spawn_id,
		enemy_id,
		String(progression.get("region_id", "")),
		int(progression.get("level", 1)),
		bool(progression.get("elite", false))
	)
	var definition := _catalog.enemy(enemy_id)
	if _world_layer == &"dungeon" and definition != null and definition.role in [&"elite", &"boss"]:
		dungeon_enemy_defeated.emit(spawn_id, definition.role)
	elif _world_layer == &"surface" and definition != null and definition.role == &"boss" and spawn_id.begins_with("regional_boss:"):
		regional_boss_defeated.emit(StringName(spawn_id.trim_prefix("regional_boss:")))
	_emit_metrics()


func _is_on_screen(world_position: Vector2, margin: float) -> bool:
	if get_viewport() == null:
		return false
	var screen_position := get_viewport().get_canvas_transform() * world_position
	return Rect2(Vector2.ZERO, get_viewport_rect().size).grow(margin).has_point(screen_position)


func _emit_metrics() -> void:
	var counts := {}
	for enemy_id in _catalog.enemy_ids():
		counts[String(enemy_id)] = 0
	var states := {}
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if not is_instance_valid(enemy) or enemy.definition == null:
			continue
		var enemy_id := String(enemy.definition.enemy_id)
		counts[enemy_id] = int(counts.get(enemy_id, 0)) + 1
		var state := String(enemy.state_name())
		states[state] = int(states.get(state, 0)) + 1
	EventBus.enemy_state_changed.emit({
		"active": _active.size(),
		"sleeping": sleeping_count(),
		"maximum": maximum_active(),
		"counts": counts,
		"states": states,
		"cooldowns": _cooldowns.size(),
	})


func _on_time_state_changed(snapshot: Dictionary) -> void:
	_time_phase = StringName(snapshot.get("phase", &"DAWN"))
	population_step()


func _on_weather_state_changed(snapshot: Dictionary) -> void:
	_weather_population_multiplier = 1.0 if _world_layer == &"underground" \
		else clampf(float(snapshot.get("enemy_population_multiplier", 1.0)), 0.25, 3.0)


func _apply_dungeon_context(context: Dictionary) -> void:
	_dungeon_id = String(context.get("dungeon_id", ""))
	var anchor: Variant = context.get("anchor_chunk", Vector2i.ZERO)
	_dungeon_anchor_chunk = anchor as Vector2i if anchor is Vector2i else Vector2i(int((anchor as Array)[0]), int((anchor as Array)[1])) if anchor is Array and (anchor as Array).size() == 2 else Vector2i.ZERO
	_dungeon_run_state = (context.get("run_state", {}) as Dictionary).duplicate(true)
