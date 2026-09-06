# V1.7.0 changelog

- Added deterministic six-room procedural dungeons behind existing surface dungeon-entrance markers.
- Added connected corridors, two locked doors, two keys, four one-shot traps and two atomic-loot chests.
- Added two elite sentinels and a final dungeon warden Boss with a stable relic reward.
- Added collision-enabled dungeon walls/doors, dedicated feature rendering, persistent darkness and a dungeon objective HUD.
- Added attempt state: leaving an incomplete dungeon resets transient progress, while Boss completion and resolved features persist.
- Added dungeon-qualified graves and isolated surface/cave/dungeon simulation contexts.
- Advanced save format to 9 for active dungeon identity, anchor, return point, attempts and resolved feature/enemy state.
- Added explicit format-8 migration while preserving generation format 4 and the canonical surface checksum.
