--[[
    Living City: a Combine APC on patrol (the owner, 20 November: "An APC on patrol: at most 1 at a
    time", on the roads; and of how it knows them, 25 November: "can you just make the roads on the
    canal ring have some sort of path for the APC that runs along the center of the road?").

      The route   the map's marks named lc_apc_route_NNN in name order (the canal ring's street has
                  them along the middle of its roadway: _dev/tools/map_corridor.py), or, on a map
                  without them, the Miscount Editor's "APC route" points in the order of their #.
                  A closed loop when the last is within 1500 of the first, else there and back.
      The patrol  every lc_apc_minutes (20) while the city runs, one APC comes out where nobody is
                  looking, drives one or two laps and leaves the same way. Never two at once. It
                  never leaves its route. A player in its way: it stops, sounds its horn and waits.
      Rebels      a Resistance player or fighter in open rebel garb, the Resistance's Commander
                  whatever he wears, and anyone who shoots at it: its gun fires bursts at them (no
                  missiles) and it follows along the road to the route mark nearest them.
      Papers      a citizen (or a rebel passing as one) within 600: it drives as near as the road
                  allows, an Overwatch soldier steps out, walks up and demands the travel permit.
                  With one they are waved on (it is not taken). Without: taken in as any unit takes
                  someone in (LC.NPCTakesIn). Who runs or fights is shot. One check a player every
                  ten minutes. The soldier gets back in and it drives on.
      The crew    600 health: bullets do a tenth, explosives double (whoever set them off), an
                  IED beside it kills the crew outright. Crew dead, it stands smoking for ten minutes and is then cleared
                  away; meanwhile a Resistance player can salvage it once (E on it, 8 seconds).

    Staff: F4 > Factions > Admin: testing tools > "APC: send one now" and "APC: remove it".
    Settings: lc_apc (1; 0: none), lc_apc_minutes (20).
    Hooks: LivingCityApcOut(ent), LivingCityApcCrewDead(ent, by), LivingCityApcSalvaged(ply, ent).
    A driveable APC for players is a later wish: nothing of it here.
    docs/features/apc-patrol.md
]]

LC = LC or {}
LC.Apc = LC.Apc or {}
local A = LC.Apc

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_apc", "1", FLAGS, "A Combine APC patrols the roads now and then, where the map or the editor marks a route for it (0: none)", 0, 1)
local cvMinutes = CreateConVar("lc_apc_minutes", "20", FLAGS, "Minutes between one APC patrol and the next", 1, 600)

local MODEL = "models/combine_apc.mdl"
local YAW = -90                 -- the model's nose against the way it drives (as the Administrator's APC: sv_livingcity_adminsecurity.lua)
local MARK = "lc_apc_route_"    -- the map's marks (map_corridor.APC_NAME), 8 over the road
local LOOP_NEAR = 1500          -- the last mark this near the first: a closed loop
local SPEED, CHASE = 220, 300   -- units a second: on patrol, and after someone
local TURN = 120                -- degrees a second
local SEE = 1500                -- how far its gunner sees
local PAPERS_NEAR, PAPERS_EVERY = 600, 600
local RAN = 450                 -- told to stand still, this far from where they stood: they ran
local HEALTH, DEAD_SECS, SALVAGE_SECS = 600, 600, 8
local BURST, PAUSE, DAMAGE = 6, 1.4, 8
local AHEAD, ASIDE = 280, 100   -- someone this far in front of its middle and this near its line is in its way
local PATROL_MAX, LEAVE_MAX = 900, 240
local ENGINE = "vehicles/apc/apc_cruise_loop3.wav"
local HORN = "ambient/alarms/apc_alarm_pass1.wav"
local GUN = "weapons/ar2/fire1.wav"
local DEMAND = { "npc/metropolice/vo/citizen.wav", "npc/metropolice/vo/apply.wav" }
local GO = "npc/metropolice/vo/allrightyoucango.wav"
local BLAST, BULLET = DMG_BLAST or 64, DMG_BULLET or 2
A.SALVAGE = { scrap = 6, ammo_smg = 2 }

function A.CityRuns() return LC.Running == true end -- (no patrol in a stopped city)

local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 40))) or p end
local function Yaw(d) return math.deg(math.atan2(d.y, d.x)) end
local function Flat(a, b) local dx, dy = a.x - b.x, a.y - b.y return dx * dx + dy * dy end

------------------------------------------------------------------------
-- The route
------------------------------------------------------------------------

-- The road's marks in order, and whether they close into a loop: the map's own, else the editor's.
function A.Route()
    local marks = {}
    for _, e in ipairs(ents.FindByName and ents.FindByName(MARK .. "*") or {}) do
        if IsValid(e) then marks[#marks + 1] = { key = string.lower(tostring(e:GetName())), pos = e:GetPos() } end
    end
    if #marks < 2 then
        marks = {}
        for i, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("apcroute") or {}) do
            marks[#marks + 1] = { key = string.format("%09d %09d", p.group or 0, i), pos = p.pos }
        end
    end
    if #marks < 2 then return nil end
    table.sort(marks, function(a, b) return a.key < b.key end)
    local pts = {}
    for i, m in ipairs(marks) do pts[i] = Ground(m.pos) end
    return pts, #pts >= 3 and pts[#pts]:DistToSqr(pts[1]) <= LOOP_NEAR * LOOP_NEAR
end

-- The mark after k going dir: nil at either end of a route that is not a loop.
local function Next(S, k, dir)
    local n = #S.route
    k = k + dir
    if S.loop then return (k - 1) % n + 1 end
    if k < 1 or k > n then return nil end
    return k
end

-- How many marks from k to g going dir (nil: g is not that way).
local function Steps(S, k, g, dir)
    local n = #S.route
    if S.loop then return ((g - k) * dir) % n end
    local d = (g - k) * dir
    return d >= 0 and d or nil
end

function A.NearestMark(S, pos)
    local best, bd
    for i, p in ipairs(S.route) do
        local d = p:DistToSqr(pos)
        if not bd or d < bd then best, bd = i, d end
    end
    return best
end

------------------------------------------------------------------------
-- Who is who to its crew
------------------------------------------------------------------------

-- Left alone whatever they are: dead, in custody, down, an admin at work.
local function Out(ply)
    if not IsValid(ply) or not ply:Alive() then return true end
    if (LC.Prisoners and LC.Prisoners[ply]) or (LC.Detained and LC.Detained[ply]) or (LC.Marching and LC.Marching[ply]) then return true end
    if (LC.IsDowned and LC.IsDowned(ply)) or (LC.IsTied and LC.IsTied(ply)) or ply.lcDreaming then return true end
    if (LC.EditorHeld and LC.EditorHeld(ply)) or (LC.IsBuilder and LC.IsBuilder(ply)) then return true end
    return ply.GetMoveType ~= nil and ply:GetMoveType() == MOVETYPE_NOCLIP
end

-- The Resistance's Commander (the rank: LC.SquadLeader's own rule).
function A.Commander(ply)
    return ply:GetNW2String("lcf_faction", "") == "resistance" and ply:GetNW2Int("lcf_rank", 1) >= 5
end

-- Fired on at sight: a rebel in open rebel garb, the Commander, whoever attacked it or ran from its soldier.
function A.Hostile(ent)
    if not IsValid(ent) then return false end
    local S = A.S
    if S and (S.marks[ent] or 0) > CurTime() then return true end
    if ent:IsPlayer() then
        if ent:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
        if LC.DisguisedAsCP and LC.DisguisedAsCP(ent) then return false end -- (a unit, to them)
        if A.Commander(ent) then return true end
        if LC.PassesAsCitizen and LC.PassesAsCitizen(ent) then return false end -- (citizen clothes: papers, not bullets)
        return ((LC.DisguisedAsRebel and LC.DisguisedAsRebel(ent)) or (LC.PlayerIsHunted and LC.PlayerIsHunted(ent))) and true or false
    end
    local st = LC.NPCs and LC.NPCs[ent]
    return st ~= nil and st.role == "rebel" and not st.casual
end

-- Asked for papers: citizens, and rebels its gunner takes for citizens.
function A.PapersDue(ply, now)
    local f = ply:GetNW2String("lcf_faction", "")
    if f ~= "citizen" and f ~= "resistance" then return false end
    if LC.DisguisedAsCP and LC.DisguisedAsCP(ply) then return false end
    return now >= (ply.lcApcPapersAt or -1e9) + PAPERS_EVERY and not A.Hostile(ply)
end

local function Mark(S, who, secs)
    if not IsValid(who) or who == S.ent then return end
    if who:IsPlayer() and (LC.PlayerIsCP and LC.PlayerIsCP(who)) then return end
    if who:IsNPC() and LC.NPCs and LC.NPCs[who] and LC.IsSecurity and LC.IsSecurity(LC.NPCs[who]) then return end
    if not who:IsPlayer() and not who:IsNPC() then return end
    S.marks[who] = CurTime() + (secs or 90)
end

local function Turret(S) return S.pos + Vector(0, 0, 118) end
local function Aim(ent) return (ent.WorldSpaceCenter and ent:WorldSpaceCenter()) or (ent:GetPos() + Vector(0, 0, 40)) end
local function Sees(S, ent)
    local P = S.papers
    if not LC.LineOfSight then return true end
    return LC.LineOfSight(Turret(S), Aim(ent), { S.ent, P and P.soldier or nil }, ent)
end

------------------------------------------------------------------------
-- Out and away
------------------------------------------------------------------------

local function Engine(S, on)
    if on then
        if not S.snd and CreateSound and IsValid(S.ent) then
            S.snd = CreateSound(S.ent, ENGINE)
            if S.snd then
                if S.snd.SetSoundLevel then S.snd:SetSoundLevel(85) end
                S.snd:PlayEx(0.9, 100)
            end
        end
    elseif S.snd then
        S.snd:Stop()
        S.snd = nil
    end
end

-- Can a player see where it is?
local function Seen(pos, ent)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local d = ply:GetPos():DistToSqr(pos)
            if d < 700 * 700 then return true end
            if d < 4000 * 4000 and (not LC.LineOfSight or LC.LineOfSight(ply:EyePos(), pos + Vector(0, 0, 70), { ply }, ent)) then return true end
        end
    end
    return false
end

-- Where it comes out: a mark nobody can see, else the one farthest from everyone. A route that is not a loop: one of its ends.
local function StartMark(route, loop)
    local n = #route
    local unseen, far, fd = {}, 1, -1
    for i = 1, n, (loop and 1 or math.max(1, n - 1)) do
        local near = math.huge
        for _, ply in ipairs(player.GetAll()) do near = math.min(near, ply:GetPos():DistToSqr(route[i])) end
        if near > fd then far, fd = i, near end
        if not Seen(route[i]) then unseen[#unseen + 1] = i end
    end
    if #unseen > 0 then return unseen[math.random(#unseen)] end
    return far
end

-- One sets out. by: the admin who sent it (it comes out about 1500 from them, heading their way).
-- at, dir: where on the route and which way (tests). Gives false and why when it cannot.
function A.Send(by, at, dir)
    if A.S then return false, "An APC is out already." end
    if not cvOn:GetBool() then return false, "APC patrols are off (lc_apc is 0)." end
    if not A.CityRuns() then return false, "Start the city first." end
    local route, loop = A.Route()
    if not route then return false, "No APC route on this map: place APC route points in the Miscount Editor, in order along the middle of the road." end
    if util.IsValidModel and not util.IsValidModel(MODEL) then return false, "The APC's model is missing." end
    local n = #route
    if not at and IsValid(by) then
        local bd
        for i = 1, n, (loop and 1 or math.max(1, n - 1)) do
            local d = math.abs(math.sqrt(route[i]:DistToSqr(by:GetPos())) - 1500)
            if not bd or d < bd then at, bd = i, d end
        end
    end
    at = math.Clamp(at or StartMark(route, loop), 1, n)
    local S = { route = route, loop = loop, at = at, home = at, dir = dir or 1, pos = Vector(route[at].x, route[at].y, route[at].z),
        marks = {}, hp = HEALTH, laps = 0, want = math.random(1, 2), t0 = CurTime(), last = CurTime(), burst = BURST }
    if not dir and IsValid(by) then -- (toward whoever sent it)
        local a, b = Next(S, at, 1), Next(S, at, -1)
        if a and b and route[b]:DistToSqr(by:GetPos()) < route[a]:DistToSqr(by:GetPos()) then S.dir = -1 end
    end
    S.to = Next(S, at, S.dir)
    if not S.to then S.dir = -S.dir S.to = Next(S, at, S.dir) end
    if not S.to then return false, "The APC's route has only one mark." end
    S.yaw = Yaw(route[S.to] - S.pos)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return false, "The APC could not be made." end
    e:SetModel(MODEL)
    e:SetPos(S.pos)
    e:SetAngles(Angle(0, S.yaw + YAW, 0))
    e:SetKeyValue("solid", "6")
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_VPHYSICS or 6) end
    if e.SetSaveValue then e:SetSaveValue("m_takedamage", 1) end -- (it hears of every hit and is never broken by one: its health is kept here)
    e:SetName("lc_apc_patrol")
    e.lcApc = true
    S.ent = e
    A.S = S
    Engine(S, true)
    hook.Run("LivingCityApcOut", e)
    if LC.Log then LC.Log("info", string.format("APC patrol out: %d marks, %s", n, loop and "a loop" or "there and back")) end
    return true, S
end

local function Release(st) -- (a soldier of its crew handed back to the city)
    if not st then return end
    st.apcCrew, st.apcPapers, st.unmanaged = nil, nil, nil
    if st.state == "event" then st.eventUntil = 0 end
end

-- It is taken off the map (and the next is a full wait away).
function A.Remove()
    local S = A.S
    A.S = nil
    A.nextAt = CurTime() + cvMinutes:GetFloat() * 60
    if not S then return false end
    Engine(S, false)
    local P = S.papers
    if P and IsValid(P.soldier) then P.soldier:Remove() end
    if IsValid(S.smoke) then S.smoke:Remove() end
    if IsValid(S.ent) then S.ent:Remove() end
    return true
end

------------------------------------------------------------------------
-- Driving: from mark to mark, never off them
------------------------------------------------------------------------

local function Arrive(S)
    S.at = S.to
    if S.goal == S.at then S.arrived = true return false end
    if S.at == S.home and not S.goal then
        S.laps = S.laps + 1
        if S.laps >= S.want then S.leaving = S.leaving or CurTime() end
    end
    local nx = Next(S, S.at, S.dir)
    if not nx then
        S.dir = -S.dir
        nx = Next(S, S.at, S.dir)
    end
    if not nx then return false end
    S.to = nx
    return true
end

-- Toward its goal mark by the shorter way round (turning back if that is it).
local function Steer(S)
    local g = S.goal
    if not g then return end
    if S.at == g and Flat(S.pos, S.route[g]) < 16 then S.arrived = true return end
    S.arrived = nil
    local fwd = Steps(S, S.to, g, S.dir)
    local back = Steps(S, S.at, g, -S.dir)
    if back and (not fwd or back < fwd) then
        S.at, S.to, S.dir = S.to, S.at, -S.dir
    end
end

-- Is pos in its way: in front of it along the road, near its line.
local function Ahead(S, pos)
    local d = S.route[S.to] - S.pos
    local o = pos - S.pos
    local len = math.sqrt(d.x * d.x + d.y * d.y)
    if len < 1 or math.abs(o.z) > 130 then return false end
    local along, side = (o.x * d.x + o.y * d.y) / len, math.abs(o.y * d.x - o.x * d.y) / len
    return along > 0 and along < AHEAD and side < ASIDE
end

-- A player standing in its way (looked for every time it moves: it never drives over one, and waits however long).
local function PlayerAhead(S)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not (ply.GetMoveType and ply:GetMoveType() == MOVETYPE_NOCLIP) and Ahead(S, ply:GetPos()) then return ply end
    end
    return nil
end

-- One of the city's people in its way: it waits a few seconds, then drives on.
local function NPCAhead(S, now)
    if now < (S.npcPassAt or 0) then return nil end
    local P = S.papers
    for npc in pairs(LC.NPCs or {}) do
        if IsValid(npc) and not (P and P.soldier == npc) and Ahead(S, npc:GetPos()) then
            S.npcSince = S.npcSince or now
            if now - S.npcSince > 6 then S.npcSince, S.npcPassAt = nil, now + 10 return nil end
            return npc
        end
    end
    S.npcSince = nil
    return nil
end

function A.Move()
    local S = A.S
    if not S or S.dead or not IsValid(S.ent) then return end
    local now = CurTime()
    local dt = math.min(now - S.last, 0.25)
    S.last = now
    if dt <= 0 then return end
    Steer(S)
    if S.to == S.at and not (S.goal and S.arrived) then -- (standing on a mark, as after a stop at one: the next along its way)
        local nx = Next(S, S.at, S.dir)
        if not nx then
            S.dir = -S.dir
            nx = Next(S, S.at, S.dir)
        end
        if nx then S.to = nx end
    end
    S.inWay = PlayerAhead(S)
    local stopped = S.hold or S.inWay or S.blocked or (S.goal and S.arrived)
    local tgt = S.route[S.to]
    local d = tgt - S.pos
    if not stopped and d:LengthSqr() > 1 then
        -- nose round first: it turns on the spot when it has to go back
        local want = Yaw(d)
        local off = math.AngleDifference(want, S.yaw)
        local turn = math.Clamp(off, -TURN * dt, TURN * dt)
        S.yaw = S.yaw + turn
        if math.abs(off) > 50 then stopped = true end
    end
    if not stopped then
        local left = (S.goal and S.target and CHASE or SPEED) * dt
        for _ = 1, 8 do
            tgt = S.route[S.to]
            d = tgt - S.pos
            local len = d:Length()
            if len > left then
                S.pos = S.pos + d * (left / len)
                break
            end
            S.pos = Vector(tgt.x, tgt.y, tgt.z)
            left = left - len
            if not Arrive(S) then break end
        end
    end
    S.ent:SetPos(S.pos)
    S.ent:SetAngles(Angle(0, S.yaw + YAW, 0))
    if S.snd and S.snd.ChangePitch and S.idle ~= (stopped and true or false) then
        S.idle = stopped and true or false
        S.snd:ChangePitch(stopped and 78 or 100, 0.6)
    end
end

------------------------------------------------------------------------
-- Its gun
------------------------------------------------------------------------

local function Target(S)
    local best, bd
    local function try(ent)
        local d = ent:GetPos():DistToSqr(S.pos)
        if d < SEE * SEE and (not bd or d < bd) and A.Hostile(ent) and Sees(S, ent) then best, bd = ent, d end
    end
    local P = S.papers
    local held = P and P.phase == "held" and P.ply or nil -- (in its own soldier's hands: never fired on)
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= held and not Out(ply) then try(ply) end
    end
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and npc:Health() > 0 and (st.role == "rebel" or S.marks[npc]) then try(npc) end
    end
    return best
end

function A.Fire()
    local S = A.S
    if not S or S.dead then return end
    local t, now = S.target, CurTime()
    if not IsValid(t) or now < (S.nextShot or 0) then return end
    if t:IsPlayer() and not t:Alive() then return end
    local src = Turret(S)
    local dir = Aim(t) - src
    if dir:LengthSqr() < 1 then return end
    dir:Normalize()
    S.burst = S.burst - 1
    if S.burst <= 0 then S.burst, S.nextShot = BURST, now + PAUSE else S.nextShot = now + 0.1 end
    S.shots = (S.shots or 0) + 1
    local e = S.ent
    if e.FireBullets then
        e:FireBullets({ Attacker = e, Inflictor = e, Num = 1, Src = src, Dir = dir, Spread = Vector(0.025, 0.025, 0), Tracer = 1,
            TracerName = "AR2Tracer", Force = 4, Damage = DAMAGE, IgnoreEntity = e })
    end
    e:EmitSound(GUN, 95, 100)
end

------------------------------------------------------------------------
-- Papers
------------------------------------------------------------------------

local function Order(sol, st, pos, now)
    if LC.SetState and st.state ~= "event" then LC.SetState(sol, st, "event") end
    st.eventUntil = now + 60
    sol:SetLastPosition(pos)
    sol:SetSchedule(SCHED_FORCED_GO)
end

local function Beside(S, toward)
    local rad = math.rad(S.yaw + 90)
    local side = Vector(math.cos(rad), math.sin(rad), 0)
    if toward and (toward - S.pos):Dot(side) < 0 then side = side * -1 end
    return Ground(S.pos + side * 125) + Vector(0, 0, 4)
end

local function PapersEnd(S, keep)
    local P = S.papers
    S.papers, S.hold = nil, nil
    if not P then return end
    local sol = P.soldier
    if IsValid(sol) then
        if keep then Release(LC.NPCs and LC.NPCs[sol]) else sol:Remove() end
    end
end

local function PapersBack(S, P, now)
    P.phase, P.t = "back", now
    local sol = P.soldier
    local st = IsValid(sol) and LC.NPCs and LC.NPCs[sol]
    if not st then return PapersEnd(S) end
    if st.state == "hostile" and LC.Release then LC.Release(sol, st) end
    Order(sol, st, Beside(S, sol:GetPos()), now)
end

local function PapersFight(S, P, ply, now)
    Mark(S, ply, 60)
    P.phase, P.t = "fight", now
    local sol = P.soldier
    local st = IsValid(sol) and LC.NPCs and LC.NPCs[sol]
    if st and LC.MakeOneHostile then
        st.eventUntil = 0
        ply.lcViolentUntil = math.max(ply.lcViolentUntil or 0, now + 60) -- (he shoots: they were told to stand still)
        LC.Try(LC.MakeOneHostile, sol, st, ply)
    end
end

-- The soldier is with them: the permit, or the cuffs.
local function PapersCheck(S, P, ply, now)
    local sol = P.soldier
    if LC.HasItem and LC.HasItem(ply, "permit") then
        sol:EmitSound(GO, 75)
        hook.Run("LivingCityApcPapers", ply, true)
        return PapersBack(S, P, now)
    end
    hook.Run("LivingCityApcPapers", ply, false)
    if LC.SetWanted then LC.SetWanted(ply, 120, "No travel permit") end
    local took = false
    if LC.NPCTakesIn then
        local ok, res = LC.Try(LC.NPCTakesIn, sol, ply)
        took = ok and res == true
    end
    if took then
        P.phase, P.t = "held", now
    elseif LC.ArmedAndFighting and LC.ArmedAndFighting(ply) then
        PapersFight(S, P, ply, now)
    else
        PapersBack(S, P, now)
    end
end

local function Papers(S, now)
    local P = S.papers
    if not P then
        if S.target or S.leaving then return end
        local best, bd
        for _, ply in ipairs(player.GetAll()) do
            if not Out(ply) and A.PapersDue(ply, now) then
                local d = ply:GetPos():DistToSqr(S.pos)
                if d < PAPERS_NEAR * PAPERS_NEAR and (not bd or d < bd) and Sees(S, ply) then best, bd = ply, d end
            end
        end
        if best then S.papers = { ply = best, phase = "approach", t = now, goal = A.NearestMark(S, best:GetPos()) } end
        return
    end
    local ply, sol = P.ply, P.soldier
    if P.phase == "approach" then
        if S.target or Out(ply) or A.Hostile(ply) or ply:GetPos():DistToSqr(S.pos) > (PAPERS_NEAR * 2) ^ 2 then return PapersEnd(S) end
        if not (S.arrived and S.goal == P.goal) and now - P.t < 15 then return end
        -- as near as the road allows: the soldier steps out
        S.hold = true
        ply.lcApcPapersAt = now
        local npc, st
        if LC.SpawnSoldier then npc, st = LC.SpawnSoldier(Beside(S, ply:GetPos()), "ar2") end
        if not IsValid(npc) or not st then return PapersEnd(S) end
        st.unmanaged, st.apcCrew = true, true
        st.apcPapers = ply -- (he walks up to them: they are not crowding him, LC.CopProvoked)
        st.leaveAt, st.routeGroup, st.zone = nil, nil, nil
        P.soldier, P.phase, P.t, P.spot, P.orderAt = npc, "walk", now, ply:GetPos(), 0
        npc:EmitSound(DEMAND[math.random(#DEMAND)], 85)
        if LC.Notice then LC.Notice(ply, "warn", "Papers", "Show your travel permit: stand still.") end
        return
    end
    if not IsValid(sol) or sol:Health() <= 0 then -- (their soldier is dead: whoever was being checked answers for it)
        if IsValid(ply) and not Out(ply) then Mark(S, ply, 90) end
        return PapersEnd(S, true)
    end
    local st = LC.NPCs and LC.NPCs[sol]
    if not st then return PapersEnd(S) end
    if P.phase == "walk" then
        if Out(ply) then return PapersBack(S, P, now) end
        if A.Hostile(ply) or (LC.ArmedAndFighting and LC.ArmedAndFighting(ply)) or ply:GetPos():DistToSqr(P.spot) > RAN * RAN then
            return PapersFight(S, P, ply, now)
        end
        if Flat(sol:GetPos(), ply:GetPos()) < 110 * 110 then return PapersCheck(S, P, ply, now) end
        if now - P.t > 30 then return PapersBack(S, P, now) end
        if now >= P.orderAt then
            P.orderAt = now + 1
            Order(sol, st, ply:GetPos(), now)
        end
    elseif P.phase == "held" then
        -- what came of it: walked off to the cells by him (he is the city's from here), cuffed, or still struggling
        if LC.Marching and LC.Marching[ply] then return PapersEnd(S, true) end
        if not IsValid(ply) or (LC.Prisoners and LC.Prisoners[ply]) or (LC.Detained and LC.Detained[ply]) then return PapersBack(S, P, now) end
        if LC.Struggles and LC.Struggles[ply] and now - P.t < 40 then return end
        if now - P.t < 2 then return end
        if (ply.lcBrokeFree or 0) > now and not Out(ply) then return PapersFight(S, P, ply, now) end
        return PapersBack(S, P, now)
    elseif P.phase == "fight" then
        if Out(ply) or now - P.t > 40 or ply:GetPos():DistToSqr(S.pos) > 2500 * 2500 then return PapersBack(S, P, now) end
    elseif P.phase == "back" then
        if now - P.t > 15 or Flat(sol:GetPos(), S.pos) < 190 * 190 then return PapersEnd(S) end
    end
end

------------------------------------------------------------------------
-- The crew dead
------------------------------------------------------------------------

function A.CrewDead(by)
    local S = A.S
    if not S or S.dead then return end
    local now = CurTime()
    S.dead, S.clearAt = now, now + DEAD_SECS
    S.target, S.goal, S.hold = nil, nil, nil
    Engine(S, false)
    PapersEnd(S, true) -- (a soldier out on the road is on his own now)
    local e = S.ent
    if IsValid(e) then
        e:EmitSound("vehicles/apc/apc_shutdown.wav", 85)
        e:SetNW2Bool("lc_apc_dead", true)
        if e.SetColor then e:SetColor(Color(110, 105, 100)) end
        local smoke = ents.Create("env_smokestack")
        if IsValid(smoke) then
            smoke:SetPos(S.pos + Vector(0, 0, 100))
            for k, v in pairs({ InitialState = "1", BaseSpread = "18", SpreadSpeed = "14", Speed = "45", StartSize = "26", EndSize = "90", Rate = "10",
                JetLength = "220", twist = "6", SmokeMaterial = "particle/SmokeStack.vmt", rendercolor = "45 45 45", renderamt = "190" }) do
                smoke:SetKeyValue(k, v)
            end
            smoke:Spawn()
            smoke:Activate()
            if smoke.SetParent then smoke:SetParent(e) end
            S.smoke = smoke
        end
    end
    hook.Run("LivingCityApcCrewDead", e, by)
    if LC.Log then LC.Log("info", "APC patrol: the crew is dead" .. (IsValid(by) and by:IsPlayer() and (" (" .. by:Nick() .. ")") or "")) end
end

function A.Damage(n, by)
    local S = A.S
    if not S or S.dead then return end
    Mark(S, by)
    S.hp = S.hp - math.max(0, n)
    if S.hp <= 0 then A.CrewDead(by) end
end

hook.Add("EntityTakeDamage", "LivingCityApc", function(ent, dmg)
    local S = A.S
    if not S or not IsValid(ent) then return end
    if ent == S.ent then
        local n, by = dmg:GetDamage(), dmg:GetAttacker()
        if dmg:IsDamageType(BLAST) then n = n * 2
        elseif not (IsValid(by) and (by:IsPlayer() or by:IsNPC())) then n = 0 -- (a door, a train, a falling crate: nobody's attack)
        elseif dmg:IsDamageType(BULLET) then n = n * 0.1
        else n = n * 0.25 end
        LC.Try(A.Damage, n, by)
        return true -- (never the engine's own breaking of a prop)
    end
    if S.papers and ent == S.papers.soldier then Mark(S, dmg:GetAttacker()) end
end)

-- An IED on the road (sv_livingcity_ied.lua): beside it, the crew is dead; near it, half its health.
hook.Add("LivingCityIED", "LivingCityApc", function(pos, by)
    local S = A.S
    if not S or S.dead or not pos then return end
    local d = pos:DistToSqr(S.pos)
    if d < 260 * 260 then LC.Try(A.Damage, HEALTH, by)
    elseif d < 520 * 520 then LC.Try(A.Damage, HEALTH / 2, by) end
end)

-- Salvage: a Resistance player, E on the dead APC, once.
function A.Salvage(ply)
    local S = A.S
    if not (S and S.dead and not S.salvaged and IsValid(S.ent)) then return false end
    if not IsValid(ply) or not ply:Alive() or ply:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
    if Flat(ply:GetPos(), S.pos) > 230 * 230 or (LC.Busy and LC.Busy(ply)) or not LC.StartTask then return false end
    local tr = ply.GetEyeTrace and ply:GetEyeTrace()
    if tr and IsValid(tr.Entity) and tr.Entity ~= S.ent then return false end
    local e = S.ent
    return LC.StartTask(ply, SALVAGE_SECS, "Salvaging the APC...", { maxMove = 60, done = function(p)
        local T = A.S
        if not (T and T.ent == e and T.dead and not T.salvaged and IsValid(p)) then return end
        T.salvaged = true
        T.clearAt = math.min(T.clearAt, CurTime() + 60)
        for id, n in pairs(A.SALVAGE) do
            if LC.GiveOrDrop then LC.GiveOrDrop(p, id, n) elseif LC.GiveItem then LC.GiveItem(p, id, n) end
        end
        if IsValid(e) then e:EmitSound("items/ammo_pickup.wav", 70) end
        hook.Run("LivingCityApcSalvaged", p, e)
    end })
end

hook.Add("KeyPress", "LivingCityApc", function(ply, key)
    if key ~= IN_USE then return end
    local S = A.S
    if S and S.dead and not S.salvaged then LC.Try(A.Salvage, ply) end
end)

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

-- What it does next (three times a second).
function A.Decide()
    local S = A.S
    if not S then return end
    local now = CurTime()
    if not IsValid(S.ent) then return A.Remove() end
    if S.dead then
        if now >= S.clearAt then A.Remove() end
        return
    end
    if not cvOn:GetBool() or not A.CityRuns() then return A.Remove() end
    for who, untilT in pairs(S.marks) do
        if not IsValid(who) or untilT <= now or (who:IsPlayer() and not who:Alive()) then S.marks[who] = nil end
    end
    S.target = Target(S)
    Papers(S, now)
    local P = S.papers
    if S.target then
        S.goal = A.NearestMark(S, S.target:GetPos())
    elseif P and P.phase == "approach" then
        S.goal = P.goal
    else
        S.goal, S.arrived = nil, nil
    end
    S.hold = (P and P.phase ~= "approach") and true or nil
    local was = S.blocked
    S.blocked = NPCAhead(S, now)
    if (S.inWay or (S.blocked and was)) and not S.hold and now >= (S.hornAt or 0) then
        S.hornAt = now + 5
        S.ent:EmitSound(HORN, 90)
    end
    -- its laps done (or out too long): gone as soon as nobody is looking
    if not S.leaving and now - S.t0 > PATROL_MAX then S.leaving = now end
    if S.leaving and not S.target and not P and (now - S.leaving > LEAVE_MAX or not Seen(S.pos, S.ent)) then return A.Remove() end
end

function A.Tick()
    local now = CurTime()
    if A.S then
        A.Move()
        A.Fire()
        A.n = (A.n or 0) + 1
        if A.n % 3 == 0 then A.Decide() end
        return
    end
    if now < (A.lookAt or 0) then return end
    A.lookAt = now + 5
    if not cvOn:GetBool() or not A.CityRuns() then A.nextAt = nil return end
    if not A.nextAt then A.nextAt = now + cvMinutes:GetFloat() * 60 * (0.3 + 0.7 * math.random()) end
    if now < A.nextAt then return end
    local ok = A.Send()
    if not ok then A.lookAt = now + 30 end -- (no route here: look again in a while)
end

timer.Create("LivingCityApc", 0.1, 0, function() LC.Try(A.Tick) end)
-- (between the timer's steps: moved every tick, so it glides)
hook.Add("Think", "LivingCityApc", function()
    if A.S and not A.S.dead then
        LC.Try(A.Move)
        LC.Try(A.Fire)
    end
end)
