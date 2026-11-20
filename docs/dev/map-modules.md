# Writing a canal module (`_dev/tools/map_modules.py`, `map_mods_*.py`)

What a module is, and how the owner uses them, is in `docs/dev/map-building.md` ("Canal modules"). This page is for whoever writes one. Nobody can compile here: the checks and the pictures are all there is before the owner's compile, so use both.

## The loop

```bash
cd _dev/tools
python3 map_build.py module                                   # the list
python3 map_modules_check.py --only NAME --views /some/folder # builds it 9 ways, then draws it: NAME_sheet.png
python3 map_view.py lc_mod_NAME.vmf --eye X Y Z --yaw A --pitch P --out a.png   # one more look, from anywhere
python3 map_view.py lc_mod_NAME.vmf --iso SW --cut 560 --out b.png              # from above, nothing drawn over z 560
python3 map_build.py module --name NAME && python3 map_assets.py lc_mod_NAME.vmf  # is every model and material real, and the right kind?
```

Look at the pictures every time (`map_view.py` draws brushes in flat colours, props as boxes of their true size, light roughly: `docs/dev/map-view.md`). A build also prints `LOOK:` lines for props that reach into a wall, stand taller than the roof over them or lie under the floor: clear them. A module is done when the check passes all ways, `map_assets.py` passes, there are no `LOOK:` lines left unexplained, AND the pictures show what was meant.

## Where a module lives

A function `m_NAME(m, opt)` and a row in a `MODULES` dictionary: `"name": (length, m_NAME, "what it is, one line")`. New ones go in their own file, `map_mods_a.py` to `map_mods_d.py`, which `map_modules.py` picks up by itself:

```python
from map_build import CELL, GATE_HIGH, MAT, prism, octagon
from map_modules import F, TRIM, BASE, SEWER, MM

def m_example(m, opt):
    """One paragraph: what is there, and what is named for the game."""
    m.open(0, -256, 1024, 256)            # the canal itself, the module's whole length
    ...

MODULES = {"example": (1024, m_example, "what it is")}
```

`opt` is the words after the name on a layout line (`["1280", "flip"]`).

## Coordinates and heights

- `u` runs along the canal from the module's entry (0) to its exit (its length); `v` across it. The canal is `v` -256 to 256. **`+v` is the left bank** walking along `u`. Yaws: 0 looks along `u`, 90 to the left, 180 back, 270 to the right. The frame turns all of it into the map's, any of four ways and flipped, so never write a map coordinate yourself.
- `F` 400: the canal's floor. `TRIM` 656: the trim line on the walls, and the height of streets carried over. `m.b.rim` (784 by default): where the walls' concrete ends, with a fence on it. `m.b.sky`: the sky's lid (rim + 384). `BASE` 224: the bottom of everything; `SEWER` 288: the city's sewers.
- A player is 32 wide, 72 high standing, 36 crouched, steps up 18, jumps about 56, walks slopes up to 45 degrees. Eyes are 64 over the floor.
- A module's length and everything painted must be multiples of 64. A module must start and end with the full canal: `m.open(0, -256, L, 256)` or the same in pieces, so the cross-section at `u` 0 and `u` L is the plain canal at floor `F`.
- Stay inside `u` 0 to L. Side rooms go out in `v`: `+v` by habit, so `flip` in a layout can put them on the other bank.

## Squares (what seals the map)

The plan is squares of 64, seen from above. Paint them and the walls, floors, roofs and sky come by themselves, sealed by construction.

- `m.open(u1, v1, u2, v2, floor=F, mat=None)`: open to the sky.
- `m.low(u1, v1, u2, v2, ceil, floor=F, mat=None)`: under a roof at `ceil` (solid concrete above it up to the rim).
- Anything not painted is solid or nothing. A pillar is squares left unpainted in the middle of a room, or taken back out with `m.unpaint(u1, v1, u2, v2)`.
- **A square's floor can be at any height.** Higher than `F` beside the canal: the dressing treats it as a wall and puts a 45 degree bank against it, which makes a walkable ramp up to a platform 128 high (the relay's pier, the checkpoint's platform). Higher than 128: build stairs (`m.steps`).
- `m.side(u1, v1, u2, v2)`: tell the mud to stay out of a side room. Call it for everything that is not open canal.
- Painting a square another module painted is a PROBLEM the tool reports.

What the dressing adds afterwards, to every module at once: sloped banks along every canal wall (128 out, 128 up), a trim line and ribs, drain stubs, mud on the floor, the fence on the walls' tops, path nodes on every other square. To keep it away from something:

- `m.no_bank(u1, v1, u2, v2)`: no bank where this rectangle covers the wall's line.
- `m.taken(u1, v1, z1, u2, v2, z2)`: a box on a wall that ribs and stubs must keep 24 clear of.
- `m.blocked(u1, v1, u2, v2)`: no path node here (a hut, stairs, a pit). `m.lane(u, v, z=F)`: one path node exactly here (on stairs, through a doorway).

## Brushes that are detail (no sealing: free to overlap, any size on the 1-unit grid)

- `m.det([(u1, v1, z1, u2, v2, z2), ...], material, top=None)`: boxes. Walls of huts, slabs, counters, railings, beams.
- `m.shapes([faces, ...])`: anything convex that is not a box, from `prism(profile, "x" or "y", a, b, material)` (a flat outline, as `(across, up)` points, pushed along `u` for "x" or along `v` for "y") or `octagon(c, up, r)` for a pipe's outline. Every corner must be a whole number. A tilted or leaning thing is a prism with a sheared outline, never a rotation.
- `m.steps(start, lo, hi, z_low, z_high, "u" or "v", +1 or -1)`: stairs, 8 up and 12 along; returns their run.
- `m.bridge(a, b, lo, hi, far_pier=True)`: a street carried over at the trim's height. `m.hut(u1, v1, u2, v2, z, material, high=112, front="lo"|"hi", open_front=False)`: a shack.
- `m.bars(slab, "u"|"v")`: bars nobody fits between (with an unseen wall in them).
- `m.world(box, material)`: a brush of the WORLD, which seals: only for a cap across an opening.
- `m.water(u1, v1, u2, v2, z1, z2, mat=None)`: standing water; `MM["sludge"]` for slime. Never across an areaportal.

Materials: `MAT` (canal_wall, canal_floor, quay_floor, ceiling, stairs, beam, bars, black, fence, mud, nodraw, clip, trigger) and `MM` (wood, tin, steel, beam_wood, water, sludge). Others known to be in the owner's map: `metal/metalcombine002`, `metal/citadel_metalwall077a`, `metal/metalduct003a`, `brick/brickwall045d`, `brick/brickwall037a`, `plaster/plasterwall042c`, `tile/tilefloor018a_c17`, `stone/stonewall040f`, `stone/stonefloor006d_c17`, `concrete/concretefloor016a`, `glass/glasswindow041a`, `nature/dirtfloor005c`, `wood/woodbeam001a`. Anything else is from memory: list it in the module's docstring as unchecked.

## Things

- `m.static(model, u, v, yaw=0, z=F)`, `m.loose(...)` (a physics prop), `m.dynamic(model, u, v, yaw, z, name=None)` (any model; may be named), `m.body(model, u, v, yaw, z)` (a ragdoll), `m.scatter(u1, v1, u2, v2, n, seed)` (odds and ends). **`z` is the floor the thing stands ON**: the tool reads the model's real size and lifts its origin as needed (many models have their origin at their middle). A model's size: `map_assets.size("models/...mdl")`, a box from its origin with x forward.
- `m.light(u, v, z, "R G B brightness")`, `m.lamp(u, v, z, colour, hang=0)` (a housing, a glow and the light), `m.spot(u, v, z, colour, yaw, pitch=60, cone=40, name=None)` (a beam), `m.glow(...)`. No flickering lights (the owner disliked them). A lamp of brightness 40 to 70 lights a room; 100 and over is a fire or a floodlight.
- `m.sound(message, u, v, z, radius=1100, volume=7, name=None, on=True)`, `m.decal(texture, u, v, z)` (the point ON the surface), `m.rope([(u, v, z), ...], slack=40)`, `m.smoke(u, v, z)`, `m.spark(u, v, z)`, `m.cubemap(u, v)`.
- `m.ladder(u, v, z0, z1, out)`: a real ladder, pieces of 128.
- `m.point(classname, u, v, z, {keys}, connections=[(output, name, input, value, delay)])` for anything else. Angles in keys: `"0 %d 0" % m.fr.yaw(a)`.

**Which models:** any model of Half-Life 2, Episode One or Lost Coast that `map_assets.py` passes. Find names in the lists it keeps: `grep -i bench _dev/tools/dl/ValveQCs.txt | grep source/hl2/` (materials: `ValveVMTs.txt`). It fails a `prop_static` whose model was not built to be static (use `m.dynamic` or `m.loose`), and notes Episode Two's models (players without it see an error: use them only when nothing else will do). Sounds cannot be checked: say "Unchecked:" for each in the docstring.

## Things that move or are named for the game

- `m.door(name, boxes, material, movedir, speed=40, lip=8)`: a brush that slides when told (Open, Close), never by a player's Use. `movedir` "-90 0 0" is up, "90 0 0" down; sideways is `"0 %d 0" % m.fr.yaw(a)`.
- `m.button(name, u, v, z, out, wires, wait="1")`: a button players press, working in the map by itself: `wires` is `[(name, input, value, delay), ...]`. `m.relay(name, u, v, z, wires)`: a switchboard to Trigger.
- `m.ent(classname, {keys}, boxes, material)`: any other brush entity (`func_brush`, `trigger_multiple`, `func_breakable` ...).
- `m.target(name, u, v, z)`: a place for the game to find.
- `m.test_button(box, [(output, name, input), ...])`: a red button that exists only in `--test` files, to work by hand what the game will work later.
- **Names start `lc_` and say the module** (`lc_lock_gate_a`). A name used twice in one chain is a PROBLEM. Everything named is listed in the report: put what each is for in the docstring.
- A brush entity that turns needs `"origin": "%d %d %d" % (m.fr.pt(u, v) + (z,))` for its hinge.

## Areaportals (what keeps one place from being drawn while standing in another)

`m.portal(u1, v1, z1, u2, v2, z2)`: a sheet 2 thick across a doorway or tunnel into a side room. It must fill the opening from wall to wall and floor to roof, with open air on both faces and solid past all four edges (the check fails it otherwise), so it goes a little way INSIDE a tunnel, never at its mouth, never under the open sky, and never through water. A door that shuts an opening needs the portal inside its own thickness. Every roofed side room should have one in its way in.

## Pictures

`m.view(u, v, z, yaw, pitch=6, label="")` asks for a picture from where a player standing at `(u, v)` on a floor at `z` would look. One from the entry is taken for every module; add one for each thing worth seeing (inside each room, from a platform, down a pit).

## The house's rules that reach here

- Never an em dash, anywhere.
- No flickering lights; no stand-and-wait job steps designed into a place (a place can be held against attacks).
- Each side room: a way in a player can find, something to do or find there, a reason for the Resistance or the Combine to want it.
- What cannot be known without a compile (a model's size or facing, an entity from memory) goes in the docstring's last lines as "Unchecked: ...".
