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

- While the thumper stands still (its button), antlions dig up at the burrow near it, starting 15 seconds after it stops, when a player is within 3500 units: two out at most, from a pool of four that gets one back every 25 seconds (Valve's own numbers, ep2_outland_05). Killing them buys a breather; lingering brings more.
- They go for everyone: units, rebels, citizens.
- Started again, the thumper drives off those left (the game does that itself), and after a minute any still alive dig themselves away.
- No setting, nothing on screen. For the owner to say: the numbers, and whether the rest of idea 5 (raids from outside the walls, workers, guards, bugbait) should build on this.

`LC.Antlions.Set(thumper, running)`, `.Tick()`, `.Spawn(pos)`. Tests: `Nov24_ThumperAntlionTests` (9).
