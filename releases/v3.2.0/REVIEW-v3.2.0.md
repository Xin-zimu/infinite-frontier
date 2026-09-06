# V3.2.0 review

Status: PASS

- The building catalog validates all nine required stable IDs, canonical item costs, three slots, interaction metadata and bounded limits.
- `BuildingState` is scene-free; preview does not mutate state, and placement/demolition/storage operations use inventory simulation before commit.
- Water, player occupancy, active resources, generated overlays, duplicate layers, missing floors, missing door adjacency, range and global capacity all reject with no material loss.
- Stable IDs derive from signed tile coordinates and occupancy slots; duplicate records, unsupported upper layers and invalid door/storage metadata reject persistence.
- `PlayerBuildingLayer` batches ground, structure and roof cells and uses an explicit collision-free atlas variant for open doors.
- Runtime placement refreshes only the owning active chunk, while nearby station and heat views feed existing crafting, lighting and survival consumers.
- Format-19 placements exist only in surface chunk differences; underground placement arrays are rejected and `player.json` contains no duplicate building state.
- The save worker deletes difference files absent from the complete retained set, preventing a demolished building-only chunk from returning after load.
- Format-18 migration preserves prior state and initializes no fabricated player structures.
