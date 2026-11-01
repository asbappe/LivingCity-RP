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
        text = "Welcome. The city keeps running even when you're not around. Tips like this one pop up the first time you run into something new. Press {gm_showhelp} for your quick menu: the nine things you'll do most, on the number keys (keys 6 to 8 change depending on what you're looking at). Press {+menu_context} for the full menu: everything you can do, with the guide at the top. You can turn these tips off in its Settings." },
    intake_arrival = { title = "First stop: Civil Intake", urgent = true, when = function(ply) return LC.IntakePending and LC.IntakePending(ply) end,
        text = { default = "You've just arrived in the city with no papers, no room and no ration card. Go to Civil Intake to register (an arrow on your screen shows the way): press {+use} on the terminal there and fill in your details. Until you register you can't get rations or Union work, and Civil Protection units will ask for papers you don't have." } },
    intake_housing = { title = "A room", when = function(ply) return LC.AwaitingHousing and LC.AwaitingHousing(ply) and not (LC.IntakePending and LC.IntakePending(ply)) end,
        text = { default = "You're registered, and your identity papers are in your pockets ({gm_showteam}). Next, get a room from Housing Allocation: press {+use} on its terminal, show your papers, pick a housing block, and stay next to the terminal while it searches. Until you have a room, wait near Civil Intake when a curfew starts: you're allowed to be there." } },
    menus = { title = "Your menus",
        text = { default = "{gm_showteam} opens your pockets (eat, drink, make things, give, wear). {gm_showspare1} opens jobs and quests. {gm_showspare2} shows your faction and rank.",
                 zombie = "{gm_showspare2} shows your faction. Zombies don't have pockets." } },
    f_citizen = { title = "You're a citizen",
        text = { citizen = "Pick a Union job on your job board ({gm_showspare1}) and work shifts to earn credits and Civil Standing. The higher your standing, the more the Commissary will sell you, and at 100 standing you can join Civil Protection." } },
    f_resistance = { title = "You're in the Resistance",
        text = { resistance = "You start in plain clothes, so Civil Protection units leave you alone unless they see a gun in your hand. To put on your Resistance gear, open {+menu_context} > Resistance > Gear up. Rebel territory is your home base: the quartermaster, the Resistance supply crate and the vegetable pots are there." } },
    f_vort = { title = "A shackled vortigaunt",
        text = { vort = "You belong to the Combine. You work the Union's shifts (job board, {gm_showspare1}), and your collar suppresses your vortessence (your powers). The Resistance can cut your shackles. Once you're free you can heal and attack with your powers, but Civil Protection units will hunt you." } },
    f_freevort = { title = "Free", when = function(ply) return ply:GetNW2String("lcf_special", "") == "vortigaunt" end,
        text = { resistance = "Your vortessence: {+attack} fires a bolt at whatever you're looking at, and {+attack2} heals whoever is in front of you, or yourself. Outside rebel territory, Civil Protection units go after you as soon as they see you." } },
    f_cp = { title = "Civil Protection",
        text = { ota = "You're Overwatch: the Combine's soldiers, not its police. Your operations are on {gm_showspare1}. When Civil Protection units call for backup, go and help them. In your quick menu ({gm_showhelp}), 1 is Call for backup and 2 sends your 10-20 (marks where you are for other units). The Civil Protection Commissary issues your ammunition and grenades ({gm_showteam} marks the way to it).",
                 cp = "Your Arrest Baton: {+attack} hits, {+attack2} arrests, {+reload} searches. Your directives (orders) are on {gm_showspare1}. Your quick menu ({gm_showhelp}) puts these on the number keys: call for backup, send your 10-20 (where you are), a BOLO (a lookout for someone), your mask's voice lines and the records terminal, plus search and cuff for whoever you're looking at. Everything else is in {+menu_context} > Unit tools. Get supplies at the Civil Protection Commissary ({gm_showteam} marks the way)." } },
    f_zombie = { title = "Infested",
        text = { zombie = "Your claws: {+attack} swipes, {+attack2} moans. The infestation zone is your home. You don't need to eat, and you never go down to bleed out: when your health runs out, you die." } },
    cp_tools = { title = "Your tools", when = function() local c = GetConVar("lc_cp_tools") return c and c:GetBool() end,
        text = { cp = "{+menu_context} > Unit tools has everything, with a note on what each one does: the records terminal (CIDs, violations, loyalty points, BOLOs and requests), your mask's voice lines, and actions for whoever you're looking at: search, cuff and drag (your quick menu, {gm_showhelp}, has the ones you use most). You don't queue for rations: your ration, ammunition and grenades are handed out at the Civil Protection Commissary ({gm_showteam} marks the way)." } },
    ic_chat = { title = "Talking", when = ICChat,
        text = { default = "Chat is spoken out loud: only people near you can hear it. In {+menu_context} > Talk you can yell, whisper, describe what you're doing or what's happening around you, or talk out of character (in chat: /y yells, /w whispers, /me and /it describe, // is out of character).",
                 zombie = "Chat is spoken out loud: only people near you can hear it. Start a message with // to talk out of character to everyone." } },
    help_staff = { title = "Need a hand?",
        text = { default = "To reach the staff, open {+menu_context} > Help > Ask staff for help (or type @ and then your message in chat). Use it for anything out of character: you're stuck, you have a rules question, or someone is breaking the rules." } },
    night = { title = "Night", when = function() local c = GetConVar("lc_atmosphere") return c and c:GetBool() end,
        text = { default = "From 21:00 to 05:00 it's night: the city goes dark and curfews happen three times as often. {+menu_context} > The city shows the current time.",
                 zombie = "It's night. The streets are darker, and most of the living stay indoors." } },
    rain = { title = "Rain", when = function() local c = GetConVar("lc_atmosphere") return c and c:GetBool() end,
        text = { default = "When it rains, it washes the blood off the streets (graffiti stays). Clean water comes from the vending machines and the taps; canal water needs boiling at a stove or a fire." } },
    acts_intro = { title = "Acting", when = function() local c = GetConVar("lc_acts") return c and c:GetBool() end,
        text = { default = "{+menu_context} > Me > Pose lets you sit, kneel, lie down or lean (move to stand back up). Me > Gesture: wave, salute, bow, nod and more. Me > Put my hands up raises your hands." } },
    slots_intro = { title = "More than one life", when = function() local c = GetConVar("lc_char_slots") return c and c:GetInt() > 1 end,
        text = { default = "You can have more than one character in the city. Go to {+menu_context} > Me > My characters to switch between them or make a new one." } },
    needs_intro = { title = "Hunger and thirst", when = Needs,
        text = { default = "Your hunger and thirst go down over time (the bars at the top left; with the quiet HUD, they only appear once they get low). Get rations from the ration dispensers, and water from vending machines and sinks. If either one reaches zero, you start dying.",
                 resistance = "Your hunger and thirst go down over time (the bars at the top left; with the quiet HUD, they only appear once they get low). The Resistance's supply crate in rebel territory gives you food; bins, fishing and the vegetable pots help too. If either one reaches zero, you start dying." } },
    quiet_hud = { title = "Where to find your numbers", when = function() local c = GetConVar("lc_quiet_hud") return c and c:GetBool() end,
        text = { default = "This server hides numbers on screen. Your credits and Civil Standing are shown at the top of your pockets ({gm_showteam}), and your rank and progress on {gm_showspare2}." } },
    view_bob = { title = "Camera sway", when = function() local c = GetConVar("lc_view_bob") return c and c:GetBool() end,
        text = { default = "The camera sways slightly as you walk and dips when you land. If that bothers you, turn it off in {+menu_context} > Settings > Camera sway (this only changes it for you)." } },

    -- what happens to you
    downed_self = { title = "You're down", urgent = true,
        text = "You're bleeding out, but you're not dead yet. Anyone can get you back up by pressing {+use} on you. While you're down you can only whisper. If nobody is coming, you can choose {+menu_context} > Me > Give up." },
    revived = { title = "Back on your feet",
        text = "You're back up, but badly hurt. Heal yourself with a bandage from your pockets ({gm_showteam}; you can make one from two rags), a medkit, or a medic." },
    wanted = { title = "You're wanted", urgent = true,
        text = { default = "Civil Protection units are coming to arrest you. Stay out of their sight and your wanted level drops over time. Or turn yourself in for half the sentence: walk up to a unit and press {+use} on them (or use {+menu_context} > Me > Give myself up).",
                 cp = "Civil Protection units can be wanted too. Stay out of sight and your wanted level drops over time, or press {+use} on another unit to turn yourself in." } },
    alert2 = { title = "Every Civil Protection unit is looking for you", urgent = true,
        text = "Units now have their pistols out. If your wanted level rises again, Overwatch soldiers are sent, and they shoot to kill instead of arresting you. Stay out of every Civil Protection unit's sight for 45 seconds to lower it (it drops faster in rebel territory)." },
    alert3 = { title = "Overwatch is coming", urgent = true,
        text = "A squad of Overwatch soldiers is hunting you, and they shoot to kill. Get out of their line of sight and stay hidden. Your wanted level drops twice as fast in rebel territory." },
    stopped = { title = "Stop and search", urgent = true,
        text = "A Civil Protection unit is searching you. Stand still (putting your hands up helps: {+menu_context} > Me). If you walk away, you'll be wanted for evading inspection. Anything illegal they find is taken from you." },
    tied_self = { title = "Your hands are cuffed", urgent = true,
        text = "You can't use anything, and you can only walk. Someone else can uncuff you. If nobody is around, try {+menu_context} > Me > Work at the cuffs to get free; if anyone sees you doing it, they tighten the cuffs." },
    socio_yellow = { title = "Sociostability: marginal",
        text = { default = "The city's alert level has gone up: Civil Protection units will stop and search more people on the street. Keep your papers ready and don't carry anything illegal. The current level is shown at the top of your screen.",
                 cp = "Units now stop 50% more people. The level shows on your mask's display, and officers can change it in {+menu_context} > Unit tools." } },
    socio_red = { title = "Judgment waiver", urgent = true,
        text = { default = "This is the city's highest alert level: Civil Protection units are allowed to kill whenever they see fit. Get indoors and stay out of sight until it ends.",
                 cp = "You may use lethal force at your own discretion, and units stop twice as many people. It ends when the city calms down, or when an officer ends it." } },
    searched = { title = "Searched",
        text = "Any contraband (illegal items) in your pockets will be found in a search. Your stash at home ({+menu_context} > Getting by) is never searched, but inspection sweeps sometimes raid it." },
    running = { title = "Don't run in front of Civil Protection units", urgent = true,
        text = "A Civil Protection unit told you to stop running. Stop within two seconds and nothing more happens. If you keep running, you'll be wanted for fleeing." },
    jailed = { title = "In custody",
        text = "Serve your sentence and you'll be let out at the release point. A friend can give you a lockpick (Give, in their pockets), and you can pick your cell door when no guard is looking, but escaping makes you wanted. If there's a Combine console in your cell, press {+use} on it to fly a city scanner while you wait." },
    released = { title = "Released",
        text = { default = "Your Civil Standing dropped because of your arrest. Community service jobs on your {gm_showspare1} board earn it back, and so does staying out of trouble." } },
    escaped = { title = "You're out", urgent = true,
        text = "You escaped, so you're wanted. Get out of sight. Spare clothes or a uniform will disguise you, and forged papers turn you into someone else." },
    curfew_warning = { title = "Get home", urgent = true,
        text = { default = "A Civil Protection unit has caught you outside after curfew. After three warnings you'll be wanted. The arrow on your HUD points to your housing block. A travel permit gets you past one curfew stop." } },
    disguise_cp = { title = "In a CP uniform",
        text = { default = "Civil Protection units on the street think you're one of them, for a while. Don't stay near real units, don't commit crimes, and don't let one search you. Most Combine doors will open for you." } },
    disguise_rebel = { title = "In Resistance gear",
        text = { default = "Resistance fighters think you're one of them, and Civil Protection units will shoot you on sight. If you stand close to a fighter, they may ask you questions you can't answer, and your cover is blown." } },
    disguise_citizen = { title = "In plain clothes",
        text = { default = "You look like an ordinary citizen. If a Civil Protection unit sees a gun in your hand, your disguise is blown. Never change clothes in front of a unit.",
                 cp = "You look like an ordinary citizen. Useful for undercover work: citizens talk more freely to you, and nobody salutes you." } },
    disguise_blown = { title = "Cover blown", urgent = true,
        text = "They've recognised you. Get away, and change clothes somewhere nobody can see you." },
    strike = { title = "Conduct strike", urgent = true,
        text = "That kill had no roleplay reason behind it. Two strikes sends you to prison, four gets you kicked from the server. Always give people a reason first: a warning, a demand, or a fight they started." },
    new_character = { title = "A new life",
        text = "Death is permanent here: your last character is gone for good. You have a new name and a new face, and nobody knows you. Getting shot puts you down to bleed out before you die, so next time someone may reach you and get you up in time." },
    promoted = { title = "Promoted",
        text = { default = "A new rank can unlock new gear, new jobs and more trust. {gm_showspare2} shows what your rank gives you access to.",
                 cp = "A new rank can unlock new gear: grenades are issued from the rank of Metrocop up. {gm_showspare2} shows what your rank gives you access to." } },
    promoted_member = { title = "A Resistance Member",
        text = { resistance = "Resistance fighters will follow you now: press {+use} on one in rebel territory to have them follow you (three at most). Press {+use} on them again to send them home." } },
    ration = { title = "A ration",
        text = "Eat it from your pockets ({gm_showteam}) when you're hungry. You get one ration per allocation, and allocations come twice as often during a ration distribution. If your Civil Standing is too low, you get nothing." },
    crafted_arms = { title = "Homemade arms",
        text = { default = "It counts as contraband while it's in your pockets, until you draw (equip) or load it ({gm_showteam}), and a search will find it. The black market dealer buys it, and the Resistance quartermaster pays 50% more." } },

    -- what happens around you
    event_rations = { title = "Ration distribution",
        text = { default = "Rations are handed out twice as often right now. Join a ration line and wait your turn, or press {+use} on a dispenser.",
                 cp = "Keep the ration lines in order. Citizens who crowd a Civil Protection unit get moved along." } },
    event_sweep = { title = "Inspection sweep",
        text = { default = "Civil Protection units are stopping and searching everyone. If you're carrying contraband, put it in your stash at home or stay off the streets.",
                 cp = "Stop and search citizens with your baton ({+reload}). Anything you confiscate earns you credits and XP." } },
    event_raid = { title = "Block raid",
        text = { default = "Civil Protection units are raiding a housing block: searching residents and taking any contraband left lying around. Whoever dropped it becomes wanted.",
                 cp = "A raid team is searching a housing block. Confiscated contraband is traced back to whoever owns it." } },
    event_curfew = { title = "Curfew",
        text = { default = "Curfew: go home. The arrow on your HUD points to your housing block, and you have a grace period to get there. After that, any Civil Protection unit who sees you outside gives you three warnings, then you're wanted.",
                 cp = "Citizens have a grace period to get home. After it ends, anyone still outside gets three warnings from a Civil Protection unit, then they're wanted." } },
    event_lockdown = { title = "Lockdown",
        text = { default = "Get inside your housing block now. Extra Civil Protection units are on the streets. Once the grace period ends, anyone outside gets three warnings, then they're wanted.",
                 cp = "Extra Civil Protection units are on the streets. Clear the streets: three warnings, then anyone still outside is wanted." } },
    skirmish_raid = { title = "A rebel raid",
        text = { default = "Resistance fighters are attacking a checkpoint, and the Civil Protection units nearby are fighting back. Keep your head down, or stay well away.",
                 resistance = "Resistance fighters are attacking a checkpoint. Join the fight, or stay hidden. Either way, it's being reported on the radio.",
                 cp = "Resistance fighters are attacking a checkpoint. In {+menu_context} > Unit tools, Call for backup sends units to you, and Send my 10-20 shows them where you are." } },
    skirmish_sweep = { title = "Civil Protection sweep into rebel territory",
        text = { default = "An armed Civil Protection team is going into rebel territory. Stay away from there.",
                 resistance = "An armed Civil Protection team is going into rebel territory, and the fighters are fighting back. Help the fighters, or get away from there.",
                 cp = "An armed team is sweeping rebel territory. Kills there win ground back from the Resistance." } },
    outbreak = { title = "Outbreak",
        text = { default = "The infestation has broken out: infected are in the nearby streets, and the area is in lockdown. Get indoors.",
                 cp = "The infected are loose in the streets near the infestation. Kill them and contain the outbreak.",
                 zombie = "The infestation has broken out. The streets are yours to roam, for now." } },
    city_unrest = { title = "The city is in unrest",
        text = { default = "The Resistance now holds enough of the city to cause unrest: expect more inspections and raids, fewer rations, and cheaper black market prices. See {+menu_context} > The city > Who holds the city." } },
    city_order = { title = "Full compliance",
        text = { default = "The Combine holds the whole city: neither the Resistance nor the infestation has spread. Expect fewer skirmishes and higher black market prices. See {+menu_context} > The city > Who holds the city." } },

    -- what's near you
    downed_other = { title = "Someone's down",
        text = { default = "They're bleeding out. Press {+use} on them to get them up (a bandage makes it faster). To pull them into cover, look at them and choose Drag them along in your quick menu ({gm_showhelp}). Shooting them kills them.",
                 cp = "They're bleeding out. Press {+use} on them to get them up; if they're wanted, {+use} cuffs them where they lie. To pull them along with you, choose Drag them along in your quick menu ({gm_showhelp}). Shooting them kills them." } },
    body = { title = "A body",
        text = { default = "Press {+use} on it and stay next to it for a few seconds to search it: you may find food, credits, ammunition, and sometimes clothes or a keycard. Don't do it where a Civil Protection unit can see you. You can also look at it and choose Haul the body in {gm_showhelp}: Morticians are paid to drag the dead to the incinerator.",
                 cp = "Press {+use} on it and stay next to it for a few seconds to search it. Dead rebels sometimes still carry their gear." } },
    bin = { title = "Bins",
        text = { citizen = "Press {+use} on a bin or dumpster to search it: you can find scrap, rags, tins, seeds and sometimes gun parts. While looking at one, you can hide things in it from your pockets ({gm_showteam}), but anyone can find them.",
                 resistance = "Press {+use} on a bin or dumpster to search it (bins in rebel territory have better finds). While looking at one, you can leave things in it from your pockets ({gm_showteam}) for someone else to collect: a dead drop." } },
    locker = { title = "A locker",
        text = { default = "Press {+use} to open it. Put something in it and it becomes yours, locked to everyone else. Civil Protection units can open any locker and confiscate anything illegal inside.",
                 cp = "Each locker belongs to whoever claimed it. Press {+use} to search one: you can confiscate contraband, and the owner becomes wanted." } },
    apartment = { title = "An apartment for rent",
        text = { default = "To rent it, look at the door and open {+menu_context} > This door > Rent it. It's a place of your own, locked to everyone except you and anyone you give a key to (look at them and open {+menu_context}). {+menu_context} > Home locks and unlocks it." } },
    stall = { title = "A market stall",
        text = { default = "Someone is selling things here. Press {+use} to see what's for sale and the prices.",
                 cp = "A licensed trader's stall. Press {+use} to search it. An officer can revoke the trader's license from the records terminal." } },
    note = { title = "Something written",
        text = { default = "A note or a notice. Press {+use} to read it; you can also take it with you.",
                 cp = "A note or a notice. Press {+use} to read it. Civil Protection units can tear notices down." } },
    lawboard = { title = "The city's laws",
        text = { default = "This board lists the city's laws. Press {+use} to read them, or read them anywhere in {+menu_context} > The city > The city's laws." } },
    overweight = { title = "Too much to carry", urgent = true,
        text = "You're carrying too much weight, so you move slower. Drop something, or carry a satchel so you can hold more." },
    water = { title = "Water",
        text = { default = "Press {+use} while standing in water to drink, but untreated water can give you parasites. You can fill empty bottles and cans here from your pockets ({gm_showteam}), then boil them before drinking. You can also fish here with a fishing line." },
        when = Needs },
    sink = { title = "A sink", when = Needs,
        text = { default = "Press {+use} to drink (there's a small chance of parasites). Fill empty bottles and cans here from your pockets ({gm_showteam}), then boil them before drinking." } },
    stove = { title = "Heat", when = Needs,
        text = { default = "Near a stove or fire, you can cook raw meat and fish and boil water from your pockets ({gm_showteam})." } },
    vending = { title = "Vending machine",
        text = { default = "Press {+use} to buy a can of Breen's Private Reserve. It quenches your thirst, and makes you a little dizzy.",
                 resistance = "Press {+use} to buy a can. Or, with a multitool: aim at the machine and fire, and after ten seconds it drops five to eight free cans. Don't do it where a Civil Protection unit can see you." } },
    dispenser = { title = "Ration dispenser",
        text = { default = "Press {+use} to get your ration. Each ration takes one ration card, and you earn a card for each Union shift you finish. You get one ration per allocation, and none if your Civil Standing is too low. A forged ration card gets you one anyway.",
                 resistance = "Press {+use} for your ration (it takes one ration card). Or, with a multitool: aim at the dispenser and fire, and after ten seconds it spits out five to eight ration packets, with no coupon and no record. Don't do it where a Civil Protection unit can see you.",
                 cp = "Citizens get one ration per allocation here. Civil Protection units don't queue for rations." } },
    event_supply = { title = "Supply drop",
        text = { default = "A crate of Union supplies has arrived at the loading dock. Anyone can press {+use} on it to take a load, but if a Civil Protection unit sees you there, you'll be warned and then wanted.",
                 resistance = "A Combine supply drop: guns, ammunition and medicine. Press {+use} on the crate to take a load. The Civil Protection units guarding it will fight you.",
                 cp = "Guard this supply drop: if anything is still in the crate when the convoy leaves, every Civil Protection unit nearby gets paid. The directive is on your board." } },
    item_jammer = { title = "A radio jammer",
        text = "Set it down from your pockets ({gm_showteam}). For four minutes, nearby Civil Protection radios are just static, request devices can't get through, and scanner photos never reach Civil Protection. It beeps, so units will come looking for it." },
    crowbar = { title = "A crowbar", urgent = true,
        text = "Hold it and press {+use} on junk (a wrecked car, a radiator, pipes, a crate) to pry scrap, rags and chemicals out of it. It's loud, and the nearest Civil Protection unit will come to check. It's also a weapon: if a unit sees it in your hand, you're wanted. Put it away when you're on the street." },
    interrogated = { title = "Interrogation", urgent = true,
        text = "You're being interrogated. Choose Talk (on screen, or in {gm_showhelp}) and the beating stops, but you give away a Resistance hideout, and if you're in the Resistance, your cell will know you talked. Or stay silent and take the beating: it won't kill you." },
    crippled = { title = "Broken feet", urgent = true,
        text = "You can't run until your feet heal (the time left is on your screen). Dying or leaving the server doesn't make them heal faster." },
    stalker = { title = "Combine property", urgent = true,
        text = "You've been turned into a stalker: slow, unarmed and unable to speak. Your job board has work orders for you. It ends when your sentence is served, or when you die." },
    traitor = { title = "Traitor", urgent = true,
        text = "A Resistance member saw you informing to Civil Protection. For half an hour, every Resistance member sees TRAITOR over your head, and their fighters will shoot you. Stay away from rebel territory." },
    dataterm = { title = "Combine data terminal",
        text = { default = "A Combine computer. You can't use it.",
                 resistance = "Only a Hacker can do this: aim the multitool at it, left click, and stay close for thirty seconds. Halfway through, the alarm goes off and a squad is sent. One terminal gives you a data fragment, which is half a chip: download from a second, different terminal and the two fragments make a whole data chip. You can sell the chip to the black market dealer, have the lab's scientist decode it (every Civil Protection unit is then marked for the whole Resistance to see), or plug it into a terminal to wipe your criminal record.",
                 cp = "A Combine data terminal. If the Resistance hack it, an alarm goes off: DATA BREACH." } },
    masterterm = { title = "The master terminal",
        text = { default = "The Combine's master terminal. You can't use it.",
                 resistance = "The biggest prize. Only a Hacker can do this: aim the multitool at it, left click, and stay with it for a full minute. A third of the way in, the alarm goes off and a bigger squad is sent. You get a master data core: the black market dealer pays a fortune for it, the quartermaster can decode it to mark every Civil Protection unit for ten minutes, and plugged into a terminal it wipes the criminal record of every Resistance member. The terminal can't be hacked again for an hour.",
                 cp = "The master terminal. If the Resistance hack it, every alarm in the nexus goes off." } },
    item_datashard = { title = "A data fragment",
        text = "Half of a data chip. Download data from a second, different terminal, and the two fragments combine into a whole chip. It's contraband: hide it." },
    item_masterchip = { title = "The master data core",
        text = "The biggest prize. It's contraband: hide it well. The black market dealer pays a fortune for it; the quartermaster can decode it to mark every Civil Protection unit for the whole Resistance for ten minutes; used at a terminal, it wipes the criminal records of every Resistance member in the city." },
    item_datachip = { title = "A Combine data chip",
        text = "It's contraband: hide it. The black market dealer pays well for it. The Resistance quartermaster can decode it (stand near him and Use it from your pockets): every Civil Protection unit is then marked for the whole Resistance for five minutes. Or use it at a terminal to wipe your own criminal record." },
    workbench = { title = "The lab",
        text = { resistance = "Your cell's lab. Press {+use} on the scientist: he makes guns, ammunition, armour, radio jammers, bypass charges and Freq 7 radios. Bring the materials and it's free, or pay him (cheaper than the black market). Stay in the lab while he works.",
                 cp = "A Resistance lab. Press {+use} on the scientist to shut it down: he's taken away, and nothing can be made here for a while.",
                 default = "A cluttered lab bench and a nervous scientist. He only works for the Resistance. Everyone else has to buy guns from the black market." } },
    transformer = { title = "Transformer",
        text = { default = "This transformer powers the district: streetlights, loudspeakers, screens, forcefields and Combine door locks. If it goes down, a Maintenance Technician can repair it by pressing {+use} on it.",
                 resistance = "This transformer powers the district, including the Combine door locks. A multitool shorts it out in twelve seconds: the lights go out and Combine doors open, until someone repairs it.",
                 cp = "This transformer powers the district, including our door locks and forcefields. Keep the Resistance away from it." } },
    forcefield = { title = "Combine forcefield",
        text = { default = "Civil Protection units can walk through it. Nobody else can, unless they swipe a Combine keycard ({+use}). It shuts off when the district's power goes out.",
                 resistance = "Civil Protection units can walk through it. A Combine keycard ({+use}) opens it for a moment, a multitool shorts it out for a minute, and it shuts off when the district's power goes out." } },
    powerbank = { title = "Combine power bank",
        text = { default = "Powers a checkpoint. The turrets and forcefields cabled to it run off it, and it gets its power from the district's transformer: if the transformer goes down, so do they.",
                 resistance = "Powers a checkpoint. A multitool (take it out, aim at the power bank and press {+attack}) shorts it out for two minutes, and every turret and forcefield connected to it shuts off. Near the infestation, this lets the infected break out.",
                 cp = "Your checkpoint's power supply. Deploy turrets near it ({+menu_context} > Civil Protection). Keep the Resistance away from it: if it goes down near the infestation, the infected break out." } },
    turret = { title = "Combine turret",
        text = { default = "It shoots the infected, wanted people and known rebels, and leaves everyone else alone. Its cable runs to the checkpoint's power bank.",
                 resistance = "If you're a known rebel, it shoots you on sight. Cut its power (the power bank, or the district's transformer) and it folds up and stops shooting.",
                 cp = "It shoots the infected and wanted people. Each Civil Protection unit can put up two ({+menu_context} > Civil Protection) and pack them up again with {+use}." } },
    incinerator = { title = "Incinerator",
        text = { default = "The city's dead bodies are brought here. Haul a body over (Morticians: press {+use} on a body; anyone else: look at it and choose Haul the body in {gm_showhelp}) and let go of it next to the incinerator, or press {+use} on the incinerator. Attendants are paid for each body.",
                 resistance = "The city's incinerator. A body burned here is never identified. To haul one over, look at it and choose Haul the body in {gm_showhelp}." } },
    recycler = { title = "Reclamation point",
        text = { default = "Press {+use} to hand in scrap, empty cans and bottles for a few credits and a little Civil Standing. The loyal citizen's way to get rid of junk.",
                 resistance = "Press {+use} to hand in scrap, cans and bottles for credits and Civil Standing. Or keep the scrap: your cell can make ammunition from it.",
                 cp = "Citizens hand in scrap here for credits and Civil Standing." } },
    console = { title = "Combine console",
        text = { default = "For prisoners and Civil Protection units: press {+use} to fly one of the city's scanners. Your body stays here. Left click takes a flash photo; if you flash a Civil Protection unit, your sentence gets longer. Get within about ten feet of rebels, free vortigaunts, wanted people or zombies and photograph them to earn Civil Standing (it never shortens your sentence). R disconnects.",
                 cp = "Press {+use} to fly a city scanner. Left click photographs anything within about ten feet: any rebels, free vortigaunts, wanted people and zombies it catches are highlighted for every Civil Protection unit." } },
    scanreport = { title = "Scanner report",
        text = "A scanner photographed someone. They're outlined in red for a minute, visible through walls, and rebel territory is marked on your screen. Go and catch them." },
    photographed = { title = "Photographed", urgent = true,
        text = "A scanner photographed you. For a minute, every Civil Protection unit can see where you are. Get out of sight, shoot the scanner down, or throw a smoke grenade: a scanner can't photograph anyone inside or behind smoke." },
    terminal = { title = "The Commissary",
        text = { default = "Press {+use} to shop. The higher your Civil Standing, the more it will sell you.",
                 cp = "Press {+use} to shop: ammunition, batteries and grenades for Civil Protection units. (A Civil Protection Commissary hands these out for free.)" } },
    cpsupply = { title = "Civil Protection Commissary",
        text = { cp = "Press {+use} to be issued supplies: grenades for your rank, ammunition for your weapons, armour, bandages and your ration. You can do this once every two minutes; in between, the unit counter there is open to buy extras.",
                 ota = "Press {+use} to be issued supplies: grenades, ammunition, armour, bandages and a ration. You can do this once every two minutes.",
                 default = "Civil Protection's supply point. Only Civil Protection units can use it." } },
    dealer = { title = "The black market",
        text = { default = "Press {+use} to trade: papers, uniforms, lockpicks, spray cans, seeds, gun parts. He buys almost anything. Don't let a Civil Protection unit see you trading with him.",
                 cp = "A black market dealer. Walk up to him to bust him: he disappears for 15 minutes, and you get paid." } },
    cache = { title = "A supply crate",
        text = { resistance = "The Resistance's food store: press {+use} to take a tin, once every four minutes. To add food from your pockets, use {+menu_context} > Resistance > Donate food.",
                 citizen = "A Resistance supply crate. You can add food from your pockets: {+menu_context} > Resistance > Donate food.",
                 cp = "A hidden stash of Resistance supplies. Press {+use} to confiscate all of it." } },
    pot = { title = "A pot",
        text = { default = "Press {+use} on it to plant a seed packet. In a few minutes it grows three lots of vegetables, and anyone can harvest a pot once it's ripe.",
                 cp = "A Resistance garden. Press {+use} to pull it up." } },
    tag = { title = "Graffiti",
        text = { citizen = "Resistance graffiti. Press {+use} on it to scrub it off and gain Civil Standing, or leave it.",
                 resistance = "The lambda, the Resistance's symbol. Spray cans (from the black market) put it on walls. Tags near rebel territory help the Resistance take more ground. Don't let a Civil Protection unit see you spraying.",
                 cp = "Press {+use} on a lambda tag to scrub it off and earn XP." } },
    quartermaster = { title = "The quartermaster",
        text = { resistance = "Press {+use} to trade. He sells the black market's stock to the Resistance, and pays 50% more for homemade guns and ammunition." } },
    fighter = { title = "Fighters",
        text = { resistance = "From the rank of Resistance Member up, press {+use} on a fighter to have them follow you and fight alongside you (three at most). Press {+use} on them again to send them home." } },
    citizen_npc = { title = "People",
        text = { default = "Everyone here has a name and a life. Press {+use} on someone to talk: they may tell you what they've heard or give you a bit of food, or you can pick their pocket. They remember how you treat them.",
                 cp = "With your baton out: {+use} stops a citizen, {+reload} searches them (sympathizers carry more), and {+attack2} detains them." } },
    cop_near = { title = "Civil Protection",
        text = { citizen = "Don't run in front of Civil Protection units and don't crowd around them. If one stops you, stand still until they're done.",
                 resistance = "Don't run in front of Civil Protection units and don't crowd around them. In plain clothes, keep your gun out of sight." } },
    wanted_near = { title = "Someone wanted",
        text = { cp = "Someone near you is wanted. Your baton's {+attack2} arrests them, and {+reload} searches them. If it turns violent, use {+menu_context} > Unit tools > Call for backup." } },
    unshackle = { title = "A shackled vortigaunt",
        text = { resistance = "From the rank of Member up, you can cut its shackles: look at it and choose {+menu_context} > Cut the vortigaunt's shackles (it takes ten seconds, and no Civil Protection unit can be watching). It then joins the Resistance." } },
    stranger = { title = "Strangers", when = ICChat,
        text = { default = "People don't know your name until you tell them. To introduce yourself, look at someone and choose {+menu_context} > Tell them my name (or show them your papers). Until then they see a description of you instead, which you can change in {+menu_context} > Me > Change how strangers see me." } },
    birds = { title = "Birds",
        text = { default = "One punch kills a bird. Cook it at a stove or burning barrel from your pockets ({gm_showteam})." } },
    headcrab = { title = "A headcrab",
        text = { default = "Weak, but don't turn your back on it. Several punches kill one, and it leaves meat you can cook. Don't go AFK in an alley." } },
    zone_rebel = { title = "Rebel territory",
        text = { citizen = "Resistance fighters leave citizens alone. The bins here have better finds, and the black market is open ({+menu_context} > Getting by). Stay out of any shooting.",
                 resistance = "Your home ground, among friends. The quartermaster, the supply crate and the vegetable pots are here, and you can make guns and ammunition here ({gm_showteam}).",
                 cp = "Resistance fighters shout one warning, then open fire. Only come in with a sweep or with backup. Kills here win ground back from the Resistance." } },
    zone_infest = { title = "The infestation",
        text = { default = "Zombies and headcrabs. There's nothing here worth the risk unless you have a reason to be here.",
                 cp = "Containment jobs on your board send Civil Protection units in here. Kills here push the infestation back.",
                 zombie = "Home." } },
    home_block = { title = "Your block",
        text = { default = "This is your housing block: come back here when a curfew starts. You can make things here ({gm_showteam}), and keep anything you don't want found in your stash ({+menu_context} > Getting by)." } },
    trespass = { title = "Combine only", urgent = true,
        text = "You're trespassing in a Combine-only area. Leave before the countdown on your screen runs out, or you'll be wanted." },
    plainclothes_gun = { title = "Careful", urgent = true,
        text = { resistance = "You're in plain clothes with a gun in your hand. If a Civil Protection unit sees it, your disguise is blown. Switch to your fists or holster the gun ({+menu_context} > Me)." } },
    grenades = { title = "Grenades",
        text = { cp = "{+attack} throws, {+reload} switches between smoke, flashbang and gas. Smoke hides you, a flashbang blinds people, and gas chokes anyone without a mask. Civil Protection units wear masks." } },

    -- how you're doing
    hungry = { title = "Hungry", every = 900, when = Needs,
        text = { default = "You're hungry. Eat something from your pockets ({gm_showteam}). No food? Try a ration dispenser, the Commissary, a bin, fishing, or something you can cook.",
                 resistance = "You're hungry. Eat something from your pockets ({gm_showteam}). No food? Try the supply crate in rebel territory, a bin, the vegetable pots, or fishing." } },
    thirsty = { title = "Thirsty", every = 900, when = Needs,
        text = { default = "You're thirsty. Drink something from your pockets ({gm_showteam}). Nothing to drink? Try a sink, a vending machine, or open water (boil it first if you can)." } },
    parasites = { title = "Parasites",
        text = { default = "You drank untreated water and caught parasites. You'll get hungry and thirsty faster, and keep coughing, until you take antiparasitic tablets (from the Commissary)." } },
    hurt = { title = "Hurt", every = 1200,
        text = { default = "You're hurt. Heal yourself with a bandage from your pockets ({gm_showteam}; two rags make one), a medkit, or a medic." } },
    low_standing = { title = "Low standing",
        text = { citizen = "Your Civil Standing is below zero: you get no rations, and Civil Protection units keep an eye on you. Community service jobs on your {gm_showspare1} board earn it back, and so does staying out of trouble." } },
    cp_eligible = { title = "You could join Civil Protection",
        text = { citizen = "Your Civil Standing is high enough to join Civil Protection. Open {gm_showspare2} to join." } },

    -- what's in your pockets
    item_seeds = { title = "Seeds",
        text = "Plant them in a pot in rebel territory: look at the pot and press {+use}. They grow into vegetables in a few minutes." },
    item_fishing = { title = "Fishing line",
        text = "Stand in the canal or look at the water, then choose Fish in your pockets ({gm_showteam}) or in {+menu_context} > Getting by, and keep still. Cook what you catch." },
    item_spray = { title = "A spray can",
        text = "Look at a wall and choose Spray in your pockets ({gm_showteam}) to paint the lambda (the Resistance symbol). If a Civil Protection unit sees you, you're wanted for vandalism." },
    item_lockpick = { title = "A lockpick",
        text = "Look at a locked door and choose {+menu_context} > This door > Pick the lock (or bind a key to lc_pick). It won't open Combine locks. You can also give one to a prisoner (from your pockets, {gm_showteam}) so they can pick their own cell door." },
    item_bypass = { title = "A bypass charge",
        text = "Opens any door once, Combine doors included: look at the door and choose {+menu_context} > This door > Pick the lock. It sometimes sets off an alarm, which makes you wanted." },
    item_keycard = { title = "A keycard",
        text = "Opens one Combine door, one time only: look at the door and choose {+menu_context} > This door > Pick the lock. Once used, it's reported stolen and won't work again." },
    item_raw = { title = "Raw meat",
        text = "Cook it near a stove, oven or burning barrel, from your pockets ({gm_showteam}). Eating it raw can give you parasites." },
    item_empty = { title = "An empty container",
        text = "Fill it in water or at a sink from your pockets ({gm_showteam}), then boil it near a stove or fire before you drink it." },
    item_dirty = { title = "Untreated water",
        text = "Boil it near a stove or fire first, from your pockets ({gm_showteam}). Drinking it unboiled can give you parasites." },
    item_clothes = { title = "Clothes",
        text = "Put them on from your pockets ({gm_showteam}) to look like an ordinary citizen. Never change clothes in front of a Civil Protection unit." },
    item_uniform = { title = "A CP uniform",
        text = "Put it on from your pockets ({gm_showteam}): Civil Protection units on the street will think you're one of them, for a while. It's contraband, so a search will find it." },
    item_gear = { title = "Resistance gear",
        text = "Put it on from your pockets ({gm_showteam}): Resistance fighters will think you're one of them. So will Civil Protection units, and they'll shoot you." },
    item_papers = { title = "Papers",
        text = "Use them from your pockets ({gm_showteam}) to become someone else. It also clears your wanted status, as long as no Civil Protection unit is watching." },
    item_blank = { title = "A blank identity form",
        text = "Forge it from your pockets ({gm_showteam}) somewhere private, where no Civil Protection unit can see you." },
    item_rationcard = { title = "A forged ration card",
        text = "Gets you one ration from any dispenser, whatever your Civil Standing and however recently you had one." },
    item_radio = { title = "An old radio",
        text = "Tuned to Freq 7, like every radio that isn't Civil Protection's. It's contraband: a search will find it." },
    item_radio_tuned = { title = "A radio, on Freq 7",
        text = "Freq 7 is the Resistance's secret channel, and you'll also hear what Civil Protection says when it thinks nobody's listening. With a radio transmitter too, {+menu_context} > Talk > On my radio talks on Freq 7. This radio is contraband." },
    item_permit = { title = "A travel permit",
        text = "Keep it in your pockets. It gets you past one curfew stop." },
    item_materials = { title = "Materials",
        text = "By hand, anywhere, from your pockets ({gm_showteam}): rags make bandages and scrap makes lockpicks. Guns, ammunition, smoke bombs and radio jammers are made from these by the Resistance lab's scientist, only for the Resistance. Everyone else buys them at the black market. Find more materials in bins, by prying junk apart with a crowbar, and on shot-down scanners." },
    item_papers = { title = "Your papers",
        text = "Your identity papers. Civil Protection units will ask to see them: look at the unit and choose Show them my papers in {gm_showhelp} (or Show in your pockets, {gm_showteam}). If you lose them, Civil Intake replaces them for a fee. Ration cards are different: you earn one for each Union shift you finish, and each ration takes one." },
    item_bandage = { title = "A bandage",
        text = "Use it from your pockets ({gm_showteam}) to heal yourself. Used on someone who's down, it gets them back up faster and with more health." },
    item_arms = { title = "Arms",
        text = "It counts as contraband until you draw (equip) or load it from your pockets ({gm_showteam}), and a search will find it. The black market buys it; the Resistance quartermaster pays more." },
    item_crate = { title = "Smuggled supplies",
        text = "These count as contraband in your pockets. Deliver them to where they're going without being stopped." },
    item_grenade = { title = "Something to throw",
        text = "Throw it from your pockets ({gm_showteam}). Smoke hides anyone inside it from both Civil Protection units and rebels." },
    item_tablets = { title = "Antiparasitic tablets",
        text = "Take them from your pockets ({gm_showteam}) to cure parasites from untreated water." },
    item_zipties = { title = "Cuffs",
        text = "To cuff someone, get up close, look at them and choose {+menu_context} > their name > Cuff them. It only works if their hands are up, they're down, they've been stopped by a Civil Protection unit, or you're behind them. Drag walks them along with you; Uncuff them lets them go." },
    item_request = { title = "A request device",
        text = "Type /request <what's wrong> to call Civil Protection to where you are. Civil Protection units see the request on their screens. You can send one once a minute, and false requests go on your record." },
    item_satchel = { title = "A satchel",
        text = "While you carry it, you can hold more: eight more kilos, and one more large item. Your pockets ({gm_showteam}) show how much you're carrying." },
    item_storage = { title = "A storage crate",
        text = "Set it down from your pockets ({gm_showteam}, Set down) and you can store things in it. Only you can open it, but Civil Protection units can open it too." },
    item_license = { title = "A business license",
        text = "While it's in your pockets, you can set down a market stall (sold at the Commissary) and sell things from it at your own prices. An officer can revoke the license." },
    item_stall = { title = "A market stall",
        text = "Set it down from your pockets ({gm_showteam}, Set down). Then look at it and Sell things from your pockets at the prices you choose. The money you make waits in the stall's till." },
    item_paper = { title = "Paper",
        text = "Write on it from your pockets ({gm_showteam}): leave it as a note, put it up on a wall as a poster, or keep it. You can sign it or leave it unsigned." },
    item_ring = { title = "A wedding ring",
        text = "It belonged to someone once. The black market pays well for it." },
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
    if LCF.IsOverwatch(ply) then return "ota" end
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
        and not LCF.IsOverwatch(ply) then
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
        ply:ChatPrint("[Tips] Tips are now off. Turn them back on in the full menu (C > Settings).")
    elseif arg == "on" then
        ply:SetPData("lc_hints_off", "0")
        ply:ChatPrint("[Tips] Tips are now on. Each tip shows the first time you run into something.")
    elseif arg == "reset" then
        ply.lcHintSeen, ply.lcHintLast = {}, {}
        SaveSeen(ply)
        ply:SetPData("lc_hints_off", "0")
        ply:ChatPrint("[Tips] Tips reset. You'll see every tip again as things come up.")
    else
        local recent = ply.lcHintRecent or {}
        if #recent == 0 then
            ply:ChatPrint("[Tips] No tips yet this session. The full guide is in C > Guide / manual.")
        else
            ply:ChatPrint("[Tips] Your last few tips:")
            for _, r in ipairs(recent) do ply:ChatPrint("  " .. r.title .. ": " .. Plain(r.text)) end
        end
        ply:ChatPrint(LC.HintsOff(ply) and "[Tips] Tips are off. Turn them back on in C > Settings."
            or "[Tips] C > Tips I've seen lists every tip you've had. C > Settings turns tips off or starts them over.")
    end
    return ""
end)
