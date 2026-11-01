# Every line of text a player sees

Made by `python3 _dev/player_text.py` from the code itself, so it can be made again after any change. Grouped by the part of the game it belongs to. Each line: the text (parts the game fills in look like {name}, and %d, %s or %.1f are numbers or words filled in), how it shows (a chat message, an on-screen notice, a button...), and when it appears. The lines starting with "Note for you" are never shown to players: they're the programmer's own note from the code, about what's going on in the game at that moment, so you know where the text below them comes up. Only the text in quotes is what players see. Where it says "text" instead of "chat message" or "on-screen notice", the script couldn't tell how it's shown: ask if it matters for a wording. The file and line are there so a correction can be found.

**How to correct it:** change the words inside the quotes, then send the whole file back. Leave everything outside the quotes as it is (that's how each line is found in the code again). Keep any {name} or %d / %s parts: the game fills those in. A line you don't touch stays as it is. To drop a line altogether, write DELETE inside its quotes. A note for me about a line can go after it on the same line, starting with NOTE:.

Made from version 2971ce3. Admin-only console messages and log lines are left out.

6135 lines, from 186 files.

## Contents

- [lc_barricade.lua](#lcbarricadelua-lcbarricadelua) (1)
- [lc_broadcastcam.lua](#lcbroadcastcamlua-lcbroadcastcamlua) (1)
- [lc_citybin.lua](#lccitybinlua-lccitybinlua) (1)
- [lc_console.lua](#lcconsolelua-lcconsolelua) (1)
- [lc_conveyor.lua](#lcconveyorlua-lcconveyorlua) (1)
- [lc_cpsupply.lua](#lccpsupplylua-lccpsupplylua) (2)
- [lc_crate.lua](#lccratelua-lccratelua) (1)
- [lc_dataterminal.lua](#lcdataterminallua-lcdataterminallua) (1)
- [lc_dealer.lua](#lcdealerlua-lcdealerlua) (1)
- [lc_dispenser.lua](#lcdispenserlua-lcdispenserlua) (2)
- [lc_dropship.lua](#lcdropshiplua-lcdropshiplua) (1)
- [lc_fire.lua](#lcfirelua-lcfirelua) (1)
- [lc_forcefield.lua](#lcforcefieldlua-lcforcefieldlua) (1)
- [lc_hazbarrel.lua](#lchazbarrellua-lchazbarrellua) (1)
- [lc_intake.lua](#lcintakelua-lcintakelua) (1)
- [lc_item.lua](#lcitemlua-lcitemlua) (2)
- [lc_item_ration.lua](#lcitemrationlua-lcitemrationlua) (1)
- [lc_item_water.lua](#lcitemwaterlua-lcitemwaterlua) (1)
- [lc_jammer.lua](#lcjammerlua-lcjammerlua) (1)
- [lc_lawboard.lua](#lclawboardlua-lclawboardlua) (1)
- [lc_masterterminal.lua](#lcmasterterminallua-lcmasterterminallua) (1)
- [lc_nest.lua](#lcnestlua-lcnestlua) (1)
- [lc_powerbank.lua](#lcpowerbanklua-lcpowerbanklua) (1)
- [lc_recycler.lua](#lcrecyclerlua-lcrecyclerlua) (2)
- [lc_rscanner.lua](#lcrscannerlua-lcrscannerlua) (2)
- [lc_scientist.lua](#lcscientistlua-lcscientistlua) (1)
- [lc_screen.lua](#lcscreenlua-lcscreenlua) (1)
- [lc_stall.lua](#lcstalllua-lcstalllua) (2)
- [lc_supply.lua](#lcsupplylua-lcsupplylua) (1)
- [lc_terminal.lua](#lcterminallua-lcterminallua) (2)
- [lc_vending.lua](#lcvendinglua-lcvendinglua) (2)
- [lc_workbench.lua](#lcworkbenchlua-lcworkbenchlua) (1)
- [weapon_lc_baton.lua](#weaponlcbatonlua-weaponlcbatonlua) (8)
- [weapon_lc_blessing.lua](#weaponlcblessinglua-weaponlcblessinglua) (7)
- [weapon_lc_hoover.lua](#weaponlchooverlua-weaponlchooverlua) (2)
- [weapon_lc_microphone.lua](#weaponlcmicrophonelua-weaponlcmicrophonelua) (4)
- [weapon_lc_multitool.lua](#weaponlcmultitoollua-weaponlcmultitoollua) (14)
- [weapon_lc_radio.lua](#weaponlcradiolua-weaponlcradiolua) (6)
- [Infestation Cleanup and the Groundskeeper)](#infestation-cleanup-and-the-groundskeeper-weaponlcsprayerlua) (2)
- [weapon_lc_vort.lua](#weaponlcvortlua-weaponlcvortlua) (10)
- [cl_init.lua](#clinitlua-clinitlua) (246)
- [init.lua](#initlua-initlua) (5)
- [cl_livingcity.lua](#cllivingcitylua-cllivingcitylua) (21)
- [cl_livingcity_actions.lua](#cllivingcityactionslua-cllivingcityactionslua) (50)
- [cl_livingcity_admintools.lua](#cllivingcityadmintoolslua-cllivingcityadmintoolslua) (22)
- [cl_livingcity_atmos.lua](#cllivingcityatmoslua-cllivingcityatmoslua) (5)
- [cl_livingcity_character.lua](#cllivingcitycharacterlua-cllivingcitycharacterlua) (14)
- [cl_livingcity_cp.lua](#cllivingcitycplua-cllivingcitycplua) (26)
- [secret endings, on your screen (sv_livingcity_endings.lua)](#secret-endings-on-your-screen-svlivingcityendingslua-cllivingcityendingslua) (65)
- [the Endings menu (superadmins): tune the secret endings live](#the-endings-menu-superadmins-tune-the-secret-endings-live-cllivingcityendingtunelua) (69)
- [morning exercise, on your screen (sv_livingcity_exercise.lua)](#morning-exercise-on-your-screen-svlivingcityexerciselua-cllivingcityexerciselua) (11)
- [cl_livingcity_factions.lua](#cllivingcityfactionslua-cllivingcityfactionslua) (22)
- [cl_livingcity_grigori.lua](#cllivingcitygrigorilua-cllivingcitygrigorilua) (10)
- [cl_livingcity_hints.lua](#cllivingcityhintslua-cllivingcityhintslua) (11)
- [cl_livingcity_infest.lua](#cllivingcityinfestlua-cllivingcityinfestlua) (9)
- [cl_livingcity_intake.lua](#cllivingcityintakelua-cllivingcityintakelua) (32)
- [cl_livingcity_jobgames.lua](#cllivingcityjobgameslua-cllivingcityjobgameslua) (11)
- [cl_livingcity_kick.lua](#cllivingcitykicklua-cllivingcitykicklua) (11)
- [cl_livingcity_lab.lua](#cllivingcitylablua-cllivingcitylablua) (9)
- [cl_livingcity_lagwatch.lua](#cllivingcitylagwatchlua-cllivingcitylagwatchlua) (27)
- [cl_livingcity_layoutbrowser.lua](#cllivingcitylayoutbrowserlua-cllivingcitylayoutbrowserlua) (33)
- [cl_livingcity_life.lua](#cllivingcitylifelua-cllivingcitylifelua) (11)
- [cl_livingcity_moregames.lua](#cllivingcitymoregameslua-cllivingcitymoregameslua) (44)
- [cl_livingcity_needs.lua](#cllivingcityneedslua-cllivingcityneedslua) (69)
- [cl_livingcity_nextstep.lua](#cllivingcitynextsteplua-cllivingcitynextsteplua) (23)
- [cl_livingcity_notices.lua](#cllivingcitynoticeslua-cllivingcitynoticeslua) (15)
- [cl_livingcity_outfits.lua](#cllivingcityoutfitslua-cllivingcityoutfitslua) (14)
- [cl_livingcity_quests.lua](#cllivingcityquestslua-cllivingcityquestslua) (17)
- [cl_livingcity_quick.lua](#cllivingcityquicklua-cllivingcityquicklua) (51)
- [apartment doors (client)](#apartment-doors-client-cllivingcityrentlua) (12)
- [cl_livingcity_resistance.lua](#cllivingcityresistancelua-cllivingcityresistancelua) (5)
- [cl_livingcity_rest.lua](#cllivingcityrestlua-cllivingcityrestlua) (5)
- [cl_livingcity_rp.lua](#cllivingcityrplua-cllivingcityrplua) (7)
- [the scanner link, as the pilot sees it, and scanner reports,](#the-scanner-link-as-the-pilot-sees-it-and-scanner-reports-cllivingcityscannerlua) (6)
- [cl_livingcity_screens.lua](#cllivingcityscreenslua-cllivingcityscreenslua) (3)
- [cl_livingcity_slots.lua](#cllivingcityslotslua-cllivingcityslotslua) (18)
- [cl_livingcity_staff.lua](#cllivingcitystafflua-cllivingcitystafflua) (21)
- [cl_livingcity_talk.lua](#cllivingcitytalklua-cllivingcitytalklua) (8)
- [cl_livingcity_unittools.lua](#cllivingcityunittoolslua-cllivingcityunittoolslua) (56)
- [cl_livingcity_view.lua](#cllivingcityviewlua-cllivingcityviewlua) (4)
- [cl_livingcity_war.lua](#cllivingcitywarlua-cllivingcitywarlua) (13)
- [cl_livingcity_ways.lua](#cllivingcitywayslua-cllivingcitywayslua) (2)
- [cl_livingcity_writing.lua](#cllivingcitywritinglua-cllivingcitywritinglua) (20)
- [sv_livingcity.lua](#svlivingcitylua-svlivingcitylua) (47)
- [the actions menu (server side)](#the-actions-menu-server-side-svlivingcityactionslua) (1)
- [acts (server). See sh_livingcity_acts.lua for the list](#acts-server-see-shlivingcityactslua-for-the-list-svlivingcityactslua) (7)
- [testing tools for admins](#testing-tools-for-admins-svlivingcityadmintoolslua) (36)
- [custom announcements, for Overwatch and for the Administrator](#custom-announcements-for-overwatch-and-for-the-administrator-svlivingcityannouncerlua) (34)
- [the time of day, the weather, and the city's music](#the-time-of-day-the-weather-and-the-citys-music-svlivingcityatmoslua) (6)
- [the dead](#the-dead-svlivingcitybodieslua) (9)
- [apartments and trade](#apartments-and-trade-svlivingcitybusinesslua) (41)
- [rearranging a rebel camp](#rearranging-a-rebel-camp-svlivingcitycampmovelua) (3)
- [characters and permanent death](#characters-and-permanent-death-svlivingcitycharacterlua) (28)
- [checkpoints, turrets, and holding the infestation back](#checkpoints-turrets-and-holding-the-infestation-back-svlivingcitycheckpointslua) (49)
- [weedkiller against the infestation, and against the Combine (the owner, 2026-11-01)](#weedkiller-against-the-infestation-and-against-the-combine-the-owner-2026-11-01-svlivingcitycleanuplua) (26)
- [Half-Life: Alyx-style Combine models](#half-life-alyx-style-combine-models-svlivingcitycombinemodelslua) (3)
- [conduct (anti-RDM and anti-combat-logging)](#conduct-anti-rdm-and-anti-combat-logging-svlivingcityconductlua) (26)
- [supply drops, radio jammers](#supply-drops-radio-jammers-svlivingcityconvoylua) (33)
- [Civil Protection's toolset](#civil-protections-toolset-svlivingcitycplua) (98)
- [the Civil Protection Commissary (units' supplies)](#the-civil-protection-commissary-units-supplies-svlivingcitycpsupplylua) (8)
- [making things, grenades, the arms trade, and getting people out](#making-things-grenades-the-arms-trade-and-getting-people-out-svlivingcitycraftinglua) (30)
- [what custody costs the worst anticitizens](#what-custody-costs-the-worst-anticitizens-svlivingcitycustodylua) (29)
- [saved layout](#saved-layout-svlivingcitydatalua) (14)
- [debugging](#debugging-svlivingcitydebuglua) (60)
- [doors](#doors-svlivingcitydoorslua) (8)
- [the Combine's dropship](#the-combines-dropship-svlivingcitydropshiplua) (7)
- [economy and social credit](#economy-and-social-credit-svlivingcityeconomylua) (32)
- [secret endings](#secret-endings-svlivingcityendingslua) (76)
- [escorts through Combine doors](#escorts-through-combine-doors-svlivingcityescortlua) (73)
- [city events](#city-events-svlivingcityeventslua) (78)
- [morning exercise (mandatory for citizens)](#morning-exercise-mandatory-for-citizens-svlivingcityexerciselua) (60)
- [sv_livingcity_factions.lua](#svlivingcityfactionslua-svlivingcityfactionslua) (38)
- [Freq 7, the Resistance's pirate broadcast](#freq-7-the-resistances-pirate-broadcast-svlivingcityfreq7lua) (6)
- [the Resistance's money (besides raiding supply drops)](#the-resistances-money-besides-raiding-supply-drops-svlivingcityfundinglua) (16)
- [Father Grigori, in the flesh](#father-grigori-in-the-flesh-svlivingcitygrigorilua) (16)
- [flood guard](#flood-guard-svlivingcityguardlua) (3)
- [stealing the Combine's data](#stealing-the-combines-data-svlivingcityheistlua) (32)
- [tips that pop up the first time something happens](#tips-that-pop-up-the-first-time-something-happens-svlivingcityhintslua) (325)
- [housing blocks](#housing-blocks-svlivingcityhousinglua) (5)
- [toilets, baths and what happens without them](#toilets-baths-and-what-happens-without-them-svlivingcityhygienelua) (51)
- [the Resistance Insider (a Civil Protection unit secretly with the Resistance)](#the-resistance-insider-a-civil-protection-unit-secretly-with-the-resistance-svlivingcityinsiderlua) (50)
- [Civil Intake (becoming somebody)](#civil-intake-becoming-somebody-svlivingcityintakelua) (73)
- [work you actually do](#work-you-actually-do-svlivingcityjobgameslua) (99)
- [the unit's kick](#the-units-kick-svlivingcitykicklua) (23)
- [the Resistance lab](#the-resistance-lab-svlivingcitylablua) (50)
- [a life](#a-life-svlivingcitylifelua) (42)
- [Resistance lookouts](#resistance-lookouts-svlivingcitylookoutslua) (14)
- [what loyalty earns (the owner, 2026-11-01: "other rewards for high standing civilians? All of them")](#what-loyalty-earns-the-owner-2026-11-01-other-rewards-for-high-standing-civilians-all-of-them-svlivingcityloyaltylua) (5)
- [letters](#letters-svlivingcitymaillua) (14)
- [marched to the cells](#marched-to-the-cells-svlivingcitymarchlua) (17)
- [more work you actually do (the engine is sv_livingcity_jobgames.lua)](#more-work-you-actually-do-the-engine-is-svlivingcityjobgameslua-svlivingcitymoregameslua) (218)
- [hauling the dead](#hauling-the-dead-svlivingcitymortuarylua) (20)
- [routes over the map's own nodegraph](#routes-over-the-maps-own-nodegraph-svlivingcitynavgraphlua) (1)
- [what now?](#what-now-svlivingcitynextsteplua) (37)
- [on the screen, not just in chat](#on-the-screen-not-just-in-chat-svlivingcitynoticeslua) (17)
- [the city does its own work](#the-city-does-its-own-work-svlivingcitynpcworklua) (49)
- [clothes that show the job](#clothes-that-show-the-job-svlivingcityoutfitslua) (8)
- [path mapping, drawing the walkable network by walking it](#path-mapping-drawing-the-walkable-network-by-walking-it-svlivingcitypathmaplua) (6)
- [people](#people-svlivingcitypeoplelua) (5)
- [server timing](#server-timing-svlivingcityperflua) (4)
- [the power grid](#the-power-grid-svlivingcitypowerlua) (28)
- [prison](#prison-svlivingcityprisonlua) (39)
- [close calls, careers for life, and what passes on](#close-calls-careers-for-life-and-what-passes-on-svlivingcityprogresslua) (16)
- [street furniture, and the city's voice](#street-furniture-and-the-citys-voice-svlivingcitypropagandalua) (43)
- [persistent props](#persistent-props-svlivingcitypropslua) (6)
- [quests](#quests-svlivingcityquestslua) (363)
- [habitation block raids](#habitation-block-raids-svlivingcityraidslua) (15)
- ["ration units are being deducted"](#ration-units-are-being-deducted-svlivingcityrationslua) (5)
- [rebel life](#rebel-life-svlivingcityrebellifelua) (34)
- [the Resistance on the street](#the-resistance-on-the-street-svlivingcityrebelslua) (71)
- [the Resistance's operations, and what the city does about them](#the-resistances-operations-and-what-the-city-does-about-them-svlivingcityresistanceopslua) (99)
- [escalation](#escalation-svlivingcityresponselua) (24)
- [sleep](#sleep-svlivingcityrestlua) (11)
- [talking, knowing each other, and going down](#talking-knowing-each-other-and-going-down-svlivingcityrplua) (47)
- [running in front of Civil Protection](#running-in-front-of-civil-protection-svlivingcityrunninglua) (23)
- [salvage, bins anywhere, the reclamation point, and workbenches](#salvage-bins-anywhere-the-reclamation-point-and-workbenches-svlivingcitysalvagelua) (42)
- [flying a scanner from a Combine console](#flying-a-scanner-from-a-combine-console-svlivingcityscannerlua) (46)
- [getting by](#getting-by-svlivingcityscavengelua) (61)
- [Combine-only areas](#combine-only-areas-svlivingcitysecuritylua) (10)
- [jobs that come with supply drops, and Union work orders that](#jobs-that-come-with-supply-drops-and-union-work-orders-that-svlivingcitysidejobslua) (95)
- [character slots](#character-slots-svlivingcityslotslua) (20)
- [staff tools](#staff-tools-svlivingcitystafflua) (48)
- [the stalker's lot](#the-stalkers-lot-svlivingcitystalkerworklua) (56)
- [static map props](#static-map-props-svlivingcitystaticpropslua) (10)
- [the city's stores](#the-citys-stores-svlivingcitystockpilelua) (8)
- [places to keep things](#places-to-keep-things-svlivingcitystoragelua) (44)
- [story chains](#story-chains-svlivingcitystorieslua) (343)
- [survival](#survival-svlivingcitysurvivallua) (59)
- [talking to people](#talking-to-people-svlivingcitytalklua) (28)
- [territory that spreads, and is pushed back](#territory-that-spreads-and-is-pushed-back-svlivingcityterritorylua) (28)
- [the trains](#the-trains-svlivingcitytrainslua) (9)
- [the underground](#the-underground-svlivingcityundergroundlua) (180)
- [powered vests ("suit power")](#powered-vests-suit-power-svlivingcityvestlua) (4)
- [vortigaunts](#vortigaunts-svlivingcityvortlua) (12)
- [things to do as a vortigaunt (and for the city's own)](#things-to-do-as-a-vortigaunt-and-for-the-citys-own-svlivingcityvortworklua) (47)
- [the state of the city](#the-state-of-the-city-svlivingcitywarlua) (58)
- [ways to get by](#ways-to-get-by-svlivingcitywayslua) (5)
- [weeds, the Groundskeeper, and weedkiller (the owner, 2026-11-01)](#weeds-the-groundskeeper-and-weedkiller-the-owner-2026-11-01-svlivingcityweedslua) (11)
- [occupations](#occupations-svlivingcityworklua) (304)
- [writing, broadcasts, and the law](#writing-broadcasts-and-the-law-svlivingcitywritinglua) (37)
- [acts (shared)](#acts-shared-shlivingcityactslua) (2)
- [sh_livingcity_cp.lua](#shlivingcitycplua-shlivingcitycplua) (44)
- [sh_livingcity_factions.lua](#shlivingcityfactionslua-shlivingcityfactionslua) (31)
- [sh_livingcity_jobs.lua](#shlivingcityjobslua-shlivingcityjobslua) (43)
- [sh_livingcity_shop.lua](#shlivingcityshoplua-shlivingcityshoplua) (233)
- [shared.lua](#sharedlua-sharedlua) (1)

## lc_barricade.lua (lc_barricade.lua)

`gamemodes/livingcity/entities/entities/lc_barricade.lua`

- "Combine barricade"  (name, line 11)

## lc_broadcastcam.lua (lc_broadcastcam.lua)

`gamemodes/livingcity/entities/entities/lc_broadcastcam.lua`

- "Broadcast camera"  (name, line 13)

## lc_citybin.lua (lc_citybin.lua)

`gamemodes/livingcity/entities/entities/lc_citybin.lua`

- "City bin"  (name, line 9)

## lc_console.lua (lc_console.lua)

`gamemodes/livingcity/entities/entities/lc_console.lua`

- "Combine console"  (name, line 8)

## lc_conveyor.lua (lc_conveyor.lua)

`gamemodes/livingcity/entities/entities/lc_conveyor.lua`

- "Conveyor belt"  (name, line 12)

## lc_cpsupply.lua (lc_cpsupply.lua)

`gamemodes/livingcity/entities/entities/lc_cpsupply.lua`

- "Civil Protection Commissary"  (name, line 14)

> Note for you (not shown in game): part of: draw

- "Commissary: Issues supplies for Civil Protection units"  (drawn on screen, line 59)

## lc_crate.lua (lc_crate.lua)

`gamemodes/livingcity/entities/entities/lc_crate.lua`

- "Storage crate"  (name, line 11)

## lc_dataterminal.lua (lc_dataterminal.lua)

`gamemodes/livingcity/entities/entities/lc_dataterminal.lua`

- "Combine data terminal"  (name, line 9)

## lc_dealer.lua (lc_dealer.lua)

`gamemodes/livingcity/entities/entities/lc_dealer.lua`

- "Black market dealer"  (name, line 14)

## lc_dispenser.lua (lc_dispenser.lua)

`gamemodes/livingcity/entities/entities/lc_dispenser.lua`

- "Ration dispenser"  (name, line 12)

> Note for you (not shown in game): part of: use

- "Blackout: no rations until power is restored."  (chat message, line 42)

## lc_dropship.lua (lc_dropship.lua)

`gamemodes/livingcity/entities/entities/lc_dropship.lua`

- "Combine dropship"  (name, line 10)

## lc_fire.lua (lc_fire.lua)

`gamemodes/livingcity/entities/entities/lc_fire.lua`

- "Burning barrel"  (name, line 7)

## lc_forcefield.lua (lc_forcefield.lua)

`gamemodes/livingcity/entities/entities/lc_forcefield.lua`

- "Combine forcefield"  (name, line 16)

## lc_hazbarrel.lua (lc_hazbarrel.lua)

`gamemodes/livingcity/entities/entities/lc_hazbarrel.lua`

- "Infestation control barrel"  (name, line 11)

## lc_intake.lua (lc_intake.lua)

`gamemodes/livingcity/entities/entities/lc_intake.lua`

- "Civil Intake terminal"  (name, line 13)

## lc_item.lua (lc_item.lua)

`gamemodes/livingcity/entities/entities/lc_item.lua`


> Note for you (not shown in game): part of: use

- "Picked up: {id}"  (chat message, line 41)
- "Your pockets are full."  (chat message, line 46)

## lc_item_ration.lua (lc_item_ration.lua)

`gamemodes/livingcity/entities/entities/lc_item_ration.lua`

- "Ration packet"  (name, line 4)

## lc_item_water.lua (lc_item_water.lua)

`gamemodes/livingcity/entities/entities/lc_item_water.lua`

- "Breen's Private Reserve"  (name, line 4)

## lc_jammer.lua (lc_jammer.lua)

`gamemodes/livingcity/entities/entities/lc_jammer.lua`

- "Radio jammer"  (name, line 10)

## lc_lawboard.lua (lc_lawboard.lua)

`gamemodes/livingcity/entities/entities/lc_lawboard.lua`

- "Law board"  (name, line 10)

## lc_masterterminal.lua (lc_masterterminal.lua)

`gamemodes/livingcity/entities/entities/lc_masterterminal.lua`

- "Combine master terminal"  (name, line 11)

## lc_nest.lua (lc_nest.lua)

`gamemodes/livingcity/entities/entities/lc_nest.lua`

- "Infestation growth"  (name, line 10)

## lc_powerbank.lua (lc_powerbank.lua)

`gamemodes/livingcity/entities/entities/lc_powerbank.lua`

- "Combine power bank"  (name, line 12)

## lc_recycler.lua (lc_recycler.lua)

`gamemodes/livingcity/entities/entities/lc_recycler.lua`

- "Reclamation point"  (name, line 9)

> Note for you (not shown in game): part of: draw

- "Scrap  Cans  Bottles"  (text, line 48)

## lc_rscanner.lua (lc_rscanner.lua)

`gamemodes/livingcity/entities/entities/lc_rscanner.lua`

- "Linked scanner"  (name, line 8)

> Note for you (not shown in game): it winks out: a pop of energy and a spark, and nothing left behind. No debris and no scrap, so nobody risks their neck for parts that aren't there (it was put up from a console, and could be put up again and again)

- "The scanner was destroyed; the link drops."  (text, line 49)

## lc_scientist.lua (lc_scientist.lua)

`gamemodes/livingcity/entities/entities/lc_scientist.lua`

- "Resistance scientist"  (name, line 12)

## lc_screen.lua (lc_screen.lua)

`gamemodes/livingcity/entities/entities/lc_screen.lua`

- "City screen"  (name, line 10)

## lc_stall.lua (lc_stall.lua)

`gamemodes/livingcity/entities/entities/lc_stall.lua`

- "Market stall"  (name, line 10)

> Note for you (not shown in game): the sign: whose stall it is

- "Licensed by the CWU. Press E"  (drawn on screen, line 41)

## lc_supply.lua (lc_supply.lua)

`gamemodes/livingcity/entities/entities/lc_supply.lua`

- "Union supply crate"  (name, line 9)

## lc_terminal.lua (lc_terminal.lua)

`gamemodes/livingcity/entities/entities/lc_terminal.lua`

- "Union Commissary terminal"  (name, line 7)

> Note for you (not shown in game): part of: use

- "The screen's dark due to the blackout."  (chat message, line 30)

## lc_vending.lua (lc_vending.lua)

`gamemodes/livingcity/entities/entities/lc_vending.lua`

- "Water vending machine"  (name, line 7)

> Note for you (not shown in game): part of: use

- "Vending machines can't process credits or dispense during a blackout."  (chat message, line 30)

## lc_workbench.lua (lc_workbench.lua)

`gamemodes/livingcity/entities/entities/lc_workbench.lua`

- "Resistance lab"  (name, line 17)

## weapon_lc_baton.lua (weapon_lc_baton.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_baton.lua`

- "Arrest Baton"  (name, line 10)

> Note for you (not shown in game): part of: tell

- "[Living City] {msg}"  (chat message, line 47)

> Note for you (not shown in game): part of: secondary attack

- "You can't arrest another Civil Protection unit."  (chat message, line 88)
- "Arrested by {Nick}"  (text, line 89)
- "is in custody."  (text, line 90)
- "Couldn't arrest: {err}"  (text, line 90)
- "Citizen detained. They're taken to a cell."  (chat message, line 93)
- "Couldn't arrest: {err}"  (text, line 93)

## weapon_lc_blessing.lua (weapon_lc_blessing.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_blessing.lua`

- "The Blessing"  (name, line 14)

> Note for you (not shown in game): part of: heal

- "tending the wounded"  (text, line 66)

> Note for you (not shown in game): part of: primary attack

- "[Blessing] The infected are beyond your help."  (chat message, line 85)
- "[Blessing] Father Grigori lays a hand on your head and blesses you; You feel stronger."  (chat message, line 91)

> Note for you (not shown in game): part of: secondary attack

- "[Blessing] Your prayer comforts {healed} soul(s)."  (text, line 107)
- "[Blessing] You pray alone."  (chat message, line 107)

> Note for you (not shown in game): they stop and listen for a moment

- "Unlawful preaching"  (text, line 130)

## weapon_lc_hoover.lua (weapon_lc_hoover.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_hoover.lua`


> Note for you (not shown in game): part of: primary attack

- "It's still alive: spray it with weedkiller first (look at it, E)."  (chat message, line 63)

> Note for you (not shown in game): part of: draw hud

- "Hoover: %d of %d"  (message, line 145)

## weapon_lc_microphone.lua (weapon_lc_microphone.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_microphone.lua`


> Note for you (not shown in game): part of: holster

- "off air"  (text, line 45)

> Note for you (not shown in game): part of: draw hud

- "ON AIR  %ds   Hold your voice key and speak (or type). Left click to stop."  (message, line 55)
- "MICROPHONE: the transmitter is cooling down (%d:%02d)"  (message, line 58)
- "MICROPHONE: left click to go live over every loudspeaker and screen"  (text, line 59)

## weapon_lc_multitool.lua (weapon_lc_multitool.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_multitool.lua`


> Note for you (not shown in game): What the tool would do with whatever you're pointing at (shared, for the HUD and the click).

- "Hijack the city screen"  (text, line 43)
- "Download the Combine's data"  (text, line 44)

> Note for you (not shown in game): part of: job

- "Download the master terminal (the motherlode)"  (text, line 45)
- "Hack the vending machine (free water)"  (text, line 46)
- "Hack the ration dispenser (free rations)"  (text, line 47)
- "Sabotage the transformer (causes a district-wide blackout)"  (text, line 48)
- "Short out the power bank (connected turrets and forcefields will be powered off)"  (text, line 50)
- "Short out the forcefield"  (text, line 53)
- "Hack the Combine lock"  (text, line 55)
- "Unlock the vortigaunt's shackles"  (text, line 56)
- "Download the master terminal (the motherlode)"  (text, line 61)
- "Download the Combine's data"  (text, line 61)

> Note for you (not shown in game): part of: primary attack

- "Nothing here the multitool can work on. (Try: Combine doors, city screens, data terminals, shackled vortigaunts, transformers, forcefields, power banks, vending machines, and ration dispensers.)"  (text, line 89)

> Note for you (not shown in game): part of: draw hud

- "MULTITOOL: point at electronics to hack them"  (text, line 101)

## weapon_lc_radio.lua (weapon_lc_radio.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_radio.lua`

- "Radio transmitter"  (name, line 17)
- "the CP net"  (text, line 37)

> Note for you (not shown in game): part of: secondary attack

- "[Radio] Now transmitting on {or}."  (chat message, line 58)

> Note for you (not shown in game): part of: draw hud

- "your radio"  (text, line 168)
- "TRANSMITTER UP: what you type and say goes out on {band}"  (text, line 170)
- "Only someone right beside you hears you directly. R puts it away.{or}"  (text, line 171)

## Infestation Cleanup and the Groundskeeper) (weapon_lc_sprayer.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_sprayer.lua`

- "Weedkiller sprayer"  (name, line 13)

> Note for you (not shown in game): part of: primary attack

- "Your sprayer's empty: you need weedkiller (the Union Commissary sells it)."  (chat message, line 78)

## weapon_lc_vort.lua (weapon_lc_vort.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_vort.lua`


> Note for you (not shown in game): part of: primary attack

- "The collar suppresses your vortessence."  (chat message, line 51)

> Note for you (not shown in game): part of: secondary attack

- "The collar suppresses your vortessence."  (chat message, line 81)
- "Your vortessence is gathering (%ds)."  (message, line 84)
- "There is nothing left to charge."  (chat message, line 97)

> Note for you (not shown in game): the vortessence charges a vest (sv_livingcity_vest.lua); it doesn't knit flesh

- "You wear nothing for the vortessence to charge."  (chat message, line 100)
- "They wear no vest for the vortessence to charge."  (chat message, line 100)
- "Your vest is fully charged."  (chat message, line 102)
- "Their vest is fully charged."  (chat message, line 102)

> Note for you (not shown in game): part of: secondary attack

- "The vortigaunt's hands glow green, the cells hum, and your vest feels warm."  (chat message, line 107)
- "charging with vortessence"  (text, line 108)

## cl_init.lua (cl_init.lua)

`gamemodes/livingcity/gamemode/cl_init.lua`

- "F1: the quick menu"  (text, line 29)
- "Union work: Sanitation street sweep (push a cart, throw rubbish in), the Factory line (sort out rust-red parts), Intake Processor's papers check (review arrival's paperwork; approve, deny, or call CP Units to arrest)."  (text, line 30)
- "More: Maintenance rewires circuit boards (redirect a current; don't get shocked), Clinic Medics triage injured patients, Reclamation Crew breaks up rubble with a crowbar."  (text, line 31)
- "More (2): Couriers run parcels against the clock, Mortuary processes the dead, Laundry sorts uniforms, Records Clerks file forms and catch mismatches, Radio Repair fixes a radio by ear (and sometimes finds Freq 7.)"  (text, line 32)
- "Some of the city's rarer moments have flashing lights and strobes: a warning is displayed with an opt-out, and lc_ending_calm 1 in the console stops the flashing for you."  (text, line 33)
- "Got a radio? Open your pockets (F2) and press Listen on it. Turn the dial: 96.4 is the city's own station, and somewhere in the static is Freq 7, the Resistance's secret one. It plays out loud, so people near you hear it too, Civil Protection units included."  (text, line 34)
- "Want to talk over the radio? A radio only listens. Units have a transmitter on the CP net; for Freq 7 you need a Freq 7 radio and a radio transmitter (contraband, from the black market or the Resistance lab). Then switch to the Radio transmitter (next to your Hands, like a weapon). While it's up, what you type and say goes out on your radio's band instead of to the people around you. Only someone standing right beside you hears it. Press R, or switch to your hands or a gun, to put it away."  (text, line 35)
- "Freq 7 isn't one fixed frequency: the Resistance only broadcast on frequencies whose digits add up to seven. When the Combine find the current one they jam it, and the broadcast moves to another. A Resistance radio follows it automatically."  (text, line 36)
- "At the Radio Repair bench, if you pick up Freq 7 you can choose Write it down: you get a Freq 7 sheet listing all seven frequencies, to read or give to someone. The sheet is contraband."  (text, line 37)
- "Resistance operations: Doctor the records means getting into a terminal (stop the needle inside the marked band, and don't touch the panel while the scanner sweeps past). A dead drop means hiding a message without anyone seeing you. Civil Protection units pat citizens down one pocket at a time, and break down doors in housing block raids. If you close one of these minigame windows by accident, press E on the thing you were working on to bring it back."  (text, line 38)
- "Lost? {gm_showhelp} > What now? always shows your next step and how to get there. What now? > Places marks useful spots on your screen (the ration dispenser, water, your housing block, your workplace)."  (text, line 39)
- "F2: your pockets (and your stash at home)        F3: your job board (jobs, stories, Union employment)        F4: factions"  (text, line 40)
- "C (when not in build mode): the full menu. Everything you can do, with this guide, your pockets, job board, factions and tips at the top."  (text, line 41)
- "E on a person: talk to citizens, or report to Civil Protection units. E on an object: pick it up or use it."  (text, line 42)
- "Everything you can do is in the menus (Civil Protection units: C > Unit tools). Chat commands like !backup still work, but you never need them."  (text, line 43)
- "Warnings and announcements appear on screen as well as in chat: people talking to you appear as subtitles, everything else as cards at the top. C > Settings turns the cards off."  (text, line 44)
- "Death, and close calls"  (text, line 46)
- "Each character has three close calls. When you die, you use one up: you wake in the infirmary with your pockets emptied, and your character doesn't remember the fight, so don't go after whoever did it."  (text, line 47)
- "A used close call comes back after a few hours of playing that character. If you die with no close calls left, that character is gone for good. !characters shows how many close calls you have left."  (text, line 48)
- "When a character is gone for good, you come back as someone new, with a new name and citizen number, and only a little inherited from the old one."  (text, line 49)
- "Some things are permanent for a character: the Overwatch conditioning, and being made a stalker. To be someone else, play another character or retire this one (!characters)."  (text, line 50)
- "The Union taxes hoarded credits: every half hour it takes a tenth of whatever you hold above 2000 credits. Spend them."  (text, line 51)
- "When a character is gone for good, the screen goes dark and a card shows who they were: how long they lived, how many people knew their name, and what killed them."  (text, line 52)
- "People who knew their name hear about the death a minute or two later (or the next time they're in the city)."  (text, line 53)
- "Arriving: Civil Intake"  (text, line 55)
- "In a city with Civil Intake, new characters arrive with nothing: no papers, no room, no ration card."  (text, line 56)
- "Go to Civil Intake (the marker on your screen) and press E on the terminal to open the registration screen. Enter your name, your face and a description strangers will see, submit it, and stay next to the terminal while it processes you. Your identity papers go in your pockets (F2), and the screen sends you on to Housing Allocation."  (text, line 57)
- "Terminals (Civil Intake, Housing Allocation, the Civil Protection Commissary) show their menu on a screen in front of them: aim your crosshair at a button and press E. Prefer a window? C > Settings > Terminals' menus."  (text, line 58)
- "Next, Housing Allocation: press E to open the housing register. Present your papers and apply for a block. Any block is approved at once and gives you the least crowded one; asking for a crowded block needs Civil Standing 50. Your way home is then marked on screen."  (text, line 59)
- "Already housed? The same screen shows where you live and how you got it, marks your way home, and takes transfer requests (needs Civil Standing 25; once every half hour)."  (text, line 60)
- "Your identity papers are kept in your pockets (F2). Civil Protection units ask to see them (having none costs a little Civil Standing). Lost them? Civil Intake replaces them for 10 credits."  (text, line 61)
- "Ration cards are earned, not handed out: each Union shift you finish gives you one, and each ration at a dispenser takes one. No work, no rations. Rations don't come with credits."  (text, line 62)
- "To show your papers, look at someone and choose F1 > Show them my papers (or F2 > Identity papers > Show). They see your card and learn your name."  (text, line 63)
- "Until you're registered: no rations (unless you have a forged ration card), no Union job, no Commissary, and Civil Protection units will ask for your papers. Stay unregistered too long and it becomes a crime."  (text, line 64)
- "Each desk serves one person at a time, and new arrivals from the train queue too. F1 > My papers shows where you are in the process."  (text, line 65)
- "How the city looks and feels"  (text, line 67)
- "Your eye level is a little lower than other characters', and your field of view is no wider than in Half-Life 2, so the city feels big around you."  (text, line 68)
- "The camera sways a little as you walk and dips when you land. C > Settings > Camera sway turns it off, just for you."  (text, line 69)
- "There's no score on screen: your credits and Civil Standing are at the top of your pockets (F2), and your rank and progress are on F4."  (text, line 70)
- "Hunger and thirst appear at the top left once they get low, and briefly after you eat or drink."  (text, line 71)
- "Staying alive"  (text, line 73)
- "Eat and drink. Ration dispensers and the ration line give you food; the Commissary (a terminal, or C > Getting by) sells everything else."  (text, line 74)
- "Walk into water and press E to drink, but boil it first if you can (on a stove or fire, from F2). To use a sink, stand close and look right at it, with nothing in the way."  (text, line 75)
- "Parasites (coughing, hunger, thirst) never go away on their own: antiparasitic tablets from a medic or the black market cure them."  (text, line 76)
- "Parasites also mean you'll need the toilet (press E on one). Ignore it and you soil yourself: then you need a toilet, a wash (bathtub or shower) and clean clothes, or people back away from the smell."  (text, line 77)
- "Sleep once a day: press E on a bed at night. Without sleep you get drowsy, can't run and are weaker. A good night's sleep leaves you well rested."  (text, line 78)
- "You can kill birds with your fists. Cook them before you eat them."  (text, line 79)
- "Staying out of trouble"  (text, line 81)
- "Don't crowd Civil Protection units. They warn you first, then hit you with the stunstick."  (text, line 82)
- "When a Civil Protection unit stops you, stand still. They may search you and find anything illegal in your pockets."  (text, line 83)
- "Crouch to sneak: a Civil Protection unit only spots you from half the usual distance, even less if you move slowly or stay in the dark, and never from behind. While crouching, a bar shows how visible you are, and each unit's line of sight is drawn in front of him (red means he can see you)."  (text, line 84)
- "Wanted but haven't hurt anyone? Units chase you down and cuff you. They shoot at violent suspects, and at anyone with a gun in their hand."  (text, line 85)
- "Sleeping in a bed, you lie still and heal; press Jump to get up. Rations being handed out during your shift? C menu > Take a ration break: your job waits for you."  (text, line 86)
- "Resistance: with fighters following you, C menu > Resistance > Squad tells them to act casual (plain clothes, guns away), get their guns out, or meet you at the job's marker. In a camp, hold E on a mattress, crate or chair to move it (let go to put it down, R rotates it). At your stash, Stash it puts away the weapon you're holding."  (text, line 87)
- "Everyone works: the Union gives a registered citizen a job if they don't have one (ask for a different one on F3 > Jobs). Being idle gets noticed."  (text, line 88)
- "Curfew: you get one minute to reach your housing block (a fresh minute each time you respawn during curfew). A travel permit gets you past one curfew stop."  (text, line 89)
- "Morning exercise (every second dawn; citizens must attend): go where the arrow on your HUD points. The jog: keep jogging and keep up with the pace marker, or the Civil Protection units along the route hit you with the stunstick (which makes you faster for a few seconds). The drill: stay on your ring and copy every move (crouch, jump, turn around, step), and jump on every beat when the rope comes out. The parade: cheer the column as it marches past (/cheer, /salute, chant in chat, jump) and keep your enthusiasm bar up. Skipping it costs Civil Standing and your next ration (a reprimand on screen); doing it well earns some, and a few credits, plus breakfast if your standing is Trusted or better."  (text, line 90)
- "Full stomach (hunger 85 or more): 15% more XP from jobs and shifts."  (text, line 91)
- "Top left: your credits and Civil Standing, and under them your loyalty, sympathy and corruption (what your choices in jobs and stories have made of you; they open up choices later)."  (text, line 92)
- "Combine-only areas (the Nexus, offices, armory, prison) are off limits. The doors near the cells are locked."  (text, line 93)
- "Raids: Civil Protection units search a housing block, and any contraband they find (guns, TVs, radios...) is traced back to whoever owned it."  (text, line 94)
- "When you're wanted, every Civil Protection unit nearby comes after you. If they catch you, you're arrested."  (text, line 95)
- "Kill Civil Protection units and the response escalates: armed units, then Overwatch squads. Stay out of sight to let it calm down."  (text, line 96)
- "One accidental kill gets a light response; a second one soon after gets the full response. Resistance members lose a rank for every civilian they kill."  (text, line 97)
- "To surrender, walk up to a Civil Protection unit and press E. You'll be treated more leniently."  (text, line 98)
- "Marked as an anticitizen? Do community service from your job board (F3), or serve your sentence."  (text, line 99)
- "Getting by"  (text, line 101)
- "Take a Union job from your job board (F3) and work shifts to earn credits, Civil Standing and a ration card for each shift."  (text, line 102)
- "Your Civil Standing decides what the Commissary will sell you. Crimes lower it."  (text, line 103)
- "Rebel territory has a black market (C > Getting by > Black market). To talk on a radio: C > Talk > On my radio."  (text, line 104)
- "Press E on a dead body to search it. Dead Civil Protection units carry ammunition, and sometimes a keycard."  (text, line 105)
- "To carry a body, look at it and choose F1 > Haul the body (Morticians just press E). Let go of it next to the incinerator and it goes in; attendants are paid for each one."  (text, line 106)
- "Press E on a citizen to talk: hear the news, share food, pick their pocket (uses Guile), or inform on them. They remember how you treat them."  (text, line 107)
- "The Resistance (Member rank and up) can ask a sympathizer to keep watch: they warn everyone on Freq 7 when Civil Protection units approach."  (text, line 108)
- "The city runs on a daily schedule: work in the morning, ration lines at midday, quiet evenings, and nearly empty streets at night (only the night shift works)."  (text, line 109)
- "Trains arrive at the station now and then, bringing new arrivals with suitcases. Anyone leaving the city boards before it departs."  (text, line 110)
- "If a Civil Protection unit arrests you, you're cuffed and two units walk you to the cells. On the way, anyone can free you: take down the unit in front, then you can use {gm_showhelp} > Work at the cuffs."  (text, line 111)
- "Rations come from the city's stores (shown under the clock). Kitchen and factory work refills them; when the stores run low, rations shrink too and people get restless."  (text, line 112)
- "Each transformer powers its district: lights (including the map's switchable ones), screens and TVs, ration dispensers, vending machines, the Commissary and Combine door locks. Sabotage one (with a multitool) to cause a district-wide blackout and unlock its Combine doors, until Maintenance repairs it. Prison doors stay locked."  (text, line 113)
- "If half the transformers are down at once, the whole city blacks out, the map's own lighting included: turn on your flashlight (F)."  (text, line 114)
- "Checkpoints: a glowing Combine power bank powers the turrets and forcefields cabled to it. A powered turret can be knocked over. Turrets shoot the infected, wanted people and known rebels. Cut the bank's power (with a multitool, or a blackout) and they all shut off; if the checkpoint is next to the infestation, that causes a containment breach."  (text, line 115)
- "The infestation: yellow-stained, scorched ground, a thick yellow haze, and a geiger counter that clicks faster the deeper you go."  (text, line 116)
- "Union job behind Combine doors? While you're on the job, open the actions menu > Getting by > Ask for a Civil Protection escort. With your escort close by, press E on Combine doors to open them. If someone slips in behind you, the unit goes after them; let it happen twice and nobody will escort you for a while. When the job's done, they walk you out to the release point."  (text, line 117)
- "Combine forcefields: Civil Protection units walk straight through. Swiping a keycard (E) opens one briefly; a multitool shorts it out."  (text, line 118)
- "Letters: open a note in your pockets and choose Send as a letter while at the post office. A courier delivers it to the recipient's housing block. Civil Protection units can read mail while it waits there."  (text, line 119)
- "The city's NPCs work Union jobs too: fixing lights and loudspeakers, scrubbing graffiti, hauling bodies, carrying crates and mail. Look at someone to see what they're doing. Broken things are left for a while first, so players get the first chance to fix them."  (text, line 120)
- "Down and bleeding? A Union medic may come running to help, as long as you're not wanted and there's no firefight."  (text, line 121)
- "The war for the city"  (text, line 123)
- "Rebel territory and the infestation spread if nobody fights them (across a floor, or down the stairs to the next floor), and shrink when people fight them."  (text, line 124)
- "A message appears on screen when you enter either one. C > The city > Who holds the city (or F4) shows how much each side controls."  (text, line 125)
- "When unrest is high (the Resistance is strong): more inspections and raids, and ration cuts. At full compliance, the rebels go quiet."  (text, line 126)
- "Civil Protection units: F1, then 1 (Call for backup) brings the nearest units running; 2 (Send my 10-20) marks your location for other units."  (text, line 127)
- "Resistance: the quartermaster in rebel territory sells gear. Members and up can press E on fighters to have them follow you."  (text, line 128)
- "Fighters following you stick with you above all else. They hold fire until you or the Combine start shooting, then shoot while on the move."  (text, line 129)
- "Rebels fight as guerrillas: they let a Civil Protection unit get close before shouting, and out in the city they stay out of sight. Units who see an armed rebel in the street open fire."  (text, line 130)
- "In their base, rebels keep busy: patrols, the lab bench, crates, the garden, the fire, sleep. Now and then one or two leave to scavenge and bring supplies back."  (text, line 131)
- "Every rebel base needs a lab. Its scientist makes guns, ammunition, armour, jammers, bypass charges, smoke bombs and Freq 7 radios, for the Resistance only. Bring the materials and it's free, or pay him (60% of the black market dealer's price). F1 > Resistance > Find the lab marks it on your screen."  (text, line 132)
- "Everyone else buys guns, ammunition and jammers at the black market. If a Civil Protection unit finds the scientist, the lab shuts down for ten minutes."  (text, line 133)
- "Citizens pick up rumours. Talk to them (E) now and then."  (text, line 134)
- "Ways for the Resistance to make money: write notes on what you see near a checkpoint or a unit (F1 > Resistance, needs paper) and sell them to the quartermaster; steal good parts off the factory line (R while holding one); or have the lab make forged ration cards (but if too many turn up, the camp gets swept)."  (text, line 135)
- "Rebel zones that touch count as one camp: one quartermaster, one supply crate. He buys food back for 2 credits at most (food from his crate is free)."  (text, line 136)
- "A role (Hacker, Father Grigori...) is added on top of your rank: you're still a Fighter working toward Lieutenant, but you carry the role's kit. To give up the role, join the faction again in F4."  (text, line 137)
- "Getting by, and making things"  (text, line 139)
- "Near Resistance activity when the PA announces that ration units are being deducted? You lose your next ration; the dispenser tells you why."  (text, line 140)
- "Press E on bins, dumpsters and fridges to search them: scrap, rags, chemicals, tins, seeds, sometimes gun parts."  (text, line 141)
- "Fishing line (from the Commissary): stand in the canal or look at it, choose Fish in F2 (or C > Getting by), and keep still. Cook what you catch."  (text, line 142)
- "Rebel territory has plant pots (plant seeds, harvest vegetables) and a supply crate the Resistance eat from. C > Resistance > Donate food adds to it."  (text, line 143)
- "F2 > Make: craft bandages and lockpicks by hand, anywhere. Everything else is made by the Resistance lab or sold on the black market."  (text, line 144)
- "Hold a crowbar, look straight at a piece of junk (a wrecked car, a radiator, pipes, a crate) and press E to pry out scrap, rags and chemicals. It's loud: the nearest Civil Protection unit comes to check."  (text, line 145)
- "A crowbar counts as a weapon: if a Civil Protection unit sees one in your hand, you become wanted. Keep it put away on the street."  (text, line 146)
- "Rebels guard their territory: break their crates and they warn you twice, then shove you, then attack you. Leave their supplies alone."  (text, line 147)
- "Shoot down one of the city's scanners and it breaks apart into scrap. A scanner with a glowing red eye is being flown by a player: it drops nothing."  (text, line 148)
- "Supply drops: a Combine convoy unloads a crate on the street. A soldier guards it (he warns you off twice), and two metrocops carry boxes away down the street and back: sneak in while they're away. Press E on the crate to take a load (gun parts, ammo, medicine) quietly, as long as no unit sees you doing it."  (text, line 149)
- "Your vest (VEST on your HUD) is only charged by charge cells (made by the lab; dropped by dead units and downed scanners), batteries and chargers, or a freed vortigaunt (ask it with E). Sleeping doesn't charge it."  (text, line 150)
- "The lab's scientist can give you a new face (300 credits): nobody is looking for it, your wanted status and BOLOs are gone, and your old Civil Standing doesn't carry over."  (text, line 151)
- "Wanted, and out of every unit's sight for half a minute? They've lost you: only a unit that actually sees you will come after you."  (text, line 152)
- "A radio jammer (from the lab or the black market) blocks Civil Protection radios, request devices and scanner reports nearby for four minutes. Units destroy them with E."  (text, line 153)
- "Citizens' Assignments include Union work orders (streetlights, rubble, pipes) that pay in scrap, rags and chemicals."  (text, line 154)
- "Union reclamation points buy scrap, cans and bottles for credits and a little Civil Standing."  (text, line 155)
- "Homemade guns and ammo sell at the black market, and for more at the quartermaster. The risky part is getting them there."  (text, line 156)
- "F2 > Give hands an item to whoever you're looking at. With a lockpick, a prisoner can pick their cell lock."  (text, line 157)
- "In a cell with a Combine console? Press E on it to fly a city scanner while your body stays in the cell. Taking a flash photo of a Civil Protection unit adds a minute to your sentence. Photographing rebels, free vortigaunts, wanted people or zombies from about ten feet away earns Civil Standing (never time off your sentence) and marks them for every unit. Scanners can't see into or through smoke."  (text, line 158)
- "Spray cans paint the lambda symbol on walls. Civil Protection units and loyal citizens scrub tags off with E."  (text, line 159)
- "Civil Protection units: smoke, flashbang and gas grenades unlock as you rank up. The Grenades weapon throws them; R switches type."  (text, line 160)
- "Resistance: you respawn in plain clothes. C > Resistance > Gear up puts your Resistance gear on; Change into plain clothes takes it off again."  (text, line 163)
- "In plain clothes nobody looks twice at you, unless a Civil Protection unit sees a gun in your hand."  (text, line 164)
- "You can take clothes from the dead (citizen clothes, CP uniforms, Resistance gear) and find them in bins. Wear them from F2."  (text, line 165)
- "A CP uniform fools Civil Protection units on the street, for a while. Resistance gear makes rebel fighters think you're one of them, and makes units shoot at you."  (text, line 166)
- "Never change clothes in front of a Civil Protection unit."  (text, line 167)
- "Carrying and keeping things"  (text, line 169)
- "What you can carry is limited by weight and size. A satchel lets you carry more."  (text, line 170)
- "While looking at a bin, open F2 to hide items in it. Anyone can find them."  (text, line 171)
- "Lockers (E): put something in one and that locker becomes yours. A storage crate bought from the Commissary is placed from F2."  (text, line 172)
- "Civil Protection units can open any locker or crate and take anything illegal."  (text, line 173)
- "Homes, trade and writing"  (text, line 175)
- "Apartments: look at a door to see who owns it, or whether it's for rent. With your hands out, right click a free door to rent it (you'll be asked yes or no), and right click your own door to lock or unlock it. Or use C > This door, and C > Home for keys, locking and giving it up."  (text, line 176)
- "With a CWU business license you can place a market stall and sell from it. Customers press E on it to buy."  (text, line 177)
- "Paper: Write from F2. Leave it as a note, put it up on a wall as a poster, or keep it. Press E on one to read it."  (text, line 178)
- "The city's laws are in C > The city > The city's laws. The Administrator speaks to everyone from C > The city > Broadcast."  (text, line 179)
- "Characters and acts"  (text, line 181)
- "C > Me > My characters: all your characters in the city. Switch between them, or create a new one."  (text, line 182)
- "C > Me > Pose: sit, kneel, lie down, lean, cower, or one of four standing poses. Move (or choose Stand up) to get up."  (text, line 183)
- "C > Me > Gesture: wave, salute, bow, nod, shake, point, beckon, halt, cheer, laugh. C > Me > Put my hands up."  (text, line 184)
- "Vortigaunts, time and weather"  (text, line 186)
- "Shackled vortigaunts work the Union's shifts; their collar stops them using their vortessence powers."  (text, line 187)
- "A shackled vortigaunt can reach out through the vortessence (C menu), unseen, to tell the Resistance where it is, and has its own story on the board, The Collar. A free vortigaunt has jobs of its own on the Resistance's board: Free your kin, and Read the Combine. Its bolt (left click) shorts out a power bank, forcefield or turret from a distance for 45 seconds. Its right click mends another vortigaunt (a second to gather, then 25 health; once every 10 seconds for each). With two or more free vortigaunts about, they commune now and then: news of a sweep for the Resistance, or a Combine door code on a scrap."  (text, line 188)
- "Loyalty pays: Civil Protection units, and citizens with 200 Civil Standing or more, rent their apartment for free."  (text, line 189)
- "More for the loyal: from Trusted (150 standing), fewer stops, better pay, a Commissary discount and the use of a locker; at Exemplary (400), no searches, two ration cards a shift, waved through once a curfew, a minor slip forgiven once a day, praise from the Administrator, MODEL CITIZEN on your papers. (From 100 standing, the Block Warden job.)"  (text, line 190)
- "Weeds come up through the cracks on open ground and grow into bushes. The Groundskeeper (a Union job) sprays them with weedkiller: look at one and press E. Weedkiller is poison too: F2 > Weedkiller > Poison food or drink, and it looks no different. At the Resistance lab it makes a firebomb: armour doesn't keep out fire, and it burns out Combine machinery. Drop it under a barnacle and the barnacle dies."  (text, line 191)
- "The infestation has growths in it that glow green. Spray them with weedkiller (E) and they die; cleared away, the infestation shrinks. Infestation Cleanup (a Union job) does it for a living, in a respirator, guarded by Civil Protection: spray them dead with the sprayer (hold left click), vacuum them up with the hoover (hold left click), and empty it into an infestation control barrel (E; the last step marks one). Each shift counts double towards joining Civil Protection."  (text, line 192)
- "Below Trusted standing (150) the ration dispensers give a short ration, a third less food: birds and headcrabs make up the rest. Good standing earns the full packet."  (text, line 193)
- "The city keeps shackled vortigaunts sweeping the streets. Resistance (Member and up): look at one up close and unshackle it (C > Resistance, or !unshackle), with no Civil Protection unit watching, and it goes home to rebel ground."  (text, line 194)
- "The Resistance (Member rank and up) can free one (look at it, then C): it takes ten seconds, and nobody must see you. Once free, it can attack (left click) and charge vests (right click), and the Combine hunt it."  (text, line 195)
- "Armour is the charge stored in a powered vest. Civil Protection units have one built into the uniform, rebel ranks come with one, and anyone else needs one from the lab. Vortigaunts can charge it."  (text, line 196)
- "When no player is Father Grigori, he stays in rebel territory: press E on him for a blessing, a sermon, or a few words."  (text, line 197)
- "A full day lasts one real hour. Nights are dark, and curfews are more likely. C > The city shows the time and weather."  (text, line 198)
- "Stand out in the rain to fill an empty bottle or can. lc_music 0 turns off the city's music."  (text, line 199)
- "Need a staff member? Type @ followed by your message."  (text, line 200)
- "Directives and jobs"  (text, line 202)
- "F3 is your job board. Events add their own directives: they're posted two minutes before the event and taken down when it's over."  (text, line 203)
- "Only rations and curfew are announced in advance. Sweeps, raids and supply convoys happen without warning, and a lockdown only happens after violence."  (text, line 204)
- "Several people can take the same job: up to 8 for an event, 6 for containment or retaking ground, 4 for a chase."  (text, line 205)
- "Want to join Civil Protection? You need Civil Standing 100 and some shifts as a Records Clerk first (F3 > Jobs): units come up through the records office."  (text, line 206)
- "A Civil Protection unit who stays inside as the Resistance's spy (the story The Man Inside) gets a menu only they can see: C > Civil Protection > Inside. Tip off Freq 7, lose a record, take supplies for a dead drop, copy the records, or reveal yourself with the codeword, each only where nobody can see or hear you. Get caught, and you're Resistance for good: wanted, with no surrendering."  (text, line 207)
- "When the infestation spreads or the Resistance take ground, a directive to deal with it is posted straight away."  (text, line 208)
- "Civil Protection"  (text, line 210)
- "Civil Protection units: F1 is your quick menu. 1 to 5: Call for backup, Send my 10-20, Issue a BOLO, Voice lines, Kick. 6 to 8: search, cuff or escort whoever you're looking at."  (text, line 211)
- "Units: C > Unit tools lists everything a unit can do, with what each one does. The records terminal holds violations, notes, loyalty points, BOLOs and requests."  (text, line 212)
- "Civil Protection units don't craft: the Civil Protection Commissary issues grenades, ammunition, armour, bandages and your ration (press E on it; once every two minutes). F2 marks the nearest one on your screen."  (text, line 213)
- "Civil Protection units: actions menu > Civil Protection > Deploy a turret here, near a checkpoint's power bank or forcefield (each power bank runs two; press E on a turret to pack it up). Officers can put up power banks."  (text, line 214)
- "Union workers can ask for an escort. Actions menu > Civil Protection > Escort requests to take one (or look at a worker > Escort them). Keep them close, open the doors they need, and walk them out to the release point when they're done."  (text, line 215)
- "F1 > Voice lines has the mask's most used lines (or just say the words in chat); all of them are in Unit tools > Voice lines."  (text, line 216)
- "C opens the full menu (so does 9 on the quick menu): everything you can do right now, based on who you are and what you're looking at, with this guide at the top. No chat commands to remember (though they still work)."  (text, line 217)
- "A special role (Hacker, Father Grigori...) comes back with you when you rejoin, if there's still a free place in it."  (text, line 218)
- "The multitool (the Resistance's two Hackers carry one; the black market sells them; contraband): aim it and left click at a locked Combine door (hacks it open), a city screen (hijacks it), a data terminal (steals its data), a vending machine or ration dispenser (free water or rations), or a shackled vortigaunt (unlocks its shackles and frees it)."  (text, line 219)
- "The Director of Propaganda's microphone: left click to go on air over every loudspeaker and screen (one minute, once every fifteen minutes). A scanner flies down and films whoever holds it, live on every screen; its eye blinks red while it records. Shoot the scanner down to cut the picture. With no player in the job, the Administrator addresses the city herself now and then; kill her on air and her microphone is yours. Take the microphone off someone (hands up or cuffed, actions menu) and broadcasting with it is a pirate broadcast."  (text, line 220)
- "Streetlights and loudspeakers break when shot or worn out: broken lights go dark, and nobody near a broken loudspeaker hears the PA. Maintenance and Radio Repair crews fix them."  (text, line 221)
- "One data terminal gives half a chip (a fragment): hack a second, different terminal and the two fragments make a full data chip. The master terminal is the big prize: one download gives a master data core."  (text, line 222)
- "A data chip: sell it to the black market dealer, take it to the lab and have the scientist Decode it (first on his list; marks every Civil Protection unit for five minutes), or Use it at a terminal to wipe your record."  (text, line 223)
- "Dead soldiers drop their guns with about half a magazine loaded. The rest of their ammunition is on the body: search it."  (text, line 224)
- "Shooting a scanner counts as damaging city property; killing one counts as destroying it. Neither counts as assaulting anyone."  (text, line 225)
- "Ambush the landing: get to the landing zone before the dropship arrives, and attack the soldiers it drops off."  (text, line 226)
- "Someone you're escorting runs when you run, and when there's shooting. If you climb a ladder, they follow you up it."  (text, line 227)
- "Resistance: a small orange lambda over a citizen's head means they're secretly on our side. Members and up can ask them to keep watch (E, then the talk window)."  (text, line 228)
- "Break your people out of the cells, ambush Overwatch landings, free a vortigaunt: you'll find these in Operations (F3)."  (text, line 229)
- "Citizens: look at someone and choose F1 > Inform on them. Civil Protection pays you if it's true. If the Resistance see you do it, they'll know you're a traitor."  (text, line 230)
- "Trusted citizens: actions menu > Getting by > Become a Union foreman. Then open the actions menu on a citizen > Give them a work order. You get a cut of what they're paid for it."  (text, line 231)
- "The worst anticitizens face worse than prison time: interrogation (the interrogator offers 50 social credits if you talk), broken feet (no running), or being made a stalker."  (text, line 232)
- "A stalker works down below, in the Combine areas: see The Stalker's Lot on your job board (F3). Units leave stalkers alone, their papers are stamped STALKER, and they can scream but not speak. The only way out of being a stalker is death. At the end of the stalker's story is a Combine ball energizer you built yourself; stepping into it is a way out, and that character is gone for good."  (text, line 233)
- "Civil Protection is one career path: Record Keeper, Metrocop, Division Leader, then the Overwatch ranks (Prison Guard, Soldier, Elite). The Overwatch ranks need the transhuman conditioning, which the Overwatch Candidate story offers to Division Leaders."  (text, line 234)
- "Not sure what to do? F1 > What now? > Ways to get by lists everything open to you, and what you need for the rest."  (text, line 235)
- "Civil Protection units can kick: G (or F1 > Kick). Doors swing open, locked doors give way on the second kick, and people get knocked back. A Combine Soldier kicks a hinged door off its hinges; an Elite sends it flying and knocks out anyone it hits. Maintenance Technicians rehang fallen doors: E to lift it, carry it to the frame, E again."  (text, line 236)
- "Scanner Operator (Civil Protection, F4): fly a scanner from a Combine console or from the Nexus (F1 > Unit tools). Reports earn XP; any rebel you photograph gets a BOLO."  (text, line 237)
- "When you're released from prison, you get your fists back but not your guns or radio. Civil Protection units get their issued gear back."  (text, line 238)
- "Rebel territory is deadly for units: a REBEL TERRITORY AHEAD warning appears just before you cross into it. Inside, rebels shoot Civil Protection units."  (text, line 239)
- "Supply drop happening? Guard the crate: if anything is left in it when the convoy moves on, every Civil Protection unit nearby gets paid."  (text, line 240)
- "RADIO JAMMED on your HUD means a jammer is nearby. Follow the beeping and press E on it to smash it."  (text, line 241)
- "Civil Protection units: look at someone and choose F1 > Cuff them. Anyone with cuffs: C > their name > Cuff them. You can cuff someone whose hands are up, who is down, who has been stopped, or from behind. Drag walks them along; hitting them with the baton arrests them."  (text, line 242)
- "Sociostability (green, yellow or red) is shown at the top of the screen. Officers set it in C > Unit tools. Red means a judgment waiver: metrocops have their pistols drawn."  (text, line 243)
- "Set off an alarm (with a data chip, or during an escape) and a squad of two metrocops and a soldier comes through the door a few seconds later."  (text, line 244)
- "The Nexus and every Combine-only area are guarded: mostly Overwatch soldiers, plus a metrocop or two."  (text, line 245)
- "Citizens: C > Getting by > Request Civil Protection (needs a request device) calls a Civil Protection unit to you. Use C > Me > Put my hands up when a unit tells you to."  (text, line 246)
- "Cuffed? Use C > Me > Work at the cuffs to get free, when nobody's looking. Anyone can uncuff you."  (text, line 247)
- "The first time you come across something, a card on the right explains what it is and what you can do. Each card only shows once."  (text, line 250)
- "C > Tips I've seen lists every tip you've had, to read again. C > Settings turns tips off or on, or starts them over."  (text, line 251)
- "Talking, and knowing people"  (text, line 253)
- "Chat is spoken out loud: only people nearby hear it. C > Talk lets you yell so people further away hear (/y), or whisper to whoever is right next to you (/w)."  (text, line 254)
- "C > Talk: describe what your character does (/me lights a cigarette), describe the scene (/it), or roll 1 to 100 for everyone nearby to see (/roll)."  (text, line 255)
- "C > Talk > Out of character: talk to the whole server (//, with a cooldown) or only to people nearby (/looc)."  (text, line 256)
- "Voice chat works the same way: people only hear you if they're close enough."  (text, line 257)
- "Strangers don't know your name; they see your description instead. Set it in C > Me > Change how strangers see me ("tall, with a scar over one eye")."  (text, line 258)
- "To tell someone your name, look at them and choose F1 > Tell them my name. F1 > Tell everyone nearby my name tells everyone around you."  (text, line 259)
- "While their mask is on, Civil Protection units are known by their designation, not their name."  (text, line 260)
- "Going down"  (text, line 262)
- "A killing blow puts you on the ground, bleeding out, instead of killing you outright. You can still whisper."  (text, line 263)
- "Someone can press E on you to get you back up: it takes a few seconds bare-handed, and is quicker and better with a bandage."  (text, line 264)
- "If a Civil Protection unit presses E on a downed wanted person, they cuff them where they lie."  (text, line 265)
- "Shooting someone who's down kills them. To drag a downed person, look at them and choose F1 > Drag them along; choose it again to let go."  (text, line 266)
- "C > Me > Give up lets you die if nobody is coming to help. Explosions and the like kill outright."  (text, line 267)

> Note for you (not shown in game): The guide: the full menu's first item (C, cl_livingcity_actions.lua), !help, or the console command lc_help. A list of topics on the left, the topic on the right, and a search box that looks through all of it.

- "C > Help > Build mode (or !build) turns build mode on and off: spawn menu, context menu, physgun, toolgun (Living City Editor) and noclip."  (text, line 275)
- "Civil Intake: place "Fixture: Civil Intake (registration)", "Fixture: Housing Allocation" and "Point: arrival". Settings: lc_intake, lc_intake_secs (8), lc_intake_grace (10 minutes), lc_papers_fee (10), lc_card_fee (15). Commands: lc_register <name>, lc_unregister <name> (sends them back through all of it, room included). With no desk on the map, people are registered and housed automatically as they arrive."  (text, line 276)
- "Civil Protection Commissary (editor fixture): Civil Protection units get grenades, ammunition, armour, bandages and a ration there. lc_cpsupply_cooldown (120), lc_cpsupply_ration (600). If none is placed, the Union Commissary terminal issues them instead."  (text, line 277)
- "Resistance lab (editor fixture, formerly the workbench): a lab bench and a scientist who makes the Resistance's guns. Place one in every rebel base. lc_lab_price (0.6 of the dealer's price), lc_lab_shutdown (600 seconds closed after a Civil Protection unit finds it)."  (text, line 278)
- "How it feels (editor panel, How it feels): lc_fov (75, the widest view anyone gets; 0 leaves it to each player), lc_eye_height (61; GMod's default is 64), lc_view_bob (with lc_view_bob_amount, 100%, for how strong), lc_quiet_hud, lc_respawn_secs (12, how long the death card shows), lc_word_gets_around."  (text, line 279)
- "C > Help > Admin testing tools (or the button on F4, or !admintools): give yourself XP, a rank, credits and Civil Standing, switch faction, or start over."  (text, line 281)
- "Switching faction from F4 changes your uniform and kit on the spot: no need to go back to a spawn point."  (text, line 282)
- "Chat commands: !givexp, !setrank, !givecredits, !givestanding <n> [name]; !resetxp, !resetcredits [name]; !resetme."  (text, line 283)
- "C > Help > Staff panel (or !staff): logs, tickets, warnings, character bans. !warn <name> <reason>, !charban <name> <reason>."  (text, line 284)
- "To black out the whole city for an event: !admintools > The city, or lc_blackout on\|off\|auto."  (text, line 286)
- "Checkpoints in the editor: Combine power bank, Combine turret, Combine barricades. Place one at the edge of the infestation and the infestation stops spreading there, until the checkpoint loses power."  (text, line 287)
- "Cell doors not locking? Tag them in the editor with Door: prison or cell. They stay locked during a blackout, and close themselves if anyone other than a Civil Protection unit opens them."  (text, line 288)
- "Door: always open keeps a door open permanently: it's locked open, and opens again if anything shuts it."  (text, line 289)
- "Your own announcements: put .wav files directly in the server's garrysmod/sound/livingcity/overwatch/ or .../administrator/ folder, named after the trigger (curfew1.wav, ambient2.wav). For the Administrator, the tone goes in the name too (curfew_firm1.wav, curfew_stern1.wav, curfew_furious1.wav; warm has no tone word). Each folder's README lists the triggers. lc_announce_clips lists the files it found (and any the game can't play: an MP3 renamed to .wav is silent, so keep .mp3 files as .mp3; a .wav must be 16-bit 44100 Hz). lc_announce_say <voice> <trigger> [tone] tests one. Each player's own computer plays them, so players get them through FastDL (press FastDL sync after adding one, then change the map). lc_sound_check tests a player's own copy."  (text, line 290)
- "Secret endings (keep them secret): the G-Man stops time and everyone votes: 1 lets the city end, 2 skips it (if nobody votes, it ends). Nobody really dies; the map reloads afterwards. Songs go directly in the server's garrysmod/sound/livingcity/endings/ folder, named after the ending: harpies.mp3, bus.mp3, plane.mp3, standup.mp3, water.mp3, bloom.mp3, marrow.mp3, base.mp3, hard.mp3, shalom.mp3, fire.mp3. Father Grigori eating a master data core (Eat it in his pockets, or /eatchip) starts the flood (if an admin starts it, the city's own Father Grigori takes the stage; lc_ending_flood_crowd sets how many others are up there with him). Commands: lc_endings, lc_ending <id> [now], lc_ending_cancel, lc_ending_reset_cooldown. The Endings menu (C > Help > Endings menu, superadmins only, or lc_endings_menu): adjust any ending live while it plays, including its dances bone by bone (the selected bone lights up on the dancers) and all its settings, then copy what you changed. The Harpies (mingebags): lc_ending_minge_swell is the second the song swells, lc_ending_minge_end when it's all over, lc_ending_minge_max how many there are, lc_ending_minge_crowd how many of the city's people stand in the ring, lc_ending_minge_chatter 0 silences the Combine's radio chatter. Bloom (the dance): lc_ending_bloom_speedup, _ramp, _peak, _bpm; lc_bloom_preview and lc_bloom_pose tune the dance. Marrow (the skeletons): lc_ending_marrow_sections lines it up with the song (seconds:dance\|rave\|attack\|outro\|end). The Bus: lc_ending_bus_sections (seconds:fly\|drive\|fast\|end), lc_ending_bus_bpm. Base: lc_ending_base_sections, lc_ending_base_lines (the subtitles). Hard (party hard): lc_ending_hard_sections, lc_ending_hard_moment_beats (how often another Combine member joins in), lc_ending_hard_moment_max (how many at once). Plane (numa numa): lc_ending_plane_sections, lc_ending_plane_captions. Standup (the rope): lc_ending_standup_sections, lc_ending_standup_drain. The Flood: lc_ending_flood_attack_from (when the ichthyosaurs start biting), lc_ending_flood_boats (rowboats), each player's lc_headbang_angle (Father Grigori's nod). The Plane: lc_ending_plane_model_yaw (if it flies sideways). Marrow: lc_ending_marrow_crowd. Any ending: lc_ending_bodies (bodies left lying), lc_ending_edict_limit (spawning stops near the server's entity limit). Bloom: each player's lc_bloom_palm (-90 if the palms face backwards). Shalom (the hora): lc_ending_shalom_sections, lc_ending_shalom_candles (when each of the hanukkiah's candles is lit), lc_ending_shalom_lift_beats (how often someone is lifted up on a chair), lc_ending_shalom_sayings (extra sayings shown over heads, separated by \|); each player's lc_shalom_pose tunes the dance's arms and lc_shalom_kippah where the kippah sits. Fire (behinds on fire, then flying on them): lc_ending_fire_sections (seconds:ignite\|hop\|fly\|launch\|end), lc_ending_fire_hop (how high the hops are), lc_ending_fire_fly_speed, lc_ending_fire_crowd; the flying pose is tuned in the Endings menu (Pelvis tilts the whole body)."  (text, line 291)
- "Freq 7 (the pirate broadcast): voice lines and songs take turns, and warnings cut in. The Combine jam it every lc_freq7_hold minutes on green (faster on yellow and red, never during a blackout). Recordings go in the sound addon's radio/ folder. lc_freq7_status shows where it is."  (text, line 292)
- "Morning exercise: use the editor to place a jogging route (stops in order; the first is the start), an exercise yard (stand where the rows will be, and aim at the leader's spot) and a parade route (stops in order). Every lc_exercise_every dawns (2), one of them runs, taking turns (lc_exercise_kinds). lc_exercise <jog\|drill\|parade> starts one now, lc_exercise next shows which is next, lc_exercise stop ends it."  (text, line 293)
- "NPCs losing track of you in a chase? Path mapping (editor panel, Paths and doors, or !pathmap) places path nodes as you walk the streets, stairs and alleys, links them and saves them with the map. Noclip pauses it; lc_pathmap_undo removes the nodes placed this session."  (text, line 294)
- "Every setting in the editor panel is saved with the map as soon as you change it, so your values survive a restart."  (text, line 295)
- "Persistent props: spawn a prop, place it, and click it with the editor's Prop: make persistent. It's saved with the layout, frozen, and comes back every time the map loads."  (text, line 296)
- "Rebel lookout post (editor point): an armed fighter guards that spot. Place it from the side the Combine would come from, so he faces that way."  (text, line 297)
- "Bunk (editor point): a bed rebels sleep on. Mattresses, beds, couches, chairs, workbenches and crates inside rebel territory are found automatically."  (text, line 298)
- "Tag the Combine's doors with Door: Civil Protection only and Civil Protection units are routed through them, even where the map's navigation was cut off by the door."  (text, line 300)
- "The Living City Editor places everything: street furniture (bins, streetlights, loudspeakers, big screens, TVs), an incinerator for bodies, and a workplace for each Union job, plus loading docks, graffiti walls, rubble piles and leaky pipes for the jobs that use them."  (text, line 301)

> Note for you (not shown in game): part of: paint

- "C > Guide opens this guide. Tips also pop up the first time something happens (C > Tips I've seen lists them all)."  (drawn on screen, line 323)

> Note for you (not shown in game): part of: open guide

- "Search the guide"  (text, line 328)

> Note for you (not shown in game): part of: show search

- "Nothing found for "{q}". Try a single word: cuffs, rent, curfew, fish..."  (text, line 370)

## init.lua (init.lua)

`gamemodes/livingcity/gamemode/init.lua`


> Note for you (not shown in game): Build mode

- "[Living City] Build mode ON: spawn menu (Q), context menu (C), physgun, toolgun and noclip. The Living City Editor is under Q > Tools > Living City. Type !build again to go back to playing."  (chat message, line 122)

> Note for you (not shown in game): part of: lcset build

- "[Living City] Build mode OFF. You're just a person in the city now."  (chat message, line 127)

> Note for you (not shown in game): typing in chat

- "[Living City] Build mode is for admins."  (chat message, line 149)

> Note for you (not shown in game): Arriving

- "[Living City] Welcome to the city. F1: what you can do (and the guide). F2 pockets, F3 your board, F4 factions."  (chat message, line 166)
- "[Living City] You're an admin: !build switches to build mode for the editor, physgun and noclip."  (chat message, line 168)

## cl_livingcity.lua (cl_livingcity.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity.lua`


> Note for you (not shown in game): part of: block name

- "Habitation Block %02d"  (text, line 148)

> Note for you (not shown in game): part of: draw aim info

- "%s   \|   radius %d Civil Protection units (about %.1f m across)   \|   right click removes"  (message, line 618)
- "\|   right click removes"  (text, line 624)
- "PATH NODE %d   \|   %d links   \|   right click removes"  (message, line 627)

> Note for you (not shown in game): persistent props (sv_livingcity_props.lua)

- ": {GetNW2String}"  (text, line 678)

> Note for you (not shown in game): part of: play next voice

- "(the loudspeaker here is broken)"  (text, line 738)

> Note for you (not shown in game): on screen

- "Cuffed and kneeling. Wait it out."  (drawn on screen, line 846)
- "ESCORT CALLED AWAY: stay put, another Civil Protection unit is coming (%ds)"  (message, line 882)
- "Spawn protection %ds"  (message, line 891)
- "Ration distribution"  (text, line 899)
- "Civil status inspections"  (text, line 899)
- "Housing block inspection"  (text, line 899)
- "Supply convoy unloading"  (text, line 899)

> Note for you (not shown in game): units and Overwatch don't go home for curfew: they enforce it

- "Grace period: %ds to get home."  (message, line 909)

> Note for you (not shown in game): on screen

- "You are home. Stay inside."  (text, line 912)
- "Report to {block}."  (text, line 912)

> Note for you (not shown in game): Debug report viewer

- "[Living City]"  (chat message, line 934)
- "Debug report copied to your clipboard. Paste it to Claude. Also saved to {file}"  (chat message, line 934)
- "Living City debug report"  (window title, line 937)

> Note for you (not shown in game): the game answering something done in a window (lc_report)

- "Copy to clipboard again"  (label or button, line 950)

> Note for you (not shown in game): Path mapping (sv_livingcity_pathmap.lua): say so on screen while it's on

- "PATH MAPPING: walk to lay nodes"  (text, line 982)

## cl_livingcity_actions.lua (cl_livingcity_actions.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_actions.lua`


> Note for you (not shown in game): part of: open actions

- "Places in the city (show me the way)"  (text, line 101)

> Note for you (not shown in game): someone who's down (sv_livingcity_rp.lua)

- "Someone who's down"  (text, line 141)

> Note for you (not shown in game): a body

- "This body"  (text, line 149)

> Note for you (not shown in game): the thing in front of you

- "This door"  (text, line 157)

> Note for you (not shown in game): the power grid and forcefields (sv_livingcity_power.lua)

- "This transformer"  (text, line 165)

> Note for you (not shown in game): checkpoints (sv_livingcity_checkpoints.lua)

- "This power bank"  (text, line 177)

> Note for you (not shown in game): part of: open actions

- "This forcefield"  (text, line 192)

> Note for you (not shown in game): add

- "How strangers see you"  (text, line 232)
- "Describe yourself (8 to 120 characters), e.g. tall, grey coat, a scar over one eye"  (text, line 232)

> Note for you (not shown in game): talking (the same as the chat prefixes)

- "What do you yell?"  (chat message, line 240)
- "What do you whisper?"  (chat message, line 241)
- "An action"  (chat message, line 242)
- "What do you do? (e.g. leans against the wall)"  (chat message, line 242)
- "The scene"  (chat message, line 243)
- "What happens? (e.g. A siren starts up somewhere.)"  (chat message, line 243)

> Note for you (not shown in game): add

- "Out of character"  (chat message, line 245)
- "Said out of character, to people nearby"  (chat message, line 245)
- "Out of character"  (chat message, line 246)
- "Said out of character, to the whole server"  (chat message, line 246)
- "What do you say on the radio?"  (text, line 247)

> Note for you (not shown in game): getting by

- "Getting by"  (text, line 250)

> Note for you (not shown in game): add

- "What's wrong?"  (text, line 258)
- "Take a key back"  (text, line 281)
- "Whose key? (their name)"  (text, line 281)
- "Give up your apartment? Your rent isn't refunded."  (text, line 283)
- "Give up the apartment"  (text, line 283)
- "Give it up"  (text, line 283)
- "Keep it"  (text, line 283)

> Note for you (not shown in game): the city

- "The city"  (text, line 287)
- "What does the city hear?"  (text, line 293)

> Note for you (not shown in game): Civil Protection

- "Civil Protection"  (text, line 298)

> Note for you (not shown in game): add

- "What should Civil Protection units look out for?"  (text, line 306)

> Note for you (not shown in game): workers waiting for an escort, or left without one, or with an NPC unit a player can take over from

- "Escort requests ({reqs})"  (text, line 317)

> Note for you (not shown in game): the Resistance's man inside (only they see this: sv_livingcity_insider.lua)

- "Inside (only you see this)"  (text, line 325)
- "Tip off Freq 7"  (text, line 326)
- "What do you tell the Resistance? (The next planned sweep, if any, goes with it.)"  (text, line 326)
- "Lose a record"  (text, line 327)
- "Whose record goes missing? (Their name.)"  (text, line 327)

> Note for you (not shown in game): part of: open actions

- "Set sociostability (officers)"  (text, line 334)

> Note for you (not shown in game): settings, just for you

- "Camera sway: on (turn off)"  (text, line 361)
- "Next step on screen: new life and urgent (change)"  (text, line 364)
- "Next step on screen: never (change)"  (text, line 364)

> Note for you (not shown in game): part of: open actions

- "Third person while posing: on (turn off)"  (text, line 370)
- "Warnings and notices on screen: on (turn off)"  (text, line 373)

> Note for you (not shown in game): help, and staff

- "Ask staff"  (text, line 382)
- "What's wrong? Staff see this as a ticket."  (text, line 382)

> Note for you (not shown in game): Workers who want a unit with them: waiting, left alone, or with an NPC unit a player can take over from.

- "with an NPC Civil Protection unit"  (text, line 412)

> Note for you (not shown in game): the game answering something done in a window (lc_interrogate)

- "A Civil Protection unit stands over you with a stun baton. "You will answer my questions." /  / Talk, and the beating stops: you give up a Resistance hideout. Say nothing, and take it."  (label or button, line 465)
- "Talk (give them a hideout)"  (label or button, line 470)
- "Say nothing"  (label or button, line 479)

## cl_livingcity_admintools.lua (cl_livingcity_admintools.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_admintools.lua`


> Note for you (not shown in game): part of: build

- "Admin: testing tools"  (window title, line 79)

> Note for you (not shown in game): who it's for

- "Acting on:"  (text, line 87)

> Note for you (not shown in game): faction

- "Faction  (switches straight away, no requirements)"  (text, line 100)

> Note for you (not shown in game): XP and rank

- "XP and rank  (%s: %d XP)"  (message, line 108)
- "XP and rank"  (text, line 108)
- "Set rank:"  (text, line 114)

> Note for you (not shown in game): part of: build

- "This faction has no ranks to climb."  (text, line 122)
- "Reset all XP to 0"  (text, line 125)

> Note for you (not shown in game): credits and standing

- "economy off"  (message, line 128)
- "Reset to 0"  (text, line 131)
- "Civil Standing  (%s)"  (message, line 132)
- "economy off"  (message, line 132)

> Note for you (not shown in game): odds and ends

- "Clear wanted"  (text, line 143)
- "Feed and heal"  (text, line 144)
- "Clear conduct strikes"  (text, line 145)
- "Give item:"  (text, line 147)

> Note for you (not shown in game): the whole city (sv_livingcity_power.lua)

- "The city"  (text, line 157)
- "Black out the city"  (text, line 160)
- "Lights on"  (text, line 161)
- "Follow the grid"  (text, line 162)
- "Start over"  (text, line 164)

> Note for you (not shown in game): part of: build

- "Reset XP, credits and standing to 0"  (text, line 166)

## cl_livingcity_atmos.lua (cl_livingcity_atmos.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_atmos.lua`


> Note for you (not shown in game): what the city is doing at this hour (sv_livingcity_rhythm.lua)

- "night: the streets are quiet"  (text, line 59)
- "morning: off to work"  (text, line 60)
- "the work day"  (text, line 61)
- "midday: ration lines"  (text, line 62)

> Note for you (not shown in game): the city's ration stores (sv_livingcity_stockpile.lua)

- "ration stores %d%%%s"  (message, line 84)

## cl_livingcity_character.lua (cl_livingcity_character.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_character.lua`

- "This is the Civil Intake terminal's registration screen. Enter who you are, then submit it; the terminal processes you while you wait beside it."  (text, line 49)

> Note for you (not shown in game): part of: paint

- "Number to be issued:"  (text, line 80)

> Note for you (not shown in game): the game answering something done in a window (lcc_open)

- "Your name"  (label or button, line 188)
- "First name and surname"  (text, line 202)

> Note for you (not shown in game): stuck for a name: an ordinary one, for the face picked

- "Suggest a name"  (label or button, line 207)

> Note for you (not shown in game): the game answering something done in a window (lcc_open)

- "How a stranger would know you"  (label or button, line 217)
- "tall, grey coat, a scar over one eye"  (text, line 225)
- "Your face (then its look, under the picture)"  (label or button, line 233)
- "Not now"  (button, line 271)
- "Keep what I was given (ignores edits)"  (button, line 277)
- "Submit to the terminal"  (button, line 283)
- "This is me"  (button, line 283)

> Note for you (not shown in game): The server says yes, or why not.

- "[Living City]"  (chat message, line 308)
- "You are {msg}."  (chat message, line 308)

## cl_livingcity_cp.lua (cl_livingcity_cp.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_cp.lua`


> Note for you (not shown in game): part of: fill detail

- "Pick a citizen on the left."  (text, line 106)
- "Loyalty points %d (%s)"  (message, line 112)
- "in custody"  (text, line 114)
- "+{cap} loyalty"  (button, line 122)
- "-{cap} loyalty"  (button, line 123)
- "Revoke business license"  (button, line 124)
- "None on record."  (text, line 128)
- "Log a violation (e.g. 'False request')"  (text, line 133)
- "Add violation"  (text, line 133)
- "No notes."  (text, line 136)
- "Add a note"  (text, line 141)
- "Add note"  (text, line 141)
- "Be on the lookout"  (text, line 143)
- "What to look out for (30 minutes)"  (text, line 144)

> Note for you (not shown in game): part of: build records

- "Civil Protection: records terminal"  (window title, line 151)
- "Search by name or CID (people not in the city too)"  (text, line 196)

> Note for you (not shown in game): BOLOs

- "A BOLO on a description, not a record ('male, red jacket, northbound')"  (text, line 227)
- "No BOLOs out."  (text, line 229)

> Note for you (not shown in game): part of: build records

- "%s%s / %s, %s, %d min left"  (message, line 238)
- "BOLOs ({or})"  (text, line 246)

> Note for you (not shown in game): requests

- "No requests."  (text, line 251)
- "Requests ({or})"  (text, line 256)

> Note for you (not shown in game): part of: open voice menu

- "Voice (or type the words, or /vo <word>)"  (window title, line 278)

> Note for you (not shown in game): part of: draw socio pill

- "SOCIOSTABILITY: {SetFont}"  (text, line 362)

> Note for you (not shown in game): on screen

- "!struggle to work at the cuffs when nobody's looking"  (text, line 385)
- "HANDS UP  (!handsup to lower them)"  (text, line 387)

## secret endings, on your screen (sv_livingcity_endings.lua) (cl_livingcity_endings.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_endings.lua`


> Note for you (not shown in game): (the server's volume for this song, for a quiet recording, times your own)

- "the game can't open it ({err}): is it really the format its name says?"  (text, line 79)

> Note for you (not shown in game): time stopped: the colour goes

- "$pp_colour_addr"  (text, line 236)
- "$pp_colour_addg"  (text, line 236)
- "$pp_colour_addb"  (text, line 236)
- "$pp_colour_brightness"  (text, line 236)
- "$pp_colour_contrast"  (text, line 237)
- "$pp_colour_colour"  (text, line 237)
- "$pp_colour_mulr"  (text, line 237)
- "$pp_colour_mulg"  (text, line 237)
- "$pp_colour_mulb"  (text, line 237)

> Note for you (not shown in game): on screen

- "The man in the blue suit would like your decision: {or}."  (text, line 252)
- "%d seconds.   Let it happen: %d   Skip it: %d   (no votes at all: it happens)"  (message, line 255)
- "You chose: let it happen."  (text, line 256)
- "You chose: skip it."  (text, line 256)
- "PHOTOSENSITIVITY WARNING: this one has flashing lights and strobes."  (text, line 258)
- "You've turned the flashing off (lc_ending_calm 0 turns it back on)."  (text, line 259)
- "Type lc_ending_calm 1 in the console to leave the flashing out, just for you."  (text, line 259)
- "You're dead. Watch the end of the city."  (text, line 265)
- "Left / right click: someone else      Jump: fly free"  (text, line 266)
- "The city resets."  (text, line 272)

> Note for you (not shown in game): the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 792)
- "$pp_colour_addg"  (text, line 792)
- "$pp_colour_addb"  (text, line 792)
- "$pp_colour_brightness"  (text, line 793)
- "$pp_colour_contrast"  (text, line 793)
- "$pp_colour_colour"  (text, line 793)
- "$pp_colour_mulr"  (text, line 794)
- "$pp_colour_mulg"  (text, line 794)
- "$pp_colour_mulb"  (text, line 794)

> Note for you (not shown in game): on screen

- "Under the water: hold Jump to swim up"  (text, line 870)

> Note for you (not shown in game): the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 878)
- "$pp_colour_addg"  (text, line 878)
- "$pp_colour_addb"  (text, line 878)
- "$pp_colour_brightness"  (text, line 878)
- "$pp_colour_contrast"  (text, line 879)
- "$pp_colour_colour"  (text, line 879)
- "$pp_colour_mulr"  (text, line 879)
- "$pp_colour_mulg"  (text, line 879)
- "$pp_colour_mulb"  (text, line 879)

> Note for you (not shown in game): The warning, as a flashing ending starts: leave the flashing out, or not

- "Photosensitivity warning"  (window title, line 1305)

> Note for you (not shown in game): part of: flash warning

- "What's about to happen has flashing lights, strobes and screen flashes. If that could be a problem for you, leave them out: the music, the dancing and everything else stay. (lc_ending_calm in the console changes it any time.)"  (label or button, line 1314)
- "Reduce flashing"  (label or button, line 1319)

> Note for you (not shown in game): (doing nothing is "I'm fine": it goes by itself after 15 seconds, time enough to read it)

- "I'm fine, keep it (15)"  (label or button, line 1327)
- "I'm fine, keep it ({left})"  (label or button, line 1332)
- "Oy vey!"  (text, line 1688)
- "Oy gevalt!"  (text, line 1688)
- "Mazel tov!"  (text, line 1688)
- "Kvetch, kvetch"  (text, line 1688)
- "Zei gezunt!"  (text, line 1689)
- "Kol hakavod!"  (text, line 1689)
- "Oy li!"  (text, line 1689)
- "Hava nagila!"  (text, line 1690)
- "Am Yisrael chai!"  (text, line 1690)
- "Toda raba!"  (text, line 1690)
- "Ein ba'aya!"  (text, line 1690)
- "Chag sameach!"  (text, line 1690)
- "Shabbat shalom!"  (text, line 1690)
- "Ma nishma?"  (text, line 1691)
- "Yasher koach!"  (text, line 1691)
- "Oy, mamaleh!"  (text, line 1691)
- "Hakol beseder!"  (text, line 1691)
- "Tov me'od!"  (text, line 1691)
- "Baruch HaShem!"  (text, line 1691)

> Note for you (not shown in game): on screen

- "Am Yisrael chai"  (text, line 2063)

> Note for you (not shown in game): the console command lc_shalom_pose_print

- "chair %s = Angle(%g, %g, %g)"  (message, line 2082)

## the Endings menu (superadmins): tune the secret endings live (cl_livingcity_endingtune.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_endingtune.lua`


> Note for you (not shown in game): Each ending's moves: { move, what it is }

- "The dance: hands up, wrists flapping, hips swaying"  (text, line 42)
- "The dance, on the Combine's units only (their bones sit differently)"  (text, line 42)
- "Club dance (the kicks)"  (text, line 43)
- "Rave dance (bigger kicks)"  (text, line 43)
- "Sat down, arms up (Base's ZIG riders too)"  (text, line 44)
- "Sat in a ZIG, arms up (the Bus's riders too)"  (text, line 45)
- "Party hard (a pose and its mirror image)"  (text, line 46)
- "The hora: arms on the shoulders, the grapevine"  (text, line 47)
- "Rushing into the middle, arms up"  (text, line 47)
- "Up on the chair"  (text, line 47)
- "Numa numa"  (text, line 48)
- "Bent over, behind out, arms pumping (on the ground)"  (text, line 49)
- "Flying on it, Superman style (Pelvis tips the whole body)"  (text, line 49)
- "The crowd cheering"  (text, line 50)
- "On the rope, kicking"  (text, line 50)
- "Limp, at the end"  (text, line 50)
- "Father Grigori headbanging (the heavy parts)"  (text, line 51)
- "Father Grigori dancing (the calm parts)"  (text, line 51)

> Note for you (not shown in game): where each bone sits on the body map (facing you: their right arm on your left)

- "Mid back"  (text, line 69)
- "Lower back"  (text, line 70)
- "R upper arm"  (text, line 71)
- "L upper arm"  (text, line 72)

> Note for you (not shown in game): what each of a bone's three turns does (as the playtests showed them)

- "Out to the side (right arm: minus, left: plus)"  (text, line 78)
- "Raise forward (minus is up)"  (text, line 78)
- "Swing sideways"  (text, line 79)
- "Bend the elbow"  (text, line 79)
- "Twist (turns the palm)"  (text, line 79)
- "Bend the wrist"  (text, line 80)
- "Out to the side"  (text, line 81)
- "Swing forward and back"  (text, line 81)
- "Bend the knee (lifts the foot off the floor)"  (text, line 82)
- "Nod (forward and back)"  (text, line 83)
- "Tilt side to side"  (text, line 83)

> Note for you (not shown in game): part of: setting row

- "(the same on everyone's screen)"  (text, line 315)
- "Back to the default ({d})"  (button, line 346)

> Note for you (not shown in game): part of: changes

- "Living City: ending tuning, from the Endings menu"  (text, line 380)
- "Settings changed from their default:"  (text, line 386)
- "Shared settings (the same on everyone's screen):"  (text, line 393)
- "Dance tuning (added to the code's own turn of the bone; pitch yaw roll):"  (text, line 397)
- "Nothing changed yet."  (text, line 402)

> Note for you (not shown in game): part of: dance tab

- "This ending has no dance to tune. Its settings are on the next tab."  (text, line 411)

> Note for you (not shown in game): part of: paint

- "Nobody's doing this move in sight."  (drawn on screen, line 437)
- "Play the ending, or tick the stand-in below."  (drawn on screen, line 438)
- "drag to turn round, wheel to zoom"  (drawn on screen, line 449)

> Note for you (not shown in game): part of: dance tab

- "Watch someone else doing it"  (button, line 455)
- "Yellow: the bone you're turning. Blue edge: a bone that's been tuned. In the world it's lit up on everyone doing the move (red forward, green right, blue up)."  (text, line 500)
- "Left and right mirror each other"  (label or button, line 505)
- "Back to how the code has it: this bone"  (button, line 521)
- "Back to how the code has it: the whole move"  (button, line 527)
- "Stand-in: someone doing the move in front of you (only on your screen)"  (label or button, line 535)
- "The stand-in's beats a minute"  (text, line 538)

> Note for you (not shown in game): part of: think

- "The song is at %.1f s (%s)"  (message, line 550)
- "The song's time shows here while an ending plays (for lining up its sections: seconds:part,seconds:part,...)."  (label or button, line 550)

> Note for you (not shown in game): part of: settings tab

- "Copy the song's time"  (button, line 552)
- "No settings of its own."  (text, line 558)
- "Every ending:"  (text, line 560)

> Note for you (not shown in game): part of: you tab

- "These are your own game's, not the server's."  (text, line 567)
- "How loud the songs are"  (text, line 574)
- "Calm: no strobes or screen flashes"  (label or button, line 577)
- "Base's arcade blocks (1: off)"  (text, line 579)

> Note for you (not shown in game): part of: changes tab

- "Everything you've changed. Copy it and send it on, and it can be built in as the new normal."  (text, line 586)
- "Copy it all"  (button, line 596)

> Note for you (not shown in game): part of: fill

- "The dance"  (text, line 608)
- "Just for you"  (text, line 610)

> Note for you (not shown in game): part of: open

- "Endings: tune them live"  (window title, line 633)
- "Play it now"  (button, line 647)
- "Stop it"  (button, line 648)
- "(playing now)"  (text, line 662)

> Note for you (not shown in game): part of: endings menu

- "Only a superadmin can tune the endings."  (chat message, line 675)

## morning exercise, on your screen (sv_livingcity_exercise.lua) (cl_livingcity_exercise.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_exercise.lua`

- "the start of the jogging route"  (text, line 21)
- "the exercise yard"  (text, line 21)
- "the parade route"  (text, line 21)

> Note for you (not shown in game): on screen

- "You're here. Wait for the start."  (text, line 110)
- "Report to {kind} (the marker), {m} m away. It's mandatory."  (text, line 113)
- "You're missing it. Report to {kind} (the marker), before a Civil Protection unit finds you."  (text, line 122)
- "Marker %d of %d"  (message, line 132)
- "You lead: crouch, jump, turn around or step, one every few seconds. They copy you."  (text, line 140)
- "Copy every move. Stay on your place (the ring).   Mistakes: {m}"  (text, line 143)
- "SKIPPING: jump on every beat"  (text, line 154)
- "ENTHUSIASM   (/cheer, /salute, chant in chat, jump)"  (text, line 173)

## cl_livingcity_factions.lua (cl_livingcity_factions.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_factions.lua`


> Note for you (not shown in game): admins: the testing tools (XP, ranks, credits, standing)

- "Admin: testing tools (XP, ranks, credits, standing)"  (label or button, line 66)

> Note for you (not shown in game): the game answering something done in a window (lcf_menu)

- "%d special role%s"  (message, line 83)
- "Your rank: %s   XP %d%s"  (message, line 116)
- "(next: %s at %d)"  (message, line 117)
- "(highest rank)"  (message, line 117)
- "You are here"  (text, line 141)
- "Join {name}"  (text, line 141)
- "Special role: {name}  ({taken}/{or} taken)"  (label or button, line 150)

> Note for you (not shown in game): how a role sits with your rank: on top of it, not instead of it

- "A role, not a rank: you stay %s and keep earning XP toward the next rank. While you hold it you carry its kit%s instead of your rank's%s. To give it up, press "Join %s" above: you're back to %s with %s kit."  (message, line 168)

> Note for you (not shown in game): the game answering something done in a window (lcf_menu)

- "and wear its clothes"  (message, line 169)
- "your rank"  (message, line 169)
- "a {myRank}'s"  (message, line 169)
- "You hold this role"  (text, line 173)
- "Take up the role of {name}"  (text, line 173)

> Note for you (not shown in game): (a special role is held on top of your rank: "Hacker (Fighter)")

- "Habitation Block %02d"  (text, line 228)

> Note for you (not shown in game): (the Overwatch ranks wait on the conditioning: the Overwatch Candidate story)

- "%s   %d XP (higher needs the Overwatch conditioning)"  (message, line 259)

> Note for you (not shown in game): part of: xpinfo

- "%s   %d XP (top rank)"  (message, line 266)

> Note for you (not shown in game): the game's huddraw target id moment

- "Citizen {alias}"  (text, line 408)
- "NOT ON THE ROSTER (search them: baton reload, or !search)"  (text, line 416)

> Note for you (not shown in game): what units know: a BOLO out on them, hands tied, hands up (sv_livingcity_cp.lua)

- "BOLO: {GetNW2String}"  (text, line 421)
- "Hands cuffed"  (text, line 422)
- "Hands up"  (text, line 423)

## cl_livingcity_grigori.lua (cl_livingcity_grigori.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_grigori.lua`


> Note for you (not shown in game): part of: paint

- ""What do you need, child?""  (drawn on screen, line 36)
- ""Go with God. But go.""  (drawn on screen, line 36)

> Note for you (not shown in game): the game answering something done in a window (lc_grigori)

- "Ask for his blessing"  (text, line 51)
- "Again in %d s"  (message, line 51)
- "25 health, and five minutes of taking less harm"  (text, line 51)
- "Ask him to preach"  (text, line 52)
- "Again in %d s"  (message, line 52)
- "Everyone of ours nearby is emboldened for ten minutes"  (text, line 52)
- "Talk to him"  (text, line 53)
- "A word from the old man"  (text, line 53)

## cl_livingcity_hints.lua (cl_livingcity_hints.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_hints.lua`


> Note for you (not shown in game): What each binding is usually on, if the player hasn't bound it.

- "+menu_context"  (text, line 25)
- "Left click"  (text, line 26)
- "Right click"  (text, line 26)
- "Middle click"  (text, line 26)

> Note for you (not shown in game): on screen

- "+{more} more"  (drawn on screen, line 123)

> Note for you (not shown in game): gone before you finished reading? it's kept

- "Read it again any time: {HintKeys} > Tips I've seen"  (drawn on screen, line 131)

> Note for you (not shown in game): part of: paint

- "None yet: they come as you meet things."  (drawn on screen, line 162)
- "so far, this session's first"  (text, line 162)

> Note for you (not shown in game): the game answering something done in a window (lc_hints_seen)

- "Tips are off: turn them on"  (text, line 194)
- "Tips are on: turn them off"  (text, line 194)
- "Show me them all again, from the start"  (text, line 195)

## cl_livingcity_infest.lua (cl_livingcity_infest.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_infest.lua`


> Note for you (not shown in game): The air itself: a yellow cast over everything, and motes of it drifting past you.

- "$pp_colour_addr"  (text, line 108)
- "$pp_colour_addg"  (text, line 108)
- "$pp_colour_addb"  (text, line 108)
- "$pp_colour_brightness"  (text, line 109)
- "$pp_colour_contrast"  (text, line 109)
- "$pp_colour_colour"  (text, line 110)
- "$pp_colour_mulr"  (text, line 111)
- "$pp_colour_mulg"  (text, line 111)
- "$pp_colour_mulb"  (text, line 111)

## cl_livingcity_intake.lua (cl_livingcity_intake.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_intake.lua`


> Note for you (not shown in game): on screen

- "Stay next to the terminal"  (drawn on screen, line 77)

> Note for you (not shown in game): The sign on the terminal itself (lc_intake.lua draws it, in 3D).

- "Registered? Ask for a room here"  (drawn on screen, line 107)
- "New here? Register here"  (drawn on screen, line 107)

> Note for you (not shown in game): How you came to have the room you have.

- "Allocated here, at Housing Allocation."  (text, line 133)
- "Transferred here at your request."  (text, line 134)
- "Given to you with your papers (there was no Housing Allocation desk then)."  (text, line 135)
- "Given to you by the city's staff."  (text, line 136)
- "Given to you when you first arrived in the city."  (text, line 137)

> Note for you (not shown in game): part of: paint

- "citizen {or}"  (drawn on screen, line 173)

> Note for you (not shown in game): part of: open desk

- "Housing: {or}"  (text, line 208)
- "Identity papers: {or}"  (text, line 209)
- "Ration cards: %d (you earn one for each Union shift you finish)"  (message, line 210)
- "Replace my identity papers (%d credits)"  (message, line 213)
- "Civil Protection units ask to see them, and Housing Allocation needs them to give you a room"  (button, line 214)
- "Your papers are in order."  (text, line 216)
- "You have no room yet. Housing Allocation gives you one."  (text, line 219)
- "Show me the way to Housing Allocation"  (text, line 220)
- "Show me the way home"  (text, line 222)
- "You're not registered yet. Register at Civil Intake first, then come back here with your papers."  (text, line 226)
- "Show me the way to Civil Intake"  (text, line 227)
- "Show your papers and pick a block. "Any block" is approved at once and gives you the least crowded one. A crowded block needs Civil Standing {or} or more. Yours is {or}."  (text, line 230)
- "Papers: {or}"  (text, line 232)
- "Any block (approved at once)"  (button, line 233)
- "Ask for %s   (%d live there%s%s)"  (message, line 238)
- "This city has no housing blocks."  (text, line 241)
- "Show me the way home"  (text, line 245)
- "Move to another block (once every half hour). A crowded block needs Civil Standing {or}."  (text, line 248)
- "Move to %s   (%d live there%s)"  (message, line 251)
- "You need your papers to apply, and you have none on you."  (text, line 255)
- "Not now."  (text, line 257)
- "citizen {or}"  (text, line 261)

> Note for you (not shown in game): on screen

- "Shown to you by the person in front of you"  (drawn on screen, line 325)

## cl_livingcity_jobgames.lua (cl_livingcity_jobgames.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_jobgames.lua`


> Note for you (not shown in game): the game answering something done in a window (lc_papers_check)

- "Papers check: traveler %d of %d"  (message, line 109)

> Note for you (not shown in game): part of: paint

- "The seal must read OCS."  (drawn on screen, line 131)
- "Look at the traveler: is it them?"  (drawn on screen, line 132)

> Note for you (not shown in game): the buttons, at the bottom

- "Call a Civil Protection unit"  (text, line 140)

> Note for you (not shown in game): part of: paint

- "Citizen no."  (text, line 164)
- "Issued in"  (text, line 165)
- "Valid until"  (text, line 166)
- "Day {or}"  (text, line 166)

> Note for you (not shown in game): the game answering something done in a window (lc_wire_open)

- "Rewiring {or}"  (window title, line 237)

> Note for you (not shown in game): part of: paint over

- "%d s    Turns %d (par %d)    Shocks %d"  (message, line 254)
- "Click turns a tile, right-click turns it back. Get the current to the lamp. Don't touch a sparking tile."  (drawn on screen, line 256)

## cl_livingcity_kick.lua (cl_livingcity_kick.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_kick.lua`


> Note for you (not shown in game): on screen

- "Out cold"  (drawn on screen, line 145)
- "You come round in %d"  (message, line 146)

> Note for you (not shown in game): the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 158)
- "$pp_colour_addg"  (text, line 158)
- "$pp_colour_addb"  (text, line 158)
- "$pp_colour_brightness"  (text, line 159)
- "$pp_colour_contrast"  (text, line 159)
- "$pp_colour_colour"  (text, line 160)
- "$pp_colour_mulr"  (text, line 160)
- "$pp_colour_mulg"  (text, line 160)
- "$pp_colour_mulb"  (text, line 160)

## cl_livingcity_lab.lua (cl_livingcity_lab.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_lab.lua`


> Note for you (not shown in game): part of: open lab

- "He's busy with someone else's work for another %d seconds."  (message, line 57)
- "Bring him the materials and he makes it for nothing, or pay him for it (cheaper than the dealer). Stay in the lab while he works."  (label or button, line 58)
- "Decode it"  (label or button, line 74)

> Note for you (not shown in game): part of: paint

- "A new face (%d credits)"  (message, line 89)
- "Twenty seconds under. Nobody's looking for the face you wake with: wanted, BOLOs and"  (drawn on screen, line 90)
- "photos gone, and the records can't put your old name (or your standing) to it."  (drawn on screen, line 91)

> Note for you (not shown in game): part of: open lab

- "Change it"  (label or button, line 97)
- "Pay {or} credits"  (label or button, line 125)
- "Use my materials"  (label or button, line 132)

## cl_livingcity_lagwatch.lua (cl_livingcity_lagwatch.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_lagwatch.lua`


> Note for you (not shown in game): part of: set lag watch

- "[Lag monitor]"  (chat message, line 47)
- "On. It's at the right of your screen. (lc_lagwatch_print copies the last half minute to the console.)"  (chat message, line 47)

> Note for you (not shown in game): Which looks like the cause

- "The gamemode is teleporting NPCs ({tele} this second{or})."  (text, line 176)

> Note for you (not shown in game): part of: verdict

- "The server is hitching: %.0f ms between two frames (it should be %.0f)."  (message, line 179)

> Note for you (not shown in game): ping well above its usual: data queueing somewhere between you and the server

- "Your ping jumped from about %d to %d ms with the server keeping up: something on the connection (a download, another device, the host's upload)."  (message, line 184)
- "Packets are being lost between you and the server (%d%%): the connection or the host."  (message, line 187)

> Note for you (not shown in game): part of: verdict

- "The server's updates reach you late (a %.0f ms wait): the network, or the server sending you too much (choke). Check net_graph 3."  (message, line 190)
- "Your own game is stalling (a %.0f ms frame): addons, or the graphics."  (message, line 193)
- "NPCs are snapping, but nothing measured here explains it yet. Send lc_lagwatch_print."  (text, line 196)
- "Nothing wrong this second."  (text, line 198)

> Note for you (not shown in game): on screen

- "LAG MONITOR (C > Help to turn off)"  (text, line 209)
- "Server: %d of %d ticks, longest gap %.0f ms, NPC loop %.2f ms"  (message, line 215)
- "NPC teleports by the gamemode: %d%s"  (message, line 216)
- "Gamemode net: %.1f KB/s  %s"  (message, line 220)
- "Entities %d, edicts %d of 8176, NPCs %d (city %d, asleep %d)"  (message, line 221)
- "You: ping %d ms, packet loss %d%%"  (message, line 222)
- "Server: no figures yet (staff only)"  (text, line 224)
- "Your game: %d fps, slowest frame %.0f ms; server frame as heard %.1f ms (+/- %.1f)"  (message, line 226)
- "Longest wait for a server update: %.0f ms"  (message, line 227)
- "NPCs snapping on screen: %d jumps, %d steps back"  (message, line 228)
- "Busiest update: %d things moved (%s); %d values changed (%s)"  (message, line 229)
- "Server net: split rate %s, max rate %s, min rate %s"  (message, line 232)
- "cl_interp %s, cl_interp_ratio %s, cl_updaterate %s, rate %s"  (message, line 234)

> Note for you (not shown in game): the console command lc_lagwatch_print

- "%s \| srv ticks %s/%s gap %sms lua %sms tele %s (%s) net %sB [%s] ents %s edicts %s npcs %s asleep %s ping %s loss %s \| fps %d worst %.0fms srvframe %.1f+/-%.1f update-wait %.0fms snaps %d backs %d \| %s"  (message, line 256)
- "busiest update: %d moved [%s] \| %d values changed [%s]"  (message, line 260)
- "server net: net_splitpacket_maxrate %s sv_maxrate %s sv_minrate %s"  (message, line 263)
- "settings: cl_interp %s cl_interp_ratio %s cl_updaterate %s cl_cmdrate %s rate %s"  (message, line 264)

## cl_livingcity_layoutbrowser.lua (cl_livingcity_layoutbrowser.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_layoutbrowser.lua`

- "Street furniture and screens"  (title, line 18)
- "Workplaces (Union jobs)"  (title, line 19)
- "Paths and ladders"  (title, line 20)
- "Persistent props"  (title, line 23)

> Note for you (not shown in game): The other way to look at the same list: by what it's for, everything a part of the city needs in one place (building a rebel base: its zone, its lab, its beds, its lookouts, all together). A thing can be in more than one. Occupations get a folder each: their workplace and what goes with it.

- "Citizens' daily life"  (title, line 31)
- "Arriving and leaving the city"  (title, line 33)
- "Civil Protection and the Combine"  (title, line 34)
- "The Resistance and rebel bases"  (title, line 37)
- "Morning exercise"  (title, line 40)
- "Power and the street"  (title, line 41)
- "Paths, ladders and doors"  (title, line 42)

> Note for you (not shown in game): What the city would like to have and hasn't got.

- "No prison cells: arrests happen on the street."  (text, line 136)
- "No release spot: prisoners walk out of their cell."  (text, line 137)
- "No ration dispenser."  (text, line 138)
- "No ration line."  (text, line 139)
- "No spawn/exit doorways: NPCs appear out of sight."  (text, line 140)
- "No checkpoints for Civil Protection units to man."  (text, line 141)
- "No housing blocks: curfew has nowhere to send people."  (text, line 142)
- "No prison area (optional; the cells work without it)."  (text, line 143)
- "No infestation spawns: zombies appear anywhere in infestation zones."  (text, line 144)
- "No incinerator: Morticians bag bodies at the morgue workplace, or have no collections."  (text, line 145)
- "No scanner launch spot: flown scanners go up in the open air near the console."  (text, line 146)
- "No Civil Intake (optional): new people are registered as they arrive, with a room handed to them."  (text, line 147)
- "No Civil Protection Commissary: Civil Protection units are issued their supplies at the Union Commissary instead."  (text, line 148)
- "No Resistance lab: the Resistance can only get guns, jammers and radios from the black market."  (text, line 149)

> Note for you (not shown in game): part of: glance

- "%d points, %d fixtures, %d zones, %d tagged doors, %d path nodes.  %d city NPCs about."  (message, line 160)

> Note for you (not shown in game): part of: build layout browser

- "Loading the layout..."  (label or button, line 179)
- "Stop finding everything"  (label or button, line 191)

> Note for you (not shown in game): arranged by type (points, fixtures...) or by what it's for: the list is rebuilt in place

- "Arrange by type: points, fixtures, zones, doors"  (text, line 197)
- "Arrange by what it's for: rebels, prison, each job..."  (text, line 198)

> Note for you (not shown in game): (no workplace to place for the Block Warden or Infestation Cleanup; Cleanup still has its barrels and zones)

- "Job: {name}"  (title, line 215)

> Note for you (not shown in game): part of: fill

- "Take me to the next one (admins)"  (tooltip, line 284)
- "Mark every one of these on screen, through walls"  (tooltip, line 295)

## cl_livingcity_life.lua (cl_livingcity_life.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_life.lua`


> Note for you (not shown in game): "3 hours 12 minutes", "2 days 5 hours", "40 minutes", "less than a minute"

- "less than a minute"  (text, line 59)

> Note for you (not shown in game): The lines under the name, in order.

- "Lived {secs} in the city."  (text, line 75)

> Note for you (not shown in game): part of: death lines

- "Lived at least {secs} in the city."  (text, line 77)
- "Lived in the city since before anyone kept count."  (text, line 79)
- "Nobody knew {her} name."  (text, line 83)
- "One person knew {her} name."  (text, line 85)
- "people knew {her} name."  (text, line 87)

> Note for you (not shown in game): the game's post draw hud moment

- "Citizen {cid}"  (drawn on screen, line 125)
- "You died."  (drawn on screen, line 129)
- "That person is gone."  (drawn on screen, line 142)
- "Click to go on."  (drawn on screen, line 146)

## cl_livingcity_moregames.lua (cl_livingcity_moregames.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_moregames.lua`


> Note for you (not shown in game): Records terminal: stop the needle in the band

- "Records terminal: stop the needle in the band (click or space)"  (window title, line 85)

> Note for you (not shown in game): part of: paint

- "Bypassed %d of %d"  (message, line 111)
- "Seen %d of 2"  (message, line 112)
- "Scanner coming..."  (text, line 115)

> Note for you (not shown in game): part of: hack

- "Step away from it"  (button, line 119)

> Note for you (not shown in game): Searching the dead: pocket by pocket

- "Searching the dead: %d of %d"  (message, line 132)

> Note for you (not shown in game): part of: paint

- "The overseer is out of the room"  (drawn on screen, line 140)

> Note for you (not shown in game): part of: search

- "Done: into the fire"  (button, line 146)

> Note for you (not shown in game): part of: paint

- "Not searched"  (text, line 159)
- "(yours now)"  (text, line 160)
- "(set aside for the family)"  (text, line 161)

> Note for you (not shown in game): part of: fill

- "Log it"  (text, line 174)

> Note for you (not shown in game): part of: update

- "Searching the dead: %d of %d"  (message, line 178)

> Note for you (not shown in game): Sorting uniforms

- "Sorting: every uniform to its division"  (window title, line 187)

> Note for you (not shown in game): part of: paint

- "Uniform %d of %d"  (message, line 195)
- "Something in the pocket: {pocket}"  (drawn on screen, line 198)

> Note for you (not shown in game): part of: laundry

- "Pocket it"  (button, line 206)
- "Turn it in"  (button, line 208)

> Note for you (not shown in game): Filing The courier and the sender: take it, hand it back, report them, or open it

- "Take it"  (text, line 230)
- "Hand it back"  (text, line 230)
- "Report the sender"  (text, line 231)
- "Open it"  (text, line 231)
- "A parcel to deliver"  (window title, line 234)

> Note for you (not shown in game): part of: paint

- "You opened it: Civil Standing lost, and 1 credit a delivery instead of 3."  (drawn on screen, line 244)

> Note for you (not shown in game): how it works, in plain words (there were none)

- "Compare the form (left) with the register (right). If the name, number and status all match, file it by the first two digits of the citizen number: 37-412 goes in 25-49. If anything is different, even one letter or digit, or the status, it goes in Discrepancy."  (label or button, line 274)

> Note for you (not shown in game): part of: paint

- "Citizen no."  (drawn on screen, line 284)
- "Form %d of %d    %d s"  (message, line 292)

> Note for you (not shown in game): (the owner: it looked like part of the job. It's a crime, and says so)

- "CRIME: steal a blank identity form (for forged papers; a unit who sees it: wanted, and you lose standing)"  (button, line 311)

> Note for you (not shown in game): part of: radio

- "Radio repair: find its station, then set the screws by ear until it's clean"  (window title, line 486)

> Note for you (not shown in game): the time left on this set, ticking down (red near the end: it goes back on the shelf unfixed)

- "Set %d of %d"  (message, line 524)

> Note for you (not shown in game): part of: radio

- "Volume trimmer"  (text, line 533)
- "Test it: is it clean?"  (button, line 541)
- "Report the frequency"  (text, line 558)
- "Write it down"  (text, line 558)
- "Tune past it"  (text, line 558)

> Note for you (not shown in game): part of: paint over

- "Set %d of %d: clean. Off the bench it goes."  (message, line 586)
- "Set %d of %d: out of time. Back on the shelf, unfixed."  (message, line 587)
- "The next one from the shelf..."  (drawn on screen, line 589)

> Note for you (not shown in game): part of: listen window

- "Radio (retuned)"  (window title, line 617)
- "Union radio"  (window title, line 617)
- "Switch it off"  (button, line 652)
- "Anyone within about twenty feet hears it too. Close this and it keeps playing."  (label or button, line 660)

> Note for you (not shown in game): part of: paint

- "They stand very still and look at nothing."  (drawn on screen, line 698)
- "Their nerve: %d    Citizen %d of %d"  (message, line 699)

## cl_livingcity_needs.lua (cl_livingcity_needs.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_needs.lua`


> Note for you (not shown in game): loyalty, sympathy, corruption: what your choices have made of you (they open up choices in jobs and stories)

- "Loyalty %d   Sympathy %d   Corruption %d"  (message, line 118)
- "Union band"  (text, line 125)
- "Civil Protection uniform"  (text, line 126)
- "citizen clothes"  (text, line 126)
- "Resistance gear"  (text, line 126)

> Note for you (not shown in game): Breen's water, and coffee

- "Everything feels... pleasant. What were you doing?"  (chat message, line 188)

> Note for you (not shown in game): the game answering something done in a window (lcn_effect)

- "Real coffee. For a moment you remember what mornings used to be."  (chat message, line 191)

> Note for you (not shown in game): the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 208)
- "$pp_colour_addg"  (text, line 208)
- "$pp_colour_addb"  (text, line 208)
- "$pp_colour_brightness"  (text, line 209)
- "$pp_colour_contrast"  (text, line 209)
- "$pp_colour_colour"  (text, line 210)
- "$pp_colour_mulr"  (text, line 210)
- "$pp_colour_mulg"  (text, line 210)
- "$pp_colour_mulb"  (text, line 210)
- "$pp_colour_addr"  (text, line 216)
- "$pp_colour_addg"  (text, line 216)
- "$pp_colour_addb"  (text, line 216)
- "$pp_colour_brightness"  (text, line 217)
- "$pp_colour_contrast"  (text, line 217)
- "$pp_colour_colour"  (text, line 217)
- "$pp_colour_mulr"  (text, line 218)
- "$pp_colour_mulg"  (text, line 218)
- "$pp_colour_mulb"  (text, line 218)

> Note for you (not shown in game): weight and large things, against what you can carry

- "%.1f / %.0f kg     large %d / %d"  (message, line 271)
- "Too much to carry: you're slowed down"  (drawn on screen, line 273)

> Note for you (not shown in game): part of: open inventory

- "Take off the {or}"  (label or button, line 288)
- "Change into plain clothes"  (label or button, line 295)
- "Your papers say you are citizen {alias}."  (label or button, line 303)
- "Drink from the water (it may not be clean)"  (label or button, line 312)
- "Empty. Nothing to find."  (label or button, line 342)
- "Nothing for sale right now."  (text, line 342)
- "Nothing on it. Put things up for sale from your pockets below (Sell)."  (text, line 343)
- "Empty. Put things in from your pockets below."  (text, line 343)
- "Buy ({price})"  (label or button, line 366)

> Note for you (not shown in game): part of: do click

- "How many credits for one {name}?"  (text, line 383)

> Note for you (not shown in game): part of: open inventory

- "Collect the takings (%d)"  (message, line 399)
- "Closed by the Union: reopen"  (label or button, line 407)
- "Give up the locker (empty it first)"  (label or button, line 416)
- "Pack up the stall (empty it first)"  (text, line 417)
- "Pack up the crate (empty it first)"  (text, line 417)
- ""{or}..."{or}"  (label or button, line 441)
- "Your pockets are empty."  (label or button, line 456)
- "Hide it at home. (A raid on your block can still find it.)"  (text, line 493)
- "Put one on the stall, at a price you set"  (tooltip, line 500)

> Note for you (not shown in game): part of: do click

- "How many credits for one {name}?"  (text, line 502)

> Note for you (not shown in game): part of: open inventory

- "Put in"  (text, line 506)
- "Into {or}"  (text, line 506)
- "Set down"  (text, line 507)
- "Eat it"  (text, line 514)
- "Swallow the motherlode whole. You have a feeling about what happens next."  (text, line 514)
- "Hand one to the person in front of you"  (text, line 516)
- "Look at a locked door first. Or type !pick, or bind a key to lc_pick."  (text, line 517)
- "Become someone else. Clears your wanted status if no Civil Protection unit is watching."  (text, line 519)
- "Out of sight of any Civil Protection unit."  (text, line 520)
- "Visit a Civil Protection Commissary to be issued supplies: grenades for your rank, ammunition, armour, bandages and your ration."  (label or button, line 542)
- "Mark the nearest Civil Protection Commissary on my screen"  (label or button, line 547)

> Note for you (not shown in game): the lab (sv_livingcity_lab.lua) makes the Resistance's guns; everyone else buys them

- "Guns, ammunition, jammers, radios: the scientist in the lab makes them (mark the lab)"  (label or button, line 560)

> Note for you (not shown in game): part of: paint

- "(at a workbench)"  (text, line 592)
- "(out of sight)"  (text, line 592)

> Note for you (not shown in game): part of: open inventory

- "Nothing hidden here yet."  (label or button, line 620)

> Note for you (not shown in game): what's in your hands: a crowbar, a gun (not what your faction issued you)

- "On you: {name}{TEXT_ALIGN_CENTER}"  (label, line 654)

> Note for you (not shown in game): part of: open inventory

- "Stash it"  (label or button, line 663)
- "Hide it at home, magazine and all. (A raid on your block can still find it.)"  (tooltip, line 664)

> Note for you (not shown in game): the Civil Protection Commissary's counter, on its own screen (cl_livingcity_screens.lua), if this player has them on

- "{price} credits"  (text, line 697)

> Note for you (not shown in game): the game answering something done in a window (lce_shop)

- "the unit counter"  (text, line 700)

> Note for you (not shown in game): the game answering something done in a window (lcu_market)

- "Sell for {price}"  (text, line 819)
- "Sell all for {n}"  (text, line 826)

## cl_livingcity_nextstep.lua (cl_livingcity_nextstep.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_nextstep.lua`


> Note for you (not shown in game): The rank card: faction and rank, credits, Civil Standing (and wanted, when you are).

- "Credits %d     Civil Standing %d"  (message, line 63)

> Note for you (not shown in game): on screen

- "F1 > 1 shows you the way"  (drawn on screen, line 101)

> Note for you (not shown in game): F1, slot 1

- "Ration dispenser"  (text, line 113)
- "Water (a sink or a machine)"  (text, line 113)
- "Bins to search"  (text, line 113)
- "My block"  (text, line 114)
- "My workplace"  (text, line 114)
- "The Commissary"  (text, line 114)
- "Bathtub or shower"  (text, line 115)
- "Civil Intake"  (text, line 117)
- "Housing Allocation"  (text, line 117)

> Note for you (not shown in game): part of: more places page

- "Civil Protection Commissary"  (menu option, line 124)
- "The lab"  (menu option, line 125)
- "A mess to clean up"  (menu option, line 126)

> Note for you (not shown in game): part of: places page

- "More places..."  (text, line 136)

> Note for you (not shown in game): part of: what now page

- "Do it:"  (text, line 144)
- "Show me the way:"  (text, line 144)
- "Nothing pressing"  (menu option, line 150)
- "Ways to get by (everything you could do)"  (menu option, line 152)
- "Places in the city"  (text, line 153)
- "Keep it on screen: always (change)"  (menu option, line 155)
- "Keep it on screen: new life and urgent (change)"  (text, line 155)
- "Keep it on screen: never (change)"  (text, line 155)

## cl_livingcity_notices.lua (cl_livingcity_notices.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_notices.lua`


> Note for you (not shown in game): A sound the server asked for that this computer can't play: said once per file, on screen and in the console, with why. Announcements and songs play on each player's own computer, so the sound addon has to be on it too.

- "it isn't on this computer"  (text, line 77)

> Note for you (not shown in game): part of: sound trouble

- "Sound missing"  (on-screen notice, line 81)
- "Can't play {path}: {why}. Type lc_sound_check in the console to see why."  (on-screen notice, line 81)

> Note for you (not shown in game): the console command lc_sound_check

- "Game volume: {or}, lc_breencast_volume (the Administrator): {or}"  (chat message, line 117)
- "This computer has none of the city's sounds, so you hear none of them. The server sends them through FastDL: after a sound is added there, press FastDL sync, change the map, and reconnect. (For a game of your own, put them in garrysmod/sound/livingcity/ here.)"  (chat message, line 120)

> Note for you (not shown in game): the ending songs: every one on this computer, opened (not played) to see the game can play it

- "Ending songs on this computer (checking each one opens):"  (chat message, line 130)

> Note for you (not shown in game): play file

- "%s (%d KB): the game can't open it (%s)%s"  (message, line 139)
- ": it's empty, a download that didn't finish (delete it here and reconnect)"  (message, line 140)
- ": re-encode it as a 44100 Hz MP3"  (message, line 140)

> Note for you (not shown in game): the console command lc_sound_check

- "(A song added to the server only reaches players after the server changes map and they reconnect: FastDL sync, then a map change.)"  (chat message, line 144)

> Note for you (not shown in game): the stock Half-Life 2 Overwatch lines the city uses: which this install has

- "Half-Life 2's own Overwatch lines the city uses (found here, or missing):"  (chat message, line 146)

> Note for you (not shown in game): the console command lc_sound_check

- "Playing {first} now..."  (chat message, line 154)

> Note for you (not shown in game): play file

- "It plays. If you heard nothing, check your game volume. If you heard it but not in the city, tell the server's admin to run lc_announce_clips."  (chat message, line 158)
- "It's here but the game can't play it ({err}): the file isn't what its name says. Rename an MP3 to .mp3; a WAV must be 16-bit, 44100 Hz."  (chat message, line 160)

> Note for you (not shown in game): part of: draw waypoint

- "You're here: {label}."  (on-screen notice, line 273)

## cl_livingcity_outfits.lua (cl_livingcity_outfits.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_outfits.lua`


> Note for you (not shown in game): part of: describe

- "%s%s   (%d skins, %d pieces)"  (message, line 51)
- "own face,"  (message, line 51)

> Note for you (not shown in game): part of: open outfit designer

- "Job outfits"  (window title, line 62)
- "Looks for this job (each person gets one)"  (text, line 84)

> Note for you (not shown in game): part of: rebuild

- "Pick a job on the left."  (text, line 132)
- "Model (anything installed: citizens, medics, hostages, a pack)"  (text, line 133)
- "Choose a model..."  (text, line 137)
- "Keep each person's own face (a Half-Life 2 citizen face, in these clothes)"  (label or button, line 147)
- "NPC model (blank: worked out from the playermodel)"  (text, line 155)
- "Skins it may wear (%d): none ticked means any"  (message, line 164)
- ": the pieces it may show (none ticked: left as it is)"  (text, line 176)

> Note for you (not shown in game): part of: open outfit designer

- "Add this look"  (button, line 200)
- "Remove the selected look"  (button, line 211)
- "Save this job"  (button, line 217)

## cl_livingcity_quests.lua (cl_livingcity_quests.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_quests.lua`


> Note for you (not shown in game): part of: paint

- "{sympathy}     {corruption}"  (drawn on screen, line 50)

> Note for you (not shown in game): the game answering something done in a window (lcq_board)

- "Change job..."  (text, line 75)
- "You can take another job in {wait} seconds."  (label or button, line 101)
- "Nothing posted right now. Check back soon."  (label or button, line 109)
- "\|   %d/%d on it"  (message, line 152)
- "\|   up to %d together"  (message, line 152)
- "Join the squad"  (label or button, line 170)
- "Take the job"  (label or button, line 173)
- "ahead left"  (text, line 367)
- "behind left"  (text, line 367)
- "behind right"  (text, line 367)
- "ahead right"  (text, line 367)

> Note for you (not shown in game): anything more than a flight of stairs away counts: 48 units is "other level", then about 144 to a floor

- "same level"  (text, line 379)

> Note for you (not shown in game): on screen

- "A choice is waiting (it may be behind other windows)"  (drawn on screen, line 430)
- "Your squad leader is deciding..."  (drawn on screen, line 430)

> Note for you (not shown in game): being seen while tailing someone: right where you're looking, so you notice in time to duck back

- "out of sight"  (text, line 459)

> Note for you (not shown in game): on screen

- "objective  {dist} m"  (text, line 476)

## cl_livingcity_quick.lua (cl_livingcity_quick.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_quick.lua`


> Note for you (not shown in game): Pages

- "What do you yell?"  (chat message, line 54)
- "What do you whisper?"  (chat message, line 55)
- "Describe what I do (/me)..."  (menu option, line 56)
- "An action"  (chat message, line 56)
- "What do you do? (e.g. leans against the wall)"  (chat message, line 56)
- "Describe the scene (/it)..."  (menu option, line 57)
- "The scene"  (chat message, line 57)
- "What happens? (e.g. A siren starts up somewhere.)"  (chat message, line 57)
- "On my radio..."  (menu option, line 58)
- "What do you say on the radio?"  (text, line 58)
- "Roll the dice (1 to 100)"  (menu option, line 59)

> Note for you (not shown in game): part of: talk page

- "Out of character, nearby..."  (menu option, line 60)

> Note for you (not shown in game): item

- "Out of character"  (chat message, line 60)
- "Said out of character, to people nearby"  (chat message, line 60)

> Note for you (not shown in game): part of: talk page

- "Out of character, everyone..."  (menu option, line 61)

> Note for you (not shown in game): item

- "Out of character"  (chat message, line 61)
- "Said out of character, to the whole server"  (chat message, line 61)

> Note for you (not shown in game): part of: talk page

- "Tell everyone nearby my name"  (menu option, line 62)

> Note for you (not shown in game): part of: pose page

- "Lie down"  (menu option, line 68)
- "Stand: pose 1"  (menu option, line 69)
- "Stand: pose 2"  (menu option, line 70)
- "Stand up"  (menu option, line 71)

> Note for you (not shown in game): part of: voice page

- "All the voice lines..."  (menu option, line 105)

> Note for you (not shown in game): part of: resistance page

- "Find the lab (mark it)"  (menu option, line 118)
- "Donate food to the supply crate"  (menu option, line 119)
- "Decode a data chip (at the lab)"  (menu option, line 120)
- "Hack the Combine door I'm looking at"  (menu option, line 122)

> Note for you (not shown in game): part of: staff page

- "Staff panel (logs, tickets, warnings, bans)"  (menu option, line 129)
- "Admin testing tools"  (menu option, line 130)
- "Build mode: off (back to playing)"  (menu option, line 131)
- "Build mode: on"  (menu option, line 131)
- "Path mapping: on / off"  (menu option, line 132)

> Note for you (not shown in game): The first page: who you are

- "Lower my hands"  (menu option, line 219)
- "Put my hands up"  (menu option, line 219)

> Note for you (not shown in game): part of: quick root

- "My pockets (F2)"  (menu option, line 220)
- "My board: jobs (F3)"  (menu option, line 221)

> Note for you (not shown in game): slot 1 for anyone living in the city: the next step, and the way to everywhere (cl_livingcity_nextstep.lua)

- "What now?"  (text, line 223)
- "Call for backup"  (menu option, line 229)
- "Send my 10-20"  (menu option, line 230)

> Note for you (not shown in game): item

- "What should Civil Protection units look out for?"  (text, line 231)

> Note for you (not shown in game): part of: quick root

- "Voice lines"  (text, line 232)
- "Kick ({or})"  (menu option, line 233)
- "Unit tools (everything a unit has)"  (menu option, line 236)
- "My directives (F3)"  (menu option, line 237)
- "Gear up (Resistance clothes)"  (menu option, line 246)
- "Change into plain clothes"  (menu option, line 246)
- "Black market"  (menu option, line 248)
- "My papers"  (menu option, line 256)

> Note for you (not shown in game): 6 to 8: what's in front of you first, then your usual three

- "Everything else (full menu)"  (menu option, line 265)

> Note for you (not shown in game): on screen

- "+menu_context"  (text, line 366)
- ": the full menu"  (drawn on screen, line 367)

## apartment doors (client) (cl_livingcity_rent.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_rent.lua`


> Note for you (not shown in game): The lines to show for a door entity (nil: not an apartment door).

- "Apartment: available"  (text, line 33)
- "%d credits for %s hours"  (message, line 33)

> Note for you (not shown in game): part of: rent lines

- "Right click to rent it"  (text, line 34)
- "Put your hands out (nothing in them) and right click to rent it"  (text, line 34)
- "Your apartment ({or})"  (text, line 40)
- "Right click to {or} it"  (text, line 41)
- "Put your hands out and right click to lock or unlock it"  (text, line 41)
- "Apartment: {name}'s"  (text, line 43)

> Note for you (not shown in game): the game answering something done in a window (lc_rent_ask)

- "Rent this apartment for %d credits? It is yours for %s hours, locked to everyone but you and whoever you give a key."  (message, line 82)
- "Take this apartment? No rent for you (Civil Protection, or a citizen of high standing). It is yours for %s hours at a time, locked to everyone but you and whoever you give a key."  (message, line 83)
- "Rent apartment"  (text, line 87)
- "Yes, rent it"  (text, line 87)

## cl_livingcity_resistance.lua (cl_livingcity_resistance.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_resistance.lua`


> Note for you (not shown in game): on screen

- "BROKEN FEET: no running for %d:%02d"  (message, line 34)
- "COMBINE PROPERTY: there is no way out but death"  (text, line 39)
- "INTERROGATION   Talk (F1, or the choice on screen) to make it stop. Or say nothing, and take it."  (text, line 43)

> Note for you (not shown in game): part of: draw city screen

- "They are not invincible. Look out for one another."  (drawn on screen, line 110)

> Note for you (not shown in game): Someone on air: a banner for everyone, so you know whose voice it is

- "(the loudspeaker here is broken)"  (text, line 125)

## cl_livingcity_rest.lua (cl_livingcity_rest.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_rest.lua`


> Note for you (not shown in game): asleep: dark, and a little reassurance (slowly: a few seconds looking up from the pillow before your eyes close)

- "Asleep (%ds). Jump to get up (too soon, and it won't count)."  (message, line 64)

> Note for you (not shown in game): after a close call: still recovering (sv_livingcity_progress.lua)

- "Recovering from a close call (%d:%02d): a little less to give"  (message, line 96)

> Note for you (not shown in game): the urge (parasites): a line under the needs while it's building

- "You need a toilet. NOW."  (drawn on screen, line 104)
- "Your stomach cramps: find a toilet."  (text, line 104)
- "Your stomach's unsettled."  (text, line 104)

## cl_livingcity_rp.lua (cl_livingcity_rp.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_rp.lua`


> Note for you (not shown in game): What they look like, to someone who doesn't know them.

- "A shackled vortigaunt"  (text, line 45)

> Note for you (not shown in game): part of: description

- "in Resistance gear"  (text, line 48)
- "in Union blue"  (text, line 48)
- "A {who} {clothes}"  (text, line 49)

> Note for you (not shown in game): on screen

- "Bleeding out: %d:%02d"  (message, line 63)
- "Someone can help you up (E on you). You can still whisper. !giveup to let go."  (text, line 65)
- "Down, bleeding out (%ds). E to help them up. !drag to drag them."  (message, line 81)

## the scanner link, as the pilot sees it, and scanner reports, (cl_livingcity_scanner.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_scanner.lua`


> Note for you (not shown in game): the readout, top centre, like the mask's

- "CUSTODY: {now}     PHOTO RANGE: {range} FT"  (drawn on screen, line 97)

> Note for you (not shown in game): on screen

- "WASD fly   SPACE up   CTRL down   SHIFT faster   LMB flash / photograph   R disconnect"  (drawn on screen, line 153)
- "Flash a Civil Protection unit: more time.  Photograph a suspect up close: Civil Standing, never time off."  (drawn on screen, line 156)

> Note for you (not shown in game): a jammer nearby: the radio's static (sv_livingcity_convoy.lua)

- "A jammer is close. Find it (it beeps) and press E to smash it."  (text, line 251)

> Note for you (not shown in game): on screen

- "SCANNER: {GetNW2String}"  (text, line 260)
- "%dm  %ds"  (message, line 262)

## cl_livingcity_screens.lua (cl_livingcity_screens.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_screens.lua`


> Note for you (not shown in game): paging and closing, always at the bottom

- "< Previous page"  (text, line 80)
- "Next page >"  (text, line 81)

> Note for you (not shown in game): drawn in the world

- "Aim at a button and press E"  (drawn on screen, line 178)

## cl_livingcity_slots.lua (cl_livingcity_slots.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_slots.lua`


> Note for you (not shown in game): part of: paint

- "Slot {i}: empty"  (drawn on screen, line 45)
- "Someone new: a name, a face, nothing to their name."  (drawn on screen, line 46)
- "%s credits   \|   standing %s%s"  (message, line 52)
- "\|   playing now"  (message, line 53)
- "%d close call%s left"  (message, line 55)
- "No close calls left: the next death is the end"  (drawn on screen, line 55)

> Note for you (not shown in game): part of: card

- "Retire them"  (label or button, line 68)

> Note for you (not shown in game): part of: do click

- "Retire {or}? They leave the city for good, and somebody new takes their place. The new person inherits a little of their savings."  (text, line 71)
- "Retire character"  (text, line 72)
- "Keep playing"  (text, line 73)

> Note for you (not shown in game): part of: card

- "Play as them"  (label or button, line 80)
- "Start someone new"  (label or button, line 80)

> Note for you (not shown in game): part of: do click

- "Delete {or}? Everything they had goes with them."  (text, line 92)
- "Delete character"  (text, line 92)

> Note for you (not shown in game): the game answering something done in a window (lc_slots)

- "Your characters"  (window title, line 104)
- "Lives lived: %d.  Longest: %dh %02dm%s.%s"  (message, line 116)
- "({longestName})"  (text, line 116)
- "You can't switch right now: {why}"  (label or button, line 123)

## cl_livingcity_staff.lua (cl_livingcity_staff.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_staff.lua`


> Note for you (not shown in game): part of: show

- "Pick a ticket."  (text, line 83)
- "claimed by {or}"  (text, line 84)
- "{or}: {or}"  (text, line 86)
- "Go to"  (text, line 90)
- "Reply (Enter to send)"  (text, line 96)

> Note for you (not shown in game): part of: tickets tab

- "Tickets ({open} open)"  (text, line 111)

> Note for you (not shown in game): part of: logs tab

- "Search (a name, a word, a SteamID)"  (text, line 128)

> Note for you (not shown in game): part of: players tab

- "Go to"  (text, line 171)

> Note for you (not shown in game): btn

- "Warn {name}"  (text, line 173)

> Note for you (not shown in game): part of: players tab

- "Ban character"  (text, line 174)

> Note for you (not shown in game): btn

- "Ban {or}"  (text, line 175)
- "The character is wiped and their name can't be used again. Why?"  (text, line 175)

> Note for you (not shown in game): part of: players tab

- "Players ({or})"  (text, line 179)

> Note for you (not shown in game): part of: warnings tab

- "No warnings."  (text, line 185)
- "Strike off"  (label or button, line 195)

> Note for you (not shown in game): part of: bans tab

- "No characters banned."  (text, line 204)
- "%s  %s (%s), player %s: %s  (by %s)"  (message, line 210)
- "Character bans"  (text, line 217)

> Note for you (not shown in game): Open tickets, for staff, under the clock

- "open ticket"  (text, line 258)
- "open tickets"  (text, line 258)

> Note for you (not shown in game): on screen

- "Warning %d, from %s"  (message, line 282)

## cl_livingcity_talk.lua (cl_livingcity_talk.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_talk.lua`


> Note for you (not shown in game): the game answering something done in a window (lc_talk)

- "No work"  (text, line 50)
- "They're {mood}."  (label or button, line 57)
- "They wait for you to say something."  (label or button, line 65)
- "Chat (what have they heard?)"  (button, line 79)
- "Share some food"  (button, line 80)
- "Ask them to keep watch for us (a lookout)"  (button, line 81)
- "Pick their pocket (Guile)"  (button, line 82)
- "Inform on them to Civil Protection"  (button, line 83)

## cl_livingcity_unittools.lua (cl_livingcity_unittools.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_unittools.lua`


> Note for you (not shown in game): part of: open unit tools

- "[Unit tools]"  (chat message, line 47)
- "For Civil Protection (the Overwatch included)."  (chat message, line 47)

> Note for you (not shown in game): part of: paint

- "Sociostability %s     BOLOs out: %d"  (message, line 66)

> Note for you (not shown in game): part of: open unit tools

- "Call for backup"  (button, line 124)
- "The nearest Civil Protection units come to you, and see where you are."  (button, line 124)
- "Send my 10-20"  (button, line 125)
- "Marks where you are on every Civil Protection unit's screen."  (button, line 125)
- "Something for every Civil Protection unit to look out for: a face, clothes, a name."  (button, line 126)

> Note for you (not shown in game): button

- "What should Civil Protection units look out for?"  (text, line 128)

> Note for you (not shown in game): part of: open unit tools

- "Open the records terminal"  (button, line 132)
- "Citizens by name and number: record, loyalty, violations. BOLOs, and requests citizens sent in."  (button, line 132)
- "Your boot"  (text, line 134)
- "Doors swing open, locked ones give on the second kick; people are knocked back. Key: {or} (lc_kick_key)."  (button, line 135)
- "Your mask"  (text, line 138)
- "Voice lines"  (button, line 139)
- "Pick a line and the mask says it (saying the words in chat works too)."  (button, line 139)
- "In front of you"  (text, line 141)
- "Search them"  (button, line 144)
- "Pat them down for contraband (your baton's reload does it too)."  (button, line 144)
- "Uncuff them"  (button, line 146)
- "Let their hands go."  (button, line 146)
- "Drag them along / let go"  (button, line 147)
- "Walk them where you're going."  (button, line 147)
- "Cuff them"  (button, line 149)
- "Their hands up, down, stopped by a Civil Protection unit, or from behind."  (button, line 149)
- "Escort them"  (button, line 152)
- "A worker on a job behind Combine doors: they go through with you."  (button, line 152)
- "Take their microphone"  (button, line 155)
- "If they have one: no more pirate broadcasts."  (button, line 155)
- "Your baton: left click strikes, right click arrests, reload searches."  (text, line 157)
- "Look at someone up close, then open Unit tools, to search, tie or drag them."  (text, line 159)
- "Your baton: left click strikes, right click arrests, reload searches."  (text, line 160)
- "Scanner Operator"  (text, line 164)
- "Fly a scanner"  (button, line 165)
- "From a Combine console, a data terminal, or anywhere in the Nexus. Photographs earn XP; rebels go out as BOLOs."  (button, line 165)
- "Overwatch Commander"  (text, line 170)
- "next squad in %d:%02d"  (message, line 170)
- "a squad is ready"  (text, line 170)
- "Call in a squad"  (button, line 171)
- "A dropship lands an Overwatch squad at the landing zone nearest you. One every fifteen minutes."  (button, line 171)
- "Deploy a turret here"  (button, line 175)
- "At a checkpoint: near a power bank or a forcefield."  (button, line 175)
- "Put up a power bank"  (button, line 176)
- "Officers. On the wall you're facing; it powers turrets and forcefields near it."  (button, line 176)
- "Hand back my escort"  (button, line 182)
- "You're escorting {or}. Another Civil Protection unit takes over."  (button, line 182)
- "Escort {Nick}"  (button, line 185)
- "A Union worker on a job ({why})."  (button, line 185)
- "Nobody's waiting for an escort."  (text, line 187)
- "Post office"  (text, line 189)
- "Read the mail"  (button, line 190)
- "At the post office: open citizens' letters, looking for contraband and conspiracy."  (button, line 190)
- "Green, yellow or red sets how hard the city is policed; auto lets the city's mood decide."  (text, line 206)
- "Your work"  (text, line 208)
- "My directives (F3)"  (button, line 209)
- "What Overwatch wants done: patrols, stops, arrests, for XP and rank."  (button, line 209)

## cl_livingcity_view.lua (cl_livingcity_view.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_view.lua`


> Note for you (not shown in game): the console command lc_bob_toggle

- "[Living City]"  (chat message, line 38)
- "The camera sways with your steps again. (!bob keeps it still.)"  (chat message, line 38)
- "The camera holds still now. (!bob brings the sway back.)"  (chat message, line 39)

> Note for you (not shown in game): part of: calc view

- "[Living City] camera: '{name}' failed and is off until you rejoin: {err} /"  (text, line 74)

## cl_livingcity_war.lua (cl_livingcity_war.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_war.lua`

- "The Combine doesn't patrol here. Civil Protection units get shot at."  (text, line 23)
- "Infested ground. Nobody comes back the same."  (text, line 24)
- "More inspections and raids, ration cuts. Black market cheaper."  (text, line 95)
- "The rebels are quiet. Black market prices are up."  (text, line 96)
- "Nobody holds the upper hand."  (text, line 97)

> Note for you (not shown in game): part of: draw control bar

- "Combine %d%%   Resistance %d%%   Infested %d%%   \|   %s"  (message, line 114)

> Note for you (not shown in game): part of: pot label

- "Empty pot"  (text, line 259)
- "Plant a seed packet (E)"  (text, line 259)
- "Ripe vegetables"  (text, line 260)
- "Ripe in %d:%02d"  (message, line 262)

> Note for you (not shown in game): on screen

- "%d meal%s stored"  (message, line 277)
- "Step in and they'll open fire."  (text, line 363)
- "You're inside. They will shoot."  (text, line 367)

## cl_livingcity_ways.lua (cl_livingcity_ways.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_ways.lua`


> Note for you (not shown in game): part of: open ways

- "Ways to get by"  (window title, line 33)
- "Show me"  (label or button, line 56)

## cl_livingcity_writing.lua (cl_livingcity_writing.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_writing.lua`


> Note for you (not shown in game): part of: open writer

- "What do you want to write? (up to 600 characters)"  (text, line 70)
- "Sign it with your name"  (label or button, line 78)
- "Leave it here"  (text, line 93)
- "Put it up on the wall"  (text, line 93)
- "Keep it"  (text, line 93)

> Note for you (not shown in game): the game answering something done in a window (lc_read)

- "Take it"  (text, line 151)
- "Tear it down"  (text, line 152)
- "Leave it here"  (text, line 154)
- "Put it up"  (text, line 155)

> Note for you (not shown in game): post it to someone (sv_livingcity_mail.lua): at the post office

- "Send as a letter"  (label or button, line 162)

> Note for you (not shown in game): the game answering something done in a window (lc_read)

- "Tear it up"  (text, line 171)

> Note for you (not shown in game): On a city screen (lc_screen): the latest broadcast, until there's another.

- "Compliance is its own reward. Your cooperation is noted."  (text, line 213)

> Note for you (not shown in game): part of: draw law board

- "Press E to read"  (drawn on screen, line 249)

> Note for you (not shown in game): the game answering something done in a window (lc_laws)

- "The city's laws"  (window title, line 267)
- "A new law (Enter to add). Edit one above and press Enter to change it."  (text, line 301)

> Note for you (not shown in game): Civil Protection reads the mail (sv_livingcity_mail.lua)

- "The mail, waiting to go out"  (window title, line 316)

> Note for you (not shown in game): the game answering something done in a window (lc_mail_list)

- "Nothing waiting."  (label or button, line 325)
- "To %s, posted by %s%s"  (message, line 336)
- "(signed "{sig}")"  (text, line 336)
- "Confiscate it"  (label or button, line 345)

## sv_livingcity.lua (sv_livingcity.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity.lua`


> Note for you (not shown in game): part of: error

- "[Living City] {where}: {err} /"  (text, line 99)

> Note for you (not shown in game): part of: say

- "[Living City] {msg}"  (chat message, line 190)

> Note for you (not shown in game): only trust the zones if the main area is a real share of the map

- "%d of %d ground nodes, in the main connected area%s"  (message, line 492)

> Note for you (not shown in game): part of: read nodegraph

- "(%d walkable links, routes planned over them)"  (message, line 493)

> Note for you (not shown in game): part of: handle moving

- "engine found no path"  (text, line 674)
- "no progress"  (text, line 677)
- "took too long"  (text, line 678)

> Note for you (not shown in game): part of: served at

- "had their ration and went home"  (text, line 938)

> Note for you (not shown in game): Stuck NPCs are logged a few at a time, then summarized, so they don't push everything else out of the debug report.

- "...and %d more stuck NPCs moved in the last minute (%s)"  (message, line 1059)

> Note for you (not shown in game): Someone who isn't getting anywhere. If nobody's watching and the place they were heading for is close (a prop in the way, a doorframe), they're quietly put there. A far one isn't: popping people across the map is worse than the trip being given up, so they give it up, and that place is remembered as hard to reach so it isn't picked again straight away.

- "no progress"  (text, line 1074)
- "no progress"  (text, line 1074)

> Note for you (not shown in game): nobody's looking and it's just a step away: put them there. Not someone a quest has you chasing or following, though: they'd seem to go through walls.

- "%s stuck near %s (%s), moved on to hop %d/%d (%s)"  (message, line 1084)
- "no progress"  (message, line 1085)

> Note for you (not shown in game): part of: recover

- "%s removed after %d recoveries near %s"  (message, line 1097)

> Note for you (not shown in game): part of: register

- "their time out was up (lc_citizen_lifetime: a citizen stays about that long, then others come)"  (text, line 1248)

> Note for you (not shown in game): part of: choose citizen task

- "curfew or lockdown: gone home"  (text, line 1635)

> Note for you (not shown in game): more people out than the hour calls for: home (sv_livingcity_rhythm.lua)

- "the time of day: fewer people out at this hour"  (text, line 1640)

> Note for you (not shown in game): part of: cop provoked

- "[Civil Protection] The Civil Protection unit shoves you back. Move along."  (chat message, line 2016)
- "[Civil Protection] A crack across the ribs with the stick. Last warning."  (chat message, line 2017)
- "[Civil Protection] You were warned. Obstructing Civil Protection."  (chat message, line 2021)
- "Obstructing Civil Protection"  (text, line 2022)

> Note for you (not shown in game): A city scanner that has a fugitive in sight (wanted, or a hunted rebel who isn't passing as a citizen) tells the units where they are: a flash, a report to every unit on duty, and the nearby units come after them.

- "a wanted citizen"  (text, line 2178)

> Note for you (not shown in game): part of: scanner tip off

- "A scanner's flash. You've been photographed, and Civil Protection has the picture."  (chat message, line 2183)
- "[CP net] Scanner report: %s%s."  (message, line 2187)

> Note for you (not shown in game): part of: start

- "This map has no AI nodes or navmesh and nothing placed yet. Lay some path nodes or points with the Living City Editor, then start again."  (chat message, line 2418)
- "Started. Map nav: %d spots (%s). Your layout: %d points, %d path nodes."  (message, line 2425)

> Note for you (not shown in game): part of: stop

- "Stopped and removed all Living City NPCs."  (chat message, line 2442)

> Note for you (not shown in game): part of: spawn test walker

- "your path network (%d hops)"  (message, line 2471)
- "the map's own navigation"  (text, line 2471)
- "Test walker heading out using {how}."  (chat message, line 2472)

> Note for you (not shown in game): part of: test arrived

- "Test walker arrived in %.1f seconds. This route works."  (message, line 2477)

> Note for you (not shown in game): part of: test stuck

- "Test walker stuck at %s on hop %d/%d"  (message, line 2484)
- "Test walker got stuck after %.1f seconds, on hop %d of %d (marked red)."  (message, line 2485)
- "Add a path node here and link it toward the destination, or check for a door it can't open."  (text, line 2488)

> Note for you (not shown in game): guarding a supply drop (sv_livingcity_convoy.lua): he answers, without leaving his post

- "[Civil Protection] "Supply point secure. Hold the perimeter until the load moves on.""  (chat message, line 2712)

> Note for you (not shown in game): pressing E on something

- "[Civil Protection] "{Pick}""  (chat message, line 2716)

> Note for you (not shown in game): a Civil Protection player stops a citizen: they freeze and apologise

- "[Civil Protection] Stopped. With the Arrest Baton out: R to search them, right click to detain."  (chat message, line 2733)

> Note for you (not shown in game): a crime, and every cop comes for you (a scanner is city property, not a person) (one report per few seconds for a scanner: every bullet of a burst isn't a new offence)

- "Damaging city property"  (text, line 2783)
- "Assaulting Civil Protection"  (text, line 2786)
- "Assaulting a citizen"  (text, line 2786)

> Note for you (not shown in game): Console commands

- "Civil Protection has stood down."  (chat message, line 2822)

> Note for you (not shown in game): the console command lc_addpoint

- "Kinds: idle, sit, sitchair, lean, queue, patrol, checkpoint, spawn, cell, release"  (chat message, line 2829)
- "Added %s point (%d total on this map)."  (message, line 2832)

> Note for you (not shown in game): the console command lc_removepoint

- "Removed nearest {kind} point."  (text, line 2838)
- "No point within 150 Civil Protection units."  (chat message, line 2838)

> Note for you (not shown in game): the console command lc_status

- "citizens %d/%d, cops %d/%d, soldiers %d/%d, scanners %d/%d, zombies %d/%d, rebels %d/%d"  (message, line 2849)
- "map nav %d (%s) \| points %d \| path nodes %d, links %d, unlinked %d \| zones %d \| lines %d \| patrol beats %d"  (message, line 2853)

## the actions menu (server side) (sv_livingcity_actions.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_actions.lua`


> Note for you (not shown in game): the game answering something done in a window (lc_interrogate_reply)

- "[Interrogation] You say nothing."  (chat message, line 133)

## acts (server). See sh_livingcity_acts.lua for the list (sv_livingcity_acts.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_acts.lua`


> Note for you (not shown in game): part of: start act

- "Acts are off on this server."  (text, line 23)
- "No such pose."  (text, line 25)
- "Not with your hands cuffed."  (text, line 27)
- "Get your feet on the ground first."  (text, line 29)
- "Stand still first."  (text, line 30)
- "(This model has no animation for that, but you hold still.)"  (chat message, line 43)

> Note for you (not shown in game): the chat command /act

- "Poses: /sit /kneel /lie /lean /cower /pose 1-4 (/stand to get up). Gestures: /wave /salute /bow /nod /shake /point /beckon /halt /cheer /laugh"  (chat message, line 93)

## testing tools for admins (sv_livingcity_admintools.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_admintools.lua`


> Note for you (not shown in game): Everything the panel can do. Returns ok, and a line to tell the admin.

- "That faction has no ranks to climb."  (text, line 53)
- "by staff"  (text, line 56)

> Note for you (not shown in game): part of: rank

- "That faction has no ranks."  (text, line 62)
- "%s ranks go from 1 to %d."  (message, line 63)
- "by staff"  (text, line 66)
- "%s is now %s (%d XP)."  (message, line 67)

> Note for you (not shown in game): part of: resetxp

- ": XP back to 0 in every faction."  (text, line 71)

> Note for you (not shown in game): part of: credits

- "The economy is off."  (text, line 74)

> Note for you (not shown in game): part of: resetcredits

- ": credits back to 0."  (text, line 80)

> Note for you (not shown in game): part of: standing

- "The economy is off."  (text, line 83)
- "%s: Civil Standing %d."  (message, line 85)

> Note for you (not shown in game): part of: setstanding

- "The economy is off."  (text, line 88)
- "%s: Civil Standing %d."  (message, line 90)

> Note for you (not shown in game): part of: resetme

- ": XP, credits and standing all back to 0."  (text, line 96)

> Note for you (not shown in game): part of: faction

- "No such faction."  (text, line 100)
- "is now {name}."  (text, line 102)

> Note for you (not shown in game): part of: clearwanted

- "is no longer wanted."  (text, line 108)

> Note for you (not shown in game): part of: pardon

- "No conduct tracking here."  (text, line 111)
- ": conduct strikes cleared."  (text, line 113)

> Note for you (not shown in game): part of: needs

- ": fed, watered, healed."  (text, line 119)

> Note for you (not shown in game): the city, not the player: a city-wide blackout (sv_livingcity_power.lua)

- "No power grid here."  (text, line 123)
- "City-wide blackout: {or}{or}."  (text, line 125)
- "No such item."  (text, line 129)

> Note for you (not shown in game): part of: item

- "'s pockets are full."  (text, line 130)

> Note for you (not shown in game): part of: admin tool

- "Admins only."  (text, line 137)
- "Nobody to do that to."  (text, line 139)
- "Unknown action."  (text, line 141)
- "That failed: {a}"  (text, line 143)
- "admin tools: %s used %s %s on %s"  (message, line 145)

> Note for you (not shown in game): the console command lc_admintools

- "Admins only."  (chat message, line 177)

> Note for you (not shown in game): the game answering something done in a window (lc_admintools_do)

- "[Admin tools] {msg}"  (chat message, line 185)

> Note for you (not shown in game): typing in chat

- "Admins only."  (chat message, line 204)
- "Admins only."  (chat message, line 209)
- "Usage: !{cmd} <number> [player]"  (chat message, line 214)
- "Player not found: {name}"  (chat message, line 221)
- "[Admin tools] {msg}"  (chat message, line 224)

## custom announcements, for Overwatch and for the Administrator (sv_livingcity_announcer.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_announcer.lua`

- "Morning exercise"  (text, line 153)
- "Morning exercise"  (text, line 153)
- "Morning parade"  (text, line 153)
- "Power failure"  (text, line 154)
- "Power restored"  (text, line 154)
- "Overwatch response"  (text, line 154)
- "Overwatch response"  (text, line 155)
- "Prison breakout"  (text, line 155)
- "Overwatch deployment"  (text, line 155)
- "Housing block inspection"  (text, line 156)
- "Resistance activity"  (text, line 156)
- "City announcement"  (text, line 157)
- "City announcement"  (text, line 157)
- "City announcement"  (text, line 157)
- "City announcement"  (text, line 157)
- "City announcement"  (text, line 158)
- "Overwatch response"  (text, line 158)

> Note for you (not shown in game): part of: announce unused

- ": doesn't start with a trigger (a typo?)"  (text, line 224)
- ": {t} is no longer said (a surprise, or it answers violence)"  (text, line 226)
- ": plays as Overwatch (a tone word only means something to the Administrator: is this her recording?)"  (text, line 228)

> Note for you (not shown in game): part of: say

- "[{or}] "{text}""  (chat message, line 385)
- "[{or}] "{text}""  (chat message, line 401)

> Note for you (not shown in game): a timer (regularly)

- "Sound files"  (on-screen notice, line 568)
- "recording(s) can't be played (an MP3 renamed .wav, or a WAV that isn't 16-bit 44100 Hz). Type lc_announce_clips in the console to see which, and how to fix each."  (on-screen notice, line 568)

> Note for you (not shown in game): the console command lc_announce_clips

- "[Living City] {v}: {or}"  (text, line 595)
- "[Living City]   check {v}/{why}"  (text, line 596)
- "[Living City]   CAN'T PLAY {why}"  (text, line 599)
- "[Living City] {v}: {parts}"  (text, line 607)
- "[Living City] Players' computers play these, so each needs the files: {or}sv_allowdownload {or}, sv_downloadurl "{or}" (a Workshop addon is the reliable way). Each player can type lc_sound_check to test their own."  (text, line 610)
- "[Living City] {total} custom announcements found. Folders: sound/livingcity/overwatch/, administrator/, radio/ (or the same under sound/{ROOT}), flat: a file's name starts with its trigger (curfew1.wav), and the Administrator's tone is in it (curfew_firm1.wav); lc_announce_rescan after adding files."  (text, line 614)

> Note for you (not shown in game): the console command lc_announce_rescan

- "[Living City] {AnnounceRescan} custom announcements found."  (text, line 619)

> Note for you (not shown in game): the console command lc_announce_say

- "[Living City] lc_announce_say <overwatch\|administrator> <trigger> [warm\|firm\|stern\|furious]"  (text, line 625)
- "[Living City] Nothing in sound/{ROOT}{voice}/{trig}/ to say (or it's off)."  (text, line 628)

> Note for you (not shown in game): the console command lc_announce_tier

- "[Living City] {trig}: she would be {t} about it now (sociostability {or}, {Heat} violent things in ten minutes){or}."  (text, line 636)

## the time of day, the weather, and the city's music (sv_livingcity_atmos.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_atmos.lua`


> Note for you (not shown in game): part of: set weather

- "It starts to rain."  (text, line 123)
- "A storm rolls in over the city."  (text, line 123)
- "Fog comes down over the streets."  (text, line 123)
- "The sky clouds over."  (text, line 124)
- "The sky clears."  (text, line 124)

> Note for you (not shown in game): typing in chat

- "It's %s, %s. The weather: %s."  (message, line 226)

## the dead (sv_livingcity_bodies.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_bodies.lua`


> Note for you (not shown in game): Searching

- "Nothing on them."  (chat message, line 251)

> Note for you (not shown in game): part of: take loot

- "a health vial"  (text, line 277)
- "Your pockets are full."  (chat message, line 287)
- "Nothing left on them."  (chat message, line 287)
- "You search the body: {found}.{or}"  (chat message, line 289)

> Note for you (not shown in game): part of: start body search

- "You've already been through their pockets."  (text, line 297)
- "You go through their pockets..."  (chat message, line 303)

> Note for you (not shown in game): doing this in front of a unit is a crime (unless you are one)

- "Robbing the dead"  (text, line 306)
- "Looting a dead officer"  (text, line 306)

## apartments and trade (sv_livingcity_business.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_business.lua`


> Note for you (not shown in game): What this person pays for a rent period, and why it's free if it is.

- "Civil Protection housing: no rent for a unit"  (text, line 43)
- "rent-free, for a citizen of your standing"  (text, line 45)

> Note for you (not shown in game): part of: hm

- "%dh %02dm"  (message, line 165)

> Note for you (not shown in game): Why this person can't rent this door right now (nil if they can).

- "Someone already lives here."  (text, line 171)
- "You already rent somewhere. !unrent it first."  (text, line 172)
- "It's paid up for as long as the landlord will take."  (text, line 173)
- "The rent is %d credits."  (message, line 174)

> Note for you (not shown in game): part of: rent

- "Look at an apartment door that's for rent."  (text, line 180)
- "%s It's yours for %s more."  (message, line 191)
- "No charge: {free}."  (text, line 191)

> Note for you (not shown in game): the other half of a double door comes with it

- "It's yours for %s%s. Locked to everyone but you. !givekey <name> to let someone in."  (message, line 203)

> Note for you (not shown in game): part of: unrent

- "You don't rent anywhere."  (text, line 208)
- "You've moved out."  (text, line 214)

> Note for you (not shown in game): part of: set apartment lock

- "Look at your apartment door."  (text, line 220)
- "You don't have a key."  (text, line 221)
- "Unlocked: anyone can come in."  (text, line 226)

> Note for you (not shown in game): part of: give key

- "You don't rent anywhere."  (text, line 231)

> Note for you (not shown in game): or the person in front of you

- "Who? Name them, or look at them."  (text, line 238)

> Note for you (not shown in game): part of: give key

- "[Living City] {OwnerName} gave you a key to their apartment."  (chat message, line 243)
- "[Living City] {OwnerName} took back the key to their apartment."  (chat message, line 246)
- "You gave {target} a key."  (text, line 249)
- "You took {target}'s key back."  (text, line 249)

> Note for you (not shown in game): part of: apartment info

- "You don't rent anywhere, but you have keys to: {keys}'s."  (text, line 257)
- "You don't rent anywhere. Look at an apartment door that's for rent and !rent."  (text, line 258)
- "Your apartment, %s: %s left, %s. Keys: %s."  (message, line 265)
- "just you"  (message, line 266)

> Note for you (not shown in game): locked is locked, for the one with the key too: the handle rattles. Unlock it first (right click it with your hands out, or !unlock)

- "[Living City] It's locked. Unlock it first: right click it with your hands out (or !unlock)."  (chat message, line 288)

> Note for you (not shown in game): part of: rent door use

- "Forcing the door..."  (progress bar, line 295)
- "You stop."  (text, line 296)

> Note for you (not shown in game): part of: done

- "[Living City] Civil Protection forced the door of {or}'s apartment."  (chat message, line 305)

> Note for you (not shown in game): part of: rent door use

- "Locked. (Someone lives here.)"  (chat message, line 314)

> Note for you (not shown in game): a timer (regularly)

- "[Living City] Your rent ran out. The apartment isn't yours any more."  (chat message, line 329)
- "[Living City] Your rent runs out in 10 minutes. Look at the door, F1 > Rent / lock this door to pay more."  (chat message, line 335)

> Note for you (not shown in game): part of: hands right click

- "Someone lives here."  (chat message, line 370)

> Note for you (not shown in game): the game answering something done in a window (lc_rent_confirm)

- "Someone already lives here."  (chat message, line 379)

> Note for you (not shown in game): Licenses An officer takes a trader's license away; their stalls close.

- "Officers only."  (text, line 390)
- "They're not in the city right now."  (text, line 391)
- "Business license revoked"  (text, line 395)
- "[Civil Workers' Union] Your business license has been revoked. Your stalls are closed."  (chat message, line 396)

> Note for you (not shown in game): part of: revoke license

- "'s license is revoked."  (text, line 397)
- "They had no license; their stalls are closed."  (text, line 397)

## rearranging a rebel camp (sv_livingcity_campmove.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_campmove.lua`


> Note for you (not shown in game): (set down on the floor, never in it)

- "[Camp] Set down. (It'll be here next time too.)"  (chat message, line 115)

> Note for you (not shown in game): part of: camp pick up

- "Moving it"  (on-screen notice, line 135)
- "It goes where you look. Let go of E to set it down; R turns it."  (on-screen notice, line 135)

## characters and permanent death (sv_livingcity_character.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_character.lua`


> Note for you (not shown in game): part of: assign

- "[Living City] You are %s, citizen %s."  (message, line 127)

> Note for you (not shown in game): a character who hasn't been chosen yet gets to choose

- "[Living City] You are %s, citizen %s. If you die, that person is gone."  (message, line 151)

> Note for you (not shown in game): Told once they're back on their feet.

- "[Living City] %s is dead. You are %s, citizen %s. You start over with nothing."  (message, line 215)

> Note for you (not shown in game): (lcEndOfLife: an ending that is final whatever the setting, like a stalker stepping into the light)

- "Permanent death is off here: you come back as yourself."  (text, line 227)
- "[Living City] You died in build mode, so you keep this character. C > Help > Build mode to leave build mode and play for real."  (chat message, line 231)
- "Build mode: you keep this character."  (text, line 232)

> Note for you (not shown in game): someone dying

- "The infestation doesn't let go. You come back as you were."  (text, line 236)
- "[Living City] You died in custody. That doesn't change who you are, or how long you're in for."  (chat message, line 240)
- "Died in custody: you're still you, and still serving your time."  (text, line 241)

> Note for you (not shown in game): a close call, unless this one is the end of them (sv_livingcity_progress.lua)

- "A close call: %d left."  (message, line 247)
- "A close call: the last one."  (text, line 247)

> Note for you (not shown in game): Whole words that are never fine in a name.

- "Choose a realistic name for a person living in this city and era: an ordinary name, first and last if you like. No celebrities, characters from games, films or shows, memes or joke names."  (text, line 299)

> Note for you (not shown in game): Returns true, the cleaned-up name; or false, why not.

- "Names are between 3 and 26 characters long."  (text, line 311)
- "Names use letters only: no numbers or symbols."  (text, line 312)
- "A name is one to three words: a first name, and a surname if you like."  (text, line 315)

> Note for you (not shown in game): part of: validate character name

- "Each part of your name needs at least two letters."  (text, line 318)
- "That doesn't read like a real name."  (text, line 319)
- "That doesn't read like a real name."  (text, line 320)
- "That name isn't allowed. {REMINDER}"  (text, line 322)
- "That name looks like a celebrity, a character or a joke. {REMINDER}"  (text, line 328)

> Note for you (not shown in game): opts.intake: the registration form at a Civil Intake terminal (sv_livingcity_intake.lua): nothing filled in for you, a description to give, no "keep what I was given". opts.asked: they asked for it (!character), so say why not if it's not now.

- "[Civil Intake] Who you are goes on your registration form, at the Civil Intake terminal."  (chat message, line 372)

> Note for you (not shown in game): the game answering something done in a window (lcc_submit)

- "One moment."  (text, line 392)

> Note for you (not shown in game): a new name and face is no way out of trouble

- "Not while you're wanted or in custody."  (text, line 396)

> Note for you (not shown in game): the game answering something done in a window (lcc_submit)

- "Choose one of the faces shown."  (text, line 403)
- "Someone in the city already has that name."  (text, line 406)
- "That person can't come back. Choose another name."  (text, line 407)
- "[Living City] You are %s, citizen %s."  (message, line 420)

> Note for you (not shown in game): the console command lc_setname

- "[Living City] Staff changed your name to {name}."  (chat message, line 460)

## checkpoints, turrets, and holding the infestation back (sv_livingcity_checkpoints.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_checkpoints.lua`


> Note for you (not shown in game): part of: containment breach

- "[City] Containment failure{or}! The infected are breaking out."  (chat message, line 287)
- "Dispatch: containment breach{or}. All Civil Protection units, hold the line."  (text, line 289)

> Note for you (not shown in game): part of: deploy turret

- "Civil Protection units only."  (text, line 402)
- "Give it a moment."  (text, line 403)
- "You've got {GetInt} turrets up already. Pack one up first (E on it)."  (text, line 405)
- "Look at the ground in front of you, close by."  (text, line 409)
- "Not enough room there."  (text, line 414)
- "No power here: turrets go up near a Combine power bank."  (text, line 419)
- "That power bank is feeding %d things already (turrets and forcefields): put up another bank."  (message, line 421)
- "No power here: turrets go up at a checkpoint, near a Combine power bank or a forcefield."  (text, line 426)
- "That checkpoint is powering all the turrets it can."  (text, line 430)
- "The turret won't deploy."  (text, line 433)
- "Turret deployed, cabled to the {or}. It goes quiet if the power does."  (text, line 440)

> Note for you (not shown in game): part of: pack turret

- "Civil Protection units only."  (text, line 445)
- "Look at a turret a Civil Protection unit put up."  (text, line 446)
- "Get closer."  (text, line 447)
- "You fold the turret up and take it with you."  (text, line 450)

> Note for you (not shown in game): Officers put up a power bank: on the wall they're looking at.

- "Officers put up power banks (Division Leader and up). Any Civil Protection unit can deploy turrets at one."  (text, line 456)
- "You've one up already. Take it down first (the actions menu, looking at it)."  (text, line 458)

> Note for you (not shown in game): part of: deploy power bank

- "Look at a wall, close by."  (text, line 462)
- "It won't go up."  (text, line 465)
- "Power bank up. Turrets and forcefields near it run off it now."  (text, line 477)

> Note for you (not shown in game): part of: pack power bank

- "That one's the city's, not yours to take down."  (text, line 481)
- "Officers only."  (text, line 482)
- "Get closer."  (text, line 483)
- "You take the power bank down."  (text, line 487)

> Note for you (not shown in game): E on a bank: units read what it's powering. (The multitool's primary fire shorts it out.)

- "It spits sparks. Shorted out."  (text, line 495)
- "Power bank: %s. Feeding %d turret%s and %d forcefield%s (it can feed %d)."  (message, line 497)
- "DEAD (no power)"  (message, line 497)

> Note for you (not shown in game): part of: use power bank

- "It hums. A Combine power bank."  (text, line 500)
- "Dead. No power."  (text, line 500)

> Note for you (not shown in game): A multitool: eight seconds, and it's dead for two minutes, with everything on its cables.

- "You need a multitool."  (text, line 505)
- "Look at a power bank."  (text, line 506)
- "It's already dead."  (text, line 507)
- "Shorting the power bank..."  (progress bar, line 508)
- "You pull your hands back."  (text, line 509)

> Note for you (not shown in game): part of: vort zap tech

- "Combine machinery shorted out"  (text, line 552)

> Note for you (not shown in game): part of: forcefield break

- "A forcefield is broken"  (on-screen notice, line 636)
- "The forcefield {where} is broken. E on it to repair it (ten seconds, paid)."  (on-screen notice, line 636)
- "[CP net] The forcefield {where} is broken. Maintenance has been told."  (chat message, line 638)

> Note for you (not shown in game): part of: forcefield repaired

- "Forcefield repaired"  (text, line 651)
- "Forcefield repaired"  (on-screen notice, line 652)
- "It hums back up. 15 credits."  (on-screen notice, line 652)

> Note for you (not shown in game): (the city's maintenance crews normally get there first: the task at the end)

- "[CP net] City crews have repaired the forcefield {GetPos}."  (chat message, line 722)

> Note for you (not shown in game): E on a broken one: a Maintenance Technician repairs it.

- "It's broken: sparks and a dead hum. A Maintenance Technician could fix it."  (text, line 744)
- "Repairing the forcefield..."  (progress bar, line 746)
- "You leave it half done."  (text, line 747)

> Note for you (not shown in game): The city's own maintenance crews walk out and repair a broken forcefield (after the players have had their chance); the timer above is only for a city with no crew to send.

- "repairing a forcefield"  (label, line 756)

> Note for you (not shown in game): part of: find

- "repairing a forcefield"  (what someone is doing, line 771)

## weedkiller against the infestation, and against the Combine (the owner, 2026-11-01) (sv_livingcity_cleanup.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_cleanup.lua`


> Note for you (not shown in game): Weedkiller for a job that sprays (Infestation Cleanup, the Groundskeeper): issued when they take the job, again at each shift, and whenever they go to spray with none left.

- "[Union] A canister of weedkiller from your kit."  (chat message, line 137)

> Note for you (not shown in game): the game's living city job changed moment

- "[Union] You're issued a respirator, weedkiller (the sprayer) and a hoover. Accept a shift (F3): it takes you into the infestation. Civil Protection will guard you."  (chat message, line 147)

> Note for you (not shown in game): part of: clear nest

- "sprayed out"  (text, line 341)

> Note for you (not shown in game): the zone you placed is never taken away: it goes quiet for a while instead

- "[Union] That's the last of the growth here. It'll be quiet for a while, but it always comes back."  (chat message, line 347)

> Note for you (not shown in game): part of: kill nest

- "Infestation growth killed"  (text, line 363)
- "[Union] It shrivels and dies. Now vacuum it up with your hoover (hold left click on it)."  (chat message, line 364)

> Note for you (not shown in game): Spraying one: a few seconds, close up.

- "It's dead already: vacuum it up with your hoover (hold left click on it)."  (text, line 373)
- "It's dead already. The cleanup crew will take it away."  (text, line 373)
- "You'd need weedkiller to spray it (the Union Commissary sells it)."  (text, line 375)

> Note for you (not shown in game): part of: spray nest

- "Spraying the growth..."  (progress bar, line 381)
- "You stop spraying."  (text, line 381)

> Note for you (not shown in game): (held to it: nothing else sends them off, and they don't leave the city mid-job)

- "[Union] Civil Protection is sending you a guard. Stay close to them in there."  (chat message, line 500)

> Note for you (not shown in game): The city's own cleanup crews: spray the growths, with a guard.

- "clearing the infestation"  (label, line 597)

> Note for you (not shown in game): part of: find

- "spraying the infestation"  (what someone is doing, line 607)
- "vacuuming up the dead growth"  (what someone is doing, line 611)

> Note for you (not shown in game): The hoover (weapon_lc_hoover, the cleanup job's): dead growths in, emptied into an infestation control barrel (the warning post's), or, where there are none, sealed in a bag

- "It's still alive: spray it with weedkiller first (look at it, E)."  (text, line 628)

> Note for you (not shown in game): part of: vacuum nest

- "Your hoover's full: empty it into an infestation control barrel (E on one)."  (text, line 630)
- "[Union] Your hoover's full. Empty it into an infestation control barrel (E on one){or}"  (chat message, line 635)

> Note for you (not shown in game): part of: emptied

- "Infestation waste disposed of"  (text, line 651)
- "[Union] %s: %d dead growth%s disposed of."  (message, line 652)

> Note for you (not shown in game): part of: dump hoover

- "Your hoover's empty."  (text, line 657)
- "Into the barrel"  (text, line 660)

> Note for you (not shown in game): part of: bag hoover

- "Your hoover's empty."  (text, line 666)
- "There's an infestation control barrel near here: empty it into that (E on it)."  (text, line 667)
- "Sealed in a bag"  (text, line 677)

> Note for you (not shown in game): E on the barrel (entities/entities/lc_hazbarrel.lua)

- "An infestation control barrel. Empty a cleanup worker's hoover into it (E, with something in the hoover)."  (chat message, line 686)

## Half-Life: Alyx-style Combine models (sv_livingcity_combinemodels.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_combinemodels.lua`


> Note for you (not shown in game): the console command lc_combine_models_list

- "%-14s player: %-50s npc: %s"  (message, line 130)
- "(Half-Life 2's)"  (message, line 130)
- "(Half-Life 2's)"  (message, line 130)

## conduct (anti-RDM and anti-combat-logging) (sv_livingcity_conduct.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_conduct.lua`


> Note for you (not shown in game): part of: tell admins

- "[Conduct] {msg}"  (chat message, line 53)

> Note for you (not shown in game): part of: conduct summary

- "strikes {StrikeCount}"  (text, line 89)

> Note for you (not shown in game): part of: add strike

- "%s received strike %d: %s"  (message, line 98)
- "[Conduct] Strike %d of %d: %s"  (message, line 99)
- "KICK {Who} after {n} strikes"  (text, line 103)

> Note for you (not shown in game): a timer (regularly)

- "Repeated rule violations (random deathmatch / combat logging)"  (text, line 104)

> Note for you (not shown in game): part of: add strike

- "Conduct violation: {reason}"  (text, line 106)

> Note for you (not shown in game): part of: judge kill

- "server rule"  (text, line 176)
- "self defense"  (text, line 178)
- "killed another Civil Protection unit"  (text, line 186)
- "no roleplay reason found"  (text, line 188)

> Note for you (not shown in game): someone dying

- "KILL %s -> %s with %s at %du: %s (%s)"  (message, line 201)
- "killed %s with no roleplay reason (%s, %du)"  (message, line 206)
- "[Conduct] That kill has been flagged for staff. C > Help > Ask staff for help if there's more to it."  (chat message, line 207)

> Note for you (not shown in game): Combat logging

- "[Conduct] You can't do that right now."  (chat message, line 218)

> Note for you (not shown in game): someone leaving

- "%s disconnected %s. It'll be dealt with if they return."  (message, line 254)

> Note for you (not shown in game): a timer (regularly)

- "[Conduct] You left the server {why}. That counts against you."  (chat message, line 265)
- "disconnected {why}"  (text, line 266)
- "Evading arrest"  (text, line 268)

> Note for you (not shown in game): Chat and admin commands

- "[Conduct] Please wait a moment before reporting again."  (chat message, line 282)

> Note for you (not shown in game): typing in chat

- "Report from %s: %s"  (message, line 287)
- "[Conduct] Sent to staff{or}"  (chat message, line 288)

> Note for you (not shown in game): the console command lc_conduct

- "Usage: lc_conduct <name>"  (text, line 296)
- "%s has %d active strike(s)."  (message, line 298)

> Note for you (not shown in game): the console command lc_pardon

- "PARDON {target} by {or}"  (text, line 315)
- "[Conduct] Your strikes have been cleared."  (chat message, line 316)

## supply drops, radio jammers (sv_livingcity_convoy.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_convoy.lua`


> Note for you (not shown in game): part of: start supply drop

- "nowhere to put it"  (text, line 217)
- "[CP net] A supply {or}{where}. Guard the drop until it moves on. Directive on your board (F3)."  (chat message, line 233)
- "A Combine supply {or}{where}. Guns, ammunition, medicine. Lightly guarded."  (text, line 237)

> Note for you (not shown in game): part of: end supply drop

- "supply drop secured"  (text, line 285)
- "supply drop secured"  (text, line 286)
- "[CP net] The convoy moves on with %d of %d loads. Drop secured."  (message, line 290)
- "[City] A Union supply drop was looted. Anyone with information is to report it to Civil Protection."  (chat message, line 294)
- "The supply drop's empty. Good work."  (text, line 296)

> Note for you (not shown in game): E on the crate: take a load.

- "Empty, and sealed."  (text, line 316)
- "[CP net] Union supplies. Guard them until the convoy moves on."  (text, line 317)
- "You're busy."  (text, line 318)
- "Cleaned out."  (text, line 319)

> Note for you (not shown in game): part of: loot supply

- "Prying a load out of the crate... keep still"  (progress bar, line 322)
- "You leave it."  (text, line 323)

> Note for you (not shown in game): part of: done

- "Someone beat you to it."  (chat message, line 329)
- "Taken from the supply drop: {got}."  (chat message, line 338)
- "Looting Union supplies"  (text, line 341)
- "[Civil Protection] A Civil Protection unit saw you at the crate."  (chat message, line 342)
- "[CP net] The supply drop has been emptied."  (chat message, line 348)

> Note for you (not shown in game): caught at it

- "[Civil Protection] Caught with your hands in the crate."  (chat message, line 452)
- "Looting Union supplies"  (text, line 453)

> Note for you (not shown in game): part of: guard step

- "[Overwatch soldier] "Restricted supply point. Step away from the crates.""  (chat message, line 463)
- "[Overwatch soldier] "Final warning. Step away from the crates.""  (chat message, line 464)
- "[Overwatch soldier] "Noncompliance at the supply point." You're wanted."  (chat message, line 466)
- "Loitering at a Union supply drop"  (text, line 467)

> Note for you (not shown in game): Set one down from your pockets.

- "Civil Protection units don't jam their own radios."  (text, line 527)
- "You don't have a jammer."  (text, line 528)

> Note for you (not shown in game): part of: place jammer

- "[Jammer] It hisses into life. %d seconds of static for every Civil Protection unit radio within reach."  (message, line 540)
- "Operating a jamming device"  (text, line 542)
- "[Civil Protection] A Civil Protection unit saw you set it down."  (chat message, line 543)

> Note for you (not shown in game): A unit smashes it (E), or it runs out.

- "It hisses. Better not to touch it."  (text, line 552)
- "jammer destroyed"  (text, line 555)
- "[CP net] Jammer destroyed. Radio's clear."  (chat message, line 556)

## Civil Protection's toolset (sv_livingcity_cp.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_cp.lua`


> Note for you (not shown in game): part of: name of

- "Citizen {alias}"  (text, line 128)

> Note for you (not shown in game): part of: add record note

- "No such record."  (text, line 167)
- "Write something."  (text, line 169)

> Note for you (not shown in game): The city writes the record as things happen.

- "Wanted: {or}"  (text, line 177)
- "Custody, %d min: %s"  (message, line 181)

> Note for you (not shown in game): the game's living city searched moment

- "Contraband: {names}"  (text, line 193)

> Note for you (not shown in game): the game's living city escaped moment

- "Escaped custody"  (text, line 197)

> Note for you (not shown in game): Loyalty points: units award or deduct Civil Standing.

- "Civil Protection units only."  (text, line 206)
- "They're not in the city right now."  (text, line 207)
- "Not on yourself."  (text, line 208)
- "Nothing to change."  (text, line 211)

> Note for you (not shown in game): part of: adjust loyalty

- "\|{CurTime}"  (text, line 212)
- "You've already adjusted their points. Again in %ds."  (message, line 214)
- "loyalty points awarded by"  (text, line 217)
- "loyalty points deducted by"  (text, line 217)
- "Loyalty points %+d"  (message, line 219)
- "%s: %+d loyalty points."  (message, line 221)

> Note for you (not shown in game): part of: add bolo

- "Civil Protection units only."  (text, line 261)
- "Say who or what to look out for."  (text, line 263)

> Note for you (not shown in game): one every half minute (each one is a call and a sound for every unit)

- "You sent one just now. Wait %d seconds."  (message, line 266)

> Note for you (not shown in game): part of: add bolo

- "[CP net] BOLO (be on the lookout) from %s: %s%s (%d min)"  (message, line 280)

> Note for you (not shown in game): part of: clear bolo

- "Civil Protection units only."  (text, line 288)
- "[CP net] BOLO cancelled by %s: %s"  (message, line 295)
- "No such BOLO."  (text, line 299)

> Note for you (not shown in game): part of: open records

- "The records terminal is off on this server."  (chat message, line 366)
- "[Records] Access denied: this terminal is for Civil Protection only."  (chat message, line 369)
- "Civil Protection only."  (chat message, line 371)

> Note for you (not shown in game): the game answering something done in a window (lc_records_do)

- "[Records] {msg}"  (chat message, line 411)
- "[Records] {msg}"  (chat message, line 411)

> Note for you (not shown in game): part of: set hands up

- "[Living City] Hands up. (F1 > Lower my hands.)"  (chat message, line 429)

> Note for you (not shown in game): Can this person tie that one up? ok, or false and why.

- "Cuffs are off on this server."  (text, line 451)
- "Look at someone, up close."  (text, line 452)
- "Not yourself."  (text, line 453)
- "Your hands are cuffed."  (text, line 454)
- "Their hands are already cuffed."  (text, line 455)
- "They're already in custody."  (text, line 456)
- "Get closer."  (text, line 457)

> Note for you (not shown in game): part of: can tie

- "You need cuffs."  (text, line 458)
- "They'd fight you off. You can only cuff someone with their hands up, knocked down, stopped by a Civil Protection unit, or from behind."  (text, line 462)

> Note for you (not shown in game): part of: tie player

- "[Living City] Your hands are cuffed, so you can't use anything. To try to get free: F1 > Work at the cuffs, when nobody's looking."  (chat message, line 480)
- "Cuffed. Look at them and press F1 to drag them along or take the cuffs off."  (chat message, line 481)

> Note for you (not shown in game): part of: start tie

- "[Living City] Someone is putting cuffs on you."  (chat message, line 515)
- "Cuffing them..."  (progress bar, line 516)
- "You let go."  (text, line 517)

> Note for you (not shown in game): part of: done

- "They got away from you."  (chat message, line 520)

> Note for you (not shown in game): part of: start untie

- "Look at someone whose hands are cuffed, up close."  (text, line 530)
- "Your own hands are cuffed."  (text, line 531)
- "[Living City] A Civil Protection unit takes your cuffs off."  (chat message, line 534)
- "Uncuffing them..."  (progress bar, line 537)
- "You stop."  (text, line 538)

> Note for you (not shown in game): part of: done

- "[Living City] Someone gets your cuffs off. You're free."  (chat message, line 542)

> Note for you (not shown in game): part of: start struggle

- "Your hands aren't cuffed."  (text, line 560)
- "Not while they've got hold of you."  (text, line 561)
- "Working at the cuffs..."  (progress bar, line 562)
- "You stop working at the cuffs."  (text, line 563)

> Note for you (not shown in game): part of: done

- "[Living City] They see you working at the cuffs, and tighten them."  (chat message, line 568)
- "[Living City] The cuffs give. Your hands are free."  (chat message, line 572)

> Note for you (not shown in game): !drag on someone tied: walk them along. Returns nil when it's not about a tied person.

- "You let go of them."  (chat message, line 582)

> Note for you (not shown in game): part of: try escort

- "Your hands are cuffed."  (text, line 588)
- "You take them by the arm. (F1 > Drag them along again to let go.)"  (chat message, line 590)
- "[Living City] You're being walked along."  (chat message, line 591)
- "Things are back to normal. Ordinary stops, ordinary days."  (text, line 661)
- "Back to ordinary patrols."  (text, line 661)
- "More stop-and-searches on the street. Keep your papers ready and nothing on you you'd want found."  (text, line 662)
- "Half as many stops again as usual. Keep an eye out."  (text, line 663)
- "Civil Protection units may shoot to kill as they see fit, and stop twice as many people. Get indoors and stay out of sight."  (text, line 664)
- "Twice as many stops. You may shoot to kill as you see fit: make it count."  (text, line 665)

> Note for you (not shown in game): an outbreak: red only while its infected are actually loose in the city (at most 5 minutes); headcrabs and zombies in the infestation itself don't touch it

- "infected loose in the city"  (text, line 685)
- "civil unrest"  (text, line 688)
- "fighting in the streets"  (text, line 689)
- "an anticitizen at large"  (text, line 692)

> Note for you (not shown in game): part of: socio auto

- "a wanted anticitizen"  (text, line 693)

> Note for you (not shown in game): part of: announce socio

- "[Overwatch] "{subtitle}""  (chat message, line 719)
- "[Overwatch] Sociostability: %s.%s"  (message, line 722)

> Note for you (not shown in game): part of: set socio

- "Officers only (Division Leader and up, the Administrator)."  (text, line 744)
- "Sociostability is back to what the city makes it."  (text, line 749)
- "Pick green, yellow, red, or auto (the city decides)."  (text, line 751)

> Note for you (not shown in game): (announced to the whole city each time: not more than once every half minute)

- "You only just set it. Wait %d seconds."  (message, line 754)
- "Sociostability set to %s for %d minutes."  (message, line 760)

> Note for you (not shown in game): Requests

- "Requests are off on this server."  (text, line 774)
- "You're a Civil Protection unit. Use the radio, or !backup."  (text, line 776)
- "You need a Civil Protection call box (the Union Commissary sells them)."  (text, line 777)
- "Say what's wrong: /request <what's wrong>"  (text, line 778)

> Note for you (not shown in game): part of: cprequest

- "The call box crackles. Nothing gets through: something nearby is jamming it."  (text, line 779)
- "The device is still recharging (%ds)."  (message, line 782)
- "[Request] Sent. Civil Protection has your location."  (chat message, line 814)
- "[Request] Sent. A Civil Protection unit is on the way."  (text, line 815)
- "[Request] Sent. Nobody answers."  (text, line 815)
- "request from %s: %s"  (message, line 816)

> Note for you (not shown in game): Play a line and say it. word: the line's short word, its number, or its words.

- "Only Civil Protection units have the mask's voice."  (text, line 852)
- "No such line. !vo opens the list."  (text, line 855)

> Note for you (not shown in game): part of: vo

- "Only Civil Protection units have the mask's voice."  (chat message, line 908)

> Note for you (not shown in game): part of: socio

- "[Overwatch] Sociostability: %s%s"  (message, line 920)
- "(set by %s, %d min left)"  (message, line 921)

> Note for you (not shown in game): part of: issue duty allocation

- "a ration packet"  (text, line 975)
- "a ration packet (your pockets are full: collect it from a dispenser)"  (text, line 975)
- "credits in ration coupons"  (text, line 977)
- "[Civil Protection] Duty allocation issued: {got}."  (chat message, line 978)

## the Civil Protection Commissary (units' supplies) (sv_livingcity_cpsupply.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_cpsupply.lua`


> Note for you (not shown in game): ammunition for what they carry

- "{load} rounds"  (text, line 66)

> Note for you (not shown in game): armour

- "armour, to {want}"  (text, line 74)

> Note for you (not shown in game): the ration allocation

- "a ration packet"  (text, line 84)

> Note for you (not shown in game): part of: use cpsupply

- "[CP Commissary] Restricted: Civil Protection only."  (chat message, line 95)
- "[CP Commissary] The screen's dark. No power."  (chat message, line 99)
- "[CP Commissary] Your next issue is in %d seconds. The Civil Protection unit counter is open."  (message, line 104)
- "[CP Commissary] Issued: {got}."  (chat message, line 110)
- "[CP Commissary] You're fully supplied. The Civil Protection unit counter is open."  (chat message, line 112)

## making things, grenades, the arms trade, and getting people out (sv_livingcity_crafting.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_crafting.lua`


> Note for you (not shown in game): Crafting

- "You need {n} {name}."  (text, line 61)
- "Not with someone watching. Get out of sight first."  (text, line 63)

> Note for you (not shown in game): part of: craft

- "That's the lab's work: the Resistance's scientist makes it. Everyone else buys it at the black market."  (text, line 70)
- "[CP Commissary] Visit a Civil Protection Commissary to be issued supplies."  (text, line 73)
- "You're busy."  (text, line 74)
- "Making {name}... keep still"  (progress bar, line 78)
- "You put it down, half finished."  (text, line 79)

> Note for you (not shown in game): part of: done

- "Made: {name}."  (chat message, line 86)
- "Manufacturing weapons"  (text, line 88)
- "Manufacturing contraband"  (text, line 88)
- "[Civil Protection] A Civil Protection unit saw what you were making."  (chat message, line 89)

> Note for you (not shown in game): Using things

- "You're not hurt."  (text, line 127)

> Note for you (not shown in game): part of: arms use

- "You can't wear any more."  (text, line 140)
- "You've no powered vest on to charge."  (text, line 146)
- "Your vest is fully charged."  (text, line 147)
- "You've already got one in your hand."  (text, line 158)
- "Brandishing a weapon"  (text, line 163)

> Note for you (not shown in game): a mask keeps it out (chlorine and poison alike), unless its filter has been fouled

- "Your filter"  (on-screen notice, line 299)
- "The gas is coming straight through your mask: the filter's no good. Get out of it!"  (on-screen notice, line 299)

> Note for you (not shown in game): part of: throw grenade

- "Not with your hands cuffed."  (text, line 339)

> Note for you (not shown in game): The Grenades weapon asks for one of a kind

- "None left."  (text, line 385)

> Note for you (not shown in game): A unit's issued grenades are Combine issue: kept, thrown, or handed to another unit; never sold, dropped, stashed or passed to anyone else (they came back free with every respawn).

- "That's Combine issue: it stays with you (or another unit)."  (text, line 410)

> Note for you (not shown in game): Passing things on (and smuggling them into a cell)

- "Look at the person you want to give it to, up close."  (text, line 437)
- "Your papers stay with you. (Show them instead: Use.)"  (text, line 440)

> Note for you (not shown in game): part of: give to

- "They can't carry any more."  (text, line 442)
- "Smuggling contraband into custody"  (text, line 447)
- "[Civil Protection] A guard saw you pass something through the bars. It's confiscated, and so is your freedom."  (chat message, line 448)
- "You hand over: {name}."  (chat message, line 453)
- "slips you: {name}.{or}"  (chat message, line 454)

> Note for you (not shown in game): typing in chat

- "You don't have anything like that."  (chat message, line 468)

## what custody costs the worst anticitizens (sv_livingcity_custody.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_custody.lua`


> Note for you (not shown in game): Interrogation

- "Who are your contacts?"  (text, line 70)
- "Where do they meet?"  (text, line 70)
- "Who gave you the weapon?"  (text, line 70)
- "Where is the hideout?"  (text, line 71)
- "Names. Give me names."  (text, line 71)
- "Who else knows?"  (text, line 71)

> Note for you (not shown in game): part of: start interrogation

- "[Interrogation] A Civil Protection unit steps into your cell and switches on his baton. "You will answer my questions." (Talk, and it stops: the choice is on your screen. Or don't.)"  (chat message, line 118)
- "[Interrogation] "If you comply, I will grant you {COOP_REWARD} social credits.""  (chat message, line 119)

> Note for you (not shown in game): Give them what they want: a hideout, marked for every unit.

- "Nobody's asking."  (text, line 128)

> Note for you (not shown in game): part of: interrogation talk

- "[CP net] A prisoner has talked: a Resistance hideout {where}."  (chat message, line 139)
- "cooperated under interrogation"  (text, line 146)

> Note for you (not shown in game): the cell hears about it

- "talked in custody. Don't trust them."  (text, line 150)
- "[Interrogation] You tell them{or}. The Civil Protection unit nods, and leaves."  (text, line 152)

> Note for you (not shown in game): part of: interrogation tick

- "[Interrogation] "We'll talk again." The Civil Protection unit leaves. You said nothing."  (text, line 161)
- "said nothing under interrogation"  (text, line 162)

> Note for you (not shown in game): Broken feet: no running

- "[Custody] They hold you down and break your feet. You won't be running for %d minutes. Not after release, not after anything."  (message, line 188)

> Note for you (not shown in game): part of: make stalker

- "[Custody] You come to, standing. Your body moves when they tell it to, not when you do. You are a stalker now: Combine property. You can't run, fight or speak, and you'll work. There is no way out of it but death."  (chat message, line 268)
- "Combine property"  (on-screen notice, line 269)
- "You are a stalker now. There is no way out of it but death. Your work is on your board (F3)."  (on-screen notice, line 269)
- "[City] An anticitizen has been repurposed. Citizens are reminded that cooperation is mandatory."  (chat message, line 273)

> Note for you (not shown in game): part of: stalker scene

- "[Custody] The cell door opens. Two Civil Protection units come in, batons out. They aren't here to ask questions."  (chat message, line 297)
- "They've come for you"  (on-screen notice, line 298)
- "Two units, batons out. You're not being released."  (on-screen notice, line 298)

> Note for you (not shown in game): a timer (regularly)

- "[Custody] Everything goes black."  (chat message, line 310)

> Note for you (not shown in game): part of: free stalker

- "[City] The city has had its use of you. You're let back onto the streets, on probation."  (chat message, line 329)

> Note for you (not shown in game): (superadmin) let someone off being a stalker: lc_unstalker <part of a name>

- "[City] An administrator has let you off being a stalker."  (text, line 340)
- "[Living City] {Nick} is no longer a stalker."  (chat message, line 341)

> Note for you (not shown in game): nor talk to anyone (E on a person does nothing: a stalker's work is the only thing it does) (asked first by every E-on-someone handler: sv_livingcity.lua, the rebels', Grigori's, the lab's)

- "[Stalker] You try to speak. Only a scream comes out: they left you a voice, not words."  (chat message, line 363)

> Note for you (not shown in game): a timer (regularly)

- "[City] The stalker that was you is gone. You come back as a citizen, on probation."  (text, line 397)

## saved layout (sv_livingcity_data.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_data.lua`


> Note for you (not shown in game): part of: restore backup

- "No such backup. lc_backups lists them."  (text, line 180)
- "That backup can't be read."  (text, line 182)

> Note for you (not shown in game): the console command lc_reload

- "[Living City] Reloaded layout: %d points, %d path nodes, %d zones, %d tagged doors."  (message, line 498)

> Note for you (not shown in game): the console command lc_backup

- "[Living City] Backed up the layout as {name}."  (text, line 508)
- "[Living City] Nothing to back up yet."  (text, line 508)

> Note for you (not shown in game): the console command lc_backups

- "[Living City] Layout: data/%s. %d backups in data/%s/:"  (message, line 514)
- "Restore one with lc_restore <number>. What's there now is backed up first."  (text, line 516)

> Note for you (not shown in game): the console command lc_restore

- "[Living City] Restored {what}."  (text, line 522)
- "[Living City] {what}"  (text, line 522)

> Note for you (not shown in game): the console command lc_autolink

- "[Living City] Made %d new links.%s"  (message, line 537)
- "%d nodes still have no links (shown in red)."  (message, line 538)

> Note for you (not shown in game): the console command lc_goto_layout

- "[Living City] None of those on this map."  (chat message, line 572)
- "[Living City] %s %d of %d. (You're in noclip; it's easy to land inside things.)"  (message, line 577)

> Note for you (not shown in game): the game answering something done in a window (lc_setting)

- "%s set %s to %s"  (message, line 614)

## debugging (sv_livingcity_debug.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_debug.lua`


> Note for you (not shown in game): Server-side Lua errors (hook exists on current Garry's Mod builds)

- "lua %s error: %s (%s)"  (message, line 36)

> Note for you (not shown in game): part of: settings

- "= {GetString}"  (text, line 73)

> Note for you (not shown in game): part of: build report

- "version %s \| map %s \| gamemode %s \| %s"  (message, line 81)
- "players %d/%d \| singleplayer %s \| dedicated %s \| uptime %s"  (message, line 83)
- "city %s \| event %s"  (message, line 86)
- "running for {CurTime}"  (text, line 87)
- "points: {or}"  (text, line 101)
- "zones: {GrownCount}"  (text, line 112)
- "territory grown since placed: rebel %d patches, infestation %d patches (lc_territory for details)"  (message, line 114)
- "door tags: {or}"  (text, line 121)
- "no prison cells: arrests become street detentions (cuffed, searched, fined, released)"  (text, line 127)
- "no spawn/exit doorways: NPCs appear out of sight and leave into blocks or wander off"  (text, line 128)
- "no housing blocks: curfew can't send anyone home, and nobody has a stash"  (text, line 129)
- "static map fixtures: {or}{or}"  (text, line 135)
- "people: %d alive (%d sympathizers), %d dead remembered"  (message, line 143)
- "no Combine-only zones: citizens can walk into the nexus, offices and armory (doors by the cells still lock)"  (text, line 145)
- "no infestation spawn points: zombies appear at random spots inside infestation zones"  (text, line 146)
- "no checkpoints or patrol beats: cops wander at random"  (text, line 147)
- "no workplaces: Union shifts happen out on the streets"  (text, line 148)
- "line %d has no ration dispenser at its front: NPCs are still served, and players who wait at the front are handed a ration"  (message, line 156)
- "recordings: {or}"  (text, line 169)
- "ending songs (sound/livingcity/endings/): {songs}"  (text, line 175)
- "downloads: sv_downloadurl "{or}" (players get new sounds after a FastDL sync and a map change)"  (text, line 177)
- "setup notes: {_}"  (text, line 179)
- "people who left since the map started: %d"  (message, line 185)
- ", no dispenser by its front (a clerk hands rations out)"  (text, line 192)
- ", its dispenser has NO POWER: nobody queues for a dead dispenser"  (text, line 193)
- "line %d: %d slots, %d queued, %d on their way, front waiting %ds%s%s"  (message, line 194)
- "(placed from the back: turned round so the front is at the dispenser)"  (message, line 196)
- "vortigaunts: %d freed in rebel ground (lc_rebel_vorts %s)%s, %d shackled on the streets (lc_vort_slaves %s)"  (message, line 206)
- "chasing %s at %.0fu"  (message, line 219)
- "%-8s %-16s hp %3d recov %d err %d hop %s/%s pos %s%s%s%s"  (message, line 222)
- "beat {routeGroup}"  (text, line 226)
- "line {line} slot {slotIndex}"  (text, line 227)
- "heading to line {lineHeading}"  (text, line 227)
- "by role: {out}{or}"  (text, line 234)
- "stuck: %d moved on a step, %d far trips given up%s"  (message, line 238)
- "routes: %s, %d trips not started (unreachable), %d places skipped as hard to reach"  (message, line 243)
- "%d planned over the nodegraph, %d short enough to walk direct"  (message, line 244)
- "no nodegraph links"  (message, line 244)
- "route repairs: %d legs walked in single steps, %d links found unwalkable (%d avoided right now), %d trips re-planned around them"  (message, line 247)
- "main loop: avg %.2f ms, last %.2f ms, worst %.2f ms over %d ticks"  (message, line 255)
- "server tick interval %.4f, entity count %d"  (message, line 257)
- "whole server frame (engine AI, physics, networking): avg %.2f ms, worst %.2f ms, %d of %d ticks late (%.1f%%), a tick should take %.1f ms"  (message, line 260)
- "entities by class: {top}"  (text, line 273)
- "NPCs on the map (all of them, Living City's and not): %d"  (message, line 276)
- "asleep (far from everyone, engine AI off; lc_npc_sleep %s): %d now; %d times put to sleep, %d woken, %d route stops walked out of sight"  (message, line 279)
- "%s [%s] step %d/%d (%s) %ds left: %s"  (message, line 290)
- "active %d \| violent cap %d"  (message, line 295)
- "prisoners: {prisoners} \| detained on the street: {held}"  (text, line 302)
- "stops in progress: {stops} \| next event: {_}"  (text, line 305)
- "disguise {GetNW2String}"  (text, line 313)
- "alias {GetNW2String}"  (text, line 314)
- "radio {GetNW2String}"  (text, line 315)
- "contraband {illegal}"  (text, line 316)
- "alert %d (heat %d, %d soldiers after them)"  (message, line 318)
- "running check: {pl}"  (text, line 320)
- "(rebel territory)"  (message, line 322)
- "%s \| %s \| job %s \| block %s \| cp %s \| wanted %s \| hunger %d thirst %d \| credits %s standing %s%s%s"  (message, line 323)
- "Recent log (newest last)"  (text, line 333)

## doors (sv_livingcity_doors.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_doors.lua`


> Note for you (not shown in game): part of: say

- "[Living City] {msg}"  (chat message, line 42)

> Note for you (not shown in game): Editor helpers: inspect and test

- "%s (map id %s)"  (message, line 463)
- "none: spawned, can't be tagged"  (message, line 463)

> Note for you (not shown in game): part of: door info

- "A prison door, automatically: it's by a cell or the release point, or in the prison area. Locked to all but Civil Protection units, even in a blackout (tag it to override)"  (text, line 468)
- "Locked automatically: it's in a Combine-only area. Its lock goes dead in a blackout (tag it to override)"  (text, line 470)
- "NPCs treat it as a door: {lines}{or}"  (text, line 474)

> Note for you (not shown in game): the console command lc_unlockdoors

- "Unlocked {n} doors (locked-tagged doors left alone)."  (chat message, line 504)

> Note for you (not shown in game): the console command lc_opendoors

- "Opened {n} doors. They will stay open."  (chat message, line 557)

## the Combine's dropship (sv_livingcity_dropship.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_dropship.lua`


> Note for you (not shown in game): The flight: in from afar to a point over the spot, down, a while there, up, and away. above: how high over the ground the ship's origin hovers.

- "there's a roof over it, not open sky"  (text, line 60)
- "not enough open sky over it"  (text, line 65)

> Note for you (not shown in game): part of: plan

- "no clear way in over the rooftops"  (text, line 79)

> Note for you (not shown in game): Where a carried container hangs: in the ship's claws. The container model is drawn in the ship's own frame (Half-Life 2 puts it at the ship's origin, at the ship's angles, and parents it there), so it goes exactly where the ship is, tilting with it. (It used to be hung a further body-length down, and dangled about fifteen feet under the ship.)

- "nowhere to go"  (text, line 108)

> Note for you (not shown in game): part of: fly dropship

- "no dropship model on this server"  (text, line 109)
- "the sky's busy"  (text, line 110)
- "no dropship"  (text, line 112)

## economy and social credit (sv_livingcity_economy.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_economy.lua`


> Note for you (not shown in game): part of: flush standing

- "(it can't go any lower)"  (text, line 73)
- "(it can't go any higher)"  (text, line 74)
- "[Civil Standing] %+d%s: %s"  (message, line 75)
- "[Civil Standing] You are now classified: {name}."  (chat message, line 78)

> Note for you (not shown in game): What earns and costs you

- "Community service"  (text, line 121)
- "shift complete"  (text, line 123)

> Note for you (not shown in game): the game's living city quest complete moment

- "Union shift completed"  (text, line 124)
- "paid quietly"  (text, line 126)

> Note for you (not shown in game): the game's living city escaped moment

- "Escaped custody"  (text, line 140)

> Note for you (not shown in game): Serving your time pays back part of what you owe: a quarter of the deficit plus 100, and more if you gave yourself up. Never past zero.

- "Turned yourself in and served your time"  (text, line 152)
- "Served your time"  (text, line 152)

> Note for you (not shown in game): the game's living city strike moment

- "Conduct violation"  (text, line 154)

> Note for you (not shown in game): (what an offence costs in standing; most are 25. A shot at a scanner is a little, wrecking one is 50)

- "Destroying city property"  (text, line 156)
- "Damaging city property"  (text, line 156)
- "Out after curfew"  (text, line 158)
- "Reported anticitizen activity"  (text, line 160)

> Note for you (not shown in game): Where a unit's things are sold: the Civil Protection Commissary's counter (sv_livingcity_cpsupply.lua), never the Union's terminals; only a city with no Civil Protection Commissary sells them at the Union terminal.

- "The commissary is closed."  (text, line 197)

> Note for you (not shown in game): part of: can buy

- "The terminal doesn't recognize you. It doesn't recognize anything like you."  (text, line 198)
- "Civil Protection units only."  (text, line 199)
- "Not for units: the Civil Protection Commissary has clean uniforms."  (text, line 200)
- "Issued at the Civil Protection Commissary, not here."  (text, line 201)
- "Not at your rank."  (text, line 203)
- "Requires {name} standing."  (text, line 206)
- "Not enough credits."  (text, line 207)

> Note for you (not shown in game): part of: buy

- "[Commissary] {why}"  (chat message, line 224)
- "[Commissary] Purchased: %s (%d credits)"  (message, line 239)

> Note for you (not shown in game): part of: open shop

- "[Commissary] The commissary is closed."  (chat message, line 245)
- "[Commissary] The terminal asks for a citizen number you don't have yet. Register at Civil Intake."  (chat message, line 247)
- "[Commissary] Find a Union Commissary terminal."  (chat message, line 250)

> Note for you (not shown in game): typing in chat

- "[Union] %d credits. Civil Standing %d (%s)."  (message, line 279)

> Note for you (not shown in game): the console command lc_givecredits

- "from staff"  (text, line 288)

> Note for you (not shown in game): the console command lc_setstanding

- "adjusted by staff"  (text, line 295)

## secret endings (sv_livingcity_endings.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_endings.lua`

- "They Return"  (name, line 126)
- "The lights go out. Something is gathering out there in the dark."  (spoken line, line 126)
- "The Bus"  (name, line 127)
- "Hear that horn? All aboard."  (spoken line, line 127)
- "Alo, salut. Please fasten your seatbelts."  (spoken line, line 128)
- "Look up."  (spoken line, line 129)
- "The Flood"  (name, line 130)
- "Father Grigori has eaten the motherlode. The waters rise."  (spoken line, line 130)
- "Everybody dances. Nobody stops."  (spoken line, line 131)
- "Something is rattling out there. Lots of somethings."  (spoken line, line 132)
- "What happen ?"  (spoken line, line 133)
- "It's time."  (spoken line, line 134)
- "Shalom. Take your neighbour by the shoulders: it's time to dance."  (spoken line, line 135)
- "Something smells like smoke. It's coming from behind you."  (spoken line, line 136)

> Note for you (not shown in game): part of: take

- "You were taken."  (chat message, line 264)

> Note for you (not shown in game): part of: spectator

- "You're out of it. Watch the rest."  (chat message, line 564)

> Note for you (not shown in game): part of: slaughter

- "The mingebags got you."  (text, line 573)

> Note for you (not shown in game): part of: hit

- "They're on you, all of them, in that pose. The mingebags got you."  (text, line 611)

> Note for you (not shown in game): part of: harpies

- "[Civil Protection] "All Civil Protection units, open fire! Take them down!""  (chat message, line 950)

> Note for you (not shown in game): the last two seconds: nobody's left

- "There's nowhere left. The mingebags got you."  (text, line 1044)

> Note for you (not shown in game): part of: bloom

- "You spin up into the sky and burst into sparkles. Watch the rest go."  (text, line 1208)

> Note for you (not shown in game): part of: convert

- "The skeletons got you. You're one of them now. Dance."  (chat message, line 1282)

> Note for you (not shown in game): part of: apply section

- "The skeletons claim everyone in the end. You're one of them now. Dance it out."  (text, line 1402)

> Note for you (not shown in game): the ride lasts the song, more or less, and then nobody ever gets off

- "The ride doesn't stop. It never stops."  (text, line 1571)

> Note for you (not shown in game): Engrish: what everyone says, the way the captain would say it.

- "%f[%a][Yy]our%f[%A]"  (text, line 1881)
- "%f[%a][Yy]ou're%f[%A]"  (text, line 1881)
- "you are"  (text, line 1881)
- "are belong"  (text, line 1881)
- "%f[%a]going to%f[%A]"  (text, line 1883)
- "on the way to"  (text, line 1883)

> Note for you (not shown in game): Partied too hard: down they go.

- "You partied too hard. Lights out."  (text, line 2211)

> Note for you (not shown in game): the music cuts: everyone left goes down

- "The music stops. So do you. You partied too hard."  (text, line 2285)

> Note for you (not shown in game): part of: burst

- "Your behind takes you all the way up, and you go off like a firework. Watch the rest go."  (text, line 2762)

> Note for you (not shown in game): (held there, not frozen: a frozen player can't even look about, and the rope's view is all about looking about; where they are is set every tick anyway)

- "A rope drops round your neck from above, and up you go. (You can still look about.)"  (chat message, line 3097)

> Note for you (not shown in game): Gone limp: still hanging there, looking on.

- "You stop kicking. You hang there, and watch the rest."  (chat message, line 3118)

> Note for you (not shown in game): part of: bite

- "Something huge comes up out of the dark water. That's the last you see."  (text, line 3294)

> Note for you (not shown in game): part of: icthy step

- "It comes over the edge of the stage at you, jaws first. That's the last you see."  (text, line 3309)

> Note for you (not shown in game): under the water: you hold your breath, then you drown

- "The water closes over your head. Somewhere above, Father Grigori hits the high note."  (text, line 3542)

> Note for you (not shown in game): the last note: whoever's still here goes, and Father Grigori last of all

- "The tide takes you, gently, at the very end."  (text, line 3669)
- "Father Grigori holds the last note, bows, and the flood takes its encore."  (text, line 3671)

> Note for you (not shown in game): part of: water

- "Father Grigori holds the last note, bows, and the flood takes its encore."  (chat message, line 3674)

> Note for you (not shown in game): part of: go to

- "[???] Time stops. A man in a blue suit is standing in front of you. He'd like a word, and your vote: 1 to let it happen, 2 to skip it."  (text, line 3764)
- "No song"  (on-screen notice, line 3773)
- "No song found for {id}: put {id}.mp3 in garrysmod/sound/livingcity/endings/ on the server (and sync FastDL). lc_endings shows what it finds."  (on-screen notice, line 3773)
- "[???] So be it. {say}"  (text, line 3778)
- "[???] The city resets. Everyone you were is still you."  (text, line 3786)

> Note for you (not shown in game): part of: trigger ending

- "No such ending."  (text, line 3793)
- "One's already under way."  (text, line 3794)
- "Secret endings are off."  (text, line 3795)
- "Not yet ({EndingCooldownLeft} minutes)."  (text, line 3796)

> Note for you (not shown in game): pcall

- "[???] %d to %d. Very well. He straightens his tie, and time starts again."  (message, line 3852)
- "[???] Silence. He takes that as a yes."  (text, line 3855)

> Note for you (not shown in game): Triggers Father Grigori eats the motherlode.

- "You'd break your teeth."  (text, line 3897)
- "You've nothing like that to eat."  (text, line 3898)
- "Not now."  (text, line 3899)
- "It doesn't go down. Not yet."  (text, line 3900)

> Note for you (not shown in game): part of: eat chip

- "** Father Grigori swallows a Combine data core whole. His eyes light up."  (chat message, line 3904)

> Note for you (not shown in game): For the admin

- "[Living City] {m}"  (chat message, line 3918)

> Note for you (not shown in game): the console command lc_endings

- "{song} is a low-quality copy ({hz} Hz: it plays, but sounds muffled); a better copy would sound much better"  (text, line 3926)
- "NO SONG FOUND (looking for {id}.mp3 in garrysmod/sound/{ROOT})"  (text, line 3928)

> Note for you (not shown in game): everything that's actually there, so a file in the wrong place shows

- "In sound/{ROOT}: {or}"  (text, line 3933)
- "The folder {d}/ holds {inside} file(s) that never play: move them up one level, straight into sound/{ROOT}"  (text, line 3938)

> Note for you (not shown in game): the console command lc_endings

- "never plays: name it for its ending (harpies.mp3, bus.mp3 ...)"  (text, line 3944)
- "isn't a sound the game plays (.mp3, .ogg or .wav)"  (text, line 3946)
- "Next one possible in {left} minutes (lc_ending_reset_cooldown)."  (text, line 3950)
- "One can happen now."  (text, line 3950)

> Note for you (not shown in game): the console command lc_ending

- "Ending triggered: {id}"  (text, line 3958)

> Note for you (not shown in game): the console command lc_ending_cancel

- "Ending cancelled. Time runs again."  (text, line 3963)
- "No ending on."  (text, line 3963)

> Note for you (not shown in game): the console command lc_ending_reset_cooldown

- "Secret ending cooldown cleared."  (text, line 3970)

> Note for you (not shown in game): Settings are saved, so a default changed since would never reach a server that ran the old one: anything still exactly at an old default moves to the new one (once; a value someone chose themselves is left alone).

- "harpies=2,shalom=2"  (text, line 3988)
- "harpies=4,shalom=2"  (text, line 3988)
- "3.5:bomb,14.7:screen,34:zig,126:move,174:justice,212:boom,224:end"  (text, line 3989)
- "3.5:bomb,9.5:screen,34:zig,126:move,174:justice,212:boom,224:end"  (text, line 3989)
- "2.2=CAPTAIN: What happen ?\|3.5=MECHANIC: Somebody set up us the bomb.\|6.5=OPERATOR: We get signal.\|9.5=CAPTAIN: What !\|12.5=OPERATOR: Main screen turn on.\|14.7=CAPTAIN: It's you !!\|16.4=CATS: How are you gentlemen !!\|18.4=CATS: All your base are belong to us.\|20.4=CATS: You are on the way to destruction.\|21.6=CAPTAIN: What you say !!\|23.0=CATS: You have no chance to survive make your time.\|26.0=CATS: Ha ha ha ha ....\|34=CAPTAIN: Take off every 'ZIG' !!\|126=CAPTAIN: Move 'ZIG'.\|174=CAPTAIN: For great justice."  (text, line 3990)
- "2.15=CAPTAIN: What happen ?\|3.55=MECHANIC: Somebody set up us the bomb.\|4.65=OPERATOR: We get signal.\|6.5=CAPTAIN: What !\|9.5=OPERATOR: Main screen turn on.\|11.7=CAPTAIN: It's you !!\|12.55=CATS: How are you gentlemen !!\|14.7=CATS: All your base are belong to us.\|18.45=CATS: You are on the way to destruction.\|20.6=CAPTAIN: What you say !!\|21.65=CATS: You have no chance to survive make your time.\|26.0=CATS: Ha ha ha ha ....\|34=CAPTAIN: Take off every 'ZIG' !!\|126=CAPTAIN: Move 'ZIG'.\|174=CAPTAIN: For great justice."  (text, line 3990)

## escorts through Combine doors (sv_livingcity_escort.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_escort.lua`


> Note for you (not shown in game): part of: radio

- "[CP net] {text}"  (chat message, line 60)

> Note for you (not shown in game): What a unit is called on the radio.

- "A Civil Protection unit"  (text, line 68)
- "Unit {EntIndex}"  (text, line 73)

> Note for you (not shown in game): Who can have one, and who can give one A Union worker, on a job.

- "Escorts are off on this server."  (text, line 96)
- "You're a Civil Protection unit. You open those doors yourself."  (text, line 98)
- "Not from in here."  (text, line 100)
- "Only Union workers get an escort: take a Union job from your board (F3)."  (text, line 101)
- "You need to be on a job: accept a shift from your board (F3) first."  (text, line 102)

> Note for you (not shown in game): part of: may have escort

- "Civil Protection doesn't escort wanted people."  (text, line 103)
- "Dispatch won't send anyone with you. ({CurTime} min)"  (text, line 105)

> Note for you (not shown in game): part of: dispatch

- "[Union] {npc} is coming to take over your escort. Stay where you are."  (chat message, line 245)
- ": copy, taking over the escort of {worker}."  (text, line 246)
- "[Union] {npc} is on the way to escort you. Wait for them."  (chat message, line 248)

> Note for you (not shown in game): Ask for one.

- "You've already got {or}."  (text, line 258)

> Note for you (not shown in game): part of: request escort

- "Escort requested: %s, Union %s, %s.%s"  (message, line 262)
- "(Actions menu: Civil Protection > Escort requests.)"  (message, line 263)
- "[Union] No Civil Protection unit's free right now. Dispatch has your request; wait for one."  (text, line 267)

> Note for you (not shown in game): Dismiss it yourself.

- "You haven't got an escort."  (text, line 273)
- "[CP net] {NameOf} has dismissed you."  (chat message, line 275)
- "[Union] You send your escort away.{or}"  (text, line 276)

> Note for you (not shown in game): A player unit takes it on (from an NPC unit, or a request nobody's answered).

- "Civil Protection units only."  (text, line 282)
- "Look at the worker, or pick them from Escort requests."  (text, line 283)
- "You're already escorting them."  (text, line 285)
- "They aren't on a job."  (text, line 288)

> Note for you (not shown in game): part of: take escort

- "Finish the escort you're on first."  (text, line 293)
- "[Union] {unit} is escorting you."  (chat message, line 301)
- "[CP net] You're escorting {worker}{or}"  (chat message, line 302)

> Note for you (not shown in game): A player unit hands it back: the next free unit takes over.

- ": handing off the escort of {worker}, {GetPos}."  (text, line 311)
- "handed off"  (text, line 311)
- "[CP net] You hand the escort back to dispatch."  (chat message, line 312)

> Note for you (not shown in game): part of: drop escort

- "You aren't escorting anyone."  (text, line 316)

> Note for you (not shown in game): part of: escort unattended

- "Worker unattended: nearest free Civil Protection unit, take over."  (text, line 330)
- "[Union] Your escort's been called away. Stay where you are: another Civil Protection unit is coming."  (chat message, line 331)

> Note for you (not shown in game): the game's living city can use cpdoor moment

- "[Union] {u} buzzes you through."  (chat message, line 381)

> Note for you (not shown in game): Someone slipped in behind the worker.

- "Unauthorized access"  (text, line 399)
- "%s: intruder through a Combine door %s, in pursuit."  (message, line 401)

> Note for you (not shown in game): part of: tailgated

- "someone followed you through a Combine door"  (text, line 403)
- "Under escort, let someone through a Combine door"  (text, line 404)
- "[Civil Protection] "Hold it!" A Civil Protection unit saw you slip through behind the worker."  (chat message, line 405)

> Note for you (not shown in game): A prisoner got out of a door the unit opened.

- "%s: prisoner out of a cell %s, returning them."  (message, line 415)

> Note for you (not shown in game): part of: prisoner out

- "a prisoner got out through a door your escort opened"  (text, line 420)
- "Under escort, had a cell door opened: a prisoner got out"  (text, line 421)
- "[Civil Protection] "Don't move!" The Civil Protection unit's seen you."  (chat message, line 422)

> Note for you (not shown in game): Twice on one job, and that's the last escort they get for a while.

- "Dispatch: no further escorts for {w}. Twice now."  (text, line 431)
- "[Union] Dispatch won't send anyone else with you. Get out of the restricted area."  (text, line 432)

> Note for you (not shown in game): part of: begin out

- "[Union] Your job's done. Your escort heads back to their beat."  (text, line 472)
- "[Union] "You're done. Out the way you came." Your escort heads back."  (text, line 476)
- "[CP net] {w}'s job is done: walk them out{or}"  (chat message, line 481)
- "[Union] "You're done here. This way." Your escort walks you out{or} Stay with them."  (chat message, line 485)

> Note for you (not shown in game): part of: finish out

- ": escort of {worker} complete."  (text, line 499)
- "[Union] "Move along." You're out, and your escort leaves you here."  (text, line 500)

> Note for you (not shown in game): part of: drive npc

- "[Union] {u}: "{or}""  (chat message, line 519)

> Note for you (not shown in game): too far from their escort for too long: on their own

- "you slipped your escort"  (text, line 530)
- ": {w} slipped their escort {wp}."  (text, line 531)
- "[Union] You left your escort behind. You're on your own in there."  (text, line 532)

> Note for you (not shown in game): wait for them

- "[Union] {u}: "Keep up.""  (chat message, line 554)

> Note for you (not shown in game): no release point: follow them out

- "[Union] Your escort leaves you to find your own way out."  (text, line 562)

> Note for you (not shown in game): part of: tick one

- "[Union] Your job's over. Dispatch cancels the escort request."  (text, line 594)
- ": escort of {w} interrupted, {GetPos}."  (text, line 603)
- "Civil Protection unit down"  (text, line 603)

> Note for you (not shown in game): called away (a crime nearby, someone shooting), or down

- "Dispatch: escort Civil Protection unit down"  (text, line 618)
- ": called away"  (text, line 618)
- ", {GetPos}."  (text, line 618)
- "Civil Protection unit down"  (text, line 619)
- "called away"  (text, line 619)

> Note for you (not shown in game): nobody with them

- "Dispatch: no Civil Protection unit free to take over the escort of {w}."  (text, line 636)
- "nobody came"  (text, line 637)
- "[Union] No Civil Protection unit came. You're on your own: leave the restricted area."  (text, line 637)

> Note for you (not shown in game): part of: tick one

- "[Union] No Civil Protection unit was free. Your escort request lapses; ask again later."  (text, line 640)

> Note for you (not shown in game): part of: recaptures

- "The Civil Protection unit marches you back to your cell."  (text, line 655)

> Note for you (not shown in game): someone leaving

- "Dispatch: escort Civil Protection unit off the net."  (text, line 682)
- "Civil Protection unit gone"  (text, line 682)

> Note for you (not shown in game): part of: escort command

- "Who? (!escort name, or Civil Protection > Escort requests in the actions menu.)"  (text, line 723)

## city events (sv_livingcity_events.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_events.lua`


> Note for you (not shown in game): morning exercise (sv_livingcity_exercise.lua)

- "Ration distribution"  (text, line 62)
- "Civil status inspections"  (text, line 62)
- "Housing block inspection"  (text, line 63)
- "Stabilization restored"  (text, line 63)
- "City announcement"  (text, line 63)
- "Overwatch response"  (text, line 64)
- "Supply convoy"  (text, line 64)
- "Morning exercise: the jog"  (text, line 65)
- "Morning exercise: the drill"  (text, line 65)
- "Morning parade"  (text, line 65)

> Note for you (not shown in game): Announcements What each PA line says, roughly, in plain words: the voice lines come from Half-Life 2 and aren't always clear, or are a loose fit for what's happening.

- "Failing to report suspicious behaviour counts as conspiracy. Report it to Civil Protection."  (text, line 99)
- "Ground Civil Protection units: an anticitizen has been reported in this community. Contain them."  (text, line 100)
- "Residents: a miscount has been detected. Cooperate with Civil Protection to keep your full rations."  (text, line 101)
- "Residents: this block may harbour civil unrest. Inform, cooperate, assemble."  (text, line 102)
- "Occupants: your block is charged with tolerating noncompliance. Ration units are being deducted."  (text, line 103)
- "An individual has been convicted of anticivil violations. Their citizenship is revoked."  (text, line 104)
- "Evasive behaviour detected. Ground protection teams: isolate the suspect."  (text, line 105)
- "An individual is charged with capital malcompliance. Anticitizen status approved."  (text, line 106)
- "Citizen notice: assemble at your designated positions."  (text, line 107)
- "Residents: assume your positions."  (text, line 108)
- "Persons of interest: confirm your civil status with your local protection team immediately."  (text, line 109)
- "Unrest procedure is now in effect."  (text, line 110)
- "All ground protection teams: response protocol is now in effect."  (text, line 111)
- "Socio-stabilization restored. Civil Protection units, return to standard duty."  (text, line 112)

> Note for you (not shown in game): part of: minutes

- "about a minute"  (text, line 118)

> Note for you (not shown in game): What actually happens, for the person reading it.

- "The city is in unrest: more inspections and raids, and rations come slower. See !city."  (text, line 129)
- "Just the city talking. Nothing changes."  (text, line 131)

> Note for you (not shown in game): part of: rations

- "Rations are being handed out for {Minutes}. The lines move faster and citizens crowd them; keep order."  (text, line 134)
- "Rations are being handed out for {Minutes}. Lines move faster and you can collect again sooner. Stand at the front of a ration line to get yours (not if you're wanted)."  (text, line 135)

> Note for you (not shown in game): part of: sweep

- "Civil status inspections for {Minutes}. Stop and search citizens: Civil Protection units stop people far more often now."  (text, line 138)
- "Civil status inspections for {Minutes}. Civil Protection units stop and search people far more often and from further away. Anything illegal on you will be found: stash it, or stay out of sight."  (text, line 139)

> Note for you (not shown in game): part of: raid

- "a housing block"  (name, line 143)
- "Civil Protection units are searching {name}. Contraband found there is traced to its owner, who becomes wanted."  (name, line 144)
- "Civil Protection units are searching {name}{or} room by room. Anyone there gets frisked, contraband lying around is traced to whoever left it, and they become wanted. Stashes can be found too."  (text, line 146)

> Note for you (not shown in game): part of: curfew

- "A curfew in the daytime: a punishment for the unrest in the city."  (text, line 151)
- "It's about you: any Civil Protection unit who sees you knows you, and won't stop at a warning."  (text, line 152)
- "Curfew for {Minutes}. Get inside {or} within {grace} seconds."  (text, line 155)
- "Curfew for {Minutes}. After {grace} seconds, citizens still outside get three warnings from a Civil Protection unit, then they're wanted."  (text, line 157)
- "Curfew for {Minutes}. You have no room yet: wait it out at Civil Intake, or where you arrived. Civil Protection units leave new arrivals there alone."  (text, line 160)
- "Curfew for {Minutes}. Get inside {or} (your HUD points the way). You have {grace} seconds. After that, a Civil Protection unit who sees you outside warns you three times, then you're wanted. Running is allowed until then."  (text, line 162)

> Note for you (not shown in game): part of: lockdown

- "Lockdown for {Minutes}, and it's about you: any Civil Protection unit who sees you knows you, and won't stop at a warning. Get out of sight."  (text, line 168)
- "Lockdown for {Minutes}: a curfew with extra Civil Protection units out. After {grace} seconds, anyone outside gets three warnings, then they're wanted."  (text, line 170)
- "Lockdown for {Minutes}. You have no room yet: wait it out at Civil Intake, or where you arrived. Civil Protection units leave new arrivals there alone."  (text, line 173)
- "Lockdown for {Minutes}: a curfew, with extra Civil Protection units on the street. Get inside {or} within {grace} seconds. After that, Civil Protection units who see you outside warn you three times, then you're wanted."  (text, line 175)

> Note for you (not shown in game): part of: ended

- "The curfew is over. You can go out again."  (text, line 178)

> Note for you (not shown in game): part of: response

- "Overwatch has been sent in. Keep clear of any fighting."  (text, line 179)

> Note for you (not shown in game): part of: supply

- "on the streets"  (text, line 184)
- "A supply convoy is unloading {where} for {Minutes}. Guard the crate: if anything's left in it when the convoy moves on, every Civil Protection unit nearby is paid."  (text, line 185)
- "A supply convoy is unloading {where} for {Minutes}. Guns, ammunition, medicine, lightly guarded. Take what you can (E on the crate)."  (text, line 186)
- "A supply convoy is unloading {where} for {Minutes}. Keep clear of it. Anyone caught taking from the crate is wanted."  (text, line 187)
- "Ration distribution is over. Lines go back to their usual pace."  (text, line 192)
- "Inspections are over. Civil Protection units are back to stopping people at the usual rate."  (text, line 193)
- "The housing block inspection is over."  (text, line 194)
- "Morning exercise is over. Off to work."  (text, line 195)
- "Morning exercise is over. Off to work."  (text, line 195)
- "The parade is over. Off to work."  (text, line 195)

> Note for you (not shown in game): and in chat, what it said and what it means

- "[{title}] "{says}""  (chat message, line 229)

> Note for you (not shown in game): part of: end event

- "[City] {was}"  (chat message, line 266)

> Note for you (not shown in game): pull idle citizens toward the lines right away

- "curfew or lockdown: gone home"  (text, line 303)

> Note for you (not shown in game): part of: start event

- "Event started: %s (%s min)"  (message, line 308)

> Note for you (not shown in game): part of: block name

- "Habitation Block %02d"  (text, line 351)

> Note for you (not shown in game): the one this is all about: no warnings, he knows you

- "[Civil Protection] "That's the one!" The Civil Protection unit knows you: this curfew is about you. You are wanted."  (chat message, line 418)
- "Wanted in connection with the unrest"  (text, line 419)

> Note for you (not shown in game): and he comes over: walking at the first warning, running after that

- "Civil Intake (you have no room yet)"  (text, line 432)
- "your residence"  (text, line 432)
- "[Civil Protection] Curfew is in effect. Return to %s. (Warning %d of %d)"  (message, line 436)

> Note for you (not shown in game): part of: enforce curfew

- "[Civil Protection] Curfew violation. You are now wanted."  (chat message, line 440)
- "Curfew violation"  (text, line 441)

> Note for you (not shown in game): part of: can think

- "Refusing a lawful order"  (text, line 579)

> Note for you (not shown in game): Commands

- "[Living City] Start the city first."  (chat message, line 651)
- "[Living City] Events: rations, sweep, curfew, lockdown, raid, supply, jog, drill, parade (those three need their points placed). Usage: lc_event curfew 5"  (chat message, line 653)
- "[Living City] Event started: {name}"  (chat message, line 655)

> Note for you (not shown in game): a unit sets off after someone causing a disturbance

- "Civil Protection is chasing someone {or}. Stay out of the way."  (chat message, line 686)

> Note for you (not shown in game): wanted: for running, evasion; for killing or attacking, capital malcompliance

- "citizen {GetNW2String}"  (text, line 693)
- "is wanted: {or}."  (chat message, line 695)
- "is wanted: {or}."  (chat message, line 697)

> Note for you (not shown in game): a long sentence: citizenship revoked

- "has been sentenced."  (chat message, line 703)

> Note for you (not shown in game): someone reports a crime: failing to report is conspiracy (said when people do report)

- "A citizen has reported something to Civil Protection."  (chat message, line 708)

## morning exercise (mandatory for citizens) (sv_livingcity_exercise.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_exercise.lua`

- "Morning jog"  (text, line 83)
- "Morning drill"  (text, line 83)
- "Morning parade"  (text, line 83)

> Note for you (not shown in game): part of: where

- "the assembly point"  (text, line 93)

> Note for you (not shown in game): (on the jog: "Move it!", "Keep moving!", never "First warning, move away", which sounded like being told to get back)

- "Keep up, citizen."  (text, line 244)
- "Do it properly."  (text, line 244)
- "Louder, citizen. With feeling."  (text, line 244)
- "Exercise is mandatory."  (text, line 244)

> Note for you (not shown in game): on the jog, a shove on along the route: toward the next marker

- "[Civil Protection] A crack with the stick. {absent}"  (chat message, line 298)

> Note for you (not shown in game): part of: tell

- "[{or}] {msg}"  (chat message, line 394)

> Note for you (not shown in game): part of: setup drill

- "You lead the drill this morning. Stand at the front of the yard (the marker) facing the rows: every move you make (crouch, jump, spin, a step left, right, forward or back) is called out for them to copy, one every few seconds. Stand still and the instructor fills in."  (chat message, line 551)

> Note for you (not shown in game): part of: join

- "Late. It has been noted."  (chat message, line 655)

> Note for you (not shown in game): part of: start run

- "You're leading. Go."  (chat message, line 693)
- "Go! Keep jogging, and keep up with the pace marker."  (chat message, line 743)
- "Stay on your place (the ring) and copy every move. Mistakes are counted."  (chat message, line 744)
- "Here they come. Cheer! (/cheer, /salute, chant in chat, jump.) Enthusiasm is watched."  (chat message, line 745)
- "You didn't report. Get there now: {center}. Civil Protection units are looking for you."  (chat message, line 748)

> Note for you (not shown in game): part of: truants

- "[Civil Protection] Morning exercise is mandatory. Report to {center}. Now."  (chat message, line 770)

> Note for you (not shown in game): part of: jog think

- "You're falling behind the pace. Run."  (chat message, line 867)
- "That's not jogging. Pick it up."  (chat message, line 867)

> Note for you (not shown in game): The drill

- "Turn around, all the way!"  (text, line 888)
- "Step left!"  (text, line 888)
- "Step right!"  (text, line 889)
- "Step forward!"  (text, line 889)
- "Step back!"  (text, line 889)

> Note for you (not shown in game): part of: rope start

- "Skipping! Jump on every beat of the rope."  (chat message, line 949)

> Note for you (not shown in game): part of: drill think

- "The rope catches your ankles."  (text, line 1021)
- "Too slow."  (text, line 1043)
- "Wrong move."  (text, line 1044)

> Note for you (not shown in game): your own place, not someone else's

- "Back to your place."  (text, line 1052)

> Note for you (not shown in game): The parade

- "long live"  (text, line 1089)

> Note for you (not shown in game): part of: parade think

- "[Civil Protection] Show some enthusiasm, citizen."  (chat message, line 1165)

> Note for you (not shown in game): Afterwards

- "[Union] Exemplary citizens are served first: a hot breakfast, and coffee. You feel well fed."  (chat message, line 1257)

> Note for you (not shown in game): part of: breakfast

- "[Union] For citizens of good standing: breakfast."  (chat message, line 1260)
- "[Union] Rations are issued at the usual distribution. Breakfast is for citizens of good standing."  (chat message, line 1262)

> Note for you (not shown in game): standing: for doing it, and doing it well

- "You didn't finish."  (chat message, line 1276)

> Note for you (not shown in game): part of: exercise finish

- "Poor showing at the {kind}"  (text, line 1284)

> Note for you (not shown in game): said plainly, on screen: what it earned (the owner: a small reward for doing it)

- "morning exercise"  (text, line 1287)
- "Done. %+d Civil Standing%s."  (message, line 1290)
- "and %d credits"  (message, line 1290)
- "A poor showing: %d Civil Standing."  (message, line 1291)

> Note for you (not shown in game): part of: exercise finish

- "Led the morning drill"  (text, line 1296)
- "Skipped morning exercise"  (text, line 1299)

> Note for you (not shown in game): and a reprimand they can't miss: their next ration is withheld (sv_livingcity_survival.lua)

- "you skipped morning exercise"  (text, line 1301)
- "You skipped morning exercise: -10 Civil Standing{or}"  (on-screen notice, line 1303)

> Note for you (not shown in game): What it means, for the person reading the announcement (sv_livingcity_events.lua).

- "the assembly point"  (text, line 1348)
- ": citizens report {where} within {secs} seconds. Civil Protection units are posted automatically; anyone shirking gets the stick."  (text, line 1351)
- "for citizens, {where}."  (text, line 1353)

> Note for you (not shown in game): part of: exercise means

- "Report to the start of the jogging route, {where}, within {secs} seconds (your HUD points the way). Then run it: keep jogging and keep up with the pace marker, or Civil Protection units along the route use the stick (which does speed you up)."  (text, line 1355)
- "Report to the exercise yard, {where}, within {secs} seconds. Take your place in the rows and copy every move (crouch, jump, spin, a step); jump on every beat when the rope comes out. Too many mistakes and you get the stick."  (text, line 1358)
- "Line the parade route, {where}, within {secs} seconds, and cheer the column as it passes: /cheer, /salute, chant in chat, jump. Your enthusiasm is on screen; let it drop as they pass and a Civil Protection unit sees to it."  (text, line 1361)

> Note for you (not shown in game): a timer (regularly)

- "You're well fed. Work goes better on a full stomach (+15% XP)."  (chat message, line 1440)

> Note for you (not shown in game): For the admin

- "[Living City] {m}"  (chat message, line 1454)
- "Exercise stopped."  (text, line 1457)
- "No exercise on."  (text, line 1457)

> Note for you (not shown in game): the console command lc_exercise

- "Next morning exercise: {or}. Every {GetInt} morning(s), at dawn. lc_exercise <jog\|drill\|parade> starts one now."  (text, line 1462)
- "Start the city first."  (text, line 1467)
- "Place an exercise yard first (editor: Point: exercise yard)."  (text, line 1469)
- "Place a {or} first (two or more stops, in order)."  (text, line 1470)
- "Couldn't start it."  (text, line 1473)

## sv_livingcity_factions.lua (sv_livingcity_factions.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_factions.lua`


> Note for you (not shown in game): Anyone without a faction becomes a Citizen.

- "[Factions] {msg}"  (chat message, line 42)

> Note for you (not shown in game): part of: titles

- "Resistance {hunted}"  (text, line 88)

> Note for you (not shown in game): Returns ok, reason

- "No such faction."  (text, line 358)

> Note for you (not shown in game): (a stalker is bound even as a superadmin: only death, or lc_unstalker, ends it)

- "Whitelist only."  (text, line 368)

> Note for you (not shown in game): part of: can join faction

- "Civil Protection only takes citizens in good standing (%d or more). Yours is %d."  (message, line 374)

> Note for you (not shown in game): and who've come up the Civil Protection path: Intake Processor, or Infestation Cleanup (sv_livingcity_work.lua counts the shifts)

- "Civil Protection recruits from the train station's Intake Processors and the infestation cleanup crews: finish %d Intake Processor shifts first, or half as many in Infestation Cleanup (F3 > Jobs). You've done %d."  (message, line 380)

> Note for you (not shown in game): part of: can join faction

- "Requires %s in %s."  (message, line 386)
- "No such role."  (text, line 391)
- "Someone already holds that role."  (text, line 393)
- "Requires {name} in {name}."  (text, line 395)

> Note for you (not shown in game): part of: set faction

- "You are now {name}."  (chat message, line 418)

> Note for you (not shown in game): the game answering something done in a window (lcf_join)

- "Not while you're in custody."  (chat message, line 444)
- "Not while you're wanted or in a fight."  (chat message, line 445)
- "You can change faction again in {CurTime} seconds."  (chat message, line 447)

> Note for you (not shown in game): what Civil Protection asks of a citizen, as progress bars on the card (the owner asked)

- "Civil Standing"  (label, line 467)
- "Intake Processor shifts finished (F3 > Jobs; Infestation Cleanup counts double)"  (label, line 468)

> Note for you (not shown in game): part of: send menu

- "Jobs done for the Resistance, to be trusted as a Fighter (their board, F3)"  (label, line 474)

> Note for you (not shown in game): only ever to give back what they had (never to take more away)

- "Welcome back. You're still {name}."  (chat message, line 539)

> Note for you (not shown in game): a timer (regularly)

- "You can't be %s right now: %s You're %s for now; take it again from the faction menu (F4) when there's a place."  (message, line 544)
- "back to your rank"  (message, line 546)

> Note for you (not shown in game): XP The transhuman conditioning: the Overwatch ranks open, and whatever XP you've earned counts at once. There's no undoing it.

- "the conditioning"  (text, line 561)

> Note for you (not shown in game): part of: add xp

- "Promoted to {name}!{or}"  (chat message, line 580)
- "[%s] %s has been promoted to %s."  (message, line 585)
- "Demoted to {name}."  (chat message, line 589)

> Note for you (not shown in game): Admin commands

- "Player not found."  (text, line 707)

> Note for you (not shown in game): admin cmd

- "Factions: citizen, resistance, cp, ota, admin, zombie"  (text, line 714)
- "No such special role."  (text, line 716)
- "set to {name}."  (text, line 718)
- "Usage: lcf_setxp <name> <xp>"  (text, line 724)
- "now has {xp} XP in {name}."  (text, line 727)

> Note for you (not shown in game): part of: step

- "by staff"  (text, line 736)
- "is now {name}."  (text, line 737)

> Note for you (not shown in game): admin cmd

- "Usage: lcf_whitelist <name> <faction>"  (text, line 744)
- "whitelisted for"  (text, line 748)
- "removed from"  (text, line 748)

> Note for you (not shown in game): A job done for the Resistance builds their trust; the last one needed makes a Fighter of a member with the XP.

- "[Resistance] You've proved yourself. They trust you now."  (chat message, line 758)
- "trusted by the Resistance"  (text, line 759)

> Note for you (not shown in game): the game's living city quest complete moment

- "[Resistance] They're starting to trust you: %d of %d jobs before they'd arm you as a Fighter."  (message, line 761)

## Freq 7, the Resistance's pirate broadcast (sv_livingcity_freq7.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_freq7.lua`


> Note for you (not shown in game): part of: freq7 jam

- "Dispatch: pirate signal located on %.1f. Jamming."  (message, line 173)

> Note for you (not shown in game): the console command lc_freq7_status

- "[Living City] Freq 7: %s %.1f; on now: %s (%s); found in %d s%s"  (message, line 244)
- "on air at"  (message, line 245)
- "jammed at"  (message, line 245)
- "nothing (no recordings)"  (message, line 245)
- "(blackout: the hunt has stopped)"  (message, line 246)

## the Resistance's money (besides raiding supply drops) (sv_livingcity_funding.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_funding.lua`


> Note for you (not shown in game): part of: say

- "[Intel] {text}"  (chat message, line 45)

> Note for you (not shown in game): Intel What's worth writing down from here: the best thing in sight, and a key for "the same place".

- "the approaches to the Combine's ground"  (text, line 56)

> Note for you (not shown in game): part of: whats here

- "the checkpoint: its shifts, its gate, its men"  (text, line 61)
- "a unit's beat: where he walks, and when"  (text, line 68)

> Note for you (not shown in game): part of: scout

- "Intel is the Resistance's trade: the quartermaster buys it."  (text, line 77)
- "You need a sheet of paper to write on (the Commissary sells them)."  (text, line 78)
- "You're busy."  (text, line 79)
- "Nothing worth writing down here. Get within sight of a checkpoint, a unit on his beat, or the Combine's own ground."  (text, line 81)
- "You've written this one down already. It's old news for a while."  (text, line 83)
- "Writing down what you see... keep out of sight"  (progress bar, line 85)
- "You put the paper away."  (text, line 86)

> Note for you (not shown in game): part of: done

- "Written down: {what}. The quartermaster pays for it."  (chat message, line 93)

> Note for you (not shown in game): A unit who sees you at it: the paper's taken, and he remembers your face.

- "A Civil Protection unit sees you writing. He takes the paper off you, and looks hard at your face."  (chat message, line 105)
- "Seen taking notes on Civil Protection"  (text, line 106)

> Note for you (not shown in game): part of: forgery turned up

- "[City] Counterfeit ration cards are in circulation. Civil Protection is tracing them to their source. Report anything you know."  (chat message, line 142)
- "They're onto the cards. They've traced them to one of our camps: a sweep is coming. Lie low."  (text, line 144)

## Father Grigori, in the flesh (sv_livingcity_grigori.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_grigori.lua`

- ""Come, my child. There is nothing here that the Lord has not seen.""  (text, line 41)
- ""They took the town, they took the bells. They did not take this." He taps his chest."  (text, line 42)
- ""Mind the traps on the way out. I would hate to bury you.""  (text, line 43)
- ""Every soul that walks out of their city is a prayer answered.""  (text, line 44)
- ""Annabelle and I keep watch. Sleep, if you can.""  (text, line 45)
- ""Pray for them too. Under the masks they were men once.""  (text, line 46)

> Note for you (not shown in game): Talking to him

- "[Father Grigori] "Ah, a shepherd of the Combine! Come closer, so Annabelle can give you my blessing.""  (chat message, line 178)

> Note for you (not shown in game): A blessing, a sermon, or a word. True, or false and why not.

- "Father Grigori isn't here."  (text, line 199)
- "[Father Grigori] {SAYINGS}"  (chat message, line 202)

> Note for you (not shown in game): part of: grigori ask

- ""Go with God, child. But go.""  (text, line 205)
- ""Patience. God does not repeat Himself so soon." (%d s)"  (message, line 207)
- "He lays a heavy hand on your head and mutters in Russian. For five minutes, the world hurts you a little less."  (on-screen notice, line 213)
- ""I have said my piece. Come back later and I will say it again, louder." (%d s)"  (message, line 216)
- "Father Grigori's sermon"  (text, line 225)
- "Father Grigori preaches fire and brimstone at the Combine. For ten minutes your shots hit them harder."  (on-screen notice, line 226)

> Note for you (not shown in game): the game answering something done in a window (lc_grigori_ask)

- "[Father Grigori] {why}"  (chat message, line 239)

## flood guard (sv_livingcity_guard.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_guard.lua`


> Note for you (not shown in game): part of: net allowed

- "flood guard: kicked %s (%s) for flooding the server (%s)"  (message, line 56)
- "Too many requests to the server"  (text, line 57)

> Note for you (not shown in game): part of: chat allowed

- "Slow down: you're sending messages too fast."  (chat message, line 83)

## stealing the Combine's data (sv_livingcity_heist.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_heist.lua`


> Note for you (not shown in game): part of: alarm

- "[CP net] {or}{where}. Anticitizens are inside Combine systems. All Civil Protection units respond."  (chat message, line 139)
- "Anticitizens are breaking into Combine systems {where}."  (text, line 147)

> Note for you (not shown in game): What a finished download leaves in your pockets: from an ordinary terminal a fragment (two from different terminals make a chip), from the master terminal a master data core.

- "[Resistance] The master terminal's data, all of it, on one core. This is the motherlode: the quartermaster can decode it (every Civil Protection unit marked for ten minutes), the dealer will pay a fortune, or plug it in and wipe every comrade's record."  (chat message, line 159)

> Note for you (not shown in game): part of: downloaded

- "[Resistance] The other half. The two fragments make a whole chip of Combine data: the dealer pays well for it, or take it to the quartermaster to decode."  (chat message, line 166)
- "[Resistance] Half the picture: a data fragment. Another terminal has the rest. Download it and the two make a whole chip."  (chat message, line 170)

> Note for you (not shown in game): part of: steal data

- "You need a multitool to get into it. (The Resistance's Hackers carry one; the black market sells them.)"  (text, line 177)
- "You're busy."  (text, line 179)
- "Look at a Combine terminal."  (text, line 181)
- "Nothing new on this one. (Ready again in about %d minutes.)"  (message, line 184)
- "You've already got this terminal's half. The rest is on another terminal."  (text, line 187)
- "Downloading the master terminal... stay close"  (progress bar, line 192)
- "Downloading Combine data... stay close"  (progress bar, line 192)
- "The download breaks off. Nothing to show for it."  (text, line 193)

> Note for you (not shown in game): partway through, the terminal notices (the master terminal sooner)

- "[Resistance] Every alarm in the nexus at once. They're coming in force. Keep going, or run."  (chat message, line 210)
- "[Resistance] An alarm. They know. Keep going, or run."  (chat message, line 211)

> Note for you (not shown in game): part of: steal data

- "Breaking into the master terminal"  (text, line 215)
- "Breaking into Combine systems"  (text, line 215)

> Note for you (not shown in game): part of: decode chip

- "You don't have a data chip."  (text, line 231)
- "Only the Resistance can make sense of it. The dealer would buy it."  (text, line 232)
- "Take it to the lab: the scientist decodes them."  (text, line 233)
- "The master terminal's data decoded"  (text, line 236)
- "Combine data decoded"  (text, line 236)
- "The master terminal's data decoded"  (text, line 237)
- "Combine data decoded"  (text, line 237)
- "The data's decoded: Civil Protection unit positions, patrol routes, posts. Every unit is marked for you for %d seconds. Move."  (message, line 241)

> Note for you (not shown in game): part of: wipe record with chip

- "You don't have a data chip."  (text, line 262)
- "Look at a Combine terminal to plug it in (or take it to the quartermaster, or sell it)."  (text, line 263)

> Note for you (not shown in game): the motherlode: every comrade's record, not just yours

- "[Resistance] Someone fed the master terminal's own code back into it. Your record comes back clean."  (chat message, line 273)

> Note for you (not shown in game): part of: wipe record with chip

- "[Resistance] The master core's code goes into the system. %d records come back clean: no violations, no BOLOs, nobody wanted. The core is spent."  (message, line 276)
- "[Resistance] The chip's code goes into the system. Your record comes back clean: no violations, no BOLO, not wanted. The chip is spent."  (chat message, line 279)
- "[Resistance] Your face is still known, though: a fighter in the open is hunted whatever the records say."  (chat message, line 282)

> Note for you (not shown in game): Two fragments in your pockets, however they got there, are a chip.

- "[Resistance] Two data fragments, one whole chip."  (chat message, line 320)

## tips that pop up the first time something happens (sv_livingcity_hints.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_hints.lua`


> Note for you (not shown in game): first steps, in this order, a few seconds after you arrive

- "Welcome to the city"  (title, line 60)
- "Welcome. The city keeps running even when you're not around. Tips like this one pop up the first time you run into something new. Press {gm_showhelp} for your quick menu: the nine things you'll do most, on the number keys (keys 6 to 8 change depending on what you're looking at). Press {+menu_context} for the full menu: everything you can do, with the guide at the top. You can turn these tips off in its Settings."  (text, line 61)
- "First stop: Civil Intake"  (title, line 62)
- "You've just arrived in the city with no papers, no room and no ration card. Go to Civil Intake to register (an arrow on your screen shows the way): press {+use} on the terminal there and fill in your details. Until you register you can't get rations or Union work, and Civil Protection units will ask for papers you don't have."  (text, line 63)
- "You're registered, and your identity papers are in your pockets ({gm_showteam}). Next, get a room from Housing Allocation: press {+use} on its terminal, show your papers, pick a housing block, and stay next to the terminal while it searches. Until you have a room, wait near Civil Intake when a curfew starts: you're allowed to be there."  (text, line 65)
- "Your menus"  (title, line 66)
- "{gm_showteam} opens your pockets (eat, drink, make things, give, wear). {gm_showspare1} opens jobs and quests. {gm_showspare2} shows your faction and rank."  (text, line 67)
- "{gm_showspare2} shows your faction. Zombies don't have pockets."  (text, line 68)
- "You're a citizen"  (title, line 69)
- "Pick a Union job on your job board ({gm_showspare1}) and work shifts to earn credits and Civil Standing. The higher your standing, the more the Commissary will sell you, and at 100 standing you can join Civil Protection."  (text, line 70)
- "You're in the Resistance"  (title, line 71)
- "You start in plain clothes, so Civil Protection units leave you alone unless they see a gun in your hand. To put on your Resistance gear, open {+menu_context} > Resistance > Gear up. Rebel territory is your home base: the quartermaster, the Resistance supply crate and the vegetable pots are there."  (text, line 72)
- "A shackled vortigaunt"  (title, line 73)
- "You belong to the Combine. You work the Union's shifts (job board, {gm_showspare1}), and your collar suppresses your vortessence (your powers). The Resistance can cut your shackles. Once you're free you can heal and attack with your powers, but Civil Protection units will hunt you."  (text, line 74)
- "Your vortessence: {+attack} fires a bolt at whatever you're looking at, and {+attack2} heals whoever is in front of you, or yourself. Outside rebel territory, Civil Protection units go after you as soon as they see you."  (text, line 76)
- "Civil Protection"  (title, line 77)
- "You're Overwatch: the Combine's soldiers, not its police. Your operations are on {gm_showspare1}. When Civil Protection units call for backup, go and help them. In your quick menu ({gm_showhelp}), 1 is Call for backup and 2 sends your 10-20 (marks where you are for other units). The Civil Protection Commissary issues your ammunition and grenades ({gm_showteam} marks the way to it)."  (text, line 78)
- "Your Arrest Baton: {+attack} hits, {+attack2} arrests, {+reload} searches. Your directives (orders) are on {gm_showspare1}. Your quick menu ({gm_showhelp}) puts these on the number keys: call for backup, send your 10-20 (where you are), a BOLO (a lookout for someone), your mask's voice lines and the records terminal, plus search and cuff for whoever you're looking at. Everything else is in {+menu_context} > Unit tools. Get supplies at the Civil Protection Commissary ({gm_showteam} marks the way)."  (text, line 79)
- "Your claws: {+attack} swipes, {+attack2} moans. The infestation zone is your home. You don't need to eat, and you never go down to bleed out: when your health runs out, you die."  (text, line 81)
- "Your tools"  (title, line 82)
- "{+menu_context} > Unit tools has everything, with a note on what each one does: the records terminal (CIDs, violations, loyalty points, BOLOs and requests), your mask's voice lines, and actions for whoever you're looking at: search, cuff and drag (your quick menu, {gm_showhelp}, has the ones you use most). You don't queue for rations: your ration, ammunition and grenades are handed out at the Civil Protection Commissary ({gm_showteam} marks the way)."  (text, line 83)
- "Chat is spoken out loud: only people near you can hear it. In {+menu_context} > Talk you can yell, whisper, describe what you're doing or what's happening around you, or talk out of character (in chat: /y yells, /w whispers, /me and /it describe, // is out of character)."  (text, line 85)
- "Chat is spoken out loud: only people near you can hear it. Start a message with // to talk out of character to everyone."  (text, line 86)
- "Need a hand?"  (title, line 87)
- "To reach the staff, open {+menu_context} > Help > Ask staff for help (or type @ and then your message in chat). Use it for anything out of character: you're stuck, you have a rules question, or someone is breaking the rules."  (text, line 88)
- "From 21:00 to 05:00 it's night: the city goes dark and curfews happen three times as often. {+menu_context} > The city shows the current time."  (text, line 90)
- "It's night. The streets are darker, and most of the living stay indoors."  (text, line 91)
- "When it rains, it washes the blood off the streets (graffiti stays). Clean water comes from the vending machines and the taps; canal water needs boiling at a stove or a fire."  (text, line 93)
- "{+menu_context} > Me > Pose lets you sit, kneel, lie down or lean (move to stand back up). Me > Gesture: wave, salute, bow, nod and more. Me > Put my hands up raises your hands."  (text, line 95)
- "More than one life"  (title, line 96)
- "You can have more than one character in the city. Go to {+menu_context} > Me > My characters to switch between them or make a new one."  (text, line 97)
- "Hunger and thirst"  (title, line 98)
- "Your hunger and thirst go down over time (the bars at the top left; with the quiet HUD, they only appear once they get low). Get rations from the ration dispensers, and water from vending machines and sinks. If either one reaches zero, you start dying."  (text, line 99)
- "Your hunger and thirst go down over time (the bars at the top left; with the quiet HUD, they only appear once they get low). The Resistance's supply crate in rebel territory gives you food; bins, fishing and the vegetable pots help too. If either one reaches zero, you start dying."  (text, line 100)
- "Where to find your numbers"  (title, line 101)
- "This server hides numbers on screen. Your credits and Civil Standing are shown at the top of your pockets ({gm_showteam}), and your rank and progress on {gm_showspare2}."  (text, line 102)
- "Camera sway"  (title, line 103)
- "The camera sways slightly as you walk and dips when you land. If that bothers you, turn it off in {+menu_context} > Settings > Camera sway (this only changes it for you)."  (text, line 104)

> Note for you (not shown in game): what happens to you

- "You're down"  (title, line 107)
- "You're bleeding out, but you're not dead yet. Anyone can get you back up by pressing {+use} on you. While you're down you can only whisper. If nobody is coming, you can choose {+menu_context} > Me > Give up."  (text, line 108)
- "Back on your feet"  (title, line 109)
- "You're back up, but badly hurt. Heal yourself with a bandage from your pockets ({gm_showteam}; you can make one from two rags), a medkit, or a medic."  (text, line 110)
- "You're wanted"  (title, line 111)
- "Civil Protection units are coming to arrest you. Stay out of their sight and your wanted level drops over time. Or turn yourself in for half the sentence: walk up to a unit and press {+use} on them (or use {+menu_context} > Me > Give myself up)."  (text, line 112)
- "Civil Protection units can be wanted too. Stay out of sight and your wanted level drops over time, or press {+use} on another unit to turn yourself in."  (text, line 113)
- "Every Civil Protection unit is looking for you"  (title, line 114)
- "Units now have their pistols out. If your wanted level rises again, Overwatch soldiers are sent, and they shoot to kill instead of arresting you. Stay out of every Civil Protection unit's sight for 45 seconds to lower it (it drops faster in rebel territory)."  (text, line 115)
- "Overwatch is coming"  (title, line 116)
- "A squad of Overwatch soldiers is hunting you, and they shoot to kill. Get out of their line of sight and stay hidden. Your wanted level drops twice as fast in rebel territory."  (text, line 117)
- "Stop and search"  (title, line 118)
- "A Civil Protection unit is searching you. Stand still (putting your hands up helps: {+menu_context} > Me). If you walk away, you'll be wanted for evading inspection. Anything illegal they find is taken from you."  (text, line 119)
- "Your hands are cuffed"  (title, line 120)
- "You can't use anything, and you can only walk. Someone else can uncuff you. If nobody is around, try {+menu_context} > Me > Work at the cuffs to get free; if anyone sees you doing it, they tighten the cuffs."  (text, line 121)
- "Sociostability: marginal"  (title, line 122)
- "The city's alert level has gone up: Civil Protection units will stop and search more people on the street. Keep your papers ready and don't carry anything illegal. The current level is shown at the top of your screen."  (text, line 123)
- "Units now stop 50% more people. The level shows on your mask's display, and officers can change it in {+menu_context} > Unit tools."  (text, line 124)
- "Judgment waiver"  (title, line 125)
- "This is the city's highest alert level: Civil Protection units are allowed to kill whenever they see fit. Get indoors and stay out of sight until it ends."  (text, line 126)
- "You may use lethal force at your own discretion, and units stop twice as many people. It ends when the city calms down, or when an officer ends it."  (text, line 127)
- "Any contraband (illegal items) in your pockets will be found in a search. Your stash at home ({+menu_context} > Getting by) is never searched, but inspection sweeps sometimes raid it."  (text, line 129)
- "Don't run in front of Civil Protection units"  (title, line 130)
- "A Civil Protection unit told you to stop running. Stop within two seconds and nothing more happens. If you keep running, you'll be wanted for fleeing."  (text, line 131)
- "In custody"  (title, line 132)
- "Serve your sentence and you'll be let out at the release point. A friend can give you a lockpick (Give, in their pockets), and you can pick your cell door when no guard is looking, but escaping makes you wanted. If there's a Combine console in your cell, press {+use} on it to fly a city scanner while you wait."  (text, line 133)
- "Your Civil Standing dropped because of your arrest. Community service jobs on your {gm_showspare1} board earn it back, and so does staying out of trouble."  (text, line 135)
- "You're out"  (title, line 136)
- "You escaped, so you're wanted. Get out of sight. Spare clothes or a uniform will disguise you, and forged papers turn you into someone else."  (text, line 137)
- "Get home"  (title, line 138)
- "A Civil Protection unit has caught you outside after curfew. After three warnings you'll be wanted. The arrow on your HUD points to your housing block. A travel permit gets you past one curfew stop."  (text, line 139)
- "In a CP uniform"  (title, line 140)
- "Civil Protection units on the street think you're one of them, for a while. Don't stay near real units, don't commit crimes, and don't let one search you. Most Combine doors will open for you."  (text, line 141)
- "In Resistance gear"  (title, line 142)
- "Resistance fighters think you're one of them, and Civil Protection units will shoot you on sight. If you stand close to a fighter, they may ask you questions you can't answer, and your cover is blown."  (text, line 143)
- "In plain clothes"  (title, line 144)
- "You look like an ordinary citizen. If a Civil Protection unit sees a gun in your hand, your disguise is blown. Never change clothes in front of a unit."  (text, line 145)
- "You look like an ordinary citizen. Useful for undercover work: citizens talk more freely to you, and nobody salutes you."  (text, line 146)
- "Cover blown"  (title, line 147)
- "They've recognised you. Get away, and change clothes somewhere nobody can see you."  (text, line 148)
- "Conduct strike"  (title, line 149)
- "That kill had no roleplay reason behind it. Two strikes sends you to prison, four gets you kicked from the server. Always give people a reason first: a warning, a demand, or a fight they started."  (text, line 150)
- "A new life"  (title, line 151)
- "Death is permanent here: your last character is gone for good. You have a new name and a new face, and nobody knows you. Getting shot puts you down to bleed out before you die, so next time someone may reach you and get you up in time."  (text, line 152)
- "A new rank can unlock new gear, new jobs and more trust. {gm_showspare2} shows what your rank gives you access to."  (text, line 154)
- "A new rank can unlock new gear: grenades are issued from the rank of Metrocop up. {gm_showspare2} shows what your rank gives you access to."  (text, line 155)
- "A Resistance Member"  (title, line 156)
- "Resistance fighters will follow you now: press {+use} on one in rebel territory to have them follow you (three at most). Press {+use} on them again to send them home."  (text, line 157)
- "Eat it from your pockets ({gm_showteam}) when you're hungry. You get one ration per allocation, and allocations come twice as often during a ration distribution. If your Civil Standing is too low, you get nothing."  (text, line 159)
- "Homemade arms"  (title, line 160)
- "It counts as contraband while it's in your pockets, until you draw (equip) or load it ({gm_showteam}), and a search will find it. The black market dealer buys it, and the Resistance quartermaster pays 50% more."  (text, line 161)

> Note for you (not shown in game): what happens around you

- "Ration distribution"  (title, line 164)
- "Rations are handed out twice as often right now. Join a ration line and wait your turn, or press {+use} on a dispenser."  (text, line 165)
- "Keep the ration lines in order. Citizens who crowd a Civil Protection unit get moved along."  (text, line 166)
- "Inspection sweep"  (title, line 167)
- "Civil Protection units are stopping and searching everyone. If you're carrying contraband, put it in your stash at home or stay off the streets."  (text, line 168)
- "Stop and search citizens with your baton ({+reload}). Anything you confiscate earns you credits and XP."  (text, line 169)
- "Block raid"  (title, line 170)
- "Civil Protection units are raiding a housing block: searching residents and taking any contraband left lying around. Whoever dropped it becomes wanted."  (text, line 171)
- "A raid team is searching a housing block. Confiscated contraband is traced back to whoever owns it."  (text, line 172)
- "Curfew: go home. The arrow on your HUD points to your housing block, and you have a grace period to get there. After that, any Civil Protection unit who sees you outside gives you three warnings, then you're wanted."  (text, line 174)
- "Citizens have a grace period to get home. After it ends, anyone still outside gets three warnings from a Civil Protection unit, then they're wanted."  (text, line 175)
- "Get inside your housing block now. Extra Civil Protection units are on the streets. Once the grace period ends, anyone outside gets three warnings, then they're wanted."  (text, line 177)
- "Extra Civil Protection units are on the streets. Clear the streets: three warnings, then anyone still outside is wanted."  (text, line 178)
- "A rebel raid"  (title, line 179)
- "Resistance fighters are attacking a checkpoint, and the Civil Protection units nearby are fighting back. Keep your head down, or stay well away."  (text, line 180)
- "Resistance fighters are attacking a checkpoint. Join the fight, or stay hidden. Either way, it's being reported on the radio."  (text, line 181)
- "Resistance fighters are attacking a checkpoint. In {+menu_context} > Unit tools, Call for backup sends units to you, and Send my 10-20 shows them where you are."  (text, line 182)
- "Civil Protection sweep into rebel territory"  (title, line 183)
- "An armed Civil Protection team is going into rebel territory. Stay away from there."  (text, line 184)
- "An armed Civil Protection team is going into rebel territory, and the fighters are fighting back. Help the fighters, or get away from there."  (text, line 185)
- "An armed team is sweeping rebel territory. Kills there win ground back from the Resistance."  (text, line 186)
- "The infestation has broken out: infected are in the nearby streets, and the area is in lockdown. Get indoors."  (text, line 188)
- "The infected are loose in the streets near the infestation. Kill them and contain the outbreak."  (text, line 189)
- "The infestation has broken out. The streets are yours to roam, for now."  (text, line 190)
- "The city is in unrest"  (title, line 191)
- "The Resistance now holds enough of the city to cause unrest: expect more inspections and raids, fewer rations, and cheaper black market prices. See {+menu_context} > The city > Who holds the city."  (text, line 192)
- "Full compliance"  (title, line 193)
- "The Combine holds the whole city: neither the Resistance nor the infestation has spread. Expect fewer skirmishes and higher black market prices. See {+menu_context} > The city > Who holds the city."  (text, line 194)

> Note for you (not shown in game): what's near you

- "Someone's down"  (title, line 197)
- "They're bleeding out. Press {+use} on them to get them up (a bandage makes it faster). To pull them into cover, look at them and choose Drag them along in your quick menu ({gm_showhelp}). Shooting them kills them."  (text, line 198)
- "They're bleeding out. Press {+use} on them to get them up; if they're wanted, {+use} cuffs them where they lie. To pull them along with you, choose Drag them along in your quick menu ({gm_showhelp}). Shooting them kills them."  (text, line 199)
- "Press {+use} on it and stay next to it for a few seconds to search it: you may find food, credits, ammunition, and sometimes clothes or a keycard. Don't do it where a Civil Protection unit can see you. You can also look at it and choose Haul the body in {gm_showhelp}: Morticians are paid to drag the dead to the incinerator."  (text, line 201)
- "Press {+use} on it and stay next to it for a few seconds to search it. Dead rebels sometimes still carry their gear."  (text, line 202)
- "Press {+use} on a bin or dumpster to search it: you can find scrap, rags, tins, seeds and sometimes gun parts. While looking at one, you can hide things in it from your pockets ({gm_showteam}), but anyone can find them."  (text, line 204)
- "Press {+use} on a bin or dumpster to search it (bins in rebel territory have better finds). While looking at one, you can leave things in it from your pockets ({gm_showteam}) for someone else to collect: a dead drop."  (text, line 205)
- "Press {+use} to open it. Put something in it and it becomes yours, locked to everyone else. Civil Protection units can open any locker and confiscate anything illegal inside."  (text, line 207)
- "Each locker belongs to whoever claimed it. Press {+use} to search one: you can confiscate contraband, and the owner becomes wanted."  (text, line 208)
- "An apartment for rent"  (title, line 209)
- "To rent it, look at the door and open {+menu_context} > This door > Rent it. It's a place of your own, locked to everyone except you and anyone you give a key to (look at them and open {+menu_context}). {+menu_context} > Home locks and unlocks it."  (text, line 210)
- "A market stall"  (title, line 211)
- "Someone is selling things here. Press {+use} to see what's for sale and the prices."  (text, line 212)
- "A licensed trader's stall. Press {+use} to search it. An officer can revoke the trader's license from the records terminal."  (text, line 213)
- "Something written"  (title, line 214)
- "A note or a notice. Press {+use} to read it; you can also take it with you."  (text, line 215)
- "A note or a notice. Press {+use} to read it. Civil Protection units can tear notices down."  (text, line 216)
- "The city's laws"  (title, line 217)
- "This board lists the city's laws. Press {+use} to read them, or read them anywhere in {+menu_context} > The city > The city's laws."  (text, line 218)
- "Too much to carry"  (title, line 219)
- "You're carrying too much weight, so you move slower. Drop something, or carry a satchel so you can hold more."  (text, line 220)
- "Press {+use} while standing in water to drink, but untreated water can give you parasites. You can fill empty bottles and cans here from your pockets ({gm_showteam}), then boil them before drinking. You can also fish here with a fishing line."  (text, line 222)
- "Press {+use} to drink (there's a small chance of parasites). Fill empty bottles and cans here from your pockets ({gm_showteam}), then boil them before drinking."  (text, line 225)
- "Near a stove or fire, you can cook raw meat and fish and boil water from your pockets ({gm_showteam})."  (text, line 227)
- "Vending machine"  (title, line 228)
- "Press {+use} to buy a can of Breen's Private Reserve. It quenches your thirst, and makes you a little dizzy."  (text, line 229)
- "Press {+use} to buy a can. Or, with a multitool: aim at the machine and fire, and after ten seconds it drops five to eight free cans. Don't do it where a Civil Protection unit can see you."  (text, line 230)
- "Ration dispenser"  (title, line 231)
- "Press {+use} to get your ration. Each ration takes one ration card, and you earn a card for each Union shift you finish. You get one ration per allocation, and none if your Civil Standing is too low. A forged ration card gets you one anyway."  (text, line 232)
- "Press {+use} for your ration (it takes one ration card). Or, with a multitool: aim at the dispenser and fire, and after ten seconds it spits out five to eight ration packets, with no coupon and no record. Don't do it where a Civil Protection unit can see you."  (text, line 233)
- "Citizens get one ration per allocation here. Civil Protection units don't queue for rations."  (text, line 234)
- "Supply drop"  (title, line 235)
- "A crate of Union supplies has arrived at the loading dock. Anyone can press {+use} on it to take a load, but if a Civil Protection unit sees you there, you'll be warned and then wanted."  (text, line 236)
- "A Combine supply drop: guns, ammunition and medicine. Press {+use} on the crate to take a load. The Civil Protection units guarding it will fight you."  (text, line 237)
- "Guard this supply drop: if anything is still in the crate when the convoy leaves, every Civil Protection unit nearby gets paid. The directive is on your board."  (text, line 238)
- "A radio jammer"  (title, line 239)
- "Set it down from your pockets ({gm_showteam}). For four minutes, nearby Civil Protection radios are just static, call boxes can't get through, and scanner photos never reach Civil Protection. It beeps, so units will come looking for it."  (text, line 240)
- "Hold it and press {+use} on junk (a wrecked car, a radiator, pipes, a crate) to pry scrap, rags and chemicals out of it. It's loud, and the nearest Civil Protection unit will come to check. It's also a weapon: if a unit sees it in your hand, you're wanted. Put it away when you're on the street."  (text, line 242)
- "You're being interrogated. Choose Talk (on screen, or in {gm_showhelp}) and the beating stops, but you give away a Resistance hideout, and if you're in the Resistance, your cell will know you talked. Or stay silent and take the beating: it won't kill you."  (text, line 244)
- "Broken feet"  (title, line 245)
- "You can't run until your feet heal (the time left is on your screen). Dying or leaving the server doesn't make them heal faster."  (text, line 246)
- "Combine property"  (title, line 247)
- "You've been turned into a stalker: slow, unarmed and unable to speak. Your job board has work orders for you. It ends when your sentence is served, or when you die."  (text, line 248)
- "A Resistance member saw you informing to Civil Protection. For half an hour, every Resistance member sees TRAITOR over your head, and their fighters will shoot you. Stay away from rebel territory."  (text, line 250)
- "Combine data terminal"  (title, line 251)
- "A Combine computer. You can't use it."  (text, line 252)
- "Only a Hacker can do this: aim the multitool at it, left click, and stay close for thirty seconds. Halfway through, the alarm goes off and a squad is sent. One terminal gives you a data fragment, which is half a chip: download from a second, different terminal and the two fragments make a whole data chip. You can sell the chip to the black market dealer, have the lab's scientist decode it (every Civil Protection unit is then marked for the whole Resistance to see), or plug it into a terminal to wipe your criminal record."  (text, line 253)
- "A Combine data terminal. If the Resistance hack it, an alarm goes off: DATA BREACH."  (text, line 254)
- "The master terminal"  (title, line 255)
- "The Combine's master terminal. You can't use it."  (text, line 256)
- "The biggest prize. Only a Hacker can do this: aim the multitool at it, left click, and stay with it for a full minute. A third of the way in, the alarm goes off and a bigger squad is sent. You get a master data core: the black market dealer pays a fortune for it, the quartermaster can decode it to mark every Civil Protection unit for ten minutes, and plugged into a terminal it wipes the criminal record of every Resistance member. The terminal can't be hacked again for an hour."  (text, line 257)
- "The master terminal. If the Resistance hack it, every alarm in the nexus goes off."  (text, line 258)
- "A data fragment"  (title, line 259)
- "Half of a data chip. Download data from a second, different terminal, and the two fragments combine into a whole chip. It's contraband: hide it."  (text, line 260)
- "The master data core"  (title, line 261)
- "The biggest prize. It's contraband: hide it well. The black market dealer pays a fortune for it; the quartermaster can decode it to mark every Civil Protection unit for the whole Resistance for ten minutes; used at a terminal, it wipes the criminal records of every Resistance member in the city."  (text, line 262)
- "A Combine data chip"  (title, line 263)
- "It's contraband: hide it. The black market dealer pays well for it. The Resistance quartermaster can decode it (stand near him and Use it from your pockets): every Civil Protection unit is then marked for the whole Resistance for five minutes. Or use it at a terminal to wipe your own criminal record."  (text, line 264)
- "The lab"  (title, line 265)
- "Your cell's lab. Press {+use} on the scientist: he makes guns, ammunition, armour, radio jammers, bypass charges and Freq 7 radios. Bring the materials and it's free, or pay him (cheaper than the black market). Stay in the lab while he works."  (text, line 266)
- "A Resistance lab. Press {+use} on the scientist to shut it down: he's taken away, and nothing can be made here for a while."  (text, line 267)
- "A cluttered lab bench and a nervous scientist. He only works for the Resistance. Everyone else has to buy guns from the black market."  (text, line 268)
- "This transformer powers the district: streetlights, loudspeakers, screens, forcefields and Combine door locks. If it goes down, a Maintenance Technician can repair it by pressing {+use} on it."  (text, line 270)
- "This transformer powers the district, including the Combine door locks. A multitool shorts it out in twelve seconds: the lights go out and Combine doors open, until someone repairs it."  (text, line 271)
- "This transformer powers the district, including our door locks and forcefields. Keep the Resistance away from it."  (text, line 272)
- "Combine forcefield"  (title, line 273)
- "Civil Protection units can walk through it. Nobody else can, unless they swipe a Combine keycard ({+use}). It shuts off when the district's power goes out."  (text, line 274)
- "Civil Protection units can walk through it. A Combine keycard ({+use}) opens it for a moment, a multitool shorts it out for a minute, and it shuts off when the district's power goes out."  (text, line 275)
- "Combine power bank"  (title, line 276)
- "Powers a checkpoint. The turrets and forcefields cabled to it run off it, and it gets its power from the district's transformer: if the transformer goes down, so do they."  (text, line 277)
- "Powers a checkpoint. A multitool (take it out, aim at the power bank and press {+attack}) shorts it out for two minutes, and every turret and forcefield connected to it shuts off. Near the infestation, this lets the infected break out."  (text, line 278)
- "Your checkpoint's power supply. Deploy turrets near it ({+menu_context} > Civil Protection). Keep the Resistance away from it: if it goes down near the infestation, the infected break out."  (text, line 279)
- "Combine turret"  (title, line 280)
- "It shoots the infected, wanted people and known rebels, and leaves everyone else alone. Its cable runs to the checkpoint's power bank."  (text, line 281)
- "If you're a known rebel, it shoots you on sight. Cut its power (the power bank, or the district's transformer) and it folds up and stops shooting."  (text, line 282)
- "It shoots the infected and wanted people. Each Civil Protection unit can put up two ({+menu_context} > Civil Protection) and pack them up again with {+use}."  (text, line 283)
- "The city's dead bodies are brought here. Haul a body over (Morticians: press {+use} on a body; anyone else: look at it and choose Haul the body in {gm_showhelp}) and let go of it next to the incinerator, or press {+use} on the incinerator. Attendants are paid for each body."  (text, line 285)
- "The city's incinerator. A body burned here is never identified. To haul one over, look at it and choose Haul the body in {gm_showhelp}."  (text, line 286)
- "Reclamation point"  (title, line 287)
- "Press {+use} to hand in scrap, empty cans and bottles for a few credits and a little Civil Standing. The loyal citizen's way to get rid of junk."  (text, line 288)
- "Press {+use} to hand in scrap, cans and bottles for credits and Civil Standing. Or keep the scrap: your cell can make ammunition from it."  (text, line 289)
- "Citizens hand in scrap here for credits and Civil Standing."  (text, line 290)
- "Combine console"  (title, line 291)
- "For prisoners and Civil Protection units: press {+use} to fly one of the city's scanners. Your body stays here. Left click takes a flash photo; if you flash a Civil Protection unit, your sentence gets longer. Get within about ten feet of rebels, free vortigaunts, wanted people or zombies and photograph them to earn Civil Standing (it never shortens your sentence). R disconnects."  (text, line 292)
- "Press {+use} to fly a city scanner. Left click photographs anything within about ten feet: any rebels, free vortigaunts, wanted people and zombies it catches are highlighted for every Civil Protection unit."  (text, line 293)
- "Scanner report"  (title, line 294)
- "A scanner photographed someone. They're outlined in red for a minute, visible through walls, and rebel territory is marked on your screen. Go and catch them."  (text, line 295)
- "A scanner photographed you. For a minute, every Civil Protection unit can see where you are. Get out of sight, shoot the scanner down, or throw a smoke grenade: a scanner can't photograph anyone inside or behind smoke."  (text, line 297)
- "The Commissary"  (title, line 298)
- "Press {+use} to shop. The higher your Civil Standing, the more it will sell you."  (text, line 299)
- "Press {+use} to shop: ammunition, batteries and grenades for Civil Protection units. (A Civil Protection Commissary hands these out for free.)"  (text, line 300)
- "Civil Protection Commissary"  (title, line 301)
- "Press {+use} to be issued supplies: grenades for your rank, ammunition for your weapons, armour, bandages and your ration. You can do this once every two minutes; in between, the unit counter there is open to buy extras."  (text, line 302)
- "Press {+use} to be issued supplies: grenades, ammunition, armour, bandages and a ration. You can do this once every two minutes."  (text, line 303)
- "Civil Protection's supply point. Only Civil Protection units can use it."  (text, line 304)
- "The black market"  (title, line 305)
- "Press {+use} to trade: papers, uniforms, lockpicks, spray cans, seeds, gun parts. He buys almost anything. Don't let a Civil Protection unit see you trading with him."  (text, line 306)
- "A black market dealer. Walk up to him to bust him: he disappears for 15 minutes, and you get paid."  (text, line 307)
- "A supply crate"  (title, line 308)
- "The Resistance's food store: press {+use} to take a tin, once every four minutes. To add food from your pockets, use {+menu_context} > Resistance > Donate food."  (text, line 309)
- "A Resistance supply crate. You can add food from your pockets: {+menu_context} > Resistance > Donate food."  (text, line 310)
- "A hidden stash of Resistance supplies. Press {+use} to confiscate all of it."  (text, line 311)
- "Press {+use} on it to plant a seed packet. In a few minutes it grows three lots of vegetables, and anyone can harvest a pot once it's ripe."  (text, line 313)
- "A Resistance garden. Press {+use} to pull it up."  (text, line 314)
- "Resistance graffiti. Press {+use} on it to scrub it off and gain Civil Standing, or leave it."  (text, line 316)
- "The lambda, the Resistance's symbol. Spray cans (from the black market) put it on walls. Tags near rebel territory help the Resistance take more ground. Don't let a Civil Protection unit see you spraying."  (text, line 317)
- "Press {+use} on a lambda tag to scrub it off and earn XP."  (text, line 318)
- "The quartermaster"  (title, line 319)
- "Press {+use} to trade. He sells the black market's stock to the Resistance, and pays 50% more for homemade guns and ammunition."  (text, line 320)
- "From the rank of Resistance Member up, press {+use} on a fighter to have them follow you and fight alongside you (three at most). Press {+use} on them again to send them home."  (text, line 322)
- "Everyone here has a name and a life. Press {+use} on someone to talk: they may tell you what they've heard or give you a bit of food, or you can pick their pocket. They remember how you treat them."  (text, line 324)
- "With your baton out: {+use} stops a citizen, {+reload} searches them (sympathizers carry more), and {+attack2} detains them."  (text, line 325)
- "Civil Protection"  (title, line 326)
- "Don't run in front of Civil Protection units and don't crowd around them. If one stops you, stand still until they're done."  (text, line 327)
- "Don't run in front of Civil Protection units and don't crowd around them. In plain clothes, keep your gun out of sight."  (text, line 328)
- "Someone wanted"  (title, line 329)
- "Someone near you is wanted. Your baton's {+attack2} arrests them, and {+reload} searches them. If it turns violent, use {+menu_context} > Unit tools > Call for backup."  (text, line 330)
- "A shackled vortigaunt"  (title, line 331)
- "From the rank of Member up, you can cut its shackles: look at it and choose {+menu_context} > Cut the vortigaunt's shackles (it takes ten seconds, and no Civil Protection unit can be watching). It then joins the Resistance."  (text, line 332)
- "People don't know your name until you tell them. To introduce yourself, look at someone and choose {+menu_context} > Tell them my name (or show them your papers). Until then they see a description of you instead, which you can change in {+menu_context} > Me > Change how strangers see me."  (text, line 334)
- "One punch kills a bird. Cook it at a stove or burning barrel from your pockets ({gm_showteam})."  (text, line 336)
- "Weak, but don't turn your back on it. Several punches kill one, and it leaves meat you can cook. Don't go AFK in an alley."  (text, line 338)
- "Rebel territory"  (title, line 339)
- "Resistance fighters leave citizens alone. The bins here have better finds, and the black market is open ({+menu_context} > Getting by). Stay out of any shooting."  (text, line 340)
- "Your home ground, among friends. The quartermaster, the supply crate and the vegetable pots are here, and you can make guns and ammunition here ({gm_showteam})."  (text, line 341)
- "Resistance fighters shout one warning, then open fire. Only come in with a sweep or with backup. Kills here win ground back from the Resistance."  (text, line 342)
- "The infestation"  (title, line 343)
- "Zombies and headcrabs. There's nothing here worth the risk unless you have a reason to be here."  (text, line 344)
- "Containment jobs on your board send Civil Protection units in here. Kills here push the infestation back."  (text, line 345)
- "Your block"  (title, line 347)
- "This is your housing block: come back here when a curfew starts. You can make things here ({gm_showteam}), and keep anything you don't want found in your stash ({+menu_context} > Getting by)."  (text, line 348)
- "Combine only"  (title, line 349)
- "You're trespassing in a Combine-only area. Leave before the countdown on your screen runs out, or you'll be wanted."  (text, line 350)
- "You're in plain clothes with a gun in your hand. If a Civil Protection unit sees it, your disguise is blown. Switch to your fists or holster the gun ({+menu_context} > Me)."  (text, line 352)
- "{+attack} throws, {+reload} switches between smoke, flashbang and gas. Smoke hides you, a flashbang blinds people, and gas chokes anyone without a mask. Civil Protection units wear masks."  (text, line 354)

> Note for you (not shown in game): how you're doing

- "You're hungry. Eat something from your pockets ({gm_showteam}). No food? Try a ration dispenser, the Commissary, a bin, fishing, or something you can cook."  (text, line 358)
- "You're hungry. Eat something from your pockets ({gm_showteam}). No food? Try the supply crate in rebel territory, a bin, the vegetable pots, or fishing."  (text, line 359)
- "You're thirsty. Drink something from your pockets ({gm_showteam}). Nothing to drink? Try a sink, a vending machine, or open water (boil it first if you can)."  (text, line 361)
- "You drank untreated water and caught parasites. You'll get hungry and thirsty faster, and keep coughing, until you take antiparasitic tablets (from the Commissary)."  (text, line 363)
- "You're hurt. Heal yourself with a bandage from your pockets ({gm_showteam}; two rags make one), a medkit, or a medic."  (text, line 365)
- "Low standing"  (title, line 366)
- "Your Civil Standing is below zero: you get no rations, and Civil Protection units keep an eye on you. Community service jobs on your {gm_showspare1} board earn it back, and so does staying out of trouble."  (text, line 367)
- "You could join Civil Protection"  (title, line 368)
- "Your Civil Standing is high enough to join Civil Protection. Open {gm_showspare2} to join."  (text, line 369)

> Note for you (not shown in game): what's in your pockets

- "Plant them in a pot in rebel territory: look at the pot and press {+use}. They grow into vegetables in a few minutes."  (text, line 373)
- "Fishing line"  (title, line 374)
- "Stand in the canal or look at the water, then choose Fish in your pockets ({gm_showteam}) or in {+menu_context} > Getting by, and keep still. Cook what you catch."  (text, line 375)
- "A spray can"  (title, line 376)
- "Look at a wall and choose Spray in your pockets ({gm_showteam}) to paint the lambda (the Resistance symbol). If a Civil Protection unit sees you, you're wanted for vandalism."  (text, line 377)
- "Look at a locked door and choose {+menu_context} > This door > Pick the lock (or bind a key to lc_pick). It won't open Combine locks. You can also give one to a prisoner (from your pockets, {gm_showteam}) so they can pick their own cell door."  (text, line 379)
- "A bypass charge"  (title, line 380)
- "Opens any door once, Combine doors included: look at the door and choose {+menu_context} > This door > Pick the lock. It sometimes sets off an alarm, which makes you wanted."  (text, line 381)
- "Opens one Combine door, one time only: look at the door and choose {+menu_context} > This door > Pick the lock. Once used, it's reported stolen and won't work again."  (text, line 383)
- "Raw meat"  (title, line 384)
- "Cook it near a stove, oven or burning barrel, from your pockets ({gm_showteam}). Eating it raw can give you parasites."  (text, line 385)
- "An empty container"  (title, line 386)
- "Fill it in water or at a sink from your pockets ({gm_showteam}), then boil it near a stove or fire before you drink it."  (text, line 387)
- "Untreated water"  (title, line 388)
- "Boil it near a stove or fire first, from your pockets ({gm_showteam}). Drinking it unboiled can give you parasites."  (text, line 389)
- "Put them on from your pockets ({gm_showteam}) to look like an ordinary citizen. Never change clothes in front of a Civil Protection unit."  (text, line 391)
- "Put it on from your pockets ({gm_showteam}): Civil Protection units on the street will think you're one of them, for a while. It's contraband, so a search will find it."  (text, line 393)
- "Resistance gear"  (title, line 394)
- "Put it on from your pockets ({gm_showteam}): Resistance fighters will think you're one of them. So will Civil Protection units, and they'll shoot you."  (text, line 395)
- "Use them from your pockets ({gm_showteam}) to become someone else. It also clears your wanted status, as long as no Civil Protection unit is watching."  (text, line 397)
- "A blank identity form"  (title, line 398)
- "Forge it from your pockets ({gm_showteam}) somewhere private, where no Civil Protection unit can see you."  (text, line 399)
- "A forged ration card"  (title, line 400)
- "Gets you one ration from any dispenser, whatever your Civil Standing and however recently you had one."  (text, line 401)
- "An old radio"  (title, line 402)
- "Tuned to Freq 7, like every radio that isn't Civil Protection's. It's contraband: a search will find it."  (text, line 403)
- "A radio, on Freq 7"  (title, line 404)
- "Freq 7 is the Resistance's secret channel, and you'll also hear what Civil Protection says when it thinks nobody's listening. With a radio transmitter too, {+menu_context} > Talk > On my radio talks on Freq 7. This radio is contraband."  (text, line 405)
- "A travel permit"  (title, line 406)
- "Keep it in your pockets. It gets you past one curfew stop."  (text, line 407)
- "By hand, anywhere, from your pockets ({gm_showteam}): rags make bandages and scrap makes lockpicks. Guns, ammunition, smoke bombs and radio jammers are made from these by the Resistance lab's scientist, only for the Resistance. Everyone else buys them at the black market. Find more materials in bins, by prying junk apart with a crowbar, and on shot-down scanners."  (text, line 409)
- "Your papers"  (title, line 410)
- "Your identity papers. Civil Protection units will ask to see them: look at the unit and choose Show them my papers in {gm_showhelp} (or Show in your pockets, {gm_showteam}). If you lose them, Civil Intake replaces them for a fee. Ration cards are different: you earn one for each Union shift you finish, and each ration takes one."  (text, line 411)
- "Use it from your pockets ({gm_showteam}) to heal yourself. Used on someone who's down, it gets them back up faster and with more health."  (text, line 413)
- "It counts as contraband until you draw (equip) or load it from your pockets ({gm_showteam}), and a search will find it. The black market buys it; the Resistance quartermaster pays more."  (text, line 415)
- "Smuggled supplies"  (title, line 416)
- "These count as contraband in your pockets. Deliver them to where they're going without being stopped."  (text, line 417)
- "Something to throw"  (title, line 418)
- "Throw it from your pockets ({gm_showteam}). Smoke hides anyone inside it from both Civil Protection units and rebels."  (text, line 419)
- "Antiparasitic tablets"  (title, line 420)
- "Take them from your pockets ({gm_showteam}) to cure parasites from untreated water."  (text, line 421)
- "To cuff someone, get up close, look at them and choose {+menu_context} > their name > Cuff them. It only works if their hands are up, they're down, they've been stopped by a Civil Protection unit, or you're behind them. Drag walks them along with you; Uncuff them lets them go."  (text, line 423)
- "A Civil Protection call box"  (title, line 424)
- "It calls Civil Protection to where you are: F1 > Request Civil Protection (or type /request <what's wrong>). Civil Protection units see the request on their screens. You can send one once a minute, and false requests go on your record."  (text, line 425)
- "While you carry it, you can hold more: eight more kilos, and one more large item. Your pockets ({gm_showteam}) show how much you're carrying."  (text, line 427)
- "A storage crate"  (title, line 428)
- "Set it down from your pockets ({gm_showteam}, Set down) and you can store things in it. Only you can open it, but Civil Protection units can open it too."  (text, line 429)
- "A business license"  (title, line 430)
- "While it's in your pockets, you can set down a market stall (sold at the Commissary) and sell things from it at your own prices. An officer can revoke the license."  (text, line 431)
- "A market stall"  (title, line 432)
- "Set it down from your pockets ({gm_showteam}, Set down). Then look at it and Sell things from your pockets at the prices you choose. The money you make waits in the stall's till."  (text, line 433)
- "Write on it from your pockets ({gm_showteam}): leave it as a note, put it up on a wall as a poster, or keep it. You can sign it or leave it unsigned."  (text, line 435)
- "A wedding ring"  (title, line 436)
- "It belonged to someone once. The black market pays well for it."  (text, line 437)

> Note for you (not shown in game): !hints For chat, where nobody's binding can be looked up: the usual keys.

- "Left click"  (text, line 875)
- "Right click"  (text, line 875)

> Note for you (not shown in game): typing in chat

- "[Tips] Tips are now off. Turn them back on in the full menu (C > Settings)."  (chat message, line 888)
- "[Tips] Tips are now on. Each tip shows the first time you run into something."  (chat message, line 891)
- "[Tips] Tips reset. You'll see every tip again as things come up."  (chat message, line 896)
- "[Tips] No tips yet this session. The full guide is in C > Guide / manual."  (chat message, line 900)
- "[Tips] Your last few tips:"  (chat message, line 902)
- "{title}: {text}"  (chat message, line 903)
- "[Tips] Tips are off. Turn them back on in C > Settings."  (chat message, line 905)
- "[Tips] C > Tips I've seen lists every tip you've had. C > Settings turns tips off or starts them over."  (chat message, line 906)

## housing blocks (sv_livingcity_housing.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_housing.lua`


> Note for you (not shown in game): part of: assign block

- "[Living City] You have been assigned to {n}."  (chat message, line 97)

> Note for you (not shown in game): typing in chat

- "[Living City] You live in {n}."  (text, line 147)
- "[Living City] You have no room yet. Ask Housing Allocation for one."  (text, line 148)
- "[Living City] This map has no housing blocks yet."  (chat message, line 149)

> Note for you (not shown in game): the console command lc_setblock

- "[Living City] You have been reassigned to {n}."  (chat message, line 166)

## toilets, baths and what happens without them (sv_livingcity_hygiene.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_hygiene.lua`


> Note for you (not shown in game): part of: register places

- "No toilets found in this city."  (text, line 113)
- "No bathtubs or showers found in this city."  (text, line 114)
- "No beds found in this city."  (text, line 115)

> Note for you (not shown in game): part of: stain

- "A mess to clean"  (text, line 122)
- "Nothing to clean up right now."  (text, line 123)

> Note for you (not shown in game): Sanitation is told

- "A mess to clean up"  (on-screen notice, line 177)
- "Someone soiled themselves {or}. E on it to scrub it up (paid). F1 > Places marks it."  (on-screen notice, line 177)

> Note for you (not shown in game): on the trousers, and on the ground

- "You couldn't hold it"  (on-screen notice, line 197)
- "You've soiled yourself. A toilet, a wash (a bathtub or shower) and clean clothes, or people will keep their distance (and you may make them ill)."  (on-screen notice, line 197)

> Note for you (not shown in game): part of: soil

- "[Living City] Someone nearby has soiled themselves. The smell reaches you a moment later."  (chat message, line 200)

> Note for you (not shown in game): Toilets, baths, clean clothes

- "On the toilet..."  (progress bar, line 218)
- "You get up before you're done."  (text, line 219)

> Note for you (not shown in game): part of: done

- "That's better"  (on-screen notice, line 238)
- "For now. It drained you, though: drink something. Only antiparasitic tablets will stop it coming back."  (on-screen notice, line 238)
- "It drained you, though: drink something."  (on-screen notice, line 239)
- "That's better"  (on-screen notice, line 241)
- "Nothing much to it."  (on-screen notice, line 241)
- "[Living City] Still to do: {left}."  (chat message, line 245)

> Note for you (not shown in game): part of: use bath

- "You step out half washed."  (text, line 255)

> Note for you (not shown in game): part of: done

- "Clean skin, filthy clothes: change into clean ones (spare clothes or overalls from your pockets)."  (on-screen notice, line 265)
- "Scrubbed clean."  (on-screen notice, line 265)
- "You wash. You feel almost human."  (on-screen notice, line 267)

> Note for you (not shown in game): Into clean clothes: spare citizen clothes or Union overalls from your pockets. id: which (else whichever you have). True, or false and why.

- "Your clothes are clean enough."  (text, line 277)
- "You need a clean uniform (the Civil Protection Commissary has them)."  (text, line 280)
- "You need clean clothes: spare citizen clothes or Union overalls (the Commissary sells them)."  (text, line 281)

> Note for you (not shown in game): part of: change clothes

- "Clean clothes"  (on-screen notice, line 288)
- "Better. You still need a wash: a bathtub or a shower."  (on-screen notice, line 288)
- "Better. The old ones can go in the bin."  (on-screen notice, line 288)

> Note for you (not shown in game): The stain on the ground

- "Scrubbing it up..."  (progress bar, line 307)
- "You leave it half done."  (text, line 308)

> Note for you (not shown in game): part of: done

- "Cleaned up a mess"  (text, line 314)
- "Something got on you"  (on-screen notice, line 317)
- "Scrubbing that up, something got on your hands. Your stomach turns."  (on-screen notice, line 317)
- "Cleaned up"  (on-screen notice, line 319)
- "5 credits. Wash your hands."  (on-screen notice, line 319)

> Note for you (not shown in game): people nearby smell it, and may catch it

- "[Living City] Someone near you reeks. Flies, and worse. You'd step back if you were sensible."  (chat message, line 351)

> Note for you (not shown in game): part of: hygiene tick

- "Your stomach cramps"  (on-screen notice, line 369)
- "You need a toilet. Soon. (F1 > What now? shows the nearest.)"  (on-screen notice, line 369)
- "Find a toilet. NOW."  (on-screen notice, line 370)
- "You can't hold it much longer."  (on-screen notice, line 370)

> Note for you (not shown in game): What now? (sv_livingcity_nextstep.lua asks this first)

- "Find a toilet"  (text, line 391)
- "You've soiled yourself. A toilet first, then a wash and clean clothes."  (text, line 391)
- "Your stomach's cramping (parasites): sit on a toilet before it's too late. Antiparasitic tablets stop it for good."  (text, line 392)

> Note for you (not shown in game): part of: hygiene step

- "Get washed"  (text, line 395)
- "You reek. A bathtub or a shower: press E on it."  (text, line 395)
- "Change into clean clothes"  (text, line 400)
- "Your clothes are filthy. Choose this to change into the clean ones in your pockets."  (text, line 400)
- "Get a clean uniform"  (text, line 402)
- "Your uniform is filthy. The Civil Protection Commissary has clean ones; then change into it."  (text, line 402)
- "Get clean clothes"  (text, line 404)
- "Your clothes are filthy. The Commissary sells spare clothes; then change into them."  (text, line 404)

## the Resistance Insider (a Civil Protection unit secretly with the Resistance) (sv_livingcity_insider.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_insider.lua`


> Note for you (not shown in game): Who could see or hear them right now (nobody: they can act).

- "Someone's close enough to hear you."  (text, line 82)
- "Someone can see you."  (text, line 83)

> Note for you (not shown in game): part of: insider watched

- "A Civil Protection unit can see you."  (text, line 86)

> Note for you (not shown in game): part of: ready

- "Not yet: in %d seconds."  (message, line 94)

> Note for you (not shown in game): The checks every Insider action makes first: true, or false and why.

- "Nothing like that is open to you."  (text, line 101)
- "Not now."  (text, line 102)
- "Slip away somewhere nobody's watching first."  (text, line 104)

> Note for you (not shown in game): part of: insider tip

- "a sweep into our ground %s in about %d seconds"  (message, line 123)
- "a housing block raid is on"  (text, line 125)
- "Say what to tell them."  (text, line 128)
- "A friend inside: {or}{RadioNotice}"  (text, line 129)
- "[Inside] Sent on Freq 7, unsigned."  (chat message, line 132)

> Note for you (not shown in game): part of: insider lose record

- "No such person."  (text, line 140)
- "They aren't wanted."  (text, line 141)
- "A record lost through carelessness"  (text, line 143)
- "[Inside] Their record goes missing. Somebody will call it carelessness (-%d Civil Standing)."  (message, line 144)
- "[City] Your record seems to have gone missing. Nobody is looking for you, for now."  (chat message, line 145)

> Note for you (not shown in game): part of: insider skim

- "Only at the Civil Protection Commissary."  (text, line 153)
- "a box of pistol ammunition"  (text, line 158)
- "Your pockets are full."  (text, line 159)
- "Supplies unaccounted for"  (text, line 161)
- "[Inside] Off the shelf and into your pockets, not on the books: %s. Leave them in a bin for the Resistance (-%d Civil Standing)."  (message, line 162)

> Note for you (not shown in game): part of: insider copy

- "Your pockets are full."  (text, line 172)
- "[Inside] You copy out the city's own records: names, routes, who's being watched. The quartermaster pays the most for this."  (chat message, line 174)

> Note for you (not shown in game): At the Civil Protection Commissary, with weedkiller: foul the filter stock (every unit's mask lets gas through for lc_fouled_minutes), or spike the station's food (units fall sick).

- "Only at the Civil Protection Commissary, where the spare filters are kept."  (text, line 185)
- "You'd need weedkiller to soak them in."  (text, line 186)

> Note for you (not shown in game): part of: insider foul

- "[Inside] You soak the spare filter canisters and put them back. For a while, every unit's mask will let gas straight through: theirs as much as anyone's."  (chat message, line 192)
- "A friend inside: their mask filters are fouled. For a while, gas will get to them too."  (text, line 193)

> Note for you (not shown in game): part of: insider spike

- "Only at the Civil Protection Commissary, where the station's food is kept."  (text, line 201)
- "You'd need weedkiller."  (text, line 202)
- "[Inside] A few drops into the station's coffee and rations. Over the next few minutes, the units who eat here will be sick. Don't eat here yourself."  (chat message, line 208)

> Note for you (not shown in game): each unit eats sometime in the next few minutes

- "Something you ate"  (on-screen notice, line 216)
- "The station's coffee tasted wrong. Your stomach turns over: you've been poisoned."  (on-screen notice, line 216)

> Note for you (not shown in game): part of: insider reveal

- "Nothing like that is open to you."  (text, line 230)
- "Look at the one person you want to tell."  (text, line 231)
- "Get closer: this is said quietly."  (text, line 232)
- "[Freq 7] {name} leans in and says the codeword. This unit is the Resistance's friend inside. Keep it to yourself."  (chat message, line 234)
- "[Inside] You say the codeword. They know now."  (chat message, line 235)

> Note for you (not shown in game): Caught: out of the system for good

- "Treason: a mole in Civil Protection"  (text, line 251)

> Note for you (not shown in game): part of: burn insider

- "They know you were the Resistance's man inside. You're wanted, and there's no surrendering. You'll never wear the mask again, nor work for the city or the Union: you're Resistance now, for good."  (on-screen notice, line 253)
- "Dispatch: all units, a traitor in our ranks. Shoot on sight. No surrender accepted."  (text, line 256)

> Note for you (not shown in game): Unmasked (the reckoning, sv_livingcity_stories.lua): no longer undercover, an ordinary Resistance fighter; never Civil Protection (or anyone's man inside) again. Not wanted for it.

- "Out of the mask"  (on-screen notice, line 267)
- "You're Resistance now, in the open. Civil Protection will never have you back."  (on-screen notice, line 267)

> Note for you (not shown in game): unmasked: just never a unit (or any Combine role) again

- "You took off the mask for good. Civil Protection will never have you back: only the Resistance."  (text, line 280)
- "They know what you did. There's no surrendering for you."  (text, line 283)
- "The Union won't have a traitor on its books."  (text, line 284)
- "You're known as a traitor. Only the Resistance will have you now."  (text, line 285)

> Note for you (not shown in game): newly recruited: the leaders hear of it

- "[Freq 7] For the leaders only: we have a friend inside Civil Protection now. {p}. Keep it close."  (chat message, line 319)

> Note for you (not shown in game): A leader coming on hears who's inside, once.

- "[Freq 7] For the leaders only: our friends inside Civil Protection: {names}."  (chat message, line 334)

> Note for you (not shown in game): From the menus (and chat, as a backup)

- "[Inside] {why}"  (chat message, line 343)

## Civil Intake (becoming somebody) (sv_livingcity_intake.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_intake.lua`


> Note for you (not shown in game): part of: register person

- "[Civil Intake] You were processed while in custody: %s, citizen %s. Your papers are in your pockets (F2). Ration cards come from work: each Union shift you finish earns one."  (message, line 222)
- "[Civil Intake] Registration complete. %s, citizen %s. Your identity papers are in your pockets (F2): keep them on you. Ration cards come from work: each Union shift you finish earns one."  (message, line 224)
- "[Civil Intake] Next, go to Housing Allocation to get a room. It's marked on your screen."  (chat message, line 228)
- "[Civil Intake] You already have a room: {n}. Ask at Housing Allocation if you want to know more."  (chat message, line 232)
- "[Civil Intake] You've been given a room in {n}."  (chat message, line 237)

> Note for you (not shown in game): part of: house person

- "[Housing Allocation] {or} is full, so your request was declined. You've been given a room in {n}."  (chat message, line 293)
- "[Housing Allocation] Approved: a room in {n}. It's marked on your screen. From now on, go home there when curfew starts."  (chat message, line 295)
- "[Housing Allocation] This city has no rooms to give out."  (chat message, line 298)

> Note for you (not shown in game): A housed citizen moving to another block.

- "You have no room to move from."  (text, line 308)
- "Transfers are for citizens in good standing ({TRANSFER_STANDING} or more)."  (text, line 310)
- "You moved blocks too recently. Ask again in %d minutes."  (message, line 313)

> Note for you (not shown in game): part of: transfer person

- "[Housing Allocation] {why}"  (chat message, line 319)
- "[Housing Allocation] There's no other block to move you to."  (chat message, line 322)
- "[Housing Allocation] Transfer declined: {or} is full, so you can't move there. You stay in {from}."  (chat message, line 324)
- "[Housing Allocation] Transfer approved: {from} to {n}. It's marked on your screen."  (chat message, line 329)
- "Processing your registration"  (text, line 351)
- "[Civil Intake] Stand still next to the terminal while it registers you."  (text, line 351)
- "Searching the housing register"  (text, line 352)
- "[Housing Allocation] Stand still next to the terminal while it finds you a room."  (text, line 352)
- "Processing your transfer request"  (text, line 353)
- "[Housing Allocation] Stand still next to the terminal while it processes your move."  (text, line 353)
- "Printing your identity papers"  (text, line 354)
- "[Civil Intake] Stand still next to the terminal while it prints your new papers."  (text, line 354)

> Note for you (not shown in game): part of: finish

- "[Civil Intake] You don't have enough credits. New papers cost {fee}."  (chat message, line 379)
- "replacement {what}"  (text, line 382)
- "[Civil Intake] New identity papers issued ({fee} credits). Keep them on you."  (chat message, line 384)

> Note for you (not shown in game): part of: use intake

- "[Housing Allocation]"  (title, line 407)
- "[Civil Intake]"  (title, line 407)
- "The screen says CLOSED. In this city, new arrivals are registered automatically."  (chat message, line 409)
- "%d waiting in line."  (message, line 413)
- "This terminal is only for citizens."  (chat message, line 415)

> Note for you (not shown in game): the registered (and anyone at Housing Allocation): the terminal's own screen

- "Processing another citizen. Wait your turn."  (chat message, line 421)

> Note for you (not shown in game): A button on a terminal's screen. True if the terminal took it on.

- "[Housing Allocation]"  (title, line 469)
- "[Civil Intake]"  (title, line 469)
- "Processing another citizen. Wait your turn."  (chat message, line 473)

> Note for you (not shown in game): part of: desk action

- "You're not registered. Register at Civil Intake first."  (chat message, line 477)
- "Present your identity papers. You have none on you: Civil Intake can give you new ones."  (chat message, line 479)
- "You already have a room. Ask for a transfer instead."  (chat message, line 483)
- "Ration cards aren't issued here. You earn one for each Union shift you finish."  (chat message, line 493)
- "You already have your papers on you."  (chat message, line 498)
- "New papers cost {fee} credits, and you don't have enough."  (chat message, line 501)

> Note for you (not shown in game): the game answering something done in a window (lc_intake_act)

- "[Civil Intake] Go back and stand next to the terminal."  (chat message, line 521)

> Note for you (not shown in game): The registration form, handed in (sv_livingcity_character.lua asks first).

- "Stand next to the terminal to fill in your details."  (text, line 531)
- "Describe yourself: what a stranger would notice about you (at least 8 characters)."  (text, line 534)

> Note for you (not shown in game): part of: intake form check

- "Your description is too long (120 characters at most)."  (text, line 535)

> Note for you (not shown in game): a timer (regularly)

- "[Civil Intake] You walked away from the terminal, so it stopped. Go back to it to carry on."  (chat message, line 564)

> Note for you (not shown in game): on the register, but never handed their papers (everyone from before they were things you carry)

- "[Papers] Your identity papers are in your pockets (F2). Keep them on you: Civil Protection units ask for them."  (chat message, line 609)

> Note for you (not shown in game): a timer (regularly)

- "[Civil Intake] You've arrived in the city with nothing: no papers and no room. Report to Civil Intake to register. Your screen shows the way."  (chat message, line 638)
- "[Housing Allocation] You have nowhere to sleep yet. Go to Housing Allocation and ask for a room. Your screen shows the way."  (chat message, line 640)

> Note for you (not shown in game): on the register: are they carrying their papers?

- "[Civil Protection] Papers. None? Carry them at all times. Civil Intake replaces lost papers."  (chat message, line 658)
- "no papers on them"  (text, line 659)

> Note for you (not shown in game): part of: intake stopped

- "[Civil Protection] No papers. New arrival? Report to Civil Intake. Now."  (chat message, line 666)
- "[Civil Protection] Still no papers. Failure to register."  (chat message, line 670)
- "Failure to register"  (text, line 671)

> Note for you (not shown in game): A unit's own search finds no papers.

- "[Records] No papers, and not registered: a new arrival who has to register at Civil Intake."  (chat message, line 679)
- "[Records] Registered, but not carrying their papers."  (chat message, line 681)

> Note for you (not shown in game): The steps a new arrival takes at the desks before going home (empty when there are none, or intake is off).

- "in line at Civil Intake"  (text, line 799)
- "being registered at Civil Intake"  (text, line 799)
- "in line for Housing Allocation"  (text, line 801)
- "waiting on a housing allocation"  (text, line 801)

> Note for you (not shown in game): Commands What their papers say: their own, or the forged ones they're living under.

- "None yet (ask Housing Allocation)"  (text, line 837)
- "None on file"  (text, line 837)

> Note for you (not shown in game): part of: papers info

- "Citizen {alias}"  (text, line 845)

> Note for you (not shown in game): Show your papers to whoever you're looking at (or read them yourself).

- "[Papers] You have none. Report to Civil Intake to register."  (text, line 858)
- "[Papers] You have no papers on you. Civil Intake can give you new ones."  (text, line 860)

> Note for you (not shown in game): part of: show papers

- "[Papers] They show you their papers: %s, citizen %s."  (message, line 866)
- "[Papers] You hold your papers up for them to see."  (chat message, line 868)

> Note for you (not shown in game): part of: papers

- "[Papers] You have none. Report to Civil Intake to register."  (chat message, line 879)
- "[Papers] %s, citizen %s. Housing: %s.%s"  (message, line 884)
- "(Your papers aren't on you: Civil Intake replaces them.)"  (message, line 885)

> Note for you (not shown in game): the console command lc_register

- "[Living City] Usage: lc_register <name>"  (text, line 910)

> Note for you (not shown in game): the console command lc_unregister

- "[Living City] Usage: lc_unregister <name> (sends them back through Civil Intake)"  (text, line 917)
- "[Living City] Staff have unregistered you. Register again at Civil Intake, then ask Housing Allocation for a room."  (chat message, line 933)

## work you actually do (sv_livingcity_jobgames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_jobgames.lua`


> Note for you (not shown in game): community service is unpaid (sv_livingcity_work.lua): the work still counts

- "You earned %d extra credits for this work, on top of your normal shift pay."  (message, line 112)
- "No extra credits for this work."  (text, line 112)

> Note for you (not shown in game): What's under the wrapper: { item, weight } (credits for "coins")

- "A small folded scrap of paper. It says 'Kleiner lives.', with a lambda (the Resistance symbol) drawn underneath."  (text, line 179)
- "A ration wrapper with a map drawn on the inside: it shows the canal, with an X marked on it."  (text, line 180)
- "A note written by a child: 'Papa, they took the man from 4C. Come home the back way.'"  (text, line 181)
- "Half of a torn Combine notice. All that's left: '...relocation of all residents of Block...'"  (text, line 182)

> Note for you (not shown in game): part of: start

- "Street sweep"  (title, line 216)

> Note for you (not shown in game): part of: lc on pickup

- "found in the rubbish"  (text, line 247)
- "[Sanitation] You found %d credits in Union tokens stuck in that rubbish. They're yours to keep."  (message, line 248)
- "Found in the rubbish"  (on-screen notice, line 250)
- "[Sanitation] You found {what} hidden in that rubbish. It's in your pockets now."  (chat message, line 253)

> Note for you (not shown in game): part of: start

- "[Sanitation] Your cart is waiting at the depot. Look at it and press E to grab it and push it; press E again to let go. Pick up each piece of rubbish with E and throw it into the cart with left click (long throws pay extra). When the cart is full, push it back to the depot to finish. You have 7 minutes, and finishing in under 3 earns a bonus."  (chat message, line 263)

> Note for you (not shown in game): part of: hud

- "Rubbish in the cart: %d of %d"  (message, line 266)
- "Long throws (extra pay): %d"  (message, line 267)
- "Cart full: push it back to the depot to finish"  (text, line 268)
- "Pushing the cart (press E to let go)"  (text, line 268)
- "Press E on the cart to push it"  (text, line 268)

> Note for you (not shown in game): part of: tick

- "Done in under 3 minutes: 5 credits bonus."  (text, line 301)
- "%d long throws into the cart (1 extra credit each)."  (message, line 303)
- "Time's up: you're paid for the rubbish already in the cart."  (text, line 308)

> Note for you (not shown in game): pressing a key

- "[Sanitation] You let go of the cart. Press E on it to push it again."  (chat message, line 323)

> Note for you (not shown in game): The same line, other work: the ration plant's sealing line (opts.variant = "rations").

- "Factory line"  (title, line 349)
- "The conveyor belt is starting. Rust-red, sparking parts are faulty: pick them up with E and throw them (left click) into the scrap bin beside the belt. Leave the good parts on the belt so they reach the end. You're paid for each one you get right and lose pay for each mistake. (Stealing: press R while holding a good part to hide it in your coat; the dealer and the quartermaster buy them. If a Civil Protection unit sees you, you become wanted, and if you take more than one, the foreman may find the count short and dock your pay.)"  (text, line 350)
- "Something rattles inside this part. Press R while holding it to open it and pocket what's hidden inside."  (text, line 351)
- "Ration sealing line"  (title, line 352)
- "The ration sealing belt is starting. Split, leaking packs (the sickly green ones) are faulty: pick them up with E and throw them (left click) into the reject bin beside the belt. Leave the sealed packs on the belt so they reach the end and go on to the dispensers. You're paid for each one you get right and lose pay for each mistake. (Stealing: press R while holding a sealed pack to hide it in your coat. If a Civil Protection unit sees you, you become wanted, and if you take more than one, the foreman may find the count short and dock your pay.)"  (text, line 353)
- "This pack is heavier than a ration should be. Press R while holding it to open it and pocket what's hidden inside."  (text, line 354)

> Note for you (not shown in game): part of: hud

- "Faulty %s binned: %d    Good %s passed: %d"  (message, line 423)
- "Faulty %s missed: %d    Good %s binned by mistake: %d"  (message, line 424)

> Note for you (not shown in game): part of: tick

- "[Foreman] That one was good! Binning good ones comes out of your pay."  (chat message, line 474)
- "[Foreman] A faulty one reached the end of the belt! That comes out of your pay."  (chat message, line 477)

> Note for you (not shown in game): the foreman counts what went through: skim more than one and he may find it short

- "The foreman found %d missing from his count. It comes out of your pay, and you lose Civil Standing."  (message, line 514)
- "Goods went missing on your shift"  (text, line 515)

> Note for you (not shown in game): part of: tick

- "No mistakes all shift: 6 credits bonus."  (text, line 519)
- "Faulty parts binned: %d of %d. Good parts passed: %d."  (message, line 521)

> Note for you (not shown in game): Skimming (sv_livingcity_funding.lua): R while holding a good part pockets it. A unit who sees it makes you wanted; and the more you take, the likelier the foreman finds the count short.

- "That one is faulty: nobody would buy it, so it's not worth stealing."  (chat message, line 540)

> Note for you (not shown in game): part of: line skim

- "You hid {name} in your coat. The foreman's count will be one short."  (chat message, line 546)
- "Theft from the factory floor"  (text, line 548)
- "[Civil Protection] A Civil Protection unit saw you steal that. You're now wanted."  (chat message, line 549)

> Note for you (not shown in game): pressing a key

- "You open it and pocket what was hidden inside: {what}."  (chat message, line 565)
- "Theft from the factory floor"  (text, line 567)
- "[Civil Protection] A Civil Protection unit saw you steal that. You're now wanted."  (chat message, line 568)

> Note for you (not shown in game): part of: rule lines

- "Papers must not be expired."  (text, line 609)
- "The photo must match the person in front of you."  (text, line 609)

> Note for you (not shown in game): One traveler's papers, and what's wrong with them (if anything).

- "Anya Vasek"  (text, line 620)
- "Pavel Orlov"  (text, line 620)
- "Mira Kessler"  (text, line 620)
- "Tomas Hrabal"  (text, line 620)
- "Ilse Brandt"  (text, line 620)
- "Jonas Petrov"  (text, line 620)

> Note for you (not shown in game): part of: start

- "Papers check"  (title, line 687)
- "[Station] Travelers will walk up to you one at a time. Press E on each one to see their papers and check them against today's rules (listed on your screen). Then choose: approve them, deny them, or call a Civil Protection unit if the papers are forged (look closely at the seal). Right calls pay; wrong ones get you a citation and docked pay."  (chat message, line 694)

> Note for you (not shown in game): part of: hud

- "Travelers checked: %d of %d"  (message, line 696)
- "Right calls: %d    Citations (mistakes): %d"  (message, line 696)
- "Today's rules:"  (text, line 696)
- "Press E on the traveler to see their papers"  (text, line 698)

> Note for you (not shown in game): part of: finish

- "No citations all shift: 5 credits bonus."  (text, line 722)
- "%d of %d decisions right."  (message, line 724)

> Note for you (not shown in game): The call: "approve", "deny" or "unit". True when it was right.

- "Forged papers: the seal reads {seal}. A Civil Protection unit takes the traveler away."  (text, line 780)

> Note for you (not shown in game): part of: papers decide

- "Denied. The seal was forged, so calling a Civil Protection unit would have paid more."  (text, line 782)
- "You approved forged papers (the seal read {seal})."  (text, line 786)
- "They walk through on forged papers. Under their breath: 'Thank you.' Nobody noticed this time."  (text, line 788)
- "You approved papers that had expired."  (text, line 793)
- "You approved a traveler whose photo didn't match them."  (text, line 793)
- "You approved entry from a banned district, {banned}."  (text, line 794)
- "You approved a traveler with no transit permit stamp."  (text, line 794)
- "You approved travel for work without a Union stamp."  (text, line 795)
- "You turned away a traveler whose papers were all in order."  (text, line 799)
- "Your pay is docked for this."  (on-screen notice, line 806)
- "[Station] {note}"  (chat message, line 808)

> Note for you (not shown in game): part of: start

- "the panel"  (text, line 971)
- "the terminal"  (text, line 972)

> Note for you (not shown in game): part of: hud

- "Turns used: %d (fewest possible: %d)"  (message, line 981)
- "Blackout: this job pays double."  (text, line 982)

> Note for you (not shown in game): the breaker trips: a new board (and paid less)

- "[Maintenance] Too slow: the breaker tripped and the wires are scrambled. Start again (this job now pays less)."  (chat message, line 993)

> Note for you (not shown in game): part of: wire try

- "Finished in close to the fewest turns: 2 credits bonus."  (text, line 1044)
- "Blackout: pay doubled."  (text, line 1045)
- "Not shocked once."  (text, line 1047)

> Note for you (not shown in game): Triage (Clinic Medic): patients bleeding out at different rates. Treat them with the medkit (primary fire) before they're gone: the worst first. How fast each gets worse (health a second, roughly): an emergency department's mix, not everyone bleeding out alike (the owner: a broken arm isn't dying like someone bleeding out). 0: stable, in pain, can wait.

- "Gunshot wound, bleeding heavily"  (label, line 1069)
- "Stab wound"  (label, line 1069)
- "Electrocuted, heart racing"  (label, line 1070)
- "Head injury (blunt force)"  (label, line 1070)
- "Crushed under rubble"  (label, line 1071)
- "Stunstick beating"  (label, line 1071)
- "Severe burns"  (label, line 1072)
- "Smoke inhalation"  (label, line 1072)
- "Broken arm"  (label, line 1073)
- "Dislocated shoulder"  (label, line 1073)

> Note for you (not shown in game): part of: urgency

- "(stable: can wait)"  (text, line 1076)

> Note for you (not shown in game): part of: start

- "[Clinic] Patients are coming in, and their health keeps dropping. Aim your medkit at a patient and left click to heal them, until each one is almost fully healed. Treat the worst injuries first (critical ones go downhill fast; a broken arm can wait): a patient whose health reaches zero dies."  (chat message, line 1119)

> Note for you (not shown in game): part of: hud

- "Saved: %d    Lost: %d    Waiting: %d"  (message, line 1121)

> Note for you (not shown in game): part of: tick

- "[Clinic] A patient has died: {label}."  (chat message, line 1134)
- "[Clinic] A patient has died: {label}."  (chat message, line 1149)
- "[Clinic] {or} grabs your wrist on the way out. 'Thank you. Please... don't write down what did this.'"  (chat message, line 1159)
- "Every patient survived: 6 credits bonus."  (text, line 1171)
- "%d patients saved, %d lost."  (message, line 1172)

> Note for you (not shown in game): part of: start

- "[Reclamation] Smash every block in the pile with your crowbar (left click). Each broken block drops a piece of scrap you can pick up, and sometimes something else. You're paid 1 credit per block."  (chat message, line 1225)

> Note for you (not shown in game): part of: hud

- "Blocks broken: %d of %d"  (message, line 1226)
- "Hit the blocks with the crowbar (left click)"  (text, line 1226)

## the unit's kick (sv_livingcity_kick.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_kick.lua`


> Note for you (not shown in game): part of: knock out

- "Out cold"  (on-screen notice, line 107)
- "Knocked senseless"  (on-screen notice, line 107)
- "A door, out of nowhere. Everything goes black."  (on-screen notice, line 108)
- "The door catches you on its way down. The room won't keep still."  (on-screen notice, line 108)

> Note for you (not shown in game): a brush door (a sliding warehouse door, a Combine shutter, a gate) is too big and too heavy: a boot does nothing to it

- "It doesn't budge."  (chat message, line 209)

> Note for you (not shown in game): part of: kick door

- "It doesn't give."  (chat message, line 216)
- "[Living City] The Overwatch kicked the door of {or}'s apartment off its hinges."  (chat message, line 230)
- "[Living City] Civil Protection kicked in the door of {or}'s apartment."  (chat message, line 266)

> Note for you (not shown in game): the chat command /kick

- "Only Civil Protection kick doors in."  (chat message, line 352)

> Note for you (not shown in game): part of: drop door

- "You set the door down."  (chat message, line 374)

> Note for you (not shown in game): Hung: back on its hinges, and the technician is paid.

- "door rehung"  (text, line 392)

> Note for you (not shown in game): part of: door rehung

- "Door rehung"  (on-screen notice, line 393)
- "Back on its hinges.{or}"  (on-screen notice, line 393)

> Note for you (not shown in game): E on a fallen door.

- "Off its hinges. A Maintenance Technician could hang it back up."  (text, line 403)

> Note for you (not shown in game): part of: use fallen door

- "Rehanging the door..."  (progress bar, line 408)
- "You leave it leaning against the frame."  (text, line 409)
- "Someone already has hold of it."  (text, line 413)
- "The door frame"  (text, line 421)
- "A door to rehang"  (on-screen notice, line 422)
- "Carry it back to the frame it came off (marked), and press E on it there."  (on-screen notice, line 422)

> Note for you (not shown in game): The city's own crews rehang a door nobody else has (after the players have had their chance).

- "rehanging a door"  (label, line 460)

> Note for you (not shown in game): part of: find

- "lifting a door"  (what someone is doing, line 477)
- "rehanging a door"  (what someone is doing, line 481)

## the Resistance lab (sv_livingcity_lab.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_lab.lua`


> Note for you (not shown in game): part of: say

- "[Scientist] {text}"  (chat message, line 46)

> Note for you (not shown in game): Who runs each lab: Dr. Kleiner, Eli Vance or Dr. Magnusson, a different one at each (the first that isn't at another lab already; any of them again past three labs).

- "Dr. Kleiner"  (name, line 64)
- "Eli Vance"  (name, line 65)
- "Dr. Magnusson"  (name, line 66)

> Note for you (not shown in game): the Combine's data, decoded here (sv_livingcity_heist.lua)

- "150 XP, 150 credits, and every Civil Protection unit marked for the whole Resistance for ten minutes"  (description, line 203)
- "50 XP, 50 credits, and every Civil Protection unit marked for the whole Resistance for five minutes"  (description, line 204)
- "He looks up from a tangle of wires. "Ah! Yes, hello. What do you need?""  (text, line 217)
- ""Mind the, ah, the jar. What can I make for you?""  (text, line 218)
- "He pushes his glasses up his nose. "Materials, or credits? Either will do.""  (text, line 219)

> Note for you (not shown in game): part of: use scientist

- "He steps between you and the bench. "I'm terribly sorry, I don't believe we've met. This is a private... laboratory. Please, go.""  (chat message, line 230)
- ""Half a chip? Bring me the other fragment and I'll decode the lot.""  (chat message, line 239)
- ""Is that Combine data? I can decode that. (Decode: at the top of my list.)""  (chat message, line 240)

> Note for you (not shown in game): Have him make one. how: "mats" (from your pockets) or "pay". True, or false and why not.

- "He only works for the Resistance."  (text, line 249)
- "Find the scientist in the lab."  (text, line 251)
- "You're busy."  (text, line 252)

> Note for you (not shown in game): part of: lab make

- "He's still working on the last thing."  (text, line 255)
- "He's in the middle of someone else's work (%ds)."  (message, line 256)
- "He wants {price} credits for that. You don't have them."  (text, line 261)
- "the lab"  (text, line 262)
- "You're missing the materials ({mid})."  (text, line 265)

> Note for you (not shown in game): part of: refund

- "the lab, handed back"  (text, line 284)

> Note for you (not shown in game): part of: lab make

- ""Credits. Yes. Fine. Give me a moment.""  (chat message, line 290)
- ""Ah, good, good. Let me see what I can do with these.""  (chat message, line 290)
- "The scientist is making your {name}... stay in the lab"  (progress bar, line 291)

> Note for you (not shown in game): part of: done

- ""There. Do be careful with it." He hands you: {name}."  (chat message, line 300)

> Note for you (not shown in game): part of: lab make

- "[Scientist] You wander off. He sighs, and hands it all back."  (text, line 304)

> Note for you (not shown in game): A new face. Papers in a dead man's name don't stop a unit who knows your face; the scientist can change it. Twenty seconds under (stay on the table), lc_surgery_price credits, and you wake with someone else's face, bandaged and slow on your feet for a few minutes. Nobody's looking for that face: your wanted status, any BOLO on you and the scanners' pictures are gone, a wanted notice won't match it, and a Civil Standing below lc_surgery_standing (-50) comes back up to it (the records can't put a name to the face). Get wanted again and they learn the new one.

- "He only works for the Resistance."  (text, line 326)
- ""Surgery? Here? Good heavens, no.""  (text, line 328)
- ""Your face needs to heal first." (%d min)"  (message, line 330)
- "%d credits, and you don't have them."  (message, line 331)

> Note for you (not shown in game): part of: lab surgery

- "Find the scientist in the lab."  (text, line 349)
- "He's in the middle of someone else's work."  (text, line 351)
- "a new face"  (text, line 353)
- ""Lie down, lie down. You'll feel a little... well. You won't feel anything, actually. Count backwards from ten.""  (chat message, line 357)
- "Under the knife... stay on the table"  (progress bar, line 360)

> Note for you (not shown in game): part of: done

- "a face the records don't know"  (text, line 376)
- ""There. Nobody will know you. Well, I hardly do. Keep the bandages on a few minutes, and don't run.""  (chat message, line 381)
- "A new face"  (on-screen notice, line 382)
- "Nobody's looking for this face. Your wanted status, any BOLO and the scanners' pictures are gone, and a wanted notice won't match it. Get wanted again and they'll learn this one."  (on-screen notice, line 382)

> Note for you (not shown in game): part of: cancel

- "the lab, handed back"  (text, line 389)

> Note for you (not shown in game): part of: lab surgery

- "[Scientist] You sit up too soon. "No, no, no! We'll have to do this another time." He hands your credits back."  (text, line 392)
- "the lab, handed back"  (text, line 397)

> Note for you (not shown in game): the game answering something done in a window (lc_lab_surgery)

- "[Lab] {why}"  (chat message, line 407)

> Note for you (not shown in game): the game answering something done in a window (lc_lab_decode)

- "He slots it into a humming console and leans in. "Oh, this is marvellous. Get the word out.""  (chat message, line 415)

> Note for you (not shown in game): the game answering something done in a window (lc_lab_make)

- "[Lab] {why}"  (chat message, line 425)

> Note for you (not shown in game): part of: shut lab

- "[Civil Protection] A Resistance lab. The scientist is taken into custody and the equipment smashed. Nothing will be made here for a while."  (chat message, line 443)
- "a Resistance lab shut down"  (text, line 444)
- "Shut down a Resistance lab"  (text, line 445)
- "They found the lab {GetPos}. The scientist's been taken. Nothing comes out of there for a while."  (text, line 449)

> Note for you (not shown in game): a timer (regularly)

- "The scientist's back at the lab {GetPos}."  (text, line 455)

## a life (sv_livingcity_life.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_life.lua`

- "a Civil Protection unit"  (text, line 163)
- "an Overwatch soldier"  (text, line 163)
- "a Resistance fighter"  (text, line 164)
- "one of the infested"  (text, line 165)
- "a city scanner"  (text, line 165)
- "a poison headcrab"  (text, line 172)
- "a poison headcrab"  (text, line 172)
- "an antlion"  (text, line 177)
- "an antlion guard"  (text, line 177)
- "an energy ball"  (text, line 178)

> Note for you (not shown in game): part of: death cause

- "Killed by {who}."  (text, line 213)
- "Shot by {who}."  (text, line 214)
- "Beaten to death by {who}."  (text, line 215)
- "Blown up by {who}."  (text, line 216)
- "Burned to death by {who}."  (text, line 217)
- "Disintegrated by {who}."  (text, line 218)
- "Gassed by {who}."  (text, line 219)
- "Killed by {who}."  (text, line 220)
- "Burned to death."  (text, line 224)
- "An explosion."  (text, line 225)
- "Hit by a vehicle."  (text, line 226)
- "Radiation sickness."  (text, line 231)
- "Died of thirst."  (text, line 233)
- "Sickness: parasites."  (text, line 234)
- "Nobody saw how."  (text, line 235)

> Note for you (not shown in game): part of: me

- "\|{GetNW2String}"  (text, line 276)

> Note for you (not shown in game): Word gets around

- "%s is dead."  (text, line 341)
- "You hear that %s died."  (text, line 341)
- "Someone tells you %s is dead."  (text, line 341)
- "They say it was the Combine."  (text, line 343)
- "They say it was the Resistance."  (text, line 343)
- "The infestation, they say."  (text, line 344)
- "Somebody killed them, people say."  (text, line 344)
- "A fall, they say."  (text, line 345)
- "Drowned, they say."  (text, line 345)
- "Starved, they say."  (text, line 345)
- "Thirst, they say."  (text, line 346)
- "Sick, they say."  (text, line 346)
- "An accident, they say."  (text, line 346)
- "Something out past the walls, they say."  (text, line 347)

> Note for you (not shown in game): part of: tell

- "[Word gets around] {text}"  (chat message, line 355)

> Note for you (not shown in game): !bob

- "[Living City] The camera sway is off for everyone on this server."  (chat message, line 478)

## Resistance lookouts (sv_livingcity_lookouts.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_lookouts.lua`


> Note for you (not shown in game): part of: can recruit lookout

- "Only the Resistance asks this of people."  (text, line 36)
- "They don't know you well enough. (Member and up)"  (text, line 37)
- "They wouldn't."  (text, line 39)
- "They're already keeping watch."  (text, line 40)
- "They're afraid of you."  (text, line 41)
- "You already have two people keeping watch."  (text, line 42)

> Note for you (not shown in game): part of: recruit lookout

- "They nod, and lean against the wall like they've nowhere to be. They'll watch %s for %d minutes. (Freq 7 hears what they see.)"  (message, line 61)

> Note for you (not shown in game): Freq 7 hears it; whoever posted them always does (a whistle, a runner), radio or not.

- "[Your lookout] {text}"  (chat message, line 69)

> Note for you (not shown in game): part of: lookout tick

- "The lookout {pos} has gone quiet."  (text, line 104)
- "The lookout {pos} has been stopped by a Civil Protection unit."  (text, line 107)

> Note for you (not shown in game): (spoken to, or briefly busy: back to the watch, not a reason to stand down)

- "[Resistance] Your lookout {pos} has gone home."  (chat message, line 113)

> Note for you (not shown in game): part of: lookout tick

- "a Civil Protection unit"  (text, line 119)
- "a Civil Protection unit"  (text, line 119)
- "Lookout {pos}: {what} coming."  (chat message, line 120)

## what loyalty earns (the owner, 2026-11-01: "other rewards for high standing civilians? All of them") (sv_livingcity_loyalty.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_loyalty.lua`


> Note for you (not shown in game): Once a curfew, an Exemplary citizen is waved through (sv_livingcity_underground.lua asks, at a curfew stop).

- "[Civil Protection] The unit looks at your papers, and then at you. "A model citizen. Get home, citizen." You're cleared until this is over."  (chat message, line 68)

> Note for you (not shown in game): the game's living city crime moment

- ""{reason}." The unit lets it go this once: a model citizen gets a warning. Next time, it counts."  (on-screen notice, line 84)

> Note for you (not shown in game): part of: praise

- "The Administrator"  (text, line 104)
- "Citizen %s is commended for exemplary conduct. Let %s be an example to us all."  (message, line 107)
- "Commended by the Administrator"  (text, line 110)

## letters (sv_livingcity_mail.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_mail.lua`


> Note for you (not shown in game): part of: send letter

- "You don't have that note."  (text, line 115)
- "The post office doesn't know anyone by that name."  (text, line 117)
- "You could just keep it."  (text, line 118)
- "Take it to the post office."  (text, line 119)
- "You hand it over the counter, addressed to {name}. It'll go out with the next round."  (text, line 133)

> Note for you (not shown in game): part of: deliver letter

- "[Mail] A letter has come for you{or}. It's in your pockets (F2)."  (chat message, line 145)
- "letter delivered"  (text, line 150)

> Note for you (not shown in game): Civil Protection reads the mail

- "Civil Protection units only."  (text, line 216)
- "The mail's at the post office."  (text, line 217)

> Note for you (not shown in game): part of: confiscate letter

- "mail inspected"  (text, line 233)
- "Confiscated. It won't arrive. (Posted by {or}.)"  (text, line 235)

> Note for you (not shown in game): The city's couriers carry real mail when there is some

- "delivering letters"  (label, line 262)

> Note for you (not shown in game): part of: find

- "collecting the mail"  (what someone is doing, line 273)
- "delivering a letter to {or}"  (what someone is doing, line 277)

## marched to the cells (sv_livingcity_march.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_march.lua`

- "You're struck from behind, and everything goes black. When you come to, you're in a cell."  (text, line 40)

> Note for you (not shown in game): Taken inside: untied (their things are recorded and kept as on any arrest) and locked up.

- "[Civil Protection] {how}"  (chat message, line 139)

> Note for you (not shown in game): Got away: still tied, and wanted for it.

- "Free, for now"  (on-screen notice, line 148)
- "Your hands are still cuffed: F1 > Work at the cuffs, or have someone uncuff them."  (on-screen notice, line 148)
- "[Custody] {how}"  (chat message, line 149)
- "Escaping custody"  (text, line 151)

> Note for you (not shown in game): part of: march to prison

- "[Custody] Cuffed. {or} you to the cells. Charge: {or}."  (chat message, line 193)
- "Under arrest"  (on-screen notice, line 195)
- "You're being walked to the prison. Someone could still get you out on the way."  (on-screen notice, line 195)
- "Civil Protection are marching a prisoner to the cells{or}. Hit them on the way and they're ours."  (text, line 198)
- "Prisoner in transit{or}. Escort to holding."  (text, line 199)
- "Marching %s to the prison (%s)"  (message, line 201)

> Note for you (not shown in game): part of: march take over

- "[Custody] The unit leading you is down. Another takes your arm before you can run."  (chat message, line 247)

> Note for you (not shown in game): part of: tick

- "The Civil Protection unit leading you is down."  (text, line 275)

> Note for you (not shown in game): he's fighting: he lets go of you

- "While they were busy, you slipped away."  (text, line 281)

> Note for you (not shown in game): there, or as close as he can get (stopped at the doors): through them, and down to the cells

- "They put you in the cell, and the door locks behind you."  (text, line 287)
- "They unlock the prison door, walk you through, and lock you in a cell."  (text, line 288)

## more work you actually do (the engine is sv_livingcity_jobgames.lua) (sv_livingcity_moregames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_moregames.lua`


> Note for you (not shown in game): Parcel run (Courier) text: what it looks like; say: what an honest sender calls it; inside: what's really in it

- "A heavy little box, taped twice. It smells of gun oil."  (text, line 70)
- "pistol rounds, loose in a sock"  (text, line 70)
- "Soft and lumpy, wrapped in newspaper. Something inside sloshes."  (text, line 71)
- "a bottle of something that isn't water, and a rag for a fuse"  (text, line 71)
- "A flat tin, very light. It rattles when you turn it."  (text, line 72)
- "buttons, for the laundry"  (spoken line, line 72)
- "buttons, hundreds of them"  (text, line 72)
- "A shoebox tied up with wire. It's warm, somehow."  (text, line 73)
- "a Combine battery cell, humming to itself"  (text, line 73)
- "The label says medicine, but the label is handwritten."  (text, line 74)
- "my mother's medicine"  (spoken line, line 74)
- "painkillers, a few days' worth, in a paper twist"  (text, line 74)
- "It's as heavy as books. Nobody has said the word 'books' out loud in years."  (text, line 75)
- "books, the kind the Union burns"  (text, line 75)
- "A small parcel, neatly wrapped. It weighs almost nothing."  (text, line 76)
- "a letter and some socks for my son"  (spoken line, line 76)
- "a letter, and a pair of darned socks"  (text, line 76)

> Note for you (not shown in game): The sender: an honest one says what's in it; a silent one won't; a bold one owns up to contraband and offers more. The courier takes it, hands it back, reports the sender to a Civil Protection unit (only when they wouldn't say, or owned up), or opens it (Civil Standing, and 1 credit a delivery instead of 3: you opened somebody's mail).

- "You opened it. Inside: {inside}."  (text, line 87)
- "The sender says it's {or}."  (text, line 88)
- "You ask what's in it. The sender won't say: 'Don't ask. Just get it there.'"  (text, line 89)
- "The sender admits it's contraband: 'It's not something a unit should see. {SMUGGLE_BONUS} credits extra when it gets there.'"  (text, line 90)

> Note for you (not shown in game): part of: parcel set off

- "Deliver three parcels (follow the waypoint) before the timer runs out. If a Civil Protection unit watches you too long, they stop you for a search, so crouch near them to draw less attention. When stopped, stand still for 5 seconds, or run (you become wanted)."  (chat message, line 106)

> Note for you (not shown in game): part of: parcel way

- "Next delivery"  (text, line 112)

> Note for you (not shown in game): part of: start

- "Parcel run"  (title, line 117)
- "The Resistance cell's cargo, wrapped to look harmless."  (text, line 122)
- "guns and ammunition for the cell"  (text, line 122)
- "Smuggling run"  (title, line 128)
- "Deliver the Resistance cell's cargo to three drop points (follow the waypoint) before the timer runs out. If a Civil Protection unit watches you too long, they stop you for a search, so crouch near them to draw less attention. When stopped, stand still for 5 seconds and hope they miss it, or run (you become wanted)."  (chat message, line 130)
- "Deliver three parcels (follow the waypoint) before the timer runs out. If a Civil Protection unit watches you too long, they stop you for a search, so crouch near them to draw less attention. When stopped, stand still for 5 seconds, or run (you become wanted)."  (chat message, line 134)

> Note for you (not shown in game): the sender: honest about a harmless one most of the time; a hot one is never "honest"

- "The sender is waiting for your answer."  (text, line 143)
- "Choose in the window: take the parcel, hand it back, report the sender, or open it (closed it? press E to bring it back)"  (text, line 143)

> Note for you (not shown in game): part of: hud

- "Delivery %d of %d: %s"  (message, line 146)
- "Civil Protection attention (full means a search): {heat}"  (text, line 148)
- "SEARCH: stand still for %d more seconds, or run"  (message, line 149)
- "A Civil Protection unit is watching you. Crouch or get out of sight before the bar fills and they search you."  (text, line 150)

> Note for you (not shown in game): part of: tick

- "Evading a search"  (text, line 162)
- "You ran from a search"  (on-screen notice, line 163)
- "You're now wanted for evading a search: every Civil Protection unit in the sector has your description. You can still deliver the parcels."  (on-screen notice, line 163)
- "Carrying contraband"  (text, line 170)
- "A Civil Protection unit opened the parcel and found contraband. It's seized, you're wanted, and you get no pay."  (text, line 171)
- "The Civil Protection unit turns it over, shakes it, and hands it back. 'Move along.' You passed the search: carry on."  (chat message, line 175)
- "A Civil Protection unit is stopping you to search the parcel. Stand still for 5 seconds, or run (you become wanted)."  (on-screen notice, line 188)
- "Parcel delivered: {or}. Nobody signs for these."  (chat message, line 195)
- "Finished with %d seconds to spare (1 extra credit for every 10 seconds)."  (message, line 201)
- "Never stopped for a search: 2 credits bonus."  (text, line 205)
- "The cargo got through: 10 credits bonus. The cell won't forget it."  (text, line 208)
- "a smuggling run"  (text, line 209)
- "The sender's %d extra credits, as promised. You knew you were carrying contraband."  (message, line 212)
- "Whatever was in the parcels, it got there."  (text, line 214)
- "Time's up, so there's no time bonus. Deliver the rest anyway."  (chat message, line 222)

> Note for you (not shown in game): part of: act

- "You hand the parcel back: 'Find someone else.' The job ends, with no pay."  (chat message, line 234)
- "reported a sender of contraband"  (text, line 244)
- "You hand the parcel to a Civil Protection unit and point out the sender. It was contraband, so the unit takes it from there, and you gain Civil Standing."  (text, line 245)
- "reported a sender"  (text, line 247)
- "You hand it to a Civil Protection unit. It was harmless: {inside}. The unit isn't pleased you wasted their time."  (text, line 248)
- "opened somebody's parcel"  (text, line 257)
- "You open it. Opening the mail costs you Civil Standing, and each delivery now pays 1 credit instead of 3."  (chat message, line 258)

> Note for you (not shown in game): part of: start

- "Records terminal"  (title, line 294)
- "the records terminal"  (text, line 295)
- "A needle swings back and forth: click (or press Space) while it's inside the marked band. Do it 4 times to get in; each miss sets you back one. When the scanner flies over, don't click: if it sees you twice, the alarm goes off and you become wanted."  (chat message, line 311)

> Note for you (not shown in game): part of: hud

- "Hits: %d of %d needed"  (message, line 313)
- "Seen by the scanner: %d of 2 (2 sets off the alarm)"  (message, line 313)
- "SCANNER OVERHEAD: don't click"  (text, line 314)
- "Scanner coming: get ready to stop clicking"  (text, line 314)

> Note for you (not shown in game): part of: act

- "Tampering with a Combine terminal"  (text, line 355)
- "The scanner saw you twice and set off the alarm. You're wanted: get out."  (text, line 356)
- "The scanner saw you working the panel. If it sees you once more, it sets off the alarm."  (chat message, line 361)
- "The scanner never saw you: 6 credits bonus."  (text, line 373)

> Note for you (not shown in game): Dead drop (Resistance): hide it where nobody sees you do it

- "the bin"  (text, line 398)
- "the oil drum"  (text, line 398)
- "the box"  (text, line 399)
- "the crate"  (text, line 399)

> Note for you (not shown in game): part of: start

- "Dead drop"  (title, line 405)
- "Three hiding places are outlined. Press E on one, then crouch close to it and stay there until it's hidden. If someone watches you while you hide it, the Seen bar fills; when it's full, that place is burned and you must try another."  (chat message, line 420)

> Note for you (not shown in game): part of: hud

- "Seen bar (full means this place is burned): {seen}"  (text, line 422)
- "Hiding places burned: %d of %d"  (message, line 422)
- "Crouch close to it to keep hiding it"  (text, line 423)
- "Hiding it (stay crouched): {HIDE_SECS}%"  (text, line 423)
- "Press E on an outlined hiding place"  (text, line 424)

> Note for you (not shown in game): part of: tick

- "Someone saw you at {lcDropName}, so it's burned. Try another hiding place."  (on-screen notice, line 452)
- "Someone saw you at every hiding place. You take the message home, with no pay."  (text, line 454)
- "Hidden in {lcDropName}."  (text, line 462)
- "Nobody noticed you: 2 credits bonus."  (text, line 463)

> Note for you (not shown in game): Searching the dead (Mortuary), before the incinerator

- "Trouser pockets"  (text, line 478)
- "Identity papers, still valid"  (label, line 480)
- "Ration coupons, two days' worth"  (label, line 481)
- "A wedding ring"  (label, line 482)
- "Loose pistol rounds"  (label, line 483)
- "A folded note: a name and an address"  (label, line 484)
- "A data chip, sewn into the hem"  (label, line 485)
- "A photograph of two children"  (label, line 486)

> Note for you (not shown in game): part of: start

- "Searching the dead"  (title, line 542)
- "Three bodies to search before they go in the incinerator. Press E on the body and search each pocket. For anything you find, choose: Log it (paid), Keep it, or Family (set it aside for them). Then press 'Done: into the fire'. The overseer looks in now and then: if he's watching when you keep something, you're caught."  (chat message, line 548)

> Note for you (not shown in game): part of: hud

- "Body %d of %d"  (message, line 550)
- "Logged: %d    Kept: %d"  (message, line 550)
- "The overseer is out of the room (nobody is watching)"  (text, line 551)
- "Press E on the body to search it"  (text, line 551)

> Note for you (not shown in game): part of: tick

- "The door opens. The overseer leans on the frame, watching you work. Don't keep anything while he's here."  (chat message, line 560)
- "The overseer goes back out. Nobody is watching now."  (chat message, line 562)

> Note for you (not shown in game): part of: act

- "logged contraband from the dead"  (text, line 580)
- "caught stealing from the dead"  (text, line 586)
- "The overseer saw you: 'In the tray.' It's logged instead, and you lose pay and Civil Standing."  (chat message, line 587)
- "%d items logged, %d kept."  (message, line 602)
- "The overseer wrote your name down for stealing (no clean-work bonus)."  (text, line 603)
- "Into the incinerator. The next body is on the slab: press E on it."  (chat message, line 607)

> Note for you (not shown in game): Sorting (Uniform Laundry)

- "a folded note"  (text, line 624)
- "a pistol magazine"  (text, line 624)
- "ration coupons"  (text, line 624)
- "a door keycard"  (text, line 625)
- "a ration bar, half eaten"  (text, line 625)

> Note for you (not shown in game): part of: start

- "Incident wash (bloodstained)"  (label, line 653)

> Note for you (not shown in game): part of: hud

- "Uniforms: %d of %d"  (message, line 658)
- "Right: %d    Wrong: %d"  (message, line 658)

> Note for you (not shown in game): part of: tick

- "Time's up, with uniforms still on the pile."  (text, line 665)

> Note for you (not shown in game): part of: act

- "a Civil Protection unit's pocket came back short"  (text, line 677)
- "The supervisor counts what comes out of the pockets. Tonight he counts one short and suspects you: you lose Civil Standing."  (chat message, line 678)
- "turned in what a Civil Protection unit left in a pocket"  (text, line 683)
- "You didn't empty the pocket first, so whatever was in it went into the bin too."  (chat message, line 693)
- "No uniforms in the wrong bin: 3 credits bonus."  (text, line 696)
- "%d of %d sorted right."  (message, line 697)

> Note for you (not shown in game): Filing (Records Clerk)

- "Anya Vasek"  (text, line 715)
- "Pavel Orlov"  (text, line 715)
- "Mira Kessler"  (text, line 715)
- "Tomas Hrabal"  (text, line 715)
- "Ilse Brandt"  (text, line 715)
- "Jonas Petrov"  (text, line 715)
- "Lena Duric"  (text, line 715)
- "Viktor Sorel"  (text, line 716)
- "Hana Novak"  (text, line 716)
- "Emil Strand"  (text, line 716)
- "Katya Lind"  (text, line 716)
- "Oskar Benes"  (text, line 716)
- "Rosa Kalnin"  (text, line 716)
- "Dmitri Arkov"  (text, line 716)

> Note for you (not shown in game): (the owner, 1 November: the status meant nothing and nothing said so. Now the register has one too, and a form that differs from the register in anything, name, number or status, is a discrepancy)

- "the name is spelled differently"  (text, line 742)

> Note for you (not shown in game): part of: next form

- "the citizen number is different"  (text, line 746)
- "the status is different"  (text, line 750)

> Note for you (not shown in game): part of: hud

- "Forms: %d of %d"  (message, line 773)
- "Right: %d    Wrong: %d"  (message, line 773)

> Note for you (not shown in game): part of: tick

- "Time's up, with forms still in the in-tray."  (text, line 780)

> Note for you (not shown in game): part of: act

- "caught taking a blank identity form"  (text, line 790)
- "Theft of state forms"  (text, line 791)
- "A Civil Protection unit at the counter saw you take it. You put it back, but you're wanted and lose Civil Standing."  (chat message, line 792)
- "You slip a blank identity form into your sleeve. It's in your pockets now."  (chat message, line 796)

> Note for you (not shown in game): why, every time (it was right or wrong with no reason given)

- "Right: {why}, so it's a discrepancy."  (text, line 811)
- "Right: it matches, and {cid} goes in {drawer}."  (text, line 811)
- "Wrong: {why} from the register, so it goes in Discrepancy."  (text, line 813)
- "Wrong: it matched the register exactly, so it's filed by number: {cid} goes in {drawer}."  (text, line 815)

> Note for you (not shown in game): part of: act

- "Wrong drawer: the number starts {cid}, so it goes in {drawer}."  (text, line 817)
- "No forms filed wrong: 3 credits bonus."  (text, line 822)
- "%d of %d filed right."  (message, line 823)

> Note for you (not shown in game): Radio repair: a set's trimmer screws, set by ear. Tune it to its station (the dial), then turn the screws with the screwdriver until it comes through clean: the volume trimmer brings the station up, the squelch pushes the static down, the alignment pulls a smeared signal into focus. Sometimes the clearest thing on the band is Freq 7.

- "Volume trimmer"  (text, line 841)

> Note for you (not shown in game): How right a screw is: 1 on the spot, 0 a third of the range off.

- "'...this is Freq 7. They count the rations and they count you. Count them back...'"  (text, line 850)
- "'...the third shift at the station is short two Civil Protection units on Tuesdays. Freq 7, out...'"  (text, line 851)
- "'...if you can hear this, you are not alone. Freq 7...'"  (text, line 852)
- "'...the Administrator's broadcasts are recorded. She is not in the city. Freq 7...'"  (text, line 853)

> Note for you (not shown in game): part of: new radio

- "A voice comes through the static, on Freq 7."  (text, line 893)

> Note for you (not shown in game): part of: radio done

- "You fixed every radio: 3 credits bonus."  (text, line 916)
- "%d of %d radios fixed."  (message, line 917)

> Note for you (not shown in game): part of: start

- "Radio repair"  (title, line 926)

> Note for you (not shown in game): part of: hud

- "Radio %d of %d"  (message, line 931)
- "Turn the dial to its station, then adjust the screws until it sounds clear"  (text, line 932)
- "%d seconds left for this radio"  (message, line 933)

> Note for you (not shown in game): part of: tick

- "Out of time: this radio goes back on the shelf unfixed."  (chat message, line 940)

> Note for you (not shown in game): part of: act

- "Right station, but too faint. Adjust the volume trimmer."  (text, line 978)
- "Right station, but buried in static. Adjust the squelch."  (text, line 979)
- "Right station, but blurred and smeared. Adjust the alignment."  (text, line 979)
- "reported an illegal broadcast"  (text, line 1002)
- "You report the frequency to Civil Protection: extra pay and Civil Standing. They'll be listening for it now."  (chat message, line 1004)
- "You secretly write down Freq 7 and the seven frequencies it broadcasts on. The Freq 7 sheet is in your pockets: it's contraband, so pass it on or burn it."  (chat message, line 1010)
- "You tune past it and leave Freq 7 alone. Nothing on this band is worth the risk."  (chat message, line 1013)

> Note for you (not shown in game): A Freq 7 sheet, read: the rule, and the seven frequencies it gives.

- "FREQ 7 /  / Freq 7 only broadcasts on frequencies whose digits add up to seven. These are the seven places on the dial: /  / {list} /  / {or}When the Combine find the broadcast, it moves to another of these: try the next one. /  / Keep the volume low, and never listen where a Civil Protection unit can hear it."  (text, line 1028)

> Note for you (not shown in game): part of: read item

- "(in a cramped hand)"  (text, line 1035)

> Note for you (not shown in game): part of: listen off

- "[Radio] {why}"  (chat message, line 1081)

> Note for you (not shown in game): Listen (already on: the window again, where you left the dial; it has its own off switch).

- "You can't listen to a radio while you're in custody."  (text, line 1089)

> Note for you (not shown in game): a timer (regularly)

- "Your radio is no longer in your pockets, so it switched off."  (text, line 1123)

> Note for you (not shown in game): the pirate band, out loud, where a unit can hear it

- "Listening to an illegal broadcast"  (text, line 1140)
- "A Civil Protection unit heard that"  (on-screen notice, line 1141)
- "A Civil Protection unit heard Freq 7 playing from your radio. You're now wanted: switch it off, or run."  (on-screen notice, line 1141)

> Note for you (not shown in game): Pat-down (Civil Protection)

- "Left pocket"  (text, line 1153)
- "Right pocket"  (text, line 1153)
- "They hold their coat closed with one hand."  (text, line 1155)
- "Their left hand keeps drifting to their pocket."  (text, line 1155)
- "They keep their right side turned away from you."  (text, line 1156)
- "They won't stop tugging their shirt down."  (text, line 1156)
- "They shift their weight off one foot."  (text, line 1157)
- "They hold the bag tight against them."  (text, line 1157)
- "a pistol magazine"  (text, line 1159)
- "a Resistance leaflet"  (text, line 1159)
- "a forged ration card"  (text, line 1159)
- "a data chip"  (text, line 1160)

> Note for you (not shown in game): part of: verdict

- "You let them go, but they were hiding something you missed."  (chat message, line 1186)
- "You let them go and hand back what you found. They don't say thank you; they don't dare."  (chat message, line 1187)
- "Confiscated: {what}. Logged as evidence."  (chat message, line 1193)
- "You detained someone with nothing on them: a wrong call, and it comes out of your pay. Dispatch is not impressed, and neither is the street."  (chat message, line 1204)
- "Every call right: 3 credits bonus."  (text, line 1214)
- "%d searched, %d right."  (message, line 1215)

> Note for you (not shown in game): part of: start

- "Press E on a citizen to stop them. In the window, pat down one place at a time: each empty place you check costs some of their nerve, and if it runs out they run off. Watch how they act, as it hints where something is hidden. Then choose: Release, Confiscate (if you found something) or Detain."  (chat message, line 1227)

> Note for you (not shown in game): part of: hud

- "Searched: %d of %d"  (message, line 1229)
- "Right calls: %d"  (message, line 1229)
- "Their nerve (they run at zero): %s"  (message, line 1230)
- "Press E on a citizen to stop and search them"  (text, line 1230)

> Note for you (not shown in game): part of: use

- "You searched that citizen already. Pick someone else."  (chat message, line 1241)

> Note for you (not shown in game): part of: act

- "They lose their nerve and run off."  (chat message, line 1282)
- "One ran off with something hidden on them."  (text, line 1283)
- "%d searched, %d right."  (message, line 1287)

> Note for you (not shown in game): part of: room

- "Get everyone on the floor: press E on each person before they run or burn evidence. Then search the room: press E on each outlined piece of furniture."  (chat message, line 1340)

> Note for you (not shown in game): part of: start

- "The door is locked. Press E on it to set a breaching charge, then stand back: it blows a moment later."  (chat message, line 1358)

> Note for you (not shown in game): part of: hud

- "Charge set: stand back"  (text, line 1363)
- "Press E on the door to set the charge"  (text, line 1363)
- "On the floor: %d    Ran: %d    Still standing: %d"  (message, line 1368)
- "Found: %d    Destroyed: %d    Left to search: %d"  (message, line 1369)

> Note for you (not shown in game): part of: use

- "Found: {what}."  (chat message, line 1397)
- "Ash, and the smell of burnt paper. Someone destroyed what was here before you searched it."  (chat message, line 1399)

> Note for you (not shown in game): part of: tick

- "Someone you didn't get on the floor in time burned evidence. Whatever it was, it's gone."  (chat message, line 1432)
- "One of them ran out the back before you got them on the floor."  (chat message, line 1438)
- "Nobody ran and nothing was destroyed: 4 credits bonus."  (text, line 1447)
- "%d on the floor, %d ran, %d found."  (message, line 1448)

## hauling the dead (sv_livingcity_mortuary.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_mortuary.lua`


> Note for you (not shown in game): Where bodies go Incinerators, then morgue workplaces. Each: { pos, ent, name }.

- "the incinerator"  (name, line 42)
- "the morgue"  (name, line 46)

> Note for you (not shown in game): part of: cremate

- "The incinerator door clangs shut. The roar takes a while to die down."  (text, line 106)
- "You zip the bag and leave it with the others."  (text, line 106)
- "[Mortuary] {burnt}{or}"  (chat message, line 110)

> Note for you (not shown in game): part of: start haul

- "That isn't a body."  (text, line 123)
- "Someone else already has hold of them."  (text, line 125)
- "Get closer."  (text, line 126)
- "You take hold of the body by the collar.{or}"  (chat message, line 132)

> Note for you (not shown in game): let go next to an incinerator, or at the morgue: that's where it stays

- "You let go of the body."  (chat message, line 151)

> Note for you (not shown in game): E on the incinerator: in goes whoever you're hauling, or a body lying right beside it.

- "the incinerator"  (name, line 167)

> Note for you (not shown in game): a body cart brought up to it: everything on it goes in

- "The incinerator is roaring. You've nothing to put in it. (Haul a body here: E on a body, or the actions menu.)"  (text, line 176)
- "Bring the body closer."  (text, line 177)

> Note for you (not shown in game): Drag: the body follows at your heels, by the shoulders.

- "The body snags on something and slips out of your grip."  (chat message, line 189)

> Note for you (not shown in game): The body cart (Morticians, if they want one): take one at the incinerator or the morgue (F1 > Take a body cart, or !bodycart), let go of a body beside it and it goes on, push it (E on it; E again lets go), and E on the incinerator burns everything on it, paid for each. Four at a time.

- "Body carts are for Morticians."  (text, line 244)

> Note for you (not shown in game): part of: take body cart

- "You've a cart out already (E on it to push it)."  (text, line 245)
- "Body carts are kept by the incinerator, or at the morgue. Go there for one."  (text, line 246)
- "[Mortuary] A body cart. E on it to push it (E again lets go). Let go of a body beside it and it goes on. Push it to the incinerator and press E on the incinerator."  (chat message, line 261)

> Note for you (not shown in game): part of: load body cart

- "[Mortuary] On the cart (%d of %d)."  (message, line 277)

> Note for you (not shown in game): typing in chat

- "[Mortuary] You leave the cart."  (chat message, line 362)

## routes over the map's own nodegraph (sv_livingcity_navgraph.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_navgraph.lua`


> Note for you (not shown in game): part of: learn ladder

- "Learned a ladder (#%d) from a climb: %s up to %s"  (message, line 619)

## what now? (sv_livingcity_nextstep.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_nextstep.lua`


> Note for you (not shown in game): { key, text, why, way, urgent }

- "Serve your time"  (text, line 180)
- "You're in custody. It ends when your sentence does (or someone gets you out)."  (text, line 180)
- "Hold on"  (text, line 183)
- "You're down and bleeding out. Someone can press E on you to help."  (text, line 183)

> Note for you (not shown in game): part of: next step

- "Register at Civil Intake"  (text, line 196)
- "Until you're on the register you get no rations, no job and no room."  (text, line 196)
- "Ask Housing Allocation for a room"  (text, line 199)
- "You're registered. Next, a room: press E on the Housing Allocation terminal."  (text, line 199)

> Note for you (not shown in game): eating and drinking, before anything else

- "Eat something"  (text, line 205)
- "You're hungry, and you have {food}: F2, then use it."  (text, line 205)
- "Collect your ration"  (text, line 206)
- "You're hungry and your allocation is ready: go to the dispenser (it takes one ration card)."  (text, line 206)
- "Buy food at the Commissary"  (text, line 208)
- "You're hungry. %s costs %d credits; you have enough."  (message, line 208)
- "Work a shift for a ration card"  (text, line 210)
- "You're hungry and have no ration card. Each Union shift you finish earns one: F3 has your next shift. Until then, search bins."  (text, line 210)

> Note for you (not shown in game): part of: next step

- "Find something to eat"  (text, line 213)
- "Your next ration is in %d minutes."  (message, line 213)
- "Until then: search bins, or work a shift (it pays credits and a ration card)."  (text, line 214)
- "Have a drink"  (text, line 218)
- "You're thirsty, and you have {drink}: F2, then use it."  (text, line 218)
- "Find water"  (text, line 219)
- "You're thirsty. A sink or a water machine: press E on it."  (text, line 219)
- "Find your block"  (text, line 223)
- "You live in {or}. It's where you sleep, keep things, and shelter at curfew."  (text, line 223)
- "Finish what you're doing"  (text, line 229)
- "its next step is on your screen, and on F3."  (text, line 229)
- "Get a Union job"  (text, line 232)
- "Jobs pay credits, standing and a ration card for each shift. No job, no rations. F3 > Jobs: pick one."  (text, line 232)
- "Collect your ration"  (text, line 235)
- "Your allocation is ready: go to the dispenser (it takes one ration card)."  (text, line 235)
- "Work a shift"  (text, line 238)
- "You're short of credits. F3 has your next shift."  (text, line 238)
- "The Union expects more"  (text, line 240)
- "Idle hands are noticed. Another shift (F3), or a side job (F3); a citizen seen loafing is a citizen asked questions."  (text, line 240)
- "On duty"  (text, line 243)
- "Your directives are on F3. The Commissary issues your supplies."  (text, line 243)

## on the screen, not just in chat (sv_livingcity_notices.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_notices.lua`


> Note for you (not shown in game): [tag] = how it shows

- "Civil Protection"  (text, line 35)
- "Civil Intake"  (text, line 37)
- "Housing Allocation"  (text, line 37)

> Note for you (not shown in game): Where each kind of place is, for this person: pos, label (or nil and why not).

- "Civil Protection Commissary"  (text, line 140)
- "Commissary (Civil Protection units are issued supplies here)"  (text, line 142)
- "There's no Civil Protection Commissary in this city yet. Your grenades are topped up when you go on duty. (Staff: Living City Editor > Fixture: Civil Protection Commissary.)"  (text, line 143)

> Note for you (not shown in game): part of: intake

- "Civil Intake"  (text, line 147)
- "This city has no Civil Intake desk."  (text, line 148)

> Note for you (not shown in game): part of: housing

- "Housing Allocation"  (text, line 152)
- "This city has no Housing Allocation desk."  (text, line 153)

> Note for you (not shown in game): part of: home

- "Your block isn't on the map."  (text, line 159)
- "You have no room yet."  (text, line 159)

> Note for you (not shown in game): part of: lab

- "The lab"  (text, line 163)
- "No cell has a lab yet. (Staff: Living City Editor > Fixture: Resistance lab.)"  (text, line 164)

> Note for you (not shown in game): Point them at a place by kind. True, or false and why not.

- "[Living City] {label}"  (chat message, line 176)

> Note for you (not shown in game): a block's middle can be in mid air or between wings: being inside the block is arriving

- ": it's marked on your screen."  (on-screen notice, line 182)

> Note for you (not shown in game): a timer (regularly)

- "You're here: {or}."  (on-screen notice, line 196)

## the city does its own work (sv_livingcity_npcwork.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_npcwork.lua`

- "fixing a streetlight"  (text, line 490)
- "fixing a loudspeaker"  (text, line 491)

> Note for you (not shown in game): Sanitation Graffiti gets scrubbed (sv_livingcity_scavenge.lua).

- "scrubbing graffiti"  (label, line 498)

> Note for you (not shown in game): part of: find

- "scrubbing graffiti"  (what someone is doing, line 512)

> Note for you (not shown in game): Junk left lying in the street: empty cans and bottles, rags.

- "picking up litter"  (label, line 529)

> Note for you (not shown in game): part of: find

- "picking up litter"  (what someone is doing, line 542)

> Note for you (not shown in game): The bin round: the city's bins, one after another, and the bags to the depot.

- "emptying bins"  (label, line 555)

> Note for you (not shown in game): part of: find

- "emptying the bins"  (what someone is doing, line 563)
- "taking the rubbish to the depot"  (what someone is doing, line 568)

> Note for you (not shown in game): Mortuary: hauling the dead (sv_livingcity_mortuary.lua)

- "collecting the dead"  (label, line 578)

> Note for you (not shown in game): part of: find

- "collecting the dead"  (what someone is doing, line 605)
- "taking the body to {name}"  (what someone is doing, line 608)
- "helping someone who's down"  (label, line 632)
- "helping someone who's down"  (what someone is doing, line 647)

> Note for you (not shown in game): part of: done

- "[Living City] {or}, a Union medic, patches you up enough to stand."  (chat message, line 651)

> Note for you (not shown in game): A wounded citizen.

- "treating the wounded"  (label, line 659)

> Note for you (not shown in game): part of: find

- "treating the wounded"  (what someone is doing, line 672)

> Note for you (not shown in game): Clinic duty: and anyone who comes in gets seen to.

- "on duty at the clinic"  (label, line 678)
- "on duty at the clinic"  (what someone is doing, line 682)

> Note for you (not shown in game): part of: tick

- "[Living City] The clinic medic sees to you. (+10 health while you stay close)"  (chat message, line 691)

> Note for you (not shown in game): Ration Production

- "collecting a crate from the dock"  (text, line 832)
- "sealing ration packs"  (text, line 833)

> Note for you (not shown in game): Factory

- "collecting parts from the dock"  (text, line 837)

> Note for you (not shown in game): (quiet work at the line: the clanks were heard all over the factory, long after the belt stopped)

- "working the line"  (text, line 841)

> Note for you (not shown in game): Courier: the mail, door to door

- "collecting the mail"  (text, line 847)

> Note for you (not shown in game): Intake Processor: luggage, platform to the blocks

- "collecting luggage from the platform"  (text, line 852)
- "on the platform"  (text, line 853)

> Note for you (not shown in game): Records Clerk

- "filing records"  (text, line 856)
- "collecting the day's papers"  (text, line 858)

> Note for you (not shown in game): Uniform Laundry

- "running the machines"  (text, line 861)
- "bundling the pressed uniforms"  (text, line 863)

> Note for you (not shown in game): Reclamation Crew: rubble to the reclamation point

- "clearing rubble"  (label, line 871)

> Note for you (not shown in game): part of: find

- "clearing rubble"  (what someone is doing, line 883)
- "handing in scrap"  (what someone is doing, line 888)
- "sorting scrap at the yard"  (text, line 892)

> Note for you (not shown in game): Radio Repair, and Maintenance, when nothing's broken: at the bench, in the yard

- "repairing radios at the bench"  (text, line 895)

> Note for you (not shown in game): (the radios are on the benches whether anyone's working them or not)

- "at the maintenance yard"  (text, line 901)
- "at the sanitation depot"  (text, line 902)

> Note for you (not shown in game): Dead headcrabs left lying about: the morgue bags them for the incinerator.

- "bagging dead headcrabs"  (label, line 907)

> Note for you (not shown in game): part of: find

- "bagging a dead headcrab"  (what someone is doing, line 923)

> Note for you (not shown in game): Somebody's mess in the street: sanitation scrubs it up (sv_livingcity_hygiene.lua)

- "scrubbing up a mess"  (label, line 929)

> Note for you (not shown in game): part of: find

- "scrubbing up somebody's mess"  (what someone is doing, line 944)
- "at the morgue"  (text, line 951)
- "sorting the mail"  (text, line 952)

> Note for you (not shown in game): part of: npcretake screens

- "retaking a hijacked screen"  (text, line 984)
- "retaking a hijacked screen"  (what someone is doing, line 987)

> Note for you (not shown in game): part of: done

- "[CP net] A Civil Protection unit has the hijacked screen back under control."  (chat message, line 993)
- "[Resistance] They cut the broadcast."  (chat message, line 994)

> Note for you (not shown in game): In the debug report

- "NPC work: %d at it now; %d started, %d finished, %d dropped. %s"  (message, line 1019)

## clothes that show the job (sv_livingcity_outfits.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_outfits.lua`


> Note for you (not shown in game): The look this person wears for this job: model, skin, { bodygroup name = value }. key keeps it the same person to person; face is their own face (male_03). sex: "male" or "female" when it's known (the person's own record); else from their face

- "\|{jobId}"  (text, line 99)

> Note for you (not shown in game): The designer (cl_livingcity_outfits.lua)

- "Everyone else (no job)"  (name, line 368)
- "New characters choose from"  (name, line 369)

> Note for you (not shown in game): What the designer sends back for one job, cleaned up.

- "Admins only."  (text, line 376)
- "No such job."  (text, line 377)

> Note for you (not shown in game): the game answering something done in a window (lc_outfits_save)

- "[Outfits] {or}"  (chat message, line 411)

> Note for you (not shown in game): (not "lc_outfits": that name is the on/off setting, and a setting and a command can't share a name)

- "Admins only."  (chat message, line 415)
- "Admins only."  (chat message, line 417)

## path mapping, drawing the walkable network by walking it (sv_livingcity_pathmap.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_pathmap.lua`


> Note for you (not shown in game): part of: path map step

- "[Path mapping] %d nodes laid this session (%d in the map)."  (message, line 104)

> Note for you (not shown in game): part of: set path mapping

- "[Path mapping] ON. Walk the places NPCs should be able to go. Noclip, jumping and vehicles pause it. Run lc_pathmap again to stop."  (chat message, line 132)
- "[Path mapping] OFF. %d nodes added and saved (%d in the map). Unlinked ones show red in the editor overlay."  (message, line 137)

> Note for you (not shown in game): the console command lc_pathmap_undo

- "[Path mapping] Turn it on first; undo removes what this session added."  (chat message, line 152)
- "[Path mapping] Removed the %d nodes added this session."  (message, line 158)

> Note for you (not shown in game): typing in chat

- "Only editors can map paths."  (chat message, line 164)

## people (sv_livingcity_people.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_people.lua`


> Note for you (not shown in game): the face first, then a name that goes with it

- "Citizen {id}"  (text, line 203)

> Note for you (not shown in game): an NPC dying

- "%s (%s) was killed%s"  (message, line 310)
- "by {killer}"  (text, line 310)

> Note for you (not shown in game): the console command lc_people

- "[Living City] %d citizens and %d Civil Protection units alive (%d out now), %d sympathizers, %d with jobs, %d dead remembered"  (message, line 369)

> Note for you (not shown in game): the console command lc_resetpeople

- "[Living City] The city's people have been replaced. People already on the streets keep their old faces until they leave."  (chat message, line 388)

## server timing (sv_livingcity_perf.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_perf.lua`


> Note for you (not shown in game): the console command lc_profile

- "[Living City] Timer timings cleared."  (chat message, line 70)
- "[Living City] Costliest timers (total ms, per call average, worst, calls):"  (chat message, line 75)
- "%-34s %8.1f total  %6.2f avg  %6.2f worst  %d calls"  (message, line 78)
- "NPC loop: %.2f ms average, %.2f worst, over %d runs"  (message, line 83)

## the power grid (sv_livingcity_power.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_power.lua`


> Note for you (not shown in game): the map's lighting, with the hour of the day (sv_livingcity_atmos.lua tells everyone's game to rebuild it)

- "[City] The grid's gone. The whole city is dark: switch on your flashlight (F)."  (chat message, line 162)
- "[City] The lights come back on across the city."  (chat message, line 163)
- "The whole grid's down. Every Combine door in the city is dead."  (text, line 165)

> Note for you (not shown in game): part of: transformer down

- "[CP net] Power failure {where}. The district's Combine locks are dead and its forcefields are down. Secure it."  (chat message, line 218)
- "The grid's down {where}. Their doors are open, for now."  (text, line 220)
- "[Union] Power failure {where}. Get the transformer back up (E on it)."  (chat message, line 222)
- "the grid"  (text, line 226)

> Note for you (not shown in game): part of: transformer restore

- "[CP net] Power restored {where}."  (chat message, line 239)

> Note for you (not shown in game): E on a transformer: a maintenance technician fixes it.

- "It hums. The district has power."  (text, line 246)
- "Dead, and sparking. You don't know the first thing about it: Maintenance Technicians repair these."  (text, line 248)
- "Rewiring the transformer..."  (progress bar, line 250)
- "You leave it half rewired."  (text, line 251)

> Note for you (not shown in game): part of: done

- "power restored"  (text, line 254)
- "[Union] The district has power again."  (chat message, line 256)

> Note for you (not shown in game): A multitool: twelve seconds, and the district goes dark.

- "You need a multitool."  (text, line 263)
- "Look at a transformer."  (text, line 264)
- "It's already dead."  (text, line 265)
- "Shorting the transformer... keep at it"  (progress bar, line 266)
- "You pull back before it blows."  (text, line 267)

> Note for you (not shown in game): Forcefields

- "You need a multitool."  (text, line 274)
- "Look at a forcefield."  (text, line 275)
- "Shorting the forcefield..."  (progress bar, line 276)
- "The field snaps back."  (text, line 277)

> Note for you (not shown in game): part of: swipe forcefield

- "Access denied. (Civil Protection units pass; a Combine keycard opens it for a moment.)"  (text, line 295)
- "Unauthorized access"  (text, line 302)

> Note for you (not shown in game): Emergency crews, eventually.

- "[City] Emergency crews have restored power {GetPos}."  (chat message, line 346)

> Note for you (not shown in game): The city's own maintenance crews see to it too (after the players have had their chance).

- "restoring power"  (label, line 353)

> Note for you (not shown in game): part of: find

- "restoring power"  (what someone is doing, line 368)

## prison (sv_livingcity_prison.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_prison.lua`


> Note for you (not shown in game): part of: say

- "[Living City] {msg}"  (chat message, line 39)

> Note for you (not shown in game): part of: notify cp

- "[Dispatch] {msg}"  (chat message, line 44)

> Note for you (not shown in game): Players

- "not a player"  (text, line 87)

> Note for you (not shown in game): part of: incarcerate

- "no free cell (place more with the editor)"  (text, line 98)
- "You have been incarcerated for %s. Reason: %s"  (message, line 111)
- "none given"  (message, line 111)
- "no reason"  (message, line 112)
- "Jailed %s for %ds: %s"  (message, line 113)

> Note for you (not shown in game): part of: release prisoner

- "[Civil Protection] Your weapons and radio stay in the evidence locker."  (chat message, line 168)
- "You have been released. Behave."  (chat message, line 173)

> Note for you (not shown in game): Back in their cell (a unit caught them out of it).

- "[Civil Protection] {msg}"  (chat message, line 185)

> Note for you (not shown in game): part of: escape

- "Prison escape"  (text, line 197)
- "has escaped custody!"  (text, line 199)
- "You escaped. Every Civil Protection unit in the sector is looking for you."  (chat message, line 201)

> Note for you (not shown in game): part of: end detention

- "[Civil Protection] Released with a warning. Move along."  (chat message, line 251)

> Note for you (not shown in game): part of: detain on the spot

- "[Civil Protection] Detained: %s. You're cuffed and made to kneel."  (message, line 273)
- "[Living City] This map has no prison cells yet, so arrests happen on the street. Place cells (and a release spot) with the Living City Editor for real ones."  (chat message, line 277)
- "Detained %s on the street for %ds: %s"  (message, line 279)

> Note for you (not shown in game): Giving yourself up: walk up to a unit and press E (or !surrender). A shorter sentence, the search called off, and serving it pays back more of your Civil Standing.

- "Not now."  (text, line 307)
- "Civil Protection units don't surrender."  (text, line 308)

> Note for you (not shown in game): part of: surrender

- "[Civil Protection] You put your hands up."  (chat message, line 315)

> Note for you (not shown in game): to a unit NPC: he walks you there (sv_livingcity_march.lua)

- "Nobody's taking you in right now."  (text, line 323)

> Note for you (not shown in game): typing in chat

- "[Civil Protection] There's no Civil Protection unit close enough to surrender to."  (chat message, line 343)
- "[Civil Protection] {why}"  (chat message, line 346)

> Note for you (not shown in game): A unit takes someone in: walked to a cell, or cuffed on the street where there's none. (A stunstick hit does it, a hit that would take them under 20 health, or a unit who's run a non-violent suspect down and laid hands on them: sv_livingcity.lua.)

- "Resisting Civil Protection"  (text, line 442)

> Note for you (not shown in game): Disconnecting doesn't either.

- "disconnected while in custody. Their sentence will resume when they return."  (text, line 485)

> Note for you (not shown in game): a timer (regularly)

- "Returned mid-sentence"  (text, line 494)
- "You left in the middle of your sentence. It resumes now, with {GetInt} extra seconds."  (chat message, line 497)
- "Absconded from custody"  (text, line 499)

> Note for you (not shown in game): out, and off home: they don't hang about outside the prison

- "let out of prison, and gone home"  (text, line 528)

> Note for you (not shown in game): Used by the Arrest Baton on NPC citizens (and by quests): cuffed, then a moment later they're in a cell, the same way an arrested player is.

- "only citizens can be arrested"  (text, line 535)
- "no free cell"  (text, line 537)

> Note for you (not shown in game): part of: baton may arrest

- "Only Civil Protection can make arrests."  (text, line 561)

> Note for you (not shown in game): the console command lc_jail

- "Usage: lc_jail <name> [seconds] [reason]"  (chat message, line 583)
- "Administrative detention"  (text, line 586)
- "Couldn't: {err}"  (text, line 587)

> Note for you (not shown in game): the console command lc_unjail

- "Usage: lc_unjail <name>"  (chat message, line 593)
- "isn't in custody."  (text, line 594)

> Note for you (not shown in game): the console command lc_prisoners

- "Nobody is in custody."  (chat message, line 606)

## close calls, careers for life, and what passes on (sv_livingcity_progress.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_progress.lua`


> Note for you (not shown in game): a timer (regularly)

- "A close call"  (on-screen notice, line 108)
- "You wake up in the infirmary, sore and empty-handed: what was in your pockets is gone. You don't remember the fight, or who started it; leave it be. {or}"  (on-screen notice, line 109)

> Note for you (not shown in game): Careers for life Why this person can't take up another faction (nil if they can).

- "Combine property doesn't choose. Only death ends a stalker."  (text, line 144)
- "The conditioning can't be undone: this person is Overwatch for life. Another character (!characters) can be someone else."  (text, line 147)
- "stepped into the light"  (text, line 171)
- "was taken out of the city by staff"  (text, line 171)

> Note for you (not shown in game): a timer (regularly)

- "An inheritance"  (on-screen notice, line 197)
- "A relative you barely knew has left you %d credits. It isn't much. It's yours."  (message, line 197)

> Note for you (not shown in game): Retiring someone

- "Not while you're dead."  (text, line 207)
- "Not while you're wanted."  (text, line 208)
- "Not while you're in custody."  (text, line 209)
- "Not in the middle of a fight."  (text, line 210)
- "A stalker doesn't retire. There's only the one way out."  (text, line 211)

> Note for you (not shown in game): part of: retire character

- "has left the city for good. Somebody new takes their place."  (text, line 216)

> Note for you (not shown in game): part of: levy

- "Union levy"  (on-screen notice, line 231)
- "%d credits redistributed: holdings above %d are shared with the Union. Spend it, or lose it slowly."  (message, line 231)

## street furniture, and the city's voice (sv_livingcity_propaganda.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_propaganda.lua`


> Note for you (not shown in game): part of: start broadcast

- "Someone is already on air."  (text, line 149)

> Note for you (not shown in game): The Administrator's recorded address (below): the Director of Propaganda can cut in; anyone else waits

- "is on air. The transmitter is hers until she's done."  (text, line 152)
- "The transmitter is cooling down: %d:%02d."  (message, line 157)

> Note for you (not shown in game): part of: start broadcast

- "[Pirate broadcast] Someone has seized the city's transmitter: {Nick}."  (text, line 165)
- "[City broadcast] {Nick} is on air."  (text, line 166)
- "[CP net] The city transmitter has been seized. Find whoever has the microphone."  (chat message, line 170)

> Note for you (not shown in game): part of: stop broadcast

- "[Pirate broadcast] The transmission ends."  (chat message, line 191)
- "[City broadcast] Off air."  (chat message, line 191)
- "pirate broadcast"  (text, line 195)
- "pirate broadcast"  (text, line 197)
- "city broadcast"  (text, line 201)

> Note for you (not shown in game): part of: toggle broadcast

- "off air"  (text, line 209)
- "You need the microphone in your hand."  (text, line 210)

> Note for you (not shown in game): Taking it off someone tied up, or with their hands up (the actions menu, F1)

- "Look at who has it."  (text, line 265)
- "Get closer."  (text, line 266)
- "They haven't got a microphone."  (text, line 267)
- "Not while they can stop you: hands up, or cuffed."  (text, line 269)

> Note for you (not shown in game): part of: take microphone

- "[City] {Nick} takes the microphone off you."  (chat message, line 274)
- "[City] You take the microphone. Left click with it to go on air, when the transmitter's ready."  (chat message, line 275)
- "[CP net] The city microphone has been stolen {GetPos}."  (chat message, line 278)

> Note for you (not shown in game): Dormant by default until there are enough recordings. Switch on with lc_breen_broadcasts 1 (the lc_breencast command still works for a test).

- "The Administrator"  (text, line 296)

> Note for you (not shown in game): song: played by the game's music player (sound.PlayFile), which takes an .mp3 or .ogg at any rate: only a file that isn't what its name says matters.

- "empty, or couldn't be read"  (text, line 487)
- "it's really an MP3 named .wav, so nobody hears it: rename it to .mp3"  (text, line 491)

> Note for you (not shown in game): part of: sound problem

- "it's really an OGG named .wav, so nobody hears it: rename it to .ogg"  (text, line 492)
- "not a real WAV: convert it (16-bit, 44100 Hz)"  (text, line 493)
- "-bit, which the game can't play: convert it to 16-bit"  (text, line 500)
- "32-bit float, which the game can't play: convert it to 16-bit"  (text, line 501)
- "Hz, which the game can't play: convert it to 44100 Hz"  (text, line 502)
- "not a real WAV: convert it (16-bit, 44100 Hz)"  (text, line 507)
- "it's really a WAV named .mp3: rename it to .wav"  (text, line 509)
- "it's really an OGG named .mp3: rename it to .ogg"  (text, line 510)
- "not a real MP3"  (text, line 512)
- "Hz, which may play at the wrong speed: convert it to 44100 Hz"  (text, line 513)
- "it's really a WAV named .ogg: rename it to .wav"  (text, line 515)
- "it's really an MP3 named .ogg: rename it to .mp3"  (text, line 516)

> Note for you (not shown in game): part of: start npcbroadcast

- "Someone is already on air."  (text, line 583)
- "No recordings for {AdministratorName} yet (sound/livingcity/administrator/, named ambient1.wav and so on)."  (text, line 585)
- "[City broadcast] {AdministratorName} addresses the city."  (chat message, line 595)

> Note for you (not shown in game): part of: stop npcbroadcast

- "[City broadcast] The transmission cuts out."  (chat message, line 617)
- "[City broadcast] Off air."  (chat message, line 619)

> Note for you (not shown in game): an NPC dying

- "[CP net] {AdministratorName} has been attacked {GetPos}. Secure the microphone."  (chat message, line 642)
- "Attacking the Administrator"  (text, line 644)

> Note for you (not shown in game): the console command lc_breencast

- "[Living City] {why}"  (text, line 674)

## persistent props (sv_livingcity_props.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_props.lua`


> Note for you (not shown in game): part of: tell

- "[Living City] {msg}"  (chat message, line 30)

> Note for you (not shown in game): Make a prop persistent (or, if it already is, save it as it is now).

- "Aim at a prop (one you've spawned)."  (text, line 90)
- "That prop is part of the map already: it's always there."  (text, line 93)

> Note for you (not shown in game): part of: persist prop

- "That one belongs to the city (dressing, a supply crate, a fixture or a job). Spawn your own."  (text, line 96)

> Note for you (not shown in game): Moved with the physgun (build mode): saved where it's dropped, frozen again.

- "Moved: the persistent prop is saved where you put it."  (chat message, line 190)

> Note for you (not shown in game): the game's can tool moment

- "Removed, and taken out of the layout."  (chat message, line 205)

## quests (sv_livingcity_quests.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_quests.lua`


> Note for you (not shown in game): Reading the world

- "hoarding ration units"  (text, line 153)
- "unauthorized assembly"  (text, line 153)
- "possession of contraband"  (text, line 153)
- "failing a loyalty check"  (text, line 153)
- "breaking curfew"  (text, line 154)
- "speaking out against the Combine"  (text, line 154)
- "trading ration units"  (text, line 154)
- "moving home without registering"  (text, line 154)
- "tampering with a city terminal"  (text, line 155)
- "harboring an anticitizen"  (text, line 155)

> Note for you (not shown in game): Half-Life 2 has no proper elderly citizen model; these are its older faces.

- "an unregistered radio"  (text, line 163)
- "a stash of ration units"  (text, line 164)
- "Resistance pamphlets"  (text, line 165)
- "a weapons cache"  (text, line 166)
- "The note says only: the canal gate opens at four."  (text, line 173)
- "A child's drawing of a lambda (the Resistance symbol) and an address. You memorize the address and burn the note."  (text, line 174)
- "Coordinates, and a single word: Ravenholm. You decide not to go."  (text, line 175)
- "A list of Civil Protection unit numbers. Two are crossed out."  (text, line 176)

> Note for you (not shown in game): part of: describe place

- "near {group}"  (text, line 190)
- "in rebel territory"  (text, line 192)
- "by the prison"  (text, line 194)
- "by the ration line"  (text, line 200)
- "at a checkpoint"  (text, line 201)
- "outside an apartment doorway"  (text, line 202)
- "%d metres %s of you"  (message, line 203)
- "somewhere in the city"  (text, line 204)

> Note for you (not shown in game): Somewhere safe for the Resistance: rebel territory if there is any, else far away.

- "rebel territory"  (text, line 531)

> Note for you (not shown in game): part of: narrate

- "[{board}] {text}"  (chat message, line 675)

> Note for you (not shown in game): part of: enter stage

- "the job's target couldn't be found"  (text, line 759)

> Note for you (not shown in game): part of: send state

- "%ds / %ds"  (message, line 823)
- "You can't remember what you were doing: Breen's water has clouded your memory. It comes back in about a minute."  (text, line 835)

> Note for you (not shown in game): Ticking quests

- "the person you were escorting is gone"  (text, line 862)

> Note for you (not shown in game): part of: poll

- "you ran out of time"  (text, line 991)
- "everyone left the job"  (text, line 993)
- "you were arrested"  (text, line 997)

> Note for you (not shown in game): follow someone: close enough to keep them in sight, far enough not to be noticed

- "the person you were following is gone"  (text, line 1009)

> Note for you (not shown in game): suspicion builds while they can see you (or hear you right behind them) and fades while you're out of sight; only a full meter blows it

- "They keep glancing back: they're getting suspicious. Get out of their sight before they spot you."  (quest narration, line 1027)

> Note for you (not shown in game): part of: poll

- "they noticed you following them"  (text, line 1031)
- "you fell too far behind and lost them"  (text, line 1035)
- "your target is gone"  (text, line 1062)
- "Another Civil Protection unit arrested them first. You get half the reward."  (quest narration, line 1068)

> Note for you (not shown in game): A ration break: rations are out mid-shift, so the job waits (its clock stopped, nothing failing for your being away) till you've had your ration, five minutes are up, or you go back to it. F1 > Take a ration break (or !rationbreak; !back to carry on).

- "You don't have a shift or job running, so there's nothing to take a break from."  (text, line 1087)
- "Rations aren't being handed out right now, so you can't take a ration break."  (text, line 1088)

> Note for you (not shown in game): part of: on break

- "[Work] Your ration break is over (five minutes at most). Your job's timer is running again."  (chat message, line 1103)

> Note for you (not shown in game): the game's living city ration collected moment

- "[Work] You've got your ration, so your break is over. Your job carries on from where you left it."  (chat message, line 1111)

> Note for you (not shown in game): the game's living city event started moment

- "Rations are being handed out"  (on-screen notice, line 1119)
- "To get your ration without failing your job, press F1 and choose Take a ration break. It pauses your job's timer until you've collected your ration (five minutes at most)."  (on-screen notice, line 1119)

> Note for you (not shown in game): the chat command /rationbreak

- "[Work] Ration break started. Your job's timer is paused until you collect your ration, for five minutes at most. Type /back to end the break early."  (chat message, line 1126)
- "[Work] {or}"  (text, line 1126)

> Note for you (not shown in game): the chat command /back

- "[Work] Break ended. Your job's timer is running again."  (chat message, line 1129)
- "[Work] You're not on a break."  (chat message, line 1129)

> Note for you (not shown in game): a timer (regularly)

- "something went wrong"  (text, line 1140)

> Note for you (not shown in game): Building blocks for templates

- "Choose what to do"  (text, line 1246)

> Note for you (not shown in game): part of: arrest stage

- "Detain them with the Arrest Baton (right click)"  (text, line 1290)

> Note for you (not shown in game): part of: build

- "Walk to patrol stop %d of %d, %s"  (message, line 1356)
- "Patrol sweep {GetPos}"  (title, line 1358)
- "Walk to each marked patrol stop in turn, so citizens see Civil Protection on the streets."  (description, line 1359)
- "Dispatch wants boots on the street. Yours will do."  (text, line 1360)
- "Overwatch reports elevated noncompliance. Show them the uniform."  (text, line 1360)
- "Civil status inspections"  (title, line 1371)
- "Stop %d citizens and %s. Nobody is above suspicion."  (message, line 1372)
- "pat them down"  (message, line 1372)
- "check their papers"  (message, line 1372)
- "Pat down %d citizens: walk up to one and press E, search them, then release them, confiscate what they carry, or detain them"  (message, line 1373)
- "Inspect citizens: walk up to one and press E"  (quest step, line 1374)
- "Apprehend citizen {id}"  (title, line 1386)
- "Citizen %s is wanted for %s. An informant has given you their location: they're marked on your screen."  (message, line 1387)
- "Find citizen {id} (marked on your screen)"  (text, line 1389)
- "Citizen %s freezes. Their eyes go to your baton, then to the street behind you."  (message, line 1390)
- "Detain them."  (text, line 1391)
- "Make them name their supplier."  (text, line 1392)

> Note for you (not shown in game): part of: success

- "They crack and tell you: there's {stash} hidden {GetPos}."  (quest narration, line 1395)
- "Find {stash} (marked) and press E on it to seize it"  (text, line 1399)

> Note for you (not shown in game): part of: fail

- "They shove past you and run! Catch them."  (quest narration, line 1402)

> Note for you (not shown in game): part of: build

- "Take their ration units as a bribe and let them go (ends the job, less XP)."  (text, line 1405)

> Note for you (not shown in game): part of: pick

- "The ration units are still warm from their pocket. Nobody will ever know. You will."  (quest narration, line 1410)

> Note for you (not shown in game): part of: build

- "Let them go (ends the job, no XP)."  (text, line 1413)

> Note for you (not shown in game): part of: pick

- "You look away. They're gone before you look back."  (quest narration, line 1418)

> Note for you (not shown in game): part of: build

- "Checkpoint duty {GetPos}"  (title, line 1435)
- "Go to the checkpoint and stand guard there until the timer is full. Nobody passes without being looked at."  (description, line 1436)
- "Go to the marked checkpoint"  (quest step, line 1437)
- "Stay at the checkpoint until the timer is full"  (quest step, line 1437)
- "Contraband sweep {GetPos}"  (title, line 1449)
- "An informant reports {kind} hidden around this area, in three places. Find and confiscate all three."  (description, line 1450)
- "Confiscate {kind}: find each one (marked) and press E on it"  (text, line 1452)
- "Disturbance {GetPos}"  (title, line 1464)
- "There's a disturbance nearby. Get there fast, then catch and arrest the suspect who runs."  (description, line 1465)
- "Hurry to the marked disturbance"  (quest step, line 1467)
- "Chase the suspect and arrest them with the Arrest Baton (right click)"  (text, line 1469)
- "Someone breaks from the crowd and runs! That's your suspect."  (text, line 1485)
- "Ration line supervision"  (title, line 1499)
- "Keep order at ration line {g} while rations are handed out."  (description, line 1500)
- "Go to ration line {g} (marked)"  (quest step, line 1502)
- "The line is restless. A woman at the front is shaking, and the man behind her keeps looking at your hands."  (quest choice, line 1503)
- "Keep order, by the book."  (text, line 1504)
- "Calm the line with a few quiet words."  (text, line 1505)

> Note for you (not shown in game): part of: success

- "The shaking stops. Somebody actually says thank you."  (quest narration, line 1509)

> Note for you (not shown in game): part of: fail

- "Someone spits near your boots. The line goes quiet anyway."  (quest narration, line 1511)

> Note for you (not shown in game): part of: build

- "Pocket a few ration units while nobody's counting."  (text, line 1512)
- "Stay near the front of the line while 3 citizens collect their rations"  (text, line 1516)
- "Go to the infested area (marked)"  (quest step, line 1541)

> Note for you (not shown in game): done when every infested thing in the area is down, not after a set number

- "Kill every infested creature in this area"  (quest step, line 1574)

> Note for you (not shown in game): part of: poll

- "Kill every infested creature in this area (%d left)"  (message, line 1577)
- "Area clear: every infested creature here is dead"  (text, line 1577)

> Note for you (not shown in game): a patch of it, gone, and quiet for a while

- "The infestation is pushed back: this part of the infested zone is cleared, and nothing will crawl back for a while."  (quest narration, line 1585)
- "Area clear. No infested creatures will appear here for a while."  (quest narration, line 1587)

> Note for you (not shown in game): part of: build

- "Containment {GetPos}"  (title, line 1591)
- "The infestation has spread into new ground. Go there and kill every infested creature to push it back."  (description, line 1592)
- "The infestation is active at its source. Go there and kill every infested creature before it spreads."  (description, line 1592)

> Note for you (not shown in game): the ground that was just taken, or the nearest piece of it

- "Go to the rebel-held ground {where} (marked)"  (quest step, line 1624)
- "Stay on the ground for 30 seconds to secure it"  (quest step, line 1626)

> Note for you (not shown in game): part of: on done

- "The ground is retaken: it's no longer rebel territory. Whatever they built here comes down by morning."  (quest narration, line 1629)

> Note for you (not shown in game): part of: build

- "Retake the block {where}"  (title, line 1632)
- "Anticitizens have taken over ground {where}. Go there, kill 3 of the rebels holding it, then stay on the ground for 30 seconds. Expect them to fight back."  (description, line 1633)
- "Kill 3 of the rebels holding the ground"  (quest step, line 1636)
- "Stay on the spot for 60 seconds. Civil Protection units will come to stop you."  (quest step, line 1660)

> Note for you (not shown in game): dispatch hears about it, and sends whoever is nearest to look

- "Dispatch: anticitizens gathering {where}. Nearby Civil Protection units, investigate."  (text, line 1663)

> Note for you (not shown in game): part of: on done

- "The ground is ours: it's rebel territory now. People are already moving in behind you."  (quest narration, line 1681)
- "You held it, but it can't be kept: the ground doesn't become rebel territory."  (quest narration, line 1681)

> Note for you (not shown in game): part of: build

- "Take ground {where}"  (title, line 1684)
- "We want the ground {where}. Get there and stay on it for a minute, and it becomes rebel territory. Civil Protection units will be sent to stop you."  (description, line 1685)
- "Go to the marked ground {where}"  (quest step, line 1686)
- "Steal the crate of Union supplies {where}: press E on it"  (text, line 1711)

> Note for you (not shown in game): part of: on done

- "Theft of Union supplies"  (text, line 1715)
- "A Civil Protection unit saw you take it. You're wanted now: run."  (quest narration, line 1716)
- "Nobody saw you take it. Walk, don't run."  (quest narration, line 1718)

> Note for you (not shown in game): word gets out: units can follow the smuggler on their screens (sv_livingcity_resistanceops.lua)

- "Take it to the Resistance supply crate in rebel territory (marked)"  (text, line 1723)
- "You add six meals to the Resistance supply crate. It now holds %d."  (message, line 1726)

> Note for you (not shown in game): and ammunition, packed under the food

- "There was ammunition packed under the food. Everyone on the job gets a box."  (quest narration, line 1731)
- "Supply run {where}"  (title, line 1734)
- "The Resistance's food stores are low. The Union keeps supplies {where}. Steal a crate and bring it to the Resistance supply crate in rebel territory."  (description, line 1735)

> Note for you (not shown in game): part of: build

- "Find the crate a contact left {where} and press E to break it open"  (text, line 1765)

> Note for you (not shown in game): part of: on done

- "You break the crate open and put the supplies in your pockets. A search will find them, so don't get stopped."  (quest narration, line 1770)
- "The crate breaks open, but your pockets are full. Make room in your pockets (F2), then pick the supplies up off the ground."  (quest narration, line 1773)

> Note for you (not shown in game): part of: build

- "Take the supplies home to {homeName}"  (text, line 1777)
- "Take the supplies to the Resistance quartermaster (marked)"  (text, line 1777)

> Note for you (not shown in game): (the supplies; or a whole crate, from before crates were broken open)

- "You arrived without the supplies, so there's no reward. Somebody's going to want to know where they went."  (quest narration, line 1784)

> Note for you (not shown in game): part of: on done

- "Inside: 3 gun parts and some chemicals, now in your pockets. Craft them into something worth selling."  (quest narration, line 1791)
- "gun run"  (text, line 1793)
- "The quartermaster counts the guns, then counts out sixty credits. 'Same again, soon.'"  (quest narration, line 1795)

> Note for you (not shown in game): part of: build

- "Parts pickup {where}"  (text, line 1799)
- "Gun run {where}"  (text, line 1799)
- "A smuggler has left gun parts for you {where}. Pick them up and take them home without getting searched."  (text, line 1800)
- "A crate of guns is waiting {where}. Get it to the Resistance quartermaster and you're paid sixty credits."  (text, line 1801)
- "Take over detainee {id} from the Civil Protection unit holding them {place}: walk up to them (marked)"  (text, line 1824)

> Note for you (not shown in game): the handover; then he's back on his beat

- "The Civil Protection unit nods at the detainee. 'All yours.' He heads back to his beat."  (quest narration, line 1849)

> Note for you (not shown in game): part of: build

- "Detainee transfer: {id}"  (title, line 1855)
- "A Civil Protection unit is holding citizen {id} {place} and has been called away. Take over the detainee, choose how to handle them, then arrest them with the Arrest Baton (right click) to send them to the cells."  (description, line 1856)
- "The detainee was flagged by an informant. They swear they've done nothing, and their voice is steady."  (quest choice, line 1859)
- "Process them."  (text, line 1860)
- "Hear them out."  (text, line 1861)

> Note for you (not shown in game): part of: success

- "Their story holds. The informant owed them money. You note it in the file. It won't matter."  (quest narration, line 1865)

> Note for you (not shown in game): part of: fail

- "Halfway through, they contradict themselves. You stop listening."  (quest narration, line 1867)

> Note for you (not shown in game): part of: build

- "Lean on them for names."  (text, line 1868)

> Note for you (not shown in game): part of: success

- "Two names. You'll see them on a directive soon."  (quest narration, line 1872)

> Note for you (not shown in game): part of: fail

- "They go silent. Smarter than they look."  (quest narration, line 1874)

> Note for you (not shown in game): part of: build

- "Detain them with the Arrest Baton (right click) to send them to the cells"  (text, line 1876)

> Note for you (not shown in game): Overwatch: Protocols    Administrator: Agenda

- "Incursion {GetPos}"  (title, line 1892)
- "Go into rebel territory and stay alive inside it for sixty seconds. Expect rebels to fight back."  (description, line 1893)

> Note for you (not shown in game): {

- "Go into the marked rebel territory"  (quest step, line 1896)

> Note for you (not shown in game): part of: build

- "Stay alive inside rebel territory for 60 seconds"  (text, line 1900)
- "Address the citizens"  (title, line 1914)
- "The people need to hear their Administrator. Go to the plaza, speak to the crowd, then choose how to end your speech."  (description, line 1915)
- "Go to the plaza (marked)"  (quest step, line 1917)
- "Stay there for 40 seconds while you give your speech"  (quest step, line 1918)
- "The crowd watches you in silence. How do you end it?"  (quest choice, line 1919)
- "Announce additional rations (starts a ration handout)."  (text, line 1920)
- "Remind them of their duty to the city (starts an inspection sweep)."  (text, line 1924)
- "Declare a curfew, effective immediately (starts a curfew)."  (text, line 1928)
- "Review the Civil Protection units"  (title, line 1944)
- "Check on Civil Protection in person: find units on the street and talk to them."  (description, line 1945)
- "Talk to Civil Protection units: walk up to one and press E"  (quest step, line 1946)

> Note for you (not shown in game): Resistance: Operations

- "Supply run"  (title, line 1962)

> Note for you (not shown in game): part of: build

- "A contact has a crate of medical supplies for you {GetPos}. Bring it to the Resistance's safe spot: {where}."  (description, line 1963)
- "Find your contact (marked) and press E on them to take the crate"  (text, line 1965)
- "'Don't thank me. Don't look back, either.'"  (text, line 1965)
- "The crate is heavier than it should be. There's a Civil Protection unit posted at the end of the street."  (quest choice, line 1966)
- "Walk it out in plain sight."  (text, line 1967)
- "Bury it under a coat and some laundry."  (text, line 1968)

> Note for you (not shown in game): part of: success

- "Nobody looks twice at a tired citizen with laundry."  (quest narration, line 1969)

> Note for you (not shown in game): part of: fail

- "A Civil Protection unit shouts after you. You're wanted now: run!"  (quest narration, line 1971)
- "Carrying contraband"  (text, line 1972)

> Note for you (not shown in game): part of: build

- "Find the quartermaster at the safe spot ({where}) and press E on him to hand over the crate"  (text, line 1975)
- "He's already prying the lid up. 'Good. We needed this yesterday.'"  (text, line 1975)
- "Post flyer %d of 3 %s: crouch at the marked spot for 3 seconds"  (message, line 1988)

> Note for you (not shown in game): part of: on done

- "A Civil Protection unit saw you put that up. You're wanted now."  (quest narration, line 1994)
- "Distributing propaganda"  (text, line 1995)

> Note for you (not shown in game): part of: build

- "Paper the walls"  (title, line 2000)
- "Put up three Resistance flyers in three marked places. If a Civil Protection unit sees you putting one up, you become wanted."  (description, line 2001)
- "Go to the marked checkpoint and crouch there for 5 seconds to plant the charge"  (quest step, line 2013)

> Note for you (not shown in game): part of: on done

- "The checkpoint goes up in a shower of sparks. You're wanted now, and every Civil Protection unit in the sector heard that."  (quest narration, line 2022)

> Note for you (not shown in game): part of: build

- "Sabotage {GetPos}"  (title, line 2025)
- "Blow up the checkpoint to put it out of action for five minutes, then escape to safety."  (description, line 2026)
- "Escape: get to the safe spot ({where})"  (text, line 2027)
- "Jailbreak: {id}"  (title, line 2043)
- "Citizen {id} was arrested last night, and they know too much to stay in a cell. Break them out of prison and lead them to safety."  (description, line 2044)
- "Go to their cell in the prison (marked) and press E on them to break them out"  (text, line 2047)

> Note for you (not shown in game): part of: on done

- "Aiding an escape"  (text, line 2060)
- "The lock gives. You're wanted for this now, and the alarms won't stay quiet for long. Move."  (quest narration, line 2061)

> Note for you (not shown in game): part of: build

- "Lead them to the safe spot ({where}): they follow you"  (text, line 2064)
- "Sound out the neighbors"  (title, line 2077)
- "Find three citizens who might be ready to join the Resistance, and talk to them where no Civil Protection unit can see you."  (description, line 2078)
- "Talk to 3 citizens (walk up and press E) where no Civil Protection unit can see you"  (quest step, line 2079)

> Note for you (not shown in game): count

- "[Operations] A Civil Protection unit can see you, so that didn't count. Move somewhere out of sight."  (chat message, line 2082)

> Note for you (not shown in game): part of: build

- "Dead drop"  (title, line 2097)
- "Meet a contact at the meeting point, then hide a message at the drop for the Resistance to find."  (description, line 2098)
- "Go to the marked meeting point {GetPos}"  (quest step, line 2100)
- "Wait at the meeting point for 20 seconds for your contact"  (quest step, line 2101)
- "Your contact doesn't come. Instead, a child walks past and presses a folded note into your hand."  (quest choice, line 2102)
- "Read it."  (text, line 2103)
- "Burn it unread."  (text, line 2104)

> Note for you (not shown in game): part of: pick

- "Some things are safer not known."  (quest narration, line 2104)

> Note for you (not shown in game): part of: build

- "Take the message to the marked drop {GetPos}"  (text, line 2106)
- "Go to the marked drop {GetPos} to leave the message"  (quest step, line 2107)
- "Hide the message: press E on one of the three marked hiding places, then crouch and keep still. If anyone sees you doing it, that hiding place is ruined."  (text, line 2108)
- "the drop {from}"  (name, line 2127)
- "Smuggling run"  (title, line 2130)
- "Take the Resistance cell's cargo (guns and ammunition) to three drops around the city. If a Civil Protection unit searches you, they'll find it."  (description, line 2131)
- "Go to the quartermaster (marked) to collect the cargo"  (text, line 2133)
- "Go to the marked spot to collect the cargo"  (text, line 2133)
- "Deliver the cargo to the three marked drops before time runs out. Crouch to sneak past Civil Protection units, or stand still for their search and hope for the best"  (text, line 2134)
- "the civil records terminal"  (text, line 2152)
- "the Combine console"  (text, line 2152)
- "a records terminal"  (text, line 2154)

> Note for you (not shown in game): one of ours with a record (or whoever did it, if nobody else has one)

- "[Operations] A Resistance member wiped your record from the Combine's terminals: you're no longer wanted."  (chat message, line 2166)

> Note for you (not shown in game): part of: wipe

- "[Operations] You wiped {Nick}'s record: they're no longer wanted."  (chat message, line 2167)
- "[Operations] Nobody of ours was wanted, so you wiped three names from the registers instead. The scanner never noticed."  (chat message, line 2169)

> Note for you (not shown in game): part of: build

- "Doctor the records"  (title, line 2173)
- "Some of ours are wanted by the Combine. Hack into {what} {GetPos} and wipe a wanted Resistance member's record."  (description, line 2174)
- "Go to {what} {GetPos} (marked)"  (text, line 2176)
- "Hack the terminal: stop the moving needle inside the band (click or space) four times. When the scanner passes over, stop touching the panel"  (text, line 2177)
- "Ambush a patrol"  (title, line 2188)
- "For fighters only. Kill two Civil Protection units, then get away."  (description, line 2189)
- "Kill 2 Civil Protection units"  (quest step, line 2190)
- "Someone on a Civil Protection wanted list is hiding {GetPos}. Find them and lead them to safety."  (description, line 2207)
- "Find the fugitive (marked on your screen)"  (text, line 2210)
- "Lead them to the safe spot ({safe}): they follow you"  (text, line 2220)
- "The ministry"  (title, line 2232)
- "Tend to your flock: comfort a grieving woman, heal three wounded people with The Blessing, and preach once. The Combine call it unlawful worship. You call it Sunday."  (description, line 2233)
- "A woman catches your sleeve. Her husband was taken last night. She asks you to pray with her, here, in the open."  (quest choice, line 2235)
- "Pray with her where she stands (if a Civil Protection unit sees, you become wanted)."  (text, line 2236)

> Note for you (not shown in game): part of: pick

- "You finish the prayer. Then you hear the boots: a Civil Protection unit saw you, and you're wanted now."  (quest narration, line 2240)
- "Unlawful worship"  (text, line 2241)
- "She holds your hand through all of it. Nobody comes."  (quest narration, line 2243)

> Note for you (not shown in game): part of: build

- "Promise to pray for him tonight, somewhere safe."  (text, line 2246)

> Note for you (not shown in game): part of: success

- "She nods. It's enough. For now it's enough."  (quest narration, line 2247)

> Note for you (not shown in game): part of: fail

- "She lets go of your sleeve and doesn't look back."  (quest narration, line 2248)

> Note for you (not shown in game): part of: build

- "Heal 3 different wounded people with The Blessing (left click)"  (quest step, line 2250)
- "Preach the Word: hold The Blessing and press reload where people can hear"  (quest step, line 2251)

> Note for you (not shown in game): Citizens: Assignments

- "Collect your ration"  (title, line 2268)

> Note for you (not shown in game): part of: build

- "Your ration is ready. Go to ration line {g} and wait at the front to collect it."  (description, line 2269)
- "Go to ration line {g} (marked)"  (quest step, line 2270)
- "Stand at the front of the line for 10 seconds"  (quest step, line 2270)
- "Union work order: sanitation"  (title, line 2281)
- "Pick up four pieces of litter {GetPos}. A clean city is a compliant city."  (description, line 2282)
- "Pick up the litter: press E on each marked piece"  (text, line 2284)
- "Find her cousin {GetPos} (marked) and press E on them to hand over the parcel"  (text, line 2310)
- "'From Kleiner? Tell her I'm fine.' It's not true, and you both know it."  (text, line 2311)
- "A neighbor's errand"  (title, line 2313)
- "Mrs. Kleiner from the third floor needs a parcel carried across the district. Collect it from her inside the housing block, then deliver it to her cousin."  (description, line 2314)
- "Mrs. Kleiner from the third floor needs a parcel carried across the district. Collect it from her, then deliver it to her cousin."  (description, line 2315)
- "Find Mrs. Kleiner inside the housing block (marked) and press E on her"  (text, line 2317)
- "Find Mrs. Kleiner (marked) and press E on her"  (text, line 2317)
- "'It's only a little parcel. It's gone to the third floor and back already.' She presses it into your hands."  (text, line 2318)
- "The parcel is taped shut. It's light, and something inside slides when you tilt it."  (quest choice, line 2319)
- "Deliver it unopened."  (text, line 2320)
- "Peel back the tape and look."  (text, line 2321)

> Note for you (not shown in game): part of: success

- "Resistance pamphlets. Your hands are suddenly cold."  (quest choice, line 2323)
- "Deliver it anyway."  (text, line 2324)
- "Hand it to Civil Protection instead."  (text, line 2325)

> Note for you (not shown in game): part of: pick

- "Hand the parcel to a Civil Protection unit: walk up to one and press E"  (quest step, line 2328)

> Note for you (not shown in game): part of: fail

- "The tape tears loudly. Better just deliver it, and fast."  (quest narration, line 2332)

> Note for you (not shown in game): part of: build

- "the dumpster"  (text, line 2359)
- "the bins"  (text, line 2359)
- "Two people swap a bundle behind {noun}. One has a lambda scratched into his sleeve."  (text, line 2360)
- "Walk over to {noun} (marked), casually"  (quest step, line 2361)
- "Something you saw"  (title, line 2411)
- "Neighbors whisper about something going on behind {or}{GetPos}. Go and see what it is."  (description, line 2412)
- "Stay nearby and watch quietly for 6 seconds"  (quest step, line 2415)
- "Report it to a Civil Protection unit."  (text, line 2417)

> Note for you (not shown in game): part of: pick

- "Tell a Civil Protection unit: walk up to one and press E"  (quest step, line 2420)

> Note for you (not shown in game): part of: build

- "Keep it to yourself (ends the job, little XP)."  (text, line 2422)

> Note for you (not shown in game): part of: pick

- "You saw nothing. You'll keep seeing nothing."  (quest narration, line 2426)

> Note for you (not shown in game): part of: build

- "his doorway"  (text, line 2448)
- "The confused old man"  (title, line 2451)
- "An old man is wandering {GetPos}, asking everyone for directions. Find him and walk him home."  (description, line 2452)
- "Find the old man (marked on your screen)"  (text, line 2455)
- "He doesn't remember his block number. He keeps asking for his daughter."  (quest choice, line 2467)
- "Calm him down first."  (text, line 2468)

> Note for you (not shown in game): part of: success

- "He takes your arm. His hand is light as paper."  (quest narration, line 2469)

> Note for you (not shown in game): part of: fail

- "He shuffles after you anyway, still asking."  (quest narration, line 2470)

> Note for you (not shown in game): part of: build

- "Just lead the way."  (text, line 2471)
- "Walk him home to {homeName}. He follows you, slowly."  (text, line 2473)
- "Loyalty check"  (title, line 2486)
- "You've been summoned for a routine loyalty check. Go to the checkpoint and present yourself to a Civil Protection officer."  (description, line 2487)
- "Go to the marked checkpoint"  (quest step, line 2489)
- "Present yourself to a Civil Protection officer: walk up to one and press E"  (quest step, line 2490)
- "The officer's mask tilts. Where were you last night, citizen?"  (quest choice, line 2491)
- "Tell the truth."  (text, line 2492)
- "Give a smooth, boring alibi."  (text, line 2493)

> Note for you (not shown in game): part of: success

- "He waves you through. Boring is safe."  (quest narration, line 2494)

> Note for you (not shown in game): part of: fail

- "He doesn't buy it. You're wanted now for failing a loyalty check."  (quest narration, line 2496)
- "Failing a loyalty check"  (text, line 2497)

> Note for you (not shown in game): The Infested: Urges

- "Kill 2 citizens"  (quest step, line 2516)

> Note for you (not shown in game): part of: build

- "Get close to 4 different citizens (they'll run from you)"  (quest step, line 2528)
- "Scare the living: get close to four different citizens."  (description, line 2541)
- "Leave the infested zones and survive outside them for two minutes."  (description, line 2551)
- "Stay alive outside the infested zones for 2 minutes"  (text, line 2552)

> Note for you (not shown in game): part of: advance chain

- "[Story] You turned down {name}. It comes back to your board (F3) in about 30 minutes."  (chat message, line 2653)
- "[Story] {name} has ended. {ending}"  (chat message, line 2657)
- "Story %s ended for %s: %s"  (message, line 2658)
- "[Story] {name} continues.{or}"  (chat message, line 2665)
- "[Story] {name} has ended."  (chat message, line 2668)
- "[Story] {name}: that part failed. You can try it again: it comes back to your board (F3)."  (chat message, line 2673)

> Note for you (not shown in game): part of: check unlocks

- "[Story] A new story is available. Check your job board (F3)."  (chat message, line 2688)

> Note for you (not shown in game): part of: build

- "Housing block inspection: {name}"  (title, line 2833)
- "The raid team is searching {name}. Back them up: inspect the residents, then guard the block until the search is done."  (description, line 2834)
- "Go to {name} (marked)"  (text, line 2836)
- "Breach and search: press E on the locked door to set the charge and stand back, press E on each resident to put them on the floor, then press E on the furniture to search it"  (text, line 2837)
- "Go to {name} (marked)"  (quest step, line 2839)
- "Inspect 3 residents of {name}: walk up to each one and press E"  (text, line 2841)
- "Stay at the block for 45 seconds while the team finishes the search"  (quest step, line 2846)
- "Dispatch: all units, {name} is under inspection. Nobody leaves without papers."  (text, line 2848)
- "Clear the streets: go to stop %d of %d, %s"  (message, line 2860)
- "Stay on this street for 60 seconds. Anyone still outside gets three warnings before they become wanted"  (quest step, line 2861)
- "Curfew enforcement"  (title, line 2863)
- "Curfew is in effect. Walk to each marked stop, moving people along as you go, then stay at the last stop for 60 seconds."  (description, line 2864)
- "Lockdown: hold the perimeter {GetPos}"  (title, line 2877)
- "Lockdown is in effect. Go to your post and guard it for 90 seconds, or until the lockdown lifts. Nobody moves through your sector."  (description, line 2878)
- "Go to your marked post"  (quest step, line 2879)
- "Stay at your post for 90 seconds"  (quest step, line 2879)
- "Warn {name}"  (title, line 2892)
- "Civil Protection units are about to search {name}. Get there first and warn three residents to move what they're hiding."  (description, line 2893)
- "Get to {name} (marked) before the Civil Protection units do"  (quest step, line 2895)
- "Warn 3 residents: walk up to each one and press E"  (text, line 2897)
- "Run supplies under curfew"  (title, line 2930)
- "The streets are empty and the Civil Protection units are busy. A contact left a crate {GetPos}. Pick it up and bring it to the safe spot: {toName}."  (description, line 2931)
- "Find the crate (marked) and press E to pick it up"  (text, line 2934)
- "Bring it to the safe spot ({toName})"  (text, line 2935)

> Note for you (not shown in game): part of: post directive

- "[%s] New job: %s. Take it from your job board (F3). Up to %d people can work on it together."  (message, line 3072)

> Note for you (not shown in game): whoever got stuck in gets paid; whoever hadn't started hasn't failed; a count left short (residents warned, people stopped) wasn't done

- "the event ended with only %d of %d done"  (message, line 3102)
- "The event is over. Good work: the job counts as done."  (quest narration, line 3104)

> Note for you (not shown in game): the game's living city event ended moment

- "the event ended before you got started, so it doesn't count against you"  (text, line 3107)

> Note for you (not shown in game): part of: send board

- "[Living City] Quests are turned off on this server."  (chat message, line 3126)

> Note for you (not shown in game): part of: accept posting

- "[Living City] Finish or abandon your current job first."  (chat message, line 3167)
- "[Living City] You have to wait before taking another job. Next job in {CurTime}s."  (chat message, line 3169)
- "[Living City] That job is no longer available."  (chat message, line 3178)
- "[Living City] Stalkers can only do stalker work. You can't take this job."  (chat message, line 3181)
- "[Living City] That job has enough people."  (chat message, line 3188)
- "has joined the job."  (quest narration, line 3191)
- "[{board}] {title}. {or}"  (chat message, line 3213)
- "Quest accepted: %s [%s] by %s"  (message, line 3215)

> Note for you (not shown in game): part of: abandon quest

- "left the job."  (quest narration, line 3229)

> Note for you (not shown in game): part of: resolve choice

- "%s check: rolled %d + %d skill = %d, needed %d. %s"  (message, line 3247)

> Note for you (not shown in game): the console command lcq_startchain

- "[Story] Chains: {ids}. Usage: lcq_startchain <chain> [player]"  (text, line 3299)
- "[Story] Player not found."  (text, line 3301)
- "[Story] {name} is ready on {Nick}'s board (F3)."  (text, line 3306)

> Note for you (not shown in game): the console command lcq_story

- "[Story] Player not found."  (text, line 3313)
- "[Story] %s: loyalty %d, sympathy %d, corruption %d"  (message, line 3315)
- "counters: {or}"  (text, line 3319)
- "ended ({done})"  (text, line 3321)
- "at {part}"  (text, line 3321)

> Note for you (not shown in game): the console command lcq_resetstory

- "[Story] Your story has been reset."  (chat message, line 3333)

## habitation block raids (sv_livingcity_raids.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_raids.lua`


> Note for you (not shown in game): Charge someone with what was found under their name.

- "in {block}"  (text, line 98)
- "Weapons and contraband cache"  (text, line 99)
- "Possession of contraband"  (text, line 99)
- "[Civil Protection] %d contraband item%s found%s under your name. You are wanted."  (message, line 100)
- "Contraband found in your block"  (text, line 101)

> Note for you (not shown in game): part of: scan

- "[Civil Protection] Block inspection. Stand still and cooperate."  (chat message, line 234)

> Note for you (not shown in game): part of: finish

- "[Civil Protection] Block inspection complete. %d item%s confiscated."  (message, line 292)
- "[Civil Protection] Block inspection complete. Carry on."  (chat message, line 293)
- "Raid on block %d finished: %d item(s) found"  (message, line 296)

> Note for you (not shown in game): Pick the block: one with people in it first, else any.

- "A raid is already in progress."  (text, line 303)
- "This map has no housing blocks."  (text, line 305)

> Note for you (not shown in game): part of: start raid

- "No such block."  (text, line 317)
- "No Civil Protection units could get to {block}."  (text, line 324)
- "Raid on block %d: %d unit(s) sent"  (message, line 326)
- "[Civil Protection] Inspection of {block} is under way. Stay in your residence."  (chat message, line 329)

## "ration units are being deducted" (sv_livingcity_rations.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rations.lua`


> Note for you (not shown in game): part of: dock rations

- "[Rations] You were near {why}{or}. Your next ration allocation is forfeit."  (chat message, line 40)
- "Residents near {why}{or} lose their next ration allocation."  (text, line 47)

> Note for you (not shown in game): a timer (regularly)

- "a Resistance attack"  (text, line 55)

> Note for you (not shown in game): part of: found

- "Resistance graffiti"  (text, line 84)

> Note for you (not shown in game): the game's living city territory grew moment

- "Resistance-held ground"  (text, line 102)

## rebel life (sv_livingcity_rebellife.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rebellife.lua`


> Note for you (not shown in game): part of: patrol

- "on patrol"  (what someone is doing, line 592)
- "on patrol"  (what someone is doing, line 596)

> Note for you (not shown in game): At a workbench or the camp table.

- "cleaning a gun"  (text, line 603)
- "going over a map"  (text, line 603)
- "fixing something"  (text, line 603)
- "working at the bench"  (text, line 603)
- "fixing a gun"  (text, line 603)
- "making something"  (text, line 603)

> Note for you (not shown in game): Going through a crate.

- "going through the crates"  (text, line 611)
- "checking the supplies"  (text, line 611)
- "counting rounds"  (text, line 611)

> Note for you (not shown in game): Tending a pot.

- "tending the garden"  (what someone is doing, line 619)

> Note for you (not shown in game): part of: carry

- "fetching supplies"  (what someone is doing, line 633)
- "carrying supplies"  (text, line 638)
- "putting it down"  (what someone is doing, line 638)

> Note for you (not shown in game): part of: fire

- "warming up by the fire"  (what someone is doing, line 657)

> Note for you (not shown in game): On a chair, a couch, a bench.

- "taking a break"  (text, line 673)
- "sitting down"  (text, line 673)

> Note for you (not shown in game): The editor's sit, bench and lean points inside the zone.

- "leaning on the wall"  (what someone is doing, line 687)

> Note for you (not shown in game): Sleeping on a mattress, a bed, a bunk.

- "turning in"  (text, line 702)

> Note for you (not shown in game): the zone's on alert: on their feet, facing the trouble

- "on alert"  (text, line 793)

> Note for you (not shown in game): part of: start errand

- "fewer than three fighters at home"  (text, line 895)
- "nowhere to scavenge"  (text, line 897)
- "out scavenging"  (text, line 909)
- "Rebel scavenging run: %d out of %s toward %s"  (message, line 911)

> Note for you (not shown in game): part of: deliver

- "%s is back from a scavenging run: %d meal%s for the stores."  (message, line 944)

> Note for you (not shown in game): part of: rebel errand think

- "keeping out of sight"  (text, line 973)
- "out scavenging"  (text, line 988)

> Note for you (not shown in game): home, with whatever they found

- "bringing back what they found"  (text, line 1024)
- "heading home"  (text, line 1024)

> Note for you (not shown in game): the console command lc_rebel_errand

- "[Living City] Start the city first."  (chat message, line 1070)
- "[Living City] No rebel territory on this map."  (chat message, line 1077)
- "[Living City] A scavenging run is heading out of the nearest rebel zone."  (chat message, line 1079)
- "[Living City] Couldn't send one: {why}"  (text, line 1079)

## the Resistance on the street (sv_livingcity_rebels.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rebels.lua`


> Note for you (not shown in game): still shouting

- "[Resistance] Someone shouts: 'Combine! In the yard!' You've been seen."  (chat message, line 433)

> Note for you (not shown in game): sent ahead to meet the leader at the job's destination: there, loitering, till the leader turns up

- "[Resistance] {GetNW2String} falls in with you."  (chat message, line 590)

> Note for you (not shown in game): under fire: guns out, all of them

- "[Resistance] Your squad pull their guns out."  (chat message, line 614)

> Note for you (not shown in game): Units get something for it.

- "anticitizen neutralized"  (text, line 965)

> Note for you (not shown in game): part of: units spot rebels

- "Dispatch: armed anticitizen {or}. Civil Protection units engaging."  (text, line 1009)

> Note for you (not shown in game): purpose: nil for a plain raid on a checkpoint; or an operation with an objective at the target ("heist", "breakout", "ambush", "screen"), worked out in sv_livingcity_resistanceops.lua

- "no rebel territory on this map"  (text, line 1072)
- "nothing of the Combine's to hit"  (text, line 1074)

> Note for you (not shown in game): part of: start raid

- "no fighters"  (text, line 1092)
- "in the city"  (text, line 1104)
- "Our people are hitting the Combine {where}. Stay clear, or lend a hand."  (text, line 1105)

> Note for you (not shown in game): dispatch hears about it once they're close

- "Skirmish: rebel raid of %d from %s toward %s"  (message, line 1110)

> Note for you (not shown in game): part of: plan raid

- "in the city"  (text, line 1125)
- "In about {lead} seconds our people hit the Combine {where}. Anyone who can, back them up."  (text, line 1126)
- "A raid is coming"  (on-screen notice, line 1129)
- "Our fighters hit the Combine {where} in about {lead} seconds. Back them up: the job's on your board (F3)."  (on-screen notice, line 1129)

> Note for you (not shown in game): part of: start rebel raid

- "a skirmish is already on"  (text, line 1138)

> Note for you (not shown in game): part of: sweep chore

- "smashing the pots"  (text, line 1196)
- "confiscating supplies"  (text, line 1196)

> Note for you (not shown in game): part of: start sweep

- "no rebel territory on this map"  (text, line 1220)
- "no Civil Protection units"  (text, line 1221)
- "nowhere out of sight to gather a team"  (text, line 1223)
- "no Civil Protection units"  (text, line 1240)
- "rebel territory"  (text, line 1242)
- "Dispatch: sweep team moving into anticitizen territory {where}. Civil Protection units may assist."  (text, line 1243)
- "Combine are moving on our people {where}! Everyone who can fight, get there."  (text, line 1244)
- "Skirmish: Combine sweep of %d into %s"  (message, line 1245)

> Note for you (not shown in game): part of: plan sweep

- "rebel territory"  (text, line 1265)
- "Dispatch: sweep team moves into anticitizen territory {where} in about {secs} seconds. All available Civil Protection units, assist."  (text, line 1267)
- "A sweep is coming"  (on-screen notice, line 1270)
- "A sweep team moves into anticitizen territory {where} in about {secs} seconds. Join it: the job's on your board (F3)."  (on-screen notice, line 1270)

> Note for you (not shown in game): part of: end skirmish

- "Dispatch: anticitizen incursion {where} is over. Resume your beats."  (text, line 1321)
- "Dispatch: sweep team withdrawing."  (text, line 1323)
- "Civil Protection units down"  (text, line 1324)
- "They're pulling back. We held."  (text, line 1324)
- "The Combine have pulled back."  (text, line 1324)

> Note for you (not shown in game): part of: run skirmish

- "raiders down"  (text, line 1337)

> Note for you (not shown in game): once they're close, dispatch notices and the nearest units respond

- "Armed Resistance fighters are attacking {or}. Civil Protection units nearby are fighting them; anyone else, keep clear."  (text, line 1345)
- "Dispatch: armed anticitizens {or}. All nearby Civil Protection units respond."  (text, line 1346)

> Note for you (not shown in game): part of: run skirmish

- "Civil Protection units down"  (text, line 1385)
- "territory cleared"  (text, line 1386)

> Note for you (not shown in game): there: at the edge of their ground, or already fighting them

- "never got there"  (text, line 1435)

> Note for you (not shown in game): the console command lc_skirmish

- "[Living City] Start the city first."  (chat message, line 1493)
- "called off"  (text, line 1494)
- "[Living City] Skirmish called off."  (chat message, line 1499)
- "[Living City] Usage: lc_skirmish raid\|sweep\|end"  (chat message, line 1500)
- "[Living City] {kind} started."  (text, line 1501)
- "[Living City] Couldn't start a {kind}: {why}"  (text, line 1501)

> Note for you (not shown in game): part of: dismiss follower

- "[Resistance] '{GetNW2String}. I'll head back.'"  (chat message, line 1540)

> Note for you (not shown in game): part of: recruit

- "[Resistance] 'I'm on watch. Find someone else.'"  (chat message, line 1549)
- "[Resistance] They're busy."  (chat message, line 1549)
- "[Resistance] 'Who are you? Get someone who's earned it to ask me.' (Members and up can lead fighters.)"  (chat message, line 1553)
- "[Resistance] You've got {MAX_FOLLOWERS} with you already. Any more and you're a parade."  (chat message, line 1557)
- "[Resistance] {GetNW2String} is with you, and stays with you. They hold their fire until you open up or the Combine do. E on them again to send them home."  (chat message, line 1573)

> Note for you (not shown in game): pressing E on something

- "[Resistance] The quartermaster looks you over. 'I don't know you. Come back with someone who does.'"  (chat message, line 1619)
- "[Quartermaster] 'What do you need?' (Work: F3. Fighters: E on any of ours here, to bring them along.)"  (chat message, line 1625)
- "[Quartermaster] 'Is that a Combine chip? Don't wave it about. Take it to the lab, the doc will decode it.'"  (chat message, line 1627)

> Note for you (not shown in game): Orders for the squad (F1 / the C menu, Resistance; or the chat shortcuts !casual, !gunsout, !meet).

- "[Resistance] You've nobody with you."  (chat message, line 1640)
- "[Resistance] Guns away, plain clothes on. They walk like anyone else now. (Shot at, they'll fight.)"  (text, line 1640)
- "[Resistance] They're acting casual already."  (text, line 1640)
- "[Resistance] You've nobody with you."  (chat message, line 1644)
- "[Resistance] Guns out."  (text, line 1644)
- "[Resistance] They're armed and ready already."  (text, line 1644)

> Note for you (not shown in game): the chat command /meet

- "[Resistance] You've nobody with you."  (chat message, line 1648)
- "[Resistance] Meet you where? Take a job first: they go on ahead to where it's taking you."  (chat message, line 1650)
- "[Resistance] 'We'll meet you there.' They go on ahead, acting casual, and wait for you near the job's marker."  (chat message, line 1660)

> Note for you (not shown in game): What a lookout sees coming: warn (a shout, and Freq 7) when the Combine is in sight on the way; open fire when they're close, or on our ground.

- "at a lookout post"  (text, line 1700)

> Note for you (not shown in game): part of: post warn

- "%s on lookout %s: Combine coming%s!"  (message, line 1702)
- ", the city's own"  (message, line 1703)
- "[Resistance] Someone shouts from up ahead: 'Combine! Coming in!' You've been seen."  (chat message, line 1705)

> Note for you (not shown in game): an NPC dying

- "We lost the lookout {or}. Someone will take the post, give it time."  (text, line 1791)
- "They got the quartermaster. Someone will take his place, give it time."  (text, line 1840)

## the Resistance's operations, and what the city does about them (sv_livingcity_resistanceops.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_resistanceops.lua`


> Note for you (not shown in game): part of: hack door

- "You need a multitool for that. (The Resistance's Hackers carry one; the black market sells them.)"  (text, line 103)
- "You're busy."  (text, line 105)
- "Look at a locked Combine door, up close."  (text, line 109)
- "Hacking the lock... keep at it"  (progress bar, line 112)
- "You pull the wires out. It stays shut."  (text, line 113)

> Note for you (not shown in game): part of: done

- "[Resistance] The lock gives. Thirty seconds before it shuts again."  (chat message, line 118)
- "[CP net] Door breach {GetPos}. A Combine lock has been tampered with."  (text, line 120)
- "Tampering with a Combine lock"  (text, line 123)

> Note for you (not shown in game): Prison breaks

- "[Resistance] The cell door slams open. "Move. Now." You're out, and wanted."  (chat message, line 167)
- "is out. Get them home."  (text, line 169)
- "prison break"  (text, line 170)

> Note for you (not shown in game): part of: prison break alarm

- "[CP net] PRISON BREAK {pos}. Anticitizens are at the cells. All Civil Protection units respond."  (text, line 176)

> Note for you (not shown in game): Smugglers on a supply run

- "[CP net] Union supplies stolen. The smuggler's on the move: follow the SMUGGLER marker."  (text, line 199)

> Note for you (not shown in game): Arrested or killed with the crate: stopped.

- "[CP net] The smuggler is down. Supplies recovered."  (text, line 220)

> Note for you (not shown in game): part of: inform

- "You're a Civil Protection unit: arrest them."  (text, line 242)
- "Inform on your own? No."  (text, line 243)
- "Look at who you want to report (or !inform <name>)."  (text, line 244)
- "Civil Protection has your last report. (%ds)"  (message, line 245)

> Note for you (not shown in game): seen doing it? A Resistance member who watches you talk to the Combine remembers.

- "saw {Nick} informing to the Combine. Traitor."  (text, line 255)

> Note for you (not shown in game): part of: inform

- "citizen {GetNW2String}"  (text, line 262)
- "[CP net] Informant tip: {who} is a suspected anticitizen, {GetPos}. Outlined for 60 seconds."  (text, line 263)
- "Informant tip: suspected anticitizen"  (text, line 266)
- "informant's reward"  (text, line 267)
- "useful information"  (text, line 268)
- "[Civil Protection] Your report has been received. The Union thanks you."  (chat message, line 269)
- "a false report"  (text, line 271)
- "[Civil Protection] Your report was checked. It was false. Don't waste our time."  (chat message, line 272)

> Note for you (not shown in game): Hijacking a city screen

- "Citizens of City 17. They count your rations, your words, your children. Count theirs."  (text, line 283)
- "The Combine are not invincible. Every Civil Protection unit you see is a man in a mask. Remember that."  (text, line 284)
- "Lambda lives. Help is closer than you think."  (text, line 285)
- "Their cameras are blind tonight. Look out for one another."  (text, line 286)

> Note for you (not shown in game): part of: hijack start

- "[CP net] A city screen {where} has been hijacked. Get there and cut it (E on the screen)."  (text, line 295)

> Note for you (not shown in game): a timer (regularly)

- "[Broadcast interrupted] {i}"  (chat message, line 302)
- "Resistance broadcast"  (text, line 310)
- "[City] The Resistance's message ran for a full minute. People are talking."  (chat message, line 312)
- "screen hijack"  (text, line 313)

> Note for you (not shown in game): part of: hijack screen

- "You need a multitool to wire into it."  (text, line 321)
- "Look at a city screen."  (text, line 322)
- "It's already ours."  (text, line 323)
- "You're busy."  (text, line 324)
- "Wiring into the screen... keep at it"  (progress bar, line 325)
- "You pull the wires. The screen goes back to the Combine."  (text, line 326)

> Note for you (not shown in game): part of: done

- "[Resistance] You're in. One minute: keep Civil Protection units off it."  (chat message, line 329)

> Note for you (not shown in game): part of: cut hijack

- "hijacked screen cut"  (text, line 340)
- "[CP net] The hijacked screen is back under control."  (text, line 341)
- "[Resistance] They cut the broadcast."  (chat message, line 342)

> Note for you (not shown in game): Overwatch drops

- "a drop is already down"  (text, line 369)

> Note for you (not shown in game): part of: start overwatch drop

- "nowhere to land"  (text, line 374)
- "[CP net] Overwatch reinforcements inbound {where}. Secure the landing zone."  (text, line 378)
- "Dropship inbound {where}. Overwatch soldiers. Hit them on the ground, or keep clear."  (text, line 380)
- "Overwatch soldiers are landing {where}."  (text, line 381)

> Note for you (not shown in game): on foot, from out of sight, at a run

- "No dropship: they're coming in on foot {where}."  (text, line 436)

> Note for you (not shown in game): The Overwatch Commander calls a squad in: to the landing zone nearest them (or where they stand), one every fifteen minutes.

- "Only the Overwatch Commander can call in a squad."  (text, line 459)
- "The next squad can be called in %d:%02d."  (message, line 463)

> Note for you (not shown in game): part of: commander drop

- "A squad is already down."  (text, line 465)
- "The dropship can't come: {d}."  (text, line 471)

> Note for you (not shown in game): the chat command /dropship

- "Squad inbound"  (on-screen notice, line 480)
- "A dropship is on its way with an Overwatch squad. Secure the landing zone."  (on-screen notice, line 480)
- "No squad"  (on-screen notice, line 482)

> Note for you (not shown in game): part of: drop tick

- "The landing party is down. Good work."  (text, line 493)
- "[CP net] The Overwatch landing party is lost."  (text, line 494)

> Note for you (not shown in game): part of: achieve

- "Our fighters got into the Combine's systems: Civil Protection unit positions for everyone, five minutes. Move."  (text, line 526)
- "[CP net] Data stolen from a Combine terminal {target}."  (text, line 527)
- "Our fighters hit the landing zone."  (text, line 533)

> Note for you (not shown in game): and food for the stores at home

- "Our fighters got into the supply drop: %d load%s gone, and food for the stores."  (message, line 544)
- "Our fighters hit the supply drop. Cleaned out already."  (text, line 545)
- "[CP net] Anticitizens looted the supply drop {target}."  (text, line 546)

> Note for you (not shown in game): part of: op tick

- "[CP net] DATA BREACH {target}. Armed anticitizens at a Combine terminal."  (text, line 565)

> Note for you (not shown in game): part of: launch op

- "a Combine data terminal"  (text, line 592)
- "the prison"  (text, line 592)
- "a city screen"  (text, line 592)
- "the landing zone"  (text, line 592)
- "the supply drop"  (text, line 592)
- "Our fighters are going for {or} {target}. Lend a hand."  (text, line 593)

> Note for you (not shown in game): Union foremen

- "Foremen are citizens."  (text, line 656)
- "The Union only makes Trusted citizens foremen (150 Civil Standing)."  (text, line 657)

> Note for you (not shown in game): part of: become foreman

- "[Union] You're a foreman now. !assign <name> hands a citizen a work order; you take a cut of their pay."  (text, line 660)
- "[Union] You hand back your foreman's armband."  (text, line 660)

> Note for you (not shown in game): part of: assign work

- "You're not a foreman (!foreman)."  (text, line 664)
- "Assign it to another citizen."  (text, line 665)
- "is already working."  (text, line 666)
- "No work orders to hand out."  (text, line 673)
- "Nothing to send them to right now."  (text, line 675)
- "(from foreman {Nick})"  (title, line 678)
- "can't take it right now."  (text, line 682)
- "[Union] Foreman {Nick} has given you a work order: {title}. It's on your board (F3)."  (chat message, line 685)
- "[Union] Work order handed to {Nick}."  (text, line 686)

> Note for you (not shown in game): the game's living city quest complete moment

- "foreman's cut"  (text, line 692)

> Note for you (not shown in game): part of: settle vort

- "The vortigaunt is home. Ask it (E) and it will charge your vest."  (text, line 713)

> Note for you (not shown in game): Why one didn't come (for the debug report).

- "no rebel zones drawn"  (text, line 749)

> Note for you (not shown in game): part of: free street vort

- "[Living City] The collar falls. The vortigaunt looks at you a long moment, then heads for rebel ground."  (chat message, line 810)
- "freeing a vortigaunt"  (text, line 811)
- "A vortigaunt has been freed from the street crews. It's on its way to us. Welcome it."  (text, line 813)

> Note for you (not shown in game): A freed vortigaunt charges your vest when you ask it (E), not by itself (not while you sleep beside it): once every lc_vort_charge_minutes.

- "The vortigaunt looks at you, and through you."  (text, line 841)
- ""You wear no vessel for the vortessence, friend." (You've no powered vest on.)"  (text, line 842)
- ""Your vessel is full." (Your vest is fully charged.)"  (text, line 843)

> Note for you (not shown in game): part of: vort charge

- ""The vortessence needs time to gather." (%d min)"  (message, line 846)
- "The vortigaunt's hands glow green, and your vest hums with charge."  (text, line 851)

> Note for you (not shown in game): pressing E on something

- "[Vortigaunt] {msg}"  (chat message, line 859)

## escalation (sv_livingcity_response.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_response.lua`

- "Sector-wide search"  (text, line 32)
- "Overwatch response"  (text, line 32)

> Note for you (not shown in game): part of: dispatch squad

- "Overwatch squad of %d dispatched after %s"  (message, line 135)

> Note for you (not shown in game): part of: escalate

- "Alert {level}"  (text, line 142)

> Note for you (not shown in game): every unit in the sector, guns drawn

- "[Overwatch] Alert 2: every Civil Protection unit in the sector has your description. They've drawn their weapons."  (chat message, line 151)
- "Dispatch: all units, suspect {Nick} is armed and dangerous. Weapons free."  (text, line 152)

> Note for you (not shown in game): part of: escalate

- "[Overwatch] Alert 3: Overwatch has been dispatched. Lethal force is authorized."  (chat message, line 154)
- "Overwatch soldiers have been sent after {Nick}, who is armed and dangerous. Lethal force is authorized. Keep clear."  (text, line 156)
- "[Overwatch] Alert 4: a second squad, and the sector is locked down."  (chat message, line 160)

> Note for you (not shown in game): part of: demote for civilian kill

- "[Resistance] You killed one of the people you fight for."  (chat message, line 231)
- "killed a civilian"  (text, line 232)

> Note for you (not shown in game): an NPC dying

- "Murder of a Civil Protection officer"  (text, line 250)
- "killed a Civil Protection unit"  (text, line 251)
- "Murder of an Overwatch soldier"  (text, line 254)
- "killed a soldier"  (text, line 255)
- "Destroying city property"  (text, line 257)
- "destroyed a scanner"  (text, line 258)
- "killed a citizen"  (text, line 262)

> Note for you (not shown in game): lying low; rebel territory cools you off twice as fast

- "[Overwatch] The search for you has been called off."  (chat message, line 299)
- "[Overwatch] The search is winding down. Alert {AlertLevel}."  (chat message, line 300)

> Note for you (not shown in game): pcall

- "a response squad going back"  (text, line 319)

> Note for you (not shown in game): the console command lc_setalert

- "set by staff"  (text, line 337)

> Note for you (not shown in game): the game's living city data breach moment

- "master terminal breach"  (text, line 417)
- "data breach"  (text, line 417)

## sleep (sv_livingcity_rest.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rest.lua`


> Note for you (not shown in game): Sleep in a bed. True, or false and why not. You lie still (you can't move) till you press Jump.

- "There's no bed here."  (text, line 124)
- "Someone's already asleep in this bed."  (text, line 126)
- "You're not tired, and it's broad daylight. Beds are for the night (or when you're exhausted)."  (text, line 127)

> Note for you (not shown in game): part of: sleep in

- "You slept already. You couldn't sleep again if you tried."  (text, line 128)

> Note for you (not shown in game): off the bed: back where they stood to get in, if nobody's standing there now

- "You wake with a start. You've not slept."  (chat message, line 170)
- "You get up before you've really slept."  (chat message, line 170)

> Note for you (not shown in game): part of: sleep step

- "Well rested"  (on-screen notice, line 198)
- "A night's sleep, and you're healed. For the next day: hunger and thirst come on more slowly, and you heal a little. Press Jump to get up."  (on-screen notice, line 198)

> Note for you (not shown in game): part of: rest tick

- "You haven't slept in a day. Your eyes keep closing, you can't run, and you're weaker. Find a bed at night (F1 > What now? > Places)."  (on-screen notice, line 263)

> Note for you (not shown in game): What now? (sv_livingcity_nextstep.lua)

- "Get some sleep"  (text, line 302)
- "You're exhausted: no running, and weaker until you've slept. Find a bed and press E on it."  (text, line 302)

## talking, knowing each other, and going down (sv_livingcity_rp.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rp.lua`


> Note for you (not shown in game): part of: description

- "A masked Civil Protection unit"  (text, line 109)
- "An Overwatch soldier"  (text, line 111)
- "A shackled vortigaunt"  (text, line 113)
- "in Resistance gear"  (text, line 118)
- "in Union blue"  (text, line 118)
- "in Resistance gear"  (text, line 119)
- "in Union blue"  (text, line 119)
- "A {Gender} {clothes}"  (text, line 120)

> Note for you (not shown in game): part of: name for

- "citizen {alias}"  (text, line 138)

> Note for you (not shown in game): part of: set description

- "Description cleared: people see your clothes and build."  (text, line 149)
- "A little more than that (8 characters at least)."  (text, line 151)
- "Shorter, please (120 characters at most)."  (text, line 152)
- "People who don't know you now see: {text}"  (text, line 156)

> Note for you (not shown in game): a stalker has no words left (sv_livingcity_custody.lua): only the sound comes out

- "screams: a strained, wordless noise."  (text, line 217)

> Note for you (not shown in game): a unit saying one of the mask's lines word for word: heard in its voice too (sv_livingcity_cp.lua)

- "says: "{text}""  (text, line 226)

> Note for you (not shown in game): part of: speak

- "yells: "{text}!""  (text, line 228)
- "whispers: "{text}""  (text, line 230)
- "** {name} {text}"  (text, line 232)

> Note for you (not shown in game): part of: recognize

- "** {Description} introduces themselves as {Nick}."  (text, line 265)
- "Look at someone (or /recognize all, for everyone close enough to hear)."  (chat message, line 269)
- "They already know who you are."  (chat message, line 269)
- "You tell %d %s your name."  (message, line 271)

> Note for you (not shown in game): always available, whatever the chat mode

- "Your description: {Description}  (/chardesc <text> to change it, /chardesc clear to reset)"  (chat message, line 290)

> Note for you (not shown in game): global out of character

- "Global OOC is off on this server. /looc talks out of character to people nearby."  (chat message, line 305)
- "Wait %ds before OOC again."  (message, line 307)

> Note for you (not shown in game): typing in chat

- "** {l} rolls {n} out of {max}."  (text, line 321)
- "The dead don't talk."  (chat message, line 330)

> Note for you (not shown in game): a command nobody knows: don't say it out loud

- "Unknown command. Chat: /me /it /y /w /looc // /roll /recognize /chardesc{or}"  (chat message, line 344)
- "The dead don't talk. (// for OOC.)"  (chat message, line 348)

> Note for you (not shown in game): part of: go down

- "[Living City] You're down, bleeding out. Someone can help you up (E on you). Hold on, or F1 > Give up."  (chat message, line 437)

> Note for you (not shown in game): part of: revive

- "[Living City] {by} gets you back on your feet."  (text, line 478)
- "[Living City] You get back on your feet."  (chat message, line 478)

> Note for you (not shown in game): credited to whoever put them down (the conduct system judges that kill)

- "[Living City] {why}"  (chat message, line 497)

> Note for you (not shown in game): A unit cuffs a wanted person where they lie.

- "Arrested while incapacitated"  (text, line 518)

> Note for you (not shown in game): part of: help downed

- "Cuffing them..."  (text, line 529)
- "Bandaging the wound..."  (text, line 529)
- "Stopping the bleeding with your hands..."  (text, line 529)
- "You leave them."  (text, line 531)

> Note for you (not shown in game): part of: done

- "You cuff them where they lie. They'll live long enough for a cell."  (chat message, line 536)
- "You get them back on their feet."  (chat message, line 544)

> Note for you (not shown in game): hitting someone who's down finishes them

- "They finished what they started."  (text, line 564)

> Note for you (not shown in game): someone tied up: walked along instead (sv_livingcity_cp.lua)

- "You let go."  (chat message, line 577)

> Note for you (not shown in game): part of: toggle drag

- "Look at someone who's down, up close."  (text, line 582)
- "You take hold and drag. (F1 > Drag them along again to let go.)"  (chat message, line 585)

> Note for you (not shown in game): a timer (regularly)

- "You bled out."  (text, line 596)

> Note for you (not shown in game): typing in chat

- "You let go."  (text, line 631)
- "You're not down."  (chat message, line 631)

## running in front of Civil Protection (sv_livingcity_running.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_running.lua`


> Note for you (not shown in game): A shout from a unit: chat, and the words across the middle of the screen.

- "[Civil Protection] {or}{text}"  (chat message, line 44)

> Note for you (not shown in game): Why the cops wouldn't shout at this player, or nil if they would.

- "dead or in a vehicle"  (text, line 78)
- "build mode"  (text, line 79)
- "a Civil Protection unit"  (text, line 80)
- "a stalker (Combine property)"  (text, line 81)
- "in a convincing uniform"  (text, line 82)
- "already wanted"  (text, line 84)

> Note for you (not shown in game): part of: exempt why

- "in custody"  (text, line 85)
- "being stopped"  (text, line 86)
- "Overwatch or the Administrator"  (text, line 87)
- "in rebel territory"  (text, line 88)

> Note for you (not shown in game): told to hurry home: running is what they want

- "curfew grace period"  (text, line 90)

> Note for you (not shown in game): For the debug report: would a unit shout at this player right now, and if not, why not.

- "off (lc_running_cops 0)"  (text, line 113)
- "city not running"  (text, line 114)
- "speed %d (walk %d, run %d)%s, %s, %s"  (message, line 119)

> Note for you (not shown in game): part of: running status

- "exempt: {why}"  (text, line 120)
- "not exempt"  (message, line 120)
- "Civil Protection unit watching at {GetPos}"  (text, line 121)
- "no Civil Protection unit in sight within {GetInt}"  (text, line 121)

> Note for you (not shown in game): part of: chase

- "I said stop running!"  (text, line 128)
- "[Civil Protection] You ran from a Civil Protection unit. Units are after you. Press E on one to give yourself up."  (chat message, line 129)
- "Fleeing Civil Protection"  (text, line 130)

> Note for you (not shown in game): part of: warn

- "Stop running!"  (text, line 139)

## salvage, bins anywhere, the reclamation point, and workbenches (sv_livingcity_salvage.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_salvage.lua`


> Note for you (not shown in game): What it is, to say so: "Prying the radiator apart".

- "the radiator"  (text, line 79)
- "the engine"  (text, line 79)
- "the pipes"  (text, line 79)
- "the wreck"  (text, line 79)
- "the wreck"  (text, line 80)
- "the wreck"  (text, line 80)
- "the wreck"  (text, line 80)
- "the crate"  (text, line 80)
- "the pallet"  (text, line 80)
- "the fridge"  (text, line 81)
- "the fridge"  (text, line 81)
- "the washing machine"  (text, line 81)
- "the stove"  (text, line 81)
- "the drum"  (text, line 82)
- "the drum"  (text, line 82)
- "the fencing"  (text, line 82)
- "the debris"  (text, line 82)
- "the rubble"  (text, line 82)

> Note for you (not shown in game): part of: junk at

- "the junk pile"  (text, line 113)

> Note for you (not shown in game): The noise: units near enough hear it, and a unit on the street comes to look.

- "[CP] Metal being pried apart{or}. Unauthorised salvage?"  (chat message, line 144)

> Note for you (not shown in game): part of: salvage

- "Civil Protection units don't pick through junk."  (text, line 171)
- "You're busy."  (text, line 172)
- "Look at some junk: a wreck, a radiator, pipes, a crate."  (text, line 174)
- "You'll need a crowbar out to get anything off that."  (text, line 175)
- "Stripped already. Nothing left worth taking, for now."  (text, line 179)
- "Prying {or} apart... keep at it"  (progress bar, line 183)
- "You leave it."  (text, line 184)

> Note for you (not shown in game): part of: done

- "Salvaged: {got}."  (text, line 198)
- "Nothing worth keeping in it."  (chat message, line 198)

> Note for you (not shown in game): part of: rebel guard

- "[Rebel] Hey! Those are our supplies. Quit it."  (chat message, line 277)
- "[Rebel] I won't say it again. Put it down and walk away."  (chat message, line 278)
- "[Rebel] A hard shove back out of it. Go."  (chat message, line 284)
- "[Rebel] A fist in the ribs. Last chance."  (chat message, line 285)
- "[Rebel] That's it."  (chat message, line 289)

> Note for you (not shown in game): a timer (regularly)

- "Carrying a weapon (a crowbar)"  (text, line 320)
- "[Civil Protection] A Civil Protection unit saw the crowbar in your hand. That's a weapon."  (chat message, line 321)

> Note for you (not shown in game): Reclamation

- "Civil Protection units don't hand in scrap."  (text, line 364)

> Note for you (not shown in game): part of: reclaim

- "[Reclamation] Quota met for now. Come back later."  (text, line 372)
- "[Reclamation] Scrap metal, empty cans and bottles only."  (text, line 385)
- "materials returned to the Union"  (text, line 389)
- "[Reclamation] The Union thanks you. (The cell could have made something of that.)"  (chat message, line 392)
- "[Reclamation] The Union thanks you for your contribution."  (chat message, line 394)

## flying a scanner from a Combine console (sv_livingcity_scanner.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_scanner.lua`


> Note for you (not shown in game): part of: can link scanner

- "The console is dead. (Scanner links are off on this server.)"  (text, line 69)
- "You're already linked."  (text, line 71)
- "ACCESS DENIED. Civil Protection credentials required."  (text, line 72)
- "Someone's already on this console."  (text, line 74)

> Note for you (not shown in game): never inside a wall: somewhere with room near there, or over the console

- "The console flickers. Nothing answers."  (text, line 168)

> Note for you (not shown in game): part of: start scanner link

- "[Scanner link] You're in the scanner. WASD to fly, Space and Ctrl up and down, Shift faster, left click to flash, R (or E, or F1 > Disconnect) to disconnect."  (chat message, line 180)
- "[Scanner link] Flash a Civil Protection unit and it's %d more seconds on your sentence."  (message, line 182)

> Note for you (not shown in game): part of: end scanner link

- "[Scanner link] {why}"  (chat message, line 196)

> Note for you (not shown in game): a timer (regularly)

- "Link closed."  (text, line 208)

> Note for you (not shown in game): the signal only reaches so far

- "[Scanner link] Signal weak. Turn back."  (chat message, line 240)

> Note for you (not shown in game): part of: scanner flash

- "[Prison] You flashed a Civil Protection unit through the scanner. %d more seconds on your sentence (%d:%02d left)."  (message, line 322)
- "Interfered with a Civil Protection unit through a city scanner, from custody"  (text, line 325)

> Note for you (not shown in game): Who's worth a report, and what it's worth to the one who sends it.

- "Father Grigori"  (text, line 346)
- "a free vortigaunt"  (text, line 347)

> Note for you (not shown in game): part of: scanner suspect

- "a wanted citizen"  (text, line 350)
- "someone on rebel ground"  (text, line 352)
- "an anticitizen"  (text, line 354)
- "a free vortigaunt"  (text, line 360)

> Note for you (not shown in game): a jammer near the scanner: the picture's taken, but it never reaches anyone

- "[Scanner link] Interference. The picture doesn't go through: something nearby is jamming the signal."  (chat message, line 446)

> Note for you (not shown in game): part of: scanner photo

- "A scanner's flash. You've been photographed, and Civil Protection has the picture."  (chat message, line 467)
- "Photographed by a city scanner: {label}"  (text, line 468)

> Note for you (not shown in game): rebel ground, where the camera's pointed

- "rebel ground"  (text, line 479)

> Note for you (not shown in game): the report: every unit on duty gets it, with the subjects lit up

- "a scanner run from custody"  (text, line 489)
- "scanner {Nick}"  (text, line 489)
- "[CP net] Scanner report from %s: %s%s. Subjects highlighted for %ds."  (message, line 490)

> Note for you (not shown in game): part of: scanner photo

- "SCANNER: rebel ground"  (name, line 495)

> Note for you (not shown in game): the city's own units act on it too: hunted people, and the wanted, near enough

- "Father Grigori"  (label, line 501)
- "a wanted citizen"  (label, line 501)

> Note for you (not shown in game): a Scanner Operator's photographs: XP (the same cap as a snitch's standing), and a rebel caught on camera goes out to every unit as a BOLO

- "scanner report"  (text, line 515)

> Note for you (not shown in game): part of: scanner photo

- "Photographed by a city scanner as a rebel{or}"  (text, line 520)
- "[Scanner link] Report filed: %s.%s"  (message, line 523)
- "[Scanner link] Report filed: %s. Civil Standing %+d.%s"  (message, line 530)
- "Your sentence stands."  (message, line 531)
- "[Scanner link] Report filed: {parts}. The city has had enough from you for now; no more standing for a while."  (chat message, line 533)
- "[Scanner link] Report filed: {parts}."  (chat message, line 536)

> Note for you (not shown in game): hurt, however it happened (some damage never reaches the hook below)

- "Something hits you. You pull out of the link."  (text, line 619)
- "The link drops."  (text, line 621)

> Note for you (not shown in game): sentence served: the release has already walked them out

- "Time's up. The console goes dark."  (text, line 624)
- "The console is gone."  (text, line 626)

> Note for you (not shown in game): part of: operator link

- "Scanner Operators only (F4: Civil Protection, Scanner Operator)."  (text, line 664)
- "Get to a terminal: a Combine console, a data terminal, or anywhere in the Nexus."  (text, line 666)

> Note for you (not shown in game): the chat command /scanner

- "Scanner link"  (on-screen notice, line 674)

> Note for you (not shown in game): a timer (regularly)

- "Something hits you. You pull out of the link."  (text, line 680)

> Note for you (not shown in game): released or not, nobody walks out of the cell still flying

- "Time's up. The console goes dark."  (text, line 687)

> Note for you (not shown in game): Out of the link by chat or console, whatever the keys are doing.

- "Link closed."  (text, line 694)
- "Link closed."  (text, line 698)

## getting by (sv_livingcity_scavenge.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_scavenge.lua`


> Note for you (not shown in game): A few seconds of doing something, keeping still

- "You're busy."  (text, line 56)

> Note for you (not shown in game): a fridge at home is yours: your stash, like the stove (not a rummage through someone else's)

- "[Home] Your fridge: your stash is open (F2) while you stand by it."  (chat message, line 188)
- "Civil Protection units don't rummage through people's fridges."  (text, line 191)
- "Civil Protection units don't go through bins."  (text, line 191)

> Note for you (not shown in game): part of: scavenge

- "Somebody's cleared it out already. Nothing but the smell."  (text, line 195)
- "Somebody's been through this one already. Nothing left."  (text, line 195)
- "Your pockets are full."  (text, line 197)
- "Going through the fridge..."  (progress bar, line 198)
- "Going through the rubbish..."  (progress bar, line 198)
- "You leave it."  (text, line 199)

> Note for you (not shown in game): part of: done

- "Nothing worth having."  (chat message, line 206)
- "Found: {name}."  (chat message, line 208)

> Note for you (not shown in game): part of: fish

- "You need water: stand in the canal, or look at it."  (text, line 230)
- "Your pockets are full."  (text, line 231)
- "Fishing... keep still"  (progress bar, line 234)
- "You reel in. The fish can wait."  (text, line 235)

> Note for you (not shown in game): part of: done

- "Nothing bites. The canal keeps its secrets."  (chat message, line 239)
- "A bite! A fish, of a kind. Cook it."  (chat message, line 242)
- "You reel in... {name}."  (text, line 242)

> Note for you (not shown in game): part of: sweep cache

- "The Combine found our supplies. Everything's gone."  (text, line 294)

> Note for you (not shown in game): part of: use cache

- "confiscated Resistance supplies"  (text, line 371)
- "[Civil Protection] Confiscated: %d meals' worth of hoarded supplies."  (message, line 372)
- "The Combine found our supplies. Everything's gone."  (text, line 373)
- "[Civil Protection] Empty. They've eaten it already."  (chat message, line 376)
- "The crate is nailed shut. Whoever it belongs to isn't here."  (chat message, line 381)
- "[Resistance] Everyone eats. Come back in %d minute%s."  (message, line 386)
- "[Resistance] The crate's empty. Somebody needs to make a supply run (F3), or bring food (C > Resistance > Donate food)."  (chat message, line 390)
- "Your pockets are full."  (chat message, line 393)
- "[Resistance] A tin from the stores. %d left."  (message, line 396)

> Note for you (not shown in game): part of: use pot

- "uprooted an illegal garden"  (text, line 405)
- "[Civil Protection] Unlicensed agriculture. You pull it up by the roots."  (chat message, line 406)
- "An empty pot."  (chat message, line 408)
- "An empty pot. Plant a seed packet in it (the black market, or rubbish bins, if you're lucky)."  (chat message, line 414)
- "You plant the seeds. Back in %d minutes."  (message, line 420)
- "Green shoots. Ripe in %d:%02d."  (message, line 427)
- "Your pockets are full."  (chat message, line 429)
- "You pick %d lot%s of vegetables.%s"  (message, line 434)
- "Not your pot. Somebody will be annoyed."  (message, line 435)
- "Someone's harvested your pot in rebel territory."  (chat message, line 436)

> Note for you (not shown in game): part of: donate

- "Stand by a Resistance supply crate to donate food."  (text, line 475)
- "That's not how confiscation works."  (text, line 476)
- "The crate's full. Eat something."  (text, line 486)
- "You've no proper food to give (rations, tins, bread, vegetables, cooked meat)."  (text, line 486)
- "fed the Resistance"  (text, line 488)
- "[Resistance] You add %d meal%s to the stores. %d in the crate."  (message, line 490)

> Note for you (not shown in game): part of: spray

- "Look at a wall, up close."  (text, line 532)
- "There's already one here."  (text, line 533)
- "Spraying the lambda... keep looking at the wall"  (progress bar, line 534)
- "You stop, half done, and the paint runs."  (text, line 535)

> Note for you (not shown in game): part of: done

- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 545)

> Note for you (not shown in game): part of: clean tag

- "Paint over our own? No."  (text, line 564)
- "Scrubbing it off..."  (progress bar, line 565)
- "You leave it half scrubbed."  (text, line 566)

> Note for you (not shown in game): part of: done

- "cleaned up anticitizen graffiti"  (text, line 574)
- "[Civil Protection] Gone. As if it never was."  (chat message, line 575)
- "You scrub it off. Someone from the Union nods at you. +3 standing."  (chat message, line 579)

> Note for you (not shown in game): part of: item use

- "Find an empty pot in rebel territory."  (text, line 625)
- "Something's already growing in that one."  (text, line 626)

> Note for you (not shown in game): typing in chat

- "You need a fishing line (the Commissary sells them)."  (chat message, line 671)

> Note for you (not shown in game): the game's living city tagged moment

- "Someone painted the lambda up {or}. Bold."  (text, line 680)
- "There's a lambda on the wall {or}. Civil Protection will have it off by morning."  (text, line 681)

## Combine-only areas (sv_livingcity_security.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_security.lua`


> Note for you (not shown in game): part of: combine zone tick

- "[Civil Protection] This is a restricted area. Leave immediately."  (chat message, line 44)
- "[Civil Protection] Trespassing in a restricted area. You are now wanted."  (chat message, line 48)
- "Trespassing in a Combine area"  (text, line 49)

> Note for you (not shown in game): Stuck in a pit, behind a fence, in the map? !stuck puts you back on the street.

- "Not now."  (text, line 75)
- "Not while you're in custody."  (text, line 76)
- "Not while you're wanted."  (text, line 77)
- "You can use that again in %d seconds."  (message, line 79)

> Note for you (not shown in game): part of: unstick

- "There's nowhere to put you. Ask an admin."  (text, line 93)

> Note for you (not shown in game): part of: stuck command

- "[Living City] You pull yourself out and brush yourself off."  (chat message, line 102)
- "[Living City] {why}"  (chat message, line 103)

## jobs that come with supply drops, and Union work orders that (sv_livingcity_sidejobs.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_sidejobs.lua`


> Note for you (not shown in game): part of: factions

- "[Assignments] {line} You keep: {got}."  (chat message, line 40)

> Note for you (not shown in game): Supply drops

- "Guard the supply drop {GetPos}"  (title, line 57)

> Note for you (not shown in game): part of: build

- "A dropship is setting Union supplies down"  (text, line 58)
- "A convoy is unloading Union supplies"  (text, line 58)
- ". Anticitizens will want them. Nobody touches that crate."  (description, line 58)
- "Get to the supply drop"  (quest step, line 59)
- "Guard the crate until the convoy moves on"  (quest step, line 59)
- "Raid the supply drop {GetPos}"  (title, line 71)
- "A Combine dropship is bringing guns, ammunition and medicine down"  (text, line 72)
- "A Combine convoy is unloading guns, ammunition and medicine"  (text, line 72)
- ". Get in, take what you can carry from the open crate, get out."  (description, line 72)
- "Get to the supply drop"  (quest step, line 74)
- "Take loads from the crate (press E on it)"  (quest step, line 75)

> Note for you (not shown in game): the map has streetlights and none are out: nothing to fix

- "Work order: fix a streetlight"  (title, line 112)
- "A streetlight is out {GetPos}. Rewire it. Keep what's left over."  (description, line 113)
- "Find the dead streetlight"  (quest step, line 114)
- "Rewire it (stay close)"  (quest step, line 114)

> Note for you (not shown in game): part of: build

- "The light flickers on."  (text, line 115)
- "Work order: fix a streetlight"  (title, line 121)
- "A streetlight is out {GetPos}. Rewire it. Keep what's left over."  (description, line 122)
- "Find the dead streetlight"  (quest step, line 123)
- "Rewire it (stay close)"  (quest step, line 123)
- "The light flickers on."  (text, line 124)
- "Work order: clear rubble"  (title, line 135)
- "Rubble is blocking the way {GetPos}. Clear it. Anything salvageable is yours."  (description, line 136)
- "Clear the rubble (press E)"  (text, line 138)
- "The way is clear."  (text, line 139)
- "Work order: patch a leaking pipe"  (title, line 150)
- "A pipe is leaking {GetPos}. Get down and patch it."  (description, line 151)
- "Find the leak"  (quest step, line 152)
- "Patch the pipe (crouch beside it)"  (quest step, line 152)
- "The leak stops."  (text, line 153)
- "Steal the Combine's data {here}"  (title, line 182)
- "Each Combine terminal only holds half the picture. Hit two: one {here}, then another {GetPos}. Aim the multitool at each, left click, and stay with it while it downloads. Each sounds the alarm halfway, and a squad comes. The two fragments make a chip: the lab's scientist decodes it, or the dealer pays for it."  (description, line 183)
- "Get to the first terminal"  (quest step, line 186)
- "Download its half (aim the multitool and left click; stay close)"  (quest step, line 187)
- "Get to the second terminal"  (quest step, line 188)
- "Download the other half (a different terminal)"  (quest step, line 189)
- "The master terminal {GetPos}"  (title, line 207)
- "The Combine's master terminal {GetPos}: everything they know, in one place. It takes a full minute to download, every alarm in the nexus goes off a third of the way in, and they'll send more than a squad. Bring the core home: the quartermaster's decoding marks every Civil Protection unit for ten minutes, the dealer pays a fortune, or it wipes every comrade's record."  (description, line 208)
- "Get to the master terminal"  (quest step, line 210)
- "Download the master terminal (aim the multitool and left click; hold on for a minute)"  (quest step, line 211)
- "Data breach {GetPos}"  (title, line 224)
- "Anticitizens are inside Combine systems. Get there, stop them, and secure the terminal."  (description, line 225)
- "Get to the breach"  (quest step, line 226)
- "Secure the terminal"  (quest step, line 226)

> Note for you (not shown in game): The Resistance's operations, and the city's answers (sv_livingcity_resistanceops.lua)

- "Get the cell open (stay at the door while the alarm goes)"  (quest step, line 241)

> Note for you (not shown in game): part of: build

- "Break {Nick} out"  (title, line 245)
- "is in a cell {GetPos}. Get in (a keycard, a bypass charge, or a Hacker's multitool on the Combine doors), get the cell open, get them out."  (description, line 246)
- "Get to the cells"  (quest step, line 247)
- "Prison break {GetPos}"  (title, line 259)
- "Anticitizens are at the cells. Get there and hold them."  (description, line 260)
- "Get to the cells"  (quest step, line 261)
- "Hold the cells"  (quest step, line 261)
- "Intercept the smuggler"  (title, line 271)
- "Stolen Union supplies are on the move. Follow the SMUGGLER marker and stop the carrier: arrest or kill."  (description, line 272)
- "Stop the smuggler (follow the SMUGGLER marker)"  (quest step, line 273)
- "Retake the city screen {GetPos}"  (title, line 285)
- "The Resistance have hijacked a city screen. Get there inside a minute and cut it (E on the screen)."  (description, line 286)
- "Cut the broadcast (E on the screen)"  (quest step, line 287)
- "Secure the landing zone {GetPos}"  (title, line 299)
- "Overwatch reinforcements are coming down. Hold the ground around the landing zone."  (description, line 300)
- "Get to the landing zone"  (quest step, line 301)
- "Hold the landing zone"  (quest step, line 301)
- "Ambush the landing {GetPos}"  (title, line 314)
- "A dropship is bringing Overwatch soldiers down at the landing zone. Be there when it comes in, and hit the landing party while they're still on the ground."  (description, line 315)
- "Get to the landing zone before the dropship does"  (quest step, line 317)
- "Bring down the landing party (the soldiers off the dropship)"  (quest step, line 318)
- "Join the sweep {GetPos}"  (title, line 343)
- "A sweep team is moving into anticitizen territory {GetPos}. Join it, and take down the anticitizens who resist."  (description, line 344)
- "Join the sweep team at the edge of anticitizen territory"  (quest step, line 346)
- "Take down two armed anticitizens there"  (quest step, line 347)
- "Repel the attack {GetPos}"  (title, line 359)
- "Armed anticitizens are attacking Civil Protection units {GetPos}. Get there and put it down."  (description, line 360)
- "Get to the attack"  (quest step, line 362)
- "Take down two of the attackers"  (quest step, line 363)
- "Back up the raid {GetPos}"  (title, line 379)
- "Our fighters are hitting the Combine {GetPos}. Get there, and help them: take down the units they're fighting."  (description, line 380)
- "Meet our fighters at the target"  (quest step, line 382)
- "Back them up: take down two of the Combine's units there"  (quest step, line 383)

> Note for you (not shown in game): A shackled vortigaunt, at a Combine work site. It waits, shackled and harmless, with its keepers. Cut the shackles there (they may see), or lead it off still shackled as if you were moving Combine property, and cut them in rebel territory (any of it): unless a unit stops you and asks where you're taking it.

- "player {or} 99"  (text, line 399)

> Note for you (not shown in game): part of: build

- "Find the shackled vortigaunt at the work site"  (text, line 424)

> Note for you (not shown in game): a unit who sees you leading it may stop you and ask (once): then it's a fight

- "A Civil Protection unit steps into your way: "Where are you taking that?" No answer will do. Run, or fight."  (quest narration, line 460)
- "Theft of Combine property"  (text, line 461)

> Note for you (not shown in game): part of: on done

- "In rebel territory, the shackles come off. It breathes in, slowly, and looks round at its new home."  (quest narration, line 471)

> Note for you (not shown in game): part of: build

- "Cut the shackles (stay beside it)"  (quest step, line 478)

> Note for you (not shown in game): part of: on done

- "Theft of Combine property"  (text, line 481)
- "The shackles fall. It looks at you, and waits. Lead it home."  (quest narration, line 483)

> Note for you (not shown in game): part of: build

- "The vortigaunt waits, its collar humming. Cut it loose here, or walk it out as if it were still the Combine's?"  (quest choice, line 485)
- "Cut the shackles here (twelve seconds beside it; its keepers may see), then lead it home."  (text, line 486)

> Note for you (not shown in game): part of: pick

- "Lead it home to rebel territory (any of it)"  (text, line 487)

> Note for you (not shown in game): part of: build

- "Lead it off still shackled, like Combine property on the move; cut them in rebel territory (a unit may stop you and ask)."  (text, line 488)

> Note for you (not shown in game): part of: pick

- "Walk it to rebel territory (any of it), still shackled"  (text, line 489)

> Note for you (not shown in game): part of: build

- "Free a vortigaunt {GetPos}"  (title, line 492)
- "The Combine are working a shackled vortigaunt {GetPos}. Free it and bring it to rebel territory: it will heal our wounded."  (description, line 493)

## character slots (sv_livingcity_slots.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_slots.lua`


> Note for you (not shown in game): Can this player switch right now? ok, or false and why.

- "Character slots are off on this server."  (text, line 133)
- "Not while you're dead."  (text, line 134)
- "Not while you're wanted."  (text, line 135)
- "Not while you're in custody."  (text, line 136)
- "Not while you're down."  (text, line 137)
- "Not with your hands cuffed."  (text, line 138)
- "Not in the middle of a fight."  (text, line 139)

> Note for you (not shown in game): part of: can switch character

- "Finish or abandon your job first (!abandon)."  (text, line 140)
- "A stalker has no other life to go back to. Only death ends it."  (text, line 141)
- "You can switch again in %ds."  (message, line 143)

> Note for you (not shown in game): part of: switch character

- "No such slot."  (text, line 150)
- "You're already playing them."  (text, line 152)
- "[Living City] You are someone new: %s, citizen %s."  (message, line 177)
- "[Living City] You are %s, citizen %s."  (message, line 180)
- "%s switched to slot %d (%s)"  (message, line 182)

> Note for you (not shown in game): part of: delete character slot

- "You can't delete the person you're playing. Switch to someone else first."  (text, line 189)
- "That slot is empty."  (text, line 190)
- "Gone. Nobody in the city remembers them."  (text, line 196)

> Note for you (not shown in game): the game answering something done in a window (lc_slots_do)

- "[Characters] {msg}"  (chat message, line 215)

> Note for you (not shown in game): typing in chat

- "Character slots are off on this server. C > Me > Change my name and face."  (chat message, line 229)

## staff tools (sv_livingcity_staff.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_staff.lua`


> Note for you (not shown in game): commands and out-of-character chat (in-character speech is logged where it's spoken)

- "({SteamID}) joined"  (text, line 91)
- "({SteamID}) left"  (text, line 92)

> Note for you (not shown in game): someone dying

- "killed {victim} with {how}"  (text, line 98)
- "died ({how})"  (text, line 100)

> Note for you (not shown in game): the game's living city incarcerated moment

- "jailed {or}s: {or}{or}"  (text, line 105)

> Note for you (not shown in game): the game's living city wanted moment

- "wanted: {or}"  (text, line 109)

> Note for you (not shown in game): the game's living city strike moment

- "conduct strike {n}: {or}"  (text, line 112)

> Note for you (not shown in game): part of: open ticket

- "Say what you need: @ <message>"  (text, line 137)
- "Give staff a moment to read that before you add more."  (text, line 138)
- "Your ticket is already long. Staff will read it: wait for an answer."  (text, line 143)
- "[Ticket #%d] %s adds: %s"  (message, line 145)
- "#{id} {Who}: {text}"  (text, line 146)
- "Added to your ticket. Staff will be with you."  (text, line 147)
- "[Ticket #%d] %s: %s  (C > Help > Staff panel to answer)"  (message, line 158)
- "#{id} opened by {Who}: {text}"  (text, line 161)
- "Your ticket is in. Staff will be with you."  (text, line 162)
- "Your ticket is in. No staff are on right now; it'll wait."  (text, line 162)

> Note for you (not shown in game): part of: ticket action

- "No such ticket."  (text, line 171)
- "[Staff] {me} is looking at your ticket."  (chat message, line 176)
- "[Staff] {me}: {text}"  (chat message, line 181)
- "[Staff] Your ticket was closed by {me}."  (chat message, line 184)
- "They're not on."  (text, line 186)
- "They're not on."  (text, line 189)

> Note for you (not shown in game): part of: warn player

- "Staff only."  (text, line 214)
- "Player not found."  (text, line 215)
- "Give a reason: !warn <name> <reason>"  (text, line 217)
- "[Staff] You have been warned: %s (warning %d)"  (message, line 229)
- "warned by {or}: {reason}"  (text, line 230)
- "warned ({list} in total)."  (text, line 231)

> Note for you (not shown in game): part of: unwarn

- "No such warning."  (text, line 239)
- "warning {idx} struck off {sid} by {or}"  (text, line 242)
- "Struck off."  (text, line 243)

> Note for you (not shown in game): Is this name (a character's) banned?

- "Staff only."  (text, line 268)

> Note for you (not shown in game): part of: char ban

- "Player not found."  (text, line 269)
- "Give a reason: !charban <name> <reason>"  (text, line 271)
- "[Staff] %s is gone, by staff decision: %s. You're someone new."  (message, line 282)
- "({cid}, {target}) banned by {or}: {reason}"  (text, line 283)
- "is banned. {Nick} starts over as someone new."  (text, line 284)

> Note for you (not shown in game): part of: char unban

- "No such ban."  (text, line 290)
- "ban on {or} lifted by {or}"  (text, line 293)
- "The ban on {or} is lifted."  (text, line 294)

> Note for you (not shown in game): the game answering something done in a window (lc_staff_do)

- "{action} {Nick}"  (text, line 339)
- "[Staff] {msg}"  (chat message, line 342)

> Note for you (not shown in game): Chat

- "[Tickets] {msg}"  (chat message, line 355)

> Note for you (not shown in game): typing in chat

- "Staff only. Need help? @ <message>"  (chat message, line 361)
- "Staff only."  (chat message, line 365)
- "[Staff] {msg}"  (chat message, line 370)

> Note for you (not shown in game): the console command lc_staff

- "Staff only."  (chat message, line 375)

## the stalker's lot (sv_livingcity_stalkerwork.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_stalkerwork.lua`


> Note for you (not shown in game): part of: stalker step in

- "Walked into the gap between two power transformers. The current took them before they hit the floor."  (text, line 167)
- "[City] A flash below the Nexus. Combine property has been written off."  (chat message, line 172)

> Note for you (not shown in game): Turned away: back to work. The energizer stays, and so does the way out.

- "Back to work"  (on-screen notice, line 182)
- "The current snaps across the gap behind you. It will still be there: walk into it, or E on it twice, if you change your mind."  (on-screen notice, line 182)

> Note for you (not shown in game): part of: use energizer

- "The current"  (on-screen notice, line 198)
- "It would be very easy. Press E again to step into the gap. There's no coming back."  (on-screen notice, line 198)

> Note for you (not shown in game): The holding floor: grime here and there; a push broom (no kneeling: a stalker hasn't the legs for it). E on each patch sweeps it up (a couple of seconds).

- "The holding floor"  (title, line 278)

> Note for you (not shown in game): part of: start

- "[Stalker] A push broom, and the floor. Walk to each patch of grime and sweep it up (E)."  (chat message, line 293)

> Note for you (not shown in game): part of: hud

- "Swept: %d of %d"  (message, line 294)
- "E on the grime sweeps it up"  (text, line 294)

> Note for you (not shown in game): pressing E on something

- "Sweeping it up..."  (progress bar, line 310)

> Note for you (not shown in game): The frame: four containment cells to carry over and seat in it (pick each up with E, set it in the frame), then the housing welded shut at four seams (E on each, a few seconds of sparks).

- "The frame"  (title, line 328)

> Note for you (not shown in game): part of: start

- "[Stalker] Four containment cells lie about. Carry each one to the frame (E to pick it up) and set it in."  (chat message, line 346)

> Note for you (not shown in game): part of: hud

- "Cells seated: %d of %d"  (message, line 348)
- "E picks a cell up; set it in the frame"  (text, line 348)
- "Seams welded: %d of %d"  (message, line 349)
- "E on each glowing seam"  (text, line 349)

> Note for you (not shown in game): part of: tick

- "[Stalker] The cells click home. Now the housing: weld the four seams (E on each)."  (chat message, line 362)

> Note for you (not shown in game): pressing E on something

- "Welding the seam..."  (progress bar, line 400)

> Note for you (not shown in game): part of: tech gone

- "an Overwatch technician going back"  (text, line 445)

> Note for you (not shown in game): The story

- "The Stalker's Lot"  (name, line 455)
- "You walked into the gap between the transformers. The current took the stalker that was you, all at once."  (text, line 459)
- "You turned away from it, and went back to work. It's still down there, humming. So are you."  (text, line 460)

> Note for you (not shown in game): part of: build

- "They brought you up from below with a number where your name was, and a voice that can only scream. Report where you're kept. Stand still while they finish you."  (description, line 468)
- "Report to the Nexus, where they keep you"  (quest step, line 470)

> Note for you (not shown in game): then

- "An Overwatch technician comes for you, tools in hand."  (quest narration, line 472)

> Note for you (not shown in game): part of: build

- "Stand still while the technician fits the harness"  (quest step, line 474)

> Note for you (not shown in game): then

- "Cold metal on your spine. A click. Your legs are yours to walk with, and nothing else."  (quest narration, line 476)

> Note for you (not shown in game): part of: build

- "The holding floors are never clean. That's what you're for now: a push broom, and the grime."  (description, line 489)
- "Go to the holding floor: your push broom's waiting"  (text, line 491)
- "Sweep up every patch of grime (E on each)"  (text, line 492)

> Note for you (not shown in game): then

- "A Civil Protection unit steps over the broom without looking down. You are furniture that moves."  (quest narration, line 493)

> Note for you (not shown in game): part of: build

- "Something new is going in below the Nexus, and it needs power. The cable runs from the banks. You run the cable."  (description, line 504)
- "Go to the power bank"  (text, line 506)
- "the power bank"  (text, line 506)
- "Splice the cable in: turn the tiles till the current reaches the bank (a sparking tile bites)"  (text, line 507)
- "Now the next power bank"  (text, line 508)
- "the power bank"  (text, line 508)
- "Splice it in"  (text, line 509)

> Note for you (not shown in game): then

- "The banks drop and surge. Somewhere under your feet, something drinks."  (quest narration, line 510)

> Note for you (not shown in game): part of: build

- "Go to the frame they've set up, beside the power transformer"  (quest step, line 519)
- "The frame"  (title, line 523)
- "A second power transformer, to stand beside the city's own. A frame of black metal, waiting for you."  (description, line 524)
- "Carry the four containment cells to the frame and set them in (E), then weld the four seams (E on each)"  (text, line 527)

> Note for you (not shown in game): then

- "Sparks, and then it's sealed. It stands beside the other one like a twin, a body's width apart."  (quest narration, line 529)

> Note for you (not shown in game): part of: build

- "Go back to the transformer you built"  (quest step, line 538)

> Note for you (not shown in game): part of: on done

- "the terminal"  (text, line 540)

> Note for you (not shown in game): part of: build

- "The charge"  (title, line 542)
- "It needs its first charge. Then it's finished, and so are you, one way or another."  (description, line 543)
- "Route its first charge through the regulator: turn the tiles till the current reaches it"  (text, line 546)

> Note for you (not shown in game): then

- "It hums, and then the current jumps the gap: a blue-white arc between the two transformers, snapping, never still. It is the most beautiful thing you have seen since they took you."  (quest narration, line 548)

> Note for you (not shown in game): part of: build

- "The Civil Protection units have stopped watching you. The arc snaps across the gap, and snaps again. It would be very easy to walk into it, and then there would be no more stalker."  (quest choice, line 550)
- "Walk into the gap. (This person ends for good: you start over as someone new.)"  (text, line 551)

> Note for you (not shown in game): part of: pick

- "You step into the gap."  (quest narration, line 553)

> Note for you (not shown in game): part of: build

- "Turn away, and go back to work."  (text, line 556)

> Note for you (not shown in game): part of: pick

- "You turn your back on it. Behind you it hums, and hums."  (quest narration, line 558)

## static map props (sv_livingcity_staticprops.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_staticprops.lua`


> Note for you (not shown in game): Reads the static props of a BSP. Returns a list of fixtures, or nil and why.

- "couldn't open {path}"  (text, line 117)
- "not a BSP file"  (text, line 120)

> Note for you (not shown in game): part of: read static fixtures

- "odd game lump directory"  (text, line 128)
- "the map's static props are compressed"  (text, line 135)
- "odd model list"  (text, line 139)
- "odd leaf list"  (text, line 149)

> Note for you (not shown in game): the record size depends on the map's version, but origin, angles and the model index lead them all

- "odd prop records"  (text, line 156)

> Note for you (not shown in game): part of: scan static props

- "Static props: %d stove/sink/vending fixtures, %d dumpsters or bins, %d tables, counters or shelves, %d beds and seats and %d pieces of junk to salvage found in the map"  (message, line 185)

> Note for you (not shown in game): the console command lc_scanprops

- "[Living City] Static props: {or}"  (text, line 218)
- "[Living City] Couldn't read the map's props: {StaticScanNote}"  (text, line 219)

## the city's stores (sv_livingcity_stockpile.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_stockpile.lua`

- "The city's ration stores are empty. Distribution is suspended until supplies arrive."  (text, line 78)
- "Ration stores are running low. Allocations will be slower until supplies arrive."  (short name, line 79)
- "Ration stores are full. Productive citizens are rewarded."  (text, line 80)

> Note for you (not shown in game): part of: check level

- "[City] {lvl}"  (chat message, line 88)

> Note for you (not shown in game): the game's living city npcwork finished moment

- "npc work"  (text, line 134)

> Note for you (not shown in game): the game's living city train arrived moment

- "train freight"  (text, line 137)

> Note for you (not shown in game): What goes out

- "ration line"  (text, line 144)

> Note for you (not shown in game): the console command lc_stock

- "[Living City] City stores: %d of %d rations (%s)."  (message, line 172)

## places to keep things (sv_livingcity_storage.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_storage.lua`

- "the bin"  (text, line 91)
- "the locker"  (text, line 91)
- "the crate"  (text, line 91)
- "the stall"  (text, line 91)

> Note for you (not shown in game): What this player may do with it: "open" (their own, or a bin), "search" (a unit), or nil and why.

- "Lockers are for citizens in good standing (Civil Standing %d). Yours is %d."  (message, line 156)

> Note for you (not shown in game): part of: access

- "The stall is closed."  (text, line 161)
- "The locker is locked. It's someone else's."  (text, line 164)
- "The crate is locked. It isn't yours."  (text, line 164)

> Note for you (not shown in game): Pressing E on a locker or crate: open your pockets alongside it.

- "[Search] You open {kind}{or}."  (chat message, line 191)

> Note for you (not shown in game): Putting in and taking out

- "There's nothing here to put it in."  (text, line 212)
- "Not yours to fill."  (text, line 214)
- "That's Combine issue: it stays with you (or another unit)."  (text, line 216)
- "It won't fit."  (text, line 217)

> Note for you (not shown in game): part of: container put

- "[Living City] The locker is yours now. Only you can open it."  (chat message, line 223)

> Note for you (not shown in game): part of: container take

- "Buy it."  (text, line 237)

> Note for you (not shown in game): units only take what's illegal

- "It's not contraband. It stays."  (text, line 240)

> Note for you (not shown in game): part of: container take

- "Contraband seized"  (text, line 249)
- "Contraband in their {or}"  (text, line 254)
- "Contraband found in their {kind}: {name}"  (text, line 255)
- "[Civil Protection] Your {kind} was searched. They found: {name}."  (chat message, line 256)

> Note for you (not shown in game): Giving up an empty locker, or packing up an empty crate.

- "It isn't yours."  (text, line 266)
- "Empty it first."  (text, line 267)

> Note for you (not shown in game): part of: container release

- "The locker is free for anyone now."  (text, line 271)
- "Collect the takings first."  (text, line 274)
- "You can't carry it."  (text, line 275)
- "You pack the stall up."  (text, line 280)
- "You pack the crate up."  (text, line 280)

> Note for you (not shown in game): part of: place crate

- "Storage is off on this server."  (text, line 303)
- "Trading needs a CWU business license in your pockets (the Commissary issues them)."  (text, line 306)
- "You already have %d %s set down. Pack one up first."  (message, line 311)
- "Not in a doorway."  (text, line 316)
- "There's no room there."  (text, line 318)

> Note for you (not shown in game): Market stalls: stock it with prices, people buy, takings wait in the till Put one in for sale at a price (or change the price of what's there). spec: "item|price"

- "Name a price."  (text, line 355)
- "It isn't your stall."  (text, line 358)

> Note for you (not shown in game): part of: stall buy

- "The stall is closed."  (text, line 375)
- "It's your own stall. Take it back instead."  (text, line 376)
- "That's gone."  (text, line 378)
- "You can't afford it."  (text, line 379)
- "[Stall] Sold: %s, %d credits. (%d in the till)"  (message, line 389)
- "Bought: %s, %d credits."  (message, line 392)

> Note for you (not shown in game): part of: stall collect

- "The till is empty."  (text, line 399)
- "the stall's takings"  (text, line 401)

> Note for you (not shown in game): part of: stall reopen

- "You need a business license to trade."  (text, line 417)
- "The stall is open."  (text, line 420)

## story chains (sv_livingcity_stories.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_stories.lua`


> Note for you (not shown in game): part of: patrol

- "Go to patrol stop"  (message, line 50)

> Note for you (not shown in game): Internal Affairs

- "A camera flashes in the window across the street. Internal Affairs was watching the whole time, and saw you take the bribe."  (quest narration, line 98)

> Note for you (not shown in game): part of: refuse bribe

- "Arrest him for attempted bribery with the Arrest Baton (right click)"  (text, line 108)
- "Internal Affairs"  (name, line 112)
- "Internal Affairs closes your file. As far as they're concerned, your slate is clean again."  (text, line 116)
- "Internal Affairs found nothing on you. This time."  (text, line 117)
- "Internal Affairs caught you taking a bribe. It stays on your record and will follow you."  (text, line 118)
- "You named another unit, and now he's paying for what you did."  (text, line 119)
- "You took the blame and lost 100 XP. You kept your conscience. In this city that is a bad trade, and you made it anyway."  (text, line 120)
- "You stared them down. Internal Affairs can't prove anything, but they'll never stop watching you."  (text, line 121)
- "You work for the crooked officers now. The money is very good."  (text, line 122)
- "You sank the ring's weapons and reported them seized. You played both sides and got away with it. For now."  (text, line 123)
- "Internal Affairs knows you dumped their crate of weapons in the canal."  (text, line 124)

> Note for you (not shown in game): part of: build

- "A quiet word"  (title, line 132)
- "You've been summoned {GetPos}. The message isn't signed, but you can guess who sent it: Internal Affairs."  (description, line 133)
- "Go to the marked spot where you were summoned"  (quest step, line 135)
- "Walk up to the officer waiting for you there"  (text, line 136)
- "The officer won't give his unit number: he's Internal Affairs, and he knows about the bribes. 'Your ration ledger doesn't add up, unit. Neither do the citizens who keep walking free on your shift.'"  (quest choice, line 137)
- "Confess to the bribes, and ask for a chance to make it right."  (text, line 139)

> Note for you (not shown in game): part of: pick

- "He nods slowly. 'Then make it right. Your next patrol goes by the book, every step. We'll be counting.'"  (quest narration, line 142)

> Note for you (not shown in game): part of: build

- "Talk your way out of it."  (text, line 145)

> Note for you (not shown in game): part of: success

- "He writes something down. 'We'll be in touch.' It doesn't sound like you're off the hook."  (quest narration, line 147)

> Note for you (not shown in game): part of: fail

- "He doesn't believe a word of it. 'From now on, someone will be watching you, Civil Protection unit.'"  (quest narration, line 151)

> Note for you (not shown in game): part of: build

- "Offer him a share of your bribes."  (text, line 154)

> Note for you (not shown in game): part of: pick

- "A long pause. Then he laughs, and holds out his hand for the money. He's as crooked as you are."  (quest narration, line 157)

> Note for you (not shown in game): part of: build

- "Patrol by the book: go to stop"  (text, line 166)
- "Inspect three different citizens by the book: walk up to each one and press E"  (quest step, line 168)
- "Internal Affairs wants to see a model officer. Patrol three stops and inspect three citizens, all by the book, while they watch."  (description, line 175)
- "The audit"  (title, line 184)
- "You've been sent on a routine patrol {GetPos}. Nothing to worry about, they say."  (description, line 185)
- "Go to the marked spot and patrol there"  (quest step, line 187)
- "A citizen is waving you over: walk up to him"  (text, line 188)
- "A citizen presses a bundle of ration units into your hand: a bribe. 'For your trouble, officer.' His eyes flick to a window across the street."  (quest choice, line 189)
- "Refuse, and arrest him for attempted bribery."  (text, line 191)
- "Take the bribe."  (text, line 192)
- "Look at the window he glanced at."  (text, line 193)

> Note for you (not shown in game): part of: success

- "A camera lens glints behind the glass: this is an Internal Affairs test. You hand the bundle back, loudly, and thank him for his loyalty."  (quest narration, line 198)

> Note for you (not shown in game): part of: fail

- "You see nothing but a window. The bundle is still in your hand, and he's still waiting for your answer."  (quest narration, line 202)
- "He's still waiting for you to decide. The bribe is still in your hand."  (quest choice, line 203)
- "Refuse, and arrest him."  (text, line 204)
- "Take the bribe."  (text, line 205)

> Note for you (not shown in game): part of: build

- "Inspect two different citizens while he watches (walk up to each one and press E)"  (quest step, line 220)
- "The Civil Protection unit who has followed you all shift finally speaks. 'Give us the name of another Civil Protection unit who takes bribes. Or we keep looking at you.'"  (quest choice, line 221)
- "Give them another unit's name."  (text, line 223)

> Note for you (not shown in game): part of: pick

- "Unit 4-17 is reassigned to the canals the next morning. You never see him again."  (quest narration, line 226)

> Note for you (not shown in game): part of: build

- "Take the blame yourself (you lose 100 XP)."  (text, line 228)
- "Say nothing. Stare at his mask until he gives up and leaves."  (text, line 233)

> Note for you (not shown in game): part of: fail

- "You look away first. That's all the answer he needs."  (quest narration, line 236)

> Note for you (not shown in game): part of: build

- "Under watch"  (title, line 242)
- "Internal Affairs has put a unit on your tail, and he'll follow you all shift. Patrol three stops and inspect two citizens, and do it well."  (description, line 243)
- "The smuggling ring"  (title, line 267)
- "Your new friends, the crooked officers, need a crate moved quietly. Pick it up {GetPos}."  (description, line 268)
- "Collect the crate: walk up to your contact and press E"  (text, line 270)
- "'Careful with that one. It's not what the label says.'"  (text, line 270)
- "The crate rattles. It's full of guns for the rebels, sold by the very officers whose job is hunting them."  (quest choice, line 271)
- "Deliver it to the buyer. Business is business."  (text, line 272)
- "Dump it in the canal and report it seized."  (text, line 276)

> Note for you (not shown in game): part of: success

- "The crate sinks. Your report says it was seized, and it's convincing."  (quest narration, line 281)

> Note for you (not shown in game): part of: fail

- "Internal Affairs finds out what you did within the hour."  (quest narration, line 285)
- "Theft from Internal Affairs"  (text, line 287)

> Note for you (not shown in game): part of: build

- "Take the crate to the buyer {GetPos} and press E on him"  (text, line 293)
- "The buyer doesn't count the money in front of you. That's how you know it's a lot."  (text, line 293)

> Note for you (not shown in game): The Pamphleteer

- "The Pamphleteer"  (name, line 305)
- "You've joined the Resistance. Your old life is just a cover story now."  (text, line 311)
- "You're a friend of the Resistance, not a member. They'll call on you when they need help."  (text, line 312)
- "You reported the stranger. He never came back. Neither did the family in 4C."  (text, line 313)
- "You shut the door on the Resistance. Some doors stay shut."  (text, line 314)

> Note for you (not shown in game): part of: build

- "A knock at night"  (title, line 321)
- "Go home ({name}). Someone is waiting for you there."  (description, line 322)
- "Go home ({name})"  (quest step, line 324)
- "Someone is waiting outside your door: walk up to him"  (text, line 325)
- "A stranger in a Union jacket that doesn't fit him. He says your name like he's known it for years. 'You've been kind to the people the Combine hunt. We noticed. Can you be useful to us, too?'"  (quest choice, line 326)

> Note for you (not shown in game): part of: pick

- "He talks for a long time, about the Resistance and what you could do for it. Mostly about you."  (quest narration, line 329)

> Note for you (not shown in game): part of: build

- "Report him to Civil Protection."  (text, line 332)

> Note for you (not shown in game): part of: pick

- "He sees it in your face before you move. He's gone by the time you turn around."  (quest narration, line 336)
- "Find a Civil Protection unit and press E on him to report the stranger"  (quest step, line 337)

> Note for you (not shown in game): part of: build

- "Shut the door on him."  (text, line 339)

> Note for you (not shown in game): part of: pick

- "You lean against the door until his footsteps fade."  (quest narration, line 342)

> Note for you (not shown in game): part of: build

- "Proof of nerve"  (title, line 354)
- "The Resistance is testing you: carry a parcel across the district to a dead drop. Don't open it, and don't get arrested on the way, or the job fails."  (description, line 355)
- "Walk up to your contact and press E to take the parcel"  (text, line 357)
- "'Straight there. Don't open it. Don't be late.'"  (text, line 357)
- "Two Civil Protection units are checking papers at the corner ahead, and you're carrying the parcel."  (quest choice, line 358)
- "Walk past them, calmly."  (text, line 359)

> Note for you (not shown in game): part of: success

- "One of them looks right at you. Then past you. You're through."  (quest narration, line 360)

> Note for you (not shown in game): part of: fail

- "'Citizen! Stop!' You keep walking, and now you're wanted for carrying contraband."  (quest narration, line 362)
- "Carrying contraband"  (text, line 363)

> Note for you (not shown in game): part of: build

- "Take the long way, through the alleys."  (text, line 365)

> Note for you (not shown in game): part of: pick

- "Take the long way round: go to the marked spot first"  (quest step, line 366)

> Note for you (not shown in game): part of: build

- "Take the parcel to the dead drop {GetPos}"  (text, line 369)
- "The choice"  (title, line 378)
- "The Resistance wants to meet you in person this time ({where})."  (description, line 379)
- "Go to the meeting place ({where})"  (quest step, line 381)
- "Walk up to the stranger"  (text, line 382)
- "The stranger is waiting with two others. One of them wears the Resistance's lambda openly. 'Well? Are you with us?'"  (quest choice, line 383)
- "I'm with you. (You join the Resistance.)"  (text, line 384)
- "Not yet. But I'll help when I can. (You stay a citizen, as a friend of the Resistance.)"  (text, line 389)
- "I've changed my mind. (You turn them down.)"  (text, line 393)

> Note for you (not shown in game): part of: tail stage

- "your neighbor isn't out on the streets right now. Try again later, when the city is busier"  (text, line 419)
- "Follow your neighbor (marked) without being noticed"  (text, line 420)

> Note for you (not shown in game): part of: on enter

- "Follow your neighbor (marked) without being noticed. Don't fall too far behind, and stay out of {his} sight: the longer {he} sees you, the more suspicious {he} gets"  (text, line 428)

> Note for you (not shown in game): part of: on noticed

- "{He} stops and turns around. {He} has spotted you, and knows exactly who you are."  (text, line 433)
- "Pretend you were heading the other way."  (text, line 434)

> Note for you (not shown in game): part of: success

- "{He} shrugs and walks on. Keep following, but give {him} more room this time."  (text, line 436)

> Note for you (not shown in game): part of: fail

- "{He} doesn't believe you. {He} runs off, and the job has failed."  (text, line 440)

> Note for you (not shown in game): part of: on noticed

- "Confront {him}."  (text, line 444)

> Note for you (not shown in game): part of: pick

- "'You're one of them now? You?' {He} doesn't run. {He} just looks tired."  (text, line 446)
- "The Informant"  (name, line 455)
- "You took the double rations. Your neighbors have started saying good morning a little too carefully."  (text, line 462)
- "Your brother is released. He comes home thinner and quieter, and never asks how."  (text, line 463)
- "Now they're watching your brother too. Because of you."  (text, line 464)
- "You refused any reward. The city has no truer friend. The city does not have friends."  (text, line 465)

> Note for you (not shown in game): part of: build

- "Eyes and ears"  (title, line 472)
- "The Union wants you to keep watch {GetPos}, then report what you saw to Civil Protection."  (description, line 473)
- "Go to the marked lookout spot"  (quest step, line 475)
- "Stay near the spot for 15 seconds and watch who comes and goes"  (quest step, line 476)
- "Report what you saw: find any Civil Protection unit and press E on him"  (quest step, line 477)
- "Report your neighbor: find any Civil Protection unit and press E on him"  (quest step, line 484)

> Note for you (not shown in game): part of: on enter

- "Report {him}: find any Civil Protection unit and press E on the unit"  (text, line 485)

> Note for you (not shown in game): part of: on done

- "Civil Protection comes for your neighbor. By evening, {his} door is sealed with yellow tape."  (text, line 488)

> Note for you (not shown in game): part of: build

- "The neighbor"  (title, line 493)
- "Your neighbor has been keeping strange hours. The Union wants you to follow them without being seen, then report them to Civil Protection."  (description, line 494)
- "Collect your reward for informing {GetPos}."  (description, line 505)
- "Go to the marked spot to collect your payment"  (quest step, line 507)
- "Walk up to a Civil Protection officer and press E"  (quest step, line 508)
- "The officer slides a ration card across. 'Double rations. The Union appreciates its friends.'"  (quest choice, line 509)
- "Take the card."  (text, line 510)
- "Ask for your brother's release instead."  (text, line 515)

> Note for you (not shown in game): part of: success

- "A name is typed. Somewhere below your feet, a cell door opens: your brother is free."  (quest narration, line 522)

> Note for you (not shown in game): part of: fail

- "'Your brother? Interesting. We'll look into him too.'"  (quest narration, line 526)

> Note for you (not shown in game): part of: build

- "Refuse the reward. You did it for the city."  (text, line 528)

> Note for you (not shown in game): The Missing Unit

- "Lambda graffiti on the wall, the paint still wet, and drag marks leading toward the canals. Rebels took him."  (text, line 544)
- "Headcrab shells, cracked open. A lot of them. His stunstick is bent nearly in half. The infestation got him."  (text, line 545)
- "His mask is folded neatly on the ground, as if he took it off himself and didn't want it damaged. It looks like he deserted."  (text, line 546)
- "The Missing Civil Protection unit"  (name, line 550)
- "The radio is dead. For a while, the Resistance goes quiet too."  (text, line 556)
- "For a week, the Resistance follows your false orders. Overwatch notices your work."  (text, line 557)
- "You put 6-12 down yourself and file his tags with the others. Nobody asks how he died."  (text, line 558)
- "Overwatch cleans the area. They don't find him. You don't tell them where to look."  (text, line 559)
- "He's processed by morning. You never learn what happened to his daughter."  (text, line 560)
- "You let him go and report him killed in action. You'll never be sure that was a kindness."  (text, line 561)
- "6-12 made it to the Resistance. Somewhere in the canals, he's teaching rebels how Civil Protection units think."  (text, line 562)
- "6-12 got away. He's out there somewhere, and now he knows your face."  (text, line 563)

> Note for you (not shown in game): part of: build

- "Gone dark"  (title, line 574)
- "Unit 6-12 stopped answering dispatch {GetPos}. Go there and find out what happened to him."  (description, line 575)
- "Go to 6-12's last known position (marked)"  (quest step, line 577)
- "Search the area: find 2 of 6-12's belongings and press E on each"  (text, line 580)
- "Report it to your superiors."  (text, line 582)
- "Keep it quiet and look into it yourself."  (text, line 583)
- "What's left of him"  (title, line 597)
- "The trail leads into the infestation. Go in and find 6-12."  (description, line 598)
- "Go into the infestation (marked)"  (quest step, line 600)
- "Fight your way through: kill 3 zombies or headcrabs"  (quest step, line 601)
- "Among the zombies, a familiar uniform: it's 6-12, turned into one of them. His mask is still on."  (quest choice, line 602)
- "Put him down yourself."  (text, line 603)
- "Leave him for Overwatch to deal with."  (text, line 604)
- "Go into rebel territory (marked). Armed rebels will be waiting"  (quest step, line 610)

> Note for you (not shown in game): the people who took him are in there, and they're armed

- "The drag marks lead into rebel territory. Go in and stay inside for 45 seconds to search it. Armed rebels will fight you."  (description, line 615)
- "Stay alive inside rebel territory for 45 seconds while you search (the rebels know you're here)"  (text, line 618)

> Note for you (not shown in game): part of: build

- "You find his radio in a stairwell, still switched on. Someone has been listening to Civil Protection frequencies all week."  (quest choice, line 620)
- "Smash the radio."  (text, line 621)
- "Leave it on, and feed them false orders."  (text, line 622)

> Note for you (not shown in game): part of: fail

- "They stop transmitting the moment you touch it. The trick won't work now."  (quest narration, line 625)

> Note for you (not shown in game): part of: build

- "The man in the stolen coat"  (title, line 638)
- "A man in citizen's clothes with a Civil Protection haircut was seen {GetPos}. It might be 6-12."  (description, line 639)
- "Find the man in the stolen coat (marked) and walk up to him"  (text, line 641)
- "It's him: 6-12, in a stolen coat, his haircut already growing out. 'Please. I have a daughter in Block 4.'"  (quest choice, line 642)
- "Arrest him and bring him in."  (text, line 643)

> Note for you (not shown in game): part of: pick

- "Arrest him with the Arrest Baton (right click)"  (text, line 648)

> Note for you (not shown in game): part of: build

- "Let him go, and say nothing."  (text, line 651)
- "Help him reach the Resistance."  (text, line 657)

> Note for you (not shown in game): part of: success

- "Lead him to safety ({safe}). He follows you"  (text, line 661)

> Note for you (not shown in game): part of: fail

- "He doesn't trust you. He runs, and he's gone."  (quest narration, line 665)

> Note for you (not shown in game): Father Grigori's Flock

- "Father Grigori's Flock"  (name, line 683)
- "You forgave the informant. He weeps through the whole blessing, and never informs again."  (text, line 687)
- "You sent the informant away. He leaves without a word. The flock is smaller, and safer."  (text, line 688)
- "The informant talked, and your chapel is burned to ash by morning. You will find another. You always do."  (text, line 689)
- "You blessed the informant with the rest. If he reports you, he'll have to report that too."  (text, line 690)

> Note for you (not shown in game): part of: build

- "Lost sheep"  (title, line 695)
- "The city is full of frightened people. Speak with three citizens, then heal two wounded people with The Blessing."  (description, line 696)
- "Speak with 3 different citizens: walk up to each one and press E"  (quest step, line 698)
- "Heal 2 wounded people with The Blessing (left click on someone who is hurt)"  (quest step, line 699)
- "Hold a secret mass: stay at the chapel for 60 seconds, out of sight of Civil Protection"  (quest step, line 707)

> Note for you (not shown in game): they gather, face the priest, and stay for the service

- "The secret mass"  (title, line 724)
- "Gather the faithful for a secret mass ({where}). Pray quietly, pray quickly, and keep out of sight of Civil Protection."  (description, line 725)

> Note for you (not shown in game): part of: build

- "Go to the hidden chapel ({where})"  (quest step, line 727)
- "As the last hymn ends, you notice one of your flock quietly counting the others, like a man taking notes for Civil Protection. There's an informant among you."  (quest choice, line 729)
- "Work out which of them is the informant."  (text, line 730)

> Note for you (not shown in game): part of: success

- "You find him. He's young and frightened: they're holding his mother."  (quest choice, line 732)
- "Forgive him."  (text, line 733)
- "Send him away."  (text, line 734)

> Note for you (not shown in game): part of: fail

- "You can't tell which of them it is. By morning, Civil Protection knows everything, and you're wanted for unlawful worship."  (quest narration, line 738)
- "Unlawful worship"  (text, line 739)

> Note for you (not shown in game): part of: build

- "Bless them all, the informant too."  (text, line 742)

> Note for you (not shown in game): part of: tick

- "Boots on the stairs: Civil Protection saw the mass. You're wanted for unlawful worship."  (quest narration, line 753)
- "Unlawful worship"  (text, line 754)

> Note for you (not shown in game): The Overwatch Candidate

- "The Overwatch Candidate"  (name, line 767)
- "You accepted the conditioning. You don't remember your name. You don't need to."  (text, line 771)
- "You keep your name, your face, and the nightmares. Overwatch won't ask twice: you'll go no higher than Division Leader."  (text, line 772)

> Note for you (not shown in game): part of: build

- "Overwatch is judging whether you're fit for more. Hold a checkpoint for 90 seconds, then inspect three citizens. No mistakes."  (description, line 781)
- "Go to the marked checkpoint"  (quest step, line 783)
- "Stay at the checkpoint for 90 seconds while Overwatch observes you"  (quest step, line 784)
- "Inspect 3 different citizens (walk up to each one and press E)"  (quest step, line 785)
- "You've been ordered to report {GetPos}. Come alone."  (description, line 796)
- "Go to the marked spot as ordered"  (quest step, line 798)
- "A technician in a coat that has never been white. 'Transhuman conditioning. It will make you Overwatch. You won't remember your name, Civil Protection unit. You won't need to.'"  (quest choice, line 799)
- "Accept. (You become Overwatch: the Prison Guard, Soldier and Elite ranks open to you. There's no undoing it.)"  (text, line 801)
- "Decline. You like your name. (You'll rise no higher than Division Leader.)"  (text, line 805)

> Note for you (not shown in game): The Man Inside: honest, kind cops get an offer

- "Someone saw that, and they'll remember. Suspicion of you is growing."  (quest narration, line 823)
- "[Story] Too many people have seen you acting strangely. You have a feeling you're being watched."  (chat message, line 825)
- "The Man Inside"  (name, line 860)
- "You arrested her. She was processed by morning, and you were commended. You don't sleep well."  (text, line 866)
- "You joined the Resistance and burned your uniform in a canal barrel. They now have a fighter who knows exactly how Civil Protection units think."  (text, line 867)
- "You stay in Civil Protection as a Resistance spy. You still wear the mask, but now you know who you're wearing it for."  (text, line 868)
- "You walked away from both sides and never answer another note. Some nights you wonder."  (text, line 869)

> Note for you (not shown in game): part of: build

- "A note in your ration packet"  (title, line 876)
- "Someone slipped a note into your ration packet. It names a place, {GetPos}, and a time: now."  (description, line 877)
- "Go to the place named in the note (marked)"  (quest step, line 879)
- "Find whoever left the note (marked) and walk up to them"  (text, line 880)
- "A woman with the Resistance's lambda tattooed on the inside of her wrist. 'People talk about you, officer. The one who looks the other way. The one who says please.' She doesn't blink. 'We could use someone like that.'"  (quest choice, line 881)
- "Hear her out."  (text, line 883)

> Note for you (not shown in game): part of: pick

- "She talks fast and quiet. By the end, you know the names of three rebels, names you shouldn't know."  (quest narration, line 884)

> Note for you (not shown in game): part of: build

- "Arrest her."  (text, line 887)

> Note for you (not shown in game): part of: pick

- "Arrest her with the Arrest Baton (right click)"  (text, line 892)

> Note for you (not shown in game): part of: build

- "Pretend you never saw her."  (text, line 895)

> Note for you (not shown in game): part of: pick

- "You walk away. You keep the note."  (quest narration, line 898)

> Note for you (not shown in game): part of: build

- "Proof of good faith"  (title, line 910)
- "The Resistance wants proof you're on their side: free a prisoner from the cells and walk them to safety ({where}). Don't let another Civil Protection unit see you."  (description, line 911)
- "Go to the cells and press E on the marked prisoner to unlock their cell"  (text, line 913)
- "Lead the prisoner to safety ({where}). They follow you: act like it's routine"  (text, line 914)
- "A Civil Protection unit saw you walking a prisoner out of the block. He'll remember."  (text, line 917)
- "The crossroads"  (title, line 925)
- "The Resistance wants to meet you ({where}). Come out of uniform if you can. Come alone either way."  (description, line 926)
- "Go to the meeting place ({where})"  (quest step, line 928)
- "Find the woman from the note and walk up to her"  (text, line 929)
- "She's waiting with a man in a lambda armband who doesn't take his hand off his rifle. 'You've proven yourself. So: do you join us, or stay in Civil Protection where you can do the most good?'"  (quest choice, line 930)
- "Come over. Tonight. (You join the Resistance.)"  (text, line 932)
- "Stay inside. Be their eyes. (You stay in Civil Protection as their spy.)"  (text, line 937)

> Note for you (not shown in game): part of: pick

- "He finally lets go of the rifle. 'Then you never met us. Watch your job board (F3): we'll send you work there.'"  (quest narration, line 941)

> Note for you (not shown in game): part of: build

- "Walk away from all of it."  (text, line 943)

> Note for you (not shown in game): Inside Work: repeatable secret jobs for a double agent

- "Crouch at the dead drop for 4 seconds to leave the patrol schedule"  (quest step, line 960)
- "A Civil Protection unit watched you crouch by that drainpipe. He'll wonder why."  (text, line 962)

> Note for you (not shown in game): part of: ops

- "Leak the schedule"  (title, line 965)
- "Leave tomorrow's patrol routes at a Resistance dead drop {GetPos}. Don't let other units see you."  (description, line 966)
- "Go to the dead drop (marked)"  (quest step, line 967)

> Note for you (not shown in game): part of: stages

- "Find citizen {id} (marked) and press E to warn them before the raid"  (text, line 975)

> Note for you (not shown in game): part of: on done

- "They go pale, then they go. By the time the raid comes, the apartment is empty."  (quest narration, line 991)

> Note for you (not shown in game): part of: stages

- "Warn them first"  (title, line 995)
- "Citizen {id} is on tomorrow's raid list. Warn them before Civil Protection gets there, and be quick."  (description, line 996)
- "Another Civil Protection unit saw you whispering to someone on the list."  (text, line 998)

> Note for you (not shown in game): part of: tick

- "Lose the evidence"  (title, line 1008)
- "Evidence against a Resistance cell is lying {GetPos}. Collect it and take it to the Resistance instead of the evidence room."  (description, line 1009)
- "Find the 2 pieces of evidence and press E on each"  (text, line 1011)
- "Take the evidence to the marked spot ({where}), not to HQ"  (text, line 1012)
- "A Civil Protection unit saw you heading the wrong way with an evidence bag."  (text, line 1014)
- "A quiet release"  (title, line 1023)
- "Someone in the cells knows too much about the Resistance. Free them and walk them out before they're interrogated."  (description, line 1024)
- "Press E on the marked prisoner to open their cell"  (text, line 1026)
- "Lead the prisoner to the marked spot (they follow you). Act like it's routine paperwork"  (text, line 1027)
- "The desk officer is going to remember that release had no paperwork."  (text, line 1030)
- "Your sector report is due, and there was Resistance activity near the canals this week. Hand it in, and decide whether to cover for them."  (description, line 1040)
- "Go to the marked spot to file your sector report"  (quest step, line 1042)
- "Walk up to a Civil Protection officer and press E to hand in your report"  (quest step, line 1043)
- "The officer skims your report. 'Canals. Anything to note, Civil Protection unit?'"  (quest choice, line 1044)
- "Lie: the canals were quiet. Completely quiet."  (text, line 1045)

> Note for you (not shown in game): part of: success

- "He stamps it without looking up. The lie worked."  (quest narration, line 1046)

> Note for you (not shown in game): part of: fail

- "He reads it twice, then looks at you for a long moment. He doesn't believe you."  (text, line 1047)

> Note for you (not shown in game): part of: tick

- "Report it honestly. You can't risk it today."  (text, line 1048)

> Note for you (not shown in game): part of: pick

- "Because of your report, a Resistance cell in the canals has to move tonight. They'll understand. Probably."  (quest narration, line 1050)
- "Inside Work"  (name, line 1058)

> Note for you (not shown in game): Mole Hunt: when suspicion catches up with you

- "He picks up your file instead. 'Interesting.' You've been exposed as the mole."  (quest narration, line 1094)

> Note for you (not shown in game): Refused: the guards open up, and you go down bleeding on the cell floor. They don't let you die: you're carried out, and the Combine make a stalker of you (the owner, 2026-11-01).

- "[Loyalty test] {or} The guards raise their shotguns."  (chat message, line 1157)

> Note for you (not shown in game): a timer (regularly)

- "[Loyalty test] You're down on the cell floor, bleeding out. They don't let you die. Someone lifts you by the arms."  (chat message, line 1175)

> Note for you (not shown in game): part of: ltsetup

- "The Civil Protection unit in front of you is another player, and Internal Affairs is watching them. They've been told to get answers out of you, and then to finish you. Beg for your life, bargain, or refuse to say a word: it's up to you, and to them."  (on-screen notice, line 1218)
- "The prisoner is a player"  (on-screen notice, line 1220)
- "The prisoner in front of you is a real person, from the Resistance. Talk to them. Beat answers out of them, then finish it, or refuse."  (on-screen notice, line 1220)
- "[Loyalty test] The cell door shuts behind you. Your weapons are on a table outside. A guard either side of you, shotguns held low."  (chat message, line 1254)

> Note for you (not shown in game): a hand raised to a guard: that's the answer

- "You turn on the guard."  (text, line 1267)

> Note for you (not shown in game): No ignoring it: after the loyalty test, the reckoning starts by itself, and so does the debt (the owner: the Resistance would want answers). Whatever job they're on is dropped for it. The soldier conversion, forced: the transhuman conditioning and the Soldier rank, for good.

- "the conversion"  (text, line 1302)
- "The conversion"  (on-screen notice, line 1303)
- "You proved your loyalty, so Overwatch wants all of you. They come for you that night: the surgery is done before you wake. A soldier now, and there's no going back."  (on-screen notice, line 1303)

> Note for you (not shown in game): part of: force mole hunt

- "The Resistance wants answers"  (on-screen notice, line 1327)
- "The debt starts now. They're watching."  (on-screen notice, line 1327)
- "Overwatch wants proof. A sweep team is waiting for you."  (text, line 1327)
- "A note in your locker: they know what you did in that cell. They want to see you, now."  (text, line 1327)

> Note for you (not shown in game): with Resistance players in the city, the test waits for one of them to be caught (the owner: a real person in the chair); the units go looking meanwhile. Otherwise, or if nobody's caught in time, an NPC.

- "Internal Affairs is bringing a Resistance prisoner in. Carry on, and wait to be called to the cells"  (quest step, line 1352)
- "Report to the cells (marked)"  (quest step, line 1353)
- "The loyalty test"  (title, line 1355)
- "Internal Affairs has a prisoner from the Resistance, and a question about you.{GetPos}"  (description, line 1356)

> Note for you (not shown in game): part of: test spec

- "The prisoner looks up at you through one swollen eye. The guard on your left speaks without looking at you: 'He knows who the mole is. Get it out of him. Then finish it.' The other guard's shotgun is pointed at the floor. For now."  (quest choice, line 1360)
- "Interrogate him. With your fists."  (text, line 1362)

> Note for you (not shown in game): part of: pick

- "You close your fists. He knows what's coming."  (quest narration, line 1365)
- "Beat answers out of him (punch him, 6 times)"  (quest step, line 1367)
- "He's told you everything he will. Finish it: kill him"  (quest step, line 1368)

> Note for you (not shown in game): part of: test spec

- "Refuse. You won't do it."  (text, line 1371)

> Note for you (not shown in game): part of: pick

- "You lower your hands."  (text, line 1371)

> Note for you (not shown in game): waiting for a real prisoner: the first Resistance player in a cell; or, out of time, an NPC

- "Dispatch: Internal Affairs wants a member of the Resistance taken alive and put in the cells."  (text, line 1380)

> Note for you (not shown in game): after the beating, the last of it

- "He gives you a name. It's yours, though he doesn't know it. Then nothing more. 'Finish it,' says the guard."  (quest narration, line 1401)

> Note for you (not shown in game): leaving the cell is refusing

- "You try to leave."  (text, line 1404)

> Note for you (not shown in game): you killed one of theirs: the Resistance wants a word (the reckoning, next on your board)

- "[Loyalty test] The guard lowers his shotgun. 'Welcome back, officer.' Your weapons are handed back at the door."  (chat message, line 1416)
- "You took too long."  (text, line 1419)
- "Mole Hunt"  (name, line 1427)
- "You passed their test. The prisoner's blood is on your hands, and nobody in Civil Protection doubts you now."  (text, line 1431)
- "You let the Combine have all of you. The surgery took the rest: a soldier of Overwatch now, and nothing you were before. There's no going back."  (text, line 1432)
- "The debt is paid. They don't forget what you did in that cell, but they let you back in. The Resistance has its man inside again."  (text, line 1433)
- "You wouldn't do it. The guards did their duty. They found the mole, in the end."  (text, line 1434)
- "You wouldn't do it. They shot you down on the cell floor and didn't let you die. What's left of you belongs to the Combine now."  (text, line 1435)
- "You took off the mask for good. No more lies: you fight with the Resistance in the open now, and Civil Protection will never have you back."  (text, line 1436)
- "Unit 3-09 was taken in your place. You tell yourself he probably deserved it."  (text, line 1437)
- "You fled to the Resistance before they could knock. Every Civil Protection unit in the city has your face now."  (text, line 1438)
- "The mole hunt moves on to another sector. You breathe again. Carefully."  (text, line 1439)
- "Exposed as the mole, you're stripped of rank and mask. A citizen again, with a file that will never close."  (text, line 1440)

> Note for you (not shown in game): after the loyalty test: you killed one of theirs, and the Resistance knows

- "The reckoning"  (title, line 1448)
- "Word reaches you through a note in your locker: the Resistance knows what you did in that cell. They want to see you ({where}). Until this is settled, they won't work with you."  (description, line 1449)
- "Go to the meeting place ({where})"  (quest step, line 1451)

> Note for you (not shown in game): part of: build

- "Find the woman from the note and walk up to her"  (text, line 1452)
- "She doesn't sit down. 'He was one of ours. You beat him, and then you killed him, to keep your mask. Maybe you had to.' Her hand doesn't leave her pocket. 'We want answers. Are you still with us? Then you'll pay for him. Or are you theirs now?'"  (quest choice, line 1453)
- "Pay the debt. Whatever it takes. (It starts at once.)"  (text, line 1455)

> Note for you (not shown in game): part of: pick

- "'Then listen.' She tells you what it will cost."  (quest narration, line 1456)

> Note for you (not shown in game): part of: build

- "Take off the mask for good: leave Civil Protection and fight with the Resistance in the open. (You'll never be a unit, or anyone's man inside, again.)"  (text, line 1459)
- "Tell her you're done with the Resistance. (You stay with the Combine. They'll want proof, and then all of you.)"  (text, line 1465)

> Note for you (not shown in game): part of: pick

- "You walk out. Before morning, Overwatch has orders for you: they want proof."  (quest narration, line 1469)

> Note for you (not shown in game): done with the Resistance: the Combine want proof first. In with a sweep team, two of their fighters down, and then the conversion (the owner: they'd push you further before they took all of you)

- "Join the sweep team at the edge of anticitizen territory (marked)"  (quest step, line 1487)

> Note for you (not shown in game): part of: build

- "You told the Resistance you're done with them. Overwatch wants proof: go in with the sweep team on their ground {GetPos}, and put down two of their fighters."  (description, line 1492)
- "Take down two of the Resistance's fighters there"  (quest step, line 1495)

> Note for you (not shown in game): the blood debt: a life for a life, out of the cells

- "A blood debt"  (title, line 1515)
- "A life for a life: get one of theirs out of the cells and walk them to safety ({where}). Don't let another Civil Protection unit see you."  (description, line 1516)

> Note for you (not shown in game): part of: build

- "Go to the cells and press E on the marked prisoner to unlock their cell"  (text, line 1518)
- "Lead the prisoner to safety ({where}). They follow you: act like it's routine"  (text, line 1519)
- "A Civil Protection unit saw you walking a prisoner out. He'll remember."  (text, line 1522)
- "A blood debt"  (title, line 1530)
- "Make it right: what Civil Protection seized from the Resistance this week is lying {GetPos}. Get it back to them ({where})."  (description, line 1531)
- "Find the 3 seized crates and press E on each"  (text, line 1533)
- "Take them to the Resistance ({where})"  (text, line 1534)
- "A Civil Protection unit saw you heading the wrong way with seized goods."  (text, line 1536)

> Note for you (not shown in game): the loyalty test, in the cells; a map with no cells has the briefing instead

- "The briefing"  (title, line 1549)
- "Internal Affairs believes there's a mole in your division, and wants your help finding them. The mole is you."  (description, line 1550)

> Note for you (not shown in game): part of: build

- "Go to the marked spot for the briefing"  (quest step, line 1552)
- "Walk up to the Internal Affairs officer"  (text, line 1553)
- "The officer spreads three files across the hood of an APC. One of them is yours. He hasn't noticed. Yet."  (quest choice, line 1554)
- "Steer him toward another Civil Protection unit's file, so they take the blame."  (text, line 1555)
- "Excuse yourself. Run to the Resistance tonight (you'll be wanted for desertion)."  (text, line 1562)
- "Keep your head down and ride it out."  (text, line 1568)

## survival (sv_livingcity_survival.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_survival.lua`


> Note for you (not shown in game): Can they take n more of this? ok, or false and why.

- "Your pockets are full."  (text, line 134)

> Note for you (not shown in game): part of: can carry

- "You've no room for something that size."  (text, line 145)
- "That's more than you can carry."  (text, line 148)

> Note for you (not shown in game): Give an item, or drop it at their feet if their pockets are full.

- "Your pockets are full. {id} is on the ground."  (chat message, line 210)

> Note for you (not shown in game): part of: infect

- "Your stomach turns. Something in that wasn't clean."  (chat message, line 233)

> Note for you (not shown in game): a timer (regularly)

- "You're getting hungry."  (text, line 273)
- "You're starving."  (text, line 273)
- "Your mouth is dry."  (text, line 274)
- "You're badly dehydrated."  (text, line 274)
- "You are starving and dehydrated."  (chat message, line 286)
- "You are starving."  (text, line 286)
- "You are dehydrated."  (text, line 286)

> Note for you (not shown in game): part of: breen water

- "Where were you going again?"  (chat message, line 334)

> Note for you (not shown in game): food mends you a little as you eat it (a quarter of what it fills you); drinks don't. Healing comes from eating, sleeping and medicine, nothing else (no slow mending while awake)

- "The cramps ease."  (chat message, line 353)

> Note for you (not shown in game): part of: consume

- "It burns all the way down. Your legs go out from under you."  (chat message, line 359)

> Note for you (not shown in game): part of: inv action

- "Your hands are cuffed."  (chat message, line 485)
- "You need to be standing in water."  (chat message, line 511)
- "You can't eat that."  (chat message, line 517)
- "Cooking won't help that."  (chat message, line 521)
- "You need a stove or a fire."  (chat message, line 522)

> Note for you (not shown in game): a crackle and sizzle (the ignite sound was a small bang). Half-Life 2's fire sounds loop forever, so it's stopped after a moment (it used to keep crackling wherever you went)

- "becomes {name}."  (chat message, line 530)
- "Stand in water, or by a sink, to fill it."  (chat message, line 533)

> Note for you (not shown in game): the tap running into it (a splash was too loud for a sink); dipped in water, a soft slosh

- "[Papers] You keep your papers on you. (Stash them at home if you must.)"  (chat message, line 540)
- "That's Combine issue: it stays with you (or another unit)."  (chat message, line 541)

> Note for you (not shown in game): pressing E on something

- "Picked up: {name}"  (chat message, line 591)
- "Your pockets are full."  (chat message, line 593)

> Note for you (not shown in game): the game's physgun drop moment

- "[Living City] Moved: the {kind} is saved where you put it."  (chat message, line 883)

> Note for you (not shown in game): part of: use vending

- "[Vending] Insert {price} credits."  (chat message, line 899)

> Note for you (not shown in game): part of: use static vending

- "[Vending] Insert {price} credits."  (chat message, line 946)

> Note for you (not shown in game): part of: use fixture

- "[Stove] Cook from your pockets (F2). Your stash is open there too, while you stand by the stove."  (chat message, line 967)
- "[Stove] Cook from your pockets (F2)."  (chat message, line 967)
- "[Sink] Fill bottles and cans from your pockets (F2). Boil them before you drink."  (chat message, line 971)

> Note for you (not shown in game): part of: dispense

- "[Rations] The clerk at the counter hands you a ration packet."  (chat message, line 1040)
- "[Rations] The clerk hands you a short ration: a third less than the full one. Good standing (Trusted) earns the full packet."  (chat message, line 1041)

> Note for you (not shown in game): Hacking them (the multitool): a vending machine spits out its water, a ration dispenser its packets (5 to 8 of them), no credits and no coupon. Ten seconds, keep still; a unit who sees you at it makes you wanted. Then it's empty for lc_machine_hack_cooldown minutes (10).

- "the vending machine"  (text, line 1052)
- "the ration dispenser"  (text, line 1052)
- "Aim at a vending machine or a ration dispenser."  (text, line 1055)
- "You need a multitool to get into it."  (text, line 1056)
- "You're busy."  (text, line 1057)
- "It's dead: no power. Nothing to get out of it."  (text, line 1058)

> Note for you (not shown in game): part of: hack machine

- "Someone's already emptied it. It'll be restocked in about %d minutes."  (message, line 1061)
- "Hacking {name}... keep still"  (progress bar, line 1065)
- "You leave it."  (text, line 1066)

> Note for you (not shown in game): part of: done

- "[Resistance] The dispenser chokes, and spits out %d ration packets. No coupon, no record."  (message, line 1087)
- "[Resistance] The machine shudders and drops %d cans. Free water, for once."  (message, line 1088)
- "Tampering with Union property"  (text, line 1090)
- "[Civil Protection] A Civil Protection unit saw you at it."  (chat message, line 1091)

> Note for you (not shown in game): ent may be nil: a line with no dispenser placed at its front.

- "[Rations] You aren't registered, so you can't have a ration card. Register at Civil Intake, then work a Union shift to earn one."  (text, line 1105)
- "[Rations] No ration card. You earn one for each Union shift you finish (your board, F3), and each ration takes one card."  (text, line 1107)

> Note for you (not shown in game): part of: use dispenser

- "[Rations] Your ration privileges have been suspended."  (text, line 1109)
- "[Rations] Next allocation in %d seconds."  (message, line 1111)

> Note for you (not shown in game): a reprimand (skipping morning exercise: sv_livingcity_exercise.lua): this one allocation

- "[Rations] Allocation withheld: {why}. Your next allocation is as normal."  (text, line 1117)

> Note for you (not shown in game): the PA said it: tolerating noncompliance costs this allocation (sv_livingcity_rations.lua)

- "[Rations] Allocation withheld: five ration units deducted for tolerating noncompliance{why}. Your next allocation is as normal."  (text, line 1124)

> Note for you (not shown in game): the city's stores (sv_livingcity_stockpile.lua): empty, nothing; low, sometimes nothing

- "[Rations] Distribution suspended: the city's stores are empty."  (text, line 1131)
- "[Rations] Supply shortfall. The dispenser whirs and gives nothing. Try again in a minute (the stores are low: kitchen and factory shifts, trains and supply drops fill them)."  (text, line 1134)

> Note for you (not shown in game): a forged card: no questions, usually

- "[Rations] Card invalid. This incident has been logged."  (chat message, line 1143)
- "Ration fraud"  (text, line 1144)

> Note for you (not shown in game): part of: use dispenser

- "[Rations] Card accepted."  (chat message, line 1147)

> Note for you (not shown in game): part of: serve players at line

- "[Rations] Wait at the counter."  (chat message, line 1182)

## talking to people (sv_livingcity_talk.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_talk.lua`


> Note for you (not shown in game): Who you are to them: this character of yours, not just your account.

- "\|{GetNW2String}"  (text, line 49)

> Note for you (not shown in game): part of: mood word

- "glad to see you"  (text, line 80)
- "terrified of you"  (text, line 82)
- "wary of you"  (text, line 83)

> Note for you (not shown in game): A sympathizer who likes you: where the Resistance gathers.

- "out past the checkpoints"  (text, line 128)

> Note for you (not shown in game): part of: safe house hint

- "If you're looking for people who think like you, they're {where}. Ask for the quartermaster."  (text, line 129)
- "'Another day. Keep your head down and it's another day.'"  (text, line 133)
- "'The water tastes of something again.'"  (text, line 133)
- "'They moved the line again this morning. Nobody knows why.'"  (text, line 134)
- "'I don't sleep much. Nobody does.'"  (text, line 134)
- "'Have you seen my neighbour? Since Tuesday, nobody has.'"  (text, line 135)
- "'The trains are always full coming in. Never going out.'"  (text, line 135)
- "'Don't stand under the scanners. They don't like it.'"  (text, line 136)
- "'They say the rations will be bigger next month. They always say that.'"  (text, line 136)
- "They won't look at you."  (text, line 138)
- "They step back, hands up: 'I don't want any trouble.'"  (text, line 138)
- "'Please. Just leave me alone.'"  (text, line 138)

> Note for you (not shown in game): part of: doing

- "waiting in the ration line"  (text, line 152)

> Note for you (not shown in game): part of: share food

- "They take the {name} with both hands. 'I won't forget this. I mean it.'"  (name, line 236)
- "They take the {name} and hide it in their coat. 'Thank you.'"  (name, line 237)

> Note for you (not shown in game): part of: pick pocket

- "Their pockets are already empty."  (text, line 250)
- "Your fingers come out with {item}. They didn't feel a thing."  (text, line 258)
- "%d credits, and they didn't feel a thing."  (message, line 263)

> Note for you (not shown in game): caught

- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 270)

> Note for you (not shown in game): part of: pick pocket

- "They feel your hand and spin round. 'Thief! Get away from me!'"  (text, line 276)

> Note for you (not shown in game): part of: inform

- "You reported someone a moment ago. Don't push your luck."  (text, line 280)
- "You give their name to a Civil Protection unit. He writes it down. (+15 standing) They'll be picked up."  (text, line 294)
- "You give their name to a Civil Protection unit. He checks it and looks at you instead. 'Waste of time.' (-5 standing)"  (text, line 298)

## territory that spreads, and is pushed back (sv_livingcity_territory.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_territory.lua`


> Note for you (not shown in game): a timer (regularly)

- ", and elsewhere"  (text, line 364)
- "We've taken more ground {list}. Hold it."  (text, line 366)
- "Dispatch: anticitizen activity spreading {list}. Civil Protection units are advised to push it back."  (text, line 367)
- "Dispatch: infestation spreading {list}. Containment teams required."  (text, line 369)

> Note for you (not shown in game): part of: grow territory

- "it's as big as it gets (lc_territory_max)"  (text, line 408)
- "nowhere to grow"  (text, line 411)

> Note for you (not shown in game): someone moves in

- "Territory: %s grew at %s (r %d), %d patches now"  (message, line 424)

> Note for you (not shown in game): by: the player whose work it was, if any. The whole city hears who did it.

- "somewhere in the city"  (text, line 458)

> Note for you (not shown in game): part of: recede territory

- "Dispatch: {who} has retaken anticitizen ground{place}."  (text, line 462)
- "Dispatch: anticitizen ground{place} is retaken."  (text, line 462)
- "We've lost the ground{place}."  (text, line 463)
- "Dispatch: {who} has contained the infestation{place}."  (text, line 465)
- "Dispatch: infestation{place} is contained."  (text, line 465)
- "has retaken ground from the Resistance{place}."  (text, line 468)
- "has contained the infestation{place}."  (text, line 469)
- "[City] {line}"  (chat message, line 470)

> Note for you (not shown in game): a patch with nobody left in it falls straight away

- "cleared out"  (text, line 526)

> Note for you (not shown in game): a timer (regularly)

- "pushed back"  (text, line 530)

> Note for you (not shown in game): part of: pay containment

- "+{credits} credits"  (text, line 559)
- "{ammo} rounds"  (text, line 565)
- "[Civil Protection] Containment pay: %d infested put down. %s."  (message, line 570)

> Note for you (not shown in game): Commands

- "[Living City] No rebel or infestation zones placed."  (chat message, line 642)

> Note for you (not shown in game): the console command lc_territory

- "[Living City] %s at %s: %d patch%s grown, next growth in %ds, %d hit%s since the last push-back"  (message, line 645)

> Note for you (not shown in game): the console command lc_territory_grow

- "[Living City] Usage: lc_territory_grow rebel\|infest"  (chat message, line 654)
- "[Living City] No {kind} zones placed."  (chat message, line 657)
- "[Living City] Grew {kind} territory {or}"  (text, line 659)
- "[Living City] Couldn't grow: {why}"  (text, line 659)

> Note for you (not shown in game): the console command lc_territory_reset

- "[Living City] Took back {n} grown patch{or}. Only the zones you placed are left."  (chat message, line 670)

## the trains (sv_livingcity_trains.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_trains.lua`

- "the coast"  (text, line 26)
- "the industrial district"  (text, line 26)
- "the outlands transfer"  (text, line 26)
- "Nova Prospekt processing"  (text, line 26)

> Note for you (not shown in game): part of: train arrive

- "at the station"  (text, line 73)
- "[Station] The train from {from} has arrived {where}."  (chat message, line 75)
- "[Union] A train is in. Arrivals on the platform: your shift."  (chat message, line 76)

> Note for you (not shown in game): through Civil Intake first, in line with everyone else, if the city has it (sv_livingcity_intake.lua)

- "just off the train, carrying a suitcase"  (what someone is doing, line 91)
- "just off the train"  (text, line 93)

## the underground (sv_livingcity_underground.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_underground.lua`


> Note for you (not shown in game): A d20 check: a natural 20 always works, a natural 1 never does.

- "somewhere in the city"  (text, line 66)

> Note for you (not shown in game): Radios

- "Union band"  (text, line 78)

> Note for you (not shown in game): part of: radio notice

- "[{name}] *static* {text}"  (chat message, line 110)
- "[{name}] {text}"  (chat message, line 112)
- "[Intercept] {text}"  (chat message, line 114)

> Note for you (not shown in game): part of: radio say

- "You don't have a radio."  (text, line 147)
- "Nobody talks on the Union band: it's the city's, for listening."  (text, line 148)
- "Your radio only listens. To talk on Freq 7 you need a radio transmitter (black market, or the Resistance lab) and a Freq 7 radio."  (text, line 150)
- "Your radio was taken when you were processed."  (text, line 153)
- "Your transmitter isn't on that band."  (text, line 154)
- "Static. Something nearby is jamming the band."  (text, line 155)
- "Say what?"  (text, line 157)

> Note for you (not shown in game): part of: radio raised say

- "[Radio] {why}"  (chat message, line 190)
- "(into a radio): {t}"  (chat message, line 193)

> Note for you (not shown in game): typing in chat

- "[Radio] {why}"  (chat message, line 236)

> Note for you (not shown in game): City notices reach radios before the loudspeakers.

- "ration distribution"  (text, line 241)
- "civil status inspections"  (text, line 241)
- "a housing block inspection"  (text, line 241)
- "Civil Protection units are gearing up for a sweep. Move anything you don't want found."  (text, line 243)
- "Curfew's coming. Get where you need to be."  (text, line 244)
- "Lockdown incoming. Get off the street."  (text, line 245)
- "Civil Protection units are about to go through a housing block. Anything they find is traced to whoever it belongs to."  (text, line 246)
- "A Combine convoy is coming through. Lots of crates, not many guards."  (text, line 247)

> Note for you (not shown in game): the Union band only announces the routine ones; the rest are surprises

- "Notice: %s begins in %d seconds."  (message, line 254)

> Note for you (not shown in game): a timer (regularly)

- "Dispatch: all units, suspect %s, %s. Last seen %s."  (message, line 267)
- "citizen {alias}"  (text, line 268)

> Note for you (not shown in game): the game's living city incarcerated moment

- "Dispatch: suspect {Nick} in custody."  (text, line 274)

> Note for you (not shown in game): part of: take off

- "You change back into your own clothes."  (chat message, line 327)

> Note for you (not shown in game): part of: blow disguise

- "[Disguise] {why} Your disguise is blown."  (chat message, line 335)
- "Impersonating a Civil Protection officer"  (text, line 338)

> Note for you (not shown in game): filthy clothes: spare citizen clothes are just clean clothes (sv_livingcity_hygiene.lua)

- "You're already in disguise. Take it off first."  (text, line 358)
- "Not now."  (text, line 359)
- "Not in the middle of a fight."  (text, line 360)
- "You don't need a disguise to be a Civil Protection unit."  (text, line 361)
- "You're one of them already. (!gearup puts your own gear on.)"  (text, line 362)

> Note for you (not shown in game): part of: wear

- "A Civil Protection unit watched you change."  (text, line 375)
- "[Disguise] You're a Civil Protection unit now, as far as anyone on the street can tell. Don't fight, don't linger near real units, and stay away from Combine doors unless you're feeling lucky."  (chat message, line 380)
- "[Disguise] Resistance colours. The fighters in rebel territory will take you for one of them, for a while. Out on the streets, Civil Protection units will take you for one of them too."  (chat message, line 382)
- "[Disguise] Plain clothes. You're just another citizen. Keep your gun out of sight: a Civil Protection unit who sees it will know. (F1 > Gear up to change back.)"  (chat message, line 384)
- "[Disguise] Union blue, like everyone else. Nobody looks twice at a citizen. Until they check your face."  (chat message, line 386)

> Note for you (not shown in game): part of: disguise door check

- "The door reads your biosignal and sounds an alarm."  (text, line 403)

> Note for you (not shown in game): Any new crime blows a CP disguise; hunted Resistance get recognized.

- "Civil Protection units don't do that."  (text, line 411)
- "Someone recognized you."  (text, line 413)

> Note for you (not shown in game): Hanging around real units is the risky part.

- "A Civil Protection unit asks for your designation. You give one that doesn't exist."  (text, line 419)
- "A Civil Protection unit tries to sync with your mask radio. There's nothing to sync with."  (text, line 420)
- "A Civil Protection unit looks at your boots for a long second. They're civilian issue."  (text, line 421)

> Note for you (not shown in game): A gun in your hand gives plain clothes away.

- "A Civil Protection unit saw the gun in your hand."  (text, line 431)

> Note for you (not shown in game): A Combine plant in Resistance colours gets asked questions.

- "A fighter asks who vouched for you. You give a name. Nobody knows it."  (text, line 439)
- "Someone asks which cell you're from. You hesitate a moment too long."  (text, line 440)
- "A fighter looks at your boots. Civil Protection issue."  (text, line 441)

> Note for you (not shown in game): part of: assume identity

- "Not now."  (text, line 491)
- "Not with a Civil Protection unit watching."  (text, line 492)
- "[Papers] As far as the city knows, you're citizen %s now. Nobody is looking for %s."  (message, line 501)
- "[Papers] Your face is still on the notices, though. Citizen clothes would help."  (chat message, line 503)

> Note for you (not shown in game): (a face the lab changed isn't on any notice: sv_livingcity_lab.lua)

- "Your face matches a wanted notice."  (text, line 514)
- "Your papers don't hold up to a close look."  (text, line 518)

> Note for you (not shown in game): part of: papers failed

- "Your papers don't check out."  (text, line 524)
- "[Civil Protection] {why}"  (chat message, line 530)
- "Forged identity papers"  (text, line 532)
- "Wanted anticitizen"  (text, line 532)

> Note for you (not shown in game): part of: curfew excuse

- "[Civil Protection] The Civil Protection unit checks your permit and stamps it. You're cleared until this is over."  (chat message, line 544)
- "[Civil Protection] Your papers say night shift. The Civil Protection unit waves you on."  (chat message, line 552)

> Note for you (not shown in game): searcher: a unit (player) or a security NPC.

- "Hands on, the uniform is obviously a costume."  (text, line 622)

> Note for you (not shown in game): part of: search

- "Search complete. Nothing found."  (chat message, line 632)
- "[Search] {Nick} is clean."  (chat message, line 633)
- "Confiscated: {list}."  (chat message, line 639)
- "Contraband confiscated"  (text, line 640)
- "Possession of contraband"  (text, line 641)
- "[Search] {Nick} was carrying: {list}. Confiscated."  (chat message, line 643)
- "Contraband seized"  (text, line 644)
- "seizure bonus"  (text, line 645)

> Note for you (not shown in game): A unit searches the person in front of them: three seconds of standing still. What a citizen on the street might be carrying. Sympathizers are far likelier to have something.

- "a Resistance pamphlet"  (text, line 655)
- "an unregistered radio"  (text, line 655)
- "black market rations"  (text, line 655)
- "a crowbar wrapped in newspaper"  (text, line 655)
- "a lambda armband"  (text, line 656)
- "forged ration coupons"  (text, line 656)
- "a handful of pistol rounds"  (text, line 656)

> Note for you (not shown in game): A unit patting down an NPC citizen: they stop, hands out, and after a few seconds you hear what was on them.

- "You can only search citizens."  (text, line 663)
- "Not now."  (text, line 664)
- "Get closer."  (text, line 665)
- "You searched them a moment ago."  (text, line 667)
- "They're already being searched."  (text, line 668)

> Note for you (not shown in game): part of: search npc

- "[Search] Patting them down..."  (chat message, line 679)

> Note for you (not shown in game): a timer (regularly)

- "[Search] Found {contraband}. Confiscated. Right click with the baton to detain them."  (chat message, line 687)
- "[Search] Nothing on them. Papers in order."  (chat message, line 691)

> Note for you (not shown in game): part of: start search

- "Only Civil Protection units can search people."  (text, line 700)
- "Search who?"  (text, line 703)
- "Only Civil Protection units can search people."  (text, line 704)
- "Not now."  (text, line 705)
- "You don't search other Civil Protection units."  (text, line 706)
- "Get closer."  (text, line 707)
- "They're already being searched."  (text, line 708)
- "They were searched a moment ago."  (text, line 710)
- "[Civil Protection] {Nick} is searching you. Stay still."  (chat message, line 714)
- "[Search] Searching {Nick}..."  (chat message, line 715)

> Note for you (not shown in game): a timer (regularly)

- "[Search] {Nick} walked away."  (chat message, line 723)
- "Evading a search"  (text, line 724)

> Note for you (not shown in game): typing in chat

- "[Search] {why}"  (chat message, line 736)

> Note for you (not shown in game): Processing: anything illegal on you when you're arrested is gone.

- "[Processing] Confiscated: {found}."  (chat message, line 746)

> Note for you (not shown in game): part of: start stop

- "[Civil Protection] Hold it right there. Stand still for inspection."  (chat message, line 798)

> Note for you (not shown in game): part of: evaded

- "Hold it! Get back here!"  (text, line 811)
- "[Civil Protection] You walked away from an inspection."  (chat message, line 812)
- "Evading inspection"  (text, line 813)

> Note for you (not shown in game): a model citizen: a glance at the papers, no search (sv_livingcity_loyalty.lua)

- "[Civil Protection] Papers in order. A model citizen: the unit waves you on without a search."  (chat message, line 829)

> Note for you (not shown in game): part of: run stops

- "[Civil Protection] Papers. Arms out."  (chat message, line 856)

> Note for you (not shown in game): part of: start pick

- "Not now."  (text, line 944)
- "You're already working on a lock."  (text, line 945)
- "Look at a locked door, up close."  (text, line 949)
- "There's no card reader on that door."  (text, line 953)

> Note for you (not shown in game): (the old cell locks are mechanical underneath: from the inside, with time, a pick will do)

- "That's a Combine lock. A pick won't touch it."  (text, line 956)
- "It isn't locked."  (text, line 958)
- "It's already open."  (text, line 959)
- "Swiping the card..."  (text, line 962)
- "Working the lock... keep looking at it"  (text, line 962)

> Note for you (not shown in game): a guard was watching the whole time

- "[Civil Protection] A guard takes the pick off you. Two more minutes for the trouble."  (chat message, line 1005)

> Note for you (not shown in game): part of: finish pick

- "Your pick snaps in the lock."  (chat message, line 1012)
- "The lock won't give. Try again."  (chat message, line 1014)
- "Tampering with Combine technology"  (text, line 1023)
- "You punch in the code. The reader blinks green: they'll have changed it by tomorrow."  (chat message, line 1028)
- "The reader blinks green. The card won't work twice."  (text, line 1028)
- "The lock gives."  (text, line 1028)
- "Unauthorized use of a Civil Protection keycard"  (text, line 1030)
- "Breaking and entering"  (text, line 1030)

> Note for you (not shown in game): a timer (regularly)

- "You stop working on the lock."  (text, line 1044)

> Note for you (not shown in game): Forging papers

- "Not with someone watching. Get out of sight first."  (text, line 1061)
- "Not with a Civil Protection unit watching."  (text, line 1062)

> Note for you (not shown in game): part of: forge

- "[Papers] Name, number, stamp. It looks right. It has to."  (chat message, line 1066)
- "[Papers] The ink bleeds across the number. The form is ruined."  (chat message, line 1069)

> Note for you (not shown in game): part of: stash store

- "Your stash is at home, in your own block."  (text, line 1122)
- "That's Combine issue: it stays with you (or another unit)."  (text, line 1124)
- "Your stash is full."  (text, line 1125)

> Note for you (not shown in game): part of: stash take

- "Your stash is at home, in your own block."  (text, line 1134)

> Note for you (not shown in game): part of: stash store weapon

- "Your stash is at home, in your own block."  (text, line 1163)
- "That was issued to you. It stays with you."  (text, line 1166)
- "Your stash is full."  (text, line 1167)
- "You hide the {cls} away."  (text, line 1179)

> Note for you (not shown in game): part of: stash take weapon

- "Your stash is at home, in your own block."  (text, line 1183)
- "You've one of those on you already."  (text, line 1187)

> Note for you (not shown in game): the game's living city event started moment

- "[Civil Protection] Your residence%s was searched. Confiscated: %s."  (message, line 1215)
- "in {home}"  (text, line 1216)
- "Contraband found in your residence"  (text, line 1217)

> Note for you (not shown in game): typing in chat

- "[Stash] Your stash is at home, in {or}: press E on a stove, fridge, dresser or wardrobe there."  (chat message, line 1227)
- "Overwatch doesn't shop."  (text, line 1251)
- "The Administrator has people for this."  (text, line 1251)

> Note for you (not shown in game): What the quartermaster won't buy: the lab decodes it (sv_livingcity_heist.lua, sv_livingcity_lab.lua)

- "Nobody here sells anything to a Civil Protection unit."  (text, line 1256)

> Note for you (not shown in game): part of: market access

- "Find the dealer."  (text, line 1264)
- "There's no black market here. Try rebel territory, or ask an admin to place a dealer."  (text, line 1265)

> Note for you (not shown in game): part of: open market

- "[Black market] {why}"  (chat message, line 1271)

> Note for you (not shown in game): the quartermaster (and no dealer here): he won't buy the Combine's data; the lab decodes it

- "Not enough credits"  (text, line 1281)
- "Too much to carry"  (text, line 1282)

> Note for you (not shown in game): At the quartermaster: a chip decoded, from his menu.

- "[Quartermaster] {why}"  (chat message, line 1310)
- "[Quartermaster] He plugs it into a battered laptop and reads. 'This is good. Get the word out.'"  (chat message, line 1311)

> Note for you (not shown in game): part of: black buy

- "Not enough credits."  (text, line 1340)
- "[Black market] %s, for %d credits. You didn't get it here."  (message, line 1344)

> Note for you (not shown in game): Sell one of something (or all of it): pocket items, or a weapon as "w:<class>".

- "That was issued to you. The dealer doesn't want it."  (text, line 1356)

> Note for you (not shown in game): part of: dealer sell

- "[Black market] Sold: %s, for %d credits."  (message, line 1359)
- "The quartermaster doesn't buy those. Take it to the lab: the scientist decodes them."  (text, line 1366)
- "[Black market] Sold: %s%s, for %d credits."  (message, line 1373)

> Note for you (not shown in game): the game answering something done in a window (lcu_buy)

- "[Black market] {why}"  (chat message, line 1380)

> Note for you (not shown in game): the game answering something done in a window (lcu_sell)

- "[Black market] {why}"  (chat message, line 1387)

> Note for you (not shown in game): part of: bust dealer

- "[Civil Protection] The dealer bolts. You confiscate what's left of the stock."  (chat message, line 1397)
- "black market busted"  (text, line 1398)
- "Busted a dealer"  (text, line 1399)
- "The dealer {GetPos} got raided. Stay away for a while."  (text, line 1402)

> Note for you (not shown in game): Inventory actions and what the inventory window needs to know !pick (or bind a key to lc_pick): use the right tool you're carrying on the door you're looking at.

- "Look at a locked door, up close."  (text, line 1428)

> Note for you (not shown in game): part of: quick pick

- "That's a Combine lock. You need a keycard, a door code or a bypass charge."  (text, line 1435)
- "You don't have a lockpick. Make one from four pieces of scrap (F2), or find the dealer."  (text, line 1435)

> Note for you (not shown in game): bend four bits of scrap into something that opens a lock

- "You need four pieces of scrap."  (text, line 1468)
- "You bend and file the scrap into a lockpick set."  (text, line 1473)

> Note for you (not shown in game): part of: underground action

- "[Stash] {why}"  (chat message, line 1480)
- "Keep it on you. It's shown when a Civil Protection unit stops you during curfew."  (text, line 1493)
- "It only listens. With a radio transmitter too, you can talk on Freq 7: switch to the Radio transmitter (next to Hands), or !r <message>."  (text, line 1495)
- "It only listens: nobody talks on the Union band, it's the city's. Press Listen to hear it."  (text, line 1496)
- "Use any ration dispenser."  (text, line 1498)

> Note for you (not shown in game): Upkeep

- "[Papers] Your borrowed name has worn thin. You're yourself again."  (chat message, line 1532)

> Note for you (not shown in game): the console command lc_search

- "%s searched: %d item(s) confiscated%s"  (message, line 1554)

> Note for you (not shown in game): The Resistance's own plain clothes

- "You don't have anything else to wear. (Find some clothes.)"  (chat message, line 1580)

> Note for you (not shown in game): typing in chat

- "You're already in your own clothes."  (chat message, line 1586)

> Note for you (not shown in game): a timer (regularly)

- "[Resistance] You're in plain clothes. F1 > Gear up when it's time to fight."  (chat message, line 1597)

## powered vests ("suit power") (sv_livingcity_vest.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_vest.lua`


> Note for you (not shown in game): Put on a powered vest from your pockets. True, or false and why.

- "You're already wearing one."  (text, line 55)
- "Your own gear has a vest at least as good."  (text, line 56)

> Note for you (not shown in game): part of: put on vest

- "Powered vest"  (on-screen notice, line 62)
- "On, with some charge in it. Vortigaunts, suit batteries and chargers top it up."  (on-screen notice, line 62)

## vortigaunts (sv_livingcity_vort.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_vort.lua`


> Note for you (not shown in game): part of: start unshackle

- "Only the Resistance (Member and up) knows how to cut a vortigaunt's shackles."  (text, line 38)
- "Look at a shackled vortigaunt, up close."  (text, line 42)
- "Not with a Civil Protection unit watching."  (text, line 43)
- "[Living City] Someone is working at your shackles."  (chat message, line 44)
- "Cutting the shackles..."  (progress bar, line 45)
- "You stop."  (text, line 46)

> Note for you (not shown in game): one of the city's own: it goes home to rebel ground and lives there, free

- "A Civil Protection unit is watching. Not now."  (chat message, line 51)
- "A Civil Protection unit is watching. Not now."  (chat message, line 56)

> Note for you (not shown in game): part of: done

- "[Living City] The shackles fall away. The vortessence is yours again: left click strikes, right click charges a vest (yours or a comrade's). The Combine will want you back."  (chat message, line 59)
- "The shackles fall. The vortigaunt is free."  (chat message, line 60)
- "freeing a vortigaunt"  (text, line 61)
- "A vortigaunt has been freed. Welcome it."  (text, line 62)

## things to do as a vortigaunt (and for the city's own) (sv_livingcity_vortwork.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_vortwork.lua`


> Note for you (not shown in game): Reaching out through the vortessence The call itself: the Resistance hears where you are, and so do the free vortigaunts.

- "Through the vortessence: a shackled vortigaunt calls out from {GetPos}. Cut it loose (look at it up close, and unshackle)."  (text, line 63)
- "[Vortessence] One of your kin calls out, in chains, {GetPos}."  (chat message, line 66)
- "[Vortessence] Your call goes out. Somewhere, someone hears it."  (chat message, line 68)

> Note for you (not shown in game): part of: vort call

- "Only a shackled vortigaunt can reach out like that."  (text, line 75)
- "The vortessence is quiet. Try again in %d minutes."  (message, line 78)

> Note for you (not shown in game): the collar bites

- "A Civil Protection unit is watching. The collar bites, and the vortessence goes quiet."  (text, line 85)
- "Reaching out through the vortessence..."  (progress bar, line 88)
- "The thread slips away."  (text, line 89)

> Note for you (not shown in game): The Collar: a story for a shackled vortigaunt

- "The Collar"  (name, line 107)
- "Your call went out through the vortessence. The Resistance knows where you are now: the rest is up to them."  (text, line 111)

> Note for you (not shown in game): part of: build

- "Go to the street the Overseer has marked"  (quest step, line 117)
- "The Overseer wants a street swept, and you're the broom. The collar hums at your neck the whole time."  (description, line 121)
- "Sweep the street clean (the cart, the litter, the bin)"  (quest step, line 122)
- "The Overseer's crate"  (title, line 131)
- "A crate of Union stores to carry to a checkpoint {GetPos}. Its manifest is clipped to the lid."  (description, line 132)
- "Carry the crate to the checkpoint (marked)"  (quest step, line 134)
- "The manifest lists what's going where: the checkpoint's new orders, a sweep two days from now. The unit at the gate isn't looking."  (quest choice, line 135)
- "Fold a warning into it for the Resistance: a mark in the margin they'll know."  (text, line 136)

> Note for you (not shown in game): part of: success

- "Nobody sees. Somewhere down the line, someone will read the margin."  (quest narration, line 139)
- "A mark in a Union manifest, from a vortigaunt in chains: a sweep in two days. Be ready."  (text, line 140)

> Note for you (not shown in game): part of: fail

- "The unit looks up as you fold it. The collar bites before you can straighten."  (quest narration, line 143)

> Note for you (not shown in game): part of: build

- "Hand it over as it is."  (text, line 146)

> Note for you (not shown in game): part of: pick

- "The unit signs for it without a glance at you."  (quest narration, line 148)

> Note for you (not shown in game): part of: build

- "Reach out through the vortessence: stay still here, unseen, for 20 seconds"  (quest step, line 158)
- "A whisper in the vortessence"  (title, line 161)
- "Some nights the collar flickers, and the vortessence stirs behind it. Find somewhere quiet {GetPos}, and reach out."  (description, line 162)
- "Find a quiet corner (marked)"  (quest step, line 163)
- "Free your kin"  (title, line 197)
- "One of your kin sweeps the streets in a collar {GetPos}. Cut it loose, and it will find its way to us."  (description, line 198)
- "Find your kin, collared, sweeping the street (marked)"  (quest step, line 201)
- "Cut it loose: look at it up close and unshackle it (C > Resistance), with no unit watching"  (quest step, line 202)

> Note for you (not shown in game): not on top of it: a little way off, where you can watch

- "Read the Combine"  (title, line 226)
- "The vortessence sees what eyes don't: who stands where, and when they change. Watch the checkpoint {GetPos} from a little way off, unseen, and bring what it shows you to the quartermaster."  (description, line 227)

> Note for you (not shown in game): part of: build

- "Find somewhere to watch from (marked), out of the units' sight"  (quest step, line 229)
- "Still yourself and let the vortessence read the checkpoint (20 seconds, unseen)"  (quest step, line 230)

> Note for you (not shown in game): part of: on finish

- "[Vortessence] Shifts, the gate, the men: it all settles into your mind, and you write it down. The quartermaster pays for this."  (chat message, line 235)

> Note for you (not shown in game): True if it's begun, false and why if not, nil if the target isn't a vortigaunt at all (a vest, then).

- "Their body is whole."  (text, line 263)
- "Their vortessence needs a moment before it can take more."  (text, line 265)

> Note for you (not shown in game): part of: vort heal

- "[Vortessence] You gather it in your hands..."  (chat message, line 268)

> Note for you (not shown in game): a timer (regularly)

- "[Vortessence] Too far: it slips away."  (chat message, line 272)
- "[Vortessence] Green light, and warmth: your kin mends you."  (chat message, line 282)
- "mending your kin"  (text, line 283)

> Note for you (not shown in game): part of: vort commune

- "[Vortessence] Your kin reach for one another, and for a moment you are many. Something is seen."  (chat message, line 425)

> Note for you (not shown in game): what's seen: a sweep or raid on its way, if one is; else a door code

- "The vortigaunts have seen it in the vortessence: a sweep into our ground %s, in about %d seconds. Move what you can."  (message, line 429)
- "The vortigaunts have seen it in the vortessence: our raid {target} will meet more Combine than we planned for."  (text, line 432)

> Note for you (not shown in game): a door code: on a scrap by an NPC vortigaunt in camp, or in a free vortigaunt player's pockets

- "The vortigaunts have seen a Combine door code in the vortessence. It's scratched on a scrap beside them, {GetPos}. One door, before they change it."  (text, line 442)

> Note for you (not shown in game): part of: vort commune

- "[Vortessence] A string of numbers settles in your mind: a Combine door code. You scratch it down (it's in your pockets). One door, before they change it."  (chat message, line 447)

## the state of the city (sv_livingcity_war.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_war.lua`

- "The Resistance holds a real share of the city. Expect more inspections and raids, ration cuts and a harsher PA. The black market is cheaper while it lasts."  (text, line 407)
- "The Combine holds the whole city. The rebels have gone quiet, and the black market has put its prices up."  (text, line 408)
- "Nobody holds the upper hand. The city goes about its business."  (text, line 409)
- "Civil unrest"  (text, line 411)
- "Full compliance"  (text, line 411)

> Note for you (not shown in game): part of: set state

- "[City] {name}. {name}"  (chat message, line 419)

> Note for you (not shown in game): part of: outbreak

- "The infestation {or} has broken out into the streets. Infected are loose nearby. Get indoors, or get armed."  (text, line 485)
- "Dispatch: quarantine breach. All Civil Protection units, contain the infected."  (text, line 488)

> Note for you (not shown in game): part of: city report

- "[City] Combine %d%%, Resistance %d%%, infested %d%%. %s."  (message, line 516)

> Note for you (not shown in game): part of: mark1020

- "Only Civil Protection units can call a 10-20."  (text, line 534)
- "Static. Your radio can't get through: there's a jammer nearby."  (text, line 535)
- "[CP net] 10-20: {name} is {where}. Respond for XP; the faster, the more."  (chat message, line 547)
- "[CP net] Your 10-20 is out to every Civil Protection unit for 90 seconds."  (chat message, line 549)

> Note for you (not shown in game): part of: call backup

- "Only Civil Protection units can call for backup."  (text, line 555)
- "Static. Your radio can't get through: there's a jammer nearby."  (text, line 556)
- "Dispatch already has your last call. Again in %ds."  (message, line 559)
- "[CP net] {Callsign} requests backup {where}. Respond for XP."  (chat message, line 582)
- "[Dispatch] %d unit%s en route to you."  (message, line 584)
- "[Dispatch] No Civil Protection units free nearby. Your 10-20 is out to every unit."  (chat message, line 585)

> Note for you (not shown in game): part of: backup tick

- "responded to a 10-20"  (text, line 632)
- "[CP net] On scene in %ds. +%d XP."  (message, line 633)
- "[CP net] {p} is on scene."  (chat message, line 634)

> Note for you (not shown in game): Chat

- "[Dispatch] {why}"  (chat message, line 655)

> Note for you (not shown in game): typing in chat

- "[CP net] {why}"  (chat message, line 660)

> Note for you (not shown in game): the console command lc_backup_call

- "[Dispatch] {why}"  (chat message, line 665)

> Note for you (not shown in game): the console command lc_1020

- "[CP net] {why}"  (chat message, line 666)

> Note for you (not shown in game): the console command lc_outbreak

- "[Living City] No infestation zones placed."  (chat message, line 671)
- "[Living City] Outbreak started."  (chat message, line 672)
- "[Living City] Nowhere for them to break out to."  (chat message, line 672)

> Note for you (not shown in game): Talk on the street What's happened in the city lately, as people heard it. Press E on a citizen and now and then they'll pass something on. Units mostly get nervous silence.

- "over that way"  (text, line 689)
- "'I didn't see anything, officer.'"  (text, line 714)
- "'Nothing to report. Nothing at all.'"  (text, line 714)
- "'I keep my head down. Like we're told.'"  (text, line 714)

> Note for you (not shown in game): everyone else hears the city's rumours in the talk window (sv_livingcity_talk.lua)

- "They say the Resistance has taken the streets {w}. Civil Protection won't go in."  (text, line 737)
- "Someone told me the rebels are holding ground {w} now. Just walked in and took it."  (text, line 738)

> Note for you (not shown in game): the game's living city territory grew moment

- "Stay away from {w}. The infected are spreading. I heard them last night."  (text, line 740)
- "My neighbour went {w} for scrap. Didn't come back. They say it's crawling with them now."  (text, line 741)

> Note for you (not shown in game): the game's living city territory receded moment

- "The Combine cleared the rebels out {w}. There was a lot of shooting."  (text, line 748)
- "I heard Civil Protection took back the ground {w}. Nobody's saying what happened to the people there."  (text, line 749)
- "Civil Protection burned out the infected {w}. You can still smell it."  (text, line 751)
- "They say it's safe {w} again. I wouldn't bet on it."  (text, line 752)

> Note for you (not shown in game): the game's living city skirmish moment

- "Did you hear the shooting? Rebels hit the Combine {or}."  (text, line 758)
- "The Resistance went after a checkpoint {or}. Brave, or stupid."  (text, line 759)
- "The Combine sent a team into rebel ground {pos}. Armed."  (text, line 761)
- "Civil Protection went into the rebel streets {pos} with guns drawn."  (text, line 762)

> Note for you (not shown in game): the game's living city outbreak moment

- "The infected broke out {pos}. People didn't make it."  (text, line 767)
- "They had to lock everything down. The things came out of {pos}."  (text, line 768)

> Note for you (not shown in game): the game's living city block raided moment

- "They tore {name} apart looking for contraband. Took people, too."  (text, line 773)
- "Did you hear about {name}? Doors kicked in, the lot."  (text, line 774)

> Note for you (not shown in game): the game's living city dealer busted moment

- "The dealer {GetPos} got raided. Don't go asking for him."  (text, line 779)

> Note for you (not shown in game): the game's living city incarcerated moment

- "They took {name} away. {or}"  (text, line 787)
- "Have you seen {name}? Civil Protection came for them."  (text, line 788)

> Note for you (not shown in game): the game's living city person killed moment

- "They killed {name}. Civil Protection. In the street, in front of everyone."  (text, line 794)
- "is dead. Nobody will say who did it."  (text, line 795)

> Note for you (not shown in game): the game's living city state changed moment

- "Everyone's on edge. The Combine are losing the streets, and they know it."  (text, line 800)
- "Rations are short again. That's what happens when the rebels are winning."  (text, line 801)
- "It's quiet. Too quiet. The Combine have the whole city now."  (text, line 803)
- "Haven't heard a shot in days. I don't know if that's good."  (text, line 804)

## ways to get by (sv_livingcity_ways.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_ways.lua`


> Note for you (not shown in game): part of: ways to get by

- "Buy a market stall at the Commissary (%d credits) and set it down; or look at the one you have, with your pockets open."  (message, line 60)
- "A CWU business license (%d credits), then a stall, both at the Commissary."  (message, line 62)
- "Needs Civil Standing 50 (you have %d)"  (message, line 63)
- "A fishing line (Commissary, %d credits): Fish from your pockets, at the water."  (message, line 67)
- "Needs Civil Standing %d (you have %d)"  (message, line 75)

## weeds, the Groundskeeper, and weedkiller (the owner, 2026-11-01) (sv_livingcity_weeds.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_weeds.lua`


> Note for you (not shown in game): Spraying one: a moment for a tuft, longer for a bush.

- "You'd need weedkiller (the Union Commissary sells it; the Groundskeeper is issued it)."  (text, line 131)

> Note for you (not shown in game): part of: spray weed

- "Spraying the weeds..."  (progress bar, line 138)
- "You stop spraying."  (text, line 138)

> Note for you (not shown in game): Weedkiller as poison

- "You've no weedkiller."  (text, line 146)
- "You've nothing to eat or drink to put it in."  (text, line 152)

> Note for you (not shown in game): part of: poison food

- "Attempted murder: poisoning food"  (text, line 154)
- "A Civil Protection unit saw you tip it in. You're wanted."  (text, line 155)
- "[Pockets] A few drops of weedkiller into the %s. It looks no different, and nobody will taste it until it's too late."  (message, line 160)

> Note for you (not shown in game): The Groundskeeper: issued weedkiller; their shifts and the city's own

- "[Union] You're issued a canister of weedkiller. Look at a weed and press E to spray it."  (chat message, line 173)
- "spraying weeds"  (label, line 178)

> Note for you (not shown in game): part of: find

- "spraying weeds"  (what someone is doing, line 188)

## occupations (sv_livingcity_work.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_work.lua`


> Note for you (not shown in game): part of: set job

- "That job doesn't exist."  (text, line 62)
- "That job is closed right now. Pick a different one."  (text, line 63)
- "Only citizens can take Union jobs."  (text, line 65)
- "%s is only for citizens with Civil Standing %d or more. Yours is %d."  (message, line 67)
- "Only registered citizens can take Union jobs. Register at Civil Intake first, then pick a job."  (text, line 70)
- "You changed jobs recently. You can change again in {CurTime} seconds."  (text, line 73)
- "[Union] Your job is now: {name}. Open your board (F3) to find your shifts."  (chat message, line 100)

> Note for you (not shown in game): part of: give union work

- "Union work assignment"  (on-screen notice, line 130)
- "The Union has given you a job: {name}. Go to the {place} to work. Your shifts are on your board (F3), and you can ask for a different job there."  (on-screen notice, line 130)

> Note for you (not shown in game): the game answering something done in a window (lcj_set)

- "[Union] {why}"  (chat message, line 140)

> Note for you (not shown in game): a timer (regularly)

- "[Union] Your job ({name}) has been closed, so you don't have one now. Pick a new job on your board (F3)."  (chat message, line 161)

> Note for you (not shown in game): Shifts, by job

- "Litter sweep"  (title, line 249)

> Note for you (not shown in game): part of: sanitation

- "Pick up 5 pieces of litter {GetPos}."  (description, line 250)
- "Pick up the litter: press E on each piece (5 in all)"  (text, line 252)

> Note for you (not shown in game): part of: text

- "Go to bin %d of 3 (%s) and stay next to it for 6 seconds to empty it"  (message, line 270)
- "Bin round"  (title, line 278)
- "Three bins are overflowing. Go to each one and empty it."  (description, line 278)

> Note for you (not shown in game): part of: stages

- "Graffiti removal"  (title, line 284)
- "Someone reported graffiti {GetPos}. Go there and scrub it off."  (description, line 285)
- "Go to the graffiti (marked)"  (quest step, line 287)
- "Someone has sprayed a lambda (the Resistance symbol) and a name across the wall. You know the name: it's your neighbor's boy."  (quest choice, line 288)
- "Scrub off all of it, lambda and name."  (text, line 289)
- "Scrub off only the name and leave the lambda (if you're caught, you're wanted)."  (text, line 290)

> Note for you (not shown in game): part of: success

- "Somebody will see that lambda tomorrow and feel a little less alone."  (quest narration, line 294)

> Note for you (not shown in game): part of: fail

- "A Civil Protection unit on the corner saw you leave the lambda on the wall. You're now wanted."  (quest narration, line 297)
- "Defacing city property"  (text, line 298)

> Note for you (not shown in game): part of: stages

- "Report the boy's name to a Civil Protection unit."  (text, line 300)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report the name"  (quest step, line 303)

> Note for you (not shown in game): part of: stages

- "Crouch at the wall for 5 seconds to scrub it clean"  (quest step, line 306)

> Note for you (not shown in game): part of: kitchen

- "The sealing line"  (title, line 327)
- "Ration bars and gel get sealed in foil here, thousands a day. Go to the ration plant and work the sealing line."  (description, line 328)
- "Go to the ration plant (marked)"  (quest step, line 329)
- "Stay at the line for 40 seconds to seal ration packs"  (quest step, line 329)

> Note for you (not shown in game): part of: stages

- "Supply run"  (title, line 337)
- "The supply truck is waiting {GetPos}. Get the crate of ration packs from the driver and take it to the dispenser attendant."  (description, line 338)
- "Go to the truck driver (marked) and press E on them to take the ration crate"  (text, line 340)
- "'Sign here. No, nobody has a pen. Just take it.'"  (text, line 340)
- "Take the crate to the dispenser attendant (marked) and press E on them"  (text, line 341)
- "She counts the packs twice and doesn't say what the number should have been."  (text, line 342)
- "The count"  (title, line 350)
- "Every ration pack in the dispensers must match the register. Go to the dispensers and count them."  (description, line 351)
- "Go to the dispensers (marked)"  (quest step, line 353)
- "Stay at the dispensers for 25 seconds to count the packs against the register"  (quest step, line 354)
- "The count is three packs short. Nobody signed for them, and the register doesn't care whose fault that is."  (quest choice, line 355)
- "Report the missing packs to the supervisor."  (text, line 356)

> Note for you (not shown in game): part of: pick

- "The supervisor writes it down. Somebody is going to have a very bad week. It isn't you. (5 extra XP for this shift.)"  (quest narration, line 359)

> Note for you (not shown in game): part of: stages

- "Change the register so the numbers match."  (text, line 361)

> Note for you (not shown in game): part of: pick

- "A stroke of the pen and the register matches the shelves. Nobody will ever know. Probably."  (quest narration, line 363)

> Note for you (not shown in game): part of: stages

- "Write it down as six short and keep three packs for yourself (if you're caught, you're wanted)."  (text, line 365)

> Note for you (not shown in game): part of: success

- "You take three ration packs for yourself. The register will blame whoever worked here before you."  (quest narration, line 369)

> Note for you (not shown in game): part of: fail

- "A dispenser attendant saw you take the packs. She doesn't say anything. She doesn't have to: you're now wanted for ration fraud."  (quest narration, line 372)
- "Ration fraud"  (text, line 373)
- "The counter"  (title, line 385)
- "You're checking ration cards at line {g} today. Each valid card gets one ration pack. Forged cards get nothing."  (description, line 386)
- "Go to the ration counter (marked)"  (quest step, line 388)
- "A card with a smudged stamp and a citizen number that's one digit too long: it's forged. The man holding it is very thin."  (quest choice, line 389)
- "Take the card and report him to Civil Protection."  (text, line 390)

> Note for you (not shown in game): part of: pick

- "A Civil Protection unit takes him by the arm. The card goes in the box with the others. (10 extra XP for this shift.)"  (quest narration, line 393)
- "Accept the card and give him his ration."  (text, line 395)
- "He takes the pack and doesn't look back. Neither do you."  (quest narration, line 398)
- "Keep the forged card for yourself (if you're caught, you're wanted)."  (text, line 400)

> Note for you (not shown in game): part of: success

- "'Invalid,' you tell him, and the card goes in your pocket instead of the box. He doesn't argue."  (quest narration, line 404)

> Note for you (not shown in game): part of: fail

- "The supervisor saw the card go in your pocket. 'Ration fraud,' he says, almost bored. You're now wanted."  (quest narration, line 407)
- "Ration fraud"  (text, line 408)
- "Stay at the counter until 3 citizens have been handed their rations"  (text, line 412)

> Note for you (not shown in game): part of: medic

- "Clinic rounds"  (title, line 423)
- "Three injured patients are waiting at the clinic. Heal each one with your medkit until they're back on their feet."  (description, line 424)
- "Go to the clinic (marked)"  (quest step, line 426)
- "Heal the patients: hold your medkit and left click on each one until they're healed"  (text, line 427)

> Note for you (not shown in game): part of: stages

- "House call"  (title, line 435)
- "A man was hurt {GetPos} and can't walk to the clinic. Go to him and heal him."  (description, line 436)
- "Go to the injured man (marked)"  (text, line 439)
- "Stunstick bruises, in neat rows: Civil Protection did this. He grabs your wrist. 'Please. Don't write it down. Say I fell.'"  (quest choice, line 448)
- "Write down the truth: a stunstick beating."  (text, line 449)
- "Cover for him: write 'fell down the stairs'."  (text, line 450)

> Note for you (not shown in game): part of: pick

- "He closes his eyes. 'Thank you.'"  (quest narration, line 453)

> Note for you (not shown in game): part of: stages

- "Heal him: hold your medkit and left click on him until he's healed"  (text, line 456)

> Note for you (not shown in game): part of: factory

- "Assembly quota"  (title, line 469)
- "Today's quota is posted: work the line, then carry the finished part to the next station and fit it. Nobody asks what the parts are for."  (description, line 470)
- "Go to the factory line (marked)"  (quest step, line 472)
- "Stay at the line for 25 seconds to work it"  (quest step, line 473)
- "Pick up the finished part: press E on the box"  (text, line 474)
- "Carry the part to the next station (marked)"  (text, line 475)
- "Stay at the station for 15 seconds to fit the part"  (quest step, line 476)

> Note for you (not shown in game): part of: text

- "Go to the loading dock (marked) and press E on crate %d of 2 to pick it up"  (message, line 487)
- "Carry crate %d to the factory floor (marked)"  (message, line 488)
- "Loading dock"  (title, line 490)
- "Carry two crates, one at a time, from the loading dock to the factory floor."  (description, line 490)

> Note for you (not shown in game): part of: stages

- "Short count"  (title, line 496)
- "Another shift working the factory line."  (description, line 497)
- "Go to the factory line (marked)"  (quest step, line 499)
- "Stay at the line for 20 seconds to work it"  (quest step, line 500)
- "The parts count is short again. You see the foreman slide a box of parts under his coat, and he sees you watching."  (quest choice, line 501)
- "Report the foreman to Civil Protection."  (text, line 502)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report the foreman"  (quest step, line 505)

> Note for you (not shown in game): part of: stages

- "Say nothing."  (text, line 507)
- "Ask him for a share of what he's stealing."  (text, line 508)

> Note for you (not shown in game): part of: pick

- "He grins like you've always been friends. (10 extra XP for this shift.)"  (quest narration, line 512)

> Note for you (not shown in game): part of: groundskeeper

- "Weeds are coming up through the cracks nearby. Spray them before they become bushes."  (description, line 537)
- "Spray 3 weeds: look at one and press E (your weedkiller does the rest)"  (quest step, line 538)

> Note for you (not shown in game): the barrel nearest the growth, marked for the last step (none: a bag will do)

- "Empty your hoover into the infestation control barrel (marked): E on it"  (quest step, line 560)
- "Seal the hoover's load in a bag: right click with the hoover (there's no infestation control barrel near)"  (quest step, line 561)

> Note for you (not shown in game): part of: cleanup

- "Clearing the infestation"  (title, line 564)
- "The infestation is spreading. Go in with your respirator, weedkiller and hoover: kill its growths, vacuum them up, and get rid of them. Civil Protection will guard you: stay close to them."  (description, line 565)
- "Go to the infestation (marked): Civil Protection meets you there"  (quest step, line 567)
- "Spray 3 growths dead: the glowing ones (the sprayer out, hold left click on one; or E)"  (quest step, line 568)
- "Vacuum up the dead growths: the hoover out, hold left click on one"  (quest step, line 569)

> Note for you (not shown in game): part of: warden

- "Block patrol"  (title, line 586)
- "Walk your block, and keep your eyes open. The Union trusts you to know your neighbours."  (description, line 587)
- "Walk your block: the first corner (marked)"  (quest step, line 589)
- "And the next (marked)"  (quest step, line 590)
- "Have a word with a neighbour (walk up to one and press E)"  (quest step, line 591)
- "They answer your questions a little too quickly, and won't quite meet your eye."  (quest choice, line 592)
- "Report them: something about them isn't right."  (text, line 593)

> Note for you (not shown in game): part of: pick

- "A report that held up"  (text, line 595)
- "a report that held up"  (text, line 596)
- "Civil Protection looks into it. Your report holds up: 10 credits and 15 standing. You don't see the neighbour again."  (quest narration, line 597)
- "A report that came to nothing"  (text, line 599)
- "Civil Protection looks into it, and finds nothing. Wasted time is noted: 10 standing."  (quest narration, line 600)

> Note for you (not shown in game): part of: warden

- "Nothing to report. Nervous people are just nervous."  (text, line 604)

> Note for you (not shown in game): part of: pick

- "A quiet patrol"  (text, line 605)
- "You write it up as a quiet patrol."  (quest narration, line 607)

> Note for you (not shown in game): real letters, from people in the city to people in the city (sv_livingcity_mail.lua)

- "Go to the post office (marked) and press E on the postal clerk to collect today's letters"  (text, line 623)
- "'Real post, for once. Mind none of it goes astray.'"  (text, line 624)

> Note for you (not shown in game): part of: courier

- "Take letter %d of %d to %s (marked) and stay at their door for 3 seconds to push it under"  (message, line 640)

> Note for you (not shown in game): they're yours from the moment you start

- "The real mail"  (title, line 651)

> Note for you (not shown in game): part of: courier

- "letter{or} written by people in the city, for you to deliver to other people in the city."  (description, line 652)

> Note for you (not shown in game): part of: claimed

- "an apartment doorway"  (text, line 662)

> Note for you (not shown in game): the mail comes from the clerk at the post office, and goes to people, by hand

- "Go to the post office (marked) and press E on the postal clerk to collect the mail"  (text, line 670)
- "'Three for the district. Two are overdue. Don't tell them I said so.'"  (text, line 671)
- "Hand letter %d of 3 to %s, %s (marked): go there and press E on them"  (message, line 675)
- "They take it without looking at who sent it."  (text, line 676)
- "'Finally,' they say, and shut the door on the rest of the sentence."  (text, line 676)
- "A nod. Nobody says anything useful in this city out loud."  (text, line 677)
- "They read the envelope twice before they put it away."  (text, line 677)

> Note for you (not shown in game): part of: claimed

- "Mail round"  (title, line 680)
- "Collect three letters from the clerk at the post office, then hand each one to the person it's addressed to."  (description, line 680)

> Note for you (not shown in game): part of: stages

- "Sealed envelope"  (title, line 688)
- "Collect an envelope with a Civil Protection seal from the post office and deliver it to someone {GetPos}."  (description, line 689)
- "Go to the post office (marked) and press E on the clerk to collect the envelope"  (text, line 691)
- "'Hand it over in person. Nobody signs for these.'"  (text, line 691)
- "The seal is a Combine stamp, and it's not glued very well. You could probably open it."  (quest choice, line 692)
- "Deliver it unopened."  (text, line 693)
- "Steam it open and read it (the seal might tear)."  (text, line 694)

> Note for you (not shown in game): part of: success

- "It's an eviction order for the family in 3B, the one with the twins. They have to be out by tomorrow."  (quest choice, line 696)
- "Deliver it as addressed and say nothing."  (text, line 697)
- "Warn the family before you deliver it."  (text, line 698)

> Note for you (not shown in game): part of: pick

- "Go to the family's home (marked) to quietly warn them"  (quest step, line 701)

> Note for you (not shown in game): part of: fail

- "The seal tears. You'll have to hope nobody checks."  (quest narration, line 705)

> Note for you (not shown in game): part of: stages

- "Take the envelope to the person it's addressed to (marked) and press E on them"  (text, line 707)
- "They take it with both hands, like it might go off."  (text, line 707)

> Note for you (not shown in game): the city's own streetlights, the broken ones first (sv_livingcity_propaganda.lua)

- "Go to streetlight %d of %d (%s) and stay next to it to repair it"  (message, line 721)

> Note for you (not shown in game): part of: maintenance

- "Lights out"  (title, line 728)
- "Streetlights are broken across the district. Go to each one and repair it."  (description, line 728)
- "Go to fuse box %d of 3 (%s) and stay next to it to repair it"  (message, line 734)
- "Lights out"  (title, line 739)
- "Three fuse boxes are broken across the district. Go to each one and repair it."  (description, line 739)

> Note for you (not shown in game): part of: stages

- "Terminal fault"  (title, line 746)
- "A scanner terminal at a checkpoint keeps breaking down. Go there and repair it."  (description, line 747)
- "Go to the broken terminal (marked)"  (quest step, line 749)
- "Stay next to the terminal to repair it"  (quest step, line 750)
- "While the terminal reboots, its log scrolls past. One of last night's entries is your neighbor, out at 3 a.m."  (quest choice, line 751)
- "Leave the log as it is."  (text, line 752)
- "Erase your neighbor's entry while you're in there (if you're caught, you're wanted)."  (text, line 753)

> Note for you (not shown in game): part of: success

- "One line of the log becomes noise. Terminals glitch all the time."  (quest narration, line 757)

> Note for you (not shown in game): part of: fail

- "The terminal flags the edit. Every Civil Protection unit in the sector gets the alert. You're now wanted."  (quest narration, line 760)
- "Tampering with a city terminal"  (text, line 761)

> Note for you (not shown in game): Somewhere people live: a housing block, an apartment doorway, or a street.

- "an apartment doorway"  (text, line 783)

> Note for you (not shown in game): Somewhere Civil Protection works: a checkpoint, the prison, or a street.

- "the checkpoint"  (text, line 791)
- "the prison"  (text, line 793)

> Note for you (not shown in game): Intake Processor

- "New arrivals"  (title, line 832)
- "A train has arrived. Meet one of the new arrivals on the platform and walk him to his assigned housing."  (description, line 833)

> Note for you (not shown in game): part of: porter

- "Go to the new arrival on the platform (marked)"  (text, line 836)
- "He's holding a transfer slip like it might bite him. Under his breath he asks: 'Is there anywhere in this city they don't look?'"  (quest choice, line 845)
- "Tell him: 'Go to your block and keep your head down.'"  (text, line 846)
- "Tell him about the canals (rebel territory) and walk him there instead."  (text, line 847)

> Note for you (not shown in game): part of: pick

- "He doesn't say thank you. He doesn't have to."  (quest narration, line 854)

> Note for you (not shown in game): part of: porter

- "Report what he said to a Civil Protection unit."  (text, line 856)

> Note for you (not shown in game): part of: pick

- "A Civil Protection unit takes him by the arm. He looks back at you once."  (quest narration, line 860)

> Note for you (not shown in game): part of: porter

- "Walk him to his new home (marked)"  (text, line 865)

> Note for you (not shown in game): part of: on enter

- "Walk him to {or}"  (text, line 870)

> Note for you (not shown in game): part of: text

- "A suitcase was left on the train platform. Pick it up and return it to its owner, {destName}."  (description, line 882)
- "Go to the platform (marked) and press E on the suitcase to pick it up"  (text, line 885)
- "The suitcase is heavier than clothes. Something inside slides and settles, like a stack of paper."  (quest choice, line 886)
- "Just carry it. It's not your business."  (text, line 887)
- "Open it and look inside (if you're caught, you're wanted)."  (text, line 888)

> Note for you (not shown in game): part of: success

- "Under the shirts: a stack of blank identity forms. You take one. Nobody counts them twice."  (quest narration, line 890)

> Note for you (not shown in game): part of: fail

- "The latches snap open loud enough to turn heads. A Civil Protection unit is already walking over. You're now wanted."  (quest narration, line 895)
- "Theft from a traveler"  (text, line 896)

> Note for you (not shown in game): part of: text

- "Hand it to Civil Protection."  (text, line 898)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to hand over the suitcase"  (quest step, line 902)

> Note for you (not shown in game): part of: text

- "Take the suitcase to its owner, {destName} (marked), and press E on them"  (text, line 905)
- "'That's mine. I thought I'd lost it.' They don't say thank you."  (text, line 905)
- "Ticket check"  (title, line 913)
- "Check the ticket and transit permit of everyone boarding the train."  (description, line 914)
- "Go to the train platform (marked)"  (quest step, line 916)
- "Check three travelers' tickets: press E on citizens on the platform"  (quest step, line 917)
- "An old woman has a ticket, but no transit permit. "I'm going to see my son," she says. "He's in Nova Prospekt.""  (quest choice, line 918)
- "Let her board anyway (if you're caught, you're wanted)."  (text, line 919)

> Note for you (not shown in game): part of: success

- "She squeezes your hand on the way past. It's the last train she'll ever take, and you both know it."  (quest narration, line 923)

> Note for you (not shown in game): part of: fail

- "The platform scanner flags her before she reaches the door. And you, for letting her through: you're now wanted."  (quest narration, line 926)
- "Aiding unauthorized travel"  (text, line 927)
- "Refuse, and send her back."  (text, line 929)
- "Report her to Civil Protection."  (text, line 930)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report her"  (quest step, line 933)

> Note for you (not shown in game): a real body if the city has left one lying about, or a reported one

- "Go to the body {GetPos}"  (quest step, line 981)

> Note for you (not shown in game): part of: mortuary

- "A body was reported {GetPos}. Nobody has claimed it. Collect it and take it to the incinerator or morgue."  (description, line 998)
- "His coat pocket holds identity papers, still valid. Nobody has reported him dead yet."  (quest choice, line 1002)
- "Hand everything in, papers included."  (text, line 1003)
- "Keep his identity papers."  (text, line 1004)

> Note for you (not shown in game): part of: pick

- "They're good papers. They'll be good for somebody."  (quest narration, line 1007)

> Note for you (not shown in game): part of: mortuary

- "Tell his family before you take him away."  (text, line 1009)

> Note for you (not shown in game): part of: pick

- "Go and tell his family: {homeName}"  (quest step, line 1011)

> Note for you (not shown in game): part of: mortuary

- "Drag the body (press E on it to grab it, E again to let go) to the marked spot"  (text, line 1014)
- "Drag %d bodies off the streets to %s (press E on a body to grab it, E again to let go)"  (message, line 1028)
- "Clear the streets"  (title, line 1031)
- "There's been trouble, and bodies are lying in the streets. Take them to the incinerator or morgue: the city wants them gone before morning."  (description, line 1032)

> Note for you (not shown in game): part of: stages

- "Stay at the incinerator for 30 seconds to burn the bodies"  (quest step, line 1041)
- "The incinerator runs all night, and somebody has to feed it the bodies. Go there and work it."  (description, line 1045)
- "Go to the incinerator (marked)"  (quest step, line 1047)
- "Go to the morgue (marked)"  (quest step, line 1047)
- "The next body still has a wedding ring on."  (quest choice, line 1049)
- "Leave the ring on her."  (text, line 1050)
- "Keep the ring for yourself."  (text, line 1051)
- "Set the ring aside for her family."  (text, line 1055)
- "Find the dead headcrabs and press E on each one to bag it"  (text, line 1080)
- "Take the bags to {name} (marked) to burn them"  (text, line 1084)
- "Headcrab collection"  (title, line 1087)
- "Dead headcrabs left lying in the street breed flies and worse. Bag every one, then take them to be burned."  (description, line 1088)

> Note for you (not shown in game): Reclamation Crew

- "Scrap run"  (title, line 1103)
- "Scrap metal is lying {GetPos}. Collect 5 pieces and bring them to the reclamation yard. The Union needs all of it."  (description, line 1104)

> Note for you (not shown in game): part of: scrap

- "Collect the scrap: press E on each piece (5 in all)"  (text, line 1107)
- "One good piece of copper wasn't on anybody's list."  (quest choice, line 1108)
- "Log it with the rest."  (text, line 1109)
- "Keep it to sell to the dealer (you get 2 scrap)."  (text, line 1110)
- "Bring the scrap to the reclamation yard (marked)"  (text, line 1115)
- "Go to rubble pile %d of 3 (%s) and stay next to it to clear it"  (message, line 1124)
- "Under the bricks: a canvas bag. Inside, a pistol and a magazine wrapped in oilcloth. Someone hid it here on purpose."  (quest choice, line 1128)
- "Report the hidden gun to Civil Protection."  (text, line 1129)

> Note for you (not shown in game): part of: pick

- "Find a Civil Protection unit and press E on them to report the gun"  (quest step, line 1132)
- "Leave it where it is."  (text, line 1134)
- "You put the bricks back exactly how they were."  (quest narration, line 1136)
- "Take the pistol (if a unit sees you take it, you're wanted)."  (text, line 1138)
- "A Civil Protection unit saw you pull the gun out of the rubble. You're now wanted."  (quest narration, line 1142)
- "Possession of a firearm"  (text, line 1143)
- "It's cold and heavy and nobody saw."  (quest narration, line 1145)
- "Rubble clearing"  (title, line 1149)
- "Clear three piles of rubble left over from the old city."  (description, line 1149)
- "Work the line: throw the bad parts (rust-red and sparking) in the scrap bin and let the good ones pass. E grabs a part, left click throws it"  (text, line 1214)

> Note for you (not shown in game): part of: litter

- "Street sweep"  (title, line 1224)
- "Take your cart from the sanitation depot, fill it with rubbish from the streets and bring it back. You're paid credits for every piece in the cart."  (description, line 1225)
- "Go to the sanitation depot (marked): your cart is there"  (text, line 1227)
- "Fill the cart and push it back to the depot. E on the cart grabs it to push (E again lets go). E picks up rubbish, left click throws it in the cart"  (text, line 1228)

> Note for you (not shown in game): part of: quota

- "On the line"  (title, line 1239)
- "Work the factory line: throw the bad parts in the scrap bin before they reach the end. Good parts go through."  (description, line 1240)
- "Go to the factory line (marked)"  (text, line 1241)

> Note for you (not shown in game): part of: seal

- "The sealing line"  (title, line 1250)
- "Ration bars and gel get sealed in foil here, thousands a day. Throw the split packs in the reject bin: only sealed ones go through."  (description, line 1251)
- "Go to the sealing line at the ration plant (marked)"  (text, line 1252)
- "Work the sealing line: throw split, leaking packs (sickly green) in the reject bin and let the sealed ones pass. E grabs a pack, left click throws it"  (text, line 1253)

> Note for you (not shown in game): The loading dock (two crates, a long walk each way) is the Intake Processor's work now; the factory floor gets more of the line instead (the owner: "an absolute grind").

- "Freight from the dock"  (description, line 1268)
- "Carry two crates, one at a time, from the loading dock to the station."  (text, line 1268)

> Note for you (not shown in game): part of: text

- "Overtime on the line"  (title, line 1280)
- "The quota went up again. Work the factory line: bad parts in the scrap bin, good ones through. The line doesn't stop for you."  (description, line 1281)
- "Go to the factory line (marked)"  (text, line 1282)
- "Overtime on the line"  (title, line 1286)
- "The quota went up again. Go to the factory line and work it."  (description, line 1286)
- "Go to the factory line (marked)"  (quest step, line 1287)
- "Stay at the line for 40 seconds to work it"  (quest step, line 1287)

> Note for you (not shown in game): Maintenance: every repair is a wiring panel

- "Rewire it: click the tiles to turn them (right-click turns back) until the current reaches the lamp. Don't turn a tile while it's sparking: it shocks you"  (text, line 1296)
- "the terminal"  (text, line 1297)
- "the box"  (text, line 1297)

> Note for you (not shown in game): Clinic Medic: rounds are triage

- "Patients are coming into the clinic faster than you can treat them. Treat the worst hurt first."  (description, line 1311)

> Note for you (not shown in game): part of: rounds

- "Go to the clinic (marked)"  (text, line 1313)
- "Heal the patients with your medkit (left click) before they bleed out. The bar over each one's head shows who's worst"  (text, line 1314)

> Note for you (not shown in game): Reclamation Crew: rubble is something you break up

- "Break up the rubble: hit it with your crowbar (left click)"  (text, line 1323)

> Note for you (not shown in game): part of: ticket

- "Check the travelers' papers: press E on each traveler, then approve, deny, or call a Civil Protection unit"  (text, line 1331)
- "Papers check"  (title, line 1332)
- "Check the papers and permits of everyone boarding the train. Today's rules are shown next to their papers."  (description, line 1334)

> Note for you (not shown in game): Courier: a parcel run against the clock (they aren't letters)

- "an apartment doorway"  (name, line 1349)

> Note for you (not shown in game): part of: desc

- "Parcel run"  (title, line 1358)
- "Deliver three parcels before time runs out: the faster you are, the more you're paid. They aren't letters, and nobody tells you what's in them."  (description, line 1359)
- "Go to the post office (marked) to collect the parcels"  (text, line 1361)
- "Deliver the parcels to the marked spots before time runs out. Civil Protection units stop couriers they get a good look at, so crouch when you pass them"  (text, line 1362)

> Note for you (not shown in game): part of: incinerator

- "Before the fire"  (title, line 1377)
- "Three bodies go in the incinerator tonight. Search every pocket first. The overseer checks on you now and then: don't get caught keeping anything."  (description, line 1378)
- "Go to the incinerator (marked)"  (text, line 1380)
- "Go to the morgue (marked)"  (text, line 1380)
- "Search each body before it goes in: press E on it, check every pocket, then put it in the fire"  (text, line 1381)
- "Sort the washed and pressed Civil Protection uniforms back to their own divisions. Civil Protection units leave things in their pockets."  (text, line 1396)
- "Go to the Nexus laundry (marked)"  (text, line 1397)
- "Put each uniform in its division's bin (the bins are labelled). Bloodstained ones go to the incident wash. If you close the window, press E to open it again"  (text, line 1397)
- "File the in-tray: check each form against the register. If it all matches, file it by the first two digits of the citizen number; if anything differs, it goes in Discrepancy."  (text, line 1398)
- "Go to the civil records office (marked)"  (text, line 1399)
- "File every form: all matching the register, by the first two digits of the citizen number (37-412 in 25-49); anything different, in Discrepancy. If you close the window, press E to open it again"  (text, line 1399)
- "Four radio sets on the shelf, all hissing. Tune each one to its station, then adjust its screws until the sound comes through clean."  (text, line 1400)
- "Go to the radio repair shop (marked)"  (text, line 1401)
- "Repair the sets: turn the dial to the station, then turn the screws while you listen, until the static is gone. If you close the window, press E to open it again"  (text, line 1401)

> Note for you (not shown in game): (tests: finish a game at once)

- "Union shift"  (name, line 1410)

> Note for you (not shown in game): the game's living city quest complete moment

- "[Rations] You earned %s for that shift. You have %d now: each ration at a dispenser takes one."  (message, line 1454)
- "a ration card"  (message, line 1455)
- "ration cards"  (text, line 1455)
- "Civil rehabilitation"  (name, line 1473)

> Note for you (not shown in game): part of: build

- "Community service: {desc}"  (title, line 1483)

## writing, broadcasts, and the law (sv_livingcity_writing.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_writing.lua`


> Note for you (not shown in game): part of: open writer

- "You need paper."  (text, line 78)

> Note for you (not shown in game): mode: "note" (on the ground), "poster" (on the wall you're looking at), "keep" (in your pockets)

- "Write something."  (text, line 128)
- "You need paper."  (text, line 129)
- "Your hands are cuffed."  (text, line 130)

> Note for you (not shown in game): part of: write note

- "You can't carry any more notes. Drop one first."  (text, line 134)
- "You fold the note into your pocket."  (text, line 138)
- "You've got enough of your writing out there already."  (text, line 140)
- "Look at a wall to put it up on."  (text, line 145)
- "You put it up."  (text, line 165)
- "You leave the note."  (text, line 165)

> Note for you (not shown in game): part of: take note

- "You can't carry any more notes."  (text, line 194)
- "You take it."  (text, line 200)

> Note for you (not shown in game): part of: tear down

- "unauthorised notice removed"  (text, line 210)
- "You tear it down."  (text, line 211)

> Note for you (not shown in game): who it could be posted to, as a letter (sv_livingcity_mail.lua)

- "You've got enough of your writing out there already."  (text, line 226)

> Note for you (not shown in game): part of: carried note

- "You tear it up."  (text, line 241)

> Note for you (not shown in game): part of: broadcast

- "Only the City Administrator speaks to the whole city."  (text, line 295)
- "Say something."  (text, line 297)
- "Give the city a moment."  (text, line 298)
- "The City Administrator"  (text, line 300)
- "The City Administrator"  (text, line 301)
- "[{who}] {text}"  (chat message, line 309)

> Note for you (not shown in game): The law

- "Obey the instructions of Civil Protection at all times."  (text, line 319)
- "Carry your identification. Present it when asked."  (text, line 320)
- "Curfew is absolute. Be in your residence when it is called."  (text, line 321)
- "Gatherings of more than three citizens require a permit."  (text, line 322)
- "Do not run. Do not loiter. Do not obstruct a Civil Protection unit."  (text, line 323)
- "Possession of weapons, unregistered radios or Resistance materials is forbidden."  (text, line 324)
- "Report anticitizen activity. Inaction is conspiracy."  (text, line 325)
- "Rations are allocated by standing. Do not take what is not yours."  (text, line 326)

> Note for you (not shown in game): part of: set law

- "Only the City Administrator writes the law."  (text, line 349)
- "Write the law."  (text, line 353)
- "No such law."  (text, line 356)
- "Laws go from 1 to {list}."  (text, line 359)
- "[City] The law has changed. C > The city > The city's laws."  (chat message, line 363)

> Note for you (not shown in game): Chat

- "Usage: !setlaw <number> <text>"  (chat message, line 403)

> Note for you (not shown in game): part of: dellaw

- "Usage: !dellaw <number>"  (chat message, line 409)

## acts (shared) (sh_livingcity_acts.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_acts.lua`


> Note for you (not shown in game): name = { sequences to try (first found wins), activity to fall back to, eye height, what it's called }

- "lying down"  (label, line 24)
- "hands up"  (label, line 31)

## sh_livingcity_cp.lua (sh_livingcity_cp.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_cp.lua`


> Note for you (not shown in game): on the street

- "Move along."  (text, line 20)
- "I said move along."  (text, line 21)
- "Keep moving."  (text, line 22)
- "Move it!"  (text, line 23)
- "Move back, right now!"  (text, line 24)
- "Vacate, citizen!"  (text, line 25)
- "All right, you can go."  (text, line 29)
- "Pick up that can."  (text, line 30)
- "Now put it in the trash can."  (text, line 31)
- "Looking for trouble?"  (text, line 32)
- "Watch it."  (text, line 33)
- "Now get out of here."  (text, line 34)

> Note for you (not shown in game): warnings and arrests

- "Hold it right there!"  (text, line 37)
- "Don't move!"  (text, line 38)
- "Get down!"  (text, line 40)
- "First warning, move away."  (text, line 41)
- "This is your second warning!"  (text, line 42)
- "Final warning!"  (text, line 43)
- "You want a malcompliance verdict?"  (text, line 44)
- "Issuing malcompliant citation."  (text, line 45)
- "Prepare for judgment!"  (text, line 46)
- "Ready to prosecute."  (text, line 47)
- "Sentence delivered."  (text, line 48)
- "Final verdict administered."  (text, line 49)

> Note for you (not shown in game): on the radio and in a fight

- "Roger that."  (text, line 54)
- "Civil Protection unit is on duty, 10-8."  (text, line 55)
- "In position."  (text, line 56)
- "We are sociostable at this location."  (text, line 57)
- "Searching for suspect."  (text, line 58)
- "There he is!"  (text, line 59)
- "He's running!"  (text, line 60)
- "Suspect is bleeding."  (text, line 61)
- "11-99, officer needs assistance!"  (text, line 63)
- "Officer down, I am 10-99!"  (text, line 64)
- "Shots fired, hostile malignants!"  (text, line 65)
- "Take cover!"  (text, line 66)
- "Cover me, I'm going in."  (text, line 67)
- "All Civil Protection units, move in!"  (text, line 69)

> Note for you (not shown in game): Overwatch soldiers sound different.

- "Copy that."  (text, line 75)
- "Move in."  (text, line 77)
- "Lost contact."  (text, line 78)

> Note for you (not shown in game): City-wide sociostability. Set by events and the state of the city, or by an officer (or an admin) for a while.

- "Sociostability nominal"  (text, line 89)
- "Sociostability marginal"  (text, line 90)
- "Judgment waiver in effect"  (text, line 91)

## sh_livingcity_factions.lua (sh_livingcity_factions.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_factions.lua`

- "An ordinary resident of the city. Keep your head down, carry your papers, collect your rations. Assignments from the Union earn standing."  (description, line 44)
- "Union Worker"  (name, line 48)
- "Model Citizen"  (name, line 50)
- "The underground. Low ranks pass for ordinary citizens. Fighters wear the lambda openly and are hunted on sight outside rebel territory."  (description, line 55)
- "Combine locks, screens and terminals are your trade. You carry the multitool: hack doors open, hijack city screens, pull data off Combine terminals. It's contraband: a search will take it."  (description, line 69)
- "Moving the cell's cargo is your trade: guns, ammunition and worse, out past the units to drops all over the city. Your board (F3) has smuggling runs on it, better paid than anything a courier carries. A search that finds the cargo finds you."  (description, line 75)
- "Father Grigori"  (name, line 80)
- "Chaplain of the Resistance. A priest who will not let faith die under the Combine. He tends the wounded with his Blessing and preaches the Word aloud. The Combine have declared his faith contraband, so Civil Protection hunts him on sight outside rebel territory."  (description, line 81)
- "Free Vortigaunt"  (name, line 89)
- "A vortigaunt with the shackles off, fighting beside the people who freed it. Its vortessence heals (right click) and strikes (left click). The Combine want it back in chains, and hunt it on sight."  (description, line 90)

> Note for you (not shown in game): One career, from the records office to the Overwatch. The Overwatch ranks (overwatch = true) need the transhuman conditioning first: the Overwatch Candidate story offers it to Division Leaders. Without it, XP keeps counting but the rank stops at Division Leader.

- "Civil Protection"  (name, line 103)
- "Civil Protection: the records office, the Metropolice, and for the best of them, the Overwatch. Earn your way up. Past Division Leader there is no going back to being human."  (description, line 104)
- "Record Keeper"  (name, line 107)
- "Division Leader"  (name, line 110)
- "Combine Prison Guard"  (name, line 111)
- "Combine Soldier"  (name, line 113)
- "Elite Soldier"  (name, line 115)
- "Scanner Operator"  (name, line 120)
- "Two at a time, from any rank. Flies a city scanner from a Combine console or data terminal, or anywhere in the Nexus (F1 > Unit tools). Photographs earn XP, and a rebel caught on camera goes out to every Civil Protection unit as a BOLO."  (description, line 121)
- "Overwatch Commander"  (name, line 129)
- "One at a time, from the Elite. Calls in an Overwatch squad by dropship (F1 > Unit tools), every fifteen minutes, and commands every Civil Protection unit in the city."  (description, line 130)
- "A shackled vortigaunt: Combine property, put to work on the city's dirtiest labour. The collar holds your vortessence in. The Resistance can cut the shackles (!unshackle), if they reach you."  (description, line 140)
- "Trusted Laborer"  (name, line 144)
- "Overseer's Hand"  (name, line 145)
- "City Administrator"  (name, line 149)
- "The face of the city's government. Whitelisted by staff."  (description, line 150)
- "Director of Propaganda"  (name, line 156)
- "The city's voice. Carries the microphone: on air over every loudspeaker and screen, a minute at a time, when the transmitter is ready. Keep hold of it: the Resistance would love to use it."  (description, line 157)

> Note for you (not shown in game): not chosen: made. The worst anticitizens the city catches (sv_livingcity_custody.lua)

- "What the Combine make of the anticitizens they can't use any other way. Combine property: slow, unarmed, made to work. It lasts until you die, or the city has had its use of you."  (description, line 167)
- "What the headcrabs left behind. NPC zombies are your kin. Everyone else is food, and knows it."  (description, line 176)
- "Fast Zombie"  (name, line 180)

## sh_livingcity_jobs.lua (sh_livingcity_jobs.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_jobs.lua`

- "Sanitation Worker"  (name, line 19)
- "Sanitation depot"  (text, line 19)
- "Pick up litter, empty bins and scrub off graffiti. The city must look clean, whatever it really is."  (description, line 20)
- "Ration Production"  (name, line 21)
- "Ration plant"  (text, line 21)
- "Seal ration packs on the line, count the packs against the register, and check ration cards at the counter, catching the forged ones. Nobody cooks here: rations are made in a factory, not cooked."  (description, line 22)
- "Clinic Medic"  (name, line 23)
- "Heal injured citizens with your medkit and write down how they got hurt. Sometimes you decide what goes in the report."  (description, line 24)
- "Factory Worker"  (name, line 25)
- "Work the factory line to meet the quota: throw out the bad parts, pass the good ones. Nobody asks what the parts are for."  (description, line 26)
- "Post office"  (text, line 27)
- "Deliver letters, parcels and sealed envelopes to people all over the district."  (description, line 28)
- "Maintenance Technician"  (name, line 29)
- "Maintenance yard"  (text, line 29)
- "Repair fuse boxes, streetlights and Combine terminals. You get to see what the terminals have logged."  (description, line 30)
- "Intake Processor"  (name, line 31)
- "Train station"  (text, line 31)
- "Check travelers' tickets and papers at the train station, return lost luggage, carry freight from the loading dock, and walk new arrivals to their housing."  (description, line 32)
- "Records Clerk"  (name, line 33)
- "Civil records office"  (text, line 33)
- "File forms by citizen number at the civil records office. The cabinet of blank identity forms is rarely locked."  (description, line 34)
- "Uniform Laundry"  (name, line 35)
- "Nexus laundry"  (text, line 35)
- "Sort washed and pressed Civil Protection uniforms by division. They're supposed to be counted, and usually are."  (description, line 36)
- "City morgue"  (text, line 37)
- "Collect bodies from the streets, search them and burn them in the incinerator. Nobody checks your work closely."  (description, line 38)
- "Reclamation Crew"  (name, line 39)
- "Reclamation yard"  (text, line 39)
- "Collect scrap metal and clear rubble from the old city. Some of what's buried there was hidden on purpose."  (description, line 40)
- "Radio Repair"  (name, line 41)
- "Radio repair shop"  (text, line 41)
- "Repair loudspeakers and Union radios. Some come in tuned to frequencies that aren't supposed to exist."  (description, line 42)
- "the streets"  (text, line 43)
- "Spray the weeds coming up through the cracks before they take over: a tuft is quick, a bush takes a while. You're issued weedkiller."  (description, line 44)

> Note for you (not shown in game): (the owner, 2026-11-01: like contamination cleanup elsewhere; a faster way into Civil Protection than the records office)

- "Infestation Cleanup"  (name, line 46)
- "the infestation"  (text, line 46)
- "Into the infestation in a respirator, with weedkiller and a hoover: spray its growths dead, vacuum them up, and empty the hoover into the infestation control barrel. Civil Protection guards you; it's dangerous. Each shift counts double towards joining Civil Protection."  (description, line 47)

> Note for you (not shown in game): (the owner, 2026-11-01: something for the city's most loyal) players only, Exemplary standing; no workplace: your own block (the owner, 1 November: for the loyal, 100 standing; and not listed at all for anyone below it)

- "Block Warden"  (name, line 50)
- "your housing block"  (text, line 50)
- "For loyal citizens only (Civil Standing 100). Walk your own block, have a word with the neighbours, and report what isn't right. Paid when a report holds up; a false one costs you."  (description, line 51)

> Note for you (not shown in game): Career paths (the owner, 1 November): which jobs lead where, as the board groups them.

- "Civil Protection path"  (name, line 56)
- "Administration path"  (name, line 57)
- "Union work"  (name, line 58)

## sh_livingcity_shop.lua (sh_livingcity_shop.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_shop.lua`


> Note for you (not shown in game): Items you can carry (inventory: F2 or !inv) hunger, thirst   how much they restore (0 to 100 scale) parasite         chance of catching parasites when consumed breen            Dr. Breen's Private Reserve side effects leaves           item left in your pocket afterwards (the empty can) cooksTo          what it becomes over a stove or fire fillTo           what it becomes when filled from water cures            status it removes

- "Ration packet"  (name, line 26)
- "Breen's Private Reserve"  (name, line 27)
- "Union bread"  (name, line 28)
- "Real coffee"  (name, line 31)
- "Antiparasitic tablets"  (name, line 32)
- "Raw bird"  (name, line 34)
- "Roast bird"  (name, line 35)
- "Raw headcrab"  (name, line 36)
- "Raw fast headcrab"  (name, line 37)
- "Raw poison headcrab"  (name, line 38)
- "The venom's still in it. Cooking burns it out. Eating it raw will put you on the floor"  (description, line 39)
- "Roast headcrab"  (name, line 40)
- "Empty can"  (name, line 42)
- "Can of untreated water"  (name, line 43)
- "Can of boiled water"  (name, line 44)
- "Empty bottle"  (name, line 45)
- "Bottle of untreated water"  (name, line 46)
- "Bottle of boiled water"  (name, line 47)

> Note for you (not shown in game): rain caught straight from the sky: clean enough as it is (no boiling)

- "Can of rainwater"  (name, line 49)
- "Bottle of rainwater"  (name, line 50)

> Note for you (not shown in game): Your own papers (sv_livingcity_intake.lua): Civil Intake issues them when you register, and replaces them (for a fee) if you lose them. doc   one of your documents: weighs nothing, takes no room, and can't be dropped or handed over (stashing them is up to you)

- "Identity papers"  (name, line 58)
- "Your name, your citizen number, your block. Show: to whoever you're looking at (Civil Protection units ask), or read them yourself"  (description, line 60)
- "Ration card"  (name, line 61)
- "Earned by work: one for each Union shift you finish. A ration dispenser takes one card for each ration"  (description, line 62)

> Note for you (not shown in game): Things that change what you can do (see sv_livingcity_underground.lua) contraband   illegal to carry: searches look for it conceal      base chance it slips past a search (Guile adds to it) sell         what the dealer pays for it radio        "union" (public band, early event notices) or "resistance" (Freq 7, plus intercepted CP dispatch) permit       excuses you from one curfew or lockdown stop papers       "forged" or "dead": assume a new identity, which clears your wanted status and passes inspections (mostly) forge        turn it into forged papers somewhere private (Guile check) rationCard   a free ration from any dispenser, whatever your standing wear         a disguise: "cp" fools security NPCs and opens CP doors, "citizen" lets hunted Resistance pass as ordinary citizens tool         "lockpick" for locked doors, "bypass" for Combine doors too (1 November, the owner: every radio that isn't Civil Protection's is a Freq 7 radio. This old one, the Union radio, can't be had any more: one still in someone's pockets becomes a Freq 7 radio, sv_livingcity_underground.lua)

- "Old radio"  (name, line 82)
- "Tuned to Freq 7, like every radio that isn't Civil Protection's. Contraband"  (description, line 83)
- "Tuned to Freq 7, the Resistance's: their chat, sweep warnings, and whatever Civil Protection says when it thinks nobody is listening. It only listens: to talk on Freq 7 you also need a radio transmitter"  (description, line 86)
- "Radio transmitter"  (name, line 87)
- "A hand-held set that sends, not just listens: with a Freq 7 radio, talk on Freq 7 (switch to it like a weapon, or !r). Contraband (units have their own, on the CP net)"  (description, line 88)
- "Travel permit"  (name, line 89)
- "Stamped and legal. Gets you past one curfew stop"  (description, line 90)
- "Blank identity form"  (name, line 91)
- "Fill it in somewhere private and it becomes somebody"  (description, line 93)
- "Forged papers"  (name, line 94)
- "A new name. Clears your wanted status if no Civil Protection unit is watching"  (description, line 96)
- "A dead man's papers"  (name, line 97)
- "Genuine papers. Their owner won't be needing them"  (description, line 99)
- "Forged ration card"  (name, line 100)
- "One extra ration from any dispenser, whatever your standing"  (description, line 102)
- "Civil Protection uniform"  (name, line 103)
- "Mask and all. Civil Protection units on the street will take you for one of them, mostly"  (description, line 105)
- "Union work overalls"  (name, line 106)
- "Union-issue, a little worn. Lets anyone pass as an ordinary citizen"  (description, line 107)
- "Resistance gear"  (name, line 108)
- "Off a dead fighter. The fighters in rebel territory will take you for one of them. Civil Protection units will too"  (description, line 110)
- "Clean uniform"  (name, line 111)
- "A fresh Civil Protection uniform, pressed and bagged, for when yours is past saving (put it on: F1 > What now? > Change into clean clothes)"  (description, line 112)
- "Spare citizen clothes"  (name, line 113)
- "Union blue. Lets a hunted Resistance member pass as an ordinary citizen"  (description, line 114)
- "Lockpick set"  (name, line 115)
- "Look at a locked door and use it. Not Combine locks"  (description, line 117)
- "Combine bypass charge"  (name, line 118)
- "Opens any door once, Combine doors included. Sometimes trips an alarm"  (description, line 120)
- "Poison gas bomb"  (name, line 121)
- "Combine issue: weedkiller gas in a can, a green cloud that chokes and poisons, worse than chlorine. A unit's mask keeps it out (while its filter's good)"  (description, line 123)
- "Weedkiller, cooked down, in a bottle with a rag. Armour doesn't keep out fire: it burns whoever's in it, burns out Combine machinery, and burns the infestation's growths away"  (description, line 126)
- "Short ration"  (name, line 127)
- "A ration packet, cut by a third: what the Union gives a citizen who hasn't earned more (Trusted citizens get the full ration)"  (description, line 128)
- "Poison food or drink"  (pocket button, line 129)
- "For the weeds in the cracks and the infestation's growths (look at one, E). A few drops in someone's food or drink, and it's for them. A barnacle that eats it dies"  (description, line 130)
- "A Combine door code"  (name, line 131)
- "Seen by the vortigaunts through the vortessence, scratched on a scrap: opens one Combine door before the code is changed"  (description, line 133)
- "Civil Protection keycard"  (name, line 134)
- "Off a dead Civil Protection unit. Opens one Combine door before someone reports it missing"  (description, line 136)

> Note for you (not shown in game): Getting by (sv_livingcity_scavenge.lua) use      what "Use" does from your pockets: "fish", "plant", "spray"

- "Canned beans"  (name, line 141)
- "Pre-war. The label's gone. Probably beans"  (description, line 142)
- "Rooftop vegetables"  (name, line 143)
- "Grown in a pot on a roof somewhere. Real food"  (description, line 144)
- "Raw fish"  (name, line 145)
- "From the canal. Cook it. Really, cook it"  (description, line 146)
- "Fried fish"  (name, line 147)
- "Seed packet"  (name, line 148)
- "Plant them in a pot in rebel territory (look at it and press E, or Plant here)"  (description, line 149)
- "Fishing line"  (name, line 150)
- "Stand in the canal, or look at the water, and wait. Keeps"  (description, line 151)
- "Spray can"  (name, line 152)
- "Look at a wall and spray the lambda. Don't let a Civil Protection unit see you do it"  (description, line 154)

> Note for you (not shown in game): Making things (sv_livingcity_crafting.lua) arms     weapons and ammunition: the quartermaster pays half as much again use      "heal", "ammo" (ammo = { type, amount }), "arm" (weapon = class), "throw" (grenade = smoke, flash or gas)

- "Clean enough for a bandage"  (description, line 161)
- "Cleaning chemicals"  (name, line 162)
- "Union-issue. Mixed with the right things, they do more than clean"  (description, line 163)
- "Gun parts"  (name, line 164)
- "Springs, a barrel, a firing pin. Off a dead Civil Protection unit, or out of a smuggler's crate"  (description, line 165)
- "Patch up"  (pocket button, line 166)
- "Twenty health, give or take"  (description, line 167)
- "Box of pistol rounds"  (name, line 168)
- "Hand-loaded. Mostly reliable"  (description, line 169)
- "Box of SMG rounds"  (name, line 170)
- "Box of shells"  (name, line 172)
- "Hand-packed shells"  (description, line 173)
- "Homemade pistol"  (name, line 174)
- "Put together on a kitchen table. It fires"  (description, line 175)
- "Homemade shotgun"  (name, line 176)
- "Hard to hide. Hard to argue with"  (description, line 177)
- "It jams. Not often"  (description, line 179)
- "Smoke bomb"  (name, line 180)
- "A can of chemicals and a fuse. Thick white smoke"  (description, line 181)
- "Smoke grenade"  (name, line 182)
- "Civil Protection issue. Nobody sees through it"  (description, line 183)
- "Blinds and deafens anyone who sees it go off"  (description, line 185)
- "Chlorine gas grenade"  (name, line 186)
- "A choking green cloud. Masks protect; nothing else does"  (description, line 187)
- "Smuggled crate"  (name, line 188)
- "Heavy, and it clinks. Get it where it's going"  (description, line 189)
- "Smuggled supplies"  (name, line 190)
- "Guns and parts wrapped in rags, out of a broken crate. Get them where they're going"  (description, line 191)

> Note for you (not shown in game): Order (sv_livingcity_cp.lua)

- "Cuff someone: !cuff, looking at them (hands up, down, stopped, or from behind). Civil Protection units carry their own"  (description, line 196)
- "Civil Protection call box"  (name, line 197)
- "A little handset that calls Civil Protection to where you are, and tells them what's wrong (F1 > Request Civil Protection, or /request <what's wrong>)"  (description, line 198)

> Note for you (not shown in game): Carrying and keeping things (sv_livingcity_storage.lua) bag      extra kilograms and large things you can carry while you have it place    "crate": set down in the world as your own lockable crate

- "A canvas bag over the shoulder. Room for more, and for something large"  (description, line 205)
- "Storage crate"  (name, line 206)
- "Set it down somewhere (Set down, in your pockets) and it's yours: only you can open it. Civil Protection units can"  (description, line 207)

> Note for you (not shown in game): Trade and writing (sv_livingcity_business.lua, sv_livingcity_writing.lua)

- "CWU business license"  (name, line 211)
- "Stamped by the Civil Workers' Union. Lets you set up a market stall and trade. Officers can revoke it"  (description, line 212)
- "Market stall"  (name, line 213)
- "A folding table and a sign. Set it down (with a license) and sell from it: you set the prices"  (description, line 214)
- "Write a note to leave somewhere, a poster to put up, or one to keep"  (description, line 216)
- "Scrap metal"  (name, line 217)
- "Out of bins, junk and downed scanners. The dealer pays for it, and so does reclamation"  (description, line 218)
- "Pries scrap out of junk. A weapon too, and every Civil Protection unit knows it"  (description, line 220)
- "Combine data chip"  (name, line 221)
- "Decode / plug in"  (pocket button, line 221)
- "Two terminals' data, put together. The dealer pays well; the lab decodes it; plugged into a terminal it wipes your record"  (description, line 223)
- "Combine data fragment"  (name, line 224)
- "Half of what the Combine know: one terminal's data. Download another terminal's and the two make a whole chip"  (description, line 226)
- "Master data core"  (name, line 227)
- "Decode / plug in"  (pocket button, line 227)
- "Out of the Combine's master terminal: the motherlode. The dealer pays a fortune; the quartermaster's decoding marks every Civil Protection unit for ten minutes; plugged into a terminal it wipes every comrade's record"  (description, line 229)
- "Radio jammer"  (name, line 230)
- "Set down"  (pocket button, line 230)
- "Set it down: four minutes of static on every Civil Protection unit radio nearby, and no scanner photos get out"  (description, line 231)
- "Powered vest"  (name, line 232)
- "Put on"  (pocket button, line 232)
- "Plates and salvaged charge cells: holds a charge (75), comes with thirty in it. Charge cells (the lab's, or off a dead unit or a downed scanner) top it up, and a vortigaunt will if you ask"  (description, line 233)

> Note for you (not shown in game): the Resistance's money (sv_livingcity_funding.lua): intel only the quartermaster buys, and parts skimmed off the factory line

- "Freq 7 sheet"  (name, line 236)
- "Copied down at a radio repair bench: the rule, and the seven places on the dial Freq 7 hides. Pass it on, or burn it"  (description, line 238)
- "Notes on a patrol"  (name, line 239)
- "A unit's beat, written down: where he walks, and when. The quartermaster pays for it"  (description, line 240)
- "Notes on a checkpoint"  (name, line 241)
- "A checkpoint's shifts, its gate, its men. The quartermaster pays for it"  (description, line 242)
- "Notes on the Combine's ground"  (name, line 243)
- "The approaches to the Combine's own ground. The quartermaster pays well for it"  (description, line 244)
- "Copied city records"  (name, line 245)
- "The city's own records, copied out by someone inside: names, routes, who's being watched. The best intel there is"  (description, line 246)
- "Union machine parts"  (name, line 247)
- "Finished parts, skimmed off the factory line. The dealer moves them; the quartermaster pays more (they end up in guns)"  (description, line 248)
- "Charge cell"  (name, line 249)
- "Charge your vest"  (pocket button, line 249)
- "A salvaged suit cell: twenty-five charge into a powered vest you're wearing"  (description, line 250)
- "Box of .357 rounds"  (name, line 251)
- "Six heavy rounds, hand-loaded"  (description, line 252)
- "Homemade revolver"  (name, line 253)
- "Machined at a workbench. Loud, heavy, final"  (description, line 254)
- "Wedding ring"  (name, line 255)
- "It belonged to somebody"  (description, line 256)

> Note for you (not shown in game): The Union Commissary item      goes into your inventory entity    spawns in front of you (health vials, batteries) ammo      { type, amount } civOnly   never offered to units (citizen clothes: the owner, 1 November) cpOnly    units only, and sold only at the Civil Protection Commissary's counter (the Union terminal sells them only in a city without one)

- "Nutrient bar and a little water. It keeps you alive."  (description, line 343)
- "Clean, cold, refreshing. Do not ask what is in it."  (description, line 344)
- "An empty glass bottle, for whatever water you can find."  (description, line 345)
- "For what the canal water gives you."  (description, line 346)
- "Union-issue work clothes. Everyone looks the same in them."  (description, line 347)
- "For the weeds in the cracks. Keep it away from food."  (description, line 348)
- "One night out after curfew, stamped and legal."  (description, line 349)
- "Grey, dense, and real."  (description, line 350)
- "Powdered, reconstituted, nearly milk."  (description, line 351)
- "Health vial"  (name, line 352)
- "For the trusted."  (description, line 352)
- "A whole watermelon. Exemplary citizens only."  (description, line 353)
- "Real coffee. You'd forgotten the smell."  (description, line 354)
- "Medical kit"  (name, line 355)
- "A full medical kit."  (description, line 355)
- "Something wrong? It calls Civil Protection to where you are."  (description, line 356)

> Note for you (not shown in game): (no spare cuffs for sale: a unit's own never run out, and it read as though they had to buy them; the owner, 1 November)

- "For notes, letters and notices."  (description, line 358)
- "The Union's permission to trade from a stall."  (description, line 359)
- "Everything you need to sell. A license not included."  (description, line 360)
- "Carry more. Eight more kilos, and one more large thing."  (description, line 361)
- "Somewhere of your own to keep things. Civil Protection units can open it."  (description, line 362)
- "Line and a hook. The canal has fish, of a kind."  (description, line 363)
- "Cover for an advance, or a retreat."  (description, line 364)
- "Metrocops and up. Don't look at it."  (description, line 365)
- "Division Leaders and the Overwatch. For clearing anticitizen holdouts."  (description, line 366)
- "Weedkiller gas: worse than chlorine, and your mask keeps it out."  (description, line 367)
- "A clean uniform, for when yours is past saving. It happens to the best of us."  (description, line 368)
- "Pistol ammunition"  (name, line 369)
- "Standard issue."  (description, line 369)
- "For Civil Protection units in good standing."  (description, line 370)
- "Suit battery"  (name, line 371)
- "Armor recharge."  (description, line 371)

> Note for you (not shown in game): The black market (a dealer placed with the editor, or rebel territory) weapon    given straight to you Standing doesn't matter here. Credits do. Units who walk up to a dealer don't buy anything: they bust it.

- "Already tuned to Freq 7."  (description, line 388)
- "Good work. Not perfect work."  (description, line 389)
- "For people with a steady hand."  (description, line 390)
- "One more meal than the Union thinks you deserve."  (description, line 391)
- "Picks, tension wrench, patience not included."  (description, line 392)
- "One use. Don't ask where it came from."  (description, line 393)
- "Clean, plain, forgettable."  (description, line 394)
- "Off a Civil Protection unit who won't be needing it."  (description, line 395)
- "No questions about why you need them."  (description, line 396)
- "Every revolution starts somewhere."  (description, line 397)
- "Opens Combine locks, screens and terminals. Very illegal. Don't get searched."  (description, line 398)
- "Springs, barrels, pins. Make something with them."  (description, line 399)
- "Bought by the bottle. Nobody cleans that much."  (description, line 400)
- "Tomatoes, beans, maybe. Plant them in rebel territory."  (description, line 401)
- "Pre-war tins. Nobody asks where they come from."  (description, line 402)
- "For a Civil Protection unit who needs to stay put."  (description, line 403)
- "No questions about what goes in it."  (description, line 404)
- "Spray cans (3)"  (name, line 405)
- "Let the city know we're still here."  (description, line 405)

> Note for you (not shown in game): what the Resistance's lab makes (sv_livingcity_lab.lua); everyone else pays the dealer for it

- "Chemicals in a can, and a fuse."  (description, line 407)
- "Eighteen rounds. Hand-loaded, mostly reliable."  (description, line 408)
- "Twelve shells."  (description, line 409)
- "Forty-five rounds."  (description, line 410)
- "Six heavy rounds."  (description, line 411)
- "Put together on somebody's kitchen table. It fires."  (description, line 412)
- "It jams. Not often."  (description, line 413)
- "Hard to hide. Hard to argue with."  (description, line 414)
- "Loud, heavy, final."  (description, line 415)
- "Plates and salvaged charge cells. Holds a charge; comes with thirty in it."  (description, line 416)
- "Talk on your radio's band, not just listen. Contraband."  (description, line 417)
- "Four minutes of static on every Civil Protection unit radio nearby."  (description, line 418)

> Note for you (not shown in game): Making things by hand (F2): just these, anywhere. Everything else (guns, ammunition, armour, jammers, bypass charges, smoke bombs, a radio tuned to Freq 7) is the Resistance lab's (LCS.Lab, below) or the black market's. private   out of any unit's sight (a tunnel or back room will do)

- "Bent and filed scrap"  (description, line 458)
- "Rags, torn into strips"  (description, line 459)

> Note for you (not shown in game): The Resistance lab (sv_livingcity_lab.lua): what the scientist makes, for the Resistance only. Bring him the materials (needs) and he makes it for nothing; or pay him: 60% of the dealer's price (never less than the quartermaster pays for it). secs: how long he takes.

- "Eighteen pistol rounds"  (description, line 472)
- "Twelve shotgun shells"  (description, line 473)
- "Forty-five SMG rounds"  (description, line 474)
- "Six .357 rounds"  (description, line 475)
- "A powered vest: holds a charge (charge cells top it up)"  (description, line 480)
- "A charge cell: twenty-five charge into your vest"  (description, line 481)
- "Five forged ration cards: the dealer buys them, the dispensers take them. The more turn up, the hotter the search for the forger"  (description, line 483)
- "Thick white smoke"  (description, line 484)
- "Opens any door once"  (description, line 485)
- "Weedkiller, cooked down, in a bottle with a rag: fire, which armour doesn't keep out"  (description, line 486)
- "Two canisters of weedkiller, cooked down into chemicals"  (description, line 487)
- "A Freq 7 radio rebuilt to send as well as listen"  (description, line 488)
- "A radio that only screams"  (description, line 489)
- "Bar stock, heated and bent"  (description, line 490)

## shared.lua (shared.lua)

`gamemodes/livingcity/gamemode/shared.lua`

- "Living City"  (text, line 17)

