# Hooks, and how the code is laid out

Other code can answer the city's questions (return nil to leave it to the city): `LivingCityIsCP`, `LivingCityIsZombie`, `LivingCityIsWanted`, `LivingCityCrime`, `LivingCityCanUseCPDoor`, `LivingCityJudgeKill`.

## How the code is laid out

**For whoever works on the code (people or AI):** `CLAUDE.md` and `CORE.md` at the top of the repo say what must not change without the owner's OK and how the owner's server is actually set up; the test suite checks a snapshot of the core (`_dev/core_snapshot.txt`) and fails when it changes.

Everything is in `gamemodes/livingcity/`: `gamemode/shared.lua` lists every module in the order it loads (`LC_MODULES`), and `init.lua` and `cl_init.lua` load them from `gamemode/modules/shared`, `server` and `client`. Entities and weapons are in `gamemodes/livingcity/entities/`. The one file outside it is the editor tool (`lua/weapons/gmod_tool/stools/livingcity_editor.lua`, where Sandbox's toolgun looks for tools), and it only lists itself in this gamemode. Tests: `_dev/` (see its README).
