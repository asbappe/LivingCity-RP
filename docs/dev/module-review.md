# Module review: every map module through the viewer, against City 18

The owner, 20 November: "look through everything with the 3D viewer, a module at a time, and write changes needed or improvements possible to a document ... compare concepts, geometry, styles, and level design and artistic design to the city 18 map and improve based on that".

How each module was looked at: `map_modules_check.py --only NAME --views DIR` (built every way it can be, then a sheet of six pictures: from above, from above with the roofs off, and its own viewpoints at a player's eye), plus what it says it is (its docstring), what it is made of (props, materials, entities) and `map_floating.py`. The viewer draws brushes in flat colours and props as boxes of their true size, so a prop's look and facing are not judged here, only its size, place and company.

Each module below has: **Seen** (what the pictures show), **Fix** (wrong, should change), **Better** (would make it more like City 18 or a better place to play), and a rough **Weight** (small, medium, large work). Nothing here is built yet: this is the list to build from, the owner choosing.

## What City 18 does (read from the owner's map, c18_lc.vmf)

Counted in their map, and seen in two pictures of it (a street at y -980 and a flat at x -1380):

- **It is lit by many small fixtures, and a lot of them throw a beam.** 597 lights, 391 light_spot and 174 point_spotlight (a lamp you can see the cone of), 126 sprites. The commonest fixtures: the dome light (151), the lab fluorescent tube (149), the Combine light (75, on Combine places), the hanging lamp fixture (52), the cage light (47), the industrial bell (5), prison caged lights. **The modules light a room with one or two lamps; City 18 lights a room with several, and points some of them.**
- **Grime is laid on, not left out.** 249 info_overlays and 267 infodecals: stains (decalstain002a alone 26 times, and 001a, 005a, 010a to 014a), trash decals, plaster cracks, posters of Breen, danger signs, metal grates and speaker grilles painted on walls, wires, graffiti, the lambda spray, concrete debris. **The modules have almost none.** The tools have `m.decal` (an infodecal) but no overlay; an `m.overlay` (a stretched decal on any face, any size) is the first thing to add.
- **Every place sounds like itself.** 155 env_soundscapes (and only 41 ambient_generics). **The modules use a single ambient_generic or two and no soundscape.** Each module should name a Half-Life 2 soundscape for itself (the canals' own: `d1_canals.*`, `streets.*`, `prison.*`, `coast.*`), and the town its own.
- **Buildings are massed, not boxed.** Stepped blocks with setbacks, chamfered (cut) corners and octagonal columns, plinths a step high, deep reveals round doors and windows, a trim line at every floor, overhangs and canopies, garage and shop fronts. Walls are the commonest concretes and bricks (stonewall050f as trim 953 times, concretewall008a 873, 059e 734, 036a 486, brickwall014l 473, brickwall045d 385, plasterwall041a/047b/042c inside).
- **Flats inside:** plaster walls split by a dado line (two tones), wooden floors, door casings that stand proud of the wall, a long hall with doors off it; stoves, sinks, toilets, fridges and iron bunks backs to the wall; radiators; fluorescent tubes on the ceiling.
- **Pipes run along walls and ceilings.** pipe02 straight and connector pieces (127 together), pipe sets (pipeset32d, pipeset08d, pipeset02d), gutter pipes down fronts (gutter_704 and others), prison pipes. **Most module walls are bare concrete.**
- **Doors are real.** 134 prop_door_rotating (door01_left, opening 50 by 110). 42 func_door, 20 func_door_rotating, 15 func_movelinear for the big things.
- **Streets:** 416 between the fronts, a cobbled crown, kerbs of 8 or so, pavements in a large tile grid; lampposts, benches, payphones, dumpsters, Combine fences; the commonest street sign is the route sign.
- **Optimisation:** 62 func_areaportal and 41 func_areaportalwindow, 24 func_lod, 321 env_cubemap, info_lighting where props sit in odd light.

### What runs through nearly every module (so it is done once, in the tools)

Filled in as the review goes; the first ones are clear already:

1. **An `m.overlay` helper** and a pass of grime on every module: a stain where water runs down a wall, trash decals in corners, a crack or two, posters where people are, the lambda where the Resistance is, danger signs on Combine things.
2. **An `m.soundscape` helper** (env_soundscape with a radius) and a soundscape named in every module.
3. **More, smaller lights, some of them beams** (`m.spot` exists): a tunnel lit every 256, a room by two or three fixtures, the Combine's places by combine_light002a.
4. **Pipe runs** (`m.pipe_run(u1, v1, z, u2, v2)` from pipe02 straights and connectors, with caps) along walls and ceilings of the service places.

## The modules

### 1. drain (showroom 1): the storm drain junction, down to the sewers

**Seen.** From the canal: the drain's mouth on the left under a short arched roof, a round outfall pipe high on the right wall, the canal's far end barred, mud patches on the floor. Through the mouth: a long, straight, bare concrete tube with chamfered upper corners, dark floor, one lamp at the far end over a low wall. The chamber: a square sump of standing water inside eight handrails, two concrete inflow pipes in the side walls, a valve, a crate, a drum, a pallet, a bell lamp. Then a narrow stair down into the dark, a grate of four bar panels at the bottom.

**Fix.**
- The mouth tube is about 600 long with nothing in it and no light until the far end: in game it reads as a black corridor. A cage light (light_cagelight02_on, a light under it) every 192 to 256 along one wall.
- The inflow pipes are "dark inside" plugs: nothing comes out of them. Water should: a thin sheet of water falling from each into the sump (a func_water slab, or a falling-water material on a thin brush) and a splash sound at each.
- The stair down has no light at all: one at its foot, so the grate can be seen.

**Better.**
- City 18's service tunnels carry pipes: a pipe02 run along the mouth's upper corner, into the chamber and down the stair wall (a pipe_run helper, see the top).
- Grime: decalconcretedrain001a to 003a under the inflow pipes and the outfall, decalstain002a down the walls under the chamber's waterline, trashdecal04a in the corners.
- A lambda spray (decals/lambdaspray_1a) at the head of the stair: the Resistance's way into the sewers, as Half-Life 2 marks its routes.
- A soundscape (d1_canals.util_drips style, water and drips) instead of one loop.
- The sump: a ladder down into it and something worth finding at the bottom (a waterproof case, a supply cache the game can fill), so the room is more than a corridor.

**Weight.** small (lights, decals, soundscape), medium (falling water, pipes).

### 2. overflow (showroom 1): the spillway toward Ravenholm, behind a sluice plate

**Seen.** In the left wall a wide spillway, its apron stepping down into the canal, shut by a steel plate in a frame; two winches on a ledge above it; a red-lit cage lamp each side; driftwood, rubble, a pallet and two burnt bodies piled against the plate. Behind it a long, plain, dark channel to a cap, one small thing on its floor.

**Fix.**
- The red lamps are `light_cagelight02_off` with a red light under them: the model is dark while the light glows. Use the `_on` model (or keep `_off` and drop the light: a dead lamp is a fine story too, but not both).
- Behind the plate there is nothing: the channel is a plain box. It is the way to Ravenholm and should say so the moment the plate lifts.

**Better.**
- The channel as Ravenholm's threshold: Half-Life 2's own `ravenholmsign` model at its far end (it is in Valve's list), blood and handprint decals on the walls, a burnt car or cart, crows' sounds, a headcrab canister half through the roof, rags, a zombie torso (charple and zombie models), very low warm light from one broken lamp. A shallow strip of water down the channel's middle (it is an overflow).
- On the plate itself: rust and stain overlays, a painted warning (decalsigndanger001c, the owner's map uses it), "do not open" in the Combine's way: a combine_barricade or a padlocked chain (prison_padlock001a) across the winches.
- The winches drive the plate in the game's eyes: a button or lever beside them (the owner's lever models: props_c17/lever or the canal's own) so players can open it by hand, not only the game.
- A soundscape that grows uneasy near the plate (wind through the gap, distant zombies).

**Weight.** small (lamp model, decals), medium (the channel dressed as Ravenholm's edge, a lever).

