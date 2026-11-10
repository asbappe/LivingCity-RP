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

- 2026-11-10 (latest): **survival modes** (owner approved). `sv_livingcity_survivalmode.lua`: `LC.SurvivalMode`, `LC.Relaxed`, `LC.SetSurvivalMode` (PData `lc_survival`, `lc_survival_at`, per character), `LC.RelaxedNeedsMul` (survival tick), `LC.SurvivalPayMul`/`LC.SurvivalXPMul` (economy shift pay, jobgames pay, `LC.AddXP`), wraps `LC.LegacyTitle` for "Hardened"; parasites, `LC.Infect` and `LC.SpoilCheck` skip Relaxed. UI: characters screen button, F1 > Me item, action `survival`. Tests run with `lc_survival_modes` 0 (prelude) except SurvivalModeTests (13).
- 2026-11-10 (latest): **prison** (owner approved). `sv_livingcity_sentence.lua`: crimes recorded per character (`LC.RapSheet`, PData `lc_rap`, via the `LivingCityWanted` hook), `LC.CrimeMinutes`, `LC.SentenceFor` called from `LC.Incarcerate` (only arrests: arrester valid, not `ply.lcExactSentence`, which `lc_jail` sets; "Surrendered..." halves); work detail (`LC.AskWorkDetail`, `LC.WorkDetails`, `LC.SentenceTick`, trash props `lcPrisonTrash`, point `prisonwork`, `pr.work` skips the escape check); probation (`LC.StartProbation`, `LC.ProbationCheckIn`, `LC.ProbationViolation`, wraps `LC.AddTrait` for sympathy). `sv_livingcity_interrogation.lua`: `LC.InterrogationStep` (called from custody's tick), `LC.InterrogationAnswer`, `LC.InterrogationIntel`, `LC.StartPlayerInterrogation`, `LC.PlayerInterrogationDo`; client `cl_livingcity_interrogation.lua`. F1 actions `workdetail`, `checkin`; F2 "Interrogate". Tests: SentenceTests (30), InterrogationTests (21), client smoke blocks.
- Earlier today: **the arrival search** (`sv_livingcity_intaketutor.lua`, spec end of `docs/features/civil-intake.md`; IntakeTutorTests).
- **The owner's approved queue** (from the gameplay review, 10 November), in order: one standing panel for all the numbers; Combine work when there are no rebels (quotas, apartment inspections, checkpoint papers duty, reviews); informants (secret snitch citizen NPCs, a passive flag, who walk to a unit or terminal; the Resistance can "burn" a suspect: shunned, beaten, a scar; guessing wrong costs sympathy); Resistance planning board; the state of the city (districts with an owner, persistent supply/morale/strengths/authority, collapse aftermath, two-week acts, drift while empty) with the Administrator's speeches (a speech point) and tools, news through the city's own announcements and screens, no new popups; small-server mode; citizen goals (status, households, businesses, citizen crime).
- Next: dreams. Dreams (owner, 10 November, approved): Exemplary (400+) citizens may opt out of Nightmares and propaganda, told in a small note as the dream fades in; after 2 Happy dreams lived through anyone may opt out of Happy ones, after 2 Neutral of Neutral ones. Not built yet.
- 2026-11-10 (another chat): **citizens show the way** (owner asked; spec `docs/features/city-people.md`, Chat bullet). `sv_livingcity_advice.lua`: `LC.CitizenAdvice` (called from Chat in sv_livingcity_talk.lua) maps `LC.NextStep` keys (`LC.AdviceForStep`) to a line (`LC.AdviceLines`, no place names) and the step's `way` (`LC.WaypointPlaces`). A stranger points (`LC.GuideTo`: marker + trail); a warm citizen leads (`LC.GoTo`, `LC.AdviceLeads`, `LC.AdviceLeadTick`: waits past 450, gives up past 1600 or 150 s, falls back to the trail). Once a minute per player.
- Settings `lc_citizen_advice`, `lc_citizen_lead`, `lc_citizen_lead_range` (snapshot updated, owner-asked). Recordings `sound/livingcity/citizens/<id>_male|female<n>` (`LC.AdviceClip`), in `lc_voice_missing` and `VOICE_LINES.md` section 5.
- Tests: TalkTests "Citizens who show you the way", AnnouncerTests (citizens row). Not run: full suite.
- The audit's other ideas (info desk, old-timer, posters, talking machines, body signs, pamphlet, veteran XP, shorter PA lines, cards only when stuck): the owner likes them all; listed in `TODO.md`, each to be described to the owner before building.
- **`VOICE_LINES.md`**: made by `_dev/voice_lines.py`; rerun after adding any line.
- Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section.
- Tests need `pip install lupa` in a fresh container.
- Next: the owner's recordings; the next idea from the audit.
