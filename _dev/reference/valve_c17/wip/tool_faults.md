# Tool faults met while picturing City 17 (one line each, added each round)

- map_view / views: CombineInnerwallCluster1024 props (001a to 003a, about 320 to 720 by 1024 by 1060) draw as solid boxes of their bounds, so in d3_c17_02 they fill overviews and eye views with orange slabs; a picture there had to leave them out (a scratch script dropping them before `views.scene`). Draw them thin, or skip far skyline props.
- asset_facts.json lacks combine_barricade_med02c and combine_gate_citizen, so a Combine checkpoint (d3_c17_02, x -5582) draws as small markers instead of barricades.
- sections (streets): steps beside a road are read as a crown; d3_c17_03 gives "crown 14" at 40 cuts and "road 596" where the square's steps (8 by 12) meet a flat road of 380. Count a crown only between the kerbs.
- sections (streets): the first example can land on a yard, not a street (d3_c17_02, x -7180: W 1030 with steps up), and "wall to wall" can catch a recessed ground floor, so a street cut wants checking with a floor profile.
- views: d3_c17_01 (all indoors, 19 nodes) gives one eye view only.
