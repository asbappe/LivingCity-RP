# City 17's uprising: entity logic and NPCs (work in progress)

Maps: d3_c17_01 to 12b (15 maps; 13 was read before). Counts are over these 15 unless a map is named (c01 = d3_c17_01).
Entity lists parsed as text into `<scratchpad>/work/c17/ents/*.json`; scripts in `<scratchpad>/work/c17/`.

## Class counts (NPC and logic, 15 maps)

npc_template_maker 364 (in all 15; c06b alone 87), info_node 5271, info_node_hint 927, info_node_air 442,
air hints 157, aiscripted_schedule 219, scripted_sequence 150, logic_choreographed_scene 164, path_corner 316,
path_track 159, assault_rallypoint 109 / assault_assaultpoint 111 / ai_goal_assault 41, ai_relationship 91,
npc_bullseye 64, info_node_link_controller 55 (11 maps), ai_script_conditions 30, npc_enemyfinder 25,
ai_goal_standoff 22, ai_battle_line 22, ai_ally_manager 16 (9 maps), ai_goal_follow 13, ai_sound 13,
env_gunfire 15, env_shooter 50, item_item_crate 138, item_dynamic_resupply 39, item_healthkit 73,
trigger_autosave 55, npc_combinedropship 13 (9 maps), npc_strider 13, npc_cscanner 13, npc_manhack 17,
npc_turret_floor 11, npc_turret_ground 8 and ceiling 6 (c10b only), npc_sniper 5 (c09), env_headcrabcanister 4
(c06b), game_weapon_manager 6, logic_navigation 8 (c08), ai_goal_actbusy 8, ai_changehintgroup 6, func_tank 3,
trigger_look 3, func_viscluster 3 (c02), env_message 4, env_hudhint 2, game_text 1.
Placed NPCs are mostly templates: npc_combine_s 181, npc_citizen 109 (71 are templates), npc_metropolice 48.

## Makers (364)

- 365 of 367 start disabled; Radius 256 (347); CriterionVisibility and Distance 2 "don't care" (363): out of view by
  placement, not by flag. Stock and alive: 1 and 1 (140), 1 and 5 (131), 400 and 4 (9, the squad top-up makers).
- Templates: npc_combine_s 159, npc_citizen 74, metropolice 27, manhack 23, scanner 13, dropship 12, strider 12.
- Fired by trigger_once (264), logic_relay (81), ai_ally_manager (47), trigger_multiple (19), counters (14), a
  soldier's own output (12). Inputs: Spawn 290, Enable 129, Kill 39 (makers passed are killed), Disable 28,
  SpawnNPCInRadius 15.
- OnSpawnNPC (309 lines): StartSchedule 131, SetRelationship 30, BeginSequence 20, FlyToSpecificTrackViaPath 15,
  Activate 10, scanners SetFlightSpeed and EquipMine 9 each, BeginRappel 8, MoveToPosition 8.

## Squad top-up: ai_ally_manager (16 in 9 maps)

- maxallies 4 (2 to 5), maxmedics 1 (one has 2, one 0). The manager's SpawnAlly0..3 and SpawnMedicAlly go to
  makers (Spawn, or SpawnNPCInRadius to a 400-stock maker, 4 alive, flag 32) and only for the places missing.
- Fired with Replenish by a trigger_once at each checkpoint the squad reaches (a barricade door, a gate, a roof),
  by map start, by a relay, once by a citizen's OnWake. So the squad is refilled to 4 with one medic at each stage,
  not continuously.
- Rebels: citizentype Default 99 (the game picks rebels from the map's name: from memory), smg1 63, none 22, rpg 12,
  ar2 8, shotgun 2. Flags: fall to ground 98, random head 79, template 71, fade corpse 43, not commandable 29,
  medic 21 (1 to 5 a map), follow on spawn 9. No placed citizen is an ammo giver: ammo comes from 138 item_item_crate
  and 39 item_dynamic_resupply (c01, c02 16 each). ResponseContext reinforcement:1 on 12 top-up rebels.
- Outputs: OnJoinedPlayerSquad > Deactivate their goal (6) or Add to a counter (4); OnDeath > Kill, Break, Add.

## A timed hold: c07 (Alyx at work, about 285 s)

One scripted_sequence (alyx_atwork_seq) is the clock; its OnBeginSequence sends the whole fight on delays: dropship
@20, balcony cop maker @40, north front @50, music @55, dropship 2 @60, south front @80, tower doors @110, 210,
260, radio lines @150, 210, 240, 260, 275, elite makers @250, autosave @210, "4 seconds to go" @266.
Each front: a point_template of 3 soldiers spawned by env_entity_maker (PostSpawnDirectionVariance 0.15); on
spawn the standoff goal Activates and each man's aiscripted_schedule (forcestate 3, goal battle line 1) starts.
A wave relay walks them forward: battle line 1, 2, 3, then the assault, each line a timed window; later waves are
quicker: wave 1 lines @0, 15, 40 and assault @70; wave 2 @0, 10, 30, @50; wave 3 @0, 5, 20, @40; wave 4 @0, 5, 15,
@25; wave 5 @0, 5, 7, @9. All 3 dead (counter max 3, OnDeath Add 1) > reset relay (CancelPending on every wave
relay, lines and goals off, counter 0) > the wave counter Adds 1 and ForceSpawns the next squad @6; a logic_case
on the wave number picks the wave relay (default: the last). "4 seconds to go": Kill and CancelPending the waves,
both fronts' final assault (Activate @0.5, BeginAssault @1), pressure makers on @4, rebels change squad.
ai_goal_standoff here: Aggressiveness 3, PlayerBattleline 1, AbandonIfEnemyHides 1; ai_battle_line Strict 1.
After the hold, "pressure" makers (stock 100, 2 alive, every 1.5 s, schedule "set enemy and run" at the player) run
until the players close the exit gate (gate counter OnHitMax > Kill the makers @3): leave now, or be swamped.

## Rebels at work (scenes)

- Supply drop from a roof (c03 npc_tower_thrower): ai_script_conditions (player looks at him: 20 degree true cone,
  line of sight) > scene "hey, down there" > his throw sequence: OnScriptEvent01 shows a crate prop in his hands,
  OnScriptEvent02 hides it and ForceSpawns an env_entity_maker crate (the real one falls), a counter of crates to
  throw Kills the sequence at its max. c12: a trigger_once spawns a rebel on a roof edge (damage filter keeps him
  alive, removed 10 s later), his scene "cit_dropper01" starts and a point_template drops 3 health kits and 2 item
  crates (357 ammo, 2 batteries) off the edge.
- Password at a hideout door (c06a, c06b bld_a): a rebel behind the door, scenes c17_06_password01 to 04 (male and
  female answer each other), then the door opens; "tunnel_greet" and "firepit_greet" when a rebel joins the squad.
- Prisoners freed (c10a jail, c10b pods): "let us out" scene, then their ai_ally_manager (jail_replenisher, 2 allies
  and a medic) spawns them into the squad.
- Hopper mines given by a rebel at a barricade (c04, c05: c17_05_hoppers, minehelp1, 2).
- Scenes: 164, busyactor 1 on 154; started by relays 54, trigger_once 30, another scene's OnCompletion 26 (chains),
  a sequence's OnBeginSequence 20, ai_script_conditions 6, logic_case (random pick) 10.
- scripted_sequence 150: soldiers 42, citizens 35, zombies 21; flags no-interrupt and override 139, priority 53,
  loop post idle 39, start on spawn 26. Zombies rise (slumprise_b, 18) started by their own OnDamaged (17).
  Props follow the animation by script events (crate shown, crate thrown, wall exploded, weapon given).

## Strider breach (c12; firmer valve-swap-broken)

A trigger_once sends each strider SetCannonTarget at a named npc_bullseye in a pillar or wall (12 lines). The
bullseye (health 20, damagefilter "strider only", flag 65536) on OnDeath: intact brush Disable, hole brush TurnOn,
env_explosion @0 and @0.5, env_shooter concrete chunks, env_physexplosion, a one-shot sound, env_shake, debris
template ForceSpawn, and a node link TurnOn (the hole becomes a path). 64 npc_bullseye in 10 maps: health 35 on 36;
damage filters strider-only 8, turret damage-type 8, mortar 5.

## Schedules, relationships

- aiscripted_schedule 219: run to goal 85, run along a path 76, set enemy and run 34, set enemy 14; goal a
  path_corner 108, !player 64 (single player: our version names the target), another schedule 21, a battle line
  10; interruptible by death only 131; started by makers' OnSpawnNPC 133, trigger_once 25, a sequence's end 13.
- ai_relationship 91: like 38, hate 26, neutral 25, fear 2; applied by makers on spawn 22, triggers 13, map start 9;
  reverted by relays and triggers 16. Striders hate bullseyes and citizens; snipers hate crows (target practice).

## Nodes and hints

- Ground nodes 5271: nearest other median 84 (quartiles 61, 115); dense flats 67 to 73 (c05, c06b, c09).
- Air nodes 442 in 9 maps (c06a 131 about 175 apart; c12b 118, 189; c08 75, 140; c03 48, 215).
- Hint types (meanings as the FGD is remembered): 900 follower wait point 291 (in 10 maps; clusters 59 apart),
  101 cover low 215 (72 apart), 904 strider node 156 (air hints, c12 61), 902 squad transition 110 (near the map
  change, 262 away at the median), 950 ally "move away" spot 91 (84 in c05, the rebel base: 152 apart), 901 jump
  override 87, act busy 12 only 8 (citizens in the street fight do not idle), cover medium 100 only 7.
- Hint groups 25 named by place and job: hintgroup_soldiers_die_2 33, hintgroup_defend 18, strider_street_nodes 18,
  assault_fallback_hintgroup 9, exit_barricade_soldier 8, garrison_3nd_floor_cop_fallbacks 4. ai_changehintgroup
  (6) moves a squad to its next set when its assault clears (4 of 6 from OnAssaultClear): a fallback line.

## The Combine at war

- **Battle lines walk a squad forward.** ai_battle_line 22 (Strict 1 on 15) with ai_goal_standoff 22. Two ways to
  move the line: by time (c07, above) or by arrival (c06b: a trigger_multiple for NPCs, flag 2, round each line;
  3 arrivals, counter max 3, switch to the next line and enable its trigger). Lines 380 to 480 apart (c06b 384, 480;
  c07 430, 380). Respawn: 3 dead (max 3) > a reset relay zeroes every counter, turns lines and goals off, and the
  env_entity_maker spawns 3 more, who get the standoff, line 1 and their schedules at once.
- **Standoff settings.** Aggressiveness 2 (9) or 3 (8); PlayerBattleline 1 on 17; StayAtCover 1 for units holding
  a place (barricade cops, garrison rooms), 0 for those advancing; custom shots 3 to 6 per burst (min 1 to 3),
  2 to 4 s, cover on reload, 25% odds of taking cover. Garrison rooms (c05) Activate their standoff from a cop's
  OnFoundPlayer; when two cops on the 3rd floor die, a fallback relay activates a fallback line, a fallback
  standoff and a schedule to the fallback hint group.
- **Dropships.** 13 in 9 maps; crate 1 (soldiers) 7, none 4, 2 (strider) 2. Spawned by a maker (trigger, the
  hold's clock, or 30 s after the gunship dies), sent FlyToSpecificTrackViaPath at once; a path_track's OnPass
  sends LandTakeCrate(4) or LandLeaveCrate; OnFinishedDropoff: fly away by another track (Killed at its far end,
  out of sight), the troops' assault Activate @0 and BeginAssault @10.5 while a roof gate opens with a sound and
  its node link turns on @10. Rally points there play "cower" while they wait (rallysequence).
- **Flybys for atmosphere** (c10a): a maker (stock 2, 1 alive) sends a dropship or gunship along a path; at the far
  end the ship is Killed (out of view) and the maker told Spawn again 20 or 30 s later; the gunship is made neutral
  (disposition 4) to players and citizens on spawn @0.5, so it is scenery; a trigger_once Kills the maker when the
  player moves on. c04, c05, c09, c12b: a "firstdropship" carrying a strider or nothing crosses the sky once.
- **Strider and gunship.** Striders from makers (12) walk path_corners (OnPass Stand, SetTargetPath, Kill at the
  end); 904 strider hints on their streets; a strider's death enables the next resupply trigger and spawns the next
  strider (c12): rest and resupply between waves.
- **Snipers (c09, 5).** In windows 281 to 409 above the street; EnableSniper from a trigger as the player arrives
  (one from map start @5), Kill when passed; PaintInterval 1 s (variance 0.75): the laser shows before the shot;
  they hate crows (a flock of 5 to shoot first); a func_brush blocks one sniper's view until he dies; when one dies
  another SweepGroupRandomly over sweep targets; two dead (counter max 2) ends the street.
- **Ambient battle.** env_gunfire 15 (c07, c11, c12b): unseen guns firing tracers (AR2TRACER) at named targets,
  bursts 2 to 7 shots, 2 to 5 s apart, rate 10 to 15, spread 5, sounds Weapon_AR2.NPC_Single or SMG1; all start
  disabled and are Enabled by relays (13) as the fight nears, Killed when passed.
- **Debris.** env_shooter 50: concrete chunks (props_debris) 1 to 4 a shot, velocity 400 to 800, life 4 s, fired
  by a bullseye's OnDeath, a sequence's script event or a relay: walls hit by a strider or a mortar.
- **Danger sound.** ai_sound 13: InsertSound, soundtype 8 (danger), volume 120, duration 0.5, fired by relays and
  triggers just before something blows: NPCs scatter from the spot.
- **Weapons left on the ground.** game_weapon_manager 6 (c07, c11, c12): ar2 or smg1, maxpieces 2 to 4, ammomod 1:
  in long fights only that many dropped guns stay.
- **Headcrab shelling (c06b).** env_headcrabcanister 4: FlightSpeed 2000, FlightTime 0.5 to 1, Damage 100 to 150 in
  150 to 200, 6 headcrabs, smoke 30 s; fired from relays or a path_corner; OnImpacted chains the next canister,
  explosions, fire and a relationship change.

## The Overwatch Nexus inside (c10b)

- **Tripwires that re-arm.** 32 env_beam lasers (colour 170 0 0, width 0.2, 78 to 414 long, median 202, TouchType 1,
  filter "not npc_combine_s" so soldiers pass) and a trigger_multiple per room fire a "detected" relay: lasers off,
  alarm sound for 1.5 s, two turret lifts (func_door) Open and their npc_turret_ground Enable. A turret's
  OnAreaClear closes its lift (the lift's OnClose disables it). A counter of lifts shut (max 2: Subtract on
  OnFullyOpen, Add on OnFullyClosed) turns the lasers back on and re-enables the trigger. Both turrets dead (death
  counter max 2): lasers off for good, the re-arm counter and trigger Killed, the squad's holding assault ends.
- **Three switches.** Each of three control rooms has a force field fed by a Combine ball spawner; taking the ball
  (OnBallGrabbed) fires that room's relay: field Kill, generator off, sparks, shake, sounds, counter Add 1. Counter
  max 3: every laser and turret trigger Killed, turrets SetHealth 0, the fields' node links on, a shake, an
  autosave, the last squad spawned and its assault Activated 1 s later.
- **Combine-only paths.** info_node_link and controllers with AllowUse npc_combine_s (13 in c10b): soldiers path
  through the force fields while they are up; TurnOn for everyone when the fields fall.
- 6 npc_turret_ceiling and 2 npc_combine_camera (inner 700 or 800, outer 1000) Enabled by relays; a camera's
  OnFoundEnemy fires the alarm.
