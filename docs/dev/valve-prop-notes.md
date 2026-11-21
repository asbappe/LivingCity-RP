# How Valve places props (measured from 8,951 props in 22 of Valve's map sources, 21 November; reference)

# Valve props, second pass (21 November)

Sources: 22 maps (d1_trainstation_01 to 05, d3_c17_13, d1_town_03, d3_citadel_01, d2_coast_12, d1_canals_01, 01a, 02, 03, 05 to 13); sdk_vehicles left out. 8,951 props in play areas (3D skybox rooms and skybox-only models removed, objects inside Hammer `hidden` blocks left out: about 3% of props). Model boxes and prop_data from the Valve QCs (all but 2 of 927 models). Scripts: `scratchpad/p2/` (parse.py, dparse.py for displacement heights, lib.py, a_*.py, s_*.py).

Kinds come from model names (lib.py); "dressing" = furniture, clutter, lamps, corpses.

## 1. Classes

| class | n | yaw on exact 90s | turned 1-20 | free |
|---|---|---|---|---|
| prop_static | 6154 | 69% | 15% | 11% |
| prop_physics | 2193 | 41% | 34% | 21% |
| prop_dynamic | 421 | 89% | 6% | 3% |

Also: prop_ragdoll 66 (mattresses 17, crushed cars 3, the dead 46), prop_door_rotating 50, prop_physics_override 9, prop_dynamic_override 3, prop_physics_multiplayer 0.

Physics by kind: barrels 451, crates 288, boards 227, trash 130, boxes 111, tyres 82, pallets 76, cans 74, shelves 74, chairs 47, cinderblocks 43, tables 39, buckets 34, bins 33, radiators 24.
Static even though it has prop_data (allowstatic): handrail04_long 121, cargo_container01 93, beam01c/d 31, coolingtank02 19, trashdumpster02 16, furniturestove001a 6, Combine monitors and interfaces.

prop_physics spawnflags bits: 1 asleep 571 (26%), 2 no phys damage 147, 4 debris 219 (10%), 8 motion disabled 637 (29%), 64 free on grab 76, 128 rotor wash 254, 256 use output 694 (default).
Motion disabled: boards 207, dock planks 61, barrels 55, crates 37, radiators 24 (of 25), shelves 21, tables 12, couches 11, signs 16. Debris: trash 99, boards 38, cans 36, boxes 12, buckets 11.

prop_dynamic, why: parented 45% (trains, lifts, pods), named only 35% (10% also StartDisabled), unnamed 20% (train seats and racks, canal locks, pods). DefaultAnim on 15 (bunker_gun01 idle_inactive). Turning things are func_rotating (tram wheels, windmill, teleport rings).

Physics per map: median about 105 (22 to 199; citadel 2). Our scratch town: 42 physics, 231 prop_dynamic_override.

## 2. Placement

Yaw by kind (share on exact 90s): radiator 100, phone 100, bench 89, fence 88, ladder 87, pipe 84, door 84, light 73, debris 72, combine 71, lamppost 71, can 70, barrel 57, shelf 55, box 54, table 50, board 46, container 44, mattress 36, cinder 37, personal 35, chair 32, plant 31, bin 29, pallet 29, trash 27, crate 19, couch 15, cart 14.

Tilt (pitch or roll): physics 43% (lying 75-105: 23%, upside down: 6%, lean under 15: 7%); static dressing 16%.
Lying by kind (physics): trash 53, cinder 53 (+16 upside down), personal 47, pallet 39 (+13 upside down), barrel 28, bottle 23, bucket 21, can 16, chair 11, crate 6, box 6, table 5. Nailed boards: 145 vertical (pitch 90), 39 flat. Pallets: 49 of 76 on edge or leaning (16 against a wall), 19 flat.
Ground: on a brush floor 41% (statics) / 52% (physics); on displacement 27% / 24%; on another prop 4% / 14%. Dressing on displacement tilted 54% (small tilt 15 or less: 14%), on flat floors 26% (3%).

Wall gap (prop box to nearest axis brush at its height):

| | touch | <=4 | 4-16 | 16-32 | 32-64 | 64-128 | >128 |
|---|---|---|---|---|---|---|---|
| static | 45% | 4% | 4% | 3% | 5% | 8% | 31% |
| physics | 16% | 8% | 14% | 11% | 12% | 14% | 25% |
| physics, city maps | 12% | 16% | 23% | 14% | 10% | 15% | 11% |

Within 16 of a wall: pot 100, phone 88, shelf 76, radiator 76, door 76, barricade 73, ladder 64, table 62, box 60, tv 60, trash 51, corpse 48, pallet 47, crate 38, barrel 32, board 30, chair 22, cinder 21, can 12. Shelves by a wall face out (back to it) 46 of 70.

Skins: 9% of props not skin 0. oildrum001 45%, cargo_container01 69%, wood_crate001a 33%, plasticcrate01a 60%, door01_left 91% (skin 7 commonest), lights_florescent01a 88% skin 1, light_spotlight01_base 94% skin 1, poplar trees 100% skin 1. rendercolor: only 4 dark prop_dynamic. modelscale: never.

Fades (min/max, medians): tiny statics 2000 (17% set), medium 2000/2600 (41%), large 2500/3000 (35%), huge 4000/5000 (33%); physics tiny 1024/1500 (26%), small 2000/2500 (30%), medium 1900/2500 (42%); dynamics 8%. By kind: trash 1024/1500, chair 1000/1200, corpse 1000/1500, board and cinder 1200/1600, debris 1800/2000, crate 1900/2500, barrel 2000/3000, fence 2750/3200, dock 4000/5000.
disableshadows 1: lamps 52%, machines 49%, ladders 55%, fences 45%, boards 45%, trash 43%, dynamics 67%, statics 26%.
solid 0 statics 22%: shrub_01a 190, ivy_01 110, fence03a 72, cattails 62, garbage256 piles 98, canal_cap001 49, powertower01 41, lamppost03a_off 25 of 38, utilitypole02b 21.

Stacks: crate on crate 49 (17% of crates), top turned median 7 (q75 30), shifted median 8 (q75 20). Tyres: 82, all physics, 76% flat, columns 1:28, 2:7, 3:7, 4:2, 5:1, 6:1. On shelves: TVs 9, trash 5, papers 3, boxes 2. Pots on the stove 7-12 up.

## 3. Clusters (single link at 96, 3,307 dressing props, 540 clusters, sizes 2 median, 7 at 90th pct)

Same kind within 96: board 87%, can 76%, shelf 75%, box 67%, crate 66%, barrel 65%, machine 60%, barricade 55%, trash 46%, personal 45%, pallet 38%, chair 38%.

| # | group | clusters (maps) | typical layout |
|---|---|---|---|
| 1 | 2-3 barrels | 72 pairs, 19 threes, 18 of 4-5 | 31-58 apart (median 39), 41% have one lying, 51% mix skins, 12% mix in an explosive one, 24% all explosive |
| 2 | 2-4 crates | 36 pairs, 24 threes, 8 fours | touching (nearest 7-62, median 31), 17% stacked, 6% of groups all square |
| 3 | barrel + crate | 24 (10) | within 96, both turned |
| 4 | crate + trash | 16 (9) | within 96 |
| 5 | crate + pallet | 14 (11) | pallets on edge nearby (median 45), crates rarely on them (7) |
| 6 | chair + table | 14 (10) | chair 33-58 from table, faces it within 45 (18 of 20), 1-3 chairs |
| 7 | bench + trash | 14 (2) | trash 70 from the bench, under or beside |
| 8 | bin (dumpster) + trash | 13 (5) | 22% of dumpsters have bags within 128; 21 of 37 dumpsters physics |
| 9 | box + shelf / tv + shelf | 13 (6), 8 (4) | boxes and TVs on or beside shelves |
| 10 | corpse + crate | 11 (9) | the dead behind cover, median 80 |
| 11 | barrel + pallet | 11 (8) | |
| 12 | push cart + suitcases + box | 8 (2) | 2-6 suitcases within 30 of the cart, one or more on its side |
| 13 | radiator + shelf/couch/chair | 9 (3) | flats: radiator on a wall, the furniture along the walls |
| 14 | wall box + light (elecbox+light) | 13 (10) | a lamp beside the switch box on the wall |
| 15 | stacked tyres | 7 columns of 3+ | flat, freely turned |

Benches: rows of 2-6, 96-112 apart, 83% same yaw, 89% square, 62% against a wall; trash 45% within 70, payphone 20%, bin 18%. Lampposts: 34 of 38 have no dressing prop within 192 (along canal walls and streets, alone). Drum fires: only 3 env_fire inside a drum (d1_canals_12 -5712 4192 291), firesize 48, spawnflags 19.

## 4. Density (floor rasterised at 32, near AI nodes; 18 maps)

Whole maps: one prop per 24,000 (ts01) to 205,000 (c13) square units of floor. 256 x 256 squares:

| place | squares | empty | busiest 10% hold | occupied: median / 90th |
|---|---|---|---|---|
| city indoor | 310 | 47% | 46% | 2 / 10 |
| city outdoor | 730 | 74% | 64% | 2 / 5 |
| canal indoor | 536 | 65% | 55% | 2 / 6 |
| canal outdoor | 1454 | 79% | 69% | 1 / 4 |
| Ravenholm indoor | 13 | 54% | 47% | 5 / 17 |

Physics per 512 square with props: city indoor median 1, q90 12, max 25; city outdoor 0, 4, 13; canal indoor 2, 9, 20; canal outdoor 1, 5, 18.
Within 192 of key furniture: kitchen 10 props (9 physics), washroom 14 (7), living 12 (7), hideout 8 (5), office 8 (5), workshop 7 (4), Combine room 2 (0).
Busiest: ts04 -7680 -4352 (21 props), c03 -2304 -768 (19), ts03 -4352 -5120 (14).
Doorways: of 69 doors, 1 floor item within 48 of the middle (the rest are lamps and switch boxes on the wall).

## 5. Story props (map, x y z)

1. Bunk room: 3 mattresses (ragdolls), radio on a plastic crate, pallet, chair, batteries, graffiti, trash decal. c01a 2400 6240 -155.
2. Camp: mattress, two pots, boards, pallet, box, rug overlay, bills decal, supply crates, lamp with sprite. c03 -819 2807 -728.
3. Shanty: mattress by a fireplace, cinderblocks, chairs (one on its back), corpses with an SMG 38 away, blood decals, shanty song. c05 4524 908 -440.
4. Radio left on: dead woman beside a citizen radio playing coast.radio_dead, blood decals, at the gate wheel. c05 7161 1635 -387.
5. Relay post: mattress, corpse, radio (radio_dead, radio_comein12), canal map, blood stain. c06 4000 5812 -151.
6. Waystation: mattress, metal pot, four tins, box, healthkits, grenades, graffiti. c10 11152 39 -375.
7. Dead with his weapon: corpse, weapon_357 68 away, two ammo boxes, blood stains. c12 687 6445 425; charred rebel with SMG 21 away, scorch and blood. c03 -801 -328 -905.
8. Raided flat: fridge on its back with both doors off, drawer tipped, boards, cinderblocks, mattress on the floor, burn overlay. ts03 -4254 -4712 274; upper flat: bathtub tilted 32, couches tipped 70 and 162, dresser 86. ts03 -4320 -4634 440.
9. Beaten citizen: ragdoll by a couch, chair on its side 50 from the table, sound citizen_beating. ts03 -4463 -4107 307.
10. Travellers: push carts with 2-6 suitcases, a briefcase, boxes, by the benches. ts01 -3958 -1711 2 and -4169 -2967 12.
11. Burnt yard: six charred corpses, scorch decals, drums, tyres. c02 -504 -368 -754.
12. Burned headcrabs: four headcrab ragdolls, six env_fire, scorch decal, by a shelf of tins. c13 11116 1136 -256.

## 6. Small details

Ropes (781): cable/cable 98%; width 1 (43%), 2 (25%), 3 (26%); Subdiv 2 (67%), 5 (32%). Spans: under 128 slack 50 width 1 (90); 128-1024 slack 100 (229); over 1024 slack 120 width 3 (283, power towers). Ends: pole-pole 276 (powertower01 120, utilitypole01b 94), box-box 24, box-pole 18, swingset 8, pulley 5; 39 ropes parented.
Decals and overlays near props (within 48): trash 57% (trashdecal01a/02a), benches 45% (decalstain014a, debris_concrete001a), shelves 43%, bins 42%, chairs 40% (decalstain002a, bloodstain_001), personal 37%, boxes 25%, corpses 25% (blood1/5, scorch1, bloodstain), barrels 11%, crates 11%. Doors: decalsigndanger001e; wall boxes: decalsigndanger001c.
Sprites (254): light_glow03 162 (scale .75, rendermode 9, renderamt 255), glow01 37, blueflare1 22; at the bulb of the lamp model (distance 0). Lit lamp models: 114 of 149 with a sprite, 147 with a light within reach. Light entities by lamps: light_spot 475, point_spotlight 202, light 111.
Sounds at props: sinkdrips at sinks (6-10), coast.radio_dead at radios (24-28), diesel_generator, k_lab.printer, k_lab.tech1 at servers, fire loops at debris (radius 200-750), cryingloop by a couch (ts03). ambient_generic spawnflags 48 (triggered one-shots) 129, 49: 37, 16: 23.
Animated props: almost none for ambience (bunker guns idle); func_rotating for tram wheels (9), teleport rings, windmill.

## 7. Room recipes (props within 192 of the key furniture; share of rooms, median distance, against a wall)

- Kitchen (ts03 -4658 -4691 276): stove square on a wall; 2 metal pots on it (physics, 13-21 off its middle, 7-12 up); cupboard and cabinet drawer beside it (34-61); kitchen sink 115 away on a wall with shelves above or beside (38-47) and bottles, cans, milk carton, takeout carton loose around it (25-60); trash bin and plastic crate on the floor; lightbulb overhead (64); power outlet and stain decals; sinkdrips. About 10 props, 9 physics.
- Washroom (ts03 -3900 -4700 302): toilet against a wall, sink 58 from it, bathtub 97 away on a wall, radiator, shelves (001b/002a) on the wall 92 away (all within 16), lightbulb overhead 31 from the toilet; stain decal; sinkdrips. 14 props.
- Flat living room (ts03): couch on a wall (100%), radiator (48% of rooms, all on a wall), chairs free (11% on a wall), table, dresser or drawers on a wall, shelves 109 away, TV on a shelf or drawer, dome light or bulb overhead, picture frame on a wall; mattress on the floor in 29%. 12 props, 7 physics.
- Office (ts01 -3744 -480, c08, c10): controlroom_desk001b against a wall (86%), file cabinets in a row on a wall (79%, 67 from the desk), binders close by (28), office chair free, clock on the wall, bucket, crates; Combine interfaces in a row of three in station offices. 8 props, 5 physics.
- Hideout/bunk (canals): mattress on the floor (43% on a wall), pallet 90 away, plastic crate, radio on a crate, chair, couch on a wall, cinderblocks, tins (51), prison shelf (45); rug overlay, graffiti; batteries, healthkits. 8 props, 5 physics.
- Workshop (c11 6016 4992, ts05 lab): parts bin with a receiver on it, magnifying lamp, crates and plastic crates on the walls (80-100%), push cart, canal map, power boxes high on the wall, caged lights; lab: workspace001-003 benches on the walls, pipe systems, fluorescent lights. 7 props, 4 physics.
- Combine room (c07, c13, ts01): interface 001/002/003 side by side, monitor 78 off and 53 up, wires, combine_light002a; almost no loose props (median 0 physics). 2 props.

Pictures: `scratchpad/p2/pics/v2_kitchen_bath.png` (ts03 flats from the south-west, cut at 370: kitchen left, raided room middle, washroom right; furniture on the walls, floors clear). Other renders dropped: an iso view at this scale shows walls, not clutter.

## 8. Check ideas for our tools

1. Grid share: warn when more than 60% of a module's prop_physics are on exact 90s (Valve 41%).
2. No tilt: note a module with 10+ loose props and none tilted (Valve 43%).
3. Flags: list prop_physics with spawnflags 0; small junk without the debris flag.
4. Fades: count loose props under 64 tall with no fademaxdist in outdoor modules.
5. Skins: note 4+ of one multi-skin model all on skin 0.
6. Density: props per 256 square and physics per 512 square, warn over 12 / 25 indoors; flag an indoor room with no prop at all; flag a prop within 48 of a doorway's middle.
7. Walls: note shelves, couches, desks, radiators, sinks, bathtubs more than 16 from any wall.
8. Stacks: note stacked props with exactly the same place and yaw.
9. Ropes: warn slack under 25 on spans over 128 (Valve 100).
10. Lamps: a lit model (_on, skin 1 tube) without a sprite and a light within 64.
11. Decals: loose trash groups with no trash decal within 48.
12. Isolation: note a module whose loose props are all more than 96 from each other (Valve groups them).

## What did not work

- Room segmentation by ceiling height merged whole flats (door headers are not lower than ceilings in ts03): recipes use a 192 radius around key furniture instead.
- Floor raster misses props in water and on non-axis brushes: 40 to 60% of canal props land on a floor cell; densities are lower bounds for canals.
- Model-name kinds are rough (payphone_reciever counted as a workshop anchor; kitchen_shelf001a is a canal-station shelf, so the "kitchen" numbers mix both).
- Hidden-block objects were left out (not checked whether vbsp compiles them).
