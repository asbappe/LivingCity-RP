# Supply lines to the Resistance's headquarters (`sv_livingcity_supplylines.lua`)

The owner, 22 November: "Now and then an NPC courier walks the road, or a boat comes up the canal, with food and rounds for the HQ crate. The Resistance get an escort job, Civil Protection get Stop the courier. This needs the route marked on the map, as editor points or names in the map pieces." Built 22 November; not played yet.

## What happens

- **When:** only while the headquarters is live (its flag at the top: `resistance-base.md`), every 15 to 25 minutes (`lc_supply_line_minutes` 20, give or take a quarter), one at a time. A map with no route has none.
- **By road:** a courier of the Resistance in plain clothes, unarmed, a box in both hands, steps out at the route's first point and walks it, point after point, then on to the headquarters' supply crate (along the city's paths where it has them). Shot at, or with a unit close, he runs.
- **By canal:** a canal boat with a rebel in it comes up the route on the water, moved smoothly point to point. At the last point it ties up; the boatman takes the box ashore and walks it to the crate.
- **In:** six meals into the crate, and four boxes of rounds (two pistol, one SMG, one of shells) set on top of it. The Resistance have no stock of rounds (the fund buys them as fighters are issued), so the rounds come as boxes anyone there can pick up.
- **Stopped:** killed, arrested, the boat sunk (enough rounds into it) or the boatman shot: nothing comes in. The headquarters packed, overrun or torn down while he is on the way, or 15 minutes gone by: the run is called off and he goes home.

## The jobs

Posted as the run starts, on the boards and with the usual "New job" line; nothing else is said.

- **The Resistance: "Escort the courier"** (road) **or "Meet the boat"** (canal). Get to him (marked), then see him to the crate. It counts if one of the job's people is near him as he gets in; he does not wait for anyone on the way. The courier waits at his first point for whoever takes the job, as a supply drop waits for its guards: the job is on the board for a minute, and he sets out a minute after it is taken, or at once if nobody takes it.
- **Civil Protection and Overwatch: "Stop the courier"** (both kinds). Kill or arrest him, or sink the boat or shoot the boatman: the usual pay for a job (and an anticitizen's usual 2 credits if they kill him, which the board shows). **He is marked on their job only once a unit has seen him** (a unit's player within about 90 feet with a clear line, or one of the Combine's own NPCs) **or once he is half way.** Before that the job says to find him.

## Marking a route

- **The map's names:** `info_target`s named `lc_supply_road_1`, `lc_supply_road_2`, ... (one is enough: the crate is the rest of the way) and `lc_supply_canal_1`, `lc_supply_canal_2`, ... (two at least: where the boat sets out and where it ties up, beside the bank), in that order. A canal point may sit on the water or under it: the boat floats on the surface above it.
- **The Miscount Editor:** "Point: supply line, road" and "Point: supply line, canal" (in the Resistance's folder). The # is the route; its points go in the order they are placed. Shown as SUPPLY ROAD 1 #1 (START), with a line between them.
- With several routes, each run picks one.

## Testing

F4 > Admin testing tools > Testing alone > Supplies: "Supply run to the headquarters now" (the headquarters must be live and the map have a route; it says what is missing).

## Settings (both new)

`lc_supply_lines` 1 (on) · `lc_supply_line_minutes` 20.

## For other code

`LC.SupplyLineStart(kind)` ("road", "canal" or nil: any), `LC.SupplyLineRoutes(kind)`, `LC.SupplyLines.run` (the run under way: `kind`, `state` "waiting", "boat" or "walk", `courier`, `boat`, `spotted`), `LC.SupplyLines.Thing()` (what is on its way), `LC.SupplyLines.CallOff()`; hooks `LivingCitySupplyLine(run)`, `LivingCitySupplyArrived(run, food, rounds)`, `LivingCitySupplyStopped(run, how, by)` (how: `killed`, `caught`, `sunk`, `shot`, `off`). Jobs `res_supplyescort`, `cp_supplystop`. Point kinds `supplyroad`, `supplycanal`. Tests: `Nov22_SupplyLineTests` (35); the robot players do both jobs.
