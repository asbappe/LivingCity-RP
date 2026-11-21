# The Combine's own architecture: what makes it look unnatural (21 November, work in progress)

The owner (batch 6): "pay special attention to the odd, unnerving, and unnatural architecture of the combine
structures. they never have symmetrical architecture ... I want to reproduce it". Measured from the VMFs (read as
text) of d3_citadel_01 to 05, d3_breen_01, ep1_intro, ep1_citadel_00 to 04, styleguide_core,
styleguide_destroyed_citadel; the old buildings of d3_c17_10a, 10b, ep1_c17_00, 01 for comparison. Scripts in the
chat's scratch folder (`arch/arch_lib.py`, `analyse.py`, `walls.py`, `rhythm.py`, `cantilever.py`, `pooled.py`).
Builds on valve-combine-lean, valve-combine-wall-chain, valve-combine-aimed, valve-combine-cold, combine-kit.
Nothing here changes a piece already built: the checkpoint, depot and armoury stand upright and square; ask the
owner first before changing them.

**The short answer.** The Combine is not random. It works on a 256 bay with 128 courses like anyone, and its giant
pillars and formal rooms (Breen's office, the reactor core) are centred. What makes it unnerving is what it lays
over that: thin plates (2 to 16 thick) in 3 to 6 layers, a fifth of its surface leaning or turned off the grid by
simple ratios, a small part set straight against one 8 to 32 times its size, and the relief of every wall and the
two sides of every passage built differently.

## The recipe (a Combine wall, gate, tower or hall side from scratch)

1. **Bay and mass.** Lay out on a 256 bay in 128 courses. One to three masses (slabs 64 or 128 thick, 512 to 1216
   long). A mass may be centred or even mirrored; what is laid on it may not.
2. **Plates.** Pick 2 or 3 thicknesses from 2, 4, 8, 16 (8 commonest in HL2, 2 in EP1); plates 32 to 64 by 64 to
   256 (128 commonest), giant ones 1024. Butt them (gap 0 on 60 to 81% of joins); one join in five gets a reveal of
   8, 12, 40 or 48.
3. **Layers.** By wall area: 1 layer on 36 to 61%, 2 on 10 to 29%, 3 to 6 on 17 to 67% (median 37%). The first step
   off the mass is 48, 56 or 64; each layer on top steps 4 or 8. Almost nothing in between (steps are bimodal).
4. **Lean.** Pick 1 or 2: a 128 course set back 32 (1 in 4, 14.0 degrees), 40 (5 in 16, 17.4) or 16 (1 in 8, 7.1).
   Giant walls lean 2 to 11 (1856 high set back 67 to 346). Half the leaning faces look down (heads over), half up.
5. **Turn.** Pick 1 to 3 plan turns from 45, 26.6 (1 in 2), 14.0 (1 in 4), 22.5 (the core's octagon, on the grid as
   22.2 and 23.5). A detail group uses 2 to 4 off-axis directions (90th percentile 4 to 12). Off-axis area: 4 to 15% for a
   plain hall, 15 to 35% for a showpiece, up to 44 to 56% (the core, the intro's wreck).
6. **Break the mirror.** The relief of a wall and the two sides of an opening or passage differ: one side 1 or 2
   layers, the other 3 to 5; different step depths; one side leaning, the other plumb; bays 88 to 408 deep on one
   side only (U27). Aim: a third of articulated walls (3+ relief levels) match their mirror below 0.6; the two
   sides of a passage match below 0.3.
7. **Scale jump.** About one touching pair in six differs 8 times or more in size (a 2 to 16 plate on a 512 to 1216
   slab). Texture near plates at 0.25, giant faces at 1 or 2 so the panel pattern grows with the piece.
8. **Rhythm.** Repeat at 256 (or 128), then break it: of runs of like pieces, 2 in 5 even, 1 in 5 in pairs (14 to
   36 apart, a pair every 143 to 285), the rest free (170, 36, 510).
9. **Light.** Light panels (lights/white004_nochop, white003_nochop) set flush in the plate layer, 16 to 64 thick,
   64 to 192 by 140 to 1150; upright 3 to 2 over lying; cold 147 226 240 or 122 173 188; warm (254 95 48,
   249 177 106) only where the place is failing.
10. **Dress.** Combine pipes along it (2 in 5 turned by 15 off the walls), creeping-wall props hung tilted 6 to 54
    and often upside down (roll near 180), lights aimed (valve-combine-aimed).
11. **Meeting the old city.** Inside an old building, plates laid flush and square on the old walls. Where the
    Combine's own mass arrives, drive it in at 1 in 2 (27) or 45, cut 4 to 128 into the old.

## A generator for our tools (not built)

- **`_dev/tools/map_combine.py`** (new, about 400 lines): `combine_piece(kind, box, seed)` for kind wall, gate,
  tower, hall side; it lays the mass, plate stacks, lean courses and turns by the recipe and returns convex solids
  as face lists for `Vmf.detail_shapes` / `convex_text` (map_build.py already has `prism` and `convex_text`).
  Sloped and turned faces from three integer points on the 4 to 16 grid (as HL2 did; EP1's are fractional).
- **Its own check** (from `walls.py` here): a depth picture of each wall, mirrored; a seed is thrown away when an
  articulated wall matches 0.9 or more, or a passage's two sides match 0.5 or more; then `map_assets.py`, then one
  `map_view.py` picture. A map_lint kind `mirror` could report the same on any Combine piece.
- Shown to the owner on a test map before it touches anything they settled.

## The numbers

**1. Symmetry.** (a) Wall relief as a depth picture on an 8 grid, mirrored about the best upright line in its middle
half. Articulated walls (3+ relief levels): Combine 1082 walls, 30% match their mirror below 0.6 and 43% at 0.9 or
more; old 206 walls, 15% and 46%. Per map the Combine's median runs 0.57 (d3_citadel_04) to 1.0 (the core), the
old 0.71 to 1.0. So the Combine is lopsided twice as often, but half its walls are still mirror-true. (b) The two
sides of a passage (walls facing 64 to 640 apart): median match 0.02 (d3_citadel_05) to 0.30 in 12 of 15 maps;
exceptions d3_citadel_02 0.96, ep1_citadel_04 0.63, the core 1.0. The old city's streets 0.18 to 0.50. (c) Round
doors (door plus 160 each side, 192 deep): Combine medians 0.05 (the Nexus's Combine plates round old doors) to
0.73, ep1_citadel_03's 63 door pieces 0.41; old doors 0.23 to 0.81. Weak. (d) Detail groups (Valve's own tied
groups) are mostly true to a mirror (median 0.91 to 1.0): single pieces are symmetric, their arrangement is not.
d3_citadel_03's shaft walls (300+ brushes, 384 to 1400 wide, 6100 high) 0.93 to 0.998; d3_breen_01's office has
mirrored pairs of pillars (-1206..-246 at y 306..1266 and -1266..-306).

**2. Angles.** Combine faces off the axes: 18.1% of 4.6 billion square units of visible Combine area (per map 3.8%
d3_citadel_02 to 56% ep1_intro; the core 44%); old intact City 17 (d3_c17_10a, b) 1.4%, ruined (ep1_c17) 6.5%.
Kinds by area: turned only 2 to 30%, leaning only 0.4 to 11%, both 0 to 8%. Leans as height and set-back: 128 and
32 (39% of leaning area in d3_citadel_02, 30% in 05, 11% in ep1_citadel_01), 128 and 40 (33%, 26%, 10%), 128 and
16 (23% in d3_citadel_03); giant walls 1856 to 2560 high set back 67 to 346. Faces looking up 43 to 62%. Turns:
45 (commonest: 83% of turned area in d3_citadel_02, 88% in ep1_citadel_01), 1 in 2 (24 to 25% in ep1_citadel_00,
d3_citadel_05, 56% in styleguide_destroyed_citadel), 1 in 4 (36% in d3_citadel_03), 22.5, laid on the grid as 22.1 to 22.3 and 23.5 (53% in ep1_citadel_03, 62% the core). HL2's off-axis plane points sit on a 4, 8 or 16 grid (fractional 9% in d3_citadel_02); EP1's are
mostly fractional (84% in ep1_citadel_03): rotated freely.

**3. Plates and layers.** Plates (thinnest side 16 or less, short side 3 times that) are 32 to 74% of Combine
brushes (median 56%). Thickness tops: 8 (26 to 38% in d3_citadel_02, 05, ep1_citadel_00), 16 (30% d3_citadel_03),
2 (25 to 28% ep1_citadel_01, 03; 39% the Nexus), 4, then 64 and 128 for masses. Long side 128 commonest in HL2
(22 to 33%), 1024 next; EP1 smaller (32 to 160). Wall stacks (same-facing faces within 64 of depth): 3+ layers on
17 to 67% of the area in 14 of 15 maps (the core 3%). Steps between layers: 64, 48, 56 and 4, 8 lead every map.
Joins between plates in one plane: gap 0 on 60 to 81%, then 8, 12, 40, 48, 64.

**4. Silhouettes.** No clear difference found. Flat Combine slabs held at one edge only (cantilevers): 3 to 24% (old
10 to 21%), reach median 80 to 650. Wall columns proud at the top by more than 4: 5 to 16% (old 0 to 19%). Detail
groups wider at the top: 2 to 45% (old 0 to 50%, small samples). The leaning look comes from the leans above, not
from top-heavy masses.

**5. Rhythm.** 1345 runs of like Combine pieces (3 or more in a line): even 40% (pitch 256 on 416 of them), near even
15%, paired 19% (pairs 14 to 36 apart, a pair every 143 to 285, the pairs themselves evenly spaced), free 26%. Old
City 17 (162 runs): even 47% (pitch 128), paired 17%, free 22%. EP1's Citadel is freer (51 to 73% uneven) than
HL2's (27 to 40%). Examples: ep1_citadel_03 fins 16 by 32, spacings 32, 160, 32, 160...; plates 2 thick 14, 98,
14, 490; d3_citadel_04 slabs 170, 36, 510. Sizes repeat inside a Valve detail group about as often as in old ones (a
median 39 to 94% of its pieces share their size with another; old 0 to 91%): the oddness is not in sizes.

**6. Scale.** Touching Combine pairs differing 8 times or more in size: 15.8% of 148 thousand pairs (16 times: 5.1%);
old 6.5% (1.6%). Combine longest sides: median 128 to 512, 90th percentile 512 to 1737 (the Nexus's Combine plates
64 to 176). Texture scale: 0.25 on 39 to 81% of HL2's Combine area, 1.0 on 21 to 55%, 2.0 on 42% in d3_citadel_01.

**7. Meeting the old.** Two ways. Inside old buildings (the Nexus, d3_c17_10a, b): 43 to 79% of the Combine's brushes
touch old ones, 2.5 to 6% cut in, 0 to 6% turned, the rest stand 14 to 16 off. Where the Citadel's mass arrives:
ep1_citadel_00, 40% of the touching Combine brushes cut in (to 64 and 128), 43% turned against the old, by 27
(1 in 2) on 65% of those; ep1_citadel_03 (the old concrete under the core) 67% cut in 4 to 13, 29% turned (45);
ep1_c17_00 29% cut in, 29% turned (13).

**8. Light.** Light-panel brushes: 11 to 74 a map; their face flush with the plate beside it on 77 to 100%; HL2
panels 16 to 64 thick, 64 to 192 by 140 to 1150; ep1_citadel_03's thinner, 8 to 16 by 16 to 100 by 48 to 256;
upright 3 to 2 over lying. light and light_spot colour 147 226 240 leads (122 173 188 in d3_citadel_04, 05); EP1's
failing core adds 254 95 48, 249 177 106, 235 114 33. Glow sprites 1 to 92 a map (glow01, glow03, glow06).

**9. Props on its walls.** In the 15 maps: 745 single Combine pipes (pipes01 to 03) and 310 clusters: singles 39% on
15s, 20% on 45s, 39% square, 9% tilted (pitch 90: rising runs). combine_light 175: 10% square, 22% tilted. Creeping
walls (combineinnerwall*, combineinnerwallcluster1024) 39: 74% tilted, mostly rolled near 180 (upside down) with
pitch 6 to 54, 49% at free yaws, nearest twin a median 900 away. combine_intwallunit 43, 86% square, nearest twin 64
to 124 apart. Railings (railing_128, 256, 512) 233, 60% square.

## Pictures

- `arch_01_core_lozenge.png`: styleguide_core from the south-west (map_view, iso SW, whole map). The reactor room as
  one centred column: square shaft, an octagonal lozenge in the middle turned 22.5, opening out and closing in; the
  formal core is built round its axis, the exception to the no-mirror rule. Five eye views tried for lopsided walls
  (ep1_citadel_01 -3460 1712, d3_citadel_04 -330 -1732, d3_citadel_05 -2331 -625) showed only close dark faces in
  map_view; a cut-away iso is the better next try.

## What did not work

- The units cut from whole connected masses (the Citadel is one piece) gave numbers that hang on where the cut fell;
  Valve's own detail groups and the wall rasters were used instead.
- Volume-based mirror scores ignore thin plates (a plate 2 thick on a wall 16 thick barely moves them); edges and
  depth pictures were used instead.
- Cantilevers and top-heavy silhouettes showed no difference from the old city by these measures (see 4).
- Door surrounds (1c) barely differ from old doors: the window round a door also takes in floors and ceilings.
