# Changelog

All notable changes are recorded here. Version numbers follow the staged project plan.

## [4.1.0] - 2026-09-06

### Added

- A validated ocean catalog with bounded shallow/deep swimming multipliers, swim stamina drain and the rowboat speed, deployment cap and range.
- Full swimming on base-terrain water: shallow and deep water apply data-driven movement multipliers and extra stamina drain, deep water drains a new oxygen attribute, zero oxygen applies the data-driven drowning effect, and surfacing clears it while oxygen recovers.
- Survival-state schema 2 with the oxygen attribute, drowning effect and oxygen HUD bar; older survival documents migrate with neutral full oxygen.
- A craftable rowboat: deployment consumes the item onto the facing water tile, a second interaction boards it, sailing uses the boat speed without oxygen drain, reaching dry land moors the boat at its last water tile automatically and facing-land interactions disembark deliberately.
- Boat persistence as tile-qualified `surface:<x>:<y>` records inside their owning surface chunk difference (save format 26), with a 16-boat global cap, no duplication and no fabricated boats in migrations.
- The data-driven palm island biome classified from a dedicated island-mask noise plus genuine low-elevation islets, keeping terrain bytes, checksums semantics and building legality unchanged.
- Four ocean resources (kelp, clam cluster, coral, driftwood log) generated on a dedicated stable water-channel hash that never changes land resource results.
- Two aquatic enemies (reef fin, abyss maw) that spawn only on allowed water tiles and never overlap ocean resources; land candidates reject aquatic enemies.
- Shipwreck and sea ruin water structures with chest and enemy-spawn markers, validated cell-by-cell to rest entirely on water.
- The fourth regional boss Tide Sovereign anchored only in open water, unlocked at 90 world progress, with the tide sigil extending the equipment score to 48.

### Changed

- Game version advances to 4.1.0, save format to 26 and generation format to 6 with explicit migrations for formats 25 and earlier.
- The interact chain handles boats on the surface layer before buildings, NPCs, ruins, graves and resource harvest.
- The survival HUD exposes a third oxygen bar row.

### Fixed

- Drowning and starvation are now condition-persistent effects: when the trigger condition still holds (in deep water with zero oxygen, or zero hunger), a single long `update` call no longer lets `_tick_effects` expire and erase the effect within the same frame. This keeps `has_effect("drowning")` stable across both real per-frame deltas and large test step deltas.

## [4.0.0] - 2026-08-11

### Added

- A validated homestead catalog with a three-base limit, 24-tile management radius, 32-tile beacon spacing and 120-second successful-travel cooldown.
- A craftable homestead beacon that establishes a stable named base without duplicating the owning `BuildingState` placement.
- Base-range aggregation for shelter, storage, farming, husbandry, cooking, smelting, enhancement and automation, completing the eight-step survival-building loop.
- A responsive `X`-key homestead panel for base status, active-home selection, asset inspection and safe return travel.
- Save-format-25 homestead schema persistence with strict cross-validation against chunk-owned beacon placements.

### Changed

- Game version advances to 4.0.0 and save format advances to 25; generation format remains 5.
- Building presentation now includes a dedicated homestead category and seventeenth blueprint.
- Building, farming, husbandry and automation mutations refresh the immutable homestead status view.

### Fixed

- Home travel commits its cooldown only after the player has safely changed layer, relocated and rebuilt streaming state.
- Demolishing a beacon removes its base and repairs the active-home selection immediately.
- Format-24 migration creates no fabricated beacon, base or cooldown and synchronizes only real compatible marker placements.

## [3.7.0] - 2026-08-11

### Added

- A validated automation catalog for conveyors, automatic smelters, storage links and item sorters, with explicit cadence, throughput, connection span and hard limits.
- Four craftable, rotatable automation machines, extending the canonical catalogs to 72 items, 28 crafting recipes and 16 player-building pieces.
- Directional chest-to-machine logistics, selected-item sorting and fuel-aware automatic use of the four canonical smelter recipes.
- Persisted machine enablement, time cursor, work status, completed cycles, fuel, selected recipe and sorter filter inside owning surface-chunk building records.
- A responsive `Y`-key automation panel for status inspection, machine toggles, recipe selection and filter selection.
- Bounded unloaded-chunk catch-up plus explicit global machine, per-advance operation and per-machine offline-tick limits.

### Changed

- Game version advances to 3.7.0 and save format advances to 24; generation format remains 5.
- Building and crafting presentation now includes a dedicated automation category and four new machine blueprints.

### Fixed

- Logistics simulate against a complete building snapshot and commit only after schema validation, preventing partial input/output, fuel loss or item duplication.
- Format-23 and earlier differences cannot fabricate automation machines or work state during migration.
- The expanded control-hint row remains contained at 1280×720 and every larger supported target resolution.

## [3.6.0] - 2026-08-11

### Added

- A validated equipment catalog with six worn slots, four quality tiers, four rarity tiers, deterministic affixes, a three-piece set bonus and bounded enhancement/repair rules.
- Player-owned equipment instances for weapons, armor and accessories, imported atomically from canonical inventory stacks without duplicating ownership.
- Seven new craftable equipment items and recipes, extending the canonical item and crafting catalogs to 68 items and 24 recipes.
- A responsive `O`-key equipment panel for inventory registration, slot management, live stat comparison, enhancement and repair.
- Runtime attack, defense, health and stamina composition plus active-weapon durability integration.
- Save-format-23 equipment-state schema persistence with explicit empty-equipment migration from format 22 and every earlier supported format.

### Changed

- Game version advances to 3.6.0 and save format advances to 23; generation format remains 5.
- Regional gear score and combat presentation now use explicitly worn equipment while preserving the legacy inventory baseline for migrated worlds.

### Fixed

- Equipment generation derives quality, rarity and affixes from stable instance identity, so reloads cannot reroll an owned item.
- Enhancement, repair, import and slot changes validate before commit; rejected actions consume no materials and duplicate no equipment.
- Broken weapons remain owned at zero durability and can be repaired instead of disappearing.

## [3.5.0] - 2026-08-11

### Added

- A validated processing catalog with two station types, two fuel values and ten multi-material cooking, potion and refining recipes.
- Placeable cooking-pot and smelter buildings with persistent fuel capacity, remaining units and completed-operation counts.
- Three meals, three recovery potions, copper/iron/steel ingots and tempered equipment plate items.
- A responsive `T`-key processing panel that reports nearby device, fuel, inventory materials and actionable recipes.
- Runtime temperature-aware potion use plus explicit poison, frostbite and burning recovery.
- Save-format-22 processor fields stored inside the owning surface chunk's existing building records.

### Changed

- Game version advances to 3.5.0 and save format advances to 22; generation format remains 5.
- Player-built cooking pots and smelters contribute to heat-source checks and use distinct shared-atlas presentation.
- Food validation now permits recovery-only potion items and rejects use when none of their configured effects can help.

### Fixed

- Processing validates an inventory clone, output capacity and exact station fuel before commit; failed operations change neither owner.
- Fuel insertion rolls the inventory back if the building mutation cannot commit, and fueled devices cannot be demolished silently.
- Format-21 migration preserves every prior building while fabricating no processor or fuel state.

## [3.4.0] - 2026-08-11

### Added

- A validated husbandry catalog for deterministic biome-compatible chickens, cows and sheep, including feed, taming, friendship, adulthood, breeding cooldown and product rules.
- A responsive `U`-key husbandry panel with contextual feeding, taming, product collection and fenced breeding actions.
- Pure `HusbandryPlanner` and `HusbandryState` models for stable wild identities, daily care, two-day feed reserve, night sleep, juvenile growth and bounded inactive-chunk product simulation.
- Egg, milk and wool inventory items, plus a tenth player-building blueprint for animal fences.
- A batched `AnimalChunkLayer` that distinguishes wild, tamed, juvenile, sleeping and product-ready animals without modifying generated chunk bytes.
- Save-format-21 chunk-owned interacted-animal differences, stale-file cleanup and explicit format-2-through-20 empty-husbandry migration.

### Changed

- Game version advances to 3.4.0 and save format advances to 21; generation format remains 5.
- Building, farming and husbandry now share reciprocal occupancy checks so no persistent or deterministic animal can overlap another mutable surface overlay.

### Fixed

- Feeding, collection and placement operations validate cloned inventory transactions before commit, preventing item loss or duplicated animal products.
- Birth IDs are re-derived from chunk-owned offspring records on load, preserving stable identity without a duplicated player-level counter.
- Day and phase events refresh only affected active renderers while still simulating saved animals in unloaded chunks.

## [3.3.0] - 2026-08-11

### Added

- A data-driven agriculture catalog for wheat, carrots, tomatoes and apple trees, including growth stages, regrowth, yields and quality-specific outputs.
- A responsive `H`-key farming panel plus contextual mouse controls for tilling, sowing, watering, fertilizing and harvesting within six tiles.
- Pure `FarmingState` day simulation with rain watering, snow/sandstorm slowdown, bounded catch-up, deterministic normal/silver/gold quality and fruit-tree regrowth.
- A shared-atlas `FarmingChunkLayer` that batches tilled, watered, growing and mature presentation without altering generated chunk bytes.
- Five craftable farming inputs and seventeen canonical seed, fertilizer, sapling and harvest items.
- Save-format-20 chunk-owned farming differences, stale-file cleanup and explicit format-2-through-19 empty-farming migration.

### Changed

- Game version advances to 3.3.0 and save format advances to 20; generation format remains 5.
- Building and farming placement validation now share surface occupancy so persistent overlays cannot overlap.

### Fixed

- Farming input and harvest operations simulate complete inventory transactions before committing, preventing loss or duplication on capacity failures.
- Restored JSON farming numbers are normalized to exact integer/float fields, preserving strict snapshot identity.
- Regrowing crops derive their post-harvest stage from retained growth rather than assuming a fixed number of stages.

## [3.2.0] - 2026-08-11

### Added

- A data-driven nine-piece player-building catalog covering floors, walls, doors, roofs, furniture, persistent storage, lights and both existing workstation types.
- A `K`-key building panel, mouse-world placement preview, quarter-turn rotation, explicit invalid reasons and layered demolition controls.
- Pure `BuildingState` transactions for placement costs, 50% refunds, door state, eight-slot chest storage, workstation proximity and heat-source queries.
- A shared-atlas `PlayerBuildingLayer` with separate ground/structure/roof batches and collision-free open-door variants.
- Runtime integration for nearby placed workbench/campfire recipes, player-built lighting/survival heat and door/chest `E` interactions.
- Save-format-19 chunk-owned building differences, stale-difference cleanup and explicit format-2-through-18 empty-building migration.

### Changed

- Game version advances to 3.2.0 and save format advances to 19; generation format remains 5.
- `ChunkRenderer` and `ChunkStreamManager` now refresh only the owning active chunk when a player building changes.
- Save jobs remove obsolete difference JSON after a successful snapshot writes its complete retained set.

### Fixed

- Building placement and demolition use cloned inventory transactions so validation, capacity or material failures cannot consume or duplicate items.
- Player-built doors update both their rendered atlas variant and physical collision immediately when toggled.
- Building state is stored only in surface chunk differences and is never duplicated into `player.json`.

## [3.1.0] - 2026-08-11

### Added

- Data-driven hunger, body-temperature and wetness attributes composed from activity, biome, weather, day phase, world layer, water and nearby heat.
- Poison, burning, frostbite and starvation effects with bounded exposure, duration, periodic damage and movement multipliers.
- Atomic `G`-key food consumption for berries and cooked berries, including health/temperature recovery and poison cleansing.
- A responsive survival HUD plus a persisted gameplay setting that disables survival decay and environmental damage.
- Save-format-18 survival-state schema 1 persistence and explicit format-2-through-17 neutral migration.

### Changed

- Game version advances to 3.1.0 and save format advances to 18; generation format remains 5.
- Death and inn recovery now normalize survival condition and clear temporary effects.

### Fixed

- Survival movement penalties compose with existing walk, run and roll speed instead of replacing player movement rules.
- Food is removed only after the selected hotbar item and quantity validate, preventing failed-use loss or duplication.

## [3.0.0] - 2026-08-11

### Added

- Twenty-four validated fixed quest templates: ten prerequisite-linked main quests and fourteen replayable side quests.
- Four deterministic random-contract rules producing three region/day offers with bounded targets, quantities, rewards and a 96-definition retention cap.
- Three prerequisite-gated world choices with exact faction-standing outcomes and deduplicated world-progress credit.
- Journal presentation for main, side and random quests plus available, locked and resolved world choices.
- Save-format-17 persistence for generated definitions, boards and choice records, with explicit format-16 quest-schema migration.

### Changed

- Game version advances to 3.0.0 and save format advances to 17; generation format remains 5.
- Quest-state schema advances to 2 while preserving all fixed-quest entries from schema 1.

### Fixed

- Generated quests keep their exact original definition across reloads instead of depending on later catalog changes.
- Choice settlement rolls back faction standing and world progress together if either side cannot commit.

## [2.6.0] - 2026-08-11

### Added

- Five data-driven regional danger tiers over stable 6×6-chunk regions, with enemy level ranges, recommended gear scores and region rewards.
- Seed- and spawn-ID-deterministic enemy levels, elite rolls, combat scaling, visual identity and doubled elite drops.
- A composed equipment score using the best weapon/tool entries and unique regional-Boss sigils.
- Deduplicated world-progress sources for regions, elites, quests, events, dungeons and regional Bosses, plus two progression-gated Boss unlocks.
- A `P`-key progression tracker/window with danger, equipment, enemy, reward and Boss-gate views.
- Save-format-16 persistence and explicit format-15 migration coverage.

### Changed

- Game version advances to 2.6.0 and save format advances to 16; generation format remains 5.
- Regional Boss population now honors world-progress unlocks, while deterministic map markers remain discoverable.

### Fixed

- Region reward settlement restores the complete inventory when any configured output does not fit.
- Repeated discoveries, elite deaths and other stable sources cannot duplicate world progress.

## [2.5.0] - 2026-08-11

### Added

- Eight data-driven dynamic world events covering caravans, village raids, meteor falls, resource surges, blizzards, ruin openings, temporary Bosses and rescues.
- A seed-deterministic bounded timetable, current-region activation, objective progress and a 48-entry outcome history.
- Runtime effects for enemy population, resource yield and snow-weather override, plus trade/combat/harvest/exploration/NPC progress sources.
- A `V`-key event tracker and responsive timetable window with active, upcoming and historical views.
- Save-format-15 persistence and explicit format-14 migration coverage.

### Changed

- Game version advances to 2.5.0 and save format advances to 15; generation format remains 5.
- Surface enemy and resource multipliers now compose weather and active world-event effects.

### Fixed

- Large in-game time skips fast-forward the deterministic schedule without unbounded loops or save growth.
- Event population refresh runs only when the effective multiplier changes.

## [1.2.0] - 2026-08-03

### Added

- Data-driven clear, rain, snow and sandstorm weather with biome-specific regional weights.
- Smooth tint/particle transitions and fully offline synthesized weather ambience.
- Weather modifiers for resolved resource yield and active enemy population.
- Exact weather-state persistence plus explicit save-format-2-through-6 migration coverage.

### Changed

- Game version advances to 1.2.0 and save format advances to 7; generation format remains 4.
- Terrain and biome numeric boundaries use runtime-safe conversions for Godot 4.7.1.

### Fixed

- Ordinary saves no longer erase an existing weather snapshot when the caller omits an unchanged state.
- Weather audio streams stop and release cleanly during scene shutdown.
- The weather test probe is explicitly freed, eliminating the new ObjectDB leak.

## [1.1.0] - 2026-08-03

### Added

- Configurable dawn, day, dusk and night phases totaling a 20-minute game day.
- Smooth environment-color transitions and player-following torch illumination.
- Phase-aware enemy selection, a data-driven 1.5× night population cap and nocturnal cave-bat activity.
- Night-only moonflowers with a stable moonpetal inventory item.
- Automated coverage and actual GPU evidence for all four phases and torch lighting.

### Changed

- Biome rules are compiled from JSON into thread-safe typed scalar objects before generation begins.
- Game version advances to 1.1.0; save format remains 6 and generation format remains 4.

### Fixed

- Eliminated intermittent native Godot crashes caused by shared mutable biome-rule dictionaries during repeated generation tests.
- Night-only resources cannot be seen or interacted with outside their configured phase.

## [1.0.1] - 2026-08-02

### Added

- Shared responsive UI layout helpers and automated containment/overlap checks for four target resolutions.
- Windows PowerShell test and release-build gates with PE x64, runtime smoke and SHA-256 validation.
- Actual GPU screenshots for windowed target resolutions and exclusive fullscreen.

### Changed

- HUD panels, inventory, crafting, hotbar and interaction prompts now use anchors and viewport-relative safe areas.
- Window content expands to fill the display while nearest filtering preserves crisp pixel edges.
- Fullscreen uses exclusive fullscreen and game/export metadata advances to 1.0.1; save format 6 and generation format 4 remain unchanged.

### Fixed

- The hotbar no longer covers the `E` interaction prompt.
- HUD elements no longer depend on fixed 1280×720 screen coordinates.
- Fullscreen and common widescreen/ultrawide resolutions no longer retain a fixed-size world image.
- Biome condition checks no longer invoke redundant runtime float constructors during threaded generation.
- PowerShell tests restore temporary Godot profile environment variables before the release export begins.

## [1.0.0] - 2026-08-02

### Added

- Basic 300-second day/night cycle with day count, night overlay and persisted world time.
- Seed-deterministic canonical ruin located in a bounded discovery ring without changing generation-v4 chunk bytes.
- Data-driven ruin guardian with chase, telegraphed slam, defense, health, knockback and one terminal defeat event.
- Persistent discover/Boss/reward milestone state and explicit save-format-2/3/4/5 migrations.
- One-time ancient-core reward with full-inventory retry and duplicate-claim prevention.
- Direction/distance ruin hint, objective/Boss/time HUD and procedural PCM sound cues.

### Changed

- Game version advances to 1.0.0 and save format advances from 5 to 6; generation remains format 4.
- Item catalog expands from 19 to 20 stable entries.
- The V0.10 training fixtures are removed from normal world startup now that real enemies and the Boss close the combat loop.

### Fixed

- A full inventory cannot consume or duplicate the one-time Boss reward.
- Legacy worlds initialize an incomplete milestone state while preserving terrain, inventory, crafting, combat and graves.

## [0.11.0] - 2026-08-02

### Added

- Validated enemy catalog for slime, wolf and cave-bat definitions, biome rules, combat values and drops.
- Shared eight-state enemy machine covering idle, wander, alert, chase, attack, hurt, return and death.
- Deterministic signed-chunk enemy candidates selected from terrain and biome data without water/resource overlap.
- Screen-exclusion spawning, active/per-chunk hard caps, distance sleep, despawn cooldowns and bounded candidate cache.
- Collision-aware `CharacterBody2D` movement with stable tangent avoidance when a world obstacle blocks pursuit.
- Enemy attacks against player combat state, player attacks against enemy defense/health, death fade and pooled drops.
- Canonical slime-gel, wolf-pelt and bat-wing item IDs plus population/type/state HUD.

### Changed

- Game version advances to 0.11.0; save format remains 5 and generation format remains 4.
- Item catalog expands from 16 to 19 stable entries.
- Runtime font subset expands to every V0.11 source/data/test glyph.

### Fixed

- Enemy population cannot grow beyond 18 active nodes or retain an unbounded explored-chunk candidate cache.
- Spawns inside the viewport plus margin are rejected, preventing visible pop-in.
- Far enemies stop state-machine ticks, while world collision prevents persistent movement through solid obstacles.

## [0.10.0] - 2026-08-01

### Added

- Validated weapon catalog for unarmed, wooden-sword and stone-sword combat definitions.
- Normal attacks, three-step combos, cooldowns, stamina costs and direction-following `Area2D` hitboxes.
- Per-attack target registry that prevents a target from receiving duplicate hits from one swing.
- Documented damage/defense formula, knockback, hit invulnerability and roll invulnerability.
- Player death count, safe-position respawn and short respawn protection.
- Multi-grave inventory deposit/reclaim with exact durable-item preservation and world markers.
- Combat training target, damage hazard and dedicated weapon/combo/cooldown/grave HUD.
- Combat/grave disk persistence plus save-format-2/3/4 migration.

### Changed

- Save format advances from 4 to 5; inventory and generation schemas remain unchanged.
- Equipped swords now drive attack data and lose one durability on the first accepted hit of a swing.
- Project font subset expanded to every V0.10 runtime/data/test glyph.

### Fixed

- Repeated overlap callbacks from the active hitbox cannot damage the same target twice.
- Death cannot erase backpack contents: the complete normalized snapshot is moved into a persistent grave before respawn.

## [0.9.0] - 2026-08-01

### Added

- Validated station and recipe catalog with ten recipes across hands, workbench and campfire.
- Discovery-based recipe unlocks, station availability and a dedicated `C` crafting panel.
- Transactional crafting that simulates deduction/output before committing the inventory snapshot.
- Wooden and stone axes, pickaxes and swords, plus workbench, campfire, torch and cooked berries.
- Per-instance tool durability, hotbar durability display, break removal and durability-preserving drops.
- Tool power applied to resource durability so correct stone tools gather faster than wooden tools.
- Persistent crafting discoveries and selected durable-tool state.

### Changed

- Save format advances from 3 to 4; inventory schema advances from 1 to 2; generation remains format 4.
- Grass drops both fiber and branches, providing a hands-only path to the first wooden tools.
- Item data advances to schema 2 with tool, weapon, station and utility categories and equipment fields.
- Project font subset expanded to every V0.9 runtime/data/test glyph.

### Fixed

- Failed crafting, including insufficient materials or a full inventory, never consumes inputs.
- Sorting, discarding and pooled ground transfer retain the exact durability of individual tools.

## [0.8.0] - 2026-08-01

### Added

- Validated item-data catalog with stable unique IDs, material/food categories and per-item stack limits.
- Pure 24-slot inventory model with deterministic stacking and an eight-slot hotbar view.
- Drag swap/combine, right-click half split, exact discard and category-aware sort operations.
- Inventory window, always-visible hotbar, selected-slot details and explicit full-inventory feedback.
- Pickup transfer contract that leaves every unaccepted remainder in its original pooled ground drop.
- Versioned slot-order persistence, byte-stable normalized snapshot checks and save-format-2 migration.

### Changed

- Save format advances from 2 to 3; generation remains format 4.
- Item presentation data moved from the resource catalog into canonical `data/items.json` resources.
- Player saves now store all 24 slots, stack quantities, hotbar size and selected hotbar index.
- Project font subset expanded to every V0.8 runtime/data/test glyph.

### Fixed

- JSON numeric normalization now restores integer slot metadata and quantities exactly.
- Full-inventory automatic pickup no longer deactivates a ground drop before capacity is accepted.

## [0.7.0] - 2026-08-01

### Added

- World-creation overlay with validated name and original text/numeric seed.
- Versioned world metadata and player documents under isolated local world directories.
- Player position, health, stamina, active tool and V0.6 pickup-count restoration.
- Sparse per-chunk surface differences containing only destroyed resource keys.
- 30-second autosave, `Ctrl+S` manual save and return/close save triggers.
- Worker-thread JSON writes with main-thread immutable snapshot dispatch and timing feedback.
- Temporary/previous-file transaction, five retained timestamped backups and shutdown flush.
- File/line-specific corruption and save/generation incompatibility messages.
- Continue flow for the most recently played valid world and a complete save-format document.
- Exact-data visual of 75 restored removals over 668 remaining resources.

### Changed

- Save format advanced from placeholder 1 to complete format 2; generation remains format 4.
- The main menu now enables Continue when a local world document exists.
- `ResourceHarvestState` and `PlayerCharacter` expose explicit persistence snapshots/restoration.
- Project font subset expanded for all V0.7 world creation, save and error labels.

### Fixed

- Save validation no longer string-casts arbitrary dictionary Variants.
- Outstanding old-world saves are flushed before creating or loading another world.

## [0.6.0] - 2026-08-01

### Added

- Data-driven resource catalog for trees, rocks, grass, flowers and berry bushes.
- Deterministic global candidate-grid placement with biome rules and cross-chunk minimum spacing.
- Packed resource coordinates, codes and variants in `ChunkData` and generation checksums.
- Shared resource `TileMapLayer` atlas with physical collisions for solid resources.
- Hands, axe and pickaxe selection, proximity prompts, durability and tool validation.
- Hit-flash collection animation, deterministic item stacks and automatic proximity pickup.
- Fixed 32-object drop pool with matching-item overflow merging.
- Session difference state that prevents repeated drops or resource restoration after chunk reload.
- Exact-data 6×6-chunk resource distribution renderer and generation/interaction/pool regression tests.

### Changed

- Generation format advanced from 3 to 4 because resource spawn bytes became part of chunks.
- Project font subset expanded for V0.6 resource, tool, pickup and inventory labels.
- Test runner now treats a non-zero assertion summary as a release failure even if Godot exits zero.
- Export presets continue to include all external JSON catalogs.

### Fixed

- Register the runtime resource atlas with its `TileSet` before adding per-tile collision polygons.
- Player spawn selection now excludes generated resource cells.

## [0.5.0] - 2026-08-01

### Added

- Independently seeded continentalness, elevation, erosion, temperature, moisture and detail fields.
- Data-driven biome catalog loaded from `data/biomes.json` with schema and ID validation.
- Plains, forest, desert, snowfield, swamp, mountain, coast, ocean and deep-ocean biomes.
- Configurable transition bands and global-neighbour majority cleanup for coherent biome borders.
- Per-chunk continental, erosion, temperature, moisture and biome byte maps included in checksums.
- Terrain, biome, climate and elevation debug views plus live climate HUD values.
- Headless deterministic biome-map renderer and continuity/coverage regression tests.

### Changed

- Generation format advanced from 2 to 3 because chunk bytes and terrain fields changed.
- Project font subset expanded for all V0.5 Chinese biome and climate labels.
- Export presets explicitly include the external biome JSON configuration.

### Fixed

- Replaced a non-constant `PackedStringArray` class constant with a valid constant array.
- Added generation-HUD containment tests after expanding diagnostics to two lines.

## [0.4.0] - 2026-07-31

### Added

- Dynamic chunk activation, preloading, sleeping, cache retention and unloading.
- Distance-prioritized queue biased toward the player's movement direction.
- Up to four concurrent WorkerThreadPool jobs that return pure `ChunkData`.
- Main-thread-only creation and removal of per-chunk `TileMapLayer` renderers.
- Shared runtime pixel atlas and local 0–31 TileMap coordinates per renderer.
- Active/preload/cache/queue/worker/peak-memory streaming metrics.
- Toggleable chunk-boundary overlay and unbounded follow camera.
- Seam, return consistency, worker execution and 1,800-step bounded-cache tests.

### Fixed

- Added explicit `Vector2i` typing for queue values returned as Variant.
- Reimported the expanded CJK font subset before visual capture.
- Moved boundary lines above TileMap batches and prevented camera-ready zoom from overriding the streaming view.

## [0.3.0] - 2026-07-31

### Added

- Stable SHA-256-based 64-bit text seeds, numeric seeds and domain-derived seeds.
- Signed world-tile, 32×32 chunk, local-tile and pixel coordinate conversion.
- Pure `ChunkData` generation independent of scene-tree state and request order.
- Multi-scale FastNoiseLite elevation using continental, elevation and detail fields.
- Deep-water, shallow-water, beach and land classification with isolated-cell cleanup.
- Programmatic pixel atlas rendered through one `TileMapLayer`.
- Deterministic regeneration, terrain/noise debug toggle and generation HUD.
- Restart, ordering, negative-coordinate, exact-byte and isolated-cell regression tests.

### Fixed

- Replaced the all-land showcase coordinate with a stable negative-coordinate coastline fixture.
- Applied global-neighborhood majority cleanup to remove isolated shallow-water cells.

## [0.2.0] - 2026-07-31

### Added

- Eight-direction player movement with walk, run and roll states.
- Health and stamina models with bounded damage, healing, drain and recovery.
- Physics obstacles and collision-based movement through `CharacterBody2D`.
- Pixel-aligned smooth camera with finite sandbox limits.
- Gameplay HUD for health, stamina, movement state and world coordinates.
- Code-drawn sandbox terrain, river, particles and placeholder pixel visuals.
- Frame-rate independence, movement normalization, state and resource tests.
- Dedicated game-scene smoke test and error-aware Godot log validation.

### Fixed

- Renamed a helper that conflicted with Godot 4.7's native `draw_ellipse` API.
- Reworked HUD bar sizing to avoid anchor/layout warnings.

## [0.1.0] - 2026-07-31

### Added

- Godot 4.7.1 project skeleton and standard directory layout.
- Pixel-art styled main menu and game-shell scene.
- Event bus, game lifecycle, persistent settings and bounded logging autoloads.
- Runtime FPS, scene and memory debug panel.
- Headless automated tests and repository structural verification.
- Windows and Linux export presets.
- Architecture, development process and release-roadmap documentation.
# V1.3.0 - 河流、湖泊和桥梁

- 新增全局确定性河流与河岸场，水系跨区块连续且与生成顺序无关。
- 新增普通湖泊、低温冰湖、沙漠绿洲和稳定短桥覆盖层。
- 新增涉水、游泳、冰面移动倍率以及游泳耐力消耗。
- 扩展区块纯数据与共享 TileSet 渲染，同时保持生成格式 4 和既有地形校验值。
- 自动化覆盖水系类型、确定性、区块数据、桥梁速度和水中减速。
# V1.4.0 - 建筑模板

- 新增结构 JSON 格式及五类内置建筑模板。
- 新增宝箱、敌人出生点、地牢入口语义标记。
- 新增旋转、镜像和跨区块确定性规划。
- 新增共享 TileMap 结构渲染层及墙体碰撞。
- 建筑覆盖位置会隐藏并阻止采集原有资源。
- 新增离线结构校验和预览工具。
# V1.5.0 - 村庄和道路

- 新增数据驱动村庄区域、中心、广场、房屋和商店布局。
- 新增水井、火堆、NPC、商店与房屋入口标记。
- 新增村内道路、区域道路、地形代价选择和水上桥梁。
- 新增共享 TileMap 村庄层及覆盖资源避让。

# V1.6.0 - 地下洞穴

- 新增确定性地表洞穴入口，以及保持坐标不变的地表/地下世界层切换。
- 新增元胞自动机地下区块、最小地板比例、孤立区域连通修复和跨区块固定通道。
- 新增煤、铜、铁矿脉，洞穴蝙蝠、地下宝箱、洞穴墙体碰撞和固定火把照明。
- 敌人候选按世界层过滤，洞穴蝙蝠只在地下生成。
- 墓碑按世界层保存与交互；地下死亡返回地表重生点，遗迹/Boss 与地表天气效果不会泄漏到地下。
- 存档格式升级为 8，分层保存地下采集差异、宝箱状态和玩家当前世界层。
- 格式 2–7 旧存档显式迁移；生成格式仍为 4，既有地表校验值保持不变。

# V1.7.0 - 程序化地牢

- 复用地表地牢入口标记，进入入口坐标绑定的独立有限地牢，并精确返回地表。
- 每座地牢确定性生成六个房间、五段连通走廊、两组锁门/钥匙、四个陷阱和两个宝箱。
- 新增两名地牢精英、最终守卫 Boss、专属遗物奖励和挑战状态 HUD。
- 新增共享 TileMap 地牢层、墙体与锁门碰撞，以及地牢固定黑暗表现。
- 未完成地牢退出后重置本次进度；击败 Boss 后完成状态、已解决机关和宝箱永久保存。
- 墓碑按具体地牢 ID 隔离，地表、洞穴和不同地牢之间不会共享同坐标状态。
- 存档格式升级为 9，保存当前地牢、锚点、返回位置、尝试次数、机关、宝箱与敌人完成状态。
- 格式 2–8 旧存档显式迁移；生成格式仍为 4，既有地表校验值保持不变。

# V2.0.0 - 完整探索世界

- 新增针叶林、稀树草原和花甸，将稳定群系目录扩展至 12 类并升级生成格式至 5。
- 新增荒野野猪与霜灵两类普通敌人，并将随机种群严格限制为 `normal` 角色。
- 新增林冠巨像、沙海巨兽和霜穹翼龙三只确定性区域首领及专属印记奖励。
- 新增带迷雾的世界地图、地点自动发现、地点完成状态、32 个自定义标记和地图图例。
- 新增村庄、遗迹、地牢与安全营地快速旅行，并在旅行时安全刷新流送和敌人会话状态。
- 存档格式升级为 10，保存发现区块、地点、自定义标记与区域首领完成状态。
- 新增格式 9 / 生成格式 4 到 V2.0 的显式迁移，并保留格式 2–8 的既有迁移链。
- 从当前运行时脚本与数据重建中文字体子集，覆盖全部 V2.0 地图与内容字形。
- 自动化套件扩展至 682 项，覆盖探索模型、运行时地图、快速旅行、区域首领、字体字形与存档往返。

# V2.1.0 - NPC 与村庄生活

- 新增六类数据驱动 NPC、稳定姓名与每村必备的村长、杂货商和旅店老板。
- 新增按昼夜进度解析的工作/休息日程、村内 A* 寻路和地表外完整休眠。
- 新增响应式 NPC 对话与商店界面，支持阶段对话、继续交谈和当前活动展示。
- 新增边境币，以及材料出售、补给购买和背包空间不足时的原子回滚。
- 新增旅店睡眠：精确推进到次日黎明，恢复生命/体力并触发存档。
- 存档格式升级至 11，保存 NPC 交谈和交易统计；格式 10 显式迁移为空 NPC 状态。
- 保持生成格式 5 与 V2.0 规范地形校验值不变。
- 完整自动化套件扩展至 718 项，结构校验 127 项，导入、菜单和游戏场景冒烟均通过。

# V2.2.0 - 关系与村庄声望

- 新增五级 NPC 态度、个人好感与村庄声望，全部采用稳定 ID 和严格范围校验。
- 新增六类职业礼物偏好、每日一次赠礼限制、友善/信赖一次性奖励与事务回滚。
- 交易同时提升个人与村庄关系；买入、卖出价格随态度和正向声望动态调整。
- 敌对 NPC 拒绝商店和旅店服务，同时保留可恢复关系的对话与赠礼入口。
- NPC 面板扩展为三栏关系界面，实时显示态度、好感、声望、礼物效果与库存。
- 存档格式升级至 12；格式 11 显式迁移为空关系状态，既有格式 2–10 继续沿迁移链升级。
- 保持生成格式 5 与 V2.0 规范地形校验值不变。
- 完整自动化套件扩展至 736 项，结构校验 130 项，导入、菜单和游戏场景冒烟均通过。

# V2.3.0 - 任务与冒险日志

- 新增 10 条数据驱动固定任务：六段主线和四条可重试支线。
- 新增采集、讨伐、探索、护送/会合目标，以及前置任务、并发上限和稳定目标 ID。
- 新增任务状态机，覆盖接取、追踪、完成、奖励领取、失败、重试和严格存档校验。
- 采集库存、探索标记、敌人死亡与 NPC 交谈接入统一任务事件流。
- 新增 `L` 键任务日志与常驻任务追踪 HUD；奖励领取采用完整背包事务回滚。
- 存档格式升级至 13；格式 12 显式迁移为空任务状态，格式 2–11 继续沿原迁移链升级。
- 保持生成格式 5 与 V2.0 规范地形校验值不变。
- 完整自动化套件扩展至 766 项，结构校验 134 项，导入、菜单和游戏场景冒烟均通过。

# V2.4.0 - 阵营与边境势力

- 新增四个数据驱动阵营、五级声望、六组对称阵营关系与稳定成员归属。
- NPC 交易、任务领奖、地点发现和阵营成员击败接入统一声望事件流。
- 新增灰烬斥候普通敌人，以及敌对成员击败的双向阵营结果。
- 新增按声望等级解锁、尊敬/同盟折扣和完整背包事务回滚的阵营商店。
- 新增村庄控制点、影响力争夺与归属变更；地点发现与控制状态使用稳定 ID。
- 新增 `F` 键阵营档案，显示四阵营声望、关系、商店、控制点和最近事件。
- 存档格式升级至 14；格式 13 显式迁移为四阵营默认状态，格式 2–12 继续沿原迁移链升级。
- 保持生成格式 5 与 V2.0 规范地形校验值不变。
- 完整自动化套件扩展至 794 项，结构校验 138 项，导入、菜单和游戏场景冒烟均通过。
