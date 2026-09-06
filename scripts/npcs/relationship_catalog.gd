class_name RelationshipCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/relationships.json"

var _valid := false
var _error_message := ""
var _config: Dictionary = {}
var _tiers: Array[Dictionary] = []
var _item_catalog := ItemCatalog.new()


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func affection_minimum() -> int:
	return int(_config.get("affection_minimum", -100))


func affection_maximum() -> int:
	return int(_config.get("affection_maximum", 100))


func reputation_minimum() -> int:
	return int(_config.get("reputation_minimum", -100))


func reputation_maximum() -> int:
	return int(_config.get("reputation_maximum", 100))


func trade_affection() -> int:
	return int(_config.get("trade_affection", 1))


func trade_reputation() -> int:
	return int(_config.get("trade_reputation", 1))


func gift_reputation_divisor() -> int:
	return maxi(1, int(_config.get("gift_reputation_divisor", 2)))


func tier_id(affection: int) -> StringName:
	var normalized := clampi(affection, affection_minimum(), affection_maximum())
	for value in _tiers:
		if normalized <= int(value["maximum"]):
			return StringName(value["id"])
	return &"trusted"


func tier(tier_id_value: StringName) -> Dictionary:
	for value in _tiers:
		if StringName(value["id"]) == tier_id_value:
			return value.duplicate(true)
	return {}


func gift_value(role_id: StringName, item_id: StringName) -> int:
	var role_gifts := (_config.get("role_gifts", {}) as Dictionary).get(String(role_id), {}) as Dictionary
	if (role_gifts.get("liked", []) as Array).has(String(item_id)):
		return int(_config.get("liked_gift_value", 8))
	if (role_gifts.get("disliked", []) as Array).has(String(item_id)):
		return int(_config.get("disliked_gift_value", -7))
	return int(_config.get("default_gift_value", 2))


func rewards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _config.get("rewards", []) as Array:
		result.append((value as Dictionary).duplicate(true))
	return result


func adjusted_buy_price(base_price: int, affection: int, reputation: int) -> int:
	var definition := tier(tier_id(affection))
	var multiplier := float(definition.get("buy_multiplier", 1.0)) - _reputation_bonus(reputation)
	return maxi(1, ceili(float(base_price) * maxf(multiplier, 0.5)))


func adjusted_sell_price(base_price: int, affection: int, reputation: int) -> int:
	var definition := tier(tier_id(affection))
	var multiplier := float(definition.get("sell_multiplier", 1.0)) + _reputation_bonus(reputation)
	return maxi(1, floori(float(base_price) * maxf(multiplier, 0.25)))


func dialogue(tier_id_value: StringName, index: int) -> String:
	var lines := (_config.get("dialogue", {}) as Dictionary).get(String(tier_id_value), []) as Array
	return String(lines[posmod(index, lines.size())]) if not lines.is_empty() else ""


func _reputation_bonus(reputation: int) -> float:
	var positive := maxi(reputation, 0)
	var steps := floori(float(positive) / 25.0)
	return minf(float(steps) * float(_config.get("reputation_discount_per_25", 0.02)), float(_config.get("maximum_reputation_discount", 0.08)))


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open relationship configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Relationship configuration is not an object")
		return
	_config = (parsed as Dictionary).duplicate(true)
	if int(_config.get("schema_version", 0)) != 1 \
			or affection_minimum() >= 0 or affection_maximum() <= 0 \
			or reputation_minimum() >= 0 or reputation_maximum() <= 0:
		_fail("Relationship bounds or schema are invalid")
		return
	var previous_maximum := affection_minimum() - 1
	var seen_tiers := {}
	for value in _config.get("tiers", []) as Array:
		if not value is Dictionary:
			_fail("Relationship tiers must be objects")
			return
		var definition := (value as Dictionary).duplicate(true)
		var tier_id_value := String(definition.get("id", ""))
		var maximum := int(definition.get("maximum", affection_minimum() - 1))
		if tier_id_value.is_empty() or seen_tiers.has(tier_id_value) or maximum <= previous_maximum \
				or float(definition.get("buy_multiplier", 0.0)) <= 0.0 or float(definition.get("sell_multiplier", 0.0)) <= 0.0:
			_fail("Relationship tiers must be ordered, unique and positive")
			return
		seen_tiers[tier_id_value] = true
		previous_maximum = maximum
		_tiers.append(definition)
	if previous_maximum != affection_maximum() or _tiers.size() != 5:
		_fail("Relationship tiers must cover the complete affection range")
		return
	for required in ["hostile", "wary", "neutral", "friendly", "trusted"]:
		if not seen_tiers.has(required):
			_fail("Relationship tier %s is missing" % required)
			return
	var npc_roles := NpcCatalog.new().role_ids()
	for role_value in (_config.get("role_gifts", {}) as Dictionary).keys():
		if not npc_roles.has(StringName(role_value)):
			_fail("Gift preferences reference an unknown NPC role")
			return
		var preferences := (_config["role_gifts"] as Dictionary)[role_value] as Dictionary
		for key in ["liked", "disliked"]:
			for item_value in preferences.get(key, []) as Array:
				if not _item_catalog.has_item(StringName(item_value)):
					_fail("Gift preferences reference an unknown item")
					return
	var seen_rewards := {}
	var previous_threshold := 0
	for value in _config.get("rewards", []) as Array:
		var reward := value as Dictionary
		var reward_id := String(reward.get("id", ""))
		var threshold := int(reward.get("minimum_affection", 0))
		if reward_id.is_empty() or seen_rewards.has(reward_id) or threshold <= previous_threshold \
				or not _item_catalog.has_item(StringName(reward.get("item_id", ""))) or int(reward.get("quantity", 0)) < 1:
			_fail("Relationship rewards are invalid")
			return
		seen_rewards[reward_id] = true
		previous_threshold = threshold
	_valid = true


func _fail(message: String) -> void:
	_valid = false
	_error_message = message
	push_error(message)
