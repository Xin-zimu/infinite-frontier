class_name ExplorationMapState
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_CUSTOM_MARKERS := 32
const VALID_TYPES := ["village", "structure", "ruin", "cave", "dungeon", "boss", "custom", "home"]

var last_error := ""
var _discovered_chunks: Dictionary = {}
var _markers: Dictionary = {}
var _next_custom_id := 1


func reveal_chunk(center: Vector2i, radius := 1) -> bool:
	var changed := false
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var key := _chunk_key(Vector2i(x, y))
			if _discovered_chunks.has(key):
				continue
			_discovered_chunks[key] = Vector2i(x, y)
			changed = true
	return changed


func is_chunk_discovered(chunk: Vector2i) -> bool:
	return _discovered_chunks.has(_chunk_key(chunk))


func discovered_chunks() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value in _discovered_chunks.values():
		result.append(value as Vector2i)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return result


func discovered_count() -> int:
	return _discovered_chunks.size()


func register_marker(marker_id: String, marker_type: StringName, display_name: String, world_tile: Vector2i, color := "ffffff", travel_enabled := false) -> bool:
	if marker_id.is_empty() or not VALID_TYPES.has(String(marker_type)) or display_name.strip_edges().is_empty() or not is_chunk_discovered(WorldCoordinates.tile_to_chunk(world_tile)):
		return false
	var normalized := {
		"id": marker_id,
		"type": String(marker_type),
		"display_name": display_name.strip_edges(),
		"world_tile": [world_tile.x, world_tile.y],
		"color": Color(String(color)).to_html(false),
		"travel_enabled": bool(travel_enabled),
		"completed": bool((_markers.get(marker_id, {}) as Dictionary).get("completed", false)),
	}
	if _markers.get(marker_id, {}) == normalized:
		return false
	_markers[marker_id] = normalized
	return true


func add_custom_marker(world_tile: Vector2i, display_name := "自定义标记", color := "f0ca58") -> String:
	if not is_chunk_discovered(WorldCoordinates.tile_to_chunk(world_tile)) or custom_marker_count() >= MAX_CUSTOM_MARKERS:
		return ""
	var marker_id := "custom:%d" % _next_custom_id
	_next_custom_id += 1
	if not register_marker(marker_id, &"custom", display_name, world_tile, color, false):
		return ""
	return marker_id


func remove_custom_marker(marker_id: String) -> bool:
	var marker := _markers.get(marker_id, {}) as Dictionary
	if String(marker.get("type", "")) != "custom":
		return false
	_markers.erase(marker_id)
	return true


func custom_marker_count() -> int:
	var result := 0
	for marker in _markers.values():
		result += 1 if String((marker as Dictionary).get("type", "")) == "custom" else 0
	return result


func mark_completed(marker_id: String) -> bool:
	if not _markers.has(marker_id) or bool((_markers[marker_id] as Dictionary).get("completed", false)):
		return false
	(_markers[marker_id] as Dictionary)["completed"] = true
	return true


func marker(marker_id: String) -> Dictionary:
	return (_markers.get(marker_id, {}) as Dictionary).duplicate(true)


func markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _markers.values():
		result.append((value as Dictionary).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return result


func travel_points() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in markers():
		if bool(value.get("travel_enabled", false)):
			result.append(value)
	return result


func travel_world_position(marker_id: String) -> Vector2:
	var value := marker(marker_id)
	if value.is_empty() or not bool(value.get("travel_enabled", false)):
		return Vector2.INF
	var tile := value["world_tile"] as Array
	return WorldCoordinates.tile_to_world_pixel(Vector2i(int(tile[0]), int(tile[1])), true)


func persistence_snapshot() -> Dictionary:
	var chunk_values: Array = []
	for chunk in discovered_chunks():
		chunk_values.append([chunk.x, chunk.y])
	return {
		"schema_version": SCHEMA_VERSION,
		"next_custom_id": _next_custom_id,
		"discovered_chunks": chunk_values,
		"markers": markers(),
	}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_discovered_chunks.clear()
		_markers.clear()
		_next_custom_id = 1
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION or not value.get("discovered_chunks", []) is Array or not value.get("markers", []) is Array:
		return _fail("探索地图格式无效")
	var next_custom := int(value.get("next_custom_id", 0))
	if next_custom < 1:
		return _fail("探索地图自定义标记序号无效")
	var restored_chunks := {}
	for chunk_value in value.get("discovered_chunks", []) as Array:
		if not chunk_value is Array or (chunk_value as Array).size() != 2:
			return _fail("探索地图区块坐标无效")
		var chunk := Vector2i(int((chunk_value as Array)[0]), int((chunk_value as Array)[1]))
		var key := _chunk_key(chunk)
		if restored_chunks.has(key):
			return _fail("探索地图包含重复区块")
		restored_chunks[key] = chunk
	var restored_markers := {}
	var custom_count := 0
	var maximum_custom_id := 0
	for marker_value in value.get("markers", []) as Array:
		if not marker_value is Dictionary:
			return _fail("探索标记必须是对象")
		var normalized := _normalize_marker(marker_value as Dictionary, restored_chunks)
		if normalized.is_empty():
			return false
		var marker_id := String(normalized["id"])
		if restored_markers.has(marker_id):
			return _fail("探索标记 ID 重复")
		restored_markers[marker_id] = normalized
		if String(normalized["type"]) == "custom":
			custom_count += 1
			var custom_suffix := marker_id.trim_prefix("custom:")
			if not custom_suffix.is_valid_int() or int(custom_suffix) < 1:
				return _fail("自定义探索标记 ID 无效")
			maximum_custom_id = maxi(maximum_custom_id, int(custom_suffix))
	if custom_count > MAX_CUSTOM_MARKERS:
		return _fail("自定义探索标记超过上限")
	if next_custom <= maximum_custom_id:
		return _fail("探索地图自定义标记序号重复")
	_discovered_chunks = restored_chunks
	_markers = restored_markers
	_next_custom_id = next_custom
	last_error = ""
	return true


func status_snapshot() -> Dictionary:
	return {
		"discovered_chunks": discovered_count(),
		"marker_count": _markers.size(),
		"travel_point_count": travel_points().size(),
		"custom_marker_count": custom_marker_count(),
		"chunks": discovered_chunks(),
		"markers": markers(),
	}


func _normalize_marker(value: Dictionary, chunks: Dictionary) -> Dictionary:
	var marker_id := String(value.get("id", ""))
	var marker_type := String(value.get("type", ""))
	var display_name := String(value.get("display_name", "")).strip_edges()
	var tile_value: Variant = value.get("world_tile", [])
	if marker_id.is_empty() or not VALID_TYPES.has(marker_type) or display_name.is_empty() or not tile_value is Array or (tile_value as Array).size() != 2:
		_fail("探索标记字段无效")
		return {}
	var tile := Vector2i(int((tile_value as Array)[0]), int((tile_value as Array)[1]))
	if not chunks.has(_chunk_key(WorldCoordinates.tile_to_chunk(tile))):
		_fail("探索标记位于未发现迷雾区")
		return {}
	if marker_type == "custom" and not marker_id.begins_with("custom:"):
		_fail("自定义探索标记 ID 无效")
		return {}
	return {
		"id": marker_id,
		"type": marker_type,
		"display_name": display_name,
		"world_tile": [tile.x, tile.y],
		"color": Color(String(value.get("color", "ffffff"))).to_html(false),
		"travel_enabled": bool(value.get("travel_enabled", false)),
		"completed": bool(value.get("completed", false)),
	}


func _chunk_key(chunk: Vector2i) -> String:
	return "%d:%d" % [chunk.x, chunk.y]


func _fail(message: String) -> bool:
	last_error = message
	return false
