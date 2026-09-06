# V3.7.0 review

Status: PASS

- `AutomationCatalog` cross-validates every machine with building, item and processing catalogs and rejects unknown recipes, filters or unsafe limits.
- `BuildingState` remains the single machine-state owner; non-machine records reject automation fields and fuel-retaining machines reject demolition.
- `AutomationSystem` is scene-free and simulates against a complete copied building snapshot before strict atomic commit.
- Direction is derived only from quarter-turn building rotation; source and target storage resolution is bounded to twelve compatible tiles.
- Transfer, sorting, refueling and smelting settle exact quantities; blocked input/output paths make no partial inventory change.
- Game-time advancement is independent of active renderers, so loaded and unloaded chunks follow the same bounded simulation path.
- The 128-machine, 64-operation and 720-offline-tick limits are data-driven, validated and exposed in status UI.
- Save-format-24 stores machine state only in the existing owning surface chunk; format-23 migration imports no machine or fabricated work state.
- The automation panel remains contained at every required target resolution and owns no gameplay state.
- Generated terrain bytes, stable world identities and the generation-v5 checksum remain unchanged.
