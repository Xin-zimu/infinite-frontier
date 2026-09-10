#!/usr/bin/env python3
"""Repository-level structural checks that do not require the Godot editor."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_PATHS = (
    "project.godot",
    "README.md",
    "AGENTS.md",
    "CHANGELOG.md",
    "docs/save-format.md",
    "scenes/main/main.tscn",
    "scenes/main/game.tscn",
    "scenes/player/player.tscn",
    "scripts/core/event_bus.gd",
    "scripts/core/game_manager.gd",
    "scripts/core/settings_manager.gd",
    "scripts/core/log_manager.gd",
    "scripts/save/save_manager.gd",
    "scripts/save/save_write_job.gd",
    "scripts/ui/ui_theme_factory.gd",
    "scripts/ui/ui_layout.gd",
    "scripts/main/world_sandbox.gd",
    "scripts/player/player_character.gd",
    "scripts/player/player_motor.gd",
    "scripts/generation/world_seed.gd",
    "scripts/generation/biome_catalog.gd",
    "scripts/generation/biome_rule.gd",
    "scripts/generation/resource_catalog.gd",
    "scripts/generation/resource_generator.gd",
    "scripts/generation/terrain_generator.gd",
    "scripts/generation/hydrology_generator.gd",
    "scripts/generation/cave_catalog.gd",
    "scripts/generation/cave_entrance_planner.gd",
    "scripts/generation/cave_generator.gd",
    "scripts/dungeons/dungeon_catalog.gd",
    "scripts/dungeons/dungeon_generator.gd",
    "scripts/dungeons/dungeon_run_state.gd",
    "scripts/structures/structure_catalog.gd",
    "scripts/structures/structure_planner.gd",
    "scripts/villages/village_catalog.gd",
    "scripts/villages/village_planner.gd",
    "scripts/npcs/npc_catalog.gd",
    "scripts/npcs/npc_world_state.gd",
    "scripts/npcs/npc_pathfinder.gd",
    "scripts/npcs/npc_planner.gd",
    "scripts/npcs/npc_actor.gd",
    "scripts/npcs/npc_director.gd",
    "scripts/npcs/relationship_catalog.gd",
    "scripts/npcs/relationship_state.gd",
    "scripts/quests/quest_catalog.gd",
    "scripts/quests/quest_generator.gd",
    "scripts/quests/quest_state.gd",
    "scripts/quests/world_choice_state.gd",
    "scripts/factions/faction_catalog.gd",
    "scripts/factions/faction_state.gd",
    "scripts/world_events/world_event_catalog.gd",
    "scripts/world_events/world_event_planner.gd",
    "scripts/world_events/world_event_state.gd",
    "scripts/progression/region_progression_catalog.gd",
    "scripts/progression/region_progression_model.gd",
    "scripts/progression/region_progression_state.gd",
    "scripts/survival/survival_catalog.gd",
    "scripts/survival/survival_state.gd",
    "scripts/building/building_catalog.gd",
    "scripts/building/building_state.gd",
    "scripts/building/building_preview.gd",
    "scripts/farming/farming_catalog.gd",
    "scripts/farming/farming_state.gd",
    "scripts/husbandry/husbandry_catalog.gd",
    "scripts/husbandry/husbandry_planner.gd",
    "scripts/husbandry/husbandry_state.gd",
    "scripts/processing/processing_catalog.gd",
    "scripts/processing/processing_system.gd",
    "scripts/equipment/equipment_catalog.gd",
    "scripts/equipment/equipment_state.gd",
    "scripts/crafting/recipe_data.gd",
    "scripts/crafting/recipe_catalog.gd",
    "scripts/crafting/crafting_system.gd",
    "scripts/combat/weapon_definition.gd",
    "scripts/combat/weapon_catalog.gd",
    "scripts/combat/damage_calculator.gd",
    "scripts/combat/attack_sequence_model.gd",
    "scripts/combat/player_combat_state.gd",
    "scripts/combat/grave_model.gd",
    "scripts/combat/player_combat_controller.gd",
    "scripts/combat/combat_target_dummy.gd",
    "scripts/combat/training_hazard.gd",
    "scripts/combat/grave_marker.gd",
    "scripts/enemies/enemy_definition.gd",
    "scripts/enemies/enemy_catalog.gd",
    "scripts/enemies/enemy_state_machine.gd",
    "scripts/enemies/enemy_spawn_planner.gd",
    "scripts/enemies/enemy_base.gd",
    "scripts/enemies/enemy_director.gd",
    "scripts/exploration/exploration_map_state.gd",
    "scripts/exploration/regional_boss_catalog.gd",
    "scripts/exploration/regional_boss_planner.gd",
    "scripts/exploration/regional_boss_state.gd",
    "scripts/exploration/world_discovery_scanner.gd",
    "scripts/adventure/milestone_catalog.gd",
    "scripts/adventure/milestone_state.gd",
    "scripts/adventure/day_night_cycle.gd",
    "scripts/adventure/ruin_planner.gd",
    "scripts/adventure/ruin_guardian.gd",
    "scripts/adventure/ruin_encounter.gd",
    "scripts/audio/audio_cue_player.gd",
    "scripts/items/item_data.gd",
    "scripts/items/item_catalog.gd",
    "scripts/items/inventory_model.gd",
    "data/biomes.json",
    "data/resources.json",
    "data/items.json",
    "data/recipes.json",
    "data/weapons.json",
    "data/enemies.json",
    "data/milestones.json",
    "data/time_cycle.json",
    "data/structures.json",
    "data/villages.json",
    "data/caves.json",
    "data/dungeons.json",
    "data/regional_bosses.json",
    "data/npcs.json",
    "scripts/world/world_coordinates.gd",
    "scripts/world/chunk_data.gd",
    "scripts/world/chunk_renderer.gd",
    "scripts/world/chunk_boundary_overlay.gd",
    "scripts/world/chunk_stream_planner.gd",
    "scripts/world/chunk_generation_job.gd",
    "scripts/world/chunk_stream_manager.gd",
    "scripts/world/resource_chunk_layer.gd",
    "scripts/world/structure_chunk_layer.gd",
    "scripts/world/village_chunk_layer.gd",
    "scripts/world/cave_chunk_layer.gd",
    "scripts/world/dungeon_chunk_layer.gd",
    "scripts/world/world_drop_pool.gd",
    "scripts/gameplay/resource_harvest_state.gd",
    "scripts/ui/resource_hud.gd",
    "scripts/ui/inventory_panel.gd",
    "scripts/ui/crafting_panel.gd",
    "scripts/ui/combat_hud.gd",
    "scripts/ui/enemy_hud.gd",
    "scripts/ui/day_night_overlay.gd",
    "scripts/ui/milestone_hud.gd",
    "scripts/ui/dungeon_hud.gd",
    "scripts/ui/exploration_map_canvas.gd",
    "scripts/ui/exploration_map_panel.gd",
    "scripts/ui/npc_interaction_panel.gd",
    "data/relationships.json",
    "data/quests.json",
    "data/factions.json",
    "data/world_events.json",
    "data/region_progression.json",
    "data/survival.json",
    "data/buildings.json",
    "data/farming.json",
    "data/husbandry.json",
    "data/processing.json",
    "data/equipment.json",
    "data/automation.json",
    "scripts/ui/quest_journal_panel.gd",
    "scripts/ui/faction_panel.gd",
    "scripts/ui/world_event_panel.gd",
    "scripts/ui/region_progression_panel.gd",
    "scripts/ui/survival_hud.gd",
    "scripts/ui/building_panel.gd",
    "scripts/ui/farming_panel.gd",
    "scripts/ui/husbandry_panel.gd",
    "scripts/ui/processing_panel.gd",
    "scripts/ui/equipment_panel.gd",
    "scripts/ui/automation_panel.gd",
    "scripts/automation/automation_catalog.gd",
    "scripts/automation/automation_system.gd",
    "scripts/homestead/homestead_catalog.gd",
    "scripts/homestead/homestead_state.gd",
    "scripts/ui/homestead_panel.gd",
    "data/homestead.json",
    "scripts/ocean/ocean_catalog.gd",
    "scripts/ocean/boat_state.gd",
    "scripts/world/boat_layer.gd",
    "data/ocean.json",
    "scripts/world/player_building_layer.gd",
    "scripts/world/farming_chunk_layer.gd",
    "scripts/world/animal_chunk_layer.gd",
    "assets/fonts/NotoSansCJKsc-ProjectSubset.otf",
    "tests/run_all.gd",
    "tests/test_runner.tscn",
    "tools/build_release.sh",
    "tools/run_tests.ps1",
    "tools/build_release.ps1",
    "tools/render_biome_map.gd",
    "tools/render_resource_map.gd",
    "tools/render_save_diff_map.gd",
    "tools/render_cave_map.gd",
    "tools/render_dungeon_map.gd",
    "tools/structure_editor.py",
)


def main() -> int:
    failures: list[str] = []
    for relative in REQUIRED_PATHS:
        if not (ROOT / relative).is_file():
            failures.append(f"missing required file: {relative}")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for autoload in ("EventBus", "LogManager", "SettingsManager", "SaveManager", "GameManager"):
        if not re.search(rf"^{autoload}=", project, flags=re.MULTILINE):
            failures.append(f"autoload not registered: {autoload}")

    version_text = (ROOT / "scripts/core/game_version.gd").read_text(encoding="utf-8")
    if 'const VERSION := "4.2.0"' not in version_text:
        failures.append("game version is not 4.2.0")

    if "const SAVE_VERSION := 27" not in version_text:
        failures.append("save version is not 27")

    if "const GENERATION_VERSION := 7" not in version_text:
        failures.append("generation version is not 7")

    if failures:
        print("Structural verification failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Structural verification passed ({len(REQUIRED_PATHS)} required files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
