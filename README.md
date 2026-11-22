# Living City

A Combine-occupied city for Garry's Mod: ambient citizens and Civil Protection running real routines, plus factions and ranks, radiant quests with dice, personal story chains, twelve Union jobs, hunger and thirst, social credit, a Commissary, contraband and a black market, stop-and-search, disguises and forged papers, radios, prisons, curfews, and an in-game editor for all of it. Its own gamemode, for singleplayer and servers.

**Voice lines to record or generate** (announcements in both voices, the radio, the G-Man, the dreams): [`VOICE_SCRIPTS.md`](VOICE_SCRIPTS.md), made from the code by `python3 _dev/voice_lines.py`.

## Where everything is described

This file is only an index. The specification of how everything behaves (the agreed behaviour: `CORE.md`, rule 2) is split into one file per feature in `docs/features/`, so a change touches one file. Open only the file you need.

- [Install and first run, and what is left of Sandbox](docs/features/install.md): Unzip, pick the gamemode, first steps, build mode; the gamemode versus Sandbox
- [Permanent death, and a slower pace](docs/features/permanent-death.md): Close calls, careers for life, what passes on, movement, the view, choosing who you are
- [Civil Intake: arriving with nothing](docs/features/civil-intake.md): Intake desk, Housing Allocation, papers, sleeping in beds, rations and ration cards, registration
- [What now, the quick menus (F1, F2), F4 and the full menu (C)](docs/features/menus-and-what-now.md): What now? steps, ways to get by, the F1 and F2 quick menus, F4 (jobs, career, factions), the C menu, on-screen notices
- [Building a map with the editor](docs/features/editor.md): Build mode, the editor tool, saving, backups, moving to a server
- [The editor: placing things, path mapping](docs/features/editor-placing.md): The editor's panel, every fixture and zone, path mapping, doors
- [Custom announcements (Overwatch and the Administrator)](docs/features/custom-announcements.md): Where recordings go, how files are named, triggers and tones
- [The city and the Resistance](docs/features/city.md): Ration lines, rebel territory and camps, squads, skirmishes, rebels at home
- [The city: getting by, making things, the Resistance's money](docs/features/city-economy.md): Bins, crafting, the lab, salvage, intel, forged cards, the arms trade, grenades, disguises
- [The city: events, raids, prison and the Combine's data](docs/features/city-events.md): PA announcements, events, morning exercise, block raids, prison, scanners, supply drops, data terminals
- [The city: street furniture, broadcasts, doors, operations, custody](docs/features/city-administration.md): Screens, broadcasts and the Administrator, Combine doors, Resistance operations, Overwatch drops, custody, jammers
- [Escalation, and the dead](docs/features/escalation.md): Alert levels, scanners and alarms, bodies and searching them
- [The city's people](docs/features/city-people.md): Trains, the power grid, forcefields, checkpoints and turrets, talking to people, lookouts
- [Factions and ranks](docs/features/factions.md): Ranks and XP, Civil Protection's career, squads, the kick, special roles, vests, Father Grigori
- [Factions: the 1 November playtest](docs/features/factions-1-november.md): The owner's 1 November list, item by item
- [The Resistance Insider and the loyalty test](docs/features/resistance-insider.md): The spy inside Civil Protection, Inside Work, the loyalty test
- [Things to do as a vortigaunt, and what loyalty earns](docs/features/loyalty-and-vortigaunts.md): Vortigaunt jobs, loyalty rewards for citizens
- [The Resistance pamphlet](docs/features/resistance-pamphlet.md): A hand-printed sheet the Resistance hands to people or leaves lying about to be found
- [The Cremator](docs/features/cremator.md): An NPC that walks the streets, burns the dead where they lie and attacks enemies; needs a Workshop model
- [Weeds, the Groundskeeper and weedkiller](docs/features/infestation-cleanup.md): Infestation Cleanup, the hoover, weedkiller against growths and against the Combine
- [Civil Protection's tools](docs/features/civil-protection-tools.md): The unit's quick menu, the Commissary, unit tools
- [Jobs and quests (F4), and story chains](docs/features/jobs-and-quests.md): The job board, objectives, directives, story chains
- [Union jobs, and escorts through Combine doors](docs/features/union-jobs.md): Everyone works, mini-game shifts, ration breaks, escorts
- [Radios](docs/features/radios.md): The CP net, Freq 7, your own radio, the transmitter
- [The city does its own work, and the city's stores](docs/features/city-work-and-stores.md): NPC repairs and errands, how they carry things, the stores
- [Survival, social credit and your characters](docs/features/survival-and-credit.md): Hunger, thirst, sleep, medicine, standing, credits, characters
- [Talking, knowing people, going down, and tips](docs/features/talking-and-tips.md): Chat, recognition, acts, going down instead of dying, pop-up tips
- [Window styles](docs/features/window-styles.md): Every window in your faction's look (Combine, Resistance, citizen, in custody)
- [The city's minds](docs/features/city-minds.md): the named people's eleven traits, needs, thoughts, stress and rumours; their choices bend with mood, breaks happen in the street, informants and unrest come from them; citizens drinking and smoking in the street
- [The patdown, lockpicks on cuffs, players in the Resistance's cage](docs/features/patdown-and-cuffs.md): an optional patdown of a cuffed player, picking cuffs and the cage's padlock, and the quick menu for the chair, the cage and cuffing.
- [The chronicle](docs/features/chronicle.md): what happens to named people and players is kept with what led to it, and told in the world: citizens' rumours, the Civil Protection incident feed and the Resistance notice board (staff also get a stories list and a joining card); the Resistance's interrogation chair, where the secrets come out; the agreed plan for an emergent story system
- [The director and free talk](docs/features/director-and-free-talk.md): a hosted model picks one thing to happen every few minutes from a short list, and named people answer what you say to them; setting up the key, cost, safeguards
- [What named people say, recorded](docs/features/recorded-lines.md): a bank of 79 citizen lines and 17 unit lines to record once; the model picks from it in free talk, the director and the minds' breaks use it; how to record them; one voice for each named person; `VOICE_SCRIPTS.md` is the text to paste into ElevenLabs
- [Homes, trade and the written word](docs/features/homes-and-trade.md): Apartments, business licenses, notes, letters, broadcasts, the law
- [Vortigaunts, and day, night and weather](docs/features/vortigaunts-and-weather.md): Freed vortigaunts, the clock, light, rain
- [Staff tools](docs/features/staff-tools.md): Admin safeguards for a public server, staff menus
- [Contraband, searches, the underground, and conduct](docs/features/contraband.md): Stop and search, stash, stealth, wanted, the black market, lockpicks, conduct
- [Pose Recorder (a separate tool)](docs/features/pose-recorder.md): The separate dance and pose tool
- [The Miscount Poser: the hand-made poses, set by hand](docs/features/pose-tool.md): The tool below the editor, the mannequin and the physgun, which poses it sets, where they are kept
- [The Resistance's way marks](docs/features/way-marks.md): permanent sprayed arrows and FREEDOM THIS WAY, painted on walls with the editor, pointing to rebel ground
- [Posters that hint at dreams](docs/features/dream-posters.md): a share of the plain curfew posters foreshadow tonight's dream or remember a recent one
- [The play study](docs/features/play-study.md): the owner's own play written down (who, where, in what, on which job), as a model for the city's people; F4 > Factions > Admin: play study
- [Secret endings](docs/features/endings.md): Sealed directives, every ending, songs, the Endings menu
- [The collapse: sociostability BLACK and the last stand](docs/features/collapse.md): Chaos after long red, the G-Man's offer to the Administrator, her last stand in her office, Barney and Freeman
- [Hooks, and how the code is laid out](docs/features/code-layout.md): For whoever works on the code: modules, load order, hooks
- [Big servers, when something breaks, admin commands, honest limits](docs/features/admin.md): Server sizing, debugging, every admin command, known limits
- [Squads: sizes, leading units, backup by radio](docs/features/squads.md): How many NPCs a player leads by players on their side, E on a unit, backup out of rebel territory, the radio's left click
- [The radio to HQ, and the resupply scanner](docs/features/radio-hq-and-resupply.md): a unit's calls to HQ only with the radio out, its right click's Radio menu, and the shield scanner's resupply crate.
- [Gas masks, the gas and the flashbang](docs/features/gas-masks.md): masks off uniforms and the dead, who puts one on in the gas, hands over mouths and eyes, running from the gas.
- [Half-Life 2's ammo limits](docs/features/ammo-limits.md): pistol 150, SMG 225, shotgun 30 and the rest instead of Garry's Mod's 9999, kept through deaths, respawns, close calls and dreams.
- [IEDs](docs/features/ieds.md): a homemade bomb set on the ground and blown by hand with the Detonator, on a road or on the tracks, where it stops the trains until a unit mends them.
- [The Resistance's headquarters](docs/features/resistance-base.md): one base at a time; the leader raises a flag in rebel territory (five minutes), the commander's office appears when it is up; it moves only by being packed, ransacked by the Combine or overrun and won back.
- [The Resistance's fund](docs/features/resistance-fund.md): half of every take from supplies raided and people saved, the other half to those who took part; it pays for the leader's order to kill the Administrator (300 each), and later shooters are paid half.
- [The Resistance's own money](docs/features/resistance-money.md): the still, the dealer selling only the drink sold to him, a member's half of what the dealer pays (the rest to the fund), the dealer's rent on rebel ground, the Union paymaster, the back-room card table
- [The armory and barter](docs/features/armory-and-barter.md): a gun you already carry goes in your pockets; sold to the quartermaster (5 credits from the fund) it goes in the Resistance's armory, which arms its fighters first; what he is paid goes into the fund and what he buys comes out of it; his Barter button, and the Goodwill that lets a trade go a few credits short.
- [Informing to Civil Protection](docs/features/informing.md): a citizen who saw the would-be assassin tells a unit (E, or F1 > Inform) and leads the units to them for 250 credits and 250 standing; the poster; more kinds plug in later.
- [Firing squads](docs/features/firing-squads.md): the Administrator has a prisoner shot at the editor's execution wall; two minutes' warning, every Resistance member gets "Stop the execution"; a player shot is dead for good.
- [Combine strongholds](docs/features/strongholds.md): tripwires that wake floor turrets (the map's), the CP net hearing a broken wire, the Resistance's Cut the defences job
- [The Advisor screens](docs/features/advisors.md): the Administrator asks the Advisors (Fixture: Advisor screen, or F2 > City orders) for Overwatch troops, a supply drop or more units, and reports on the unrest every third night; their patience is hidden, shown in words; a missed report or patience run out cuts rations, then sends an officer to watch her, then removes her
- [What becomes of the Resistance's prisoners](docs/features/resistance-prisoners.md): three ways of letting them go, exchanges, bodies as evidence, how the people see the Resistance (felt, never shown), and the Administrator's answer to a killing.
