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

- 2026-11-08/09 (part 12): **strange dreams** (14 in all) and **testing dreams from the editor**, all asked for by the owner. Spec: `docs/features/endings.md` ("Strange dreams you play", "Ten more strange dreams", "Testing a dream from the editor"). Lines to record: `docs/features/dream-lines.md` (made by `python3 _dev/dream_lines.py`; rerun after adding lines).
- `sv_livingcity_strangedreams.lua`: cheese, chairs, flying, melons; the kit (`LC.StrangeKit`): `IntroTick`/`IntroHello` (voices in the dark: frozen, DSP 25, music on `def.begin`), `SayAs` (cue lines through `LC.StrangeAddCues`, recordings via `LC.PropagandaVoice`), `LC.DreamSongFor` (any dream's music by codeword; `sv_livingcity_dreamgames.lua` asks it unless `def.ownMusic` or an intro). A def may have `leave(g, p)` (gravity, DSP, lagged movement back).
- `sv_livingcity_strangedreams2.lua`: horse (Nightmare; `LC.HorseLines` = HL2 question09, unverified), boxing, exam, train, lamarr, molasses (Nightmare), potato, simon, dance (`LC.DanceTempo` from dance1.txt), sheep (chat answers: `LC.StrangeDreamSay`, also called from sv_livingcity_rp.lua). Client: `cl_livingcity_strangedreams.lua` (generic dreamy echo `LC_CL.DreamIntro`: sound.Play from far points).
- `sv_livingcity_dreamtest.lua`: the editor's "Dreams: test one" (last section of the panel): `LC.DreamTest` (`dream.test`, woken as `why == "test"`, listeners skip it, never an Enforcer).
- The Exam (9 November, owner): seated at desks, answers in chat (`LC.ExamAnswerOf`), Kleiner eats each paper (walk, grab, eat, reveal), score secret until then (`LC.ExamScore`, `LC.ExamPass` 4).
- Tests: `run_parallel.py` 4557 passed, 0 failed (the serial `run_tests.py` now loads but ran past its timeout: `TODO.md`). `StrangeDreamTests` (38), `MoreStrangeDreamTests` (46) pass; client smoke draws every theme and clicks the editor's Test/Stop. Stub got `SetGravity`, `SetLaggedMovementValue`, `SetDSP`.
- Unchecked in game: PLAYTEST.md "8 November, part 12" and "9 November" (the owner judges each dream by playing it); part 11 and earlier still open.
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`).
