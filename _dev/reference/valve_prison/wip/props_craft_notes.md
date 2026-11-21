# Nova Prospekt: props, building craft and cross-sections (work in progress, 21 November)

Sources: d2_prison_01 to 08 (Valve's VMFs, read as text; old format, corners from planes). Hidden and 3D skybox
objects left out. Scripts: scratchpad `prison/` (load.py caches each map; lib.py; cells, parts, cellfill, lamps,
lightrec, cyaw, cmats, cjoin, cang, clean, corr, band2 .py). Numbers are brush boxes, so angled pieces read a
little large.

## 1. The cell (71 cells found in 16 rows, d2_prison_02, 03, 04, 07)

- **Size, every one:** 128 wide inside, 176 deep, partitions 16 thick at a pitch of 144; floor slab 8 (16 in
  d2_prison_04), so a storey is 128 and the cell is 120 clear (112 where the slab is 16).
- **Front:** a 16 wall, the opening 52 to 56 wide and 108 high (a 20 lintel over it), in the middle of the cell's
  front (38 from each partition); the door slides along the outside face (prison_celldoor001a barred, or
  prison_heavydoor001a solid, with prison_doortrack001a over it 53 up from the door's middle).
- **Rows and tiers:** rows of 5 cells (6 partitions, 736 long), two tiers (d2_prison_02, 03) or three
  (d2_prison_04: cell floors at 128, 256, 384, roof slab at 512). Rows face each other across a hall (d2_prison_02)
  or line one wall of a tall hall (d2_prison_04).
- **What is in them:** 36 of 71 empty. A bed in 13 (prison_metalbed001a 10, bedframe 3), the full kit (bed, toilet,
  sink, heater) in only 3: the cells a player walks into. Elsewhere a crate, two drums, a fence panel, rubble.
- **The full kit** (d2_prison_03 -3628 3997 0): toilet on the back wall's middle (25 off it), sink on a side wall
  45 from the back (16 off the wall), heater (prison_heater002a) on the same side nearer the door, metal bed along
  the other side; a ceiling panel (prison_flourescentlight002b, skin 1) in the middle; outside, a cage lamp on the
  front wall beside the door.
- Ours: the cells module's cells are 128 by 160 by 128, corridor 128 wide and 128 high, dado at 56; Valve's are
  128 by 176, 120 clear, a hall 224 to 448 wide; the Combine bay from City 18 (c18_cell_a) is 188 by 237 by 216.

## 2. Tiers, walkways, rails (cellblock halls)

- d2_prison_02 (-1280..-1056): two rows facing across a hall 224 wall to wall; upper walks 80 wide, 8 thick, on each
  side, an open well 64 wide between them; a stair in the well 60 wide, open treads 2 thick, 8 by 12, 15 steps from
  256 to 376.
- d2_prison_03: one row; the upper walk is 56 wide (func_detail 8 thick), the rail an unseen clip 2 thick and 40
  high, with handrail props.
- d2_prison_04 (the tall cellblock, x -1088..-448): a hall 448 wide, about 512 high (tubes hang at 567 to 631),
  three tiers of cells on one side, walks 80 wide and 8 thick hung off the cell fronts at 256 and 384, a 32 column
  rising the full height in the hall; handrail04_long (128 long) along the walk's outer edge, origin 20 over the
  walk; interior_fence002c panels close the walk's ends.
- Tier pitch 128 everywhere; the walk is the cell storey's own slab carried out 56 to 80.

## 3. Light (cold tubes, warm cage lamps, the Combine's beams)

- prison_cagedlight001a (154): on a wall 2 off it, 86 over the floor (94 of 154): beside a door, on cell fronts,
  128 to 144 apart along a tier (one a cell). In the cellblocks few are lit (d2_prison_02 4 of 40, 07 9 of 44, 03 5
  of 16); elsewhere nearly all (05 10 of 11, 06 11 of 11). Only 61 are lit: light_spot 254 216 146, 75, cone 70/30, pitch -70, quadratic, 10 over the model, with an
  env_sprite light_glow03 scale 0.75 rendermode 9. 93 of 154 have no light within 64: dark dressing between lit ones.
- prison_flourescentlight002b (96, the flat ceiling panel, skin 1 on 94): 3 under the ceiling, or on a wall
  (pitch 90, 31). Every one lit: light_spot 159 237 215 600 (or 255 245 145 400 to 600), cone 70/20 to 70/30,
  pitch -74, constant attenuation 500000, at the model.
- prison_flourescentlight001a/b (hanging tubes on chains, 240): 32 to 73 under the ceiling; 001b never lit (130 of
  130), 001a lit on 14 of 110 (159 237 215 600, 70/20, -90, 35 under). The tubes are dressing; the panels and spots
  light the room.
- combine_light002a (66): on walls 1 to 11 off, turned off the grid on 58 (yaw by 15s and 45s); every one lit:
  light_spot 147 226 240 2000, cone 30 to 35 / 12, pitch -30, 22 under the model, plus a point_spotlight 147 226 240,
  length 768, width 96 (62 of 66): the visible blue beam.
- light_cagelight02_off with glow01 sprites, scale 0.5, red 213 0 0 and green 0 223 0 (20 each): status lights.
- Of all light and light_spot entities: 249 at a lamp model, 186 free (fills: 255 245 145 300 cone 70 pitch 45;
  40 51 50 40 ambient fills; 147 226 240 floods 2000 to 3800 cone 25 pitch -60).

## 4. Walls: two tones at 128

- Where two wall faces stack, the material changes on 4506, stays on 3248; 2721 of the changes are 128 over the
  floor. Pairs: tilewall009b under plasterwall026a (300, washrooms), plasterwall034c under 034a or 034b (393),
  032c under 032b (159), concretewall022a under concretewall004c (116), 035c/d under 035a/b (184), 018c/e under
  018a/b (225), concretewall010c under 010b (88). The lower band is the same plaster's darker partner.
- Ours: City 18's two tones with a dado rail at 56 (the owner's look); Valve's prison changes at 128 with no rail.

## 5. Corridors and halls (from 535 corridor nodes and the halls, ray to brush boxes)

- Corridors: 192 wide most of all (245 nodes), then 128 (75); ceilings 128 and 120 at 192 wide, 192 to 208 at 128
  wide; median 192 by 176. The flats of City 17 are 112 by 120.
- Halls: 256 wide by 128 to 192 high (256 nodes), 384 by 128 to 256 (182), 640 to 704 by 192 (68).
- Ours: the cells corridor 128 by 128; Valve would give a prison corridor 192 by 128, or 128 by 192.

## 6. Combine architecture (the Combine's own places)

- Brush share of the Combine's metal by visible area: 0 to 1% in the old prison (01 to 05, 07), 20% in d2_prison_06
  (the depot and train yard), 81% in d2_prison_08 (the teleport works): the Combine moved in with props and built
  its own halls beside the old ones, not over them.
- The old prison's own fixtures sit square (prison_ models 97% on exact 90s); the Combine's things are 73% square:
  its lights turned to aim (combine_light002a 88% off the grid, by 15s and 45s), consoles and monitors set at
  free angles (combine_interface003 yaw 24, 69, 204, 294, 356; combine_smallmonitor001 5 of 5 free), but racks,
  fences, pods and locks square.
- **Leaning walls.** The Combine's walls stand square in plan (99% of wall area on the axes) but lean: 14% of
  wall area in d2_prison_06 and 7% in 08 is sloped 14 to 17 degrees off upright: panels 128 high leaning 32 (1 in 4)
  or 40 (5 in 16), and 104 high leaning 44 (23 degrees). Bases lean back, heads lean over.
- **The pod shaft** (d2_prison_08, 1680..2032 by 2816..4096, -960 to 192): 256 wide at the foot, opening out by
  32 a step (128 high, 1 in 4) to about 400, straight for 600, then closing in by 40 a step (5 in 16) to 224 at
  the head; the two sides step at different heights: the profile is a lozenge, not symmetrical.
- **The train trench** (d2_prison_06, cut at x 3000): the Combine's metal walls 192 thick at the foot, the track bed
  256 wide at -592; the way between is 336 wide to -464, 400 to -336, 464 above: out 32 a side every 112 to 128.
- **Texture:** metalwall077a at scale 0.5 (89% of its area in 08, 60% in 06); the old prison at 0.25 (94%).
- **Consoles of brushes:** in the old prison the Combine's control posts are 25 to 30 small metalcombine001 brushes
  with doorbutton002a buttons in a box about 64 by 96 by 119 (d2_prison_07 -632 -3390 -168; 4096 -4096 -512).
- **Field walls:** comshieldwall3 on a func_brush 2 thick, 126 high, 192 wide across a way (d2_prison_07 3776 -4904).
- Where Combine brushes meet the old: d2_prison_07 bolts thin metalcombine001 panels (2 to 10 thick, func_detail,
  87% at angles) against plaster; d2_prison_06's Combine brushes are 8 thick (140) or 2 (82), 177 of 504 touch old
  brushes (concrete floor, concretewall004c, rails), 44 cut into them. Of the thin Combine wall slabs (up to 32
  thick, 64+ high), 49 of 74 in 06 and 66 of 79 in 08 stand free as walls of their own; where one is laid on an old
  wall it touches it (gap 0 on 23 of 25 in 06, 11 of 13 in 08): plate laid flush on concretewall004c or plaster,
  never stood off it.

## 7. Rooms and their props (props within 192 to 256 of the key piece, pooled)

- **Guard office** (40 desks, controlroom_desk001b): desk 24 to 58 off a wall, chair 44 from it, file cabinets
  (002a, 001a) 73 to 131 away on the walls, a monitor on the desk (54), a switch box on the wall by the door (97 up),
  a heater, a ceiling panel; litter (coffee mug, cardboard, a bag) in a few. The cellblock's guard room in
  d2_prison_02 (-1346 2820 404) sits on the upper tier at the end of the hall, its corner cut at 45 with a window
  band of glass in metalwall062a frames 2 wide, 60 high over a 32 sill, the desk turned 45 to face the window.
- **Interrogation** (d2_prison_06 661 102 0): the room is one Combine model (props_combine/introomarea,
  prop_dynamic int_room) and the pod arm (pod_extractor) set into an old room (door01_left, hanging tubes, pipes, a
  shelf); the Combine round it as props: combine_door01 with a combine_lock01 each side 54 up, combine_fence01a/b and
  barricade brackets, consoles at 225 and 270, two generators, wires. Light: narrow cold spots on the subject
  (155 220 255 500 cone 12 pitch -30, twice; 204 255 255 400 to 600 cone 21 pitch -63; 155 220 255 900 cone 50),
  faint console glows (light 74 209 217 20).
- **Washroom** (d2_prison_03 -3700..-3270, 2016..2272): toilets 64 apart in two rows facing each other, sinks 64
  apart in facing rows (y 2725 and 2779), tile under plaster at 128.
- **Showers**: shower_system001a 40 off the wall, 320 apart, on the two long walls of a tiled hall (d2_prison_03
  x -4120 and -2856; d2_prison_02 three in a row), hanging tubes, a sprinkler; rubble in the broken one.
- **Laundry** (d2_prison_05 -600..92, 293..1744): laundry_dryer002 static in rows of 2 or 3 at 76 to 92, turned 1 to
  12 off the grid on 8 of 12; washers on the walls; laundry carts physics, turned freely (7 of 001, 5 of 002).
- **Kitchen** (d2_prison_05 -2160..-1695, -896..-615): kitchen_counter001d in a line, two stoves 217 apart on the
  wall (19 off), kitchen_shelf001a, gas cans, gas pipes, tile wall pieces.
- **Canteen**: cafeteria_table001a about 128 apart, benches 74 off; 7 of 19 tables lie on their sides (pitch or roll
  75 to 90) as cover, sometimes two stacked (d2_prison_08 -1116 1320).
- **Cell** (see 1). **Cellblock hall**: walks, rails, a cage lamp a cell, tubes hanging 192 to 256 apart, sprinklers.
- Fixtures everywhere: prison_sprinkler001a 21 under the ceiling, 256 to 512 apart (median 302, 121 of them);
  prison_heater001a 27 over the floor, 6 to 9 off the wall, 250 to 540 apart; prison_switchbox001a 97 up beside a
  door; prison_pipes002a 8 under the ceiling, 8 off the wall; prison_conduit001a on walls (2 off) at any height.
- **Gates**: prison_gate001c fills a 192 corridor wall to wall (96 to each wall, 62 up), its door
  prison_slidingdoor001a in it (60 up), named and moved; prison_archgate002a/b/c over wider ways.

## 8. Yards, towers, walls (d2_prison_01, the way in)

- Yards wall to wall 420 to 1632 (median 1104, 217 cuts); the rim on the low side 128 to 366, the high side 253 to
  617; ledges along the yard walls most often 80 wide (7 cuts).
- **Gun towers** (d2_prison_01 1300 -4700 1790): an octagon of concrete (corners cut, func_detail) 160 across on the
  wall top, a floor of metalgrate013a, posts 32 by 44 and 128 high with gaps between, a roof slab 176 across 8 thick
  on them; bunker_gun01 40 over the floor, 58 off the parapet, facing out, a point_spotlight 147 226 240 1024 by 64
  parented to it (7 of 7). Combine wall lights on the yard walls with their beams (768 by 96).
- Fences: exterior_fence002b to e (chain link) along the yard edges, interior_fence003b about 196 apart.

## 9. The depot and the trains (d2_prison_06)

- combine_train02a/b cars 632 apart on two lines (Train_L, Train_L2), every car a prop_dynamic parented to its
  train, the pods parented with it (56 cell_01_pod); the train runs in the Combine trench (6).
- The depot hall round it is the Combine's (20% of the map's brush area): metalwall077a at 0.5, combine_light002a
  with beams, combine_generator01 in rows of three 72 apart (-16 56 128 at y 576), combine_fence01a/b, consoles.
- freightelevator props with their button; the Combine's own doors (combine_door01) with a lock each side.

## 10. Brush and texture craft

- Texture scale 0.25 on 80 to 98% of area (Combine metal 0.5). Lightmapscale 16 on 46 to 86% of faces, and 8 on 10
  to 25% in 02 to 08 (the city 3 to 4%): whole rooms at 8, walls and floors alike, not tied to lamps.
- Trims: metalwall062a is the commonest trim (window and door frames, 45 to 89 a map), then tilestair001a nosings
  and the plaster's lower band; sections 16x16, 8x12, 2x12. Ledges: bands 96 to 256 up, 16 out.
- Chamfers small: 4 off (5.7 wide) and 3 off (4.2) commonest (the city: 8); round brushes 12-sided, radius 12 to 19.
- func_detail 29 to 57% of brushes.

## 11. Cross-sections against ours

- Ours: the cells module's corridor is 128 wide and 128 high; Valve's prison corridor is 192 by 120 to 128 (245
  nodes) or 128 by 192 (27): ours is Valve's narrow kind under the low kind's ceiling.
- Ours: our cells are 128 by 160 by 128 inside, a corridor in front; Valve's are 128 by 176 by 120, two or three
  tiers over a hall 224 to 448 wide, walks 56 to 80.
- Ours: the cells' walls are brick to a 56 dado with a stone rail (City 18's); Valve's prison is plaster in two
  tones changing at 128 with no rail.
- Ours: the depot hall is 768 by 384 by 192 with upright clad walls; Valve's Combine halls lean 14 to 23 degrees,
  and d2_prison_06's nodes stand under 208 most often (93), then 184 (36).
- Ours: the armoury's corridor is 128 by 128 and its vault 384 by 256 by 160; Valve's guard rooms and offices sit in
  rooms 192 to 256 wide under 128 to 192.
- Ours: the Combine bay from City 18 (c18_cell_a) is 188 by 237 by 216: wider, deeper and taller than Valve's cell.

## 12. Check ideas

1. Cell rows: a cell narrower than 112 or deeper than 192, or a door opening under 48 or over 64 wide.
2. Tier walks: a walk under 48 or over 96 wide with no handrail prop along its edge every 128 or so.
3. combine_light002a without a light_spot and a point_spotlight within 32 (map_lint offlamp extension).
4. A row of cage lamps (5 or more at 128 to 160) all lit: note it (Valve lights one in five to ten in a cellblock).
5. Combine props: a combine_light002a on an exact 90 facing a bare wall (note); a pod rack or fence off square (warn).
6. Prison corridor gates: a prison_gate001c that does not reach both walls (gap over 8).
7. Combine wall pieces: share of sloped wall area (Valve 7 to 14% in its own halls; ours 0).

## What did not work

- Brush boxes square off leaning faces, so the cut-aways show the Combine's slopes as steps; the lean numbers come
  from face normals instead.
- Cell finding by door lintels missed rows whose doors are brushes or gates; finding by partitions (16 by 176 by 120
  to 136 in rows at a steady pitch) found 71 cells; rows with uneven pitch in d2_prison_07 are mixed rooms.
- Lightmapscale 8 could not be tied to lamps or bars (33% within 192 of a light, against 39% at 16).
- Many of the prison's floors are 8 slabs over voids, so floor-below from props sometimes lands on the storey under.
