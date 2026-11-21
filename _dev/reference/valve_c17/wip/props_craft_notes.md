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
