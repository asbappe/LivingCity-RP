# Handoff: the 7 November lists, part 2

The owner's answers on the three open core items, the rest of their first 7 November list, and their whole second list ("next batch"). Built by the coordinator plus nine workers in worktrees, merged into `main`. **Nothing here is checked in game.** Each item has a line in `PLAYTEST.md` under "7 November, part 2".

## The owner's answers

- First ration skipping the dock: **no**, undone.
- CP players in the HL:Alyx metrocop model: **yes** (the owner has the playermodels installed).
- The `lc_cleanup_guards` help text: now says Overwatch soldiers (the owner hadn't followed what it meant).

## Built (where to look)

- **Labor Assignment terminal** (`sv_livingcity_labor.lua`, `cl_livingcity_labor.lua`, union-jobs.md). Without one on the map, the old way.
- **Rebel food scaling** (`sv_livingcity_scavenge.lua`, city-economy.md): crate deliveries sized to the Resistance online, about half their need.
- **Shared dreams** (`sv_livingcity_dreams.lua`, `cl_livingcity_dreams.lua`, endings.md, endings-notes.md): only with a dream point placed; snapshot to memory and `data/livingcity/dreams/`, verified restore. Admin's `lc_ending` stays whole-city.
- **Small fixes:** a worn disguise keeps its pocket room; the kick shows only the legs; sweeps wait out other fights, are called off out loud, and meet the units who joined.
- **Faction change** (`sv_livingcity_reconcile.lua`): job, tools, suit look cleared for non-workers on connect, spawn, faction, rank, job change. Ration vouchers, the CP Commissary's daily kit and vest charging (`sv_livingcity_cpsupply.lua`), radio R, editor tool pauses sleep, full-look bodies.
- **Arrests** (`sv_livingcity_arrest.lua`, `cl_livingcity_arrest.lua`, civil-protection-tools.md): cuffed in place, walked in, an E-pressing struggle, rebels arrestable, a committed shove-and-run.
- **Combine ground** (`sv_livingcity_combineground.lua`): soldiers home, citizens out, a stalker clears up, rebel warnings off inside, crab carcasses cleared.
- **Field ops** (`sv_livingcity_fieldops.lua`, `sv_livingcity_labdamage.lua`, `sv_livingcity_career.lua`): Retake the block, armed backup, flashbang stun, `lc_quest_allies` friends on violent jobs, the Missing Unit's zombine, C > My career, the contraband suspect, lab damage and "Get the lab running".
- **Guidance** (`cl_livingcity_context.lua`, `cl_livingcity_trail.lua`, `sv_livingcity_guidance.lua`): the context panel and the quest trail.
- **Pacing** (`sv_livingcity_pacing.lua`, `docs/dev/pacing-audit.md`): panting on one handle, rain 30% quieter, sleep warnings, citizens' night hours, one PA voice at a time, event spacing doubled, combat music for units.

## Core

Everything new is in `CORE_CHANGELOG.md` (2026-11-07 part 2) under "Not yet OK'd". `_dev/core_snapshot.txt` is not updated, so the snapshot test fails until the owner says yes. Open questions are in `TODO.md`.
