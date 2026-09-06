# V3.7.0 known issues

- Logistics lines are straight and direction follows each machine's quarter-turn rotation; branching graphs and programmable routing are outside this version.
- Machines settle in five-second game-time ticks rather than animating individual items continuously on a belt.
- Automatic smelters run one selected canonical recipe and do not expose queues, priorities or per-recipe stock targets.
- Automation exists only on the surface building layer and every machine requires a supporting player floor.
- Closing the game adds no wall-clock production. In-game time jumps and unloaded chunks catch up at most 720 ticks per machine; older excess ticks are intentionally discarded.
- One advance performs at most 64 successful operations across all machines; saturated networks report performance throttling and continue on later game-time updates.
- V4.0 home/base progression and later roadmap systems are intentionally excluded.
