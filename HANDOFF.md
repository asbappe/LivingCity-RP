# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

## The project

- Living City is a Garry's Mod Half-Life 2 roleplay gamemode. Repo `asbappe/LivingCity-RP`. **`main` is the official branch.** Start from `main`, push the session's branch and also fast-forward `main` (`git push origin HEAD:main`; merge first if it moved, never force). No pull requests unless asked.
- Layout: `gamemodes/livingcity/` (the gamemode; modules in `gamemode/modules/server` and `client`; the in-game guide text is in `gamemode/cl_init.lua`), `livingcity_sound/` (READMEs only, never ship it), `pose_recorder/` (separate tool addon), `lua/` (editor tool), `_dev/` (offline tests, not shipped), `docs/features/` (spec), `docs/dev/` (notes for code workers, e.g. `endings-notes.md`).
- The latest work is in `git log` on `main`.

## The owner and their server

- Linux Mint (give Linux commands). Dedicated server on a Hexane host, map `rp_c18_ug`. FastDL mirrors `garrysmod/`; the host panel's "FastDL sync" must be pressed after every upload.
- Recordings and songs are in the server's `garrysmod/sound/livingcity/` (`overwatch/`, `administrator/`, `endings/`). Full details: `CORE.md`. A recording that "stopped working": run `lc_announce_clips` first.

## Testing

- Client smoke test, repo root: `python3 _dev/client_smoke.py` (must end `CLIENT SMOKE PASS`).
- **The owner asked (2026-10-31) to test less:** compile-check changed files and run only the test section you touched; run the full suite only when they ask. Compile check: `from lupa import luajit21 as lupa`, then `loadstring` on the file.
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 10.5 minutes since 9 November; includes the core snapshot check). Last run (2026-11-09): 4711 passed, 21 failed, all serial-order only (`TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).

## Where things stand

- 2026-11-10 (latest): **the arrival search** (owner asked; spec `docs/features/civil-intake.md`, end). New `sv_livingcity_intaketutor.lua` / `cl_livingcity_intaketutor.lua`: units posted (`st.tutorPost`, `st.holdPos`) at intake and housingterm points while anyone is `LC.TutorWants`; the search is a copy of the pat-down run by the NPC (`LC.TutorBegin`, `LC.TutorChoose`, `LC.TutorSlip`, `LC.TutorTick`), lesson with practice note and a client-only practice search; unregistered out of `LC.InStation` are cuffed and walked to `LC.TutorDeskSpot`, handed over at the desk if stuck (never `LC.MarchToPrison`). `CopProvoked` skips desk units and anyone in a search (they were arresting people in the queue). Tests: IntakeTutorTests (24), client smoke block.
- **The owner's approved queue** (from the gameplay review, 10 November), in order: prison (sentences by crime 3/6/8/10/15/20 summed since the last sentence, cap 30; labour escorted out of the small cells by a prison guard takes time off; 15 min probation, offences count double, check in with a metrocop or Administration staff, any dealing with the Resistance punished; deeper interrogation); survival modes (Relaxed: hunger/thirst a third, no toilet/hygiene/parasites/spoilage; Realistic: +20% pay and XP, "Hardened" legacy title; switch once per 3 hours; character screen and F-menus); one standing panel for all the numbers; Combine work when there are no rebels (quotas, apartment inspections, checkpoint papers duty, reviews); informants (secret snitch citizen NPCs, a passive flag, who walk to a unit or terminal; the Resistance can "burn" a suspect: shunned, beaten, a scar; guessing wrong costs sympathy); Resistance planning board; the state of the city (districts with an owner, persistent supply/morale/strengths/authority, collapse aftermath, two-week acts, drift while empty) with the Administrator's speeches (a speech point) and tools, news through the city's own announcements and screens, no new popups; small-server mode; citizen goals (status, households, businesses, citizen crime).
- Dreams (owner, 10 November, approved): Exemplary (400+) citizens may opt out of Nightmares and propaganda, told in a small note as the dream fades in; after 2 Happy dreams lived through anyone may opt out of Happy ones, after 2 Neutral of Neutral ones. Not built yet.
- Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section.
- Tests need `pip install lupa` in a fresh container.
