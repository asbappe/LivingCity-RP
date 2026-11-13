--[[
    Items, Civil Standing tiers, the Union Commissary and the black market
    (shared config).

    Edit freely: item effects, prices, and what standing each purchase needs.
]]


LCS = LCS or {}

------------------------------------------------------------------------
-- Items you can carry (inventory: F3 or !inv)
--   hunger, thirst   how much they restore (0 to 100 scale)
--   parasite         chance of catching parasites when consumed
--   breen            Dr. Breen's Private Reserve side effects
--   leaves           item left in your pocket afterwards (the empty can)
--   cooksTo          what it becomes over a stove or fire
--   fillTo           what it becomes when filled from water
--   cures            status it removes
------------------------------------------------------------------------

local CAN = "models/props_junk/popcan01a.mdl"
local BOTTLE = "models/props_junk/garbage_glassbottle001a.mdl"

LCS.Items = {
    ration          = { name = "Ration packet", model = "models/weapons/w_package.mdl", hunger = 45, thirst = 15 },
    water           = { name = "Breen's Private Reserve", model = CAN, thirst = 40, breen = true, leaves = "can_empty" },
    bread           = { name = "Union bread", model = "models/props_junk/garbage_takeoutcarton001a.mdl", hunger = 30 },
    milk            = { name = "Milk", model = "models/props_junk/garbage_milkcarton001a.mdl", hunger = 10, thirst = 30 },
    melon           = { name = "Watermelon", model = "models/props_junk/watermelon01.mdl", hunger = 40, thirst = 40 },
    coffee          = { name = "Real coffee", model = "models/props_junk/garbage_coffeemug001a.mdl", hunger = 5, thirst = 25, uplift = true },
    tablets         = { name = "Antiparasitic tablets", model = "models/props_lab/jar01b.mdl", cures = "parasites" },
    dog_tags        = { name = "Dog tags", model = "models/props_lab/box01a.mdl", kg = 0.05, sell = 1,
                        desc = "A soldier's tags on a chain, a name scratched in by hand. Someone at the Resistance camp is looking for these" },
    medicine        = { name = "Union medicine", model = "models/healthvial.mdl", cures = "illness", sell = 4,
                        desc = "Cures a cold or a fever at once (sv_livingcity_illness.lua). Does nothing for parasites" },

    -- Cigarettes, alcohol and stimulants (sv_livingcity_vices.lua; the owner, 7 November). From your
    -- pockets: Smoke, Drink or Take. vice = what it does, strength = how much of it.
    cig_union       = { name = "Union cigarette", model = "models/props_lab/box01a.mdl", use = "vice", useLabel = "Smoke", vice = "smoke", strength = 1, kg = 0.01,
                        desc = "Union-approved tobacco, mostly. Steadies the nerves, takes the edge off hunger" },
    cig_rolled      = { name = "Hand-rolled cigarette", model = "models/props_lab/box01a.mdl", use = "vice", useLabel = "Smoke", vice = "smoke", strength = 2, kg = 0.01,
                        contraband = true, conceal = 0.8, desc = "Real tobacco from somewhere. Harsher than the Union's: more cough, more calm" },
    beer            = { name = "Homebrew beer", model = BOTTLE, use = "vice", useLabel = "Drink", vice = "drink", strength = 1, quench = 8, leaves = "bottle_empty",
                        contraband = true, conceal = 0.4, desc = "Brewed in a bathtub. A little drunk, a little less thirsty" },
    vodka           = { name = "Pre-war vodka", model = "models/props_junk/glassjug01.mdl", use = "vice", useLabel = "Drink", vice = "drink", strength = 2, quench = -6,
                        desc = "A Commissary privilege for exemplary citizens. Strong" },
    moonshine       = { name = "Moonshine", model = "models/props_junk/glassjug01.mdl", use = "vice", useLabel = "Drink", vice = "drink", strength = 3, quench = -10, badChance = 0.2,
                        contraband = true, conceal = 0.4, desc = "Very strong, very cheap, and one jar in five is a bad batch" },
    stimulant       = { name = "Stimulant shot", model = "models/props_lab/jar01a.mdl", use = "vice", useLabel = "Take", vice = "stim", kg = 0.05,
                        contraband = true, conceal = 0.7, desc = "Combine-issue, for units on double shifts. Fifteen minutes you couldn't sleep through if you tried: lights out waits, and tonight's dream goes by without you. Then the crash. One at a time: no second shot until you've slept and dreamt properly" },
    -- The lab's foil hat (the owner, 8 November; sv_livingcity_bedtime.lua): put it on and sleep in it, and no dream reaches you once.
    foil_hat        = { name = "Foil hat", model = "models/props_junk/PopCan01a.mdl", use = "foilhat", useLabel = "Put it on", kg = 0.05,
                        contraband = true, conceal = 0.5, desc = "A cap of foil, lined with copper wire. Sleep in it and it keeps the city's dream out, sometimes: about one night in three. The scientist mutters about field harmonics and thermodynamics; it is a tin foil hat. Spent come the dream either way" },

    -- Meat and fish, raw or cooked, go off after one city day (spoils = true; sv_livingcity_survival.lua,
    -- the owner, 7 November). A dead bird leaves its own kind: pigeon, crow or gull, all roast the same.
    raw_bird        = { name = "Raw pigeon", model = "models/pigeon.mdl", hunger = 10, parasite = 0.7, cooksTo = "cooked_bird", spoils = true },
    raw_crow        = { name = "Raw crow", model = "models/crow.mdl", hunger = 10, parasite = 0.7, cooksTo = "cooked_bird", spoils = true },
    raw_gull        = { name = "Raw gull", model = "models/seagull.mdl", hunger = 12, parasite = 0.7, cooksTo = "cooked_bird", spoils = true },
    cooked_bird     = { name = "Roast bird", model = "models/pigeon.mdl", hunger = 30, spoils = true },
    raw_headcrab    = { name = "Raw headcrab", model = "models/headcrabclassic.mdl", hunger = 15, parasite = 0.85, cooksTo = "cooked_headcrab", spoils = true },
    raw_fastcrab    = { name = "Raw fast headcrab", model = "models/headcrab.mdl", hunger = 12, parasite = 0.85, cooksTo = "cooked_headcrab", spoils = true },
    raw_poisoncrab  = { name = "Raw poison headcrab", model = "models/headcrabblack.mdl", hunger = 15, parasite = 0.9, poison = 45, cooksTo = "cooked_headcrab", spoils = true,
                        desc = "The venom's still in it. Cooking burns it out. Eating it raw will put you on the floor" },
    cooked_headcrab = { name = "Roast headcrab", model = "models/headcrabclassic.mdl", hunger = 40, spoils = true },

    can_empty       = { name = "Empty can", model = CAN, fillTo = "can_dirty" },
    can_dirty       = { name = "Can of untreated water", model = CAN, thirst = 30, parasite = 0.4, cooksTo = "can_clean", leaves = "can_empty" },
    can_clean       = { name = "Can of boiled water", model = CAN, thirst = 30, leaves = "can_empty" },
    bottle_empty    = { name = "Empty bottle", model = BOTTLE, fillTo = "bottle_dirty" },
    bottle_dirty    = { name = "Bottle of untreated water", model = BOTTLE, thirst = 45, parasite = 0.4, cooksTo = "bottle_clean", leaves = "bottle_empty" },
    bottle_clean    = { name = "Bottle of boiled water", model = BOTTLE, thirst = 45, leaves = "bottle_empty" },
    -- rain caught straight from the sky: clean enough as it is (no boiling)
    can_rain        = { name = "Can of rainwater", model = CAN, thirst = 30, leaves = "can_empty" },
    bottle_rain     = { name = "Bottle of rainwater", model = BOTTLE, thirst = 45, leaves = "bottle_empty" },

    ------------------------------------------------------------------------
    -- Your own papers (sv_livingcity_intake.lua): Civil Intake issues them
    -- when you register, and replaces them (for a fee) if you lose them.
    --   doc   one of your documents: weighs nothing, takes no room, and
    --         can't be dropped or handed over (stashing them is up to you)
    ------------------------------------------------------------------------
    id_papers       = { name = "Identity papers", model = "models/props_c17/paper01.mdl", doc = true, kg = 0, sell = 0,
                        use = "papers", useLabel = "Show",
                        desc = "Your name, your citizen number, your block. Show: to whoever you're looking at (Civil Protection units ask), or read them yourself" },
    pamphlet        = { name = "Civil Orientation pamphlet", model = "models/props_c17/paper01.mdl", kg = 0, sell = 1,
                        use = "pamphlet", useLabel = "Read",
                        desc = "Handed to every new arrival at Civil Intake: rations, work, housing, papers, curfew, the law. Read: from your pockets, any time" },
    ration_card     = { name = "Ration card", model = "models/props_c17/paper01.mdl", doc = true, kg = 0, sell = 0,
                        desc = "Earned by work: one for each Union shift you finish. A ration dispenser takes one card for each ration" },
    -- (the owner, 7 November: units no longer get ration packets out of thin air; their duty allocation is a voucher,
    -- for a packet at a Civil Protection Commissary or a ration dispenser: sv_livingcity_cp.lua, sv_livingcity_cpsupply.lua)
    ration_voucher  = { name = "Ration voucher", model = "models/props_c17/paper01.mdl", doc = true, kg = 0, sell = 0,
                        desc = "A Civil Protection unit's duty allocation. Take it to a Civil Protection Commissary or a ration dispenser for a ration packet" },
    ------------------------------------------------------------------------
    -- Things that change what you can do (see sv_livingcity_underground.lua)
    --   contraband   illegal to carry: searches look for it
    --   conceal      base chance it slips past a search (Guile adds to it)
    --   sell         what the dealer pays for it
    --   radio        "union" (public band, early event notices) or
    --                "resistance" (Freq 7, plus intercepted CP dispatch)
    --   permit       excuses you from one curfew or lockdown stop
    --   papers       "forged" or "dead": assume a new identity, which clears
    --                your wanted status and passes inspections (mostly)
    --   forge        turn it into forged papers somewhere private (Guile check)
    --   rationCard   a free ration from any dispenser, whatever your standing
    --   wear         a disguise: "cp" fools security NPCs and opens CP doors,
    --                "citizen" lets hunted Resistance pass as ordinary citizens
    --   tool         "lockpick" for locked doors, "bypass" for Combine doors too
    ------------------------------------------------------------------------
    -- (1 November, the owner: every radio that isn't Civil Protection's is a Freq 7 radio. This old one,
    -- the Union radio, can't be had any more: one still in someone's pockets becomes a Freq 7 radio,
    -- sv_livingcity_underground.lua)
    radio           = { name = "Old radio", model = "models/props_lab/citizenradio.mdl", radio = "resistance", contraband = true, conceal = 0.25, sell = 12, use = "listen", useLabel = "Listen",
                        desc = "Tuned to Freq 7, like every radio that isn't Civil Protection's. Contraband" },
    radio_tuned     = { name = "Radio", model = "models/props_lab/citizenradio.mdl", radio = "resistance", use = "listen", useLabel = "Listen",
                        contraband = true, conceal = 0.25, sell = 20,
                        desc = "Tuned to Freq 7, the Resistance's: their chat, sweep warnings, and whatever Civil Protection says when it thinks nobody is listening. It only listens: to talk on Freq 7 you also need a radio transmitter" },
    radio_transmitter = { name = "Radio transmitter", model = "models/props_lab/reciever01a.mdl", contraband = true, conceal = 0.35, sell = 25,
                        desc = "A hand-held set that sends, not just listens: with a Freq 7 radio, talk on Freq 7 (switch to it like a weapon, or !r). Contraband (units have their own, on the CP net)" },
    permit          = { name = "Travel permit", model = "models/props_c17/paper01.mdl", permit = true,
                        desc = "Stamped and legal. Gets you past one curfew stop" },
    papers_blank    = { name = "Blank identity form", model = "models/props_c17/paper01.mdl", forge = true,
                        contraband = true, conceal = 0.6, sell = 10,
                        desc = "Fill it in somewhere private and it becomes somebody" },
    papers_forged   = { name = "Forged papers", model = "models/props_c17/paper01.mdl", papers = "forged",
                        contraband = true, conceal = 0.5, sell = 30,
                        desc = "A new name. Clears your wanted status if no Civil Protection unit is watching" },
    papers_dead     = { name = "A dead man's papers", model = "models/props_c17/paper01.mdl", papers = "dead",
                        contraband = true, conceal = 0.5, sell = 25,
                        desc = "Genuine papers. Their owner won't be needing them" },
    ration_forged   = { name = "Forged ration card", model = "models/props_c17/paper01.mdl", rationCard = true,
                        contraband = true, conceal = 0.65, sell = 4,
                        desc = "One extra ration from any dispenser, whatever your standing" },
    uniform_cp      = { name = "Civil Protection uniform", model = "models/props_c17/BriefCase001a.mdl", wear = "cp",
                        contraband = true, conceal = 0, sell = 50,
                        desc = "Mask and all. Civil Protection units on the street will take you for one of them, mostly" },
    cwu_overalls    = { name = "Union work overalls", model = "models/props_c17/suitcase_passenger_physics.mdl", wear = "citizen", sell = 6,
                        desc = "Union-issue, a little worn. Lets anyone pass as an ordinary citizen" },
    rebel_gear      = { name = "Resistance gear", model = "models/props_c17/BriefCase001a.mdl", wear = "rebel",
                        contraband = true, conceal = 0.15, sell = 25,
                        desc = "Off a dead fighter. The fighters in rebel territory will take you for one of them. Civil Protection units will too" },
    uniform_clean   = { name = "Clean uniform", model = "models/props_c17/BriefCase001a.mdl",
                        desc = "A fresh Civil Protection uniform, pressed and bagged, for when yours is past saving (put it on: F1 > What now? > Change into clean clothes)" },
    civvies         = { name = "Spare citizen clothes", model = "models/props_c17/suitcase_passenger_physics.mdl", wear = "citizen",
                        desc = "Union blue. Lets a hunted Resistance member pass as an ordinary citizen" },
    lockpick        = { name = "Lockpick set", model = "models/props_c17/tools_wrench01a.mdl", tool = "lockpick",
                        contraband = true, conceal = 0.55, sell = 10,
                        desc = "Look at a locked door and use it. Not Combine locks" },
    bypass          = { name = "Combine bypass charge", model = "models/props_lab/reciever01b.mdl", tool = "bypass",
                        contraband = true, conceal = 0.35, sell = 25,
                        desc = "One use. Look at a Combine door (or any locked door) up close and use it from your pockets: four seconds, and the lock gives. The door opens for half a minute, and for the first ten seconds it's held open whatever else works it. Now and then it trips an alarm, and a unit who sees you reports you" },
    gas_bomb        = { name = "Poison gas bomb", model = "models/props_junk/popcan01a.mdl", use = "throw", useLabel = "Throw", grenade = "poison",
                        contraband = true, conceal = 0.45, sell = 25,
                        desc = "Combine issue: weedkiller gas in a can, a green cloud that chokes and poisons, worse than chlorine. A unit's mask keeps it out (while its filter's good)" },
    firebomb        = { name = "Firebomb", model = "models/props_junk/garbage_glassbottle001a.mdl", use = "throw", useLabel = "Throw", grenade = "fire",
                        contraband = true, conceal = 0.5, sell = 25,
                        desc = "Weedkiller, cooked down, in a bottle with a rag. Armour doesn't keep out fire: it burns whoever's in it, burns out Combine machinery, and burns the infestation's growths away" },
    ration_short    = { name = "Short ration", model = "models/weapons/w_package.mdl", hunger = 31, thirst = 10,
                        desc = "A ration packet, cut by a third: what the Union gives a citizen who hasn't earned more (Trusted citizens get the full ration)" },
    weedkiller      = { name = "Weedkiller", model = "models/props_junk/garbage_plasticbottle001a.mdl", use = "poison", useLabel = "Poison food or drink",
                        desc = "For the weeds in the cracks and the infestation's growths (look at one, E). A few drops in someone's food or drink, and it's for them. A barnacle that eats it dies" },
    transfer_order  = { name = "Transfer order", model = "models/props_c17/paper01.mdl", contraband = true, conceal = 0.8, kg = 0,
                        desc = "Forged: a prisoner to be moved, stamped and signed. It passes a glance, not a close look" },
    door_code       = { name = "A Combine door code", model = "models/props_c17/paper01.mdl", tool = "keycard", kg = 0,
                        contraband = true, conceal = 0.8, sell = 25,
                        desc = "Seen by the vortigaunts through the vortessence, scratched on a scrap: opens one Combine door before the code is changed" },
    cp_keycard      = { name = "Civil Protection keycard", model = "models/props_c17/paper01.mdl", tool = "keycard",
                        contraband = true, conceal = 0.45, sell = 30,
                        desc = "Off a dead Civil Protection unit. Opens one Combine door before someone reports it missing" },
    ------------------------------------------------------------------------
    -- Getting by (sv_livingcity_scavenge.lua)
    --   use      what "Use" does from your pockets: "fish", "plant", "spray"
    ------------------------------------------------------------------------
    canned_food     = { name = "Canned beans", model = "models/props_junk/garbage_metalcan001a.mdl", hunger = 35, leaves = "can_empty",
                        desc = "Pre-war. The label's gone. Probably beans" },
    vegetables      = { name = "Rooftop vegetables", model = "models/props_junk/garbage_takeoutcarton001a.mdl", hunger = 25, thirst = 10,
                        desc = "Grown in a pot on a roof somewhere. Real food" },
    -- (Half-Life 2 has no fish model: the raw one is the bugbait pod, tinted grey in lc_item.lua, a fish
    -- of a kind; the fried one comes wrapped in a takeout carton. Change the paths here for a real fish model.)
    raw_fish        = { name = "Raw fish", model = "models/weapons/w_bugbait.mdl", hunger = 15, parasite = 0.5, cooksTo = "cooked_fish", spoils = true,
                        desc = "From the canal. Cook it. Really, cook it" },
    cooked_fish     = { name = "Fried fish", model = "models/props_junk/garbage_takeoutcarton001a.mdl", hunger = 35, spoils = true },
    seeds           = { name = "Seed packet", model = "models/props_lab/box01a.mdl", use = "plant", useLabel = "Plant",
                        desc = "Plant them in a pot in rebel territory (look at it and press E, or Plant here)" },
    fishing_line    = { name = "Fishing line", model = "models/props_lab/box01a.mdl", use = "fish", useLabel = "Fish",
                        desc = "Stand in the canal, or look at the water, and wait. Good for four to eight casts, then it snaps" },
    spraypaint      = { name = "Spray can", model = "models/props_junk/popcan01a.mdl", use = "spray", useLabel = "Spray",
                        contraband = true, conceal = 0.5, sell = 4,
                        desc = "Look at a wall and spray the lambda or another mark of ours, or at one of the city's posters to paint over it. Don't let a Civil Protection unit see you do it" },
    -- (a Resistance poster to paste on a wall: Paste in sv_livingcity_scavenge.lua, entities/lc_civposter.lua)
    pasteup         = { name = "Resistance paste-up", model = "models/props_c17/paper01.mdl", use = "pasteup", useLabel = "Paste it up",
                        contraband = true, conceal = 0.5, sell = 3,
                        desc = "A hand-painted Resistance poster and a dab of glue. Look at a bare wall, up close, and paste it up. Don't let a Civil Protection unit see you do it" },
    -- (a Resistance pamphlet to read, hand over or leave lying about: sv_livingcity_rebelpamphlet.lua)
    rebel_pamphlet  = { name = "Resistance pamphlet", model = "models/props_c17/paper01.mdl", kg = 0, use = "rebelpamphlet", useLabel = "Read",
                        contraband = true, conceal = 0.8, sell = 1,
                        desc = "A cheap sheet run off by hand, the ink still purple. Read it, hand it to someone who might listen, or leave it where it will be found. Don't let a Civil Protection unit see you do it" },
    ------------------------------------------------------------------------
    -- Making things (sv_livingcity_crafting.lua)
    --   arms     weapons and ammunition: the quartermaster pays half as much again
    --   use      "heal", "ammo" (ammo = { type, amount }), "arm" (weapon = class),
    --            "throw" (grenade = smoke, flash or gas)
    ------------------------------------------------------------------------
    cloth           = { name = "Rags", model = "models/props_junk/garbage_newspaper001a.mdl", sell = 1, desc = "Clean enough for a bandage" },
    chemicals       = { name = "Cleaning chemicals", model = "models/props_junk/garbage_plasticbottle001a.mdl", sell = 3,
                        desc = "Union-issue. Mixed with the right things, they do more than clean" },
    gun_parts       = { name = "Gun parts", model = "models/props_lab/box01a.mdl", contraband = true, conceal = 0.4, sell = 12,
                        desc = "Springs, a barrel, a firing pin. Off a dead Civil Protection unit, or out of a smuggler's crate" },
    -- (a unit's daily issue, kept in the pockets until wanted: the owner, 11 November, it fell on the floor at full health)
    health_vial     = { name = "Health vial", model = "models/healthvial.mdl", use = "heal", useLabel = "Use it", heal = 10,
                        desc = "Ten health, at once" },
    bandage         = { name = "Bandage", model = "models/props_junk/garbage_newspaper001a.mdl", use = "heal", useLabel = "Patch up", heal = 20,
                        desc = "Twenty health, give or take" },
    ammo_pistol     = { name = "Box of pistol rounds", model = "models/items/boxsrounds.mdl", use = "ammo", useLabel = "Load", ammo = { "Pistol", 18 },
                        contraband = true, conceal = 0.35, sell = 15, arms = true, desc = "Hand-loaded. Mostly reliable" },
    ammo_smg        = { name = "Box of SMG rounds", model = "models/items/boxmrounds.mdl", use = "ammo", useLabel = "Load", ammo = { "SMG1", 45 },
                        contraband = true, conceal = 0.3, sell = 25, arms = true, desc = "Hand-loaded" },
    ammo_buckshot   = { name = "Box of shells", model = "models/items/boxbuckshot.mdl", use = "ammo", useLabel = "Load", ammo = { "Buckshot", 12 },
                        contraband = true, conceal = 0.3, sell = 20, arms = true, desc = "Hand-packed shells" },
    gun_pistol      = { name = "Pistol", model = "models/weapons/w_pistol.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_pistol",
                        contraband = true, conceal = 0.25, sell = 45, arms = true, desc = "Put together on a kitchen table. It fires" },
    gun_shotgun     = { name = "Shotgun", model = "models/weapons/w_shotgun.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_shotgun",
                        contraband = true, conceal = 0.05, sell = 80, arms = true, desc = "Hard to hide. Hard to argue with" },
    gun_smg         = { name = "SMG", model = "models/weapons/w_smg1.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_smg1",
                        contraband = true, conceal = 0.1, sell = 75, arms = true, desc = "It jams. Not often" },
    smokebomb       = { name = "Smoke bomb", model = "models/props_junk/popcan01a.mdl", use = "throw", useLabel = "Throw", grenade = "smoke",
                        contraband = true, conceal = 0.5, sell = 8, desc = "A can of chemicals and a fuse. Thick white smoke" },
    gren_smoke      = { name = "Smoke grenade", model = "models/weapons/w_grenade.mdl", use = "throw", useLabel = "Throw", grenade = "smoke",
                        contraband = true, conceal = 0.3, sell = 15, desc = "Civil Protection issue. Nobody sees through it" },
    gren_flash      = { name = "Flashbang", model = "models/weapons/w_grenade.mdl", use = "throw", useLabel = "Throw", grenade = "flash",
                        contraband = true, conceal = 0.3, sell = 20, desc = "Blinds and deafens anyone who sees it go off" },
    gren_gas        = { name = "Chlorine gas grenade", model = "models/weapons/w_grenade.mdl", use = "throw", useLabel = "Throw", grenade = "gas",
                        contraband = true, conceal = 0.3, sell = 30, desc = "A choking green cloud. Masks protect; nothing else does" },
    arms_crate      = { name = "Smuggled crate", model = "models/items/item_item_crate.mdl", contraband = true, conceal = 0.1, sell = 1,
                        desc = "Heavy, and it clinks. Get it where it's going" },
    smuggled_supplies = { name = "Smuggled supplies", model = "models/items/boxsrounds.mdl", contraband = true, conceal = 0.25, sell = 1,
                        desc = "Guns and parts wrapped in rags, out of a broken crate. Get them where they're going" },
    ------------------------------------------------------------------------
    -- Order (sv_livingcity_cp.lua)
    ------------------------------------------------------------------------
    zipties         = { name = "Cuffs", model = "models/props_lab/box01a.mdl", sell = 1, -- (1, not 4: a unit's own never run out)
                        desc = "Tie someone's hands: up close, looking at them, C > their name > Cuff them. Only someone with their hands up, knocked down, stopped by a unit, or taken from behind. Cuffed, they can't use anything; Drag walks them along, Uncuff lets them go. Units carry their own" },
    request_device  = { name = "Civil Protection call box", model = "models/props_lab/reciever01b.mdl", sell = 6,
                        desc = "A little handset that calls Civil Protection to where you are and tells them what's wrong: Call for help, beside it in your pockets (F3), or C > Getting by > Request Civil Protection" },
    ------------------------------------------------------------------------
    -- Carrying and keeping things (sv_livingcity_storage.lua)
    --   bag      extra kilograms and large things you can carry while you have it
    --   place    "crate": set down in the world as your own lockable crate
    ------------------------------------------------------------------------
    satchel         = { name = "Satchel", model = "models/props_c17/BriefCase001a.mdl", bag = { kg = 8, bulky = 1 }, sell = 10,
                        desc = "A canvas bag over the shoulder. Room for more, and for something large" },
    -- hand-made goods to sell from a stall (sv_livingcity_employment.lua): worth is what the city's people will pay
    rag_doll        = { name = "Rag doll", model = "models/props_c17/doll01.mdl", handmade = true, worth = 18, sell = 4, desc = "Sewn from rags. Children still want toys." },
    tin_toy         = { name = "Tin toy", model = "models/props_junk/garbage_metalcan001a.mdl", handmade = true, worth = 20, sell = 5, desc = "A little wind-up soldier, hammered from cans." },
    patched_coat    = { name = "Patched coat", model = "models/props_c17/SuitCase_Passenger_Physics.mdl", handmade = true, worth = 32, sell = 8, desc = "Warm, ugly, and better than the Union's." },
    -- status (sv_livingcity_status.lua, the owner, 10 November): things other people can see
    fine_clothes    = { name = "Fine clothes", model = "models/props_c17/SuitCase001a.mdl", use = "finery", useLabel = "Put on / take off", sell = 40,
                        desc = "A good coat and a clean collar. People notice." },
    decor_cactus    = { name = "Potted cactus", model = "models/props_lab/cactus.mdl", use = "decor", useLabel = "Place it at home", sell = 6, desc = "Something alive on the windowsill." },
    decor_lamp      = { name = "Desk lamp", model = "models/props_c17/lamp001a.mdl", use = "decor", useLabel = "Place it at home", sell = 8, desc = "A warm light of your own." },
    decor_chair     = { name = "Armchair", model = "models/props_c17/FurnitureChair001a.mdl", use = "decor", useLabel = "Place it at home", sell = 12, desc = "Somewhere to sit that isn't the floor." },
    decor_frame     = { name = "Picture frame", model = "models/props_lab/frame002a.mdl", use = "decor", useLabel = "Place it at home", sell = 10, desc = "A photograph from before. Or a portrait of the Administrator, to be safe." },
    radio_set       = { name = "Radio set", model = "models/props_lab/citizenradio.mdl", use = "decor", useLabel = "Place it at home", sell = 25,
                        desc = "A wireless for the home. Press E on it to play music; again to stop." },
    pet_bird        = { name = "Pet bird", model = "models/pigeon.mdl", use = "petbird", useLabel = "On my shoulder / off", sell = 30,
                        desc = "A tame pigeon that rides on your shoulder. A luxury in this city." },
    storage_crate   = { name = "Storage crate", model = "models/props_junk/wood_crate001a.mdl", place = "crate", sell = 12,
                        desc = "Set it down somewhere (Set down, in your pockets) and it's yours: only you can open it. Civil Protection units can" },
    ------------------------------------------------------------------------
    -- Trade and writing (sv_livingcity_business.lua, sv_livingcity_writing.lua)
    ------------------------------------------------------------------------
    business_license = { name = "CWU business license", model = "models/props_c17/paper01.mdl", license = true, sell = 1,
                        desc = "Stamped by the Civil Workers' Union. Lets you set up a market stall and trade. Officers can revoke it" },
    vendor_stall    = { name = "Market stall", model = "models/props_c17/FurnitureTable001a.mdl", place = "stall", sell = 15,
                        desc = "A folding table and a sign. Set it down (with a license) and sell from it: you set the prices" },
    paper           = { name = "Paper", model = "models/props_c17/paper01.mdl", use = "write", useLabel = "Write",
                        desc = "Write a note to leave somewhere, a poster to put up, or one to keep" },
    scrap           = { name = "Scrap metal", model = "models/props_junk/garbage_metalcan002a.mdl", sell = 3,
                        desc = "Out of bins, junk and downed scanners. The dealer pays for it, and so does reclamation" },
    crowbar         = { name = "Crowbar", model = "models/weapons/w_crowbar.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_crowbar",
                        contraband = true, conceal = 0.05, sell = 14, desc = "Pries scrap out of junk. A weapon too, and every Civil Protection unit knows it" },
    data_chip       = { name = "Combine data chip", model = "models/props_lab/harddrive02.mdl", use = "datachip", useLabel = "Decode / plug in",
                        contraband = true, conceal = 0.3, sell = 130,
                        desc = "Two terminals' data, put together. The dealer pays well; the lab decodes it; plugged into a terminal it wipes your record" },
    data_shard      = { name = "Combine data fragment", model = "models/props_lab/harddrive01.mdl",
                        contraband = true, conceal = 0.35, sell = 40,
                        desc = "Half of what the Combine know: one terminal's data. Download another terminal's and the two make a whole chip" },
    master_chip     = { name = "Master data core", model = "models/props_lab/harddrive02.mdl", use = "datachip", useLabel = "Decode / plug in",
                        contraband = true, conceal = 0.2, sell = 400,
                        desc = "Out of the Combine's master terminal: the motherlode. The dealer pays a fortune; the quartermaster's decoding marks every Civil Protection unit for ten minutes; plugged into a terminal it wipes every comrade's record" },
    jammer          = { name = "Radio jammer", model = "models/props_lab/reciever01b.mdl", use = "jammer", useLabel = "Set down",
                        contraband = true, conceal = 0.3, sell = 35, desc = "Set it down: four minutes of static on every Civil Protection unit radio nearby, and no scanner photos get out" },
    armor_vest      = { name = "Powered vest", model = "models/props_c17/SuitCase001a.mdl", use = "armor", useLabel = "Put on", armor = 30,
                        contraband = true, conceal = 0.15, sell = 30, desc = "Plates and salvaged charge cells: holds a charge (75), comes with thirty in it. Charge cells (the lab's, or off a dead unit or a downed scanner) top it up, and a vortigaunt will if you ask" },
    -- the Resistance's money (sv_livingcity_funding.lua): intel only the quartermaster buys, and
    -- parts skimmed off the factory line
    freq7_sheet     = { name = "Freq 7 sheet", model = "models/props_c17/paper01.mdl", kg = 0, contraband = true, conceal = 0.85, sell = 6,
                        use = "read", useLabel = "Read",
                        desc = "Copied down at a radio repair bench: the rule, and the seven places on the dial Freq 7 hides. Pass it on, or burn it" },
    intel_patrol    = { name = "Notes on a patrol", model = "models/props_c17/paper01.mdl", kg = 0, contraband = true, conceal = 0.9, sell = 20, intel = true,
                        desc = "A unit's beat, written down: where he walks, and when. The quartermaster pays for it" },
    intel_checkpoint = { name = "Notes on a checkpoint", model = "models/props_c17/paper01.mdl", kg = 0, contraband = true, conceal = 0.9, sell = 25, intel = true,
                        desc = "A checkpoint's shifts, its gate, its men. The quartermaster pays for it" },
    intel_nexus     = { name = "Notes on the Combine's ground", model = "models/props_c17/paper01.mdl", kg = 0, contraband = true, conceal = 0.9, sell = 35, intel = true,
                        desc = "The approaches to the Combine's own ground. The quartermaster pays well for it" },
    intel_records   = { name = "Copied city records", model = "models/props_c17/paper01.mdl", kg = 0, contraband = true, conceal = 0.85, sell = 60, intel = true,
                        desc = "The city's own records, copied out by someone inside: names, routes, who's being watched. The best intel there is" },
    union_goods     = { name = "Union machine parts", model = "models/props_lab/box01a.mdl", contraband = true, conceal = 0.4, sell = 8, arms = true,
                        desc = "Finished parts, skimmed off the factory line. The dealer moves them; the quartermaster pays more (they end up in guns)" },
    vest_cell       = { name = "Charge cell", model = "models/items/battery.mdl", use = "charge", useLabel = "Charge your vest", charge = 25,
                        contraband = true, conceal = 0.5, sell = 8, desc = "A salvaged suit cell: twenty-five charge into a powered vest you're wearing" },
    ammo_357        = { name = "Box of .357 rounds", model = "models/items/357ammo.mdl", use = "ammo", useLabel = "Load", ammo = { "357", 6 },
                        contraband = true, conceal = 0.4, sell = 20, arms = true, desc = "Six heavy rounds, hand-loaded" },
    gun_357         = { name = "Revolver", model = "models/weapons/w_357.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_357",
                        contraband = true, conceal = 0.2, sell = 90, arms = true, desc = "Machined at a workbench. Loud, heavy, final" },
    keepsake        = { name = "Wedding ring", model = "models/props_lab/box01a.mdl", sell = 20,
                        desc = "It belonged to somebody" },
}

------------------------------------------------------------------------
-- Weight and size (lc_inventory_weight 1): kilograms, and whether it's a
-- large thing (bulky) that only so many of fit about your person.
-- Anything not listed weighs half a kilo. Set `kg` or `bulky` on an item to
-- override.
------------------------------------------------------------------------

-- Tainted with weedkiller (sv_livingcity_weeds.lua): every food and drink has a twin that looks exactly
-- the same, in the pockets and to whoever's given it, and poisons whoever eats or drinks it.
do
    local add = {}
    for id, it in pairs(LCS.Items) do
        if (it.hunger or it.thirst) and not it.cooksTo and not string.find(id, "^raw_") then
            local t = table.Copy and table.Copy(it) or {}
            if not table.Copy then for k, v in pairs(it) do t[k] = v end end
            t.poison, t.tainted, t.parasite = 40, true, nil
            add["tainted_" .. id] = t
        end
    end
    for id, t in pairs(add) do LCS.Items[id] = t end
end

LCS.Weights = {
    beer = 0.6, vodka = 0.9, moonshine = 0.9,
    ration = 0.3, water = 0.4, bread = 0.5, milk = 0.6, melon = 3.0, coffee = 0.3, tablets = 0.05, medicine = 0.1,
    raw_bird = 0.6, raw_crow = 0.6, raw_gull = 0.7, cooked_bird = 0.5, raw_headcrab = 1.2, raw_fastcrab = 1.0, raw_poisoncrab = 1.4, cooked_headcrab = 1.0,
    can_empty = 0.05, can_dirty = 0.4, can_clean = 0.4, bottle_empty = 0.3, bottle_dirty = 0.8, bottle_clean = 0.8,
    radio = 1.0, radio_tuned = 1.0, radio_transmitter = 0.6, permit = 0.02, papers_blank = 0.02, papers_forged = 0.02, papers_dead = 0.02, ration_forged = 0.02,
    uniform_cp = 3.0, cwu_overalls = 1.2, rebel_gear = 3.0, civvies = 1.0,
    lockpick = 0.1, bypass = 0.6, cp_keycard = 0.02, canned_food = 0.5, vegetables = 0.6, raw_fish = 0.7, cooked_fish = 0.6,
    seeds = 0.05, fishing_line = 0.2, spraypaint = 0.4, pasteup = 0.1, cloth = 0.2, chemicals = 0.8, gun_parts = 1.0, bandage = 0.1,
    ammo_pistol = 0.4, ammo_smg = 0.8, ammo_buckshot = 0.7, gun_pistol = 1.1, gun_shotgun = 3.4, gun_smg = 2.8,
    smokebomb = 0.4, gas_bomb = 0.4, firebomb = 0.6, ration_short = 0.3, gren_smoke = 0.5, gren_flash = 0.5, gren_gas = 0.6, arms_crate = 9.0, smuggled_supplies = 2.5, data_shard = 0.3, master_chip = 0.6, zipties = 0.05,
    request_device = 0.3, scrap = 0.5, keepsake = 0.01, satchel = 0.8, storage_crate = 6.0,
    business_license = 0.02, vendor_stall = 7.0, paper = 0.02,
    rag_doll = 0.3, tin_toy = 0.3, patched_coat = 1.5,
    fine_clothes = 1.5, decor_cactus = 1.0, decor_lamp = 1.5, decor_chair = 6.0, decor_frame = 0.5, radio_set = 3.0, pet_bird = 0.3, -- (sv_livingcity_status.lua)
}
-- (a tainted twin weighs what the real thing does: sv_livingcity_weeds.lua)
for id, it in pairs(LCS.Items) do
    if it.tainted then
        local real = string.sub(id, 9)
        if LCS.Weights[real] then LCS.Weights[id] = LCS.Weights[real] end
    end
end
LCS.Bulky = { melon = true, uniform_cp = true, rebel_gear = true, gun_shotgun = true, gun_smg = true, arms_crate = true, storage_crate = true, vendor_stall = true, decor_chair = true }

function LCS.Weight(id)
    local it = LCS.Items[id]
    return (it and it.kg) or LCS.Weights[id] or 0.5
end

function LCS.IsBulky(id)
    local it = LCS.Items[id]
    if it and it.bulky ~= nil then return it.bulky end
    return LCS.Bulky[id] == true
end

------------------------------------------------------------------------
-- Civil Standing tiers
------------------------------------------------------------------------

LCS.Tiers = {
    { min = -1e9, name = "Anticitizen", color = Color(220, 60, 60) },
    { min = -50, name = "Probationary", color = Color(225, 150, 80) },
    { min = 0, name = "Citizen", color = Color(200, 200, 200) },
    { min = 150, name = "Trusted", color = Color(120, 205, 140) },
    { min = 400, name = "Exemplary", color = Color(120, 170, 255) },
}

function LCS.TierFor(standing)
    local t = LCS.Tiers[1]
    for _, x in ipairs(LCS.Tiers) do if standing >= x.min then t = x end end
    return t
end

------------------------------------------------------------------------
-- The Union Commissary
--   item      goes into your inventory
--   entity    spawns in front of you (health vials, batteries)
--   ammo      { type, amount }
--   civOnly   never offered to units (citizen clothes: the owner, 1 November)
--   cpOnly    units only, and sold only at the Civil Protection Commissary's
--             counter (the Union terminal sells them only in a city without one)
------------------------------------------------------------------------

LCS.Goods = {
    { id = "ration", item = "ration", price = 15, minStanding = -50, desc = "Nutrient bar and a little water. It keeps you alive." },
    { id = "water", item = "water", price = 2, minStanding = -50, desc = "Clean, cold, refreshing. Do not ask what is in it." },
    { id = "bottle", item = "bottle_empty", price = 2, minStanding = -50, desc = "An empty glass bottle, for whatever water you can find." },
    { id = "tablets", item = "tablets", price = 15, minStanding = -50, desc = "For what the canal water gives you." },
    { id = "medicine", item = "medicine", price = 12, minStanding = -50, desc = "For a cold or a fever. Take it as directed." },
    { id = "civvies", item = "civvies", price = 10, minStanding = -50, civOnly = true, desc = "Union-issue work clothes. Everyone looks the same in them." },
    { id = "weedkiller", item = "weedkiller", price = 15, minStanding = 0, desc = "For the weeds in the cracks. Keep it away from food." },
    { id = "permit", item = "permit", price = 35, minStanding = 150, desc = "One night out after curfew, stamped and legal." },
    { id = "bread", item = "bread", price = 15, minStanding = 0, desc = "Grey, dense, and real." },
    { id = "milk", item = "milk", price = 15, minStanding = 0, desc = "Powdered, reconstituted, nearly milk." },
    { id = "healthvial", name = "Health vial", entity = "item_healthvial", price = 25, minStanding = 150, desc = "For the trusted." },
    { id = "melon", item = "melon", price = 25, minStanding = 400, desc = "A whole watermelon. Exemplary citizens only." },
    { id = "coffee", item = "coffee", price = 30, minStanding = 400, desc = "Real coffee. You'd forgotten the smell." },
    { id = "cig_union", item = "cig_union", count = 5, name = "Union cigarettes (5)", price = 12, minStanding = 75, civOnly = true, desc = "A pack of five. Union-approved. Mildly." },
    { id = "vodka", item = "vodka", price = 45, minStanding = 150, civOnly = true, desc = "Pre-war vodka. For citizens the Union is proud of." },
    { id = "healthkit", name = "Medical kit", entity = "item_healthkit", price = 50, minStanding = 400, desc = "A full medical kit." },
    { id = "request_device", item = "request_device", price = 10, minStanding = 0, desc = "Something wrong? It calls Civil Protection to where you are." },
    -- (no spare cuffs for sale: a unit's own never run out, and it read as though they had to buy them; the owner, 1 November)
    { id = "paper", item = "paper", count = 3, name = "Paper (3)", price = 2, minStanding = -50, desc = "For notes, letters and notices." },
    { id = "business_license", item = "business_license", price = 75, minStanding = 50, desc = "The Union's permission to trade from a stall." },
    { id = "vendor_stall", item = "vendor_stall", price = 60, minStanding = 50, desc = "Everything you need to sell. A license not included." },
    { id = "satchel", item = "satchel", price = 25, minStanding = -50, desc = "Carry more. Eight more kilos, and one more large thing." },
    -- things other people can see (sv_livingcity_status.lua)
    { id = "fine_clothes", item = "fine_clothes", price = 120, minStanding = 150, civOnly = true, desc = "A good coat and a clean collar. For citizens the Union trusts." },
    { id = "decor_cactus", item = "decor_cactus", price = 20, minStanding = 25, civOnly = true, desc = "For the home. Place it from your pockets, in your block." },
    { id = "decor_lamp", item = "decor_lamp", price = 25, minStanding = 25, civOnly = true, desc = "For the home. Place it from your pockets, in your block." },
    { id = "decor_frame", item = "decor_frame", price = 30, minStanding = 50, civOnly = true, desc = "For the home. Place it from your pockets, in your block." },
    { id = "decor_chair", item = "decor_chair", price = 35, minStanding = 50, civOnly = true, desc = "For the home. Place it from your pockets, in your block." },
    { id = "radio_set", item = "radio_set", price = 60, minStanding = 75, civOnly = true, desc = "A wireless for the home: music, Union-approved." },
    { id = "pet_bird", item = "pet_bird", price = 80, minStanding = 100, civOnly = true, desc = "A tame pigeon for your shoulder. Everyone will want one." },
    { id = "storage_crate", item = "storage_crate", price = 40, minStanding = 0, desc = "Somewhere of your own to keep things. Civil Protection units can open it." },
    { id = "fishing_line", item = "fishing_line", price = 15, minStanding = -50, civOnly = true, desc = "Line and a hook. The canal has fish, of a kind." },
    { id = "gren_smoke", item = "gren_smoke", price = 20, cpOnly = true, desc = "Cover for an advance, or a retreat." },
    { id = "gren_flash", item = "gren_flash", price = 35, cpOnly = true, minRank = 2, desc = "Metrocops and up. Don't look at it." },
    { id = "gren_gas", item = "gren_gas", price = 60, cpOnly = true, minRank = 3, desc = "Division Leaders and the Overwatch. For clearing anticitizen holdouts." },
    { id = "gas_bomb", item = "gas_bomb", price = 40, cpOnly = true, minRank = 3, desc = "Division Leaders and the Overwatch. Weedkiller gas: worse than chlorine, and your mask keeps it out." },
    { id = "uniform_clean", item = "uniform_clean", price = 5, cpOnly = true, desc = "A clean uniform, for when yours is past saving. It happens to the best of us." },
    { id = "pistolammo", name = "Pistol ammunition", ammo = { "Pistol", 36 }, price = 10, cpOnly = true, desc = "Standard issue." },
    { id = "smgammo", name = "SMG ammunition", ammo = { "SMG1", 90 }, price = 20, cpOnly = true, minStanding = 150, desc = "For Civil Protection units in good standing." },
    { id = "battery", name = "Suit battery", entity = "item_battery", price = 30, cpOnly = true, desc = "Armor recharge." },
}

LCS.GoodsById = {}
for _, g in ipairs(LCS.Goods) do
    g.name = g.name or (g.item and LCS.Items[g.item] and LCS.Items[g.item].name) or g.id
    LCS.GoodsById[g.id] = g
end

------------------------------------------------------------------------
-- The black market (a dealer placed with the editor, or rebel territory)
--   weapon    given straight to you
--   qm        only the Resistance's quartermaster has it, never a dealer
-- Standing doesn't matter here. Credits do. Units who walk up to a dealer
-- don't buy anything: they bust it.
------------------------------------------------------------------------

LCS.Black = {
    { id = "radio_tuned", item = "radio_tuned", price = 60, desc = "Already tuned to Freq 7." },
    { id = "papers_forged", item = "papers_forged", price = 80, desc = "Good work. Not perfect work." },
    { id = "papers_blank", item = "papers_blank", price = 30, desc = "For people with a steady hand." },
    { id = "ration_forged", item = "ration_forged", price = 10, desc = "One more meal than the Union thinks you deserve." },
    { id = "lockpick", item = "lockpick", price = 35, desc = "Picks, tension wrench, patience not included." },
    { id = "bypass", item = "bypass", price = 70, desc = "One use: opens a Combine door (or any locked door), holds it open ten seconds, open for thirty. Can trip an alarm. Don't ask where it came from." },
    { id = "civvies", item = "civvies", price = 15, desc = "Clean, plain, forgettable." },
    { id = "uniform_cp", item = "uniform_cp", price = 160, desc = "Off a Civil Protection unit who won't be needing it." },
    { id = "tablets", item = "tablets", price = 20, desc = "No questions about why you need them." },
    { id = "medicine", item = "medicine", price = 18, desc = "Fell off a Commissary truck." },
    { id = "cig_rolled", item = "cig_rolled", count = 5, name = "Hand-rolled cigarettes (5)", price = 10, desc = "Real tobacco. Don't ask from where." },
    { id = "beer", item = "beer", price = 8, desc = "Bathtub beer. It's wet, and it works." },
    { id = "moonshine", item = "moonshine", price = 10, desc = "Strong enough to strip paint. Mostly safe." },
    { id = "vodka_black", item = "vodka", price = 70, desc = "Pre-war vodka, for people the Union isn't proud of." },
    { id = "stimulant", item = "stimulant", price = 40, stock = "stim", desc = "Stolen from a Civil Protection depot, a few at a time. Keeps you up past lights out, and the night's dream goes by without you." }, -- (40 and a limited supply: the owner, 8 November)
    { id = "crowbar", name = "Crowbar", weapon = "weapon_crowbar", price = 50, desc = "Every revolution starts somewhere." },
    { id = "multitool", name = "Multitool", weapon = "weapon_lc_multitool", price = 250, desc = "Opens Combine locks, screens and terminals. Very illegal. Don't get searched." },
    { id = "gun_parts", item = "gun_parts", price = 18, desc = "Springs, barrels, pins. Make something with them." },
    { id = "chemicals", item = "chemicals", price = 6, desc = "Bought by the bottle. Nobody cleans that much." },
    { id = "seeds", item = "seeds", price = 12, desc = "Tomatoes, beans, maybe. Plant them in rebel territory." },
    { id = "canned_food", item = "canned_food", price = 14, desc = "Pre-war tins. Nobody asks where they come from." },
    { id = "zipties", item = "zipties", count = 2, name = "Cuffs (2)", price = 20, desc = "Two pairs. Tie anyone's hands, a Civil Protection unit's included: up close, looking at them, C > their name > Cuff them. They must have their hands up, be down, be stopped by a unit, or you come from behind. Cuffed, they can't use anything, and Drag walks them along." },
    { id = "satchel", item = "satchel", price = 30, desc = "No questions about what goes in it." },
    { id = "spraypaint", item = "spraypaint", count = 3, name = "Spray cans (3)", price = 25, desc = "Let the city know we're still here." },
    { id = "pasteup", item = "pasteup", count = 3, name = "Paste-ups (3)", price = 20, desc = "Their walls, our words.", qm = true }, -- (the owner, 10 November: the dealer isn't Resistance)
    { id = "rebel_pamphlet", item = "rebel_pamphlet", count = 5, name = "Pamphlets (5)", price = 15, desc = "Read this. Then pass it on.", qm = true },
    -- what the Resistance's lab makes (sv_livingcity_lab.lua); everyone else pays the dealer for it
    { id = "smokebomb", item = "smokebomb", price = 30, desc = "Chemicals in a can, and a fuse." },
    { id = "ammo_pistol", item = "ammo_pistol", price = 40, desc = "Eighteen rounds. Hand-loaded, mostly reliable." },
    { id = "ammo_buckshot", item = "ammo_buckshot", price = 55, desc = "Twelve shells." },
    { id = "ammo_smg", item = "ammo_smg", price = 65, desc = "Forty-five rounds." },
    { id = "ammo_357", item = "ammo_357", price = 55, desc = "Six heavy rounds." },
    { id = "gun_pistol", item = "gun_pistol", price = 120, desc = "Put together on somebody's kitchen table. It fires." },
    { id = "gun_smg", item = "gun_smg", price = 200, desc = "It jams. Not often." },
    { id = "gun_shotgun", item = "gun_shotgun", price = 210, desc = "Hard to hide. Hard to argue with." },
    { id = "gun_357", item = "gun_357", price = 240, desc = "Loud, heavy, final." },
    { id = "armor_vest", item = "armor_vest", price = 90, desc = "Plates and salvaged charge cells. Holds a charge; comes with thirty in it." },
    { id = "radio_transmitter", item = "radio_transmitter", price = 70, desc = "Talk on your radio's band, not just listen. Contraband." },
    { id = "jammer", item = "jammer", price = 150, desc = "Four minutes of static on every Civil Protection unit radio nearby." },
}

LCS.BlackById = {}
for _, g in ipairs(LCS.Black) do
    g.name = g.name or (g.item and LCS.Items[g.item] and LCS.Items[g.item].name) or g.id
    LCS.BlackById[g.id] = g
end

------------------------------------------------------------------------
-- What the black market dealer pays
--   Items with their own `sell` above keep it. Everything else fetches 40% of
--   its cheapest shop price (so there's never a profit in buy-and-resell), or
--   a little for food and water nobody sells. Weapons you carry have a price
--   too, unless your faction issued them to you.
------------------------------------------------------------------------

do
    local ref = {}
    for _, list in ipairs({ LCS.Goods, LCS.Black }) do
        for _, g in ipairs(list) do
            if g.item then ref[g.item] = math.min(ref[g.item] or 1e9, g.price) end
        end
    end
    for id, it in pairs(LCS.Items) do
        if not it.sell then
            local base = ref[id] or (((it.hunger or 0) + (it.thirst or 0)) / 5)
            it.sell = math.max(1, math.floor(base * 0.4))
        end
    end
end

------------------------------------------------------------------------
-- Making things by hand (F3): just these, anywhere. Everything else (guns,
-- ammunition, armour, jammers, bypass charges, smoke bombs, a radio tuned to
-- Freq 7) is the Resistance lab's (LCS.Lab, below) or the black market's.
--   private   out of any unit's sight (a tunnel or back room will do)
------------------------------------------------------------------------

LCS.Recipes = {
    { id = "lockpick", out = "lockpick", needs = { scrap = 4 }, secs = 5, desc = "Bent and filed scrap" },
    { id = "bandage", out = "bandage", needs = { cloth = 2 }, secs = 4, desc = "Rags, torn into strips" },
    -- (hand-made goods, to sell from a stall: sv_livingcity_employment.lua)
    { id = "rag_doll", out = "rag_doll", needs = { cloth = 3 }, secs = 8, desc = "Sew a rag doll to sell (the city pays about 18)" },
    { id = "tin_toy", out = "tin_toy", needs = { scrap = 3 }, secs = 8, desc = "Hammer out a tin toy to sell (about 20)" },
    { id = "patched_coat", out = "patched_coat", needs = { cloth = 4, scrap = 1 }, secs = 12, desc = "Patch together a coat to sell (about 32)" },
}
LCS.RecipesById = {}
for _, r in ipairs(LCS.Recipes) do LCS.RecipesById[r.id] = r end

------------------------------------------------------------------------
-- The Resistance lab (sv_livingcity_lab.lua): what the scientist makes, for
-- the Resistance only. Bring him the materials (needs) and he makes it for
-- nothing; or pay him: 60% of the dealer's price (never less than the
-- quartermaster pays for it). secs: how long he takes.
------------------------------------------------------------------------

LCS.Lab = {
    { id = "ammo_pistol", out = "ammo_pistol", needs = { scrap = 2, chemicals = 1 }, secs = 6, desc = "Eighteen pistol rounds" },
    { id = "ammo_buckshot", out = "ammo_buckshot", needs = { scrap = 2, chemicals = 2 }, secs = 6, desc = "Twelve shotgun shells" },
    { id = "ammo_smg", out = "ammo_smg", needs = { scrap = 3, chemicals = 2 }, secs = 8, desc = "Forty-five SMG rounds" },
    { id = "ammo_357", out = "ammo_357", needs = { scrap = 3, chemicals = 2 }, secs = 8, desc = "Six .357 rounds" },
    { id = "gun_pistol", out = "gun_pistol", needs = { gun_parts = 2, scrap = 3 }, secs = 12, desc = "A pistol" },
    { id = "gun_smg", out = "gun_smg", needs = { gun_parts = 4, scrap = 6, chemicals = 1 }, secs = 18, desc = "An SMG" },
    { id = "gun_shotgun", out = "gun_shotgun", needs = { gun_parts = 3, scrap = 5 }, secs = 15, desc = "A shotgun" },
    { id = "gun_357", out = "gun_357", needs = { gun_parts = 4, scrap = 6, chemicals = 1 }, secs = 20, desc = "A .357 revolver" },
    { id = "armor_vest", out = "armor_vest", needs = { scrap = 6, cloth = 4, chemicals = 1 }, secs = 14, desc = "A powered vest: holds a charge (charge cells top it up)" },
    { id = "vest_cell", out = "vest_cell", needs = { scrap = 2, chemicals = 2 }, secs = 6, desc = "A charge cell: twenty-five charge into your vest" },
    { id = "forged_batch", out = "ration_forged", count = 5, needs = { paper = 3, chemicals = 1 }, secs = 12,
      desc = "Five forged ration cards: the dealer buys them, the dispensers take them. The more turn up, the hotter the search for the forger" },
    { id = "smokebomb", out = "smokebomb", needs = { chemicals = 2, can_empty = 1 }, secs = 5, desc = "Thick white smoke" },
    { id = "bypass", out = "bypass", needs = { gun_parts = 1, chemicals = 2, scrap = 2 }, secs = 10, desc = "Opens any door once, Combine doors too, and holds it open ten seconds" },
    { id = "firebomb", out = "firebomb", needs = { weedkiller = 2, bottle_empty = 1, cloth = 1 }, secs = 8, desc = "Weedkiller, cooked down, in a bottle with a rag: fire, which armour doesn't keep out" },
    { id = "chemicals_weedkiller", out = "chemicals", needs = { weedkiller = 2 }, secs = 6, desc = "Two canisters of weedkiller, cooked down into chemicals" },
    { id = "radio_transmitter", out = "radio_transmitter", needs = { radio_tuned = 1, scrap = 2 }, secs = 12, desc = "A Freq 7 radio rebuilt to send as well as listen" },
    { id = "jammer", out = "jammer", needs = { radio_tuned = 1, scrap = 2, chemicals = 1 }, secs = 15, desc = "A radio that only screams" },
    { id = "crowbar", out = "crowbar", needs = { scrap = 6 }, secs = 10, desc = "Bar stock, heated and bent" },
    -- (only once you've lived through lc_chip_dreams of the city's dreams: sv_livingcity_bedtime.lua)
    { id = "foil_hat", out = "foil_hat", needs = { scrap = 1, cloth = 1 }, secs = 5, dreamGate = true,
      desc = "A foil hat: sleep in it and it keeps the dream out about one night in three. \"The physics is... complicated.\" Contraband" },
}
LCS.LabById = {}
for _, r in ipairs(LCS.Lab) do LCS.LabById[r.id] = r end

LCS.SellWeapons = {
    weapon_crowbar = 20, weapon_stunstick = 30, weapon_pistol = 40, weapon_smg1 = 70, weapon_shotgun = 80,
    weapon_357 = 90, weapon_ar2 = 150, weapon_frag = 25, weapon_crossbow = 100,
}

------------------------------------------------------------------------
-- Carrying more than you can manage (say, after putting your satchel down):
-- you slow to a trudge until you drop something.
------------------------------------------------------------------------

hook.Add("SetupMove", "LivingCityOverweight", function(ply, mv)
    if not ply:GetNW2Bool("lc_overweight", false) then return end
    local cap = (ply:GetWalkSpeed() or 110) * 0.7
    if mv:GetMaxClientSpeed() > cap then mv:SetMaxClientSpeed(cap) end
end)
