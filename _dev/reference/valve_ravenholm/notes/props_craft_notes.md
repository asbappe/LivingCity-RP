# Ravenholm props, craft and cross-sections (work in progress, 21 November)

Maps: d1_town_01, 01a, 02, 02a, 04, 05 and the style rooms styleguide_ravenholm_01 and styleguide_mining
(d1_town_03 was done before: lessons tagged infestation). Scripts and caches: `<scratchpad>/ravpc/` (cache.py,
lib.py, a_*.py). Per-map numbers: `_dev/reference/valve_d1_town_NN/measure.json`.

What each map is: t01 the town's first streets (Grigori's traps, the pyre); t01a a short run of houses and a
corridor; t02 the town square, the church yard and the tram; t02a the graveyard and the church roof (Grigori's
goodbye); t04 the mine (caves and timber sets); t05 the way out to the railway (Combine and rebels, not infested).
The style room `styleguide_ravenholm_01` is NOT the timber town: a snowy industrial yard (dusk sky, sun
'235 155 71' 700, pipes, APCs, snow blends): an early idea for Ravenholm. Its houses and roofs still match the
town's numbers (timber posts 2x8, roofs 25 degrees, eaves 16).

## 1. Blood and the dead (corrects one map's reading)

d1_town_03 had no blood decals. The rest of Ravenholm has plenty: 189 blood decals in the six maps (t01 146:
bloodstain_101 46, bloodstain_002 42, bloodstain_001 19, bloodstain_003 12, 003b 10, blood1 7, blood2 5);
in t01 47% lie within 128 of a body (median 142), in t01a all 10 within 107 of one.
Bodies: 66 prop_ragdoll (t01 36: classic_legs 10, classic 9, fast 4, classic_torso 4, corpse1 4, charple 3),
mostly spawnflags 4 (debris: players pass through). In t01 they come in two set pieces of 9 and 7 within 128
(the pyre yard, the sawblade room), a 4, three 2s and singles. Crows: 43 (t01 19, median 189 from a body, 13 of
19 within 256; t02 10 and t02a 14 nowhere near a body: crows on the church and graveyard roofs).
Hung dead: 15 meathook001a (13 in t01), prop_physics with motion disabled (flag 8), pitch 0 roll 8 to 15
(lean under 15 on 10), 67% against a wall or post, each tied to a ragdoll by a phys_constraint (pyre_hook_N,
pyre_corpse_N): a hook every 15 to 60 (median 36), hung at 70 to 165 over the ground.

## 2. Trap kits (props; the logic is in valve-logic-recipes style)

- Propane tanks (propane_tank001a, 31: t01 26): all prop_physics, 28 of 31 LYING on their side (the model
  stands upright by default), 5 on a table, 58% within 16 of a wall, nearest other tank median 36; beside
  sawblades (10 of 31), tables, boards, paint cans. Not stood in rows.
- Graveyard gas (canister_propane01a, 6 in t02a): upright, free yaw, groups of 2 and 4 about 33 apart, held still
  (flags 1+2+8).
- Explosive barrels (oildrum001_explosive, 67): 65 of 67 upright, yaw turned (grid 25%), nearest other explosive
  median 128 (q25 57): spread, not in pairs; mixed with plain oildrum001 (91; 10 of the explosive ones have a plain
  one within 96); skins not 0 on 28%; flag 2 (no physics damage) on 16 of 67.
- Sawblades (sawblade001a, 24: t01 17): lying flat on 14, on edge against a wall on 7 (33% touch a wall), on a
  table or another blade on 4, held still (flag 8 plus 64, free when the gravity gun grabs it) on 9; with
  wrenches, pliers, paint cans, a stool and a table: a workbench (t01 2149 -1026: 3 blades, 2 wrenches, 2 paint
  cans, pliers, stool, table, lamp). The blade store (t01 3784 -1117): 11 blades and 11 tanks, boards, paint
  cans, bulbs, and three bodies cut in half.
- Graveyard blades: 5 single blades lying out on the grass 150 to 1050 apart (t02a): ammunition, not a store.
- Propeller trap (t01 has 5; t04 1): engine static, blade a free prop_physics (flag 0) on a phys_hinge and
  phys_motor 30 over the engine, a lever (func_button plus func_rot_button carrying TrapPropeller_lever), a timer
  for the sputter, spin-up / loop / spin-down sounds; the engine, blade and lever all within 30.
- Fire trap (t01 911 -1459): a propane canister, a valve wheel (func_door_rotating carrying valvewheel002) that
  opens the gas, a pad button (func_door_rotating carrying Firetrap_button01a) that sparks, a gas hose model to
  the pyre, 35 env_fire nodes (spawnflags 3, firesize 32 to 130, about 20 apart) over the pyre, env_firesource,
  env_firesensor enabling a trigger_hurt, env_steam heat haze, an orange light '254 174 10 1250', a health kit and
  a spawn point beside the controls.

## 3. Houses: timber and plaster brush craft

- Timber on plaster: 196 wood strips touch plaster brushes (t01 90, t01a 47, t02 59): section 4x8 most (72),
  8x8 26, 4x16 19, 2x16 15; they stand 4 proud of the plaster (85 of 154 measured; then 8 and 2); a third are
  diagonal braces (80 of 196), the rest posts (54, about a storey long, median 124 to 146) and beams (62).
- Roofs: 285 sloped roof brushes in t01 to t02a: pitch 25 most (131), then 35 (43), 45 (38), 20 (28); slabs 3 to 8 thick
  (metal sheet 3 to 4, tile 7 to 8); eaves overhang the wall under them by 16 (median; q25 0, q75 16, a few 48 to
  96 for porches); materials metalwall026a / 014a (corrugated), tileroof004b / 003a, woodshingles002a (church).
- Walls: slabs 8 thick most (t01 171, t02 197, t02a 124), then 16; wall material changes first at 128 (q25 64).
- Windows: glass 40x104 (tall and narrow, glasswindow011a) in t01 and t01a, 80x48 low wide panes, 64x96
  (glasswindow010b) round the square and church; doors door01_left in 48x108 or 56x112 openings.
- Breakable plaster: t01a has plaster patches (func_breakable 1x40x84 plasterwall029g, health 1) to smash through.

## 4. The mine (d1_town_04) and the mining style room

- Timber sets: two 16x16 posts of woodfloor005a 240 apart centre to centre (224 clear), a 16x16 cap across their
  tops, 128 tall (256 where the floor drops), one set every 512 along the tunnel (238 at the mouth), func_detail.
- Shaft cribbing: rings of 16x16 beams round a 192 square, a ring every 190 to 320 up the shaft.
- Walkways: 16x16 posts 64 tall on an 84 grid under planks 4x80 and 4x64.
- Caves: 327 displacements, power 2 on all but 3, 256x256 (290), every one lightmapscale 16, offsets median 60
  (q75 128), a closed tube: wall 181, floor 76, ceiling 70; rockwall015a on walls, blendrockgravel001a floor
  with alpha painted (170 of 327 painted).
- styleguide_mining: woodwall041a braces 16x16 at an angle, concretewall_mine walls, cage lights, vol_light cones.

## 5. The graveyard (d1_town_02a)

26 grave pieces over about 1300 by 1300 of grass displacement (one per 65,000 square units), all prop_static:
headstones (gravestone004a 9, 002a 4, 001a 2, 003a 1), crosses 4, a statue, coffin lids (coffinpiece001a / 002a,
5) lying 60 to 90 in front of a stone. Yaw: 11 square, 9 turned 3 to 20, 5 free; only the three against the wall
stand in a row (86 and 78 apart, same yaw). No pathed rows. The church: stonewall036b walls to 600 tall,
woodshingles002a and metalroof005a roofs, glasswindow010b panes 64x96.

## 6. Light

- Same sun in t01, t01a, t02, t02a: '175 230 239 50', ambient '43 45 57 5', pitch -45, sky_day01_09; no fog but
  the graveyard's (black '0 0 0', 1500 to 4000); the mine has no sun; t05 (out of town) '254 242 160 400' with warm
  fog 1024 to 10000: the light comes back as you leave.
- Clamp lamps (light_spotlight02_lamp, 41): static, 80% touching a wall, 38 pitched down, yaw free on 22; all 41
  have a light_spot (a median 5 away) and a point_spotlight within 48: warm '255 245 145' on 26, cool '159 237 215'
  on 15, brightness median 600 (q75 1000, q90 2000), cone 35 (14), 45 and 50 (8 each), inner 20 or 30, pitch
  median -50 (q10 -65, q90 -20). point_spotlight nearest neighbour median 294 (t01), 368 (t02),
  452 (t01a), 540 (t02a), 780 (t04). light_spotlight01_lamp (17): '159 237 215 1500' or '255 245 145 400', 35/20,
  pitch -30.
- Indoors: lightbulb01a with light '254 216 146 8' (13) and a spot 300 cone 75/30 straight down (8).
- Trap fires: grids of 8 to 46 env_fire 10 to 30 apart (t01 29, 11, 8; t01a 23; t02a 46 and 13), one name each,
  sizes mixed 25 to 130, not lit at the start (spawnflags 3; 34 in t02a), lit together.
- Lightmapscale 64 on 26% of faces in t01 and 36% in t01a (city maps 12 to 13%): roofs, trusses, upper plaster.

## 7. Rooms and story kits

Domestic furniture is nearly gone. Indoor props in the six maps: 26 clamp lamps, 13 bulbs, 9 cafeteria tables, 12
drawers and 6 dressers (all within 16 of a wall, 4 tipped), 6 radiators (held still, on walls), 5 washing machines
by a boiler, 2 couches, 4 mattresses, no stove or fridge.
- Barricaded flat (t01 351 -896): couch, 2 dressers, 2 drawers, a chair by the door, 4 dead zombies, 6 blood
  stains, one warm spot '239 210 156 300', a health kit and a pistol, zombies that get up (scripted_sequence).
- Bedroom (t02 -3800 -180): mattress on prison_bedframe001a, radiator, drawer, bulb, corpse1, decalrug002a.
- Work table (t01a -500 800): 3 tables, 2 meathooks, cinderblocks, a body on the table, a blade, a paint can, a
  clamp lamp with two spots (cool 1600, warm 600), trash decals, 2 health kits.
- Laundry (t02): 5 washing machines 40 to 87 apart, turned 3 to 20, beside radiators and a boiler.
- Corpse rooms: d1_town.CorpseRoom soundscapes radius 128 (t01 2, t01a 1, t02 2) at the blade store, the
  barricaded flat, the work table and the bedroom.

## 8. Loose props in the trap streets

- Physics to static: t01 166 to 157, t01a 40 to 57 (t02 84 to 286, t02a 24 to 255); Valve's 22 earlier maps 2193
  to 6154. Ours (map_raven.py): 8 loose to 24 static.
- Held still (flag 8): 109 of 462 physics props; held and freed on grab (8+64): 51 (t01 38 of 166): blades 9,
  tanks 9, radiators 6, boards 14, propeller blades 3, tables 3. Flag 64 elsewhere: 3.5% of physics props.
- Tilt by kind (physics, t01 to t04): propane 28 of 37 lying, boards 19 of 22 tilted, tools 10 of 28, shelves 6 of
  22; barrels 1 of 58 (they stand: explosive drums must), boxes 1 of 29, tables, crates, cans 0. All 29%.
- Density near nodes: props per 10,000 square units 0.48 (t01), 0.48 (t01a), 0.54 (t02), 0.19 (t02a), 0.20 (t04);
  empty 256 cells 24% (t01), 16% (t01a), 31% (t02), 53% (t02a), 50% (t04).

## 9. Boards, pipes, gutters, poles

- Plank brushes (2 to 6 thick, 6 to 20 wide, 48 to 140 long, wood door or floor materials): t01 119 (78 turned off
  the axes), t02 71 (51 turned), t01a 49 (24), t04 131 (mine boards); woodfloor005a most, then wooddoor004a,
  015a, 032a; func_detail 176 of 239 in t01, t01a and t02. Physics boards: 22 (all held still, 14 free on grab,
  73% touching a wall). Confirms valve-boarded-openings with three more maps.
- Pipes: pipe02_straight01_long 147 (t02 56, t02a 41, style room 50) chained every 48 with connectors, 64% within
  16 of a wall, 122 lying along it, skin 2 (rust) on 98.
- Gutters (44): on walls (89% touching), skins 0 and 1 mixed; chimneys 8 in t01; utilitypole01b 16, 485 to 906
  apart (median 726), turned 45 on half.

## 10. Ground, displacements, texture

- Outdoor ground near nodes: t01 dirt blend 36%, cobbles stonefloor006a/b/c 31%, planks 8%, red_grass 6%; t01a
  cobbles 57%, planks 18%; t02 cobbles 23%, grass and gravel 15%, flat roofs 13%; t02a 91% displacement (dirt and
  grass blends); t05 gravel 53%, red_grass 20%.
- Yard and hill displacements (t02 38, t02a 47 on floors): power 3 on 53 of 85 (power 4 on 10), odd sizes fitted
  to the plot (224x128, 352x304, 288x144, 576x512), texture scale 0.25, lightmapscale 16 near play, alpha painted
  on 38 of 85, offsets median 32 to 70 (q75 107 to 140 on the hill). Muddy patches: dirtfloor005b (t01 3, t02 8).
- Texture scale 0.25 on 94% (t01), 96% (t01a), 90% (t02) of area; 0.5 on cliffs (t02a 13%).
- Style room: 546 floor displacements of snow blends, power 2, 85% painted, offsets median 13, and 56 strips
  128x32 along wall feet (snow drifts).

## 11. Cross-sections: Valve's lanes against ours

- Kerbs: Valve 4 of 320 cross-sections in t01, 0 of 50 in t01a; 21 of 275 in t02 (the square: kerbs 4 to 15).
  Ours: the quarter's main street keeps the owner's crown, kerb 8 and pavements 96 (asked for); its alleys and
  yards have none, as Valve's lanes.
- Width: Valve wall to wall median 620 (t01), 376 (t01a), 589 (t02), 625 (t02a), 622 (t03); the commonest narrow
  lane 192 (t01: 34 sections), gaps between houses 128 (10). Ours: alleys 128 wide (south row, north off the square,
  the north yard 128 deep), the south street 192: our alleys are at Valve's narrowest gap, not its lanes.
- Walls: Valve median 352 (t01), 448 in t01a's narrow lanes (height over width 0.9), 288 (t02), topped by pitched
  roofs at 25 degrees with 16 eaves. Ours: walls up to the sky lid at z 1408 (about 750 over the road) with the
  owner's facade bands and no pitched roofs.
- Floor: Valve's lanes dirt and cobbles, a third of t02's yards displaced. Ours: a dirt material on flat brushes
  for the alleys.
- Inside: Valve's ceilings 120 to 128 (t01 q25 128, t02 120). Ours: rooms 144 high, the tenement 296 for two floors.

## Check ideas

1. Blood decal more than 192 from any prop_ragdoll in an infestation module (Valve: none alone in t01a).
2. Share of prop_physics among dressing props in an infestation module (Valve's trap streets 0.4 to 0.5).
3. propane_tank001a standing upright in rows (Valve lays 28 of 31 down).
4. An explosive drum with another within 32 (Valve: nearest median 128).
5. A sloped roof brush thicker than 16, or with no eave past its wall.
6. Cave displacements at power 3 or 4, or lightmapscale over 16 near nodes.
7. 4 or more gravestones in a line at one yaw away from a wall.
8. A lit clamp lamp (light_spotlight02_lamp) without a light_spot within 16.
9. Planks of a boarded opening all square (Valve turns two in three).
10. Trap fire: env_fire nodes of one name more than 40 apart, or lit at the start.

## What did not work

- Floor-under lookups skip displacements, so crow heights over the graveyard's grass read 400 to 575 until checked
  against nodes (they stand on the ground).
- Mine frames by "posts under a beam" found only 2: the posts reach into the floor displacements; the sets were read
  from the brush list instead.
- Window sills, house footprints and storey counts were not measured (no clean way from plane brushes).
- styleguide_ravenholm_01 is an industrial snow yard, not the town: used only where its numbers agree.
