# The coast: d1_trainstation_06 and d2_coast_01 to 11 (work in progress, 21 November)

One pass over the rest of Half-Life 2's way out (d2_coast_12 was done before: `valve_d2_coast_12`). These maps
matter less to a city RP, so only what the 255 lessons and the EP2 batch (`valve_ep2/wip`) do not already hold is
kept here. Numbers from `valve_NAME/measure.json`, the drafts' number sentences, and entity dumps read with
`python3 -I` (the scripts stayed in the scratch folder). Proposals: `wip/lessons.json` (6 new, 4 extras).
Pictures: `valve_coast/pictures.json` (draft, K1 to K13).

## The maps in one line each

| Map | What it is |
|---|---|
| d1_trainstation_06 | the train yard chase (8 metrocops, 2 scanners), Barney's crowbar on a roof, the canal's start as a tunnel |
| d2_coast_01 | the Resistance dock post; a crane lifts the buggy ashore; sand that wakes antlions |
| d2_coast_03 | New Little Odessa: a Resistance village, its gunship fight, the RPG, four thumpers |
| d2_coast_04 | a Combine-held dock and warehouses (18 soldiers, four squads), a second crane |
| d2_coast_05 | the cliff road, a gas station and a ruined house held by soldiers, rollermines, an APC that blows up |
| d2_coast_07, 08 | the great bridge: the village at its end, the catwalks under it, the force field and the control house |
| d2_coast_09 | shacks and yards on the shore, zombies in the houses, rollermines dropped by a dropship |
| d2_coast_10 | the lighthouse and its farm, held by the Resistance against four dropships and a gunship |
| d2_coast_11 | the sand crossing on rocks and boards, the vortigaunts' camp, the bugbait (antlions turn friendly) |

## 1. Props and craft

- **The road.** Gravel blends on displacements (blendgrassgravel001a/b; dirt and sand track overlays in d2_coast_01:
  sandtrack02a 27, dirttrack01a/b 9, gravelpath 7), roadway 384 wide in d2_coast_05; no kerbs, no crown, no
  lights (d2_coast_05 has no light entity at all, sun 400). Poles (utilitypole01b) 1022 to 1788 apart, cables
  spanning a median 1052 to 1764 with slack 100 to 105: twice the city's span with the same sag
  (`valve-overhead-cables` extra). Signs (signpole001) about 1950 apart. EP2's `valve-dirt-road` (wip) covers the rest.
- **The bridge** (d2_coast_07, 08): a truss (metaltruss020a on 2029 faces) about 1150 wide and over 9000 long, top
  at 2016, carrying the road deck (concretefloor037a) at 1856 over the sea at 0; catwalks (metalfloor003a) at 1240
  to 1792 under it; metalrail003a rails. Force field strips 32 apart (func_brush, never solid) with one solid clip,
  as `valve-forcefield`. Not a piece we would build: notes only.
- **Shacks and houses.** Windows are props: a frame (prop_static) and its `_bars` twin (prop_dynamic) on one spot
  (plasterwall029c 10/10, 21/21; plasterwall029g 16/16, 18/19; woodwall030b 9/9), as EP2's `valve-window-pairs`
  (wip). The coast adds the glass: a func_breakable pane in the opening OnBreak > the bars SetBodyGroup 1, 115 such
  windows in d2_coast_03, 05, 07, 09, 10 (plasterwall029g 42, 029c 36, woodwall030b_window01a 26, 02a 11).
  **Extra for `valve-window-pairs` once EP2's lessons are merged** (not in `wip/lessons.json`, because merging an
  extra for an id that does not exist yet fails). Rooms 120 high (most nodes indoors), roofs tileroof004b at 20 to
  35 degrees, walls plasterwall029b/c/d and woodwall006a/009a.
- **New Little Odessa's house** (K3): a radio room (four receivers, two on a cart, a radio, an antenna, a control
  desk, five storage closets), a mess (cafeteria tables and benches), bunks (prison bed frames and mattresses 5),
  a generator trailer, six floodlamps on stands (light_spotlight02_lamp: light_spot 186 205 214 at 150, cone 45,
  straight down), eleven explosive drums. The lighthouse's house and the dock post have the radio and the canal map
  too (`valve-rebel-hideout` extra). The rest is as `valve-base-quarters` and EP2's `valve-outpost-room`.
- **The lighthouse** (K10): its stair is one model (lighthouse_stairs, 128 high) stacked ten times from z 836 to
  1988, each turned 180 from the last, the fresnel lamp at 2108; handrail04 pieces (36) round the gallery. A way to
  build any tall round tower from one stair piece.
- **The shore.** Driftwood lies at the waterline (d2_coast_01: median 9 over the water, -39 to 73; d2_coast_03: 44,
  -13 to 120), in clumps (driftwood_clump_02a 12); dock pilings (dock01_pole01a_128) 80 to 90 apart, pole clusters
  224 apart; rock cluster props (rockcliff_cluster01b to 03c) over cliff displacements and cliffface001a brushes,
  about half of them tilted (14 of 26, 12 of 23, 12 of 21; none in d2_coast_04). Displacements 179 to 597 a map.
  Few lights: the coast is lit by the sun (pitch -15 to -45, brightness 300 to 700) and fog (from 500 to 2048).
- **The canal's start** (d1_trainstation_06, K1): a closed concrete tunnel about 256 wide under a roof 352 up,
  ledges 116 wide at 224 up, before d1_canals_01 opens out. The yard: trains (train003 14), track markers, switches,
  signals, column lamps 367 apart, cable poles 501 apart.

## 2. Logic and NPCs

- **The village keeps its people** (`valve-village-respawn`): three rebels in New Little Odessa (the regular, the
  ammo man with RPG rounds, the medic) come back 10 s after dying from makers under the house, never while seen,
  corpses fading; the lighthouse's every 15 s until the gunship comes. Valve's wiki: the don't-spawn-while-visible
  flag is broken in multiplayer, so our version needs its own sight check.
- **The lookout and the siren** (`valve-lookout-siren`): a lookout sits in a tower about 300 over the village; the
  attack starts with his hand siren (radius 1250, winds up 10 s); the gunship hates him first (rank 999999); when he
  dies the siren squeals off and the tower's props fall.
- **The gunship** (`valve-aircraft-loops`): three loops over the village, a random one every 7 to 12 s; it turns on
  the player at the first hit; on the bridge, nine zones (gaps 450 to 1920) keep it beside the player, each waking
  only its neighbours; its death plays music, stops the siren, starts the post-fight scenes and saves. The rebels
  hand out rockets (citizentype 3, ammosupply RPG_Round) and RPG rounds lie about (11 in d2_coast_03).
- **The lighthouse fight** (`valve-npc-dropship` extra): four dropships, a crate shot down before landing sends the
  ship away and is counted, the rebels call for rockets 5 to 10 s after each ship appears (three shout counters to 6).
- **The Combine at the coast** (`valve-squad-guns`): 100 soldiers, all combine_soldier skin 0, guns 56 SMG, 25 AR2,
  19 shotgun, squads named for what they hold. A thumper post (d2_coast_03): three soldiers hold a thumper against
  antlions made at its edge (jumping disabled); one death sends the rest into the boathouse (as the existing
  fall-back rule). A Combine spy post watches the road from a hill: a soldier on an actbusy hint at a fixed binocular prop
  (combine_binocular01), two more men.
- **Sand and antlions** (`valve-antlion-pool` extra): a surface trigger (sand, material 78) switches the maker on
  under the player's feet; two settings, on foot and in the car; repellent points keep roads and docks clear;
  thumpers reach 1000 here (512 in EP2). After the bugbait (d2_coast_11), env_global antlion_allied and
  ai_relationships turn antlions neutral to players, rebels and vortigaunts.
- **The buggy.** func_vehicleclip keeps it on the road; losing it in the sea ends the game (env_message
  GAMEOVER_OBJECT in seven maps); a flipped car brings a nag 5 s after the antlions are dead; the hint for the
  turbo is one env_hudhint. A crane (prop_vehicle_crane, npc_cranedriver, phys_magnet) lifts it in d2_coast_01; a second
  crane stands at the Combine dock in d2_coast_04. Ours: no vehicles, notes only.
- **Guidance along a long road.** The road itself, poles and wires along it, one lambda a map marking a cache
  (`valve-lambda-cache`), soundscapes changing every few hundred units (9 to 35 a map, radius 104 to 384), people who
  say where to go (the gatekeeper's three "get your car" lines at most every 10 s; the barn greeter's nag every 10 to
  15 s; the vortigaunt's three bugbait nags every 15 s, as `valve-teach-then-give-up`). On-screen text is rare: one
  env_hudhint for the turbo, two for the bugbait, one game_text at the lighthouse ("Stash your car in the barn").
  d1_trainstation_06 still holds two placeholder game_text lines ("metrocop instructs citizens to exit train",
  "turrets killed you"): Valve's own leftovers.
- **The train yard** (`valve-level-crossing`): the crossing's two red lamps toggle every 0.5 s and the bell rings for
  25 s while four trains roll at 0.7 speed; the train carries its sounds and a hurt brush (20).

## 3. Pictures (`valve_coast/pictures.json`, draft, K1 to K13)

One sheet looked at per map (800 by 260); K1 is a cut-away drawn by hand and looked at once, small. K3 and K4 (New
Little Odessa), K10 and K11 (the lighthouse), K12 and K13 (the camp and the sand) are the two-picture places. The
eye views on open ground are mostly grass and sky; the cut-aways (K2, K3, K12) and the block view (K10) teach more.

## 4. Check ideas

- A Resistance base with no lookout spot or siren could be flagged once the owner wants one.
- The window pair check (EP2's) can also require the pane brush to be wired to the bars' bodygroup.
- A spawned Combine squad's guns can be counted against 56/25/19.

## 5. What did not work

- The views for d1_trainstation_06 never reach the canal's start (the map's best-scored eyes are on the platform);
  the cut-away of the tunnel is 83% background because a brush far below widens the frame (the known fault).
- `views` calls an eye under an overhanging cliff "indoors" (d2_coast_11 07_in shows open cliffs).
- Water height by counting up-facing water faces is wrong where the 3D sky's sea has more faces than the real one
  (d2_coast_04, 09, 11): weigh faces by area or skip the sky room.
- The d2_coast_08 eye views by the bridge's concrete rooms showed only grass and trees: the overview (K8) was used.
