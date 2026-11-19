--[[
    Living City (server): firing squads, public executions

    The owner, 10 November: "firing squads and public punishments and
    executions YES". Settled 19 November: only the Administrator orders one (a
    player from F2 > City orders, or the city's own when she answers a killing
    by the Resistance with a reprisal: sv_livingcity_rebelanswer.lua); a player
    shot by the squad is dead for good ("yes real death please"), "but I also
    want it to automatically pop up as a job for ALL resistance members so there
    is an increased chance of a rescue".

    The wall       The editor's "Point: execution wall" (kind execwall): the
                   condemned stands there, back to the wall, facing the way the
                   point faces; the squad lines up in front. None placed: no
                   firing squads.
    Who            Someone in the Combine's cells who is of the Resistance, or
                   tried to kill her (lc_regicide), or is in for murder; or one
                   of the city's own held there for the Resistance.
    The order      The PA says who, and that it is in two minutes. Every member
                   of the Resistance online is given the job "Stop the
                   execution" (one posting, everyone can work on it together).
                   Thirty seconds on, the condemned is taken from the cell to the
                   wall, cuffed and held there; four Overwatch soldiers come in
                   out of sight and line up. Citizens nearby come to watch.
    Rescue         Uncuff the condemned (F1 > Uncuff, as anyone cuffed), or bring
                   the whole squad down, before the volley. The condemned runs:
                   an escape from custody (wanted, as any escape). Everyone on the
                   job is done.
    The volley     At two minutes. A player is dead for good (their character
                   ends); one of the city's own is dead. Written in the chronicle
                   at its heaviest; authority up, morale down.

    lc_firingsquad 1/0
]]

LC = LC or {}

local cvOn = CreateConVar("lc_firingsquad", "1", FCVAR_ARCHIVE, "Firing squads: the Administrator orders a prisoner shot at the editor's execution wall (two minutes' warning; the Resistance may rescue them)")

local WARN = 120       -- the PA, then the volley this long after
local TAKE = 30        -- the condemned taken to the wall after this long
local SQUAD = 4
local LINE_OUT = 300   -- how far in front of the wall the squad stands
local LINE_GAP = 70
local WATCHERS = 6
local JOB = "res_stopexec"

if util.AddNetworkString then
    util.AddNetworkString("lc_fsquad")
    util.AddNetworkString("lc_fsquad_ask")
    util.AddNetworkString("lc_fsquad_do")
end

local function On() return cvOn:GetBool() end
local function Key(p) return LC.MindsWhoKey and LC.MindsWhoKey(p) or nil end
local function NameOf(e)
    if not IsValid(e) then return "someone" end
    if e:IsPlayer() then return e:Nick() end
    return (LC.NPCStr and LC.NPCStr(e, "lc_pname", "") ~= "" and LC.NPCStr(e, "lc_pname", "")) or (e.lcProfile and e.lcProfile.name) or "a prisoner"
end
local function IdOf(e)
    if not IsValid(e) then return nil end
    if e:IsPlayer() then return Key(e) end
    return e.lcProfile and e.lcProfile.id
end

LC.FiringSquad = LC.FiringSquad or nil -- the one under way: { target, by, why, wall, startT, stage, squad = {}, watchers = {} }

function LC.FiringSquadWall()
    local pts = LC.PointsOfKind and LC.PointsOfKind("execwall") or {}
    return pts[1]
end

-- Why this one may be shot (a word for the list), or nil.
function LC.FiringSquadCrime(t)
    if not IsValid(t) then return nil end
    if t:IsPlayer() then
        local pr = LC.Prisoners and LC.Prisoners[t]
        if not pr or not t:Alive() then return nil end
        if LC.AdminNeverForgotten and LC.AdminNeverForgotten(t) then return "tried to kill the Administrator" end
        if t:GetNW2String("lcf_faction", "") == "resistance" then return "the Resistance" end
        if string.find(string.lower(tostring(pr.reason or "")), "murder", 1, true) then return "murder" end
        return nil
    end
    local st = LC.NPCs and LC.NPCs[t]
    if st and st.state == "jailed" and (st.rebel or st.role == "rebel") then return "the Resistance" end
    return nil
end

function LC.FiringSquadCandidates()
    local out = {}
    for p in pairs(LC.Prisoners or {}) do
        local why = LC.FiringSquadCrime(p)
        if why then out[#out + 1] = { ent = p, name = p:Nick(), why = why } end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.state == "jailed" then
            local why = LC.FiringSquadCrime(npc)
            if why then out[#out + 1] = { ent = npc, name = NameOf(npc), why = why } end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- The Administrator (a player, or nil for the city's own). Returns ok, or false and why.
function LC.FiringSquadOrder(by, target, why)
    if not On() then return false, "There are no firing squads in this city." end
    if IsValid(by) and by:GetNW2String("lcf_faction", "") ~= "admin" then return false, "Only the Administrator orders that." end
    if LC.FiringSquad then return false, "One is under way already." end
    local wall = LC.FiringSquadWall()
    if not wall then return false, "There is no execution wall (the editor's Point: execution wall)." end
    local crime = LC.FiringSquadCrime(target)
    if not crime then return false, "They can't be shot for what they're in for." end
    local F = { target = target, by = by, why = why or "order", crime = crime, wall = wall, startT = CurTime(), stage = "called",
        squad = {}, watchers = {}, name = NameOf(target) }
    LC.FiringSquad = F
    if LC.Announce then
        LC.Announce("execution", nil, string.format("%s, enemy of the city, will be executed at the wall in two minutes. Citizens, attend.", F.name))
    end
    -- every member of the Resistance online is told: a job they can all work on together
    if LC.PostDirective then LC.PostDirective(JOB) end
    hook.Run("LivingCityFiringSquadOrdered", target, by, F.why)
    return true
end

------------------------------------------------------------------------
-- What happens
------------------------------------------------------------------------

local function WallDir(F) return Angle(0, F.wall.yaw or 0, 0):Forward() end
local function LineSpot(F, i)
    local fwd = WallDir(F)
    local right = Angle(0, (F.wall.yaw or 0) - 90, 0):Forward()
    local p = F.wall.pos + fwd * LINE_OUT + right * ((i - (SQUAD + 1) / 2) * LINE_GAP)
    return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 40))) or p
end

local function Lock(npc, st, F)
    st.questLock, st.fsquad = true, true
    if LC.SetState then LC.SetState(npc, st, "event") else st.state = "event" end
    st.eventUntil = CurTime() + WARN + 120
end
local function Unlock(npc, st)
    st.questLock, st.fsquad, st.eventUntil = nil, nil, nil
    if LC.SetState then LC.SetState(npc, st, "idle") else st.state = "idle" end
end

local function BringSquad(F)
    local spot = LC.AlarmSquadSpot and LC.AlarmSquadSpot(F.wall.pos) or (F.wall.pos + WallDir(F) * (LINE_OUT + 400))
    if not LC.SpawnSoldier then return end
    for i = 1, SQUAD do
        local npc, st = LC.SpawnSoldier(spot + Vector(math.cos(i) * 40, math.sin(i) * 40, 4))
        if IsValid(npc) and st then
            st.unmanaged = true
            Lock(npc, st, F)
            F.squad[#F.squad + 1] = { npc = npc, spot = LineSpot(F, i) }
        end
    end
end

local function CallWatchers(F)
    local behind = F.wall.pos + WallDir(F) * (LINE_OUT + 260)
    for npc, st in pairs(LC.NPCs or {}) do
        if #F.watchers >= WATCHERS then break end
        if IsValid(npc) and st.role == "citizen" and not st.questLock and (st.state == "idle" or st.state == "moving")
            and npc:GetPos():DistToSqr(F.wall.pos) < 2500 * 2500 and LC.GoTo then
            local p = behind + Vector(math.Rand(-220, 220), math.Rand(-220, 220), 0)
            if LC.GoTo(npc, st, p, false) then F.watchers[#F.watchers + 1] = npc end
        end
    end
end

-- To the wall: cuffed, held still, facing out.
local function TakeOut(F)
    local t = F.target
    if not IsValid(t) then return false end
    local spot = F.wall.pos + Vector(0, 0, 4)
    if t:IsPlayer() then
        local pr = LC.Prisoners and LC.Prisoners[t]
        if not pr then return false end
        pr.work = true -- (out of the cell under guard: not an escape; the squad watches them)
        pr.untilT = math.max(pr.untilT, CurTime() + WARN + 60)
        if t.ScreenFade then t:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 1.5, 0.5) end
        t:SetPos(spot)
        t:SetEyeAngles(Angle(0, F.wall.yaw or 0, 0))
        if LC.TiePlayer and not (LC.IsTied and LC.IsTied(t)) then LC.TiePlayer(t, nil) end
        if t.Freeze then t:Freeze(true) end
    else
        local st = LC.NPCs and LC.NPCs[t]
        if not st then return false end
        Lock(t, st, F)
        t:SetPos(spot)
        if LC.Face then LC.Face(t, F.wall.pos + WallDir(F) * 100) end
    end
    F.atWall = true
    return true
end

local function JobEvent(name)
    for p, q in pairs(LC.QuestOf or {}) do
        if IsValid(p) and q and not q.done and q.tmpl and q.tmpl.id == JOB and LC.QuestEvent then LC.QuestEvent(name, p) end
    end
end

local function Finish(F, how)
    if LC.FiringSquad ~= F then return end
    LC.FiringSquad = nil
    F.over = how
    LC.FiringSquadLast = { target = F.target, how = how }
    for _, s in ipairs(F.squad) do
        local st = IsValid(s.npc) and LC.NPCs and LC.NPCs[s.npc]
        if st then
            Unlock(s.npc, st)
            if LC.ResponseSquads then LC.ResponseSquads[s.npc] = { untilT = CurTime() + 20 } end -- (they go once out of sight)
        end
    end
    local t = F.target
    if how == "rescued" and IsValid(t) then
        if t:IsPlayer() then
            if t.Freeze then t:Freeze(false) end
            local pr = LC.Prisoners and LC.Prisoners[t]
            if pr then pr.work = nil end
            if LC.EscapePrisoner then LC.EscapePrisoner(t) end
        else
            local st = LC.NPCs and LC.NPCs[t]
            if st then st.jailUntil = nil Unlock(t, st) end
        end
        JobEvent("fsquad_rescued")
    elseif how == "cancelled" and IsValid(t) and t:IsPlayer() then
        if t.Freeze then t:Freeze(false) end
        local pr = LC.Prisoners and LC.Prisoners[t]
        if pr then pr.work = nil if LC.ReturnToCell then LC.ReturnToCell(t) end end
        if LC.Untie and LC.IsTied and LC.IsTied(t) then LC.Untie(t, nil, false) end
    end
    hook.Run("LivingCityFiringSquadDone", t, how, F.why)
end
LC.FiringSquadFinish = Finish

local function Volley(F)
    local t = F.target
    local alive = {}
    for _, s in ipairs(F.squad) do if IsValid(s.npc) and s.npc:Health() > 0 then alive[#alive + 1] = s.npc end end
    for _, npc in ipairs(alive) do
        if LC.Face and IsValid(t) then LC.Face(npc, t:GetPos()) end
        npc:EmitSound("weapons/ar2/fire1.wav", 95)
    end
    local name, pos, id = F.name, IsValid(t) and t:GetPos() or F.wall.pos, IdOf(t)
    if IsValid(t) and t:IsPlayer() then
        if t.Freeze then t:Freeze(false) end
        local pr = LC.Prisoners and LC.Prisoners[t]
        if pr then
            LC.Prisoners[t] = nil
            if LC.Occupied and LC.Occupied[pr.cell] == t then LC.Occupied[pr.cell] = nil end
            t:SetNW2Float("lc_jail_until", 0)
            if t.RemovePData then t:RemovePData("lc_jail_left") end
        end
        if LC.Untie and LC.IsTied and LC.IsTied(t) then LC.Untie(t, nil, false) end
        -- (the owner, 19 November: "yes real death please")
        t.lcEndOfLife = "executed"
        timer.Simple(5, function() if IsValid(t) then t.lcEndOfLife = nil end end)
        t:Kill()
    elseif IsValid(t) then
        local st = LC.NPCs and LC.NPCs[t]
        if st then st.questLock, st.fsquad = nil, nil end
        if t.TakeDamage then t:TakeDamage(9999, alive[1], alive[1]) end
        if IsValid(t) and t:Health() > 0 then t:SetHealth(0) end
    end
    if LC.ChronicleAdd and id then
        LC.ChronicleAdd({ k = "shot", s = id, pred = "was shot by a firing squad at the wall, on the Administrator's order", pos = pos, w = 5 })
    end
    if LC.LedgerAdd then
        LC.LedgerAdd("authority", 3, "a public execution")
        LC.LedgerAdd("morale", -4, "a public execution")
    end
    Finish(F, "shot")
end

-- one second at a time
function LC.FiringSquadTick(now)
    local F = LC.FiringSquad
    if not F then return end
    local t = F.target
    local held
    if IsValid(t) and t:IsPlayer() then held = t:Alive() and LC.Prisoners ~= nil and LC.Prisoners[t] ~= nil
    else held = IsValid(t) and t:Health() > 0 end
    if not held then return Finish(F, IsValid(t) and t:IsPlayer() and t:Alive() and "rescued" or "cancelled") end
    local since = now - F.startT
    if F.stage == "called" and since >= 4 then
        F.stage = "coming"
        BringSquad(F)
        CallWatchers(F)
    end
    if F.stage == "coming" and since >= TAKE then
        if not TakeOut(F) then return Finish(F, "cancelled") end
        F.stage = "wall"
    end
    -- the squad walks to its line and faces the wall
    local alive = 0
    for _, s in ipairs(F.squad) do
        if IsValid(s.npc) and s.npc:Health() > 0 then
            alive = alive + 1
            local st = LC.NPCs and LC.NPCs[s.npc]
            if st then st.eventUntil = now + 60 end
            if s.npc:GetPos():DistToSqr(s.spot) > 40 * 40 then
                if (s.nextGo or 0) <= now then
                    s.nextGo = now + 2
                    s.npc:SetLastPosition(s.spot)
                    s.npc:SetSchedule(SCHED_FORCED_GO)
                end
            elseif LC.Face then
                LC.Face(s.npc, F.wall.pos)
            end
        end
    end
    if F.stage == "wall" then
        if #F.squad > 0 and alive == 0 then return Finish(F, "rescued") end
        if t:IsPlayer() and not (LC.IsTied and LC.IsTied(t)) then return Finish(F, "rescued") end
        if since >= WARN then return Volley(F) end
    end
end

timer.Create("LivingCityFiringSquad", 1, 0, function()
    if not On() then return end
    local ok, err = LC.Try(LC.FiringSquadTick, CurTime())
    if not ok and LC.Error then LC.Error("firing squad", err) end
end)

-- One of the city's own at the wall: a member of the Resistance pressing E on them cuts them loose.
hook.Add("LivingCityPlayerUsedNPC", "LivingCityFiringSquad", function(ply, npc)
    local F = LC.FiringSquad
    if not F or F.target ~= npc or not F.atWall then return end
    if ply:GetNW2String("lcf_faction", "") ~= "resistance" then return end
    Finish(F, "rescued")
end)

-- (the condemned uncuffed by anyone: the tick sees it and calls it a rescue)

------------------------------------------------------------------------
-- The Resistance's job: "Stop the execution", for all of them at once
------------------------------------------------------------------------

local TEMPLATE = {
    id = JOB, factions = { resistance = true }, squad = 16, violent = true, brings = true, recheck = true,
    recheckWhy = "It's over at the wall.",
    available = function() return LC.FiringSquad ~= nil and LC.FiringSquad.over == nil end,
    over = function(q)
        local F = LC.FiringSquad
        if F and F.target == q.data.target then return nil end
        local last = LC.FiringSquadLast
        if last and last.target == q.data.target and last.how == "rescued" then return true end -- (got out: everyone on it is done)
        if q.data.target and not (IsValid(q.data.target) and q.data.target:Alive()) then return false, "the squad fired first" end
        return false, "it's over"
    end,
    build = function()
        local F = LC.FiringSquad
        if not F then return nil end
        local left = math.max(30, WARN - (CurTime() - F.startT))
        return {
            title = "Stop the execution", reward = 40, limit = math.floor(left + 60), data = { target = F.target },
            desc = F.name .. " is to be shot at the wall. Get them out before the volley.",
            stages = {
                { kind = "goto", pos = F.wall.pos, r = 700, text = "Get to the wall (marked)" },
                { kind = "count", event = "fsquad_rescued", need = 1, text = "Uncuff them, or bring the squad down" },
            },
        }
    end,
}
if LC.QuestTemplates then
    for i = #LC.QuestTemplates, 1, -1 do if LC.QuestTemplates[i].id == TEMPLATE.id then table.remove(LC.QuestTemplates, i) end end
    LC.QuestTemplates[#LC.QuestTemplates + 1] = TEMPLATE
end

------------------------------------------------------------------------
-- Her F2 > City orders > Firing squad...
------------------------------------------------------------------------

function LC.FiringSquadMenu(ply)
    if not IsValid(ply) or ply:GetNW2String("lcf_faction", "") ~= "admin" then return false end
    local list = LC.FiringSquadCandidates()
    local note
    if not On() then note = "There are no firing squads in this city."
    elseif not LC.FiringSquadWall() then note = "There is no execution wall here (the editor's Point: execution wall)."
    elseif LC.FiringSquad then note = "One is under way."
    elseif #list == 0 then note = "Nobody in the cells is in for that." end
    net.Start("lc_fsquad")
    net.WriteString(note or "")
    local n = note and 0 or math.min(#list, 8)
    net.WriteUInt(n, 4)
    for i = 1, n do
        net.WriteEntity(list[i].ent)
        net.WriteString(list[i].name .. " (" .. list[i].why .. ")")
    end
    net.Send(ply)
    return true
end

net.Receive("lc_fsquad_ask", function(_, ply) LC.FiringSquadMenu(ply) end)
net.Receive("lc_fsquad_do", function(_, ply)
    local t = net.ReadEntity()
    if (ply.lcFsquadNext or 0) > CurTime() then return end
    ply.lcFsquadNext = CurTime() + 1
    LC.FiringSquadOrder(ply, t, "order")
    net.Start("lc_fsquad") net.WriteString("-") net.WriteUInt(0, 4) net.Send(ply) -- (closes the list)
end)
