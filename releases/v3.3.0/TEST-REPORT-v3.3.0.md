# V3.3.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (165 required files).
- Automated result: 1,041 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: four crop IDs, one fertilizer, weather modifiers, stage/yield/regrowth bounds and every canonical seed/quality output.
- Model coverage: till rejection, exact seed/fertilizer transactions, watering, rain/dry/snow/sand growth, stages, maturity, deterministic quality, annual clearing, fruit-tree regrowth and strict round trip.
- Renderer coverage: tilled, watered, growing and mature batches plus stable active-chunk counts.
- Runtime coverage: valid tile discovery, contextual action cycle, reciprocal building collision, exact inputs, weather/day maturation, owning-chunk refresh, harvest conservation and shared persistence/metric counts.
- UI coverage: four crop rows, capacity/target/weather state, minimum 1280×720 containment and 1920×1080/2560×1440/3440×1440 responsive containment.
- Persistence coverage: farming-only chunk creation, no player-document duplication, exact reload, stale-file deletion/recreation, format-19 empty migration and current-format corruption rejection.
- Regression coverage: generation-v5 checksum plus every prior inventory, building, survival, quest, faction, event, cave, dungeon and progression invariant remain valid.
