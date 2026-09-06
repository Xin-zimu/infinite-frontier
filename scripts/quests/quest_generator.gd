class_name QuestGenerator
extends RefCounted

var _world_seed := 0
var _catalog: QuestCatalog


func _init(world_seed: int, catalog := QuestCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func board_key(board_id: String, day: int) -> String:
	return "%s|%d" % [board_id.strip_edges(), day]


func generate_board(board_id: String, day: int) -> Array[Dictionary]:
	var clean_board := board_id.strip_edges()
	if _catalog == null or not _catalog.is_valid() or clean_board.is_empty() or day < 1:
		return []
	var rule_ids := _catalog.random_rule_ids()
	var selected_rules: Dictionary = {}
	var result: Array[Dictionary] = []
	for slot in _catalog.random_offers_per_board():
		var selection_seed := WorldSeed.from_text("%d|quest-board|%s|%d|%d|rule|v1" % [_world_seed, clean_board, day, slot])
		var rule_index := posmod(selection_seed, rule_ids.size())
		while selected_rules.has(String(rule_ids[rule_index])):
			rule_index = posmod(rule_index + 1, rule_ids.size())
		var rule_id := rule_ids[rule_index]
		selected_rules[String(rule_id)] = true
		var definition := _generate_definition(clean_board, day, slot, rule_id)
		if definition.is_empty() or not _catalog.validate_generated_quest(definition):
			return []
		result.append(definition)
	return result


func _generate_definition(board_id: String, day: int, slot: int, rule_id: StringName) -> Dictionary:
	var rule := _catalog.random_rule(rule_id)
	if rule.is_empty():
		return {}
	var targets := rule.get("targets", []) as Array
	var giver_roles := rule.get("giver_roles", []) as Array
	var target_seed := WorldSeed.from_text("%d|quest-board|%s|%d|%d|target|v1" % [_world_seed, board_id, day, slot])
	var giver_seed := WorldSeed.from_text("%d|quest-board|%s|%d|%d|giver|v1" % [_world_seed, board_id, day, slot])
	var quantity_seed := WorldSeed.from_text("%d|quest-board|%s|%d|%d|quantity|v1" % [_world_seed, board_id, day, slot])
	var reward_seed := WorldSeed.from_text("%d|quest-board|%s|%d|%d|reward|v1" % [_world_seed, board_id, day, slot])
	var target := targets[posmod(target_seed, targets.size())] as Dictionary
	var giver_role := String(giver_roles[posmod(giver_seed, giver_roles.size())])
	var quantity := int(rule["quantity_min"]) + posmod(quantity_seed, int(rule["quantity_max"]) - int(rule["quantity_min"]) + 1)
	var coins := int(rule["coin_min"]) + posmod(reward_seed, int(rule["coin_max"]) - int(rule["coin_min"]) + 1)
	var clean_token := board_id.replace(":", "_").replace("/", "_").replace("|", "_").replace(" ", "_")
	var quest_id := "random:%s:%d:%d:%s" % [clean_token, day, slot, rule_id]
	var target_name := String(target["display_name"])
	return {
		"id": quest_id,
		"category": "random",
		"display_name": "%s · %s" % [rule["display_name"], target_name],
		"description": "第 %d 天的区域委托：完成%s相关目标。" % [day, target_name],
		"giver_role": giver_role,
		"prerequisite_ids": [],
		"objectives": [{
			"id": "objective",
			"type": String(rule["objective_type"]),
			"target_id": String(target["id"]),
			"quantity": quantity,
			"display_name": "%s%s" % [_objective_verb(String(rule["objective_type"])), target_name],
		}],
		"rewards": [{"item_id": "coin", "quantity": coins}],
		"can_abandon": true,
		"retryable": false,
		"random": {"board_id": board_id, "day": day, "slot": slot, "rule_id": String(rule_id)},
	}


func _objective_verb(objective_type: String) -> String:
	return {"collect": "持有", "defeat": "击败", "explore": "发现", "escort": "会见"}.get(objective_type, "完成")
