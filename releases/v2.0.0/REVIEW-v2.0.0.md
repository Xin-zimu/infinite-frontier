# V2.0.0 review

Status: PASS

- Twelve biome IDs validate and all appear in the deterministic broad scan; generation-v5 fixture `16cf513e93ddfbe3` is stable.
- Five normal enemy definitions remain distinct from elite/Boss roles; ordinary candidate generation never selects a Boss.
- Exactly three regional Bosses resolve to unique dry-land chunks in separate rings and deterministic preferred biomes.
- Entering a surface chunk reveals only its bounded 3×3 fog neighborhood and publishes only landmarks whose owning chunk is discovered.
- Village, structure, ruin, cave, dungeon, Boss, home and custom marker schemas validate, sort and round-trip exactly.
- Fast travel accepts only explicit discovered surface travel points and safely drains/rebuilds streamed state.
- Regional Boss completion is one-time, prevents respawn, dims its map marker and persists separately from session cooldowns.
- Save format 10 round-trips fog, markers and Boss completion; format 9/generation 4 migrates explicitly to current metadata.
- The 980×620 map window remains inside the 1280×720 viewport and its modal open/close state composes with inventory/crafting input.
- The rebuilt offline font contains every V2.0 exploration UI glyph.
