--[[
    Living City (server): informing to Civil Protection

    The owner, 17 November: "When an assassination attempt ends with the
    assassin neither arrested nor killed, citizens can inform on them. Walk up
    to a Civil Protection unit (NPC or player), press E, choose Inform: a list
    of things to report, one being 'I know where the assassin is' (with its
    reward shown). The unit radios it in out loud and follows the player; at
    some point 2 Overwatch soldiers join ... The objective becomes 'Lead Civil
    Protection to the traitor', 5 minutes. Success: the player brings them
    within 50 feet of the assassin measured as walking distance along the path
    nodes ... Reward: 250 Civil Standing and 250 credits." Built so more kinds
    of informing plug into the same list (LC.InformKindAdd), "the owner wants
    citizens able to live off informing alone".

    Settled 19 November (the owner): only a citizen who saw the assassin with
    their own eyes in the last 15 minutes, and after the attempt, can say so;
    nothing on screen points to the assassin while leading. Running out of
    time costs 10 standing and 10 minutes before they may report it again.

    Who informs     A citizen (not a unit, the Resistance, the Administrator or
                    anyone else), alive.
    The assassin    A player marked for an attempt on the Administrator's life
                    (lc_regicide, sv_livingcity_adminsecurity.lua), alive and
                    free: not in the cells or held by the Combine.
    Seen            Within 2000 units, in front of them, nothing solid between
                    their eyes, checked every two seconds.
    Where           E on a Civil Protection unit (a player or one of the city's),
                    or F1 > Inform, looking at one. Only shown with something to
                    report.
    The lead        A job of its own, "Lead Civil Protection to the traitor",
                    five minutes (the job tracker shows the clock). The unit
                    follows; 20 to 40 seconds in, two Overwatch soldiers join
                    (ones nearby, else brought in out of sight). Done when one of
                    them is within 800 units (50 feet) of the assassin, walking.
    Afterwards      Done: 250 credits and 250 standing, and the units go for the
                    assassin. Out of time (or given up): 10 standing, and no new
                    report of it for 10 minutes. The assassin caught or gone, or
                    the informer dead: it ends without a word against anyone.

    lc_inform 1/0
]]

LC = LC or {}

local cvOn = CreateConVar("lc_inform", "1", FCVAR_ARCHIVE, "Informing to Civil Protection: E on a unit (or F1 > Inform) to report what you know, first of all where the assassin who got away is")

local SEEN_SECS = 900            -- a sighting this recent counts (the owner, 19 November: 15 minutes)
local SIGHT_RANGE = 2000
local LEAD_SECS = 300            -- the owner: 5 minutes
local REACH = 800                -- 50 feet, walking
local PAY_CREDITS, PAY_STANDING = 250, 250
local FAIL_STANDING, FAIL_WAIT = -10, 600
local SOLDIERS = 2
local ASK_RANGE = 200

if util.AddNetworkString then
    util.AddNetworkString("lc_inform")
    util.AddNetworkString("lc_inform_do")
end

local function On() return cvOn:GetBool() end
local function Sid(p) return (p.SteamID64 and p:SteamID64()) or tostring(p:EntIndex()) end
local function Faction(p) return p:GetNW2String("lcf_faction", "") end
local function IsUnitPly(p) return IsValid(p) and p:IsPlayer() and LC.PlayerIsCP ~= nil and LC.PlayerIsCP(p) end

-- Who may inform: a citizen, alive.
function LC.MayInform(p)
    if not (IsValid(p) and p:IsPlayer() and p:Alive()) then return false end
    local f = Faction(p)
    if f ~= "citizen" and f ~= "" then return false end
    if IsUnitPly(p) then return false end
    if (LC.InCustody and LC.InCustody(p)) or (LC.HeldByCombine and LC.HeldByCombine(p)) then return false end
    return true
end

-- A unit someone can report to: a Civil Protection player, or one of the city's own, not fighting.
function LC.InformUnit(e)
    if not IsValid(e) then return false end
    if e:IsPlayer() then return IsUnitPly(e) and e:Alive() and e:GetNW2Float("lc_downed_until", 0) <= CurTime() end
    local st = LC.NPCs and LC.NPCs[e]
    return st ~= nil and st.role == "cop" and st.state ~= "hostile" and (e.Health == nil or e:Health() > 0)
end

------------------------------------------------------------------------
-- The assassin who got away, and who saw them
------------------------------------------------------------------------

-- When their attempt was (os.time), read now and then (it lives with the character: lc_regicide).
local function AttemptAt(p)
    if (p.lcRegicideReadAt or -99) < CurTime() - 30 then
        p.lcRegicideReadAt = CurTime()
        p.lcRegicideAt = tonumber(p.GetPData and p:GetPData("lc_regicide", "") or "") or 0
    end
    return p.lcRegicideAt or 0
end
LC.InformAttemptAt = AttemptAt

function LC.AssassinFree(p)
    if not (IsValid(p) and p:IsPlayer() and p:Alive()) then return false end
    if not p:GetNW2Bool("lc_regicide", false) then return false end
    if not (LC.AdminNeverForgotten and LC.AdminNeverForgotten(p)) then return false end
    if (LC.InCustody and LC.InCustody(p)) or (LC.HeldByCombine and LC.HeldByCombine(p)) then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(p) then return false end
    return true
end

function LC.FreeAssassins()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if LC.AssassinFree(p) then out[#out + 1] = p end end
    return out
end

local function Sees(viewer, target)
    local a, b = viewer:EyePos(), target:EyePos()
    local d = b - a
    local dist = d:Length()
    if dist > SIGHT_RANGE then return false end
    if dist > 120 and viewer:GetAimVector():Dot(d / dist) < 0.5 then return false end
    local tr = util.TraceLine({ start = a, endpos = b, mask = MASK_OPAQUE, filter = { viewer, target } })
    return not (tr and tr.Hit)
end
LC.InformSees = Sees

-- Seen now: kept (os.time) for SEEN_SECS, only after their attempt.
function LC.InformSaw(viewer, target, at)
    at = at or os.time()
    if at < AttemptAt(target) then return false end
    viewer.lcSawAssassin = viewer.lcSawAssassin or {}
    viewer.lcSawAssassin[Sid(target)] = at
    return true
end

-- The free assassin this one saw last, within the time and after their attempt; nil if none.
function LC.InformSeenAssassin(ply)
    local best, bt
    local now = os.time()
    for _, a in ipairs(LC.FreeAssassins()) do
        local t = ply.lcSawAssassin and ply.lcSawAssassin[Sid(a)]
        if a ~= ply and t and now - t <= SEEN_SECS and t >= AttemptAt(a) and (not bt or t > bt) then best, bt = a, t end
    end
    return best
end

------------------------------------------------------------------------
-- What there is to report (more kinds plug in here)
------------------------------------------------------------------------

-- kind: { id, order, label = function(ply) or string, available = function(ply) -> what, or nil,
--   start = function(ply, unit, what) -> ok, why }
LC.InformKinds = LC.InformKinds or {}
function LC.InformKindAdd(kind)
    for i = #LC.InformKinds, 1, -1 do if LC.InformKinds[i].id == kind.id then table.remove(LC.InformKinds, i) end end
    LC.InformKinds[#LC.InformKinds + 1] = kind
    table.sort(LC.InformKinds, function(a, b) return (a.order or 50) < (b.order or 50) end)
end

LC.InformLeads = LC.InformLeads or {} -- [informer] = the lead under way

-- What this player could report now: { { id, label, what, disabled } }
function LC.InformOptions(ply)
    local out = {}
    if not On() or not LC.MayInform(ply) or LC.InformLeads[ply] then return out end
    local busy = LC.QuestOf and LC.QuestOf[ply] ~= nil
    for _, k in ipairs(LC.InformKinds) do
        local wait = ply.lcInformWaits and ply.lcInformWaits[k.id]
        if not (wait and wait > CurTime()) then
            local ok, what = LC.Try(k.available, ply)
            if ok and what then
                local label = isfunction(k.label) and k.label(ply, what) or tostring(k.label)
                out[#out + 1] = { id = k.id, label = busy and (label .. " (finish your job first)") or label, what = what, disabled = busy }
            end
        end
    end
    return out
end

function LC.InformOpen(ply, unit)
    if not On() or not LC.MayInform(ply) or not LC.InformUnit(unit) then return false end
    if ply:GetPos():DistToSqr(unit:GetPos()) > ASK_RANGE * ASK_RANGE then return false end
    local opts = LC.InformOptions(ply)
    if #opts == 0 then return false end
    ply.lcInformAskedAt = CurTime()
    net.Start("lc_inform")
    net.WriteEntity(unit)
    net.WriteUInt(math.min(#opts, 8), 4)
    for i = 1, math.min(#opts, 8) do
        net.WriteString(opts[i].id)
        net.WriteString(opts[i].label)
        net.WriteBool(opts[i].disabled == true)
    end
    net.Send(ply)
    return true
end

local function CloseMenu(ply)
    net.Start("lc_inform")
    net.WriteEntity(NULL)
    net.Send(ply)
end

-- Report it. Returns ok, and what's said to them when it isn't.
function LC.InformDo(ply, unit, id)
    if not On() or not LC.MayInform(ply) or not LC.InformUnit(unit) then return false end
    if ply:GetPos():DistToSqr(unit:GetPos()) > ASK_RANGE * ASK_RANGE then return false, "Get closer to the unit." end
    for _, o in ipairs(LC.InformOptions(ply)) do
        if o.id == id then
            if o.disabled then return false, "Finish the job you're on first." end
            for _, k in ipairs(LC.InformKinds) do
                if k.id == id then
                    local ok, started, why = LC.Try(k.start, ply, unit, o.what)
                    if not ok then return false end
                    return started, why
                end
            end
        end
    end
    return false
end

net.Receive("lc_inform_do", function(_, ply)
    local unit, id = net.ReadEntity(), net.ReadString()
    if (ply.lcInformDoNext or 0) > CurTime() then return end
    ply.lcInformDoNext = CurTime() + 0.5
    if LC.InformDo(ply, unit, id) then CloseMenu(ply) end
end)

------------------------------------------------------------------------
-- The lead: "Lead Civil Protection to the traitor"
------------------------------------------------------------------------

local TEMPLATE = { id = "inform_assassin", factions = {}, noJobPay = true } -- (given outright: never on a board; its reward is its own)
local Finished

-- Walking distance between two places along the paths (the drawn network, else the map's nodes); the
-- straight line when there are none. math.huge when there's no way through.
function LC.InformWalkDist(a, b)
    local straight = a:Distance(b)
    if straight > REACH then return straight end
    local route = LC.BuildRoute and LC.BuildRoute(a, b, "cop")
    if route == false then return math.huge end
    if not istable(route) or #route == 0 then return straight end
    local d, last = 0, a
    for _, p in ipairs(route) do d = d + last:Distance(p) last = p end
    return d + last:Distance(b)
end

local function Enlist(L, npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st then return false end
    st.questLock, st.informFor = true, L.ply
    if LC.SetState then LC.SetState(npc, st, "event") else st.state = "event" end
    st.eventUntil = CurTime() + LEAD_SECS + 60
    L.escorts[#L.escorts + 1] = npc
    return true
end

local function Release(L, hunt)
    for _, npc in ipairs(L.escorts) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if st then
            st.questLock, st.informFor, st.eventUntil = nil, nil, nil
            if hunt and IsValid(L.target) then
                st.armed = true
                if LC.ResponseSquads then LC.ResponseSquads[npc] = { untilT = CurTime() + 180, target = L.target } end
                if LC.MakeOneHostile then LC.MakeOneHostile(npc, st, L.target) end
            else
                if LC.SetState then LC.SetState(npc, st, "idle") else st.state = "idle" end
                -- (brought in for this: they go again once out of sight, as a response squad does)
                if L.spawned[npc] and LC.ResponseSquads then LC.ResponseSquads[npc] = { untilT = CurTime() + 5 } end
            end
        end
    end
end

local function SoldiersJoin(L)
    local ply = L.ply
    local have = 0
    for npc, st in pairs(LC.NPCs or {}) do
        if have >= SOLDIERS then break end
        if IsValid(npc) and st.role == "soldier" and not st.questLock and st.state ~= "hostile" and st.state ~= "event"
            and npc:GetPos():DistToSqr(ply:GetPos()) < 1500 * 1500 and Enlist(L, npc) then
            have = have + 1
        end
    end
    if have < SOLDIERS and LC.SpawnSoldier then
        local spot = LC.AlarmSquadSpot and LC.AlarmSquadSpot(ply:GetPos())
        for i = have + 1, SOLDIERS do
            if not spot then break end
            local npc, st = LC.SpawnSoldier(spot + Vector(math.cos(i) * 40, math.sin(i) * 40, 4))
            if IsValid(npc) and st then
                st.unmanaged = true
                L.spawned[npc] = true
                Enlist(L, npc)
            end
        end
    end
end

local function StartAssassin(ply, unit, target)
    if not LC.GiveQuest then return false end
    local L = { ply = ply, kind = "assassin", target = target, unit = unit, escorts = {}, spawned = {}, startT = CurTime(),
        soldiersAt = CurTime() + math.Rand(20, 40) }
    local q = LC.GiveQuest(ply, {
        tmpl = TEMPLATE, title = "Lead Civil Protection to the traitor", limit = LEAD_SECS, reward = 0,
        stages = { { kind = "count", event = "inform_led", need = 1, text = "Lead them to the traitor" } },
        onFinish = function(q, success) Finished(ply, q, success) end,
    })
    if not q then return false, "Finish the job you're on first." end
    L.q = q
    LC.InformLeads[ply] = L
    -- he radios it in (the Civil Protection net: a unit player hears who to follow) and comes along
    if not unit:IsPlayer() then
        unit:EmitSound("npc/metropolice/vo/copy.wav", 75)
        Enlist(L, unit)
    end
    if LC.RadioNotice then
        LC.RadioNotice("cp", "Citizen " .. ply:Nick() .. " has eyes on the assassin. " .. (unit:IsPlayer() and (unit:Nick() .. ", follow them.") or "Unit following."))
    end
    hook.Run("LivingCityInformLead", ply, "assassin", target, unit)
    return true
end

LC.InformKindAdd({
    id = "assassin", order = 10,
    label = function() return string.format("I know where the assassin is (%d credits, %d standing)", PAY_CREDITS, PAY_STANDING) end,
    available = function(ply) return LC.InformSeenAssassin(ply) end,
    start = StartAssassin,
})

-- It's over: done (paid, and the units go for them), or failed (out of time or given up: a wasted report).
Finished = function(ply, q, success)
    local L = LC.InformLeads[ply]
    if not L or L.q ~= q then return end
    LC.InformLeads[ply] = nil
    if not IsValid(ply) then Release(L, false) return end
    if success then
        if LC.AddCredits then LC.AddCredits(ply, PAY_CREDITS, "informing on the assassin") end
        if LC.AddStanding then LC.AddStanding(ply, PAY_STANDING, "informing on the assassin") end
        Release(L, true)
        local by = L.escorts[1]
        if IsValid(by) then by:EmitSound("npc/metropolice/vo/contactwith243suspect.wav", 80) end
        if LC.RadioNotice then LC.RadioNotice("cp", "Contact with the assassin. All units, move in.") end
        if LC.ChronicleAdd and LC.MindsWhoKey then
            local key = LC.MindsWhoKey(ply)
            if key then LC.ChronicleAdd({ k = "informed", s = key, o = IsValid(L.target) and LC.MindsWhoKey(L.target) or nil,
                pred = "led Civil Protection to the would-be assassin", pos = ply:GetPos(), w = 3 }) end
        end
        hook.Run("LivingCityInformed", ply, L.kind, L.target, true)
    else
        Release(L, false)
        if LC.AddStanding then LC.AddStanding(ply, FAIL_STANDING, "a wasted report") end
        ply.lcInformWaits = ply.lcInformWaits or {}
        ply.lcInformWaits[L.kind] = CurTime() + FAIL_WAIT
        hook.Run("LivingCityInformed", ply, L.kind, L.target, false)
    end
end

-- Ended by what happened, not by them: nothing against anyone, and nothing said (the job is simply gone).
local function Drop(ply, L)
    LC.InformLeads[ply] = nil
    Release(L, false)
    if L.q and LC.WithdrawQuest then LC.WithdrawQuest(L.q) end
end

local function FollowTick(L)
    local ply = L.ply
    for _, npc in ipairs(L.escorts) do
        local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
        if st then
            st.eventUntil = CurTime() + 60
            local d = npc:GetPos():DistToSqr(ply:GetPos())
            if d > 160 * 160 then
                npc:SetLastPosition(ply:GetPos())
                npc:SetSchedule(d > 500 * 500 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
            elseif LC.Face then
                LC.Face(npc, ply:GetPos())
            end
        end
    end
end

-- How near the units are to the assassin, walking (the nearest of them).
function LC.InformNearest(L)
    if not IsValid(L.target) then return math.huge end
    local best = math.huge
    local who = {}
    for _, npc in ipairs(L.escorts) do if IsValid(npc) then who[#who + 1] = npc end end
    if IsValid(L.unit) and L.unit:IsPlayer() then who[#who + 1] = L.unit end
    for _, e in ipairs(who) do
        local d = LC.InformWalkDist(e:GetPos(), L.target:GetPos())
        if d < best then best = d end
    end
    return best
end

function LC.InformLeadTick(now)
    for ply, L in pairs(LC.InformLeads) do
        if not IsValid(ply) then
            LC.InformLeads[ply] = nil
            Release(L, false)
        elseif not ply:Alive() then
            Drop(ply, L)
        elseif not LC.AssassinFree(L.target) then
            Drop(ply, L)
        elseif L.q and L.q.done then
            LC.InformLeads[ply] = nil
            Release(L, false)
        else
            for i = #L.escorts, 1, -1 do if not IsValid(L.escorts[i]) then table.remove(L.escorts, i) end end
            if not L.soldiersDone and now >= L.soldiersAt then
                L.soldiersDone = true
                SoldiersJoin(L)
            end
            FollowTick(L)
            if LC.InformNearest(L) <= REACH then LC.QuestEvent("inform_led", ply) end
        end
    end
end

function LC.InformSightTick()
    if not On() then return end
    local free = LC.FreeAssassins()
    for _, p in ipairs(player.GetAll()) do
        local can = false
        if LC.MayInform(p) then
            for _, a in ipairs(free) do
                if a ~= p and Sees(p, a) then LC.InformSaw(p, a) end
            end
            can = #LC.InformOptions(p) > 0
        end
        if p:GetNW2Bool("lc_inform_can", false) ~= can then p:SetNW2Bool("lc_inform_can", can) end
    end
end

timer.Create("LivingCityInform", 1, 0, function()
    if not On() then return end
    local ok, err = LC.Try(LC.InformLeadTick, CurTime())
    if not ok and LC.Error then LC.Error("informing: the lead", err) end
end)
timer.Create("LivingCityInformSight", 2, 0, function()
    local ok, err = LC.Try(LC.InformSightTick)
    if not ok and LC.Error then LC.Error("informing: who saw the assassin", err) end
end)

------------------------------------------------------------------------
-- Where it's asked: E on a unit, and F1 > Inform
------------------------------------------------------------------------

hook.Add("LivingCityPlayerUsedNPC", "LivingCityInform", function(ply, npc, st)
    if not st or st.role ~= "cop" or not On() then return end
    if not ply:GetNW2Bool("lc_inform_can", false) then return end
    LC.InformOpen(ply, npc)
end)

-- E on a Civil Protection player
hook.Add("KeyPress", "LivingCityInform", function(ply, key)
    if key ~= IN_USE or not On() or not ply:GetNW2Bool("lc_inform_can", false) then return end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e:IsPlayer() and tr.HitPos:DistToSqr(ply:EyePos()) < 120 * 120 then LC.InformOpen(ply, e) end
end)

LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.informunit = function(ply, target)
    if not LC.InformUnit(target) then return false end
    if LC.InformOpen(ply, target) then return true end
    return false, "There's nothing you could tell them."
end

-- Gone from the server mid-lead: the units go back.
hook.Add("PlayerDisconnected", "LivingCityInform", function(ply)
    local L = LC.InformLeads[ply]
    if L then LC.InformLeads[ply] = nil Release(L, false) end
end)

------------------------------------------------------------------------
-- The poster (lc_civposter.lua): while an assassin is free, every other plain curfew notice is
-- "REPORT THE TRAITOR ASSASSIN" instead.
------------------------------------------------------------------------

function LC.InformPosterKind(ent)
    if not On() or not IsValid(ent) or ent:EntIndex() % 2 ~= 0 then return nil end
    if #LC.FreeAssassins() == 0 then return nil end
    return "assassin"
end
