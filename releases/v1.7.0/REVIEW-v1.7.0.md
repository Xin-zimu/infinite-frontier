# V1.7.0 review

Status: PASS

- A surface entrance derives one stable dungeon ID, anchor chunk, entry tile and exact surface return position.
- Six non-overlapping procedural rooms are joined by five contiguous orthogonal corridors; every floor tile is reachable.
- Every generated dungeon contains exactly two locks, two keys, four traps, two chests, two elite markers and one final Boss marker.
- Neighbor chunks are sealed walls, making the dungeon finite without sharing scene-tree state with generation workers.
- Keys consume once, locks lose collision only after unlock, traps damage once per attempt and full-inventory chests remain unopened atomically.
- Elite and Boss candidates are dungeon-only and use stable spawn IDs; Boss defeat permanently completes the run.
- Incomplete exit clears transient feature/enemy progress before the next numbered attempt; completed exit and re-entry preserve it.
- Graves use the dungeon ID as their layer scope, preventing identical coordinates from leaking between different dungeons.
- Save format 9 round-trips an active dungeon and rejects a layer/current-dungeon mismatch; format 8 initializes an empty dungeon state.
- Generation format 4 and checksum `25b17b18822faa6c` remain compatible for the established surface fixture.
