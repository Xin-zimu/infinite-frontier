# V3.5.0 review

Status: PASS

- `ProcessingCatalog` validates both station IDs, interaction radius, fuel items/values and every canonical recipe input/output/cost.
- `ProcessingSystem` is scene-free and accepts only explicit inventory/building owners; views do not mutate either state.
- Material removal and output placement are validated against an inventory clone before commit. Building-side failure restores the exact prior inventory snapshot.
- Station selection resolves a bounded nearest compatible processor; recipes cannot use an inventory-held or wrong-kind station item.
- Processor fuel and completed-operation count are stored only by `BuildingState`, bounded on restore and rejected on every non-processor record.
- Fuel insertion checks capacity and inventory before commit; recipes check both materials and exact retained fuel; fueled demolition is refused.
- Meals and potions reuse canonical survival effects and are accepted only when hunger, health, temperature or a configured status can improve.
- Format-22 fields stay inside the owning surface chunk's `placed_buildings` record. `player.json` has no duplicate processing owner.
- Format-21 migration preserves every prior valid building and creates no cooking pot, smelter, fuel or processing count.
- Generation bytes, deterministic checksum, worker boundaries and existing mutable-overlay occupancy remain unchanged.
