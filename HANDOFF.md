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

- 2026-11-10 (the Resistance pamphlet, owner-asked; spec `docs/features/resistance-pamphlet.md`): item `rebel_pamphlet` (quartermaster, 5 for 15), read as its own sheet (`OpenRebelPamphlet`, paper from `_dev/posters/rebelpamphlet.js`), handed to players or citizens (F1) and left lying about (entity `lc_rebelpamphlet`); `sv_livingcity_rebelpamphlet.lua`. RebelPamphletTests (29). Unchecked in game.
- 2026-11-10 (latest): **the city's minds, watching only** (owner-asked; spec `docs/features/city-minds.md`). `sv_livingcity_psyche.lua` (`LC.Psy`: 11 traits from the id (independent dice since the second pass), needs incl. craving, thoughts, stress, ties, news, breaks and inspirations; pure arithmetic) and `sv_livingcity_minds.lua` (`LC.MindsStep` one mind per 0.5 s; fed by hurt/killed/arrested/served/shared food/abed, stopped (polled `detained`), EventStarted, `LC.MindsSocio` (polls `LC.Socio`), PosterDefaced, Pickpocket, Burned, Snitched, CustomAnnouncement; minds kept apart in `LC.Minds.byId`, never in people.json). Breaks only logged (`WOULD`, with trait words). `lc_minds` 1, `lc_minds_show` 0. **Visible:** `sv_livingcity_npcvices.lua` (`lc_npc_vices` 1): vice citizens smoke (`lc_vice` puffs) or drink (bottle on RH) while calm near players. MindsTests (39); prelude turns `lc_minds` and `lc_npc_vices` 0.
- 2026-11-10: **Give menu** in the talk window (`LC.GiveKind`, `LC.GiveableTo`, `Give` in sv_livingcity_talk.lua; action `give:<id>`; hook `LivingCityGaveCitizen`; client DermaMenu; GiveTests (14)). Food still via ShareFood/`LivingCitySharedFood`. Resistance leaflets = items with `leaflet = "resistance"` (another chat makes them, `TODO.md`).
- **The owner leaves it running and brings back `data/livingcity/minds/`**: `python3 _dev/psyche/analyze.py FOLDER_OR_ZIP`; tune `Psy.cfg`/THOUGHTS; `_dev/psyche/analyze_traits.py` checks every trait still moves outcomes; then propose phase 2 and 3 one piece at a time (`TODO.md`). Firing squads, public punishments and executions are in `TODO.md` (owner: YES), to design with them.
- 2026-11-10, this chat (all owner-approved from the gameplay review; specs in `docs/features/`, modules in `python3 _dev/make_modules_map.py --module NAME`):
  - arrival search (`intaketutor`), prison sentences, work detail by turns and probation (`sentence`), a deeper interrogation (`interrogation`), survival modes (`survivalmode`), dream sit-outs (`dreamskip`), Where I stand (`standingpanel`)
  - a unit's 15-minute shift, no break needed (`cpduty`); snitches, burning and the rat scar, which bars the Resistance (`snitches`, `cl_livingcity_ratscar`)
  - planning board and bounties (`opplan`); state of the city (`ledger`, `ledger2`, speech stand point); small-server mode (`smallserver`)
  - citizen goals: status symbols and the pet pigeon (`status`, `cl_livingcity_petbird`), households (`households`), a stall business with hand-made goods and workers (`employment`), pickpocketing, loans and bad deals (`streetcrime`)
- The owner: **never only in the C menu** (CLAUDE.md house rule 2). A citizen's F2 > Me keeps lines 1 to 4 and the milestone; new pages go under "More". F1 gets "More with them..." when entries overflow.
- Insider **Report it clean** (`LC.CPReportClean` in cpduty) built; F2 now overflows into a More page at slot 8 (a unit's Me/My shift did not fit before). Open offer: tuning `lc_ratscar_pos` and `lc_petbird_pos` after an in-game look.
- Known: "a winner wakes Unbroken" (after ExerciseParadeTests) and a PropagandaDreamTests check (after DreamGameTests) fail only by test order, old (TODO.md); a few random tests come and go.
- Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section.
- Tests need `pip install lupa` in a fresh container.
