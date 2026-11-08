# Living City: the core (read this before changing anything)

This is the master technical document. It lists what the owner's server, files, players and workflow depend on. **None of it changes without the owner being told first and saying yes**, in the chat, before the change is made. A new feature is fine; changing, moving, renaming or removing anything below is not, unless the owner asked for exactly that.

## The rules

1. **Read this file, `CLAUDE.md` and `HANDOFF.md` at the start of every session (all short).** Open the rest only when the task needs it: `README.md` is an index to `docs/features/` (one file per feature: read only the one you are changing); `TIMELINE.md` has every chat's work in date order; `CORE_CHANGELOG.md` has every approved core change.
2. **Anything `docs/features/` describes is the agreed behaviour.** Change it only when the owner asks for that change, or after asking them ("this would change X to Y: OK?") and getting a yes. Never as a side effect, a tidy-up or a guess.
3. **Something isn't working?** Find out what's actually on the owner's server first (the debug report, `lc_announce_clips`, `lc_voice_missing`, `lc_endings`, `lc_sound_check`, or ask them to look) and compare it with this file. Don't guess, and don't ask them to move or rename their files to fit the code: make the code fit what they have, and write down here what they have.
4. **The core snapshot is a tripwire.** `_dev/core_snapshot.txt` lists every setting and its default, every announcement trigger and folder, every ending, the data files, every faction and rank (with its XP), every item, and every chat and console command. The test suite compares the code with it ("the core is as the owner knows it"). If the test fails, something core changed: tell the owner exactly what (the test prints the differences, `+` added, `-` gone), and only with their OK copy `_dev/core_snapshot.new.txt` over `_dev/core_snapshot.txt`. Adding a new feature adds lines too: say what they are, the same way.
5. **An approved change is written down in the same commit:** here (if it touches anything below), in the matching `docs/features/` file, in the snapshot, and in `CORE_CHANGELOG.md`, with the date and the owner's words approving it.

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
| Performance debugger reports (saved when it stops, or on Save report; the newest 30 kept) | `data/livingcity/perf/` | sv_livingcity_perfdebug.lua |
| When the last secret ending was | `data/livingcity/endings.json` | `LC.EndingCooldownFile` |
| The endings' dances as tuned in the Endings menu, and its shared settings | `data/livingcity/ending_tuning.json` | `LC.EndingTuneFile`, sv_livingcity_endingtune.lua |
| How the players arranged each rebel camp (the city's mattresses, crates, chairs and the like, moved with a held E) | `data/livingcity/<map>_camp.json` | sv_livingcity_campmove.lua |
| The city's named people (citizens and cops, who they are) | `data/livingcity/<map>_people.json` | sv_livingcity_people.lua |
| Charges waiting for raided players who were offline | `data/livingcity/pending_raid.json` | sv_livingcity_raids.lua |
| Each player's record (character, credits, standing, XP, faction) | PData: the server's `garrysmod/sv.db`, table `playerpdata` | |
| Dream snapshots (everything about a dreamer, until it's all put back) | `data/livingcity/dreams/<steamid64>.json` | sv_livingcity_dreams.lua |
| Propaganda dreams' music, flat, named for its codeword (`admire`, `adore`, `roses`, `mirror`, `saviour_horde`, `saviour`, `quiz`, and for the ten more `harvest`, `shift`, `spy`, `newsreel`, `hate`, `massgames`, `guidance`, `scrap`, `flowers`, `duck`, `ravenholm`, or `propaganda` for any of those); her voice lines in `voice/`, named for the line, a `.txt` its subtitle; the older `dreams/administrator/` still counts as `admire` | `sound/livingcity/dreams/` | `LC.PropagandaSongs`, `LC.PropagandaVoice`, sv_livingcity_propagandadreams.lua (and sv_livingcity_propagandamore.lua) |
| The Administrator's Commissary rules and the market's stock and demand | `data/livingcity/<map>_market.json` | sv_livingcity_market.lua |
| Pose Recorder recordings | the player's `data/pose_recorder/<name>.json` | pose_recorder/ |

Every recording and song is sent to players with `resource.AddFile` when the map starts.

## Settings

- Every setting (`lc_*`) and its default is in the core snapshot. **Settings are saved on the server (archived): changing a default never reaches a server that already has the old value.** When a default has to change (with the owner's OK), add the old and new value to the `RETUNED` table in sv_livingcity_endings.lua (`LC.EndingRetune`), which moves a server still on exactly the old default to the new one.
- **Settings changed in game are also saved per map**, in the layout file (`data/livingcity/<map>.json`, under `"settings"`) and put back on every start (`LC.RememberSetting`). A setting the owner once changed stays that way on that map, whatever its default (that's how `lc_npc_budget` stayed at 10).
- `lc_npc_budget` caps the city's NPCs (default 100). Lower than what the settings add up to, nothing more spawns (Civil Protection included); superadmins are told, and the debug report says so.

## How it all behaves

`docs/features/` (indexed by `README.md`) is the specification, one file per feature, covering: Install and first run; Permanent death; Civil Intake; the quick menu (F1) and the full menu (C); building a map with the editor; the city (events, escalation, the dead); the city's people (trains, the power grid, checkpoints, talking to people, lookouts); factions and ranks; Civil Protection's tools; jobs and quests; story chains; Union jobs; survival; social credit; your characters; talking, knowing people and going down; homes, trade and writing; vortigaunts; day, night and weather; staff tools; contraband and the underground; conduct; the secret endings; admin commands. Each of those is core: the tests in `_dev/tests.lua` (about 2500 of them, by section) check them.

Things players and the owner rely on that were settled in conversation:

- **The keys (approved 7 November):** F1 the quick menu (what everyone can do), F2 the same for your side, rank and job, F3 your pockets, F4 Jobs, Career and Factions as tabs.
- **Everything works through the in-game UI.** Console commands are extras for admins, never the only way. Important messages go through `LC.Notice`.
- **Switching faction from the F4 menu keeps you where you stand** (a new character, another of your characters, or an admin setting your faction starts you at a spawn point).
- **Secret endings:** the G-Man stops time, everyone votes (no votes is a yes), nobody can be hurt, the city's events and announcer are quiet, and the map reloads afterwards; one per `lc_ending_cooldown` minutes. (Approved 7 November: with a "Point: dream" placed, the Administrator can choose a dream for tonight from the tablet, played for sleepers only at the dream point, with no reload and everything put back on waking; the G-Man's sealed directives, sleep visits and talks are off by default, `lc_directives` 0, kept for a future endings setup.) Each ending's timing comes from its song (`lc_ending_<id>_sections`).
- **Dreams and nightmares (approved 7 November, part 3):** players may opt out of Happy and Neutral dreams, not out of a Nightmare: everyone asleep dreams a Nightmare, and nobody wakes themselves from one until they are out of it. Only a stimulant shot (it keeps you from sleeping for 15 minutes) keeps you out of one. In a dream you play, someone out of lives (or who won) chooses to wake now or watch until it is over; winners wake Unbroken (a day of no Breen's-water fog and no nightmare) with a second wind (a day of tiring and hungering slower), plus a Vortigaunt's whisper for a citizen or a Vortigaunt's gift for the Resistance, never credits, standing or experience (approved 8 November); whoever lost every life has 30 off their health until their next full night's sleep. A nightmare reaches everyone asleep outside a Combine-only zone; anyone asleep inside one is spared. Cigarettes, alcohol and stimulants are items (`cig_union`, `cig_rolled`, `beer`, `vodka`, `moonshine`, `stimulant`).
- **Propaganda dreams (asked for 8 November):** five dreams you play on her tablet, under Happy, listed as "Propaganda: ..." (Kneel Before Her, Roses for Her, Mirror, Mirror, The Saviour, The Loyalty Quiz): flattery, heroics and loyalty, nothing explicit. Not skippable (no opting out, no waking yourself until out of it; Unbroken spares you). Disloyalty in one (each life lost, insults, thoughtcrime) costs 3 loyalty points (Civil Standing), 5 more for being thrown out, at most 20; no health lost. The Saviour's rescue comes when a dreamer is down to 25 health; her soldiers only shoot monsters. If the Administrator is asleep for one with someone else and her tablet's "Star in propaganda dreams yourself" is on (the default), she plays her part herself. **Ten more (asked for 8 November, "Can we build them all?"),** the same way: Record Harvest, The Stakhanov Shift, Careless Talk, The Newsreel, Two Minutes of Hate, The Mass Games, On-the-Spot Guidance, The Scrap Drive, Flowers for the Liberators, Duck and Cover, and Ravenholm (her version unless a vortigaunt freed from its shackles, player or NPC, is alive, then the truth) (`docs/features/endings.md`). Dreams are goofy: the Resistance can be giant, glowing red and flying (the owner, 8 November).
- **NPCs carry boxes and crates in front in both hands,** luggage at the side, small things in the hand.

## How the code must be written (or things break)

- **Never an em dash**, anywhere: `grep -rl $'\xe2\x80\x94' . --exclude-dir=.git` must print nothing.
- **Lua allows 200 local variables per function:** `sv_livingcity_endings.lua` and `_dev/tests.lua` are at the limit. Put new code in its own scope (`do ... end`, or a function, as Shalom and the newer tests do).
- **Bone poses (the dances):** on the arms, yaw raises an arm forward (minus is up), pitch takes it out to the side (minus for the right arm, plus for the left), roll twists it; a forearm bends at the elbow on yaw. On the head and spine, yaw tilts side to side, roll twists, pitch nods. Thighs: yaw swings forward and back. **Never bend the knee of a standing leg or tip the pelvis**: the feet leave the floor and the character floats. Anyone an ending holds in place goes exactly on the ground under them.
- **Docs are updated once per task, in one batched pass at the end** (not after each change): the touched `docs/features/` file(s), `PLAYTEST.md`, the in-game guide (`cl_init.lua`, when players would notice) and this file when the core changed. `_dev/tests.lua` and `_dev/client_smoke.py` go with the code. `PLAYER_TEXT.md` is only ever made by `python3 _dev/player_text.py`, run once at the end when player text changed; never hand-edit it. The client smoke test must end `CLIENT SMOKE PASS`; the full suite (`timeout 6900 python3 run_tests.py tests.lua` from `_dev`) must pass (the owner asked to run the full suite only when they ask: see `HANDOFF.md`, Testing).


## Changelog

Approved changes are recorded in `CORE_CHANGELOG.md` (history: open it only to add an entry or when asked about a past decision).
