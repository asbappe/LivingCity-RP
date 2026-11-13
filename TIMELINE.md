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
10. **"Never add CalcView hooks" (a code rule from the scale/seriousness chat, about 10-07).** That chat made one camera pipeline, `GM:CalcView` plus `LC_CL.ViewMods` (scanner, acts, bob, FOV, dizzy), and said never to add CalcView hooks. The secret endings (built 10-13 and 10-14) add five (`cl_livingcity_endings.lua`: the G-Man, Bloom, the Flood, Base, Standup). Nothing is known to be broken by it, and the rule wasn't in CORE.md, so later chats didn't know. **Proposal:** write the rule into CORE.md's code rules, and leave the endings' cameras as they are unless one fights with the view (they only run during an ending). OK?
11. **Two more data files missing from CORE.md:** `data/livingcity/known.json` (who knew whom, for "word gets around") and `data/livingcity/word.json` (news of a death still to be passed on), both from the scale/seriousness chat (`sv_livingcity_life.lua`). Added to CORE.md as facts.
12. **The Resistance lab's numbers were never confirmed.** The chat that built it (10-08) listed its own guesses and the owner never said yes or no: the lab sells at 60% of the dealer's price (`lc_lab_price` 0.6), a CP unit shuts it for 10 minutes (`lc_lab_shutdown` 600), and which items it makes. They're what runs. **Question for the owner:** keep them?

Checked and in agreement: everything the scale/seriousness chat built (the view settings, death card, Civil Intake, papers and ration card, housing register, the CP Commissary's armour 50/75/100 and its settings, crafting cut to lockpick and bandage, the dealer's prices, `lc_rebel_pursuit`); its five lab bugs were fixed on 10-08 (`246eece`); hacker cap 2 (`sh_livingcity_factions.lua`); `lc_mantle_height` 108; `lc_cp_min_standing` 100; `lc_stock_eat` 40; `lc_morning_exercise` (setting) vs `lc_exercise` (command); the ranks ladder; `lc_ending_cooldown` 60; Marrow max 80; Base bombs 60; Hard moments every 5 beats, 3 at once; the Combine-only zone and auto-locked prison doors (asked for in v2.7, built in git on 10-04); welcome only for the unregistered; `lc_administrator_model` `models/mossman.mdl` (whether that path exists in game is still `?`).

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

## 2026-10-05 to 10-08: scale and seriousness, menus, papers, the CP Commissary, the lab (outside git; delivered as a zip with HANDOFF.md, synced into git on 10-08 as `0aa5faf`)

Undated, in order:
- DECISION | design | owner: copy Synapse RP's sense of scale and seriousness "without breaking everything"; plan: the feel, the weight of death, Civil Intake ("please start")
- FEAT | feel | narrower view, lower eyes, step sway, landing dip, a quiet HUD (`lc_fov` 75, `lc_eye_height` 61, `lc_view_bob`, `lc_quiet_hud`; each player's `lc_my_view_bob`, `lc_bob_toggle`)
- ARCH | camera | one camera pipeline, `GM:CalcView` and `LC_CL.ViewMods`; "never add CalcView hooks" (Disagreement 10)
- FEAT | death | the death card, a respawn wait, word getting round to people who knew them, kill feed hidden (`sv_livingcity_life.lua`, `lc_respawn_secs` 12, `lc_word_gets_around`; files `data/livingcity/known.json`, `word.json`: Disagreement 11)
- FIX | death | a rumour named a disguised rebel's Resistance identity; the card's "Lived at least less than a minute" reworded
- FEAT | intake | Civil Intake: arrive with nothing, register, then Housing Allocation; gates on rations, a job, the Commissary, stops; NPC arrivals queue (`lc_intake` 1, `lc_intake_secs` 8, `lc_intake_grace` 10; `lc_register`, `lc_unregister`)
- SETUP | editor | owner to place "Fixture: Civil Intake", "Fixture: Housing Allocation", "Point: arrival"
- CHANGE | feel | owner: sway "a tad bit too much": about 60% (`lc_view_bob_amount` 100%)
- FIX | dropship | owner: the container hung about 15 ft below: now at the ship's own origin
- DECISION | menus | owner: "we don't want ANYTHING to be reliant on chat commands only" (house rule 2 since)
- FEAT | menus | Unit tools window, "Tips I've seen", F1 menu with Talk, Home, The city, Settings, Help

**2026-10-07**
- CHANGE | docs | README test count, the em dash check in HANDOFF

**2026-10-08**
- DECISION | menus | owner: a TF2-style popup menu, 9 slots by role and rank, one opening the full menu
- DECISION | CP | owner: no crafting for CP/OTA; "Visit a Civil Protection Commisary to be issued supplies" with a waypoint button
- DECISION | intake | owner: papers and ration card as items; terminal wording; point to Housing Allocation; a real interaction there
- DECISION | UI | owner: rebel warnings and event messages on screen, not just chat
- DECISION | lab | owner: replace the workbench with a Resistance lab (Kleiner's things, Kleiner as the scientist), materials or credits, cheaper than the dealer, Resistance only, one in every rebel base (the numbers never confirmed: Disagreement 12)
- FEAT | menus | F1 quick menu (keys 1 to 9, 0 back, closes after 20 s); C is the full menu (`lc_quick`)
- FEAT | notices | on-screen notices: subtitles, coloured cards, event announcements with what they mean (`lc_notices` 1)
- FEAT | waypoints | HUD waypoint with distance and an edge arrow
- FEAT | CP | the CP Commissary: grenades, ammo, armour (50; officers 75; Overwatch 100), 2 bandages, a ration (`lc_cpsupply_cooldown` 120, `lc_cpsupply_ration` 600)
- CORE | items | papers and ration card (`id_papers`, `ration_card`): weightless, can't be dropped or given
- FEAT | intake | papers at registration; shown to whoever you look at; dispensers need the card; no papers at a stop costs 2 standing (`lc_papers_fee` 10, `lc_card_fee` 15)
- CHANGE | intake | Housing Allocation is a register: apply for a block, transfers, standing gates
- CHANGE | intake | `lc_unregister` takes papers and room too
- CHANGE | editor | rebel zone reworded: "Resistance ground: street units stay out"
- FEAT | lab | the Resistance lab (`lc_lab_price` 0.6, `lc_lab_shutdown` 600); the workbench fixture renamed "Resistance lab" (class kept)
- CHANGE | crafting | hand crafting cut to lockpick and bandage; the dealer sells the finished goods (smoke bomb 30, ammo 40 to 65, guns 120 to 240, vest 90, jammer 150)
- ISSUE | lab | five bugs left for later (fixed 10-08 in git, `246eece`)
- DECISION | release | owner: "please give a handoff doc and package this ASAP, we are out of usage"

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

## 2026-10-17: the 17 October playtest

- ISSUE/FIX | playtest | the owner's notes, all fixed in one go (owner: "you are authorized to begin fixing them all"): the warn-the-block job paid when the raid ended with nobody warned (and the block had nobody in it); changing jobs left the old shift; the Administrator talked over Overwatch; units let people walk past in curfew; your locked apartment door wouldn't shut; stuck in someone after pickpocketing; the march to the cells gave up after half a second's pause; map sinks ignored E; the ration line stood empty (work came first during rations; lines placed from the back; dead dispensers); factory parts too heavy to pick up and rolling off the belt; carried boxes' hands swinging; the sweep cart sideways, hurting, stuck at stairs
- FEAT | playtest | the owner's asks: bed with a mattress, a flush, the stash's wording, a fridge at home as the stash, "Civil Protection unit" everywhere, why people leave (debug report), the editor arranged by what it's for, hide markers and no x-ray, battle helmets only on the open Resistance, everyone assigned work (`lc_assign_work`), a stern "What now?", the factory's dock run to the porters, stealth (crouch, sight on the ground, a visibility bar, the dark; `lc_stealth`), vortigaunts living in rebel ground (`lc_rebel_vorts`), the Mortician's body cart
- NOTE | answers | a dead drop is a bin or dumpster used to leave something for someone else (anyone who looks can take it); vortigaunts came to rebel ground only from the "Free a vortigaunt" job; a job ends if you're taken into custody or killed (the supply raid)

## 2026-10-17 to 10-20: the evening playtest, the Combine's heads-up, the 20 October playtest

- FIX/FEAT | evening playtest | announcers one voice at a time, rebel camps (room, walkways, beds, hold E to move things), prices, stashing guns, arrest before shooting, sleep, 3D sight cones, squads acting casual, Free a vortigaunt, the labs' scientists, the factory line, the Intake Processor, raids announced ahead to the Resistance.
- FEAT | 18 October | sweeps planned ahead for Civil Protection and Overwatch ("Join the sweep"), "Repel the attack" when the Resistance raid; Maintenance rewiring became a circuit-tile puzzle with live sparks.
- FIX/FEAT | 20 October | the playtest's notes and the messages after it (see CORE.md's changelog for every setting): voices over each other, stuck on spawn, the camp carry, touching zones as one territory, the quartermaster's subtitles and food price, the vest (charge cells, vortigaunts on asking), Hacker on top of a rank, a new face at the lab, the rank card, losing the units, cuffing only the subdued, the march (doors, takeover, no van), stalkers (only killers, the scene, nothing kept, no way round it), eyelids, Grigori's moves, the jog, the radio repair, the supply drop's soldier and porters, the clipboard, the outfits button, rainwater, the Endings menu's changes list and Combine tuning, song volumes, "They Return". Answered in chat: other ways for the Resistance to raise money (ideas only).

## 2026-10-21: the 21 October playtest, the Resistance's money

- FIX/FEAT | playtest | stalkers (quieter scream, never searched or booked, their jobs became games), the infested (citizen speed, no guns, rise in a nest, their kills aren't murder), metrocops off the Combine HQ, flown scanners, the jog's lanes and latecomers, radio repair's "Write it down" (a Freq 7 sheet).
- FEAT | money | the Resistance sell written intel to the quartermaster, skim parts off the factory line (R), and the lab forges ration cards (too many bring a sweep).

## 2026-10-29 to 10-31: getting ready to open the server

- FEAT | owner's list before going public | PLAYER_TEXT.md (every line a player sees, to correct and send back) and `_dev/apply_player_text.py`; rent 15; public-server safeguards (flood guard, capped drops, one pickup, issued items stay issued, cooldowns). Put off for usage: secret ending triggers and a local OOC chat (TODO.md).
- FEAT | asks | zip ties became cuffs (!cuff, !uncuff); hacked machines pay 5 to 8 items; couriers meet the sender (take, refuse, report, open) and the Resistance has Smugglers; the Radio transmitter (contraband, held in the hands, CP net or Freq 7, soft static) and radios only listen; no music on Freq 7. Designed but not built: the Resistance Insider (TODO.md).
- FEAT | wording | rewording into plain words, batches 1 to 3 (the guide, tips, quests, story chains, job text); batches 4 and up wait for the owner.
- FIX | playtest notes | auto healing removed (only food, sleep, medicine); a locked apartment door stays locked for its owner; the ration line's front walks to the dispenser; rain washes decals but never graffiti; the stove's crackle stops; the stash opens only from furniture at home; the light-level log flood; garrison soldiers out of doorways; the editor shows only the held tool's markers; people walk round turrets; raids and sweeps that were announced but never seen (raids now spawn their own team nearby; no announcement if none can go); the editor tool in hand keeps admins fed and left alone by units; the apartment TV's picture on the glass.
- OPEN | the map's lights twinkle (not the day and night dimming): the owner to try `rp_c18_ug` in plain Sandbox. The full test suite hasn't been run since rewording batch 2 (the owner asked to test less).

## 2026-10-29 to 11-02: session notes (moved here from HANDOFF.md when it was shortened)

Every commit says what it did; TIMELINE.md has the summary. The big pieces:

- **PLAYER_TEXT.md**: every line of text a player sees, for the owner to correct and send back. Regenerate with `python3 _dev/player_text.py` whenever player text changes. When the owner sends a corrected copy back: `python3 _dev/apply_player_text.py EDITED.md ORIGINAL.md` (matches each changed line by its old text near its file and line; strings built from several pieces or ending in a placeholder may need doing by hand). Lines starting "> Note for you (not shown in game):" are the code's notes, not game text.
- **Rewording into plain words** (the owner loved it: "can't you go through and reword everything in the game this way?"): batches 1 to 3 are in the code (the in-game guide, pop-up tips, the job board's quests and story chains, job text). Drafts and originals are in `_dev/rewording/`. **Batches 4 and up are waiting for the owner to ask** (largest left: underground ~170 lines, CP tools ~91, Resistance ops ~95, events ~78, intake ~75, side jobs ~95, shop ~217).
- **Public server safeguards** (`sv_livingcity_guard.lua`: net message and chat flood limits), capped drops, one pickup per item, issued items can't be sold or passed on, cooldowns on BOLOs, tickets and character submits.
- **Radio transmitter** (`weapon_lc_radio.lua`, contraband): held in the hands (no gun at the same time), tuned to the CP net or Freq 7, soft static while held. Plain radios only listen. No more music on Freq 7.
- **Couriers** meet the sender (take, refuse, report or open the parcel); the Resistance has Smugglers.
- Rent 15, cuffs (were zip ties), hacked machines pay out 5 to 8 items, healing only from food, sleep and medicine, a locked apartment door stays locked for its owner too, the ration line's front walks up to the dispenser, rain washes decals (never graffiti), the stove's crackle stops, the stash only opens from furniture at home, the editor shows only the held tool's markers when markers are hidden, people walk round turrets.
- **Raids really happen now** (2026-10-31): a block raid spawns its own team just out of sight near the block (never the city's patrols, the owner's call), and is not announced at all if nobody can be sent. Sweeps into rebel territory start from a spot with a way in, use the city's routes, and their clock starts when they arrive.
- **Admins holding the editor tool**: no hunger or thirst, and the units leave them alone (`LC.EditorHeld`).

### This session (2026-11-01), cut short (out of usage)

- Ration cards come only from finished Union shifts (`lc_shift_ration_cards` 1); each ration takes one; no credits with a ration; Civil Intake no longer issues or replaces cards (`lc_card_fee` removed). Snapshot updated with the owner's request.
- Citizens sleep on beds in habitation blocks at curfew, lockdown and night (`lc_citizens_sleep`, `lc_bed_head_flip`; sv_livingcity_rest.lua, GoHome in sv_livingcity.lua); players lie on the bed with the camera on the pillow (cl_livingcity_rest.lua, sh_livingcity_acts.lua).
- **Not verified:** the full test suite was started but not finished (no failures in the part that ran); the new tests (PapersHousingTests, NextStepTests, HygieneTests) never completed a run. Client smoke test passes. Run the full suite first next time.
- **Rewording batch 4** (Civil Intake and Housing Allocation) is in the code; originals in `_dev/rewording/batch4_intake.md`. Kept the phrases the tests look for. Batch 5 (Civil Protection's tools; the cuffs no longer say "ties" or "plastic") too.

### Later the same session (2026-11-01)

- The owner's playtest notes, all fixed (README, "The 1 November playtest"): infestations no-go for NPCs, rebels on the editor's beds, sweep teams doing the job (scientist, pots, crates), rebel health and weapons, Combine weapons, triage injuries, credits and traits on the HUD, job tools taken back, bins you stand by, the jog's barks, reward and reprimand.
- Rewording finished (batch 5: Civil Protection's tools, cuffs; "primary fire" is "left click"; the rest was already plain).
- The Resistance Insider built (`sv_livingcity_insider.lua`): the Inside menu, the leaders told, caught means Resistance for good.
- Terminals on their own screens (`cl_livingcity_screens.lua`): Civil Intake, Housing Allocation, the CP Commissary. Where the screen stands is a guess (in front, 54 units up): adjust `Frame` if the owner says.
- The "Move it" bark file names are from memory: if a unit goes silent on the jog, a file name is wrong.
- Weedkiller against the infestation (`sv_livingcity_cleanup.lua`, `entities/entities/lc_nest.lua`): growths in infestations, Infestation Cleanup (15th job) with guards (NPC state `cleanguard`), barnacles, the firebomb, poison gas for units only, fouled filters and spiked food for the Insider, sweeps opening with gas. The growths' built-in model paths are from memory (antlionhill, antlion_grub, charple01, then a rubbish bag): check what shows. The owner's workshop pack (id 2043900984) is Half-Life: Alyx's Combine hazard props (`models/hlvr/combine_hazardprops/combinehazardprops_*`: barrel, barrel_lock, clothe, container, crate, detector, forcefield_left/right, hoover, lamp, trashbag, warningsign) and Xen gunk (`models/hlvr/distillery_gunk/distillerygunk_gunk.mdl`). The growths use the gunk when it's there; the warning posts and bags use the props. The hazmat suits come from a second pack (id 3185145650): `models/player/` and `models/npc/` `worker_male`, `worker_female`, `engineer_male`, `engineer_female` (hands `models/weapons/c_hands/c_worker_arms.mdl`, `c_engineer_hands.mdl`, registered by the pack's own autorun). They're the cleanup job's automatic outfit (Job outfits entry marked `lcAuto`, replaced as soon as the owner saves their own), `lc_cleanup_suit` worker/engineer. The owner confirmed: worker = the hazmat suit (cleanup), engineer = overalls without filter or tank, worn by Mortician, Sanitation and Reclamation (DIRTY in `sv_livingcity_cleanup.lua`). Male or female comes from `LC.PlayerSex` (the creator's face, `lc_model`) and NPCs' own `gender`, never from FaceOf alone. The suits are worn only for the work (the owner): outfits marked `onDuty` (the automatic ones) are worn by players only on a shift (`LC.PlayerOnDuty`), by NPCs only while `st.npcWork` is set, with 90 seconds' grace between tasks, off at once going to bed, curfew, lockdown or leaving (`LivingCityDutyClothes` timer in `sv_livingcity_outfits.lua`).
- The cleanup is three steps now (the owner): spray kills a growth (`LC.KillNest`, NW `lc_dead`), the hoover (`entities/weapons/weapon_lc_hoover.lua`, a job tool) vacuums dead ones (`LC.VacuumNest`, NW `lc_hoover_load`), E on the warning post's barrel empties it (`LC.DumpHoover`), right click bags it only where no barrel is within 3000 (`LC.BagHoover`). Dead growths rot after `lc_nest_rot_minutes`. The hoover has no viewmodel: the prop is drawn at EyePos plus `lc_hoover_view` (a guess; the owner may send better numbers) and on the right hand bone in third person.
- The Black Mesa citizens pack (534130993; the owner sent its model list): with it on the server and no looks set for Everyone else (no job), about half the jobless NPCs wear its citizen or refugee NPC models (`lc_bms_people` 50, new; `LC.BlackMesaLook` in sv_livingcity_outfits.lua), and the character creator lists its citizen and refugee player models; players download it on joining. A look that keeps faces (`{face}`) on someone with no numbered face now picks a face of their sex (was always male_01).
- The owner's Marrow crash (1 November): with 100+ NPCs, the ring endings (Harpies, Bloom, Marrow, Hard) put everyone on one small ring, inside each other; the engine pushed some through the floor (endless "Ignoring unreasonable position" in the console), CPU hit 100%, and the owner's game was dropped in a loop with `SendData reliable data too big (744335 > 262107)`. Now: `LC.EndingRingSpots` gives each their own spot and spills onto more rings; `LC.FreeSpawnPos` keeps the city's spawns off each other; `LC.RescueFallen` (timer LivingCityFallen) puts an NPC out of the map back where it last stood after two seconds, or removes it. The 744 KB send is thought to be the pile-up's entity update (not confirmed: ask for the console if it happens again). NPCs were also falling out of the map before Marrow (lc_npc_725), probably from the same crowding at spawns.
- 2026-11-02, the sealed directives (the owner's design, ENDING_TRIGGERS_DRAFT.md): sv_livingcity_directives.lua (`LC.Directives` riddles and conditions, `LC.DirectiveHeat`, `LC.DirectiveRoute`, `LC.DirectiveAnswer`, `LC.DirectiveTick` every 2 s, the escalation `S.esc`, `LC.GmanDream`, the office's new Orders through a wrapper on `LC.AdminDo`, and wrappers on `LC.Firebomb`, `LC.ExerciseFinish`, `LC.IssueWeedkiller`, `LC.SprayWeed`), cl_livingcity_directives.lua (the envelopes, the staff popup, `LC_CL.GmanVision`: the G-Man drawn with his own camera in a void over the screen), entity lc_gmancrate. The tests turn `lc_directives` off at the top (it would start endings mid-suite) and on in its own section. Not built: the city's own way into All your base (the master data core to a lab scientist doesn't exist yet); the Flood still starts from Grigori as before. The G-Man's Episode One lines (`gman_wellseeaboutthat`, `gman_notforlong`, `gman_notthistime`) are only in the pre-release Episode One files: skipped if the server hasn't got them. Later the same day: the last call and walk-away lines with a reminder bar (`lc_directive_until`, `lc_directive_urgent`), the rival and the recall vote (`LC.GmanRival`, `LC.CallRecall`, `LC.RecallTick` in sv_livingcity_cityadmin.lua; voters `LC.AdminVoter`: units and the Administration), the elected visit (hook LivingCityAdministratorChosen), the crate line (each player's first look), glimpses (`LC.GmanGlimpseTick`, client places him). Every clip: GMAN_SOUNDS.md.
- 2026-11-02 (the owner asked: "yes please do these"): the lost v2.7 pieces: stamina (sh_livingcity_stamina.lua, `LCS`; `lc_stamina*`), guns (the owner refined it: contraband on the streets, wanted at once when seen; carried lowered only on rebel ground (everyone) and for recruits and metrocops on the Combine's ground, `lc_carry_lowered` and `lc_lowered_ground` set by `LC.BrandishTick`, `LCL.MustLower`; from the zone's edge (`LC.NearRebelZone`, `LC.NearCombineZone`) a client prompt (LivingCityLowerPrompt) while a gun is up, the fighters or soldiers stand to (SCHED_TARGET_FACE, `st.lcAimAt`) and call out (`LC.GunWarnLines`, Half-Life 2 voice files) while a gun is up, fire after `lc_brandish_grace` 10 once inside (`LC.RebelSetFoe`, `LC.MakeOneHostile`); players only), obituaries (sv_livingcity_streetlife.lua; `lc_brandish*`, `lc_obituary`), longer street detentions (`lc_street_detention_per_minute` 10, `lc_street_detention_max` 60; `ply.lcWantedSince` set in LC.SetWanted), LC.FindPlayer by citizen number or character name, breathing view sway and colour grading (cl_livingcity_view.lua; `lc_color_grade`, client `lc_my_color_grade`). The Administration path: Records Clerk shifts count `lc_admin_clerk_minutes` (20) each towards `lc_admin_hours` (`LC.AdminHours`). `/stand` is the acts command again (the election had taken it). The ending triggers: a draft for the owner, ENDING_TRIGGERS_DRAFT.md (Administrator-unlocked endings with riddles, and in-play triggers); build once they pick.
- The owner's playtest of it (1 November, late): ERROR growths (stand-ins drawn client-side now, and `resource.AddWorkshop` for both packs: `lc_workshop_packs`), no warning posts (they needed the pack; now always placed, with cones and an oil drum as stand-ins, and the barrel is its own entity `lc_hazbarrel`, also an editor fixture), the vacuum count stuck at 1 (the event fired after the entity was removed: fixed, events before Remove), no weedkiller (now given first, topped up at shifts and when out: `LC.IssueWeedkiller`), guards lost (questLock while guarding, teleport back after 4 s beyond 700, a spawned cop when none free, fights don't drop them), hoover invisible (PreDrawViewModel returning true stopped PostDrawViewModel; an empty WorldModel stopped DrawWorldModel), suit hands too far (`cl_livingcity_suit.lua`, CalcViewModelView), geiger 40% calmer. Also from that playtest: F4 rebuilt as collapsible headers (cards were measured before wrapped text grew), Stalker hidden on F4, Fighter needs trust jobs (`res_jobs` counter), rain filling removed, boiling by particle fires. Then: filing explains itself (register status, why right or wrong), sleeping NPCs as a frozen prop_ragdoll double (`LieDouble` in sv_livingcity_rebellife.lua; the NPC hidden and non-solid under it), career paths (`path` on jobs, `LCJ.Paths`, CP counts `cp_shifts` from Intake and cleanup), Block Warden at 100 and hidden below, units spawn in a Combine zone, `lc_cp_hands`, the radio raised (`lc_radio_view`).

### Testing state (2026-11-01)

- **The owner asked: no full test suite for a while.** Use the client smoke test and single sections only.
- The last full run that finished (2026-10-31 night): 2869 passed, 9 failed. All 9 were fixed and the touched sections re-run (UndergroundTests, the Mole Hunt, the 1 November section: all pass). Not run since: the vortigaunt additions, the loyalty test's real prisoner, Proof, the faction progress bars (each has its own passing tests in "The 1 November playtest" section).

## 2026-11-07: the 7 November playtest lists

- First chats: the first list (handoff in `docs/dev/handoff-2026-11-07.md`).
- This chat (part 2): the owner's answers on three core items, the rest of the first list (Labor Assignment, rebel food scaling, shared dreams, the pockets, the kick, sweeps) and the whole second list (faction cleanup, arrests, Combine ground, field ops, guidance, pacing), built with nine workers in worktrees and merged. Details: `docs/dev/handoff-2026-11-07-part2.md`.

- 2026-11-10: **Give menu** in the talk window (`LC.GiveKind`, `LC.GiveableTo`, `Give` in sv_livingcity_talk.lua; action `give:<id>`; hook `LivingCityGaveCitizen`; client DermaMenu; GiveTests (14)). Food still via ShareFood/`LivingCitySharedFood`. Resistance pamphlet (`rebel_pamphlet`, another chat) goes through `LC.GiveRebelPamphlet`; units never see arms in the menu.
- 2026-11-11: the owner's 11 November playtest notes worked through (the Cremator, clearing away, stalkers' noise, G kick, the radio, the conditioning, night shift hours, vouchers, shift notices, the trail, chat lines, looping sounds, Bubbles, the health vial, music, the vortigaunt's charge); what is left is in `TODO.md`.
- planning board and bounties (`opplan`); state of the city (`ledger`, `ledger2`, speech stand point); small-server mode (`smallserver`); citizen goals: status symbols and the pet pigeon (`status`, `cl_livingcity_petbird`), households (`households`), a stall business with hand-made goods and workers (`employment`), pickpocketing, loans and bad deals (`streetcrime`) The owner: **never only in the C menu** (CLAUDE.md house rule 2). A citizen's F2 > Me keeps lines 1 to 4 and the milestone; new pages go under "More". F1 gets "More with them..." when entries overflow. Insider **Report it clean** (`LC.CPReportClean` in cpduty) built; F2 now overflows into a More page at slot 8 (a unit's Me/My shift did not fit before). Open offer: tuning `lc_ratscar_pos` and `lc_petbird_pos` after an in-game look. Known: "a winner wakes Unbroken" (after ExerciseParadeTests) and a PropagandaDreamTests check (after DreamGameTests) fail only by test order, old (TODO.md); a few random tests come and go. Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section. Tests need `pip install lupa` in a fresh container.
- a unit's 15-minute shift, no break needed (`cpduty`); snitches, burning and the rat scar, which bars the Resistance (`snitches`, `cl_livingcity_ratscar`)
- arrival search (`intaketutor`), prison sentences, work detail by turns and probation (`sentence`), a deeper interrogation (`interrogation`), survival modes (`survivalmode`), dream sit-outs (`dreamskip`), Where I stand (`standingpanel`)
- 2026-11-10, this chat (all owner-approved from the gameplay review; specs in `docs/features/`, modules in `python3 _dev/make_modules_map.py --module NAME`):
- 2026-11-10 (owner-asked: "Let's get the minds fully operational", then "a small hosted fee is fine"): **the minds act** (`sv_livingcity_mindsact.lua`, spec `docs/features/city-minds.md`): `LC.MindsBias` bends `ChooseCitizenTask`, `LC.MindsAct` does a break in the street through errands (`LC.MindsErrand`, `LC.MindsErrandTick`), `LC.MindsIsInformer` picks named informants, `LC.MindsUnrestHigh` turns sociostability yellow. `lc_minds_act` 1, `lc_minds_unrest` 0.4. MindsTests (64).
- Same chat: **the director and free talk** (`sv_livingcity_brain.lua`, spec `docs/features/director-and-free-talk.md`): a hosted model asked with `HTTP()` (`LC.BrainAsk`; the tests swap `LC.BrainHTTP`), key in `data/livingcity/brain_key.txt` set from the editor panel; `LC.DirectorLook`/`LC.DirectorApply` (none, event, break, approach) and `LC.BrainHeard` on `LivingCitySpoke`. BrainTests (30). **Never run on a real server yet:** the owner has to make a key, press Test, and bring back the debug report and `DIRECTOR`/`TALK` lines from `data/livingcity/minds/` to tune the two prompts. 11 November: **the city's own Administrator** (`LC.AdminLook`, `LC.AdminDecree`; no player in the post: the office's acts, same waits; BrainTests 43). **The G-Man and the city's own** (`LC.CollapseNext`, `C.npcRefusals`; `LC.CollapseNpcRoll` for the tests): 1 to 3 refusals, the last stand only on 3; CollapseOwnTests (8). **Her voice** (`sv_livingcity_voice.lua`, `cl_livingcity_voice.lua`; `LC.VoiceSpeak` from `LC.AdminApply`; ElevenLabs, `lc_voice` 0 until the owner has a key and voice id; VoiceTests 19; the request shape and playing the clip on a client are unchecked against the real thing). **Recorded lines** (`sv_livingcity_lines.lua`, spec `docs/features/recorded-lines.md`: `LC.StreetLines` 79, `LC.UnitLines` 17, `LC.LineSay`; the model picks by id, `lc_brain_lines` 1; LinesTests 26; none recorded yet; American wording, each line's third entry is its ElevenLabs text; `VOICE_SCRIPTS.md` is generated by `_dev/voice_lines.py` with the voice descriptions; `_dev/tools/elevenlabs_batch.py` (reads the generated `_dev/tools/voice_batch.tsv`) makes them all on the owner's PC, untried against the real service; `LC.OwnVoice` silences Half-Life 2's voice for named citizens once the bank is recorded; units use `npc/metropolice/vo/` clips where named, UNCHECKED: ask the owner for `lc_hl2_lines` output, `data/livingcity/hl2_lines.txt`). **New plan from the owner (11 November): replace every Half-Life 2 voice line with their own, except the G-Man** (matching HL2's actors by description failed): `LC.VoiceReplacement` and the `EntityEmitSound` hook swap a clip for `sound/livingcity/hl2/<its path>`; `elevenlabs_batch.py --hl2 hl2_lines.txt` makes them; unproven in the real game. **Then built instead: two voices by personality** (`LC.VoiceOf`, `LC.LineKey`, `LC.HL2Lines` 107 clips, `LC.HL2Instead`, `lc_voice_split`; units' 21 lines all stock clips; from the owner's `_dev/tools/hl2_lines.txt`; LinesTests 45; unchecked in game). Open with the owner: `lc_minds_show` default (still 0); whether to let the hosted model be another provider's (they asked; not built).
- 2026-11-10 (owner-asked: real seats for the chair dreams; spec: the last section of `docs/features/endings.md`): `LC.DreamSeat`/`LC.DreamSeatMove`/`LC.DreamUnseat` (sv_livingcity_dreams.lua; GMod's seat pod, unseen), used by Musical Chairs (claiming a chair sits you; Use also claims) and Shalom's chair lift for players (`m.seat`, NW2 `lc_real_seat` stops the hand-bent legs on the client). Heights and facing unseen in game: `LC.ChairsSeatUp`, `LC.ShalomSeatUp`, `LC.DreamSeatYaw`.
- 2026-11-10 (dreams, owner: "all 3 please" and a buggy race; specs: the last two sections of `docs/features/endings.md`): **staging** in `sv_livingcity_dreamstage.lua` (opening and finish cards on net `lc_dream_stage`, `LC.DreamActSet`, her figure/hunters/admirers (`g.admirers`) and players' bodies act; client in `cl_livingcity_dreamacting.lua`, which now moves anything with NW2 `lc_dream_actor`). **The Midnight Rally** (`rally`, Happy): `sv_livingcity_dreamrally.lua`, `sh_livingcity_kart.lua` (`LCK.Step`, SetupMove on NW2 `lc_kart`), `cl_livingcity_dreamrally.lua` (chase view); `def.ownStandins` (rival drivers). Driving feel, the camera and every pose are untested in game: expect tuning (`LCK.*`, `LC_CL.KartCam*`). 11 November: a **close** card as a dreamer wakes at the end of an ending-dream (a line each, `LC.DreamCloseLines`) or of a dream they didn't win (`LC.DreamCloseFor`).
- 2026-11-10, this chat (all owner-approved from the gameplay review; specs in `docs/features/`, modules in `python3 _dev/make_modules_map.py --module NAME`):
  - arrival search (`intaketutor`), prison sentences, work detail by turns and probation (`sentence`), a deeper interrogation (`interrogation`), survival modes (`survivalmode`), dream sit-outs (`dreamskip`), Where I stand (`standingpanel`); a unit's 15-minute shift, no break needed (`cpduty`); snitches, burning and the rat scar, which bars the Resistance (`snitches`, `cl_livingcity_ratscar`); planning board and bounties (`opplan`); state of the city (`ledger`, `ledger2`, speech stand point); small-server mode (`smallserver`); citizen goals: status symbols and the pet pigeon (`status`, `cl_livingcity_petbird`), households (`households`), a stall business with hand-made goods and workers (`employment`), pickpocketing, loans and bad deals (`streetcrime`) The owner: **never only in the C menu** (CLAUDE.md house rule 2). A citizen's F2 > Me keeps lines 1 to 4 and the milestone; new pages go under "More". F1 gets "More with them..." when entries overflow. Insider **Report it clean** (`LC.CPReportClean` in cpduty) built; F2 now overflows into a More page at slot 8 (a unit's Me/My shift did not fit before). Open offer: tuning `lc_ratscar_pos` and `lc_petbird_pos` after an in-game look. Known: "a winner wakes Unbroken" (after ExerciseParadeTests) and a PropagandaDreamTests check (after DreamGameTests) fail only by test order, old (TODO.md); a few random tests come and go. Unchecked in game: PLAYTEST.md "9 November, part 13" and every "10 November" section. Tests need `pip install lupa` in a fresh container.
- 2026-11-11 (owner: "Please add it"; core, in `CORE_CHANGELOG.md`; spec: the `harpies` row of `docs/features/endings.md`): **the harpies carry players off and turn them** (`LC.MingeCarry`, `LC.MingeTurn`, `LC.MingeDrop`, the `s.carry` branch of `LC.MingeStep` and `TICK.harpies`; NW2 `lc_minge_carried`; a turned player rides their own mingebag, `p.lcMingeSelf`, and doesn't steer it). Later that day (owner: "Replace both the ending and the dream with this new idea"): nobody is killed where they stand; units and citizens are carried and turned too, and the last two seconds snatch whoever is left. Then (owner): 1.5 times as many once they leap (`LC.MingeMore`), and the finale: kill at 5 s from the end, dead players rise as mingebags at 3 (`LC.MingeRise`), all scatter at 1.5 (`LC.MingeKillAt`/`RiseAt`/`ScatterAt`; the test's song is 45 s for this). A mingebag that grabs anyone (player, unit or citizen) is invincible from then on (`s.invincible`), a carried player godded (`p.lcMingeGod`). Offered next: letting a turned player steer theirs. Unchecked in game.

- 2026-11-12, the 12 November playtest (latest; the owner: "fix all of it please"; per item in `PLAYTEST.md` top section and each feature doc's "12 November playtest" paragraph): dreams (`sh_livingcity_soundguard.lua` sound guard, `LC.DreamStopAll` on F1, units dream, `dreams/<codeword>/` music folders + `LC.DreamMusicList`, Battle Line/bus/Careless Talk/Duck and Cover/Freeze/Bubbles reworked); CP (3 cuffs `LC.CP_CUFFS` refilled at the CP Commissary, shift 30 min again (core, snapshot updated), terminal screens over the console with hologram signs, baton tip glow, papers button + `LC.HoldFacing`, squad teleport `LC.SquadCatchUpTick`, cuffed arm pose); city (incinerator upright, Cremators guard infestations and escort cleanup crews, morticians stay out, lip sync `cl_livingcity_lipsync.lua`, no action music from events or in bed `LC.AtRest`, jobs over the radio `LC.RadioJobs`, metrocop re-dress `LC.MetrocopRecheck`); sprays off; vortigaunt broom in front; lights-out wording.
- 2026-11-12, Careless Talk redone (owner-asked): 3 rounds, E to pick (`LC.SpyAimed`), canteen chat (`LC.SpyTalk`), salute (`LC.SpyChant`, bone pose), firing squad (`LC.SpyVolley`); new dream cues `spy_chant_*`, `spy_flat_*`, `spy_whisper_*`, `spy_ready/aim/fire`; 12 small-talk lines `say_small_*` used by street chatter (`LC.CueTopic`) and the dream (`LC.SpySmallTalk`).
- Open: should F4's Jobs tab be limited to terminals/boards/the radio (asked the owner); arm pose and baton glow need the owner's eyes in game; the cause of Careless Talk's 15 to 30 s vortigaunt delay wasn't found (now a fixed 8 s gather).
- 2026-11-12, voice triggers (latest, owner-asked: "wire up all these voices now", no director key for now): new `sv_livingcity_voicecues.lua` (`LC.Cue`, `LC.CueState/Topic/Answer/Greeting/Goodbye/Reply/ApproachLine`), settings `lc_voice_cues` 1, `lc_voice_approach` 300, `lc_voice_cue_words` 1 (core, in `CORE_CHANGELOG.md`). All 79 citizen lines have a moment: talk window (talk.lua, `Said()` quotes the recorded line for own-voiced citizens), street chatter, stopped/frisked/arrested, panic and gunfire, what they see (`LivingCityThought` hook added to `Psy.Think`), hurt by a player, chat near them (only with no key), walk-ups (may give water or a ration). Spec: recorded-lines.md "Heard without the director". VoiceCuesTests (32). Open: tune chattiness after the owner plays.
- 2026-11-12, citizens recorded (latest, owner-asked): the owner recorded all 79 `say_` lines (man and woman) with nine rewordings; the subtitle and paste text in `LC.StreetLines` now match (`say_greet_plain`, `say_no`, `say_state_fine`, `say_state_hopeful`, `say_disagree`, `say_loyal`, `say_res_side`, `say_warn_watched`, `say_break_steady`); VOICE_LINES/VOICE_SCRIPTS/voice_batch.tsv regenerated (`_dev/voice_lines.py` now writes the "Just the citizens" paragraph that was hand-added). LinesTests 45 pass.
- 2026-11-12, voices (owner-asked): `_dev/tools/record_citizens.sh` (finds its two partner files in its own folder, writes `voice_out/` there) records the 158 citizen lines (man and woman ids at its top) with `elevenlabs_batch.py`, asking for the key hidden; plain run makes 3 test lines, `all` the rest; boosts loudness once with ffmpeg loudnorm (-14 LUFS, 44.1 kHz, 128k). Noted in `VOICE_SCRIPTS.md`.
- 2026-11-12, the chronicle (latest; owner-asked, the first steps away from scripted events; spec **and the agreed plan** in `docs/features/chronicle.md`; core: `lc_chronicle` 1, `/news`, `data/livingcity/chronicle/`): `sv_livingcity_chronicle.lua` keeps what happens to named people and players with what led to it (`LC.ChronicleAdd`, `LC.ChronicleBroke`, `LC.ChronicleStories`). Players meet it **in the world only** (the owner: no psychic lists, keep the noise down): a citizen's Chat (`LC.ChronicleRumor`, after `LC.TakeRumor`) and two placed boards, entity `lc_newsfeed`, fixture kinds `cpfeed` (only what was formally reported) and `rebelboard` (what their own saw; `LC.ChronicleFeeds`, `cl_livingcity_feeds.lua`). Staff only: the stories list (F1 > What now?, `!news`) and the joining card. Tests: `ChronicleTests`. **The Resistance's interrogation chair** (`sv_livingcity_chair.lua`, `lc_interrochair` with a lamp over it, `lc_chair` 1, tests `ChairTests`): a Resistance player takes a citizen to it from the talk window (`LC.ChairTake`), then E on the chair (`LC.ChairDo`: done, seen, hit, free); what they give up is `LC.ChronicleKnows`; beating someone with nothing to tell turns them and their friends (`Wronged`). **The holding cage** (`sv_livingcity_rebelhold.lua`, `lc_rebelcage`: four fence panels, the gate faces the placer; `lc_rebel_cage` 1, `lc_rebel_hold` 1200; tests `CageTests`): a Fighter or above (`LC.RebelMayHold`, also the chair's rule now) takes citizens prisoner from the talk window (`LC.CageTake`), four to a cage, and works it with E (`LC.CageDo`: gate, chair, free). Prisoners are held 5 minutes (`lc_rebel_hold` 300), eight to a cage (`lc_rebel_cage_room`; `Reseat` when one leaves), questioned by the cell itself (`lc_rebel_auto`, `LC.CageAutoNext`, the chair's `AutoStep`; a confession is chronicle kind `confess` and goes on the rebel board), with Father Grigori, a vortigaunt or a rebel at the cage every 30 to 60 s (`lc_rebel_visitor`, `LC.CageVisit`). **Built later on 12 November (`docs/features/patdown-and-cuffs.md`, `sv_livingcity_patdown.lua`, tests `PatdownTests`; core: `lc_patdown` 1):** a patdown of a cuffed player (`LC.PatdownStart/Do`; a quick menu on cuffing, net `lc_custody`; city units do one at `LivingCityMarchStarted` unless `LC.CopInFirefight`), F1 > Pick the cuffs (`LC.StartPickCuffs`), players in the cage (`LC.RebelHeldPly`, `LC.CagePutPlayer`, `LC.RebelPrisonerTick`, `LC.StartPickCage`), and **the quick menu for situations** (`LC_CL.OpenSituation` in cl_livingcity_quick.lua: the owner wants no mouse windows for these; the chair and the cage use it now). Unchecked in game. **Then, the same day (same spec file; tests `RebelRuleTests`; core: `lc_evidence_locker` 1, `lc_rebel_rules` 1, fixture `evidlocker`, `weapon_lc_rebelclip`, `data/livingcity/rebel_rules.json`):** the evidence locker (`lc_evidencelocker`, the end of sv_livingcity_evidence.lua: `LC.EvidenceLockerUse/Do/Take`); NPC prisoners hide things (`LC.NPCHides`, `LC.PatdownNPC`, `LC.NPCSlipTick`); a player in the chair (`sv_livingcity_chairplayer.lua`: truth, lie or nothing, the truth from `LC.ChronicleKnows`); the rules, mood, clipboard, kind options and executions (`sv_livingcity_rebelrule.lua`: `LC.RebelChief`, never `LC.RebelLeader`, which is the zones'; `LC.RebelRuleSet`, `LC.RebelAtmosphere`, `LC.RebelBoardLines`, `LC.RebelChairExtra`, `LC.ExecAskLeave`, `LC.Execute`, `LC.ExecJudged`); hints for all of it in the context panel (the `nearby` kind at the end of the data in cl_livingcity_context.lua). **Still to do from the owner's 12 November answers: Civil Protection's search window, their interrogation and the citizen talk window as quick menus that close F1 to F4 menus; another way than a bar to show struggling at cuffs and locks (`TODO.md`).** **How cuffed people look** (`cl_livingcity_cuffed.lua`: arms behind the back by bone turns, two rings and a link, a squirm while `LC_CL.CuffWorking`; cuffed NPCs with a hidden pick work at their cuffs unwatched, `LC.NPCCuffTick`): unseen in game, the owner tunes `lc_cuff_pose` and `lc_cuff_ring` by eye. Not built: the people's standing, pamphlets from it, the body, exchanges, the Administrator's answer, jobs from the board. Not checked in game: the corkboard's facing, the chair's lamp and sitting pose, the cage's fence model and gate. Waiting on the owner: `<map>_stories.txt` after a week.
- 2026-11-11, the name ( owner-approved, core, in `CORE_CHANGELOG.md` and `CORE.md`): **players now see "Miscount"**, on screen only (380 text strings: title, `GM.Name`, `[Miscount]` chat prefix, guide, categories, "Miscount Editor"); the `livingcity` folder, `lc_` commands, data and file locations and the code's names are unchanged, and docs and comments still say Living City. The loading screen: `node _dev/posters/loading.js OUTDIR` (the Administrator at her balcony, residents' readouts, one lit window with no record; the title's M is the mark, the shield stays the Administrator's); rendered files in `_dev/loading_screen/`, `miscount_loading.html` is for `sv_loadingurl`. Not hosted or tried in game yet (unknown whether the FastDL mirror serves `.html`).
- 2026-11-11, part 3 (latest; the owner: "finish all the other todo items"; specs at the end of `docs/features/civil-protection-tools.md`): `sv_livingcity_patrolcompany.lua` (`LC.PatrolCompanyStart/Step/Tick`, `st.suspect`, `lc_patrol_company`); `sv_livingcity_combat.lua` (`LC.CombatHolds` called from `HandleMoving` in sv_livingcity.lua, `LC.CombatStep`, `LC.CombatHurt`, `lc_combat_ai`); street papers (`LC.StreetPapers`, `LC.StreetPapersDecide`, `LC.TargetActions.streetpapers`, in sv_livingcity_jobgames.lua); the search's fifth spot (`LC.PatSearchCarried`, `lc_pat_papers`); `LC.DreamMissedCheck` (S.missedNight). Their tests sit in VestTests (an odd home: move them if that unit is ever split). All unchecked in game. The owner's whole 11 November list is done; what waits on them is the last bullet of `TODO.md`. **Then flashbangs** (the owner: no effect in the real game, twice now): `LC.FlashDisarm`/`LC.FlashRearm` in sv_livingcity_fieldops.lua take a blinded NPC's weapons away until it wears off, `FLASH_NEAR` 300, and the thrower is told the count (`LC.LastFlash`). If the owner still sees "N blinded" and gunfire, the stun itself is being undone by something else: look at what re-arms or re-targets rebels.
- 2026-11-11, part 2 ( the owner's screenshots and further asks; `CORE_CHANGELOG.md`; specs at the end of `docs/features/civil-protection-tools.md` and `city-people.md`): **protect jobs** (`LC.ProtectWait`/`ProtectWaitTick` in sv_livingcity_quests.lua: 60 s on the board, 60 s after taken, NW2 `lc_protect_at`/`lc_protect_what`, `LC_CL.ProtectArrives` in the tracker; used by `LC.StartOverwatchDrop` (`d.landT`) and the supply drop (`s.arrive`, `s.waiting`); the tests set `LC.ProtectWaitOff`); **F3/F4** (`cl_livingcity_fmenus.lua`); kick hips hidden; own hands (`LC_CL.OwnHandsArms`, retried; UNPROVEN: the owner must say whether the hands are back); clipboard in `AT_SIDE`; pockets header; screen height from the feet; `LC.CPTurnIn`; baton sparks (`SWEP:PostDrawViewModel`), `LC.UnitLeavesStunstick`; breach game (door locked, kick hook, `RoomSpot`, trail to a door); `LC.BackupBringNear`; `LC.CopInFirefight`; editor grace (`EDIT_GRACE`); stalker rope (`cl_livingcity_dragrope.lua`, NW2 `lc_roped_to`) and `ITEM_REACH`. All unchecked in game.
- 2026-11-11 (latest, owner-reported): Hexane refused to unzip a `.sh` file, so `livingcity.zip` also leaves out `_dev/`; `livingcity_tools.zip` (`livingcity/_dev/`) is for the owner's PC, sent when a tool changes.
- 2026-11-11 (latest, owner-asked; core, in `CORE_CHANGELOG.md`): **pictures and the font left the gamemode zip.** The FastDL sync never reads `addons/` and deleted the posters, `ui/`, `pamphlet/` and `lcrebelhand.ttf` from FastDL once their loose copies were gone. Now `livingcity.zip` drops `materials/` and `resource/`; `livingcity_content.zip` (sent only when a picture or the font changes) is unzipped in the server's `garrysmod/`. No code changed.
- 2026-11-11 (latest; the owner's playtest notes, merged into `PLAYTEST.md`, and their asks in the chat; `CORE_CHANGELOG.md`): **fixed**: the Cremator (no fire on small prey, kills left cooked `LC.CarcassItem`, burns carcasses `LC.CrematorCarcass`, unsticks from barricades by a 20-second progress check, greener flame); dropped items and meat gone after `lc_body_time` seen or not (`LC.ClearsAway`, `lcPocketDrop`); stalkers' voice once a minute (`LC.StalkerSoundAllowed`); the G kick key (it ran the convar `lc_kick`; now `LC_CL.SendAction("kick")`); the radio's R both ways (`LC.HoldReload` from the hands too); **the conditioning** (story unlock needs `LC.ConditioningXPShort` <= 0, a soldier and stalker at the spot with a 90-unit reach, `LC.ConditioningScene`: fade, sounds, freeze; no XP given: the owner refused that); night shift 18:00 to 21:00 (`LC.NightShiftHour`, template `recheck`); vouchers every 857 s; shift notices (`LC.CPShiftTell`); the trail (`LC.TrailShortcut`, `lc_trail_straight`, chevrons anchored by `t.d0`); one chat line for ground retaken (`LC.RadioNotice` third argument); five looping sounds; Bubbles lifts; `health_vial`; music (`ACTION_FIGHT`, `JOB_NEAR`, `QUIET_MIN/MAX`, no repeats); vortigaunt charge shown (`LC.VortChargeShow`, `cl_livingcity_vortcharge.lua`). All unchecked in game. **Not done: one long bullet at the end of `TODO.md`** (first person hands, pockets header, Commissary window and selling junk, stunstick, search extras, housing inspection, backup, landing zone, NPC combat, raid spawns, the unit's dream, stalker rope, night shift company). Full suite (run_parallel): 5589 passed; 3 DreamGameTests fail only by shard order (they pass alone).
- 2026-11-11 (latest, owner-asked): the editor's "Arrange by what it's for" view gains a **Dreams** folder (`dream`, `zone_dream`; `USES` in cl_livingcity_layoutbrowser.lua); they were in no folder there. `client_smoke.py` now fails if any editor mode is in no such folder.
- 2026-11-11 (owner-asked: the Cremator "at least 2x faster in movement speed (not animation speed)"; core, in `CORE_CHANGELOG.md`; spec `docs/features/cremator.md`): new setting `lc_cremator_speed` (2, 0.5 to 4), `LC.CrematorPace`; the unseen npc_stalker walker's playback rate is set to it at spawn and every think, so it covers ground faster while the model's walk is unchanged. Snapshot updated. Waits on the owner: does the pace look right (`PLAYTEST.md`).
- 2026-11-13: a unit's HQ calls only over the radio (the Radio menu on its right click), the resupply scanner, gas masks, hands over mouths and eyes, running from the gas (`docs/features/radio-hq-and-resupply.md`, `gas-masks.md`, `CORE_CHANGELOG.md`).
