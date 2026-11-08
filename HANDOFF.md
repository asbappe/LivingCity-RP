# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes). One task per chat: when you finish, rewrite "Where things stand" below in 15 lines or fewer.

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
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 40 minutes; includes the core snapshot check). Last full run (2026-11-02): 2994 passed, 6 failed (flaky, see `TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).

## Where things stand

- 2026-11-08 (part 12): **strange dreams and testing dreams**, both asked for by the owner. Spec: `docs/features/endings.md` ("Strange dreams you play", "Testing a dream from the editor"); `editor.md` has a line.
- New `sv_livingcity_strangedreams.lua` + `cl_livingcity_strangedreams.lua`: The Cheese Dream (`cheese`, Neutral: 9 s black intro, everyone frozen, HL2 `vo/npc/male01|female01/question06.wav` echoed client-side; then low gravity, crumbs, rolling wheels `LC.CheeseUnder`, psychedelic colour modify, water-warp overlay, wobbling song rate), Musical Chairs (`chairs`, Neutral), Wings (`flying`, Happy: flap on jump in the air, `LC.WingsFlapPush`), It's Raining Melons (`melons`, Happy: `LC.MelonLand`). Their own `woke`: a win calls `LC.DreamOutcome`, a loss only a line (no 30 health).
- A dream def may have `leave(g, p)` (called from `LC.DreamGameLeave`; gravity back). Client: `LC_CL.DreamGameSongChannel()`, theme colours in `cl_livingcity_dreamgames.lua`.
- New `sv_livingcity_dreamtest.lua`: net `lc_dream_test` ("list", "test" id, "stop"), `LC.DreamTest` sets `p.lcDreamTesting` and `LC.DreamTestOnly` so `LC.DreamStart` takes only the tester (`dream.test`); wakes with `why == "test"`, and the woke/started listeners (bedtime, dreamrules, propaganda loyalty, dream games outcome) skip it; never an Enforcer; `LC.DreamCanWake` true. Editor panel: "Dreams: test one" (combo filled through `LC_CL.DreamTestWatchers`).
- Tests: `StrangeDreamTests` (38) pass; dream units and client smoke pass (smoke now builds the editor's panel and clicks Test/Stop). Stub got `SetGravity`.
- Unchecked in game: PLAYTEST.md "8 November, part 12" (the owner will judge each dream by playing it), plus part 11 and earlier still open.
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`).
