# V3.6.0 review

Status: PASS

- `EquipmentCatalog` validates every slot, quality, rarity, affix, set, item reference and enhancement/repair bound.
- `EquipmentState` is scene-free and owns stable instance IDs, complete records and worn-slot references exactly once.
- Inventory registration removes one canonical item before creating a record; equipment and inventory never duplicate ownership.
- Quality, rarity and affixes derive from stable identity and cannot reroll on reload or slot changes.
- Enhancement and repair verify exact material quantity before committing; rejected operations leave both owners unchanged.
- Zero durability is valid retained state, disables the broken item's effective stats and remains repairable.
- Attack, defense, maximum health and maximum stamina use transient equipment composition, avoiding cumulative bonuses after reload.
- Save-format-23 stores equipment only in `player.json`; format-22 migration creates no equipment, roll or worn reference.
- The equipment panel remains contained at every required target resolution and owns no gameplay state.
- Generated terrain bytes, stable world identities and the generation-v5 checksum remain unchanged.
