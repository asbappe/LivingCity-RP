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
- 2026-11-14 (the owner sent their `PLAYTEST.md` from the 13 November playtest: about 45 notes; core, in `CORE_CHANGELOG.md`; snapshot: `- item gren_gas`, `+ lc_jog 0`, `lc_rebel_damage` 0.6). Built: `PLAYTEST.md`, "Your 13 November notes" (27 items to retry).
- **Sounds that loop by themselves:** `sh_livingcity_soundguard.lua`, end (`LC.SoundLoops` reads the .wav's loop mark; `LC.SoundLoopWatch`, `LC.SoundLoopsStop` on death and spawn; `surface.PlaySound` of one goes through the player).
- **Jobs:** kills on the way and NPC allies' kills count (`LC.QuestEvent`, `LC.QuestAssist`), a template's `over` (cp_repelraid); the trail retries with no ground kept out (`LC.TrailRoute`, `EditorRoute(..., free)`).
- **Combine:** no lowered guns for units on rebel ground (`LC.LoweredGround`); backup delay and squad revive (`LC.CallBackup`, `LC.SquadReviveStep`, sv_livingcity_war.lua); sweeps in turn (`LC.NextSweepZone`).
- **Music:** `sv_livingcity_pacing.lua` (`LC.NoteShot`, `LC.InAction` for everyone, `lc_by_infest`), `cl_livingcity_atmos.lua` ("eerie" mood).
- **Cremator:** `LC.CrematorBoost` (real speed), `LC.CrematorNearestNode`, `LC.CrematorEscortHere`.
- **Dreams:** Roses (`LC_CL.DrawRose`, `g.laid`), Careless Talk (`g.spyTbls`, `LC.SpyDressing`, the salute).
- **Also:** jog archived (`lc_jog`, `LC.ArchiveJogPoints`); `gren_gas` gone; lab (`LC.LabHold`, `LC.LabCollect`, `LC.LabClean`); `LC.AmmoRoom`, `LC.PocketVial`; shop scroll and wrap (`cl_livingcity_needs.lua`); screens 20% larger with paging side by side; role ranks; `LC.InfestedKin`; `LC.ScatterNear`.
- Other chat, same day (owner-asked; `CORE_CHANGELOG.md`; no snapshot change): the dream posters' pictures (`_dev/posters/dreams.js` through `gen.js`): `dream_lamarr`, `dream_cheese`, `dream_watchers`, `dream_mirror` for the city, and `dream_forecast` (the melons' one) only inside It's Raining Melons, on four billboards (`LC.DreamBillboard`; `lcDreamProp`, `lc_big` in `lc_civposter.lua`; size and height are guesses). Every dream poster's small words are one sentence (the owner's rule for new ones). Still to draw: 42 dreams, `dream.png`, `dream_x.png` (`TODO.md`, a Fable 5.2 chat), where a secret Lamarr pet is also noted.
- **Waiting on the owner** (asked in chat, listed at the end of `TODO.md`): `lc_announce_clips` (the "report" announcement repeating, hers silent), `lc_territory` (underground camps), yellow filling the collapse bar or not, the Free Vortigaunt role, the unit that ran past and vanished, the dreams' text screenshot.
- **Next from `TODO.md`** ("From the owner's 13 November playtest"): prison guard jobs and rank, the infested as a hidden side, vortigaunts chosen at the start, lab parts found not lying about, loudspeaker utility boxes, a way out of a manhunt, Resistance operations on the F4 board, dressing the dreams.
- Unseen in game: everything above. Tests (2026-11-14): `python3 _dev/run_parallel.py` 6241 passed, 0 failed; client smoke passes.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
