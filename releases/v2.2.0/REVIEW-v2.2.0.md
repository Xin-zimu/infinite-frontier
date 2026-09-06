# V2.2.0 review

Status: PASS

- Relationship configuration validates complete signed bounds, five ordered tiers, known roles/items and ordered rewards.
- Liked, disliked and neutral gifts resolve deterministic affection deltas; each NPC accepts one gift per game day.
- Friendly/trusted rewards are recorded before delivery and both inventory/relationship snapshots roll back if delivery cannot fit.
- Successful trades update personal affection and village reputation exactly once; adjusted prices are used for both UI and settlement.
- Hostile attitude removes shop/inn services without removing dialogue or the possibility of a restorative gift.
- Relationship records round-trip in stable ID order and reject duplicate NPC/village records or out-of-range values.
- Format-11 worlds receive empty relationship arrays without fabricated history and commit format 12 on their next save.
- The 1040×590 three-column NPC window remains inside the minimum supported 1280×720 viewport.
