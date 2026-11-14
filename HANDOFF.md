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
- 2026-11-14, latest: **no "stand here" job steps** (`CLAUDE.md` house rule 9, `CORE.md`); the older ones to replace are listed in `TODO.md` (about 31, shifts, side jobs, board jobs, stories, vortigaunts).
- **Prison guard jobs rebuilt** (sv_livingcity_prisonguard.lua): `pg_inspect` (search by hand, `LC.QuestSearchStage` in the new sv_livingcity_questsearch.lua), `pg_question` (`LC.NPCInterrogationStart`/`Do`: the unit's interrogation quick menu, "call" added in cl_livingcity_interrogation.lua; `LC.PlayerInterrogationDo` passes to it first), `pg_break`, `pg_riot` (`LC.RiotQuiet`). Promotion after four, as before.
- **The lab:** `LCS.Lab` is only `vest_cell`, `firebomb`, `foil_hat`; `LC.QuartermasterStocks` keeps anything he sells off it (also the market's extras). Surgery 40 s (`LC.SurgerySecs`, `LC.SurgeryScene`). Get the lab running: searches and the wiring game (`Q.GameGo`, now in `LC.QB`). Go to ground: just reach the camp.
- Tests that found "the quartermaster" by `st.quartermaster` now skip the medic (`and not st.medic`).
- Earlier the same day: the playtest notes, the to-do run, the owner's answers (snapshot, infested side, Lamarr, dressed dreams, job boards). The audit: `docs/dev/lab-vs-quartermaster-audit.md`.
- The owner asked (14 November) to stop the reminder about the vanishing unit: don't raise it again unless they bring it up.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
