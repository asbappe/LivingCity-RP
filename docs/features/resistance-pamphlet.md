# The Resistance pamphlet

Asked for by the owner on 10 November: a pamphlet "resistance members can either give to sympathisers or leave about on purpose for people to find", with the graphic for reading it and the object and mechanic.

## The sheet

One cheap sheet folded once, run off on a hand duplicator: purple ink that didn't take evenly, a typed masthead ("READ THIS. THEN PASS IT ON."), the lambda sprayed over it in orange, two hands passing a sheet cut into the foot of the cover, thumbprints, a cup ring. The cover half lists what's inside; the other half is the page, written by hand.

- Paper: `materials/livingcity/pamphlet/rebel_paper.jpg`, made by `node _dev/posters/rebelpamphlet.js OUTDIR` (1024 x 690). Without the file the sheet is drawn plainly.
- Handwriting (the owner, 10 November: "more like humble/simple/sloppy handwriting"): the pages and the list are written in `resource/fonts/lcrebelhand.ttf`. It is Kimberly Geswein's "Covered By Your Grace" (SIL Open Font License, the text is beside it), renamed inside to one word that matches its file name so Windows, Linux and Mac all find it. Players download it like the paper; a player who gets it for the first time may need to restart the game once before it shows (until then the game uses its plain font). The masthead on the paper itself stays typed.
- Window: `OpenRebelPamphlet` in `cl_livingcity_dialog.lua` (dialog style `rebelpamphlet`).
- Words: `LC.RebelPamphletPages` in `sv_livingcity_rebelpamphlet.lua`. Six pages: The water, The ration, Who is listening, If they stop you, If you want to help, Pass it on. "If you want to help" says how a citizen really earns the Resistance's trust (food for the supply crates, selling to the quartermaster, jobs).

## The item

`rebel_pamphlet`, "Resistance pamphlet": weighs nothing, contraband (well hidden, like other papers). The quartermaster sells five for 15 credits; no dealer does. Pockets > Read opens the sheet.

The first one a citizen ever reads is worth 1 sympathy (once per player, kept in `lc_rpamphlet_read`). Civil Protection, the Administration and Resistance members gain nothing from reading.

## Handing it over

- **To a player:** F1 > their name > Hand them a Resistance pamphlet (Resistance members), or Pockets > Give as with any item.
- **To one of the city's people:** F1 > This person > Hand them a Resistance pamphlet (Resistance members). One offer per person every five minutes.
  - A sympathiser takes it.
  - Anyone else: about one in three takes it and becomes a sympathiser (the same as one brought in on rebel ground: they can be asked to keep a lookout, and so on); two in five tuck it away; one in four push it back and you keep it.
  - An informant takes it like anyone, and 20 seconds later Civil Protection hears of it (a crime).

## Leaving it about

F1 > Leave a Resistance pamphlet here (Resistance members), or the "Leave it here" line on the sheet itself (anyone holding one). It lies on the floor, bench or table in front of you (entity `lc_rebelpamphlet`).

- Anyone presses E on it to read it. A citizen or Resistance member may pocket it; Civil Protection and the Administration may confiscate it.
- When someone reads one for their first time, the member who left it is told and earns 2 XP.
- Citizens walking past sometimes read it. After three have, someone has carried it off. A reader may become a sympathiser (one in five). An informant hands it in.
- A unit walking past takes it away, and Dispatch says where on the Civil Protection radio.
- One player can have `lc_rebel_pamphlets_max` (6) lying about, the oldest going first; each stays `lc_rebel_pamphlet_minutes` (30).

## Risk and reward

Handing one over or leaving one where a unit can see you is a crime ("Distributing seditious material"), the same as pasting a poster. Unseen, a Resistance member earns 1 XP (2 for winning a sympathiser).

## Code

`sv_livingcity_rebelpamphlet.lua` (`LC.ReadRebelPamphlet`, `LC.LeaveRebelPamphlet`, `LC.GiveRebelPamphlet`, `LC.RebelPamphletsTick`, `LC.RebelPamphlets`; menu actions `givepamphlet`, `leavepamphlet` in `LC.TargetActions`; hooks `LivingCityPamphletRead`, `LivingCityPamphletLeft`, `LivingCityPamphletWon`, `LivingCityPamphletSeized`), `entities/lc_rebelpamphlet.lua`, the item and the quartermaster's line in `sh_livingcity_shop.lua`. Tests: RebelPamphletTests; the smoke test opens and paints the sheet.
