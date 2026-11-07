--[[
    Living City: arrests in the open (the owner's playtest, 7 November)

    The Arrest Baton's right click (a player, a citizen, or a rebel) no
    longer puts anyone straight in a cell:

      1. They can struggle first. A player always can (unless their hands
         are up, they're down, or they've been beaten down); a citizen NPC
         sometimes does (lc_arrest_struggle_chance), a rebel NPC always.
         For lc_arrest_struggle_time seconds both sides press E as fast as
         they can (a bar on both screens; the mouse is left alone). The one
         resisting needs lc_arrest_struggle_ratio times the officer's presses,
         and two more, to break free. Against an NPC the officer plays alone:
         the NPC's presses come by themselves (a rebel fights harder).
      2. Broken free: they shove the officer back (the same shove a unit
         gives anyone crowding him) and run. A player is wanted for resisting
         arrest; an NPC runs flat out, the whole way, to somewhere well away
         from the officer, and the nearest free unit goes after them.
      3. Held: cuffed where they stand. The officer can walk them to the
         cells himself (F1 > Walk them to the cells, or Drag them along for a
         player), or leave it: the nearest free unit walks over and walks
         them in, the way a unit walks in anyone it arrests
         (sv_livingcity_march.lua). Nobody free to come for lc_arrest_wait
         seconds, or no way to walk there: they're taken in, as before.

    A unit NPC arresting a citizen at an inspection walks them in too.
    Arrests a job or a story makes off screen (a neighbour picked up by
    evening, a prisoner to break out) still put them straight in a cell.

      lc_arrest_struggle (1), lc_arrest_struggle_time (4),
      lc_arrest_struggle_ratio (1.25), lc_arrest_struggle_chance (25),
      lc_arrest_wait (60). lc_march 0 turns the walking off (straight to a cell).
]]

if CLIENT then return end

LC = LC or {}
LC.Struggles = LC.Struggles or {}     -- [target] = { officer, endT, r, o, ... }
LC.NPCCustody = LC.NPCCustody or {}   -- [npc] = { st, officer, leader, walking, dest, startT, ... }
LC.ArrestHolds = LC.ArrestHolds or {} -- [ply] = { officer, seconds, reason, unit, ... }
LC.Fleeing = LC.Fleeing or {}         -- [npc] = { untilT, chaser }

util.AddNetworkString("lc_struggle")
util.AddNetworkString("lc_struggle_press")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn     = CreateConVar("lc_arrest_struggle", "1", FLAGS, "Someone arrested with the Arrest Baton can struggle against the cuffs: both sides press E as fast as they can")
local cvTime   = CreateConVar("lc_arrest_struggle_time", "4", FLAGS, "Seconds a struggle against an arrest lasts")
local cvRatio  = CreateConVar("lc_arrest_struggle_ratio", "1.25", FLAGS, "How many times the officer's presses someone needs to break free of an arrest (higher: harder to get away)")
local cvChance = CreateConVar("lc_arrest_struggle_chance", "25", FLAGS, "Percent chance a citizen NPC struggles when arrested with the baton (sympathizers twice as often; rebels always do)")
local cvWait   = CreateConVar("lc_arrest_wait", "60", FLAGS, "Seconds someone cuffed waits for a unit to walk them in before, with nobody free, they're simply taken to a cell")

local MARGIN = 2          -- presses more than the ratio asks, to break free
local PRESS_GAP = 0.06    -- (no faster than this: a macro gains nothing)
local NPC_RATE = { citizen = 5.5, rebel = 7.5 } -- an NPC's presses a second
local THERE, CLOSE = 170, 600 -- (as sv_livingcity_march.lua)
local CELL_NEAR = 220     -- walked this close to a cell (or into the prison): put in it
local UNIT_RANGE = 3000   -- the furthest a unit is called from
local LET_GO = 700        -- an officer this far from the one he was walking has let go

local function Up(e) return IsValid(e) and e:Health() > 0 end
local function IsUnitSt(st) return st and (st.role == "cop" or st.role == "soldier") end
local function Name(e)
    if not IsValid(e) then return "someone" end
    if e:IsPlayer() then return e:Nick() end
    local st = LC.NPCs and LC.NPCs[e]
    return (st and st.role == "rebel") and "the rebel" or "the citizen"
end
local function Tell(ply, msg) if IsValid(ply) and ply:IsPlayer() then ply:ChatPrint("[Living City] " .. msg) end end
local function Notice(ply, kind, title, text)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    if LC.Notice then LC.Notice(ply, kind, title, text) else ply:ChatPrint("[Living City] " .. text) end
end
local function MarchOn() local c = GetConVar("lc_march") return not c or c:GetBool() end
local function PrisonTime() local c = GetConVar("lc_prison_time") return c and c:GetInt() or 180 end
local function MarchMax() local c = GetConVar("lc_march_max") return c and c:GetFloat() or 240 end

local function InPrison(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("prison") or {}) do
        if LCZ and LCZ.Contains(z, pos, 0) then return true end
    end
    return false
end
-- Walked up to a cell, or into the prison: the cell nearest (one that's free to them), else nil.
local function CellHere(pos, who)
    local best, bd
    for _, c in ipairs(LC.FreePoints and LC.FreePoints({ cell = true }, who) or {}) do
        local d = c.pos:DistToSqr(pos)
        if not bd or d < bd then best, bd = c, d end
    end
    if best and (bd < CELL_NEAR * CELL_NEAR or InPrison(pos)) then return best end
    return nil
end

------------------------------------------------------------------------
-- Units called over
------------------------------------------------------------------------

-- The nearest unit NPC with nothing more important on.
local function FreeUnit(near, skip)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if Up(npc) and IsUnitSt(st) and not st.test and not st.questLock and not st.marching and not st.arrestDuty
            and not st.raid and not st.escortee and not st.subject and not st.workEscort and not st.holdPos
            and st.state ~= "hostile" and st.state ~= "event" and st.state ~= "escorted" and not (skip and skip[npc]) then
            local d = npc:GetPos():DistToSqr(near)
            if d < UNIT_RANGE * UNIT_RANGE and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end
LC.ArrestFreeUnit = FreeUnit

local function Claim(unit, what)
    local st = LC.NPCs[unit]
    st.arrestDuty, st.questLock = what, true
    if st.state == "hostile" and LC.CalmOne then LC.CalmOne(unit, st, CurTime()) end
end

local function Unclaim(unit)
    local st = IsValid(unit) and LC.NPCs and LC.NPCs[unit]
    if not st then return end
    st.arrestDuty, st.questLock, st.marching = nil, nil, nil
    if st.state == "moving" or st.state == "event" then
        st.eventUntil = 0
        LC.SetState(unit, st, "idle")
        st.untilT = CurTime() + 2
    end
end

-- A unit on its way to someone: off again when it's stopped, or they've moved on.
local function Approach(unit, pos, rec, now)
    local st = LC.NPCs[unit]
    if st.state == "hostile" then return true end -- (busy with a fight: he comes when it's over)
    st.untilT = now + 5
    if now < (rec.nextTry or 0) then return true end
    rec.nextTry = now + 1.5
    if st.state == "moving" and st.dest and st.dest:DistToSqr(pos) < 150 * 150 then return true end
    return LC.GoTo(unit, st, pos, true) and true or false
end

------------------------------------------------------------------------
-- Rebels in custody: no gun, no fight
------------------------------------------------------------------------

function LC.DisarmPrisoner(npc, st)
    st.foe = nil
    if st.follow and LC.DismissFollower then LC.DismissFollower(npc, st, true) end
    local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
    if IsValid(w) then
        st.cuffWeapon = st.cuffWeapon or w:GetClass()
        if w.Remove then w:Remove() end
    end
end

local function Rearm(npc, st)
    if st.cuffWeapon and IsValid(npc) and npc.Give then npc:Give(st.cuffWeapon) end
    st.cuffWeapon = nil
end

-- A rebel's turn while they're cuffed or in a cell (sv_livingcity_rebels.lua asks first).
function LC.PrisonerThink(npc, st, now)
    if st.state == "jailed" then
        if now > (st.untilT or 0) and LC.ReleaseNPCPrisoner then
            LC.ReleaseNPCPrisoner(npc, st, now)
            if st.state ~= "jailed" then
                st.leaveAt, st.leaveWhy = nil, nil -- (back to their people, not home)
                Rearm(npc, st)
            end
        end
        return true
    elseif st.state == "detained" then
        if now > (st.untilT or 0) and not LC.NPCCustody[npc] then
            LC.SetState(npc, st, "idle")
            st.untilT = now + 1
            Rearm(npc, st)
        end
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Shoved back, and away they run
------------------------------------------------------------------------

-- `by` shoves `victim` back, as a unit shoves anyone crowding him (sv_livingcity.lua, LC.CopProvoked).
function LC.ShoveOff(by, victim)
    if not IsValid(by) or not IsValid(victim) then return false end
    local away = victim:GetPos() - by:GetPos()
    away.z = 0
    if away:LengthSqr() < 1 then away = by:GetForward() away.z = 0 end
    away = away:GetNormalized()
    if by:IsNPC() and LC.Face then LC.Face(by, victim:GetPos()) end
    if victim:IsPlayer() then
        victim:SetVelocity(away * 380 + Vector(0, 0, 120))
        victim:ViewPunch(Angle(-10, math.Rand(-6, 6), 0))
        victim:SetNW2Float("lc_dazed_until", CurTime() + 1.5)
    else
        if victim.SetLocalVelocity then victim:SetLocalVelocity(away * 300 + Vector(0, 0, 120)) end
        local st = LC.NPCs and LC.NPCs[victim]
        if st then st.stunnedUntil = math.max(st.stunnedUntil or 0, CurTime() + 1.5) end
    end
    by:EmitSound("physics/body/body_medium_impact_soft3.wav", 72)
    return true
end

-- A spot to run to: well away (600 to 1600 units), on the far side from whoever they're running
-- from, and somewhere they can actually get to.
local function FleeSpot(npc, st, fromPos)
    local pos = npc:GetPos()
    local away = pos - fromPos
    away.z = 0
    if away:LengthSqr() < 1 then away = npc:GetForward() away.z = 0 end
    away = away:GetNormalized()
    local best, bs
    for _ = 1, 20 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos(st.role, pos)
        if p then
            local d = p - pos
            d.z = 0
            local len = d:Length()
            if len > 400 and len < 2500 then
                local dot = (d / len):Dot(away)
                local score = math.min(len, 1600) * (dot + 0.6)
                if dot > 0.2 and (not bs or score > bs) then best, bs = p, score end
            end
        end
    end
    if not best then
        -- nowhere known that way: as far straight off as the street goes
        local tr = util.TraceLine({ start = pos + Vector(0, 0, 36), endpos = pos + away * 900 + Vector(0, 0, 36), mask = MASK_NPCSOLID, filter = npc })
        local len = (tr and tr.Fraction or 0) * 900 - 40
        if len > 200 then best = pos + away * len end
    end
    return best, away
end

-- Run, flat out and without a second look: a burst straight away from them, then all the way to
-- a spot well off on the far side. secs: how long they count as running from the law.
-- noChase: no unit sent after them (a job's suspect, for the player to catch).
function LC.NPCFlee(npc, from, secs, noChase)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st or not LC.GoTo then return false end
    if LC.LeaveLine then LC.LeaveLine(npc, st) end
    st.eventUntil = 0
    local fromPos = (IsValid(from) and from:GetPos()) or (from and from.x and from) or npc:GetPos()
    local dest, away = FleeSpot(npc, st, fromPos)
    if not dest or not LC.GoTo(npc, st, dest, true, nil) then return false end
    -- the first steps: straight away from them, not round by the nearest path node
    local pos = npc:GetPos()
    local want = pos + away * 260
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 36), endpos = want + Vector(0, 0, 36), mask = MASK_NPCSOLID, filter = npc })
    local clear = (tr and tr.Fraction or 0) * 260
    if clear > 120 and st.route then
        local burst = pos + away * (clear - 30)
        table.insert(st.route, 1, Vector(burst.x, burst.y, pos.z))
        st.hop = 1
        npc:SetLastPosition(st.route[1])
        npc:SetSchedule(SCHED_FORCED_GO_RUN)
    end
    st.fleeingUntil = CurTime() + (secs or 40)
    npc:SetNW2Bool("lc_fleeing", true)
    LC.Fleeing[npc] = { untilT = CurTime() + (secs or 40), noChase = noChase or (LC.InSomeonesJob and LC.InSomeonesJob(npc, st)) }
    return true
end

-- A rebel's run (rebels don't walk the city's routes the way citizens do; sv_livingcity_rebels.lua
-- asks this first): hop to hop along the route, at a run. True while they're running.
function LC.FleeThink(npc, st, now)
    if not st.fleeingUntil or now > st.fleeingUntil or st.state ~= "moving" or not st.route then
        st.fleeingUntil = nil
        return false
    end
    local target = st.route[st.hop]
    if target and npc:GetPos():DistToSqr(target) < 96 * 96 then
        st.hop = st.hop + 1
        target = st.route[st.hop]
    end
    if not target then
        st.fleeingUntil = nil
        LC.SetState(npc, st, "idle")
        st.untilT = now + 3
        return true
    end
    if LC.RebelHeadFor then LC.RebelHeadFor(npc, st, target, true) end
    return true
end

------------------------------------------------------------------------
-- Cuffed: walked to the cells
------------------------------------------------------------------------

local function EndCustody(npc, c)
    LC.NPCCustody[npc] = nil
    if IsValid(c.leader) and not c.leader:IsPlayer() then Unclaim(c.leader) end
    if IsValid(npc) then npc:SetNW2Bool("lc_cuffed", false) end
end

-- In the cell: the end of the walk (the last few steps through the doors are the game's).
local function Jail(npc, c, how)
    EndCustody(npc, c)
    local st = c.st
    if not IsValid(npc) or LC.NPCs[npc] ~= st then return end
    local cell = st.poi
    if not (cell and cell.kind == "cell") then
        cell = LC.FreeCell and LC.FreeCell(npc)
        if cell and LC.Claim then LC.Claim(npc, st, cell) st.poi = cell end
    end
    if cell then
        npc:SetPos(cell.pos + Vector(0, 0, 4))
        if LC.FaceYaw and cell.yaw then LC.FaceYaw(npc, cell.yaw) end
    end
    LC.OnNPCReachedCell(npc, st, CurTime())
    if how and IsValid(c.officer) and c.officer:IsPlayer() then Tell(c.officer, how) end
end
LC.JailNPCPrisoner = Jail

-- The one leading them takes them by the arm: a player, a unit, or nobody (a unit is called).
function LC.NPCCustodyLead(npc, who)
    local c = LC.NPCCustody[npc]
    if not c then return false end
    if IsValid(c.leader) and c.leader ~= who and not c.leader:IsPlayer() then Unclaim(c.leader) end
    c.leader, c.walking, c.nextTry, c.tries = who, false, nil, 0
    if not IsValid(who) then c.aloneSince = CurTime() end
    if IsValid(who) and not who:IsPlayer() then Claim(who, npc) end
    return true
end

-- An arrest someone made in person: walked to the cells instead of sent there. False: do it the old way.
function LC.WalkNPCToPrison(npc, st, arrester, cell)
    if not MarchOn() or not IsValid(arrester) or not LC.MarchDestination then return false end
    -- the nearest free cell there's a way to (else as near the cells as a unit can get)
    local dest, near = LC.MarchDestination(npc:GetPos(), npc)
    if not dest or dest:DistToSqr(npc:GetPos()) < THERE * THERE then return false end
    if near and near ~= cell and LC.Claim then
        LC.Claim(npc, st, near) -- (that one, not whichever cell came up first)
        st.poi, cell = near, near
    end
    local now = CurTime()
    local c = { st = st, officer = arrester, dest = dest, cell = cell, startT = now, aloneSince = now, tries = 0 }
    if arrester:IsPlayer() then
        LC.NPCCustody[npc] = c
    else
        local ast = LC.NPCs and LC.NPCs[arrester]
        if not IsUnitSt(ast) or not Up(arrester) then return false end
        LC.NPCCustody[npc] = c
        LC.NPCCustodyLead(npc, arrester)
    end
    st.untilT = now + 30
    npc:SetNW2Bool("lc_cuffed", true)
    return true
end

-- They walk along a step behind and to the side of whoever has them.
local function Follow(npc, leader, c, now)
    local fwd = leader:GetVelocity()
    fwd.z = 0
    if fwd:LengthSqr() < 100 then fwd = leader:GetForward() fwd.z = 0 end
    fwd = fwd:GetNormalized()
    local right = Vector(fwd.y, -fwd.x, 0)
    local want = leader:GetPos() - fwd * 50 + right * 22
    local d = npc:GetPos():Distance(want)
    if d > 450 then
        npc:SetPos(want) -- caught on something: brought round behind them
    elseif d > 60 and now >= (c.nextFollow or 0) then
        c.nextFollow = now + 0.4
        npc:SetLastPosition(want)
        npc:SetSchedule(d > 220 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
    end
end

local function CustodyTick(npc, c, now)
    local st = c.st
    if not IsValid(npc) or LC.NPCs[npc] ~= st or st.state ~= "detained" then
        -- freed (a job let them go, someone got them out) or gone
        EndCustody(npc, c)
        if IsValid(npc) and st and st.state ~= "jailed" then Rearm(npc, st) end
        return
    end
    st.untilT = now + 30
    local L = c.leader
    if IsValid(L) and L:IsPlayer() then
        if not L:Alive() or L:GetPos():DistToSqr(npc:GetPos()) > LET_GO * LET_GO then
            c.leader, c.aloneSince = nil, now
            c.declined = L
            Tell(L, "You've left your prisoner behind. A unit will come for them.")
            return
        end
        Follow(npc, L, c, now)
        if CellHere(npc:GetPos(), npc) then Jail(npc, c, "You put them in a cell. The door locks behind them.") end
        return
    end
    if Up(L) and LC.NPCs[L] then
        local ls = LC.NPCs[L]
        if now - c.startT > MarchMax() then return Jail(npc, c) end -- (taking far too long: in a van)
        if not c.walking then
            -- on his way over
            if L:GetPos():DistToSqr(npc:GetPos()) < 110 * 110 then
                if not LC.GoTo(L, ls, c.dest, false) then return Jail(npc, c) end -- (no way to walk there)
                c.walking, c.tries, c.nextTry = true, 0, nil
                ls.marching, ls.questLock = true, true
                L:EmitSound("npc/metropolice/vo/movingtocode3.wav", 75)
            elseif not Approach(L, npc:GetPos(), c, now) then
                c.skip = c.skip or {}
                c.skip[L] = true
                LC.NPCCustodyLead(npc, nil)
            end
            return
        end
        if ls.state == "hostile" then return end -- (fighting: the prisoner waits, cuffed, till he's done)
        local d2 = L:GetPos():DistToSqr(c.dest)
        if d2 < THERE * THERE or (ls.state ~= "moving" and d2 < CLOSE * CLOSE) then return Jail(npc, c) end
        if ls.state ~= "moving" and now >= (c.nextTry or 0) then
            -- stopped short: off again, a few times, then the old way
            c.tries = c.tries + 1
            c.nextTry = now + 2
            if c.tries > 8 or not LC.GoTo(L, ls, c.dest, false) then return Jail(npc, c) end
            ls.marching = true
        end
        ls.untilT = now + 5
        Follow(npc, L, c, now)
        return
    end
    -- nobody has them: the nearest free unit comes; with none, the officer is left holding them
    c.leader = nil
    local unit = FreeUnit(npc:GetPos(), c.skip)
    local o = c.officer
    if unit then
        LC.NPCCustodyLead(npc, unit)
        Approach(unit, npc:GetPos(), c, now)
        if IsValid(o) and o:IsPlayer() and not c.toldUnit then
            c.toldUnit = true
            Tell(o, "A unit is on his way to walk your prisoner to the cells.")
        end
    elseif IsValid(o) and o:IsPlayer() and o:Alive() and c.declined ~= o and o:GetPos():DistToSqr(npc:GetPos()) < LET_GO * LET_GO then
        LC.NPCCustodyLead(npc, o)
        Notice(o, "info", "Your prisoner", "No unit is free to take them: they follow you. Walk them to the cells. (F1 > Walk them to the cells / let go, to leave them for a unit.)")
    elseif now - (c.aloneSince or now) > cvWait:GetFloat() then
        Jail(npc, c)
    end
end

-- F1 > Walk them to the cells / let go (the same as Drag them along, on a cuffed NPC).
-- nil when it isn't about a cuffed NPC.
function LC.NPCCustodyDrag(ply)
    for npc, c in pairs(LC.NPCCustody) do
        if c.leader == ply then
            LC.NPCCustodyLead(npc, nil)
            c.declined = ply
            Tell(ply, "You let go of them. A unit will come to walk them in.")
            return true
        end
    end
    local tr = ply:GetEyeTrace()
    local e = tr and tr.Entity
    if not (IsValid(e) and LC.NPCCustody[e]) then return nil end
    if not (LC.PlayerIsCP(ply) or ply:IsAdmin()) then return nil end
    if e:GetPos():DistToSqr(ply:GetPos()) > 160 * 160 then return false, "Get closer." end
    LC.NPCCustodyLead(e, ply)
    LC.NPCCustody[e].declined = nil
    Tell(ply, "You take them by the arm. Walk them to the cells: at the cell, they're locked in. (F1 > Walk them to the cells / let go again, to leave them for a unit.)")
    return true
end

------------------------------------------------------------------------
-- A player cuffed by a player
------------------------------------------------------------------------

local function EndHold(ply, h)
    LC.ArrestHolds[ply] = nil
    if IsValid(h.unit) then Unclaim(h.unit) end
    h.unit = nil
end

local function TakeInPlayer(ply, h, how)
    EndHold(ply, h)
    local ok = LC.Incarcerate(ply, h.seconds, h.reason, h.officer)
    if ok and how then ply:ChatPrint("[Civil Protection] " .. how) end
    return ok
end

local function CuffPlayer(target, officer)
    local secs, reason = PrisonTime(), "Arrested by " .. officer:Nick()
    if not MarchOn() or not LC.TiePlayer then return LC.Incarcerate(target, secs, reason, officer) end
    if not LC.IsTied(target) then LC.TiePlayer(target, officer) end
    local now = CurTime()
    LC.ArrestHolds[target] = { officer = officer, seconds = secs, reason = reason, startT = now, aloneSince = now }
    Notice(target, "warn", "Under arrest", "You're cuffed. You'll be walked to the cells.")
    return true
end

local function HoldTick(ply, h, now)
    if not IsValid(ply) or not ply:Alive() or not LC.IsTied(ply) or (LC.Prisoners and LC.Prisoners[ply]) or (LC.Marching and LC.Marching[ply]) then
        return EndHold(ply, h)
    end
    local t = LC.Tied[ply]
    local dragger = t and t.escort
    if IsValid(dragger) then
        -- someone's walking them: no unit needed
        if IsValid(h.unit) then Unclaim(h.unit) h.unit = nil end
        h.aloneSince = now
        local cell = (LC.PlayerIsCP(dragger) or dragger:IsAdmin()) and CellHere(ply:GetPos(), ply)
        if cell then
            ply.lcPreferCell = cell
            TakeInPlayer(ply, h, "They walk you into the cell, and the door locks behind you.")
            ply.lcPreferCell = nil
            Tell(dragger, "You put " .. ply:Nick() .. " in a cell.")
        end
        return
    end
    if Up(h.unit) and LC.NPCs[h.unit] then
        if h.unit:GetPos():DistToSqr(ply:GetPos()) < 120 * 120 then
            local unit = h.unit
            EndHold(ply, h)
            if LC.MarchToPrison and LC.MarchToPrison(ply, unit, h.seconds, h.reason) then
                if LC.Marching[ply] then LC.Marching[ply].arrester = h.officer end -- (the arrest is still the officer's)
            else
                LC.Incarcerate(ply, h.seconds, h.reason, h.officer)
            end
        elseif not Approach(h.unit, ply:GetPos(), h, now) then
            h.skip = h.skip or {}
            h.skip[h.unit] = true
            Unclaim(h.unit)
            h.unit = nil
        end
        return
    end
    h.unit = nil
    local unit = FreeUnit(ply:GetPos(), h.skip)
    if unit then
        h.unit = unit
        Claim(unit, ply)
        h.nextTry = nil
        Approach(unit, ply:GetPos(), h, now)
    elseif now - h.aloneSince > cvWait:GetFloat() then
        TakeInPlayer(ply, h, "With no unit free to walk you in, a transport takes you to the cells.")
    end
end

------------------------------------------------------------------------
-- The struggle
------------------------------------------------------------------------

local function Send(s, done)
    for _, p in ipairs({ s.target, s.officer }) do
        if IsValid(p) and p:IsPlayer() then
            local resist = p == s.target
            net.Start("lc_struggle")
            net.WriteBool(not done)
            if not done then
                net.WriteString(resist and "resist" or "restrain")
                net.WriteString(Name(resist and s.officer or s.target))
                net.WriteFloat(s.endT)
                net.WriteUInt(math.min(1023, math.floor(resist and s.r or s.o)), 10)
                net.WriteUInt(math.min(1023, math.floor(resist and s.o or s.r)), 10)
                net.WriteFloat(s.ratio)
                net.WriteUInt(MARGIN, 4)
            end
            net.Send(p)
        end
    end
end

function LC.StruggleOf(ply)
    if LC.Struggles[ply] then return LC.Struggles[ply], "resist" end
    for _, s in pairs(LC.Struggles) do if s.officer == ply then return s, "restrain" end end
    return nil
end

-- A press of E in a struggle (lc_struggle_press from the client).
function LC.StrugglePress(ply)
    local s, role = LC.StruggleOf(ply)
    if not s or CurTime() > s.endT then return false end
    local now = CurTime()
    if role == "resist" then
        if now - (s.lastR or 0) < PRESS_GAP then return false end
        s.lastR, s.r = now, s.r + 1
    else
        if now - (s.lastO or 0) < PRESS_GAP then return false end
        s.lastO, s.o = now, s.o + 1
    end
    return true
end
net.Receive("lc_struggle_press", function(_, ply) if IsValid(ply) then LC.StrugglePress(ply) end end)

function LC.StruggleWouldWin(s) return s.r >= s.o * s.ratio + MARGIN end

local function Resolve(target, s, why)
    LC.Struggles[target] = nil
    Send(s, true)
    local officer = s.officer
    if IsValid(target) and target:IsPlayer() then target:SetNW2Float("lc_struggle_until", 0) end
    if not IsValid(target) or (target:IsPlayer() and not target:Alive()) or (not target:IsPlayer() and not LC.NPCs[target]) then return end
    local free = why == "gone" or LC.StruggleWouldWin(s)
    hook.Run("LivingCityArrestStruggled", target, officer, not free)
    if not free then
        -- held: cuffed
        if target:IsPlayer() then
            if CuffPlayer(target, officer) then
                Tell(officer, target:Nick() .. " is cuffed. Drag them to the cells yourself (F1 > Drag them along), or leave them: a unit is called to walk them in.")
                target:ChatPrint("[Living City] They hold you down and get the cuffs on.")
            end
        else
            local ok, err = LC.ArrestNPC(target, officer)
            if ok then
                Tell(officer, "Cuffed. A unit is called to walk them to the cells, or walk them in yourself (F1 > Walk them to the cells).")
            else
                Tell(officer, "Couldn't arrest: " .. tostring(err))
            end
        end
        return
    end
    -- free: a shove, and away
    if why ~= "gone" then LC.ShoveOff(target, officer) end
    if target:IsPlayer() then
        target.lcBrokeFree = CurTime() + 2.5
        Notice(target, "warn", "You broke free", "You shove the officer back. Run!")
        if LC.ReportCrime then LC.ReportCrime(target, "Resisting arrest", 120) end
        Tell(officer, target:Nick() .. " shoves you back and breaks free!")
    else
        local st = LC.NPCs[target]
        if st then
            st.eventUntil = 0
            if st.state == "event" then LC.SetState(target, st, "idle") end
        end
        target.lcBrokeFree = CurTime() + 2.5
        if not LC.NPCFlee(target, officer, 40) and st then st.untilT = 0 end
        Tell(officer, (st and st.role == "rebel" and "The rebel" or "They") .. " shove you back and run! Chase them down.")
    end
end

-- Does this one get a chance to struggle?
local function WillStruggle(target)
    if not cvOn:GetBool() then return false end
    if target:IsPlayer() then
        if LC.IsTied and LC.IsTied(target) then return false end
        if LC.IsDowned and LC.IsDowned(target) then return false end
        if target:GetNW2Bool("lc_handsup", false) then return false end -- (hands up: going quietly)
        if target:Health() < 20 then return false end
        local hits = GetConVar("lc_subdue_hits")
        if LC.SubdueHits and LC.SubdueHits(target) >= math.max(1, hits and hits:GetInt() or 3) then return false end -- beaten down
        return true
    end
    local st = LC.NPCs[target]
    if not st then return false end
    if st.role == "rebel" then return true end
    local chance = cvChance:GetFloat() * (st.rebel and 2 or 1)
    return math.random() * 100 < chance
end
LC.ArrestWillStruggle = WillStruggle

function LC.BeginArrestStruggle(officer, target)
    local now = CurTime()
    if LC.Fleeing[target] then LC.Fleeing[target].untilT = 0 end -- (caught: the chase is over)
    local s = { target = target, officer = officer, endT = now + math.max(1, cvTime:GetFloat()), r = 0, o = 0,
        ratio = math.max(1, cvRatio:GetFloat()), npc = not target:IsPlayer() }
    if s.npc then
        local st = LC.NPCs[target]
        s.rate = NPC_RATE[st.role] or NPC_RATE.citizen
        if LC.LeaveLine then LC.LeaveLine(target, st) end
        LC.SetState(target, st, "event")
        st.eventUntil = s.endT + 2
        target:SetSchedule(SCHED_IDLE_STAND)
        if LC.Face then LC.Face(target, officer:GetPos()) end
        if LC.Sounds and LC.Sounds.Vo then target:EmitSound(LC.Sounds.Vo(st.gender or "male", "no02"), 72) end
    else
        target:SetNW2Float("lc_struggle_until", s.endT) -- (held where they stand: sh_livingcity_custody.lua)
        Notice(target, "warn", "Resist arrest?", "Press E as fast as you can to break free and run. Do nothing and you're cuffed.")
    end
    target:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 70)
    Notice(officer, "info", "They're struggling", "Press E as fast as you can to hold " .. Name(target) .. " down.")
    LC.Struggles[target] = s
    Send(s)
    return s
end

local function StruggleTick(now)
    for target, s in pairs(LC.Struggles) do
        local o = s.officer
        if not IsValid(target) or not IsValid(o) or not o:Alive() or (target:IsPlayer() and not target:Alive()) then
            Resolve(target, s, "gone")
        elseif o:GetPos():DistToSqr(target:GetPos()) > 220 * 220 then
            Resolve(target, s, "gone") -- (the officer let go of them)
        else
            if s.npc then
                local dt = now - (s.lastSim or now)
                s.lastSim = now
                s.r = s.r + s.rate * dt * math.Rand(0.7, 1.3)
            end
            if now >= s.endT then
                Resolve(target, s)
            elseif now >= (s.nextSend or 0) then
                s.nextSend = now + 0.2
                Send(s)
            end
        end
    end
end

------------------------------------------------------------------------
-- The Arrest Baton's right click
------------------------------------------------------------------------

-- ok, and what to tell the officer.
function LC.BatonArrest(officer, ent)
    if not IsValid(officer) or not IsValid(ent) then return false end
    if LC.StruggleOf(officer) then return false, "You've got your hands full." end
    if LC.Struggles[ent] then return false end
    if (ent.lcBrokeFree or 0) > CurTime() then return false, Name(ent) .. " just broke free of you. Catch them first." end
    if ent:IsPlayer() then
        if LC.PlayerIsCP(ent) and not officer:IsAdmin() then return false, "You can't arrest another Civil Protection unit." end
        if (LC.Prisoners and LC.Prisoners[ent]) or (LC.Marching and LC.Marching[ent]) or LC.ArrestHolds[ent] then
            return false, ent:Nick() .. " is already in custody."
        end
        if not (LC.FreeCell and LC.FreeCell(ent)) then return false, "Couldn't arrest: no free cell (place more with the editor)" end
        if WillStruggle(ent) then
            LC.BeginArrestStruggle(officer, ent)
            return true, ent:Nick() .. " struggles! Press E as fast as you can to hold them."
        end
        local done, err = CuffPlayer(ent, officer)
        if not done then return false, "Couldn't arrest: " .. tostring(err) end
        return true, ent:Nick() .. " is cuffed. Drag them to the cells yourself (F1 > Drag them along), or leave them: a unit is called to walk them in."
    end
    local st = LC.NPCs and LC.NPCs[ent]
    if not st then return false end
    if st.role ~= "citizen" and st.role ~= "rebel" then return false, "Couldn't arrest: only citizens and rebels can be arrested" end
    if LC.NPCCustody[ent] or st.state == "jailed" then return false, "They're already in custody." end
    if not (LC.FreeCell and LC.FreeCell(ent)) then return false, "Couldn't arrest: no free cell" end
    if WillStruggle(ent) then
        LC.BeginArrestStruggle(officer, ent)
        return true, (st.role == "rebel" and "The rebel fights" or "They struggle") .. "! Press E as fast as you can to hold them."
    end
    local done, err = LC.ArrestNPC(ent, officer)
    if not done then return false, "Couldn't arrest: " .. tostring(err) end
    return true, "Cuffed. A unit is called to walk them to the cells, or walk them in yourself (F1 > Walk them to the cells)."
end

------------------------------------------------------------------------
-- The fleeing: a unit goes after them
------------------------------------------------------------------------

local function FleeTick(npc, f, now)
    local st = IsValid(npc) and LC.NPCs[npc]
    if not st or now > f.untilT or st.state == "detained" or st.state == "jailed" then
        LC.Fleeing[npc] = nil
        if IsValid(f.chaser) then Unclaim(f.chaser) end
        if st then st.fleeingUntil = nil end
        if IsValid(npc) then npc:SetNW2Bool("lc_fleeing", false) end
        return
    end
    if f.noChase or LC.Struggles[npc] then return end
    if not Up(f.chaser) then
        f.chaser = nil
        if now < (f.nextLook or 0) then return end
        f.nextLook = now + 2
        local u = FreeUnit(npc:GetPos())
        if u and u:GetPos():DistToSqr(npc:GetPos()) < 1500 * 1500 then
            f.chaser = u
            Claim(u, npc)
            u:EmitSound("npc/metropolice/vo/holdit.wav", 78)
        end
        return
    end
    if f.chaser:GetPos():DistToSqr(npc:GetPos()) < 90 * 90 then
        local u = f.chaser
        LC.Fleeing[npc] = nil
        Unclaim(u)
        st.fleeingUntil = nil
        npc:SetNW2Bool("lc_fleeing", false)
        LC.ArrestNPC(npc, u)
        return
    end
    Approach(f.chaser, npc:GetPos(), f, now)
end

timer.Create("LivingCityArrest", 0.2, 0, function()
    if not (next(LC.Struggles) or next(LC.NPCCustody) or next(LC.ArrestHolds) or next(LC.Fleeing)) then return end
    local ok, err = pcall(function()
        local now = CurTime()
        StruggleTick(now)
        for npc, c in pairs(LC.NPCCustody) do CustodyTick(npc, c, now) end
        for ply, h in pairs(LC.ArrestHolds) do HoldTick(ply, h, now) end
        for npc, f in pairs(LC.Fleeing) do FleeTick(npc, f, now) end
    end)
    if not ok and LC.Error then LC.Error("arrest", err) end
end)

-- Leaving, dying, or removed mid-arrest.
hook.Add("PlayerDisconnected", "LivingCityArrest", function(ply)
    local h = LC.ArrestHolds[ply]
    if h then pcall(TakeInPlayer, ply, h) end -- (left with the cuffs on: on the books, as if they'd got there)
    local s = LC.Struggles[ply]
    if s then LC.Struggles[ply] = nil end
end)
hook.Add("PlayerDeath", "LivingCityArrest", function(ply)
    local h = LC.ArrestHolds[ply]
    if h then EndHold(ply, h) end
end)
hook.Add("EntityRemoved", "LivingCityArrest", function(ent)
    local c = LC.NPCCustody[ent]
    if c then EndCustody(ent, c) end
end)
