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

- 2026-11-08 (part 11): **dream safeguards**, all asked for by the owner. Spec: `docs/features/endings.md` (after "Opting out, and nightmares": stand-ins, Enforcers, a dream you missed waits, the foil hat and the chip), lights out in `survival-and-credit.md` (Sleep), the night shift in `civil-protection-tools.md` and `jobs-and-quests.md`, the lab's chip in `city-economy.md`.
- New files: `sv_livingcity_dreamstandins.lua` (`lc_dream_min` 6: the city's people fill every dream; the quiz seats up to the same), `sv_livingcity_dreamenforcers.lua` + `cl_livingcity_dreamenforce.lua` (CP and Administration are Enforcers in forced dreams: baton, red glow, 1 XP banked and paid on waking), `sv_livingcity_bedtime.lua` (lights out via `LC.BedtimeDue` in `LC.TiredDue`, the `cp_nightshift` directive marked `first` on the board, `LC.NightShiftIssue` at the CP Commissary, missed dreams `S.missed` dreamt solo via `LC.DreamStart(..., only)`, `LC.FoilHatUse`, `LC.Chipless`, `LC.ImplantNoticed`, chipless 90 s sleep). Chip surgery: `LC.LabChip` in sv_livingcity_lab.lua.
- Gotcha: the dream snapshot puts back every `lc<Upper>` field on the player; dream state must start with `lcDream` (hence `lcDreamEnforcer`, `lcDreamEnforceXP`, `lcDreamWokeEnforcer`).
- Also: a unit killing a rebel player gets 5 XP (`LCF.XP.rebel_kill`); the reward now reads the victim's side from `DoPlayerDeath` (permanent death could make them a citizen first).
- Tests: `DreamCrowdTests` (41) pass; the quiz test expects six; SleepWarnTests runs with `lc_bedtime 0`; the vices test's fake sleeps got an end time. Parallel suite: 4422 passed, 1 failed (the core check: only the 13 older differences below). Client smoke passes.
- Snapshot has this chat's 9 settings and `foil_hat`. **Still waiting on the owner:** the 13 older differences approved on 7 November (CORE_CHANGELOG lines 56 to 60: `lc_npc_budget`, `lc_birds`, `lc_fridge_refill`, `lc_ration_interval`, `lc_rebel_errand_minutes`, `lc_scavenge_refill`, `lc_stock_eat`, `/letslip`, `lc_burn_evidence`); copy them in on their OK.
- Unchecked in game: PLAYTEST.md "8 November, part 11" (stand-in models and running, the Enforcer's baton and glow, lights out timing, the night shift's patrol stops on rp_c18_ug).
- Earlier, still open: PLAYTEST.md "7 November, part 3" onwards (quiz forgiveness, performance debugger, propaganda dreams, Ravenholm).
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`).
