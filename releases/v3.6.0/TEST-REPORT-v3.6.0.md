# V3.6.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (179 required files).
- Automated result: 1,198 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: six slots, four qualities, four rarities, five affixes, one set, nine definitions and all canonical item/weapon references.
- Model coverage: deterministic rolls, unique ownership, compatible slot selection, two-accessory behavior, set bonuses, comparison, +5 cap, repair and broken-item retention.
- Runtime coverage: inventory registration, active weapon, outgoing attack, defense, maximum attributes, durability damage and immutable state views.
- UI coverage: six slot rows, import/owned lists, comparison, enhance/repair controls and four target resolutions from 1280×720 through 3440×1440.
- Persistence coverage: exact schema-1 round trip, invalid reference rejection, no inventory duplication and format-22 no-fabrication migration.
- Regression coverage: generation-v5 checksum and every prior inventory, processing, building, farming, husbandry, survival, quest, faction, event, cave, dungeon, combat and progression invariant remain valid.
