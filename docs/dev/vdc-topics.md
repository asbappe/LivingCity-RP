# Valve's wiki by topic (where to look first)

The saved Valve Developer Community wiki (`docs/dev/vdc-reference.md`) has about 10,000 pages; this is its
table of contents for Living City's work. Each topic names the pages to read first; get any of them in short with
`python3 _dev/tools/vdc.py --card NAME` (an entity: what it is, keyvalues, flags, inputs, outputs, bugs, Valve's use,
the map lessons naming it) or whole with `vdc.py NAME`. For anything not here: `vdc.py --search WORDS` (the best
pages, a line each), `vdc.py --gotchas WORDS` (every bug, warning and workaround on it), `vdc.py --entities WORD`
(entity pages, Valve's most used first).

**Before building or changing a map piece, check its entities' cards and the topic's gotchas.** The wiki holds the
small print a chat gets wrong from memory: what breaks in multiplayer, which keyvalues exist only in other games
(a card marks them `[only ...]`; they do nothing in Garry's Mod), compile limits, known bugs and their workarounds.
Valve's own maps and the owner's corrections still come first (`map_lessons.py`); the wiki says what the engine does.

- **The editor and units:** Valve Hammer Editor, Your First Map, Dimensions, Dimensions (Half-Life 2 and Counter-Strike: Source), Tool textures (Source), World brush, Func instance
- **Compiling and leaks:** Leak, Compile Errors, VBSP, VVIS, VRAD
- **Visibility and optimization:** VIS optimization, Visleaf, Func detail, Hint brush, Areaportal, Func areaportal, Func areaportalwindow, Func occluder, Func lod, Func viscluster
- **Doors and moving parts:** Door creation, Func door, Func door rotating, Prop door rotating, Func button, Opening doors with func button, Func movelinear, Func rotating, Func tracktrain, Path track
- **Stairs and ladders:** Working ladders, Func ladder, Brush ladders
- **Terrain:** Displacement, Creating Holes in Displacements, Displacement Grass
- **Lighting:** Lighting, Light, Light spot, Light environment, Info lighting, Lightmap, Point spotlight, Env lightglow, Env sprite
- **HDR and cubemaps:** HDR, HDR Lighting Basics, Env tonemap controller, Env cubemap, Parallax Corrected Cubemaps
- **Water and canals:** Adding water, Water (shader), Moving water (Source)
- **Sky and fog:** 3D Skybox, Sky camera, Skybox (2D), Env fog controller, Fog tutorial
- **Props:** Prop Types Overview, Prop static, Prop physics, Prop dynamic, Prop physics override, Func physbox, Phys constraint, Keyframe rope
- **Surfaces:** Decals, Info overlay, Hammer Overlay Tool, Infodecal, LightmappedGeneric, Func breakable surf, Breakable Glass, Func breakable
- **Sound:** Soundscape, Env soundscape, Ambient generic, DSP
- **Logic and I/O:** Inputs and Outputs, Logic relay, Logic auto, Math counter, Point template, Trigger once, Trigger multiple, Trigger teleport, Env shake, Env fade, Game text
- **NPC paths and nodes:** Nodegraph, Info node, Info node hint, Info node air hint, Info node link, Info node link controller, Assault, Ai goal standoff
- **NPC scenes:** Scripted sequence, Logic choreographed scene, Choreography creation, Npc template maker, Npc maker
- **Combine and citizens:** Npc combine s, Npc metropolice, Npc cscanner, Npc manhack, Npc turret floor, Npc rollermine, Npc strider, Npc helicopter, Npc combinegunship, Npc citizen
- **Effects:** Info particle system, Env smokestack, Env fire, Env spark, Env laser, Env beam, Func dustcloud, Func smokevolume, Env wind
- **Cameras and screens:** Point camera, Point viewcontrol, Env screenoverlay
- **Garry's Mod itself:** Garry's Mod, Garry's Mod level design, Gameinfo.txt/Garry's Mod, Info player start, Info player deathmatch

The wiki covers maps and the engine; Garry's Mod's Lua (the gamemode's own code) is not in it.
