# Building pieces of map (`_dev/tools/map_build.py`)

The owner, 19 November: "It is SO labor intensive to do all the menial map building ... I wanted to add more of an 'edge of city' or even outside of city area to the map for the resistance to hide in the woods outside the city, or in the canals." They use **Hammer++**. Their map in progress is `c18_lc.vmf` (27 MB, a decompile of `rp_c18_ug` they are changing; on their Google Drive, see `docs/dev/map-survey.md`).

**The rule:** the tool writes a NEW, separate VMF for each piece. It never opens or changes the owner's VMF. The owner brings a piece in with a `func_instance` at 0 0 0 (a new version is then just a new file) or with Paste Special at no offset, looks, and compiles. A chat cannot compile or see the map in 3D: the owner is the eyes, and only their compile proves a piece is sealed.

```bash
python3 map_build.py canal          # writes lc_canal.vmf
```

**How a piece is made:** it is drawn on a 64-unit grid from above (`Plan.paint`): each square is open under the sky, open under a ceiling ("low"), or nothing. From that come a floor block under every open square, a sky lid over it, and a solid block in every square touching an open one (corners too), so it is sealed by construction; alike squares are joined into the biggest rectangles. Walls have three looks by height (canal concrete, upper wall, sky). Stairs, beams, bars and low walls are `func_detail`. Materials are all ones the owner's VMF already uses (`MAT`, at the top). Everything is in visgroups ("LC canal: walls and floors", "details", "path nodes", "props").

**It checks itself** before writing: every corner on the grid, and a flood from the air inside that must not reach the outside with the piece's one opening stopped up (taking away any sealing brush makes the check fail: tried). Then `map_survey.py` on the piece, and on the piece and the map together, for the pictures.

**The first piece, `canal`** (the owner: start at the skybox brush that ends the road, 640 x 16 x 2136 at 3648 1864 1716, brush id 15074; "a standard HL2 Route Kanal size ... not filled with water, that runs for a bit then turns and maybe even forks and maybe dumps out to a forest"). Read as: the canal runs **east**, across the road's end like a T (along the brush's 640 side), away from the city. If they meant straight on north, it is a different layout, not a setting.
- Joins at 3328 1856 (the road is x 3328..3968, its surface z 656, its sky z 2784). The owner removes brush 15074 (the sky wall) and 15616 (the invisible wall before it); the piece brings a sky plug for the road above its own lower sky (z 1184).
- A quay at road level (640 x 256), a low wall, a landing and 31 steps (8 x 12) down; the canal 512 wide, floor z 400 (256 deep), walls to z 912, sky lid z 1168.
- East 3072, north 2048, then a fork: east arm 1536 (capped: the forest joins here later), north arm 768 to a barred tunnel mouth. A low bay (256 x 384, 192 high) off the north run to hide in. Two beams across. 125 path nodes (ids from 4000; the map's own stop at 3043), 8 cubemaps, 9 physics props.
- It fills x 3264..8000, y 1856..5760: checked empty in the owner's map on 19 November (the six leftover rooms start at y 5876).

**Not built yet:** the forest (displacement ground, trees), anything that isn't a box (sloped banks, curves), lights (the map's sun does the canal), soundscapes, hints and areaportals for the new area.

**The owner's next idea (19 November, after the canal was sent, before testing it):** run the canal and/or forest in a half ring round the north of the city to a second road's end in the west: the skybox brush 16 x 640 x 1504 at -2616 2240 1584 (brush id 14734, x -2624..-2608, y 1920..2560; the invisible wall before it is 15630). That road runs east-west, its surface is z 840 (184 higher than the east road's 656), its sky z 2336. Checked in their VMF: free just west of the brush; the city reaches x -3056 south of it, -2768 just north, -4120 at y 3072..4096 and about -3430 above that; its north edge is y 6288 (the six leftover rooms, to be deleted, reach y 7444 between x 820 and 5704). So a ring would run north from the canal's north arm to about y 6500..7000, west to about x -4800, south to y 2240 and east to the brush: about 18,000 units, inside the engine's limit of 16,384 each way. Not built: waiting for their test of the first piece.
