# Save Format Contract

## Version

- Game version: `4.1.0`
- Save version: `26`
- Generation version: `6`
- Inventory schema: `2`
- Crafting-state schema: `1`
- Combat-state schema: `1`
- Grave-state schema: `1`
- Milestone-state schema: `1`
- Weather-state schema: `1`
- Dungeon-state schema: `1`
- Exploration-state schema: `1`
- Regional-Boss-state schema: `1`
- NPC-state schema: `1`
- Relationship-state schema: `1`
- Quest-state schema: `2`
- World-choice-state schema: `1`
- Faction-state schema: `1`
- World-event-state schema: `1`
- Region-progression-state schema: `1`
- Survival-state schema: `2`
- Equipment-state schema: `1`
- Homestead-state schema: `1` (logical metadata cross-validated against surface beacons)
- Building-state schema: `1` (reconstructed from surface chunk differences)
- Farming-state schema: `1` (reconstructed from surface chunk differences)
- Husbandry-state schema: `1` (reconstructed from surface chunk differences)
- Boat-state schema: `1` (reconstructed from surface chunk differences)
- Storage root: `user://saves`

Save and generation formats are independent. Save version 26 adds chunk-owned deployed-boat differences and survival-state schema 2 (oxygen) on top of format-25 homesteads. Normal enemy/NPC motion remains session state; survival/progression/equipment/home-selection records are player-owned, while placed structures, automation machines, homestead beacons, farm plots, interacted animals and deployed boats are world differences grouped by owning surface chunk. Versions 2 through 25 are accepted only by documented migration paths; any other save version or an unsupported generation version is rejected with a file-specific error.

V4.1.0 advances generation format to 6 because the island-biome classification and the water-resource channel change generated biome and resource bytes. Formats 4 and 5 remain loadable; the next transactional save rewrites metadata under generation 6 while every permanent difference keeps its coordinate-keyed identity. Weather and the event timetable resume from saved game-time fields and deliberately add no wall-clock elapsed time; husbandry uses saved game-day boundaries and automation/home travel use saved game seconds only. Formats 2–6 receive deterministic weather; formats 2–7 receive `player_layer=surface`; formats 2–8 receive an empty dungeon schema; formats 2–9 receive empty exploration/regional-Boss schemas; formats 2–10 receive an empty NPC schema; formats 2–11 receive an empty relationship schema; formats 2–12 receive an empty quest schema; formats 2–13 receive all four configured default faction standings; formats 2–14 receive an empty world-event schema; formats 2–15 receive empty region progress; formats 2–16 receive empty world choices; formats 2–17 receive neutral survival state; formats 2–18 receive empty building differences; formats 2–19 receive empty farming differences; formats 2–20 receive empty husbandry differences. Format 21 contains no processor definitions or fields and migrates without fabricated devices or fuel. Formats 2–22 receive empty equipment state. Format 23 and every earlier format import no automation piece or machine fields. Format 24 and every earlier format initialize empty logical homestead state, then synchronize only real valid beacon placements. Format 25 and every earlier format initialize an empty boat state plus survival schema 2 with full oxygen. Format 16 quest schema 1 is lifted to schema 2 with every fixed entry and tracked ID preserved. A format-9/generation-4 world retains coordinate-keyed resource/chest differences while metadata advances to the current generation on the next save.

## Directory layout

```text
saves/
└── world_<stable-local-id>/
    ├── world.json
    ├── player.json
    ├── chunks/
    │   ├── surface/
    │   │   └── <chunk_x>_<chunk_y>.json
    │   └── underground/
    │       └── <chunk_x>_<chunk_y>.json
    └── backups/
        └── backup-<unix-time>-<suffix>/
            ├── world.json
            ├── player.json
            └── chunks/
                ├── surface/*.json
                └── underground/*.json
```

The directory ID is local and collision-resistant; the player-facing name remains in metadata. Paths never use the unsanitized world name.

## World metadata

`world.json` is a UTF-8 JSON object:

```json
{
  "save_version": 26,
  "generation_version": 6,
  "game_version": "4.1.0",
  "world_id": "world_123456789",
  "world_name": "无尽边境",
  "seed_text": "无尽边境",
  "seed": 6266252184503203218,
  "created_at": "2026-08-02T14:00:00",
  "last_played_at": "2026-08-02T14:30:00",
  "game_time_seconds": 1800.0,
  "weather_state": {
    "schema_version": 1,
    "current_id": "RAIN",
    "target_id": "CLEAR",
    "region": [-1, -1],
    "segment": 2,
    "weather_elapsed": 42.5,
    "weather_duration": 126.0,
    "transition_elapsed": 3.0
  },
  "player_layer": "dungeon"
}
```

The 64-bit seed is stored together with its original text so the UI can reproduce the user's input without recalculating identity.

## Player state

`player.json` stores only player-owned state:

```json
{
  "save_version": 26,
  "position": [-2048.5, 1024.25],
  "health": 73.0,
  "maximum_health": 100.0,
  "stamina": 41.0,
  "maximum_stamina": 100.0,
  "active_tool": "pickaxe",
  "world_layer": "dungeon",
  "inventory": {
    "schema_version": 2,
    "slot_count": 24,
    "hotbar_slot_count": 8,
    "selected_hotbar_slot": 0,
    "slots": [
      {"item_id": "stone_axe", "quantity": 1, "durability": 23},
      {"item_id": "wood", "quantity": 7},
      {"item_id": "stone", "quantity": 3},
      {}, {}, {}, {}, {}, {}, {}, {}, {},
      {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
    ]
  },
  "crafting_state": {
    "schema_version": 1,
    "discovered_items": ["branch", "fiber", "stone", "wood"]
  },
  "combat_state": {
    "schema_version": 1,
    "defense": 4.0,
    "invulnerability_remaining": 0.25,
    "death_count": 2,
    "status": "alive",
    "respawn_position": [-2016.0, 992.0]
  },
  "grave_state": {
    "schema_version": 1,
    "next_id": 1,
    "graves": []
  },
  "milestone_state": {
    "schema_version": 1,
    "ruin_discovered": true,
    "boss_defeated": true,
    "reward_claimed": false
  },
  "dungeon_state": {
    "schema_version": 1,
    "current_dungeon_id": "dungeon_-17_29",
    "runs": [
      {
        "dungeon_id": "dungeon_-17_29",
        "anchor_chunk": [-1, 0],
        "return_position": [-528.0, 944.0],
        "attempt_count": 1,
        "completed": false,
        "boss_defeated": false,
        "key_count": 1,
        "collected_keys": ["dungeon_-17_29:key:-15:30"],
        "unlocked_doors": [],
        "triggered_traps": ["dungeon_-17_29:trap:-14:30"],
        "opened_chests": [],
        "defeated_elites": []
      }
    ]
  },
  "exploration_state": {
    "schema_version": 1,
    "next_custom_id": 2,
    "discovered_chunks": [[-2, -5], [-1, -5], [0, -5], [-2, -4], [-1, -4], [0, -4], [-2, -3], [-1, -3], [0, -3]],
    "markers": [
      {"id": "home:respawn", "type": "home", "display_name": "安全营地", "world_tile": [-48, -112], "color": "fff0a8", "travel_enabled": true, "completed": false},
      {"id": "custom:1", "type": "custom", "display_name": "自定义标记", "world_tile": [-46, -110], "color": "f0ca58", "travel_enabled": false, "completed": false}
    ]
  },
  "regional_boss_state": {
    "schema_version": 1,
    "defeated_ids": ["grove_titan"]
  },
  "npc_state": {
    "schema_version": 1,
    "records": [
      {
        "npc_id": "village:-1:2:npc:1",
        "talk_count": 3,
        "trade_count": 2,
        "coins_spent": 6,
        "coins_earned": 3,
        "last_talk_day": 4,
        "last_trade_day": 4
      }
    ]
  },
  "relationship_state": {
    "schema_version": 1,
    "npcs": [
      {"npc_id": "village:-1:2:npc:1", "affection": 27, "last_gift_day": 4, "gift_count": 3, "claimed_rewards": ["friendly_gift"]}
    ],
    "villages": [
      {"village_id": "village:-1:2", "reputation": 14}
    ]
  },
  "quest_state": {
    "schema_version": 2,
    "tracked_id": "side_slime_hunt",
    "entries": [
      {"quest_id": "side_slime_hunt", "status": "active", "progress": [{"objective_id": "slimes", "current": 2}], "failure_count": 0}
    ],
    "generated_quests": [],
    "boards": []
  },
  "world_choice_state": {
    "schema_version": 1,
    "records": [
      {"choice_id": "core_destination", "option_id": "village_vault", "resolved_day": 5}
    ]
  },
  "faction_state": {
    "schema_version": 1,
    "standings": [
      {"faction_id": "ash_raiders", "standing": -51},
      {"faction_id": "frontier_union", "standing": 3},
      {"faction_id": "merchant_guild", "standing": 8},
      {"faction_id": "pathfinders", "standing": 2}
    ],
    "control_points": [
      {"point_id": "village:-1:2", "marker_type": "village", "owner_faction_id": "frontier_union", "challenger_faction_id": "", "influence": 100}
    ],
    "discoveries": ["village:-1:2"],
    "events": [
      {"event_id": 1, "faction_id": "pathfinders", "delta": 2, "before": 0, "after": 2, "source": "discovery:village:village:-1:2"}
    ],
    "next_event_id": 2
  },
  "world_event_state": {
    "schema_version": 1,
    "next_slot": 3,
    "active": [
      {
        "instance_id": "world-event:2:village_raid",
        "event_id": "village_raid",
        "start_seconds": 690.0,
        "end_seconds": 930.0,
        "target_chunk": [-2, 1],
        "progress": 1,
        "goal": 3,
        "status": "active"
      }
    ],
    "history": [
      {
        "instance_id": "world-event:1:caravan_passage",
        "event_id": "caravan_passage",
        "start_seconds": 390.0,
        "end_seconds": 570.0,
        "target_chunk": [-2, 1],
        "progress": 2,
        "goal": 2,
        "status": "completed",
        "resolved_seconds": 480.0
      }
    ]
  },
  "region_progression_state": {
    "schema_version": 1,
    "sources": [
      {"source_type": "region_discovered", "source_id": "region:-1:0", "points": 2},
      {"source_type": "elite_defeated", "source_id": "region:-1:0|surface:-3:2:slot:4", "points": 2},
      {"source_type": "regional_boss_defeated", "source_id": "grove_titan", "points": 15}
    ],
    "regions": [
      {"region_id": "region:-1:0", "danger_level": 1, "reward_claimed": true}
    ]
  },
  "survival_state": {
    "schema_version": 2,
    "hunger": 62.0,
    "body_temperature": 35.2,
    "wetness": 78.0,
    "oxygen": 45.0,
    "effects": [
      {"effect_id": "poison", "remaining_seconds": 20.0, "tick_elapsed": 1.0}
    ],
    "exposures": {
      "poison": 5.0,
      "burning": 0.0,
      "frostbite": 1.0
    }
  },
  "equipment_state": {
    "schema_version": 1,
    "next_instance_id": 3,
    "records": [
      {"instance_id": 1, "item_id": "copper_sword", "quality_id": "fine", "rarity_id": "rare", "durability": 96, "enhance_level": 2, "affixes": ["keen", "guarded"]},
      {"instance_id": 2, "item_id": "explorer_charm", "quality_id": "standard", "rarity_id": "uncommon", "durability": 80, "enhance_level": 0, "affixes": ["swift"]}
    ],
    "equipped": {"weapon": 1, "accessory_1": 2}
  },
  "homestead_state": {
    "schema_version": 1,
    "active_base_id": "surface:-2:-130:structure",
    "next_base_number": 2,
    "last_teleport_seconds": 1680.0,
    "bases": [
      {
        "base_id": "surface:-2:-130:structure",
        "display_name": "拓荒家园",
        "world_tile": [-2, -130],
        "established_seconds": 960.0
      }
    ]
  }
}
```

The slot array always contains exactly 24 objects in player-defined order. Empty objects represent empty slots; occupied entries reference a known stable item ID and contain `1..max_stack`. Durable items have stack limit one and an integer `durability` in `1..maximum`. Slots 0–7 are the hotbar, and the selected index must be `0..7`.

Crafting discoveries are sorted known item IDs. They persist even after the player consumes or discards the last copy of an item, while loading also discovers any items currently in the inventory. JSON numbers are validated and reconstructed through `InventoryModel` and `CraftingSystem` before gameplay receives a normalized snapshot.

Combat state stores non-negative defense, remaining hit protection, cumulative death count, `alive`/`dead` status and a signed safe respawn point. A normal lethal hit deposits inventory and respawns synchronously, so committed gameplay saves normally contain `alive`; `dead` is accepted on load and immediately resolves to the saved safe position.

Each grave entry contains a positive unique `id`, signed `position`, `world_layer` (`surface`, `underground`, or a `dungeon_<x>_<y>` ID) and a complete inventory-schema-2 snapshot. `next_id` is greater than every existing grave ID. Pre-V1.6 entries without a layer normalize to `surface`. Empty graves are invalid and removed after complete reclaim. Partial reclaim writes every unaccepted stack back into a normalized grave snapshot, including individual durability; marker display and reclaim lookup never cross layers or dungeon identities.

Milestone state enforces the only valid order: ruin discovery, Boss defeat, then reward claim. A claimed reward without a defeated Boss, or a defeated Boss without a discovered ruin, is rejected. The canonical ruin position is re-derived from the world seed and is not duplicated in the save. A full inventory leaves `reward_claimed=false`, allowing a later retry without loss or duplication.

Dungeon state stores sorted, unique stable feature/spawn keys. `key_count + unlocked_doors.size()` must equal `collected_keys.size()`, and `completed` must equal `boss_defeated`. `world_layer=dungeon` requires a non-empty `current_dungeon_id` that references one listed run; surface/underground require it to be empty. Leaving an incomplete dungeon clears all transient arrays before the next attempt, while a completed run keeps them and does not increment its attempt count on revisit.

Exploration state stores sorted discovered chunk coordinates and normalized markers only inside those chunks. Marker IDs are unique; custom IDs use a positive `custom:<n>` suffix, never reuse `_next_custom_id`, and are capped at 32. Only markers with `travel_enabled=true` are valid fast-travel destinations. Regional Boss state stores a sorted unique subset of the three catalog IDs; a completed Boss marker remains visible but dimmed on the map.

NPC state stores at most 2,048 unique village-qualified NPC IDs. Talk/trade counts, coin totals and last interaction days are non-negative; presentation position, current schedule step and path are re-derived from world seed and time. Shop operations clone inventory, apply both sides, and commit only when every item fits, so a failed transaction never changes currency or stock.

Relationship state stores at most 2,048 unique NPC records and 512 village records. Affection and reputation are signed integers in `-100..100`; gift days/counts are non-negative, claimed reward IDs are unique, and records are sorted by stable ID. One NPC accepts at most one gift per saved game day. Gift consumption and threshold rewards share an inventory transaction, so insufficient reward capacity restores both inventory and relationship snapshots.

Quest state stores accepted fixed/generated records plus exact generated definitions and their boards. Each record contains the exact ordered objective IDs with bounded progress, one of `active`, `completed`, `claimed` or `failed`, and a non-negative failure count. The tracked ID must name an active or completed record. Completed/claimed records require every objective at its configured quantity, duplicate IDs are rejected, and active records cannot exceed the catalog limit. Each board contains exactly three definitions tied to one stable region/day identity; generated storage is capped at 96. Reward delivery is transactional; a full inventory leaves status `completed` for a later retry.

World-choice state stores at most one valid option and positive resolved day for each of the three configured choices. Availability is derived from claimed prerequisite quests, not trusted from the save. Faction deltas and the exact six-point world-progress source settle atomically; stored records prevent a choice from being applied twice.

Faction state contains exactly one signed standing for each of the four catalog factions. Discoveries and control points use unique stable marker IDs; control owners/challengers must be known factions and influence is `0..100`. Event IDs are strictly increasing, the retained list is capped at 32, and each event's `after - before` must equal its stored delta. Trades, quest claims and shop purchases settle exactly once; full-inventory faction purchases restore the complete inventory and do not append standing events.

World-event state stores a non-negative next-slot cursor, at most one active record and at most 48 historical records. Instance IDs are unique across both arrays and reference one of the eight catalog events. Start/end times are ordered, target chunks contain two signed integers, progress is bounded by the catalog objective goal, active records cannot already meet their goal, and completed/expired history must agree with progress plus `resolved_seconds`. Timetable entries are reconstructed from world seed and cursor; no future plan list is serialized.

Region-progression state stores no trusted total. Every source record contains a configured source type, stable source ID and the exact catalog point value; duplicate composite IDs or altered values are rejected. Every region ID parses to signed coordinates, its saved danger must equal the coordinate-derived tier, and a matching discovery source must exist. Elite sources reference a discovered region. Reward claims remain one-time and inventory settlement is atomic. Enemy level/elite rolls, equipment score, world level and Boss-unlock views are derived at runtime and are not duplicated in the save.

Survival state schema 2 stores hunger and wetness in `0..100`, body temperature in the catalog's supported range, oxygen in `0..100`, one unique record per known active effect and exactly the configured exposure keys. Durations, tick offsets and exposure values are finite and bounded; unknown effects, duplicate IDs or non-finite numbers reject the document. Environment inputs and the survival-enabled setting are runtime configuration and are not duplicated in the save. Formats 2–17 initialize neutral hunger, normal temperature, zero wetness/exposure and no effects; every schema-1 survival document migrates to schema 2 with full oxygen.

Equipment state stores a positive monotonic next-instance ID, sorted unique owned records and a slot-to-instance mapping. Each record references a canonical equipable item plus known quality, rarity and unique affix IDs; enhancement is `0..5`, durability is `0..maximum`, and zero durability intentionally preserves a repairable broken item. One instance can occupy at most one compatible slot, every equipped reference must resolve to an owned record, and the state contains no inventory copy. Formats 2–22 initialize `next_instance_id=1` with no records or worn slots.

Homestead state stores at most three unique base records, the active base reference, the next default-name number and a finite last successful travel time (`-1` before first use). Each base ID, signed tile and record count must exactly match one `homestead_beacon` in the reconstructed `BuildingState`; the physical marker is never duplicated here. Names are bounded to 24 characters, marker tiles obey the configured 32-tile spacing and the active ID must resolve whenever any base exists. Range assets and eight-step completion flags are derived at runtime and are not serialized. Formats 2–24 start with no logical base, then synchronize only compatible markers that actually exist in chunk differences.

Player-building state is intentionally absent from `player.json`. It is reconstructed from the surface chunk differences below, preventing two independently writable copies of the same world object.

Farming state is likewise absent from `player.json`. Tilled soil and every crop field are reconstructed from the one owning surface chunk difference, so a plot cannot diverge from a duplicated player-owned copy.

Husbandry state is also absent from `player.json`. Deterministic wild candidates are re-derived until first interaction; fed, tamed or bred animals are reconstructed from their one owning surface chunk difference. The next offspring counter is derived from stable `bred:<day>:<id>` records instead of storing a second global copy.

## Chunk differences

Generated terrain, climate, biomes, cave walls, unmodified resources and untouched wild animals are never written. A layer-specific chunk file exists only while it contains at least one permanent resource, chest, player-building, farming or interacted-animal change:

```json
{
  "save_version": 26,
  "generation_version": 6,
  "layer": "surface",
  "chunk": [-1, -5],
  "removed_resources": ["-1:-129:0"],
  "opened_chests": [],
  "placed_buildings": [
    {
      "placement_id": "surface:-2:-130:ground",
      "piece_id": "wood_floor",
      "world_tile": [-2, -130],
      "rotation": 0
    },
    {
      "placement_id": "surface:-2:-130:structure",
      "piece_id": "homestead_beacon",
      "world_tile": [-2, -130],
      "rotation": 0
    },
    {
      "placement_id": "surface:-4:-130:ground",
      "piece_id": "wood_floor",
      "world_tile": [-4, -130],
      "rotation": 0
    },
    {
      "placement_id": "surface:-4:-130:structure",
      "piece_id": "smelter",
      "world_tile": [-4, -130],
      "rotation": 0,
      "fuel_units": 4,
      "processed_count": 3
    },
    {
      "placement_id": "surface:-5:-130:ground",
      "piece_id": "wood_floor",
      "world_tile": [-5, -130],
      "rotation": 0
    },
    {
      "placement_id": "surface:-5:-130:structure",
      "piece_id": "automatic_smelter",
      "world_tile": [-5, -130],
      "rotation": 90,
      "automation_enabled": true,
      "automation_last_seconds": 1800.0,
      "automation_cycles": 12,
      "automation_status": "working",
      "automation_fuel_units": 4,
      "automation_recipe_id": "copper_ingot"
    }
  ],
  "farming_plots": [
    {
      "plot_id": "surface:-3:-131:farm",
      "world_tile": [-3, -131],
      "tilled_day": 3,
      "last_simulated_day": 7,
      "watered_day": 6,
      "crop_id": "wheat",
      "planted_day": 3,
      "growth_points": 4.0,
      "care_days": 4,
      "stage": 3,
      "mature": true,
      "fertilizer_id": "basic_fertilizer",
      "harvest_count": 0
    }
  ],
  "husbandry_animals": [
    {
      "animal_id": "wild:-1:-9",
      "animal_type": "chicken",
      "world_tile": [-4, -132],
      "sex": "female",
      "tamed": true,
      "friendship": 3,
      "birth_day": 1,
      "adult_day": 3,
      "last_simulated_day": 7,
      "last_fed_day": 6,
      "fed_until_day": 8,
      "last_product_day": 7,
      "product_ready": 2,
      "breeding_cooldown_until": 9,
      "sleeping": false,
      "generation": 0
    }
  ],
  "deployed_boats": [
    {
      "boat_id": "surface:-6:-135",
      "item_id": "rowboat",
      "world_tile": [-6, -135]
    }
  ]
}
```

Surface resource keys contain signed world tile X, signed world tile Y and stable resource code. Underground keys add the `underground:` prefix. On load, the generated chunk is unchanged; `ResourceHarvestState` hides keys listed by the matching difference layer. This guarantees that deterministic generation remains the source of truth and collected nodes cannot drop twice.

Each building record references one of the seventeen catalog pieces, a signed integer tile, a quarter-turn rotation and the exact stable ID derived from its `ground`, `structure` or `roof` slot. At most one record may occupy a tile/slot. Definitions that require a floor must have a matching ground record. Doors alone carry `door_open`; storage chests alone carry up to eight normalized item stacks, including validated durability for tools. Cooking pots and smelters alone carry integer `fuel_units` in `0..24` and non-negative `processed_count`; non-processors reject either field. Automation pieces alone carry boolean enablement, finite non-negative game-time cursor (or `-1` before initialization), non-negative cycles and a known work status. The automatic smelter additionally owns `0..24` fuel units and one of four automatic recipes; the sorter alone owns one known item filter. Non-machine records reject every automation field, and the global machine count may not exceed 128. Homestead beacons are limited to three, must be at least 32 Chebyshev tiles apart and must match the complete logical homestead record set. Duplicate IDs, unsupported upper layers, unknown pieces, invalid metadata or a record outside the file's declared chunk reject the save.

Each farming record uses the exact `surface:<tile_x>:<tile_y>:farm` identity and one signed tile owned by the declaring chunk. Tilled/simulated/watered/planted days, growth, care, stage, maturity, fertilizer and harvest count must form a valid catalog-backed crop state. Empty tilled soil omits `planted_day`; planted plots reference one of the four stable crops. A plot may not overlap a player-building placement. Duplicate IDs, unknown crops/fertilizer, impossible stage/maturity values or a record outside its chunk reject the save.

Each husbandry record references chicken, cow or sheep, one stable `wild:` or `bred:` identity, a signed owned tile, sex, taming/friendship, birth/adult day, last simulated/fed/product day, feed reserve, bounded ready-product count, breeding cooldown, sleep and generation. Wild taming must agree with its configured feed threshold; offspring must remain tamed. Animals may not share a tile or overlap a building/farm record. Unknown species, impossible day ordering, forged taming state or a record outside its declared surface chunk reject the save.

Each deployed-boat record uses the exact `surface:<tile_x>:<tile_y>` identity derived from its signed water tile and one canonical boat item. IDs and tiles are unique, every record belongs to its declaring surface chunk, and the global deployed count may not exceed the item's configured cap. Whether the tile is actually water, water-resource occupancy and other placement legality are enforced at deployment time exactly like building terrain checks; the save validates structure only. Session boarding state, boat orientation and motion are never serialized. Formats 25 and earlier import no boat records.

An underground difference uses the same signed coordinate plane:

```json
{
  "save_version": 26,
  "generation_version": 6,
  "layer": "underground",
  "chunk": [-1, -5],
  "removed_resources": ["underground:-17:-129:5"],
  "opened_chests": ["underground:-17:-129"],
  "placed_buildings": [],
  "farming_plots": [],
  "husbandry_animals": [],
  "deployed_boats": []
}
```

Opened-chest keys omit a resource code because a coordinate can own at most one derived cave chest. A full inventory does not add the key, so the same chest remains available without duplicating loot. Underground differences reject any non-empty player-building, automation, homestead, farming or husbandry array in V4.0.

An unmodified world may contain both layer directories but contains zero difference files. `SaveWriteJob` compares the complete retained difference set after writing a snapshot and removes obsolete JSON files from the two active layer directories; demolishing the final building, clearing the final plot or removing the final interacted animal in an otherwise empty chunk therefore removes that file. The regression fixture verifies two resource surface files, one building-only, one farming-only, one husbandry-only surface file and one underground file, then reloads every difference exactly.

Dungeon maps are finite derived data and do not create a third chunk-difference directory. Mutable dungeon keys live in `player.json` under `dungeon_state`; an active run is therefore restored without serializing a 32×32 room grid.

## Save lifecycle

- New world: metadata and initial player state are written synchronously before scene entry.
- Automatic save: every 30 seconds while a persistent world is active.
- Manual save: `Ctrl+S`, return to menu, or a normal window-close request.
- Settings: continue to use `user://settings.cfg` through `ConfigFile`.
- Shutdown: outstanding save tasks are joined before process exit.

Runtime state is copied into a small immutable snapshot on the main thread. `SaveWriteJob` writes JSON and copies backups through `WorkerThreadPool`; it never reads players, UI nodes or the scene tree. A completed job publishes its duration and difference-file count through the event bus.

## Transaction and backup rules

Each JSON document is first written to `<name>.tmp`. The prior valid document is moved to `<name>.previous`, the temporary file is committed, and the previous transaction file is removed only after success. If commit fails, the previous document is restored.

Manual saves copy the existing metadata, player document and difference files into a timestamped backup before overwriting. The five newest backup directories are retained. Backup deletion is restricted to descendants of the active world's `backups` directory.

## Corruption behavior

Loading validates readable JSON objects, current save version 26 or migratable versions 2–25, supported generation version, required metadata, matching layers, weather, player attributes, inventory, crafting, combat, graves, milestones, dungeon/exploration/regional-Boss/NPC/relationship/quest/faction/world-event/region-progression/world-choice/survival/equipment/homestead/boat invariants and all layer-difference arrays. Current-format worlds must use generation 6. Resource/chest keys plus building, farming, animal and boat coordinates require signed integers; every placement, plot, interacted animal and deployed boat must belong to the file's declared surface chunk, satisfy its complete schema and not overlap another mutable overlay. Processor-only fields additionally require a processor definition and bounded fuel; machine-only fields require a canonical automation definition, bounded time/cycles/fuel and valid recipe/filter IDs. Homestead metadata must match every physical beacon ID and tile exactly. Deployed boats require the exact tile-derived `surface:<x>:<y>` identity, a canonical boat item and the configured global cap. Dungeon keys require a valid entrance-derived scope. Parse failures include filename, parser line and message. Continue remains on the menu and displays `SaveManager.last_error`; it never silently starts a new world over damaged data.

## Format-2 through format-25 migration

V0.7 format-2 player documents stored `inventory` as an item-to-count dictionary. V0.10 validates the legacy fields, feeds those counts through canonical stack limits into a 24-slot inventory, assigns no invented tools and initializes crafting discoveries from the restored material slots.

V0.8 format-3 documents already contain 24 inventory slots under schema 1. V0.10 accepts and normalizes those non-durable slots under schema 2, initializes crafting discovery from the known contents and preserves slot order and hotbar selection.

V0.9 format-4 documents already contain inventory schema 2 and crafting-state schema 1. V0.10 preserves both objects exactly, initializes combat state with the last player position as the safe respawn point and creates an empty grave-state list. Unknown items, over-capacity counts, invalid slots or malformed documents fail with actionable migration errors rather than being truncated.

V0.10/V0.11 format-5 documents already contain combat-state and grave-state schema 1. V1.0 preserves them exactly and initializes a valid incomplete milestone state. The player can then discover the seed-derived ruin normally.

V1.0/V1.1 format-6 documents already contain milestone-state schema 1. V1.2 preserves all existing state and initializes deterministic clear weather at the saved world's seed; subsequent weather selection uses the player's region and biome.

V1.2–V1.5 format-7 documents already contain weather-state schema 1. V1.6 preserves every prior field and initializes both metadata and player state to the surface layer. Underground directories remain empty until the player enters a cave and creates a permanent difference.

V1.6 format-8 documents already contain the surface/underground layer and cave differences. V1.7 preserves them exactly and initializes an empty dungeon-state schema 1. Migration never invents an active dungeon or changes the saved layer.

V1.7 format-9 documents already contain dungeon-state schema 1 and may use generation format 4. V2.0 preserves all player-owned and coordinate-keyed difference state, initializes empty exploration/regional-Boss schemas and advances metadata to generation 5. The next transactional save rewrites active sparse differences under the current format.

V2.0 format-10 documents already contain exploration and regional-Boss schema 1 at generation format 5. V2.1 preserves them exactly and initializes an empty NPC-state schema 1; generated villagers then reappear from the unchanged seed without fabricated interaction history.

V2.1 format-11 documents already contain NPC-state schema 1. V2.2 preserves every interaction record and initializes empty relationship-state schema 1 arrays; no affection, reputation, gift or reward history is fabricated.

V2.2 format-12 documents already contain relationship-state schema 1. V2.3 preserves all NPC and village records and initializes an empty quest-state schema 1; no task is silently accepted or completed during migration.

V2.3 format-13 documents already contain quest-state schema 1. V2.4 preserves every task record and initializes faction-state schema 1 with the four configured default standings; it creates no discovery credit, event history or control points during migration.

V2.4 format-14 documents already contain faction-state schema 1. V2.5 preserves every standing, discovery, faction event and control point and initializes world-event-state schema 1 with cursor zero and empty active/history arrays. The first runtime time update deterministically catches the timetable up to saved game time without inventing successful outcomes.

V2.5 format-15 documents already contain world-event-state schema 1. V2.6 preserves the timetable cursor, objectives and bounded history and initializes region-progression-state schema 1 with empty source/region arrays. The first normal surface update discovers the player's actual current region; migration itself grants no points, unlocks or rewards.

V2.6 format-16 documents already contain region-progression-state schema 1 and quest-state schema 1. V3.0 preserves every fixed quest entry, objective count, status, failure count and tracked ID while adding empty generated-definition/board arrays under quest schema 2. It also initializes world-choice-state schema 1 with no records; migration never grants faction standing or world progress.

V3.0 format-17 documents already contain quest-state schema 2 and world-choice-state schema 1. V3.1 preserves them exactly and initializes neutral survival-state schema 1 with normal attributes, zero exposure and no active effects. Migration never fabricates hunger damage, wetness or environmental status.

V3.1 format-18 documents already contain survival-state schema 1 and have no defined player-building field. V3.2 preserves every player/progression/resource/chest record and reconstructs an empty building-state schema 1. Difference files below format 19 never import `placed_buildings`, so malformed or backported fields cannot fabricate structures during migration.

V3.2 format-19 documents already contain surface chunk-owned building-state schema 1 and have no defined farming field. V3.3 preserves every player/progression/resource/chest/building record and reconstructs an empty farming-state schema 1. Difference files below format 20 never import `farming_plots`, so malformed or backported fields cannot fabricate crops during migration.

V3.3 format-20 documents already contain surface chunk-owned building and farming schemas and have no defined husbandry field. V3.4 preserves every prior record and reconstructs an empty husbandry-state schema 1. Difference files below format 21 never import `husbandry_animals`, so malformed or backported fields cannot fabricate animals.

V3.4 format-21 documents already contain complete building, farming and husbandry differences but no processor definitions. V3.5 preserves every prior placement and accepts no fabricated processor-only fields; missing processor fields normalize only on actual V3.5 processor records. Migration creates no cooking pot, smelter, fuel or processed-operation count.

V3.5 format-22 documents already contain complete processing state but no player-owned equipment document. V3.6 preserves every prior player, inventory and chunk record and initializes equipment-state schema 1 with `next_instance_id=1`, no records and no worn slots. Migration does not convert legacy inventory weapons into equipment or roll any quality, rarity or affix.

V3.6 format-23 documents already contain complete equipment state but no automation definitions or machine fields. V3.7 preserves every ordinary building, storage, processor and player record while importing no automation piece from a pre-24 chunk difference. Migration therefore creates no enablement, time cursor, status, completed cycle, fuel, recipe or sorter filter.

V3.7 format-24 documents already contain complete automation state but no logical homestead document. V4.0 initializes empty home metadata and synchronizes only actual, valid `homestead_beacon` placements found in the reconstructed surface `BuildingState`; an ordinary format-24 world therefore gains no base, active home or cooldown. Any synchronized marker receives a stable default name and establishment time from the saved game clock.

V4.0 format-25 documents already contain complete homestead state but no oxygen field and no boat records. V4.1 lifts every survival-state document to schema 2 with neutral full oxygen, initializes an empty boat state and accepts generation formats 4, 5 and 6; the next transactional save rewrites metadata under format 26 and generation 6. Migration fabricates no boat, no drowning state and no island-specific content, and every permanent difference keeps its coordinate-keyed identity across the generation advance.

All paths update metadata and player state in memory to save format 26 and transactionally commit format 26 on the next save. Migration never serializes generated terrain or recreates unmodified chunk files.
