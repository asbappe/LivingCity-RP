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

- 2026-11-10 (latest): **the city's minds, watching only** (owner-asked; spec `docs/features/city-minds.md`). `sv_livingcity_psyche.lua` (`LC.Psy`: traits from the id, needs, thoughts, stress, ties, news, breaks; pure arithmetic) and `sv_livingcity_minds.lua` (`LC.MindsStep` one mind per 0.5 s; fed by `LC.MindsHurt` (EntityTakeDamage), `LC.MindsKilled` (OnNPCKilled), LivingCityIncarcerated, LivingCityServed, LivingCitySharedFood, `abed`; minds kept apart from the roster in `LC.Minds.byId`, never in people.json). Breaks are only logged (`WOULD`). Logs and state in `data/livingcity/minds/`. `lc_minds` 1, `lc_minds_show` 0 (talk window line, `LC.MindsSeem`). Debug report section. MindsTests (20); the prelude turns `lc_minds` 0 for older tests.
- **The owner leaves it running and brings back `data/livingcity/minds/`**: read it with `python3 _dev/psyche/analyze.py FOLDER_OR_ZIP`, tune `Psy.cfg`/THOUGHTS, then propose phase 2 (choices bend) and 3 (breaks for real) one piece at a time (`TODO.md`). Offline city: `python3 _dev/psyche/run.py [seed] [days]` (uses the gamemode's own library).
- Earlier the same day: posters, the poster roll and Resistance paste-ups, the pamphlet leaflet, arrival search, prison, survival modes, dreams sat out, F2 > Me, a unit's shift, snitches and burning, learning the city, illness (details in `git log` and `TIMELINE.md`).
- The owner: **never only in the C menu** (CLAUDE.md house rule 2).
- **Next, the approved queue:** Resistance planning board; the state of the city (districts, persistent supply/morale/authority, collapse aftermath, two-week acts, drift while empty), news through the city's own announcements and screens, the Administrator's speeches; small-server mode; citizen goals.
- Known: "a winner wakes Unbroken" fails only after ExerciseParadeTests in a shard (old, TODO.md); a few random tests come and go.
- Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section.
- Tests need `pip install lupa` in a fresh container.
