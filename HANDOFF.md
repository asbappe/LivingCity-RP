# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's playtest card: about 15 things only a person can judge; the old list, sorted and tagged, is `PLAYTEST_ARCHIVE.md`), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

## The project

- Living City is a Garry's Mod Half-Life 2 roleplay gamemode. Repo `asbappe/LivingCity-RP`. **`main` is the official branch.** Start from `main`, push the session's branch and also fast-forward `main` (`git push origin HEAD:main`; merge first if it moved, never force). No pull requests unless asked.
- Layout: `gamemodes/livingcity/` (the gamemode; modules in `gamemode/modules/server` and `client`; the in-game guide text is in `gamemode/cl_init.lua`), `livingcity_sound/` (READMEs only, never ship it), `pose_recorder/` (separate tool addon), `lua/` (editor tool), `_dev/` (offline tests, not shipped), `docs/features/` (spec), `docs/dev/` (notes for code workers, e.g. `endings-notes.md`).
- The latest work is in `git log` on `main`.

## The owner and their server

- Linux Mint (give Linux commands). Dedicated server on a Hexane host, map `rp_c18_ug`. FastDL mirrors `garrysmod/`; the host panel's "FastDL sync" must be pressed after every upload. Pictures and the font live loose in `garrysmod/materials/livingcity/` and `garrysmod/resource/fonts/` (`livingcity_content.zip`), not in the gamemode zip.
- Recordings and songs are in the server's `garrysmod/sound/livingcity/` (`overwatch/`, `administrator/`, `endings/`). Full details: `CORE.md`. A recording that "stopped working": run `lc_announce_clips` first.

## Testing

- Client smoke test, repo root: `python3 _dev/client_smoke.py` (must end `CLIENT SMOKE PASS`).
- **The owner asked (2026-10-31) to test less:** compile-check changed files and run only the test section you touched; run the full suite only when they ask. Compile check: `from lupa import luajit21 as lupa`, then `loadstring` on the file.
- **The run to trust is `python3 _dev/run_parallel.py`** (two minutes; every shard starts from a fresh city). Last runs (2026-11-14): about 6,425 passed, 3 to 11 failed, all from the unreliable list in `TODO.md`. The one-piece run (`cd _dev && timeout 6900 python3 run_tests.py tests.lua`) loads again but stops in `DreamGameTests` (tests.lua line 19504, a dream with no game) because of what earlier tests leave behind: `TODO.md`.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- The robot players: `python3 _dev/robots.py` (a minute and a half; must end `ROBOTS PASS`). The house rules: `python3 _dev/house_rules.py`. Both in `CLAUDE.md`, Testing.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes `VOICE_LINES.md` and `VOICE_SCRIPTS.md` from the code; what the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in either file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun).

## Where things stand
- 2026-11-14 night, latest: **a pause on new features** (the owner: "over development and not enough playtesting"). They chose five ideas from a list; 5 and 7 to 10 wait in `TODO.md` ("Simpler and better").
- **Every error in one file** (`sh_livingcity_errors.lua`): the server's and players' Lua errors, what `LC.Error` reports and what a protected call swallowed, grouped and counted, kept over restarts in `data/livingcity/errors.txt`. F4 > Factions > Admin: errors (N). **`LC.Try`, never `pcall`, in the gamemode** (a bare `pcall` fails the run). Next: read the owner's `errors.txt` when sent.
- **The robot players** (`python3 _dev/robots.py`, `docs/dev/robot-players.md`): 135 jobs (boards, stories, Union shifts) done as a player would, twice, the second time with hooks in the other order. 84 finish; 2 KNOWN and 7 "robot can't" are listed. They found five hold-E steps that depended on hook order: fixed (the owner's yes), `LivingCityQuestItems` leaves searched things to the search hook.
- **The house rules as numbers** (`python3 _dev/house_rules.py`, `_dev/house_rules.json`): 23 stand-still steps, 1,451 text places, 78 console-only commands. A rise fails the run; `--update` only with a reason in the commit.
- **The tests:** `tests.lua` loads whole again (the reference run had been dead since a merge that morning: over 200 main-level locals) and the runners say when it does not; the fake game runs hooks and timers in the order they were made. About ten tests still come and go: list in `TODO.md`.
- **`PLAYTEST.md` is a card** (17 things only a person can judge); the old list is `PLAYTEST_ARCHIVE.md`, every item tagged. `CLAUDE.md`, reading budget 4 and 5.
- Waiting on the owner (`TODO.md`, "What the robot players and the audits found"): the kitchen shift "The counter", The Man Inside part 2, two stand-and-wait steps.
- Earlier 14 November: Overwatch PA spam fixed at the root (`lc_announce_quiet`), every kill counter finishable (`WatchTargets`), players' bug reports (F1 > Out of character; admins on are told, the text is cleaned by `LC.FeedbackClean`), the play study (next: the owner's `report.txt`), the dream flight recorder (next: `log.txt`), stand-here steps replaced (house rule 9).
- Open in TODO.md from before: the lab's dark look, each dream's own card wording, the dream posters, the leader's clipboard for operations.
- The owner asked (14 November) to stop the reminder about the vanishing unit: don't raise it again unless they bring it up.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
