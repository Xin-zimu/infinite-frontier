# V3.7.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (183 required files).
- Automated result: 1,249 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: four stable machines, cadence, connection span, throughput, automatic recipes, sorter filters and every hard limit.
- Model coverage: conveyor transfer, four-item storage linking, selected-item sorting, automatic smelting, refueling, enable/disable, recipe/filter cycling, status and demolition safety.
- Performance coverage: 128-machine placement cap, 64-operation advance budget and 720-tick offline catch-up bound with explicit throttled/discarded results.
- Runtime coverage: time-event advancement in an unloaded chunk, immutable views, stream metrics, control APIs and owning-chunk persistence.
- UI coverage: machine rows, limits, status, recipe/filter controls and four target resolutions from 1280×720 through 3440×1440.
- Persistence coverage: exact machine-state round trip, invalid field/reference rejection, chunk ownership and format-23 no-fabrication migration.
- Regression coverage: generation-v5 checksum and every prior inventory, processing, equipment, building, farming, husbandry, survival, quest, faction, event, cave, dungeon, combat and progression invariant remain valid.
