# V3.5.0 known issues

- Processing completes immediately; timed machine queues and unloaded-chunk automation are reserved for V3.7.
- A fueled processor cannot be demolished. Remaining fuel must be consumed through recipes; fuel extraction is not included in this version.
- Cooking pots and smelters use the generated shared-atlas visual style rather than authored animated sprites.
- All processed outputs share the existing 24-slot inventory and stay blocked atomically when no complete output stack can fit.
- Potion recovery is limited to existing poison, frostbite and burning states; long-duration buffs are outside V3.5 scope.
- Equipment quality, armor, accessories, reinforcement and repair are intentionally deferred to V3.6.
