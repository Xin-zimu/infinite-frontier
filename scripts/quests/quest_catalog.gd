class_name QuestCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/quests.json"
const VALID_CATEGORIES := ["main", "side", "random"]
const VALID_OBJECTIVE_TYPES := ["collect", "defeat", "explore", "escort"]
const VALID_EXPLORE_TARGETS := ["village", "structure", "ruin", "cave", "dungeon", "boss", "home"]

var _valid := false
var _error_message := ""
var _maximum_active := 1
var _quests: Dictionary = {}
var _order: Array[StringName] = []
var _random_board: Dictionary = {}
var _random_rules: Dictionary = {}
var _random_rule_order: Array[StringName] = []
var _world_choices: Dictionary = {}
var _world_choice_order: Array[StringName] = []
var _item_catalog := ItemCatalog.new()
var _enemy_catalog := EnemyCatalog.new()
var _npc_catalog := NpcCatalog.new()
var _faction_catalog := FactionCatalog.new()
var _region_catalog := RegionProgressionCatalog.new()


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func maximum_active() -> int:
	return _maximum_active


func quest_ids() -> Array[StringName]:
	return _order.duplicate()


func quest(quest_id: StringName) -> Dictionary:
	return (_quests.get(String(quest_id), {}) as Dictionary).duplicate(true)


func has_quest(quest_id: StringName) -> bool:
	return _quests.has(String(quest_id))


func random_offers_per_board() -> int:
	return int(_random_board.get("offers_per_board", 0))


func maximum_generated_quests() -> int:
	return int(_random_board.get("maximum_generated_quests", 0))


func random_rule_ids() -> Array[StringName]:
	return _random_rule_order.duplicate()


func random_rule(rule_id: StringName) -> Dictionary:
	return (_random_rules.get(String(rule_id), {}) as Dictionary).duplicate(true)


func world_choice_ids() -> Array[StringName]:
	return _world_choice_order.duplicate()


func world_choice(choice_id: StringName) -> Dictionary:
	return (_world_choices.get(String(choice_id), {}) as Dictionary).duplicate(true)


func choice_option(choice_id: StringName, option_id: StringName) -> Dictionary:
	for value in world_choice(choice_id).get("options", []) as Array:
		var option := value as Dictionary
		if StringName(option.get("id", "")) == option_id:
			return option.duplicate(true)
	return {}


func validate_generated_quest(definition: Dictionary) -> bool:
	var catalog_valid := _valid
	var fields_valid := _validate_quest(definition, true, false)
	_valid = catalog_valid
	if not fields_valid:
		return false
	if String(definition.get("category", "")) != "random" or not definition.get("random", {}) is Dictionary:
		return _runtime_fail("Generated quest metadata is invalid")
	var metadata := definition.get("random", {}) as Dictionary
	var rule := random_rule(StringName(metadata.get("rule_id", "")))
	var board_id := String(metadata.get("board_id", "")).strip_edges()
	var day := int(metadata.get("day", 0))
	var slot := int(metadata.get("slot", -1))
	if rule.is_empty() or board_id.is_empty() or day < 1 or slot < 0 or slot >= random_offers_per_board():
		return _runtime_fail("Generated quest origin is invalid")
	if not String(definition.get("id", "")).begins_with("random:") \
			or not (definition.get("prerequisite_ids", []) as Array).is_empty() \
			or bool(definition.get("retryable", true)):
		return _runtime_fail("Generated quest identity or retry rule is invalid")
	var objective := (definition.get("objectives", []) as Array)[0] as Dictionary
	if String(objective.get("type", "")) != String(rule["objective_type"]) \
			or int(objective["quantity"]) < int(rule["quantity_min"]) \
			or int(objective["quantity"]) > int(rule["quantity_max"]):
		return _runtime_fail("Generated quest objective is outside its rule")
	var target_allowed := false
	for target_value in rule.get("targets", []) as Array:
		if String((target_value as Dictionary).get("id", "")) == String(objective["target_id"]):
			target_allowed = true
			break
	if not target_allowed or not (rule.get("giver_roles", []) as Array).has(String(definition["giver_role"])):
		return _runtime_fail("Generated quest target or giver is outside its rule")
	var rewards := definition.get("rewards", []) as Array
	if rewards.size() != 1:
		return _runtime_fail("Generated quest reward shape is invalid")
	var reward := rewards[0] as Dictionary
	if String(reward.get("item_id", "")) != "coin" or int(reward.get("quantity", 0)) < int(rule["coin_min"]) \
			or int(reward.get("quantity", 0)) > int(rule["coin_max"]):
		return _runtime_fail("Generated quest reward is outside its rule")
	return true


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open quest configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Quest configuration is not an object")
		return
	var root := parsed as Dictionary
	_maximum_active = int(root.get("maximum_active", 0))
	if int(root.get("schema_version", 0)) != 2 or _maximum_active < 1 or _maximum_active > 16:
		_fail("Quest schema or active limit is invalid")
		return
	if not _item_catalog.is_valid() or not _enemy_catalog.is_valid() or not _npc_catalog.is_valid() \
			or not _faction_catalog.is_valid() or not _region_catalog.is_valid():
		_fail("Quest dependencies are invalid")
		return
	for value in root.get("quests", []) as Array:
		if not value is Dictionary or not _validate_quest(value as Dictionary, false, true):
			return
		var definition := (value as Dictionary).duplicate(true)
		var quest_id := String(definition["id"])
		_quests[quest_id] = definition
		_order.append(StringName(quest_id))
	if _order.size() < 20:
		_fail("Quest catalog requires at least 20 fixed templates")
		return
	for quest_id in _order:
		for prerequisite in (_quests[String(quest_id)] as Dictionary).get("prerequisite_ids", []) as Array:
			if not _quests.has(String(prerequisite)) or String(prerequisite) == String(quest_id):
				_fail("Quest prerequisite is missing or self-referential")
				return
	if not _is_acyclic() or not _load_random_board(root.get("random_board", {}) as Dictionary) \
			or not _load_world_choices(root.get("world_choices", []) as Array):
		return
	_valid = true


func _validate_quest(definition: Dictionary, allow_random: bool, check_duplicate: bool) -> bool:
	var quest_id := String(definition.get("id", ""))
	var category := String(definition.get("category", ""))
	var giver := StringName(definition.get("giver_role", ""))
	if quest_id.is_empty() or (check_duplicate and _quests.has(quest_id)) or not VALID_CATEGORIES.has(category) \
			or (category == "random" and not allow_random) \
			or String(definition.get("display_name", "")).strip_edges().is_empty() \
			or String(definition.get("description", "")).strip_edges().is_empty() or not _npc_catalog.role_exists(giver):
		return _fail("Quest identity, category or giver is invalid")
	var prerequisite_value: Variant = definition.get("prerequisite_ids", [])
	if not prerequisite_value is Array or (prerequisite_value as Array).size() > 8:
		return _fail("Quest prerequisites are invalid")
	var prerequisite_ids := {}
	for prerequisite in prerequisite_value as Array:
		var prerequisite_id := String(prerequisite)
		if prerequisite_id.is_empty() or prerequisite_ids.has(prerequisite_id):
			return _fail("Quest prerequisite IDs are invalid")
		prerequisite_ids[prerequisite_id] = true
	var objective_ids := {}
	var objectives := definition.get("objectives", []) as Array
	if objectives.is_empty() or objectives.size() > 8:
		return _fail("Quest objectives must contain 1-8 entries")
	for value in objectives:
		if not value is Dictionary:
			return _fail("Quest objective must be an object")
		var objective := value as Dictionary
		var objective_id := String(objective.get("id", ""))
		var objective_type := String(objective.get("type", ""))
		var target_id := StringName(objective.get("target_id", ""))
		if objective_id.is_empty() or objective_ids.has(objective_id) or not VALID_OBJECTIVE_TYPES.has(objective_type) \
				or target_id.is_empty() or int(objective.get("quantity", 0)) < 1 or int(objective.get("quantity", 0)) > 999 \
				or String(objective.get("display_name", "")).strip_edges().is_empty():
			return _fail("Quest objective fields are invalid")
		objective_ids[objective_id] = true
		if objective_type == "collect" and not _item_catalog.has_item(target_id):
			return _fail("Collect objective references an unknown item")
		if objective_type == "defeat" and _enemy_catalog.enemy(target_id) == null:
			return _fail("Defeat objective references an unknown enemy")
		if objective_type == "explore" and not VALID_EXPLORE_TARGETS.has(String(target_id)):
			return _fail("Explore objective references an unknown landmark type")
		if objective_type == "escort" and not _npc_catalog.role_exists(target_id):
			return _fail("Escort objective references an unknown NPC role")
	var rewards := definition.get("rewards", []) as Array
	if rewards.is_empty() or rewards.size() > 6:
		return _fail("Quest rewards must contain 1-6 entries")
	for value in rewards:
		if not value is Dictionary:
			return _fail("Quest reward must be an object")
		var reward := value as Dictionary
		if not _item_catalog.has_item(StringName(reward.get("item_id", ""))) or int(reward.get("quantity", 0)) < 1:
			return _fail("Quest reward references an invalid item or quantity")
	return true


func _load_random_board(board: Dictionary) -> bool:
	var offers := int(board.get("offers_per_board", 0))
	var maximum := int(board.get("maximum_generated_quests", 0))
	var values := board.get("rules", []) as Array
	if offers < 1 or offers > 6 or maximum < offers or maximum > 256 or values.size() < offers or values.size() > 16:
		return _fail("Random quest board limits are invalid")
	for value in values:
		if not value is Dictionary:
			return _fail("Random quest rule must be an object")
		var rule := value as Dictionary
		var rule_id := String(rule.get("id", ""))
		var objective_type := String(rule.get("objective_type", ""))
		var giver_roles := rule.get("giver_roles", []) as Array
		var targets := rule.get("targets", []) as Array
		if rule_id.is_empty() or _random_rules.has(rule_id) or not VALID_OBJECTIVE_TYPES.has(objective_type) \
				or String(rule.get("display_name", "")).strip_edges().is_empty() or giver_roles.is_empty() or targets.size() < 2 \
				or int(rule.get("quantity_min", 0)) < 1 or int(rule.get("quantity_max", 0)) < int(rule["quantity_min"]) \
				or int(rule.get("coin_min", 0)) < 1 or int(rule.get("coin_max", 0)) < int(rule["coin_min"]):
			return _fail("Random quest rule fields are invalid")
		for giver in giver_roles:
			if not _npc_catalog.role_exists(StringName(giver)):
				return _fail("Random quest rule references an unknown giver")
		var target_ids := {}
		for target_value in targets:
			if not target_value is Dictionary:
				return _fail("Random quest target must be an object")
			var target := target_value as Dictionary
			var target_id := StringName(target.get("id", ""))
			if target_id.is_empty() or target_ids.has(String(target_id)) or String(target.get("display_name", "")).strip_edges().is_empty() \
					or not _target_exists(objective_type, target_id):
				return _fail("Random quest target is invalid")
			target_ids[String(target_id)] = true
		_random_rules[rule_id] = rule.duplicate(true)
		_random_rule_order.append(StringName(rule_id))
	_random_board = {"offers_per_board": offers, "maximum_generated_quests": maximum}
	return true


func _load_world_choices(values: Array) -> bool:
	if values.size() < 3 or values.size() > 12:
		return _fail("World choices require 3-12 entries")
	var choice_points: int = _region_catalog.progress_points(&"world_choice")
	if choice_points < 1:
		return _fail("World-choice progress source is missing")
	for value in values:
		if not value is Dictionary:
			return _fail("World choice must be an object")
		var choice := value as Dictionary
		var choice_id := String(choice.get("id", ""))
		var prerequisite := StringName(choice.get("prerequisite_quest_id", ""))
		var options := choice.get("options", []) as Array
		if choice_id.is_empty() or _world_choices.has(choice_id) or not has_quest(prerequisite) \
				or String(quest(prerequisite).get("category", "")) != "main" \
				or String(choice.get("display_name", "")).strip_edges().is_empty() \
				or String(choice.get("description", "")).strip_edges().is_empty() or options.size() < 2 or options.size() > 4:
			return _fail("World choice fields are invalid")
		var option_ids := {}
		for option_value in options:
			if not option_value is Dictionary:
				return _fail("World choice option must be an object")
			var option := option_value as Dictionary
			var option_id := String(option.get("id", ""))
			var changes := option.get("faction_changes", []) as Array
			if option_id.is_empty() or option_ids.has(option_id) \
					or String(option.get("display_name", "")).strip_edges().is_empty() \
					or String(option.get("description", "")).strip_edges().is_empty() \
					or int(option.get("world_progress", 0)) != choice_points or changes.is_empty():
				return _fail("World choice option fields are invalid")
			option_ids[option_id] = true
			var changed_factions := {}
			for change_value in changes:
				if not change_value is Dictionary:
					return _fail("World choice faction change must be an object")
				var change := change_value as Dictionary
				var faction_id := StringName(change.get("faction_id", ""))
				var delta := int(change.get("delta", 0))
				if not _faction_catalog.has_faction(faction_id) or changed_factions.has(String(faction_id)) or delta == 0 or absi(delta) > 100:
					return _fail("World choice faction change is invalid")
				changed_factions[String(faction_id)] = true
		_world_choices[choice_id] = choice.duplicate(true)
		_world_choice_order.append(StringName(choice_id))
	return true


func _target_exists(objective_type: String, target_id: StringName) -> bool:
	if objective_type == "collect":
		return _item_catalog.has_item(target_id)
	if objective_type == "defeat":
		return _enemy_catalog.enemy(target_id) != null
	if objective_type == "explore":
		return VALID_EXPLORE_TARGETS.has(String(target_id))
	return _npc_catalog.role_exists(target_id)


func _is_acyclic() -> bool:
	var remaining := {}
	var resolved := {}
	for quest_id in _order:
		remaining[String(quest_id)] = true
	while not remaining.is_empty():
		var progressed := false
		for quest_id_value in remaining.keys():
			var ready := true
			for prerequisite in (_quests[String(quest_id_value)] as Dictionary).get("prerequisite_ids", []) as Array:
				if not resolved.has(String(prerequisite)):
					ready = false
					break
			if not ready:
				continue
			resolved[String(quest_id_value)] = true
			remaining.erase(quest_id_value)
			progressed = true
		if not progressed:
			return _fail("Quest prerequisites contain a cycle")
	return true


func _fail(message: String) -> bool:
	_valid = false
	_error_message = message
	push_error(message)
	return false


func _runtime_fail(message: String) -> bool:
	_error_message = message
	return false
