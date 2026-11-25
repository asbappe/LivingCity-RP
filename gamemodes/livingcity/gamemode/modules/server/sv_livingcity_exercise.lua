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

      drill   The morning drill. At the start of the jogging route (the leader
              stands there, the rows in front of it, the way the point faces),
              or at an exercise yard if one is placed ("Point: exercise yard",
              optional: where the leader stands). Everyone gets a place in rows in front of the leader and
              copies the leader's moves: crouch, jump, spin, step left, right,
              forward or back. The leader is a player Clinic Medic or Records
              Clerk if one is there (their own moves are called out), or else a
              Union fitness instructor calls them. Halfway through: skipping, a
              rope turned to a beat (jump on every beat). Too many mistakes
              (lc_drill_mistakes), wandering out of your place, and a unit at
              the edge of the yard steps in with the stick.

      parade  The morning parade. A column of Overwatch soldiers, two abreast,
              with an APC, a pair of hunters and a strider behind them, marches
              a route ("Point: parade route stop", in order). A third of the way
              along, the Combine march plays from the column (lc_parade_music).
              Every citizen NPC lines the middle third and cheers. Players line
              it and cheer: /cheer, /salute, /wave, chanting in chat ("Glory to
              the Union!"), jumping up and down. Enthusiasm is a meter on screen
              that drains while the column is near; let it drop too low as it
              passes, and a unit sees to it. Nobody in the parade harms anyone
              but whoever attacks it: then it stops and fights them, and forms
              up again at the last route point it had reached.

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
util.AddNetworkString("lc_parade_music")

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_morning_exercise", "1", FLAGS, "Morning exercise for citizens (a jog, a drill or a parade at dawn)")
local cvEvery    = CreateConVar("lc_exercise_every", "2", FLAGS, "Hold morning exercise every this many mornings (1: every morning)")
local cvKinds    = CreateConVar("lc_exercise_kinds", "jog,drill,parade", FLAGS, "Which morning exercises take turns (jog, drill, parade)")
local cvMuster   = CreateConVar("lc_exercise_muster", "75", FLAGS, "Seconds citizens have to report for morning exercise")
local cvBeat     = CreateConVar("lc_exercise_beat_dmg", "8", FLAGS, "Damage from one blow with the stick at morning exercise (never takes you below 15 health)")
local cvPay       = CreateConVar("lc_exercise_pay", "5", FLAGS, "Credits a citizen is paid for finishing morning exercise well (0: none)")
local cvSkipRation = CreateConVar("lc_exercise_skip_ration", "1", FLAGS, "A citizen who skips morning exercise has their next ration withheld")
local cvBreakfast = CreateConVar("lc_exercise_breakfast", "1", FLAGS, "After morning exercise, citizens of good standing (Trusted and up) get breakfast")
local cvNPCs     = CreateConVar("lc_exercise_npcs", "0", FLAGS, "The most NPC citizens taking part in morning exercise (0: every one of the city's own; they come whatever they are doing, and by day those at home come out)")
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
local cvParadeN  = CreateConVar("lc_parade_units", "6", FLAGS, "Soldiers marching in the parade column, two abreast (never fewer than 8)")
local cvParadeMin = CreateConVar("lc_parade_min", "35", FLAGS, "Enthusiasm below this as the column passes earns the stick")
local cvMachines = CreateConVar("lc_parade_machines", "1", FLAGS, "An APC and a strider follow the parade's column")
local cvMusic    = CreateConVar("lc_parade_music", "music/hl2_song22_combinetheme3.mp3", FLAGS, "The march played from the parade's column once it is a third of the way along (a sound path; empty: none)")
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

-- The drill's yard: an exercise yard point if one is placed, else the start of each jogging route (the owner,
-- 13 November: "just make the jogging start point into the exercise yard point, they can be the same").
local function Yards()
    local out = {}
    for _, p in ipairs(LC.Points or {}) do if p.kind == "yard" then out[#out + 1] = p end end
    if #out == 0 then
        for _, r in ipairs(Routes("jogroute")) do out[#out + 1] = r[1] end
    end
    return out
end
LC.ExerciseYards = Yards

-- The morning jog is archived (the owner, 13 November: "it's time to archive the morning jog; please
-- disable it ... Remove all jog paths/points please and remove it from the schedule in the gamemode.
-- it's just kind of odd and awkward when played on the server"). Its code stays, behind lc_jog (0):
-- with it off the jog is never held, by the schedule or by hand, and a layout's jogging routes are
-- taken out as it loads, each route's start kept as an exercise yard (sv_livingcity_data.lua).
local cvJog = CreateConVar("lc_jog", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "The morning jog (archived 13 November): 0 never held and jogging routes are removed from the layout as it loads, 1 as it was")
function LC.JogOn() return cvJog:GetBool() end

function LC.ExerciseReady(kind)
    if kind == "jog" then return cvJog:GetBool() and #Routes("jogroute") > 0 end
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
-- maxDist: a free unit further from its post than this is left where it is and a fresh one comes
-- instead (the parade: a column drafted from across the city never formed up; the owner, 14 November,
-- "I ordered a parade and nothing happened").
-- opt.only: nobody of another kind is drafted (the parade's column is soldiers: a fresh one comes rather than
-- a unit off the street). opt.free: fresh ones come whatever Overwatch's reserve says (LC.ManpowerFree, as the
-- Administrator's guards do): with the reserve low the column came out three strong (the owner, 15 November,
-- "right now there are just 3 soldiers walking the route"); if no soldier can come at all, a unit does.
local function Post(posts, prefer, maxDist, opt)
    opt = opt or {}
    local pool = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if Free(npc, st) and not (opt.only and st.role ~= prefer) then pool[#pool + 1] = { npc = npc, st = st } end
    end
    local units = {}
    for pi, post in ipairs(posts) do
        local best, bi
        for i, u in ipairs(pool) do
            local raw = u.npc:GetPos():DistToSqr(post)
            if not maxDist or raw <= maxDist * maxDist then
                local d = raw * ((prefer and u.st.role ~= prefer) and 4 or 1)
                if not best or d < best then best, bi = d, i end
            end
        end
        local npc, st
        if bi then
            npc, st = pool[bi].npc, pool[bi].st
            table.remove(pool, bi)
        else
            local from = LC.AlarmSquadSpot and LC.AlarmSquadSpot(post) or post
            local first = LC.Spawners and (LC.Spawners[prefer or "cop"] or LC.Spawners.cop)
            for _, sp in ipairs({ first, opt.only and LC.Spawners and LC.Spawners.cop or nil }) do
                local ok, n, s
                if opt.free and LC.ManpowerFree then ok, n, s = LC.Try(LC.ManpowerFree, sp, from) else ok, n, s = LC.Try(sp, from) end
                if ok and IsValid(n) and s then npc, st = n, s st.unmanaged = true st.exTemp = true break end
            end
        end
        if npc then
            st.exPostI = pi
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

local function Unpost(npc, walkOff)
    local st = IsValid(npc) and LC.NPCs and LC.NPCs[npc]
    if not st then return end
    if st.exColumn then st.marching, st.provokedBy, st.provokedUntil, npc.lcParade = nil, nil, nil, nil end -- (no longer of the parade)
    st.exUnit, st.holdPos, st.exChase, st.exColumn, st.exNext, st.exPostI = nil, nil, nil, nil, nil, nil
    st.nextInspect = CurTime() + math.Rand(20, 50)
    if st.state == "event" then LC.SetState(npc, st, "idle") st.untilT = CurTime() + 2 end
    if st.exTemp then
        -- the extra ones go back where they came from, once nobody's looking (the parade's column
        -- marches off out of sight first, rather than standing about where the route ends)
        if walkOff and st.state ~= "hostile" then
            local to = LC.AlarmSquadSpot and LC.AlarmSquadSpot(npc:GetPos())
            if to and LC.GoTo then LC.GoTo(npc, st, to, false, nil) end
        end
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
local HIT = { jog = "Keep up, citizen.", drill = "Do it properly.", parade = "Louder, citizen. With feeling.", absent = "Exercise is mandatory.", speech = "The Administrator is speaking. Attendance is mandatory." }

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
    if dmg > 0 then
        LC.ExerciseStick = true -- (the stick is the stick, a marcher's too: the parade's own rule on what it harms lets it by)
        local okS, errS = LC.Try(ply.TakeDamage, ply, dmg, IsValid(npc) and npc or nil, IsValid(npc) and npc or nil)
        LC.ExerciseStick = nil
        if not okS then LC.Error("exercise stick", errS) end
    end
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

-- Who can be called to it (the owner, 15 November, at the drill: "no one is partaking ... all the citizens are
-- just mosying around"). Only those idle or walking about used to be asked, once, at the start: at dawn nearly
-- everyone is in bed, sitting somewhere, in a line or at a job, so nobody came. Now a citizen of the city's own
-- comes whatever they are doing (by day out of bed too; at night nobody is taken out of bed), and the city keeps
-- asking while it is on, so those up later come too. Not one in a job of a player's, on the way home, held,
-- fighting, or already in something scripted.
local DRAFT = { idle = true, moving = true, busy = true, inline = true, working = true }
local function Draftable(npc, st, wake)
    if not IsValid(npc) or st.role ~= "citizen" or st.test or st.unmanaged or st.questLock or st.leaving or st.exCitizen then return false end
    if st.jailUntil or (X and st.exDone == X) then return false end -- (a prisoner; someone the parade has already let go)
    if st.carry and not st.npcWork then return false end
    if st.state == "abed" then return wake == true end
    return DRAFT[st.state] == true
end
LC.ExerciseDraftable = Draftable

-- Whatever they were doing, they drop it.
local function CallAway(npc, st)
    if st.state == "abed" and LC.NPCBedUp then LC.NPCBedUp(npc, st) end
    if st.state == "busy" and LC.EndBusy then LC.EndBusy(npc, st, false) end
    if st.line and LC.LeaveLine then LC.LeaveLine(npc, st) end
    if st.npcWork and LC.NPCWorkReset then LC.NPCWorkReset(npc, st) end
    if LC.Release then LC.Release(npc, st) end
end

LC.ExerciseCallAway = CallAway -- (her address and the ration line call people the same way)

-- How many of the city's own take part at the most: lc_exercise_npcs, or (0, the default) every one of them
-- (the owner, 15 November: "please make sure all the citizen NPCs show up").
local function Cap()
    local n = cvNPCs:GetInt()
    return n > 0 and n or math.huge
end

-- n: how many in all; poiFor(i): the i-th one's place and { yaw }. most: by day those at home are free to
-- come out for it too (LC.PeopleCallOut), and up to this many of them do at this ask, from a doorway out of
-- sight near by (always one of the city's own people, never a nameless extra).
local function EnlistCitizens(n, poiFor, most)
    X.enlisted = X.enlisted or 0
    local wake = not (LC.DayPhase and LC.DayPhase() == "night")
    local cands = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if not X.npcs[npc] and Draftable(npc, st, wake) then
            cands[#cands + 1] = { npc = npc, st = st, d = X.center and npc:GetPos():DistToSqr(X.center) or 0 }
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    local function Send(npc, st, pos, data, far)
        if not (LC.GoTo and LC.GoTo(npc, st, pos, X.kind == "jog" or far, { kind = "exercise", pos = pos, yaw = data and data.yaw })) then return false end
        data = data or {}
        data.spot = pos
        st.exCitizen = data
        X.npcs[npc] = true
        X.enlisted = X.enlisted + 1
        return true
    end
    for _, c in ipairs(cands) do
        if X.enlisted >= n then break end
        local pos, data = poiFor(X.enlisted + 1, c.npc)
        if not pos then break end
        local was = c.st.state
        CallAway(c.npc, c.st)
        if not Send(c.npc, c.st, pos, data, c.d > 1500 * 1500) and was ~= "idle" and was ~= "moving" then
            LC.SetState(c.npc, c.st, "idle")
            c.st.untilT = CurTime() + 2
        end
    end
    if not most or most <= 0 or not wake then return end
    local sp = LC.Spawners and LC.Spawners.citizen
    if not (sp and LC.PersonAvailable and LC.AlarmSquadSpot) then return end
    if LC.PeopleCallOut then LC.PeopleCallOut("citizen") end
    local came = 0
    while came < most and X.enlisted < n and LC.PersonAvailable("citizen") do
        local pos, data = poiFor(X.enlisted + 1)
        if not pos then break end
        local from = LC.AlarmSquadSpot(pos)
        if not from then break end
        local ok, npc, st = LC.Try(sp, from)
        if not (ok and IsValid(npc) and st) then break end
        came = came + 1
        if Send(npc, st, pos, data, true) then st.exTemp = true end
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

-- Where a marcher of the parade's column goes for the stop he is on: his own file, to the side of the way
-- in to it; at the last stop each rank halts a little short of the one in front.
local function ColumnStop(col)
    local i = col.i
    local dir = i > 1 and Flat(X.route[i] - X.route[i - 1]) or Vector(X.dir1.x, X.dir1.y, 0)
    if dir:LengthSqr() < 0.01 then dir = Vector(X.dir1.x, X.dir1.y, 0) end
    dir:Normalize()
    local at = X.route[i] + Vector(-dir.y, dir.x, 0) * (col.side or 0)
    if i == #X.route then
        at = at - dir * ((col.rank or 0) * 50)
        col.yaw = dir:Angle().y
    end
    return at
end

-- An NPC arriving somewhere for the exercise (sv_livingcity.lua's Arrive hands them over).
function LC.ExerciseArrive(npc, st, now)
    local c = st.exCitizen
    if st.exColumn and X and X.kind == "parade" then
        local col = st.exColumn
        if col.forming then
            -- back at his place after a fight: he stands there until the rest are formed up (ReformThink)
            col.formed = true
            LC.SetState(npc, st, "event") st.eventUntil = now + 600
            if col.yaw then LC.FaceYaw(npc, col.yaw) end
            return
        end
        -- the column: on to the next stop of the route
        repeat
            col.i = col.i + 1
            if col.i > #X.route then
                col.done = true
                LC.SetState(npc, st, "event") st.eventUntil = now + 600
                if col.yaw then LC.FaceYaw(npc, col.yaw) end
                return
            end
        until LC.GoTo(npc, st, ColumnStop(col), col.run == true, { kind = "exercise" })
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
    EnlistCitizens(Cap(), function(i)
        return route[1] + Vector(math.Rand(-120, 120), math.Rand(-120, 120), 0), { i = 1 }
    end, 6)
end

-- The drill's places: eight rows of five in front of the leader (1 to 40, as ever), and three more to either
-- side of each row (41 to 88) so there is room for a whole city, not ten.
local DRILL_SPOTS = 88
local function DrillSpot(i)
    local y = X.yard
    local fwd, right = Angle(0, y.yaw, 0):Forward(), Angle(0, y.yaw, 0):Right()
    local row, col = math.floor((i - 1) / 5), (i - 1) % 5 - 2
    if i > 40 then
        local k = i - 41
        row = math.floor(k / 6)
        col = k % 6
        col = col < 3 and (col - 5) or col
    end
    return Ground(y.pos + fwd * (220 + row * 100) + right * (col * 100))
end

local function SetupDrill()
    X.yard = Pick(Yards())
    X.center = X.yard.pos
    X.radius = 900
    X.spots, X.taken = {}, {}
    for i = 1, DRILL_SPOTS do X.spots[i] = DrillSpot(i) end
    local fwd, right = Angle(0, X.yard.yaw, 0):Forward(), Angle(0, X.yard.yaw, 0):Right()
    -- units at the edges of the yard (outside the rows, now that they are wider), and one behind the back row
    X.units = Post({ X.yard.pos + fwd * 300 + right * 600, X.yard.pos + fwd * 300 - right * 600, X.yard.pos + fwd * 1020 }, "cop")
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
    -- the city's own take the back rows (the players get the front): the last free place each
    X.drillPoi = function()
        for k = #X.spots, 1, -1 do
            if not X.taken[k] then X.taken[k] = true return X.spots[k], { yaw = X.yard.yaw + 180 } end
        end
    end
    EnlistCitizens(Cap(), X.drillPoi, 6)
    X.enlistNext = CurTime() + 4
end

local COLUMN_REACH, GUARD_REACH = 1500, 1800 -- how far a free unit may be from its post to be drafted

-- The route to march: any of them, or (a parade someone ordered: LC.ExerciseNear, where they stand)
-- the one that starts nearest to them.
local function ParadeRoute()
    local routes = Routes("parade")
    local near = LC.ExerciseNear
    if not near then return Pick(routes) end
    local best, bd
    for _, r in ipairs(routes) do
        local d = r[1].pos:DistToSqr(near)
        if not bd or d < bd then best, bd = r, d end
    end
    return best
end

-- The parade (the owner, 15 November: "please make a parade out of marching soldiers, an APC, and a strider
-- all marching along the path ... when it passes the first 1/3 of the route, have the combine march music play
-- emanating from the parade marchers ... I want ALL the citizens to drop what they are doing and get their
-- fannies to the parade, between the 1/3 mark and 2/3 mark, and cheer their hearts out").
--
-- X.head is how far along the route the front rank is (less than nothing: still behind the first stop). The
-- soldiers walk the route themselves, stop to stop, in two files; the APC and the strider keep their places
-- behind the last rank by X.head (X.machines, MachinesStep).
local RANK_GAP, FILE_OFF = 70, 40            -- ranks this far apart, the two files this far either side of the way
local APC_BEHIND, STRIDER_BEHIND = 240, 380  -- the APC behind the last rank, the strider behind the APC
local MARCH_PACE = 75                        -- units a second, with nobody left marching to set the pace
local CROWD_BACK, CROWD_APART = 170, 56      -- the crowd: this far back from the way, this far from each other
local APC_MODEL = "models/combine_apc.mdl"
local APC_SOUNDS = { "vehicles/apc/apc_cruise_loop3.wav", "vehicles/apc/apc_firstgear_loop1.wav", "vehicles/apc/apc_idle1.wav" }
local APC_WHEELS = { "vehicle_wheel_fl_spin", "vehicle_wheel_fr_spin", "vehicle_wheel_rl_spin", "vehicle_wheel_rr_spin" }
LC.ParadeLeftovers = LC.ParadeLeftovers or {} -- machines of a parade that is over, waiting to go unseen

-- A spot this far along the parade (before the first stop: back along the way the first stretch runs), and
-- the way the route runs there.
local function ParadeAt(d)
    if d <= 0 then return X.route[1] + X.dir1 * d, X.dir1 end
    return AlongRoute(X.route, X.cum, d)
end
-- How far along it a spot is (behind the first stop: less than nothing), and how far to the side of it.
local function ParadeAlong(pos)
    local off, along = OnRoute(X.route, X.cum, pos)
    if along <= 0 then
        local rel = Flat(pos - X.route[1])
        along = math.min(0, rel:Dot(X.dir1))
        off = (rel - X.dir1 * rel:Dot(X.dir1)):Length()
    end
    return along, off
end
local function YawOf(dir) return math.deg(math.atan2(dir.y, dir.x)) end

-- The march, as paths to try in order: the setting, the Combine march Half-Life 2 ships and never plays, and a
-- piece every copy has. Each player's game plays the first it finds (cl_livingcity_exercise.lua) and says which.
LC.ParadeMusicDefault, LC.ParadeMusicSure = "music/hl2_song22_combinetheme3.mp3", "music/hl2_song20_submix0.mp3"
local function MusicList()
    local own = string.lower(string.Trim(cvMusic:GetString()))
    local out, seen = {}, {}
    if own == "" then return out end -- (the setting emptied: no march)
    for _, p in ipairs({ own, LC.ParadeMusicDefault, LC.ParadeMusicSure }) do
        if not seen[p] then seen[p] = true out[#out + 1] = p end
    end
    return out
end
LC.ParadeMusicList = MusicList
local function MusicStop()
    SetGlobal2String("lc_parade_music", "")
    SetGlobal2Float("lc_parade_music_at", 0)
end
MusicStop() -- (nothing is playing as the gamemode loads)

local function RemoveMachine(m)
    if m.patch then LC.Try(function() m.patch:Stop() end) m.patch = nil end
    if IsValid(m.ent) then m.ent:Remove() end
end
-- The machines of a parade that is over go when nobody is looking at them (after a minute, anyway).
local function DismissMachines(list)
    for _, m in ipairs(list or {}) do
        if m.patch then LC.Try(function() m.patch:Stop() end) m.patch = nil end -- (the engine is cut at once)
        if IsValid(m.ent) then LC.ParadeLeftovers[#LC.ParadeLeftovers + 1] = m end
    end
    local tries = 0
    timer.Create("LivingCityParadeMachines", 3, 21, function()
        tries = tries + 1
        for i = #LC.ParadeLeftovers, 1, -1 do
            local m = LC.ParadeLeftovers[i]
            if not IsValid(m.ent) or tries >= 20 or not (LC.IsSeen and LC.IsSeen(m.ent:GetPos() + Vector(0, 0, 40))) then
                RemoveMachine(m)
                table.remove(LC.ParadeLeftovers, i)
            end
        end
        if #LC.ParadeLeftovers == 0 then timer.Remove("LivingCityParadeMachines") end
    end)
end
local function ClearLeftovers()
    for _, m in ipairs(LC.ParadeLeftovers) do RemoveMachine(m) end
    LC.ParadeLeftovers = {}
    timer.Remove("LivingCityParadeMachines")
end

-- The APC: a model rolled along the route by MachinesStep (nobody drives it, nothing can stop it; people walk
-- through it rather than being run down, but it can be shot at, and its gun answers: TurretStep). The strider
-- and the pair of hunters: real ones, so they stand and walk as they do. None of them is anyone's enemy, and
-- nobody's enemy is any of them, until someone attacks the parade.
function LC.ParadeCanHunters() -- (Episode Two's: never an error model where it is not installed)
    return util.IsValidModel ~= nil and util.IsValidModel("models/hunter.mdl") == true
end
local WALKER_NEUTRAL = { "player", "npc_citizen", "npc_vortigaunt", "npc_alyx", "npc_barney", "npc_monk", "npc_kleiner", "npc_eli", "npc_mossman" }
local function SpawnWalker(class, kind, off, side)
    local e = ents.Create(class)
    if not IsValid(e) then return nil end
    local d = X.head - off
    local pos, dir = ParadeAt(d)
    local f = Flat(dir)
    f:Normalize()
    local ground = Ground(pos + Vector(-f.y, f.x, 0) * (side or 0) + Vector(0, 0, 30))
    e:SetPos(ground + Vector(0, 0, 8)) -- (a strider finds its own height above the ground as it spawns)
    e:SetAngles(Angle(0, YawOf(dir), 0))
    e:SetKeyValue("spawnflags", tostring(SF_NPC_FADE_CORPSE or 512))
    e:Spawn()
    e:Activate()
    for _, cls in ipairs(WALKER_NEUTRAL) do e:AddRelationship(cls .. " D_NU 99") end
    for _, p in ipairs(player.GetAll()) do e:AddEntityRelationship(p, D_NU, 99) end
    e.lcParade = true
    X.machines[#X.machines + 1] = { kind = kind, ent = e, off = off, side = side, d = d, yaw = YawOf(dir), ground0 = ground }
    return e
end
local function SpawnMachines()
    X.machines = {}
    if not cvMachines:GetBool() then return end
    local up = Vector(0, 0, 30)
    local ok, err = LC.Try(function()
        if util.IsValidModel and not util.IsValidModel(APC_MODEL) then return end
        local e = ents.Create("prop_dynamic")
        if not IsValid(e) then return end
        local d = X.head - X.offApc
        local pos, dir = ParadeAt(d)
        e:SetModel(APC_MODEL)
        e:SetPos(Ground(pos + up))
        e:SetKeyValue("solid", "6")
        e:Spawn()
        e:Activate()
        if not IsValid(e) then return end
        e:SetCollisionGroup(COLLISION_GROUP_WEAPON or 11) -- (shots hit it; people and units pass through)
        -- its wheels on the ground and its nose to the front, whichever way the model was built (a
        -- vehicle's length runs along its own Y)
        local mins, maxs = e:OBBMins(), e:OBBMaxs()
        local m = { kind = "apc", ent = e, off = X.offApc, d = d, lift = -mins.z, turn = ((maxs.y - mins.y) > (maxs.x - mins.x)) and -90 or 0 }
        m.yaw = YawOf(dir)
        e:SetPos(Ground(pos + up) + Vector(0, 0, m.lift))
        e:SetAngles(Angle(0, m.yaw + m.turn, 0))
        e.lcParade = true
        if CreateSound then
            for _, s in ipairs(APC_SOUNDS) do
                if file.Exists("sound/" .. s, "GAME") then
                    m.patch = CreateSound(e, s)
                    if m.patch then m.patch:SetSoundLevel(80) m.patch:PlayEx(0.25, 90) end
                    break
                end
            end
        end
        X.machines[#X.machines + 1] = m
    end)
    if not ok then LC.Error("parade APC", err) end
    -- the pair of hunters, either side of the way between the APC and the strider
    if LC.ParadeCanHunters() then
        local got = 0
        for _, side in ipairs({ -90, 90 }) do
            ok, err = LC.Try(function() if SpawnWalker("npc_hunter", "hunter", X.offHunters, side) then got = got + 1 end end)
            if not ok then LC.Error("parade hunter", err) end
        end
        if got < 2 then LC.Log("warn", "The parade has " .. got .. " of its 2 hunters: npc_hunter could not be made here") end
    else
        LC.Log("info", "The parade goes without its hunters: this server has no models/hunter.mdl (Episode Two is not mounted)")
    end
    ok, err = LC.Try(function()
        local e = SpawnWalker("npc_strider", "strider", X.offStrider, nil)
        if not e then return end
        e:Fire("DisableMinigun")
        e:Fire("DisableAggressiveBehavior")
        e.lcParadeStrider = true
        X.strider = e
    end)
    if not ok then LC.Error("parade strider", err) end
end

-- Nobody in the city takes the strider or the hunters for an enemy either (a citizen who did would cower
-- or run instead of cheering; a unit never does anyway). The Resistance's own are left as they are.
local function WalkersAreFriends()
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.role == "citizen" and st.exFriends ~= X.start then
            st.exFriends = X.start
            for _, m in ipairs(X.machines or {}) do
                if m.kind ~= "apc" and IsValid(m.ent) then npc:AddEntityRelationship(m.ent, D_NU, 99) end
            end
        end
    end
end

-- The crowd's places: both sides of the middle third of the route, spread along it (not filled from one end),
-- a few steps back and facing the way; a second row behind when the first is full.
local function CrowdPlaces()
    local third = X.total / 3
    local per = math.max(1, math.floor(third / CROWD_APART))
    local order = {}
    for i = 1, per do order[i] = i end
    table.sort(order, function(a, b)
        local fa, fb = (a * 0.618034) % 1, (b * 0.618034) % 1
        if fa ~= fb then return fa < fb end
        return a < b
    end)
    local n = 0
    return function()
        n = n + 1
        local k = n - 1
        local s = (k % 2 == 0) and 1 or -1
        local m = math.floor(k / 2)
        local row, slot = math.floor(m / per), order[m % per + 1]
        local spot, d = AlongRoute(X.route, X.cum, third + (slot - 0.5) * third / per)
        d = Flat(d)
        if d:LengthSqr() < 0.01 then d = Vector(X.dir1.x, X.dir1.y, 0) end
        d:Normalize()
        local back = CROWD_BACK + row * CROWD_APART
        return Ground(spot + Vector(-d.y, d.x, 0) * (back * s) + Vector(0, 0, 30)), { yaw = (Vector(d.y, -d.x, 0) * s):Angle().y, cheer = true }
    end
end

local function SetupParade()
    ClearLeftovers()
    MusicStop()
    local pts = {}
    for _, p in ipairs(ParadeRoute()) do pts[#pts + 1] = p.pos end
    X.route = pts
    X.cum = Cumulative(pts)
    X.total = X.cum[#pts]
    X.center = pts[1]
    local dir = Flat(pts[2] - pts[1])
    dir:Normalize()
    X.dir1 = dir
    -- the column: soldiers, two abreast, eight at the least
    local n = math.max(8, cvParadeN:GetInt())
    n = n + n % 2
    local ranks = n / 2
    X.ranks = ranks
    X.offApc = (ranks - 1) * RANK_GAP + APC_BEHIND
    X.offHunters = X.offApc + STRIDER_BEHIND / 2
    X.offStrider = X.offApc + STRIDER_BEHIND
    -- it forms up behind the first stop; with a wall there, that much further on along the route
    local need = 60 + (cvMachines:GetBool() and (X.offStrider + 150) or ((ranks - 1) * RANK_GAP + 60))
    local clear = need
    local tr = util.TraceLine({ start = pts[1] + Vector(0, 0, 40), endpos = pts[1] - dir * need + Vector(0, 0, 40), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit then clear = need * (tr.Fraction or 1) end
    X.head = math.min(-60 + (need - clear), X.total * 0.25)
    X.head0 = X.head
    local posts = {}
    for i = 1, n do
        local rank = math.floor((i - 1) / 2)
        local at, d = ParadeAt(X.head - rank * RANK_GAP)
        d = Flat(d)
        d:Normalize()
        posts[i] = at + Vector(-d.y, d.x, 0) * ((i % 2 == 0) and FILE_OFF or -FILE_OFF)
    end
    X.column = Post(posts, "soldier", COLUMN_REACH, { only = true, free = true })
    for _, u in ipairs(X.column) do
        local st = LC.NPCs[u]
        if st then
            local i = st.exPostI or 1
            local rank = math.floor((i - 1) / 2)
            local at = 0 -- (the stop behind him: he marches on from the next)
            for k = 1, #pts do if X.cum[k] <= X.head - rank * RANK_GAP then at = k end end
            st.exColumn = { i = at, rank = rank, side = (i % 2 == 0) and FILE_OFF or -FILE_OFF, delay = 0 }
            -- one of the parade; and, as a unit walking a prisoner in, he goes for nobody but whoever attacks
            -- it (LC.MakeOneHostile, sv_livingcity.lua): not the wanted, not a rebel who only stands there
            u.lcParade = true
            st.marching = true
        end
    end
    SpawnMachines()
    WalkersAreFriends()
    -- and guards along the way, to keep the crowd honest
    local guards = {}
    local g = math.Clamp(math.floor(X.total / 700), 2, 6)
    for i = 1, g do
        local spot, d = AlongRoute(pts, X.cum, X.total * (i - 0.5) / g)
        guards[#guards + 1] = spot + Vector(-d.y, d.x, 0) * ((i % 2 == 0) and 140 or -140)
    end
    X.units = Post(guards, "cop", GUARD_REACH)
    -- the crowd: every citizen the city has (lc_exercise_npcs above 0 is the most), those at home too by day,
    -- a few at a time out of a doorway; the city keeps calling until the head of the column is two thirds of
    -- the way along (the clock, below)
    X.crowdPoi = CrowdPlaces()
    X.crowdAsk = true
    EnlistCitizens(Cap(), X.crowdPoi, 6)
    X.enlistNext = CurTime() + 4
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
    local ok, err = LC.Try(kind == "jog" and SetupJog or kind == "drill" and SetupDrill or SetupParade)
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
                local ok, npc, st = LC.Try(sp, X.yard.pos + Vector(0, 0, 4))
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
            -- (attacked before it set off: they march when the fight is over and they have formed up again)
            if st and st.exColumn and not X.fight and not X.reform then
                -- one that never reached the form-up (lost on the way) is put with the others, while
                -- nobody is looking at it or at its place
                local post = st.holdPos
                if post and u:GetPos():DistToSqr(post) > 300 * 300 and LC.IsSeen
                    and not LC.IsSeen(post + Vector(0, 0, 40)) and not LC.IsSeen(u:GetPos() + Vector(0, 0, 40)) then
                    u:SetPos(post + Vector(0, 0, 4))
                end
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

-- A move of the drill, done by an NPC where they stand (the instructor out front, the city's own in the rows).
-- yaw: the way they face; spot: their place, stepped back to after a step.
-- (both arms up, for the jump: the numbers are the pose registry's, sh_livingcity_poses.lua "drill_arms_up",
-- so what the owner sets by hand with the Miscount Poser is what the drill does)
local ARMS_UP = "drill_arms_up"
local function Pose(npc, pose, secs)
    if not (npc.ManipulateBoneAngles and npc.LookupBone) then return false end
    local done = {}
    for bone, ang in pairs(LC.PoseBones(pose)) do
        local b = npc:LookupBone(bone)
        if b then npc:ManipulateBoneAngles(b, ang) done[#done + 1] = b end
    end
    timer.Simple(secs, function()
        if not IsValid(npc) then return end
        for _, b in ipairs(done) do npc:ManipulateBoneAngles(b, Angle(0, 0, 0)) end
    end)
    return #done > 0
end
local STEP = { step_left = { 0, -1 }, step_right = { 0, 1 }, step_forward = { 1, 0 }, step_back = { -1, 0 } }
local function DoMove(npc, move, yaw, spot)
    if not IsValid(npc) then return end
    yaw = yaw or npc:GetAngles().y
    if move == "spin" then
        LC.FaceYaw(npc, yaw + 120)
        timer.Simple(0.35, function() if IsValid(npc) then LC.FaceYaw(npc, yaw + 240) end end)
        timer.Simple(0.7, function() if IsValid(npc) then LC.FaceYaw(npc, yaw) end end)
    elseif move == "crouch" then
        if LC.PlayGesture then LC.PlayGesture(npc, { "Crouch_idleD", "crouchidle_panicked4", "ACT_COWER" }, 1.5) end
    elseif move == "jump" then
        Pose(npc, ARMS_UP, 0.7)
        if LC.PlayGesture then LC.PlayGesture(npc, { "jump_holding_jump", "ACT_JUMP" }, 1) end
    elseif STEP[move] and spot then
        local s, a = STEP[move], Angle(0, yaw, 0)
        npc:SetLastPosition(spot + a:Forward() * (s[1] * 45) + a:Right() * (s[2] * 45))
        npc:SetSchedule(SCHED_FORCED_GO)
        timer.Simple(1.3, function()
            if not IsValid(npc) then return end
            npc:SetLastPosition(spot)
            npc:SetSchedule(SCHED_FORCED_GO)
            timer.Simple(1.1, function() if IsValid(npc) then LC.FaceYaw(npc, yaw) end end)
        end)
    end
end
LC.DrillDoMove = DoMove
-- The instructor calls it out loud (Half-Life 2's own citizen voices: "Get down!", "Behind you!", "Let's go!").
local CALL = { crouch = { "getdown02" }, spin = { "behindyou01" } }
local CALL_ANY = { "letsgo01", "letsgo02" }
local function Call(npc, move)
    local st = LC.NPCs[npc]
    local s = "vo/npc/" .. ((st and st.gender == "female") and "female01" or "male01") .. "/" .. Pick(CALL[move] or CALL_ANY) .. ".wav"
    if file.Exists("sound/" .. s, "GAME") then npc:EmitSound(s, 80) end
end

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
    -- the instructor calls it and does it himself, out front (the owner, 15 November: "a single fitness
    -- instructor just standing there doing nothing")
    if IsValid(X.instructor) then
        X.instructor:EmitSound("buttons/blip1.wav", 70)
        Call(X.instructor, move)
        DoMove(X.instructor, move, X.yard.yaw, X.yard.pos + Vector(0, 0, 4))
        X.instructorMoves = (X.instructorMoves or 0) + 1
    end
    -- the city's own in the rows copy it, a beat behind (mostly right)
    for npc in pairs(X.npcs) do
        local st = IsValid(npc) and LC.NPCs[npc]
        local c = st and st.exCitizen
        if c and st.state == "event" then
            local m = math.random() < 0.85 and move or Pick(MOVES)
            timer.Simple(math.Rand(0.25, 0.7), function()
                if X and IsValid(npc) and st.exCitizen == c and st.state == "event" then
                    DoMove(npc, m, c.yaw, c.spot)
                    c.moves = (c.moves or 0) + 1
                end
            end)
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
            for npc in pairs(X.npcs) do -- (the city's own skip too)
                local st = IsValid(npc) and LC.NPCs[npc]
                if st and st.state == "event" and st.exCitizen and math.random() < 0.9 then DoMove(npc, "jump") end
            end
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

-- One NPC in a crowd cheers the Administrator: a loyal one out loud with a gesture; a Resistance
-- sympathizer (st.rebel) a beat late, flat and bored (spy_flat_male/_female, the same takes as
-- Careless Talk's spy), arm half up; with no flat take on the server, they just don't cheer.
-- Returns "cheer" or "flat".
LC.FlatCheerLate = 0.8
-- The right arm up to the brow (amount 1 a smart salute, about a half a limp one), down again after a moment:
-- the same pose as Careless Talk's salute (sv_livingcity_propagandamore.lua).
-- (the smart salute's numbers are the pose registry's, sh_livingcity_poses.lua "salute_crowd": the upper arm
-- -35 -75 0 and the forearm 0 -115 0 unless the owner has set it by hand with the Miscount Poser)
function LC.CrowdSalute(npc, amount, secs)
    if not (IsValid(npc) and npc.ManipulateBoneAngles and npc.LookupBone) then return false end
    local done = {}
    for name, a in pairs(LC.PoseBones("salute_crowd")) do
        local b = npc:LookupBone(name)
        if b then
            npc:ManipulateBoneAngles(b, Angle(a.p * amount, a.y * amount, a.r * amount))
            done[#done + 1] = b
        end
    end
    npc.lcSaluteAmt = amount
    timer.Simple(secs or 2.5, function()
        if not IsValid(npc) then return end
        for _, b in ipairs(done) do npc:ManipulateBoneAngles(b, Angle(0, 0, 0)) end
        npc.lcSaluteAmt = 0
    end)
    return true
end
function LC.CrowdCheer(npc, st)
    st = st or LC.NPCs[npc]
    if st and st.rebel then
        local man = not (LC.IsFemaleModel and LC.IsFemaleModel(npc.GetModel and npc:GetModel() or ""))
        local snd = LC.PropagandaVoice and LC.PropagandaVoice("spy_flat_" .. (man and "male" or "female"))
        timer.Simple(LC.FlatCheerLate, function()
            if not IsValid(npc) then return end
            if snd then npc:EmitSound(snd, 62, math.random(94, 100)) end
            LC.CrowdSalute(npc, 0.45, 1.6) -- (half up, and down again early)
        end)
        st.flatCheers = (st.flatCheers or 0) + 1
        return "flat"
    end
    local s = Pick(CHEER_SOUNDS)
    if file.Exists("sound/" .. s, "GAME") then npc:EmitSound(s, 72) end
    if math.random() < 0.5 then LC.CrowdSalute(npc, 1, 2.5)
    elseif LC.PlayGesture then LC.PlayGesture(npc, { "cheer1", "cheer2", "ACT_CHEER" }, 2) end
    return "cheer"
end

-- After the Administrator's speech, the citizens within earshot of the stand cheer once, a moment
-- apart (their sympathizers flat, as above). Returns how many cheered and how many muttered.
function LC.SpeechCrowd(pos, radius)
    radius = radius or 1200
    local cheered, flat = 0, 0
    for npc, st in pairs(LC.NPCs or {}) do
        local free = st.state == "idle" or st.state == "moving" or st.state == "event" or st.state == "busy"
        if IsValid(npc) and st.role == "citizen" and free and npc:GetPos():DistToSqr(pos) < radius * radius then
            if st.rebel then flat = flat + 1 else cheered = cheered + 1 end
            timer.Simple(math.Rand(0.2, 1.6), function()
                if IsValid(npc) then LC.CrowdCheer(npc, LC.NPCs[npc]) end
            end)
        end
    end
    return cheered, flat
end

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

-- Who is in the parade: the column's soldiers, the APC, the hunters, the strider.
local function Member(e) return IsValid(e) and e.lcParade == true end
LC.ParadeMember = Member
local function Members()
    local out = {}
    for _, u in ipairs(X.column) do
        if IsValid(u) and LC.NPCs[u] and u:Health() > 0 then out[#out + 1] = u end
    end
    for _, m in ipairs(X.machines or {}) do
        if IsValid(m.ent) then out[#out + 1] = m.ent end
    end
    return out
end

------------------------------------------------------------------------
-- The parade under attack (the owner, 15 November: "make sure they do not attack anyone, unless someone is
-- stupid enough to attack the parade, then the APCs turret attacks the attacker and the combine troops swarm
-- the attacker, hunters can as well, strider too, all so long as they reform the parade formation once the
-- threat is neutralized or out of sight for 30 seconds, at which the parade resumes at the most recent parade
-- path node and the music starts again from the beginning of the song"; and "make sure they cannot friendly
-- fire each other or other cp or overwatch, nor really anyone EXCEPT the attackers").
--
-- X.fight = { foes = { [attacker] = when last seen }, all = { every attacker there was }, node = the last
-- placed stop of the route the front rank had reached }. While it is set the march, the music and the
-- cheering are stopped. X.reform: the fight is over and they are walking back to their places at that stop.
------------------------------------------------------------------------

local FIGHT_LOST = 30 -- seconds with no attacker seen by anyone in the parade: the threat is over
LC.ParadeFightLost = FIGHT_LOST
local COMBINE = { npc_combine_s = true, npc_metropolice = true, npc_strider = true, npc_hunter = true, npc_cscanner = true,
    npc_clawscanner = true, npc_manhack = true, npc_rollermine = true, npc_turret_floor = true, npc_turret_ceiling = true,
    npc_combinegunship = true, npc_helicopter = true, npc_combinedropship = true, npc_apcdriver = true }

local function FoeAlive(a)
    if not IsValid(a) then return false end
    if a:IsPlayer() then return a:Alive() end
    return a:Health() > 0
end
-- May this one be the parade's enemy? Never one of its own, never anyone on the Combine's side (a unit, a
-- soldier, a player of Civil Protection or Overwatch), never the Administrator, never an admin at work.
local function CanBeFoe(a)
    if not IsValid(a) or Member(a) then return false end
    if a:IsPlayer() then
        local f = a:GetNW2String("lcf_faction", "")
        if f == "cp" or f == "ota" or f == "admin" or LC.PlayerIsCP(a) or (LC.IsAdministrator and LC.IsAdministrator(a)) then return false end
        if LC.EditorHeld and LC.EditorHeld(a) then return false end
        return a:Alive()
    end
    if not a:IsNPC() or COMBINE[a:GetClass()] then return false end
    local st = LC.NPCs[a]
    if st and LC.IsSecurity(st) then return false end
    return a:Health() > 0
end
LC.ParadeCanBeFoe = CanBeFoe

-- One of the parade goes for one of its attackers.
local function Engage(e, a, now)
    local st = LC.NPCs[e]
    if st then -- (a soldier of the column: the city's own way of going after someone)
        if st.state ~= "hostile" or not FoeAlive(st.enemy) then
            st.holdPos = nil
            st.provokedBy, st.provokedUntil = a, now + 600
            LC.MakeOneHostile(e, st, a)
        elseif st.enemy ~= a and not a:IsPlayer() then
            e:AddEntityRelationship(a, D_HT, 99)
        end
    elseif e:IsNPC() then -- (the strider, a hunter)
        e:AddEntityRelationship(a, D_HT, 99)
        if e.lcParadeStrider then e:Fire("EnableMinigun") end
        if e.SetEnemy and not FoeAlive(e:GetEnemy()) then e:SetEnemy(a) end
        if e:IsCurrentSchedule(SCHED_FORCED_GO) then e:SetSchedule(SCHED_CHASE_ENEMY) end
    end
    if e.UpdateEnemyMemory and e:IsNPC() then e:UpdateEnemyMemory(a, a:GetPos()) end
end

-- Someone has attacked the parade: it stops where it is, the music with it, and everyone in it goes for them.
local function ParadeAttacked(a, now)
    local F = X.fight
    if not F then
        local node = 0
        for k = 1, #X.route do if X.cum[k] <= X.head + 1 then node = k end end
        F = { foes = {}, all = {}, at = now, node = node }
        X.fight, X.reform = F, nil
        MusicStop()
        X.music = nil
        for _, u in ipairs(X.column) do
            local col = IsValid(u) and LC.NPCs[u] and LC.NPCs[u].exColumn
            if col then col.forming, col.formed = nil, nil end
        end
        LC.Log("info", "The parade was attacked by " .. (a:IsPlayer() and a:Nick() or a:GetClass()) .. ": the march stops")
    end
    local known = F.foes[a] ~= nil
    F.foes[a], F.all[a] = now, true
    if known then return end
    for _, e in ipairs(Members()) do Engage(e, a, now) end
end

-- The APC's gun: at the nearest attacker it can see, in bursts. (What it hits besides is unharmed: the hook below.)
local function TurretStep(m, F, now)
    local e = m.ent
    local nose = Angle(0, m.yaw, 0):Forward()
    local src = e:GetPos() + Vector(0, 0, 95) + nose * 30
    local best, bd, aim
    for a in pairs(F.foes) do
        if FoeAlive(a) then
            local at = a:IsPlayer() and (a:GetPos() + Vector(0, 0, 40)) or a:WorldSpaceCenter()
            local d = at:DistToSqr(src)
            if d < 3500 * 3500 and (not bd or d < bd) and LC.LineOfSight(src, at, e, a) then best, bd, aim = a, d, at end
        end
    end
    m.target = best
    if not best then return end
    local dir = (aim - src):GetNormalized()
    if e.SetPoseParameter then
        local ang = dir:Angle()
        e:SetPoseParameter("vehicle_weapon_yaw", math.AngleDifference(ang.y, m.yaw))
        e:SetPoseParameter("vehicle_weapon_pitch", math.AngleDifference(ang.p, 0))
    end
    if now < (m.fireAt or 0) then return end
    m.shots = (m.shots or 0) + 1
    m.fireAt = now + ((m.shots % 5 == 0) and 1.2 or 0.1)
    if e.FireBullets then
        e:FireBullets({ Attacker = e, Inflictor = e, Src = src, Dir = dir, Spread = Vector(0.02, 0.02, 0), Num = 1, Damage = 7,
            Tracer = 1, TracerName = "AR2Tracer", IgnoreEntity = e })
    end
    e:EmitSound("weapons/ar2/fire1.wav", 95, math.random(96, 104))
end

-- The threat is over: enemies of nobody again, and back to their places at the last stop of the route the
-- front rank had reached (the editor's own parade route point, not somewhere between two).
local function StandDown(F, now)
    for _, e in ipairs(Members()) do
        local st = LC.NPCs[e]
        for a in pairs(F.all) do
            if IsValid(a) and e:IsNPC() then
                if st and a:IsPlayer() then LC.SetRel(e, st, a, D_NU) else e:AddEntityRelationship(a, D_NU, 99) end
            end
        end
        if st then
            st.provokedBy, st.provokedUntil = nil, nil
            if st.state == "hostile" then LC.CalmOne(e, st, now) end
        elseif e:IsNPC() then
            if e.lcParadeStrider then e:Fire("DisableMinigun") end
            if e.SetEnemy then e:SetEnemy(NULL) end
            if e.ClearEnemyMemory then e:ClearEnemyMemory() end
            e:SetSchedule(SCHED_IDLE_STAND)
        end
    end
end
local function FightEnd(now)
    local F = X.fight
    X.fight = nil
    StandDown(F, now)
    local node = F.node
    X.head = math.max(X.head0, node >= 1 and X.cum[node] or X.head0)
    X.reform = { at = now, node = node }
    X.paradeDone = nil
    for _, u in ipairs(X.column) do
        local st = IsValid(u) and LC.NPCs[u]
        local col = st and st.exColumn
        if col and u:Health() > 0 then
            local d = X.head - (col.rank or 0) * RANK_GAP
            local at, dir = ParadeAt(d)
            dir = Flat(dir)
            dir:Normalize()
            col.post = Ground(at + Vector(-dir.y, dir.x, 0) * (col.side or 0) + Vector(0, 0, 30))
            col.i = 0
            for k = 1, #X.route do if X.cum[k] <= d then col.i = k end end
            col.done, col.run, col.idleAt, col.forming, col.formed, col.yaw = nil, nil, nil, true, nil, YawOf(dir)
            if not LC.GoTo(u, st, col.post, true, { kind = "exercise" }) then col.formed = true end
        end
    end
    LC.Log("info", "The parade's attackers are dead or gone: it forms up again at stop " .. node .. " of its route")
end

local function FightThink(now)
    local F = X.fight
    local members = Members()
    -- who is still a threat: alive, and seen by someone in the parade in the last half minute
    if now >= (F.lookAt or 0) then
        F.lookAt = now + 0.5
        for a in pairs(F.foes) do
            if not FoeAlive(a) then
                F.foes[a] = nil
            else
                local eye = a:IsPlayer() and a:EyePos() or (a:GetPos() + Vector(0, 0, 40))
                for _, e in ipairs(members) do
                    if e:GetPos():DistToSqr(a:GetPos()) < 4000 * 4000 and LC.LineOfSight(e:EyePos(), eye, e, a) then F.foes[a] = now break end
                end
            end
        end
    end
    local live = 0
    for _, seen in pairs(F.foes) do if now - seen < FIGHT_LOST then live = live + 1 end end
    if live == 0 or #members == 0 then return FightEnd(now) end
    -- everyone keeps after them: one whose own enemy is dead or lost takes the nearest that is left
    if now >= (F.pressAt or 0) then
        F.pressAt = now + 1
        for _, e in ipairs(members) do
            local st = LC.NPCs[e]
            local has
            if st then has = st.state == "hostile" and FoeAlive(st.enemy) and F.foes[st.enemy] ~= nil
            elseif e:IsNPC() then has = FoeAlive(e:GetEnemy()) and F.foes[e:GetEnemy()] ~= nil
            else has = true end
            if not has then
                local best, bd
                for a, seen in pairs(F.foes) do
                    if now - seen < FIGHT_LOST then
                        local d = a:GetPos():DistToSqr(e:GetPos())
                        if not bd or d < bd then best, bd = a, d end
                    end
                end
                if best then Engage(e, best, now) end
            end
        end
    end
    for _, m in ipairs(X.machines or {}) do
        if m.kind == "apc" and IsValid(m.ent) then TurretStep(m, F, now) end
    end
    -- the crowd stops cheering and cowers where it stands
    if now >= (F.cowerAt or 0) then
        F.cowerAt = now + 4
        for npc in pairs(X.npcs) do
            local st = IsValid(npc) and LC.NPCs[npc]
            if st and st.state == "event" and LC.PlayGesture then LC.PlayGesture(npc, { "crouchidle_panicked4", "Fear_Reaction", "ACT_COWER" }, 4) end
        end
    end
end

-- What the parade deals harms only those who attacked it: not its own, not a unit, not a citizen, not a
-- bystander, not a thing (a stray round, a splash, a hunter's charge, the strider's foot). And whoever harms
-- the parade is its enemy from then on.
hook.Add("EntityTakeDamage", "LivingCityParade", function(victim, dmg)
    local a, inf = dmg:GetAttacker(), dmg:GetInflictor()
    local by = Member(a) or Member(inf)
    if not by and IsValid(inf) and inf.GetOwner then by = Member(inf:GetOwner()) end
    if not by and IsValid(a) and a.GetOwner then by = Member(a:GetOwner()) end
    if by then
        if LC.ExerciseStick then return end -- (a marcher's stick on someone not cheering: LC.ExerciseBeat)
        local F = X and X.fight
        if F and F.foes[victim] ~= nil then return end
        dmg:SetDamage(0)
        return true
    end
    if X and X.kind == "parade" and Member(victim) and (dmg:GetDamage() or 0) > 0 and CanBeFoe(a) then
        local ok, err = LC.Try(ParadeAttacked, a, CurTime())
        if not ok then LC.Error("parade attacked", err) end
    end
end)

-- The strider and the hunters keep their places behind the APC. Each walks there by itself, sent on whenever
-- its place has got ahead of it; one that cannot find its way (left well behind for a few seconds) is carried
-- along the route from then on, its walk playing.
local function WalkerStep(m, e, ground, dir, now, dt, moving)
    -- (its own height above the ground: a strider's middle is its body, far above its feet)
    m.hgt = m.hgt or math.Clamp(e:GetPos().z - m.ground0.z, 0, 700)
    local place = ground + Vector(0, 0, m.hgt)
    local at = e:GetPos()
    local to = Flat(place - at)
    local off = to:Length()
    if not m.carry then
        local fwd = Flat(dir)
        fwd:Normalize()
        if (to:Dot(fwd) > 150 or (X.reform and off > 100)) and now >= (m.orderAt or 0) then
            m.orderAt = now + 1.5
            local goal = place
            if not X.reform then -- (marching: a little on from its place, so it need not stop as soon as it gets there)
                local ahead = (ParadeAt(math.min(m.d + 100, X.total)))
                goal = Ground(ahead + Vector(-fwd.y, fwd.x, 0) * (m.side or 0) + Vector(0, 0, 30)) + Vector(0, 0, m.hgt)
            end
            e:SetLastPosition(goal)
            e:SetSchedule(SCHED_FORCED_GO)
        end
        if off > 450 then
            m.lostAt = m.lostAt or now
            if now - m.lostAt > (X.reform and 12 or 3) then
                m.carry = true
                e:SetSchedule(SCHED_IDLE_STAND)
            end
        else
            m.lostAt = nil
        end
        return
    end
    local step = math.min(off, 300 * dt)
    if off > 1 then at = at + to * (step / off) end
    e:SetPos(Vector(at.x, at.y, place.z))
    e:SetAngles(Angle(0, m.yaw, 0))
    local act = (moving or off > 20) and ACT_WALK or ACT_IDLE
    if act and e.SetIdealActivity and now >= (m.actAt or 0) then
        m.actAt = now + 0.5
        if not e.GetIdealActivity or e:GetIdealActivity() ~= act then e:SetIdealActivity(act) end
    end
end

-- The APC, the hunters and the strider, each kept at its place behind the column: every tick in the game (the
-- Think hook below), so they move smoothly. Not while the parade fights. Forming up again, they may back up.
local function MachinesStep(now)
    if not (X and X.kind == "parade" and X.machines and not X.fight and (X.phase == "run" or X.reform)) then return end
    local dt = math.Clamp(now - (X.machT or now), 0, 0.25)
    X.machT = now
    if dt <= 0 then return end
    for _, m in ipairs(X.machines) do
        local e = m.ent
        if IsValid(e) then
            local moved = math.Clamp(math.min(X.head, X.total) - m.off - m.d, X.reform and -220 * dt or 0, 220 * dt)
            m.d = m.d + moved
            local pos, dir = ParadeAt(m.d)
            if m.side then
                local f = Flat(dir)
                f:Normalize()
                pos = pos + Vector(-f.y, f.x, 0) * m.side
            end
            local ground = Ground(pos + Vector(0, 0, 30))
            -- its nose comes round to the way it is going, not all at once
            m.yaw = m.yaw + math.Clamp(math.AngleDifference(YawOf(dir), m.yaw), -90 * dt, 90 * dt)
            if m.kind == "apc" then
                e:SetPos(ground + Vector(0, 0, m.lift))
                e:SetAngles(Angle(0, m.yaw + m.turn, 0))
                if moved ~= 0 and e.SetPoseParameter then
                    local spin = ((m.d * 2) % 360) - 180
                    for _, w in ipairs(APC_WHEELS) do e:SetPoseParameter(w, spin) end
                end
            else
                WalkerStep(m, e, ground, dir, now, dt, moved ~= 0)
            end
        end
    end
end
LC.ParadeMachinesStep = MachinesStep
hook.Add("Think", "LivingCityParadeMachines", function()
    if not (X and X.machines and #X.machines > 0 and not X.machinesBroken) then return end
    local ok, err = LC.Try(MachinesStep, CurTime())
    if not ok then X.machinesBroken = true LC.Error("parade machines", err) end
end)

-- Forming up again after a fight: once every marcher is at his place and the machines at theirs (or after 25
-- seconds: a straggler nobody is looking at is put in his place), the march goes on from that stop.
local function ReformThink(now)
    local R = X.reform
    local ready = true
    for _, u in ipairs(X.column) do
        local st = IsValid(u) and LC.NPCs[u]
        local col = st and st.exColumn
        if col and col.forming and not col.formed then
            if st.state == "idle" and not LC.GoTo(u, st, col.post, true, { kind = "exercise" }) then col.formed = true end
            if not col.formed then ready = false end
        end
    end
    for _, m in ipairs(X.machines or {}) do
        if IsValid(m.ent) and math.abs(math.min(X.head, X.total) - m.off - m.d) > 30 then ready = false end
    end
    if not ready and now - R.at < 25 then return end
    X.reform = nil
    for _, u in ipairs(X.column) do
        local st = IsValid(u) and LC.NPCs[u]
        local col = st and st.exColumn
        if col and col.forming then
            if not col.formed and col.post and LC.IsSeen and not LC.IsSeen(col.post + Vector(0, 0, 40)) and not LC.IsSeen(u:GetPos() + Vector(0, 0, 40)) then
                u:SetPos(col.post + Vector(0, 0, 4))
            end
            local post = col.post
            col.forming, col.formed, col.post = nil, nil, nil
            if X.phase == "run" then LC.ExerciseArrive(u, st, now)
            else st.holdPos = post LC.SetState(u, st, "idle") st.untilT = now + 1 end
        end
    end
    X.reformed = { at = now, node = R.node }
    LC.Log("info", "The parade has formed up again: the march goes on from stop " .. R.node)
end

-- The crowd goes back to its day (the column's tail has passed the two-thirds mark).
local function ReleaseCrowd()
    ReleaseCitizens()
    X.npcs = {}
    X.crowdPoi = nil
end

local function ParadeThink(now, dt)
    if X.fight then return FightThink(now) end
    if X.reform then
        if not X.machinesBroken then MachinesStep(now) end
        return ReformThink(now)
    end
    -- where the column is, and how far the front rank has come (never back, never in a leap)
    local alive, done, front = 0, 0, nil
    for _, u in ipairs(X.column) do
        local st = IsValid(u) and LC.NPCs[u]
        if st and st.exColumn then
            alive = alive + 1
            local col = st.exColumn
            if col.done then
                done = done + 1
            else
                -- (only a marcher on the route counts: one still on his way to it would put the head anywhere)
                local along, off = ParadeAlong(u:GetPos())
                along = along + (col.rank or 0) * RANK_GAP
                if off < 200 and along < X.head + 400 and (not front or along > front) then front = along end
                -- one who has dropped behind his rank runs to make it up, and walks again once he has
                if off < 300 and now >= (col.paceAt or 0) and col.i >= 1 and col.i <= #X.route and st.state == "moving" then
                    col.paceAt = now + 1
                    local lag = X.head - along
                    local run = (lag > 150) or (col.run and lag > 30) or false
                    if run ~= (col.run or false) then
                        col.run = run
                        LC.GoTo(u, st, ColumnStop(col), run, { kind = "exercise" })
                    end
                end
                if st.state == "idle" and now - (X.runStart or now) > col.delay + 1 then
                    -- a marcher who has stopped short of a stop (the way there given up) goes on to the
                    -- next one: one of them standing about kept the parade from ever ending
                    col.idleAt = col.idleAt or now
                    if now - col.idleAt > 1.5 then
                        col.idleAt = nil
                        LC.ExerciseArrive(u, st, now)
                    end
                else
                    col.idleAt = nil
                end
            end
        end
    end
    if alive == 0 or done >= alive then
        X.head = math.min(X.total, X.head + MARCH_PACE * dt) -- (nobody left marching: the rest comes on at a walk)
    elseif front then
        X.head = math.Clamp(front, X.head, X.total)
        X.noFront = nil
    else
        -- (every marcher off the route, finding a way round something: after a moment the rest comes on anyway)
        X.noFront = X.noFront or now
        if now - X.noFront > 3 then X.head = math.min(X.total, X.head + MARCH_PACE * dt) end
    end
    if not X.machinesBroken then MachinesStep(now) end
    local tail = X.head - (X.ranks - 1) * RANK_GAP
    for _, m in ipairs(X.machines or {}) do
        if IsValid(m.ent) then tail = math.min(tail, m.d) end
    end
    X.tail = tail
    -- the march, from the middle of the column, once its head is a third of the way along (after a fight:
    -- from the beginning again, as soon as it moves)
    local mid = (ParadeAt(X.head - (X.ranks - 1) * RANK_GAP / 2)) + Vector(0, 0, 60)
    if not X.music and (X.musicDue or X.head >= X.total / 3) then
        X.musicDue = true
        X.music = { list = MusicList(), at = now }
        X.musicStarts = (X.musicStarts or 0) + 1
        if #X.music.list > 0 then
            SetGlobal2Vector("lc_parade_music_pos", mid)
            SetGlobal2String("lc_parade_music", table.concat(X.music.list, "|"))
            SetGlobal2Float("lc_parade_music_at", now)
        end
    elseif X.music and now >= (X.music.posAt or 0) then
        X.music.posAt = now + 0.2
        SetGlobal2Vector("lc_parade_music_pos", mid)
    end
    -- the crowd is let go once the tail has passed the two-thirds mark
    if X.crowdPoi and tail >= X.total * 2 / 3 then ReleaseCrowd() end
    local function ColumnDist(pos)
        local best = math.huge
        for _, u in ipairs(X.column) do
            if IsValid(u) then best = math.min(best, u:GetPos():Distance(pos)) end
        end
        for _, m in ipairs(X.machines or {}) do
            if IsValid(m.ent) then best = math.min(best, Dist2D(m.ent:GetPos(), pos)) end
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
    -- the NPCs along the route cheer as it goes by (a sympathizer only mutters, flat and late)
    for npc in pairs(X.npcs) do
        local st = IsValid(npc) and LC.NPCs[npc]
        if st and st.state == "event" and now > (st.exCheerNext or 0) and ColumnDist(npc:GetPos()) < 600 then
            st.exCheerNext = now + math.Rand(2, 4.5)
            st.exCheers = (st.exCheers or 0) + 1
            LC.CrowdCheer(npc, st)
        end
    end
    -- over: the marchers at the end of the route (or none left), and the machines at their places behind them
    local settled = X.head >= X.total - 1
    for _, m in ipairs(X.machines or {}) do
        if IsValid(m.ent) and not X.machinesBroken and X.total - m.off - m.d > 20 then settled = false end
    end
    if (alive == 0 or done >= alive) and settled then
        X.paradeDone = X.paradeDone or now
        if now - X.paradeDone > 8 then LC.EndEvent(false) end
    end
end

-- Which piece a player's game found and played (the first to say so, once a start): for the log and the debug report.
net.Receive("lc_parade_music", function(_, ply)
    local path = string.lower(string.sub(net.ReadString() or "", 1, 120))
    local m = X and X.music
    if not m or m.used or not IsValid(ply) then return end
    local known = path == "none"
    for _, p in ipairs(m.list) do if p == path then known = true end end
    if not known then return end
    m.used = path
    LC.ParadeMusicUsed = { path = path, by = ply:Nick(), at = CurTime() }
    if path == "none" then LC.Log("warn", "Parade music: none of " .. table.concat(m.list, ", ") .. " is on " .. ply:Nick() .. "'s game")
    else LC.Log("info", "Parade music: " .. path .. " (as played on " .. ply:Nick() .. "'s game)") end
end)

-- The parade's march in a line, for the debug report: what was played last, and what would be tried.
function LC.ParadeDebugLine()
    local u = LC.ParadeMusicUsed
    local tries = {}
    for _, p in ipairs(MusicList()) do tries[#tries + 1] = p .. (file.Exists("sound/" .. p, "GAME") and " (the server has it)" or " (not on the server)") end
    return "parade music: " .. (u and (u.path .. ", on " .. u.by .. "'s game, " .. math.floor((CurTime() - u.at) / 60) .. " min ago") or "none played yet")
        .. " | tried in order: " .. (#tries > 0 and table.concat(tries, ", ") or "nothing (lc_parade_music is empty)")
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
    local ok, err = LC.Try(function()
        if not LC.Running or (LC.Event ~= X.kind) then return LC.ExerciseFinish() end
        local dt = math.Clamp(now - lastTick, 0, 0.5)
        lastTick = now
        -- the drill keeps calling the city's own until halfway through (those up late, or done sitting, come too)
        if X.drillPoi and now >= (X.enlistNext or 0) then
            X.enlistNext = now + 4
            if X.phase == "muster" or (X.cueNo or 0) < math.floor(math.max(2, cvCues:GetInt()) / 2) then EnlistCitizens(Cap(), X.drillPoi, 4) end
        end
        -- the parade keeps calling every citizen until the column's tail has passed them; one frightened off
        -- their place by a fight walks back to it
        if X.crowdPoi and now >= (X.enlistNext or 0) then
            X.enlistNext = now + 4
            if X.crowdAsk and X.head >= X.total * 2 / 3 then X.crowdAsk = nil end
            if not X.fight then
                if X.crowdAsk then EnlistCitizens(Cap(), X.crowdPoi, 4) end
                for npc in pairs(X.npcs) do
                    local st = IsValid(npc) and LC.NPCs[npc]
                    local c = st and st.exCitizen
                    if c and c.spot and st.state == "idle" then LC.GoTo(npc, st, c.spot, false, { kind = "exercise", pos = c.spot, yaw = c.yaw }) end
                end
            end
            WalkersAreFriends()
        end
        if X.phase == "muster" then
            -- (the parade attacked before it set off: the fight, and forming up again, as on the march)
            if X.kind == "parade" and X.fight then FightThink(now)
            elseif X.kind == "parade" and X.reform then MachinesStep(now) ReformThink(now) end
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
    if kind == "parade" then
        -- the march is silent, nobody of the parade is anyone's enemy any more, and the machines go (once
        -- nobody is looking at them)
        MusicStop()
        if x.fight then StandDown(x.fight, CurTime()) x.fight = nil end
        DismissMachines(x.machines)
    end
    for _, u in ipairs(x.units) do Unpost(u) end
    for _, u in ipairs(x.column) do Unpost(u, kind == "parade") end
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

-- Where the one going on now is held, in words ("near ..."), or nil.
function LC.ExerciseWhere() return X and X.center and Where(X.center) or nil end

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
    -- (whether this morning has exercise: the city's own Administrator speaks on the days without, sv_livingcity_speech.lua)
    LC.ExerciseToday = (dawns - 1) % math.max(1, cvEvery:GetInt()) == 0 and LC.NextExercise(false) ~= nil
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
    local function Reply(m) if IsValid(ply) then ply:ChatPrint("[Miscount] " .. m) else print("[Miscount] " .. m) end end
    local a = string.lower(tostring(args[1] or ""))
    if a == "stop" then
        if X then LC.EndEvent(false) Reply("Exercise stopped.") else Reply("No exercise on.") end
        return
    end
    if a == "next" or a == "" then
        local k = LC.NextExercise(false)
        Reply("Next morning exercise: " .. (k and NAMES[k] or "none (place a jogging route or a parade route)") ..
            ". Every " .. math.max(1, cvEvery:GetInt()) .. " morning(s), at dawn. lc_exercise <jog|drill|parade> starts one now.")
        return
    end
    if not LC.ExerciseKinds[a] then Reply("lc_exercise <jog|drill|parade|next|stop>") return end
    if not LC.Running then Reply("Start the city first.") return end
    if not LC.ExerciseReady(a) then
        Reply(a == "drill" and "Place an exercise yard first (editor: Point: exercise yard)."
            or (a == "jog" and not LC.JogOn()) and "The morning jog is archived (13 November). lc_jog 1 brings it back."
            or ("Place a " .. (a == "jog" and "jogging route" or "parade route") .. " first (two or more stops, in order)."))
        return
    end
    if LC.StartEvent(a) then Reply(NAMES[a] .. " started.") else Reply("Couldn't start it.") end
end)
