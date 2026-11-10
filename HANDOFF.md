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

- 2026-11-10 (latest): **learning the city by living in it** (owner asked for all the audit's ideas; specs: `talking-and-tips.md` "Learning the city before the cards", `city-people.md` (clerk, old-timer), `civil-intake.md` (pamphlet), `city-events.md` (PA), `editor-placing.md`).
- `sv_livingcity_learning.lua`: `LC.HintDeferSecs` (hints Due/Hint hold place/item/needs tips `lc_hints_wait`), `LC.HintLearned`/`LC.Learn`, `LC.PAExplainDue` (events.lua), `LC.MentorCredit`, `LC.CivPosterNotice/Read` (entity `lc_civposter`). `sv_livingcity_dialog.lua` + `cl_livingcity_dialog.lua`: generic Q&A window (`LC.OpenDialog`, `LC.DialogHandlers`, `LC.DialogDo`).
- `sv_livingcity_infodesk.lua` (entity `lc_infoclerk`, fixture `infodesk`), `sv_livingcity_oldtimer.lua` (roster flag `oldtimer`, `LC.OldTimerTick`, dealer waypoint), `sv_livingcity_pamphlet.lua` (item `pamphlet`), `sv_livingcity_machines.lua` (`LC.MachineSpeak` from the dispenser and vending), `cl_livingcity_bodysigns.lua` (client `lc_body_signs`).
- Earlier today: citizens show the way (`sv_livingcity_advice.lua`).
- Tests turn `lc_hints_wait`, `lc_pa_explain`, `lc_machine_voice` off in the prelude for older tests; the new ones are TalkTests "Learning the city by living in it". Full parallel run: 4913 passed, 2 failed, both fixed and rechecked. Core snapshot updated (owner-asked).
- `VOICE_LINES.md` sections 5 to 8 (citizens, clerk, old-timer, machines); `lc_voice_missing` lists them.
- Still open (TODO.md): a weary Resistance fighter at camp in the old-timer's style.
- Unchecked in game: PLAYTEST.md "10 November" sections.
- Tests need `pip install lupa` in a fresh container.
