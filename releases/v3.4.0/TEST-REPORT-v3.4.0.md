# V3.4.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (171 required files).
- Automated result: 1,102 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: chicken/cow/sheep IDs, biomes, feeds, tame/breed/adult/cooldown values, products, sleep phase and every bounded limit.
- Model coverage: deterministic planning, dry/unique tiles, exact daily feed, duplicate-day rollback, taming, partner selection, sleep/wake, fenced breeding, juvenile adulthood, inactive-day production, collection and strict round trip.
- Renderer coverage: simultaneous wild/tamed records plus product-ready and sleeping counts.
- Runtime coverage: natural candidate discovery, feed/collection sequencing, reciprocal building/farm collision, partner restoration validation, fence placement, breeding, day/phase events, owning-renderer refresh and shared metrics.
- UI coverage: three species rows, capacity/product/sleep/simulation state, minimum 1280×720 containment and 1920×1080/2560×1440/3440×1440 responsive containment.
- Persistence coverage: husbandry-only chunk creation, no player-document duplication, exact reload, stale-file deletion/recreation, format-20 empty migration and current-format corruption rejection.
- Regression coverage: generation-v5 checksum plus every prior inventory, building, farming, survival, quest, faction, event, cave, dungeon, combat and progression invariant remain valid.
