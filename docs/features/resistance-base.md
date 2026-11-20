# The Resistance's headquarters: one base at a time (`sv_livingcity_base.lua`)

The owner, 20 November: "the highest ranking Resistance player (Lieutenant or Commander) can alter the location of the resistance HQ ... which he has to visit and be present at ... it takes 5 minutes with him nearby (within 300 feet radius or so) to setup"; "setup could literally be hoisting the flag up the pole slowly"; the commander's office ("securitybank.mdl with all the camera monitors, his desk, shelves, any computers or consoles, board, even the science lab") does "not show until the base is established"; and, to stop leaders "running in a big circle around the map moving CONSTANTLY", it moves only three ways (below). Built 20 November; not played yet.

## What happens

- **Where:** any rebel territory (the zones of kind `rebel` placed with the Miscount Editor). Each territory is a possible site; only one is the headquarters.
- **Raising the flag.** The Resistance's leader (a Commander; a Lieutenant when no Commander is playing: the same rule as the leader's orders), standing in rebel territory: **F2 > Resistance > Raise the flag here**. A pole stands where he stood (330 tall in the open; **under a roof or a bridge only as tall as fits**, down to 110, so a base in the canal's shantytown shows no flag over the canal's walls) and a red flag climbs it for 5 minutes, but only while he is alive within 300 feet of it and nothing hostile (a unit, a Combine NPC, a zombie, a headcrab, an antlion) is within about 45 feet of the pole. Left alone for a minute, a half-raised flag slides back down and the pole goes. The same F2 line, pressed again, gives it up.
- **Live.** At the top the base is the headquarters and **the commander's office appears round the pole**: the security monitors, a desk, a console bench, shelves, a lab bench, servers and a board. They are the camp's own things: a held E carries them, R turns them, and where each was left at a site is kept, so each site's office is laid out once by hand and comes back like that.
- **The flag is the only message.** Nothing is written on anyone's screen: climbing is setting up, the top is live, half mast is overrun, coming down is packing or a unit tearing it down.

## The three ways a base moves

1. **Packed (their own choice).** The leader, at the live base once it has stood 10 minutes: **F2 > Resistance > Strike the flag**. It comes down over 3 minutes with him near; at the bottom the office is packed and a flag may be raised somewhere else (another 5 minutes). Pressed again while it comes down, the same line hoists it back.
2. **Ransacked (the Combine).** A Civil Protection or Overwatch unit presses E at the pole while no living Resistance player is within about 45 feet: the flag comes down in 20 seconds as long as the unit stays by it; a rebel coming back stops it and the flag goes up again. At the bottom the office is destroyed, **35 per cent of the Resistance's fund** is shared among the units there, and the Resistance has no base.
3. **Overrun (zombies, headcrabs, antlions; zombie players too).** On its ground for 45 seconds with no living rebel there: the flag drops to half mast and the base is not live. The office stays. Clear them out and stand there 20 seconds and it is live again (or strike it then). No flag goes up anywhere else while it is overrun; a unit can still tear the half-mast flag down.

## What changed for what was there before

- **The security monitors** stood in every rebel camp (19 November). With this on they are part of the office and stand only at the live base. `lc_base 0` turns the whole feature off and puts them back in every camp.
- Nothing else of the camps changes: the quartermaster, the supply crate, the fund's screen and the rest work everywhere as before. **Not built:** services that work only at the live base, the Combine learning where the base is (scouting, informers, prisoners), the Administrator's order to raid it, supply lines. Each is to be described to the owner first.

## Settings (all new)

`lc_base` 1 (on) · `lc_base_setup_time` 300 · `lc_base_pack_time` 180 · `lc_base_stay` 600 (before it may be struck) · `lc_base_radius` 4800 (300 feet: how near the leader stays) · `lc_base_core` 700 (the base's ground) · `lc_base_teardown` 20 · `lc_base_ransack_share` 35 · `lc_base_overrun` 45.

## For other code

`LC.BaseLive()` (the base's zone, or nil), `LC.BaseState()` (`raising`, `live`, `striking`, `overrun` or nil), `LC.BaseShows(zone)`, `LC.BaseRaise(ply)`, `LC.BaseStrike(ply)`, `LC.BaseOrder(ply)` (the F2 line), `LC.BaseTear(ply)`; hooks `LivingCityBaseLive(zone)`, `LivingCityBaseGone(zone, how)` (`packed`, `ransacked`, `abandoned`), `LivingCityBaseRansacked(zone, credits, unit)`. The office's list is `LC.BaseOffice`; its places are in `data/livingcity/<map>_base.json`. The flag is drawn by `cl_livingcity_base.lua` from the pole's `lc_flag_h`. Tests: `BaseTests` (32).
