# V2.1.0 changelog

- Added six validated village NPC roles with deterministic identities, names, schedules and phase dialogue.
- Guaranteed elder, merchant and innkeeper availability even when terrain rejects an intended house location.
- Added bounded surface-only NPC activation, village-road pathfinding and complete off-layer sleep.
- Added a responsive dialogue/shop panel with current activity, rotating dialogue, buy and sell actions.
- Added the stable `coin` item and atomic two-sided shop transactions with full rollback on capacity failure.
- Added inn sleep that advances exactly to the next dawn, restores health/stamina and requests persistence.
- Advanced save format to 11 for NPC interaction/economy records and added explicit format-10 migration.
- Preserved generation format 5 and the V2.0 canonical terrain checksum.
