# V3.0.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (150 required files).
- Automated result: 883 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Catalog coverage: exact 24-template split, prerequisite graph, four random rules, board bounds and three key choices.
- Model coverage: deterministic region/day offers, generated completion/reward flow, bounded persistence and invalid-record rejection.
- Choice coverage: prerequisite availability, exact faction/progress effects, duplicate rejection, transactional rollback and round trip.
- Runtime coverage: board/day integration, journal categories, choice controls, selection feedback and full world-state ownership.
- Persistence coverage: generated definitions/boards/choices plus explicit save-format-2-through-16 migration.
- Regression coverage: generation-v5 checksum and every prior quest, faction, event and progression invariant remain valid.
