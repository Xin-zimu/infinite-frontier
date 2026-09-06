# V1.6.0 review

Status: PASS

- Surface entrance and underground exit resolve to the same signed world tile and round-trip through normal `E` interaction.
- Cellular smoothing uses a deterministic halo; minimum-floor and component-repair passes leave every floor cell reachable.
- Mid-edge gates reconstruct traversable links on both sides of adjacent chunk seams.
- Coal, copper and iron veins use the existing harvest, durability, drop-pool and inventory conservation paths.
- Cave bats are filtered to the underground layer and never appear in the surface candidate scan.
- Underground chests reject a full inventory atomically and store one layer-qualified opened key only after loot transfer succeeds.
- Cave walls use a shared collision-enabled TileMap atlas; static and handheld torches drive the underground lighting mask.
- Graves retain their surface/underground layer, and death below ground returns the player to the established surface respawn without exposing that grave above ground.
- Surface ruin/Boss simulation and weather modifiers are isolated from the underground layer.
- Layer changes drain pending workers before resetting the bounded cache, preventing surface/underground result aliasing.
- Save format 8 separates surface and underground difference directories and backups both, and rejects mismatched player/metadata layer state.
- Generation format 4 and checksum `25b17b18822faa6c` remain compatible for the established surface fixture.
