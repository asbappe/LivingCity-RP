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

