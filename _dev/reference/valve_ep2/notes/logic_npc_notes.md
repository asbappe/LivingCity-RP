# Episode Two: entity logic and NPC scripting (work in progress, 21 November)

Read as text from the 18 EP2 game maps (ep2_outland_01 to 12a). Only what is NEW or firmer than the 237 lessons. [owner] = changes how our NPCs or features behave: ask the owner first. [map] = a map piece.

## Class counts (logic and NPCs, 18 maps)

info_node_hint 881, logic_relay 857, trigger_once 659, logic_choreographed_scene 507, scripted_sequence 404,
point_template 391, npc_antlion_grub 340, ai_relationship 324, ai_script_conditions 161, npc_bullseye 125,
logic_timer 124, math_counter 123, npc_antlion 104, npc_template_maker 91, logic_case 60, logic_branch 53,
ai_goal_actbusy 35, npc_antlion_template_maker 28, npc_hunter 27, npc_strider 18, npc_antlionguard 5, npc_advisor 3.
Burrow hints (hinttype 400): 13, 30, 29, 35 in 01a, 02, 03, 05.

Which map is what: 01 the wreck; 01a the first antlion caves; 02 the mine arena (Griggs, Sheckley, the turrets) and
the vortigaunts' healing; 03 the caves and the zombie miners' lift holdout; 04 the guardian's maze and the extract;
05 the thumpers, the two guardians and the basket lift; 06 the car and the zombie pits; 06a the radio tower and the
first hunters; 07 the farm and the advisor; 08 the train yard; 09 the caches and the welder; 10 the town and the
hunters' siege; 10a the gate and the race; 11 White Forest's gate and silo; 11a the abandoned silo; 11b the
striderbuster school; 12 the battle; 12a the launch.

## 1. The antlion caves

**The mine arena holdout, 02 (the best wave fight in Valve's maps so far).** Four tunnels (00 to 03) into one
room held by two NPC rebels and two floor turrets. Each tunnel has a looping siren (radius 1250) and three
`point_spotlight`s marked easy, medium, hard. A `GO_spawnNN_tier` relay plays the tunnel's siren and lights one, two
or three of its lamps (the lamp props change skin with them), then enables that tunnel's maker **20 s later** (15 s
for the final wave). The first antlion out stops the siren; when all from a tunnel are dead its lamps go out. So a
player always knows where the next wave comes from and how big it is, from the world alone.
- Seven waves from a `logic_case` "pattern master" fed by a counter: 1 tunnel (medium), 2, 3, 3 (one medium), 4, 4
  (one medium), then all four at once (21 each, 2 or 3 alive). The wave counter's max is set to the number of tunnels
  open (`SetHitMax 1, 2, 3, 3, 4, 4`); each tunnel's maker adds 1 `OnAllSpawnedDead`.
- Wave over: autosave, a 6 s timer (refire 6, disables itself), the rebels speak "wave end" (response context
  `wave:N`, so each wave has its own lines), the next pattern. Each new wave `SetHealth 100` on the rebels: the AI
  allies are topped up, not the player.
- Tiers: easy 3 or 4 alive of 16, one per second; medium 4 to 6 of 32, every 0.05 to 0.1 s; hard 4 of 40. The rebels run
  `ai_goal_assault` to the tunnel mouth that is about to open (a case per wave).
- A pressure valve: a trigger counts antlions inside the room; 8 at once ends the wave (makers `SetMaxChildren 0`,
  disabled). `game_ragdoll_manager` capped to 3 from wave 4.
- Wave 6 takes the defence away on purpose: the turrets run dry at 50 and 60 s (`DepleteAmmo`, steam and sparks, a
  rebel shouts), and the antlions stop ignoring the turrets. Wave 7 the vortigaunts arrive with their own assault.
  The end: the final counter (4) stops the music in 7 s, the vortigaunts go calm, strays are killed off (`SetHealth
  0` @8), and the healing begins.

**The guardian's chase, 04 (`maze_guard`).** An antlion guardian that cannot die (`OnHalfHealth > SetHealth 500`)
hunts the player through a maze of crawlspaces too low for it. Entering a crawlspace (a trigger at its middle)
sends the guardian to a waiting spot at the mouth (`scripted_sequence`, post idle) and starts a timer at random 7 to
15 s that picks dust, roars and pounding from a `logic_case`. Leaving it by either end (`playerout` triggers)
cancels that and starts an `aiscripted_schedule` "run to the player". Its leaps are scripted, with stalactites
falling; it ends bashing through a boarded exit (breakables that spawn broken boards from templates). Sounds
before sight: three relays play rubble, shake, impacts and roars down the tunnel at 0, 1, 1.5, 3.4, 4.5, 8 and 11 s
before it is seen.

**Two guardians and the swarm, 05.** Guard 2 spawns, guard 1 follows 15 s later (a timer that kills itself). A
`func_brush` that blocks only antlion guardians (`excludednpc` with `invert_exclusion 1`) keeps them in their
arena while players pass. If the player runs far back, a trigger turns the guardians on Alyx and the vortigaunt
instead; coming back in turns them on the player again (a leash both ways, with `OnLostPlayer` doing the same).
Both dead (counter 2): the antlions still out get `ai_relationship` "hate" rank 100 on a far `npc_bullseye`, run
to it, and a trigger there kills each antlion that touches it, out of sight. The swarm leaves; it is not mopped up.

**Thumpers, 05.** Three `prop_thumper`, effect radius 512, about 1420 and 1680 apart along the sand: safe islands
to run between. Out in the open the antlions come from makers with a **pool**: 1 alive of 5, the pool refilled 5
every 30 s (caves); 2 alive of 3, refilled every 20 s (sand); spawn at a random burrow (flag 1024). Kill them all
and you have a breather; stand still and they come back. Nags at each thumper count up and stop after 3.

**Staged moments in the caves, 01a and 03.** The antlion is busy with something of its own until disturbed:
feasting antlions (start burrowed, "hate" rank 100 on a `npc_bullseye` at a corpse, a physics clip keeps the corpse
in place; hurt one and it drops the corpse; a relay sends all at the player); lure workers walking to a bullseye
until a trigger wakes them; a ceiling spitter that waits until the player looks at it (`ai_script_conditions`, FOV
45, true cone, timeout 15 to 16 s, then it acts anyway). 161 `ai_script_conditions` in EP2 (48 in 12).
Spitters (workers, spawnflag 262144) are 31 of the 104 antlions.

**Grubs.** 340 `npc_antlion_grub` (93, 143, 96 in 01a, 03, 04): mostly in twos and threes (clusters within 160:
in 03, 11 alone, 22 pairs, 21 threes), 22 to 50 from the nearest other, along the cave floor and walls. A few are
named to be squashed by the guardian in a scene. Each killed by a player counts to an achievement.

**Zombie miners and the lift holdout, 03.** Dead miners slump on work hints (hinttype 12, `zombie_slump_a`, `_b`,
21 hints), held by `ai_goal_actbusy` with a search range of 64 (each to his own spot). The wake relay deactivates
the goals one by one at 0, 1, 3, 5 and 7 s, so they rise in turn, and sends antlions 5 s after. The lift: the call
button at the bottom locks itself, lights the lamps, starts the cage down (a `func_tracktrain` at speed 35 down
about 1260, so about 36 s), a red lamp 5 s later and the zombies' makers 10 s later. Riding: the cage climbs only
while someone stands in it (`OnStartTouch` go, `OnEndTouch` back down to fetch them). A holdout that is a wait for
a slow machine the players can see coming; the fighting fills the wait.
The mine carts (03) are scripted rides: a `func_tracktrain` rolls down (200 to 1000), at the track's end it is killed and
the cart turned to physics (`phys_convert`) to crash, the player unhurt for 6 s.

**The extract and the healing, 02 and 04.** The extract is a glowing prop with a light parented to it, carried
from the guardian's chamber. The healing is a scene: the extract handed over (it is re-parented to the
vortigaunt's hand by script event), eaten (a particle at the mouth, a sound), four vortigaunts round Alyx with a
chant loop and random single chants (timer 7 to 9 s), then all `TurnBlue 0` and they unfreeze 0, 0.1, 0.3, 0.4 s
apart. The gman's slow field is switched on for the middle of it.

## 2. Hunters

27 `npc_hunter` in 6 maps, always in a squad of 2 or 3 (06a `hunter_squad` 3, 10 `hunter_squad` 2, 11a
`huntersquadgo` 3, 12 one squad of 3 per strider). Their flanking is the hunter's own squad AI; the maps only give
them a squad, a zone and a target.
- **First sight, 06a.** Three hunters circle the house the players hide in. Each is first glimpsed in turn: look
  triggers enabled 1.5 and 2.5 s after the first is seen (`ai_script_conditions`, FOV 60, timeout 3 s, then anyway).
  While the players hide, the hunters fire at `npc_bullseye`s by the hiding place (pinning, not killing); a trigger
  releases them. The first is invulnerable until the scene is over. Three dead (counter 3): music fades in 1 s, the
  next task opens 4 s later.
- **A zone each.** `hintgroup` with `hintlimiting 1` keeps a hunter inside its own patch (06a, 10, 11a catwalk).
- **The siege of the inn, 10.** Five phases from one relay chain: phase 1 starts the soldiers and enables two hunter
  makers 7 s later; phase 2 at 80 s; phase 3 at 55 s more; phase 4 when two `logic_branch`es are both true (soldiers
  dead and another condition: `logic_branch_listener OnAllTrue`); phase 5 the hunters break in. The hunters hide
  (`ai_changehintgroup` to a hide group, `UseSiegeTargets`) and fire into the house; at the end each goes to a door,
  plants, and the door is made a bullseye only it may damage (`SetDamageFilter`), so it bursts the door it chose.
  The hunters are neutral to the player while he stays inside; a trigger outside makes one hate him at once and
  forgets him when he goes back in (wait 4). The soldiers shoot at window bullseyes in sets that change every 6 to 8
  s (front 2, 4, 6 for 6 s; front 1, 2, 3 from 8 to 15 s; again at 17 s). Leftover soldiers at the end walk to a
  spot out of sight (`scripted_sequence`) where a trigger removes them.
- **Reinforcement by health, 11a.** When a hunter is at half health (`OnHalfHealth`, once) the next hunter and the
  manhack makers come. Another hunter crawls along a `path_track`, shooting, then `SetSquad` joins the others.
- **With striders, 12.** Each strider's maker relay spawns three hunters with it (`npc_hunter_maker SpawnMultiple 3`,
  `FollowStrider`); they go ahead of it at the outposts.

## 3. The battle for White Forest, 12 (a defence with waves and an end)

- 13 striders from three sides (north, east, west), one maker each, started in turn by relays with long delays;
  each strider gets three hunters, an announcer line ("strider 1" to "strider 13", 74 scenes in the map) and a
  path chosen by triggers on its way in. The win is the last five striders dead (`victory_counter` max 5). Each
  defender is a maker of one (`defence_cit_*`, enabled from the start, every 5 s): killed, he is replaced from the
  base door, which opens for him (`basedoor Open` on spawn).
- **The outposts (cabin, lodge, sawmill, outpost)**, each with rebels inside. A strider walks up, its hunters are
  set on bullseyes inside the building in turns (30 s cycle), the rebels run out on seven `scripted_sequence`s 20 s
  after the strider spawns, and when the hunters are out the evacuation is cancelled and clip brushes shut the way.
  Then the strider's cannon targets a bullseye in the building, and `cabin_destroy_relay` swaps it whole (brushes,
  lods and props killed, breakables broken, physics props let go, sparks for 20 and 30 s, smoke at 1 s, a broken
  model from a template).
- **The loss:** a strider within reach of the base trips an alarm, slows to 0.75 speed and the announcer warns;
  leaving it stops the alarm. If it reaches the silo, `base_destroy_relay` ends the game (shockwave, white fade,
  reload at 8 s).
- **Striderbusters on pads.** Six Magnusson devices, each on a teleporter pad with an idle hum (radius 3000) and a
  car radar mark. A trigger that feels physics objects (flag 8) notices when the device leaves the pad; the pad
  spins up and 7 s later a new one appears from a template. Never more than one per pad; never runs out. A device
  shot down by a hunter adds to a counter and a rebel tells the players to shoot the hunters first.
- **Victory:** the base gate and doors open, the announcer, hunters retreat (relay at 7 and 9 s), the defenders
  walk back on scripted sequences at 18 s, achievement, save.

## 4. White Forest at work (11, 11a, 11b, 12a)

- **Big doors are slow and loud.** The round blast doors: two leaves turning 60 degrees at 6 a second (10 s), a lock
  bar that drops first and shuts after (`OnFullyClosed > lock Close`), start, loop and end sounds; the lift opens
  them as it passes a `path_track`. The silo's seal doors (11a): `func_movelinear` 136 at speed 5, about 27 s, with
  start, loop and stop sounds; while they close, soldiers come from a hole (a maker of 50, 2 alive, every 3 to 5 s),
  rappel from a dropship and three manhacks fly in; shut, the makers stop and the alarm ends. The base gate (12):
  240 at 30, 8 s. Ours: the bunker's leaves slide 120 at 26, 4.6 s.
- **A door that has broken down (11):** it toggles open and shut every 0.8 to 1.5 s with a random one of five button
  sounds and a spark, until a vortigaunt fixes it (a reset relay closes it slowly at speed 5 and locks it).
- **The monitor room (11):** a rebel watches a screen; a button steps through five channels (a counter that wraps);
  he thanks you when it is back on his, reacts when you change it, and after four changes away says he is fed up.
- **The alarm (11, 11a):** two relays, on and off: cage lamps swapped, a siren, rotating red lights, spotlights on the
  doors; the scene that starts it is the same scene that stops it.
- **The launch (12a):** one button (`OnIn`, once) and one relay of 28 timed lines: warning sounds at 0 and 20 s, a
  voice at 5, the silo doors open at 3 with dust, birds fly off at 3, rumble dust at 10, 20 and 25, a shake timer
  from 3 to 36 s, the rocket sound at 27 and the rocket moves at 30 (`SetSpeedReal 50`). The countdown shows on four
  digit panels by animated texture frames (`StartAnimSequence`), from 30 down to 0. Nags before the press: a case of
  nine, killed by the press.

## 5. Advisors (07, 11a, 12a)

- **A pod that pulses (07):** every 8 to 12 s (random) a pulse: a sound, a screen overlay for 0.4 s, a jitter, a
  colour flash for 2 s, and the people near it react in turn (three relays, each once); after three it slows to 14
  to 20 s. When it wakes: steam bursts at 1, 1.6, 2.6, 2.9, 3.3, 3.5 s, the player slowed to 0.1 at 3 s, the attack
  at 7.9 s. Its lights blink faster in three steps (not for us: no flickering lights).
- **The advisors arrive (12a):** the player slowed to 0.1, shakes at 2 and 3 s, the far lights killed one by one at
  1, 3.7 and 5 s, a long pulse with a white fade.

## 6. Doors forced

Blows on a door at 0, 2, 4, 5, 5.5, 5.8, 6, 6.1 s, then it bursts (06); a breaching charge beeps every 2 s, every
0.2 s from 8 s, blows at 9 s (07). Firmer numbers for `valve-breach-buildup`.

## 7. The car and the road (06, 06a, 08, 09, 10, 10a)

- **Alyx covering the player with a rifle (06):** an `npc_sniper` (`shootzombiesinchest 1`) whose laser sweeps a
  group of targets chosen by the zone the player is in (`SweepGroupRandomly`, one trigger per zone); paint every 1 s
  (varied 0.75), quicker (0.25) once she is guiding; killed and respawned from a template as she moves on. Firmer
  for `valve-rooftop-cover`.
- **The radio tower's power (06a):** carry physics plugs to sockets (triggers that feel physics objects, filtered
  by the plug's name, snap it in); two right sockets per route (`logic_branch_listener OnAllTrue`) light a lamp on
  the socket, the tower's lamps, the radio and a hum; pulling a plug turns them off again (OnMixed).
- **The caches on the radar (09):** six beacons (`info_radar_target`, found within 1924 to 4595) on supply crates
  (`item_item_crate` with a beacon sprite): breaking the crate shuts its beacon off with steam for 5 s and sparks for
  3. The caches hold what the stretch ahead needs (rockets and crossbow bolts before the striders; health).
- **A cover-wrecking helicopter (08):** every 20 s it picks one shelter at random (`logic_timer` 20 >
  `case_destruction PickRandomShuffle`) and bombs it apart in one relay (the health shack: physics freed, propane
  burst, decal, fire, an AI danger sound at 0.3 s); three hits on it bring a big bomb; at half health a last one.
  Alyx polls the player's health every 3 s (`logic_playerproxy RequestPlayerHealth` into `logic_compare` 75) and
  below 75 fetches a medkit and throws it when he looks at her (FOV 55).
- **The welder (09, 11):** a spark and its sound every 1.5 to 3 s; a 1 s light with each (skip it: no flickering).
- **The White Forest gate (10a):** the lookout in the gate tower calls down; the gate (a fence on a
  `func_tracktrain`) slides open on his line. Odd-job rebels come from makers of one, each given one of two random
  jobs (`PickRandomShuffle`): crouch, pick up a weapon (`GiveWeapon` at 0.7 s), walk back.

## 8. White Forest's people at work (11, 12a)

A vortigaunt sweeps with a broom (custom walk `Walk_all_HoldBroom`), moving between four spots picked at random
after each sweep (`case_sweepSpots PickRandom` on the scene's completion), a dust puff on while it sweeps; two
welders loop; a gun class (a teacher with an AR2 and three pupils, arms crossed); a consoling couple
(`ai_goal_actbusy`); supervisors with shotguns and SMGs in the halls; a rope puller; a lookout waving from a tower.
**Magnusson's school (11b):** the practice striderbusters are duds (`dud 1`); his scene pauses at each step and
resumes when the step is done (a trigger), a nag after 20 s of dawdling; a missed throw (`OnShatter`) gets one of
three lines and a new device from the pad 1 s later.

## For Living City ([owner] ask first; [map] map pieces; the lesson ids in brackets)

- **The nest** (`NestTube`; the gamemode knows nothing of it yet): [map] a siren and three lamps per mouth
  (wave-warning); [owner] waves by mouths open, 6 s rests, cut short at 8 inside (wave-pattern); a pool refilled
  every 20 to 30 s, not no end (antlion-pool); feeders in the first chamber (busy-until-disturbed); [map] grubs in
  twos and threes (grub-clusters); [owner] the extract for a vortigaunt's healing (extract-heals); the hive boss
  with crawlspaces and a fence only it bumps into (boss-escape-gaps, boss-fence); the swarm leaving at the end
  (swarm-retreats).
- **The forest:** thumpers 1400 to 1700 apart if antlions roam it; hunters in twos and threes (hunters-in-squads).
- **The bunker:** [owner] a slower door, lock bar, three sounds (big-door-slow: Valve 8 to 27 s, ours 4.6 s); [map]
  supply pads (supply-pad); a lift holdout (lift-holdout); a jammed door as a repair job (jammed-door).
- **The Resistance base and district fights:** [owner] a siege in phases (siege-house); a clear win and loss,
  outposts evacuated first (defence-win-loss); cover wrecked by aircraft (cover-wrecked); a medic polling health.
- **Advisors:** [owner] a pulse people flinch at (advisor-pulse).

## Check ideas

- Nest piece: each mouth has a named siren and three named lamps; grubs' nearest-other median 20 to 60, at most a
  quarter alone; a hive boss chamber has a `func_brush` with `excludednpc` and `invert_exclusion 1`.
- Any maker wired by us: `pool_max` set (or the owner chose no end), `maxlivechildren` 1 to 4.
- A supply pad: the trigger feels physics objects (flag 8), the template respawns at 7 s, and only one item sits on it.
- A big door: a lock that moves first, start, loop and end sounds, travel time 8 s or more (if the owner says so).

## What did not work

- Hint type numbers are not on the wiki card: 400 burrow, 12 work spot, 13 and 14 look spots, 101 low cover,
  901 and 902 jump hints, 950 and 951 ally spots are from the engine's list as I know it: check first.
- The guardian's `cavernbreed` and `incavern`, the pools and the hunter makers are EP2 keyvalues: Garry's Mod has
  the EP2 code, but each needs trying on the owner's server before a piece leans on it.
- 01 (the wreck) and 10a's dog and strider are single-player story with little to borrow; 11a's and 06's
  `portalwindow` and `perf_kill` relays switch areaportals and kill whole areas when the player leaves (not for a
  multiplayer server).
