# V3.2.0 known issues

- Player construction is limited to the surface world layer; underground and dungeon building are rejected explicitly.
- Every V3.2 blueprint occupies one world tile. Multi-tile footprints, snapping groups and blueprint dragging arrive in later building-polish work.
- Roofs are a translucent visual layer and support state; they do not yet calculate indoor weather shelter or room enclosure.
- Chest interaction transfers the selected hotbar stack or withdraws as much stored content as the inventory can accept; a dedicated chest-grid UI is not included yet.
- Building visuals use the project's generated pixel atlas. Dedicated authored sprites and construction animations remain future presentation work.
- Farming, animal housing and automation are intentionally outside V3.2 scope.
