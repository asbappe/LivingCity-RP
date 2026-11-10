--[[
    Living City: the Resistance plans its own operations, and the Combine
    puts prices on heads (the owner, 10 November: "this all sounds great").

    The planning board. A Resistance Lieutenant or Commander (a Fighter when
    neither is online) opens F2 > Resistance > Operations: plan or join, and
    picks a target the city offers right now (a data terminal to raid, a city
    screen to hijack, one of ours to break out of the prison, a supply drop
    or an Overwatch landing while one is on) and when: in 2, 5 or 10 minutes.
    The cell hears it on Freq 7 and any of them can join (F2, same page).
    When the time comes the fighters go (the same operation the city's own
    rebels run: LC.LaunchRebelOp), everyone who joined gets a waypoint to the
    target, and if it succeeds, everyone who joined and was there earns
    25 experience and 15 credits (the planner 10 more experience). If the
    streets are too hot (another fight going on) it waits, up to five
    minutes, then it's called off. One plan at a time, one every
    lc_rebel_plan_minutes (15). And someone always talks: lc_rebel_plan_leak
    (15%) of plans reach Civil Protection beforehand, the target and the time.

    Bounties. The City Administrator, or a unit of Division Leader rank or
    higher, can put a price on a wanted person's head (F2 > Me > Bounties: 50
    or 100 credits). Every unit hears of it, and so does the person. A unit
    player who brings them in collects it (and 10 experience); taken in by
    the city's own units, or no longer wanted, the bounty lapses.

      lc_rebel_plans 0/1, lc_rebel_plan_minutes (15), lc_rebel_plan_leak (0.15),
      lc_bounties 0/1
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvPlans = CreateConVar("lc_rebel_plans", "1", FLAGS, "Resistance leaders can plan their own operations: a target, a time, who joins")
local cvGap   = CreateConVar("lc_rebel_plan_minutes", "15", FLAGS, "Least minutes between two operations the Resistance's players plan")
local cvLeak  = CreateConVar("lc_rebel_plan_leak", "0.15", FLAGS, "Chance a planned operation leaks to Civil Protection beforehand")
local cvBounty = CreateConVar("lc_bounties", "1", FLAGS, "The Administrator and senior units can put a price on a wanted person's head")

local WAIT_MAX = 300
local REWARD_XP, REWARD_CR, PLANNER_XP = 25, 15, 10

local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function Rank(p) return p:GetNW2Int("lcf_rank", 1) end
local function Name(p) return (LC.CharacterName and LC.CharacterName(p)) or (IsValid(p) and p:Nick()) or "someone" end
local function Where(pos) return (LC.DescribePlace and LC.DescribePlace(pos)) or "" end
local function Radio(band, text) if LC.RadioNotice then LC.RadioNotice(band, text) end end
local function TellUnits(text)
    for _, p in ipairs(player.GetAll()) do if LC.PlayerIsCP(p) then p:ChatPrint(text) end end
end

------------------------------------------------------------------------
-- The planning board
------------------------------------------------------------------------

LC.OpPlan = LC.OpPlan or nil
local nextPlan = 0

-- May they plan? Lieutenants and Commanders; Fighters when no Lieutenant or Commander is online.
function LC.CanPlanOp(ply)
    if not cvPlans:GetBool() then return false, "There's no planning here." end
    if not IsValid(ply) or Faction(ply) ~= "resistance" then return false, "Only the Resistance plans operations." end
    if Rank(ply) >= 4 then return true end
    if Rank(ply) >= 3 then
        for _, p in ipairs(player.GetAll()) do
            if p ~= ply and Faction(p) == "resistance" and Rank(p) >= 4 then return false, "Your Lieutenant plans the operations. Ask them." end
        end
        return true
    end
    return false, "Fighters and up plan operations. Join one when it's posted."
end

-- What can be hit right now: { label, kind, pos, data }.
function LC.OpTargets()
    local out, now = {}, CurTime()
    local prisoner, cellPos
    if LC.JailedRebel then prisoner, cellPos = LC.JailedRebel() end
    if IsValid(prisoner) and cellPos then out[#out + 1] = { label = "Break " .. Name(prisoner) .. " out of the prison", kind = "breakout", pos = cellPos, data = { prisoner = prisoner } } end
    local n = 0
    for _, t in ipairs(LC.DataTerminals and LC.DataTerminals() or {}) do
        if n < 3 and (LC.TerminalReadyAt and (LC.TerminalReadyAt[t.key] or 0) or 0) <= now then
            n = n + 1
            out[#out + 1] = { label = "Raid the data terminal " .. Where(t.pos), kind = "heist", pos = t.pos, data = { key = t.key } }
        end
    end
    n = 0
    for _, s in ipairs(LC.EntsOf and LC.EntsOf("lc_screen") or {}) do
        if n < 3 and IsValid(s) and s:GetNW2Float("lc_hijacked_until", 0) <= now then
            n = n + 1
            out[#out + 1] = { label = "Hijack the city screen " .. Where(s:GetPos()), kind = "screen", pos = s:GetPos(), data = { screen = s } }
        end
    end
    if LC.Supply and LC.Supply.pos then out[#out + 1] = { label = "Hit the supply drop " .. Where(LC.Supply.pos), kind = "supply", pos = LC.Supply.pos, data = {} } end
    if LC.OverwatchDrop and LC.OverwatchDrop.pos then out[#out + 1] = { label = "Ambush the Overwatch landing " .. Where(LC.OverwatchDrop.pos), kind = "ambush", pos = LC.OverwatchDrop.pos, data = {} } end
    return out
end

local function PlanSummary(p)
    if not p then return nil end
    local joined = 0
    for q in pairs(p.joined) do if IsValid(q) then joined = joined + 1 end end
    return { label = p.label, by = Name(p.by), left = math.max(0, math.floor(p.fireAt - CurTime())), joined = joined, waiting = p.waiting or nil }
end

-- What the menu shows a Resistance player (F2 > Resistance > Operations).
local function SyncMenu(ply)
    if Faction(ply) ~= "resistance" then
        if ply:GetNW2String("lc_op_menu", "") ~= "" then ply:SetNW2String("lc_op_menu", "") end
        return
    end
    local can, why = LC.CanPlanOp(ply)
    local t = { plan = PlanSummary(LC.OpPlan), joined = LC.OpPlan and LC.OpPlan.joined[ply] or nil, can = can or nil, why = not can and why or nil }
    if can and not LC.OpPlan then
        ply.lcOpTargets = LC.OpTargets()
        t.targets = {}
        for i, o in ipairs(ply.lcOpTargets) do t.targets[i] = o.label end
        t.wait = math.max(0, math.floor(nextPlan - CurTime()))
    end
    ply:SetNW2String("lc_op_menu", util.TableToJSON(t) or "")
end
LC.OpSyncMenu = SyncMenu

function LC.PlanOp(ply, index, minutes)
    local ok, why = LC.CanPlanOp(ply)
    if not ok then return false, why end
    if LC.OpPlan then return false, "There's an operation planned already: join it." end
    if CurTime() < nextPlan then return false, string.format("Too soon after the last one. (%s)", string.NiceTime(nextPlan - CurTime())) end
    minutes = tonumber(minutes) or 5
    if minutes ~= 2 and minutes ~= 5 and minutes ~= 10 then minutes = 5 end
    local o = (ply.lcOpTargets or LC.OpTargets())[tonumber(index) or 0]
    if not o then return false, "That target isn't there any more. Look again." end
    local plan = { by = ply, label = o.label, kind = o.kind, pos = o.pos, data = o.data, fireAt = CurTime() + minutes * 60, joined = { [ply] = true } }
    LC.OpPlan = plan
    nextPlan = CurTime() + cvGap:GetFloat() * 60
    Radio("resistance", string.format("%s plans an operation: %s, in %d minutes. Join it: F2 > Resistance > Operations.", Name(ply), o.label, minutes))
    if math.random() < math.Clamp(cvLeak:GetFloat(), 0, 1) then
        plan.leaked = true
        TellUnits(string.format("[CP net] Intelligence: the anticitizens plan to %s, in about %d minutes.", string.lower(string.sub(o.label, 1, 1)) .. string.sub(o.label, 2), minutes))
    end
    for _, p in ipairs(player.GetAll()) do SyncMenu(p) end
    hook.Run("LivingCityOpPlanned", ply, plan)
    return true
end

function LC.JoinOp(ply)
    local plan = LC.OpPlan
    if not plan then return false, "Nothing is planned right now." end
    if Faction(ply) ~= "resistance" then return false, "Only the Resistance." end
    if plan.joined[ply] then
        plan.joined[ply] = nil
        ply:ChatPrint("[Freq 7] You've backed out of the operation.")
    else
        plan.joined[ply] = true
        ply:ChatPrint("[Freq 7] You're in: " .. plan.label .. ". You'll be pointed there when it starts.")
    end
    SyncMenu(ply)
    return true
end

function LC.CancelOp(ply)
    local plan = LC.OpPlan
    if not plan then return false end
    if ply ~= plan.by and not (IsValid(ply) and ply:IsAdmin()) then return false, "Only whoever planned it can call it off." end
    LC.OpPlan = nil
    Radio("resistance", "The operation is called off: " .. plan.label .. ".")
    for _, p in ipairs(player.GetAll()) do SyncMenu(p) end
    return true
end

local function Fire(plan)
    if LC.Skirmish then
        plan.waiting = true
        if CurTime() - plan.fireAt > WAIT_MAX then
            LC.OpPlan = nil
            Radio("resistance", "The streets are too hot. The operation is called off: " .. plan.label .. ".")
        end
        return
    end
    local ok = LC.LaunchRebelOp and LC.LaunchRebelOp(plan.kind, plan.pos, plan.data)
    LC.OpPlan = nil
    if not ok then
        Radio("resistance", "The fighters couldn't get there. The operation is off: " .. plan.label .. ".")
        return
    end
    if LC.Skirmish then LC.Skirmish.planned = plan end
    plan.started = CurTime()
    for p in pairs(plan.joined) do
        if IsValid(p) then
            if LC.SetWaypoint then LC.SetWaypoint(p, plan.pos, "The operation", 200) end
            p:ChatPrint("[Freq 7] Go: " .. plan.label .. ". It's marked on your screen.")
        end
    end
    hook.Run("LivingCityOpStarted", plan)
end
LC.FireOp = Fire

hook.Add("LivingCityRebelOpDone", "LivingCityOpPlan", function(purpose, sk)
    local plan = sk and sk.planned
    if not plan then return end
    local paid = 0
    for p in pairs(plan.joined) do
        if IsValid(p) and p:Alive() and p:GetPos():DistToSqr(plan.pos) < 1500 * 1500 then
            paid = paid + 1
            if LC.AddXP then LC.AddXP(p, REWARD_XP, "a planned operation") end
            if LC.AddCredits then LC.AddCredits(p, REWARD_CR, "a planned operation") end
        end
    end
    if IsValid(plan.by) and LC.AddXP then LC.AddXP(plan.by, PLANNER_XP, "planned an operation that worked") end
    Radio("resistance", string.format("The operation worked: %s. %d of ours were there.", plan.label, paid))
end)

------------------------------------------------------------------------
-- Bounties
------------------------------------------------------------------------

LC.Bounties = LC.Bounties or {} -- [target] = { amount, by }

function LC.CanPostBounty(ply)
    if not cvBounty:GetBool() or not IsValid(ply) then return false, "No bounties here." end
    local f = Faction(ply)
    if f == "admin" then return true end
    if f == "cp" and Rank(ply) >= 3 then return true end
    return false, "Only the Administrator, or a Division Leader and up, puts a price on a head."
end

local function SyncBounties(ply)
    if not LC.CanPostBounty(ply) then
        if ply:GetNW2String("lc_bounty_menu", "") ~= "" then ply:SetNW2String("lc_bounty_menu", "") end
        return
    end
    local list = {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and LC.PlayerIsWanted and LC.PlayerIsWanted(p) and not LC.PlayerIsCP(p) then
            local b = LC.Bounties[p]
            list[#list + 1] = { id = p:EntIndex(), name = Name(p), why = p:GetNW2String("lc_wanted_reason", ""), bounty = b and b.amount or nil }
        end
    end
    ply:SetNW2String("lc_bounty_menu", util.TableToJSON(list) or "")
end

function LC.PostBounty(ply, target, amount)
    local ok, why = LC.CanPostBounty(ply)
    if not ok then return false, why end
    if not IsValid(target) or not target:IsPlayer() or not (LC.PlayerIsWanted and LC.PlayerIsWanted(target)) then return false, "Only on someone wanted." end
    if LC.Bounties[target] then return false, "There's a price on them already." end
    if (ply.lcBountyNext or 0) > CurTime() then return false, string.format("You posted one just now. (%ds)", math.ceil(ply.lcBountyNext - CurTime())) end
    amount = tonumber(amount) == 100 and 100 or 50
    ply.lcBountyNext = CurTime() + 120
    LC.Bounties[target] = { amount = amount, by = ply }
    TellUnits(string.format("[CP net] BOUNTY: %d credits for bringing in %s (%s). Posted by %s.", amount, Name(target), target:GetNW2String("lc_wanted_reason", "wanted"), Name(ply)))
    target:ChatPrint(string.format("[Living City] There's a price on your head: %d credits to the unit who brings you in.", amount))
    if LC.Notice then LC.Notice(target, "warn", "A price on your head", amount .. " credits to the unit who brings you in.", 8) end
    hook.Run("LivingCityBountyPosted", ply, target, amount)
    return true
end

hook.Add("LivingCityIncarcerated", "LivingCityBounty", function(ply, secs, reason, arrester)
    local b = LC.Bounties[ply]
    if not b then return end
    LC.Bounties[ply] = nil
    if IsValid(arrester) and arrester:IsPlayer() and LC.PlayerIsCP(arrester) then
        if LC.AddCredits then LC.AddCredits(arrester, b.amount, "a bounty") end
        if LC.AddXP then LC.AddXP(arrester, 10, "brought in a wanted person with a price on their head") end
        TellUnits(string.format("[CP net] %s collected the bounty on %s: %d credits.", Name(arrester), Name(ply), b.amount))
    else
        TellUnits(string.format("[CP net] %s was brought in. The bounty lapses.", Name(ply)))
    end
end)

------------------------------------------------------------------------

timer.Create("LivingCityOpPlan", 2, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        local plan = LC.OpPlan
        if plan then
            if not IsValid(plan.by) and next(plan.joined) == nil then LC.OpPlan = nil
            elseif now >= plan.fireAt then Fire(plan) end
        end
        for target, b in pairs(LC.Bounties) do
            if not IsValid(target) or not (LC.PlayerIsWanted and LC.PlayerIsWanted(target)) then LC.Bounties[target] = nil end
        end
        for _, p in ipairs(player.GetAll()) do
            SyncMenu(p)
            SyncBounties(p)
        end
    end)
    if not ok and LC.Error then LC.Error("op plan", err) end
end)

-- The menu's actions (F2).
local function Wrap()
    if LC.MenuActions then
        LC.MenuActions.planop, LC.MenuActions.joinop, LC.MenuActions.cancelop, LC.MenuActions.bounty = true, true, true, true
    end
end
Wrap()
hook.Add("Initialize", "LivingCityOpPlan", Wrap)
hook.Add("PlayerSay", "LivingCityOpPlan", function(ply, text)
    local t = string.Trim(tostring(text or ""))
    local cmd, rest = string.match(t, "^[!/](%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    local ok, why
    if cmd == "planop" then
        local i, m = string.match(rest or "", "^(%d+):(%d+)$")
        ok, why = LC.PlanOp(ply, tonumber(i), tonumber(m))
    elseif cmd == "joinop" then ok, why = LC.JoinOp(ply)
    elseif cmd == "cancelop" then ok, why = LC.CancelOp(ply)
    elseif cmd == "bounty" then
        local id, amt = string.match(rest or "", "^(%d+):(%d+)$")
        ok, why = LC.PostBounty(ply, Entity(tonumber(id) or 0), tonumber(amt))
    else
        return
    end
    if not ok and why then ply:ChatPrint("[Living City] " .. why) end
    return ""
end)
