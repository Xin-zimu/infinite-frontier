extends Node

## Central signal hub. Systems communicate through typed signals instead of
## reaching into each other's scene trees.

signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)
signal settings_changed(key: StringName, value: Variant)
signal notification_requested(message: String, severity: StringName)
signal debug_visibility_changed(visible: bool)
signal player_health_changed(current: float, maximum: float)
signal player_stamina_changed(current: float, maximum: float)
signal player_state_changed(state_name: StringName)
signal resource_prompt_changed(text: String)
signal active_tool_changed(tool_id: StringName, display_name: String)
signal inventory_changed(inventory: Dictionary)
signal inventory_state_changed(inventory_state: Dictionary)
signal crafting_state_changed(recipe_views: Array)
signal interaction_feedback(message: String, successful: bool)
signal attack_started(attack: Dictionary)
signal combat_status_changed(status: Dictionary)
signal combat_feedback(message: String, successful: bool)
signal grave_state_changed(state: Dictionary)
signal enemy_state_changed(state: Dictionary)
signal time_state_changed(state: Dictionary)
signal weather_state_changed(state: Dictionary)
signal season_state_changed(state: Dictionary)
signal world_layer_changed(state: Dictionary)
signal dungeon_state_changed(state: Dictionary)
signal milestone_state_changed(state: Dictionary)
signal exploration_state_changed(state: Dictionary)
signal npc_interaction_requested(state: Dictionary)
signal npc_state_changed(state: Dictionary)
signal relationship_state_changed(state: Dictionary)
signal quest_state_changed(state: Dictionary)
signal world_choice_state_changed(state: Dictionary)
signal faction_state_changed(state: Dictionary)
signal world_event_state_changed(state: Dictionary)
signal region_progression_state_changed(state: Dictionary)
signal survival_state_changed(state: Dictionary)
signal building_state_changed(state: Dictionary)
signal farming_state_changed(state: Dictionary)
signal husbandry_state_changed(state: Dictionary)
signal processing_state_changed(state: Dictionary)
signal equipment_state_changed(state: Dictionary)
signal automation_state_changed(state: Dictionary)
signal homestead_state_changed(state: Dictionary)
signal sleep_requested(npc_id: String, display_name: String)
signal save_status_changed(message: String, successful: bool)


func request_scene(scene_path: String) -> void:
	scene_change_requested.emit(scene_path)


func notify(message: String, severity: StringName = &"info") -> void:
	notification_requested.emit(message, severity)
