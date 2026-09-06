class_name HomesteadCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/homestead.json"

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _marker_piece_id: StringName = &""
var _base_radius_tiles := 0
var _max_bases := 0
var _minimum_spacing_tiles := 0
var _teleport_cooldown_seconds := 0.0
var _default_names: Array[String] = []


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func marker_piece_id() -> StringName:
	return _marker_piece_id


func base_radius_tiles() -> int:
	return _base_radius_tiles


func max_bases() -> int:
	return _max_bases


func minimum_spacing_tiles() -> int:
	return _minimum_spacing_tiles


func teleport_cooldown_seconds() -> float:
	return _teleport_cooldown_seconds


func default_name(number: int) -> String:
	var normalized := maxi(1, number)
	if normalized <= _default_names.size():
		return _default_names[normalized - 1]
	return "边境基地 %d" % normalized


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open homestead configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Homestead configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported homestead schema version in %s" % _config_path)
		return
	_marker_piece_id = StringName(root.get("marker_piece_id", ""))
	_base_radius_tiles = int(root.get("base_radius_tiles", 0))
	_max_bases = int(root.get("max_bases", 0))
	_minimum_spacing_tiles = int(root.get("minimum_spacing_tiles", 0))
	_teleport_cooldown_seconds = float(root.get("teleport_cooldown_seconds", -1.0))
	var names_value: Variant = root.get("default_names", [])
	if _marker_piece_id.is_empty() or _base_radius_tiles < 8 or _base_radius_tiles > 128 \
			or _max_bases < 1 or _max_bases > 8 \
			or _minimum_spacing_tiles < _base_radius_tiles or _minimum_spacing_tiles > 256 \
			or not is_finite(_teleport_cooldown_seconds) or _teleport_cooldown_seconds < 0.0 \
			or _teleport_cooldown_seconds > 3600.0 or not names_value is Array:
		_fail("Homestead limits are invalid in %s" % _config_path)
		return
	for value in names_value as Array:
		var display_name := String(value).strip_edges()
		if display_name.is_empty() or display_name.length() > 24:
			_fail("Homestead default name is invalid in %s" % _config_path)
			return
		_default_names.append(display_name)
	if _default_names.size() < _max_bases:
		_fail("Homestead configuration needs at least one name per base slot")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
