--[[
    Items, Civil Standing tiers, the Union Commissary and the black market
    (shared config).

    Edit freely: item effects, prices, and what standing each purchase needs.
]]


LCS = LCS or {}

------------------------------------------------------------------------
-- Items you can carry (inventory: F2 or !inv)
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

    raw_bird        = { name = "Raw bird", model = "models/pigeon.mdl", hunger = 10, parasite = 0.7, cooksTo = "cooked_bird" },
    cooked_bird     = { name = "Roast bird", model = "models/pigeon.mdl", hunger = 30 },
    raw_headcrab    = { name = "Raw headcrab", model = "models/headcrabclassic.mdl", hunger = 15, parasite = 0.85, cooksTo = "cooked_headcrab" },
    raw_fastcrab    = { name = "Raw fast headcrab", model = "models/headcrab.mdl", hunger = 12, parasite = 0.85, cooksTo = "cooked_headcrab" },
    raw_poisoncrab  = { name = "Raw poison headcrab", model = "models/headcrabblack.mdl", hunger = 15, parasite = 0.9, poison = 45, cooksTo = "cooked_headcrab",
                        desc = "The venom's still in it. Cooking burns it out. Eating it raw will put you on the floor" },
    cooked_headcrab = { name = "Roast headcrab", model = "models/headcrabclassic.mdl", hunger = 40 },

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
    ration_card     = { name = "Ration card", model = "models/props_c17/paper01.mdl", doc = true, kg = 0, sell = 0,
                        desc = "Earned by work: one for each Union shift you finish. A ration dispenser takes one card for each ration" },
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
    -- (1 November, the owner: no Union radio any more; a civilian with any radio is breaking the law)
    radio           = { name = "Radio set", model = "models/props_lab/citizenradio.mdl", radio = "union", contraband = true, conceal = 0.3, sell = 12, use = "listen", useLabel = "Listen",
                        desc = "An old receiver. Civilians aren't allowed radios: carrying one is an offence. The Resistance lab turns one into a Freq 7 radio or a transmitter" },
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
    civvies         = { name = "Spare citizen clothes", model = "models/props_c17/suitcase_passenger_physics.mdl", wear = "citizen",
                        desc = "Union blue. Lets a hunted Resistance member pass as an ordinary citizen" },
    lockpick        = { name = "Lockpick set", model = "models/props_c17/tools_wrench01a.mdl", tool = "lockpick",
                        contraband = true, conceal = 0.55, sell = 10,
                        desc = "Look at a locked door and use it. Not Combine locks" },
    bypass          = { name = "Combine bypass charge", model = "models/props_lab/reciever01b.mdl", tool = "bypass",
                        contraband = true, conceal = 0.35, sell = 25,
                        desc = "Opens any door once, Combine doors included. Sometimes trips an alarm" },
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
    raw_fish        = { name = "Raw fish", model = "models/props_junk/garbage_newspaper001a.mdl", hunger = 15, parasite = 0.5, cooksTo = "cooked_fish",
                        desc = "From the canal. Cook it. Really, cook it" },
    cooked_fish     = { name = "Fried fish", model = "models/props_junk/garbage_newspaper001a.mdl", hunger = 35 },
    seeds           = { name = "Seed packet", model = "models/props_lab/box01a.mdl", use = "plant", useLabel = "Plant",
                        desc = "Plant them in a pot in rebel territory (look at it and press E, or Plant here)" },
    fishing_line    = { name = "Fishing line", model = "models/props_lab/box01a.mdl", use = "fish", useLabel = "Fish",
                        desc = "Stand in the canal, or look at the water, and wait. Keeps" },
    spraypaint      = { name = "Spray can", model = "models/props_junk/popcan01a.mdl", use = "spray", useLabel = "Spray",
                        contraband = true, conceal = 0.5, sell = 4,
                        desc = "Look at a wall and spray the lambda. Don't let a Civil Protection unit see you do it" },
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
    bandage         = { name = "Bandage", model = "models/props_junk/garbage_newspaper001a.mdl", use = "heal", useLabel = "Patch up", heal = 20,
                        desc = "Twenty health, give or take" },
    ammo_pistol     = { name = "Box of pistol rounds", model = "models/items/boxsrounds.mdl", use = "ammo", useLabel = "Load", ammo = { "Pistol", 18 },
                        contraband = true, conceal = 0.35, sell = 15, arms = true, desc = "Hand-loaded. Mostly reliable" },
    ammo_smg        = { name = "Box of SMG rounds", model = "models/items/boxmrounds.mdl", use = "ammo", useLabel = "Load", ammo = { "SMG1", 45 },
                        contraband = true, conceal = 0.3, sell = 25, arms = true, desc = "Hand-loaded" },
    ammo_buckshot   = { name = "Box of shells", model = "models/items/boxbuckshot.mdl", use = "ammo", useLabel = "Load", ammo = { "Buckshot", 12 },
                        contraband = true, conceal = 0.3, sell = 20, arms = true, desc = "Hand-packed shells" },
    gun_pistol      = { name = "Homemade pistol", model = "models/weapons/w_pistol.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_pistol",
                        contraband = true, conceal = 0.25, sell = 45, arms = true, desc = "Put together on a kitchen table. It fires" },
    gun_shotgun     = { name = "Homemade shotgun", model = "models/weapons/w_shotgun.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_shotgun",
                        contraband = true, conceal = 0.05, sell = 80, arms = true, desc = "Hard to hide. Hard to argue with" },
    gun_smg         = { name = "Homemade SMG", model = "models/weapons/w_smg1.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_smg1",
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
    zipties         = { name = "Cuffs", model = "models/props_lab/box01a.mdl", sell = 1, -- (1, not 4: Civil Protection buy them three for 6)
                        desc = "Cuff someone: !cuff, looking at them (hands up, down, stopped, or from behind). Civil Protection units carry their own" },
    request_device  = { name = "Request device", model = "models/props_lab/reciever01b.mdl", sell = 6,
                        desc = "Calls Civil Protection to where you are: /request <what's wrong>" },
    ------------------------------------------------------------------------
    -- Carrying and keeping things (sv_livingcity_storage.lua)
    --   bag      extra kilograms and large things you can carry while you have it
    --   place    "crate": set down in the world as your own lockable crate
    ------------------------------------------------------------------------
    satchel         = { name = "Satchel", model = "models/props_c17/BriefCase001a.mdl", bag = { kg = 8, bulky = 1 }, sell = 10,
                        desc = "A canvas bag over the shoulder. Room for more, and for something large" },
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
    gun_357         = { name = "Homemade revolver", model = "models/weapons/w_357.mdl", use = "arm", useLabel = "Draw", weapon = "weapon_357",
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

LCS.Weights = {
    ration = 0.3, water = 0.4, bread = 0.5, milk = 0.6, melon = 3.0, coffee = 0.3, tablets = 0.05,
    raw_bird = 0.6, cooked_bird = 0.5, raw_headcrab = 1.2, raw_fastcrab = 1.0, raw_poisoncrab = 1.4, cooked_headcrab = 1.0,
    can_empty = 0.05, can_dirty = 0.4, can_clean = 0.4, bottle_empty = 0.3, bottle_dirty = 0.8, bottle_clean = 0.8,
    radio = 1.0, radio_tuned = 1.0, radio_transmitter = 0.6, permit = 0.02, papers_blank = 0.02, papers_forged = 0.02, papers_dead = 0.02, ration_forged = 0.02,
    uniform_cp = 3.0, cwu_overalls = 1.2, rebel_gear = 3.0, civvies = 1.0,
    lockpick = 0.1, bypass = 0.6, cp_keycard = 0.02, canned_food = 0.5, vegetables = 0.6, raw_fish = 0.7, cooked_fish = 0.6,
    seeds = 0.05, fishing_line = 0.2, spraypaint = 0.4, cloth = 0.2, chemicals = 0.8, gun_parts = 1.0, bandage = 0.1,
    ammo_pistol = 0.4, ammo_smg = 0.8, ammo_buckshot = 0.7, gun_pistol = 1.1, gun_shotgun = 3.4, gun_smg = 2.8,
    smokebomb = 0.4, gren_smoke = 0.5, gren_flash = 0.5, gren_gas = 0.6, arms_crate = 9.0, smuggled_supplies = 2.5, data_shard = 0.3, master_chip = 0.6, zipties = 0.05,
    request_device = 0.3, scrap = 0.5, keepsake = 0.01, satchel = 0.8, storage_crate = 6.0,
    business_license = 0.02, vendor_stall = 7.0, paper = 0.02,
}
LCS.Bulky = { melon = true, uniform_cp = true, rebel_gear = true, gun_shotgun = true, gun_smg = true, arms_crate = true, storage_crate = true, vendor_stall = true }

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
--   cpOnly    units only, and sold only at the Civil Protection Commissary's
--             counter (the Union terminal sells them only in a city without one)
------------------------------------------------------------------------

LCS.Goods = {
    { id = "ration", item = "ration", price = 5, minStanding = -50, desc = "Nutrient bar and a little water. It keeps you alive." },
    { id = "water", item = "water", price = 2, minStanding = -50, desc = "Clean, cold, refreshing. Do not ask what is in it." },
    { id = "bottle", item = "bottle_empty", price = 2, minStanding = -50, desc = "An empty glass bottle, for whatever water you can find." },
    { id = "tablets", item = "tablets", price = 15, minStanding = -50, desc = "For what the canal water gives you." },
    { id = "civvies", item = "civvies", price = 10, minStanding = -50, desc = "Union-issue work clothes. Everyone looks the same in them." },
    { id = "permit", item = "permit", price = 35, minStanding = 150, desc = "One night out after curfew, stamped and legal." },
    { id = "bread", item = "bread", price = 8, minStanding = 0, desc = "Grey, dense, and real." },
    { id = "milk", item = "milk", price = 8, minStanding = 0, desc = "Powdered, reconstituted, nearly milk." },
    { id = "healthvial", name = "Health vial", entity = "item_healthvial", price = 25, minStanding = 150, desc = "For the trusted." },
    { id = "melon", item = "melon", price = 25, minStanding = 400, desc = "A whole watermelon. Exemplary citizens only." },
    { id = "coffee", item = "coffee", price = 30, minStanding = 400, desc = "Real coffee. You'd forgotten the smell." },
    { id = "healthkit", name = "Medical kit", entity = "item_healthkit", price = 50, minStanding = 400, desc = "A full medical kit." },
    { id = "request_device", item = "request_device", price = 10, minStanding = 0, desc = "Something wrong? Call Civil Protection: /request." },
    { id = "zipties", item = "zipties", count = 3, name = "Cuffs (3)", price = 6, cpOnly = true, desc = "Spares. Civil Protection units never run out of their own." },
    { id = "paper", item = "paper", count = 3, name = "Paper (3)", price = 2, minStanding = -50, desc = "For notes, letters and notices." },
    { id = "business_license", item = "business_license", price = 75, minStanding = 50, desc = "The Union's permission to trade from a stall." },
    { id = "vendor_stall", item = "vendor_stall", price = 60, minStanding = 50, desc = "Everything you need to sell. A license not included." },
    { id = "satchel", item = "satchel", price = 25, minStanding = -50, desc = "Carry more. Eight more kilos, and one more large thing." },
    { id = "storage_crate", item = "storage_crate", price = 40, minStanding = 0, desc = "Somewhere of your own to keep things. Civil Protection units can open it." },
    { id = "fishing_line", item = "fishing_line", price = 15, minStanding = -50, desc = "Line and a hook. The canal has fish, of a kind." },
    { id = "gren_smoke", item = "gren_smoke", price = 20, cpOnly = true, desc = "Cover for an advance, or a retreat." },
    { id = "gren_flash", item = "gren_flash", price = 35, cpOnly = true, minRank = 2, desc = "Metrocops and up. Don't look at it." },
    { id = "gren_gas", item = "gren_gas", price = 60, cpOnly = true, minRank = 3, desc = "Division Leaders and the Overwatch. For clearing anticitizen holdouts." },
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
-- Standing doesn't matter here. Credits do. Units who walk up to a dealer
-- don't buy anything: they bust it.
------------------------------------------------------------------------

LCS.Black = {
    { id = "radio_tuned", item = "radio_tuned", price = 60, desc = "Already tuned to Freq 7." },
    { id = "radio", item = "radio", price = 30, desc = "A plain receiver. The lab can retune it, or make a transmitter of it." },
    { id = "papers_forged", item = "papers_forged", price = 80, desc = "Good work. Not perfect work." },
    { id = "papers_blank", item = "papers_blank", price = 30, desc = "For people with a steady hand." },
    { id = "ration_forged", item = "ration_forged", price = 10, desc = "One more meal than the Union thinks you deserve." },
    { id = "lockpick", item = "lockpick", price = 35, desc = "Picks, tension wrench, patience not included." },
    { id = "bypass", item = "bypass", price = 70, desc = "One use. Don't ask where it came from." },
    { id = "civvies", item = "civvies", price = 15, desc = "Clean, plain, forgettable." },
    { id = "uniform_cp", item = "uniform_cp", price = 160, desc = "Off a Civil Protection unit who won't be needing it." },
    { id = "tablets", item = "tablets", price = 20, desc = "No questions about why you need them." },
    { id = "crowbar", name = "Crowbar", weapon = "weapon_crowbar", price = 50, desc = "Every revolution starts somewhere." },
    { id = "multitool", name = "Multitool", weapon = "weapon_lc_multitool", price = 250, desc = "Opens Combine locks, screens and terminals. Very illegal. Don't get searched." },
    { id = "gun_parts", item = "gun_parts", price = 18, desc = "Springs, barrels, pins. Make something with them." },
    { id = "chemicals", item = "chemicals", price = 6, desc = "Bought by the bottle. Nobody cleans that much." },
    { id = "seeds", item = "seeds", price = 12, desc = "Tomatoes, beans, maybe. Plant them in rebel territory." },
    { id = "canned_food", item = "canned_food", price = 14, desc = "Pre-war tins. Nobody asks where they come from." },
    { id = "zipties", item = "zipties", count = 2, name = "Cuffs (2)", price = 20, desc = "For a Civil Protection unit who needs to stay put." },
    { id = "satchel", item = "satchel", price = 30, desc = "No questions about what goes in it." },
    { id = "spraypaint", item = "spraypaint", count = 3, name = "Spray cans (3)", price = 25, desc = "Let the city know we're still here." },
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
-- Making things by hand (F2): just these, anywhere. Everything else (guns,
-- ammunition, armour, jammers, bypass charges, smoke bombs, a radio tuned to
-- Freq 7) is the Resistance lab's (LCS.Lab, below) or the black market's.
--   private   out of any unit's sight (a tunnel or back room will do)
------------------------------------------------------------------------

LCS.Recipes = {
    { id = "lockpick", out = "lockpick", needs = { scrap = 4 }, secs = 5, desc = "Bent and filed scrap" },
    { id = "bandage", out = "bandage", needs = { cloth = 2 }, secs = 4, desc = "Rags, torn into strips" },
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
    { id = "bypass", out = "bypass", needs = { gun_parts = 1, chemicals = 2, scrap = 2 }, secs = 10, desc = "Opens any door once" },
    { id = "radio_tuned", out = "radio_tuned", needs = { radio = 1 }, secs = 8, desc = "A radio set, opened up and retuned to Freq 7" },
    { id = "radio_transmitter", out = "radio_transmitter", needs = { radio = 1, scrap = 2 }, secs = 12, desc = "A radio set rebuilt to send as well as listen" },
    { id = "jammer", out = "jammer", needs = { radio_tuned = 1, scrap = 2, chemicals = 1 }, secs = 15, desc = "A radio that only screams" },
    { id = "crowbar", out = "crowbar", needs = { scrap = 6 }, secs = 10, desc = "Bar stock, heated and bent" },
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
