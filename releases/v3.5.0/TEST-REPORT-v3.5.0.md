# V3.5.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (175 required files).
- Automated result: 1,148 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: two processor stations, two fuels, ten recipes, exact multi-material inputs, outputs, fuel costs and canonical item references.
- Model coverage: station placement, capacity, fuel insertion, meal cooking, ore refining, retained fuel, completed counts, no-material rollback, demolition guard and strict round trip.
- Runtime coverage: placed cooking pot, manager fuel path, manager recipe path, output inventory, live state view and chunk-owned persistence snapshot.
- Survival coverage: meal attributes, recovery-only potion usefulness, directional temperature change and poison/frostbite/burning clearing.
- UI coverage: two station tabs, two fuel controls, six cooking/potion rows, four smelting rows and four target resolutions from 1280×720 through 3440×1440.
- Persistence coverage: exact processor fields in one surface difference, no player duplication, full reload and format-21 no-fabrication migration.
- Regression coverage: generation-v5 checksum and every prior inventory, building, farming, husbandry, survival, quest, faction, event, cave, dungeon, combat and progression invariant remain valid.
