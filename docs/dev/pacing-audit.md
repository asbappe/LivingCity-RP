# Pacing audit: announcements, events and chat notices (7 November)

The owner, 7 November: "There is the administrator, the overwatch announcer voice we made, and then the default HL2 overwatch voice. All 3 will chime in randomly for random things and the rate at which things happen and change in the city feels too fast for the pace we are aiming for; there are just constant announcements, chat notifications, noise, etc. ... I feel stressed just playing due to this."

Nothing was renamed or moved: every trigger, folder and recording works as before (`CORE.md`). Changed defaults are in the `RETUNED` table (`sv_livingcity_endings.lua`), which now also runs once every module has loaded (`InitPostEntity`), so settings made after that file (most of them) are moved too.

## The three voices, and where each one speaks from

| Voice | What it is | Where it starts | When |
|---|---|---|---|
| Overwatch, the owner's recordings | `sound/livingcity/overwatch/<trigger>N.wav` | `LC.Announce` (`sv_livingcity_events.lua`), `AnnounceSocio` (`sv_livingcity_cp.lua`), `Say` (`sv_livingcity_announcer.lua`) | any trigger he has a file for |
| The Administrator, the owner's recordings | `sound/livingcity/administrator/<trigger>[_tone]N.wav`, over the loudspeakers | the same three, `lc_announce_admin_share` (50) percent of the time when both have a line; her broadcasts (`sv_livingcity_propaganda.lua`, `lc_breen_broadcasts` 0: off) | as Overwatch, never both for one thing |
| Half-Life 2's stock Overwatch lines | `npc/overwatch/cityvoice/*_spkr.wav` | `LC.Announce` (events with no recording; responses, the PA's remarks, ration deductions, unrest ambient lines, which named a stock line outright), `AnnounceSocio` | before: whenever a caller named one, even with the owner's recording there; now: only for what the owner has no recording of |

Each player's game already played one voice at a time (`cl_livingcity.lua`, `LC_CL.QueueVoice`), 0.8 seconds apart. The server had no shared idea of who was speaking: each source kept its own gap.

## Every source, before and after

| Source | Trigger(s) | Before | After |
|---|---|---|---|
| Automatic city events | rations, sweep, curfew, raid, supply | one every `lc_event_interval` 12 min; each is an announcement, a chat explanation and a notice | every 24 min (`lc_event_interval` 24) |
| Event warnings | rations_soon, curfew_soon | 2 min before a public event | unchanged (always said) |
| Event over | ended (curfew, lockdown) + "[City] ... is over" chat | every curfew or lockdown | unchanged |
| Lockdown | lockdown | answers violence | unchanged (always said) |
| Sociostability | socio_green, socio_yellow, socio_red | voice + 2 chat lines at every change; an event start or end usually flips it too (sweep, raid, curfew make it yellow), so it came on top of the event's own announcement, and a flicker back and forth was said each time | at most once in 2 min (red, or the Administrator setting it: at once); a change in between is said when the time is up only if it still stands (a flicker is never said); green or yellow straight after another announcement: chat only, no voice |
| Response squads | response (`sv_livingcity_response.lua`, `sv_livingcity_rebels.lua`, `sv_livingcity_war.lua`) | every squad sent; always the stock line (named outright) | once in 3 min; the owner's `response` recordings first |
| The PA's remarks | ambient: someone wanted, a long sentence, a crime reported, a cop chasing (`LC.AnnounceLine`) | one in 45 s, 30 s after anything; always stock | one in 3 min, only after `lc_announce_quiet` of quiet; the owner's `ambient` recordings first |
| Ration deduction | ambient, after a rebel raid | one a minute; stock | only after `lc_announce_quiet` of quiet (the people docked still get their own chat line); the owner's `ambient` recordings first |
| Random ambient lines | ambient (`lc_announce_interval`) | 0: off | off; if turned on, only after quiet |
| Time of day | dawn, day, dusk, night | every phase change; day and dusk waited `lc_announce_quiet` 60 s, dawn and night never | all four wait for 90 s of quiet |
| Skirmishes | skirmish_raid, skirmish_sweep | one every `lc_skirmish_interval` 25 min | every 50 min; still a routine announcement (waits for quiet) |
| Rebel territory | territory_grew (+ a "[City]" chat line) | every `lc_rebel_spread_minutes` 20 min on average | every 40 min |
| Overwatch drops | overwatch_drop | `lc_drop_cooldown` 30 min apart | 60 min |
| The Resistance's own operations | (skirmish and drop announcements, Freq 7) | `lc_rebel_ops_minutes` 30 min apart | 60 min |
| Trains | train_arrival + horn | `lc_train_minutes` 12 | 24 |
| Commendation | the Administrator's notice to everyone | `lc_loyalty_praise_minutes` 20 | 40 |
| Outbreak, blackout, power back, breakout, block raided | their triggers | when they happen | unchanged (power back and block raided wait for quiet, as before) |
| Welcome | welcome (just for the person joining) | unchanged | unchanged |
| The Administrator's broadcasts | ambient, as a programme | `lc_breen_broadcasts` 0 (off) | unchanged |
| Freq 7, radios | their own band | only on a radio tuned to it | unchanged |
| Civil Protection radio chatter | stock metrocop lines, from the cop | 40 to 90 s per cop near a player, half the time | unchanged (heard only near the cop) |

## The one PA

`LC.PAMark(secs)` (`sv_livingcity_announcer.lua`) is called by every voice that speaks to the city: the next one is due after the last has finished. `LC.PAQuiet()` is the silence so far. `LC.AnnounceTooSoon(trigger)` leaves out a routine one until the PA has been quiet `lc_announce_quiet` seconds (90, was 60, measured from when the last one finished rather than when it started). The routine list (`LC.AnnounceMinor`) gained dawn, night, socio_green and socio_yellow. The things that matter are never left out; each player's game still plays them one after another.

## Left for the owner to decide (not changed)

- `lc_announce_admin_share` (50): which voice speaks for a thing is still a coin toss when both have a recording. Making it fixed per kind (Overwatch for enforcement, the Administrator for civic news) would make the two voices predictable; that changes an existing setting's meaning, so it waits for the owner.
- Chat lines that go with announcements (the quote, then "  > what it means", plus the on-screen notice) are unchanged; the fewer announcements, the fewer of them.
