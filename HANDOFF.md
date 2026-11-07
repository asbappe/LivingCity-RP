# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes). One task per chat: when you finish, rewrite "Where things stand" below in 15 lines or fewer.

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
- Full suite, from `_dev`, in the background: `timeout 6900 python3 run_tests.py tests.lua` (about 40 minutes; includes the core snapshot check). Last full run (2026-11-02): 2994 passed, 6 failed (flaky, see `TODO.md`). Stop a run with ``kill $(pgrep -f "^python3 -u run_tests.py tests.lua")``.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).

## Where things stand

- 2026-11-07 (part 3b): nightmare rules and vices. Opting out covers Happy and Neutral dreams only; a Nightmare takes everyone asleep and nobody wakes themselves while still in it (`LC.DreamSleepers(mood)`, `LC.DreamCanWake`, `LC.DreamWakeAsked` in `sv_livingcity_dreams.lua`). In a dream you play, out of lives or won: wake now or watch (spectate inside the arena); outcome on waking via the `LivingCityDreamWoke` hook and `LC.DreamOutcome`.
- New `sv_livingcity_vices.lua` / `cl_livingcity_vices.lua`: cigarettes, beer, vodka, moonshine, stimulant shot (items in `sh_livingcity_shop.lua`, `use = "vice"`); a stimulant blocks sleep (`sv_livingcity_rest.lua`). Spec: `docs/features/survival-and-credit.md`, `docs/features/endings.md`; core line in `CORE.md`, entry in `CORE_CHANGELOG.md`.
- **Waiting on the owner:** `_dev/core_snapshot.txt` needs six new lines (`item beer`, `item cig_rolled`, `item cig_union`, `item moonshine`, `item stimulant`, `item vodka`); the edit was blocked in this session, so the full suite's core check will fail on exactly those until they're added with the owner's OK.
- Tests: `DreamGameTests` (37), `ViceTests` (17), `DreamMoodTests` pass; `DreamTests` has one flaky check (an awake player's random job loadout), it passed on rerun. Client smoke passes. Nothing checked in game: PLAYTEST.md, the last two sections.
- The full suite hasn't been rerun since 2026-11-02 (run it when the owner asks).
