class_name WorldDiscoveryScanner
extends RefCounted

var _world_seed: int
var _terrain: TerrainGenerator
var _structure_catalog := StructureCatalog.new()
var _structure_planner: StructurePlanner
var _village_planner: VillagePlanner
var _cave_planner: CaveEntrancePlanner
var _ruin_plan: Dictionary
var _boss_planner: RegionalBossPlanner


func _init(world_seed: int) -> void:
	_world_seed = world_seed
	_terrain = TerrainGenerator.new(world_seed)
	_structure_planner = StructurePlanner.new(world_seed, _structure_catalog)
	_village_planner = VillagePlanner.new(world_seed)
	_cave_planner = CaveEntrancePlanner.new(world_seed)
	_ruin_plan = RuinPlanner.new(world_seed).plan()
	_boss_planner = RegionalBossPlanner.new(world_seed)


func markers_for_chunk(chunk_position: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	var village := _village_planner.generate_for_chunk(chunk_position, _terrain)
	for marker_value in village.get("markers", []) as Array:
		var marker := marker_value as Dictionary
		if int(marker.get("marker", VillagePlanner.Marker.NONE)) != VillagePlanner.Marker.VILLAGE_CENTER:
			continue
		_add_marker(result, seen, String(marker["village_key"]), &"village", "村庄传送点", marker["world_tile"] as Vector2i, "e6c46a", true)
	for entrance in _cave_planner.entrances_for_chunk(chunk_position, _terrain):
		_add_marker(result, seen, String(entrance["entrance_id"]), &"cave", "洞穴入口", entrance["world_tile"] as Vector2i, "79a8c7", false)
	var structure_instances := {}
	for cell_value in _structure_planner.generate_for_chunk(chunk_position, _terrain):
		var cell := cell_value as Dictionary
		var instance_key := String(cell["instance_key"])
		if not structure_instances.has(instance_key):
			structure_instances[instance_key] = cell
		if int(cell["marker_kind"]) == StructureCatalog.MarkerKind.DUNGEON_ENTRANCE:
			_add_marker(result, seen, "dungeon:%s" % instance_key, &"dungeon", "地牢入口", cell["world_tile"] as Vector2i, "b98ce8", true)
	for instance_key_value in structure_instances.keys():
		var cell := structure_instances[instance_key_value] as Dictionary
		var definition := _structure_catalog.template_by_code(int(cell["structure_code"]))
		_add_marker(result, seen, "structure:%s" % instance_key_value, &"structure", String(definition.get("display_name", "地表建筑")), cell["world_tile"] as Vector2i, "d3b77d", false)
	if not _ruin_plan.is_empty() and _ruin_plan["chunk"] == chunk_position:
		_add_marker(result, seen, "ruin:canonical", &"ruin", "古老遗迹", _ruin_plan["world_tile"] as Vector2i, "e4c66b", true)
	for plan in _boss_planner.plans():
		if plan["chunk_position"] != chunk_position:
			continue
		_add_marker(result, seen, "boss:%s" % plan["id"], &"boss", String(plan["display_name"]), plan["world_tile"] as Vector2i, String(plan["marker_color"]), false)
	return result


func _add_marker(result: Array[Dictionary], seen: Dictionary, marker_id: String, marker_type: StringName, display_name: String, tile: Vector2i, color: String, travel: bool) -> void:
	if seen.has(marker_id):
		return
	seen[marker_id] = true
	result.append({
		"id": marker_id,
		"type": marker_type,
		"display_name": display_name,
		"world_tile": tile,
		"color": color,
		"travel_enabled": travel,
	})
