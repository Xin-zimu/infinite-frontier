# V2.5.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (143 required files).
- Automated result: 823 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Model coverage: exact eight-event catalog, deterministic full-cycle scheduling, boundary activation, target anchoring, progress, effects, expiration, persistence and bounded large-time skips.
- Runtime coverage: resource modifiers, village-raid encounters, temporary Boss encounter, blizzard override, progress completion, tracker and timetable layout.
- Persistence coverage: exact active/history/cursor round trip, numeric normalization, duplicate rejection and explicit save-format-2-through-14 migration.
- Regression coverage: generation-v5 checksum, prior exploration/NPC/relationship/quest/faction systems and all existing save formats remain valid.
