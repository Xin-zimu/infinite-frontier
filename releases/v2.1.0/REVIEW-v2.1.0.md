# V2.1.0 review

Status: PASS

- All six roles validate complete, contiguous schedules and dialogue for dawn, day, dusk and night.
- Every generated village exposes stable elder, merchant and innkeeper services; fallback placement does not mutate village-generation bytes.
- Repeated seed/region planning returns byte-equivalent NPC identities, names, homes and service locations.
- NPC paths are deterministic cardinal routes over village cells and actors are bounded to a configurable surface radius.
- NPC actors release completely outside the surface layer and re-derive their current schedule after return.
- Merchant sales and purchases conserve exact item/currency totals; any capacity failure restores the original inventory snapshot.
- Inn sleep emits one validated request and advances the independent day-cycle model to the next dawn exactly once.
- Save format 11 round-trips talk/trade counts and coin totals; format 10 initializes an empty valid NPC schema.
- The 850×560 dialogue/shop window remains inside the 1280×720 viewport and composes with existing modal input.
