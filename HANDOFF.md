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
- **The run to trust is `python3 _dev/run_parallel.py`** (two minutes; every shard starts from a fresh city). Last run (2026-11-20): 8,701 passed, 2 failed, both passing alone (tests that fail now and then by what ran before them: `TODO.md`, end; on 20 November the maze dream and the prisoners test were fixed, and "Stop" is the last section again: anything added after it runs in every shard). The one-piece run (`cd _dev && timeout 6900 python3 run_tests.py tests.lua`) loads again but stops in `DreamGameTests` (tests.lua line 19504, a dream with no game) because of what earlier tests leave behind: `TODO.md`.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- The robot players: `python3 _dev/robots.py` (a minute and a half; must end `ROBOTS PASS`). The house rules: `python3 _dev/house_rules.py`. Both in `CLAUDE.md`, Testing.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes **`VOICE_SCRIPTS.md`, the one file with every voice line** (the owner, 16 November: "We previously were using VOICE_SCRIPTS ... please consolidate"; the second file, `VOICE_LINES.md`, is gone: never bring it back or name it to the owner). What the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in the file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun). `_dev/voice_seen.txt` is what existed when that list came in: a line added since is left unticked (it used to be ticked as if the server had it) and counted under "added since the server's list was made".

## Where things stand

- 21 November (night). Valve map ingestion of the whole set is DONE: 145 maps measured, 279 lessons, 289 pictures in
  `_dev/reference/valve_*`, each batch's notes in its `notes/`. What was done and the owner's requests:
  docs/dev/valve-ingest-progress.md. Guide: docs/dev/map-ingestion.md; digest: docs/dev/valve-digest.md.
- Pieces lifted at the owner's asking (docs/dev/prefabs.md, "Pieces with their wiring"): Black Mesa East (airlock,
  turrets, lift, work spots), the Citadel (big doors, core, walkway reactor, pod; light bridge, vortex, ball socket and
  dispenser, weapon check room), White Forest's silo (for the bunker: where it goes is the owner's call).
- New tool: `_dev/tools/map_combine.py` (Combine structures from the architecture study); its test map
  `lc_combine_test.vmf` waits on the owner's look before any module uses it.
- Built after ingestion, owner-approved (TODO.md): timed holds with faster waves, squads topped up, supplies from
  roofs, tripwires and turrets; the church as a forward Resistance base over the crypt (Grigori there, wall benches,
  no cells); the silo into the bunker; Citadel and Black Mesa East pieces as modules. Ideas: Advisor screens.
- Canals built to Valve's table; the Breencast screen and the mounted gun are in the game; VDC Saver saves Valve's wiki.
- Open questions: the mounted gun's damage; lock gates crush or stop; which NPC lessons to build (all say ask first).
