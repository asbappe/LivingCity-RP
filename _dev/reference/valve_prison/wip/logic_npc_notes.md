# Nova Prospekt: entity logic and NPC scripting (work in progress)

Read 21 November from d2_prison_01 to 08 (p1 to p8 below). Entity lists parsed as text into
`<scratchpad>/work/prisonlogic/ents/*.json`; scripts beside them (parse.py, lib.py, flow.py, w.py, census.py,
npcstats.py). Outputs are written `Output > target.Input(value) @delay`. Lesson proposals:
`logic_npc_lessons.json` beside this file. Valve left 58 comments (p7 38, p6 13, p4 6): quoted where they say why.

What each map is: p1 the outer wall and its guard towers (antlions set on the towers with bugbait, two gunships);
p2 the first cell block and a camera room; p3 the showers, the vortigaunt held in beams, a second camera room, a gate
counterattack; p4 cell block B2 held by soldiers with a manned gun and a camera room; p5 the laundry, kitchen and
cafeteria, crushing walls, a third camera room; p6 the depot (trains, prisoner pods on conveyors), Alyx's security
station and the interrogation room; p7 control room 2 and room 5, the two turret holds; p8 the teleport room, its
hold, the pod extractor and the lights-out ambush.

## Class counts (logic and NPCs, 8 maps)

| class | p1 | p2 | p3 | p4 | p5 | p6 | p7 | p8 | all |
|---|---|---|---|---|---|---|---|---|---|
| logic_relay | 26 | 10 | 21 | 9 | 17 | 44 | 51 | 81 | 259 |
| trigger_once / trigger_multiple | 17/8 | 6/11 | 15/16 | 19/13 | 25/6 | 38/17 | 17/20 | 14/8 | 151/99 |
| ambient_generic / env_soundscape | 12/21 | 7/41 | 30/27 | 7/13 | 41/23 | 45/27 | 24/23 | 58/11 | 224/186 |
| npc_combine_s (placed and templates) | 24 | 2 | 33 | 26 | 34 | 17 | 13 | 21 | 170 |
| npc_template_maker / antlion maker | 2/5 | 0/2 | 6/10 | 1/3 | 1/5 | 3/0 | 18/0 | 33/0 | 64/25 |
| npc_turret_floor / func_tank | 0/7 | 7/0 | 5/0 | 3/2 | 10/0 | 5/1 | 5/0 | 3/2 | 38/12 |
| point_camera / func_monitor | 0/0 | 4/1 | 4/1 | 4/1 | 4/1 | 15/6 | 8/2 | 15/4 | 54/16 |
| env_beam (tripmines, torture, teleport) | . | . | 9 | 6 | 7 | 1 | 5 | 61 | 89 |
| logic_choreographed_scene | . | . | 1 | 1 | . | 38 | 23 | 29 | 92 |
| math_counter / logic_case / logic_timer | 4/0/0 | 3/1/1 | 4/1/0 | 2/1/1 | 5/1/0 | 7/1/2 | 9/10/11 | 6/4/1 | 40/19/16 |
| point_bugbait / npc_bullseye | 5/8 | 0/1 | 7/3 | 2/6 | 5/8 | . | . | . | 19/26 |

None in the eight: env_hudhint, ai_script_conditions outside p7 (2), func_viscluster. Text: 4 game_text and 5
point_message, all leftovers of a cut vortigaunt and two turret hints (p3, p6), and 2 GAMEOVER_ALLY messages.
Outputs 3537 (x1 716; !activator 29; dangling 27, 0.8%); Kill is the commonest step (211). Soldiers: 29 placed,
141 templates; ar2 76, smg1 63, shotgun 31; combine_soldier_prisonguard 166, super soldier 4; squads of 2 to 3 most.

## 1. How the prison runs

**Guard towers (p1).** Seven manned func_tank guns (bunker_gun01, damage 26 but 5 to a player, range 1400 to 1700,
lock 1 to 1.5 s before firing, the gunner at `npc_man_point`); a spotlight (1024 by 64) rides each, lit only while
manned (Got/LostController). Squads of 3 a tower. A soldier hurt by a player opens the tower's range to 3000 and aims
it at him; the gun's first shot fires the alarm @1: the tower's glow and two sirens (radius 10000) for the yard.

**Camera rooms (p2, p3, p4, p5): watch the block from a console.** One func_monitor, 3 or 4 point_cameras (FOV 20 to
75, 60 on 9 of 15, pitched 10 to 32 down on most), one func_button (1025, wait 0.3). A press: counter Add 1
(max 3 or 4, back to 0 at max) > `OutValue > logic_case.InValue` > that channel's relay: monitor SetCamera, a click
(k_lab.monitorbutton, 48), one of four small glow sprites lit (scale .05) and the rest hidden, the button's own
sprite red then green @0.3. Each camera has an env_microphone beside it (MaxRange 512 to 1024, flags 31 all sounds,
`SpeakerName` the monitor, DSP 58 or 59) switched on with its channel: you hear the room you watch. The monitor is
on only while someone stands in the room (trigger StartTouch Enable, EndTouch Disable, microphones off too).
Choosing a camera starts a short live scene there (p8: the squad at the blast door seen gathering,
signal_group @0.2, signal_advance @1.4, moving up @2.6, screen off @5, the on-screen men Killed @6): two soldiers spawn and walk a path out of view where they are
Killed (p5 laundry, kitchen, cafe), soldiers fight an antlion in the showers (p2), an antlion guard breaks in
(p3); a trigger_look on the screen starts the first one by itself (p3, p5). The picture breaks up as it switches:
a static brush toggled at 0, 0.1, 0.2, 0.5, 0.6, 0.7, 1.1, 1.2 (p5) or once for 0.1 to 1 s (p6 to p8).
Scripted monitors (p6 to p8) cut cameras @0, 4.5, 5, 6, 7, 8 as a search; a func_tank with no bullets carries a camera
and SetTargetEntity turns it to follow a soldier or a pod (functank_room3_camera).

**Combine doors open in steps.** p6 combine_door_rl_1: areaportal Open @0, the lock's glow sprite (light_glow03,
scale .08) on @0, unlock beep (d1_trainstation_01.combinelock_unlock) @0.1, the door model (combine_door01.mdl)
animates Open @0.5, sprite off @0.8, the func_door (64 by 128, flags 544 toggle and NPCs cannot open, lip 16, speed
150) moves @1.25, model idle_Open @5. The interrogation room door is the same model with a player clip brush
Disabled as it opens. Blast doors (p8 door_comb_1): ten leaves, each a func_door, opened @0, 0.8, 1, 1.1, 1.5, 1.6,
1.9, 2.1, 2.3, 2.5 at speeds 60 to 100, and only 6 of the 10 make a sound (the others flag 4096 silent).
Gates (p3, p4, p6, p7): func_door speed 50, wait -1, Doors.Move12/17/18 and FullOpen10/16; a pair of glow sprites
beside each shows open or shut, switched by the door's own Open and FullyClosed outputs (p3 showers_gate2) or by
the button (p4); a gate lever is a func_rot_button (distance 150, speed 150, sounds 22, wait -1) whose OnIn turns
a sprite green.

**Force fields (p3, p6, p7, p8).** Two brushes: a nodraw box with the shield texture on its two faces
(`effects/combineshield/comshieldwall3`, Solidity 1 never solid), and a clip that does the blocking: toolsclip with
`excludednpc npc_combine_s` (p3: soldiers walk through) or toolsplayerclip (p7: only players are held). Poles
(combine_fence01a and b) take Skin(1) when the field is off. Sound: a hum loop (combine.sheild_loop, radius 500) and
a buzz (combine.sheild_touch) started and stopped by a trigger_multiple round the field (StartTouch, EndTouch).
Off: hum and buzz Volume(.1) or (0) @0.5, Killed @1, sparks, a shutdown sound @0.2. In p7 room 5 the hold starts by
switching four fields ON across the gateways @3 while the gates open and the node links turn on @5: players are
shut in, soldiers come through.

**The vortigaunt in beams (p3).** Four env_beam from two poles, end glows and two thin spotlights, three machine
loops (radius 400) started as the player comes. Pulling a plug (func_physbox held by a breakable) ends it: beams off
@0 and 0.25, end glows @0.6, three shutdown sounds @0, 0.3, 0.5, the field Killed, the poles Skin(1), sparks.

**The interrogation room (p6 'introom').** A pod extractor (prop_dynamic arm) brings the prisoner's pod in by
animation (introom_approach, extract, depart) with the pod's move sound and its stop at 13.4 s; the prisoner is
parented to the pod's attachments. Door: Combine door model plus a player clip, opened by the lock sequence above.
Two env_speakers nag the player to go in and to come out (concepts EnterIntRoomNag, ExitIntRoomNag, every 10 to
18 s), turned on 10 s after a scene ends and Killed the moment he moves.

**Prisoners are shown, not kept.** No citizen stands in a cell in eight maps. Prisoners ride pods on conveyors
(p6, p8: five 'PodPerson' citizens in one scene, removed when it starts), the vortigaunt hangs in beams, and Eli
is seen on monitors. The pod lines run on two looping relays: the lower line halts for 2 s every 22 s, the upper for
3 s every 18 s (Toggle @0 and @2 or @3, the relay calling itself @22 or @18); pods are func_tracktrains (start speed
100, novaprospekt.pods_track_move_1 and stop_1).

**Depot trains (p4, p6).** Doors Toggle, horn @4 (radius 6000), StartForward @5, speed 500 (75 pulling away); a
shake (radius 700) steps 2 @2, 3 @6, 2 @9, 1 @12, off @18; KillHierarchy at the track's end; the next 35 s after.

**The PA and the radio.** 13 Overwatch lines (`prison.overwatch_*`: antlions inside prison 1 and 2, contact block
B2, Freeman spotted, kill prisoners A7, mission failure punish, alyx reprograms turret, freeman in block D8,
communications out) and 10 soldier radio lines (`prison.sradio_<block>_controlroom`), all one-shot (48 or 49),
radius 1250 (10000 for 'kill prisoners', 8000 for 'communications out'). Fired by a trigger_once at a stage (16), a
relay (33), a counter of deaths (p4 radio_counter: 12 dead > the next radio line @2), a gate opening (p7). Each line
names the block (A5, A7, B2, B4, D7, D8, D9): the prison's places are lettered and numbered and the voice says where.

**Soundscapes by combat level.** 186 env_soundscape, all placed, none switched by logic; each kind of room comes in
up to three levels: general_hallway (light 29, very light 26), larger_cellblock (heavy 19, light 9, very light 17),
outdoor_courtyard (plain 4, heavy 5), plus control_room (12, simple 8), showers, laundry, dripping tunnel,
util_quiet and util_louder cellblock. The level follows how close the war is: heavy in p1 and p2, very light from p6.
Radius 128 (79) or -1 (57).

**Lights come on bank by bank.** p6 relay_room1_lights: light 1 and its lamp model Skin(1) @0, a clunk
(Buttons.snd4) and light 3 @2, light 4 @2.5, a clunk and light 5 @6, light 6 @6.5. The ambush in p8 runs it
backwards (below).

**A hold's clock is a machine you can watch (p8).** The teleporter charges for 184 s: a lift (func_tracktrain,
SetSpeed .06) sinks past 12 path_tracks about 38 apart; at each the hum (teleport_active_loop) steps up in pitch 60,
65, 70 ... 100, 110, 120, 140 and 165 at the end; every second track starts one of six dials (combine_tptimer.mdl,
animation '30sec') whose beam and lamp come on at 28 s; Alyx says halfway, taking forever, almost there, just
seconds. No timer on screen.

**Lockdown (p8 logic_trap_mossman_1).** Both Combine door models SetAnimation close, two security doors Close, a
sound, a warning light for 10 s (SetPattern aaaazzzz: a blink, not for us).

## 2. Guards: posts, not patrols

- No soldier walks a patrol route in eight maps (StartPatrol only for the two gunships, 19 path_corners all for
  scripted walks and exits). Soldiers hold places: 50 of 170 have a hint group, the groups name the place (cell2_far_end
  27 hints, cell2_floor2_section1 20, cafe_center 18, defense_2 17, teleport_platform_defense 16, laundry_catwalk 15).
- Busy poses for soldiers (39 hinttype 12, 12 ai_goal_actbusy, busysearchrange 32 to 500, visibleonly on 1):
  LeanWall_CrouchLeft_B 8, Cover_crouch_B 8, Idle_Alert 5, LeanWall_corner_Right 6, LeanWall_Left_B 5, Signal_Advance 3;
  ForceNPCToActBusy 'soldier hint teleport 0' as the template spawns (p1, p3). Dropped when he is hurt (p3
  post_fan_camper OnDamaged > Deactivate) or sees the player (a sight blocker brush Killed, the hint disabled).
- Fall back by deaths: ai_changehintgroup (12) moves survivors to the next group: p4 cell2_floor1_start >
  cell2_floor1_fallback when any of 5 catwalk soldiers dies; cell2_bunker1 > cell2_far_end (radius 2000) from a trigger.
- Reinforcements: p5 laundry: each of 4 soldiers' OnDeath Spawns one reinforcement (maker 4 in stock, 4 alive) whose
  schedule runs him at the attacker (forcestate 3, radius 128); a trigger past the laundry Kills the maker.
- A manned gun in a cell block (p4): a maker spawns the gunner, `FindNPCToManTank` @0.1; an npc_enemyfinder (search
  100 to 2048) aims the gun (FoundEnemy > SetTargetEntity); antlions ignore the gunner for his first 7 s (relationship
  applied @0.1, reverted @7) so he reaches the gun; a player on the gun gets damage 15 instead of 26 and a blue glow.
- Combine floor turrets (30) come in pairs: nearest other turret 87 to 328 (median 111), a soldier within 323 for
  half; p5 spawns each with its soldier from one point_template as the player arrives. Turrets carried in (p3): a counterattack soldier spawns with a turret prop in his left hand (SetParent,
  carry_pose); his sequence's OnScriptEvent01 Kills the prop and ForceSpawns the real floor turret where he sets it.
- Tripmines (p3 to p6, 12 in p5): a red env_beam (BoltWidth .5, TextureScroll 35) with TouchedByEntity, a backup
  trigger_once along the beam for players, NPCs and physics (flags 11), a 1-health breakable over the mine and an
  npc_bullseye (autoaim 28) so it can be shot; Break: explosion (magnitude 100), beam off, the backup Killed.

## 3. A raid on a held place, how it unfolds

**Antlions set on the guards (p1 to p5).** A point_bugbait zone (radius 256 to 830, median 512) where the player's
bugbait lands; OnBaited fires the zone's relay: every other spawn group disabled, the antlion maker SetFightTarget to
that tower's gunner spot (`turret_N_standhere`), its burrow hints (hinttype 400) enabled @0.1, live antlions up to 4
@0.2, the tower's own maker (2 or 3 at once, every 0.1 s) enabled. Indoors a burrow is a concrete plug in the floor
(concrete_spawnplug001a, 12): relay > plug Break, env_physexplosion, hints on, the burrow's maker Spawn @0.1. A
tower whose 3 men die gets a blocker brush (counter max 3 > Enable).

**The player's turret hold (p7, p8), Valve's comments quoted.** Lockers open on a button (the locker brush Killed
@0.9); turrets set down are counted (PhysGunDrop > Add; max 2 in control room 2 and the teleport room, 3 in room 5).
Then: radio @0.2, warnings @5 and @10, the assault @15. Control room 2: "This counter counts the number of assault
waves, and automatically spawns the next one": counter > logic_case > wave relay; wave 1 two SMG (the death counter
starts at 2 of 4), wave 2 two SMG and a shotgun (starts at 1), wave 3 all four, wave 4 four and a manhack plus the
balcony, wave 5 four and both manhacks; each 10 s after the last; makers 1 alive, every 0.2 s, radius 32; a timer of
480 s; "This is a failsafe ... on the assumption it's because a combine's stuck somewhere": finished anyway 180 s after
the timer; "Trigger fires when all combine in the wave are killed. Should stretch over all the places combine get
to": an NPC trigger (filter Combine and manhacks) whose EndTouchAll fires the end @6.
Room 5 and the teleport room keep the pressure level instead: each death Adds 1 to a living counter and spawns one
replacement @1 at a random maker (logic_case PickRandom over 4 to 5 lower and 3 upper makers); the first 4 deaths
each add an extra man or manhack ("At intervals, this case is used to add extra bad guys"); a manhack comes back 10
s after it dies; the timer (190 s room 5; the teleporter's 184 s) stops the spawning, then "Whenever it finds itself
at 0, it triggers the finish-assault relay". p8 opens a second way in ('behind') only after 8 deaths, 5 s later and
once no player is in its trigger, and its door 30 s after that. Pressure lines from Alyx at 45 s intervals (three one-shot timers).
Teaching (p7, comment): "When a turret is first tipped ... once a turret gets deployed after tipping once, we know the
player has learned to pick them up again": a tipped turret starts a reminder @2 and every 20 s (four lines in turn)
until one is set up again; all cancelled at the end of the hold.

**The breach (p8, soldiers forcing the blast door).** Behind the door: guards talking on a random timer 0.8 to 3 s,
a logic_case of 5 where only case 1 plays (d3_citadel.guards_talk): a line one time in five. Before a turret is
set: a crash (explode_4, radius 5000) and a shake (amplitude 1, 0.75 s, radius 1240) every 16 s. The first turret set:
crashes @0, 5, 7, 12, 14 in each 16 s. Both set, the charge: beeps @0, 3, 4, 5, 6, 6.5, 7, 7.5 (from @2), crashes @2, 2.5, 4, 5,
6.5, 7, 7.5, 8.5, 9, shakes @2, 6.5, 7.5, 9, 10, and @10 the door breaks (explosion @0.2, smoke 8 s), the first two
come in, the assault goal Activates @0.4 and BeginAssault @0.5, the guard chatter is Killed.

**Lights-out ambush (p8).** Any soldier who sees the player or is hurt (@1), or a trigger, fires ambush_relay: the
booth light off with a clunk (Doors.FullClose9, radius 2500) @0, lights 1, 2, 3 and 4 off one by one @0.5, 1, 1.5,
each with its own clunk and its sprite hidden; fog to black; a soldier's flare call @1; flares launched @4.5, 4.9,
5.8 (Launch 800 to 1100) each lighting 0.5 s later; soldiers Wake @6.1 and assault @6.2.

**Traps and the dead (p5, p7).** Four crushing walls close @0, 15, 30, 45 (scripted sequences whose script events
play the scrape, the impact, the shake and smoke; a hurt trigger on at the end); slumped zombies rise as in Ravenholm.

**Counterattack after a gate (p3).** The gate's OnOpen spawns the counterattack (template) whose schedule starts on
FullyOpen; 4 soldiers dead (counter) > second wave @5: the gate alarm @4, the assault template @4, the next gate
Toggle @5.

## 4. How players are guided

No hud hints. Alyx's voice on stage triggers; env_speaker nags every 10 to 18 s (16 to 24 in p7), on 10 to 12 s
after a scene, off the moment the player acts; turret nags every 20 s until learned. Lit gates, the console's
sprites, a hum at every field, the PA naming the block.

## 5. For Living City ([game] gamemode, [map] map pieces, [owner] ask first, [new] new)

1. CCTV at the Combine console (city-events.md): 3 or 4 fixed cameras stepped on E, the watched room's sound,
   static 0.1 to 1 s per switch, drawn only while used [game][owner]; camera points in prison pieces [map][new].
2. Combine doors in steps (keycards, hacks): light, beep @0.1, model @0.5, open @1.25 [game][owner]; blast doors of
   staggered leaves, some silent [map][new].
3. Force fields as Valve builds them (checkpoints, Combine-only zones): shield never solid, a clip the Combine pass,
   poles dark when off, hum 500 and buzz on touch, fade @0.5 to 1 [game][owner].
4. Breach build-up for raids and bypass charges: voices behind the door, a blow every 16 s, quickening beeps, open
   at 10 s [game][owner].
5. Guard towers that hold fire until attacked: spotlight while manned, 1 to 1.5 s lock, first shot sounds the alarm
   [game][owner]; tower pieces [map][new].
6. Steady pressure for held zones (rule 9's exception): cap N, a replacement 1 s after each death, +1 for the first
   4, stop at time, end at none left, an NPC trigger and a 180 s failsafe [game][owner].
7. The PA names the block, one line per change of state [game][owner].
8. Interrogation rig: the prisoner in beams, freed by pulling the plug (prison break) [game][owner]; rig piece
   [map][new].
9. Machines on a beat: pod lines halting 2 to 3 s every 18 to 22 s; the train's horn 1 s before it moves and a shake
   2, 3, 2, 1 over 18 s [game][owner].
10. Guards hold, lean and fall back: lean and crouch poses at posts, a hint group per room, pulled back a group per
    death [game][owner].
11. Power back bank by bank (0, 2, 2.5, 6 s, a clunk each); lights killed one by one before a Combine strike
    [game][owner].
12. Soundscapes in combat levels, heavier while a fight runs nearby [game][owner].

## Check ideas

- map_lint 'wire': camera microphones left on when the room empties; a channel counter whose max differs from its
  case count; a combineshield brush that is solid or has no clip twin; a func_tank spotlight no controller switches.
- Tests: a hold's living count never passes its cap; it ends at time up and none left, or at the failsafe.
- Robots: a raid on a held block whose attackers cannot path still finishes.

## What did not work

- The .vcd scenes and nag rule scripts are not in the sources: what Alyx and Overwatch say is known from names only.
- Flag bits (maker 16, 272; func_door 544, 4096; microphone 31; turret 32, 64, 128) are the FGD's as remembered; who
  passes a field was settled from its brush materials. Brush sizes from three plane points are approximate.
