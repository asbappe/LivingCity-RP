# Set pieces in Valve's maps worth lifting

The owner, 23 November: "is there a way to find other unique assets in HL2, EP1, and EP2 that can be lifted for future
use? I'm sure there are tons I'm just forgetting". The way: `_dev/tools/map_setpieces.py` reads all 105 shipped maps of
HL2, Episode One and Episode Two straight from the owner's VMF zip (`HL2Leak-VMFs-master.zip`, on their Drive) and
finds every group of entities wired to each other, with the rare props standing round it. It scores each group by its
rare models (in one or two maps only), rare entity kinds, effects, machinery and size, less for story (scenes, scripted
sequences, Alyx and friends), keeps Valve's own visgroup names (they often say what it is), and marks groups inside a
piece we already hold. 621 groups scored 8 or more and are kept in `_dev/reference/valve_setpieces.json`.

    python3 map_setpieces.py ZIP                 scan again (about 30 s)
    python3 map_setpieces.py --top 60            the best, one line each
    python3 map_setpieces.py --map d2_prison_05  one map's groups
    python3 map_setpieces.py --find thumper      groups whose models, kinds, names or visgroups hold a word

Below: the ones picked by hand from the scan for Living City, by what they would be for. Each gives the map, the place
in Valve's coordinates (the scan's middle of the group: lift with a box round it, `docs/dev/prefabs.md`), what it is
(from Valve's names and models) and a use. None is lifted yet unless it says so; the owner picks.

## Already lifted

The Combine autogun (`valve_ep2_cannon`, ep2_outland_09), the vortigaunt torture cell (`valve_prison_vort_torture`,
d2_prison_03), White Forest's silo, rocket, blast door and Silo 2's doors, the radar cache cave, the Citadel's core,
doors, ball socket and dispensers and weapon check, Black Mesa East's airlock, lift ride and rooms, Nova Prospekt's
teleporter charge, the station's Breencast screen and playground, the canal and Ravenholm pieces (`docs/dev/prefabs.md`).

## The Combine at work (Union side)

| Map | At | What it is | For us |
|---|---|---|---|
| d1_trainstation_02 | -3720 -2108 80 | the ration line: citizens queue at a window (`ai_goal_actbusy_queue`) and walk off with a package (`w_package`) | ration hand-out at a Union window |
| d1_trainstation_03 | -4231 -4612 317 | the apartment raid: Civil Protection bursts into flats (`ai_goal_police`, "cop seq", the TVs) | raid scripting for a block |
| d2_prison_03 | -7521 13504 393 | a security camera that sends guards: `camera_2_soldier_spawner`, `camera_guard_template`, a spawn plug | stronghold cameras that call the Union |
| d2_prison_04 | -778 2532 266, -1191 1671 444 | turret spots with glow sprites; exit lights open and closed with a counterattack | prison wing defences |
| d2_prison_05 | -1664 408 545 | the kitchen turrets and a fire trap in the hall (with a microphone that sets it off) | cell block hazards |
| d2_prison_05 | -2798 348 766 | the crusher wall (a concrete column that breaks in four) | breach, prison break |
| d2_prison_01 | 1872 -2656 1756 | pipe room valves that shoot fire (`piperoom_valve1_firejet`), a propane tank that blows | a hazard a player can turn on |
| d3_citadel_01, 02, 05 | 10624 4505 -1663; -1025 6272 2744; 1306 -479 -2793 | the prisoner pods on their tracks, the zapper pods (`zapper_hurt`, sparks), stasis cores, the gunship bay | a Citadel transport or execution line |
| d3_citadel_03 | 6064 119 2208 | Breen's monitor consoles (`breen_monitor_console1` to 3) | Overwatch screens beside the Breencast |
| d2_coast_12, 11; d3_c17_05 | 4398 160 740; 3005 9912 535; 1598 -4452 144 | Combine thumpers (`prop_thumper`, `combinethumper001a`, a switch with its glow) | outpost thumpers that keep antlions off |
| d2_coast_08 | 3032 -2016 1801 | the bridge's force fields (`bridge_field_03`) and a rockfall | a Combine field gate |
| d2_coast_07 | 2184 4808 1712 | a dropship that drops soldiers (`dropship_guy`), field wall poles | Overwatch reinforcements |
| ep1_c17_06 (and ep2_intro) | 7584 10386 -266 | soldiers rappelling down ropes (`csoldier_rappel02`, `rope_10_start`); also ep1_c17_02b's rappel template | rappel drop on a raid |
| ep1_c17_00 | 4320 -2835 -57 | ceiling turrets (`npc_turret_ceiling`), stalker pods | Citadel and Nexus defences |
| ep1_citadel_04 | 3840 8122 3566 | the stalker train: cars with pods (`stalkercar`, `stalkerpod`) | a Combine train that carries stalkers |

## Battles and bombardment (events)

| Map | At | What it is | For us |
|---|---|---|---|
| d3_c17_02 | -6038 -5929 62 | the APC street ambush: an APC with rockets (`func_tankrocket`), storefronts and shop poles that break, ragdolls thrown | a street battle |
| d3_c17_10a | -2434 6824 537 | mortar strikes on a building (`func_tankmortar`), windows blown, the building burning, concrete chunks | a Combine bombardment |
| d3_c17_06b | 2179 1208 9 | a headcrab shell strikes the street (`start_street_crab_pod_fire_1`, the shooter, the scorch) | the headcrab shelling event |
| d3_c17_12 | -1828 6386 209 | a wall blown in with physics debris and pillar shooters | breach charges |
| d3_c17_12b | -5256 -409 135 | a tunnel and a ceiling blown in | collapse, sabotage |
| d1_canals_05 | 4248 2104 -416 | a cave-in: rockfall debris, dust, a shower of rock | collapse in the tunnels |
| ep2_outland_05 to 10 | (3D sky) | the portal storm in the sky (`fx_portal_storm`, rotating lightning) | a storm event over the city (it lives in the 3D sky) |

## The Resistance and citizens

| Map | At | What it is | For us |
|---|---|---|---|
| d3_c17_01 | -7030 -1512 60 | the hidden lab door: a picture that hides an eye scanner (`secret_picture_1`, `secret_scanner_1`, `eyescanner`) | a Resistance door only members open |
| d3_c17_01 | -6376 -1190 52 | Kleiner's mini teleporter (`miniteleport`, its arcs, the force) | a Resistance gadget room |
| d2_coast_09 | 10917 8834 -135 | the car battery puzzle: carry a battery to a socket, sparks, and the door's engine starts | a power-the-door job |
| d1_canals_05 | 5424 1243 -383 | the shanty's electrical puzzle (sparks, a blast when it shorts) | the same, in the canals |
| d2_coast_05 | -3935 -62 1149 | petrol pumps with buttons (three housings) | a fuel station that works |
| d1_canals_06 | 4591 5902 81 | a supply crate on a winch and pulley (`item_item_crate_dynamic`, `winch01b`) | a supply drop let down on a rope |
| d2_coast_01 | -7976 -8224 920 | the magnet crane (`cranemagnet01a`, a crane driver) | a dock crane that lifts cars and crates |
| ep1_c17_02a | -356 7699 -2482 (and round it) | the hospital: wards of beds, IV stands, carts, rails, power ropes, a door zombies break | the clinic's rooms |

## Infestation and hazards (Ravenholm, the outlands)

| Map | At | What it is | For us |
|---|---|---|---|
| d1_town_01 | 901 -729 -3673; 1555 -827 -3752 | Grigori's fire traps: a button, a gas hose, an ignition spark, a zombie cage | traps in the infested quarter |
| d1_town_02a | -7878 560 -3345 | the graveyard: graves, coffin pieces, propane fires, crows | the cemetery |
| ep2_outland_06 | 1894 458 -68 | a fire trap of gas hose and propane, trash thrown at the player | a scripted ambush |
| ep2_outland_03 | 1056 -4512 -959 | a pit trap: boards on hinges that drop the player into a pit | a trap in the tunnels |
| d3_c17_08 | -960 -1600 94 | planks swinging on ropes (`underground_rope_plinko`), swinging doors | a hard way through |

## Mines, lifts and machines (Episode Two)

| Map | At | What it is | For us |
|---|---|---|---|
| ep2_outland_04 | 5009 -1624 -2188 | the hand-cranked lift: a lever, a winch, a cog, a shaft (`control_lever01`, `elevator_winch`, a torque) | a lift players crank |
| ep2_outland_01a | -11210 -6754 2050 | a mine lift platform hung on pulleys (`ceiling_winch01`, `remap_lift_speed`), cable mines | the mine's cage |
| ep2_outland_03 | 322 -5008 -951 | platforms hung on pulleys that swing | the same |
| ep2_outland_11b | -50 -8704 -239 | the crane trolley, the strider buster rack (`weapon_striderbuster`), destination monitors | White Forest's workshop |

## Story pieces (big, mostly scripted: lift only part)

d3_breen_01 (Breen's office, his teleporter and pod), ep1_citadel_00 (the opening), ep2_outland_12a (the advisor and
Eli), ep2_outland_10a (the dog and the strider), d1_trainstation_01 (the train in, the cameras), d1_eli_01 and 02
(Black Mesa East: parts lifted). Their best parts are already in the tables above or lifted.
