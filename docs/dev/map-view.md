# Looking at a VMF without Hammer (`_dev/tools/map_view.py`)

The owner, 20 November: "Please make sure your vmf 3D viewer is available for other and future chats, very useful."

A chat cannot compile a map or open Hammer. This tool draws a VMF to a PNG so a chat can LOOK at what it built (or at a part of the owner's own map) before the owner spends a compile on it. Read the picture with the Read tool. It needs `pip install numpy pillow`; nothing else. It only reads.

```bash
cd _dev/tools
python3 map_view.py FILE.vmf --iso SW --out above.png                 # from above, looking from the south-west corner
python3 map_view.py FILE.vmf --iso NE --cut 560 --out open.png        # ...with nothing drawn above z 560: roofs off, to see into rooms
python3 map_view.py FILE.vmf --eye 1024 -700 464 --yaw 270 --pitch 10 --out inside.png   # as a player standing there would see it
python3 map_view.py c18_lc.vmf --iso SW --box 3000 1500 4500 3000 --out corner.png        # only what lies in a rectangle (a big map)
```

- `--eye X Y Z`: where the eyes are (a player's eyes are 64 over the floor). `--yaw`: 0 east, 90 north. `--pitch`: degrees DOWN (negative looks up). `--fov` 90.
- `--iso NE|NW|SE|SW`: the corner looked from. `--cut Z`: a cut-away. `--box X1 Y1 X2 Y2`. `--size W H` (1280 800).
- From Python: `map_view.render(path, out, eye=..., yaw=..., pitch=..., iso=..., cut=..., box=..., size=..., title=...)` and `map_view.sheet([pictures], out)` to put several on one page.

**What it draws:** every brush face from the file's own corner lists (Hammer++'s `vertices_plus`; a file without them has its corners worked out from the planes), displaced ground, brush entities; tool textures (sky, nodraw, clips, triggers, areaportals) are left out, so an open-topped place shows the sky. Flat colours by material name (concrete grey, wood brown, Combine metal blue, water blue, slime green, chain link and force fields see-through), a dark line where two faces meet.

**Props and other things:** a model whose size is known (`asset_facts.json`, made by `map_assets.py`) is drawn as its own box, turned as it stands: orange a `prop_static`, yellow a `prop_physics`, cyan a `prop_dynamic`. Bodies are flat red boxes, NPCs green, lights small pale cubes, anything named `lc_...` for the game magenta. A model of unknown size is a post.

**Light, roughly:** where nothing is overhead, the sun; under a roof, only the file's own `light` and `light_spot` entities (no shadows are cast, so light goes through walls). Good enough to see that a room is dark or which lamp does the work; not the game's lighting.

**What it is not:** the game's look. No textures, no models, no shadows, no fog. A thing that looks right here can still be wrong in the game; a thing that looks wrong here IS wrong.

## With it: is every model real? (`map_assets.py`)

```bash
python3 map_assets.py FILE.vmf [more.vmf ...]
```

Checks every model and material a VMF names against the decompiled build files of Valve's own models (`github.com/Pinsplash/ValveQCs`, `ValveVMTs`: reachable from a chat at `raw.githubusercontent.com` and by `git clone`): that it exists in Half-Life 2 or its episodes, that a `prop_static`'s model was built to be static (else the compiler silently leaves it out), that a `prop_physics` has physics data, that a ragdoll has joints, and notes what is Episode Two's. The first run fetches the two lists of file names into `_dev/tools/dl/` (not kept in the repo); what it learns about each model, its size too, is kept in `_dev/tools/asset_facts.json` (in the repo), so builds and pictures know models' sizes with no network. `map_assets.size(model)` gives a model's box from its origin. Sounds cannot be checked: there is no list.

## Where it is used

`map_build.py module --name X --views FOLDER` and `chain --layout F --views FOLDER` take a standard set of pictures (from above, roofs off, and each view a module asks for with `m.view`) and put them on one sheet; `map_modules_check.py --only X --views FOLDER` does the same after checking. `docs/dev/map-modules.md` is the guide to writing a module with them.
