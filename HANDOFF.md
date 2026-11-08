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

- 2026-11-08 (part 2): the Administrator's dreams, new file `sv_livingcity_admiredreams.lua`: three Happy dreams you play on her tablet, Kneel Before Her (`adore`: crouch and look at her to fill Devotion, standing in her gaze costs a life), Roses for Her (`roses`: carry roses to her feet, crouch past the gold line), Mirror, Mirror (`mirror`: crouch and compliment her in chat; chat stays in the dream via `LC.AdmireSay`, called first by the IC chat hook in `sv_livingcity_rp.lua`). Flattery and comedy, nothing explicit (the owner asked for no 18+).
- Her music: any song in `sound/livingcity/dreams/administrator/` (random, looping, client side in `cl_livingcity_dreamgames.lua`). The owner will import songs.
- `sv_livingcity_dreamgames.lua` now exports `LC.DreamGameKit`, passes the player to `def.state(g, p)`, and lets a dream have its own `timeUp` text and `woke` (her dreams: a line on waking, no rewards or penalties). The nightmares behave as before.
- Earlier today: nightmare rewards (Unbroken, Second wind, Vortigaunt whisper/gift; losing: `LC.SetDreamScar`), all in `sv_livingcity_vices.lua`.
- The six vice items are now in `_dev/core_snapshot.txt` (the owner approved, on `main`). Her dreams add no snapshot lines.
- Tests: `AdmireDreamTests` (27), `DreamGameTests` (38) pass; client smoke passes. Nothing checked in game: PLAYTEST.md, last section (sizes and the mirrors' angles are guesses).
- `TODO.md`: Combine sleep in the head-clamp prop (later). Full suite last run 2026-11-02.
