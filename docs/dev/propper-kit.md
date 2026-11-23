# Turning the ring's kit into models with Propper++ (step by step)

The canal ring's Combine wall and the ruins beyond the canal are made of a kit of 35 pieces. Each piece is a small VMF
holding one piece of brushwork. Propper++, which is built into Hammer++, turns each into a model that keeps only the
faces players can see. The ring then places these models as props, so they cost no brushes and no brush faces in the
map's compile (the owner's compile stopped on "Too many detail brush faces, max = 65536", 23 November).

You do this once now, and again only if a piece's design changes. Moving the ring or changing the map never needs it.

## What you need

- Hammer++ (you already use it). Propper++ is in its Tools menu.
- The kit: `lc_propkit.zip` (the 35 VMFs). Unzip it anywhere, for example into `~/mapwork/propkit/`.
- Garry's Mod's own model compiler, `studiomdl.exe`, which comes with the game: in your install it is at
  `Z:\home\anon\.local\share\Steam\steamapps\common\GarrysMod\bin\studiomdl.exe`
  (that is `~/.local/share/Steam/steamapps/common/GarrysMod/bin/studiomdl.exe` on Linux; use the one in `bin`, not the
  one in `bin/win64`, as the Valve wiki warns the 64-bit one does not work in some branches).

## Once: tell Hammer++ where the compiler is

1. In Hammer++: **Tools > Options > Build Programs**.
2. Set **MDL executable** to the `studiomdl.exe` above (Browse, or paste the `Z:\...` path).
3. OK.

## For each of the 35 pieces (about a minute each)

1. **File > Open** the piece's VMF (for example `lc_cwall_512_a.vmf`). It shows one piece of Combine wall or one ruin.
2. Press **Ctrl+A** to select everything (it is one entity).
3. Press **Ctrl+Shift+P** (or **Tools > Propper++**). The Propper++ window opens.
4. The first time only, set these (Hammer++ remembers them for the next pieces; glance at them each time):
   - **Model Path + Name:** `lc/kit/$vmf`
     (`$vmf` is replaced with the open file's name, so this piece becomes `models/lc/kit/lc_cwall_512_a.mdl`; the ring
     looks for exactly those names, so do not change it).
   - **Add incremental suffix if already existing MDL name is found:** OFF (a recompile then replaces the old model
     instead of making `_0`, `_1` copies the ring would not find).
   - **Source file directory:** `modelsrc/lc/kit`
   - **Material path:** `models/lc/kit`
   - **Entity name as physics mesh:** EMPTY (delete whatever is there). The models get no collision; the map keeps the
     wall solid with its own brushes and an invisible clip, and nobody can reach the ruins.
   - **Relocate materials:** ON. This matters: it puts the model copies of the materials in `materials/models/lc/kit/`
     so they can never replace the brush materials your map's walls use.
   - **Rename shaders:** ON.
   - **Remove $bumpmap/$phong:** ON.
   - **Skip nodraw faces:** ON. Every face nobody sees is already nodraw in the kit, so this is what deletes them.
   - **Generate atlas / Bake AO:** OFF.
   - **Create entity after compile:** ON (it lets you check the first piece, below).
   - The rest as they are.
5. Press **Build + Compile**. A compiler window runs for a few seconds. If it stops with an error, copy its text and send
   it to me.
6. **On the very first piece only:** look at where the new model stands. It should sit exactly where the brushes were,
   facing the same way (Propper++ moves the brushes into a hidden visgroup named "Propper"; the model is what you see
   now). If it came out turned or moved, stop and tell me: the ring places every piece the same way, so it must be right
   before you do the rest.
7. Close the piece without saving (nothing in it needs saving) and open the next one.

The pieces: `lc_cwall_512_a`, `lc_cwall_512_b`, `lc_cwall_640_a`, `lc_cwall_640_b`, `lc_cwall_768_a`, `lc_cwall_768_b`,
`lc_cwall_896_a`, `lc_cwall_896_b`, `lc_cwall_1024_a`, `lc_cwall_1024_b`, `lc_cwall_pier`, `lc_cwall_corner`, and the
ruins `lc_ruin_block_a` to `_g`, `lc_ruin_house_a` to `_f`, `lc_ruin_shell_a` to `_f`, `lc_ruin_collapsed_a` and `_b`,
`lc_ruin_wall_a` and `_b` (the kit's `README.md` lists all 35 with their sizes).

## Where the results go

- Models: `GarrysMod/garrysmod/models/lc/kit/` (each piece as `.mdl` with its `.vvd` and `.vtx` files).
- Their materials: `GarrysMod/garrysmod/materials/models/lc/kit/`.
- The compiler's sources: `GarrysMod/garrysmod/modelsrc/lc/kit/` (only for recompiling; never ship these).

## Then

1. Compile the ring's test map as usual, with two extra settings for VRAD (the light compile): `-StaticPropLighting`
   and `-StaticPropPolys`. Without the first, each model is lit from a single point that may sit inside the wall, so long
   wall runs come out flat or dark; the second lets the models cast proper shadows. (If you compile from a command line,
   add them after `vrad.exe`; in Hammer++'s Run Map dialog, Expert mode, add them to the $light_exe line's parameters.)
   The models must be in place before you compile: vbsp drops any prop whose model it cannot find.
2. For the server and the players, the models and their materials ship like the other content: copy
   `garrysmod/models/lc/` and `garrysmod/materials/models/lc/` into the server's `garrysmod/` folder (not into
   `addons/`, which FastDL never looks in), and add them to your FastDL or Workshop content.
3. The tops of the wall and the roofs of the ruins are left out, because nobody on the street or in the canal can see
   them. If you later stitch City 18 in and its upper windows look down on them, tell me: the kit can be rebuilt keeping
   them (`map_propkit.py --keep-tops`), and you recompile.
4. If a piece looks wrong in game (a face missing that should be there, or one showing that should not), tell me which
   piece and from where; I change the kit and you recompile only that piece.
