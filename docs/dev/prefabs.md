# Prefabs: pieces lifted from City 18 and Valve's maps

The owner, 21 November: "don't be afraid to more or less rip off and copy the design principles, textures, etc from city 18; the modules are really bad with texture choice and architecture". This library holds real pieces of the owner's own map, City 18 (`c18_*`, 28 pieces), and of Valve's Source SDK sample maps (`valve_*`, 12 pieces), so a generated map piece can be dressed with their architecture and their textures, laid exactly as they laid them.

Each piece is one JSON file in `_dev/reference/prefabs/`: every brush wholly inside a box of the source map (world brushes and detail alike), each face with its material and texture alignment, and the props, lights and decals inside the box. The tool is `_dev/tools/map_prefab.py`.

## Using a piece

In a module (`_dev/tools/map_mods_*.py`):

```python
from map_prefab import place
place(m, "c18_entrance_a", u, v, z, turn)
```

The piece's anchor goes to (u, v, z) of the module's frame, turned `turn` quarter turns anticlockwise seen from above (0 to 3), on top of the frame's own turning. Its brushes go in as one func_detail (a piece never seals: the module's own plan does that); its props, lights and decals go in moved and turned with it. `place(..., props=False)` leaves the props out.

Every piece's anchor is at z 0 on the floor or ground it stands on, and on the plane of the wall it dresses, so it can be set on a wall line. The table says which way each piece faces before it is turned. Turning by quarter turns:

| faces | turn 1 | turn 2 | turn 3 |
|---|---|---|---|
| -y | +x | +y | -x |
| +x | +y | -x | -y |
| +y | -x | -y | +x |
| -x | -y | +x | +y |

Commands (from `_dev/tools`):

```
python3 map_prefab.py list                          the library, with each piece's box and note
python3 map_prefab.py show NAME --out a.vmf         a VMF with only that piece (anchor at 0 0 0), for map_view.py
python3 map_prefab.py extract MAP.vmf NAME X1 Y1 Z1 X2 Y2 Z2 --anchor X Y Z --note "what it is"
```

Each JSON's `note` says what the piece is, which way it faces, its size and anything to watch for. Read it before placing.

## Things to know

- **Doors and lamps come along.** A piece with a doorway carries the source map's door (`prop_door_rotating`) and lamp; a door keeps its name from the source map, so two copies of one piece share a door name (they would open together if something fires that name). Rename in the module when it matters.
- **Moving brushes taken shut.** `c18_garage_a` holds the roller door (a func_door in City 18) and `valve_shop_a` Valve's breakable glass and shelves (func_breakable and func_breakable_surf), all taken as fixed slabs.
- **Black panes.** City 18 puts a `tools/toolsblack` pane behind shop and house windows whose rooms are not built; `c18_window_b`, `c18_bay_a` and `c18_shopfront_b` keep theirs.
- **Content outside Half-Life 2:** `c18_culvert_a` uses `concrete/concretewall056c`, a Counter-Strike: Source material (City 18 uses it, so the owner's server mounts it). Every other piece passes `map_assets.py`. The env_sprite glows are written `sprites/light_glow03.vmt` (City 18 and Valve write `materials/Sprites/...`, which the game reads the same but the assets check does not).
- **Valve's stairs** are 8 high per step (`valve_stairwell_a`, `valve_metalstair_a`); City 18's outdoor stair `c18_stair_b` is 16 high and 16 deep, steeper than our 16 by 24 rule.
- **What City 18 does not give:** its cornices, parapet copings and string courses are long single brushes running a whole street front, so none could be cut into a piece; most of its facades are flat walls with windows painted in the texture (`building_template`, `brickwall037a`), and its kerbs are long strips. For those, copy the materials (listed in each note) rather than a piece.

## The pieces

Size is width (x) by depth (y) by height (z) of the brushes, before turning. "From" gives the source map and the anchor's place in it.

| Piece | What it is | Size | Faces | Main materials | From |
|---|---|---|---|---|---|
| `c18_balcony_a` | long balcony: brick slab on two corbels, thin metal railing | 92 x 316 x 88 | +x | metalrail003a, concretefloor031a, brickwall053e, brickwall053d | City 18, at -1352 -314 1208 |
| `c18_bathroom_a` | a flat's whole bathroom: walls, door in its casing, bath, toilet, basin, bulb | 144 x 162 x 120 | a room: anchor at its inner south-west corner | plasterwall003b, plasterwallpaper001a, concretewall036a, tilefloor009a | City 18, at -1720 216 1208 |
| `c18_bay_a` | one storey bay of a brick facade: window with sill and head reveals, glass, black pane | 8 x 84 x 128 | +x | plasterwall041a, brickwall031d, concreteceiling004a, glasswindow042a | City 18, at -1352 -438 824 |
| `c18_cell_a` | Combine cell bay: two sloped-top metal dividers, a bunk, a lamp | 188 x 237 x 216 | -x | metalcombine001, concretewall055b, stonewall050f, metalcombine002 | City 18, at 2836 560 928 |
| `c18_combinedoor_a` | Combine kit in an old wall: long Combine glass window and a door in a Combine metal frame | 232 x 16 x 128 | +y | concretewall059e, metalcombine001, metalcombine002, concretewall036a | City 18, at 2316 848 368 |
| `c18_combineglass_a` | Combine observation window: two leaning panes, mullion, angled frame | 280 x 36 x 112 | -y (leans back to +y) | metalcombine002, combineglass001a, stonewall050f | City 18, at 2556 512 1088 |
| `c18_combinerail_a` | Combine railing: posts, metal panels, glass strip, top trim | 4 x 148 x 96 | runs +y, both sides alike | metalcombine001, citadel_metalwall090a, glasswindow015a, combineglass001a | City 18, at 2006 512 928 |
| `c18_combinewindow_a` | Combine reception window in a citadel metal wall, shutter slot, sill | 28 x 104 x 128 | -x | metalpipe001a, citadel_metalwall072c, citadel_metalwall077a, combineglass001a | City 18, at 2520 690 928 |
| `c18_corner_b` | L-shaped stone corner pier with chamfers and a plinth course | 112 x 160 x 184 | -x and -y (wraps the corner at the anchor) | stonewall050f, stonewall040f | City 18, at -704 80 664 |
| `c18_culvert_a` | sewer culvert: stepped round arch over a floor slab, bars at both mouths | 128 x 184 x 168 | mouth at y 0, runs +y | concretewall056c, metalfloor005a, concretefloor010b | City 18, at 336 1192 287 |
| `c18_door_a` | service door: casing, paired posts, caged lamp, door01_left | 48 x 152 x 120 | -x | concretewall055b, concretewall008a, metalpipe001a, concretewall064c | City 18, at 40 -1460 664 |
| `c18_door_b` | a flat's inner door in an 8 thick wall, tiled dado on one side, casing, door01_left | 16 x 112 x 120 | +x (tiled side) | plasterwall003b, concretewall036a, plasterwallpaper001a, tilefloor009a | City 18, at -1608 312 1208 |
| `c18_downpipe_a` | downpipe (gutter_704) with a gutter piece at its head (props only) | props, about 700 high | +x | (props only) | City 18, at -1352 17 664 |
| `c18_entrance_a` | recessed shop entrance: chamfered jambs, canopy slab, framed billboard, caged lamp | 161 x 40 x 248 | -y | concretewall008a, brickwall045d, plasterwall046b, woodstair002c | City 18, at -1931 2560 832 |
| `c18_garage_a` | garage bay: opening between paired posts under a beam, the roller door shut | 48 x 224 x 144 | -x | concretewall055b, metalpipe001a, metaldoor018a, concretewall002c | City 18, at 40 -1616 664 |
| `c18_grate_a` | drain grate over a sewer channel, with edge strips | 128 x 64 x 4 | lies flat | concretewall073c, stonewall050f, metalgrate013a | City 18, at 336 1144 303 |
| `c18_kitchen_a` | a flat's kitchen wall: tile dado, wallpaper, corner beads, fridge, stove, sink | 208 x 16 x 120 | -y | plasterwall041a, woodfloor006b, plasterwall047b, plasterwallpaper001a | City 18, at -1464 8 1208 |
| `c18_payphones_a` | payphone wall: low brick wall, shelf, three payphones, a bench each end | 42 x 320 x 72 | +x | stonewall050f, brickwall040b, metaltruss017a, concretewall008a | City 18, at 3136 -1960 760 |
| `c18_phonebooth_a` | two glass payphone booths in concrete frames | 136 x 56 x 104 | +y (open side) | concretewall020a, stonewall050f, glasswindow007a, glasswindow015a | City 18, at 875 -1126 664 |
| `c18_pilaster_a` | brick pilaster, street to parapet | 16 x 16 x 928 | +x | brickwall053d, brickwall014l | City 18, at -1352 -488 664 |
| `c18_sewerstair_a` | concrete service steps in the sewer with a handrail | 96 x 144 x 90 | foot at y 0, climbs toward -y | concretefloor010b, concretewall071f, concretewall073c, concretefloor027a | City 18, at 222 1648 307 |
| `c18_shopfront_a` | shopfront of the square: framed windows round plaster panels, concrete fascia, door | 523 x 88 x 200 | -y | concretewall036a, plasterwall003b, plasterwall047b, concretewall037a | City 18, at 512 -1488 712 |
| `c18_shopfront_b` | stone shopfront: two framed windows with grilles, billboard, brick course, door | 640 x 54 x 296 | -y | concretewall036a, woodfloor006b, stonewall040f, plasterwall042c | City 18, at -384 80 712 |
| `c18_stair_a` | split hall stair: middle flight, landing, two flights back up, balustrade walls | 352 x 260 x 203 | back wall y 0, comes out to -y | woodstair002a, woodstair002c, plasterwall005a, woodstair002b | City 18, at 1224 1788 712 |
| `c18_stair_b` | outdoor stair along a wall with a solid sloped balustrade and newel | 161 x 144 x 200 | back wall y 0, open side -y, climbs +x | concretefloor031a, concretestair005a, stonewall017b, stonewall050f | City 18, at 3984 336 656 |
| `c18_steps_a` | broad entrance steps to a raised forecourt, stepped side wall, newel | 277 x 137 x 90 | foot at y 0 facing +y, climbs to -y | concretewall001a, brickwall040c, concretestair005a | City 18, at 640 -1056 664 |
| `c18_window_b` | shop bay window: angled glazing, black pane, chamfered sill and head | 144 x 48 x 248 | -y | concreteceiling004a, brickwall045d, metalwall030a, glasswindow007a | City 18, at -1731 2560 832 |
| `c18_window_c` | applied wood framed window laid on a wall face (no hole) | 1 x 64 x 104 | +x | glasswindow011a, woodstair002c | City 18, at -1352 -424 1392 |
| `valve_balcony_a` | Juliet balcony: small slab and railing under an upper window | 21 x 64 x 36 | +x | metalrail001a, building_template012g, plasterwall003a | from Valve's d1_trainstation_02 (Source SDK sample), at -5456 -3824 332 |
| `valve_celldoor_a` | interrogation room door: thin metal frame, slotted door, its slot, Combine lock | 56 x 8 x 112 | -y (corridor side) | dev_lowermetaldoor02a | from Valve's d1_trainstation_01 (Source SDK sample), at -3712 -464 -32 |
| `valve_column_a` | free standing platform column in Valve's stone courses, base moulding | 36 x 44 x 576 | free standing, centred | stonewall050c, stonewall050a, stonewall050b, stonewall050e | from Valve's d1_trainstation_01 (Source SDK sample), at -4984 -1464 -32 |
| `valve_entrance_a` | apartment block entrance passage: template walls, angled reveals, canopy | 240 x 128 x 136 | +x | building_template014f, building_template012j, building_template014i, brickwall038c | from Valve's d1_trainstation_02 (Source SDK sample), at -5440 -3824 0 |
| `valve_metalstair_a` | open metal stair between thin side walls | 64 x 180 x 128 | foot at y 0, climbs toward -y | metalstair003a, plasterwall034a | from Valve's d1_trainstation_01 (Source SDK sample), at -3168 -396 -64 |
| `valve_pilaster_a` | station hall pilaster in the stone courses with a two step capital | 48 x 24 x 320 | +y | stonewall050c, stonewall050a, stonewall050b | from Valve's d1_trainstation_01 (Source SDK sample), at -5104 -1424 -32 |
| `valve_raven_belfry_a` | church belfry: corner piers, infill panels, tiled pyramid cap | 224 x 224 x 268 | centred | plasterwall029a, tileroof003a, plasterwall029g, plasterwall013c | from Valve's d1_town_03 (Source SDK sample), for the infestation quarter (map_raven.py), at -4704 288 -2816 |
| `valve_raven_boards_a` | loose planks nailed up as a barricade | 140 x 145 x 159 | -y | woodfloor005a | from Valve's d1_town_03 (Source SDK sample), for the infestation quarter (map_raven.py), at -2448 -1296 -3468 |
| `valve_raven_housefront_a` | two storey brick house front: piers, two window columns, ground course | 264 x 8 x 384 | -y | plasterwall029a, brickwall048i, concretewall032d, brickwall049d | from Valve's d1_town_03 (Source SDK sample), for the infestation quarter (map_raven.py), at -3388 -832 -3600 |
| `valve_raven_roof_a` | church roof: pitched tiles, eaves boards, octagonal lantern | 736 x 480 x 352 | centred | plasterwall029a, tileroof003a, plasterwall029d, woodfloor005a | from Valve's d1_town_03 (Source SDK sample), for the infestation quarter (map_raven.py), at -5280 288 -2944 |
| `valve_shop_a` | a whole corner shop: glazed front, recessed door, shelves, coolers, lights | 392 x 265 x 128 | +y | storefront_template001g, woodshelf001a, woodshelf006a, plasterwall018c | from Valve's d3_c17_13 (Source SDK sample), at 5508 -2176 0 |
| `valve_stairwell_a` | apartment stairwell, a full turn (two storeys) round an old lift shaft | 244 x 240 x 258 | lift shaft front at y 0, stair to +y | woodstair002c, plasterwall030a, woodstair002a, plasterwall030c | from Valve's d1_trainstation_03 (Source SDK sample), at -5024 -4608 0 |
