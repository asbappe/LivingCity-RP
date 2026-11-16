# Living City: handoff (short on purpose)

Read `CLAUDE.md` (house rules) and `CORE.md` (what must not change) first, then this. Everything else is on demand: `docs/features/` (the spec, one file per feature, indexed by `README.md`), `PLAYTEST.md` (the owner's playtest card: about 15 things only a person can judge; what else waits for a person is the short backlog `PLAYTEST_ARCHIVE.md`), `TODO.md` (open items and what waits on the owner), `TIMELINE.md` (history, every chat), `CORE_CHANGELOG.md` (approved core changes).

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
- **The run to trust is `python3 _dev/run_parallel.py`** (two minutes; every shard starts from a fresh city). Last runs (2026-11-14): about 6,425 passed, 3 to 11 failed, all from the unreliable list in `TODO.md`. The one-piece run (`cd _dev && timeout 6900 python3 run_tests.py tests.lua`) loads again but stops in `DreamGameTests` (tests.lua line 19504, a dream with no game) because of what earlier tests leave behind: `TODO.md`.
- Full suite on every core: `python3 _dev/run_parallel.py` (a few minutes; same last line as `run_tests.py`; see `CLAUDE.md`, Testing).
- The robot players: `python3 _dev/robots.py` (a minute and a half; must end `ROBOTS PASS`). The house rules: `python3 _dev/house_rules.py`. Both in `CLAUDE.md`, Testing.
- One section only: `python3 _dev/run_section.py "part of the section name"` or `--unit NameTests` (see `CLAUDE.md`, Testing; the code map is `docs/dev/modules.md`). Gaps in the stub: there's no IN_ATTACK, so build key lists with pairs, not ipairs; no HSVToColor; `Entity()` returns nil in the smoke test and OBBMaxs defaults to (2,24,96).

## Tools

- `python3 _dev/player_text.py` makes `PLAYER_TEXT.md` (every line of player text, for the owner to correct). Run it once at the end of a task that changed player text. Never hand-edit it or read it whole (700 KB).
- When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md`.
- Rewording drafts and originals are in `_dev/rewording/` (batches 1 to 5 done; not needed).
- `python3 _dev/voice_lines.py` writes **`VOICE_SCRIPTS.md`, the one file with every voice line** (the owner, 16 November: "We previously were using VOICE_SCRIPTS ... please consolidate"; the second file, `VOICE_LINES.md`, is gone: never bring it back or name it to the owner). What the owner has recorded is kept in `_dev/voice_done.txt` (rows ticked [x] in the file are added to it first), so ticks survive. `elevenlabs_batch.py` skips what's listed there. `_dev/voice_missing.txt` is the server's last `lc_voice_missing` list: when present it decides the ticks for every folder it checks (replace it with a newer one from the owner and rerun). `_dev/voice_seen.txt` is what existed when that list came in: a line added since is left unticked (it used to be ticked as if the server had it) and counted under "added since the server's list was made".

## Where things stand
- **IN FLIGHT (16 November, afternoon): one side job in a local worktree, NOT on `main` yet:** `worktree-agent-acf3dd62712d85d16` (`git log --oneline -5` on it): **units pursue through ladders and out of their patrol areas**, and **the hunt** (Overwatch squads sent after a marked player, hideout after hideout, until arrested: new module `sv_livingcity_adminhunt.lua`). Merge what is committed if its tests pass (compile every Lua file, the units, client smoke), else finish it. **Merged since the morning:** the shield run, the close call scene (`LC.CloseCallSurvived`), the rogue unit (`LC.BurnInsider(ply, rogue)`), only explosive grenades jumped on, the Administrator-led interrogation and the stalker ending (`sv_livingcity_adminquestioning.lua`, `LC.ZoneStalkerAdopt`), frag grenades at the Commissary and one for NPC soldiers. **Asked and not built (`TODO.md`, last items):** the helicopter; the coordinated Resistance attack when the attempt was ordered.
- 2026-11-16: **the owner's 15 November card notes and what they asked for that night are all built, merged and on `main`**, except the two items below. Nothing of it has run in the real game yet: `PLAYTEST.md` is the card (15 things), and every spec is in `docs/features/` (`city.md` for her address, `city-events.md` for the parade and the drill, `pose-tool.md`, `pose-recorder.md`).
- **Still to build (the owner: "tomorrow we'll build the shield run"):** her other way out after an attempt: with no APC point by the stand, every Combine at the address forms a shell round her and runs her to her office at 5 times walking speed, moved by script (through doors and NPCs, firing at the attackers, never stopping). `TODO.md`, last items.
- **The 21 dream posters are drawn (16 November, the owner: "please make these posters"):** every dream you play has its picture (`materials/livingcity/posters/dream_<codeword>.jpg`, `_dev/posters/dreams5.js` to `dreams7.js`), in `livingcity_content.zip`. Not made: `dream.png` and `dream_x.png` (`TODO.md`: ask first).
- **Her address** (`sv_livingcity_speech.lua`, `sv_livingcity_adminsecurity.lua`): everyone is called whatever they are doing (`LC.ExerciseDraftable`, `LC.ExerciseCallAway`, `LC.PeopleCallOut`; `lc_speech_npcs` and `lc_exercise_npcs` 0 = everyone); a row of three and a detail of four; keep back (one warning, then shot); a grenade is dived on; an attempt (a hit, a near miss within 320 units, a projectile) means the ring, the glass and the APC (point kind `adminapc`); a hit is a close call, never a kill; the attacker gets -999 standing and is wanted for that character's life (`lc_regicide`).
- **The parade** (`sv_livingcity_exercise.lua`): 8 soldiers, an APC prop rolled by script, two hunters, a strider; `lc_parade_music` (the file name is unconfirmed: the debug report says which piece played); fights back only at attackers and re-forms at the last route node.
- **The Miscount Poser** builds on Pose Recorder 2.1 (`pose_recorder/`, its own zip: `pose_recorder.zip`): poses in `data/livingcity/poses.json`. One Combine monitor only (the hanging one).
- **A default that changes goes in `RETUNED`** (sv_livingcity_endings.lua) or the owner's server keeps the old value: added this round for the Harpies' forest, `lc_speech_npcs`, `lc_exercise_npcs`.
- **Hook order is not promised:** a hook that answers first hides the event from the rest (an EntityTakeDamage hook that returned true hid the shot from the exit's trigger in a test). Where it matters, listen in two places.
- **Side jobs:** two at a time at most (the owner's usage limit, hit twice on 15 November). Commit and push after every finished piece; a WIP commit before tests is fine.
- Earlier, still true: `run_parallel.py` is the run to trust (about 5 of 7,200 fail from run to run: `TODO.md`); the robots; the house rules; don't raise the vanishing unit.
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
