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

## Where things stand
- 2026-11-13 (latest, owner-asked): **a unit's HQ calls only over the radio.** The radio's right click opens the Radio menu (`LC_CL.OpenRadioQuick`/`QuickRadioRoot` in cl_livingcity_quick.lua, net `lc_radio_menu`): resupply, backup, 10-20, BOLO, records, directives, sweep, the Commander's squad; Freq 7's calls; Switch frequency. Off F2/Unit tools/C menu for units (F2 > 4 now points to the radio; an Insider's Let them slip and Inside are F2 > 5). Server gate `LC.RadioOnly` in `sv_livingcity_radiohq.lua` wraps `LC.CallBackup`, `Mark1020`, `OfficerCallSweep`, `CommanderDrop`, `LC.RunAction` and cp.lua's !records/!bolo (`lc_radio_only`). Tests give units the radio with `_radioUp(p)` (gmod_stub.lua).
- Same day: **the resupply scanner** (`LC.RequestResupply`, `LC.ResupplyNeeds` scoring, entities `lc_resupplyscanner`, `lc_resupplycrate`; `lc_resupply`, `lc_resupply_cooldown`); **gas masks** (`sv_livingcity_gasmask.lua`, `cl_livingcity_gasmask.lua`: items `gas_mask`/`gas_mask_broken`, F3 Scavenge, dead units' loot, recipe; auto on in the gas; hand over the mouth, coughing, `LC.GasFleeSpot` away from Combine units; flashbang left hand over the eyes, `lc_flash_hand`). Specs: `docs/features/radio-hq-and-resupply.md`, `gas-masks.md`. Tests `RadioHQTests`, `GasMaskTests`. Snapshot updated (7 added lines).
- Same day, later: **Half-Life 2's ammo limits** (`sv_livingcity_ammo.lua`, `lc_hl2_ammo`: `gmod_maxammo` 0 and `sk_max_*`, re-set each map start and every 5 s; `LC.ClampAmmo` at spawn, revival, dream wake; dream and story restores capped with `LC.AmmoCapped`). The resupply's full load is these limits. Spec `docs/features/ammo-limits.md`.
- Same day, later: **Freq 7 needs a transmitter to send** (`LC.SendsOnFreq7` in quickmore: backup and position too); **Fighters and up are issued a Freq 7 radio and transmitter**, locked (`LC.IssueRebelRadio`, `LC.RebelIssued`, `LC.IssuedWhy` in crafting.lua). Then **no psychic communication**: Freq 7's message, backup and position only with the transmitter in hand (`LC.RadioSay`, `RebelCallBackup`, `RebelSendPosition` check `LC.RadioHeld`; `!r` for any band too); F2 > Freq 7 is now Find the way (guides). Tests `Freq7KitTests`. F4's Jobs tab stays (owner); how job boards work at terminals is to settle (`TODO.md`).
- Unseen in game: the mask on faces (Metrocop model with every bone but the head folded; `lc_gasmask_fit`), the arm poses (`lc_handface_eyes`/`_mouth`), the scanner's model and flight, the crate's breaking.
- 2026-11-13, latest (owner-asked; core, in `CORE_CHANGELOG.md`, snapshot updated with added lines only): **speeches attended** (`sv_livingcity_speech.lua`, spec `docs/features/city.md`, tests `SpeechTests`). New point `speechcrowd`; with one placed, Give a speech calls the city (`LC.CallSpeech`): Overwatch's `speech_soon`, notices, NPC rows (`LC.SpeechSpot`, poi kind `speech`, `LC.SpeechArrive`), a podium (`lc_speech_podium`), her words after `lc_speech_muster`. Absentees: warned, the unit stays on them (`S.chaser`), the stick (`LC.ExerciseBeat` "speech") until `lc_speech_beatings`, then `LC.SpeechBlackOut` (`LC.KnockOut` now takes a notice) wakes them in the crowd. Nobody playing her: the city's own speech on days with no morning exercise (`LC.ExerciseToday`, set at dawn in exercise.lua), at `lc_speech_city_hour`, her body at the podium, stitched from 24 recorded pieces (`LC.SpeechPieces`, `LC.SpeechCompose`: open, up to three from `LC.SpeechEvents` (the chronicle, `lc_speech_lookback`) and the state of the city, one from `LC.SpeechMood` (the minds), close; said piece by piece by `SpeakOn`; hers only: `LC.AnnounceHersOnly`). A piece's id must not contain firm/stern/furious (the announcer reads those as tone). Ledger delivery is `LC.SpeechDeliver` (quiet: no chat line). No crowd point: as before.
- Same chat: **sympathizers' flat cheer** (`LC.CrowdCheer`, `LC.CrowdSalute` in exercise.lua; parades and speeches; `spy_flat_*` takes) and **the harpies dreamt in a forest** (`LC.MingeForest`, `LC.MingeCover`; `lc_ending_minge_forest/_cover/_trees`).
- Unseen in game: the podium model and placement, the salute pose on citizens, the pine model names (Episode Two guesses, filtered by `util.IsValidModel`), the crowd rows.
- Next from TODO.md (owner said yes): number-key quick menus for CP search, interrogation and the talk window; struggle at cuffs shown without a bar; posters hinting at dreams; the "save with the gamemode" tool; a new dream (airboat race or obstacle course); dynamic speeches from events and the Resistance's answer.
- The drill is now held at the jogging route's start when no exercise yard is placed (owner-asked; `LC.ExerciseYards`): the owner had only ever seen the jog.
- Full suite (run_parallel, 13 November): all pass but a few dream and timing tests that pass alone (shard order or random rolls).
- Earlier, still open: arm pose and baton glow need the owner's eyes; Careless Talk's vortigaunt delay; the chronicle file after a week; voice cue chattiness; the cuffed pose; the loading screen not hosted; job boards at terminals to settle (F4's Jobs tab stays meanwhile).
- History of every earlier chat: `TIMELINE.md`, `CORE_CHANGELOG.md`.
