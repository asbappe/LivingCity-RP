# Valve map ingestion: progress (the whole set, from 21 November)

The owner, 21 November, sent every HL2, EP1 and EP2 map source in one zip and chose: **the 81 game maps not yet in,
plus Valve's 41 style guide and standards rooms** (not the dated drafts or the test, demo and trailer maps);
**every map measured first, then pictures, studies and lessons one batch at a time, in the order below**, saving
(commit and push) **every 5 or so maps**, because usage limits will interrupt the work. How to ingest:
`docs/dev/map-ingestion.md`. This page is only what is done and what is next. Update it with every save.

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

- **EP1 Citadel (batch 6):** copy and save for future use the **massive Combine doors built of 20 to 40 brushes**,
  and the **Citadel core reactor** with its effect, animation, damage, sounds and wiring, as pieces
  (`map_prefab.py extract`, with the logic noted in `docs/dev/prefabs.md`). Not done yet.
- **HL2 Citadel walkway reactors (do with batch 6):** the small power reactors in the middle of the walkways in
  d3_citadel_03 and 04: step in and you float (`trigger_vphysics_motion`, `SetGravityScale` 0; 9 in 03, 10 in 04),
  float to the middle and it kills you (`trigger_physics_trap`, `trigger_hurt`). Lift one whole, brushes, effects,
  sounds and wiring, as a piece. Not done yet.

## The batches (M measured, P pictures reviewed, S studied and lessons merged)

All 122 measured on 21 November (145 maps in `valve_stats.json` with the first 23).

| # | Batch | Maps | M | P | S |
|---|---|---|---|---|---|
| 1 | City 17's uprising, and Valve's standards | d3_c17_01, 02, 03, 04, 05, 06a, 06b, 07, 08, 09, 10a, 10b, 11, 12, 12b; testroom_standards, zoo_standards, testroom_measure_movement; styleguide_c17_rubble, styleguide_c17_rubble_2 | yes | | |
| 2 | Ravenholm | d1_town_01, 01a, 02, 02a, 04, 05; styleguide_ravenholm_01, styleguide_mining | yes | | |
| 3 | Nova Prospekt | d2_prison_01 to 08 | yes | | |
| 4 | Black Mesa East | d1_eli_01, 02 | yes | | |
| 5 | EP1 City 17 | ep1_c17_00, 00a, 01, 01a, 02, 02a, 02b, 03, 05, 06; styleguide_hospital_exit, styleguide_garage, styleguide_garage_destroyed, styleguide_garage_antlionroom, styleguide_train_loadingdock, styleguide_train_repair, styleguide_antlion_tunnel, styleguide_antlionhole | yes | | |
| 6 | EP1 Citadel | ep1_intro, ep1_citadel_00, 01, 02, 02b, 03, 04; styleguide_core, styleguide_destroyed_citadel | yes | | |
| 7 | EP2 | ep2_outland_01, 01a, 02, 03, 04, 05, 06, 06a, 07, 08, 09, 10, 10a, 11, 11a, 11b, 12, 12a; styleguide_01_antenna, 06_elev_tower, 11a, barn, barn_deterioration, bunkers, caves, farmhouse1, farmhouse2, farmyard, forest_01, inn, logging, radiotower, radiotower_a, radiotower_b, silo, silo_derilict, vista_01, riverbed, riverbed2; outland_building_large_01, medium_01, medium_02 | yes | | |
| 8 | The rest of HL2 | d1_trainstation_06; d2_coast_01, 03, 04, 05, 07, 08, 09, 10, 11; d3_citadel_02 to 05; d3_breen_01 | yes | | |

Left out on purpose: the `_fix`, `_clean`, `_steph`, `_ps3`, `_websacks` and dated (`_0609`...) copies, the
backgrounds, credits, demos, trailers and test rooms.
