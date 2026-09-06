class_name StructureCatalog
extends RefCounted

enum TileKind { FLOOR, WALL, DOOR, CHEST, ENEMY_SPAWN, ALTAR, ENTRANCE, CAMPFIRE }
enum MarkerKind { NONE, CHEST, ENEMY_SPAWN, DUNGEON_ENTRANCE }

const DEFAULT_CONFIG_PATH := "res://data/structures.json"
const ALLOWED_GLYPHS := ".FWDC EAXR"

var _valid := false
var _error_message := ""
var _region_size_tiles := 192
var _spawn_chance := 0.0
var _templates: Array[Dictionary] = []
var _ids_by_code: Array[StringName] = []


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_load(config_path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func region_size_tiles() -> int:
	return _region_size_tiles


func spawn_chance() -> float:
	return _spawn_chance


func template_count() -> int:
	return _templates.size()


func templates() -> Array[Dictionary]:
	return _templates.duplicate(true)


func template_by_code(code: int) -> Dictionary:
	return _templates[code].duplicate(true) if code >= 0 and code < _templates.size() else {}


func template_by_id(structure_id: StringName) -> Dictionary:
	var code := _ids_by_code.find(structure_id)
	return template_by_code(code)


func display_name(code: int) -> String:
	var definition := template_by_code(code)
	return String(definition.get("display_name", "未知建筑"))


func color_for_code(code: int) -> Color:
	var definition := template_by_code(code)
	return Color(String(definition.get("base_color", "ff00ff")))


func choose(weight_roll: int) -> Dictionary:
	var total := 0
	for definition in _templates:
		total += int(definition["weight"])
	if total <= 0:
		return {}
	var resolved := posmod(weight_roll, total)
	for definition in _templates:
		resolved -= int(definition["weight"])
		if resolved < 0:
			return definition.duplicate(true)
	return _templates.back().duplicate(true)


static func tile_kind_for_glyph(glyph: String) -> int:
	match glyph:
		"W": return TileKind.WALL
		"D": return TileKind.DOOR
		"C": return TileKind.CHEST
		"E": return TileKind.ENEMY_SPAWN
		"A": return TileKind.ALTAR
		"X": return TileKind.ENTRANCE
		"R": return TileKind.CAMPFIRE
		_: return TileKind.FLOOR


static func marker_kind_for_glyph(glyph: String) -> int:
	match glyph:
		"C": return MarkerKind.CHEST
		"E": return MarkerKind.ENEMY_SPAWN
		"X": return MarkerKind.DUNGEON_ENTRANCE
		_: return MarkerKind.NONE


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open structure configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Structure configuration is not an object")
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported structure schema version")
		return
	_region_size_tiles = int(root.get("region_size_tiles", 0))
	_spawn_chance = float(root.get("spawn_chance", -1.0))
	if _region_size_tiles < 64 or _spawn_chance < 0.0 or _spawn_chance > 1.0:
		_fail("Invalid structure region size or spawn chance")
		return
	var values: Variant = root.get("templates", [])
	if not values is Array or (values as Array).is_empty():
		_fail("Structure templates must be a non-empty array")
		return
	for value in values as Array:
		if not value is Dictionary or not _validate_template(value as Dictionary):
			return
	_valid = true


func _validate_template(value: Dictionary) -> bool:
	var definition := value.duplicate(true)
	var structure_id := StringName(definition.get("id", ""))
	var code := int(definition.get("code", -1))
	var rows: Variant = definition.get("rows", [])
	if structure_id.is_empty() or code < 0 or _ids_by_code.has(structure_id):
		_fail("Structure IDs and codes must be unique")
		return false
	if not rows is Array or (rows as Array).is_empty():
		_fail("Structure %s has no rows" % structure_id)
		return false
	var width := String((rows as Array)[0]).length()
	if width <= 0 or width > 31 or (rows as Array).size() > 31:
		_fail("Structure %s dimensions are invalid" % structure_id)
		return false
	for row_value in rows as Array:
		var row := String(row_value)
		if row.length() != width:
			_fail("Structure %s rows are not rectangular" % structure_id)
			return false
		for glyph in row:
			if not ALLOWED_GLYPHS.contains(glyph):
				_fail("Structure %s contains unknown glyph %s" % [structure_id, glyph])
				return false
	if int(definition.get("weight", 0)) <= 0:
		_fail("Structure %s has invalid weight" % structure_id)
		return false
	while _ids_by_code.size() <= code:
		_ids_by_code.append(&"")
		_templates.append({})
	if not _ids_by_code[code].is_empty():
		_fail("Structure code %d is duplicated" % code)
		return false
	definition["width"] = width
	definition["height"] = (rows as Array).size()
	_ids_by_code[code] = structure_id
	_templates[code] = definition
	return true


func _fail(message: String) -> void:
	_valid = false
	_error_message = message
	push_error(message)
