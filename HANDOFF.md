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

- 2026-11-10: **the collapse reworked** (owner asked; spec `docs/features/collapse.md`). The G-Man in person: entity `lc_gman` (SOLID_NONE, `SetPreventTransmit` to all but her, `lc_for` NW2), `LC.CollapseGman` spawns/leaves him (`GmanFor`, `GmanLeave`); walking away (`LC.CollapseWalkAway`, `LC.CollapseGmanTick`, 300 units or the window's "Walk away") gives 10 s (`lc_gman_back_by` NW2) to press E (`KeyPress` hook, `LC.CollapseGmanUsed`) else `Refuse`. His lines: `GLINES` (settings `lc_black_gman_*`, words from a `.txt` beside the clip: `LC.CollapseGmanWords`); `GMAN_SOUNDS.md` rows 11 to 23; `lc_voice_missing` lists them.
- Her shield: entity `lc_adminpower` (point `adminpower`, fixture class in survival.lua), `LC.CollapseStandSpot` (desk within reach, else beside it; none placed: a temporary one), `LC.CollapseShieldUp` (standing and within `lc_black_power_range`), `LC.CollapsePowerHit` (sparks, smoke stages `lc_power_smoke`, blasts). `lc_black_shield` removed. Client: beam and bubble, transformer bar and markers.
- Her desk: `LC.DesksNear` (map props with "desk" in the model, and static props read from the BSP by `LC.ReadStaticProps`: game lump 35, "sprp"), `StandBeside`; the desk point (`AtDeskPoint`) comes first. Test builds a fake BSP in CollapseTests.
- F1: item 6 is the "Out of character" page (`OOCPage` in cl_livingcity_quick.lua): 1 Nearby, 2 Server-wide.
- Tests: CollapseTests (51), client smoke covers the G-Man words, countdown, beam. Core snapshot updated (owner-asked). Full parallel run: only the known random tests fail.
- Earlier (9 November): the collapse, heroes, team chat, `lc_announce_stock`, warning posts, the serial suite fix: `git log`. Unchecked in game: PLAYTEST.md "9 November, part 13" and "10 November".
- Tests need `pip install lupa` in a fresh container.
- Next: the owner's spliced G-Man clips, the Workshop dance and Alyx sleep-rig file lists; whatever they ask.
