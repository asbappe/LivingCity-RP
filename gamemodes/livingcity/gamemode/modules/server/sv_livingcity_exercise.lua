--[[
    Living City: morning exercise (mandatory for citizens)

      Every lc_exercise_every mornings (2: every second one), at dawn, the city
      holds one of these, in turn (lc_exercise_kinds "jog,drill,parade"; a kind
      the map has no points for is skipped):

      jog     The morning jog. A route plotted with the editor ("Point: jogging
              route stop", in order, the first is the start; route # for more
              than one). Citizens gather at the start, then run it. Units post
              themselves along the route at intervals. Anyone not jogging (too
              slow) or falling too far behind the pace (a marker that moves
              along the route at lc_jog_pace) gets the stick: and a few
              seconds of extra speed to catch back up (lc_jog_boost).

      drill   The morning drill. At the exercise yard ("Point: exercise yard":
              place it where the leader stands, from where the citizens will
              be). Everyone gets a place in rows in front of the leader and
              copies the leader's moves: crouch, jump, spin, step left, right,
              forward or back. The leader is a player Clinic Medic or Records
              Clerk if one is there (their own moves are called out), or else a
              Union fitness instructor calls them. Halfway through: skipping, a
              rope turned to a beat (jump on every beat). Too many mistakes
              (lc_drill_mistakes), wandering out of your place, and a unit at
              the edge of the yard steps in with the stick.

      parade  The morning parade. A column of Overwatch soldiers and Civil
              Protection marches a route ("Point: parade route stop", in order).
              Citizens line it and cheer: /cheer, /salute, /wave, chanting in
              chat ("Glory to the Union!"), jumping up and down. Enthusiasm is a
              meter on screen that drains while the column is near; let it
              drop too low as it passes, and a unit sees to it.

    Everyone has lc_exercise_muster seconds to report. Skipping it: units who
    see you send you there, then use the stick; skip it entirely and it costs
    Civil Standing. Doing it well earns some. Afterwards citizens of good
    standing (Trusted and up) get breakfast (lc_exercise_breakfast); the rest
    eat at the usual distribution.

    A full stomach (hunger 85 or more) helps: completed jobs and shifts give
    15% more XP, and you heal slowly (lc_fullstomach 0/1).

    Admins: lc_morning_exercise 0/1, lc_exercise <jog|drill|parade> (start one now), lc_exercise next
    (what the next morning holds), lc_exercise stop, lc_event jog|drill|parade.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_exercise")
util.AddNetworkString("lc_drill_cue")
util.AddNetworkString("lc_drill_rope")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_morning_exercise", "1", FLAGS, "Morning exercise for citizens (a jog, a drill or a parade at dawn)")
local cvEvery    = CreateConVar("lc_exercise_every", "2", FLAGS, "Hold morning exercise every this many mornings (1: every morning)")
local cvKinds    = CreateConVar("lc_exercise_kinds", "jog,drill,parade", FLAGS, "Which morning exercises take turns (jog, drill, parade)")
local cvMuster   = CreateConVar("lc_exercise_muster", "75", FLAGS, "Seconds citizens have to report for morning exercise")
local cvBeat     = CreateConVar("lc_exercise_beat_dmg", "8", FLAGS, "Damage from one blow with the stick at morning exercise (never takes you below 15 health)")
local cvPay       = CreateConVar("lc_exercise_pay", "5", FLAGS, "Credits a citizen is paid for finishing morning exercise well (0: none)")
local cvSkipRation = CreateConVar("lc_exercise_skip_ration", "1", FLAGS, "A citizen who skips morning exercise has their next ration withheld")
local cvBreakfast = CreateConVar("lc_exercise_breakfast", "1", FLAGS, "After morning exercise, citizens of good standing (Trusted and up) get breakfast")
local cvNPCs     = CreateConVar("lc_exercise_npcs", "10", FLAGS, "How many NPC citizens take part in morning exercise (the city's own first, topped up with new ones out of sight)")
local cvPace     = CreateConVar("lc_jog_pace", "150", FLAGS, "How fast the pace marker goes round the jogging route (Civil Protection units a second; walking is 110, sprinting 190)")
local cvBehind   = CreateConVar("lc_jog_behind", "450", FLAGS, "How far behind the pace marker a jogger can fall before the stick")
local cvJogMin   = CreateConVar("lc_jog_min_speed", "0", FLAGS, "Slowest speed that counts as jogging (0: a bit over your walking speed)")
local cvJogUnits = CreateConVar("lc_jog_units", "8", FLAGS, "Most Civil Protection units posted along the jogging route")
local cvJogGap   = CreateConVar("lc_jog_gap", "600", FLAGS, "Distance between Civil Protection units posted along the jogging route")
local cvBoost    = CreateConVar("lc_jog_boost", "1.5", FLAGS, "Speed multiplier after the stick on the morning jog (1: none)")
local cvBoostS   = CreateConVar("lc_jog_boost_secs", "4", FLAGS, "Seconds the speed boost after the stick lasts")
local cvLaps     = CreateConVar("lc_jog_laps", "1", FLAGS, "Times round the jogging route")
local cvCues     = CreateConVar("lc_drill_cues", "14", FLAGS, "Moves in the morning drill")
local cvPaceD    = CreateConVar("lc_drill_pace", "3.5", FLAGS, "Seconds between moves the instructor calls")
local cvWindow   = CreateConVar("lc_drill_window", "2.5", FLAGS, "Seconds to copy a move")
local cvMistakes = CreateConVar("lc_drill_mistakes", "3", FLAGS, "Mistakes in the drill before the stick (then every two more)")
local cvRope     = CreateConVar("lc_drill_rope", "1", FLAGS, "Skipping in the middle of the drill")
local cvParadeN  = CreateConVar("lc_parade_units", "6", FLAGS, "Soldiers and Civil Protection units marching in the parade column")
local cvParadeMin = CreateConVar("lc_parade_min", "35", FLAGS, "Enthusiasm below this as the column passes earns the stick")
local cvFull     = CreateConVar("lc_fullstomach", "1", FLAGS, "A full stomach (hunger 85+) gives 15% more XP from jobs and shifts")

LC.ExerciseKinds = { jog = true, drill = true, parade = true }
local NAMES = { jog = "Morning jog", drill = "Morning drill", parade = "Morning parade" }
LC.ExerciseNames = NAMES

local X -- the exercise in progress
function LC.ExerciseSession() return X end

local function Pick(t) return t[math.random(#t)] end
local function Flat(v) return Vector(v.x, v.y, 0) end
local function Dist2D(a, b) return (Flat(a) - Flat(b)):Length() end
local function Ground(v) return LC.GroundAt and LC.GroundAt(v) or v end
local function Where(pos) return LC.DescribePlace and LC.DescribePlace(pos) or "the assembly point" end

------------------------------------------------------------------------
-- Who has to take part, and where
------------------------------------------------------------------------

local function Eligible(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if ply:GetNW2String("lcf_faction", "") ~= "citizen" then return false end
    if LC.PlayerIsCP(ply) or (LC.PlayerIsZombie and LC.PlayerIsZombie(ply)) then return false end
    if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then return false end
    if LC.InCustody and LC.InCustody(ply) then return false end
    if LC.IsTied and LC.IsTied(ply) then return false end
    if LC.IsDowned and LC.IsDowned(ply) then return false end
    if LC.DisguisedAsCP and LC.DisguisedAsCP(ply) then return false end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false end
    return true
end
LC.ExerciseEligible = Eligible

-- Routes: the points of one kind, by route number, in the order they were placed.
local function Routes(kind)
    local by, order = {}, {}
    for _, p in ipairs(LC.Points or {}) do
        if p.kind == kind then
            if not by[p.group] then by[p.group] = {} order[#order + 1] = p.group end
            table.insert(by[p.group], p)
        end
    end
    local out = {}
    for _, g in ipairs(order) do if #by[g] >= 2 then out[#out + 1] = by[g] end end
    return out
end
LC.ExerciseRoutes = Routes

-- A path node under every stop of the jogging route (the owner, 7 November: with none there,
-- the city's joggers lost the way). Each stop gets a node (one already within NODE_NEAR of it
-- is used), linked to the stops either side of it round the route and to the nearest other
-- node within LINK_REACH that can be walked to, so the route joins the rest of the paths.
-- Nothing is laid twice: on the next load every stop already has its node. Called when a
-- jogging stop is placed and when the layout loads (sv_livingcity_data.lua). Returns true if
-- the layout changed (the caller saves it).
local NODE_NEAR, LINK_REACH = 48, 450
function LC.LayJogNodes()
    if not (LC.Nodes and LC.AddNode and LC.NearestNode) then return false end
    local changed = false
    local function Link(a, b)
        if not a or not b or a == b then return false end
        if a.links[b.id] then return true end
        if LC.Walkable and not LC.Walkable(a.pos, b.pos) then return false end
        a.links[b.id], b.links[a.id] = true, true
        changed = true
        return true
    end
    for _, route in ipairs(Routes("jogroute")) do
        local nodes, own = {}, {}
        for i, p in ipairs(route) do
            local n = LC.NearestNode(p.pos, NODE_NEAR)
            if not n then
                n = LC.AddNode(p.pos, true)
                changed = true
            end
            nodes[i], own[n] = n, true
        end
        for i, n in ipairs(nodes) do
            Link(n, nodes[i % #nodes + 1]) -- (the next stop; the last one back round to the start)
            local joined = false
            for id in pairs(n.links) do
                local o = LC.Nodes[id]
                if o and not own[o] then joined = true break end
            end
            if not joined then
                -- the nearest nodes that aren't the route's own, nearest first, till one can be walked to
                local near = {}
                for _, o in pairs(LC.Nodes) do
                    local d = o.pos:DistToSqr(n.pos)
                    if not own[o] and d < LINK_REACH * LINK_REACH then near[#near + 1] = { o, d } end
                end
                table.sort(near, function(a, b) return a[2] < b[2] end)
                for k = 1, math.min(3, #near) do
                    if Link(n, near[k][1]) then break end
                end
            end
        end
    end
    return changed
end

local function Yards()
    local out = {}
    for _, p in ipairs(LC.Points or {}) do if p.kind == "yard" then out[#out + 1] = p end end
    return out
end

function LC.ExerciseReady(kind)
    if kind == "jog" then return #Routes("jogroute") > 0 end
    if kind == "parade" then return #Routes("parade") > 0 end
    if kind == "drill" then return #Yards() > 0 end
    return false
end

-- Distance from a spot to a route (its nearest stretch), and how far along it that is.
local function OnRoute(pts, cum, pos)
    local best, along = math.huge, 0
    for i = 1, #pts - 1 do
        local a, b = Flat(pts[i]), Flat(pts[i + 1])
        local ab = b - a
        local len2 = ab:LengthSqr()
        local t = len2 > 0 and math.Clamp((Flat(pos) - a):Dot(ab) / len2, 0, 1) or 0
        local d = (Flat(pos) - (a + ab * t)):Length()
        if d < best then best, along = d, cum[i] + math.sqrt(len2) * t end
    end
    return best, along
end

local function Cumulative(pts)
    local cum = { 0 }
    for i = 2, #pts do cum[i] = cum[i - 1] + Dist2D(pts[i - 1], pts[i]) end
    return cum
end

-- A spot this far along the route.
local function AlongRoute(pts, cum, d)
    for i = 2, #pts do
        if cum[i] >= d then
            local seg = cum[i] - cum[i - 1]
            local t = seg > 0 and (d - cum[i - 1]) / seg or 0
            return LerpVector(t, pts[i - 1], pts[i]), (pts[i] - pts[i - 1]):GetNormalized()
        end
    end
    return pts[#pts], (pts[#pts] - pts[math.max(1, #pts - 1)]):GetNormalized()
end

------------------------------------------------------------------------
-- The units: posted for the morning, and back to their beats after
------------------------------------------------------------------------

local function Free(npc, st)
    return IsValid(npc) and LC.IsSecurity(st) and (st.state == "idle" or st.state == "moving")
        and not st.unmanaged and not st.raid and not st.npcWork and not st.holdPos and not st.guardZone
        and not st.questLock and not st.exUnit and not st.test and npc:Health() > 0
end

-- Units for these posts: the nearest free ones, then fresh ones from out of sight.
local function Post(posts, prefer)
    local pool = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if Free(npc, st) then pool[#pool + 1] = { npc = npc, st = st } end
    end
    local units = {}
    for _, post in ipairs(posts) do
        local best, bi
        for i, u in ipairs(pool) do
            local d = u.npc:GetPos():DistToSqr(post) * ((prefer and u.st.role ~= prefer) and 4 or 1)
            if not best or d < best then best, bi = d, i end
        end
        local npc, st
        if bi then
            npc, st = pool[bi].npc, pool[bi].st
            table.remove(pool, bi)
        else
            local sp = LC.Spawners and (LC.Spawners[prefer or "cop"] or LC.Spawners.cop)
            local from = LC.AlarmSquadSpot and LC.AlarmSquadSpot(post) or post
            if sp then
                local ok, n, s = pcall(sp, from)
                if ok and IsValid(n) and s then npc, st = n, s st.unmanaged = true st.exTemp = true end
            end
        end
        if npc then
            st.exUnit = true
            st.exInspect = st.nextInspect
            st.nextInspect = math.huge -- (no stopping people while on duty here)
            st.holdPos = Ground(post)
            if LC.GoTo then LC.GoTo(npc, st, st.holdPos, true, nil) end
            units[#units + 1] = npc
        end
    end
    return units
end

local function Unpost(npc)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    st.exUnit, st.holdPos, st.exChase, st.exColumn, st.exNext = nil, nil, nil, nil, nil
    st.nextInspect = CurTime() + math.Rand(20, 50)
    if st.state == "event" then LC.SetState(npc, st, "idle") st.untilT = CurTime() + 2 end
    if st.exTemp then
        -- the extra ones go back where they came from, once nobody's looking
        local tries = 0
        timer.Create("LivingCityExerciseLeave" .. npc:EntIndex(), 5, 40, function()
            tries = tries + 1
            if not IsValid(npc) then return end
            if tries >= 40 or not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) then npc:Remove() end
        end)
    end
end

------------------------------------------------------------------------
-- The stick
------------------------------------------------------------------------

local SWING = { "pushplayer", "swinggesture", "ACT_MELEE_ATTACK_SWING_GESTURE", "ACT_MELEE_ATTACK1", "ACT_MELEE_ATTACK_SWING" }
-- (on the jog: "Move it!", "Keep moving!", never "First warning, move away", which sounded like being told to get back)
local COP_BARK = { "npc/metropolice/vo/moveit.wav", "npc/metropolice/vo/moveit2.wav", "npc/metropolice/vo/keepmoving.wav", "npc/metropolice/vo/movealong.wav" }
local HIT = { jog = "Keep up, citizen.", drill = "Do it properly.", parade = "Louder, citizen. With feeling.", absent = "Exercise is mandatory." }

local function Rec(ply) return X and X.people[ply] end

local function Boost(ply)
    local mul = cvBoost:GetFloat()
    if mul <= 1 then return end
    local b = ply.lcxBoost
    if not b then
        b = { walk = ply:GetWalkSpeed(), run = ply:GetRunSpeed() }
        ply.lcxBoost = b
    end
    b.untilT = CurTime() + cvBoostS:GetFloat()
    b.setWalk, b.setRun = math.floor(b.walk * mul), math.floor(b.run * mul)
    ply:SetWalkSpeed(b.setWalk)
    ply:SetRunSpeed(b.setRun)
    ply:SetNW2Float("lcx_boost", b.untilT)
end

local function EndBoost(ply)
    local b = ply.lcxBoost
    if not b then return end
    ply.lcxBoost = nil
    -- (unless something else has changed their speed since)
    if ply:GetWalkSpeed() == b.setWalk then ply:SetWalkSpeed(b.walk) end
    if ply:GetRunSpeed() == b.setRun then ply:SetRunSpeed(b.run) end
    ply:SetNW2Float("lcx_boost", 0)
end
LC.ExerciseBoost, LC.ExerciseEndBoost = Boost, EndBoost

function LC.ExerciseBeat(npc, ply, why)
    if not IsValid(ply) or not ply:Alive() then return false end
    local now = CurTime()
    if (ply.lcxBeatNext or 0) > now then return false end
    ply.lcxBeatNext = now + 3
    local role = "cop"
    if IsValid(npc) then
        local st = LC.NPCs and LC.NPCs[npc]
        role = st and st.role or "cop"
        LC.Face(npc, ply:GetPos())
        if LC.PlayGesture then LC.PlayGesture(npc, SWING, 1.2) end
        npc:EmitSound(role == "cop" and "Weapon_StunStick.Melee_Hit" or ("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav"), 75)
        if role == "cop" and math.random() < 0.6 then npc:EmitSound(Pick(COP_BARK), 78) end
    end
    local dmg = math.min(cvBeat:GetFloat(), math.max(0, ply:Health() - 15))
    if dmg > 0 then ply:TakeDamage(dmg, IsValid(npc) and npc or nil, IsValid(npc) and npc or nil) end
    ply:ViewPunch(Angle(-14, math.Rand(-8, 8), 0))
    local push = IsValid(npc) and (ply:GetPos() - npc:GetPos()) or Vector(0, 0, 0)
    -- on the jog, a shove on along the route: toward the next marker
    local r0 = Rec(ply)
    if why == "jog" and r0 and r0.cp and X.route and X.route[r0.cp] then push = X.route[r0.cp] - ply:GetPos() end
    push.z = 0
    push = push:GetNormalized() * 220 + Vector(0, 0, 90)
    ply:SetVelocity(push)
    ply:ChatPrint("[Civil Protection] A crack with the stick. " .. (HIT[why] or HIT.absent))
    local r = Rec(ply)
    if r then r.beatings = (r.beatings or 0) + 1 end
    if why == "jog" then Boost(ply) end
    hook.Run("LivingCityExerciseBeating", ply, npc, why)
    return true
end

-- A unit deals with someone: the stick if they're close, else a run over to them.
local function SendUnit(units, ply, why, reach)
    local best, bd
    local pos = ply:GetPos()
    for _, u in ipairs(units) do
        local st = IsValid(u) and LC.NPCs[u]
        if st and st.state ~= "hostile" then
            local d = u:GetPos():DistToSqr(pos)
            if d < (reach or 700) ^ 2 and (not bd or d < bd) then best, bd = u, d end
        end
    end
    -- nobody posted near: any unit about who can see them steps in (and stays on it)
    if not best then
        local eye = ply:EyePos()
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and LC.IsSecurity(st) and st.state ~= "hostile" and not st.exColumn then
                local d = npc:GetPos():DistToSqr(pos)
                if d < 1400 * 1400 and (not bd or d < bd) and LC.LineOfSight and LC.LineOfSight(npc:EyePos(), eye, npc) then best, bd = npc, d end
            end
        end
        if best and X and not table.HasValue(X.units, best) then
            X.units[#X.units + 1] = best
            X.borrowed = X.borrowed or {}
            X.borrowed[best] = true
        end
    end
    -- and long out of everyone's reach: the nearest of the route's own units comes for them
    if not best and X and (ply.lcxUnreached or 0) > 0 and CurTime() - ply.lcxUnreached > 12 then
        for _, u in ipairs(units) do
            local st = IsValid(u) and LC.NPCs[u]
            if st and st.state ~= "hostile" then
                local d = u:GetPos():DistToSqr(pos)
                if not bd or d < bd then best, bd = u, d end
            end
        end
    end
    if not best then
        ply.lcxUnreached = ply.lcxUnreached or CurTime()
        return false
    end
    ply.lcxUnreached = nil
    if bd < 120 * 120 then return LC.ExerciseBeat(best, ply, why) end
    local st = LC.NPCs[best]
    local now = CurTime()
    if st.exChase ~= ply or now > (st.exChaseT or 0) then
        st.exChase, st.exChaseT = ply, now + 1.5 + math.sqrt(bd) / 200
        if LC.GoTo then LC.GoTo(best, st, pos, true, nil) end
    end
    return false
end

-- Units still chasing someone: the stick once they get there.
local function ChaseThink(units, now)
    for _, u in ipairs(units) do
        local st = IsValid(u) and LC.NPCs[u]
        local ply = st and st.exChase
        if ply then
            if not IsValid(ply) or not ply:Alive() or now > (st.exChaseT or 0) + 6 then
                st.exChase = nil
            elseif u:GetPos():DistToSqr(ply:GetPos()) < 120 * 120 then
                local r = Rec(ply)
                LC.ExerciseBeat(u, ply, st.exWhy or (r and r.why) or X.kind)
                st.exChase = nil
            end
        end
    end
end

------------------------------------------------------------------------
-- Keeping everyone informed
------------------------------------------------------------------------

local function Send(to)
    net.Start("lc_exercise")
    if not X then
        net.WriteString("")
    else
        net.WriteString(X.kind)
        net.WriteString(X.phase)
        net.WriteFloat(X.musterEnds)
        net.WriteFloat(X.ends or 0)
        net.WriteTable({ center = X.center, route = X.route, pace = X.pace, runStart = X.runStart, total = X.total, laps = X.laps,
            yard = X.yard and X.yard.pos, yardYaw = X.yard and X.yard.yaw })
    end
    if to then net.Send(to) else net.Broadcast() end
end
LC.SendExercise = Send

local function Tell(ply, msg) if IsValid(ply) then ply:ChatPrint("[" .. (X and NAMES[X.kind] or "Morning exercise") .. "] " .. msg) end end

------------------------------------------------------------------------
-- NPC citizens join in
------------------------------------------------------------------------

local function EnlistCitizens(n, poiFor)
    local got = 0
    for npc, st in pairs(LC.NPCs or {}) do
        if got >= n then break end
        if IsValid(npc) and st.role == "citizen" and (st.state == "idle" or st.state == "moving") and not st.unmanaged and not st.questLock
            and not st.test and not st.leaving and not st.line and not st.npcWork and not st.carry then
            local pos, data = poiFor(got + 1, npc)
            if pos and LC.GoTo and LC.GoTo(npc, st, pos, X.kind == "jog", { kind = "exercise", pos = pos, yaw = data and data.yaw }) then
                st.exCitizen = data or {}
                X.npcs[npc] = true
                got = got + 1
            end
        end
    end
    -- not enough of them about: more come out of a doorway near by (out of sight)
    local sp = LC.Spawners and LC.Spawners.citizen
    for _ = got + 1, n do
        local pos, data = poiFor(got + 1)
        if not (pos and sp) then break end
        local from = (LC.AlarmSquadSpot and LC.AlarmSquadSpot(pos)) or nil
        if not from then break end
        local ok, npc, st = pcall(sp, from)
        if not (ok and IsValid(npc) and st) then break end
        if LC.GoTo and LC.GoTo(npc, st, pos, X.kind == "jog", { kind = "exercise", pos = pos, yaw = data and data.yaw }) then
            st.exCitizen = data or {}
            st.exTemp = true
            X.npcs[npc] = true
            got = got + 1
        end
    end
end

local function ReleaseCitizens()
    local now = CurTime()
    for npc in pairs(X.npcs) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st then
            st.exCitizen = nil
            if st.state == "event" or st.state == "moving" then LC.SetState(npc, st, "idle") st.untilT = now + math.Rand(1, 4) end
        end
    end
end

-- The city's joggers each keep to their own lane, a little to the side of the route,
-- so they don't all aim for the same spot and jostle round it in circles.
local function JogTo(npc, st, c)
    local i = c.i
    local at = X.route[i]
    if not at then return false end
    local lane = c.lane or 0
    if lane ~= 0 then
        local a, b = X.route[math.max(1, i - 1)], X.route[i]
        if a == b then b = X.route[i + 1] or b end
        local dir = Flat(b - a)
        if dir:LengthSqr() > 1 then
            dir:Normalize()
            local spot = Ground(at + Vector(-dir.y, dir.x, 0) * lane + Vector(0, 0, 30))
            if spot and LC.GoTo(npc, st, spot, true, { kind = "exercise" }) then return true end
        end
    end
    return LC.GoTo(npc, st, at, true, { kind = "exercise" })
end
LC.ExerciseJogTo = function(npc, st, c) return X and JogTo(npc, st, c) end

-- An NPC arriving somewhere for the exercise (sv_livingcity.lua's Arrive hands them over).
function LC.ExerciseArrive(npc, st, now)
    local c = st.exCitizen
    if st.exColumn and X and X.kind == "parade" then
        -- the column: on to the next stop of the route
        local col = st.exColumn
        repeat
            col.i = col.i + 1
            if col.i > #X.route then
                col.done = true
                LC.SetState(npc, st, "event") st.eventUntil = now + 600
                return
            end
        until LC.GoTo(npc, st, X.route[col.i] + col.offset, false, { kind = "exercise" })
        return
    end
    if not c or not X then st.untilT = now + 2 return end
    if X.kind == "jog" and X.phase == "run" then
        c.i = (c.i or 1) + 1
        if c.i > #X.route then st.exCitizen = nil st.untilT = now + math.Rand(3, 8) return end
        JogTo(npc, st, c)
        return
    end
    -- at their place: they stay put for it
    LC.SetState(npc, st, "event")
    st.eventUntil = now + 900
    if c.yaw then LC.FaceYaw(npc, c.yaw) end
end

------------------------------------------------------------------------
-- Setting up each kind
------------------------------------------------------------------------

local function SetupJog()
    local routes = Routes("jogroute")
    local pts = {}
    for _, p in ipairs(Pick(routes)) do pts[#pts + 1] = p.pos end
    X.laps = math.max(1, cvLaps:GetInt())
    local route = {}
    for _ = 1, X.laps do for _, v in ipairs(pts) do route[#route + 1] = v end end
    X.route = route
    X.cum = Cumulative(route)
    X.total = X.cum[#route]
    X.pace = math.max(40, cvPace:GetFloat())
    X.center = route[1]
    -- posts along the route, every so often, a little off to one side
    local n = math.Clamp(math.floor(Cumulative(pts)[#pts] / math.max(150, cvJogGap:GetFloat())), 2, math.max(2, cvJogUnits:GetInt()))
    local posts = {}
    local loopLen = Cumulative(pts)[#pts]
    for i = 1, n do
        local spot, dir = AlongRoute(pts, Cumulative(pts), loopLen * (i - 0.5) / n)
        local side = Vector(-dir.y, dir.x, 0) * ((i % 2 == 0) and 90 or -90)
        posts[#posts + 1] = spot + side
    end
    X.units = Post(posts, "cop")
    EnlistCitizens(cvNPCs:GetInt(), function(i)
        return route[1] + Vector(math.Rand(-120, 120), math.Rand(-120, 120), 0), { i = 1 }
    end)
end

local function DrillSpot(i)
    local y = X.yard
    local fwd, right = Angle(0, y.yaw, 0):Forward(), Angle(0, y.yaw, 0):Right()
    local row, col = math.floor((i - 1) / 5), (i - 1) % 5 - 2
    return Ground(y.pos + fwd * (220 + row * 100) + right * (col * 100))
end

local function SetupDrill()
    X.yard = Pick(Yards())
    X.center = X.yard.pos
    X.radius = 900
    X.spots, X.taken = {}, {}
    for i = 1, 40 do X.spots[i] = DrillSpot(i) end
    local fwd, right = Angle(0, X.yard.yaw, 0):Forward(), Angle(0, X.yard.yaw, 0):Right()
    -- units at the edges of the yard, and one behind the back row
    X.units = Post({ X.yard.pos + fwd * 300 + right * 380, X.yard.pos + fwd * 300 - right * 380, X.yard.pos + fwd * 780 }, "cop")
    -- a player Clinic Medic or Records Clerk leads it, if there is one
    local best, bd
    for _, p in ipairs(player.GetAll()) do
        local job = p:GetNW2String("lcj_job", "")
        if (job == "medic" or job == "clerk") and Eligible(p) then
            local d = p:GetPos():DistToSqr(X.yard.pos)
            if not bd or d < bd then best, bd = p, d end
        end
    end
    X.leaderCandidate = best
    if IsValid(best) then
        Tell(best, "You lead the drill this morning. Stand at the front of the yard (the marker) facing the rows: every move you make " ..
            "(crouch, jump, spin, a step left, right, forward or back) is called out for them to copy, one every few seconds. Stand still and the instructor fills in.")
    end
    X.cues, X.cueNo = {}, 0
    X.nextCue = 0
    EnlistCitizens(cvNPCs:GetInt(), function(i)
        local spot = X.spots[#X.spots - i + 1] -- (the back rows: the players get the front)
        X.taken[#X.spots - i + 1] = true
        return spot, { yaw = X.yard.yaw + 180 }
    end)
end

local function SetupParade()
    local pts = {}
    for _, p in ipairs(Pick(Routes("parade"))) do pts[#pts + 1] = p.pos end
    X.route = pts
    X.cum = Cumulative(pts)
    X.total = X.cum[#pts]
    X.center = pts[1]
    -- the column forms up at the start: soldiers if there are any, Civil Protection otherwise
    local n = math.max(2, cvParadeN:GetInt())
    local dir = (pts[2] - pts[1]):GetNormalized()
    local side = Vector(-dir.y, dir.x, 0)
    local posts = {}
    for i = 1, n do
        local rank = math.floor((i - 1) / 2)
        posts[i] = pts[1] - dir * (60 + rank * 70) + side * ((i % 2 == 0) and 40 or -40)
    end
    X.column = Post(posts, "soldier")
    for i, u in ipairs(X.column) do
        local st = LC.NPCs[u]
        if st then st.exColumn = { i = 0, offset = side * ((i % 2 == 0) and 40 or -40), delay = math.floor((i - 1) / 2) * 1.6 } end
    end
    -- and guards along the way, to keep the crowd honest
    local guards = {}
    local g = math.Clamp(math.floor(X.total / 700), 2, 6)
    for i = 1, g do
        local spot, d = AlongRoute(pts, X.cum, X.total * (i - 0.5) / g)
        guards[#guards + 1] = spot + Vector(-d.y, d.x, 0) * ((i % 2 == 0) and 140 or -140)
    end
    X.units = Post(guards, "cop")
    EnlistCitizens(cvNPCs:GetInt(), function(i)
        local spot, d = AlongRoute(pts, X.cum, X.total * (i - 0.5) / math.max(1, cvNPCs:GetInt()))
        local s = (i % 2 == 0) and 1 or -1
        local yaw = (Vector(d.y, -d.x, 0) * s):Angle().y
        return spot + Vector(-d.y, d.x, 0) * (170 * s), { yaw = yaw, cheer = true }
    end)
end

------------------------------------------------------------------------
-- Starting, running, ending
------------------------------------------------------------------------

-- A place in the drill's rows: the nearest free one.
local function AssignSpot(ply, r)
    local best, bi
    for i, s in ipairs(X.spots) do
        if not X.taken[i] then
            local d = s:DistToSqr(ply:GetPos())
            if not best or d < best then best, bi = d, i end
        end
    end
    if bi then X.taken[bi] = true r.spot = X.spots[bi] ply:SetNW2Vector("lcx_spot", r.spot) end
end

local function InArea(ply)
    local pos = ply:GetPos()
    if X.kind == "drill" then return pos:DistToSqr(X.yard.pos) < X.radius * X.radius end
    if X.kind == "jog" then
        if X.phase == "muster" then return pos:DistToSqr(X.route[1]) < 600 * 600 end
        return (OnRoute(X.route, X.cum, pos)) < 300
    end
    return (OnRoute(X.route, X.cum, pos)) < 520 -- parade: lining the route
end

local function Join(ply, late)
    if X.people[ply] or not Eligible(ply) then return X.people[ply] end
    local r = { late = late, beatings = 0, mistakes = 0, total = 0, actions = {}, cheer = 70, cheerSum = 0, cheerN = 0 }
    X.people[ply] = r
    X.absent[ply] = nil
    if X.kind == "jog" then
        if X.phase == "run" then
            local _, along = OnRoute(X.route, X.cum, ply:GetPos())
            r.cp = #X.route
            for i = 2, #X.route do if X.cum[i] > along then r.cp = i break end end
            -- late: your own pace marker starts where you join, and the jog waits for you to finish it
            local pacer = math.min(X.total, (CurTime() - (X.runStart or CurTime())) * X.pace)
            r.lag = math.max(0, pacer - along)
            ply:SetNW2Float("lcx_lag", r.lag)
            local need = (X.runStart or CurTime()) + (X.total + r.lag) / X.pace + 70
            if LC.EventEnds and LC.EventEnds < need then
                LC.EventEnds = need
                X.ends = need
                if SetGlobal2Float then SetGlobal2Float("lc_event_ends", need) end
                timer.Simple(0, function() if X then Send() end end)
            end
        else
            r.cp = 2
        end
        ply:SetNW2Int("lcx_cp", r.cp)
    elseif X.kind == "drill" and X.phase == "run" then
        AssignSpot(ply, r)
    end
    ply:SetNW2Bool("lcx_in", true)
    if late then Tell(ply, "Late. It has been noted.") end
    return r
end

function LC.ExerciseBegin(kind)
    if X then LC.ExerciseFinish() end
    local now = CurTime()
    X = { kind = kind, phase = "muster", start = now, musterEnds = now + math.max(15, cvMuster:GetFloat()),
        people = {}, absent = {}, npcs = {}, units = {}, column = {} }
    local ok, err = pcall(kind == "jog" and SetupJog or kind == "drill" and SetupDrill or SetupParade)
    if not ok then
        LC.Error("exercise setup", err)
        X = nil
        return false
    end
    X.ends = LC.EventEnds or (now + 420)
    for _, p in ipairs(player.GetAll()) do
        p.lcxSeen, p.lcxUnreached = X, nil
        if Eligible(p) then X.absent[p] = true p:SetNW2Bool("lcx_in", false) end
    end
    Send()
    LC.Log("info", "Morning exercise: " .. kind)
    return true
end

local function StartRun(now)
    X.phase = "run"
    X.runStart = now
    for _, p in ipairs(player.GetAll()) do
        if X.absent[p] and InArea(p) then X.absent[p] = nil Join(p, false) end
    end
    if X.kind == "drill" then
        local l = X.leaderCandidate
        if IsValid(l) and l:Alive() and l:GetPos():DistToSqr(X.yard.pos) < 300 * 300 then
            X.leader = l
            X.people[l] = nil
            X.absent[l] = nil
            l:SetNW2Bool("lcx_leader", true)
            Tell(l, "You're leading. Go.")
        else
            -- a Union fitness instructor runs it
            local sp = LC.Spawners and LC.Spawners.citizen
            if sp then
                local ok, npc, st = pcall(sp, X.yard.pos + Vector(0, 0, 4))
                if ok and IsValid(npc) and st then
                    st.unmanaged, st.questLock = true, true
                    LC.SetState(npc, st, "event")
                    st.eventUntil = math.huge
                    npc:SetPos(X.yard.pos + Vector(0, 0, 4))
                    LC.FaceYaw(npc, X.yard.yaw)
                    LC.SetNPCStr(npc, "lc_pname", "Union fitness instructor")
                    X.instructor = npc
                end
            end
        end
        -- everyone to their places
        for p, r in pairs(X.people) do AssignSpot(p, r) end
        X.nextCue = now + 3
        X.ropeAt = cvRope:GetBool() and math.floor(math.max(2, cvCues:GetInt()) / 2) or -1
    elseif X.kind == "jog" then
        -- the NPC joggers set off, each in a lane of their own and a moment apart (not a scrum)
        local k = 0
        for npc in pairs(X.npcs) do
            local st = IsValid(npc) and LC.NPCs[npc]
            if st and st.exCitizen then
                k = k + 1
                st.exCitizen.i = 1
                st.exCitizen.lane = ((k % 5) - 2) * 40
                local c, ex = st.exCitizen, X
                timer.Simple((k - 1) * 0.6, function()
                    if X == ex and IsValid(npc) and LC.NPCs[npc] == st and st.exCitizen == c then LC.ExerciseArrive(npc, st, CurTime()) end
                end)
            end
        end
    elseif X.kind == "parade" then
        for _, u in ipairs(X.column) do
            local st = LC.NPCs[u]
            if st and st.exColumn then
                st.holdPos = nil
                timer.Simple(st.exColumn.delay, function()
                    if IsValid(u) and X and X.kind == "parade" and LC.NPCs[u] then
                        LC.ExerciseArrive(u, LC.NPCs[u], CurTime())
                    end
                end)
            end
        end
    end
    for p in pairs(X.people) do
        if X.kind == "jog" then Tell(p, "Go! Keep jogging, and keep up with the pace marker.")
        elseif X.kind == "drill" then Tell(p, "Stay on your place (the ring) and copy every move. Mistakes are counted.")
        else Tell(p, "Here they come. Cheer! (/cheer, /salute, chant in chat, jump.) Enthusiasm is watched.") end
    end
    for p in pairs(X.absent) do
        if IsValid(p) then Tell(p, "You didn't report. Get there now: " .. Where(X.center) .. ". Civil Protection units are looking for you.") end
    end
    Send()
end

-- Seen skipping it by a unit: sent there, then the stick.
local function Truants(now)
    for p in pairs(X.absent) do
        if not IsValid(p) or not Eligible(p) then
            X.absent[p] = nil
        elseif InArea(p) then
            Join(p, true)
        elseif now > (p.lcxTruantNext or 0) then
            p.lcxTruantNext = now + 1
            local eye = p:EyePos()
            for npc, st in pairs(LC.NPCs or {}) do
                if IsValid(npc) and LC.IsSecurity(st) and st.state ~= "hostile" and npc:GetPos():DistToSqr(p:GetPos()) < 700 * 700
                    and LC.LineOfSight(npc:EyePos(), eye, npc) then
                    p.lcxTruantN = (p.lcxTruantN or 0) + 1
                    if p.lcxTruantN == 1 then
                        LC.Face(npc, p:GetPos())
                        npc:EmitSound("npc/metropolice/vo/firstwarningmove.wav", 78)
                        Tell(p, "[Civil Protection] Morning exercise is mandatory. Report to " .. Where(X.center) .. ". Now.")
                        p.lcxTruantNext = now + 20
                    elseif npc:GetPos():DistToSqr(p:GetPos()) < 120 * 120 then
                        LC.ExerciseBeat(npc, p, "absent")
                        p.lcxTruantNext = now + 15
                    elseif not st.exChase and (st.state == "idle" or st.state == "moving") then
                        st.exChase, st.exChaseT, st.exWhy = p, now + 1.5, "absent"
                        LC.GoTo(npc, st, p:GetPos(), true, nil)
                        if not table.HasValue(X.units, npc) then X.units[#X.units + 1] = npc X.borrowed = X.borrowed or {} X.borrowed[npc] = true end
                    end
                    break
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- The jog
------------------------------------------------------------------------

local function JogSpeed(ply)
    local m = cvJogMin:GetFloat()
    if m > 0 then return m end
    local b = ply.lcxBoost
    local walk, run = b and b.walk or ply:GetWalkSpeed(), b and b.run or ply:GetRunSpeed()
    return math.min(walk * 1.15, run * 0.85)
end

local function Progress(ply, r)
    local i = math.min(r.cp, #X.route)
    local seg = X.cum[i] - X.cum[i - 1]
    local d = Dist2D(ply:GetPos(), X.route[i])
    return X.cum[i - 1] + math.Clamp(seg - d, 0, seg)
end
LC.ExerciseProgress = function(ply) local r = Rec(ply) return r and r.cp and Progress(ply, r) or nil end

-- The city's own joggers keep up with the pace marker: one who has fallen behind (lost the way,
-- held up) catches up out of everyone's sight, a little behind the marker.
local function NPCJoggers(now, pacer)
    if (X.npcNext or 0) > now then return end
    X.npcNext = now + 1
    local k = 0
    for npc in pairs(X.npcs) do
        local st = IsValid(npc) and LC.NPCs[npc]
        local c = st and st.exCitizen
        if c and c.i then
            k = k + 1
            local _, along = OnRoute(X.route, X.cum, npc:GetPos())
            local off = Dist2D and Dist2D(npc:GetPos(), (AlongRoute(X.route, X.cum, along))) or 0
            local want = math.max(0, pacer - 60 - (k % 5) * 45)
            if (along < want - 350 or off > 400) and not LC.IsSeen(npc:GetPos() + Vector(0, 0, 40)) then
                local spot = AlongRoute(X.route, X.cum, want)
                if spot and not LC.IsSeen(spot + Vector(0, 0, 40)) then
                    spot = Ground(spot + Vector(math.Rand(-50, 50), math.Rand(-50, 50), 0)) or spot
                    npc:SetPos(spot + Vector(0, 0, 4))
                    c.i = #X.route
                    for i = 2, #X.route do if X.cum[i] > want then c.i = i break end end
                    JogTo(npc, st, c)
                end
            end
        end
    end
end

local function JogThink(now)
    local pacer = math.min(X.total, (now - X.runStart) * X.pace)
    NPCJoggers(now, pacer)
    local allDone = true
    for p, r in pairs(X.people) do
        if not IsValid(p) or not p:Alive() then
            -- (dead or gone: they're out of it)
        elseif not r.done then
            allDone = false
            -- the markers, in order
            local target = X.route[r.cp]
            if target and p:GetPos():DistToSqr(target) < 150 * 150 then
                r.cp = r.cp + 1
                p:SetNW2Int("lcx_cp", r.cp)
                if r.cp > #X.route then
                    r.done = now
                    Tell(p, "Finished." .. (r.beatings == 0 and " Not a single blow. The Union notices." or ""))
                end
            end
            if not r.done then
                local v = p:GetVelocity()
                local speed = Vector(v.x, v.y, 0):Length()
                local slow = speed < JogSpeed(p)
                if slow then r.slowSince = r.slowSince or now else r.slowSince = nil end
                local mine = math.min(X.total, (now - X.runStart) * X.pace - (r.lag or 0)) -- (their own marker, if they joined late)
                local behind = Progress(p, r) < mine - cvBehind:GetFloat()
                local walking = r.slowSince and now - r.slowSince > 2.5 and not p.lcxBoost
                p:SetNW2Bool("lcx_behind", behind)
                if behind or walking then
                    r.why = "jog"
                    if now > (r.warnNext or 0) then
                        r.warnNext = now + 6
                        Tell(p, behind and "You're falling behind the pace. Run." or "That's not jogging. Pick it up.")
                    end
                    SendUnit(X.units, p, "jog", 700)
                end
            end
        end
    end
    -- over once everyone's in, or a minute after the pace marker (the latest joiner's own marker)
    local lag = 0
    for p, r in pairs(X.people) do if IsValid(p) and not r.done then lag = math.max(lag, r.lag or 0) end end
    if (allDone and next(X.people) ~= nil and now - X.runStart > 10) or (now - X.runStart > (X.total + lag) / X.pace + 60) then
        LC.EndEvent(false)
    end
end

------------------------------------------------------------------------
-- The drill
------------------------------------------------------------------------

local MOVES = { "crouch", "jump", "spin", "step_left", "step_right", "step_forward", "step_back" }
LC.DrillMoves = MOVES
local MOVE_SAY = { crouch = "Crouch!", jump = "Jump!", spin = "Turn around, all the way!", step_left = "Step left!",
    step_right = "Step right!", step_forward = "Step forward!", step_back = "Step back!" }
local KEY_MOVE = { [IN_DUCK or 4] = "crouch", [IN_JUMP or 2] = "jump", [IN_MOVELEFT or 512] = "step_left", [IN_MOVERIGHT or 1024] = "step_right",
    [IN_FORWARD or 8] = "step_forward", [IN_BACK or 16] = "step_back" }

local function Mistake(p, r, why)
    r.mistakes = r.mistakes + 1
    r.total = r.total + 1
    p:SetNW2Int("lcx_mistakes", r.total)
    local need = math.max(1, cvMistakes:GetInt())
    Tell(p, why .. string.format(" (%d of %d)", math.min(r.mistakes, need), need))
    if r.mistakes >= need then
        r.mistakes = need - 2
        r.why = "drill"
        r.owed = true
    end
end

local function Cue(move, now)
    X.cueNo = X.cueNo + 1
    X.lastCueT = now
    local win = math.max(1, cvWindow:GetFloat())
    X.cue = { move = move, t = now, deadline = now + win }
    for p, r in pairs(X.people) do r.pending = { move = move, t = now, deadline = now + win } end
    net.Start("lc_drill_cue")
    net.WriteString(move)
    net.WriteFloat(now + win)
    net.WriteBool(IsValid(X.leader))
    net.Broadcast()
    if IsValid(X.instructor) then
        X.instructor:EmitSound("buttons/blip1.wav", 70)
        if move == "spin" then
            local yaw = X.yard.yaw
            LC.FaceYaw(X.instructor, yaw + 180)
            timer.Simple(0.8, function() if X and IsValid(X.instructor) then LC.FaceYaw(X.instructor, yaw) end end)
        end
    end
    -- the NPCs in the rows have a go (mostly right)
    for npc in pairs(X.npcs) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st and st.state == "event" and math.random() < 0.85 and st.exCitizen then
            local yaw = st.exCitizen.yaw
            if move == "spin" and yaw then
                LC.FaceYaw(npc, yaw + 180)
                timer.Simple(0.8, function() if IsValid(npc) then LC.FaceYaw(npc, yaw) end end)
            elseif move == "crouch" and LC.PlayGesture then
                LC.PlayGesture(npc, { "Crouch_idleD", "crouchidle_panicked4", "ACT_COWER" }, 1.5)
            end
        end
    end
end
LC.DrillCue = Cue

local function RopeStart(now)
    local interval, beats = 0.85, 10
    X.rope = { start = now + 2.5, interval = interval, beats = beats, n = 0 }
    net.Start("lc_drill_rope")
    net.WriteFloat(X.rope.start)
    net.WriteFloat(interval)
    net.WriteUInt(beats, 8)
    net.Broadcast()
    for p in pairs(X.people) do Tell(p, "Skipping! Jump on every beat of the rope.") end
end

-- What someone did, and when (crouch, jump, a step, a spin).
local function Action(ply, move, now)
    if not X or X.kind ~= "drill" or X.phase ~= "run" then return end
    if ply == X.leader then
        if not X.rope and now - (X.lastCueT or 0) >= 2.5 and X.cueNo < math.max(2, cvCues:GetInt()) then
            X.leaderActive = now
            Cue(move, now)
        end
        return
    end
    local r = X.people[ply]
    if not r then return end
    r.actions[#r.actions + 1] = { move = move, t = now }
    if #r.actions > 12 then table.remove(r.actions, 1) end
    if move == "jump" then r.lastJump = now end
end
LC.DrillAction = Action

hook.Add("KeyPress", "LivingCityExercise", function(ply, key)
    if not X or X.phase ~= "run" then return end
    local now = CurTime()
    if X.kind == "drill" then
        local m = KEY_MOVE[key]
        if m == "jump" and not ply:IsOnGround() then return end
        if m then Action(ply, m, now) end
    elseif X.kind == "parade" and key == (IN_JUMP or 2) then
        local r = X.people[ply]
        if r and now > (r.jumpNext or 0) then
            r.jumpNext = now + 0.4
            r.cheer = math.min(100, r.cheer + 6)
        end
    end
end)

local function DrillThink(now)
    -- spins: the view turned most of the way round within a moment
    for _, p in ipairs(player.GetAll()) do
        local r = X.people[p] or (p == X.leader and {})
        if r then
            local yaw = p:EyeAngles().y
            local last = p.lcxYaw
            p.lcxYaw = yaw
            if last then
                local d = math.AngleDifference(yaw, last)
                p.lcxSpin = p.lcxSpin or {}
                table.insert(p.lcxSpin, { d = d, t = now })
                local sum = 0
                for i = #p.lcxSpin, 1, -1 do
                    if now - p.lcxSpin[i].t > 1.6 then table.remove(p.lcxSpin, i) else sum = sum + p.lcxSpin[i].d end
                end
                if math.abs(sum) >= 300 then
                    p.lcxSpin = {}
                    Action(p, "spin", now)
                end
            end
        end
    end

    -- the rope
    local rope = X.rope
    if rope then
        local beatT = rope.start + rope.n * rope.interval
        if now >= beatT + 0.2 then
            rope.n = rope.n + 1
            for p, r in pairs(X.people) do
                if IsValid(p) and p:Alive() then
                    local j = r.lastJump
                    if not (j and j >= beatT - 0.45 and j <= beatT + 0.2) then
                        r.ropeMiss = (r.ropeMiss or 0) + 1
                        if r.ropeMiss <= 3 then Mistake(p, r, "The rope catches your ankles.") end
                    end
                end
            end
            if rope.n >= rope.beats then
                X.rope = nil
                X.ropeDone = true
                X.nextCue = now + 2
                for _, r in pairs(X.people) do r.ropeMiss = nil end
            end
        end
    end

    -- judging the last move
    for p, r in pairs(X.people) do
        local pend = r.pending
        if pend and now >= pend.deadline then
            r.pending = nil
            local first
            for _, a in ipairs(r.actions) do
                if a.t >= pend.t - 0.15 and a.t <= pend.deadline then first = a break end
            end
            if not first then Mistake(p, r, "Too slow.")
            elseif first.move ~= pend.move then Mistake(p, r, "Wrong move.") end
        end
        -- your own place, not someone else's
        if r.spot and IsValid(p) and p:Alive() then
            if Dist2D(p:GetPos(), r.spot) > 130 then
                r.outSince = r.outSince or now
                if now - r.outSince > 2.5 then
                    r.outSince = now
                    Mistake(p, r, "Back to your place.")
                end
            else
                r.outSince = nil
            end
        end
        if r.owed and IsValid(p) then
            if SendUnit(X.units, p, "drill", 1200) then r.owed = nil end
        end
    end

    -- the next move
    if not X.rope and now >= X.nextCue then
        local n = math.max(2, cvCues:GetInt())
        if X.cueNo == X.ropeAt and not X.ropeDone then
            RopeStart(now)
            X.ropeAt = -1
        elseif X.cueNo >= n then
            if now > (X.lastCueT or 0) + cvWindow:GetFloat() + 1 then LC.EndEvent(false) end
        else
            -- a player leader calls them; if they stand about, the instructor's voice fills in
            local leaderLive = IsValid(X.leader) and X.leader:Alive() and now - (X.leaderActive or X.runStart) < 10
            if not leaderLive then
                local m
                repeat m = Pick(MOVES) until m ~= X.lastMove or #MOVES < 2
                X.lastMove = m
                Cue(m, now)
            end
            X.nextCue = now + math.max(1.5, cvPaceD:GetFloat())
        end
    end
end

------------------------------------------------------------------------
-- The parade
------------------------------------------------------------------------

local CHANTS = { "glory", "union", "hail", "long live", "hooray", "hurray", "hurrah", "yay", "huzzah", "administrator", "breen", "overwatch", "combine", "thank", "bless", "cheer" }
local CHEER_SOUNDS = {
    "vo/coast/odessa/male01/nlo_cheer01.wav", "vo/coast/odessa/male01/nlo_cheer02.wav", "vo/coast/odessa/male01/nlo_cheer03.wav",
    "vo/coast/odessa/female01/nlo_cheer01.wav", "vo/coast/odessa/female01/nlo_cheer02.wav", "vo/npc/male01/yeah02.wav", "vo/npc/female01/yeah02.wav",
}
local GESTURE_CHEER = { cheer = 35, salute = 30, wave = 20, point = 10, nod = 8, bow = 15 }

function LC.ParadeCheer(ply, amount)
    local r = X and X.kind == "parade" and X.phase == "run" and X.people[ply]
    if not r then return false end
    r.cheer = math.min(100, r.cheer + amount)
    ply:SetNW2Float("lcx_cheer", r.cheer)
    return true
end

hook.Add("LivingCityGesture", "LivingCityExercise", function(ply, name)
    if X and X.kind == "parade" then LC.ParadeCheer(ply, GESTURE_CHEER[name] or 5) end
end)

-- Chanting: anything said counts a little, the right words more, yelling them most.
local function Chant(ply, text, yell)
    if not X or X.kind ~= "parade" or X.phase ~= "run" then return end
    local r = X.people[ply]
    if not r then return end
    local t = string.lower(string.Trim(text or ""))
    if string.sub(t, 1, 1) == "/" or string.sub(t, 1, 1) == "!" then
        if string.match(t, "^[/!]cheer") or string.match(t, "^[/!]salute") or string.match(t, "^[/!]wave") then return end -- (the gesture counts it)
        if string.match(t, "^/y%s") or string.match(t, "^/yell%s") then yell = true end
        t = string.gsub(t, "^[/!]%w+%s*", "")
    end
    if t == "" then return end
    -- (said once, heard once: the chat hook and the in-character one both see it)
    local now = CurTime()
    if r.chantText == t and now - (r.chantT or 0) < 1 then return end
    local n = 10
    for _, w in ipairs(CHANTS) do if string.find(t, w, 1, true) then n = 28 break end end
    if string.find(t, "!", 1, true) then n = n + 6 end
    if yell then n = n + 10 end
    if r.lastChant == t then n = math.floor(n / 2) end
    r.lastChant, r.chantText, r.chantT = t, t, now
    LC.ParadeCheer(ply, n)
end
LC.ParadeChant = Chant
hook.Add("PlayerSay", "LivingCityExerciseChant", function(ply, text) Chant(ply, text) end)
hook.Add("LivingCitySpoke", "LivingCityExercise", function(ply, kind, text)
    if kind == "say" or kind == "yell" then Chant(ply, text, kind == "yell") end
end)

local function ParadeThink(now, dt)
    -- where the column is
    local alive, done = 0, 0
    for _, u in ipairs(X.column) do
        local st = IsValid(u) and LC.NPCs[u]
        if st and st.exColumn then
            alive = alive + 1
            if st.exColumn.done then done = done + 1 end
        end
    end
    local function ColumnDist(pos)
        local best = math.huge
        for _, u in ipairs(X.column) do
            if IsValid(u) then best = math.min(best, u:GetPos():Distance(pos)) end
        end
        return best
    end
    for p, r in pairs(X.people) do
        if IsValid(p) and p:Alive() then
            local d = ColumnDist(p:GetPos())
            local near = d < 900
            r.cheer = math.max(0, r.cheer - (near and 6 or 1.5) * dt)
            p:SetNW2Float("lcx_cheer", r.cheer)
            if near then r.cheerSum, r.cheerN = r.cheerSum + r.cheer, r.cheerN + 1 end
            if d < 550 and r.cheer < cvParadeMin:GetFloat() then
                r.lowSince = r.lowSince or now
                if not r.warned or now - r.warned > 12 then
                    r.warned = now
                    Tell(p, "[Civil Protection] Show some enthusiasm, citizen.")
                end
                if now - r.lowSince > 3.5 then
                    r.why = "parade"
                    local units = {}
                    for _, u in ipairs(X.units) do units[#units + 1] = u end
                    if not SendUnit(units, p, "parade", 700) then
                        -- no guard near: a marcher steps out of line for it
                        for _, u in ipairs(X.column) do
                            if IsValid(u) and u:GetPos():DistToSqr(p:GetPos()) < 140 * 140 then
                                if LC.ExerciseBeat(u, p, "parade") then break end
                            end
                        end
                    end
                    if (p.lcxBeatNext or 0) > now + 2 then r.cheer, r.lowSince = 55, nil end
                end
            else
                r.lowSince = nil
            end
        end
    end
    -- the NPCs along the route cheer as it goes by
    for npc in pairs(X.npcs) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st and st.state == "event" and now > (st.exCheerNext or 0) and ColumnDist(npc:GetPos()) < 600 then
            st.exCheerNext = now + math.Rand(3, 6)
            local s = Pick(CHEER_SOUNDS)
            if file.Exists("sound/" .. s, "GAME") then npc:EmitSound(s, 72) end
            if LC.PlayGesture then LC.PlayGesture(npc, { "cheer1", "cheer2", "ACT_CHEER" }, 2) end
        end
    end
    if alive == 0 or done >= alive then
        X.paradeDone = X.paradeDone or now
        if now - X.paradeDone > 8 then LC.EndEvent(false) end
    end
end

------------------------------------------------------------------------
-- The clock
------------------------------------------------------------------------

local lastTick = 0
timer.Create("LivingCityExercise", 0.1, 0, function()
    local now = CurTime()
    -- boosts wear off
    for _, p in LC.Players() do
        if p.lcxBoost and now > p.lcxBoost.untilT then EndBoost(p) end
    end
    if not X then return end
    local ok, err = pcall(function()
        if not LC.Running or (LC.Event ~= X.kind) then return LC.ExerciseFinish() end
        local dt = math.Clamp(now - lastTick, 0, 0.5)
        lastTick = now
        if X.phase == "muster" then
            -- people arriving
            if now >= X.musterEnds then return StartRun(now) end
            for _, p in ipairs(player.GetAll()) do
                if not X.people[p] and not X.absent[p] and Eligible(p) then X.absent[p] = true p:SetNW2Bool("lcx_in", false) end
                if X.absent[p] and InArea(p) then X.absent[p] = nil X.people[p] = nil Join(p, false) end
            end
            return
        end
        ChaseThink(X.units, now)
        if (X.tick5 or 0) < now then
            X.tick5 = now + 0.5
            -- anyone who's become a citizen since it started (joined the server, or a new life) is
            -- expected too, and can join in
            for _, p in ipairs(player.GetAll()) do
                if not X.people[p] and not X.absent[p] and Eligible(p) and p.lcxSeen ~= X then
                    p.lcxSeen = X
                    X.absent[p] = true
                    p:SetNW2Bool("lcx_in", false)
                end
            end
            Truants(now)
        end
        if X.kind == "jog" then JogThink(now)
        elseif X.kind == "drill" then DrillThink(now)
        else ParadeThink(now, dt) end
    end)
    if not ok then LC.Error("exercise", err) end
end)

------------------------------------------------------------------------
-- Afterwards
------------------------------------------------------------------------

local function Breakfast(p, r)
    if not cvBreakfast:GetBool() or not LCS or not LCS.TierFor or not LC.Feed then return end
    local s = LC.Standing and LC.Standing(p) or 0
    if s >= 400 then
        LC.Feed(p, 50, 25)
        p:ChatPrint("[Union] Exemplary citizens are served first: a hot breakfast, and coffee. You feel well fed.")
    elseif s >= 150 then
        LC.Feed(p, 35, 20)
        p:ChatPrint("[Union] For citizens of good standing: breakfast.")
    else
        p:ChatPrint("[Union] Rations are issued at the usual distribution. Breakfast is for citizens of good standing.")
    end
end

function LC.ExerciseFinish()
    if not X then return end
    local x = X
    local kind = x.kind
    -- standing: for doing it, and doing it well
    for p, r in pairs(x.people) do
        if IsValid(p) then
            local gain
            if kind == "jog" then
                gain = r.done and (r.beatings == 0 and 10 or 5) or 0
                if not r.done then Tell(p, "You didn't finish.") end
            elseif kind == "drill" then
                gain = (r.total <= 2 and r.beatings == 0) and 10 or (r.beatings == 0 and 5 or 2)
            else
                local avg = r.cheerN > 0 and r.cheerSum / r.cheerN or r.cheer
                gain = avg >= 60 and 10 or (avg >= cvParadeMin:GetFloat() and 4 or -5)
            end
            if r.late then gain = math.min(gain, 2) end
            if gain ~= 0 and LC.AddStanding then LC.AddStanding(p, gain, gain > 0 and NAMES[kind] or "Poor showing at the " .. string.lower(NAMES[kind])) end
            -- said plainly, on screen: what it earned (the owner: a small reward for doing it)
            local pay = (gain > 0 and Eligible(p)) and math.max(0, cvPay:GetInt()) or 0
            if pay > 0 and LC.AddCredits then LC.AddCredits(p, pay, "morning exercise") end
            if LC.Notice and gain ~= 0 then
                LC.Notice(p, gain > 0 and "info" or "warn", NAMES[kind], gain > 0
                    and string.format("Done. %+d Civil Standing%s.", gain, pay > 0 and string.format(" and %d credits", pay) or "")
                    or string.format("A poor showing: %d Civil Standing.", gain), 8)
            end
            if gain >= 0 then Breakfast(p, r) end
        end
    end
    if IsValid(x.leader) and LC.AddStanding then LC.AddStanding(x.leader, 10, "Led the morning drill") end
    for p in pairs(x.absent) do
        if IsValid(p) and Eligible(p) and LC.AddStanding then
            LC.AddStanding(p, -10, "Skipped morning exercise")
            -- and a reprimand they can't miss: their next ration is withheld (sv_livingcity_survival.lua)
            if cvSkipRation:GetBool() then p.lcRationWithheld = "you skipped morning exercise" end
            if LC.Notice then
                LC.Notice(p, "warn", "Reprimand", "You skipped morning exercise: -10 Civil Standing" .. (cvSkipRation:GetBool() and ", and your next ration is withheld." or "."), 10)
            end
        end
    end
    -- everyone back to normal
    for _, u in ipairs(x.units) do Unpost(u) end
    for _, u in ipairs(x.column) do Unpost(u) end
    X = x
    ReleaseCitizens()
    X = nil
    if IsValid(x.instructor) then
        local npc = x.instructor
        local st = LC.NPCs[npc]
        if st then st.unmanaged, st.questLock, st.eventUntil = nil, nil, 0 st.leaveAt = CurTime() end
    end
    for _, p in ipairs(player.GetAll()) do
        p:SetNW2Bool("lcx_in", false)
        p:SetNW2Bool("lcx_leader", false)
        p:SetNW2Bool("lcx_behind", false)
        p:SetNW2Float("lcx_lag", 0)
        p:SetNW2Int("lcx_mistakes", 0)
        p:SetNW2Float("lcx_cheer", 0)
        p:SetNW2Int("lcx_cp", 0)
        p.lcxTruantN, p.lcxTruantNext, p.lcxSpin, p.lcxYaw = nil, nil, nil, nil
    end
    Send()
    hook.Run("LivingCityExerciseEnded", kind, x)
end

hook.Add("LivingCityEventStarted", "LivingCityExercise", function(name)
    if LC.ExerciseKinds[name] then LC.ExerciseBegin(name) elseif X then LC.ExerciseFinish() end
end)
hook.Add("LivingCityEventEnded", "LivingCityExercise", function(was)
    if X and was == X.kind then LC.ExerciseFinish() end
end)
hook.Add("PlayerInitialSpawn", "LivingCityExercise", function(ply)
    timer.Simple(5, function() if IsValid(ply) and X then Send(ply) end end)
end)
hook.Add("PlayerSpawn", "LivingCityExercise", function(ply) ply.lcxBoost = nil ply:SetNW2Float("lcx_boost", 0) end)
hook.Add("PlayerDisconnected", "LivingCityExercise", function(ply)
    if X then X.people[ply] = nil X.absent[ply] = nil if X.leader == ply then X.leader = nil end end
end)

-- What it means, for the person reading the announcement (sv_livingcity_events.lua).
function LC.ExerciseMeans(kind, ply)
    local where = X and Where(X.center) or "the assembly point"
    local secs = X and math.max(0, math.floor(X.musterEnds - CurTime())) or 60
    if LC.PlayerIsCP(ply) then
        return NAMES[kind] .. ": citizens report " .. where .. " within " .. secs .. " seconds. Civil Protection units are posted automatically; anyone shirking gets the stick."
    end
    if not Eligible(ply) then return NAMES[kind] .. " for citizens, " .. where .. "." end
    if kind == "jog" then
        return "Report to the start of the jogging route, " .. where .. ", within " .. secs .. " seconds (your HUD points the way). Then run it: " ..
            "keep jogging and keep up with the pace marker, or Civil Protection units along the route use the stick (which does speed you up)."
    elseif kind == "drill" then
        return "Report to the exercise yard, " .. where .. ", within " .. secs .. " seconds. Take your place in the rows and copy every move " ..
            "(crouch, jump, spin, a step); jump on every beat when the rope comes out. Too many mistakes and you get the stick."
    end
    return "Line the parade route, " .. where .. ", within " .. secs .. " seconds, and cheer the column as it passes: /cheer, /salute, " ..
        "chant in chat, jump. Your enthusiasm is on screen; let it drop as they pass and a Civil Protection unit sees to it."
end

------------------------------------------------------------------------
-- The mornings
------------------------------------------------------------------------

local dawns, rotation = 0, 0
local function Kinds()
    local out = {}
    for k in string.gmatch(string.lower(cvKinds:GetString() or ""), "[%a_]+") do
        if LC.ExerciseKinds[k] then out[#out + 1] = k end
    end
    return out
end

-- The next one in turn that this map has the points for.
function LC.NextExercise(advance)
    local kinds = Kinds()
    for i = 1, #kinds do
        local k = kinds[(rotation + i - 1) % #kinds + 1]
        if LC.ExerciseReady(k) then
            if advance then rotation = (rotation + i) % #kinds end
            return k
        end
    end
    return nil
end

function LC.TryMorningExercise()
    if not cvOn:GetBool() or not LC.Running or X then return false end
    if LC.Event then
        if LC.Event == "curfew" or LC.Event == "lockdown" or LC.Event == "raid" then return false, "busy" end
        return false, "wait"
    end
    local k = LC.NextExercise(true)
    if not k then return false, "none" end
    return LC.StartEvent(k), k
end

hook.Add("LivingCityDayPhase", "LivingCityExercise", function(phase)
    if phase ~= "dawn" or not cvOn:GetBool() then return end
    dawns = dawns + 1
    if (dawns - 1) % math.max(1, cvEvery:GetInt()) ~= 0 then return end
    -- now, or as soon as whatever's on (rations, an inspection) is over, while it's still morning
    local tries = 0
    timer.Create("LivingCityExerciseMorning", 5, 60, function()
        tries = tries + 1
        local ok, why = LC.TryMorningExercise()
        if ok or why == "busy" or why == "none" or (LC.DayPhase and LC.DayPhase() ~= "dawn" and tries > 1) then
            timer.Remove("LivingCityExerciseMorning")
        end
    end)
end)

------------------------------------------------------------------------
-- A full stomach
------------------------------------------------------------------------

function LC.FullStomach(ply)
    if not cvFull:GetBool() or not IsValid(ply) or not LC.Hunger then return false end
    local needs = GetConVar("lc_needs")
    if needs and not needs:GetBool() then return false end -- (nobody eats: nobody's full)
    local f = ply:GetNW2String("lcf_faction", "")
    if f == "ota" or f == "zombie" or f == "stalker" then return false end -- (they don't eat)
    return LC.Hunger(ply) >= 85
end

-- jobs and shifts pay 15% more XP on a full stomach (sv_livingcity_quests.lua)
function LC.FullStomachXP(ply, xp)
    if xp > 0 and LC.FullStomach(ply) then return math.floor(xp * 1.15 + 0.5) end
    return xp
end

timer.Create("LivingCityFullStomach", 10, 0, function()
    if not cvFull:GetBool() then return end
    for _, p in ipairs(player.GetAll()) do
        local full = p:Alive() and LC.FullStomach(p)
        if full and not p.lcxFull then p:ChatPrint("You're well fed. Work goes better on a full stomach (+15% XP).") end
        p.lcxFull = full
    end
end)
hook.Add("EntityTakeDamage", "LivingCityFullStomach", function(ent)
    if IsValid(ent) and ent:IsPlayer() then ent.lcxHurtT = CurTime() end
end)

------------------------------------------------------------------------
-- For the admin
------------------------------------------------------------------------

concommand.Add("lc_exercise", function(ply, _, args)
    if IsValid(ply) and not LC.CanEdit(ply) then return end
    local function Reply(m) if IsValid(ply) then ply:ChatPrint("[Living City] " .. m) else print("[Living City] " .. m) end end
    local a = string.lower(tostring(args[1] or ""))
    if a == "stop" then
        if X then LC.EndEvent(false) Reply("Exercise stopped.") else Reply("No exercise on.") end
        return
    end
    if a == "next" or a == "" then
        local k = LC.NextExercise(false)
        Reply("Next morning exercise: " .. (k and NAMES[k] or "none (place a jogging route, an exercise yard or a parade route)") ..
            ". Every " .. math.max(1, cvEvery:GetInt()) .. " morning(s), at dawn. lc_exercise <jog|drill|parade> starts one now.")
        return
    end
    if not LC.ExerciseKinds[a] then Reply("lc_exercise <jog|drill|parade|next|stop>") return end
    if not LC.Running then Reply("Start the city first.") return end
    if not LC.ExerciseReady(a) then
        Reply(a == "drill" and "Place an exercise yard first (editor: Point: exercise yard)."
            or ("Place a " .. (a == "jog" and "jogging route" or "parade route") .. " first (two or more stops, in order)."))
        return
    end
    if LC.StartEvent(a) then Reply(NAMES[a] .. " started.") else Reply("Couldn't start it.") end
end)
