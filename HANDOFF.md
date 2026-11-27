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

- 26 November (the owner): the quiet HUD card lost "This server hides numbers on screen"; ambient PA lines get no second line in chat (not "Just the city talking", not the unrest one).
- 26 November: the old-timer's fisherman head no longer parented (it floated where he left a player's view, his own head shrunk): it takes its bones from his every frame and draws only with him (LC_CL.HeadOn; city-people.md). Not seen in game yet.
- 26 November: the cistern as its own piece (map_cistern.py; `map_build.py cistern --test`: lc_cistern_test.vmf, sent), a street plate
  over it, Valve's freight lift from gallery to street (models, lc_cistern_lift; map-building.md). Not compiled. Next: Propper++.
- 25 and 26 November (the owner's answers; none seen in game): Combine APC on the ring's road (apc-patrol.md); the city falls chapter,
  `lc_chapter` 0; the hive boss NextBot 2149660804, `lc_hiveboss` 0; `lc_text_gate` 3; `lc_train_real` 0. Staff: F4 > Factions > Admin:
  testing tools. The ten new settings are in the core snapshot (the owner's OK). Mask off = out of uniform. Last full run (26 Nov):
  9,460 passed, 4 failed, all four passing alone (order-dependent: TODO.md, end). HintTests stops at tests.lua:4168 (old: TODO.md, end).
- 26 November, not seen in game: LC.CombatDrive (civil-protection-tools.md), LC.FearStep (city-people.md), units hear
  (sv_livingcity_noise.lua). Ideas left: docs/dev/npc-ai-lessons.md. 24 Nov TODO run: wildlife, resistance-base, ieds (not seen).
- 22 to 26 November: the canal ring (map_ring_walk.py joins the first canal, ring.txt, inlet.txt, bunker_way.txt and the
  bunker forest; ~30 min; the ring's half nodraw-passed, the forest's half as built: TODO.md). Kit: 43 pieces. Combine
  wall on every city bank; rail bridge a viaduct, the Combine engine at its train's head; trains portal to portal;
  floodgate (valve wheel), tramfall, the crypt's inlet. 26 Nov, late: overflow and swingbridge modules gone (the swing
  bridge is the quay's bridge), pour() three jets, backdrop 16 buildings and Valve's card trees, the bunker forest 3520
  east down Valve's tunnel (servicetunnel, map_shift.py). 27 Nov: the walk map holds the OWNER'S OWN forest file (--forest; their
  Drive link is in that chat; two CS:S materials in it are fine: Garry's Mod ships CS:S content since July 2025). Test map: 24,953 faces, ~47,188 vertices. Not run in game.
- Owner's c18_lc.vmf and Valve's VMF zip: their Drive. Bunker map chat: map_owner_delta.py, map_hidden_faces, map_areas.py (fixes5 sent). Cave: lifts, shed doors, holes 212 to 6, back way (lc_forest_cave_1127b sent, not compiled).
