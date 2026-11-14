# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's in-game checklist), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

## The project

- Living City is a Garry's Mod Half-Life 2 roleplay gamemode. Repo `asbappe/LivingCity-RP`. **`main` is the official branch.** Start from `main`, push the session's branch and also fast-forward `main` (`git push origin HEAD:main`; merge first if it moved, never force). No pull requests unless asked.
- Layout: `gamemodes/livingcity/` (the gamemode; modules in `gamemode/modules/server` and `client`; the in-game guide text is in `gamemode/cl_init.lua`), `livingcity_sound/` (READMEs only, never ship it), `pose_recorder/` (separate tool addon), `lua/` (editor tool), `_dev/` (offline tests, not shipped), `docs/features/` (spec), `docs/dev/` (notes for code workers, e.g. `endings-notes.md`).
- The latest work is in `git log` on `main`.

## The owner and their server

- Linux Mint (give Linux commands). Dedicated server on a Hexane host, map `rp_c18_ug`. FastDL mirrors `garrysmod/`; the host panel's "FastDL sync" must be pressed after every upload. Pictures and the font live loose in `garrysmod/materials/livingcity/` and `garrysmod/resource/fonts/` (`livingcity_content.zip`), not in the gamemode zip.
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
- `python3 _dev/voice_lines.py` writes `VOICE_LINES.md` and `VOICE_SCRIPTS.md` from the code; what the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in either file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun).

## Where things stand
- 2026-11-14, latest: **the play study, stage 1** (the owner: record how they play as a model for the city's people). F4 > Factions > Admin: play study. sv_livingcity_study.lua samples every second (who: faction and rank; where: zone kind, whose ground, nearest layout point; in what: the city or a dream; job; movement; security in sight), logs events (the gamemode's own `LivingCity...` hooks naming the player, via wrapped `hook.Run`/`hook.Call` while on), pauses (noclip, editor tool, out of the window, away from the keys), keeps failed or struck jobs out, and builds the report; cl_livingcity_study.lua saves `data/livingcity/study/<date>_<time>_<faction>/` on the player's PC. Spec: `docs/features/play-study.md`. Neither recorder has run in a real game yet.
- **Next, when the owner sends a study (a zip of one folder):** read `report.txt` first, propose NPC changes for their OK. Stage 2 (NPCs read baselines directly) is not built and needs their OK. Their later ideas: read the map's VMF to lay the study's map coordinates over it (hotspots, redesign, holes in geometry).
- Earlier 14 November: **the dream flight recorder** (the owner: a way for the code chat to "see" a dream; "only when I initiate a dream from the editor tool"). An editor test with *Record the test* ticked (`lc_dreamrec`, the tester's computer) is written down: sv_livingcity_dreamrec.lua (`LC.DreamRecBegin` from `LC.DreamTest`; made/gone, sound, notice, state, nw, net, you, near) sends lines to cl_livingcity_dreamrec.lua (text on screen with seconds readable, chat, sound, screenshots, fps), saved on the tester's PC in `data/livingcity/dreamrec/<date>_<time>_<dream>/` (`log.txt`, pacing check on top). Spec: `docs/features/endings.md`, "The dream flight recorder".
- **Next, when the owner sends a recording (a zip of one folder):** read `log.txt` (the pacing check first, then the timeline; look at a few screenshots), and propose fixes to that dream for their OK. The owner finds the dreams "rushed" and their words and instructions hard to follow.
<<<<<<< HEAD
- 2026-11-14, latest: **the older "stand here" steps are replaced** (house rule 9; the list is in `docs/features/jobs-and-quests.md`): work by hand is `LC.QuestHandsStage` (sv_livingcity_questsearch.lua: hold E on one thing, nothing said in chat), the rest are the job games (`Q.GameGo` wiring, hack with `title`/`crime` options, drop) or the step is simply gone. **Kept by the owner's exception:** holding ground against attacks or a counterattack, a unit's checkpoint or post, holding a raided zone; also the old shifts under `lc_jobgames 0`. Last full run (`run_parallel.py`): 6352 passed, 1 failed (the speech crowd one, random: passes alone).
=======
- Also 14 November (another chat): **no "stand here" job steps** (`CLAUDE.md` house rule 9, `CORE.md`); the older ones to replace are listed in `TODO.md` (about 31, shifts, side jobs, board jobs, stories, vortigaunts).
>>>>>>> origin/main
- **Prison guard jobs rebuilt** (sv_livingcity_prisonguard.lua): `pg_inspect` (search by hand, `LC.QuestSearchStage` in the new sv_livingcity_questsearch.lua), `pg_question` (`LC.NPCInterrogationStart`/`Do`: the unit's interrogation quick menu, "call" added in cl_livingcity_interrogation.lua; `LC.PlayerInterrogationDo` passes to it first), `pg_break`, `pg_riot` (`LC.RiotQuiet`). Promotion after four, as before.
- **The lab:** `LCS.Lab` is only `vest_cell`, `firebomb`, `foil_hat`; `LC.QuartermasterStocks` keeps anything he sells off it (also the market's extras). Surgery 40 s (`LC.SurgerySecs`, `LC.SurgeryScene`). Get the lab running: searches and the wiring game (`Q.GameGo`, now in `LC.QB`). Go to ground: just reach the camp.
- Tests that found "the quartermaster" by `st.quartermaster` now skip the medic (`and not st.medic`).
- Earlier the same day: the playtest notes, the to-do run, the owner's answers (snapshot, infested side, Lamarr, dressed dreams, job boards). The audit: `docs/dev/lab-vs-quartermaster-audit.md`.
- **The infested, hidden:** sv_livingcity_infestedside.lua (`ply.lcTurning` from `LivingCityDowned`; `LC.TurnInfested` from the PlayerDeath hook; dying infested is the end, no close call, `LC.NewCharacter(ply, "infested")` in sv_livingcity_character.lua; F4 and `LC.CanJoinFaction` skip `f.zombie`).
- **Lamarr:** entities/lc_lamarr.lua, `LC.LabLamarr`, `LC.LamarrSync` hides her while Kleiner is away (sv_livingcity_lab.lua). **Dreams dressed:** `LC.DreamDress` (sv_livingcity_dreamgames.lua, 420 below the arena; `noDress` on Careless Talk). **Job boards:** entities/lc_jobboard.lua, sv_livingcity_jobboards.lua, editor mode `jobboard`.
- Open in TODO.md: the lab's dark look (needs the model in game), each dream's own card wording, the dream posters (a Fable 5.2 chat), the leader's clipboard for operations.
- The owner asked (14 November) to stop the reminder about the vanishing unit: don't raise it again unless they bring it up.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
