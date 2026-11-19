# The map survey (`_dev/tools/map_survey.py`)

The owner, 14 and 19 November: read the map's VMF (`c18_lc.vmf`, 27 MB) "to help map out NPC hotspots, player hotspots, and what could/should be redesigned", and help find "holes and cracks between geometry". The VMF is too big to read in a chat, so the tool reads it (on the owner's PC, or in a chat that has the file) and writes a small folder to read instead. It only reads: nothing in the VMF changes.

```bash
python3 map_survey.py c18_lc.vmf --study ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/livingcity/study/FOLDER
```

`--study` (a play study's folder or its `log.txt`, `docs/features/play-study.md`) is optional and may be given more than once; `--out` names the folder (default `map_survey`), `--size` the pictures' longest side (2400). Needs only Python 3; pictures are PNG with Pillow, SVG without.

**`survey.txt`:**
- *What the map is made of:* bounds, brushes (world, brush entities, displacements, by tool texture), entity and model counts, path nodes, clips, spawn points.
- *What looks wrong (candidates, not proof: only a compile proves a leak):* world brushes with corners off the 1-unit grid, slivers under 1 unit, box brushes a hair apart (a gap under 2 units between overlapping faces), point entities outside the world's bounds. Each with its brush id and map coordinates, for Hammer's "go to brush" and "go to coordinates".
- *The play study on the map:* every jump and crouch spot with a verdict, "the map" (a rise to get over, or low headroom, within 56 units) or "a habit"; where the player spends time with no path node within 400 units; where there are path nodes the player never went near.

**Pictures:** `map_all` (the whole map from above) and `map_level_N` (a floor plan for each height people walk at: taken from the study's trail when there is one, else from where spawn points, nodes and doors stand), with a grid line every 1024 units, entities as dots, and the study's trail (orange), jumps (cyan) and crouches (pink) laid over.

**Not built yet:** reading a compile's pointfile (`.lin`) to show a real leak's path; proposing or writing geometry changes; the same survey from the gamemode's own layout (zones and points) instead of a study.
