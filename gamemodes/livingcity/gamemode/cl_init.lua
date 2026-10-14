--[[
    Living City (gamemode, client)

    No spawn menu or context menu unless you're an admin in build mode, no
    Sandbox hints, and the full menu (C) opens a short guide to the city.
]]

include("shared.lua")
LC_LoadModules("client")

function GM:SpawnMenuOpen() return self:LCBuilder(LocalPlayer()) end
function GM:ContextMenuOpen() return self:LCBuilder(LocalPlayer()) end
function GM:SuppressHint() return true end

-- One camera (cl_livingcity_view.lua): whatever Sandbox makes of the view
-- (vehicles, weapons, drive), then the city's own touches on top of it.
function GM:CalcView(ply, origin, angles, fov, znear, zfar)
    local base = self.BaseClass and self.BaseClass.CalcView
    local view = base and base(self, ply, origin, angles, fov, znear, zfar) or nil
    if not istable(view) then view = { origin = origin, angles = angles, fov = fov, znear = znear, zfar = zfar } end
    if LC_CL and LC_CL.CalcView then view = LC_CL.CalcView(ply, view) or view end
    return view
end

local INK, ACCENT = Color(232, 226, 210), Color(230, 180, 90)

local GUIDE = {
    { "Keys", {
        "F1  the quick menu: nine things on the number keys, for who you are and what's in front of you (0 closes; 9 is everything else)",
        "Union work you do with your hands: Sanitation's street sweep (push the cart, throw the rubbish in), the Factory line (bin the rust-red parts), the Station Porter's papers check (approve, deny, or call a unit).",
        "More of it: Maintenance rewires panels against the clock (a wrong wire bites), Clinic Medics triage patients bleeding out, the Reclamation Crew breaks up rubble with a crowbar.",
        "And more: Couriers run parcels against the clock past units who want to search them, the Mortuary searches the dead before the fire (log it, keep it, or keep it for the family; mind the overseer), the Laundry sorts uniforms by division, Records Clerks file forms and catch mismatches, Radio Repair finds each set's station and turns its trimmer screws by ear until it's clean (and sometimes finds Freq 7; record your own broadcasts in sound/livingcity/announce/radio/).",
        "A radio in your pockets has Listen: turn the dial through the static to the Union band (96.4) or, if you can find it, Freq 7. Anyone nearby hears it, units included.",
        "Freq 7 is a rule, not a number: the Resistance only broadcast where the digits add up to seven. The Combine jam it when they find it, and it comes back on another; a Resistance radio follows it by itself.",
        "The Resistance doctor records at a terminal (stop the needle in the band; hands off while the scanner passes) and hide dead drops unseen. Units pat citizens down a place at a time, and breach doors on block raids. If you close a game's panel, E brings it back.",
        "Lost? {gm_showhelp} > What now? is always your next step, with the way there; What now? > Places marks anywhere worth knowing (the dispenser, water, your block, your work).",
        "F2  your pockets (and stash at home)        F3  your board: jobs, stories, Union employment        F4  factions",
        "C (outside build mode)  the full menu: everything you can do, with this guide, your pockets, board, factions and tips at the top.",
        "E on people: talk to citizens, report to units. E on things: pick up, use.",
        "Everything you can do is in the menus (units: C > Unit tools). Chat commands like !backup still work, but you never need them.",
        "Warnings and announcements show on your screen as well as in chat: people talking to you as subtitles, the rest as cards at the top. C > Settings turns the cards off.",
    } },
    { "Death, and close calls", {
        "Each person has three close calls: you die, and wake in the infirmary with your pockets emptied and no memory of the fight (leave it be).",
        "A used close call comes back after a few hours of that person's life. The death after the last one is the end of them: !characters shows how many you have.",
        "When a person ends you come back as someone new, with a new name and citizen number, and nothing but a little inherited from them.",
        "Some things are for life: the Overwatch conditioning, being made a stalker. To be someone else, play another character, or retire this one (!characters).",
        "The Union levies hoarded credits: above 2000, a tenth of the excess goes every half hour. Spend it.",
        "The screen goes dark and a card says who they were: how long they lived, how many people knew their name, what killed them.",
        "The people who knew their name hear about it a minute or two later, in passing (or when they're next in the city).",
    } },
    { "Arriving: Civil Intake", {
        "In a city with Civil Intake, a new person arrives with nothing: no papers, no room, no ration card.",
        "Civil Intake (the marker on your screen): E opens the terminal's registration screen. Enter your name, your face, how a stranger would know you, submit it, and stay beside the terminal while it processes you. Your identity papers and ration card go in your pockets (F2), and the screen points you to Housing Allocation.",
        "Then Housing Allocation: E opens the housing register. Present your papers and apply for a block: any block is approved at once (the least crowded); a crowded one needs Civil Standing 50. It marks the way home.",
        "Housed already? The same screen says where you live and how you got it, marks the way home, and takes transfer requests (standing 25, once every half hour).",
        "Your papers: identity papers and a ration card, in your pockets (F2). Units ask for papers (carrying none costs a little standing); the dispensers want the card. Lost them? Civil Intake replaces them (10 and 15 credits).",
        "Show your papers: look at someone, F1 > Show them my papers (or F2 > Identity papers > Show). They see the card, and learn your name.",
        "Until you're registered: no rations (a forged ration card works), no Union job, no Commissary, and units ask for papers. Leave it too long and it's a crime.",
        "One person at a desk at a time. New arrivals off the train queue too. F1 > My papers says where you stand.",
    } },
    { "How the city looks and feels", {
        "Your eyes sit a little lower than everyone else's, and the view is no wider than Half-Life 2's: the city is big, and you're not.",
        "The camera sways a little with your steps and dips when you land. C > Settings > Camera sway keeps it still, just for you.",
        "Nothing on screen keeps score: your credits and Civil Standing are at the top of your pockets (F2), your rank and progress on F4.",
        "Hunger and thirst show at the top left once they start to bite, and for a moment after you eat or drink.",
    } },
    { "Staying alive", {
        "Eat and drink. Ration dispensers and the ration line feed you; the Commissary (a terminal, or C > Getting by) sells the rest.",
        "Wade into water and press E to drink, but boil it first if you can (stove or fire, F2). A sink has to be in plain sight to use.",
        "Parasites (coughing, hunger, thirst) never wear off: antiparasitic tablets from a medic or the black market clear them.",
        "Parasites also mean you'll need a toilet (E on one). Ignore it and you soil yourself: then a toilet, a wash (a bathtub or shower) and clean clothes, or people back away from your stink.",
        "Sleep once a day: E on a bed at night. Without it your eyes droop, you can't run and you're weaker. A good night leaves you well rested.",
        "Your fists kill birds. Cook them.",
    } },
    { "Staying out of trouble", {
        "Don't crowd Civil Protection. Warnings come first, then the stick.",
        "When a unit stops you, stand still. Anything illegal in your pockets may be found.",
        "Curfew: you get a minute to reach your housing block (a fresh one each time you respawn into a curfew). A travel permit gets you past one stop.",
        "Morning exercise (every second dawn, mandatory for citizens): report where your HUD points. The jog: keep jogging and keep up with the pace marker, or the units along the route use the stick (which speeds you up for a few seconds). The drill: stay on your ring and copy every move (crouch, jump, turn around, a step), and jump on every beat when the rope comes out. The parade: cheer the column as it passes (/cheer, /salute, chant in chat, jump) and keep your enthusiasm bar up. Skipping it costs standing; doing it well earns some, and breakfast if your standing is Trusted or better.",
        "A full stomach (hunger 85+): 15% more XP from jobs and shifts, and you heal slowly.",
        "Combine-only areas (the nexus, offices, armory, prison) are off limits. Doors by the cells are locked.",
        "Raids: units sweep a housing block and trace any contraband (guns, TVs, radios...) to whoever owned it.",
        "Being wanted means every unit nearby comes for you. Get caught and you're arrested.",
        "Kill units and it escalates: armed units, then Overwatch squads. Lie low to cool it off.",
        "One accidental kill is answered lightly; a second soon after gets the full response. Resistance members lose a rank for every civilian they kill.",
        "To give yourself up, walk up to a unit and press E. It goes easier on you.",
        "Anticitizen? Do community service from your board (F3), or serve your time.",
    } },
    { "Getting by", {
        "Take a Union job on your board (F3) and work shifts for credits and Civil Standing.",
        "Standing decides what the Commissary will sell you. Crimes lower it.",
        "Rebel territory has a black market (C > Getting by > Black market). Radios: C > Talk > On my radio.",
        "Search the dead with E. Dead units carry ammunition, and sometimes a keycard.",
        "Haul a body: look at it, F1 > Haul the body; Morticians just press E. Let go by the incinerator and in it goes; attendants are paid for each.",
        "Press E on a citizen to talk: hear what's going on, share food, pick their pocket (Guile), or inform on them. They remember how you treat them.",
        "The Resistance (Member and up) can ask a sympathizer to keep watch: they warn Freq 7 when units come.",
        "The city keeps to the clock: work in the morning, ration lines at midday, quiet evenings, and thin streets at night (only the night shift works).",
        "Trains come into the station now and then: new arrivals with suitcases, and anyone leaving the city boards before it pulls out.",
        "Arrested by a unit, you're tied and walked to the cells by two of them. On the way anyone can get you out: put the leading unit down, then {gm_showhelp} > Work at the ties.",
        "Rations come out of the city's stores (under the clock). Kitchen and factory work fills them; when they run low, so do the rations, and people grow restless.",
        "Transformers power their district: its lights (the map's switchable ones too), screens and TVs, dispensers, vending machines, the commissary and Combine door locks. Sabotage one (multitool) and the district goes dark and its Combine doors open, until maintenance fixes it. Prison doors stay locked.",
        "Half the grid down at once and the whole city goes dark, the map's own lighting included: switch on your flashlight (F).",
        "Checkpoints: a glowing Combine power bank runs the turrets and forcefields cabled to it. A powered turret can be knocked over. Turrets shoot the infected, the wanted and known rebels. Kill the bank's power (a multitool, or the grid) and they all die; next to the infestation, that's a containment breach.",
        "The infestation: ground stained yellow and scorched, a thick yellow haze and a geiger counter. The deeper you go, the faster it clicks.",
        "Union work behind Combine doors? Actions menu > Getting by > Ask for a Civil Protection escort, while you're on a job. With your escort close, E opens Combine doors for you. Let someone slip in behind you and the unit goes after them; twice and nobody escorts you for a while. When the job's done, they walk you out to the release point.",
        "Combine forcefields: units walk through; a keycard swipe (E) opens one for a moment; a multitool shorts it out.",
        "Letters: read a note in your pockets and Send as a letter, at the post office. A courier takes it to their block. Units can read the mail while it waits there.",
        "The city's own people work their Union jobs too: fixing lights and loudspeakers, scrubbing graffiti, hauling the dead, carrying crates and mail. Look at someone to see what they're doing. Broken things wait a while for a player first.",
        "Down and bleeding? A Union medic may come running, if you're not wanted and it isn't a firefight.",
    } },
    { "The war for the city", {
        "Rebel territory and the infestation spread if nobody fights them (across a floor, or down the stairs to the next), and shrink when they're fought.",
        "Your screen tells you when you cross into either. C > The city > Who holds the city (or F4) shows who holds how much.",
        "Unrest (the Resistance strong): more inspections and raids, ration cuts. Full compliance: the rebels go quiet.",
        "Units: F1, 1 (Call for backup) brings the nearest units running; 2 (Send my 10-20) marks where you are for other units.",
        "Resistance: the quartermaster in rebel territory sells gear. Members and up can press E on fighters to bring them along.",
        "Fighters with you stay with you before anything else. They hold their fire until you open up or the Combine do, then shoot as they go.",
        "The rebels are guerrillas: they let a unit get close before they shout, and out in the city they keep out of sight. Units who see an armed rebel in the street open fire.",
        "At home the rebels keep busy: patrols, the lab bench, crates, the garden, the fire, sleep. Now and then one or two slip out to scavenge and bring it home.",
        "Every rebel base needs a lab: its scientist makes guns, ammunition, armour, jammers, bypass charges, smoke bombs and Freq 7 radios, for the Resistance only. Bring the materials and it's free, or pay him (60% of the dealer's price). F1 > Resistance > Find the lab marks it.",
        "Everyone else buys guns, ammunition and jammers at the black market. A unit who finds the scientist shuts the lab for ten minutes.",
        "Citizens hear things. Press E on them now and then.",
    } },
    { "Getting by, and making things", {
        "Near Resistance activity when the PA says ration units are deducted? Your next ration is withheld; the dispenser tells you why.",
        "Press E on bins, dumpsters and fridges to go through them: scrap, rags, chemicals, tins, seeds, sometimes gun parts.",
        "Fishing line (Commissary): stand in the canal or look at it, Fish from F2 (or C > Getting by), and keep still. Cook the catch.",
        "Rebel territory has pots (plant seeds, harvest vegetables) and a supply crate the Resistance eat from. C > Resistance > Donate food adds to it.",
        "F2 > Make: bandages and lockpicks, by hand, anywhere. Everything else is the Resistance lab's work, or the black market's.",
        "Hold a crowbar, look right at a piece of junk (a wrecked car, a radiator, pipes, a crate) and press E to pry out scrap, rags and chemicals. It's loud: the nearest unit comes to look.",
        "A crowbar is a weapon: a unit who sees one in your hand makes you wanted. Keep it holstered on the street.",
        "Rebels guard their territory: break their crates and they warn you twice, shove you, then turn on you. Leave their supplies alone.",
        "Shoot one of the city's scanners down and it comes apart as scrap. A scanner with a glowing red eye is being flown by a person: it leaves nothing.",
        "Supply drops: a Combine convoy unloads a guarded crate on the street. E on it takes a load (gun parts, ammo, medicine), if no unit sees you.",
        "A radio jammer (the lab, or the black market) blinds unit radios, request devices and scanner reports nearby for four minutes. Units smash them with E.",
        "Citizens' Assignments include Union work orders (streetlights, rubble, pipes) that pay in scrap, rags and chemicals.",
        "Union reclamation points take scrap, cans and bottles for credits and a little Civil Standing.",
        "Homemade guns and ammo sell at the black market, and for more at the quartermaster. Getting them there is the risky part.",
        "F2 > Give hands something to whoever you're looking at. A lockpick lets a prisoner work their cell lock.",
        "In a cell with a Combine console? Press E on it to fly a city scanner; your body stays put. Flashing a unit adds a minute to your sentence. Photographing rebels, free vortigaunts, the wanted or zombies from about ten feet earns Civil Standing (never time off), and lights them up for every unit. A scanner can't see into or through smoke.",
        "Spray cans put the lambda on walls. Units and loyal citizens scrub tags off with E.",
        "Units: smoke, flashbangs and gas come with rank. The Grenades weapon throws them; R switches type.",
    } },
    { "Disguises", {
        "Resistance: you come back in plain clothes. C > Resistance > Gear up puts your own gear on; Change into plain clothes takes it off again.",
        "In plain clothes nobody looks twice, until a unit sees a gun in your hand.",
        "Clothes come off the dead (citizens' clothes, CP uniforms, Resistance gear) and turn up in bins. Wear them from F2.",
        "A CP uniform fools units on the street, for a while. Resistance gear fools the fighters, and makes units shoot.",
        "Never change in front of a unit.",
    } },
    { "Carrying and keeping things", {
        "Your pockets are limited by weight and size. A satchel lets you carry more.",
        "Looking at a bin, F2 lets you hide things in it. Anyone can find them.",
        "Lockers (E): put something in and it's yours. A storage crate from the Commissary is set down from F2.",
        "Units can open any locker or crate, and take what's illegal.",
    } },
    { "Homes, trade and writing", {
        "Apartments: look at a door and it says who holds it, or that it is for rent. With your hands out, right click a free one to rent it (yes or no), and right click your own to lock or unlock it. Or C > This door, and C > Home for keys, locking and giving it up.",
        "With a CWU business license you can set down a market stall and sell from it. Customers press E on it.",
        "Paper: Write from F2. Leave a note, put a poster up on a wall, or keep it. E on one reads it.",
        "C > The city > The city's laws. The Administrator speaks to everyone from C > The city > Broadcast.",
    } },
    { "Characters and acts", {
        "C > Me > My characters: your people in the city. Switch between them, or start someone new.",
        "C > Me > Pose: sit, kneel, lie, lean, cower, four standing poses; move (or Stand up) to get up.",
        "C > Me > Gesture: wave, salute, bow, nod, shake, point, beckon, halt, cheer, laugh. C > Me > Put my hands up.",
    } },
    { "Vortigaunts, time and weather", {
        "Shackled vortigaunts work the Union's shifts; the collar holds their vortessence in.",
        "The Resistance (Member and up) can cut one free (look at it, C): ten seconds, unseen. Free, it strikes (left click) and charges vests (right click), and is hunted.",
        "Armour is the charge in a powered vest: units have one in the uniform, rebel ranks come with one, anyone else needs one from the lab. Vortigaunts charge it.",
        "Father Grigori keeps to rebel territory when no player is him: E on him for a blessing, a sermon, or a word.",
        "A day lasts an hour. Nights are dark, and curfews likelier. C > The city tells the time and the weather.",
        "Rain fills an empty bottle or can if you stand out in it. lc_music 0 turns the city's music off.",
        "Need staff? Type @ and your message.",
    } },
    { "Directives and jobs", {
        "F3 is your board. Events bring their own directives: they go up two minutes before, and come down when it's over.",
        "Only rations and curfew are announced ahead. Sweeps, raids and supply convoys come without warning, and a lockdown only follows violence.",
        "Several people can take the same job: up to 8 for an event, 6 for containment or retaking ground, 4 for a chase.",
        "When the infestation spreads or the Resistance take ground, a directive to deal with it goes up straight away.",
    } },
    { "Civil Protection", {
        "Units: F1 is your quick menu: backup, 10-20, BOLO, the mask's voice lines and records on 1 to 5; search, ties and escorts for whoever you're looking at on 6 to 8.",
        "Units: C > Unit tools has everything a unit can do, each with what it does. Records terminal: violations, notes, loyalty points, BOLOs, requests.",
        "Units don't make things: the Civil Protection Commissary issues grenades, ammunition, armour, bandages and your ration (E on it, every two minutes). F2 marks the nearest on your screen.",
        "Units: actions menu > Civil Protection > Deploy a turret here, near a checkpoint's power bank or forcefield (two each; E packs one up). Officers put up power banks.",
        "Union workers can ask for an escort. Actions menu > Civil Protection > Escort requests to take one (or look at a worker > Escort them). Keep them close, open the doors they need, walk them out to the release point when they're done.",
        "F1 > Voice lines for the mask's most used lines (or say the words); all of them are in Unit tools > Voice lines.",
        "C opens the full menu (so does 9 on the quick menu): everything you can do right now, for who you are and what you're looking at, with this guide at the top. No chat commands to remember (they still work).",
        "A special role (Hacker, Father Grigori...) comes back with you when you rejoin, if there's still a place in it.",
        "The multitool (the Resistance's two Hackers carry one; the black market sells them, contraband): point it at a locked Combine door (hack it), a city screen (hijack it), a data terminal (steal its data), a vending machine or ration dispenser (free water or rations) or a shackled vortigaunt, and left click.",
        "The Director of Propaganda's microphone: left click to go on air over every loudspeaker and screen (a minute, once every fifteen). A scanner comes down and films whoever holds it, live on every screen; its eye blinks red while it records. With no player in the job, the Administrator addresses the city herself now and then; kill her on air and her microphone is yours. Shoot it down to kill the picture. Take the microphone off them (hands up or tied, actions menu) and it's a pirate broadcast.",
        "Shot or worn out, streetlights go dark and loudspeakers go quiet: nobody near a broken one hears the PA. Maintenance and radio repair crews fix them.",
        "One terminal is half a chip (a fragment): hack a second, different terminal and the two make a whole data chip. The master terminal is the motherlode: one download, a master data core.",
        "A data chip: sell it to the dealer, take it to the lab and have the scientist Decode it (top of his list: every unit marked for five minutes), or Use it at a terminal to wipe your record.",
        "Dead soldiers drop their guns, with about half a clip in them. The rest of their ammunition is on the body: search it.",
        "Shooting a scanner is damaging city property; killing one is destroying it. Neither is assaulting anyone.",
        "Ambush the landing: be at the landing zone before the dropship comes in, and hit the soldiers it sets down.",
        "Someone you're escorting runs when you run, and when there's shooting. Climb a ladder and they follow you up it.",
        "Resistance: a small orange lambda over a citizen's head means they're secretly one of ours. Members and up can ask them to keep watch (E, then the talk window).",
        "Break your people out of the cells, ambush Overwatch landings, free a vortigaunt: see Operations (F3).",
        "Citizens: look at someone, F1 > Inform on them. Civil Protection pays if it's true. If the Resistance see you do it, you're a traitor.",
        "Trusted citizens: actions menu > Getting by > Become a Union foreman; then the actions menu on a citizen > Give them a work order. You take a cut.",
        "The worst anticitizens get worse than time: interrogation (the interrogator offers 50 social credits if you talk), broken feet (no running), or being made a stalker.",
        "A stalker works below, in the Combine areas: The Stalker's Lot on your board (F3). There is no way out of being a stalker but death. At the end of it is a Combine ball energizer you built yourself, and stepping into it is a way out: that person is gone for good.",
        "Civil Protection is one career: Record Keeper, Metrocop, Division Leader, then the Overwatch ranks (Prison Guard, Soldier, Elite), which need the transhuman conditioning: the Overwatch Candidate story offers it to Division Leaders.",
        "Not sure what you could be doing? F1 > What now? > Ways to get by: everything open to you, and what the rest need.",
        "Units kick: G (or F1 > Kick). Doors swing open, locked ones give on the second kick, people get knocked back. A Combine Soldier kicks a hinged door off its hinges; an Elite sends it flying, and whoever it hits is knocked out. Maintenance Technicians rehang fallen doors: E to lift, carry it to the frame, E again.",
        "Scanner Operator (Civil Protection, F4): fly a scanner from a Combine console or the Nexus (F1 > Unit tools). Reports earn XP; a rebel you photograph becomes a BOLO.",
        "Released from prison, you get your fists back but not your guns or radio. Units get their issue back.",
        "Rebel ground has no mercy: REBEL TERRITORY AHEAD warns you a step before it. Inside, they shoot units.",
        "Supply drop on? Guard the crate: if anything's left when the convoy moves on, every unit nearby is paid.",
        "RADIO JAMMED on your HUD: a jammer is close. Follow the beeping and press E on it.",
        "Units: look at someone, F1 > Zip-tie them. Anyone with zip ties: C > their name > Zip-tie their hands. Hands up, down, stopped, or from behind. Drag walks them along; the baton arrests them.",
        "Sociostability (green, yellow, red) is at the top of the screen. Officers set it in C > Unit tools. Red is a judgment waiver: metrocops have their pistols out.",
        "Set off an alarm (a data chip, an escape) and a squad of two metrocops and a soldier comes through the door a few seconds later.",
        "The nexus and every Combine-only zone are garrisoned: mostly Overwatch soldiers, a metrocop or two.",
        "Citizens: C > Getting by > Request Civil Protection (with a request device) calls a unit. C > Me > Put my hands up when a unit tells you to.",
        "Tied up? C > Me > Work at the ties, when nobody's looking. Anyone can cut you free.",
    } },
    { "Tips", {
        "The first time you run into something, a card on the right says what it is and what you can do. Each one shows once.",
        "C > Tips I've seen has every tip you've had, to read again. C > Settings turns them off or on, or starts them over.",
    } },
    { "Talking, and knowing people", {
        "Chat is spoken out loud: only people nearby hear it. C > Talk yells further (/y) or whispers to whoever is right next to you (/w).",
        "C > Talk: describe what you do (/me lights a cigarette), the scene (/it), or roll 1-100 for everyone near (/roll).",
        "C > Talk > Out of character: for the whole server (//, with a cooldown) or nearby only (/looc).",
        "Voice works the same way: people hear you if they're close enough.",
        "Strangers don't know your name. They see your description: C > Me > Change how strangers see me (\"tall, with a scar over one eye\").",
        "Look at someone, F1 > Tell them my name. F1 > Tell everyone nearby my name.",
        "Units are known by their designation while the mask is on.",
    } },
    { "Going down", {
        "A killing blow puts you on the ground, bleeding, instead of killing you outright. You can still whisper.",
        "Someone can press E on you to get you back up: a few seconds bare-handed, quicker and better with a bandage.",
        "A unit pressing E on a wanted person cuffs them where they lie.",
        "Shoot someone who's down and that's the end. Looking at them, F1 > Drag them along; again lets go.",
        "C > Me > Give up lets go if nobody's coming. Explosions and the like kill outright.",
    } },
}

-- The guide: the full menu's first item (C, cl_livingcity_actions.lua), !help,
-- or the console command lc_help. A list of topics on the left, the topic on the
-- right, and a search box that looks through all of it.
local ADMIN_GUIDE = { "Admin", {
    "C > Help > Build mode (or !build) toggles build mode: spawn menu, context menu, physgun, toolgun (Living City Editor) and noclip.",
    "Civil Intake: place \"Fixture: Civil Intake (registration)\", \"Fixture: Housing Allocation\" and \"Point: arrival\". lc_intake, lc_intake_secs (8), lc_intake_grace (10 minutes), lc_papers_fee (10), lc_card_fee (15); lc_register <name>, lc_unregister <name> (back through all of it, room included). No desk on the map: people are registered and housed as they arrive.",
    "Civil Protection Commissary (editor fixture): units are issued grenades, ammunition, armour, bandages and a ration there. lc_cpsupply_cooldown (120), lc_cpsupply_ration (600). None placed: the Union Commissary terminal issues them instead.",
    "Resistance lab (editor fixture, the old workbench): a lab bench and a scientist who makes the Resistance's guns. Put one in every rebel base. lc_lab_price (0.6 of the dealer's), lc_lab_shutdown (600 seconds after a unit finds it).",
    "How it feels (editor panel, How it feels): lc_fov (75, the widest anyone sees; 0 leaves it to each player), lc_eye_height (61; GMod's is 64), lc_view_bob (lc_view_bob_amount, 100%, for how strong), lc_quiet_hud, lc_respawn_secs (12, the death card), lc_word_gets_around.",
    "lc_debugreport copies a report to send when something breaks.",
    "C > Help > Admin testing tools (or the button on F4, or !admintools): give yourself XP, a rank, credits and standing, switch faction, start over.",
    "Chat: !givexp, !setrank, !givecredits, !givestanding <n> [name]; !resetxp, !resetcredits [name]; !resetme.",
    "C > Help > Staff panel (or !staff): logs, tickets, warnings, character bans. !warn <name> <reason>, !charban <name> <reason>.",
    "lc_time <hour>, lc_weather <clear|overcast|fog|rain|storm|auto>.",
    "Black out the whole city for an event: !admintools > The city, or lc_blackout on|off|auto.",
    "Checkpoints in the editor: Combine power bank, Combine turret, Combine barricades. Put one at the edge of the infestation and it stops spreading there, until the power goes.",
    "Cell doors not locking? Tag them with the editor: Door: prison or cell. They stay locked in a blackout, and shut themselves if anything but a unit opens them.",
    "Door: always open keeps a door open for good: locked open, and opened again if anything shuts it.",
    "Your own announcements: drop .wav files straight into addons/livingcity_sound/sound/livingcity/announce/overwatch/ or .../administrator/, named for the trigger (curfew1.wav, ambient2.wav); the Administrator's tone is in the name too (curfew_firm1.wav, curfew_stern1.wav, curfew_furious1.wav; no tone word is warm). Each folder's README lists the triggers. lc_announce_clips lists what it found, lc_announce_say <voice> <trigger> [tone] tests one.",
    "Secret endings (keep them secret): the G-Man stops time and everyone votes, 1 to let the city end, 2 to skip (no votes: it ends). Nobody really dies; the map reloads after. Songs go in the livingcity_sound addon, sound/livingcity/endings/<harpies|bus|nuanua|topsecret|water|bloom|marrow>/. Father Grigori eating a master data core (Eat it in his pockets, or /eatchip) starts the flood. lc_endings, lc_ending <id> [now], lc_ending_cancel, lc_ending_reset_cooldown. The Harpies (mingebags): lc_ending_minge_swell is the second the song swells, lc_ending_minge_end when it is all over, lc_ending_minge_max how many. Bloom (the dance): lc_ending_bloom_speedup, _ramp, _peak, _bpm; lc_bloom_preview and lc_bloom_pose tune the dance. Marrow (the skeletons): lc_ending_marrow_sections lines it up with the song (seconds:dance|rave|attack|outro|end). The Bus: lc_ending_bus_sections (seconds:fly|drive|fast|end), lc_ending_bus_bpm.",
    "Freq 7 (the pirate broadcast): voice lines and songs take turns, warnings cut in; the Combine jam it every lc_freq7_hold minutes on green (faster on yellow and red, never in a blackout). Recordings: the sound addon's radio/ folder. lc_freq7_status says where it is.",
    "Morning exercise: place a jogging route (stops in order, the first is the start), an exercise yard (stand where the rows will be, aim at the leader's spot) and a parade route (stops in order) with the editor. Every lc_exercise_every dawns (2) one runs, taking turns (lc_exercise_kinds). lc_exercise <jog|drill|parade> starts one now, lc_exercise next says what's next, lc_exercise stop ends it.",
    "NPCs losing you in pursuit? Path mapping (editor panel, Paths and doors, or !pathmap) lays path nodes as you walk the streets, stairs and alleys, links them and saves them with the map. Noclip pauses it; lc_pathmap_undo removes this session's nodes.",
    "Every setting in the editor panel saves with the map as you change it, so a restart keeps your numbers.",
    "Persistent props: spawn a prop, place it, and zap it with the editor's Prop: make persistent. It's saved with the layout, frozen, and back every time the map loads.",
    "Rebel lookout post (editor point): an armed fighter guards that spot. Place it from where the Combine would come, so he faces that way.",
    "Bunk (editor point): a bed rebels sleep on. Mattresses, beds, couches, chairs, workbenches and crates inside rebel territory are found by themselves.",
    "lc_rebel_errand sends a scavenging run out of the nearest rebel zone now; lc_rebel_react is how often the fighters go for supply drops and Overwatch landings.",
    "Tag the Combine's doors Door: Civil Protection only and units are routed through them, even ones the map's navigation was cut off by.",
    "The Living City Editor places everything: street furniture (bins, streetlights, loudspeakers, big screens, TVs), an incinerator for the dead, and a workplace for each Union job, plus loading docks, graffiti walls, rubble piles and leaky pipes for the shifts that use them.",
} }

local guide
function LC_GuideSections(admin)
    local sections = table.Copy(GUIDE)
    if admin then sections[#sections + 1] = ADMIN_GUIDE end
    return sections
end

local function OpenGuide(admin)
    if IsValid(guide) then guide:Remove() guide = nil return end -- F1 again closes it
    local sections = LC_GuideSections(admin)
    local f = vgui.Create("DFrame")
    guide = f
    f:SetTitle("")
    f:SetSize(math.min(ScrW() - 60, 900), math.min(ScrH() - 60, 600))
    f:Center()
    f:MakePopup()
    f.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(16, 15, 13, 245))
        draw.SimpleText("LIVING CITY: A GUIDE", "DermaLarge", 16, 12, ACCENT)
        draw.SimpleText("C > Guide opens this. Tips also pop up the first time something happens (C > Tips I've seen has them all).", "DermaDefault", 16, 44, Color(150, 145, 130))
    end
    local search = vgui.Create("DTextEntry", f)
    search:SetPos(f:GetWide() - 276, 14)
    search:SetSize(260, 24)
    search:SetPlaceholderText("Search the guide")

    local list = vgui.Create("DScrollPanel", f)
    list:Dock(LEFT)
    list:SetWide(230)
    list:DockMargin(8, 46, 4, 8)
    local body = vgui.Create("DScrollPanel", f)
    body:Dock(FILL)
    body:DockMargin(4, 46, 8, 8)

    local function Line(text, col, font, indent)
        local l = vgui.Create("DLabel", body)
        l:Dock(TOP)
        l:DockMargin(indent or 4, font and 10 or 0, 4, 4)
        l:SetFont(font or "DermaDefault")
        l:SetTextColor(col or INK)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText(text)
        return l
    end

    local function ShowSection(sec)
        body:Clear()
        Line(string.upper(sec[1]), ACCENT, "DermaDefaultBold")
        for _, line in ipairs(sec[2]) do Line(line, INK, nil, 12) end
    end

    local function ShowSearch(q)
        body:Clear()
        q = string.lower(q)
        local found = 0
        for _, sec in ipairs(sections) do
            local head
            for _, line in ipairs(sec[2]) do
                if string.find(string.lower(line), q, 1, true) or string.find(string.lower(sec[1]), q, 1, true) then
                    if not head then head = Line(string.upper(sec[1]), ACCENT, "DermaDefaultBold") end
                    Line(line, INK, nil, 12)
                    found = found + 1
                end
            end
        end
        if found == 0 then Line("Nothing about \"" .. q .. "\". Try one word: tie, rent, curfew, fish...", Color(150, 145, 130)) end
    end

    for _, sec in ipairs(sections) do
        local b = vgui.Create("DButton", list)
        b:Dock(TOP)
        b:SetTall(26)
        b:DockMargin(0, 0, 0, 2)
        b:SetText(sec[1])
        b.DoClick = function() search:SetValue("") ShowSection(sec) end
    end
    search.OnChange = function(self)
        local q = string.Trim(self:GetValue() or "")
        if q == "" then ShowSection(sections[1]) else ShowSearch(q) end
    end
    ShowSection(sections[1])
end
LC_OpenGuide = OpenGuide
function LC_GuideOpen() return IsValid(guide) end
function LC_CloseGuide() if IsValid(guide) then guide:Remove() guide = nil end end

-- The server's answer to F1 (if it's bound to gm_showhelp) and to !help.
net.Receive("lcg_help", function()
    local admin = net.ReadBool()
    if IsValid(guide) and (guide.lcOpenedAt or 0) > CurTime() - 0.5 then return end -- the key already opened it
    if (LC_CL and LC_CL.ActionsOpenedAt or 0) > CurTime() - 0.5 then return end -- F1 opened a menu; the guide is in the full one
    OpenGuide(admin)
end)

concommand.Add("lc_help", function() OpenGuide(LocalPlayer():IsAdmin()) end)

-- F1 itself opens the quick menu (cl_livingcity_quick.lua); C opens the full menu, which has the
-- guide in it. With the guide open, F1 closes it.

-- Chat shows who people are in the city, not their Steam names.
hook.Add("OnPlayerChat", "LivingCityCharacterNames", function(ply, text, teamOnly, dead)
    if not IsValid(ply) then return end
    local name = ply:GetNW2String("lc_char", "")
    if name == "" then return end
    chat.AddText(Color(150, 170, 200), name, color_white, ": " .. text)
    return true
end)
