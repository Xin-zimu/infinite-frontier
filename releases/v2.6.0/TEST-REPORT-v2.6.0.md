# V2.6.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (148 required files).
- Automated result: 862 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Model coverage: region partition, five danger tiers, enemy ranges, deterministic elite scaling, equipment composition, source deduplication, Boss gates, rewards and persistence rejection paths.
- Runtime coverage: current-region discovery, equipment refresh, forced elite combat/credit, reward button, tracker/window layout and save snapshot ownership.
- Persistence coverage: exact source/region/reward round trip, point-tamper rejection, atomic reward rollback and explicit save-format-2-through-15 migration.
- Regression coverage: generation-v5 checksum, events, factions, quests, NPCs, exploration, dungeons and all prior save formats remain valid.
