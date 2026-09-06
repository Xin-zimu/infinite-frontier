# V3.1.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (154 required files).
- Automated result: 911 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: attributes, environment rules, four effects, two foods, limits and stable IDs.
- Model coverage: hunger/activity drain, rain/water wetness, drying, heat/cold, exposure, tick damage, movement and disabled-mode pause.
- Recovery coverage: raw/cooked food, health/temperature restore, poison cleansing, death recovery and inn recovery.
- Runtime coverage: environment composition, atomic selected-slot consumption, HUD state, player damage and speed composition.
- Persistence coverage: exact survival round trip, tamper rejection and explicit save-format-2-through-17 migration.
- Regression coverage: generation-v5 checksum plus every prior inventory, quest, faction, event, dungeon and progression invariant remain valid.
