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
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).

## Where things stand

- 2026-11-08 (part 5): **ten more propaganda dreams**, `sv_livingcity_propagandamore.lua` (uses `LC.PropagandaKit`, exported at the end of `sv_livingcity_propagandadreams.lua`): Record Harvest (`harvest`), The Stakhanov Shift (`shift`), Careless Talk (`spy`), The Newsreel (`newsreel`), Two Minutes of Hate (`hate`), The Mass Games (`massgames`), On-the-Spot Guidance (`guidance`, she can star), The Scrap Drive (`scrap`), Flowers for the Liberators (`flowers`), Duck and Cover (`duck`). Spec: `docs/features/endings.md`, the paragraph after "Propaganda dreams".
- Client (`cl_livingcity_dreamgames.lua`): generic `glows`, floating `board` (3D2D), the Mass Games `mosaic`, `notes`, `carryName`, `marchers` (NOW for flowers), themes `harvest`, `hate`, `civil`, `newsreel` (black and white).
- Owner's follow-up (same day): mini games must be party games (everyone picks on their own in 30 s, revealed to all): Careless Talk (4 rounds) and The Newsreel (8 takes, everyone at once) reworked; the others were already simultaneous. Duck and Cover framed as the Resistance's rocket (`LC.DuckRockets`: EP2 path is a guess, falls back to PHX).
- The owner's rule for every dream: dreams are goofy and absurd; the Resistance can be giant, glowing red, flying (`LC.PropagandaVillain`: Magnusson on the rocket, the unmasked spy, a rebel over the Hate screen).
- Ravenholm (`ravenholm`, end of the same file): zombies from graves, red Grigori; turns at 25 health or 55 s: her version (she descends, soldiers, Grigori flees) unless `LC.DreamFreeVort()` finds a freed vortigaunt alive (a Free Vortigaunt player, or an NPC with `lcVortFreed`, set where street-crew and work-site vortigaunts are freed), then the green storm, Grigori good with his shotgun, a red giant her flies off. Client `storm`, theme `graveyard`.
- Inputs: crouch edge (`Ducked`), jump edge (`Jumped`: IN_JUMP or off the ground), chat (`def.say`), position. Offences go through the same `Offend` (loyalty on waking).
- Tests: `PropagandaMoreTests` (70) pass; `PropagandaDreamTests`, `DreamGameTests` and the client smoke test pass. Full suite not run (the owner asked to test less).
- Nothing checked in game: PLAYTEST.md, "Ten more propaganda dreams" (sizes of the floating boards, the mosaic's height, the factory machines and other models are guesses).
- Core snapshot: sorted and in step (the six drinks and smokes approved); `.claude/settings.json` no longer blocks it, so a command can update it with the owner's OK.
- Earlier (still open): PLAYTEST.md "7 November, part 3" onwards; the first five propaganda dreams unchecked in game.
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`).
