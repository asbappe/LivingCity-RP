# Ravenholm's entity logic and NPC scripting (work in progress)

Read 21 November from d1_town_01, 01a, 02, 02a, 04, 05 (t01 to t05 below; d1_town_03 was done before) and the style
rooms styleguide_ravenholm_01 and styleguide_mining. Scripts: `<scratchpad>/work/ravlogic/` (parse.py, lib.py, w.py,
flow.py, makers.py, seqs.py, sounds.py). Outputs are written `Output > target.Input(value) @delay`. Lesson proposals:
`logic_npc_lessons.json` beside this file (10 new, 8 extras).

What each map is: t01 the first streets (Grigori's traps, the pyre, the car trap, the live fence); t01a a short run of
houses and Grigori's attic (the car bomb); t02 the square, the freight lift, the church and its cable car; t02a the
graveyard and Grigori's farewell; t04 the mines (the bladed cart, headcrab shafts); t05 the way out to the coast (Combine
soldiers, snipers, rebels, Alyx on a monitor: not zombie town). styleguide_ravenholm_01 is a cut Combine-against-rebels
town (16 soldiers, gunships, an APC, a falling water tower, a SLAM lesson): its logic adds nothing beyond City 17's
lessons (battle lines, standoffs, nags). styleguide_mining holds 7 cyclers and one light glow: no logic.

## Class counts (logic and NPCs)

| class | t01 | t01a | t02 | t02a | t04 | t05 |
|---|---|---|---|---|---|---|
| npc_template_maker / npc_maker | 27/14 | 10/9 | 20/11 | 11/4 | 11/25 | 8/4 |
| scripted_sequence / aiscripted_schedule | 23/15 | 12/5 | 26/17 | 5/8 | 0/12 | 12/6 |
| logic_choreographed_scene | 7 | 2 | 15 | 13 | . | 12 |
| npc_zombie / fast / poison / torso | 38/0/0/1 | 16/0/0/2 | 7/11/2/1 | 2/5/0/0 | 11/0/0/0 | 2/0/0/0 |
| npc_headcrab / fast / black | 13/0/2 | 0/1/2 | 12/0/0 | . | . | 1/0/1 |
| npc_crow | 19 | . | 10 | 14 | . | . |
| env_fire / firesource / firesensor | 78/11/7 | 28/0/0 | 3/0/0 | 62/0/0 | 3/0/0 | 2/0/0 |
| ambient_generic / env_soundscape | 63/37 | 9/17 | 66/32 | 15/3 | 19/6 | 11/6 |
| env_microphone / npc_enemyfinder | 9/1 | . | 0/5 | . | . | 1/0 |
| info_node_link_controller / info_node_link / info_node_climb | 2/0/0 | . | 3/9/14 | 1/0/0 | . | . |
| info_npc_spawn_destination | . | . | . | 13 | . | . |
| ai_goal_lead / ai_goal_assault / ai_script_conditions | 0/0/2 | . | 1/1/5 | 4/8/0 | . | 0/0/5 |
| item_healthkit | 13 | 14 | 17 | 5 | 13 | 9 |

None in the six: env_headcrabcanister, env_hudhint, game_text, point_message. env_message 2 (Grigori dead: game over).

## 1. How the dead arrive

**One maker, one zombie, on cue.** 154 makers: 142 hold one NPC (`MaxNPCCount` 1), 152 start disabled; fired by `Spawn`
from a trigger_once 101 times, `Enable` from a trigger_once 32. Defaults left alone: `MaxLiveChildren` 5,
`SpawnFrequency` 5, `Radius` 256. Kinds: zombie 60, fast zombie 29, fast headcrab 24, black headcrab 14, Combine 8, crow
7, Grigori 6, poison zombie 3. The job comes at once from `OnSpawnNPC` (median 0.2 s): `StartSchedule` 53,
`BeginSequence` 16, `MoveToPosition` 12, relationships 5. aiscripted_schedule: 'set enemy to the player and run' 36 of
63, 'set enemy' 15, run to a spot or along a path 9, run to the player 2. Template flags: 2048 + 4 (fall to ground) on street zombies, + 512 (fade corpse)
on fast zombies, + 128 (wait for script) when an entrance plays. Staggered starts: makers @0, 0.5, 1; rises @0.5, 1, 1.3.

**Other triggers for a spawn**: a board's `OnHealthChanged` (the zombie behind it, which then smashes through), a door's
`OnOpen` (the attic's crabs), a prop's `OnMotionEnabled` (corridor zombie), a weapon's `OnPlayerPickup` (Grigori's
shotgun: three roof makers @3, 7, 8: the gift is tested at once), a barrel's `OnBreak` (blows a grate, starts a fire,
lets fast headcrabs out of the wall: max 3, flags 192).

**The slumped dead rise** (`raven-slumped-dead`). 17 scripted_sequences in t01 and t01a: `slump_a`/`b` held, then
`slumprise_a`/`a2`/`b` on a trigger 100 to 400 ahead or on the zombie's own `OnDamaged`; `m_fMoveTo` 4; flags 624 or
608. 3 more in t02 rise when looked at (PlayerActorFOV 60 to 65 with sight).

**The house wakes together.** t01: one zombie's `OnFoundPlayer` Enables the others' ai_script_conditions (PlayerTargetFOV
75). npc_enemyfinder (6) carries a `squadname` (FieldOfView -1, MaxSearchDist 500 to 2048): turned on at the lift button,
as Grigori leaves the roof, or for 10 s at a trap, it gives the whole squad the player at once.

**Graveyard: a stream that follows the front and stops when you stop** (`raven-stream-follows-front`). One template
maker (10000, 6 alive, every 1 s, only at unseen points), 13 spawn destinations in four groups; each stage switches the
group, sets 6, 8, 4 alive, and starts a 15 or 20 s cull relay (maker `Disable`) that the next stage cancels.

**Fast zombies: heard, glimpsed, then they come** (`raven-fast-zombie-show`). 13 far calls (radius 2500) in t02; seven
scripted runs end with the runner Killed out of sight; the attack follows (lift show @8, @8.5). Climbing is heard: NPC-only
triggers at the foot and top of 7 ladders clank metal and wobble the pipe 3 degrees (`raven-climb-heard`); climb links
open 5 s into the church ambush.

**When the threat's reason ends, the dead leave.** Stepping into the cable car Kills both makers; a 1 s timer sends each
fast zombie on an 'away' run to a hidden spot where it is Killed (counter of 2). A spawner by a shaft (t04, 20 crabs, 5
alive, flag 128) is Disabled while a player stands next to it and Enabled when he steps off.

**Zombies passing through fire**: a trigger_multiple gives whatever enters it a damage filter 'not from env_fire' and
clears it on leaving (t02), so the dead walk through a burning street to reach you.

## 2. Traps and how they are wired

**Gas and fire** (`raven-gas-fire-trap`; t01, three alike). Valve wheel (func_door_rotating 180, toggle) opens the gas
(hiss loop, heat haze); lit by the igniter (four clicks with sparks), an env_firesensor (radius 39) or an env_microphone
(radius 100, flags 40: shots and blasts); then 40 env_fire over 274 by 234 (pyre) or 32 over 328 by 85 (corridor), 8 to
14 apart, plus env_firesource (45, damage 100) and a hurt; wheel shut puts it out @0.5 to @2. Re-usable.

**The car on the rope** (`raven-car-drop-trap`; t01, two). Car prop on a length constraint from an unseen ballast on a
slide constraint; a lever toggles drop (velocity 10) and stop; pulleys spin; a physics-only trigger filtered to the car
detects the hit; a winch lifts it back (speed 500); rope creaks every 3 to 7 s while it hangs.

**The spinning blade** (t01 three, t04 one). Blade prop on a phys_motor (-1200); toggle lever (flags 1057, wait 5);
spin-up, loop, spin-down, a sputter every 3 to 8 s; the first is running when the player first sees it (logic_auto
Press); one relay turns all off once the player has moved on.

**The bladed mine cart** (t04). A func_physbox cart pushed by a phys_thruster (force 1000) along the rails, a
func_rotating blade (1500) with a trigger_hurt 250 parented to it; a lever starts it; four trigger_onces 640 to 770 apart
spawn 2 to 4 zombies each that run at the player, through the blade's path; at each end a physics trigger filtered to the
cart flips its thruster.

**The live fence** (`raven-live-fence`; t01). Pulsed shock (10, cap 20; off 0.3 s after each hurt), a push of 500, one
of four zaps, three sparks; the power switch kills it and enables the ladder on. No electrified water in these maps.

**The car bomb** (t01a). Four zombies walk to a car (scripted walk, radius 1500); a barrel under it breaks: explosion,
fire, shake, hurt; the clip that held the player back goes on the blast or @10 anyway.

**Collapses** (t04). A catwalk's `OnMotionEnabled`: physics blast, shake (8, 3 s, radius 500), a dust sphere, metal sounds
@0 and @1.5; boards fall on constraints broken as the player passes; `IgnoreFallDamage(5)` before a drop (!player: single
player only).

## 3. Grigori (npc_monk)

- From template makers, one per scene, `Kill`ed at the scene's end and spawned afresh further on.
- Leads with ai_goal_lead (`LeadDistance` 128, `Retrieve` 1, `RetrieveDistance` 160, `Run` 1); each fight stage swaps
  the lead for an assault (Deactivate, Activate @0.1, BeginAssault @0.2).
- Sets off the propane only from his post and never with a player beside it (`raven-ally-blast-safety`); the fire holds
  the way 47 s.
- Kept alive: `SetHealth(100)` at stages and every 1 s in the last scene; his death is a game over (single player).
- Nags: a 20 s timer, three nags @0, 7, 13, all killed on arrival (`valve-teach-then-give-up`); a random laugh of three
  when a crypt zombie dies; a vigil line every 10 s on the roof.
- Shows a kill from afar: he shoots a bullseye, an env_shooter drops a dead headcrab model @2.3 with its death sound.
- His fights are heard first: zombie @1, shotgun @1.5, 2.4, 4.2, 5, laugh @3 (`valve-npc-heard-not-seen`).
- Relationships: Grigori hates every zombie class (rank 0, both ways); a fast zombie on its scripted run likes him until
  its scripted run is over.

## 4. Machines that time a fight

- Freight lift (t02): a func_tracktrain (start speed 12) between two path_tracks 385 apart (about 32 s); the button Locks
  itself, spawns fast zombies @0 and @1, TurnOns the shaft's node link and the squad's enemyfinder, and fast zombies break
  in through windows @5; at the top the door opens and a bell rings.
- Cable car to the church (t02): lever (func_door_rotating with a button), wheels spinning while it moves, 784 at speed
  40; Grigori holds the cave zombies about a minute (two makers of 6, one alive, one of two routes by PickRandom); the
  car's own trigger ends the attack.
- Graveyard gate (t02a): a momentary wheel turns the gate (func_movelinear 60) and seven pulleys follow it; motor
  spin-up, loop and spin-down sounds; Grigori's nags until it turns.

## 5. Sound and fear

101 env_soundscape (WoodBuilding 23, Street 22, Start 15, Rooftop 14, ConcreteBuilding 11, CorpseRoom 5, caves 6), radius
128 always. 183 ambient_generic, 142 one-shot (48), radius median 1250; fired by trigger_once 45, relays 36,
trigger_multiple 23, scripted_sequence 13, buttons and doors 16, fire sensors 6. Placed scares: far fast-zombie calls
(13, radius 2500), poison zombie calls (9, radius 1250 to 3000) @0, 0.7, 1.2, 2 from 300 to 1400 away, a door pounded, a
wake, wood creaks (11) as boards are touched or a floor is crossed, flies over six corpses (trigger 13 to 45 away), metal
clanks on ladders when something climbs (14). Music: d1_town.Music_Intro on entering, Music_Goodbye_Grigori at the end.

## 6. How players are guided

No text at all. Grigori's voice from ahead (three rants 387 to 936 ahead of their triggers, each stopping the last);
crows lifting and flying ahead into the town (`raven-crows-lead`); a spotlight lit as a door opens (the pyre door); the
first trap already running; a trap's wheel opened by script as you near it; sounds from where to go; Grigori leading and
waiting (`Retrieve`). Clips that hold you back go when the scene ends, or after 10 s anyway.

## 7. For our infestation quarter (`docs/features/infestation-cleanup.md`)

[game] gamemode, [map] map pieces, [owner] changes a feature: ask first, [new] new.
1. Zombies near a cleanup crew capped (6 to 8), spawned from the cluster ahead, quiet when the crew stalls, walked off at
   the end [game][owner]. Clusters of zspawn points [map][new].
2. Some zombies spawned slumped, woken by a player, a look or a hit [game][owner].
3. A gas trap and a car trap in the sealed quarter (lc_ravenholm.vmf) [map][new]; burning a growth in the gas counts
   for a job [game][new].
4. A live fence or flooded floor with a hidden power box as a job step for the flush or the door (not a timer) [game][new].
5. The Cremator and soldiers never start fire with a player inside its radius [game][owner].
6. A district's spread shown by a far call and a fast zombie running over a roof, no notice [game][owner].
7. Crows lifting into an infested district as a player comes [game][owner].
8. Climb triggers that clank on the quarter's pipes [map][new].
9. Spent canisters left stuck in the quarter; shelling's wreckage kept longer there [map][new] / [game][owner].
10. The flush gate's slow opening, its motor sound, as the hold's clock (`valve-npc-timed-hold`) [game][owner].

## Check ideas

- map_lint 'wire': env_fire in a trap start off and are Enabled and Disabled by name; a maker with `MaxNPCCount` over 100
  is sent `Disable` by something (Valve's endless maker has two cull relays); an env_microphone has `MaxRange`.
- A test: zombies alive near a cleanup crew never pass the cap; a slumped zombie wakes on damage and on a player near.
- A test: no ally fire or grenade starts with a player inside its radius.
- Robots: a cleanup job where the crew stands still 20 s sees no new zombies (if the owner takes the stream rule).

## What did not work

- No electrified water, no live headcrab canisters and no mine elevator in these maps: the shock is a fence, the
  canisters are props, the mine's moving part is the bladed cart (the lift is t02's freight lift).
- The .vcd scenes are not in the sources: what Grigori says is known only from file names (aimforhead, exit_hurry,
  bucket_guardwell...).
- Flag meanings (maker 4 and 2048, template 128 and 1024, microphone 40) are the FGD's as remembered, firmed by City 17's
  outpost microphone; sequence names come from the maps, not from model files.
- t05 and the style room are Combine and rebel maps; only their zombie-against-Combine tunnel (a zombie's `OnDamaged`
  spawns soldiers and drops its health to 5 or 10 so the staged fight goes one way) touches the infestation.
