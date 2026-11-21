# Episode Two, the countryside: props, building craft and cross-sections (work in progress, 21 November)

Read from the 18 ep2_outland maps and 25 of Valve's EP2 style rooms with the repo's own reader
(`_dev/tools/ingest/vmf.py`), Hammer-hidden objects and the 3D skybox left out. "Nodes" are the AI walking nodes,
standing in for where players walk. Density is trees per 1,000,000 square units (a square 1000 a side). Scripts that
made the numbers were kept in the chat's scratch folder only.

## 1. Forest layout (the owner's first ask)

Trees in play (cards left out): 01 180, 05 155, 06a 446, 07 313, 08 173, 09 158, 10 439, 10a 613, 12 479, 12a 90;
styleguide_forest_01 62, styleguide_logging 106. Models: tree_pine04, 05, 06 make half to three quarters of every
forest, then tree_dead01 to 04 and tree_dry01, 02 (10 to 25%), tree_deciduous_01a/03a (5 to 10%), tree_pine_large
(3 to 6%). Every tree is a `prop_static`, solid (vphysics), casting shadows.

- **Spacing.** Nearest other tree, median: 148 (05), 154 (01), 165 (10a), 206 (10), 211 (12a), 244 (12), 252 (09),
  261 (06a), 294 (07), 298 (08); the 10% closest 79 to 179. Ours (simulated from `Forest.plant`): median 132, 10%
  at 95; Valve's typical gap is half as far again to twice ours.
- **Alone, not clumped.** With trees linked when within 160: 54 to 97% stand alone (no other within 160). Only
  01, 05 and 10a put a quarter of their trees in groups of three or more (largest 11 and 14). Ours: 27% alone.
- **Density.** Over all the ground in the trees' box: 2.6 (06a), 5 (01), about 3 to 6 elsewhere. By distance from
  the walk: 0 to 128 off the path 0.1 to 7 (thin: the path is kept clear), 128 to 256 0.5 to 8, **256 to 512 2.2 to
  10.6 (the thickest band in most maps)**, 512 to 1024 1.8 to 6.4, beyond 1024 0 to 3 (then cards). Ours: about 14
  over the whole valley (21 before the pond and paths take theirs), 28 on the ridge band.
- **Clearings.** Of the 512 squares with ground in the trees' box, 44 to 82% hold no tree at all (0.44 10a, 0.47
  12, 0.48 10, 0.57 01, 0.59 06a, 0.73 07). Open ground is the rule; the woods are bands and islands along the way.
- **How trees meet the ground.** Origin below the displaced ground under it: median 5 to 13, the 10% deepest 20 to 54
  (on slopes). None stand on the surface. Ours: a fixed 8 down: right in the middle; deeper on slopes would match.
- **Lean.** 0 to 61% of trees lean more than 2 degrees (01 43%, 05 61%, 06 57%, 08 23%, 12 20%, 10a 15%, 06a 14%,
  10 10%, 07 7%, 09 0%); median lean of those 4 to 11, the 90th 10 to 27. Ours: none lean.
- **Yaw** on 15 degree steps for 53 to 99% (the rest free). Fades: fademaxdist mostly 4200 to 7000 (07 all 7000;
  10a 2200 for 164 small ones); ours 2800 to 3400.
- **Undergrowth is sparse and lines the path.** Plants (fern01 nearly always, fern01lg, grass_cluster03a, a few
  shrub_01a): 6 to 155 a map, 0.04 to 0.5 per tree, never solid, half tilted in 10 and 10a. Median distance from the
  walk 70 to 370, from a tree 110 to 500: ferns edge the path, not the tree feet. Ground cover is the detail sprites
  (every map sets `detailmaterial` detail/detailsprites, `detailvbsp` detail.vbsp) on blendgrassdirt01, with its
  twin `blendgrassdirt01_noprop` (no sprites) on the walked ground (07: 14,763 against 6,246 by area). Ours: 170
  plants a forest (0.74 per tree).
- **Logs and stumps**: 2 to 133 a map (tree_stump01, fallentree01/02, fallentree_dry01/02, forest_log01; in 12 the
  sawmill's tree_slice01/02 as physics props); 39 to 100% tilted; median 110 to 500 from a tree.
- **Rocks**: 17 to 174 a map (rockcluster01/02, rock_coast02a to h, rocks_large/xlarge*_veg, forestrock_cluster01/02),
  41 to 76% tilted more than 5 degrees, static; median 160 to 340 from a tree, 180 to 940 from the walk. Ours: 34 a
  forest, none tilted.

## 2. How a forest is bordered

- **Cards, then the painted sky.** Past the last trees (about 1000 to 2000 from the walk) stand
  `tree_pine_card_cluster_01/02`, `tree_deciduous_card_01`, `tree_pine_tall_cluster_01`: flat clumps, not solid in
  most maps (0.8 to 1.0), median 870 to 2340 from the walk, 500 to 1200 beyond the last real tree. 3 to 42 a map.
  The 3D skybox holds no trees at all: it is brushes painted with `mountainrange_far_*`, `mountains_skybox02`,
  `groundplane_01c` (and Citadel clouds), 8 to 44 brushes, 0 to 11 displacements.
- **Invisible walls on the slopes.** 26 to 177 `toolsplayerclip` brushes a forest map, median 54 to 570 from the
  walk, tall (median 336 to 896) and 192 to 576 long, half of them turned off the axes: the player is stopped by a
  clip laid over a slope or along the trees, never by a wall he sees.
- **Steep ground.** Steep displacement (more than about 53 degrees) is 0.13 to 1.43 of the flat ground's area;
  cliff materials `cliff01a`, `cliff02a`, `cliff04a` with rockcliff01b/c/j and rockcliff_cluster02a/b models
  dressing their feet 80 to 530 from the walk.
- **Rail fences along the way.** `props_forest/fence_border_128/256/512` and `fence_trail_128/256/512` (271 in
  five maps): chained end to end (nearest piece 130 to 264 apart), 145 to 260 from the walk, turned freely (73 to
  86% off the axes), border fences never tilted, trail fences a quarter tilted 5 to 10. They mark the edge of the
  road and trail; chain-link (`exterior_fence002*`) is kept to the bases and yards.
- Ours: a ridge 440 high round a 4096 valley, thickest planting on the ridge (`d < 380`), the city's skybox over it.

## 3. Mines, antlion tunnels and the nest (the owner's second ask)

Measured by casting rays from every AI node (16 ways level at 40 up, one up, one down) against displacements and
solid brushes. "Cave" nodes have a displaced roof and displaced walls; "built" ones a brush roof (mine galleries,
the Resistance's works). Maps: 01a (the mine and first grub caves), 02 (the vortigaunt cave, the extract), 03 (the
long dig, the mine works, the tall and water caves), 04 (the nest, the guardian's maze); style room `caves`.

- **Natural passages** (cave nodes 297, 40, 287, 281): narrowest width median 298 (01a), 131 (02), 266 (03), 219
  (04); 10% under 117 to 180; height median 243, 148, 243, 220, a quarter under 158 to 190, a quarter over 319 to
  371. 60 to 74% of cave nodes are in tunnels under 384 wide, 17 to 20% in chambers 512 wide or more; the longest
  way across a chamber 1500 to 1840 (75th percentile). So: about three parts tunnel 220 to 300 wide and 160 to 240
  high to one part chamber 512 to 1800 across. Ours: the cave is hung on a square 320 wide and 320 high, the nest's
  tube about 345 wide narrowing to 760 in its chambers (radius 150 to 330): in Valve's upper quarter, chambers
  about a third of the nest's length.
- **Built galleries**: height 192 at the median in every map (q25 176 to 192), width median 294 to 365. The mine's
  timber sets are models in two sizes, `props_mining/struts_tunnel192_01..03` and `struts_tunnel320_01..05`, one
  every 160 to 280 along the gallery (median 192 to 280), square to the grid in 69 to 100%; `struts_single01/02` (a
  lone post, every 90 to 170), `struts_wall02/03` (every 250 to 450), `struts_ceiling02`. 42 to 88 sets a cave map.
  Ours (Ravenholm lesson `raven-mine-sets`): a timber set every 512 in a displacement cave. Valve's are twice as
  close where it is a gallery, none in the raw cave.
- **Ground and walls**: displacement materials by area: 01a `rockwall_cave02a` (3258), 03 and 04
  `blendrockslime02a` (3035, 5618), `blendrockdirt_tunnel03a`, `blendrockblack02a`, and the nest's web
  `antlion_web01a` on 456 to 582 of displaced area; mine floors `blenddirtrock_mine01a`, `dirtfloor_mine001a`. Power
  2 is 89% of 01's displacements; caves use 948 to 1708 displacements a map.
- **Grubs** (01a 93, 03 143, 04 96, style room 100): in **groups of two to four**, the nearest grub 23 to 50 away
  (median), groups 100 to 200 apart; half of them on walls (pitch or roll 45 to 135), 0 to 13 on ceilings; a
  quarter within 60 of the walk, half within 110 to 320. **A small light sits in each group** (median 30 to 43 from
  the nearest grub in 01a and the style room): `_light` 255 245 157 (a pale yellow-green), brightness 30 to 80,
  quadratic, fifty-percent at 300 in 01a. 38 to 60 of these a map. Ours (`NestTube`): 19 grubs one at a time every
  110 along the wall feet, all upright, and six lights for the whole nest (greens 190 255 130).
- **Light in the caves**: 69 to 128 lights a map, all steady (style 0), quadratic. Three kinds: the grubs' yellow
  (255 245 157, 30 to 80), the miners' cage lamps (255 226 174, often 80 to 136, on `light_cagelight02_on`), and a
  cold dim fill (132 158 202, brightness 25: half of 04's lights). Every walking node is within 165 to 185 of a
  light at the median, 90% within 430 to 600. Fog 18 23 35 from 1 to 2800 in every cave map.
- **The nest** (04): `props_hive/nest_lrg_flat` 78 and `nest_med_flat` 30 laid on the floors, `websackhalf`, `_b`,
  `_c` 30 on walls, `websackceiling01..05`, `websackceilingbig01/02/05` overhead, `grubtunnel_door` 6 to 15 a map
  (the web plugs of side tunnels), `nest_extract` with `larval_essence` at the end. Hive crust is the displacement
  material, never brushes.
- **The guardian's ground**: the guard stands in a passage 190 to 380 across at its narrowest, 1000 to 1740 long,
  230 to 290 high (02, 03, 04, style room): the long cave lets him charge. Flags `cavernbreed` 1, `incavern` 1, and in
  04 `shovetargets` naming rocks he throws.
- **Stalactites** (`props_mining/stalactite_static01..04`, `stalactite_cluster01`) 12 to 50 a cave map, with
  `caverocks_cluster01/02` heaped on the floors; `rock_forest01/02` and rockgranite02a as fallen rock.

## 4. White Forest base and the rocket silo (the owner's third ask)

Which map is which (from the visgroups and entities): **ep2_outland_11** the base under the hill and the **rocket
silo** with the rocket being finished (the core silo); **11a** the second silo (visgroups `Silo_2`,
`Silo2_stairwell`, `Silo2_ramped_exit`, `fallendoor_silo2`), flooded at the foot, with the sliding missile doors on
top, where the Combine come in; **11b** the hangar and the surface buildings in snow; **12** the strider battle
round the base's barns and yards; **12a** the launch control room, the hangar and the ending barn (its rocket is a
`rocket_low` model on a `func_tracktrain` in an open set, not a shaft: not worth lifting).

### The core silo in ep2_outland_11: exact bounds

- **The silo block** (every brush inside it lies within; a slab lids it): **x 1280 to 2368, y -10480 to -9392,
  z -1792 to 64** (1088 by 1088 by 1856), centred on the rocket's axis **x 1824, y -9936**. Inside: 1,765 brushes
  (674 world, 957 func_detail, 37 func_brush, 21 func_tracktrain pieces, 14 func_door_rotating, 8 func_door, 9
  trigger_multiple, 13 func_viscluster) and 790 entities (159 prop_static, 87 info_node, 74 info_target, 47
  env_sprite, 39 light, 35 light_spot, 29 prop_physics, 28 keyframe_rope, 27 info_overlay, 24 prop_dynamic, 21
  env_cubemap, 18 ambient_generic, 17 scenes, 16 scripted_sequence...).
- **Ways out of the block** (brushes crossing its edge): north at x 1824 to 1904, y -9432 to -9232, z -1408 to -832
  (to the lab); north-east at x 2144 to 2560, y -9584 to -9264, z -1280 to -1152; north-west at x 1344 to 1580, y
  -9520 to -9296, z -1472 to -1248; west near the top at x 1184 to 1440, y -10080 to -9792, z -320 to 128 (the lift
  from the surface, visgroup `elevator_2` at x 1284 to 1419). A piece lifted whole needs these four mouths capped.
- **The shaft**: a **24-sided cylinder**, its flats 254 from the axis (256 to the corners; the sides turned 7.5
  degrees off the axes), `concretewall010a` lined to its full height with `metalwall069a` panels; straight from the
  floor at z -1406 to z -300 (1106). Over it a **collar of 24 sides at 381** (384) from z -252 to 32, and the lid
  (world slab z 32 to 64, x 1280 to 2368, y -10480 to -9392) closing it; above z 84 is open sky.
- **The pit** under the rocket: a grate (`metalgrate014a`) at z -1568 over a floor at z -1728 (`metalhull003a`),
  x 1632 to 2016, y -10112 to -9760; an inner ring wall at 127 to 159 from the axis (`concretewall073b`,
  `ep2_concretewall01b/c`, `concretewall062a`).
- **Levels in the shaft** (floors between 150 and 256 from the axis, each a full 24-sided ring): z -1406 (the
  shaft floor, `concretefloor039b`), -832 (a slab -896 to -832), -576, and the gantry at -320 (`metalgrate_silo01a`
  on `metaltruss011a/017a` trusses, func_detail); inside 150, grates `metalgrate_silo01b` at -1406, -832, -576 hug
  the rocket. Ring rooms from 256 out to 508 to 552 open off the shaft at z -1404 to -1308, -828 to -684, -540 to
  -348 and -300 to -204 (a wide opening at the top gallery, 790 to 980 deep); their floors at -1408, -1280/-1216,
  -1152, -832, -640/-576, -448/-384/-320, -160/-128/-96.
- **The rocket, to leave out**: prop_static `props_silo/rocket.mdl` (origin z -473), `rocket_stage1` (z -1381),
  `rocket_stage2` (-989), `rocket_stage3` (-801), three `rocket_engine` (-1381), prop_dynamic `rocket_hatch`
  (`prop_rocket_hatch`, -474) with its func_door_rotating `door_rocket_hatch`, env_steam `steamjet_rocket_*`,
  info_lighting `lighting_rocket_1/2`, and the scene marks `mark_*rocket*`, `target_rocket_cam`, all on x 1824,
  y -9936.
- **Silo 2 (11a)** is the same design on axis x 1824, y -11264: the 24 sides at 254 from z about -1354 to -200,
  a ring at 239 at z -106, the collar at 382 at z 182; water (`water_silo_01`) from z -1344 to -1100 in its foot;
  the top shut by `props_silo/missile_doors` (frame z 161) moved by two `func_movelinear` (`silo_seal_door`,
  `_2`) sliding 136 apart along y at speed 5. Ours: the bunker's two sliding leaves (`BunkerForest.door`) already
  work this way.

### The base round it (11, 11a, 12a)

- One rough pale concrete, `concretewall010a`, is 43 to 45% of all brush area in 11 and 11a; banded in 59 to 63%
  of wall columns, the first change at 64 or 128 (`ep2_concretewall01a > 01c`, `concretewall_bunker05b > 05a`,
  `06a > 06c`); floors `concretefloor_bunker02a`, `concretefloor006a`; ceilings `concreteceiling_bunker01a`.
- Rooms: ceilings median 192 (quartiles 186 and 229 in 11; 144 and 252 in 11a); stairs 8 by 12 and 8 by 16.
- Doors: the sliding steel door is a `props_silo/silo_door01` prop_dynamic carried by a func_door 99 by 123 (5 to
  12 a map); wide ones 80 by 160. Lights: cold fluorescent tubes (224 254 248, 61 of 161 in 11a) in
  `prison_flourescentlight001a` and `lab_flourescentlight001a/002b`, warm 252 241 180 in work rooms, red alarm
  lamps (240 51 30, `light_security`, 12 to 32 a map), `wall_light` and `industriallight01` in the silos.
- Props in the base (props_silo): `prodcables256`, `wall_wires1/2` along walls, `wall_console1..3`,
  `desk_console1a/2/3`, `fuel_cask`, `pushcart`, `tirestack2/3`, `acunit01/02`, `electricalbox01/02`,
  `handrail_alley-upperdeck`, `handrail_singlespan_128`.

## 5. Farmhouses, barns, the inn, sheds: timber and decay

- **Timber is brush, in small sections, much of it off the square.** Wood brushes (most faces wood): barn 620
  (276 off the axes), farmyard 1088 (521), inn 495 (203), logging camp 503 (228), farmhouse1 127, farmhouse2 97.
  Sections (the two short sides): boards 2x4 and 2x5 (barn 199 of 620, farmyard 319), planks 4x13 and 2x11/2x12,
  studs 4x8 and 4x10 (farmhouses), beams 10x18, 10x10 and 8x8, posts 6x6 and 8x8 (the logging camp's frames 8x8 on
  112 of 503, the elevator tower 8x8 and 6x8). Lengths median 111 (barn), 104 (farmyard), 55 (inn). Nearly all
  `woodfloor005a` (barn 521, farmyard 832) with woodwall008a/009a/024a for cladding. Ravenholm's houses
  (`raven-timber-craft`) were 4x8 timbers standing 4 proud: the EP2 farms are finer and more often turned.
- **Roofs** pitched 45 and 34 degrees (1 in 1, 2 in 3) on the farms, 27 at the logging camp; Ravenholm's 20 to 35.
- **Decay, read from the deterioration room** against the sound barn (both 620 wood brushes): off the axes 59%
  against 45%; func_detail 75% against 20%; boards shorter (median length 62 against 111); and **539 displacements
  where the sound barn has none**, power 2 on 479 (4 on 36): boards bent (woodfloor005a 212, strips about 153 by 30
  to 39), roof tiles sagging (`tileroof003a` 68), corrugated sheets buckled (`metalwall014a` 50), brick bulging (33);
  95 on ceilings, 354 on walls. The inn bends its shingles and stone the same way (139 displacements, all power 2);
  the large outland house breaks its brick edges with 40 small brick displacements (21x6, 24x6).
- **Windows are two models on one spot**: the frame `woodwall030b_window01a/02a/03a`, `plasterwall029c/g_window01a`
  as prop_static, and its `_bars` twin as prop_dynamic at the same origin (inn 34 of 41, farmyard 33, 07 20 of 21).
- **Farm rooms are bare shells**: farmhouse1 and 2 hold two `furniture_chair01a`, a `sinkkitchen01a`, a pot, a
  bucket, a shovel; the farmyard the same twice. Only the inn is furnished: 13 chairs and 7 tables, 7 radiators, a
  dresser, drawers, two armchairs, two couches, a bed, a bathtub, a toilet, a stove, a fridge, a boiler, 10 unlit
  dome lamps, hay bales and boards (`wood_board03a/04a/06a`) nailed over openings.
- **A Resistance outpost** (radio tower b, and the house in 06a): `bunkbed` and `bunkbed2`, `prison_sink001a`,
  `furnituretoilet001a`, `furnitureboiler001a`, `propane_tank001a` and canisters, `box01a/b`, `wood_pallet001a`,
  `oildrum001`, tires, `kitchen_shelf001a`, file cabinets, a clock, bare bulbs (`lightbulb01a`), dome lamps lit.
- Ours: our bunker rooms and the cave office (`docs/dev/map-building.md`).
