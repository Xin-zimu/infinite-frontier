# V4.2.0 季节系统 — 技术设计（design.md）

> 版本：V4.2.0 · 描述「怎么建（HOW）」
> 前置：`spec.md` 已确认。本设计严格基于已存在的 `SeasonCatalog` / `SeasonState` API，不重新设计核心类。

---

## 1. 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                    ChunkStreamManager (集成中枢)              │
│  持有 _season_state: SeasonState                              │
│  _on_time_state_changed(snapshot) →                           │
│    day = snapshot["day"]                                      │
│    _season_state.advance_to_day(day)                          │
│    season_id = _season_state.season_id()                      │
│    传递 season_id / 倍率给各子系统                            │
└──────┬──────────────────────────────────────────────────────┘
       │ season_id / multipliers
       ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ SurvivalCatalog│  │ WeatherSystem │  │ HydrologyGen  │  │ FarmingState  │
│ +season_offset │  │ +season_weights│ │ +river_freezes│  │ +growth_mult  │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
       │                  │                  │                  │
       ▼                  ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ EnemySpawn    │  │ ResourceYield │  │ BiomeRender   │  │ SaveManager   │
│ +pop_mult     │  │ +yield_mult   │  │ +plant_tint   │  │ 26→27 migrate │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

**驱动源**：`DayNightCycle.snapshot()` 已返回 `"day"` 字段（`int(floor(total_seconds / _cycle_seconds)) + 1`）。`ChunkStreamManager._on_time_state_changed(snapshot)` 已监听昼夜变更并推进 `_quest_day`。本设计在此同一回调中推进 `_season_state`。

**核心约束**：`SeasonState` 是纯 `RefCounted`，无副作用，由 `ChunkStreamManager` 持有并驱动。所有季节倍率通过参数传入既有函数，不引入全局可变状态。

---

## 2. 既有 API 摘要（不改动）

### 2.1 SeasonCatalog（`scripts/season/season_catalog.gd`）

```gdscript
class_name SeasonCatalog extends RefCounted
func is_valid() -> bool
func season_duration_days() -> int          # 8
func transition_days() -> int               # 1
func season_ids() -> Array[StringName]      # [spring, summer, autumn, winter]
func season_count() -> int                  # 4
func season_index_for_day(day: int) -> int
func season_id_for_day(day: int) -> StringName
func temperature_offset(season_id: StringName) -> float
func plant_tint(season_id: StringName) -> Color
func river_freezes(season_id: StringName) -> bool
func crop_growth_multiplier(season_id: StringName) -> float
func resource_yield_multiplier(season_id: StringName) -> float
func enemy_population_multiplier(season_id: StringName) -> float
func weather_weight(season_id: StringName, weather_id: StringName) -> float
```

### 2.2 SeasonState（`scripts/season/season_state.gd`）

```gdscript
class_name SeasonState extends RefCounted
const SCHEMA_VERSION := 1
func _init(catalog := SeasonCatalog.new(), initial_day := 1) -> void
func day() -> int
func advance_days(days: int) -> Dictionary
func advance_to_day(day: int) -> Dictionary
func season_id() -> StringName
func season_index() -> int
func temperature_offset() -> float
func plant_tint() -> Color
func river_freezes() -> bool
func crop_growth_multiplier() -> float
func resource_yield_multiplier() -> float
func enemy_population_multiplier() -> float
func weather_weight(weather_id: StringName) -> float
func snapshot() -> Dictionary
func persistence_snapshot() -> Dictionary   # {schema_version, day}
func restore_snapshot(value: Dictionary) -> bool
```

---

## 3. 集成点详细设计

### 3.1 集成点 1：昼夜/天数驱动（FR-7）

**文件**：`scripts/world/chunk_stream_manager.gd`

**改动**：
1. 新增成员 `var _season_state := SeasonState.new()`（在 `_farming_state` 声明附近，约第 74 行）。
2. 在 `_on_time_state_changed(snapshot)`（约第 1255 行）开头，`previous_quest_day` 赋值后，新增：
   ```gdscript
   var season_day := maxi(1, int(snapshot.get("day", _quest_day)))
   _season_state.advance_to_day(season_day)
   ```
3. 新增辅助方法：
   ```gdscript
   func _season_id() -> StringName:
       return _season_state.season_id()
   func season_state_snapshot() -> Dictionary:
       return _season_state.snapshot()
   ```
4. 通过 `EventBus` 发出季节变更（见 3.9）。

**不改** `DayNightCycle` 本身——它已返回 `day` 字段。

### 3.2 集成点 2：生存温度（FR-8）

**文件**：`scripts/survival/survival_catalog.gd`（`target_temperature()` 第 78 行）

**改动**：在 `target_temperature(environment)` 中，`near_heat` 加成之后、`clampf` 之前，新增：
```gdscript
base += float(environment.get("season_temperature_offset", 0.0))
```

**调用方**：`ChunkStreamManager` 构造生存环境字典时（`_survival_environment` 类方法，约第 1999 行），新增字段：
```gdscript
"season_temperature_offset": _season_state.temperature_offset(),
```

**不改** `data/survival.json`——季节偏移由运行时 `SeasonState` 提供，不写入静态配置（避免双重配置源）。

> **设计决策**：用数值 `season_temperature_offset` 而非 `season_id`，使 `SurvivalCatalog` 不依赖 `SeasonCatalog`，保持单一职责。`ChunkStreamManager` 负责把 `season_id` 解析为偏移值传入。

### 3.3 集成点 3：天气权重（FR-9）

**文件**：`scripts/weather/weather_system.gd`（`update()` 第 24 行、`_select_weather()` 第 140 行）

**改动**：
1. `update()` 签名新增可选参数：
   ```gdscript
   func update(delta: float, world_tile: Vector2i, biome_id: StringName, season_weights: Dictionary = {}) -> Dictionary
   ```
   `season_weights` 形如 `{"CLEAR": 0.5, "RAIN": 0.4, ...}`，空字典表示无季节调整（向后兼容）。
2. 将 `season_weights` 存入成员 `var _season_weights: Dictionary = {}`，在 `update` 开头赋值。
3. `_select_weather(biome_id)` 改为用组合权重：
   ```gdscript
   func _select_weather(biome_id: StringName) -> StringName:
       var stable := WorldSeed.from_text(...)
       var roll := float(stable & 0xffff) / 65536.0
       return _catalog.choose_for_biome_weighted(biome_id, roll, _season_weights)
   ```
4. `WeatherCatalog` 新增方法：
   ```gdscript
   func choose_for_biome_weighted(biome_id: StringName, roll: float, season_weights: Dictionary) -> StringName:
       var total := 0.0
       var combined: Array[float] = []
       for candidate in _definitions:
           var w := candidate.weight_for_biome(biome_id) * float(season_weights.get(String(candidate.weather_id), 1.0))
           combined.append(w)
           total += w
       if total <= 0.0:
           return &"CLEAR"
       var cursor := clampf(roll, 0.0, 0.999999) * total
       for i in _definitions.size():
           cursor -= combined[i]
           if cursor < 0.0:
               return _definitions[i].weather_id
       return &"CLEAR"
   ```
   保留原 `choose_for_biome` 不变（`season_weights={}` 时等价）。

**调用方**：`ChunkStreamManager` 调用 `_weather_system.update(delta, tile, biome, _season_weather_weights())` 处，新增：
```gdscript
func _season_weather_weights() -> Dictionary:
    var weights := {}
    for wid in [&"CLEAR", &"RAIN", &"SNOW", &"SANDSTORM"]:
        weights[String(wid)] = _season_state.weather_weight(wid)
    return weights
```

### 3.4 集成点 4：河流冻结（FR-10）

**文件**：`scripts/generation/hydrology_generator.gd`（`feature_at()` 第 22 行）

**改动**：`feature_at` 签名新增可选参数：
```gdscript
func feature_at(world_tile: Vector2i, terrain: ChunkData.Terrain, biome_id: StringName, temperature: float, elevation: float, river_freezes: bool = false) -> Feature:
```
在河流返回处（第 35 行 `return Feature.RIVER`）改为：
```gdscript
    return Feature.ICE_LAKE if river_freezes else Feature.RIVER
```

**调用方**：`ChunkStreamManager` / `ChunkGenerationJob` 调用 `feature_at(...)` 处传入 `_season_state.river_freezes()`。

**生成字节影响**：冬季河流格从 `RIVER` 变为 `ICE_LAKE`，改变 `ChunkData` 校验和字节 → `GENERATION_VERSION` 从 6 升至 7（见第 7 节）。

> **注意**：`Feature.BANK`（河岸）不冻结，保持可通行边界。`movement_multiplier(ICE_LAKE)==0.82` 已存在，玩家可在冰上行走。

### 3.5 集成点 5：作物生长（FR-11）

**文件**：`scripts/farming/farming_state.gd`（`advance_to_day()` 第 170 行）

**改动**：`advance_to_day` 签名新增可选参数：
```gdscript
func advance_to_day(day: int, weather_id: StringName, season_growth_multiplier: float = 1.0) -> Dictionary:
```
在生长增量计算处（第 188 行 `growth_delta` 赋值后）乘以季节倍率：
```gdscript
growth_delta *= season_growth_multiplier
```

**调用方**：`ChunkStreamManager._on_time_state_changed`（第 1257 行）改为：
```gdscript
var farming_result := _farming_state.advance_to_day(_quest_day, _current_weather_id, _season_state.crop_growth_multiplier())
```

### 3.6 集成点 6：植物颜色（FR-12）

**文件**：`scripts/world/chunk_renderer.gd`（渲染群系/植物颜色处）

**改动**：`ChunkRenderer` 新增成员 `var _season_plant_tint := Color.WHITE`。在渲染植物/植被 tile 颜色时，用 `_season_plant_tint` 混合：
```gdscript
var base_color := biome_color  # 既有
var tinted := base_color.lerp(_season_plant_tint, 0.35)  # 35% 季节色调
```
`ChunkStreamManager` 在 `_on_time_state_changed` 中设置 renderer 的 tint：
```gdscript
_chunk_renderer.set_season_plant_tint(_season_state.plant_tint())
```
新增 `ChunkRenderer.set_season_plant_tint(color: Color)` 方法。

> **设计决策**：混合比例 0.35 为固定常量，不写入配置（本版本范围）。`plant_tint` 的 alpha 通道（配置中 `20` 即 0x20/0xFF≈12%）不参与混合，仅用 RGB。

### 3.7 集成点 7：敌人数量（FR-13）

**文件**：`scripts/enemies/enemy_spawn_planner.gd`（`candidates_for_chunk()` 第 21 行）

**改动**：`candidates_for_chunk` 签名新增可选参数：
```gdscript
func candidates_for_chunk(chunk_position: Vector2i, phase_id: StringName = &"", world_layer: StringName = &"surface", population_multiplier: float = 1.0) -> Array[Dictionary]:
```
在 `spawn_roll` 判断处（第 37 行 `if spawn_roll >= _catalog.spawn_chance()`），改为：
```gdscript
var effective_chance := clampf(_catalog.spawn_chance() * population_multiplier, 0.0, 1.0)
if spawn_roll >= effective_chance:
    continue
```
缓存键加入 `population_multiplier` 的舍入值以保持缓存正确性：
```gdscript
var cache_key := "%s:%d:%d:%s:%d" % [world_layer, chunk_position.x, chunk_position.y, phase_id, roundi(population_multiplier * 100)]
```

**调用方**：`EnemyDirector` / `ChunkStreamManager` 调用处传入 `_season_state.enemy_population_multiplier()`。

### 3.8 集成点 8：资源产出（FR-14）

**文件**：`scripts/world/chunk_stream_manager.gd`（`adjusted_resource_quantity` 第 1304 行附近、`_on_weather_state_changed` 第 1300 行）

**改动**：新增成员 `var _season_resource_multiplier := 1.0`。在 `_on_time_state_changed` 中更新：
```gdscript
_season_resource_multiplier = _season_state.resource_yield_multiplier()
```
`adjusted_resource_quantity` 改为：
```gdscript
func adjusted_resource_quantity(base_quantity: int) -> int:
    return maxi(1, roundi(float(base_quantity) * _weather_resource_multiplier * _world_event_resource_multiplier * _season_resource_multiplier))
```

### 3.9 集成点 9：季节事件通知（FR-16）

**文件**：`scripts/core/event_bus.gd`

**改动**：新增信号：
```gdscript
signal season_state_changed(snapshot: Dictionary)
```
`ChunkStreamManager._on_time_state_changed` 在推进季节后，若季节 ID 变化则发射：
```gdscript
var new_season_id := _season_state.season_id()
if new_season_id != _previous_season_id:
    _previous_season_id = new_season_id
    EventBus.season_state_changed.emit(_season_state.snapshot())
```

---

## 4. 存档迁移设计

### 4.1 格式变更

| 字段 | V4.1.0 (format 26) | V4.2.0 (format 27) |
|------|--------------------|--------------------|
| `save_version` | 26 | 27 |
| `generation_version` | 6 | 7 |
| `game_version` | "4.1.0" | "4.2.0" |
| `world.json` 新增 | — | `season_state: {schema_version: 1, day: <int>}` |
| `player.json` | 不变 | 不变（季节属世界状态） |

### 4.2 SaveManager 迁移（`scripts/save/save_manager.gd`）

1. `SUPPORTED_SAVE_VERSIONS` 数组末尾追加 `27`（第 5 行）。
2. 在迁移链中（第 269 行 `if loaded_save_version < GameVersion.SAVE_VERSION:` 之前）新增：
   ```gdscript
   if loaded_save_version < 27:
       metadata["season_state"] = {"schema_version": 1, "day": 1}
   ```
   这与既有 `if loaded_save_version < 25: player["homestead_state"] = ...` 模式完全一致。
3. 加载后规范化季节状态（与既有 `normalized_weather` 模式一致）：
   ```gdscript
   var normalized_season := SeasonState.new()
   if not normalized_season.restore_snapshot(metadata.get("season_state", {}) as Dictionary):
       return _fail("季节存档状态无效")
   metadata["season_state"] = normalized_season.persistence_snapshot()
   ```
4. 写入 `world.json` 时（`_write_world_metadata` 类方法，约第 79/925 行）包含 `season_state`。

### 4.3 ChunkStreamManager 恢复

在 `_restore_from_save` / `load_world` 路径中，从 `metadata["season_state"]` 恢复：
```gdscript
_season_state.restore_snapshot(metadata.get("season_state", {}))
```

### 4.4 生成版本兼容

`SaveManager._validate_metadata`（第 1082 行）当前要求 `save_version == SAVE_VERSION` 时 `generation_version == GENERATION_VERSION`。升到 27/7 后，format 26/gen 6 的旧档通过迁移路径接受（`loaded_save_version < SAVE_VERSION` 分支不强制 gen 匹配），迁移后下次保存写 27/7。

---

## 5. 测试设计

### 5.1 新增 `_test_season_models()`（`tests/run_all.gd`）

放在 `_test_weather_models()`（第 1937 行）之后。断言清单：

```gdscript
func _test_season_models() -> void:
    # 1. Catalog 加载校验
    var catalog := SeasonCatalog.new()
    _assert_true(catalog.is_valid(), "season configuration loads and validates")
    _assert_equal(catalog.season_count(), 4, "exactly four seasons")
    _assert_equal(catalog.season_duration_days(), 8, "season duration is 8 days")
    _assert_equal(catalog.transition_days(), 1, "transition is 1 day")

    # 2. 四季 ID 顺序
    var ids := catalog.season_ids()
    _assert_equal(ids[0], &"spring", "first season is spring")
    _assert_equal(ids[1], &"summer", "second season is summer")
    _assert_equal(ids[2], &"autumn", "third season is autumn")
    _assert_equal(ids[3], &"winter", "fourth season is winter")

    # 3. 天数→季节映射
    var state := SeasonState.new(catalog, 1)
    _assert_equal(state.season_id(), &"spring", "day 1 is spring")
    state.advance_to_day(9)
    _assert_equal(state.season_id(), &"summer", "day 9 is summer")
    state.advance_to_day(17)
    _assert_equal(state.season_id(), &"autumn", "day 17 is autumn")
    state.advance_to_day(25)
    _assert_equal(state.season_id(), &"winter", "day 25 is winter")
    state.advance_to_day(33)
    _assert_equal(state.season_id(), &"spring", "day 33 cycles to spring")

    # 4. 季节属性值
    _assert_true(is_equal_approx(catalog.temperature_offset(&"spring"), -1.5), "spring temperature offset")
    _assert_true(is_equal_approx(catalog.temperature_offset(&"summer"), 3.0), "summer temperature offset")
    _assert_true(is_equal_approx(catalog.temperature_offset(&"winter"), -6.0), "winter temperature offset")
    _assert_true(catalog.river_freezes(&"winter"), "winter rivers freeze")
    _assert_true(not catalog.river_freezes(&"summer"), "summer rivers do not freeze")
    _assert_true(is_equal_approx(catalog.crop_growth_multiplier(&"summer"), 1.3), "summer crop growth 1.3")
    _assert_true(is_equal_approx(catalog.crop_growth_multiplier(&"winter"), 0.3), "winter crop growth 0.3")
    _assert_true(is_equal_approx(catalog.resource_yield_multiplier(&"summer"), 1.15), "summer resource yield 1.15")
    _assert_true(is_equal_approx(catalog.enemy_population_multiplier(&"winter"), 0.85), "winter enemy population 0.85")

    # 5. 天气权重
    _assert_true(is_equal_approx(catalog.weather_weight(&"winter", &"SNOW"), 0.50), "winter snow weight 0.50")
    _assert_true(is_equal_approx(catalog.weather_weight(&"summer", &"SANDSTORM"), 0.20), "summer sandstorm weight 0.20")

    # 6. 存档 round trip
    state.advance_to_day(20)
    var persisted := state.persistence_snapshot()
    var restored := SeasonState.new(catalog, 1)
    _assert_true(restored.restore_snapshot(persisted), "season state restores")
    _assert_equal(restored.day(), 20, "season day round trips")
    _assert_equal(restored.season_id(), state.season_id(), "season id round trips")

    # 7. 无效配置拒绝
    # (可选：用临时无效 JSON 验证 is_valid()==false，若文件系统允许)
```

### 5.2 注册（`_ready()` 第 30 行附近）

在 `_test_weather_models()` 调用后插入：
```gdscript
_test_season_models()
```

### 5.3 既有测试不回归

- `_test_survival_models`：`target_temperature` 新增 `season_temperature_offset` 默认 0.0，既有环境字典不含该字段 → 行为不变。
- `_test_weather_models`：`update()` 新增可选参数默认空字典 → 行为不变。
- `_test_hydrology_models`：`feature_at` 新增 `river_freezes` 默认 false → 行为不变。
- `_test_farming_models`：`advance_to_day` 新增 `season_growth_multiplier` 默认 1.0 → 行为不变。
- `_test_enemy_spawn_planner`：`candidates_for_chunk` 新增 `population_multiplier` 默认 1.0 → 行为不变。
- 生成校验和夹具：generation 6→7，夹具需重算（与 V4.1.0 gen 5→6 同模式）。

---

## 6. 版本号变更清单

| 文件 | 改动 |
|------|------|
| `scripts/core/game_version.gd` | `VERSION := "4.2.0"`、`SAVE_VERSION := 27`、`GENERATION_VERSION := 7` |
| `tools/verify_project.py` | 第 219/222/225 行断言改为 `4.2.0` / `27` / `7` |
| `docs/save-format.md` | 版本号段更新；新增 `Season-state schema: 1`；迁移段新增 format 26→27 说明 |
| `CHANGELOG.md` | 新增 `## [4.2.0]` 段落 |
| `SESSION-PROGRESS.md` | 记录 V4.2.0 完成 |
| `README.md` | 版本号与特性列表更新 |
| `AGENTS.md` | 当前状态段更新为 V4.2.0 |

---

## 7. 风险与回滚策略

| 风险 | 缓解 | 回滚 |
|------|------|------|
| 河流冻结改变生成字节，既有 gen-6 夹具失败 | 重算 gen-7 校验和夹具（与 V4.1.0 同模式） | `git revert` 单次提交；generation 版本回 6 |
| 天气权重归一化使某些天气概率为零导致除零 | `choose_for_biome_weighted` 已有 `total <= 0.0` 保护返回 `&"CLEAR"` | 移除 `season_weights` 参数 |
| 存档迁移初始化 day=1 使旧档玩家「回到春季」 | 设计如此（旧档无季节进度，春季为安全默认）；不发明历史进度 | 移除 `if loaded_save_version < 27` 分支 |
| 季节倍率使冬季作物几乎不生长（0.3×）导致卡死 | 配置值 0.3 非零，仍可缓慢生长；且玩家可等待春季 | 调整 `data/season.json` 值 |
| `ChunkRenderer` 颜色混合影响既有视觉测试 | 混合比例 0.35 温和；既有 HUD 布局测试不检查像素颜色 | `set_season_plant_tint(Color.WHITE)` 使混合无效果 |
| 新增 `EventBus.season_state_changed` 信号破坏信号契约测试 | `_test_event_bus_contract` 新增断言 `EventBus.has_signal("season_state_changed")` | 移除信号 |

**回滚总策略**：全部改动在单次 Git 提交内，`git revert <commit>` 即可完整回滚到 V4.1.0（gen 6 / save 26），旧存档不受影响（迁移路径保留）。

---

## 8. 数据流总结

```
DayNightCycle.advance(delta)
  → snapshot {day: N, ...}
  → EventBus.time_state_changed
  → ChunkStreamManager._on_time_state_changed
      → _season_state.advance_to_day(N)
      → season_id = _season_state.season_id()
      → _farming_state.advance_to_day(N, weather, _season_state.crop_growth_multiplier())
      → _chunk_renderer.set_season_plant_tint(_season_state.plant_tint())
      → _weather_system.update(delta, tile, biome, _season_weather_weights())
      → EventBus.season_state_changed.emit(snapshot)  [若季节变更]
```

生成时（`ChunkGenerationJob`）：
```
HydrologyGenerator.feature_at(tile, terrain, biome, temp, elev, _season_state.river_freezes())
  → Feature.RIVER 或 Feature.ICE_LAKE
```

生存更新时：
```
environment = {..., "season_temperature_offset": _season_state.temperature_offset()}
SurvivalCatalog.target_temperature(environment)
```

敌人/资源：
```
EnemySpawnPlanner.candidates_for_chunk(chunk, phase, layer, _season_state.enemy_population_multiplier())
adjusted_resource_quantity(base) *= _season_state.resource_yield_multiplier()
```
