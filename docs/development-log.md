# Development Log

## V1.2.0 - Regional weather

- Added validated weather definitions for clear skies, rain, snow and sandstorms with ecological biome weights.
- Added deterministic 6×6-chunk weather regions, bounded durations and smooth eight-second transitions.
- Added screen-space rain/snow/sand presentation and deterministic offline synthesized ambience.
- Applied weather multipliers only at canonical resource-drop resolution and enemy population-cap calculation.
- Advanced save format to 7 with exact current/target/region/segment/timer persistence and format-2-through-6 migration.
- Added HUD weather status, runtime integration checks and visual evidence for all four weather states.

### Decisions

- Weather is a regional runtime layer and does not modify generation-format-4 terrain or resource keys.
- Save loading does not simulate offline weather progress; it resumes the exact saved transition state.
- Weather audio is synthesized locally and releases its playback stream during scene shutdown.
- Numeric boundaries crossing packed Godot values are explicitly normalized to avoid Godot 4.7.1 runtime type instability.

## V1.1.0 - Complete day/night and lighting

- Replaced the 300-second two-state prototype with a validated external four-phase, 1,200-second cycle.
- Added smooth phase-edge color blending, persistent phase/day HUD state and a screen-space torch light that follows the player.
- Added phase-aware enemy candidates, a 27-enemy night cap and night-only moonflowers dropping moonpetals.
- Preserved save format 6 and generation format 4: time already persists as seconds and existing resource coordinates/keys are unchanged.
- Replaced runtime biome-rule Dictionary reads with typed scalar `BiomeRule` instances after repeated stress runs reproduced Godot COW memory corruption.
- Captured and visually reviewed dawn, day, dusk, night and torch-at-night frames using Godot 4.7.1.

### Decisions

- The existing stable `flower` resource code is presented as a moonflower and gated by phase, so V1.0.1 resource keys and collected-state compatibility remain intact.
- Offline elapsed time is intentionally ignored; loading resumes the exact saved world time.
- Texture filtering remains nearest; lighting is applied by a canvas shader without blurring world pixels.

## V1.0.0 - First complete playable build

- Added a basic 300-second day/night clock driven by persisted world time and a presentation-only night overlay.
- Added validated milestone data for a deterministic canonical ruin, a small ruin guardian and the ancient-core reward.
- Added a bounded-ring ruin planner that queries land/biome fields without changing generation-v4 `ChunkData` bytes.
- Added guardian chase and telegraphed slam combat, one terminal defeat event and a retry-safe one-time reward interaction.
- Added ordered milestone state, direction/distance guidance and a compact day/objective/Boss HUD.
- Added locally synthesized PCM cues for attacks, blocked actions, success, Boss events and milestone completion.
- Advanced save format to 6 with explicit format-2/3/4/5 migration while preserving generation format 4.
- Removed training fixtures from normal world startup because real procedural enemies and the ruin guardian now validate combat.
- Expanded the suite from 377 to 409 checks before final font, documentation, visual and build gates.

### Iteration findings

- Generating complete chunks for every ruin-search candidate made repeated scene startup unnecessarily expensive. The planner now samples nine pure terrain points per candidate and reserves full chunk generation for normal streaming.
- A deterministic landmark must not silently invalidate a stable terrain world. The ruin is a separately versioned overlay, so the generation-v4 checksum and old world coordinates remain unchanged.
- Marking the Boss defeated before a full-inventory reward transfer could permanently lose progression. The claim transition commits only after the canonical inventory accepts the complete one-item reward.
- A discoverable landmark several chunks away needs actionable guidance. The milestone snapshot now exposes coarse direction and distance without serializing player-relative data.

### Decisions

- V1.0 implements only the plan's basic day/night split; dawn, dusk, complete lighting, night enemies and night resources remain V1.1.
- The single ruin is canonical per seed and lies three to six chunks from the original spawn region.
- `game_time_seconds` remains the sole clock persistence field; milestone state receives schema 1 under save format 6.
- Basic sound is generated at runtime from bounded PCM samples, keeping the release fully local and license-simple.
- V1.0 runtime/data/test text expands the project font to 536 required characters with zero missing glyphs.

## V0.11.0 - Basic enemies

- Added validated data definitions for slimes, wolves and cave bats with biome, movement, combat and drop rules.
- Added the common idle/wander/alert/chase/attack/hurt/return/dead state machine and three presentation profiles.
- Added deterministic signed-chunk spawn candidates that reject water, resource candidates and unsupported biomes.
- Added screen-exclusion spawn checks, an 18-enemy hard cap, per-chunk cap, distance sleep, despawn and respawn cooldown.
- Added collision-aware pursuit/return movement and stable tangent selection when solid world geometry blocks a route.
- Connected enemy attacks to player invulnerability/death and player `Area2D` attacks to enemy defense, knockback and death.
- Added deterministic pooled drops for three new canonical item IDs and a bounded enemy diagnostic HUD.
- Preserved save format 5 and generation format 4; expanded the suite from 332 to 377 checks before final documentation/build gates.

### Iteration findings

- A short wall test initially classified legitimate end-running as wall penetration. The collision fixture was extended so the gate measures polygon crossing rather than successful obstacle avoidance.
- A hard active-node cap alone does not bound memory in an infinite world if the deterministic candidate cache remembers every visited chunk. The planner now retains only the current 49-chunk preload square.
- A radial spawn threshold does not fully guarantee off-screen placement near viewport corners. The director checks the camera canvas transform against the full viewport plus a 96-pixel margin in addition to the 760-pixel radius.
- Far entities must skip the state-machine tick itself, not merely set velocity to zero; the runtime counter test confirms sleeping enemies perform no complex transitions.
- V0.11 labels and new item names expanded the source/data/test font set to 496 visible characters with zero missing glyphs.

### Decisions

- Cave bats use mountain surface candidates until the planned underground layer exists; their stable ID and behavior remain ready for a later cave biome mapping.
- Enemy candidates are reproducible runtime content but are excluded from `ChunkData`, so generation format 4 and its checksum fixture stay immutable.
- Active enemy AI and respawn timers are session state. Only drops accepted into the inventory persist through the existing format-5 save contract.
- All three movement profiles collide with the World layer, including bats, to satisfy the V0.11 no-wall-persistence gate before richer navigation arrives.

## V0.10.0 - Player combat

- Added data-driven unarmed, wooden-sword and stone-sword definitions with damage, speed, range, knockback, stamina and combos.
- Added normal attacks, three-step combo timing, cooldown rejection and direction-following short-lived `Area2D` hitboxes.
- Added a per-attack target registry, defense-coefficient damage, directional knockback and one durability cost per accepted swing.
- Added player hit/roll invulnerability, death counting, safe-position respawn and respawn protection.
- Added persistent multi-grave inventory deposit/reclaim with exact damaged-tool preservation.
- Added a training target, controlled damage hazard and combat HUD for weapon, combo, cooldown, grave and feedback state.
- Advanced save format to 5 with explicit format-2, format-3 and format-4 migrations; generation remains format 4.
- Expanded the suite from 281 to 332 passing checks, including real hitbox-controller and sword-durability integration.

### Iteration findings

- `Area2D` can report a body through both `body_entered` and overlap polling during one active window. An attack-ID-local target set now rejects the second callback before target code runs.
- Charging durability inside the per-target loop could consume multiple points on a wide swing. The controller records a per-swing durability flag and charges only the first accepted contact.
- Saving a raw list of dropped stacks would lose ordered-slot validation and worn-tool values. Every grave stores a complete inventory-schema-2 snapshot and reclaims through canonical add rules.
- V0.9 migration must preserve crafting discoveries while adding combat fields. Format-specific initialization now adds crafting only below format 4 and combat/graves only below format 5.
- V0.10 combat labels introduced 19 Chinese characters absent from the prior subset. The rebuilt font contains all 458 required glyphs with zero missing.

### Decisions

- Enemy AI and procedural enemy spawning remain V0.11; V0.10 uses explicit training fixtures to exercise the complete player-side pipeline.
- Attack collision uses geometry and player facing, never center-distance-only damage checks.
- A lethal hit deposits inventory before immediate safe respawn, avoiding an externally visible dead-save race.
- Multiple graves are retained so dying again before recovery cannot overwrite an earlier inventory snapshot.

## V0.9.0 - Tools and crafting

- Added a validated recipe catalog with hands, workbench and campfire stations and ten progression recipes.
- Added discovery unlocks, station-gated recipe views and a dedicated keyboard-accessible crafting panel.
- Implemented atomic simulation-and-commit crafting so every rejection preserves exact material counts.
- Added wooden and stone axes, pickaxes and swords, workbench, campfire, torch and cooked berries.
- Added per-instance durability through inventory, hotbar, sort, discard, pooled pickup and disk persistence.
- Applied equipped tool type and power to harvesting; broken tools are removed immediately after an accepted hit.
- Advanced save format to 4 and inventory schema to 2 with explicit format-2 and format-3 migrations.
- Expanded the suite from 227 to 281 passing checks, including crafting transactions, speed, breakage, durability transfer and disk restoration.

### Iteration findings

- A capacity check based only on current free slots can reject or corrupt recipes whose inputs free the needed output slot. Crafting now clones the inventory, performs the exact deductions and output insertion, then commits only the successful result.
- Stack-only slot data cannot represent two copies of the same tool at different wear levels. Durable items therefore use stack size one and retain their own durability value across every movement path.
- Function closures created inside recipe-row loops can capture changing loop state. Button handlers now bind immutable recipe IDs at construction time.
- The expanded Chinese crafting vocabulary exceeded the previous runtime font subset. The subset was regenerated from current sources and data, producing 439 required glyphs with zero missing.

### Decisions

- Unlock state records discovered stable item IDs rather than derived recipe booleans, so future recipe balancing cannot silently rewrite player discovery history.
- Possessing a workbench or campfire enables its recipes in V0.9; placement and proximity belong to the later building stage.
- Wooden/stone swords are fully craftable durable inventory items, while attack behavior begins in V0.10 rather than being pre-implemented here.
- Cooked berries are a valid basic-food output; consumption and hunger effects remain the survival-system stage.

## V0.8.0 - Items and inventory

- Added canonical item resources with stable IDs, categories, colors and stack limits.
- Replaced bridge counts with a pure 24-slot model and eight-slot hotbar projection.
- Added conservation-tested add, drag swap/combine, half split, exact discard and category sort operations.
- Added the inventory window, hotbar, selection details and gameplay input integration.
- Changed ground-drop pickup to an accepted-quantity transfer so full inventories leave remainders in place.
- Advanced save format to 3 with normalized ordered-slot snapshots and explicit format-2 migration.
- Expanded the suite from 177 to 227 passing tests, including checksum identity, overflow, migration and UI containment gates.

### Iteration findings

- JSON numbers parse as floating-point Variants. Schema validation alone was insufficient for strict dictionary equality, so load now reconstructs the inventory through `InventoryModel` and exposes an integer-normalized snapshot.
- Deactivating a pooled drop before capacity validation can lose an overflow remainder. The pool now asks a receiver for the accepted quantity and decrements only that amount.
- Duplicating item display data between resource and inventory catalogs risks diverging IDs. `data/items.json` is now canonical and the resource catalog delegates item lookups.

### Decisions

- Slots are ordered and persisted exactly because user hotbar organization is gameplay state.
- The hotbar is a view of slots 0–7, not a second inventory, eliminating cross-container duplication paths.
- Sorting consolidates by stable item ID and category order while proving total conservation in tests.
- V0.8 introduces no recipes, workstations, durability-bearing tools or crafting unlocks; those remain V0.9 scope.

## V0.7.0 - Basic saves and chunk differences

- Added a world-creation overlay with world name and stable text/numeric seed input.
- Added versioned world metadata, player state and sparse surface-chunk difference files.
- Restored signed player position, health, stamina, selected tool, pickup counts and removed resource keys.
- Added 30-second autosave, `Ctrl+S`, return-to-menu and window-close save triggers.
- Added worker-thread writes, atomic temporary/previous transactions, five backups and shutdown task joins.
- Added file/line-specific corruption errors and exact save/generation compatibility checks.
- Added a normative save-format document and a headless difference-state visual.
- Expanded the suite from 148 to 177 passing tests, including empty-world sparsity, exact restore, backup, corruption and dispatch-latency gates.

### Iteration findings

- Godot's warnings-as-errors rejects a local inferred from `Dictionary.get` as Variant; persistence restore values now use explicit `Variant` annotations before shape checks.
- `PackedStringArray` has no `pop_front`; backup pruning copies directory names into a typed `Array[String]` before removing the oldest entry.
- Arbitrary Variant values should not be passed through the `String` constructor during schema validation; `str()` is used only for required non-empty metadata checks.
- A scene compilation failure can leave a prior cached script usable long enough for later assertions to run. The error-aware shell gate correctly rejected that run despite a zero-failure assertion summary.

### Decisions

- V0.7 uses readable JSON for small metadata/player/difference documents; the sparse data model matters more than premature database complexity.
- Save version advances to 2 while generation remains 4 because persistence changed without changing base world bytes.
- The main thread captures state and dispatches; file I/O, transaction replacement and backups run in a worker job.
- Corrupt or incompatible worlds never fall back to a new world automatically.
- The first project stage (V0.1–V0.7) now closes with engineering foundation, movement, deterministic infinite terrain, biomes, resources, interaction and persistence all independently releasable.

## V0.6.0 - Resources and interaction

- Added a validated JSON catalog for five resource nodes, three tools and five item drops.
- Added deterministic global candidate cells with biome weights and pairwise minimum spacing across chunk borders.
- Packed resource codes, local coordinates and variants into worker-safe `ChunkData`; advanced generation format to 4.
- Added a shared resource atlas, physical collision for solid nodes and a temporary hit-highlight row.
- Added nearest-resource prompts, strict tool checks, durability, correct deterministic drops and automatic pickup.
- Added a fixed 32-object drop pool and shared harvest-difference state that prevents duplicate drops after chunk reload.
- Added a dedicated resource/tool/inventory HUD and exact-data resource distribution map.
- Expanded the suite from 99 to 148 passing tests, including water exclusion, five-type coverage, cross-chunk spacing, collision, durability, duplicate-drop and pool-capacity gates.

### Iteration findings

- `TileData` does not expose physics layers until its atlas source has been registered with the owning `TileSet`; source registration now precedes collision polygon creation.
- Godot can exit zero after a failed custom assertion summary. The shell gate now also parses the final `passed/failed` line and rejects any non-zero failure count.
- Advancing the generation format changes domain-derived terrain fields as well as resource bytes, so the V0.6 exact checksum fixture and nearby start-region coverage gate were refreshed together.
- A real X11 gameplay frame remains unavailable in this sandbox. Visual QA uses the same generated `ChunkData` rendered into a 6×6-chunk resource map, plus scene smoke, collision and UI containment tests.

### Decisions

- Resource candidate selection compares stable global ranks, never a shared random sequence or generation order.
- Solid resource collision is batched in one `TileMapLayer` per chunk; drop objects are the only pooled per-object visuals.
- The harvest state stores differences rather than rewriting generated chunks. V0.7 will serialize this state without changing V0.6 generation ownership.
- Building entrances do not exist yet, so the applicable exclusion gate is all deep and shallow water; later structure versions add entrance exclusion zones.

## V0.5.0 - Layered terrain and ecological biomes

- Added independent continentalness, elevation, erosion, temperature, moisture and detail fields.
- Added a validated external biome catalog with nine stable IDs and configurable colors, thresholds, priorities and transition bands.
- Added six land biomes plus coast, ocean and deep ocean to every streamed chunk.
- Expanded `ChunkData` with five new field maps and a biome map; advanced generation format to 3.
- Added terrain, biome, climate and elevation renderer modes and live current-cell diagnostics.
- Added a deterministic headless biome-map renderer for release evidence.
- Expanded the suite from 58 to 99 passing tests, including broad biome coverage, continuity, seams and HUD containment.

### Iteration findings

- `PackedStringArray([...])` is not a valid GDScript constant expression; the stable required-ID list now uses an array literal.
- The original V0.3 showcase coordinate no longer contains all four base terrain categories after the multi-field generation upgrade, so the obsolete single-chunk assertion was replaced by broad coverage and continuity gates.
- The bundled font lacked the new Chinese biome and climate glyphs; the subset was rebuilt from all runtime source strings and reimported before release.
- A real X11 window cannot be opened in the current sandbox because local display sockets are blocked. The new feature was visually verified through a headless, exact-data biome map; HUD layout is covered by containment tests and both scenes pass runtime smoke tests.

### Decisions

- Biome configuration is shipped as JSON and explicitly included in exports.
- Transition bands route threshold edges through configured neighbor biomes before global-neighbour cleanup.
- The release map uses the same `TerrainGenerator.biome_at` path as streamed chunks, not a separate visualization approximation.
- Resource nodes, collection and persistent modifications remain V0.6.0 and V0.7.0 work.

## V0.4.0 - Infinite chunk streaming

- Added active, preload and retention radii of 2, 3 and 4 chunks.
- Added a distance-sorted queue biased toward the player's current movement direction.
- Added four concurrent WorkerThreadPool jobs with mandatory completion joins.
- Added main-thread renderer activation/removal, shared TileSet reuse and bounded local TileMap coordinates.
- Added current/peak cache, queue, worker and memory metrics plus visible boundary debugging.
- Added 1,800-step retention simulation, seam-coordinate/global-field checks, return consistency and worker-ID tests.
- Captured an actual fully warmed 25-active/24-preloaded frame spanning chunk boundaries.

### Iteration findings

- A statically impossible `ChunkData is Node` test was rejected by the GDScript compiler; the test now checks absence of scene-tree APIs.
- `Array.pop_front()` returns Variant, and warning-as-error required an explicit `Vector2i` annotation.
- The expanded font had not been reimported before the first capture, producing missing-glyph boxes despite a correct cmap.
- A TileMap batch covered the first custom boundary draw, so boundaries moved to an independent `Line2D` child layer.
- `PixelCamera._ready()` overwrote pre-tree unbounded zoom configuration; removing that override exposed adjacent chunks correctly.

### Decisions

- Workers never receive players, renderers or scene-tree references.
- Completed jobs outside the current retention radius are joined and discarded rather than inserted into cache.
- The manager waits every outstanding task on shutdown, following WorkerThreadPool's resource contract.
- V0.4 streams only base terrain; biome, decoration and resource activation begin in later versions.

## V0.3.0 - Deterministic single-chunk generation

- Added stable SHA-256-derived 64-bit seeds and independent domain/chunk seed derivation.
- Added signed tile, chunk, local and pixel coordinate conversion with negative-boundary regression tests.
- Added `ChunkData` as the scene-independent output of a multi-scale FastNoiseLite terrain generator.
- Rendered a 32×32 chunk through one `TileMapLayer` using a generated nearest-neighbour pixel atlas.
- Added deep water, shallow water, beach and land thresholds plus global-neighbour cleanup.
- Added `R` regeneration, `N` terrain/noise switching, a generation HUD and two actual render captures.
- Raised the generation format version from 1 to 2.

### Iteration findings

- `namespace` is reserved in GDScript 4.7; the initial parameter name prevented class registration and was renamed to `seed_domain`.
- The first fixed negative chunk happened to be entirely land, so a deterministic four-terrain fixture at `(-1, -4)` was selected through data probing rather than hard-coded tile output.
- Visual review exposed one isolated shallow-water cell; global neighbour-majority cleanup removed it, and a zero-isolated-cell regression was added.

### Decisions

- Text seeds use the first 63 bits of SHA-256 so results do not depend on Godot's default hash implementation.
- Generation algorithms use continuous world coordinates; they do not seed a shared random sequence or depend on requested chunk order.
- Rendering and generation remain separate so V0.4 can schedule pure data without touching the scene tree from workers.
- V0.3 renders exactly one chunk. Multi-chunk streaming is deliberately not pre-implemented.

## V0.2.0 - Player movement and camera

- Replaced the static game shell with a playable movement sandbox.
- Added eight-direction walk, run and roll states with health and stamina models.
- Kept velocity math in a pure helper and verified equivalent distance at 30, 60 and 120 FPS.
- Added physics obstacles, a pixel-aligned smooth camera and camera/world limits.
- Added a gameplay HUD and expanded the bundled CJK font subset for the new labels.
- Added an independent game-scene smoke test and made any Godot script error fail the release gate.
- Captured and inspected an actual 1280×720 OpenGL gameplay frame before packaging.

### Decisions

- `CharacterBody2D` is the authoritative movement and collision body.
- Player state is explicit (`IDLE`, `WALK`, `RUN`, `ROLL`) rather than inferred by UI code.
- The V0.2 terrain and avatar are code-drawn validation art so later world-generation work does not inherit temporary asset dependencies.
- The movement sandbox remains finite until deterministic generation and chunk streaming arrive in V0.3 and V0.4.

## V0.1.0 - Engineering skeleton

- Selected Godot 4.7.1 stable and GDScript.
- Created the public repository foundation and standard project structure.
- Added the boot menu, game-shell scene, settings persistence, bounded file logging, global event bus and lifecycle manager.
- Added a runtime debug panel, headless test entry point and structural verification script.
- Added a shared Noto Sans CJK SC UI font subset after the first visual render exposed missing Chinese glyphs; the subset is kept offline and expanded with each content release.
- Added automated containment checks after visual QA exposed a long-label overflow risk.
- Kept gameplay and procedural generation out of this version as required by the staged plan.

### Decisions

- The base viewport is 1280×720. Pixel assets use nearest-neighbour filtering.
- The compatibility renderer is the default to support more Windows computers.
- Core content uses stable IDs and separate save/generation version numbers from the beginning.
- Generated and downloaded binaries are release assets rather than source-controlled files.
# V1.0.1 - Responsive UI and Windows release gate

- Replaced fixed HUD positions with shared anchor-based layout helpers and explicit interaction-prompt/hotbar safe spacing.
- Configured expanding viewport content, fractional window scaling and nearest texture filtering so 1920×1080 fills correctly without blurred texture sampling.
- Added automated layout coverage at 1280×720, 1920×1080, 2560×1440 and 3440×1440; the suite now contains 417 passing checks.
- Added PowerShell test/build entry points, validated a Godot 4.7.1 Windows x64 export, and captured windowed plus exclusive-fullscreen evidence.
- Kept save format 6 and generation format 4 unchanged, preserving existing V1.0.0 saves and terrain.

### Review findings

- Integer-only viewport scaling cannot fill 1920×1080 from a 1280×720 base because the scale factor is 1.5; fractional viewport scaling plus nearest texture filtering is the compatible choice.
- A single native Godot access violation occurred during the first resource-generation gate and did not reproduce in the immediate standalone rerun or subsequent complete gate.
# V1.3.0 - Rivers, lakes and bridges

- Added a global-coordinate hydrology field with deterministic rivers, banks, lake basins, frozen lakes, desert oases and short bridges.
- Stored the resolved water feature in pure `ChunkData` so worker generation and render activation remain separated.
- Extended the shared terrain atlas with water, bank and bridge tiles without adding per-cell scene nodes.
- Applied surface-aware movement: wading and swimming slow the player, swimming drains stamina, ice is mildly slippery, and bridges preserve land speed.
- Preserved save format 7, generation format 4 and the V1.2 base checksum by treating hydrology as a compatible derived overlay.

### Decisions

- Hydrology uses only the world seed and signed world-tile coordinates, so chunk request order and borders cannot change a river.
- Water features are derived rather than persisted; no offline service or large save payload is required.
- V1.4 building templates are intentionally not included in this version.
# V1.4.0 - Structure templates

- Added a validated JSON resource format for cabins, camps, ruins, temples and dungeon entrances.
- Added semantic chest, enemy-spawn and dungeon-entrance markers to template cells and pure chunk data.
- Added lossless quarter-turn rotation and horizontal mirroring.
- Planned at most one deterministic structure candidate per 192×192-tile region and clipped cells independently into every intersecting chunk.
- Added a shared-atlas `StructureChunkLayer` with batched rendering and physical wall collision.
- Suppressed rendering and interaction for base resources hidden beneath a structure while retaining V1.3 generation checksums and saves.
- Added `tools/structure_editor.py` for offline schema validation and transformed text previews.

### Decisions

- Structure overlays are derived from the stable seed and region coordinates rather than persisted as full tile grids.
- Marker semantics are stored separately from visual tile kinds so later chest, encounter and dungeon systems can consume them without parsing artwork.
- V1.5 villages and roads are intentionally not pre-implemented.
# V1.5.0 - Villages and roads

- Added deterministic village regions, centers, plazas, radial house/shop layouts, wells, campfires and NPC markers.
- Connected every generated building entrance to the plaza and linked adjacent valid villages with cross-chunk regional roads.
- Compared horizontal-first and vertical-first paths using base terrain, hydrology and elevation-change costs.
- Converted road cells over rivers and lakes into bridge cells.
- Added a shared-atlas village layer and excluded covered resources from rendering and interaction.
- Preserved save format 7, generation format 4 and prior base checksums through a derived overlay.

### Decisions

- Village plans are regenerated from seed and signed region coordinates instead of storing full road grids.
- Roads are deterministic orthogonal paths; advanced pathfinding remains available for later world-polish versions.
- V1.6 underground caves are not pre-implemented.

# V1.6.0 - Underground caves

- Added one deterministic dry-land cave entrance per 4×4-chunk surface region and exact-coordinate layer transitions.
- Added signed-coordinate cellular-automata cave chunks, minimum-floor enforcement, component repair and guaranteed seam gates.
- Added coal, copper and iron veins through the existing harvest/inventory path, plus underground-only cave-bat candidates.
- Added deterministic chest loot with atomic full-inventory rejection, cave-wall collision and static/handheld torch lighting.
- Added layer-aware streaming jobs and preserved the existing bounded cache by draining active workers before a layer swap.
- Advanced save format to 8 for `player_layer`, underground resource differences and opened chests; formats 2–7 migrate to surface.
- Preserved generation format 4 and the established surface checksum because entrances remain derived overlay data.

### Decisions

- Underground chunks share the same signed X/Y coordinate plane as the surface, so every entrance and exit round-trips without a secondary coordinate transform.
- Cellular smoothing uses a halo wider than the iteration count; deterministic seam gates then guarantee traversable links between adjacent chunks.
- Cave walls/features are batched in a collision-enabled `TileMapLayer`; mineral veins continue through `ResourceHarvestState` instead of creating a parallel mining inventory.
- Graves carry their world layer, while the canonical ruin, its Boss and surface weather modifiers pause underground; this prevents same-coordinate state from leaking between layers.
- V1.7 procedural dungeon rooms, keys, traps and Boss state are intentionally not included in this version.

# V1.7.0 - Procedural dungeons

- Activated the existing surface dungeon-entrance marker as a third streamed world layer with an entrance-derived stable ID and exact return point.
- Added a data-driven finite generator with six non-overlapping rooms, five connected corridors and sealed neighbor chunks.
- Added two balanced lock/key pairs, four one-shot traps, two atomic-loot chests, two elite encounters and one final Boss marker.
- Added dungeon-only enemy roles and stable spawn IDs, plus the `dungeon_relic` completion reward.
- Added collision-enabled dungeon walls/doors, feature hiding, persistent darkness and a dedicated objective/progress HUD.
- Added `DungeonRunState`: incomplete exit clears transient progress and increments the next attempt; Boss completion persists without duplicate rewards or attempt inflation.
- Added dungeon-ID grave scopes and paused surface ruin/weather behavior in the third layer.
- Advanced save format to 9 and verified active-run round trip plus explicit format-2-through-8 migrations.
- Preserved generation format 4 and the canonical surface checksum.

### Decisions

- Generated cell/feature bytes are immutable; keys, doors, traps, chests and defeated encounters are resolved as a small save-state overlay.
- One anchor chunk contains the playable map and all neighbors are solid, making finiteness explicit while retaining the existing stream/job interfaces.
- The Boss room is always the last room in the stable sequence, but dimensions and intermediate order remain seed-derived.
- A completed run is revisit-safe; incomplete resets occur on exit instead of through wall-clock timers or offline progress.
- V2.0 exploration-map work is intentionally not pre-implemented in this version.

# V2.0.0 - Complete exploration world

- Expanded the ecological catalog from nine to twelve stable biomes with taiga, savanna and meadow climate rules.
- Added wild-boar and frost-sprite normal populations and prevented Boss-role definitions from entering ordinary candidate selection.
- Added three seed-deterministic regional Boss plans in separate discovery rings with biome preference, dry-land validation and stable rewards.
- Added a persistent exploration model for 3×3 fog reveal, discovered landmarks, completion state, travel points and up to 32 custom markers.
- Added a world-discovery scanner that derives village, structure, ruin, cave, dungeon and regional-Boss markers without storing generated layouts.
- Added a full-screen responsive map canvas, `M` input flow, safe-camp travel and same-layer stream relocation.
- Advanced save format to 10 and generation format to 5; format-9/generation-4 worlds explicitly migrate with their permanent coordinate differences retained.
- Rebuilt the offline CJK font subset from every runtime script/data string and added direct V2 glyph coverage to the test gate.
- Expanded the complete gate to 682 assertions plus import, menu smoke and game-scene smoke.

### Decisions

- Fog and markers are player progression, so they are persisted; generated landmark positions remain deterministic overlays and are re-derived from the seed.
- Regional Bosses use the existing enemy state machine and object-drop path, but have a separate one-time completion state so normal respawn cooldowns cannot duplicate world progression.
- Fast travel is restricted to discovered explicit travel points on the surface and drains active generation jobs before replacing the cache.
- The biome catalog changes generated bytes, so V2.0 advances generation format instead of claiming compatibility with the V1.7 checksum.

# V2.1.0 - NPCs and village life

- Added six validated NPC roles with deterministic village-qualified identities, stable names, phase dialogue and contiguous full-day schedules.
- Added guaranteed elder, merchant and innkeeper fallbacks so terrain-rejected houses cannot remove required village services.
- Added bounded NPC activation, surface-only simulation, daytime work/patrol/social movement and deterministic village-road pathfinding.
- Added a modal dialogue/shop interface, one stable currency item and atomic buy/sell transactions with complete inventory rollback.
- Added inn sleep that advances the persisted cycle exactly to the next dawn, restores player condition and requests a save.
- Added `NpcWorldState` for talk/trade counters and coin statistics, advanced save format to 11 and covered explicit format-10 migration.
- Preserved generation format 5 and the established V2.0 checksum because NPCs remain a seed-derived runtime overlay.
- Expanded the complete gate to 718 assertions and 127 structural paths plus import, menu smoke and game-scene smoke.

# V2.2.0 - Relationships and village reputation

- Added a validated relationship catalog with five signed-affection tiers, role-specific gift preferences, price multipliers, reputation discounts and threshold rewards.
- Added `RelationshipState` as the sole owner of NPC affection, daily gift limits, claimed rewards and village reputation.
- Integrated relationship dialogue and service refusal into `NpcDirector`; every completed trade updates relationships and every gift/reward operation is transactional.
- Expanded the NPC panel to show attitude, affection, village reputation and a bounded inventory-backed gift list.
- Advanced save format to 12 with explicit format-11 migration while retaining the complete format-2-through-10 chain.
- Preserved generation format 5 because all relationship records are player progression overlays keyed by deterministic NPC/village IDs.
- Expanded the complete gate to 736 assertions and 130 structural paths plus import, menu smoke and game-scene smoke.

# V2.3.0 - Quests and adventure journal

- Added ten validated fixed quest definitions: six prerequisite-linked main quests and four retryable side quests.
- Added `QuestState` for active limits, objective progress, tracking, completion, atomic reward claims, abandonment, failure counts and retry.
- Connected inventory quantities, discovered landmark types, all enemy deaths and NPC role meetings to four canonical objective types.
- Added an `L`-key journal with status-aware actions and a compact persistent tracked-objective HUD.
- Advanced save format to 13 with explicit format-12 migration and retained the complete format-2-through-11 chain.
- Preserved generation format 5 because quests reference stable item/enemy/NPC/marker IDs and never mutate generated bytes.
- Expanded the complete gate to 766 assertions and 134 structural paths plus import, menu smoke and game-scene smoke.

# V2.4.0 - Factions and frontier powers

- Added four validated factions, five signed-standing tiers, all six pairwise relations and unique NPC/enemy ownership.
- Added `FactionState` for standing, bounded event history, one-time discovery credit and stable control-point ownership.
- Connected completed trades, claimed quests, discovered landmarks and hostile-member defeats to exact standing actions.
- Added the ash-raider scout to normal surface populations without changing terrain generation bytes.
- Added tier-gated faction shops with respected/allied discounts and complete inventory rollback.
- Added an `F`-key faction archive for standings, relations, stock, control points and recent events.
- Advanced save format to 14 with explicit format-13 migration and retained the complete format-2-through-12 chain.
- Preserved generation format 5 because factions and control points are progression overlays keyed by stable generated IDs.
- Expanded the complete gate to 794 assertions and 138 structural paths plus import, menu smoke and game-scene smoke.

# V2.5.0 - Dynamic world events

- Added eight validated event definitions for caravans, village raids, meteor falls, resource surges, blizzards, ruin openings, temporary Bosses and rescue operations.
- Added a seed-deterministic timetable whose coprime permutation covers all eight event IDs per cycle and whose absolute boundaries use persisted in-game time only.
- Added `WorldEventState` for current-region activation, objective progress, survival resolution, expiration, bounded history and large-time-skip fast-forward.
- Composed event multipliers with weather-driven resource/enemy modifiers and added snow override for active blizzards.
- Connected canonical trade, harvest, enemy defeat, ruin discovery, regional-Boss and NPC interaction sources to event objectives.
- Materialized three stable ash-raider encounters for village raids and one stable grove-titan encounter for temporary-Boss events; stale event encounters are removed when their instance ends.
- Added a `V`-key tracker and responsive timetable window for active progress, six upcoming entries and recent results.
- Advanced save format to 15 with strict numeric normalization, duplicate-instance rejection and explicit format-14 migration.
- Preserved generation format 5 because the schedule and active encounters are runtime/progression overlays rather than generated terrain bytes.
- Expanded the complete gate to 823 assertions and 143 structural paths plus import, menu smoke and game-scene smoke.

### Decisions

- Event order is seed-derived, but activation location is the player's current chunk so scheduled content remains reachable in an infinite world.
- The timetable advances only with saved game time; closing the application cannot complete objectives or manufacture outcomes.
- Only the active record and bounded history are serialized. Future plans are reconstructed from seed and cursor, preventing save growth.
- Weather and event multipliers compose multiplicatively and clamp at the consumer boundary; neither system silently overwrites the other.

# V2.6.0 - Regional levels and world progress

- Added a validated five-tier danger curve over stable 6×6-chunk regions with signed-coordinate floor division.
- Added `RegionProgressionModel` for deterministic enemy levels, elite rolls and layer-aware combat multipliers without changing generation bytes.
- Extended `EnemyBase` with runtime level/elite identity, scaled health/attack/defense, elite outline and doubled drops.
- Added a composed equipment score from the best weapon, axe and pickaxe plus unique regional-Boss sigils.
- Added `RegionProgressionState` for discovered regions, deduplicated canonical progress sources and transactional one-time rewards.
- Connected region discovery, elite defeats, claimed quests, completed events/dungeons and defeated regional Bosses to exact world-progress values.
- Gated the dune behemoth and frost wyrm at 24 and 60 world-progress points while leaving deterministic map markers intact.
- Added a `P`-key tracker and responsive progression window for danger, gear, enemy ranges, reward conditions and Boss gates.
- Advanced save format to 16 with explicit format-15 migration and retained the complete format-2-through-14 chain.
- Preserved generation format 5 and its canonical checksum because regional difficulty is a runtime/progression overlay.
- Expanded the complete gate to 862 assertions and 148 structural paths plus import, menu smoke and game-scene smoke.

### Decisions

- Danger is fixed by region coordinate, so a location never changes tier when the player gains progress or equipment.
- Enemy levels and elite identity use stable spawn IDs; unloading and returning cannot reroll an encounter.
- World progress stores validated sources rather than a mutable total, making duplicate credit and point tampering detectable.
- Equipment score uses the best owned item per slot until the dedicated V3 equipment system introduces explicit worn slots.
- Region rewards commit only after every item fits; failure restores the complete inventory and leaves the claim available.

# V3.0.0 - Civilization and complete quests

- Expanded the fixed quest catalog to 24 templates: ten linked main quests and fourteen side quests across all four canonical objective types.
- Added four bounded random-contract rules and a pure region/day generator that creates three stable offers without using global randomness.
- Added schema-2 quest persistence for generated definitions and boards, a 96-definition cap and whole-board terminal pruning.
- Added three main-chain-gated world choices with exact faction effects, six-point deduplicated progress credit and atomic rollback.
- Expanded the `L` journal with task categories, board status and key-choice controls while retaining the minimum 1280×720 layout gate.
- Advanced save format to 17 with explicit format-16/schema-1 migration; generation format remains 5.
- Expanded the complete gate to 883 assertions and 150 structural paths plus import, menu smoke and game-scene smoke.

### Decisions

- Generated definitions are persisted because a player-accepted contract must not change if a later version adjusts generation rules.
- Board identity combines a stable region ID and in-game day; closing the game neither refreshes offers nor advances them by real time.
- Choice records store only the selected option and resolved day. Effects are configured in the catalog and applied once through transactional state owners.
- Fixed quests and generated contracts share objective/reward machinery, while generated definitions remain distinguishable in presentation and storage.

# V3.1.0 - Complete survival systems

- Added a validated survival catalog for hunger, body temperature, wetness, four status effects, environmental modifiers and two canonical foods.
- Added a scene-free survival state with bounded exposure, periodic damage, movement penalties, food recovery, death/inn recovery and strict schema-1 round trips.
- Composed biome, weather, time phase, world layer, water contact, heat proximity and player activity in the runtime sandbox without changing generated world bytes.
- Added atomic selected-hotbar food use on `G`, a responsive survival HUD and a gameplay setting that pauses the complete survival rule set.
- Advanced save format to 18 with explicit format-2-through-17 neutral migration; generation format remains 5.
- Expanded the complete gate to 911 assertions and 154 structural paths plus import, main-menu smoke and game-scene smoke.

### Decisions

- Survival state accepts one immutable environmental snapshot per update so the model remains independently testable and never reads the scene tree.
- Disabling survival pauses mutation instead of resetting values, allowing players to re-enable the rule without losing their condition.
- Food consumption removes exactly one validated selected item before applying recovery; a mismatched slot or empty stack changes nothing.
- Environmental and status speed multipliers compose into the existing player motor, preserving walk/run/roll behavior and collision ownership.
- Older saves start neutral with no fabricated exposure or effects, while death and inn recovery clear temporary effects to prevent immediate damage loops.

# V3.2.0 - Player building systems

- Added a validated nine-piece building catalog for floor, wall, door, roof, furniture, storage, lighting, workbench and campfire definitions.
- Added `BuildingState` with three occupancy layers, stable signed-coordinate IDs, support/adjacency validation and cloned-inventory placement/demolition transactions.
- Added a `K`-key responsive building panel, live mouse-world preview, quarter-turn rotation and explicit placement rejection reasons.
- Added a shared-atlas player-building renderer with separate ground/structure/roof batches, solid furniture/walls and a collision-free open-door variant.
- Added persistent eight-slot chest storage that preserves normal stacks and individual tool durability, plus `E`-key door/chest interaction.
- Connected placed workbenches/campfires to existing crafting station availability and connected campfires/torches to lighting and survival heat.
- Advanced save format to 19 with surface chunk-owned placement arrays, strict schema reconstruction, stale-difference cleanup and explicit format-2-through-18 empty migration.
- Preserved generation format 5 and the canonical terrain checksum because every placement remains a mutable overlay.
- Expanded the complete gate to 970 assertions and 160 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- A global script class can appear cached enough for assertions to continue after a dependent parse failure. The error-aware shell gate caught the failure; explicit `Vector2i` annotations removed the ambiguous atlas-marker inference.
- A ternary expression returning a typed `Array[Dictionary]` on one branch and `[]` on the other fails at runtime under Godot's typed-array boundary. Renderer calls now build an explicitly typed local array before dispatch.
- A placed workstation is useful only inside its configured proximity radius. The runtime test moves to the workbench before asserting external station availability, matching the actual gameplay contract.
- Sparse saves need deletion as well as creation. `SaveWriteJob` now removes old layer-difference files that are absent from the complete retained snapshot, so full demolition cannot resurrect a stale building.

### Decisions

- Generated structures and player buildings remain separate: generated overlays are seed-derived and immutable, while player placements are validated world differences.
- Placement IDs derive from world tile and occupancy slot rather than a mutable counter, preventing duplicate identity and making chunk ownership independently verifiable.
- Building state exists only in surface chunk differences; `player.json` does not contain a second copy that could diverge.
- Placement, demolition and storage are inventory transactions. A failed material, support, storage or capacity check changes neither inventory nor world state.
- Workstation possession remains backward-compatible, but a consumed placed workstation continues to grant recipes only while the player is nearby.
- V3.2 deliberately excludes farming, animal systems and production automation; those begin in later isolated versions.

# V3.3.0 - Agriculture systems

- Added a validated farming catalog for four crops, one fertilizer, weather growth modifiers, bounded plots, staged growth, quality outputs and regrowth.
- Added `FarmingState` with signed-coordinate plot IDs, atomic seed/fertilizer/harvest inventory transactions and deterministic day-based simulation.
- Added `H`-key crop selection plus contextual mouse actions for tilling, sowing, watering, fertilizing and harvesting within six tiles.
- Added shared-atlas farming presentation for tilled, watered, growing and mature plots, refreshed only in affected active chunks.
- Connected rain, snow and sandstorm state to growth; added ordinary, silver and gold harvest tiers determined from care, fertilizer and a stable world-seed roll.
- Added five playable crafting recipes and seventeen canonical agriculture items covering inputs and all quality outputs.
- Advanced save format to 20 with surface chunk-owned plot arrays, strict schema reconstruction, stale farm-only difference cleanup and explicit format-2-through-19 empty migration.
- Preserved generation format 5 and its canonical terrain checksum because soil and crop progress remain mutable overlays.
- Expanded the complete gate to 1,041 assertions and 165 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- JSON numeric values return as floating-point Variants even after structural validation. Farming restore now reconstructs every integer, float and Boolean field so strict snapshot equality survives disk round trips.
- A regrowing crop cannot assume its retained stage is simply the penultimate stage because crops expose different stage counts and regrow durations. The stage is derived from retained growth over days-to-maturity.
- Farming and building persistence are independent arrays but share world occupancy. Both placement paths perform reciprocal checks, and load rejects overlap instead of relying on whichever overlay restores first.
- Sparse farm-only chunks require the same retained-set cleanup as demolished buildings; the save regression removes and recreates the exact owning file.

### Decisions

- Simulation advances from saved in-game days, never wall-clock time. Sleeping or explicit game-time skips mature crops predictably without offline real-time growth.
- Rain counts as watering for every elapsed simulated day; snow and sandstorms slow growth through catalog multipliers while preserving deterministic catch-up.
- Harvest quality is deterministic per plot/crop/harvest count and combines care with fertilizer, preventing save reloads from rerolling an output.
- Fruit trees and tomatoes retain a crop record after harvest and regrow; annual wheat and carrots return to empty tilled soil.
- Farming state exists only in surface chunk differences and never duplicates into `player.json` or generated chunk bytes.
- Animal husbandry, processing, equipment and automation remain isolated to their following roadmap versions.

# V3.4.0 - Animal husbandry systems

- Added a validated husbandry catalog for chickens, cows and sheep with biome rules, feed items, taming/breeding thresholds, adulthood, cooldowns, products, sleep phases and bounded limits.
- Added deterministic global-cell wild planning with stable IDs, signed coordinates, biome-compatible species and rejection of water, resources and generated overlays.
- Added `HusbandryState` for daily feeding, friendship, taming, two-day feed reserve, bounded product catch-up, collection, night sleep, fenced breeding and juvenile growth.
- Added `U`-key species selection plus contextual left-click feed/tame/collect and right-click breed actions through a responsive husbandry panel.
- Added egg, milk and wool items, a tenth animal-fence blueprint, reciprocal building/farming/animal occupancy and a dedicated batched animal chunk layer.
- Advanced save format to 21 with surface chunk-owned animal arrays, strict schema reconstruction, stale husbandry-only difference cleanup and explicit format-2-through-20 empty migration.
- Preserved generation format 5 and its canonical terrain checksum because untouched wild animals are derived overlays and interacted animals never modify generated bytes.
- Expanded the complete gate to 1,102 assertions and 171 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- A local inferred from a heterogeneous inline `Vector2i` offset array did not retain a strong type under full runtime compilation. The offspring search now annotates the target explicitly, and the error-aware gate was rerun from a fresh import cache.
- A mechanical save-version assertion update also matched the unrelated berry stack limit. The full regression exposed it immediately; the fixture remains the catalog-backed value 20.
- Product-ready animals prioritize collection. Runtime care therefore performs collection and feeding as separate atomic actions on the same game day, preserving both inventory and friendship progress.
- Chunk-owned offspring cannot persist a separate global birth counter without creating two owners. Restore derives the next counter from stable `bred:<day>:<id>` identities.

### Decisions

- Untouched wild animals remain deterministic and free to re-derive. The first successful feed is the boundary that converts one candidate into a persisted world difference.
- Husbandry advances only on saved in-game day transitions. Closing the game adds no wall-clock production, while sleeping and other explicit day skips simulate unloaded chunks predictably.
- Buildings, farms and animals share reciprocal occupancy validation; corrupted overlaps reject load instead of depending on restore order.
- Feed, collection and fence placement remain complete inventory transactions. Capacity, material or duplicate-day failures change neither items nor animal state.
- V3.4 deliberately excludes cooking, refining, equipment upgrades and automation; those remain isolated to later roadmap versions.

# V3.5.0 - Cooking and refining systems

- Added a validated processing catalog for cooking-pot/smelter stations, wood/coal fuels and ten multi-material meal, potion, ingot and equipment-material recipes.
- Added cooking-pot and smelter inventory items, workbench recipes, supported building blueprints, distinct shared-atlas rendering and heat-source behavior.
- Added rollback-safe `ProcessingSystem` inventory/fuel transactions plus a responsive `T`-key panel for live station, capacity, fuel, material and result views.
- Expanded survival recovery with three meals and three state-aware potions covering hunger, health, temperature, poison, frostbite and burning.
- Extended processor placement records with bounded fuel and completed-operation counts; fueled devices reject demolition.
- Advanced save format to 22 while retaining surface chunk ownership and explicit format-21 migration with no fabricated processors or fuel.
- Preserved generation format 5 and the canonical terrain checksum because every processor remains a player-authored building overlay.
- Expanded the complete gate to 1,148 assertions and 175 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- Bulk save-version assertion edits can match unrelated gameplay fixtures; the full regression caught the regional enemy-level ceiling immediately and the catalog-backed level 21 limit remains unchanged.
- Processor fuel belongs with the placed building, not in a separate player document. Keeping one owner lets the existing chunk grouping, backup and stale-file rules remain authoritative.
- A two-resource transaction cannot rely on UI button state. The processing model rechecks nearby device, capacity, materials, output space and fuel, then restores the inventory snapshot if the building-side commit cannot complete.
- Recovery-only potions require a usefulness rule distinct from food. Temperature direction and matching active effects now make zero-hunger consumables valid without allowing waste at a neutral state.

### Decisions

- Wood provides two fuel units and coal provides six; devices retain at most 24 units and every recipe declares a positive exact cost.
- Fuel and completed-operation count are processor-only building fields. Non-processor injection, overflow, negative values and unsupported demolition reject rather than normalize silently.
- Cooking and smelting are immediate deterministic transactions in V3.5. Timed queues and unloaded-machine automation remain isolated to V3.7.
- Meals and potions use the existing `G` recovery action so inventory selection remains the single source of the consumed item.
- V3.5 deliberately excludes weapon quality, armor, accessories and reinforcement; those remain isolated to V3.6.

# V3.6.0 - Equipment and enhancement systems

- Added a validated equipment catalog with six worn slots, four quality tiers, four rarity tiers, five deterministic affixes, a copper-guard set and bounded enhancement/repair rules.
- Added `EquipmentState` as the sole owner of stable equipment instances and worn-slot references, with atomic inventory import, enhancement material use and repair material use.
- Added copper and iron weapons, a three-piece copper armor set and two accessories, expanding the canonical catalogs to 68 items and 24 recipes.
- Added runtime attack, defense, health and stamina composition, set bonuses and active-weapon durability while retaining zero-durability records for repair.
- Added an `O`-key responsive equipment panel with inventory registration, six slot rows, owned-item selection, stat comparison, enhancement and repair controls.
- Advanced save format to 23 with player-owned equipment-state schema 1 and explicit format-22 no-fabrication migration.
- Preserved generation format 5 and the canonical terrain checksum because equipment remains entirely outside generated world bytes.
- Expanded the complete gate to 1,198 assertions and 179 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- A fixed-height dual-column equipment layout exceeded the 1280×720 regression once six slot rows and minimum scroll heights composed. Reducing only the content minima preserved every control while restoring the four-resolution containment contract.
- Persisted combat defense remains the player's base value. Equipment defense is transient and recomposed after load, avoiding cumulative bonuses across repeated restore cycles.
- Inventory weapons and owned equipment cannot share ownership. Registration removes one complete durable stack before creating the stable equipment instance.

### Decisions

- Instance IDs are monotonic and quality, rarity and affixes are derived from stable identity. Opening the panel, changing slots or reloading cannot reroll equipment.
- Enhancement is capped at +5 and consumes the V3.5 tempered plate material; repair consumes iron ingots according to missing durability.
- Broken weapons remain equipped but contribute no equipment stats or active weapon identity until repaired, preventing deletion and preserving player investment.
- Equipment state is stored once in `player.json`; chunk differences continue to own only world-positioned mutable overlays.
- V3.6 deliberately excludes timed production queues and logistics automation; those remain isolated to V3.7.

# V3.7.0 - Basic automation systems

- Added a validated automation catalog for conveyors, automatic smelters, storage links and item sorters, including cadence, throughput, connection span, recipe/filter sets and hard limits.
- Added four inventory items, four workbench recipes and four supported building blueprints, expanding the canonical catalogs to 72 items, 28 recipes and 16 building pieces.
- Added scene-free, snapshot-transactional logistics for directional chest transfer, selected-item sorting and fuel-aware use of all four existing smelter recipes.
- Added persistent machine enablement, time cursor, work status, cycles, fuel, selected recipe and selected filter inside owning surface-chunk building records.
- Added a responsive `Y`-key panel with live machine status, performance limits, enable/disable, recipe and filter controls.
- Advanced automation from saved game time independently of chunk renderers, with 128-machine, 64-operation and 720-offline-tick bounds.
- Advanced save format to 24 with explicit format-23 no-fabrication migration while preserving generation format 5 and its canonical checksum.
- Expanded the complete gate to 1,249 assertions and 183 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- A full source chest fixture initially assumed twelve slots while the canonical player chest has eight. Reusing the catalog limit kept the performance-throttle test tied to actual game capacity.
- Adding one more control hint made the label's text minimum wider than its old centered control rectangle. Expanding the rectangle to the existing 24-pixel viewport margins preserved the 14-pixel font and restored 1280×720 containment.
- Machine simulation cannot depend on active renderers: an unloaded-chunk runtime fixture now proves that saved game time advances the same `BuildingState` while only loaded changed chunks request visual refresh.
- Throughput alone is not a performance bound. A full storage-link line can execute many ticks in one time jump, so the global successful-operation budget is enforced separately from per-machine catch-up.

### Decisions

- Rotation is the single source of logistics direction. A valid line reads storage behind a machine and writes storage in front, traversing only compatible transport/link/sorter pieces for at most twelve tiles.
- Automation runs every five game seconds. Closing the game adds no wall-clock progress; explicit in-game time jumps and unloaded chunks use the same bounded catch-up path.
- The complete building snapshot is the transaction boundary. Inputs, outputs, fuel and machine counters commit together only after strict state validation.
- Machine state remains chunk-owned with its building. No player-level automation document or renderer-owned work queue can become a second persistence owner.
- V3.7 deliberately excludes V4.0 home/base progression and later roadmap systems.

# V4.0.0 - Complete survival-building loop

- Added a validated homestead catalog for a three-base cap, 24-tile base radius, 32-tile marker spacing, stable names and a 120-second travel cooldown.
- Added the homestead beacon as the seventeenth player-building blueprint and retained `BuildingState` as its only physical persistence owner.
- Added scene-free base synchronization, active-home selection and nearest-base asset aggregation across buildings, storage, farms, tamed animals, processors, workbenches and automation machines.
- Composed the roadmap's house, storage, farming, husbandry, cooking/potions, smelting, equipment-enhancement and automation systems into one derived eight-step completion view.
- Added a responsive `X`-key home panel with base limits, coordinates, asset summaries, loop progress, active-home controls and travel feedback.
- Added surface/underground home relocation that rebuilds streaming state before committing cooldown and explicitly rejects dungeon travel.
- Advanced save format to 25 with player-level home metadata cross-validated against the complete chunk-owned beacon set, plus explicit format-24 no-fabrication migration.
- Preserved generation format 5 and the canonical terrain checksum because bases remain mutable overlays.
- Expanded the complete gate to 1,285 assertions and 187 structural paths plus import, main-menu smoke and game-scene smoke.

### Iteration findings

- Comparing a freshly parsed JSON document directly with an in-memory snapshot exposed Godot's JSON numeric normalization (`42` becomes `42.0`). Restoring through the production schema before comparison now verifies semantic identity and the same validation path used by a real load.
- A home marker cannot be copied into a separate base-owned building list without creating two writable authorities. Using the building placement ID as the base ID keeps demolition, chunk persistence and migration referentially exact.
- Teleport cooldown cannot begin when planning succeeds: layer switching or relocation could still fail. The runtime commits time only after the player reaches the exact validated beacon tile.
- Base completion stays current only when every contributing owner publishes changes. Building, farming, husbandry and automation mutation paths therefore emit a fresh immutable homestead view.

### Decisions

- A world supports at most three bases. Their 32-tile spacing exceeds the 24-tile management radius threshold enough to avoid colocated markers, while deterministic nearest-base resolution handles any remaining range overlap.
- Base range and eight-step completion are derived views, not save fields. Reloading cannot retain stale asset counts or completion flags.
- Base names and active-home choice are player-owned metadata; the physical beacon, surrounding structures, farms and animals remain in their existing owning chunk differences.
- Format-24 migration starts empty and then synchronizes only actual valid homestead beacons. A world without a marker gains no base, selection or travel time.
- V4.0 completes the planned survival/building milestone and deliberately excludes V4.1 ocean and island expansion.

# V4.1.0 - Ocean and islands

- Added a validated ocean catalog for shallow/deep swimming multipliers, swim stamina drain and the rowboat's speed, 16-boat cap and two-tile deploy range.
- Added full swimming on base-terrain water with data-driven movement multipliers plus a fourth survival attribute: oxygen drains in deep water, emptiness applies the data-driven drowning effect and surfacing recovers it deterministically.
- Added the craftable rowboat with atomic deployment onto the facing water tile, session boarding, boat-speed sailing without oxygen drain, automatic mooring on dry land and deliberate facing-land disembark.
- Persisted boats as tile-qualified `surface:<x>:<y>` records inside their owning surface chunk difference, advancing save format to 26 with a strict no-fabrication migration for formats 25 and earlier.
- Added the palm island biome from a dedicated island-mask noise plus a genuine-islet rule, reclassifying existing land tiles only so terrain bytes and building legality stay intact while generation version advances to 6.
- Added four ocean resources on a separate stable water hash channel, two aquatic enemies restricted to allowed water tiles and cell-by-cell water structures (shipwreck, sea ruin).
- Added the fourth regional boss Tide Sovereign anchored only in open water with its 90-point world-progress gate and the tide sigil equipment-score slot.
- Expanded the complete gate with ocean catalog, boat-state, oxygen, island-classification, water-resource, water-structure, aquatic-spawn and boat-persistence assertions plus runtime deploy/board/moor coverage.

### Iteration findings

- Windows PowerShell 5.1 turns native stderr into a terminating NativeCommandError under `$ErrorActionPreference='Stop'`; the test gate now streams Godot output with a relaxed preference and judges the log afterwards, so parse errors and failed assertions no longer truncate the suite silently.
- Save-probe catalogs were reconstructed and revalidated on every autosave dispatch. Memoizing them in `SaveManager` and skipping deep copies of probe-normalized documents keeps dispatch under the 50 ms main-thread budget on slower machines.
- Ocean resources must not perturb land generation. A separate `resource-water-cell` hash channel preserves every land candidate byte-for-byte within one generation version while water tiles gain their own stable resources.
- Boats cannot reuse the building system: they are water-anchored, movable and ridable. Keeping `BoatState` as the sole record owner with the boarding flag as session state avoids a second writable authority while mooring stays referentially exact.
- Island classification must not move coastlines. Deriving the biome from a mask noise plus an islet rule over existing land tiles keeps every building, road and structure anchor valid across the generation-version advance.

### Decisions

- Oxygen drains only in deep base-terrain water on the surface layer. Shallow water, lakes, rivers and boarding a boat keep breathing free, so ocean crossing still demands a boat or deliberate risk.
- The boat identity is its water tile. Deployment, mooring and migration all derive the same `surface:<x>:<y>` ID, so a relocated boat remains one stable record and chunk persistence stays the only physical owner.
- Aquatic enemies never spawn on land and land enemies never spawn in water; the planner enforces both directions so no enemy can strand on an island or swim inland far from its return radius.
- V4.1 deliberately excludes V4.2 seasons, deeper world layers and every later roadmap system.
