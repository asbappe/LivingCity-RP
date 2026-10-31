--[[
    Living City: marched to the cells

    Arrested by a Civil Protection or Overwatch NPC (beaten down with the
    stunstick, or giving yourself up to one), you aren't put straight in a
    cell any more. Your hands are tied and two units walk you there: the one
    who arrested you leads, holding you by the arm, and the nearest other
    unit comes along behind. They walk the city's paths to a free cell,
    unlocking the Civil Protection and prison doors on the way (the
    perimeter's, the cell block's) and locking them behind them. Where the
    paths don't reach a cell, they walk you as close as they can get and take
    you through the doors from there.

    On the way, anyone can try to get you out. Kill or drive off the unit
    leading you and his grip is gone: your hands are still tied (F1 > Work at
    the ties, or someone cuts them), and you're wanted for escaping custody.
    While the units are busy fighting, they let go of you; stray far enough
    and you've slipped away.

    If there's no way to walk there (no route at all, or it takes longer
    than lc_march_max seconds), it's the old way: straight to a cell.

      lc_march 0/1, lc_march_max (240)
]]

if CLIENT then return end

LC = LC or {}
LC.Marching = LC.Marching or {} -- [ply] = { lead, rear, seconds, reason, arrester, dest, startT, tries }

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn  = CreateConVar("lc_march", "1", FLAGS, "Civil Protection units arresting someone walk them to the prison instead of putting them straight in a cell")
local cvMax = CreateConVar("lc_march_max", "240", FLAGS, "Seconds a march to the prison may take before they're simply taken in")

local SLIP = 450   -- this far from the unit leading you, while he's busy fighting: you've slipped away
local THERE = 170  -- this close to the spot by the cells: taken inside
local CLOSE = 600  -- stopped this close to it (held up at the doors): taken inside too

local function IsUnit(st) return st and (st.role == "cop" or st.role == "soldier") end
local KNOCKED_OUT = "You're struck from behind, and everything goes black. When you come to, you're in a cell."
local function Up(npc) return IsValid(npc) and npc:Health() > 0 end

function LC.IsMarching(ply) return LC.Marching[ply] ~= nil end
-- Someone being walked in (or a unit walking them) near pos: a door there stays open for them.
function LC.MarchNear(pos, r)
    for ply, m in pairs(LC.Marching) do
        if IsValid(ply) and ply:GetPos():DistToSqr(pos) < r * r then return true end
        if Up(m.lead) and m.lead:GetPos():DistToSqr(pos) < r * r then return true end
        if Up(m.rear) and m.rear:GetPos():DistToSqr(pos) < r * r then return true end
    end
    return false
end

-- Where they walk you. Units open Civil Protection and prison doors as they
-- walk up to them, and lock them again behind them (sv_livingcity_doors.lua),
-- so first: right to a free cell, through the perimeter and the cell block.
-- If there's no route there: as close to the cells as a unit can walk (the
-- nearest spot on the paths outside the prison zone), and through the doors
-- from there. Failing that, the prison's release point.
-- Returns the spot, and the cell when they're walking right to one.
local function InPrison(pos)
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("prison") or {}) do
        if LCZ.Contains(z, pos, 0) then return true end
    end
    return false
end

local function Destination(from, who)
    local cells = LC.FreePoints and LC.FreePoints({ cell = true }, who) or {}
    table.sort(cells, function(a, b) return a.pos:DistToSqr(from) < b.pos:DistToSqr(from) end)
    if LC.BuildRoute then
        for i = 1, math.min(3, #cells) do
            if LC.BuildRoute(from, cells[i].pos, "cop") ~= false then return cells[i].pos, cells[i] end
        end
    end
    local cell = cells[1] and cells[1].pos
    if not cell then
        for _, c in ipairs(LC.PointsOfKind and LC.PointsOfKind("cell") or {}) do cell = cell or c.pos end
    end
    if cell and LC.NodePositions and LC.BuildRoute then
        local list = {}
        for _, p in ipairs(LC.NodePositions("cop") or {}) do
            if not InPrison(p) then list[#list + 1] = { p = p, d = p:DistToSqr(cell) } end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        for i = 1, math.min(25, #list) do
            if LC.BuildRoute(from, list[i].p, "cop") ~= false then return list[i].p end
        end
    end
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("release") or {}) do
        local d = p.pos:DistToSqr(from)
        if not bd or d < bd then best, bd = p.pos, d end
    end
    return best
end
LC.MarchDestination = Destination

-- The nearest other unit free to come along.
local function SecondUnit(near, lead)
    local best, bd
    for npc, st in pairs(LC.NPCs or {}) do
        if npc ~= lead and Up(npc) and IsUnit(st) and not st.test and not st.questLock and not st.marching
            and st.state ~= "hostile" and st.state ~= "event" and st.state ~= "escorted" then
            local d = npc:GetPos():DistToSqr(near)
            if d < 1500 * 1500 and (not bd or d < bd) then best, bd = npc, d end
        end
    end
    return best
end

local function Release(npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    st.marching, st.questLock = nil, nil
    if st.state == "event" or st.state == "moving" then
        st.eventUntil = 0
        LC.SetState(npc, st, "idle")
        st.untilT = CurTime() + 2
    end
end

local function Finish(ply, m)
    LC.Marching[ply] = nil
    Release(m.lead)
    Release(m.rear)
    if IsValid(ply) then ply:SetNW2Bool("lc_marching", false) end
end

-- Taken inside: untied (their things are recorded and kept as on any
-- arrest) and locked up.
local function TakeIn(ply, m, how)
    Finish(ply, m)
    if not IsValid(ply) then return end
    if LC.Untie then LC.Untie(ply, nil, true) end
    ply.lcPreferCell = m.cell -- (the cell they were walked to, if it's still free)
    local ok = LC.Incarcerate(ply, m.seconds, m.reason, m.arrester)
    ply.lcPreferCell = nil
    if ok and how then ply:ChatPrint("[Civil Protection] " .. how) end
    if ok and how == KNOCKED_OUT and ply.ScreenFade then ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 3, 2) end
    if not ok and LC.DetainOnTheSpot then LC.DetainOnTheSpot(ply, m.arrester, m.reason) end
end

-- Got away: still tied, and wanted for it.
local function Escaped(ply, m, how)
    Finish(ply, m)
    if not IsValid(ply) or not ply:Alive() then return end
    if LC.Notice then LC.Notice(ply, "warn", "Free, for now", how .. " Your hands are still cuffed: F1 > Work at the cuffs, or have someone uncuff them.") end
    ply:ChatPrint("[Custody] " .. how)
    local esc = GetConVar("lc_escape_wanted")
    if LC.ReportCrime then LC.ReportCrime(ply, "Escaping custody", esc and esc:GetFloat() or 300) end
    if LC.Log then LC.Log("info", "Escaped a march to the prison: " .. ply:Nick()) end
    hook.Run("LivingCityMarchBroken", ply, m)
end

-- Arrested by a unit NPC: walk them to the prison. True if the march has
-- begun; false (do it the old way) when it can't.
function LC.MarchToPrison(ply, arrester, seconds, reason)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LC.Marching[ply] or (LC.Prisoners and LC.Prisoners[ply]) then return false end
    local st = IsValid(arrester) and LC.NPCs and LC.NPCs[arrester]
    if not IsUnit(st) or st.test or not Up(arrester) then return false end
    if not (LC.PrisonAvailable and LC.PrisonAvailable()) or not LC.TiePlayer or not LC.GoTo then return false end
    local dest, cell = Destination(ply:GetPos(), ply)
    if not dest or dest:DistToSqr(ply:GetPos()) < THERE * THERE then return false end

    -- the one who arrested him leads
    if st.state == "hostile" and LC.CalmOne then LC.CalmOne(arrester, st, CurTime()) end
    if not LC.GoTo(arrester, st, dest, false) then return false end -- no way to walk there
    st.marching, st.questLock = true, true

    if LC.ClearWanted then LC.ClearWanted(ply) end
    if LC.CalmCops then LC.CalmCops(ply) end
    if ply:InVehicle() then ply:ExitVehicle() end
    if LC.IsTied and LC.IsTied(ply) then LC.Untie(ply, nil, true) end -- (their things are recorded when they're locked up)
    LC.TiePlayer(ply, nil)

    local rear = SecondUnit(ply:GetPos(), arrester)
    if IsValid(rear) then
        local rs = LC.NPCs[rear]
        LC.SetState(rear, rs, "event")
        rs.eventUntil = CurTime() + cvMax:GetFloat() + 30
        rs.marching, rs.questLock = true, true
    end

    local m = { lead = arrester, rear = rear, seconds = seconds, reason = reason, arrester = arrester, dest = dest,
        cell = cell, startT = CurTime(), tries = 0 }
    LC.Marching[ply] = m
    ply:SetNW2Bool("lc_marching", true)
    arrester:EmitSound("npc/metropolice/vo/movingtocode3.wav", 75)

    local where = LC.DescribePlace and LC.DescribePlace(ply:GetPos()) or ""
    ply:ChatPrint("[Custody] Cuffed. " .. (IsValid(rear) and "Two Civil Protection units march" or "A Civil Protection unit marches") .. " you to the cells. Charge: " .. tostring(reason or "none given") .. ".")
    if LC.Notice then
        LC.Notice(ply, "warn", "Under arrest", "You're being walked to the prison. Someone could still get you out on the way.")
    end
    if LC.RadioNotice then
        LC.RadioNotice("resistance", "Civil Protection are marching a prisoner to the cells" .. (where ~= "" and (", " .. where) or "") .. ". Hit them on the way and they're ours.")
        LC.RadioNotice("cp", "Prisoner in transit" .. (where ~= "" and (", " .. where) or "") .. ". Escort to holding.")
    end
    if LC.Log then LC.Log("info", string.format("Marching %s to the prison (%s)", ply:Nick(), tostring(reason))) end
    hook.Run("LivingCityMarchStarted", ply, m)
    return true
end

-- Where the prisoner should be: at the side of the unit leading him, a step behind.
local function Heading(npc)
    local v = npc:GetVelocity()
    v.z = 0
    if v:LengthSqr() > 100 then return v:GetNormalized() end
    local f = npc:GetForward()
    f.z = 0
    return f:GetNormalized()
end

local function Pull(ply, lead)
    local fwd = Heading(lead)
    local right = Vector(fwd.y, -fwd.x, 0)
    local want = lead:GetPos() - fwd * 40 + right * 26
    local d = want - ply:GetPos()
    d.z = 0
    local dist = d:Length()
    if dist > 220 then
        -- caught on something: brought round behind him
        local tr = util.TraceLine({ start = lead:GetPos() + Vector(0, 0, 36), endpos = want + Vector(0, 0, 36),
            mask = MASK_PLAYERSOLID or MASK_SOLID, filter = { lead, ply } })
        local spot = tr.Hit and (tr.HitPos - (want - lead:GetPos()):GetNormalized() * 20) or (want + Vector(0, 0, 36))
        ply:SetPos(Vector(spot.x, spot.y, lead:GetPos().z + 2))
    elseif dist > 30 then
        local v = ply:GetVelocity()
        ply:SetVelocity(d:GetNormalized() * math.min(dist * 5, 240) - Vector(v.x, v.y, 0))
    end
end

-- The unit leading you goes down: the one behind takes your arm, or another unit nearby
-- comes over and does. Only with nobody left to take you are you free. True when someone has you.
function LC.MarchTakeOver(ply, m)
    local new = Up(m.rear) and m.rear or SecondUnit(ply:GetPos(), m.lead)
    if not new then return false end
    if new == m.rear then m.rear = nil end
    local st = LC.NPCs[new]
    if st.state == "hostile" and LC.CalmOne then LC.CalmOne(new, st, CurTime()) end
    if not LC.GoTo(new, st, m.dest, false) then return false end
    st.marching, st.questLock = true, true
    m.lead, m.tries, m.nextTry = new, 0, nil
    new:EmitSound("npc/metropolice/vo/holdit.wav", 75)
    if IsValid(ply) then ply:ChatPrint("[Custody] The unit leading you is down. Another takes your arm before you can run.") end
    return true
end

-- A unit walking a prisoner alone: another nearby falls in behind.
local function Reinforce(ply, m, now)
    if Up(m.rear) or (m.nextReinforce or 0) > now then return end
    m.nextReinforce = now + 3
    local rear = SecondUnit(ply:GetPos(), m.lead)
    if not rear then return end
    local rs = LC.NPCs[rear]
    LC.SetState(rear, rs, "event")
    rs.eventUntil = now + cvMax:GetFloat() + 30
    rs.marching, rs.questLock = true, true
    m.rear = rear
end

local function Tick(now)
    for ply, m in pairs(LC.Marching) do
        local lead = m.lead
        local ls = IsValid(lead) and LC.NPCs and LC.NPCs[lead]
        if (not Up(lead) or not ls) and IsValid(ply) and ply:Alive() and LC.MarchTakeOver(ply, m) then
            lead = m.lead
            ls = LC.NPCs[lead]
        end
        if not IsValid(ply) or not ply:Alive() then
            Finish(ply, m)
        elseif not Up(lead) or not ls then
            Escaped(ply, m, "The Civil Protection unit leading you is down.")
        elseif now - m.startT > cvMax:GetFloat() then
            TakeIn(ply, m, KNOCKED_OUT)
        elseif ls.state == "hostile" then
            -- he's fighting: he lets go of you
            if ply:GetPos():DistToSqr(lead:GetPos()) > SLIP * SLIP then
                Escaped(ply, m, "While they were busy, you slipped away.")
            end
        else
            local d2 = lead:GetPos():DistToSqr(m.dest)
            if d2 < THERE * THERE or (ls.state ~= "moving" and d2 < CLOSE * CLOSE) then
                -- there, or as close as he can get (stopped at the doors): through them, and down to the cells
                TakeIn(ply, m, m.cell and d2 < THERE * THERE and "They put you in the cell, and the door locks behind you."
                    or "They unlock the prison door, walk you through, and lock you in a cell.")
            else
                local going = true
                if ls.state ~= "moving" and now >= (m.nextTry or 0) then
                    -- stopped (arrived somewhere else, or gave up): set off again, a few times, a couple
                    -- of seconds apart (it used to be five tries a tenth of a second apart: half a
                    -- second's pause and the van came, without a step walked)
                    m.tries = m.tries + 1
                    m.nextTry = now + 2
                    if m.tries > 8 or not LC.GoTo(lead, ls, m.dest, false) then
                        TakeIn(ply, m, KNOCKED_OUT)
                        going = false
                    end
                end
                if going then
                    Pull(ply, lead)
                    Reinforce(ply, m, now)
                    -- the second unit keeps close behind
                    if Up(m.rear) and (m.nextRear or 0) < now then
                        m.nextRear = now + 0.8
                        local behind = ply:GetPos() - Heading(lead) * 70
                        if m.rear:GetPos():DistToSqr(behind) > 80 * 80 then
                            m.rear:SetLastPosition(behind)
                            m.rear:SetSchedule(m.rear:GetPos():DistToSqr(behind) > 400 * 400 and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO)
                        end
                    end
                end
            end
        end
    end
end

timer.Create("LivingCityMarch", 0.1, 0, function()
    if not next(LC.Marching) then return end
    local ok, err = pcall(Tick, CurTime())
    if not ok and LC.Error then LC.Error("march", err) end
end)

-- Units don't keep beating someone they're walking in.
hook.Add("EntityTakeDamage", "LivingCityMarch", function(victim, dmg)
    if not (IsValid(victim) and victim:IsPlayer() and LC.Marching[victim]) then return end
    local st = LC.NPCs and LC.NPCs[dmg:GetAttacker()]
    if IsUnit(st) then dmg:SetDamage(0) return true end
end)

-- Their struggle with the ties is noticed while they're being held.
hook.Add("LivingCityCanStruggle", "LivingCityMarch", function(ply)
    if LC.Marching[ply] then return false end
end)

-- Leaving mid-march: they're on the books, as if they'd got there.
hook.Add("PlayerDisconnected", "LivingCityMarch", function(ply)
    local m = LC.Marching[ply]
    if m then pcall(TakeIn, ply, m) end
end)

hook.Add("PlayerDeath", "LivingCityMarch", function(ply)
    local m = LC.Marching[ply]
    if m then Finish(ply, m) end
end)
