# Every line of text a player sees

Made by `python3 _dev/player_text.py` from the code itself, so it can be made again after any change. Grouped by the part of the game it belongs to. Each line: the text (parts the game fills in look like {name}, and %d, %s or %.1f are numbers or words filled in), how it shows (a chat message, an on-screen notice, a button...), and when: the code's own note above it, or the function it's in. The file and line are there so a correction can be found.

**How to correct it:** change the words inside the quotes, then send the whole file back. Leave everything outside the quotes as it is (that's how each line is found in the code again). Keep any {name} or %d / %s parts: the game fills those in. A line you don't touch stays as it is. To drop a line altogether, write DELETE inside its quotes. A note for me about a line can go after it on the same line, starting with NOTE:.

Made from version e5e3a89. Admin-only console messages and log lines are left out.

5735 lines, from 175 files.

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
- [lc_intake.lua](#lcintakelua-lcintakelua) (1)
- [lc_item.lua](#lcitemlua-lcitemlua) (2)
- [lc_item_ration.lua](#lcitemrationlua-lcitemrationlua) (1)
- [lc_item_water.lua](#lcitemwaterlua-lcitemwaterlua) (1)
- [lc_jammer.lua](#lcjammerlua-lcjammerlua) (1)
- [lc_lawboard.lua](#lclawboardlua-lclawboardlua) (1)
- [lc_masterterminal.lua](#lcmasterterminallua-lcmasterterminallua) (1)
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
- [weapon_lc_microphone.lua](#weaponlcmicrophonelua-weaponlcmicrophonelua) (4)
- [weapon_lc_multitool.lua](#weaponlcmultitoollua-weaponlcmultitoollua) (14)
- [weapon_lc_vort.lua](#weaponlcvortlua-weaponlcvortlua) (10)
- [cl_init.lua](#clinitlua-clinitlua) (233)
- [init.lua](#initlua-initlua) (5)
- [cl_livingcity.lua](#cllivingcitylua-cllivingcitylua) (21)
- [cl_livingcity_actions.lua](#cllivingcityactionslua-cllivingcityactionslua) (47)
- [cl_livingcity_admintools.lua](#cllivingcityadmintoolslua-cllivingcityadmintoolslua) (22)
- [cl_livingcity_atmos.lua](#cllivingcityatmoslua-cllivingcityatmoslua) (5)
- [cl_livingcity_character.lua](#cllivingcitycharacterlua-cllivingcitycharacterlua) (14)
- [cl_livingcity_cp.lua](#cllivingcitycplua-cllivingcitycplua) (26)
- [secret endings, on your screen (sv_livingcity_endings.lua)](#secret-endings-on-your-screen-svlivingcityendingslua-cllivingcityendingslua) (65)
- [the Endings menu (superadmins): tune the secret endings live](#the-endings-menu-superadmins-tune-the-secret-endings-live-cllivingcityendingtunelua) (69)
- [morning exercise, on your screen (sv_livingcity_exercise.lua)](#morning-exercise-on-your-screen-svlivingcityexerciselua-cllivingcityexerciselua) (11)
- [cl_livingcity_factions.lua](#cllivingcityfactionslua-cllivingcityfactionslua) (21)
- [cl_livingcity_grigori.lua](#cllivingcitygrigorilua-cllivingcitygrigorilua) (10)
- [cl_livingcity_hints.lua](#cllivingcityhintslua-cllivingcityhintslua) (11)
- [cl_livingcity_infest.lua](#cllivingcityinfestlua-cllivingcityinfestlua) (9)
- [cl_livingcity_intake.lua](#cllivingcityintakelua-cllivingcityintakelua) (33)
- [cl_livingcity_jobgames.lua](#cllivingcityjobgameslua-cllivingcityjobgameslua) (11)
- [cl_livingcity_kick.lua](#cllivingcitykicklua-cllivingcitykicklua) (11)
- [cl_livingcity_lab.lua](#cllivingcitylablua-cllivingcitylablua) (9)
- [cl_livingcity_lagwatch.lua](#cllivingcitylagwatchlua-cllivingcitylagwatchlua) (27)
- [cl_livingcity_layoutbrowser.lua](#cllivingcitylayoutbrowserlua-cllivingcitylayoutbrowserlua) (33)
- [cl_livingcity_life.lua](#cllivingcitylifelua-cllivingcitylifelua) (11)
- [cl_livingcity_moregames.lua](#cllivingcitymoregameslua-cllivingcitymoregameslua) (38)
- [cl_livingcity_needs.lua](#cllivingcityneedslua-cllivingcityneedslua) (66)
- [cl_livingcity_nextstep.lua](#cllivingcitynextsteplua-cllivingcitynextsteplua) (23)
- [cl_livingcity_notices.lua](#cllivingcitynoticeslua-cllivingcitynoticeslua) (15)
- [cl_livingcity_outfits.lua](#cllivingcityoutfitslua-cllivingcityoutfitslua) (14)
- [cl_livingcity_quests.lua](#cllivingcityquestslua-cllivingcityquestslua) (17)
- [cl_livingcity_quick.lua](#cllivingcityquicklua-cllivingcityquicklua) (51)
- [apartment doors (client)](#apartment-doors-client-cllivingcityrentlua) (11)
- [cl_livingcity_resistance.lua](#cllivingcityresistancelua-cllivingcityresistancelua) (5)
- [cl_livingcity_rest.lua](#cllivingcityrestlua-cllivingcityrestlua) (5)
- [cl_livingcity_rp.lua](#cllivingcityrplua-cllivingcityrplua) (7)
- [the scanner link, as the pilot sees it, and scanner reports,](#the-scanner-link-as-the-pilot-sees-it-and-scanner-reports-cllivingcityscannerlua) (6)
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
- [the time of day, the weather, and the city's music](#the-time-of-day-the-weather-and-the-citys-music-svlivingcityatmoslua) (7)
- [the dead](#the-dead-svlivingcitybodieslua) (9)
- [apartments and trade](#apartments-and-trade-svlivingcitybusinesslua) (37)
- [rearranging a rebel camp](#rearranging-a-rebel-camp-svlivingcitycampmovelua) (3)
- [characters and permanent death](#characters-and-permanent-death-svlivingcitycharacterlua) (28)
- [checkpoints, turrets, and holding the infestation back](#checkpoints-turrets-and-holding-the-infestation-back-svlivingcitycheckpointslua) (48)
- [Half-Life: Alyx-style Combine models](#half-life-alyx-style-combine-models-svlivingcitycombinemodelslua) (3)
- [conduct (anti-RDM and anti-combat-logging)](#conduct-anti-rdm-and-anti-combat-logging-svlivingcityconductlua) (26)
- [supply drops, radio jammers](#supply-drops-radio-jammers-svlivingcityconvoylua) (33)
- [Civil Protection's toolset](#civil-protections-toolset-svlivingcitycplua) (93)
- [the Civil Protection Commissary (units' supplies)](#the-civil-protection-commissary-units-supplies-svlivingcitycpsupplylua) (8)
- [making things, grenades, the arms trade, and getting people out](#making-things-grenades-the-arms-trade-and-getting-people-out-svlivingcitycraftinglua) (28)
- [what custody costs the worst anticitizens](#what-custody-costs-the-worst-anticitizens-svlivingcitycustodylua) (29)
- [saved layout](#saved-layout-svlivingcitydatalua) (14)
- [debugging](#debugging-svlivingcitydebuglua) (59)
- [doors](#doors-svlivingcitydoorslua) (8)
- [the Combine's dropship](#the-combines-dropship-svlivingcitydropshiplua) (7)
- [economy and social credit](#economy-and-social-credit-svlivingcityeconomylua) (31)
- [secret endings](#secret-endings-svlivingcityendingslua) (76)
- [escorts through Combine doors](#escorts-through-combine-doors-svlivingcityescortlua) (73)
- [city events](#city-events-svlivingcityeventslua) (78)
- [morning exercise (mandatory for citizens)](#morning-exercise-mandatory-for-citizens-svlivingcityexerciselua) (54)
- [sv_livingcity_factions.lua](#svlivingcityfactionslua-svlivingcityfactionslua) (31)
- [Freq 7, the Resistance's pirate broadcast](#freq-7-the-resistances-pirate-broadcast-svlivingcityfreq7lua) (6)
- [the Resistance's money (besides raiding supply drops)](#the-resistances-money-besides-raiding-supply-drops-svlivingcityfundinglua) (16)
- [Father Grigori, in the flesh](#father-grigori-in-the-flesh-svlivingcitygrigorilua) (16)
- [flood guard](#flood-guard-svlivingcityguardlua) (3)
- [stealing the Combine's data](#stealing-the-combines-data-svlivingcityheistlua) (32)
- [tips that pop up the first time something happens](#tips-that-pop-up-the-first-time-something-happens-svlivingcityhintslua) (326)
- [housing blocks](#housing-blocks-svlivingcityhousinglua) (5)
- [toilets, baths and what happens without them](#toilets-baths-and-what-happens-without-them-svlivingcityhygienelua) (48)
- [Civil Intake (becoming somebody)](#civil-intake-becoming-somebody-svlivingcityintakelua) (75)
- [work you actually do](#work-you-actually-do-svlivingcityjobgameslua) (92)
- [the unit's kick](#the-units-kick-svlivingcitykicklua) (23)
- [the Resistance lab](#the-resistance-lab-svlivingcitylablua) (50)
- [a life](#a-life-svlivingcitylifelua) (42)
- [Resistance lookouts](#resistance-lookouts-svlivingcitylookoutslua) (14)
- [letters](#letters-svlivingcitymaillua) (14)
- [marched to the cells](#marched-to-the-cells-svlivingcitymarchlua) (17)
- [more work you actually do (the engine is sv_livingcity_jobgames.lua)](#more-work-you-actually-do-the-engine-is-svlivingcityjobgameslua-svlivingcitymoregameslua) (178)
- [hauling the dead](#hauling-the-dead-svlivingcitymortuarylua) (20)
- [routes over the map's own nodegraph](#routes-over-the-maps-own-nodegraph-svlivingcitynavgraphlua) (1)
- [what now?](#what-now-svlivingcitynextsteplua) (35)
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
- [quests](#quests-svlivingcityquestslua) (357)
- [habitation block raids](#habitation-block-raids-svlivingcityraidslua) (13)
- ["ration units are being deducted"](#ration-units-are-being-deducted-svlivingcityrationslua) (5)
- [rebel life](#rebel-life-svlivingcityrebellifelua) (34)
- [the Resistance on the street](#the-resistance-on-the-street-svlivingcityrebelslua) (68)
- [the Resistance's operations, and what the city does about them](#the-resistances-operations-and-what-the-city-does-about-them-svlivingcityresistanceopslua) (95)
- [escalation](#escalation-svlivingcityresponselua) (24)
- [sleep](#sleep-svlivingcityrestlua) (10)
- [talking, knowing each other, and going down](#talking-knowing-each-other-and-going-down-svlivingcityrplua) (47)
- [running in front of Civil Protection](#running-in-front-of-civil-protection-svlivingcityrunninglua) (23)
- [salvage, bins anywhere, the reclamation point, and workbenches](#salvage-bins-anywhere-the-reclamation-point-and-workbenches-svlivingcitysalvagelua) (42)
- [flying a scanner from a Combine console](#flying-a-scanner-from-a-combine-console-svlivingcityscannerlua) (46)
- [getting by](#getting-by-svlivingcityscavengelua) (60)
- [Combine-only areas](#combine-only-areas-svlivingcitysecuritylua) (10)
- [jobs that come with supply drops, and Union work orders that](#jobs-that-come-with-supply-drops-and-union-work-orders-that-svlivingcitysidejobslua) (95)
- [character slots](#character-slots-svlivingcityslotslua) (20)
- [staff tools](#staff-tools-svlivingcitystafflua) (48)
- [the stalker's lot](#the-stalkers-lot-svlivingcitystalkerworklua) (56)
- [static map props](#static-map-props-svlivingcitystaticpropslua) (10)
- [the city's stores](#the-citys-stores-svlivingcitystockpilelua) (8)
- [places to keep things](#places-to-keep-things-svlivingcitystoragelua) (43)
- [story chains](#story-chains-svlivingcitystorieslua) (284)
- [survival](#survival-svlivingcitysurvivallua) (57)
- [talking to people](#talking-to-people-svlivingcitytalklua) (28)
- [territory that spreads, and is pushed back](#territory-that-spreads-and-is-pushed-back-svlivingcityterritorylua) (28)
- [the trains](#the-trains-svlivingcitytrainslua) (9)
- [the underground](#the-underground-svlivingcityundergroundlua) (171)
- [powered vests ("suit power")](#powered-vests-suit-power-svlivingcityvestlua) (4)
- [vortigaunts](#vortigaunts-svlivingcityvortlua) (11)
- [the state of the city](#the-state-of-the-city-svlivingcitywarlua) (58)
- [ways to get by](#ways-to-get-by-svlivingcitywayslua) (5)
- [occupations](#occupations-svlivingcityworklua) (276)
- [writing, broadcasts, and the law](#writing-broadcasts-and-the-law-svlivingcitywritinglua) (37)
- [acts (shared)](#acts-shared-shlivingcityactslua) (2)
- [sh_livingcity_cp.lua](#shlivingcitycplua-shlivingcitycplua) (44)
- [sh_livingcity_factions.lua](#shlivingcityfactionslua-shlivingcityfactionslua) (30)
- [sh_livingcity_jobs.lua](#shlivingcityjobslua-shlivingcityjobslua) (32)
- [sh_livingcity_shop.lua](#shlivingcityshoplua-shlivingcityshoplua) (217)
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

*When:* part of: draw

- "Commissary: Civil Protection units are issued supplies here"  (drawn on screen, line 59)

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

*When:* part of: use

- "Dead. No power: no rations until it's back."  (chat message, line 42)

## lc_dropship.lua (lc_dropship.lua)

`gamemodes/livingcity/entities/entities/lc_dropship.lua`

- "Combine dropship"  (name, line 10)

## lc_fire.lua (lc_fire.lua)

`gamemodes/livingcity/entities/entities/lc_fire.lua`

- "Burning barrel"  (name, line 7)

## lc_forcefield.lua (lc_forcefield.lua)

`gamemodes/livingcity/entities/entities/lc_forcefield.lua`

- "Combine forcefield"  (name, line 16)

## lc_intake.lua (lc_intake.lua)

`gamemodes/livingcity/entities/entities/lc_intake.lua`

- "Civil Intake terminal"  (name, line 13)

## lc_item.lua (lc_item.lua)

`gamemodes/livingcity/entities/entities/lc_item.lua`


*When:* part of: use

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

## lc_powerbank.lua (lc_powerbank.lua)

`gamemodes/livingcity/entities/entities/lc_powerbank.lua`

- "Combine power bank"  (name, line 12)

## lc_recycler.lua (lc_recycler.lua)

`gamemodes/livingcity/entities/entities/lc_recycler.lua`

- "Reclamation point"  (name, line 9)

*When:* part of: draw

- "Scrap  Cans  Bottles"  (text, line 48)

## lc_rscanner.lua (lc_rscanner.lua)

`gamemodes/livingcity/entities/entities/lc_rscanner.lua`

- "Linked scanner"  (name, line 8)

*When:* it winks out: a pop of energy and a spark, and nothing left behind. No debris and no scrap, so nobody risks their neck for parts that aren't there (it was put up from a console, and could be put up again and again)

- "The scanner was shot down. The link drops."  (text, line 49)

## lc_scientist.lua (lc_scientist.lua)

`gamemodes/livingcity/entities/entities/lc_scientist.lua`

- "Resistance scientist"  (name, line 12)

## lc_screen.lua (lc_screen.lua)

`gamemodes/livingcity/entities/entities/lc_screen.lua`

- "City screen"  (name, line 10)

## lc_stall.lua (lc_stall.lua)

`gamemodes/livingcity/entities/entities/lc_stall.lua`

- "Market stall"  (name, line 10)

*When:* the sign: whose stall it is

- "Licensed by the CWU. Press E"  (drawn on screen, line 41)

## lc_supply.lua (lc_supply.lua)

`gamemodes/livingcity/entities/entities/lc_supply.lua`

- "Union supply crate"  (name, line 9)

## lc_terminal.lua (lc_terminal.lua)

`gamemodes/livingcity/entities/entities/lc_terminal.lua`

- "Union Commissary terminal"  (name, line 7)

*When:* part of: use

- "The screen's dark. No power."  (chat message, line 30)

## lc_vending.lua (lc_vending.lua)

`gamemodes/livingcity/entities/entities/lc_vending.lua`

- "Water vending machine"  (name, line 7)

*When:* part of: use

- "Dead. No power: the machine won't take your credits."  (chat message, line 30)

## lc_workbench.lua (lc_workbench.lua)

`gamemodes/livingcity/entities/entities/lc_workbench.lua`

- "Resistance lab"  (name, line 17)

## weapon_lc_baton.lua (weapon_lc_baton.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_baton.lua`

- "Arrest Baton"  (name, line 10)

*When:* part of: tell

- "[Living City] {msg}"  (chat message, line 47)

*When:* part of: secondary attack

- "You can't arrest another Civil Protection unit."  (chat message, line 88)
- "Arrested by {Nick}"  (text, line 89)
- "is in custody."  (text, line 90)
- "Couldn't arrest: {err}"  (text, line 90)
- "Citizen detained. They're taken to a cell."  (chat message, line 93)
- "Couldn't arrest: {err}"  (text, line 93)

## weapon_lc_blessing.lua (weapon_lc_blessing.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_blessing.lua`

- "The Blessing"  (name, line 14)

*When:* part of: heal

- "tending the wounded"  (text, line 66)

*When:* part of: primary attack

- "[Blessing] The infected are beyond your help."  (chat message, line 85)
- "[Blessing] Father Grigori lays a hand on your shoulder. You feel stronger."  (chat message, line 91)

*When:* part of: secondary attack

- "[Blessing] Your prayer comforts {healed} soul(s)."  (text, line 107)
- "[Blessing] You pray alone."  (chat message, line 107)

*When:* they stop and listen for a moment

- "Unlawful preaching"  (text, line 130)

## weapon_lc_microphone.lua (weapon_lc_microphone.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_microphone.lua`


*When:* part of: holster

- "off air"  (text, line 45)

*When:* part of: draw hud

- "ON AIR  %ds   Hold your voice key and speak (or type). Left click to stop."  (message, line 55)
- "MICROPHONE: the transmitter is cooling down (%d:%02d)"  (message, line 58)
- "MICROPHONE: left click to go live over every loudspeaker and screen"  (text, line 59)

## weapon_lc_multitool.lua (weapon_lc_multitool.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_multitool.lua`


*When:* What the tool would do with whatever you're pointing at (shared, for the HUD and the click).

- "Hijack the city screen"  (text, line 43)
- "Download the Combine's data"  (text, line 44)

*When:* part of: job

- "Download the master terminal (the motherlode)"  (text, line 45)
- "Hack the vending machine (free water)"  (text, line 46)
- "Hack the ration dispenser (rations, no coupon)"  (text, line 47)
- "Sabotage the transformer (the district goes dark)"  (text, line 48)
- "Short out the power bank (its turrets and forcefields die with it)"  (text, line 50)
- "Short out the forcefield"  (text, line 53)
- "Hack the Combine lock"  (text, line 55)
- "Cut the vortigaunt's shackles"  (text, line 56)
- "Download the master terminal (the motherlode)"  (text, line 61)
- "Download the Combine's data"  (text, line 61)

*When:* part of: primary attack

- "Nothing here the multitool can work on. (A Combine door, a city screen, a data terminal, a shackled vortigaunt, a transformer, a forcefield, a power bank, a vending machine, a ration dispenser.)"  (text, line 89)

*When:* part of: draw hud

- "MULTITOOL: point at a Combine door, a city screen, a data terminal or a vending machine"  (text, line 101)

## weapon_lc_vort.lua (weapon_lc_vort.lua)

`gamemodes/livingcity/entities/weapons/weapon_lc_vort.lua`


*When:* part of: primary attack

- "The collar holds your vortessence in."  (chat message, line 51)

*When:* part of: secondary attack

- "The collar holds your vortessence in."  (chat message, line 79)
- "Your vortessence is gathering (%ds)."  (message, line 82)
- "There is nothing left in them to charge."  (chat message, line 87)

*When:* the vortessence charges a vest (sv_livingcity_vest.lua); it doesn't knit flesh

- "You wear nothing for the vortessence to charge."  (chat message, line 90)
- "They wear no vest for the vortessence to charge."  (chat message, line 90)
- "Your vest is full."  (chat message, line 92)
- "Their vest is full."  (chat message, line 92)

*When:* part of: secondary attack

- "A warmth runs through your vest. The vortigaunt's hands glow green, and the cells hum."  (chat message, line 97)
- "charging with the vortessence"  (text, line 98)

## cl_init.lua (cl_init.lua)

`gamemodes/livingcity/gamemode/cl_init.lua`

- "F1  the quick menu: nine things on the number keys, for who you are and what's in front of you (0 closes; 9 is everything else)"  (text, line 29)
- "Union work you do with your hands: Sanitation's street sweep (push the cart, throw the rubbish in), the Factory line (bin the rust-red parts), the Intake Processor's papers check (approve, deny, or call a Civil Protection unit)."  (text, line 30)
- "More of it: Maintenance rewires circuit boards against the clock (turn the tiles till the current reaches the lamp; a sparking tile bites), Clinic Medics triage patients bleeding out, the Reclamation Crew breaks up rubble with a crowbar."  (text, line 31)
- "And more: Couriers run parcels against the clock past Civil Protection units who want to search them, the Mortuary searches the dead before the fire (log it, keep it, or keep it for the family; mind the overseer), the Laundry sorts uniforms by division, Records Clerks file forms and catch mismatches, Radio Repair finds each set's station and turns its trimmer screws by ear until it's clean (and sometimes finds Freq 7; record your own broadcasts in sound/livingcity/radio/)."  (text, line 32)
- "Some of the city's rarer moments have flashing lights and strobes: you're warned first, and lc_ending_calm 1 in the console leaves the flashing out, just for you."  (text, line 33)
- "A radio in your pockets has Listen: turn the dial through the static to the Union band (96.4) or, if you can find it, Freq 7. Anyone nearby hears it, Civil Protection units included."  (text, line 34)
- "Freq 7 is a rule, not a number: the Resistance only broadcast where the digits add up to seven. The Combine jam it when they find it, and it comes back on another; a Resistance radio follows it by itself."  (text, line 35)
- "Write Freq 7 down at the repair bench and you carry a Freq 7 sheet: the seven frequencies, to read or pass on. It's contraband."  (text, line 36)
- "The Resistance doctor records at a terminal (stop the needle in the band; hands off while the scanner passes) and hide dead drops unseen. Civil Protection units pat citizens down a place at a time, and breach doors on block raids. If you close a game's panel, E brings it back."  (text, line 37)
- "Lost? {gm_showhelp} > What now? is always your next step, with the way there; What now? > Places marks anywhere worth knowing (the dispenser, water, your block, your work)."  (text, line 38)
- "F2  your pockets (and stash at home)        F3  your board: jobs, stories, Union employment        F4  factions"  (text, line 39)
- "C (outside build mode)  the full menu: everything you can do, with this guide, your pockets, board, factions and tips at the top."  (text, line 40)
- "E on people: talk to citizens, report to Civil Protection units. E on things: pick up, use."  (text, line 41)
- "Everything you can do is in the menus (units: C > Unit tools). Chat commands like !backup still work, but you never need them."  (text, line 42)
- "Warnings and announcements show on your screen as well as in chat: people talking to you as subtitles, the rest as cards at the top. C > Settings turns the cards off."  (text, line 43)
- "Death, and close calls"  (text, line 45)
- "Each person has three close calls: you die, and wake in the infirmary with your pockets emptied and no memory of the fight (leave it be)."  (text, line 46)
- "A used close call comes back after a few hours of that person's life. The death after the last one is the end of them: !characters shows how many you have."  (text, line 47)
- "When a person ends you come back as someone new, with a new name and citizen number, and nothing but a little inherited from them."  (text, line 48)
- "Some things are for life: the Overwatch conditioning, being made a stalker. To be someone else, play another character, or retire this one (!characters)."  (text, line 49)
- "The Union levies hoarded credits: above 2000, a tenth of the excess goes every half hour. Spend it."  (text, line 50)
- "The screen goes dark and a card says who they were: how long they lived, how many people knew their name, what killed them."  (text, line 51)
- "The people who knew their name hear about it a minute or two later, in passing (or when they're next in the city)."  (text, line 52)
- "Arriving: Civil Intake"  (text, line 54)
- "In a city with Civil Intake, a new person arrives with nothing: no papers, no room, no ration card."  (text, line 55)
- "Civil Intake (the marker on your screen): E opens the terminal's registration screen. Enter your name, your face, how a stranger would know you, submit it, and stay beside the terminal while it processes you. Your identity papers and ration card go in your pockets (F2), and the screen points you to Housing Allocation."  (text, line 56)
- "Then Housing Allocation: E opens the housing register. Present your papers and apply for a block: any block is approved at once (the least crowded); a crowded one needs Civil Standing 50. It marks the way home."  (text, line 57)
- "Housed already? The same screen says where you live and how you got it, marks the way home, and takes transfer requests (standing 25, once every half hour)."  (text, line 58)
- "Your papers: identity papers and a ration card, in your pockets (F2). Civil Protection units ask for papers (carrying none costs a little standing); the dispensers want the card. Lost them? Civil Intake replaces them (10 and 15 credits)."  (text, line 59)
- "Show your papers: look at someone, F1 > Show them my papers (or F2 > Identity papers > Show). They see the card, and learn your name."  (text, line 60)
- "Until you're registered: no rations (a forged ration card works), no Union job, no Commissary, and Civil Protection units ask for papers. Leave it too long and it's a crime."  (text, line 61)
- "One person at a desk at a time. New arrivals off the train queue too. F1 > My papers says where you stand."  (text, line 62)
- "How the city looks and feels"  (text, line 64)
- "Your eyes sit a little lower than everyone else's, and the view is no wider than Half-Life 2's: the city is big, and you're not."  (text, line 65)
- "The camera sways a little with your steps and dips when you land. C > Settings > Camera sway keeps it still, just for you."  (text, line 66)
- "Nothing on screen keeps score: your credits and Civil Standing are at the top of your pockets (F2), your rank and progress on F4."  (text, line 67)
- "Hunger and thirst show at the top left once they start to bite, and for a moment after you eat or drink."  (text, line 68)
- "Staying alive"  (text, line 70)
- "Eat and drink. Ration dispensers and the ration line feed you; the Commissary (a terminal, or C > Getting by) sells the rest."  (text, line 71)
- "Wade into water and press E to drink, but boil it first if you can (stove or fire, F2). A sink has to be in plain sight to use."  (text, line 72)
- "Parasites (coughing, hunger, thirst) never wear off: antiparasitic tablets from a medic or the black market clear them."  (text, line 73)
- "Parasites also mean you'll need a toilet (E on one). Ignore it and you soil yourself: then a toilet, a wash (a bathtub or shower) and clean clothes, or people back away from your stink."  (text, line 74)
- "Sleep once a day: E on a bed at night. Without it your eyes droop, you can't run and you're weaker. A good night leaves you well rested."  (text, line 75)
- "Your fists kill birds. Cook them."  (text, line 76)
- "Staying out of trouble"  (text, line 78)
- "Don't crowd Civil Protection. Warnings come first, then the stick."  (text, line 79)
- "When a Civil Protection unit stops you, stand still. Anything illegal in your pockets may be found."  (text, line 80)
- "Crouch to sneak: a Civil Protection unit sees you at half the distance, less again creeping slowly or in the dark, and not at all behind his back. While you crouch, a bar shows how easily you're seen, and each unit's sight is shown in front of him (red: he sees you)."  (text, line 81)
- "Wanted but you've hurt nobody? Units run you down and cuff you; they shoot at the violent (or at a gun in your hand)."  (text, line 82)
- "Sleeping in a bed you lie still and heal; press Jump to get up. Rations out mid-shift? C menu > Take a ration break: the job waits."  (text, line 83)
- "Resistance: with fighters along, C menu > Resistance > Squad: act casual (plain clothes, guns away), guns out, or meet me at the job's marker. Hold E on a camp's mattress, crate or chair to move it (let go to set it down, R turns it). At your stash, Stash it puts away the weapon in your hands."  (text, line 84)
- "Everyone works: the Union assigns a registered citizen a job if they have none (ask for another on F3 > Jobs). Idle hands are noticed."  (text, line 85)
- "Curfew: you get a minute to reach your housing block (a fresh one each time you respawn into a curfew). A travel permit gets you past one stop."  (text, line 86)
- "Morning exercise (every second dawn, mandatory for citizens): report where your HUD points. The jog: keep jogging and keep up with the pace marker, or the Civil Protection units along the route use the stick (which speeds you up for a few seconds). The drill: stay on your ring and copy every move (crouch, jump, turn around, a step), and jump on every beat when the rope comes out. The parade: cheer the column as it passes (/cheer, /salute, chant in chat, jump) and keep your enthusiasm bar up. Skipping it costs standing; doing it well earns some, and breakfast if your standing is Trusted or better."  (text, line 87)
- "A full stomach (hunger 85+): 15% more XP from jobs and shifts, and you heal slowly."  (text, line 88)
- "Combine-only areas (the nexus, offices, armory, prison) are off limits. Doors by the cells are locked."  (text, line 89)
- "Raids: Civil Protection units sweep a housing block and trace any contraband (guns, TVs, radios...) to whoever owned it."  (text, line 90)
- "Being wanted means every Civil Protection unit nearby comes for you. Get caught and you're arrested."  (text, line 91)
- "Kill Civil Protection units and it escalates: armed units, then Overwatch squads. Lie low to cool it off."  (text, line 92)
- "One accidental kill is answered lightly; a second soon after gets the full response. Resistance members lose a rank for every civilian they kill."  (text, line 93)
- "To give yourself up, walk up to a Civil Protection unit and press E. It goes easier on you."  (text, line 94)
- "Anticitizen? Do community service from your board (F3), or serve your time."  (text, line 95)
- "Getting by"  (text, line 97)
- "Take a Union job on your board (F3) and work shifts for credits and Civil Standing."  (text, line 98)
- "Standing decides what the Commissary will sell you. Crimes lower it."  (text, line 99)
- "Rebel territory has a black market (C > Getting by > Black market). Radios: C > Talk > On my radio."  (text, line 100)
- "Search the dead with E. Dead Civil Protection units carry ammunition, and sometimes a keycard."  (text, line 101)
- "Haul a body: look at it, F1 > Haul the body; Morticians just press E. Let go by the incinerator and in it goes; attendants are paid for each."  (text, line 102)
- "Press E on a citizen to talk: hear what's going on, share food, pick their pocket (Guile), or inform on them. They remember how you treat them."  (text, line 103)
- "The Resistance (Member and up) can ask a sympathizer to keep watch: they warn Freq 7 when Civil Protection units come."  (text, line 104)
- "The city keeps to the clock: work in the morning, ration lines at midday, quiet evenings, and thin streets at night (only the night shift works)."  (text, line 105)
- "Trains come into the station now and then: new arrivals with suitcases, and anyone leaving the city boards before it pulls out."  (text, line 106)
- "Arrested by a Civil Protection unit, you're tied and walked to the cells by two of them. On the way anyone can get you out: put the leading unit down, then {gm_showhelp} > Work at the ties."  (text, line 107)
- "Rations come out of the city's stores (under the clock). Kitchen and factory work fills them; when they run low, so do the rations, and people grow restless."  (text, line 108)
- "Transformers power their district: its lights (the map's switchable ones too), screens and TVs, dispensers, vending machines, the commissary and Combine door locks. Sabotage one (multitool) and the district goes dark and its Combine doors open, until maintenance fixes it. Prison doors stay locked."  (text, line 109)
- "Half the grid down at once and the whole city goes dark, the map's own lighting included: switch on your flashlight (F)."  (text, line 110)
- "Checkpoints: a glowing Combine power bank runs the turrets and forcefields cabled to it. A powered turret can be knocked over. Turrets shoot the infected, the wanted and known rebels. Kill the bank's power (a multitool, or the grid) and they all die; next to the infestation, that's a containment breach."  (text, line 111)
- "The infestation: ground stained yellow and scorched, a thick yellow haze and a geiger counter. The deeper you go, the faster it clicks."  (text, line 112)
- "Union work behind Combine doors? Actions menu > Getting by > Ask for a Civil Protection escort, while you're on a job. With your escort close, E opens Combine doors for you. Let someone slip in behind you and the Civil Protection unit goes after them; twice and nobody escorts you for a while. When the job's done, they walk you out to the release point."  (text, line 113)
- "Combine forcefields: Civil Protection units walk through; a keycard swipe (E) opens one for a moment; a multitool shorts it out."  (text, line 114)
- "Letters: read a note in your pockets and Send as a letter, at the post office. A courier takes it to their block. Civil Protection units can read the mail while it waits there."  (text, line 115)
- "The city's own people work their Union jobs too: fixing lights and loudspeakers, scrubbing graffiti, hauling the dead, carrying crates and mail. Look at someone to see what they're doing. Broken things wait a while for a player first."  (text, line 116)
- "Down and bleeding? A Union medic may come running, if you're not wanted and it isn't a firefight."  (text, line 117)
- "The war for the city"  (text, line 119)
- "Rebel territory and the infestation spread if nobody fights them (across a floor, or down the stairs to the next), and shrink when they're fought."  (text, line 120)
- "Your screen tells you when you cross into either. C > The city > Who holds the city (or F4) shows who holds how much."  (text, line 121)
- "Unrest (the Resistance strong): more inspections and raids, ration cuts. Full compliance: the rebels go quiet."  (text, line 122)
- "Civil Protection units: F1, 1 (Call for backup) brings the nearest units running; 2 (Send my 10-20) marks where you are for other units."  (text, line 123)
- "Resistance: the quartermaster in rebel territory sells gear. Members and up can press E on fighters to bring them along."  (text, line 124)
- "Fighters with you stay with you before anything else. They hold their fire until you open up or the Combine do, then shoot as they go."  (text, line 125)
- "The rebels are guerrillas: they let a Civil Protection unit get close before they shout, and out in the city they keep out of sight. Units who see an armed rebel in the street open fire."  (text, line 126)
- "At home the rebels keep busy: patrols, the lab bench, crates, the garden, the fire, sleep. Now and then one or two slip out to scavenge and bring it home."  (text, line 127)
- "Every rebel base needs a lab: its scientist makes guns, ammunition, armour, jammers, bypass charges, smoke bombs and Freq 7 radios, for the Resistance only. Bring the materials and it's free, or pay him (60% of the dealer's price). F1 > Resistance > Find the lab marks it."  (text, line 128)
- "Everyone else buys guns, ammunition and jammers at the black market. A Civil Protection unit who finds the scientist shuts the lab for ten minutes."  (text, line 129)
- "Citizens hear things. Press E on them now and then."  (text, line 130)
- "Money for the Resistance: write down what you see near a checkpoint or a unit (F1 > Resistance, with paper) and sell the notes to the quartermaster; skim good parts off the factory line (R while holding one); or have the lab make forged ration cards (but too many turning up brings a sweep on the camp)."  (text, line 131)
- "Rebel zones that touch are one camp: one quartermaster, one supply crate. He buys food back for 2 credits at most (it's free from his crate)."  (text, line 132)
- "A role (Hacker, Father Grigori...) sits on top of your rank: you're still a Fighter, earning toward Lieutenant, carrying the role's kit. Join the faction again in F4 to give it up."  (text, line 133)
- "Getting by, and making things"  (text, line 135)
- "Near Resistance activity when the PA says ration units are deducted? Your next ration is withheld; the dispenser tells you why."  (text, line 136)
- "Press E on bins, dumpsters and fridges to go through them: scrap, rags, chemicals, tins, seeds, sometimes gun parts."  (text, line 137)
- "Fishing line (Commissary): stand in the canal or look at it, Fish from F2 (or C > Getting by), and keep still. Cook the catch."  (text, line 138)
- "Rebel territory has pots (plant seeds, harvest vegetables) and a supply crate the Resistance eat from. C > Resistance > Donate food adds to it."  (text, line 139)
- "F2 > Make: bandages and lockpicks, by hand, anywhere. Everything else is the Resistance lab's work, or the black market's."  (text, line 140)
- "Hold a crowbar, look right at a piece of junk (a wrecked car, a radiator, pipes, a crate) and press E to pry out scrap, rags and chemicals. It's loud: the nearest Civil Protection unit comes to look."  (text, line 141)
- "A crowbar is a weapon: a Civil Protection unit who sees one in your hand makes you wanted. Keep it holstered on the street."  (text, line 142)
- "Rebels guard their territory: break their crates and they warn you twice, shove you, then turn on you. Leave their supplies alone."  (text, line 143)
- "Shoot one of the city's scanners down and it comes apart as scrap. A scanner with a glowing red eye is being flown by a person: it leaves nothing."  (text, line 144)
- "Supply drops: a Combine convoy unloads a crate on the street. A soldier guards it (he warns you off twice), and two metrocops carry boxes off down the street and back: sneak in between them. E on the crate takes a load (gun parts, ammo, medicine), quietly, if no unit sees you at it."  (text, line 145)
- "Your vest (VEST): only charge cells (the lab makes them; dead units and downed scanners drop them), batteries and chargers, and a freed vortigaunt you ask (E) charge it. Sleeping doesn't."  (text, line 146)
- "The lab's scientist can give you a new face (300 credits): nobody's looking for it, wanted and BOLOs gone, and your old standing doesn't follow it."  (text, line 147)
- "Wanted, and out of every unit's sight for half a minute? They've lost you: only a unit who actually sees you comes for you."  (text, line 148)
- "A radio jammer (the lab, or the black market) blinds Civil Protection unit radios, request devices and scanner reports nearby for four minutes. Units smash them with E."  (text, line 149)
- "Citizens' Assignments include Union work orders (streetlights, rubble, pipes) that pay in scrap, rags and chemicals."  (text, line 150)
- "Union reclamation points take scrap, cans and bottles for credits and a little Civil Standing."  (text, line 151)
- "Homemade guns and ammo sell at the black market, and for more at the quartermaster. Getting them there is the risky part."  (text, line 152)
- "F2 > Give hands something to whoever you're looking at. A lockpick lets a prisoner work their cell lock."  (text, line 153)
- "In a cell with a Combine console? Press E on it to fly a city scanner; your body stays put. Flashing a Civil Protection unit adds a minute to your sentence. Photographing rebels, free vortigaunts, the wanted or zombies from about ten feet earns Civil Standing (never time off), and lights them up for every unit. A scanner can't see into or through smoke."  (text, line 154)
- "Spray cans put the lambda on walls. Civil Protection units and loyal citizens scrub tags off with E."  (text, line 155)
- "Civil Protection units: smoke, flashbangs and gas come with rank. The Grenades weapon throws them; R switches type."  (text, line 156)
- "Resistance: you come back in plain clothes. C > Resistance > Gear up puts your own gear on; Change into plain clothes takes it off again."  (text, line 159)
- "In plain clothes nobody looks twice, until a Civil Protection unit sees a gun in your hand."  (text, line 160)
- "Clothes come off the dead (citizens' clothes, CP uniforms, Resistance gear) and turn up in bins. Wear them from F2."  (text, line 161)
- "A CP uniform fools Civil Protection units on the street, for a while. Resistance gear fools the fighters, and makes units shoot."  (text, line 162)
- "Never change in front of a Civil Protection unit."  (text, line 163)
- "Carrying and keeping things"  (text, line 165)
- "Your pockets are limited by weight and size. A satchel lets you carry more."  (text, line 166)
- "Looking at a bin, F2 lets you hide things in it. Anyone can find them."  (text, line 167)
- "Lockers (E): put something in and it's yours. A storage crate from the Commissary is set down from F2."  (text, line 168)
- "Civil Protection units can open any locker or crate, and take what's illegal."  (text, line 169)
- "Homes, trade and writing"  (text, line 171)
- "Apartments: look at a door and it says who holds it, or that it is for rent. With your hands out, right click a free one to rent it (yes or no), and right click your own to lock or unlock it. Or C > This door, and C > Home for keys, locking and giving it up."  (text, line 172)
- "With a CWU business license you can set down a market stall and sell from it. Customers press E on it."  (text, line 173)
- "Paper: Write from F2. Leave a note, put a poster up on a wall, or keep it. E on one reads it."  (text, line 174)
- "C > The city > The city's laws. The Administrator speaks to everyone from C > The city > Broadcast."  (text, line 175)
- "Characters and acts"  (text, line 177)
- "C > Me > My characters: your people in the city. Switch between them, or start someone new."  (text, line 178)
- "C > Me > Pose: sit, kneel, lie, lean, cower, four standing poses; move (or Stand up) to get up."  (text, line 179)
- "C > Me > Gesture: wave, salute, bow, nod, shake, point, beckon, halt, cheer, laugh. C > Me > Put my hands up."  (text, line 180)
- "Vortigaunts, time and weather"  (text, line 182)
- "Shackled vortigaunts work the Union's shifts; the collar holds their vortessence in."  (text, line 183)
- "The Resistance (Member and up) can cut one free (look at it, C): ten seconds, unseen. Free, it strikes (left click) and charges vests (right click), and is hunted."  (text, line 184)
- "Armour is the charge in a powered vest: Civil Protection units have one in the uniform, rebel ranks come with one, anyone else needs one from the lab. Vortigaunts charge it."  (text, line 185)
- "Father Grigori keeps to rebel territory when no player is him: E on him for a blessing, a sermon, or a word."  (text, line 186)
- "A day lasts an hour. Nights are dark, and curfews likelier. C > The city tells the time and the weather."  (text, line 187)
- "Rain fills an empty bottle or can if you stand out in it. lc_music 0 turns the city's music off."  (text, line 188)
- "Need staff? Type @ and your message."  (text, line 189)
- "Directives and jobs"  (text, line 191)
- "F3 is your board. Events bring their own directives: they go up two minutes before, and come down when it's over."  (text, line 192)
- "Only rations and curfew are announced ahead. Sweeps, raids and supply convoys come without warning, and a lockdown only follows violence."  (text, line 193)
- "Several people can take the same job: up to 8 for an event, 6 for containment or retaking ground, 4 for a chase."  (text, line 194)
- "When the infestation spreads or the Resistance take ground, a directive to deal with it goes up straight away."  (text, line 195)
- "Civil Protection"  (text, line 197)
- "Civil Protection units: F1 is your quick menu: backup, 10-20, BOLO, the mask's voice lines and records on 1 to 5; search, ties and escorts for whoever you're looking at on 6 to 8."  (text, line 198)
- "Units: C > Unit tools has everything a unit can do, each with what it does. Records terminal: violations, notes, loyalty points, BOLOs, requests."  (text, line 199)
- "Civil Protection units don't make things: the Civil Protection Commissary issues grenades, ammunition, armour, bandages and your ration (E on it, every two minutes). F2 marks the nearest on your screen."  (text, line 200)
- "Civil Protection units: actions menu > Civil Protection > Deploy a turret here, near a checkpoint's power bank or forcefield (two each; E packs one up). Officers put up power banks."  (text, line 201)
- "Union workers can ask for an escort. Actions menu > Civil Protection > Escort requests to take one (or look at a worker > Escort them). Keep them close, open the doors they need, walk them out to the release point when they're done."  (text, line 202)
- "F1 > Voice lines for the mask's most used lines (or say the words); all of them are in Unit tools > Voice lines."  (text, line 203)
- "C opens the full menu (so does 9 on the quick menu): everything you can do right now, for who you are and what you're looking at, with this guide at the top. No chat commands to remember (they still work)."  (text, line 204)
- "A special role (Hacker, Father Grigori...) comes back with you when you rejoin, if there's still a place in it."  (text, line 205)
- "The multitool (the Resistance's two Hackers carry one; the black market sells them, contraband): point it at a locked Combine door (hack it), a city screen (hijack it), a data terminal (steal its data), a vending machine or ration dispenser (free water or rations) or a shackled vortigaunt, and left click."  (text, line 206)
- "The Director of Propaganda's microphone: left click to go on air over every loudspeaker and screen (a minute, once every fifteen). A scanner comes down and films whoever holds it, live on every screen; its eye blinks red while it records. With no player in the job, the Administrator addresses the city herself now and then; kill her on air and her microphone is yours. Shoot it down to kill the picture. Take the microphone off them (hands up or tied, actions menu) and it's a pirate broadcast."  (text, line 207)
- "Shot or worn out, streetlights go dark and loudspeakers go quiet: nobody near a broken one hears the PA. Maintenance and radio repair crews fix them."  (text, line 208)
- "One terminal is half a chip (a fragment): hack a second, different terminal and the two make a whole data chip. The master terminal is the motherlode: one download, a master data core."  (text, line 209)
- "A data chip: sell it to the dealer, take it to the lab and have the scientist Decode it (top of his list: every Civil Protection unit marked for five minutes), or Use it at a terminal to wipe your record."  (text, line 210)
- "Dead soldiers drop their guns, with about half a clip in them. The rest of their ammunition is on the body: search it."  (text, line 211)
- "Shooting a scanner is damaging city property; killing one is destroying it. Neither is assaulting anyone."  (text, line 212)
- "Ambush the landing: be at the landing zone before the dropship comes in, and hit the soldiers it sets down."  (text, line 213)
- "Someone you're escorting runs when you run, and when there's shooting. Climb a ladder and they follow you up it."  (text, line 214)
- "Resistance: a small orange lambda over a citizen's head means they're secretly one of ours. Members and up can ask them to keep watch (E, then the talk window)."  (text, line 215)
- "Break your people out of the cells, ambush Overwatch landings, free a vortigaunt: see Operations (F3)."  (text, line 216)
- "Citizens: look at someone, F1 > Inform on them. Civil Protection pays if it's true. If the Resistance see you do it, you're a traitor."  (text, line 217)
- "Trusted citizens: actions menu > Getting by > Become a Union foreman; then the actions menu on a citizen > Give them a work order. You take a cut."  (text, line 218)
- "The worst anticitizens get worse than time: interrogation (the interrogator offers 50 social credits if you talk), broken feet (no running), or being made a stalker."  (text, line 219)
- "A stalker works below, in the Combine areas: The Stalker's Lot on your board (F3). Units leave it alone, its papers are stamped STALKER, and it can scream but not speak. There is no way out of being a stalker but death. At the end of it is a Combine ball energizer you built yourself, and stepping into it is a way out: that person is gone for good."  (text, line 220)
- "Civil Protection is one career: Record Keeper, Metrocop, Division Leader, then the Overwatch ranks (Prison Guard, Soldier, Elite), which need the transhuman conditioning: the Overwatch Candidate story offers it to Division Leaders."  (text, line 221)
- "Not sure what you could be doing? F1 > What now? > Ways to get by: everything open to you, and what the rest need."  (text, line 222)
- "Civil Protection units kick: G (or F1 > Kick). Doors swing open, locked ones give on the second kick, people get knocked back. A Combine Soldier kicks a hinged door off its hinges; an Elite sends it flying, and whoever it hits is knocked out. Maintenance Technicians rehang fallen doors: E to lift, carry it to the frame, E again."  (text, line 223)
- "Scanner Operator (Civil Protection, F4): fly a scanner from a Combine console or the Nexus (F1 > Unit tools). Reports earn XP; a rebel you photograph becomes a BOLO."  (text, line 224)
- "Released from prison, you get your fists back but not your guns or radio. Civil Protection units get their issue back."  (text, line 225)
- "Rebel ground has no mercy: REBEL TERRITORY AHEAD warns you a step before it. Inside, they shoot Civil Protection units."  (text, line 226)
- "Supply drop on? Guard the crate: if anything's left when the convoy moves on, every Civil Protection unit nearby is paid."  (text, line 227)
- "RADIO JAMMED on your HUD: a jammer is close. Follow the beeping and press E on it."  (text, line 228)
- "Civil Protection units: look at someone, F1 > Zip-tie them. Anyone with zip ties: C > their name > Zip-tie their hands. Hands up, down, stopped, or from behind. Drag walks them along; the baton arrests them."  (text, line 229)
- "Sociostability (green, yellow, red) is at the top of the screen. Officers set it in C > Unit tools. Red is a judgment waiver: metrocops have their pistols out."  (text, line 230)
- "Set off an alarm (a data chip, an escape) and a squad of two metrocops and a soldier comes through the door a few seconds later."  (text, line 231)
- "The nexus and every Combine-only zone are garrisoned: mostly Overwatch soldiers, a metrocop or two."  (text, line 232)
- "Citizens: C > Getting by > Request Civil Protection (with a request device) calls a Civil Protection unit. C > Me > Put my hands up when a unit tells you to."  (text, line 233)
- "Tied up? C > Me > Work at the ties, when nobody's looking. Anyone can cut you free."  (text, line 234)
- "The first time you run into something, a card on the right says what it is and what you can do. Each one shows once."  (text, line 237)
- "C > Tips I've seen has every tip you've had, to read again. C > Settings turns them off or on, or starts them over."  (text, line 238)
- "Talking, and knowing people"  (text, line 240)
- "Chat is spoken out loud: only people nearby hear it. C > Talk yells further (/y) or whispers to whoever is right next to you (/w)."  (text, line 241)
- "C > Talk: describe what you do (/me lights a cigarette), the scene (/it), or roll 1-100 for everyone near (/roll)."  (text, line 242)
- "C > Talk > Out of character: for the whole server (//, with a cooldown) or nearby only (/looc)."  (text, line 243)
- "Voice works the same way: people hear you if they're close enough."  (text, line 244)
- "Strangers don't know your name. They see your description: C > Me > Change how strangers see me ("tall, with a scar over one eye")."  (text, line 245)
- "Look at someone, F1 > Tell them my name. F1 > Tell everyone nearby my name."  (text, line 246)
- "Civil Protection units are known by their designation while the mask is on."  (text, line 247)
- "Going down"  (text, line 249)
- "A killing blow puts you on the ground, bleeding, instead of killing you outright. You can still whisper."  (text, line 250)
- "Someone can press E on you to get you back up: a few seconds bare-handed, quicker and better with a bandage."  (text, line 251)
- "A Civil Protection unit pressing E on a wanted person cuffs them where they lie."  (text, line 252)
- "Shoot someone who's down and that's the end. Looking at them, F1 > Drag them along; again lets go."  (text, line 253)
- "C > Me > Give up lets go if nobody's coming. Explosions and the like kill outright."  (text, line 254)

*When:* The guide: the full menu's first item (C, cl_livingcity_actions.lua), !help, or the console command lc_help. A list of topics on the left, the topic on the right, and a search box that looks through all of it.

- "C > Help > Build mode (or !build) toggles build mode: spawn menu, context menu, physgun, toolgun (Living City Editor) and noclip."  (text, line 262)
- "Civil Intake: place "Fixture: Civil Intake (registration)", "Fixture: Housing Allocation" and "Point: arrival". lc_intake, lc_intake_secs (8), lc_intake_grace (10 minutes), lc_papers_fee (10), lc_card_fee (15); lc_register <name>, lc_unregister <name> (back through all of it, room included). No desk on the map: people are registered and housed as they arrive."  (text, line 263)
- "Civil Protection Commissary (editor fixture): Civil Protection units are issued grenades, ammunition, armour, bandages and a ration there. lc_cpsupply_cooldown (120), lc_cpsupply_ration (600). None placed: the Union Commissary terminal issues them instead."  (text, line 264)
- "Resistance lab (editor fixture, the old workbench): a lab bench and a scientist who makes the Resistance's guns. Put one in every rebel base. lc_lab_price (0.6 of the dealer's), lc_lab_shutdown (600 seconds after a Civil Protection unit finds it)."  (text, line 265)
- "How it feels (editor panel, How it feels): lc_fov (75, the widest anyone sees; 0 leaves it to each player), lc_eye_height (61; GMod's is 64), lc_view_bob (lc_view_bob_amount, 100%, for how strong), lc_quiet_hud, lc_respawn_secs (12, the death card), lc_word_gets_around."  (text, line 266)
- "C > Help > Admin testing tools (or the button on F4, or !admintools): give yourself XP, a rank, credits and standing, switch faction, start over."  (text, line 268)
- "Switching faction from F4 changes your uniform and kit where you stand: no trip back to a spawn point."  (text, line 269)
- "Chat: !givexp, !setrank, !givecredits, !givestanding <n> [name]; !resetxp, !resetcredits [name]; !resetme."  (text, line 270)
- "C > Help > Staff panel (or !staff): logs, tickets, warnings, character bans. !warn <name> <reason>, !charban <name> <reason>."  (text, line 271)
- "Black out the whole city for an event: !admintools > The city, or lc_blackout on\|off\|auto."  (text, line 273)
- "Checkpoints in the editor: Combine power bank, Combine turret, Combine barricades. Put one at the edge of the infestation and it stops spreading there, until the power goes."  (text, line 274)
- "Cell doors not locking? Tag them with the editor: Door: prison or cell. They stay locked in a blackout, and shut themselves if anything but a Civil Protection unit opens them."  (text, line 275)
- "Door: always open keeps a door open for good: locked open, and opened again if anything shuts it."  (text, line 276)
- "Your own announcements: drop .wav files straight into the server's garrysmod/sound/livingcity/overwatch/ or .../administrator/, named for the trigger (curfew1.wav, ambient2.wav); the Administrator's tone is in the name too (curfew_firm1.wav, curfew_stern1.wav, curfew_furious1.wav; no tone word is warm). Each folder's README lists the triggers. lc_announce_clips lists what it found (and any file the game can't play: an MP3 renamed .wav is silent, so keep .mp3 as .mp3; a .wav must be 16-bit 44100 Hz), lc_announce_say <voice> <trigger> [tone] tests one. Every player's own computer plays them, so they reach players through FastDL (press FastDL sync after adding one, then change the map); lc_sound_check tests a player's own."  (text, line 277)
- "Secret endings (keep them secret): the G-Man stops time and everyone votes, 1 to let the city end, 2 to skip (no votes: it ends). Nobody really dies; the map reloads after. Songs go straight in the server's garrysmod/sound/livingcity/endings/ folder, named for the ending: harpies.mp3, bus.mp3, plane.mp3, standup.mp3, water.mp3, bloom.mp3, marrow.mp3, base.mp3, hard.mp3, shalom.mp3, fire.mp3. Father Grigori eating a master data core (Eat it in his pockets, or /eatchip) starts the flood (started by an admin, the city's own Father Grigori takes the stage; lc_ending_flood_crowd is how many others are up there with him). lc_endings, lc_ending <id> [now], lc_ending_cancel, lc_ending_reset_cooldown. The Endings menu (C > Help > Endings menu, superadmins, or lc_endings_menu): tune any ending live while it plays, its dances bone by bone (the bone lit up on the dancers) and all its settings, and copy what you changed. The Harpies (mingebags): lc_ending_minge_swell is the second the song swells, lc_ending_minge_end when it is all over, lc_ending_minge_max how many, lc_ending_minge_crowd how many of the city's people stand in the ring, lc_ending_minge_chatter 0 silences the Combine's radio chatter. Bloom (the dance): lc_ending_bloom_speedup, _ramp, _peak, _bpm; lc_bloom_preview and lc_bloom_pose tune the dance. Marrow (the skeletons): lc_ending_marrow_sections lines it up with the song (seconds:dance\|rave\|attack\|outro\|end). The Bus: lc_ending_bus_sections (seconds:fly\|drive\|fast\|end), lc_ending_bus_bpm. Base: lc_ending_base_sections, lc_ending_base_lines (the subtitles). Hard (party hard): lc_ending_hard_sections, lc_ending_hard_moment_beats (how often another of the Combine goes for it), lc_ending_hard_moment_max (how many at once). Plane (numa numa): lc_ending_plane_sections, lc_ending_plane_captions. Standup (the rope): lc_ending_standup_sections, lc_ending_standup_drain. The Flood: lc_ending_flood_attack_from (when the ichthyosaurs start biting), lc_ending_flood_boats (rowboats), each player's lc_headbang_angle (Father Grigori's nod). The Plane: lc_ending_plane_model_yaw (if it flies sideways). Marrow: lc_ending_marrow_crowd. Any ending: lc_ending_bodies (bodies left lying), lc_ending_edict_limit (spawns stop near the server's entity limit). Bloom: each player's lc_bloom_palm (-90 if the palms face back). Shalom (the hora): lc_ending_shalom_sections, lc_ending_shalom_candles (when each of the hanukkiah's candles is lit), lc_ending_shalom_lift_beats (how often someone goes up on a chair), lc_ending_shalom_sayings (more sayings over heads, separated by \|); each player's lc_shalom_pose tunes the dance's arms and lc_shalom_kippah where the kippah sits. Fire (behinds on fire, then flying on them): lc_ending_fire_sections (seconds:ignite\|hop\|fly\|launch\|end), lc_ending_fire_hop (how high the hops), lc_ending_fire_fly_speed, lc_ending_fire_crowd; the flying pose is tuned in the Endings menu (Pelvis tips the whole body)."  (text, line 278)
- "Freq 7 (the pirate broadcast): voice lines and songs take turns, warnings cut in; the Combine jam it every lc_freq7_hold minutes on green (faster on yellow and red, never in a blackout). Recordings: the sound addon's radio/ folder. lc_freq7_status says where it is."  (text, line 279)
- "Morning exercise: place a jogging route (stops in order, the first is the start), an exercise yard (stand where the rows will be, aim at the leader's spot) and a parade route (stops in order) with the editor. Every lc_exercise_every dawns (2) one runs, taking turns (lc_exercise_kinds). lc_exercise <jog\|drill\|parade> starts one now, lc_exercise next says what's next, lc_exercise stop ends it."  (text, line 280)
- "NPCs losing you in pursuit? Path mapping (editor panel, Paths and doors, or !pathmap) lays path nodes as you walk the streets, stairs and alleys, links them and saves them with the map. Noclip pauses it; lc_pathmap_undo removes this session's nodes."  (text, line 281)
- "Every setting in the editor panel saves with the map as you change it, so a restart keeps your numbers."  (text, line 282)
- "Persistent props: spawn a prop, place it, and zap it with the editor's Prop: make persistent. It's saved with the layout, frozen, and back every time the map loads."  (text, line 283)
- "Rebel lookout post (editor point): an armed fighter guards that spot. Place it from where the Combine would come, so he faces that way."  (text, line 284)
- "Bunk (editor point): a bed rebels sleep on. Mattresses, beds, couches, chairs, workbenches and crates inside rebel territory are found by themselves."  (text, line 285)
- "Tag the Combine's doors Door: Civil Protection only and Civil Protection units are routed through them, even ones the map's navigation was cut off by."  (text, line 287)
- "The Living City Editor places everything: street furniture (bins, streetlights, loudspeakers, big screens, TVs), an incinerator for the dead, and a workplace for each Union job, plus loading docks, graffiti walls, rubble piles and leaky pipes for the shifts that use them."  (text, line 288)

*When:* part of: paint

- "C > Guide opens this. Tips also pop up the first time something happens (C > Tips I've seen has them all)."  (drawn on screen, line 310)

*When:* part of: open guide

- "Search the guide"  (text, line 315)

*When:* part of: show search

- "Nothing about "{q}". Try one word: tie, rent, curfew, fish..."  (text, line 357)

## init.lua (init.lua)

`gamemodes/livingcity/gamemode/init.lua`


*When:* Build mode

- "[Living City] Build mode ON: spawn menu (Q), context menu (C), physgun, toolgun and noclip. The Living City Editor is under Q > Tools > Living City. Type !build again to go back to playing."  (chat message, line 122)

*When:* part of: lcset build

- "[Living City] Build mode OFF. You're just a person in the city now."  (chat message, line 127)

*When:* typing in chat

- "[Living City] Build mode is for admins."  (chat message, line 149)

*When:* Arriving

- "[Living City] Welcome to the city. F1: what you can do (and the guide). F2 pockets, F3 your board, F4 factions."  (chat message, line 166)
- "[Living City] You're an admin: !build switches to build mode for the editor, physgun and noclip."  (chat message, line 168)

## cl_livingcity.lua (cl_livingcity.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity.lua`


*When:* part of: block name

- "Habitation Block %02d"  (text, line 148)

*When:* part of: draw aim info

- "%s   \|   radius %d Civil Protection units (about %.1f m across)   \|   right click removes"  (message, line 598)
- "\|   right click removes"  (text, line 604)
- "PATH NODE %d   \|   %d links   \|   right click removes"  (message, line 607)

*When:* persistent props (sv_livingcity_props.lua)

- ": {GetNW2String}"  (text, line 657)

*When:* part of: play next voice

- "(the loudspeaker here is broken)"  (text, line 717)

*When:* on screen

- "Cuffed and kneeling. Wait it out."  (drawn on screen, line 825)
- "ESCORT CALLED AWAY: stay put, another Civil Protection unit is coming (%ds)"  (message, line 861)
- "Spawn protection %ds"  (message, line 870)
- "Ration distribution"  (text, line 878)
- "Civil status inspections"  (text, line 878)
- "Housing block inspection"  (text, line 878)
- "Supply convoy unloading"  (text, line 878)

*When:* units and Overwatch don't go home for curfew: they enforce it

- "Grace period: %ds to get home."  (message, line 888)

*When:* on screen

- "You are home. Stay inside."  (text, line 891)
- "Report to {block}."  (text, line 891)

*When:* Debug report viewer

- "[Living City]"  (chat message, line 913)
- "Debug report copied to your clipboard. Paste it to Claude. Also saved to {file}"  (chat message, line 913)
- "Living City debug report"  (window title, line 916)

*When:* the game answering something done in a window (lc_report)

- "Copy to clipboard again"  (label or button, line 929)

*When:* Path mapping (sv_livingcity_pathmap.lua): say so on screen while it's on

- "PATH MAPPING: walk to lay nodes"  (text, line 961)

## cl_livingcity_actions.lua (cl_livingcity_actions.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_actions.lua`


*When:* part of: open actions

- "Places in the city (show me the way)"  (text, line 98)

*When:* someone who's down (sv_livingcity_rp.lua)

- "Someone who's down"  (text, line 136)

*When:* a body

- "This body"  (text, line 144)

*When:* the thing in front of you

- "This door"  (text, line 152)

*When:* the power grid and forcefields (sv_livingcity_power.lua)

- "This transformer"  (text, line 160)

*When:* checkpoints (sv_livingcity_checkpoints.lua)

- "This power bank"  (text, line 172)

*When:* part of: open actions

- "This forcefield"  (text, line 187)

*When:* add

- "How strangers see you"  (text, line 227)
- "Describe yourself (8 to 120 characters), e.g. tall, grey coat, a scar over one eye"  (text, line 227)

*When:* talking (the same as the chat prefixes)

- "What do you yell?"  (chat message, line 235)
- "What do you whisper?"  (chat message, line 236)
- "An action"  (chat message, line 237)
- "What do you do? (e.g. leans against the wall)"  (chat message, line 237)
- "The scene"  (chat message, line 238)
- "What happens? (e.g. A siren starts up somewhere.)"  (chat message, line 238)

*When:* add

- "Out of character"  (chat message, line 240)
- "Said out of character, to people nearby"  (chat message, line 240)
- "Out of character"  (chat message, line 241)
- "Said out of character, to the whole server"  (chat message, line 241)
- "What do you say on the radio?"  (text, line 242)
- "Union band"  (text, line 243)
- "What do you say on the Union band?"  (text, line 243)

*When:* getting by

- "Getting by"  (text, line 246)

*When:* add

- "What's wrong?"  (text, line 254)
- "Take a key back"  (text, line 277)
- "Whose key? (their name)"  (text, line 277)
- "Give up your apartment? Your rent isn't refunded."  (text, line 279)
- "Give up the apartment"  (text, line 279)
- "Give it up"  (text, line 279)
- "Keep it"  (text, line 279)

*When:* the city

- "The city"  (text, line 283)
- "What does the city hear?"  (text, line 289)

*When:* Civil Protection

- "Civil Protection"  (text, line 294)

*When:* add

- "What should Civil Protection units look out for?"  (text, line 302)

*When:* workers waiting for an escort, or left without one, or with an NPC unit a player can take over from

- "Escort requests ({reqs})"  (text, line 313)

*When:* part of: open actions

- "Set sociostability (officers)"  (text, line 319)

*When:* settings, just for you

- "Camera sway: on (turn off)"  (text, line 346)
- "Next step on screen: new life and urgent (change)"  (text, line 349)
- "Next step on screen: never (change)"  (text, line 349)

*When:* part of: open actions

- "Third person while posing: on (turn off)"  (text, line 352)
- "Warnings and notices on screen: on (turn off)"  (text, line 355)

*When:* help, and staff

- "Ask staff"  (text, line 364)
- "What's wrong? Staff see this as a ticket."  (text, line 364)

*When:* Workers who want a unit with them: waiting, left alone, or with an NPC unit a player can take over from.

- "with an NPC Civil Protection unit"  (text, line 394)

*When:* the game answering something done in a window (lc_interrogate)

- "A Civil Protection unit stands over you with a stun baton. "You will answer my questions." /  / Talk, and the beating stops: you give up a Resistance hideout. Say nothing, and take it."  (label or button, line 447)
- "Talk (give them a hideout)"  (label or button, line 452)
- "Say nothing"  (label or button, line 461)

## cl_livingcity_admintools.lua (cl_livingcity_admintools.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_admintools.lua`


*When:* part of: build

- "Admin: testing tools"  (window title, line 79)

*When:* who it's for

- "Acting on:"  (text, line 87)

*When:* faction

- "Faction  (switches straight away, no requirements)"  (text, line 100)

*When:* XP and rank

- "XP and rank  (%s: %d XP)"  (message, line 108)
- "XP and rank"  (text, line 108)
- "Set rank:"  (text, line 114)

*When:* part of: build

- "This faction has no ranks to climb."  (text, line 122)
- "Reset all XP to 0"  (text, line 125)

*When:* credits and standing

- "economy off"  (message, line 128)
- "Reset to 0"  (text, line 131)
- "Civil Standing  (%s)"  (message, line 132)
- "economy off"  (message, line 132)

*When:* odds and ends

- "Clear wanted"  (text, line 143)
- "Feed and heal"  (text, line 144)
- "Clear conduct strikes"  (text, line 145)
- "Give item:"  (text, line 147)

*When:* the whole city (sv_livingcity_power.lua)

- "The city"  (text, line 157)
- "Black out the city"  (text, line 160)
- "Lights on"  (text, line 161)
- "Follow the grid"  (text, line 162)
- "Start over"  (text, line 164)

*When:* part of: build

- "Reset XP, credits and standing to 0"  (text, line 166)

## cl_livingcity_atmos.lua (cl_livingcity_atmos.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_atmos.lua`


*When:* what the city is doing at this hour (sv_livingcity_rhythm.lua)

- "night: the streets are quiet"  (text, line 59)
- "morning: off to work"  (text, line 60)
- "the work day"  (text, line 61)
- "midday: ration lines"  (text, line 62)

*When:* the city's ration stores (sv_livingcity_stockpile.lua)

- "ration stores %d%%%s"  (message, line 84)

## cl_livingcity_character.lua (cl_livingcity_character.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_character.lua`

- "This is the Civil Intake terminal's registration screen. Enter who you are, then submit it; the terminal processes you while you wait beside it."  (text, line 49)

*When:* part of: paint

- "Number to be issued:"  (text, line 80)

*When:* the game answering something done in a window (lcc_open)

- "Your name"  (label or button, line 188)
- "First name and surname"  (text, line 202)

*When:* stuck for a name: an ordinary one, for the face picked

- "Suggest a name"  (label or button, line 207)

*When:* the game answering something done in a window (lcc_open)

- "How a stranger would know you"  (label or button, line 217)
- "tall, grey coat, a scar over one eye"  (text, line 225)
- "Your face (then its look, under the picture)"  (label or button, line 233)
- "Not now"  (button, line 271)
- "Keep what I was given (ignores edits)"  (button, line 277)
- "Submit to the terminal"  (button, line 283)
- "This is me"  (button, line 283)

*When:* The server says yes, or why not.

- "[Living City]"  (chat message, line 308)
- "You are {msg}."  (chat message, line 308)

## cl_livingcity_cp.lua (cl_livingcity_cp.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_cp.lua`


*When:* part of: fill detail

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

*When:* part of: build records

- "Civil Protection: records terminal"  (window title, line 151)
- "Search by name or CID (people not in the city too)"  (text, line 196)

*When:* BOLOs

- "A BOLO on a description, not a record ('male, red jacket, northbound')"  (text, line 227)
- "No BOLOs out."  (text, line 229)

*When:* part of: build records

- "%s%s / %s, %s, %d min left"  (message, line 238)
- "BOLOs ({or})"  (text, line 246)

*When:* requests

- "No requests."  (text, line 251)
- "Requests ({or})"  (text, line 256)

*When:* part of: open voice menu

- "Voice (or type the words, or /vo <word>)"  (window title, line 278)

*When:* part of: draw socio pill

- "SOCIOSTABILITY: {SetFont}"  (text, line 362)

*When:* on screen

- "!struggle to work at the ties when nobody's looking"  (text, line 385)
- "HANDS UP  (!handsup to lower them)"  (text, line 387)

## secret endings, on your screen (sv_livingcity_endings.lua) (cl_livingcity_endings.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_endings.lua`


*When:* (the server's volume for this song, for a quiet recording, times your own)

- "the game can't open it ({err}): is it really the format its name says?"  (text, line 79)

*When:* time stopped: the colour goes

- "$pp_colour_addr"  (text, line 236)
- "$pp_colour_addg"  (text, line 236)
- "$pp_colour_addb"  (text, line 236)
- "$pp_colour_brightness"  (text, line 236)
- "$pp_colour_contrast"  (text, line 237)
- "$pp_colour_colour"  (text, line 237)
- "$pp_colour_mulr"  (text, line 237)
- "$pp_colour_mulg"  (text, line 237)
- "$pp_colour_mulb"  (text, line 237)

*When:* on screen

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

*When:* the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 792)
- "$pp_colour_addg"  (text, line 792)
- "$pp_colour_addb"  (text, line 792)
- "$pp_colour_brightness"  (text, line 793)
- "$pp_colour_contrast"  (text, line 793)
- "$pp_colour_colour"  (text, line 793)
- "$pp_colour_mulr"  (text, line 794)
- "$pp_colour_mulg"  (text, line 794)
- "$pp_colour_mulb"  (text, line 794)

*When:* on screen

- "Under the water: hold Jump to swim up"  (text, line 870)

*When:* the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 878)
- "$pp_colour_addg"  (text, line 878)
- "$pp_colour_addb"  (text, line 878)
- "$pp_colour_brightness"  (text, line 878)
- "$pp_colour_contrast"  (text, line 879)
- "$pp_colour_colour"  (text, line 879)
- "$pp_colour_mulr"  (text, line 879)
- "$pp_colour_mulg"  (text, line 879)
- "$pp_colour_mulb"  (text, line 879)

*When:* The warning, as a flashing ending starts: leave the flashing out, or not

- "Photosensitivity warning"  (window title, line 1305)

*When:* part of: flash warning

- "What's about to happen has flashing lights, strobes and screen flashes. If that could be a problem for you, leave them out: the music, the dancing and everything else stay. (lc_ending_calm in the console changes it any time.)"  (label or button, line 1314)
- "Reduce flashing"  (label or button, line 1319)

*When:* (doing nothing is "I'm fine": it goes by itself after 15 seconds, time enough to read it)

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

*When:* on screen

- "Am Yisrael chai"  (text, line 2063)

*When:* the console command lc_shalom_pose_print

- "chair %s = Angle(%g, %g, %g)"  (message, line 2082)

## the Endings menu (superadmins): tune the secret endings live (cl_livingcity_endingtune.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_endingtune.lua`


*When:* Each ending's moves: { move, what it is }

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

*When:* where each bone sits on the body map (facing you: their right arm on your left)

- "Mid back"  (text, line 69)
- "Lower back"  (text, line 70)
- "R upper arm"  (text, line 71)
- "L upper arm"  (text, line 72)

*When:* what each of a bone's three turns does (as the playtests showed them)

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

*When:* part of: setting row

- "(the same on everyone's screen)"  (text, line 315)
- "Back to the default ({d})"  (button, line 346)

*When:* part of: changes

- "Living City: ending tuning, from the Endings menu"  (text, line 380)
- "Settings changed from their default:"  (text, line 386)
- "Shared settings (the same on everyone's screen):"  (text, line 393)
- "Dance tuning (added to the code's own turn of the bone; pitch yaw roll):"  (text, line 397)
- "Nothing changed yet."  (text, line 402)

*When:* part of: dance tab

- "This ending has no dance to tune. Its settings are on the next tab."  (text, line 411)

*When:* part of: paint

- "Nobody's doing this move in sight."  (drawn on screen, line 437)
- "Play the ending, or tick the stand-in below."  (drawn on screen, line 438)
- "drag to turn round, wheel to zoom"  (drawn on screen, line 449)

*When:* part of: dance tab

- "Watch someone else doing it"  (button, line 455)
- "Yellow: the bone you're turning. Blue edge: a bone that's been tuned. In the world it's lit up on everyone doing the move (red forward, green right, blue up)."  (text, line 500)
- "Left and right mirror each other"  (label or button, line 505)
- "Back to how the code has it: this bone"  (button, line 521)
- "Back to how the code has it: the whole move"  (button, line 527)
- "Stand-in: someone doing the move in front of you (only on your screen)"  (label or button, line 535)
- "The stand-in's beats a minute"  (text, line 538)

*When:* part of: think

- "The song is at %.1f s (%s)"  (message, line 550)
- "The song's time shows here while an ending plays (for lining up its sections: seconds:part,seconds:part,...)."  (label or button, line 550)

*When:* part of: settings tab

- "Copy the song's time"  (button, line 552)
- "No settings of its own."  (text, line 558)
- "Every ending:"  (text, line 560)

*When:* part of: you tab

- "These are your own game's, not the server's."  (text, line 567)
- "How loud the songs are"  (text, line 574)
- "Calm: no strobes or screen flashes"  (label or button, line 577)
- "Base's arcade blocks (1: off)"  (text, line 579)

*When:* part of: changes tab

- "Everything you've changed. Copy it and send it on, and it can be built in as the new normal."  (text, line 586)
- "Copy it all"  (button, line 596)

*When:* part of: fill

- "The dance"  (text, line 608)
- "Just for you"  (text, line 610)

*When:* part of: open

- "Endings: tune them live"  (window title, line 633)
- "Play it now"  (button, line 647)
- "Stop it"  (button, line 648)
- "(playing now)"  (text, line 662)

*When:* part of: endings menu

- "Only a superadmin can tune the endings."  (chat message, line 675)

## morning exercise, on your screen (sv_livingcity_exercise.lua) (cl_livingcity_exercise.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_exercise.lua`

- "the start of the jogging route"  (text, line 21)
- "the exercise yard"  (text, line 21)
- "the parade route"  (text, line 21)

*When:* on screen

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


*When:* admins: the testing tools (XP, ranks, credits, standing)

- "Admin: testing tools (XP, ranks, credits, standing)"  (label or button, line 66)

*When:* the game answering something done in a window (lcf_menu)

- "Your rank: %s   XP %d%s"  (message, line 105)
- "(next: %s at %d)"  (message, line 106)
- "(highest rank)"  (message, line 106)
- "You are here"  (text, line 113)
- "Join {name}"  (text, line 113)
- "Special role: {name}  ({taken}/{or} taken)"  (label or button, line 122)

*When:* how a role sits with your rank: on top of it, not instead of it

- "A role, not a rank: you stay %s and keep earning XP toward the next rank. While you hold it you carry its kit%s instead of your rank's%s. To give it up, press "Join %s" above: you're back to %s with %s kit."  (message, line 140)

*When:* the game answering something done in a window (lcf_menu)

- "and wear its clothes"  (message, line 141)
- "your rank"  (message, line 141)
- "a {myRank}'s"  (message, line 141)
- "You hold this role"  (text, line 145)
- "Take up the role of {name}"  (text, line 145)

*When:* (a special role is held on top of your rank: "Hacker (Fighter)")

- "Habitation Block %02d"  (text, line 183)

*When:* (the Overwatch ranks wait on the conditioning: the Overwatch Candidate story)

- "%s   %d XP (higher needs the Overwatch conditioning)"  (message, line 214)

*When:* part of: xpinfo

- "%s   %d XP (top rank)"  (message, line 221)

*When:* the game's huddraw target id moment

- "Citizen {alias}"  (text, line 363)
- "NOT ON THE ROSTER (search them: baton reload, or !search)"  (text, line 371)

*When:* what units know: a BOLO out on them, hands tied, hands up (sv_livingcity_cp.lua)

- "BOLO: {GetNW2String}"  (text, line 376)
- "Hands tied"  (text, line 377)
- "Hands up"  (text, line 378)

## cl_livingcity_grigori.lua (cl_livingcity_grigori.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_grigori.lua`


*When:* part of: paint

- ""What do you need, child?""  (drawn on screen, line 36)
- ""Go with God. But go.""  (drawn on screen, line 36)

*When:* the game answering something done in a window (lc_grigori)

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


*When:* What each binding is usually on, if the player hasn't bound it.

- "+menu_context"  (text, line 25)
- "Left click"  (text, line 26)
- "Right click"  (text, line 26)
- "Middle click"  (text, line 26)

*When:* on screen

- "+{more} more"  (drawn on screen, line 123)

*When:* gone before you finished reading? it's kept

- "Read it again any time: {HintKeys} > Tips I've seen"  (drawn on screen, line 131)

*When:* part of: paint

- "None yet: they come as you meet things."  (drawn on screen, line 162)
- "so far, this session's first"  (text, line 162)

*When:* the game answering something done in a window (lc_hints_seen)

- "Tips are off: turn them on"  (text, line 194)
- "Tips are on: turn them off"  (text, line 194)
- "Show me them all again, from the start"  (text, line 195)

## cl_livingcity_infest.lua (cl_livingcity_infest.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_infest.lua`


*When:* The air itself: a yellow cast over everything, and motes of it drifting past you.

- "$pp_colour_addr"  (text, line 107)
- "$pp_colour_addg"  (text, line 107)
- "$pp_colour_addb"  (text, line 107)
- "$pp_colour_brightness"  (text, line 108)
- "$pp_colour_contrast"  (text, line 108)
- "$pp_colour_colour"  (text, line 109)
- "$pp_colour_mulr"  (text, line 110)
- "$pp_colour_mulg"  (text, line 110)
- "$pp_colour_mulb"  (text, line 110)

## cl_livingcity_intake.lua (cl_livingcity_intake.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_intake.lua`


*When:* on screen

- "Stay at the terminal"  (drawn on screen, line 77)

*When:* The sign on the terminal itself (lc_intake.lua draws it, in 3D).

- "Registered arrivals: request a room"  (drawn on screen, line 107)
- "New arrivals: registration"  (drawn on screen, line 107)

*When:* How you came to have the room you have.

- "Allocated here, at Housing Allocation."  (text, line 133)
- "Transferred here at your request."  (text, line 134)
- "Came with your papers (there was no Housing Allocation desk then)."  (text, line 135)
- "Assigned by the city administration."  (text, line 136)
- "Already on file before you came to this desk: assigned when you first arrived in the city."  (text, line 137)

*When:* part of: paint

- "citizen {or}"  (drawn on screen, line 163)

*When:* part of: open desk

- "Housing: {or}"  (text, line 197)
- "Identity papers: {or}"  (text, line 198)
- "Ration card: {or}"  (text, line 199)
- "Replace my identity papers (%d credits)"  (message, line 202)
- "Civil Protection units ask for papers; Housing Allocation wants to see them"  (button, line 203)
- "Replace my ration card (%d credits)"  (message, line 206)
- "The ration dispensers want to see it"  (button, line 207)
- "Your papers are in order."  (text, line 209)
- "You have no room yet. Housing Allocation assigns one."  (text, line 212)
- "Show me the way to Housing Allocation"  (text, line 213)
- "Show me the way home"  (text, line 215)
- "The terminal can't find you on the register. Register at Civil Intake first; then come back with your papers."  (text, line 219)
- "Show me the way to Civil Intake"  (text, line 220)
- "Present your papers and pick a block. Any block is approved at once (the least crowded). A crowded block is only granted to citizens in good standing ({or} or more). Yours: {or}."  (text, line 223)
- "Papers: {or}"  (text, line 225)
- "Any block (approved at once)"  (button, line 226)
- "Apply for %s   (%d living there%s%s)"  (message, line 231)
- "No blocks on file in this city."  (text, line 234)
- "Show me the way home"  (text, line 238)
- "Move to another block (once every half hour). A crowded block needs good standing ({or})."  (text, line 241)
- "Transfer to %s   (%d living there%s)"  (message, line 244)
- "Present your papers to apply: you have none on you."  (text, line 248)
- "Not now."  (text, line 250)

*When:* on screen

- "Held up by the person in front of you"  (drawn on screen, line 313)

## cl_livingcity_jobgames.lua (cl_livingcity_jobgames.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_jobgames.lua`


*When:* the game answering something done in a window (lc_papers_check)

- "Papers check: traveler %d of %d"  (message, line 109)

*When:* part of: paint

- "The seal must read OCS."  (drawn on screen, line 131)
- "Look at the traveler: is it them?"  (drawn on screen, line 132)

*When:* the buttons, at the bottom

- "Call a Civil Protection unit"  (text, line 140)

*When:* part of: paint

- "Citizen no."  (text, line 164)
- "Issued in"  (text, line 165)
- "Valid until"  (text, line 166)
- "Day {or}"  (text, line 166)

*When:* the game answering something done in a window (lc_wire_open)

- "Rewiring {or}"  (window title, line 237)

*When:* part of: paint over

- "%d s    Turns %d (par %d)    Shocks %d"  (message, line 254)
- "Click turns a tile, right-click turns it back. Get the current to the lamp. Don't touch a sparking tile."  (drawn on screen, line 256)

## cl_livingcity_kick.lua (cl_livingcity_kick.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_kick.lua`


*When:* on screen

- "Out cold"  (drawn on screen, line 145)
- "You come round in %d"  (message, line 146)

*When:* the game's render screenspace effects moment

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


*When:* part of: open lab

- "He's busy with someone else's work for another %d seconds."  (message, line 57)
- "Bring him the materials and he makes it for nothing, or pay him for it (cheaper than the dealer). Stay in the lab while he works."  (label or button, line 58)
- "Decode it"  (label or button, line 74)

*When:* part of: paint

- "A new face (%d credits)"  (message, line 89)
- "Twenty seconds under. Nobody's looking for the face you wake with: wanted, BOLOs and"  (drawn on screen, line 90)
- "photos gone, and the records can't put your old name (or your standing) to it."  (drawn on screen, line 91)

*When:* part of: open lab

- "Change it"  (label or button, line 97)
- "Pay {or} credits"  (label or button, line 125)
- "Use my materials"  (label or button, line 132)

## cl_livingcity_lagwatch.lua (cl_livingcity_lagwatch.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_lagwatch.lua`


*When:* part of: set lag watch

- "[Lag monitor]"  (chat message, line 47)
- "On. It's at the right of your screen. (lc_lagwatch_print copies the last half minute to the console.)"  (chat message, line 47)

*When:* Which looks like the cause

- "The gamemode is teleporting NPCs ({tele} this second{or})."  (text, line 176)

*When:* part of: verdict

- "The server is hitching: %.0f ms between two frames (it should be %.0f)."  (message, line 179)

*When:* ping well above its usual: data queueing somewhere between you and the server

- "Your ping jumped from about %d to %d ms with the server keeping up: something on the connection (a download, another device, the host's upload)."  (message, line 184)
- "Packets are being lost between you and the server (%d%%): the connection or the host."  (message, line 187)

*When:* part of: verdict

- "The server's updates reach you late (a %.0f ms wait): the network, or the server sending you too much (choke). Check net_graph 3."  (message, line 190)
- "Your own game is stalling (a %.0f ms frame): addons, or the graphics."  (message, line 193)
- "NPCs are snapping, but nothing measured here explains it yet. Send lc_lagwatch_print."  (text, line 196)
- "Nothing wrong this second."  (text, line 198)

*When:* on screen

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

*When:* the console command lc_lagwatch_print

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

*When:* The other way to look at the same list: by what it's for, everything a part of the city needs in one place (building a rebel base: its zone, its lab, its beds, its lookouts, all together). A thing can be in more than one. Occupations get a folder each: their workplace and what goes with it.

- "Citizens' daily life"  (title, line 31)
- "Arriving and leaving the city"  (title, line 33)
- "Civil Protection and the Combine"  (title, line 34)
- "The Resistance and rebel bases"  (title, line 37)
- "Morning exercise"  (title, line 40)
- "Power and the street"  (title, line 41)
- "Paths, ladders and doors"  (title, line 42)

*When:* What the city would like to have and hasn't got.

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

*When:* part of: glance

- "%d points, %d fixtures, %d zones, %d tagged doors, %d path nodes.  %d city NPCs about."  (message, line 160)

*When:* part of: build layout browser

- "Loading the layout..."  (label or button, line 179)
- "Stop finding everything"  (label or button, line 191)

*When:* arranged by type (points, fixtures...) or by what it's for: the list is rebuilt in place

- "Arrange by type: points, fixtures, zones, doors"  (text, line 197)
- "Arrange by what it's for: rebels, prison, each job..."  (text, line 198)

*When:* part of: groups

- "Job: {name}"  (title, line 213)

*When:* part of: fill

- "Take me to the next one (admins)"  (tooltip, line 282)
- "Mark every one of these on screen, through walls"  (tooltip, line 293)

## cl_livingcity_life.lua (cl_livingcity_life.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_life.lua`


*When:* "3 hours 12 minutes", "2 days 5 hours", "40 minutes", "less than a minute"

- "less than a minute"  (text, line 59)

*When:* The lines under the name, in order.

- "Lived {secs} in the city."  (text, line 75)

*When:* part of: death lines

- "Lived at least {secs} in the city."  (text, line 77)
- "Lived in the city since before anyone kept count."  (text, line 79)
- "Nobody knew {her} name."  (text, line 83)
- "One person knew {her} name."  (text, line 85)
- "people knew {her} name."  (text, line 87)

*When:* the game's post draw hud moment

- "Citizen {cid}"  (drawn on screen, line 125)
- "You died."  (drawn on screen, line 129)
- "That person is gone."  (drawn on screen, line 142)
- "Click to go on."  (drawn on screen, line 146)

## cl_livingcity_moregames.lua (cl_livingcity_moregames.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_moregames.lua`


*When:* Records terminal: stop the needle in the band

- "Records terminal: stop the needle in the band (click or space)"  (window title, line 85)

*When:* part of: paint

- "Bypassed %d of %d"  (message, line 111)
- "Seen %d of 2"  (message, line 112)
- "Scanner coming..."  (text, line 115)

*When:* part of: hack

- "Step away from it"  (button, line 119)

*When:* Searching the dead: pocket by pocket

- "Searching the dead: %d of %d"  (message, line 132)

*When:* part of: paint

- "The overseer is out of the room"  (drawn on screen, line 140)

*When:* part of: search

- "Done: into the fire"  (button, line 146)

*When:* part of: paint

- "Not searched"  (text, line 159)
- "(yours now)"  (text, line 160)
- "(set aside for the family)"  (text, line 161)

*When:* part of: fill

- "Log it"  (text, line 174)

*When:* part of: update

- "Searching the dead: %d of %d"  (message, line 178)

*When:* Sorting uniforms

- "Sorting: every uniform to its division"  (window title, line 187)

*When:* part of: paint

- "Uniform %d of %d"  (message, line 195)
- "Something in the pocket: {pocket}"  (drawn on screen, line 198)

*When:* part of: laundry

- "Pocket it"  (button, line 206)
- "Turn it in"  (button, line 208)

*When:* Filing

- "Filing: by citizen number; anything that doesn't match the register, to the discrepancy tray"  (window title, line 229)

*When:* part of: paint

- "Citizen no."  (drawn on screen, line 240)
- "Form %d of %d    %d s"  (message, line 247)

*When:* part of: filing

- "Take a blank identity form from the cabinet"  (button, line 259)

*When:* part of: radio

- "Radio repair: find its station, then set the screws by ear until it's clean"  (window title, line 430)

*When:* the time left on this set, ticking down (red near the end: it goes back on the shelf unfixed)

- "Set %d of %d"  (message, line 468)

*When:* part of: radio

- "Volume trimmer"  (text, line 477)
- "Test it: is it clean?"  (button, line 485)
- "Report the frequency"  (text, line 502)
- "Write it down"  (text, line 502)
- "Tune past it"  (text, line 502)

*When:* part of: paint over

- "Set %d of %d: clean. Off the bench it goes."  (message, line 530)
- "Set %d of %d: out of time. Back on the shelf, unfixed."  (message, line 531)
- "The next one from the shelf..."  (drawn on screen, line 533)

*When:* part of: listen window

- "Radio (retuned)"  (window title, line 561)
- "Union radio"  (window title, line 561)
- "Switch it off"  (button, line 596)
- "Anyone within about twenty feet hears it too. Close this and it keeps playing."  (label or button, line 604)

*When:* part of: paint

- "They stand very still and look at nothing."  (drawn on screen, line 642)
- "Their nerve: %d    Citizen %d of %d"  (message, line 643)

## cl_livingcity_needs.lua (cl_livingcity_needs.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_needs.lua`

- "Union band"  (text, line 117)
- "Civil Protection uniform"  (text, line 118)
- "citizen clothes"  (text, line 118)
- "Resistance gear"  (text, line 118)

*When:* Breen's water, and coffee

- "Everything feels... pleasant. What were you doing?"  (chat message, line 180)

*When:* the game answering something done in a window (lcn_effect)

- "Real coffee. For a moment you remember what mornings used to be."  (chat message, line 183)

*When:* the game's render screenspace effects moment

- "$pp_colour_addr"  (text, line 200)
- "$pp_colour_addg"  (text, line 200)
- "$pp_colour_addb"  (text, line 200)
- "$pp_colour_brightness"  (text, line 201)
- "$pp_colour_contrast"  (text, line 201)
- "$pp_colour_colour"  (text, line 202)
- "$pp_colour_mulr"  (text, line 202)
- "$pp_colour_mulg"  (text, line 202)
- "$pp_colour_mulb"  (text, line 202)
- "$pp_colour_addr"  (text, line 208)
- "$pp_colour_addg"  (text, line 208)
- "$pp_colour_addb"  (text, line 208)
- "$pp_colour_brightness"  (text, line 209)
- "$pp_colour_contrast"  (text, line 209)
- "$pp_colour_colour"  (text, line 209)
- "$pp_colour_mulr"  (text, line 210)
- "$pp_colour_mulg"  (text, line 210)
- "$pp_colour_mulb"  (text, line 210)

*When:* weight and large things, against what you can carry

- "%.1f / %.0f kg     large %d / %d"  (message, line 263)
- "Too much to carry: you're slowed down"  (drawn on screen, line 265)

*When:* part of: open inventory

- "Take off the {or}"  (label or button, line 280)
- "Change into plain clothes"  (label or button, line 287)
- "Your papers say you are citizen {alias}."  (label or button, line 295)
- "Drink from the water (it may not be clean)"  (label or button, line 304)
- "Empty. Nothing to find."  (label or button, line 334)
- "Nothing for sale right now."  (text, line 334)
- "Nothing on it. Put things up for sale from your pockets below (Sell)."  (text, line 335)
- "Empty. Put things in from your pockets below."  (text, line 335)
- "Buy ({price})"  (label or button, line 358)

*When:* part of: do click

- "How many credits for one {name}?"  (text, line 375)

*When:* part of: open inventory

- "Collect the takings (%d)"  (message, line 391)
- "Closed by the Union: reopen"  (label or button, line 399)
- "Give up the locker (empty it first)"  (label or button, line 408)
- "Pack up the stall (empty it first)"  (text, line 409)
- "Pack up the crate (empty it first)"  (text, line 409)
- ""{or}..."{or}"  (label or button, line 433)
- "Your pockets are empty."  (label or button, line 448)
- "Hide it at home. (A raid on your block can still find it.)"  (text, line 485)
- "Put one on the stall, at a price you set"  (tooltip, line 492)

*When:* part of: do click

- "How many credits for one {name}?"  (text, line 494)

*When:* part of: open inventory

- "Put in"  (text, line 498)
- "Into {or}"  (text, line 498)
- "Set down"  (text, line 499)
- "Eat it"  (text, line 506)
- "Swallow the motherlode whole. You have a feeling about what happens next."  (text, line 506)
- "Hand one to the person in front of you"  (text, line 508)
- "Look at a locked door first. Or type !pick, or bind a key to lc_pick."  (text, line 509)
- "Become someone else. Clears your wanted status if no Civil Protection unit is watching."  (text, line 511)
- "Out of sight of any Civil Protection unit."  (text, line 512)
- "Visit a Civil Protection Commissary to be issued supplies: grenades for your rank, ammunition, armour, bandages and your ration."  (label or button, line 534)
- "Mark the nearest Civil Protection Commissary on my screen"  (label or button, line 539)

*When:* the lab (sv_livingcity_lab.lua) makes the Resistance's guns; everyone else buys them

- "Guns, ammunition, jammers, radios: the scientist in the lab makes them (mark the lab)"  (label or button, line 552)

*When:* part of: paint

- "(at a workbench)"  (text, line 584)
- "(out of sight)"  (text, line 584)

*When:* part of: open inventory

- "Nothing hidden here yet."  (label or button, line 612)

*When:* what's in your hands: a crowbar, a gun (not what your faction issued you)

- "On you: {name}{TEXT_ALIGN_CENTER}"  (label, line 646)

*When:* part of: open inventory

- "Stash it"  (label or button, line 655)
- "Hide it at home, magazine and all. (A raid on your block can still find it.)"  (tooltip, line 656)

*When:* the game answering something done in a window (lcu_market)

- "Sell for {price}"  (text, line 797)
- "Sell all for {n}"  (text, line 804)

## cl_livingcity_nextstep.lua (cl_livingcity_nextstep.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_nextstep.lua`


*When:* The rank card: faction and rank, credits, Civil Standing (and wanted, when you are).

- "Credits %d     Civil Standing %d"  (message, line 63)

*When:* on screen

- "F1 > 1 shows you the way"  (drawn on screen, line 101)

*When:* F1, slot 1

- "Ration dispenser"  (text, line 113)
- "Water (a sink or a machine)"  (text, line 113)
- "Bins to search"  (text, line 113)
- "My block"  (text, line 114)
- "My workplace"  (text, line 114)
- "The Commissary"  (text, line 114)
- "Bathtub or shower"  (text, line 115)
- "Civil Intake"  (text, line 117)
- "Housing Allocation"  (text, line 117)

*When:* part of: more places page

- "Civil Protection Commissary"  (menu option, line 124)
- "The lab"  (menu option, line 125)
- "A mess to clean up"  (menu option, line 126)

*When:* part of: places page

- "More places..."  (text, line 136)

*When:* part of: what now page

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


*When:* A sound the server asked for that this computer can't play: said once per file, on screen and in the console, with why. Announcements and songs play on each player's own computer, so the sound addon has to be on it too.

- "it isn't on this computer"  (text, line 77)

*When:* part of: sound trouble

- "Sound missing"  (on-screen notice, line 81)
- "Can't play {path}: {why}. Type lc_sound_check in the console to see why."  (on-screen notice, line 81)

*When:* the console command lc_sound_check

- "Game volume: {or}, lc_breencast_volume (the Administrator): {or}"  (chat message, line 117)
- "This computer has none of the city's sounds, so you hear none of them. The server sends them through FastDL: after a sound is added there, press FastDL sync, change the map, and reconnect. (For a game of your own, put them in garrysmod/sound/livingcity/ here.)"  (chat message, line 120)

*When:* the ending songs: every one on this computer, opened (not played) to see the game can play it

- "Ending songs on this computer (checking each one opens):"  (chat message, line 130)

*When:* play file

- "%s (%d KB): the game can't open it (%s)%s"  (message, line 139)
- ": it's empty, a download that didn't finish (delete it here and reconnect)"  (message, line 140)
- ": re-encode it as a 44100 Hz MP3"  (message, line 140)

*When:* the console command lc_sound_check

- "(A song added to the server only reaches players after the server changes map and they reconnect: FastDL sync, then a map change.)"  (chat message, line 144)

*When:* the stock Half-Life 2 Overwatch lines the city uses: which this install has

- "Half-Life 2's own Overwatch lines the city uses (found here, or missing):"  (chat message, line 146)

*When:* the console command lc_sound_check

- "Playing {first} now..."  (chat message, line 154)

*When:* play file

- "It plays. If you heard nothing, check your game volume. If you heard it but not in the city, tell the server's admin to run lc_announce_clips."  (chat message, line 158)
- "It's here but the game can't play it ({err}): the file isn't what its name says. Rename an MP3 to .mp3; a WAV must be 16-bit, 44100 Hz."  (chat message, line 160)

*When:* part of: draw waypoint

- "You're here: {label}."  (on-screen notice, line 273)

## cl_livingcity_outfits.lua (cl_livingcity_outfits.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_outfits.lua`


*When:* part of: describe

- "%s%s   (%d skins, %d pieces)"  (message, line 51)
- "own face,"  (message, line 51)

*When:* part of: open outfit designer

- "Job outfits"  (window title, line 62)
- "Looks for this job (each person gets one)"  (text, line 84)

*When:* part of: rebuild

- "Pick a job on the left."  (text, line 132)
- "Model (anything installed: citizens, medics, hostages, a pack)"  (text, line 133)
- "Choose a model..."  (text, line 137)
- "Keep each person's own face (a Half-Life 2 citizen face, in these clothes)"  (label or button, line 147)
- "NPC model (blank: worked out from the playermodel)"  (text, line 155)
- "Skins it may wear (%d): none ticked means any"  (message, line 164)
- ": the pieces it may show (none ticked: left as it is)"  (text, line 176)

*When:* part of: open outfit designer

- "Add this look"  (button, line 200)
- "Remove the selected look"  (button, line 211)
- "Save this job"  (button, line 217)

## cl_livingcity_quests.lua (cl_livingcity_quests.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_quests.lua`


*When:* part of: paint

- "{sympathy}     {corruption}"  (drawn on screen, line 50)

*When:* the game answering something done in a window (lcq_board)

- "Change job..."  (text, line 75)
- "You can take another job in {wait} seconds."  (label or button, line 89)
- "Nothing posted right now. Check back soon."  (label or button, line 97)
- "\|   %d/%d on it"  (message, line 140)
- "\|   up to %d together"  (message, line 140)
- "Join the squad"  (label or button, line 158)
- "Take the job"  (label or button, line 161)
- "ahead left"  (text, line 355)
- "behind left"  (text, line 355)
- "behind right"  (text, line 355)
- "ahead right"  (text, line 355)

*When:* anything more than a flight of stairs away counts: 48 units is "other level", then about 144 to a floor

- "same level"  (text, line 367)

*When:* on screen

- "A choice is waiting (it may be behind other windows)"  (drawn on screen, line 418)
- "Your squad leader is deciding..."  (drawn on screen, line 418)

*When:* being seen while tailing someone: right where you're looking, so you notice in time to duck back

- "out of sight"  (text, line 447)

*When:* on screen

- "objective  {dist} m"  (text, line 464)

## cl_livingcity_quick.lua (cl_livingcity_quick.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_quick.lua`


*When:* Pages

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

*When:* part of: talk page

- "Out of character, nearby..."  (menu option, line 60)

*When:* item

- "Out of character"  (chat message, line 60)
- "Said out of character, to people nearby"  (chat message, line 60)

*When:* part of: talk page

- "Out of character, everyone..."  (menu option, line 61)

*When:* item

- "Out of character"  (chat message, line 61)
- "Said out of character, to the whole server"  (chat message, line 61)

*When:* part of: talk page

- "Tell everyone nearby my name"  (menu option, line 62)

*When:* part of: pose page

- "Lie down"  (menu option, line 68)
- "Stand: pose 1"  (menu option, line 69)
- "Stand: pose 2"  (menu option, line 70)
- "Stand up"  (menu option, line 71)

*When:* part of: voice page

- "All the voice lines..."  (menu option, line 105)

*When:* part of: resistance page

- "Find the lab (mark it)"  (menu option, line 118)
- "Donate food to the supply crate"  (menu option, line 119)
- "Decode a data chip (at the lab)"  (menu option, line 120)
- "Hack the Combine door I'm looking at"  (menu option, line 122)

*When:* part of: staff page

- "Staff panel (logs, tickets, warnings, bans)"  (menu option, line 129)
- "Admin testing tools"  (menu option, line 130)
- "Build mode: off (back to playing)"  (menu option, line 131)
- "Build mode: on"  (menu option, line 131)
- "Path mapping: on / off"  (menu option, line 132)

*When:* The first page: who you are

- "Lower my hands"  (menu option, line 219)
- "Put my hands up"  (menu option, line 219)

*When:* part of: quick root

- "My pockets (F2)"  (menu option, line 220)
- "My board: jobs (F3)"  (menu option, line 221)

*When:* slot 1 for anyone living in the city: the next step, and the way to everywhere (cl_livingcity_nextstep.lua)

- "What now?"  (text, line 223)
- "Call for backup"  (menu option, line 229)
- "Send my 10-20"  (menu option, line 230)

*When:* item

- "What should Civil Protection units look out for?"  (text, line 231)

*When:* part of: quick root

- "Voice lines"  (text, line 232)
- "Kick ({or})"  (menu option, line 233)
- "Unit tools (everything a unit has)"  (menu option, line 236)
- "My directives (F3)"  (menu option, line 237)
- "Gear up (Resistance clothes)"  (menu option, line 246)
- "Change into plain clothes"  (menu option, line 246)
- "Black market"  (menu option, line 248)
- "My papers"  (menu option, line 256)

*When:* 6 to 8: what's in front of you first, then your usual three

- "Everything else (full menu)"  (menu option, line 265)

*When:* on screen

- "+menu_context"  (text, line 366)
- ": the full menu"  (drawn on screen, line 367)

## apartment doors (client) (cl_livingcity_rent.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_rent.lua`


*When:* The lines to show for a door entity (nil: not an apartment door).

- "Apartment: available"  (text, line 33)
- "%d credits for %s hours"  (message, line 33)

*When:* part of: rent lines

- "Right click to rent it"  (text, line 34)
- "Put your hands out (nothing in them) and right click to rent it"  (text, line 34)
- "Your apartment ({or})"  (text, line 40)
- "Right click to {or} it"  (text, line 41)
- "Put your hands out and right click to lock or unlock it"  (text, line 41)
- "Apartment: {name}'s"  (text, line 43)

*When:* the game answering something done in a window (lc_rent_ask)

- "Rent this apartment for %d credits? It is yours for %s hours, locked to everyone but you and whoever you give a key."  (message, line 82)
- "Rent apartment"  (text, line 86)
- "Yes, rent it"  (text, line 86)

## cl_livingcity_resistance.lua (cl_livingcity_resistance.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_resistance.lua`


*When:* on screen

- "BROKEN FEET: no running for %d:%02d"  (message, line 34)
- "COMBINE PROPERTY: there is no way out but death"  (text, line 39)
- "INTERROGATION   Talk (F1, or the choice on screen) to make it stop. Or say nothing, and take it."  (text, line 43)

*When:* part of: draw city screen

- "They are not invincible. Look out for one another."  (drawn on screen, line 110)

*When:* Someone on air: a banner for everyone, so you know whose voice it is

- "(the loudspeaker here is broken)"  (text, line 125)

## cl_livingcity_rest.lua (cl_livingcity_rest.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_rest.lua`


*When:* asleep: dark, and a little reassurance

- "Asleep (%ds). Jump to get up (too soon, and it won't count)."  (message, line 63)

*When:* after a close call: still recovering (sv_livingcity_progress.lua)

- "Recovering from a close call (%d:%02d): a little less to give"  (message, line 95)

*When:* the urge (parasites): a line under the needs while it's building

- "You need a toilet. NOW."  (drawn on screen, line 103)
- "Your stomach cramps: find a toilet."  (text, line 103)
- "Your stomach's unsettled."  (text, line 103)

## cl_livingcity_rp.lua (cl_livingcity_rp.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_rp.lua`


*When:* What they look like, to someone who doesn't know them.

- "A shackled vortigaunt"  (text, line 45)

*When:* part of: description

- "in Resistance gear"  (text, line 48)
- "in Union blue"  (text, line 48)
- "A {who} {clothes}"  (text, line 49)

*When:* on screen

- "Bleeding out: %d:%02d"  (message, line 63)
- "Someone can help you up (E on you). You can still whisper. !giveup to let go."  (text, line 65)
- "Down, bleeding out (%ds). E to help them up. !drag to drag them."  (message, line 81)

## the scanner link, as the pilot sees it, and scanner reports, (cl_livingcity_scanner.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_scanner.lua`


*When:* the readout, top centre, like the mask's

- "CUSTODY: {now}     PHOTO RANGE: {range} FT"  (drawn on screen, line 97)

*When:* on screen

- "WASD fly   SPACE up   CTRL down   SHIFT faster   LMB flash / photograph   R disconnect"  (drawn on screen, line 153)
- "Flash a Civil Protection unit: more time.  Photograph a suspect up close: Civil Standing, never time off."  (drawn on screen, line 156)

*When:* a jammer nearby: the radio's static (sv_livingcity_convoy.lua)

- "A jammer is close. Find it (it beeps) and press E to smash it."  (text, line 251)

*When:* on screen

- "SCANNER: {GetNW2String}"  (text, line 260)
- "%dm  %ds"  (message, line 262)

## cl_livingcity_slots.lua (cl_livingcity_slots.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_slots.lua`


*When:* part of: paint

- "Slot {i}: empty"  (drawn on screen, line 45)
- "Someone new: a name, a face, nothing to their name."  (drawn on screen, line 46)
- "%s credits   \|   standing %s%s"  (message, line 52)
- "\|   playing now"  (message, line 53)
- "%d close call%s left"  (message, line 55)
- "No close calls left: the next death is the end"  (drawn on screen, line 55)

*When:* part of: card

- "Retire them"  (label or button, line 68)

*When:* part of: do click

- "Retire {or}? They leave the city for good, and somebody new takes their place. The new person inherits a little of their savings."  (text, line 71)
- "Retire character"  (text, line 72)
- "Keep playing"  (text, line 73)

*When:* part of: card

- "Play as them"  (label or button, line 80)
- "Start someone new"  (label or button, line 80)

*When:* part of: do click

- "Delete {or}? Everything they had goes with them."  (text, line 92)
- "Delete character"  (text, line 92)

*When:* the game answering something done in a window (lc_slots)

- "Your characters"  (window title, line 104)
- "Lives lived: %d.  Longest: %dh %02dm%s.%s"  (message, line 116)
- "({longestName})"  (text, line 116)
- "You can't switch right now: {why}"  (label or button, line 123)

## cl_livingcity_staff.lua (cl_livingcity_staff.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_staff.lua`


*When:* part of: show

- "Pick a ticket."  (text, line 83)
- "claimed by {or}"  (text, line 84)
- "{or}: {or}"  (text, line 86)
- "Go to"  (text, line 90)
- "Reply (Enter to send)"  (text, line 96)

*When:* part of: tickets tab

- "Tickets ({open} open)"  (text, line 111)

*When:* part of: logs tab

- "Search (a name, a word, a SteamID)"  (text, line 128)

*When:* part of: players tab

- "Go to"  (text, line 171)

*When:* btn

- "Warn {name}"  (text, line 173)

*When:* part of: players tab

- "Ban character"  (text, line 174)

*When:* btn

- "Ban {or}"  (text, line 175)
- "The character is wiped and their name can't be used again. Why?"  (text, line 175)

*When:* part of: players tab

- "Players ({or})"  (text, line 179)

*When:* part of: warnings tab

- "No warnings."  (text, line 185)
- "Strike off"  (label or button, line 195)

*When:* part of: bans tab

- "No characters banned."  (text, line 204)
- "%s  %s (%s), player %s: %s  (by %s)"  (message, line 210)
- "Character bans"  (text, line 217)

*When:* Open tickets, for staff, under the clock

- "open ticket"  (text, line 258)
- "open tickets"  (text, line 258)

*When:* on screen

- "Warning %d, from %s"  (message, line 282)

## cl_livingcity_talk.lua (cl_livingcity_talk.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_talk.lua`


*When:* the game answering something done in a window (lc_talk)

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


*When:* part of: open unit tools

- "[Unit tools]"  (chat message, line 47)
- "For Civil Protection (the Overwatch included)."  (chat message, line 47)

*When:* part of: paint

- "Sociostability %s     BOLOs out: %d"  (message, line 66)

*When:* part of: open unit tools

- "Call for backup"  (button, line 124)
- "The nearest Civil Protection units come to you, and see where you are."  (button, line 124)
- "Send my 10-20"  (button, line 125)
- "Marks where you are on every Civil Protection unit's screen."  (button, line 125)
- "Something for every Civil Protection unit to look out for: a face, clothes, a name."  (button, line 126)

*When:* button

- "What should Civil Protection units look out for?"  (text, line 128)

*When:* part of: open unit tools

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
- "Cut the ties"  (button, line 146)
- "Let their hands go."  (button, line 146)
- "Drag them along / let go"  (button, line 147)
- "Walk them where you're going."  (button, line 147)
- "Zip-tie their hands"  (button, line 149)
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


*When:* the console command lc_bob_toggle

- "[Living City]"  (chat message, line 38)
- "The camera sways with your steps again. (!bob keeps it still.)"  (chat message, line 38)
- "The camera holds still now. (!bob brings the sway back.)"  (chat message, line 39)

*When:* part of: calc view

- "[Living City] camera: '{name}' failed and is off until you rejoin: {err} /"  (text, line 74)

## cl_livingcity_war.lua (cl_livingcity_war.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_war.lua`

- "The Combine doesn't patrol here. Civil Protection units get shot at."  (text, line 23)
- "Infested ground. Nobody comes back the same."  (text, line 24)
- "More inspections and raids, ration cuts. Black market cheaper."  (text, line 95)
- "The rebels are quiet. Black market prices are up."  (text, line 96)
- "Nobody holds the upper hand."  (text, line 97)

*When:* part of: draw control bar

- "Combine %d%%   Resistance %d%%   Infested %d%%   \|   %s"  (message, line 114)

*When:* part of: pot label

- "Empty pot"  (text, line 238)
- "Plant a seed packet (E)"  (text, line 238)
- "Ripe vegetables"  (text, line 239)
- "Ripe in %d:%02d"  (message, line 241)

*When:* on screen

- "%d meal%s stored"  (message, line 256)
- "Step in and they'll open fire."  (text, line 342)
- "You're inside. They will shoot."  (text, line 346)

## cl_livingcity_ways.lua (cl_livingcity_ways.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_ways.lua`


*When:* part of: open ways

- "Ways to get by"  (window title, line 33)
- "Show me"  (label or button, line 56)

## cl_livingcity_writing.lua (cl_livingcity_writing.lua)

`gamemodes/livingcity/gamemode/modules/client/cl_livingcity_writing.lua`


*When:* part of: open writer

- "What do you want to write? (up to 600 characters)"  (text, line 70)
- "Sign it with your name"  (label or button, line 78)
- "Leave it here"  (text, line 93)
- "Put it up on the wall"  (text, line 93)
- "Keep it"  (text, line 93)

*When:* the game answering something done in a window (lc_read)

- "Take it"  (text, line 151)
- "Tear it down"  (text, line 152)
- "Leave it here"  (text, line 154)
- "Put it up"  (text, line 155)

*When:* post it to someone (sv_livingcity_mail.lua): at the post office

- "Send as a letter"  (label or button, line 162)

*When:* the game answering something done in a window (lc_read)

- "Tear it up"  (text, line 171)

*When:* On a city screen (lc_screen): the latest broadcast, until there's another.

- "Compliance is its own reward. Your cooperation is noted."  (text, line 213)

*When:* part of: draw law board

- "Press E to read"  (drawn on screen, line 249)

*When:* the game answering something done in a window (lc_laws)

- "The city's laws"  (window title, line 267)
- "A new law (Enter to add). Edit one above and press Enter to change it."  (text, line 301)

*When:* Civil Protection reads the mail (sv_livingcity_mail.lua)

- "The mail, waiting to go out"  (window title, line 316)

*When:* the game answering something done in a window (lc_mail_list)

- "Nothing waiting."  (label or button, line 325)
- "To %s, posted by %s%s"  (message, line 336)
- "(signed "{sig}")"  (text, line 336)
- "Confiscate it"  (label or button, line 345)

## sv_livingcity.lua (sv_livingcity.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity.lua`


*When:* part of: error

- "[Living City] {where}: {err} /"  (text, line 99)

*When:* part of: say

- "[Living City] {msg}"  (chat message, line 190)

*When:* only trust the zones if the main area is a real share of the map

- "%d of %d ground nodes, in the main connected area%s"  (message, line 484)

*When:* part of: read nodegraph

- "(%d walkable links, routes planned over them)"  (message, line 485)

*When:* part of: handle moving

- "engine found no path"  (text, line 666)
- "no progress"  (text, line 669)
- "took too long"  (text, line 670)

*When:* part of: line think

- "had their ration and went home"  (text, line 972)

*When:* Stuck NPCs are logged a few at a time, then summarized, so they don't push everything else out of the debug report.

- "...and %d more stuck NPCs moved in the last minute (%s)"  (message, line 1017)

*When:* Someone who isn't getting anywhere. If nobody's watching and the place they were heading for is close (a prop in the way, a doorframe), they're quietly put there. A far one isn't: popping people across the map is worse than the trip being given up, so they give it up, and that place is remembered as hard to reach so it isn't picked again straight away.

- "no progress"  (text, line 1032)
- "no progress"  (text, line 1032)

*When:* nobody's looking and it's just a step away: put them there. Not someone a quest has you chasing or following, though: they'd seem to go through walls.

- "%s stuck near %s (%s), moved on to hop %d/%d (%s)"  (message, line 1042)
- "no progress"  (message, line 1043)

*When:* part of: recover

- "%s removed after %d recoveries near %s"  (message, line 1055)

*When:* part of: register

- "their time out was up (lc_citizen_lifetime: a citizen stays about that long, then others come)"  (text, line 1183)

*When:* part of: choose citizen task

- "curfew or lockdown: gone home"  (text, line 1569)

*When:* more people out than the hour calls for: home (sv_livingcity_rhythm.lua)

- "the time of day: fewer people out at this hour"  (text, line 1574)

*When:* part of: cop provoked

- "[Civil Protection] The Civil Protection unit shoves you back. Move along."  (chat message, line 1945)
- "[Civil Protection] A crack across the ribs with the stick. Last warning."  (chat message, line 1946)
- "[Civil Protection] You were warned. Obstructing Civil Protection."  (chat message, line 1950)
- "Obstructing Civil Protection"  (text, line 1951)

*When:* A city scanner that has a fugitive in sight (wanted, or a hunted rebel who isn't passing as a citizen) tells the units where they are: a flash, a report to every unit on duty, and the nearby units come after them.

- "a wanted citizen"  (text, line 2105)

*When:* part of: scanner tip off

- "A scanner's flash. You've been photographed, and Civil Protection has the picture."  (chat message, line 2110)
- "[CP net] Scanner report: %s%s."  (message, line 2114)

*When:* part of: start

- "This map has no AI nodes or navmesh and nothing placed yet. Lay some path nodes or points with the Living City Editor, then start again."  (chat message, line 2345)
- "Started. Map nav: %d spots (%s). Your layout: %d points, %d path nodes."  (message, line 2352)

*When:* part of: stop

- "Stopped and removed all Living City NPCs."  (chat message, line 2369)

*When:* part of: spawn test walker

- "your path network (%d hops)"  (message, line 2398)
- "the map's own navigation"  (text, line 2398)
- "Test walker heading out using {how}."  (chat message, line 2399)

*When:* part of: test arrived

- "Test walker arrived in %.1f seconds. This route works."  (message, line 2404)

*When:* part of: test stuck

- "Test walker stuck at %s on hop %d/%d"  (message, line 2411)
- "Test walker got stuck after %.1f seconds, on hop %d of %d (marked red)."  (message, line 2412)
- "Add a path node here and link it toward the destination, or check for a door it can't open."  (text, line 2415)

*When:* guarding a supply drop (sv_livingcity_convoy.lua): he answers, without leaving his post

- "[Civil Protection] "Supply point secure. Hold the perimeter until the load moves on.""  (chat message, line 2638)

*When:* pressing E on something

- "[Civil Protection] "{Pick}""  (chat message, line 2642)

*When:* a Civil Protection player stops a citizen: they freeze and apologise

- "[Civil Protection] Stopped. With the Arrest Baton out: R to search them, right click to detain."  (chat message, line 2659)

*When:* a crime, and every cop comes for you (a scanner is city property, not a person) (one report per few seconds for a scanner: every bullet of a burst isn't a new offence)

- "Damaging city property"  (text, line 2709)
- "Assaulting Civil Protection"  (text, line 2712)
- "Assaulting a citizen"  (text, line 2712)

*When:* Console commands

- "Civil Protection has stood down."  (chat message, line 2748)

*When:* the console command lc_addpoint

- "Kinds: idle, sit, sitchair, lean, queue, patrol, checkpoint, spawn, cell, release"  (chat message, line 2755)
- "Added %s point (%d total on this map)."  (message, line 2758)

*When:* the console command lc_removepoint

- "Removed nearest {kind} point."  (text, line 2764)
- "No point within 150 Civil Protection units."  (chat message, line 2764)

*When:* the console command lc_status

- "citizens %d/%d, cops %d/%d, soldiers %d/%d, scanners %d/%d, zombies %d/%d, rebels %d/%d"  (message, line 2775)
- "map nav %d (%s) \| points %d \| path nodes %d, links %d, unlinked %d \| zones %d \| lines %d \| patrol beats %d"  (message, line 2779)

## the actions menu (server side) (sv_livingcity_actions.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_actions.lua`


*When:* the game answering something done in a window (lc_interrogate_reply)

- "[Interrogation] You say nothing."  (chat message, line 133)

## acts (server). See sh_livingcity_acts.lua for the list (sv_livingcity_acts.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_acts.lua`


*When:* part of: start act

- "Acts are off on this server."  (text, line 23)
- "No such pose."  (text, line 25)
- "Not with your hands tied."  (text, line 27)
- "Get your feet on the ground first."  (text, line 29)
- "Stand still first."  (text, line 30)
- "(This model has no animation for that, but you hold still.)"  (chat message, line 43)

*When:* the chat command /act

- "Poses: /sit /kneel /lie /lean /cower /pose 1-4 (/stand to get up). Gestures: /wave /salute /bow /nod /shake /point /beckon /halt /cheer /laugh"  (chat message, line 93)

## testing tools for admins (sv_livingcity_admintools.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_admintools.lua`


*When:* Everything the panel can do. Returns ok, and a line to tell the admin.

- "That faction has no ranks to climb."  (text, line 53)
- "by staff"  (text, line 56)

*When:* part of: rank

- "That faction has no ranks."  (text, line 62)
- "%s ranks go from 1 to %d."  (message, line 63)
- "by staff"  (text, line 66)
- "%s is now %s (%d XP)."  (message, line 67)

*When:* part of: resetxp

- ": XP back to 0 in every faction."  (text, line 71)

*When:* part of: credits

- "The economy is off."  (text, line 74)

*When:* part of: resetcredits

- ": credits back to 0."  (text, line 80)

*When:* part of: standing

- "The economy is off."  (text, line 83)
- "%s: Civil Standing %d."  (message, line 85)

*When:* part of: setstanding

- "The economy is off."  (text, line 88)
- "%s: Civil Standing %d."  (message, line 90)

*When:* part of: resetme

- ": XP, credits and standing all back to 0."  (text, line 96)

*When:* part of: faction

- "No such faction."  (text, line 100)
- "is now {name}."  (text, line 102)

*When:* part of: clearwanted

- "is no longer wanted."  (text, line 108)

*When:* part of: pardon

- "No conduct tracking here."  (text, line 111)
- ": conduct strikes cleared."  (text, line 113)

*When:* part of: needs

- ": fed, watered, healed."  (text, line 119)

*When:* the city, not the player: a city-wide blackout (sv_livingcity_power.lua)

- "No power grid here."  (text, line 123)
- "City-wide blackout: {or}{or}."  (text, line 125)
- "No such item."  (text, line 129)

*When:* part of: item

- "'s pockets are full."  (text, line 130)

*When:* part of: admin tool

- "Admins only."  (text, line 137)
- "Nobody to do that to."  (text, line 139)
- "Unknown action."  (text, line 141)
- "That failed: {a}"  (text, line 143)
- "admin tools: %s used %s %s on %s"  (message, line 145)

*When:* the console command lc_admintools

- "Admins only."  (chat message, line 177)

*When:* the game answering something done in a window (lc_admintools_do)

- "[Admin tools] {msg}"  (chat message, line 185)

*When:* typing in chat

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

*When:* part of: announce unused

- ": doesn't start with a trigger (a typo?)"  (text, line 224)
- ": {t} is no longer said (a surprise, or it answers violence)"  (text, line 226)
- ": plays as Overwatch (a tone word only means something to the Administrator: is this her recording?)"  (text, line 228)

*When:* part of: say

- "[{or}] "{text}""  (chat message, line 385)
- "[{or}] "{text}""  (chat message, line 401)

*When:* a timer (regularly)

- "Sound files"  (on-screen notice, line 568)
- "recording(s) can't be played (an MP3 renamed .wav, or a WAV that isn't 16-bit 44100 Hz). Type lc_announce_clips in the console to see which, and how to fix each."  (on-screen notice, line 568)

*When:* the console command lc_announce_clips

- "[Living City] {v}: {or}"  (text, line 595)
- "[Living City]   check {v}/{why}"  (text, line 596)
- "[Living City]   CAN'T PLAY {why}"  (text, line 599)
- "[Living City] {v}: {parts}"  (text, line 607)
- "[Living City] Players' computers play these, so each needs the files: {or}sv_allowdownload {or}, sv_downloadurl "{or}" (a Workshop addon is the reliable way). Each player can type lc_sound_check to test their own."  (text, line 610)
- "[Living City] {total} custom announcements found. Folders: sound/livingcity/overwatch/, administrator/, radio/ (or the same under sound/{ROOT}), flat: a file's name starts with its trigger (curfew1.wav), and the Administrator's tone is in it (curfew_firm1.wav); lc_announce_rescan after adding files."  (text, line 614)

*When:* the console command lc_announce_rescan

- "[Living City] {AnnounceRescan} custom announcements found."  (text, line 619)

*When:* the console command lc_announce_say

- "[Living City] lc_announce_say <overwatch\|administrator> <trigger> [warm\|firm\|stern\|furious]"  (text, line 625)
- "[Living City] Nothing in sound/{ROOT}{voice}/{trig}/ to say (or it's off)."  (text, line 628)

*When:* the console command lc_announce_tier

- "[Living City] {trig}: she would be {t} about it now (sociostability {or}, {Heat} violent things in ten minutes){or}."  (text, line 636)

## the time of day, the weather, and the city's music (sv_livingcity_atmos.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_atmos.lua`


*When:* part of: set weather

- "It starts to rain."  (text, line 123)
- "A storm rolls in over the city."  (text, line 123)
- "Fog comes down over the streets."  (text, line 123)
- "The sky clouds over."  (text, line 124)
- "The sky clears."  (text, line 124)

*When:* Rain fills an empty bottle or can held out to it.

- "[Living City] Rain fills your {pair}. Rainwater: clean enough to drink as it is."  (chat message, line 182)

*When:* typing in chat

- "It's %s, %s. The weather: %s."  (message, line 239)

## the dead (sv_livingcity_bodies.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_bodies.lua`


*When:* Searching

- "Nothing on them."  (chat message, line 251)

*When:* part of: take loot

- "a health vial"  (text, line 277)
- "Your pockets are full."  (chat message, line 287)
- "Nothing left on them."  (chat message, line 287)
- "You search the body: {found}.{or}"  (chat message, line 289)

*When:* part of: start body search

- "You've already been through their pockets."  (text, line 297)
- "You go through their pockets..."  (chat message, line 303)

*When:* doing this in front of a unit is a crime (unless you are one)

- "Robbing the dead"  (text, line 306)
- "Looting a dead officer"  (text, line 306)

## apartments and trade (sv_livingcity_business.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_business.lua`


*When:* part of: hm

- "%dh %02dm"  (message, line 149)

*When:* Why this person can't rent this door right now (nil if they can).

- "Someone already lives here."  (text, line 155)
- "You already rent somewhere. !unrent it first."  (text, line 156)
- "It's paid up for as long as the landlord will take."  (text, line 157)
- "The rent is %d credits."  (message, line 158)

*When:* part of: rent

- "Look at an apartment door that's for rent."  (text, line 164)
- "Paid. It's yours for %s more."  (message, line 173)

*When:* the other half of a double door comes with it

- "It's yours for %s. Locked to everyone but you. !givekey <name> to let someone in."  (message, line 185)

*When:* part of: unrent

- "You don't rent anywhere."  (text, line 190)
- "You've moved out."  (text, line 196)

*When:* part of: set apartment lock

- "Look at your apartment door."  (text, line 202)
- "You don't have a key."  (text, line 203)
- "Unlocked: anyone can come in."  (text, line 208)

*When:* part of: give key

- "You don't rent anywhere."  (text, line 213)

*When:* or the person in front of you

- "Who? Name them, or look at them."  (text, line 220)

*When:* part of: give key

- "[Living City] {OwnerName} gave you a key to their apartment."  (chat message, line 225)
- "[Living City] {OwnerName} took back the key to their apartment."  (chat message, line 228)
- "You gave {target} a key."  (text, line 231)
- "You took {target}'s key back."  (text, line 231)

*When:* part of: apartment info

- "You don't rent anywhere, but you have keys to: {keys}'s."  (text, line 239)
- "You don't rent anywhere. Look at an apartment door that's for rent and !rent."  (text, line 240)
- "Your apartment, %s: %s left, %s. Keys: %s."  (message, line 247)
- "just you"  (message, line 248)

*When:* part of: rent door use

- "Forcing the door..."  (progress bar, line 274)
- "You stop."  (text, line 275)

*When:* part of: done

- "[Living City] Civil Protection forced the door of {or}'s apartment."  (chat message, line 284)

*When:* part of: rent door use

- "Locked. (Someone lives here.)"  (chat message, line 293)

*When:* a timer (regularly)

- "[Living City] Your rent ran out. The apartment isn't yours any more."  (chat message, line 308)
- "[Living City] Your rent runs out in 10 minutes. Look at the door, F1 > Rent / lock this door to pay more."  (chat message, line 314)

*When:* part of: hands right click

- "Someone lives here."  (chat message, line 349)

*When:* the game answering something done in a window (lc_rent_confirm)

- "Someone already lives here."  (chat message, line 358)

*When:* Licenses An officer takes a trader's license away; their stalls close.

- "Officers only."  (text, line 369)
- "They're not in the city right now."  (text, line 370)
- "Business license revoked"  (text, line 374)
- "[Civil Workers' Union] Your business license has been revoked. Your stalls are closed."  (chat message, line 375)

*When:* part of: revoke license

- "'s license is revoked."  (text, line 376)
- "They had no license; their stalls are closed."  (text, line 376)

## rearranging a rebel camp (sv_livingcity_campmove.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_campmove.lua`


*When:* (set down on the floor, never in it)

- "[Camp] Set down. (It'll be here next time too.)"  (chat message, line 115)

*When:* part of: camp pick up

- "Moving it"  (on-screen notice, line 135)
- "It goes where you look. Let go of E to set it down; R turns it."  (on-screen notice, line 135)

## characters and permanent death (sv_livingcity_character.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_character.lua`


*When:* part of: assign

- "[Living City] You are %s, citizen %s."  (message, line 127)

*When:* a character who hasn't been chosen yet gets to choose

- "[Living City] You are %s, citizen %s. If you die, that person is gone."  (message, line 151)

*When:* Told once they're back on their feet.

- "[Living City] %s is dead. You are %s, citizen %s. You start over with nothing."  (message, line 215)

*When:* (lcEndOfLife: an ending that is final whatever the setting, like a stalker stepping into the light)

- "Permanent death is off here: you come back as yourself."  (text, line 227)
- "[Living City] You died in build mode, so you keep this character. C > Help > Build mode to leave build mode and play for real."  (chat message, line 231)
- "Build mode: you keep this character."  (text, line 232)

*When:* someone dying

- "The infestation doesn't let go. You come back as you were."  (text, line 236)
- "[Living City] You died in custody. That doesn't change who you are, or how long you're in for."  (chat message, line 240)
- "Died in custody: you're still you, and still serving your time."  (text, line 241)

*When:* a close call, unless this one is the end of them (sv_livingcity_progress.lua)

- "A close call: %d left."  (message, line 247)
- "A close call: the last one."  (text, line 247)

*When:* Whole words that are never fine in a name.

- "Choose a realistic name for a person living in this city and era: an ordinary name, first and last if you like. No celebrities, characters from games, films or shows, memes or joke names."  (text, line 299)

*When:* Returns true, the cleaned-up name; or false, why not.

- "Names are between 3 and 26 characters long."  (text, line 311)
- "Names use letters only: no numbers or symbols."  (text, line 312)
- "A name is one to three words: a first name, and a surname if you like."  (text, line 315)

*When:* part of: validate character name

- "Each part of your name needs at least two letters."  (text, line 318)
- "That doesn't read like a real name."  (text, line 319)
- "That doesn't read like a real name."  (text, line 320)
- "That name isn't allowed. {REMINDER}"  (text, line 322)
- "That name looks like a celebrity, a character or a joke. {REMINDER}"  (text, line 328)

*When:* opts.intake: the registration form at a Civil Intake terminal (sv_livingcity_intake.lua): nothing filled in for you, a description to give, no "keep what I was given". opts.asked: they asked for it (!character), so say why not if it's not now.

- "[Civil Intake] Who you are goes on your registration form, at the Civil Intake terminal."  (chat message, line 372)

*When:* the game answering something done in a window (lcc_submit)

- "One moment."  (text, line 392)

*When:* a new name and face is no way out of trouble

- "Not while you're wanted or in custody."  (text, line 396)

*When:* the game answering something done in a window (lcc_submit)

- "Choose one of the faces shown."  (text, line 403)
- "Someone in the city already has that name."  (text, line 406)
- "That person can't come back. Choose another name."  (text, line 407)
- "[Living City] You are %s, citizen %s."  (message, line 420)

*When:* the console command lc_setname

- "[Living City] Staff changed your name to {name}."  (chat message, line 460)

## checkpoints, turrets, and holding the infestation back (sv_livingcity_checkpoints.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_checkpoints.lua`


*When:* part of: containment breach

- "[City] Containment failure{or}! The infected are breaking out."  (chat message, line 287)
- "Dispatch: containment breach{or}. All Civil Protection units, hold the line."  (text, line 289)

*When:* part of: deploy turret

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

*When:* part of: pack turret

- "Civil Protection units only."  (text, line 445)
- "Look at a turret a Civil Protection unit put up."  (text, line 446)
- "Get closer."  (text, line 447)
- "You fold the turret up and take it with you."  (text, line 450)

*When:* Officers put up a power bank: on the wall they're looking at.

- "Officers put up power banks (Division Leader and up). Any Civil Protection unit can deploy turrets at one."  (text, line 456)
- "You've one up already. Take it down first (the actions menu, looking at it)."  (text, line 458)

*When:* part of: deploy power bank

- "Look at a wall, close by."  (text, line 462)
- "It won't go up."  (text, line 465)
- "Power bank up. Turrets and forcefields near it run off it now."  (text, line 477)

*When:* part of: pack power bank

- "That one's the city's, not yours to take down."  (text, line 481)
- "Officers only."  (text, line 482)
- "Get closer."  (text, line 483)
- "You take the power bank down."  (text, line 487)

*When:* E on a bank: units read what it's powering. (The multitool's primary fire shorts it out.)

- "It spits sparks. Shorted out."  (text, line 495)
- "Power bank: %s. Feeding %d turret%s and %d forcefield%s (it can feed %d)."  (message, line 497)
- "DEAD (no power)"  (message, line 497)

*When:* part of: use power bank

- "It hums. A Combine power bank."  (text, line 500)
- "Dead. No power."  (text, line 500)

*When:* A multitool: eight seconds, and it's dead for two minutes, with everything on its cables.

- "You need a multitool."  (text, line 505)
- "Look at a power bank."  (text, line 506)
- "It's already dead."  (text, line 507)
- "Shorting the power bank..."  (progress bar, line 508)
- "You pull your hands back."  (text, line 509)

*When:* part of: forcefield break

- "A forcefield is broken"  (on-screen notice, line 602)
- "The forcefield {where} is broken. E on it to repair it (ten seconds, paid)."  (on-screen notice, line 602)
- "[CP net] The forcefield {where} is broken. Maintenance has been told."  (chat message, line 604)

*When:* part of: forcefield repaired

- "Forcefield repaired"  (text, line 617)
- "Forcefield repaired"  (on-screen notice, line 618)
- "It hums back up. 15 credits."  (on-screen notice, line 618)

*When:* (the city's maintenance crews normally get there first: the task at the end)

- "[CP net] City crews have repaired the forcefield {GetPos}."  (chat message, line 688)

*When:* E on a broken one: a Maintenance Technician repairs it.

- "It's broken: sparks and a dead hum. A Maintenance Technician could fix it."  (text, line 710)
- "Repairing the forcefield..."  (progress bar, line 712)
- "You leave it half done."  (text, line 713)

*When:* The city's own maintenance crews walk out and repair a broken forcefield (after the players have had their chance); the timer above is only for a city with no crew to send.

- "repairing a forcefield"  (label, line 722)

*When:* part of: find

- "repairing a forcefield"  (what someone is doing, line 737)

## Half-Life: Alyx-style Combine models (sv_livingcity_combinemodels.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_combinemodels.lua`


*When:* the console command lc_combine_models_list

- "%-14s player: %-50s npc: %s"  (message, line 130)
- "(Half-Life 2's)"  (message, line 130)
- "(Half-Life 2's)"  (message, line 130)

## conduct (anti-RDM and anti-combat-logging) (sv_livingcity_conduct.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_conduct.lua`


*When:* part of: tell admins

- "[Conduct] {msg}"  (chat message, line 53)

*When:* part of: conduct summary

- "strikes {StrikeCount}"  (text, line 89)

*When:* part of: add strike

- "%s received strike %d: %s"  (message, line 98)
- "[Conduct] Strike %d of %d: %s"  (message, line 99)
- "KICK {Who} after {n} strikes"  (text, line 103)

*When:* a timer (regularly)

- "Repeated rule violations (random deathmatch / combat logging)"  (text, line 104)

*When:* part of: add strike

- "Conduct violation: {reason}"  (text, line 106)

*When:* part of: judge kill

- "server rule"  (text, line 176)
- "self defense"  (text, line 178)
- "killed another Civil Protection unit"  (text, line 186)
- "no roleplay reason found"  (text, line 188)

*When:* someone dying

- "KILL %s -> %s with %s at %du: %s (%s)"  (message, line 201)
- "killed %s with no roleplay reason (%s, %du)"  (message, line 206)
- "[Conduct] That kill has been flagged for staff. C > Help > Ask staff for help if there's more to it."  (chat message, line 207)

*When:* Combat logging

- "[Conduct] You can't do that right now."  (chat message, line 218)

*When:* someone leaving

- "%s disconnected %s. It'll be dealt with if they return."  (message, line 254)

*When:* a timer (regularly)

- "[Conduct] You left the server {why}. That counts against you."  (chat message, line 265)
- "disconnected {why}"  (text, line 266)
- "Evading arrest"  (text, line 268)

*When:* Chat and admin commands

- "[Conduct] Please wait a moment before reporting again."  (chat message, line 282)

*When:* typing in chat

- "Report from %s: %s"  (message, line 287)
- "[Conduct] Sent to staff{or}"  (chat message, line 288)

*When:* the console command lc_conduct

- "Usage: lc_conduct <name>"  (text, line 296)
- "%s has %d active strike(s)."  (message, line 298)

*When:* the console command lc_pardon

- "PARDON {target} by {or}"  (text, line 315)
- "[Conduct] Your strikes have been cleared."  (chat message, line 316)

## supply drops, radio jammers (sv_livingcity_convoy.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_convoy.lua`


*When:* part of: start supply drop

- "nowhere to put it"  (text, line 217)
- "[CP net] A supply {or}{where}. Guard the drop until it moves on. Directive on your board (F3)."  (chat message, line 233)
- "A Combine supply {or}{where}. Guns, ammunition, medicine. Lightly guarded."  (text, line 237)

*When:* part of: end supply drop

- "supply drop secured"  (text, line 285)
- "supply drop secured"  (text, line 286)
- "[CP net] The convoy moves on with %d of %d loads. Drop secured."  (message, line 290)
- "[City] A Union supply drop was looted. Anyone with information is to report it to Civil Protection."  (chat message, line 294)
- "The supply drop's empty. Good work."  (text, line 296)

*When:* E on the crate: take a load.

- "Empty, and sealed."  (text, line 316)
- "[CP net] Union supplies. Guard them until the convoy moves on."  (text, line 317)
- "You're busy."  (text, line 318)
- "Cleaned out."  (text, line 319)

*When:* part of: loot supply

- "Prying a load out of the crate... keep still"  (progress bar, line 322)
- "You leave it."  (text, line 323)

*When:* part of: done

- "Someone beat you to it."  (chat message, line 329)
- "Taken from the supply drop: {got}."  (chat message, line 338)
- "Looting Union supplies"  (text, line 341)
- "[Civil Protection] A Civil Protection unit saw you at the crate."  (chat message, line 342)
- "[CP net] The supply drop has been emptied."  (chat message, line 348)

*When:* caught at it

- "[Civil Protection] Caught with your hands in the crate."  (chat message, line 452)
- "Looting Union supplies"  (text, line 453)

*When:* part of: guard step

- "[Overwatch soldier] "Restricted supply point. Step away from the crates.""  (chat message, line 463)
- "[Overwatch soldier] "Final warning. Step away from the crates.""  (chat message, line 464)
- "[Overwatch soldier] "Noncompliance at the supply point." You're wanted."  (chat message, line 466)
- "Loitering at a Union supply drop"  (text, line 467)

*When:* Set one down from your pockets.

- "Civil Protection units don't jam their own radios."  (text, line 527)
- "You don't have a jammer."  (text, line 528)

*When:* part of: place jammer

- "[Jammer] It hisses into life. %d seconds of static for every Civil Protection unit radio within reach."  (message, line 540)
- "Operating a jamming device"  (text, line 542)
- "[Civil Protection] A Civil Protection unit saw you set it down."  (chat message, line 543)

*When:* A unit smashes it (E), or it runs out.

- "It hisses. Better not to touch it."  (text, line 552)
- "jammer destroyed"  (text, line 555)
- "[CP net] Jammer destroyed. Radio's clear."  (chat message, line 556)

## Civil Protection's toolset (sv_livingcity_cp.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_cp.lua`


*When:* part of: name of

- "Citizen {alias}"  (text, line 128)

*When:* part of: add record note

- "No such record."  (text, line 167)
- "Write something."  (text, line 169)

*When:* The city writes the record as things happen.

- "Wanted: {or}"  (text, line 177)
- "Custody, %d min: %s"  (message, line 181)

*When:* the game's living city searched moment

- "Contraband: {names}"  (text, line 193)

*When:* the game's living city escaped moment

- "Escaped custody"  (text, line 197)

*When:* Loyalty points: units award or deduct Civil Standing.

- "Civil Protection units only."  (text, line 206)
- "They're not in the city right now."  (text, line 207)
- "Not on yourself."  (text, line 208)
- "Nothing to change."  (text, line 211)

*When:* part of: adjust loyalty

- "\|{CurTime}"  (text, line 212)
- "You've already adjusted their points. Again in %ds."  (message, line 214)
- "loyalty points awarded by"  (text, line 217)
- "loyalty points deducted by"  (text, line 217)
- "Loyalty points %+d"  (message, line 219)
- "%s: %+d loyalty points."  (message, line 221)

*When:* part of: add bolo

- "Civil Protection units only."  (text, line 261)
- "Say what to look out for."  (text, line 263)

*When:* one every half minute (each one is a call and a sound for every unit)

- "The net's still busy with your last one. %d seconds."  (message, line 266)

*When:* part of: add bolo

- "[CP net] BOLO from %s: %s%s (%d min)"  (message, line 280)

*When:* part of: clear bolo

- "Civil Protection units only."  (text, line 288)
- "[CP net] BOLO cancelled by %s: %s"  (message, line 295)
- "No such BOLO."  (text, line 299)

*When:* part of: open records

- "The records terminal is off on this server."  (chat message, line 366)
- "[Records] Biosignal not recognised. Access denied."  (chat message, line 369)
- "Civil Protection only."  (chat message, line 371)

*When:* the game answering something done in a window (lc_records_do)

- "[Records] {msg}"  (chat message, line 411)
- "[Records] {msg}"  (chat message, line 411)

*When:* part of: set hands up

- "[Living City] Hands up. (F1 > Lower my hands.)"  (chat message, line 429)

*When:* Can this person tie that one up? ok, or false and why.

- "Zip ties are off on this server."  (text, line 451)
- "Look at someone, up close."  (text, line 452)
- "Not yourself."  (text, line 453)
- "Your hands are tied."  (text, line 454)
- "Their hands are already tied."  (text, line 455)
- "They're already in custody."  (text, line 456)
- "Get closer."  (text, line 457)

*When:* part of: can tie

- "You need zip ties."  (text, line 458)
- "They'd fight you off. Hands up, down, stopped by a Civil Protection unit, or from behind."  (text, line 462)

*When:* part of: tie player

- "[Living City] Your hands are tied. You can't use anything. F1 > Work at the ties, when nobody's looking."  (chat message, line 480)
- "Tied. Looking at them, F1: drag them along, or cut the ties."  (chat message, line 481)

*When:* part of: start tie

- "[Living City] Someone is tying your hands."  (chat message, line 515)
- "Tying their hands..."  (progress bar, line 516)
- "You let go."  (text, line 517)

*When:* part of: done

- "They got away from you."  (chat message, line 520)

*When:* part of: start untie

- "Look at someone whose hands are tied, up close."  (text, line 530)
- "Your own hands are tied."  (text, line 531)
- "[Living City] A Civil Protection unit cuts your ties."  (chat message, line 534)
- "Cutting the ties..."  (progress bar, line 537)
- "You stop."  (text, line 538)

*When:* part of: done

- "[Living City] Someone cuts your ties. You're free."  (chat message, line 542)

*When:* part of: start struggle

- "Your hands aren't tied."  (text, line 560)
- "Not while they've got hold of you."  (text, line 561)
- "Working at the ties..."  (progress bar, line 562)
- "You stop working at the ties."  (text, line 563)

*When:* part of: done

- "[Living City] They see you working at the ties, and pull them tighter."  (chat message, line 568)
- "[Living City] The plastic gives. Your hands are free."  (chat message, line 572)

*When:* !drag on someone tied: walk them along. Returns nil when it's not about a tied person.

- "You let go of them."  (chat message, line 582)

*When:* part of: try escort

- "Your hands are tied."  (text, line 588)
- "You take them by the arm. (F1 > Drag them along again to let go.)"  (chat message, line 590)
- "[Living City] You're being walked along."  (chat message, line 591)
- "Things are back to normal. Ordinary stops, ordinary days."  (text, line 661)
- "Back to ordinary patrols."  (text, line 661)
- "More stop-and-searches on the street. Keep your papers ready and nothing on you you'd want found."  (text, line 662)
- "Half as many stops again. Keep an eye out."  (text, line 663)
- "Civil Protection units may use lethal force as they see fit. Twice as many stops. Get indoors and stay out of sight."  (text, line 664)
- "Twice the stops. Lethal force at your discretion: make it count."  (text, line 665)

*When:* part of: announce socio

- "[Overwatch] "{subtitle}""  (chat message, line 703)
- "[Overwatch] Sociostability: %s.%s"  (message, line 706)

*When:* part of: set socio

- "Officers only (Division Leader and up, the Administrator)."  (text, line 727)
- "Sociostability is back to what the city makes it."  (text, line 732)
- "Green, yellow, red, or auto."  (text, line 734)

*When:* (announced to the whole city each time: not more than once every half minute)

- "You've only just set it. %d seconds."  (message, line 737)
- "Sociostability set to %s for %d minutes."  (message, line 743)

*When:* Requests

- "Requests are off on this server."  (text, line 757)
- "You're a Civil Protection unit. Use the radio, or !backup."  (text, line 759)
- "You need a request device (the Commissary sells them)."  (text, line 760)
- "Say what's wrong: /request <what's wrong>"  (text, line 761)

*When:* part of: cprequest

- "The request device crackles. Nothing gets through: something nearby is jamming it."  (text, line 762)
- "The device is still recharging (%ds)."  (message, line 765)
- "[Request] Sent. Civil Protection has your location."  (chat message, line 797)
- "[Request] Sent. A Civil Protection unit is on the way."  (text, line 798)
- "[Request] Sent. Nobody answers."  (text, line 798)
- "request from %s: %s"  (message, line 799)

*When:* Play a line and say it. word: the line's short word, its number, or its words.

- "Only Civil Protection units have the mask's voice."  (text, line 835)
- "No such line. !vo opens the list."  (text, line 838)

*When:* part of: vo

- "Only Civil Protection units have the mask's voice."  (chat message, line 889)

*When:* part of: socio

- "[Overwatch] Sociostability: %s%s"  (message, line 901)
- "(set by %s, %d min left)"  (message, line 902)

*When:* part of: issue duty allocation

- "a ration packet"  (text, line 956)
- "a ration packet (your pockets are full: collect it from a dispenser)"  (text, line 956)
- "credits in ration coupons"  (text, line 958)
- "[Civil Protection] Duty allocation issued: {got}."  (chat message, line 959)

## the Civil Protection Commissary (units' supplies) (sv_livingcity_cpsupply.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_cpsupply.lua`


*When:* ammunition for what they carry

- "{load} rounds"  (text, line 66)

*When:* armour

- "armour, to {want}"  (text, line 74)

*When:* the ration allocation

- "a ration packet"  (text, line 84)

*When:* part of: use cpsupply

- "[CP Commissary] Restricted: Civil Protection only."  (chat message, line 95)
- "[CP Commissary] The screen's dark. No power."  (chat message, line 99)
- "[CP Commissary] Your next issue is in %d seconds. The Civil Protection unit counter is open."  (message, line 104)
- "[CP Commissary] Issued: {got}."  (chat message, line 110)
- "[CP Commissary] You're fully supplied. The Civil Protection unit counter is open."  (chat message, line 112)

## making things, grenades, the arms trade, and getting people out (sv_livingcity_crafting.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_crafting.lua`


*When:* Crafting

- "You need {n} {name}."  (text, line 61)
- "Not with someone watching. Get out of sight first."  (text, line 63)

*When:* part of: craft

- "That's the lab's work: the Resistance's scientist makes it. Everyone else buys it at the black market."  (text, line 70)
- "[CP Commissary] Visit a Civil Protection Commissary to be issued supplies."  (text, line 73)
- "You're busy."  (text, line 74)
- "Making {name}... keep still"  (progress bar, line 78)
- "You put it down, half finished."  (text, line 79)

*When:* part of: done

- "Made: {name}."  (chat message, line 86)
- "Manufacturing weapons"  (text, line 88)
- "Manufacturing contraband"  (text, line 88)
- "[Civil Protection] A Civil Protection unit saw what you were making."  (chat message, line 89)

*When:* Using things

- "You're not hurt."  (text, line 127)

*When:* part of: arms use

- "You can't wear any more."  (text, line 138)
- "You've no powered vest on to charge."  (text, line 144)
- "Your vest is fully charged."  (text, line 145)
- "You've already got one in your hand."  (text, line 156)
- "Brandishing a weapon"  (text, line 161)

*When:* part of: throw grenade

- "Not with your hands cuffed."  (text, line 314)

*When:* The Grenades weapon asks for one of a kind

- "None left."  (text, line 360)

*When:* A unit's issued grenades are Combine issue: kept, thrown, or handed to another unit; never sold, dropped, stashed or passed to anyone else (they came back free with every respawn).

- "That's Combine issue: it stays with you (or another unit)."  (text, line 385)

*When:* Passing things on (and smuggling them into a cell)

- "Look at the person you want to give it to, up close."  (text, line 412)
- "Your papers stay with you. (Show them instead: Use.)"  (text, line 415)

*When:* part of: give to

- "They can't carry any more."  (text, line 417)
- "Smuggling contraband into custody"  (text, line 422)
- "[Civil Protection] A guard saw you pass something through the bars. It's confiscated, and so is your freedom."  (chat message, line 423)
- "You hand over: {name}."  (chat message, line 428)
- "slips you: {name}.{or}"  (chat message, line 429)

*When:* typing in chat

- "You don't have anything like that."  (chat message, line 443)

## what custody costs the worst anticitizens (sv_livingcity_custody.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_custody.lua`


*When:* Interrogation

- "Who are your contacts?"  (text, line 70)
- "Where do they meet?"  (text, line 70)
- "Who gave you the weapon?"  (text, line 70)
- "Where is the hideout?"  (text, line 71)
- "Names. Give me names."  (text, line 71)
- "Who else knows?"  (text, line 71)

*When:* part of: start interrogation

- "[Interrogation] A Civil Protection unit steps into your cell and switches on his baton. "You will answer my questions." (Talk, and it stops: the choice is on your screen. Or don't.)"  (chat message, line 118)
- "[Interrogation] "If you comply, I will grant you {COOP_REWARD} social credits.""  (chat message, line 119)

*When:* Give them what they want: a hideout, marked for every unit.

- "Nobody's asking."  (text, line 128)

*When:* part of: interrogation talk

- "[CP net] A prisoner has talked: a Resistance hideout {where}."  (chat message, line 139)
- "cooperated under interrogation"  (text, line 146)

*When:* the cell hears about it

- "talked in custody. Don't trust them."  (text, line 150)
- "[Interrogation] You tell them{or}. The Civil Protection unit nods, and leaves."  (text, line 152)

*When:* part of: interrogation tick

- "[Interrogation] "We'll talk again." The Civil Protection unit leaves. You said nothing."  (text, line 161)
- "said nothing under interrogation"  (text, line 162)

*When:* Broken feet: no running

- "[Custody] They hold you down and break your feet. You won't be running for %d minutes. Not after release, not after anything."  (message, line 188)

*When:* part of: make stalker

- "[Custody] You come to, standing. Your body moves when they tell it to, not when you do. You are a stalker now: Combine property. You can't run, fight or speak, and you'll work. There is no way out of it but death."  (chat message, line 268)
- "Combine property"  (on-screen notice, line 269)
- "You are a stalker now. There is no way out of it but death. Your work is on your board (F3)."  (on-screen notice, line 269)
- "[City] An anticitizen has been repurposed. Citizens are reminded that cooperation is mandatory."  (chat message, line 273)

*When:* part of: stalker scene

- "[Custody] The cell door opens. Two Civil Protection units come in, batons out. They aren't here to ask questions."  (chat message, line 297)
- "They've come for you"  (on-screen notice, line 298)
- "Two units, batons out. You're not being released."  (on-screen notice, line 298)

*When:* a timer (regularly)

- "[Custody] Everything goes black."  (chat message, line 310)

*When:* part of: free stalker

- "[City] The city has had its use of you. You're let back onto the streets, on probation."  (chat message, line 329)

*When:* (superadmin) let someone off being a stalker: lc_unstalker <part of a name>

- "[City] An administrator has let you off being a stalker."  (text, line 340)
- "[Living City] {Nick} is no longer a stalker."  (chat message, line 341)

*When:* nor talk to anyone (E on a person does nothing: a stalker's work is the only thing it does) (asked first by every E-on-someone handler: sv_livingcity.lua, the rebels', Grigori's, the lab's)

- "[Stalker] You try to speak. Only a scream comes out: they left you a voice, not words."  (chat message, line 363)

*When:* a timer (regularly)

- "[City] The stalker that was you is gone. You come back as a citizen, on probation."  (text, line 397)

## saved layout (sv_livingcity_data.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_data.lua`


*When:* part of: restore backup

- "No such backup. lc_backups lists them."  (text, line 179)
- "That backup can't be read."  (text, line 181)

*When:* the console command lc_reload

- "[Living City] Reloaded layout: %d points, %d path nodes, %d zones, %d tagged doors."  (message, line 497)

*When:* the console command lc_backup

- "[Living City] Backed up the layout as {name}."  (text, line 507)
- "[Living City] Nothing to back up yet."  (text, line 507)

*When:* the console command lc_backups

- "[Living City] Layout: data/%s. %d backups in data/%s/:"  (message, line 513)
- "Restore one with lc_restore <number>. What's there now is backed up first."  (text, line 515)

*When:* the console command lc_restore

- "[Living City] Restored {what}."  (text, line 521)
- "[Living City] {what}"  (text, line 521)

*When:* the console command lc_autolink

- "[Living City] Made %d new links.%s"  (message, line 536)
- "%d nodes still have no links (shown in red)."  (message, line 537)

*When:* the console command lc_goto_layout

- "[Living City] None of those on this map."  (chat message, line 571)
- "[Living City] %s %d of %d. (You're in noclip; it's easy to land inside things.)"  (message, line 576)

*When:* the game answering something done in a window (lc_setting)

- "%s set %s to %s"  (message, line 613)

## debugging (sv_livingcity_debug.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_debug.lua`


*When:* Server-side Lua errors (hook exists on current Garry's Mod builds)

- "lua %s error: %s (%s)"  (message, line 36)

*When:* part of: settings

- "= {GetString}"  (text, line 73)

*When:* part of: build report

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
- "chasing %s at %.0fu"  (message, line 210)
- "%-8s %-16s hp %3d recov %d err %d hop %s/%s pos %s%s%s%s"  (message, line 213)
- "beat {routeGroup}"  (text, line 217)
- "line {line} slot {slotIndex}"  (text, line 218)
- "heading to line {lineHeading}"  (text, line 218)
- "by role: {out}{or}"  (text, line 225)
- "stuck: %d moved on a step, %d far trips given up%s"  (message, line 229)
- "routes: %s, %d trips not started (unreachable), %d places skipped as hard to reach"  (message, line 234)
- "%d planned over the nodegraph, %d short enough to walk direct"  (message, line 235)
- "no nodegraph links"  (message, line 235)
- "route repairs: %d legs walked in single steps, %d links found unwalkable (%d avoided right now), %d trips re-planned around them"  (message, line 238)
- "main loop: avg %.2f ms, last %.2f ms, worst %.2f ms over %d ticks"  (message, line 246)
- "server tick interval %.4f, entity count %d"  (message, line 248)
- "whole server frame (engine AI, physics, networking): avg %.2f ms, worst %.2f ms, %d of %d ticks late (%.1f%%), a tick should take %.1f ms"  (message, line 251)
- "entities by class: {top}"  (text, line 264)
- "NPCs on the map (all of them, Living City's and not): %d"  (message, line 267)
- "asleep (far from everyone, engine AI off; lc_npc_sleep %s): %d now; %d times put to sleep, %d woken, %d route stops walked out of sight"  (message, line 270)
- "%s [%s] step %d/%d (%s) %ds left: %s"  (message, line 281)
- "active %d \| violent cap %d"  (message, line 286)
- "prisoners: {prisoners} \| detained on the street: {held}"  (text, line 293)
- "stops in progress: {stops} \| next event: {_}"  (text, line 296)
- "disguise {GetNW2String}"  (text, line 304)
- "alias {GetNW2String}"  (text, line 305)
- "radio {GetNW2String}"  (text, line 306)
- "contraband {illegal}"  (text, line 307)
- "alert %d (heat %d, %d soldiers after them)"  (message, line 309)
- "running check: {pl}"  (text, line 311)
- "(rebel territory)"  (message, line 313)
- "%s \| %s \| job %s \| block %s \| cp %s \| wanted %s \| hunger %d thirst %d \| credits %s standing %s%s%s"  (message, line 314)
- "Recent log (newest last)"  (text, line 324)

## doors (sv_livingcity_doors.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_doors.lua`


*When:* part of: say

- "[Living City] {msg}"  (chat message, line 42)

*When:* Editor helpers: inspect and test

- "%s (map id %s)"  (message, line 463)
- "none: spawned, can't be tagged"  (message, line 463)

*When:* part of: door info

- "A prison door, automatically: it's by a cell or the release point, or in the prison area. Locked to all but Civil Protection units, even in a blackout (tag it to override)"  (text, line 468)
- "Locked automatically: it's in a Combine-only area. Its lock goes dead in a blackout (tag it to override)"  (text, line 470)
- "NPCs treat it as a door: {lines}{or}"  (text, line 474)

*When:* the console command lc_unlockdoors

- "Unlocked {n} doors (locked-tagged doors left alone)."  (chat message, line 504)

*When:* the console command lc_opendoors

- "Opened {n} doors. They will stay open."  (chat message, line 557)

## the Combine's dropship (sv_livingcity_dropship.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_dropship.lua`


*When:* The flight: in from afar to a point over the spot, down, a while there, up, and away. above: how high over the ground the ship's origin hovers.

- "there's a roof over it, not open sky"  (text, line 60)
- "not enough open sky over it"  (text, line 65)

*When:* part of: plan

- "no clear way in over the rooftops"  (text, line 79)

*When:* Where a carried container hangs: in the ship's claws. The container model is drawn in the ship's own frame (Half-Life 2 puts it at the ship's origin, at the ship's angles, and parents it there), so it goes exactly where the ship is, tilting with it. (It used to be hung a further body-length down, and dangled about fifteen feet under the ship.)

- "nowhere to go"  (text, line 108)

*When:* part of: fly dropship

- "no dropship model on this server"  (text, line 109)
- "the sky's busy"  (text, line 110)
- "no dropship"  (text, line 112)

## economy and social credit (sv_livingcity_economy.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_economy.lua`


*When:* part of: flush standing

- "(it can't go any lower)"  (text, line 73)
- "(it can't go any higher)"  (text, line 74)
- "[Civil Standing] %+d%s: %s"  (message, line 75)
- "[Civil Standing] You are now classified: {name}."  (chat message, line 78)

*When:* What earns and costs you

- "Community service"  (text, line 121)
- "shift complete"  (text, line 123)

*When:* the game's living city quest complete moment

- "Union shift completed"  (text, line 124)
- "paid quietly"  (text, line 126)

*When:* the game's living city escaped moment

- "Escaped custody"  (text, line 140)

*When:* Serving your time pays back part of what you owe: a quarter of the deficit plus 100, and more if you gave yourself up. Never past zero.

- "Turned yourself in and served your time"  (text, line 152)
- "Served your time"  (text, line 152)

*When:* the game's living city strike moment

- "Conduct violation"  (text, line 154)

*When:* (what an offence costs in standing; most are 25. A shot at a scanner is a little, wrecking one is 50)

- "Destroying city property"  (text, line 156)
- "Damaging city property"  (text, line 156)
- "Out after curfew"  (text, line 158)
- "Reported anticitizen activity"  (text, line 160)

*When:* Where a unit's things are sold: the Civil Protection Commissary's counter (sv_livingcity_cpsupply.lua), never the Union's terminals; only a city with no Civil Protection Commissary sells them at the Union terminal.

- "The commissary is closed."  (text, line 197)

*When:* part of: can buy

- "The terminal doesn't recognize you. It doesn't recognize anything like you."  (text, line 198)
- "Civil Protection units only."  (text, line 199)
- "Issued at the Civil Protection Commissary, not here."  (text, line 200)
- "Not at your rank."  (text, line 202)
- "Requires {name} standing."  (text, line 205)
- "Not enough credits."  (text, line 206)

*When:* part of: buy

- "[Commissary] {why}"  (chat message, line 216)
- "[Commissary] Purchased: %s (%d credits)"  (message, line 231)

*When:* part of: open shop

- "[Commissary] The commissary is closed."  (chat message, line 237)
- "[Commissary] The terminal asks for a citizen number you don't have yet. Register at Civil Intake."  (chat message, line 239)
- "[Commissary] Find a Union Commissary terminal."  (chat message, line 242)

*When:* typing in chat

- "[Union] %d credits. Civil Standing %d (%s)."  (message, line 270)

*When:* the console command lc_givecredits

- "from staff"  (text, line 279)

*When:* the console command lc_setstanding

- "adjusted by staff"  (text, line 286)

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

*When:* part of: take

- "You were taken."  (chat message, line 264)

*When:* part of: spectator

- "You're out of it. Watch the rest."  (chat message, line 564)

*When:* part of: slaughter

- "The mingebags got you."  (text, line 573)

*When:* part of: hit

- "They're on you, all of them, in that pose. The mingebags got you."  (text, line 611)

*When:* part of: harpies

- "[Civil Protection] "All Civil Protection units, open fire! Take them down!""  (chat message, line 950)

*When:* the last two seconds: nobody's left

- "There's nowhere left. The mingebags got you."  (text, line 1044)

*When:* part of: bloom

- "You spin up into the sky and burst into sparkles. Watch the rest go."  (text, line 1208)

*When:* part of: convert

- "The skeletons got you. You're one of them now. Dance."  (chat message, line 1282)

*When:* part of: apply section

- "The skeletons claim everyone in the end. You're one of them now. Dance it out."  (text, line 1402)

*When:* the ride lasts the song, more or less, and then nobody ever gets off

- "The ride doesn't stop. It never stops."  (text, line 1571)

*When:* Engrish: what everyone says, the way the captain would say it.

- "%f[%a][Yy]our%f[%A]"  (text, line 1881)
- "%f[%a][Yy]ou're%f[%A]"  (text, line 1881)
- "you are"  (text, line 1881)
- "are belong"  (text, line 1881)
- "%f[%a]going to%f[%A]"  (text, line 1883)
- "on the way to"  (text, line 1883)

*When:* Partied too hard: down they go.

- "You partied too hard. Lights out."  (text, line 2211)

*When:* the music cuts: everyone left goes down

- "The music stops. So do you. You partied too hard."  (text, line 2285)

*When:* part of: burst

- "Your behind takes you all the way up, and you go off like a firework. Watch the rest go."  (text, line 2762)

*When:* (held there, not frozen: a frozen player can't even look about, and the rope's view is all about looking about; where they are is set every tick anyway)

- "A rope drops round your neck from above, and up you go. (You can still look about.)"  (chat message, line 3097)

*When:* Gone limp: still hanging there, looking on.

- "You stop kicking. You hang there, and watch the rest."  (chat message, line 3118)

*When:* part of: bite

- "Something huge comes up out of the dark water. That's the last you see."  (text, line 3294)

*When:* part of: icthy step

- "It comes over the edge of the stage at you, jaws first. That's the last you see."  (text, line 3309)

*When:* under the water: you hold your breath, then you drown

- "The water closes over your head. Somewhere above, Father Grigori hits the high note."  (text, line 3542)

*When:* the last note: whoever's still here goes, and Father Grigori last of all

- "The tide takes you, gently, at the very end."  (text, line 3669)
- "Father Grigori holds the last note, bows, and the flood takes its encore."  (text, line 3671)

*When:* part of: water

- "Father Grigori holds the last note, bows, and the flood takes its encore."  (chat message, line 3674)

*When:* part of: go to

- "[???] Time stops. A man in a blue suit is standing in front of you. He'd like a word, and your vote: 1 to let it happen, 2 to skip it."  (text, line 3764)
- "No song"  (on-screen notice, line 3773)
- "No song found for {id}: put {id}.mp3 in garrysmod/sound/livingcity/endings/ on the server (and sync FastDL). lc_endings shows what it finds."  (on-screen notice, line 3773)
- "[???] So be it. {say}"  (text, line 3778)
- "[???] The city resets. Everyone you were is still you."  (text, line 3786)

*When:* part of: trigger ending

- "No such ending."  (text, line 3793)
- "One's already under way."  (text, line 3794)
- "Secret endings are off."  (text, line 3795)
- "Not yet ({EndingCooldownLeft} minutes)."  (text, line 3796)

*When:* pcall

- "[???] %d to %d. Very well. He straightens his tie, and time starts again."  (message, line 3852)
- "[???] Silence. He takes that as a yes."  (text, line 3855)

*When:* Triggers Father Grigori eats the motherlode.

- "You'd break your teeth."  (text, line 3897)
- "You've nothing like that to eat."  (text, line 3898)
- "Not now."  (text, line 3899)
- "It doesn't go down. Not yet."  (text, line 3900)

*When:* part of: eat chip

- "** Father Grigori swallows a Combine data core whole. His eyes light up."  (chat message, line 3904)

*When:* For the admin

- "[Living City] {m}"  (chat message, line 3918)

*When:* the console command lc_endings

- "{song} is a low-quality copy ({hz} Hz: it plays, but sounds muffled); a better copy would sound much better"  (text, line 3926)
- "NO SONG FOUND (looking for {id}.mp3 in garrysmod/sound/{ROOT})"  (text, line 3928)

*When:* everything that's actually there, so a file in the wrong place shows

- "In sound/{ROOT}: {or}"  (text, line 3933)
- "The folder {d}/ holds {inside} file(s) that never play: move them up one level, straight into sound/{ROOT}"  (text, line 3938)

*When:* the console command lc_endings

- "never plays: name it for its ending (harpies.mp3, bus.mp3 ...)"  (text, line 3944)
- "isn't a sound the game plays (.mp3, .ogg or .wav)"  (text, line 3946)
- "Next one possible in {left} minutes (lc_ending_reset_cooldown)."  (text, line 3950)
- "One can happen now."  (text, line 3950)

*When:* the console command lc_ending

- "Ending triggered: {id}"  (text, line 3958)

*When:* the console command lc_ending_cancel

- "Ending cancelled. Time runs again."  (text, line 3963)
- "No ending on."  (text, line 3963)

*When:* the console command lc_ending_reset_cooldown

- "Secret ending cooldown cleared."  (text, line 3970)

*When:* Settings are saved, so a default changed since would never reach a server that ran the old one: anything still exactly at an old default moves to the new one (once; a value someone chose themselves is left alone).

- "harpies=2,shalom=2"  (text, line 3987)
- "harpies=4,shalom=2"  (text, line 3987)
- "3.5:bomb,14.7:screen,34:zig,126:move,174:justice,212:boom,224:end"  (text, line 3988)
- "3.5:bomb,9.5:screen,34:zig,126:move,174:justice,212:boom,224:end"  (text, line 3988)
- "2.2=CAPTAIN: What happen ?\|3.5=MECHANIC: Somebody set up us the bomb.\|6.5=OPERATOR: We get signal.\|9.5=CAPTAIN: What !\|12.5=OPERATOR: Main screen turn on.\|14.7=CAPTAIN: It's you !!\|16.4=CATS: How are you gentlemen !!\|18.4=CATS: All your base are belong to us.\|20.4=CATS: You are on the way to destruction.\|21.6=CAPTAIN: What you say !!\|23.0=CATS: You have no chance to survive make your time.\|26.0=CATS: Ha ha ha ha ....\|34=CAPTAIN: Take off every 'ZIG' !!\|126=CAPTAIN: Move 'ZIG'.\|174=CAPTAIN: For great justice."  (text, line 3989)
- "2.15=CAPTAIN: What happen ?\|3.55=MECHANIC: Somebody set up us the bomb.\|4.65=OPERATOR: We get signal.\|6.5=CAPTAIN: What !\|9.5=OPERATOR: Main screen turn on.\|11.7=CAPTAIN: It's you !!\|12.55=CATS: How are you gentlemen !!\|14.7=CATS: All your base are belong to us.\|18.45=CATS: You are on the way to destruction.\|20.6=CAPTAIN: What you say !!\|21.65=CATS: You have no chance to survive make your time.\|26.0=CATS: Ha ha ha ha ....\|34=CAPTAIN: Take off every 'ZIG' !!\|126=CAPTAIN: Move 'ZIG'.\|174=CAPTAIN: For great justice."  (text, line 3989)

## escorts through Combine doors (sv_livingcity_escort.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_escort.lua`


*When:* part of: radio

- "[CP net] {text}"  (chat message, line 60)

*When:* What a unit is called on the radio.

- "A Civil Protection unit"  (text, line 68)
- "Unit {EntIndex}"  (text, line 73)

*When:* Who can have one, and who can give one A Union worker, on a job.

- "Escorts are off on this server."  (text, line 96)
- "You're a Civil Protection unit. You open those doors yourself."  (text, line 98)
- "Not from in here."  (text, line 100)
- "Only Union workers get an escort: take a Union job from your board (F3)."  (text, line 101)
- "You need to be on a job: accept a shift from your board (F3) first."  (text, line 102)

*When:* part of: may have escort

- "Civil Protection doesn't escort wanted people."  (text, line 103)
- "Dispatch won't send anyone with you. ({CurTime} min)"  (text, line 105)

*When:* part of: dispatch

- "[Union] {npc} is coming to take over your escort. Stay where you are."  (chat message, line 245)
- ": copy, taking over the escort of {worker}."  (text, line 246)
- "[Union] {npc} is on the way to escort you. Wait for them."  (chat message, line 248)

*When:* Ask for one.

- "You've already got {or}."  (text, line 258)

*When:* part of: request escort

- "Escort requested: %s, Union %s, %s.%s"  (message, line 262)
- "(Actions menu: Civil Protection > Escort requests.)"  (message, line 263)
- "[Union] No Civil Protection unit's free right now. Dispatch has your request; wait for one."  (text, line 267)

*When:* Dismiss it yourself.

- "You haven't got an escort."  (text, line 273)
- "[CP net] {NameOf} has dismissed you."  (chat message, line 275)
- "[Union] You send your escort away.{or}"  (text, line 276)

*When:* A player unit takes it on (from an NPC unit, or a request nobody's answered).

- "Civil Protection units only."  (text, line 282)
- "Look at the worker, or pick them from Escort requests."  (text, line 283)
- "You're already escorting them."  (text, line 285)
- "They aren't on a job."  (text, line 288)

*When:* part of: take escort

- "Finish the escort you're on first."  (text, line 293)
- "[Union] {unit} is escorting you."  (chat message, line 301)
- "[CP net] You're escorting {worker}{or}"  (chat message, line 302)

*When:* A player unit hands it back: the next free unit takes over.

- ": handing off the escort of {worker}, {GetPos}."  (text, line 311)
- "handed off"  (text, line 311)
- "[CP net] You hand the escort back to dispatch."  (chat message, line 312)

*When:* part of: drop escort

- "You aren't escorting anyone."  (text, line 316)

*When:* part of: escort unattended

- "Worker unattended: nearest free Civil Protection unit, take over."  (text, line 330)
- "[Union] Your escort's been called away. Stay where you are: another Civil Protection unit is coming."  (chat message, line 331)

*When:* the game's living city can use cpdoor moment

- "[Union] {u} buzzes you through."  (chat message, line 381)

*When:* Someone slipped in behind the worker.

- "Unauthorized access"  (text, line 399)
- "%s: intruder through a Combine door %s, in pursuit."  (message, line 401)

*When:* part of: tailgated

- "someone followed you through a Combine door"  (text, line 403)
- "Under escort, let someone through a Combine door"  (text, line 404)
- "[Civil Protection] "Hold it!" A Civil Protection unit saw you slip through behind the worker."  (chat message, line 405)

*When:* A prisoner got out of a door the unit opened.

- "%s: prisoner out of a cell %s, returning them."  (message, line 415)

*When:* part of: prisoner out

- "a prisoner got out through a door your escort opened"  (text, line 420)
- "Under escort, had a cell door opened: a prisoner got out"  (text, line 421)
- "[Civil Protection] "Don't move!" The Civil Protection unit's seen you."  (chat message, line 422)

*When:* Twice on one job, and that's the last escort they get for a while.

- "Dispatch: no further escorts for {w}. Twice now."  (text, line 431)
- "[Union] Dispatch won't send anyone else with you. Get out of the restricted area."  (text, line 432)

*When:* part of: begin out

- "[Union] Your job's done. Your escort heads back to their beat."  (text, line 472)
- "[Union] "You're done. Out the way you came." Your escort heads back."  (text, line 476)
- "[CP net] {w}'s job is done: walk them out{or}"  (chat message, line 481)
- "[Union] "You're done here. This way." Your escort walks you out{or} Stay with them."  (chat message, line 485)

*When:* part of: finish out

- ": escort of {worker} complete."  (text, line 499)
- "[Union] "Move along." You're out, and your escort leaves you here."  (text, line 500)

*When:* part of: drive npc

- "[Union] {u}: "{or}""  (chat message, line 519)

*When:* too far from their escort for too long: on their own

- "you slipped your escort"  (text, line 530)
- ": {w} slipped their escort {wp}."  (text, line 531)
- "[Union] You left your escort behind. You're on your own in there."  (text, line 532)

*When:* wait for them

- "[Union] {u}: "Keep up.""  (chat message, line 554)

*When:* no release point: follow them out

- "[Union] Your escort leaves you to find your own way out."  (text, line 562)

*When:* part of: tick one

- "[Union] Your job's over. Dispatch cancels the escort request."  (text, line 594)
- ": escort of {w} interrupted, {GetPos}."  (text, line 603)
- "Civil Protection unit down"  (text, line 603)

*When:* called away (a crime nearby, someone shooting), or down

- "Dispatch: escort Civil Protection unit down"  (text, line 618)
- ": called away"  (text, line 618)
- ", {GetPos}."  (text, line 618)
- "Civil Protection unit down"  (text, line 619)
- "called away"  (text, line 619)

*When:* nobody with them

- "Dispatch: no Civil Protection unit free to take over the escort of {w}."  (text, line 636)
- "nobody came"  (text, line 637)
- "[Union] No Civil Protection unit came. You're on your own: leave the restricted area."  (text, line 637)

*When:* part of: tick one

- "[Union] No Civil Protection unit was free. Your escort request lapses; ask again later."  (text, line 640)

*When:* part of: recaptures

- "The Civil Protection unit marches you back to your cell."  (text, line 655)

*When:* someone leaving

- "Dispatch: escort Civil Protection unit off the net."  (text, line 682)
- "Civil Protection unit gone"  (text, line 682)

*When:* part of: escort command

- "Who? (!escort name, or Civil Protection > Escort requests in the actions menu.)"  (text, line 723)

## city events (sv_livingcity_events.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_events.lua`


*When:* morning exercise (sv_livingcity_exercise.lua)

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

*When:* Announcements What each PA line says, roughly, in plain words: the voice lines come from Half-Life 2 and aren't always clear, or are a loose fit for what's happening.

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

*When:* part of: minutes

- "about a minute"  (text, line 118)

*When:* What actually happens, for the person reading it.

- "The city is in unrest: more inspections and raids, and rations come slower. See !city."  (text, line 129)
- "Just the city talking. Nothing changes."  (text, line 131)

*When:* part of: rations

- "Rations are being handed out for {Minutes}. The lines move faster and citizens crowd them; keep order."  (text, line 134)
- "Rations are being handed out for {Minutes}. Lines move faster and you can collect again sooner. Stand at the front of a ration line to get yours (not if you're wanted)."  (text, line 135)

*When:* part of: sweep

- "Civil status inspections for {Minutes}. Stop and search citizens: Civil Protection units stop people far more often now."  (text, line 138)
- "Civil status inspections for {Minutes}. Civil Protection units stop and search people far more often and from further away. Anything illegal on you will be found: stash it, or stay out of sight."  (text, line 139)

*When:* part of: raid

- "a housing block"  (name, line 143)
- "Civil Protection units are searching {name}. Contraband found there is traced to its owner, who becomes wanted."  (name, line 144)
- "Civil Protection units are searching {name}{or} room by room. Anyone there gets frisked, contraband lying around is traced to whoever left it, and they become wanted. Stashes can be found too."  (text, line 146)

*When:* part of: curfew

- "A curfew in the daytime: a punishment for the unrest in the city."  (text, line 151)
- "It's about you: any Civil Protection unit who sees you knows you, and won't stop at a warning."  (text, line 152)
- "Curfew for {Minutes}. Get inside {or} within {grace} seconds."  (text, line 155)
- "Curfew for {Minutes}. After {grace} seconds, citizens still outside get three warnings from a Civil Protection unit, then they're wanted."  (text, line 157)
- "Curfew for {Minutes}. You have no room yet: wait it out at Civil Intake, or where you arrived. Civil Protection units leave new arrivals there alone."  (text, line 160)
- "Curfew for {Minutes}. Get inside {or} (your HUD points the way). You have {grace} seconds. After that, a Civil Protection unit who sees you outside warns you three times, then you're wanted. Running is allowed until then."  (text, line 162)

*When:* part of: lockdown

- "Lockdown for {Minutes}, and it's about you: any Civil Protection unit who sees you knows you, and won't stop at a warning. Get out of sight."  (text, line 168)
- "Lockdown for {Minutes}: a curfew with extra Civil Protection units out. After {grace} seconds, anyone outside gets three warnings, then they're wanted."  (text, line 170)
- "Lockdown for {Minutes}. You have no room yet: wait it out at Civil Intake, or where you arrived. Civil Protection units leave new arrivals there alone."  (text, line 173)
- "Lockdown for {Minutes}: a curfew, with extra Civil Protection units on the street. Get inside {or} within {grace} seconds. After that, Civil Protection units who see you outside warn you three times, then you're wanted."  (text, line 175)

*When:* part of: ended

- "The curfew is over. You can go out again."  (text, line 178)

*When:* part of: response

- "Overwatch has been sent in. Keep clear of any fighting."  (text, line 179)

*When:* part of: supply

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

*When:* and in chat, what it said and what it means

- "[{title}] "{says}""  (chat message, line 229)

*When:* part of: end event

- "[City] {was}"  (chat message, line 266)

*When:* pull idle citizens toward the lines right away

- "curfew or lockdown: gone home"  (text, line 303)

*When:* part of: start event

- "Event started: %s (%s min)"  (message, line 308)

*When:* part of: block name

- "Habitation Block %02d"  (text, line 350)

*When:* the one this is all about: no warnings, he knows you

- "[Civil Protection] "That's the one!" The Civil Protection unit knows you: this curfew is about you. You are wanted."  (chat message, line 414)
- "Wanted in connection with the unrest"  (text, line 415)

*When:* and he comes over: walking at the first warning, running after that

- "Civil Intake (you have no room yet)"  (text, line 428)
- "your residence"  (text, line 428)
- "[Civil Protection] Curfew is in effect. Return to %s. (Warning %d of %d)"  (message, line 432)

*When:* part of: enforce curfew

- "[Civil Protection] Curfew violation. You are now wanted."  (chat message, line 436)
- "Curfew violation"  (text, line 437)

*When:* part of: can think

- "Refusing a lawful order"  (text, line 575)

*When:* Commands

- "[Living City] Start the city first."  (chat message, line 647)
- "[Living City] Events: rations, sweep, curfew, lockdown, raid, supply, jog, drill, parade (those three need their points placed). Usage: lc_event curfew 5"  (chat message, line 649)
- "[Living City] Event started: {name}"  (chat message, line 651)

*When:* a unit sets off after someone causing a disturbance

- "Civil Protection is chasing someone {or}. Stay out of the way."  (chat message, line 682)

*When:* wanted: for running, evasion; for killing or attacking, capital malcompliance

- "citizen {GetNW2String}"  (text, line 689)
- "is wanted: {or}."  (chat message, line 691)
- "is wanted: {or}."  (chat message, line 693)

*When:* a long sentence: citizenship revoked

- "has been sentenced."  (chat message, line 699)

*When:* someone reports a crime: failing to report is conspiracy (said when people do report)

- "A citizen has reported something to Civil Protection."  (chat message, line 704)

## morning exercise (mandatory for citizens) (sv_livingcity_exercise.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_exercise.lua`

- "Morning jog"  (text, line 81)
- "Morning drill"  (text, line 81)
- "Morning parade"  (text, line 81)

*When:* part of: where

- "the assembly point"  (text, line 91)

*When:* The stick

- "Keep up, citizen."  (text, line 241)
- "Do it properly."  (text, line 241)
- "Louder, citizen. With feeling."  (text, line 241)
- "Exercise is mandatory."  (text, line 241)

*When:* on the jog, a shove on along the route: toward the next marker

- "[Civil Protection] A crack with the stick. {absent}"  (chat message, line 295)

*When:* part of: tell

- "[{or}] {msg}"  (chat message, line 391)

*When:* part of: setup drill

- "You lead the drill this morning. Stand at the front of the yard (the marker) facing the rows: every move you make (crouch, jump, spin, a step left, right, forward or back) is called out for them to copy, one every few seconds. Stand still and the instructor fills in."  (chat message, line 548)

*When:* part of: join

- "Late. It has been noted."  (chat message, line 652)

*When:* part of: start run

- "You're leading. Go."  (chat message, line 690)
- "Go! Keep jogging, and keep up with the pace marker."  (chat message, line 740)
- "Stay on your place (the ring) and copy every move. Mistakes are counted."  (chat message, line 741)
- "Here they come. Cheer! (/cheer, /salute, chant in chat, jump.) Enthusiasm is watched."  (chat message, line 742)
- "You didn't report. Get there now: {center}. Civil Protection units are looking for you."  (chat message, line 745)

*When:* part of: truants

- "[Civil Protection] Morning exercise is mandatory. Report to {center}. Now."  (chat message, line 767)

*When:* part of: jog think

- "You're falling behind the pace. Run."  (chat message, line 864)
- "That's not jogging. Pick it up."  (chat message, line 864)

*When:* The drill

- "Turn around, all the way!"  (text, line 885)
- "Step left!"  (text, line 885)
- "Step right!"  (text, line 886)
- "Step forward!"  (text, line 886)
- "Step back!"  (text, line 886)

*When:* part of: rope start

- "Skipping! Jump on every beat of the rope."  (chat message, line 946)

*When:* part of: drill think

- "The rope catches your ankles."  (text, line 1018)
- "Too slow."  (text, line 1040)
- "Wrong move."  (text, line 1041)

*When:* your own place, not someone else's

- "Back to your place."  (text, line 1049)

*When:* The parade

- "long live"  (text, line 1086)

*When:* part of: parade think

- "[Civil Protection] Show some enthusiasm, citizen."  (chat message, line 1162)

*When:* Afterwards

- "[Union] Exemplary citizens are served first: a hot breakfast, and coffee. You feel well fed."  (chat message, line 1254)

*When:* part of: breakfast

- "[Union] For citizens of good standing: breakfast."  (chat message, line 1257)
- "[Union] Rations are issued at the usual distribution. Breakfast is for citizens of good standing."  (chat message, line 1259)

*When:* standing: for doing it, and doing it well

- "You didn't finish."  (chat message, line 1273)

*When:* part of: exercise finish

- "Poor showing at the {kind}"  (text, line 1281)
- "Led the morning drill"  (text, line 1285)
- "Skipped morning exercise"  (text, line 1287)

*When:* What it means, for the person reading the announcement (sv_livingcity_events.lua).

- "the assembly point"  (text, line 1330)
- ": citizens report {where} within {secs} seconds. Civil Protection units are posted automatically; anyone shirking gets the stick."  (text, line 1333)
- "for citizens, {where}."  (text, line 1335)

*When:* part of: exercise means

- "Report to the start of the jogging route, {where}, within {secs} seconds (your HUD points the way). Then run it: keep jogging and keep up with the pace marker, or Civil Protection units along the route use the stick (which does speed you up)."  (text, line 1337)
- "Report to the exercise yard, {where}, within {secs} seconds. Take your place in the rows and copy every move (crouch, jump, spin, a step); jump on every beat when the rope comes out. Too many mistakes and you get the stick."  (text, line 1340)
- "Line the parade route, {where}, within {secs} seconds, and cheer the column as it passes: /cheer, /salute, chant in chat, jump. Your enthusiasm is on screen; let it drop as they pass and a Civil Protection unit sees to it."  (text, line 1343)

*When:* a timer (regularly)

- "You're well fed. Work goes better on a full stomach (+15% XP), and you mend slowly."  (chat message, line 1422)

*When:* For the admin

- "[Living City] {m}"  (chat message, line 1439)
- "Exercise stopped."  (text, line 1442)
- "No exercise on."  (text, line 1442)

*When:* the console command lc_exercise

- "Next morning exercise: {or}. Every {GetInt} morning(s), at dawn. lc_exercise <jog\|drill\|parade> starts one now."  (text, line 1447)
- "Start the city first."  (text, line 1452)
- "Place an exercise yard first (editor: Point: exercise yard)."  (text, line 1454)
- "Place a {or} first (two or more stops, in order)."  (text, line 1455)
- "Couldn't start it."  (text, line 1458)

## sv_livingcity_factions.lua (sv_livingcity_factions.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_factions.lua`


*When:* Anyone without a faction becomes a Citizen.

- "[Factions] {msg}"  (chat message, line 39)

*When:* part of: titles

- "Resistance {hunted}"  (text, line 85)

*When:* Returns ok, reason

- "No such faction."  (text, line 320)

*When:* (a stalker is bound even as a superadmin: only death, or lc_unstalker, ends it)

- "Whitelist only."  (text, line 325)

*When:* part of: can join faction

- "Civil Protection only takes citizens in good standing (%d or more). Yours is %d."  (message, line 331)
- "Requires %s in %s."  (message, line 337)
- "No such role."  (text, line 342)
- "Someone already holds that role."  (text, line 344)
- "Requires {name} in {name}."  (text, line 346)

*When:* part of: set faction

- "You are now {name}."  (chat message, line 369)

*When:* the game answering something done in a window (lcf_join)

- "Not while you're in custody."  (chat message, line 395)
- "Not while you're wanted or in a fight."  (chat message, line 396)
- "You can change faction again in {CurTime} seconds."  (chat message, line 398)

*When:* only ever to give back what they had (never to take more away)

- "Welcome back. You're still {name}."  (chat message, line 474)

*When:* a timer (regularly)

- "You can't be %s right now: %s You're %s for now; take it again from the faction menu (F4) when there's a place."  (message, line 479)
- "back to your rank"  (message, line 481)

*When:* XP The transhuman conditioning: the Overwatch ranks open, and whatever XP you've earned counts at once. There's no undoing it.

- "the conditioning"  (text, line 496)

*When:* part of: add xp

- "Promoted to {name}!{or}"  (chat message, line 515)
- "[%s] %s has been promoted to %s."  (message, line 520)
- "Demoted to {name}."  (chat message, line 524)

*When:* Admin commands

- "Player not found."  (text, line 642)

*When:* admin cmd

- "Factions: citizen, resistance, cp, ota, admin, zombie"  (text, line 649)
- "No such special role."  (text, line 651)
- "set to {name}."  (text, line 653)
- "Usage: lcf_setxp <name> <xp>"  (text, line 659)
- "now has {xp} XP in {name}."  (text, line 662)

*When:* part of: step

- "by staff"  (text, line 671)
- "is now {name}."  (text, line 672)

*When:* admin cmd

- "Usage: lcf_whitelist <name> <faction>"  (text, line 679)
- "whitelisted for"  (text, line 683)
- "removed from"  (text, line 683)

## Freq 7, the Resistance's pirate broadcast (sv_livingcity_freq7.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_freq7.lua`


*When:* part of: freq7 jam

- "Dispatch: pirate signal located on %.1f. Jamming."  (message, line 156)

*When:* the console command lc_freq7_status

- "[Living City] Freq 7: %s %.1f; on now: %s (%s); found in %d s%s"  (message, line 227)
- "on air at"  (message, line 228)
- "jammed at"  (message, line 228)
- "nothing (no recordings)"  (message, line 228)
- "(blackout: the hunt has stopped)"  (message, line 229)

## the Resistance's money (besides raiding supply drops) (sv_livingcity_funding.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_funding.lua`


*When:* part of: say

- "[Intel] {text}"  (chat message, line 45)

*When:* Intel What's worth writing down from here: the best thing in sight, and a key for "the same place".

- "the approaches to the Combine's ground"  (text, line 56)

*When:* part of: whats here

- "the checkpoint: its shifts, its gate, its men"  (text, line 61)
- "a unit's beat: where he walks, and when"  (text, line 68)

*When:* part of: scout

- "Intel is the Resistance's trade: the quartermaster buys it."  (text, line 77)
- "You need a sheet of paper to write on (the Commissary sells them)."  (text, line 78)
- "You're busy."  (text, line 79)
- "Nothing worth writing down here. Get within sight of a checkpoint, a unit on his beat, or the Combine's own ground."  (text, line 81)
- "You've written this one down already. It's old news for a while."  (text, line 83)
- "Writing down what you see... keep out of sight"  (progress bar, line 85)
- "You put the paper away."  (text, line 86)

*When:* part of: done

- "Written down: {what}. The quartermaster pays for it."  (chat message, line 93)

*When:* A unit who sees you at it: the paper's taken, and he remembers your face.

- "A Civil Protection unit sees you writing. He takes the paper off you, and looks hard at your face."  (chat message, line 105)
- "Seen taking notes on Civil Protection"  (text, line 106)

*When:* part of: forgery turned up

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

*When:* Talking to him

- "[Father Grigori] "Ah, a shepherd of the Combine! Come closer, so Annabelle can give you my blessing.""  (chat message, line 178)

*When:* A blessing, a sermon, or a word. True, or false and why not.

- "Father Grigori isn't here."  (text, line 199)
- "[Father Grigori] {SAYINGS}"  (chat message, line 202)

*When:* part of: grigori ask

- ""Go with God, child. But go.""  (text, line 205)
- ""Patience. God does not repeat Himself so soon." (%d s)"  (message, line 207)
- "He lays a heavy hand on your head and mutters in Russian. For five minutes, the world hurts you a little less."  (on-screen notice, line 213)
- ""I have said my piece. Come back later and I will say it again, louder." (%d s)"  (message, line 216)
- "Father Grigori's sermon"  (text, line 225)
- "Father Grigori preaches fire and brimstone at the Combine. For ten minutes your shots hit them harder."  (on-screen notice, line 226)

*When:* the game answering something done in a window (lc_grigori_ask)

- "[Father Grigori] {why}"  (chat message, line 239)

## flood guard (sv_livingcity_guard.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_guard.lua`


*When:* part of: net allowed

- "flood guard: kicked %s (%s) for flooding the server (%s)"  (message, line 56)
- "Too many requests to the server"  (text, line 57)

*When:* part of: chat allowed

- "Slow down: you're sending messages too fast."  (chat message, line 83)

## stealing the Combine's data (sv_livingcity_heist.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_heist.lua`


*When:* part of: alarm

- "[CP net] {or}{where}. Anticitizens are inside Combine systems. All Civil Protection units respond."  (chat message, line 139)
- "Anticitizens are breaking into Combine systems {where}."  (text, line 147)

*When:* What a finished download leaves in your pockets: from an ordinary terminal a fragment (two from different terminals make a chip), from the master terminal a master data core.

- "[Resistance] The master terminal's data, all of it, on one core. This is the motherlode: the quartermaster can decode it (every Civil Protection unit marked for ten minutes), the dealer will pay a fortune, or plug it in and wipe every comrade's record."  (chat message, line 159)

*When:* part of: downloaded

- "[Resistance] The other half. The two fragments make a whole chip of Combine data: the dealer pays well for it, or take it to the quartermaster to decode."  (chat message, line 166)
- "[Resistance] Half the picture: a data fragment. Another terminal has the rest. Download it and the two make a whole chip."  (chat message, line 170)

*When:* part of: steal data

- "You need a multitool to get into it. (The Resistance's Hackers carry one; the black market sells them.)"  (text, line 177)
- "You're busy."  (text, line 179)
- "Look at a Combine terminal."  (text, line 181)
- "Nothing new on this one. (Ready again in about %d minutes.)"  (message, line 184)
- "You've already got this terminal's half. The rest is on another terminal."  (text, line 187)
- "Downloading the master terminal... stay close"  (progress bar, line 192)
- "Downloading Combine data... stay close"  (progress bar, line 192)
- "The download breaks off. Nothing to show for it."  (text, line 193)

*When:* partway through, the terminal notices (the master terminal sooner)

- "[Resistance] Every alarm in the nexus at once. They're coming in force. Keep going, or run."  (chat message, line 210)
- "[Resistance] An alarm. They know. Keep going, or run."  (chat message, line 211)

*When:* part of: steal data

- "Breaking into the master terminal"  (text, line 215)
- "Breaking into Combine systems"  (text, line 215)

*When:* part of: decode chip

- "You don't have a data chip."  (text, line 231)
- "Only the Resistance can make sense of it. The dealer would buy it."  (text, line 232)
- "Take it to the lab: the scientist decodes them."  (text, line 233)
- "The master terminal's data decoded"  (text, line 236)
- "Combine data decoded"  (text, line 236)
- "The master terminal's data decoded"  (text, line 237)
- "Combine data decoded"  (text, line 237)
- "The data's decoded: Civil Protection unit positions, patrol routes, posts. Every unit is marked for you for %d seconds. Move."  (message, line 241)

*When:* part of: wipe record with chip

- "You don't have a data chip."  (text, line 262)
- "Look at a Combine terminal to plug it in (or take it to the quartermaster, or sell it)."  (text, line 263)

*When:* the motherlode: every comrade's record, not just yours

- "[Resistance] Someone fed the master terminal's own code back into it. Your record comes back clean."  (chat message, line 273)

*When:* part of: wipe record with chip

- "[Resistance] The master core's code goes into the system. %d records come back clean: no violations, no BOLOs, nobody wanted. The core is spent."  (message, line 276)
- "[Resistance] The chip's code goes into the system. Your record comes back clean: no violations, no BOLO, not wanted. The chip is spent."  (chat message, line 279)
- "[Resistance] Your face is still known, though: a fighter in the open is hunted whatever the records say."  (chat message, line 282)

*When:* Two fragments in your pockets, however they got there, are a chip.

- "[Resistance] Two data fragments, one whole chip."  (chat message, line 320)

## tips that pop up the first time something happens (sv_livingcity_hints.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_hints.lua`


*When:* first steps, in this order, a few seconds after you arrive

- "Welcome to the city"  (title, line 60)
- "The city runs whether you're watching or not. Tips like this pop up the first time you run into something. {gm_showhelp} opens your quick menu: the nine things you'll do most, on the number keys (6 to 8 change with what's in front of you). {+menu_context} opens the full menu: everything, with the guide at the top. Its Settings turn tips off."  (text, line 61)
- "Nothing is yours yet"  (title, line 62)
- "You've just arrived: no papers, no room, no ration card. Civil Intake registers you (your screen points the way): {+use} at the terminal and fill in who you are. Until then there are no rations or Union work for you, and Civil Protection units will ask for papers you don't have."  (text, line 63)
- "You're on the register, and your papers are in your pockets ({gm_showteam}). Housing Allocation gives you a room: {+use} at the terminal, present your papers and pick a block, and stay put while it searches. Until then, a curfew finds you waiting near Civil Intake."  (text, line 65)
- "Your menus"  (title, line 66)
- "{gm_showteam}: your pockets (eat, drink, make, give, wear). {gm_showspare1}: jobs and quests. {gm_showspare2}: your faction and rank."  (text, line 67)
- "{gm_showspare2}: your faction. You don't need pockets where you're going."  (text, line 68)
- "You're a citizen"  (title, line 69)
- "Pick a Union job on your {gm_showspare1} board and work shifts for credits and Civil Standing. Good standing opens up the Commissary, and at 100 you can join Civil Protection."  (text, line 70)
- "You're in the Resistance"  (title, line 71)
- "You come back in plain clothes: Civil Protection units leave you alone until they see a gun in your hand. {+menu_context} > Resistance > Gear up puts your own gear on. Rebel territory is home: the quartermaster, a supply crate, the pots."  (text, line 72)
- "A shackled vortigaunt"  (title, line 73)
- "You're Combine property: you work the Union's shifts ({gm_showspare1}), and the collar holds your vortessence in. The Resistance can cut your shackles. Then you heal and strike, and they hunt you."  (text, line 74)
- "Your vortessence: {+attack} a bolt at what you're looking at, {+attack2} heals whoever's in front of you, or yourself. Civil Protection units hunt you on sight outside rebel territory."  (text, line 76)
- "Civil Protection"  (title, line 77)
- "You're Overwatch: the Combine's soldiers, not its police. Your operations are on {gm_showspare1}. Civil Protection units call for help ({gm_showhelp}, then 1: Call for backup); answer it. 2 sends your 10-20, marking where you are. The Civil Protection Commissary issues your ammunition and grenades ({gm_showteam} marks the way)."  (text, line 78)
- "Your Arrest Baton: {+attack} strikes, {+attack2} arrests, {+reload} searches. Your directives are on {gm_showspare1}. Your quick menu ({gm_showhelp}) has backup, your 10-20, a BOLO, the mask's voice and records on the number keys, and search and ties for whoever you're looking at. Everything else: {+menu_context} > Unit tools. Supplies: the Civil Protection Commissary ({gm_showteam} marks the way)."  (text, line 79)
- "Your claws: {+attack} swipes, {+attack2} moans. The infestation is home. You don't eat, and you don't go down: you just die."  (text, line 81)
- "Your tools"  (title, line 82)
- "{+menu_context} > Unit tools has it all, each with what it does: the records terminal (CIDs, violations, loyalty points, BOLOs and requests), the mask's voice lines, and for whoever you're looking at, search, zip-tie and drag (the quick menu, {gm_showhelp}, has the ones you use most). You don't queue for rations: your ration, ammunition and grenades are issued at the Civil Protection Commissary ({gm_showteam} marks the way)."  (text, line 83)
- "Chat is spoken out loud: only people near you hear it. {+menu_context} > Talk yells, whispers, describes what you do or the scene, and talks out of character (in chat: /y, /w, /me, /it, //)."  (text, line 85)
- "Chat is spoken out loud: only people near you hear it. // is out of character, for everyone."  (text, line 86)
- "Need a hand?"  (title, line 87)
- "{+menu_context} > Help > Ask staff for help reaches the staff (or type @ and your message), for anything out of character: stuck, a rule question, someone breaking the rules."  (text, line 88)
- "The city goes dark from 21:00 to 05:00, and curfews come three times as often. {+menu_context} > The city tells you the hour."  (text, line 90)
- "Night. The streets are darker, and the living stay in."  (text, line 91)
- "Stand out in it with an empty bottle or can and it fills: rainwater, clean enough to drink as it is."  (text, line 93)
- "{+menu_context} > Me > Pose: sit, kneel, lie, lean (move to stand up). Me > Gesture: wave, salute, bow, nod and more. Me > Put my hands up."  (text, line 95)
- "More than one life"  (title, line 96)
- "You can have more than one person in the city. {+menu_context} > Me > My characters: switch between them, or start someone new."  (text, line 97)
- "Hunger and thirst"  (title, line 98)
- "Hunger and thirst drain over time (the bars at the top left; on a quiet HUD they show up once they start to bite). Rations come from the dispensers, water from vending machines and sinks. At zero you start dying."  (text, line 99)
- "Hunger and thirst drain over time (the bars at the top left; on a quiet HUD they show up once they start to bite). The supply crate in rebel territory feeds the Resistance; bins, fishing and the pots help. At zero you start dying."  (text, line 100)
- "Nothing keeps score"  (title, line 101)
- "No numbers on screen. Your credits and Civil Standing are at the top of your pockets ({gm_showteam}), your rank and progress on {gm_showspare2}."  (text, line 102)
- "Your eyes"  (title, line 103)
- "The camera sways a little with your steps and dips when you land. If that bothers you, {+menu_context} > Settings > Camera sway keeps it still (just for you)."  (text, line 104)

*When:* what happens to you

- "You're down"  (title, line 107)
- "You're bleeding out, not dead. Anyone can get you up by pressing {+use} on you. You can only whisper for help. {+menu_context} > Me > Give up, if nobody's coming."  (text, line 108)
- "Back on your feet"  (title, line 109)
- "You're up, but barely. Patch yourself up: a bandage from {gm_showteam} (make them from two rags), a medkit, or a medic."  (text, line 110)
- "You're wanted"  (title, line 111)
- "Civil Protection units will come for you. Get out of their sight and it cools down. Or give yourself up: walk to a unit and press {+use} ({+menu_context} > Me > Give myself up) for half the sentence."  (text, line 112)
- "Even Civil Protection units can be wanted. Get out of sight and it cools down, or press {+use} on a unit to hand yourself in."  (text, line 113)
- "Every Civil Protection unit has your description"  (title, line 114)
- "They've drawn pistols. At the next level Overwatch comes, and they don't arrest. Stay out of every Civil Protection unit's sight for 45 seconds to cool down (faster in rebel territory)."  (text, line 115)
- "Overwatch is coming"  (title, line 116)
- "A soldier squad is hunting you, with lethal force. Break line of sight and keep it broken. Rebel territory cools you down twice as fast."  (text, line 117)
- "Stop and search"  (title, line 118)
- "A Civil Protection unit is searching you. Stand still (hands up doesn't hurt: {+menu_context} > Me). Walk off and you're wanted for evading inspection. Anything illegal they find is confiscated."  (text, line 119)
- "Your hands are tied"  (title, line 120)
- "You can't use anything, and you can only walk. Someone can cut you free. Left alone, {+menu_context} > Me > Work at the ties; if anyone sees, they pull them tighter."  (text, line 121)
- "Sociostability: marginal"  (title, line 122)
- "More stop-and-searches on the street. Keep your papers ready and nothing on you you'd want found. The level is at the top of your screen."  (text, line 123)
- "Half as many stops again. The level is on your mask's readout; officers can set it in {+menu_context} > Unit tools."  (text, line 124)
- "Judgment waiver"  (title, line 125)
- "Civil Protection units may use lethal force as they see fit. Get indoors and stay out of sight until it lifts."  (text, line 126)
- "Lethal force at your discretion, and twice the stops. It lifts when the city calms, or when an officer says so."  (text, line 127)
- "Contraband in your pockets gets found. Your stash at home ({+menu_context} > Getting by) is never searched, though sweeps sometimes raid it."  (text, line 129)
- "Don't run in front of Civil Protection units"  (title, line 130)
- "A Civil Protection unit told you to stop running. Stop within two seconds and that's the end of it. Keep running and you're wanted for fleeing."  (text, line 131)
- "In custody"  (title, line 132)
- "Serve your time and you're let out at the release point. A friend can pass you a lockpick (Give, in their pockets) and you can work your cell door when no guard is looking. Escaping makes you wanted. If there's a Combine console in your cell, {+use} it to fly a city scanner while you wait."  (text, line 133)
- "Your standing took a hit. Community service on your {gm_showspare1} board earns it back, and so does keeping your head down."  (text, line 135)
- "You're out"  (title, line 136)
- "And wanted. Get out of sight. Spare clothes, a uniform or forged papers can make you someone else."  (text, line 137)
- "Get home"  (title, line 138)
- "A Civil Protection unit has caught you out after curfew. Three warnings and you're wanted. The arrow on your HUD points to your block. A travel permit gets you past one stop."  (text, line 139)
- "In a CP uniform"  (title, line 140)
- "Civil Protection units on the street take you for one of them, for a while. Don't hang around real units, don't commit crimes, and don't let one search you. Combine doors usually open."  (text, line 141)
- "In Resistance gear"  (title, line 142)
- "The fighters take you for one of them, and Civil Protection units will shoot you on sight. A fighter standing close may ask questions you can't answer."  (text, line 143)
- "In plain clothes"  (title, line 144)
- "You pass as an ordinary citizen. A gun in your hand where a Civil Protection unit can see it gives you away. Never change in front of a unit."  (text, line 145)
- "You pass as an ordinary citizen. Undercover work: citizens talk more freely, and nobody salutes."  (text, line 146)
- "Cover blown"  (title, line 147)
- "They know who you are. Get away, and change somewhere nobody can see you."  (text, line 148)
- "Conduct strike"  (title, line 149)
- "That kill had no roleplay reason. Two strikes is prison, four is a kick. Give people a reason first: a warning, a demand, a fight they started."  (text, line 150)
- "A new life"  (title, line 151)
- "Death here is permanent: that character is gone. New name, new face, and nobody knows you. Being shot first puts you down, so next time someone may get to you in time."  (text, line 152)
- "A new rank can mean new gear, new jobs and new trust. {gm_showspare2} shows what your rank opens up."  (text, line 154)
- "A new rank can mean new gear: grenades come from Metrocop up. {gm_showspare2} shows what your rank opens up."  (text, line 155)
- "A Resistance Member"  (title, line 156)
- "Fighters will follow you now: press {+use} on one in rebel territory (three at most). {+use} again sends them home."  (text, line 157)
- "Eat it from {gm_showteam} when you're hungry. One per allocation, twice as often during distribution. Low standing gets you nothing."  (text, line 159)
- "Homemade arms"  (title, line 160)
- "It's contraband in your pockets until you draw or load it ({gm_showteam}), and a search will find it. The black market buys it. The Resistance quartermaster pays half as much again."  (text, line 161)

*When:* what happens around you

- "Ration distribution"  (title, line 164)
- "Rations come twice as often now. Join a ration line and wait your turn, or press {+use} on a dispenser."  (text, line 165)
- "Keep the ration lines orderly. Citizens crowding a Civil Protection unit get moved along."  (text, line 166)
- "Inspection sweep"  (title, line 167)
- "Civil Protection units are stopping and searching everyone. If you're carrying contraband, stash it (in your stash, at home) or stay off the streets."  (text, line 168)
- "Stop and search citizens: {+reload} with your baton. What you seize pays credits and XP."  (text, line 169)
- "Block raid"  (title, line 170)
- "Civil Protection units are going through a housing block, frisking residents and taking contraband lying around. Whoever dropped it gets wanted."  (text, line 171)
- "A raid team is going through a housing block. Seized contraband is traced to its owners."  (text, line 172)
- "Go home: the arrow on your HUD points to your housing block, with a grace period to get there. After that, a Civil Protection unit who sees you out gives three warnings, then you're wanted."  (text, line 174)
- "Citizens have a grace period to get home. After it, anyone outside gets three warnings from a Civil Protection unit before they're wanted."  (text, line 175)
- "Get inside your block now. Extra Civil Protection units are on the streets. After the grace period, anyone outside gets three warnings, then they're wanted."  (text, line 177)
- "Extra Civil Protection units are on the streets. Clear them: three warnings, then anyone still out is wanted."  (text, line 178)
- "A rebel raid"  (title, line 179)
- "Fighters are hitting a checkpoint, and the Civil Protection units nearby are fighting back. Keep your head down, or keep well clear."  (text, line 180)
- "Fighters are hitting a checkpoint. Join in, or keep your cover. Either way, it's on the radio."  (text, line 181)
- "Fighters are hitting a checkpoint. {+menu_context} > Unit tools: Call for backup brings units to you, and Send my 10-20 shows them where you are."  (text, line 182)
- "A sweep into rebel ground"  (title, line 183)
- "An armed CP team is going into rebel territory. Stay out of it."  (text, line 184)
- "An armed CP team is going into rebel territory, and the fighters are fighting back. Help them, or get clear."  (text, line 185)
- "An armed team is sweeping rebel territory. Kills there push the Resistance back."  (text, line 186)
- "The infestation has broken out: infected in the nearby streets, and a lockdown. Get indoors."  (text, line 188)
- "The infected are loose in the streets near the infestation. Contain it."  (text, line 189)
- "The infestation has broken out. The streets are yours, for now."  (text, line 190)
- "The city is in unrest"  (title, line 191)
- "The Resistance holds enough ground: more inspections and raids, slower rations, a cheaper black market. {+menu_context} > The city > Who holds the city."  (text, line 192)
- "Full compliance"  (title, line 193)
- "Nothing has spread. Fewer skirmishes, and a dearer black market. {+menu_context} > The city > Who holds the city."  (text, line 194)

*When:* what's near you

- "Someone's down"  (title, line 197)
- "They're bleeding out. Press {+use} on them to get them up (a bandage makes it faster). Looking at them, {gm_showhelp} (your quick menu) > Drag them along pulls them into cover. Shooting them finishes them."  (text, line 198)
- "They're bleeding out. Press {+use} on them to get them up; if they're wanted, {+use} cuffs them where they lie. {gm_showhelp} (your quick menu) > Drag them along pulls them with you. Shooting them finishes them."  (text, line 199)
- "Press {+use} and stay with it a few seconds to search it: food, credits, ammunition, sometimes clothes or a keycard. Not in front of a Civil Protection unit. Looking at it, {gm_showhelp} > Haul the body works too: Morticians are paid to drag the dead to the incinerator."  (text, line 201)
- "Press {+use} and stay with it a few seconds to search it. Dead rebels sometimes carry their gear."  (text, line 202)
- "Press {+use} on a bin or dumpster to go through it: scrap, rags, tins, seeds, sometimes gun parts. Looking at one, your pockets ({gm_showteam}) can hide things in it, for anyone to find."  (text, line 204)
- "Press {+use} on a bin or dumpster to go through it (rebel territory's are better). Looking at one, your pockets ({gm_showteam}) can leave things in it: a dead drop."  (text, line 205)
- "Press {+use} to open it. Put something in and it's yours: locked to everyone else. Civil Protection units can open any locker, and take what's illegal."  (text, line 207)
- "Lockers belong to whoever claimed them. Press {+use} to search one: you can confiscate contraband, and the owner is wanted."  (text, line 208)
- "An apartment for rent"  (title, line 209)
- "Look at the door, {+menu_context} > This door > Rent it: a place of your own, locked to everyone but you and whoever you give a key (look at them: {+menu_context}). {+menu_context} > Home locks and unlocks it."  (text, line 210)
- "A market stall"  (title, line 211)
- "Someone's selling. Press {+use} to see what's on it and what it costs."  (text, line 212)
- "A licensed trader. Press {+use} to search it; an officer can revoke their license from the records terminal."  (text, line 213)
- "Something written"  (title, line 214)
- "A note or a notice. Press {+use} to read it; you can take it with you."  (text, line 215)
- "A note or a notice. Press {+use} to read it. Civil Protection units can tear down notices."  (text, line 216)
- "The law"  (title, line 217)
- "The city's laws. Press {+use} to read them, or {+menu_context} > The city > The city's laws, anywhere."  (text, line 218)
- "Too much to carry"  (title, line 219)
- "You're carrying more than you can manage, so you're slowed down. Drop something, or carry a satchel."  (text, line 220)
- "Press {+use} standing in water to drink, but untreated water can give you parasites. Fill empty bottles and cans here ({gm_showteam}), then boil them. A fishing line works here too."  (text, line 222)
- "Press {+use} to drink (a small risk of parasites). Fill bottles and cans from {gm_showteam}, then boil them."  (text, line 225)
- "Near a stove or fire you can cook raw meat and fish, and boil water, from your pockets ({gm_showteam})."  (text, line 227)
- "Vending machine"  (title, line 228)
- "Press {+use} to buy a can of Breen's Private Reserve. It quenches thirst, and leaves you a little dizzy."  (text, line 229)
- "Press {+use} to buy a can. With a multitool, aim at it and fire: ten seconds and it drops three cans, free. Not where a Civil Protection unit can see you."  (text, line 230)
- "Ration dispenser"  (title, line 231)
- "Press {+use} for your ration: one per allocation, none if your standing is too low. A forged ration card gets one anyway."  (text, line 232)
- "Press {+use} for your ration. With a multitool, aim at it and fire: ten seconds and it spits out three packets, no coupon, no record. Not where a Civil Protection unit can see you."  (text, line 233)
- "Citizens get one ration per allocation here. Civil Protection units don't queue."  (text, line 234)
- "Supply drop"  (title, line 235)
- "Union supplies are coming in: a crate of them at the loading dock. Anyone can press {+use} on it to take a load, but a Civil Protection unit who sees you is trouble."  (text, line 236)
- "A Combine supply drop: guns, ammunition, medicine. Press {+use} on the crate to take a load. The Civil Protection units guarding it will fight."  (text, line 237)
- "A supply drop to guard: if anything's left in the crate when the convoy moves on, every Civil Protection unit nearby is paid. Directive on your board."  (text, line 238)
- "A radio jammer"  (title, line 239)
- "Set it down from {gm_showteam}: for four minutes, Civil Protection unit radios nearby are static, request devices don't get through, and scanner photos never reach Civil Protection. It beeps, and units will come looking for it."  (text, line 240)
- "Hold it and press {+use} on junk (a wrecked car, a radiator, pipes, a crate) to pry scrap, rags and chemicals out of it: loud, and the nearest Civil Protection unit comes to look. It's a weapon, too: a unit who sees it in your hand makes you wanted. Put it away on the street."  (text, line 242)
- "Choose Talk (on screen, or {gm_showhelp}) and the beating stops: you give them a Resistance hideout, and if you're Resistance the cell will know you talked. Or say nothing and take it: it won't kill you."  (text, line 244)
- "Broken feet"  (title, line 245)
- "You can't run until it heals (the time is on your screen). It doesn't heal faster for dying or leaving."  (text, line 246)
- "Combine property"  (title, line 247)
- "You're a stalker now: slow, unarmed, unable to speak. Your board has work orders for you. It ends when your time is served, or when you die."  (text, line 248)
- "A Resistance member saw you inform. The Resistance see TRAITOR over your head for half an hour, and their fighters will shoot you. Stay away from rebel ground."  (text, line 250)
- "Combine data terminal"  (title, line 251)
- "Combine systems. Not for you."  (text, line 252)
- "A Hacker's job: aim the multitool at it, primary fire, and stay close for thirty seconds. It sounds the alarm halfway, and a squad comes. One terminal gives you a fragment, half the picture: download a second terminal's and the two make a whole chip. Sell the chip to the dealer, have the lab's scientist decode it (every Civil Protection unit marked for the whole Resistance), or plug it into a terminal to wipe your record."  (text, line 253)
- "A Combine data terminal. If the Resistance get at it, the alarm goes off: DATA BREACH."  (text, line 254)
- "The master terminal"  (title, line 255)
- "The Combine's master terminal. Not for you."  (text, line 256)
- "The motherlode. A Hacker's job: aim the multitool at it, primary fire, and hold on for a full minute. The alarm goes a third of the way in and a bigger squad comes. What you get is a master data core: the dealer pays a fortune, the quartermaster's decoding marks every Civil Protection unit for ten minutes, and plugged into a terminal it wipes every comrade's record. Dry for an hour after."  (text, line 257)
- "The master terminal. If the Resistance get at it, every alarm in the nexus goes off."  (text, line 258)
- "A data fragment"  (title, line 259)
- "Half of a chip. Download a second terminal's data (a different terminal) and the two fragments make a whole chip. Contraband: hide it."  (text, line 260)
- "The master data core"  (title, line 261)
- "The motherlode. Contraband: hide it well. The dealer pays a fortune; the quartermaster's decoding marks every Civil Protection unit for the whole Resistance for ten minutes; used at a terminal it wipes the records of every Resistance member in the city."  (text, line 262)
- "A Combine data chip"  (title, line 263)
- "Contraband: hide it. The black market dealer pays well for it. The Resistance quartermaster can decode it (Use it from your pockets near him): every Civil Protection unit marked for the whole Resistance for five minutes. Or use it at a terminal to wipe your own record."  (text, line 264)
- "The lab"  (title, line 265)
- "The cell's lab. Press {+use} on the scientist: he makes guns, ammunition, armour, jammers, bypass charges and Freq 7 radios. Bring the materials and it's free, or pay him (cheaper than the dealer). Stay in the lab while he works."  (text, line 266)
- "A Resistance lab. Press {+use} on the scientist to shut it down: he's taken away, and nothing is made here for a while."  (text, line 267)
- "A cluttered lab bench, and a nervous man beside it. He works for the Resistance, and only for them. Everyone else buys guns at the black market."  (text, line 268)
- "It powers this district: the streetlights, loudspeakers, screens, forcefields and the Combine door locks. If it goes down, a Maintenance Technician brings it back ({+use})."  (text, line 270)
- "It powers this district, Combine door locks included. A multitool shorts it out in twelve seconds: the lights go out and their doors open, until someone fixes it."  (text, line 271)
- "It powers this district, our door locks and forcefields included. Keep the Resistance away from it."  (text, line 272)
- "Combine forcefield"  (title, line 273)
- "Civil Protection units walk through it. Nobody else does, unless they swipe a Combine keycard ({+use}). It drops when the district's power goes."  (text, line 274)
- "Civil Protection units walk through. A Combine keycard ({+use}) opens it for a moment; a multitool shorts it out for a minute; and it drops with the district's power."  (text, line 275)
- "Combine power bank"  (title, line 276)
- "A checkpoint's power. The turrets and forcefields cabled to it run off it, and it draws from the district's transformer: when the power goes, so do they."  (text, line 277)
- "A checkpoint's power. A multitool ({+attack} with it out, aimed at the bank) shorts it out for two minutes, and every turret and forcefield on its cables dies with it. Near the infestation, that's a breach."  (text, line 278)
- "Your checkpoint's power. Deploy turrets near it ({+menu_context} > Civil Protection). Keep the Resistance off it: if it dies near the infestation, the infected break out."  (text, line 279)
- "Combine turret"  (title, line 280)
- "It shoots the infected, the wanted and known rebels, and leaves everyone else alone. Its cable runs to the checkpoint's power."  (text, line 281)
- "It shoots you on sight if they know you. Kill its power (the power bank, or the district's transformer) and it folds up."  (text, line 282)
- "It shoots the infected and the wanted. Civil Protection units put up two each ({+menu_context} > Civil Protection) and pack them up with {+use}."  (text, line 283)
- "The city's dead end up here. Haul a body over (Morticians: {+use} on a body; anyone: look at it, {gm_showhelp} > Haul the body) and let go beside it, or press {+use} on the incinerator. Attendants are paid for each one."  (text, line 285)
- "The city's incinerator. A body that goes in here never gets identified. Haul one over: look at it, {gm_showhelp} > Haul the body."  (text, line 286)
- "Reclamation point"  (title, line 287)
- "Press {+use} to hand in scrap, empty cans and bottles: a few credits and a little Civil Standing. The loyal way to use junk."  (text, line 288)
- "Press {+use} to hand in scrap, cans and bottles for credits and standing. Or keep it: the cell makes ammunition from scrap."  (text, line 289)
- "Citizens hand in scrap here for credits and standing."  (text, line 290)
- "Combine console"  (title, line 291)
- "Prisoners and Civil Protection units: press {+use} to fly one of the city's scanners. Your body stays here. Left click flashes; flash a unit and your sentence grows. Get within about ten feet of rebels, free vortigaunts, the wanted or zombies and photograph them for Civil Standing (never time off). R disconnects."  (text, line 292)
- "Press {+use} to fly a city scanner. Left click photographs whatever's within about ten feet: rebels, free vortigaunts, the wanted and zombies it catches are lit up for every Civil Protection unit."  (text, line 293)
- "Scanner report"  (title, line 294)
- "A scanner photographed someone. Whoever it caught is outlined in red for a minute, through walls, and rebel ground is marked on your screen. Go and get them."  (text, line 295)
- "A scanner caught you. Every Civil Protection unit can see where you are for a minute. Get out of sight, shoot the scanner down, or throw smoke: a scanner can't photograph anyone in it or behind it."  (text, line 297)
- "The Commissary"  (title, line 298)
- "Press {+use} to shop. What it sells you depends on your Civil Standing."  (text, line 299)
- "Press {+use} to shop: ammunition, batteries and grenades for Civil Protection units. (A Civil Protection Commissary issues them for nothing.)"  (text, line 300)
- "Civil Protection Commissary"  (title, line 301)
- "Press {+use} to be issued supplies: grenades for your rank, ammunition for your weapons, armour, bandages and your ration. Once every two minutes; the Civil Protection unit counter opens after."  (text, line 302)
- "Press {+use} to be issued supplies: grenades, ammunition, armour, bandages and a ration. Once every two minutes."  (text, line 303)
- "Civil Protection's supply point. Civil Protection units only."  (text, line 304)
- "The black market"  (title, line 305)
- "Press {+use} to trade: papers, uniforms, lockpicks, spray cans, seeds, gun parts. He buys almost anything. Don't let a Civil Protection unit see you."  (text, line 306)
- "A black market dealer. Walk up to him and he's busted: gone for 15 minutes, and you're paid."  (text, line 307)
- "A supply crate"  (title, line 308)
- "The Resistance eats from this: press {+use} for a tin, one every four minutes. {+menu_context} > Resistance > Donate food puts food from your pockets in."  (text, line 309)
- "A Resistance supply crate. Food from your pockets goes in: {+menu_context} > Resistance > Donate food."  (text, line 310)
- "Hoarded Resistance supplies. Press {+use} to confiscate the lot."  (text, line 311)
- "Plant a seed packet in it with {+use}. In a few minutes it's three lots of vegetables, and anyone can harvest a ripe pot."  (text, line 313)
- "A Resistance garden. Press {+use} to uproot it."  (text, line 314)
- "A Resistance tag. Scrub it off with {+use} for standing, or leave it."  (text, line 316)
- "The lambda. Spray cans (black market) put it on walls. Tags near rebel ground help it spread. Don't let a Civil Protection unit see you."  (text, line 317)
- "Press {+use} on a lambda tag to scrub it off, for XP."  (text, line 318)
- "The quartermaster"  (title, line 319)
- "Press {+use} to trade. He sells the black market's stock to the Resistance, and pays half as much again for homemade guns and ammo."  (text, line 320)
- "From Resistance Member up, press {+use} on a fighter to have them follow you and fight with you (three at most). {+use} again sends them home."  (text, line 322)
- "Everyone here has a name and a life. Press {+use} on someone to talk: what they've heard, a bit of food, or a hand in their pocket. They remember how you treat them."  (text, line 324)
- "With the baton out: {+use} stops a citizen, {+reload} pats them down (sympathizers carry more), {+attack2} detains them."  (text, line 325)
- "Civil Protection"  (title, line 326)
- "Don't run in front of Civil Protection units and don't crowd them. If one stops you, stand still until it's over."  (text, line 327)
- "Don't run in front of Civil Protection units and don't crowd them. Keep your gun out of sight in plain clothes."  (text, line 328)
- "Someone wanted"  (title, line 329)
- "Someone near you is wanted. Your baton's {+attack2} arrests them, {+reload} searches. {+menu_context} > Unit tools > Call for backup if it turns ugly."  (text, line 330)
- "A shackled vortigaunt"  (title, line 331)
- "From Member up, you can cut its shackles: look at it, {+menu_context} > Cut the vortigaunt's shackles (ten seconds, no Civil Protection unit watching). It joins the Resistance."  (text, line 332)
- "People don't know your name until you tell them: look at someone, {+menu_context} > Tell them my name (or show them your papers). Until then they see your description: {+menu_context} > Me > Change how strangers see me."  (text, line 334)
- "One punch kills a bird. Cook the carcass at a stove or burning barrel ({gm_showteam})."  (text, line 336)
- "Weak, but don't turn your back. Several punches kill one, and it leaves meat to cook. Never go AFK in an alley."  (text, line 338)
- "Rebel territory"  (title, line 339)
- "The fighters leave citizens alone. The bins are better here, and the black market is open ({+menu_context} > Getting by). Stay out of any shooting."  (text, line 340)
- "Home. You're among friends. The quartermaster, the supply crate and the pots are here, and you can make guns and ammo ({gm_showteam})."  (text, line 341)
- "The fighters shout once, then shoot. Come in with a sweep, or with backup. Kills here push the Resistance back."  (text, line 342)
- "The infestation"  (title, line 343)
- "Zombies and headcrabs. Nothing here is worth it unless you've got a reason."  (text, line 344)
- "Containment jobs on your board send Civil Protection units in. Kills here push the infestation back."  (text, line 345)
- "Your block"  (title, line 347)
- "This is your housing block: come here at curfew. You can make things here ({gm_showteam}), and keep what you don't want found in your stash ({+menu_context} > Getting by)."  (text, line 348)
- "Combine only"  (title, line 349)
- "You're trespassing. Leave before the countdown on your screen runs out, or you're wanted."  (text, line 350)
- "You're in plain clothes with a gun in your hand. If a Civil Protection unit sees it, your cover is blown. Switch to your fists or holster it ({+menu_context} > Me)."  (text, line 352)
- "{+attack} throws, {+reload} switches between smoke, flashbang and gas. Smoke hides you, a flashbang blinds, gas chokes anyone without a mask. Civil Protection units are masked."  (text, line 354)

*When:* how you're doing

- "Eat something from {gm_showteam}. No food? A ration dispenser, the Commissary, a bin, fishing, or something you can cook."  (text, line 358)
- "Eat something from {gm_showteam}. No food? The supply crate in rebel territory, a bin, the pots, fishing."  (text, line 359)
- "Drink something from {gm_showteam}. A sink, a vending machine, or water: boil it first if you can."  (text, line 361)
- "Untreated water. You'll be hungrier and thirstier, and coughing, until you take antiparasitic tablets (Commissary)."  (text, line 363)
- "Patch yourself up: a bandage from {gm_showteam} (two rags make one), a medkit, or a medic."  (text, line 365)
- "Low standing"  (title, line 366)
- "Your Civil Standing is below zero: no rations, and Civil Protection units watch you. Community service on your {gm_showspare1} board earns it back, and so does keeping quiet."  (text, line 367)
- "You could join Civil Protection"  (title, line 368)
- "Your standing is high enough to put on the uniform. {gm_showspare2} to join."  (text, line 369)

*When:* what's in your pockets

- "Plant them in a pot in rebel territory: look at the pot and press {+use}. They ripen into vegetables in a few minutes."  (text, line 373)
- "Fishing line"  (title, line 374)
- "Stand in the canal or look at the water, then Fish from {gm_showteam} (or {+menu_context} > Getting by) and keep still. Cook what you catch."  (text, line 375)
- "A spray can"  (title, line 376)
- "Look at a wall and Spray from {gm_showteam} to put the lambda up. If a Civil Protection unit sees you, you're wanted for vandalism."  (text, line 377)
- "Look at a locked door: {+menu_context} > This door > Pick the lock (or bind a key to lc_pick). It won't open Combine locks. Give one to a prisoner (from {gm_showteam}) and they can work their own cell door."  (text, line 379)
- "A bypass charge"  (title, line 380)
- "Opens any door once, Combine doors included: look at the door, {+menu_context} > This door > Pick the lock. Sometimes it trips an alarm."  (text, line 381)
- "Opens one Combine door (look at it, {+menu_context} > This door > Pick the lock) before someone reports it missing."  (text, line 383)
- "Raw meat"  (title, line 384)
- "Cook it near a stove, oven or burning barrel ({gm_showteam}). Eating it raw is a gamble."  (text, line 385)
- "An empty container"  (title, line 386)
- "Fill it in water or at a sink ({gm_showteam}), then boil it near a stove or fire before you drink it."  (text, line 387)
- "Untreated water"  (title, line 388)
- "Boil it near a stove or fire first ({gm_showteam}), or risk parasites."  (text, line 389)
- "Wear them from {gm_showteam} to pass as an ordinary citizen. Never change in front of a Civil Protection unit."  (text, line 391)
- "Wear it from {gm_showteam}: Civil Protection units on the street will take you for one of them, for a while. It's contraband, and a search finds it."  (text, line 393)
- "Resistance gear"  (title, line 394)
- "Wear it from {gm_showteam}: the fighters take you for one of them. Civil Protection units will too, and they shoot."  (text, line 395)
- "Use them from {gm_showteam} to become someone else. It clears your wanted status, if no Civil Protection unit is watching."  (text, line 397)
- "A blank identity form"  (title, line 398)
- "Forge it ({gm_showteam}) somewhere private: out of any Civil Protection unit's sight."  (text, line 399)
- "A forged ration card"  (title, line 400)
- "One ration from any dispenser, whatever your standing or how recently you ate."  (text, line 401)
- "A Union radio"  (title, line 402)
- "City notices come through it before an event. {+menu_context} > Talk > On my radio. Civil Protection listens."  (text, line 403)
- "A radio, on Freq 7"  (title, line 404)
- "Freq 7: the Resistance band, and whatever Civil Protection says when it thinks nobody's listening. {+menu_context} > Talk > On my radio talks on it; On the Union band, on the city's. It's contraband."  (text, line 405)
- "A travel permit"  (title, line 406)
- "Keep it on you. It gets you past one stop during curfew."  (text, line 407)
- "Rags make bandages and scrap makes lockpicks, by hand, anywhere ({gm_showteam}). Guns, ammunition, smoke bombs and jammers are the Resistance lab's work: its scientist makes them from these, for the Resistance. Everyone else buys them at the black market. More from bins, from junk pried apart with a crowbar, and from downed scanners."  (text, line 409)
- "Your papers"  (title, line 410)
- "Identity papers and a ration card. Civil Protection units ask for papers: look at them, {gm_showhelp} > Show them my papers (or {gm_showteam} > Show). The ration dispensers want the card. Lose them and Civil Intake replaces them, for a fee."  (text, line 411)
- "Patch yourself up from {gm_showteam}. Used on someone who's down, it gets them up faster and in better shape."  (text, line 413)
- "Contraband until you draw or load it from {gm_showteam}, and a search will find it. The black market buys it; the quartermaster pays more."  (text, line 415)
- "Smuggled supplies"  (title, line 416)
- "Contraband in your pockets. Get them where they're going without being stopped."  (text, line 417)
- "Something to throw"  (title, line 418)
- "Throw it from {gm_showteam}. Smoke hides anyone in it from Civil Protection units and rebels alike."  (text, line 419)
- "Antiparasitic tablets"  (title, line 420)
- "Take them from {gm_showteam} if untreated water has given you parasites."  (text, line 421)
- "Zip ties"  (title, line 422)
- "Look at someone up close, {+menu_context} > their name > Zip-tie their hands: their hands up, down, stopped by a Civil Protection unit, or from behind. Drag walks them along; Cut the ties lets them go."  (text, line 423)
- "A request device"  (title, line 424)
- "/request <what's wrong> calls Civil Protection to where you are. Civil Protection units see it on their screens. Once a minute, and false requests go on your record."  (text, line 425)
- "While you carry it you can take more: eight more kilos, and one more large thing. Your pockets ({gm_showteam}) show the weight."  (text, line 427)
- "A storage crate"  (title, line 428)
- "Set it down somewhere from your pockets ({gm_showteam}, Set down) and it's yours to keep things in. Only you can open it, but Civil Protection units can."  (text, line 429)
- "A business license"  (title, line 430)
- "With it in your pockets you can set down a market stall (Commissary) and sell from it at your own prices. An officer can revoke it."  (text, line 431)
- "A market stall"  (title, line 432)
- "Set it down from your pockets ({gm_showteam}, Set down). Then look at it and Sell things from your pockets at a price you choose. The money waits in the till."  (text, line 433)
- "Write from your pockets ({gm_showteam}): leave a note, put a poster up on a wall, or keep it. Sign it, or don't."  (text, line 435)
- "A wedding ring"  (title, line 436)
- "It belonged to somebody. The black market pays well for it."  (text, line 437)

*When:* !hints For chat, where nobody's binding can be looked up: the usual keys.

- "Left click"  (text, line 875)
- "Right click"  (text, line 875)

*When:* typing in chat

- "[Tips] Off. Turn them back on from the full menu (C > Settings)."  (chat message, line 888)
- "[Tips] On. You'll see each one the first time it comes up."  (chat message, line 891)
- "[Tips] Reset. You'll see them all again, as things come up."  (chat message, line 896)
- "[Tips] Nothing yet this session. F1 has the full guide."  (chat message, line 900)
- "[Tips] The last few:"  (chat message, line 902)
- "{title}: {text}"  (chat message, line 903)
- "[Tips] They're off. C > Settings turns them back on."  (chat message, line 905)
- "[Tips] C > Tips I've seen has every one you've had; C > Settings turns them off, or starts them over."  (chat message, line 906)

## housing blocks (sv_livingcity_housing.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_housing.lua`


*When:* part of: assign block

- "[Living City] You have been assigned to {n}."  (chat message, line 97)

*When:* typing in chat

- "[Living City] You live in {n}."  (text, line 147)
- "[Living City] You have no room yet. Ask Housing Allocation for one."  (text, line 148)
- "[Living City] This map has no housing blocks yet."  (chat message, line 149)

*When:* the console command lc_setblock

- "[Living City] You have been reassigned to {n}."  (chat message, line 166)

## toilets, baths and what happens without them (sv_livingcity_hygiene.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_hygiene.lua`


*When:* part of: register places

- "No toilets found in this city."  (text, line 112)
- "No bathtubs or showers found in this city."  (text, line 113)
- "No beds found in this city."  (text, line 114)

*When:* part of: stain

- "A mess to clean"  (text, line 121)
- "Nothing to clean up right now."  (text, line 122)

*When:* Sanitation is told

- "A mess to clean up"  (on-screen notice, line 176)
- "Someone soiled themselves {or}. E on it to scrub it up (paid). F1 > Places marks it."  (on-screen notice, line 176)

*When:* on the trousers, and on the ground

- "You couldn't hold it"  (on-screen notice, line 196)
- "You've soiled yourself. A toilet, a wash (a bathtub or shower) and clean clothes, or people will keep their distance (and you may make them ill)."  (on-screen notice, line 196)

*When:* part of: soil

- "[Living City] Someone nearby has soiled themselves. The smell reaches you a moment later."  (chat message, line 199)

*When:* Toilets, baths, clean clothes

- "On the toilet..."  (progress bar, line 217)
- "You get up before you're done."  (text, line 218)

*When:* part of: done

- "That's better"  (on-screen notice, line 237)
- "For now. It drained you, though: drink something. Only antiparasitic tablets will stop it coming back."  (on-screen notice, line 237)
- "It drained you, though: drink something."  (on-screen notice, line 238)
- "That's better"  (on-screen notice, line 240)
- "Nothing much to it."  (on-screen notice, line 240)
- "[Living City] Still to do: {left}."  (chat message, line 244)

*When:* part of: use bath

- "You step out half washed."  (text, line 254)

*When:* part of: done

- "Clean skin, filthy clothes: change into clean ones (spare clothes or overalls from your pockets)."  (on-screen notice, line 264)
- "Scrubbed clean."  (on-screen notice, line 264)
- "You wash. You feel almost human."  (on-screen notice, line 266)

*When:* Into clean clothes: spare citizen clothes or Union overalls from your pockets. id: which (else whichever you have). True, or false and why.

- "Your clothes are clean enough."  (text, line 276)
- "You need clean clothes: spare citizen clothes or Union overalls (the Commissary sells them)."  (text, line 279)

*When:* part of: change clothes

- "Clean clothes"  (on-screen notice, line 286)
- "Better. You still need a wash: a bathtub or a shower."  (on-screen notice, line 286)
- "Better. The old ones can go in the bin."  (on-screen notice, line 286)

*When:* The stain on the ground

- "Scrubbing it up..."  (progress bar, line 305)
- "You leave it half done."  (text, line 306)

*When:* part of: done

- "Cleaned up a mess"  (text, line 312)
- "Something got on you"  (on-screen notice, line 315)
- "Scrubbing that up, something got on your hands. Your stomach turns."  (on-screen notice, line 315)
- "Cleaned up"  (on-screen notice, line 317)
- "5 credits. Wash your hands."  (on-screen notice, line 317)

*When:* people nearby smell it, and may catch it

- "[Living City] Someone near you reeks. Flies, and worse. You'd step back if you were sensible."  (chat message, line 349)

*When:* part of: hygiene tick

- "Your stomach cramps"  (on-screen notice, line 367)
- "You need a toilet. Soon. (F1 > What now? shows the nearest.)"  (on-screen notice, line 367)
- "Find a toilet. NOW."  (on-screen notice, line 368)
- "You can't hold it much longer."  (on-screen notice, line 368)

*When:* What now? (sv_livingcity_nextstep.lua asks this first)

- "Find a toilet"  (text, line 389)
- "You've soiled yourself. A toilet first, then a wash and clean clothes."  (text, line 389)
- "Your stomach's cramping (parasites): sit on a toilet before it's too late. Antiparasitic tablets stop it for good."  (text, line 390)

*When:* part of: hygiene step

- "Get washed"  (text, line 393)
- "You reek. A bathtub or a shower: press E on it."  (text, line 393)
- "Change into clean clothes"  (text, line 398)
- "Your clothes are filthy. Choose this to change into the clean ones in your pockets."  (text, line 398)
- "Get clean clothes"  (text, line 399)
- "Your clothes are filthy. The Commissary sells spare clothes; then change into them."  (text, line 399)

## Civil Intake (becoming somebody) (sv_livingcity_intake.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_intake.lua`


*When:* part of: register person

- "[Civil Intake] You were processed while in custody: %s, citizen %s. Your papers and ration card are in your pockets (F2)."  (message, line 218)
- "[Civil Intake] Registration complete. %s, citizen %s. Your identity papers and ration card are in your pockets (F2). Keep them on you."  (message, line 220)
- "[Civil Intake] Next: Housing Allocation, for a room. It's marked on your screen."  (chat message, line 224)
- "[Civil Intake] Your file already lists a room: {n}. Housing Allocation can tell you more."  (chat message, line 228)
- "[Civil Intake] You've been given a room in {n}."  (chat message, line 233)

*When:* part of: house person

- "[Housing Allocation] {or} is full; your request was declined. Assigned: a room in {n}."  (chat message, line 289)
- "[Housing Allocation] Approved: a room in {n}. It's marked on your screen. Curfew finds you at home from now on."  (chat message, line 291)
- "[Housing Allocation] No rooms on file in this city."  (chat message, line 294)

*When:* A housed citizen moving to another block.

- "You have no room to transfer from."  (text, line 304)
- "Transfers are for citizens in good standing ({TRANSFER_STANDING} or more)."  (text, line 306)
- "Your last transfer is too recent. Ask again in %d minutes."  (message, line 309)

*When:* part of: transfer person

- "[Housing Allocation] {why}"  (chat message, line 315)
- "[Housing Allocation] There's nowhere to transfer you to."  (chat message, line 318)
- "[Housing Allocation] Transfer declined: {or} is full. You stay in {from}."  (chat message, line 320)
- "[Housing Allocation] Transfer approved: {from} to {n}. It's marked on your screen."  (chat message, line 325)
- "Processing your registration"  (text, line 347)
- "[Civil Intake] Stand still. Processing."  (text, line 347)
- "Searching the housing register"  (text, line 348)
- "[Housing Allocation] Stand still. Searching the housing register."  (text, line 348)
- "Processing your transfer request"  (text, line 349)
- "[Housing Allocation] Stand still. Processing your transfer request."  (text, line 349)
- "Printing your identity papers"  (text, line 350)
- "[Civil Intake] Stand still. Printing new papers."  (text, line 350)
- "Issuing a new ration card"  (text, line 351)
- "[Civil Intake] Stand still. Issuing a new ration card."  (text, line 351)

*When:* part of: finish

- "[Civil Intake] Insufficient credits. The replacement costs {fee}."  (chat message, line 377)
- "replacement {what}"  (text, line 380)
- "[Civil Intake] New identity papers issued ({fee} credits). Keep them on you."  (text, line 382)
- "[Civil Intake] New ration card issued ({fee} credits)."  (text, line 383)

*When:* part of: use intake

- "[Housing Allocation]"  (title, line 406)
- "[Civil Intake]"  (title, line 406)
- "The screen reads CLOSED. New arrivals are registered as they come in."  (chat message, line 408)
- "%d waiting in line."  (message, line 412)
- "The terminal only processes citizens."  (chat message, line 414)

*When:* the registered (and anyone at Housing Allocation): the terminal's own screen

- "Processing another citizen. Wait your turn."  (chat message, line 420)

*When:* A button on a terminal's screen. True if the terminal took it on.

- "[Housing Allocation]"  (title, line 468)
- "[Civil Intake]"  (title, line 468)
- "Processing another citizen. Wait your turn."  (chat message, line 472)

*When:* part of: desk action

- "No record of you. Register at Civil Intake first."  (chat message, line 476)
- "Present your identity papers. You have none on you: Civil Intake replaces lost papers."  (chat message, line 478)
- "You already have a room. Ask for a transfer instead."  (chat message, line 482)
- "You already have {or} on you."  (chat message, line 494)
- "A replacement costs {fee} credits. You don't have them."  (chat message, line 497)

*When:* the game answering something done in a window (lc_intake_act)

- "[Civil Intake] Step back up to the terminal."  (chat message, line 517)

*When:* The registration form, handed in (sv_livingcity_character.lua asks first).

- "Step back up to the terminal to enter your details."  (text, line 527)
- "Describe yourself for the register: how a stranger would know you (8 characters at least)."  (text, line 530)

*When:* part of: intake form check

- "A shorter description, please (120 characters at most)."  (text, line 531)

*When:* a timer (regularly)

- "[Civil Intake] You walked away from the terminal. Start again."  (chat message, line 560)

*When:* on the register, but never handed their papers (everyone from before they were things you carry)

- "[Papers] Your identity papers and ration card are in your pockets (F2). Keep them on you: Civil Protection units ask for papers, and the dispensers want the card."  (chat message, line 605)

*When:* a timer (regularly)

- "[Civil Intake] You've arrived in the city with nothing: no papers, no room, no ration card. Report to Civil Intake to register. Your screen points the way."  (chat message, line 634)
- "[Housing Allocation] You've arrived in the city with nowhere to sleep. Ask Housing Allocation for a room. Your screen points the way."  (chat message, line 636)

*When:* on the register: are they carrying their papers?

- "[Civil Protection] Papers. None? Carry them at all times. Civil Intake replaces lost papers."  (chat message, line 654)
- "no papers on them"  (text, line 655)

*When:* part of: intake stopped

- "[Civil Protection] No papers. New arrival? Report to Civil Intake. Now."  (chat message, line 662)
- "[Civil Protection] Still no papers. Failure to register."  (chat message, line 666)
- "Failure to register"  (text, line 667)

*When:* A unit's own search finds no papers.

- "[Records] No papers: not on the register. New arrivals report to Civil Intake."  (chat message, line 675)
- "[Records] On the register, but carrying no papers."  (chat message, line 677)

*When:* The steps a new arrival takes at the desks before going home (empty when there are none, or intake is off).

- "in line at Civil Intake"  (text, line 795)
- "being registered at Civil Intake"  (text, line 795)
- "in line for Housing Allocation"  (text, line 797)
- "waiting on a housing allocation"  (text, line 797)

*When:* Commands What their papers say: their own, or the forged ones they're living under.

- "None yet: Housing Allocation"  (text, line 833)
- "None on file"  (text, line 833)

*When:* part of: papers info

- "Citizen {alias}"  (text, line 840)

*When:* Show your papers to whoever you're looking at (or read them yourself).

- "[Papers] You have none. Report to Civil Intake to register."  (text, line 853)
- "[Papers] You have no papers on you. Civil Intake replaces lost papers."  (text, line 855)

*When:* part of: show papers

- "[Papers] They show you their papers: %s, citizen %s."  (message, line 861)
- "[Papers] You hold your papers up for them to see."  (chat message, line 863)

*When:* part of: papers

- "[Papers] You have none. Report to Civil Intake to register."  (chat message, line 874)
- "[Papers] %s, citizen %s. Housing: %s.%s"  (message, line 879)
- "(Your papers aren't on you: Civil Intake replaces them.)"  (message, line 880)

*When:* the console command lc_register

- "[Living City] Usage: lc_register <name>"  (text, line 905)

*When:* the console command lc_unregister

- "[Living City] Usage: lc_unregister <name> (sends them back through Civil Intake)"  (text, line 912)
- "[Living City] Staff sent you back through Civil Intake: register, then ask Housing Allocation for a room."  (chat message, line 928)

## work you actually do (sv_livingcity_jobgames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_jobgames.lua`


*When:* community service is unpaid (sv_livingcity_work.lua): the work still counts

- "Paid %d credits for the work, on top of the shift."  (message, line 112)
- "Nothing extra for that."  (text, line 112)

*When:* What's under the wrapper: { item, weight } (credits for "coins")

- "A scrap of paper, folded small: 'Kleiner lives.' Underneath, a lambda."  (text, line 179)
- "A ration wrapper with a map drawn on the inside: the canal, and an X."  (text, line 180)
- "A note in a child's hand: 'Papa, they took the man from 4C. Come home the back way.'"  (text, line 181)
- "Half a Combine notice, the rest torn away: '...relocation of all residents of Block...'"  (text, line 182)

*When:* part of: start

- "Street sweep"  (title, line 216)

*When:* part of: lc on pickup

- "found in the rubbish"  (text, line 247)
- "[Sanitation] Wedged in it: %d credits in Union tokens. Finders keepers."  (message, line 248)
- "Found in the rubbish"  (on-screen notice, line 250)
- "[Sanitation] Tucked inside it: {what}. It's in your pockets."  (chat message, line 253)

*When:* part of: start

- "[Sanitation] Your cart's at the depot. E on it to push it (E again to let go). Pick up the rubbish with E and throw it in (left click). Bring the cart back when it's full."  (chat message, line 263)

*When:* part of: hud

- "In the cart: %d of %d"  (message, line 266)
- "Long throws: %d"  (message, line 267)
- "Full: push the cart back to the depot"  (text, line 268)
- "Pushing the cart (E to let go)"  (text, line 268)
- "E on the cart to push it"  (text, line 268)

*When:* part of: tick

- "Quick work: the foreman nods."  (text, line 301)
- "%d long throws into the cart."  (message, line 303)
- "Out of time: what's in the cart counts."  (text, line 308)

*When:* pressing a key

- "[Sanitation] You let go of the cart."  (chat message, line 323)

*When:* The same line, other work: the ration plant's sealing line (opts.variant = "rations").

- "On the line"  (title, line 349)
- "The line's starting. Rust-red, sparking parts are bad: grab them (E) and throw them in the scrap bin. Let the good ones go through. (R while holding a good one slips it into your coat: the dealer and the quartermaster buy them. Not where a unit can see, and the foreman counts.)"  (text, line 350)
- "Something rattles inside this one. R while you're holding it to slip it in your pocket."  (text, line 351)
- "The sealing line"  (title, line 352)
- "The sealing line's starting. Split, leaking packs (the sickly green ones) go in the reject bin: grab them (E) and throw them in. Sealed ones go through to the dispensers. (R while holding a sealed one slips it into your coat. Not where a unit can see, and the foreman counts.)"  (text, line 353)
- "This pack is heavier than a ration should be. R while you're holding it to slip it in your pocket."  (text, line 354)

*When:* part of: hud

- "Bad %s binned: %d    Good %s through: %d"  (message, line 423)
- "Bad %s let through: %d    Good %s binned: %d"  (message, line 424)

*When:* part of: tick

- "[Foreman] That one was good! Watch what you're binning."  (chat message, line 474)
- "[Foreman] A bad one went through! That comes out of your pay."  (chat message, line 477)

*When:* the foreman counts what went through: skim more than one and he may find it short

- "The foreman's count is %d short. It comes out of your pay, and he'll remember."  (message, line 514)
- "The count was short on your shift"  (text, line 515)

*When:* part of: tick

- "A clean shift: not a single mistake."  (text, line 519)
- "%d of %d bad parts caught; %d good parts through."  (message, line 521)

*When:* Skimming (sv_livingcity_funding.lua): R while holding a good part pockets it. A unit who sees it makes you wanted; and the more you take, the likelier the foreman finds the count short.

- "That one's scrap: nobody would buy it."  (chat message, line 540)

*When:* part of: line skim

- "Into your coat: {name}. The count will be one short."  (chat message, line 546)
- "Theft from the factory floor"  (text, line 548)
- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 549)

*When:* pressing a key

- "You work it open and palm what's inside: {what}."  (chat message, line 565)
- "Theft from the factory floor"  (text, line 567)
- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 568)

*When:* part of: rule lines

- "Papers must be in date."  (text, line 609)
- "The photo must be the bearer."  (text, line 609)

*When:* One traveler's papers, and what's wrong with them (if anything).

- "Anya Vasek"  (text, line 620)
- "Pavel Orlov"  (text, line 620)
- "Mira Kessler"  (text, line 620)
- "Tomas Hrabal"  (text, line 620)
- "Ilse Brandt"  (text, line 620)
- "Jonas Petrov"  (text, line 620)

*When:* part of: start

- "Papers check"  (title, line 687)
- "[Station] Travelers will come to you. E on one to check their papers against today's rules: approve, deny, or call a Civil Protection unit."  (chat message, line 694)

*When:* part of: hud

- "Travelers checked: %d of %d"  (message, line 696)
- "Right: %d    Citations: %d"  (message, line 696)
- "Today's rules:"  (text, line 696)
- "E on the traveler to see their papers"  (text, line 698)

*When:* part of: finish

- "Not a single citation."  (text, line 722)
- "%d of %d calls right."  (message, line 724)

*When:* The call: "approve", "deny" or "unit". True when it was right.

- "A forgery: the seal reads {seal}. A Civil Protection unit takes them away."  (text, line 780)

*When:* part of: papers decide

- "Denied. (The seal was forged: a Civil Protection unit would have wanted to know.)"  (text, line 782)
- "Approved forged papers (the seal read {seal})."  (text, line 786)
- "They walk through. Under their breath: 'Thank you.'"  (text, line 788)
- "Approved papers out of date."  (text, line 793)
- "Approved a traveler whose photo wasn't them."  (text, line 793)
- "Approved entry from {banned}."  (text, line 794)
- "Approved a traveler with no transit permit."  (text, line 794)
- "Approved work travel without a Union stamp."  (text, line 795)
- "Turned away a traveler whose papers were in order."  (text, line 799)
- "Pay docked."  (on-screen notice, line 806)
- "[Station] {note}"  (chat message, line 808)

*When:* part of: start

- "the panel"  (text, line 971)
- "the terminal"  (text, line 972)

*When:* part of: hud

- "Turns: %d (par %d)"  (message, line 981)
- "Blackout: double pay."  (text, line 982)

*When:* the breaker trips: a new board (and paid less)

- "[Maintenance] Too slow: the breaker trips and the board scrambles. Again."  (chat message, line 993)

*When:* part of: wire try

- "Neat work: on par."  (text, line 1044)
- "Blackout rates."  (text, line 1045)
- "Clean: not a spark."  (text, line 1047)

*When:* Triage (Clinic Medic): patients bleeding out at different rates. Treat them with the medkit (primary fire) before they're gone: the worst first.

- "Bleeding badly"  (label, line 1067)
- "Stab wound"  (label, line 1067)
- "Stunstick beating"  (label, line 1068)
- "Broken arm"  (label, line 1068)

*When:* part of: start

- "[Clinic] Patients coming in. Medkit, primary fire. The worst first: they won't all wait."  (chat message, line 1097)

*When:* part of: hud

- "Saved: %d    Lost: %d    Waiting: %d"  (message, line 1099)

*When:* part of: tick

- "[Clinic] You've lost one. {label}."  (chat message, line 1112)
- "[Clinic] You've lost one. {label}."  (chat message, line 1127)
- "[Clinic] He grabs your wrist on the way out. 'Thank you. Please... don't write down what did this.'"  (chat message, line 1135)
- "Everyone walked out."  (text, line 1147)
- "%d saved, %d lost."  (message, line 1148)

*When:* part of: start

- "[Reclamation] Break the pile up (crowbar, primary fire). Each block gives up a bit of scrap."  (chat message, line 1201)

*When:* part of: hud

- "Blocks broken: %d of %d"  (message, line 1202)
- "Crowbar, primary fire"  (text, line 1202)

## the unit's kick (sv_livingcity_kick.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_kick.lua`


*When:* part of: knock out

- "Out cold"  (on-screen notice, line 107)
- "Knocked senseless"  (on-screen notice, line 107)
- "A door, out of nowhere. Everything goes black."  (on-screen notice, line 108)
- "The door catches you on its way down. The room won't keep still."  (on-screen notice, line 108)

*When:* a brush door (a sliding warehouse door, a Combine shutter, a gate) is too big and too heavy: a boot does nothing to it

- "It doesn't budge."  (chat message, line 209)

*When:* part of: kick door

- "It doesn't give."  (chat message, line 216)
- "[Living City] The Overwatch kicked the door of {or}'s apartment off its hinges."  (chat message, line 230)
- "[Living City] Civil Protection kicked in the door of {or}'s apartment."  (chat message, line 266)

*When:* the chat command /kick

- "Only Civil Protection kick doors in."  (chat message, line 352)

*When:* part of: drop door

- "You set the door down."  (chat message, line 374)

*When:* Hung: back on its hinges, and the technician is paid.

- "door rehung"  (text, line 392)

*When:* part of: door rehung

- "Door rehung"  (on-screen notice, line 393)
- "Back on its hinges.{or}"  (on-screen notice, line 393)

*When:* E on a fallen door.

- "Off its hinges. A Maintenance Technician could hang it back up."  (text, line 403)

*When:* part of: use fallen door

- "Rehanging the door..."  (progress bar, line 408)
- "You leave it leaning against the frame."  (text, line 409)
- "Someone already has hold of it."  (text, line 413)
- "The door frame"  (text, line 421)
- "A door to rehang"  (on-screen notice, line 422)
- "Carry it back to the frame it came off (marked), and press E on it there."  (on-screen notice, line 422)

*When:* The city's own crews rehang a door nobody else has (after the players have had their chance).

- "rehanging a door"  (label, line 460)

*When:* part of: find

- "lifting a door"  (what someone is doing, line 477)
- "rehanging a door"  (what someone is doing, line 481)

## the Resistance lab (sv_livingcity_lab.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_lab.lua`


*When:* part of: say

- "[Scientist] {text}"  (chat message, line 46)

*When:* Who runs each lab: Dr. Kleiner, Eli Vance or Dr. Magnusson, a different one at each (the first that isn't at another lab already; any of them again past three labs).

- "Dr. Kleiner"  (name, line 64)
- "Eli Vance"  (name, line 65)
- "Dr. Magnusson"  (name, line 66)

*When:* the Combine's data, decoded here (sv_livingcity_heist.lua)

- "150 XP, 150 credits, and every Civil Protection unit marked for the whole Resistance for ten minutes"  (description, line 203)
- "50 XP, 50 credits, and every Civil Protection unit marked for the whole Resistance for five minutes"  (description, line 204)
- "He looks up from a tangle of wires. "Ah! Yes, hello. What do you need?""  (text, line 217)
- ""Mind the, ah, the jar. What can I make for you?""  (text, line 218)
- "He pushes his glasses up his nose. "Materials, or credits? Either will do.""  (text, line 219)

*When:* part of: use scientist

- "He steps between you and the bench. "I'm terribly sorry, I don't believe we've met. This is a private... laboratory. Please, go.""  (chat message, line 230)
- ""Half a chip? Bring me the other fragment and I'll decode the lot.""  (chat message, line 239)
- ""Is that Combine data? I can decode that. (Decode: at the top of my list.)""  (chat message, line 240)

*When:* Have him make one. how: "mats" (from your pockets) or "pay". True, or false and why not.

- "He only works for the Resistance."  (text, line 249)
- "Find the scientist in the lab."  (text, line 251)
- "You're busy."  (text, line 252)

*When:* part of: lab make

- "He's still working on the last thing."  (text, line 255)
- "He's in the middle of someone else's work (%ds)."  (message, line 256)
- "He wants {price} credits for that. You don't have them."  (text, line 261)
- "the lab"  (text, line 262)
- "You're missing the materials ({mid})."  (text, line 265)

*When:* part of: refund

- "the lab, handed back"  (text, line 284)

*When:* part of: lab make

- ""Credits. Yes. Fine. Give me a moment.""  (chat message, line 290)
- ""Ah, good, good. Let me see what I can do with these.""  (chat message, line 290)
- "The scientist is making your {name}... stay in the lab"  (progress bar, line 291)

*When:* part of: done

- ""There. Do be careful with it." He hands you: {name}."  (chat message, line 300)

*When:* part of: lab make

- "[Scientist] You wander off. He sighs, and hands it all back."  (text, line 304)

*When:* A new face. Papers in a dead man's name don't stop a unit who knows your face; the scientist can change it. Twenty seconds under (stay on the table), lc_surgery_price credits, and you wake with someone else's face, bandaged and slow on your feet for a few minutes. Nobody's looking for that face: your wanted status, any BOLO on you and the scanners' pictures are gone, a wanted notice won't match it, and a Civil Standing below lc_surgery_standing (-50) comes back up to it (the records can't put a name to the face). Get wanted again and they learn the new one.

- "He only works for the Resistance."  (text, line 326)
- ""Surgery? Here? Good heavens, no.""  (text, line 328)
- ""Your face needs to heal first." (%d min)"  (message, line 330)
- "%d credits, and you don't have them."  (message, line 331)

*When:* part of: lab surgery

- "Find the scientist in the lab."  (text, line 349)
- "He's in the middle of someone else's work."  (text, line 351)
- "a new face"  (text, line 353)
- ""Lie down, lie down. You'll feel a little... well. You won't feel anything, actually. Count backwards from ten.""  (chat message, line 357)
- "Under the knife... stay on the table"  (progress bar, line 360)

*When:* part of: done

- "a face the records don't know"  (text, line 376)
- ""There. Nobody will know you. Well, I hardly do. Keep the bandages on a few minutes, and don't run.""  (chat message, line 381)
- "A new face"  (on-screen notice, line 382)
- "Nobody's looking for this face. Your wanted status, any BOLO and the scanners' pictures are gone, and a wanted notice won't match it. Get wanted again and they'll learn this one."  (on-screen notice, line 382)

*When:* part of: cancel

- "the lab, handed back"  (text, line 389)

*When:* part of: lab surgery

- "[Scientist] You sit up too soon. "No, no, no! We'll have to do this another time." He hands your credits back."  (text, line 392)
- "the lab, handed back"  (text, line 397)

*When:* the game answering something done in a window (lc_lab_surgery)

- "[Lab] {why}"  (chat message, line 407)

*When:* the game answering something done in a window (lc_lab_decode)

- "He slots it into a humming console and leans in. "Oh, this is marvellous. Get the word out.""  (chat message, line 415)

*When:* the game answering something done in a window (lc_lab_make)

- "[Lab] {why}"  (chat message, line 425)

*When:* part of: shut lab

- "[Civil Protection] A Resistance lab. The scientist is taken into custody and the equipment smashed. Nothing will be made here for a while."  (chat message, line 443)
- "a Resistance lab shut down"  (text, line 444)
- "Shut down a Resistance lab"  (text, line 445)
- "They found the lab {GetPos}. The scientist's been taken. Nothing comes out of there for a while."  (text, line 449)

*When:* a timer (regularly)

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

*When:* part of: death cause

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

*When:* part of: me

- "\|{GetNW2String}"  (text, line 276)

*When:* Word gets around

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

*When:* part of: tell

- "[Word gets around] {text}"  (chat message, line 355)

*When:* !bob

- "[Living City] The camera sway is off for everyone on this server."  (chat message, line 478)

## Resistance lookouts (sv_livingcity_lookouts.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_lookouts.lua`


*When:* part of: can recruit lookout

- "Only the Resistance asks this of people."  (text, line 36)
- "They don't know you well enough. (Member and up)"  (text, line 37)
- "They wouldn't."  (text, line 39)
- "They're already keeping watch."  (text, line 40)
- "They're afraid of you."  (text, line 41)
- "You already have two people keeping watch."  (text, line 42)

*When:* part of: recruit lookout

- "They nod, and lean against the wall like they've nowhere to be. They'll watch %s for %d minutes. (Freq 7 hears what they see.)"  (message, line 61)

*When:* Freq 7 hears it; whoever posted them always does (a whistle, a runner), radio or not.

- "[Your lookout] {text}"  (chat message, line 69)

*When:* part of: lookout tick

- "The lookout {pos} has gone quiet."  (text, line 104)
- "The lookout {pos} has been stopped by a Civil Protection unit."  (text, line 107)

*When:* (spoken to, or briefly busy: back to the watch, not a reason to stand down)

- "[Resistance] Your lookout {pos} has gone home."  (chat message, line 113)

*When:* part of: lookout tick

- "a Civil Protection unit"  (text, line 119)
- "a Civil Protection unit"  (text, line 119)
- "Lookout {pos}: {what} coming."  (chat message, line 120)

## letters (sv_livingcity_mail.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_mail.lua`


*When:* part of: send letter

- "You don't have that note."  (text, line 115)
- "The post office doesn't know anyone by that name."  (text, line 117)
- "You could just keep it."  (text, line 118)
- "Take it to the post office."  (text, line 119)
- "You hand it over the counter, addressed to {name}. It'll go out with the next round."  (text, line 133)

*When:* part of: deliver letter

- "[Mail] A letter has come for you{or}. It's in your pockets (F2)."  (chat message, line 145)
- "letter delivered"  (text, line 150)

*When:* Civil Protection reads the mail

- "Civil Protection units only."  (text, line 216)
- "The mail's at the post office."  (text, line 217)

*When:* part of: confiscate letter

- "mail inspected"  (text, line 233)
- "Confiscated. It won't arrive. (Posted by {or}.)"  (text, line 235)

*When:* The city's couriers carry real mail when there is some

- "delivering letters"  (label, line 262)

*When:* part of: find

- "collecting the mail"  (what someone is doing, line 273)
- "delivering a letter to {or}"  (what someone is doing, line 277)

## marched to the cells (sv_livingcity_march.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_march.lua`

- "You're struck from behind, and everything goes black. When you come to, you're in a cell."  (text, line 40)

*When:* Taken inside: untied (their things are recorded and kept as on any arrest) and locked up.

- "[Civil Protection] {how}"  (chat message, line 139)

*When:* Got away: still tied, and wanted for it.

- "Free, for now"  (on-screen notice, line 148)
- "Your hands are still tied: F1 > Work at the ties, or have someone cut them."  (on-screen notice, line 148)
- "[Custody] {how}"  (chat message, line 149)
- "Escaping custody"  (text, line 151)

*When:* part of: march to prison

- "[Custody] Cuffed. {or} you to the cells. Charge: {or}."  (chat message, line 193)
- "Under arrest"  (on-screen notice, line 195)
- "You're being walked to the prison. Someone could still get you out on the way."  (on-screen notice, line 195)
- "Civil Protection are marching a prisoner to the cells{or}. Hit them on the way and they're ours."  (text, line 198)
- "Prisoner in transit{or}. Escort to holding."  (text, line 199)
- "Marching %s to the prison (%s)"  (message, line 201)

*When:* part of: march take over

- "[Custody] The unit leading you is down. Another takes your arm before you can run."  (chat message, line 247)

*When:* part of: tick

- "The Civil Protection unit leading you is down."  (text, line 275)

*When:* he's fighting: he lets go of you

- "While they were busy, you slipped away."  (text, line 281)

*When:* there, or as close as he can get (stopped at the doors): through them, and down to the cells

- "They put you in the cell, and the door locks behind you."  (text, line 287)
- "They unlock the prison door, walk you through, and lock you in a cell."  (text, line 288)

## more work you actually do (the engine is sv_livingcity_jobgames.lua) (sv_livingcity_moregames.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_moregames.lua`


*When:* Parcel run (Courier)

- "A heavy little box, taped twice. It smells of gun oil."  (text, line 69)
- "Soft and lumpy, wrapped in newspaper. Something inside sloshes."  (text, line 70)
- "A flat tin, very light. It rattles when you turn it."  (text, line 71)
- "A shoebox tied up with wire. It's warm, somehow."  (text, line 72)
- "Medicine, by the label. The label is in somebody's handwriting."  (text, line 73)
- "Books, by the weight. Nobody has said the word 'books' out loud in years."  (text, line 74)

*When:* part of: parcel way

- "The next parcel"  (text, line 80)

*When:* part of: start

- "Parcel run"  (title, line 85)
- "Three to go, against the clock. Civil Protection units stop couriers they get a good look at: crouch past them, or stand still for the search."  (chat message, line 93)

*When:* part of: hud

- "Parcel %d of %d: %s"  (message, line 98)
- "Watched {heat}"  (text, line 100)
- "SEARCH: stand still (%d), or run"  (message, line 101)
- "A Civil Protection unit is looking at you. Crouch, or get out of sight."  (text, line 102)

*When:* part of: tick

- "Evading a search"  (text, line 113)
- "You ran"  (on-screen notice, line 114)
- "Every Civil Protection unit in the sector has your description now. Get the parcels there anyway."  (on-screen notice, line 114)
- "Carrying contraband"  (text, line 121)
- "A Civil Protection unit opened the parcel. It's evidence now, and so are you."  (text, line 122)
- "The Civil Protection unit turns it over, shakes it, and hands it back. 'Move along.'"  (chat message, line 126)
- "A Civil Protection unit wants to see the parcel. Stand still for the search, or run."  (on-screen notice, line 139)
- "Delivered, {or}. Nobody signs for these."  (chat message, line 146)
- "%d seconds to spare."  (message, line 152)
- "Never stopped once."  (text, line 156)
- "Whatever was in them, it got there."  (text, line 157)
- "You're late. The rest still has to get there."  (chat message, line 164)

*When:* part of: start

- "Records terminal"  (title, line 197)
- "the records terminal"  (text, line 198)
- "Stop the needle in the band (click, or space), four times. When the scanner comes over, keep your hands off the panel."  (chat message, line 214)

*When:* part of: hud

- "Bypassed: %d of %d"  (message, line 216)
- "Seen by the scanner: %d of 2"  (message, line 216)
- "SCANNER OVERHEAD: hands off"  (text, line 217)
- "Scanner coming..."  (text, line 217)

*When:* part of: act

- "Tampering with a Combine terminal"  (text, line 258)
- "The scanner saw you twice: the alarm's going. Get out."  (text, line 259)
- "The scanner's light catches your hands on the panel. Once more and it calls it in."  (chat message, line 264)
- "The scanner never saw a thing."  (text, line 276)

*When:* Dead drop (Resistance): hide it where nobody sees you do it

- "the bin"  (text, line 301)
- "the oil drum"  (text, line 301)
- "the box"  (text, line 302)
- "the crate"  (text, line 302)

*When:* part of: start

- "Dead drop"  (title, line 308)
- "Three places to leave it. E on one, then crouch and keep still. If anyone sees you at it, that one's burned."  (chat message, line 323)

*When:* part of: hud

- "Seen {seen}"  (text, line 325)
- "Places burned: %d of %d"  (message, line 325)
- "Crouch, close to it, to hide it"  (text, line 326)
- "Hiding it... {HIDE_SECS}%"  (text, line 326)
- "E on a hiding place (outlined)"  (text, line 327)

*When:* part of: tick

- "Someone saw you at {lcDropName}. Not that one: try another."  (on-screen notice, line 355)
- "Every place was watched. The message goes home with you."  (text, line 357)
- "Left in {lcDropName}."  (text, line 365)
- "Nobody looked twice."  (text, line 366)

*When:* Searching the dead (Mortuary), before the incinerator

- "Trouser pockets"  (text, line 381)
- "Identity papers, still valid"  (label, line 383)
- "Ration coupons, two days' worth"  (label, line 384)
- "A wedding ring"  (label, line 385)
- "Loose pistol rounds"  (label, line 386)
- "A folded note: a name and an address"  (label, line 387)
- "A data chip, sewn into the hem"  (label, line 388)
- "A photograph of two children"  (label, line 389)

*When:* part of: start

- "Searching the dead"  (title, line 445)
- "Three for the fire tonight. E on the body: every pocket before it goes in. Log it, keep it, or set it aside for the family. The overseer looks in now and then."  (chat message, line 451)

*When:* part of: hud

- "Body %d of %d"  (message, line 453)
- "Logged: %d    Kept: %d"  (message, line 453)
- "The overseer is out of the room"  (text, line 454)
- "E on the body to search it"  (text, line 454)

*When:* part of: tick

- "The door opens. The overseer leans on the frame, watching you work."  (chat message, line 463)
- "The overseer goes back out. You're alone with them."  (chat message, line 465)

*When:* part of: act

- "logged contraband from the dead"  (text, line 483)
- "caught stealing from the dead"  (text, line 489)
- "The overseer clears his throat. 'In the tray.' It goes in the tray, and in his notebook."  (chat message, line 490)
- "%d logged, %d kept."  (message, line 505)
- "The overseer wrote your name down."  (text, line 506)
- "Into the fire. The next one's on the slab."  (chat message, line 510)

*When:* Sorting (Uniform Laundry)

- "a folded note"  (text, line 527)
- "a pistol magazine"  (text, line 527)
- "ration coupons"  (text, line 527)
- "a door keycard"  (text, line 528)
- "a ration bar, half eaten"  (text, line 528)

*When:* part of: start

- "Incident wash (bloodstained)"  (label, line 556)

*When:* part of: hud

- "Uniforms: %d of %d"  (message, line 561)
- "Right: %d    Wrong: %d"  (message, line 561)

*When:* part of: tick

- "The shift ran out with uniforms still on the pile."  (text, line 568)

*When:* part of: act

- "a Civil Protection unit's pocket came back short"  (text, line 580)
- "The supervisor counts what comes out of the pockets. Tonight he counts one short, and looks at you."  (chat message, line 581)
- "turned in what a Civil Protection unit left in a pocket"  (text, line 586)
- "Whatever was in the pocket went in with it."  (chat message, line 596)
- "Not one in the wrong bin."  (text, line 599)
- "%d of %d sorted right."  (message, line 600)

*When:* Filing (Records Clerk)

- "Anya Vasek"  (text, line 618)
- "Pavel Orlov"  (text, line 618)
- "Mira Kessler"  (text, line 618)
- "Tomas Hrabal"  (text, line 618)
- "Ilse Brandt"  (text, line 618)
- "Jonas Petrov"  (text, line 618)
- "Lena Duric"  (text, line 618)
- "Viktor Sorel"  (text, line 619)
- "Hana Novak"  (text, line 619)
- "Emil Strand"  (text, line 619)
- "Katya Lind"  (text, line 619)
- "Oskar Benes"  (text, line 619)
- "Rosa Kalnin"  (text, line 619)
- "Dmitri Arkov"  (text, line 619)

*When:* part of: hud

- "Forms: %d of %d"  (message, line 666)
- "Right: %d    Wrong: %d"  (message, line 666)

*When:* part of: tick

- "Forms left in the in-tray. They'll be there tomorrow."  (text, line 673)

*When:* part of: act

- "caught taking a blank identity form"  (text, line 683)
- "Theft of state forms"  (text, line 684)
- "A Civil Protection unit at the counter watches you put it back."  (chat message, line 685)
- "One blank identity form, folded into your sleeve."  (chat message, line 689)
- "A clean in-tray."  (text, line 703)
- "%d of %d filed right."  (message, line 704)

*When:* Radio repair: a set's trimmer screws, set by ear. Tune it to its station (the dial), then turn the screws with the screwdriver until it comes through clean: the volume trimmer brings the station up, the squelch pushes the static down, the alignment pulls a smeared signal into focus. Sometimes the clearest thing on the band is Freq 7.

- "Volume trimmer"  (text, line 722)

*When:* How right a screw is: 1 on the spot, 0 a third of the range off.

- "'...this is Freq 7. They count the rations and they count you. Count them back...'"  (text, line 731)
- "'...the third shift at the station is short two Civil Protection units on Tuesdays. Freq 7, out...'"  (text, line 732)
- "'...if you can hear this, you are not alone. Freq 7...'"  (text, line 733)
- "'...the Administrator's broadcasts are recorded. She is not in the city. Freq 7...'"  (text, line 734)

*When:* part of: new radio

- "A voice comes through the static, on Freq 7."  (text, line 774)

*When:* part of: radio done

- "Every set on the shelf works."  (text, line 797)
- "%d of %d fixed."  (message, line 798)

*When:* part of: start

- "Radio repair"  (title, line 807)

*When:* part of: hud

- "Set %d of %d"  (message, line 812)
- "Find its station, then the screws: by ear"  (text, line 813)
- "%d seconds on this one"  (message, line 814)

*When:* part of: tick

- "Out of time: it goes back on the shelf, still hissing."  (chat message, line 821)

*When:* part of: act

- "It's there, but so faint you'd miss it. The volume trimmer."  (text, line 859)
- "It's there, under a wall of hiss. The squelch."  (text, line 860)
- "It's there, but smeared across the dial. The alignment."  (text, line 860)
- "reported an illegal broadcast"  (text, line 883)
- "You write the frequency on a slip for the Civil Protection units. Somebody will be listening for it now."  (chat message, line 885)
- "You copy it down where nobody will look: Freq 7, and the seven places on the dial it hides. A Freq 7 sheet, in your pockets (contraband: pass it on, or burn it)."  (chat message, line 891)
- "You tune past it. Nothing on this band is worth what it costs."  (chat message, line 894)

*When:* A Freq 7 sheet, read: the rule, and the seven frequencies it gives.

- "FREQ 7 /  / They only broadcast where the digits add up to seven. There are seven places on the dial: /  / {list} /  / {or}When the Combine find it, it moves: try the next one. /  / Listen low. Never where a unit can hear it."  (text, line 909)

*When:* part of: read item

- "(in a cramped hand)"  (text, line 916)

*When:* part of: listen off

- "[Radio] {why}"  (chat message, line 962)

*When:* Listen (already on: the window again, where you left the dial; it has its own off switch).

- "Not in here."  (text, line 970)

*When:* a timer (regularly)

- "Your radio's gone."  (text, line 1004)

*When:* the pirate band, out loud, where a unit can hear it

- "Listening to an illegal broadcast"  (text, line 1021)
- "A Civil Protection unit heard that"  (on-screen notice, line 1022)
- "Freq 7, out loud, in front of Civil Protection. Turn it off, or run."  (on-screen notice, line 1022)

*When:* Pat-down (Civil Protection)

- "Left pocket"  (text, line 1034)
- "Right pocket"  (text, line 1034)
- "They hold their coat closed with one hand."  (text, line 1036)
- "Their left hand keeps drifting to their pocket."  (text, line 1036)
- "They keep their right side turned away from you."  (text, line 1037)
- "They won't stop tugging their shirt down."  (text, line 1037)
- "They shift their weight off one foot."  (text, line 1038)
- "They hold the bag tight against them."  (text, line 1038)
- "a pistol magazine"  (text, line 1040)
- "a Resistance leaflet"  (text, line 1040)
- "a forged ration card"  (text, line 1040)
- "a data chip"  (text, line 1041)

*When:* part of: verdict

- "They walk off lighter on their feet than they should."  (chat message, line 1067)
- "You hand it back. They don't say thank you; they don't dare."  (chat message, line 1068)
- "Confiscated: {what}. Logged as evidence."  (chat message, line 1074)
- "Detained with nothing on them. Dispatch is not impressed, and neither is the street."  (chat message, line 1085)
- "Every call right."  (text, line 1095)
- "%d searched, %d right."  (message, line 1096)

*When:* part of: start

- "Stop citizens on the street: E on one. Pat them down a place at a time before they lose their nerve. Watch their hands."  (chat message, line 1108)

*When:* part of: hud

- "Searched: %d of %d"  (message, line 1110)
- "Right calls: %d"  (message, line 1110)
- "Their nerve: %s"  (message, line 1111)
- "E on a citizen to stop them"  (text, line 1111)

*When:* part of: use

- "You searched that one already."  (chat message, line 1122)

*When:* part of: act

- "They lose their nerve and bolt."  (chat message, line 1163)
- "One bolted with something on them."  (text, line 1164)
- "%d searched, %d right."  (message, line 1168)

*When:* part of: room

- "Everyone on the floor: E on each of them before they run or get rid of something. Then search the place (E on the furniture)."  (chat message, line 1221)

*When:* part of: start

- "The door's locked. E on it to set the charge, then stand back."  (chat message, line 1239)

*When:* part of: hud

- "Charge set: stand back"  (text, line 1244)
- "E on the door to set the charge"  (text, line 1244)
- "On the floor: %d    Ran: %d    Still standing: %d"  (message, line 1249)
- "Found: %d    Flushed: %d    To search: %d"  (message, line 1250)

*When:* part of: use

- "Found: {what}."  (chat message, line 1278)
- "Ash, and the smell of burnt paper. Too late."  (chat message, line 1280)

*When:* part of: tick

- "Somebody's burning something. Whatever it was, it's gone."  (chat message, line 1313)
- "One of them's out the back."  (chat message, line 1319)
- "Nobody ran, nothing burned."  (text, line 1328)
- "%d on the floor, %d ran, %d found."  (message, line 1329)

## hauling the dead (sv_livingcity_mortuary.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_mortuary.lua`


*When:* Where bodies go Incinerators, then morgue workplaces. Each: { pos, ent, name }.

- "the incinerator"  (name, line 42)
- "the morgue"  (name, line 46)

*When:* part of: cremate

- "The incinerator door clangs shut. The roar takes a while to die down."  (text, line 106)
- "You zip the bag and leave it with the others."  (text, line 106)
- "[Mortuary] {burnt}{or}"  (chat message, line 110)

*When:* part of: start haul

- "That isn't a body."  (text, line 123)
- "Someone else already has hold of them."  (text, line 125)
- "Get closer."  (text, line 126)
- "You take hold of the body by the collar.{or}"  (chat message, line 132)

*When:* let go next to an incinerator, or at the morgue: that's where it stays

- "You let go of the body."  (chat message, line 151)

*When:* E on the incinerator: in goes whoever you're hauling, or a body lying right beside it.

- "the incinerator"  (name, line 167)

*When:* a body cart brought up to it: everything on it goes in

- "The incinerator is roaring. You've nothing to put in it. (Haul a body here: E on a body, or the actions menu.)"  (text, line 176)
- "Bring the body closer."  (text, line 177)

*When:* Drag: the body follows at your heels, by the shoulders.

- "The body snags on something and slips out of your grip."  (chat message, line 189)

*When:* The body cart (Morticians, if they want one): take one at the incinerator or the morgue (F1 > Take a body cart, or !bodycart), let go of a body beside it and it goes on, push it (E on it; E again lets go), and E on the incinerator burns everything on it, paid for each. Four at a time.

- "Body carts are for Morticians."  (text, line 244)

*When:* part of: take body cart

- "You've a cart out already (E on it to push it)."  (text, line 245)
- "Body carts are kept by the incinerator, or at the morgue. Go there for one."  (text, line 246)
- "[Mortuary] A body cart. E on it to push it (E again lets go). Let go of a body beside it and it goes on. Push it to the incinerator and press E on the incinerator."  (chat message, line 261)

*When:* part of: load body cart

- "[Mortuary] On the cart (%d of %d)."  (message, line 277)

*When:* typing in chat

- "[Mortuary] You leave the cart."  (chat message, line 362)

## routes over the map's own nodegraph (sv_livingcity_navgraph.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_navgraph.lua`


*When:* part of: learn ladder

- "Learned a ladder (#%d) from a climb: %s up to %s"  (message, line 616)

## what now? (sv_livingcity_nextstep.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_nextstep.lua`


*When:* { key, text, why, way, urgent }

- "Serve your time"  (text, line 180)
- "You're in custody. It ends when your sentence does (or someone gets you out)."  (text, line 180)
- "Hold on"  (text, line 183)
- "You're down and bleeding out. Someone can press E on you to help."  (text, line 183)

*When:* part of: next step

- "Register at Civil Intake"  (text, line 196)
- "Until you're on the register you get no rations, no job and no room."  (text, line 196)
- "Ask Housing Allocation for a room"  (text, line 199)
- "You're registered. Next, a room: press E on the Housing Allocation terminal."  (text, line 199)

*When:* eating and drinking, before anything else

- "Eat something"  (text, line 205)
- "You're hungry, and you have {food}: F2, then use it."  (text, line 205)
- "Collect your ration"  (text, line 206)
- "You're hungry and your allocation is ready: the dispenser (show your ration card)."  (text, line 206)
- "Buy food at the Commissary"  (text, line 208)
- "You're hungry. %s costs %d credits; you have enough."  (message, line 208)
- "Find something to eat"  (text, line 210)
- "Your next ration is in %d minutes."  (message, line 210)

*When:* part of: next step

- "Until then: search bins, or work a shift for credits."  (text, line 211)
- "Have a drink"  (text, line 215)
- "You're thirsty, and you have {drink}: F2, then use it."  (text, line 215)
- "Find water"  (text, line 216)
- "You're thirsty. A sink or a water machine: press E on it."  (text, line 216)
- "Find your block"  (text, line 220)
- "You live in {or}. It's where you sleep, keep things, and shelter at curfew."  (text, line 220)
- "Finish what you're doing"  (text, line 226)
- "its next step is on your screen, and on F3."  (text, line 226)
- "Get a Union job"  (text, line 229)
- "Jobs pay credits and standing, a shift at a time. F3 > Jobs: pick one."  (text, line 229)
- "Collect your ration"  (text, line 232)
- "Your allocation is ready: the dispenser (show your ration card)."  (text, line 232)
- "Work a shift"  (text, line 235)
- "You're short of credits. F3 has your next shift."  (text, line 235)
- "The Union expects more"  (text, line 237)
- "Idle hands are noticed. Another shift (F3), or a side job (F3); a citizen seen loafing is a citizen asked questions."  (text, line 237)
- "On duty"  (text, line 240)
- "Your directives are on F3. The Commissary issues your supplies."  (text, line 240)

## on the screen, not just in chat (sv_livingcity_notices.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_notices.lua`


*When:* [tag] = how it shows

- "Civil Protection"  (text, line 35)
- "Civil Intake"  (text, line 37)
- "Housing Allocation"  (text, line 37)

*When:* Where each kind of place is, for this person: pos, label (or nil and why not).

- "Civil Protection Commissary"  (text, line 140)
- "Commissary (Civil Protection units are issued supplies here)"  (text, line 142)
- "There's no Civil Protection Commissary in this city yet. Your grenades are topped up when you go on duty. (Staff: Living City Editor > Fixture: Civil Protection Commissary.)"  (text, line 143)

*When:* part of: intake

- "Civil Intake"  (text, line 147)
- "This city has no Civil Intake desk."  (text, line 148)

*When:* part of: housing

- "Housing Allocation"  (text, line 152)
- "This city has no Housing Allocation desk."  (text, line 153)

*When:* part of: home

- "Your block isn't on the map."  (text, line 159)
- "You have no room yet."  (text, line 159)

*When:* part of: lab

- "The lab"  (text, line 163)
- "No cell has a lab yet. (Staff: Living City Editor > Fixture: Resistance lab.)"  (text, line 164)

*When:* Point them at a place by kind. True, or false and why not.

- "[Living City] {label}"  (chat message, line 176)

*When:* a block's middle can be in mid air or between wings: being inside the block is arriving

- ": it's marked on your screen."  (on-screen notice, line 182)

*When:* a timer (regularly)

- "You're here: {or}."  (on-screen notice, line 196)

## the city does its own work (sv_livingcity_npcwork.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_npcwork.lua`

- "fixing a streetlight"  (text, line 489)
- "fixing a loudspeaker"  (text, line 490)

*When:* Sanitation Graffiti gets scrubbed (sv_livingcity_scavenge.lua).

- "scrubbing graffiti"  (label, line 497)

*When:* part of: find

- "scrubbing graffiti"  (what someone is doing, line 511)

*When:* Junk left lying in the street: empty cans and bottles, rags.

- "picking up litter"  (label, line 528)

*When:* part of: find

- "picking up litter"  (what someone is doing, line 541)

*When:* The bin round: the city's bins, one after another, and the bags to the depot.

- "emptying bins"  (label, line 554)

*When:* part of: find

- "emptying the bins"  (what someone is doing, line 562)
- "taking the rubbish to the depot"  (what someone is doing, line 567)

*When:* Mortuary: hauling the dead (sv_livingcity_mortuary.lua)

- "collecting the dead"  (label, line 577)

*When:* part of: find

- "collecting the dead"  (what someone is doing, line 604)
- "taking the body to {name}"  (what someone is doing, line 607)
- "helping someone who's down"  (label, line 631)
- "helping someone who's down"  (what someone is doing, line 646)

*When:* part of: done

- "[Living City] {or}, a Union medic, patches you up enough to stand."  (chat message, line 650)

*When:* A wounded citizen.

- "treating the wounded"  (label, line 658)

*When:* part of: find

- "treating the wounded"  (what someone is doing, line 671)

*When:* Clinic duty: and anyone who comes in gets seen to.

- "on duty at the clinic"  (label, line 677)
- "on duty at the clinic"  (what someone is doing, line 681)

*When:* part of: tick

- "[Living City] The clinic medic sees to you. (+10 health while you stay close)"  (chat message, line 690)

*When:* Ration Production

- "collecting a crate from the dock"  (text, line 831)
- "sealing ration packs"  (text, line 832)

*When:* Factory

- "collecting parts from the dock"  (text, line 836)

*When:* (quiet work at the line: the clanks were heard all over the factory, long after the belt stopped)

- "working the line"  (text, line 840)

*When:* Courier: the mail, door to door

- "collecting the mail"  (text, line 846)

*When:* Intake Processor: luggage, platform to the blocks

- "collecting luggage from the platform"  (text, line 851)
- "on the platform"  (text, line 852)

*When:* Records Clerk

- "filing records"  (text, line 855)
- "collecting the day's papers"  (text, line 857)

*When:* Uniform Laundry

- "running the machines"  (text, line 860)
- "bundling the pressed uniforms"  (text, line 862)

*When:* Reclamation Crew: rubble to the reclamation point

- "clearing rubble"  (label, line 870)

*When:* part of: find

- "clearing rubble"  (what someone is doing, line 882)
- "handing in scrap"  (what someone is doing, line 887)
- "sorting scrap at the yard"  (text, line 891)

*When:* Radio Repair, and Maintenance, when nothing's broken: at the bench, in the yard

- "repairing radios at the bench"  (text, line 894)

*When:* (the radios are on the benches whether anyone's working them or not)

- "at the maintenance yard"  (text, line 900)
- "at the sanitation depot"  (text, line 901)

*When:* Dead headcrabs left lying about: the morgue bags them for the incinerator.

- "bagging dead headcrabs"  (label, line 906)

*When:* part of: find

- "bagging a dead headcrab"  (what someone is doing, line 922)

*When:* Somebody's mess in the street: sanitation scrubs it up (sv_livingcity_hygiene.lua)

- "scrubbing up a mess"  (label, line 928)

*When:* part of: find

- "scrubbing up somebody's mess"  (what someone is doing, line 943)
- "at the morgue"  (text, line 950)
- "sorting the mail"  (text, line 951)

*When:* part of: npcretake screens

- "retaking a hijacked screen"  (text, line 983)
- "retaking a hijacked screen"  (what someone is doing, line 986)

*When:* part of: done

- "[CP net] A Civil Protection unit has the hijacked screen back under control."  (chat message, line 992)
- "[Resistance] They cut the broadcast."  (chat message, line 993)

*When:* In the debug report

- "NPC work: %d at it now; %d started, %d finished, %d dropped. %s"  (message, line 1018)

## clothes that show the job (sv_livingcity_outfits.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_outfits.lua`


*When:* The look this person wears for this job: model, skin, { bodygroup name = value }. key keeps it the same person to person; face is their own face (male_03).

- "\|{jobId}"  (text, line 81)

*When:* The designer (cl_livingcity_outfits.lua)

- "Everyone else (no job)"  (name, line 326)
- "New characters choose from"  (name, line 327)

*When:* What the designer sends back for one job, cleaned up.

- "Admins only."  (text, line 334)
- "No such job."  (text, line 335)

*When:* the game answering something done in a window (lc_outfits_save)

- "[Outfits] {or}"  (chat message, line 369)

*When:* (not "lc_outfits": that name is the on/off setting, and a setting and a command can't share a name)

- "Admins only."  (chat message, line 373)
- "Admins only."  (chat message, line 375)

## path mapping, drawing the walkable network by walking it (sv_livingcity_pathmap.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_pathmap.lua`


*When:* part of: path map step

- "[Path mapping] %d nodes laid this session (%d in the map)."  (message, line 104)

*When:* part of: set path mapping

- "[Path mapping] ON. Walk the places NPCs should be able to go. Noclip, jumping and vehicles pause it. Run lc_pathmap again to stop."  (chat message, line 132)
- "[Path mapping] OFF. %d nodes added and saved (%d in the map). Unlinked ones show red in the editor overlay."  (message, line 137)

*When:* the console command lc_pathmap_undo

- "[Path mapping] Turn it on first; undo removes what this session added."  (chat message, line 152)
- "[Path mapping] Removed the %d nodes added this session."  (message, line 158)

*When:* typing in chat

- "Only editors can map paths."  (chat message, line 164)

## people (sv_livingcity_people.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_people.lua`


*When:* the face first, then a name that goes with it

- "Citizen {id}"  (text, line 201)

*When:* an NPC dying

- "%s (%s) was killed%s"  (message, line 308)
- "by {killer}"  (text, line 308)

*When:* the console command lc_people

- "[Living City] %d citizens and %d Civil Protection units alive (%d out now), %d sympathizers, %d with jobs, %d dead remembered"  (message, line 367)

*When:* the console command lc_resetpeople

- "[Living City] The city's people have been replaced. People already on the streets keep their old faces until they leave."  (chat message, line 386)

## server timing (sv_livingcity_perf.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_perf.lua`


*When:* the console command lc_profile

- "[Living City] Timer timings cleared."  (chat message, line 70)
- "[Living City] Costliest timers (total ms, per call average, worst, calls):"  (chat message, line 75)
- "%-34s %8.1f total  %6.2f avg  %6.2f worst  %d calls"  (message, line 78)
- "NPC loop: %.2f ms average, %.2f worst, over %d runs"  (message, line 83)

## the power grid (sv_livingcity_power.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_power.lua`


*When:* the map's lighting, with the hour of the day (sv_livingcity_atmos.lua tells everyone's game to rebuild it)

- "[City] The grid's gone. The whole city is dark: switch on your flashlight (F)."  (chat message, line 162)
- "[City] The lights come back on across the city."  (chat message, line 163)
- "The whole grid's down. Every Combine door in the city is dead."  (text, line 165)

*When:* part of: transformer down

- "[CP net] Power failure {where}. The district's Combine locks are dead and its forcefields are down. Secure it."  (chat message, line 218)
- "The grid's down {where}. Their doors are open, for now."  (text, line 220)
- "[Union] Power failure {where}. Get the transformer back up (E on it)."  (chat message, line 222)
- "the grid"  (text, line 226)

*When:* part of: transformer restore

- "[CP net] Power restored {where}."  (chat message, line 239)

*When:* E on a transformer: a maintenance technician fixes it.

- "It hums. The district has power."  (text, line 246)
- "Dead, and sparking. You don't know the first thing about it: Maintenance Technicians repair these."  (text, line 248)
- "Rewiring the transformer..."  (progress bar, line 250)
- "You leave it half rewired."  (text, line 251)

*When:* part of: done

- "power restored"  (text, line 254)
- "[Union] The district has power again."  (chat message, line 256)

*When:* A multitool: twelve seconds, and the district goes dark.

- "You need a multitool."  (text, line 263)
- "Look at a transformer."  (text, line 264)
- "It's already dead."  (text, line 265)
- "Shorting the transformer... keep at it"  (progress bar, line 266)
- "You pull back before it blows."  (text, line 267)

*When:* Forcefields

- "You need a multitool."  (text, line 274)
- "Look at a forcefield."  (text, line 275)
- "Shorting the forcefield..."  (progress bar, line 276)
- "The field snaps back."  (text, line 277)

*When:* part of: swipe forcefield

- "Access denied. (Civil Protection units pass; a Combine keycard opens it for a moment.)"  (text, line 295)
- "Unauthorized access"  (text, line 302)

*When:* Emergency crews, eventually.

- "[City] Emergency crews have restored power {GetPos}."  (chat message, line 346)

*When:* The city's own maintenance crews see to it too (after the players have had their chance).

- "restoring power"  (label, line 353)

*When:* part of: find

- "restoring power"  (what someone is doing, line 368)

## prison (sv_livingcity_prison.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_prison.lua`


*When:* part of: say

- "[Living City] {msg}"  (chat message, line 39)

*When:* part of: notify cp

- "[Dispatch] {msg}"  (chat message, line 44)

*When:* Players

- "not a player"  (text, line 87)

*When:* part of: incarcerate

- "no free cell (place more with the editor)"  (text, line 98)
- "You have been incarcerated for %s. Reason: %s"  (message, line 111)
- "none given"  (message, line 111)
- "no reason"  (message, line 112)
- "Jailed %s for %ds: %s"  (message, line 113)

*When:* part of: release prisoner

- "[Civil Protection] Your weapons and radio stay in the evidence locker."  (chat message, line 168)
- "You have been released. Behave."  (chat message, line 173)

*When:* Back in their cell (a unit caught them out of it).

- "[Civil Protection] {msg}"  (chat message, line 185)

*When:* part of: escape

- "Prison escape"  (text, line 197)
- "has escaped custody!"  (text, line 199)
- "You escaped. Every Civil Protection unit in the sector is looking for you."  (chat message, line 201)

*When:* part of: end detention

- "[Civil Protection] Released with a warning. Move along."  (chat message, line 251)

*When:* part of: detain on the spot

- "[Civil Protection] Detained: %s. You're cuffed and made to kneel."  (message, line 273)
- "[Living City] This map has no prison cells yet, so arrests happen on the street. Place cells (and a release spot) with the Living City Editor for real ones."  (chat message, line 277)
- "Detained %s on the street for %ds: %s"  (message, line 279)

*When:* Giving yourself up: walk up to a unit and press E (or !surrender). A shorter sentence, the search called off, and serving it pays back more of your Civil Standing.

- "Not now."  (text, line 307)
- "Civil Protection units don't surrender."  (text, line 308)
- "[Civil Protection] You put your hands up."  (chat message, line 313)

*When:* to a unit NPC: he walks you there (sv_livingcity_march.lua)

- "Nobody's taking you in right now."  (text, line 321)

*When:* typing in chat

- "[Civil Protection] There's no Civil Protection unit close enough to surrender to."  (chat message, line 341)
- "[Civil Protection] {why}"  (chat message, line 344)

*When:* A unit takes someone in: walked to a cell, or cuffed on the street where there's none. (A stunstick hit does it, a hit that would take them under 20 health, or a unit who's run a non-violent suspect down and laid hands on them: sv_livingcity.lua.)

- "Resisting Civil Protection"  (text, line 440)

*When:* Disconnecting doesn't either.

- "disconnected while in custody. Their sentence will resume when they return."  (text, line 483)

*When:* a timer (regularly)

- "Returned mid-sentence"  (text, line 492)
- "You left in the middle of your sentence. It resumes now, with {GetInt} extra seconds."  (chat message, line 495)
- "Absconded from custody"  (text, line 497)

*When:* out, and off home: they don't hang about outside the prison

- "let out of prison, and gone home"  (text, line 526)

*When:* Used by the Arrest Baton on NPC citizens (and by quests): cuffed, then a moment later they're in a cell, the same way an arrested player is.

- "only citizens can be arrested"  (text, line 533)
- "no free cell"  (text, line 535)

*When:* part of: baton may arrest

- "Only Civil Protection can make arrests."  (text, line 559)

*When:* the console command lc_jail

- "Usage: lc_jail <name> [seconds] [reason]"  (chat message, line 581)
- "Administrative detention"  (text, line 584)
- "Couldn't: {err}"  (text, line 585)

*When:* the console command lc_unjail

- "Usage: lc_unjail <name>"  (chat message, line 591)
- "isn't in custody."  (text, line 592)

*When:* the console command lc_prisoners

- "Nobody is in custody."  (chat message, line 604)

## close calls, careers for life, and what passes on (sv_livingcity_progress.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_progress.lua`


*When:* a timer (regularly)

- "A close call"  (on-screen notice, line 108)
- "You wake up in the infirmary, sore and empty-handed: what was in your pockets is gone. You don't remember the fight, or who started it; leave it be. {or}"  (on-screen notice, line 109)

*When:* Careers for life Why this person can't take up another faction (nil if they can).

- "Combine property doesn't choose. Only death ends a stalker."  (text, line 144)
- "The conditioning can't be undone: this person is Overwatch for life. Another character (!characters) can be someone else."  (text, line 147)
- "stepped into the light"  (text, line 171)
- "was taken out of the city by staff"  (text, line 171)

*When:* a timer (regularly)

- "An inheritance"  (on-screen notice, line 197)
- "A relative you barely knew has left you %d credits. It isn't much. It's yours."  (message, line 197)

*When:* Retiring someone

- "Not while you're dead."  (text, line 207)
- "Not while you're wanted."  (text, line 208)
- "Not while you're in custody."  (text, line 209)
- "Not in the middle of a fight."  (text, line 210)
- "A stalker doesn't retire. There's only the one way out."  (text, line 211)

*When:* part of: retire character

- "has left the city for good. Somebody new takes their place."  (text, line 216)

*When:* part of: levy

- "Union levy"  (on-screen notice, line 231)
- "%d credits redistributed: holdings above %d are shared with the Union. Spend it, or lose it slowly."  (message, line 231)

## street furniture, and the city's voice (sv_livingcity_propaganda.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_propaganda.lua`


*When:* part of: start broadcast

- "Someone is already on air."  (text, line 149)

*When:* The Administrator's recorded address (below): the Director of Propaganda can cut in; anyone else waits

- "is on air. The transmitter is hers until she's done."  (text, line 152)
- "The transmitter is cooling down: %d:%02d."  (message, line 157)

*When:* part of: start broadcast

- "[Pirate broadcast] Someone has seized the city's transmitter: {Nick}."  (text, line 165)
- "[City broadcast] {Nick} is on air."  (text, line 166)
- "[CP net] The city transmitter has been seized. Find whoever has the microphone."  (chat message, line 170)

*When:* part of: stop broadcast

- "[Pirate broadcast] The transmission ends."  (chat message, line 191)
- "[City broadcast] Off air."  (chat message, line 191)
- "pirate broadcast"  (text, line 195)
- "pirate broadcast"  (text, line 197)
- "city broadcast"  (text, line 201)

*When:* part of: toggle broadcast

- "off air"  (text, line 209)
- "You need the microphone in your hand."  (text, line 210)

*When:* Taking it off someone tied up, or with their hands up (the actions menu, F1)

- "Look at who has it."  (text, line 265)
- "Get closer."  (text, line 266)
- "They haven't got a microphone."  (text, line 267)
- "Not while they can stop you: hands up, or tied."  (text, line 269)

*When:* part of: take microphone

- "[City] {Nick} takes the microphone off you."  (chat message, line 274)
- "[City] You take the microphone. Left click with it to go on air, when the transmitter's ready."  (chat message, line 275)
- "[CP net] The city microphone has been stolen {GetPos}."  (chat message, line 278)

*When:* Dormant by default until there are enough recordings. Switch on with lc_breen_broadcasts 1 (the lc_breencast command still works for a test).

- "The Administrator"  (text, line 296)

*When:* song: played by the game's music player (sound.PlayFile), which takes an .mp3 or .ogg at any rate: only a file that isn't what its name says matters.

- "empty, or couldn't be read"  (text, line 487)
- "it's really an MP3 named .wav, so nobody hears it: rename it to .mp3"  (text, line 491)

*When:* part of: sound problem

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

*When:* part of: start npcbroadcast

- "Someone is already on air."  (text, line 583)
- "No recordings for {AdministratorName} yet (sound/livingcity/administrator/, named ambient1.wav and so on)."  (text, line 585)
- "[City broadcast] {AdministratorName} addresses the city."  (chat message, line 595)

*When:* part of: stop npcbroadcast

- "[City broadcast] The transmission cuts out."  (chat message, line 617)
- "[City broadcast] Off air."  (chat message, line 619)

*When:* an NPC dying

- "[CP net] {AdministratorName} has been attacked {GetPos}. Secure the microphone."  (chat message, line 642)
- "Attacking the Administrator"  (text, line 644)

*When:* the console command lc_breencast

- "[Living City] {why}"  (text, line 674)

## persistent props (sv_livingcity_props.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_props.lua`


*When:* part of: tell

- "[Living City] {msg}"  (chat message, line 30)

*When:* Make a prop persistent (or, if it already is, save it as it is now).

- "Aim at a prop (one you've spawned)."  (text, line 90)
- "That prop is part of the map already: it's always there."  (text, line 93)

*When:* part of: persist prop

- "That one belongs to the city (dressing, a supply crate, a fixture or a job). Spawn your own."  (text, line 96)

*When:* Moved with the physgun (build mode): saved where it's dropped, frozen again.

- "Moved: the persistent prop is saved where you put it."  (chat message, line 190)

*When:* the game's can tool moment

- "Removed, and taken out of the layout."  (chat message, line 205)

## quests (sv_livingcity_quests.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_quests.lua`


*When:* Reading the world

- "hoarding ration units"  (text, line 141)
- "unauthorized assembly"  (text, line 141)
- "possession of contraband"  (text, line 141)
- "failing a loyalty check"  (text, line 141)
- "breaking curfew"  (text, line 142)
- "anti-civil remarks"  (text, line 142)
- "trading ration units"  (text, line 142)
- "unregistered relocation"  (text, line 142)
- "tampering with a city terminal"  (text, line 143)
- "harboring an anticitizen"  (text, line 143)

*When:* Half-Life 2 has no proper elderly citizen model; these are its older faces.

- "an unregistered radio"  (text, line 151)
- "a stash of ration units"  (text, line 152)
- "Resistance pamphlets"  (text, line 153)
- "a weapons cache"  (text, line 154)
- "The note says only: the canal gate opens at four."  (text, line 161)
- "A child's drawing of a lambda, and an address you memorize and burn."  (text, line 162)
- "Coordinates, and a single word: Ravenholm. You decide not to go."  (text, line 163)
- "A list of Civil Protection unit numbers. Two are crossed out."  (text, line 164)

*When:* part of: describe place

- "near {group}"  (text, line 178)
- "in rebel territory"  (text, line 180)
- "by the prison"  (text, line 182)
- "by the ration line"  (text, line 188)
- "at a checkpoint"  (text, line 189)
- "outside an apartment doorway"  (text, line 190)
- "%d m %s of you"  (message, line 191)
- "somewhere in the city"  (text, line 192)

*When:* Somewhere safe for the Resistance: rebel territory if there is any, else far away.

- "rebel territory"  (text, line 490)

*When:* part of: narrate

- "[{board}] {text}"  (chat message, line 593)

*When:* part of: enter stage

- "the trail went cold"  (text, line 677)

*When:* part of: send state

- "%ds / %ds"  (message, line 741)
- "You can't quite remember what you were doing."  (text, line 753)

*When:* Ticking quests

- "you lost them"  (text, line 780)

*When:* part of: poll

- "out of time"  (text, line 909)
- "nobody left on the job"  (text, line 911)
- "taken into custody"  (text, line 915)

*When:* follow someone: close enough to keep them in sight, far enough not to be noticed

- "you lost them"  (text, line 927)

*When:* suspicion builds while they can see you (or hear you right behind them) and fades while you're out of sight; only a full meter blows it

- "They keep glancing back. Get out of sight."  (quest narration, line 945)

*When:* part of: poll

- "they spotted you"  (text, line 949)
- "you lost them"  (text, line 953)
- "the target is gone"  (text, line 980)
- "Another Civil Protection unit brought them in. Credit shared."  (quest narration, line 986)

*When:* A ration break: rations are out mid-shift, so the job waits (its clock stopped, nothing failing for your being away) till you've had your ration, five minutes are up, or you go back to it. F1 > Take a ration break (or !rationbreak; !back to carry on).

- "You've no shift or job on to step away from."  (text, line 1005)
- "Rations aren't out right now."  (text, line 1006)

*When:* part of: on break

- "[Work] Break's over. Back to it."  (chat message, line 1021)

*When:* the game's living city ration collected moment

- "[Work] Ration in hand. Back to the job: it's waiting where you left it."  (chat message, line 1029)

*When:* the game's living city event started moment

- "Rations are out"  (on-screen notice, line 1037)
- "Your shift can wait: F1 > Take a ration break (it pauses the job till you've had your ration)."  (on-screen notice, line 1037)

*When:* the chat command /rationbreak

- "[Work] You step away for your ration. The job waits (five minutes at most)."  (chat message, line 1044)
- "[Work] {or}"  (text, line 1044)

*When:* the chat command /back

- "[Work] Back to it."  (chat message, line 1047)
- "[Work] You're not on a break."  (chat message, line 1047)

*When:* a timer (regularly)

- "something went wrong"  (text, line 1058)

*When:* Building blocks for templates

- "Decide what to do"  (text, line 1164)

*When:* part of: arrest stage

- "Detain them with the Arrest Baton (right click)"  (text, line 1208)

*When:* part of: build

- "Patrol stop %d of %d, %s"  (message, line 1274)
- "Patrol sweep {GetPos}"  (title, line 1276)
- "Walk the route and be seen. Visibility is the deterrent."  (description, line 1277)
- "Dispatch wants boots on the street. Yours will do."  (text, line 1278)
- "Overwatch reports elevated noncompliance. Show them the uniform."  (text, line 1278)
- "Civil status inspections"  (title, line 1289)
- "Stop %d citizens and %s. Nobody is above suspicion."  (message, line 1290)
- "pat them down"  (message, line 1290)
- "check their papers"  (message, line 1290)
- "Stop %d citizens and pat them down (E on one): release, confiscate or detain"  (message, line 1291)
- "Stop citizens for inspection (walk up and press E)"  (quest step, line 1292)
- "Apprehend citizen {id}"  (title, line 1304)
- "Citizen %s is wanted for %s. An informant has marked them for you."  (message, line 1305)
- "Find citizen {id} (marked)"  (text, line 1307)
- "Citizen %s freezes. Their eyes go to your baton, then to the street behind you."  (message, line 1308)
- "Detain them."  (text, line 1309)
- "Make them name their supplier."  (text, line 1310)

*When:* part of: success

- "They crack. There's {stash} {GetPos}."  (quest narration, line 1313)
- "Seize {stash} (press E)"  (text, line 1317)

*When:* part of: fail

- "They shove past you and run!"  (quest narration, line 1320)

*When:* part of: build

- "Take their ration units and walk away."  (text, line 1323)

*When:* part of: pick

- "The Civil Protection units are warm from their pocket. Nobody will ever know. You will."  (quest narration, line 1328)

*When:* part of: build

- "Let them go."  (text, line 1331)

*When:* part of: pick

- "You look away. They're gone before you look back."  (quest narration, line 1336)

*When:* part of: build

- "Checkpoint duty {GetPos}"  (title, line 1353)
- "Hold the checkpoint. Nobody passes without being looked at."  (description, line 1354)
- "Report to the checkpoint"  (quest step, line 1355)
- "Hold the checkpoint"  (quest step, line 1355)
- "Contraband sweep {GetPos}"  (title, line 1367)
- "An informant reports {kind} hidden around the area. Find all three."  (description, line 1368)
- "Confiscate {kind} (press E)"  (text, line 1370)
- "Disturbance {GetPos}"  (title, line 1382)
- "Reports of a disturbance. Respond quickly."  (description, line 1383)
- "Respond to the disturbance (hurry)"  (quest step, line 1385)
- "Catch the suspect and detain them"  (text, line 1387)
- "Someone breaks from the crowd and runs!"  (text, line 1403)
- "Ration line supervision"  (title, line 1417)
- "Keep order at ration line {g} while Civil Protection units are distributed."  (description, line 1418)
- "Report to ration line {g}"  (quest step, line 1420)
- "The line is restless. A woman at the front is shaking, and the man behind her keeps looking at your hands."  (quest choice, line 1421)
- "Keep order, by the book."  (text, line 1422)
- "Calm the line with a few quiet words."  (text, line 1423)

*When:* part of: success

- "The shaking stops. Somebody actually says thank you."  (quest narration, line 1427)

*When:* part of: fail

- "Someone spits near your boots. The line goes quiet anyway."  (quest narration, line 1429)

*When:* part of: build

- "Pocket a few ration units while nobody's counting."  (text, line 1430)
- "Supervise the distribution (stay near the front)"  (text, line 1434)
- "Reach the infestation"  (quest step, line 1459)

*When:* done when every infested thing in the area is down, not after a set number

- "Clear out every infested thing here"  (quest step, line 1492)

*When:* part of: poll

- "Clear out every infested thing here (%d left)"  (message, line 1495)
- "Area clear"  (text, line 1495)

*When:* a patch of it, gone, and quiet for a while

- "The line holds. This part of the infestation is contained, and nothing will crawl back for a while."  (quest narration, line 1503)
- "Area clear. Nothing will crawl back here for a while."  (quest narration, line 1505)

*When:* part of: build

- "Containment {GetPos}"  (title, line 1509)
- "The infestation has spread past the line. Push it back."  (description, line 1510)
- "Infestation activity at the source. Thin it out before it spreads."  (description, line 1510)

*When:* the ground that was just taken, or the nearest piece of it

- "Move on the rebel-held ground {where}"  (quest step, line 1542)
- "Hold the ground until it's secure"  (quest step, line 1544)

*When:* part of: on done

- "The ground is retaken. Whatever they built here comes down by morning."  (quest narration, line 1547)

*When:* part of: build

- "Retake the block {where}"  (title, line 1550)
- "Anticitizens have taken ground {where}. Clear them out and hold it. Expect them to fight."  (description, line 1551)
- "Neutralize the anticitizens holding it"  (quest step, line 1554)
- "Hold the ground. Stay close; they'll come"  (quest step, line 1578)

*When:* dispatch hears about it, and sends whoever is nearest to look

- "Dispatch: anticitizens gathering {where}. Nearby Civil Protection units, investigate."  (text, line 1581)

*When:* part of: on done

- "The ground is ours. People are already moving in behind you."  (quest narration, line 1599)
- "You held it, but there's no holding it for long."  (quest narration, line 1599)

*When:* part of: build

- "Take ground {where}"  (title, line 1602)
- "We want the ground {where}. Get there and hold it for a minute, and it's ours. The Combine will notice."  (description, line 1603)
- "Get to the ground we want {where}"  (quest step, line 1604)
- "Steal a crate of Union supplies {where} (press E)"  (text, line 1629)

*When:* part of: on done

- "Theft of Union supplies"  (text, line 1633)
- "A Civil Protection unit saw you take it. Run."  (quest narration, line 1634)
- "Nobody saw. Walk, don't run."  (quest narration, line 1636)

*When:* word gets out: units can follow the smuggler on their screens (sv_livingcity_resistanceops.lua)

- "Get it to the Resistance stores in rebel territory"  (text, line 1641)
- "Six meals' worth, into the crate. %d stored now."  (message, line 1644)

*When:* and ammunition, packed under the food

- "There was ammunition packed under the tins. Everyone gets a box."  (quest narration, line 1649)
- "Supply run {where}"  (title, line 1652)
- "The stores are low. The Union keeps food {where}. Take a crate and bring it home."  (description, line 1653)

*When:* part of: build

- "Break open the crate from a contact {where} (press E)"  (text, line 1683)

*When:* part of: on done

- "The crate breaks open. The supplies are in your pockets now. Searches will find them. Don't get stopped."  (quest narration, line 1688)
- "The crate breaks open, but your pockets are full. Make room (F2) and pick the supplies up."  (quest narration, line 1691)

*When:* part of: build

- "Get it home to {homeName}"  (text, line 1695)
- "Get it to the Resistance quartermaster"  (text, line 1695)

*When:* (the supplies; or a whole crate, from before crates were broken open)

- "You got there with empty pockets. Somebody's going to want to know where it went."  (quest narration, line 1702)

*When:* part of: on done

- "Gun parts, and something to clean them with. Make something worth selling."  (quest narration, line 1709)
- "gun run"  (text, line 1711)
- "The quartermaster counts the guns, then counts out sixty credits. 'Same again, soon.'"  (quest narration, line 1713)

*When:* part of: build

- "Parts pickup {where}"  (text, line 1717)
- "Gun run {where}"  (text, line 1717)
- "A smuggler has gun parts for you {where}. Get them home without being searched."  (text, line 1718)
- "A crate of guns {where} needs to reach the Resistance quartermaster. Sixty credits if it gets there."  (text, line 1719)
- "Collect detainee {id} from the Civil Protection unit holding them {place} (walk up to them)"  (text, line 1742)

*When:* the handover; then he's back on his beat

- "The Civil Protection unit nods at the detainee. 'All yours.' He heads back to his beat."  (quest narration, line 1767)

*When:* part of: build

- "Detainee transfer: {id}"  (title, line 1773)
- "A Civil Protection unit is holding citizen {id} {place} and has been called away. Collect the detainee, decide what to do with them, then detain them with the Arrest Baton to send them to the cells."  (description, line 1774)
- "The detainee was flagged by an informant. They swear they've done nothing, and their voice is steady."  (quest choice, line 1777)
- "Process them."  (text, line 1778)
- "Hear them out."  (text, line 1779)

*When:* part of: success

- "Their story holds. The informant owed them money. You note it in the file. It won't matter."  (quest narration, line 1783)

*When:* part of: fail

- "Halfway through, they contradict themselves. You stop listening."  (quest narration, line 1785)

*When:* part of: build

- "Lean on them for names."  (text, line 1786)

*When:* part of: success

- "Two names. You'll see them on a directive soon."  (quest narration, line 1790)

*When:* part of: fail

- "They go silent. Smarter than they look."  (quest narration, line 1792)

*When:* part of: build

- "Detain them with the Arrest Baton (right click) to send them to the cells"  (text, line 1794)

*When:* Overwatch: Protocols    Administrator: Agenda

- "Incursion {GetPos}"  (title, line 1810)
- "Enter anticitizen territory and hold it. Sixty seconds."  (description, line 1811)

*When:* {

- "Enter rebel territory"  (quest step, line 1814)

*When:* part of: build

- "Hold position inside rebel territory"  (text, line 1818)
- "Address the citizens"  (title, line 1832)
- "The people need to hear their Administrator. Go out among them."  (description, line 1833)
- "Go to the plaza"  (quest step, line 1835)
- "Deliver your address"  (quest step, line 1836)
- "The crowd watches you in silence. How do you end it?"  (quest choice, line 1837)
- "Announce additional rations."  (text, line 1838)
- "Remind them of their duty to the city."  (text, line 1842)
- "Declare a curfew. Effective immediately."  (text, line 1846)
- "Review the Civil Protection units"  (title, line 1862)
- "See for yourself that Civil Protection is doing its job."  (description, line 1863)
- "Speak with Civil Protection units (press E)"  (quest step, line 1864)

*When:* Resistance: Operations

- "Supply run"  (title, line 1880)

*When:* part of: build

- "A crate of medical supplies is waiting {GetPos}. Bring it home to {where}."  (description, line 1881)
- "Meet your contact and take the crate (press E)"  (text, line 1883)
- "'Don't thank me. Don't look back, either.'"  (text, line 1883)
- "The crate is heavier than it should be. There's a Civil Protection unit posted at the end of the street."  (quest choice, line 1884)
- "Walk it out in plain sight."  (text, line 1885)
- "Bury it under a coat and some laundry."  (text, line 1886)

*When:* part of: success

- "Nobody looks twice at a tired citizen with laundry."  (quest narration, line 1887)

*When:* part of: fail

- "A Civil Protection unit shouts after you. Run!"  (quest narration, line 1889)
- "Carrying contraband"  (text, line 1890)

*When:* part of: build

- "Hand it to the quartermaster at {where} (press E)"  (text, line 1893)
- "He's already prying the lid up. 'Good. We needed this yesterday.'"  (text, line 1893)
- "Post flyer %d of 3 %s (crouch at the spot)"  (message, line 1906)

*When:* part of: on done

- "A Civil Protection unit saw that."  (quest narration, line 1912)
- "Distributing propaganda"  (text, line 1913)

*When:* part of: build

- "Paper the walls"  (title, line 1918)
- "Three flyers, three places people will see them. Don't get seen putting them up."  (description, line 1919)
- "Plant the charge at the checkpoint (crouch)"  (quest step, line 1931)

*When:* part of: on done

- "The checkpoint goes up in a shower of sparks. Every Civil Protection unit in the sector heard that."  (quest narration, line 1940)

*When:* part of: build

- "Sabotage {GetPos}"  (title, line 1943)
- "Take that checkpoint offline for a while, then get clear."  (description, line 1944)
- "Get clear: reach {where}"  (text, line 1945)
- "Jailbreak: {id}"  (title, line 1961)
- "Citizen {id} was taken last night. They know too much to stay in there."  (description, line 1962)
- "Break them out (press E on them in their cell)"  (text, line 1965)

*When:* part of: on done

- "Aiding an escape"  (text, line 1978)
- "The lock gives. Alarms don't, yet. Move."  (quest narration, line 1979)

*When:* part of: build

- "Get them to {where}"  (text, line 1982)
- "Sound out the neighbors"  (title, line 1995)
- "Find three people who might be ready. Talk to them where Civil Protection can't see."  (description, line 1996)
- "Quietly talk to citizens (press E) away from Civil Protection"  (quest step, line 1997)

*When:* count

- "[Operations] A Civil Protection unit is watching. Not here."  (chat message, line 2000)

*When:* part of: build

- "Dead drop"  (title, line 2015)
- "Meet a contact, then leave a message where it'll be found."  (description, line 2016)
- "Go to the meeting point {GetPos}"  (quest step, line 2018)
- "Wait for your contact"  (quest step, line 2019)
- "Your contact doesn't come. Instead, a child walks past and presses a folded note into your hand."  (quest choice, line 2020)
- "Read it."  (text, line 2021)
- "Burn it unread."  (text, line 2022)

*When:* part of: pick

- "Some things are safer not known."  (quest narration, line 2022)

*When:* part of: build

- "Take the message to the drop {GetPos}"  (text, line 2024)
- "Leave the message {GetPos}"  (quest step, line 2025)
- "Hide the message where nobody sees you do it: E on a hiding place, then crouch and keep still"  (text, line 2026)
- "the civil records terminal"  (text, line 2044)
- "the Combine console"  (text, line 2044)
- "a records terminal"  (text, line 2046)

*When:* one of ours with a record (or whoever did it, if nobody else has one)

- "[Operations] Your record is gone from the Combine's terminals. Somebody of ours did that."  (chat message, line 2058)

*When:* part of: wipe

- "[Operations] {Nick}'s record is gone."  (chat message, line 2059)
- "[Operations] Three names gone from the registers, and the scanner none the wiser."  (chat message, line 2061)

*When:* part of: build

- "Doctor the records"  (title, line 2065)
- "Some of ours are in the Combine's records. Get into {what} {GetPos} and make them disappear."  (description, line 2066)
- "Go to {what} {GetPos}"  (text, line 2068)
- "Get into the terminal: stop the needle in the band, and keep your hands off while the scanner passes"  (text, line 2069)
- "Ambush a patrol"  (title, line 2080)
- "Fighters only. Take down two Civil Protection units and disappear."  (description, line 2081)
- "Take down Civil Protection units"  (quest step, line 2082)
- "Someone on a CP list is hiding {GetPos}. Bring them in."  (description, line 2099)
- "Find the fugitive (marked)"  (text, line 2102)
- "Lead them to {safe}"  (text, line 2112)
- "The ministry"  (title, line 2124)
- "Tend to your flock. The Combine call it contraband. You call it Sunday."  (description, line 2125)
- "A woman catches your sleeve. Her husband was taken last night. She asks you to pray with her, here, in the open."  (quest choice, line 2127)
- "Pray with her where she stands."  (text, line 2128)

*When:* part of: pick

- "You finish the prayer. Then you hear the boots."  (quest narration, line 2132)
- "Unlawful worship"  (text, line 2133)
- "She holds your hand through all of it. Nobody comes."  (quest narration, line 2135)

*When:* part of: build

- "Promise to pray for him tonight, somewhere safe."  (text, line 2138)

*When:* part of: success

- "She nods. It's enough. For now it's enough."  (quest narration, line 2139)

*When:* part of: fail

- "She lets go of your sleeve and doesn't look back."  (quest narration, line 2140)

*When:* part of: build

- "Tend to the wounded with The Blessing"  (quest step, line 2142)
- "Preach the Word (reload) where people can hear"  (quest step, line 2143)

*When:* Citizens: Assignments

- "Collect your ration"  (title, line 2160)

*When:* part of: build

- "Your ration allocation is ready at line {g}."  (description, line 2161)
- "Go to ration line {g}"  (quest step, line 2162)
- "Wait at the front of the line"  (quest step, line 2162)
- "Union work order: sanitation"  (title, line 2173)
- "Clear the litter {GetPos}. A clean city is a compliant city."  (description, line 2174)
- "Pick up the litter (press E)"  (text, line 2176)
- "Give the parcel to her cousin {GetPos} (press E)"  (text, line 2202)
- "'From Kleiner? Tell her I'm fine.' It's not true, and you both know it."  (text, line 2203)
- "A neighbor's errand"  (title, line 2205)
- "Mrs. Kleiner from the third floor has left a parcel in the block, to be carried across the district."  (description, line 2206)
- "Mrs. Kleiner from the third floor needs a parcel carried across the district."  (description, line 2207)
- "Speak to Mrs. Kleiner inside the block (press E)"  (text, line 2209)
- "Speak to Mrs. Kleiner (press E)"  (text, line 2209)
- "'It's only a little parcel. It's gone to the third floor and back already.' She presses it into your hands."  (text, line 2210)
- "The parcel is taped shut. It's light, and something inside slides when you tilt it."  (quest choice, line 2211)
- "Deliver it unopened."  (text, line 2212)
- "Peel back the tape and look."  (text, line 2213)

*When:* part of: success

- "Resistance pamphlets. Your hands are suddenly cold."  (quest choice, line 2215)
- "Deliver it anyway."  (text, line 2216)
- "Hand it to Civil Protection instead."  (text, line 2217)

*When:* part of: pick

- "Hand it to a Civil Protection unit (press E)"  (quest step, line 2220)

*When:* part of: fail

- "The tape tears loudly. Better just deliver it, and fast."  (quest narration, line 2224)

*When:* part of: build

- "the dumpster"  (text, line 2251)
- "the bins"  (text, line 2251)
- "Two people swap a bundle behind {noun}. One has a lambda scratched into his sleeve."  (text, line 2252)
- "Go over to {noun}, casually"  (quest step, line 2253)
- "Something you saw"  (title, line 2303)
- "Neighbors whisper about something going on behind {or}{GetPos}."  (description, line 2304)
- "Watch quietly"  (quest step, line 2307)
- "Report it to a Civil Protection unit."  (text, line 2309)

*When:* part of: pick

- "Tell a Civil Protection unit (press E)"  (quest step, line 2312)

*When:* part of: build

- "Keep it to yourself."  (text, line 2314)

*When:* part of: pick

- "You saw nothing. You'll keep seeing nothing."  (quest narration, line 2318)

*When:* part of: build

- "his doorway"  (text, line 2340)
- "The confused old man"  (title, line 2343)
- "An old man is wandering {GetPos}, asking everyone for directions."  (description, line 2344)
- "Find the old man (marked)"  (text, line 2347)
- "He doesn't remember his block number. He keeps asking for his daughter."  (quest choice, line 2359)
- "Calm him down first."  (text, line 2360)

*When:* part of: success

- "He takes your arm. His hand is light as paper."  (quest narration, line 2361)

*When:* part of: fail

- "He shuffles after you anyway, still asking."  (quest narration, line 2362)

*When:* part of: build

- "Just lead the way."  (text, line 2363)
- "Walk him home to {homeName}"  (text, line 2365)
- "Loyalty check"  (title, line 2378)
- "You've been summoned to a checkpoint for a routine loyalty check."  (description, line 2379)
- "Report to the checkpoint"  (quest step, line 2381)
- "Present yourself to an officer (press E)"  (quest step, line 2382)
- "The officer's mask tilts. Where were you last night, citizen?"  (quest choice, line 2383)
- "Tell the truth."  (text, line 2384)
- "Give a smooth, boring alibi."  (text, line 2385)

*When:* part of: success

- "He waves you through. Boring is safe."  (quest narration, line 2386)

*When:* part of: fail

- "He doesn't buy it."  (quest narration, line 2388)
- "Failing a loyalty check"  (text, line 2389)

*When:* The Infested: Urges

- "Feed on citizens"  (quest step, line 2408)

*When:* part of: build

- "Get close to the living (they'll scatter)"  (quest step, line 2420)
- "Let them see you."  (description, line 2433)
- "Leave the nest. Stay out."  (description, line 2443)
- "Stay out of the infestation zones"  (text, line 2444)

*When:* part of: advance chain

- "[Story] {name}: maybe another time."  (chat message, line 2545)
- "[Story] {name} has ended. {ending}"  (chat message, line 2549)
- "Story %s ended for %s: %s"  (message, line 2550)
- "[Story] {name} continues.{or}"  (chat message, line 2557)
- "[Story] {name} has ended."  (chat message, line 2560)
- "[Story] {name}: that didn't go to plan. You'll get another chance."  (chat message, line 2565)

*When:* part of: check unlocks

- "[Story] Something has changed. Check your board (F3)."  (chat message, line 2580)

*When:* part of: build

- "Housing block inspection: {name}"  (title, line 2725)
- "The raid team is going through {name}. Back them up: stop residents and check their papers, then hold the entrance until it's done."  (description, line 2726)
- "Report to {name}"  (text, line 2728)
- "Breach and search: blow the door, everyone on the floor (E), then search the furniture (E)"  (text, line 2729)
- "Report to {name}"  (quest step, line 2731)
- "Inspect residents of {name} (walk up and press E)"  (text, line 2733)
- "Hold the block until the team is through"  (quest step, line 2738)
- "Dispatch: all units, {name} is under inspection. Nobody leaves without papers."  (text, line 2740)
- "Clear the street, stop %d of %d, %s"  (message, line 2752)
- "Hold the street: anyone still out gets three warnings"  (quest step, line 2753)
- "Curfew enforcement"  (title, line 2755)
- "Curfew is in effect. Walk the streets, move people along, and hold your position until it's quiet."  (description, line 2756)
- "Lockdown: hold the perimeter {GetPos}"  (title, line 2769)
- "Lockdown is in effect. Nobody moves through your sector. Hold it until it lifts."  (description, line 2770)
- "Take up position"  (quest step, line 2771)
- "Hold the perimeter"  (quest step, line 2771)
- "Warn {name}"  (title, line 2784)
- "Civil Protection units are going through {name}. Get there first and tell people to move what they're hiding."  (description, line 2785)
- "Get to {name} before the Civil Protection units do"  (quest step, line 2787)
- "Warn residents (walk up and press E)"  (text, line 2789)
- "Run supplies under curfew"  (title, line 2822)
- "The streets are empty and the Civil Protection units are busy. A contact left a crate {GetPos}. Get it to {toName}."  (description, line 2823)
- "Pick up the crate (press E)"  (text, line 2826)
- "Bring it to {toName}"  (text, line 2827)

*When:* part of: post directive

- "[%s] New: %s. Take it from your board (F3); up to %d of you can work it together."  (message, line 2964)

*When:* whoever got stuck in gets paid; whoever hadn't started hasn't failed; a count left short (residents warned, people stopped) wasn't done

- "it's over, and only %d of %d done"  (message, line 2994)
- "It's over. Good work."  (quest narration, line 2996)

*When:* the game's living city event ended moment

- "it's over before you got there; no harm done"  (text, line 2999)

*When:* part of: send board

- "[Living City] Quests are turned off on this server."  (chat message, line 3018)

*When:* part of: accept posting

- "[Living City] Finish or abandon your current job first."  (chat message, line 3057)
- "[Living City] Take a breath. Next job in {CurTime}s."  (chat message, line 3059)
- "[Living City] That posting is gone."  (chat message, line 3068)
- "[Living City] A stalker does the work it's given, and nothing else."  (chat message, line 3071)
- "[Living City] That job has enough people."  (chat message, line 3078)
- "has joined."  (quest narration, line 3081)
- "[{board}] {title}. {or}"  (chat message, line 3103)
- "Quest accepted: %s [%s] by %s"  (message, line 3105)

*When:* part of: abandon quest

- "left the job."  (quest narration, line 3119)

*When:* part of: resolve choice

- "%s check: rolled %d + %d = %d against %d. %s"  (message, line 3137)

*When:* the console command lcq_startchain

- "[Story] Chains: {ids}. Usage: lcq_startchain <chain> [player]"  (text, line 3189)
- "[Story] Player not found."  (text, line 3191)
- "[Story] {name} is ready on {Nick}'s board (F3)."  (text, line 3196)

*When:* the console command lcq_story

- "[Story] Player not found."  (text, line 3203)
- "[Story] %s: loyalty %d, sympathy %d, corruption %d"  (message, line 3205)
- "counters: {or}"  (text, line 3209)
- "ended ({done})"  (text, line 3211)
- "at {part}"  (text, line 3211)

*When:* the console command lcq_resetstory

- "[Story] Your story has been reset."  (chat message, line 3223)

## habitation block raids (sv_livingcity_raids.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_raids.lua`


*When:* Charge someone with what was found under their name.

- "in {block}"  (text, line 98)
- "Weapons and contraband cache"  (text, line 99)
- "Possession of contraband"  (text, line 99)
- "[Civil Protection] %d contraband item%s found%s under your name. You are wanted."  (message, line 100)
- "Contraband found in your block"  (text, line 101)

*When:* part of: scan

- "[Civil Protection] Block inspection. Stand still and cooperate."  (chat message, line 219)

*When:* part of: finish

- "[Civil Protection] Block inspection complete. %d item%s confiscated."  (message, line 271)
- "[Civil Protection] Block inspection complete. Carry on."  (chat message, line 272)
- "Raid on block %d finished: %d item(s) found"  (message, line 275)

*When:* Pick the block: one with people in it first, else any.

- "A raid is already in progress."  (text, line 282)
- "This map has no housing blocks."  (text, line 284)

*When:* part of: start raid

- "No such block."  (text, line 296)
- "[Civil Protection] Inspection of {block} is under way. Stay in your residence."  (chat message, line 303)

## "ration units are being deducted" (sv_livingcity_rations.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rations.lua`


*When:* part of: dock rations

- "[Rations] You were near {why}{or}. Your next ration allocation is forfeit."  (chat message, line 40)
- "Residents near {why}{or} lose their next ration allocation."  (text, line 47)

*When:* a timer (regularly)

- "a Resistance attack"  (text, line 55)

*When:* part of: found

- "Resistance graffiti"  (text, line 84)

*When:* the game's living city territory grew moment

- "Resistance-held ground"  (text, line 102)

## rebel life (sv_livingcity_rebellife.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rebellife.lua`


*When:* part of: patrol

- "on patrol"  (what someone is doing, line 495)
- "on patrol"  (what someone is doing, line 499)

*When:* At a workbench or the camp table.

- "cleaning a gun"  (text, line 506)
- "going over a map"  (text, line 506)
- "fixing something"  (text, line 506)
- "working at the bench"  (text, line 506)
- "fixing a gun"  (text, line 506)
- "making something"  (text, line 506)

*When:* Going through a crate.

- "going through the crates"  (text, line 514)
- "checking the supplies"  (text, line 514)
- "counting rounds"  (text, line 514)

*When:* Tending a pot.

- "tending the garden"  (what someone is doing, line 522)

*When:* part of: carry

- "fetching supplies"  (what someone is doing, line 536)
- "carrying supplies"  (text, line 541)
- "putting it down"  (what someone is doing, line 541)

*When:* part of: fire

- "warming up by the fire"  (what someone is doing, line 560)

*When:* On a chair, a couch, a bench.

- "taking a break"  (text, line 576)
- "sitting down"  (text, line 576)

*When:* The editor's sit, bench and lean points inside the zone.

- "leaning on the wall"  (what someone is doing, line 590)

*When:* Sleeping on a mattress, a bed, a bunk.

- "turning in"  (text, line 605)

*When:* the zone's on alert: on their feet, facing the trouble

- "on alert"  (text, line 696)

*When:* part of: start errand

- "fewer than three fighters at home"  (text, line 798)
- "nowhere to scavenge"  (text, line 800)
- "out scavenging"  (text, line 812)
- "Rebel scavenging run: %d out of %s toward %s"  (message, line 814)

*When:* part of: deliver

- "%s is back from a scavenging run: %d meal%s for the stores."  (message, line 847)

*When:* part of: rebel errand think

- "keeping out of sight"  (text, line 876)
- "out scavenging"  (text, line 891)

*When:* home, with whatever they found

- "bringing back what they found"  (text, line 927)
- "heading home"  (text, line 927)

*When:* the console command lc_rebel_errand

- "[Living City] Start the city first."  (chat message, line 973)
- "[Living City] No rebel territory on this map."  (chat message, line 980)
- "[Living City] A scavenging run is heading out of the nearest rebel zone."  (chat message, line 982)
- "[Living City] Couldn't send one: {why}"  (text, line 982)

## the Resistance on the street (sv_livingcity_rebels.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rebels.lua`


*When:* still shouting

- "[Resistance] Someone shouts: 'Combine! In the yard!' You've been seen."  (chat message, line 431)

*When:* sent ahead to meet the leader at the job's destination: there, loitering, till the leader turns up

- "[Resistance] {GetNW2String} falls in with you."  (chat message, line 588)

*When:* under fire: guns out, all of them

- "[Resistance] Your squad pull their guns out."  (chat message, line 612)

*When:* Units get something for it.

- "anticitizen neutralized"  (text, line 961)

*When:* part of: units spot rebels

- "Dispatch: armed anticitizen {or}. Civil Protection units engaging."  (text, line 1005)

*When:* purpose: nil for a plain raid on a checkpoint; or an operation with an objective at the target ("heist", "breakout", "ambush", "screen"), worked out in sv_livingcity_resistanceops.lua

- "no rebel territory on this map"  (text, line 1068)
- "nothing of the Combine's to hit"  (text, line 1070)

*When:* part of: start raid

- "no fighters"  (text, line 1088)
- "in the city"  (text, line 1100)
- "Our people are hitting the Combine {where}. Stay clear, or lend a hand."  (text, line 1101)

*When:* dispatch hears about it once they're close

- "Skirmish: rebel raid of %d from %s toward %s"  (message, line 1106)

*When:* part of: plan raid

- "in the city"  (text, line 1121)
- "In about {lead} seconds our people hit the Combine {where}. Anyone who can, back them up."  (text, line 1122)
- "A raid is coming"  (on-screen notice, line 1125)
- "Our fighters hit the Combine {where} in about {lead} seconds. Back them up: the job's on your board (F3)."  (on-screen notice, line 1125)

*When:* part of: start rebel raid

- "a skirmish is already on"  (text, line 1134)

*When:* part of: start sweep

- "no rebel territory on this map"  (text, line 1155)
- "no Civil Protection units"  (text, line 1156)
- "nowhere out of sight to gather a team"  (text, line 1158)
- "no Civil Protection units"  (text, line 1175)
- "rebel territory"  (text, line 1177)
- "Dispatch: sweep team moving into anticitizen territory {where}. Civil Protection units may assist."  (text, line 1178)
- "Combine are moving on our people {where}! Everyone who can fight, get there."  (text, line 1179)
- "Skirmish: Combine sweep of %d into %s"  (message, line 1180)

*When:* part of: plan sweep

- "rebel territory"  (text, line 1200)
- "Dispatch: sweep team moves into anticitizen territory {where} in about {secs} seconds. All available Civil Protection units, assist."  (text, line 1202)
- "A sweep is coming"  (on-screen notice, line 1205)
- "A sweep team moves into anticitizen territory {where} in about {secs} seconds. Join it: the job's on your board (F3)."  (on-screen notice, line 1205)

*When:* part of: end skirmish

- "Dispatch: anticitizen incursion {where} is over. Resume your beats."  (text, line 1256)
- "Dispatch: sweep team withdrawing."  (text, line 1258)
- "Civil Protection units down"  (text, line 1259)
- "They're pulling back. We held."  (text, line 1259)
- "The Combine have pulled back."  (text, line 1259)

*When:* part of: run skirmish

- "raiders down"  (text, line 1272)

*When:* once they're close, dispatch notices and the nearest units respond

- "Armed Resistance fighters are attacking {or}. Civil Protection units nearby are fighting them; anyone else, keep clear."  (text, line 1280)
- "Dispatch: armed anticitizens {or}. All nearby Civil Protection units respond."  (text, line 1281)

*When:* part of: run skirmish

- "Civil Protection units down"  (text, line 1320)
- "territory cleared"  (text, line 1321)

*When:* the console command lc_skirmish

- "[Living City] Start the city first."  (chat message, line 1409)
- "called off"  (text, line 1410)
- "[Living City] Skirmish called off."  (chat message, line 1415)
- "[Living City] Usage: lc_skirmish raid\|sweep\|end"  (chat message, line 1416)
- "[Living City] {kind} started."  (text, line 1417)
- "[Living City] Couldn't start a {kind}: {why}"  (text, line 1417)

*When:* part of: dismiss follower

- "[Resistance] '{GetNW2String}. I'll head back.'"  (chat message, line 1456)

*When:* part of: recruit

- "[Resistance] 'I'm on watch. Find someone else.'"  (chat message, line 1465)
- "[Resistance] They're busy."  (chat message, line 1465)
- "[Resistance] 'Who are you? Get someone who's earned it to ask me.' (Members and up can lead fighters.)"  (chat message, line 1469)
- "[Resistance] You've got {MAX_FOLLOWERS} with you already. Any more and you're a parade."  (chat message, line 1473)
- "[Resistance] {GetNW2String} is with you, and stays with you. They hold their fire until you open up or the Combine do. E on them again to send them home."  (chat message, line 1489)

*When:* pressing E on something

- "[Resistance] The quartermaster looks you over. 'I don't know you. Come back with someone who does.'"  (chat message, line 1535)
- "[Quartermaster] 'What do you need?' (Work: F3. Fighters: E on any of ours here, to bring them along.)"  (chat message, line 1541)
- "[Quartermaster] 'Is that a Combine chip? Don't wave it about. Take it to the lab, the doc will decode it.'"  (chat message, line 1543)

*When:* Orders for the squad (F1 / the C menu, Resistance; or the chat shortcuts !casual, !gunsout, !meet).

- "[Resistance] You've nobody with you."  (chat message, line 1556)
- "[Resistance] Guns away, plain clothes on. They walk like anyone else now. (Shot at, they'll fight.)"  (text, line 1556)
- "[Resistance] They're acting casual already."  (text, line 1556)
- "[Resistance] You've nobody with you."  (chat message, line 1560)
- "[Resistance] Guns out."  (text, line 1560)
- "[Resistance] They're armed and ready already."  (text, line 1560)

*When:* the chat command /meet

- "[Resistance] You've nobody with you."  (chat message, line 1564)
- "[Resistance] Meet you where? Take a job first: they go on ahead to where it's taking you."  (chat message, line 1566)
- "[Resistance] 'We'll meet you there.' They go on ahead, acting casual, and wait for you near the job's marker."  (chat message, line 1576)

*When:* What a lookout sees coming: warn (a shout, and Freq 7) when the Combine is in sight on the way; open fire when they're close, or on our ground.

- "at a lookout post"  (text, line 1616)

*When:* part of: post warn

- "%s on lookout %s: Combine coming%s!"  (message, line 1618)
- ", the city's own"  (message, line 1619)
- "[Resistance] Someone shouts from up ahead: 'Combine! Coming in!' You've been seen."  (chat message, line 1621)

*When:* an NPC dying

- "We lost the lookout {or}. Someone will take the post, give it time."  (text, line 1707)
- "They got the quartermaster. Someone will take his place, give it time."  (text, line 1756)

## the Resistance's operations, and what the city does about them (sv_livingcity_resistanceops.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_resistanceops.lua`


*When:* part of: hack door

- "You need a multitool for that. (The Resistance's Hackers carry one; the black market sells them.)"  (text, line 103)
- "You're busy."  (text, line 105)
- "Look at a locked Combine door, up close."  (text, line 109)
- "Hacking the lock... keep at it"  (progress bar, line 112)
- "You pull the wires out. It stays shut."  (text, line 113)

*When:* part of: done

- "[Resistance] The lock gives. Thirty seconds before it shuts again."  (chat message, line 118)
- "[CP net] Door breach {GetPos}. A Combine lock has been tampered with."  (text, line 120)
- "Tampering with a Combine lock"  (text, line 123)

*When:* Prison breaks

- "[Resistance] The cell door slams open. "Move. Now." You're out, and wanted."  (chat message, line 167)
- "is out. Get them home."  (text, line 169)
- "prison break"  (text, line 170)

*When:* part of: prison break alarm

- "[CP net] PRISON BREAK {pos}. Anticitizens are at the cells. All Civil Protection units respond."  (text, line 176)

*When:* Smugglers on a supply run

- "[CP net] Union supplies stolen. The smuggler's on the move: follow the SMUGGLER marker."  (text, line 199)

*When:* Arrested or killed with the crate: stopped.

- "[CP net] The smuggler is down. Supplies recovered."  (text, line 220)

*When:* part of: inform

- "You're a Civil Protection unit: arrest them."  (text, line 242)
- "Inform on your own? No."  (text, line 243)
- "Look at who you want to report (or !inform <name>)."  (text, line 244)
- "Civil Protection has your last report. (%ds)"  (message, line 245)

*When:* seen doing it? A Resistance member who watches you talk to the Combine remembers.

- "saw {Nick} informing to the Combine. Traitor."  (text, line 255)

*When:* part of: inform

- "citizen {GetNW2String}"  (text, line 262)
- "[CP net] Informant tip: {who} is a suspected anticitizen, {GetPos}. Outlined for 60 seconds."  (text, line 263)
- "Informant tip: suspected anticitizen"  (text, line 266)
- "informant's reward"  (text, line 267)
- "useful information"  (text, line 268)
- "[Civil Protection] Your report has been received. The Union thanks you."  (chat message, line 269)
- "a false report"  (text, line 271)
- "[Civil Protection] Your report was checked. It was false. Don't waste our time."  (chat message, line 272)

*When:* Hijacking a city screen

- "Citizens of City 17. They count your rations, your words, your children. Count theirs."  (text, line 283)
- "The Combine are not invincible. Every Civil Protection unit you see is a man in a mask. Remember that."  (text, line 284)
- "Lambda lives. Help is closer than you think."  (text, line 285)
- "Their cameras are blind tonight. Look out for one another."  (text, line 286)

*When:* part of: hijack start

- "[CP net] A city screen {where} has been hijacked. Get there and cut it (E on the screen)."  (text, line 295)

*When:* a timer (regularly)

- "[Broadcast interrupted] {i}"  (chat message, line 302)
- "Resistance broadcast"  (text, line 310)
- "[City] The Resistance's message ran for a full minute. People are talking."  (chat message, line 312)
- "screen hijack"  (text, line 313)

*When:* part of: hijack screen

- "You need a multitool to wire into it."  (text, line 321)
- "Look at a city screen."  (text, line 322)
- "It's already ours."  (text, line 323)
- "You're busy."  (text, line 324)
- "Wiring into the screen... keep at it"  (progress bar, line 325)
- "You pull the wires. The screen goes back to the Combine."  (text, line 326)

*When:* part of: done

- "[Resistance] You're in. One minute: keep Civil Protection units off it."  (chat message, line 329)

*When:* part of: cut hijack

- "hijacked screen cut"  (text, line 340)
- "[CP net] The hijacked screen is back under control."  (text, line 341)
- "[Resistance] They cut the broadcast."  (chat message, line 342)

*When:* Overwatch drops

- "a drop is already down"  (text, line 369)

*When:* part of: start overwatch drop

- "nowhere to land"  (text, line 374)
- "[CP net] Overwatch reinforcements inbound {where}. Secure the landing zone."  (text, line 378)
- "Dropship inbound {where}. Overwatch soldiers. Hit them on the ground, or keep clear."  (text, line 380)
- "Overwatch soldiers are landing {where}."  (text, line 381)

*When:* on foot, from out of sight, at a run

- "No dropship: they're coming in on foot {where}."  (text, line 436)

*When:* The Overwatch Commander calls a squad in: to the landing zone nearest them (or where they stand), one every fifteen minutes.

- "Only the Overwatch Commander can call in a squad."  (text, line 459)
- "The next squad can be called in %d:%02d."  (message, line 463)

*When:* part of: commander drop

- "A squad is already down."  (text, line 465)
- "The dropship can't come: {d}."  (text, line 471)

*When:* the chat command /dropship

- "Squad inbound"  (on-screen notice, line 480)
- "A dropship is on its way with an Overwatch squad. Secure the landing zone."  (on-screen notice, line 480)
- "No squad"  (on-screen notice, line 482)

*When:* part of: drop tick

- "The landing party is down. Good work."  (text, line 493)
- "[CP net] The Overwatch landing party is lost."  (text, line 494)

*When:* part of: achieve

- "Our fighters got into the Combine's systems: Civil Protection unit positions for everyone, five minutes. Move."  (text, line 526)
- "[CP net] Data stolen from a Combine terminal {target}."  (text, line 527)
- "Our fighters hit the landing zone."  (text, line 533)

*When:* and food for the stores at home

- "Our fighters got into the supply drop: %d load%s gone, and food for the stores."  (message, line 544)
- "Our fighters hit the supply drop. Cleaned out already."  (text, line 545)
- "[CP net] Anticitizens looted the supply drop {target}."  (text, line 546)

*When:* part of: op tick

- "[CP net] DATA BREACH {target}. Armed anticitizens at a Combine terminal."  (text, line 565)

*When:* part of: launch op

- "a Combine data terminal"  (text, line 592)
- "the prison"  (text, line 592)
- "a city screen"  (text, line 592)
- "the landing zone"  (text, line 592)
- "the supply drop"  (text, line 592)
- "Our fighters are going for {or} {target}. Lend a hand."  (text, line 593)

*When:* Union foremen

- "Foremen are citizens."  (text, line 656)
- "The Union only makes Trusted citizens foremen (150 Civil Standing)."  (text, line 657)

*When:* part of: become foreman

- "[Union] You're a foreman now. !assign <name> hands a citizen a work order; you take a cut of their pay."  (text, line 660)
- "[Union] You hand back your foreman's armband."  (text, line 660)

*When:* part of: assign work

- "You're not a foreman (!foreman)."  (text, line 664)
- "Assign it to another citizen."  (text, line 665)
- "is already working."  (text, line 666)
- "No work orders to hand out."  (text, line 673)
- "Nothing to send them to right now."  (text, line 675)
- "(from foreman {Nick})"  (title, line 678)
- "can't take it right now."  (text, line 682)
- "[Union] Foreman {Nick} has given you a work order: {title}. It's on your board (F3)."  (chat message, line 685)
- "[Union] Work order handed to {Nick}."  (text, line 686)

*When:* the game's living city quest complete moment

- "foreman's cut"  (text, line 692)

*When:* part of: settle vort

- "The vortigaunt is home. Ask it (E) and it will charge your vest."  (text, line 713)

*When:* A freed vortigaunt charges your vest when you ask it (E), not by itself (not while you sleep beside it): once every lc_vort_charge_minutes.

- "The vortigaunt looks at you, and through you."  (text, line 751)
- ""You wear no vessel for the vortessence, friend." (You've no powered vest on.)"  (text, line 752)
- ""Your vessel is full." (Your vest is fully charged.)"  (text, line 753)

*When:* part of: vort charge

- ""The vortessence needs time to gather." (%d min)"  (message, line 756)
- "The vortigaunt's hands glow green, and your vest hums with charge."  (text, line 761)

*When:* pressing E on something

- "[Vortigaunt] {msg}"  (chat message, line 769)

## escalation (sv_livingcity_response.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_response.lua`

- "Sector-wide search"  (text, line 32)
- "Overwatch response"  (text, line 32)

*When:* part of: dispatch squad

- "Overwatch squad of %d dispatched after %s"  (message, line 135)

*When:* part of: escalate

- "Alert {level}"  (text, line 142)

*When:* every unit in the sector, guns drawn

- "[Overwatch] Alert 2: every Civil Protection unit in the sector has your description. They've drawn their weapons."  (chat message, line 151)
- "Dispatch: all units, suspect {Nick} is armed and dangerous. Weapons free."  (text, line 152)

*When:* part of: escalate

- "[Overwatch] Alert 3: Overwatch has been dispatched. Lethal force is authorized."  (chat message, line 154)
- "Overwatch soldiers have been sent after {Nick}, who is armed and dangerous. Lethal force is authorized. Keep clear."  (text, line 156)
- "[Overwatch] Alert 4: a second squad, and the sector is locked down."  (chat message, line 160)

*When:* part of: demote for civilian kill

- "[Resistance] You killed one of the people you fight for."  (chat message, line 231)
- "killed a civilian"  (text, line 232)

*When:* an NPC dying

- "Murder of a Civil Protection officer"  (text, line 250)
- "killed a Civil Protection unit"  (text, line 251)
- "Murder of an Overwatch soldier"  (text, line 254)
- "killed a soldier"  (text, line 255)
- "Destroying city property"  (text, line 257)
- "destroyed a scanner"  (text, line 258)
- "killed a citizen"  (text, line 262)

*When:* lying low; rebel territory cools you off twice as fast

- "[Overwatch] The search for you has been called off."  (chat message, line 299)
- "[Overwatch] The search is winding down. Alert {AlertLevel}."  (chat message, line 300)

*When:* pcall

- "a response squad going back"  (text, line 319)

*When:* the console command lc_setalert

- "set by staff"  (text, line 337)

*When:* the game's living city data breach moment

- "master terminal breach"  (text, line 417)
- "data breach"  (text, line 417)

## sleep (sv_livingcity_rest.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rest.lua`


*When:* Sleep in a bed. True, or false and why not. You lie still (you can't move) till you press Jump.

- "There's no bed here."  (text, line 77)
- "You're not tired, and it's broad daylight. Beds are for the night (or when you're exhausted)."  (text, line 78)
- "You slept already. You couldn't sleep again if you tried."  (text, line 79)

*When:* Up again: Jump, or hurt. Before the sleep's done, it doesn't count.

- "You wake with a start. You've not slept."  (chat message, line 96)
- "You get up before you've really slept."  (chat message, line 96)

*When:* part of: sleep step

- "Well rested"  (on-screen notice, line 124)
- "A night's sleep, and you're healed. For the next day: hunger and thirst come on more slowly, and you heal a little. Press Jump to get up."  (on-screen notice, line 124)

*When:* part of: rest tick

- "You haven't slept in a day. Your eyes keep closing, you can't run, and you're weaker. Find a bed at night (F1 > What now? > Places)."  (on-screen notice, line 189)

*When:* What now? (sv_livingcity_nextstep.lua)

- "Get some sleep"  (text, line 232)
- "You're exhausted: no running, and weaker until you've slept. Find a bed and press E on it."  (text, line 232)

## talking, knowing each other, and going down (sv_livingcity_rp.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_rp.lua`


*When:* part of: description

- "A masked Civil Protection unit"  (text, line 109)
- "An Overwatch soldier"  (text, line 111)
- "A shackled vortigaunt"  (text, line 113)
- "in Resistance gear"  (text, line 118)
- "in Union blue"  (text, line 118)
- "in Resistance gear"  (text, line 119)
- "in Union blue"  (text, line 119)
- "A {Gender} {clothes}"  (text, line 120)

*When:* part of: name for

- "citizen {alias}"  (text, line 138)

*When:* part of: set description

- "Description cleared: people see your clothes and build."  (text, line 149)
- "A little more than that (8 characters at least)."  (text, line 151)
- "Shorter, please (120 characters at most)."  (text, line 152)
- "People who don't know you now see: {text}"  (text, line 156)

*When:* a stalker has no words left (sv_livingcity_custody.lua): only the sound comes out

- "screams: a strained, wordless noise."  (text, line 217)

*When:* a unit saying one of the mask's lines word for word: heard in its voice too (sv_livingcity_cp.lua)

- "says: "{text}""  (text, line 226)

*When:* part of: speak

- "yells: "{text}!""  (text, line 228)
- "whispers: "{text}""  (text, line 230)
- "** {name} {text}"  (text, line 232)

*When:* part of: recognize

- "** {Description} introduces themselves as {Nick}."  (text, line 265)
- "Look at someone (or /recognize all, for everyone close enough to hear)."  (chat message, line 269)
- "They already know who you are."  (chat message, line 269)
- "You tell %d %s your name."  (message, line 271)

*When:* always available, whatever the chat mode

- "Your description: {Description}  (/chardesc <text> to change it, /chardesc clear to reset)"  (chat message, line 289)

*When:* global out of character

- "Global OOC is off on this server. /looc talks out of character to people nearby."  (chat message, line 304)
- "Wait %ds before OOC again."  (message, line 306)

*When:* typing in chat

- "** {l} rolls {n} out of {max}."  (text, line 320)
- "The dead don't talk."  (chat message, line 329)

*When:* a command nobody knows: don't say it out loud

- "Unknown command. Chat: /me /it /y /w /looc // /roll /recognize /chardesc{or}"  (chat message, line 343)
- "The dead don't talk. (// for OOC.)"  (chat message, line 347)

*When:* part of: go down

- "[Living City] You're down, bleeding out. Someone can help you up (E on you). Hold on, or F1 > Give up."  (chat message, line 432)

*When:* part of: revive

- "[Living City] {by} gets you back on your feet."  (text, line 473)
- "[Living City] You get back on your feet."  (chat message, line 473)

*When:* credited to whoever put them down (the conduct system judges that kill)

- "[Living City] {why}"  (chat message, line 492)

*When:* A unit cuffs a wanted person where they lie.

- "Arrested while incapacitated"  (text, line 513)

*When:* part of: help downed

- "Cuffing them..."  (text, line 524)
- "Bandaging the wound..."  (text, line 524)
- "Stopping the bleeding with your hands..."  (text, line 524)
- "You leave them."  (text, line 526)

*When:* part of: done

- "You cuff them where they lie. They'll live long enough for a cell."  (chat message, line 531)
- "You get them back on their feet."  (chat message, line 539)

*When:* hitting someone who's down finishes them

- "They finished what they started."  (text, line 559)

*When:* someone tied up: walked along instead (sv_livingcity_cp.lua)

- "You let go."  (chat message, line 572)

*When:* part of: toggle drag

- "Look at someone who's down, up close."  (text, line 577)
- "You take hold and drag. (F1 > Drag them along again to let go.)"  (chat message, line 580)

*When:* a timer (regularly)

- "You bled out."  (text, line 591)

*When:* typing in chat

- "You let go."  (text, line 626)
- "You're not down."  (chat message, line 626)

## running in front of Civil Protection (sv_livingcity_running.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_running.lua`


*When:* A shout from a unit: chat, and the words across the middle of the screen.

- "[Civil Protection] {or}{text}"  (chat message, line 44)

*When:* Why the cops wouldn't shout at this player, or nil if they would.

- "dead or in a vehicle"  (text, line 78)
- "build mode"  (text, line 79)
- "a Civil Protection unit"  (text, line 80)
- "a stalker (Combine property)"  (text, line 81)
- "in a convincing uniform"  (text, line 82)
- "already wanted"  (text, line 84)

*When:* part of: exempt why

- "in custody"  (text, line 85)
- "being stopped"  (text, line 86)
- "Overwatch or the Administrator"  (text, line 87)
- "in rebel territory"  (text, line 88)

*When:* told to hurry home: running is what they want

- "curfew grace period"  (text, line 90)

*When:* For the debug report: would a unit shout at this player right now, and if not, why not.

- "off (lc_running_cops 0)"  (text, line 113)
- "city not running"  (text, line 114)
- "speed %d (walk %d, run %d)%s, %s, %s"  (message, line 119)

*When:* part of: running status

- "exempt: {why}"  (text, line 120)
- "not exempt"  (message, line 120)
- "Civil Protection unit watching at {GetPos}"  (text, line 121)
- "no Civil Protection unit in sight within {GetInt}"  (text, line 121)

*When:* part of: chase

- "I said stop running!"  (text, line 128)
- "[Civil Protection] You ran from a Civil Protection unit. Units are after you. Press E on one to give yourself up."  (chat message, line 129)
- "Fleeing Civil Protection"  (text, line 130)

*When:* part of: warn

- "Stop running!"  (text, line 139)

## salvage, bins anywhere, the reclamation point, and workbenches (sv_livingcity_salvage.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_salvage.lua`


*When:* What it is, to say so: "Prying the radiator apart".

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

*When:* part of: junk at

- "the junk pile"  (text, line 113)

*When:* The noise: units near enough hear it, and a unit on the street comes to look.

- "[CP] Metal being pried apart{or}. Unauthorised salvage?"  (chat message, line 144)

*When:* part of: salvage

- "Civil Protection units don't pick through junk."  (text, line 171)
- "You're busy."  (text, line 172)
- "Look at some junk: a wreck, a radiator, pipes, a crate."  (text, line 174)
- "You'll need a crowbar out to get anything off that."  (text, line 175)
- "Stripped already. Nothing left worth taking, for now."  (text, line 179)
- "Prying {or} apart... keep at it"  (progress bar, line 183)
- "You leave it."  (text, line 184)

*When:* part of: done

- "Salvaged: {got}."  (text, line 198)
- "Nothing worth keeping in it."  (chat message, line 198)

*When:* part of: rebel guard

- "[Rebel] Hey! Those are our supplies. Quit it."  (chat message, line 277)
- "[Rebel] I won't say it again. Put it down and walk away."  (chat message, line 278)
- "[Rebel] A hard shove back out of it. Go."  (chat message, line 284)
- "[Rebel] A fist in the ribs. Last chance."  (chat message, line 285)
- "[Rebel] That's it."  (chat message, line 289)

*When:* a timer (regularly)

- "Carrying a weapon (a crowbar)"  (text, line 320)
- "[Civil Protection] A Civil Protection unit saw the crowbar in your hand. That's a weapon."  (chat message, line 321)

*When:* Reclamation

- "Civil Protection units don't hand in scrap."  (text, line 364)

*When:* part of: reclaim

- "[Reclamation] Quota met for now. Come back later."  (text, line 372)
- "[Reclamation] Scrap metal, empty cans and bottles only."  (text, line 385)
- "materials returned to the Union"  (text, line 389)
- "[Reclamation] The Union thanks you. (The cell could have made something of that.)"  (chat message, line 392)
- "[Reclamation] The Union thanks you for your contribution."  (chat message, line 394)

## flying a scanner from a Combine console (sv_livingcity_scanner.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_scanner.lua`


*When:* part of: can link scanner

- "The console is dead. (Scanner links are off on this server.)"  (text, line 69)
- "You're already linked."  (text, line 71)
- "ACCESS DENIED. Civil Protection credentials required."  (text, line 72)
- "Someone's already on this console."  (text, line 74)

*When:* never inside a wall: somewhere with room near there, or over the console

- "The console flickers. Nothing answers."  (text, line 168)

*When:* part of: start scanner link

- "[Scanner link] You're in the scanner. WASD to fly, Space and Ctrl up and down, Shift faster, left click to flash, R (or E, or F1 > Disconnect) to disconnect."  (chat message, line 180)
- "[Scanner link] Flash a Civil Protection unit and it's %d more seconds on your sentence."  (message, line 182)

*When:* part of: end scanner link

- "[Scanner link] {why}"  (chat message, line 196)

*When:* a timer (regularly)

- "Link closed."  (text, line 208)

*When:* the signal only reaches so far

- "[Scanner link] Signal weak. Turn back."  (chat message, line 240)

*When:* part of: scanner flash

- "[Prison] You flashed a Civil Protection unit through the scanner. %d more seconds on your sentence (%d:%02d left)."  (message, line 322)
- "Interfered with a Civil Protection unit through a city scanner, from custody"  (text, line 325)

*When:* Who's worth a report, and what it's worth to the one who sends it.

- "Father Grigori"  (text, line 346)
- "a free vortigaunt"  (text, line 347)

*When:* part of: scanner suspect

- "a wanted citizen"  (text, line 350)
- "someone on rebel ground"  (text, line 352)
- "an anticitizen"  (text, line 354)
- "a free vortigaunt"  (text, line 360)

*When:* a jammer near the scanner: the picture's taken, but it never reaches anyone

- "[Scanner link] Interference. The picture doesn't go through: something nearby is jamming the signal."  (chat message, line 446)

*When:* part of: scanner photo

- "A scanner's flash. You've been photographed, and Civil Protection has the picture."  (chat message, line 467)
- "Photographed by a city scanner: {label}"  (text, line 468)

*When:* rebel ground, where the camera's pointed

- "rebel ground"  (text, line 479)

*When:* the report: every unit on duty gets it, with the subjects lit up

- "a scanner run from custody"  (text, line 489)
- "scanner {Nick}"  (text, line 489)
- "[CP net] Scanner report from %s: %s%s. Subjects highlighted for %ds."  (message, line 490)

*When:* part of: scanner photo

- "SCANNER: rebel ground"  (name, line 495)

*When:* the city's own units act on it too: hunted people, and the wanted, near enough

- "Father Grigori"  (label, line 501)
- "a wanted citizen"  (label, line 501)

*When:* a Scanner Operator's photographs: XP (the same cap as a snitch's standing), and a rebel caught on camera goes out to every unit as a BOLO

- "scanner report"  (text, line 515)

*When:* part of: scanner photo

- "Photographed by a city scanner as a rebel{or}"  (text, line 520)
- "[Scanner link] Report filed: %s.%s"  (message, line 523)
- "[Scanner link] Report filed: %s. Civil Standing %+d.%s"  (message, line 530)
- "Your sentence stands."  (message, line 531)
- "[Scanner link] Report filed: {parts}. The city has had enough from you for now; no more standing for a while."  (chat message, line 533)
- "[Scanner link] Report filed: {parts}."  (chat message, line 536)

*When:* hurt, however it happened (some damage never reaches the hook below)

- "Something hits you. You pull out of the link."  (text, line 619)
- "The link drops."  (text, line 621)

*When:* sentence served: the release has already walked them out

- "Time's up. The console goes dark."  (text, line 624)
- "The console is gone."  (text, line 626)

*When:* part of: operator link

- "Scanner Operators only (F4: Civil Protection, Scanner Operator)."  (text, line 664)
- "Get to a terminal: a Combine console, a data terminal, or anywhere in the Nexus."  (text, line 666)

*When:* the chat command /scanner

- "Scanner link"  (on-screen notice, line 674)

*When:* a timer (regularly)

- "Something hits you. You pull out of the link."  (text, line 680)

*When:* released or not, nobody walks out of the cell still flying

- "Time's up. The console goes dark."  (text, line 687)

*When:* Out of the link by chat or console, whatever the keys are doing.

- "Link closed."  (text, line 694)
- "Link closed."  (text, line 698)

## getting by (sv_livingcity_scavenge.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_scavenge.lua`


*When:* A few seconds of doing something, keeping still

- "You're busy."  (text, line 56)

*When:* a fridge at home is yours: your stash, like the stove (not a rummage through someone else's)

- "[Home] Your fridge: your stash is in your pockets' window (F2)."  (chat message, line 188)
- "Civil Protection units don't rummage through people's fridges."  (text, line 191)
- "Civil Protection units don't go through bins."  (text, line 191)

*When:* part of: scavenge

- "Somebody's cleared it out already. Nothing but the smell."  (text, line 195)
- "Somebody's been through this one already. Nothing left."  (text, line 195)
- "Your pockets are full."  (text, line 197)
- "Going through the fridge..."  (progress bar, line 198)
- "Going through the rubbish..."  (progress bar, line 198)
- "You leave it."  (text, line 199)

*When:* part of: done

- "Nothing worth having."  (chat message, line 206)
- "Found: {name}."  (chat message, line 208)

*When:* part of: fish

- "You need water: stand in the canal, or look at it."  (text, line 230)
- "Your pockets are full."  (text, line 231)
- "Fishing... keep still"  (progress bar, line 234)
- "You reel in. The fish can wait."  (text, line 235)

*When:* part of: done

- "Nothing bites. The canal keeps its secrets."  (chat message, line 239)
- "A bite! A fish, of a kind. Cook it."  (chat message, line 242)
- "You reel in... {name}."  (text, line 242)

*When:* part of: use cache

- "confiscated Resistance supplies"  (text, line 356)
- "[Civil Protection] Confiscated: %d meals' worth of hoarded supplies."  (message, line 357)
- "The Combine found our supplies. Everything's gone."  (text, line 358)
- "[Civil Protection] Empty. They've eaten it already."  (chat message, line 361)
- "The crate is nailed shut. Whoever it belongs to isn't here."  (chat message, line 366)
- "[Resistance] Everyone eats. Come back in %d minute%s."  (message, line 371)
- "[Resistance] The crate's empty. Somebody needs to make a supply run (F3), or bring food (C > Resistance > Donate food)."  (chat message, line 375)
- "Your pockets are full."  (chat message, line 378)
- "[Resistance] A tin from the stores. %d left."  (message, line 381)

*When:* part of: use pot

- "uprooted an illegal garden"  (text, line 390)
- "[Civil Protection] Unlicensed agriculture. You pull it up by the roots."  (chat message, line 391)
- "An empty pot."  (chat message, line 393)
- "An empty pot. Plant a seed packet in it (the black market, or rubbish bins, if you're lucky)."  (chat message, line 399)
- "You plant the seeds. Back in %d minutes."  (message, line 405)
- "Green shoots. Ripe in %d:%02d."  (message, line 412)
- "Your pockets are full."  (chat message, line 414)
- "You pick %d lot%s of vegetables.%s"  (message, line 419)
- "Not your pot. Somebody will be annoyed."  (message, line 420)
- "Someone's harvested your pot in rebel territory."  (chat message, line 421)

*When:* part of: donate

- "Stand by a Resistance supply crate to donate food."  (text, line 460)
- "That's not how confiscation works."  (text, line 461)
- "The crate's full. Eat something."  (text, line 471)
- "You've no proper food to give (rations, tins, bread, vegetables, cooked meat)."  (text, line 471)
- "fed the Resistance"  (text, line 473)
- "[Resistance] You add %d meal%s to the stores. %d in the crate."  (message, line 475)

*When:* part of: spray

- "Look at a wall, up close."  (text, line 513)
- "There's already one here."  (text, line 514)
- "Spraying the lambda... keep looking at the wall"  (progress bar, line 515)
- "You stop, half done, and the paint runs."  (text, line 516)

*When:* part of: done

- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 526)

*When:* part of: clean tag

- "Paint over our own? No."  (text, line 545)
- "Scrubbing it off..."  (progress bar, line 546)
- "You leave it half scrubbed."  (text, line 547)

*When:* part of: done

- "cleaned up anticitizen graffiti"  (text, line 555)
- "[Civil Protection] Gone. As if it never was."  (chat message, line 556)
- "You scrub it off. Someone from the Union nods at you. +3 standing."  (chat message, line 560)

*When:* part of: item use

- "Find an empty pot in rebel territory."  (text, line 606)
- "Something's already growing in that one."  (text, line 607)

*When:* typing in chat

- "You need a fishing line (the Commissary sells them)."  (chat message, line 652)

*When:* the game's living city tagged moment

- "Someone painted the lambda up {or}. Bold."  (text, line 661)
- "There's a lambda on the wall {or}. Civil Protection will have it off by morning."  (text, line 662)

## Combine-only areas (sv_livingcity_security.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_security.lua`


*When:* part of: combine zone tick

- "[Civil Protection] This is a restricted area. Leave immediately."  (chat message, line 44)
- "[Civil Protection] Trespassing in a restricted area. You are now wanted."  (chat message, line 48)
- "Trespassing in a Combine area"  (text, line 49)

*When:* Stuck in a pit, behind a fence, in the map? !stuck puts you back on the street.

- "Not now."  (text, line 75)
- "Not while you're in custody."  (text, line 76)
- "Not while you're wanted."  (text, line 77)
- "You can use that again in %d seconds."  (message, line 79)

*When:* part of: unstick

- "There's nowhere to put you. Ask an admin."  (text, line 93)

*When:* part of: stuck command

- "[Living City] You pull yourself out and brush yourself off."  (chat message, line 102)
- "[Living City] {why}"  (chat message, line 103)

## jobs that come with supply drops, and Union work orders that (sv_livingcity_sidejobs.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_sidejobs.lua`


*When:* part of: factions

- "[Assignments] {line} You keep: {got}."  (chat message, line 40)

*When:* Supply drops

- "Guard the supply drop {GetPos}"  (title, line 57)

*When:* part of: build

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

*When:* the map has streetlights and none are out: nothing to fix

- "Work order: fix a streetlight"  (title, line 112)
- "A streetlight is out {GetPos}. Rewire it. Keep what's left over."  (description, line 113)
- "Find the dead streetlight"  (quest step, line 114)
- "Rewire it (stay close)"  (quest step, line 114)

*When:* part of: build

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
- "Each Combine terminal only holds half the picture. Hit two: one {here}, then another {GetPos}. Aim the multitool at each, primary fire, and stay with it while it downloads. Each sounds the alarm halfway, and a squad comes. The two fragments make a chip: the lab's scientist decodes it, or the dealer pays for it."  (description, line 183)
- "Get to the first terminal"  (quest step, line 186)
- "Download its half (multitool, primary fire; stay close)"  (quest step, line 187)
- "Get to the second terminal"  (quest step, line 188)
- "Download the other half (a different terminal)"  (quest step, line 189)
- "The master terminal {GetPos}"  (title, line 207)
- "The Combine's master terminal {GetPos}: everything they know, in one place. It takes a full minute to download, every alarm in the nexus goes off a third of the way in, and they'll send more than a squad. Bring the core home: the quartermaster's decoding marks every Civil Protection unit for ten minutes, the dealer pays a fortune, or it wipes every comrade's record."  (description, line 208)
- "Get to the master terminal"  (quest step, line 210)
- "Download the master terminal (multitool, primary fire; hold on for a minute)"  (quest step, line 211)
- "Data breach {GetPos}"  (title, line 224)
- "Anticitizens are inside Combine systems. Get there, stop them, and secure the terminal."  (description, line 225)
- "Get to the breach"  (quest step, line 226)
- "Secure the terminal"  (quest step, line 226)

*When:* The Resistance's operations, and the city's answers (sv_livingcity_resistanceops.lua)

- "Get the cell open (stay at the door while the alarm goes)"  (quest step, line 241)

*When:* part of: build

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

*When:* A shackled vortigaunt, at a Combine work site. It waits, shackled and harmless, with its keepers. Cut the shackles there (they may see), or lead it off still shackled as if you were moving Combine property, and cut them in rebel territory (any of it): unless a unit stops you and asks where you're taking it.

- "player {or} 99"  (text, line 399)

*When:* part of: build

- "Find the shackled vortigaunt at the work site"  (text, line 424)

*When:* a unit who sees you leading it may stop you and ask (once): then it's a fight

- "A Civil Protection unit steps into your way: "Where are you taking that?" No answer will do. Run, or fight."  (quest narration, line 460)
- "Theft of Combine property"  (text, line 461)

*When:* part of: on done

- "In rebel territory, the shackles come off. It breathes in, slowly, and looks round at its new home."  (quest narration, line 471)

*When:* part of: build

- "Cut the shackles (stay beside it)"  (quest step, line 478)

*When:* part of: on done

- "Theft of Combine property"  (text, line 481)
- "The shackles fall. It looks at you, and waits. Lead it home."  (quest narration, line 483)

*When:* part of: build

- "The vortigaunt waits, its collar humming. Cut it loose here, or walk it out as if it were still the Combine's?"  (quest choice, line 485)
- "Cut the shackles here (twelve seconds beside it; its keepers may see), then lead it home."  (text, line 486)

*When:* part of: pick

- "Lead it home to rebel territory (any of it)"  (text, line 487)

*When:* part of: build

- "Lead it off still shackled, like Combine property on the move; cut them in rebel territory (a unit may stop you and ask)."  (text, line 488)

*When:* part of: pick

- "Walk it to rebel territory (any of it), still shackled"  (text, line 489)

*When:* part of: build

- "Free a vortigaunt {GetPos}"  (title, line 492)
- "The Combine are working a shackled vortigaunt {GetPos}. Free it and bring it to rebel territory: it will heal our wounded."  (description, line 493)

## character slots (sv_livingcity_slots.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_slots.lua`


*When:* Can this player switch right now? ok, or false and why.

- "Character slots are off on this server."  (text, line 133)
- "Not while you're dead."  (text, line 134)
- "Not while you're wanted."  (text, line 135)
- "Not while you're in custody."  (text, line 136)
- "Not while you're down."  (text, line 137)
- "Not with your hands tied."  (text, line 138)
- "Not in the middle of a fight."  (text, line 139)

*When:* part of: can switch character

- "Finish or abandon your job first (!abandon)."  (text, line 140)
- "A stalker has no other life to go back to. Only death ends it."  (text, line 141)
- "You can switch again in %ds."  (message, line 143)

*When:* part of: switch character

- "No such slot."  (text, line 150)
- "You're already playing them."  (text, line 152)
- "[Living City] You are someone new: %s, citizen %s."  (message, line 177)
- "[Living City] You are %s, citizen %s."  (message, line 180)
- "%s switched to slot %d (%s)"  (message, line 182)

*When:* part of: delete character slot

- "You can't delete the person you're playing. Switch to someone else first."  (text, line 189)
- "That slot is empty."  (text, line 190)
- "Gone. Nobody in the city remembers them."  (text, line 196)

*When:* the game answering something done in a window (lc_slots_do)

- "[Characters] {msg}"  (chat message, line 215)

*When:* typing in chat

- "Character slots are off on this server. C > Me > Change my name and face."  (chat message, line 229)

## staff tools (sv_livingcity_staff.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_staff.lua`


*When:* commands and out-of-character chat (in-character speech is logged where it's spoken)

- "({SteamID}) joined"  (text, line 91)
- "({SteamID}) left"  (text, line 92)

*When:* someone dying

- "killed {victim} with {how}"  (text, line 98)
- "died ({how})"  (text, line 100)

*When:* the game's living city incarcerated moment

- "jailed {or}s: {or}{or}"  (text, line 105)

*When:* the game's living city wanted moment

- "wanted: {or}"  (text, line 109)

*When:* the game's living city strike moment

- "conduct strike {n}: {or}"  (text, line 112)

*When:* part of: open ticket

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

*When:* part of: ticket action

- "No such ticket."  (text, line 171)
- "[Staff] {me} is looking at your ticket."  (chat message, line 176)
- "[Staff] {me}: {text}"  (chat message, line 181)
- "[Staff] Your ticket was closed by {me}."  (chat message, line 184)
- "They're not on."  (text, line 186)
- "They're not on."  (text, line 189)

*When:* part of: warn player

- "Staff only."  (text, line 214)
- "Player not found."  (text, line 215)
- "Give a reason: !warn <name> <reason>"  (text, line 217)
- "[Staff] You have been warned: %s (warning %d)"  (message, line 229)
- "warned by {or}: {reason}"  (text, line 230)
- "warned ({list} in total)."  (text, line 231)

*When:* part of: unwarn

- "No such warning."  (text, line 239)
- "warning {idx} struck off {sid} by {or}"  (text, line 242)
- "Struck off."  (text, line 243)

*When:* Is this name (a character's) banned?

- "Staff only."  (text, line 268)

*When:* part of: char ban

- "Player not found."  (text, line 269)
- "Give a reason: !charban <name> <reason>"  (text, line 271)
- "[Staff] %s is gone, by staff decision: %s. You're someone new."  (message, line 282)
- "({cid}, {target}) banned by {or}: {reason}"  (text, line 283)
- "is banned. {Nick} starts over as someone new."  (text, line 284)

*When:* part of: char unban

- "No such ban."  (text, line 290)
- "ban on {or} lifted by {or}"  (text, line 293)
- "The ban on {or} is lifted."  (text, line 294)

*When:* the game answering something done in a window (lc_staff_do)

- "{action} {Nick}"  (text, line 339)
- "[Staff] {msg}"  (chat message, line 342)

*When:* Chat

- "[Tickets] {msg}"  (chat message, line 355)

*When:* typing in chat

- "Staff only. Need help? @ <message>"  (chat message, line 361)
- "Staff only."  (chat message, line 365)
- "[Staff] {msg}"  (chat message, line 370)

*When:* the console command lc_staff

- "Staff only."  (chat message, line 375)

## the stalker's lot (sv_livingcity_stalkerwork.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_stalkerwork.lua`


*When:* part of: stalker step in

- "Stepped into the energizer they had built. Nothing came back out."  (text, line 141)
- "[City] A flash below the Nexus. Combine property has been written off."  (chat message, line 146)

*When:* Turned away: back to work. The energizer stays, and so does the way out.

- "Back to work"  (on-screen notice, line 156)
- "The energizer hums behind you. It will still be there. E on it, twice, if you change your mind."  (on-screen notice, line 156)

*When:* part of: use energizer

- "The light"  (on-screen notice, line 172)
- "It would be very easy. Press E again to step in. There's no coming back."  (on-screen notice, line 172)

*When:* The holding floor: grime here and there; a push broom (no kneeling: a stalker hasn't the legs for it). E on each patch sweeps it up (a couple of seconds).

- "The holding floor"  (title, line 234)

*When:* part of: start

- "[Stalker] A push broom, and the floor. Walk to each patch of grime and sweep it up (E)."  (chat message, line 249)

*When:* part of: hud

- "Swept: %d of %d"  (message, line 250)
- "E on the grime sweeps it up"  (text, line 250)

*When:* pressing E on something

- "Sweeping it up..."  (progress bar, line 266)

*When:* The frame: four containment cells to carry over and seat in it (pick each up with E, set it in the frame), then the housing welded shut at four seams (E on each, a few seconds of sparks).

- "The frame"  (title, line 281)

*When:* part of: start

- "[Stalker] Four containment cells lie about. Carry each one to the frame (E to pick it up) and set it in."  (chat message, line 299)

*When:* part of: hud

- "Cells seated: %d of %d"  (message, line 301)
- "E picks a cell up; set it in the frame"  (text, line 301)
- "Seams welded: %d of %d"  (message, line 302)
- "E on each glowing seam"  (text, line 302)

*When:* part of: tick

- "[Stalker] The cells click home. Now the housing: weld the four seams (E on each)."  (chat message, line 315)

*When:* pressing E on something

- "Welding the seam..."  (progress bar, line 353)

*When:* part of: tech gone

- "an Overwatch technician going back"  (text, line 398)

*When:* The story

- "The Stalker's Lot"  (name, line 408)
- "You stepped into the light you made. Nothing of the stalker came back out."  (text, line 412)
- "You turned away from it, and went back to work. It's still down there, humming. So are you."  (text, line 413)

*When:* part of: build

- "They brought you up from below with a number where your name was, and a voice that can only scream. Report where you're kept. Stand still while they finish you."  (description, line 421)
- "Report to the Nexus, where they keep you"  (quest step, line 423)

*When:* then

- "An Overwatch technician comes for you, tools in hand."  (quest narration, line 425)

*When:* part of: build

- "Stand still while the technician fits the harness"  (quest step, line 427)

*When:* then

- "Cold metal on your spine. A click. Your legs are yours to walk with, and nothing else."  (quest narration, line 429)

*When:* part of: build

- "The holding floors are never clean. That's what you're for now: a push broom, and the grime."  (description, line 442)
- "Go to the holding floor: your push broom's waiting"  (text, line 444)
- "Sweep up every patch of grime (E on each)"  (text, line 445)

*When:* then

- "A Civil Protection unit steps over the broom without looking down. You are furniture that moves."  (quest narration, line 446)

*When:* part of: build

- "Something new is going in below the Nexus, and it needs power. The cable runs from the banks. You run the cable."  (description, line 457)
- "Go to the power bank"  (text, line 459)
- "the power bank"  (text, line 459)
- "Splice the cable in: turn the tiles till the current reaches the bank (a sparking tile bites)"  (text, line 460)
- "Now the next power bank"  (text, line 461)
- "the power bank"  (text, line 461)
- "Splice it in"  (text, line 462)

*When:* then

- "The banks drop and surge. Somewhere under your feet, something drinks."  (quest narration, line 463)

*When:* part of: build

- "Go to the frame they've set up"  (quest step, line 472)
- "The frame"  (title, line 476)
- "A Combine ball energizer, they call it on the work order. A frame of black metal, waiting for you."  (description, line 477)
- "Carry the four containment cells to the frame and set them in (E), then weld the four seams (E on each)"  (text, line 480)

*When:* then

- "Sparks, and then it's sealed. The light inside is brighter now. It doesn't flicker."  (quest narration, line 482)

*When:* part of: build

- "Go back to the energizer"  (quest step, line 491)

*When:* part of: on done

- "the terminal"  (text, line 493)

*When:* part of: build

- "The charge"  (title, line 495)
- "It needs its first charge. Then it's finished, and so are you, one way or another."  (description, line 496)
- "Route its first charge through the regulator: turn the tiles till the current reaches it"  (text, line 499)

*When:* then

- "It hums. A ball of white light turns slowly inside it, and it is the most beautiful thing you have seen since they took you."  (quest narration, line 501)

*When:* part of: build

- "The Civil Protection units have stopped watching you. The light turns, and turns. It would be very easy to step inside, and then there would be no more stalker."  (quest choice, line 503)
- "Step into the light. (This person ends for good: you start over as someone new.)"  (text, line 504)

*When:* part of: pick

- "You step forward. It's warm."  (quest narration, line 506)

*When:* part of: build

- "Turn away, and go back to work."  (text, line 509)

*When:* part of: pick

- "You turn your back on it. Behind you it hums, and hums."  (quest narration, line 511)

## static map props (sv_livingcity_staticprops.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_staticprops.lua`


*When:* Reads the static props of a BSP. Returns a list of fixtures, or nil and why.

- "couldn't open {path}"  (text, line 117)
- "not a BSP file"  (text, line 120)

*When:* part of: read static fixtures

- "odd game lump directory"  (text, line 128)
- "the map's static props are compressed"  (text, line 135)
- "odd model list"  (text, line 139)
- "odd leaf list"  (text, line 149)

*When:* the record size depends on the map's version, but origin, angles and the model index lead them all

- "odd prop records"  (text, line 156)

*When:* part of: scan static props

- "Static props: %d stove/sink/vending fixtures, %d dumpsters or bins, %d tables, counters or shelves, %d beds and seats and %d pieces of junk to salvage found in the map"  (message, line 185)

*When:* the console command lc_scanprops

- "[Living City] Static props: {or}"  (text, line 218)
- "[Living City] Couldn't read the map's props: {StaticScanNote}"  (text, line 219)

## the city's stores (sv_livingcity_stockpile.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_stockpile.lua`

- "The city's ration stores are empty. Distribution is suspended until supplies arrive."  (text, line 78)
- "Ration stores are running low. Allocations will be slower until supplies arrive."  (short name, line 79)
- "Ration stores are full. Productive citizens are rewarded."  (text, line 80)

*When:* part of: check level

- "[City] {lvl}"  (chat message, line 88)

*When:* the game's living city npcwork finished moment

- "npc work"  (text, line 134)

*When:* the game's living city train arrived moment

- "train freight"  (text, line 137)

*When:* What goes out

- "ration line"  (text, line 144)

*When:* the console command lc_stock

- "[Living City] City stores: %d of %d rations (%s)."  (message, line 172)

## places to keep things (sv_livingcity_storage.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_storage.lua`

- "the bin"  (text, line 91)
- "the locker"  (text, line 91)
- "the crate"  (text, line 91)
- "the stall"  (text, line 91)

*When:* What this player may do with it: "open" (their own, or a bin), "search" (a unit), or nil and why.

- "The stall is closed."  (text, line 139)

*When:* part of: access

- "The locker is locked. It's someone else's."  (text, line 142)
- "The crate is locked. It isn't yours."  (text, line 142)

*When:* Pressing E on a locker or crate: open your pockets alongside it.

- "[Search] You open {kind}{or}."  (chat message, line 169)

*When:* Putting in and taking out

- "There's nothing here to put it in."  (text, line 190)
- "Not yours to fill."  (text, line 192)
- "That's Combine issue: it stays with you (or another unit)."  (text, line 194)
- "It won't fit."  (text, line 195)

*When:* part of: container put

- "[Living City] The locker is yours now. Only you can open it."  (chat message, line 201)

*When:* part of: container take

- "Buy it."  (text, line 215)

*When:* units only take what's illegal

- "It's not contraband. It stays."  (text, line 218)

*When:* part of: container take

- "Contraband seized"  (text, line 227)
- "Contraband in their {or}"  (text, line 232)
- "Contraband found in their {kind}: {name}"  (text, line 233)
- "[Civil Protection] Your {kind} was searched. They found: {name}."  (chat message, line 234)

*When:* Giving up an empty locker, or packing up an empty crate.

- "It isn't yours."  (text, line 244)
- "Empty it first."  (text, line 245)

*When:* part of: container release

- "The locker is free for anyone now."  (text, line 249)
- "Collect the takings first."  (text, line 252)
- "You can't carry it."  (text, line 253)
- "You pack the stall up."  (text, line 258)
- "You pack the crate up."  (text, line 258)

*When:* part of: place crate

- "Storage is off on this server."  (text, line 281)
- "Trading needs a CWU business license in your pockets (the Commissary issues them)."  (text, line 284)
- "You already have %d %s set down. Pack one up first."  (message, line 289)
- "Not in a doorway."  (text, line 294)
- "There's no room there."  (text, line 296)

*When:* Market stalls: stock it with prices, people buy, takings wait in the till Put one in for sale at a price (or change the price of what's there). spec: "item|price"

- "Name a price."  (text, line 333)
- "It isn't your stall."  (text, line 336)

*When:* part of: stall buy

- "The stall is closed."  (text, line 353)
- "It's your own stall. Take it back instead."  (text, line 354)
- "That's gone."  (text, line 356)
- "You can't afford it."  (text, line 357)
- "[Stall] Sold: %s, %d credits. (%d in the till)"  (message, line 367)
- "Bought: %s, %d credits."  (message, line 370)

*When:* part of: stall collect

- "The till is empty."  (text, line 377)
- "the stall's takings"  (text, line 379)

*When:* part of: stall reopen

- "You need a business license to trade."  (text, line 395)
- "The stall is open."  (text, line 398)

## story chains (sv_livingcity_stories.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_stories.lua`


*When:* part of: patrol

- "Patrol stop"  (message, line 50)

*When:* Internal Affairs

- "The window across the street flashes. Internal Affairs was watching the whole time."  (quest narration, line 93)

*When:* part of: refuse bribe

- "Arrest him for attempted bribery (right click)"  (text, line 103)
- "Internal Affairs"  (name, line 107)
- "Your file is closed. Somewhere, a number is quietly reset."  (text, line 111)
- "Internal Affairs found nothing. This time."  (text, line 112)
- "Caught in the act. Your record will follow you."  (text, line 113)
- "Someone else is paying for what you did."  (text, line 114)
- "You lost your rank. You kept your conscience. In this city that is a bad trade, and you made it anyway."  (text, line 115)
- "They'll never prove anything. They'll never stop watching."  (text, line 116)
- "You work for them now. The money is very good."  (text, line 117)
- "You played both sides and walked away. For now."  (text, line 118)
- "Internal Affairs knows exactly what you did with their crate."  (text, line 119)

*When:* part of: build

- "A quiet word"  (title, line 127)
- "You've been summoned {GetPos}. The message didn't say by whom. It didn't have to."  (description, line 128)
- "Report as summoned"  (quest step, line 130)
- "Speak with the officer waiting for you"  (text, line 131)
- "The officer doesn't give a Civil Protection unit number. 'Your ration ledger doesn't add up, unit. Neither do the citizens who keep walking free on your shift.'"  (quest choice, line 132)
- "Confess. Ask for a chance to make it right."  (text, line 134)

*When:* part of: pick

- "He nods slowly. 'Then make it right. By the book, every step. We'll be counting.'"  (quest narration, line 137)

*When:* part of: build

- "Explain it away."  (text, line 140)

*When:* part of: success

- "He writes something down. 'We'll be in touch.' It doesn't sound like a dismissal."  (quest narration, line 142)

*When:* part of: fail

- "He doesn't even pretend to believe you. 'Someone will be keeping an eye on you, Civil Protection unit.'"  (quest narration, line 146)

*When:* part of: build

- "Offer him a cut."  (text, line 149)

*When:* part of: pick

- "A long pause. Then he laughs, and holds out his hand."  (quest narration, line 152)

*When:* part of: build

- "Clean patrol, stop"  (text, line 161)
- "Inspect three citizens. Properly."  (quest step, line 163)
- "Internal Affairs wants to see a model officer. Show them one."  (description, line 170)
- "The audit"  (title, line 179)
- "A routine patrol {GetPos}. Nothing to worry about."  (description, line 180)
- "Patrol the market"  (quest step, line 182)
- "A citizen is waving you over"  (text, line 183)
- "A citizen presses a bundle of ration units into your hand. 'For your trouble, officer.' His eyes flick to a window across the street."  (quest choice, line 184)
- "Refuse, and arrest him for attempted bribery."  (text, line 186)
- "Take it."  (text, line 187)
- "Glance at that window."  (text, line 188)

*When:* part of: success

- "A lens glints behind the glass. A test. You hand the bundle back, loudly, and thank him for his loyalty."  (quest narration, line 193)

*When:* part of: fail

- "Just a window. The bundle is still in your hand, and he's still waiting."  (quest narration, line 197)
- "He's still waiting. The bundle is still warm."  (quest choice, line 198)
- "Refuse, and arrest him."  (text, line 199)
- "Take it."  (text, line 200)

*When:* part of: build

- "Inspect two citizens while he watches"  (quest step, line 215)
- "The Civil Protection unit who has followed you all shift finally speaks. 'Name another Civil Protection unit who takes. Or we keep looking at you.'"  (quest choice, line 216)
- "Give them a name."  (text, line 218)

*When:* part of: pick

- "Unit 4-17 is reassigned to the canals the next morning. You don't see him again."  (quest narration, line 221)

*When:* part of: build

- "Take the fall."  (text, line 223)
- "Stare at the mask until he leaves."  (text, line 228)

*When:* part of: fail

- "You blink first."  (quest narration, line 231)

*When:* part of: build

- "Under watch"  (title, line 237)
- "Internal Affairs has assigned you a shadow. Do your job. Do it well."  (description, line 238)
- "The ring"  (title, line 262)
- "Your new friends need something moved. Quietly. Pick it up {GetPos}."  (description, line 263)
- "Collect the crate from your new friends (press E)"  (text, line 265)
- "'Careful with that one. It's not what the label says.'"  (text, line 265)
- "The crate rattles. Weapons. Rebel weapons, sold by the people whose job is hunting rebels."  (quest choice, line 266)
- "Deliver it. Business is business."  (text, line 267)
- "Dump it in the canal and report it seized."  (text, line 271)

*When:* part of: success

- "The crate sinks. Your report is a work of art."  (quest narration, line 276)

*When:* part of: fail

- "Internal Affairs finds out within the hour."  (quest narration, line 280)
- "Theft from Internal Affairs"  (text, line 282)

*When:* part of: build

- "Hand the crate to the buyer {GetPos} (press E)"  (text, line 288)
- "The buyer doesn't count the money in front of you. That's how you know it's a lot."  (text, line 288)

*When:* The Pamphleteer

- "The Pamphleteer"  (name, line 300)
- "You are Resistance now. Your old life is a cover story."  (text, line 306)
- "A friend of the Resistance. They'll call on you."  (text, line 307)
- "The stranger never came back. Neither did the family in 4C."  (text, line 308)
- "Some doors stay shut."  (text, line 309)

*When:* part of: build

- "A knock at night"  (title, line 316)
- "Go home to {name}. Someone is waiting."  (description, line 317)
- "Go home to {name}"  (quest step, line 319)
- "Someone is waiting outside your door"  (text, line 320)
- "A stranger in a Union jacket that doesn't fit him. He says your name like he's known it for years. 'You've been kind to the wrong people. We noticed. Can you be useful, too?'"  (quest choice, line 321)

*When:* part of: pick

- "He talks for a long time. Mostly about you."  (quest narration, line 324)

*When:* part of: build

- "Report him to Civil Protection."  (text, line 327)

*When:* part of: pick

- "He sees it in your face before you move. He's gone by the time you turn around."  (quest narration, line 331)
- "Report the stranger to a Civil Protection unit (press E)"  (quest step, line 332)

*When:* part of: build

- "Shut the door."  (text, line 334)

*When:* part of: pick

- "You lean against the door until his footsteps fade."  (quest narration, line 337)

*When:* part of: build

- "Proof of nerve"  (title, line 349)
- "Carry a parcel across the district. Don't open it. Don't get caught."  (description, line 350)
- "Take the parcel from your contact (press E)"  (text, line 352)
- "'Straight there. Don't open it. Don't be late.'"  (text, line 352)
- "Two Civil Protection units are checking papers at the corner ahead."  (quest choice, line 353)
- "Walk past them, calmly."  (text, line 354)

*When:* part of: success

- "One of them looks right at you. Then past you."  (quest narration, line 355)

*When:* part of: fail

- "'Citizen! Stop!' You don't."  (quest narration, line 357)
- "Carrying contraband"  (text, line 358)

*When:* part of: build

- "Take the long way, through the alleys."  (text, line 360)

*When:* part of: pick

- "Take the long way round"  (quest step, line 361)

*When:* part of: build

- "Leave it at the dead drop {GetPos}"  (text, line 364)
- "The choice"  (title, line 373)
- "They want to meet you in {where}. In person, this time."  (description, line 374)
- "Go to the meeting in {where}"  (quest step, line 376)
- "Find the stranger"  (text, line 377)
- "The stranger is waiting with two others. One of them wears the lambda openly. 'Well?'"  (quest choice, line 378)
- "I'm with you."  (text, line 379)
- "Not yet. But I'll help when I can."  (text, line 384)
- "I've changed my mind."  (text, line 388)

*When:* part of: tail stage

- "your neighbor isn't out on the streets right now. Try again once the city is busy"  (text, line 414)
- "Follow your neighbor without being noticed"  (text, line 415)

*When:* part of: on enter

- "Follow your neighbor without being noticed. Not too far, and stay out of {his} sight: the longer {he} sees you, the more suspicious {he} gets"  (text, line 423)

*When:* part of: on noticed

- "{He} stops and turns around. {He} knows exactly who you are."  (text, line 428)
- "Pretend you were heading the other way."  (text, line 429)

*When:* part of: success

- "{He} shrugs and walks on. You give {him} a longer leash."  (text, line 431)

*When:* part of: fail

- "{He} doesn't buy it. {He} runs."  (text, line 435)

*When:* part of: on noticed

- "Confront {him}."  (text, line 439)

*When:* part of: pick

- "'You're one of them now? You?' {He} doesn't run. {He} just looks tired."  (text, line 441)
- "The Informant"  (name, line 450)
- "Double rations. Your neighbors have started saying good morning a little too carefully."  (text, line 457)
- "Your brother comes home thinner and quieter, and never asks how."  (text, line 458)
- "Now they're watching your brother too. Because of you."  (text, line 459)
- "The city has no truer friend. The city does not have friends."  (text, line 460)

*When:* part of: build

- "Eyes and ears"  (title, line 467)
- "The Union asks its friends to keep watch {GetPos}."  (description, line 468)
- "Go and keep watch"  (quest step, line 470)
- "Watch the comings and goings"  (quest step, line 471)
- "Tell a Civil Protection unit what you saw (press E)"  (quest step, line 472)
- "Report your neighbor to a Civil Protection unit (press E)"  (quest step, line 479)

*When:* part of: on enter

- "Report {him} to a Civil Protection unit (press E)"  (text, line 480)

*When:* part of: on done

- "By evening, {his} door is sealed with yellow tape."  (text, line 483)

*When:* part of: build

- "The neighbor"  (title, line 488)
- "Your neighbor has been keeping strange hours. The Union would like to know where they go."  (description, line 489)
- "Collect what you're owed {GetPos}."  (description, line 500)
- "Go to collect your payment"  (quest step, line 502)
- "Speak with an officer (press E)"  (quest step, line 503)
- "The officer slides a ration card across. 'Double rations. The Union appreciates its friends.'"  (quest choice, line 504)
- "Take the card."  (text, line 505)
- "Ask for your brother's release instead."  (text, line 510)

*When:* part of: success

- "A name is typed. Somewhere below your feet, a cell door opens."  (quest narration, line 517)

*When:* part of: fail

- "'Your brother? Interesting. We'll look into him too.'"  (quest narration, line 521)

*When:* part of: build

- "Refuse it. You did it for the city."  (text, line 523)

*When:* The Missing Unit

- "Lambda graffiti on the wall, the paint still wet. Drag marks lead toward the canals."  (text, line 539)
- "Headcrab shells, cracked open. A lot of them. His stunstick is bent nearly in half."  (text, line 540)
- "His mask is folded neatly on the ground. Like he took it off himself, and didn't want it damaged."  (text, line 541)
- "The Missing Civil Protection unit"  (name, line 545)
- "The radio is silent. So, for a while, is the Resistance."  (text, line 551)
- "For a week, the Resistance follows your orders. Overwatch notices."  (text, line 552)
- "You file his tags with the others. Nobody asks how he died."  (text, line 553)
- "Overwatch cleans the area. They don't find him. You don't tell them where to look."  (text, line 554)
- "He's processed by morning. You never learn what happened to his daughter."  (text, line 555)
- "Your report says killed in action. You'll never be sure that was a kindness."  (text, line 556)
- "Somewhere in the canals, a man with a CP haircut is teaching rebels how Civil Protection units think."  (text, line 557)
- "He's out there somewhere, and now he knows your face."  (text, line 558)

*When:* part of: build

- "Gone dark"  (title, line 569)
- "Unit 6-12 stopped answering dispatch {GetPos}. Find out why."  (description, line 570)
- "Go to 6-12's last known position"  (quest step, line 572)
- "Search the area for 6-12's things (press E)"  (text, line 575)
- "Report it up the chain."  (text, line 577)
- "Keep it quiet and look into it yourself."  (text, line 578)
- "What's left of him"  (title, line 592)
- "The trail leads into the infestation."  (description, line 593)
- "Enter the infestation"  (quest step, line 595)
- "Fight your way through"  (quest step, line 596)
- "Among the infested, a familiar uniform. His mask is still on."  (quest choice, line 597)
- "Put him down yourself."  (text, line 598)
- "Leave him for Overwatch."  (text, line 599)
- "Enter rebel territory. They'll be waiting"  (quest step, line 605)

*When:* the people who took him are in there, and they're armed

- "The drag marks lead into rebel territory. Go in, and hold long enough to find something. Expect a fight."  (description, line 610)
- "Search rebel territory (they know you're here)"  (text, line 613)

*When:* part of: build

- "You find his radio in a stairwell, still switched on. Someone has been listening to Civil Protection frequencies all week."  (quest choice, line 615)
- "Smash it."  (text, line 616)
- "Leave it on, and feed them false orders."  (text, line 617)

*When:* part of: fail

- "They stop transmitting the moment you touch it."  (quest narration, line 620)

*When:* part of: build

- "The man in the stolen coat"  (title, line 633)
- "A citizen with a Civil Protection haircut was seen {GetPos}."  (description, line 634)
- "Find the man in the stolen coat (marked)"  (text, line 636)
- "It's him. 6-12, in a stolen coat, his haircut already growing out. 'Please. I have a daughter in Block 4.'"  (quest choice, line 637)
- "Bring him in."  (text, line 638)

*When:* part of: pick

- "Arrest him (right click)"  (text, line 643)

*When:* part of: build

- "Let him disappear."  (text, line 646)
- "Help him reach the Resistance."  (text, line 652)

*When:* part of: success

- "Get him to {safe}"  (text, line 656)

*When:* part of: fail

- "He doesn't trust you. He runs."  (quest narration, line 660)

*When:* Father Grigori's Flock

- "Father Grigori's Flock"  (name, line 678)
- "He weeps through the whole blessing. He never informs again."  (text, line 682)
- "He leaves without a word. The flock is smaller, and safer."  (text, line 683)
- "Your chapel is ash by morning. You will find another. You always do."  (text, line 684)
- "If he reports you, he'll have to report that too."  (text, line 685)

*When:* part of: build

- "Lost sheep"  (title, line 690)
- "The city is full of frightened people. Find some of them."  (description, line 691)
- "Seek out frightened souls and speak with them (press E)"  (quest step, line 693)
- "Tend to their wounds (The Blessing)"  (quest step, line 694)
- "Hold a secret mass"  (quest step, line 702)

*When:* they gather, face the priest, and stay for the service

- "The secret mass"  (title, line 719)
- "Gather the faithful in {where}. Pray quietly. Pray quickly."  (description, line 720)

*When:* part of: build

- "Go to the hidden chapel in {where}"  (quest step, line 722)
- "As the last hymn ends, you notice one of your flock counting the others. Quietly. Like a man taking inventory."  (quest choice, line 724)
- "Find the informant among them."  (text, line 725)

*When:* part of: success

- "He's young. He's frightened. They have his mother."  (quest choice, line 727)
- "Forgive him."  (text, line 728)
- "Send him away."  (text, line 729)

*When:* part of: fail

- "You can't tell which of them it is. By morning, Civil Protection knows everything."  (quest narration, line 733)
- "Unlawful worship"  (text, line 734)

*When:* part of: build

- "Bless them all, the informant too."  (text, line 737)

*When:* part of: tick

- "Boots on the stairs."  (quest narration, line 748)
- "Unlawful worship"  (text, line 749)

*When:* The Overwatch Candidate

- "The Overwatch Candidate"  (name, line 762)
- "You don't remember your name. You don't need to."  (text, line 766)
- "You keep your name, your face, and the nightmares. Overwatch won't ask twice: you'll go no higher than Division Leader."  (text, line 767)

*When:* part of: build

- "Overwatch is watching your performance. Hold a checkpoint and inspect citizens. Flawlessly."  (description, line 776)
- "Report to the checkpoint"  (quest step, line 778)
- "Hold the checkpoint under observation"  (quest step, line 779)
- "Inspect three citizens"  (quest step, line 780)
- "Report {GetPos}. Come alone."  (description, line 791)
- "Report as ordered"  (quest step, line 793)
- "A technician in a coat that has never been white. 'Transhuman conditioning. You won't remember your name, Civil Protection unit. You won't need to.'"  (quest choice, line 794)
- "Accept. (The Overwatch ranks open to you: Prison Guard, Soldier, Elite. There's no undoing it.)"  (text, line 796)
- "Decline. You like your name. (You'll rise no higher than Division Leader.)"  (text, line 800)

*When:* The Man Inside: honest, kind cops get an offer

- "Someone saw that. They'll remember."  (quest narration, line 818)
- "[Story] You have a feeling you're being watched."  (chat message, line 820)
- "The Man Inside"  (name, line 855)
- "She was processed by morning. You were commended. You don't sleep well."  (text, line 861)
- "You burned your uniform in a canal barrel. The Resistance has a fighter who knows exactly how Civil Protection units think."  (text, line 862)
- "You still wear the mask. Now you know who you're wearing it for."  (text, line 863)
- "You never answer another note. Some nights you wonder."  (text, line 864)

*When:* part of: build

- "A note in your ration packet"  (title, line 871)
- "Someone slipped a note into your ration packet. One line: a place, {GetPos}, and a time. Now."  (description, line 872)
- "Go to the place named in the note"  (quest step, line 874)
- "Find whoever left it (marked)"  (text, line 875)
- "A woman with a lambda tattooed on the inside of her wrist. 'People talk about you, officer. The one who looks the other way. The one who says please.' She doesn't blink. 'We could use someone like that.'"  (quest choice, line 876)
- "Hear her out."  (text, line 878)

*When:* part of: pick

- "She talks fast and quiet. By the end, you know three names you shouldn't."  (quest narration, line 879)

*When:* part of: build

- "Arrest her."  (text, line 882)

*When:* part of: pick

- "Arrest her (right click)"  (text, line 887)

*When:* part of: build

- "Pretend you never saw her."  (text, line 890)

*When:* part of: pick

- "You walk away. You keep the note."  (quest narration, line 893)

*When:* part of: build

- "Proof of good faith"  (title, line 905)
- "They want proof. A prisoner, released on your shift, walked to {where}. Don't let another Civil Protection unit see you."  (description, line 906)
- "Unlock the cell of the prisoner they named (press E)"  (text, line 908)
- "Walk them to {where} like it's routine"  (text, line 909)
- "A Civil Protection unit saw you walking a prisoner out of the block. He'll remember."  (text, line 912)
- "The crossroads"  (title, line 920)
- "They want to meet in {where}. Come out of uniform if you can. Come alone either way."  (description, line 921)
- "Go to the meeting in {where}"  (quest step, line 923)
- "Find her"  (text, line 924)
- "She's waiting with a man in a lambda armband who doesn't take his hand off his rifle. 'You've proven yourself. So: do you come over, or do you stay where you can do the most good?'"  (quest choice, line 925)
- "Come over. Tonight."  (text, line 927)
- "Stay inside. Be their eyes."  (text, line 932)

*When:* part of: pick

- "He finally lets go of the rifle. 'Then you never met us. Watch your board.'"  (quest narration, line 936)

*When:* part of: build

- "Walk away from all of it."  (text, line 938)

*When:* Inside Work: repeatable secret jobs for a double agent

- "Leave the patrol schedule at the dead drop (crouch)"  (quest step, line 955)
- "A Civil Protection unit watched you crouch by that drainpipe. He'll wonder why."  (text, line 957)

*When:* part of: ops

- "Leak the schedule"  (title, line 960)
- "Tomorrow's patrol routes, left where the right people will find them {GetPos}."  (description, line 961)
- "Go to the dead drop"  (quest step, line 962)

*When:* part of: stages

- "Warn citizen {id} before the raid (press E)"  (text, line 970)

*When:* part of: on done

- "They go pale, then they go. By the time the raid comes, the apartment is empty."  (quest narration, line 986)

*When:* part of: stages

- "Warn them first"  (title, line 990)
- "Citizen {id} is on tomorrow's list. Get to them first. Quickly."  (description, line 991)
- "Another Civil Protection unit saw you whispering to someone on the list."  (text, line 993)

*When:* part of: tick

- "Lose the evidence"  (title, line 1003)
- "Evidence against a Resistance cell is sitting {GetPos}. It should never reach the evidence room."  (description, line 1004)
- "Collect the evidence (press E)"  (text, line 1006)
- "Take it to {where} instead of HQ"  (text, line 1007)
- "A Civil Protection unit saw you heading the wrong way with an evidence bag."  (text, line 1009)
- "A quiet release"  (title, line 1018)
- "Someone in the cells knows too much about the Resistance. Get them out before interrogation."  (description, line 1019)
- "Open their cell (press E)"  (text, line 1021)
- "Walk them out like it's paperwork"  (text, line 1022)
- "The desk officer is going to remember that release had no paperwork."  (text, line 1025)
- "Your sector report is due. There was Resistance activity near the canals this week."  (description, line 1035)
- "Go to file your sector report"  (quest step, line 1037)
- "Hand your report to an officer (press E)"  (quest step, line 1038)
- "The officer skims your report. 'Canals. Anything to note, Civil Protection unit?'"  (quest choice, line 1039)
- "The canals were quiet. Completely quiet."  (text, line 1040)

*When:* part of: success

- "He stamps it without looking up."  (quest narration, line 1041)

*When:* part of: fail

- "He reads it twice, then looks at you for a long moment."  (text, line 1042)

*When:* part of: tick

- "Report it honestly. You can't risk it today."  (text, line 1043)

*When:* part of: pick

- "Somewhere in the canals, a cell has to move house tonight. They'll understand. Probably."  (quest narration, line 1045)
- "Inside Work"  (name, line 1053)

*When:* Mole Hunt: when suspicion catches up with you

- "He picks up your file instead. 'Interesting.'"  (quest narration, line 1089)
- "Mole Hunt"  (name, line 1099)
- "Unit 3-09 was taken in your place. You tell yourself he probably deserved it."  (text, line 1103)
- "You ran before they could knock. Every Civil Protection unit in the city has your face now."  (text, line 1104)
- "The mole hunt moves on to another sector. You breathe again. Carefully."  (text, line 1105)
- "Stripped of rank and mask. A citizen again, with a file that will never close."  (text, line 1106)

*When:* part of: build

- "The briefing"  (title, line 1114)
- "Internal Affairs believes there's a mole in your division. They want your help finding them."  (description, line 1115)
- "Report for the briefing"  (quest step, line 1117)
- "Speak with the Internal Affairs officer"  (text, line 1118)
- "The officer spreads three files across the hood of an APC. One of them is yours. He hasn't noticed. Yet."  (quest choice, line 1119)
- "Steer him toward another Civil Protection unit's file."  (text, line 1120)
- "Excuse yourself. Run, tonight."  (text, line 1127)
- "Keep your head down and ride it out."  (text, line 1133)

## survival (sv_livingcity_survival.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_survival.lua`


*When:* Can they take n more of this? ok, or false and why.

- "Your pockets are full."  (text, line 129)

*When:* part of: can carry

- "You've no room for something that size."  (text, line 140)
- "That's more than you can carry."  (text, line 143)

*When:* Give an item, or drop it at their feet if their pockets are full.

- "Your pockets are full. {id} is on the ground."  (chat message, line 205)

*When:* part of: infect

- "Your stomach turns. Something in that wasn't clean."  (chat message, line 228)

*When:* a timer (regularly)

- "You're getting hungry."  (text, line 267)
- "You're starving."  (text, line 267)
- "Your mouth is dry."  (text, line 268)
- "You're badly dehydrated."  (text, line 268)
- "You are starving and dehydrated."  (chat message, line 280)
- "You are starving."  (text, line 280)
- "You are dehydrated."  (text, line 280)

*When:* part of: breen water

- "Where were you going again?"  (chat message, line 328)

*When:* part of: consume

- "The cramps ease."  (chat message, line 342)
- "It burns all the way down. Your legs go out from under you."  (chat message, line 348)

*When:* part of: inv action

- "Your hands are tied."  (chat message, line 467)
- "You need to be standing in water."  (chat message, line 493)
- "You can't eat that."  (chat message, line 499)
- "Cooking won't help that."  (chat message, line 503)
- "You need a stove or a fire."  (chat message, line 504)
- "becomes {name}."  (chat message, line 508)
- "Stand in water, or by a sink, to fill it."  (chat message, line 511)

*When:* the tap running into it (a splash was too loud for a sink); dipped in water, a soft slosh

- "[Papers] You keep your papers on you. (Stash them at home if you must.)"  (chat message, line 518)
- "That's Combine issue: it stays with you (or another unit)."  (chat message, line 519)

*When:* pressing E on something

- "Picked up: {name}"  (chat message, line 569)
- "Your pockets are full."  (chat message, line 571)

*When:* the game's physgun drop moment

- "[Living City] Moved: the {kind} is saved where you put it."  (chat message, line 860)

*When:* part of: use vending

- "[Vending] Insert {price} credits."  (chat message, line 876)

*When:* part of: use static vending

- "[Vending] Insert {price} credits."  (chat message, line 923)

*When:* part of: use fixture

- "[Stove] Cook from your pockets (F2)."  (chat message, line 942)
- "[Sink] Fill bottles and cans from your pockets (F2). Boil them before you drink."  (chat message, line 946)

*When:* part of: dispense

- "[Rations] The clerk at the counter hands you a ration packet."  (chat message, line 1006)

*When:* Hacking them (the multitool): a vending machine spits out its water, a ration dispenser its packets, no credits and no coupon. Ten seconds, keep still; a unit who sees you at it makes you wanted. Then it's empty for lc_machine_hack_cooldown minutes (10).

- "the vending machine"  (text, line 1017)
- "the ration dispenser"  (text, line 1017)
- "Aim at a vending machine or a ration dispenser."  (text, line 1020)
- "You need a multitool to get into it."  (text, line 1021)
- "You're busy."  (text, line 1022)
- "It's dead: no power. Nothing to get out of it."  (text, line 1023)

*When:* part of: hack machine

- "Someone's already emptied it. It'll be restocked in about %d minutes."  (message, line 1026)
- "Hacking {name}... keep still"  (progress bar, line 1030)
- "You leave it."  (text, line 1031)

*When:* part of: done

- "[Resistance] The dispenser chokes, and spits out %d ration packets. No coupon, no record."  (message, line 1051)
- "[Resistance] The machine shudders and drops %d cans. Free water, for once."  (message, line 1052)
- "Tampering with Union property"  (text, line 1054)
- "[Civil Protection] A Civil Protection unit saw you at it."  (chat message, line 1055)

*When:* ent may be nil: a line with no dispenser placed at its front.

- "[Rations] No ration card on file. Register at Civil Intake first."  (text, line 1069)
- "[Rations] Present your ration card. Lost it? Civil Intake issues another."  (text, line 1071)

*When:* part of: use dispenser

- "[Rations] Your ration privileges have been suspended."  (text, line 1073)
- "[Rations] Next allocation in %d seconds."  (message, line 1075)

*When:* the PA said it: tolerating noncompliance costs this allocation (sv_livingcity_rations.lua)

- "[Rations] Allocation withheld: five ration units deducted for tolerating noncompliance{why}. Your next allocation is as normal."  (text, line 1082)

*When:* the city's stores (sv_livingcity_stockpile.lua): empty, nothing; low, sometimes nothing

- "[Rations] Distribution suspended: the city's stores are empty."  (text, line 1089)
- "[Rations] Supply shortfall. The dispenser whirs and gives nothing. Try again in a minute (the stores are low: kitchen and factory shifts, trains and supply drops fill them)."  (text, line 1092)

*When:* a forged card: no questions, usually

- "[Rations] Card invalid. This incident has been logged."  (chat message, line 1101)
- "Ration fraud"  (text, line 1102)

*When:* part of: use dispenser

- "[Rations] Card accepted."  (chat message, line 1105)
- "ration coupon"  (text, line 1122)

*When:* part of: serve players at line

- "[Rations] Wait at the counter."  (chat message, line 1138)

## talking to people (sv_livingcity_talk.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_talk.lua`


*When:* Who you are to them: this character of yours, not just your account.

- "\|{GetNW2String}"  (text, line 49)

*When:* part of: mood word

- "glad to see you"  (text, line 80)
- "terrified of you"  (text, line 82)
- "wary of you"  (text, line 83)

*When:* A sympathizer who likes you: where the Resistance gathers.

- "out past the checkpoints"  (text, line 128)

*When:* part of: safe house hint

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

*When:* part of: doing

- "waiting in the ration line"  (text, line 152)

*When:* part of: share food

- "They take the {name} with both hands. 'I won't forget this. I mean it.'"  (name, line 236)
- "They take the {name} and hide it in their coat. 'Thank you.'"  (name, line 237)

*When:* part of: pick pocket

- "Their pockets are already empty."  (text, line 250)
- "Your fingers come out with {item}. They didn't feel a thing."  (text, line 258)
- "%d credits, and they didn't feel a thing."  (message, line 263)

*When:* caught

- "[Civil Protection] A Civil Protection unit saw that."  (chat message, line 270)

*When:* part of: pick pocket

- "They feel your hand and spin round. 'Thief! Get away from me!'"  (text, line 276)

*When:* part of: inform

- "You reported someone a moment ago. Don't push your luck."  (text, line 280)
- "You give their name to a Civil Protection unit. He writes it down. (+15 standing) They'll be picked up."  (text, line 294)
- "You give their name to a Civil Protection unit. He checks it and looks at you instead. 'Waste of time.' (-5 standing)"  (text, line 298)

## territory that spreads, and is pushed back (sv_livingcity_territory.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_territory.lua`


*When:* a timer (regularly)

- ", and elsewhere"  (text, line 364)
- "We've taken more ground {list}. Hold it."  (text, line 366)
- "Dispatch: anticitizen activity spreading {list}. Civil Protection units are advised to push it back."  (text, line 367)
- "Dispatch: infestation spreading {list}. Containment teams required."  (text, line 369)

*When:* part of: grow territory

- "it's as big as it gets (lc_territory_max)"  (text, line 408)
- "nowhere to grow"  (text, line 411)

*When:* someone moves in

- "Territory: %s grew at %s (r %d), %d patches now"  (message, line 424)

*When:* by: the player whose work it was, if any. The whole city hears who did it.

- "somewhere in the city"  (text, line 458)

*When:* part of: recede territory

- "Dispatch: {who} has retaken anticitizen ground{place}."  (text, line 462)
- "Dispatch: anticitizen ground{place} is retaken."  (text, line 462)
- "We've lost the ground{place}."  (text, line 463)
- "Dispatch: {who} has contained the infestation{place}."  (text, line 465)
- "Dispatch: infestation{place} is contained."  (text, line 465)
- "has retaken ground from the Resistance{place}."  (text, line 468)
- "has contained the infestation{place}."  (text, line 469)
- "[City] {line}"  (chat message, line 470)

*When:* a patch with nobody left in it falls straight away

- "cleared out"  (text, line 526)

*When:* a timer (regularly)

- "pushed back"  (text, line 530)

*When:* part of: pay containment

- "+{credits} credits"  (text, line 559)
- "{ammo} rounds"  (text, line 565)
- "[Civil Protection] Containment pay: %d infested put down. %s."  (message, line 570)

*When:* Commands

- "[Living City] No rebel or infestation zones placed."  (chat message, line 642)

*When:* the console command lc_territory

- "[Living City] %s at %s: %d patch%s grown, next growth in %ds, %d hit%s since the last push-back"  (message, line 645)

*When:* the console command lc_territory_grow

- "[Living City] Usage: lc_territory_grow rebel\|infest"  (chat message, line 654)
- "[Living City] No {kind} zones placed."  (chat message, line 657)
- "[Living City] Grew {kind} territory {or}"  (text, line 659)
- "[Living City] Couldn't grow: {why}"  (text, line 659)

*When:* the console command lc_territory_reset

- "[Living City] Took back {n} grown patch{or}. Only the zones you placed are left."  (chat message, line 670)

## the trains (sv_livingcity_trains.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_trains.lua`

- "the coast"  (text, line 26)
- "the industrial district"  (text, line 26)
- "the outlands transfer"  (text, line 26)
- "Nova Prospekt processing"  (text, line 26)

*When:* part of: train arrive

- "at the station"  (text, line 73)
- "[Station] The train from {from} has arrived {where}."  (chat message, line 75)
- "[Union] A train is in. Arrivals on the platform: your shift."  (chat message, line 76)

*When:* through Civil Intake first, in line with everyone else, if the city has it (sv_livingcity_intake.lua)

- "just off the train, carrying a suitcase"  (what someone is doing, line 91)
- "just off the train"  (text, line 93)

## the underground (sv_livingcity_underground.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_underground.lua`


*When:* A d20 check: a natural 20 always works, a natural 1 never does.

- "somewhere in the city"  (text, line 66)

*When:* Radios

- "Union band"  (text, line 78)

*When:* part of: radio notice

- "[{name}] *static* {text}"  (chat message, line 108)
- "[{name}] {text}"  (chat message, line 110)
- "[Intercept] {text}"  (chat message, line 112)

*When:* part of: radio say

- "You don't have a radio."  (text, line 119)
- "Your radio was taken when you were processed."  (text, line 120)
- "Your radio isn't on that band."  (text, line 122)
- "Static. Something nearby is jamming the band."  (text, line 123)
- "Say what?"  (text, line 125)

*When:* typing in chat

- "[Radio] {why}"  (chat message, line 139)

*When:* City notices reach radios before the loudspeakers.

- "ration distribution"  (text, line 144)
- "civil status inspections"  (text, line 144)
- "a housing block inspection"  (text, line 144)
- "Civil Protection units are gearing up for a sweep. Move anything you don't want found."  (text, line 146)
- "Curfew's coming. Get where you need to be."  (text, line 147)
- "Lockdown incoming. Get off the street."  (text, line 148)
- "Civil Protection units are about to go through a housing block. Anything they find is traced to whoever it belongs to."  (text, line 149)
- "A Combine convoy is coming through. Lots of crates, not many guards."  (text, line 150)

*When:* the Union band only announces the routine ones; the rest are surprises

- "Notice: %s begins in %d seconds."  (message, line 157)

*When:* a timer (regularly)

- "Dispatch: all units, suspect %s, %s. Last seen %s."  (message, line 170)
- "citizen {alias}"  (text, line 171)

*When:* the game's living city incarcerated moment

- "Dispatch: suspect {Nick} in custody."  (text, line 177)

*When:* part of: take off

- "You change back into your own clothes."  (chat message, line 230)

*When:* part of: blow disguise

- "[Disguise] {why} Your disguise is blown."  (chat message, line 238)
- "Impersonating a Civil Protection officer"  (text, line 241)

*When:* filthy clothes: spare citizen clothes are just clean clothes (sv_livingcity_hygiene.lua)

- "You're already in disguise. Take it off first."  (text, line 261)
- "Not now."  (text, line 262)
- "Not in the middle of a fight."  (text, line 263)
- "You don't need a disguise to be a Civil Protection unit."  (text, line 264)
- "You're one of them already. (!gearup puts your own gear on.)"  (text, line 265)

*When:* part of: wear

- "A Civil Protection unit watched you change."  (text, line 278)
- "[Disguise] You're a Civil Protection unit now, as far as anyone on the street can tell. Don't fight, don't linger near real units, and stay away from Combine doors unless you're feeling lucky."  (chat message, line 283)
- "[Disguise] Resistance colours. The fighters in rebel territory will take you for one of them, for a while. Out on the streets, Civil Protection units will take you for one of them too."  (chat message, line 285)
- "[Disguise] Plain clothes. You're just another citizen. Keep your gun out of sight: a Civil Protection unit who sees it will know. (F1 > Gear up to change back.)"  (chat message, line 287)
- "[Disguise] Union blue, like everyone else. Nobody looks twice at a citizen. Until they check your face."  (chat message, line 289)

*When:* part of: disguise door check

- "The door reads your biosignal and sounds an alarm."  (text, line 306)

*When:* Any new crime blows a CP disguise; hunted Resistance get recognized.

- "Civil Protection units don't do that."  (text, line 314)
- "Someone recognized you."  (text, line 316)

*When:* Hanging around real units is the risky part.

- "A Civil Protection unit asks for your designation. You give one that doesn't exist."  (text, line 322)
- "A Civil Protection unit tries to sync with your mask radio. There's nothing to sync with."  (text, line 323)
- "A Civil Protection unit looks at your boots for a long second. They're civilian issue."  (text, line 324)

*When:* A gun in your hand gives plain clothes away.

- "A Civil Protection unit saw the gun in your hand."  (text, line 334)

*When:* A Combine plant in Resistance colours gets asked questions.

- "A fighter asks who vouched for you. You give a name. Nobody knows it."  (text, line 342)
- "Someone asks which cell you're from. You hesitate a moment too long."  (text, line 343)
- "A fighter looks at your boots. Civil Protection issue."  (text, line 344)

*When:* part of: assume identity

- "Not now."  (text, line 394)
- "Not with a Civil Protection unit watching."  (text, line 395)
- "[Papers] As far as the city knows, you're citizen %s now. Nobody is looking for %s."  (message, line 404)
- "[Papers] Your face is still on the notices, though. Citizen clothes would help."  (chat message, line 406)

*When:* (a face the lab changed isn't on any notice: sv_livingcity_lab.lua)

- "Your face matches a wanted notice."  (text, line 417)
- "Your papers don't hold up to a close look."  (text, line 421)

*When:* part of: papers failed

- "Your papers don't check out."  (text, line 427)
- "[Civil Protection] {why}"  (chat message, line 433)
- "Forged identity papers"  (text, line 435)
- "Wanted anticitizen"  (text, line 435)

*When:* Curfew: a permit (or papers that say night shift) gets you past the stop.

- "[Civil Protection] The Civil Protection unit checks your permit and stamps it. You're cleared until this is over."  (chat message, line 446)

*When:* part of: curfew excuse

- "[Civil Protection] Your papers say night shift. The Civil Protection unit waves you on."  (chat message, line 454)

*When:* searcher: a unit (player) or a security NPC.

- "Hands on, the uniform is obviously a costume."  (text, line 524)

*When:* part of: search

- "Search complete. Nothing found."  (chat message, line 534)
- "[Search] {Nick} is clean."  (chat message, line 535)
- "Confiscated: {list}."  (chat message, line 541)
- "Contraband confiscated"  (text, line 542)
- "Possession of contraband"  (text, line 543)
- "[Search] {Nick} was carrying: {list}. Confiscated."  (chat message, line 545)
- "Contraband seized"  (text, line 546)
- "seizure bonus"  (text, line 547)

*When:* A unit searches the person in front of them: three seconds of standing still. What a citizen on the street might be carrying. Sympathizers are far likelier to have something.

- "a Resistance pamphlet"  (text, line 557)
- "an unregistered radio"  (text, line 557)
- "black market rations"  (text, line 557)
- "a crowbar wrapped in newspaper"  (text, line 557)
- "a lambda armband"  (text, line 558)
- "forged ration coupons"  (text, line 558)
- "a handful of pistol rounds"  (text, line 558)

*When:* A unit patting down an NPC citizen: they stop, hands out, and after a few seconds you hear what was on them.

- "You can only search citizens."  (text, line 565)
- "Not now."  (text, line 566)
- "Get closer."  (text, line 567)
- "You searched them a moment ago."  (text, line 569)
- "They're already being searched."  (text, line 570)

*When:* part of: search npc

- "[Search] Patting them down..."  (chat message, line 581)

*When:* a timer (regularly)

- "[Search] Found {contraband}. Confiscated. Right click with the baton to detain them."  (chat message, line 589)
- "[Search] Nothing on them. Papers in order."  (chat message, line 593)

*When:* part of: start search

- "Only Civil Protection units can search people."  (text, line 602)
- "Search who?"  (text, line 605)
- "Only Civil Protection units can search people."  (text, line 606)
- "Not now."  (text, line 607)
- "You don't search other Civil Protection units."  (text, line 608)
- "Get closer."  (text, line 609)
- "They're already being searched."  (text, line 610)
- "They were searched a moment ago."  (text, line 612)
- "[Civil Protection] {Nick} is searching you. Stay still."  (chat message, line 616)
- "[Search] Searching {Nick}..."  (chat message, line 617)

*When:* a timer (regularly)

- "[Search] {Nick} walked away."  (chat message, line 625)
- "Evading a search"  (text, line 626)

*When:* typing in chat

- "[Search] {why}"  (chat message, line 638)

*When:* Processing: anything illegal on you when you're arrested is gone.

- "[Processing] Confiscated: {found}."  (chat message, line 648)

*When:* part of: start stop

- "[Civil Protection] Hold it right there. Stand still for inspection."  (chat message, line 699)

*When:* part of: evaded

- "Hold it! Get back here!"  (text, line 712)
- "[Civil Protection] You walked away from an inspection."  (chat message, line 713)
- "Evading inspection"  (text, line 714)

*When:* part of: run stops

- "[Civil Protection] Papers. Arms out."  (chat message, line 751)

*When:* part of: start pick

- "Not now."  (text, line 836)
- "You're already working on a lock."  (text, line 837)
- "Look at a locked door, up close."  (text, line 841)
- "There's no card reader on that door."  (text, line 845)

*When:* (the old cell locks are mechanical underneath: from the inside, with time, a pick will do)

- "That's a Combine lock. A pick won't touch it."  (text, line 848)
- "It isn't locked."  (text, line 850)
- "It's already open."  (text, line 851)

*When:* a guard was watching the whole time

- "[Civil Protection] A guard takes the pick off you. Two more minutes for the trouble."  (chat message, line 897)

*When:* part of: finish pick

- "Your pick snaps in the lock."  (chat message, line 904)
- "The lock won't give. Try again."  (chat message, line 906)
- "Tampering with Combine technology"  (text, line 915)
- "The reader blinks green. The card won't work twice."  (chat message, line 920)
- "The lock gives."  (chat message, line 920)
- "Unauthorized use of a Civil Protection keycard"  (text, line 922)
- "Breaking and entering"  (text, line 922)

*When:* a timer (regularly)

- "You stop working on the lock."  (text, line 936)

*When:* Forging papers

- "Not with someone watching. Get out of sight first."  (text, line 953)
- "Not with a Civil Protection unit watching."  (text, line 954)

*When:* part of: forge

- "[Papers] Name, number, stamp. It looks right. It has to."  (chat message, line 958)
- "[Papers] The ink bleeds across the number. The form is ruined."  (chat message, line 961)

*When:* part of: stash store

- "Your stash is at home, in your own block."  (text, line 991)
- "That's Combine issue: it stays with you (or another unit)."  (text, line 993)
- "Your stash is full."  (text, line 994)

*When:* part of: stash take

- "Your stash is at home, in your own block."  (text, line 1003)

*When:* part of: stash store weapon

- "Your stash is at home, in your own block."  (text, line 1032)
- "That was issued to you. It stays with you."  (text, line 1035)
- "Your stash is full."  (text, line 1036)
- "You hide the {cls} away."  (text, line 1048)

*When:* part of: stash take weapon

- "Your stash is at home, in your own block."  (text, line 1052)
- "You've one of those on you already."  (text, line 1056)

*When:* the game's living city event started moment

- "[Civil Protection] Your residence%s was searched. Confiscated: %s."  (message, line 1084)
- "in {home}"  (text, line 1085)
- "Contraband found in your residence"  (text, line 1086)

*When:* typing in chat

- "[Stash] Your stash is at home, in {or}."  (chat message, line 1096)
- "Overwatch doesn't shop."  (text, line 1120)
- "The Administrator has people for this."  (text, line 1120)

*When:* What the quartermaster won't buy: the lab decodes it (sv_livingcity_heist.lua, sv_livingcity_lab.lua)

- "Nobody here sells anything to a Civil Protection unit."  (text, line 1125)

*When:* part of: market access

- "Find the dealer."  (text, line 1133)
- "There's no black market here. Try rebel territory, or ask an admin to place a dealer."  (text, line 1134)

*When:* part of: open market

- "[Black market] {why}"  (chat message, line 1140)

*When:* the quartermaster (and no dealer here): he won't buy the Combine's data; the lab decodes it

- "Not enough credits"  (text, line 1150)
- "Too much to carry"  (text, line 1151)

*When:* At the quartermaster: a chip decoded, from his menu.

- "[Quartermaster] {why}"  (chat message, line 1179)
- "[Quartermaster] He plugs it into a battered laptop and reads. 'This is good. Get the word out.'"  (chat message, line 1180)

*When:* part of: black buy

- "Not enough credits."  (text, line 1209)
- "[Black market] %s, for %d credits. You didn't get it here."  (message, line 1213)

*When:* Sell one of something (or all of it): pocket items, or a weapon as "w:<class>".

- "That was issued to you. The dealer doesn't want it."  (text, line 1225)

*When:* part of: dealer sell

- "[Black market] Sold: %s, for %d credits."  (message, line 1228)
- "The quartermaster doesn't buy those. Take it to the lab: the scientist decodes them."  (text, line 1235)
- "[Black market] Sold: %s%s, for %d credits."  (message, line 1242)

*When:* the game answering something done in a window (lcu_buy)

- "[Black market] {why}"  (chat message, line 1249)

*When:* the game answering something done in a window (lcu_sell)

- "[Black market] {why}"  (chat message, line 1256)

*When:* part of: bust dealer

- "[Civil Protection] The dealer bolts. You confiscate what's left of the stock."  (chat message, line 1266)
- "black market busted"  (text, line 1267)
- "Busted a dealer"  (text, line 1268)
- "The dealer {GetPos} got raided. Stay away for a while."  (text, line 1271)

*When:* Inventory actions and what the inventory window needs to know !pick (or bind a key to lc_pick): use the right tool you're carrying on the door you're looking at.

- "Look at a locked door, up close."  (text, line 1297)

*When:* part of: quick pick

- "That's a Combine lock. You need a keycard or a bypass charge."  (text, line 1304)
- "You don't have a lockpick. Make one from four pieces of scrap (F2), or find the dealer."  (text, line 1304)

*When:* bend four bits of scrap into something that opens a lock

- "You need four pieces of scrap."  (text, line 1337)
- "You bend and file the scrap into a lockpick set."  (text, line 1342)

*When:* part of: underground action

- "[Stash] {why}"  (chat message, line 1349)
- "Keep it on you. It's shown when a Civil Protection unit stops you during curfew."  (text, line 1362)
- "Talk with !r <message>{or}"  (text, line 1364)
- "Use any ration dispenser."  (text, line 1366)

*When:* Upkeep

- "[Papers] Your borrowed name has worn thin. You're yourself again."  (chat message, line 1400)

*When:* the console command lc_search

- "%s searched: %d item(s) confiscated%s"  (message, line 1422)

*When:* The Resistance's own plain clothes

- "You don't have anything else to wear. (Find some clothes.)"  (chat message, line 1448)

*When:* typing in chat

- "You're already in your own clothes."  (chat message, line 1454)

*When:* a timer (regularly)

- "[Resistance] You're in plain clothes. F1 > Gear up when it's time to fight."  (chat message, line 1465)

## powered vests ("suit power") (sv_livingcity_vest.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_vest.lua`


*When:* Put on a powered vest from your pockets. True, or false and why.

- "You're already wearing one."  (text, line 55)
- "Your own gear has a vest at least as good."  (text, line 56)

*When:* part of: put on vest

- "Powered vest"  (on-screen notice, line 62)
- "On, with some charge in it. Vortigaunts, suit batteries and chargers top it up."  (on-screen notice, line 62)

## vortigaunts (sv_livingcity_vort.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_vort.lua`


*When:* part of: start unshackle

- "Only the Resistance (Member and up) knows how to cut a vortigaunt's shackles."  (text, line 21)
- "Look at a shackled vortigaunt, up close."  (text, line 25)
- "Not with a Civil Protection unit watching."  (text, line 26)
- "[Living City] Someone is working at your shackles."  (chat message, line 27)
- "Cutting the shackles..."  (progress bar, line 28)
- "You stop."  (text, line 29)

*When:* part of: done

- "A Civil Protection unit is watching. Not now."  (chat message, line 33)
- "[Living City] The shackles fall away. The vortessence is yours again: left click strikes, right click charges a vest (yours or a comrade's). The Combine will want you back."  (chat message, line 36)
- "The shackles fall. The vortigaunt is free."  (chat message, line 37)
- "freeing a vortigaunt"  (text, line 38)
- "A vortigaunt has been freed. Welcome it."  (text, line 39)

## the state of the city (sv_livingcity_war.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_war.lua`

- "The Resistance holds a real share of the city. Expect more inspections and raids, ration cuts and a harsher PA. The black market is cheaper while it lasts."  (text, line 407)
- "The Combine holds the whole city. The rebels have gone quiet, and the black market has put its prices up."  (text, line 408)
- "Nobody holds the upper hand. The city goes about its business."  (text, line 409)
- "Civil unrest"  (text, line 411)
- "Full compliance"  (text, line 411)

*When:* part of: set state

- "[City] {name}. {name}"  (chat message, line 419)

*When:* part of: outbreak

- "The infestation {or} has broken out into the streets. Infected are loose nearby. Get indoors, or get armed."  (text, line 485)
- "Dispatch: quarantine breach. All Civil Protection units, contain the infected."  (text, line 488)

*When:* part of: city report

- "[City] Combine %d%%, Resistance %d%%, infested %d%%. %s."  (message, line 516)

*When:* part of: mark1020

- "Only Civil Protection units can call a 10-20."  (text, line 534)
- "Static. Your radio can't get through: there's a jammer nearby."  (text, line 535)
- "[CP net] 10-20: {name} is {where}. Respond for XP; the faster, the more."  (chat message, line 547)
- "[CP net] Your 10-20 is out to every Civil Protection unit for 90 seconds."  (chat message, line 549)

*When:* part of: call backup

- "Only Civil Protection units can call for backup."  (text, line 555)
- "Static. Your radio can't get through: there's a jammer nearby."  (text, line 556)
- "Dispatch already has your last call. Again in %ds."  (message, line 559)
- "[CP net] {Callsign} requests backup {where}. Respond for XP."  (chat message, line 582)
- "[Dispatch] %d unit%s en route to you."  (message, line 584)
- "[Dispatch] No Civil Protection units free nearby. Your 10-20 is out to every unit."  (chat message, line 585)

*When:* part of: backup tick

- "responded to a 10-20"  (text, line 632)
- "[CP net] On scene in %ds. +%d XP."  (message, line 633)
- "[CP net] {p} is on scene."  (chat message, line 634)

*When:* Chat

- "[Dispatch] {why}"  (chat message, line 655)

*When:* typing in chat

- "[CP net] {why}"  (chat message, line 660)

*When:* the console command lc_backup_call

- "[Dispatch] {why}"  (chat message, line 665)

*When:* the console command lc_1020

- "[CP net] {why}"  (chat message, line 666)

*When:* the console command lc_outbreak

- "[Living City] No infestation zones placed."  (chat message, line 671)
- "[Living City] Outbreak started."  (chat message, line 672)
- "[Living City] Nowhere for them to break out to."  (chat message, line 672)

*When:* Talk on the street What's happened in the city lately, as people heard it. Press E on a citizen and now and then they'll pass something on. Units mostly get nervous silence.

- "over that way"  (text, line 689)
- "'I didn't see anything, officer.'"  (text, line 714)
- "'Nothing to report. Nothing at all.'"  (text, line 714)
- "'I keep my head down. Like we're told.'"  (text, line 714)

*When:* everyone else hears the city's rumours in the talk window (sv_livingcity_talk.lua)

- "They say the Resistance has taken the streets {w}. Civil Protection won't go in."  (text, line 737)
- "Someone told me the rebels are holding ground {w} now. Just walked in and took it."  (text, line 738)

*When:* the game's living city territory grew moment

- "Stay away from {w}. The infected are spreading. I heard them last night."  (text, line 740)
- "My neighbour went {w} for scrap. Didn't come back. They say it's crawling with them now."  (text, line 741)

*When:* the game's living city territory receded moment

- "The Combine cleared the rebels out {w}. There was a lot of shooting."  (text, line 748)
- "I heard Civil Protection took back the ground {w}. Nobody's saying what happened to the people there."  (text, line 749)
- "Civil Protection burned out the infected {w}. You can still smell it."  (text, line 751)
- "They say it's safe {w} again. I wouldn't bet on it."  (text, line 752)

*When:* the game's living city skirmish moment

- "Did you hear the shooting? Rebels hit the Combine {or}."  (text, line 758)
- "The Resistance went after a checkpoint {or}. Brave, or stupid."  (text, line 759)
- "The Combine sent a team into rebel ground {pos}. Armed."  (text, line 761)
- "Civil Protection went into the rebel streets {pos} with guns drawn."  (text, line 762)

*When:* the game's living city outbreak moment

- "The infected broke out {pos}. People didn't make it."  (text, line 767)
- "They had to lock everything down. The things came out of {pos}."  (text, line 768)

*When:* the game's living city block raided moment

- "They tore {name} apart looking for contraband. Took people, too."  (text, line 773)
- "Did you hear about {name}? Doors kicked in, the lot."  (text, line 774)

*When:* the game's living city dealer busted moment

- "The dealer {GetPos} got raided. Don't go asking for him."  (text, line 779)

*When:* the game's living city incarcerated moment

- "They took {name} away. {or}"  (text, line 787)
- "Have you seen {name}? Civil Protection came for them."  (text, line 788)

*When:* the game's living city person killed moment

- "They killed {name}. Civil Protection. In the street, in front of everyone."  (text, line 794)
- "is dead. Nobody will say who did it."  (text, line 795)

*When:* the game's living city state changed moment

- "Everyone's on edge. The Combine are losing the streets, and they know it."  (text, line 800)
- "Rations are short again. That's what happens when the rebels are winning."  (text, line 801)
- "It's quiet. Too quiet. The Combine have the whole city now."  (text, line 803)
- "Haven't heard a shot in days. I don't know if that's good."  (text, line 804)

## ways to get by (sv_livingcity_ways.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_ways.lua`


*When:* part of: ways to get by

- "Buy a market stall at the Commissary (%d credits) and set it down; or look at the one you have, with your pockets open."  (message, line 60)
- "A CWU business license (%d credits), then a stall, both at the Commissary."  (message, line 62)
- "Needs Civil Standing 50 (you have %d)"  (message, line 63)
- "A fishing line (Commissary, %d credits): Fish from your pockets, at the water."  (message, line 67)
- "Needs Civil Standing %d (you have %d)"  (message, line 75)

## occupations (sv_livingcity_work.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_work.lua`


*When:* part of: set job

- "No such job."  (text, line 56)
- "The Union isn't taking anyone on for that."  (text, line 57)
- "The Union only employs citizens."  (text, line 59)
- "The Union only employs registered citizens. Register at Civil Intake first."  (text, line 61)
- "You can change jobs again in {CurTime} seconds."  (text, line 64)
- "[Union] You are now employed as: {name}. Your shifts appear on your board (F3)."  (chat message, line 81)

*When:* part of: give union work

- "Union work assignment"  (on-screen notice, line 111)
- "You are assigned: {name}. Report to the {place}. Your shifts are on F3; ask for another post there."  (on-screen notice, line 111)

*When:* the game answering something done in a window (lcj_set)

- "[Union] {why}"  (chat message, line 121)

*When:* a timer (regularly)

- "[Union] Your post ({name}) has been closed. Pick another job on your board (F3)."  (chat message, line 142)

*When:* Shifts, by job

- "Litter sweep"  (title, line 230)

*When:* part of: sanitation

- "Clear the litter {GetPos}."  (description, line 231)
- "Pick up the litter (press E)"  (text, line 233)

*When:* part of: text

- "Empty bin %d of 3, %s"  (message, line 251)
- "Bin round"  (title, line 259)
- "Three bins, overflowing again."  (description, line 259)

*When:* part of: stages

- "Graffiti removal"  (title, line 265)
- "Graffiti reported {GetPos}."  (description, line 266)
- "Go to the reported graffiti"  (quest step, line 268)
- "Someone has sprayed a lambda and a name across the wall. You know the name: your neighbor's boy."  (quest choice, line 269)
- "Scrub all of it off."  (text, line 270)
- "Scrub the name. Leave the lambda."  (text, line 271)

*When:* part of: success

- "Somebody will see that lambda tomorrow and feel a little less alone."  (quest narration, line 275)

*When:* part of: fail

- "A Civil Protection unit on the corner watches you skip it."  (quest narration, line 278)
- "Defacing city property"  (text, line 279)

*When:* part of: stages

- "Report the name to a Civil Protection unit."  (text, line 281)

*When:* part of: pick

- "Report the name to a Civil Protection unit (press E)"  (quest step, line 284)

*When:* part of: stages

- "Scrub the wall (crouch)"  (quest step, line 287)

*When:* part of: kitchen

- "The sealing line"  (title, line 308)
- "Bars and gel, sealed in foil, by the thousand. Split packs don't leave the plant."  (description, line 309)
- "Go to the ration plant"  (quest step, line 310)
- "Seal ration packs on the line"  (quest step, line 310)

*When:* part of: stages

- "Supply run"  (title, line 318)
- "The supply truck is waiting {GetPos}. Bring the driver's crate of sealed packs in."  (description, line 319)
- "Get the ration crate from the truck driver (press E)"  (text, line 321)
- "'Sign here. No, nobody has a pen. Just take it.'"  (text, line 321)
- "Hand the crate to the dispenser attendant (press E)"  (text, line 322)
- "She counts the packs twice and doesn't say what the number should have been."  (text, line 323)
- "The count"  (title, line 331)
- "Every pack in the dispensers is on the register. Every pack. Count them."  (description, line 332)
- "Go to the dispensers"  (quest step, line 334)
- "Count the packs against the register"  (quest step, line 335)
- "The count is three short. Nobody signed for them, and the register doesn't care whose fault that is."  (quest choice, line 336)
- "Report the shortfall."  (text, line 337)

*When:* part of: pick

- "The supervisor writes it down. Somebody is going to have a very bad week. It isn't you."  (quest narration, line 340)

*When:* part of: stages

- "Make the numbers match."  (text, line 342)

*When:* part of: pick

- "A stroke of the pen and the register agrees with the shelves. Nobody will ever know. Probably."  (quest narration, line 344)

*When:* part of: stages

- "Make it six short, and pocket three."  (text, line 346)

*When:* part of: success

- "Three packs go up your sleeve. The register will blame whoever was here before you."  (quest narration, line 350)

*When:* part of: fail

- "A dispenser attendant watches you do it. She doesn't say anything. She doesn't have to."  (quest narration, line 353)
- "Ration fraud"  (text, line 354)
- "The counter"  (title, line 366)
- "You check ration cards at line {g} today. One card, one pack, and forged cards don't get either."  (description, line 367)
- "Take your place at the counter"  (quest step, line 369)
- "A card with a smudged stamp and a citizen number that's one digit too long. The man holding it is very thin."  (quest choice, line 370)
- "Confiscate it, and report him."  (text, line 371)

*When:* part of: pick

- "A Civil Protection unit takes him by the arm. The card goes in the box with the others."  (quest narration, line 374)
- "Let it through."  (text, line 376)
- "He takes the pack and doesn't look back. Neither do you."  (quest narration, line 379)
- "Keep the card for yourself."  (text, line 381)

*When:* part of: success

- "'Invalid,' you tell him, and it goes in your pocket instead of the box. He doesn't argue."  (quest narration, line 385)

*When:* part of: fail

- "The supervisor saw the card go in your pocket. 'Ration fraud,' he says, almost bored."  (quest narration, line 388)
- "Ration fraud"  (text, line 389)
- "Hand out the rations (stay at the counter)"  (text, line 393)

*When:* part of: medic

- "Clinic rounds"  (title, line 404)
- "Three patients waiting. Use your medkit on them until they're on their feet."  (description, line 405)
- "Go to the clinic"  (quest step, line 407)
- "Treat the injured (medkit, primary fire)"  (text, line 408)

*When:* part of: stages

- "House call"  (title, line 416)
- "A man was hurt {GetPos}. He can't walk to the clinic."  (description, line 417)
- "Find the injured man (marked)"  (text, line 420)
- "Stunstick bruises, in neat rows. He grabs your wrist. 'Please. Don't write it down. Say I fell.'"  (quest choice, line 429)
- "Log it truthfully."  (text, line 430)
- "Write 'fell down the stairs'."  (text, line 431)

*When:* part of: pick

- "He closes his eyes. 'Thank you.'"  (quest narration, line 434)

*When:* part of: stages

- "Treat him (medkit, primary fire)"  (text, line 437)

*When:* part of: factory

- "Assembly quota"  (title, line 450)
- "Today's quota is posted. Nobody asks what the parts are for."  (description, line 451)
- "Report to the line"  (quest step, line 453)
- "Work the line"  (quest step, line 454)
- "Take the finished part (press E)"  (text, line 455)
- "Carry it to the next station"  (text, line 456)
- "Fit the part"  (quest step, line 457)

*When:* part of: text

- "Collect crate %d of 2 from the loading dock (press E)"  (message, line 468)
- "Bring crate %d to the factory floor"  (message, line 469)
- "Loading dock"  (title, line 471)
- "Two crates, loading dock to the floor."  (description, line 471)

*When:* part of: stages

- "Short count"  (title, line 477)
- "Another shift on the line."  (description, line 478)
- "Report to the line"  (quest step, line 480)
- "Work the line"  (quest step, line 481)
- "The parts count is short again. You watch the foreman slide a box under his coat, and he sees you watching."  (quest choice, line 482)
- "Report him."  (text, line 483)

*When:* part of: pick

- "Report the foreman to a Civil Protection unit (press E)"  (quest step, line 486)

*When:* part of: stages

- "Say nothing."  (text, line 488)
- "Ask for your cut."  (text, line 489)

*When:* part of: pick

- "He grins like you've always been friends."  (quest narration, line 493)

*When:* real letters, from people in the city to people in the city (sv_livingcity_mail.lua)

- "Collect today's letters from the postal clerk (press E)"  (text, line 509)
- "'Real post, for once. Mind none of it goes astray.'"  (text, line 510)

*When:* part of: courier

- "Deliver letter %d of %d to %s (push it under their door)"  (message, line 526)

*When:* they're yours from the moment you start

- "The real mail"  (title, line 537)

*When:* part of: courier

- "letter{or} from people in the city, to people in the city."  (description, line 538)

*When:* part of: claimed

- "an apartment doorway"  (text, line 548)

*When:* the mail comes from the clerk at the post office, and goes to people, by hand

- "Collect the mail from the postal clerk (press E)"  (text, line 556)
- "'Three for the district. Two are overdue. Don't tell them I said so.'"  (text, line 557)
- "Hand letter %d of 3 to %s, %s (press E)"  (message, line 561)
- "They take it without looking at who sent it."  (text, line 562)
- "'Finally,' they say, and shut the door on the rest of the sentence."  (text, line 562)
- "A nod. Nobody says anything useful in this city out loud."  (text, line 563)
- "They read the envelope twice before they put it away."  (text, line 563)

*When:* part of: claimed

- "Mail round"  (title, line 566)
- "Three letters, three people. Collect them at the post office."  (description, line 566)

*When:* part of: stages

- "Sealed envelope"  (title, line 574)
- "One envelope, Civil Protection seal, to be delivered {GetPos}."  (description, line 575)
- "Collect the envelope from the clerk (press E)"  (text, line 577)
- "'Hand it over in person. Nobody signs for these.'"  (text, line 577)
- "The seal is a Combine stamp. It's not glued very well."  (quest choice, line 578)
- "Deliver it unopened."  (text, line 579)
- "Steam it open."  (text, line 580)

*When:* part of: success

- "An eviction order. The family in 3B, the one with the twins. Effective tomorrow."  (quest choice, line 582)
- "Deliver it as addressed."  (text, line 583)
- "Warn the family first."  (text, line 584)

*When:* part of: pick

- "Warn the family, quietly"  (quest step, line 587)

*When:* part of: fail

- "The seal tears. You'll have to hope nobody checks."  (quest narration, line 591)

*When:* part of: stages

- "Hand the envelope to the addressee (press E)"  (text, line 593)
- "They take it with both hands, like it might go off."  (text, line 593)

*When:* the city's own streetlights, the broken ones first (sv_livingcity_propaganda.lua)

- "Fix streetlight %d of %d, %s"  (message, line 607)

*When:* part of: maintenance

- "Lights out"  (title, line 614)
- "Streetlights down across the district."  (description, line 614)
- "Repair fuse box %d of 3, %s"  (message, line 620)
- "Lights out"  (title, line 625)
- "Three fuse boxes down across the district."  (description, line 625)

*When:* part of: stages

- "Terminal fault"  (title, line 632)
- "A checkpoint scanner terminal is throwing faults."  (description, line 633)
- "Go to the faulty terminal"  (quest step, line 635)
- "Repair the terminal"  (quest step, line 636)
- "The terminal's log scrolls past while it reboots. One of last night's entries is your neighbor, at 3 a.m."  (quest choice, line 637)
- "Leave the log intact."  (text, line 638)
- "Corrupt that entry while you're in there."  (text, line 639)

*When:* part of: success

- "One line of the log becomes noise. Terminals glitch all the time."  (quest narration, line 643)

*When:* part of: fail

- "The terminal flags the edit. Every Civil Protection unit in the sector gets the alert."  (quest narration, line 646)
- "Tampering with a city terminal"  (text, line 647)

*When:* Somewhere people live: a housing block, an apartment doorway, or a street.

- "an apartment doorway"  (text, line 669)

*When:* Somewhere Civil Protection works: a checkpoint, the prison, or a street.

- "the checkpoint"  (text, line 677)
- "the prison"  (text, line 679)

*When:* Intake Processor

- "New arrivals"  (title, line 718)
- "A train came in. One of the new arrivals needs walking to their assigned housing."  (description, line 719)

*When:* part of: porter

- "Meet the new arrival on the platform (marked)"  (text, line 722)
- "He's holding a transfer slip like it might bite him. Under his breath: 'Is there anywhere in this city they don't look?'"  (quest choice, line 731)
- "'Your block. Keep your head down.'"  (text, line 732)
- "Tell him about the canals, and walk him there instead."  (text, line 733)

*When:* part of: pick

- "He doesn't say thank you. He doesn't have to."  (quest narration, line 740)

*When:* part of: porter

- "Repeat the question to a Civil Protection unit."  (text, line 742)

*When:* part of: pick

- "A Civil Protection unit takes him by the arm. He looks back at you once."  (quest narration, line 746)

*When:* part of: porter

- "Walk him to his new home"  (text, line 751)

*When:* part of: on enter

- "Walk him to {or}"  (text, line 756)

*When:* part of: text

- "A suitcase was left on the platform. It goes to its owner, {destName}."  (description, line 768)
- "Collect the suitcase from the platform (press E)"  (text, line 771)
- "The suitcase is heavier than clothes. Something inside slides and settles, like a stack of paper."  (quest choice, line 772)
- "Carry it. It's not your business."  (text, line 773)
- "Take a look inside."  (text, line 774)

*When:* part of: success

- "Under the shirts: a stack of blank identity forms. You take one. Nobody counts them twice."  (quest narration, line 776)

*When:* part of: fail

- "The latches snap open loud enough to turn heads. A Civil Protection unit is already walking over."  (quest narration, line 781)
- "Theft from a traveler"  (text, line 782)

*When:* part of: text

- "Hand it to Civil Protection."  (text, line 784)

*When:* part of: pick

- "Hand the suitcase to a Civil Protection unit (press E)"  (quest step, line 788)

*When:* part of: text

- "Return the suitcase to its owner, {destName} (press E)"  (text, line 791)
- "'That's mine. I thought I'd lost it.' They don't say thank you."  (text, line 791)
- "Ticket check"  (title, line 799)
- "Tickets and transit permits, everyone boarding."  (description, line 800)
- "Go to the platform"  (quest step, line 802)
- "Check three travelers' tickets (press E on citizens)"  (quest step, line 803)
- "An old woman has a ticket, but no transit permit. "I'm going to see my son," she says. "He's in Nova Prospekt.""  (quest choice, line 804)
- "Let her board."  (text, line 805)

*When:* part of: success

- "She squeezes your hand on the way past. It's the last train she'll ever take, and you both know it."  (quest narration, line 809)

*When:* part of: fail

- "The platform scanner flags her before she reaches the door. And you, for letting her through."  (quest narration, line 812)
- "Aiding unauthorized travel"  (text, line 813)
- "Turn her back."  (text, line 815)
- "Call a Civil Protection unit."  (text, line 816)

*When:* part of: pick

- "Report her to a Civil Protection unit (press E)"  (quest step, line 819)

*When:* a real body if the city has left one lying about, or a reported one

- "Collect the body {GetPos}"  (quest step, line 867)

*When:* part of: mortuary

- "A body was reported {GetPos}. Nobody has claimed it."  (description, line 884)
- "His coat pocket holds identity papers, still valid. Nobody has reported him dead yet."  (quest choice, line 888)
- "Turn everything in."  (text, line 889)
- "Keep his papers."  (text, line 890)

*When:* part of: pick

- "They're good papers. They'll be good for somebody."  (quest narration, line 893)

*When:* part of: mortuary

- "Find his family first."  (text, line 895)

*When:* part of: pick

- "Tell his family, {homeName}"  (quest step, line 897)

*When:* part of: mortuary

- "Haul him (E on the body to drag, E to let go)"  (text, line 900)
- "Haul %d bodies off the streets to %s"  (message, line 914)
- "Clear the streets"  (title, line 917)
- "There's been trouble. The city wants the streets clean before morning."  (description, line 918)

*When:* part of: stages

- "Work the incinerator"  (quest step, line 927)
- "The incinerator runs all night. Somebody has to feed it."  (description, line 931)
- "Go to the incinerator"  (quest step, line 933)
- "Go to the morgue"  (quest step, line 933)
- "The next one still has a wedding ring on."  (quest choice, line 935)
- "Leave it on her."  (text, line 936)
- "Pocket the ring."  (text, line 937)
- "Set it aside for the family."  (text, line 941)
- "Bag the dead headcrabs (press E on each)"  (text, line 966)
- "Take them to {name} and burn them"  (text, line 970)
- "Headcrab collection"  (title, line 973)
- "Dead headcrabs left lying in the street breed flies and worse. Bag them and burn them."  (description, line 974)

*When:* Reclamation Crew

- "Scrap run"  (title, line 989)
- "Metal {GetPos}. The Union needs all of it."  (description, line 990)

*When:* part of: scrap

- "Collect the scrap (press E)"  (text, line 993)
- "One good piece of copper wasn't on anybody's list."  (quest choice, line 994)
- "Log it."  (text, line 995)
- "Keep it for the dealer."  (text, line 996)
- "Bring it to the reclamation yard"  (text, line 1001)
- "Clear rubble %d of 3, %s"  (message, line 1010)
- "Under the bricks: a canvas bag. Inside, a pistol and a magazine wrapped in oilcloth. Someone hid it here on purpose."  (quest choice, line 1014)
- "Report the cache."  (text, line 1015)

*When:* part of: pick

- "Report the cache to a Civil Protection unit (press E)"  (quest step, line 1018)
- "Leave it where it is."  (text, line 1020)
- "You put the bricks back exactly how they were."  (quest narration, line 1022)
- "Take it."  (text, line 1024)
- "A Civil Protection unit saw the oilcloth come out of the rubble."  (quest narration, line 1028)
- "Possession of a firearm"  (text, line 1029)
- "It's cold and heavy and nobody saw."  (quest narration, line 1031)
- "Rubble clearing"  (title, line 1035)
- "Three rubble piles from the old city."  (description, line 1035)
- "Work the line: rust-red, sparking parts in the scrap bin (E to grab, left click to throw); good ones through"  (text, line 1100)

*When:* part of: litter

- "Street sweep"  (title, line 1110)
- "Your cart's at the depot. The streets are a mess. Pay for every piece in the cart."  (description, line 1111)
- "Go to the sanitation depot: your cart's there"  (text, line 1113)
- "Fill the cart and bring it back: E pushes it, E picks up rubbish, left click throws it in"  (text, line 1114)

*When:* part of: quota

- "On the line"  (title, line 1125)
- "The line runs all day. Bad parts don't leave the floor."  (description, line 1126)
- "Report to the line"  (text, line 1127)

*When:* part of: seal

- "The sealing line"  (title, line 1136)
- "Bars and gel, sealed in foil, by the thousand. Split packs don't leave the plant."  (description, line 1137)
- "Report to the sealing line"  (text, line 1138)
- "Work the sealing line: split, leaking packs (sickly green) in the reject bin (E to grab, left click to throw); sealed ones through"  (text, line 1139)

*When:* The loading dock (two crates, a long walk each way) is the Intake Processor's work now; the factory floor gets more of the line instead (the owner: "an absolute grind").

- "Freight from the dock"  (description, line 1154)
- "Two crates off the loading dock, to the station."  (text, line 1154)

*When:* part of: text

- "Overtime on the line"  (title, line 1166)
- "The quota went up again. The line doesn't stop for you."  (description, line 1167)
- "Report to the line"  (text, line 1168)
- "Overtime on the line"  (title, line 1172)
- "The quota went up again."  (description, line 1172)
- "Report to the line"  (quest step, line 1173)
- "Work the line"  (quest step, line 1173)

*When:* Maintenance: every repair is a wiring panel

- "Rewire it: turn the tiles till the current reaches the lamp (a sparking tile bites)"  (text, line 1182)
- "the terminal"  (text, line 1183)
- "the box"  (text, line 1183)

*When:* Clinic Medic: rounds are triage

- "Patients coming in, and not enough of you. The worst first."  (description, line 1197)

*When:* part of: rounds

- "Go to the clinic"  (text, line 1199)
- "Treat them before they bleed out (medkit, primary fire): the bars over their heads say who's worst"  (text, line 1200)

*When:* Reclamation Crew: rubble is something you break up

- "Break up the rubble (crowbar, primary fire)"  (text, line 1209)

*When:* part of: ticket

- "Check the travelers' papers: E on each, then approve, deny or call a Civil Protection unit"  (text, line 1217)
- "Papers check"  (title, line 1218)
- "Papers and permits, everyone boarding. Today's rules are posted."  (description, line 1220)

*When:* Courier: a parcel run against the clock (they aren't letters)

- "an apartment doorway"  (name, line 1235)

*When:* part of: desc

- "Parcel run"  (title, line 1244)
- "Three parcels, against the clock. They aren't letters, and nobody says what's in them."  (description, line 1245)
- "Collect the parcels at the post office"  (text, line 1247)
- "Deliver the parcels against the clock (marked): Civil Protection units stop couriers they get a good look at, so crouch past them"  (text, line 1248)

*When:* part of: incinerator

- "Before the fire"  (title, line 1263)
- "Three for the incinerator tonight. Every pocket first. Nobody checks your work, except when they do."  (description, line 1264)
- "Go to the incinerator"  (text, line 1266)
- "Go to the morgue"  (text, line 1266)
- "Search the dead before they go in: E on the body, every pocket, then into the fire"  (text, line 1267)
- "Civil Protection uniforms, washed and pressed, and every one back to its own division. Civil Protection units leave things in their pockets."  (text, line 1282)
- "Go to the Nexus laundry"  (text, line 1283)
- "Sort the uniforms by division (the bins say which); bloodstained ones to the incident wash. E brings the pile back"  (text, line 1283)
- "The in-tray, by citizen number. Anything that doesn't match the register goes in the discrepancy tray."  (text, line 1284)
- "Go to the civil records office"  (text, line 1285)
- "File every form in its drawer; mismatches to the discrepancy tray. E brings the in-tray back"  (text, line 1285)
- "Four sets on the shelf, all hissing. Find each one's station, then set its screws until it comes through clean."  (text, line 1286)
- "Go to the radio repair shop"  (text, line 1287)
- "Repair the sets: find the station on the dial, then turn the screws by ear until it's clean. E brings the bench back"  (text, line 1287)

*When:* (tests: finish a game at once)

- "Union shift"  (name, line 1296)
- "Civil rehabilitation"  (name, line 1339)

*When:* part of: build

- "Community service: {desc}"  (title, line 1349)

## writing, broadcasts, and the law (sv_livingcity_writing.lua)

`gamemodes/livingcity/gamemode/modules/server/sv_livingcity_writing.lua`


*When:* part of: open writer

- "You need paper."  (text, line 78)

*When:* mode: "note" (on the ground), "poster" (on the wall you're looking at), "keep" (in your pockets)

- "Write something."  (text, line 128)
- "You need paper."  (text, line 129)
- "Your hands are tied."  (text, line 130)

*When:* part of: write note

- "You can't carry any more notes. Drop one first."  (text, line 134)
- "You fold the note into your pocket."  (text, line 138)
- "You've got enough of your writing out there already."  (text, line 140)
- "Look at a wall to put it up on."  (text, line 145)
- "You put it up."  (text, line 165)
- "You leave the note."  (text, line 165)

*When:* part of: take note

- "You can't carry any more notes."  (text, line 194)
- "You take it."  (text, line 200)

*When:* part of: tear down

- "unauthorised notice removed"  (text, line 210)
- "You tear it down."  (text, line 211)

*When:* who it could be posted to, as a letter (sv_livingcity_mail.lua)

- "You've got enough of your writing out there already."  (text, line 226)

*When:* part of: carried note

- "You tear it up."  (text, line 241)

*When:* part of: broadcast

- "Only the City Administrator speaks to the whole city."  (text, line 295)
- "Say something."  (text, line 297)
- "Give the city a moment."  (text, line 298)
- "The City Administrator"  (text, line 300)
- "The City Administrator"  (text, line 301)
- "[{who}] {text}"  (chat message, line 309)

*When:* The law

- "Obey the instructions of Civil Protection at all times."  (text, line 319)
- "Carry your identification. Present it when asked."  (text, line 320)
- "Curfew is absolute. Be in your residence when it is called."  (text, line 321)
- "Gatherings of more than three citizens require a permit."  (text, line 322)
- "Do not run. Do not loiter. Do not obstruct a Civil Protection unit."  (text, line 323)
- "Possession of weapons, unregistered radios or Resistance materials is forbidden."  (text, line 324)
- "Report anticitizen activity. Inaction is conspiracy."  (text, line 325)
- "Rations are allocated by standing. Do not take what is not yours."  (text, line 326)

*When:* part of: set law

- "Only the City Administrator writes the law."  (text, line 349)
- "Write the law."  (text, line 353)
- "No such law."  (text, line 356)
- "Laws go from 1 to {list}."  (text, line 359)
- "[City] The law has changed. C > The city > The city's laws."  (chat message, line 363)

*When:* Chat

- "Usage: !setlaw <number> <text>"  (chat message, line 403)

*When:* part of: dellaw

- "Usage: !dellaw <number>"  (chat message, line 409)

## acts (shared) (sh_livingcity_acts.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_acts.lua`


*When:* name = { sequences to try (first found wins), activity to fall back to, eye height, what it's called }

- "lying down"  (label, line 24)
- "hands up"  (label, line 31)

## sh_livingcity_cp.lua (sh_livingcity_cp.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_cp.lua`


*When:* on the street

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

*When:* warnings and arrests

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

*When:* on the radio and in a fight

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

*When:* Overwatch soldiers sound different.

- "Copy that."  (text, line 75)
- "Move in."  (text, line 77)
- "Lost contact."  (text, line 78)

*When:* City-wide sociostability. Set by events and the state of the city, or by an officer (or an admin) for a while.

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
- "Father Grigori"  (name, line 74)
- "Chaplain of the Resistance. A priest who will not let faith die under the Combine. He tends the wounded with his Blessing and preaches the Word aloud. The Combine have declared his faith contraband, so Civil Protection hunts him on sight outside rebel territory."  (description, line 75)
- "Free Vortigaunt"  (name, line 83)
- "A vortigaunt with the shackles off, fighting beside the people who freed it. Its vortessence heals (right click) and strikes (left click). The Combine want it back in chains, and hunt it on sight."  (description, line 84)

*When:* One career, from the records office to the Overwatch. The Overwatch ranks (overwatch = true) need the transhuman conditioning first: the Overwatch Candidate story offers it to Division Leaders. Without it, XP keeps counting but the rank stops at Division Leader.

- "Civil Protection"  (name, line 97)
- "Civil Protection: the records office, the Metropolice, and for the best of them, the Overwatch. Earn your way up. Past Division Leader there is no going back to being human."  (description, line 98)
- "Record Keeper"  (name, line 101)
- "Division Leader"  (name, line 104)
- "Combine Prison Guard"  (name, line 105)
- "Combine Soldier"  (name, line 107)
- "Elite Soldier"  (name, line 109)
- "Scanner Operator"  (name, line 114)
- "Two at a time, from any rank. Flies a city scanner from a Combine console or data terminal, or anywhere in the Nexus (F1 > Unit tools). Photographs earn XP, and a rebel caught on camera goes out to every Civil Protection unit as a BOLO."  (description, line 115)
- "Overwatch Commander"  (name, line 123)
- "One at a time, from the Elite. Calls in an Overwatch squad by dropship (F1 > Unit tools), every fifteen minutes, and commands every Civil Protection unit in the city."  (description, line 124)
- "A shackled vortigaunt: Combine property, put to work on the city's dirtiest labour. The collar holds your vortessence in. The Resistance can cut the shackles (!unshackle), if they reach you."  (description, line 134)
- "Trusted Laborer"  (name, line 138)
- "Overseer's Hand"  (name, line 139)
- "City Administrator"  (name, line 143)
- "The face of the city's government. Whitelisted by staff."  (description, line 144)
- "Director of Propaganda"  (name, line 150)
- "The city's voice. Carries the microphone: on air over every loudspeaker and screen, a minute at a time, when the transmitter is ready. Keep hold of it: the Resistance would love to use it."  (description, line 151)

*When:* not chosen: made. The worst anticitizens the city catches (sv_livingcity_custody.lua)

- "What the Combine make of the anticitizens they can't use any other way. Combine property: slow, unarmed, made to work. It lasts until you die, or the city has had its use of you."  (description, line 161)
- "What the headcrabs left behind. NPC zombies are your kin. Everyone else is food, and knows it."  (description, line 170)
- "Fast Zombie"  (name, line 174)

## sh_livingcity_jobs.lua (sh_livingcity_jobs.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_jobs.lua`

- "Sanitation Worker"  (name, line 19)
- "Sanitation depot"  (text, line 19)
- "Litter, bins, graffiti. The city must look clean, whatever it is."  (description, line 20)
- "Ration Production"  (name, line 21)
- "Ration plant"  (text, line 21)
- "Seal the packs on the line, count them against the register, and catch the forged cards at the counter. Nobody cooks: rations are made, not cooked."  (description, line 22)
- "Clinic Medic"  (name, line 23)
- "Patch people up. Write down what happened. Decide what really happened."  (description, line 24)
- "Factory Worker"  (name, line 25)
- "Quotas, parts and loading docks. Nobody asks what the parts are for."  (description, line 26)
- "Post office"  (text, line 27)
- "Letters, parcels and sealed envelopes to every block in the district."  (description, line 28)
- "Maintenance Technician"  (name, line 29)
- "Maintenance yard"  (text, line 29)
- "Fuse boxes, streetlights and Combine terminals. You see a lot of logs."  (description, line 30)
- "Intake Processor"  (name, line 31)
- "Train station"  (text, line 31)
- "Papers, tickets, luggage and new arrivals who don't know where anything is yet."  (description, line 32)
- "Records Clerk"  (name, line 33)
- "Civil records office"  (text, line 33)
- "Stamps, files and identity forms. The cabinet with the blank ones is rarely locked."  (description, line 34)
- "Uniform Laundry"  (name, line 35)
- "Nexus laundry"  (text, line 35)
- "Civil Protection uniforms, washed, pressed and counted. Usually counted."  (description, line 36)
- "City morgue"  (text, line 37)
- "Collect the dead. Process what they leave behind. Nobody checks your work."  (description, line 38)
- "Reclamation Crew"  (name, line 39)
- "Reclamation yard"  (text, line 39)
- "Scrap and rubble from the old city. Some of it was hidden there on purpose."  (description, line 40)
- "Radio Repair"  (name, line 41)
- "Radio repair shop"  (text, line 41)
- "Loudspeakers and Union radios. Some come in tuned to frequencies that don't exist."  (description, line 42)

## sh_livingcity_shop.lua (sh_livingcity_shop.lua)

`gamemodes/livingcity/gamemode/modules/shared/sh_livingcity_shop.lua`


*When:* Items you can carry (inventory: F2 or !inv) hunger, thirst   how much they restore (0 to 100 scale) parasite         chance of catching parasites when consumed breen            Dr. Breen's Private Reserve side effects leaves           item left in your pocket afterwards (the empty can) cooksTo          what it becomes over a stove or fire fillTo           what it becomes when filled from water cures            status it removes

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

*When:* rain caught straight from the sky: clean enough as it is (no boiling)

- "Can of rainwater"  (name, line 49)
- "Bottle of rainwater"  (name, line 50)

*When:* Your own papers (sv_livingcity_intake.lua): Civil Intake issues them when you register, and replaces them (for a fee) if you lose them. doc   one of your documents: weighs nothing, takes no room, and can't be dropped or handed over (stashing them is up to you)

- "Identity papers"  (name, line 58)
- "Your name, your citizen number, your block. Show: to whoever you're looking at (Civil Protection units ask), or read them yourself"  (description, line 60)
- "Ration card"  (name, line 61)
- "Union-issue. The ration dispensers want to see it. Lost? Civil Intake issues another, for a fee"  (description, line 62)

*When:* Things that change what you can do (see sv_livingcity_underground.lua) contraband   illegal to carry: searches look for it conceal      base chance it slips past a search (Guile adds to it) sell         what the dealer pays for it radio        "union" (public band, early event notices) or "resistance" (Freq 7, plus intercepted CP dispatch) permit       excuses you from one curfew or lockdown stop papers       "forged" or "dead": assume a new identity, which clears your wanted status and passes inspections (mostly) forge        turn it into forged papers somewhere private (Guile check) rationCard   a free ration from any dispenser, whatever your standing wear         a disguise: "cp" fools security NPCs and opens CP doors, "citizen" lets hunted Resistance pass as ordinary citizens tool         "lockpick" for locked doors, "bypass" for Combine doors too

- "Union radio"  (name, line 79)
- "Union band. Hear city notices before the loudspeakers do. Talk with !r"  (description, line 80)
- "Tuned to Freq 7, the Resistance's: their chat, sweep warnings, and whatever Civil Protection says when it thinks nobody is listening"  (description, line 83)
- "Travel permit"  (name, line 84)
- "Stamped and legal. Gets you past one curfew stop"  (description, line 85)
- "Blank identity form"  (name, line 86)
- "Fill it in somewhere private and it becomes somebody"  (description, line 88)
- "Forged papers"  (name, line 89)
- "A new name. Clears your wanted status if no Civil Protection unit is watching"  (description, line 91)
- "A dead man's papers"  (name, line 92)
- "Genuine papers. Their owner won't be needing them"  (description, line 94)
- "Forged ration card"  (name, line 95)
- "One extra ration from any dispenser, whatever your standing"  (description, line 97)
- "Civil Protection uniform"  (name, line 98)
- "Mask and all. Civil Protection units on the street will take you for one of them, mostly"  (description, line 100)
- "Union work overalls"  (name, line 101)
- "Union-issue, a little worn. Lets anyone pass as an ordinary citizen"  (description, line 102)
- "Resistance gear"  (name, line 103)
- "Off a dead fighter. The fighters in rebel territory will take you for one of them. Civil Protection units will too"  (description, line 105)
- "Spare citizen clothes"  (name, line 106)
- "Union blue. Lets a hunted Resistance member pass as an ordinary citizen"  (description, line 107)
- "Lockpick set"  (name, line 108)
- "Look at a locked door and use it. Not Combine locks"  (description, line 110)
- "Combine bypass charge"  (name, line 111)
- "Opens any door once, Combine doors included. Sometimes trips an alarm"  (description, line 113)
- "Civil Protection keycard"  (name, line 114)
- "Off a dead Civil Protection unit. Opens one Combine door before someone reports it missing"  (description, line 116)

*When:* Getting by (sv_livingcity_scavenge.lua) use      what "Use" does from your pockets: "fish", "plant", "spray"

- "Canned beans"  (name, line 121)
- "Pre-war. The label's gone. Probably beans"  (description, line 122)
- "Rooftop vegetables"  (name, line 123)
- "Grown in a pot on a roof somewhere. Real food"  (description, line 124)
- "Raw fish"  (name, line 125)
- "From the canal. Cook it. Really, cook it"  (description, line 126)
- "Fried fish"  (name, line 127)
- "Seed packet"  (name, line 128)
- "Plant them in a pot in rebel territory (look at it and press E, or Plant here)"  (description, line 129)
- "Fishing line"  (name, line 130)
- "Stand in the canal, or look at the water, and wait. Keeps"  (description, line 131)
- "Spray can"  (name, line 132)
- "Look at a wall and spray the lambda. Don't let a Civil Protection unit see you do it"  (description, line 134)

*When:* Making things (sv_livingcity_crafting.lua) arms     weapons and ammunition: the quartermaster pays half as much again use      "heal", "ammo" (ammo = { type, amount }), "arm" (weapon = class), "throw" (grenade = smoke, flash or gas)

- "Clean enough for a bandage"  (description, line 141)
- "Cleaning chemicals"  (name, line 142)
- "Union-issue. Mixed with the right things, they do more than clean"  (description, line 143)
- "Gun parts"  (name, line 144)
- "Springs, a barrel, a firing pin. Off a dead Civil Protection unit, or out of a smuggler's crate"  (description, line 145)
- "Patch up"  (pocket button, line 146)
- "Twenty health, give or take"  (description, line 147)
- "Box of pistol rounds"  (name, line 148)
- "Hand-loaded. Mostly reliable"  (description, line 149)
- "Box of SMG rounds"  (name, line 150)
- "Box of shells"  (name, line 152)
- "Hand-packed shells"  (description, line 153)
- "Homemade pistol"  (name, line 154)
- "Put together on a kitchen table. It fires"  (description, line 155)
- "Homemade shotgun"  (name, line 156)
- "Hard to hide. Hard to argue with"  (description, line 157)
- "It jams. Not often"  (description, line 159)
- "Smoke bomb"  (name, line 160)
- "A can of chemicals and a fuse. Thick white smoke"  (description, line 161)
- "Smoke grenade"  (name, line 162)
- "Civil Protection issue. Nobody sees through it"  (description, line 163)
- "Blinds and deafens anyone who sees it go off"  (description, line 165)
- "Chlorine gas grenade"  (name, line 166)
- "A choking green cloud. Masks protect; nothing else does"  (description, line 167)
- "Smuggled crate"  (name, line 168)
- "Heavy, and it clinks. Get it where it's going"  (description, line 169)
- "Smuggled supplies"  (name, line 170)
- "Guns and parts wrapped in rags, out of a broken crate. Get them where they're going"  (description, line 171)

*When:* Order (sv_livingcity_cp.lua)

- "Zip ties"  (name, line 175)
- "Tie someone's hands: !tie, looking at them (hands up, down, stopped, or from behind). Civil Protection units carry their own"  (description, line 176)
- "Request device"  (name, line 177)
- "Calls Civil Protection to where you are: /request <what's wrong>"  (description, line 178)

*When:* Carrying and keeping things (sv_livingcity_storage.lua) bag      extra kilograms and large things you can carry while you have it place    "crate": set down in the world as your own lockable crate

- "A canvas bag over the shoulder. Room for more, and for something large"  (description, line 185)
- "Storage crate"  (name, line 186)
- "Set it down somewhere (Set down, in your pockets) and it's yours: only you can open it. Civil Protection units can"  (description, line 187)

*When:* Trade and writing (sv_livingcity_business.lua, sv_livingcity_writing.lua)

- "CWU business license"  (name, line 191)
- "Stamped by the Civil Workers' Union. Lets you set up a market stall and trade. Officers can revoke it"  (description, line 192)
- "Market stall"  (name, line 193)
- "A folding table and a sign. Set it down (with a license) and sell from it: you set the prices"  (description, line 194)
- "Write a note to leave somewhere, a poster to put up, or one to keep"  (description, line 196)
- "Scrap metal"  (name, line 197)
- "Out of bins, junk and downed scanners. The dealer pays for it, and so does reclamation"  (description, line 198)
- "Pries scrap out of junk. A weapon too, and every Civil Protection unit knows it"  (description, line 200)
- "Combine data chip"  (name, line 201)
- "Decode / plug in"  (pocket button, line 201)
- "Two terminals' data, put together. The dealer pays well; the lab decodes it; plugged into a terminal it wipes your record"  (description, line 203)
- "Combine data fragment"  (name, line 204)
- "Half of what the Combine know: one terminal's data. Download another terminal's and the two make a whole chip"  (description, line 206)
- "Master data core"  (name, line 207)
- "Decode / plug in"  (pocket button, line 207)
- "Out of the Combine's master terminal: the motherlode. The dealer pays a fortune; the quartermaster's decoding marks every Civil Protection unit for ten minutes; plugged into a terminal it wipes every comrade's record"  (description, line 209)
- "Radio jammer"  (name, line 210)
- "Set down"  (pocket button, line 210)
- "Set it down: four minutes of static on every Civil Protection unit radio nearby, and no scanner photos get out"  (description, line 211)
- "Powered vest"  (name, line 212)
- "Put on"  (pocket button, line 212)
- "Plates and salvaged charge cells: holds a charge (75), comes with thirty in it. Charge cells (the lab's, or off a dead unit or a downed scanner) top it up, and a vortigaunt will if you ask"  (description, line 213)

*When:* the Resistance's money (sv_livingcity_funding.lua): intel only the quartermaster buys, and parts skimmed off the factory line

- "Freq 7 sheet"  (name, line 216)
- "Copied down at a radio repair bench: the rule, and the seven places on the dial Freq 7 hides. Pass it on, or burn it"  (description, line 218)
- "Notes on a patrol"  (name, line 219)
- "A unit's beat, written down: where he walks, and when. The quartermaster pays for it"  (description, line 220)
- "Notes on a checkpoint"  (name, line 221)
- "A checkpoint's shifts, its gate, its men. The quartermaster pays for it"  (description, line 222)
- "Notes on the Combine's ground"  (name, line 223)
- "The approaches to the Combine's own ground. The quartermaster pays well for it"  (description, line 224)
- "Union machine parts"  (name, line 225)
- "Finished parts, skimmed off the factory line. The dealer moves them; the quartermaster pays more (they end up in guns)"  (description, line 226)
- "Charge cell"  (name, line 227)
- "Charge your vest"  (pocket button, line 227)
- "A salvaged suit cell: twenty-five charge into a powered vest you're wearing"  (description, line 228)
- "Box of .357 rounds"  (name, line 229)
- "Six heavy rounds, hand-loaded"  (description, line 230)
- "Homemade revolver"  (name, line 231)
- "Machined at a workbench. Loud, heavy, final"  (description, line 232)
- "Wedding ring"  (name, line 233)
- "It belonged to somebody"  (description, line 234)

*When:* The Union Commissary item      goes into your inventory entity    spawns in front of you (health vials, batteries) ammo      { type, amount } cpOnly    units only, and sold only at the Civil Protection Commissary's counter (the Union terminal sells them only in a city without one)

- "Nutrient bar and a little water. It keeps you alive."  (description, line 298)
- "Clean, cold, refreshing. Do not ask what is in it."  (description, line 299)
- "An empty glass bottle, for whatever water you can find."  (description, line 300)
- "For what the canal water gives you."  (description, line 301)
- "Union-issue work clothes. Everyone looks the same in them."  (description, line 302)
- "Union band. Notices before the loudspeakers, and a way to talk (!r)."  (description, line 303)
- "One night out after curfew, stamped and legal."  (description, line 304)
- "Grey, dense, and real."  (description, line 305)
- "Powdered, reconstituted, nearly milk."  (description, line 306)
- "Health vial"  (name, line 307)
- "For the trusted."  (description, line 307)
- "A whole watermelon. Exemplary citizens only."  (description, line 308)
- "Real coffee. You'd forgotten the smell."  (description, line 309)
- "Medical kit"  (name, line 310)
- "A full medical kit."  (description, line 310)
- "Something wrong? Call Civil Protection: /request."  (description, line 311)
- "Zip ties (3)"  (name, line 312)
- "Spares. Civil Protection units never run out of their own."  (description, line 312)
- "For notes, letters and notices."  (description, line 313)
- "The Union's permission to trade from a stall."  (description, line 314)
- "Everything you need to sell. A license not included."  (description, line 315)
- "Carry more. Eight more kilos, and one more large thing."  (description, line 316)
- "Somewhere of your own to keep things. Civil Protection units can open it."  (description, line 317)
- "Line and a hook. The canal has fish, of a kind."  (description, line 318)
- "Cover for an advance, or a retreat."  (description, line 319)
- "Metrocops and up. Don't look at it."  (description, line 320)
- "Division Leaders and the Overwatch. For clearing anticitizen holdouts."  (description, line 321)
- "Pistol ammunition"  (name, line 322)
- "Standard issue."  (description, line 322)
- "For Civil Protection units in good standing."  (description, line 323)
- "Suit battery"  (name, line 324)
- "Armor recharge."  (description, line 324)

*When:* The black market (a dealer placed with the editor, or rebel territory) weapon    given straight to you Standing doesn't matter here. Credits do. Units who walk up to a dealer don't buy anything: they bust it.

- "Already tuned to Freq 7."  (description, line 341)
- "Good work. Not perfect work."  (description, line 342)
- "For people with a steady hand."  (description, line 343)
- "One more meal than the Union thinks you deserve."  (description, line 344)
- "Picks, tension wrench, patience not included."  (description, line 345)
- "One use. Don't ask where it came from."  (description, line 346)
- "Clean, plain, forgettable."  (description, line 347)
- "Off a Civil Protection unit who won't be needing it."  (description, line 348)
- "No questions about why you need them."  (description, line 349)
- "Every revolution starts somewhere."  (description, line 350)
- "Opens Combine locks, screens and terminals. Very illegal. Don't get searched."  (description, line 351)
- "Springs, barrels, pins. Make something with them."  (description, line 352)
- "Bought by the bottle. Nobody cleans that much."  (description, line 353)
- "Tomatoes, beans, maybe. Plant them in rebel territory."  (description, line 354)
- "Pre-war tins. Nobody asks where they come from."  (description, line 355)
- "Zip ties (2)"  (name, line 356)
- "For a Civil Protection unit who needs to stay put."  (description, line 356)
- "No questions about what goes in it."  (description, line 357)
- "Spray cans (3)"  (name, line 358)
- "Let the city know we're still here."  (description, line 358)

*When:* what the Resistance's lab makes (sv_livingcity_lab.lua); everyone else pays the dealer for it

- "Chemicals in a can, and a fuse."  (description, line 360)
- "Eighteen rounds. Hand-loaded, mostly reliable."  (description, line 361)
- "Twelve shells."  (description, line 362)
- "Forty-five rounds."  (description, line 363)
- "Six heavy rounds."  (description, line 364)
- "Put together on somebody's kitchen table. It fires."  (description, line 365)
- "It jams. Not often."  (description, line 366)
- "Hard to hide. Hard to argue with."  (description, line 367)
- "Loud, heavy, final."  (description, line 368)
- "Plates and salvaged charge cells. Holds a charge; comes with thirty in it."  (description, line 369)
- "Four minutes of static on every Civil Protection unit radio nearby."  (description, line 370)

*When:* Making things by hand (F2): just these, anywhere. Everything else (guns, ammunition, armour, jammers, bypass charges, smoke bombs, a radio tuned to Freq 7) is the Resistance lab's (LCS.Lab, below) or the black market's. private   out of any unit's sight (a tunnel or back room will do)

- "Bent and filed scrap"  (description, line 410)
- "Rags, torn into strips"  (description, line 411)

*When:* The Resistance lab (sv_livingcity_lab.lua): what the scientist makes, for the Resistance only. Bring him the materials (needs) and he makes it for nothing; or pay him: 60% of the dealer's price (never less than the quartermaster pays for it). secs: how long he takes.

- "Eighteen pistol rounds"  (description, line 424)
- "Twelve shotgun shells"  (description, line 425)
- "Forty-five SMG rounds"  (description, line 426)
- "Six .357 rounds"  (description, line 427)
- "A powered vest: holds a charge (charge cells top it up)"  (description, line 432)
- "A charge cell: twenty-five charge into your vest"  (description, line 433)
- "Five forged ration cards: the dealer buys them, the dispensers take them. The more turn up, the hotter the search for the forger"  (description, line 435)
- "Thick white smoke"  (description, line 436)
- "Opens any door once"  (description, line 437)
- "A Union radio, opened up and retuned to Freq 7"  (description, line 438)
- "A radio that only screams"  (description, line 439)
- "Bar stock, heated and bent"  (description, line 440)

## shared.lua (shared.lua)

`gamemodes/livingcity/gamemode/shared.lua`

- "Living City"  (text, line 17)

