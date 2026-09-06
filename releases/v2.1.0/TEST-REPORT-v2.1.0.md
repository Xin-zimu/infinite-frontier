# V2.1.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (127 required files).
- Automated result: 718 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Model coverage: catalog schema, schedule continuity, deterministic naming/planning, required-service fallback, pathfinding and state validation.
- Economy coverage: exact sell/buy totals, stable currency, insufficient-capacity rollback and persistent trade counters.
- Runtime coverage: bounded actor activation, phase schedule, dialogue panel, merchant transactions, inn sleep request and off-layer release.
- Persistence coverage: current-format NPC round trip plus explicit save-format-2-through-10 migration.
- UI/font coverage: responsive NPC window and all V2.1 Chinese glyphs in the bundled offline font.
