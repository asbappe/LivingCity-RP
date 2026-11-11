# The city does its own work, and the city's stores

### The city does its own work

The city's own people have these jobs too, and when no player is doing the work, **they do it, with the same effects**: nobody walks across the map for nothing. **Every job is staffed:** at least one of the city's people works each Union job in a city of about a dozen, rising to four each from about a hundred (the roster plus the players), filled from the unemployed first and then from the most crowded trades; and a trade nobody on the streets is doing sends its people out first, so the city keeps itself running. When one of them picks what to do next, it's nearly always their work (`lc_npc_work_pct`, 85):

| Job | What the city's workers do |
|---|---|
| Maintenance | Fix broken streetlights; otherwise, the maintenance yard |
| Radio Repair | Fix broken loudspeakers; otherwise, the repair bench |
| Sanitation | Scrub graffiti, pick up empty cans and bottles left in the street (and dead headcrabs left lying a minute and a half), empty the bins and take the bags to the depot |
| Mortuary | Haul the dead to the incinerator (dragged, like a player does it); bag dead headcrabs left lying about a minute and a half. A dead headcrab nobody clears or takes is gone after `lc_body_time` seconds (300), once nobody is near enough to see it, the way bodies go |
| Clinic Medic | Run to a citizen who's down and get them back on their feet (not the wanted, not in a fight on rebel, infested or Combine ground), patch up wounded citizens, and at the clinic see to any player standing with them (+10 health a few seconds apart) |
| Ration Production | Carry crates of sealed packs in from the loading dock; work the sealing line |
| Factory | Carry parts from the dock and between stations, work the line |
| Courier | Collect the mail at the post office and carry it to people's doors |
| Intake Processor | Carry luggage from the platform to the housing blocks |
| Records Clerk | File at the records office (at a desk, if there's a chair near it), take papers to the checkpoint |
| Laundry | Run the machines, take pressed uniforms to the checkpoint |
| Reclamation | Clear rubble piles, carry the scrap to the reclamation point |

And **Civil Protection units take back a hijacked city screen** if no player unit does it first.

**Not inside a Combine-only zone.** The city's citizens stay out of those (the owner, 7 November), so their work in there is left alone; each zone's own stalkers clean up and repair the streetlights and loudspeakers in there instead (see editor-placing.md, Zones).

**How they carry things.** A box or a crate is held out in front in both hands, the arms bent under it; luggage hangs from a hand at the side; small things (a clipboard, a can) are in the hand.

**Players come first.** Something broken waits `lc_npc_work_grace` seconds (60) for a player before the city's crew comes for it, or `lc_npc_work_grace_players` (300) while someone with that job is on the server, so their shifts always have work. Two of the city's workers never go after the same thing. What a citizen is doing shows under their name when you look at them ("Maintenance Technician, fixing a streetlight"), and what they carry is in their hands (a crate, a letter, a suitcase, a bag of rubbish). The things they need are placed with the editor: workplaces, loading docks, rubble piles, the incinerator, bins; whatever a map hasn't got, that part of the work doesn't happen. `lc_npc_work 0` turns it off; `lc_npcwork` (admin) says how it's going, and so does the debug report.

### The city's stores

The rations the dispensers hand out come out of the city's stores (`lc_stock_max`, 400 rations), shown to everyone under the clock. **In:** a Ration Production shift (+12) or a factory shift (+8) worked by a player, the city's own ration and factory workers (a few for each task they finish), a train's freight (+15), a supply convoy (+15 for every load that wasn't stolen). **Out:** every ration handed out, and the city eating (one a minute for every `lc_stock_eat` (20) citizens out; 40 until 7 November, when the owner asked for food to be scarcer, and fifteen before that, when a city of 80 ate more than it could ever make). **Low** (under a quarter): allocations come half again as slowly, the dispenser is sometimes empty, the PA says so, and hungry people listen to the Resistance (rebel ground spreads faster). **Empty:** no rations at all (a forged card won't help either) until something comes in. **Well stocked** (over four fifths): the city's calmer. Saved per map. `lc_stockpile 0` makes rations endless again; `lc_stock [n]` (admin) shows or sets it. Editor panel, Survival and economy: the stores on or off, how much they hold, how fast the city eats, and **Fill the city's ration stores**. A dispenser that turns you away (a shortfall, too soon) doesn't try again by itself while you stand there: step away from the counter and come back.

## Clearing away (11 November)

Meat left by a dead headcrab or bird (raw, or cooked by a Cremator) and anything dropped out of a player's pockets is gone `lc_body_time` seconds (300) after it was last let go of, whether or not anyone is looking (before: only headcrabs, and only out of sight). A body goes after `lc_body_time` when nobody sees it, and a minute later even when somebody does.
