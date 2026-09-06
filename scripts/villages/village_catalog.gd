class_name VillageCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/villages.json"

var _valid := false
var _error_message := ""
var _config: Dictionary = {}


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open village configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Village configuration is not an object")
		return
	_config = (parsed as Dictionary).duplicate(true)
	if int(_config.get("schema_version", 0)) != 1:
		_fail("Unsupported village schema version")
		return
	if region_size_tiles() < 128 or spawn_chance() < 0.0 or spawn_chance() > 1.0:
		_fail("Village region size or spawn chance is invalid")
		return
	if house_count_min() < 1 or house_count_max() < house_count_min():
		_fail("Village house count range is invalid")
		return
	_valid = true


func is_valid() -> bool: return _valid
func error_message() -> String: return _error_message
func region_size_tiles() -> int: return int(_config.get("region_size_tiles", 384))
func spawn_chance() -> float: return float(_config.get("spawn_chance", 0.0))
func house_count_min() -> int: return int(_config.get("house_count_min", 4))
func house_count_max() -> int: return int(_config.get("house_count_max", 7))
func house_radius_min() -> int: return int(_config.get("house_radius_min", 10))
func house_radius_max() -> int: return int(_config.get("house_radius_max", 17))


func color(name: String) -> Color:
	return Color(String((_config.get("road_colors", {}) as Dictionary).get(name, "ff00ff")))


func _fail(message: String) -> void:
	_valid = false
	_error_message = message
	push_error(message)
