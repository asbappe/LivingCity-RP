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
  (`map_prefab.py extract`, with the logic noted in `docs/dev/prefabs.md`). Not done yet.
- **HL2 Citadel walkway reactors (batch 6):** the small power reactors in the middle of the walkways in
  d3_citadel_03 and 04: step in and you float (`trigger_vphysics_motion`, `SetGravityScale` 0; 9 in 03, 10 in 04),
  float to the middle and it kills you (`trigger_physics_trap`, `trigger_hurt`). Lift one whole, brushes, effects,
  sounds and wiring, as a piece. Not done yet.
- **The Citadel pods that carry you (batch 6):** the ride in d3_citadel_01 and 05 and ep1_citadel_00 (the
  prisoner pod with `Inner_pod_arm` and `Inner_pod_rotator` on `func_tracktrain` along `path_track`s, 12 to 22
  tracktrains a map). Lift the pod, its route and its wiring as a piece. Not done yet.
- **Combine architecture, special attention (batch 6, the owner's words):** "pay special attention to the odd,
  unnerving, and unnatural architecture of the combine structures. they never have symmetrical architecture, it
  seems very random/odd and that's something we don't do well and the C18 map doesn't do well and I want to
  reproduce it". A study of its own, by numbers: how far each Combine structure is from mirror symmetry; leaning and
  off-axis faces; overhangs and cantilevers; panel sizes and how they step out from a wall; contrast of huge and small;
  materials and light strips. Across the Citadel maps first, then every Combine structure in the 145 maps (the Nexus
  in d3_c17_10a, 10b, 11; Nova Prospekt's Combine parts; EP2). It ends in rules our map tools can follow to build
  such structures (a generator or module), shown to the owner before it changes anything they settled. Not done yet.
  Numbers gathered on the way: City 17's Nexus (`valve_c17/pictures.json` U26, U27, U32: Combine metal as thin plates,
  2 thick most often, longest side 64; 14% of its faces off right angles against 4% of the old plaster, tilted 45 to 70
  and turned 25, 45 or 65; set inside the old rooms like a second skin and breaking out through the front), and the
  "Combine architecture" section of Nova Prospekt's notes (`valve_prison/notes/`) with its pictures P14 (depot: Combine
  walls leaning against old concrete, 20% of its wall area at about 14 degrees), P16 (the lopsided pod shaft), P17.

- **Approving findings (21 November):** at the end of each batch, put the findings most worth building to the owner
  to pick from; approved ones go on `TODO.md` under "Owner-approved Valve findings", and **nothing is built until
  all ingestion is done** (the owner's choice). City 17's four approved: timed holds with faster waves, squads topped
  up with a medic, supplies from roofs, tripwires and turrets.

## If the work was cut off (21 November, at the usage limit)

Running when the session neared its limit (Nova Prospekt, Black Mesa East and EP1 City 17's props finished since; now running: EP1 City 17's logic and its pictures): EP1 City 17's props and craft
(`valve_ep1c17/wip/`). Whatever they saved is committed. To carry on: read what each saved, finish the missing
maps with a new helper (same brief as before: `docs/dev/map-ingestion.md`, "Briefing a helper"), then merge and
close the batch as batches 1 and 2 were (the `notes/` and draft steps above). Next to start: EP1 City 17's logic
and NPCs, then its pictures; then batch 6 (the Citadel, with the owner's four pieces and the architecture study).

## The batches (M measured, P pictures reviewed, S studied and lessons merged)

All 122 measured on 21 November (145 maps in `valve_stats.json` with the first 23).

| # | Batch | Maps | M | P | S |
|---|---|---|---|---|---|
| 1 | City 17's uprising, and Valve's standards | d3_c17_01, 02, 03, 04, 05, 06a, 06b, 07, 08, 09, 10a, 10b, 11, 12, 12b; testroom_standards, zoo_standards, testroom_measure_movement; styleguide_c17_rubble, styleguide_c17_rubble_2 | yes | yes: 36 pictures U1 to U36 (`valve_c17/`) | yes: 22 new lessons, 22 extended; notes in `valve_c17/notes/` |
| 2 | Ravenholm | d1_town_01, 01a, 02, 02a, 04, 05; styleguide_ravenholm_01, styleguide_mining | yes | yes: 19 pictures R101 to R119 (`valve_ravenholm/`) | yes: 18 new lessons, 18 extended; notes in `valve_ravenholm/notes/` |
| 3 | Nova Prospekt | d2_prison_01 to 08 | yes | yes: 17 pictures P1 to P17 (`valve_prison/`) | yes: 23 new lessons, 16 extended; notes in `valve_prison/notes/` |
| 4 | Black Mesa East | d1_eli_01, 02 | yes | yes: 8 pictures E1 to E8 (`valve_eli/`) | yes: 9 new lessons, 5 extended; notes in `valve_eli/notes/` |
| 5 | EP1 City 17 | ep1_c17_00, 00a, 01, 01a, 02, 02a, 02b, 03, 05, 06; styleguide_hospital_exit, styleguide_garage, styleguide_garage_destroyed, styleguide_garage_antlionroom, styleguide_train_loadingdock, styleguide_train_repair, styleguide_antlion_tunnel, styleguide_antlionhole | yes | running (`valve_ep1c17/`) | props and craft merged (14 new, 5 extended; 213 in all); logic and NPCs running |
| 6 | The Citadel, HL2 and EP1 | d3_citadel_01 (in before; studied again), 02, 03, 04, 05, d3_breen_01; ep1_intro, ep1_citadel_00, 01, 02, 02b, 03, 04; styleguide_core, styleguide_destroyed_citadel | yes | | |
| 7 | EP2 | ep2_outland_01, 01a, 02, 03, 04, 05, 06, 06a, 07, 08, 09, 10, 10a, 11, 11a, 11b, 12, 12a; styleguide_01_antenna, 06_elev_tower, 11a, barn, barn_deterioration, bunkers, caves, farmhouse1, farmhouse2, farmyard, forest_01, inn, logging, radiotower, radiotower_a, radiotower_b, silo, silo_derilict, vista_01, riverbed, riverbed2; outland_building_large_01, medium_01, medium_02 | yes | | |
| 8 | The rest of HL2 | d1_trainstation_06; d2_coast_01, 03, 04, 05, 07, 08, 09, 10, 11 | yes | | |

Left out on purpose: the `_fix`, `_clean`, `_steph`, `_ps3`, `_websacks` and dated (`_0609`...) copies, the
backgrounds, credits, demos, trailers and test rooms.
