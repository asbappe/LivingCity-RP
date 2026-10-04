# Living City

A Combine-occupied city for Garry's Mod: ambient citizens and Civil Protection running real routines, plus factions and ranks, radiant quests with dice, personal story chains, twelve Union jobs, hunger and thirst, social credit, a Commissary, contraband and a black market, stop-and-search, disguises and forged papers, radios, prisons, curfews, and an in-game editor for all of it. Its own gamemode, for singleplayer and servers. It also still works as an addon on Sandbox, DarkRP or Helix/NutScript/Clockwork HL2RP.

## Install and first run

1. Unzip into `garrysmod/addons/` so you have `garrysmod/addons/livingcity/lua/...` and `garrysmod/addons/livingcity/gamemodes/...`
2. In the main menu, click the gamemode button in the bottom right corner and pick **Living City**. Start a game on a city map.
3. The city starts by itself. You're a citizen. Press **F1** for the guide, **F4** to pick a faction.
4. To build the city as an admin, type `!build`. Build mode gives you the spawn menu, the physgun, the toolgun and noclip. Then go to Q menu > Tools > **Living City > Living City Editor**. Type `!build` again to go back to playing.

### Permanent death, and a slower pace

**When you die, that person is gone.** You come back as someone new: a new name and citizen number (shown on name tags and in chat), no credits, no Civil Standing, no job, empty pockets and stash, no rank in any faction, no story, and a housing block of your own. Infested players come back as themselves, admins in build mode are exempt, and dying in custody doesn't end or shorten a sentence. Conduct strikes belong to the real player and stay. `lc_permadeath 0` turns it off; `lc_newcharacter <name>` wipes someone by hand.

**Movement is slower and grounded**, so it feels like a person walking through a city: walk 110, sprint 190 (`lc_walk_speed`, `lc_run_speed`), a short jump (`lc_jump_power`) with a pause before the next one (`lc_jump_delay`), no jumping from a crouch, no ducking in the air, and no gaining speed in the air. `lc_slow_movement 0` brings the Half-Life 2 feel back. The visual style (models, materials, lighting, HUD art) is up to the map and content packs you run; this gamemode only changes how it plays.

### The gamemode, and what's left of Sandbox

Living City is built on Sandbox only so admins keep the building tools. Regular players can't spawn props, NPCs, weapons or vehicles. They also can't noclip, use the physgun or toolgun, or open the spawn and context menus. Factions and ranks are always on. Falls hurt the way they did in Half-Life 2, and there's a short wait before you respawn. Admins outside build mode play by the same rules as everyone else.

Running it as an addon on plain Sandbox still works, but then Sandbox stays Sandbox. In that case, start the city from the editor panel and tick **Enable factions and ranks** yourself.

| Key | Opens |
|---|---|
| F1 or `!help` | The guide (and the admin commands, if you're an admin) |
| F2 or `!inv` | Your pockets (and your stash, when you're home) |
| F3 or `!jobs` | Your board: jobs, story chains, and your Union employment |
| F4 or `!faction` | Factions |
| `!shop` | Union Commissary (or use a commissary terminal) |
| `!market` | Black market (at a dealer, or in rebel territory) |
| `!r <msg>`, `!ru <msg>` | Talk on your radio, or on the Union band |
| `!search` | Units: search the person you're looking at |
| `!stash` | Your hidden stash at home |
| `!block`, `!credits`, `!report <msg>`, `!abandon` | Housing, money and standing, staff reports, drop a job |

## Building a map with the editor

Left click places or tags, right click removes, R cycles modes, Z undoes. Holding the tool shows every point, path, zone and door, and what each NPC is doing.

- **Zones** are shaded on the ground in their color. The zone you're aiming at fills in strongly with a bold edge, and the others dim. Its name and radius show under your crosshair. Aim at a zone's center marker to pick it out from overlapping zones; that's also the one a right click removes. While you're placing a zone, its size is shaded where it will go. Points and path nodes you're aiming at are highlighted the same way. Untick **Shade zones on the ground** in the panel to only shade the one you're aiming at.

### Saving

Every change saves straight away to `garrysmod/data/livingcity/<map>.json`. There's no save button to forget, and the layout loads whenever that map loads, whichever gamemode you're in. Before each save, the previous version is backed up to `garrysmod/data/livingcity/backups/<map>/` (at most every 5 minutes, newest 30 kept). Backups can also be made by hand.

| Command | Does |
|---|---|
| `lc_backup` | Back up the layout now |
| `lc_backups` | List the backups, newest first |
| `lc_restore <number>` | Bring one back (what's there now is backed up first) |

If the layout file is ever damaged, it's copied aside as `<map>_unreadable_<time>.txt` before anything can overwrite it.

**Moving to a server:** install the addon on the server, and copy `garrysmod/data/livingcity/<map>.json` into the server's `garrysmod/data/livingcity/` folder.

### Placing things

- **Points:** loiter, sit, bench, lean, ration line slots (front first), patrol beats (in order), checkpoints, spawn/exit doorways (citizens), prison cells, release spot, **workplaces** (number = job), **infestation spawns** (zombies and infested players) and **resistance spawns** (hunted players). Place the three kinds of spawn far apart so citizens don't walk into the infestation. Citizens only ever appear at their spawn doorways (or, on a map with none, at clean spots), never on Combine metal or glass, in a Combine-only zone, or near an infestation spawn.
- **Fixtures:** water vending machine, ration dispenser, commissary terminal, stove, burning barrel, black market dealer. They appear in the world and come back with the layout. Place them at the foot of a wall and they'll face you. Floor-standing ones sit on the ground. The ration dispenser is wall-mounted at chest height, and a **ration dispenser placed at the front of a ration line** serves that line. Vending machines drop the can out of their slot near the floor.
- **Paths:** nodes and links for places the map's own navigation can't handle. Send a **test walker** to see if a route works.
- **Zones:** no-go, rebel territory (no security), housing blocks (numbered), prison area, infestation, and **Combine only** (the nexus, offices, armory, prison). Citizens, NPC or player, stay out: NPCs never wander or route through it, and a player gets `lc_trespass_grace` seconds (10) to leave before they're wanted for trespassing. Units, admins, people in custody and anyone in a convincing uniform may be inside.
- **Doors:** CP only, always locked, always open, NPCs ignore, force-treat-as-door, plus a tester and inspector. **Doors beside a prison cell or release spot, or inside a prison or Combine-only zone, lock themselves** to everyone but Civil Protection. A tag of your own overrides that.

## The city

Citizens wander, sit, lean, work at workplaces, chat, queue at ration lines, and arrive and leave through doorways. They don't know who Gordon Freeman is. Cops walk beats, hold checkpoints, walk right up to citizens to inspect them (with the trainstation harassment animations, where the model has them), chatter on the radio, and occasionally ask you to pick up a can. Crowd a cop or keep pestering him and you get "move along", then a warning, a shove, a crack with the stick, and then you're wanted for obstructing Civil Protection. Hostile units actually come after you.

**Ration lines:** people nearby join the line and take their places in the order they arrive. The person at the front is served from the ration dispenser if one is placed at the front of the line (it plays its dispensing animation), or by an unseen clerk if not. Players can stand at the front of the line too. After a few seconds you're handed a ration, and the NPCs behind you wait their turn. The usual allocation rules apply: one per allocation, and none for anticitizens. Scanners follow citizens, change altitude now and then, and work themselves free when they snag on walkways. Overwatch soldiers are optional. Zombies live in infestation zones; birds and the odd headcrab roam the streets.

**Events** run automatically or from the panel: rations, inspection sweeps, block raids, curfew, lockdown. During curfew and lockdown your HUD points you home to your housing block, and you get a **grace period of at least 60 seconds** (`lc_curfew_grace`) to reach it, counted down on the HUD. After that, a cop who sees you outside gives three warnings before you're wanted. Citizens walk home into the nearest housing block when curfew starts and go inside, instead of disappearing from the edge of the map.

**Block raids** (`lc_event raid`): a few units walk into one housing block and go through it systematically, a string of stops spread across the block. At each stop they frisk anyone there and confiscate contraband lying around: contraband items, loose weapons, TVs and radios. Whoever dropped or spawned each item is traced, and **each owner becomes wanted for contraband, for longer the more was found under their name** (five or more is a weapons cache, and gets the street units after them). Residents' hidden stashes may be found too, and owners who are offline are wanted when they next log in. `lc_raid_units`, `lc_raid_stash_chance`.

**Prison:** security NPCs arrest instead of kill, CP players arrest with the Arrest Baton, escaping makes you wanted, and sentences survive death and disconnects. **No cells on the map yet?** Then an arrest happens on the street. You're cuffed and made to kneel for 20 seconds (`lc_street_detention`), searched, fined 25 credits (`lc_street_fine`), and let go with a warning. (Arrests need prison **cell points** placed with the editor; a prison zone around them is optional.)

**Giving yourself up:** while you're wanted, walk up to a unit and press E (or type `!surrender` near one). You get half the usual sentence, the search is called off, and serving it pays back more of your Civil Standing.

### Escalation

Violence gets a proportionate answer. Your alert level shows under the WANTED banner.

| Alert | What happens |
|---|---|
| 1 | Wanted. Units nearby come for you and arrest you if they can. |
| 2 | Every unit in the sector has your description, and they draw pistols. Killing a unit gets you here straight away. |
| 3 | Overwatch dispatched: a soldier squad deploys out of sight and hunts you, into rebel territory if need be. Lethal force: no more arrests. |
| 4 | A second squad, and the sector goes into lockdown. |

What raises it: hitting a unit, killing a citizen, a unit, or a soldier, or wrecking a scanner. Getting arrested or killed resets it. Staying out of sight of every unit for 45 seconds cools it down (twice as fast in rebel territory), and the squads go home once you drop below alert 3. A unit you shoot remembers you however far away you were, and follows you into rebel territory. Settings: `lc_response`, `lc_response_soldiers`; admins can test with `lc_setalert <name> <level>`.

### The dead

Citizens, metrocops and soldiers leave a body when they die. Press E on one and stay with it for a few seconds to search it.
- **Citizens:** rations, water, a few credits, sometimes their identity papers.
- **Metrocops:** pistol ammunition, credits, sometimes a stunstick or their **keycard**, which opens one Combine door before it's reported missing.
- **Soldiers:** rifle ammunition, grenades, health vials.

Searching a body in front of a unit is a crime. Bodies stay for 5 minutes (`lc_body_time`), up to 16 at once (`lc_max_bodies`). Birds and headcrabs leave a carcass item instead of a ragdoll, so nothing appears twice.

## The city's people

Every citizen and Civil Protection unit is a **named person with a profile that never changes**: a name, a sex and voice, a model, a Union job, and a housing block. You'll see the same faces again. Look at one to see their name and what they do. They spend part of their day at their workplace (if the map has one for their job) and go to **their own block** at curfew. About one in eight citizens (`lc_rebel_pct`) is secretly a **Resistance sympathizer**: Resistance players see "one of ours" on them, and the Resistance's contacts and supply runs are drawn from them.

`lc_citizens` and `lc_cops` still set how many are out on the streets at once; the roster (`lc_roster_size` citizens, `lc_roster_cops` units) is everybody who lives in the city, and they take turns, the person who's been away longest coming out next. The roster is saved per map in `garrysmod/data/livingcity/<map>_people.json`, so it's the same people next session and next week. **A person who is killed stays dead**, and the city fills the gap with a new arrival. `lc_people [list]` summarizes, `lc_resetpeople` starts over.

## Factions and ranks

| Faction | Ladder |
|---|---|
| Citizen | Citizen, Union Worker, Loyalist, Model Citizen |
| Resistance | Sympathizer, Member (pass for citizens), Fighter, Lieutenant, Commander (hunted outside rebel zones) |
| Civil Protection | RCT, 05, 04, 03, 02, 01, OfC, EpU, DvL, SeC |
| Overwatch | OWS, Prison Guard, Elite (needs Unit 01) |
| City Administrator | whitelist only |
| Infested | Zombie, Fast Zombie, Zombine |

**Father Grigori** is a special Resistance role: The Blessing heals, preaching draws Civil Protection, and he's hunted on sight outside rebel territory. Edit `lua/autorun/sh_livingcity_factions.lua` to rename ranks, change XP, models and loadouts.

## Jobs and quests (F3)

**Finding the objective.** The tracker on the right shows a compass for whatever you're after: a pointer relative to where you're facing, the distance in meters, a heading (ahead, behind left, ...) and whether it's on your level, a floor or more **UP**, or **DOWN**. It works even when the target is far enough away that the game isn't drawing it. Quests never send you to the infestation or onto Combine ground. Deliveries are made to **people**: the mail comes from the postal clerk and goes to named residents, Mrs. Kleiner hands you her parcel herself, luggage goes back to its owner, uniforms go to the unit at the checkpoint. Ration crates come from the truck driver and go to the kitchen hand, and the Resistance's supply runs, the weapons ring and the proof-of-nerve parcel are handed over by and to contacts. Each person waits at a marked spot; walk up and press E.

Each faction has a board of radiant jobs built from your actual map: Directives, Protocols, Agenda, Operations, Assignments, Urges. Many have **choices with d20 checks** (Authority, Empathy, Guile, Nerve), and your choices build three traits that stick: **Loyalty, Sympathy, Corruption**.

Built for crowded servers: no job ever targets a player, boards are finite and scale with faction size, violent jobs are capped city-wide, and people can squad up.

## Story chains

Personal stories that unlock from what you've done, appear at the top of your board marked **Your Story**, and branch on your choices:

| Story | Who it finds |
|---|---|
| Internal Affairs | Cops who take bribes |
| The Man Inside | Kind, clean cops. Defect, or stay in uniform as a double agent with secret **Inside Work**, until **Suspicion** brings a **Mole Hunt** |
| The Missing Unit | Experienced cops. Three different truths |
| The Overwatch Candidate | Unit 01s. Accept conditioning, or keep your name |
| The Pamphleteer | Kind citizens. Can end with you joining the Resistance |
| The Informant | Loyal citizens. Includes tailing a neighbor without being seen |
| Father Grigori's Flock | The chaplain. A secret mass, and a traitor among the faithful |

Admins can start any chain directly: `lcq_startchain <ia|inside|missing|candidate|pamphleteer|informant|flock> [player]`. `lcq_story <name>` shows someone's traits, counters and progress; `lcq_resetstory <name>` starts them over.

## Union jobs

Citizens (and Resistance members who still pass for citizens) choose a job on their board. Promotions never take your tools away. Each job posts a steady stream of **Union shifts** at its workplaces, or in the streets if none are marked:

| # | Job | Shifts |
|---|---|---|
| 1 | Sanitation Worker | Litter sweeps, bin rounds (at the map's own bins), graffiti removal |
| 2 | Ration Kitchen | Prep, supply runs, serving the line |
| 3 | Clinic Medic (gets a medkit) | Clinic rounds, house calls |
| 4 | Factory Worker | Assembly quotas, the loading dock, a foreman who skims |
| 5 | Courier | Mail rounds, sealed envelopes |
| 6 | Maintenance Technician | Fuse boxes, faulty terminals |
| 7 | Station Porter | New arrivals to walk home, luggage, ticket checks |
| 8 | Records Clerk | Filing, the permit desk, the cabinet of blank identity forms |
| 9 | Uniform Laundry | Wash cycles, pressed uniforms for the precinct, bloodstains |
| 10 | Mortuary Attendant | Collecting the dead, the incinerator |
| 11 | Reclamation Crew | Scrap runs, rubble that sometimes hides a weapons cache |
| 12 | Radio Repair | Loudspeakers, the repair bench, Union radio orders |

The number is the workplace number in the editor. Shifts pay Credits and Civil Standing, and many carry small choices: the mother with one ration card, the beaten man who begs you to write "fell down the stairs". The newer jobs are also where contraband comes from, if you want it: blank forms from the records office, a spare uniform from the laundry, a dead man's papers from the morgue, a retuned radio from the repair bench.

## Survival

- **Hunger and thirst** drain while the city runs. At zero you start dying. Prisoners are fed; Overwatch and the Infested don't eat.
- **Pockets** (F2) hold 12 items: eat, drink, cook, fill, drop.
- **Water:** wade in and press E to drink. Untreated water can give you **parasites** (hungrier, thirstier, coughing) until you take antiparasitic tablets.
- **Breen's Private Reserve** from the vending machines quenches thirst and leaves you dizzy. Sometimes you forget what you were doing, and so does your quest tracker. You keep the empty can.
- **Bottles and cans:** fill them in water, then boil them over a stove or fire.
- **Hunting:** birds and headcrabs leave carcasses. Cook them at a stove or burning barrel (any stove, oven or fire already on the map works too). Raw meat is a gamble.
- **Stoves, sinks and vending machines** the map already has work as fixtures, including ones baked into the map as static props: the game reads their positions straight from the map file. Stand by a stove to cook (F2). Press E at a sink to drink (a small parasite risk) and fill bottles and cans from your pockets, then boil them. Press E at a vending machine to buy a can. `lc_scanprops` rescans the map and says what it found.
- **Fists:** everyone has them. One punch kills a bird. A headcrab takes several. People barely notice. Don't go AFK in an alley with headcrabs around.
- **Ration dispensers** give a ration packet once per allocation (twice as often during distribution), unless your standing is too low.

## Social credit

**Getting your standing back:** anyone below zero gets **community service** on their board (F3), no job needed: litter sweeps and bin rounds that restore 40 standing each. Serving time also pays it back: a quarter of what you owe plus 100, and 75 more if you turned yourself in. It never takes you past zero, though. Quiet compliance adds 10 every 10 minutes while you're below zero.

**Credits** are money: earned from shifts, jobs and ration coupons, spent at the Commissary and vending machines (on DarkRP, this is DarkRP money). **Civil Standing** runs from -1000 to 1000: work, compliance and reporting raise it; being wanted, jailed, escaping, curfew violations and conduct strikes lower it. Your tier (Anticitizen, Probationary, Citizen, Trusted, Exemplary) decides what the **Union Commissary** will sell you, from rations and water for everyone, to medkits for the Trusted, to watermelon and real coffee for Exemplary citizens. Units can buy ammunition and batteries. Edit `lua/autorun/sh_livingcity_shop.lua` for items, prices and tiers.

## Contraband, searches and the underground

**Stop and search.** Civil Protection NPCs stop people and frisk them. It happens sometimes at checkpoints, rarely on the street, and constantly during inspection sweeps. Each person has a cooldown, so on a big server it doesn't keep landing on the same few people. When you're stopped, stand still. Walk off and you're wanted for evading inspection. They check your papers, then your pockets. Each illegal item has a chance to slip past (Guile improves it). Anything they find is confiscated, and you lose standing and become wanted. Units (players) search people with the Arrest Baton (reload) or `!search`, and get credits and XP for what they seize. Getting arrested confiscates everything illegal you were carrying.

| Item | Where | What it does |
|---|---|---|
| Union radio | Commissary | Union band: city notices about 45 seconds before an event, and `!r` to talk. CP monitors it |
| Retuned radio | Black market, radio bench | Freq 7: private Resistance chat, sweep warnings, and garbled Civil Protection dispatch |
| Travel permit | Commissary (Trusted) | Gets you past one curfew stop, for the rest of that curfew |
| Spare citizen clothes | Commissary, black market | A hunted Resistance member passes as a citizen (and can hold a Union job) until someone checks their face. Units can wear them to go undercover |
| Civil Protection uniform | Black market, laundry | Security NPCs take you for a unit, even if you're wanted. Combine doors usually open. Blown by any crime, by lingering near real units, by a door reading your biosignal, or by a real unit's search. Real units who look closely see "not on the roster" |
| Forged papers / a dead man's papers | Black market, morgue, or forge a blank form | A new identity: clears your wanted status if no unit is watching. Inspections can catch it (dead men's papers are better) |
| Blank identity form | Black market, records office, luggage | Forge it in your own block or rebel territory (Guile check) |
| Forged ration card | Black market | One ration from any dispenser, whatever your standing or cooldown |
| Lockpick set | Black market | Locked doors (not Combine locks). Can snap. Being seen is breaking and entering |
| Combine bypass charge | Black market | Opens any door once, Combine doors included. Sometimes trips an alarm |

**Stash.** Eight hidden slots in your own housing block (`!stash`, or F2 while you're home). Searches never reach it, but inspection sweeps sometimes raid it. A retuned radio warns you before a sweep.

**Black market.** Place a dealer with the editor, or on maps without one, trade in rebel territory (`!market`). The dealer sells contraband and a crowbar, and buys scrap, wedding rings, uniforms and spare papers. A unit who walks up to the dealer busts it: it vanishes for 15 minutes, the unit gets paid, and Freq 7 hears about it. Edit `lua/autorun/sh_livingcity_shop.lua` for prices and items.

Admin helpers: `lc_giveitem <name> <item> [count]`, `lc_search <name>`.

## Conduct

Every player kill is judged; unjustified ones earn strikes (2: prison, 4: kick), and leaving mid-fight is remembered. New spawns get 8 seconds of protection. Logged to `garrysmod/data/livingcity/conduct_log.txt`.

## DarkRP and HL2RP

Detected automatically. CP jobs and Combine factions count as Civil Protection, DarkRP's wanted system, jail and money are used, CP door groups count as CP doors, and Living City never takes over doors on RP gamemodes. Its own factions stay off there. Override anything with hooks: `LivingCityIsCP`, `LivingCityIsZombie`, `LivingCityIsWanted`, `LivingCityCrime`, `LivingCityCanUseCPDoor`, `LivingCityJudgeKill`.

## Big servers

`lc_npc_budget` caps NPCs (40 to 60 is sensible for a full server). Distant NPCs think less often, and relationships only touch the engine when something changes. NPC stops are capped at a few at a time (one per 16 players online), and each person has a cooldown (`lc_stop_cooldown`, 8 minutes by default). The debug report includes timings.

## When something breaks

Run **Copy debug report** in the editor panel (or `lc_debugreport`). It copies settings, layout, every NPC's state, jobs in progress, player status, timings and recent errors to your clipboard, and saves a copy in `garrysmod/data/livingcity/reports/`. It also lists setup notes, such as a missing prison, missing doorways, or a ration line with no dispenser at its front. Paste it to Claude.

## Admin commands

Gamemode: `lc_buildmode` (or `!build`), `lc_permadeath`, `lc_newcharacter <name>`, `lc_slow_movement`, `lc_walk_speed`, `lc_run_speed`, `lc_jump_power`, `lc_jump_delay`. Escalation: `lc_setalert <name> <level>`. Curfew and raids: `lc_curfew_grace`, `lc_event raid`, `lc_raid_units`, `lc_raid_stash_chance`, `lc_trespass_grace`.
City: `lc_start`, `lc_stop`, `lc_calm`, `lc_status`, `lc_reload`, `lc_savesettings`, `lc_autolink`, `lc_event <rations|sweep|curfew|lockdown> [minutes]`, `lc_endevent`, `lc_announce`, `lc_unlockdoors`, `lc_opendoors`.
People: `lc_jail`, `lc_unjail`, `lc_prisoners`, `lc_setblock`, `lc_reassignblocks`, `lc_conduct`, `lc_pardon`, `lc_setjob`, `lc_givecredits`, `lc_setstanding`, `lc_giveitem`, `lc_search`, `lcf_setfaction`, `lcf_setxp`, `lcf_promote`, `lcf_demote`, `lcf_whitelist`.
Stories: `lcq_startchain`, `lcq_story`, `lcq_resetstory`. Debug: `lc_debugreport`.

## Honest limits

The server logic and the gamemode's rules are exercised by 485 automated scenario tests, and the client HUD and editor overlay by a smoke test, all against a simulated Garry's Mod (see `_dev/`). Real-game playtesting has only just started, so expect rough edges in anything visual or audible: animations, sounds, menus, HUD layout, and entity models. Send the debug report and they'll get fixed.
