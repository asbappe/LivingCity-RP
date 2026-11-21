# Episode One's City 17: entity logic and NPC scripting (work in progress, 21 November)

Ten maps: ep1_c17_00, 00a (the dark and the lift), 01, 01a (start of the evacuation, the gate), 02 (the guard
and the garrison), 02a (the hospital), 02b, 03, 05 (the station), 06 (the train out, the strider). Read as text
with a parser in the scratch folder; numbers below are counted from the VMFs. [owner] = ask the owner first.
Only what is NEW or firmer than the lessons from City 17's uprising, Ravenholm, Nova Prospekt and Black Mesa East.

## NPC counts (10 maps)

177 zombies and crabs (npc_zombie 69, zombine 54, black crabs 17, crabs 12, torsos 9, fast 7, poison 5); 92
npc_combine_s; 77 npc_template_maker; 21 citizens (8 in 02b, 6 in 05); 2 striders; 5 gunships; 5 dropships;
11 antlion makers. Of zombies that state a sleep, 46 wait for an input (sleepstate 3) and 11 wait until seen (2).

## 1. The dark: the dead come when your light is off (00, 00a)

- **The rule (00, tunnel_darkness):** logic_playerproxy OnFlashlightOff sends the flashlight's charge to a
  logic_compare (CompareValue .7). Below it, a relay picks one of three cases at random; each spawns one or two
  of zombine, zombie, torso, 1 to 5 s apart, from npc_template_maker with CriterionVisibility 1 (only where no
  player sees) at 31 info_npc_spawn_destination spots along about 4000 of tunnel (ReuseDelay 20). Each one, 0.1 s
  after spawning, is given an aiscripted_schedule (walk to the player). After a spawn the relay is shut for 20 s.
  OnFlashlightOn cancels every spawn still pending. In the lit rooms (trigger_darkness_spawners) none come.
- **A flare is a shield:** picking up a flare (OnPhysGunPickup) sets SetMinimumSpawnDistance 1000 on the maker
  for 30 s (a logic_timer, RefireTime 30, then back to 0).
- **The lift's dark (00a):** the same, capped: math_count_flashlight (max 2) counts the darkness dead alive; at 2
  no more come until they die (OnAllLiveChildrenDead subtracts). Spawns 1 to 3 s after the light goes off.
- **Seeing in the dark:** env_global ep_alyx_darknessmode switched by 6 triggers; 22 info_darknessmode_lightsource
  in 00 (radius 59 to 512, median 128) mark the lit pools (fires, lamps) where the companion can see.
- **A person asks for the light:** ai_script_conditions (Alyx cannot see the power box) start a timer every 10 to
  16 s: Alyx SpeakResponseConcept ShineLightOnPowerbox. Stops when the box is lit.
- **Never stuck without ammo:** a counter of 2 weapon pickups starts a 2 s timer asking the player's ammo; on
  PlayerHasNoAmmo a padlock breaks and another way opens.

## 2. The lift: a timed hold with a visible clock (00a)

- Alyx starts the lift at the power box; zombie waves Enable at @5, @35, @65, @85 (logic_zombie_wave_01 to 04,
  2 or 3 makers each, CriterionVisibility 1, live 1 to 3); the lift timer is 79 to 80 s from @5.
- The floor lamps step every 20 s (logic_case InValue 1, 2, 3 at @0, 20, 40; 4 when the car arrives): the clock
  is a row of lit floor sprites, not a number.
- The car leaves only when everyone is in: counter_elevator (max 2) Add on StartTouch, Subtract on EndTouch, for
  Alyx and the player. At max: doors close, a player clip blocks the way, and every zombie (aiscripted_schedule
  graball 1, run) rushes the shaft: a last wave as the doors shut.

## 3. Burrows plugged by cars (00a, 01, 02)

- Car park: three npc_antlion_template_maker, each with its own group of 1 to 3 burrow hints (hinttype 400).
  OnAllBlocked (every hint covered by a physics prop) adds 1 to counter_BlockedHoles (max 3) and stops that
  burrow's spore puff (env_spore Disable); a later spawn there (the car pushed off) subtracts 1 and the spores come
  back. The spores show which burrows are still open.
- Pressure moves to the open holes: a second counter (max 1) sets the others to pool_regen 2 s and 2 alive while
  any hole is plugged, back to 12 s and 1 when none.
- All three plugged: Alyx's 'holes blocked' line; the fight ends. In 01, counter_coveredburrows (max 2) counts
  trigger_multiples touched by cars; in 02, the guard's death sets counter_antlions_neutralized to max.
- Antlion makers: pool_start 1 to 4, pool_regen 1 to 25 s, live 1 to 3; createspores 1 and ignorebugbait 1 on all.

## 4. The Combine's last hold of the streets (01, 01a, 02)

- **A gate that lets out waves (01a):** a squad of 3 is ForceSpawned behind a barricade gate; the gate opens when
  they arrive at its rally point (counter_gateAssault OnArrival) and they assault. All 3 dead adds 2 to
  counter_WaveRestart, whose value becomes the restart timer's RefireTime: 2, 4, 6 s... (each wave waits 2 s
  longer). counter_gateWaves stops it at 6 waves. A car pushed into the gateway (trigger_car_detect StartTouch)
  disables relay_closeGate: the gate can be jammed open.
- **The crushing wall (01):** the Combine's wall advances in three stutters (relay_openwall: animation 12 s,
  scrape sounds @0 and @5, impact, smoke, shake and a trigger_hurt of 250 open for 0.5 s at @8); after the third
  it falls shut, killing the city screen that was showing Kleiner. Danger sound to NPCs @0 and @4.
- **Kleiner on the city screens (01, 01a):** 13 scenes chained OnCompletion on one monitor through a point_camera;
  the map starts the loop at scene 5 (players join mid-broadcast); after scene 13 the screen goes blank @2 and the
  loop starts again @5.
- **Fleeing citizens (02):** 7 assault_rallypoints spread 300 to 700 apart all lead to one assault point
  (Assaultpoint_fleeing_citizens, tolerance 36, timeout 3); a second set of 7 leads to a second point. Wherever a
  citizen is, he runs to the nearest rally spot and then to the gathering place.
- **Breaching the garrison (02):** relay_bustfrontdoor: lock beeps every 2 s, then every 0.2 s from @8, danger
  sound @8, blast @9.02, assault @9.3 (firmer valve-breach-buildup).
- **Guard and APC (02):** the antlion guard is woken and SetChargeTarget at the APC's bullseye; a 1 s timer sets
  its health to 99999 until the APC dies (a set piece's beast cannot die early).

## 5. The hospital (02a)

- **Combine and the dead together:** each logic_hospital_spawner_N enables makers of zombies and zombines beside
  makers of soldiers with shotgun, SMG or AR2 (CriterionVisibility 1, MaxLive 1 to 2, MinSpawnDistance 30). The
  soldiers hate crabs at a low rank. A counter of 4 standoff soldiers' deaths shuts the zombie makers 5 s later.
- **The dead behind doors:** a timer every 1 to 1.5 s opens a door a crack and shuts it 0.5 s later, with a bang
  loop; opening it lets the poison zombie out. A holdout room: a random 20 to 40 s timer, then bangs at @0, 2, 4,
  5, 5.5, 5.8, 6, 6.1 and the door breaks at @6.3 with a group spawn; breaking it early cancels all of that.
- **The gunship at the windows:** 3 bullseyes in each window; the gunship hates them (rank 1); when all 3 are shot
  a counter respawns them: the strafing runs along the windows without end. When hit (OnDamagedByPlayer) it
  flies to a random spot of its track (PickRandomShuffle of 5 or more). Targets for it respawn every 8 to 12 s.
  The rebel with the RPG is shot first; his boards break and the launcher is the player's.
- **Building supports:** 13 math_counters (max 2): two breakables broken free a physbox (EnableMotion).

## Still to read: 02b, 03, 05, 06 (Barney, the citizens, the station, the train, the strider and advisors)

## For Living City (draft)

- [owner] Night and dark districts: the dead come where no light is (spawn only unseen, 20 s apart, capped at 2
  alive per player); a lit lamp or a flare holds them 1000 off for 30 s. Changes how our night zombies behave.
- [owner] Antlion districts: burrows plugged by pushing cars or crates over them; spores show the open ones; the
  others spawn faster while one is plugged; all plugged ends the incursion. A new way to clear antlions.
- [owner] A Combine checkpoint gate that lets out squads of 3, up to 6 times, the gap growing 2 s each; a car
  jammed in the gate keeps it open.
- [map] Fleeing citizens: rally spots 300 to 700 apart that all lead to one gathering place (evacuations).
- [owner] Clinic under siege: zombies banging on the doors, bangs quickening for 6 s before the door gives.
