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

- 2026-11-08 (part 9): **The Loyalty Quiz forgives answers** (the owner's OK): common endings, one-letter typos in words of 5+ letters, more synonyms per question, swears and insults are thoughtcrime (leet, stretched and misspelt too) unless aimed at the Resistance (`LC.QuizHas`, `LC.QuizWordMatch`, `LC.QuizForbidden`, `LC.QuizSwears` in sv_livingcity_propagandadreams.lua; thoughtcrime typos only from 6 letters). `PropagandaDreamTests` pass. Unchecked in game: PLAYTEST.md "The Loyalty Quiz forgives". Same chat: the dreams' Foreman, Loudspeaker, Narrator, Screen and Conductor lines are now the Administrator's (reworded), and the Shift's foreman is gone (she watches, `shift_idle`); Sunny the Scanner stays. Then **quiz stand-ins**: under 4 dreamers the city's named people answer in chat (`LC.QuizSeat`, `LC.QuizNPCAnswers`), and a rebel (made-up name) shouts thoughtcrime and is beaten and dragged off (`quiz_rebel`, `quiz_resume`); models and poses unchecked in game.
- 2026-11-08 (part 8): **the performance debugger** (staff): `sh_livingcity_perfdebug.lua` (the measuring, both sides), `sv_livingcity_perfdebug.lua` (on/off, players and send queue, saving to `data/livingcity/perf/`, auto-off), `cl_livingcity_perfdebug.lua` (the window, C > Help > Performance debugger). Spec: `docs/features/admin.md`, after the lag monitor.
- While on it wraps every hook (via `hook.GetTable`, ULib priorities kept), `hook.Add`, `timer.Simple`/`timer.Create`, `net.Incoming` (its own copy), `net.Start`/`Send`/`Broadcast`/..., and `SetNW*`/`SetNW2*`; off puts back each one still its own. Hitches: the gap between its `Think` hooks (`P.Frame`). One line in `sv_livingcity_perf.lua` passes city timer times on (`LC.PerfDebugNote`).
- **Waiting on the owner:** OK to add three snapshot lines (`setting lc_perfdebug_minutes = 30`, `setting lc_perfdebug_spike_ms = 60`, `console command lc_perfdebug`) to `_dev/core_snapshot.txt`. Until then the core check fails on just those three.
- Also the last button of the editor tool's panel (`lc_perfdebug_menu`). Tests: `PerfDebugTests` (31) pass, client smoke passes. Unchecked in game: PLAYTEST.md "8 November, part 8".
- Part 7: **`lc_voice_missing`** (superadmins or the server console; `LC.VoiceMissing` in sv_livingcity_announcer.lua) lists every voice line with no recording yet; spec: the last paragraph of `docs/features/custom-announcements.md`. Core snapshot has it.
- Parts 5 and 6 (fifteen propaganda dreams, Ravenholm): unchecked in game, PLAYTEST.md "Ten more propaganda dreams" onwards.
- Earlier (still open): PLAYTEST.md "7 November, part 3" onwards.
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`).
