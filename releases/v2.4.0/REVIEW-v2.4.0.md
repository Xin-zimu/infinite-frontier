# V2.4.0 review

Status: PASS

- Faction configuration requires exactly four stable IDs, five ordered tiers, six complete relations and unique NPC/enemy ownership.
- Standing stays inside `-100..100`; retained event history is bounded, ordered and arithmetically validated.
- Discovery credit uses stable marker IDs and cannot be awarded twice; village discoveries register one persistent control point.
- Hostile-member defeat applies the configured loss to its faction and reward to its enemy exactly once per death event.
- Shop views gate stock by tier, calculate price from current standing and roll back the full inventory on capacity failure.
- Only negative-relation factions can contest a control point; capture occurs precisely when remaining influence reaches zero.
- Format-13 worlds receive all four default standings without fabricated discoveries, events or control points and commit format 14 on their next save.
- The 1040×640 faction window remains inside the minimum supported 1280×720 viewport and composes with all existing modal inputs.
