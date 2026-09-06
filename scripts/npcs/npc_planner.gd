class_name NpcPlanner
extends RefCounted

const HOUSE_ROLE_SEQUENCE: Array[StringName] = [&"merchant", &"innkeeper", &"farmer", &"guard", &"explorer"]

var _world_seed: int
var _catalog: NpcCatalog
var _village_catalog: VillageCatalog
var _village_planner: VillagePlanner


func _init(world_seed: int, catalog := NpcCatalog.new(), village_catalog := VillageCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_village_catalog = village_catalog
	_village_planner = VillagePlanner.new(world_seed, village_catalog)


func plan_for_region(region: Vector2i, terrain: TerrainGenerator) -> Dictionary:
	var village := _village_planner.village_for_region(region, terrain)
	if village.is_empty():
		return {}
	var layout := _village_planner.layout_for_village(village, terrain)
	var markers := layout.get("markers", []) as Array
	var npc_markers: Array[Dictionary] = []
	var shop_tile := village["center"] as Vector2i
	var well_tile := village["center"] as Vector2i
	var campfire_tile := (village["center"] as Vector2i) + Vector2i(2, 2)
	for value in markers:
		var marker := value as Dictionary
		match int(marker.get("marker", VillagePlanner.Marker.NONE)):
			VillagePlanner.Marker.NPC: npc_markers.append(marker)
			VillagePlanner.Marker.SHOP: shop_tile = marker["world_tile"] as Vector2i
			VillagePlanner.Marker.WELL: well_tile = marker["world_tile"] as Vector2i
	var present_indices := {}
	for marker in npc_markers:
		present_indices[int(marker.get("npc_index", -1))] = true
	var fallback_offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(-2, 0)]
	for required_index in 3:
		if present_indices.has(required_index):
			continue
		var fallback_home := (village["center"] as Vector2i) + fallback_offsets[required_index]
		npc_markers.append({
			"world_tile": fallback_home,
			"marker": VillagePlanner.Marker.NPC,
			"village_key": village["key"],
			"npc_index": required_index,
			"home_tile": fallback_home,
		})
	npc_markers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["npc_index"]) < int(b["npc_index"]))
	var plans: Array[Dictionary] = []
	for marker in npc_markers:
		var index := int(marker["npc_index"])
		var role_id := &"elder" if index == 0 else HOUSE_ROLE_SEQUENCE[posmod(index - 1, HOUSE_ROLE_SEQUENCE.size())]
		var role := _catalog.role(role_id)
		var names := role.get("names", []) as Array
		var stable_name := int(WorldSeed.from_text("%d|%s|%d|npc-name" % [_world_seed, village["key"], index]))
		var home_tile := marker["home_tile"] as Vector2i
		var outskirts_offset := _outskirts_offset(stable_name, index)
		var outskirts_tile := (village["center"] as Vector2i) + outskirts_offset
		var npc_id := "%s:npc:%d" % [village["key"], index]
		plans.append({
			"id": npc_id,
			"village_id": String(village["key"]),
			"npc_index": index,
			"role_id": String(role_id),
			"role_display_name": String(role.get("display_name", role_id)),
			"display_name": String(names[posmod(stable_name, names.size())]),
			"color": String(role.get("color", "ffffff")),
			"home_tile": home_tile,
			"locations": {
				"home": home_tile,
				"center": village["center"] as Vector2i,
				"shop": shop_tile,
				"well": well_tile,
				"campfire": campfire_tile,
				"outskirts": outskirts_tile,
			},
		})
	return {
		"village": village.duplicate(true),
		"cells": (layout.get("cells", {}) as Dictionary).duplicate(),
		"npcs": plans,
	}


func region_for_tile(world_tile: Vector2i) -> Vector2i:
	var size := _village_catalog.region_size_tiles()
	return Vector2i(floori(float(world_tile.x) / size), floori(float(world_tile.y) / size))


func _outskirts_offset(stable: int, index: int) -> Vector2i:
	var distance := 18 + posmod(stable >> 8, 8)
	match posmod(stable + index, 4):
		0: return Vector2i(distance, 0)
		1: return Vector2i(0, distance)
		2: return Vector2i(-distance, 0)
		_: return Vector2i(0, -distance)
