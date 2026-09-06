# V2.4.0 test report

Status: PASS

- Engine: Godot 4.7.1 stable, Linux x86_64 headless.
- Structural verification: PASS (138 required files).
- Automated result: 794 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: PASS.
- Model coverage: four required factions, five tier boundaries, role/enemy ownership, pairwise symmetry, event actions, shop gates, discounts, control contests and invalid-state rejection.
- Runtime coverage: NPC trade standing, quest standing, faction-panel layout, faction-shop settlement and manager persistence.
- Persistence coverage: exact standing/discovery/event/control-point round trip plus explicit save-format-2-through-13 migration.
- Transaction coverage: faction purchases settle currency, stock and standing together only after the complete output fits.
- Font coverage: every V2.4 faction and interface glyph exists in the bundled offline CJK font.
