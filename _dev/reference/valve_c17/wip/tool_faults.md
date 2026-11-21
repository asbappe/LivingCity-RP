# Tool faults met while picturing City 17 (one line each, added each round)

- map_view / views: CombineInnerwallCluster1024 props (001a to 003a, about 320 to 720 by 1024 by 1060) draw as solid boxes of their bounds, so in d3_c17_02 they fill overviews and eye views with orange slabs; a picture there had to leave them out (a scratch script dropping them before `views.scene`). Draw them thin, or skip far skyline props.
- asset_facts.json lacks combine_barricade_med02c and combine_gate_citizen, so a Combine checkpoint (d3_c17_02, x -5582) draws as small markers instead of barricades.
- sections (streets): steps beside a road are read as a crown; d3_c17_03 gives "crown 14" at 40 cuts and "road 596" where the square's steps (8 by 12) meet a flat road of 380. Count a crown only between the kerbs.
- sections (streets): the first example can land on a yard, not a street (d3_c17_02, x -7180: W 1030 with steps up), and "wall to wall" can catch a recessed ground floor, so a street cut wants checking with a floor profile.
- views: d3_c17_01 (all indoors, 19 nodes) gives one eye view only.
- map_view / views (round 2): CombineInnerwall001a (306 by 296 by 998; the advancing Combine wall, 18 in d3_c17_06b) also draws as solid boxes, filling the overviews and eye views of d3_c17_06b with tall slabs; U15 and U18 leave them out.
- map_view / views: project_building02 (a far backdrop block, 3760 by 1518 by 1389) draws as one huge box in the d3_c17_06a overviews; backdrop and skyline models want leaving out or drawing as fronts.
- views: the auto cut-away of d3_c17_06a (near 2766 4262, cut at -127) shows only flat slabs: the cut height lands at a tunnel's roof; cut-aways underground want the floor under the knot plus about 150.
- measure: d3_c17_06b's boards over windows are physics props (wood_board04a to 07a, three to a window), not the plank brushes valve-boarded-openings counts, so the plank count misses them.
- map_view / views (round 3): in d3_c17_10b the CombineInnerwall001a and 001c props and combine_bridge (320 by 212 by 429) fill the Nexus overviews and cut-aways as orange slabs; U26, U27 leave them out. Outside (U32) the plates were kept, as they are what marks the Nexus as Combine, but they draw as plain boxes.
- views: in d3_c17_10b two of six chosen eye views (08_in, 09_in) are 70 to 81% dark, and in d3_c17_12b one (06_out) is one flat colour over 99% of the frame: outdoor and spread rules pick them before the score does; reject dark over 0.6 or modal over 0.8 first.
- views: the style rooms have no visible info_node (styleguide_c17_rubble none; styleguide_c17_rubble_2's 295 are Hammer-hidden), so they get no eye views; round 3 fed views.eyes points on floors beside each prop from a scratch script.
- map_view: collapsedbuilding01a, 01awall, 02c and project_destroyedbuildings01 draw as solid boxes of their bounds, so every eye view of styleguide_c17_rubble is orange slabs; only its cut-away block was usable.
- asset_facts.json lacks combine_gate_vehicle and fountain_01 too (d3_c17_07, 10a, 12): the vehicle gates between tall barricades draw as small markers.
- views: d3_c17_10a, 11 and 12 share one frame (the park before the Nexus, the Nexus itself at about x -444 to 1700, y 4500 to 7900), so their drafts repeat the same park; d3_c17_10b's frame is 10a's moved by (2048, -6784) at the landmark.
