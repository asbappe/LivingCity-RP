# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

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
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 10.5 minutes since 9 November; includes the core snapshot check). Last run (2026-11-09): 4711 passed, 21 failed, all serial-order only (`TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes `VOICE_LINES.md` and `VOICE_SCRIPTS.md` from the code; what the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in either file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun).

## Where things stand
- 2026-11-14 evening, latest (the owner's Saturday playtest): **Overwatch PA spam fixed at the root**: `LC.Announce` refuses an ambient line until `lc_announce_quiet` (90 s) of quiet, whoever calls; the ration stores line is said once in 20 minutes per level (stores on the 25% line flipped and re-announced). **Every kill counter can be finished**: `WatchTargets` (sv_livingcity_quests.lua) counts targets still standing; short 10 s, it calls the stage's `refill` or `Q.Spawns(stage, { role, pos, r, arg })`; nothing for 45 s, pays what was done or calls it off. New kill counters need one. **Dropship always brings its soldiers**: reserve topped up per soldier, `LC.OverwatchDropTopUp` puts the missing ones on the ground. **Drawn guns survive restarts**: `LC.PocketHeldGuns` on disconnect/shutdown (not rank guns, not in dreams). Can filling needs the water in view. Collapse: an hour of red adds 20% (`LC.ChaosRedRate` 0.1); yellow unchanged (2.5% an hour). "Change into citizen clothes".
- Also 14 November (another chat): **players' bug reports and feedback** (F1 > Out of character > Report a bug or feedback; `LC.Feedback`, sv_livingcity_feedback.lua): saved in the server's `data/livingcity/feedback/` with a debug report under the player's words, one a minute each. In one of those files the top is what the player wrote and where; the rest is the usual debug report.
- Also 14 November: **the older "stand here" steps are replaced** (house rule 9; the list is in `docs/features/jobs-and-quests.md`): work by hand is `LC.QuestHandsStage` (sv_livingcity_questsearch.lua), the rest are job games (`Q.GameGo`: wiring, hack with `title`/`crime`, drop) or the step is gone. Kept by the owner's exception: holding ground against attacks, a unit's checkpoint or post, holding a raided zone; also the old shifts under `lc_jobgames 0`.
- Earlier 14 November: the play study (stage 1, `docs/features/play-study.md`; next: read the owner's `report.txt` when sent), the dream flight recorder (`docs/features/endings.md`; next: read `log.txt` when sent), the older "stand here" steps replaced (house rule 9; kept: holding ground against attacks, a unit's post, a raided zone), prison guard jobs rebuilt, the lab trimmed, the infested side hidden, Lamarr, dressed dreams, job boards.
- Open in TODO.md: the lab's dark look, each dream's own card wording, the dream posters, the leader's clipboard for operations.
- The owner asked (14 November) to stop the reminder about the vanishing unit: don't raise it again unless they bring it up.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
