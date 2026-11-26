# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's playtest card: about 15 things only a person can judge; what else waits for a person is the short backlog `PLAYTEST_ARCHIVE.md`), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

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
- **The run to trust is `python3 _dev/run_parallel.py`** (four minutes; every shard starts from a fresh city; needs `pip install lupa`). Last run (2026-11-20): 8,701 passed, 2 failed, both passing alone (tests that fail now and then by what ran before them: `TODO.md`, end; on 20 November the maze dream and the prisoners test were fixed, and "Stop" is the last section again: anything added after it runs in every shard). The one-piece run (`cd _dev && timeout 6900 python3 run_tests.py tests.lua`) loads again but stops in `DreamGameTests` (tests.lua line 19504, a dream with no game) because of what earlier tests leave behind: `TODO.md`.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- The robot players: `python3 _dev/robots.py` (a minute and a half; must end `ROBOTS PASS`). The house rules: `python3 _dev/house_rules.py`. Both in `CLAUDE.md`, Testing.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes **`VOICE_SCRIPTS.md`, the one file with every voice line** (the owner, 16 November: "We previously were using VOICE_SCRIPTS ... please consolidate"; the second file, `VOICE_LINES.md`, is gone: never bring it back or name it to the owner). What the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in the file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun). `_dev/voice_seen.txt` is what existed when that list came in: a line added since is left unticked (it used to be ticked as if the server had it) and counted under "added since the server's list was made".

## Where things stand

- 26 November: the cistern lifted out of the ring into its own piece (map_cistern.py; `map_build.py cistern --test`: lc_cistern_test.vmf,
  sent). A street plate over it and a lift from the gallery to the street: Valve's own freight lift, models not brushes (the owner
  insists; lc_cistern_lift; map-building.md, "The cistern by itself"). Not compiled. The ring's cistern is untouched. Next: Propper++.
- 25 and 26 November (the owner's answers; none seen in the real game): a Combine APC on the ring's road (apc-patrol.md); the chapter,
  the city falls, `lc_chapter` 0 (chapter-city-falls.md); the hive boss as the Workshop NextBot 2149660804, `lc_hiveboss` 0
  (wildlife.md); `lc_text_gate` 3; `lc_train_real` 0. Staff lines: F4 > Factions > Admin: testing tools. Ten new settings wait for the
  owner's OK before they go in the core snapshot (CORE_CHANGELOG.md): the core check fails on exactly those until then. Last full run
  (26 November): 9,449 passed, 5 failed: the core check, and four that pass alone (TODO.md, end).
- 26 November, not seen in game: fights handed to the engine Background NPCs' way (LC.CombatDrive; civil-protection-tools.md), citizens'
  fright lasts while the shooting does (LC.FearStep; city-people.md), units hear (sv_livingcity_noise.lua). Ideas left: docs/dev/npc-ai-lessons.md.
- 24 November (the TODO run), not seen in game: wildlife.md, resistance-base.md, ieds.md. The Resistance's town is off the map.
- 22 to 25 November: the canal ring (map_ring_walk.py, ~22 min with the nodraw pass). Propper++ kit: 43 pieces; the wall's 20 changed
  25 Nov: owner recompiles those. Latest test map: 20,200 faces. Stitched map over; the drain and the railway left of the review (TODO).
- The owner's c18_lc.vmf and Valve's VMF zip are on their Drive (the Drive connector finds them). Flaky, pass alone: TODO.md, end.
- Map chat (bunker): owner's VMF via map_owner_delta.py, map_hidden_faces --brushes/--holes, map_areas.py. 26 Nov fixes3 sent.
