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
- **Service tunnels** (00a, ep1_c17_00_tunnel_wet): heights 128 and 256, concretefloor006a, walls concretewall002c
  and 037c. The pipe rack is three runs of pipe03 (96 long, 17 across) at 80, 104 and 120 over the floor, 20 to 44
  off the wall, with thinner pipe02 and pipe01 (48 long) at 184 to 208 under the ceiling. Every run is straights
  with one connector at each joint (112 straights, 112 connectors; connector 48 to 49 from the straight's middle),
  all static, skin 1 on 88 of 112, laid with pitch 90 (the model's flat back to the wall).
- **The antlion-dug way** (styleguide_antlion_tunnel): a service tunnel 352 wide and 176 high (mine concrete,
  pipe sets along one wall at 245 to 298 up, cage lamps 248 apart, chain-link panels as a gate) broken open
  into a cave of 119 displacements (power 3 on 74, 4 on 24, 2 on 21; pieces 128 to 512 across, rockwall015a with
  blends), 120 to 680 high. At the break: 11 concrete_spawnchunk physics pieces within 80 of each other, five
  rebar pieces sticking out of the broken edge at pitch 60 to 90, a pallet and three drums. Grub clusters (3 to 7)
  each carry a faint green light (154 168 122 80) 12 over them; the cave is lit by one cool blue light
  (109 192 207 1500) and a dim one (65 100 109 200).

## 3. The train yard, the loading dock and the repair shed (05, 06, styleguide_train_loadingdock, _repair)

- **Loading dock** (style room): a brick shed 1824 wall to wall (brickwall037a, building_trainstation_template001c,
  truss roof metaltruss022a): a dock 256 wide on one side and a loading floor 800 wide on the other, both 96 over
  a gravel track bed 736 wide holding three sidings (car centres 224 apart). Under the roof 608 over the docks, 704
  over the bed. Steps down from dock to bed: metal stairs 8 rise in 128. Kit: cargo_container01 (17, 132 by 388),
  lockers (12 + 8), wood crates, drums, pallets, forklifts, pulley hooks, cafeteria benches; flatcars (train005,
  460 long) and boxcars (train003, 560) as prop_dynamic on the sidings.
- **Bell lamps**: light_industrialbell01_on hang right under the roof, 480 to 704 over the floor, in rows 192 to 224
  apart (loading dock 48, repair shed 25, 05 37, 06 25), all static; each with a light_spot 221 249 241 3000, cone
  50/20, straight down. This is how Valve lights a tall shed: many lamps high up in a tight grid, not a few floods.
- **Repair shed** (style room, also in 05): 1296 wide, a pitched roof (rising 1 in 4 to the ridge over the track),
  the train on the middle at floor level with a sunk walk 64 deep and 120 wide either side of it (for the bogies), and
  galleries 256 up along both walls (grates 48 to 64 wide) at the height of the car roofs.
- **Track** is a texture (metaltrack001a) on a strip 128 wide laid on the gravel bed (gravelfloor002a/b), not rail
  brushes or props.
- **The evacuation** leaves little behind: across ten maps only 5 suitcases and 5 briefcases, a few garbage bags and
  pop cans (19 in the hospital's waiting room, 17 in 01a); the evacuation is told by people (citizens, soldiers)
  and by the trains, not by piles of luggage.

## 4. Props across the episode (4,817 props in ten maps, pooled from measure.json)

| | grid yaw | turned 3-20 | free | tilted |
|---|---|---|---|---|
| prop_static (3178) | 76% | 8% | 8% | 37% |
| prop_physics (1448) | 31% | 26% | 32% | 56% |
| prop_dynamic (191) | 87% | 7% | 5% | 28% |

- Loose things are less square here than anywhere yet (physics on 90s: 31%; the uprising 53%, the 22-map pass 41%)
  and more tilted (56%; 28%, 43%).
- **Debris flag** (4) on 424 of 1448 physics props (29%; the uprising 4%, the 22-map pass 10%): trash 305, cans 39,
  boards 22. Motion off (8) on 18% (fences 61, shelves 47, boards 34, debris 31, radiators 17); asleep 5%; freed on
  grab 6%. Lying: trash 201, boards 53, cinder blocks 41, fences 35, cans 33.
- **Abandoned vehicles** (105 in ten maps and the hospital exit room): square 18%, tilted 40% (8 on a side, 8 on
  the roof), static 70%, skin not 0 on 46%. **They come in jams**: 74% have another vehicle within 400, 38 have three
  or more. The hospital exit room's jam: 11 trucks, vans and cars in 1200 by 750, yaws 60 to 270, one tilted -10.
  Trucks stand jackknifed 15 to 35 across a road.
- **Fires** are few and small here: 5 to 12 a map (the uprising 137 in 15), firesize 32 (8 to 15 lit at 100 to
  200) or 64 (100 to 200), 80 to 128 with 300 to 400, one of 256 with 2000. 49 of 52 have a steady orange light
  (254 174 10, or 250 159 69) 8 to 24 over them (16 commonest). Within 64 of a fire: rubble piles and burnt
  hatchbacks.
- **Explosive drums** (02: 26) stand upright, never tilted, in clusters 32 to 48 apart.

## 5. A Resistance hideout (02b, the flats round 1200 2000; Barney and five citizens)

- **Doors**: door03_slotted_left (a prop_door_rotating) with door03_slot (a prop_dynamic at the same origin): the
  door with a sliding peephole, at the street door and the hideout's own door.
- **Barricades**: barricade_tall01a/02a static, pitched 30 (leaned back), 39 to 46 off the window wall, 52 up: they
  lean against the windows from inside; a short one across a doorway; boards (wood_board06a, physics, held still and
  freed on grab, flags 328) rolled 105 across windows 41 to 61 out.
- **Radio corner**: citizenradio (prop_dynamic_override) and harddrive02 on a shelf 12 off the wall, a reciever_cart
  beside: the Resistance's radio set.
- **Living**: couch (held still), five chairs, a TV, fridge, kitchen sink, stove, pot, cupboards, a cabinet, a
  radiator, a bed frame tipped (pitch -7, roll 17) 92 off the wall; warm dome lights (light_domelight02_on) and bare
  bulbs, two plaster piles on the floor, a destroyedceiling piece.
- **A hoist**: pulley wheels on the wall (a crank, prop_dynamic and a physics twin) with two crowbars wedged in it
  (prop_dynamic, pitch -71), the way up to the hideout.
- Ours: our stash and the town's hideouts have the city's doors, not the slotted door; a hideout lesson would add
  the slotted door, the leaned barricades and the radio corner (props only: ask the owner before a door changes).

## 6. Combine architecture

- **Under the Citadel** (00, the Combine's hall at the tunnel's end, y about -6900 to -5600): Combine metal is 28% of
  the map's visible area (citadel_metalwall063a 37%, 077a 32%, 076a 24%, 072b 5%); texture scale 0.25 on 94% (not
  Nova Prospekt's 0.5); 826 brushes, the thinnest side 8 (159) or 4 (158), then 24, 2, 3: plates. In plan 94% of
  wall area stands on the axes. 77% stands upright; the rest leans: panels 128 high at 14 degrees (1 in 4, as Nova
  Prospekt's), 208 high at 4, 112 high at 8, 176 high at 57, 32 high at 13; faces looking down (heads over the
  room) 46% of the leaning area, looking up (bases out) 54%. The floor is ribbed: plate 063a with ribs 32 wide every
  128, alternately 20 and 3 high; the ceiling about 336 over it.
- **The Combine's wall in the street** (01): metalcombine001 brushes 48 thick and 160 to 256 high, end caps 48 to 64,
  in straight runs 208, 375, 433, 496, 574, 858 and 984 long, each turned 3 to 17 degrees from the last (yaws 357,
  357, 13, 30, 77, 94, 105), never on the grid for long; outer faces lean back 4 degrees (all look up), inner faces
  upright. Texture scale 1.0 on half its area.
- **The yard's great walls** (06, far side): 768 high, 96 thick, runs 690 to 1093 long turned 10, 21 and 34 degrees
  off the grid; on each slab one face leans back 4.4 to 4.7 degrees and the other is plumb (about 60 wider at the
  foot than the head): lop-sided in section.
- **Force fields**: comshieldwall3 on func_brush pieces 70 wide and 340 high in a row across the yard (06), 1 apart
  as two faces; in 01a and 02b comshieldwall2.
- **The creeping walls** (01, 01a: combineinnerwall001a 10 and 13; the hospital exit room:
  combineinnerwallcluster1024 at yaws 105, 120, 135, 225) are props high in the skyline, turned in 15 degree steps
  as in the uprising.
- Combine rooms in old buildings (02 control room): combine_light002a (three a room), combine_intmonitor001,
  combine_interface001, combine_emitter01 pairs, combine_barricade_bracket02a on the door, combine_wire002 along the
  wall, combine_lock01 by each door, set into an ordinary office (controlroom_desk001b, desk lamp, binder, chair,
  radiator).
