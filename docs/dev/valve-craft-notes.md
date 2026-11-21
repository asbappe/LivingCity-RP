# Valve's building craft (measured from 22 of Valve's map sources, 21 November; reference)

# Valve building craft, second pass (21 November)

Read from the plane-only VMFs in scratchpad/valve (city = d1_trainstation_01 to 05, d3_c17_13, d1_town_03,
d3_citadel_01, d2_coast_12; canals = d1_canals_01, 01a, 02, 03, 05 to 13). Visible = not tools/, dev/, effects/,
skybox. "Near/far" = distance from the nearest info_node (AI node), the only sample of play space in the files.
Scripts and caches: scratchpad/craft2/ (ex2.py extracts faces with uaxis/vaxis/lightmapscale; tex, tex2, brush,
ovl, disp, disp2, space, sky, light, light2, frames, misc, trim2, combine .py measure). Texture sizes are not in
the files, so seams are tested against 128/256/512 texels.

## 1. Texture craft

| | city (67704 faces) | canals (132409) |
|---|---|---|
| scale 0.25 / 0.5 / 1 (faces) | 84% / 6% / 3% | 63% / 31% / 2% |
| scale by area | 0.25 41%, 1 23%, 2 8%, 0.5 8% | 0.25 43%, 0.5 39%, 2 9%, 1 7% |
| rotation used | 3% (90 deg on 81% of those; wood, metal) | 4% (90 deg on 88%) |
| texture turned off the world axes on a square face | 1.5% | 3.7% |
| angled faces left world-aligned / following the face | 75% / 25% | 63% / 37% |
| some shift on u or v | 80% | 82% |

Scale by material (area): canal concrete at 0.5: concretewall074a 53%, 022a 71%, 004c 64%, 010c 89%, 074c 90%,
010b 88%; concretewall004a and concretefloor006a stay at 0.25 (87%, 98%). rockwall006a 2 (85%); blends 0.5 to 1;
water 0.5 (70%) or 1; city dirt floors 0.27 to 0.38; citadel metal 0.5 to 2.
Scale by distance (area): near (<256) 0.25 on 51 to 64%; far (>1024) 1 and 2 on 43% (city), 21% (canals).

Seams on walls whose v runs vertically (35681 city, 60507 canal walls):

| foot on a seam of | 128 | 256 | 512 | no-shift chance at 512 |
|---|---|---|---|---|
| city | 54% | 45% | 36% | 24% |
| canals | 56% | 46% | 34% | 30% |

The top behaves the same (35% vs 24%). u edges: no better than chance. Corners (same material, perpendicular,
one brush): 24840 pairs (city), texture runs the same way on 56%, continues across on 7.5% (chance): not wrapped.

Lightmapscale (faces): 16 71 to 74%, 64 12 to 13%, 32 8 to 11%, 8 3 to 4%, 4 under 1%, 128 under 1%.

| distance from nodes | city brush faces | canal brush faces | displacements (canals) |
|---|---|---|---|
| < 256 | 16 86%, 32 6%, 8 4% | 16 83%, 8 10% | 16 69%, 64 23% |
| 256 to 1024 | 16 68%, 32 20%, 64 8% | 16 76%, 64 14% | 64 70%, 16 21% |
| 1024 to 3000 | 16 48%, 64 30%, 32 18% | 16 71%, 64 19% | 64 78%, 128 15% |
| > 3000 | 64 54%, 16 34% | 16 61%, 64 16%, 32 15% | 64 75%, 128 17% |

At 8 or 4: stonefloor006a/c, stonewall050b/c, plasterwall044b/005a, concretewall004a/b (canal walkways),
metalstair004a, metalpipe009a/b, metalwall018e, metaltrack001a, metalrail013b. At 32 and over: citadel_metalwall077a,
stonewall050a/c, canal concretewall004c, rockwall006a, canal_reeds, dirtwall001a.

Trim strips (two small sides <=16 x <=32, long >=64, touching a bigger brush): city 1627, canals 1481. Sections
16x32 239, 8x32 231, 8x16 183, 8x8 150, 4x8 110, 16x16 92. func_detail 59% / 83%. Vertical 54% (city), horizontal
58% (canals). Material vs the touched brush: other 49% / 66%, same 26% / 16%, same kind 25% / 18%.
Top trim materials: citadel_metalwall077a, metalwall061f, plasterwall021a, stonewall050b/c, woodfloor005a (city);
woodfloor005a/006a, metalpipe003a, metaltruss017a, stonewall051a (canals).
Ledges along walls (horizontal strips touching a wall 96+ tall): city 246: stand out 8 (116), 16 (65), 32 (25);
tall 16 (88), 32 (75), 8 (38); bottom over the ground: 256+ 119, 96 to 256 84, 8 to 96 8, foot 9 (median 319).
Canals 331: out 16, 32, 4; mostly 96 to 256 up (median 181).
Materials per 512 cube holding AI nodes: median 5 (p90 15), kinds median 3 (city) / 2 (canals).

## 2. Overlays and decals

| | city | canals |
|---|---|---|
| info_overlay / infodecal | 157 / 699 | 75 / 613 |
| per map | ts03 54 ovl, ts02 162 dec; c17 3 ovl; cit 0 and 0 | c05 24 ovl; c12 85 dec |
| 512 cells with nodes holding any | 36% (p90 4, max 19) | 26% (p90 2, max 9) |
| overlays across 2+ faces | 50% | 35% |
| atlas part (Start/End U/V not 0-1) | 46 | 24 |

Overlays: floor = sandtrack02a, redrunner001b, decalstain, trash, scorch1; wall = ivy01-03, decalstain015a/002a,
posters, plaster; canals: decalconcretedrain002a (11), slimeoverlay001a (8), lambdaspray_2a, sign_gate5.
Overlay sizes (median): stain 128x137 (64 to 602), ivy 232x231, trash 128, burn 260, poster 128x75, drain 96x128.
Decals: floor = trash 158, leaves 105; wall = graffiti 85, stain 69, plaster 67, posters 46, ivy 45; canals wall =
ivy 164, graffiti 87, stain 37, signs 30, drains 27; floor trash 126. Top: leaves_ground02 107, trashdecal01a 87+90,
decalstain015a 62, ivy03 40, ivy02 97 (canals), decalgraffiti001b/c/d.
Height on walls: overlays median 74 over the floor (p10 28, p90 157); decals 78 (p10 28, p90 398); canals 108/112.

## 3. Displacements

| | city 643 | canals 2600 |
|---|---|---|
| power 2 / 3 / 4 | 86% / 11% / 2% | 66% / 33% / 1% |
| surface floor / wall | 253 / 332 (coast cliffs) | 1855 / 725 |
| common size | 512x512, 1024x1024 | 1024x1024 (1363), 1024x512 (586) |
| lightmapscale | 64 47%, 32 27%, 16 20% | 64 70%, 128 16%, 16 12% |
| alpha painted | 47% (blend materials: 71%) | 88% (blend materials: 95%) |
| offset up / down | 41% / 52% | 63% / 34% |
| near play (<256) / far (>1024) | 42% / 25% | 6% / 82% |
| floor edges sewn to another disp | 65% | 72% |

Blend materials: blenddirtgrass008b 808 (canals), blendtoxictoxic004a/002a, blendgrassgravel001b, blendsandsand008b.
Walls: cliffface001a 221, dirtwall001a 128 (coast); rockwall006a 636, canal_reeds 590 (canals).
Borders are not pinned: border offset mean (median) 144 vs inner 116 (canals); only 0.5% have a flat border.
Floor edge beside a brush floor, displaced edge vs that floor: canals mixed 1344, over 802, under 710, flush 16;
city mixed 89, under 72, over 20, flush 19. At a wall: canals 323 at it, 149 past its plane; the edge climbs a
median 34 (p90 124) up the wall.

## 4. Brush craft

| | city | canals |
|---|---|---|
| func_detail share of brushes / of visible area | 47% / 19% | 73% / 27% |
| detail kinds | angled 46%, strip 25%, thin 12%, mid 11% | angled 72%, strip 10% |
| world kinds | angled 31%, thin 29%, strip 14%, mid 13%, large 12% | large 32%, angled 29%, mid 26% |
| fully covered faces nodraw / textured | 22% / 71% | 28% / 67% |
| uncovered faces nodraw | 18% | 20% |
| far brushes (>1024): share, faces each, nodraw | 13%, 6, 29% | 48%, 6, 34% |

Chamfers (45-degree faces between square faces): city 1995, width 11 (8 off) 568, 23 (16 off) 265, 6 (4 off) 151,
17 (12 off) 145, 91 (64 off) 133; canals 2729, width 23 557, 91 298, 6 216, 11 154.
Ledge bevels (45-degree slope on a brush with a top and sides): city 741, slant 6 (214), 23 (142); canals 2316,
slant 13 (628), 17 (521).
Angles: walls off the axes at 45 (2736 city, 5049 canals), 26.6 and 63.4 (2:1), 22.5 and 67.5 (canal curves).
Round brushes (8+ vertical sides): city 8 sides 32, 16 sides 34, 10 and 12 11 each, radius median 90;
canals 32 sides 33 (radius to 512), 12 30, 10 29, 8 27, 16 26.
Wall slabs (tall square brushes, length 3x thickness): city 8 (512), 16 (495), 64 (204), 32 (152); textured on both
faces 8 (400), 16 (306). Canals 64 (568), 32 (454), 16 (356), 48 (147).
Doors (prop_door_rotating): opening 48x108 (city 20 of 32, canals 18 of 19), 96 wide for door02_double, 60x108;
jamb depth 8 on 29 of 32 (14 of 19); a strip trim within reach on 28 of 32.
Glass (largest glass face per brush): thickness 2 (63), 1 (40); panes 44x64, 64x72, 42x96; frame proud of the
glass median 4 (2, 5, 1 most often); func_breakable_surf 2x58x99 (c17), 1x94x125 (canals).
Broken walls: odd-angle cut brushes 10% of old-material brushes in d3_c17_13 (62 of 102 six-sided), 18% in
Ravenholm, 8% in d1_trainstation_04; debris models in c17: concrete_section64floor001a/b/c 126,
concrete_section128wall001a 34, rebar_cluster001a/b 41, walldestroyed08a 14.
Combine in the old city: brushes almost absent (ts02 34 metalcombine001 panels 4 to 8 thick: 10 cut into old
brushes, 11 against, 13 apart; c17 5; ts03 to 05 none); models carry it (barricades, combine_lock01, monitors,
CombineInnerwallCluster1024 8 in c17, combine_light002a).

## 5. Space and flow (rays from AI nodes; brush boxes block, props do not)

| | city | canals |
|---|---|---|
| indoor ceiling median (p10, p90) | 139 (100, 356) | 173 (91, 343) |
| corridor (width <192, 3x longer) width, ceiling | 112 (p10 64, p90 178), 120 | 118, 123 |
| room width, length, ceiling | 271, 1040, 139 | 340, 1380, 195 |
| longest view indoors / outdoors | 688 / 3360 | 987 / 3909 |
| outdoor typical view (median of 16 dirs) | 483 | 616 |
| outdoor directions ending within 512 | 52% | 46% |

Per map ceilings: ts03 112 (81 of 125 nodes), ts04 120, c17 104 to 112, town 112, coast 136, c08 120, c07 216.
Share of 256 squares with visible faces that hold a node: 11 to 41% (city); visible area more than 1024 from any
node: ts02 6%, c17 21%, town 22%, ts03 29% (canal numbers are high because airboat runs have few nodes).
3D skybox: sky_camera scale 16 in all 20 maps that have one (town and coast have none); a sealed box with 1 to 47
models (row_res_2, row_upscale, row_hill_cluster, project_building01/02/03_skybox, buildingskybox_002a,
combine_citadel001b, tree_deciduous_card_01_skybox 32 in c10, refinery_0x_skybox) and 0 to 21 ground brushes
(blenddirtgrass008b, concretewall074b/c, dirtfloor012a).

## 6. Light craft

| | city 391 | canals 555 |
|---|---|---|
| light in / out: tone, brightness median | warm 65 cool 42, 10 / cool 9 warm 8, 75 | warm 118 cool 62, 70 / warm 25, 200 |
| light_spot in / out | cool 113 warm 96, 400 / cool 36 of 37, 2500 | warm 166 cool 87, 1200 / warm 61 of 74, 1500 |
| falloff | quadratic 246, constant 50k to 600k 69 (all spots) | quadratic 150, 500/500/0 69, 20/0/1 65 |
| spot pitch -90 / -75 / -45 | 97 / 20 / 33 of 260 | 174 / 35 / 56 of 336 |
| spot cone (common) | 60, 45, 35, 20, 80 | 80, 45, 60, 70 |
| inner (common), inner/outer median | 30, 10, 0; 0.43 | 30, 45; 0.56 |
| _exponent | 1 (215), 0 (21), 0.5 (12) | 1 (122), 5 (117), 2 (35), 0.5 (31) |
| spot with a point light within 40 | 44 (point 8, spot 400) | 37 (point 2, spot 550) |
| indoor nodes with no light within 256 / 512 | 40% / 16% | 58% / 24% |

Colours: city spots 147 226 240 (58, Combine), 254 216 146 (45; lights 41), 159 237 215 (23, fluorescent),
255 245 145; fills 40 51 50 (9), 122 173 188. Canals: spots 241 214 173 (78), 254 216 146 (51), 159 237 215 (45),
248 233 186 (40); lights 216 183 105 (70), 39 64 73 (42). Pure white 26 of 946.

Per fixture (nearest model within 48; light, cone/inner, pitch, exponent, attn c/l/q, z under the model):

| model | light | spot |
|---|---|---|
| light_domelight02_on | 254 216 146 8, 27 under | 254 216 146 200, 60/30, -90, 1, 500/0/1, 11 under |
| lightbulb01a | 254 216 146 8 | 254 216 146 300, 75/30, -90, 500/0/1 |
| prison_lamp001b | 254 216 146 2, 45 under | 254 216 146 400 to 550, 45-60/25-30, -90, 1 to 1.5 |
| light_cagelight02_on | (rare) 241 214 173 15 to 60 | 241 214 173 1850, 80/45, -90, 5, 20/0/1, 15 under |
| lights_florescent01a | | 159 237 215 1200, 80/30, -90, 2, 100000/100/1 |
| lampfixture01a | | 159 237 215 600, 60/20, -90, 3 |
| prison_cagedlight001a | 254 216 146 50 | 254 216 146 75, 70/30, -70 |
| lamp_bell_on | | 255 245 206 3000, 60/30, -90, 2 |
| combine_light002a / 001a | | 147 226 240 2000 to 2500, 35/12, -60 or +30, 500000/0/1 |
| light_spotlight01_lamp | | 187 234 201 1500, 35/20, -30, 0.5, 500000/0/1 |
| walllight001a | | 169 205 188 140, 80/22, up or down |

Suns and fog: d1_trainstation 237 218 143 800, ambient 190 201 220 100, pitch -35; d3_c17_13 and the Citadel
238 200 128 450, ambient 75 96 116 250, pitch -12; coast 237 232 209 70; canals 248 234 205 1000 (c01 to 02),
248 233 186 860 (c05 to 08), 240 187 117 1000 (c09 to 11), 235 155 71 (c13). Fog starts 0 to 2048 (512 in the canals),
ends 4000 to 30000; canal fog 149 158 166 then 145 136 111.
Windows: only 27 light_spots within 128 of window glass (most point down): the room is lit by its fixtures and the
sun through open sky, not by spots aimed through glass.

## 7. Other

Water (canals): 410 water brushes (water_canals_water2 235, toxicslime002a 109, murky 23, cheap001 14), 64 tall
(166) or 32 (106); bed under the surface median 62 (p10 30, p90 71); water_lod_control in every canal map
(1000/2000, 1500/2000, 1500/2500, 1500/3000); func_water_analog 1. City: coast water_wasteland002c, 384 tall.
Ladders: func_useableladder 32 (5 city, 27 canals), 126 to 224 tall mostly (one 624); info_ladder_dismount 225;
metalladder002 models 70, 001 13, 002b 11.
Fences: models dominate (fence03a 199, exterior_fence002a-e 380, fence01a/b 32); brush fences 1 unit thick, 128
tall (metalfence007a func_detail 26, metalfence001a 16, metalfence004a in func_brush 17 in the canals).
Signs: props streetsign003b/005b, signpole001; overlays props/sign_gate5, sign_obersvation; danger decals
decalsigndanger001e 9.

## Check ideas for our tools

1. map_lint lightmap: faces >64k square units at lightmapscale 16 with no viewpoint/spawn within 1024; a
   displacement at 16 or 32; count faces at 8 (should be a few %, on stairs/rails/trims).
2. map_lint scale: rock/cliff/blend/terrain faces at 0.25; one material at 0.25 over a face longer than 1024; a
   canal wall panel over 256 tall at 0.25 (soft).
3. map_lint seam: wall faces of banded materials whose foot is not on a 128-texel seam.
4. map_lint offlamp extension: a lit model from the fixture table without its light_spot under it; a light_spot
   whose cone is under 20 or inner over the cone.
5. map_lint disp: an edge lying exactly on a brush edge at the same height (Valve: 0.6%); a blend material with no
   alpha; power 4 (Valve: 1%).
6. map_lint water: water deeper than 128; water with no water_lod_control in the map.
7. A trims count per module: strips (<=16 x <=32) per 1000 units of wall; Valve city fronts have one about every
   200 units of tall wall (rough: 1627 strips, 246 wall ledges).
8. Materials per 512 cube: warn above 15 (Valve p90), note under 3.

## What did not work

- Texture sizes are not in the files (no VTFs), so seam alignment is judged on 128/256/512-texel multiples only.
- Ray casts use brush boxes: angled brushes block more than they should, props block nothing.
- AI nodes stand in for play space; airboat canal runs have few, so "far" numbers in the canals overstate backdrop.
- Window sills could not be told from the street below (the glass side facing out), so sill numbers are not used.
- Pictures: an eye view in d3_c17_13 landed inside a room and a canal edge view showed only water, and a cutaway
  from above was too small to show the cuts; none kept.

## What our tools do with this (21 November, later)

`map_build.craft` runs on every face our tools lay as a file is written (copied faces are left alone): lightmapscale
8 on stairs, rails, ladders and bars, 64 more than 1024 from every path node, displacements 64 more than 256 from one
and 32 nearer, 16 for the rest; the canal's concrete walls at texture scale 0.5; every upright face's texture starting
at its wall's foot (where the floor in front of it is). `m.lamp` lights each fixture by the per-fixture table (dome
and bell: glow 0.75, a spot down, cone 60/30, falloff 500/0/1, and a faint point light); `map_build.FALLOFF` holds
presets (fill, lamp, cage, tube, flood) that `m.light` and `m.spot` take. `map_lint.py` kinds `lightmap`, `scale`
and `seam` make checks 1, 2 and 3. Not done: 45 degree corners cut at 8; blends and rock at 0.5 or more (the lint
names them: the mud is still 0.25); the canal walls' caged lamps keep their point lights. How any of it looks (the
lamps' brightness, the wall textures' feet) waits on the owner's compile.
