# Episode One's City 17: entity logic and NPC scripting (21 November)

Ten maps: ep1_c17_00, 00a (the dark, the lift, the car park), 01, 01a (the evacuation starts, the gate), 02 (the
guard and the garrison), 02a (the hospital), 02b (the safehouses, the raid), 03 (the gears, Alyx on the roofs),
05 (the escort to the trains), 06 (the train out, the strider, the advisors' pods). Read as text with a parser in
the scratch folder; every number is counted from the VMFs. Only what is NEW or firmer than the lessons from City
17's uprising, Ravenholm, Nova Prospekt and Black Mesa East. [owner] = ask the owner first. Draft lessons:
`logic_npc_lessons.json` here (8 new, 7 extras).

## NPC counts (10 maps)

177 zombies and crabs (npc_zombie 69, zombine 54, black crabs 17, crabs 12, torsos 9, fast 7, poison 5); 92
npc_combine_s but only 4 metropolice (05): the soldiers hold the falling city; 77 npc_template_maker; 21 citizens
(8 in 02b, 6 in 05); 2 striders, 5 gunships, 5 dropships, 11 antlion makers. Of the 135 zombies that state a
sleep, 46 wait for an input (sleepstate 3) and 11 until seen (2); 54 zombie_slump act busy hints in 6 maps.

## 1. The dark: the dead come when your light is off (00, 00a)

- **The rule (00):** logic_playerproxy OnFlashlightOff sends the charge to a logic_compare (CompareValue .7);
  below it a relay picks one of 3 cases: zombine, zombie or torso pairs @1, @3 or @5 from npc_template_maker with
  CriterionVisibility 1 (only unseen) into 32 info_npc_spawn_destination (ReuseDelay 20, nearest median 114)
  along about 5000 of tunnel; each gets an aiscripted_schedule (walk at the player) @0.1. After a spawn the relay
  shuts for 20 s. OnFlashlightOn cancels all pending spawns. Lit rooms (trigger_darkness_spawners): none.
- **A flare is a shield:** picking one up (OnPhysGunPickup) sets SetMinimumSpawnDistance 1000 for 30 s.
  5 flare props in 00, 8 in 00a.
- **Capped (00a):** math_count_flashlight (max 2) stops dark spawns while 2 are alive.
- **Seeing in the dark:** env_global ep_alyx_darknessmode switched by 6 triggers; 25 info_darknessmode_lightsource
  (22 in 00, radius 59 to 512, median 128) mark the lit pools where the companion sees.
- **Lights:** 00 has 26 point lights (median brightness 35) and 22 spots over about 5000 by 10000: dark on purpose.
- **A person asks for light:** while Alyx cannot see the power box, every 10 to 16 s 'shine your light on it'.
- **Never stuck without ammo:** two gun pickups start a 2 s ammo check; PlayerHasNoAmmo breaks a padlock.

## 2. The lift: a timed hold with a visible clock (00a)

- Zombie waves Enable 2 or 3 makers each at @5, @35, @65, @85 (all unseen spawns, live 1 to 3); the car comes
  79 to 80 s after @5. The floor lamps step 1, 2, 3 at @0, 20, 40 and 4 on arrival: the clock is a lit row.
- It leaves only when everyone is in: counter_elevator (max 2) Add on StartTouch, Subtract on EndTouch. Then a
  clip shuts the way and every zombie runs at the shaft (aiscripted_schedule graball 1): a last rush.

## 3. Burrows plugged by cars (00, 00a, 01, 02)

- Car park: 3 antlion makers, each with 1 to 3 burrow hints (400). OnAllBlocked (all hints covered by physics
  props) adds 1 to counter_BlockedHoles (max 3) and stops that burrow's spores; a later spawn (car moved)
  subtracts 1 and the spores return. While any is plugged the others regen in 2 s with 2 alive (12 s and 1 when
  none). All 3: Alyx's line, the way on. 00's training burrow: OnAllBlocked plays 'good work'. 01: a counter of
  2 covered burrows from trigger_multiples. All 11 antlion makers: createspores 1, ignorebugbait 1.

## 4. The Combine's last hold (01, 01a, 02, 02b)

- **Gate waves (01a):** a squad of 3 spawns behind a barricade gate, which opens when they reach its rally point;
  all 3 dead adds 2 to the restart timer's RefireTime (2, 4, 6 s), 6 waves at most; a car in the gateway
  (trigger_car_detect) stops it shutting.
- **The crushing wall (01):** three stutters (12 s animation, scrapes @0 and @5, impact, smoke, shake and a 250
  trigger_hurt open 0.5 s at @8), then it falls shut, killing the screen that showed Kleiner.
- **Rappellers (01):** 4 from a dropship; a counter of their 4 deaths opens the next stretch. A dropship drops
  rollermines on a 100 to 200 s timer, 20 drops at most.
- **Fleeing citizens (02):** 7 rally points (nearest 148 to 640) that lead 72 to 1075 on to one assault point
  (tolerance 36, timeout 3); a second set of 7 to a second point.
- **Breach (02, 02b):** relay_bustfrontdoor: beeps every 2 s, every 0.2 s from @8, blast @9.02, assault @9.3.
- **Guard and APC (02):** the antlion guard charges the APC's bullseye; a 1 s timer keeps its health at 99999
  until the APC dies.
- **East front (02b):** d3_c17_07's battle-line waves again (eastfront_wave relays, 3 battle lines,
  respawn counter, a stop counter).

## 5. The hospital (02a)

- Each logic_hospital_spawner_N enables zombie and zombine makers beside soldier makers (shotgun, SMG, AR2),
  CriterionVisibility 1, live 1 to 2. Soldiers hate crabs at a low rank. 4 standoff soldiers dead: zombie makers
  off 5 s later.
- **The dead behind doors:** a timer every 1 to 1.5 s cracks a door open for 0.5 s with a bang loop; opening it
  lets the poison zombie out. A holdout room: a random 20 to 40 s, then bangs at @0, 2, 4, 5, 5.5, 5.8, 6, 6.1
  and the door breaks @6.3 with a group spawn; breaking it first cancels it all.
- **The gunship at the windows:** 3 bullseyes per window, respawned when all 3 are shot (endless strafing); when
  hit it flies to a random spot of its track (PickRandomShuffle); new targets every 8 to 12 s. The rebel with the
  RPG is shot first and his launcher left for the player.
- Supplies: 21 item_dynamic_resupply loose and 19 in crates; 13 counters (max 2) free a physbox when two supports
  break.

## 6. Safehouses and the raid (02b)

- **Slot doors (2):** door03_slotted_left.mdl with a door03_slot.mdl prop. The guide arrives, the slot opens @1
  after the first line, the password, the slot shuts, the door is unlocked and opened away from the guest @1.
  The guide dead: slot open @0, shut @2, the door opens anyway.
- **Calling the player over:** after the gate opens, a citizen says 'over here' every 10 to 20 s until he sees
  the player within 600 (ai_script_conditions), then leads him in.
- **The guide spawns unseen:** npcmaker_greeter spawns him when the last rappeller dies.
- **The TV room:** a trigger round the screen adds kcaston:1 to the player while inside (0 when he leaves), so
  Alyx comments on Kleiner only if he is listening.
- **The raid:** Barney's door slot opens and shuts, two shotgun citizens hold the door and raise the alarm.
- Speech filters: 6 in 02b and 06, all NeverSayHello 1, 4 with IdleModifier 0.

## 7. Alyx on the roofs (03)

- 7 roof snipe spots (all z 377, 304 to 600 apart); 7 zone triggers each switch her to their spot. Endless
  wanderers below (antlion 5, zombine 4, zombie 2, fast 1 alive, every 0.1 s, unseen); OnLostPlayerLOS sets their
  health to 1 so her shots kill. Two gears put in place (trigger with a filter, counter of 2) start the lift.
- 43 item_dynamic_resupply in this one small map.

## 8. The escort to the trains (05)

- Groups wait hidden by a door (assault_citizen_wait, neutral to the player): 4, then 2, 4, 2, 2. Picked up:
  player squad, like the player. At the train: leave the squad, board, damage filter 'safe'.
- The trip ends when the board counter (max = group size) is full, fed by boarding AND deaths; all dead, or the
  escort walking out without them (trigger_outStation adds 10), brings the next group.
- Trips TO and FROM counted (max 6); 16 logic_compares give each trip its own Combine answer: scanner bombers and
  manhacks, a dropship and soldiers @5 to 6, a random bomber and a sniper, the APC and a car group, the trainkiller
  and roof soldiers, a breach. Soldiers left on a leg are killed (SetHealth 0) when the escort passes on.
- The first group cannot be hurt (damage filter allowing only !null), removed once they board: a rehearsal.
- Talk: 'next group' re-armed every 10 s until pickup; a citizen at the train door turns the player back (20 s);
  E on a refugee aboard, one line every 10 s; Alyx's line on each boarding.
- The last train: a counter of 5 (refugees aboard or dead, Alyx and Barney at their spots, the player aboard).
- **The Combine see you:** a camera (inner 288, outer 408, invulnerable till then) OnFoundEnemy: screens to static
  @0, the advisor @0.5, static @3, off @3.5, the broadcast cancelled, the lights by the exit out.
- **Kleiner on the screens (01, 01a, 02b, 05):** 13 scenes chained on one monitor through a point_camera; the map
  starts at scene 5; after 13 the screen is blank @2 and the loop restarts @5.

## 9. The train out (06)

- **The goodbye:** a counter of 2 holds the farewell scene until both are in place; its Trigger3 starts the train
  (horn @0, start sound and StartForward @2).
- **Nags in two voices:** a logic_timer of 5 to 10 s in alternating mode: OnTimerHigh Alyx (7 shuffled lines),
  OnTimerLow Barney (4); killed the moment the player goes through.
- **The strider:** SetCannonTarget on bullseyes inside the containers players hide in, one after another; each
  blast sets the next target; a failsafe kills the target 8 s after its trigger if the strider missed.
  Headcrab canisters land on the train cars 0.3 s after a container blows, crabs out @1.3.
- **The advisors leave:** two launch sites each spawn a pod every 1.5 s while the train passes (13 s); a counter
  1 to 8 picks one of 8 flight paths in turn (not random): the sky fills with pods going different ways.
- The razor train: speeds 300, 330 @4, 400 @8 (relay_train_slowdown).

## For Living City ([owner] ask first; [map] map pieces)

1. [owner] Night and dark districts: dead that come only unseen, at most 2 per stretch, 20 s apart, held off by
   a flashlight or a flare within 1000 (valve-dark-spawns).
2. [owner] Antlion districts: burrows shut by pushing cars or crates over their holes, spores on the open ones,
   the rest angrier while one is shut (valve-burrow-plugs).
3. [owner] Evacuations and the station: trips of 2 to 4 refugees from a door to the train, counted aboard or
   dead, a new Combine answer each trip, the first group a rehearsal (valve-evac-trips). [map] rally spots 150 to
   650 apart leading to a gathering place.
4. [owner] An uprising's Combine gate: squads of 3, six times, 2 s slower each; a car jams it (valve-gate-waves).
5. [owner] The clinic besieged by the infested: doors cracking open and banging, quickening for 6 s before one
   gives (extra on valve-breach-buildup); Combine and zombies fighting in the wards.
6. [owner] A Resistance door with a slot that opens on a knock (valve-slot-door).
7. [owner] Cabinets and caches that give what the finder lacks (valve-supplies-by-need).
8. [owner] A rebel marksman moving between roof spots over the players' fight (valve-rooftop-cover).
9. [owner] Broadcasts that loop and are joined midway; the Combine cutting into the screens when a camera spots
   a wanted player (valve-screens-cut-in).
10. [owner] For the collapse: the Combine's leaders leaving as a stream of pods on 8 paths, one every 1.5 s;
    soldiers, not police, holding the last streets (92 to 4).

## Check ideas

- robots.py: an escort trip ends whatever happens to its group; a lift or hold leaves only with all players in.
- A test that no spawn from the dark happens within a player's sight, near a flare, or past the cap.
- A test that a burrow covered by props stops spawning and opens again when uncovered.
- map_lint: a gate piece has a clip and an inside rally spot; burrow holes have a heavy prop within 300.

## What did not work

- Single-player tricks not to copy: !player as a goal (the dark spawns walk at player 1), point_teleport of Alyx
  (12) to keep her up, the guard's 99999 health, OnLostPlayerLOS health 1 (with many players it means nothing).
- Hint types are read from memory of the FGD (900 follower wait, 950 ally move-away, 400 burrow, 12 act busy,
  13 visually interesting, 451 crab pod exit); 901 counted 46 in 05 is uncertain.
- 00 has 34 outputs aimed at names missing from the map (elev_darkness_* live in 00a; some are commented '//').
- Choreographed scenes (.vcd) are not in the VMFs: what is said is guessed from file names.
