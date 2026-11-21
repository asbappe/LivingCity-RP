# Episode One's City 17: props, building craft and cross-sections (work in progress, 21 November)

Maps: ep1_c17_00, 00a (the dark underground: a road tunnel, car parks, service ways), 01, 01a, 02, 02b (the city after
the Citadel's blast, the evacuation), 02a (the hospital), 03 (a small test map of loose junk), 05, 06 (the station,
the train yard, the last train); style rooms: styleguide_hospital_exit, garage, garage_destroyed,
garage_antlionroom, train_loadingdock, train_repair, antlion_tunnel, antlionhole. Numbers from `measure.json` and
from our own reads of the VMFs (rays against brushes, props within a radius of a key piece). Only what is new, or
firmer, beside the City 17, Ravenholm and Nova Prospekt notes.

## 1. The hospital (ep1_c17_02a, 162 hospital props, 534 nodes inside)

- **Corridors**: narrow side 160 to 256 (commonest 224, then 256, 192), ceilings 128 (134 nodes) or 192 (201), a
  few 112 to 120. The lobby corridor is 224 wide and 192 high; ward corridors 240 by 128.
- **Wall rail**: hospital_railing_64/160/32/256_01 (113 in all), every one static, on the wall (gap 0), square,
  origin 34 to 36 over the floor (the rail's top about 37). Runs of 64 and 160 pieces with 32s to fill.
- **The ward**: a single room 232 by 304 under 128 (6 of 13 beds), with its own washroom 152 by 112 under 120.
  The bed (hospital_bed01, 87 by 42) is a physics prop (flags 256: free), never on a wall: 32 to 56 from it
  (median 40), turned 3 to 20 on 7 of 13. Round it: an IV stand 42 to 51 away, a cart 52 to 58, a bedside
  cabinet (hospital_shelf01, 16 from the wall) with a monitor on it (consolebox03a at 36 up), a radiator on the wall
  (21 up), and a fluorescent tube on the wall over the bed's head at 64 up, pitched 75 (a reading light), with a
  light_spot 220 235 245 600, cone 40, pitch -35, and a faint point 20 beside it.
- **The washroom** (9 alike, one to a ward): bathtub01a 16 from the wall, furnituresink001a 8 to 16 off it at
  23 up, toilet 16 off, a radiator, a wall rail by the tub, a sconce in two.
- **Theatres**: hospital_surgerytable01 static, square on 7 of 8, 48 to 120 from every wall; one room has three
  tables in a row 92 apart. Over each, one to three hospital_surgerylight01: physics held still (flags 266: no
  damage, motion off), 100 over the floor, 24 to 32 under the ceiling, rolled 45 and each turned its own way
  (yaw 0 with 120, 225 with 0...). Round them: monitors, a kitchen sink pair (the scrub sinks), IV stand, cart,
  shelf; rooms 288 to 451 wide under 124 to 192.
- **Waiting**: bench01a physics (16), 24 off the corridor wall, turned 3 to 20 on 7; a picture (frame002a, physics)
  at 72 to 92 on the wall over each bench, a clock, a TV monitor; vending machines and payphones in pairs in a
  corner (payphones 8 off the wall, 36 up).
- **Evacuated**: four beds stand in corridors 176 to 253 wide, turned 105 to 195: left where they were wheeled.
- **Dark and the power**: 91 lights in the hospital (35 light, 35 spot, 19 sprites); 10 named power_light_N start
  off (spawnflags 1) and come on when the power is restored: warm cage lamps (254 216 146 75, cone 70, pitch -70)
  each with a glow sprite 10 under it. Two road flares (physics) on the floor beside an orange light 254 174 10
  at 100 to 200, 12 over the floor: the flare's glow baked in. An exit sign is a green sprite (37 186 60).
  Blue sparking lights (41 166 226 100 to 120) named electric_flickerlight. Node to nearest light: median 211.

## 2. The underground (ep1_c17_00, 00a; style rooms garage, garage_destroyed, garage_antlionroom, antlionhole)

- **A road tunnel under the city** (00, ep1.zombiedark, about 6000 long): 608 wall to wall, 196 clear, tiled walls
  (tilewall006c) over a concrete ceiling; two carriageways of 240 and 272 either side of a central strip 96 wide
  raised 4 (concretefloor028c), lanes in concretefloor033k/q with a 48 edge strip (033p). Broken pillar clusters
  (pillarcluster_001b) on the centre line about 875 apart. Sprinklers in two rows 384 apart, every 512, 20 under
  the ceiling. 15 vehicles over the length: only one square, trucks jackknifed 15 to 35 across the lanes, 7 tilted
  (on a side, roll 84 to 90; burnt hatchbacks at pitch -15 roll 26), skins 1 or 2 on 8. 20 corpses.
- **The car park** (style room garage, the same in 00 and 00a): a deck 2288 by 1072, ceiling 112 clear (beams to
  96), the whole deck sloping 4.8 degrees (1 in 12); columns 32 by 32 every 256 along, in three rows (the drive
  aisle 384 between two of them); two cars to a column bay (128 a car: the cars are 76 to 87 wide, 152 to 203
  long), bays 176 to 192 deep; cars 2 in 3 nose to the wall (yaw 90 or 270 to 2), 3 of 13 free. Ramps between
  decks 9.2 degrees (1 in 6), 224 to 240 wide. Ground markings are overlays: bay lines 32 by 128
  (garagegroundmarking01h) in pairs, arrows (01f), letters (01a, 01b), 8 wide edge lines (01i); wall markings
  (garagewallmarking02*) on the columns. Kit: fluorescent tubes, prison sprinklers (13 a deck), handrails on the
  ramps' edges, pipe sets along the ceiling, power boxes, cones, bins, a dumpster, bicycles.
- **Ceilings** where the nodes are: garage 112 (00) and 120 (00a); service ways 128; the road tunnel 192 to 196.
- **The car park after the blast** (00a, garage_antlionroom): the upper deck broken into func_detail slabs 96 to
  300 across and 27 to 56 thick, tilted 5 to 60 degrees, floor material on top (concretefloor033o) and the ceiling's
  on the underside; wrecked cars lie on them tilted with the slab (pitch -8 to -15, roll 136: on their sides and
  roofs) and one car rests on another (76 over it). Antlions come up through concrete_spawnhole001a (a 128 round
  hole model laid on the floor, 3 in the antlionhole room, 2 in 00, 3 in 00a).
