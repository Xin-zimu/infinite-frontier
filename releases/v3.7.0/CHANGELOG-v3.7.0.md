# Infinite Frontier V3.7.0

## Basic automation

- Added conveyors, automatic smelters, storage links and item sorters as craftable, rotatable player-building pieces.
- Expanded the canonical catalogs to 72 items, 28 crafting recipes and 16 building blueprints.
- Added directional chest logistics with one-, two- and four-item machine throughput.
- Added automatic use of all four smelter recipes with wood/coal refueling from connected source storage.
- Added sorter filter selection, machine enable/disable, localized work states and completed-cycle counters.
- Added bounded unloaded-chunk catch-up driven by saved game time.
- Added hard limits of 128 machines, 64 successful operations per advance and 720 catch-up ticks per machine.
- Added the responsive `Y`-key automation panel.
- Advanced save format to 24 with chunk-owned machine state and explicit format-23 no-fabrication migration.
- Retained generation format 5 and its canonical checksum.
