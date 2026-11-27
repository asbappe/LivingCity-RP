# The canal modules (made by `_dev/tools/map_catalogue.py --list`: never edit by hand)

What a module is and how to lay them out: `docs/dev/map-building.md` ("Canal modules"). How to write one: `docs/dev/map-modules.md`. Everything under "named for the game" is there for the gamemode to give a use: nothing uses them yet unless a feature's own doc says so.

| Module | Long | What it is | Named for the game | File |
|---|---|---|---|---|
| `drain` | 1024 | 1. the storm drain junction, down to the city's sewers (left) | `lc_drain_cache`, `lc_drain_grate`, `lc_drain_junction`, `lc_drain_wheel` | `map_modules.py` |
| `shanty` | 2048 | 4. the shantytown under a street bridge (left) | `lc_base_vehicle_airboat_shanty`, `lc_hq_setup_shanty`, `lc_shanty_board`, `lc_shanty_cards`, `lc_shanty_fire`, `lc_shanty_fund`, `lc_shanty_soup`, `lc_shanty_tent_1`, `lc_shanty_tent_2`, `lc_shanty_tent_3`, `lc_shanty_tent_4`, `lc_shanty_tent_5`, `lc_zone_rebel_r780_h400_shanty` | `map_modules.py` |
| `vort` | 1024 | 6. the vortigaunt culvert (left) | `lc_vort_fire`, `lc_vort_npc`, `lc_vort_seat_1`, `lc_vort_seat_2`, `lc_vort_seat_3` | `map_modules.py` |
| `relay` | 1024 | 7. Cubbage's relay shack and mast, on a pier (right) | `lc_relay_hum`, `lc_relay_lamp`, `lc_relay_mast`, `lc_relay_radio`, `lc_relay_seat` | `map_modules.py` |
| `checkpoint` | 1280 | 8. the Combine checkpoint: a wall, a force field gateway, a guard's platform and searchlight | `lc_checkpoint_field`, `lc_checkpoint_hum`, `lc_checkpoint_light`, `lc_checkpoint_light_b`, `lc_checkpoint_pen`, `lc_checkpoint_pen_spot`, `lc_checkpoint_post`, `lc_checkpoint_queue` | `map_modules.py` |
| `ash` | 768 | 10. the ash outfall: trash and burnt corpses (left) | `lc_ash_clatter`, `lc_ash_dust`, `lc_ash_grate`, `lc_ash_heap`, `lc_ash_timer`, `lc_ash_tip` | `map_modules.py` |
| `sludge` | 2048 | 11. the sludge tunnel: a shortcut through the long way round (left) | `lc_sludge_gas`, `lc_sludge_gurgle`, `lc_sludge_gurgle_timer`, `lc_sludge_gurgle_timer_near`, `lc_sludge_haze` | `map_modules.py` |
| `cistern` | 1536 | 12. the cistern for the hive boss (right) | `lc_cistern_gallery`, `lc_hive_boss_spot` | `map_modules.py` |
| `underpass` | 1536 | 13. the barnacle underpass | `lc_underpass_body_1`, `lc_underpass_body_2`, `lc_underpass_body_3`, `lc_underpass_body_4`, `lc_underpass_body_5`, `lc_underpass_dust`, `lc_underpass_dust_timer`, `lc_underpass_dust_timer_near` | `map_modules.py` |
| `tram` | 1536 | a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk | `lc_tram_exit`, `lc_tram_stash` | `map_mods_a.py` |
| `quay` | 1024 | stairs up to a quay with a street doorway (a cap to delete), the swing bridge (it turns on a pier) to a barred door | `lc_quay_far_door`, `lc_quay_store_button`, `lc_quay_store_door`, `lc_quay_street`, `lc_swing_arm_a`, `lc_swing_arm_b`, `lc_swing_bell`, `lc_swing_bridge`, `lc_swing_lamp_a`, `lc_swing_lamp_b`, `lc_swing_move`, `lc_swing_red_a`, `lc_swing_red_a2`, `lc_swing_red_b`, `lc_swing_red_b2`, `lc_swing_stop`, `lc_swing_wheel_a`, `lc_swing_wheel_b` | `map_mods_a.py` |
| `collapse` | 768 | a street's wall and roadway fallen in: a squeeze by the right wall, a crawl under the slabs | `lc_collapse_hide` | `map_mods_a.py` |
| `boathouse` | 1024 | a smugglers' boat shed in the left wall: a roll-up door, a slipway, a hatch to a cellar | `lc_boathouse_button_in`, `lc_boathouse_button_out`, `lc_boathouse_cellar`, `lc_boathouse_door`, `lc_boathouse_hatch`, `lc_boathouse_hatch_button` | `map_mods_a.py` |
| `crypt` | 1024 | the left wall broken into a church crypt: pillars, coffins, an altar, a tunnel to Ravenholm's church in its walled graveyard behind | `lc_church_altar`, `lc_church_grigori`, `lc_church_side_door`, `lc_crypt_altar` | `map_mods_a.py` |
| `barge` | 1280 | a river barge grounded askew: a hideout in its hold, a wheelhouse, a gangplank from the bank | `lc_barge_hold`, `lc_barge_wheel` | `map_mods_a.py` |
| `shell` | 1024 | a headcrab canister in the right bank: a crater, a cracked wall, the start of an infestation (no creatures) | `lc_shell_canister`, `lc_shell_patch_1`, `lc_shell_patch_2`, `lc_shell_patch_3`, `lc_shell_patch_4` | `map_mods_a.py` |
| `aqueduct` | 1024 | a water trough crossing over the canal on two piers: a ladder to a walk along it, a leak and a pool | `lc_aqueduct_drip`, `lc_aqueduct_fall`, `lc_aqueduct_valve`, `lc_aqueduct_walk` | `map_mods_a.py` |
| `camp` | 1280 | a refugee camp on a terrace on the left bank: six tents of brushes round a cooking fire | `lc_camp_fire`, `lc_camp_tent_1`, `lc_camp_tent_2`, `lc_camp_tent_3`, `lc_camp_tent_4`, `lc_camp_tent_5`, `lc_camp_tent_6` | `map_mods_a.py` |
| `cells` | 1024 | the cells: a guard room, three barred cells, a crawl duct out (left) | `lc_cells_button_1`, `lc_cells_button_2`, `lc_cells_button_3`, `lc_cells_door_1`, `lc_cells_door_2`, `lc_cells_door_3`, `lc_cells_entry`, `lc_cells_grate`, `lc_cells_spot_1`, `lc_cells_spot_2`, `lc_cells_spot_3` | `map_mods_b.py` |
| `memorial` | 768 | the wall of the dead: plaques and candles in a recess under the open sky (left) | `lc_memorial_wall` | `map_mods_b.py` |
| `pit` | 1280 | the fighting pit: a caged sunken ring, tiers of seats, a bookmaker (left) | `lc_pit_bookie`, `lc_pit_corner_a`, `lc_pit_corner_b`, `lc_pit_gate`, `lc_pit_gate_button` | `map_mods_b.py` |
| `garden` | 1280 | the walled garden: soil beds, bean poles, a scarecrow, a lean-to, a rain butt (left) | `lc_garden_bed_1`, `lc_garden_bed_2`, `lc_garden_bed_3`, `lc_garden_bed_4`, `lc_garden_bed_5`, `lc_garden_bed_6`, `lc_garden_gate`, `lc_garden_plot_1`, `lc_garden_plot_2`, `lc_garden_plot_3`, `lc_garden_plot_4`, `lc_garden_plot_5`, `lc_garden_plot_6`, `lc_garden_plot_7`, `lc_garden_plot_8` | `map_mods_b.py` |
| `stash` | 768 | the stash: a brick arms room with guns on racks, behind a section of wall that a pipe valve opens (left) | `lc_stash_inside`, `lc_stash_room`, `lc_stash_valve`, `lc_stash_wall` | `map_mods_b.py` |
| `market` | 1280 | the black market: a vaulted arcade of five shuttered stalls (left) | `lc_market_button_1`, `lc_market_button_2`, `lc_market_button_3`, `lc_market_button_4`, `lc_market_button_5`, `lc_market_shutter_1`, `lc_market_shutter_2`, `lc_market_shutter_3`, `lc_market_shutter_4`, `lc_market_shutter_5`, `lc_market_stall_1`, `lc_market_stall_2`, `lc_market_stall_3`, `lc_market_stall_4`, `lc_market_stall_5` | `map_mods_b.py` |
| `press` | 768 | the pamphlet press: a printing room behind a door in a side tunnel (left) | `lc_press_door`, `lc_press_machine`, `lc_press_stack` | `map_mods_b.py` |
| `still` | 768 | the still: a pot still, mash casks and bottles in a cellar (left) | `lc_still_pot`, `lc_still_shelf` | `map_mods_b.py` |
| `plaza` | 1536 | the plaza: five rows of seats stepping down from the street to a stage at the back wall (left) | `lc_hq_setup_plaza`, `lc_plaza_crowd`, `lc_plaza_rostrum` | `map_mods_b.py` |
| `playground` | 1024 | the playground: Half-Life 2's own from the train station's courtyard, a path through it (left) | `lc_playground_bench`, `lc_playground_roundabout`, `lc_playground_roundabout_hinge`, `lc_playground_swing_1`, `lc_playground_swing_1_hinge`, `lc_playground_swing_2`, `lc_playground_swing_2_hinge`, `lc_playground_teeter`, `lc_playground_teeter_hinge` | `map_mods_b.py` |
| `clinic` | 1024 | the clinic: a ward, an operating theatre, a dispensary and a sluice room in a vault (left) | `lc_clinic_bed_1`, `lc_clinic_bed_2`, `lc_clinic_bed_3`, `lc_clinic_bed_4`, `lc_clinic_table` | `map_mods_b.py` |
| `lock` | 1536 | a lock house: two steel gates and the control house that works them | `lc_lock_a_klaxon`, `lc_lock_a_lamp_open`, `lc_lock_a_lamp_shut`, `lc_lock_a_move`, `lc_lock_a_open`, `lc_lock_a_shake`, `lc_lock_a_shut`, `lc_lock_a_slam`, `lc_lock_a_warn_1`, `lc_lock_a_warn_2`, `lc_lock_a_warn_3`, `lc_lock_a_warn_4`, `lc_lock_b_klaxon`, `lc_lock_b_lamp_open`, `lc_lock_b_lamp_shut`, `lc_lock_b_move`, `lc_lock_b_open`, `lc_lock_b_shake`, `lc_lock_b_shut`, `lc_lock_b_slam`, `lc_lock_b_warn_1`, `lc_lock_b_warn_2`, `lc_lock_b_warn_3`, `lc_lock_b_warn_4`, `lc_lock_button_a`, `lc_lock_button_b`, `lc_lock_gate_a`, `lc_lock_gate_b`, `lc_lock_house` | `map_mods_c.py` |
| `pumphouse` | 1280 | a pumping station: a machine hall, a flywheel, a turbine pit, a pipe bridge | `lc_pump_button`, `lc_pump_down`, `lc_pump_glow`, `lc_pump_hall`, `lc_pump_sound`, `lc_pump_start`, `lc_pump_stop`, `lc_pump_up`, `lc_pump_wheel` | `map_mods_c.py` |
| `thumper` | 1024 | a Combine thumper on a fenced terrace, with the box that stops it (experimental) | `lc_thumper_burrow`, `lc_thumper_button`, `lc_thumper_down`, `lc_thumper_dust`, `lc_thumper_gate`, `lc_thumper_glow`, `lc_thumper_head`, `lc_thumper_hit`, `lc_thumper_lamp`, `lc_thumper_pad`, `lc_thumper_shake`, `lc_thumper_start`, `lc_thumper_stop`, `lc_thumper_timer`, `lc_thumper_top` | `map_mods_c.py` |
| `depot` | 1280 | the Combine's ration depot: a roller door, a loading bay, caged stores, a staff door | `lc_depot_alarm`, `lc_depot_alarm_light`, `lc_depot_button_door`, `lc_depot_button_side`, `lc_depot_cage_1`, `lc_depot_cage_2`, `lc_depot_cage_3`, `lc_depot_desk`, `lc_depot_door`, `lc_depot_side` | `map_mods_c.py` |
| `armory` | 1024 | a Combine armoury vault behind a two-button door: a heist target | `lc_armory_alarm`, `lc_armory_beam_1`, `lc_armory_beam_1a`, `lc_armory_beam_1b`, `lc_armory_beam_2`, `lc_armory_beam_2a`, `lc_armory_beam_2b`, `lc_armory_blip`, `lc_armory_button_a`, `lc_armory_button_b`, `lc_armory_button_exit`, `lc_armory_count`, `lc_armory_door`, `lc_armory_groan`, `lc_armory_lamp_a`, `lc_armory_lamp_b`, `lc_armory_light`, `lc_armory_move`, `lc_armory_open`, `lc_armory_red_1`, `lc_armory_red_2`, `lc_armory_shake`, `lc_armory_shut`, `lc_armory_slam`, `lc_armory_vault` | `map_mods_c.py` |
| `railbridge` | 1024 | a railway bridge: a Combine train crosses every few minutes (experimental) | `lc_rail_dust_1`, `lc_rail_dust_2`, `lc_rail_dust_3`, `lc_rail_horn`, `lc_rail_p1`, `lc_rail_p2`, `lc_rail_p3`, `lc_rail_p4`, `lc_rail_run`, `lc_rail_shake`, `lc_rail_signal_1`, `lc_rail_signal_2`, `lc_rail_timer`, `lc_rail_train` | `map_mods_c.py` |
| `execwall` | 768 | the firing wall: a backstop, three posts, one hard lamp (left) | `lc_execwall_lamp`, `lc_execwall_line`, `lc_execwall_post_1`, `lc_execwall_post_2`, `lc_execwall_post_3` | `map_mods_d.py` |
| `substation` | 1024 | the substation: transformers behind the Combine's fence, a fuse panel to break (right) | `lc_substation_cut`, `lc_substation_fuse`, `lc_substation_gate`, `lc_substation_glow`, `lc_substation_hum`, `lc_substation_lamp`, `lc_substation_light_1`, `lc_substation_light_2`, `lc_substation_smoke`, `lc_substation_spark`, `lc_substation_spark_t1`, `lc_substation_spark_t2`, `lc_substation_spark_t3` | `map_mods_d.py` |
| `tramfall` | 1024 | the tram under the breach: the canal's floor fallen in over a tram tunnel, the wrecked car under the slabs, a station under the street | none | `map_mods_d.py` |
| `breach` | 1024 | the breach: the floor fallen into an old cellar, slabs for ramps, an undercut | `lc_breach_bottom`, `lc_breach_stash` | `map_mods_d.py` |
| `wreck` | 1024 | the wreck: a Combine carrier's container down in the canal, hollow, to race for | `lc_wreck_beacon`, `lc_wreck_cache`, `lc_wreck_spark` | `map_mods_d.py` |
| `morgue` | 1024 | the morgue: a cold room of drawers and tables behind a sliding door (left) | `lc_morgue_chute`, `lc_morgue_door`, `lc_morgue_ledger`, `lc_morgue_table_1`, `lc_morgue_table_2`, `lc_morgue_table_3` | `map_mods_d.py` |
| `servicetunnel` | 3008 | a long way on foot: Valve's tunnel from Black Mesa East toward Ravenholm, twice end to end, a bulkhead doorway at each end | none | `map_mods_e.py` |
| `floodgate` | 512 | Valve's sluice gate in a headwall across the canal: hold its valve wheel to slide the leaves open; let go and they slam shut | `lc_floodgate_1_alarm`, `lc_floodgate_1_alarm_timer`, `lc_floodgate_1_beacon`, `lc_floodgate_1_clang`, `lc_floodgate_1_latch`, `lc_floodgate_1_leaf_a`, `lc_floodgate_1_leaf_b`, `lc_floodgate_1_move`, `lc_floodgate_1_wheel` | `map_mods_e.py` |
| `lockgate` | 2048 | Valve's lock gates across the wide canal: toggled open and shut, a klaxon, a control booth, a passage round | `lc_lockgate_beacon`, `lc_lockgate_close`, `lc_lockgate_closed`, `lc_lockgate_klaxon`, `lc_lockgate_leaf_a`, `lc_lockgate_leaf_b`, `lc_lockgate_open`, `lc_lockgate_opened`, `lc_lockgate_portal`, `lc_lockgate_state`, `lc_lockgate_switch`, `lc_lockgate_switch_light`, `lc_lockgate_switch_model`, `lc_lockgate_toggle` | `map_mods_e.py` |
| `roadend` | 1088 | the west road's end: a platform at the road's height, stairs down, and a side gate on (the ring's north half ends here) | none | `map_mods_f.py` |
| `hq` | 768 | the Resistance leader's office: a briefing room and an office behind it (the game puts the flagpole at its door) | `lc_hq_desk`, `lc_hq_map`, `lc_hq_table` | `map_town.py` |
| `flats` | 768 | a house to live in: a front door that opens, a hall, and two flats of a kitchen and a bedroom each (stove, sink, fridge, table, bed) | `lc_flat_1`, `lc_flat_2`, `lc_flat_door` | `map_town.py` |
| `straight` | 1024 | plain canal ("straight 1536", "straight 1024 bridge") | none | `map_modules.py` |
| `jog` | 1024 | the canal steps sideways to break a long view ("jog left 768", "jog right 1024") | none | `map_modules.py` |
| `tee` | 512 | a standard gate in the left wall, for another piece or layout to join | none | `map_modules.py` |
| `tunnel` | 1024 | the canal under the city: a covered stretch of any length ("tunnel 1536") | none | `map_mods_d.py` |
| `shed` | 2112 | plain canal with a train's shed on the street beside it (two to a straight run; needs "upper left") | none | `map_modules.py` |
| `widen` | 768 | the canal widens from 512 to 1024 in two steps (its next module must be a wide one) | none | `map_mods_e.py` |
| `narrow` | 768 | the wide canal narrows back to 512 in two steps | none | `map_mods_e.py` |
| `wide` | 1024 | the wide canal: 1024 between upright walls, any length ("wide 2048"), a walk along a wall from 2048 | none | `map_mods_e.py` |
| `widetee` | 512 | a standard gate in the wide canal's left wall, for another piece or layout to join | none | `map_mods_e.py` |
| `basin` | 2048 | the canal widens into a 1024 basin and narrows again (512 at both ends; "basin 2560") | none | `map_mods_e.py` |

## Each module, in its own words

### `drain`

1. The storm drain junction: a way from the canal down into the city's sewers. In the left wall a drain's mouth
with a concrete collar and an arched roof, caged lamps along its wall; a junction chamber round a sump of standing
water behind the city's handrail (steps down into it at one corner, a lost case at its bottom), two inflow pipes
(concrete pipes out of the side walls, water running from them into the sump), a standing valve, a run of the
city's pipes along each side wall, a lamp each end; then thirteen steps down to the sewers' height (z 288), a lamp
at their foot, a grate (the canals' own bar panels, four of them), and beyond it the start of the owner's sewer: a
channel of dark water between two walks under a round arch, to a cap to delete where the owner joins it to a sewer
of theirs (their sewers: water about z 267 to 291 in a channel, walks either side, round-arched mouths).
Grime: drain stains under the inflow pipes, stains down the walls, trash in the corners, a number by the valve, and
the lambda by the head of the stair (the Resistance's way down, as Half-Life 2 marks its routes).
Along the right wall a walk (walk_ledge: 72 wide, 208 up, the city's handrail on it, stairs at its near end, its
far end railed), the bank stopping either side of it in slopes: the drain's keepers' way along the canal.
Under a street along its bank (the canal ring) the chamber's roof is the street's deck, at 640, and the lamps' rods
are 16 shorter, so none comes up through the road.
Named for the game: lc_drain_wheel (the valve wheel beside the grate, a momentary_rot_button: hold it and the grate
lifts, let go and it drops), lc_drain_grate (a func_movelinear: SetPosition 0 shut to 1 open; unseen, the four bar panels riding
on it), lc_drain_junction (the chamber), lc_drain_cache (the case at the bottom of the sump: a place the game can
fill).
Left as brushes: the mouth, its collar and arch, the chamber, the sump and its steps, the plugs that darken the
inflow pipes' insides, the stair, the sewer channel's walks and arch, the sewer end's cap.
Unchecked: ambient/water/water_flow_loop1.wav, ambient/water/drip_loop1.wav; the water running from the pipes is an
env_steam aimed down and out (as the owner's map aims its jets: Half-Life 2 has no falling-water material), how it
reads is not seen; that the concrete pipe is open at both ends (a dark plug closes its back, against the wall).

### `shanty`

4. The shantytown under a street bridge. The canal widens into a basin on its left; a boardwalk runs along the
basin's back, with three shacks on it (map_mods_c.shack: a sheet of wood, tin or steel hull a wall, a tin roof sloping to
the front, one with a window of cracked glass): a card room (a table, two chairs, a radio on the table, the
canals' own map on the back wall, a lantern), a trader's stall open at the front (a long table for its counter,
shelves on its back wall with jars and cans, a painted board over it, a cart and crates outside) and a bunk room
(two bed frames, mattresses on them, a crate with a lantern between them). Under the street between them, a fire drum
with seats round it and a stove with its chimney pipe. A plank fence against the wind at the basin's edge east of the
street; a string of bulbs on a cable from an old dock pole to the bridge's deck and on to a second pole; washing on a
line from the card room's roof post to a pole; a boat pulled up; a cork notice board on two poles; posters on and in
the card room, the lambda on the bridge's pier, trash and puddles on the basin's floor. In front of the card room the
basin's floor is left clear for the Resistance's flag; east of the bridge three ridge tents stand on the basin's
floor (the camp's, folded in on 24 November: lc_shanty_tent_1 to _5, where someone sleeps). Where the chain's street runs along the bank the bridge starts
from (the canal ring, 23 November) the bridge is the street's way in: the street's parapet opens there, and an iron
ladder comes down the bridge's side (a gap in its side wall, a post under its edge) to the boardwalk by the card room.
Named for the game (places only): lc_shanty_cards (the card room's table), lc_shanty_fund (the stall, for the fund's
screen), lc_shanty_soup (under the street, for the soup), lc_shanty_fire (the drum), lc_shanty_board (the notices),
lc_hq_setup_shanty (where the game stands the Resistance's flagpole when a territory covers the shanty town: the
basin's open floor, 64 clear all round, open to the sky), lc_zone_rebel_r780_h400_shanty (that territory, brought by
the map: 780 round the basin's middle, 400 high) and lc_base_vehicle_airboat_shanty (where the base's airboat lies,
on the canal's floor west of the bridge).
Left as brushes: the boardwalk, the shacks (sheets, posts, roofs: no model is a shack's wall), the board over the
stall, the washing on the line (no game has a model of clothes on a line), the street bridge.
Unchecked: ambient/fire/fire_small_loop2.wav, env_smokestack, the cables (move_rope), sprites/light_glow03.vmt;
where on prison_bedframe001b a mattress lies (the mattresses are loose: they fall onto the frames).

### `vort`

6. The vortigaunt culvert: a low side drain in the left wall with the city's pipe along its wall under the roof
(capped where it starts), turning twice (nobody in the canal can see or shoot into its end); a green glow leaks round
its first turn to draw people in; and a dead-end den: damp brick walls, broken through into earth and rock in its back corner; a ring of
stones round a fire with a pot in it, steam rising from it; three old mattresses for mats; shelves on its
wall with jars and a pot; bones and an antlion's shell by the rocks, firewood, a few candles; a seep of water in one
corner glowing faintly green (the vortessence pool: small green glows over it, a green beam on the wall behind).
Named for the game: lc_vort_fire, lc_vort_seat_1 to _3 (the mats, facing the fire), lc_vort_npc (where a
vortigaunt the game makes would stand, facing the fire).
Left as brushes: the culvert and the den and their linings, the hearth's slab, the candles (no model of one: a small
block each).
Unchecked: env_fire, env_steam rising, ambient/fire/fire_small_loop2.wav.

### `relay`

7. Cubbage's relay. A concrete quay against the right wall, 128 high and 256 deep (room to walk along the shack's
front: the owner, 22 November, had to noclip to its door), with a stone coping, three mooring cleats and an iron
ladder down its face, two tyres for fenders, steps the quay's full depth up its upstream end, their solid side flush
with the quay's face; and on it a radio
shack built from pieces (map_mods_c.shack: mismatched sheets, a tin roof on posts, a boarded window), netting thrown
over its roof against eyes above: inside, the set on a table under a desk lamp, its dials glowing, a receiver and a
logbook by it, a chair, a cot (a bed frame), a shelf of car batteries, the canals' map pinned on the back wall, a
poster beside it. Beside it the mast: one of the city's tall utility poles (utilitypole01a, about 230 over the
canal's walls) with two small dishes on it, an aerial on the shack's roof, guy wires to the quay and the wall, a red
lamp at its tip (shielded from above), a long-wire aerial from the tip across the canal to the far wall (beside a
street on the far bank, which has no wall top, downstream to its own wall) and the feed from the shack up to the
pole. A diesel generator (generatortrailer01) hums behind the shack under a lean-to, its
exhaust pipe up through the lean-to's roof; fuel drums beside it.
Named for the game: lc_relay_radio (the set, a prop_dynamic), lc_relay_hum (the generator's sound: StopSound),
lc_relay_lamp (the red lamp's glow: HideSprite, ShowSprite), lc_relay_mast (the mast's foot), lc_relay_seat.
Left as brushes: the quay, its coping and its steps, the shack, the lean-to, the netting over the roof.
Unchecked: models/props_lab/citizenradio.mdl, ambient/machines/diesel_engine_idle1.wav, the cables (move_rope);
where on the pole its cross arm is (the lamp and the wires are at its tip, the dishes on its shaft).

### `checkpoint`

8. The Combine checkpoint, in the Combine's own kit. People come at it from the module's entry (flip it to face
the other way): a chicane of concrete barriers and Combine barricades, a queue marked on the floor in hazard stripes,
then a Combine wall across the canal to z 720 (the owner's Combine metal, buttresses and a cap of the Citadel's
plate) with one gateway (192 wide, 160 high) shut by a force field between two of the Combine's fence posts
(combine_fence01b and 01a, 192 high, the owner's own field between them); a camera on the wall over the gateway, the
Combine's lights either side, Breen's poster and numbers on the wall's face. Behind the wall, on the left bank, a
guard's platform 128 high (the banks are its ramps) with one of the Combine's booths (combine_booth_short01a), a
console, a monitor and a health charger on the wall; stairs from it (their lowest steps open at the side, climbed
from the platform beside them) to a walk along the wall's top behind the Combine's railing, a parapet before it,
two Combine floodlights on its ends for the searchlights. Beside a street along the platform's bank (the canal ring,
23 November) the street's parapet opens where the stairs pass the street's height, so the Combine step off the
street onto them (up to the walk, down to the platform), and the two wall lights over the platform hang under the
street's edge. Under the walk on
the right bank, a chain link holding pen with a sliding gate, the police line on its wall.
Named for the game: lc_checkpoint_field (a func_brush: Disable opens it, Enable shuts it), lc_checkpoint_hum (its
sound: StopSound, PlaySound), lc_checkpoint_light and lc_checkpoint_light_b (the searchlights: LightOff, LightOn),
lc_checkpoint_pen (the pen's gate, a func_door: Open, Close; unseen, a panel of the pen's fence riding on it),
lc_checkpoint_pen_spot (where a prisoner stands), lc_checkpoint_post (the guard's place on the wall),
lc_checkpoint_queue (where people wait to be seen).
The health charger is a working item_healthcharger (it heals whoever uses it): delete it if the game's medics should
be the only healing.
Left as brushes: the wall, its buttresses and cap, the gateway's frame, the walk, its deck, brackets and parapet,
the stairs and their plate, the pen's mesh roof, the queue's stripes (dev_hazzardstripe01a, as the owner's map
paints its edges).
Unchecked: ambient/machines/combine_shield_loop3.wav, point_spotlight and light_spot keys; which way
combine_light001b, combinecamera001 and the booth face (their fronts taken as the models' +x).

### `ash`

10. The ash outfall (the owner: "just trash and burnt corpses"). High in the left wall, a chute's mouth: a real
hole under a concrete hood, barred with one of the canals' bar panels, black behind, with a steel tray, soot down the
wall under it, a danger sign and a number beside it. Under it a heap of ash and rubble 110 high (its own ground,
Half-Life 2's rubble-and-ash blend: grey ash on its top, rubble at its foot) with the burnt dead lying on it, scorch
marks, thin smoke rising; a second, smaller heap; garbage, bags and tyres; a wheelbarrow left on its side. Now and
then (every three to ten minutes) the chute's grate swings open with a burst of grey dust and a clatter, and shuts
again: everyone in the canal knows where the Combine's dead go. Flies.
Named for the game: lc_ash_heap (the top of the heap: a place to sift through), lc_ash_grate (the chute's grate, a
func_door_rotating: Open, Close; unseen, the bar panel riding on it), lc_ash_timer (the logic_timer that tips it:
Disable, Enable), lc_ash_dust (the dust: SpawnDust), lc_ash_tip (a relay: Trigger tips the grate once).
Left as brushes: the chute's mouth, its hood and its tray.
Unchecked: the garbage pile and garbage bag models, models/humans/charple01..04.mdl, metalbucket01a, env_smokestack,
env_dustpuff, ambient/creatures/flies1.wav, physics/concrete/rock_impact_hard1.wav; the heap is nature/gravelfloor002a (blendrubbleash001a is not in the owner's Garry's Mod: their compile, 22 November)
(which of its two textures shows at alpha 0); which way the grate swings (spawnflags 64 or 128: about the chute's top
edge); the wheelbarrow is loose and turned on its side (roll 85): it settles as it falls.

### `sludge`

11. The sludge tunnel. The canal goes the long way round a block (out to the left and back, about 3,800, under a
street, past a dumped container and a car that went over the edge, a Combine camera watching it), and a low tunnel
768 long cuts straight through, ankle deep in toxic runoff. The tunnel has a shape: its roof chamfered along both
sides, ribs every 128, a ledge along its left wall, broken in two places so the slime must be waded. Slime pours
from three of its five outfalls (the city's pipes out of the walls at the slime's face) with a gurgle; drums stand
tilted in it, a pallet floats, scum bubbles. The light is the slime's: green from low over it, small green glows on
it, the roof dark between a caged lamp inside each mouth. At both mouths the warning shown, not told: danger signs, a
chain slung across, and at one a body that did not make it.
Named for the game: lc_sludge_gas (a trigger filling the tunnel's air: a place for gas masks), lc_sludge_haze (the
green haze in it, a func_dustcloud: TurnOff, TurnOn).
Left as brushes: the tunnel, its chamfers, ribs and ledge, the beams over its mouths, the slime plugs in the pipes,
the street bridge.
Unchecked: nature/toxicslime002a, func_dustcloud and its keys, ambient/levels/canals/toxic_slime_loop1.wav,
ambient/levels/canals/toxic_slime_gurgle2.wav, the slime pouring (an env_steam aimed down and out), the chains'
material (cable/chain.vmt); that loose planks and pallets float on the slime (they do on water).

### `cistern`

12. The cistern, for the hive boss (blind, hunts by sound). Off the RIGHT wall, a tall passage with a stair in
it leads to a round settling tank 1536 across, ankle deep in water. Its wall is truly round (36 straight segments on
the squares' line, damp concrete below a water line, the squares behind only seal); a stone kerb rings the water.
Two levels: a dry ledge round the tank at the canal's height (iron grating in places, which rings underfoot) with
four plank walks out to an island in the middle, and over the ledge a gallery, a smooth ring of slab 128 up behind
the city's handrail, reached by the stair (a steel plate along its open side) and by two ladders from the ledge.
Four pillars with numbers on them and caged lamps (two lit, two long dead), three inflow pipes high in the wall
(concrete pipes, dark inside), one still pouring into the tank; chains slung from the shaft's grate down to the
island; the island lies under a grated shaft open to the sky, so it stands in daylight (a beam straight down, dust
hanging in it) while the rest is dim. A plank, a drum and a body float in the water; buckets, cans and bottles lie
about the ledge and the gallery, things to throw for a blind thing to chase.
Wading is in the water (the game can tell: a player's water level), down two steps off the kerb beside each walk and
back up them; the ledge, the planks (each laid over the kerb onto the ledge at its end) and the gallery are dry.
Named for the game: lc_hive_boss_spot (the island), lc_cistern_gallery (the head of the stair).
Left as brushes: the tank, its round wall and kerb, its gallery's ring, the landing and the stair and its plate, the
plank walks and their posts (decks on piers), the boards over the kerb, the steps into the water, the shaft's grate,
the pillars, the plugs that darken the inflow pipes.
Unchecked: ambient/water/water_flow_loop1.wav, the chains (cable/chain.vmt on ropes), the water pouring (an env_steam
aimed down and in), func_dustmotes in daylight.

### `underpass`

13. The barnacle underpass: 1024 of canal under a wide road bridge (a deck on piers under the open sky, a parapet along each edge), dark under it. Three piers stand down its middle, chamfered
(as City 18's columns are) under wider caps, and a concrete girder crosses the canal on each, the road's deck resting
on them; the road's drains come down the piers in gutter pipes, puddles under them. Six barnacles hang from the deck
between them, and under each Half-Life 2's tell: bones and a stain on the floor, two of the dead lying where they
were dropped. Part of the deck has come in by the right wall: daylight straight down a shaft (dust hanging in it,
now and then more dust and grit falling off the broken edge), a fallen slab with its bars sticking out, rubble, a
street sign and its pole come down with it. A lorry jammed against a pier, its load of crates spilled behind it, a
car, cables hanging, five of the dead in all, one beside a lantern (the city's oil lamp, lamp001a) that still
burns. Graffiti on the piers, a danger sign by the hole.
Named for the game: lc_underpass_body_1 to _5 (where each body lies: things to search), lc_underpass_dust (the dust
off the broken edge: SpawnDust; a logic_timer, lc_underpass_dust_timer, works it).
Left as brushes: the road's deck and parapets, the barred gateway's frame, the piers, their caps and the girders, the fallen slab.
Unchecked: npc_barnacle (and whether the game minds NPCs it did not make), models/humans/corpse1.mdl and
charple01, charple03, ambient/atmosphere/tunnel1.wav, env_dustpuff, the cables (move_rope); the rebar is laid on its
side (pitch 90), centred on its origin; the sign and its pole are loose, laid on their sides, and settle.

### `tram`

The fallen tram bridge. A tram line crossed the canal here, 88 over its floor; its bridge is gone but for a stub
of deck at each wall, one whole girder on a pier and one that sags. In each wall a station opens: a mouth 256 wide
and 296 high (the cars are 151 and 163 across and 208 high, 260 over the track on their bogies), then a hall with a
platform 64 high either side of a track pit 176 wide, and at its back the line going on into a tunnel 256 wide and
320 high that ends in the dark (both stations: the track visibly goes somewhere each way). The halls are dressed in
Half-Life 2's own station kit as Valve builds it: its cast iron columns (trainstation_column001) standing their full
256 on the platforms, its arches at their heads (column_arch001a between them, ceiling_arch001a to the walls),
a girder across the hall over each pair, a plaster ceiling 288 over the platforms, walls in two tones as the city's
station (brick to the shoulder, a rail, plaster over it), and its wall lamps (light_128wallmounted001a) set as Valve
sets them in d1_trainstation_02: the arm's foot against the wall, reaching 132 out over the platform, its origin 64
off the wall and 216 over the floor, each with a light and a beam down; indoor benches, a bin, a payphone, route
signs and the city's notices; the station clocks stand 2 off their walls (no face shares a plane with the wall).
From each platform's end a flight of steps goes down beside the track into the tunnel, so a player crosses from one
platform to the other at the tunnel's mouth, never in a car's way. Episode Two's opening train car, crushed
(wrecked_train_02), has come off the bridge: it lies across the canal from the right bank's foot, where its open
front end is on the floor, up over the left mouth's lip into the left station, about 12 degrees, leaning 4 to one
side, clear of both platforms' edges; two of its seats and a suitcase spilled out of its open end. Walk in at its
open end and up through it into the left station. The overhead wire still hangs from it, snapped, its live end
spitting sparks on the canal floor. The line's own service stair climbs the left wall from the canal floor to the
left stub (a second way up that does not depend on the car's insides). The left station has a ticket booth with a
barred window and, at the back beside the tunnel, a stair up to the street behind a prison's sliding gate with a
danger sign over it, black beyond (lc_tram_exit); a signal on the far platform at the tunnel's mouth, its lamp toward
the tunnel and its arm over the track. The right station is reached only along the whole girder, a beam 16 wide and
368 long, 88 over the floor (steps at its end climb from the deck to the platform): the twin car (wrecked_train)
stands at its platform on two bogies with a cache in it (lc_tram_stash), and somebody has been living on that
platform (a mattress, a fire in a drum, a lambda on the wall). Dropping from either stub is safe.
Where a street runs along one bank (the ring's outside bank, z 656 over everything 768 out from it), no station can
stand under it (its rooms' roofs must be 720 or lower, and a car needs 288): the module turns itself so the left
station (the wreck's end, the booth, the barred stair, the service stair) is on the other bank, and on the street's
bank the line's portal is bricked up under the street, its arch and rails still showing; the camp moves to the far
platform and the cache (lc_tram_stash) into the ticket booth. Sounds: the
station's own soundscape in each hall (d1_trainstation.Turnstyle, which the owner's map uses), the metal groaning
over the wreck (coast.util_metalstress).
Named for the game: lc_tram_exit (an info_target on the left platform before the barred stair: where people come
from or go to the street), lc_tram_stash (an info_target inside the car in the right station: a cache).
Left as brushes: the stations' walls, platforms, steps, tiles and girders (architecture), the bridge's deck, girders
and pier (a building's frame), the rails (no single track narrower than 288 exists as a model), the booth's walls.
The two crates inside the right car are meant to be there (the cache): the build's LOOK lines naming them are
expected.
Unchecked: the cars are Episode Two's (players without it see errors; the owner asked for them); that the cars' own
collision lets a player walk inside them, where their doors are and that the wreck's floor walks well at 12
degrees; how high the car's floor is inside (the platform is 12 over its underside); which way the signal, the
benches and the payphone face (set by their boxes and Valve's own placings); which end of ceiling_arch001a meets the
wall (both stations alike: its +y end to the wall).

### `quay`

The quay: a way up to the streets. Stairs 64 wide climb along the left wall from the canal floor (u 64) to a
landing at the trim's height (u 448 to 512), with the city's own stair rail on the canal's side; their open side is
made solid from the floor to a parapet over the flight, so from the canal it reads as one stair built against the
wall. The landing opens onto a quay recessed into the left wall, 640 by 256 and open to the sky: a low wall along
its edge, two of the city's street lamps at the edge with their arms over the quay, mooring cleats with a boat roped
below, tyres hung down the quay wall as fenders on short ropes, an iron ladder from the canal floor up through a gap
in the edge wall (a second way up), three posts before the street doorway, a skip, a bench, a payphone, crates. At
the back a street doorway 128 wide and 128 high stands in a concrete frame, a route sign over it, the city's notices
beside it and a Combine camera on the wall watching who comes down; it is closed 64 in by a cap of the world in its
own visgroup ("the quay's street end (delete to join a street)"). From the quay the swing bridge (map_mods_c.swing_bridge:
it was a module of its own until 26 November, and a fixed footbridge stood here) crosses to a landing in the right
wall: it turns on a round pier in the middle of the canal, a button on a post at the quay's edge and one over the
winch on the landing turn it (a bell, then a quarter turn: along the canal it joins nothing), green and red lamps
and a barrier arm at each end. In the landing's back wall a barred door of Nova Prospekt's: a button on the
landing's end wall beside it slides the bars aside into the wall and back (Toggle, with the grate's own scrape and
clunk); behind them a short passage to the city's store for the quay (the Combine's supply crates on shelves, a lamp left on), seen
through the bars while they are shut. Beside the chain's street (the canal ring) the quay is the street's own edge:
no doorway, frame, back wall or camera (the railway runs over its back half), its furniture on the far pavement,
lc_quay_street there too, and the street's parapet is its edge wall, open at the landing, the ladder and the
bridge, so the stairs, the ladder and the bridge to the store all meet the street.
Sounds: the quiet courtyard up on the quay, the watery hallway down in the canal (both the owner's map's own).
Named for the game: lc_quay_street (an info_target in the street doorway, facing the quay: where people arrive
from the street), lc_quay_far_door (an info_target on the bridge before the barred door), lc_quay_store_door (the
barred door: a func_door, unseen, wearing the cell door's model; Open, Close, Toggle), lc_quay_store_button (the
button beside it, Episode Two's button model, that toggles it); and the bridge's: lc_swing_bridge (Toggle, or Open:
along the canal; Close: across), lc_swing_wheel_a and _b (its buttons: the quay's, the landing's), lc_swing_lamp_a/_b
and lc_swing_red_a/_b (the lamps), lc_swing_arm_a/_b (the barrier arms), lc_swing_move, lc_swing_stop, lc_swing_bell.
Left as brushes: the stairs and their solid side, the landing, the quay's low wall, the doorway's frame, the
store's walls, the bridge (deck, beams, truss, counterweight), its pier and drum, the landing's lip.
Unchecked: that handrail04_doublerise rises toward its own +y end (if the stair rail falls the wrong way, turn
both by 180) and where its posts meet the steps (they were made for steps of 8 and 12, these are 16 and 24); how
the boat, bench, payphone and camera models face; that the hung tyres (turned up on edge) lie flat to the wall;
the doorway's frame stands 24 above the walls' tops when the rim is at its lowest (784), which may look odd from
the street.

### `collapse`

The cave-in. The left street's retaining wall and a length of roadway have come down across the canal (the wall
is bitten out to a ledge of earth at z 528, open to the sky). From the bite to v 32 two great slabs lean on each
other like a tent, its ridge at z 640; from v 32 a wedge of roadway slopes down to a standing piece of the wall at
v -160. Each slab is plainly a piece of the owner's street: cobbles on top (stonefloor006d_c17) with a sett gutter,
a kerb and a strip of pavement at its far end, raw concrete underneath with rebar standing out of every broken edge,
the broken ends rough; cracks and grit painted on them. Every face is steeper than a player can walk. Two ways
through: the squeeze: 96 wide between that standing piece and the right wall (v -256 to -160), open to the sky, no
bank; the crawl: a hole 40 wide (a beam props it) and 44 high at the foot of the near slab (v 72 to 112), torn at its
corner, into the hollow under the tent (192 by 96 of flat floor, room to stand, earth sloping up behind), and another
out through the far slab (v 40 to 88): the two holes do not line up, so nobody sees or shoots straight through. The
hollow is a hide (lc_collapse_hide): a slot 16 wide by the ridge lets one shaft of daylight in, dust hangs in it.
Each side also has a perch: the earth bank leads up to the end of the bite's ledge beside the slabs. What came down
with the street lies about: broken slabs of road, a bench, a cone, a car, rubble (all real models); the street's
cables still hang strung from the bite to the ridge. Sounds: metal and concrete settling (coast.util_metalstress),
the hollow a cave's quiet (d1_town.CaveTunnel), both the owner's map's own.
Named for the game: lc_collapse_hide (an info_target in the hollow under the slabs).
Left as brushes: the great slabs, the wedge and the standing piece of wall (the fallen street itself, too big for
any model), the kerb, gutter and pavement on them, the prop beam.
Unchecked: how far each rebar model sticks out of its slab (set by their boxes); that players cannot scramble up
the slabs (they lean at 63 and 51 degrees; the game's limit is about 45); that the leaning hole reads as a way in;
how the car and the bench lie; the func_dustmotes keys (from Half-Life 2's own entity, not read from the owner's
map); how the cobbles' texture lies on the slopes.

### `boathouse`

The smugglers' boathouse: a boat shed built into the left wall, its floor 64 over the canal's. A slipway of
concrete with two launching rails climbs from the canal floor through a cut in the bank to a roll-up door of the
owner's corrugated steel (metaldoor032c) 256 wide, a slot of daylight under it (lc_boathouse_door: a func_door that
lifts). The door is worked by a button inside, to the right of it, and by one outside on the canal wall, on the far
side of a drain pipe so that nobody coming along the canal sees it (stand on the bank to reach it). Inside, under a
pitched tin roof on four timber trusses with a ridge beam: a boat on two crates on the rails' line, the canal's own
winch behind it with its cable on the bow, a chain hoist (the game's pulley hook on its cable) hanging from the ridge
over the slip, a workbench of two tables with an outboard engine on it and the tools on a board over it, shelves,
fuel drums, bare bulbs on their cables under the tie beams. In the floor at the back a steel hatch
(lc_boathouse_hatch: a func_door that slides aside, worked by the button over the workbench) covers steps down to a
cellar 192 square of damp brick where the contraband is kept: the Combine's own ammunition crates and a supply crate,
shelves, a radio (lc_boathouse_cellar). Sounds: the watery hallway in the shed, a dripping tunnel in the cellar.
Along the right wall a walk (walk_ledge: 72 wide, 208 up, the city's handrail on it, stairs at its near end, its
far end railed), the bank stopping either side of it in slopes: a lookout over the slipway.
Named for the game: lc_boathouse_door (func_door: Open, Close, Toggle), lc_boathouse_hatch (func_door, the same),
lc_boathouse_button_in, lc_boathouse_button_out, lc_boathouse_hatch_button (func_buttons that already work in the
map), lc_boathouse_cellar (an info_target in the cellar: the cache).
Left as brushes: the roll-up door and the hatch (plates the game moves; no roll-up door or floor hatch exists as a
model), the door's guides and roller housing, the slipway and its rails, the roof, its trusses and the tool board.
Unchecked: which way the winch, the engine and the ammunition crates face; how the corrugated door's ribs lie (the
owner's own way of laying it is the default one); the buttons' model is Episode Two's (the shared button helper's
choice); that the outside button can be pressed past the pipe; that the hatch, sliding from under someone, lets them
down the steps cleanly; that the tools hung on the board (rolled 90) lie flat to it.

### `crypt`

The crypt. The canal's left wall has broken through into the crypt of a church that is no longer there: a
ragged hole 128 wide at the top of the bank (the bank is the way up), torn rather than cut (teeth of brick and stone
round it), broken slabs round it and rubble down the bank under it; from the canal it is a dark mouth with
candlelight deep inside. Then a vaulted room 512 square under a roof 112 high, its floor of old stone 128 over the
canal's. Four squat pillars carry arches both ways. In each side wall two burial niches hold a stone coffin under
one of the graveyard's carved lids; one lid is ajar, bones lie in a niche. In the middle of the nave stands a tomb
that has been opened, its lid leaning against it, a skull in it and bones spilled beside it. At the back Lost
Coast's monastery altar on a step, two of its tall candlesticks, a cross cut in the wall behind it (lc_crypt_altar),
and to its right the old stair up into the church, its bricks broken through: a tunnel under the churchyard runs on
to the church's basement, and Ravenholm's church stands behind (map_mods_f.church). Stone
plaques on the walls. It is lit by people, not by fittings: candles here and there (a cluster on the altar, one in
a niche, one on a pillar's base, a few by the tomb, one on the stair; the other pillars dark), dust hanging in their
light, a little day at the hole. The Resistance uses it: a radio on the altar, a mattress for the wounded, the lambda
on the wall. Water from the canal stains the wall by the hole and stands on the floor. It drips
(prison.general_dripping_tunnel). Quiet and old: a place to hide, to meet, or to be buried.
Named for the game: lc_crypt_altar (an info_target before the altar).
Left as brushes: the crypt, pillars, vault, niches, the coffins' carved bases, the altar's step, the cross cut in
the wall, the plaques, the broken slabs and teeth round the hole, the candle stubs (no model of one
exists).
Unchecked: the bones (models/gibs) as prop_dynamics; which way the altar faces; the look of stone/stonefloor006d_c17
and stone/stonewall040f; whether the candles' small lights are enough to see by; the func_dustmotes keys.

### `barge`

The grounded barge. A river barge lies on the canal floor from u 320 to 960, askew (its stern 80 nearer the left
bank than its bow: sheared in plan, never turned): a steel hull 640 long, 192 wide and 96 high, its sides flaring,
its bow and stern raked and tapered (no ship model fits a canal: the hull stays brushes). Its face is a vessel's: a
timber rub rail along the sheer, a band of a second plate at the old waterline, rust streaking down from the
scuppers, its name painted on the bow (the owner's own ship's sign decal), the anchor's chain run out ahead into the
mud, tyres hung down both sides for fenders, mud heaped against its sides where it grounded. Forward a wooden pole
of the docks for a mast with a caged lamp on it, the canal's own winch, cleats; amidships the hold under four hatch
covers, the second slid back onto the third: a ladder goes down through the gap. The hold (336 by 128, 88 high) is
somebody's hideout, its floor clear down the middle: two beds forward, a stove with its pipe (the city's pipe pieces)
up through the deck and a thin smoke from it, a table and chairs to one side, a lamp, a crate (lc_barge_hold). Aft a
wheelhouse with windows all round, a doorway astern, an instrument console with a radio under the front windows and
a wooden spoked wheel on its pedestal (lc_barge_wheel). A gangplank runs level from the left bank to the deck. The
canal stays passable either side of the hull: a strip of floor and the bank. Sounds: the hull's metal groaning
(coast.util_metalstress), the hold a wooden room's creak (d1_town.WoodBuilding).
Named for the game: lc_barge_hold (an info_target in the hold), lc_barge_wheel (an info_target at the wheel).
Left as brushes: the hull, its rub rail and waterline band, decks, bulwarks, hatch coaming and covers, the
wheelhouse, its console and pedestal, the funnel, the mast's yard, the gangplank (the vessel itself), the mud heaped
against it.
Unchecked: that props_wasteland/wheel01 (a cart's wheel: Half-Life 2 has no ship's wheel) reads as a ship's; which
way the winch and the radio face; the ladder standing free in the hatch (the shared helper's models and dismount
points); that walls sheared in plan do not snag a player walking the side decks (40 wide); the colour of the
waterline band (metal/metalwall030a, one of the owner's commonest metals, chosen unseen); that the hung tyres lie
flat to the flaring sides. Not done: a list to one side (a roll sheared into every brush would not keep their faces
on the grid).

### `shell`

The shell. A headcrab canister has come down in the canal: the game's own (headcrabcannister01b, shown
opened, as the game leaves one that has landed) stands out of the right bank where it struck, nose buried, leaning
back the way it came at about 55 degrees, in a crater: a ring of mud raised on the floor, rocks thrown up on the
bank, the bank scorched and littered round it. Steam vents from its open end, it spits a spark now and then, a small
fire burns on the bank, a thread of smoke rises from the crater and the trail it came down on drifts off in the sky
the way it came. The wall above it is cracked from the bank to the trim (painted cracks, the owner's own plaster
decals) and a piece of its face lies on the bank. Round it the beginnings of an infestation: seven low fleshy mounds
(one func_brush tinted dark red, lc_shell_growth, so the game can take them away), torn flesh on them and a sick
yellow glow that swells slowly over three (a sprite, no light), a faint sick-green light that does not flicker. What
came out of it lies dead: two headcrabs, a zombie's torso, and the people it got (three bodies, blood). The Combine
came, lost a Civil Protection officer (lying by the far end), and shut the canal: two of their short barricades and
a police line across it at the far end, a danger sign on the wall. It sounds of slime (canals_slime_tunnel). No
living creatures: the game brings its own (the four patches).
Named for the game: lc_shell_canister (an info_target at the shell's open end), lc_shell_patch_1 to _4
(info_targets on the floor round it, where the game may put infestation patches and headcrabs), lc_shell_growth
(a func_brush: the mounds; Disable removes them).
Left as brushes: the growth mounds (no model of flesh exists in the games; the game takes them away by name), the
piece of the wall's face on the bank.
Unchecked: that the canister shows opened with DefaultAnim idle_open and which end is its nose (taken to be +x,
where its trail is not); that a func_brush takes the dark red tint (rendercolor) on plaster and the flesh decals on
it; models/humans/corpse1, headcrabclassic, zombie/classic_torso and police as ragdolls lying where put; how high
the mud ring comes out (it is the mud's displaced skin, raised up to 34); the env_steam and the drifting
env_smokestack's keys (Half-Life 2's own entities, not read from the owner's map); that the slow pulse of the
growth's glow (renderfx 1) is not taken for a flicker.

### `aqueduct`

The aqueduct. A smaller channel crosses OVER the canal at the trim's height: a concrete trough 112 wide on two
piers, ribbed under its belly, pilasters down its far side every 64, a coping of the city's trim stone along both
rims, from a culvert mouth in the left wall to one in the right, each shut by the canal's own bars: behind the bars a
lit stretch of culvert, the trough's water flowing on into it, dark where it goes on. 24 of standing water in it.
Along its entry side runs a maintenance walk 48 wide (the trough's rim and a grating on brackets) with the city's
handrail on its outer edge: a ladder climbs the left pier's buttress to it (256 up), and from it the whole canal can
be watched, or crossed up high from bank to bank (the walk ends at each wall; the way down is the ladder or a drop to
a bank). It is lit from below: a caged lamp on each pier and a lamp washing each side of the trough. At mid-span the
trough is cracked (painted cracks): its water stains and greens its sides, falls in a thin stream onto the canal
floor, and lies there in a shallow pool in a ring of mud, with a dripping sound. A sluice valve stands on the trough's
rim by the left wall. It sounds of water (prison.watery_hallway).
The sluice valve (the owner, 21 November: "sure"; a wheel as Valve's are, the owner said go ahead): a wheel on the
left wall beside the walk (on the right wall where the chain's street runs along the left bank: there the walk
meets the street, the street's parapet open over it and the trough's end, and no wall stands over it)
(lc_aqueduct_valve, a momentary_rot_button: hold E to turn it) drains the trough and the
culverts' water (lc_aqueduct_water sinks) and lifts both culverts' bars into the wall (lc_aqueduct_bars) as far as
it is turned; turned all the way it locks with a clunk for the round, stops the fall and the drip and turns the
bars' clip off (lc_aqueduct_bars_clip): the dry trough is then a way across into either culvert.
Named for the game: lc_aqueduct_walk (an info_target on the walk at mid-span: a lookout's place), lc_aqueduct_valve,
lc_aqueduct_water, lc_aqueduct_fall, lc_aqueduct_drip, lc_aqueduct_bars, lc_aqueduct_bars_clip.
Left as brushes: the trough, its piers, ribs, pilasters, coping and buttress, the culverts' frames, the grating and
its brackets.
Unchecked: which way canal_bars004 faces; the sound ambient/water/drip_loop1.wav (if it is not there, the place is
silent); water standing in a trough of detail brushes; the pool, a sheet of water 5 deep lying on the floor; the
ladder against a buttress; that a thin env_steam pointed down reads as falling water (Half-Life 2 has no falling
water material); the culverts beyond the bars are short (192) and end dark: where they lead is still to come.

### `camp`

The camp. The canal widens to the left onto a broad terrace of beaten earth 128 over the floor (896 by 448, open
to the sky; the bank along its whole edge is the way up). People who have nowhere else live here, making do: three
ridge tents (brushes: no tent model exists), no two the same size, patched from tar paper, carpet and sheeting, each
with a mat inside, a back pole and guy ropes to pegs; a shelter of pallets stood on edge under a tarp; a lean-to of
sheeting against the back wall, open in front on two poles; a car's wreck with a tarp run off its side and a
mattress under it. A lantern (the city's oil lamp) burns low by each. Their open ends (crouch to go in) turn to a
cooking fire in the middle: a ring of the game's stones, a pot hung from a tripod, embers that glow and do not
flicker, a thread of smoke, two benches carried off from a station and two flat rocks to sit on round it. A washing
line on two poles with what they own on it and a laundry basket under it, a water barrel under a gutter pipe down the
back wall and buckets, a pushcart, a cork notice board on a pole where the bank comes up, a few crates, a chair and a
couch, a child's doll; chalk scrawls low on the back wall, a Breen poster high over them all, and a Combine camera
on the opposite rim watching (where a street runs along that bank, on its wall just under the street's edge).
Quiet, poor, lived in (d1_trainstation.QuietCourtyard).
Named for the game: lc_camp_fire (an info_target at the fire), lc_camp_tent_1 to lc_camp_tent_6 (an info_target
on the floor inside each shelter: where someone sleeps; 2 is the pallet shelter, 3 the lean-to, 4 the car).
Left as brushes: the tents, the lean-to and the tarps, their poles and pegs, the tripod's three bars, the embers, the
washing (no model of cloth hung to dry).
Unchecked: which face of the cork board is its front and which way the camera looks; how props/tarpaperroof002a,
props/carpetfloor003a and props/carpetfloor006a look as tent cloth (no canvas is in the game's own materials); that
thin sheared sides 3 thick stop a player cleanly; that the washing line's rope hangs where its cloths are (the rope
sags by itself); that the pallets stood on edge (pitched 90) stand as worked out.

### `cells`

The cells: where the Resistance keeps captured Combine units, in an old cellar done up as City 18 does its
rooms: brick to the dado line, plaster above it, a stone rail between, a concrete floor and roof. A heavy steel
door at the foot of the left wall (lc_cells_entry: Use swings it in) opens on a guard room lit by a fluorescent
tube and a prison lamp: a table with a radio and a revolver, a chair set to watch the corridor, lockers, a bench,
a board with the padlocks on it, a shotgun on a rack, a Civil Protection helmet hung on the wall as a trophy, a
crate of what was taken off the prisoners. A corridor runs on past three cells, a lamp over each cell's door and
darker between, each cell 128 by 160 behind a wall with a barred window and a barred door (lc_cells_door_1 to _3)
that slides aside behind the wall when the button beside it on the corridor's pier is pressed (lc_cells_button_1
to _3, tally marks over each say which) or the game sends Open, Close or Toggle. Each cell has a toilet, a bucket
and a drain in the floor, a name or two scratched on the wall; the first a mattress on the floor, the middle one
an iron bed frame with the mattress on it and a pan of food on the floor (and the days scratched on its wall),
the far one a mattress and the way out. lc_cells_spot_1 to _3 are where a prisoner stands. The far cell has a
loose grate low in its side wall (lc_cells_grate: Use swings it; the game can Lock it), a few loose bricks and
grit trailing from it, onto a crawl duct 40 high that comes out at the canal's floor through a concrete pipe:
the way to break out, or in.
The doors are Nova Prospekt's models (prison_heavydoor001a, prison_celldoor001a) riding on unseen brush doors
of the same names and inputs as before; the windows are prison_cellwindow002a with an unseen wall in them.
Left as brushes: the grate (no model 62 by 38), the tally marks (paint, not things), the gun rack's board.
Unchecked: which way the door, window, bench and board models face (each is thin along its x, so its face looks
along x: turned here to look along v); the helmet (models/barneyhelmet.mdl) hanging on its nail; whether a
prisoner's Use can reach a button round the pier's corner; the doors' sounds (doors/doormove1.wav,
doors/gate_move1.wav).

### `memorial`

The wall of the dead: a shallow recess in the left wall, open to the sky, its floor one step above the canal's
(on a street, level with the pavement).
A stone wall stands against its back, covered in rows of small plaques of dark metal on pale stone backs, no two
quite the same size (the upper rows half empty: room for more), with a ledge at its foot where candle stubs burn
steadily among framed photographs turned this way and that, bottles, tins, pots, a child's doll and a shoe; a
tall candlestick at each end of it; names scratched on the recess's side walls where the plaques ran out, the
lambda once, small; posters; a line strung across, and a bench out in the canal facing it. lc_memorial_wall is
the middle of the wall, facing out: the game may one day list there the names of characters who died for good.
Lit by the candles alone: three small lights among them.
Left as brushes: the stone wall, its plaques and the candle stubs (Half-Life 2 has no plaque and no candle).
Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (a low wind); which way the picture frames
face; the candlesticks are Lost Coast's (lostcoast/props_monastery/candlestick). No flowers: there is no model.

### `pit`

The fighting pit: the canal opens on its left, through a mouth 512 wide, into an eight-sided arena under the
open sky. In its middle a ring sunk 64 into the floor, 384 across, floored with dirt, inside a cage of Nova
Prospekt's fence panels on a kerb; the one gate (lc_pit_gate, on the side toward the canal) swings open when the
button on the post beside it is pressed (lc_pit_gate_button) or the game tells it to (Open, Close), and steps go
down from it into the ring. lc_pit_corner_a and lc_pit_corner_b are the two corners the fighters start in (a stool
in each, a bucket by it, blood in the dirt). Three tiers of seats, 32 high each, concrete on brick risers, stand on
the three far sides, with stairs of 16 up the middle of each and the city's handrail along the fronts of the upper
two (the stairs left open); a caged lamp on the wall over each stair lights the crowd, and a painted cloth banner
hangs on each wall above the top tier; bottles and cans left on the tiers. By the mouth on the right the
bookmaker's table, chair, till and lamp under a chalk board of odds, betting slips trodden into the floor
(lc_pit_bookie: where he sits); on the left the corner men's bench, water drum and bucket. Two lamps hang over
the ring from a gantry (the owner asked for these, not street lamps).
The gate is Nova Prospekt's gate (interior_fence001g) in its own frame (interior_fence002e), riding on an unseen
brush door of the same name and inputs that swings it out (Use opens it too); an
unseen wall stands in the cage's line all round, so the cage holds whatever the panels' own shapes are.
Left as brushes: the tiers, kerb and posts for the buttons (concrete), the chalk board (no model of one), the
gantry and its lamps' rods, the banners (cloth: no model).
Unchecked: which way the fence panels face and whether their meshes meet at the corners; whether a press of the
gate's button can be made through the cage from inside; the button's model is Episode Two's.

### `garden`

The walled garden: where the Resistance grows food. A gap in the left wall, a fence of boards and an iron gate
(lc_garden_gate: Use swings it in), opens on a yard 640 by 448 under the open sky: in a canal 24 above its floor and
two steps up, on a street level with the pavement (the owner, of the playground: places sit at the pavement's
height). Its ground is grass, worn to earth along a path of flagstones set into it from the gate to the lean-to.
Six raised soil beds edged with timber, three on each side of the path (lc_garden_bed_1 to _6: on the beds, for a
farming job; 1 to 3 on the left going back, 4 to 6 on the right), ridged. lc_garden_plot_1 to _8 are the planting
spots for the game (melons, pumpkins): info_targets on the soil of the four beds that have no bean poles, two a
bed, each a little off the line and turned an odd way (the same every build). Over the first bed on each side
bean poles stand in pairs leaning together, tied to a cane along the top, as a crop is grown; a scarecrow in the
middle bed on the right. Ivy climbs the side walls. Against the back wall a tool lean-to (a desk with pots, jars
and a sack, a shovel, a bucket, a bell lamp), a cold frame (an old window on a timber box over seedlings), a
barrel under a gutter pipe in the left corner with a puddle by it, a compost heap behind boards in the right
corner; a push cart, a wheelbarrow and a crate of melons on the path.
The gate is props_c17/gate_door01a riding on an unseen brush door of the same name.
Left as brushes: the beds (timber and soil), the canes along the bean poles, the scarecrow (no model of one), the
lean-to, the cold frame, the fence's two rails.
Unchecked: which way the gate, the boards and the ivy face (ivy_01 is thin along its x: its back put to the
wall); how far the bean poles lean (roll 16: they should meet over the bed's middle); how the loose things lie
once the game drops them.

### `stash`

The stash: a secret arms room. From the canal there is only a run of rusted pipes on the left wall with a valve
wheel on the thick one (lc_stash_valve, Valve's wheel model: held with Use it turns a quarter; held again it turns back), and for the
observant a small lambda sprayed low behind the pipe. Turning it slides a section of the wall itself aside
(lc_stash_wall: 96 wide, 112 high, of the wall's own concrete, flush with it when shut, its sill at the top of the
bank, 128 up); it shuts again by itself after 12 seconds, and the button on the wall just inside (lc_stash_inside)
opens it from within. Behind: a short passage of raw concrete that turns twice, then the arms room (lc_stash_room:
its middle), a cellar of brick over a damp concrete plinth, the pipes it hides running along under its roof, lit
by two fluorescent tubes. Racks on two walls hold Half-Life 2's own guns (pulse rifles, shotguns, SMGs, a rocket
launcher, a crowbar, pistols; a peg or two empty: those are out); a steel workbench against the wall toward the
canal with a vice, tools, a parts bin and a crossbow on it, the canal map and a board of papers on the wall over
it; a planning table with papers, a radio, a desk lamp, a revolver and a mug, its chair pushed back; two of the
Combine's ammunition crates and wooden crates along the far wall (the SMG one a real crate, opened for rounds);
boxes of rounds on a shelf.
Left as brushes: the racks (Half-Life 2 has no gun rack: a board, rails and pegs), the valve's wheel (it turns).
Unchecked: func_rot_button (the valve wheel) is from memory, with its turning axis set by spawnflag 64 or 128 (the
map's x or y, whichever way the module is turned): if the wheel turns the wrong way round or not at all, the door
still needs only one Open sent to lc_stash_wall. The door slides a little inward as well as aside (its movedir is
2 degrees off the wall's line) so that, open, it does not lie in the wall's own face. Sounds doors/doormove1.wav and
doormove2.wav are the bunker doors' own. Which way the weapon models' muzzles point on the racks (their length is
their x), which side of the ammunition crates is their front, and whether the canal map (props_canal/canalmap001)
reads as a map on a wall.

### `market`

The black market: a vaulted arcade inside the left wall, entered from the canal's floor by two archways, its
walls as City 18's vaulted halls are (brick to the dado, plaster above, a stone rail between), damp at the foot
and blackened over the fire. Five stalls in alcoves along its back, each with a steel kitchen counter across the
right half of its front (the left half is the way behind it), a shelf unit, a trade's goods on the counter (food,
the Combine's ration packs, parts and tools, medicine, radios), a dome light, and a roll shutter of the city's
corrugated door metal with a handle at its foot (lc_market_shutter_1 to _5: each lifts into its box and drops
when the button inside its own stall is pressed, lc_market_button_1 to _5, or when the game sends Open or
Close); the two that start down carry a padlock on the handle, and three boxes carry a painted sign.
lc_market_stall_1 to _5 are where the stallholders stand, facing out. A fire drum burns in the middle of the
arcade between two benches, its smoke gathering under the vault; a lookout's stool stands inside each archway,
where the canal can be watched both ways; ribs carry the vault at every pier.
Left as brushes: the shutters, their boxes and guide rails (Half-Life 2 has no roll shutter; they are the named
doors), the vault's ribs and the arches.
Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look (the same settings as the vortigaunt
culvert's fire); func_door's "spawnpos" 1 (starts open) is from memory; which way the counters and small goods
face. The first, third and fifth shutters start up, the second and fourth down (to be seen both ways); a shut
stall is still got into by crouching under the shutter's foot: the shutter says closed, it does not lock.

### `press`

The pamphlet press: a short side tunnel off the left wall, shut by a wall with one of the city's doors in it
(lc_press_door, a prop_door_rotating: anyone opens it; the game may Lock it), bricked up across the tunnel with a
timber casing round the door. Behind is the printing room, brick to a timber dado rail and stained plaster above,
its corners dark: lit only by a work lamp hung low in front of the press and the lamp on the table. A hand press (a
bed on legs with the forme on it, a platen hanging from a screw between two cheeks, a long lever), lc_press_machine
on its bed; a chest of drawers for the type, a radio on it; three drying lines across the room hung with sheets;
boxes and bundles of paper on a pallet (lc_press_stack); a table with a lamp and papers; a board of proofs on the
wall; drums and cans of ink, ink spattered on the walls by the press; a runner's case by the door; a mattress.
Left as brushes: the hand press (Half-Life 2 has no printing press), the sheets on the lines (they hang; the
paper models lie flat).
Unchecked: how taut the drying lines hang; which way the drawers face.

### `still`

The still: a distillery in a cellar off the left wall. A short tunnel, then four steps down, walled on both
open sides, into a cellar 64 below the canal's floor: stone to the knee and brick above, sweating, two brick ribs
carrying its low vault, lit by the fire's glow and one bare bulb. Against its far side the still: a brick firebox
open at the front with a small steady fire in it, a boiler standing on it with its flue up through the vault
(blackened round it, scorched in front of the fire), a pipe across to the worm (a drum on a crate, capped, a
funnel into it) and a glass jug under it (lc_still_pot: in front of the firebox), a bucket of water by the fire.
Three mash barrels along the left wall, sacks of grain and boxes; kitchen shelves along the back wall with filled
bottles on top (lc_still_shelf: in front of them); a table with a pot, bottles and a jug; a stool; the tally
chalked on the wall and a warning painted by the fire.
Left as brushes: the firebox (brick) and its grate, the flue, the ribs.
Unchecked: the sound ambient/fire/fire_small_loop1.wav; env_fire's look and env_smokestack's (the framework's own
settings, made small and pale here); which way the boiler and the pipe pieces face; that the bare bulb
(props_interiors/lightbulb01a, a box 49 high) hangs from its top; Half-Life 2 has no wooden cask, so the barrels
are its blue plastic ones and an oil drum.

### `plaza`

The plaza: where people gather to listen. The canal (or the street) opens on its left, 1152 wide, onto a
terrace at its own height, and from the terrace five concrete rows of seats step DOWN and away, each 16 high and
48 deep (walked down anywhere, sat on anywhere), round half an eight-sided floor 512 across and 80 below the
street. At the back wall, facing the rows and the street beyond them, a timber stage 256 wide and 48 up, two steps
up at its front, a lectern at its edge (lc_plaza_rostrum: where the speaker stands, facing the street); behind the
speaker a cloth banner with the lambda hangs on the wall, a tin canopy on two posts over the stage, and above the
canopy the cluster of loudspeakers on the wall (speakercluster01a, the owner's choice: on the wall, turned to the
street); a caged lamp on the wall each side. Two spotlights on the side walls throw their beams on the speaker; the
rows stay in half light. A fire drum burns on each side of the floor; crates people sit on along the terrace, cans
left on the rows. lc_plaza_crowd is the middle of the third row, facing the stage.
(Turned round on 21 November at the owner's word: the top row used to be at the back.)
Left as brushes: the rows, the stage, its steps and canopy (timber staging), its lectern (no model of one), the
banner (cloth: no model).
Unchecked: env_fire's look in the drums; which way the loudspeakers face (turned to the street); the spotlights'
aim (yaw 15 and pitch 13 from the side walls toward the lectern).

### `playground`

The playground: Half-Life 2's own, copied from the courtyard by the train station (sdk_d1_trainstation_02.vmf,
the prefab valve_playground_a), each thing where Valve put it and turned as Valve turned it (vpg). A yard on the
left, open to the sky: in a canal a terrace 128 above its floor (the bank is the way up), on a street level with the
pavement. Valve's grass, and Valve's path through the middle of it, concrete between stone kerbs, coming in from the
pavement between the posts of Valve's low stone wall with its metal fence on top. On the right of the path: the
noughts and crosses post, its eight blocks turning on their rods; a bench turned toward the swings
(lc_playground_bench: on the bench); two climbing frames; the swing set, whose two seats swing on their chains
(lc_playground_swing_1 and _2, each on a phys_hinge under the bar), worn to mud under them; a tree over it; the doll
lying in the grass; the see-saw, its seat rocking on a hinge (lc_playground_teeter); in the far corner Valve's
terrace, paved 64 up behind a raised grass bed and its stone wall, with steps up. On the left: a bin overflowing,
our sandpit edged with timber, a dumpster, the roundabout that turns (lc_playground_roundabout on a phys_hinge) and
the slide. Leaves on the grass, chalk on the path, rust down the walls, a Combine notice. No lamp.
Left as brushes: the sandpit, the worn patches; the path, the terrace, its steps, the low wall and its fence (Valve's
own brushes too).
Unchecked: the sound ambient/levels/canals/windmill_wind_loop1.wav (one faint wind); how freely the hinges turn
(the see-saw's and the blocks' are Valve's settings, the swings' and the roundabout's ours).

### `clinic`

The clinic: a field hospital in a vault off the left wall, whitewashed over a tiled dado with a stone rail
between (City 18's dado line), against the canal's concrete. A wide way in between two drawn curtains, light cloth hung from a rail and clear of the floor (a white
cross on the wall over it); a working health charger on the ward's front wall; a ward of four beds along its back wall under two fluorescent tubes, with cloth screens
between them (lc_clinic_bed_1 to _4: where a patient lies), a mattress and a bedside drawer each, a chart on two of
the drawers, a drip stand by two beds and oxygen bottles by the others, a hospital cart, a stove with a pot
steaming on it, a bench, the nurse's table; a dispensary nook behind a shop's display counter (walk round its left
end), kitchen shelves behind, jars and kits on it, under a warm dome light; through a curtained opening an
operating theatre: Episode One's operating table under its surgery lamp, which shines straight down
(lc_clinic_table: on the table), old stains under it, a drip stand, a cart, a closet and shelves under a cool tube;
and off the theatre a sluice room with a sink, a boiler, a bucket and a floor grille, and a leak.
Left as brushes: the curtains and the screens between the beds (cloth: no model), the white cross (paint), the
theatre's door frame.
Unchecked: the sound ambient/water/leak_1.wav; which end of a bed frame is its head, and which way the sink,
stove, radiator, drawers, closet, boiler and shelves face (sizes and places are from the models' own files;
BED_YAW turns the frames); how the loose mattresses settle on the frames; that Episode One's surgery lamp
(props_c17/hospital_surgerylight01) hangs from its top (its box is 33 high: placed with its top on the roof).

### `lock`

The lock house: two lock gates across the canal, 704 apart, and between them a control house on a concrete
gantry at the trim's height. Whoever holds the house cuts the canal in two.

Each gate is Half-Life 2's own pair of canal lock leaves (props_canal locks_small and locks_small_b, side by side)
between two concrete piers that fill the banks (the gateway is 256 wide). The pair rides on one unseen leaf that
slides sideways into the left pier and the wall behind it. Shut, the canal is blocked wall to wall up to z F + 296.
They are drawn shut (so the light on them is worked out there) and the map opens both as it starts: the canal is
open until somebody shuts it. The leaf is a func_button used as a mover (PressIn opens, PressOut shuts), exactly as
the bunker's door: the gamemode's door rules (kicks, lockpicks) do not reach it, nothing can use or shoot it open,
and it has no damage of its own: a leaf that meets somebody stops and waits. A Combine lamp on each pier's beam
shows red while a gate moves, and on each pier's outer face a railway signal head shows red with it (Half-Life 2's
light_signal002a); a klaxon sounds while a gate moves. The lock chamber says what it is: a dark tide line along its
walls, depth numbers up the piers' faces.

Inside the lock, on the left bank, the way up to the gantry: from the canal floor a flight of 8 along the bank
toward gate a (an upstand on its open side) onto a landing against gate a's pier, the concrete pier beside it (an
oil drum on it), and from the pier a flight of 8 up along the wall behind a concrete parapet; on the gantry, behind
the city's handrail, the house (its doorway 64 wide and 104 high), concrete with steel
plate to the waist inside: a slit each way down the canal, a button under each slit's end for the gate on that side
with a lever panel beside it and two lamps over it (green while that gate is open, red while it is shut), the
canals' own map on the wall, switch boxes, a desk with a monitor and a chair, a fluorescent tube. On the left wall at
the gantry's end a street doorway that is never used: planked over, boards nailed across; where the chain's street
runs along the left bank (the canal ring, 23 November) there is no doorway: the gantry is at the street's height and
meets it, the street's parapet open from the upper flight's head across the gantry. The right half of the gantry
holds the hydraulic pack (a pipe cluster and a generator) and cannot be reached; its two pipes run under the
gantry along the right wall to the gates.

Named for the game:
  lc_lock_gate_a, lc_lock_gate_b    the gates (a: toward the module's entry), one unseen leaf each with both
                                    leaf models riding on it. PressOut shuts, PressIn opens (no sound that way:
                                    use the relays).
  lc_lock_a_shut, lc_lock_a_open, lc_lock_b_shut, lc_lock_b_open
                                    relays: Trigger one to shut or open a gate with its sounds, warning lamp and
                                    slam. Only the one that makes sense is live (shut while open, open while shut).
  lc_lock_button_a, lc_lock_button_b   the buttons in the house (a press triggers both of its gate's relays).
  lc_lock_house                     the middle of the control house's floor.
  lc_lock_a_move, lc_lock_a_slam, lc_lock_a_warn, lc_lock_a_shake, lc_lock_a_klaxon (and _b_)   the sounds, lamps
                                    and shake of each gate.
  lc_lock_a_lamp_open, lc_lock_a_lamp_shut (and _b_)   the house's lamps for each gate (ShowSprite, HideSprite).

Left as brushes: the piers, the beams, sills and slot lips, the gantry, its girders and corbels, the stairs and
their parapet, the house's walls, steel lining and roof, the street doorway's frame and planking (all of them the
building).

Unchecked: the two sounds are the bunker door's (Streetwar.d3_c17_11_garage_move1 / _stop1: the owner has heard
them there). That a func_button leaf simply stops against a player (no damage, no reversing) is how the bunker's
leaves behaved before their crushers were added, by its comments; not seen here. How locks_small looks from each
face (it is the canals' own lock leaf, 65 thick, 163 wide, 291 high: its sizes are read, its faces are not); that
locks_small_b is its mirror. That a prop rides on a func_button by parentname (it does on doors).
ambient/alarms/apc_alarm_loop1.wav; which way the lever panel, its handle, the signal heads and the map face.

### `pumphouse`

The pumping station: off the left wall, through a wide doorway, a machine hall 704 by 512 and 320 high, its walls
laid in courses as City 18 and Valve lay a big wall (a concrete base, brick, a stone band course, concrete to the
roof). The doorway opens onto floor, the turbine pit straight ahead; in the hall's right half a big iron wheel
(Half-Life 2's wheel02b, 132 across) turns slowly (lc_pump_wheel) on the shaft of the pump, a long horizontal tank
on the floor behind it (horizontalcoolingtank04) running back to the far wall, hazard stripes round the wheel's
guard; two risers climb from the tank to a header pipe under the roof, which runs on into the front wall as the
main; a travelling crane's beam crosses the roof with its hoist hanging; switch boxes on the wall by the stairs, a
cable to them from the turbine. Behind the doorway's line a turbine pit (192 square, 96 deep, ankle
deep in water, steps down into it, the city's handrail round it, hazard stripes round its edge, the turbine's
casing standing in it), numbers on the walls by the machines. The main leaves through the
front wall, runs along the canal wall and crosses the canal overhead on a pipe bridge nobody can reach (where the
chain's street runs along the far bank, at 608, under the street's edge, so it goes on under the street). A steel
gallery runs round the hall 144 up behind the handrail: its stairs climb along the left wall toward the front wall
(a steel plate along their open side, room at their foot) onto a landing in the corner left of the door; over the
door a bay 64 deeper holds the control desk against the front wall, 64 clear behind it: a monitor, a lamp, and the
button that stops and starts the pumps, facing whoever stands at the desk. The door that shuts the doorway (a sliding gate) stands slid open along the wall inside.

Named for the game:
  lc_pump_wheel     the wheel: a func_rotating (Start, Stop), unseen itself, the wheel model riding on it. It turns
                    as the map starts. Not solid: an unseen wall for players stands round it instead, so nobody is
                    caught in it.
  lc_pump_button    the button on the desk: a press triggers both relays below; only the live one answers.
  lc_pump_stop, lc_pump_start   relays: Trigger one to stop or start the pumps (wheel, sound, the desk's lamp).
                    lc_pump_stop is live while they run, lc_pump_start while they stand.
  lc_pump_sound     the pumps' drone (a looping sound, playing from the start).
  lc_pump_down, lc_pump_up      the run-down and run-up sounds.
  lc_pump_glow      the green glow on the desk's lamp: lit while the pumps run.
  lc_pump_hall      the hall's floor, inside the door.
An areaportal stands in the doorway's thickness (well clear of the pit's water).

Left as brushes: the hall and its courses, the doorway's frame, the gallery (its grating and posts), the steel plate
along the stairs, the wheel's bearing pedestal, the crane's beam, the hazard stripes (dev_hazzardstripe01a, as the
owner's map paints its edges), the pipe bridge's girders and the plates where pipes meet the walls.

Unchecked: func_rotating's keys from memory ("maxspeed" 40 degrees a second, "fanfriction", spawnflags 1 start on +
16 run up and down + 64 not solid, and 4 or 8 for the axle: if the wheel tumbles instead of turning, those two are
the other way round). That a prop parented to a func_rotating turns with it. Sounds from memory:
ambient/machines/pump_loop_1.wav, ambient/machines/thumper_shutdown1.wav, ambient/machines/thumper_startup1.wav.
Material metal/metalgrate013a passes the assets check; how it looks as a floor is not known. How the models look
(their sizes are read): wheel02b as a flywheel, the cooling tank as a pump, substation_transformer01c as the
turbine's casing, slidinggate001 as the door, pulleyhook01 hung from the crane's beam (its top taken as 142 over its
origin).

### `thumper`

EXPERIMENTAL: a Combine thumper. The canal widens to the right into a concrete terrace 512 long and 384 deep,
128 over the floor: a flight of 8 steps against its face climbs to a landing at the gate's foot (an upstand on its
open side), and the bank either side of the flight is a ramp too. On it, behind the Combine's own fence (combine_fence01b and 01a posts, the
owner's field between them) with a gate players open (Nova Prospekt's gate in its frame, between two of the posts),
Half-Life 2's own thumper (prop_thumper, the coast's CombineThumper002, 338 high) on a concrete plinth, fed by a fat
cable from a Combine generator: it lifts and drops its hammer by itself, shakes the ground, thuds and keeps antlions
away, for ever. Each time it lands dust jumps from the plinth. Against the terrace's near wall a Combine console,
the Combine's lamp over it and a small screen beside it, and the button that stops and starts it; Combine lamps and
a camera on the terrace's back wall, danger signs. Why it is here is shown downstream: sand drifted over the canal's
floor toward the exit, a burrow broken through the left wall's foot with sand spilling from it, two dead antlions.

Every copy has names of its own (the owner, 27 November: four round the ring for the Swarm, each stopped and
started by its own button alone). The first in a piece keeps the names below; the second is lc_thumper2_head,
lc_thumper2_button and so on, the third lc_thumper3_..., counted as they come in the layout (as the flood gates
count theirs). Every output points at its own copy's names. The ring's four: map_layouts/ring.txt.

Named for the game:
  lc_thumper_head    the thumper itself (prop_thumper): Disable stops it, Enable starts it; its output OnThumped
                     fires each time the hammer lands (the dust and the shake hang on it).
  lc_thumper_timer   a logic_timer, RefireTime 3, that tells lc_thumper_head Enable: it keeps the thumper going
                     while it runs (the relays below switch both).
  lc_thumper_stop, lc_thumper_start   relays: Trigger one to stop or start it (the thumper, the timer, the lamp,
                     a sound). lc_thumper_stop is live while it runs. The game may hang antlions on lc_thumper_stop.
  lc_thumper_button  the button by the console: a press triggers both relays; only the live one answers.
  lc_thumper_pad     the ground under the hammer.
  lc_thumper_gate    the fence's gate (a func_door_rotating, unseen, with Nova Prospekt's gate riding on it: Use
                     opens it; the gamemode can lock it).
  lc_thumper_hit, lc_thumper_top, lc_thumper_shake, lc_thumper_dust, lc_thumper_glow, lc_thumper_down
                     a thud and a clank the game may play (the thumper makes its own sounds, so nothing plays
                     them), the shake and the dust at each landing, the blue glow on the lamp over the console
                     (lit while it runs), the run-down sound.
  lc_thumper_lamp    the console lamp's light (TurnOff, TurnOn: the relays switch it with the glow).
  lc_thumper_burrow  the burrow's mouth in the left wall (where the game may bring antlions out).

Left as brushes: the terrace and the thumper's plinth (the ground it stands on), the burrow's back.

Unchecked: prop_thumper's keys and its input and output from memory of Half-Life 2's coast ("dustscale",
"EffectRadius", Enable, Disable, OnThumped); that it starts running by itself; which way the model faces (it is
placed so its box is centred on the plinth). env_smokestack's TurnOn and TurnOff for the dust. Sounds from memory:
ambient/machines/thumper_hit.wav, ambient/machines/thumper_top.wav, ambient/machines/thumper_shutdown1.wav.
models/antlion.mdl as a ragdoll; nature/blendmuddirt001a for the drift (blendsandmud001a is not in the owner's Garry's Mod: their compile, 22 November); combine_shield_loop3.wav.

### `depot`

The Combine's ration depot: a place to raid. In the left wall the Combine's own big door (combine_door01, 192
wide and high: lc_depot_door, shut) opens straight off the canal's floor into a loading bay with a truck backed up
to a dock 40 high, tyres hung on its edge, hazard stripes along it. The hall is the Combine's inside: its walls
clad in their plate (a base of metalcombine001, panels of metalcombine002, a band of the Citadel's plate under the
roof), lit by the Combine's wall lights and two tubes, a camera over the cages, a small screen by the big door. The
dock runs along the back (pallets of the Combine's own supply crates) and fills the far half of the hall: three
cages of Nova Prospekt's chain link panels against the back wall, a shelf unit with ration packages on it, cases of
Breen's water and the Combine's crates in each, each with its own gate in its frame and a Combine lock on it
(lc_depot_cage_1 to _3: Use opens them, the gamemode can lock them),
the dispatch desk with a Combine console (lc_depot_desk), and a roller conveyor that carries crates out through a
low hatch in the wall and down a chute to the canal (the hatch is 26 high over the rollers: nobody gets in that
way). At the far end a staff door (lc_depot_side, one of the city's doors) up the steps from the canal: no Use
opens it, only the button beside it inside, and it shuts by itself after four seconds. A caged lamp on the wall
over each door; beside the big door inside, an alarm lamp the game can light.

Named for the game:
  lc_depot_door         the big door: a func_door that lifts (Open, Close, Toggle), unseen, the Combine door's model
                        riding on it.
  lc_depot_button_door  the button inside, left of the roller door: Toggle.
  lc_depot_side         the staff door: one of the city's doors (prop_door_rotating) that ignores Use (spawnflag
                        32768): Open opens it; it shuts itself after four seconds. The gamemode's door rules
                        (lockpicks, kicks) may still reach it: that is the raiders' other way in.
  lc_depot_button_side  the button inside beside the staff door: Open.
  lc_depot_cage_1, _2, _3   the cages' gates (func_door_rotating, Use: unseen, Nova Prospekt's gate riding on each).
  lc_depot_desk         the Combine console at the dispatch desk (a prop_dynamic).
  lc_depot_alarm, lc_depot_alarm_light   the alarm lamp's red glow and light beside the big door inside (off: ShowSprite
                        and TurnOn light them, HideSprite and TurnOff put them out).
In a --test file a red button in the roller door's mouth opens and shuts it from outside, as the game will.
Areaportals: one inside the thickness of each door, one in the hatch.

Left as brushes: the hall and its cladding, the dock, its steel edge and stripes, the steps, the doors' frames, the cages' mesh roof (no
model lies flat), the roller conveyor and its chute (Half-Life 2 has no conveyor), the hatch's shutter and the
concrete cheeks in the bank.

Unchecked: prop_door_rotating's spawnflag 32768 (ignore Use) and "returndelay" 4; that combine_door01 stands shut
as a prop_dynamic (it has its own animation) and which of its faces is its front. All models pass the assets check;
the truck's, the console's and the shelf unit's facing are guesses; where combine_lock01 sits on a gate's frame.

### `armory`

A Combine armoury vault: a heist target. Off the left wall an armoured corridor 128 wide runs 384 in to a vault
door: Nova Prospekt's sliding door (prison_slidingdoor001a, between Combine jambs) that slides sideways into the
wall at 20 a second, with a klaxon, a groan and a slam. Beside the corridor's first half is the guard booth, behind a wall of Combine metal with a doorway and
a slit that looks down the corridor. The door answers only to TWO buttons pressed within two seconds of each other:
one in the booth's far corner, one on the corridor wall by the door, 340 apart with the booth's wall between, so
it takes two people (the Combine's small light over each glows green for the two seconds its press counts). Pressed
together again, they shut it. A Combine camera watches the corridor from its entry. Booth and vault are the
Combine's inside, as the corridor is: walls clad in their plate (a base of metalcombine001, panels of
metalcombine002, the vault's a band of the Citadel's plate under its roof), the vault's floor steel; tubes light the
corridor and the booth, the Combine's wall lights the vault. In the booth a desk with the guard's log, a chair, a
monitor on its stand, a small screen on the wall over the slit, his stun baton, lockers. Inside the vault (384 by
256), behind two red laser beams across its doorway: gun lockers along one wall, the Combine's ammunition crates
along the other with guns and boxes of rounds laid on them, more stacked by the door, and the Combine's weapon frame
(weaponstripper) against the far wall with three pulse rifles standing in front of it under a blue glow. A button
inside by the door opens it, so nobody is shut in. A red alarm lamp hangs in the corridor by the door, and while the
door moves two red lights come on along the corridor.

The door is a func_button used as a mover, as the bunker's, unseen, the door's model riding on it: the gamemode's
door rules do not reach it, and it has no damage of its own (at 20 a second it stops against whoever stands in its
way).

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
  lc_armory_red_1, lc_armory_red_2   the corridor's red lights while the door moves (TurnOn, TurnOff).
  lc_armory_beam_1, lc_armory_beam_2   the laser beams across the vault's doorway (env_beam: TurnOn, TurnOff,
                        Toggle; nothing is tied to them: the game may tie an alarm to them), between
                        lc_armory_beam_1a and _1b, _2a and _2b (info_targets).
Areaportals: one in the entry, one inside the vault door's thickness.

Left as brushes: the corridor, its Combine plates and ribs, the booth's wall with its slit, the booth's and the
vault's cladding, the door's jambs and head, the plinth the rifles stand on.

Unchecked: the wiring is the owner's nest door's (math_counter Add and Subtract, OnHitMax) and the sounds are the
bunker's and the nest's, heard there. The rifles are prop_dynamics turned to stand on their butts ("angles" -90
pitch), the guns on the crates turned on their sides (roll 90): which way a weapon model's barrel lies is from its
size alone. The weapon and ammunition models pass the assets check as prop_dynamic; whether the gamemode lets
players pick such props up is its affair. How weaponstripper looks as a rack (its size is read). env_beam's keys
(from memory: LightningStart, LightningEnd, texture sprites/laserbeam.vmt, life 0, spawnflags 1 starts it on).

### `railbridge`

EXPERIMENTAL: a railway crosses over the canal on a steel girder bridge, from a tunnel mouth in the left wall to
one in the right. Every 150 seconds a horn sounds, a red lamp shows at each mouth, and two seconds later a freight
train of two flat cars (Half-Life 2's train005, one loaded with steel beams, one with crates) comes out of the left
tunnel, crosses, and is gone into the right one. The bridge shakes as it passes. Under the bridge the canal carries
on between two concrete piers; a crate or two has fallen off. Nobody can get onto the bridge: its bed is 240 over
the canal's floor, there are no stairs, and both tunnels are dead ends (black at the back) 1024 deep, long enough
to hide the whole train. Each mouth has a face: concrete pilasters, the abutment, a number and a danger sign, and
beside it on the wall one of Half-Life 2's railway signal heads (light_signal002a) that shows red while a train
comes. The track is seen whole: ballast on the bed, sleepers, rails running into both tunnels, and an overhead wire
on three posts from tunnel to tunnel. When the train crosses, dust and grit fall from under the bridge. Under it,
caged lamps on the piers (one dead), graffiti, crates fallen off the last train and broken, and the body of someone
who stood on the line.

The rails' bed is at the walls' top less 144 (z 640 with the usual walls), not higher: the canal walls' concrete
ends at the rim with the fence along it and sky above, so a tunnel mouth must end at the rim.

How it runs (none of it could be tried here):
  lc_rail_train    one func_tracktrain: an unseen block as big as the train, built standing hidden in the LEFT
                   tunnel on lc_rail_p1; the two car models and their loads ride on it (parentname).
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
  lc_rail_dust_1 .. _3   the dust off the bridge's underside (env_dustpuff: SpawnDust), sent by lc_rail_p2.
In a --test file a red button on the left pier's canal face triggers lc_rail_run.
An areaportal stands 64 inside each tunnel, walled all round; the train passes through both.

Left as brushes: the tunnels, the bridge (girders, bed, cross girders, abutments, piers), the overhead wire's posts
and the track: the only track models (traintrack001c, 006b, 006c) are 288 wide and more, too wide for the 128 bed.

Unchecked: everything above about func_tracktrain and path_track is from memory of Hammer's entity list (the
keys "startspeed", "speed", "orientationtype", "height", "wheels", "bank", "dmg", "MoveSound", "volume"; the
spawnflags; that a path_track with spawnflag 16 is teleported to; the inputs StartForward and Stop; the output
OnPass). The sounds are from memory: ambient/alarms/train_horn2.wav, ambient/machines/razor_train_wheels_loop1.wav.
If the train comes out sideways, the fixed orientation did not take: tell me. If it never moves, try "speed" 0.
env_dustpuff's keys; which way the signal heads face (taken as the model's +x).
That train005 is a flat car (its size is read: 118 wide, 460 long, 54 high; its look is not), and which of its
ends is its front (it is the same both ways round in its size).

### `execwall`

The firing wall: where the Combine shoots people. A recess in the left wall under the open sky, its floor a
slab 8 high: a row of concrete barriers along the back wall, the wall above them pocked with bullet holes and
stained, three timber posts (the docks' poles) with a rope's end on each, a grating down the middle to the canal, a
barrier at each front corner, one hard Combine floodlight in the back corner throwing its beam along the posts, two
of the Combine's wall lights over the barriers. The Combine's marks: a loudspeaker high on the back wall to read the
sentence, a camera over the recess, Breen's poster on the side wall facing the posts, a number stencilled on the
wall. What is left behind, still sober: a dark stain at the grating, a shoe, a dropped ration bag, a candle someone
lit at night. The squad stands in the canal, behind a yellow line painted on its floor. Silent but for the
floodlight's hum and the wind (the soundscape "Nothing", as the owner's map uses it).
Named for the game: lc_execwall_post_1 to _3 (at the posts, facing out), lc_execwall_line (where the squad stands,
facing the wall), lc_execwall_lamp (the lamp's beam: LightOff, LightOn).
Left as brushes: the slab, the grating, the painted line (dev_hazzardstripe01a, 1 high, as the owner's map paints
its edges), the candle (no model of one).
Unchecked: the rope ends (move_rope), point_spotlight and light_spot keys; which way combine_light001b,
speakercluster01a and combinecamera001 face (their fronts taken as the models' +x); ambient/machines/
combine_terminal_loop1.wav for the floodlight's hum.

### `substation`

The substation: what powers the Combine's things in the canals. A concrete quay against the RIGHT wall, 128 high
with steps up its upstream end; along its front, set back from the edge, the Combine's own fence (combine_fence01b
and 01a posts, the owner's field between them), and at the steps' head a sliding gate (a chain link panel in a
short run of Nova Prospekt's fence) players open by hand. Inside, a yard: three of the city's own substation
transformers (substation_transformer01c) back against the wall, a danger sign over each, cables from them up to an
arm on the wall and across the canal to an insulator on the far wall's top (where a street runs along the far bank,
which has no wall top, to one on the yard's own wall's top), a steel switch cabinet (controlroom_storagecloset001a) with the fuse panel on its front and the Combine's meter box beside it, a caged
warning lamp on the wall over it, two of the Combine's lights on the wall, danger signs on the quay's face, a steady
hum. The cabinet's panel is a func_breakable (40 health): breaking it fires the relay lc_substation_cut, which stops
the hum, puts out the lamps (the warning lamp and the Combine's lights), throws sparks from the panel and from each
transformer's top and lets a wisp of smoke rise: the game can hang more on it (dropping a checkpoint's force field).
Named for the game: lc_substation_fuse (the panel), lc_substation_cut (the relay: Trigger; give it more wires),
lc_substation_hum, lc_substation_lamp and lc_substation_glow, lc_substation_spark, lc_substation_gate (a func_door,
unseen, the gate's panel riding on it), lc_substation_spark_t1 to _t3 (the transformers' sparks), lc_substation_smoke
(TurnOn), lc_substation_light_1 and _2 (the Combine's lights: TurnOff).
Left as brushes: the quay and its steps, the steel arm on the wall that carries the cables, the fuse panel (a
func_breakable: the game needs a thing that breaks, and a model riding on it would outlive it).
Unchecked: ambient/energy/electric_loop.wav, func_breakable's keys, the cables (move_rope); where on the
transformers' tops their insulators are (the cables start at the middle of each top); combine_shield_loop3.wav.

### `tramfall`

The tram under the breach (the owner, 26 November, of the tram's station that could not stand under the street
and of the breach: "sink the tram line even lower than the canal floor and combine it with the breach module so
the broken canal floor is above the crashed tram, and the crashed tram is flat on the tracks but the
rubble/concrete slabs from the breach have fallen onto it so it's still the EP2 model"). The tram's line crosses
under the canal in a tunnel, its rails 304 under the canal's floor, its roof the canal's floor slab; over it the
floor has fallen in, a hole 384 by 256: Episode Two's wrecked car (wrecked_train_02) stands level on the rails on
its two bogies under the hole, as the tram module stands its cars, slabs of the canal's floor leaning on it and
lying on its roof, rubble and bent bars round it, daylight and dust down the hole. Beside the car a slab of the
collapsed floor lies as a ramp from the hole's edge down to the tunnel's floor (no steps: the owner, "just make it
a slab of broken/collapsed concrete: a ramp"). Away from the city the tunnel ends in the dark, black.
Toward the city the line runs under the street into THE TRAM MODULE'S OWN STATION, copied whole
(map_mods_a.tram_station: the owner, the same day, of a bare hall first built here: "I told you to take the tram
module that had the little station and put it in the breach module ... WHY NOT JUST COPY PASTE IT? WHERE IS THE
STATION? WHERE ARE THE PROPS?"): the hall with its platforms either side of the track's pit, Half-Life 2's
station columns and arches, the two-tone walls, the wall lamps, the ticket booth, the benches, the clock, the bin,
the payphone, the signs, the signal, and the barred stair behind the prison's sliding gate; its tunnel's black end
and the stair's lie directly under the Combine wall (the owner: the "gate/black void side ... directly under a
combine wall section"), the station set 64 further from the canal than the tram module's to reach it.
Named for the game: lc_breach_bottom (the tunnel's floor under the hole), lc_tram_exit (the station's, on the
platform before the barred stair), lc_tram_stash (beside the car: a cache).
The layout needs "base 64" or lower (the rails are at z 96), and the street on the module's left.
Left as brushes: the tunnel, the fallen slabs, and what the station leaves as brushes.
Unchecked: the car and its bogies are Episode Two's; the look of it.

### `breach`

The breach: the canal's floor has fallen into an old cellar. A pit 640 by 256 and 160 deep in the middle of
the canal: its edge broken, not cut (chunks of the canal's floor slab overhang it unevenly, the slab's thickness
showing over the cellar's old brick), cracks running out across the canal's floor from it. The cellar's walls are
old brick, a bricked-up doorway in a stone frame in one of them; its floor earth over old flagstones, with a pool of
standing water in the low end and drips from the edge. Two slabs of the old floor lean down into it along its
sides as ramps (one from each end); a third still hangs over the downstream end on two old timber poles and makes a
dark undercut where things are kept, a lantern burning under it; a shelf of old bottles against the upstream wall,
crates; reinforcing bars stick out of the broken edge, rubble lies at the bottom, dust hangs in the light from above.
The canal's banks pass either side, so nobody has to go down.
Named for the game: lc_breach_bottom (the middle of the pit), lc_breach_stash (under the hanging slab).
Left as brushes: the pit, its broken edge and brick lining, the doorway's frame, the flagstones and the three slabs
of fallen floor (the ground itself).
Unchecked: the look of it; the rebar is stood on its side (pitch 90), centred on its origin so it stays where it is
put; ambient/water/drip_loop1.wav.

### `wreck`

The wreck: a Combine dropship's troop container has come down in the canal: Episode One's own wrecked container
(combine_dropship_container_static, 415 long, hollow: its collision is the hull's own), lying askew as a thing that
fell from the sky lies: turned 20 degrees across the canal, nose down a few degrees into a ring of thrown earth,
its tail toward the left bank, a dim red glow still on inside and a red beacon pulsing slowly on its back. Behind it
the gouge it cut: slabs of the canal's floor lifted and tilted, scorch and debris along its track, a torn-off piece
of its hull. Round it the crash's leftovers: two dead Combine soldiers, a pulse rifle by one, the Combine's supply
crates and an ammunition crate spilled from it, a small fire still burning, sparks, thin smoke. A thing to race
for: the Combine to recover it, the Resistance to strip it.
Named for the game: lc_wreck_cache (inside, at its middle), lc_wreck_beacon (the beacon's pulsing glow on its back:
HideSprite, ShowSprite), lc_wreck_spark (StopSpark).
Left as brushes: the lifted slabs of floor (the ground itself; the earth round its nose is the ground's own bumps).
Unchecked: env_spark, env_smokestack, env_fire, models/combine_soldier.mdl as a ragdoll. The container is Episode
One's (players need Episode One's content, as for every Episode One model); whether its door end is open and
players can get in, and which end is its nose (its size is read, its shape is not: the nose is taken as its +x,
171 before its origin); container_chunk04 as a torn-off piece.

### `morgue`

The morgue: where the city's dead wait for the cremator. A sliding steel door in the left wall (Nova Prospekt's
sliding door between steel jambs: players open it by hand), a short passage, a cold room tiled to the waist and
plastered above: a wall of twelve drawers, two pulled out, a number on each column, three steel tables (the
hospital's surgery tables), two of the dead laid out on them (they do not move), a drain in the floor, a thin cold
mist on the floor, three fluorescent tubes; in the right wall the body chute to the cremator (a steel hatch in a
frame, a roller conveyor up to it: where the dead go to the ash outfall); a clerk's desk with the ledger, a
clipboard, papers, a radio and a Combine screen for the records; a caged lamp over the door outside; a compressor's
hum.
Named for the game: lc_morgue_door (a func_door, unseen, the door's model riding on it), lc_morgue_table_1 to _3
(the tables), lc_morgue_ledger (the desk), lc_morgue_chute (where the game sends the dead from: on the
floor at the foot of the conveyor, facing the chute's hatch at its top; a place to stand, not the hatch itself).
Left as brushes: the room, its tiles and plaster, the door's jambs and head, the drain, the wall of drawers (built
into the wall: Half-Life 2 has no morgue drawers), the chute's hatch and frame and the conveyor (no model of one).
Unchecked: models/humans/corpse1.mdl as a ragdoll laid on a table with its motion disabled (spawnflags 16388:
debris and motion disabled, so it stays where it is laid), func_dustcloud's keys for the mist; which way the
surgery table's head is (it is the same both ways in its size).

### `servicetunnel`

A long way on foot, in Valve's own tunnel: Black Mesa East's tunnel toward Ravenholm (the prefab
valve_eli_raven_tunnel, lifted from d1_eli_02), laid twice end to end, 2752 of it: an arched concrete tunnel 192 wide
and 176 to its crown on a marble floor, Valve's pipes along one wall, deck lamps in the crown (one lit in each length,
the others dead, as Valve left them), a red emergency lamp, and in each length Valve's bulkhead (a doorway 176 wide
and 112 high, where the Ravenholm door hung) 312 from its outer end. The owner, 26 November, of the bunker forest's
place on the ring: "can we please make it down a longer tunnel and not put it RIGHT there; like a HL2 tunnel
copy/pasted". At each end 128 of the canal's own culvert (512 wide, the gate's height), shut across by a concrete
bulkhead with a doorway 128 wide and 128 high into the tunnel, a caged lamp over it. For a buried chain between two
gates (map_layouts/bunker_way.txt).
Changed from Valve's: the story left out (Dog, the door he lifts, its marks and triggers); the emergency lamp, dark
until the attack in Valve's map, is lit; the two fence panels at the base's end left out. The second length is the
first turned half round. Left as brushes: the tunnel (Valve's own, one func_detail a length), the bulkheads.
Unchecked: which way Valve's pipe models lie once turned with the piece.

### `floodgate`

The flood gate (the owner, 26 November: "copy the flood gate that blocks the airboat (right after you get the
airboat) from HL2 and requires the valve to be turned; and if the valve stops being turned mid-open, the gate slams
shut"): Valve's sliding sluice gate of d1_canals_05 (the prefab valve_canal_sluicegate_a: two metal leaves 188 wide
side by side, door panels under a band of grating in a truss frame, 206 high) in a concrete headwall across the
canal, its crest at the street's height. The leaves are func_movelinears that slide apart into the headwall's
piers as far as the wheel has been turned (Half-Life 2's valvewheel001 on an unseen momentary_rot_button: hold E;
two full turns open them). While it is turned an alarm sounds as the forest bunker's door does and a red beacon
turns over the wheel; the gate's rumble lasts while it moves and stops with it. Let go before it is fully open
and it slams shut; once fully open it stays, closing so slowly that it takes two minutes, and turning the wheel
again in that time opens it again (the owner, 26 November: "once the door has been opened all the way, it stays
open and doesn't slam shut EXCEPT it slowly slowly starts to shut and would take about 2 minutes to shut all the
way again; if someone turns the valve again during this 2 minutes it resumes it's opening sequence"). The wheel
stands where the men who built it would have set it with the water in mind (the owner: "the valve wheel is just
below the canal/road level and not at the bottom of the canal ... we need to keep in mind how it would have been
constructed with a potential water level in mind"): on the headwall's upstream face 64 under its crest, over a
steel service platform 112 under it on the street's bank (the left, where there is no street), reached by an iron
ladder up the canal's wall. A lamp by the wheel, a danger sign and a number on the headwall. A leaf that meets
someone stops.
Named for the game: lc_floodgate_N_wheel (the momentary_rot_button: Lock, Unlock, SetPosition 0 to 1),
lc_floodgate_N_leaf_a and _b (the func_movelinears: SetPosition 0 shut to 1 open), lc_floodgate_N_latch (a
logic_branch: 1 from fully open until shut again), lc_floodgate_N_beacon, _alarm, _alarm_timer, _move and _clang
(the beacon and the sounds), N counting the flood gates of a map from 1.
Left as brushes: the headwall, the leaves (they move), the platform.
Unchecked (from Valve's wiki and maps, not run here): that a momentary_rot_button's Position output drives a
func_movelinear's SetPosition as it turns and as it runs back, and that SetPositionImmediately 0 on the wheel sends
it; which way valvewheel001 faces when pitched 90; plats/elevator_move_loop1.wav and
doors/door_metal_large_chamber_close1.wav.

### `lockgate`

The lock gates: Valve's pair of lock gates from d1_canals_08 across the wide canal (the owner, 21 November: "the
massive dual water hazard gates that shut and force the player to navigate around them ... a great toggle able gate
to block the canal"). Two leaves 384 long and 480 high turn 80 degrees on hinges 768 apart, each carrying Valve's
model (locks_large_b and locks_large, 572 high), wired as Valve's: speed 15, a klaxon four times a second apart as
they start, Floodgate_Move_Short while they swing and Floodgate_Stop as they stop. Open, they lie in recesses in
the walls downstream; shut, they close the canal from wall to wall (piers either side of them) and an areaportal in
their thickness closes behind them, so the far canal is not drawn (Valve's rules: the portal shuts on
OnFullyClosed and opens on OnOpen; over the leaves the gate line is sky, which it looks like anyway).
On the left bank, upstream of the gates, a control booth in the wall 192 up (stairs up to it along the wall, the
city's stair rail, a landing, the city's handrail along its open front, a lamp): on its back wall the switch,
Valve's CombineButton with a light beside it that shows the gates' state, green open and red shut (Valve's switch
recipe, the state set by the gates themselves, so it is right whoever moved them); over its front a red beacon
that turns while the gates move (the alarm recipe: a func_rotating with two red spotlights in a cage lamp).
For people on foot, the way round: in the right wall a doorway upstream of the gates, a passage 128 wide inside the
wall, lit, past the gates, and a doorway back into the canal beyond the recesses (its own areaportal, always open).
Beside a street (the canal ring) the leaf on the street's bank, open, stands 300 over the street at its canal edge,
its recess reaching under the street's edge: the street's parapet is left out there (it would run through the leaf).
The gates start open: they swing open as the map starts ("lockgate shut" leaves them shut); the Combine, or rebels
laying an ambush, shut them at the booth (the owner, 21 November). Nothing kills (the owner, 22 November: "considering
how dying in the gamemode means a new character, yes just shove, not kill"; until then a leaf killed whatever it met):
in the last moments of each swing a shove pushes whoever is in a leaf's way out of it. Path nodes go round by the
passage, never through the gate line. The canal is 1024 wide at both ends (between "widen" and "narrow").
Named for the game: lc_lockgate_open, lc_lockgate_close and lc_lockgate_toggle (logic_relays the gamemode fires:
the klaxon, the beacon and the leaves), lc_lockgate_opened and lc_lockgate_closed (logic_relays fired when the
leaves have finished moving), lc_lockgate_switch (the button in the booth: it fires lc_lockgate_toggle),
lc_lockgate_state (a logic_branch, 1 while open), lc_lockgate_leaf_a and lc_lockgate_leaf_b (the
func_door_rotating leaves), lc_lockgate_portal (the areaportal), lc_lockgate_klaxon, lc_lockgate_beacon.
Left as brushes: the piers, the quoins and the sky over the gate line, the stairs and landing, the booth.
Unchecked: Valve's sound scripts d1_canals.Floodgate_Klaxon, d1_canals.Floodgate_Move_Short and
d1_canals.Floodgate_Stop (Half-Life 2's canal sounds); that locks_large and locks_large_b hide the areaportal
with no gaps (Valve kept theirs far behind the gates); which way CombineButton faces (turned out of the wall and
tipped back 30, as Valve's).

### `roadend`

The west road's end (the owner's brushes 14734, the sky wall, and 15630, the unseen wall before it, are what it
stands in the place of: map_merge.py leaves them out). Built for one place: heading south at x -3136, from y 2752
to 1664 (map_layouts/ring_north.txt), with the road's opening at x -2608, y 1920..2560, its surface z 840.

On the left bank a platform at the road's height (256 by 640, open to the sky as the old ring's was) carries the
road on to the canal's edge; a flight of 28 steps (16 up, 24 along) runs south down the left wall from its north
end to the canal's floor, filled under and railed on its open side, and the platform's edge is railed. The far
(right) wall has a standard gate (512 wide, 256 high, capped until the ring's south half is joined to it): the way
on round the south of the city. The canal ends past the platform, as the old ring's did (the city stands 64 beyond).
A lamppost on the platform, a caged lamp over the stairs' foot, a puddle and trash; the courtyard's soundscape.
With --test the road's opening is shut by a wall of sky (the city is not there to close it).
Unchecked: nothing new (the old ring's platform, stairs and threshold, rebuilt to fit one module).

### `hq`

The Resistance leader's office. A doorway in the left wall into a briefing room (a long table and benches, a
cork board, a lamp), and behind a partition the leader's own office: a desk and chair, a filing cabinet, a steel
closet, a bed. The town's flagpole stands on the plaza, not here (lc_hq_setup_plaza: the owner, 21 November).
Named for the game: lc_hq_desk, lc_hq_table, lc_hq_map.
Unchecked: which way the cork board, the closet and the bed face.

### `flats`

A house people can live in, furnished as the owner's city's flats are (stoves, sinks, fridges and beds stand
backs to the wall). A front door that opens (the city's own door, with its handle) into a hall; off it two flats,
each behind its own door: a kitchen (stove, sink, fridge, a table and two chairs, a radiator) and through an
archway a living room (a fireplace, a couch facing it, a dresser). At the hall's end a stair climbs 160 to a landing
and a passage with a bedroom off each side: the left flat's has the city's iron bed, the right one's a wooden bed
and mattress; both a dresser and a bedside drawer. (The owner, 20 November: "too cramped, half of that can go in
the bedroom(s), can we have a few upstairs rooms too?")
Named for the game: lc_flat_door (the front door), lc_flat_1 and lc_flat_2 (info_targets in the two kitchens). A
second house in one chain takes a word after its name in the layout ("flats b"): lc_flat_b_door, lc_flat_b_1 ...
Each bedroom has a bathroom behind it (a toilet, a sink, a bath); the walls are lined in two tones of plaster
with a dado rail, the living rooms panelled below it; the kitchens have the owner's fluorescent tube.
Unchecked: the mattress's height on its frame; which way the dresser, drawers, toilet and bath face;
the living rooms are panelled in wood/woodwall006a (the owner uses it 87 times).

### `straight`

Plain canal. "straight 1536": that long. Add "bridge" for a street carried over its middle, "pipes" for a pair of
pipes across it, "bare" for nothing left lying in it (otherwise a few odds and ends from CANAL_JUNK, the same every
time for one place: crates, tyres, a cart, a cone, a bicycle, a washing machine). Puddles and trash on the floor; a
quiet courtyard's soundscape (wind and the city over the walls). The walls' caged lamps, outfalls, drain stains and
graffiti come with every canal (dress_canal_walls). From 1536 long a walk along the left wall (walk_ledge: 72 wide,
208 up, stairs at each end where it is long enough; "flip" puts it on the right, "noledge" leaves it out), clear
of a bridge or pipes.

### `jog`

The canal steps sideways, to break a long view: "jog left 768" (the default), "jog right 1024". What the floods
leave in the elbow (two things from CANAL_JUNK), puddles and trash, the courtyard's soundscape.

### `tee`

A way off to the left: a standard gate in the left wall (512 wide, 256 high), capped until another piece, or
another layout's start, is joined to it. A number painted beside the gate, puddles and trash, the courtyard's
soundscape.

### `tunnel`

The canal under the city: a covered stretch of any length ("tunnel 1536"), for passing under streets and
buildings. Its roof is vaulted (a polygonal barrel springing from the walls 96 under the crown) with a rib every
256, posts down the walls under each; a raised kerb walk along each wall, the city's handrail along its edge in
places; the city's pipe (pipeset32d) along the right wall, capped at both ends, a cable slung along over it;
caged lamps on the left wall between the ribs (one in three dead); in the left wall's middle a maintenance doorway,
planked over and boarded (nobody goes in); puddles under the roof's joints, drips, the tunnel's own soundscape.
Left as brushes: the kerbs, the vault and its ribs, the doorway's frame and planking (the tunnel itself).

### `shed`

Plain canal, and on the street beside it a brick shed over the tracks, where a train waits out of sight. A
straight run needs two for a train: one to come out of, one to go into. Only where the layout has a street
("upper left"). "shed 2304": that long (by itself it is the length of the train and a little over).

### `widen`

The canal widens from 512 to 1024 (Valve's airboat canals' width): 256 of the city canal, then its walls step out
128 each side, and again 256 on, so it is 1024 wide for its last 256. The banks wrap round both steps (a slope up
each step's face, a quarter pyramid on each corner) and stop against the wide canal's upright walls. The next
module must be a wide one ("wide", "widetee", a turn) or "narrow". Beside a street the chain makes it one-sided
("oneleft", "oneright"): the street's wall runs straight on, the far one steps out 256 and 256 again.

### `narrow`

The wide canal narrows back to 512: the mirror of "widen" (256 of the wide canal, two steps in, 256 of the city
canal), the banks starting again round the steps. One-sided beside a street, as "widen".

### `wide`

The wide canal: 1024 between upright walls, the floor sagging about 42 to its middle, any length ("wide 2048").
From 2048 long a walk along its left wall (walk_ledge: 102 wide, 320 up, stairs at each end; "flip" puts it on the
right, "noledge" leaves it out). "bridge": a street carried over its middle; "pipes": a pair of pipes across it.
Odds and ends lying in it, puddles and trash, the quiet courtyard's soundscape; the lamps and outfalls come with
its walls (dress_canal_walls).

### `widetee`

A way off the wide canal's left wall: the same standard gate as "tee" (512 wide, 256 high), capped until another
piece or another layout's start is joined to it, a number painted beside it. The canal is 1024 wide at both ends.

### `basin`

The canal widens into a basin 1024 wide and narrows again within one module, so it starts and ends on the plain
512 section and goes anywhere a plain stretch does ("basin 2560": that long, 2048 at least). Its steps are those of
"widen" and "narrow" (the banks wrap round them); between them the wide canal's upright walls and deeper dish, a
walk along the left wall where the basin is 2560 or longer ("flip": the right; "noledge": none), odds and ends.
(Valve's boathouse, jetty and lookout stood here for one build: the owner's walk, 22 November, "floating props and
no walls and a missing ceiling", "why are these on the other side": a piece lifted from a riverbank on piles does
not stand in a dry canal. Lesson valve-piece-fit.)
