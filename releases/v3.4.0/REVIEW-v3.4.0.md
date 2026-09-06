# V3.4.0 review

Status: PASS

- The husbandry catalog validates all three required species, canonical feed/product items, biome lists, progression thresholds, day rules and hard limits.
- Wild candidates derive only from world seed and signed global cell; planning is request-order independent and rejects water, generated overlays and resources.
- `HusbandryState` is scene-free. Feeding and collection clone the inventory before commit, while breeding validates every parent, fence, cooldown and child-tile rule before mutation.
- Wild taming status is derived from friendship threshold; offspring remain tamed and the next birth counter is recovered from stable persisted identities.
- Day catch-up is based exclusively on saved game days and feed reserve, is bounded by the ready-product cap and does not depend on loaded renderers.
- Building, farming and husbandry perform reciprocal occupancy checks; save load independently rejects overlaps or duplicate animal tiles.
- `AnimalChunkLayer` batches wild/interacted records and reports exact tamed/sleeping counts without entering generated terrain bytes.
- Format-21 animals exist only in owning surface chunk differences; `player.json` contains no duplicate state and husbandry-only stale files are removed.
- Format-20 migration preserves every prior field and initializes no fabricated animal, product or friendship progress.
