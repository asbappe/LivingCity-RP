# The Propper++ model kit (the canal ring's Combine wall and ruins)

Written by `_dev/tools/map_propkit.py`: never edit these files by hand; change the code and run it again (`python3 map_propkit.py`; then `--check` says whether the folder matches the code, and casts rays from where players stand at every piece: none may meet a face left out of it first).

Each VMF here is one model. It holds a single `func_brush` whose origin (0 0 0) is the model's origin; every face nobody on the ring's street or in its canal can see is `tools/toolsnodraw`, which Propper++ leaves out. The ring's builders (`map_corridor.combine_wall`, `map_backdrop.py`) place these models as `prop_static`s named `models/lc/kit/<file name>.mdl`, and read `kit.json` for their sizes, lamps and lights.

## Pieces

| File | What | Size (x by y by z) | Faces kept | Pivot |
|---|---|---|---|---|
| `lc_cwall_512_a.vmf` | Combine wall run, 512 long, look a | 512 by 141 by 704 | 34 | its start, on the core's street face, at street height |
| `lc_cwall_512_b.vmf` | Combine wall run, 512 long, look b | 512 by 157 by 512 | 24 | its start, on the core's street face, at street height |
| `lc_cwall_640_a.vmf` | Combine wall run, 640 long, look a | 640 by 155 by 672 | 43 | its start, on the core's street face, at street height |
| `lc_cwall_640_b.vmf` | Combine wall run, 640 long, look b | 640 by 163 by 672 | 43 | its start, on the core's street face, at street height |
| `lc_cwall_768_a.vmf` | Combine wall run, 768 long, look a | 768 by 147 by 512 | 38 | its start, on the core's street face, at street height |
| `lc_cwall_768_b.vmf` | Combine wall run, 768 long, look b | 768 by 159 by 672 | 54 | its start, on the core's street face, at street height |
| `lc_cwall_896_a.vmf` | Combine wall run, 896 long, look a | 896 by 155 by 640 | 49 | its start, on the core's street face, at street height |
| `lc_cwall_896_b.vmf` | Combine wall run, 896 long, look b | 896 by 159 by 512 | 42 | its start, on the core's street face, at street height |
| `lc_cwall_1024_a.vmf` | Combine wall run, 1024 long, look a | 1024 by 155 by 640 | 48 | its start, on the core's street face, at street height |
| `lc_cwall_1024_b.vmf` | Combine wall run, 1024 long, look b | 1024 by 157 by 512 | 51 | its start, on the core's street face, at street height |
| `lc_cwall_pier.vmf` | Combine wall pier (over every joint, flush with every free end) | 192 by 192 by 680 | 41 | its middle, on the core's street face, at street height |
| `lc_cwall_corner.vmf` | Combine wall corner pier (the wall turning round a corner) | 176 by 184 by 712 | 52 | the corner of the two cores' street faces |
| `lc_ruin_block_a.vmf` | ruin: block | 256 by 256 by 408 | 12 | the middle of its footprint, on the ground |
| `lc_ruin_block_b.vmf` | ruin: block | 384 by 256 by 536 | 13 | the middle of its footprint, on the ground |
| `lc_ruin_block_c.vmf` | ruin: block | 320 by 320 by 664 | 11 | the middle of its footprint, on the ground |
| `lc_ruin_block_d.vmf` | ruin: block | 512 by 384 by 472 | 11 | the middle of its footprint, on the ground |
| `lc_ruin_block_e.vmf` | ruin: block | 448 by 256 by 792 | 13 | the middle of its footprint, on the ground |
| `lc_ruin_block_f.vmf` | ruin: block | 640 by 448 by 600 | 13 | the middle of its footprint, on the ground |
| `lc_ruin_block_g.vmf` | ruin: block | 192 by 256 by 472 | 12 | the middle of its footprint, on the ground |
| `lc_ruin_house_a.vmf` | ruin: house | 272 by 272 by 392 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_house_b.vmf` | ruin: house | 400 by 272 by 520 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_house_c.vmf` | ruin: house | 336 by 336 by 592 | 7 | the middle of its footprint, on the ground |
| `lc_ruin_house_d.vmf` | ruin: house | 464 by 400 by 504 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_house_e.vmf` | ruin: house | 528 by 272 by 552 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_house_f.vmf` | ruin: house | 208 by 272 by 464 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_shell_a.vmf` | ruin: shell | 256 by 256 by 512 | 12 | the middle of its footprint, on the ground |
| `lc_ruin_shell_b.vmf` | ruin: shell | 384 by 320 by 704 | 18 | the middle of its footprint, on the ground |
| `lc_ruin_shell_c.vmf` | ruin: shell | 320 by 256 by 832 | 17 | the middle of its footprint, on the ground |
| `lc_ruin_shell_d.vmf` | ruin: shell | 512 by 384 by 640 | 24 | the middle of its footprint, on the ground |
| `lc_ruin_shell_e.vmf` | ruin: shell | 448 by 256 by 896 | 20 | the middle of its footprint, on the ground |
| `lc_ruin_shell_f.vmf` | ruin: shell | 192 by 192 by 640 | 13 | the middle of its footprint, on the ground |
| `lc_ruin_collapsed_a.vmf` | ruin: collapsed | 384 by 320 by 416 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_collapsed_b.vmf` | ruin: collapsed | 512 by 384 by 480 | 14 | the middle of its footprint, on the ground |
| `lc_ruin_wall_a.vmf` | ruin: broken wall | 384 by 24 by 256 | 13 | the middle of its footprint, on the ground |
| `lc_ruin_wall_b.vmf` | ruin: broken wall | 512 by 24 by 256 | 12 | the middle of its footprint, on the ground |

Every piece faces -y (south in Hammer's top view): the wall's battered face and the ruins' fronts. The wall is 512 high over the street (its piers 640 and their crowns more); the ruins stand on the canal's rim.

## Making the models (facts for the owner's instructions)

- Hammer++, once: Tools > Options > Build Programs > MDL executable: Garry's Mod's `bin/studiomdl.exe` (the 32-bit one in `bin`, not `bin/x64`).
- For each VMF here: open it, select all (Ctrl+A), Tools > Propper++ (Ctrl+Shift+P), then Build + Compile.
- Propper++ settings, set once and kept: Model Path + Name `lc/kit/$vmf` (each model is named after its file: `models/lc/kit/<file name>.mdl`); Entity name as physics mesh BLANK (no collision: the ring puts a player clip along the wall instead); Skip nodraw faces ON; Material path `models/lc/kit` (the converted materials go to `materials/models/lc/kit/`); Rename shaders ON and Remove $bumpmap/$phong ON (so VRAD can light the props per vertex); Add incremental suffix OFF (so a piece built again replaces the old model).
- The first time: with Create entity after compile on, the model should land exactly where the brushes were, facing the same way. If it comes out turned or moved, stop and say so (the ring places every model by that).
- What the compile makes, to copy to the server (both under `garrysmod/`, as FastDL mirrors it): `models/lc/kit/` (each piece's .mdl, .vvd and .vtx files) and `materials/models/lc/kit/`. They are our own models, not in Half-Life 2: pack them into the map (CompilePal's pack step, or VIDE) or send them as downloads, or players see errors.
- The map's compile: VRAD with `-StaticPropLighting` (props lit per vertex; without it each model is lit from one point, and a long wall run comes out flat or dark) and `-StaticPropPolys` (shadows from the models' own faces: they have no collision mesh to cast them from).
- Until a model is compiled, the game shows an error model where it stands, and `map_assets.py` reports it as ours, not missing.

## What is left out of each model

- The wall: faces looking away from the street (to +y), bottoms on the ground, tops more than 256 over the street, and each run's two ends (a pier, the corner pier or the next run covers them). The corner pier keeps its far sides (one of them stands out along the second street).
- The ruins: backs, bottoms and roofs (they stand on the canal's rim, above every eye on the street and in the canal).
- Any face that lies inside another solid of the same piece.
- Built with `--keep-tops`, the kit keeps every top and roof (for a place where players could look down on it). This kit was built without them.

