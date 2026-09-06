# V1.6.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (104 required files).
- Automated result: 560 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Cave coverage: deterministic entrances/cells/loot, minimum floor ratio, full floor connectivity, seam passage, all three veins, underground enemies, collision layer, chest interaction and torch lighting.
- Persistence coverage: surface and underground resource differences, opened chests, current layer, layer-specific graves, metadata/player layer consistency, backups and explicit save-format-2-through-7 migration.
