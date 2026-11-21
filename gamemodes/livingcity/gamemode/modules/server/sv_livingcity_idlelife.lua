--[[
    Living City: the citizens' idle life, the way Valve directs it

    The owner, 21 November, on the study of Valve's own maps (docs/dev/valve-npc-notes.md):
    build all of the ideas. This is the citizens' share of them.

    1. A pose for every idle spot. Valve's maps mark 75 spots where someone idles, each naming
       one pose: a window watcher, a seated drinker, arms crossed, a couch, a bed, two bench
       sits alternating along a row. New editor points (Miscount Editor, "Point: ..."):
         window       standing at a window, looking out (d1_t03, the tenement watchers)
         armscrossed  standing about, arms crossed or hands in pockets (d1_t02, the playground)
         drinker      a seated drinker; one fond of a drink takes out a bottle there
         couch        sitting (or lying) on a couch
         bedside      sitting on the edge of a bed
       Bench seats (sitchair points in a row, facing the same way) take Valve's two plaza sits
       in turn along the row (ts02); a lone chair keeps the game's own sit. A seat placed
       within 72 units of another is put 48 from it along its bench, as Valve spaces them.
       A model without Valve's pose keeps the game's own (LC.BUSY_ACTS), so nothing stands in
       a T-pose: every name is checked against the model first (sequence names from Valve's
       QC files for the citizens: humans/male_ss, female_ss, male_shared).
    2. Moments start where a player is looking (Valve's ai_script_conditions: a player 128 to
       1000 away with the spot in a 60 degree cone and in sight, for half a second to a second
       and a half; after 15 seconds it happens anyway). LC.WhenSeen holds the person where
       they are until then. The minds' breaks use it (sv_livingcity_mindsact.lua): a break
       is seen, not told, so their "** ..." chat lines are gone (house rule 10).
    3. A quiet crowd (Valve's station maps: no greetings, no idle chatter; they look instead).
       Under the Combine's eye (a unit within 700 units, a Combine-only zone, a city screen,
       a train platform, the ration line) a citizen who would strike up a chat turns to look
       instead: at a player close by, at the unit, at the screen. A player brushing past gets
       a glance, never "Excuse me". Out of the Combine's sight two citizens still chat (and
       the owner's small talk lines are still said there). Pressing E still greets you.
    4. The city finds idle spots by itself as well (the owner, 21 November): couches, chairs and
       beds among the map's props, glass under a roof beside a walking node, and plain walls by a
       path, a few of each (section 4 below).

    No settings and nothing new on anyone's screen.
]]

LC = LC or {}

------------------------------------------------------------------------
-- 1. A pose for every idle spot
------------------------------------------------------------------------

-- Each kind lists Valve's poses (entry, loop, exit: sequence names); the first one the model
-- has is used, or with pick = "person" one of those it has, always the same for the same person.
local POSES = {
    window = {
        { loop = "d1_t03_Tenements_Look_Out_Window_Idle" }, -- (men)
        { loop = "d1_t03_LookOutWindow" },                  -- (women)
    },
    armscrossed = {
        pick = "person",
        { loop = "d1_t02_Playground_Cit1_Arms_Crossed" },   -- (men)
        { loop = "d1_t02_Playground_Cit2_Pockets" },        -- (men: hands in pockets)
    },
    drinker = {
        { entry = "drinker_sit", loop = "drinker_sit_idle", exit = "Sit_Chair_to_Idle" }, -- (men; women sit as on a chair)
    },
    couch = {
        pick = "person",
        { loop = "sitcouch1" },
        { loop = "sitcouchknees1" },
        { loop = "d1_t03_Sit_couch" },                      -- (women)
        { loop = "laycouch1", exit = "laycouch1_exit" },
    },
    bedside = {
        { entry = "d1_t03_Sit_Bed_Entry", loop = "d1_t03_Sit_Bed", exit = "d1_t03_Sit_Bed_Exit" }, -- (women; men sit as on a chair)
    },
}
LC.IDLE_POSES = POSES

-- Bench seats in a row: Valve's two plaza sits, one then the other (d1_trainstation_02).
local BENCH = {
    { entry = "Idle_to_d1_t01_BreakRoom_Sit01", loop = "d1_t02_Plaza_Sit01_Idle", exit = "d1_t01_BreakRoom_Sit01_to_Idle" },
    { entry = "d1_t01_BreakRoom_Sit02_Entry", loop = "d1_t02_Plaza_Sit02", exit = "d1_t01_BreakRoom_Sit02_Exit" },
}
LC.BENCH_POSES = BENCH

-- The game's own pose for each new kind, for a model without Valve's (and for anyone else who
-- plays a kind: LC.BUSY_ACTS is the table sv_livingcity.lua sits people down with).
local SIT_CHAIR = { "ACT_BUSY_SIT_CHAIR_ENTRY", "ACT_BUSY_SIT_CHAIR", "ACT_BUSY_SIT_CHAIR_EXIT" }
local FALLBACK = {
    window = { nil, "ACT_BUSY_QUEUE", nil },
    armscrossed = { nil, "ACT_BUSY_QUEUE", nil },
    drinker = SIT_CHAIR, couch = SIT_CHAIR, bedside = SIT_CHAIR,
}
for kind, names in pairs(FALLBACK) do
    if LC.BUSY_ACTS and not LC.BUSY_ACTS[kind] then LC.BUSY_ACTS[kind] = names end
    if LC.SITTABLE then LC.SITTABLE[kind] = true end -- (the citizens' sit, bench and lean spots: ChooseCitizenTask)
end

-- Citizens' poses only (the owner, 21 November: Civil Protection and the Overwatch never take them, placed or
-- found): true if this NPC may not be sent to a spot of this kind. Asked by FreePoints and StartBusy.
local POSE_ROLES = { citizen = true, rebel = true }
function LC.IdleKindRefused(kind, who)
    if not POSES[kind] or not IsValid(who) then return false end
    local st = LC.NPCs and LC.NPCs[who]
    return not (st and POSE_ROLES[st.role])
end

-- A name this model can play: an ACT_ activity or a sequence name (nil: it hasn't got it).
local function Seq(npc, name)
    if not name or not IsValid(npc) then return nil end
    if string.sub(name, 1, 4) == "ACT_" then return LC.BusySeqName and LC.BusySeqName(npc, name) or nil end
    local s = npc.LookupSequence and npc:LookupSequence(name)
    return (s and s >= 0) and name or nil
end
LC.IdleSeq = Seq

-- The same number for the same person (their roster id), so each keeps one pose.
local function PersonNumber(npc)
    local p = npc.lcProfile
    local id = p and p.id or (npc.EntIndex and npc:EntIndex()) or 0
    return tonumber(id) or tonumber(util.CRC(tostring(id))) or 0
end

local ROW, SEAT = 72, 48 -- seats this close, facing about the same way, are one bench; Valve's seats are 48 apart

local function Flat(v) return math.sqrt(v.x * v.x + v.y * v.y) end
local function YawGap(a, b) return math.abs(((a or 0) - (b or 0) + 180) % 360 - 180) end
local function SameBench(p, q)
    return Flat(q.pos - p.pos) <= ROW and math.abs(q.pos.z - p.pos.z) < 24 and YawGap(p.yaw, q.yaw) < 45
end

-- Where this seat is along its row of bench seats, counted from one end (1, 2, 3...); nil for a lone chair.
function LC.BenchSeatIndex(p)
    if not p or p.kind ~= "sitchair" or not LC.PointsOfKind then return nil end
    local all = LC.PointsOfKind("sitchair")
    local row, seen, i = { p }, { [p] = true }, 1
    while i <= #row do
        for _, q in ipairs(all) do
            if not seen[q] and SameBench(row[i], q) then seen[q] = true row[#row + 1] = q end
        end
        i = i + 1
    end
    if #row < 2 then return nil end
    local right = Angle(0, p.yaw or 0, 0):Right()
    table.sort(row, function(a, b)
        local da, db = (a.pos - p.pos):Dot(right), (b.pos - p.pos):Dot(right)
        if da ~= db then return da < db end
        return tostring(a.pos) < tostring(b.pos)
    end)
    for n, q in ipairs(row) do if q == p then return n end end
end

-- The pose for this person on this spot: entry, loop, exit (sequence names), or nil for the game's own.
-- StartBusy in sv_livingcity.lua asks this first.
function LC.BusyPose(npc, st, p)
    if not IsValid(npc) or not p then return nil end
    local list
    if p.kind == "sitchair" then
        local n = LC.BenchSeatIndex(p)
        if not n then return nil end
        local mine = (n % 2 == 1) and 1 or 2
        list = { BENCH[mine], BENCH[3 - mine] } -- its own sit, or failing that the other
    else
        list = POSES[p.kind]
    end
    if not list then return nil end
    local have = {}
    for _, v in ipairs(list) do
        if Seq(npc, v.loop) then have[#have + 1] = v end
    end
    if #have == 0 then return nil end
    local v = have[1]
    if list.pick == "person" then v = have[(PersonNumber(npc) % #have) + 1] end
    return Seq(npc, v.entry), v.loop, Seq(npc, v.exit)
end

-- Sat down (or stood) at a spot: a drinker's seat has the bottle out, if they are fond of one.
function LC.BusyStarted(npc, st, p)
    if not p or p.kind ~= "drinker" or not LC.NPCViceStart or not LC.NPCViceOf then return end
    local cv = GetConVar("lc_npc_vices") -- (lc_npc_vices 0: nobody drinks in the street, nor here)
    if (cv and not cv:GetBool()) or LC.NPCViceOf(npc) <= 0 then return end
    local now = CurTime()
    if LC.NPCViceStop then LC.NPCViceStop(npc) end
    if LC.NPCViceStart(npc, "drink", now) and LC.NPCVices and LC.NPCVices[npc] then
        LC.NPCVices[npc].untilT = math.max(LC.NPCVices[npc].untilT, st and st.untilT or now)
    end
end

-- The editor puts a bench seat 48 units from the seat beside it, along that bench and facing the
-- same way (Valve's spacing). Returns where to place it and its facing.
function LC.BenchSeatSnap(pos, yaw)
    if not LC.PointsOfKind then return pos, yaw end
    local all = LC.PointsOfKind("sitchair")
    local best, bd
    for _, q in ipairs(all) do
        local d = Flat(q.pos - pos)
        if d <= ROW and math.abs(q.pos.z - pos.z) < 24 and YawGap(q.yaw, yaw) < 45 and (not bd or d < bd) then best, bd = q, d end
    end
    if not best then return pos, yaw end
    local right = Angle(0, best.yaw or 0, 0):Right()
    local side = (pos - best.pos):Dot(right) >= 0 and 1 or -1
    for _, s in ipairs({ side, -side }) do
        local at = best.pos + right * (SEAT * s)
        at = Vector(at.x, at.y, pos.z)
        local taken = false
        for _, q in ipairs(all) do
            if q ~= best and Flat(q.pos - at) < SEAT / 2 then taken = true break end
        end
        if not taken then return at, best.yaw end
    end
    return pos, yaw
end

------------------------------------------------------------------------
-- Gestures: what a person does with their hands and head while they stand or sit
------------------------------------------------------------------------

-- Layered over whatever they are doing (Valve's citizen gestures: humans/male_gestures and
-- female_gestures); the first the model has is played.
local GESTURES = {
    angry   = { "g_fistshake", "g_frustrated_point", "urgenthandsweep", "broadsweepdown" },
    point   = { "g_frustrated_point", "g_point", "g_right_openhand", "G_puncuate" },
    give    = { "g_present", "give" },
    calm    = { "g_Lhandease", "g_palm_out_l", "g_left_openhand", "hg_nod_yes", "hg_nod_right" },
    despair = { "hg_headshake", "G_shrug" },
    flinch  = { "ACT_GESTURE_FLINCH_BLAST" },
    screen  = { "g_Breencast_Watcher_Response", "hg_nod_right" },
    left    = { "hg_turn_l", "hg_turnL", "hg_nod_left" },
    right   = { "hg_turn_r", "hg_turnR", "hg_nod_right" },
}
LC.CITIZEN_GESTURES = GESTURES

-- kind: a name above, or a list of names. Returns the name played, or nil.
function LC.CitizenGesture(npc, kind)
    if not IsValid(npc) then return nil end
    for _, name in ipairs(type(kind) == "table" and kind or GESTURES[kind] or {}) do
        if string.sub(name, 1, 4) == "ACT_" then
            local act = _G[name]
            if act and npc.AddGesture and npc.SelectWeightedSequence and (npc:SelectWeightedSequence(act) or -1) >= 0 then
                npc:AddGesture(act)
                return name
            end
        elseif npc.AddGestureSequence and npc.LookupSequence then
            local s = npc:LookupSequence(name)
            if s and s >= 0 then
                npc:AddGestureSequence(s, true)
                return name
            end
        end
    end
    return nil
end

------------------------------------------------------------------------
-- 2. Moments start where a player is looking
------------------------------------------------------------------------

local NEAR, FAR = 128, 1000             -- Valve: a player 128 to 1000 away (closer than 128: right there, seen)
local CONE = math.cos(math.rad(30))     -- the spot in a 60 degree cone round where they look (Valve: 25 to 60)
local NEED_MIN, NEED_MAX = 0.5, 1.5     -- in sight this long (Valve: 0.4 to 2.5 seconds)
local WAIT = 15                         -- and after this long it happens anyway (Valve's timeout)
local EYE = Vector(0, 0, 48)

-- A living player looking at this spot right now, or nil.
function LC.SpotWatched(pos, far)
    far = far or FAR
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local eye = ply:EyePos()
            local to = pos - eye
            local d2 = to:LengthSqr()
            if d2 < NEAR * NEAR then return ply end
            if d2 <= far * far and to:GetNormalized():Dot(ply:GetAimVector()) >= CONE then
                local tr = util.TraceLine({ start = eye, endpos = pos, mask = MASK_OPAQUE, filter = ply })
                if not tr.Hit or tr.Fraction > 0.97 then return ply end
            end
        end
    end
    return nil
end

local Pending = {}
LC.StagedMoments = Pending
local HOLDABLE = { idle = true, moving = true, inline = true }

local function Hold(s, now)
    local npc, st = s.npc, s.st
    if st.state == "inline" and LC.LeaveLine then LC.LeaveLine(npc, st) end
    if LC.SetState then LC.SetState(npc, st, "event") else st.state = "event" end
    st.eventUntil = s.deadline + 2
    s.held = st.eventUntil
    st.lcStaged = s
    if npc.SetSchedule and SCHED_IDLE_STAND then npc:SetSchedule(SCHED_IDLE_STAND) end
end

local function Release(s)
    local st = s.st
    if not s.held or not st or st.lcStaged ~= s then return end
    st.lcStaged = nil
    if st.state == "event" and st.eventUntil == s.held then
        if LC.SetState and IsValid(s.npc) then LC.SetState(s.npc, st, "idle") else st.state = "idle" end
        st.untilT = CurTime() + 2
    end
end

local function StillOn(s)
    local npc, st = s.npc, s.st
    if not IsValid(npc) or (npc.Health and npc:Health() <= 0) then return false end
    if st and LC.NPCs and LC.NPCs[npc] ~= st then return false end
    if s.held and (st.state ~= "event" or st.eventUntil ~= s.held) then return false end -- (taken by something else: arrested, called away)
    if s.valid and not s.valid() then return false end
    return true
end

-- Do fn(npc, st, seen, who) once a player has had this person in view for a moment, or after 15
-- seconds anyway (seen false). A citizen standing about, walking or queueing is held where they
-- are meanwhile (they stop, as if something is on their mind). o: valid() (false drops it),
-- wait, need (seconds in view). A later one for the same person replaces the earlier.
function LC.WhenSeen(npc, fn, o)
    if not IsValid(npc) or not fn then return false end
    o = o or {}
    local now = CurTime()
    local st = LC.NPCs and LC.NPCs[npc]
    for i = #Pending, 1, -1 do
        if Pending[i].npc == npc then
            Release(Pending[i])
            table.remove(Pending, i)
        end
    end
    local s = { npc = npc, st = st, fn = fn, valid = o.valid, at = now, deadline = now + (o.wait or WAIT),
        need = o.need or math.Rand(NEED_MIN, NEED_MAX) }
    if st and st.role == "citizen" and HOLDABLE[st.state] and not st.questLock then Hold(s, now) end
    Pending[#Pending + 1] = s
    return true
end

function LC.StageTick(now)
    now = now or CurTime()
    for i = #Pending, 1, -1 do
        local s = Pending[i]
        if not s then
            -- (a moment's own fn removed others)
        elseif not StillOn(s) then
            table.remove(Pending, i)
            Release(s)
        else
            local who = LC.SpotWatched(s.npc:GetPos() + EYE)
            if who then s.since = s.since or now else s.since = nil end
            local seen = who ~= nil and now - s.since >= s.need
            if seen or now >= s.deadline then
                table.remove(Pending, i)
                Release(s)
                local ok, err = LC.Try(s.fn, s.npc, s.st, seen, who)
                if not ok and LC.Error then LC.Error("idle life (a moment)", err) end
            end
        end
    end
end

timer.Create("LivingCityStagedMoments", 0.25, 0, function()
    if LC.TimeStopped or #Pending == 0 then return end
    local ok, err = LC.Try(LC.StageTick, CurTime())
    if not ok and LC.Error then LC.Error("idle life (moments)", err) end
end)

------------------------------------------------------------------------
-- 3. A quiet crowd
------------------------------------------------------------------------

local WATCH_UNIT, WATCH_SCREEN, WATCH_PLATFORM, LOOK_PLAYER = 700, 900, 700, 500
local SCREENS = { "screen", "screen_big", "screen_mid", "screen_station", "tv" }

local function NearestUnit(pos, r)
    local best, bd
    for _, e in ipairs(ents.FindInSphere(pos, r)) do
        local st = LC.NPCs and LC.NPCs[e]
        local unit = (st and st.role ~= "scanner" and LC.IsSecurity and LC.IsSecurity(st))
            or (e:IsPlayer() and e:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(e))
        if unit then
            local d = e:GetPos():DistToSqr(pos)
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best
end

local function NearestPoint(pos, kinds, r)
    local best, bd
    for _, k in ipairs(kinds) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(k) or {}) do
            local d = p.pos:DistToSqr(pos)
            if d < r * r and (not bd or d < bd) then best, bd = p, d end
        end
    end
    return best
end

local function NearestPlayer(pos, r)
    local best, bd
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local d = ply:GetPos():DistToSqr(pos)
            if d < r * r and (not bd or d < bd) then best, bd = ply, d end
        end
    end
    return best
end

-- Turn to look at a spot: the whole body when standing about, the head (a glance) otherwise.
function LC.CrowdLook(npc, st, at, what)
    if not IsValid(npc) or not at then return false end
    if st and st.state == "idle" and LC.Face then
        LC.Face(npc, at)
    else
        local ang = npc:GetAngles()
        local want = (at - npc:GetPos()):Angle().y
        local gap = (want - (ang and ang.y or 0) + 180) % 360 - 180
        if math.abs(gap) > 25 then LC.CitizenGesture(npc, gap > 0 and "left" or "right") end
    end
    if npc.SetEyeTarget then npc:SetEyeTarget(at) end
    if what == "screen" and math.random() < 0.5 then LC.CitizenGesture(npc, "screen") end
    npc.lcLook = { what = what, at = at, t = CurTime() }
    return true
end

-- Is the Combine watching this citizen (a unit near, a Combine zone, a city screen, a platform,
-- the ration line)? Returns true, and what there is to look at instead of talking: kind, spot.
function LC.CrowdWatched(npc, st)
    local pos = npc:GetPos()
    local unit = NearestUnit(pos, WATCH_UNIT)
    local screen = NearestPoint(pos, SCREENS, WATCH_SCREEN)
    local watched = unit ~= nil or screen ~= nil or (st and st.state == "inline")
        or (LC.CombineZoneAt and LC.CombineZoneAt(pos) ~= nil) or NearestPoint(pos, { "platform" }, WATCH_PLATFORM) ~= nil
    if not watched then return false end
    local ply = NearestPlayer(pos, LOOK_PLAYER)
    if ply then return true, "player", ply:EyePos() end
    if unit then return true, "unit", unit:EyePos() end
    if screen then return true, "screen", screen.pos + Vector(0, 0, 72) end
    return true
end

-- Asked before two citizens chat (TryChat in sv_livingcity.lua): true if the Combine is watching,
-- and then they look instead of saying anything.
function LC.CrowdQuiet(npc, st, now)
    if not IsValid(npc) or not st or st.role ~= "citizen" then return false end
    local watched, what, at = LC.CrowdWatched(npc, st)
    if not watched then return false end
    if what then LC.CrowdLook(npc, st, at, what) end
    return true
end

-- A player brushing past (BarkPass in sv_livingcity.lua): a glance at them, not a word.
function LC.CrowdGlance(npc, st, ply)
    if not IsValid(npc) or not IsValid(ply) then return false end
    return LC.CrowdLook(npc, st, ply:EyePos(), "player")
end

------------------------------------------------------------------------
-- 4. Idle spots the city finds by itself (the owner, 21 November: "surely you can make any couch have
--    this entity automatically, or any window texture that is below a ceiling (not under the skybox) can
--    just automatically have a chance of a civilian standing and looking out? ... any seat/chair ... any
--    bed frame prop/entity can have a small chance ... arms crossed could just be anywhere against a wall
--    (but not against a window/glass) facing a path node path?")
--
--    From the map's props (entities and the map's own static props, sv_livingcity_staticprops.lua):
--    couches and sofas (a couch spot), chairs, stools and benches (a drinker's seat), beds and bed frames
--    (a bed's edge), the seat found the way the Resistance's people find theirs (in front, facing out:
--    LC.RebelSeatSpots). From the map's walking nodes (LC.NavGraph): glass or a window texture in a wall
--    beside a node under a ceiling, not the sky (a window spot facing it), and a solid wall, not glass,
--    beside a node (arms crossed, back to the wall, looking at the path). Sparing: each thing has a chance
--    (the same each time the map loads), at most two in an area (512 units square, a floor at a time) and
--    one of a kind; never within 64 units of a point the editor placed, never in a Combine-only zone, the
--    prison, rebel ground or the infestation. They live only while the map runs (nothing is saved) and
--    are looked for again every 10 minutes (props move); FreePoints offers them with the placed ones.
------------------------------------------------------------------------

local AUTO = LC.AutoSpots or { byKind = {}, byKey = {}, counts = {} }
LC.AutoSpots = AUTO
LC.AUTO_CHANCE = LC.AUTO_CHANCE or { couch = 0.5, bedside = 0.25, drinker = 0.15, window = 0.35, armscrossed = 0.06 }
local AUTO_ORDER = { couch = 1, bedside = 2, drinker = 3, window = 4, armscrossed = 5 } -- (furniture first, when an area is full)
local AUTO_CELL, AUTO_FLOOR, AUTO_PER_CELL, AUTO_APART = 512, 256, 2, 48
local AUTO_KEEP_OFF = 64        -- never this close to a point the editor placed
local AUTO_NODE = 128           -- furniture this close to a walking node (somewhere people get to)
local AUTO_RESCAN = 600
local AUTO_STEP = 400           -- walking nodes looked at in one go
local REST_KIND = { couch = "couch", seat = "drinker", bed = "bedside" }
local PROP_CLASSES = { "prop_physics", "prop_physics_multiplayer", "prop_physics_override", "prop_dynamic", "prop_dynamic_override" }
local NOT_HERE = { combine = true, prison = true, rebel = true, infest = true, nogo = true, dream = true }
local DIRS8 = {}
for i = 0, 7 do local a = math.rad(i * 45) DIRS8[#DIRS8 + 1] = Vector(math.cos(a), math.sin(a), 0) end

-- The same answer for the same place every time the map loads.
local function Chance(pos, kind)
    local h = tonumber(util.CRC(string.format("%s:%d:%d:%d", kind, math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)))) or 0
    return (h % 10000) / 10000 < (LC.AUTO_CHANCE[kind] or 0)
end

-- Somewhere a citizen idling would fit: not on top of what the editor placed, not on Combine ground, in
-- the cells, on rebel ground or in the infestation.
local function Fits(pos)
    if LC.NearestPoint and LC.NearestPoint(pos, AUTO_KEEP_OFF) then return false end
    if LC.CombineZoneAt and LC.CombineZoneAt(pos) then return false end
    if LC.InfestZoneAt and LC.InfestZoneAt(pos) then return false end -- (the owner: no citizen lounging on a couch in the infestation)
    for _, z in ipairs(LC.Zones or {}) do
        if NOT_HERE[z.kind] and LCZ and LCZ.Contains and LCZ.Contains(z, pos) then return false end
    end
    return true
end

local function NearNode(pos)
    if not LC.NavNodesNear then return false end
    for _, nd in ipairs(LC.NavNodesNear(pos, AUTO_NODE)) do
        if math.abs(nd.pos.z - pos.z) < 64 then return true end
    end
    return false
end

local function FloorAt(p)
    local tr = util.TraceLine({ start = p + Vector(0, 0, 30), endpos = p - Vector(0, 0, 90), mask = MASK_NPCSOLID_BRUSHONLY })
    if tr and tr.Hit and not tr.StartSolid then return tr.HitPos end
    return nil
end

-- Glass, or a window in the wall's texture.
local function IsGlass(tr)
    local tex = string.lower(tr.HitTexture or "")
    if string.find(tex, "glass", 1, true) or string.find(tex, "window", 1, true) then return true end
    if MAT_GLASS and tr.MatType == MAT_GLASS then return true end
    return IsValid(tr.Entity) and tr.Entity:GetClass() == "func_breakable_surf"
end
LC.AutoIsGlass = IsGlass

-- A ceiling over it, not the sky.
local function UnderRoof(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 8), endpos = pos + Vector(0, 0, 512), mask = MASK_SOLID_BRUSHONLY })
    return tr ~= nil and tr.Hit and not tr.HitSky and not tr.StartSolid
end

local function Wall(from, dir, len, mask)
    local tr = util.TraceLine({ start = from, endpos = from + dir * len, mask = mask })
    if tr and tr.Hit and not tr.StartSolid and tr.HitNormal and math.abs(tr.HitNormal.z) < 0.3 then return tr end
    return nil
end

-- Couches, chairs and beds among the props, each with a seat in front of it.
local function PropCandidates(list)
    if not LC.RebelSeatSpots or not LC.RestKindForModel then return end
    local things = {}
    for _, cls in ipairs(PROP_CLASSES) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            local k = IsValid(e) and not e.lcCarried and not e.lcViceProp and LC.RestKindForModel(e:GetModel())
            if k and REST_KIND[k] then things[#things + 1] = { ent = e, kind = k, pos = e:GetPos() } end
        end
    end
    for _, s in ipairs(LC.StaticRest or {}) do
        if REST_KIND[s.kind] then things[#things + 1] = { kind = s.kind, pos = s.pos, ang = s.ang } end
    end
    for _, t in ipairs(things) do
        local kind = REST_KIND[t.kind]
        if Chance(t.pos, kind) and NearNode(t.pos) then
            local sp = (LC.RebelSeatSpots(t) or {})[1]
            if sp and Fits(sp.pos) then
                list[#list + 1] = { kind = kind, pos = sp.pos, yaw = sp.yaw, ent = t.ent, entAt = t.ent and t.ent:GetPos() }
            end
        end
    end
end

-- The nearest wall round a spot (the one straight in front of it), glass or not as asked.
local function NearestWall(from, len, mask, glass)
    local best, bd
    for _, d in ipairs(DIRS8) do
        local tr = Wall(from, d, len, mask)
        if tr and IsGlass(tr) == glass then
            local dd = tr.HitPos:DistToSqr(from)
            if not bd or dd < bd then best, bd = { tr = tr, d = d }, dd end
        end
    end
    return best
end

-- A window beside a walking node under a roof, and a wall to stand against.
local function NodeCandidates(list, nodes, from, to)
    for i = from, to do
        local nd = nodes[i]
        local at = nd and nd.pos
        if at and Chance(at, "window") and UnderRoof(at) then
            local w = NearestWall(at + Vector(0, 0, 56), 128, MASK_SOLID, true)
            if w then
                local n = Vector(w.tr.HitNormal.x, w.tr.HitNormal.y, 0):GetNormalized()
                local p = FloorAt(Vector(w.tr.HitPos.x, w.tr.HitPos.y, at.z) + n * 22)
                if p and math.abs(p.z - at.z) < 32 and Fits(p) then list[#list + 1] = { kind = "window", pos = p, yaw = (n * -1):Angle().y } end
            end
        end
        if at and Chance(at, "armscrossed") then
            local w = NearestWall(at + Vector(0, 0, 40), 96, MASK_SOLID_BRUSHONLY, false)
            local top = w and Wall(at + Vector(0, 0, 80), w.d, 96, MASK_SOLID_BRUSHONLY)
            -- a solid wall from chest to head height (not a railing, not glass)
            if top and not IsGlass(top) and math.abs(top.HitPos:Distance(at + Vector(0, 0, 80)) - w.tr.HitPos:Distance(at + Vector(0, 0, 40))) < 12 then
                local n = Vector(w.tr.HitNormal.x, w.tr.HitNormal.y, 0):GetNormalized()
                local p = FloorAt(Vector(w.tr.HitPos.x, w.tr.HitPos.y, at.z) + n * 20)
                if p and math.abs(p.z - at.z) < 32 and Fits(p) and (not LC.ClearSpot or LC.ClearSpot(p)) then
                    local look = at - p
                    look.z = 0
                    local yaw = look:LengthSqr() > 24 * 24 and look:Angle().y or n:Angle().y -- (looking at the path)
                    list[#list + 1] = { kind = "armscrossed", pos = p, yaw = yaw }
                end
            end
        end
    end
end

local function KeyOf(c) return string.format("%s:%d:%d:%d", c.kind, math.floor(c.pos.x / 8), math.floor(c.pos.y / 8), math.floor(c.pos.z / 8)) end

-- The candidates, thinned to the caps; a spot found again keeps the same table (whoever sits there keeps it).
local function Finish(list)
    for _, c in ipairs(list) do c.key = KeyOf(c) end
    table.sort(list, function(a, b)
        if AUTO_ORDER[a.kind] ~= AUTO_ORDER[b.kind] then return AUTO_ORDER[a.kind] < AUTO_ORDER[b.kind] end
        return a.key < b.key
    end)
    local byKind, byKey, counts, cells, kept = {}, {}, {}, {}, {}
    for _, c in ipairs(list) do
        local ck = string.format("%d:%d:%d", math.floor(c.pos.x / AUTO_CELL), math.floor(c.pos.y / AUTO_CELL), math.floor(c.pos.z / AUTO_FLOOR))
        local cell = cells[ck] or { n = 0 }
        cells[ck] = cell
        local apart = not byKey[c.key]
        for _, o in ipairs(apart and kept or {}) do
            if o.pos:DistToSqr(c.pos) < AUTO_APART * AUTO_APART then apart = false break end
        end
        if apart and cell.n < AUTO_PER_CELL and not cell[c.kind] then
            local p = AUTO.byKey[c.key] or { kind = c.kind, group = 0, auto = true }
            p.pos, p.yaw, p.ent, p.entAt = c.pos, c.yaw, c.ent, c.entAt
            byKey[c.key] = p
            byKind[c.kind] = byKind[c.kind] or {}
            table.insert(byKind[c.kind], p)
            kept[#kept + 1] = p
            cell.n, cell[c.kind] = cell.n + 1, true
            counts[c.kind] = (counts[c.kind] or 0) + 1
        end
    end
    AUTO.byKind, AUTO.byKey, AUTO.counts, AUTO.built = byKind, byKey, counts, CurTime()
    if LC.Log then
        LC.Log("info", string.format("Idle spots found by the city: %d couches, %d beds' edges, %d drinkers' seats, %d windows, %d walls to stand against",
            counts.couch or 0, counts.bedside or 0, counts.drinker or 0, counts.window or 0, counts.armscrossed or 0))
    end
end

-- Still there: a couch or chair someone has moved or knocked over is no seat until it is found again.
function LC.AutoSpotOK(p)
    if not p.ent and not p.entAt then return true end
    if not IsValid(p.ent) or p.ent:GetPos():DistToSqr(p.entAt) > 16 * 16 then return false end
    local a = p.ent:GetAngles()
    return not a or (math.abs(a.p or 0) < 25 and math.abs(a.r or 0) < 25)
end

-- Look for them. now: all at once (the tests); else the walking nodes a few hundred at a time.
function LC.AutoSpotsScan(now)
    local list = {}
    PropCandidates(list)
    local nodes = (LC.NavGraph and LC.NavGraph.nodes) or {}
    if now or #nodes <= AUTO_STEP then
        NodeCandidates(list, nodes, 1, #nodes)
        Finish(list)
    else
        AUTO.job = { list = list, nodes = nodes, i = 1 }
    end
    return true
end

function LC.AutoSpotsStep()
    local j = AUTO.job
    if not j then return false end
    local to = math.min(#j.nodes, j.i + AUTO_STEP - 1)
    NodeCandidates(j.list, j.nodes, j.i, to)
    j.i = to + 1
    if j.i > #j.nodes then
        AUTO.job = nil
        Finish(j.list)
    end
    return true
end

-- First once the map's props and walking nodes are read (a little after the map starts), then every 10 minutes.
hook.Add("InitPostEntity", "LivingCityAutoSpots", function() AUTO.nextScan = CurTime() + 15 end)
timer.Create("LivingCityAutoSpots", 0.5, 0, function()
    if LC.TimeStopped then return end
    local fn = AUTO.job and LC.AutoSpotsStep or (AUTO.nextScan and CurTime() >= AUTO.nextScan and LC.AutoSpotsScan)
    if not fn then return end
    if not AUTO.job then AUTO.nextScan = CurTime() + AUTO_RESCAN end
    local ok, err = LC.Try(fn)
    if not ok and LC.Error then LC.Error("idle life (spots found)", err) end
end)
