# Living City

A Combine-occupied city for Garry's Mod: ambient citizens and Civil Protection running real routines, plus factions and ranks, radiant quests with dice, personal story chains, twelve Union jobs, hunger and thirst, social credit, a Commissary, contraband and a black market, stop-and-search, disguises and forged papers, radios, prisons, curfews, and an in-game editor for all of it. Its own gamemode, for singleplayer and servers.

**Voice lines to record or generate** (announcements in both voices, the radio, the G-Man, the dreams): [`VOICE_LINES.md`](VOICE_LINES.md), made from the code by `python3 _dev/voice_lines.py`.

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
- [The director and free talk](docs/features/director-and-free-talk.md): a hosted model picks one thing to happen every few minutes from a short list, and named people answer what you say to them; setting up the key, cost, safeguards
- [Homes, trade and the written word](docs/features/homes-and-trade.md): Apartments, business licenses, notes, letters, broadcasts, the law
- [Vortigaunts, and day, night and weather](docs/features/vortigaunts-and-weather.md): Freed vortigaunts, the clock, light, rain
- [Staff tools](docs/features/staff-tools.md): Admin safeguards for a public server, staff menus
- [Contraband, searches, the underground, and conduct](docs/features/contraband.md): Stop and search, stash, stealth, wanted, the black market, lockpicks, conduct
- [Pose Recorder (a separate tool)](docs/features/pose-recorder.md): The separate dance and pose tool
- [Secret endings](docs/features/endings.md): Sealed directives, every ending, songs, the Endings menu
- [The collapse: sociostability BLACK and the last stand](docs/features/collapse.md): Chaos after long red, the G-Man's offer to the Administrator, her last stand in her office, Barney and Freeman
- [Hooks, and how the code is laid out](docs/features/code-layout.md): For whoever works on the code: modules, load order, hooks
- [Big servers, when something breaks, admin commands, honest limits](docs/features/admin.md): Server sizing, debugging, every admin command, known limits
- [Squads: sizes, leading units, backup by radio](docs/features/squads.md): How many NPCs a player leads by players on their side, E on a unit, backup out of rebel territory, the radio's left click
