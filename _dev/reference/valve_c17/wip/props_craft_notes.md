# City 17's uprising: props and building craft (work in progress, 21 November)

Sources: d3_c17_01 to 12b (15 maps; d3_c17_13 was done before), styleguide_c17_rubble and _2, and Valve's
standards rooms (testroom_standards, zoo_standards, testroom_measure_movement). Read with the repo's reader
(`_dev/tools/ingest/vmf.py`), 3D skybox rooms and Hammer-hidden objects left out. Scripts and a pickle cache of
every map: `<scratchpad>/c17pc/` (cache.py, lib.py, a_*.py). Short names: c01 = d3_c17_01 ... c12b.

## 1. Valve's standards rooms (testroom_standards, zoo_standards)

Built in dev_measure* textures, so each brush is a size Valve set as its rule. The zoo is the same room with
crates, barrels, chargers, a toilet stall and two Alyx figures for scale.

| What | Valve's standard |
|---|---|
| Rooms | walls 8 thick, 128 a storey (rooms 128 or 256 tall) |
| Hall (dev_measurehall01) | 64 wide, 128 tall (the narrowest hall) |
| Doorway (dev_measuredoor01) | 48 by 108 in an 8 wall; a frame 4 wide each side and 4 over (rough hole 56 by 112); door brush 2 thick; knob 43 up |
| Stairs (dev_measurestairs01a) | 8 rise, 12 tread, 64 wide; 8 steps a flight of 64 |
| Stairwell | 128 wide, two 60-wide flights of open treads (2 thick, 8 by 12) with landings 80 and 92 deep: one storey of 128 in a shaft 128 by 256 |
| Steep stair | 46 wide, slats 8 up and 4 on, 128 high in 64 run, stringers 1 thick |
| Stair rail (dev_measurerails02) | 2 thick, 64 tall along the pitch; landing rail (rails01) 2 thick, 32 tall; handrail04_singlerise props on both sides of the flight, 62 apart |
| Ladder (dev_measureladder01) | 24 wide, 256 tall brush, func_ladder; dismount points 36 to each side at the top and 36 out at the foot |
| Counter (dev_measurecounter) | 40 tall, 32 deep, 64 long; items on it at 41 to 42 |
| Desk | top 30 up (2 thick), 64 by 32; monitor 24 wide, 20 tall |
| Chair | seat 16 to 18 up, 24 by 22, back to 42 |
| Switches | 8 by 12 plates 40 to 52 up |
| Wall chargers | 16 by 4 by 32, 40 to 72 up, 24 apart |
| Lights | fluorescent panels 32 by 16 hung at 168 under a 256 ceiling on 84 wires |
| Crates (zoo) | 32, 40, 64 cubes, 48 tall by 64 to 67, 75 and 88 wide by 64 (wood_crate001a is 40) |
| Barrels (zoo) | 32 across, 48 tall (oildrum001 29 by 45) |
| Columns | 30 across, 12-sided |
| Nodes | 49 info_node, nearest neighbour median 70 (p10 40, p90 166) |

testroom_measure_movement is only a logic_measure_movement demo (a barrel following a target): no sizes.

## 2. Props across the uprising (4,181 props in 15 maps)

prop_static 3151, prop_physics 714, prop_dynamic 183, prop_ragdoll 51, prop_door_rotating 38,
prop_physics_override 34, prop_dynamic_override 10. Kinds: pipes 823, debris 534, fences 387, lights 321, Combine 230,
poles 133, barricades 105, barrels 82. Physics per map: median 37 (c11 0, c05 137, c08 107 + 25 overrides).

Pooled from measure.json (weighted by class counts):

| | grid yaw | turned 3-20 | free | touch a wall | >128 from walls |
|---|---|---|---|---|---|
| prop_static (3075) | 81% | 8% | 6% | 51% | 13% |
| prop_physics (714) | 53% | 23% | 20% | 12% | 16% |
| prop_dynamic (183) | 87% | 5% | 6% | 49% | 14% |

So the uprising keeps loose things squarer than the 22-map pass (physics on 90s: 53% here, 41% there) and fixed
things squarer still (81% vs 69%). Shadows off: dynamics 66%, statics 16%, physics 14%.

### Rebel barricades are models, not furniture piles

73 props_debris barricade models (barricade_short04a 34, barricade_tall02a 16, tall03a 6, short01a-03a 3 each,
tall04a 1, concrete_debris256barricade001a 7), every one but one prop_static. Sizes: short04a 94x183x58,
tall02a 78x108x124, tall03a 80x134x116, short03a 56x122x63, short02a 66x98x56, short01a 45x69x56, rubble
barricade 126x262x50. Only 19 of 73 stand within 160 of another (pairs of 2, one three); 54 stand alone.
- 39 of 73 touch a wall (26 with an end on it, 13 with the back on it); a way past is left open: across the long
  axis the free gap beside the barricade is over 128 for 66 of 73, median 957 to the next wall (rays on axis brushes).
- 7 plug a doorway or gap under 256 (two in c07 fill 96-wide doorways: tall02a, short02a with short01a on its
  side on top).
- 45 of 73 square on the grid, 11 tilted (up to 30), set into the floor 0 to 5 (median 0; p10 -5).
- Furniture barricades exist only as rooms: couches 11, drawers 16, tables, beds inside flats, not piled in streets.

### Combine barricades: rows of one piece at a fixed pitch

78 props_combine barricade pieces, all static, 74 square on the grid, never tilted, sunk 1 to 5.
- combine_barricade_tall02b (142x133x261) in rows of 2 to 4 at exactly 128 apart, back against a building
  (20 of 24 that touch a wall have their back on it), ends on walls.
- med01a/med01b in long rows of 9 and 10 at 63 to 64 apart (spans 512 and 567) across the plaza (c11, c12),
  one yaw for the whole row; med02a/b/c in pairs 128 apart; short01a-03a in pairs 63 to 146 apart.
- combine_fence01a and 01b (27x61x192) as a pair of posts with the field between: posts 113 to 488 apart (488
  three times in c10a), 35 of 38 posts touch a wall (set into the sides of a gap). The field is a func_brush or
  func_illusionary 1 thick and 192 tall, effects/combineshield/comshieldwall2 on both faces and nodraw round it
  (c10b cuts one into nine 32-wide pieces).

### Cars: turned, half tilted, against the walls

52 cars, vans and trucks (plus wheels and parts). Yaw: free 30 of 58, 3-20 16, square only 12. 26 tilted over 5
degrees (car001b_hatchback on its roof at 180, others on their side at 73 to 104). Wall gap median 4 (half touch
a wall), q75 90. Skins varied (about half not 0). 13 have an env_fire or smokestack within 200, 9 a scorch1 decal
under them, trashdecal01a beside 14. Physics only for the small car models (car002b, 003b, 004a, 005a/b,
van001a_physics); trucks, tankers and the burnt hatchback are static. Crushed cars are prop_ragdoll (car001a_phy 3).

### Rubble and ruin: models fitted to the break

| family | n | grid yaw | tilted >5 | touch a wall | bottom over the floor | notes |
|---|---|---|---|---|---|---|
| concrete_section (64floor, 128wall, 128floor) | 128 | 127 | 22 | 106 | median 104, q75 184 | on broken floor edges at storey height |
| rebar (clusters, singles, medthin) | 124 | 64 | 108 | 52 | median 80 | sticks out of the sections, 17 prop_dynamic |
| debris piles 256/128 | 106 | 83 | 18 | 69 | median -3 (p10 -10) | sunk a few units at wall feet, fade 1100 to 1660 on 38 |
| broken fronts (building_broken*, walldestroyed*, windowdestroyed) | 98 | 84 | 10 | 58 of 90 | median 0 | fitted to the wall hole |
| destroyedceiling01a-d | 37 | 37 | 0 | 36 | 80 to 200 | under the ceiling of a burned flat (c06b 23) |
| concrete_chunk (physics) | 23 | 16 | 13 | 5 of 17 | 0 | loose pieces |

Groups at 128: 220 alone, 53 pairs; mixes: section alone 21, rebar alone 14, rebar + section 10, pile + section 4.
Style guide rooms: styleguide_c17_rubble is a distant ruin vista (collapsedbuilding01a/02c, project_destroyedbuildings01,
parliament_dome_destroyed_exterior, walldestroyed09a-g) over a displacement ground of power 3 at lightmapscale 64;
styleguide_c17_rubble_2 is a ruined street: concrete_section64floor001b 17, piles 15, rebar 10, walldestroyed09 10,
48 displacements (power 3 on 43, lightmapscale 16 on 31).

### Loose props in a war (748 physics props)

- On exact 90s 54%, tilted over 5 degrees 28%, lying (75 to 105) 13% (the 22-map pass: 41%, 43%, 23%).
- Flags: asleep 9% (26% before), motion disabled 21% (29%), debris 4% (10%), free on grab 12%, use output 61%;
  119 with flags 0. Held still: shelves 19, boards 19, debris 19, radiators 15, fences 15, cars 12, couches 9, bins 8.
  Debris flag: trash 17, personal 4. Asleep: personal things 18, boxes 6, bins 6.
- Fades on 12% of physics (max median 1500; bins 2250, crates 2200, debris 1200, bottles 1100) and 16% of
  statics (max median 1600; rubble 1200, fences 2400, barricades 2600, lamps 1200, Combine 1100).
- Skins not 0 on 767 of 4181 (pipes, fluorescent tubes skin 1, door01_left, oildrum001 20); rendercolor 5, modelscale 0.
- physdamagescale 0.1 on 744 of 748 (the default kept); explodedamage on 27 (the red barrels).
- 44 corpses (ragdolls; 47 of 51 ragdolls spawnflags 4): 34 indoors, wall gap median 32; a weapon within 160 for
  17 (median 52), a blood decal within 96 for 25; items rest on corpses 21 times, on tables 9.
- Items: item_item_crate 138 (the supply crate is the main cache), healthkits 72, batteries 51, dynamic resupply 39.

### Fires, burned flats

- env_fire 137 (c04 30, c12 22, c06b 19), firesize 64 (41), 128 to 150 (35), 48 (13), 32 (10); flags 47
  (infinite, smokeless, start on, start full, no glow) 39, 3 (lit later) 31, 45 (with smoke) 22. 85 outdoors.
- 111 of 137 have no prop within 64: they burn on rubble and floors, alone (57) or in rows (29 fires along one
  street in a single chain at 96).
- 88 have a light within 128 (median 33 away), orange: '254 150 35' 300 to 900, '254 174 10 500', no light styles
  (steady, as the owner wants). A scorch1 overlay under 42; a fire sound within 256 of 86.
- The burned block (c06b): burn01a 30 and burn02a 16 wall decals, scorch1 7, destroyedceiling01a-d 23 under the
  ceilings, streetwar.fire_tiny loops, plaster walls broken as small displacements (107 displacements, 128x45 and
  64x45, on plasterwall009d and 037f, power 2 and 3).
- Lived-in refuge (c06b 3176 877): couches 3, fridge 2, bottles 5, sinks, rug overlays, crying loop
  (d1_trainstation.crying), four citizens, being raided by soldiers.

### The Combine in the old city

- combine_lock01 (18x14x39) beside 21 of 22 Combine doors (func_door), centred 44 to 58 over the floor (median 52),
  on the wall, 2 to 11 from the door's origin.
- The creeping wall: combineinnerwall001a (306x296x998) and combineinnerwallcluster1024 (322x1024x1064) high in
  the skyline (z 400 to 1176), static, in broken runs of 2 to 4 pieces 150 to 250 apart, each turned in steps of
  15 degrees from the last (yaws 150, 165, 180, 210, 240, 255, 270, 285).

## 3. Building craft across the uprising (112,670 faces, 22,474 brushes)

- Texture scale 0.25 on 91% of faces (87% of area), 0.5 on 3%: the city stays at 0.25 even on its ruins.
- Lightmapscale 16 on 83% of faces (near 87%, mid 74%, far 68%), 64 on 7%, 32 on 7%, 8 on 2%. The uprising
  coarsens far faces less than the canals (far: 16 on 68%, 64 on 16%).
- func_detail 41% of brushes. Trims 2623 strips: 16x32 311, 8x32 262, 8x8 251, 8x16 234, 2x14 220 (window and
  door frames), 4x8 176. Ledges 517: out 8 (186), 32 (165), 16 (116); tall 8 (162), 32 (158), 16 (99).
  Chamfers 2984: 11.3 wide (8 off) 874, 22.6 (16 off) 735, 45.3 (32 off) 376. Slabs: 8 (1379), 16 (682), 32 (403).
- Walls change material first at 128 over the foot (12,885 columns), then 64 (4,489), 16 (2,935); banded share
  70 to 93% per map. Painted building_template fronts on 31 to 66% of front area (c04 66, c11 64, c10a 60).
- Glass panes 2 thick (69) or 8 (58); 64x96 the commonest pane.
- Doorways 48x108 (24), 96x108 (10), 56 and 59 x108 (6). Stairs 8x12 on 4,410 steps (16x24 on 42 in c03 only).
  Flats' ceilings 120 (c05 294 nodes, c06b 263, c07 124), 184 to 192 in shops and halls.
- Streets: roadway 256 (most maps), wall to wall median 512 to 768, kerbs 4.

### Broken walls and ruin brushes

Brushes in old materials (brick, plaster, concrete, stone, wood, templates) with a face at an odd angle (not a
simple ratio: 90, 45, 2:1, 3:2 stairs, 3:1, 4:1, 5:1, 15/30/60/75, 22.5/67.5): 8.1% of 20,584 (c04 3%, c06b 4%,
c05 6%, c10a 6%, c09 6%, c12 6%, c03 11%, c12b 11%, c08 16%), and 27% in styleguide_c17_rubble_2 (the ruin as Valve
meant it). 913 of 1661 are six-sided boxes with one or two odd faces; thickness 8 (205), 4 (139, planks), 64
(124), 16 (76); 1869 of 2143 odd faces are textured (the cut shows), most of them upright (jagged vertical edges).
(A first pass that counted 3:2 faces as odd gave 21%: stair stringers.)

### Displacements

- Outdoor rubble streets are power 3 (c02 56%, c03 59% with power 4 on 41%, c09 100%, c10a 89%, c11 100%,
  c12b 100%) at lightmapscale 16 near play, 512x512 to 1088x464, in concretefloor007a, dirtfloor005b,
  blendgrassgravel001a (alpha painted on the blends). The 22-map digest had power 2 on 86% of city displacements.
- Small displacements break walls and ceilings in burned rooms: c06b 107 (128x45, 64x45, 96x8 on plaster), c12 126
  (rockwall003a_c17 55), c08 144 (128x128 floors in blendsandrock004a and dirtfloor004a, 67 blend painted).
  c10b has 212 thin displacements on metalwall076a (160x12): the Combine wall's ribs.
- Style guide: styleguide_c17_rubble ground 21 displacements power 3 at 64 (a far vista); _2 48 displacements,
  power 3 on 43, 16 on 31 (a street).

### Decals and overlays

1,299 decals to 74 overlays (17 to 1; the 22-map pass 4.5 to 1). Overlays are mostly scorch1 and burn floor
overlays 248 to 287 across under fires and cars (c06a 9, c12 8). Decals per map 43 to 172: trash, stains,
plaster, graffiti, plants (ivy), burn in c06b (55 on walls), blood in c07 (18) and c09 (10).

## 4. Light across the uprising

The sun sinks across the chapter: pitch -25 to -40 and brightness 600 to 700 in c02 to c10b, -12 at 450 in c11,
-8 at 450 in c12 and 350 in c12b; skies sky_day03_01 to 05 in order; ambient 160 184 211 150 then 75 96 116 at the
end. Fog warm grey 224 224 201 from 3000 to 9000 (c02 to c05), 234 236 236 3000 to 6500 (c06b, c07),
214 207 189 1024 to 16285 (c11, c12). Lights warm in homes (c05 42 warm of 45, c06b 42 of 46), cool in
industry and the Nexus (c08 65 cool of 96, c10b 16 of 20). Fires carry their own steady orange light (above).
