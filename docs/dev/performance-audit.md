# Server performance audit (7 November)

A look through every repeating piece of the gamemode for work the server does more often than it needs to, with nothing players or the owner rely on changed: no setting, default, command or timing.

## How it was looked at

- Every `Think` and `Tick` hook, every repeating `LivingCity...` timer under a second, the per-player move hooks (`SetupMove`, `StartCommand`) and the client's per-frame hooks (`HUDPaint`, `Post/PreDraw...`, `CalcView`, `PreDrawHalos`) were listed and read.
- A load run on the offline test stub (84 NPCs, 24 players, 60 seconds) timed each timer through `LC.TimerPerf` (the same numbers as `lc_profile`) and counted the engine calls each line makes (traces, entity searches, player lists). The stub's engine calls are free, so this shows Lua time and call volume, not the engine's own cost.

## What was already in good shape

Most of the obvious traps were dealt with in earlier passes and are not repeated here: the NPC loop has a time budget and thinks less for NPCs far from everyone (`lc_think_budget_ms`, `lc_lod_distance`); calm NPCs nobody can see are put to sleep (`lc_npc_sleep`); who can see what is worked out once per tick (`LC.ViewerPositions`, `LC.IsSeen`); NPC relationships only touch the engine when they change; entity lists by class are kept as they come and go (`LC.EntsOf`); zones are indexed by kind; doors are found through a grid; saved player data is read from memory (`LC.CachePData`); the timers are staggered across the second (`lc_stagger_timers`); data files are written only when something changed. Client fonts and materials are made once; client entity searches are already throttled to once a second or so.

## What changed

- `LC.Players()` (sh_livingcity_cache.lua): every player for a loop, through the game's own `player.Iterator` where it has one (one kept list, no new table per call), and `ipairs(player.GetAll())` otherwise (tests, an old game). Same players, same order. Used in the loops that run every tick, every tenth of a second, or once per NPC on its turn: the "move along" check each Civil Protection NPC makes on its turn, scanners sparing units, who is looking (once a tick), brushing past citizens, making way, Annabelle (every tick), workout boosts, ladder learning, stamina, the kick hint, the rebel-ground edge, acts, tips, NPC memories, guns in the street; and on the client the hands-up pose shift, the flies and the bed check (each every frame). Together these made a few hundred throwaway tables a second on the server with 20 to 60 players, and three a frame on every client.
- Barnacles eating weedkiller (sv_livingcity_cleanup.lua): the barnacles come from `LC.EntsOf("npc_barnacle")` instead of a search of every entity in the map twice a second.
- The lag monitor (sv_livingcity_lagwatch.lua, only while someone has it open): one list of every entity a second instead of two.
- The Stand-up ending's cone hats (client): the white material is looked up once, not every frame.
- Tests: `_dev/tests.lua`, "Quick lookups (and smoke)", checks `LC.Players` both ways and the barnacle list.

## The costliest things left (rough order)

1. **The engine's own NPC AI and physics** for 50 to 100+ NPCs. By far the largest cost on the server, and the reason for `lc_npc_budget`, the sleep and the think budget. Nothing in the Lua comes close.
2. **The NPC loop** (`LivingCityThink`, up to 2.5 ms each tenth of a second): about 60 percent of all the gamemode's Lua time in the load run. Already budgeted.
3. **`LC.IsSeen` traces.** Each call can trace from every player facing the spot within 6000 units. It is asked for each NPC that's far from everyone on its turn (to sleep or wake it), for withdrawing squads, spawn spots and more: with 100 NPCs and 40 players that can reach a couple of thousand cheap traces a second. Keeping each NPC's answer for a second would cut this a lot, but an NPC could then sleep or vanish up to a second after someone turned to look: listed, not done.
4. **`LC.SeenBySecurity`** walks every NPC and traces from each unit in range; it's asked per player by several timers (heat cooling every 2 s, guns in the street every 0.5 s while armed, Freq 7 every 0.25 s while listening). Fine with a few units; grows as players x units. A per-player answer kept for a fraction of a second would change when a crime is noticed: listed.
5. **Unstick** (`LivingCityUnstick`): one hull trace per living player every second. Cheap each, but steady.
6. **Route checks** (`LC.Walkable`): a hull trace per step when a route is planned; the biggest trace caller in the load run after Unstick.
7. **NPC memories** (`LivingCityMemory`): an entity search of 220 units round each player every 2 seconds.
8. **Client, during job games:** the sweeping game and the job marks search every entity within 900 to 1200 units of the player every frame (`PreDrawHalos`, `PostDrawTranslucentRenderables`), reading networked values from each. Keeping the list for a fifth of a second would be invisible in practice, but the files are being worked on, so it's listed rather than done.
9. **Client HUD colours:** many HUD and 3D2D hooks make `Color(...)` tables every frame. Small each; hoisting them touches many lines of UI code other work is changing, so it's left.

`GetConVar("name")` inside functions was looked at too: the game keeps its own table of convars by name, so these are a table lookup, not a search, and were left alone.

## Client pass (7 November)

Same rule as above: nothing a player sees changes. Every per-frame client hook (`HUDPaint`, `HUDPaintBackground`, `PostDraw/PreDraw...Renderables`, `PreDrawHalos`, `RenderScreenspaceEffects`, `CalcView`, `Think`, `Post/PrePlayerDraw`, `HUDDrawTargetID`, `RenderScene`) in `modules/client`, the shared files and the entities' and weapons' `Draw`, `DrawTranslucent`, `DrawHUD` and client `Think` was listed and read for entity searches, fonts, materials, text measuring and objects made fresh each frame.

### What changed

- **Job games** (cl_livingcity_jobgames.lua, cl_livingcity_moregames.lua): the sweep's outlines, the cart's count, the triage labels and the job marks searched every entity within 900 to 1200 units on every frame (the 3D labels more than once a frame, as `PostDrawTranslucentRenderables` runs per view). Each list is now kept for a fifth of a second and searched again at once if anything on it is gone; outlines and labels still draw every frame. At 60 fps that is about 5 searches a second per list instead of 60 to 120, each of which read networked values from every prop, NPC and player in range.
- **The "what you can do" panel** (cl_livingcity_context.lua, on screen nearly all the time): it made a new colour for every line it drew, every frame, measured each key's width every frame and capitalised each title every frame. The faint colours, key widths and capitalised titles are now kept. Roughly 20 to 40 tables and a few text measurements a frame gone.
- **The recall box** (cl_livingcity_directives.lua): each line's width is measured once (only the time left changes, once a second).
- **Fixed colours, offsets and angles** (`Color(...)`, `Vector(...)`, `Angle(...)` with only numbers in them) inside per-frame drawing are made once when the file loads, in 50-odd files: the main HUD banners, needs and quest panels, scanner, stealth, arrest, rent, grigori, rp, kick, dreams, intake, terminal screens, the editor overlay, the endings, and the entities' world labels (`lc_stall`, `lc_supply`, `lc_recycler`, `lc_note`, `lc_powerbank`, `lc_item`, `lc_incinerator`, `lc_jammer`, `lc_energizer`, ...) and weapon HUDs. Only ones never changed afterwards were moved (each is passed straight to a draw call or added to a position). A typical frame with the HUD up and a few labelled entities nearby made 50 to 150 of these; now close to none.
- **Smaller ones:** the water ending's monk microphones look the monks up twice a second instead of every frame; the traitor labels walk the players through `LC.Players()` (no new list each frame); the editor's zone edges use one shared lift instead of two new vectors per segment.

Checked with `_dev/client_smoke.py` (CLIENT SMOKE PASS), a compile of every changed file, and the job-game hooks driven in the client stub (searches per frame counted, a removed piece of rubbish looked for again at once).

### What's left (client)

- **Colours made from a changing alpha** (pulses, fades: `Color(r, g, b, alpha)` each frame) and `Angle(0, ang.y - 90, 90)` for each 3D label: small, and caching them needs a table per value.
- **Menu windows' `Paint` functions** build colours each frame while a window is open: only while open, and spread over many UI files; left alone.
- **Left alone on purpose, because other work is changing those lines:** the war HUD and territory drawing (cl_livingcity_war.lua), the name and job labels over people (`HUDDrawTargetID` in cl_livingcity_factions.lua) and the hijacked city screen (cl_livingcity_resistance.lua). Each makes a few colours a frame.
- **The terminal screen's layout** (cl_livingcity_screens.lua) is rebuilt every frame while one is open (a small table per row). Keeping it would mean tracking when the rows or page change: left.
- Searches that were already throttled (the overlay's NPC list once a second, sleepers' eyes once a second, the ending dancers once a second, lab smoke every 2 seconds, sympathizers every 0.4 s, rebel intel every 0.5 s) were left as they are.
