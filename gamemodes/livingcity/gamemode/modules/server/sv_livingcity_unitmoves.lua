--[[
    Living City: how the Combine's units move and handle people (the owner, 21 November:
    "build ALL of the ideas" read from Valve's own maps, docs/dev/valve-npc-notes.md, section 5)

      Lanes             a squad sent somewhere (a raid team to a block door, a sweep
                        team walking into rebel ground, a reaction squad sent to a
                        place) goes each man to his own spot, about 130 apart across
                        the way (Valve: lanes about 130 apart), in bounds of 450 to
                        1000 along the city's routes, with a pause of up to 3 seconds
                        at each, and sets off a fifth to half a second after the
                        order (Valve's ai_goal_assault).
      Two at a wall     now and then a unit about to look a citizen over lines up two
                        of them against the nearest wall instead (Valve's spreadwall
                        and spreadwallidle), frisks one, then the other, and lets them
                        go. Only men: the women's models have no such pose.
      The punch         one arrest in three by a unit starts with a punch (Valve's
                        arrestpunch, played by both); the walk to the cells follows.

    Valve's sequences (checked against police_ss.qc, police_animations.qc, male_ss.qc
    and male_shared.qc): a model without one is skipped, never forced.
]]

if CLIENT then return end

LC = LC or {}

local LANE_GAP = 130
local BOUND_MIN, BOUND_MAX = 450, 1000
local PAUSE_MAX = 3

local LOOP, NOCOMPLAIN, MAYDIE = 256, 2048, 4096
local MP = "npc/metropolice/vo/"

local function Has(npc, name) local s = IsValid(npc) and npc.LookupSequence and npc:LookupSequence(name) return s ~= nil and s ~= false and s >= 0 end

------------------------------------------------------------------------
-- Lanes
------------------------------------------------------------------------

-- n spots about LANE_GAP apart, across the way from `from` to `to`, none through a wall.
function LC.LaneSpots(to, from, n, gap)
    gap = gap or LANE_GAP
    local dir = to - (from or to)
    dir.z = 0
    if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
    dir:Normalize()
    local right = Vector(dir.y, -dir.x, 0)
    local out = {}
    for i = 1, n do
        local off = (i - (n + 1) / 2) * gap
        local want = to + right * off
        local tr = util.TraceLine({ start = to + Vector(0, 0, 32), endpos = want + Vector(0, 0, 32), mask = MASK_NPCSOLID_BRUSHONLY })
        if tr and tr.Hit then want = to + right * (off * math.max(0, (tr.Fraction or 0) - 0.15)) end
        out[i] = want
    end
    return out
end

-- The stops on the way from `from` to `to`: points along the city's route every 450 to 1000, then `to`.
function LC.LaneBounds(from, to, role)
    local route = LC.BuildRoute and LC.BuildRoute(from, to, role)
    local pts = {}
    if type(route) == "table" then for _, p in ipairs(route) do pts[#pts + 1] = p end end
    if #pts == 0 or pts[#pts]:DistToSqr(to) > 16 then pts[#pts + 1] = to end
    local out, walked, cur, nextAt = {}, 0, from, math.Rand(BOUND_MIN, BOUND_MAX)
    for i, p in ipairs(pts) do
        local seg = cur:Distance(p)
        local along = 0
        while seg > 0 and walked + (seg - along) >= nextAt do
            local at = along + (nextAt - walked)
            if i == #pts and seg - at < BOUND_MIN * 0.5 then break end -- (not a bound just short of the end)
            along = at
            out[#out + 1] = cur + (p - cur) * (along / seg)
            walked, nextAt = 0, math.Rand(BOUND_MIN, BOUND_MAX)
        end
        walked = walked + (seg - along)
        cur = p
    end
    out[#out + 1] = to
    return out
end

-- Give one unit its lane: spot i of n across the way, from `from` to `to`.
function LC.LaneOne(npc, st, to, from, i, n, opts)
    opts = opts or {}
    local spot = (opts.spot) or LC.LaneSpots(to, from or npc:GetPos(), n or 1)[i or 1] or to
    st.lane = { pts = LC.LaneBounds(npc:GetPos(), spot, st.role), i = 0, run = opts.run, done = opts.done, target = spot, yaw = opts.yaw }
    st.untilT = CurTime() + math.Rand(0.2, 0.5) -- (Valve: the move begins a fifth to half a second after the order)
    return st.lane
end

-- Send units in lanes to `to`. opts: run, from, spots (each man's own end), yaw, done(npc, st, now).
function LC.LaneMove(units, to, opts)
    opts = opts or {}
    local live = {}
    for _, u in ipairs(units) do if IsValid(u) and LC.NPCs[u] then live[#live + 1] = u end end
    if #live == 0 then return 0 end
    local from = opts.from
    if not from then
        from = Vector(0, 0, 0)
        for _, u in ipairs(live) do from = from + u:GetPos() end
        from = from / #live
    end
    local spots = opts.spots or LC.LaneSpots(to, from, #live)
    for i, u in ipairs(live) do
        LC.LaneOne(u, LC.NPCs[u], to, from, i, #live, { spot = spots[i] or to, run = opts.run, done = opts.done, yaw = opts.yaw })
    end
    return #live
end

-- The next bound of a unit's lane, when it is idle. True while the lane goes on.
function LC.LaneStep(npc, st, now)
    local l = st.lane
    if not l then return false end
    if st.state == "moving" then return true end
    l.i = l.i + 1
    local p = l.pts[l.i]
    if not p then
        st.lane = nil
        if l.yaw and LC.FaceYaw then LC.FaceYaw(npc, l.yaw) end
        if l.done then LC.Try(l.done, npc, st, now) end
        return false
    end
    if not LC.GoTo(npc, st, p, l.run, { kind = "lanehop", pos = p, yaw = l.yaw or npc:GetAngles().y, last = l.i == #l.pts }) then
        -- no way on this bound: straight for the end of the lane instead (or done, if that fails too)
        if l.i < #l.pts then l.i = #l.pts - 1 else st.lane = nil if l.done then LC.Try(l.done, npc, st, now) end return false end
        st.untilT = now + 0.3
    end
    return true
end

LC.ArriveHandlers = LC.ArriveHandlers or {}
LC.ArriveHandlers.lanehop = function(npc, st, now, poi)
    st.untilT = now + (poi.last and 0.2 or math.Rand(0, PAUSE_MAX)) -- (Valve: 0 to 3 s at each)
    return true
end

------------------------------------------------------------------------
-- Two citizens frisked against a wall
------------------------------------------------------------------------

local WALL_REACH = 160
local FRISK_APART = 52   -- (Valve: the two stand 52 apart, the unit 39 behind them)
local FRISK_BEHIND = 39
local FRISK_CHANCE = 0.3

local function FriskableCitizen(cit, ist)
    return IsValid(cit) and ist and ist.role == "citizen" and not ist.test and (ist.state == "idle" or ist.state == "moving")
        and Has(cit, "spreadwallidle")
end

-- The nearest wall to pos: its foot and the way out of it, or nil.
function LC.WallNear(pos)
    local eye = pos + Vector(0, 0, 40)
    local best, bn, bf
    for i = 0, 7 do
        local dir = Angle(0, i * 45, 0):Forward()
        local tr = util.TraceLine({ start = eye, endpos = eye + dir * WALL_REACH, mask = MASK_SOLID_BRUSHONLY })
        if tr and tr.Hit and (not bf or tr.Fraction < bf) then
            local n = tr.HitNormal or -dir
            n = Vector(n.x, n.y, 0)
            if n:LengthSqr() < 0.25 then n = -dir end
            n:Normalize()
            best, bn, bf = Vector(tr.HitPos.x, tr.HitPos.y, pos.z), n, tr.Fraction
        end
    end
    return best, bn
end

-- Line up two citizens near the unit against a wall. True if he started it.
function LC.WallFriskTry(cop, cst, now, force)
    if not force and math.random() > FRISK_CHANCE then return false end
    if not Has(cop, "Spreadwall") or not LC.MakeSequence then return false end
    local a, b
    for cit, ist in pairs(LC.NPCs) do
        if FriskableCitizen(cit, ist) and cit:GetPos():DistToSqr(cop:GetPos()) < 500 * 500 then
            if not a then a = cit
            elseif cit:GetPos():DistToSqr(a:GetPos()) < 250 * 250 then b = cit break end
        end
    end
    if not (a and b) then return false end
    local wall, n = LC.WallNear(a:GetPos())
    if not wall then return false end
    local along = Vector(n.y, -n.x, 0)
    local yaw = (-n):Angle().y -- (facing the wall)
    local mid = wall + n * 22
    local spots = { mid - along * (FRISK_APART / 2), mid + along * (FRISK_APART / 2) }
    local f = { cits = { a, b }, spots = spots, yaw = yaw, n = n, t = now, phase = 0, ss = {} }
    for i, cit in ipairs(f.cits) do
        local ist = LC.NPCs[cit]
        LC.SetState(cit, ist, "detained")
        ist.untilT = now + 30
        local ok, ss = LC.Try(LC.MakeSequence, cit, spots[i], yaw, "spreadwallidle", "spreadwallidle", LOOP + NOCOMPLAIN + MAYDIE, 1, 0)
        if ok and IsValid(ss) then
            cit.lcGesture = ss
            f.ss[i] = ss
            SafeRemoveEntityDelayed(ss, 30)
        end
    end
    cop:EmitSound(MP .. "holdit.wav", 75)
    LC.SetState(cop, cst, "wallfrisk")
    cst.frisk, cst.subject = f, a
    return true
end

local function FriskEnd(cop, cst, now)
    local f = cst.frisk
    cst.frisk, cst.subject = nil, nil
    if f then
        for i, cit in ipairs(f.cits) do
            if IsValid(f.ss[i]) then f.ss[i]:Fire("CancelSequence") SafeRemoveEntityDelayed(f.ss[i], 0.2) end
            local ist = IsValid(cit) and LC.NPCs[cit]
            if ist and ist.state == "detained" then LC.SetState(cit, ist, "idle") ist.untilT = now + math.Rand(0.5, 2) end
        end
        if IsValid(f.copSS) then f.copSS:Remove() end
    end
    if IsValid(cop) then
        LC.SetState(cop, cst, "idle")
        cst.untilT = now + math.Rand(2, 5)
    end
end

-- The unit's think while he frisks them: behind the first, behind the second, then he lets them go.
function LC.WallFriskThink(cop, cst, now)
    local f = cst.frisk
    if not f then return FriskEnd(cop, cst, now) end
    for _, cit in ipairs(f.cits) do
        local ist = IsValid(cit) and LC.NPCs[cit]
        if not ist or ist.state ~= "detained" or cit:Health() <= 0 then return FriskEnd(cop, cst, now) end
    end
    local at = now - f.t
    local want = (at >= 13 and 3) or (at >= 7 and 2) or (at >= 1.5 and 1) or 0
    if want == 3 then
        cop:EmitSound(MP .. "allrightyoucango.wav", 75)
        return FriskEnd(cop, cst, now)
    end
    if want > f.phase then
        f.phase = want
        if IsValid(f.copSS) then f.copSS:Fire("CancelSequence") SafeRemoveEntityDelayed(f.copSS, 0.2) end
        local behind = f.spots[want] + f.n * FRISK_BEHIND
        local ok, ss = LC.Try(LC.MakeSequence, cop, behind, f.yaw, "Spreadwall", nil, NOCOMPLAIN + MAYDIE, 1, 0)
        if ok and IsValid(ss) then
            f.copSS = ss
            cop.lcGesture = ss
            SafeRemoveEntityDelayed(ss, 8)
        end
    end
end

LC.SecurityStates = LC.SecurityStates or {}
LC.SecurityStates.wallfrisk = function(npc, st, now) return LC.WallFriskThink(npc, st, now) end

------------------------------------------------------------------------
-- The punch before the arrest
------------------------------------------------------------------------

local PUNCH_CHANCE = 1 / 3
local PUNCH_TIME = 2.8 -- (arrestpunch: the blow lands at frame 51 of about 80, at 30 a second)

-- One arrest in three starts with a punch; arrest(cit, cop) is the arrest itself, after it. True if it took over.
function LC.ArrestPunch(cop, cst, cit, ist, now, arrest, force)
    if not force and math.random() > PUNCH_CHANCE then return false end
    if not (Has(cop, "arrestpunch") and Has(cit, "arrestpunch")) or not LC.MakeSequence then return false end
    if LC.Face then LC.Face(cop, cit:GetPos()) LC.Face(cit, cop:GetPos()) end
    for _, who in ipairs({ cop, cit }) do
        local ok, ss = LC.Try(LC.MakeSequence, who, who:GetPos(), who:GetAngles().y, "arrestpunch", nil, NOCOMPLAIN + MAYDIE, 0, 0)
        if ok and IsValid(ss) then
            who.lcGesture = ss
            SafeRemoveEntityDelayed(ss, PUNCH_TIME + 0.5)
        end
    end
    cst.subject = nil
    LC.SetState(cop, cst, "event")
    cst.eventUntil = now + PUNCH_TIME + 0.3
    LC.SetState(cit, ist, "detained")
    ist.untilT = now + PUNCH_TIME + 10
    timer.Simple(PUNCH_TIME, function()
        if not (IsValid(cop) and IsValid(cit)) or cop:Health() <= 0 or cit:Health() <= 0 then return end
        local cs, is = LC.NPCs[cop], LC.NPCs[cit]
        if not (cs and is) or cs.state ~= "event" or is.state ~= "detained" then return end
        LC.SetState(cop, cs, "idle")
        cs.untilT = CurTime() + 1
        if not (arrest and arrest(cit, cop)) then
            LC.SetState(cit, is, "idle")
            is.untilT = CurTime() + 1
        end
    end)
    hook.Run("LivingCityArrestPunch", cop, cit)
    return true
end
