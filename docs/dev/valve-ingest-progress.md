# Valve map ingestion: progress (the whole set, from 21 November)

The owner, 21 November, sent every HL2, EP1 and EP2 map source in one zip and chose: **the 81 game maps not yet in,
plus Valve's 41 style guide and standards rooms** (not the dated drafts or the test, demo and trailer maps);
**every map measured first, then pictures, studies and lessons one batch at a time, in the order below**, saving
(commit and push) **every 5 or so maps**, because usage limits will interrupt the work. How to ingest:
`docs/dev/map-ingestion.md`. This page is only what is done and what is next. Update it with every save.

## Where each batch's work goes

Pictures and `pictures.json` in the batch's shared set (`_dev/reference/valve_c17/`, `valve_ravenholm/`, `valve_prison/`...);
helpers' running notes and lesson proposals in its `wip/` while it runs; at the batch's end the proposals are merged
(`merge-lessons`) and deleted, the notes kept in `notes/`, the set's `"draft"` taken out, and the batch pushed to `main`.

## Getting the maps again (a new chat or a wiped scratch folder)

- The zip is `HL2Leak-VMFs-master.zip` (194 MB, 1.7 GB unpacked) on the owner's Google Drive: the link is in the chat
  of 21 November, or ask the owner. It downloads with curl from
  `https://drive.usercontent.google.com/download?id=FILE_ID&export=download&confirm=t`.
- Inside: `HL2-MapPack/NAME.vmf`; `HL2EP1-MapPack/maps/NAME.vmf` (the standards rooms in `maps/dev/`,
  `styleguide_ravenholm_01` in `maps/personal/gautam/`); `HL2EP2-MapPack/maps/NAME.vmf` (the three outland buildings
  in `maps/instances/`). Same source as the first 23 maps (d1_canals_05 matches brush for brush).
- Extract only the maps of the batch at hand, into `<scratchpad>/valve/hl2`, `ep1`, `ep2`, `style`
  (`unzip -j ZIP 'HL2Leak-VMFs-master/PATH.vmf' -d DIR`). All are editorversion 400, no `vertices_plus`.
- Valve's own damage in some files: the digit 1 saved as `&i` (EP1 Citadel maps, d3_breen_01, d3_citadel_05,
  styleguide_destroyed_citadel) and a stray `)` in a light value (d1_town_02a). The readers now cope (21 November).
- Measuring again is safe (it rewrites `measure.json`): `python3 -I _dev/tools/map_ingest.py all NAME F.vmf
  --no-pictures`.

## The owner's requests on the way

- **EP1 Citadel doors and core (batch 6):** copy and save for future use the **massive Combine doors built of 20 to 40 brushes**,
  and the **Citadel core reactor** with its effect, animation, damage, sounds and wiring, as pieces
  (`map_prefab.py extract`, with the logic noted in `docs/dev/prefabs.md`). **Done 21 November:** `valve_citadel_door_big`
  (ten slats rising one after another), `valve_citadel_door_shutters` (six shutters parting), `valve_citadel_core` and
  `valve_citadel_core_effects` (one anchor; 83 wired effects, kill zones and sounds).
- **HL2 Citadel walkway reactors (batch 6):** the small power reactors in the middle of the walkways in
  d3_citadel_03 and 04: step in and you float (`trigger_vphysics_motion`, `SetGravityScale` 0; 9 in 03, 10 in 04),
  float to the middle and it kills you (`trigger_physics_trap`, `trigger_hurt`). Lift one whole, brushes, effects,
  sounds and wiring, as a piece. **Done 21 November:** `valve_citadel_walkway_reactor` (d3_citadel_03). It floats a
  player by taking away the gravity of the player's physics copy (no push, no gravity setting); it should work in
  Garry's Mod (same code) but is untested: a Lua zone is the fallback.
- **The Citadel pods that carry you (batch 6):** the ride in d3_citadel_01 and 05 and ep1_citadel_00 (the
  prisoner pod with `Inner_pod_arm` and `Inner_pod_rotator` on `func_tracktrain` along `path_track`s, 12 to 22
  tracktrains a map). Lift the pod, its route and its wiring as a piece. **Done 21 November:** `valve_citadel_pod`
  (pod, arm, rotator, train, seat trigger, halt-and-go logic, a route of 13 path points).
- **Combine architecture, special attention (batch 6, the owner's words):** "pay special attention to the odd,
  unnerving, and unnatural architecture of the combine structures. they never have symmetrical architecture, it
  seems very random/odd and that's something we don't do well and the C18 map doesn't do well and I want to
  reproduce it". A study of its own, by numbers: how far each Combine structure is from mirror symmetry; leaning and
  off-axis faces; overhangs and cantilevers; panel sizes and how they step out from a wall; contrast of huge and small;
  materials and light strips. Across the Citadel maps first, then every Combine structure in the 145 maps (the Nexus
  in d3_c17_10a, 10b, 11; Nova Prospekt's Combine parts; EP2). It ends in rules our map tools can follow to build
  such structures (a generator or module), shown to the owner before it changes anything they settled. Not done yet.
  Numbers gathered on the way: City 17's Nexus (the study itself: `valve_citadel/notes/architecture_notes.md` and lessons `valve-combine-*`; earlier, `valve_c17/pictures.json` U26, U27, U32: Combine metal as thin plates,
  2 thick most often, longest side 64; 14% of its faces off right angles against 4% of the old plaster, tilted 45 to 70
  and turned 25, 45 or 65; set inside the old rooms like a second skin and breaking out through the front), and the
  "Combine architecture" sections of Nova Prospekt's and EP1 City 17's notes (`valve_prison/notes/`, `valve_ep1c17/notes/`; EP1 pictures C2, C6, C8, C14) with its pictures P14 (depot: Combine
  walls leaning against old concrete, 20% of its wall area at about 14 degrees), P16 (the lopsided pod shaft), P17.

- **Black Mesa East pieces (the owner, 21 November: "all of them please lift for use in the future with the modules"):**
  lift from d1_eli_01 and 02 as pieces (`map_prefab.py extract`, each with its wiring noted in `docs/dev/prefabs.md`):
  the airlock (two blast doors about 270 apart, the guard's booth with its camera screen), the turrets that only
  look alive (prop turrets and their six floor zones), the lift ride (the cage, the shaft, the three floors seen on
  the way and their timed people), and the base at work (the work spots: cooks at the stove, vortigaunts at the
  machine, the walking loop). Lessons `valve-base-airlock`, `valve-turrets-follow-by-cells`, `valve-lift-diorama`,
  `valve-base-at-work`. The owner keeps `valve-look-and-answer`, `valve-raid-on-the-base` and `valve-play-teaches`
  as references (not to build for now). **Done 21 November:** seven pieces `valve_eli_airlock`,
  `valve_eli_lookalive_turrets`, `valve_eli_lift_ride` (the shaft alone), `valve_eli_lift_floor`,
  `valve_eli_work_spots_kitchen`, `_repairs`, `_walker`, with their wiring and what to change for multiplayer in
  `docs/dev/prefabs.md`, "Pieces with their wiring" (read it by grep: 37 KB).
- **Approving findings (21 November):** at the end of each batch, put the findings most worth building to the owner
  to pick from; approved ones go on `TODO.md` under "Owner-approved Valve findings", and **nothing is built until
  all ingestion is done** (the owner's choice). City 17's four approved: timed holds with faster waves, squads topped
  up with a medic, supplies from roofs, tripwires and turrets.

## If the work was cut off (21 November, at the usage limit)

Batches 3 to 6 finished since (21 November). Now running: the Combine generator (`map_combine.py`, the owner's "build it next"), batch 7's props and craft and its logic and NPCs. Earlier note: EP1 City 17's props and craft
(`valve_ep1c17/wip/`). Whatever they saved is committed. To carry on: read what each saved, finish the missing
maps with a new helper (same brief as before: `docs/dev/map-ingestion.md`, "Briefing a helper"), then merge and
close the batch as batches 1 and 2 were (the `notes/` and draft steps above). Next to start: EP1 City 17's logic
and NPCs, then its pictures; then batch 6 (the Citadel, with the owner's four pieces and the architecture study).

- **More Citadel pieces, as possible modules (the owner, 21 November):** lift (1) the light bridge, without the
  whirring wind vortex that pulls players off, and the vortex as a separate piece; (2) the energy balls powering
  things (a ball held in a socket keeps a shield wall up; pull it and the wall drops; with a dispenser and a catcher
  if they belong to it); (3) the weapon check room (`valve-confiscation-field`: held, Overwatch at 2 s, cores at 7,
  weapons stripped at 11 and burned at 13, the exit opens). The owner's idea: the weapon check room could take
  prisoners' weapons. The other Citadel concepts (spoken countdown, the Advisor on screens, defenders woken in a
  chain, a place falling apart) stay as lessons for later. **Done 21 November:** `valve_citadel_light_bridge` (its deck
  never solid: a clip holds you up; the tool drops clips, so the entry gives its box), `valve_citadel_wind_vortex`
  (pulses 6 s in every 9.3 s; vphysics triggers, a negative physics explosion and a ragdoll magnet, no push),
  `valve_citadel_ball_socket`, `valve_citadel_ball_dispenser`, `valve_citadel_weapon_check` (it ends only when a
  gravity gun charges in it: a timed end must be added).

- **EP2, special attention (the owner, 21 November):** the forest layouts (tree spacing and clusters, clearings,
  paths), how the forests are bordered (what stops the player at the edges and how it is hidden), prop layout and
  design in the woods; the mines and the antlion nests and tunnels, for our own cave and forest; the White Forest
  base for our own bunker map (`map_forest.py`, `lc_forest_bunker.vmf`). **Lift the core missile silo** (its brushes
  and rooms, minus the missile) as a piece, to be added to our existing bunker. The EP2 props helper was told
  (its notes get a section for each). **Silo lifted 21 November:** `valve_ep2_silo` (one piece, no rocket); what
  joining it to the bunker takes, and the question of where it goes, are on TODO.md.

- **The Combine generator (the owner, 21 November: "build it next"):** right after batch 6 closes, build
  `_dev/tools/map_combine.py` as planned in TODO.md and `_dev/reference/valve_citadel/` (`notes/architecture_notes.md`, `arch_scripts/`),
  show the owner one structure on a test map, then carry on with batch 7 (EP2). **Built 21 November:**
  `map_combine.py` (wall, gate, tower, skin; `test` and `check`), test map `_dev/tools/lc_combine_test.vmf` and its
  picture; waiting on the owner's look; what it lacks is on TODO.md.

- **Silo joined to the bunker (the owner, 21 November: "connect the silo to the bunker so that the silo sits just
  outside the existing map area (then seal it off obviously)"):** in progress (`BunkerForest`, `lc_forest_bunker.vmf`).
  With it (the owner, same day): "update/revamp the bunker to match the EP2 whiteforest bunker aesthetic and designs
  ... the bunker/silo doors for whiteforest from EP2 and such too": White Forest's materials, lights and dressing on
  the bunker's rooms (layout kept), its big door lifted (`valve_ep2_bunker_door`) for the main entrance. In progress.
- **The teleporter's power-up (the owner, 21 November):** the "below the floor" Combine laser and lightning effect
  that powers up the teleporter in Entanglement, lifted as `valve_prison_teleport_charge` (**done 21 November**:
  d2_prison_08, a slot 128 wide down the teleport room's floor under an invisible lid; six dials, seven glows, six
  beams lighting in six steps about 26 s apart; `docs/dev/prefabs.md`, "Pieces with their wiring (Nova Prospekt)").

## The batches (M measured, P pictures reviewed, S studied and lessons merged)

All 122 measured on 21 November (145 maps in `valve_stats.json` with the first 23).

| # | Batch | Maps | M | P | S |
|---|---|---|---|---|---|
| 1 | City 17's uprising, and Valve's standards | d3_c17_01, 02, 03, 04, 05, 06a, 06b, 07, 08, 09, 10a, 10b, 11, 12, 12b; testroom_standards, zoo_standards, testroom_measure_movement; styleguide_c17_rubble, styleguide_c17_rubble_2 | yes | yes: 36 pictures U1 to U36 (`valve_c17/`) | yes: 22 new lessons, 22 extended; notes in `valve_c17/notes/` |
| 2 | Ravenholm | d1_town_01, 01a, 02, 02a, 04, 05; styleguide_ravenholm_01, styleguide_mining | yes | yes: 19 pictures R101 to R119 (`valve_ravenholm/`) | yes: 18 new lessons, 18 extended; notes in `valve_ravenholm/notes/` |
| 3 | Nova Prospekt | d2_prison_01 to 08 | yes | yes: 17 pictures P1 to P17 (`valve_prison/`) | yes: 23 new lessons, 16 extended; notes in `valve_prison/notes/` |
| 4 | Black Mesa East | d1_eli_01, 02 | yes | yes: 8 pictures E1 to E8 (`valve_eli/`) | yes: 9 new lessons, 5 extended; notes in `valve_eli/notes/` |
| 5 | EP1 City 17 | ep1_c17_00, 00a, 01, 01a, 02, 02a, 02b, 03, 05, 06; styleguide_hospital_exit, styleguide_garage, styleguide_garage_destroyed, styleguide_garage_antlionroom, styleguide_train_loadingdock, styleguide_train_repair, styleguide_antlion_tunnel, styleguide_antlionhole | yes | yes: 19 pictures C1 to C19 (`valve_ep1c17/`) | yes: 22 new lessons, 15 extended; notes in `valve_ep1c17/notes/` |
| 6 | The Citadel, HL2 and EP1 | d3_citadel_01 (in before; studied again), 02, 03, 04, 05, d3_breen_01; ep1_intro, ep1_citadel_00, 01, 02, 02b, 03, 04; styleguide_core, styleguide_destroyed_citadel | yes | yes: 25 pictures Z1 to Z25 and arch_01 (`valve_citadel/`) | yes: 16 new lessons, 9 extended; the owner's six pieces; notes and `arch_scripts/` in `valve_citadel/` |
| 7 | EP2 | ep2_outland_01, 01a, 02, 03, 04, 05, 06, 06a, 07, 08, 09, 10, 10a, 11, 11a, 11b, 12, 12a; styleguide_01_antenna, 06_elev_tower, 11a, barn, barn_deterioration, bunkers, caves, farmhouse1, farmhouse2, farmyard, forest_01, inn, logging, radiotower, radiotower_a, radiotower_b, silo, silo_derilict, vista_01, riverbed, riverbed2; outland_building_large_01, medium_01, medium_02 | yes | yes: 40 pictures W1 to W40 (`valve_ep2/`) | yes: 36 new lessons, 16 extended; notes in `valve_ep2/notes/`; the silo being lifted |
| 8 | The rest of HL2 | d1_trainstation_06; d2_coast_01, 03, 04, 05, 07, 08, 09, 10, 11 | yes | yes: 13 pictures K1 to K13 (`valve_coast/`) | yes: 6 new lessons, 4 extended; notes in `valve_coast/notes/` |

Left out on purpose: the `_fix`, `_clean`, `_steph`, `_ps3`, `_websacks` and dated (`_0609`...) copies, the
backgrounds, credits, demos, trailers and test rooms.
