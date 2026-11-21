# The map lessons checked against Valve's wiki (21 November)

Every lesson in `_dev/reference/lessons.json` (279 then) was checked against the saved Valve Developer Community wiki
(`docs/dev/vdc-reference.md`). **No lesson was changed: each item below is for the owner to decide** (CLAUDE.md, the
one rule). Rerun on lessons added later: `python3 _dev/tools/vdc_lessons.py --names --skip-checked` and
`--worksheet DIR --skip-checked` (the lesson ids checked are listed at the end of this file).

**The exact check, all 279 lessons: nothing wrong.** Every input, output and keyvalue a lesson names exists on the wiki
page of an entity it names, or in Garry's Mod's own FGD files (as the wiki keeps them); none is marked as only another
game's; every entity a lesson relies on is in Garry's Mod's FGD.

**The judged check, the 183 lessons that name a wiki entity:** each was read beside the wiki's bugs, warnings and notes
on its entities. One contradiction and 53 catches (things the wiki says that matter for following the lesson in
Garry's Mod, above all on a multiplayer server). Each wiki claim below was checked in the page's own text.

## The one contradiction

- **The node limit** (`valve-npc-node-spacing`): the lesson counts nodes against 4096 "from memory: check"; the wiki's
  Nodegraph page says a nodegraph holds at most **1500**. That is stock Source; Garry's Mod is believed to have raised it,
  but the wiki does not say. Valve's City 17 maps average about 350 nodes each, so a map under 1500 is safe either way.
  Suggestion: keep each map under 1500 until a bigger nodegraph is seen working in Garry's Mod.

## Can crash the server

- **`ai_script_conditions` crashes the game when enabled in multiplayer** (hardcoded to the single player).
  Lessons: `valve-look-and-answer`, `valve-busy-until-disturbed`, `valve-npc-in-view`, `valve-npc-squad-topup`,
  `valve-hunters-in-squads`, `raven-slumped-dead`. They already do the look check in Lua; the catch is never to copy
  Valve's entity into a map. Suggestion: say so in those lessons, and have `map_lint` refuse the class.
- **A `logic_relay` that sends `CancelPending` to itself breaks the I/O queue and crashes**
  (`valve-relay-per-event`, `valve-machines-on-a-beat`). Suggestion: stop a relay from a separate reset relay, as
  Valve's northfront_battle_reset does.
- **An `npc_helicopter` killed while still waiting for its `Activate` input crashes the game** (`valve-cover-wrecked`).
  Suggestion: spawn it active, or unkillable until activated.
- **`trigger_weapon_strip` crashes if a non-player, non-NPC thing that passes its flags enters** (`valve-confiscation-field`;
  a Garry's Mod server is full of thrown props). The lesson does the taking in Lua; if a map ever uses the trigger, its
  flags allow clients and NPCs only.
- **An `assault_rallypoint` named as the next assault point crashes the game** (`valve-npc-assault-lanes`). In a map
  chain every "next" is an `assault_assaultpoint`.
- **A `phys_lengthconstraint` is measured from its own origin and its attach point, and placed wrong crashes the game**
  (`raven-car-drop-trap`). Check both before compiling; try the trap on a local server first.

## Broken or different in multiplayer

- **`npc_template_maker` flag 128 (don't spawn while visible) is broken in multiplayer** (`valve-npc-spawn-job`).
  The lesson already hides spawns by placement and the gamemode; suggestion: say outright never to rely on flag 128.
- **`ai_relationship` does not work on players in multiplayer** (timing), unless spawned by a point_template
  (`valve-npc-flyby`, `valve-aircraft-loops`). Set relationships to players from Lua, per player, joiners included.
- **A non-looping `ambient_generic` without flag 32 plays again for everyone whenever any player's connection drops**
  (`valve-countdown-spoken`, `valve-sound-flags`). Valve's 48 and 49 have it; the proposed sound check should require 32
  on every sound that does not loop.
- **`trigger_once` enabled while several players stand in it fires `OnStartTouch` for each; only `OnTrigger` fires once**
  (`valve-trigger-who`). Wire `OnTrigger` on trigger_once.
- **`trigger_multiple` end-touch can fire before start-touch in the same tick, and fires for things removed inside (a
  player disconnecting) with `!activator` gone** (`valve-trigger-who`). A small delay on end-touch outputs; never send to
  `!activator` from one.
- **Server-side ragdolls (`prop_ragdoll`) make very large network traffic**; starting them asleep, motion off and
  collisions off cuts it (`valve-base-quarters`, `valve-story-props`, `mattress-turned`, `raven-dead-set-pieces`). Also: a
  ragdoll posed in Hammer that starts asleep can stop updating its render box. Suggestion: corpses and mattresses start
  asleep with motion off, kept few; or loose props.
- **Multiplayer maps should use `prop_physics_multiplayer` where they can** (better with collision prediction, bouncier
  when sv_turbophysics is off) (`valve-physics-flags`). Worth a test on loose junk.
- **A raw `.wav` in a door's sound keyvalues plays everywhere in the map** (the wiki: "may be" a problem in multiplayer)
  (`real-doors`). Doors with sound overrides use soundscript names.
- **`point_spotlight` costs 2 edicts each in Garry's Mod (its beam and end); killing it, or its parent, while on leaves the
  end behind** (`raven-clamp-lamps`, `valve-combine-light-beam`, `valve-guard-tower`). Count beams against the edict
  budget players' props share; send `LightOff` before removing a light or the thing it rides.
- **A player manning a `func_tank` who switches to spectator is stuck on it** (tested in HL2DM, not in Garry's Mod)
  (`valve-guard-tower`). Release the gun on a team change.

## Sounds

- **Looping `ambient_generic`s:** a loop not started silent (flag 16) cannot be stopped; `StopSound` works only after
  `PlaySound`; killing a playing loop leaves it playing for the rest of the map (and they stack); the `Volume` input makes
  a loop unstoppable; about 64 sounds at once breaks the sound engine server-wide (`valve-sound-at-the-prop`,
  `valve-wave-warning`, `valve-lookout-siren`, `soundscapes`, `valve-sound-flags`). Suggestion: flag 0 only for loops
  nothing will ever stop; everything else Start Silent and stopped with StopSound, never Kill; check a whole town with
  `snd_show`.
- **Soundscripts ignore an `ambient_generic`'s own sound settings** (spin-up, spin-down) (`valve-lookout-siren`): put the
  wind-up in the sound itself and listen in game.
- **A parented `ambient_generic` does not move its sound (use SourceEntityName); the source must exist when it spawns;
  killed, its source cannot play the sound again even if respawned** (`valve-names-no-loose-ends`, `valve-level-crossing`:
  a train that comes back keeps the same train entity).
- **A door's "Loop Moving Sound" with a move sound that already loops plays forever, a copy more each move**
  (`valve-big-door-slow`). Leave it off with a looping sound.

## Stops working after a while, or after one use (a live server runs for days)

- **A `func_rotating` stops for good after turning 360,000 degrees** (`networked-budget`, `valve-alarm`): about 3.3 hours at
  30 degrees a second, 17 minutes at 350. Suggestion: anything always turning gets a timer sending Stop then Start hourly.
- **A `func_button` locked while pressed never comes back when unlocked** (`valve-lift-holdout`). Lock it after it returns.
- **A `func_tracktrain` sent backwards can jam or go the wrong way unless every `path_track` has a nonzero New Train
  Speed; trains also stop short of a path_track, more so the faster** (`valve-lift-holdout`, `valve-lift-diorama`).
- **A `logic_relay` cannot be triggered again until all its outputs have fired, unless flag 2 (fast retrigger)**
  (`valve-machines-on-a-beat`: a loop that calls itself at its last delay can be ignored).

## How it looks or works

- **`func_tank` in the HL2 games fires no bullets (no damage) without a "bullet" keyvalue** (`valve-guard-tower`: the copied
  d2_prison_01 gun lists none). Have the helper write it; check the gun hurts.
- **`env_fire` shows only four sizes** (35 or less, 36 to 71, 72 to 107, 108 or more; firesize still sets the damage area),
  **and a fire placed exactly at ground level can fall through the world** (`valve-fire-kit`). Pick sizes by band; raise
  floor fires a little or set "don't drop" (16).
- **A named `env_sprite` obeys "Start On" and starts off without it** (`valve-switch-state`). Status lights need flag 1.
- **A camera rendering to a screen makes water in the 3D skybox glitch** (`valve-base-airlock`, `valve-screens-cut-in`).
  Test camera screens on a map with skybox water.
- **Overlays stick only to world brushes (func_detail too) and displacements, never brush entities or models; they keep
  brush face ids, which go stale when brushes change; more than 64 faces near one can fail VBSP** (`valve-decal-or-overlay`,
  `grime`). Write overlays last, onto world or func_detail faces. (The "overlays are not batched" bug is fixed in Garry's Mod.)
- **VBSP adds a `water_lod_control` by itself when a map has water** (`valve-water-depth`): a missing one is not an error.

<!-- checked: props-not-brushes prop-fits-its-job physics-props-dynamic networked-budget real-doors no-fake-doors stairs-16-24 stair-open-side no-gaps nothing-floating no-floating-ropes cap-open-ends water-plane fire-in-drums mattress-turned moving-things-move gates-in-frames lamppost-arm light-model-matches city18-lighting grime soundscapes street-profile facades glass-variety skyline-corners town-shape flush-with-street room-to-move city18-interiors combine-kit keep-what-works speaker-on-wall planting-spots flagpole-markers ep2-models canal-water true-curves fake-windows valid-viewpoints viewer-economy roofs-need-depth room-linings palette no-flush-faces copy-city18 valve-wall-bands valve-column-rhythm valve-light-pools valve-clutter valve-street-proportions valve-template-fronts valve-flat-interiors valve-boarded-openings valve-overhead-cables valve-combine-cold raven-dusk-light raven-streets-and-houses raven-rooftop-refuge raven-traps-and-makers raven-litter-not-gore raven-sound valve-canal-dish valve-canal-ledges valve-canal-outfalls valve-canal-lamps valve-canal-fence-props valve-canal-culverts valve-canal-varies valve-canal-locks valve-wheel-gate valve-portal-door valve-sound-flags valve-timer-asleep valve-counter valve-relay-per-event valve-switch-state valve-swap-broken valve-hazard-cycle valve-trigger-who valve-names-no-loose-ends valve-door-retry valve-alarm valve-fade-clutter valve-turn-the-loose valve-tilt-and-topple valve-physics-flags valve-fade-small valve-shadows-and-solid valve-skin-variety valve-prop-groups valve-stacks valve-busy-and-quiet valve-furniture-on-walls valve-story-props valve-sound-at-the-prop valve-lightmap-by-distance valve-texture-scale valve-wall-foot-seam valve-fixture-lights valve-falloff-by-job valve-light-colour-by-place valve-trim-strips valve-chamfer-8 valve-wall-thickness valve-terrain-into-brush valve-decal-or-overlay valve-sightlines valve-broken-edges valve-water-depth valve-detail-and-nodraw valve-npc-busy-poses valve-npc-posts valve-npc-queue valve-npc-police-post valve-npc-guards-relax valve-npc-in-view valve-npc-spawn-job valve-npc-assault-lanes valve-npc-cover-hints valve-npc-node-spacing valve-npc-gate-links valve-npc-air-nodes valve-npc-heard-not-seen valve-npc-quiet-crowd valve-npc-raid valve-npc-suppression valve-npc-timed-hold valve-npc-battle-lines valve-npc-squad-topup valve-npc-supply-drop valve-npc-flyby valve-npc-dropship valve-tripwire-turrets valve-ambient-gunfire valve-npc-danger-sound valve-weapon-pile-limit valve-teach-then-give-up valve-npc-follow-wait-spots valve-npc-noisy-approach valve-npc-snipers valve-standard-sizes valve-stairwell valve-rebel-barricades valve-combine-barricade-rows valve-wrecked-cars valve-rubble-fitted valve-fire-kit valve-rubble-displacements raven-dead-set-pieces raven-held-till-grabbed raven-trap-kits raven-timber-craft raven-mine-sets raven-graveyard raven-room-kits raven-clamp-lamps raven-stream-follows-front raven-slumped-dead raven-gas-fire-trap raven-car-drop-trap raven-live-fence raven-ally-blast-safety raven-fast-zombie-show raven-climb-heard raven-crows-lead raven-pod-aftermath valve-prison-cell valve-cellblock-tiers valve-prison-fixtures valve-prison-rooms valve-combine-lean valve-combine-aimed valve-combine-light-beam valve-pod-racks valve-interrogation-light valve-prison-cctv valve-combine-door-steps valve-forcefield valve-breach-buildup valve-guard-tower valve-npc-steady-pressure valve-pa-names-the-block valve-prisoner-in-beams valve-machines-on-a-beat valve-lights-bank-by-bank valve-soundscape-combat-levels valve-bait-zones valve-progress-in-the-world valve-turret-pairs valve-base-airlock valve-turrets-follow-by-cells valve-lift-diorama valve-base-at-work valve-look-and-answer valve-raid-on-the-base valve-play-teaches valve-base-concrete-and-salvage valve-base-quarters valve-hospital-ward valve-operating-theatre valve-hospital-corridor valve-power-out valve-car-park valve-collapsed-deck valve-road-tunnel valve-pipe-runs valve-antlion-breach valve-train-shed valve-rebel-hideout valve-combine-wall-chain valve-blast-lean valve-haze-cards valve-dark-spawns valve-burrow-plugs valve-evac-trips valve-gate-waves valve-slot-door valve-supplies-by-need valve-rooftop-cover valve-screens-cut-in valve-combine-recipe valve-combine-plates valve-combine-turns valve-combine-no-mirror valve-combine-scale-jump valve-combine-rhythm valve-combine-meets-old valve-combine-light-panels valve-confiscation-field valve-ball-socket-power valve-countdown-spoken valve-overseer-on-screens valve-wake-chain valve-place-falling-apart valve-work-shown-in-passing valve-blast-grows valve-wave-warning valve-wave-pattern valve-swarm-retreats valve-antlion-pool valve-busy-until-disturbed valve-grub-clusters valve-boss-escape-gaps valve-boss-fence valve-lift-holdout valve-extract-heals valve-hunters-in-squads valve-siege-house valve-supply-pad valve-defence-win-loss valve-big-door-slow valve-jammed-door valve-advisor-pulse valve-cover-wrecked valve-forest-layout valve-tree-footing valve-forest-border valve-forest-floor valve-forest-fences valve-cave-proportions valve-grub-groups valve-cave-light valve-nest-dressing valve-guardian-run valve-white-forest-silo valve-farm-timber valve-decay-bends valve-window-pairs valve-outpost-room valve-dirt-road valve-bunker-into-hill valve-radio-mast valve-village-respawn valve-lookout-siren valve-aircraft-loops valve-lambda-cache valve-squad-guns valve-level-crossing -->
