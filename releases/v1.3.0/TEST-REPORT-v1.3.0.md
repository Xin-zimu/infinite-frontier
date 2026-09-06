# V1.3.0 test report

Status: TEST PASS / WINDOWS EXPORT BLOCKED

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Baseline: V1.2.0 passed 454/454 before implementation.
- V1.3 coverage: deterministic signed-coordinate hydrology, all planned surface feature families, movement multipliers and 32×32 chunk feature data.
- Final automated result: 462 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Windows export: BLOCKED because the local Godot runtime does not include `4.7.1.stable/windows_release_x86_64.exe`; no source or test failure was reported.
