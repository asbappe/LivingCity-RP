--[[
    Living City: the Resistance's own money (19 November)

    The owner, 19 November: the Resistance should earn money the way real movements do ("mafia-esque tactics ...
    Making their own bootleg alcohol and selling it to the black market dealer"), and "please be logical ... why
    would anyone deliver things for free"; "killing headcrabs and bringing their corpses home does not magically
    produce credits". And for all of it: "the resistance member doing the deed/act/work gets a maybe 50% cut".
    docs/features/resistance-money.md.

    The still     a fixture ("Fixture: Resistance still", entities/lc_still.lua), in a camp or by the lab. A
                  Resistance member presses E with the makings in their pockets (RECIPE below): they are taken,
                  and it brews for BREW_SECS on its own while they go about their business (steam and a quiet
                  hiss while it works). E when it is done takes the bottles: moonshine, contraband as it always
                  was (a unit's search takes it). Lacking something, one line says the whole recipe.
    The dealer's  the black market sells alcohol only from what players have sold it (the owner: "the black
    drink         market dealer doesn't sell alcohol unless the resistance is doing so"): each bottle sold to
                  the black market adds one to its stock of that drink (goods marked bootleg in LCS.Black), and
                  each it sells takes one. None left: not on his list. Kept with the state of the city
                  (LC.Ledger: "bootleg" in data/livingcity/<map>_city.json), written the moment it changes. His
                  pre-war vodka is gone (gone in LCS.Black: there is none left in the city); the Union's own
                  vodka for exemplary citizens at the Commissary is not touched.
    Selling to    a Resistance member selling the dealer anything whose item carries resistanceSplit (moonshine,
    the dealer    skimmed Union machine parts, forged ration cards) has SHARE of what he pays; the rest goes to
                  the fund. Not at the quartermaster (he is the Resistance's own), and a citizen is paid in full.
                  His window shows each member what they will have.
    His rent      every sale the dealer makes to a player while he stands on rebel ground puts a share of the
                  price in the fund: RENT, RENT_SAFE while the place is safe (no unit within SAFE_REACH, no
                  lockdown), nothing while the Combine hold it (a sweep in that territory, or a unit right
                  there). Nobody is paid for it.
    The paymaster a Union paymaster (a citizen in the Union's blue) walks the shift wages from a loading dock to
                  where people are paid (Labor Assignment, the Commissary, a workplace) with ESCORT Civil
                  Protection units, now and then by day (about every MEAN_MINUTES of play, never sooner than
                  GAP_MINUTES after the last). Killed, he drops his satchel; alive with no unit of his escort
                  within ESCORT_REACH, E on him and he hands it over. WAGES credits in it: from one of ours, half
                  to the fund and half shared among the Resistance's players who took part (the one who took
                  it, those on the job, those who hurt him or his escort); a citizen keeps the whole satchel.
                  The Combine answer as they do a looted supply drop: seen at it, wanted and the units after
                  you; the Resistance's strength in the ledger goes up. The Resistance's job while he walks:
                  "Rob the paymaster" (res_paymaster).
    The card      a fixture ("Fixture: card table", entities/lc_cardtable.lua), for a back room on rebel ground;
    table         off rebel ground it does nothing. E opens one small window: a bet of 5, 10 or 25, and high
                  card against the house (each draws one from a fresh deck; ties go to the house: the player
                  wins 24 hands in 51, the house's edge 3 in 51, about 5.9%). A lost bet goes to the fund; a win
                  is paid out of it at even money. It takes no bet the fund could not pay and still keep FLOOR,
                  so it rests while the fund is low. One hand every RATE seconds at most. Nothing in the chat:
                  the cards and the result are in the window.

    Nothing is said about any of it beyond what was there: no notice, hint, chat line or announcement, but the
    still's one line and the job's posting (as the supply drop's raid job is posted).

    LC.UseStill(ply, still)                  E on the still
    LC.BootlegLeft(item)                     the dealer's stock of a drink
    LC.BootlegAdd(item, n), LC.BootlegTake(item, n)
    LC.DealerSplit(ply, id)                  SHARE when this sale is split with the fund, else nil
    LC.DealerPaysYou(ply, id, price)         what one of it fetches this seller
    LC.DealerSaleSplit(ply, id, n, price)    a sale split: the seller's part (the rest is in the fund)
    LC.DealerRentRate(pos)                   rate, and "safe", "normal", "held" or nil (not rebel ground)
    LC.DealerRent(ply, price, dealer)        his rent on one sale, put in the fund
    LC.StartPaymaster(), LC.EndPaymaster(why), LC.RobPaymaster(ply, ent), LC.Paymaster
    LC.OpenCardTable(ply, table), LC.CardTableDeal(ply, table, bet)

    Hooks run: LivingCityPaymaster (P), LivingCityPaymasterRobbed (robber, take, partakers, P),
    LivingCityPaymasterEnded (P, why). Hooks heard (nothing is answered to any): EntityTakeDamage, OnNPCKilled,
    PlayerUse, LivingCityPlayerUsedNPC. Net: lc_cards (to the player), lc_cards_deal (from the player, checked:
    who, how near, how much, how often). No settings, no commands: the numbers are the constants below.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_cards")
util.AddNetworkString("lc_cards_deal")

------------------------------------------------------------------------
-- The numbers
------------------------------------------------------------------------

-- the still: one batch is BATCH bottles of moonshine
local BATCH = 4              -- bottles a batch makes; an empty bottle goes in for each
local WATER = 2              -- water a batch takes (any bottle or can of water: WATERS)
local FOOD = 1               -- ration food a batch takes (FOODS)
local BREW_SECS = 300        -- how long it brews by itself
local WATERS = { "bottle_dirty", "bottle_clean", "bottle_rain", "water_purified", "can_dirty", "can_clean", "can_rain", "water" }
local FOODS = { "ration", "ration_short" }
-- selling to the dealer
local SHARE = 0.5            -- a Resistance member's part of what the dealer pays for a resistanceSplit item
-- his rent
local RENT, RENT_SAFE = 0.2, 0.3
local SAFE_REACH = 1200      -- no unit nearer than this: safe
local HELD_REACH = 400       -- a unit this near the dealer: the Combine hold it
-- the paymaster
local WAGES = { 80, 200 }    -- credits in his satchel
local ESCORT = 2             -- Civil Protection units walking with him
local ESCORT_REACH = 700     -- none of them nearer than this: his escort is gone
local MEAN_MINUTES = 300     -- about once in this long (the supply convoy: about once in 280 minutes of auto events)
local GAP_MINUTES = 90       -- never sooner than this after the last
local WALK_SECS = 600        -- the longest he walks
local SATCHEL_SECS = 180     -- a satchel left lying this long is picked up by the Union
local PART_REACH = 1500      -- who took part: on the job or had a go at him, and this near
local JOB = "res_paymaster"
local LINE = "A Union paymaster is walking the shift wages across the city with an escort: take his satchel."
-- the card table
local BETS = { 5, 10, 25 }
local RATE = 4               -- seconds between hands, per player
local FLOOR = 50             -- the fund keeps at least this after paying out a win
local TABLE_REACH = 160

local WHY = "your share"     -- what each of ours reads with their credits, as with any of the fund's shares

local function Faction(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") or "" end
local function Ours(p) return Faction(p) == "resistance" end
local function Unit(p) return LC.PlayerIsCP and LC.PlayerIsCP(p) end
local function Name(p) return LC.CharacterName and LC.CharacterName(p) or p:Nick() end
local function Heard(what, fn, ...)
    local okH, err = LC.Try(fn, ...)
    if not okH and LC.Error then LC.Error("the Resistance's money (" .. what .. ")", err) end
end

------------------------------------------------------------------------
-- The still
------------------------------------------------------------------------

local function CountOf(ply, list)
    local n = 0
    for _, id in ipairs(list) do n = n + (LC.Inventory(ply)[id] or 0) end
    return n
end
local function TakeFrom(ply, list, n)
    for _, id in ipairs(list) do
        if n <= 0 then return end
        local have = LC.Inventory(ply)[id] or 0
        local k = math.min(have, n)
        if k > 0 then LC.TakeItem(ply, id, k) n = n - k end
    end
end

LC.StillRecipe = { batch = BATCH, water = WATER, food = FOOD, secs = BREW_SECS, waters = WATERS, foods = FOODS }

-- E on the still. True when something happened (it started, or the bottles were taken).
function LC.UseStill(ply, still)
    if not (IsValid(ply) and IsValid(still)) or not Ours(ply) or not ply:Alive() then return false end
    local b = still.lcBrew
    if b then
        if CurTime() < b.done then return false end -- (still brewing: it hisses on)
        still.lcBrew = nil
        still:SetNW2Float("lc_brew_done", 0)
        if LC.GiveOrDrop then LC.GiveOrDrop(ply, "moonshine", b.n) else LC.GiveItem(ply, "moonshine", b.n) end
        still:EmitSound("physics/glass/glass_bottle_impact_hard" .. math.random(1, 3) .. ".wav", 60)
        hook.Run("LivingCityStillCollected", ply, still, b.n)
        return true
    end
    if CountOf(ply, FOODS) < FOOD or CountOf(ply, WATERS) < WATER or not LC.HasItem(ply, "bottle_empty", BATCH) then
        ply:ChatPrint(string.format("You need a ration packet, %d water and %d empty bottles.", WATER, BATCH))
        return false
    end
    TakeFrom(ply, FOODS, FOOD)
    TakeFrom(ply, WATERS, WATER)
    LC.TakeItem(ply, "bottle_empty", BATCH)
    local done = CurTime() + BREW_SECS
    still.lcBrew = { done = done, n = BATCH, by = ply }
    still:SetNW2Float("lc_brew_done", done) -- (the steam and the hiss while it works: entities/lc_still.lua)
    still:EmitSound("physics/glass/glass_bottle_impact_soft" .. math.random(1, 3) .. ".wav", 55)
    timer.Simple(BREW_SECS, function()
        if IsValid(still) and still.lcBrew and still.lcBrew.done == done then
            still:EmitSound("ambient/machines/steam_release_2.wav", 55, 120) -- (ready: a last sigh of steam)
        end
    end)
    hook.Run("LivingCityStillStarted", ply, still)
    return true
end

------------------------------------------------------------------------
-- The dealer's stock of drink
------------------------------------------------------------------------

local spare = {} -- (with the ledger off: kept until the server stops)
local function Stock()
    local book = LC.Ledger and LC.Ledger() or nil
    if not book then return spare, false end
    if not istable(book.bootleg) then book.bootleg = {} end
    return book.bootleg, true
end
local function Save() if LC.LedgerSave then LC.Try(LC.LedgerSave) end end

-- Drinks the black market sells only from its stock: the items of its goods marked bootleg.
local function Drinks()
    local out = {}
    for _, g in ipairs(LCS.Black or {}) do if g.bootleg and g.item then out[g.item] = true end end
    return out
end
LC.BootlegDrinks = Drinks

function LC.BootlegLeft(item)
    local s = Stock()
    return math.max(0, math.floor(tonumber(s[item]) or 0))
end
function LC.BootlegAdd(item, n)
    n = math.floor(tonumber(n) or 0)
    if n <= 0 or not Drinks()[item] then return LC.BootlegLeft(item) end
    local s, kept = Stock()
    s[item] = LC.BootlegLeft(item) + n
    if kept then Save() end
    return s[item]
end
function LC.BootlegTake(item, n)
    n = math.floor(tonumber(n) or 0)
    local has = LC.BootlegLeft(item)
    if n <= 0 then return true end
    if has < n then return false end
    local s, kept = Stock()
    s[item] = has - n
    if kept then Save() end
    return true
end

------------------------------------------------------------------------
-- Selling to the dealer: half to the fund
------------------------------------------------------------------------

function LC.DealerSplit(ply, id)
    local it = LCS.Items[id or ""]
    if not (it and it.resistanceSplit and Ours(ply)) then return nil end
    if LC.AtQuartermaster and LC.AtQuartermaster(ply) then return nil end -- (the quartermaster is the Resistance's own)
    return SHARE
end
function LC.DealerPaysYou(ply, id, price)
    local s = LC.DealerSplit(ply, id)
    if not s or not price then return price end
    return math.floor(price * s)
end
-- n of it sold at price each: what the seller has; the rest is put in the fund (what does not divide stays there).
function LC.DealerSaleSplit(ply, id, n, price)
    n, price = math.max(0, math.floor(tonumber(n) or 0)), math.max(0, math.floor(tonumber(price) or 0))
    local total = n * price
    local s = LC.DealerSplit(ply, id)
    if not s then return total end
    local yours = n * math.floor(price * s)
    if total - yours > 0 and LC.ResistanceFundAdd then
        local it = LCS.Items[id]
        LC.ResistanceFundAdd(total - yours, string.format("%s%s sold to the dealer (%s)", it.name, n > 1 and (" x" .. n) or "", Name(ply)))
    end
    return yours
end

------------------------------------------------------------------------
-- The dealer's rent
------------------------------------------------------------------------

local function UnitNear(pos, r)
    local r2 = r * r
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and Unit(p) and p:GetPos():DistToSqr(pos) < r2 then return true end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and LC.IsSecurity and LC.IsSecurity(st) and npc:GetPos():DistToSqr(pos) < r2 then return true end
    end
    return false
end
local function SweptHere(pos)
    local sk = LC.Skirmish
    local z = istable(sk) and sk.kind == "sweep" and sk.zone or nil
    return istable(z) and z.pos ~= nil and pos:Distance(z.pos) < (tonumber(z.r) or 0) + 800
end

function LC.DealerRentRate(pos)
    if not (pos and LC.InRebelZone and LC.InRebelZone(pos)) then return 0, nil end
    if SweptHere(pos) or UnitNear(pos, HELD_REACH) then return 0, "held" end
    if LC.Event == "lockdown" or UnitNear(pos, SAFE_REACH) then return RENT, "normal" end
    return RENT_SAFE, "safe"
end
function LC.DealerRent(ply, price, dealer)
    local pos = (IsValid(dealer) and dealer:GetPos()) or (IsValid(ply) and ply:GetPos()) or nil
    local rate = LC.DealerRentRate(pos)
    local n = math.floor((tonumber(price) or 0) * rate)
    if n > 0 and LC.ResistanceFundAdd then LC.ResistanceFundAdd(n, "The dealer's rent") end
    return n
end

------------------------------------------------------------------------
-- The paymaster
------------------------------------------------------------------------

LC.Paymaster = LC.Paymaster or nil -- { npc, escort = {}, goal, wages, startT, hurtBy = {}, satchel }
local lastPaymaster = -math.huge

local function Walk(npc, pos, run)
    if not (IsValid(npc) and npc.SetLastPosition) then return end
    npc:SetLastPosition(pos)
    npc:SetSchedule(run and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
end
local function Pick(t) return t[math.random(#t)] end

-- From a loading dock (or the street) to where people are paid: Labor Assignment, the Commissary, a workplace.
local function Route()
    local from
    local docks = LC.PointsOfKind and LC.PointsOfKind("dock") or {}
    if #docks > 0 then from = Pick(docks).pos end
    from = from or (LC.SupplyDropSpot and LC.SupplyDropSpot())
    if not from then return nil end
    local best, bd
    for _, kind in ipairs({ "laborterm", "terminal", "work" }) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) do
            local d = p.pos:Distance(from)
            if d > 800 and not (LC.InRebelZone and LC.InRebelZone(p.pos)) and (not bd or d > bd) then best, bd = p.pos, d end
        end
        if best then break end
    end
    if not best then
        for _ = 1, 10 do
            local p = LC.SupplyDropSpot and LC.SupplyDropSpot()
            if p and p:Distance(from) > 1200 then best = p break end
        end
    end
    return from, best or (from + Vector(1500, 0, 0))
end

-- The Resistance's players who took part: the one who took it, those on the job, those who had a go at him or his
-- escort; each once, alive and near.
local function Partakers(P, robber)
    local out, seen = {}, {}
    local at = (IsValid(P.npc) and P.npc:GetPos()) or (IsValid(P.satchel) and P.satchel:GetPos()) or (IsValid(robber) and robber:GetPos())
    local function add(p)
        if Ours(p) and not seen[p] and p:Alive() and (p == robber or (at and p:GetPos():DistToSqr(at) < PART_REACH * PART_REACH)) then
            seen[p] = true
            out[#out + 1] = p
        end
    end
    add(robber)
    for p, q in pairs(LC.QuestOf or {}) do
        if IsValid(p) and istable(q) and not q.done and istable(q.tmpl) and q.tmpl.id == JOB then add(p) end
    end
    for p in pairs(P.hurtBy or {}) do if IsValid(p) then add(p) end end
    return out
end

local function Jobs(fn)
    for p, q in pairs(LC.QuestOf or {}) do
        if IsValid(p) and istable(q) and not q.done and istable(q.tmpl) and q.tmpl.id == JOB then fn(p, q) end
    end
end
local function Mark(ent) -- (where the job's marker points: him, or the satchel he dropped)
    Jobs(function(_, q)
        local st = q.stages and q.stages[q.stage]
        if st and st.event == "paymaster_robbed" and st.npc ~= ent then
            st.npc = ent
            if LC.QB and LC.QB.SendStateAll then LC.QB.SendStateAll(q) end
        end
    end)
end

local function Release(npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    st.unmanaged, st.paymaster, st.paymasterEscort, st.eventUntil = nil, nil, nil, 0
    st.leaveAt = CurTime() + 60 -- (they walk off, and the city takes them back)
end

function LC.EndPaymaster(why)
    local P = LC.Paymaster
    if not P then return end
    LC.Paymaster = nil
    lastPaymaster = CurTime()
    Release(P.npc)
    for _, g in ipairs(P.escort or {}) do Release(g) end
    if IsValid(P.satchel) then P.satchel:Remove() end
    -- off the board, and a job still going has nothing left to do
    for _, list in pairs(LC.Postings or {}) do
        for _, p in ipairs(list) do if istable(p.tmpl) and p.tmpl.id == JOB and not p.q then p.dead = true end end
    end
    local ended = {}
    Jobs(function(_, q) ended[q] = true end)
    for q in pairs(ended) do if not q.done and LC.FinishQuest then LC.FinishQuest(q, false, "you ran out of time") end end
    if why ~= "silent" then LC.Log("info", "The paymaster: " .. tostring(why)) end
    hook.Run("LivingCityPaymasterEnded", P, why)
end

function LC.StartPaymaster()
    if LC.Paymaster then LC.EndPaymaster("silent") end
    if not (LC.Spawners and LC.Spawners.citizen) then return false, "nobody to send" end
    local from, to = Route()
    if not from then return false, "nowhere to start from" end
    local okS, npc, st = LC.Try(LC.Spawners.citizen, from + Vector(0, 0, 4))
    if not (okS and IsValid(npc) and st) then return false, "nobody to send" end
    st.unmanaged, st.leaveAt, st.routeGroup, st.paymaster = true, nil, nil, true
    if LC.SetState then LC.SetState(npc, st, "event") end
    st.eventUntil = CurTime() + 3600
    local P = { npc = npc, escort = {}, from = from, goal = to, wages = math.random(WAGES[1], WAGES[2]), startT = CurTime(), hurtBy = {} }
    for i = 1, ESCORT do
        local spawn = LC.Spawners.cop
        local okC, cop, cst = false, nil, nil
        if spawn then okC, cop, cst = LC.Try(spawn, from + Vector(i % 2 == 0 and 60 or -60, -60, 4)) end
        if okC and IsValid(cop) and cst then
            cst.unmanaged, cst.leaveAt, cst.routeGroup, cst.paymasterEscort = true, nil, nil, true
            if LC.SetState then LC.SetState(cop, cst, "event") end
            cst.eventUntil = CurTime() + 3600
            P.escort[#P.escort + 1] = cop
        end
    end
    LC.Paymaster = P
    Walk(npc, to)
    LC.Log("info", string.format("The paymaster sets out %s with %d credits", LC.DescribePlace and LC.DescribePlace(from) or "", P.wages))
    if LC.PostDirective then LC.PostDirective(JOB) end
    hook.Run("LivingCityPaymaster", P)
    return true, P
end

-- His escort is gone: none of them standing within reach of him.
local function EscortGone(P)
    local at = IsValid(P.npc) and P.npc:GetPos()
    if not at then return true end
    for _, g in ipairs(P.escort or {}) do
        if IsValid(g) and g:Health() > 0 and g:GetPos():DistToSqr(at) < ESCORT_REACH * ESCORT_REACH then return false end
    end
    return true
end
LC.PaymasterEscortGone = function() return LC.Paymaster ~= nil and EscortGone(LC.Paymaster) end

local function DropSatchel(P, pos)
    if IsValid(P.satchel) then return end
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return end
    e:SetModel("models/props_c17/BriefCase001a.mdl")
    e:SetPos(pos + Vector(0, 0, 12))
    e:SetAngles(Angle(0, math.random(0, 359), 0))
    e:Spawn()
    local phys = e:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    e.lcDressing = true -- (not pocketed as a thing: taken with E, below)
    e.lcPaySatchel = true
    P.satchel, P.droppedAt = e, CurTime()
    Mark(e)
end

-- E on him (his escort gone) or on the satchel he dropped: the wages are theirs. True when taken.
function LC.RobPaymaster(ply, ent)
    local P = LC.Paymaster
    if not P or P.robbed or not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return false end
    if Unit(ply) or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) or Faction(ply) == "admin" then return false end
    local fromSatchel = IsValid(P.satchel) and ent == P.satchel
    if not fromSatchel then
        if ent ~= P.npc or not IsValid(P.npc) or P.npc:Health() <= 0 or not EscortGone(P) then return false end
    end
    P.robbed = true
    local take = P.wages
    local at = IsValid(ent) and ent:GetPos() or ply:GetPos()
    local party = {}
    if Ours(ply) then
        party = Partakers(P, ply)
        local shared = math.floor(take * (1 - SHARE))
        local each = #party > 0 and math.floor(shared / #party) or 0
        local kept = take - each * #party
        if LC.ResistanceFundAdd then LC.ResistanceFundAdd(kept, "The paymaster's satchel") end
        if each > 0 then for _, p in ipairs(party) do LC.AddCredits(p, each, WHY) end end
    else
        LC.AddCredits(ply, take) -- (a citizen keeps it all: their money is not the Resistance's)
    end
    if IsValid(P.satchel) then P.satchel:Remove() end
    ply:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 50)
    -- the Combine answer it as they do a looted supply drop: seen at it, wanted, and the units after you
    if LC.SeenBySecurity and LC.SeenBySecurity(ply, 900) then
        if LC.ReportCrime then LC.ReportCrime(ply, "Looting Union supplies", 240) end
        if LC.MakeCopsHostile then LC.MakeCopsHostile(ply, at, 1200) end
    end
    if LC.LedgerAdd then LC.LedgerAdd("resistance", 1, nil) end
    -- the job: whoever of ours took part and is on it has done it
    if LC.QuestEvent then
        LC.QuestEvent("paymaster_robbed", ply, P.npc)
        for _, p in ipairs(party) do LC.QuestEvent("paymaster_robbed", p, P.npc) end
    end
    -- alive, he runs for it
    if IsValid(P.npc) and P.npc:Health() > 0 and P.from then Walk(P.npc, P.from, true) end
    hook.Run("LivingCityPaymasterRobbed", ply, take, party, P)
    LC.EndPaymaster("robbed")
    return true
end

hook.Add("PlayerUse", "LivingCityPaymaster", function(ply, ent)
    local P = LC.Paymaster
    if not P or not IsValid(ent) or (ent ~= P.npc and ent ~= P.satchel) then return end
    Heard("E on the paymaster", LC.RobPaymaster, ply, ent)
end)
-- (and where the city hears E on any of its people: whichever of the two hears it first, it is taken once)
hook.Add("LivingCityPlayerUsedNPC", "LivingCityPaymaster", function(ply, npc)
    local P = LC.Paymaster
    if not P or npc ~= P.npc then return end
    Heard("E on the paymaster", LC.RobPaymaster, ply, npc)
end)

hook.Add("EntityTakeDamage", "LivingCityPaymaster", function(victim, dmg)
    local P = LC.Paymaster
    if not P or not IsValid(victim) then return end
    local his = victim == P.npc
    if not his then for _, g in ipairs(P.escort or {}) do if g == victim then his = true break end end end
    if not his then return end
    local by = dmg and dmg.GetAttacker and dmg:GetAttacker()
    if IsValid(by) and by:IsPlayer() then P.hurtBy[by] = CurTime() end
    if victim == P.npc then P.scared = true end
end)

hook.Add("OnNPCKilled", "LivingCityPaymaster", function(npc, attacker)
    local P = LC.Paymaster
    if not P or npc ~= P.npc or P.robbed then return end
    Heard("the paymaster killed", function()
        if IsValid(attacker) and attacker:IsPlayer() then P.hurtBy[attacker] = CurTime() end
        DropSatchel(P, npc:GetPos())
    end)
end)

-- His walk, his escort beside him, and the end of it.
local function Tick(now)
    local P = LC.Paymaster
    if not P then return end
    if not LC.Running then return LC.EndPaymaster("silent") end
    if IsValid(P.satchel) then
        if now - (P.droppedAt or now) > SATCHEL_SECS then LC.EndPaymaster("the satchel was picked up by the Union") end
        return
    end
    local npc = P.npc
    if not (IsValid(npc) and npc:Health() > 0) then return LC.EndPaymaster("gone") end
    if now - P.startT > WALK_SECS then return LC.EndPaymaster("out of time") end
    local pos = npc:GetPos()
    if pos:DistToSqr(P.goal) < 120 * 120 then return LC.EndPaymaster("paid") end
    Walk(npc, P.goal, P.scared)
    -- stuck, and nobody watching: a little further along
    if P.lastPos and pos:DistToSqr(P.lastPos) < 20 * 20 then P.still = (P.still or 0) + 1 else P.still = 0 end
    P.lastPos = pos
    if P.still >= 12 and not (LC.IsSeen and LC.IsSeen(pos + Vector(0, 0, 40))) then
        local dir = (P.goal - pos)
        local step = math.min(dir:Length(), 300)
        if step > 1 then
            local to = pos + dir:GetNormalized() * step
            npc:SetPos((LC.GroundAt and LC.GroundAt(to)) or to)
        end
        P.still = 0
    end
    -- the escort a step behind him, either side (one that is fighting is left to it)
    local back = (pos - P.goal)
    back.z = 0
    back = back:LengthSqr() > 1 and back:GetNormalized() or Vector(-1, 0, 0)
    local side = Vector(-back.y, back.x, 0)
    for i, g in ipairs(P.escort or {}) do
        local gst = IsValid(g) and g:Health() > 0 and LC.NPCs and LC.NPCs[g]
        if gst and gst.state ~= "hostile" then
            local want = pos + back * 70 + side * (i % 2 == 0 and 50 or -50)
            if g:GetPos():DistToSqr(want) > 110 * 110 then Walk(g, want, g:GetPos():DistToSqr(want) > 500 * 500) end
        end
    end
end
LC.PaymasterTick = Tick

timer.Create("LivingCityPaymaster", 1, 0, function() Heard("his walk", Tick, CurTime()) end)

-- Now and then, by day: about once in MEAN_MINUTES of the city running, never sooner than GAP_MINUTES after the last.
function LC.PaymasterMayStart(now)
    now = now or CurTime()
    if LC.Paymaster or not LC.Running then return false end
    if now - lastPaymaster < GAP_MINUTES * 60 then return false end
    if #player.GetAll() == 0 then return false end
    if LC.IsNight and LC.IsNight() then return false end
    if LC.Event == "curfew" or LC.Event == "lockdown" then return false end
    if LC.EndingBusy and LC.EndingBusy() then return false end
    return true
end
LC.PaymasterEvery = MEAN_MINUTES
timer.Create("LivingCityPaymasterClock", 60, 0, function()
    Heard("the paymaster's day", function()
        if LC.PaymasterMayStart() and math.random() < 1 / MEAN_MINUTES then
            local okP, why = LC.StartPaymaster()
            if not okP then LC.Log("info", "The paymaster did not set out: " .. tostring(why)) end
        end
    end)
end)

-- The Resistance's job while he walks. Its pay as the board shows it: the board's pay for any job, and the share of
-- the satchel each step that robs him is worth (LC.ResistanceFundStepKinds, below).
if LC.QB then
    local Q = LC.QB
    LC.QuestTemplates[#LC.QuestTemplates + 1] = {
        id = JOB, brings = true, factions = { resistance = true }, squad = 4, violent = true,
        available = function() return LC.Paymaster ~= nil and not LC.Paymaster.robbed and IsValid(LC.Paymaster.npc) end,
        build = function()
            local P = LC.Paymaster
            if not (P and IsValid(P.npc)) then return nil end
            local st = Q.Count("paymaster_robbed", 1, LINE)
            st.onEnter = function(_, s) s.npc = (IsValid(P.satchel) and P.satchel) or P.npc end
            return {
                title = "Rob the paymaster", reward = 45, limit = math.max(120, math.floor(WALK_SECS - (CurTime() - P.startT)) + 60),
                desc = LINE, stages = { st },
            }
        end,
    }
end

-- What robbing him puts in the fund, for the job boards: the fund's own tables, with the paymaster's satchel added.
if istable(LC.ResistanceFundStepKinds) then LC.ResistanceFundStepKinds.paymaster_robbed = "paymaster" end
local function SatchelShares(n)
    n = math.max(0, math.floor(tonumber(n) or 0))
    local keptLo, keptHi, eachLo, eachHi
    for take = WAGES[1], WAGES[2] do
        local shared = math.floor(take * (1 - SHARE))
        local each = n > 0 and math.floor(shared / n) or 0
        local kept = n > 0 and (take - each * n) or (take - shared)
        keptLo, keptHi = math.min(keptLo or kept, kept), math.max(keptHi or kept, kept)
        eachLo, eachHi = math.min(eachLo or each, each), math.max(eachHi or each, each)
    end
    return keptLo, keptHi, eachLo, eachHi
end
if LC.ResistanceFundShares and LC.ResistanceFundShares ~= LC.ResistanceMoneyShares then
    local base = LC.ResistanceFundShares
    LC.ResistanceMoneyShares = function(kind, n)
        if kind == "paymaster" then return SatchelShares(n) end
        return base(kind, n)
    end
    LC.ResistanceFundShares = LC.ResistanceMoneyShares
end

------------------------------------------------------------------------
-- The card table
------------------------------------------------------------------------

local NO_CARDS = { cp = true, ota = true, admin = true, zombie = true }
local function MayPlay(ply, tbl)
    if not (IsValid(ply) and ply:IsPlayer() and ply:Alive() and IsValid(tbl)) then return false end
    if tbl:GetClass() ~= "lc_cardtable" then return false end
    if NO_CARDS[Faction(ply)] or Unit(ply) then return false end
    if ply:GetPos():DistToSqr(tbl:GetPos()) > TABLE_REACH * TABLE_REACH then return false end
    return LC.InRebelZone ~= nil and LC.InRebelZone(tbl:GetPos())
end
LC.CardTableOpen = MayPlay

-- The bets the table will take from this player now: each bet, true or false.
local function Takes(ply)
    local out, credits, fund = {}, LC.Credits(ply), LC.ResistanceFund and LC.ResistanceFund() or 0
    for _, b in ipairs(BETS) do out[b] = credits >= b and fund - b >= FLOOR end
    return out
end
LC.CardTableTakes = Takes

local function Send(ply, tbl, you, house, result)
    local mask, takes = 0, Takes(ply)
    for i, b in ipairs(BETS) do if takes[b] then mask = mask + 2 ^ (i - 1) end end
    net.Start("lc_cards")
    net.WriteEntity(tbl)
    net.WriteUInt(you or 0, 5)
    net.WriteUInt(house or 0, 5)
    net.WriteUInt(result or 0, 2)
    net.WriteUInt(mask, 3)
    net.Send(ply)
end

function LC.OpenCardTable(ply, tbl)
    if not MayPlay(ply, tbl) then return false end
    Send(ply, tbl)
    return true
end

-- One hand of high card. True, and the player's card, the house's card (2 to 14, the ace high) and whether they won;
-- or false and why not.
function LC.CardTableDeal(ply, tbl, bet)
    if not MayPlay(ply, tbl) then return false, "not here" end
    bet = math.floor(tonumber(bet) or 0)
    local legal = false
    for _, b in ipairs(BETS) do if b == bet then legal = true end end
    if not legal then return false, "no such bet" end
    local now = CurTime()
    if now < (ply.lcCardsAt or 0) + RATE then return false, "too soon" end
    if not Takes(ply)[bet] then return false, "the table won't take it" end
    ply.lcCardsAt = now
    -- one from a fresh deck each, two different cards (a rank in four suits)
    local a = math.random(0, 51)
    local b = math.random(0, 50)
    if b >= a then b = b + 1 end
    local you, house = a % 13 + 2, b % 13 + 2
    local won = you > house -- (a tie is the house's)
    if won then
        if LC.ResistanceFundTake and not LC.ResistanceFundTake(bet, "The card table paid out (" .. Name(ply) .. ")") then return false, "the table won't take it" end
        LC.AddCredits(ply, bet)
    else
        LC.AddCredits(ply, -bet)
        if LC.ResistanceFundAdd then LC.ResistanceFundAdd(bet, "The card table's take") end
    end
    tbl:EmitSound("physics/cardboard/cardboard_box_impact_soft" .. math.random(1, 3) .. ".wav", 45, 160)
    Send(ply, tbl, you, house, won and 1 or 2)
    hook.Run("LivingCityCardHand", ply, bet, won)
    return true, you, house, won
end

net.Receive("lc_cards_deal", function(_, ply)
    local tbl = net.ReadEntity()
    local bet = net.ReadUInt(8)
    Heard("a hand of cards", function()
        local okD = LC.CardTableDeal(ply, tbl, bet)
        if not okD and MayPlay(ply, tbl) then Send(ply, tbl) end -- (the window as it stands: what it will take now)
    end)
end)
