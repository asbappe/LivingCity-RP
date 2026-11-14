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
- 2026-11-14, latest (the owner's answers to the playtest work; core, in `CORE_CHANGELOG.md`; snapshot: `+ lc_vort_start 1`, `lc_vort_reach_minutes 4`, `lc_vort_rescue_minutes 10`).
- **Vortigaunts chosen at the start:** `sv_livingcity_vortstart.lua` (`LC.OfferRace` from `LC.OpenCharacterCreator`, `LC.BecomeVortSlave`, `LC.VortRescueTick`), `cl_livingcity_vortstart.lua` (`LC_CL.OpenRacePick`); `LC.IsVortChar` and the swap rules in `LC.CanJoinFaction`; the Free Vortigaunt special is `hidden`.
- **Repel the attack** counts every raid attacker (`cp_repelraid`, sv_livingcity_sidejobs.lua). **Action music** on an enemy hit twice (`LC.IsEnemyOf`). **Squad revive** once unhit for 5 s (`st.bulletHitAt`, `LC.SquadReviveCalm`). **Collapse** yellow at `LC.ChaosYellowRate` (0.0125).
- **Trail:** `LC.TrailRoute` plans between nodes nearest each end, never a straight line through walls (`LC.TrailNoWay`).
- **Dream HUD:** `LC_CL.DreamQuietHUD` (cards, hints, pill hidden), goal line 15 s (`LC_CL.DreamGoalSecs`), notices lower.
- Earlier today: the 13 November playtest's fixes (`TIMELINE.md`), and another chat's five dream poster pictures.
- **Remind the owner at the end of every message until answered:** paste `lc_announce_clips` (the "report" announcement repeating, hers silent); paste `lc_territory` (underground camps never retaken); the unit that ran past and vanished (they have no name for it; the first 13 November debug report has only stuck soldiers near the prison, 1800 to 2400 x, 0 to 500 y, z 1440).
- **Next from `TODO.md`** ("From the owner's 13 November playtest"): prison guard jobs and rank, the infested as a hidden side, lab parts found, loudspeaker utility boxes, a way out of a manhunt, Resistance operations on F4, dressing the dreams.
- Unseen in game: everything above. Tests: full suite on every core passes but for the known order-dependent ones (they pass alone); client smoke passes.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
