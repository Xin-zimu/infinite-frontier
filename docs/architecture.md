# Architecture

Infinite Frontier uses a layered, data-oriented Godot architecture. This document records the playable foundation through V4.0.0 and will evolve with every version.

## Runtime layers

| Layer | Responsibility | Components through V4.0.0 |
|---|---|---|
| Core | Application lifecycle, settings, logging, events | `GameManager`, `SettingsManager`, `SaveManager`, `LogManager`, `EventBus` |
| Presentation | Scenes, menus and debug UI | `main_menu.gd`, `world_sandbox.gd`, gameplay HUDs, `SurvivalHud`, `BuildingPanel`, `BuildingPreview`, `FarmingPanel`, `HusbandryPanel`, `ProcessingPanel`, `EquipmentPanel`, `AutomationPanel`, `HomesteadPanel`, inventory/crafting/exploration/civilization panels, environment overlays and debug panels |
| Gameplay | Player, interaction, combat, survival, building, farming, husbandry, processing, equipment, automation, homesteads and progression | `PlayerCharacter`, inventory/crafting/combat/enemy/adventure/exploration systems, `SurvivalState`, `BuildingState`, `FarmingState`, `HusbandryState`, `ProcessingSystem`, `EquipmentState`, `AutomationSystem`, `HomesteadState`, civilization and progression state owners |
| World | Coordinates, chunk data, persistence and streaming | `WorldCoordinates`, `ChunkData`, `ChunkStreamPlanner`, `ChunkGenerationJob`, `ChunkStreamManager`, `ChunkRenderer`, generated overlay layers, `PlayerBuildingLayer`, `FarmingChunkLayer`, `AnimalChunkLayer`, `WorldDropPool`, `SaveWriteJob` |
| Generation | Pure deterministic world data | `WorldSeed`, terrain/resource/hydrology generators, structure/village/NPC/event/quest planners, `QuestGenerator`, `CaveGenerator`, `DungeonGenerator`, `RuinPlanner` |
| Data | Stable IDs and data-driven content | JSON catalogs in `data/`, including exploration, dungeon and NPC definitions, plus catalog and definition resources |

## Architectural rules

1. Generation code is pure with respect to scene-tree state.
2. Systems communicate through typed signals or explicit APIs.
3. UI scripts do not own world-generation or combat logic.
4. Background work produces data only; scene-tree mutation remains on the main thread.
5. Save and generation formats are independently versioned.
6. World coordinates support negative values from their first implementation.
7. Stable versions are immutable Git tags.

## Boot flow

`project.godot` loads the five core autoloads, then opens the main menu. `GameManager` owns scene transitions. `SettingsManager` loads local configuration before the first interactive frame, while `LogManager` creates a bounded session log under `user://logs`.

## Player flow

`PlayerCharacter` owns input, the finite state machine and `move_and_slide`. Pure velocity calculations live in `PlayerMotor`, allowing the same diagonal normalization and delta integration rules to be tested without a scene tree. `PixelCamera` follows the physics body independently, and `GameplayHud` consumes player signals without owning player state.

The V0.2 sandbox is intentionally finite. `SandboxTerrain` and static obstacle bodies are presentation and collision fixtures for validating player movement; V0.3 replaces the terrain source with deterministic generation, while V0.4 introduces streamed chunks.

## Deterministic generation flow

`WorldSeed` converts text with a documented SHA-256 fixture and derives independent system seeds. `WorldCoordinates` converts signed world tiles to chunk/local coordinates with floor division, including negative boundaries. `TerrainGenerator` reads only seeds, biome configuration and integer world coordinates and returns `ChunkData`; it never reads the player or scene tree. `ChunkRenderer` is the only component that translates those bytes into `TileMapLayer` cells.

## Biome ownership

`BiomeCatalog` validates the external JSON schema, unique stable IDs, contiguous byte codes, ordered water thresholds and land-biome rules. `TerrainGenerator` owns noise sampling and classification. `ChunkData` stores the resulting maps. `ChunkRenderer` owns palette presentation, while `GenerationHud` only displays values supplied by the stream manager. Editing biome thresholds, priorities, colors or transition widths therefore does not require changing generation code.

The generation pipeline uses independent seed domains for continentalness, elevation, erosion, temperature, moisture and local detail. Altitude cools the temperature field and nearby oceans influence moisture. Hard-rule boundaries include configured transition bands, then a global 3×3 majority pass removes sparse outliers without depending on chunk generation order.

## Streaming ownership

`ChunkStreamPlanner` is a pure policy module for radii, retention and priority. `ChunkStreamManager` owns the queue, job lifecycle, bounded cache and renderer lifecycle. A `ChunkGenerationJob` constructs a private generator on a worker and returns only `ChunkData`; every task is joined before its result is read or the manager exits. `ChunkRenderer` creation, TileMap updates, HUD signals and node removal happen only on the main thread.

The active radius is 2 (at most 25 renderer nodes), the preload radius is 3 (at most 49 nearby data targets), and the retention radius is 4 (at most 81 cached coordinates under sustained travel). Each renderer stores local cells `0..31` and applies its signed chunk position as a node transform, avoiding large serialized TileMap coordinates.

## Cave-layer ownership

`CaveCatalog` validates cellular-automata thresholds, entrance spacing, vein rules and chest loot against the canonical resource and item catalogs. `CaveEntrancePlanner` derives surface entrances from seed, signed region and pure terrain queries. `CaveGenerator` owns underground cell smoothing, minimum-floor enforcement, component joining, seam gates, veins and feature markers; it returns only `ChunkData`.

`ChunkStreamManager` owns the active `surface`/`underground`/`dungeon` layer. A transition first joins outstanding worker tasks, releases renderers and cache entries, then seeds the target layer. Cave transitions preserve the signed tile; dungeon transitions use the generated entry tile and retain an exact surface return point. `ChunkGenerationJob` selects `TerrainGenerator`, `CaveGenerator` or `DungeonGenerator` from immutable context. `CaveChunkLayer` and `DungeonChunkLayer` alone translate their cells/features into collision-enabled batches, while the environment overlays own darkness and surface-only weather visibility.

## Dungeon ownership

`DungeonCatalog` validates room, lock/key, trap, chest, elite and reset rules against canonical item data. `DungeonGenerator` derives one finite six-room plan from world seed, entrance-derived dungeon ID and anchor chunk. It owns room dimensions, sequence, orthogonal corridors and immutable feature bytes; every non-anchor chunk is a sealed wall map. It never reads a player, save file or scene-tree node.

`DungeonRunState` is the only owner of mutable dungeon progress. It records attempt count, collected keys, unlocked doors, triggered traps, opened chests, defeated elites and Boss completion. `DungeonChunkLayer` renders unresolved generated features and owns wall/locked-door collision, `EnemyDirector` materializes only unresolved elite/Boss markers, and `DungeonHud` consumes a status snapshot. Leaving an incomplete run clears transient fields; leaving a completed run preserves them. These rules are tested independently of presentation.

## Resource generation ownership

`ResourceCatalog` validates stable resource, tool and item IDs plus biome weights, durability, spacing and drop bounds. `ResourceGenerator` evaluates one jittered candidate per global 2×2 tile cell. A candidate is accepted only when its stable rank wins every conflicting neighbor within the larger of their configured spacing radii. Because selection reads global cells rather than adjacent chunk objects, the result is independent of request order and remains valid across negative chunk borders.

Accepted coordinates, resource codes and visual variants are packed into `ChunkData` and its checksum. Water rejection happens before selection. `ResourceChunkLayer` creates one shared-atlas `TileMapLayer` per active chunk; it does not create a `Node2D` for every resource. Solid atlas entries carry collision polygons, while hit feedback swaps only the affected cell to a temporary highlighted atlas row.

## Resource interaction ownership

`ChunkStreamManager` performs proximity queries against active chunk data and delegates hit rules to `ResourceHarvestState`. The state layer owns partial durability, collected keys and the slot inventory. A collected key is never resolved twice and remains hidden when the chunk renderer is recreated. V0.7 serializes resource differences; V0.8 replaces bridge counts with exact slot/stack persistence.

`WorldDropPool` preallocates 32 visual objects. Destroyed resources resolve bounded item stacks from the stable resource key, then activate or merge a pooled object. Nearby mature drops return to the pool after automatic pickup. `ResourceHud` receives prompt, tool, inventory and feedback events; it never calculates harvest rules.

## Item and inventory ownership

`data/items.json` is the canonical source for unique item IDs, presentation, category and stack limit. `ItemCatalog` validates it and materializes immutable `ItemData` resources. Resource drops reference those IDs but do not duplicate item definitions.

`InventoryModel` is a pure `RefCounted` value model with 24 ordered slots; the first eight slots are also the hotbar. Add, move/combine, split, discard and sort operations mutate only validated slot dictionaries and expose conservation-friendly return values. `InventoryPanel` translates drag, right-click and button input into manager API calls; it never owns stack rules. A pooled ground drop is decremented only by the quantity the inventory confirms, so a full inventory leaves the remainder active in the world.

Durable items are individual stack-size-one slot objects with an integer `durability` field. Sorting preserves each instance, discarding carries the field into `WorldDropPool`, and pickup passes it back to the inventory. `ChunkStreamManager` derives the active tool from the selected hotbar slot, applies catalog power only when the resource accepts that tool kind, then consumes one durability for an accepted hit. A broken tool is removed exactly once.

## Crafting ownership

`data/recipes.json` defines stable station IDs, ingredients, outputs and discovery requirements. `RecipeCatalog` validates every station, material, output and unlock item against the canonical item catalog. `CraftingSystem` owns discovery state and crafting rules; `CraftingPanel` displays recipe views and forwards a recipe ID without changing inventory data directly.

Each craft clones the complete inventory, deducts inputs and adds output on that clone, then commits the normalized snapshot only when every operation succeeds. Insufficient materials, a missing station, a locked recipe or missing output capacity therefore leaves the original slots byte-for-byte unchanged. Possessing a station item remains backward-compatible, while V3.2 also supplies workbench/campfire availability from bounded proximity to a placed player building.

## Combat ownership

`data/weapons.json` is the canonical source for stable weapon IDs, damage, attack speed, range, hitbox width, active duration, knockback, stamina cost and combo multipliers. `WeaponCatalog` validates weapon values and sword-item references. `AttackSequenceModel` owns cooldown/combo timing, normalized facing and the per-attack set of already-hit target instance IDs; it has no scene-tree dependency.

`PlayerCombatController` translates an accepted attack into a short-lived `Area2D` rectangle on collision mask 4/“Enemy”. It sends an immutable attack payload only to bodies implementing `receive_attack`. Target damage remains target-owned and uses `DamageCalculator`; the controller consumes sword durability only after the first accepted contact. `CombatHud` displays event data and owns no damage or timing rules.

`PlayerCombatState` owns defense, hit invulnerability, death count, alive/dead status and safe respawn position. `PlayerCharacter` owns health and physical knockback, granting roll invulnerability through the state API. A lethal result emits one death event; `world_sandbox.gd` asks the stream manager to deposit inventory, respawns the player synchronously and requests a persistence update.

`GraveModel` owns a versioned list of layer-qualified graves and transfers normalized inventory snapshots transactionally. Surface and underground use their layer names; a dungeon uses its full entrance-derived ID, so identical local coordinates in different dungeons remain isolated. `ChunkStreamManager` renders only markers in the active scope, prioritizes a nearby scoped grave over resource interaction and includes grave state in persistence. Partial reclaim retains every unaccepted remainder. A non-surface death stores the grave before the sandbox switches to the established surface respawn.

## Enemy ownership

`data/enemies.json` defines the five stable enemy IDs, allowed world layers, role, movement profile, health/defense, awareness distances, attack timing and canonical drop rules. `EnemyCatalog` validates every biome, layer, role and item reference. Surface/cave candidates derive from world seed, signed chunk coordinate, slot number and pure generation queries. Dungeon elite/Boss candidates derive directly from immutable feature markers and stable dungeon-qualified IDs. Runtime enemy placement therefore remains reproducible without becoming part of generation-format-4 surface bytes.

`EnemyStateMachine` is a scene-free eight-state model. `EnemyBase` owns health, physical motion, hurt/knockback, player damage and visuals; it cannot change population rules. Ground and flying profiles all use `CharacterBody2D` collision against the World layer. A collision selects a stable tangent for a short avoidance window, allowing pursuit around finite obstacles without passing through their polygons.

`EnemyDirector` alone owns active nodes and spawn/despawn cooldowns. It rejects candidates inside the viewport plus a 96-pixel margin or inside the 760-pixel minimum radius, caps the population at 18 and each chunk at three candidates, stops complex state ticks past 920 pixels, and unloads entities past 1700 pixels. Its planner cache is pruned to the current 49-chunk preload square on every population update. Death removes the active identity once and forwards deterministic drops into the existing bounded `WorldDropPool`; accepted pickups then follow the canonical inventory path.

## NPC ownership

`data/npcs.json` defines six stable roles, name pools, services, dialogue by time phase, complete-day schedules and merchant offer/buy tables. `NpcCatalog` validates schedule continuity, service IDs and every traded item against `ItemCatalog`. `NpcPlanner` combines those definitions with deterministic village markers; elder, merchant and innkeeper receive plaza fallbacks when terrain rejects their intended house, preserving access to core services without changing generated village cells.

`NpcPathfinder` resolves deterministic cardinal paths across the village overlay. `NpcActor` owns only presentation and movement along a supplied path; `NpcDirector` owns bounded activation, schedule transitions, surface-layer sleep, proximity interaction and atomic inventory transactions. NPCs outside the surface layer are released entirely and later reconstructed from seed. `NpcInteractionPanel` only renders immutable interaction snapshots and forwards item IDs or a sleep request.

`NpcWorldState` persists dialogue/trade counts, currency totals and last interaction days under stable village-qualified NPC IDs. `RelationshipCatalog` validates five attitude tiers, per-role gift preferences, price modifiers and one-time rewards. `RelationshipState` alone owns signed affection, last-gift day, claimed rewards and village reputation; completed trades and gifts update it through `NpcDirector`, while `NpcInteractionPanel` only renders the resulting snapshot. Current position, route and activity are session state re-derived from time. Inn sleep is owned by `world_sandbox.gd`: it advances `DayNightCycle` to the next dawn, restores player condition and requests a normal save.

## Quest ownership

`QuestCatalog` validates stable IDs, main/side categories, acyclic prerequisites, canonical item/enemy/landmark/NPC targets and reward items. `QuestState` is the sole owner of accepted records, objective counters, failure counts, tracking and claimed status. Inventory and exploration objectives synchronize to current canonical snapshots; enemy and NPC events increment only matching active objectives. `ChunkStreamManager` coordinates these sources and performs reward delivery against `InventoryModel`, while `QuestJournalPanel` only renders quest views and forwards IDs. A failed capacity check restores the inventory and leaves the quest completed but unclaimed.

## Faction ownership

`FactionCatalog` validates exactly four stable faction IDs, five ordered standing tiers, all six unique pairwise relations, unique NPC/enemy membership and canonical shop items. `FactionState` alone owns signed standing, bounded event history, one-time discovery credit and control-point ownership. `ChunkStreamManager` translates completed trades, claimed quests, discoveries and enemy defeats into catalog-defined standing actions; `FactionPanel` renders immutable views and forwards only faction/item IDs. Shop settlement clones the complete inventory and commits currency, stock and standing only after all output fits.

Generated villages remain seed-derived landmarks. Discovering one registers a stable control point keyed by its marker ID; contest influence and ownership are player progression overlays, never mutations of village cells or generation checksums.

## World-event ownership

`WorldEventCatalog` validates exactly eight roadmap event IDs, schedule bounds, objective contracts and composable surface effects. `WorldEventPlanner` derives a repeatable permutation and absolute in-game start/end times solely from world seed and slot index; it does not read wall-clock time, scene nodes or save files.

`WorldEventState` alone owns the next timetable slot, active records, objective counters and the bounded 48-entry outcome history. It activates due plans at the player's current chunk, resolves survival events at their end, expires unmet objectives and fast-forwards old schedules by retaining only the bounded relevant tail. Stable instance IDs prevent duplicate active/history entries. `ChunkStreamManager` translates canonical trade, harvest, enemy, exploration, Boss and NPC events into progress and composes event effects with weather; `WorldEventPanel` only consumes immutable status views.

## Region-progression ownership

`RegionProgressionCatalog` validates the 6×6-chunk partition, five ordered danger tiers, enemy scaling bounds, equipment-score slots, world-progress source values, one-time rewards and three regional-Boss gates. `RegionProgressionModel` maps signed chunks to regions with floor division and derives each enemy level/elite roll solely from world seed, stable spawn ID, layer and role. These values never alter `ChunkData` or generation checksums.

`RegionProgressionState` alone owns discovered region IDs, deduplicated progress-source records and one-time reward claims. Progress points are recomputed from validated source entries rather than trusting a serialized total. `ChunkStreamManager` records canonical discovery, elite, quest, event, dungeon and Boss outcomes; `EnemyDirector` consumes only the unlocked-Boss view, while `RegionProgressionPanel` renders immutable status and forwards a reward-claim request. Reward settlement clones and fully restores `InventoryModel` if any output cannot fit.

## Persistence ownership

`WeatherCatalog` validates the four stable weather IDs, transition/duration bounds, particle/audio presentation and biome weights. `WeatherSystem` derives a deterministic weather segment from world seed, 6×6-chunk region, segment and current biome, then exposes one immutable blended snapshot. `WeatherOverlay`, `AudioCuePlayer`, `ChunkStreamManager` and `EnemyDirector` consume that snapshot without owning weather selection. Weather remains a runtime overlay, so generation-format-4 bytes and collected-resource keys do not change.

`SaveManager` is an autoload because it must survive scene changes and join outstanding file tasks at shutdown. It owns world selection, schema validation, immutable save snapshots and last-error state. It never asks `PlayerCharacter` to write a file: the player and resource systems expose plain dictionaries, and `world_sandbox.gd` orchestrates the save request.

`SaveWriteJob` receives a deep-copied snapshot and performs JSON transaction writes and backup copies on `WorkerThreadPool`. It owns no nodes and calls no UI or gameplay APIs. Completion returns duration, difference-file count and an actionable error; `SaveManager` publishes that result on the main thread.

World metadata, player attributes and generated-world differences are separate documents. Collected resource keys, player-building records, farming plots and interacted animals are grouped by mathematical chunk coordinate. Only groups with at least one permanent change are written, and a successful save removes no-longer-retained difference files, so visiting, unloading or clearing the final mutable overlay from an otherwise unmodified chunk cannot leave stale data. See `docs/save-format.md` for the normative schema.

Save format 25 adds player-owned homestead selection metadata cross-validated against chunk-owned beacon placements on top of format-24 automation. Formats 2–24 are accepted only through explicit migrations. Generation remains format 5 because homesteads, automation, equipment, processing devices, animals, plots and placements are mutable state rather than generated terrain bytes.

V0.11 enemies are runtime challenge entities rather than permanent world differences. Their base candidates, active AI state and respawn cooldowns are intentionally not serialized. Canonical enemy-drop items become normal inventory entries when picked up and are therefore persisted by the unchanged inventory schema 2.

## Adventure-loop ownership

`DayNightCycle` and `WeatherSystem` are scene-free environment models driven by persisted seconds and weather-state fields. `DayNightOverlay`, `WeatherOverlay` and `MilestoneHud` consume event snapshots and own no selection, timing or progression rules.

`MilestoneCatalog` validates ruin search limits, guardian combat values and the canonical reward item. `RuinPlanner` samples a bounded chunk ring using only seed-derived ranks and pure terrain queries, yielding exactly one stable land landmark. The landmark remains outside `ChunkData`, preserving every generation-v4 fixture.

`RuinEncounter` owns discovery, Boss activation, core interaction and presentation. `RuinGuardian` owns its physical combat state and emits one terminal defeat event. `MilestoneState` enforces the ordered discover → defeat → claim transition and rejects impossible snapshots. Reward insertion uses `InventoryModel`; a full inventory leaves the core claimable, while a committed claim can never mint a second item.

`AudioCuePlayer` generates short bounded PCM waveforms locally and maps combat, interaction and milestone events to basic cues. It contains no gameplay decisions and requires no downloaded audio or network service.

## V3.0 quest and world-choice ownership

`QuestCatalog` validates 24 fixed templates, four bounded random-contract rules and three key world choices as one data contract. `QuestGenerator` is a pure deterministic service: world seed, stable region ID, in-game day and offer slot fully determine the generated definition. It never consumes global randomness or scene state.

`QuestState` schema 2 owns accepted fixed/generated records, exact generated definitions and region/day boards. Boards contain three unique offers; generated storage is capped at 96 and pruning removes only complete old boards whose offers are terminal and untracked. This keeps saves bounded without changing an accepted contract after a catalog or generator revision.

`WorldChoiceState` owns one immutable record per choice. It verifies the prerequisite main quest, applies configured faction deltas and adds the exact `world_choice` progress source as one transaction. Any failure restores both faction and progression snapshots, while the stored record prevents duplicate settlement.

`ChunkStreamManager` supplies the current stable region and saved game day, routes canonical quest progress, and emits complete journal/choice views. `QuestJournalPanel` is presentation only. Save format 17 migrates quest schema 1 to schema 2 without changing fixed entries and initializes an empty world-choice schema; generation format remains 5 because all new state is a progression overlay.

## V3.1 survival ownership

`SurvivalCatalog` validates the three bounded attributes, environmental modifiers, four effect definitions and canonical food recovery entries from `data/survival.json`. `SurvivalState` alone owns hunger, body temperature, wetness, exposure timers and active effects. Its update API consumes an immutable environment snapshot and returns only damage, movement and presentation results; it does not read scene nodes, inventory or settings.

`world_sandbox.gd` composes biome, weather, phase, world layer, water contact, heat proximity and player activity on the main thread. It applies returned damage through `PlayerCharacter`, passes the composed speed multiplier into existing movement rules, and emits an immutable HUD view. `ChunkStreamManager` performs atomic selected-slot food removal; only a successful removal is followed by catalog-driven recovery in `SurvivalState`.

`SurvivalHud` is presentation-only. `SettingsManager` owns the `gameplay/survival_enabled` preference; disabling the rule pauses attribute/effect mutation and environmental damage without deleting the saved state. Save format 18 persists survival schema 1, while every older supported format receives neutral attributes, zero exposure and no active effects. Generation remains format 5 because no generated cell, feature, spawn ID or checksum changes.

## V3.2 player-building ownership

`BuildingCatalog` validates the nine stable blueprint IDs, three placement slots, canonical item costs, collision/support flags, interaction kinds, range, capacity, refund and proximity limits from `data/buildings.json`. `BuildingState` alone owns stable placement IDs, rotation, door-open state and normalized chest contents. Preview is pure against an immutable context; placement, demolition and storage transfer clone the complete inventory and commit only after all material/capacity checks pass.

`ChunkStreamManager` composes preview context from the active surface chunk, player tile, water, uncollected resources and generated structure/village overlays. A successful mutation refreshes only the owning renderer and updates nearby workstation/heat consumers. `CraftingSystem` accepts the resulting external station IDs without owning world queries; `world_sandbox.gd` combines player-built heat with the established torch/cave heat path. Door and chest interaction use the normal `E` priority chain.

`PlayerBuildingLayer` owns three shared-atlas `TileMapLayer` batches for ground, structure and roof. Solid definitions carry World-layer collision; an open door selects a dedicated collision-free atlas variant. `BuildingPreview` and `BuildingPanel` are presentation-only and never mutate inventory or state directly.

Save format 19 reconstructs global `BuildingState` from `placed_buildings` arrays in surface chunk differences. `player.json` contains no duplicate building copy, underground differences reject placements, and stale files are removed when their final difference disappears. Format 18 and older inputs ignore any impossible legacy placement field and initialize no structures. Generation remains format 5 and all canonical generation checksums are unchanged.

## V3.3 agriculture ownership

`FarmingCatalog` validates the four stable crop IDs, seed and quality-output items, stage counts, day requirements, regrowth rules, fertilizer effects, weather multipliers, interaction range and global plot cap from `data/farming.json`. `FarmingState` alone owns stable signed-coordinate plot IDs, tilled/watered/fertilized state, crop growth, care history, stage, maturity and harvest count. Tilling, sowing, fertilizing and harvesting simulate inventory changes before committing them.

`ChunkStreamManager` supplies immutable active-surface context and prevents a farm plot from overlapping water, resources, generated overlays or a player building. It advances plots from saved game-day boundaries and the canonical weather ID, then refreshes only affected active renderers. Rain supplies water automatically; snow and sandstorms apply catalog growth multipliers. Quality is derived from world seed, stable plot identity, care days and harvest count, so reload and chunk order cannot reroll an outcome.

`FarmingChunkLayer` batches tilled soil, wet soil, crop stages and mature markers in one shared-atlas overlay. `FarmingPanel` displays immutable crop/target/weather views and forwards only selected crop and action requests. Neither presentation component owns inventory or simulation decisions.

Save format 20 reconstructs global `FarmingState` from `farming_plots` arrays in surface chunk differences. `player.json` contains no second copy, underground differences reject plots, and farm-only files are removed when their final plot disappears. Format 19 and older inputs ignore impossible backported farm fields and initialize no plots. Generation remains format 5 and the canonical checksum is unchanged.

## V3.4 husbandry ownership

`HusbandryCatalog` validates the three required species, canonical feed/product items, biome rules, taming and breeding thresholds, adulthood, cooldowns, product intervals, sleep phases, interaction ranges and population caps from `data/husbandry.json`. `HusbandryPlanner` owns only deterministic untouched candidates. It derives a stable wild ID, species, sex and dry tile from world seed plus signed global cell and never persists or mutates generated bytes.

`HusbandryState` alone owns interacted animals, friendship, taming, feed reserve, saved-day simulation, ready products, sleep, breeding cooldown and juvenile generation. Feeding and collection simulate the complete inventory before commit. Breeding validates same species, opposite sex, adulthood, friendship, cooldown, range, nearby animal fences and an unoccupied child tile before creating one stable offspring record.

`ChunkStreamManager` supplies active surface context, canonical day/phase events and reciprocal building/farming/animal occupancy. It refreshes only affected active renderers; unloaded animal records still advance from their saved game day through the same bounded state model. `AnimalChunkLayer` and `HusbandryPanel` consume immutable views and own no inventory or simulation decisions.

Save format 21 reconstructs global `HusbandryState` from `husbandry_animals` arrays in surface chunk differences. `player.json` contains no duplicate animal copy, underground differences reject animals, stale husbandry-only files are removed, and the next birth ID is derived from stable offspring identities. Format 20 and older inputs ignore impossible backported fields and initialize no animals. Generation remains format 5 and the canonical checksum is unchanged.

## V3.5 processing ownership

`ProcessingCatalog` validates `data/processing.json`: cooking-pot and smelter station IDs, wood/coal fuel values, interaction radius, every multi-material input, output item and positive fuel cost. It contains no runtime inventory or building state.

`ProcessingSystem` owns transaction orchestration but no persisted fields. It resolves the nearest compatible processor from `BuildingState`, validates exact materials and output capacity through an `InventoryModel` clone, then commits inventory and station fuel as one rollback-safe operation. Fuel insertion follows the same rule. Recipe views are immutable combinations of catalog rules, inventory counts and nearest-device state.

`BuildingState` remains the sole owner of placed processor records. Only processor definitions may carry bounded `fuel_units` and non-negative `processed_count`; a processing operation decrements fuel and increments the count together. Devices with retained fuel reject demolition. `ChunkStreamManager` supplies the surface player tile, refreshes the owning renderer, and emits `processing_state_changed`; `ProcessingPanel` never mutates inventory or records directly.

Save format 22 stores processor fields inside the existing `placed_buildings` record in its owning surface chunk, so there is no duplicated player-level processing document or extra difference family. Format-21 records restore unchanged and cannot fabricate a cooking pot, smelter or fuel. Generation remains format 5 and the canonical checksum is unchanged.

## V3.6 equipment ownership

`EquipmentCatalog` validates six worn slots, four ordered quality tiers, four ordered rarity tiers, bounded affixes, set bonuses, enhancement and repair materials, and canonical item/weapon references from `data/equipment.json`. `EquipmentState` alone owns stable instance IDs, owned records and the slot-to-instance mapping. Import removes exactly one inventory item only after a complete equipment record can be created; inventory and equipment never own the same physical item simultaneously.

Quality, rarity and affix selection are derived from stable instance identity and definition ID. Equipping, unequipping, enhancing and repairing operate on the existing record and cannot reroll it. Enhancement and repair validate cloned inventory transactions before committing. Zero weapon durability disables that weapon's effective contribution while retaining the instance for repair.

`ChunkStreamManager` exposes immutable equipment views, comparisons and action APIs. It composes the worn attack bonus into outgoing attacks, the defense bonus into `PlayerCombatState`, and health/stamina bonuses into runtime maxima without mutating their persisted base values. `EquipmentPanel` is presentation-only and forwards explicit requests.

Save format 23 stores equipment-state schema 1 once in `player.json`; no chunk difference duplicates it. Format 22 and every earlier supported format initialize an empty equipment state with the next stable instance ID at one. Generation remains format 5 and the canonical checksum is unchanged.

## V3.7 automation ownership

`AutomationCatalog` validates `data/automation.json` against canonical building, processing and item catalogs. It owns the four required machine kinds, five-second cadence, twelve-tile connection span, throughput, automatic-smelter recipe list, sorter filters and the three performance limits. It contains no mutable machine or storage state.

`BuildingState` remains the sole persistence owner. Automation definitions receive enablement, last simulated game time, work status and completed-cycle fields; only automatic smelters may carry bounded automation fuel and a canonical refining recipe, and only sorters may carry a canonical filter. Non-machine records reject every automation field. Fuel-retaining machines reject demolition.

`AutomationSystem` is scene-free. It copies the complete building snapshot, resolves storage along quarter-turn direction, applies one transfer or refining transaction at a time, and asks `BuildingState` to validate the entire result before commit. Conveyors and storage links move bounded quantities, sorters select only their configured item, and automatic smelters pull exact inputs/fuel before pushing a complete output stack. Missing inputs, full outputs and invalid connections produce explicit status without partial settlement.

`ChunkStreamManager` advances automation from saved game time rather than renderer lifetime, so unloaded chunks follow the same deterministic path. Each advance is bounded to 128 machines, 64 successful operations and 720 catch-up ticks per machine; excess work becomes an explicit throttled/discarded result. Only changed active renderers refresh. `AutomationPanel` consumes immutable views and forwards toggle, recipe and filter requests without owning gameplay state.

Save format 24 stores automation state inside the existing `placed_buildings` arrays in the owning surface chunk. Format 23 and earlier records never import an automation piece, so migration preserves ordinary floors, storage and processors without fabricating a machine, time cursor, fuel, recipe, filter or completed cycle. Generation remains format 5 and the canonical checksum is unchanged.

## V4.0 homestead ownership

`HomesteadCatalog` validates the marker piece, 24-tile management radius, three-base cap, 32-tile minimum spacing, 120-second travel cooldown and stable default names from `data/homestead.json`. `BuildingState` remains the only owner of physical homestead beacons and enforces their count and spacing during preview, placement and restore.

`HomesteadState` owns only the logical base names, current-home selection, next display-name number and last successful travel time. Every base ID is the corresponding `surface:<x>:<y>:structure` beacon placement ID. Restore and save paths cross-validate the complete base set against `BuildingState`; adding or removing a marker synchronizes this metadata immediately, so a second owner can never fabricate or retain a physical beacon.

Base status is derived rather than stored. The state assigns every building, farm plot and interacted animal to the nearest beacon within its configured radius, then composes the eight roadmap steps for shelter, storage, farming, husbandry, cooking, smelting, enhancement and automation. Overlapping ranges resolve by distance and stable base ID. `HomesteadPanel` consumes this immutable view and forwards only home-selection or travel requests.

`ChunkStreamManager` performs home travel as a safe layer relocation: dungeon requests are rejected, pending generation is drained, the surface layer is restored when necessary, the player is moved to the exact beacon tile, and only then is the cooldown committed. Save format 25 stores logical home metadata once in `player.json` while the beacon remains in its owning surface chunk. Format 24 synchronizes only real compatible markers and cannot invent a base or cooldown. Generation remains format 5 and the canonical checksum is unchanged.
