# Black Mesa East (d1_eli_01, d1_eli_02): notes (work in progress, 21 November)

Numbers from the VMFs read as text (`map_ingest.py` readers, brush-box rays, props block nothing). Positions are
Hammer units. eli_01 is the way in and the base at work; eli_02 is the same lab, corridors and airlock again, then
the scrapyard and the Combine's attack. Measured: `valve_d1_eli_01/measure.json`, `valve_d1_eli_02/measure.json`.

## The base in one line

A door in the dam's face (outside: dam concrete `concretewall064*`, gravel, red grass, a few drums, pallets and a
fence: nothing marks it), a 264 deep airlock with a decontamination scanner, an upper hall, a freight lift that drops
1458 (z -1214 to -2672) past three floors of living quarters, and the labs at the bottom (z -2736), with corridors out
to a second airlock and the scrapyard (an open pit, its floor about 2650 under the sky).

## 1. Props and craft

### The way in (eli_01)
- Outer airlock: two `func_door` halves sliding apart (movedir 0 and 180, lip 8, speed 100), each covered by a
  `blastdoor001a`/`b` prop_dynamic. Inner door slower and heavier (speed 40 and 50, lip 12). Doors 264 apart
  (y 2872 and 2608), airlock 208 wide inside, ceiling 173. The second airlock (to the scrapyard) the same: 272 apart,
  208 wide, 177 high, doors at speed 25 to 45. Both doorways are about 168 across (two leaves of about 84).
- Between the doors: the scanner (`airlockscanner` prop_dynamic, animations spray and scanfield), three `env_steam`
  parented to its attachments, a `func_smokevolume`, two `labturret` prop_dynamics behind small sliding panels
  (func_door, speed 175, lip 2) in the ceiling, and a control booth beside it: ceiling 96, 115 by 192, a
  `controlroom_monitor001b` pitched 30 and four `monitor01b` pitched 37 to 54 and turned 7 to 47 toward the seat.
  The same booth is at the second airlock (x -720). A `point_camera` over the outer door feeds a `func_monitor` inside.
- Upper hall: 353 by 1664, ceiling 184; floor half `concretewall002a`, metal plate `metalwall041a` (19%).
  Pushcarts, crates, pallets, oil drums, propane, a generator trailer and a truck (`truck003a`) by the lift: the
  base's goods yard is at the top, by the way in.

### The lift
- A `func_tracktrain` (startspeed 65) carrying the `freightelevator` cage model, on seven `path_track`s straight down
  the shaft: 1458 in about 22 s. The shaft is 176 by 800 at the bottom and 1456 high. Five `move_rope`/`env_beam`
  cables hang from 654 over the top landing to the cage. Doors at top and bottom are two `func_door` leaves (lip 16,
  speed 100, wait 4) behind an `elevatordoor` prop; the three floors passed have only the door prop (closed gates
  seen through the cage). A second, unused `freightelevator` stands parked at (-250 1320).

### Labs from old concrete and salvage
- One material does most of the work: `concretewall002a` (plain board-marked concrete) is 4610 of 15794 faces in
  eli_01: in the lower lab 46% of the wall, 55% of the floor and 50% of the ceiling. Accents: `concretewall047a`,
  `020a`, `002c`, brick `brickwall052e` 4%, rubber mats `rubberfloor009a` 14% of the lab floor.
- **Two tones even here:** the wall changes material at 112 to 128 over the floor (eli_01's first change: 422 walls
  at 112, 565 at 128 of 2412): `concretewall002c` (or `020a` in the lab) below, `002a` above. In the upper hall the
  lower band is 0 to 128, then 002a, then metal plate from about 192.
- Main lab: 304 to 554 by 800 to 874, ceiling 320 to 432 (higher than the 120 to 128 of Valve's flats). Eli's
  corner: `workspace004`, the teleporter (`teleportframe`, three `teleportgate`, four `teleportring`, `teleplatform`,
  `teleportbulkeli` overhead), crystal holder, `rotato`, jars, receivers. Mossman's room off it: 304 by 216,
  ceiling 128: `securitybank` with `servers` beside it (100 apart, both against the wall), a `func_monitor` and a
  button that cycles four cameras. A `prop_door_rotating` (`door01_left`) is the only swinging door in the map.
- Salvage dressing: 147 pipe props in eli_01 (pipe01/pipe03 straights, 45s, connectors; 93% square), chain-link
  frames as partitions (`interior_fence002a` to `e`, `001g`: 70 fence props, 91% square, many standing within 16 of
  a wall), 14 `keypad` prop_dynamics, each with its `func_button` (every door has one; skin 1 for 1.9 s when used).
  Fixtures from the prison: 29 `prison_flourescentlight001a`, 22 `prison_cagedlight001a`, `walllight001a`.
- Light: lower lab 37 spots and 6 lights, the commonest colour `169 205 188` (pale green fluorescent, 18 of them),
  median brightness 140; living floors brighter (median 700) and warmer (`232 213 174`, `202 222 165`). No styled
  or flickering light in eli_01.

### Living quarters, seen from the lift (eli_01)
- Three floors 288 apart (floors z -1584, -1872, -2160), each a vignette with no AI nodes: nobody walks there.
  - Dormitory (-1584): ceiling 128 to 200, 864 by 160 to 576; seven `prison_bedframe001a` each with a
    `FurnitureMattress001a` as a `prop_ragdoll` (the mattress sags on the frame), four `lockers001a` 48 apart in a
    row, an armchair, a couch, a vanity, a table with a chess board, a cafeteria table and bench.
  - Kitchen (-1872): 504 by 736, ceiling 200; four fridges, counters, two stoves, two sinks, shelves, `soupprep`,
    `headcrabprep`: two vortigaunt cooks in chef's hats with ladle and cleaver.
  - Repair floor (-2160): ceiling 128, 192 by 1978: two vorts and a citizen at work.
- Walls on these floors are warmer: painted `concretewall002c` 36%, `concretewall021c`, plaster `plasterwall030c`;
  ceilings `concreteceiling003a` and `plasterceiling006a`; floors `concretefloor008a`.

### Scrapyard and the way out (eli_02)
- An open pit (`scrap2` 1239 by 2204), reached through the second airlock and a gate (`func_door`, speed 80) with a
  button behind a lock. 99 props, half physics: oil drums 9, crates 15, pallets 7, washers and a dryer, sinks, a
  toilet, paint cans, a bucket, a tyre, a playground carousel, the propeller trap engine; five `lighttowercluster01`
  with 16 `point_spotlight` beams (colour `159 237 215`, median 450). A hoop made of two triggers.
- After the attack the same lab is dressed as a cave-in: `concrete_cornerpile01a` 6, rebar clusters, debris piles.
- The way to Ravenholm: a shaft 128 wide (ravenshaft), pipes (`pipesystem*`), power boxes, a ladder held by a
  `prison_padlock001a` the gravity gun breaks.

## 2. Logic and NPCs

Class counts: eli_01 31 choreographed scenes, 18 scripted sequences, 55 relays, 25 func_doors, 20 buttons, 10
areaportals, 4 env_speakers, 4 ai_script_conditions, 5 point_cameras, 2 func_monitors; NPCs: 7 vortigaunts, 5
citizens, Eli, Alyx, Mossman. eli_02 56 scenes (30 Alyx, 18 dog), 32 sequences, 102 relays, 12 npc_template_makers,
11 env_entity_makers, 18 point_templates, 3 scanners, a helicopter, 4 headcrab canisters, 5 npc_launchers.
**Text on screen in both maps: one env_hudhint** (the gravity gun's swap key). Everything else is spoken.

### The airlock (eli_01): a guard checks you in, about 31 s
- The guard (Mossman, with Chester at the booth) sees the door on a `func_monitor` fed by a `point_camera` over it,
  and talks through an `env_microphone`; the booth light comes on as the scene starts.
- `logic_AirlockScanner_StartSpray`: scanner animation spray @0.1, three steams on @0.5 (parented to the scanner's
  spray attachments), a yellow sprite, the spray sound toggled @0.5 and @14, steams off @14, the smoke volume's
  density climbing 0.05 every 0.5 s (a `logic_timer` adding to a `math_counter` whose OutValue sets the density,
  killed at max; full in 10 s) then falling 0.05 a second (20 s). @13.5 the scan: scanfield animation @3, beams on,
  off @17.
- Two `labturret` props drop from ceiling panels (func_door speed 175, opened @0) and **follow you without being
  NPCs**: six `trigger_multiple` cells (2 by 3, about 132 by 100) each play the turrets' `aimN` animation for that
  cell, and a `logic_case` PickRandom sets the aiming sound's pitch to 200, 215 or 230. They retract (@0.4 to 0.6,
  panels shut @2.2) when the guard opens the inner door.
- The outer door's areaportal opens on OnOpen and shuts on OnFullyClosed (`valve-portal-door`).

### The lift (eli_01): the base's life, timed to the ride
- The lift waits until the guide is in (a `trigger_once` for NPCs enables the player's trigger). Then: doors shut,
  the lift resumes @3, and the floors it will pass are started on its clock: dormitory loungers @4, kitchen @6.5,
  repairmen @14.2, matched to when each floor slides past at 65 a second.
- Each `path_track` on the way opens the areaportal of the floor ahead and closes the one behind 3 s later
  (four `portal_elevator_ride_N`). The last stop shakes the cage, dings @1, opens the doors and fires
  `logic_KILL_EM_ALL`: the NPCs seen on the way are removed (KillHierarchy). Nobody lives there when nobody looks.
- `info_lighting_relative` and `SetLightingOriginHack` keep the riders lit as the lift moves.

### Life on the floors (eli_01)
- Kitchen: two vortigaunt cooks on `scripted_sequence`s (soupstir, butcher), their hats, ladle and cleaver
  `prop_dynamic`s put in hand and on head by `SetParentAttachment` as the scene starts.
- Dormitory: a citizen lying on a bed, a citizen on a chair and a vortigaunt over a chess board (three sequences
  begun at once). Repair floor: two vorts made to hate an `npc_bullseye` for about 5 s (ApplyRelationship @0 and
  @0.75, Revert @6), so their beams zap the machine; the scene removes itself @7.
- Upper hall: a background walker loops between two sequences (end of 1 > 3 s > 2 > 6 s > 1), killed when the
  lift leaves.

### The lab at work (eli_01)
- Eli, Mossman, Alyx and the lab vort each have a work loop scene (`lcs_eli_Workloop01`, `lcs_mo_Workloop_1`,
  `lcs_al_tele_workloop1`, `lcs_vort_elab_workloop`) that a talk pauses and resumes after (busyactor 1).
- **Look around:** after the talk, for 25 s, four `ai_script_conditions` wait for the player to look at a thing for
  0.5 to 1 s: the photo (within 120, a 32 degree cone), the teleporter (190, 80), the thing (70, 35), Breen's
  corkboard (150, 35). Eli talks about the one looked at, the other three switch off, and the story moves on.
- Mossman's room: one button steps four cameras (`cam_chefy` the kitchen, `cam_recroom`, `cam_foyer`, `cam_stairs`):
  the base's rooms nobody walks, shown on the `securitybank`'s screen. The prison's camera room is the same wiring
  (`valve-prison-cctv`).
- Weapons: `env_global global_friendly_encounter` on as the tour starts (the player's gun lowered in the base),
  off 4 s into the attack (eli_02). Ours already carries guns lowered on rebel ground (`lc_lowered_weapons`).

### Guidance without text
- `env_speaker` nags (`nags_eli_lab.txt`) every 16 to 24 s (Mossman's room 13 to 22, stacking 12 to 24, "go back to
  the airlock" 4 to 10), on after a scene ends, off the moment the player does it. Doors shut behind the player
  as he passes the next trigger (`inner_door`, `lab_exit_door_raven`): the way back closes, so the way on is plain.
- Keypads light (skin 1 for 1.9 s) when someone opens a door: a door that will open looks used.
- The gravity gun lies in a glass case with its own `light` and glow sprite: the one lit thing in the room.

### The scrapyard teaches the gravity gun (eli_02)
- Taking the gun: Alyx opens the case, the nag starts 12 s after her sequence if the player has not taken it.
- First test: stack junk to reach a ledge 130 up beside the gate button (stacking nag 12 to 24 s). Reaching it
  unlocks the button. A failsafe opens the gate anyway (Alyx lets you out @7); walking on past the lesson
  (`trigger_skip_training`) cancels and kills 17 pending lines at once (`valve-teach-then-give-up`, firmer).
- The dog's game: 10 crates each from an `env_entity_maker` (respawned), the dog throws; `OnPhysGunPickup` > yes
  relay (Alyx praises, picked from a `logic_case`), `OnBreak` > no relay (the dog is disappointed). A ball from a
  maker for fetch; triggers where it can be lost (a vent, a roof) make Alyx ask where it went and break it @6 so the
  maker makes another. A hoop of two triggers (top enables bottom for 1 s): a score shows a sprite and Alyx says
  "nice shot" once. If the player has not played fetch in 60 s, Alyx suggests it.
- The play ends at a random moment: `timer_attack` 80 to 180 s.

### The Combine's attack on the base (eli_02)
- Order: the play timer fires; Alyx reacts; the gate opens @12, the airlock @14; rockets armed @20. Overhead
  (battlefx_0): a sky of scanners drawn as six `env_particlescript`s with only three real `npc_cscanner`s on
  `aiscripted_schedule` paths, headcrab canisters @4, 9, 12, 15, a helicopter @12. At the airlock the doors shut
  behind the player; shakes, a blast, the battle loop @3. Eli speaks on the airlock's monitor; the monitor breaks to
  static (a noise brush on for 0.5 s, then for 7 s) and goes dark.
- The alarm: a fire bell loop and four `light_emergency_turnon` lights with glow sprites blinking on a relay that
  calls itself: on 1.2 s, off 0.7 s, again @1.9. No turning beacon here.
- Inside: metrocops from one maker against vortigaunts from another; cops set to ignore Eli. The cave-in: lights
  blow out with sparks, a cable breaks, two physboxes drop, rock showers break, dust @0.5 and @3, a ceiling slab
  (`func_door` speed 450) seals the lab. The lab is later dressed as rubble.
