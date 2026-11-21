# The Citadel: entity logic and NPCs (work in progress, 21 November)

Batch 6, the logic and NPC part: how the Combine's own stronghold runs, read as text from the VMFs of d3_citadel_01
to 05, d3_breen_01, ep1_intro, ep1_citadel_00 to 04, styleguide_core and styleguide_destroyed_citadel. Not here (other
helpers): the architecture (`architecture_*`), and the owner's pieces lifted whole (the big doors, the core reactor,
the walkway reactors, the pods: `_dev/reference/prefabs/`). Tools in the chat's scratch folder (`citlogic/`: an
entity-only reader, `loops.py` for tracktrain rings, `ride.py` for a ride's timeline, `soldiers.py`).
Status: all 15 maps read (21 November).

## 1. Machinery on loops

- **Pods in lockstep (d3_citadel_01).** Two rings of 7 pods each (`pod_bay_zapper_track`, 14 path_tracks, 4749
  long; `pod_bay_track`, 9 nodes, 4549 long), speed 100. Each pod stops at its own stop (`OnPass !activator Stop`)
  and adds 1 to one math_counter (max 7); when all 7 are in, the counter fires the resume relay 3 s later (4 s for
  the other ring) and resets. One stop is the "zapper": warm-up sound at 2.5 s, then at 4 s an energy core
  discharges, a beam and sparks come on with a trigger_hurt, all stopped 6 s later. Another stop opens the pod
  (rotator Open @0, pod Open @1, Close @4, rotator Close @5). The same lockstep ring is in d3_citadel_04 (4 + 3 pods),
  05 (7 pods, 7 stops) and ep1_citadel_00 (7 pods, 7 stops). Wiring unlike Nova Prospekt's timed toggles
  (`valve-machines-on-a-beat`): here the slowest car holds the others, so the ring never drifts.
- **Staggered starts.** The diggers (2-node rings 768 to 896 long, max speed 500 to 600) are started by one
  logic_auto at 1, 4 and 6 s, so they never move together. A third ring of 3 pods (11 nodes, 6858 long) runs with no
  stops: 46 s a lap at 150.
- **Long rings far off (d3_citadel_02).** Three container trains on one ring of 15206 (about 72 s a lap at 210),
  started 0, 2 and 4 s apart by the player's pod passing a node; two razor trains of 7488 at 500; pod rings of 4840
  and 6175 at 150. Moving things fill the shaft's distance without anyone near them.
- **Sparks and rumbles on random timers.** 209 logic_timers in the 15 maps; 121 drive sparks on broken
  consoles and panels, random 0.4 to 2 s, all 121 start disabled and are switched on by the relay that breaks the
  thing (26 of 26 timers in d3_citadel_03, 42 of 50 in 04, 28 of 51 in ep1_citadel_03). In d3_citadel_03 the 12
  consoles come off the wall with the gravity gun: picking one up strains (sound, shake, physics pushes at 0, 0.1,
  0.25 ... 0.6 s); held 0.6 s its two sockets Break and it comes away (dropped sooner, `CancelPending`); then a blast,
  sparks for 2 s, the random spark timers for 10 s, and its screen skin goes dark. The dying Citadel (EP1) rumbles on its own: a timer of
  12 to 49 s (8 to 33 in ep1_citadel_02) fires a shake (amplitude 4, 4 s, radius 5000) with a far explosion (radius
  9000) and a second sound 25 s later; a story beat's rumble is harder (amplitude 12 for 1 s, then 4 for 4 s).

## 2. Stalkers and their pods

- 24 npc_stalker in 7 maps, all `beampower` Low. Two jobs: **workers** and **guards of the way**.
- **Workers, seen from the ride (d3_citadel_02).** Stalkers at work play `working` or `idle2` on scripted_sequences
  (flag 480/496: no interruptions), with ropes (move_rope/keyframe_rope) hanging to their work and sparks beside them;
  a soldier stands watching one (`npc_soldier_watchstalker3`). They are point_templates spawned when the player's pod
  passes a node ahead of them, and Killed when it passes the next (`pod_player2 OnPass npc_stalker_busy1 Kill`). The
  gunship bay's stalkers walk a 6-corner loop (aiscripted_schedule, started 4 s after the template spawns).
- **The ride itself:** 56 path_tracks, 24581 long, about 147 s at 100 to 250 (not counting the stops), 13 nodes that
  do something: a thing to see every 11 s; each hall's door Opens as the pod nears and Closes behind it (chamber,
  strider, ball, train halls). The pod piece is the other helper's; this is only its pacing.
- d3_citadel_05: the stalkers stand on act busy hints (`hints_citizenactbusy`), squad `suppress_warning`.
- EP1 (ep1_citadel_01 to 03): stalkers asleep (`sleepstate` 3, waiting for an input) on bridges and in the core; one's
  death opens the way (`OnDeath relay_releaseGate`, `lcs_alyx_opengate`), and in ep1_citadel_02 a stalker hurt by the
  player is dissolved at once (`OnDamagedByPlayer dissolver Dissolve`): they are not fighters.

## 3. The advisors

- No npc_advisor anywhere in the Citadel. The Advisor is a **face on screens**: a cycler with `models/Advisor.mdl` in
  a sealed room, filmed by point_cameras (fov 70 to 90), shown on func_monitors (ep1_citadel_01, ep1_citadel_03,
  d3_breen_01). Advisor pods: 9 `advisorpod_docked` statics and 2 dynamic pods in ep1_citadel_01.
- ep1_citadel_01, the pod room: one relay cuts the screen between Breen's camera and the Advisor's 9 times in 3.6 s,
  with the Advisor's hum switched on and off in step; then the other screens come on one by one 0.3 to 0.6 s apart
  (4.3, 4.6, 4.9, 5.6, 6.2, 6.5 s), each with a click; the Advisor's alert at 3.5 s and talk at 5 s; at 7 s the pod is
  brought out (door opens, rail and mover close, a turning light and an alarm).
- ep1_citadel_03, the core control room: two elites work consoles (`ai_goal_actbusy` ForceNPCToActBusy at console
  hints) while the Advisor talks on the room's monitors; when the player looks at the shutters for 0.6 s
  (`trigger_look` fov .975) or the look times out: the Advisor's alert, an alarm at 1 s (repeating every 8 s), the
  monitors off at 3 s, the elites woken and sent on an assault.

## 4. Energy balls: dispensers, sockets and catchers

- **Dispensers** (func_combine_ball_spawner, d3_citadel_03): `ballcount` 10, `ballrespawntime` 4, speed 125 to 350,
  radius 20, flag 4096 start inactive; in rows 80 apart.
- **Sockets that power something** (flag 8192 "power supply", `ballcount` 1, respawn -1, speed 75): pull the ball out
  and what it feeds goes off (`OnLastBallGrabbed` > the shield wall's off relay), put it back and it comes on
  (`OnBallReinserted`). d3_citadel_03: `ballspawner_ballgenerator1` holds shield wall 3; `ball_spawner_room3` holds
  wall 7. A pair of energy cores (scale 1.5, one pointing up, one down) marks each socket.
- **Catchers** (EP1): a trigger_multiple with filter_combineball_type counts balls thrown in: 2 per bridge section, 3
  for the upper bridge, 6 for the core (ep1_citadel_03 `counter_balltrap`, max 6); taking one out Subtracts again.
  Launchers (point_combine_ball_launcher, 17 in EP1) send balls out on their own.

## 5. Force fields and the confiscation field

- **A shield wall (d3_citadel_03, 7 walls):** two fence posts (`combine_fence01a/b`, skin 0 on, 1 off), the visible
  func_brush (Solidity 1, never solid), a clip func_brush (`excludednpc` npc_combine_s: soldiers walk through), a
  trigger_multiple for the touch buzz, an idle loop, and a trigger_hurt of 10000 that is on for only 0.1 s when the
  wall comes on (whatever stands in the field as it rises dies). Extends `valve-forcefield`.
- **The confiscation field (d3_citadel_03 room0; the same in ep1_citadel_01).** A trigger_once at the room's middle:
  at 0 the player is pinned (trigger_vphysics_motion: gravity 2, velocity limit 8); at 2 s Overwatch announces the
  weapon strip; at 7 s four energy cores charge (4 s) with a start sound and a loop; at 11 s the strip trigger takes
  the weapons, which float (a second vphysics trigger for weapons only: gravity 0, velocity limit 2, air density 0.5);
  at 13 s the dissolve starts from four emitter points (info_targets at the cores) and the room's light goes bright.
  The gravity gun cannot be burned: `OnChargingPhyscannon` > sparks, "strip failed" at +1 s, the end relay at +4 s
  (strip and dissolve off, the exit wall Killed, the shield wall off, autosave), "security" warning at +8 s; if
  nothing charges, `strip_stop` does the same and then sends the first squad. EP1 adds Alyx's scenes and a hold-field
  hum at 2 s.

## 6. The super gravity gun

- One `env_global super_phys_gun` (initialstate 1) in each map after the strip room (d3_citadel_04, 05, d3_breen_01,
  ep1_citadel_02, 03), beside the newgame physcannon spawner; the strip room's charge turns it on in d3_citadel_03.
- With it, soldiers' guns must not be picked up: in ep1_citadel_01 and 04 every soldier's death dissolves his weapon
  (10 of 10, 13 of 13: `OnDeath weapon_dissolver Dissolve soldierX_weapon`).

## 7. Soldiers at home

- 222 npc_combine_s: d3_citadel_03 25, 04 58, ep1_citadel_02 26, 03 59. Elites (`combine_super_soldier`) 20 to 44%
  (5 of 25, 12 of 58, 9 of 16 in d3_breen_01, 26 of 59 in ep1_citadel_03). Guns: AR2 most (49 of 58 in 04).
- **Kept out of the world until needed:** 17 of 25 in point_templates (03), 37 of 58 (04); no patrol paths (5 in
  d3_citadel_02, 8 in ep1_citadel_03, none elsewhere).
- **Sent by assault:** 137 assault_rallypoint and 128 assault_assaultpoint in 9 maps (37/37 in 04). After the strip
  room: the hall door's light On at 1 s, `Activate` the assault at 1 s, `BeginAssault` at 1.1 s, light Off at 6 s:
  the door lights as the squad comes through it.
- **Asleep until woken (EP1):** `sleepstate` 3 on 52 of 59 soldiers in ep1_citadel_03, 16 of 26 in 02; woken by
  relays, triggers, a ball pipe breaking open, or a comrade's death. On ep1_citadel_02's bridges each elite's death
  wakes the next (13 `OnDeath > Wake`): the defenders come one at a time.

## 8. Breen's broadcast

- Breen is on every console screen through one point_camera (fov 20) aimed at npc_breen in a booth far from the play
  (d3_citadel_03: camera at 11160 116 2113; 04 the same). A func_brush slate stands in front of that camera, so all
  screens show the Combine slate at once; a broadcast starts with the slate tone (twice, 2 and 5 s in d3_citadel_03),
  the slate is Disabled 0.5 s (6 s) later and Breen's scene starts 0.6 s (9 s) in. His speeches (br_mentors, create,
  foundation, worthit, freemanatlast) chain `OnCompletion` with 2 s between, or start one by one at places.

## 9. The countdown (d3_breen_01)

- A trigger_once: `countdown StartCountdown 190` at 12 s (info_teleporter_countdown: the wiki says its HUD was never
  finished), and at 19 s a relay that has Overwatch speak the time left: 3 min at 0, 2 min at 57, 1 min at 117, 45 s
  at 132, 30 s at 147, 15 s at 162, 10 s at 167 (radius 1250 each): the calls come closer as the end nears. Breen's
  lift up the core Resumes at 147 and 162 in step with the calls. The end relay Cancels the pending calls and Kills
  the relay.

## 10. d3_citadel_04 and 05: waves at home, workers and the stalker pod

- **The lift wait (d3_citadel_04).** While the lift is coming, soldiers arrive in random waves: a timer of 4 to 10 s
  picks one of 8 cases (three doors with squads of 3 from env_entity_makers, or manhacks), but only while fewer than 4
  are alive (a math_counter: each spawn Adds 3, each death Subtracts 1; its OutValue into a logic_compare against 4
  Enables or Disables the timer). A wave counter allows 6 waves; calling the lift (the door's OnOpen) narrows the timer
  to 2 to 5 s and allows 12 more; the lift's first stop Kills the timer. The stasis room does the same with a cap of 3
  alive and 8 waves (`counter_stasis_wave`). Extends `valve-npc-steady-pressure`.
- **Kill the hall's guard and the next thing wakes:** 6 soldiers' deaths fill a counter of 3 (any 3 of the 6), which
  opens the strider hall's door, Kills the strider's calm relationship and Wakes it.
- **The stalker pod (d3_citadel_05).** One pod with a stalker in it (a prop_dynamic stalker in a prisoner pod) passes
  the player slowly (70, 1229 long), with a shriek at two nodes and breathing 2 s after: what the Citadel does to
  prisoners, shown once in passing, never told.
- **Synths at work (d3_citadel_05):** 1.5 s after the player's pod passes a node, two crab synths (monster_generic)
  walk a 3-corner path through the gunship bay and are Killed at its end; four mortar synths stand as cyclers.
- **Reinforcements open their own door (ep1_citadel_04):** the template spawns, one soldier walks to a console
  (`ss_Soldier_useconsole` at 1 s), another opens the door (`ss_Soldier_opendoor` at 3 s), a standoff goal (stay at
  cover, aggressiveness 1) at 5 s; the second squad goes straight to an assault at 0.1 to 0.4 s.

## 11. Breen's office (d3_breen_01)

- Breen's office talk is one chain: lcs_BreenOffice01 > 02 > 03 > 03b > 04 OnCompletion, with a jump-ahead relay
  (`logic_goto4`: Cancel 02, Kill the soldier taking the gun, Start 04 at 0.1 s); 05 starts when Alyx's escape-pod
  sequence ends, and then Breen plays an idle loop (`breenoffice_postidle_loop`) so he is never left frozen.
- Breen pleads to the Advisor on his console's screen (func_monitor `Monitor_plead_console_1`, 6 brushes, showing
  `cam_advisor_1`); the Advisor itself is a cycler in a sealed box.
- On the climb Breen mocks the player in 7 lines (br_mock01 to 13), each started by a trigger_once at a place: one
  line a place, never a timer.
- The guards outside the door (valve-breach-buildup) and the end: `player_weaponstrip` at the end game, a speed mod
  for the G-Man's scene.

## 12. Episode One: the Citadel breaking (ep1_intro, ep1_citadel_00 to 04, the two style rooms)

- **The blast grows (ep1_intro).** The end-of-HL2 blast is a sprite whose scale a math_counter sets (OutValue >
  SetScale): it starts at 8 and a timer Multiplies it by 1.0065 every 0.05 s (about 14% a second, x49 in 30 s);
  with it the fog lerps to white over the view and the screen fades. Debris rides past on tracktrains at 170 to 2000.
  Vortigaunts warp in by a material lerp (0 to 1 over 2 s) as their scene starts.
- **The Citadel seen from outside (ep1_citadel_00):** a chunk shot off its top every 6 to 12 s (a logic_case picks one
  of 5 env_shooters), lightning every 4 to 12 s with thunder 1 and 2 s later, vortigaunts reloading on random 6 to
  18 s and 5 to 15 s timers. The van ride: 51 path_tracks, 15156 long, up to 2000.
- **The broken Citadel inside (ep1_citadel_01 to 03):** rumbles every 12 to 49 s (section 1); the advisor pod room and
  the core control room (section 3); the confiscation field again, the gravity gun charged by it (section 5); every
  soldier's gun dissolved on death (section 6); defenders asleep and woken in a chain (section 7). Ball launchers
  (ep1_citadel_02): 3 balls, back 5 s after one is lost, launched up at 20 to 30 degrees, 8 bounces.
- **The lift (ep1_citadel_02b):** small tremors every 6 to 12 s while it rides; a stalker in the shaft is the trouble, and
  once it is dead the lift runs on fast (SetSpeedReal 180 at the next node); Alyx's nag repeats every 16 s until the player acts.
- **The core's state is heard (ep1_citadel_03):** the core's loop (radius 3250) is swapped as it is mended: unstable
  (and a nearer unstable loop), then partial stable 1 s after the third laser, then stable; 6 balls into the catchers
  complete it. The core itself wobbles on three axes, each on its own random timer (0.9 to 1.1 s; 0.2 to 0.9 in
  styleguide_core) picking one of 12 to 16 scales between 0.91 and 1.1, and flares to 1.2 every 3 s while a flare-up timer runs, with
  three touch zones that follow its size. (The core as a piece is the other helper's.)
- **The alarm in the Citadel:** a siren and a glow sprite that shows 0.7 s and hides 0.2 s, six times over 5.2 s, then
  the room's alarm light off; a timer repeats it every 8 s until a scene stops it (ep1_citadel_03, 04). No turning
  beacon here.
- **The escape train (ep1_citadel_04):** the train stands still; a ring of three spotlights and a brush on a
  tracktrain runs past it at 2200 (9 path_tracks, 2560 long: a pass every 1.2 s), with shakes every 12 to 30 s: the
  lights sweeping by are the motion.
- **styleguide_destroyed_citadel** is ep1_citadel_02's bridge with 8 stalkers and the same rumble timer;
  **styleguide_core** is the core's wobble alone.

