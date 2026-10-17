# Living City: the core (read this before changing anything)

This is the master technical document. It lists what the owner's server, files, players and workflow depend on. **None of it changes without the owner being told first and saying yes**, in the chat, before the change is made. A new feature is fine; changing, moving, renaming or removing anything below is not, unless the owner asked for exactly that.

## The rules

1. **Read this file and `CLAUDE.md` at the start of every session.** `HANDOFF.md` has the latest work in progress; `TIMELINE.md` has every chat's work in date order and what each told the owner; `README.md` is the full specification of how everything behaves.
2. **Anything `README.md` describes is the agreed behaviour.** Change it only when the owner asks for that change, or after asking them ("this would change X to Y: OK?") and getting a yes. Never as a side effect, a tidy-up or a guess.
3. **Something isn't working?** Find out what's actually on the owner's server first (the debug report, `lc_announce_clips`, `lc_endings`, `lc_sound_check`, or ask them to look) and compare it with this file. Don't guess, and don't ask them to move or rename their files to fit the code: make the code fit what they have, and write down here what they have.
4. **The core snapshot is a tripwire.** `_dev/core_snapshot.txt` lists every setting and its default, every announcement trigger and folder, every ending, the data files, every faction and rank (with its XP), every item, and every chat and console command. The test suite compares the code with it ("the core is as the owner knows it"). If the test fails, something core changed: tell the owner exactly what (the test prints the differences, `+` added, `-` gone), and only with their OK copy `_dev/core_snapshot.new.txt` over `_dev/core_snapshot.txt`. Adding a new feature adds lines too: say what they are, the same way.
5. **An approved change is written down in the same commit:** here (if it touches anything below), in `README.md`, in the snapshot, and in the changelog at the bottom of this file, with the date and the owner's words approving it.

## The owner's setup (facts, as they are; don't assume otherwise)

- They play on **Linux Mint**: give Linux commands.
- The server is a **dedicated server on a Hexane host**, map **`rp_c18_ug`**.
- **FastDL** is `http://a29ka.hexane.co/9124749/garrysmod/` and mirrors `garrysmod/`. The host panel has a **"FastDL sync"** button: it must be pressed after every upload, or players don't get new files.
- **A new sound reaches players only after: upload, FastDL sync, a map change (the server builds its download list when a map starts), and the player reconnecting.**
- **`garrysmod/sound/livingcity/` is the official folder for every recording and song** (the owner, 2026-10-16: "we are dedicated to garrysmod/sound/livingcity now, that is to be the authoritative/official folder"); the older places are still read, but nothing tells anyone to use them.
- **The gamemode's one official place is `garrysmod/addons/livingcity/`** (the owner, 2026-10-16). No other copy (an old `addons/livingcity-rp-main`) may sit beside it: both would load.
- **Their recordings on the server** are in **`garrysmod/sound/livingcity/overwatch/`**, **`garrysmod/sound/livingcity/administrator/`** and **`garrysmod/sound/livingcity/endings/`** (straight under `sound/livingcity/`: no `announce/` folder, not inside an addon). Their announcement recordings are `.wav` files named for their trigger (`curfew1.wav`, `socio_green1.wav`, the Administrator's with her tone: `curfew_firm1.wav`). The Shalom song is `endings/shalom1.mp3`.
- **Delivering a change:** a `livingcity.zip` of the gamemode (`git archive HEAD` into `livingcity/`, without `livingcity_sound/` and `pose_recorder/`), sent as a file. **Never send a zip that could replace their sound folders**: the `livingcity_sound` folder in git holds only READMEs. A new sound file goes on its own, with exactly where to put it. `pose_recorder.zip` is the Pose Recorder addon, separate.

## Files and folders (where things are read from and saved to)

| What | Where | In the code |
|---|---|---|
| Overwatch and Administrator recordings, and the radio's | `sound/livingcity/<voice>/` **and** `sound/livingcity/announce/<voice>/` (both are read: `overwatch`, `administrator`, `radio`) | `LC.AnnounceRoots`, sv_livingcity_announcer.lua |
| Which trigger a recording is for | its file name starts with the trigger (the longest that fits): `curfew_soon1.wav` is `curfew_soon`; a `.txt` with the same name is its subtitle | `LC.AnnounceTriggerOf` |
| The Administrator's tone | `firm`, `stern` or `furious` anywhere in the name; none is warm | `LC.AnnounceToneOf` |
| Ending songs | `sound/livingcity/endings/`, flat, named for the ending's codeword (`bus.mp3`, `bus2.mp3`, `shalom1.mp3`); `.mp3`, `.ogg` or `.wav`; the older folder per ending still works | `LC.EndingOfSong`, `LC.EndingSongs`, `LC.EndingRoot` |
| The city's layout (the editor's work) | `data/livingcity/<map>.json`, with backups in `data/livingcity/backups/<map>/` | `LC.LayoutPath`, sv_livingcity_data.lua |
| Who knew whom (for "word gets around"), and news of a death still to pass on | `data/livingcity/known.json`, `data/livingcity/word.json` | sv_livingcity_life.lua |
| Lockers, storage crates and market stalls, with what's in them | `data/livingcity/<map>_storage.json` | sv_livingcity_storage.lua |
| Debug reports (each one saved as it's copied) | `data/livingcity/reports/` | sv_livingcity_debug.lua |
| When the last secret ending was | `data/livingcity/endings.json` | `LC.EndingCooldownFile` |
| The endings' dances as tuned in the Endings menu, and its shared settings | `data/livingcity/ending_tuning.json` | `LC.EndingTuneFile`, sv_livingcity_endingtune.lua |
| How the players arranged each rebel camp (the city's mattresses, crates, chairs and the like, moved with a held E) | `data/livingcity/<map>_camp.json` | sv_livingcity_campmove.lua |
| The city's named people (citizens and cops, who they are) | `data/livingcity/<map>_people.json` | sv_livingcity_people.lua |
| Charges waiting for raided players who were offline | `data/livingcity/pending_raid.json` | sv_livingcity_raids.lua |
| Each player's record (character, credits, standing, XP, faction) | PData: the server's `garrysmod/sv.db`, table `playerpdata` | |
| Pose Recorder recordings | the player's `data/pose_recorder/<name>.json` | pose_recorder/ |

Every recording and song is sent to players with `resource.AddFile` when the map starts.

## Settings

- Every setting (`lc_*`) and its default is in the core snapshot. **Settings are saved on the server (archived): changing a default never reaches a server that already has the old value.** When a default has to change (with the owner's OK), add the old and new value to the `RETUNED` table in sv_livingcity_endings.lua (`LC.EndingRetune`), which moves a server still on exactly the old default to the new one.
- **Settings changed in game are also saved per map**, in the layout file (`data/livingcity/<map>.json`, under `"settings"`) and put back on every start (`LC.RememberSetting`). A setting the owner once changed stays that way on that map, whatever its default (that's how `lc_npc_budget` stayed at 10).
- `lc_npc_budget` caps the city's NPCs (default 60). Lower than what the settings add up to, nothing more spawns (Civil Protection included); superadmins are told, and the debug report says so.

## How it all behaves

`README.md` is the specification, section by section: Install and first run; Permanent death; Civil Intake; the quick menu (F1) and the full menu (C); building a map with the editor; the city (events, escalation, the dead); the city's people (trains, the power grid, checkpoints, talking to people, lookouts); factions and ranks; Civil Protection's tools; jobs and quests; story chains; Union jobs; survival; social credit; your characters; talking, knowing people and going down; homes, trade and writing; vortigaunts; day, night and weather; staff tools; contraband and the underground; conduct; the secret endings; admin commands. Each of those is core: the tests in `_dev/tests.lua` (about 2500 of them, by section) check them.

Things players and the owner rely on that were settled in conversation:

- **Everything works through the in-game UI.** Console commands are extras for admins, never the only way. Important messages go through `LC.Notice`.
- **Switching faction from the F4 menu keeps you where you stand** (a new character, another of your characters, or an admin setting your faction starts you at a spawn point).
- **Secret endings:** the G-Man stops time, everyone votes (no votes is a yes), nobody can be hurt, the city's events and announcer are quiet, and the map reloads afterwards; one per `lc_ending_cooldown` minutes. Each ending's timing comes from its song (`lc_ending_<id>_sections`).
- **NPCs carry boxes and crates in front in both hands,** luggage at the side, small things in the hand.

## How the code must be written (or things break)

- **Never an em dash**, anywhere: `grep -rl $'\xe2\x80\x94' . --exclude-dir=.git` must print nothing.
- **Lua allows 200 local variables per function:** `sv_livingcity_endings.lua` and `_dev/tests.lua` are at the limit. Put new code in its own scope (`do ... end`, or a function, as Shalom and the newer tests do).
- **Bone poses (the dances):** on the arms, yaw raises an arm forward (minus is up), pitch takes it out to the side (minus for the right arm, plus for the left), roll twists it; a forearm bends at the elbow on yaw. On the head and spine, yaw tilts side to side, roll twists, pitch nods. Thighs: yaw swings forward and back. **Never bend the knee of a standing leg or tip the pelvis**: the feet leave the floor and the character floats. Anyone an ending holds in place goes exactly on the ground under them.
- **Every change** keeps `README.md`, `PLAYTEST.md`, the in-game guide (`cl_init.lua`, when players would notice), `_dev/tests.lua` and `_dev/client_smoke.py` up to date. The client smoke test must end `CLIENT SMOKE PASS`; the full suite (`timeout 6900 python3 run_tests.py tests.lua` from `_dev`) must pass.

## Changelog of the core (approved changes only)

- 2026-10-15: this file and the core snapshot created. Recordings are read from `sound/livingcity/<voice>/` as well as `sound/livingcity/announce/<voice>/` (the owner's folders had never been read: "you had me create a folder in garrysmod > sound > livingcity, one for overwatch, one for administrator, and one for endings").
- 2026-10-15: switching faction from F4 keeps you where you stand (the owner: "Can't I just change where I am?").
- 2026-10-17: the 17 October playtest's fixes, all approved together (the owner: "you are authorized to begin fixing them all without me prompting you"): the Administrator waits for Overwatch to finish; curfew warnings 10 s apart (was 15), units at posts warn too and come over; a job that runs with an event pays only if its count was done when the event ends; changing jobs ends the old shift; the factory's loading dock run moved to the Station Porter ("Overtime on the line" in its place); every registered citizen is assigned work (`lc_assign_work` 1, new); stealth (`lc_stealth` 1, new); freed vortigaunts in rebel ground from the start (`lc_rebel_vorts` 1, new); the bed fixture's model is CS:S's bed with a mattress first; "unit" reads "Civil Protection unit" in what players see (the radio's "Dispatch: all units" stays as it was); the stash's wording; a fridge at home opens the stash; a ration event puts the queue before work, and a line's front is the end at its dispenser; the "What now?" line with nothing on is stern; a pack's battle helmets only on the open Resistance; the sweep cart is the smaller one.
- 2026-10-17: a new secret ending, Fire (the owner asked: "new ending codename Fire: Everyone has fire shooting out of their butts ... at the end they all begin flying"). Its song is `endings/fire.mp3`; its settings are new lines in the snapshot (`lc_ending_fire_*`), and "ending fire (Fire)".
- 2026-10-17 (evening): the evening playtest's fixes and asks, all approved (the owner: "just fix all of these and implement them, no need for approval again thanks"). Changes to what was there: one voice for each announcement, picked at random (`lc_announce_admin_share` 50, new), minor ones left out right after another (`lc_announce_quiet` 60, new), no day-phase announcement during a curfew or lockdown; the Station Porter is called the **Intake Processor** (its id is still `porter`); the quartermaster charges his own the lab's price; a forged ration card costs 10 (was 25) and sells for 4 (was 8); units cuff the non-violent rather than shoot; a curfew or lockdown is about whoever was wanted or still hot when it began; an automatic curfew only at night, or in the day with unrest; sleeping holds you still till Jump and heals you; how long you've been awake is kept (PData `lc_awake_for`, `lc_rested_for`); Father Grigori at most a line a minute (`lc_grigori_talk_gap` 60, new); a raid planned ahead (`lc_raid_warning` 90, new); rebel numbers by room (`lc_rebel_room` 350, new); passages kept clear (`lc_walkway_clear` 100, new); sleepers settled onto beds (`lc_rebel_bed_height` 8, new); the rearranged camp kept in `data/livingcity/<map>_camp.json` (a new data file); the Free a vortigaunt job reworked; the factory line's parts list.
- 2026-10-16: the Endings menu added (a new feature, the owner asked: "make this now for all ending variables and have a dropdown to select the ending"); its tuning is kept in `data/livingcity/ending_tuning.json` (a new line in the snapshot).
- 2026-10-16: `garrysmod/sound/livingcity/` made the official folder for recordings and songs in every instruction (README, guide, messages); `addons/livingcity/` the one official place for the gamemode. The older sound places are still read.
- 2026-10-15: NPCs carry boxes in front in both hands (the owner: "can we make them use both hands to carry boxes out in front of them?").
