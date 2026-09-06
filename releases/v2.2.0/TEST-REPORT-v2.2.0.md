# V2.2.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (130 required files).
- Automated result: 736 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Model coverage: catalog bounds, tiers, preferences, price math, daily limits, threshold rewards and invalid-state rejection.
- Runtime coverage: trade relationship gains, preferred gift transfer, repeated-gift refusal, relationship UI and off-layer NPC release.
- Persistence coverage: exact relationship round trip plus explicit save-format-2-through-11 migration.
- Transaction coverage: buy/sell settlement and gift/reward rollback preserve inventory and progression on failure.
