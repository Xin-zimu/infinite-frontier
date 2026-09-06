# World Generation Contract

## Version

- Game version: `4.0.0`
- Generation version: `5`
- Chunk size: `32×32` world tiles
- Tile size: `32×32` display pixels

## Seed contract

Text is trimmed and encoded as UTF-8. The first eight bytes of SHA-256 are read in big-endian order with the sign bit cleared, producing a stable signed 63-bit value. Numeric text is preserved as a signed integer. The permanent fixture is:

```text
"无尽边境" -> 6266252184503203218
```

System seeds are derived from the world seed, domain name and generation version. Coordinate-local seeds additionally include world layer, signed chunk X/Y and generation type. No generated system consumes a shared global random stream.

## Coordinate contract

World tiles are integer coordinates. Chunk coordinates use mathematical floor division, and local coordinates use positive modulo:

```text
tile (-1, -1)   -> chunk (-1, -1), local (31, 31)
tile (-33, 64)  -> chunk (-2, 2),  local (31, 0)
```

A surface chunk key is formatted as `surface_<x>_<y>` with signs preserved.

## Layered field pipeline

The generator combines independently seeded FastNoiseLite fields:

| Field | Frequency | Octaves | Use |
|---|---:|---:|---:|
| Continentalness | 0.0045 | 3 | Large land and ocean masses; elevation weight 0.50 |
| Elevation | 0.0140 | 4 | Regional relief; elevation weight 0.32 |
| Erosion | 0.0075 | 3 | Flattens relief; inverse elevation weight 0.10 |
| Temperature | 0.0032 | 3 | Climate axis, reduced at high altitude |
| Moisture | 0.0042 | 3 | Climate axis, increased near oceanic continental values |
| Detail | 0.0550 | 2 | Local relief; elevation weight 0.08 |

Normalized elevation is classified using `data/biomes.json`: deep water below `0.275`, shallow water below `0.350`, coast below `0.420`, and land otherwise. An order-independent 3×3 global-neighbour pass replaces isolated outlier categories when at least six neighbours agree.

## Biome contract

Twelve stable byte codes represent deep ocean, ocean, coast, plains, forest, desert, snowfield, swamp, mountain, taiga, savanna and meadow. Land rules are evaluated by descending data-defined priority. Each rule may define temperature, moisture, elevation and erosion bounds, plus a transition target and band width. A second global-neighbour pass selects a five-of-nine local-biome majority where present, limiting isolated cells without reading adjacent chunk state.

The generation-v5 fixture for seed `无尽边境` and chunk `(-1,-4)` is `16cf513e93ddfbe3`. A 4,225-sample broad scan contains all twelve biomes. A 96×96 full-resolution continuity fixture has more than 90% matching orthogonal edges and at most four isolated cells.

## Resource generation contract

`data/resources.json` defines stable byte codes for tree, rock, grass, flower and berry bush surface resources plus coal, copper and iron cave veins; durability; required tools; spacing; collision behavior; and bounded drops. Deep and shallow water have no surface candidate rules, while cave veins have no surface biome weights.

The surface is divided into signed global 2×2-tile candidate cells. Each cell derives one stable hash from the world seed, signed cell coordinate and generation version. Hash fields determine the jittered tile, biome-weight roll, visual variant and conflict rank. A candidate is accepted only if no lower-ranked candidate lies closer than the larger of both resource spacing rules. The neighborhood is evaluated from global cells, so spacing is identical within chunks and across seams, including negative coordinates.

The generation-v5 25-chunk regression region contains all five surface resource types and 1,233 unique spawns. Pairwise spacing is checked across the complete region, including biome weights for taiga, savanna and meadow.

## Runtime enemy candidate contract

Enemy candidates use stable world-layer identities. Surface candidates hash world seed, signed chunk and slot, require land outside exact resources and select only `normal` definitions (slime, wolf, wild boar, frost sprite or ash-raider scout according to biome/phase). Underground candidates require a navigable cave floor without a vein/feature and select only cave bats. Dungeon candidates are the two elite and one Boss markers stored in its immutable feature map; resolved spawn IDs are filtered by `DungeonRunState`. The normal planner cache remains bounded to the current 49 preload chunks.

## Canonical ruin overlay contract

V1.0 derives one ruin from the world seed in a Chebyshev ring three to six chunks from the original spawn region. `RuinPlanner` ranks signed candidate chunks with a dedicated `ruin` domain, prefers configured desert/mountain/plains biomes and accepts only pure terrain samples classified as land. The same seed therefore yields the same ruin tile, biome and stable score.

The ruin is a landmark overlay rather than `ChunkData`: it does not modify terrain, biome, resource bytes, seams or the generation-v5 checksum. Its discover/defeat/reward changes live in milestone save schema 1.

## Data/render boundary

`TerrainGenerator.generate_chunk` and `CaveGenerator.generate_chunk` return pure `ChunkData`. Surface chunks contain the established terrain/climate/biome arrays; underground chunks add 1024 cave-cell and cave-feature bytes plus packed vein resources. `ChunkRenderer` consumes either layer on the main thread and writes 1024 base cells; `ResourceChunkLayer` and `CaveChunkLayer` batch resources, walls and features in shared atlases. Generation code never accesses the player, UI or scene tree.

The renderer cycles through ecological terrain, solid biome IDs, combined temperature/moisture climate and grayscale elevation views. Display mode never changes generated bytes or checksums.

## Player-building overlay (V3.2.0)

Player buildings are mutable world differences, never inputs to `TerrainGenerator`, `CaveGenerator` or any seed-derived planner. Every placement uses a stable `surface:<tile_x>:<tile_y>:<slot>` identity, with independent `ground`, `structure` and `roof` occupancy. Validation queries the already generated active surface chunk for water, resource and structure/village/road occupancy, then applies player distance and support rules without modifying that chunk's bytes.

`PlayerBuildingLayer` converts the owning chunk's saved placement records into three shared-atlas `TileMapLayer` batches. Rotation, door-open state, storage contents, workstation access and heat are mutable overlays; none enters `ChunkData` or the generation checksum. V3.2 therefore retains generation format 5 and the `16cf513e93ddfbe3` fixture while save format 19 groups placements into sparse surface chunk differences.

## Agriculture overlay (V3.3.0)

Tilled soil and crops are mutable surface differences keyed as `surface:<tile_x>:<tile_y>:farm`; they are never injected into `TerrainGenerator`, `ResourceGenerator` or `ChunkData`. Opening land validates the active generated tile for water, resources, structures, village roads and player-building occupancy, but does not rewrite any of those source bytes. Building placement performs the reciprocal farming-occupancy check.

Crop progress consumes saved in-game day boundaries plus the canonical weather ID. Rain supplies wet days, while dry, snow and sandstorm multipliers come from `data/farming.json`; bounded day catch-up operates only on the persisted plot records. Harvest quality hashes world seed, stable plot identity, crop ID and harvest count, then combines that stable roll with recorded care and fertilizer. Loading, renderer eviction or request order therefore cannot reroll growth or output.

`FarmingChunkLayer` renders tilled, watered, staged and mature cells from the owning chunk's difference records. The overlay preserves generation format 5 and the `16cf513e93ddfbe3` fixture; save format 20 alone changes to carry sparse `farming_plots` arrays.

## Husbandry overlay (V3.4.0)

Untouched wild animals are deterministic overlays, not `ChunkData`. `HusbandryPlanner` divides every signed surface chunk into global 16×16-tile cells, hashes world seed and cell coordinate, then resolves a stable identity, jittered tile, sex and biome-compatible chicken/cow/sheep type. Candidates on water, generated overlays or resources are rejected; planning reads no global random stream and is independent of chunk request order.

First feeding moves a candidate into `HusbandryState`. From then on its tile, taming progress, feed reserve, product count, breeding cooldown, sleep and offspring generation are mutable chunk-owned differences. Buildings and farms query both untouched candidates and interacted records, while animal rendering filters any deterministic candidate hidden by an existing mutable overlay. Game-day catch-up reads only persisted records and never wall-clock time.

`AnimalChunkLayer` batches simple wild, tamed, juvenile, sleeping and product-ready presentation for the owning active chunk. The overlay preserves generation format 5 and the `16cf513e93ddfbe3` fixture; save format 21 alone changes to carry sparse `husbandry_animals` arrays.

## Processing overlay (V3.5.0)

Cooking pots and smelters are player-authored `BuildingState` placements. Their atlas cells, heat-source role, fuel and completed-operation count are never sampled by `TerrainGenerator`, never enter `ChunkData` and never affect a generated checksum. The owning active `PlayerBuildingLayer` renders them from sparse surface differences.

Processing recipes consume only canonical inventory items and persisted station fuel. Their result is independent of chunk generation order and global random state. V3.5 therefore retains generation format 5 and the `16cf513e93ddfbe3` fixture; only save format 22 changes to extend processor placement records.

## Equipment overlay (V3.6.0)

Owned equipment, worn slots, quality, rarity, affixes, enhancement and durability are player-owned state. Their deterministic rolls depend only on stable equipment instance identity and the equipment catalog; they never read or rewrite terrain, resource, structure, village, cave or dungeon bytes.

Runtime attack, defense, health, stamina and set-bonus composition occurs after world content has been generated. V3.6 therefore retains generation format 5 and the `16cf513e93ddfbe3` fixture; only save format 23 changes to add player-owned equipment state.

## Automation overlay (V3.7.0)

Automation machines are player-authored `BuildingState` records. Logistics reads only saved structure positions, quarter-turn rotations, chest contents and machine configuration; it never samples or rewrites terrain, climate, biome, resource, structure, village, cave or dungeon generation bytes.

Unloaded-chunk work advances from persisted game seconds through bounded machine ticks rather than renderer lifetime or wall-clock time. Output remains an owning surface-chunk difference, and active `PlayerBuildingLayer` instances are refreshed only after a changed snapshot commits. V3.7 therefore retains generation format 5 and the `16cf513e93ddfbe3` fixture; only save format 24 changes to carry machine state in existing placement records.

## Homestead overlay (V4.0.0)

A homestead beacon is a player-authored `BuildingState` placement with the stable `surface:<tile_x>:<tile_y>:structure` identity. Its three-base cap, spacing and range are mutable-world validation rules; no beacon, base boundary or home selection enters `TerrainGenerator`, `ChunkData` or a seed-derived planner.

House, storage, farm, animal, processor, equipment-workstation and automation completion is computed from the current mutable overlay records inside each beacon radius. These counts and loop flags are views only and are never serialized as generated cells. V4.0 therefore retains generation format 5 and the `16cf513e93ddfbe3` fixture; only save format 25 changes to carry cross-validated base metadata and home travel time.

## V0.4 streaming contract

| State/range | Radius | Maximum square |
|---|---:|---:|
| Active renderers | 2 | 25 chunks |
| Preload targets | 3 | 49 chunks |
| Retained data cache | 4 | 81 chunks |

The manager prioritizes shorter Euclidean distance and applies a small bias in the player's movement direction. At most four jobs run concurrently. Workers build private generators and return `ChunkData`; only the main thread creates `ChunkRenderer` nodes. Each renderer stores 32×32 local cells and uses its node transform for world placement.
# Structure overlay (V1.4.0)

Surface structures are derived after generation-format-5 terrain and resource data. Each signed 192×192-tile region owns a stable candidate seed, template choice, anchor, rotation and mirror flag. A template may cross any chunk boundary; each chunk independently resolves the same instance and retains only cells inside its 32×32 bounds. This makes request order irrelevant and reconstructs the complete structure without seams.

Template glyphs separate floors, walls, doors, chests, enemy spawn points, altars, dungeon entrances and campfires. Interactive marker kinds are copied into `ChunkData`; walls are rendered through a shared collision-enabled `TileSet`. Base resources covered by structure cells remain part of the compatible generation checksum but are hidden and excluded from interaction.

## Villages and roads (V1.5.0)

Each signed 384×384-tile region has a stable village candidate, center and house count. Valid centers produce a plaza, well, campfire, shop, houses, NPC points and entrance markers. Entrance roads join the plaza; valid neighboring villages are joined by regional roads. Two orthogonal alternatives are scored using terrain, hydrology and elevation change, and selected water crossings become bridge cells. Every chunk independently clips the same global plan.

## Underground caves (V1.6.0)

Each signed 4×4-chunk surface region owns one seed-ranked dry-land entrance. Surface entrances are derived overlays and are deliberately excluded from the generation-v5 surface checksum. Underground chunks use the same signed X/Y coordinate plane, so an entrance and exit share one exact world tile.

The cave generator initializes a signed-coordinate wall field, then runs five cellular-automata smoothing passes over a halo wider than the iteration count. The 32×32 center is cropped after smoothing. A minimum floor ratio is enforced, every disconnected floor component is joined to the center, and three-cell gates at each edge midpoint connect adjacent chunks. These repairs make the result navigable without reading a neighboring chunk object or depending on request order.

Coal, copper and iron veins are placed only on floor cells through stable coarse-cell hashes. Fixed torches, treasure chests and aligned exits occupy the separate cave feature map. Chest contents are derived from their layer-qualified coordinate key; opening state is a save difference, not a change to generated bytes. Cave walls render with World-layer collision, while the active stream drains pending jobs before changing layers so surface and underground results never share a cache identity.

## Procedural dungeons (V1.7.0)

Every surface structure marker of kind `DUNGEON_ENTRANCE` derives `dungeon_<tile_x>_<tile_y>`. The entrance chunk becomes the finite dungeon anchor, but its room map uses 32×32 local cells independently of surface terrain. The same world seed, dungeon ID and anchor always reproduce the same checksum and feature coordinates.

Six bounded slots in a 3×2 grid receive deterministic room widths, heights and offsets. A stable nearest-room sequence begins at the entry room and reserves the final room for the Boss. Five orthogonal corridors connect consecutive centers; tests verify every path step is Manhattan-adjacent and every floor byte belongs to one connected component. Chunks other than the anchor contain 1024 wall cells, preventing traversal outside the finite map.

The separate feature map contains exactly one exit, two locked doors, two keys, four traps, two chests, two elite spawns and one Boss spawn. Feature keys combine dungeon ID, feature kind and signed world tile. The generator never reads mutable progress: `DungeonRunState` hides resolved features at render/spawn time. Chest loot uses stable feature-key hashes, while an incomplete-exit reset or completed-run persistence changes only save data. Dungeon derivation therefore leaves generation-format-5 surface terrain, resources and checksum fixtures unchanged.

## Exploration and regional Boss overlays (V2.0.0)

`WorldDiscoveryScanner` derives markers for villages, structures, the canonical ruin, caves, dungeons and regional Bosses only after the owning surface chunk enters discovered fog. Marker positions are never injected into `ChunkData`; the save stores discovery and player-authored state, not generated layout tiles.

`RegionalBossPlanner` derives exactly three encounters from independent ID-specific hashes. The grove, dune and frost encounters scan non-overlapping Chebyshev rings, prefer their configured biomes and accept only dry land. Their stable `regional_boss:<id>` spawn IDs reuse the enemy state machine, while `RegionalBossState` permanently filters defeated encounters from later population passes.

Generation format 5 intentionally changes the V1.7 surface fixture because biome classification and every generation-version-derived domain now use the twelve-biome catalog. Format-9/generation-4 saves are accepted by the migration layer; permanent resource/chest differences retain signed coordinate keys, then the next save commits current generation metadata.

## NPC overlays (V2.1.0)

`NpcPlanner` combines the seed-derived village layout with six data-driven roles. Each NPC ID is `village:<region_x>:<region_y>:npc:<index>`; its name, home and service role remain stable across sessions. Elder, merchant and innkeeper receive deterministic plaza fallbacks if terrain rejected their intended house, so required services never depend on an invalid building placement.

NPC path cells reuse the derived village road/building overlay and are resolved by bounded cardinal A*. Schedule targets and active actors are runtime state; only interaction/trade counters persist. NPCs therefore do not alter `ChunkData`, generation-format-5 checksums or sparse chunk differences.

## Relationship overlays (V2.2.0)

NPC and village IDs from the deterministic planner key all relationship progress. Affection, last-gift day, claimed rewards and village reputation are player-owned differences; gift preferences, attitude tiers and price multipliers are catalog data. None changes terrain, village layout, NPC identity or the generation-format-5 checksum.

## Quest overlays (V2.3.0)

Quest objectives reference canonical item IDs, enemy IDs, discovered marker types and NPC role IDs. Accepted status and counters are player-owned progression; quest definitions and prerequisite graphs are external data. Tasks never add generated tiles or change seed-derived identities, so generation format remains 5.

## Faction overlays (V2.4.0)

Faction definitions map deterministic NPC roles and canonical enemy IDs to four political identities. Standing, one-time discovery credit, event history and village control ownership are player-owned differences keyed by stable IDs. The ash-raider scout is selected by the existing normal enemy candidate hash on eligible land biomes; no terrain, resource, structure or village bytes change. Factions therefore retain generation format 5 and the canonical V2.0 terrain checksum.
