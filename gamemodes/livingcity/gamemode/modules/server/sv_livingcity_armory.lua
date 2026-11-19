--[[
    Living City: the Resistance's armory, what the quartermaster pays and is paid, and barter with him

    The owner, 19 November: "for stolen/fenced combine gear, can we just put the weapons collected directly
    into a resistance locker/armory? ... if I already have an SMG or pistol then I can't pick up the
    SMG/Pistol on the ground: let's make it so they are picked up and placed into the player's inventory and
    if sold to the quartermaster they go into the armory"; "they get like 5 credits from the resistance fund
    for each weapon"; "yes, quartermaster purchases should go into the fund"; when the fund is empty the
    quartermaster "can offer to barter/trade things ... where items are traded based on their sale value if
    credits are lacking", "a button ... that says 'Barter'", and a leniency by standing that is "it's own
    hidden value/fund that refills over time, at most once per day or two" ("a Lieutenant should get like a
    10 credit leeway and a Commander like a 20 credit leeway"), shown as a thin bar, "Goodwill".

    Pocket guns  A gun on the ground of a class you already carry (a fallen unit's pistol, SMG, shotgun,
                 revolver or pulse rifle) goes in your pockets as that gun's item (gun_pistol, gun_smg,
                 gun_shotgun, gun_357, gun_ar2), the rounds in it added to yours. Not a unit's (they leave
                 it); not when the pockets are full, or anything else says no (it stays on the ground, as
                 before); not a gun the game is handing you that moment (a Give).
    The armory   Guns by class that belong to the Resistance, kept with the fund in the ledger ("armory"
                 in data/livingcity/<map>_city.json). A gun sold to the quartermaster goes on its shelf,
                 and he pays GUN_PAY (5) for it out of the fund; a gun given to him goes on it too.
                 LC.FundIssue (sv_livingcity_fundgear.lua) arms a fighter from it first, at no cost.
    His buying   Everything he buys is paid out of the fund: guns 5, the gun run's crate RUN_PAY (60, and
                 RUN_GUNS for the armory), everything else at what he paid before (intel, skimmed parts,
                 forged cards, ammunition, materials...; intel still gives its experience). What the fund
                 can't pay, he makes up in trade: his barter opens with it on your side.
    His selling  What a player pays him goes into the fund ("Sold at the quartermaster's").
    Barter       From his window, anyone he deals with. Your things he'd buy, at what he pays; his stock,
                 at what he charges (strangers: nothing, as he sells them nothing). Credits from your
                 pocket make up a difference (into the fund); when yours is worth more, the fund pays you
                 as far as it can. Checked here, every time: who, how near, that everything is really
                 there, the totals worked out again, room in the pockets, once a second at most.
    Goodwill     A hidden allowance each character has (GOODWILL by rank; anyone else by sympathy, at most
                 3), refilling to full over REFILL (24 real hours), worked out from the time it was last
                 spent (PData lc_goodwill: "left:os.time()"). A trade short of his by no more than what is
                 left of it goes through: the difference is let go, and taken from it. Only in a barter
                 that gives something of yours; it never pays out credits.

    LC.Armory(), LC.ArmoryCount(cls), LC.ArmoryAdd(cls, n), LC.ArmoryTake(cls, n)
    LC.PocketGunItem(cls), LC.PocketPickup(ply, wep)
    LC.QuartermasterDealer(ply)             "member", "visitor" or nil: who may deal with him here
    LC.QuartermasterBuyPrice(ply, id)       what he pays for one (id: an item, or "w:<class>" in hand)
    LC.QuartermasterBuy(ply, id, all)       a sale from his window (sv_livingcity_underground.lua)
    LC.QuartermasterPaid(ply, n)            credits paid to him: into the fund
    LC.QuartermasterGunRun(ply, item)       the gun run's crate delivered (sv_livingcity_quests.lua)
    LC.GoodwillFull(ply), LC.Goodwill(ply, now), LC.GoodwillSpend(ply, n, now)
    LC.BarterOffer(ply), LC.BarterOpen(ply, pre, status), LC.BarterTrade(ply, offer)

    Net: lc_barter (both ways: the view to the player; open or trade from the player).
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_barter")

local GUN_PAY = 5            -- what the quartermaster pays for a gun, out of the fund (it goes on the armory's shelf)
local RUN_PAY = 60           -- the gun run's crate, what the job always paid
local RUN_ITEMS = { smuggled_supplies = true, arms_crate = true } -- (the crate, and the whole crate from before crates were broken open)
local RUN_GUNS = { "weapon_pistol", "weapon_smg1" }               -- what a gun run's crate puts on the shelf
local GOODWILL = { 1, 3, 5, 10, 20 } -- by Resistance rank: Sympathizer, Member, Fighter, Lieutenant, Commander
local OUTSIDER_MAX = 3       -- anyone else: one credit for every SYMPATHY_PER sympathy, no more than this
local SYMPATHY_PER = 2
local REFILL = 24 * 3600     -- seconds for an empty allowance to fill again (real time)
local KEY = "lc_goodwill"
local GAP = 1                -- seconds between one trade and the next
local OPEN_GAP = 0.3
local MAX_EACH = 10          -- of one of his things in one trade
local MAX_ROWS = 40
local FRESH = 0.5            -- a gun this new is one the game is handing them (a Give), not one lying about
local SHORT = "You don't have that much."
local HEAVY = "That's more than you can carry."
local DECODED = { data_chip = true, master_chip = true } -- (he doesn't buy the Combine's data: the lab decodes it, as in sv_livingcity_underground.lua)

LC.ArmoryGunPay, LC.GunRunPay, LC.GoodwillByRank, LC.GoodwillRefill = GUN_PAY, RUN_PAY, GOODWILL, REFILL

local function Guns() return LC.FundGuns or {} end
local function Cap(s) return (string.gsub(s, "^%l", string.upper)) end
local function Book() return LC.Ledger and LC.Ledger() or nil end
local function Save() if LC.LedgerSave then LC.Try(LC.LedgerSave) end end
local function Seed() if LC.FundSeed then LC.FundSeed() end end
local function Fund() return LC.ResistanceFund and LC.ResistanceFund() or 0 end
local function Faction(p) return p:GetNW2String("lcf_faction", "") end

-- An entry in the fund's record that moves no credits (sv_livingcity_fundgear.lua), written at once.
local function Note(line, who)
    if LC.ResistanceFundRecord then LC.ResistanceFundRecord(0, line, who) end
    Save()
end

------------------------------------------------------------------------
-- The armory
------------------------------------------------------------------------

local function Shelf()
    local book = Book()
    if not book then return nil end
    if not istable(book.armory) then book.armory = {} end
    return book.armory
end

function LC.ArmoryCount(cls)
    local s = Shelf()
    return s and Guns()[cls] and math.max(0, math.floor(tonumber(s[cls]) or 0)) or 0
end

function LC.Armory()
    local out = {}
    for cls in pairs(Guns()) do
        local n = LC.ArmoryCount(cls)
        if n > 0 then out[cls] = n end
    end
    return out
end

function LC.ArmoryAdd(cls, n)
    n = math.floor(tonumber(n) or 0)
    local s = Shelf()
    if not s or n <= 0 or not Guns()[cls] then return false end
    s[cls] = LC.ArmoryCount(cls) + n
    Save()
    return true
end

function LC.ArmoryTake(cls, n)
    n = math.floor(tonumber(n) or 1)
    local s = Shelf()
    if not s or n <= 0 or LC.ArmoryCount(cls) < n then return false end
    s[cls] = LC.ArmoryCount(cls) - n
    if s[cls] <= 0 then s[cls] = nil end
    Save()
    return true
end

-- What the record calls guns put on the shelf: "A pistol for the armory", "Guns for the armory".
local function GunLine(list)
    if #list == 1 then return Cap((Guns()[list[1]] or {}).name or "a gun") .. " for the armory" end
    return "Guns for the armory"
end

------------------------------------------------------------------------
-- A gun you carry already: into the pockets
------------------------------------------------------------------------

local pocketItem -- [class] = item id
function LC.PocketGunItem(cls)
    if not pocketItem then
        pocketItem = {}
        for id, it in pairs(LCS.Items) do
            if it.use == "arm" and it.weapon and Guns()[it.weapon] and not it.tainted then pocketItem[it.weapon] = id end
        end
    end
    return pocketItem[cls]
end

-- The other answers to PlayerCanPickupWeapon (a dream, a cell, tied hands, the infested, a stalker...): if any
-- says no, nothing goes in the pockets. Asked here, so it is the same whichever of us the game asks first.
local HOOK = "LivingCityPocketGuns"
local function OthersRefuse(ply, wep)
    local all = hook.GetTable and hook.GetTable() or nil
    for name, fn in pairs(all and all.PlayerCanPickupWeapon or {}) do
        if name ~= HOOK and isfunction(fn) then
            local okH, r
            if isstring(name) then okH, r = LC.Try(fn, ply, wep)
            elseif IsValid(name) then okH, r = LC.Try(fn, name, ply, wep) end
            if okH and r == false then return true end
        end
    end
    return false
end

-- true when the gun went in their pockets (and is gone from the ground).
function LC.PocketPickup(ply, wep)
    if not (IsValid(ply) and ply:IsPlayer() and ply:Alive() and IsValid(wep)) or wep.lcPocketed then return false end
    local cls = wep:GetClass()
    local id = LC.PocketGunItem(cls)
    if not id or not ply:HasWeapon(cls) then return false end
    if wep.GetOwner and IsValid(wep:GetOwner()) then return false end -- (in someone's hands)
    local born = wep.GetCreationTime and wep:GetCreationTime() or 0
    if CurTime() - born <= FRESH then return false end
    if LC.PlayerIsCP and LC.PlayerIsCP(ply) then return false end -- (a unit leaves it lying)
    if not LC.CanCarry(ply, id, 1) then return false end -- (pockets full: it stays where it is)
    if OthersRefuse(ply, wep) then return false end
    wep.lcPocketed = true
    local kind = Guns()[cls].ammo
    local clip = wep.Clip1 and tonumber(wep:Clip1()) or 0
    if kind and clip and clip > 0 then
        local room = LC.AmmoRoom and LC.AmmoRoom(ply, kind)
        local n = room and math.min(room, clip) or clip
        if n > 0 then ply:GiveAmmo(n, kind) end
    end
    LC.GiveItem(ply, id, 1)
    if ply.EmitSound then ply:EmitSound("items/ammo_pickup.wav", 55) end
    wep:Remove()
    return true
end

-- Answering is the point here: false once it is in the pockets (so the game doesn't also take the ammunition
-- out of a gun that's gone), and nothing otherwise, for the game and the other answers to decide as before.
hook.Add("PlayerCanPickupWeapon", HOOK, function(ply, wep)
    local okP, done = LC.Try(LC.PocketPickup, ply, wep)
    if okP and done then return false end
end)

------------------------------------------------------------------------
-- What he pays, and what he is paid
------------------------------------------------------------------------

-- Who may deal with him here: "member" (one of ours at his post), "visitor" (anyone else he takes arms from), or nil.
function LC.QuartermasterDealer(ply)
    if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return nil end
    if LC.AtQuartermaster and LC.AtQuartermaster(ply) then return "member" end
    if LC.QuartermasterVisitor and LC.QuartermasterVisitor(ply) and not (LC.IsBurned and LC.IsBurned(ply)) then return "visitor" end
    return nil
end

-- The class of a gun he puts on the shelf: one in hand ("w:<class>"), or a pocket gun.
local function GunOf(id)
    local cls = string.match(id or "", "^w:(.+)$")
    if cls then return Guns()[cls] and cls or nil end
    local it = LCS.Items[id or ""]
    if it and it.use == "arm" and it.weapon and Guns()[it.weapon] then return it.weapon end
    return nil
end

-- What he pays for one, here (nil: he won't buy it from them).
function LC.QuartermasterBuyPrice(ply, id)
    local who = LC.QuartermasterDealer(ply)
    if not who or not isstring(id) then return nil end
    local arms = LC.QuartermasterArms and LC.QuartermasterArms(id)
    if RUN_ITEMS[id] then return RUN_PAY end
    if GunOf(id) then return GUN_PAY end
    if who == "visitor" and not arms then return nil end -- (from strangers only arms and what the fight needs)
    local cls = string.match(id, "^w:(.+)$")
    if cls then return LCS.SellWeapons and LCS.SellWeapons[cls] or nil end
    local it = LCS.Items[id]
    if not it or DECODED[id] then return nil end
    local p = LC.SellPrice and LC.SellPrice(ply, id) or it.sell
    return (p and p > 0) and p or nil
end

local function Named(id)
    local cls = string.match(id, "^w:(.+)$")
    if cls then
        local item = LC.PocketGunItem(cls)
        return item and LCS.Items[item].name or (string.gsub(string.gsub(cls, "^weapon_", ""), "_", " "))
    end
    return LCS.Items[id] and LCS.Items[id].name or id
end

-- What he'd buy from them: pocket items, and guns in hand their side didn't issue them.
local function Wants(ply)
    local out = {}
    local inv = LC.Inventory(ply)
    local ids = table.GetKeys(inv)
    table.sort(ids)
    for _, id in ipairs(ids) do
        local n = math.floor(tonumber(inv[id]) or 0)
        local price = n > 0 and LCS.Items[id] and LC.QuartermasterBuyPrice(ply, id)
        if price then out[#out + 1] = { id = id, name = Named(id), n = n, price = price } end
    end
    local seen = {}
    for _, w in ipairs(ply:GetWeapons() or {}) do
        local cls = w and w.GetClass and w:GetClass()
        local id = cls and ("w:" .. cls)
        local price = id and not seen[cls] and not (LC.IsIssuedWeapon and LC.IsIssuedWeapon(ply, cls)) and LC.QuartermasterBuyPrice(ply, id)
        if price then
            seen[cls] = true
            out[#out + 1] = { id = id, name = Named(id), n = 1, price = price }
        end
    end
    return out
end

-- Out of their hands or pockets; and what follows from it (the shelf, intel's experience, the forger's trail,
-- a stranger's sympathy, the market), as when the dealer's code bought it at his post.
local function Hand(ply, id, n)
    local cls = string.match(id, "^w:(.+)$")
    if cls then
        if not ply:HasWeapon(cls) then return false end
        ply:StripWeapon(cls)
        return true
    end
    return LC.TakeItem(ply, id, n)
end

local function Took(ply, id, n)
    local gun = GunOf(id)
    if gun then LC.ArmoryAdd(gun, n) end
    if RUN_ITEMS[id] then for _, c in ipairs(RUN_GUNS) do LC.ArmoryAdd(c, n) end end
    if not string.match(id, "^w:") then
        local it = LCS.Items[id]
        if LC.MarketSold then LC.MarketSold(id, n) end
        if id == "ration_forged" then hook.Run("LivingCityForgedCard", ply, n) end -- (the search for the forger: sv_livingcity_funding.lua)
        if it and it.intel and LC.AddXP then LC.AddXP(ply, 5 * n, "intel") end -- (intel's experience, always)
    end
    local s = LC.QuartermasterSellSympathy and LC.QuartermasterSellSympathy(id) or 0
    if s > 0 and LC.AddTrait then LC.AddTrait(ply, "sympathy", s * n) end
end

-- Credits paid to him: into the fund.
function LC.QuartermasterPaid(ply, n)
    n = math.floor(tonumber(n) or 0)
    if n <= 0 or not LC.ResistanceFundAdd then return end
    Seed()
    LC.ResistanceFundAdd(n, "Sold at the quartermaster's", { ply })
end

-- He pays for what he took, out of the fund: one entry, "A pistol for the armory (Kerr)" or "Bought at the
-- quartermaster's (Kerr)"; guns that went on the shelf without credits for them get an entry of their own.
local function PayOut(ply, n, took)
    local guns, onlyGuns = {}, true
    for _, x in ipairs(took) do
        local g = GunOf(x.id)
        if g then for _ = 1, x.n do guns[#guns + 1] = g end else onlyGuns = false end
    end
    if n > 0 then
        LC.ResistanceFundTake(n, (onlyGuns and #guns > 0) and GunLine(guns) or "Bought at the quartermaster's", { ply })
        LC.AddCredits(ply, n)
    end
    if #guns > 0 and not (onlyGuns and n > 0) then Note(GunLine(guns), { ply }) end
end

-- A sale from his window: paid out of the fund; what it can't pay he makes up in trade (his barter, with it
-- on their side). true when sold; false, nil, true when the barter opened instead.
function LC.QuartermasterBuy(ply, id, all)
    if not LC.QuartermasterDealer(ply) or not isstring(id) then return false end
    local price = LC.QuartermasterBuyPrice(ply, id)
    if not price then return false end
    local n
    local cls = string.match(id, "^w:(.+)$")
    if cls then
        if not ply:HasWeapon(cls) or (LC.IsIssuedWeapon and LC.IsIssuedWeapon(ply, cls)) then return false end
        n = 1
    else
        local have = math.floor(tonumber(LC.Inventory(ply)[id]) or 0)
        if have < 1 then return false end
        n = all and have or 1
    end
    Seed()
    if price * n > Fund() then
        LC.BarterOpen(ply, { [id] = n })
        return false, nil, true
    end
    if not Hand(ply, id, n) then return false end
    PayOut(ply, price * n, { { id = id, n = n } })
    Took(ply, id, n)
    return true
end

-- The gun run's crate at his post: RUN_PAY out of the fund, and its guns on the shelf. When the fund can't pay
-- it, the crate stays in their pockets and his barter opens with it on their side. true when paid.
function LC.QuartermasterGunRun(ply, item)
    if not (IsValid(ply) and RUN_ITEMS[item] and LC.HasItem(ply, item)) then return false end
    Seed()
    if Fund() < RUN_PAY then
        if LC.QuartermasterDealer(ply) then LC.BarterOpen(ply, { [item] = 1 }) end
        return false
    end
    LC.TakeItem(ply, item, 1)
    LC.ResistanceFundTake(RUN_PAY, "A crate of guns, brought in", { ply })
    LC.AddCredits(ply, RUN_PAY, "gun run")
    Took(ply, item, 1)
    return true
end

-- A gun given to him goes on the shelf too (no credits: he says what he always said).
hook.Add("LivingCityQuartermasterGift", "LivingCityArmory", function(ply, id)
    local gun = GunOf(id)
    if gun then
        LC.Try(function()
            LC.ArmoryAdd(gun, 1)
            Note(GunLine({ gun }), { ply })
        end)
    end
end)

------------------------------------------------------------------------
-- Goodwill: how far he lets a trade go short
------------------------------------------------------------------------

function LC.GoodwillFull(ply)
    if not IsValid(ply) then return 0 end
    if Faction(ply) == "resistance" then
        return GOODWILL[math.Clamp(ply:GetNW2Int("lcf_rank", 1), 1, #GOODWILL)] or 0
    end
    local sym = LC.Trait and tonumber(LC.Trait(ply, "sympathy")) or 0
    return math.Clamp(math.floor(sym / SYMPATHY_PER), 0, OUTSIDER_MAX)
end

-- What is left of it now (a fraction while it fills), and its full size.
function LC.Goodwill(ply, now)
    local full = LC.GoodwillFull(ply)
    if full <= 0 then return 0, 0 end
    now = now or os.time()
    local left, at = string.match(tostring(ply:GetPData(KEY, "") or ""), "^([%d%.]+):(%d+)$")
    left, at = tonumber(left), tonumber(at)
    if not left or not at then return full, full end
    left = math.min(full, left + full * math.max(0, now - at) / REFILL)
    return math.max(0, left), full
end

-- Spend n whole credits of it: true, or false when that much isn't left.
function LC.GoodwillSpend(ply, n, now)
    n = math.floor(tonumber(n) or 0)
    if n <= 0 then return true end
    now = now or os.time()
    local left = LC.Goodwill(ply, now)
    if math.floor(left + 1e-9) < n then return false end
    ply:SetPData(KEY, string.format("%.4f:%d", math.max(0, left - n), now))
    return true
end

hook.Add("LivingCityNewCharacter", "LivingCityGoodwill", function(ply) ply:RemovePData(KEY) end) -- (someone new starts afresh)

------------------------------------------------------------------------
-- Barter
------------------------------------------------------------------------

-- His stock, at what he charges this player (strangers: nothing, he sells them nothing). Things only, and a
-- tool they don't carry already; not what's sold out.
local function Stock(ply)
    local out = {}
    if LC.QuartermasterDealer(ply) ~= "member" then return out end
    for _, g in ipairs(LC.MarketBlackList and LC.MarketBlackList() or LCS.Black or {}) do
        local thing = (g.item and LCS.Items[g.item]) or (g.weapon and not g.ammo and not ply:HasWeapon(g.weapon))
        if not g.lab and thing then
            local left = LC.BlackStockLeft and LC.BlackStockLeft(g) or nil
            local max = g.weapon and 1 or math.min(MAX_EACH, left or MAX_EACH)
            if max > 0 then out[#out + 1] = { id = g.id, name = g.name, price = LC.MarketPrice(ply, g), max = max, g = g, left = left } end
        end
    end
    return out
end

function LC.BarterOffer(ply)
    local left, full = LC.Goodwill(ply)
    local his = {}
    for _, s in ipairs(Stock(ply)) do his[#his + 1] = { id = s.id, name = s.name, price = s.price, max = s.max } end
    return { yours = Wants(ply), his = his, credits = LC.Credits and LC.Credits(ply) or 0, fund = Fund(),
        goodwill = math.floor(left * 100) / 100, full = full }
end

-- The view (pre: what to put on their side to start with, { [id] = n }; status: the one refusal line).
function LC.BarterOpen(ply, pre, status)
    if not LC.QuartermasterDealer(ply) then return false end
    Seed()
    local t = LC.BarterOffer(ply)
    t.pre, t.status = istable(pre) and pre or nil, isstring(status) and status ~= "" and status or nil
    LC.SendCompressed("lc_barter", t, { ply })
    return true
end

-- Will it all fit, once theirs has gone? (Papers take no room.)
local function Fits(ply, give, get)
    local dKg, dBulky, dCount = 0, 0, 0
    local function Add(item, n, sign)
        local it = LCS.Items[item]
        if not it or it.doc then return end
        dKg = dKg + sign * LCS.Weight(item) * n
        if LCS.IsBulky(item) then dBulky = dBulky + sign * n end
        dCount = dCount + sign * n
    end
    for _, x in ipairs(give) do if not string.match(x.id, "^w:") then Add(x.id, x.n, -1) end end
    for _, x in ipairs(get) do if x.g.item then Add(x.g.item, x.n * (x.g.count or 1), 1) end end
    local weighed = GetConVar("lc_inventory_weight")
    if weighed and not weighed:GetBool() then
        local size = GetConVar("lc_inventory_size")
        return dCount <= 0 or LC.InvCount(ply) + dCount <= (size and size:GetInt() or 12)
    end
    local maxKg, maxBulky = LC.CarryLimit(ply)
    if dKg > 0.001 and LC.InvWeight(ply) + dKg > maxKg + 0.001 then return false end
    if dBulky > 0 and LC.InvBulky(ply) + dBulky > maxBulky then return false end
    return true
end

-- A trade. offer = { yours = { [id] = n }, his = { [id] = n }, credits = n from their pocket }. Everything is
-- worked out again here from what is really in their pockets and his stock. true, or false and the one line
-- the view shows (nil: nothing to say, the view just shows things as they are).
function LC.BarterTrade(ply, offer)
    if not LC.QuartermasterDealer(ply) or not istable(offer) then return false end
    if (ply.lcBarterNext or 0) > CurTime() then return false end
    ply.lcBarterNext = CurTime() + GAP
    Seed()
    -- theirs
    local wants = {}
    for _, w in ipairs(Wants(ply)) do wants[w.id] = w end
    local give, Y = {}, 0
    for id, n in pairs(istable(offer.yours) and offer.yours or {}) do
        n = math.floor(tonumber(n) or 0)
        if n > 0 then
            local w = isstring(id) and wants[id]
            if not w or n > w.n then return false end
            give[#give + 1] = { id = id, n = n }
            Y = Y + w.price * n
        end
    end
    if #give == 0 then return false end -- (a barter gives something of theirs)
    -- his
    local stock = {}
    for _, s in ipairs(Stock(ply)) do stock[s.id] = s end
    local get, H = {}, 0
    for id, n in pairs(istable(offer.his) and offer.his or {}) do
        n = math.floor(tonumber(n) or 0)
        if n > 0 then
            local s = isstring(id) and stock[id]
            if not s or n > s.max then return false end
            get[#get + 1] = { id = id, n = n, g = s.g, left = s.left }
            H = H + s.price * n
        end
    end
    -- the credits, and the difference
    local credits = math.floor(tonumber(offer.credits) or 0)
    if credits < 0 then return false end
    if credits > (LC.Credits(ply) or 0) then return false, SHORT end
    local paidIn = math.min(credits, math.max(0, H - Y))
    local short = H - Y - paidIn
    local paidOut = 0
    if short > 0 then
        if math.floor(LC.Goodwill(ply) + 1e-9) < short then return false end
    else
        paidOut = math.min(-short, Fund()) -- (as far as the fund can)
        short = 0
    end
    if not Fits(ply, give, get) then return false, HEAVY end
    if short > 0 and not LC.GoodwillSpend(ply, short) then return false end
    -- it all moves
    local took = {}
    for _, x in ipairs(give) do if Hand(ply, x.id, x.n) then took[#took + 1] = x end end
    for _, x in ipairs(get) do
        local g = x.g
        if g.item then
            for _ = 1, x.n do
                if not LC.GiveItem(ply, g.item, g.count or 1) and LC.SpawnWorldItem then
                    for _ = 1, g.count or 1 do LC.SpawnWorldItem(g.item, ply:GetPos() + ply:GetForward() * 30 + Vector(0, 0, 10)) end
                end
            end
        elseif g.weapon then ply:Give(g.weapon) end
        if x.left and g.stock == "stim" and LC.BlackStock and LC.BlackStock.stim then LC.BlackStock.stim.n = math.max(0, x.left - x.n) end
        if LC.MarketBought then for _ = 1, x.n do LC.MarketBought(g, "black") end end
    end
    if paidIn > 0 then
        LC.AddCredits(ply, -paidIn)
        LC.QuartermasterPaid(ply, paidIn)
    end
    PayOut(ply, paidOut, took)
    if short > 0 then Note(string.format("Let %d credit%s go", short, short == 1 and "" or "s"), { ply }) end
    for _, x in ipairs(took) do Took(ply, x.id, x.n) end
    return true
end

net.Receive("lc_barter", function(_, ply)
    local op = net.ReadUInt(2)
    if op == 1 then
        if (ply.lcBarterOpenNext or 0) > CurTime() then return end
        ply.lcBarterOpenNext = CurTime() + OPEN_GAP
        local okO, err = LC.Try(LC.BarterOpen, ply)
        if not okO and LC.Error then LC.Error("the quartermaster's barter (opening it)", err) end
    elseif op == 2 then
        local offer = { credits = net.ReadUInt(32) or 0, yours = {}, his = {} }
        for _, side in ipairs({ "yours", "his" }) do
            for _ = 1, math.min(net.ReadUInt(8) or 0, MAX_ROWS) do
                local id = net.ReadString() or ""
                offer[side][id] = (offer[side][id] or 0) + (net.ReadUInt(16) or 0)
            end
        end
        local okT, done, why = LC.Try(LC.BarterTrade, ply, offer)
        if not okT and LC.Error then LC.Error("the quartermaster's barter (a trade)", done) end
        if LC.QuartermasterDealer(ply) then LC.BarterOpen(ply, nil, okT and not done and why or nil) end
    end
end)
