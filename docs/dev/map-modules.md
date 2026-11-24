# Writing a canal module (`_dev/tools/map_modules.py`, `map_mods_*.py`)

What a module is, and how the owner uses them, is in `docs/dev/map-building.md` ("Canal modules"). This page is for whoever writes one. Nobody can compile here: the checks and the pictures are all there is before the owner's compile, so use both.

## Read the lessons first

`python3 map_lessons.py --tag KIND` prints what the owner has corrected before for that kind of thing and how City 18 does it (the database: `_dev/reference/lessons.json`; the reference with 30 pictures of their map: `docs/dev/city18-reference.md`). Add a lesson whenever the owner corrects a piece.

## The loop

```bash
cd _dev/tools
python3 map_build.py module                                   # the list
python3 map_modules_check.py --only NAME --views /some/folder # builds it 9 ways, then draws it: NAME_sheet.png
python3 map_view.py lc_mod_NAME.vmf --eye X Y Z --yaw A --pitch P --out a.png   # one more look, from anywhere
python3 map_view.py lc_mod_NAME.vmf --iso SW --cut 560 --out b.png              # from above, nothing drawn over z 560
python3 map_build.py module --name NAME && python3 map_assets.py lc_mod_NAME.vmf  # is every model and material real, and the right kind?
python3 map_floating.py lc_mod_NAME.vmf                        # does any prop touch nothing (floating)?
python3 map_lint.py lc_mod_NAME.vmf                            # the owner's corrections by machine (every build prints these as LOOK lines too)
```

Every build also runs the stair check (`map_stairs.py`: headroom, a way off at the top and on at the foot) and the walk check (`map_walk.py`: every `lc_` spot, door and button a player can reach on foot, by ladder or riding a lift, no prop cutting a walk in two); a fault in either fails the build. Both run on any VMF by hand too (the owner, 22 November: "over half the stairs just go into walls").

**Pictures cost usage to read (the owner asked for restraint, 20 November):** pass the checks first, then read ONE small picture of a new module (`map_view.py ... --size 800 520`), and another only if something in it is in doubt. Do not use `--views` sheets as a routine.

A picture when you do look (`map_view.py` draws brushes in flat colours, props as boxes of their true size, light roughly: `docs/dev/map-view.md`). A build also prints `LOOK:` lines for props that reach into a wall, stand taller than the roof over them or lie under the floor: clear them. A module is done when the check passes all ways, `map_assets.py` passes, there are no `LOOK:` lines left unexplained, AND the pictures show what was meant.

## Where a module lives

A function `m_NAME(m, opt)` and a row in a `MODULES` dictionary: `"name": (length, m_NAME, "what it is, one line")`, with a fourth part `{"stretch": True}` for any length or `{"width": (1024, 1024)}` for a wide one. New ones go in their own file, `map_mods_a.py` to `map_mods_e.py`, which `map_modules.py` picks up by itself:

```python
from map_build import CELL, GATE_HIGH, MAT, prism, octagon
from map_modules import F, TRIM, BASE, SEWER, MM

def m_example(m, opt):
    """One paragraph: what is there, and what is named for the game."""
    m.open(0, -256, 1024, 256)            # the canal itself, the module's whole length
    ...

MODULES = {"example": (1024, m_example, "what it is")}
```

`opt` is the words after the name on a layout line (`["1280", "flip"]`). A layout line `close` ends the chain with no gate (its last module closes the canal, as `roadend` does). A module can set `b.replaces` (ids of the owner's brushes it stands in the place of), `b.allow` (boxes round its gates where a joined piece's walls may overlap its own: both solid) and `b.stoppers` (boxes stopping up an opening meant to join the owner's map, for the seal check only). `map_mods_f.py` holds the ring's own (`roadend`, the church).

## Coordinates and heights

- `u` runs along the canal from the module's entry (0) to its exit (its length); `v` across it. The canal is `v` -256 to 256. **`+v` is the left bank** walking along `u`. Yaws: 0 looks along `u`, 90 to the left, 180 back, 270 to the right. The frame turns all of it into the map's, any of four ways and flipped, so never write a map coordinate yourself.
- `F` 400: the canal's floor. `TRIM` 656: the trim line on the walls, and the height of streets carried over. `m.b.rim` (784 by default): where the walls' concrete ends, with a fence on it. `m.b.sky`: the sky's lid (rim + 384). `BASE` 224: the bottom of everything; `SEWER` 288: the city's sewers.
- A player is 32 wide, 72 high standing, 36 crouched, steps up 18, jumps about 56, walks slopes up to 45 degrees. Eyes are 64 over the floor.
- A module's length and everything painted must be multiples of 64. A module must start and end with the full canal: `m.open(0, -256, L, 256)` or the same in pieces, so the cross-section at `u` 0 and `u` L is the plain canal at floor `F`.
- **The wide canal** (Valve's airboat canals, `map_mods_e.py`): `widen` takes the canal from 512 to 1024 in two steps, `narrow` brings it back, and between them only wide modules (`v` -512 to 512 at both ends: `wide`, `widetee`, `lockgate`; a turn there is 1024 square). A chain whose widths do not meet, or that ends wide, is a PROBLEM; a wide module built alone (`module --name wide`) gets a widen and a narrow round it by itself (`alone()`). `basin` widens and narrows within itself, so it goes anywhere. `map_layouts/wide.txt` uses them all.
- **Never write `m.fr.pt(u, v) + (z,)`: write `m.fr.at(u, v, z)`.** A module can be built lifted to the street (`NAME up` in a layout: `map_corridor.py`), which moves everything in it 768 out and 256 up through the frame; a height added by hand is not lifted. `m.fr.box(...)` and every `m.` helper are safe.
- Stay inside `u` 0 to L. Side rooms go out in `v`: `+v` by habit, so `flip` in a layout can put them on the other bank.

## Squares (what seals the map)

The plan is squares of 64, seen from above. Paint them and the walls, floors, roofs and sky come by themselves, sealed by construction.

- `m.open(u1, v1, u2, v2, floor=F, mat=None)`: open to the sky.
- `m.low(u1, v1, u2, v2, ceil, floor=F, mat=None)`: under a roof at `ceil` (solid concrete above it up to the rim).
- `m.open(..., sky=Z)`: open to a sky of its own, higher than the chain's (the church's yard): the builder raises a column of sky on every square round it, so keep such a place walled in. Neither the fence nor the canal's dressing touches it.
- `m.cellar(u1, v1, u2, v2, floor, ceil, upper, mat=None, upper_mat=None, sky=None)`: a room from `floor` to `ceil`, a slab to `upper` (the floor of what is over it), air above to the sky (its own `sky` or the chain's): a basement under a building, a tunnel under a yard.
- Anything not painted is solid or nothing. A pillar is squares left unpainted in the middle of a room, or taken back out with `m.unpaint(u1, v1, u2, v2)`.
- **A square's floor can be at any height.** Higher than `F` beside the canal: the dressing treats it as a wall and puts a 45 degree bank against it, which makes a walkable ramp up to a platform 128 high (the relay's pier, the checkpoint's platform). Higher than 128: build stairs (`m.steps`).
- `m.side(u1, v1, u2, v2)`: tell the mud to stay out of a side room. Call it for everything that is not open canal.
- Painting a square another module painted is a PROBLEM the tool reports.

What the dressing adds afterwards, to every module at once (`finish`, Valve's Route Kanal measured, the owner 21 November): sloped banks along the city canal's walls (128 out, 128 up); a trim line and a rib every 512; Valve's drain outfalls (a canal_cap001 ring round a dark hole 128 across, flush with the wall, in pairs 384 apart either side of every other rib, a stain under each: in an upright wall centred 140 up over Valve's lip, a block 32 out with its top at 45 degrees; where a bank is, as Valve puts theirs over a slope, the ring's foot on the bank's top edge, centred 206 up, the trim stopping either side); a caged lamp every 768 along each wall at 300 up, the walls facing each other taking turns, one in three dead (no light), each lit one with its own light (`dress_canal_walls`); the floor dished (`dish_plan`: the concrete of every plain canal square no bank or thing stands on is lowered, and the mud over it sags 24 at a 512 canal's middle, 42 at a 1024's, rising to `F` at its edges, so modules still meet on the plain section; loose physics props and floor stains placed at `F + 1` are brought down onto the mud, anything else standing on the floor keeps the dish flat round it); the fence on the walls' tops; path nodes along the middle of every place people walk (`map_ring.lane_cells`: 128 apart in the open and in roofed halls, 64 in corridors and small rooms, none on banks), flying nodes for scanners about 150 apart and 160 over the floor, cover hints behind barriers, barricades and wrecks (`cover_hints`; the first canal, the ring and Ravenholm have them too, `piece_cover_hints`, in what is left of their shares), and a path link controller across every gate (`link_gates`: the gate's OnFullyOpen turns it on, OnClose off; the forests' gates and the bunker's room doors have them too), all thinned until the piece fits its share of the engine's 4096 path nodes (`map_build.NODE_SHARES`: City 18 has about 2406; every build prints the count and a LOOK when a piece is over its share; `map_merge.py` fails a merged map over 4096). The ring and the first canal have the same dressing (`dress_piece`). To keep it away from something, or change it:

- `m.no_bank(u1, v1, u2, v2)`: no bank where this rectangle covers the wall's line (nor trim, ribs, outfalls or lamps).
- `m.street_side()`: +1 if the chain's street runs along the module's left bank, -1 its right, 0 with none (or the layout line says `nostreet`). A room on that bank passes under the street only with its roof at 640 or lower; a side way on it reaches beyond the street with `side_gate_reach(m, side, reach)`; a bridge landing on it adds a box to `m.b.edge_gaps` (no parapet there), and so does any walk, deck, landing, gantry or stair head of the module at the street's height by the canal's edge (a world rect over the edge line, `m.fr.rect(u1, s * 236, u2, s * 284)`, opening each square of 64 along the canal whose middle it holds). Nothing of the module stands on the railway or the road, or hangs on the wall over the canal's edge above 656 (the wall ends there); a bridge across the canal leads somewhere a player can go (lesson `owner-street-meets-modules`). Under a shed (`NAME shed` in the layout) the street's edge is the shed's brick wall instead.
- `m.upright(u1, v1, u2, v2)`: the wall stands upright here as Valve's do (the wide canal): no bank, the rest of the dressing as ever.
- `walk_ledge(m, u0, u3, s, wide=False, stairs=2)`: a walk along one wall (`s` 1 the left, -1 the right): 72 wide and 208 up (wide: 102 at 320), the city's handrail on it, stairs at its start (and end, or a rail across it), lamps over it; the city canal's bank stops either side in a slope (`bank_hip`). Plain stretches from 1536 long have one on the left (`flip`: right, `noledge`: none); so do `drain`, `overflow` and `boathouse` on the right, and `wide` from 2048.
- `m.taken(u1, v1, z1, u2, v2, z2)`: a box on a wall that ribs and outfalls must keep 24 clear of (lamps 8).
- `m.blocked(u1, v1, u2, v2)`: no path node here (a hut, stairs, a pit). `m.lane(u, v, z=F)`: one path node exactly here (on stairs, through a doorway).

**Valve's building craft is done to every face as the file is written** (`map_build.craft`, `docs/dev/valve-craft-notes.md`; 21 November): lightmapscale 8 on stairs, rails, ladders and bars, 64 on a face more than 1024 from every path node and on a displacement more than 256 from one, 32 on other displacements, 16 for the rest; the canal's concrete walls (`concretewall064a`) at texture scale 0.5, not 0.25; and every upright face's texture shifted so it starts at the wall's foot, where the floor in front of it is (the faces of one material in one plane that stand on each other count as one wall). Faces copied exactly from the owner's or Valve's maps are left as they were. `map_lint.py` checks the same (kinds `lightmap`, `scale`, `seam`); it also names rock, dirt and blends at 0.25 (Valve lays them at 0.5 to 2) and upright faces over 1024 at 0.25 (long walls). The owner settled the canal's own (22 November): the mud stays Valve's blend at 0.25, as City 18 lays its mud and dirt, and the fence stays Half-Life 2's chain link (City 18's, effects/metalfence007a, is Counter-Strike: Source's alone); `map_lint.OWNER_GROUND` and `OWNER_KEPT` keep the checks from naming them. Not done: 45 degree corners cut at 8 (Valve's chamfers), which needs the shapes changed one by one.

## Brushes that are detail (no sealing: free to overlap, any size on the 1-unit grid)

- `m.det([(u1, v1, z1, u2, v2, z2), ...], material, top=None)`: boxes. Walls of huts, slabs, counters, railings, beams.
- `m.shapes([faces, ...])`: anything convex that is not a box, from `prism(profile, "x" or "y", a, b, material)` (a flat outline, as `(across, up)` points, pushed along `u` for "x" or along `v` for "y") or `octagon(c, up, r)` for a pipe's outline. Every corner must be a whole number. A tilted or leaning thing is a prism with a sheared outline, never a rotation.
- `m.steps(start, lo, hi, z_low, z_high, "u" or "v", +1 or -1)`: stairs, 8 up and 12 along; returns their run.
- `m.bridge(a, b, lo, hi, far_pier=True, gaps=())`: a street carried over at the trim's height (`gaps`: openings in its side walls, `(a or b, v1, v2)`, where a ladder comes up). `m.hut(u1, v1, u2, v2, z, material, high=112, front="lo"|"hi", open_front=False)`: a shack.
- `m.bars(slab, "u"|"v")`: bars nobody fits between (with an unseen wall in them).
- `m.world(box, material)`: a brush of the WORLD, which seals: only for a cap across an opening.
- `m.water(u1, v1, u2, v2, z1, z2, mat=None)`: standing water; `MM["sludge"]` for slime. Never across an areaportal.

Materials: `MAT` (canal_wall, canal_floor, quay_floor, ceiling, stairs, beam, bars, black, fence, mud, nodraw, clip, trigger) and `MM` (wood, tin, steel, beam_wood, water, sludge). Others known to be in the owner's map: `metal/metalcombine002`, `metal/citadel_metalwall077a`, `brick/brickwall045d`, `brick/brickwall037a`, `plaster/plasterwall042c`, `tile/tilefloor018a_c17`, `stone/stonewall040f`, `stone/stonefloor006d_c17`, `concrete/concretefloor016a`, `glass/glasswindow041a`, `nature/dirtfloor005c`, `wood/woodbeam001a`. Anything else is from memory: list it in the module's docstring as unchecked.

## Things

**A thing is a prop, never brushes** (the owner, 20 November, of the first town: "you made cell doors out of brushes, but there is a whole selection of cell doors and prison bars from HL2 Nova Prospekt, and you made a loudspeaker out of brushes but there is literally a loudspeaker prop ... it literally looks like something from 1998"). Doors, bars, beds, tables, shelves, lamps, speakers, fences, railings, pipes, signs, machines: find the model (below) and place it. Brushes are for architecture: walls, floors, slabs, steps, frames, kerbs. A door the game moves keeps an unseen brush that does the moving, with the real door model parented to it.

- `m.static(model, u, v, yaw=0, z=F)`, `m.loose(...)` (a physics prop), `m.dynamic(model, u, v, yaw, z, name=None)` (any model; may be named), `m.body(model, u, v, yaw, z)` (a ragdoll), `m.scatter(u1, v1, u2, v2, n, seed)` (odds and ends). **`z` is the floor the thing stands ON**: the tool reads the model's real size and lifts its origin as needed (many models have their origin at their middle). A model's size: `map_assets.size("models/...mdl")`, a box from its origin with x forward.
- **Props as Valve dresses them** (`docs/dev/valve-prop-notes.md`, 21 November): all of these take `pitch=` and `roll=` to lean a thing or lay it down (it still stands on `z` by its turned box: a barrel on its side `roll=90`, the mattress `roll=180`). `m.loose` turns a thing set square 3 to 17 degrees off three times in five (Valve's physics props: 41% square), starts it asleep (spawnflag 1) and makes small junk debris players walk through (4); every prop whose model has skins that are only looks (drums, crates, containers, cars, radiators: `map_skins.py`, `model_skins.json`) gets a mix of them unless its keys name one; a small thing nobody names fades far off (under 24: 1024 to 1500; under 64: 1900 to 2500), unless its keys set a fade. Lamps never fade. The older pieces' helpers do the same (`map_build.dress_keys`, `loose_flags`, `loose_yaw`). Furniture stays a `prop_dynamic_override` (Valve's are physics props with motion disabled: the owner to decide).
- `m.light(u, v, z, "R G B brightness", falloff="fill")`, `m.lamp(u, v, z, colour, hang=0)` (a real fixture: a dome light flat on a ceiling at `z + 8`, or with `hang` a bell lamp on a rod that long), `m.spot(u, v, z, colour, yaw, pitch=60, cone=40, name=None, falloff="fill")` (a beam), `m.glow(...)`. **A lamp is lit as Valve lights each fixture** (`LAMP_RECIPES`, 21 November): its glow (light_glow03 at 0.75) at the bulb, a `light_spot` under it shining down (cone 60, inner 30; the dome's 9 under the bulb, Valve's 11 under the model) and a faint point light below that (Valve's 8 of 200). `colour` is still the brightness one plain point light would have had: the spot gets twice it, the faint light a sixth, so the floor under a lamp is brighter than before and the walls darker (to judge in the first compile). **Falloffs** are presets (`map_build.FALLOFF`, Valve's constant / linear / quadratic): `fill` 0/0/1 (a plain light, the default), `lamp` 500/0/1 (a lamp's spot), `cage` 20/0/1, `tube` 100000/100/1, `flood` 500000/0/1 (a floodlight that reaches far). VRAD makes a light its brightness at 100 units whatever the falloff, so a preset changes the reach, not the brightness there. No flickering lights (the owner disliked them). A lamp of brightness 40 to 70 lights a room; 100 and over is a fire or a floodlight.
- `m.sound(message, u, v, z, radius=1100, volume=7, name=None, on=True)`, `m.decal(texture, u, v, z)` (the point ON the surface), `m.rope([(u, v, z), ...])` (left out, slack and width are Valve's for the longest span: under 128 slack 50 width 1, to 1024 slack 100, longer 120 width 3; a wire meant to be taut names its own), `m.smoke(u, v, z)`, `m.spark(u, v, z)`, `m.cubemap(u, v)`.
- `m.ladder(u, v, z0, z1, out)`: a real ladder, pieces of 128.
- `m.soundscape(SCAPES[kind], u, v, z, radius)`: what the place sounds like (every module should name one). `m.grime(kind, u, v, z, seed)`: a decal from `GRIME` (stain, drain, trash, crack, poster, danger, graffiti, number, lambda, burn, puddle, grate, debris, police), the point ON the surface. `m.stair_side(start, run, v1, v2, z_low, z_high, sign)`: the open side of a flight made solid. Every stretch of canal gets caged lamps along its walls and stains under its outfalls by itself.
- `m.point(classname, u, v, z, {keys}, connections=[(output, name, input, value, delay)])` for anything else. Angles in keys: `"0 %d 0" % m.fr.yaw(a)`.

**What the compiler throws away (the owner's compile of the town, 20 November: almost nothing showed):** a model with `prop_data` is a physics prop, and vbsp DELETES it as a `prop_static` ("must be used on a dynamic entity"): tables, chairs, shelves, lockers, boards, pots, crates. `m.static` now places those as `prop_dynamic_override` by itself, and `map_assets.py` fails a file that has one as a `prop_static` or a plain `prop_dynamic`. Each is an entity the game must network: keep such clutter to what a place needs (about 60 a module at most). Also learnt there: an `env_fire` falls to the ground below it unless it is told not to (`fire(..., drop=False)` in a drum); the loose mattress lies on its back unless turned over (`mattress()`); a door that opens is the city's own in an opening fitted as the owner's (`map_town.real_door`, `door_hole`); a moving thing of Half-Life 2's moves on a `phys_hinge` (the playground's swings and roundabout).

**Which models:** any model of Half-Life 2, Episode One or Lost Coast that `map_assets.py` passes. Find names in the lists it keeps: `grep -i bench _dev/tools/dl/ValveQCs.txt | grep source/hl2/` (materials: `ValveVMTs.txt`). It fails a `prop_static` whose model was not built to be static (use `m.dynamic` or `m.loose`), and notes Episode Two's models (players without it see an error: use them only when nothing else will do). Sounds cannot be checked: say "Unchecked:" for each in the docstring.

## Things that move or are named for the game

- `m.door(name, boxes, material, movedir, speed=40, lip=8)`: a brush that slides when told (Open, Close), never by a player's Use. `movedir` "-90 0 0" is up, "90 0 0" down; sideways is `"0 %d 0" % m.fr.yaw(a)`.
- `m.button(name, u, v, z, out, wires, wait="1")`: a button players press, working in the map by itself: `wires` is `[(name, input, value, delay), ...]`. `m.relay(name, u, v, z, wires)`: a switchboard to Trigger.
- `m.ent(classname, {keys}, boxes, material)`: any other brush entity (`func_brush`, `trigger_multiple`, `func_breakable` ...).
- `m.target(name, u, v, z)`: a place for the game to find.
- More kinds of door and entity are in `map_mods_b.py`, to import: `slide_door` (a sliding door with its own wait and start), `swing_door` (a `func_door_rotating` with its hinge), `shape_entity` (a brush entity made of shapes that are not boxes), `vprism` and `vpipe` (standing prisms and pipes). `map_mods_d.py` has `use_door` (slides when a player uses it); `map_modules.py` has `chain_link(m, a, b, z, high)` and `pyramid(...)`.
- The button model (`m.button`) is Episode Two's mine lift button, the owner's own choice for the bunker: `map_assets.py` notes it on every module with a button. That note is expected.
- `m.test_button(box, [(output, name, input), ...])`: a red button that exists only in `--test` files, to work by hand what the game will work later.
- **Name signs** (the owner, 24 November): every module and turn of a chain built with `--test` (so the ring's walk map) has a trigger over its whole length, side rooms and street, and a `game_text` that keeps its name and its layout line on the walker's screen (`MORGUE    (morgue flip)`); `name_sign` in `map_modules.py`. Never in the real map. The first canal is not built of modules, so it has none.
- **Names start `lc_` and say the module** (`lc_lock_gate_a`). A name used twice in one chain is a PROBLEM. Everything named is listed in the report: put what each is for in the docstring.
- A brush entity that turns needs `"origin": "%d %d %d" % (m.fr.pt(u, v) + (z,))` for its hinge.

## Wiring the way Valve does (read before wiring anything; the owner, 21 November: "save it for use")

Measured in 34,753 entities and 7,711 outputs of 23 Valve maps; each rule is a lesson with Valve's keys and
examples (`python3 _dev/tools/map_lessons.py --tag logic`, the recipes in `docs/dev/valve-logic-recipes.md`). The
owner said go ahead (21 November): our tools follow them, with the helpers in `_dev/tools/map_wiring.py`, and every
build checks them (`map_lint.py`, kind `wire`). What does what:

- `m.sound` sets Valve's flags itself (`map_wiring.sound_flags`: 0 or 16 for a loop, 32 or 48 for a one-shot; `loops=`
  when the file's name doesn't say). The bunker's, the trains', the canal bells' and the quarter's sounds already did.
- `map_wiring.wheel(m, name, u, v, z, out, drives=[...], on_open=[...], on_closed=[...], lock_open=True)`: a valve
  players turn (the aqueduct's sluice and the pipes' steam valve are wheels now).
- `map_wiring.sleepy_timer(m, name, u, v, z, near_boxes, wires, low, high)`: a timer that only dresses a place (the
  underpass's dust, the sludge tunnel's gurgle). Timers that run the game (trains, the thumper) stay as they are.
- `map_wiring.trigger(m, name, boxes, wires, who=1)`: a trigger that names who touches it (ours all did already).
- Areaportals: the builder links each one to the solid door hanging in it (`Vmf.link_portal_doors`, as the file is
  written; a plain wooden door or a solid brush door, never one behind bars or glass, so a cell stays seen through).

- **Valves turn** (`valve-wheel-gate`): a wheel is a `momentary_rot_button` whose `Position` drives a
  `func_movelinear`'s `SetPosition`, so the gate moves as far as the wheel is turned; fully closed, it plays its lock
  sound and locks itself. Ours fire once on a press.
- **Doors work their areaportals** (`valve-portal-door`): a portal in a doorway names its door in `target`; a gate
  sends the portal `Open` on OnOpen and `Close` on OnFullyClosed. Ours start open (`StartOpen` 1) and nothing ever
  closes them, so a room behind a shut door is still drawn.
- **One-shot sounds are flagged not looped** (`valve-sound-flags`): an `ambient_generic` the wiring plays has
  spawnflags 48 (starts silent, not looped); 16 for a loop that waits for PlaySound and StopSound; 0 only for a loop
  that runs from the start. `m.sound` sets these itself (`map_wiring.sound_flags`); so do the forests', Ravenholm's,
  the street's and the lock gate's own sound helpers.
- **Timers sleep** (`valve-timer-asleep`): a `logic_timer` that only dresses a place starts disabled, with a random
  time, and is enabled while players are near (a `trigger_multiple`'s OnStartTouchAll and OnEndTouchAll). Ours run
  all day.
- **Triggers name who touches them** (`valve-trigger-who`): set spawnflags on every trigger (1 players, 2 NPCs, 8
  physics, 64 everything); on our shared server use OnStartTouchAll / OnEndTouchAll and `!activator`, never
  `!player` (it means player 1). A `trigger_once` fires for the first player only.
- **Every moving part has a sound** (Valve's rule, `docs/dev/valve-logic-recipes.md`, checks 9 and 10): a door, gate,
  lift, train or turning thing has its own (`noise1` / `noise2` on a door, `startsound` / `stopsound` on a
  `func_movelinear` or `func_water_analog`, `movesound` on a train, `message` on a `func_rotating`), or the wire that
  moves it plays one, or moves a part that has one (a counterweight goes with its lift). `map_lint.py` (kind `wire`)
  names any that move in silence, any areaportal naming a door not in the map, and any trigger that opens or shuts
  a portal (Valve's single player trick: on our server it hides a room from whoever is still in it).
- Also kept, as the owner asked: the **alarm**, the **switch that shows its state**, the **intact set swapped for a
  broken one** and the **door the map closes again when blocked** (`map_lessons.py --tag recipe`).

## Tripwires and turret rooms (`_dev/tools/map_security.py`; 21 November, not compiled yet, no module uses it yet)

Valve's Overwatch Nexus security (d3_c17_10b; lessons `valve-tripwire-turrets`, `valve-counter`), for Combine
strongholds. Owner-approved; turrets are the Overwatch's, so ask the owner where a room goes before placing one.

- `tripwire(m, name, a, b, room=None)`: a red laser (env_beam, Valve's 170 0 0, width 0.2) from `a` to `b` (u, v, z;
  level, along u or v), touched by players or NPCs but passed by the Combine's own (filter `lc_security_notcombine`:
  not npc_combine_s, npc_metropolice, npc_manhack, npc_cscanner, npc_hunter), with a backup trigger along it (the
  beam's touch can miss a runner). In a room it fires `lc_<room>_alarm`; alone, its own `<name>_alarm` (turns it
  off) and `<name>_arm` (on again).
- `turret_room(m, name, wires, lifts, pit=16)`: ground turrets on floor lifts (a pit 64 square, 64 deep; `pit` is
  the floor's thickness, the lining laid under it; 0 when the module painted the pit square 72 lower itself). A broken
  wire: lasers off, the alarm for 1.5 s, the turrets rise; each sinks when it sees no one (OnAreaClear); all sunk
  (counter `lc_<room>_rearm`, max = the lifts): the lasers come back. All dead (`lc_<room>_dead`): the room is off.
- `switches(m, name, rooms, count, u, v, z)`: a stronghold's control rooms; each switch sends `lc_<name>_switches`
  Add 1, and at `count` every room's `lc_<room>_off` fires.
- **The gamemode's side is the relays' names:** `lc_<room>_alarm` (the map fires it; its activator is who broke the
  wire, so the gamemode can block it for the Union's own players in its AcceptInput hook: the map cannot tell them
  apart) and `lc_<room>_off` (Trigger it to shut the room for good, as a control room switch would; the map fires it
  itself when every turret is dead).
- `python3 map_security.py check` writes a test room (`lc_security_test.vmf`: two wired doorways, two turrets, a red
  button that throws the switch) and checks it; `python3 map_security.py lint FILE.vmf` checks any file: a tripwire
  with no filter, a re-arm counter whose max differs from its lifts (or starts below it), a ground turret on no lift.

## Areaportals (what keeps one place from being drawn while standing in another)

`m.portal(u1, v1, z1, u2, v2, z2)`: a sheet 2 thick across a doorway or tunnel into a side room. It must fill the opening from wall to wall and floor to roof, with open air on both faces and solid past all four edges (the check fails it otherwise), so it goes a little way INSIDE a tunnel, never at its mouth, never under the open sky, and never through water. A door that shuts an opening needs the portal inside its own thickness. Every roofed side room should have one in its way in.

A gate across the open canal (`lockgate`, Valve's lock gates: no damage and never forced closed; in the last 0.6 s of each swing and 0.3 s after, a shove (`map_forest.shove`) pushes whoever is in a leaf's way out of it: shutting, across the gate line, upstream on the upstream side (harder) and downstream on the downstream side; opening, back into the recess the leaf comes to rest in, which it leaves 50 or more clear. Until 22 November they killed (damage 10000 and boxes on their leading faces; the owner, 21 November: "make the crush anything"); the owner's newer word replaces that: "considering how dying in the gamemode means a new character, yes just shove, not kill"): the portal stands in the leaves' own thickness, between quoins (world brushes the leaves' models overlap), under a sky brush that closes the gate line over the leaves (it looks like the sky it replaces), and is named for the wiring: the leaf sends it `Close` on OnFullyClosed and `Open` on OnOpen. Any other way past the gates (its passage round) needs a portal of its own, always open, or the two sides are one area and the gate's portal does nothing.

## Pictures

`m.view(u, v, z, yaw, pitch=6, label="")` asks for a picture from where a player standing at `(u, v)` on a floor at `z` would look. One from the entry is taken for every module; add one for each thing worth seeing (inside each room, from a platform, down a pit).

## The house's rules that reach here

- Never an em dash, anywhere.
- No flickering lights; no stand-and-wait job steps designed into a place (a place can be held against attacks).
- Each side room: a way in a player can find, something to do or find there, a reason for the Resistance or the Combine to want it.
- What cannot be known without a compile (a model's size or facing, an entity from memory) goes in the docstring's last lines as "Unchecked: ...".
