# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

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
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 10.5 minutes since 9 November; includes the core snapshot check). Last run (2026-11-09): 4711 passed, 21 failed, all serial-order only (`TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).

## Where things stand

- 2026-11-10 (later): **the collapse's boss mechanics** (owner asked; spec `docs/features/collapse.md`). 2 or 3 `lc_adminpower` (`LC.CollapsePowers`, numbered by the point's `group`: `LC.CollapseGuardKind`/`LC.CollapseGuard`: 1 manhacks, 2 turrets + panels, 3 mines + rollermines + gravity guns; guards marked `lcCollapseGuardOf`, can't hurt them), each with `lc_adminglass` (`LC.AdminGlassSpot`, its front; `FACE_PLACER` has adminpower). Shield up while any stands in reach (`LC.CollapseShieldUp`, `LC.CollapsePowersLeft`). She floats (`FloatBegin`, `LC.CollapseFloatHeight`, 0.1 s timer). Squads (`LC.CollapseSquad`, `LC.CollapseSquadSpot`, `NextSquad`).
- BLACK: curfew (`LC.CollapseCurfew`), the suppression device (`LC.SuppressorTick/Fire/Land/Targets`, `LC.UnderSky`, `LC.SuppressorInRange`; entity `lc_suppressor`, point `suppressor`, `LC.SuppressorHit`, `LC.SuppressorSource`). Client ring `LivingCitySuppressorRing`. Announcements: `Announce()` with triggers `socio_black` (every 5 min), `black_stand`, `black_fallen`, `black_crushed`, `suppressor_down`.
- Earlier today: the G-Man in person (`lc_gman`), walking away = 10 s to press E, his lines (`VOICE_LINES.md` (section 3) rows 11 to 23), the map's own desk (`LC.DesksNear`, `LC.ReadStaticProps`), F1 > 6 Out of character.
- Scaling (latest): `LC.CollapseRebelCount` (near: within 3200 of her office), `LC.CollapseScale` (base at 2, max at 20), `LC.CollapseSquadGap`; guards spawn in rings, `Jolt`, `FromCeiling` (panels: door01_left, mass 30, unbreakable via `LivingCityCollapseGuards`, which also stops guards hurting each other). Squads: an Elite first.
- **`VOICE_LINES.md`**: every voice line, made by `_dev/voice_lines.py` (loads the gamemode through run_tests.py; WORDS has the suggested words; G-Man list source `_dev/gman_sounds.md`; dreams via dream_lines.py). Rerun after adding any line.
- Tests: CollapseTests (82). Core snapshot updated (owner-asked). Full parallel run: clean apart from the known random tests. Lesson: check new `LC.*` names against other modules (`LC.NearCombineZone` clashed once).
- Unchecked in game: PLAYTEST.md "9 November, part 13" and both "10 November" sections.
- Tests need `pip install lupa` in a fresh container.
- Next: the owner's recordings (collapse announcements, spliced G-Man clips); the Workshop dance and Alyx sleep-rig file lists.
