# V3.2.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (160 required files).
- Automated result: 970 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: nine stable blueprint IDs, costs, collision/support metadata, limits, refund ratio, storage and proximity settings.
- Model coverage: preview rejection, layered placement, exact material transactions, rotation, door state, storage transfer, workstation/heat queries, demolition and strict round trip.
- Renderer coverage: three placement batches, visible/solid counts, collision-enabled wall and collision-free open-door atlas variant.
- Runtime coverage: legal-tile discovery, exact floor/wall costs, owning-chunk refresh, demolition refund, consumed placed workbench availability, campfire heat and shared persistence/metric counts.
- UI coverage: nine blueprint rows, capacity/preview state, minimum 1280×720 containment and 1920×1080/2560×1440/3440×1440 responsive containment.
- Persistence coverage: building-only chunk creation, no player-document duplication, exact reload, stale-file deletion/recreation, format-18 empty migration and current-format corruption rejection.
- Regression coverage: generation-v5 checksum plus every prior inventory, survival, quest, faction, event, cave, dungeon and progression invariant remain valid.
