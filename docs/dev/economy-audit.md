# Credits and Civil Standing: an audit (7 November 2026)

The owner asked: "Can we do an audit of credits and civil standing earnings from all the jobs/quests and such? I only got 15 credits for an infestation cleanup job." This is what the code does today. Nothing here was changed; what to change is the owner's call (see the end).

Paths are relative to `gamemodes/livingcity/gamemode/modules/server/` unless they start with `shared/`.

## How pay is computed (the root of the complaint)

- `LC.AddCredits` and `LC.AddStanding` are in `sv_livingcity_economy.lua:38` and `:82`. Standing is clamped to -1000..1000, and an ending never costs standing.
- Every board job pays through one hook, `sv_livingcity_economy.lua:118-133`:
  - Union shift (`q.chain == "shift"`): `lc_shift_pay` = **15** credits, times the loyalty or admin multiplier, plus **+5** standing.
  - Rehab chain: **+40** standing, no credits.
  - Resistance Operations and the `insidework` chain: **10** credits, "paid quietly". Zombie Urges: 0.
  - Any other chain (stories): **10** credits, no message, no standing.
  - Directives, Protocols, Agenda and Assignments: `lc_directive_pay` = **10** credits plus **+3** standing.
- A quest's `reward =` field is **XP only** (`sv_livingcity_quests.lua:710-712`). The owner of the quest gets the full amount and squad members get 75%. Credits are flat and ignore `reward` completely.
- Shift multiplier: Trusted (150 standing) x1.10, Exemplary (400) x1.25 (`sv_livingcity_loyalty.lua:32,54`). An admin "bonus job" adds x1.5 for an hour (`sv_livingcity_cityadmin.lua:251-255,323`).
- A finished shift also gives 1 ration card, or 2 at Exemplary (`sv_livingcity_work.lua:1447-1465`).

**The infestation cleanup job:** Infestation Cleanup (`shared/sh_livingcity_jobs.lua:46`, shift at `sv_livingcity_work.lua:548-584`) is an ordinary Union shift. It pays **15 credits, +5 standing**, 30 XP, plus about 15 XP from the cleanup actions, plus 1 ration card. The only extra is that it counts as 2 shifts toward joining CP (`sv_livingcity_work.lua:1455`). Its pay is the same as a litter sweep's.

## Earnings

| Source | Who | Credits | Standing | XP | File:line |
|---|---|---|---|---|---|
| Starting balance | new player | 20 | 0 | | economy.lua:26 |
| Union shift, any job (litter sweep, cleanup, medic, etc.) | citizen | 15 (16 Trusted, 19 Exemplary, x1.5 admin bonus) | +5 | 10 to 30 per shift (cleanup 30, litter 15, headcrab 10+3/spot) | economy.lua:123-124; work.lua:249-1400 |
| Infestation Cleanup action XP | citizen | 0 | 0 | +3 per growth killed, +2 per waste unit | cleanup.lua:390,683 |
| Job hands-on game bonus | citizen | about 0 to 20 per game (factory +1/+2 per part, triage 4/saved +6, courier 8+6+2) | | | jobgames.lua:107-110; moregames.lua:193-601 |
| Coins found in rubbish (sanitation game) | citizen | 3 to 8 | | | jobgames.lua:251-252 |
| Sanitation: scrub a mess | sanitation job | 5 | | | hygiene.lua:312,320 |
| Block Warden report that holds up (45%) | warden | 10 | +15 | | work.lua:603-604 |
| Block Warden: quiet patrol | warden | 0 | +3 | | work.lua:613 |
| Rehab community service | standing below 0 | 0 | +40 | | economy.lua:121 |
| Directive, Protocol, Agenda, Assignment | CP/OTA/admin/citizen | 10 | +3 | 10 to 55 (Containment 45, Retake 55, Patrol 15+5/stop) | economy.lua:130-131; quests.lua:1370-2942 |
| Resistance Operation | resistance | 10 | 0 | 20 to 50 | economy.lua:126 |
| Gun run (extra) | resistance | +60 (on top of the 10) | | 30 | quests.lua:1805 |
| Story chain step | any | 10 (silent) | 0 | 10 to 60 | economy.lua:128; stories.lua:132-1586 |
| Foreman's cut of a work order | foreman | max(5, 50% of the job's XP reward) | +1 | | resistanceops.lua:689-694 |
| Containment pay (kill infested) | CP only | 3 per kill, cap 60 per payout | | | territory.lua:542,557,574-575 |
| Supply drop secured | CP near crate | 40 | | 15 | convoy.lua:52,285-286 |
| CP duty allocation (every ration interval, 600 s) | CP | 8 + (rank-1) | | | cp.lua:967,977,982 |
| Resistance lab shut down | CP | 30 | +10 | 15 | lab.lua:457-459 |
| Black market busted | CP | 20 | +10 | | underground.lua:1438-1440 |
| Contraband seizure bonus | searcher | 5 per item | | | underground.lua:684 |
| CP supply cache | CP | | | 10 | cpsupply.lua:168 |
| Forcefield repaired | any | 15 | | | checkpoints.lua:689 |
| Transformer power restored | maintenance | 15 | +5 | | power.lua:254-255 |
| Door rehung | maintenance | 10 | | | kick.lua:42,392 |
| Cremation, per body | mortician | 6 | | | mortuary.lua:20,109 |
| Letter delivered | courier | 4 | | | mail.lua:150 |
| Reclamation (scrap 2, can/bottle 1) | non-CP | up to 40 per hour | +1 per 4 items | | salvage.lua:49,359,387-389 |
| Morning exercise | citizen | 5 if gain > 0 | +2 to +10 | | exercise.lua:61,1275-1287 |
| Led the morning drill | leader | | +10 | | exercise.lua:1296 |
| Informant tip on a player (true) | any | 25 | +5 | | resistanceops.lua:267-268 |
| Inform on a rebel NPC | any | | +5, plus +10 from the reports counter = 15 | | talk.lua:285; economy.lua:160 |
| Reported anticitizen activity (counter) | any | | +10 per report | | economy.lua:160 |
| Scanner pilot report | non-CP pilot | | up to 100 per 10 min | XP for CP | scanner.lua:57,525-529 |
| Compliance tick, every 10 min | everyone not wanted | | +2 (+10 if below 0) | | economy.lua:164-171 |
| Ration collected | citizen | | +1 | | survival.lua:1166 |
| Revive someone | non-CP | | +2 | | rp.lua:545 |
| Clean graffiti | citizen / CP | | +3 / 0 | CP 4 | scavenge.lua:574-578 |
| Mail game reports | courier | | +1 / +4 | | moregames.lua:244-247 |
| Morgue / laundry / clerk / radio games | job | | +1 or +2 | | moregames.lua:580,683,1002; jobgames.lua:786 |
| CP loyalty points | CP awards | | up to +10 (+25 officer) per 2 min | | cp.lua:213-222 |
| Administrator commend | admin | | +1 to +25 (default 15), 5 per day | | cityadmin.lua:331-333 |
| Commended for exemplary conduct | auto | | +5 | | loyalty.lua:110 |
| Cooperate under interrogation | prisoner | | +50 | | custody.lua:74,146 |
| Release after serving time | prisoner below 0 | | +100 + 25% of the deficit (+75 if surrendered), never above 0 | | economy.lua:145-153 |
| Pickpocket success | any | 2 to 9 | | | talk.lua:258-261 |
| Loot a body | any | loot.credits | | | bodies.lua:288-289 |
| Combine data decoded (heist) | resistance | 50, or 150 for the master terminal | | | heist.lua:237 |
| Stall takings | stall owner | sale prices | | | storage.lua:401 |

## Penalties

| Source | Who | Credits | Standing | File:line |
|---|---|---|---|---|
| Wanted (generic offence) | any | | -25 | economy.lua:157 |
| Destroying / damaging city property | any | | -50 / -10 | economy.lua:156 |
| Conduct violation (strike) | any | | -50 | economy.lua:154 |
| Out after curfew warning | any | | -5 | economy.lua:158 |
| Incarcerated | any | | -40 | economy.lua:136 |
| Escaped custody | any | | -60 | economy.lua:140 |
| Street detention fine | any | -25 (capped at balance) | | prison.lua:38,283-284 |
| Stalker freed: standing floored | ex-stalker | | set to -50 if below | custody.lua:335 |
| Contraband confiscated | searched player | | -10 per item | underground.lua:679 |
| Contraband in your residence | resident | | -40 | underground.lua:1257 |
| Contraband found in your block (raid) | resident | | -25 per item | raids.lua:101 |
| False informant report | any | | -5 | resistanceops.lua:271 |
| Inform on a non-rebel NPC | any | | -5 | talk.lua:296 |
| Warden report that came to nothing (55%) | warden | | -10 | work.lua:607 |
| Skipped morning exercise | citizen | | -10, and the next ration is withheld | exercise.lua:1299 |
| Poor showing at exercise | citizen | | -5 | exercise.lua:1281 |
| Insider: record lost / supplies skimmed | insider | | -25 / -10 | insider.lua:58,143,161 |
| Seen taking notes on CP | any | | -10 | funding.lua:106 |
| Escort mistakes | CP escort | | -10, -15, -5 | escort.lua:403,420,530 |
| No papers at intake check | any | | -2 | intake.lua:659 |
| Goods missing on your shift | ration worker | -2 per item (pay) | -5 per item | jobgames.lua:518-520 |
| Job game mistakes | worker | -1 to -4 (pay) | -2 to -5 | jobgames.lua:479-804; moregames.lua:257,586,677,790 |
| CP loyalty deduction / admin censure | target | | up to -25 | cp.lua:222; cityadmin.lua:333 |
| Union levy | holdings above 2000 | -10% of the excess every 30 min | | progress.lua:44-46,223-232 |
| Ration docking near Resistance activity | citizens within 1500 | lose the next ration (no credits) | | rations.lua:20-50 |
| Replacement papers | any | -10 | | intake.lua:60,382 |
| Rent | renter | -50 per period | | business.lua:32,187 |
| Vending can | any | -2 | | survival.lua:46,902,949 |
| Lab work / new face | resistance | 0.6 x black market price / -300 | | lab.lua:38-39,275,366 |

## Outliers and inconsistencies

1. **Danger is not paid.** Infestation Cleanup (900 s limit, inside the infestation) pays 15 credits, the same as a 420 s litter sweep (`sv_livingcity_work.lua:249` vs `:568`). Its only bonus is counting double toward joining CP. The CP guards on the same job earn 3 credits per infested killed (up to 60), so the guard can make 4 times what the worker makes.
2. **Credits ignore difficulty.** Every Directive pays a flat 10. Containment (45 XP, 20 min, squad of 6) pays less than a 15-credit Union shift, and the same as "Review the CP units" (15 XP). The `reward` field only scales XP.
3. **"No reward" still pays.** Setting `q.reward = 0` or halving it only affects XP. The flat 10 credits are still paid on success, for example the supply run without the supplies (`sv_livingcity_quests.lua:1795`), which says "no reward"; "another unit arrested them first, half the reward" (`:1081`); the zeroed story steps (`sv_livingcity_stories.lua:96,288,341,909,1149`).
4. **Foreman's cut uses XP as credits.** It is 50% of `q.reward` (`sv_livingcity_resistanceops.lua:691`). A cleanup work order (30 XP) gives the foreman 15 credits, the same as the worker's whole pay, for doing nothing.
5. **Standing sources are lopsided.** A scanner pilot can earn up to 100 standing every 10 minutes (`sv_livingcity_scanner.lua:57`), and one cooperation in custody gives +50. A Union shift gives +5. Exemplary (400) takes about 80 shifts, or about 33 hours of compliance ticks, but 40 minutes of scanner snitching.
6. **Story chains pay silently.** The `elseif q.chain` branch pays 10 credits with no "why" text, so no chat line, and no standing (`sv_livingcity_economy.lua:128`). Players will not see that they were paid.
7. **Duplicate standing for informing.** `talk.lua:285` adds +5 and the reports counter adds +10 (`sv_livingcity_economy.lua:160`). The message hardcodes "+15". It works, but changing either one silently breaks the text.
8. **Morning exercise is a better wage per minute** (+5 credits, up to +10 standing) than a cleanup shift, with no risk.
9. **Gun run** pays 70 credits in total (10 + 60) and black market trade pays freely, so Resistance income dwarfs a citizen's 15 per shift.

## Union shift pay against shop prices

Base shift is 15 credits (Trusted 16, Exemplary 19; with the admin bonus 23 / 25 / 28).

| Item | Price | Shifts at 15 | File:line |
|---|---|---|---|
| Ration (Commissary) | 5 | 0.3 (a shift also gives a ration card) | shared/sh_livingcity_shop.lua:345 |
| Fishing line | 15 | 1.0 | shop.lua:365 |
| Weedkiller (issued free to cleanup) | 15 | 1.0 | shop.lua:350 |
| Cuffs (2), black market | 20 | 1.3 | shop.lua:405 |
| Health vial (needs 150 standing) | 25 | 1.7 | shop.lua:354 |
| Medical kit (needs 400 standing) | 50 | 3.3 | shop.lua:357 |
| Rent, one period | 50 | 3.3 | business.lua:32 |
| Bypass charge | 70 | 4.7 | shop.lua:395 |
| CP uniform, black market | 160 | 10.7 | shop.lua:397 |
| Multitool | 250 | 16.7 | shop.lua:400 |
| New face (surgery) | 300 | 20 | lab.lua:39 |

## What would fix the complaint (the owner's call)

The base wage is set by two values, `lc_shift_pay` (15) and `lc_directive_pay` (10). Either:

- per-job or per-quest credit pay (derive credits from the quest's `reward`, or give each Union job a pay multiplier: a hazard rate for Infestation Cleanup), or
- a hazard bonus paid when the cleanup shift finishes.

Both change what players are paid today, so they wait for a yes.
