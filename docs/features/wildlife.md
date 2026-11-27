# Barnacles and antlions (`sh_livingcity_barnacle.lua`, `sv_livingcity_antlions.lua`)

## A barnacle lifts the player it has caught (24 November)

The owner, 22 November: "their tongues stick to me and they make the sound, they just don't pull me up". On a multiplayer server Half-Life 2's barnacle catches a player and never raises them. Now:

- The server notes which barnacle holds whom (ten times a second); the held player's own movement carries them up at 80 units a second to its mouth, on the server and in their own game alike, so it is smooth. They cannot walk off.
- At the mouth the barnacle's own bite is waited for two seconds; if it never bites, the server bites for it (20 a second, with its crunch).
- Kill the barnacle (or have a friend do it) and you drop.
- No setting, nothing on screen. Not seen in the real game yet.

`LC.BarnacleStep(pos, mouth, dt)`, `LC.BarnacleHoldTick()`; the holder is the player's `lc_barnacle` (NW2 entity). Tests: `Nov24_BarnacleLiftTests` (8).

(Barnacles also eat weedkiller: `docs/features/infestation-cleanup.md`.)

## Antlions at a stopped thumper (24 November)

The first small piece of the owner's long-term idea 5 (18 November: "thumpers keep them off (the Combine's, which a saboteur can switch off), they come up through sand or soft ground"). Only on a map with the thumper module (`lc_thumper_head`, `lc_thumper_burrow`: `docs/dev/canal-modules.md`); elsewhere nothing happens.

- **A trickle, not a swarm** (the owner, 27 November: "a few (NOT a continuous relentless swarm, but like 1/5 the HL2 amount) ... at a small trickle (basically one at a time) at a random player/NPC in that part of the canal, until the thumper is turned back on ... one every 15 seconds with a max or 2 alive at a time"). While a thumper stands still (its button), every 15 seconds one antlion digs up near a random player or person in **that thumper's stretch of the canal** and goes for them; two alive at most from each thumper. (Until 27 November: Valve's own numbers, two out from a pool of four at the burrow.)
- **Its stretch:** within 3500 units of the thumper, down in the canal's basin: from 64 under its burrow's floor to 192 over it (the canal's floor and the thumper's terrace, 128 up; the street over the canal, 256 up, is not in it). Nobody there: none come. Each thumper on its own: two stopped, two trickles.
- They go for everyone: units, rebels, citizens (while the Swarm's pheropods are out they are its allies instead: [the-swarm.md](the-swarm.md)).
- Started again, the thumper drives off those left (the game does that itself), and a minute later any of its antlions still alive dig themselves away.
- No setting, nothing on screen. For the owner to say: the numbers (15 seconds, two, 3500 units and the basin's heights), and whether the rest of idea 5 (raids from outside the walls, workers) should build on this (bugbait and guardians: the Swarm).

**Every copy of the module (27 November):** the canal ring has four thumpers. The first keeps the names above; the others carry a number after "thumper" (`lc_thumper2_head`, `lc_thumper2_burrow`, ...). Each name is read as `^lc_thumper(%d*)_(%w+)$` and each copy's parts go together by that number, so every thumper works as the one above, with its own burrow.

**With the Swarm** ([the-swarm.md](the-swarm.md)): while the pheropods are out, the antlions at a stopped thumper are the swarm's (the Resistance's allies); after the city falls to the swarm they are wild again, and the thumpers left stopped are broken until mended (the job "Restart the thumpers").

`LC.Antlions.Set(thumper, running)`, `.Tick()`, `.Spawn(pos, thumper)`, `.OutOf(thumper)`, `.InStretch(thumper, pos)`, `.Parse(name)`, `.Heads()`, `.PartOf(ent, part)`. Tests: `Nov24_ThumperAntlionTests` (12); two copies at once in `Nov27_SwarmTests`.

## The hive boss (25 November; `sv_livingcity_hiveboss.lua`)

The owner's long-term idea 3 ("blind, hunts by sound ... bullets barely hurt it ... spawns when much of the city is infested; killing it crashes the infestation"), with the creature the owner chose on 25 November: the Workshop NextBot **"half life alyx jeff npc/nextbot"** (id 2149660804). That addon is the creature (it hears running and jumping, walks the map's navmesh, and only explosives hurt it); the gamemode only decides when it comes, where, and what its death does.

- **Off by default** (`lc_hiveboss` 0). Staff can send one or take it away: **F4 > Factions > Admin: testing tools > Testing alone > Hive boss**.
- **Switched on** (`lc_hiveboss` 1), it comes by itself when at least half the districts are badly infested (two at least), in the placed infestation nearest the worst district, out of sight where it can; one at a time, and not again for `lc_hiveboss_minutes` (90) after one dies. Players who join then download the addon (`resource.AddWorkshop`).
- **Dead**, the infestation crashes: every placed infestation loses half of what grew from it, the furthest patches first.
- **Spores:** within 500 units of it, anyone with no gas mask coughs every few seconds (a mask in the pockets goes on by itself).
- Nothing is written on anyone's screen.
- `lc_hiveboss_class`: its entity class. Empty, the gamemode finds the installed class with "jeff" in its name.

**Where it comes up:** the map's own lair if it has one (an `info_target` named `lc_hive_boss_spot`: the cistern's island in the canal ring), else the placed infestation nearest the worst district.

**A navmesh is not path nodes.** The city's own people walk the map's path nodes (`info_node`, which our map pieces place). A NextBot cannot use those: it walks a navigation mesh, a separate file (`maps/<map>.nav`) the game itself works out from the compiled map and nobody places by hand. It is made once in the game (console: `sv_cheats 1`, `nav_generate`, then `nav_save`; or the addon's own generator window), takes some minutes, and has to be made again after every compile of the map.

**What the server needs:** the addon itself (subscribed through the server's Workshop collection, or unpacked into `garrysmod/addons/`), and a navmesh for the map (`garrysmod/maps/rp_c18_ug.nav`): without one the addon opens its own "navmesh generator" window for an admin. Not known without the real game: the class name the addon uses (hence the search by name), whether it hears a cough, whether its death is told to the game as an NPC's is (a removed boss with no health left counts too).

`LC.HiveBoss.Class()`, `.Spawn([pos])`, `.Remove()`, `.Crash()`, `.Due()`; hooks `LivingCityHiveBoss(ent)`, `LivingCityHiveBossDead(by, patchesGone)`. Tests: `Nov25_HiveBossTests` (11).
