# Living City: timeline of every chat

Built on 2026-10-16 from the exports the owner pasted in from each chat, plus this chat's own work. Duplicate exports were merged. Each line is `TYPE | area | what (where; note)`. `?` means the chat that did it didn't know or didn't record it. Undated items are grouped where their chat sits in time.

**Read first:** the section right below, "Disagreements", lists every place where something a chat told the owner, or built, differs from `CORE.md` or from the code as it is now. Each one was checked against the code on 2026-10-16. Nothing has been changed because of them: each needs the owner's answer first (`CORE.md`, rule 2).

## Disagreements with CORE.md and the code (checked 2026-10-16)

1. **The "v2.7" work of 2026-10-04 never reached the code.** A chat outside git built, that day: stamina, weapons held lowered (hold R, `lc_raise`), brandishing a gun as a crime, `lc_serious` with walk 100 / run 210 / jump 170, colour grading (`lc_grading`), view sway (`lc_viewbob`), a CID on each character, an obituary line, longer street detentions (`lc_street_detention` 20 to 60, scaled by wanted time), `LC.FindPlayer` by CID, headcrabs only near infest zones (`LC.VerminSpot`), cops fighting monsters (`LC.Fight`, `LC.FleeSpot`), its own nav routing (`LC.WanderFrom`). It ended "v2.7 never packaged or sent". The same day, the git chats built their own versions of some of it, and those are what runs: `lc_slow_movement` 1, walk 110, run 190, jump 200, jump delay 0.9; `lc_permadeath` 1 (v2.7 had -1, "auto"); `sv_livingcity_character.lua` with nets `lcc_open`/`lcc_submit` (v2.7 had `sv_livingcity_characters.lua`, `lcc_create`); `lc_street_detention` is still **20**. None of the names above (`lc_serious`, `lc_raise`, `lc_grading`, `lc_viewbob`, `VerminSpot`, `LC.Fight`) exists in the code. **Question for the owner:** do you want any of the lost v2.7 pieces (stamina, lowered weapons, brandishing, longer detentions, CID) rebuilt? **Owner (10-16): add to the TODO list** (done).
2. **`lc_resetplayer` and `lc_resetall` don't exist.** The v2.x chat told the owner to clear player records with them. The code has `lc_newcharacter`, `lc_characters`, `lc_setname`, but no reset command. **Question:** should one be added back, or is a new character enough? **Owner (10-16): ignore for now.**
3. **Where the recordings go: README.md still leads with the sound addon.** CORE.md says the owner's recordings are in `garrysmod/sound/livingcity/overwatch/`, `administrator/` and `endings/`. README.md (install step and "Custom announcements") still says to install `livingcity_sound.zip` into `garrysmod/addons/` and put them in `addons/livingcity_sound/sound/livingcity/announce/`, with the owner's folders only as "they can just as well go". Both are read, so nothing is broken, but the README tells a newcomer the opposite of what the owner does. The history of this, so nobody repeats it: 10-07 the owner's own folders were `.../content/sound/livingcity/announce/breen/<trigger>/`; 10-09 `breen` became `administrator`; 10-11 told `gamemodes/livingcity/content/sound/...` (the owner had no such folder), then moved to `addons/livingcity/sound`, then (owner's request) to a separate `addons/livingcity_sound` addon, then (owner's request) flat folders, trigger and tone in the file name; 10-14 FastDL needs `garrysmod/sound/livingcity/announce/<voice>/`; the owner made `garrysmod/sound/livingcity/<voice>/`, which was never read until 10-15. **Proposal:** rewrite those README lines so the owner's own location comes first and the addon second. OK? **Owner (10-16): `garrysmod/sound/livingcity/` is the authoritative, official folder.** README, the guide, the messages and CORE.md now say so; the older places are still read.
4. **Data files missing from CORE.md.** The code also saves `data/livingcity/<map>_people.json` (the city's named people, since 10-04), `data/livingcity/pending_raid.json` (charges for raided players who were offline; the owner was never told), and every player's record in PData (`garrysmod/sv.db`, table `playerpdata`). Added to CORE.md's table as facts (no behaviour changed). Done.
5. **Settings are saved per map in the layout.** Since the long build chat (owner: "population sliders reset on restart"), every `lc_` setting changed in game is stored in `data/livingcity/<map>.json` under `"settings"` and put back on every start (`LC.RememberSetting`). That's why `lc_npc_budget` stayed at 10 on the owner's server (default 60): once set, it sticks for that map until changed again. CORE.md said only "archived"; added as a fact. Done. The editor's "NPC budget (hard cap)" slider goes down to 10, so it was likely dragged there once and then kept for the map; the past playtests' low NPC counts fit this.
6. **Old ending names aren't read.** Songs were first told to go in folders named `harpies`, `crazybus`, `nuanua`, `topsecret`, `grigori` (10-13). The endings were renamed `bus`, `plane`, `standup`, `water` (the Flood) on 10-14. The code knows only the new names (`harpies`, `bus`, `plane`, `standup`, `water`, `bloom`, `marrow`, `base`, `hard`, `shalom`); a song still called `crazybus.mp3` or in a `nuanua/` folder plays for nothing. `lc_endings` lists any song whose name matches no ending. **Ask the owner:** run `lc_endings` once and paste it. **Owner (10-16): the old names were scrapped on purpose, to be less on the nose** (crazybus became bus, nuanua plane, and so on). Nothing to do.
7. **Two copies of the gamemode on the server?** On 10-04 the owner's debug report showed the addon at `addons/livingcity-rp-main` (a GitHub download); on 10-07 the SFTP queue used `addons/livingcity/`; the delivery now is `livingcity.zip` into `addons/livingcity/`. If both folders are on the server, both load. **Ask the owner:** check `garrysmod/addons/` has only one Living City folder (plus `livingcity_sound` if used). **Owner (10-16): `addons/livingcity` is the newest and official place.** In CORE.md and README.
8. **`lc_bloom_leg_sign` was removed on 2026-10-15** (this chat) while fixing Bloom's feet, without asking first. It was a client setting added 10-14 ("if feet splay: `lc_bloom_leg_sign -1`"); the reworked dance no longer uses it (`e8b24ce`). Owner: say if you want it back. **Owner (10-16): never used it; wants every tweakable dance and pose setting as a live slider in an Endings menu** (in TODO.md).
9. **Branches.** `main` exists on GitHub (made 10-04 at `1614333`) but is far behind: work went on in `claude/youthful-rubin-j6lyfk` (to 10-15) and now `claude/intelligent-curie-p02qp4`, which holds everything. The youthful-rubin chat thought there was no `main`. The owner's GitHub default branch is `?`. **Proposal:** when you're ready, make `main` the latest and the default, so a new chat starts from it. OK? **Owner (10-16): yes, back to `main`.** `main` brought up to date the same day; CLAUDE.md now says to push finished work to `main`.

Checked and in agreement: hacker cap 2 (`sh_livingcity_factions.lua`); `lc_mantle_height` 108; `lc_cp_min_standing` 100; `lc_stock_eat` 40; `lc_morning_exercise` (setting) vs `lc_exercise` (command); the ranks ladder; `lc_ending_cooldown` 60; Marrow max 80; Base bombs 60; Hard moments every 5 beats, 3 at once; the Combine-only zone and auto-locked prison doors (asked for in v2.7, built in git on 10-04); welcome only for the unregistered; `lc_administrator_model` `models/mossman.mdl` (whether that path exists in game is still `?`).

## Before 2026-10-04: v2.1 to v2.6 (chat outside git; versions before 2.1 not itemised)

- DECISION | underground | owner: "yes please" to more jobs and Commissary goods that change the world (radios, disguises, forged papers)
- FEAT | jobs | 12 occupations with shifts (`sh_livingcity_jobs.lua`, `sv_livingcity_work.lua` SHIFTS)
- FEAT | underground | radios (!r / !ru), disguises, papers (blank/forged/dead), permit, forged ration, lockpick/bypass/keycard, forging, home stash with raids, black market (`sv_livingcity_underground.lua`, `sh_livingcity_shop.lua`)
- DECISION | stops | owner asked for random cop stop-and-search of players and NPCs
- FEAT | stops | `LC.Stops`, `!search`, baton reload search; settings `lc_stops`, `lc_stop_chance`, `lc_street_stop_chance`, `lc_stop_cooldown`, `lc_search_cooldown`, `lc_disguise_risk`, `lc_identity_minutes`, `lc_stash_size`, `lc_raid_chance`, `lc_search_weapons`
- FIX | cops | bumping or punching cops only warned: `LC.CopProvoked` escalation (warn, shove, stick, "Obstructing Civil Protection"), shot cops react
- FEAT | escalation | alert thresholds 1/4/8/14: pistols, soldier squads, lockdown and scanners (`sv_livingcity_response.lua`, `lc_setalert`)
- DECISION | standing | owner asked for a way to clear anticitizen status
- FEAT | standing | community service "Civil rehabilitation" (+40), surrender, +10 for compliance
- FEAT | prison | with no cells, arrests become street detentions (`LC.DetainOnTheSpot`; `lc_street_detention` 20, `lc_street_fine` 25)
- DECISION | gamemode | owner wanted its own gamemode instead of Sandbox, and later a hosted server
- CORE | gamemode | `gamemodes/livingcity` derived from Sandbox: build-only restrictions, `!build` / `lc_buildmode`, F1 guide, autostart, fists; maps `^rp_`, `^d1_trainstation`, `^d3_c17`, `^gm_city`
- SETUP | gamemode | owner told how to install and select the gamemode (wording `?`)
- FIX | rations | NPCs stood still in the ration line (`LineThink`, `LC.ServePlayersAtLine`)
- FEAT | editor | ration dispenser placed with the editor (`lc_dispenser.lua`)
- FIX | speech | NPCs called the player "Gordon Freeman" (`LC.FilterSpeech`)
- FEAT | editor | aimed-at zone shows a ground fill (client `lc_zone_fill`)
- SETUP | saving | layout saved on every edit to `data/livingcity/<map>.json`; backups every 300 s, keep 30, in `data/livingcity/backups/<map>/`; `lc_backup`, `lc_backups`, `lc_restore` (matches CORE.md)
- CORE | rename | black market "fence" renamed "dealer" (`lc_dealer`, `!dealer` / `!market` / `!blackmarket`); old points migrated
- FIX | scanners | stuck on walkways (`ScannerAltitude`)
- FEAT | inspections | cops walk up close and gesture (`LC.FRISK_ANIMS`)
- NOTE | fists | the fists are GMod's `weapon_fists`
- FIX | fixtures | dispenser at eye level, vending machine on the floor (`LC.SeatFixture`)
- FIX | bodies | duplicate bird ragdoll removed
- FEAT | bodies | searchable corpses, a crime if seen (`lc_bodies` 1, `lc_body_time` 300, `lc_max_bodies` 16)
- FIX | quests | lost elder: elderly models, smoother escort, arrival anywhere in the zone
- SETUP | records | player records live in PData (`garrysmod/sv.db`, table `playerpdata`); clear with `lc_resetplayer` / `lc_resetall yes` (**these commands no longer exist: Disagreement 2**)
- ISSUE | install | the owner's reports came from old builds (v2.1, v2.5); told to install the newer zip

## 2026-10-04

Three chats that day, in parallel: the git import (`claude/focused-planck-qtpuph`), a second git chat (`claude/friendly-cerf-yisnre`, which made `main`), and the v2.7 chat outside git (**never shipped: Disagreement 1**).

**Git import and gameplay overhaul** (`claude/focused-planck-qtpuph`, commits `e378275..668e7e8`)
- SETUP | repo | zip contents copied to the repo root and pushed (`e378275`); owner asked to "put project in repo"
- DECISION | repo | owner asked to "auto merge": nothing to merge; `main` not created in this chat
- DECISION | design | serious RP: death is a new character (like Synapse), a slower feel; visuals out of scope
- CHANGE | HUD | big faction panel ("Citizen Citizen") removed; compact stack top-left (`9599615`)
- FEAT | permadeath | dying is a new character, wiping credits, standing, XP, job, inventory, stash, story; zombies, admins in build mode and prisoners exempt; strikes and combat log kept (`sv_livingcity_character.lua`, `lc_permadeath` 1, `lc_newcharacter`)
- FEAT | movement | slow grounded movement: `lc_slow_movement` 1, `lc_walk_speed` 110, `lc_run_speed` 190, `lc_jump_power` 150 (later 200), `lc_jump_delay` 0.9, no crouch-jump (`shared.lua`)
- FEAT | zones | zone kind "combine" (Combine only): citizens avoid it, players get `lc_trespass_grace` 10 s then wanted
- FEAT | editor | points `zspawn` (infestation spawn) and `rspawn` (resistance spawn); citizens never spawn on Combine textures, in Combine/infest/prison areas
- CORE | doors | doors within 450 of cells or inside prison/Combine zones are CP-only unless tagged (`LC.AutoDoorTag`)
- CHANGE | curfew | grace before warnings (`lc_curfew_grace` 60), HUD countdown; NPCs walk home
- FEAT | events | block raids (`sv_livingcity_raids.lua`, `lc_raid_units` 3, `lc_raid_stash_chance` 60); offline owners charged later via `data/livingcity/pending_raid.json` (owner never told: Disagreement 4)
- CHANGE | props | map stoves, sinks and vending props usable
- FIX | quests | promotion no longer strips weapons
- CHANGE | quests | bin round uses the map's bins (owner: floating bins were silly)
- FIX | quests | quest marker always sent; patient spots avoid Combine/prison areas
- FEAT | HUD | objective compass (owner asked)
- CHANGE | quests | neighbor's errand pickup in a housing block (`bab0c71`), later person-based
- FEAT | static props | stoves, sinks, vending read from the map's BSP (`sv_livingcity_staticprops.lua`, `lc_scanprops`); tested only on a mock file
- CHANGE | quests | deliveries go to people you press E on (`f473127`, `3c52f39`)
- FIX | UI | quest choice dialog wraps and scrolls (owner saw only the first option)
- FEAT | NPCs | persistent named people per map (`sv_livingcity_people.lua`, `lc_roster_size` 30, `lc_roster_cops` 10, `lc_rebel_pct` 12, `lc_people`, `lc_resetpeople`; file `data/livingcity/<map>_people.json`)
- FEAT | character | creator on first join and each new life; name rules 1-3 words, 3-26 characters (owner corrected the first draft), blocklist, unique; `!character`, `lc_setname`, `lc_creator`
- CHANGE | editor | overlay decluttered (`lc_show_all_npcs`)
- CHANGE | character | 5-minute edit lock removed (owner: "nah, remove that")
- FEAT | economy | dealer buys almost anything (40%) and carried weapons; lockpick from 4 scrap; `!pick`
- CHANGE | factions | joining CP needs Civil Standing 100 (`lc_cp_min_standing`; owner asked)
- CHANGE | prison | escape margin `lc_prison_buffer` 150
- FIX | movement | jump 150 to 200; mantle onto ledges; `!stuck` (`lc_stuck_cooldown` 300); owner was stuck on rails
- ISSUE | permadeath | owner died and stayed the same character; cause not found (build mode suspected)
- FIX | prison | prisoners keep fists; CP doors physically locked
- FIX | NPCs | pressing E on a unit isn't crowding; wanderers stay local (owner's map had 0 path nodes)
- CHANGE | quests | "Something you saw" at real bins
- OPEN (then) | nothing run in the real game; client UIs untested; "died and same character" unexplained; nexus needs a Combine-only zone drawn

**Running cops, tail meter, dumpster quest, NPC arrests, routing, holster** (`claude/friendly-cerf-yisnre` then `main`, commits `d33d9c9..1614333`)
- FEAT | cops | "Stop running!" then wanted for fleeing (`sv_livingcity_running.lua`, `lc_running_cops` 1, `lc_run_range` 500, `lc_run_react` 2, `lc_run_memory` 30, `lc_run_wanted` 60); shout banner on screen
- FEAT | quests | informant tail: suspicion meter instead of instant fail
- DECISION | git | owner chose to create `main` (`5f94d97`); told to make it the default branch and delete the old `claude/*` branches (**not done: Disagreement 9**)
- FEAT | static props | dumpsters read from the map; "Something you saw" always at a dumpster, two citizens acting out a hand-off (owner request)
- FIX | gamemode | the city never auto-started (`init.lua` indexed a nil GM)
- FIX | stories | neighbor pronouns follow the NPC's gender; story characters spawn with fixed genders
- CORE | people | first names split male and female; saved people re-picked to match their name
- FEAT | CP | baton R on a citizen NPC is a pat-down; E on a citizen as CP shows a hint
- CHANGE | prison | NPC arrests: cuffed then put in a cell (later replaced by the march, 10-08)
- FEAT | nav | reads the map's node links; A* routes around zones (`sv_livingcity_navgraph.lua`); stuck teleport only under 700 units
- FEAT | holster | everyone spawns with empty hands (`weapon_lc_hands`); R, `!holster`, `lc_holster` (owner request: no accidental punches); told `bind h lc_holster`
- SETUP | server | owner told: update the addon from `main` and restart; the report showed the addon at `addons/livingcity-rp-main` (Disagreement 7)

**v2.7, outside git (never packaged or sent: Disagreement 1)**
- DECISION | characters | permadeath and a slower feel, no bunny hopping
- FEAT | characters | CID, creator, rename window, obituary (`sv_livingcity_characters.lua`, `lc_permadeath` -1, `lc_rename_window` 300)
- FEAT | movement | stamina, lowered weapons, brandishing (`lc_serious`, walk 100, run 210, jump 170)
- FEAT | look | colour grading, view sway (`lc_grading`, `lc_viewbob`)
- CHANGE | prison | `lc_street_detention` 20 to 60, scaled by wanted time
- DECISION/CHANGE | HUD | "Citizen Citizen" box removed (also done in git)
- FEAT | nav, monsters, vermin, map bins | own versions; the git ones are what runs
- DECISION | prison/zones | owner asked for doors near cells to lock and a Combine-only zone (built in git the same day)

## 2026-10-05 to 10-07: long build chat (outside git; delivered as a zip with HANDOFF.md)

Undated, in order:
- FEAT | power | Combine power bank work (details lost)
- FEAT | response | squads sent to alarms (`lc_squad`, `lc_squad_cops` 2, `lc_squad_soldiers` 1, `lc_squad_delay` 5)
- FEAT | heist | data breach adds 2 soldiers at the master terminal
- FEAT | garrison | Combine through the nexus (`sv_livingcity_garrison.lua`, `lc_garrison` 6, `lc_garrison_cops` 3, `lc_garrison_respawn` 90; owner request)
- DECISION | turrets | owner: keep turrets toppling over
- CHANGE | infest | thicker yellow haze
- FEAT | CP | metrocops draw pistols during a judgement waiver
- FIX | territory | rebel territory spreading off a roof; may only spread where an NPC can walk (owner correction: "he didn't draw that circle")
- FIX | doors | "Door: always open" stays open (owner report)
- FIX | factions | Hacker special lost after rejoining (owner report)
- DECISION | process | owner raised the effort level to "extra"
- CORE | settings | **settings saved per map in the layout JSON** (owner: "population sliders reset on restart"; `LC.RememberSetting`; Disagreement 5)
- CHANGE | power | transformer is `combine_generator01` with a lamp and a hum
- FEAT | editor | persistent prop tool (zap a prop to keep it)
- CHANGE | heist | data breach needs 2 terminals; master terminal is the motherlode (`res_motherlode` 120)
- CHANGE | mortuary | incinerator is `headcrabcannister01a` with a flame
- CHANGE | sound | music 20% quieter
- FIX | quests | gun-run crate breaks open into supplies (owner report)
- FIX | doors | Combine NPCs route through CP-only brush doors
- FEAT | quartermaster | decodes data chips
- FEAT | bodies | dead soldiers drop their gun (`lc_gun_drops`)
- CHANGE | items | "Returned radio" renamed "radio" (owner request)
- FEAT | supply | dropship for drops and Overwatch landings, APC by road (owner disappointed nothing happened at the LZ)
- CHANGE | economy | Civil Standing chat batched into one line (owner request)
- FIX | escort | runs under fire; ladders (`lc_learn_ladders`)
- CORE | factions | Hackers per server cut to 2 (owner request; old value `?`)
- FEAT | survival | vending machines and dispensers hackable
- FIX | conduct | no warning on joining after a server restart (owner report)
- FIX | law | destroying a scanner reported as "Damaging city property" (owner report)
- FIX | mortuary | flame at the right end (owner report)
- CHANGE | weather | lightning only outdoors
- FEAT | citizens | panic and flee from monsters; the 2 nearest units respond
- FIX | sound | `cl_livingcity_atmos.lua:257` error (owner sent it 3 times)
- FIX | CP | a metrocop let a headcrab kill him (`lc_units_spot_monsters` 1)
- DECISION | rebels | owner: "both", a rebel lookout point and the sympathizer sign
- FEAT | rebels | lookout posts (`lc_lookout_post_warn` 1400, `_fire` 650, `_respawn` 120); orange lambda over sympathizers

## 2026-10-05 to 10-07: curfew, rebel guard, path mapping, announcer (outside git; early part undated)

- FEAT | various | squad and quartermaster rules, scanner changes, rent doors, name bank, dropship container, timer staggering (details lost)
- FEAT | curfew | personal grace on respawn, 60 to 240 s by distance home; warnings every 15 s (was 8)
- FEAT | rebels | supply guard: warns, shoves, then turns on a non-rebel looting rebel ground (`lc_rebel_guard` 1)
- CHANGE | crafting | "private" means no unit or CP can see you (owner asked)
- FEAT | editor | path mapping mode: walk to lay path nodes (`sv_livingcity_pathmap.lua`, `lc_pathmap`, `!pathmap`)
- FEAT | announcer | custom announcements, a folder per trigger, 33 triggers, voices `overwatch` and `breen` (`sv_livingcity_announcer.lua`, `lc_announce_custom` 1, `_pct` 100, `lc_announce_gap` 25, `lc_announce_cat_gap` 90, `lc_announce_clips`, `lc_announce_rescan`, `lc_announce_say`)
- SETUP | announcer | owner told: `gamemodes/livingcity/content/sound/livingcity/announce/overwatch/<trigger>/` and `.../breen/<trigger>/` (superseded; Disagreement 3)
- DECISION | voices | ElevenLabs Breen clone declined; original voices: "The Administrator" (a woman, kindly turning domineering; Dr. Mossman's look) and Overwatch (deep, robotic); Voice Design prompts and an Audacity chain given

## 2026-10-07

- FIX | NPCs | quest escorts no longer scattered by panic
- CHANGE | rebels | following the leader comes first for followers (owner); they hold fire until the leader or the Combine shoot; catch-up teleport when unseen
- CHANGE | rebels | ranges cut (owner: rebels shot from too far): spot 1800 to 1100, fire 2200 to 1500, close 1200 to 900, NPC 1400 to 1000, raid 1600 to 1300
- FEAT | units | fire on armed rebels off rebel ground (`lc_units_spot_rebels` 600)
- FEAT | rebels | life at home (`sv_livingcity_rebellife.lua`, `lc_rebel_life` 1; owner: they stood around), scavenging runs (`lc_rebel_errands` 1, `lc_rebel_errand_minutes` 4), react to landings and drops (`lc_rebel_react` 0.5)
- FEAT | static props | beds, couches, seats from the map; editor point "bunk"
- FIX | character | a new character could get a banned or old name
- SETUP | handoff | owner given `livingcity.zip` and `HANDOFF.md` to start a new chat
- ISSUE | SFTP (separate chat) | the owner's FileZilla uploads to the host failed: `mkdir` "Internal server error", `cd` "I/O error" under `addons/livingcity/gamemodes/livingcity/content/sound/livingcity/announce/`; the queue used `announce/breen/<trigger>/` (renamed `administrator` 10-09); `addons/livingcity/lua/weapons/gmod_tool/stools` was missing so the editor tool failed to upload. Advised: 1 transfer and 1 connection at a time in FileZilla, check host disk space, recreate the `announce` folder in the host panel, contact the host if it persists. Outcome `?`
- OPEN (then) | lying on bunks, sitting on chairs, followers shooting while running, long errand routes: unverified in game

## 2026-10-08 to 10-15: main dev chat (`claude/youthful-rubin-j6lyfk`, commits `0aa5faf..e477970`) and the parallel announcer/exercise/endings chat (outside git)

**10-08**
- SETUP | repo | owner's `livingcity.zip` and `HANDOFF.md` synced in (`0aa5faf`, the `modules/` layout)
- DECISION | process | batch fixes and test per batch
- FIX | lab | the 5 known lab and waypoint bugs (`246eece`)
- CHANGE | infest | darker yellow haze, by depth (owner: "should be a darker yellow")
- CHANGE | items | suitcase hangs from the hand
- REVERT | perf | a think budget change, reverted (`lc_think_budget_ms` 2.5 was already the limit)
- FEAT | NPCs | far, unseen NPCs sleep (`lc_npc_sleep` 1; owner agreed)
- FIX | sound | missing files skipped (a missing laundry sound froze the game)
- FEAT | NPCs | Combine drawn larger (`lc_cp_scale` 1.05, `lc_soldier_scale` 1.10; owner asked)
- CORE | movement | mantle height setting `lc_mantle_height`, 92 to 108
- FIX | infest | haze and geiger stay on their own floor
- CHANGE | graffiti | costs block rations only once seen
- CORE | rations | the city eats 1 ration a minute per 40 citizens (`lc_stock_eat` 15 to 40)
- FEAT | arrests | marched to the cells by two units, rescuable (`lc_march` 1, `lc_march_max` 240; owner's design)
- FEAT | debug | lag monitor (`lc_lagwatch`)
- CHANGE | net | raises the server's net rates at start (`lc_net_tune` 1)
- DECISION | net | the rubber-banding was the owner's own network

**10-09**
- FEAT | onboarding | "What now?", Places with waypoints, hunger/thirst cards (owner got lost on Synapse)
- DECISION | TODO | Synapse-style terminals deferred to TODO.md
- DECISION | jobs | jobs must be fun, not a grind; job games (sweep, factory line, porter, rewiring, triage, rubble) and 9 more (`lc_jobgames`)
- CHANGE (outside git) | announcer | Dr. Breen became the configurable Administrator (`lc_administrator_name`, `lc_administrator_model` `models/mossman.mdl`, `lc_administrator_stock_lines` 0); voice folder `breen` renamed `administrator` (`breen` kept as an alias); her tone tiers warm, firm, stern, furious, rising with red sociostability and violence; told the folders `content/sound/livingcity/announce/administrator/<trigger>/firm/` and so on (superseded); merged into git the same day (`9fc282c`)
- SETUP | sound | `.wav` for her addresses; mono 44.1 kHz
- FEAT | radio | radio repair audio by dial; 3 trimmer screws

**10-10**
- FEAT | radio | listenable radios, Union 96.4, Freq 7 moves every 20 min
- FEAT | batches 1 to 4 | lab-only chip decoding, forcefields, rain, Nova Prospekt guards; toilets, soiling, baths, sleep (owner asked for the stain and sweepers); powered vests (owner: armour, not a shield); vortigaunts charge vests; Grigori in rebel ground; Stalker playermodel (Workshop 268895264) and its quest
- CORE | jobs | Mortuary Attendant renamed Mortician
- CORE | items | ammo, grenades, zip ties, batteries only at the CP Commissary
- DECISION | NPCs | city jobs done by real NPCs (owner)
- DECISION | stalker | for life; only death ends it (owner corrected)
- CORE | factions | one ladder: Record Keeper, Metrocop, Division Leader, Prison Guard, Soldier, Elite; Overwatch Commander (old Overwatch saves become Prison Guard; owner: no migration needed)
- FEAT | CP | a kick for every CP rank
- SETUP | workshop | Combine models: Workshop 3449180606 (preferred) or 2041528484

**10-11**
- FEAT | CP | Scanner Operator; Soldier kicks blow doors off; brush doors unaffected (owner corrected)
- FEAT | death | 3 close calls, inheritance, legacy record
- FEAT | misc | `!ways`, Ration Production, outfits designer, height variety, creator with installed citizen packs
- ISSUE | faces | Black Mesa faces: Workshop 534130993 to TODO
- FEAT | docs | PLAYTEST.md created
- SETUP | sound | told `garrysmod/gamemodes/livingcity/content/sound/...`: **rejected, the owner had no such folder**
- CORE | sound | moved to `addons/livingcity/sound/...`; owner rejected (deleted on each update), asked for a separate `addons/livingcity_sound`; then rejected subfolders: **flat folders, trigger and tone in the file name** (`d580b0e`), old layouts still read
- SETUP | update | each update: delete `addons/livingcity`, unzip `livingcity.zip`
- FEAT | docs | ANNOUNCEMENT_SCRIPTS.md
- CHANGE | events | only rations and curfew announced ahead; lockdown answers violence (`_soon` triggers for the others removed)

**10-12**
- FIX | announcer | retired `_soon` files flagged by `lc_announce_clips`
- SETUP | sound | owner's file list reviewed (`skirming_sweep_furious1.wav` looked like a typo, `?`)
- DECISION | radio | Freq 7 hops and is jammed (built 10-14)

**10-13 (outside git)**
- FIX | tests | announcer test leaks
- FEAT | exercise | mandatory morning exercise: jog, drill, parade (`lc_morning_exercise` 1, renamed from `lc_exercise` so the command `lc_exercise` keeps its name); breakfast and full stomach bonuses (`lc_exercise_breakfast` 1, `lc_fullstomach` 1; owner: no general breakfast)
- CHANGE | docs | "breakfast" removed from the Administrator's lines (owner correction)
- SETUP | exercise | owner to place jogging route stops, the exercise yard, parade route stops
- DECISION | endings | secret endings: harpies, crazybus, nuanua, topsecret, grigori; the G-Man stops time, everyone votes, no votes is a yes
- FEAT | endings | the framework (`sv_livingcity_endings.lua`, `lc_endings_on` 1, `lc_ending_pause` 4, `lc_ending_vote_secs` 30, `lc_ending_max` 180, `lc_ending_cooldown` 60; `data/livingcity/endings.json`)
- SETUP | endings | songs told: `gamemodes/livingcity/content/sound/livingcity/endings/<id>/` with the old ids (superseded; Disagreement 6)

**10-14**
- SETUP (outside git) | docs | porting guide `LIVINGCITY_PORT_2026-10-13.md`; yt-dlp command for audio (result `?`)
- ARCH | merge | the outside chat's exercise, full stomach and endings ported into git (`b382934`)
- FEAT | radio | Freq 7 on the frequencies whose digits add to 7; jamming
- FEAT | endings | Harpies (all Dr. Kleiner, owner corrected twice), Bloom (codeword so the song stays hidden), Marrow, Bus, Flood (`water`), Base, Hard, Plane, Standup (owner clarified: mocking the Klan)
- CORE | endings | renamed: crazy bus to `bus`, flood to `water`, nuanua to `plane`, topsecret to `standup` (Disagreement 6)
- FEAT | Grigori | "Eat it" on the data core, as well as `/eatchip`
- SETUP | endings | songs told per-ending folders in `addons/livingcity_sound/.../endings/<id>/`; then **flat, named by codeword** (owner corrected: no subfolders; `a817cfe`); old folders still read
- SETUP | sound | WAV must be 16-bit PCM at 44100/22050/11025 Hz; an MP3 renamed `.wav` is silent (owner: "YOU NEVER TOLD ME THAT"); a PowerShell script given first (owner corrected: Linux Mint); keep songs as MP3/OGG
- SETUP | FastDL | `http://a29ka.hexane.co/9124749/garrysmod/` doesn't look in `addons/`: move sounds to `garrysmod/sound/livingcity/...`; press Hexane's "FastDL sync" after every sound change
- SETUP | endings | a nested `endings/endings/` found; songs moved up one level; ffmpeg resample to 44100 Hz
- CHANGE | announcer | welcome only for players who still have to register (owner request)
- FEAT/FIX | endings | G-Man on each screen; announcer and city music silent; song timing by clock; dead can spectate; no inspections, crimes or standing loss in endings (owner lost 25 standing in Bloom, not refunded)
- CORE | endings | Marrow cap 40 to 80 (owner: ramp numbers only); Base bombs 30 to 60; Hard moments every 16 to 5 beats, 3 at once; Harpies song volume `harpies=2`; flashing warning closes after 15 s (was 8)
- ARCH | endings | `RETUNED` moves old archived defaults on load
- CHANGE | view | running bob stride longer
- CHANGE | Bloom | hips-only sway, thighs counter-turn (`lc_bloom_leg_sign` 1, client; removed 10-15: Disagreement 8)

**10-15**
- FEAT | docs | HANDOFF.md for a new session (`e477970`)

## 2026-10-15 to 10-16: this chat (`claude/intelligent-curie-p02qp4`)

- FEAT | endings | Shalom (owner asked for an ending supporting Israel: flags, giant hanukkiah, kippahs, hora, chair lifts, Yiddish and Hebrew sayings, Star of David fireworks; song `endings/shalom1.mp3`, 136 BPM, key change at about 3:25)
- FIX | endings | the owner's playtest list: Marrow server crash (a new pistol every shot; 8154 edicts), Flood (ichthyosaurs later, less drowning damage, rowboats, Grigori headbang), Plane, Harpies (no spawning behind walls), Standup (cones visible, all metrocops hanged), Bus (off the ground), Bloom (feet on the floor), Hard (spotlights), Base (arcade effects, bombs at the end)
- FEAT | tools | Pose Recorder, a separate Workshop-ready addon (`pose_recorder/`); "Pose Recorder 2" in TODO.md (owner: later)
- FIX | dances | floating and arm axes fixed in every ending
- CORE | NPCs | boxes carried in front in both hands (owner asked)
- CORE | factions | switching faction from F4 keeps you where you stand (owner: "Can't I just change where I am?")
- FEAT | NPCs | superadmins warned when `lc_npc_budget` is below what the settings add up to (the owner's server had it at 10; default 60)
- FIX | sound | `lc_sound_check` tests every ending song and the stock lines; a missing `_spkr` line falls back to the plain one
- CORE | announcer | **the owner's folders `garrysmod/sound/livingcity/overwatch/` and `administrator/` were never read; now both places are** (owner: "you had me create a folder in garrysmod > sound > livingcity")
- DECISION | process | owner: core behaviours must never change silently; `CLAUDE.md`, `CORE.md` and the core snapshot test made
- SETUP | sound | the Shalom song re-encoded to 44.1 kHz as `shalom1.mp3`: upload, FastDL sync, map change, reconnect
- CHANGE | Bloom | `lc_bloom_leg_sign` removed without asking (Disagreement 8)
- FIX | tests | the core snapshot completed (9 lines the first one missed: `lc_slow_movement`, `lc_walk_speed`, `lc_run_speed`, `lc_jump_power`, `lc_jump_delay`, `lc_mantle_height`, `lc_buildmode`, `/help`, `/guide`, all of which already existed); a test's cop given the fields the city expects
- FEAT | docs | this TIMELINE.md
- FEAT | endings | the Endings menu (owner asked): pick an ending (the one playing picked for you), tune its dances bone by bone with the bone lit up on the dancers, a close-up and a stand-in, every setting as a slider, and a list of changes to copy (`cl_livingcity_endingtune.lua`, `sv_livingcity_endingtune.lua`, `data/livingcity/ending_tuning.json`)

## Still open, from every chat

- Unverified in game: nodegraph links on rp_c18_ug, BSP static props, the creator UI, lying on bunks, chair sitting, followers shooting on the move, long errand routes, G-Man fidget and jaw, Spectator jump-to-fly (reported broken twice), the Flood raft and Grigori, Harpies civilians' pose, Bus under the sky, Bloom's feet, Standup's ropes and cones, all of this chat's ending fixes (PLAYTEST.md has the list)
- `models/mossman.mdl` path for the Administrator
- The HL2 parade script: owner to send a path or link
- Hand-off animation names on citizen models
- Mail-round recipient's nameplate shows the NPC's own name
- The owner's 25 standing lost in Bloom, never refunded
- Low sample-rate songs (bloom, bus, marrow at 16000 Hz, standup 24000 Hz): resampled by the owner? `?`
- The owner to record jog lines and the latest Overwatch scripts
- TODO.md: on-screen terminals, kick tuning, progression, faces (Workshop 534130993), Pose Recorder 2
- Whether the SFTP problems of 10-07 were ever solved `?`
