--[[
    Living City: tips that pop up the first time something happens

      A small card slides in on the right of the screen the first time you
      meet each part of the game: the first bin you walk up to, the first time
      you see someone go down, the first spray can in your pockets, the first
      curfew. Each tip shows once per player (a few, like being hungry, come
      back now and then), so a new player learns the city by living in it and
      an old hand never sees them again.

      Where they come from:
        what happens to you       going down, getting wanted, stopped, jailed,
                                  disguised, promoted, a conduct strike...
        what happens around you   curfew, rations, sweeps, raids, skirmishes,
                                  an outbreak, the city tipping into unrest
        what's near you           bins, water, sinks, stoves, dispensers, the
                                  Commissary, the dealer, bodies, someone down,
                                  the quartermaster, rebel crates and pots,
                                  graffiti, your own block, rebel ground...
        what's in your pockets    seeds, a lockpick, raw meat, clothes, papers,
                                  gun parts, a homemade gun...
        how you're doing          hungry, thirsty, parasites, hurt, low standing

      Players: !hints shows the last few again, !hints off / !hints on,
      !hints reset to see them all from the start.
      Server: lc_hints 0/1.
]]

if CLIENT then return end

util.AddNetworkString("lc_hint")

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvHints = CreateConVar("lc_hints", "1", FLAGS, "Tips that pop up the first time a player meets each part of the game (players can turn theirs off with !hints off)")

local BACKLOG = 50   -- seconds of tips waiting on a player's screen before more are held back
local INTRO_GAP = 30 -- seconds between the getting-started tips (tips about what's around you come in between)
local SCAN_EVERY = 1 -- seconds between looks at what's around each player

------------------------------------------------------------------------
-- The tips
--
--   title, text   a string, or a table by role (citizen, resistance, cp, ota,
--                 zombie, default). Overwatch falls back to cp. Zombies only
--                 get tips written for them.
--   urgent        shown straight away, ahead of anything waiting
--   every         seconds: comes back after this long instead of once
--   when          function(ply): only when this is true
--
--   Keys in braces become the player's own binding: {+use} shows as [E].
------------------------------------------------------------------------

local function Needs() local c = GetConVar("lc_needs") return c and c:GetBool() and LC.Running end
local function ICChat() return LC.ICChatActive and LC.ICChatActive() end

LC.HINTS = {
    -- first steps, in this order, a few seconds after you arrive
    welcome = { title = "Welcome to the city",
        text = "The city runs whether you're watching or not. Tips like this pop up the first time you run into something. {gm_showhelp} opens your quick menu: the nine things you'll do most, on the number keys (6 to 8 change with what's in front of you). {+menu_context} opens the full menu: everything, with the guide at the top. Its Settings turn tips off." },
    intake_arrival = { title = "Nothing is yours yet", urgent = true, when = function(ply) return LC.IntakePending and LC.IntakePending(ply) end,
        text = { default = "You've just arrived: no papers, no room, no ration card. Civil Intake registers you (your screen points the way): {+use} at the terminal and fill in who you are. Until then there are no rations or Union work for you, and units will ask for papers you don't have." } },
    intake_housing = { title = "A room", when = function(ply) return LC.AwaitingHousing and LC.AwaitingHousing(ply) and not (LC.IntakePending and LC.IntakePending(ply)) end,
        text = { default = "You're on the register, and your papers are in your pockets ({gm_showteam}). Housing Allocation gives you a room: {+use} at the terminal, present your papers and pick a block, and stay put while it searches. Until then, a curfew finds you waiting near Civil Intake." } },
    menus = { title = "Your menus",
        text = { default = "{gm_showteam}: your pockets (eat, drink, make, give, wear). {gm_showspare1}: jobs and quests. {gm_showspare2}: your faction and rank.",
                 zombie = "{gm_showspare2}: your faction. You don't need pockets where you're going." } },
    f_citizen = { title = "You're a citizen",
        text = { citizen = "Pick a Union job on your {gm_showspare1} board and work shifts for credits and Civil Standing. Good standing opens up the Commissary, and at 100 you can join Civil Protection." } },
    f_resistance = { title = "You're in the Resistance",
        text = { resistance = "You come back in plain clothes: units leave you alone until they see a gun in your hand. {+menu_context} > Resistance > Gear up puts your own gear on. Rebel territory is home: the quartermaster, a supply crate, the pots." } },
    f_vort = { title = "A shackled vortigaunt",
        text = { vort = "You're Combine property: you work the Union's shifts ({gm_showspare1}), and the collar holds your vortessence in. The Resistance can cut your shackles. Then you heal and strike, and they hunt you." } },
    f_freevort = { title = "Free", when = function(ply) return ply:GetNW2String("lcf_special", "") == "vortigaunt" end,
        text = { resistance = "Your vortessence: {+attack} a bolt at what you're looking at, {+attack2} heals whoever's in front of you, or yourself. Units hunt you on sight outside rebel territory." } },
    f_cp = { title = "Civil Protection",
        text = { ota = "You're Overwatch: the Combine's soldiers, not its police. Your operations are on {gm_showspare1}. Units call for help ({gm_showhelp}, then 1: Call for backup); answer it. 2 sends your 10-20, marking where you are. The Civil Protection Commissary issues your ammunition and grenades ({gm_showteam} marks the way).",
                 cp = "Your Arrest Baton: {+attack} strikes, {+attack2} arrests, {+reload} searches. Your directives are on {gm_showspare1}. Your quick menu ({gm_showhelp}) has backup, your 10-20, a BOLO, the mask's voice and records on the number keys, and search and ties for whoever you're looking at. Everything else: {+menu_context} > Unit tools. Supplies: the Civil Protection Commissary ({gm_showteam} marks the way)." } },
    f_zombie = { title = "Infested",
        text = { zombie = "Your claws: {+attack} swipes, {+attack2} moans. The infestation is home. You don't eat, and you don't go down: you just die." } },
    cp_tools = { title = "Your tools", when = function() local c = GetConVar("lc_cp_tools") return c and c:GetBool() end,
        text = { cp = "{+menu_context} > Unit tools has it all, each with what it does: the records terminal (CIDs, violations, loyalty points, BOLOs and requests), the mask's voice lines, and for whoever you're looking at, search, zip-tie and drag (the quick menu, {gm_showhelp}, has the ones you use most). You don't queue for rations: your ration, ammunition and grenades are issued at the Civil Protection Commissary ({gm_showteam} marks the way)." } },
    ic_chat = { title = "Talking", when = ICChat,
        text = { default = "Chat is spoken out loud: only people near you hear it. {+menu_context} > Talk yells, whispers, describes what you do or the scene, and talks out of character (in chat: /y, /w, /me, /it, //).",
                 zombie = "Chat is spoken out loud: only people near you hear it. // is out of character, for everyone." } },
    help_staff = { title = "Need a hand?",
        text = { default = "{+menu_context} > Help > Ask staff for help reaches the staff (or type @ and your message), for anything out of character: stuck, a rule question, someone breaking the rules." } },
    night = { title = "Night", when = function() local c = GetConVar("lc_atmosphere") return c and c:GetBool() end,
        text = { default = "The city goes dark from 21:00 to 05:00, and curfews come three times as often. {+menu_context} > The city tells you the hour.",
                 zombie = "Night. The streets are darker, and the living stay in." } },
    rain = { title = "Rain", when = function() local c = GetConVar("lc_atmosphere") return c and c:GetBool() end,
        text = { default = "Stand out in it with an empty bottle or can and it fills (untreated: boil it before you drink)." } },
    acts_intro = { title = "Acting", when = function() local c = GetConVar("lc_acts") return c and c:GetBool() end,
        text = { default = "{+menu_context} > Me > Pose: sit, kneel, lie, lean (move to stand up). Me > Gesture: wave, salute, bow, nod and more. Me > Put my hands up." } },
    slots_intro = { title = "More than one life", when = function() local c = GetConVar("lc_char_slots") return c and c:GetInt() > 1 end,
        text = { default = "You can have more than one person in the city. {+menu_context} > Me > My characters: switch between them, or start someone new." } },
    needs_intro = { title = "Hunger and thirst", when = Needs,
        text = { default = "Hunger and thirst drain over time (the bars at the top left; on a quiet HUD they show up once they start to bite). Rations come from the dispensers, water from vending machines and sinks. At zero you start dying.",
                 resistance = "Hunger and thirst drain over time (the bars at the top left; on a quiet HUD they show up once they start to bite). The supply crate in rebel territory feeds the Resistance; bins, fishing and the pots help. At zero you start dying." } },
    quiet_hud = { title = "Nothing keeps score", when = function() local c = GetConVar("lc_quiet_hud") return c and c:GetBool() end,
        text = { default = "No numbers on screen. Your credits and Civil Standing are at the top of your pockets ({gm_showteam}), your rank and progress on {gm_showspare2}." } },
    view_bob = { title = "Your eyes", when = function() local c = GetConVar("lc_view_bob") return c and c:GetBool() end,
        text = { default = "The camera sways a little with your steps and dips when you land. If that bothers you, {+menu_context} > Settings > Camera sway keeps it still (just for you)." } },

    -- what happens to you
    downed_self = { title = "You're down", urgent = true,
        text = "You're bleeding out, not dead. Anyone can get you up by pressing {+use} on you. You can only whisper for help. {+menu_context} > Me > Give up, if nobody's coming." },
    revived = { title = "Back on your feet",
        text = "You're up, but barely. Patch yourself up: a bandage from {gm_showteam} (make them from two rags), a medkit, or a medic." },
    wanted = { title = "You're wanted", urgent = true,
        text = { default = "Units will come for you. Get out of their sight and it cools down. Or give yourself up: walk to a unit and press {+use} ({+menu_context} > Me > Give myself up) for half the sentence.",
                 cp = "Even units can be wanted. Get out of sight and it cools down, or press {+use} on a unit to hand yourself in." } },
    alert2 = { title = "Every unit has your description", urgent = true,
        text = "They've drawn pistols. At the next level Overwatch comes, and they don't arrest. Stay out of every unit's sight for 45 seconds to cool down (faster in rebel territory)." },
    alert3 = { title = "Overwatch is coming", urgent = true,
        text = "A soldier squad is hunting you, with lethal force. Break line of sight and keep it broken. Rebel territory cools you down twice as fast." },
    stopped = { title = "Stop and search", urgent = true,
        text = "A unit is searching you. Stand still (hands up doesn't hurt: {+menu_context} > Me). Walk off and you're wanted for evading inspection. Anything illegal they find is confiscated." },
    tied_self = { title = "Your hands are tied", urgent = true,
        text = "You can't use anything, and you can only walk. Someone can cut you free. Left alone, {+menu_context} > Me > Work at the ties; if anyone sees, they pull them tighter." },
    socio_yellow = { title = "Sociostability: marginal",
        text = { default = "More stop-and-searches on the street. Keep your papers ready and nothing on you you'd want found. The level is at the top of your screen.",
                 cp = "Half as many stops again. The level is on your mask's readout; officers can set it in {+menu_context} > Unit tools." } },
    socio_red = { title = "Judgment waiver", urgent = true,
        text = { default = "Units may use lethal force as they see fit. Get indoors and stay out of sight until it lifts.",
                 cp = "Lethal force at your discretion, and twice the stops. It lifts when the city calms, or when an officer says so." } },
    searched = { title = "Searched",
        text = "Contraband in your pockets gets found. Your stash at home ({+menu_context} > Getting by) is never searched, though sweeps sometimes raid it." },
    running = { title = "Don't run in front of units", urgent = true,
        text = "A unit told you to stop running. Stop within two seconds and that's the end of it. Keep running and you're wanted for fleeing." },
    jailed = { title = "In custody",
        text = "Serve your time and you're let out at the release point. A friend can pass you a lockpick (Give, in their pockets) and you can work your cell door when no guard is looking. Escaping makes you wanted. If there's a Combine console in your cell, {+use} it to fly a city scanner while you wait." },
    released = { title = "Released",
        text = { default = "Your standing took a hit. Community service on your {gm_showspare1} board earns it back, and so does keeping your head down." } },
    escaped = { title = "You're out", urgent = true,
        text = "And wanted. Get out of sight. Spare clothes, a uniform or forged papers can make you someone else." },
    curfew_warning = { title = "Get home", urgent = true,
        text = { default = "A unit has caught you out after curfew. Three warnings and you're wanted. The arrow on your HUD points to your block. A travel permit gets you past one stop." } },
    disguise_cp = { title = "In a CP uniform",
        text = { default = "Units on the street take you for one of them, for a while. Don't hang around real units, don't commit crimes, and don't let one search you. Combine doors usually open." } },
    disguise_rebel = { title = "In Resistance gear",
        text = { default = "The fighters take you for one of them, and units will shoot you on sight. A fighter standing close may ask questions you can't answer." } },
    disguise_citizen = { title = "In plain clothes",
        text = { default = "You pass as an ordinary citizen. A gun in your hand where a unit can see it gives you away. Never change in front of a unit.",
                 cp = "You pass as an ordinary citizen. Undercover work: citizens talk more freely, and nobody salutes." } },
    disguise_blown = { title = "Cover blown", urgent = true,
        text = "They know who you are. Get away, and change somewhere nobody can see you." },
    strike = { title = "Conduct strike", urgent = true,
        text = "That kill had no roleplay reason. Two strikes is prison, four is a kick. Give people a reason first: a warning, a demand, a fight they started." },
    new_character = { title = "A new life",
        text = "Death here is permanent: that character is gone. New name, new face, and nobody knows you. Being shot first puts you down, so next time someone may get to you in time." },
    promoted = { title = "Promoted",
        text = { default = "A new rank can mean new gear, new jobs and new trust. {gm_showspare2} shows what your rank opens up.",
                 cp = "A new rank can mean new gear: grenades come from Unit 04 up. {gm_showspare2} shows what your rank opens up." } },
    promoted_member = { title = "A Resistance Member",
        text = { resistance = "Fighters will follow you now: press {+use} on one in rebel territory (three at most). {+use} again sends them home." } },
    ration = { title = "A ration",
        text = "Eat it from {gm_showteam} when you're hungry. One per allocation, twice as often during distribution. Low standing gets you nothing." },
    crafted_arms = { title = "Homemade arms",
        text = { default = "It's contraband in your pockets until you draw or load it ({gm_showteam}), and a search will find it. The black market buys it. The Resistance quartermaster pays half as much again." } },

    -- what happens around you
    event_rations = { title = "Ration distribution",
        text = { default = "Rations come twice as often now. Join a ration line and wait your turn, or press {+use} on a dispenser.",
                 cp = "Keep the ration lines orderly. Citizens crowding a unit get moved along." } },
    event_sweep = { title = "Inspection sweep",
        text = { default = "Units are stopping and searching everyone. If you're carrying contraband, stash it (in your stash, at home) or stay off the streets.",
                 cp = "Stop and search citizens: {+reload} with your baton. What you seize pays credits and XP." } },
    event_raid = { title = "Block raid",
        text = { default = "Units are going through a housing block, frisking residents and taking contraband lying around. Whoever dropped it gets wanted.",
                 cp = "A raid team is going through a housing block. Seized contraband is traced to its owners." } },
    event_curfew = { title = "Curfew",
        text = { default = "Go home: the arrow on your HUD points to your housing block, with a grace period to get there. After that, a unit who sees you out gives three warnings, then you're wanted.",
                 cp = "Citizens have a grace period to get home. After it, anyone outside gets three warnings from a unit before they're wanted." } },
    event_lockdown = { title = "Lockdown",
        text = { default = "Get inside your block now. Extra units are on the streets. After the grace period, anyone outside gets three warnings, then they're wanted.",
                 cp = "Extra units are on the streets. Clear them: three warnings, then anyone still out is wanted." } },
    skirmish_raid = { title = "A rebel raid",
        text = { default = "Fighters are hitting a checkpoint, and the units nearby are fighting back. Keep your head down, or keep well clear.",
                 resistance = "Fighters are hitting a checkpoint. Join in, or keep your cover. Either way, it's on the radio.",
                 cp = "Fighters are hitting a checkpoint. {+menu_context} > Unit tools: Call for backup brings units to you, and Send my 10-20 shows them where you are." } },
    skirmish_sweep = { title = "A sweep into rebel ground",
        text = { default = "An armed CP team is going into rebel territory. Stay out of it.",
                 resistance = "An armed CP team is going into rebel territory, and the fighters are fighting back. Help them, or get clear.",
                 cp = "An armed team is sweeping rebel territory. Kills there push the Resistance back." } },
    outbreak = { title = "Outbreak",
        text = { default = "The infestation has broken out: infected in the nearby streets, and a lockdown. Get indoors.",
                 cp = "The infected are loose in the streets near the infestation. Contain it.",
                 zombie = "The infestation has broken out. The streets are yours, for now." } },
    city_unrest = { title = "The city is in unrest",
        text = { default = "The Resistance holds enough ground: more inspections and raids, slower rations, a cheaper black market. {+menu_context} > The city > Who holds the city." } },
    city_order = { title = "Full compliance",
        text = { default = "Nothing has spread. Fewer skirmishes, and a dearer black market. {+menu_context} > The city > Who holds the city." } },

    -- what's near you
    downed_other = { title = "Someone's down",
        text = { default = "They're bleeding out. Press {+use} on them to get them up (a bandage makes it faster). Looking at them, {gm_showhelp} (your quick menu) > Drag them along pulls them into cover. Shooting them finishes them.",
                 cp = "They're bleeding out. Press {+use} on them to get them up; if they're wanted, {+use} cuffs them where they lie. {gm_showhelp} (your quick menu) > Drag them along pulls them with you. Shooting them finishes them." } },
    body = { title = "A body",
        text = { default = "Press {+use} and stay with it a few seconds to search it: food, credits, ammunition, sometimes clothes or a keycard. Not in front of a unit. Looking at it, {gm_showhelp} > Haul the body works too: Morticians are paid to drag the dead to the incinerator.",
                 cp = "Press {+use} and stay with it a few seconds to search it. Dead rebels sometimes carry their gear." } },
    bin = { title = "Bins",
        text = { citizen = "Press {+use} on a bin or dumpster to go through it: scrap, rags, tins, seeds, sometimes gun parts. Looking at one, your pockets ({gm_showteam}) can hide things in it, for anyone to find.",
                 resistance = "Press {+use} on a bin or dumpster to go through it (rebel territory's are better). Looking at one, your pockets ({gm_showteam}) can leave things in it: a dead drop." } },
    locker = { title = "A locker",
        text = { default = "Press {+use} to open it. Put something in and it's yours: locked to everyone else. Units can open any locker, and take what's illegal.",
                 cp = "Lockers belong to whoever claimed them. Press {+use} to search one: you can confiscate contraband, and the owner is wanted." } },
    apartment = { title = "An apartment for rent",
        text = { default = "Look at the door, {+menu_context} > This door > Rent it: a place of your own, locked to everyone but you and whoever you give a key (look at them: {+menu_context}). {+menu_context} > Home locks and unlocks it." } },
    stall = { title = "A market stall",
        text = { default = "Someone's selling. Press {+use} to see what's on it and what it costs.",
                 cp = "A licensed trader. Press {+use} to search it; an officer can revoke their license from the records terminal." } },
    note = { title = "Something written",
        text = { default = "A note or a notice. Press {+use} to read it; you can take it with you.",
                 cp = "A note or a notice. Press {+use} to read it. Units can tear down notices." } },
    lawboard = { title = "The law",
        text = { default = "The city's laws. Press {+use} to read them, or {+menu_context} > The city > The city's laws, anywhere." } },
    overweight = { title = "Too much to carry", urgent = true,
        text = "You're carrying more than you can manage, so you're slowed down. Drop something, or carry a satchel." },
    water = { title = "Water",
        text = { default = "Press {+use} standing in water to drink, but untreated water can give you parasites. Fill empty bottles and cans here ({gm_showteam}), then boil them. A fishing line works here too." },
        when = Needs },
    sink = { title = "A sink", when = Needs,
        text = { default = "Press {+use} to drink (a small risk of parasites). Fill bottles and cans from {gm_showteam}, then boil them." } },
    stove = { title = "Heat", when = Needs,
        text = { default = "Near a stove or fire you can cook raw meat and fish, and boil water, from your pockets ({gm_showteam})." } },
    vending = { title = "Vending machine",
        text = { default = "Press {+use} to buy a can of Breen's Private Reserve. It quenches thirst, and leaves you a little dizzy.",
                 resistance = "Press {+use} to buy a can. With a multitool, aim at it and fire: ten seconds and it drops three cans, free. Not where a unit can see you." } },
    dispenser = { title = "Ration dispenser",
        text = { default = "Press {+use} for your ration: one per allocation, none if your standing is too low. A forged ration card gets one anyway.",
                 resistance = "Press {+use} for your ration. With a multitool, aim at it and fire: ten seconds and it spits out three packets, no coupon, no record. Not where a unit can see you.",
                 cp = "Citizens get one ration per allocation here. Units don't queue." } },
    event_supply = { title = "Supply drop",
        text = { default = "Union supplies are coming in: a crate of them at the loading dock. Anyone can press {+use} on it to take a load, but a unit who sees you is trouble.",
                 resistance = "A Combine supply drop: guns, ammunition, medicine. Press {+use} on the crate to take a load. The units guarding it will fight.",
                 cp = "A supply drop to guard: if anything's left in the crate when the convoy moves on, every unit nearby is paid. Directive on your board." } },
    item_jammer = { title = "A radio jammer",
        text = "Set it down from {gm_showteam}: for four minutes, unit radios nearby are static, request devices don't get through, and scanner photos never reach Civil Protection. It beeps, and units will come looking for it." },
    crowbar = { title = "A crowbar", urgent = true,
        text = "Hold it and press {+use} on junk (a wrecked car, a radiator, pipes, a crate) to pry scrap, rags and chemicals out of it: loud, and the nearest unit comes to look. It's a weapon, too: a unit who sees it in your hand makes you wanted. Put it away on the street." },
    interrogated = { title = "Interrogation", urgent = true,
        text = "Choose Talk (on screen, or {gm_showhelp}) and the beating stops: you give them a Resistance hideout, and if you're Resistance the cell will know you talked. Or say nothing and take it: it won't kill you." },
    crippled = { title = "Broken feet", urgent = true,
        text = "You can't run until it heals (the time is on your screen). It doesn't heal faster for dying or leaving." },
    stalker = { title = "Combine property", urgent = true,
        text = "You're a stalker now: slow, unarmed, unable to speak. Your board has work orders for you. It ends when your time is served, or when you die." },
    traitor = { title = "Traitor", urgent = true,
        text = "A Resistance member saw you inform. The Resistance see TRAITOR over your head for half an hour, and their fighters will shoot you. Stay away from rebel ground." },
    dataterm = { title = "Combine data terminal",
        text = { default = "Combine systems. Not for you.",
                 resistance = "A Hacker's job: aim the multitool at it, primary fire, and stay close for thirty seconds. It sounds the alarm halfway, and a squad comes. One terminal gives you a fragment, half the picture: download a second terminal's and the two make a whole chip. Sell the chip to the dealer, have the lab's scientist decode it (every unit marked for the whole Resistance), or plug it into a terminal to wipe your record.",
                 cp = "A Combine data terminal. If the Resistance get at it, the alarm goes off: DATA BREACH." } },
    masterterm = { title = "The master terminal",
        text = { default = "The Combine's master terminal. Not for you.",
                 resistance = "The motherlode. A Hacker's job: aim the multitool at it, primary fire, and hold on for a full minute. The alarm goes a third of the way in and a bigger squad comes. What you get is a master data core: the dealer pays a fortune, the quartermaster's decoding marks every unit for ten minutes, and plugged into a terminal it wipes every comrade's record. Dry for an hour after.",
                 cp = "The master terminal. If the Resistance get at it, every alarm in the nexus goes off." } },
    item_datashard = { title = "A data fragment",
        text = "Half of a chip. Download a second terminal's data (a different terminal) and the two fragments make a whole chip. Contraband: hide it." },
    item_masterchip = { title = "The master data core",
        text = "The motherlode. Contraband: hide it well. The dealer pays a fortune; the quartermaster's decoding marks every unit for the whole Resistance for ten minutes; used at a terminal it wipes the records of every Resistance member in the city." },
    item_datachip = { title = "A Combine data chip",
        text = "Contraband: hide it. The black market dealer pays well for it. The Resistance quartermaster can decode it (Use it from your pockets near him): every unit marked for the whole Resistance for five minutes. Or use it at a terminal to wipe your own record." },
    workbench = { title = "The lab",
        text = { resistance = "The cell's lab. Press {+use} on the scientist: he makes guns, ammunition, armour, jammers, bypass charges and Freq 7 radios. Bring the materials and it's free, or pay him (cheaper than the dealer). Stay in the lab while he works.",
                 cp = "A Resistance lab. Press {+use} on the scientist to shut it down: he's taken away, and nothing is made here for a while.",
                 default = "A cluttered lab bench, and a nervous man beside it. He works for the Resistance, and only for them. Everyone else buys guns at the black market." } },
    transformer = { title = "Transformer",
        text = { default = "It powers this district: the streetlights, loudspeakers, screens, forcefields and the Combine door locks. If it goes down, a Maintenance Technician brings it back ({+use}).",
                 resistance = "It powers this district, Combine door locks included. A multitool shorts it out in twelve seconds: the lights go out and their doors open, until someone fixes it.",
                 cp = "It powers this district, our door locks and forcefields included. Keep the Resistance away from it." } },
    forcefield = { title = "Combine forcefield",
        text = { default = "Units walk through it. Nobody else does, unless they swipe a Combine keycard ({+use}). It drops when the district's power goes.",
                 resistance = "Units walk through. A Combine keycard ({+use}) opens it for a moment; a multitool shorts it out for a minute; and it drops with the district's power." } },
    powerbank = { title = "Combine power bank",
        text = { default = "A checkpoint's power. The turrets and forcefields cabled to it run off it, and it draws from the district's transformer: when the power goes, so do they.",
                 resistance = "A checkpoint's power. A multitool ({+attack} with it out, aimed at the bank) shorts it out for two minutes, and every turret and forcefield on its cables dies with it. Near the infestation, that's a breach.",
                 cp = "Your checkpoint's power. Deploy turrets near it ({+menu_context} > Civil Protection). Keep the Resistance off it: if it dies near the infestation, the infected break out." } },
    turret = { title = "Combine turret",
        text = { default = "It shoots the infected, the wanted and known rebels, and leaves everyone else alone. Its cable runs to the checkpoint's power.",
                 resistance = "It shoots you on sight if they know you. Kill its power (the power bank, or the district's transformer) and it folds up.",
                 cp = "It shoots the infected and the wanted. Units put up two each ({+menu_context} > Civil Protection) and pack them up with {+use}." } },
    incinerator = { title = "Incinerator",
        text = { default = "The city's dead end up here. Haul a body over (Morticians: {+use} on a body; anyone: look at it, {gm_showhelp} > Haul the body) and let go beside it, or press {+use} on the incinerator. Attendants are paid for each one.",
                 resistance = "The city's incinerator. A body that goes in here never gets identified. Haul one over: look at it, {gm_showhelp} > Haul the body." } },
    recycler = { title = "Reclamation point",
        text = { default = "Press {+use} to hand in scrap, empty cans and bottles: a few credits and a little Civil Standing. The loyal way to use junk.",
                 resistance = "Press {+use} to hand in scrap, cans and bottles for credits and standing. Or keep it: the cell makes ammunition from scrap.",
                 cp = "Citizens hand in scrap here for credits and standing." } },
    console = { title = "Combine console",
        text = { default = "Prisoners and units: press {+use} to fly one of the city's scanners. Your body stays here. Left click flashes; flash a unit and your sentence grows. Get within about ten feet of rebels, free vortigaunts, the wanted or zombies and photograph them for Civil Standing (never time off). R disconnects.",
                 cp = "Press {+use} to fly a city scanner. Left click photographs whatever's within about ten feet: rebels, free vortigaunts, the wanted and zombies it catches are lit up for every unit." } },
    scanreport = { title = "Scanner report",
        text = "A scanner photographed someone. Whoever it caught is outlined in red for a minute, through walls, and rebel ground is marked on your screen. Go and get them." },
    photographed = { title = "Photographed", urgent = true,
        text = "A scanner caught you. Every unit can see where you are for a minute. Get out of sight, shoot the scanner down, or throw smoke: a scanner can't photograph anyone in it or behind it." },
    terminal = { title = "The Commissary",
        text = { default = "Press {+use} to shop. What it sells you depends on your Civil Standing.",
                 cp = "Press {+use} to shop: ammunition, batteries and grenades for units. (A Civil Protection Commissary issues them for nothing.)" } },
    cpsupply = { title = "Civil Protection Commissary",
        text = { cp = "Press {+use} to be issued supplies: grenades for your rank, ammunition for your weapons, armour, bandages and your ration. Once every two minutes; the unit counter opens after.",
                 ota = "Press {+use} to be issued supplies: grenades, ammunition, armour, bandages and a ration. Once every two minutes.",
                 default = "Civil Protection's supply point. Units only." } },
    dealer = { title = "The black market",
        text = { default = "Press {+use} to trade: papers, uniforms, lockpicks, spray cans, seeds, gun parts. He buys almost anything. Don't let a unit see you.",
                 cp = "A black market dealer. Walk up to him and he's busted: gone for 15 minutes, and you're paid." } },
    cache = { title = "A supply crate",
        text = { resistance = "The Resistance eats from this: press {+use} for a tin, one every four minutes. {+menu_context} > Resistance > Donate food puts food from your pockets in.",
                 citizen = "A Resistance supply crate. Food from your pockets goes in: {+menu_context} > Resistance > Donate food.",
                 cp = "Hoarded Resistance supplies. Press {+use} to confiscate the lot." } },
    pot = { title = "A pot",
        text = { default = "Plant a seed packet in it with {+use}. In a few minutes it's three lots of vegetables, and anyone can harvest a ripe pot.",
                 cp = "A Resistance garden. Press {+use} to uproot it." } },
    tag = { title = "Graffiti",
        text = { citizen = "A Resistance tag. Scrub it off with {+use} for standing, or leave it.",
                 resistance = "The lambda. Spray cans (black market) put it on walls. Tags near rebel ground help it spread. Don't let a unit see you.",
                 cp = "Press {+use} on a lambda tag to scrub it off, for XP." } },
    quartermaster = { title = "The quartermaster",
        text = { resistance = "Press {+use} to trade. He sells the black market's stock to the Resistance, and pays half as much again for homemade guns and ammo." } },
    fighter = { title = "Fighters",
        text = { resistance = "From Resistance Member up, press {+use} on a fighter to have them follow you and fight with you (three at most). {+use} again sends them home." } },
    citizen_npc = { title = "People",
        text = { default = "Everyone here has a name and a life. Press {+use} on someone to talk: what they've heard, a bit of food, or a hand in their pocket. They remember how you treat them.",
                 cp = "With the baton out: {+use} stops a citizen, {+reload} pats them down (sympathizers carry more), {+attack2} detains them." } },
    cop_near = { title = "Civil Protection",
        text = { citizen = "Don't run in front of units and don't crowd them. If one stops you, stand still until it's over.",
                 resistance = "Don't run in front of units and don't crowd them. Keep your gun out of sight in plain clothes." } },
    wanted_near = { title = "Someone wanted",
        text = { cp = "Someone near you is wanted. Your baton's {+attack2} arrests them, {+reload} searches. {+menu_context} > Unit tools > Call for backup if it turns ugly." } },
    unshackle = { title = "A shackled vortigaunt",
        text = { resistance = "From Member up, you can cut its shackles: look at it, {+menu_context} > Cut the vortigaunt's shackles (ten seconds, no unit watching). It joins the Resistance." } },
    stranger = { title = "Strangers", when = ICChat,
        text = { default = "People don't know your name until you tell them: look at someone, {+menu_context} > Tell them my name (or show them your papers). Until then they see your description: {+menu_context} > Me > Change how strangers see me." } },
    birds = { title = "Birds",
        text = { default = "One punch kills a bird. Cook the carcass at a stove or burning barrel ({gm_showteam})." } },
    headcrab = { title = "A headcrab",
        text = { default = "Weak, but don't turn your back. Several punches kill one, and it leaves meat to cook. Never go AFK in an alley." } },
    zone_rebel = { title = "Rebel territory",
        text = { citizen = "The fighters leave citizens alone. The bins are better here, and the black market is open ({+menu_context} > Getting by). Stay out of any shooting.",
                 resistance = "Home. You're among friends. The quartermaster, the supply crate and the pots are here, and you can make guns and ammo ({gm_showteam}).",
                 cp = "The fighters shout once, then shoot. Come in with a sweep, or with backup. Kills here push the Resistance back." } },
    zone_infest = { title = "The infestation",
        text = { default = "Zombies and headcrabs. Nothing here is worth it unless you've got a reason.",
                 cp = "Containment jobs on your board send units in. Kills here push the infestation back.",
                 zombie = "Home." } },
    home_block = { title = "Your block",
        text = { default = "This is your housing block: come here at curfew. You can make things here ({gm_showteam}), and keep what you don't want found in your stash ({+menu_context} > Getting by)." } },
    trespass = { title = "Combine only", urgent = true,
        text = "You're trespassing. Leave before the countdown on your screen runs out, or you're wanted." },
    plainclothes_gun = { title = "Careful", urgent = true,
        text = { resistance = "You're in plain clothes with a gun in your hand. If a unit sees it, your cover is blown. Switch to your fists or holster it ({+menu_context} > Me)." } },
    grenades = { title = "Grenades",
        text = { cp = "{+attack} throws, {+reload} switches between smoke, flashbang and gas. Smoke hides you, a flashbang blinds, gas chokes anyone without a mask. Units are masked." } },

    -- how you're doing
    hungry = { title = "Hungry", every = 900, when = Needs,
        text = { default = "Eat something from {gm_showteam}. No food? A ration dispenser, the Commissary, a bin, fishing, or something you can cook.",
                 resistance = "Eat something from {gm_showteam}. No food? The supply crate in rebel territory, a bin, the pots, fishing." } },
    thirsty = { title = "Thirsty", every = 900, when = Needs,
        text = { default = "Drink something from {gm_showteam}. A sink, a vending machine, or water: boil it first if you can." } },
    parasites = { title = "Parasites",
        text = { default = "Untreated water. You'll be hungrier and thirstier, and coughing, until you take antiparasitic tablets (Commissary)." } },
    hurt = { title = "Hurt", every = 1200,
        text = { default = "Patch yourself up: a bandage from {gm_showteam} (two rags make one), a medkit, or a medic." } },
    low_standing = { title = "Low standing",
        text = { citizen = "Your Civil Standing is below zero: no rations, and units watch you. Community service on your {gm_showspare1} board earns it back, and so does keeping quiet." } },
    cp_eligible = { title = "You could join Civil Protection",
        text = { citizen = "Your standing is high enough to put on the uniform. {gm_showspare2} to join." } },

    -- what's in your pockets
    item_seeds = { title = "Seeds",
        text = "Plant them in a pot in rebel territory: look at the pot and press {+use}. They ripen into vegetables in a few minutes." },
    item_fishing = { title = "Fishing line",
        text = "Stand in the canal or look at the water, then Fish from {gm_showteam} (or {+menu_context} > Getting by) and keep still. Cook what you catch." },
    item_spray = { title = "A spray can",
        text = "Look at a wall and Spray from {gm_showteam} to put the lambda up. If a unit sees you, you're wanted for vandalism." },
    item_lockpick = { title = "A lockpick",
        text = "Look at a locked door: {+menu_context} > This door > Pick the lock (or bind a key to lc_pick). It won't open Combine locks. Give one to a prisoner (from {gm_showteam}) and they can work their own cell door." },
    item_bypass = { title = "A bypass charge",
        text = "Opens any door once, Combine doors included: look at the door, {+menu_context} > This door > Pick the lock. Sometimes it trips an alarm." },
    item_keycard = { title = "A keycard",
        text = "Opens one Combine door (look at it, {+menu_context} > This door > Pick the lock) before someone reports it missing." },
    item_raw = { title = "Raw meat",
        text = "Cook it near a stove, oven or burning barrel ({gm_showteam}). Eating it raw is a gamble." },
    item_empty = { title = "An empty container",
        text = "Fill it in water or at a sink ({gm_showteam}), then boil it near a stove or fire before you drink it." },
    item_dirty = { title = "Untreated water",
        text = "Boil it near a stove or fire first ({gm_showteam}), or risk parasites." },
    item_clothes = { title = "Clothes",
        text = "Wear them from {gm_showteam} to pass as an ordinary citizen. Never change in front of a unit." },
    item_uniform = { title = "A CP uniform",
        text = "Wear it from {gm_showteam}: units on the street will take you for one of them, for a while. It's contraband, and a search finds it." },
    item_gear = { title = "Resistance gear",
        text = "Wear it from {gm_showteam}: the fighters take you for one of them. Units will too, and they shoot." },
    item_papers = { title = "Papers",
        text = "Use them from {gm_showteam} to become someone else. It clears your wanted status, if no unit is watching." },
    item_blank = { title = "A blank identity form",
        text = "Forge it ({gm_showteam}) somewhere private: out of any unit's sight." },
    item_rationcard = { title = "A forged ration card",
        text = "One ration from any dispenser, whatever your standing or how recently you ate." },
    item_radio = { title = "A Union radio",
        text = "City notices come through it before an event. {+menu_context} > Talk > On my radio. Civil Protection listens." },
    item_radio_tuned = { title = "A radio, on Freq 7",
        text = "Freq 7: the Resistance band, and whatever Civil Protection says when it thinks nobody's listening. {+menu_context} > Talk > On my radio talks on it; On the Union band, on the city's. It's contraband." },
    item_permit = { title = "A travel permit",
        text = "Keep it on you. It gets you past one stop during curfew." },
    item_materials = { title = "Materials",
        text = "Rags make bandages and scrap makes lockpicks, by hand, anywhere ({gm_showteam}). Guns, ammunition, smoke bombs and jammers are the Resistance lab's work: its scientist makes them from these, for the Resistance. Everyone else buys them at the black market. More from bins, from junk pried apart with a crowbar, and from downed scanners." },
    item_papers = { title = "Your papers",
        text = "Identity papers and a ration card. Units ask for papers: look at them, {gm_showhelp} > Show them my papers (or {gm_showteam} > Show). The ration dispensers want the card. Lose them and Civil Intake replaces them, for a fee." },
    item_bandage = { title = "A bandage",
        text = "Patch yourself up from {gm_showteam}. Used on someone who's down, it gets them up faster and in better shape." },
    item_arms = { title = "Arms",
        text = "Contraband until you draw or load it from {gm_showteam}, and a search will find it. The black market buys it; the quartermaster pays more." },
    item_crate = { title = "Smuggled supplies",
        text = "Contraband in your pockets. Get them where they're going without being stopped." },
    item_grenade = { title = "Something to throw",
        text = "Throw it from {gm_showteam}. Smoke hides anyone in it from units and rebels alike." },
    item_tablets = { title = "Antiparasitic tablets",
        text = "Take them from {gm_showteam} if untreated water has given you parasites." },
    item_zipties = { title = "Zip ties",
        text = "Look at someone up close, {+menu_context} > their name > Zip-tie their hands: their hands up, down, stopped by a unit, or from behind. Drag walks them along; Cut the ties lets them go." },
    item_request = { title = "A request device",
        text = "/request <what's wrong> calls Civil Protection to where you are. Units see it on their screens. Once a minute, and false requests go on your record." },
    item_satchel = { title = "A satchel",
        text = "While you carry it you can take more: eight more kilos, and one more large thing. Your pockets ({gm_showteam}) show the weight." },
    item_storage = { title = "A storage crate",
        text = "Set it down somewhere from your pockets ({gm_showteam}, Set down) and it's yours to keep things in. Only you can open it, but units can." },
    item_license = { title = "A business license",
        text = "With it in your pockets you can set down a market stall (Commissary) and sell from it at your own prices. An officer can revoke it." },
    item_stall = { title = "A market stall",
        text = "Set it down from your pockets ({gm_showteam}, Set down). Then look at it and Sell things from your pockets at a price you choose. The money waits in the till." },
    item_paper = { title = "Paper",
        text = "Write from your pockets ({gm_showteam}): leave a note, put a poster up on a wall, or keep it. Sign it, or don't." },
    item_ring = { title = "A wedding ring",
        text = "It belonged to somebody. The black market pays well for it." },
}

-- Your pockets: which tip each item brings up.
local ITEM_HINTS = {
    seeds = "item_seeds", fishing_line = "item_fishing", spraypaint = "item_spray", lockpick = "item_lockpick",
    bypass = "item_bypass", cp_keycard = "item_keycard",
    raw_bird = "item_raw", raw_headcrab = "item_raw", raw_fastcrab = "item_raw", raw_poisoncrab = "item_raw", raw_fish = "item_raw",
    can_empty = "item_empty", bottle_empty = "item_empty", can_dirty = "item_dirty", bottle_dirty = "item_dirty",
    civvies = "item_clothes", cwu_overalls = "item_clothes", uniform_cp = "item_uniform", rebel_gear = "item_gear",
    papers_forged = "item_papers", papers_dead = "item_papers", papers_blank = "item_blank", ration_forged = "item_rationcard",
    radio = "item_radio", radio_tuned = "item_radio_tuned", permit = "item_permit",
    scrap = "item_materials", cloth = "item_materials", chemicals = "item_materials", gun_parts = "item_materials",
    id_papers = "item_papers", ration_card = "item_papers",
    bandage = "item_bandage", arms_crate = "item_crate", smuggled_supplies = "item_crate", tablets = "item_tablets", keepsake = "item_ring",
    gun_pistol = "item_arms", gun_shotgun = "item_arms", gun_smg = "item_arms",
    ammo_pistol = "item_arms", ammo_smg = "item_arms", ammo_buckshot = "item_arms",
    gun_357 = "item_arms", ammo_357 = "item_arms", jammer = "item_jammer", data_chip = "item_datachip", data_shard = "item_datashard", master_chip = "item_masterchip",
    business_license = "item_license", vendor_stall = "item_stall", paper = "item_paper", satchel = "item_satchel", storage_crate = "item_storage", zipties = "item_zipties", request_device = "item_request",
    smokebomb = "item_grenade", gren_smoke = "item_grenade", gren_flash = "item_grenade", gren_gas = "item_grenade",
}
LC.ITEM_HINTS = ITEM_HINTS

------------------------------------------------------------------------
-- Who's seen what
------------------------------------------------------------------------

local function RoleOf(ply)
    if LC.PlayerIsZombie and LC.PlayerIsZombie(ply) then return "zombie" end
    local f = ply:GetNW2String("lcf_faction", "")
    if f == "resistance" then return "resistance" end
    if f == "ota" then return "ota" end
    if f == "vort" then return "vort" end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return "cp" end
    return "citizen"
end
LC.HintRole = RoleOf

-- The text for this role, and which variant it was (nil for a plain string).
local function Variant(v, role)
    if type(v) ~= "table" then return v, nil end
    if v[role] then return v[role], role end
    if role == "ota" and v.cp then return v.cp, "cp" end
    if role ~= "zombie" and v.default then return v.default, "default" end
    return nil
end

local function Seen(ply)
    if not ply.lcHintSeen then
        local t = util.JSONToTable(ply:GetPData("lc_hints_seen", "") or "") or {}
        ply.lcHintSeen = {}
        for k, v in pairs(t) do
            if type(k) == "number" then ply.lcHintSeen[v] = true else ply.lcHintSeen[k] = true end
        end
    end
    return ply.lcHintSeen
end

local function SaveSeen(ply)
    local list = {}
    for k in pairs(Seen(ply)) do list[#list + 1] = k end
    table.sort(list)
    ply:SetPData("lc_hints_seen", util.TableToJSON(list))
end

function LC.HintsOff(ply) return ply:GetPData("lc_hints_off", "0") == "1" end

-- Would this player be shown this tip right now? Returns the text, title and
-- the key it's remembered by.
local function Due(ply, key)
    local def = LC.HINTS[key]
    if not def or not cvHints:GetBool() or not IsValid(ply) or not ply:IsPlayer() then return nil end
    if LC.HintsOff(ply) then return nil end
    local role = RoleOf(ply)
    local text, variant = Variant(def.text, role)
    if not text then return nil end
    local seenKey = variant and variant ~= "default" and (key .. "." .. variant) or key
    if def.every then
        local last = ply.lcHintLast and ply.lcHintLast[seenKey]
        if last and CurTime() - last < def.every then return nil end
    elseif Seen(ply)[seenKey] then
        return nil
    end
    if def.when and not def.when(ply) then return nil end
    return text, (Variant(def.title, role)) or "Tip", seenKey, def
end
LC.HintDue = function(ply, key) return Due(ply, key) ~= nil end

-- Show a tip, if this player hasn't had it. Returns true if it was sent.
function LC.Hint(ply, key)
    local text, title, seenKey, def = Due(ply, key)
    if not text then return false end
    local now = CurTime()
    local busy = ply.lcHintBusy or 0
    -- too many already waiting: hold this one back (it'll come up next time)
    if not def.urgent and busy - now > BACKLOG then return false end
    local dur = math.Clamp(8 + #text / 10, 14, 28) -- long enough to read without rushing
    ply.lcHintBusy = math.max(busy, now) + dur
    if def.every then
        ply.lcHintLast = ply.lcHintLast or {}
        ply.lcHintLast[seenKey] = now
    else
        Seen(ply)[seenKey] = true
        SaveSeen(ply)
    end
    ply.lcHintRecent = ply.lcHintRecent or {}
    table.insert(ply.lcHintRecent, { title = title, text = text })
    while #ply.lcHintRecent > 6 do table.remove(ply.lcHintRecent, 1) end
    LC.SendCompressed("lc_hint", { k = seenKey, t = title, x = text, u = def.urgent or nil, d = dur }, ply)
    return true
end

-- Every tip this player has had (and this session's recurring ones), with
-- what it said to them, for the "Tips I've seen" window.
util.AddNetworkString("lc_hints_seen")
function LC.SeenHints(ply)
    local out, done = {}, {}
    local role = RoleOf(ply)
    -- this session's, newest first
    local recent = ply.lcHintRecent or {}
    for i = #recent, 1, -1 do
        local r = recent[i]
        local key = r.title .. "|" .. r.text
        if not done[key] then done[key] = true out[#out + 1] = { t = r.title, x = r.text, now = true } end
    end
    -- and every other one they've had, by title
    local rest = {}
    for seenKey in pairs(Seen(ply)) do
        local key, variant = string.match(seenKey, "^([^%.]+)%.?(.*)$")
        local def = key and LC.HINTS[key]
        if def then
            local text = variant ~= "" and type(def.text) == "table" and def.text[variant] or (Variant(def.text, role))
            local title = (Variant(def.title, variant ~= "" and variant or role)) or (Variant(def.title, role)) or "Tip"
            if text and not done[title .. "|" .. text] then
                done[title .. "|" .. text] = true
                rest[#rest + 1] = { t = title, x = text }
            end
        end
    end
    table.sort(rest, function(a, b) return a.t < b.t end)
    for _, r in ipairs(rest) do out[#out + 1] = r end
    return out
end

function LC.SendSeenHints(ply)
    if not IsValid(ply) then return end
    LC.SendCompressed("lc_hints_seen", { list = LC.SeenHints(ply), off = LC.HintsOff(ply) }, { ply })
end

-- Free to show something: nothing on screen or about to be.
local function Idle(ply) return (ply.lcHintBusy or 0) < CurTime() + 1 end

------------------------------------------------------------------------
-- Looking around: what each player is near
------------------------------------------------------------------------

local FIREARMS = { weapon_pistol = true, weapon_357 = true, weapon_smg1 = true, weapon_ar2 = true, weapon_shotgun = true,
    weapon_crossbow = true, weapon_rpg = true }
local FIXTURE_CLASS = { lc_dispenser = "dispenser", lc_vending = "vending", lc_terminal = "terminal", lc_stove = "stove",
    lc_fire = "stove", lc_dealer = "dealer", lc_locker = "locker",
    lc_stall = "stall", lc_note = "note", lc_lawboard = "lawboard", lc_console = "console", lc_workbench = "workbench", lc_scientist = "workbench", lc_cpsupply = "cpsupply", lc_recycler = "recycler", lc_dataterminal = "dataterm", lc_masterterminal = "masterterm", lc_citybin = "bin", lc_incinerator = "incinerator", lc_transformer = "transformer", lc_forcefield = "forcefield", lc_powerbank = "powerbank", npc_turret_floor = "turret" }
local STATIC_KIND = { sink = "sink", stove = "stove", vending = "vending" }

-- Can this player see that spot? Walls in the way say no.
local function CanSee(ply, pos, range)
    local eye = ply:EyePos()
    if eye:DistToSqr(pos) > range * range then return false end
    local tr = util.TraceLine({ start = eye, endpos = pos, mask = MASK_OPAQUE, filter = ply })
    return not tr.Hit or tr.Fraction > 0.97
end
LC.HintCanSee = CanSee

local NEAR_KEYS = { "apartment", "stall", "note", "lawboard", "locker", "dispenser", "vending", "terminal", "stove", "dealer", "cache", "pot", "body", "bin", "sink", "incinerator", "recycler", "workbench", "cpsupply", "transformer", "forcefield", "powerbank", "turret" }
local PEOPLE_KEYS = { "unshackle", "quartermaster", "fighter", "citizen_npc", "cop_near", "birds", "headcrab", "stranger", "wanted_near" }
local FIRST = { "welcome", "intake_arrival", "intake_housing", "menus", "f_citizen", "f_resistance", "f_cp", "cp_tools", "f_vort", "f_freevort", "f_zombie", "ic_chat", "needs_intro", "quiet_hud", "acts_intro", "view_bob", "slots_intro", "help_staff" }

-- One look around for one player; shows at most one tip. Returns its key.
function LC.HintScan(ply)
    if not IsValid(ply) or not ply:Alive() or not cvHints:GetBool() or LC.HintsOff(ply) then return nil end
    local now = CurTime()
    local function Try(key) if LC.Hint(ply, key) then return key end end
    local pos = ply:GetPos()
    local role = RoleOf(ply)
    local downed = LC.IsDowned and LC.IsDowned(ply)
    local custody = LC.InCustody and LC.InCustody(ply)

    -- things that matter right now come first, even over a tip already showing
    if (ply:GetNW2Float("lc_trespass_until", 0) or 0) > now and Due(ply, "trespass") then return Try("trespass") end
    if ply:GetNW2Bool("lc_overweight", false) and Due(ply, "overweight") then return Try("overweight") end
    if role == "resistance" and LC.PassesAsCitizen and LC.PassesAsCitizen(ply) and Due(ply, "plainclothes_gun") then
        local w = ply:GetActiveWeapon()
        if IsValid(w) and FIREARMS[w:GetClass()] then return Try("plainclothes_gun") end
    end

    if not Idle(ply) or downed then return nil end

    -- someone down nearby
    if Due(ply, "downed_other") then
        for victim, d in pairs(LC.Downed or {}) do
            if victim ~= ply and IsValid(d.rag) and CanSee(ply, d.rag:GetPos() + Vector(0, 0, 10), 700) then
                return Try("downed_other")
            end
        end
    end

    -- the basics, a few seconds after arriving
    -- the getting-started tips, one every half minute, not all at once
    if now - (ply.lcHintSpawnT or 0) > 4 and now >= (ply.lcHintIntroNext or 0) then
        for _, k in ipairs(FIRST) do
            if Due(ply, k) then
                local sent = Try(k)
                if sent then ply.lcHintIntroNext = now + INTRO_GAP end
                return sent
            end
        end
    end

    if custody then return nil end

    -- how you're doing
    if Due(ply, "hurt") and ply:Health() < 35 then return Try("hurt") end
    if (Due(ply, "hungry") or Due(ply, "thirsty") or Due(ply, "parasites")) and not (LC.PlayerIsZombie and LC.PlayerIsZombie(ply))
        and ply:GetNW2String("lcf_faction", "") ~= "ota" then
        if LC.Hunger and LC.Hunger(ply) < 25 and Due(ply, "hungry") then return Try("hungry") end
        if LC.Thirst and LC.Thirst(ply) < 25 and Due(ply, "thirsty") then return Try("thirsty") end
        if LC.HasParasites and LC.HasParasites(ply) and Due(ply, "parasites") then return Try("parasites") end
    end
    if role == "citizen" and LC.Standing then
        local s = LC.Standing(ply)
        if s < 0 and Due(ply, "low_standing") then return Try("low_standing") end
        if s >= 100 and Due(ply, "cp_eligible") then return Try("cp_eligible") end
    end

    -- where you are
    local z = LC.ZoneAt and LC.ZoneAt(pos)
    if z then
        if z.kind == "rebel" and Due(ply, "zone_rebel") then return Try("zone_rebel") end
        if z.kind == "infest" and Due(ply, "zone_infest") then return Try("zone_infest") end
    end
    if Due(ply, "home_block") and LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) == true then return Try("home_block") end
    if ply:WaterLevel() >= 1 and Due(ply, "water") then return Try("water") end

    -- what you're holding
    local w = ply:GetActiveWeapon()
    if IsValid(w) and w:GetClass() == "weapon_lc_grenades" and Due(ply, "grenades") then return Try("grenades") end
    if IsValid(w) and w:GetClass() == "weapon_crowbar" and role ~= "cp" and Due(ply, "crowbar") then return Try("crowbar") end

    -- things within reach (only looked for while there's something left to tell)
    local eye = pos + Vector(0, 0, 40)
    local wantNear, wantPeople = false, false
    for _, k in ipairs(NEAR_KEYS) do if Due(ply, k) then wantNear = true break end end
    for _, k in ipairs(PEOPLE_KEYS) do if Due(ply, k) then wantPeople = true break end end
    for _, e in ipairs(wantNear and ents.FindInSphere(eye, 170) or {}) do
        if IsValid(e) and e ~= ply then
            local cls = e:GetClass()
            local k = FIXTURE_CLASS[cls]
            if k == "turret" and not e.lcTurret then k = nil end -- (a turret of the map's own, not a checkpoint's)
            if not k and e.lcRebelProp then k = e.lcRebelProp == "cache" and "cache" or (e.lcRebelProp == "pot" and "pot") or nil end
            if not k and e.lcBody and not e.lcBody.searched then k = "body" end
            if not k and LC.IsDoorEntity and LC.IsDoorEntity(e) and LC.GetDoorTag(e) == "rent" and not (LC.RentalOf and LC.RentalOf(e)) then k = "apartment" end
            if not k and not string.StartWith(cls, "lc_") and not e.lcQuest and not e.lcDressing then
                -- what a map prop is doesn't change: worked out once, from its model
                if e.lcHintKind == nil then
                    if LC.IsBinModel and LC.IsBinModel(e:GetModel()) then
                        e.lcHintKind = "bin"
                    elseif LC.FixtureKindOf then
                        e.lcHintKind = STATIC_KIND[LC.FixtureKindOf(e) or ""] or false
                    else
                        e.lcHintKind = false
                    end
                end
                k = e.lcHintKind or nil
            end
            if k and Due(ply, k) then return Try(k) end
        end
    end
    if Due(ply, "bin") then
        for _, b in ipairs(LC.StaticBins or {}) do
            if b.pos:DistToSqr(pos) < 150 * 150 then return Try("bin") end
        end
        if LC.BinPointAt and LC.BinPointAt(pos, 150) then return Try("bin") end
    end
    if LC.StaticFixtureNear then
        local fx = LC.StaticFixtureNear(eye, nil, 150)
        local k = fx and STATIC_KIND[fx.kind or ""]
        if k and Due(ply, k) then return Try(k) end
    end
    if LC.TagNear and Due(ply, "tag") then
        local t = LC.TagNear(pos, 250)
        if t and (not t.pos or CanSee(ply, t.pos, 250)) then return Try("tag") end
    end

    -- people and animals around you
    for _, e in ipairs(wantPeople and ents.FindInSphere(pos, 450) or {}) do
        if IsValid(e) and e ~= ply then
            local d2 = e:GetPos():DistToSqr(pos)
            local st = LC.NPCs and LC.NPCs[e]
            local wild = LC.Wildlife and LC.Wildlife[e]
            if st and e:Health() > 0 then
                if st.quartermaster and d2 < 250 * 250 and Due(ply, "quartermaster") then return Try("quartermaster") end
                if st.role == "rebel" and not st.quartermaster and d2 < 300 * 300 and Due(ply, "fighter") then return Try("fighter") end
                if st.role == "citizen" and d2 < 200 * 200 and Due(ply, "citizen_npc") then return Try("citizen_npc") end
                if st.role == "cop" and d2 < 350 * 350 and Due(ply, "cop_near") then return Try("cop_near") end
            elseif wild and e:Health() > 0 and d2 < 350 * 350 then
                local k = wild == "bird" and "birds" or "headcrab"
                if Due(ply, k) then return Try(k) end
            elseif e:IsPlayer() and e:Alive() and role == "resistance" and e:GetNW2String("lcf_faction", "") == "vort" and Due(ply, "unshackle") then
                return Try("unshackle")
            elseif e:IsPlayer() and e:Alive() then
                if d2 < 300 * 300 and Due(ply, "stranger") and not (LC.IsDowned and LC.IsDowned(e)) then return Try("stranger") end
                if role ~= "citizen" and role ~= "resistance" and LC.PlayerIsWanted and LC.PlayerIsWanted(e) and Due(ply, "wanted_near") then
                    return Try("wanted_near")
                end
            end
        end
    end
    return nil
end

-- A quarter of the players every quarter second: each is still looked at once
-- a second, but not all in the same tick.
local SLICES, slice = 4, 0
timer.Create("LivingCityHints", SCAN_EVERY / SLICES, 0, function()
    if not cvHints:GetBool() then return end
    slice = (slice + 1) % SLICES
    for i, ply in ipairs(player.GetAll()) do
        if i % SLICES == slice then
            local ok, err = pcall(LC.HintScan, ply)
            if not ok and LC.Error then LC.Error("hints", err) end
        end
    end
end)

hook.Add("PlayerSpawn", "LivingCityHints", function(ply) ply.lcHintSpawnT = CurTime() end)

------------------------------------------------------------------------
-- Things that happen
------------------------------------------------------------------------

local function IsPly(p) return IsValid(p) and p:IsPlayer() end
local function Everyone(key) for _, p in ipairs(player.GetAll()) do LC.Hint(p, key) end end

hook.Add("LivingCityDowned", "LivingCityHints", function(ply)
    if not IsPly(ply) then return end
    LC.Hint(ply, "downed_self")
    local d = LC.Downed and LC.Downed[ply]
    local at = (d and IsValid(d.rag) and d.rag:GetPos() or ply:GetPos()) + Vector(0, 0, 10)
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and not (LC.IsDowned and LC.IsDowned(p)) and CanSee(p, at, 900) then LC.Hint(p, "downed_other") end
    end
end)
hook.Add("LivingCityRevived", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "revived") end end)
hook.Add("LivingCityWanted", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "wanted") end end)
hook.Add("LivingCityAlert", "LivingCityHints", function(ply, level)
    if not IsPly(ply) then return end
    level = tonumber(level) or 0
    if level >= 3 then LC.Hint(ply, "alert3") elseif level >= 2 then LC.Hint(ply, "alert2") end
end)
hook.Add("LivingCityPlayerStopped", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "stopped") end end)
hook.Add("LivingCitySearched", "LivingCityHints", function(_, target) if IsPly(target) then LC.Hint(target, "searched") end end)
hook.Add("LivingCityScannerReport", "LivingCityHints", function(pilot, report)
    for _, p in ipairs(player.GetAll()) do
        if IsPly(p) and LC.PlayerIsCP and LC.PlayerIsCP(p) then LC.Hint(p, "scanreport") end
    end
    for _, e in ipairs(report and report.caught or {}) do
        if IsPly(e) then LC.Hint(e, "photographed") end
    end
end)
hook.Add("LivingCityInterrogation", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "interrogated") end end)
hook.Add("LivingCityCrippled", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "crippled") end end)
hook.Add("LivingCityStalker", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "stalker") end end)
hook.Add("LivingCityTraitor", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "traitor") end end)
hook.Add("LivingCityIncarcerated", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "jailed") end end)
hook.Add("LivingCityReleased", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "released") end end)
hook.Add("LivingCityEscaped", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "escaped") end end)
hook.Add("LivingCityCurfewWarning", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "curfew_warning") end end)
hook.Add("LivingCityDisguised", "LivingCityHints", function(ply, wear)
    if IsPly(ply) and wear and LC.HINTS["disguise_" .. wear] then LC.Hint(ply, "disguise_" .. wear) end
end)
hook.Add("LivingCityDisguiseBlown", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "disguise_blown") end end)
hook.Add("LivingCityStrike", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "strike") end end)
hook.Add("LivingCityNewCharacter", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "new_character") end end)
hook.Add("LivingCityRationCollected", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "ration") end end)
hook.Add("LivingCityCrafted", "LivingCityHints", function(ply, id)
    local it = LCS and LCS.Items and LCS.Items[id]
    if IsPly(ply) and it and it.arms then LC.Hint(ply, "crafted_arms") end
end)
hook.Add("LivingCityPromoted", "LivingCityHints", function(ply, faction, rank)
    if not IsPly(ply) then return end
    if faction == "resistance" and (tonumber(rank) or 0) >= 2 then LC.Hint(ply, "promoted_member") end
    LC.Hint(ply, "promoted")
end)

hook.Add("LivingCityDayPhase", "LivingCityHints", function(phase) if phase == "night" then Everyone("night") end end)
hook.Add("LivingCityWeather", "LivingCityHints", function(w) if w == "rain" or w == "storm" then Everyone("rain") end end)
hook.Add("LivingCityTied", "LivingCityHints", function(ply) if IsPly(ply) then LC.Hint(ply, "tied_self") end end)
hook.Add("LivingCitySocioChanged", "LivingCityHints", function(level)
    if level == "yellow" or level == "red" then Everyone("socio_" .. level) end
end)
hook.Add("LivingCityEventStarted", "LivingCityHints", function(name)
    if LC.HINTS["event_" .. tostring(name)] then Everyone("event_" .. name) end
end)
hook.Add("LivingCitySkirmish", "LivingCityHints", function(kind)
    if LC.HINTS["skirmish_" .. tostring(kind)] then Everyone("skirmish_" .. kind) end
end)
hook.Add("LivingCityOutbreak", "LivingCityHints", function() Everyone("outbreak") end)
hook.Add("LivingCityStateChanged", "LivingCityHints", function(name)
    if LC.HINTS["city_" .. tostring(name)] then Everyone("city_" .. name) end
end)

-- Something new in your pockets.
local function CheckPockets(ply)
    if not IsPly(ply) or not LC.Inventory then return end
    for id, n in pairs(LC.Inventory(ply)) do
        local k = (tonumber(n) or 0) > 0 and ITEM_HINTS[id]
        if k and Due(ply, k) then LC.Hint(ply, k) end
    end
end
LC.HintPockets = CheckPockets

hook.Add("LivingCityInventoryChanged", "LivingCityHints", function(ply)
    if not IsPly(ply) or ply.lcHintPocketsSoon then return end
    ply.lcHintPocketsSoon = true
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        ply.lcHintPocketsSoon = nil
        CheckPockets(ply)
    end)
end)
hook.Add("PlayerInitialSpawn", "LivingCityHintsPockets", function(ply)
    timer.Simple(90, function() if IsValid(ply) then CheckPockets(ply) end end)
end)

------------------------------------------------------------------------
-- !hints
------------------------------------------------------------------------

-- For chat, where nobody's binding can be looked up: the usual keys.
local DEFAULT_KEYS = { ["+use"] = "E", ["+reload"] = "R", ["+attack"] = "Left click", ["+attack2"] = "Right click",
    gm_showhelp = "F1", gm_showteam = "F2", gm_showspare1 = "F3", gm_showspare2 = "F4" }
local function Plain(text)
    return (string.gsub(text, "{([%w_%+]+)}", function(n) return DEFAULT_KEYS[n] and ("[" .. DEFAULT_KEYS[n] .. "]") or nil end))
end
LC.HintPlain = Plain

hook.Add("PlayerSay", "LivingCityHintsChat", function(ply, text)
    local t = string.lower(string.Trim(text or ""))
    local cmd, arg = string.match(t, "^!(%a+)%s*(%a*)$")
    if cmd ~= "hints" and cmd ~= "tips" then return end
    if arg == "off" then
        ply:SetPData("lc_hints_off", "1")
        ply:ChatPrint("[Tips] Off. Turn them back on from the full menu (C > Settings).")
    elseif arg == "on" then
        ply:SetPData("lc_hints_off", "0")
        ply:ChatPrint("[Tips] On. You'll see each one the first time it comes up.")
    elseif arg == "reset" then
        ply.lcHintSeen, ply.lcHintLast = {}, {}
        SaveSeen(ply)
        ply:SetPData("lc_hints_off", "0")
        ply:ChatPrint("[Tips] Reset. You'll see them all again, as things come up.")
    else
        local recent = ply.lcHintRecent or {}
        if #recent == 0 then
            ply:ChatPrint("[Tips] Nothing yet this session. F1 has the full guide.")
        else
            ply:ChatPrint("[Tips] The last few:")
            for _, r in ipairs(recent) do ply:ChatPrint("  " .. r.title .. ": " .. Plain(r.text)) end
        end
        ply:ChatPrint(LC.HintsOff(ply) and "[Tips] They're off. C > Settings turns them back on."
            or "[Tips] C > Tips I've seen has every one you've had; C > Settings turns them off, or starts them over.")
    end
    return ""
end)
