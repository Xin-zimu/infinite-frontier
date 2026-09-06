# V2.0.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (119 required files).
- Automated result: 682 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Exploration coverage: bounded fog reveal, marker visibility/invariants, custom marker IDs/cap, completion, travel eligibility and exact persistence round trip.
- Regional-Boss coverage: catalog roles, deterministic ring planning, dry-land/biome validation, stable spawn identity, one-time completion and reward IDs.
- Runtime coverage: initial discovery, safe-camp registration, custom marker creation, fast travel, Boss-map completion and responsive map UI.
- Persistence coverage: current format validation, exploration/Boss round trip and explicit save-format-2-through-9 migration including generation 4 to 5.
- Font coverage: every V2.0 map, biome, enemy and Boss UI glyph is present in the bundled offline subset.
