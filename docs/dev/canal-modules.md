# The canal modules (made by `_dev/tools/map_catalogue.py --list`: never edit by hand)

What a module is and how to lay them out: `docs/dev/map-building.md` ("Canal modules"). How to write one: `docs/dev/map-modules.md`. Everything under "named for the game" is there for the gamemode to give a use: nothing uses them yet unless a feature's own doc says so.

| Module | Long | What it is | Named for the game | File |
|---|---|---|---|---|
| `drain` | 1024 | 1. the storm drain junction, down to the city's sewers (left) | `lc_drain_cache`, `lc_drain_grate`, `lc_drain_junction` | `map_modules.py` |
| `overflow` | 1024 | 2. the overflow toward Ravenholm, behind a sluice plate (left) | `lc_overflow_drop`, `lc_overflow_far`, `lc_overflow_lever`, `lc_overflow_lift`, `lc_overflow_moan`, `lc_overflow_sluice` | `map_modules.py` |
| `shanty` | 1536 | 4. the shantytown under a street bridge (left) | `lc_hq_setup_shanty`, `lc_shanty_board`, `lc_shanty_cards`, `lc_shanty_fire`, `lc_shanty_fund`, `lc_shanty_soup` | `map_modules.py` |
| `vort` | 1024 | 6. the vortigaunt culvert (left) | `lc_vort_fire`, `lc_vort_npc`, `lc_vort_seat_1`, `lc_vort_seat_2`, `lc_vort_seat_3` | `map_modules.py` |
| `relay` | 1024 | 7. Cubbage's relay shack and mast, on a pier (right) | `lc_relay_hum`, `lc_relay_lamp`, `lc_relay_mast`, `lc_relay_radio`, `lc_relay_seat` | `map_modules.py` |
| `checkpoint` | 1280 | 8. the Combine checkpoint: a wall, a force field gateway, a guard's platform and searchlight | `lc_checkpoint_field`, `lc_checkpoint_hum`, `lc_checkpoint_light`, `lc_checkpoint_light_b`, `lc_checkpoint_pen`, `lc_checkpoint_pen_spot`, `lc_checkpoint_post`, `lc_checkpoint_queue` | `map_modules.py` |
| `ash` | 768 | 10. the ash outfall: trash and burnt corpses (left) | `lc_ash_clatter`, `lc_ash_dust`, `lc_ash_grate`, `lc_ash_heap`, `lc_ash_timer`, `lc_ash_tip` | `map_modules.py` |
| `sludge` | 2048 | 11. the sludge tunnel: a shortcut through the long way round (left) | `lc_sludge_gas`, `lc_sludge_gurgle`, `lc_sludge_gurgle_timer`, `lc_sludge_gurgle_timer_near`, `lc_sludge_haze` | `map_modules.py` |
| `cistern` | 1536 | 12. the cistern for the hive boss (right) | `lc_cistern_gallery`, `lc_hive_boss_spot` | `map_modules.py` |
| `underpass` | 1536 | 13. the barnacle underpass | `lc_underpass_body_1`, `lc_underpass_body_2`, `lc_underpass_body_3`, `lc_underpass_body_4`, `lc_underpass_body_5`, `lc_underpass_dust`, `lc_underpass_dust_timer`, `lc_underpass_dust_timer_near` | `map_modules.py` |
| `tram` | 1536 | a fallen tram bridge: a station in each wall, a derailed car to climb, a beam walk | `lc_tram_exit`, `lc_tram_stash` | `map_mods_a.py` |
| `tenement` | 1280 | a tenement block fallen across the canal: the way on is through its rooms | `lc_tenement_lookout`, `lc_tenement_stash` | `map_mods_a.py` |
| `quay` | 1024 | stairs up to a quay with a street doorway (a cap to delete), a footbridge to a barred door | `lc_quay_far_door`, `lc_quay_street` | `map_mods_a.py` |
| `collapse` | 768 | a street's wall and roadway fallen in: a squeeze by the right wall, a crawl under the slabs | `lc_collapse_hide` | `map_mods_a.py` |
| `scrapyard` | 1536 | the canal widens into a yard of stacked containers under a crane: ways through, ways over, a perch | `lc_scrap_perch` | `map_mods_a.py` |
| `boathouse` | 1024 | a smugglers' boat shed in the left wall: a roll-up door, a slipway, a hatch to a cellar | `lc_boathouse_button_in`, `lc_boathouse_button_out`, `lc_boathouse_cellar`, `lc_boathouse_door`, `lc_boathouse_hatch`, `lc_boathouse_hatch_button` | `map_mods_a.py` |
| `arcade` | 1536 | a market arcade over the canal on three arches: a covered walk above, a stair on each bank | `lc_arcade_upper` | `map_mods_a.py` |
| `chimney` | 1024 | a round yard on the right with a hollow brick chimney to climb: a lookout over the whole canal | `lc_chimney_top` | `map_mods_a.py` |
| `crypt` | 1024 | the left wall broken into a church crypt: pillars, coffins, an altar, a tunnel to Ravenholm's church in its walled graveyard behind | `lc_church_altar`, `lc_church_grigori`, `lc_church_side_door`, `lc_crypt_altar` | `map_mods_a.py` |
| `lift` | 1024 | EXPERIMENTAL: a freight lift from the canal floor up to a loading dock with a street gate (a cap to delete) | `lc_lift_button_high`, `lc_lift_button_low`, `lc_lift_button_ride`, `lc_lift_counterweight`, `lc_lift_dock`, `lc_lift_platform`, `lc_lift_street` | `map_mods_a.py` |
| `barge` | 1280 | a river barge grounded askew: a hideout in its hold, a wheelhouse, a gangplank from the bank | `lc_barge_hold`, `lc_barge_wheel` | `map_mods_a.py` |
| `busbridge` | 1024 | a bus hanging nose-down from the left street: climb through it to a pavement and a street doorway (a cap to delete) | `lc_bus_street`, `lc_bus_top` | `map_mods_a.py` |
| `shell` | 1024 | a headcrab canister in the right bank: a crater, a cracked wall, the start of an infestation (no creatures) | `lc_shell_canister`, `lc_shell_growth`, `lc_shell_patch_1`, `lc_shell_patch_2`, `lc_shell_patch_3`, `lc_shell_patch_4` | `map_mods_a.py` |
| `aqueduct` | 1024 | a water trough crossing over the canal on two piers: a ladder to a walk along it, a leak and a pool | `lc_aqueduct_drip`, `lc_aqueduct_fall`, `lc_aqueduct_valve`, `lc_aqueduct_walk` | `map_mods_a.py` |
| `pipes` | 1280 | a tangle of service pipes: duck and weave along the floor, or climb to a plank along the main and a bridge | `lc_pipes_leak`, `lc_pipes_top`, `lc_pipes_valve` | `map_mods_a.py` |
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
| `swingbridge` | 1024 | a footbridge that turns on a pier: across the canal, or along it (experimental) | `lc_swing_arm_a`, `lc_swing_arm_b`, `lc_swing_bell`, `lc_swing_bridge`, `lc_swing_lamp_a`, `lc_swing_lamp_b`, `lc_swing_move`, `lc_swing_red_a`, `lc_swing_red_a2`, `lc_swing_red_b`, `lc_swing_red_b2`, `lc_swing_stop`, `lc_swing_wheel_a`, `lc_swing_wheel_b` | `map_mods_c.py` |
| `floodroom` | 1024 | a valve chamber that floods: a trap or a refuge (experimental) | `lc_flood_alarm`, `lc_flood_beacon`, `lc_flood_beacon_beam`, `lc_flood_cache`, `lc_flood_chamber`, `lc_flood_door`, `lc_flood_door_out`, `lc_flood_drain`, `lc_flood_fill`, `lc_flood_klaxon`, `lc_flood_knock`, `lc_flood_rush`, `lc_flood_valve_a`, `lc_flood_valve_b`, `lc_flood_water` | `map_mods_c.py` |
| `railbridge` | 1024 | a railway bridge: a Combine train crosses every few minutes (experimental) | `lc_rail_dust_1`, `lc_rail_dust_2`, `lc_rail_dust_3`, `lc_rail_horn`, `lc_rail_p1`, `lc_rail_p2`, `lc_rail_p3`, `lc_rail_p4`, `lc_rail_run`, `lc_rail_shake`, `lc_rail_signal_1`, `lc_rail_signal_2`, `lc_rail_timer`, `lc_rail_train` | `map_mods_c.py` |
| `execwall` | 768 | the firing wall: a backstop, three posts, one hard lamp (left) | `lc_execwall_lamp`, `lc_execwall_line`, `lc_execwall_post_1`, `lc_execwall_post_2`, `lc_execwall_post_3` | `map_mods_d.py` |
| `substation` | 1024 | the substation: transformers behind the Combine's fence, a fuse panel to break (right) | `lc_substation_cut`, `lc_substation_fuse`, `lc_substation_gate`, `lc_substation_glow`, `lc_substation_hum`, `lc_substation_lamp`, `lc_substation_light_1`, `lc_substation_light_2`, `lc_substation_smoke`, `lc_substation_spark`, `lc_substation_spark_t1`, `lc_substation_spark_t2`, `lc_substation_spark_t3` | `map_mods_d.py` |
| `breach` | 1024 | the breach: the floor fallen into an old cellar, slabs for ramps, an undercut | `lc_breach_bottom`, `lc_breach_stash` | `map_mods_d.py` |
| `wreck` | 1024 | the wreck: a Combine carrier's container down in the canal, hollow, to race for | `lc_wreck_beacon`, `lc_wreck_cache`, `lc_wreck_spark` | `map_mods_d.py` |
| `morgue` | 1024 | the morgue: a cold room of drawers and tables behind a sliding door (left) | `lc_morgue_chute`, `lc_morgue_door`, `lc_morgue_ledger`, `lc_morgue_table_1`, `lc_morgue_table_2`, `lc_morgue_table_3` | `map_mods_d.py` |
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
Named for the game: lc_drain_grate (a func_door: Open lifts it, Close drops it; unseen, the four bar panels riding
on it), lc_drain_junction (the chamber), lc_drain_cache (the case at the bottom of the sump: a place the game can
fill).
Left as brushes: the mouth, its collar and arch, the chamber, the sump and its steps, the plugs that darken the
inflow pipes' insides, the stair, the sewer channel's walks and arch, the sewer end's cap.
Unchecked: ambient/water/water_flow_loop1.wav, ambient/water/drip_loop1.wav; the water running from the pipes is an
env_steam aimed down and out (as the owner's map aims its jets: Half-Life 2 has no falling-water material), how it
reads is not seen; that the concrete pipe is open at both ends (a dark plug closes its back, against the wall).

### `overflow`

2. The overflow toward Ravenholm. A spillway in the left wall, its apron stepping down into the canal, shut by a
steel sluice plate on two lifting rods under two of the canal's winches on a ledge, a chain and padlock slung
between the winches, caged red lamps either side, danger signs and rust stains on the wall; a lever on the wall
by it, padlocked like the winches until the game unlocks it. Driftwood (the coast's own), a pallet and two bodies
lie against the plate. Behind the plate a ribbed channel runs on to a cap ("delete to join Ravenholm"), a shallow
strip of water down its middle (where the channel is long enough), and it says Ravenholm the moment the plate lifts: Half-Life 2's own Ravenholm sign
on its wall, blood on the walls and the floor, a headcrab canister come through its roof, a zombie's torso and a
burnt body under it, a wheelbarrow on its side, rags; one oil lamp still burning low, one caged lamp dead.
"overflow 1280": how far the channel reaches from the canal's middle (default 1024).
Along the right wall a walk (walk_ledge: 72 wide, 208 up, the city's handrail on it, stairs at its near end, its
far end railed), the bank stopping either side of it in slopes: where the sluice keepers watch the plate.
Named for the game: lc_overflow_sluice (a func_door: Open lifts it), lc_overflow_moan (a sound from beyond the
plate, silent until told: PlaySound), lc_overflow_far (the channel's far end), lc_overflow_lever (the lever by the
plate, a button that starts locked: Unlock lets players lift and drop the plate by hand, Lock takes it back;
lc_overflow_lift and lc_overflow_drop are its two relays, taking turns).
Left as brushes: the weir, its sill, apron and frame, the ledge the winches stand on, the channel and its ribs, and
the sluice plate with its rods (a slab of steel 384 wide and 176 high: no model is a plate that size; the canals'
bar panels are bars, and stacked to that height they would rise out over the wall's top when it lifts).
Unchecked: ambient/creatures/town_zombie_call1.wav, models/humans/charple02.mdl, the zombie torso as a ragdoll, the
chain's material (cable/chain.vmt) on a rope; which way winch02 and the Ravenholm sign face.

### `shanty`

4. The shantytown under a street bridge. The canal widens into a basin on its left; a boardwalk runs along the
basin's back, with three shacks on it built from pieces (map_mods_c.shack: corner posts, walls of mismatched sheets
of wood, tin, steel hull and a salvaged door, uneven tops, tin roofs sloping to the front and overhanging on posts of
their own, a window each, boarded or of cracked glass): a card room (a table, two chairs, a radio on the table, the
canals' own map on the back wall, a lantern), a trader's stall open at the front (a long table for its counter,
shelves on its back wall with jars and cans, a painted board over it, a cart and crates outside) and a bunk room
(two bed frames, mattresses on them, a crate with a lantern between them). Under the street between them, a fire drum
with seats round it and a stove with its chimney pipe. A plank fence against the wind at the basin's edge east of the
street; a string of bulbs on a cable from an old dock pole to the bridge's deck and on to a second pole; washing on a
line from the card room's roof post to a pole; a boat pulled up; a cork notice board on two poles; posters on and in
the card room, the lambda on the bridge's pier, trash and puddles on the basin's floor. In front of the card room the
basin's floor is left clear for the Resistance's flag.
Named for the game (places only): lc_shanty_cards (the card room's table), lc_shanty_fund (the stall, for the fund's
screen), lc_shanty_soup (under the street, for the soup), lc_shanty_fire (the drum), lc_shanty_board (the notices),
lc_hq_setup_shanty (where the game stands the Resistance's flagpole when a territory covers the shanty town: the
basin's open floor, 64 clear all round, open to the sky).
Left as brushes: the boardwalk, the shacks (sheets, posts, roofs: no model is a shack's wall), the board over the
stall, the washing on the line (no game has a model of clothes on a line), the street bridge.
Unchecked: ambient/fire/fire_small_loop2.wav, env_smokestack, the cables (move_rope), sprites/light_glow03.vmt;
where on prison_bedframe001b a mattress lies (the mattresses are loose: they fall onto the frames).

### `vort`

6. The vortigaunt culvert: a low side drain in the left wall with the city's pipe along its wall under the roof
(capped where it starts), turning twice (nobody in the canal can see or shoot into its end); a green glow leaks round
its first turn to draw people in; a hanging of thin cloth strips on a cord half across its last turn (people brush
through it); and a dead-end den: damp brick walls, broken through into earth and rock in its back corner; a ring of
stones round a fire with a pot hung on a tripod, steam rising from it; three old mattresses for mats; shelves on its
wall with jars and a pot; bones and an antlion's shell by the rocks, firewood, a few candles; a seep of water in one
corner glowing faintly green (the vortessence pool: small green glows over it, a green beam on the wall behind).
Named for the game: lc_vort_fire, lc_vort_seat_1 to _3 (the mats, facing the fire), lc_vort_npc (where a
vortigaunt the game makes would stand, facing the fire).
Left as brushes: the culvert and the den and their linings, the hearth's slab, the tripod's three sticks and its
rod, the candles (no model of one), and the hanging of strips (Half-Life 2 has no cloth: a func_illusionary of
carpet, nobody is stopped by it).
Unchecked: env_fire, env_steam rising, ambient/fire/fire_small_loop2.wav.

### `relay`

7. Cubbage's relay. A concrete quay against the right wall, 128 high, with a stone coping, three mooring cleats and
an iron ladder down its face, two tyres for fenders, steps up its upstream end with a solid side; and on it a radio
shack built from pieces (map_mods_c.shack: mismatched sheets, a tin roof on posts, a boarded window), netting thrown
over its roof against eyes above: inside, the set on a table under a desk lamp, its dials glowing, a receiver and a
logbook by it, a chair, a cot (a bed frame), a shelf of car batteries, the canals' map pinned on the back wall, a
poster beside it. Beside it the mast: one of the city's tall utility poles (utilitypole01a, about 230 over the
canal's walls) with two small dishes on it, an aerial on the shack's roof, guy wires to the quay and the wall, a red
lamp at its tip (shielded from above), a long-wire aerial from the tip across the canal to the far wall and the feed
from the shack up to the pole. A diesel generator (generatortrailer01) hums behind the shack under a lean-to, its
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
console, a monitor and a health charger on the wall; stairs from it to a walk along the wall's top behind the
Combine's railing, a parapet before it, two Combine floodlights on its ends for the searchlights. Under the walk on
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
env_dustpuff, ambient/creatures/flies1.wav, physics/concrete/rock_impact_hard1.wav, nature/blendrubbleash001a
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
Wading is in the water (the game can tell: a player's water level); the ledge, the planks and the gallery are dry.
Named for the game: lc_hive_boss_spot (the island), lc_cistern_gallery (the head of the stair).
Left as brushes: the tank, its round wall and kerb, its gallery's ring, the landing and the stair and its plate, the
plank walks and their posts (decks on piers), the shaft's grate, the pillars, the plugs that darken the inflow
pipes.
Unchecked: ambient/water/water_flow_loop1.wav, the chains (cable/chain.vmt on ropes), the water pouring (an env_steam
aimed down and in), func_dustmotes in daylight.

### `underpass`

13. The barnacle underpass: 1024 of canal under a wide road, unlit. Three piers stand down its middle, chamfered
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
Left as brushes: the road over it, the piers, their caps and the girders, the fallen slab.
Unchecked: npc_barnacle (and whether the game minds NPCs it did not make), models/humans/corpse1.mdl and
charple01, charple03, ambient/atmosphere/tunnel1.wav, env_dustpuff, the cables (move_rope); the rebar is laid on its
side (pitch 90), centred on its origin; the sign and its pole are loose, laid on their sides, and settle.

### `tram`

The fallen tram bridge. A tram line crossed the canal here, 96 over its floor; its bridge is gone but for a stub
of deck at each wall, one whole girder on a pier and one that sags. In each wall a station opens: a short mouth, then
a hall with a platform 64 high either side of a track pit, dressed in Half-Life 2's own station kit: its cast iron
columns (trainstation_column001) carrying its arches (column_arch001a between them, ceiling_arch001a to the back
wall) under a girder across the hall, a plaster ceiling, walls in two tones as the city's station (brick to the
shoulder, a rail, plaster over it), its wall lamps (light_128wallmounted001a) each with a beam down on the platform,
its indoor benches, bins and payphone, route signs and the city's notices on the walls. Episode Two's own passenger
car, crushed and its front end torn off (passengercar001_dam01b), has come off the bridge: it lies across the canal
from the right bank's foot, where its open front end is on the floor, up over the left mouth's lip into the left
station, about 13 degrees, leaning 5 to one side; two of its seats and a suitcase spilled out of its open end. Walk in
at its open end and up through it into the left station (its doors there open onto the mouth's ledges, its far end
over the pit). The overhead wire still hangs from it, snapped, its live end spitting sparks on the canal floor. The
left station has a ticket booth with a barred window and, at the back, a stair up to the street behind a prison's
sliding gate with a danger sign over it, black beyond (lc_tram_exit); its pit ends in the line's own buffer stop and
steps up to a concourse, a signal on the far platform, the station clock stopped over the concourse. The right station
is reached only along the whole girder, a beam 16 wide and 368 long, 96 over the floor (steps at its end climb from
the pit to the platform): the same car whole (passengercar001) stands at its platform on two bogies with a cache in it
(lc_tram_stash), and somebody has been living on that platform (a mattress, a fire in a drum, a lambda on the wall).
Dropping from either stub is safe. Sounds: the station's own soundscape in each hall (d1_trainstation.Turnstyle, which
the owner's map uses), the metal groaning over the wreck (coast.util_metalstress).
Named for the game: lc_tram_exit (an info_target on the left platform before the barred stair: where people come
from or go to the street), lc_tram_stash (an info_target inside the car in the right station: a cache).
Left as brushes: the stations' walls, platforms, steps, tiles and girders (architecture), the bridge's deck, girders
and pier (a building's frame), the rails (no single track narrower than 288 exists as a model), the booth's walls.
Unchecked: the cars are Episode Two's (players without it see errors; the owner asked for them); that the cars' own
collision lets a player walk inside them, where their doors are and that the wreck's floor walks well at 13
degrees; how high the car's floor is inside (the platform is 12 over its underside); which way the wall lamps, the
benches, the signal, the clock and the payphone face (set by their boxes); that the columns, sunk 40 into the
platform so their heads meet the roof, and the arches under it read as meant; the light_256ceilingmounted001a lamp
the review named hangs 320 and does not fit under these roofs, so it is left out.

### `tenement`

The fallen tenement. A block that stood on the left street has gone into the canal and lies across it from u 320
to 960: there is no way round, the way on is through its rooms. It came down tilted: every floor in it leans 5
degrees down toward the left bank (32 over its 352 depth), the furniture has slid to the low side, the tallest wall
in it leans over the kitchen, a crack runs across the kitchen's ceiling with daylight through it, and the canal's
water has crept into the low side of the hall. Its body fills the canal from the right wall to v 128; the strip left
over by the left wall is choked by its own outer wall, fallen in slabs (with an unseen wall for players in it). Its
face to the canal at each end is a tenement's (a plinth, a string course, windows with sills and lintels, broken),
and the ways in are holes torn in it, ragged, rubble and rebar at their edges. Ground floor, 112 high: an entry hall,
a living room, a kitchen, a stair hall open to the leaning roof, a bedroom, a back room, a small room with a bed,
and behind that a nook that is easy to miss (a crawl hole by the bed, or a hole in the floor above):
lc_tenement_stash. A stair climbs to the one room left upstairs, a sentry's chair and binoculars at its window over
the canal the far way (lc_tenement_lookout); out of that window is a drop, never a way in. The rooms are the city's
flats: plaster in two tones split by a dado rail, wood floors, door casings proud of the walls, a radiator under
the window, posters and a radio. The roof is sheared slabs lying where they slid. Where the block stood, the left
wall is bitten out down to the trim, with its cellar walls and floor beams left. It creaks (d1_town.WoodBuilding).
The way through, door by door (wide, and high over the tilted floor at its lowest): the hole in the entry wall about
74 by 90; hall to living room 48 by 84; living room to kitchen 48 by 84; kitchen door to the stair hall 48 by 84;
stair hall to bedroom 48 by 80; the hole in the far wall about 74 by 90. A short cut from the hall to the stair hall
is a crawl, 48 by 42; the nook's crawl is 40 by 42.
Named for the game: lc_tenement_stash (an info_target in the nook: a cache), lc_tenement_lookout (an info_target
at the upstairs window: a sentry's place).
Left as brushes: the block itself (its walls, floors, stair, the roof's slabs and the outer wall fallen in slabs),
its trims (plinth, string course, sills, lintels, dado rails, door casings), the cellar walls and joists in the
bite. Its furniture is the game's own (couches, radiator, stove, sink, a fridge on its back, tables, chairs,
dresser, bed, shelf, a radio, mattresses turned the right way up), and rubble, rebar and a torn ceiling of the
game's lie where it struck.
Unchecked: that the crawl holes pass a crouched player in the game as they do on paper; how the furniture models
face; that the tilted props (the fridge, a fallen chair, the hanging lamp) lie as worked out; how destroyedceiling01a
looks round the living room's hole; that nobody can get onto the roof (unseen walls stand over it in case).

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
own visgroup ("the quay's street end (delete to join a street)"). From the quay a footbridge on two trestles,
railed both sides, crosses to a barred door of Nova Prospekt's in the right wall: behind it a short passage to the
city's locked store for the quay (the Combine's supply crates on shelves, a lamp left on), seen through the bars.
Sounds: the quiet courtyard up on the quay, the watery hallway down in the canal (both the owner's map's own).
Named for the game: lc_quay_street (an info_target in the street doorway, facing the quay: where people arrive
from the street), lc_quay_far_door (an info_target on the bridge before the barred door).
Left as brushes: the stairs and their solid side, the landing, the quay's low wall, the doorway's frame, the
store's walls, the footbridge's deck, girders and trestles (a structure, no model fits 512 by 64).
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

### `scrapyard`

The scrapyard. The canal widens 384 on both sides into a yard of dirt where the Combine dump what they clear from
the streets: the game's own shipping containers (133 by 388 by 130; the open ones hollow, to walk into), some of them
dumped off the square, wrecked cars stacked two high, tyres, and a tower crane on a plinth in the far right corner
whose jib reaches over the yard, Half-Life 2's crane magnet hanging from it on its cable over the open ground (its
hook lies in the dirt). Oil stains, puddles and trash on the ground. It is lit as a yard is: a floodlight on the
crane's cab and a lamp cluster on a utility pole at three corners, each throwing a beam down into it. In the right
corner by the entry the foreman's office, a wooden hut with a window over the yard: a desk, a radio, a filing
cabinet, a calendar on the wall, a bare bulb. The yard groans (coast.util_metalstress).
On the ground: a container lies across the canal at each end of the yard (the near one open toward the left bank,
the far one shut): go round their ends. Between them one lies along the middle, open toward the entry, a door swung
out; left and right lanes run past more containers, open ones to hide in, and round the stacked wrecks. Nothing
gives a straight view from one end to the other.
Over the top: a ramp of planks at each end (130 up over 256) to the roof of the container lying across; from the
entry one plank bridges on to a covered porch on the middle stack and one to the left stack, where a ramp (130 up
over 192) climbs to the roof of the second level; a ramp from the far container's roof climbs there too. From that
roof a plank crosses to a ledge on the middle stack, and a ladder climbs the last 130 to the top of the third
container (lc_scrap_perch, z 790: level with the canal walls' tops, the whole yard under it), with sheets of metal
to crouch behind. The second container of the middle stack is open toward the exit: a nest reached from its ledge.
Named for the game: lc_scrap_perch (an info_target on the highest container: a sniper's or a lookout's place).
Left as brushes: the plank ramps and bridges and their cleats (walkways; a board model is 128 long at most), the
crane's plinth, lattice tower, cab and jib (no crane model fits under the sky), the office's walls and roof.
Unchecked: which end of cargo_container01b and 01c is open (taken to be the +y end, where the model is 3 longer)
and that their insides walk; the ladder on a container's end; that two planks 22 wide side by side walk as one
ramp; how the wrecks, the magnet, the floodlights and the desk face; where the lamp cluster sits on its pole (set
by their boxes). The magnet only hangs: making it lift (a phys_magnet) is left for later.

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

### `arcade`

The market arcade: an old covered market built over the canal on three stone arches (u 640 to 896). Below, the
canal passes between two piers 64 thick with cutwaters: a middle arch 128 wide over the flat of the floor, a side
arch over each bank; a keystone of lighter dressed stone at the crowns, a trim along the deck's edge, a caged lamp
on each pier lighting the middle arch, water stains down the piers. Above, at the trim's height, a covered walk 256
wide crosses from wall to wall under a pitched tin roof on columns: open bays with a parapet 36 high look up and
down the canal, three stalls (the game's kitchen counters) stand down its middle, each under an awning with a few
goods on it (melons, a pot, a crate), lamps hang under tie beams across the walk, and barred shop fronts (the city's
own bars) close its two ends: through the bars a shallow shop each side (plaster in two tones, a counter, shelves
with a jar or a jug left, a dead lamp). It is reached by a stair along each wall, railed, its open side solid from
the floor: on the left bank from the entry side (u 256 up to 640), on the right bank from the exit side (u 1280 down
to 896), so each end of the canal has its own way up. Two levels to fight over: whoever holds the walk sees both
approaches, whoever is below has the piers. It creaks above (d1_town.WoodBuilding) and drips below
(prison.watery_hallway).
Named for the game: lc_arcade_upper (an info_target in the middle of the walk).
Left as brushes: the piers, arches, keystones, deck, parapets, columns, brackets, tie beams and roof (the building),
the shop fronts' frames and the shops' walls.
Unchecked: the look of stone/stonewall040f on the piers and arches; how the bin, the pushcart, the counters and
the awnings face; which end of handrail04_doublerise is its high end (see wall_stair).

### `chimney`

The chimney. The canal widens to the right into a round yard 896 across, its wall faced with straight segments
drawn through the inner corners of the squares' steps (so it reads as a many-sided court, not a staircase), the
canal's lip carried round it at the trim; in its middle stands what is left of a factory: its brick chimney,
eight-sided, hollow (200 across inside), on a stone plinth 320 across with a coping, tapering to its top 624 over
the canal floor and 240 over the canal walls' tops, built in courses as a works chimney is: dark brick with two bands
of light stone and three iron hoops, a corbelled crown flaring out under the gallery, a lightning conductor down its
back. A doorway 48 wide and 96 high at its foot faces the canal. Inside, slabs of stone climb round the wall in
thirteen short flights (five treads and a landing in each corner, 48 up a side, an open well down the middle with the
old hoist rope hanging in it from a pulley under the cap) to an iron gallery round the chimney's top: plates to crouch
behind on four sides, the city's handrails on the other four and round the stair's head, a cap on four posts, a pair
of binoculars left there. From up there the whole canal both ways is in view: a sniper's nest with one way up
(lc_chimney_top). In the yard, the works that was: a brick wall with two arched windows, broken off at the top, a
leaning piece of another, the pulley wheels of its machinery, drums, a skip, a car. Sounds: the quiet courtyard down
in the yard, the wind on a rooftop up on the gallery (both the owner's map's own).
Named for the game: lc_chimney_top (an info_target on the gallery).
Left as brushes: the chimney, its plinth, courses, crown, door frame and stair (the building), the gallery's floor,
its parapet plates, the cap and its posts, the yard's facing wall and lip, the works' broken walls.
Unchecked: that the corner landings turn a player comfortably (about 38 of clear floor between the well and the
corner's wall); how the taper and the courses look in brick and stone; whether the map's fog or far plane hides
the canal from up there; how the binoculars and the pulley wheels face. The courses' joints step 1 unit between
neighbouring sides (so no two faces share a plane): too small to see.

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

### `lift`

The freight lift (experimental: nothing like it has been compiled yet). A loading dock is recessed into the
left wall at the trim's height, 448 by 320 and open to the sky: a low wall along its edge, a van backed up to the
lift with its back open, the Combine's supply crates on a pallet, a clipboard on the wall, a street gate (the city's
own fence gate, 128 square) with a Breen poster by it, one of the city's street lamps. The gate and the cap behind
it are in one visgroup ("the dock's street end (delete to join a street)"). Against the wall below the dock, where
the bank is cut away, a lift platform 160 square with the city's handrails on three sides (riding on it; an unseen
rail in the platform does their blocking) rides between four guide posts from the canal floor (its deck 8 over the
floor) up 256 to the dock (its deck 8 over the dock's: a step down). It hangs from cables run over the sheave at the
frame's head, beside the motor's housing, and their low ends ride with it; a counterweight falls in its channel
against the wall as it rises; a caged lamp lights the frame at each level. It is one func_door,
lc_lift_platform, that stays where it is sent; each of three buttons sends it to its other end (Toggle), and the
counterweight with it: one on a post at the bottom, one on a post on the dock, one on a stand on the platform that
rides with it. Its own moving sound is a motor's, looping while it moves, and a clank when it stops. Sounds: the
quiet courtyard on the dock, the metal's groan by the lift.
Named for the game: lc_lift_platform (func_door: Open is up, Close is down, Toggle), lc_lift_counterweight (a
func_door that moves the other way: Toggle with the platform), lc_lift_button_low, lc_lift_button_high (func_buttons
that already work), lc_lift_button_ride (a func_button parented to the platform), lc_lift_dock (an info_target on
the dock), lc_lift_street (an info_target at the street gate).
Left as brushes: the platform's deck and the stand its button sits on (what the game moves), the counterweight and
its channel, the guide posts, their ties, sheave and the motor's housing (the lift's frame), the gate's frame, the
dock's low wall, the buttons' posts.
Unchecked: that the handrails and the cables' ends parented to the platform ride with it smoothly; that a func_door
carries players up 256 smoothly and reverses if someone stands under it (it does no harm: dmg 0); that the button
parented to it follows and still takes a press; that the counterweight keeps time with the platform (both take
about 5.4 seconds); the sounds plats/elevator_move_loop1.wav and plats/elevator_stop1.wav; the buttons' model is
Episode Two's; which way the van faces (taken to be its +x).

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

### `busbridge`

The bus. A city bus has gone through the left street's parapet and hangs nose-down from the wall's lip to the
canal floor: a hollow body of brushes (no bus model exists in any of the games; the trailers are closed boxes),
sheared (its floor climbs 248 over a run of 310, about 39 degrees), built as a bus is (BusBody): skirt panels in one
colour to the window line with an arch over each wheel and the truck tyres half hidden in them, a belt strip, window
posts and a header in a second colour, a roof with rounded edges, a front door and a middle door, its front with the
windscreen's frame (the glass gone), a grille crushed into the floor and the destination board, its back with the
engine's grille and the rear window's frame. Inside, the old train's bench seats along its sides tilted with its
floor, the driver's chair at its foot; its windscreen end is open on the floor at v -54, its luggage spilled out
there; its back axle is caught on the lip. Climbing through it is a way UP: its back end comes out on a short
stretch of pavement recessed into the wall at the trim's height (256 by 128, open to the sky, the fence gone, what is
left of the parapet either side with its rail broken off over the gap, one of the city's street lamps knocked askew
and dark, a bus stop's sign on its pole and a shelter over its bench, the timetable on the wall), with a street
doorway behind closed by a cap of the world in its own visgroup ("the bus's street end (delete to join a street)").
The scrape where it slid is cracked down the wall under the lip. The canal stays passable under the bus's high end by
the left bank and round its nose on the right. Sounds: metal groaning (coast.util_metalstress), the quiet courtyard
up on the pavement.
Named for the game: lc_bus_top (an info_target on the pavement where the bus comes out), lc_bus_street (an
info_target in the street doorway, facing the canal).
Left as brushes: the bus's body (no model of one), the pavement, the parapet's stubs, the shelter, the doorway's
frame, the slabs on the floor.
Unchecked: that the sheared floor walks well and the tilted seats do not snag a climber; which way
traincar_seats001 faces; that players fit under the high end (72 clear from v 66 to the bank); the two colours
(metal/metalwall030a below, metal/metalhull010c above: the owner's own metals, chosen unseen). Each layer of the
bus's sides stands a unit off the next (so no two faces share a plane): too small to see.

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
left wall beside the walk (lc_aqueduct_valve, a momentary_rot_button: hold E to turn it) drains the trough and the
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

### `pipes`

The pipes. A tangle of the city's service mains fills a stretch of the canal: steel pipes 87 across (solid,
eight-sided, in the owner's own pipe steel), a flange every 128, every end shut by a bolted plate, stencilled
numbers on their sides.
On the floor: one main lies across the whole floor at u 480 with 54 under it, and the fat main along the left side
has 66 under it: everyone on the floor ducks once. Past it two mains on the floor (86 high, too high to hop) make a
chicane: the first reaches from under the main to v -30 (go round its end on the right), the second from the right
wall to v -31 (go round on the left, by the main). A run of the city's pipes crosses high overhead.
Over the top: a steel service stair (grating treads on two stringers, the city's rail on its open side; u 96 to
324, by the left side) up to a valve platform 152 over the floor, with a valve, a gas meter and a lamp; from it a
plank 32 wide with the city's handrail runs along the top of the main (u 428 to 878); a grating bridge, railed,
crosses the canal there to a second fat main on the right, and from its end a ramp of planks (144 down over 244)
comes back to the floor at u 1192. That is also the only way for anyone who cannot duck.
Two steam leaks on the main: a pale one with a hiss, and one at a joint by the bridge (lc_pipes_leak) that the
wheel by the platform's valve shuts and opens again (lc_pipes_valve: turned all the way the steam stops, turned
back it starts again). Risers of the city's pipe up the walls, each
with a caged lamp. The mains are cover from end to end, and the plank is a firing step over all of it
(lc_pipes_top). It hums like a pump room (d1_canals.waterpuzzleroom).
Named for the game: lc_pipes_top (an info_target on the main's plank), lc_pipes_leak (an env_steam: TurnOn,
TurnOff, Toggle; it starts on), lc_pipes_valve (a valve wheel, momentary_rot_button: hold E to turn it; Valve's wiring, the owner said go ahead).
Left as brushes: the mains, their flanges and end plates (no pipe model of the game is 87 across), the saddles and
posts they rest on, the platform's deck and posts, the stair's treads and stringers, the bridge's grating and
girders, the planks.
Unchecked: the sound ambient/gas/steam_loop1.wav; that 54 and 66 of headroom pass a crouched player easily; that
the 86-high mains cannot be hopped; what pipeset32d_512_001a looks like overhead; where handrail04_doublerise's
posts meet the treads; the button's model is Episode Two's (the shared helper's choice). The leak does no harm:
the game can add a hurt to it if it wants the valve to matter.

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
on the opposite rim watching. Quiet, poor, lived in (d1_trainstation.QuietCourtyard).
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
wheel on the thick one (lc_stash_valve: Use turns it a quarter, and it turns back by itself), and for the
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

Inside the lock, on the left bank, a concrete pier (the bank is its ramp, a mooring cleat on it) and stairs up to
the gantry behind a concrete parapet; on the gantry, behind the city's handrail, the house, concrete with steel
plate to the waist inside: a slit each way down the canal, a button under each slit's end for the gate on that side
with a lever panel beside it and two lamps over it (green while that gate is open, red while it is shut), the
canals' own map on the wall, switch boxes, a desk with a monitor and a chair, a fluorescent tube. On the left wall at
the gantry's end a street doorway that is never used: planked over, boards nailed across. The right half of the gantry
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
front wall, runs along the canal wall and crosses the canal overhead on a pipe bridge nobody can reach. A steel
gallery runs round the hall 144 up behind the handrail (stairs in the corner left of the door, a steel plate along
their open side); on it, over the door, the control desk: a monitor, a lamp, and the button that stops and starts
the pumps. The door that shuts the doorway (a sliding gate) stands slid open along the wall inside.

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
128 over the floor (the bank is its ramp). On it, behind the Combine's own fence (combine_fence01b and 01a posts, the
owner's field between them) with a gate players open (Nova Prospekt's gate in its frame, between two of the posts),
Half-Life 2's own thumper (prop_thumper, the coast's CombineThumper002, 338 high) on a concrete plinth, fed by a fat
cable from a Combine generator: it lifts and drops its hammer by itself, shakes the ground, thuds and keeps antlions
away, for ever. Each time it lands dust jumps from the plinth. Against the terrace's near wall a Combine console,
the Combine's lamp over it and a small screen beside it, and the button that stops and starts it; Combine lamps and
a camera on the terrace's back wall, danger signs. Why it is here is shown downstream: sand drifted over the canal's
floor toward the exit, a burrow broken through the left wall's foot with sand spilling from it, two dead antlions.

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
models/antlion.mdl as a ragdoll; nature/blendsandmud001a (which of its two shows at alpha 0); combine_shield_loop3.wav.

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

### `swingbridge`

EXPERIMENTAL: a footbridge at the trim's height that turns on a round pier in the middle of the canal. As the
map starts it lies across, from a landing in the left wall to one in the right; turned a quarter it lies along the
canal and joins nothing. Each landing is a roofed alcove with a street doorway that is never used (planked over,
boards nailed across), a green lamp that shows while the bridge is across and a red one while it is turned away
(and a railway signal head on the wall beside the landing), a striped barrier arm across the landing's edge that
drops while the bridge is away, the city's handrail each side of the bridge's end, and at its back wall the canal's
winch with the button over it that turns the bridge (a press rings a bell, and two seconds later is Toggle). Each
has its own stairs from the canal floor: a covered flight in the wall, open to the canal on its side behind a
concrete parapet, running away from the bridge (the left one toward the module's exit, the right one toward its
entry). Whoever turns the bridge away strands the other bank at that height.

The bridge is 456 long and 64 wide: a plank deck on two steel beams with a truss of posts and a bottom chord under
each and a counterweight under its right end, one func_door_rotating, with the city's handrail along both sides
riding on it (prop_dynamics parented to it). It turns on a drum: a wide cap on the round pier with a toothed ring
round it and a motor box driving a pinion. Its corners sweep a circle 461 across;
the canal is 512 wide and the landings' lips stop 234 from the pier's middle, so it sweeps through nothing (ribs
and drain stubs are kept off the walls there; the walls' trim line stands 240 out). A gap of 6 is left at each end.
It has no damage of its own.

Named for the game:
  lc_swing_bridge    the bridge: Toggle (or Open: along the canal; Close: across). 12 degrees a second.
  lc_swing_wheel_a   the button over the winch on the left landing.     lc_swing_wheel_b   the same on the right.
  lc_swing_lamp_a, lc_swing_lamp_b   the green lamps (env_sprites): lit while the bridge is across.
  lc_swing_move, lc_swing_stop       the turning sound (looping) and the clank as it comes to rest.
  lc_swing_bell      the bell a press rings before the bridge moves.
  lc_swing_red_a, lc_swing_red_b     the red lamps (env_sprites): lit while the bridge is turned away.
  lc_swing_arm_a, lc_swing_arm_b     the barrier arms (func_door_rotating, no Use): Close drops one across the
                     landing's edge, Open lifts it; the bridge works them (drawn down, the map lifts them as it starts).

Unchecked: a func_door_rotating this big, turning about its middle with people on it: the engine carries riders
round on a turning brush, but how well is only seen in the game. Spawnflags 32 (toggle) and no Use; outputs OnOpen,
OnClose, OnFullyOpen, OnFullyClosed for the sound and lamps. With "wait" -1 a blocked door does not turn back: it
waits, pushing. Sounds are the bunker door's (heard there). That handrails parented to the turning bridge turn
with it (props ride on doors so). Which way the winch faces. Which way the arms swing (spawnflags 64 or 128: about
the canal's axis across the landing; if they swing down through the floor, add 2, Reverse). ambient/alarms/warningbell1.wav.

Left as brushes: the bridge's deck, beams, truss and counterweight (a bridge deck), the pier, its drum, toothed ring,
motor box and turntable, the landings, their lips and corbels, the stairs and their parapets, the doorways' jambs
and planking, the barrier arms (dev_hazzardstripe01a).

### `floodroom`

EXPERIMENTAL: a valve chamber that can be flooded: a trap or a refuge. Off the left wall a short passage, a
steel door (lc_flood_door, open: Nova Prospekt's sliding door between steel jambs) and steps down into an
eight-sided chamber 384 across. A steel gallery runs round it 96 over its floor behind the city's handrail (stairs
up to it inside the chamber, a steel plate along their open side); from the gallery's far side a passage leads
round the chamber and back to the canal through a second door (lc_flood_door_out, one of the city's doors: Use
opens it), steps up from the canal's floor. In the chamber's middle the main (the city's 32 pipe) stands from floor
to roof with a hand wheel on it (props_pipes valvewheel001, lc_flood_valve_b) and a small wheel on the gallery's
wall (lc_flood_valve_a): turning either all the way floods the chamber (turning it back drains it): a klaxon sounds, a red beacon under the roof
starts turning and sweeps its beam round the walls, the steel door at the foot of the way in drops, then water
rises 90 from under the floor to just under the gallery, in about fifteen seconds. Pressed again, it drains (the
pipes knock) and the door lifts. Nobody is hurt: whoever is on the floor swims up to the gallery and walks out. The
chamber looks like it floods: a tide line round its walls at the gallery's height, silt on its floor, a grate by
the main, a danger sign by the door and a lock wheel beside it; a lost case lies on the floor (under water when it
is flooded: a reason to flood it, or to dive).

Named for the game:
  lc_flood_water      the water: a func_water_analog, its top 2 under the chamber's floor (so the two never share a
                      plane), rising 90 (Open floods, Close drains; 6 a second).
  lc_flood_valve_a    the wheel on the gallery.      lc_flood_valve_b    the hand wheel round the main, at the floor
                      (both momentary_rot_buttons: hold E to turn; all the way floods, back drains).
  lc_flood_fill, lc_flood_drain   relays: Trigger one to flood or drain with the door and the sound. A press of
                      either button triggers both; only the one that makes sense is live.
  lc_flood_door       the door at the foot of the way in: a func_button used as a mover, as the bunker's (PressOut
                      shuts, PressIn opens; the map opens it as it starts), unseen, the door's model riding on it.
                      It has no damage of its own.
  lc_flood_door_out   the second door, at the canal: one of the city's doors (prop_door_rotating: Use; the
                      gamemode can lock it).
  lc_flood_rush       the rushing sound, playing while the water moves.
  lc_flood_chamber    the middle of the chamber's floor.
  lc_flood_cache      the case on the chamber's floor (a place the game can fill).
  lc_flood_klaxon, lc_flood_knock   the klaxon as it floods, the pipes knocking as it drains.
  lc_flood_beacon     the beacon: a func_rotating under the roof (Start, Stop), carrying lc_flood_beacon_beam (a red
                      point_spotlight: LightOn, LightOff); lc_flood_alarm, a red light (TurnOn, TurnOff). The fill
                      relay starts all three, the water's OnFullyOpen stops them.
Areaportals: one in the way in, one inside the second door's thickness: both dry, both well away from the water.

Unchecked: func_water_analog from memory ("movedir" up, "movedistance" 90, "speed" 6, "startposition" 0; inputs
Open and Close; outputs OnFullyOpen and OnFullyClosed). Its top is nature/water_canals_water_clear and its other
faces nodraw; if moving water will not draw with that material, a cheap water material is needed there. Whether
the engine lets a player surface cleanly 8 under the gallery. Sound from memory: ambient/water/water_flow_loop1.wav.
The main is pipeset32d stood on end (pitch 90), centred on its origin; the valve wheel is turned to face out of the
main's side (pitch -90): how it looks so is not seen. ambient/alarms/klaxon1.wav, ambient/materials/metal_stress4.wav,
a point_spotlight parented to a func_rotating (it turns with it in Half-Life 2's maps).

Left as brushes: the chamber, its gallery's grating, the steel plate along the stairs, the door's jambs and head,
the notch in the bank, the water.

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
arm on the wall and across the canal to an insulator on the far wall's top, a steel switch cabinet
(controlroom_storagecloset001a) with the fuse panel on its front and the Combine's meter box beside it, a caged
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
(the tables), lc_morgue_ledger (the desk), lc_morgue_chute (the chute's hatch: where the game sends the dead).
Left as brushes: the room, its tiles and plaster, the door's jambs and head, the drain, the wall of drawers (built
into the wall: Half-Life 2 has no morgue drawers), the chute's hatch and frame and the conveyor (no model of one).
Unchecked: models/humans/corpse1.mdl as a ragdoll laid on a table with its motion disabled (spawnflags 16388:
debris and motion disabled, so it stays where it is laid), func_dustcloud's keys for the mist; which way the
surgery table's head is (it is the same both ways in its size).

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
module must be a wide one ("wide", "widetee", a turn) or "narrow".

### `narrow`

The wide canal narrows back to 512: the mirror of "widen" (256 of the wide canal, two steps in, 256 of the city
canal), the banks starting again round the steps.

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
Shorter, or with no walk: Valve's Resistance boathouse (canals_06) on its piles against the left wall, an airboat
jetty (canals_05) and a timber lookout (canals_11) off the right wall, lifted whole (map_prefab.py).
Unchecked: the boathouse's physics props (drums, crates) as Valve placed them, over a dry canal floor.
