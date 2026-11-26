# A Combine APC on patrol (`sv_livingcity_apc.lua`)

The owner, 20 November: "An APC on patrol: at most 1 at a time", keeping to the roads; its turret (no missiles) fires at "a rebel seen in open rebel garb, or a commander" and follows on the road; for citizens (or rebels dressed as citizens) it drives as near as the road allows and "an overwatch NPC would pop out ... and demand to see their travel permit", arresting or killing who has none; with its crew dead it stands "undriven for a while and maybe can then be salvaged/scrapped/hacked". And of how it knows the roads, 25 November: "can you just make the roads on the canal ring have some sort of path for the APC that runs along the center of the road?"

A driveable APC for players is a later wish: nothing of it is built.

## What happens

- **When:** while the city runs and the map has a route, every `lc_apc_minutes` (20; the first one sooner). Never two at once. It comes out at a route mark nobody can see, drives one or two laps and is taken away again once nobody is looking (after four minutes of trying, regardless; fifteen minutes out is its longest).
- **Driving:** the Combine APC as a solid prop the server moves from mark to mark at about 220 a second, engine running. It never leaves its marks. A player in front of it: it stops, sounds its horn every five seconds and waits however long. One of the city's NPCs in front: it waits six seconds, then drives on.
- **Rebels:** a Resistance player in open rebel garb (a Fighter or higher not passing as a citizen, or anyone dressed as a fighter), a rebel fighter NPC not acting casual, the Resistance's Commander whatever he wears (but not in a unit's uniform), and anyone who shot at it or its soldier: within about 1500 and in sight, its gun fires bursts of six pulse rounds (8 damage each) and it drives, a little faster, to the route mark nearest them by the shorter way round. It stops there: it does not come off the road.
- **Papers:** a citizen, or a rebel it takes for one, within 600 and in sight: it drives to the mark nearest them, an Overwatch soldier steps out beside it, says "Citizen" or "Apply" and walks up. The player gets one notice ("Papers", "Show your travel permit: stand still."). Nothing else is written.
  - With a travel permit: waved on. The permit is not taken.
  - Without: wanted for "No travel permit" and taken in the way any unit takes someone in (`LC.NPCTakesIn`: the struggle, the walk to the cells or the cuffs on the street). If he walks them to the cells himself he stays in the city as one of its own soldiers.
  - Who moves more than 450 from where they stood, pulls a gun or changes into rebel gear: the soldier goes after them and the APC's gun opens up on them for a minute.
  - One check a player every ten minutes. The soldier walks back and is taken off at the APC, and it drives on.
- **The crew:** 600 health. A player's or an NPC's bullets do a tenth, their other weapons a quarter, explosives double (whoever set them off), and nothing else hurts it (a door, a falling crate); an IED within 260 kills the crew outright, within 520 takes half. Crew dead: it stops where it is, its engine dies, it smokes for ten minutes and is then cleared away (and the next patrol is a full wait off). While it stands there no other comes.
- **Salvage:** a Resistance player within reach of the dead APC presses E and keeps still for 8 seconds (the usual bar): 6 scrap metal and 2 boxes of SMG rounds, once. A minute later it is cleared away.

## The route

- **The map's names:** `info_target`s named `lc_apc_route_000`, `lc_apc_route_001`, ... taken in name order, 8 over the road. The canal ring's street has them along the middle of its roadway, one at most every 512 and one at every corner (`_dev/tools/map_corridor.py`, `apc_route`: 124 on the ring, and 9 more numbered from 900 on the first canal's stretch of the ring road, which closes the loop when both pieces are in the map).
- **The Miscount Editor**, on a map without them: "Point: APC route (place them in order along the middle of the road; # is the order)", in the "Civil Protection and the Combine" folder beside her APC point. Shown as APC ROUTE. Points with the same # go in the order they were placed.
- **A loop or not:** the last mark within 1500 of the first: it goes round and round. Else it drives there and back.
- The map's marks win when a map has two or more; the editor's points are read only when it has none.

## Testing

F4 > Factions > Admin: testing tools > Testing alone (superadmins) > The roads: "APC: send one now" (it comes out about 1500 along its route from you, heading your way; it says what is missing) and "APC: remove it".

## Settings

- `lc_apc` (1): 0 turns patrols off and takes away the one that is out.
- `lc_apc_minutes` (20): minutes between one patrol and the next.

## For other code

`LC.Apc.S` (the patrol out, or nil: `ent`, `pos`, `route`, `loop`, `hp`, `target`, `papers`, `dead`, `salvaged`), `LC.Apc.Send(by)`, `LC.Apc.Remove()`, `LC.Apc.Route()` (the marks and whether they loop), `LC.Apc.Hostile(ent)`, `LC.Apc.Damage(n, by)`, `LC.Apc.SALVAGE`. The prop is named `lc_apc_patrol` and has `lcApc = true`; dead, its `lc_apc_dead` is set. Its soldier's state has `apcCrew` and `apcPapers` (the player he was sent to: `LC.CopProvoked` does not count them as crowding him). Hooks: `LivingCityApcOut(ent)`, `LivingCityApcPapers(ply, hasPermit)`, `LivingCityApcCrewDead(ent, by)`, `LivingCityApcSalvaged(ply, ent)`.

## Tests

`Nov25_ApcTests` in `_dev/tests.lua` (`python3 _dev/run_section.py --unit Nov25_ApcTests`): the route's order, loop and editor points; one at a time; driving the marks and the corner; stopping for a player; leaving; the two settings and a stopped city; who its gun fires at and who not; following on the road by the shorter way; papers with and without a permit, the ten minutes, the runner; bullets, explosives, the IED, the dead APC, the salvage, the clearing away; the two staff buttons.

The map side: `python3 map_build.py chain --layout map_layouts/ring.txt --out X.vmf` (from `_dev/tools`) passes and writes the marks; a mark that is not over the street fails the build.

## Not verified without the real game

- How it looks moving: a prop set to a new place every tick should glide, but only the game shows it. Its nose is turned by the same -90 as the Administrator's APC.
- That it is solid to players while it moves, and that nobody is pushed into a wall or caught inside it when it turns on the spot.
- The sounds: the engine loop (`vehicles/apc/apc_cruise_loop3.wav`), the horn (`ambient/alarms/apc_alarm_pass1.wav`), the shutdown, the gun (`weapons/ar2/fire1.wav`).
- That bullets, grenades and rockets reach it at all (a prop hears of damage only if the engine tells it: it is asked to, `m_takedamage`). The IED does not depend on this.
- The smoke over a dead one (`env_smokestack`).
- The tracers, and whether its fire from 118 over the road clears its own hull.
- The soldier's walk to a player and back on the real map's paths (he is given 30 seconds to reach them and 15 to get back).
- The ring's rail bridge was raised to about 280 over the road on 26 November (the owner), so the APC (137 tall) passes under it. Nothing else is in its way on the ring's route.
- It does not tilt on a slope: the ring's road is level.
