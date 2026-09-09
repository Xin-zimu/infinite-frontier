# V4.2.0 季节系统 — 编码任务清单（tasks.md）

> 版本：V4.2.0 · 把 10 步计划拆成可独立执行、可验证的原子任务
> 前置：`spec.md`、`design.md` 已确认。每个任务有编号、标题、依赖、要修改的文件、验收方式。
> 约束：所有新增函数参数必须可选且默认值保持向后兼容；不得重新设计 `SeasonCatalog` / `SeasonState` 核心 API。

---

## 任务依赖图

```
T1 (温度) ─┐
T2 (天气) ─┤
T3 (河流) ─┤
T4 (作物) ─┤
T5 (敌人) ─┼─→ T7 (驱动接入) ─→ T8 (颜色) ─→ T9 (事件信号) ─→ T10 (测试) ─→ T11 (版本号) ─→ T12 (存档迁移) ─→ T13 (文档) ─→ T14 (测试门+提交)
T6 (资源) ─┘
```

T1–T6 互相独立，可并行。T7 依赖 T1–T6（需要各倍率 API 就位）。T8–T9 依赖 T7。T10 依赖 T7。T11–T13 依赖 T10。T14 是最终验收。

---

## T1 · 集成到生存温度

**依赖**：无
**要修改的文件**：
- `scripts/survival/survival_catalog.gd`（`target_temperature()` 第 78 行）

**步骤**：
1. 在 `target_temperature(environment)` 中，`near_heat` 加成之后、`return clampf(...)` 之前，新增一行：
   ```gdscript
   base += float(environment.get("season_temperature_offset", 0.0))
   ```

**验收**：
- 既有 `_test_survival_models` 全绿（环境字典不含 `season_temperature_offset` 时偏移为 0.0，行为不变）。
- 手动构造 `environment = {..., "season_temperature_offset": -6.0}`，`target_temperature` 比无偏移低 6.0。

---

## T2 · 集成到天气权重

**依赖**：无
**要修改的文件**：
- `scripts/weather/weather_catalog.gd`（新增 `choose_for_biome_weighted`）
- `scripts/weather/weather_system.gd`（`update()` 第 24 行、`_select_weather()` 第 140 行）

**步骤**：
1. `WeatherCatalog` 新增方法 `choose_for_biome_weighted(biome_id: StringName, roll: float, season_weights: Dictionary) -> StringName`：对每个候选天气，`combined = candidate.weight_for_biome(biome_id) * float(season_weights.get(String(candidate.weather_id), 1.0))`，按 combined 归一化选择；`total <= 0.0` 返回 `&"CLEAR"`。
2. `WeatherSystem` 新增成员 `var _season_weights: Dictionary = {}`。
3. `update()` 签名改为 `func update(delta: float, world_tile: Vector2i, biome_id: StringName, season_weights: Dictionary = {}) -> Dictionary`，开头赋值 `_season_weights = season_weights`。
4. `_select_weather(biome_id)` 改为调用 `_catalog.choose_for_biome_weighted(biome_id, roll, _season_weights)`。

**验收**：
- 既有 `_test_weather_models` 全绿（`season_weights={}` 时 `choose_for_biome_weighted` 等价 `choose_for_biome`）。
- 构造 `season_weights = {"SNOW": 0.5, "CLEAR": 0.35, "RAIN": 0.1, "SANDSTORM": 0.05}`，在 `snowfield` 群系下选择天气，SNOW 概率显著高于默认。

---

## T3 · 集成到河流冻结

**依赖**：无
**要修改的文件**：
- `scripts/generation/hydrology_generator.gd`（`feature_at()` 第 22 行）

**步骤**：
1. `feature_at` 签名末尾新增 `river_freezes: bool = false`。
2. 第 35 行 `return Feature.RIVER` 改为 `return Feature.ICE_LAKE if river_freezes else Feature.RIVER`。

**验收**：
- 既有 `_test_hydrology_models` 全绿（`river_freezes` 默认 false，行为不变）。
- 构造河流格 tile，`feature_at(..., true)` 返回 `Feature.ICE_LAKE`；`feature_at(..., false)` 返回 `Feature.RIVER`。
- `movement_multiplier(ICE_LAKE) == 0.82`（既有，玩家可走冰）。

---

## T4 · 集成到作物生长

**依赖**：无
**要修改的文件**：
- `scripts/farming/farming_state.gd`（`advance_to_day()` 第 170 行）

**步骤**：
1. `advance_to_day` 签名改为 `func advance_to_day(day: int, weather_id: StringName, season_growth_multiplier: float = 1.0) -> Dictionary`。
2. 第 188 行 `growth_delta` 计算完成后（`growth_delta += float(elapsed_days) * fertilizer_growth` 之后），新增 `growth_delta *= season_growth_multiplier`。

**验收**：
- 既有 `_test_farming_models` 全绿（默认 1.0，行为不变）。
- 同一作物、同一天数，`season_growth_multiplier=1.3` 的 `growth_points` 是 `1.0` 的 1.3 倍。

---

## T5 · 集成到敌人数量

**依赖**：无
**要修改的文件**：
- `scripts/enemies/enemy_spawn_planner.gd`（`candidates_for_chunk()` 第 21 行）

**步骤**：
1. `candidates_for_chunk` 签名末尾新增 `population_multiplier: float = 1.0`。
2. 缓存键（第 24 行）改为 `"%s:%d:%d:%s:%d" % [world_layer, chunk_position.x, chunk_position.y, phase_id, roundi(population_multiplier * 100)]`。
3. 第 37 行 `if spawn_roll >= _catalog.spawn_chance()` 改为：
   ```gdscript
   var effective_chance := clampf(_catalog.spawn_chance() * population_multiplier, 0.0, 1.0)
   if spawn_roll >= effective_chance:
       continue
   ```

**验收**：
- 既有 `_test_enemy_spawn_planner` 全绿（默认 1.0，`effective_chance == spawn_chance()`）。
- `population_multiplier=0.5` 时候选数量显著减少；`population_multiplier=2.0` 时增多（受 `maximum_per_chunk` 上限）。

---

## T6 · 集成到资源产出

**依赖**：无
**要修改的文件**：
- `scripts/world/chunk_stream_manager.gd`（`_on_weather_state_changed` 第 1300 行附近、`adjusted_resource_quantity` 第 1304 行附近）

**步骤**：
1. 新增成员 `var _season_resource_multiplier := 1.0`（在 `_weather_resource_multiplier` 声明附近）。
2. `adjusted_resource_quantity` 改为：
   ```gdscript
   func adjusted_resource_quantity(base_quantity: int) -> int:
       return maxi(1, roundi(float(base_quantity) * _weather_resource_multiplier * _world_event_resource_multiplier * _season_resource_multiplier))
   ```
3. 新增方法 `func set_season_resource_multiplier(multiplier: float) -> void: _season_resource_multiplier = clampf(multiplier, 0.25, 3.0)`（由 T7 驱动调用）。

**验收**：
- 既有资源产出测试全绿（`_season_resource_multiplier` 默认 1.0）。
- `set_season_resource_multiplier(1.15)` 后 `adjusted_resource_quantity(10)` 返回 12（roundi(11.5)=12）。

---

## T7 · 季节驱动接入 ChunkStreamManager

**依赖**：T1, T2, T3, T4, T5, T6
**要修改的文件**：
- `scripts/world/chunk_stream_manager.gd`（成员声明第 74 行附近、`_on_time_state_changed` 第 1255 行附近、天气 update 调用处、生存环境构造第 1999 行附近、`feature_at` 调用处、`candidates_for_chunk` 调用处）

**步骤**：
1. 新增成员 `var _season_state := SeasonState.new()`、`var _previous_season_id: StringName = &"spring"`。
2. 新增辅助方法：
   ```gdscript
   func _season_id() -> StringName:
       return _season_state.season_id()
   func _season_weather_weights() -> Dictionary:
       var weights := {}
       for wid in [&"CLEAR", &"RAIN", &"SNOW", &"SANDSTORM"]:
           weights[String(wid)] = _season_state.weather_weight(wid)
       return weights
   ```
3. 在 `_on_time_state_changed(snapshot)` 开头（`previous_quest_day` 赋值后）：
   ```gdscript
   var season_day := maxi(1, int(snapshot.get("day", _quest_day)))
   _season_state.advance_to_day(season_day)
   _season_resource_multiplier = clampf(_season_state.resource_yield_multiplier(), 0.25, 3.0)
   ```
4. 第 1257 行 farming 调用改为 `_farming_state.advance_to_day(_quest_day, _current_weather_id, _season_state.crop_growth_multiplier())`。
5. 天气 update 调用处改为 `_weather_system.update(delta, tile, biome, _season_weather_weights())`。
6. 生存环境字典（`_survival_environment` 类方法）新增 `"season_temperature_offset": _season_state.temperature_offset()`。
7. `feature_at` 调用处传入 `_season_state.river_freezes()`。
8. `candidates_for_chunk` 调用处传入 `_season_state.enemy_population_multiplier()`。
9. 新增 `func season_state_snapshot() -> Dictionary: return _season_state.snapshot()`。
10. 新增 `func restore_season_state(value: Dictionary) -> bool: return _season_state.restore_snapshot(value)`。

**验收**：
- 游戏启动后 `_season_state.day()` 等于当前游戏天数。
- 推进到 day 9 时 `_season_id()` 返回 `&"summer"`。
- 各子系统收到正确季节参数（通过 T1–T6 的验收间接确认）。

---

## T8 · 集成植物颜色渲染

**依赖**：T7
**要修改的文件**：
- `scripts/world/chunk_renderer.gd`（渲染植物/植被颜色处）
- `scripts/world/chunk_stream_manager.gd`（`_on_time_state_changed` 中设置 tint）

**步骤**：
1. `ChunkRenderer` 新增成员 `var _season_plant_tint := Color.WHITE`。
2. 新增方法 `func set_season_plant_tint(color: Color) -> void: _season_plant_tint = color`。
3. 在渲染植物/植被 tile 颜色处，用 `base_color.lerp(_season_plant_tint, 0.35)` 混合（仅 RGB，alpha 不变）。
4. `ChunkStreamManager._on_time_state_changed` 中新增 `_chunk_renderer.set_season_plant_tint(_season_state.plant_tint())`。

**验收**：
- 既有渲染/HUD 布局测试全绿（`Color.WHITE` lerp 0.35 仍接近原色，布局测试不检查像素）。
- day 1（春季）时 renderer 的 `_season_plant_tint` 约等于 `Color("a8d87820")` 的 RGB。

---

## T9 · 季节事件信号

**依赖**：T7
**要修改的文件**：
- `scripts/core/event_bus.gd`（新增信号）
- `scripts/world/chunk_stream_manager.gd`（`_on_time_state_changed` 中发射）
- `tests/run_all.gd`（`_test_event_bus_contract` 第 1454 行附近新增断言）

**步骤**：
1. `EventBus` 新增 `signal season_state_changed(snapshot: Dictionary)`。
2. `ChunkStreamManager._on_time_state_changed` 中，推进季节后：
   ```gdscript
   var new_season_id := _season_state.season_id()
   if new_season_id != _previous_season_id:
       _previous_season_id = new_season_id
       EventBus.season_state_changed.emit(_season_state.snapshot())
   ```
3. `_test_event_bus_contract` 新增 `_assert_true(EventBus.has_signal("season_state_changed"), "season-state signal exists")`。

**验收**：
- `_test_event_bus_contract` 全绿。
- 季节从 spring→summer 切换时 `season_state_changed` 信号发射一次，payload 含 `season_id == "summer"`。

---

## T10 · 补充季节模型测试

**依赖**：T7
**要修改的文件**：
- `tests/run_all.gd`（新增 `_test_season_models()`、`_ready()` 注册第 30 行附近）

**步骤**：
1. 在 `_test_weather_models()`（第 1937 行）之后新增 `_test_season_models()`，断言清单见 `design.md` 第 5.1 节：
   - Catalog 加载校验、四季 ID、duration=8、transition=1
   - 天数→季节映射（day 1=spring, 9=summer, 17=autumn, 25=winter, 33=spring）
   - 各季节 temperature_offset（spring -1.5, summer 3.0, winter -6.0）
   - river_freezes（winter true, summer false）
   - crop_growth_multiplier（summer 1.3, winter 0.3）
   - resource_yield_multiplier（summer 1.15）
   - enemy_population_multiplier（winter 0.85）
   - weather_weight（winter SNOW 0.50, summer SANDSTORM 0.20）
   - 存档 round trip（advance_to_day(20) → persistence_snapshot → restore_snapshot → day==20, season_id 一致）
2. 在 `_ready()` 中 `_test_weather_models()` 调用后插入 `_test_season_models()`。

**验收**：
- `_test_season_models()` 单独运行全绿。
- 测试计数较 V4.1.0 增加（约 +15 断言）。

---

## T11 · 更新版本号

**依赖**：T10
**要修改的文件**：
- `scripts/core/game_version.gd`（第 4–6 行）
- `tools/verify_project.py`（第 219、222、225 行）

**步骤**：
1. `game_version.gd`：`VERSION := "4.2.0"`、`SAVE_VERSION := 27`、`GENERATION_VERSION := 7`。
2. `verify_project.py`：`'const VERSION := "4.2.0"'`、`"const SAVE_VERSION := 27"`、`"const GENERATION_VERSION := 7"`。

**验收**：
- `python3 tools/verify_project.py` 输出 "Structural verification passed"。
- `_test_version_contract` 全绿。

---

## T12 · 存档迁移 26→27

**依赖**：T11
**要修改的文件**：
- `scripts/save/save_manager.gd`（`SUPPORTED_SAVE_VERSIONS` 第 5 行、迁移链第 269 行附近、加载后规范化、写入 world.json 第 79/925 行附近）
- `scripts/world/chunk_stream_manager.gd`（`restore_season_state` 调用）

**步骤**：
1. `SUPPORTED_SAVE_VERSIONS` 数组末尾追加 `27`。
2. 在 `if loaded_save_version < 25:` 块之后、`if loaded_save_version < GameVersion.SAVE_VERSION:` 之前，新增：
   ```gdscript
   if loaded_save_version < 27:
       metadata["season_state"] = {"schema_version": 1, "day": 1}
   ```
3. 在 `normalized_weather` 规范化之后，新增季节状态规范化：
   ```gdscript
   var normalized_season := SeasonState.new()
   if not normalized_season.restore_snapshot(metadata.get("season_state", {}) as Dictionary):
       return _fail("季节存档状态无效")
   metadata["season_state"] = normalized_season.persistence_snapshot()
   ```
4. 写入 `world.json` 的 metadata 字典中包含 `season_state`。
5. `ChunkStreamManager` 加载世界后调用 `restore_season_state(metadata.get("season_state", {}))`。

**验收**：
- 既有 `_test_save_system` 全绿（format 26 夹具迁移到 27，`season_state.day == 1`）。
- 新世界保存后 `world.json` 含 `season_state` 字段。
- 加载 format 26 旧档不丢失任何既有玩家/世界/差分状态。

---

## T13 · 更新文档

**依赖**：T11, T12
**要修改的文件**：
- `docs/save-format.md`
- `CHANGELOG.md`
- `SESSION-PROGRESS.md`
- `README.md`
- `AGENTS.md`

**步骤**：
1. `save-format.md`：
   - 版本段：`Game version: 4.2.0`、`Save version: 27`、`Generation version: 7`、新增 `Season-state schema: 1`。
   - `world.json` 示例新增 `"season_state": {"schema_version": 1, "day": 5}`。
   - 迁移段新增：`V4.1 format-26 documents ... V4.2 preserves every prior field and initializes season-state schema 1 with day 1 (spring); generation advances to 7 because winter river freezing changes generated hydrology bytes.`
2. `CHANGELOG.md`：在 `## [4.1.0]` 之前新增 `## [4.2.0] - <date>` 段落，含 Added（四季系统、9 集成点）、Changed（版本号 4.2.0/27/7）。
3. `SESSION-PROGRESS.md`：新增 V4.2.0 完成记录。
4. `README.md`：版本号与特性列表更新（加季节系统）。
5. `AGENTS.md`：当前状态段改为 `当前稳定基线：V4.1.0`、`当前开发目标：V4.2.0` → 完成后改为 `当前稳定基线：V4.2.0`。

**验收**：
- 文档无残留 4.1.0 / 26 / 6 版本号（除历史段落）。
- `save-format.md` 的迁移段连贯。

---

## T14 · 跑测试门至全绿并提交

**依赖**：T7, T8, T9, T10, T11, T12, T13
**要修改的文件**：无（仅运行与提交）

**步骤**：
1. 运行 `bash tools/run_tests.sh`（或 `tools/run_tests.ps1`）。
2. 修复所有失败（预期：gen-6→7 校验和夹具重算、任何因可选参数默认值遗漏的回归）。
3. 运行 `python3 tools/verify_project.py` 确认结构验证通过。
4. 确认测试输出 `0 FAIL`，且总数 ≥ 6475 + 15（新增季节断言）。
5. `git add` 全部改动文件：
   ```
   data/season.json
   scripts/season/season_catalog.gd
   scripts/season/season_state.gd
   scripts/survival/survival_catalog.gd
   scripts/weather/weather_catalog.gd
   scripts/weather/weather_system.gd
   scripts/generation/hydrology_generator.gd
   scripts/farming/farming_state.gd
   scripts/enemies/enemy_spawn_planner.gd
   scripts/world/chunk_stream_manager.gd
   scripts/world/chunk_renderer.gd
   scripts/core/event_bus.gd
   scripts/core/game_version.gd
   scripts/save/save_manager.gd
   tests/run_all.gd
   tools/verify_project.py
   docs/save-format.md
   CHANGELOG.md
   SESSION-PROGRESS.md
   README.md
   AGENTS.md
   ```
6. `git commit -m "V4.2.0: season system with spring/summer/autumn/winter, 9 integration points, save 26→27, gen 6→7"`。
7. **不推送** GitHub（按 AGENTS.md 约定）。

**验收**：
- `git log -1 --format='%s'` 以 `V4.2.0:` 开头。
- `tools/run_tests.sh` 全绿（0 FAIL）。
- `tools/verify_project.py` 通过。
- `git status` 无未跟踪的季节相关文件。

---

## 任务汇总

| 编号 | 标题 | 依赖 | 主要文件 |
|------|------|------|----------|
| T1 | 集成到生存温度 | — | survival_catalog.gd |
| T2 | 集成到天气权重 | — | weather_catalog.gd, weather_system.gd |
| T3 | 集成到河流冻结 | — | hydrology_generator.gd |
| T4 | 集成到作物生长 | — | farming_state.gd |
| T5 | 集成到敌人数量 | — | enemy_spawn_planner.gd |
| T6 | 集成到资源产出 | — | chunk_stream_manager.gd |
| T7 | 季节驱动接入 | T1–T6 | chunk_stream_manager.gd |
| T8 | 植物颜色渲染 | T7 | chunk_renderer.gd, chunk_stream_manager.gd |
| T9 | 季节事件信号 | T7 | event_bus.gd, chunk_stream_manager.gd, run_all.gd |
| T10 | 补充季节模型测试 | T7 | run_all.gd |
| T11 | 更新版本号 | T10 | game_version.gd, verify_project.py |
| T12 | 存档迁移 26→27 | T11 | save_manager.gd, chunk_stream_manager.gd |
| T13 | 更新文档 | T11, T12 | save-format.md, CHANGELOG.md, 等 |
| T14 | 测试门全绿并提交 | T7–T13 | （运行与提交） |

**总计**：14 个主任务，0 个子任务层级（全部原子），覆盖 spec.md 全部 FR/NFR/TR/SR/VR 需求。
