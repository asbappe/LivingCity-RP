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

### 3. shanty (showroom 1): the shantytown under a street bridge

**Seen.** The canal widens into a basin under a heavy, dark street bridge on two deep beams. Along the back a boardwalk with three shacks: a card room (a table, two chairs, a lamp), a trader's stall (a counter, shelves, a few jars), a bunk room. Under the bridge a hangout round a fire drum with chairs, a couch and a stove with its chimney pipe. A boat pulled up on the mud, dock poles, a notice board, a plank fence.

**Fix.**
- The shacks read as clean wooden boxes: each is a perfect rectangle of one wood, floor, walls and ceiling alike, no window. A shanty is the opposite: walls of mismatched sheets (corrugated tin, plywood, a door laid sideways, a tarp), roofs of tin sloping and overhanging on visible posts, gaps.
- The card room and the bunk room have no window and one lamp: inside they are closed brown boxes.

**Better.**
- Build each shack from pieces, not a box: brush walls in two or three materials per shack (wood planks, metal sheet, plaster salvage), roof sheets as thin tilted brushes overhanging 16 to 24, corner posts, and props on the walls: props_debris wood boards and metal panels nailed over gaps, an old door (door01_left as a wall panel, turned on its side so it is not mistaken for a real door), a tarp (cloth brush) over a doorway.
- A window in each shack: a hole with boards across, or a sheet of cracked glass (glasswindowbreak070a, the owner's map uses it).
- Light like a lived-in place: a string of bulbs on a cable between the dock poles and the bridge (a rope with lightbulb01a props or glow sprites every 48, the owner's map has 30 lightbulbs), a lantern in each shack, the fire's glow under the bridge.
- Washing on a line across the basin (a rope, cloth brushes hanging), crates and a cart outside the stall, a hand-painted sign over it, the lambda spray on the bridge pier, posters inside.
- The basin: the canal's water could fill it shallow (a dock to step from), with the boat floating, not pulled up on mud.
- When this is the Resistance's base: a radio table and a map board in the card room (the office the game shows), so the base is in a room, not only at the pole.

**Weight.** medium to large (the shacks rebuilt from pieces), small (lights, washing, signs).

### 4. vort (showroom 1): the vortigaunt culvert

**Seen.** A low culvert off the left wall, a pipe along its wall under the roof, two turns, tall dark brown slabs half across the last turn (the "hanging of strips"), then a chamber: smooth pale walls and ceiling, a ring of stones round a fire, a tripod with a pot over it, three mattresses for mats, shelves with jars on the back wall, a faint green glow.

**Fix.**
- The chamber's walls read as clean pale plaster: a room in a house, not a den at the end of a drain. Damp concrete or brick with water stains (decalstain002a, decalconcretedrain*), earth where it has broken through.
- The "hanging of strips" draws as a few thick planks from floor to roof: it hides the room like a fence. Thin strips (4 wide, 1 thick, uneven lengths, a hand's gap between) or a cloth brush with a material that has holes, ending a foot above the floor.
- The culvert is a bare grey tube with no light from the mouth to the turn: the walk in is a dark box. A green glow should leak round the turn (a dim green light at the turn, sprites) so players are drawn in.

**Better.**
- Make the chamber a cave the vortigaunts have dug into: one wall broken into earth and rock (rock models, nature/dirt materials, a slope of rubble), roots through the roof.
- The vortigaunts' things: bones (Half-Life 2's gibs and skull), antlion parts, bundles hung from a cord, a stack of firewood, the cooking pot steaming (env_steam: the owner's map has five), a ring of candles.
- The green glow made of several small green sprites near the floor and a point_spotlight of green on the back wall (a "vortessence" pool), not one sprite in the air.
- A soundscape of a fire and low hum.
- Gameplay: a place to heal (the game's medic) or trade with a vortigaunt NPC: an info_target for where an NPC vortigaunt stands, facing the fire.

**Weight.** medium (walls and the cave corner), small (glow, steam, strips).

### 5. checkpoint (showroom 1): the Combine checkpoint

**Seen.** A chicane of concrete barriers and Combine barricades, then a Combine wall across the canal in dark blue metal with buttresses and one gateway shut by a force field. From the wall's top: two massive slanted blocks (the battlements) either side of the gateway, mesh panels behind. Behind the wall a guard's platform with a cabin, the pen of chain link under the walk.

**Fix.**
- The picture "on the platform" (eye 1156 160 592) is solid blue: the eye is inside something. Either the cabin has grown over the place a guard stands, or the viewpoint is stale; check that a player can stand on the platform there.
- The guard's cabin is a brush box. Half-Life 2 has the Combine's own booths: `combine_booth_short01a` and `combine_booth_med01a`. Use one.
- The buttresses and battlements are brushes; Half-Life 2 has `combinebuttress` and the bunker shields (`combine_bunker_shield01a/b`) for a parapet. The slanted blocks on the walk are taller than a man and hide the canal from the walk they are meant to guard.
- The field has nothing making it: Half-Life 2's fields run between `combine_fence01a/b` posts (or `combine_emitter01`). Put the posts at the gateway's sides, the field between them (the owner's map has 12 of each post).

**Better.**
- The Combine's own railings on the walk: `railing_128/256/512` and the corner pieces, not the city's handrail.
- A camera (`combinecamera001`) over the gateway, a scanner (`combine_interface001` is there: give it a light and a beep), a `combine_smallmonitor001` and `combine_intmonitor001` in the booth, a `health_charger001` for the guards.
- Light it as City 18 lights the Combine: `combine_light002a` on the wall's face (the owner's map has 75), two point_spotlights sweeping (the searchlights could pan: a func_rotating or a logic timer turning them slowly).
- Overlays: Breen's poster (decal_posterbreen) on the wall's face, a police line decal across the pen, numbers (decalindustrialnumber) on the gateway.
- The queue: yellow lines on the floor (an overlay) and a pair of barriers making a single file to the gateway, so where to wait is shown, not told.
- A soundscape of the field's hum and distant radio chatter.

**Weight.** medium (booth, buttresses, posts, railings as props), small (lights, decals, camera).

### 6. ash (showroom 1): the ash outfall, trash and burnt corpses

**Seen.** High in the left wall a chute's mouth under a concrete hood, barred, with a steel tray. Under it a big smooth heap and a smaller one, both the canal's brown mud; garbage piles, bags and tyres on them; the burnt dead (drawn as red boxes) scattered over and above the heap; smoke rising.

**Fix.**
- The heap is the canal's mud (blendmuddirt): smooth and brown, it reads as a hill of earth, not of ash. It wants a grey-black surface: a dark concrete or dirt material blended toward black at its top, with burn decals (decals/burn01a to 03a) and soot.
- The bodies are dropped from heights above the heap (up to 96) and fall when the map starts; a few will lodge on each other or in the garbage piles. Place each on the heap's own surface: the heap is a sum of bumps the tool knows (`b.bumps`), so the height under any point can be worked out and the body put there.
- No way to the chute and no reason to look at it: the heap is scenery only.

**Better.**
- Make the chute work: now and then (a logic_timer, rarely) its grate tips, a burst of grey dust and a clatter, and a little more comes down (a func_door grate, an env_dustpuff or env_smokestack burst, a sound). It tells everyone where the Combine's dead go.
- Soot streaks down the wall under the chute (decalstain002a, the owner's commonest overlay), scorch marks round the heap's foot, flies (a soundscape with flies and a low wind).
- A painted biohazard or danger sign by the chute (decalsigndanger001c/001e, both in the owner's map) and a Combine number.
- For the game: the heap as a search spot (hold E to sift for scrap, the game's own search job), so the place has a use.

**Weight.** small (decals, sounds, bodies placed right), medium (the heap's material, the chute's event).

### 7. sludge (showroom 1): the sludge tunnel, a shortcut through the long way round

**Seen.** The canal loops out round a block (a long way, under a street, past a dumped container); a straight tunnel cuts across, a flat green slime floor wall to wall, three dome lamps in a row, planks on drums, crates, drums, a body. The loop: wide and mostly empty but for the container, a car and a few crates.

**Fix.**
- The tunnel is a perfect rectangular box with smooth walls and a flat green floor: from its mouth it reads as a lit green corridor. A culvert this long has a shape: a vaulted or chamfered roof, ribs every 128 (the canal's own), a ledge along one wall (broken in places, so the slime has to be waded somewhere).
- The five outfall pipes are lost: at the slime's face they are hard to see and nothing comes out. Slime should pour from two or three (a falling slime brush, toxicslime material), with a sound.
- The dome lamps make the tunnel evenly bright: the green should come from the slime (a dim green light low, sprites over the surface), with the roof dark between two caged lamps.

**Better.**
- Warning at both mouths, shown not told: a skull or biohazard sign (decalsigndanger), a gas mask hung on a nail, a chain across with a tin sign, a body that did not make it at the mouth.
- The slime surface broken up: drums half sunk and tilted (pitch and roll), a floating pallet, scum overlays at the walls' foot, bubbles (an env_bubbles or a small env_smokestack in green).
- The long way round should be worth taking: a ladder up to the street under the bridge (a real exit), a Combine camera watching the loop, the container open with something in it, a car half in the canal from the street above.
- A soundscape: slime gurgle and drips inside, the city's traffic outside.

**Weight.** medium (tunnel shape, ledge, pouring slime), small (signs, lights, debris).

### 8. cistern (showroom 1): the round tank, for the hive boss

**Seen.** Off the right wall a tall passage with a stair to a round settling tank 1536 across: dark water, a dry ledge round it, four plank walks out to a pale island under a grated shaft of daylight, a gallery with handrails all round 128 up, four square pillars, chains hanging, inflow pipes high up. Dim and blue, the island bright: a strong arena.

**Fix.**
- "Round" is a stepped outline of 64 squares: from above the wall is a staircase of corners, and inside the back wall is a sawtooth of small facets, each catching light differently. The wall wants to be truly round (or a clean 16 or 24 sided polygon): angled brush segments (`m.shapes` prisms) standing on the squares' line, the squares behind kept only to seal.
- The inflow pipes are dark plugs: water should fall from at least one into the tank (it is a settling tank), with its sound echoing.
- The gallery's 72 handrail pieces follow the stepped outline too, so they zigzag; on a true circle they become one smooth ring (or Combine railing pieces with corner pieces).

**Better.**
- Built for a blind boss that hunts by sound: loose things to throw for a distraction (buckets, cans, bottles as physics props on the ledge and gallery), metal grates on the ledge that ring when walked (a func_brush with a footstep material: metal grate), the chains clinking when touched. The game can listen for the sounds.
- Ways out under pressure: two ladders from the water to the gallery, a hatch and ladder up the daylight shaft to the street (an escape the boss can't follow).
- Light: caged lamps on the pillars (most dead, two working), the daylight shaft with dust motes (func_dustmotes: the owner's map uses them) and a light_spot straight down onto the island.
- Grime: water lines on the walls (an overlay band at the old water level), numbers on the pillars (decalindustrialnumber), algae at the waterline.
- Water with things in it: a floating plank, a drum, a body face down near the island (the boss's last meal).
- A soundscape of echoing drips and a low hum that the boss's own sounds play over.

**Weight.** large (the round wall and ring rail), medium (ladders, shaft exit, sound toys), small (light, grime).

### 9. underpass (showroom 1): the barnacle underpass

**Seen.** A long stretch of canal under a wide flat road deck, three plain square piers down the middle, six barnacles on the roof between them, a lorry jammed against a pier, a car, crates, the dead lying about, one lantern burning on the floor. By the right wall part of the deck has come down as a tilted slab, daylight down the hole, rubble, rebar.

**Fix.**
- The deck is one flat slab and the piers are plain square posts: an underpass reads by its structure. Girders across the deck every 256 resting on the piers' caps (a cap wider than the pier, chamfered as City 18's columns are), the piers themselves chamfered or octagonal.
- The barnacles hang where nothing warns of them. Under each, Half-Life 2's tell: bones and gibs on the floor, a dark stain (decalstain), a body half lifted. The dead are there but not under the barnacles.

**Better.**
- The road above: a rumble of traffic and a passing Combine APC in the soundscape, dust falling now and then from the broken edge (func_dustmotes or a small env_dustpuff on a timer).
- Gutter pipes down the piers from the road's drains (props_pipes gutter pipes, the owner's map has gutter_704), water dripping from them into puddles (decalborealispuddle001a).
- A road sign or a lamppost that came down through the hole with the slab (streetsign, lamppost03a_off on its side), the lorry's back open with crates spilled.
- Graffiti on the piers (decalgraffiti*), an old warning sign (decalsigndanger).
- The daylight hole as a light_spot straight down with dust in it, so the one bright place is a lure past the barnacles.

**Weight.** medium (girders, pier caps), small (bones, puddles, sounds, signs).

### 10. tram (showroom 1): the fallen tram bridge

**Seen.** Two stations face each other across the canal, each a hall with platforms either side of a track pit, square columns, dome lamps, benches, a wainscot band on the walls. Episode Two's crushed passenger car lies across the canal from the right bank up into the left station's mouth; the whole car stands in the right station. The bridge is gone but for stubs, one girder (the beam walk) and one sagging. (The viewer draws the cars as untilted boxes, so their lie is judged by numbers, not by the picture.)

**Fix.**
- The viewpoint "the car and the bridge" (eye 686 -60 464) is inside a prop's box: a debris pile has been put where the module's own view stands. Move the view (or the pile) so a player standing there sees the car.
- The stations are plain boxes with square posts: nothing says "station". City 18's station is the model to follow, and Half-Life 2 ships its pieces.

**Better.**
- Dress the stations with Half-Life 2's station kit (props_trainstation): `trainstation_column001` for the columns, `trainstation_arch001` over the platforms' ends, `ceiling_truss001a` and `ceiling_arch001a` under the roof, `light_128wallmounted001a` and `light_256ceilingmounted001a` for light, a `clock01` stopped on the wall, `trainstation_post001` posts, `light_signal001a` at the pit's end, `bench_indoor001a` (the owner's map has 16), `payphone001a`, `trashcan_indoor001b`.
- The walls in the station's own materials: building_template / trainstation templates the owner's map uses (building_trainstation_template002o, window001a/b), tile floors (tilefloor018a_c17), a platform edge stripe.
- Overlays: a route sign on each platform (decal_signroute*, the commonest street sign in the owner's map), a Breen poster, timetable posters, a "no entry" over the barred stair.
- Overhead line wires across the canal from the stubs (ropes), one snapped and hanging into the water, sparking now and then (env_spark on a timer).
- The car: a sound of creaking metal, a few seats spilled out of its open end, glass on the floor (decals), a light flickering inside it is not allowed (no flicker), so a dead light instead.
- A soundscape of wind through the gap and a distant train (the street's train passes somewhere above).

**Weight.** medium (the station kit), small (overlays, wires, sounds).

### 11. tenement (showroom 2): a tenement block fallen across the canal

**Seen.** A block lies across the canal, the way on through its rooms: a dark brick front with one neat doorway under a wooden lintel, rubble piles before it; inside a hall, a living room, a kitchen (fridge, stove, sink, table, chairs), a stair hall open to the leaning roof slabs, a bedroom, a small room with a nook, a room upstairs with a window. Plaster walls with a ceiling trim, wood floors, dome lamps.

**Fix.**
- The block "fell" but stands perfectly level and square inside: floors flat, walls plumb, doors neat. It reads as a house built in the canal, not one that came down into it. Give it the fall: floors that tilt a few degrees one way (ramps of 5 to 8 degrees), a wall leaning in (a sheared prism), a crack across a ceiling with daylight through it, furniture slid to the low side, a light hanging on its cable at an angle.
- The ways through are tidy rectangles with lintels (the "hole in the entry wall" has a timber lintel): a fall tears holes. Ragged outlines (prisms with broken edges), splintered frames, rubble spilling from each hole, rebar at the torn edges.
- The front facing the canal is blank dark brick: a tenement's face has rows of windows. The town's facade kit (`map_town.facade`, with the owner's glass) laid on its face, tilted with it, glass broken in most.
- A big debris pile stands right at the module's entry viewpoint: it fills the first look at the block; move it aside so the first sight is the block itself.

**Better.**
- Make it feel lived in before it fell: the owner's flats are the model (plaster with a dado line, door casings, a radiator under each window, fluorescent tube or dome light, a toilet and sink in a tiny bathroom), posters and a calendar, a radio.
- Water: the canal's water has come into the ground floor's low side (a shallow func_water in the lowest room).
- Sounds: creaks and a slow trickle (a soundscape), a settling thud now and then.
- The stash nook and the lookout are good: mark the lookout with a chair and an ashtray at the window, binoculars (combine_binocular01 is Half-Life 2's, or a pair of jars).

**Weight.** large (the tilt and torn holes), medium (facade on the fallen face), small (dressing, sounds).

### 12. quay (showroom 2): stairs up to a quay with a street doorway, a footbridge to a barred door

**Seen.** A stair climbs the left wall from the canal to a landing; a quay recessed into the wall with a low wall along its edge, two street lamps, cleats, a skip, a bench, a payphone, crates, three posts before a framed street doorway (black, capped). A railed footbridge on two trestles crosses to a barred door in the right wall, glowing orange and black behind.

**Fix.**
- From the canal the stair is a row of separate steps hung on the wall with their sides open: it reads as a jagged sawtooth. Give its open side a solid upstand (a parapet 32 high following the flight) and fill under the flight to the floor, so it reads as one concrete stair built against the wall (Half-Life 2's canal stairs are built so).
- The barred door leads to nothing: through its bars is black. A short corridor behind it with a light and something to see (a locked store, a Combine supply room, a ladder going down) gives the bridge a reason.
- The lamps stand where they light the wall behind them better than the quay; turn their arms over the quay (lamppost03a's arm is its +y).

**Better.**
- A quay as a working place: tyres hung as fenders down the quay wall on short chains (tire001c and ropes), an iron ladder from the canal floor to the quay's edge (a second way up), a mooring ring, a coil of rope (props_junk rope coils if any; else a ring of rope), a capstan.
- The street doorway: a street sign over it (streetsign, decal_signroute), a Combine notice (decal_posterbreen), a camera watching who comes down.
- Puddles on the quay, a stain under the skip, cigarette ends by the bench (small decals), a gull's sound in the soundscape (Half-Life 2's coast birds) since this is where the canal meets the city.

**Weight.** small to medium.

### 13. collapse (showroom 2): a street's wall and roadway fallen in

**Seen.** Two huge slabs lean together like a tent across the canal, a wedge of roadway slopes down beside them to a standing piece of wall; a squeeze by the right wall, a low crawl hole at the slabs' foot into a hollow, rebar clusters, broken road sections, chunks, a car. The slabs are plain grey with black lane stripes painted on them.

**Fix.**
- City 18's roads are cobbles with no lane lines: the fallen road should be the owner's own road (stonefloor006d_c17, the sett strips at its sides) with a pavement strip, a kerb and a gutter along one edge of the slab, so it is plainly a piece of their street. Remove the painted stripes.
- Each slab is one flat colour on every face: the top should be road, the underside raw concrete with rebar mesh (a metal grid material or rebar props along it), the broken edges rough (a broken concrete material, uneven prisms).
- The crawl hole is a neat rectangle; a hole under fallen slabs is ragged and half filled (prisms, rubble spilling out, a beam propping it).

**Better.**
- What came down with the street: a lamppost lying across the slabs (lamppost03a_off on its side), a street sign, a bench, a manhole cover and its shaft, a fire hydrant (props_c17 has none; a short pipe stub with a cap), the gutter pipe snapped.
- Under the bite: the street's insides exposed: a sewer pipe (concrete_pipe001a) broken open and trickling, cables hanging (ropes), a water main spraying (a small env_steam in white, or falling water).
- Dust (func_dustmotes in the hollow), a light_spot from the gap down into the hollow so the hide has one shaft of light.
- A soundscape of creaking and settling; a small chunk falling now and then (a physics chunk spawned by a timer is too much; a sound alone does it).

**Weight.** medium (slab materials, broken edges), small (street things, dust, light).

### 14. scrapyard (showroom 2): a yard of stacked containers under a crane

**Seen.** The canal widens into a yard full of shipping containers (some stacked three high), wrecked cars stacked, tyres, plank ramps up onto the container roofs, a plank bridge, a ladder to the perch on top, a brush tower crane in the far corner with its jib over the yard and a hook. Plenty of ways through and over; the perch commands it all. A strong space.

**Fix.**
- Everything stands square and level: containers aligned to the grid, stacks plumb. A dump is messier: turn several by 5 to 20 degrees, lean one against another (a small pitch), leave a door hanging open, one stack slumped.
- The ground is the canal's clean concrete: a yard is dirt and gravel, oil-black where machines stood (a dirt material in a blend, oil and stain decals, puddles).
- One spotlight lights it all: a yard is lit by floodlights on poles and on the crane (the industrial light models, point_spotlights pointing down), and the porch by a bare bulb.

**Better.**
- Half-Life 2's crane magnet (`props_wasteland/cranemagnet01a` and a phys_magnet) on the crane instead of the hook, or as well: something to lift and drop (players could move cars to make a new way).
- A yard office: a hut on the plinth by the crane with a desk, a radio, a calendar, a window over the yard (the Combine's foreman, or a Resistance spy's place).
- Junk heaps the game's salvage can use (the crowbar salvage: these props are its natural home), a car crusher block, piles of tyres to hide behind.
- A chain link fence (Nova Prospekt's or the city's fence01a/03a) closing the yard off from the canal's edges, with a gap cut in it.
- Sounds: wind on metal, a container creaking, a distant crane.

**Weight.** small (rotations, floodlights, ground), medium (magnet, office).

### 15. boathouse (showroom 2): the smugglers' boat shed, a slipway and a hidden cellar

**Seen.** A slipway with two rails climbs to a big dark roll-up door in the left wall; a button hidden behind a drain pipe outside. Inside: a boat up on crates over the rails, a winch at the back, a workbench, shelves, drums, two dome lamps, a flat ceiling. A hatch in the floor to a cellar with pale walls, shelves, lockers and crates.

**Fix.**
- The shed is a flat-ceilinged concrete box: a boat shed has a pitched roof on timber trusses or a steel gantry over the slip, with a chain hoist hanging from it (a rope and a pulley hook). That one change makes the room.
- The roll-up door is a flat plate: give it the owner's corrugated door material (metaldoor032c or 018a, both in their map) laid with its ribs across, and a slot of light under it.
- The cellar's walls read as clean pale plaster: a cellar under a canal is damp brick or concrete, stained.

**Better.**
- A working smugglers' shed: tools on a board over the bench (props_c17 tools: wrench, hammer, pliers, the owner can see them), an outboard motor or engine on the bench (props_c17 engine models if any; else a generator01), coiled ropes, oars, a tarp over the boat.
- The contraband looks like it: Half-Life 2's own ammo crates (models/items/ammocrate_*) and supply crates in the cellar, a Combine crate with its markings, a ledger on a table, a radio.
- Light like a shed: bulbs on cables (lightbulb01a, the owner's map has 30) instead of dome fittings, daylight from the gap under the door.
- Water: let the canal's water lap at the slip's foot (if the canal ever has water), wet decals on the slip.
- A soundscape: water lapping, a radio murmuring in the cellar.

**Weight.** medium (roof and hoist), small (materials, dressing, lights).

### 16. arcade (showroom 2): a market arcade over the canal on three arches

**Seen.** Three dark stone arches carry a timber covered walk across the canal: open bays with brackets and a parapet, a pitched roof on posts, three counters down the middle, barred shop fronts at both ends; a railed stair up each wall. One of the best-looking modules: it has a real shape.

**Fix.**
- The stairs along the walls are separate steps with open sides (the same as the quay's): from the canal they read as a sawtooth. One shared fix in the tools (see the general list at the top: a wall stair with an upstand on its open side and filled under), applied here and in the quay, lift, crypt and anywhere `wall_stair` is used.
- The barred shop fronts are black behind: a shallow shop behind each (a counter, shelves with a few things, a dead lamp) so looking through the bars rewards it.
- The stone of the arches is uniformly dark: they read as black shapes from the canal. Lighter dressed stone at the arches' edges and keystones (a second stone material), a band at the deck's edge, and a lamp on each pier's cutwater.

**Better.**
- A market needs its awnings: Half-Life 2's `awning001a` and `awning002a` (props_c17) over the stalls and the bays, faded.
- Goods and the life of a market: crates of produce (watermelons, the game's food models), hanging lanterns or bulbs on a cord down the walk (the owner's lamp fixture lampfixture01a), a scale on a counter, a chalkboard price list, sacks.
- From below: water stains down the piers (decalstain), moss at the cutwaters' feet, an old painted market name across the arches' face (decalfont letters, Half-Life 2 has them).
- A soundscape of wind through the bays and creaking timber.

**Weight.** small to medium (shops behind bars, awnings, stone trim, lights).

### 17. crypt (showroom 2): the left wall broken into a church crypt

**Seen.** In the left wall an opening into a vaulted crypt: four squat pillars, chamfered vaults both ways, niches with stone coffins (one lid ajar), an opened tomb in the nave, Lost Coast's altar on a step with two tall candlesticks and a cross lit behind it, a bricked stair. Warm candle pools on the pillars. A good, quiet room.

**Fix.**
- The way in reads from the canal as a neat rectangular doorway into a lit room: it is meant to be a wall broken through. A ragged outline (prisms with broken edges), brick and stone showing in the break, rubble down the bank, and the crypt darker than the canal so it is a black mouth with candlelight deep inside.
- The candles: a candle's light on each pillar at the same height makes even pools; vary them (some pillars dark, a cluster on the altar, one in a niche) for a room that is lit by people, not by fittings.

**Better.**
- What a crypt holds: bones and skulls in the niches (Half-Life 2's skull gib is there once: more, and bones), plaques on the walls (a carved stone material patch or decals), dust and cobweb corners (a web overlay if the owner has one; else dust motes in the candle light).
- Water finding its way in from the canal: a dark stain spreading from the broken wall, a puddle on the stone floor, a drip sound.
- The bricked stair: a crack of daylight at the top (a light_spot through the gap) so the church above is felt, and a loose brick to peek through.
- The Resistance's use of it: the altar as a meeting table (a map, a radio, candles), or a hiding place for the injured (a cot in a niche). Its own soundscape: still air, a drip, the canal far off.

**Weight.** small to medium.

### 18. lift (showroom 2): a freight lift up to a loading dock

**Seen.** Against the left wall an open lift: four thin guide posts with ties and a sheave on top, a platform with handrails on three sides and a button on a stand. Above, a loading dock recessed into the wall: a lorry backed up to a street gate, crates, a lamppost.

**Fix.**
- The lorry fills most of the dock: the view "from the back of the dock" is inside the lorry's box. The dock is 448 by 320 and the lorry nearly that long; either a smaller vehicle (a van, or the lorry's trailer only, its doors open toward the lift) or a deeper dock.
- The lift's frame is four bare posts with nothing hung on them: it does not look like it lifts anything. Cables from the sheave to the platform's corners (ropes that move with it: keyframe ropes parented to the platform, as the swings' chains are), a counterweight in a channel beside it, the motor housing on top.

**Better.**
- Safety the Combine would never bother with but the city did: a chain link cage round the shaft at the dock (Nova Prospekt's panels), a sliding gate on the dock side the lift opens, yellow and black hazard edging on the platform and the dock's lip (an overlay).
- Light on the frame (a cage light on a post at each level), and a light on the platform that rides with it.
- The dock as a place: a loading ramp, pallets of Combine supplies, a forklift's absence shown by its parking marks, a clipboard on the wall. The street gate with a Combine notice on it.
- A soundscape: the street beyond the gate, the motor's hum.

**Weight.** small (lorry, cables, light), medium (cage and gate).

### 19. barge (showroom 2): a river barge grounded askew

**Seen.** A black steel barge sits askew on the canal floor: raked bow, a mast with a lamp, a winch, hatch covers (one slid back over a ladder), a wheelhouse aft with windows, a gangplank from the left bank. The hold below: two beds, a stove, a table, crates, low and crowded.

**Fix.**
- The hull is one flat black colour with no detail: from the canal it reads as a black box with a pointed end. A hull has a rub rail along its sheer, a waterline (a band of a second, rust-red material), rust streaks down from the deck scuppers (overlays), a name painted on the bow (Half-Life 2's decalfont letters), an anchor and chain at the bow (a chain rope to the floor), tyres hung as fenders.
- The hold is packed: crates fill the space between the beds and the ladder, so a player can barely turn. Fewer crates, the hold's floor clear down the middle.

**Better.**
- Half-Life 2 has two real fishing boats (`props_wasteland/boat_fishing01a`, about 1150 long and 310 wide, and `boat_fishing02a`, 1075 by 300): one could lie wrecked in another stretch of canal, or this module could carry one as the barge's neighbour, for a second, ready-made silhouette.
- Life aboard: washing on a line from the mast to the wheelhouse, a deckchair, a fishing rod over the side, a stove pipe smoking (env_smokestack, thin).
- The wheelhouse: an instrument panel (a brush console with dials: props_lab gauges), a chart on the wall, a radio.
- Mud piled against the hull where it grounded, a list to one side (a few degrees of roll on the whole vessel would sell "grounded" better than a level deck).

**Weight.** medium (hull detail, list), small (dressing).

### 20. busbridge (showroom 2): a bus hanging nose-down from the left street

**Seen.** A long tilted body hangs from the left wall's lip to the canal floor: a frame of thin posts with window openings, train bench seats inside tilted with its floor, truck tyres on its sides, the driver's chair at its foot. At the top a short pavement recessed in the wall, a dark lamppost askew, a bus stop sign, a capped street doorway.

**Fix.**
- The bus reads as a skeleton: thin posts and rails with large openings, little body below the windows, no roof edge, no front. It is the kind of brush vehicle the owner called "1998". Either build it as a bus (solid skirt panels to the window line, wheel arches round the tyres, a front with a windscreen frame, grille and a destination board, a rounded roof edge, a back with an engine grille, the owner's metal materials in two colours), or replace it with a real model.
- Real models that could do the job (no bus exists in Half-Life 2 or its episodes): `trailer001a` or `trailer002a` (a box trailer, hanging nose-down, a way up inside if hollow; check), `van001a_nodoor` (smaller), the Episode Two passenger car used in the tram (a city railcar off its rails is as good a story as a bus).
- The tyres stand out from its sides as loose boxes: on a bus they sit inside arches, half hidden.

**Better.**
- What fell with it: the parapet's broken railing hanging down the wall (handrail pieces at angles), glass everywhere (decals), a trail of scrapes down the wall where it slid (overlays), luggage and a suitcase spilled out of the low end (props_c17 suitcase, briefcase).
- The stop: a shelter frame at the top (a few brush posts and a roof, or the station's bench and a sign), a timetable poster.
- A soundscape: metal creaking under weight; the bus could even settle a little when someone climbs it (a tiny func_movelinear drop once) for a scare.

**Weight.** large (the bus rebuilt or replaced), small (dressing).

### 21. shell (showroom 3): a headcrab canister in the right bank

**Seen.** The game's headcrab canister stands out of the right bank, nose buried, in a raised ring of mud; rocks thrown up on the bank; a crack drawn up the wall to the trim as thin black lines; seven low red-brown mounds round it, three bodies, smoke, a faint green light.

**Fix.**
- The crack is a few black strips standing on the wall: it reads as wires stuck to it. A crack is either painted (an overlay of a crack decal, decals/plaster013a and 016a are in the owner's map) or cut: a patch of the wall's face knocked out (a shallow recess with broken edges, brick or rebar showing), chunks of it on the bank below.
- Round the impact there is no scorch: Half-Life 2 has a crater decal (decals/decal_crater001a) and burn decals for exactly this; the mud ring alone looks like a heap.

**Better.**
- The canister as Half-Life 2 shows one: steam venting from its open end (env_steam, white, short), a few sparks (env_spark on a slow timer), a small fire on the bank, the trail of smoke it left in the sky above (a long thin env_smokestack angled back the way it came).
- Headcrab signs before any headcrab: a dead headcrab or two (the ragdoll), a zombie torso (charple or the zombie models as ragdolls), blood trails (decals) leading away up the bank into the city.
- The Combine's answer: a police line across the canal at one end (decal_policeline01a, two barricades), a warning sign, a dead Civil Protection unit (the police model as a ragdoll) by the bars.
- The growth: keep it, but make it read as alive: the mounds a slightly glossy dark material, small pulsing sprites in sick yellow on them (no flicker: a slow scale pulse is fine), a wet sound in the soundscape.

**Weight.** small to medium.

### 22. aqueduct (showroom 3): a water trough crossing over the canal

**Seen.** A concrete trough on two piers crosses over the canal at the trim's height, from a barred culvert mouth in one wall to another; water in it; a narrow maintenance walk with a handrail on brackets along it; a ladder up the left pier; under mid-span a dark stain and a shallow pool in a ring of mud. From below it is a long dark beam on dark piers.

**Fix.**
- From the canal the trough's underside and the piers are almost black (no light reaches them): it is a silhouette, its brackets and ribs lost. A cage light on each pier under the walk and a light washing the trough's side.
- The leak drips into the pool by sound only: water should be seen to fall (a thin falling-water brush or a stream of drops: an env_splash or a small particle-less sprite trail is not available, so a narrow vertical water sheet), with splashes in the pool.
- Both culvert mouths are barred onto black (as in several modules: see the general list). A few feet of lit culvert behind each set of bars, the trough's water flowing on into it.

**Better.**
- Give it an aqueduct's shape: arches between the piers (as the arcade's), or ribs every 64 down the trough's sides, a coping along its top. City 18's concrete trims (stonewall050f, the owner's commonest trim) along its edges.
- The algae: a green-black overlay trailing down the trough's side from the leak and at the waterline inside the trough.
- Something to do with it: the valve on its rim could open a sluice and drain the trough (its water a func_water that lowers: a func_movelinear carrying the water brush), so the walk becomes a way along the empty trough into the culvert, a route the game can open.
- A soundscape of running water overhead.

**Weight.** small (lights, falling water, algae), medium (arches, the sluice).

### 23. pipes (showroom 3): a tangle of service pipes to duck and weave through, or climb over

**Seen.** Big concrete pipe sections laid across and along the canal (one to duck under, a chicane of two, a fat main along the left), steel plates on their ends; a stair of big concrete steps up the left side to a valve platform, a plank with a handrail along the main, a railed grating bridge across, a plank ramp down; a run of small pipes high overhead, risers on the walls, a steam leak. Good routes for play.

**Fix.**
- The "service pipes" are the city's concrete culvert sections: hollow drain pipes, not pipes that carry steam or water under pressure, and they look it (plain, hollow, end plates bolted on). Service mains are steel: octagonal or round brush pipes in a metal material with flange rings every 128 (the tools' `ring` helper makes them), saddles, a valve wheel at a joint; or Half-Life 2's industrial pipe models where they fit (props_pipes pipe sets, props_wasteland pipeclusters, the Combine's pipes01/02/03 singles).
- The stair to the valve platform is a flight of massive concrete blocks: a service stair is steel, grating treads on stringers with a rail (the grating material the bridge already uses, metalgrate013a).

**Better.**
- Pipes that say what is in them: painted bands (a stripe of colour material near the ends), stencilled numbers (decalindustrialnumber), arrows, a pressure gauge (props_lab gauges) on the main by the valve.
- The steam leak is the only sign of life: a second leak that the game can turn on and off (an env_steam with a name and a hurt trigger, so it blocks a route until someone shuts the valve: the valve becomes a use).
- Cage lights on the risers, lighting along the plank walk; drips and a low hum in the soundscape.

**Weight.** medium (steel pipes and stair), small (bands, gauges, steam use).

### 24. camp (showroom 3): a refugee camp on a terrace on the left bank

**Seen.** A broad earth terrace up the bank with six ridge tents of patched tar paper and carpet, their mouths to a cooking fire with a tripod and pot, benches and flat rocks round it, a washing line with cloths, a basket, barrels, buckets, a pushcart, a notice board, crates, a couch. Warm and believable from above.

**Fix.**
- At night it is lit by the fire alone: the tents' insides are dark caves. A lantern in or by each tent (the city's oil lamp, props_c17/lamp001a, is already in the game's kit: the underpass uses it), a string of bulbs from the washing poles.
- The tents are all the same A-frame shape: some can be a lean-to against the canal wall (one slope), one a tarp over a frame of pallets, one an old car body with a tarp (car002b), so it reads as people making do, not as a row of issue tents.

**Better.**
- Windbreaks and claims: pallets and doors stood on end round some tents (doors as wall panels, never upright where they look openable), a curtain over a tent's mouth.
- Water: a barrel under a gutter pipe coming down the canal wall from the street (props_pipes gutter pipe), a basin and a washboard.
- Children: a ball, a doll, chalk drawings on the wall (graffiti decals that look childish are few; decalgraffiti ones in bright colours).
- The Combine's eye: a Breen poster pasted on the wall above them, a camera on the opposite rim watching, a notice on the board in the Combine's way.
- A soundscape: the fire, murmuring voices, a cough, a radio playing very low.

**Weight.** small to medium.

### 25. stash (showroom 3): the secret arms room behind a wall a valve opens

**Seen.** From the canal only a run of rusted pipes with a valve wheel; a section of the wall slides aside; a short passage turns twice into the arms room: wooden racks of long guns on two walls, a workbench with tools under a map board, a planning table, shelves, crates, two bell lamps. Pale cream walls.

**Fix.**
- The guns on the racks, the tools on the bench and the map on the board are all brushes (grey gun shapes, grey bars, black lines on a pale board): the owner's complaint exactly. Use Half-Life 2's own weapon world models on the racks (models/weapons/w_smg1, w_shotgun, w_irifle, w_crossbow, w_pistol, w_357, w_crowbar, as prop_dynamic_override, not solid), the city's tool models on the bench (props_c17 tools_wrench01a, pliers, hammer), and paper on the board (props_c17 paper, props_lab clipboard; a map overlay if the owner makes one).
- The room's walls are clean cream plaster: a hidden arms room behind a canal wall is raw concrete or brick, with the pipes it hides running through it.

**Better.**
- Half-Life 2's ammunition crates (models/items/ammocrate_smg1, ammocrate_ar2, ammocrate_rockets, as the game uses them) for the stock: the gamemode could even make one a real ammo crate for the Resistance.
- A planning table that looks used: a map, a radio (props_lab citizenradio), a lamp, cups, an ashtray, a chair pushed back.
- The valve wall: a hint for the observant on the canal side (a scrape on the floor where the wall slides, a lambda scratched small on a pipe), invisible to the rest.
- Its soundscape: still, a radio's hiss.

**Weight.** small to medium (props for the guns, tools and board; the walls).

### 26. lock (showroom 3): a lock house, two steel gates and the control house

**Seen.** Two pairs of Half-Life 2's canal lock leaves between concrete piers that fill the banks (a gateway 256 wide), a pier and stairs on the left bank up to a gantry, a control house on it with a slit window each way, buttons, a desk with a monitor; a heavy door that never opens; a hydraulic pack on the far half. The house inside is pale cream plaster.

**Fix.**
- The control house reads as a clean room in a flat: a lock's control room is concrete and steel, with the gear in it. Panels on the walls (props_lab gauges and levers, the Combine's interface if the Combine run it), a big lever per gate beside the buttons, a gate-position indicator (two small lamps per gate, red and green), a chart of the canal, a CRT (the owner's map has controlroom monitors).
- The lock chamber between the gates has nothing to say it is a lock: no water marks, no ladders, no bollards.

**Better.**
- Lock furniture: recessed iron ladders in the chamber walls (metalladder002 in a slot), bollards and rings along the coping, a depth board (decalindustrialnumber up the wall at each gate), a dark tide line (overlay band) half way up.
- Signals at each end for boats: Half-Life 2's rail signal lamps (props_trainstation light_signal001a/b) on the piers, set red while a gate moves.
- The hydraulics seen: the rams that push the leaves (brush cylinders with a shining rod between the pier and the leaf), pipes from the pack to them along the gantry's underside.
- The street door: since it never opens, board it (as the town's unused doorways) or chain it (prison_padlock001a), so nobody tries it.
- A soundscape: water against the gates, the pack's hum, a klaxon when a gate moves.

**Weight.** medium (control room, rams), small (lock furniture, signals, door).

### 27. thumper (showroom 3): a Combine thumper on a fenced terrace

**Seen.** A concrete terrace up the right bank, fenced with chain link panels and a gate, Half-Life 2's real thumper on a plinth, two Combine barricades, a console with a button and a lamp against the wall.

**Fix.**
- The console's lamp is `light_cagelight02_off` with a light under it (the same mismatch as the overflow): use the `_on` model.
- The fence is Nova Prospekt's prison chain link: around a Combine machine, Half-Life 2 uses the Combine's own fences (`combine_fence01a/b`, with a field between posts, or the tall barricades). The prison fence belongs to people's places (the pit, the pen).
- Nothing shows why a thumper is here: antlions are kept away from something.

**Better.**
- The other side of the story: the canal beyond the terrace drifted with sand (a sand material blended into the floor, nature/sandfloor010a), an antlion corpse or two (the antlion model as a ragdoll), a burrow mouth in the far bank (a dark hole with sand spilling), Half-Life 2's antlion hill if Episode Two is allowed.
- Power: a fat cable from a Combine generator (combine_generator01, Half-Life 2's own) to the thumper's base, lying on the terrace (a rope with slack on the floor).
- Combine presence: combine_light002a on the fence posts, a camera, a warning sign, the hum and the beat in the soundscape; the dust burst exists already, a faint shake already exists.
- The console as the thing to fight over: a screen that shows its state (combine_smallmonitor001), the button behind a cover.

**Weight.** small (lamp, fence, generator), medium (sand and antlion signs).

### 28. swingbridge (showroom 3): a footbridge that turns on a pier

**Seen.** A plank footbridge on two steel beams spans the canal at the trim's height, turning on an octagonal pier in the middle; a roofed landing in each wall with a heavy door, a winch and a button, green lamps; a covered stair to each landing.

**Fix.**
- The heavy doors at the landings never open (as the lock's): board or chain them so nobody tries them, or make one real (the city's door, `real_door`) onto a short stair to the street.
- The pier is a plain octagonal post: what turns the bridge is not shown. A swing bridge sits on a drum: a wider round cap on the pier with a toothed ring (a ring of small blocks, or the tools' `ring` helper) and a pinion from a motor box on the deck's middle.

**Better.**
- A bridge of its kind: steel truss sides instead of (or under) the handrails (a lattice of thin brush members, Half-Life 2's girder material), a counterweight box under one end, a little control cabin at the middle (a booth: the Combine's or the city's).
- Signals at both landings: a red and a green lamp (the rail signal props), a striped barrier arm that drops when the bridge is turned away (a func_door_rotating arm, linked to the bridge's own outputs).
- A klaxon and a turning motor in the bridge's sounds (it has a sound already: add a bell before it moves, so players on it hear it coming).

**Weight.** small (doors, signals, bell), medium (drum and truss).

### 29. floodroom (showroom 3): a valve chamber that floods

**Seen.** Off the left wall a passage and a steel sliding door, steps down into an eight-sided chamber with a gallery round it behind handrails, a stair up to it, a big main from floor to roof with a hand wheel, a second way out round the back through one of the city's doors. Blue water shows in patches on the chamber's floor even while it is meant to be drained.

**Fix.**
- **A real bug:** the drained water's top lies exactly at the chamber's floor (`map_mods_c.py`, the func_water_analog's box ends at FL), so floor and water share one plane and will flicker through each other in game (the blue patches in the picture). Its top should sit 2 or more under the floor (box to FL - 2, movedistance 90).
- The hand wheel on the main is `props_wasteland/wheel01`, a cart's wheel. Half-Life 2 has real valve wheels: `props_pipes/valvewheel001` and `valvewheel002` (and the Borealis's `door_wheel001a`, already used on the gallery).
- Before it floods there is no warning: a klaxon and a red rotating light (a light with a slowly turning point_spotlight: a func_rotating carrying it) while the water rises, so a player on the floor knows to climb.

**Better.**
- Make the chamber look like it floods: a tide line on the walls at the gallery's height (an overlay), silt on the floor, a drain grate in the middle (the water comes up through it: a decal of a grate and bubbles), the steel door with a rubber seal and wheel lock.
- The trap's tell for the careful: a sign by the door ("DANGER: CHAMBER FLOODS") in the city's way (decalsigndanger plus a few letters), the second way out marked with an arrow.
- Under water: something worth diving for when flooded (a lost case at the bottom, a cache the game can fill), so flooding it is also a way in.
- Sounds: rushing water when it fills, pipes knocking when it drains.

**Weight.** small (the water's top: a one-line fix; valve wheel; alarm), medium (dressing, underwater cache).

### 30. railbridge (showroom 3): a railway bridge a train crosses every few minutes

**Seen.** A steel girder bridge on two concrete piers crosses over the canal from one tunnel mouth to another; the waiting train of two flat cars sits in the left tunnel; caged lamps on the mouths, crates fallen under the bridge.

**Fix.**
- The signal lamps are `light_cagelight02_off` with a red glow sprite in front: Half-Life 2's rail signals (props_trainstation `light_signal001a/b`, `light_signal002a`) are made for this, with a lit and an unlit look.
- The tunnel mouths are plain openings in the canal wall: a railway portal has a face (a stone or concrete surround with a lintel, a number plate, a warning sign), and the rails should be seen running into it.

**Better.**
- The same train as the street's: the street corridor runs Half-Life 2's Combine train (combinetrain01a and combine_train02a cars); this bridge runs two flat cars of train005. One look for the city's trains (or both, as two kinds of traffic: Combine freight here, the Combine's own train on the street).
- Rails, sleepers and ballast seen on the bridge's deck from the canal's edge and from the tunnel mouths; an overhead wire on posts.
- When the train crosses: dust and grit falling from the girders (a func_dustmotes burst or a small env_dustpuff along the bridge's underside), the lamps' red, the horn echoing in the canal.
- Under the bridge: the fallen crates broken open, a body of someone who stood on the line (the game's trains kill), graffiti on the piers.

**Weight.** small (signals, dust, portals), medium (rails and ballast, one train look).

### 31. execwall (showroom 4): the firing wall

**Seen.** A recess in the left wall: concrete barriers along the back, the wall above pocked and stained (17 decals), three timber posts with rope ends, a grating to the canal, one hard Combine floodlight raking along the posts; a low kerb in the canal where the squad stands. Sober, and it works.

**Fix.**
- The squad's kerb runs across the canal floor as a long, low concrete rail: in the canal's walking line it is a trip edge with no reason. A painted line instead (an overlay: a yellow stripe), or two short stubs at the line's ends.

**Better.**
- The Combine's voice: a speaker on the wall (speakercluster01a, as the plaza's) to read the sentence, a camera over the recess.
- The Combine's marks: a number or stencil on the wall (decalindustrialnumber), a Breen poster facing the posts, a combine_light002a over the barriers instead of nothing.
- What is left behind, still sober: a dark stain at the grating (decalstain under it), a shoe, a dropped ration bag, a candle and a flower someone left at night (the Resistance's memorial touch; the gamemode's memorial module has candles).
- A soundscape that is silent but for the floodlight's hum and the canal's wind.

**Weight.** small.

### 32. breach (showroom 4): the floor fallen into an old cellar

**Seen.** A neat rectangular pit in the middle of the canal, its walls the canal's grey concrete, two long slabs leaning in as ramps, a third hanging over the far end on two timber poles with crates under it; a little rubble and rebar.

**Fix.**
- The pit is a clean box: perfectly straight edges, smooth walls, square corners. A floor that fell in breaks: a ragged outline (cut the edge into uneven prisms, the floor's thickness showing in layers), cracks running out from it across the canal floor (overlays), the slabs' broken ends jagged.
- It is meant to be an old cellar, but its walls are the canal's concrete: old brick walls (brick/brickwall material, an arch or two in them, a bricked-up doorway), the cellar's own floor of old flagstones under the earth and water.

**Better.**
- The cellar's past: an old wine rack or shelves against one wall, barrels (props_c17 oildrum is wrong for old; wooden barrels from Lost Coast or crates), a coal chute.
- Water: a real pool in the low corner (it has a sliver of water now), drips from the breach's edge.
- The undercut stash lit by a candle or a lantern left by whoever uses it.
- Dust in the light from above (func_dustmotes), a soundscape with dripping and a hollow echo.

**Weight.** medium (ragged edges, brick cellar), small (dressing).

### 33. wreck (showroom 4): a Combine dropship's container down in the canal

**Seen.** Episode One's wrecked troop container lies on its belly squarely along the middle of the canal, earth heaped at its nose, crates scattered, a red glow and sparks. (The viewer draws it as a box: its shape is Valve's, its lie is judged by numbers.)

**Fix.**
- It lies dead straight down the canal's middle, level: a thing that fell from the sky lands at an angle. Turn it 15 to 25 degrees across the canal, nose down a few degrees into the earth (a pitch), one corner against the bank.
- Nothing shows how it arrived: a gouge down the canal floor behind it (long scrape overlays, broken floor slabs lifted), a chunk knocked out of the canal wall's top where it clipped it, the fence there torn and hanging.

**Better.**
- The crash's leftovers: a dead Combine soldier or two (the soldier model as a ragdoll), their weapons nearby (w_irifle as a prop the game could let be taken), Combine supply cases (ammo crates), a burning patch (env_fire, small, does not drop), black scorch overlays.
- The beacon: a slow red pulse on top (a sprite whose brightness the game can toggle) and a Combine tone in the soundscape, so both sides know where it is from a distance.
- If its door end is closed or not enterable (unchecked), the cache can go in a torn-off section beside it, so the race always has a prize.

**Weight.** small (turn and pitch, scorch, bodies), medium (gouge and wall damage).

### 34. relay (street 1; also a canal module): the radio relay shack and mast

**Seen.** A concrete quay against the right wall, a tin hut on it (a table with a radio, a chair, a bed frame, a cork board), a tall utility pole for a mast with two small dishes, guy wires, a red lamp at its tip, an aerial across the canal, a generator and drums.

**Fix.**
- The quay is a plain concrete block with blunt steps: the hut and mast sit on a featureless plinth. A quay's edge has a coping, bollards, a ladder, a fender or two; the steps a rail.
- Inside, one dome lamp on a radio shack's ceiling: a radio operator works by a desk lamp (props_lab desklamp01, already in the game's kit) with the set's dials glowing (a small sprite).

**Better.**
- A relay that looks like one: a long-wire aerial strung from the mast to the hut's roof, an antenna on the hut (props_rooftop antenna01a/02a are real), cables into the hut through the wall, a battery bank or car batteries on a shelf, headphones and a logbook on the table, a map with pins on the board, a codebook.
- Hidden from the Combine: a tarp or netting thrown over the hut's roof, the red lamp shielded from above (only visible from the canal), the generator in a lean-to with its exhaust pipe.
- A soundscape: the generator's hum, radio static and fragments of Resistance chatter.

**Weight.** small.

### 35. chimney (street 1; also a canal module): a hollow factory chimney to climb

**Seen.** The canal opens into a round yard; in its middle an eight-sided brick chimney on a plinth, a doorway at its foot, a stair of stone slabs winding up inside round an open well with the old hoist rope, an iron gallery at the top with plates and handrails and a cap on posts. Broken walls of the works in the yard, a car, a skip.

**Fix.**
- The "round" yard is a stepped outline of squares (as the cistern): its wall is a staircase of corners from above and a sawtooth from inside. A true curve (angled segments) or an honest polygon with clean faces.
- The chimney is one dark brick from foot to top: a factory chimney has a stone plinth course, lighter bands of brick every 64 or so, iron hoops, a corbelled crown wider than the shaft, a lightning conductor down one face, maybe the works' name in white brick (decalfont letters).
- The broken walls of the works are low plain stubs: give them arched window openings in brick, so the factory that was is read.

**Better.**
- The works' leftovers in the yard: pulley wheels (props_c17 pulleywheels_large01), a boiler, rails set in the floor for a truck, a rusted gantry.
- An iron ladder up the chimney's outside to a hatch (a second way up, exposed, for the brave), and the hoist rope's pulley at the top.
- At the top, the reward is the view: make sure the gallery's plates do not block it at standing height (they are for crouching behind), and a pair of binoculars on a hook.
- Wind on top (a soundscape that changes up there), crows.

**Weight.** large (the yard's curve), medium (chimney detail, works' walls), small (dressing).

### 36. cells (street 1; also a canal module): the Resistance's cells

**Seen.** A heavy steel door from the canal into a guard room (table, chair, lockers, bench, a board of padlocks), a long corridor past three cells with Nova Prospekt's barred doors and windows, prison lamps, a pipe along the ceiling; in each cell a mattress, a bucket, a toilet; a loose grate in the far cell to a crawl duct out to a pipe in the canal.

**Fix.**
- Walls, ceiling and floor are one pale plaster everywhere: it reads as a clean office corridor. A cell block is concrete, painted to shoulder height (City 18's two-tone walls with a dado line: a darker lower band), stained, with a floor drain.
- The corridor is long, straight and evenly lit: give it rhythm: a lamp over each cell door (the prison lamps), darker between, the guard room brighter.

**Better.**
- The cells lived in: tally marks exist (good), scratched names, a bunk frame (prison_bedframe001b) instead of a mattress on the floor in one, a tray of food on the floor, a rag.
- The guard room as the Resistance's: a radio, a rifle on the table (a weapon prop), a ring of keys on the board, a Combine mask on a nail as a trophy, a chair facing the corridor.
- The breakout duct: a few loose bricks round the grate, dirt trailing from it, so the observant prisoner finds it.
- A soundscape: a drip, a far-off radio, a cough from a cell.

**Weight.** small to medium.

### 37. memorial (street 1; also a canal module): the wall of the dead

**Seen.** A recess with a stone wall covered in rows of small plaques (the top rows sparse), a ledge of candles, frames, bottles, tins and pots, a tall candlestick at each end, posters, a line strung across, a bench facing it. Warm, quiet, and one of the most affecting modules.

**Fix.**
- The plaques are all plain flat rectangles in slightly different flat colours: they read as tiles. Give them a material that reads as metal or stone with an engraved surface (a brass or stone plaque material if Half-Life 2 has one; otherwise a dark metal with a lighter frame, two brushes each), and vary their sizes a little.
- 14 lights for the candles is many for a small recess (each costs at compile and in game): two or three lights placed among the candles give the same glow, with the sprites kept for the flames.

**Better.**
- Personal things among the candles: a child's shoe, glasses, a Combine ration card, a hat; photographs (the frames) at different angles; dried flowers if any plant model will do (Half-Life 2's potted plants or Kleiner's cactus are wrong; leave flowers out rather than fake them).
- Writing: names scratched straight into the wall's lower part where the plaques ran out (decalfont letters, or graffiti decals in white), the lambda once, small.
- The game's link: when the gamemode lists the permanently dead (the docstring's idea), each could become a plaque here, a real tie between play and place.
- A soundscape: almost silent, a low wind, a candle's crackle.

**Weight.** small.

### 38. pit (street 1; also a canal module): the fighting pit

**Seen.** An eight-sided arena off the canal: three tiers of concrete seats on three sides, a sunken dirt ring inside a cage of Nova Prospekt's fence panels on a kerb, the real gate in its frame, a gantry with two hanging lamps over the ring, a bookmaker's table with a till, lamp and a chalk board of odds, the corner men's bench.

**Fix.**
- The tiers are plain concrete steps with no edge: spectators stand on a 32 drop with nothing to lean on. A rail along each tier's front (the city's handrail) and the tiers' faces darker, so the rows read.
- The arena's walls above the tiers are blank: lit only by the two lamps over the ring, the crowd's side is dark. Strings of bulbs from the gantry to the walls (lightbulb props on ropes), a lamp at each stair.

**Better.**
- A fight night's dressing: bottles and cans on the tiers, paper slips on the floor by the bookmaker (props_c17 paper), a bucket and towel in each corner, blood decals in the ring's dirt, a bell (a pan hung on a hook will do), banners of cloth on the walls with painted names.
- The chalk board as the one brush that should stay a brush, but with chalk on it: a few decalfont letters and numbers (Half-Life 2's font decals) instead of grey bars.
- A soundscape that the game raises with a crowd's murmur and cheer when a fight is on (the game knows when the gate opens).

**Weight.** small.

### 39. garden (street 2; also a canal module): the walled garden

**Seen.** Steps and a board fence with an iron gate into a yard: six raised timber beds with ridged soil, a flagstone path, bean poles over two beds, a scarecrow (a brush figure with a hat), a tool lean-to with a lamp, a barrel under a gutter pipe, a compost heap, a cart, a wheelbarrow, melons; eight planting spots marked for the game.

**Fix.**
- Between the beds the yard is the canal's grey concrete with flagstones laid on it: a garden's ground is earth and worn grass (the module already has a grass material, nature/grassfloor002a, and the dirt one), the flagstones set into it.
- The bean poles stand bare: nothing grows on them. Leafy plant models at their feet climbing a little (Half-Life 2's foliage: the ferns and shrubs the bunker forest uses), or fewer poles with some leaning, so they read as a crop and not as a fence of sticks.

**Better.**
- Things growing in the beds that are not the game's: rows of small plants (low foliage props, a cabbage-like shrub), a bed of seedlings under an old window laid on bricks as a cold frame (a glass brush on timber).
- The lean-to: seed packets and jars on a shelf, a hose coiled, a watering can (if no model, a bucket), sacks.
- Birds: a pigeon or crow sound, and the scarecrow earning its keep with a crow on a fence post (Half-Life 2's crow NPC is the game's to place; the sound is enough here).
- A soundscape of the street above and birds, quieter than the canal.

**Weight.** small.

### 40. market (street 2; also a canal module): the black market arcade

**Seen.** Two archways into a vaulted arcade with ribs at every pier; five stalls along the back behind roll shutters (some up, some down), each now deeper with a counter at the front, a shelf at the back and a couple of goods; a fire drum between two benches, a lookout's stool in each archway, dome lamps.

**Fix.**
- The shutters are flat plain panels: give them the corrugated door material (as the boathouse's should have), with a padlock on the down ones (prison_padlock001a) and a handle at the foot.
- The arcade's walls and vault are a pale clean plaster: a black market in a canal wall is grimy, smoke-blackened over the fire drum (a soot overlay above it), damp at the floor.

**Better.**
- Sell the black market's goods: Half-Life 2's ration package (models/weapons/w_package), batteries and health vials (items/battery, items/healthvial), radios and parts (props_lab), Combine things stripped and resold, a crate of Breen's water cans (props_junk popcan models).
- Each stall its own trade, shown above it: a hand-painted sign (a board brush with decalfont letters), an awning (props_c17 awning001a/002a) over the open ones, hanging lanterns.
- Smoke from the fire drum gathering under the vault (an env_smokestack, thin), a soundscape of low voices and the fire.

**Weight.** small.

### 41. press (street 2; also a canal module): the pamphlet press

**Seen.** A short tunnel to a wall with a real door; behind, the printing room: a wooden hand press (brush: no model exists) with its lever, platen and bed, three drying lines hung with sheets, a chest of drawers for type, a table with a lamp and papers, paper bundles on a pallet, ink drums, a mattress.

**Fix.**
- The module's one-line description still says "a printing room behind a false stack of crates" (the crates are gone): it shows in the catalogue and the build lists. "a printing room behind a door in a side tunnel".
- The room is evenly lit by one dome lamp and the walls are clean plaster: a clandestine print shop is lit by a hanging work lamp low over the press (the bell lamp) and the table lamp, the corners dark, the walls spattered with ink (dark stain decals) and pinned with proofs.

**Better.**
- What they print, shown: the Resistance's posters on the walls and on the drying lines (if the owner makes a poster or two as decals, as their city's posters are; the lambda spray as a stand-in), stacks of finished pamphlets tied with string, a satchel by the door for the runner.
- Half-Life 2's paper guillotine (props_citizen_tech/guillotine001a: check its size) as the paper cutter, a typewriter if any model exists (none known), a radio.
- A lookout's touch: a mirror or periscope by the door, a bell wired from the tunnel's mouth (a cord along the ceiling), so the printers have warning.
- A soundscape: the press's creak and thump when used, paper rustle.

**Weight.** small.

### 42. still (street 2; also a canal module): the still in a cellar

**Seen.** A tunnel, steps down into a cellar: a brick firebox with a fire, a boiler on it, a pipe across to the worm (a drum on a crate, now capped with a funnel), three blue mash barrels, kitchen shelves, a table with a pot and bottles, a stool, pale steam. Pale cream walls, a dome lamp.

**Fix.**
- A cellar of cream plaster under one dome lamp: a distillery's cellar is brick or stone, low and vaulted, lit by the fire's glow and one bare bulb, the walls sweating (damp stains) and blackened over the firebox.
- The firebox has nowhere for its smoke to go: a flue pipe from the boiler's top up through the ceiling (props_pipes gutter pipe or a brush pipe), or the cellar would fill.

**Better.**
- The trade shown: rows of filled bottles on the shelves (glassbottle props in lines), crates of empties, a funnel and a jug at the worm's tap, sacks of grain or potatoes (props_junk sacks if any; else boxes), a hand-written tally on the wall.
- The danger: a fire extinguisher (props_junk? if none, a bucket of sand), scorch marks round the firebox, a warning in the Resistance's own hand.
- A soundscape: the fire, a drip from the worm, bubbling.

**Weight.** small.

### 43. plaza (street 2; also a canal module): rows stepping down to a rostrum at the back wall

**Seen.** (Turned round on the owner's word.) From a terrace at street height five concrete rows step down to a half-octagon floor; at the back wall a small timber rostrum with a lectern, the loudspeaker cluster high on the wall above it, a caged lamp each side, a fire drum each side of the floor.

**Fix.**
- The module's description still says the rostrum stands "between two street lamps that carry a wire for a banner": the lamps and wire are gone. Update it.
- The back wall behind the rostrum is a huge blank face: every eye in the rows ends on it. It is the backdrop: a banner hung from it (a cloth brush with the lambda, or the Combine's if they take the place), a painted mural, or a framed recess with a door behind the rostrum (the speaker's way in and out).
- The rostrum is small and low against that wall (24 up): from the top row it is a box at the foot of a cliff. Larger (a stage 256 wide, 48 up) with a back screen and a canopy, the lectern on it.

**Better.**
- Light the speaker: a pair of spotlights on the side walls pointing at the rostrum (point_spotlight: the owner's map uses 174 of them), the rows in half light, so the eye goes to the speaker.
- People's things on the rows: crates and planks used as seats, a few cushions, cans, a hat.
- A flagpole at the rostrum's side for the Resistance's flag (the game's pole stands at a marker: an `lc_hq_setup_plaza` marker here would make the plaza a possible headquarters too, if the owner wants).
- Sound: the speaker's voice should carry: an env_soundscape here that is quiet, so the game's speeches are heard.

**Weight.** small to medium.

### 44. playground (street 3; also a canal module): the playground

**Seen.** A yard (in the canal a terrace up the bank; on a street level with the pavement): City 17's swing set with two seats that swing, a slide, a roundabout that turns, a timber sandpit with sand, a bench facing it all. The yard's floor is plain concrete, its walls blank.

**Fix.**
- The viewpoint "from the canal" (eye 768 40 464) looks straight into the terrace's face: it shows a grey wall. Raise the eye or set it back so the playground is seen from the canal.
- Concrete underfoot and blank walls round it: a playground has a softer, worn ground (dirt and gravel, a worn patch under each swing: an overlay), and a low fence or railing round it (the city's handrail or fence01a), so it is a place and not a corner of a yard.

**Better.**
- The relic feel: rust and peeling paint on everything (overlays on the walls behind), a dead tree in a planter (Half-Life 2's dead trees or a stump), a bin overflowing, a Combine notice on the fence.
- Children are gone but not forgotten: a ball or a doll if a model exists (check the lists), chalk drawings on the ground (a graffiti decal on the floor), a hopscotch grid (an overlay).
- A soundscape: wind, the swings' chains creaking now and then (the game's own physics will do it if the wind is not there).

**Weight.** small.

### 45. clinic (street 3; also a canal module): the field hospital

**Seen.** A vault behind drawn curtains under a painted white cross: whitewashed walls over a darker band (City 18's two tones, good), tiled floor; a ward of four bed frames with mattresses and screens between them, drawers, carts, a stove, a bench; a dispensary behind a display counter with shelves; an operating theatre with a long table under a downward light; a sluice room with a sink, a boiler, a bucket and a floor grille. One of the most finished interiors.

**Fix.**
- The curtains at the way in are heavy panels to the floor in one flat colour: a clinic's curtains are thinner, hung from a rail with a gap at the foot (end them 8 above the floor), lighter in colour.
- The theatre's table is lit, the rest of the theatre flat: one more light (a cool tone) by the closet, and the table's light a stronger, tighter spot.

**Better.**
- Medical things Half-Life 2 has: gas canisters as oxygen bottles (props_c17 canister01a/02a) by the beds, the Combine's wall health charger (props_combine health_charger001) stolen and wired up in the dispensary, health kits and vials on the shelves (items/healthkit, healthvial), a stretcher (a hospital cart with a mattress on it).
- The marks of use: bloodied rags in a bucket, stains under the theatre table (decals), a sterilising pot steaming on the stove (env_steam, small), a chart on a clipboard at each bed.
- A queue outside: a bench by the curtains, a sign with the hours.
- A soundscape: a kettle, a low moan, the leak (it has one).

**Weight.** small.

### 46. pumphouse (street 3; also a canal module): the pumping station

**Seen.** A wide doorway into a tall machine hall: a big iron wheel turning on the pump's shaft right in front of the door, the long tank of the pump behind it, risers to a header pipe, a turbine pit with water and a handrail, a steel gallery round the hall with the control desk over the door; the main leaving through the wall and crossing the canal on a pipe bridge.

**Fix.**
- The wheel stands squarely in front of the doorway: the picture "the hall from the door" is all wheel. Coming in, the first thing a player does is walk into its unseen wall. Move the wheel and pump to one side of the hall's axis so the doorway opens onto floor, with the wheel seen turning across the hall.
- The hall's walls are bare pale concrete: a machine hall has its marks: hazard stripes along the pit's edge and the wheel's guard (an overlay), numbers on the machines, a painted line round the walkway.

**Better.**
- A travelling crane rail across the roof with a hoist hanging (a beam brush and the pulley hook), as every pump hall has.
- Gauges and switchgear: props_lab gauges and switch boxes on a panel by the pump, the substation transformer already there wired to it with cables (ropes) in a tray.
- Grating over part of the floor with water running in a channel under it (a func_water strip under a grate material), the turbine pit's water moving (a slow-scrolling water material if available).
- A soundscape the game can change: loud machinery while the pumps run, silence when stopped (it has the relays: give the soundscape a name too).

**Weight.** small to medium (move the wheel, stripes, crane, gauges).

### 47. depot (street 3; also a canal module): the Combine's ration depot

**Seen.** The Combine's big door into a loading bay with a lorry at a dock; three chain link cages with gates along the back with stock; the dispatch desk with a console; a roller conveyor out through a hatch and down a chute; a staff door up steps with a red lamp. Cream walls, dome lamps.

**Fix.**
- It is the Combine's, but inside it looks like any warehouse in cream plaster: City 18 dresses the Combine's places in their metal (metalcombine002, the Combine's inner wall props combineinnerwall001a/c), lit by combine_light002a (75 in the owner's map), with monitors (combine_intmonitor001, combine_smallmonitor001) and the Combine's interface by the doors.
- The stock is wooden crates and cardboard: the Combine's ration supply should show its own crates (models/items/item_item_crate is the Combine's supply crate: there are five; more of them, stacked), ration packages (models/weapons/w_package) in the cages, Breen's water (props_junk popcan) in cases.

**Better.**
- Security that raiders must answer: a camera over the cages (combinecamera001), a Combine lock on the cage gates (props_combine combine_lock01), an alarm lamp that the game can turn red.
- The loading dock: yellow hazard edging on the dock's lip, a pallet jack (if any model; else a brush handle and forks), a clipboard of manifests at the desk.
- A soundscape of the Combine's hum, a radio dispatcher's voice now and then.

**Weight.** medium (the Combine's dressing), small (crates, camera, locks).

### 48. armory (street 3; also a canal module): the Combine armoury vault

**Seen.** An armoured corridor in Combine metal to a sliding vault door, a guard booth with a slit beside it, two buttons that must be pressed together, a red alarm lamp; inside the vault lockers, ammunition crates with guns and rounds on them, the Combine's weapon frame with pulse rifles under a blue glow.

**Fix.**
- The corridor is the Combine's metal, but the booth and the vault behind it are cream plaster: the vault, of all places, should be the Combine's (metalcombine002, the inner wall props), with a floor of steel plate.
- The green "press counts" lamps are `light_cagelight02_off` with a glow sprite: the Combine's own small light (combine_light001a/b or 002a) suits a Combine door better, and shows lit when the glow is on.

**Better.**
- The heist's feel: a camera in the corridor (combinecamera001) the raiders must deal with, laser-like tripwire beams across the vault's door (a thin red sprite beam: env_beam between two points, which the game could tie to an alarm), the Combine's ammo crates (ammocrate_ar2) with the Combine's markings stacked to the ceiling.
- The guard booth: a monitor showing the corridor (combine_smallmonitor001), a rack for the guard's stunstick, a chair, a log.
- The alarm: when the door opens without the right pair, a klaxon, the red lamp, and the corridor's lights to red (the relays are there; give the lights names).

**Weight.** small to medium.

### 49. substation (street 4; also a canal module): transformers behind chain link, a fuse panel to break

**Seen.** A concrete quay against the right wall fenced with chain link panels and a sliding gate; three of the city's transformers on it, cables up to an arm on the wall and across the canal, a switch cabinet with a breakable fuse panel, a caged warning lamp, a hum. Inside the fence a narrow aisle between the panels and the transformers.

**Fix.**
- The fence runs along the quay's very edge and the transformers fill the rest: inside is a corridor 64 wide between two walls of boxes. Pull the fence back from the quay's edge so the transformers stand in a yard, with the cabinet reachable without squeezing.
- No warning anywhere: City 18 marks its danger (decalsigndanger001c and 001e are in the owner's map): signs on the fence and the cabinet, a lightning-bolt plate on each transformer.

**Better.**
- Make the power seen: the Combine's cable conduits (props_combine pipes01/02 singles) from the transformers into the canal wall toward the checkpoint the fuse feeds, a Combine meter box (combine_interface002/003) on the cabinet.
- When it is cut: sparks from the transformers' tops as well as the panel, a smoke wisp, the hum's stop, every Combine light in the module going dark (name them: the relay is there).
- A soundscape: electrical hum close, the canal's quiet beyond.

**Weight.** small.

### 50. morgue (street 4; also a canal module): the cold room

**Seen.** A sliding steel door into a short passage and a tiled cold room: a wall of twelve drawers (brush, two pulled out), three steel surgery tables with the dead, a drain, a clerk's desk with a ledger and clipboard, hanging lamps, a hum. Clean and cold: it works.

**Fix.**
- The "cold lamps" are the warm industrial bell lamp: a cold room is lit by fluorescent tubes, and City 18 has them everywhere (props_lab lab_flourescentlight002b, 149 in the owner's map): two or three tubes on the ceiling, a cool white light.
- The two corpses are ragdolls on the tables; they may slide off (the docstring says so). A body laid out does not move: a prop_static or a prop_ragdoll with the "start asleep" and "debris" flags, or the body under a sheet as a brush shape with a cloth material, which also reads more soberly.

**Better.**
- Tie it to the ash outfall (module 6): a body chute in the back wall (a steel hatch on a frame) where the dead go to the cremator, its conveyor rollers, a tag on each drawer (small decals or numbers).
- The clerk's things: a stack of identity cards (paper props), a Combine terminal for the records (combine_interface or a monitor), a coat on a hook, a radio.
- Cold breath: a faint mist near the floor (func_dustcloud in white, very thin), the hum of a compressor in the soundscape.

**Weight.** small.

