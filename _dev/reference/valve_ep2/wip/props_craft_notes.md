# Episode Two, the countryside: props, building craft and cross-sections (work in progress, 21 November)

From the 18 ep2_outland maps and 25 EP2 style rooms, read with `_dev/tools/ingest/vmf.py` (hidden objects and the
3D skybox left out). "Nodes" are AI walking nodes, standing in for where players walk. Density: trees per square
1000 a side. The scripts stayed in the chat's scratch folder.

## 1. Forest layout (the owner's first ask)

Trees in play (cards apart): 01 180, 05 155, 06a 446, 07 313, 08 173, 09 158, 10 439, 10a 613, 12 479, 12a 90.
tree_pine04/05/06 make half to three quarters, tree_dead01-04 and tree_dry01/02 10 to 25%, tree_deciduous_01a/03a
5 to 10%, tree_pine_large 3 to 6%. All `prop_static`, solid, casting shadows.

- **Spacing**: nearest other tree, median 148 (05), 154 (01), 165 (10a), 206 (10), 244 (12), 252 (09), 261 (06a),
  294 (07), 298 (08). Ours (simulated `Forest.plant`): 132.
- **Alone, not clumped**: 54 to 97% have no other tree within 160; only 01, 05, 10a put a quarter in groups of
  three or more (largest 11, 14). Ours: 27% alone.
- **Density by distance from the walk**: 0-128 0.1 to 7 (the path kept clear), 128-256 0.5 to 8, **256-512 2.2 to
  10.6 (the thickest band in most maps)**, 512-1024 1.8 to 6.4, beyond 1024 0 to 3, then cards. Whole box 2.6
  (06a) to 5 (01). Ours: about 14 over the valley (21 before pond and paths), 28 on the ridge band.
- **Clearings**: 44 to 82% of the 512 squares with ground hold no tree (10a 0.44, 12 0.47, 10 0.48, 01 0.57, 06a
  0.59, 07 0.73).
- **Footing**: origin below the ground under it, median 5 to 13, the deepest tenth 20 to 54 (slopes). Ours: 8.
- **Lean**: more than 2 degrees on 0 to 61% (05 61, 06 57, 01 43, 08 23, 12 20, 10a 15, 06a 14, 10 10, 07 7, 09
  0), median of those 4 to 11, 90th 10 to 27. Ours: none. Yaw on 15 degree steps 53 to 99%.
- **Fades** 4200 to 7000 (07 all 7000; 10a 2200 on 164 small ones). Ours 2800 to 3400.
- **Undergrowth** (fern01 nearly always, fern01lg, grass_cluster03a, shrub_01a): 6 to 155 a map, 0.04 to 0.5 per
  tree, never solid; median 70 to 370 from the walk, 110 to 500 from a tree: it edges the path. Ground cover is the
  detail sprites (`detailmaterial` detail/detailsprites everywhere) of blendgrassdirt01, with the no-sprite twin
  `blendgrassdirt01_noprop` on walked ground (07: 14,763 against 6,246 by area). Ours: 170 a forest (0.74 a tree).
- **Logs and stumps** 2 to 133 a map, tilted 39 to 100%. **Rocks** 17 to 174 a map, tilted over 5 degrees 41 to
  76%, median 160 to 340 from a tree. Ours: 34 rocks, 12 logs, none tilted.
- **Terrain**: floor displacements power 2 on 60 to 80% (3 on the rest, 4 on six in 07), 441 to 1024 a side
  (a vertex every 128); alpha painted on 38 to 97%. Ours: 512 at power 3 (every 64).

## 2. How a forest is bordered

- **Cards past the last trees**: `tree_pine_card_cluster_01/02`, `tree_deciduous_card_01`,
  `tree_pine_tall_cluster_01`, 3 to 42 a map, median 870 to 2340 from the walk and 500 to 1200 beyond the last real
  tree, not solid in most maps. In 12 no real tree stands beyond 512 from the walk.
- **Invisible walls on the slopes**: 26 to 177 `toolsplayerclip` brushes a map, median 54 to 570 from the walk,
  tall (median 336 to 896), 192 to 576 long, half off the axes.
- **Steep ground and cliffs**: steep displacement 0.13 to 1.43 of the flat area; `cliff01a/02a/04a`, rockcliff01b/c/j
  and rockcliff_cluster02a/b at their feet 80 to 530 from the walk; `clifftrees_cardboard01a/02a` displaced faces
  in 01 paint trees on the cliffs (1,562 of displaced area).
- **The 3D skybox holds no trees**: brushes painted `mountainrange_far_*`, `mountains_skybox02`, `groundplane_01c`
  (8 to 44 brushes, 0 to 11 displacements), Citadel cloud models.
- **Rail fences** `props_forest/fence_border_*` and `fence_trail_*` (128/256/512; 271 in six maps) chained end to end
  (nearest piece 130 to 264), 145 to 260 from the walk, 73 to 86% off the axes; chain-link only at yards and bases.
- **Roads**: gravel blends on displacements (blendgravelgravel02b, blendgrassgravel01/003a, forest_road01) with
  `road_dirt_01a/b` rut overlays about 300 square chained every 215 to 290.
- Ours: a 4096 valley inside a ridge 440 high, thickest planting on the ridge, the city's skybox.

## 3. Mines, antlion tunnels and the nest (the owner's second ask)

Rays from every node (16 ways level at 40 up, up, down) in 01a, 02, 03, 04. "Cave": displaced roof and walls.

- **Natural passages** (nodes 297, 40, 287, 281): narrowest width median 298, 131, 266, 219 (tenth 117 to 180);
  height median 243, 148, 243, 220 (quartiles 158 to 190 and 319 to 371). 60 to 74% of cave nodes in tunnels under
  384, 17 to 20% in chambers 512 or more, a chamber's long way 1500 to 1840 (75th percentile). Ours: the cave on a
  320 by 320 square; the nest about 345 wide, 760 in its chambers (`NestTube` radius 150 to 330).
- **Built galleries**: 192 high (median, every map), 294 to 365 wide; timber sets are models,
  `props_mining/struts_tunnel192_01..03` and `struts_tunnel320_01..05`, every 160 to 280 (median 192 to 280),
  square in 69 to 100%; `struts_single01/02` posts every 90 to 170, `struts_wall02/03` every 250 to 450. None in raw
  cave. Ours (`raven-mine-sets`): a set every 512.
- **Surfaces**: `rockwall_cave02a` (01a 3,258), `blendrockslime02a` (03 3,035, 04 5,618), `blendrockdirt_tunnel03a`,
  `blendrockblack02a`, the web `antlion_web01a` (456 to 582); mine floors `blenddirtrock_mine01a`. 948 to 1708
  displacements a cave map.
- **Grubs** (01a 93, 03 143, 04 96, style room 100): groups of two to four, nearest grub 23 to 51, groups 100 to 200
  apart; half on walls (pitch or roll 45 to 135), 0 to 13 on ceilings. **A small light in each group**, median 30
  to 43 from it, `_light` 255 245 157 at 30 to 80, quadratic: 38 to 60 a map. Ours: 19 grubs one at a time every
  110 at the wall feet, six lights in the nest (190 255 130).
- **Light**: 69 to 128 lights a cave map, all steady and quadratic: grub yellow 255 245 157, cage lamps 255 226 174
  (80 to 136), a cold fill 132 158 202 at 25 (half of 04's). Node to nearest light median 165 to 185, 90% within
  430 to 600. Fog 18 23 35 from 1 to 2800 everywhere. Ours: 7 lights in the 3072 cave, 6 in the 2560 nest.
- **The nest** (04): `nest_lrg_flat` 78 and `nest_med_flat` 30 on the floors, `websackhalf/_b/_c` 32 on walls,
  `websackceiling01-05` and `websackceilingbig01/02/05` overhead, `grubtunnel_door` 6 to 15 a map plugging side
  holes, `nest_extract` and `larval_essence` at the end. Stalactites (`stalactite_static01-04`) 12 to 50 a map.
- **The guardian's ground**: 190 to 380 across at the narrowest, 1000 to 1740 long, 230 to 290 high; `cavernbreed`
  1, `incavern` 1, `shovetargets` naming rocks (04).

## 4. White Forest and the rocket silo (the owner's third ask)

Maps: **11** the base and the **rocket silo** (the core one); **11a** Silo 2 (visgroups `Silo_2`, `Silo2_stairwell`,
`Silo2_ramped_exit`), flooded at its foot, missile doors on top; **11b** hangar and surface in snow; **12** the
strider battle round the barns; **12a** launch control, hangar, the ending barn (its rocket is `rocket_low` on a
`func_tracktrain` in an open set, not a shaft).

### The core silo in ep2_outland_11: exact bounds

- **The block**: **x 1280 to 2368, y -10480 to -9392, z -1792 to 64** (1088 x 1088 x 1856), axis **x 1824, y
  -9936**. 1,765 brushes lie wholly inside (674 world, 957 func_detail, 37 func_brush, 21 func_tracktrain, 14
  func_door_rotating, 8 func_door, 13 func_viscluster) and 790 entities (159 prop_static, 87 info_node, 74
  info_target, 47 env_sprite, 39 light, 35 light_spot, 29 prop_physics, 28 keyframe_rope, 24 prop_dynamic, 21
  env_cubemap, 17 scenes, 16 scripted_sequence).
- **Four mouths** (brushes crossing the edge): north x 1824-1904, y -9432 to -9232, z -1408 to -832 (to the lab);
  north-east x 2144-2560, y -9584 to -9264, z -1280 to -1152; north-west x 1344-1580, y -9520 to -9296, z -1472 to
  -1248; west x 1184-1440, y -10080 to -9792, z -320 to 128 (the lift from the surface, `elevator_2`).
- **Shaft**: a **24-sided cylinder**, flats 254 from the axis (256 to the corners, sides turned 7.5 degrees),
  `concretewall010a` lined with `metalwall069a`, from the floor at z -1406 to -300; a **24-sided collar at 381**
  from -252 to 32; the **lid** a world slab z 32 to 64 over the whole block; open sky above z 84.
- **Pit**: grate `metalgrate014a` at z -1568 over `metalhull003a` at -1728, x 1632-2016, y -10112 to -9760; an
  inner ring wall 127 to 159 from the axis (`concretewall073b`, `ep2_concretewall01b/c`).
- **Levels**: full 24-sided ring floors (150 to 256 out) at z -1406 (`concretefloor039b`), -832 (slab -896 to
  -832), -576, gantry -320 (`metalgrate_silo01a` on `metaltruss011a/017a`, func_detail); grates
  `metalgrate_silo01b` inside 150 at -1406, -832, -576 hug the rocket. Ring rooms from 256 out to 508-552 open at z
  -1404 to -1308, -828 to -684, -540 to -348, -300 to -204 (790 to 980 deep at the top gallery); their floors
  -1408, -1280/-1216, -1152, -832, -640/-576, -448/-384/-320, -160/-128/-96.
- **Leave out (the rocket)**: `props_silo/rocket.mdl` (z -473), `rocket_stage1` (-1381), `_stage2` (-989),
  `_stage3` (-801), three `rocket_engine` (-1381), `rocket_hatch` (`prop_rocket_hatch`) and `door_rocket_hatch`,
  `steamjet_rocket_*`, `lighting_rocket_1/2`, marks `mark_*rocket*`, `target_rocket_cam`.
- **Silo 2 (11a)**, same design on x 1824, y -11264: 24 sides at 254 from about z -1354 to -200, the collar at 382
  at z 182, water `water_silo_01` z -1344 to -1100, shut by `props_silo/missile_doors` (frame z 161) on two
  `func_movelinear` (`silo_seal_door`, `_2`) sliding 136 along y at speed 5. Ours: the bunker's sliding leaves.

### The base (11, 11a, 12a)

`concretewall010a` is 43 to 45% of brush area; walls banded in 59 to 63% of columns, first change at 64 or 128
(`ep2_concretewall01a > 01c`, `concretewall_bunker05b > 05a`). Corridors (rays from nodes): narrowest median 181 to
248, height median 178 to 192; stairs 8x12 and 8x16. Doors: `props_silo/silo_door01` prop_dynamic on a func_door 99
x 123; wide ones 80 x 160. Light: cold tubes 224 254 248 (61 of 161 in 11a), warm 252 241 180 in work rooms, red
`light_security` 12 to 32 a map. Dressing (props_silo): `prodcables256`, `wall_wires1/2`, `wall_console1-3`,
`desk_console1a/2/3`, `fuel_cask`, `pushcart`, `tirestack2/3`, `acunit01/02`, handrails.

## 5. Farmhouses, barns, the inn, sheds

- **Timber**: wood brushes barn 620 (276 off the axes), farmyard 1088 (521), inn 495 (203), logging 503 (228).
  Sections: boards 2x4, 2x5; planks 4x13, 2x11/12; studs 4x8, 4x10; beams 10x18, 10x10, 8x8; posts 6x6, 8x8.
  Lengths median 111 (barn), 104 (farmyard), 55 (inn). `woodfloor005a` on most. Roofs 45 and 34 degrees (27 at the
  logging camp). Ravenholm's: 4x8 standing 4 proud, roofs 20 to 35.
- **Decay** (deterioration room against the sound barn, 620 wood brushes each): off the axes 59% against 45%,
  func_detail 75% against 20%, boards median 62 against 111 long, and **539 displacements against none** (power 2
  on 479): boards bowed (woodfloor005a 212, strips 153 x 30-39), tiles sagging (`tileroof003a` 68), tin buckled
  (`metalwall014a` 50), brick (33); the inn bends shingles and stone (139, power 2).
- **Windows**: frame prop_static plus its `_bars` twin prop_dynamic on the same origin (inn 34 of 41, farmyard 33).
- **Rooms**: farmhouses bare (two chairs, a kitchen sink, pot, bucket, shovel); only the inn furnished (13 chairs, 7
  tables, 7 radiators, bed, bath, stove, fridge, 10 unlit dome lamps, boards over openings). A Resistance outpost
  (radio tower b, the house in 06a): bunk beds, prison sinks, toilet, boiler, propane, boxes, pallets, drums,
  tires, file cabinets, a clock, bare bulbs.
- **Radio mast** (06a): `props_radiostation/radio_antenna01` with three anchors (`radio_antenna01_pylon`) at yaw
  180, 300, 60, 1051 to 1662 out, each with three `radio_antenna01_stay` pitched 30/45/52 (48/58/64); antennas
  `antenna03a` on nearby roofs, a `radio_station_roof` hut, `radio_antenna01_skybox` in the skybox.
- **Bunkers** (style room): walls 32 thick (`concretewall_bunker01a/b/c`), piers 24 x 32, `blastdoor001a`; the
  concrete meets the hill through a `blendbunk_conc01` displacement (12 too).

## 6. Light and sky

Outdoor sun by map shows the day going on: 01, 06a, 07 pitch -35, `240 238 217` 600 (05, 08 650); 09, 10 pitch -25,
`242 210 189` 700; 12 pitch -35 `240 185 130` 800; 12a pitch -15 `240 184 130` 750 with ambient `70 124 164`.
Ambient mostly `144 175 198` at 145 to 280. Fog blue-grey (60-67, 73-88, 87-105), start 64 to 512, end 4500 to
8000, farz 6200 to 14000; skybox scale 16. The vista room's sun stands at pitch -4 (`205 166 48`, a sunset).
Forests have no lights of their own. Ours: the city's one sun and skybox serve the forests.

## 7. Combine architecture (Episode Two)

Little is built: an outpost in a farmhouse in 07 (88 brushes of `citadel_metalwall077a/091a/060a`, x -10136 to
-9272, y -9804 to -9399, z 53 to 496: 864 x 405 x 443; 70% off the axes; plates 2 to 6 thick; 60 func_detail, 22
func_lod, a `func_movelinear` generator; `combine_lock01`, `combine_wire002`, `combine_interface001`); the advisor's
pod and platform in 05 (`advisorpod`, `combine_podholder`, func_brush `advisor_platform`); the roadblock in 10 (seven
`combine_barricade_tall01b` 58 apart each turned 15 from the last, 21 brackets, fences, `combine_emitter01`,
force fields `comshieldwall3` in garage doors); a cannon in 09 (`combine_cannon_gun`, `_powergen`, `_stand`).
White Forest reuses `citadel_metalwall060a` on 53 world brushes leaning 11 and 24 degrees (corridor roofs, 11).

## 8. Cross-sections against ours

- The way through the country: open floor median 312 to 712, 828 to 972 across at 64 up (cut widths, nine maps).
  Ours: an open valley 4096 square for roleplay, the owner's; keep it, but plant it in bands along the trail.
- Forest edge: Valve, clip on the slope and cards 1000 to 2000 out. Ours: a ridge 440 high planted thickest.
- Cave: Valve tunnels about 250 x 200, chambers 512 to 1800. Ours: 320 x 320, nest 345 to 760.
- Gallery: Valve 192 high, 290 to 365 wide, sets every 192 to 280. Ours: the office rooms; no gallery yet.
- Silo: Valve's shaft 512 across, 1106 tall to the collar, block 1088 square. Ours: the bunker, no shaft.
- Base corridor: Valve 181 to 248 wide, ceilings 192. Ours: bunker doorway 256 x 192, inner doors 128 wide.

## 9. Check ideas

Tree gap median, share alone within 160 and empty 512 squares printed by map_forest; every tree at least 4 below
the lowest ground under its trunk; card props within 600 of the trail flagged; share of rocks tilted; cave rays
from path nodes (width, height quartiles); largest gap from a cave node to a light (under 600); a grub with no light
within 160; a `_bars` window with no frame within 2; the lifted silo sealed and free of rocket entities.

## 10. What did not work

The 3D skybox finder gives nothing for the cave maps, 11, 11a, 11b (no sky_camera room); 12a's rocket is not in a
shaft. Street detection reads open country as "streets" (wall to wall up to 1900): use the cut widths instead.
Grub orientation is read from pitch and roll only. Ray casts ignore props, so passages narrowed by rocks read wider.
No scipy here: nearest-neighbour by brute force (fine at these sizes). Branching of the cave tunnels from the node
graph (links within 1.6 times the node spacing) gave 0.4 to 0.6 junctions per 1000 of links, too rough to use: wide
places link across. Pictures were not looked at.
