# V4.0.0 review

Status: PASS

- `HomesteadCatalog` validates every limit and requires a known dedicated building marker.
- `BuildingState` remains the sole physical beacon owner and enforces the global cap and minimum spacing on placement and restore.
- `HomesteadState` stores only logical names, active selection and travel time; every record is cross-validated against a beacon ID and tile.
- Base asset totals and eight loop steps are derived from current building, farming and husbandry owners instead of persisting stale completion flags.
- Overlapping management ranges resolve by nearest Chebyshev distance and stable base ID.
- Home relocation rejects dungeons, safely changes to the surface when required and commits cooldown only after exact arrival.
- Beacon placement and demolition synchronize base identity and repair active selection immediately.
- Save-format-25 migration synchronizes only real markers and cannot fabricate a beacon, base, selection or cooldown.
- The panel owns no gameplay state and remains contained at every required target resolution.
- Generated terrain bytes, stable world identities and the generation-v5 checksum remain unchanged.
