--[[
    Items, Civil Standing tiers, the Union Commissary and the black market
    (shared config).

    Edit freely: item effects, prices, and what standing each purchase needs.
]]

AddCSLuaFile()

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
    cooked_headcrab = { name = "Roast headcrab", model = "models/headcrabclassic.mdl", hunger = 40 },

    can_empty       = { name = "Empty can", model = CAN, fillTo = "can_dirty" },
    can_dirty       = { name = "Can of untreated water", model = CAN, thirst = 30, parasite = 0.4, cooksTo = "can_clean", leaves = "can_empty" },
    can_clean       = { name = "Can of boiled water", model = CAN, thirst = 30, leaves = "can_empty" },
    bottle_empty    = { name = "Empty bottle", model = BOTTLE, fillTo = "bottle_dirty" },
    bottle_dirty    = { name = "Bottle of untreated water", model = BOTTLE, thirst = 45, parasite = 0.4, cooksTo = "bottle_clean", leaves = "bottle_empty" },
    bottle_clean    = { name = "Bottle of boiled water", model = BOTTLE, thirst = 45, leaves = "bottle_empty" },

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
    radio           = { name = "Union radio", model = "models/props_lab/citizenradio.mdl", radio = "union", sell = 12,
                        desc = "Union band. Hear city notices before the loudspeakers do. Talk with !r" },
    radio_tuned     = { name = "Retuned radio", model = "models/props_lab/citizenradio.mdl", radio = "resistance",
                        contraband = true, conceal = 0.25, sell = 20,
                        desc = "Freq 7, and whatever Civil Protection says when it thinks nobody is listening" },
    permit          = { name = "Travel permit", model = "models/props_c17/paper01.mdl", permit = true,
                        desc = "Stamped and legal. Gets you past one curfew stop" },
    papers_blank    = { name = "Blank identity form", model = "models/props_c17/paper01.mdl", forge = true,
                        contraband = true, conceal = 0.6, sell = 10,
                        desc = "Fill it in somewhere private and it becomes somebody" },
    papers_forged   = { name = "Forged papers", model = "models/props_c17/paper01.mdl", papers = "forged",
                        contraband = true, conceal = 0.5, sell = 30,
                        desc = "A new name. Clears your wanted status if no unit is watching" },
    papers_dead     = { name = "A dead man's papers", model = "models/props_c17/paper01.mdl", papers = "dead",
                        contraband = true, conceal = 0.5, sell = 25,
                        desc = "Genuine papers. Their owner won't be needing them" },
    ration_forged   = { name = "Forged ration card", model = "models/props_c17/paper01.mdl", rationCard = true,
                        contraband = true, conceal = 0.65, sell = 8,
                        desc = "One extra ration from any dispenser, whatever your standing" },
    uniform_cp      = { name = "Civil Protection uniform", model = "models/props_c17/BriefCase001a.mdl", wear = "cp",
                        contraband = true, conceal = 0, sell = 50,
                        desc = "Mask and all. Units on the street will take you for one of them, mostly" },
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
                        desc = "Off a dead unit. Opens one Combine door before someone reports it missing" },
    scrap           = { name = "Scrap metal", model = "models/props_junk/garbage_metalcan002a.mdl", sell = 3,
                        desc = "The dealer pays for it" },
    keepsake        = { name = "Wedding ring", model = "models/props_lab/box01a.mdl", sell = 20,
                        desc = "It belonged to somebody" },
}

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
--   cpOnly    units only
------------------------------------------------------------------------

LCS.Goods = {
    { id = "ration", item = "ration", price = 5, minStanding = -50, desc = "Nutrient bar and a little water. It keeps you alive." },
    { id = "water", item = "water", price = 2, minStanding = -50, desc = "Clean, cold, refreshing. Do not ask what is in it." },
    { id = "bottle", item = "bottle_empty", price = 2, minStanding = -50, desc = "An empty glass bottle, for whatever water you can find." },
    { id = "tablets", item = "tablets", price = 15, minStanding = -50, desc = "For what the canal water gives you." },
    { id = "civvies", item = "civvies", price = 10, minStanding = -50, desc = "Union-issue work clothes. Everyone looks the same in them." },
    { id = "radio", item = "radio", price = 40, minStanding = 0, desc = "Union band. Notices before the loudspeakers, and a way to talk (!r)." },
    { id = "permit", item = "permit", price = 35, minStanding = 150, desc = "One night out after curfew, stamped and legal." },
    { id = "bread", item = "bread", price = 8, minStanding = 0, desc = "Grey, dense, and real." },
    { id = "milk", item = "milk", price = 8, minStanding = 0, desc = "Powdered, reconstituted, nearly milk." },
    { id = "healthvial", name = "Health vial", entity = "item_healthvial", price = 25, minStanding = 150, desc = "For the trusted." },
    { id = "melon", item = "melon", price = 25, minStanding = 400, desc = "A whole watermelon. Exemplary citizens only." },
    { id = "coffee", item = "coffee", price = 30, minStanding = 400, desc = "Real coffee. You'd forgotten the smell." },
    { id = "healthkit", name = "Medical kit", entity = "item_healthkit", price = 50, minStanding = 400, desc = "A full medical kit." },
    { id = "pistolammo", name = "Pistol ammunition", ammo = { "Pistol", 36 }, price = 10, cpOnly = true, desc = "Standard issue." },
    { id = "smgammo", name = "SMG ammunition", ammo = { "SMG1", 90 }, price = 20, cpOnly = true, minStanding = 150, desc = "For units in good standing." },
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
    { id = "papers_forged", item = "papers_forged", price = 80, desc = "Good work. Not perfect work." },
    { id = "papers_blank", item = "papers_blank", price = 30, desc = "For people with a steady hand." },
    { id = "ration_forged", item = "ration_forged", price = 25, desc = "One more meal than the Union thinks you deserve." },
    { id = "lockpick", item = "lockpick", price = 35, desc = "Picks, tension wrench, patience not included." },
    { id = "bypass", item = "bypass", price = 70, desc = "One use. Don't ask where it came from." },
    { id = "civvies", item = "civvies", price = 15, desc = "Clean, plain, forgettable." },
    { id = "uniform_cp", item = "uniform_cp", price = 160, desc = "Off a unit who won't be needing it." },
    { id = "tablets", item = "tablets", price = 20, desc = "No questions about why you need them." },
    { id = "crowbar", name = "Crowbar", weapon = "weapon_crowbar", price = 50, desc = "Every revolution starts somewhere." },
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

LCS.SellWeapons = {
    weapon_crowbar = 20, weapon_stunstick = 30, weapon_pistol = 40, weapon_smg1 = 70, weapon_shotgun = 80,
    weapon_357 = 90, weapon_ar2 = 150, weapon_frag = 25, weapon_crossbow = 100,
}
