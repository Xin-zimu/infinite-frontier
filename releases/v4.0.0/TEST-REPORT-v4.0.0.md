# V4.0.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (187 required files).
- Automated result: 1,285 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: beacon identity, three-base cap, 24-tile radius, 32-tile spacing, names and 120-second cooldown.
- Model coverage: marker synchronization, nearest-base assignment, active-home repair, eight-step composition, persistence validation and tamper rejection.
- Runtime coverage: atomic beacon placement/removal, surface relocation, underground-to-surface travel, cooldown commit ordering, metrics and owning-chunk persistence.
- UI coverage: base rows, limits, asset summaries, loop progress, home controls and four target resolutions from 1280×720 through 3440×1440.
- Persistence coverage: format-25 round trip, player/chunk single ownership, stale difference cleanup and format-24 no-fabrication migration.
- Regression coverage: generation-v5 checksum and every prior survival, inventory, production, equipment, automation, farming, husbandry, quest, faction, event, dungeon, combat and progression invariant remain valid.
