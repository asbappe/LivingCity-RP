--[[
    Living City: what now?

    Every player always has one next step, worked out from where they stand:
    register, get a room, find your block, eat, drink, get a job, work a
    shift, and so on. It's a quiet line on their screen for a new life's
    first hour (and whenever something's urgent: hungry, thirsty, nowhere to
    live), and slot 1 of the F1 quick menu for everyone: the step, why, and
    "show me the way" (a waypoint). F1 > What now? > Places lists everywhere
    worth knowing, each with a waypoint.

    Hunger or thirst running low puts a card on screen with the nearest way
    to eat or drink right now. A new life's first ration allocation is never
    turned away by a supply shortfall.

    Nothing is handed out: it only ever says where to go and what to ask for.

      lc_whatnow 0/1 (all of it), lc_whatnow_minutes (60: how long a new life
      sees the line without asking)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn   = CreateConVar("lc_whatnow", "1", FLAGS, "Players always have a next step: on screen for a new life, and on F1")
local cvMins = CreateConVar("lc_whatnow_minutes", "60", FLAGS, "Minutes a new life sees its next step on screen without asking")

local HUNGRY, THIRSTY = 30, 30

------------------------------------------------------------------------
-- More places to be shown the way to (sv_livingcity_notices.lua)
------------------------------------------------------------------------

local function Nearest(pos, list, posOf, test)
    local best, bd
    for _, x in ipairs(list or {}) do
        local p = posOf(x)
        if p and (not test or test(x)) then
            local d = p:DistToSqr(pos)
            if not bd or d < bd then best, bd = p, d end
        end
    end
    return best
end
local function EntPos(e) return IsValid(e) and e:GetPos() or nil end
local function Ents(cls) return LC.EntsOf and LC.EntsOf(cls) or {} end

-- The nearest dispenser (a ration line's own, or any), its spot.
local function DispenserPos(ply)
    local p = Nearest(ply:GetPos(), Ents("lc_dispenser"), EntPos, function(e) return not e:GetNW2Bool("lc_nopower", false) end)
    if p then return p end
    for _, line in pairs(LC.Lines or {}) do
        if line.slots and line.slots[1] then return line.slots[1].pos end
    end
end

local function WaterPos(ply)
    local all = {}
    for _, fx in ipairs(LC.StaticFixtures or {}) do if fx.kind == "sink" then all[#all + 1] = fx.pos end end
    for _, e in ipairs(Ents("lc_vending")) do all[#all + 1] = e:GetPos() end
    return Nearest(ply:GetPos(), all, function(p) return p end)
end

local function BinPos(ply)
    local all = {}
    for _, fx in ipairs(LC.StaticBins or {}) do all[#all + 1] = fx.pos end
    for _, e in ipairs(Ents("lc_citybin")) do all[#all + 1] = e:GetPos() end
    return Nearest(ply:GetPos(), all, function(p) return p end)
end

local function WorkPos(ply)
    local job = LC.Job and LC.Job(ply)
    if not job then return nil end
    return Nearest(ply:GetPos(), LC.PointsOfKind and LC.PointsOfKind("work", job.num) or {}, function(p) return p.pos end), job
end

local function ShopPos(ply)
    return Nearest(ply:GetPos(), Ents("lc_terminal"), EntPos)
end

local mine = {}
local function Add(kind, fn) mine[kind] = fn end
-- (into the waypoint list in sv_livingcity_notices.lua, whichever loads first)
local function Register()
    if not LC.WaypointPlaces then return end
    for k, fn in pairs(mine) do LC.WaypointPlaces[k] = fn end
end
hook.Add("Initialize", "LivingCityNextStepPlaces", Register)
hook.Add("InitPostEntity", "LivingCityNextStepPlaces", Register)
Add("dispenser", function(ply)
    local p = DispenserPos(ply)
    if p then return p, "Ration dispenser" end
    return nil, "This city has no ration dispenser yet."
end)
Add("water", function(ply)
    local p = WaterPos(ply)
    if p then return p, "Water" end
    return nil, "No sinks or water machines found nearby."
end)
Add("bin", function(ply)
    local p = BinPos(ply)
    if p then return p, "Bins to search" end
    return nil, "No bins found nearby."
end)
Add("work", function(ply)
    local p, job = WorkPos(ply)
    if p then return p, job.name or "Your workplace" end
    return nil, job and "Your job has no workplace on this map: shifts come to you (F3)." or "You have no job. F3 > Jobs."
end)
Add("shop", function(ply)
    local p = ShopPos(ply)
    if p then return p, "Commissary" end
    return nil, "This city has no Commissary terminal yet."
end)

Register()

------------------------------------------------------------------------
-- The next step
------------------------------------------------------------------------

local function Citizenish(ply)
    local f = ply:GetNW2String("lcf_faction", "")
    return f == "citizen" or f == "resistance" or f == "" or f == "admin"
end

local function HasFood(ply)
    local inv = LC.Inventory and LC.Inventory(ply) or {}
    for id, n in pairs(inv) do
        local it = LCS.Items[id]
        if n > 0 and it and (it.hunger or 0) >= 10 and not it.cooksTo then return it.name end
    end
end
local function HasDrink(ply)
    local inv = LC.Inventory and LC.Inventory(ply) or {}
    for id, n in pairs(inv) do
        local it = LCS.Items[id]
        if n > 0 and it and (it.thirst or 0) >= 15 then return it.name end
    end
end

local function RationReady(ply)
    if LC.IntakePending and LC.IntakePending(ply) then return false end
    if LC.LacksRationCard and LC.LacksRationCard(ply) then return false end
    if ply.lcRationDocked then return false end
    if LC.StockLevel and LC.StockLevel() == "empty" then return false end
    return CurTime() >= (ply.lcnRationAt or 0)
end

local function Cheapest(ply, what)
    local credits = LC.Credits and LC.Credits(ply) or 0
    local best
    for _, s in ipairs(LCS.Goods or {}) do
        local it = s.item and LCS.Items[s.item]
        if it and (it[what] or 0) >= 15 and credits >= s.price and (not best or s.price < best.price) then best = s end
    end
    return best
end

-- Seen their own block yet, this life?
local function HomeSeen(ply)
    local cid = ply:GetNW2String("lc_cid", "")
    if ply.lcHomeSeenCid == cid and cid ~= "" then return true end
    if cid ~= "" and ply:GetPData("lc_home_seen", "") == cid then ply.lcHomeSeenCid = cid return true end
    if LC.PlayerInOwnBlock and LC.PlayerInOwnBlock(ply) then
        ply.lcHomeSeenCid = cid
        if cid ~= "" then ply:SetPData("lc_home_seen", cid) end
        return true
    end
    return false
end

-- { key, text, why, way, urgent }
function LC.NextStep(ply)
    if not IsValid(ply) or not ply:Alive() then return nil end
    local f = ply:GetNW2String("lcf_faction", "")
    if LC.InCustody and LC.InCustody(ply) then
        return { key = "custody", text = "Serve your time", why = "You're in custody. It ends when your sentence does (or someone gets you out)." }
    end
    if LC.IsDowned and LC.IsDowned(ply) then
        return { key = "down", text = "Hold on", why = "You're down and bleeding out. Someone can press E on you to help.", urgent = true }
    end
    -- a toilet, a wash, clean clothes (sv_livingcity_hygiene.lua); a bed (sv_livingcity_rest.lua)
    local hy = LC.HygieneStep and LC.HygieneStep(ply)
    if hy then return hy end
    local rest = LC.RestStep and LC.RestStep(ply)
    if rest and rest.urgent then return rest end
    local hunger = LC.Hunger and LC.Hunger(ply) or 100
    local thirst = LC.Thirst and LC.Thirst(ply) or 100
    local needs = GetConVar("lc_needs") and GetConVar("lc_needs"):GetBool()
    local civ = Citizenish(ply)

    if civ and LC.IntakePending and LC.IntakePending(ply) then
        return { key = "intake", text = "Register at Civil Intake", why = "Until you're on the register you get no rations, no job and no room.", way = "intake", urgent = true }
    end
    if civ and LC.AwaitingHousing and LC.AwaitingHousing(ply) then
        return { key = "housing", text = "Ask Housing Allocation for a room", why = "You're registered. Next, a room: press E on the Housing Allocation terminal.", way = "housing", urgent = true }
    end

    -- eating and drinking, before anything else
    if needs and civ and hunger < HUNGRY then
        local food = HasFood(ply)
        if food then return { key = "eat_own", text = "Eat something", why = "You're hungry, and you have " .. string.lower(food) .. ": F2, then use it.", urgent = true } end
        if RationReady(ply) then return { key = "eat_ration", text = "Collect your ration", why = "You're hungry and your allocation is ready: the dispenser (show your ration card).", way = "dispenser", urgent = true } end
        local buy = Cheapest(ply, "hunger")
        if buy then return { key = "eat_buy", text = "Buy food at the Commissary", why = string.format("You're hungry. %s costs %d credits; you have enough.", LCS.Items[buy.item].name, buy.price), way = "shop", urgent = true } end
        local wait = math.max(0, math.ceil((ply.lcnRationAt or 0) - CurTime()))
        return { key = "eat_scrounge", text = "Find something to eat", why = (wait > 0 and string.format("Your next ration is in %d minutes. ", math.ceil(wait / 60)) or "")
            .. "Until then: search bins, or work a shift for credits.", way = "bin", urgent = true }
    end
    if needs and civ and thirst < THIRSTY then
        local drink = HasDrink(ply)
        if drink then return { key = "drink_own", text = "Have a drink", why = "You're thirsty, and you have " .. string.lower(drink) .. ": F2, then use it.", urgent = true } end
        return { key = "drink", text = "Find water", why = "You're thirsty. A sink or a water machine: press E on it.", way = "water", urgent = true }
    end

    if civ and LC.PlayerBlock and LC.PlayerBlock(ply) and not HomeSeen(ply) then
        return { key = "home", text = "Find your block", why = "You live in " .. (LC.BlockName and LC.BlockName(LC.PlayerBlock(ply)) or "your block") .. ". It's where you sleep, keep things, and shelter at curfew.", way = "home" }
    end

    if civ then
        if LC.QuestOf and LC.QuestOf[ply] then
            local q = LC.QuestOf[ply]
            return { key = "on_job", text = "Finish what you're doing", why = (q.title and (q.title .. ": ") or "") .. "its next step is on your screen, and on F3." }
        end
        if f ~= "resistance" and LC.Job and not LC.Job(ply) then
            return { key = "job", text = "Get a Union job", why = "Jobs pay credits and standing, a shift at a time. F3 > Jobs: pick one." }
        end
        if RationReady(ply) and hunger < 75 then
            return { key = "ration", text = "Collect your ration", why = "Your allocation is ready: the dispenser (show your ration card).", way = "dispenser" }
        end
        if (LC.Credits and LC.Credits(ply) or 0) < 15 and LC.Job and LC.Job(ply) then
            return { key = "shift", text = "Work a shift", why = "You're short of credits. F3 has your next shift.", way = "work" }
        end
        return { key = "free", text = "Your time is your own", why = "Work another shift (F3), take a side job (F3), or get to know people: F1 > Talk." }
    end
    if f == "cp" then
        return { key = "unit", text = "On duty", why = "Your directives are on F3. The Commissary issues your supplies.", way = "cpsupply" }
    end
    return nil
end

------------------------------------------------------------------------
-- Sent to each player when it changes
------------------------------------------------------------------------

local warned = {} -- [ply] = { hunger = bool, thirst = bool }

local function Push(ply)
    local s = cvOn:GetBool() and LC.NextStep(ply) or nil
    local text, why, way = s and s.text or "", s and s.why or "", s and s.way or ""
    local act = s and s.action or ""
    if ply:GetNW2String("lc_next_act", "") ~= act then ply:SetNW2String("lc_next_act", act) end
    if ply:GetNW2String("lc_next", "") ~= text then ply:SetNW2String("lc_next", text) end
    if ply:GetNW2String("lc_next_why", "") ~= why then ply:SetNW2String("lc_next_why", why) end
    if ply:GetNW2String("lc_next_way", "") ~= way then ply:SetNW2String("lc_next_way", way) end
    local urgent = s and s.urgent or false
    if ply:GetNW2Bool("lc_next_urgent", false) ~= urgent then ply:SetNW2Bool("lc_next_urgent", urgent) end
    local new = LC.LivedSeconds and LC.LivedSeconds(ply) < cvMins:GetFloat() * 60 or false
    if ply:GetNW2Bool("lc_next_new", false) ~= new then ply:SetNW2Bool("lc_next_new", new) end
    -- running low: once each time it drops, a card with the way to fix it
    local w = warned[ply] or {}
    warned[ply] = w
    for _, need in ipairs({ "hunger", "thirst" }) do
        local low = s and (s.key == (need == "hunger" and "eat_own" or "drink_own") or (need == "hunger" and string.find(s.key or "", "^eat_")) or (need == "thirst" and s.key == "drink"))
        if low and not w[need] and LC.Notice then
            w[need] = true
            LC.Notice(ply, "warn", need == "hunger" and "Hungry" or "Thirsty", s.text .. ". " .. s.why .. (s.way and s.way ~= "" and " (F1 > 1 shows you the way.)" or ""))
        elseif not low then
            w[need] = nil
        end
    end
end
LC.PushNextStep = Push

timer.Create("LivingCityNextStep", 2, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local ok, err = pcall(Push, ply)
        if not ok and LC.Error then LC.Error("next step", err) end
    end
end)

hook.Add("PlayerDisconnected", "LivingCityNextStep", function(ply) warned[ply] = nil end)

------------------------------------------------------------------------
-- A new life's first meal: never a shortfall
------------------------------------------------------------------------

function LC.FirstRationDue(ply)
    local cid = ply:GetNW2String("lc_cid", "")
    return cid ~= "" and ply:GetPData("lc_first_ration", "") ~= cid
end
hook.Add("LivingCityRationCollected", "LivingCityNextStep", function(ply)
    local cid = ply:GetNW2String("lc_cid", "")
    if cid ~= "" then ply:SetPData("lc_first_ration", cid) end
    timer.Simple(0, function() if IsValid(ply) then pcall(Push, ply) end end)
end)
