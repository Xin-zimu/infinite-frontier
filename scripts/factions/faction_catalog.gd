class_name FactionCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/factions.json"
const REQUIRED_IDS := [&"frontier_union", &"merchant_guild", &"pathfinders", &"ash_raiders"]
const REQUIRED_TIERS := [&"enemy", &"hostile", &"neutral", &"respected", &"allied"]
const REQUIRED_ACTIONS := [&"trade", &"quest", &"discovery", &"hostile_defeat", &"member_defeat"]

var _valid := false
var _error_message := ""
var _config: Dictionary = {}
var _tiers: Array[Dictionary] = []
var _factions: Dictionary = {}
var _faction_order: Array[StringName] = []
var _role_owners: Dictionary = {}
var _enemy_owners: Dictionary = {}
var _relations: Dictionary = {}
var _item_catalog := ItemCatalog.new()


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func standing_minimum() -> int:
	return int(_config.get("standing_minimum", -100))


func standing_maximum() -> int:
	return int(_config.get("standing_maximum", 100))


func event_log_limit() -> int:
	return int(_config.get("event_log_limit", 32))


func faction_ids() -> Array[StringName]:
	return _faction_order.duplicate()


func has_faction(faction_id: StringName) -> bool:
	return _factions.has(String(faction_id))


func faction(faction_id: StringName) -> Dictionary:
	return (_factions.get(String(faction_id), {}) as Dictionary).duplicate(true)


func default_standing(faction_id: StringName) -> int:
	return int((_factions.get(String(faction_id), {}) as Dictionary).get("default_standing", 0))


func tier_id(standing: int) -> StringName:
	var normalized := clampi(standing, standing_minimum(), standing_maximum())
	for definition in _tiers:
		if normalized <= int(definition["maximum"]):
			return StringName(definition["id"])
	return &"allied"


func tier(tier_id_value: StringName) -> Dictionary:
	for definition in _tiers:
		if StringName(definition["id"]) == tier_id_value:
			return definition.duplicate(true)
	return {}


func tier_rank(tier_id_value: StringName) -> int:
	for index in _tiers.size():
		if StringName(_tiers[index]["id"]) == tier_id_value:
			return index
	return -1


func action_value(action_id: StringName) -> int:
	return int((_config.get("actions", {}) as Dictionary).get(String(action_id), 0))


func role_faction(role_id: StringName) -> StringName:
	return StringName(_role_owners.get(String(role_id), ""))


func enemy_faction(enemy_id: StringName) -> StringName:
	return StringName(_enemy_owners.get(String(enemy_id), ""))


func relation(first: StringName, second: StringName) -> int:
	if first == second and has_faction(first):
		return standing_maximum()
	return int(_relations.get(_relation_key(first, second), 0))


func shop_offers(faction_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in (_factions.get(String(faction_id), {}) as Dictionary).get("shop", []) as Array:
		result.append((value as Dictionary).duplicate(true))
	return result


func adjusted_shop_price(base_price: int, standing: int) -> int:
	var multiplier := 1.0
	match tier_id(standing):
		&"respected":
			multiplier = 0.95
		&"allied":
			multiplier = 0.90
	return maxi(1, ceili(float(base_price) * multiplier))


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open faction configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Faction configuration is not an object")
		return
	_config = (parsed as Dictionary).duplicate(true)
	if int(_config.get("schema_version", 0)) != 1 \
			or standing_minimum() >= 0 or standing_maximum() <= 0 \
			or event_log_limit() < 1 or event_log_limit() > 128:
		_fail("Faction bounds, event limit or schema are invalid")
		return
	if not _validate_tiers() or not _validate_actions() or not _validate_factions() or not _validate_relations():
		return
	_valid = true


func _validate_tiers() -> bool:
	var tier_values: Variant = _config.get("tiers", [])
	if not tier_values is Array or (tier_values as Array).size() != REQUIRED_TIERS.size():
		return _fail("Faction tiers must contain the five required definitions")
	var previous_maximum := standing_minimum() - 1
	var seen := {}
	for value in tier_values as Array:
		if not value is Dictionary:
			return _fail("Faction tiers must be objects")
		var definition := (value as Dictionary).duplicate(true)
		var tier_id_value := StringName(definition.get("id", ""))
		var maximum := int(definition.get("maximum", standing_minimum() - 1))
		if tier_id_value != REQUIRED_TIERS[_tiers.size()] or seen.has(String(tier_id_value)) \
				or maximum <= previous_maximum or String(definition.get("display_name", "")).is_empty() \
				or String(definition.get("color", "")).is_empty():
			return _fail("Faction tiers must be ordered, unique and complete")
		seen[String(tier_id_value)] = true
		previous_maximum = maximum
		_tiers.append(definition)
	if previous_maximum != standing_maximum():
		return _fail("Faction tiers do not cover the complete standing range")
	for required in REQUIRED_TIERS:
		if not seen.has(String(required)):
			return _fail("Faction tier %s is missing" % required)
	return true


func _validate_actions() -> bool:
	var action_values: Variant = _config.get("actions", {})
	if not action_values is Dictionary:
		return _fail("Faction actions must be an object")
	var actions := action_values as Dictionary
	for action_id in REQUIRED_ACTIONS:
		if not actions.has(String(action_id)) or int(actions[String(action_id)]) == 0:
			return _fail("Faction action %s is missing or zero" % action_id)
	if action_value(&"member_defeat") >= 0:
		return _fail("Defeating a faction member must reduce standing")
	for positive_action in [&"trade", &"quest", &"discovery", &"hostile_defeat"]:
		if action_value(positive_action) <= 0:
			return _fail("Faction action %s must be positive" % positive_action)
	return true


func _validate_factions() -> bool:
	var faction_values: Variant = _config.get("factions", [])
	if not faction_values is Array or (faction_values as Array).size() != REQUIRED_IDS.size():
		return _fail("Faction configuration must contain exactly four factions")
	var npc_roles := NpcCatalog.new().role_ids()
	var enemy_catalog := EnemyCatalog.new()
	if not enemy_catalog.is_valid():
		return _fail("Faction enemies cannot be validated")
	for value in faction_values as Array:
		if not value is Dictionary:
			return _fail("Faction definitions must be objects")
		var definition := (value as Dictionary).duplicate(true)
		var faction_id := StringName(definition.get("id", ""))
		var faction_key := String(faction_id)
		var default_value := int(definition.get("default_standing", standing_minimum() - 1))
		if faction_id not in REQUIRED_IDS or _factions.has(faction_key) \
				or String(definition.get("display_name", "")).is_empty() \
				or String(definition.get("description", "")).is_empty() \
				or String(definition.get("color", "")).is_empty() \
				or default_value < standing_minimum() or default_value > standing_maximum():
			return _fail("Faction definitions must be unique and complete")
		var role_values: Variant = definition.get("role_ids", [])
		var enemy_values: Variant = definition.get("enemy_ids", [])
		var shop_values: Variant = definition.get("shop", [])
		if not role_values is Array or not enemy_values is Array or not shop_values is Array:
			return _fail("Faction members and shop must be arrays")
		for role_value in role_values as Array:
			var role_id := StringName(role_value)
			if role_id not in npc_roles or _role_owners.has(String(role_id)):
				return _fail("Faction roles must be known and uniquely owned")
			_role_owners[String(role_id)] = faction_key
		for enemy_value in enemy_values as Array:
			var enemy_id := StringName(enemy_value)
			if enemy_catalog.enemy(enemy_id) == null or _enemy_owners.has(String(enemy_id)):
				return _fail("Faction enemies must be known and uniquely owned")
			_enemy_owners[String(enemy_id)] = faction_key
		var seen_items := {}
		for offer_value in shop_values as Array:
			if not offer_value is Dictionary:
				return _fail("Faction shop offers must be objects")
			var offer := offer_value as Dictionary
			var item_id := StringName(offer.get("item_id", ""))
			var required_tier := StringName(offer.get("required_tier", ""))
			if not _item_catalog.has_item(item_id) or seen_items.has(String(item_id)) \
					or int(offer.get("quantity", 0)) < 1 or int(offer.get("price", 0)) < 1 \
					or required_tier not in REQUIRED_TIERS:
				return _fail("Faction shop offers are invalid")
			seen_items[String(item_id)] = true
		_factions[faction_key] = definition
		_faction_order.append(faction_id)
	for required in REQUIRED_IDS:
		if not _factions.has(String(required)):
			return _fail("Faction %s is missing" % required)
	return true


func _validate_relations() -> bool:
	var relation_values: Variant = _config.get("relations", [])
	var expected_count := REQUIRED_IDS.size() * (REQUIRED_IDS.size() - 1) / 2
	if not relation_values is Array or (relation_values as Array).size() != expected_count:
		return _fail("Faction relations must define every unique pair")
	for value in relation_values as Array:
		if not value is Dictionary:
			return _fail("Faction relations must be objects")
		var definition := value as Dictionary
		var first := StringName(definition.get("a", ""))
		var second := StringName(definition.get("b", ""))
		var relation_value := int(definition.get("value", standing_minimum() - 1))
		var key := _relation_key(first, second)
		if first == second or not has_faction(first) or not has_faction(second) or _relations.has(key) \
				or relation_value < standing_minimum() or relation_value > standing_maximum():
			return _fail("Faction relations contain an invalid or duplicate pair")
		_relations[key] = relation_value
	return _relations.size() == expected_count or _fail("Faction relations are incomplete")


func _relation_key(first: StringName, second: StringName) -> String:
	var values := [String(first), String(second)]
	values.sort()
	return "%s|%s" % values


func _fail(message: String) -> bool:
	_valid = false
	_error_message = message
	push_error(message)
	return false
