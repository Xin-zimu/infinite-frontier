# V1.4.0 review

Status: PASS

- Five required template families load from validated external data.
- Rotation and mirroring preserve exact cell and marker counts.
- Cross-chunk clipping reconstructs one instance without missing or duplicated cells.
- Structure walls own collision polygons and template cells are rendered in a single TileMap layer per chunk.
- Covered resources are neither drawn nor offered as interaction targets.
- Save format 7, generation format 4 and the V1.3 base checksum remain compatible.
