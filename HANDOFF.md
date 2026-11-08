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

- 2026-11-08 (part 11): **dream safeguards**, all asked for by the owner. Spec: `docs/features/endings.md` (after "Opting out, and nightmares": stand-ins, Enforcers, everyone in bed and stimulants, the safeguard, the foil hat and the chip), lights out in `survival-and-credit.md` (Sleep), the night shift in `civil-protection-tools.md` and `jobs-and-quests.md`, the lab's chip in `city-economy.md`.
- New files: `sv_livingcity_dreamstandins.lua` (`lc_dream_min` 6), `sv_livingcity_dreamenforcers.lua` + `cl_livingcity_dreamenforce.lua` (CP and Administration are Enforcers in forced dreams: baton, red glow, 1 XP paid on waking), `sv_livingcity_bedtime.lua` (lights out for every player via `LC.BedtimeDue` in `LC.TiredDue`, done for the night after sleeping past 21:00 / waking from tonight's dream / dusk sleep on a dreamless night; one stimulant `lc_stim_locked` until a dream dreamt through or a night slept; `cp_nightshift` directive marked `first`; foil hat; `LC.Chipless`; `LC.ImplantNoticed`). Chip surgery: `LC.LabChip`. The Administration is no longer exempt from sleep (sv_livingcity_rest.lua `Exempt`). `lc_dream_max_minutes` (5) ends any dream (sv_livingcity_dreams.lua timer).
- The owner dropped the missed-dream catch-up (a stimulant simply misses the dream). Gotcha: the dream snapshot puts back every `lc<Upper>` player field; dream state must start with `lcDream`.
- Also: a unit killing a rebel player gets 5 XP (`LCF.XP.rebel_kill`), the victim's side read at `DoPlayerDeath`.
- Core snapshot is up to date (owner OK), including the 13 older 7 November differences.
- **Asked the owner, waiting:** remove opting out of / waking from Happy and Neutral dreams (approved core rule, 7 November)? Wake a sleeper who's attacked? Stimulants are 35 credits (they guessed 40) and the dealer's supply is unlimited (the lab makes none): limit it?
- Tests: `DreamCrowdTests` (50) pass; ViceTests expects a second stimulant refused; SleepWarnTests runs with `lc_bedtime 0`. Random failures seen: "rebels in the cloud take it too" (Grenades), "a headcrab near" (1 November playtest).
- Unchecked in game: PLAYTEST.md "8 November, part 11". Earlier, still open: "7 November, part 3" onwards.
- Next, each in a fresh chat: The Battle Line and vortigaunt dream warfare (designs at the end of `TODO.md`).
