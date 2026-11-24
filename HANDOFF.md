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

- 24 November (late): **the ring cut down after the owner's walk** (its test map names each module on screen: `name_sign`).
  Off the ring: 7 saved as prefabs (`lc_mod_*`, docs/dev/prefabs.md), lift/arcade/chimney/floodroom deleted, shell off. Edge
  fence, bars over blocked openings and the stash valve are props; six-sided outfalls; no kerb rail. Ring piece alone:
  31,115 faces, about 48,000 vertices before nodraw. Rework list (underpass, pipes, vort, camp+shanty, drain, relay): TODO.md.
- 24 November: **the Resistance's town is off the map** (the owner: they "need to be more underground"), kept on the shelf:
  map_town.py, town.txt and the ten modules in map_mods_b.py still build (the town byte for byte, slimmed that morning to
  6,783 faces). ring.txt: its branch is `straight 512`, nothing else moved, ruins on its ground. Rest without the ring
  ~44,200 faces; the town's share is free. Walled garden's plots (lc_garden_plot_N) on no map piece now.
- 23 November (late, gamemode): **units fight again** (a leftover os.getenv crashed every chase; run_tests.py now fails on
  Lua GMod lacks); **Overwatch answers raids** (LC.RaidOverwatch); flying dreams free of a short zone's top (LC.DreamTop);
  sleepers lie on beds (no SetupBones); eyelids yield; intake one line, hands up, R no fists; bed tally; rain cover.
- 23 November (lip sync): mouths move with the recordings (`_dev/tools/lipsync_bake.py`; LC.PreferWav). Not seen live yet.
- 22 to 24 November: the canal ring (map_ring_walk.py): the owner compiled the Propper++ kit (35 models, models/lc/kit).
  vbsp also limits unique vertices (65,536): their quick build stopped at 70,769. map_budget.py now estimates them; the
  ring's test map needs the nodraw pass (36 min): 30,901 faces, ~56,678 vertices. Stitched map still over (TODO).
- The owner's c18_lc.vmf and Valve's VMF zip are on their Drive (the Drive connector finds them; curl with the file id).
  Flaky in full runs, pass alone: "Fighting it pushes it back" (3), the dream bubbles, EndingTests, Lamarr (TODO.md).
- Map chat: bunker rebuilt round White Forest's control room + 12a's launch room over Valve's pad on our silo; red
  button launches (lc_rocket_launch), CCTV lc_bunker_cctv (map_launch.py). Apply generator changes to the OWNER'S
  latest VMF (diff two builds), then map_hidden_faces --brushes, then --holes (0). 24 Nov: their 9 fixes sent, 10,369 sides.
