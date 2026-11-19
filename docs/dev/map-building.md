# Building pieces of map (`_dev/tools/map_build.py`, `map_forest.py`)

The owner, 19 November: "It is SO labor intensive to do all the menial map building ... I wanted to add more of an 'edge of city' or even outside of city area to the map for the resistance to hide in the woods outside the city, or in the canals." They use **Hammer++**. Their map in progress is `c18_lc.vmf` (27 MB, a decompile of `rp_c18_ug` they are changing; on their Google Drive, see `docs/dev/map-survey.md`).

**The rule:** the tools write a NEW, separate VMF for each piece. They never open or change the owner's VMF. The owner brings a piece in with a `func_instance` at 0 0 0 (a new version is then just a new file) or with Paste Special at no offset, looks, and compiles. A chat cannot compile or see the map in 3D: the owner is the eyes, and only their compile proves a piece is sealed. **Nothing here has been opened in Hammer or compiled yet** (19 November): the first load of each file is the real test.

```bash
python3 map_build.py canal                                   # lc_canal.vmf
python3 map_build.py forest_bunker --preview bunker.png      # lc_forest_bunker.vmf, and a picture from above
python3 map_build.py forest_cave --preview cave.png          # lc_forest_cave.vmf, cave.png and cave_cave.png
```

`--origin X Y` moves a piece, `--floor Z` sets a forest's gate floor (400), `--first-node N` its first path node id.

**`--test` writes `lc_PIECE_test.vmf`: the piece made to compile and be walked BY ITSELF** (a spawn point, the map's own sun, and for the canal a sky wall where the road comes in), all in a visgroup "for testing alone (never in the real map)". The owner's first compile (19 November, vbsp++ on `lc_canal.vmf` alone) leaked at the quay's path node, 3808 1952 672: not a fault in the piece, the canal is open to the road by design and was compiled without the city. The tool's flood check gives the same leak when the road's opening is not stopped up, and now also fails if any entity is outside the sealed space. What that compile did show: vbsp++ read the file and its brushes without complaint.

## How a piece is made

- **Boxes on a grid (`Plan`):** a piece is drawn on 64-unit squares from above (`Plan.paint`): each square is open under the sky, open under a ceiling ("low"), or nothing. From that come a floor block under every open square, a lid over it, and a solid block in every square touching an open one (corners too), so it is sealed by construction; alike squares are joined into the biggest rectangles. Walls have looks by height (`bands`). Used for the canal and the bunker.
- **Displaced ground and skin (`Vmf.box_text(disp=...)`):** a box face can be displaced, every point of its grid moved to any place. Box corners are written clockwise seen from outside, with Hammer++'s `vertices_plus`; a displaced face's rows run from its first corner to its second and its columns to its fourth. **This was checked against the owner's own VMF:** with that reading, all 473 edge points that its 74 displacements share meet exactly; with rows and columns swapped, 98 do not.
- **Gates:** every piece ends in the same culvert, 512 wide and 256 high (`GATE_WIDE`, `GATE_HIGH`), on the plane where the next piece begins, closed by a black wall and bars in a visgroup of its own ("... gate's cap (delete to join)"). To join two pieces, delete the cap on each side. Each piece is sealed by itself with its caps in.
- **Checks before writing:** every corner on the 1-unit grid; a flood from the air inside must not reach outside (taking away any sealing brush makes it fail: tried); for forests, every ground patch meets its neighbours, the ground stays inside the shell, the cave's skin meets itself everywhere it should, and folded quads are counted. `map_survey.py` on the pieces and the owner's map together showed no piece overlapping another or the city (apart from the two brushes the owner is to delete).
- **Assets:** every model and material name in the three files was checked against file lists of Half-Life 2, Episode One and Episode Two (the Garry's Mod spawnlists, and decompiled QC and VMT trees: `github.com/Facepunch/garrysmod` `settings/spawnlist_default`, `github.com/Pinsplash/ValveQCs`, `github.com/Pinsplash/ValveVMTs`), and every `prop_static` model was checked to be compiled as a static prop. Canal and bunker surfaces use materials already in the owner's VMF. How any of it looks is unchecked.

## The pieces (all sent 19 November; where each sits by default)

**`canal`** (the owner: start at the skybox brush that ends the road, 640 x 16 x 2136 at 3648 1864 1716, brush id 15074; "a standard HL2 Route Kanal size ... not filled with water, that runs for a bit then turns and maybe even forks"). Read as: the canal runs **east**, across the road's end like a T; if they meant straight on north, it is a different layout.
- Joins the road at 3328 1856 (road x 3328..3968, surface z 656, sky z 2784). The owner removes brush 15074 (the sky wall) and 15616 (the invisible wall before it); the piece brings a sky plug for the road above its own lower sky.
- A quay, a low wall, a landing and 31 steps down; the canal 512 wide, floor z 400, walls to z 912, sky lid z 1168. East 3072, north 2048, a fork; a low bay off the north run.
- **Details (the owner, after their test compile: "the canal is fine, can you add the sloped sides and other details? ... the bridges above the canal go nowhere", "like some dirt/mud on the bottom"):** sloped concrete banks along every wall (128 out, 128 up: 45 degrees, the steepest that can still be walked), with a quarter-pyramid where a wall's corner sticks out; **mud and silt** as a second, displaced skin over the floor (58 patches of `nature/blendmuddirt001a`: mud where it rises above the concrete, bare concrete where it dips below); **two footbridges that go somewhere** (one from the quay across to a barred doorway in the north wall, one across the north run between two barred doorways) and a **working ladder** up to the second, set up as the owner's own map does its ladders (`metalladder002` pieces 128 tall, `func_useableladder` 28 out from them, `info_ladder_dismount` at each end); two pipes across the long run on concrete saddles; drain stubs in the walls; a concrete lip along the walls' tops and a rib every 512. 83 path nodes from id 4000 (the flat of the floor, the quay, stairs and bridges); 9 physics props.
- Shapes that aren't boxes (`Vmf.convex_text`, `prism`, `octagon`): any convex solid from its faces, each turned clockwise seen from outside. Every solid in every generated file was checked to wind outwards and be closed and convex, with the owner's map as the reference (0 of its 54,875 faces fail the same test).
- **Gates:** east at x 7936, y 4160..4672; north at y 5696, x 5888..6400. (The first version sent had a capped east arm and a barred tunnel mouth instead: this one replaces it.)
- Fills x 3264..7936, y 1856..5696.

**`forest_bunker`** ("forest (bunker, pond)", `BunkerForest`): gate in its **west** wall, meeting the canal's east gate. Fills x 7936..12288, y 960..5312, z 80..1952.
- A valley 4096 square inside a ridge 440 high; 302 trees (Episode Two pines, some leafy ones round the pond), 170 ferns and bushes, rocks, fallen wood; a dirt trail from the gate past the pond to the bunker.
- **The pond:** about 1280 x 960, surface z 394, up to 62 deep, an island 42 above the water with a tree; cattails on the shore.
- **The bunker:** under a mound against the north ridge, its concrete roof level with the mound's top. A doorway (floor z 424), stairs down 128, a main room, a bunk room (west, dark) and a generator and store room (east, a failing light); beds, lockers, a desk, shelves, a generator, drums. A wrecked truck and barriers outside. 142 path nodes from id 4400.

**`forest_cave`** ("forest (cave, stream)", `CaveForest`): gate in its **south** wall, meeting the canal's north gate. Fills x 5504..9856, y 5696..10048.
- The same valley and planting (323 trees); a trail from the gate to a ford and on to the cave.
- **The cave:** in a hill against the north ridge. Its skin is 26 displaced faces hung on a square tube (a floor, a roof and two walls for each 256 of its 1280 length, a dome at the end, five pieces of rock face round the mouth), all from one function so every shared edge meets. Mouth about 416 wide and 251 high, floor z 430; a chamber 488 high about 800 in. The hillside is deliberately torn along the mouth's line (21 ground corners have two heights) so the mouth is a hole in the hill; the rock face covers the tear. Stalactites, cave rocks, 2 dim lights.
- **The stream:** level water (Source water cannot slope), surface z 414, in a bed carved from a spring in the cave's chamber, out of the mouth and across the valley to a sink pool. 145 path nodes from id 4800.

**Counts:** with all three the map has about 2,815 path nodes (the engine's limit is 4,096) and about 230 displacements.

## What the owner's compiles and walks have found (fix the cause, and add a check for its kind)

- **19 November, the canal alone leaked:** the plain file is open to the road by design. Now `--test` writes a closed version, and the flood check also fails if any entity is outside the sealed space.
- **19 November, the detailed canal, walked in game:**
  - *A doorway's black back wall seen edge-on* (at 6522 4164 707): the second footbridge's east doorway sat right beside the east arm, so it had no wall on that side. The bridge and its doorways moved 256 south; a check now fails any doorway that is open anywhere but its front.
  - *Drain stubs running through the wall ribs* (five places): the first stub of each wall was 32 from its first rib. Stubs now sit half way between ribs, and ribs and stubs are only placed where they keep 24 clear of everything else on the walls (`taken`, `fits`).
  - *Bars a player could walk between* (48 apart): every row of bars is now 8 thick and 16 apart with a crossbar (`bar_row`), and an unseen player clip stands in the same place (`barred`). The forests' gates use the same.

## Known weak points (tell the owner; fix from what they see)

- The rock face round the cave's mouth is the likeliest to show seams, where it meets the hillside. Rocks are placed to dress its edges.
- Each forest is one open room to the compiler: everything in it is drawn at once. Trees fade out between 2800 and 3400 units.
- The forests have no lights of their own outside (the map's sun and sky do it) and show the map's own 3D skybox (the city) over their ridges.
- Props inside the bunker were placed without knowing their sizes: some may sit in a wall.
- Players without Episode Two will see errors and missing textures in the forests.

## The owner's next idea (19 November)

Run the canal and/or forest in a half ring round the north of the city to a second road's end in the west: the skybox brush 16 x 640 x 1504 at -2616 2240 1584 (brush id 14734, x -2624..-2608, y 1920..2560; the invisible wall before it is 15630). That road runs east-west, its surface is z 840 (184 higher than the east road's 656), its sky z 2336. Checked in their VMF: free just west of the brush; the city reaches x -3056 south of it, -2768 just north, -4120 at y 3072..4096 and about -3430 above that; its north edge is y 6288 (the six leftover rooms, to be deleted, are between x 820 and 3536, y 5876 to 7444). The cave forest now sits north-east of that; a ring would pass south of it or through it. Not built.

**Not built yet:** anything that isn't a box or a displaced face (sloped concrete banks, curves), soundscapes, fog, hints and areaportals for the new areas, a 3D skybox of forest for the forests.
