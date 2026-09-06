# V1.3.0 review

Status: IMPLEMENTATION PASS / PACKAGING BLOCKED

- Hydrology is derived from stable global coordinates and does not depend on chunk request order.
- Rivers, banks, lakes, frozen lakes, oases and bridges have distinct render tiles.
- Movement multipliers distinguish water, ice and bridges; active swimming consumes stamina.
- Hydrology remains a compatible overlay so V1.2 saves and base generation bytes remain valid.
- Automated, import, menu-smoke and game-smoke gates pass; Windows packaging awaits the Godot 4.7.1 export template.
