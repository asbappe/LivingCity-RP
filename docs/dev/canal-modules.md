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
| `scrapyard` | 1536 | the canal widens into a yard of stacked containers under a crane: ways through, ways over, a perch | `lc_scrap_perch` | `map_mods_a.py` |
| `boathouse` | 1024 | a smugglers' boat shed in the left wall: a roll-up door, a slipway, a hatch to a cellar | `lc_boathouse_button_in`, `lc_boathouse_button_out`, `lc_boathouse_cellar`, `lc_boathouse_door`, `lc_boathouse_hatch`, `lc_boathouse_hatch_button` | `map_mods_a.py` |
| `arcade` | 1536 | a market arcade over the canal on three arches: a covered walk above, a stair on each bank | `lc_arcade_upper` | `map_mods_a.py` |
| `chimney` | 1024 | a round yard on the right with a hollow brick chimney to climb: a lookout over the whole canal | `lc_chimney_top` | `map_mods_a.py` |
| `crypt` | 1024 | the left wall broken into a church crypt: pillars, niches with stone coffins, an altar, a bricked stair | `lc_crypt_altar` | `map_mods_a.py` |
| `lift` | 1024 | EXPERIMENTAL: a freight lift from the canal floor up to a loading dock with a street gate (a cap to delete) | `lc_lift_button_high`, `lc_lift_button_low`, `lc_lift_button_ride`, `lc_lift_dock`, `lc_lift_platform`, `lc_lift_street` | `map_mods_a.py` |
| `barge` | 1280 | a river barge grounded askew: a hideout in its hold, a wheelhouse, a gangplank from the bank | `lc_barge_hold`, `lc_barge_wheel` | `map_mods_a.py` |
| `busbridge` | 1024 | a bus hanging nose-down from the left street: climb through it to a pavement and a street doorway (a cap to delete) | `lc_bus_street`, `lc_bus_top` | `map_mods_a.py` |
| `shell` | 1024 | a headcrab canister in the right bank: a crater, a cracked wall, the start of an infestation (no creatures) | `lc_shell_canister`, `lc_shell_growth`, `lc_shell_patch_1`, `lc_shell_patch_2`, `lc_shell_patch_3`, `lc_shell_patch_4` | `map_mods_a.py` |
| `aqueduct` | 1024 | a water trough crossing over the canal on two piers: a ladder to a walk along it, a leak and a pool | `lc_aqueduct_walk` | `map_mods_a.py` |
| `pipes` | 1280 | a tangle of service pipes: duck and weave along the floor, or climb to a plank along the main and a bridge | `lc_pipes_top` | `map_mods_a.py` |
| `camp` | 1280 | a refugee camp on a terrace on the left bank: six tents of brushes round a cooking fire | `lc_camp_fire`, `lc_camp_tent_1`, `lc_camp_tent_2`, `lc_camp_tent_3`, `lc_camp_tent_4`, `lc_camp_tent_5`, `lc_camp_tent_6` | `map_mods_a.py` |
| `cells` | 1024 | the cells: a guard room, three barred cells, a crawl duct out (left) | `lc_cells_button_1`, `lc_cells_button_2`, `lc_cells_button_3`, `lc_cells_door_1`, `lc_cells_door_2`, `lc_cells_door_3`, `lc_cells_entry`, `lc_cells_grate`, `lc_cells_spot_1`, `lc_cells_spot_2`, `lc_cells_spot_3` | `map_mods_b.py` |
| `memorial` | 768 | the wall of the dead: plaques and candles in a recess under the open sky (left) | `lc_memorial_wall` | `map_mods_b.py` |
| `pit` | 1280 | the fighting pit: a caged sunken ring, tiers of seats, a bookmaker (left) | `lc_pit_bookie`, `lc_pit_corner_a`, `lc_pit_corner_b`, `lc_pit_gate`, `lc_pit_gate_button` | `map_mods_b.py` |
| `garden` | 1280 | the walled garden: soil beds, bean poles, a scarecrow, a lean-to, a rain butt (left) | `lc_garden_bed_1`, `lc_garden_bed_2`, `lc_garden_bed_3`, `lc_garden_bed_4`, `lc_garden_bed_5`, `lc_garden_bed_6`, `lc_garden_gate` | `map_mods_b.py` |
| `stash` | 768 | the stash: an arms room behind a section of wall that a pipe valve opens (left) | `lc_stash_inside`, `lc_stash_room`, `lc_stash_valve`, `lc_stash_wall` | `map_mods_b.py` |
| `market` | 1280 | the black market: a vaulted arcade of five shuttered stalls (left) | `lc_market_button_1`, `lc_market_button_2`, `lc_market_button_3`, `lc_market_button_4`, `lc_market_button_5`, `lc_market_shutter_1`, `lc_market_shutter_2`, `lc_market_shutter_3`, `lc_market_shutter_4`, `lc_market_shutter_5`, `lc_market_stall_1`, `lc_market_stall_2`, `lc_market_stall_3`, `lc_market_stall_4`, `lc_market_stall_5` | `map_mods_b.py` |
| `press` | 768 | the pamphlet press: a printing room behind a false stack of crates (left) | `lc_press_machine`, `lc_press_stack` | `map_mods_b.py` |
| `still` | 768 | the still: a pot still, mash casks and bottles in a cellar (left) | `lc_still_pot`, `lc_still_shelf` | `map_mods_b.py` |
| `plaza` | 1536 | the plaza: half a round amphitheatre of five tiers, a rostrum, fire drums (left) | `lc_plaza_crowd`, `lc_plaza_rostrum` | `map_mods_b.py` |
| `playground` | 1024 | the playground: a rusted relic on a terrace over the canal (left) | `lc_playground_bench` | `map_mods_b.py` |
| `clinic` | 1024 | the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left) | `lc_clinic_bed_1`, `lc_clinic_bed_2`, `lc_clinic_bed_3`, `lc_clinic_bed_4`, `lc_clinic_table` | `map_mods_b.py` |
| `lock` | 1536 | a lock house: two steel gates and the control house that works them | `lc_lock_a_move`, `lc_lock_a_open`, `lc_lock_a_shake`, `lc_lock_a_shut`, `lc_lock_a_slam`, `lc_lock_a_warn_1`, `lc_lock_a_warn_2`, `lc_lock_b_move`, `lc_lock_b_open`, `lc_lock_b_shake`, `lc_lock_b_shut`, `lc_lock_b_slam`, `lc_lock_b_warn_1`, `lc_lock_b_warn_2`, `lc_lock_button_a`, `lc_lock_button_b`, `lc_lock_gate_a`, `lc_lock_gate_b`, `lc_lock_house` | `map_mods_c.py` |
| `pumphouse` | 1280 | a pumping station: a machine hall, a flywheel, a turbine pit, a pipe bridge | `lc_pump_button`, `lc_pump_down`, `lc_pump_glow`, `lc_pump_hall`, `lc_pump_sound`, `lc_pump_start`, `lc_pump_stop`, `lc_pump_up`, `lc_pump_wheel` | `map_mods_c.py` |
| `thumper` | 1024 | a Combine thumper on a fenced terrace, with the box that stops it (experimental) | `lc_thumper_button`, `lc_thumper_down`, `lc_thumper_dust`, `lc_thumper_gate`, `lc_thumper_glow`, `lc_thumper_head`, `lc_thumper_hit`, `lc_thumper_pad`, `lc_thumper_shake`, `lc_thumper_start`, `lc_thumper_stop`, `lc_thumper_timer`, `lc_thumper_top` | `map_mods_c.py` |
| `depot` | 1280 | the Combine's ration depot: a roller door, a loading bay, caged stores, a staff door | `lc_depot_button_door`, `lc_depot_button_side`, `lc_depot_cage_1`, `lc_depot_cage_2`, `lc_depot_cage_3`, `lc_depot_desk`, `lc_depot_door`, `lc_depot_side` | `map_mods_c.py` |
| `armory` | 1024 | a Combine armoury vault behind a two-button door: a heist target | `lc_armory_alarm`, `lc_armory_blip`, `lc_armory_button_a`, `lc_armory_button_b`, `lc_armory_button_exit`, `lc_armory_count`, `lc_armory_door`, `lc_armory_groan`, `lc_armory_lamp_a`, `lc_armory_lamp_b`, `lc_armory_light`, `lc_armory_move`, `lc_armory_open`, `lc_armory_shake`, `lc_armory_shut`, `lc_armory_slam`, `lc_armory_vault` | `map_mods_c.py` |
| `swingbridge` | 1024 | a footbridge that turns on a pier: across the canal, or along it (experimental) | `lc_swing_bridge`, `lc_swing_lamp_a`, `lc_swing_lamp_b`, `lc_swing_move`, `lc_swing_stop`, `lc_swing_wheel_a`, `lc_swing_wheel_b` | `map_mods_c.py` |
| `floodroom` | 1024 | a valve chamber that floods: a trap or a refuge (experimental) | `lc_flood_chamber`, `lc_flood_door`, `lc_flood_door_out`, `lc_flood_drain`, `lc_flood_fill`, `lc_flood_rush`, `lc_flood_valve_a`, `lc_flood_valve_b`, `lc_flood_water` | `map_mods_c.py` |
| `railbridge` | 1024 | a railway bridge: a Combine train crosses every few minutes (experimental) | `lc_rail_horn`, `lc_rail_p1`, `lc_rail_p2`, `lc_rail_p3`, `lc_rail_p4`, `lc_rail_run`, `lc_rail_shake`, `lc_rail_signal_1`, `lc_rail_signal_2`, `lc_rail_timer`, `lc_rail_train` | `map_mods_c.py` |
| `execwall` | 768 | the firing wall: a backstop, three posts, one hard lamp (left) | `lc_execwall_lamp`, `lc_execwall_line`, `lc_execwall_post_1`, `lc_execwall_post_2`, `lc_execwall_post_3` | `map_mods_d.py` |
| `substation` | 1024 | the substation: transformers behind chain link, a fuse panel to break (right) | `lc_substation_cut`, `lc_substation_fuse`, `lc_substation_gate`, `lc_substation_glow`, `lc_substation_hum`, `lc_substation_lamp`, `lc_substation_spark` | `map_mods_d.py` |
| `breach` | 1024 | the breach: the floor fallen into an old cellar, slabs for ramps, an undercut | `lc_breach_bottom`, `lc_breach_stash` | `map_mods_d.py` |
| `wreck` | 1024 | the wreck: a Combine carrier's container down in the canal, hollow, to race for | `lc_wreck_beacon`, `lc_wreck_cache`, `lc_wreck_spark` | `map_mods_d.py` |
| `morgue` | 1024 | the morgue: a cold room of drawers and tables behind a sliding door (left) | `lc_morgue_door`, `lc_morgue_ledger`, `lc_morgue_table_1`, `lc_morgue_table_2`, `lc_morgue_table_3` | `map_mods_d.py` |
| `hq` | 768 | the Resistance leader's office: a briefing room and an office behind it, a flag outside (left) | `lc_hq_desk`, `lc_hq_flag`, `lc_hq_map`, `lc_hq_setup`, `lc_hq_table` | `map_town.py` |
| `straight` | 1024 | plain canal ("straight 1536", "straight 1024 bridge") | none | `map_modules.py` |
| `jog` | 1024 | the canal steps sideways to break a long view ("jog left 768", "jog right 1024") | none | `map_modules.py` |
| `tee` | 512 | a standard gate in the left wall, for another piece or layout to join | none | `map_modules.py` |
| `tunnel` | 1024 | the canal under the city: a covered stretch of any length ("tunnel 1536") | none | `map_mods_d.py` |
| `shed` | 2112 | plain canal with a train's shed on the street beside it (two to a straight run; needs "upper left") | none | `map_modules.py` |

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
Unchecked: that the hanging car's sheared floor (about 39 degrees) walks well in the game and that its window posts
do not snag; how the bench, payphone and locker models face.

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
Unchecked: that the crawl holes (40 high) pass a crouched player in the game as they do on paper; how the
furniture models face; that nobody can get onto the roof (unseen walls stand over it in case).

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
Unchecked: how the boat, bench and payphone models face; the doorway's frame stands 24 above the walls' tops
when the rim is at its lowest (784), which may look odd from the street.

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
Unchecked: that players cannot scramble up the slabs (they lean at 63 and 51 degrees; the game's limit is about
45); that the leaning hole reads as a way in; how the car lies.

### `scrapyard`

The scrapyard. The canal widens 384 on both sides into a yard where the Combine dump what they clear from the
streets: shipping containers built of brushes (each 384 by 128 by 128, walls 4 thick, to walk through and stand
on), bales of crushed cars, wrecks, tyres, and a tower crane on a plinth in the far right corner whose jib reaches
over the yard, its hook hanging on a rope above the highest container.
On the ground: a container lies across the canal at each end of the yard with a doorway cut through its sides
(64 wide, 96 high) and both ends open; between them one lies along the middle, open toward the entry, with a
doorway cut in its right side near its closed end; side lanes left and right run through more containers and
round the bales. Nothing gives a straight view from one end to the other.
Over the top: a ramp of planks at each end (128 up over 256) to the roof of the container lying across; from
the entry one plank bridges on to a covered porch on the middle stack and one to the left stack, where a ramp
(128 up over 192) climbs to the roof of the second level; a ramp from the far container's roof climbs there too.
From that roof a plank crosses to a ledge on the middle stack, and a ladder climbs the last 128 to the top of the
third container (lc_scrap_perch, z 784: level with the canal walls' tops, the whole yard under it). The second
container of the middle stack is open toward the exit: a nest reached from the far container's roof.
Named for the game: lc_scrap_perch (an info_target on the highest container: a sniper's or a lookout's place).
Unchecked: the ladder on a container's end (the shared helper's models and dismount points); that two planks 22
wide side by side walk as one ramp; the look of metal/metalwall014a and metal/metalcombine002 on containers;
how the wrecks lie.

### `boathouse`

The smugglers' boathouse: a boat shed built into the left wall, its floor 64 over the canal's. A slipway of
concrete with two launching rails climbs from the canal floor through a cut in the bank to a roll-up door of
corrugated tin 256 wide (lc_boathouse_door: a func_door that lifts). The door is worked by a button inside, to
the right of it, and by one outside on the canal wall, on the far side of a drain pipe so that nobody coming
along the canal sees it (stand on the bank to reach it). Inside: a boat on trestles on the rails, a winch at the
back with its cable on the bow, a workbench, shelves, fuel drums, two lamps. In the floor at the back a steel
hatch (lc_boathouse_hatch: a func_door that slides aside, worked by the button over the workbench) covers steps
down to a cellar 192 square where the contraband is kept (lc_boathouse_cellar).
Named for the game: lc_boathouse_door (func_door: Open, Close, Toggle), lc_boathouse_hatch (func_door, the same),
lc_boathouse_button_in, lc_boathouse_button_out, lc_boathouse_hatch_button (func_buttons that already work in the
map), lc_boathouse_cellar (an info_target in the cellar: the cache).
Unchecked: the buttons' model is Episode Two's (the shared button helper's choice); that the outside button can
be pressed past the pipe; that the hatch, sliding from under someone, lets them down the steps cleanly.

### `arcade`

The market arcade: an old covered market built over the canal on three stone arches (u 640 to 896). Below, the
canal passes between two piers 64 thick with cutwaters: a middle arch 128 wide over the flat of the floor, a side
arch over each bank. Above, at the trim's height, a covered walk 256 wide crosses from wall to wall under a
pitched tin roof on columns: open bays with a parapet 36 high look up and down the canal, three empty stalls
stand down its middle (counters either side, a canopy), shop shutters close its two ends. It is reached by a
stair along each wall from the canal floor: on the left bank from the entry side (u 256 up to 640), on the right
bank from the exit side (u 1280 down to 896), so each end of the canal has its own way up. Two levels to fight
over: whoever holds the walk sees both approaches, whoever is below has the piers.
Named for the game: lc_arcade_upper (an info_target in the middle of the walk).
Unchecked: the look of stone/stonewall040f on the piers and arches; how the bin faces.

### `chimney`

The chimney. The canal widens to the right into a round yard 896 across, and in its middle stands what is left
of a factory: its brick chimney, eight-sided, hollow (200 across inside), on a plinth 320 across, tapering to its
top 624 over the canal floor and 240 over the canal walls' tops. A doorway 48 wide and 96 high at its foot faces
the canal. Inside, slabs of stone climb round the wall in thirteen short flights (five treads and a landing in
each corner, 48 up a side, an open well down the middle with the old hoist rope in it) to an iron gallery round
the chimney's top: plates to crouch behind on four sides, rails on the other four, a cap on four posts. From up
there the whole canal both ways is in view: a sniper's nest with one way up (lc_chimney_top).
Named for the game: lc_chimney_top (an info_target on the gallery).
Unchecked: that the corner landings turn a player comfortably (about 38 of clear floor between the well and the
corner's wall); how the taper looks in brick; whether the map's fog or far plane hides the canal from up there.

### `crypt`

The crypt. The canal's left wall has broken through into the crypt of a church that is no longer there: a
ragged hole 128 wide at the top of the bank (the bank is the way up), broken slabs round it, then a vaulted
room 512 square under a roof 112 high, its floor of old stone 128 over the canal's. Four squat pillars carry
arches both ways. In each side wall two burial niches hold a stone coffin; one coffin's lid is ajar. In the
middle of the nave stands a tomb that has been opened, its lid leaning against it. At the back a stone altar on
a step, a cross on the wall behind it (lc_crypt_altar), and to its right a stair that once went up into the
church: bricked up, with black showing through a gap at the top. The only light is candle stubs (steady) and
what comes in at the hole. Quiet and old: a place to hide, to meet, or to be buried.
Named for the game: lc_crypt_altar (an info_target before the altar).
Unchecked: models/gibs/hgibs.mdl as a prop_dynamic (the skull in the tomb); the look of
stone/stonefloor006d_c17 and stone/stonewall040f; whether eight small lights are enough to see by.

### `lift`

The freight lift (experimental: nothing like it has been compiled yet). A loading dock is recessed into the
left wall at the trim's height, 448 by 320 and open to the sky: a low wall along its edge, a lorry backed up to a
barred street gate, crates, a lamp post. The gate and the cap behind it are in one visgroup ("the dock's street
end (delete to join a street)"). Against the wall below the dock, where the bank is cut away, a lift platform
160 square with rails on three sides rides between four guide posts from the canal floor (its deck 8 over the
floor) up 256 to the dock (its deck 8 over the dock's: a step down). It is one func_door, lc_lift_platform,
that stays where it is sent; each of three buttons sends it to its other end (Toggle): one on a post at the
bottom, one on a post on the dock, one on a stand on the platform that rides with it. Its own moving sound is a
motor's, looping while it moves, and a clank when it stops.
Named for the game: lc_lift_platform (func_door: Open is up, Close is down, Toggle), lc_lift_button_low,
lc_lift_button_high (func_buttons that already work), lc_lift_button_ride (a func_button parented to the
platform), lc_lift_dock (an info_target on the dock), lc_lift_street (an info_target at the street gate).
Unchecked: that a func_door carries players up 256 smoothly and reverses if someone stands under it (it does no
harm: dmg 0); that the button parented to it follows and still takes a press; the sounds
plats/elevator_move_loop1.wav and plats/elevator_stop1.wav; the buttons' model is Episode Two's.

### `barge`

The grounded barge. A river barge lies on the canal floor from u 320 to 960, askew (its stern 80 nearer the left
bank than its bow: sheared in plan, never turned): a steel hull 640 long, 192 wide and 96 high, its sides flaring,
its bow and stern raked and tapered. Forward a mast and a winch; amidships the hold under four hatch covers, the
second slid back onto the third: a ladder goes down through the gap. The hold (336 by 128, 88 high) is somebody's
hideout: two bunks forward, a stove with its pipe up through the deck, a table, a hanging lamp, crates
(lc_barge_hold). Aft a wheelhouse with windows all round, a doorway astern and the wheel on its pedestal
(lc_barge_wheel). A gangplank runs level from the left bank to the deck. The canal stays passable either side of
the hull: a strip of floor and the bank.
Named for the game: lc_barge_hold (an info_target in the hold), lc_barge_wheel (an info_target at the wheel).
Unchecked: the ladder standing free in the hatch (the shared helper's models and dismount points); that walls
sheared in plan do not snag a player walking the side decks (40 wide).

### `busbridge`

The bus. A city bus has gone through the left street's parapet and hangs nose-down from the wall's lip to the
canal floor: a long hollow body of brushes, sheared (its floor climbs 248 over a run of 310, about 39 degrees),
its windows open, pairs of seats either side of an aisle 48 wide, its windscreen end open on the floor at v -54.
Climbing through it is a way UP: its back end comes out on a short stretch of pavement recessed into the wall at
the trim's height (256 by 128, open to the sky, the fence gone, what is left of the parapet either side, a bent
lamp post, a bus stop's sign), with a street doorway behind closed by a cap of the world in its own visgroup
("the bus's street end (delete to join a street)"). The canal stays passable under the bus's high end by the
left bank and round its nose on the right.
Named for the game: lc_bus_top (an info_target on the pavement where the bus comes out), lc_bus_street (an
info_target in the street doorway, facing the canal).
Unchecked: that the sheared floor walks well and the seats do not snag a climber; that players fit under the
high end (72 clear from v 66 to the bank).

### `shell`

The shell. A headcrab canister has come down in the canal: it stands out of the right bank where it struck,
nose buried, leaning back the way it came (an eight-sided body of brushes 48 across and about 190 long, two
bands, four tail fins; sheared, never turned), in a crater of thrown earth: a ring of mud raised on the floor
and clods of earth on the bank. The wall above it is cracked from the bank to the trim. Round it the beginnings
of an infestation: seven low fleshy mounds (one func_brush tinted dark red, lc_shell_growth, so the game can take
them away), three bodies lying where they fell, a thread of smoke from the crater, and a faint sick-green light
that does not flicker. No creatures: the game brings its own (the four patches).
Named for the game: lc_shell_canister (an info_target at the shell's open end), lc_shell_patch_1 to _4
(info_targets on the floor round it, where the game may put infestation patches and headcrabs), lc_shell_growth
(a func_brush: the mounds; Disable removes them).
Unchecked: that a func_brush takes the dark red tint (rendercolor) on plaster; models/humans/corpse1.mdl as a
ragdoll lying where put; how high the mud ring comes out (it is the mud's displaced skin, raised up to 34).

### `aqueduct`

The aqueduct. A smaller channel crosses OVER the canal at the trim's height: a concrete trough 112 wide on two
piers, from a barred culvert mouth in the left wall to one in the right (black behind the bars), 24 of standing
water in it. Along its entry side runs a maintenance walk 48 wide (the trough's rim and a grating on brackets)
with a rail on its outer edge: a ladder climbs the left pier's buttress to it (256 up), and from it the whole
canal can be watched, or crossed up high from bank to bank (the walk ends at each wall; the way down is the
ladder or a drop to a bank). At mid-span the trough is cracked: a dark stain down its side, and under it a
shallow pool on the canal floor in a ring of mud, with a dripping sound.
Named for the game: lc_aqueduct_walk (an info_target on the walk at mid-span: a lookout's place).
Unchecked: the sound ambient/water/drip_loop1.wav (if it is not there, the place is silent); water standing in a
trough of detail brushes; the pool, a sheet of water 5 deep lying on the floor; the ladder against a buttress.

### `pipes`

The pipes. A tangle of service pipes fills a stretch of the canal (eight-sided, 56 to 96 across).
On the floor: one pipe 80 across lies over the whole floor at u 480 with 52 under it, and the fat main along the
left side has 56 under it: everyone on the floor ducks once. Past it two pipes on the floor (80 high, too high
to hop) make a chicane: the first reaches from the main to v -32 (go round its end on the right), the second
from the right wall to v 32 (go round on the left, 56 of standing room beside the main, or duck under the
main). A last pipe crosses high overhead.
Over the top: steps (u 96 to 324, by the left side) up to a valve platform 152 over the floor, with a valve
wheel and gauges; from it a plank 32 wide with a rail runs along the back of the main (u 428 to 880); a grating
bridge crosses the canal there to a second fat pipe on the right, and from its end a ramp of planks (144 down
over 216) comes back to the floor at u 1192. That is also the only way for anyone who cannot duck.
A steam leak on the main (pale, small, with a hiss), risers up the walls with elbows into them, flanges,
saddles. The pipes are cover from end to end, and the plank is a firing step over all of it (lc_pipes_top).
Named for the game: lc_pipes_top (an info_target on the main's plank).
Unchecked: the sound ambient/gas/steam_loop1.wav; that 52 and 56 of headroom pass a crouched player easily; that
the 80-high pipes cannot be hopped (a crouch-jump may clear them: then the chicane is only cover).

### `camp`

The camp. The canal widens to the left onto a broad terrace of beaten earth 128 over the floor (896 by 448, open
to the sky; the bank along its whole edge is the way up). People who have nowhere else live here: six ridge
tents of brushes, no two the same size, patched from tar paper, carpet and sheeting, each with a mat inside, a
back pole and guy ropes to pegs, their open ends (crouch to go in) turned to a cooking fire in the middle: a ring
of stones, a pot on a tripod, embers that glow and do not flicker, a thread of smoke, log seats round it.
A washing line with what they own on it, a water barrel and buckets, a handcart, a notice post where the bank
comes up, a few crates and a chair. Quiet, poor, lived in.
Named for the game: lc_camp_fire (an info_target at the fire), lc_camp_tent_1 to lc_camp_tent_6 (an info_target
on the floor inside each tent: where someone sleeps).
Unchecked: how props/tarpaperroof002a, props/carpetfloor003a and props/carpetfloor006a look as tent cloth (no
canvas is in the game's own materials); that thin sheared sides 3 thick stop a player cleanly; that the washing
line's rope hangs where its cloths are (the rope sags by itself).

### `cells`

The cells: where the Resistance keeps captured Combine units. A plain steel door at the foot of the left wall
(lc_cells_entry: Use swings it in) opens on a guard room (a table, lockers, a board of keys). A corridor runs on past
three cells, each 128 by 160 behind a barred front: half of each front is a barred door (lc_cells_door_1 to _3) that
slides behind the fixed half when the button beside it on the corridor's pier is pressed (lc_cells_button_1 to _3,
tally marks over each say which). A mattress and a bucket in each; lc_cells_spot_1 to _3 are where a prisoner
stands. The far cell has a loose grate low in its side wall (lc_cells_grate: Use swings it; the game can Lock it)
onto a crawl duct 40 high that comes out at the canal's floor through a big outfall pipe: the way to break out, or in.
Unchecked: the sound ambient/atmosphere/tunnel1.wav; whether a prisoner's Use can reach a button round the pier's
corner (they are 16 or more past the cell's edge, facing away); which way the table, chair and lockers face (their
sizes and places are from the models' own files); the doors' sounds (the bunker's own, doors/doormove1.wav and
doors/gate_move1.wav).

### `memorial`

The wall of the dead: a shallow recess in the left wall, open to the sky, its floor one step above the canal's.
A stone wall stands against its back, covered in rows of small plaques (the upper rows half empty: room for more),
with a ledge at its foot where candle stubs burn steadily among tins of dried stalks, a few pictures and bottles;
a wreath over it, posters on the side walls, a line strung across, and a plank bench out in the canal facing it.
lc_memorial_wall is the middle of the wall, facing out: the game may one day list there the names of characters
who died for good.
Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (a low wind). No flowers: Half-Life 2's model
list has none, so the dried stalks are brushes.

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

### `market`

The black market: a vaulted arcade inside the left wall, entered from the canal's floor by two archways.
Five stalls in alcoves along its back, each with a counter (crouch under its left end to get behind it), shelves
of goods, a lamp, a crate to sit on, and a tin roll shutter over the counter (lc_market_shutter_1 to _5: each
lifts and drops when the button inside its own stall is pressed, lc_market_button_1 to _5, or when the game
sends Open or Close). lc_market_stall_1 to _5 are where the stallholders stand, facing out. A brazier burns in
the middle of the arcade, benches by it; a lookout's stool stands inside each archway, where the canal can be
watched both ways; ribs carry the vault at every pier.
Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look (the same settings as the vortigaunt
culvert's fire); func_door's "spawnpos" 1 (starts open) is from memory. The first, third and fifth shutters start up, the second and fourth down (to be seen both ways);
a shut stall is still got into under its counter's end: the shutter says closed, it does not lock.

### `press`

The pamphlet press: a short side tunnel off the left wall that seems to end in a stack of crates to the roof.
The crates are brushes; between the two at the floor is a gap 44 wide and 40 high behind a hanging sack (no
thing: walk, or rather crawl, through it). Behind is the printing room: a hand press built of brushes (a bed on
legs with the forme on it, a platen hanging from a screw between two cheeks, a long lever), lc_press_machine on
its bed; a type case with a sloped top; three drying lines across the room hung with sheets; stacks and tied
bundles of paper on a pallet (lc_press_stack); a table with an oil lamp; drums of ink; a mattress in the corner.
Unchecked: func_illusionary (the sack over the gap) is from memory; how taut the drying lines hang (the sheets are
brushes placed for a line with almost no sag).

### `still`

The still: a distillery in a cellar off the left wall. A short tunnel, then eight steps down into a cellar
64 below the canal's floor. Against its far side the pot still, built of brushes: a brick firebox open at the
front with a small steady fire in it, a round pot on it, a head that tapers up in rings, a pipe across to the
worm (a cask with hoops round it) and a spout over a glass jar (lc_still_pot: in front of the firebox). Three mash
casks along the left wall, one open; sacks; shelves of bottles along the back wall (lc_still_shelf: in front of
them); a table with a funnel and bottles; cut wood by the fire; a pale steam over the pot's head.
Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look and env_smokestack's (the framework's own
settings, made small and pale here); how the loose bottles lie.

### `plaza`

The plaza: where people gather to listen. The canal opens on its left, 1024 wide, into half a round
amphitheatre under the open sky: a flat floor 512 across, then five concrete tiers of seats stepping up and back
round it, each 16 high and 48 deep (walked up anywhere, sat on anywhere), the last one a broad walk under the
wall; the tiers' ends show as steps from the canal. At the canal's edge, facing the tiers, a timber rostrum three
steps up with a lectern (lc_plaza_rostrum: where the speaker stands, facing the tiers), between two poles that
carry a wire for a banner; a horn on one pole; a fire drum on each side of the floor. lc_plaza_crowd is the middle
of the third tier, facing the rostrum.
Unchecked: env_fire's look in the drums (the vortigaunt culvert's settings); no sound here.

### `playground`

The playground: a relic of before. A terrace 128 above the canal's floor on the left, open to the sky (the
bank along it is the way up). On it, rusted and built of brushes: a swing frame with two seats on chains, one
hanging by a single chain with its end on the ground; a slide with a ladder of rungs and a railed top; a
roundabout; a sandpit edged with timber; and a bench with its back to the wall, facing it all
(lc_playground_bench: on the bench). Nothing else, and no lamp.
Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (one faint wind); how the chains hang (they
are ropes drawn taut between two points each).

### `clinic`

The clinic: a field hospital in a vault off the left wall, whitewashed and tiled against the canal's concrete.
A wide way in between two drawn curtains (a white cross on the wall over it); a ward of four beds along its back wall
with cloth screens between them (lc_clinic_bed_1 to _4: where a patient lies), a bedside locker and a drip stand
each; a dispensary nook behind a counter (crouch under its flap at the left end), shelves of bottles on its back
wall; through a curtained opening an operating theatre with a steel table under a strong lamp that shines straight
down (lc_clinic_table: on the table), a trolley and shelves; and off the theatre a sluice room with a sink, a
boiler and a floor drain.
Unchecked: the sound ambient/water/leak_1.wav; which end of a bed frame is its head, and which way the sink,
stove, radiator and shelves face (sizes and places are from the models' own files; BED_YAW turns the frames).

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

### `pumphouse`

The pumping station: off the left wall, through a wide doorway, a machine hall 704 by 512 and 320 high. Facing
the door a flywheel 144 across turns slowly (lc_pump_wheel) on the shaft of a gearbox; a pump drum lies each side
of the gearbox on concrete saddles, with suction pipes back into a turbine pit (192 square, 96 deep, ankle deep in
water, steps down into it, a rail round it, the turbine's casing standing in it) and risers up to a header under the
roof. The main leaves through the front wall, runs along the canal wall and crosses the canal overhead on a pipe
bridge nobody can reach. A steel gallery runs round the hall 144 up (stairs in the corner left of the door); on it,
over the door, the control desk: gauges, a lamp, and the button that stops and starts the pumps.

Named for the game:
  lc_pump_wheel     the flywheel: a func_rotating (Start, Stop). It turns as the map starts. Not solid: an unseen
                    wall for players stands round it instead, so nobody is caught in it.
  lc_pump_button    the button on the desk: a press triggers both relays below; only the live one answers.
  lc_pump_stop, lc_pump_start   relays: Trigger one to stop or start the pumps (wheel, sound, the desk's lamp).
                    lc_pump_stop is live while they run, lc_pump_start while they stand.
  lc_pump_sound     the pumps' drone (a looping sound, playing from the start).
  lc_pump_down, lc_pump_up      the run-down and run-up sounds.
  lc_pump_glow      the green lamp on the desk: lit while the pumps run.
  lc_pump_hall      the hall's floor, inside the door.
An areaportal stands in the doorway's thickness (well clear of the pit's water).

Unchecked: func_rotating's keys from memory ("maxspeed" 40 degrees a second, "fanfriction", spawnflags 1 start on +
16 run up and down + 64 not solid, and 4 or 8 for the axle: if the wheel tumbles instead of turning, those two are
the other way round). Sounds from memory: ambient/machines/pump_loop_1.wav, ambient/machines/thumper_shutdown1.wav,
ambient/machines/thumper_startup1.wav. Material metal/metalgrate013a passes the assets check; how it looks as a
floor is not known.

### `thumper`

EXPERIMENTAL: a Combine thumper. The canal widens to the right into a concrete terrace 512 long and 384 deep,
128 over the floor (the bank is its ramp). On it, behind a chain link fence with a gate players open, a thumper
built of brushes: four leaning legs of Combine metal 240 high carrying a sleeve, and through the sleeve a piston
with a heavy head that lifts 96 and drops on a steel striker plate, for ever. Each time it lands the ground shakes,
it thuds, and dust jumps from the plate. Against the terrace's near wall a control box with the button that stops
and starts it. The head has no damage of its own: it turns back from whoever stands under it.

Named for the game:
  lc_thumper_head    the piston: a func_door, drawn down. Open lifts it; "wait" 0.4 and no toggle, so it comes down
                     by itself. OnFullyOpen sets its speed to 384 (the drop), OnFullyClosed back to 96 (the lift).
  lc_thumper_timer   a logic_timer, RefireTime 3, that fires Open. Disable stops the thumper, Enable starts it.
  lc_thumper_stop, lc_thumper_start   relays: Trigger one to stop or start it (the timer, the lamp, a sound).
                     lc_thumper_stop is live while it runs. The game may hang antlions on lc_thumper_stop.
  lc_thumper_button  the button on the control box: a press triggers both relays; only the live one answers.
  lc_thumper_pad     the ground under the head.
  lc_thumper_gate    the fence's gate (a func_door_rotating: Use opens it; the gamemode can lock it).
  lc_thumper_hit, lc_thumper_top, lc_thumper_shake, lc_thumper_dust, lc_thumper_glow, lc_thumper_down
                     the thud, the clank at the top, the shake, the dust, the lamp on the sleeve, the run-down sound.

Unchecked: that a func_door takes the input SetSpeed (if it does not, the head lifts and drops at 96: 2.4 seconds
of a 3 second beat, still landing every time). env_smokestack's TurnOn and TurnOff for the dust. Sounds from
memory: ambient/machines/thumper_hit.wav, ambient/machines/thumper_top.wav, ambient/machines/thumper_shutdown1.wav.

### `depot`

The Combine's ration depot: a place to raid. In the left wall a steel roller door 192 wide (lc_depot_door, shut)
opens straight off the canal's floor into a loading bay with a truck backed up to a dock 40 high. The dock runs
along the back (pallets of crates) and fills the far half of the hall: three chain link cages of shelved cartons
and crates against the back wall, each with its own gate (lc_depot_cage_1 to _3: Use opens them, the gamemode can
lock them), the dispatch desk with a Combine console (lc_depot_desk), and a roller conveyor that carries crates out
through a low hatch in the wall and down a chute to the canal (the hatch is 26 high over the rollers: nobody gets
in that way). At the far end a staff door (lc_depot_side) up five steps from the canal: no Use opens it, only the
button beside it inside, and it shuts by itself after four seconds.

Named for the game:
  lc_depot_door         the roller door: a func_door that lifts (Open, Close, Toggle).
  lc_depot_button_door  the button inside, left of the roller door: Toggle.
  lc_depot_side         the staff door: a func_door_rotating with no Use (Open; it shuts itself). The gamemode's
                        door rules (lockpicks, kicks) may still reach it: that is the raiders' other way in.
  lc_depot_button_side  the button inside beside the staff door: Open.
  lc_depot_cage_1, _2, _3   the cages' gates (func_door_rotating, Use).
  lc_depot_desk         the Combine console at the dispatch desk (a prop_dynamic).
In a --test file a red button in the roller door's mouth opens and shuts it from outside, as the game will.
Areaportals: one inside the thickness of each door, one in the hatch.

Unchecked: a func_door_rotating with spawnflags 0 and "wait" 4 as a door only an input opens; which way it swings
(either way is clear). All models pass the assets check; the truck's and the console's facing are guesses.

### `armory`

A Combine armoury vault: a heist target. Off the left wall an armoured corridor 128 wide runs 384 in to a vault
door: a slab of Combine metal 24 thick that slides sideways into the wall at 20 a second, with a klaxon, a groan
and a slam. Beside the corridor's first half is the guard booth, behind a wall of Combine metal with a doorway and
a slit that looks down the corridor. The door answers only to TWO buttons pressed within two seconds of each other:
one in the booth's far corner, one on the corridor wall by the door, 340 apart with the booth's wall between, so
it takes two people (a green lamp shows over each for the two seconds its press counts). Pressed together again,
they shut it. Inside the vault (384 by 256): rifle racks along two walls, stacked ammunition crates, and a
pulse-rifle charging frame of Combine metal with three rifles standing in it under a blue glow. A button inside by
the door opens it, so nobody is shut in.

The door is a func_button used as a mover, as the bunker's: the gamemode's door rules do not reach it, and it has
no damage of its own (at 20 a second it stops against whoever stands in its way).

Named for the game:
  lc_armory_door        the vault door (PressIn opens, PressOut shuts; use the relays for the sounds).
  lc_armory_button_a    the button in the guard booth.     lc_armory_button_b    the button by the door.
  lc_armory_count       a math_counter, 0 to 2: each press adds 1 and takes it off two seconds later; at 2 it
                        triggers both relays below.
  lc_armory_open, lc_armory_shut   relays: Trigger one to open or shut the vault with klaxon, groan, slam and the
                        red light. Only the one that makes sense is live.
  lc_armory_button_exit the button inside the vault: triggers lc_armory_open.
  lc_armory_vault       the middle of the vault's floor.
  lc_armory_lamp_a, _b, lc_armory_blip, lc_armory_alarm, lc_armory_move, lc_armory_slam, lc_armory_groan,
  lc_armory_light, lc_armory_shake   the buttons' lamps and blip, and the door's sounds, red light and shake.
Areaportals: one in the entry, one inside the vault door's thickness.

Unchecked: the wiring is the owner's nest door's (math_counter Add and Subtract, OnHitMax) and the sounds are the
bunker's and the nest's, heard there. The rifles in the frame are prop_dynamics turned to stand on their butts
("angles" -90 pitch): which way a weapon model's barrel lies is from its size alone. The weapon and ammunition
models pass the assets check as prop_dynamic; whether the gamemode lets players pick such props up is its affair.

### `swingbridge`

EXPERIMENTAL: a footbridge at the trim's height that turns on a round pier in the middle of the canal. As the
map starts it lies across, from a landing in the left wall to one in the right; turned a quarter it lies along the
canal and joins nothing. Each landing is a roofed alcove with a barred street door (never opens, black behind), a
green lamp that shows while the bridge is across, and a wheel on its back wall that turns the bridge (a button: a
press is Toggle). Each has its own stairs from the canal floor: a covered flight in the wall, open to the canal on
its side, running away from the bridge (the left one toward the module's exit, the right one toward its entry).
Whoever turns the bridge away strands the other bank at that height.

The bridge is 456 long and 64 wide, rails and all one func_door_rotating. Its corners sweep a circle 461 across;
the canal is 512 wide and the landings' lips stop 234 from the pier's middle, so it sweeps through nothing (ribs
and drain stubs are kept off the walls there; the walls' trim line stands 240 out). A gap of 6 is left at each end.
It has no damage of its own.

Named for the game:
  lc_swing_bridge    the bridge: Toggle (or Open: along the canal; Close: across). 12 degrees a second.
  lc_swing_wheel_a   the wheel on the left landing.     lc_swing_wheel_b   the wheel on the right landing.
  lc_swing_lamp_a, lc_swing_lamp_b   the green lamps (env_sprites): lit while the bridge is across.
  lc_swing_move, lc_swing_stop       the turning sound (looping) and the clank as it comes to rest.

Unchecked: a func_door_rotating this big, turning about its middle with people on it: the engine carries riders
round on a turning brush, but how well is only seen in the game. Spawnflags 32 (toggle) and no Use; outputs OnOpen,
OnClose, OnFullyOpen, OnFullyClosed for the sound and lamps. With "wait" -1 a blocked door does not turn back: it
waits, pushing. Sounds are the bunker door's (heard there).

### `floodroom`

EXPERIMENTAL: a valve chamber that can be flooded: a trap or a refuge. Off the left wall a short passage, a
steel door (lc_flood_door, open) and eight steps down into an eight-sided chamber 384 across. A steel gallery runs
round it 96 over its floor (stairs up to it inside the chamber); from the gallery's far side a passage leads round
the chamber and back to the canal through a second door (lc_flood_door_out: Use opens it), four steps over the
canal's floor. In the chamber's middle stands the main with a big valve wheel; a button on it (lc_flood_valve_b) and
one on the gallery's wall (lc_flood_valve_a) flood the chamber: the steel door at the foot of the way in drops,
then water rises 88 from under the floor to just under the gallery, in about fifteen seconds. Pressed again, it
drains and the door lifts. Nobody is hurt: whoever is on the floor swims up to the gallery and walks out.

Named for the game:
  lc_flood_water      the water: a func_water_analog under the chamber's floor (Open floods, Close drains; 6 a second).
  lc_flood_valve_a    the button on the gallery.     lc_flood_valve_b    the button on the main, at the floor.
  lc_flood_fill, lc_flood_drain   relays: Trigger one to flood or drain with the door and the sound. A press of
                      either button triggers both; only the one that makes sense is live.
  lc_flood_door       the door at the foot of the way in: a func_button used as a mover, as the bunker's (PressOut
                      shuts, PressIn opens; the map opens it as it starts). It has no damage of its own.
  lc_flood_door_out   the second door, at the canal (a func_door_rotating: Use; the gamemode can lock it).
  lc_flood_rush       the rushing sound, playing while the water moves.
  lc_flood_chamber    the middle of the chamber's floor.
Areaportals: one in the way in, one inside the second door's thickness: both dry, both well away from the water.

Unchecked: func_water_analog from memory ("movedir" up, "movedistance" 88, "speed" 6, "startposition" 0; inputs
Open and Close; outputs OnFullyOpen and OnFullyClosed). Its top is nature/water_canals_water_clear and its other
faces nodraw; if moving water will not draw with that material, a cheap water material is needed there. Whether
the engine lets a player surface cleanly 8 under the gallery. Sound from memory: ambient/water/water_flow_loop1.wav.

### `railbridge`

EXPERIMENTAL: a railway crosses over the canal on a steel girder bridge, from a tunnel mouth in the left wall to
one in the right. Every 150 seconds a horn sounds, a red lamp shows at each mouth, and two seconds later a Combine
train of three box cars comes out of the left tunnel, crosses, and is gone into the right one. The bridge shakes as
it passes. Under the bridge the canal carries on between two concrete piers; a crate or two has fallen off.
Nobody can get onto the bridge: its bed is 240 over the canal's floor, there are no stairs, and both tunnels are
dead ends (black at the back) long enough to hide the whole train.

The rails' bed is at the walls' top less 144 (z 640 with the usual walls), not higher: the canal walls' concrete
ends at the rim with the fence along it and sky above, so a tunnel mouth must end at the rim.

How it runs (none of it could be tried here):
  lc_rail_train    one func_tracktrain: all three cars, built standing hidden in the LEFT tunnel on lc_rail_p1.
                   "origin": its middle, on lc_rail_p1 exactly. "target" lc_rail_p1. "height" 0 (its origin rides
                   on the path). "orientationtype" 0 AND spawnflag 16 (fixed orientation): a tracktrain that turns
                   to face its path takes its nose to be the side built facing east, and a module can be turned
                   four ways, so this one never turns; its path is one straight line. "startspeed" 350 (Hammer
                   calls it Max Speed: what StartForward runs at) and "speed" 350 (Initial Speed: if the game
                   starts it moving at once, it makes one run as the map starts and then waits like any other).
                   spawnflags 530 = 2 no user control + 16 fixed orientation + 512 not blockable by players.
                   "dmg" 1000: whoever is on the rails (nobody can be, short of flying) is killed, not pushed.
  lc_rail_p1 .. lc_rail_p4   path_tracks in a ring. p1: where it waits (left tunnel), spawnflag 16 "teleport to
                   THIS path track". p2: 128 on, still in the tunnel; its OnPass starts the shake. p3: in the right
                   tunnel. p4: deep in the right tunnel, the whole train hidden; its OnPass tells the train Stop,
                   and since p4's next is p1 (a teleport one) the train is put back on p1 in the same moment, unseen.
                   So it always waits at p1 (within a tenth of a second's travel of it).
  lc_rail_run      a logic_relay: horn, lamps, and StartForward two seconds later. Trigger it to send a train now.
  lc_rail_timer    a logic_timer, RefireTime 150, that triggers lc_rail_run. Disable it to stop the trains.
  lc_rail_horn, lc_rail_shake, lc_rail_signal_1, lc_rail_signal_2   the horn, the env_shake (3.5 seconds, radius
                   1000 round the bridge's middle) and the two red lamps (env_sprites: ShowSprite, HideSprite).
In a --test file a red button on the left pier's canal face triggers lc_rail_run.
An areaportal stands 64 inside each tunnel, walled all round; the train passes through both.

Unchecked: everything above about func_tracktrain and path_track is from memory of Hammer's entity list (the
keys "startspeed", "speed", "orientationtype", "height", "wheels", "bank", "dmg", "MoveSound", "volume"; the
spawnflags; that a path_track with spawnflag 16 is teleported to; the inputs StartForward and Stop; the output
OnPass). The sounds are from memory: ambient/alarms/train_horn2.wav, ambient/machines/razor_train_wheels_loop1.wav.
If the train comes out sideways, the fixed orientation did not take: tell me. If it never moves, try "speed" 0.

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

### `hq`

The Resistance leader's office. A doorway in the left wall into a briefing room (a long table and benches, a
map board, a lamp), and behind a partition the leader's own office: a desk and chair, a filing cabinet, a strong
box, a cot. Outside by the door, a flagpole with a banner the game can show while this is the live headquarters.
Named for the game: lc_hq_setup (the doorstep: where the leader stands to set the headquarters up), lc_hq_flag
(the banner, a func_brush: Enable shows it, Disable hides it), lc_hq_desk, lc_hq_table, lc_hq_map.
Unchecked: a func_brush's rendercolor on plaster (the banner's red).

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

### `shed`

Plain canal, and on the street beside it a brick shed over the tracks, where a train waits out of sight. A
straight run needs two for a train: one to come out of, one to go into. Only where the layout has a street
("upper left"). "shed 2304": that long (by itself it is the length of the train and a little over).
