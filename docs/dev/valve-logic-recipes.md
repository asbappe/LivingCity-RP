# Valve's entity logic, as recipes (measured from 23 of Valve's map sources, 21 November; reference for module helpers)

# Valve's wiring, second pass: recipes, counts, checks

Read from 23 VMFs (d1_trainstation_01 to 05, d1_town_03, d2_coast_12, d3_c17_13, d3_citadel_01, sdk_vehicles, d1_canals_01, 01a, 02, 03, 05 to 13): 34,753 entities, 7,711 output lines. Every connections line uses commas (`"OnX" "target,Input,value,delay,times"`); no other separator was found. Hidden entities (inside `hidden { }`) are counted. Output lines are written below as `Output > target.Input(value) @delay xtimes`.

## Class counts (story maps one by one, the 13 canal maps summed)

| class | town3 | ts01 | ts02 | ts03 | ts04 | ts05 | coast12 | c17_13 | cit01 | canals (13) | total | maps |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| trigger_once | 16 | 30 | 19 | 24 | 16 | 11 | 37 | 40 | 12 | 298 | 503 | 22 |
| trigger_multiple | 9 | 29 | 29 | 17 | 8 | 11 | 21 | 14 | 20 | 147 | 305 | 22 |
| trigger_hurt | . | 1 | . | . | 1 | . | 1 | . | 6 | 64 | 73 | 15 |
| trigger_push | . | . | . | 1 | . | 1 | 1 | . | . | 20 | 23 | 11 |
| logic_relay | 2 | 48 | 14 | 35 | 11 | 71 | 10 | 16 | 6 | 201 | 414 | 22 |
| logic_auto | 2 | 5 | 3 | 6 | 2 | 2 | 13 | 3 | 4 | 43 | 83 | 22 |
| logic_timer | 2 | 3 | 4 | 4 | . | 1 | 15 | 6 | . | 15 | 50 | 15 |
| logic_case | . | 3 | 2 | . | . | . | . | 1 | . | 5 | 11 | 6 |
| logic_branch | . | 1 | 1 | . | . | . | . | . | . | 2 | 4 | 4 |
| logic_compare | . | . | . | . | . | 2 | . | . | . | 2 | 4 | 2 |
| logic_choreographed_scene | 1 | 44 | 17 | 28 | 6 | 30 | . | 13 | . | 74 | 213 | 16 |
| math_counter | 2 | 7 | 2 | . | 2 | 4 | 2 | 8 | 2 | 26 | 55 | 16 |
| filter_activator_name | 1 | 4 | 2 | 6 | . | 3 | . | 6 | . | 38 | 60 | 14 |
| filter_activator_class | . | 2 | 2 | 3 | . | . | 2 | 2 | . | 21 | 32 | 14 |
| ambient_generic | 27 | 21 | 15 | 16 | 9 | 73 | 18 | 45 | 18 | 177 | 419 | 21 |
| env_soundscape | 7 | 10 | 12 | 2 | 10 | 6 | 26 | 5 | 9 | 175 | 262 | 22 |
| env_sprite | 5 | 17 | 21 | 5 | 6 | 40 | 27 | . | . | 164 | 285 | 19 |
| env_spark | 2 | . | . | 10 | . | 13 | . | 2 | 2 | 16 | 45 | 11 |
| env_fire | 1 | . | . | . | . | . | 1 | 19 | . | 96 | 117 | 8 |
| env_explosion | . | . | . | . | . | 1 | . | 35 | . | 10 | 46 | 4 |
| env_physexplosion | 3 | 2 | 10 | 5 | 6 | 8 | . | 3 | . | 45 | 82 | 16 |
| env_shake | 1 | 4 | . | . | 2 | 1 | . | 9 | 8 | 7 | 32 | 10 |
| env_steam | . | 1 | . | . | . | 12 | . | . | . | 12 | 25 | 3 |
| env_smokestack | 5 | . | . | . | . | . | . | 4 | . | . | 9 | 2 |
| env_fade | . | . | 1 | 1 | 1 | 2 | . | 6 | 2 | 1 | 14 | 7 |
| env_hudhint | . | 1 | 1 | . | . | 1 | . | . | . | 11 | 14 | 7 |
| point_template | 3 | 18 | 9 | 6 | 14 | 3 | 15 | 5 | 6 | 97 | 176 | 22 |
| point_spotlight | 11 | 19 | 10 | 7 | 1 | 2 | 27 | 10 | 17 | 68 | 172 | 18 |
| npc_maker | 10 | 1 | . | . | . | 13 | 2 | . | . | 2 | 28 | 5 |
| npc_template_maker | 7 | . | 8 | 2 | . | 10 | 11 | 54 | . | 105 | 197 | 15 |
| scripted_sequence | 7 | 18 | 16 | 15 | 4 | 29 | 2 | 19 | . | 113 | 223 | 18 |
| aiscripted_schedule | 14 | 4 | 1 | 2 | 4 | 3 | 3 | 12 | . | 66 | 109 | 16 |
| ai_relationship | 3 | 6 | 3 | 8 | 5 | 3 | 23 | 8 | 1 | 79 | 139 | 20 |
| func_button | . | 3 | 2 | . | . | 8 | . | . | . | 2 | 15 | 5 |
| momentary_rot_button | . | . | . | . | . | . | . | . | . | 8 | 8 | 4 |
| func_rot_button | 1 | . | . | . | . | . | . | . | . | . | 1 | 1 |
| func_door | . | 7 | 10 | 8 | 6 | 16 | 4 | . | . | 9 | 60 | 12 |
| func_door_rotating | 6 | 9 | . | . | . | 13 | 1 | . | 14 | 12 | 55 | 11 |
| prop_door_rotating | . | 9 | 6 | 8 | 6 | 3 | . | . | . | 19 | 51 | 12 |
| func_movelinear | . | . | . | . | . | . | . | . | . | 8 | 8 | 4 |
| func_rotating | 10 | 1 | . | . | . | 14 | . | . | . | 5 | 30 | 7 |
| func_tracktrain | 1 | 7 | . | . | 2 | 2 | 8 | . | 22 | 8 | 50 | 10 |
| func_brush | 14 | 23 | 24 | 19 | 5 | 8 | 1 | 17 | 5 | 77 | 193 | 21 |
| func_breakable | 2 | 1 | 1 | 36 | 1 | 1 | . | 21 | . | 286 | 349 | 18 |
| func_physbox | . | 1 | . | 4 | 4 | 2 | 3 | 2 | 2 | 265 | 283 | 19 |
| func_areaportal | . | 3 | 10 | 14 | 10 | 2 | . | 12 | 1 | 121 | 173 | 18 |
| func_areaportalwindow | 2 | . | . | 24 | . | . | 5 | 3 | . | 10 | 44 | 7 |
| func_occluder | . | 3 | . | . | 5 | . | 15 | 12 | 1 | 61 | 97 | 15 |
| func_lod | 1 | . | . | . | . | . | . | 1 | . | 15 | 17 | 7 |
| info_target | . | 48 | 14 | 26 | 25 | 125 | 21 | 18 | 1 | 207 | 485 | 21 |
| info_player_start | 4 | 4 | 2 | 2 | 2 | 2 | 1 | 1 | 5 | 95 | 119 | 23 |
| env_cubemap | 109 | 76 | 174 | 89 | 173 | 52 | 128 | 22 | 28 | 811 | 1662 | 22 |
| light_environment | 4 | 6 | 5 | 2 | 3 | 7 | 1 | 3 | 3 | 79 | 114 | 23 |
| shadow_control | . | 1 | 1 | 1 | 1 | 1 | 1 | 1 | . | 15 | 22 | 20 |
| env_fog_controller | . | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 14 | 24 | 21 |
| env_tonemap_controller | . | . | . | . | . | . | . | . | . | 13 | 13 | 13 |
| sky_camera | . | 1 | 1 | 1 | 1 | 1 | . | 1 | 1 | 13 | 20 | 20 |

Common to most maps (18 or more of 23): trigger_once, trigger_multiple, trigger_changelevel, logic_relay, logic_auto, info_target, ambient_generic, env_soundscape, point_template, func_areaportal, func_brush, ai_relationship, scripted_sequence, light_environment, shadow_control, env_fog_controller, sky_camera, env_cubemap. Rare: func_button 15 (5 maps), momentary_rot_button 8 (4), func_movelinear 8 (4), logic_branch 4, logic_compare 4, func_rot_button 1. None: trigger_soundscape, env_soundscape_triggerable, point_message, func_viscluster, env_instructor_hint.

## Recipes to turn into helpers

**R1 Wheel moves a gate** (d1_canals_05 gate3_wheel, d1_canals_10 gate4_wheel)
- momentary_rot_button, brush tools/toolsinvisible, `spawnflags` 1024 use + 128 or 64 axis (none: z) + 1 not solid (2048 starts locked, 8192 jiggles when locked), `distance` 210 to 800 (negative: other way), `speed` 18 to 180, `returnspeed` 30 to 240, `sounds` 24, `startdirection` Forward.
- Model: prop_dynamic `parentname` = the wheel (valvewheel002, valvewheel002a, door_wheel001a, wheel01a).
- `Position > gate.SetPosition`; gate is func_movelinear (`movedir` -90 0 0 up, `movedistance` 148 to 320, `speed` 100 to 120, `startsound` d1_canals.citizen_gate.Move1, `stopsound` d1_canals.citizen_gate.FullClose1, `startposition` 0).
- `OnFullyClosed > lock_sound.PlaySound x1`, `OnFullyClosed > !self.Lock x1` (sound d1_canals.citizen_gate.WheelLock1, flags 48).
- Followers: a second momentary_rot_button with `spawnflags` 65 (no use) driven by the same `Position > follower.SetPosition`.
- Script opens it: relay `gate.Open`, `wheel.Unlock @0`, `wheel.SetPosition(1) @0.1` (d1_canals_11 relay_guncave_gateopen); close relay `SetPosition(0)`, `Lock @2`.

**R2 Lever that runs a machine** (d1_canals_13 gate_control_lever)
- func_door as the lever: `spawnflags` 268 (4 + 8 + 256 use opens), `movedir` 45 0 0, `speed` 20, `lip` 4, `wait` -1; handle model props_wasteland/panel_leverHandle001a parented to it. Ravenholm's tram lever is a func_rot_button instead (`spawnflags` 3137, `distance` 15, `speed` 100, `sounds` 23, model tram_lever01 parented).
- `OnOpen > !self.Lock @0.1 x1`, `click.PlaySound x1` (Buttons.snd21, 48), `alarm.PlaySound @0.5 x1`, `alarm.StopSound @3.5 x1` (apc_alarm_loop1, 16), `sluice.Open @2 x1` (func_movelinear).

**R3 Toggle switch with status light** (d2_coast_12 thumper_1_button, alarm_button)
- func_door 20x10x12 `spawnflags` 288 or 289 (use opens + toggle), `wait` 3, `noise2` Buttons.snd9; prop_dynamic props_combine/CombineButton.mdl; env_sprite sprites/glow01.spr (`rendermode` 5, `scale` 0.1, red or green); optional env_lightglow.
- `OnOpen`: `model.SetAnimation(togglein)`, `sprite.Color(0 255 0) @0.2`, `sprite.SetScale(0.05) @0.2`, `SetScale(0.1) @0.3`, `machine.Enable @0.2`, `!self.Lock @0`, `!self.Unlock @1`. `OnClose`: the same with toggleout, 255 0 0, Disable.

**R4 Button that opens a door; button that works from one side**
- Valve's buttons (15 func_button) are mostly unseen brushes (toolsclip, toolsinvisible or nodraw) over a model, `spawnflags` 1025 (use + do not move), `sounds` 0, `wait` 1 to 3; keypads add `sounds` 2, `locked_sound` 2 and flip the keypad's skin (`prop_keypad_1.Skin(2)`, `Skin(0) @1.9`). Ours (wall_button, 1025) matches.
- One side only (d1_town_03 street_lever): button starts locked (2048); trigger_multiple on the near side `OnStartTouch > button.Unlock`, `OnEndTouch > button.Lock`. On our server use OnStartTouchAll / OnEndTouchAll.

**R5 Door the map closes** (d1_trainstation_01 barney_door_2, introom_door_1)
- `door.Close @0`, `door.Lock @0.1`; on the door `OnBlockedClosing > !self.Close @1`, `OnFullyClosed > !self.Lock`. prop_door_rotating `spawnflags` 8192 normal (23 of 51), 2048 starts locked, 32768 ignores players' use; `hardware` 1, `distance` 90, `speed` 100, `returndelay` -1.

**R6 Areaportal with its door**
- prop_door_rotating or func_door: portal `target` = door name, `StartOpen` 0 if the door starts shut (11 portals).
- func_door_rotating / func_movelinear gates: `OnOpen > portal.Open`, `OnFullyClosed > portal.Close` (d1_canals_08 door_locke1_1 via relay_locks_closegateportal). Valve's other 62 portal lines come from triggers: single player only.

**R7 Alarm** (d1_canals_07 logic_start_redlight, d2_coast_12 bunker_1_alarm_relay, d1_canals_08 relay_locks_opengates)
- Beacon: func_rotating 16 cube nodraw, `spawnflags` 64, `maxspeed` 350, `fanfriction` 20; two point_spotlight parented to it, `angles` 0 0 -180 and 0 180 -180, `rendercolor` 255 0 0, `spotlightlength` 96, `spotlightwidth` 25, `spawnflags` 2, `HDRColorScale` 0.6; inside props_c17/light_cagelight01_on.
- Start relay: `spot.LightOn`, `rot.Start`, `bell.PlaySound @2`, `bell.StopSound @14`, `stop_relay.Trigger @120`. Stop relay: `LightOff`, `rot.Stop`. Sirens coast.bunker_siren1/2 (16, radius 10000) or a one-shot klaxon d1_canals.Floodgate_Klaxon (48) fired `@0, @1, @2, @3`.
- Makers: npc_template_maker `StartDisabled` 1, `MaxNPCCount` 1, `MaxLiveChildren` 1 to 5, `SpawnFrequency` 5, `Radius` 256, `CriterionVisibility` 2, `CriterionDistance` 2; fired by `Spawn` from triggers and relays (100 lines) or `Enable`; `OnSpawnNPC > schedule.StartSchedule` (aiscripted_schedule, goal an info_target, never !player).

**R8 Counters** (see lesson valve-counter)
- Wave: `npc.OnDeath > counter.Add(1)`; counter `max` N; `OnHitMax > next.Enable`, `OnHitMax > !self.SetValue(0)` to repeat (d1_canals_01 traintrackcops_south_assault_counter).
- Barricade: boards `OnBreak > counter.Add(1)`; `OnHitMax > gate_intact.Kill`, `gate_broken.Enable` (d1_canals_01a sewerbarrels_counter, max 4).
- Occupancy (d1_trainstation_01 train_door_2): two trigger_multiple, each `Add` or `Subtract`, Disables itself and Enables the other; `OnHitMax > door.Close`.

**R9 Dispenser that runs out** (d1_trainstation_01 soda_machine_1, a ration machine for us)
- func_button (1025, `wait` 1): `OnPressed > branch.Test`, `OnPressed > counter.Add(1) @0.1`.
- logic_branch: `OnFalse > dispense.Trigger`, `OnTrue > empty.Trigger`.
- dispense relay: `sound.PlaySound` (Trainyard.sodamachine_dispense, 48), `can_template.ForceSpawn @0.5`, `sprite.HideSprite`, `ShowSprite @0.2`, `total.Add(1)`; total counter max 6 `OnHitMax > branch.SetValue(1)`.
- empty relay: empty sound, `sprite.color(255 23 23)`, `can_template.Kill x1`.
- Jam: counter max 3 `OnHitMax > logic_case.PickRandom`, `!self.Subtract(1)`; case01 `branch.SetValue(1)`, case02/03 `button.Unlock`.
- logic_compare for 'has this happened yet' (d1_trainstation_05 lab03a_compare_1: button `SetValue(1)`, scene end `Compare`, `OnEqualTo` / `OnNotEqualTo`).

**R10 Timers** (lesson valve-timer-asleep, valve-hazard-cycle)
- logic_timer `StartDisabled` 1, `UseRandomTime` 1, `LowerRandomBound` 1 to 4, `UpperRandomBound` 3 to 8; presence trigger_multiple `OnStartTouchAll > timer.Enable`, `OnEndTouchAll > timer.Disable`.
- Steam hazard: timer 3 to 5 > relay: `steam.TurnOn`, `hurt.Enable`, `push.Enable`, one-shot sound; all off `@1.7`. env_steam `speed` 180, `startsize` 25, `endsize` 40, `rate` 40, `jetlength` 80; trigger_hurt `damage` 20, `damagetype` 8; trigger_push `speed` 40.
- (d3_c17_13 transition_flickerlight_timer flashes a named light with a spark: our house rule forbids flickering lights.)

**R11 Triggers**
- One-time: trigger_once `spawnflags` 1, `OnTrigger` (1152 lines) or `OnStartTouch` (256), 59 start disabled. Its inputs: Kill 153, Enable 131, Trigger 108, ForceSpawn 88, PlaySound 82, Spawn 72.
- Repeatable: trigger_multiple `wait` 1 (199 of 305) or 0 (46), outputs OnStartTouch 268, OnTrigger 156, OnEndTouch 153.
- To whoever came: `OnPass > !activator.FireUser1`; each train's own `OnUser1` runs its doors (d3_citadel_01 zapperpod1_train: rotator Open @0, vehicle Open @1, Close @4, rotator Close @5).

**R12 Breaking things** (lesson valve-swap-broken)
- env_explosion `iMagnitude` 100, `iRadiusOverride` 0, `fireballsprite` sprites/zerogxplode.spr, `rendermode` 5, flag 1 no damage (19 of 46).
- env_shake `amplitude` 12, `radius` 1000, `duration` 1, `frequency` 2.5 (commonest; 20 fired from path_track OnPass, 12 from relays).
- env_physexplosion `spawnflags` 1, `magnitude` 50, `radius` 0 (or 128 to 200 with a named target).
- env_spark `magnitude` 1 to 2, `traillength` 1 to 3, `spawnflags` 128 or 640; driven StartSpark / SparkOnce / StopSpark.
- env_fire: burning from the start `spawnflags` 15 or 47 (4 start on, 8 full), `health` 30 to 300, `firesize` 48 to 130.
- func_breakable boards: `material` 1 wood (243 of 349), `health` 1 to 10, `spawnflags` 256; func_physbox freed by relays (`EnableMotion` 154 lines, `Break` 62, `Wake` 24).

**R13 Map start**: logic_auto `spawnflags` 1 (removed after firing, 64 of 83), OnMapSpawn (212 lines): parenting (`SetParent`, `SetParentAttachment`), `ForceSpawn`, starting animations. Canals: logic_auto (flags 0) sets tonemap_controller `SetAutoExposureMin(.5)`, `SetAutoExposureMax(4)`, `SetBloomScale(.4)`, `SetTonemapRate(.35)` (26 times).

## What Valve settles among our "Unchecked" notes

- func_rot_button: axis by spawnflag 64 (x) or 128 (y), use 1024, not solid 1 (lc_stash_valve was one until 24 November: now a wheel prop on a momentary_rot_button, map_wiring.wheel).
- func_rotating: `maxspeed` (100 wheels, 350 beacon, 2750 fans), `fanfriction` 20, axis 4 (x) or 8 (y), 64 not solid, 2 reverse, 16 speeds up and down; inputs Start, Stop, StartForward, StopAtStartPos, Toggle.
- prop_thumper: `model` props_combine/CombineThumper001a.mdl, `dustscale` 256, inputs Enable and Disable (d2_coast_12 thumper_1). No OnThumped in these maps (stays unchecked).
- func_tracktrain: `startspeed` 500 to 800, `speed` 0, `orientationtype` 1, `height` 4, `wheels` 50, `bank` 0, `volume` 10, `spawnflags` 11 or 3, `movesound` / `stopsound` scripts; inputs SetSpeed, Stop, StartForward, Resume; path_track `OnPass` (Stop, SetSpeed, StartShake, PlaySound), the last one stops the train (d1_town_03 streettram_path_08). Train sounds are scripts (razortrain_wheels 16, razortrain_horn 49), not .wav.
- func_door starting open: spawnflag 1 in Valve's files (289); no func_door uses `spawnpos`.
- env_smokestack: `BaseSpread` 10 to 20, `SpreadSpeed` 15, `Speed` 30, `StartSize` 20, `EndSize` 30, `Rate` 20, `JetLength` 180, `InitialState` 1. env_dustpuff: `color` 128 128 128, `scale` 16, `speed` 20 to 32, input SpawnDust.

## Optimisation and sight

- func_areaportal 173 in 18 maps (0 to 38 a map), the two long sides about 128 and 320 at the median; func_areaportalwindow 44 in 7 maps, `FadeStartDist` / `FadeDist` 200/350 in rooms, 750/1250 to 1600/1800 outdoors, `target` a func_brush window (`..._fading_part`).
- func_occluder 97 in 15 maps, all active from the start but 1 (a few toggled by triggers); func_lod 17, `DisappearDist` 1000 to 3500; func_viscluster none (too new).
- Hint faces 89 in 13 maps (0 to 16): map-wide horizontal sheets (d1_canals_09, 13) and walls at corridor turns. Skip 140.
- Fades: 2363 of 6970 prop_static, 711 of 2237 prop_physics (lesson valve-fade-clutter).
- env_cubemap 1662 (22 to 174 a map), nearest neighbour 128 / 214 / 391 (quartiles), about 65 above the floor at the median (ours at 72: fine).
- light_environment `pitch` -35 in most, its yaw copied to shadow_control (`angles` 80 165 0 with the sun's 165; `color` 128 128 128, `distance` 75); VRAD uses one, Valve leaves copies of the same values about the map.
- env_fog_controller: canals `fogstart` 512, `fogend` 10000 to 18000, `farz` 16000 where set; sky_camera `scale` 16 in all 20, its own fog to 20000 to 85000; 3D skyboxes hold 1 to 47 prop_static (row_res_*, project_building0N_skybox, buildingskybox_002a, Combine_Citadel001b, tree_deciduous_card_01_skybox) and a few smokestacks.

## Player guidance

14 env_hudhint (Valve_Hint_* only, first use of a thing), 1 game_text, 1 env_message, 0 point_message in 23 maps. Guidance is a lit door, a sound where to go, a door that opens ahead, a sprite that changes colour. info_player_start: 119, several a map (23 with flag 1, master).

## Robustness

- Targets per output event: 1 for 1893, 2 for 594, 3 to 9 for 794, 10 or more for 78. Relays: median 3 outputs.
- Special names: !activator 93, !player 11 (+52 schedule goals), !self 4; wildcards 30 lines (monitor_*, mic_*, npc_helicopter_*). 482 shared names. 593 lines fire once (x1), mostly on trigger_once and relays.
- Dangling: 98 lines name nothing in their map (leftovers of cut scenes).
- Parenting: 479 children, depth 1: 437, 2: 41, 3: 1. Parents: func_tracktrain 118, prop_physics 68, func_door_rotating 53.
- Filters: 75 of 808 triggers; damagefilter mostly on func_physbox (81, filter_activator_class 'no cops'); filter_multi 4.
- Naming: either kind first (relay_, logic_, trigger_, sound_, template_) or place first with the kind last (soda_machine_1_counter, gallerycop_maker2); open/shut pairs as start_/stop_.

## Single player tricks not to copy

Portals and occluders switched by triggers as the player passes; doors locked behind the player; !player; env_global, point_viewcontrol, player_speedmod, env_fade on everyone; OnNewGame and OnMapTransition (GMod has one map: OnMapSpawn, which fires again after a cleanup).

## Checks our tools could make (proposed map_lint "wire")

1. An output target that is not a targetname in the chain, not a classname and not on the gamemode's list (Valve: 98 such lines).
2. A wildcard target that matches nothing; a target or parentname or filtername that names the wrong kind.
3. A named relay, timer, counter or sound nothing fires and the gamemode does not list (Valve: 31 named sounds never played).
4. A trigger with `spawnflags` 0; any `!player`; an OnEndTouch undoing an OnStartTouch on a trigger many can stand in.
5. A sound sent PlaySound without flag 16 (it also plays at spawn); a one-shot without 32.
6. A logic_timer with neither `RefireTime` > 0 nor random bounds; a timer starting enabled that is not the gamemode's.
7. A math_counter with fewer Add lines than its `max`.
8. A func_button without 256, 512 or 1024 (nobody can press it); a momentary_rot_button with no axis flag or `distance` 0.
9. A moving brush or door players use with no sound of its own and no PlaySound in its wiring.
10. An areaportal whose box meets a door's with no `target` and no door wiring; any trigger sending a portal Open or Close.
11. Parenting deeper than 2; a child whose parent does not move.
12. A relay with more than about 40 outputs or a delay over 120 seconds (Valve's most).

## What did not work

Old VMFs store only three points per face, so brush sizes are approximate. Heights above the floor take the highest brush top under the point. The 3D skybox room is found from the nearest toolsskybox brushes round the sky_camera (d1_trainstation_05 not closed). How GMod plays an ambient_generic one-shot without flag 32, and !player as player 1 in multiplayer, come from memory of Source, not from these files.

## What our tools do with this (21 November, later)

`map_lint.py` kind `wire` makes checks 1, 4, 5, 9 and 10 above: outputs to things not in the map, `!player`, triggers
with `spawnflags` 0, one-shot sounds without 32 (and loops with it), every moving part (door, gate, lift, train,
turning thing) with no sound of its own and none in the wire that moves it, an areaportal naming a door not in the
map, a door hanging in a portal that nothing closes, and any trigger opening or shutting a portal. `m.sound` and the
pieces' own sound helpers set the flags; valves are wheels (`map_wiring.wheel`). In every built piece the check finds
only the aqueduct's bars and water, which rise in silence (`docs/dev/map-modules.md`, "Wiring the way Valve does").
