# The Advisor screens (`sv_livingcity_advisors.lua`, `cl_livingcity_advisors.lua`, `entities/lc_advisorscreen.lua`)

The owner, 22 November, approving the ideas of 21 November (lesson `valve-overseer-on-screens`: the Advisor is only ever a face on a screen). The Administrator asks the Combine's Advisors for help and reports to them.

- **The screen.** Miscount Editor > Fixture: Advisor screen, on a wall in her office, facing you. A Combine wall monitor showing the Advisor's dark shape against a slow pulse, red and quicker while her report is due. **Until one is placed, there are no Advisors**: nothing below happens and her menu has no entry for them.
- **Her menu.** E on the screen, or F2 > City orders > The Advisors ("(report due)" when it is). Its title says their patience in words: "The Advisors are patient / growing impatient / out of patience". Units and everyone else pressing E get only the screen's refusal sound.
- **Who.** A player whose faction is the Administrator; with nobody playing her, the city's own Administrator does it all by itself.

## Asking

| Request | What comes | Patience |
|---|---|---|
| Overwatch troops | an Overwatch drop (as `LC.StartOverwatchDrop`: the landing zone job and all) | 30 |
| A supply drop | a supply drop (`LC.StartSupplyDrop`) | 20 |
| More Civil Protection | 3 more units on the streets for 20 minutes, and 3 more in its reserve | 20 |

- Asked while the city is calm (sociostability green, no civil unrest), it costs half as much again.
- Asked again within 15 minutes, or while they are out of patience: refused, and pestering costs 5.
- Something already coming is greyed on her menu.
- The city's own asks only while they are patient, at most every 30 minutes: troops in unrest, supplies when the stores are low, units when the city is uneasy.

## Their patience

- Hidden (0 to 100), never shown as a number. Starts at 70; patient from 60, growing impatient from 20, out of patience below. Comes back 30 a city day (`lc_day_minutes`).
- Kept with the state of the city (`data/livingcity/<map>_city.json`, under `advisors`), with the night count.

## Reporting in

- Every third night the Advisors call for her report (one line: "The Advisors await your report."), due by the next nightfall.
- She tells them the truth about the unrest (all is calm, there is unease, there is unrest, the city is in revolt) or lies, saying it is calmer. The truth pleases them while the city is calm (+12, +6) and costs while it is not (-2, -8). A lie gets what the calmer report would have got; every night until the next call it may come out (a fifth of a chance for each step it hid), and then it costs 10, plus 10 a step.
- The city's own reports by itself: honestly, or a step calmer when the city is in unrest and her hold is weak (authority under 40, or their patience under 40).
- How unsettled the city is, as they see it: sociostability yellow, uneasy; red, unrest; black, revolt; civil unrest makes it unrest at least (revolt with red); morale under 30 makes it uneasy at least.

## A missed report, or their patience run out

1. The city's rations are cut for half a city day: citizens get short packets (units keep theirs) and wait half as long again between them. The PA says so.
2. Again before their patience is back to patient: an Overwatch Elite stands watch near her office (her desk or office door, else the screen) for 20 minutes.
3. Again: a player Administrator is removed from the post (a citizen again); the city's own is replaced, with a new name if she has one (`lc_administrator_name` set; the owner naming her again wins). Then it starts over at 50.

- A missed report costs 20 and counts as a failure itself. Patience back to patient clears past failures.
- Nothing happens during her last stand or an ending.

## Settings, tests

- `lc_advisors` 1/0 (on). No new items or commands.
- Tests `Nov22_AdvisorTests`; the client smoke test checks her menu, E on the screen and the screen's drawing.
