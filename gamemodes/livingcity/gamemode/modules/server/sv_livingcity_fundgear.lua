--[[
    Living City: what the Resistance's fund buys, its record, and its screen in the camp

    The owner, 19 November: "I think the funds should be for the equipment issued to fighters, such
    as ammo, weapons, etc. obviously those are provided by the fund, which 'purchases' them at a
    reduced price versus what a player pays." When it is empty: "only what the fund can afford; if
    the fund cannot afford it then give them a cheaper/downgraded weapon that can be afforded.
    Crowbars are free (or rather, incur no cost from the fund). There needs to be ways for the
    spawning player to understand this ... the Resistance fund numbers on the small TV as an entity?
    and pressing E on it lets you review the charges/costs and additions to the fund and where they
    are coming from as a little popup window? ... our little small TV with the fund amount on it can
    also have an option for 'Donate'". And: "an option for people to donate to the resistance by
    talking to resistance members ... I don't want to make MORE windows or more menus".

    The gear   Each time a Resistance player is issued their rank's guns and rounds (on spawn, and the
               guns a promotion adds), the fund buys each gun and its rounds at the price a player pays
               the quartermaster, times lc_resistance_issue_rate (22, per cent; 0: free, as before;
               22 so a Fighter's full kit costs the fund about 50: the owner, 19 November, "we should
               lower the cost of restoring/supplying a fighter from 239 down to like 50").
               A gun the armory holds (guns sold or given to the quartermaster, sv_livingcity_armory.lua)
               comes off its shelf first, at no cost; the fund buys only what it lacks.
               A gun the quartermaster doesn't sell is priced at the unit counter's (the pulse rifle,
               300, and its rounds). The dearest gun first, with its rounds, then the next. A gun it
               can't pay for: the best cheaper gun it can pay for instead (pulse rifle, revolver,
               shotgun, SMG, pistol); none at all: the crowbar alone. The crowbar, fists and the roles'
               own tools cost nothing. Rounds: what it can pay for, up to the usual number (less what
               they carry already). Nothing is taken back, nothing they carry is charged, and the
               rounds of kinds their rank's guns don't use come as before, as for everyone. The
               city's own Resistance NPCs cost it nothing (they are never issued anything here).
    Starting   START (250) is put in once, the first time a map's ledger is seen without a record,
               so a server doesn't send every fighter out with a crowbar the day this is installed.
    The record Every change to the fund is one entry: when, how much, a short line in plain words
               ("A load from a supply convoy (Kerr)"). A fighter sent out short (a cheaper gun, or the
               crowbar alone) is an entry too, at no cost. Kept with the fund in the ledger
               ("fundLog" in data/livingcity/<map>_city.json), the newest KEEP (50).
    The screen A fixture placed with the editor ("Fixture: Resistance fund screen"): the apartment's
               small TV, the fund's number on it. E on it: one small window, the number, the newest
               SHOW (15) entries and three Donate buttons (DONATE). Anyone who can reach it.
    Donating   At the screen (10, 50 or 100), or 10 (TALK_GIFT) from the quartermaster's own window
               (cl_livingcity_needs.lua), a member's or a stranger's: from the pocket to the fund, the
               entry "A donation", with the donor's name only if they are of the Resistance.
               Refused when the pocket is short ("You don't have that much.", in the window), from
               too far away or too fast (silently).

    Nothing is said in chat or on screen when gear is bought or a fighter goes out short: the
    screen's record is where it shows.

    LC.FundIssue(ply, kit, keep)       the kit to give and the rounds of each kind (sv_livingcity_factions.lua)
    LC.FundGunPrice(cls), LC.FundRoundPrice(kind)   what a player pays (before the rate)
    LC.ResistanceFundRecord(n, why, who)            one entry (sv_livingcity_resistancefund.lua calls it)
    LC.ResistanceFundLog(n)            the newest n entries, newest first: { t, n, w }
    LC.FundScreenOpen(ply, tv, status) the window
    LC.FundDonate(ply, amount, atQM)   a donation: true, or false and why

    Setting: lc_resistance_issue_rate (22). Net: lc_fundtv (the window), lc_fund_donate (a donation).
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_fundtv")
util.AddNetworkString("lc_fund_donate")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvRate = CreateConVar("lc_resistance_issue_rate", "22", FLAGS,
    "What the Resistance's fund pays for each gun and round its players are issued by rank, in per cent of the quartermaster's price (0: issued free, the fund pays nothing)", 0, 1000)

local START = 250        -- put in once, the first time a map's ledger is seen with no record (the owner, 19 November:
                         -- "it means the resistance could just order an assassination in the first 5 minutes ... the
                         -- resistance should start with like 250"; it was 1000 for a day)
local FIRST_START = 1000 -- what that first day's version put in, taken back to START once (fundStart in the ledger)
local KEEP = 50          -- entries kept in the record
local SHOW = 15          -- entries the screen's window shows
local DONATE = { 10, 50, 100 } -- the screen's three amounts
local TALK_GIFT = 10     -- a donation from the quartermaster's window
local REACH = 150        -- how close to the screen to use it
local GAP = 1            -- seconds between one donation and the next
-- Rounds are almost free to the fund (the owner, 19 November: "rounds should be MUCH cheaper, almost free"): a tenth
-- of the gun's rate, so at lc_resistance_issue_rate 22 a round costs the fund 2.2 per cent of the quartermaster's price.
local ROUND_SHARE = 0.1
-- A donation earns sympathy toward joining (the owner, 19 November: "yes yes yes, scaling (without allowing abuse) to
-- the amount donated"): one for every SYMP_PER credits given, at most SYMP_DAY in a real day, for someone who is not
-- of the Resistance or the Combine; kept with the character (what they gave, what it has earned, the day's count).
local SYMP_PER, SYMP_DAY = 25, 2
local SHORT = "You don't have that much."
local WHO = "a fighter"  -- who the gear went to, in the record
local LINE_MAX = 120

-- The guns the fund buys, the rounds each takes, and what the record calls it.
local GUNS = {
    weapon_ar2 = { ammo = "AR2", name = "a pulse rifle" },
    weapon_357 = { ammo = "357", name = "a revolver" },
    weapon_shotgun = { ammo = "Buckshot", name = "a shotgun" },
    weapon_smg1 = { ammo = "SMG1", name = "an SMG" },
    weapon_pistol = { ammo = "Pistol", name = "a pistol" },
}
LC.FundGuns = GUNS

-- What the record says for a change some other code made (its "why").
local LORE = {
    load = "A load from a supply convoy",
    raid = "A supply drop raided",
    run = "A crate of the Union's supplies, brought home",
    saved = "A gift from someone we got out",
    ["the leader's order"] = "An order, paid for",
    ["an order ended before the attempt"] = "An order called off, paid back",
    start = "What the cells had put by",
    donation = "A donation",
}

local function Ours(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "resistance" end
local function Book() return LC.Ledger and LC.Ledger() or nil end
local function Rate() return math.max(0, cvRate:GetFloat()) / 100 end
local function Cap(s) return (string.gsub(s, "^%l", string.upper)) end

------------------------------------------------------------------------
-- What a player pays for each
------------------------------------------------------------------------

local function Stock() return LC.MarketBlackList and LC.MarketBlackList() or LCS.Black or {} end
local function QMPrice(g) return LC.QuartermasterPrice and LC.QuartermasterPrice(g) or g.price end

-- A gun: the quartermaster's price, or, for one he doesn't sell, the unit counter's.
function LC.FundGunPrice(cls)
    local best
    for _, g in ipairs(Stock()) do
        local it = g.item and LCS.Items[g.item]
        if not g.lab and (g.weapon == cls or (it and it.weapon == cls)) then best = math.min(best or math.huge, QMPrice(g)) end
    end
    if best then return best end
    for _, g in ipairs(LCS.Goods or {}) do
        if g.weapon == cls and not g.ammo then best = math.min(best or math.huge, g.price) end
    end
    return best or (LCS.SellWeapons and LCS.SellWeapons[cls] or 50) * 2
end

-- One round of a kind: the quartermaster's box, divided by what it holds; or the unit counter's.
function LC.FundRoundPrice(kind)
    local best
    for _, g in ipairs(Stock()) do
        local it = g.item and LCS.Items[g.item]
        if not g.lab and it and it.use == "ammo" and istable(it.ammo) and it.ammo[1] == kind and (it.ammo[2] or 0) > 0 then
            best = math.min(best or math.huge, QMPrice(g) / (it.ammo[2] * (g.count or 1)))
        end
    end
    if best then return best end
    for _, g in ipairs(LCS.Goods or {}) do
        if istable(g.ammo) and g.ammo[1] == kind and not g.weapon and (g.ammo[2] or 0) > 0 then best = math.min(best or math.huge, g.price / g.ammo[2]) end
    end
    return best or 1
end

local function Cost(price) return math.max(0, math.floor(price * Rate() + 0.5)) end

-- How many of `need` rounds at `per` each the budget pays for, and what they cost (whole credits).
local function Afford(need, per, budget)
    if need <= 0 or budget <= 0 then return 0, 0 end
    if per <= 0 then return need, 0 end
    local n = math.min(need, math.floor(budget / per + 1e-9))
    while n > 0 and math.ceil(n * per - 1e-9) > budget do n = n - 1 end
    return n, n > 0 and math.ceil(n * per - 1e-9) or 0
end

local function Usual(kind)
    for _, r in ipairs(LC.SpawnRounds or {}) do if r[1] == kind then return r[2] end end
    return 0
end

local function Names(list) -- "a shotgun", "a shotgun and an SMG", "a shotgun, an SMG and a pistol"
    if #list <= 1 then return list[1] or "" end
    return table.concat(list, ", ", 1, #list - 1) .. " and " .. list[#list]
end

------------------------------------------------------------------------
-- The record
------------------------------------------------------------------------

-- Who it was for, of ours, by name: "(Kerr)", "(Kerr, Vance)", "(Kerr and others)".
local function NamesOf(who)
    local names, seen = {}, {}
    for _, p in pairs(istable(who) and who or {}) do
        if Ours(p) and not seen[p] then
            seen[p] = true
            names[#names + 1] = LC.CharacterName and LC.CharacterName(p) or p:Nick()
        end
    end
    if #names == 0 then return "" end
    if #names <= 2 then return " (" .. table.concat(names, ", ") .. ")" end
    return " (" .. names[1] .. " and others)"
end

local function Log()
    local book = Book()
    if not book then return nil end
    if not istable(book.fundLog) then book.fundLog = {} end
    return book.fundLog
end

-- One entry: n credits (0: something it couldn't pay for), why (a code's word, or the line itself), who.
function LC.ResistanceFundRecord(n, why, who)
    local log = Log()
    if not log then return end
    local w = isstring(why) and (LORE[why] or Cap(why)) or ""
    w = string.sub(w .. NamesOf(who), 1, LINE_MAX)
    log[#log + 1] = { t = os.time(), n = math.floor(tonumber(n) or 0), w = w }
    while #log > KEEP do table.remove(log, 1) end
    if SetGlobal2Int then SetGlobal2Int("lc_fund", LC.ResistanceFund and LC.ResistanceFund() or 0) end
end

-- An entry that moves nothing, written at once (who: the players it was for, named if they are ours).
local function Note(line, who)
    LC.ResistanceFundRecord(0, line, who)
    if LC.LedgerSave then LC.Try(LC.LedgerSave) end
end

-- The newest n entries, newest first.
function LC.ResistanceFundLog(n)
    local log, out = Log() or {}, {}
    for i = #log, math.max(1, #log - (n or KEEP) + 1), -1 do
        local e = log[i]
        if istable(e) then out[#out + 1] = { t = tonumber(e.t) or 0, n = math.floor(tonumber(e.n) or 0), w = tostring(e.w or "") } end
    end
    return out
end

-- The starting fund, once for a map's ledger (its record is what marks it done).
function LC.FundSeed()
    local book = Book()
    if not book then return false end
    if istable(book.fundLog) then
        -- (a map seeded with the first day's 1000: brought down to START once, quietly, and its entry with it)
        if book.fundStart == nil then
            book.fundStart = START
            for _, e in ipairs(book.fundLog) do
                if e.n == FIRST_START and e.w == LORE.start then
                    e.n = START
                    local back = math.min(FIRST_START - START, LC.ResistanceFund and LC.ResistanceFund() or 0)
                    if back > 0 then book.fund = math.max(0, (tonumber(book.fund) or 0) - back) end
                    if SetGlobal2Int then SetGlobal2Int("lc_fund", LC.ResistanceFund and LC.ResistanceFund() or 0) end
                    break
                end
            end
            if LC.LedgerSave then LC.Try(LC.LedgerSave) end
        end
        return false
    end
    book.fundLog = {}
    book.fundStart = START
    if LC.ResistanceFundAdd then LC.ResistanceFundAdd(START, "start") end
    if LC.LedgerSave then LC.Try(LC.LedgerSave) end
    return true
end
local Seed = LC.FundSeed

------------------------------------------------------------------------
-- The gear
------------------------------------------------------------------------

local issued = setmetatable({}, { __mode = "k" }) -- [ply] = { [class] = true }: guns the fund bought outside their rank's kit

-- A cheaper gun the fund bought in place of one counts as issued (it can't be sold for the fund's credits).
function LC.FundIssuedWeapon(ply, cls) return issued[ply] ~= nil and issued[ply][cls] == true end

-- The kit to give a Resistance player (kit: their rank's loadout; keep: a promotion's top-up) and the
-- rounds of each kind (nil: the usual). Anyone else, or nothing to buy: the kit as it was.
function LC.FundIssue(ply, kit, keep)
    if not Ours(ply) or not istable(kit) or Rate() <= 0 then return kit end
    local guns, out = {}, {}
    for _, cls in ipairs(kit) do
        if GUNS[cls] then guns[#guns + 1] = cls else out[#out + 1] = cls end
    end
    if #guns == 0 then return kit end
    Seed()
    table.sort(guns, function(a, b)
        local pa, pb = LC.FundGunPrice(a), LC.FundGunPrice(b)
        if pa ~= pb then return pa > pb end
        return a < b
    end)
    local inKit = {}
    for _, cls in ipairs(kit) do inKit[cls] = true end
    local budget = LC.ResistanceFund()
    local spent, rounds, got, bought, standIns, without, anyRounds = 0, {}, {}, {}, {}, {}, false
    local fromArmory = {} -- (guns off the armory's shelf, first and at no cost: sv_livingcity_armory.lua)
    local function Has(cls) return got[cls] or (keep and ply:HasWeapon(cls)) end
    local function Shelf(cls) return LC.ArmoryCount and LC.ArmoryCount(cls) or 0 end
    for _, cls in ipairs(guns) do rounds[GUNS[cls].ammo] = 0 end -- (the rank's own kinds: what the fund buys, and no more)
    if not keep then issued[ply] = nil end
    for _, cls in ipairs(guns) do
        if not Has(cls) then
            local pick, cap = cls, LC.FundGunPrice(cls)
            local free = Shelf(cls) > 0
            if not free and Cost(cap) > budget - spent then
                pick = nil
                local bestP
                for c in pairs(GUNS) do
                    local p = LC.FundGunPrice(c)
                    if p < cap and not Has(c) and (Shelf(c) > 0 or Cost(p) <= budget - spent) and (not bestP or p > bestP or (p == bestP and c < pick)) then pick, bestP = c, p end
                end
                if pick then free = Shelf(pick) > 0 standIns[#standIns + 1] = { pick, cls } else without[#without + 1] = GUNS[cls].name end
            end
            if pick then
                if free and LC.ArmoryTake and LC.ArmoryTake(pick, 1) then
                    fromArmory[#fromArmory + 1] = pick
                else
                    spent = spent + Cost(LC.FundGunPrice(pick))
                    bought[#bought + 1] = pick
                end
                got[pick] = true
                out[#out + 1] = pick
                if not inKit[pick] then issued[ply] = issued[ply] or {} issued[ply][pick] = true end
                if not keep and rounds[GUNS[pick].ammo] then -- (a kind of round the rank's guns don't use comes as before)
                    local kind = GUNS[pick].ammo
                    local need = math.max(0, Usual(kind) - (ply:GetAmmoCount(kind) or 0) - (rounds[kind] or 0))
                    local n, c = Afford(need, LC.FundRoundPrice(kind) * Rate() * ROUND_SHARE, budget - spent)
                    if n > 0 then rounds[kind] = (rounds[kind] or 0) + n spent = spent + c anyRounds = true end
                end
            end
        end
    end
    local none = not keep and #bought == 0 and #fromArmory == 0
    if none and not inKit.weapon_crowbar then out[#out + 1] = "weapon_crowbar" end -- (nothing it could pay for: the crowbar, which costs it nothing)
    -- what it paid, one entry; what they went without, at no cost
    if spent > 0 then
        local what
        if #bought == 1 then what = Cap(GUNS[bought[1]].name) .. (anyRounds and " and ammunition" or "")
        elseif #bought > 1 then what = anyRounds and "Guns and ammunition" or "Guns"
        else what = "Ammunition" end
        LC.ResistanceFundTake(spent, what .. " for " .. WHO, { ply })
    end
    -- what came off the armory's shelf, at no cost: "A pistol from the armory, for a fighter (Kerr)"
    if #fromArmory == 1 then Note(Cap(GUNS[fromArmory[1]].name) .. " from the armory, for " .. WHO, { ply })
    elseif #fromArmory > 1 then Note(Cap(WHO) .. " armed from the armory", { ply }) end
    if none then
        Note(Cap(WHO) .. " went out with only a crowbar. The fund was empty.")
    else
        for _, s in ipairs(standIns) do Note(string.format("%s got %s, not %s. The fund was short.", Cap(WHO), GUNS[s[1]].name, GUNS[s[2]].name)) end
        if #without > 0 then Note(string.format("%s went without %s. The fund was short.", Cap(WHO), Names(without))) end
    end
    return out, (not keep) and rounds or nil
end

------------------------------------------------------------------------
-- The screen, and donating
------------------------------------------------------------------------

local function Near(ply, tv)
    return IsValid(ply) and ply:IsPlayer() and ply:Alive() and IsValid(tv) and tv:GetClass() == "lc_fundtv"
        and ply:GetPos():DistToSqr(tv:GetPos()) <= REACH * REACH
end

-- The window: the fund, its newest entries, the amounts to donate, and a refusal if there was one.
function LC.FundScreenOpen(ply, tv, status)
    if not Near(ply, tv) then return false end
    Seed()
    ply.lcFundTV = tv
    local log = LC.ResistanceFundLog(SHOW)
    net.Start("lc_fundtv")
    net.WriteUInt(LC.ResistanceFund(), 32)
    net.WriteUInt(#log, 8)
    for _, e in ipairs(log) do net.WriteInt(e.n, 32) net.WriteString(e.w) end
    net.WriteUInt(#DONATE, 4)
    for _, a in ipairs(DONATE) do net.WriteUInt(a, 16) end
    net.WriteString(status or "")
    net.Send(ply)
    return true
end

local okAmount = {}
for _, a in ipairs(DONATE) do okAmount[a] = true end

-- A donation: at the screen they last opened (atQM false), or from the quartermaster's window (atQM true).
function LC.FundDonate(ply, amount, atQM)
    if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return false end
    if (ply.lcFundGiveNext or 0) > CurTime() then return false, "too fast" end
    ply.lcFundGiveNext = CurTime() + GAP
    amount = math.floor(tonumber(amount) or 0)
    local tv = ply.lcFundTV
    if atQM then
        if amount ~= TALK_GIFT then return false end
        local at = (Ours(ply) and LC.AtQuartermaster and LC.AtQuartermaster(ply)) or (LC.QuartermasterVisitor and LC.QuartermasterVisitor(ply))
        if not at or (LC.IsBurned and LC.IsBurned(ply)) then return false, "too far" end
    else
        if not Near(ply, tv) then return false, "too far" end
        if not okAmount[amount] then return false end
    end
    if (LC.Credits and LC.Credits(ply) or 0) < amount then
        if not atQM then LC.FundScreenOpen(ply, tv, SHORT) end
        return false, SHORT
    end
    Seed()
    LC.AddCredits(ply, -amount)
    LC.ResistanceFundAdd(amount, "donation", { ply })
    LC.FundDonationSympathy(ply, amount)
    if atQM then
        if LC.OpenMarket then LC.OpenMarket(ply) end
    else
        LC.FundScreenOpen(ply, tv)
    end
    return true
end
LC.FundDonateAmounts, LC.FundTalkGift = DONATE, TALK_GIFT
LC.FundRoundShare, LC.FundSympathyPer, LC.FundSympathyDay = ROUND_SHARE, SYMP_PER, SYMP_DAY

-- What a donation earns toward joining. Every credit given counts toward the next sympathy, also those given past
-- the day's cap (they are earned on a later day). How many were given now.
function LC.FundDonationSympathy(ply, amount)
    if not (IsValid(ply) and ply:IsPlayer() and LC.AddTrait) then return 0 end
    local f = ply:GetNW2String("lcf_faction", "")
    if f == "resistance" or f == "cp" or f == "admin" or (LC.IsBurned and LC.IsBurned(ply)) then return 0 end
    local given = (tonumber(ply:GetPData("lc_fund_given", 0)) or 0) + math.max(0, math.floor(tonumber(amount) or 0))
    ply:SetPData("lc_fund_given", given)
    local got = tonumber(ply:GetPData("lc_fund_symp", 0)) or 0
    local day = math.floor(os.time() / 86400)
    local today = (tonumber(ply:GetPData("lc_fund_symp_day", -1)) == day) and (tonumber(ply:GetPData("lc_fund_symp_n", 0)) or 0) or 0
    local n = math.max(0, math.min(math.floor(given / SYMP_PER) - got, SYMP_DAY - today))
    if n <= 0 then return 0 end
    LC.AddTrait(ply, "sympathy", n)
    ply:SetPData("lc_fund_symp", got + n)
    ply:SetPData("lc_fund_symp_day", day)
    ply:SetPData("lc_fund_symp_n", today + n)
    return n
end
-- (someone new starts with nothing given)
hook.Add("LivingCityNewCharacter", "LivingCityFundSympathy", function(ply)
    if not IsValid(ply) then return end
    for _, k in ipairs({ "lc_fund_given", "lc_fund_symp", "lc_fund_symp_day", "lc_fund_symp_n" }) do ply:RemovePData(k) end
end)

net.Receive("lc_fund_donate", function(_, ply)
    local amount, atQM = net.ReadUInt(16), net.ReadBool()
    local okD, err = LC.Try(LC.FundDonate, ply, amount, atQM)
    if not okD and LC.Error then LC.Error("the Resistance's fund (a donation)", err) end
end)

-- The number on every screen (and the start, once), kept up to date.
local function Show()
    Seed()
    if SetGlobal2Int then SetGlobal2Int("lc_fund", LC.ResistanceFund and LC.ResistanceFund() or 0) end
end
hook.Add("InitPostEntity", "LivingCityFundGear", function()
    local okS, err = LC.Try(Show)
    if not okS and LC.Error then LC.Error("the Resistance's fund (the start)", err) end
end)
timer.Create("LivingCityFundScreen", 10, 0, function()
    local okS, err = LC.Try(Show)
    if not okS and LC.Error then LC.Error("the Resistance's fund (the screens)", err) end
end)
