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
