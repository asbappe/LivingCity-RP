# The canal modules (made by `_dev/tools/map_catalogue.py --list`: never edit by hand)

What a module is and how to lay them out: `docs/dev/map-building.md` ("Canal modules"). How to write one: `docs/dev/map-modules.md`. Everything under "named for the game" is there for the gamemode to give a use: nothing uses them yet unless a feature's own doc says so.

| Module | Long | What it is | Named for the game | File |
|---|---|---|---|---|
| `drain` | 1024 | 1. the storm drain junction, down to the city's sewers (left) | `lc_drain_grate`, `lc_drain_junction` | `map_modules.py` |
| `overflow` | 1024 | 2. the overflow toward Ravenholm, behind a sluice plate (left) | `lc_overflow_far`, `lc_overflow_moan`, `lc_overflow_sluice` | `map_modules.py` |
| `shanty` | 1536 | 4. the shantytown under a street bridge (left) | `lc_shanty_board`, `lc_shanty_cards`, `lc_shanty_fire`, `lc_shanty_fund`, `lc_shanty_soup` | `map_modules.py` |
| `vort` | 1024 | 6. the vortigaunt culvert (left) | `lc_vort_fire`, `lc_vort_seat_1`, `lc_vort_seat_2`, `lc_vort_seat_3` | `map_modules.py` |
| `relay` | 1024 | 7. Cubbage's relay shack and mast, on a pier (right) | `lc_relay_hum`, `lc_relay_lamp`, `lc_relay_mast`, `lc_relay_radio`, `lc_relay_seat` | `map_modules.py` |
| `checkpoint` | 1280 | 8. the Combine checkpoint: a wall, a force field gateway, a guard's platform and searchlight | `lc_checkpoint_field`, `lc_checkpoint_hum`, `lc_checkpoint_light`, `lc_checkpoint_light_b`, `lc_checkpoint_pen`, `lc_checkpoint_pen_spot`, `lc_checkpoint_post`, `lc_checkpoint_queue` | `map_modules.py` |
| `ash` | 768 | 10. the ash outfall: trash and burnt corpses (left) | `lc_ash_heap` | `map_modules.py` |
| `sludge` | 2048 | 11. the sludge tunnel: a shortcut through the long way round (left) | `lc_sludge_gas`, `lc_sludge_haze` | `map_modules.py` |
| `cistern` | 1536 | 12. the cistern for the hive boss (right) | `lc_cistern_gallery`, `lc_hive_boss_spot` | `map_modules.py` |
| `underpass` | 1536 | 13. the barnacle underpass | `lc_underpass_body_1`, `lc_underpass_body_2`, `lc_underpass_body_3`, `lc_underpass_body_4`, `lc_underpass_body_5` | `map_modules.py` |
| `tram` | 1536 | a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk | `lc_tram_exit`, `lc_tram_stash` | `map_mods_a.py` |
| `tenement` | 1280 | a tenement block fallen across the canal: the way on is through its rooms | `lc_tenement_lookout`, `lc_tenement_stash` | `map_mods_a.py` |
| `quay` | 1024 | stairs up to a quay with a street doorway (a cap to delete), a footbridge to a barred door | `lc_quay_far_door`, `lc_quay_street` | `map_mods_a.py` |
| `collapse` | 768 | a street's wall and roadway fallen in: a squeeze by the right wall, a crawl under the slabs | `lc_collapse_hide` | `map_mods_a.py` |
| `cells` | 1024 | the cells: a guard room, three barred cells, a crawl duct out (left) | `lc_cells_button_1`, `lc_cells_button_2`, `lc_cells_button_3`, `lc_cells_door_1`, `lc_cells_door_2`, `lc_cells_door_3`, `lc_cells_entry`, `lc_cells_grate`, `lc_cells_spot_1`, `lc_cells_spot_2`, `lc_cells_spot_3` | `map_mods_b.py` |
| `memorial` | 768 | the wall of the dead: plaques and candles in a recess under the open sky (left) | `lc_memorial_wall` | `map_mods_b.py` |
| `pit` | 1280 | the fighting pit: a caged sunken ring, tiers of seats, a bookmaker (left) | `lc_pit_bookie`, `lc_pit_corner_a`, `lc_pit_corner_b`, `lc_pit_gate`, `lc_pit_gate_button` | `map_mods_b.py` |
| `garden` | 1280 | the walled garden: soil beds, bean poles, a scarecrow, a lean-to, a rain butt (left) | `lc_garden_bed_1`, `lc_garden_bed_2`, `lc_garden_bed_3`, `lc_garden_bed_4`, `lc_garden_bed_5`, `lc_garden_bed_6`, `lc_garden_gate` | `map_mods_b.py` |
| `stash` | 768 | the stash: an arms room behind a section of wall that a pipe valve opens (left) | `lc_stash_inside`, `lc_stash_room`, `lc_stash_valve`, `lc_stash_wall` | `map_mods_b.py` |
| `clinic` | 1024 | the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left) | `lc_clinic_bed_1`, `lc_clinic_bed_2`, `lc_clinic_bed_3`, `lc_clinic_bed_4`, `lc_clinic_table` | `map_mods_b.py` |
| `lock` | 1536 | a lock house: two steel gates and the control house that works them | `lc_lock_a_move`, `lc_lock_a_open`, `lc_lock_a_shake`, `lc_lock_a_shut`, `lc_lock_a_slam`, `lc_lock_a_warn_1`, `lc_lock_a_warn_2`, `lc_lock_b_move`, `lc_lock_b_open`, `lc_lock_b_shake`, `lc_lock_b_shut`, `lc_lock_b_slam`, `lc_lock_b_warn_1`, `lc_lock_b_warn_2`, `lc_lock_button_a`, `lc_lock_button_b`, `lc_lock_gate_a`, `lc_lock_gate_b`, `lc_lock_house` | `map_mods_c.py` |
| `execwall` | 768 | the firing wall: a backstop, three posts, one hard lamp (left) | `lc_execwall_lamp`, `lc_execwall_line`, `lc_execwall_post_1`, `lc_execwall_post_2`, `lc_execwall_post_3` | `map_mods_d.py` |
| `substation` | 1024 | the substation: transformers behind chain link, a fuse panel to break (right) | `lc_substation_cut`, `lc_substation_fuse`, `lc_substation_gate`, `lc_substation_glow`, `lc_substation_hum`, `lc_substation_lamp`, `lc_substation_spark` | `map_mods_d.py` |
| `breach` | 1024 | the breach: the floor fallen into an old cellar, slabs for ramps, an undercut | `lc_breach_bottom`, `lc_breach_stash` | `map_mods_d.py` |
| `wreck` | 1024 | the wreck: a Combine carrier's container down in the canal, hollow, to race for | `lc_wreck_beacon`, `lc_wreck_cache`, `lc_wreck_spark` | `map_mods_d.py` |
| `morgue` | 1024 | the morgue: a cold room of drawers and tables behind a sliding door (left) | `lc_morgue_door`, `lc_morgue_ledger`, `lc_morgue_table_1`, `lc_morgue_table_2`, `lc_morgue_table_3` | `map_mods_d.py` |
| `straight` | 1024 | plain canal ("straight 1536", "straight 1024 bridge") | none | `map_modules.py` |
| `jog` | 1024 | the canal steps sideways to break a long view ("jog left 768", "jog right 1024") | none | `map_modules.py` |
| `tee` | 512 | a standard gate in the left wall, for another piece or layout to join | none | `map_modules.py` |
| `tunnel` | 1024 | the canal under the city: a covered stretch of any length ("tunnel 1536") | none | `map_mods_d.py` |

## Each module, in its own words

### `drain`

1. The storm drain junction: a way from the canal down into the city's sewers. In the left wall a drain's mouth
with a concrete collar and an arched roof; a junction chamber round a railed sump of standing water, two inflow
pipes, a valve wheel, a lamp; then thirteen steps down to the sewers' height (z 288), a grate, and a cap to delete
where the owner joins it to a sewer of theirs.
Named for the game: lc_drain_grate (a func_door: Open lifts it, Close drops it), lc_drain_junction (the chamber).
Unchecked: ambient/water/water_flow_loop1.wav.

### `overflow`

2. The overflow toward Ravenholm. A spillway in the left wall, its apron stepping down into the canal, shut by a
steel sluice plate on two lifting rods under a winch housing, red lamps either side. Behind the plate a ribbed
channel runs on to a cap ("delete to join Ravenholm"). Driftwood and a body lie against the plate.
"overflow 1280": how far the channel reaches from the canal's middle (default 1024).
Named for the game: lc_overflow_sluice (a func_door: Open lifts it), lc_overflow_moan (a sound from beyond the
plate, silent until told: PlaySound), lc_overflow_far (the channel's far end).
Unchecked: ambient/creatures/town_zombie_call1.wav, models/humans/charple02.mdl.

### `shanty`

4. The shantytown under a street bridge. The canal widens into a basin on its left; a boardwalk runs along the
basin's back, with a card room, a trader's stall with a counter and shelves, and a bunk room on it; under the street
between them, a fire drum with seats round it and a stove. Tin windbreaks along the basin's edge, lamps on a cable
from pole to pole, washing on a line, a boat pulled up, a notice board.
Named for the game (places only): lc_shanty_cards (the card room's table), lc_shanty_fund (the stall, for the fund's
screen), lc_shanty_soup (under the street, for the soup), lc_shanty_fire (the drum), lc_shanty_board (the notices).
Unchecked: ambient/fire/fire_small_loop2.wav, env_smokestack, the cable (move_rope), sprites/light_glow03.vmt.

### `vort`

6. The vortigaunt culvert: a low side drain in the left wall with a pipe along its roof, turning twice (nobody
in the canal can see or shoot into its end), a hanging of strips half across its last turn, and a dead-end chamber:
a ring of stones round a fire with a pot on a tripod, three mats, a shelf, things drying on a line, a seep of water
in one corner, a faint green glow in the air.
Named for the game: lc_vort_fire, lc_vort_seat_1 to _3 (the mats, facing the fire).
Unchecked: env_fire, ambient/fire/fire_small_loop2.wav, the line (move_rope).

### `relay`

7. Cubbage's relay. A concrete quay against the right wall, 128 high with steps up its upstream end, and on it a tin hut:
inside, the set on a bench, a chair, a cot, a map board. Beside it a lattice mast that stands about 350 over the canal's
walls, with rungs, two dish aerials, guy wires to the pier and the wall, a red lamp at its tip, and an aerial wire
across the canal to the far wall. A generator built of brushes hums behind the hut; fuel drums beside it.
Named for the game: lc_relay_radio (the set, a prop_dynamic), lc_relay_hum (the generator's sound: StopSound),
lc_relay_lamp (the red lamp's glow: HideSprite, ShowSprite), lc_relay_mast (the mast's foot), lc_relay_seat.
Unchecked: models/props_lab/citizenradio.mdl, ambient/machines/diesel_engine_idle1.wav, the cables (move_rope).

### `checkpoint`

8. The Combine checkpoint. People come at it from the module's entry (flip it to face the other way): a chicane
of barriers and dragon's teeth, then a Combine wall across the canal to z 720 with buttresses and one gateway
(192 wide, 160 high) shut by a force field. Behind the wall, on the left bank, a guard's platform 128 high (the banks
are its ramps) with a cabin, and stairs from it to a walk along the wall's top with battlements and two searchlights.
Under the walk on the right bank, a chain link holding pen with a sliding gate.
Named for the game: lc_checkpoint_field (a func_brush: Disable opens it, Enable shuts it), lc_checkpoint_hum (its
sound: StopSound, PlaySound), lc_checkpoint_light and lc_checkpoint_light_b (the searchlights: LightOff, LightOn),
lc_checkpoint_pen (the pen's gate, a func_door: Open, Close), lc_checkpoint_pen_spot (where a prisoner stands),
lc_checkpoint_post (the guard's place on the wall), lc_checkpoint_queue (where people wait to be seen).
Unchecked: effects/com_shield003a, ambient/machines/combine_shield_loop3.wav, point_spotlight and light_spot keys.

### `ash`

10. The ash outfall (the owner: "just trash and burnt corpses"). High in the left wall, a chute's mouth: a real
hole under a concrete hood, barred, black behind, with a steel tray. Under it a heap of ash and rubbish 110 high
with the burnt dead in it, thin smoke rising from it; a second, smaller heap; a tipped barrow built of brushes.
No way in or out.
Named for the game: lc_ash_heap (the top of the heap).
Unchecked: the garbage pile and garbage bag models, models/humans/charple01..04.mdl, metalbucket01a, env_smokestack.

### `sludge`

11. The sludge tunnel. The canal goes the long way round a block (out to the left and back, about 3,800, under a
street and past a dumped container), and a low tunnel 768 long cuts straight through, ankle deep in toxic runoff:
green lamps, six outfall pipes running slime, the start of a plank walk that has rotted away, drums, a body.
Named for the game: lc_sludge_gas (a trigger filling the tunnel's air: a place for gas masks), lc_sludge_haze (the
green haze in it, a func_dustcloud: TurnOff, TurnOn).
Unchecked: nature/toxicslime002a, func_dustcloud and its keys, ambient/levels/canals/toxic_slime_loop1.wav.

### `cistern`

12. The cistern, for the hive boss (blind, hunts by sound). Off the RIGHT wall, a tall passage with a stair in
it leads to a round settling tank 1536 across, ankle deep in water. Two levels: a dry ledge round the tank at the
canal's height with four plank walks out to an island in the middle, and over the ledge a gallery with a rail,
128 up, reached by the stair. Four pillars, three inflow pipes high in the wall, chains hanging; the island lies
under a grated shaft open to the sky, so it stands in daylight while the rest is dim.
Wading is in the water (the game can tell: a player's water level); the ledge, the planks and the gallery are dry.
Named for the game: lc_hive_boss_spot (the island), lc_cistern_gallery (the head of the stair).
Unchecked: ambient/water/water_flow_loop1.wav, the chains (move_rope).

### `underpass`

13. The barnacle underpass: 1024 of canal under a wide road, unlit. Three piers stand down its middle; six
barnacles hang from the roof between them. Part of the roof has come in by the right wall: daylight down a shaft,
a fallen slab, rubble. A lorry jammed against a pier, a car, cables hanging, and five of the dead lying where they
were dropped, one beside a lantern that still burns.
Named for the game: lc_underpass_body_1 to _5 (where each body lies: things to search).
Unchecked: npc_barnacle (and whether the game minds NPCs it did not make), models/humans/corpse1.mdl and
charple01, charple03, ambient/atmosphere/tunnel1.wav, the cables (move_rope).

### `tram`

The fallen tram bridge. A tram line crossed the canal here; its bridge is gone but for a stub of deck at each
wall, one whole girder on a pier and one that sags. In each wall, at the trim's height, a station opens: a short
tunnel mouth, then a hall with a tiled platform either side of the track, columns, benches and dim lamps. The left
station (+v) has a ticket booth and, at the back, a stair up to the street shut by bars with black behind
(lc_tram_exit); its track ends at a buffer. A derailed car built of brushes hangs from the left mouth down to the
canal floor (its floor climbs 248 over a run of 310, about 39 degrees): walk in at its low end by the right bank
and up through it into the left station. The right station is reached only by the whole girder, a beam 16 wide
and 368 long, 256 over the floor: a second car stands at its platform with a cache in it (lc_tram_stash).
Dropping from either stub onto a bank is safe; there is no other way up.
Named for the game: lc_tram_exit (an info_target on the left platform before the barred stair: where people come
from or go to the street), lc_tram_stash (an info_target inside the car in the right station: a cache).
Unchecked: how the bench, payphone, bin, locker and mattress models face and how big they are.

### `tenement`

The fallen tenement. A block that stood on the left street has gone into the canal and lies across it from u 320
to 960: there is no way round, the way on is through its rooms. Its body fills the canal from the right wall to
v 128; the strip left over by the left wall is choked by its own outer wall, fallen in slabs (with an unseen wall
for players in it). Ground floor, 112 high: an entry hall, a living room, a kitchen, a stair hall open to the
leaning roof, a bedroom, a small room with a bed, and behind that a nook that is easy to miss (a crawl hole 40
high by the bed, or a hole in the floor above): lc_tenement_stash. A stair climbs to the one room left upstairs,
with a window over the canal the far way (lc_tenement_lookout); out of that window is a drop, never a way in.
The roof is sheared slabs lying where they slid. Where the block stood, the left wall is bitten out down to the
trim, with its cellar walls and floor beams left.
The way through, door by door (wide by high): the hole in the entry wall 64 by 88; hall to living room 48 by 84;
living room to kitchen 48 by 88; kitchen door to the stair hall 48 by 96; stair hall to bedroom 48 by 92; the hole
in the far wall 64 by 92. A short cut from the hall to the stair hall is a crawl, 48 by 40.
Named for the game: lc_tenement_stash (an info_target in the nook: a cache), lc_tenement_lookout (an info_target
at the upstairs window: a sentry's place).

### `quay`

The quay: a way up to the streets. Stairs 64 wide climb along the left wall from the canal floor (u 64) to a
landing at the trim's height (u 448 to 512), with a rail on the canal's side. The landing opens onto a quay
recessed into the left wall, 640 by 256 and open to the sky: a low wall along its edge, two lamp posts built of
brushes, mooring bollards with a boat roped below, a skip, a bench, crates. At the back a street doorway 128 wide
and 128 high stands in a concrete frame, closed 64 in by a cap of the world in its own visgroup ("the quay's
street end (delete to join a street)"). From the quay a footbridge on two trestles crosses to a barred doorway in
the right wall, black behind its bars.
Named for the game: lc_quay_street (an info_target in the street doorway, facing the quay: where people arrive
from the street), lc_quay_far_door (an info_target on the bridge before the barred door).

### `collapse`

The cave-in. The left street's retaining wall and a length of roadway have come down across the canal (the wall
is bitten out to a ledge of earth at z 528, open to the sky). From the bite to v 32 two great slabs lean on each
other like a tent, its ridge at z 640; from v 32 a wedge of roadway slopes down to a standing piece of the wall at
v -160. Every face is steeper than a player can walk. Two ways through:
the squeeze: 96 wide between that standing piece and the right wall (v -256 to -160), open to the sky, no bank;
the crawl: a hole 48 wide and 44 high at the foot of the near slab (v 72 to 120) into the hollow under the tent
(192 by 96 of flat floor, room to stand, earth sloping up behind), and another out through the far slab (v 40 to
88): the two holes do not line up, so nobody sees or shoots straight through. The hollow is a hide
(lc_collapse_hide). Each side also has a perch: the earth bank leads up to the end of the bite's ledge beside the
slabs. Rebar, a car that came down with the road, rubble.
Named for the game: lc_collapse_hide (an info_target in the hollow under the slabs).

### `cells`

The cells: where the Resistance keeps captured Combine units. A plain steel door at the foot of the left wall
(lc_cells_entry: Use swings it in) opens on a guard room (a table, lockers, a board of keys). A corridor runs on past
three cells, each 128 by 160 behind a barred front: half of each front is a barred door (lc_cells_door_1 to _3) that
slides behind the fixed half when the button beside it on the corridor's pier is pressed (lc_cells_button_1 to _3,
tally marks over each say which). A mattress and a bucket in each; lc_cells_spot_1 to _3 are where a prisoner
stands. The far cell has a loose grate low in its side wall (lc_cells_grate: Use swings it; the game can Lock it)
onto a crawl duct 40 high that comes out at the canal's floor through a big outfall pipe: the way to break out, or in.
Unchecked: the sound ambient/atmosphere/tunnel1.wav; whether a prisoner's Use can reach a button round the pier's
corner (they are 16 past the cell's edge, facing away); how the prop models sit (table, chair, lockers, mattress).

### `memorial`

The wall of the dead: a shallow recess in the left wall, open to the sky, its floor one step above the canal's.
A stone wall stands against its back, covered in rows of small plaques (the upper rows half empty: room for more),
with a ledge at its foot where candle stubs burn steadily among tins of dried stalks, a few pictures and bottles;
a wreath over it, posters on the side walls, a line strung across, and a plank bench out in the canal facing it.
lc_memorial_wall is the middle of the wall, facing out: the game may one day list there the names of characters
who died for good.
Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (a low wind). No flowers: no flower model is
known to be in the owner's game, so the dried stalks are brushes.

### `pit`

The fighting pit: the canal opens on its left, through a mouth 512 wide, into an eight-sided arena under the
open sky. In its middle a ring sunk 64 into the floor, 384 across, floored with dirt, inside a chain-link cage on
posts; the one gate (lc_pit_gate, on the side toward the canal) slides aside when the button on the post beside it
is pressed (lc_pit_gate_button) or the game tells it to (Open, Close), and steps go down from it into the ring.
lc_pit_corner_a and lc_pit_corner_b are the two corners the fighters start in (a stool in each). Three tiers of
concrete seats, 32 high each, stand on the three far sides, with stairs of 16 up the middle of each side. By the
mouth on the right the bookmaker's table, chair and lamp under a chalk board of odds (lc_pit_bookie: where he
sits); on the left the corner men's bench, water drum and bucket. Two lamps hang over the ring from a gantry.
Unchecked: whether a press of the gate's button can be made through the cage from inside (it should not: the post
stands 16 clear of it); the button's model is Episode Two's (the framework's own choice).

### `garden`

The walled garden: where the Resistance grows food. A gap in the left wall, three steps up and a picket gate
(lc_garden_gate: Use swings it), opens on a yard 640 by 448 under the open sky, its floor 24 above the canal's.
Six raised soil beds edged with timber, three on each side of a path of flagstones (lc_garden_bed_1 to _6: on the
beds, for a farming job; 1 to 3 on the left going back, 4 to 6 on the right), ridged and planted; bean poles with
lines between over the first bed on each side; a scarecrow in the middle bed on the right. Against the back wall a
tool lean-to (a bench, pots, a shovel, a bucket), a rain butt fed by pipes down the wall in the left corner, a
compost bay in the right corner; a push cart and a crate of melons on the path.
Unchecked: nothing from memory (models and materials pass map_assets.py); how the loose things lie once the game
drops them (shovel, bucket, pots, melons, cart).

### `stash`

The stash: a secret arms room. From the canal there is only a run of rusted pipes on the left wall with a valve
wheel on the thick one (lc_stash_valve: Use turns it a quarter, and it turns back by itself). Turning it slides a
section of the wall itself aside (lc_stash_wall: 96 wide, 112 high, of the wall's own concrete, flush with it when
shut, its sill at the top of the bank, 128 up); it shuts again by itself after 12 seconds, and the button on the
wall just inside (lc_stash_inside) opens it from within. Behind: a short passage that turns twice, then the arms
room (lc_stash_room: its middle): racks of long guns on two walls, a workbench with a vice under a map board,
a planning table, shelves, crates.
Unchecked: func_rot_button (the valve wheel) is from memory, with its turning axis set by spawnflag 64 or 128 (the
map's x or y, whichever way the module is turned): if the wheel turns the wrong way round or not at all, the door
still needs only one Open sent to lc_stash_wall. The door slides a little inward as well as aside (its movedir is
2 degrees off the wall's line) so that, open, it does not lie in the wall's own face. Sounds doors/doormove1.wav and
doormove2.wav are the bunker doors' own.

### `clinic`

The clinic: a field hospital in a vault off the left wall, whitewashed and tiled against the canal's concrete.
A wide way in between two drawn curtains (a white cross on the wall over it); a ward of four beds along its back wall
with cloth screens between them (lc_clinic_bed_1 to _4: where a patient lies), a bedside locker and a drip stand
each; a dispensary nook behind a counter (crouch under its flap at the left end), shelves of bottles on its back
wall; through a curtained opening an operating theatre with a steel table under a strong lamp that shines straight
down (lc_clinic_table: on the table), a trolley and shelves; and off the theatre a sluice room with a sink, a
boiler and a floor drain.
Unchecked: the sound ambient/water/leak_1.wav; how the prop models sit and face (the bed frames above all: BED_YAW
turns them; the sink, radiator, shelves, table and chair).

### `lock`

The lock house: two heavy steel gates across the canal, 704 apart, and between them a control house on a concrete
gantry at the trim's height. Whoever holds the house cuts the canal in two.

Each gate is a pair of steel leaves between two concrete piers that fill the banks (the gateway is 256 wide); the
leaves slide into the piers. Shut, the canal is blocked wall to wall up to z TRIM + 16. They are drawn shut (so the
light on them is worked out there) and the map opens both as it starts: the canal is open until somebody shuts it.
A leaf is a func_button used as a mover (PressIn opens, PressOut shuts), exactly as the bunker's door: the
gamemode's door rules (kicks, lockpicks) do not reach it, nothing can use or shoot it open, and it has no damage of
its own: at 30 a second a leaf that meets somebody stops and waits.

Inside the lock, on the left bank, a concrete pier (the bank is its ramp) and stairs up to the gantry; on the gantry
the house: a slit each way down the canal, a button under each slit's end for the gate on that side, a desk. On the
left wall at the gantry's end a barred street door (never opens, black behind). The right half of the gantry holds
the hydraulic pack and cannot be reached.

Named for the game:
  lc_lock_gate_a, lc_lock_gate_b    the gates (a: toward the module's entry). Each name is on BOTH leaves of its gate.
                                    PressOut shuts, PressIn opens (no sound that way: use the relays).
  lc_lock_a_shut, lc_lock_a_open, lc_lock_b_shut, lc_lock_b_open
                                    relays: Trigger one to shut or open a gate with its sounds, warning lamp and
                                    slam. Only the one that makes sense is live (shut while open, open while shut).
  lc_lock_button_a, lc_lock_button_b   the buttons in the house (a press triggers both of its gate's relays).
  lc_lock_house                     the middle of the control house's floor.
  lc_lock_a_move, lc_lock_a_slam, lc_lock_a_warn, lc_lock_a_shake (and _b_)   the sounds, lamp and shake of each gate.

Unchecked: the two sounds are the bunker door's (Streetwar.d3_c17_11_garage_move1 / _stop1: the owner has heard
them there). That a func_button leaf simply stops against a player (no damage, no reversing) is how the bunker's
leaves behaved before their crushers were added, by its comments; not seen here. The desk and chair models are from
the guide's list, their sizes guessed.

### `execwall`

The firing wall: where the Combine shoots people. A recess in the left wall under the open sky, its floor a
slab 8 high: a backstop of old sleepers against the back wall, pocked dark, three timber posts with a rope's end on
each, a grating down the middle to the canal, a barrier at each corner, one hard lamp on a pole. The squad stands
in the canal, behind a low kerb. Sober, not gory.
Named for the game: lc_execwall_post_1 to _3 (at the posts, facing out), lc_execwall_line (where the squad stands,
facing the wall), lc_execwall_lamp (the lamp's beam: LightOff, LightOn).
Unchecked: the rope ends (move_rope), point_spotlight and light_spot keys.

### `substation`

The substation: what powers the Combine's things in the canals. A concrete quay against the RIGHT wall, 128 high
with steps up its upstream end, inside chain link with a sliding gate players open by hand. On it three
transformers built of brushes (finned, with insulators), cables up to an arm on the wall and across the canal, a
switch cabinet, a warning lamp, and a steady hum.
The cabinet's panel is a func_breakable (40 health): breaking it fires the relay lc_substation_cut, which stops
the hum, puts out the lamp and throws sparks: the game can hang more on it (dropping a checkpoint's force field).
Named for the game: lc_substation_fuse (the panel), lc_substation_cut (the relay: Trigger; give it more wires),
lc_substation_hum, lc_substation_lamp and lc_substation_glow, lc_substation_spark, lc_substation_gate (a func_door).
Unchecked: ambient/energy/electric_loop.wav, func_breakable's keys, the cables (move_rope).

### `breach`

The breach: the canal's floor has fallen into an old cellar. A pit 640 by 256 and 160 deep in the middle of
the canal, its bottom earth with standing water. Two slabs of the old floor lean down into it along its sides as
ramps (one from each end); a third still hangs over the downstream end and makes a dark undercut where things are
kept; iron sticks out of the broken edge, rubble lies at the bottom. The canal's banks pass either side, so nobody
has to go down.
Named for the game: lc_breach_bottom (the middle of the pit), lc_breach_stash (under the hanging slab).
Unchecked: nothing from memory but the look of it.

### `wreck`

The wreck: a Combine troop carrier's container has come down in the canal, nose first, and lies tilted with its
tail in the air. Built of brushes, hollow: a ramp of its own door leads up into it, benches along its sides, a
dim red lamp still on. Earth thrown up round its nose, sparks, thin smoke, its cargo scattered down the canal.
A thing to race for: the Combine to recover it, the Resistance to strip it.
Named for the game: lc_wreck_cache (inside, at the nose), lc_wreck_beacon (the red lamp's glow: HideSprite),
lc_wreck_spark (StopSpark).
Unchecked: env_spark, env_smokestack.

### `morgue`

The morgue: where the city's dead wait for the cremator. A sliding steel door in the left wall (players open
it by hand), a short passage, a tiled cold room: a wall of twelve drawers, two pulled out, three steel tables,
a drain in the floor, a clerk's desk with the ledger, cold lamps, a hum. The dead on the tables are props.
Named for the game: lc_morgue_door (a func_door), lc_morgue_table_1 to _3 (the tables), lc_morgue_ledger (the desk).
Unchecked: models/humans/corpse1.mdl as a ragdoll lying on a table (it may slide off), ambient/machines/...

### `straight`

Plain canal. "straight 1536": that long. Add "bridge" for a street carried over its middle, "pipes" for a pair of
pipes across it, "bare" for nothing left lying in it (otherwise a few odds and ends, the same every time).

### `jog`

The canal steps sideways, to break a long view: "jog left 768" (the default), "jog right 1024".

### `tee`

A way off to the left: a standard gate in the left wall (512 wide, 256 high), capped until another piece, or
another layout's start, is joined to it.

### `tunnel`

The canal under the city: a covered stretch of any length ("tunnel 1536"), for passing under streets and
buildings. A raised kerb walk along each wall, roof beams, a pipe, a dim lamp every 256 on one side then the other.
