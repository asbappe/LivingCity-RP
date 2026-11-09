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

- 2026-11-09 (part 12, last): **tougher, desperate Combine** (owner asked; spec `docs/features/city.md` "Tougher Combine units", "The desperate Combine", "The NPC cap grows with the server"). Health: `lc_cp_health` 70, `lc_soldier_health` 90, `lc_elite_health` 150 (`LC.ToughenUnit` in SpawnCop/SpawnSoldier, sv_livingcity.lua; editor sliders). NPC cap: `LC.NPCBudgetSteps` (32: 1, 64: 1.75, 120+: 2.5, max 250).
- `sv_livingcity_desperation.lua`: `LC.Desperation` 0..1 eases (0.05 per 5 s) toward `LC.DesperationTarget` (Resistance:Combine players 1.5 to 4, needs `LC.ImbalanceFloor` rebels). Cops' sidearm `LC.DesperateSidearm` (DrawPistol in response.lua, ArmUnit in rebels.lua); soldiers' NumGrenades and scripted throws `LC.DesperateThrow` (frag npc_grenade_frag, poison/flash lc_grenade; `LC.DesperateClear`); Elites' balls `LC.DesperateBall` (prop_combine_ball); +10% damage hook. Combine flashbangs spare their own (Detonate in crafting.lua). `lc_desperation` off switch. Testing alone: editor section "Desperate Combine: test it" (`LC.DesperationTestSet` pins a level 30 min, tester is the target; `LC.DesperationTestSquad` soldiers/elite/cops, gone in 5 min).
- Resistance (owner): `lc_rebel_health` 50 (SpawnRebel), `lc_rebel_home_hurt` 1 (RETUNED in endings.lua moves 2 to 1), WEAPONS 70/20/10 crossbow, `lc_rebel_per_combine` 1.25 x `LC.CombineStreetCount` in `LC.RebelTarget`; RebelTests sets it to 0 after its own check.
- Tests: SideBalanceTests (stub got `EMT:SetOwner`). Unchecked in game: PLAYTEST.md "9 November, tougher Combine" (the engine bits: thrown frags, Lua-made combine balls, NumGrenades set at runtime).
- Earlier part 12 (dreams, dream plan, sides even, imbalance, reaction squads): see `git log` and PLAYTEST.md "8 November, part 12" to "9 November, later", all still unchecked in game.
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`); 
