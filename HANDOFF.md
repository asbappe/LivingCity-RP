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

- 2026-11-10 (posters): seventeen poster pictures in `materials/livingcity/posters/` (`.jpg`, made by `node _dev/posters/gen.js OUTDIR`; drawings in `gen.js`, `art2.js`, `lib.js`). Six are the editor's (by what is nearest, unchanged). Eleven are hung by hand only, with the Director of Propaganda's poster roll (`weapon_lc_posters`: left click hang, right click take any poster down (the editor's are hidden until the map next starts, `lcTornDown`), reload choose; `LC.HangPoster`, `LC.TakeDownPoster`, max 24, not saved over a map change). The Administrator is drawn after Mossman. Tests in TalkTests. Unchecked in game: the viewmodel (c_arms plus a paper prop, placed by `lc_posters_view`) and how the roll's menu opens.
- 2026-11-10 (Resistance posters): a spray can on a poster paints over it (`Spray` in sv_livingcity_scavenge.lua > `LC.DefacePoster`, NW2 `lc_defaced`, pictures `<kind>_x.jpg`, words `DEFACED` in lc_civposter.lua); left click with the roll pastes a fresh one over it. Four paste-ups (`rebel_*`) are on the roll only for a Resistance member. Art: `_dev/posters/art3.js`. Black market item `pasteup` (3 for 20): use at a bare wall (`Paste` in scavenge.lua); limits `lc_pasteup_max` (8, oldest comes down) and `LC.PasteUpGap` (500). Lettering is hand-sprayed (a stroke alphabet, `HAND` in art3.js). Not done: sanitation scrubbing posters.
- 2026-11-10 (pamphlet look): the Civil Orientation pamphlet opens as a printed leaflet (`OpenPamphlet` in `cl_livingcity_dialog.lua`, style "pamphlet" on the `lc_dialog` message; paper `materials/livingcity/pamphlet/paper.jpg` from `_dev/posters/pamphlet.js`; page pictures cut from the posters, `PAGE_ART`). Words unchanged. Smoke test opens and paints it. Unchecked in game.
- 2026-11-10 (this chat, all owner-approved from the gameplay review; specs in `docs/features/`): **arrival search** (`sv_livingcity_intaketutor.lua`, civil-intake.md end), **prison** sentences/work detail/probation (`sv_livingcity_sentence.lua`, city-events.md end) and interrogation (`sv_livingcity_interrogation.lua`, city-administration.md), **survival modes** (`sv_livingcity_survivalmode.lua`, survival-and-credit.md end), **dreams sat out once earned** (`sv_livingcity_dreamskip.lua`, endings.md end; PData `lc_dream_sitout`, not `lc_dream_skip`, the Administrator's), **where I stand** (`sv_livingcity_standingpanel.lua`) and **F2 > Me for every side** (`MineItems`/`MinePage`/`MyDreamsPage` in cl_livingcity_quick.lua). Tests: IntakeTutorTests, SentenceTests, InterrogationTests, SurvivalModeTests (prelude runs older tests with `lc_survival_modes` 0), DreamSkipTests, StandingPanelTests, and client smoke blocks.
- The owner: **never only in the C menu** (CLAUDE.md house rule 2).
- Another chat, same day: **citizens show the way** (`sv_livingcity_advice.lua`) and **learning the city** (`sv_livingcity_learning.lua`, info desk, old-timer, pamphlet, talking machines, posters, dialog window). `VOICE_LINES.md` (sections 5 to 8 new): rerun `_dev/voice_lines.py` after adding any line.
- The work detail now comes by turns (`D.kind`: trash, sweep via the stalker's `scrub` job game with `opts.prisoner`, toilets via `LC.PrisonToilets` and `LC.PrisonToiletUse`, called first in `LC.UseToilet`; splashes `LC.PrisonSplash`).
- **A unit's shift** (`sv_livingcity_cpduty.lua`: `LC.CPShift`, `LC.CPCount` from `LivingCitySearched` and wrapped `LC.SearchNPCFound/Clean`, `LC.CPPapersDuty` (job game `papers`, `opts.cpDuty`), `LC.CPInspectOrder`/`LC.CPInspect` (charges via `LC.RaidCharge`), `LC.CPReview`; F2 > Me > My shift (`ShiftPage`); CPDutyTests (15)).
- **Snitches and burning** (`sv_livingcity_snitches.lua`: `LC.IsSnitch` (st.snitch rolled once), `LC.IllegalAct` (gun out polled, wrapped `LC.ItemUse`), `LC.SnitchReport`; `LC.Burn`, `LC.Scar`, `LC.IsBurned`, `LC.ReallyInformant`; `LC.TargetActions` in sv_livingcity_actions.lua; prelude turns `lc_snitches` 0; SnitchTests (20)).
- **Next, the approved queue:** Resistance planning board; the state of the city (districts with an owner, persistent supply/morale/strengths/authority, collapse aftermath, two-week acts, drift while empty), news through the city's own announcements and screens, no new popups, with the Administrator's speeches (a speech point) and tools; small-server mode; citizen goals (status, households, businesses, citizen crime).
- Known: "a winner wakes Unbroken" fails only after ExerciseParadeTests in a shard (old, TODO.md); a few random tests come and go.
- 2026-11-10 (latest): **learning the city by living in it** (owner asked for all the audit's ideas; specs: `talking-and-tips.md` "Learning the city before the cards", `city-people.md` (clerk, old-timer), `civil-intake.md` (pamphlet), `city-events.md` (PA), `editor-placing.md`).
- `sv_livingcity_learning.lua`: `LC.HintDeferSecs` (hints Due/Hint hold place/item/needs tips `lc_hints_wait`), `LC.HintLearned`/`LC.Learn`, `LC.PAExplainDue` (events.lua), `LC.MentorCredit`, `LC.CivPosterNotice/Read` (entity `lc_civposter`). `sv_livingcity_dialog.lua` + `cl_livingcity_dialog.lua`: generic Q&A window (`LC.OpenDialog`, `LC.DialogHandlers`, `LC.DialogDo`).
- `sv_livingcity_infodesk.lua` (entity `lc_infoclerk`, fixture `infodesk`), `sv_livingcity_oldtimer.lua` (roster flag `oldtimer`, `LC.OldTimerTick`, dealer waypoint), `sv_livingcity_pamphlet.lua` (item `pamphlet`), `sv_livingcity_machines.lua` (`LC.MachineSpeak` from the dispenser and vending), `cl_livingcity_bodysigns.lua` (client `lc_body_signs`).
- Tests turn `lc_hints_wait`, `lc_pa_explain`, `lc_machine_voice` off in the prelude for older tests; the new ones are TalkTests "Learning the city by living in it". Full parallel run: 4913 passed, 2 failed, both fixed and rechecked. Core snapshot updated (owner-asked).
- The old-timer's troubles (`LC.OldTimerTroubles`: food, water, medicine for his cough, a ration card, a smoke; roster `helped`, keepsake lockpick), the pamphlet's own words (`LC.PamphletPages`), **illness** (`sv_livingcity_illness.lua`: `LC.Illnesses` cold/stomach/fever, `LC.CatchIllness`, `LC.CureIllness`, item `medicine`, NW2 `lc_ill`; Realistic only; fever: `sh_livingcity_illness.lua` no running/fists, `LC.FeverDream` at 12:00, `cl_livingcity_feverdream.lua`) and poster art (`materials/livingcity/posters/<kind>`, brief `POSTER_BRIEF.md`), all owner-asked. Full runs: only random fails that move between runs.
- **`VOICE_LINES.md`** (sections 5 to 8 new: citizens, clerk, old-timer, machines): made by `_dev/voice_lines.py`; rerun after adding any line.
- Another chat, same day: **citizens show the way** (`sv_livingcity_advice.lua`).
- Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section.
- Tests need `pip install lupa` in a fresh container.
