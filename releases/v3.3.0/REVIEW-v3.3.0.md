# V3.3.0 review

Status: PASS

- The farming catalog validates four required crop IDs, one fertilizer, canonical seed/quality items, stages, yields, regrowth and bounded weather/range settings.
- `FarmingState` is scene-free; tilling, sowing, fertilizing and harvesting use inventory simulation before commit, and failed capacity/material checks preserve exact state.
- Stable plot IDs derive from signed surface tiles; duplicate records, wrong chunk ownership, underground plots, impossible stages and unknown crop/fertilizer IDs reject persistence.
- Growth advances from in-game day boundaries with catalog weather multipliers; deterministic quality cannot be rerolled by reload, eviction or request order.
- Annual crops clear back to tilled soil, while tomato and apple-tree records retain mathematically derived regrowth stages.
- Building and farming placement perform reciprocal occupancy checks, and runtime mutations refresh only the owning active chunk.
- `FarmingChunkLayer` batches soil, water, growth-stage and maturity presentation without changing generated terrain/resource bytes.
- Format-20 plots exist only in surface chunk differences; `player.json` contains no duplicate farming state, and farm-only stale files are removed.
- Format-19 migration preserves every prior state and initializes no fabricated plots or crops.
