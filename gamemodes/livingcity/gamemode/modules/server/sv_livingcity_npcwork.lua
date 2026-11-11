--[[
    Living City: the city does its own work

    The city's citizens have Union jobs (sv_livingcity_people.lua), and now they
    do them, with the same effects a player's shift would have:

      Maintenance       fix broken streetlights
      Radio Repair      fix broken loudspeakers
      Sanitation        scrub graffiti, pick up junk left lying about, empty bins
      Mortuary          haul the dead to the incinerator
      Clinic Medic      get downed citizens back on their feet, patch up the
                        wounded, and see to players at the clinic
      Kitchen           bring crates in from the loading dock, cook
      Factory           work the line, carry parts from the dock
      Courier           carry the mail from the post office to people's doors
      Intake Processor    carry luggage from the platform to the housing blocks
      Records Clerk     file at the records office, take papers to the checkpoint
      Laundry           wash, and take pressed uniforms to the checkpoint
      Reclamation       clear rubble, carry the scrap to the reclamation point

    and Civil Protection units take back hijacked city screens.

    Players come first. Something broken waits lc_npc_work_grace seconds for
    a player before an NPC sees to it, or lc_npc_work_grace_players while
    someone with that job is on the server, so their shifts still have work.

    What an NPC is doing shows under their name. lc_npc_work 0 turns it off;
    lc_npc_work_pct is how often an employed citizen picks work over wandering.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn      = CreateConVar("lc_npc_work", "1", FLAGS, "City NPCs do their Union jobs (fix, haul, carry, deliver, heal)")
local cvPct     = CreateConVar("lc_npc_work_pct", "85", FLAGS, "Percent chance an employed citizen picks work over wandering")
local cvGrace   = CreateConVar("lc_npc_work_grace", "60", FLAGS, "Seconds something broken waits for a player before an NPC fixes it")
local cvGraceP  = CreateConVar("lc_npc_work_grace_players", "300", FLAGS, "The same, while a player with that job is on the server")

local TASKS = {}            -- [job id] = { task, ... }
LC.NPCWorkTasks = TASKS
local claims = {}           -- [key] = npc
local recent = {}           -- [key] = time something was last done there (bins emptied, rubble cleared)
LC.NPCWorkStats = LC.NPCWorkStats or { started = 0, finished = 0, dropped = 0, byTask = {} }
local Stats = LC.NPCWorkStats

local UP = Vector(0, 0, 8)
local function Pick(t) return t[math.random(#t)] end

------------------------------------------------------------------------
-- Players first
------------------------------------------------------------------------

function LC.JobHumans(jobId)
    local n = 0
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and p:GetNW2String("lcj_job", "") == jobId then n = n + 1 end
    end
    return n
end

function LC.NPCWorkGrace(jobId)
    return LC.JobHumans(jobId) > 0 and cvGraceP:GetFloat() or cvGrace:GetFloat()
end
local Grace = function(j) return LC.NPCWorkGrace(j) end

------------------------------------------------------------------------
-- Little helpers
------------------------------------------------------------------------

local function Floor(pos)
    local tr = util.TraceLine({ start = pos + Vector(0, 0, 16), endpos = pos - Vector(0, 0, 600), mask = MASK_SOLID_BRUSHONLY })
    return (tr and tr.Hit and tr.HitPos) or pos
end

-- A spot beside something, on the side the NPC is coming from.
local function Beside(target, from, d)
    local dir = from - target
    dir.z = 0
    if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
    dir:Normalize()
    return Floor(target + dir * (d or 48) + UP)
end
LC.NPCWorkBeside = Beside

local function JobPoints(jobId)
    local job = LCJ and LCJ.ById and LCJ.ById[jobId]
    if not job or not LC.PointsOfKind then return {} end
    return LC.PointsOfKind("work", job.num)
end

local function Nearest(list, from, maxD, posOf)
    local best, bd = nil, (maxD or 1e9) ^ 2
    for _, x in ipairs(list) do
        local p = posOf and posOf(x) or x.pos
        if p then
            local d = p:DistToSqr(from)
            if d < bd then best, bd = x, d end
        end
    end
    return best
end

local function Near(list, from, maxD, posOf)
    local out = {}
    for _, x in ipairs(list) do
        local p = posOf and posOf(x) or x.pos
        if p and p:DistToSqr(from) < (maxD or 3500) ^ 2 then out[#out + 1] = x end
    end
    return out
end

local function Claimed(key, npc)
    local c = claims[key]
    if c == nil then return false end
    local cst = IsValid(c) and LC.NPCs[c]
    if not cst or not cst.npcWork or cst.npcWork.key ~= key then claims[key] = nil return false end
    return c ~= npc
end
LC.NPCWorkClaimed = function(key) return Claimed(key, nil) end

-- Inside a Combine-only zone: not a citizen's work (a stalker sees to it: sv_livingcity_combineground.lua).
local function OffLimits(npc, st, pos)
    return LC.CitizenBarredAt ~= nil and LC.CitizenBarredAt(npc, st or (LC.NPCs and LC.NPCs[npc]), pos)
end
LC.NPCWorkOffLimits = OffLimits

-- One of these sounds, of the ones this install has.
local function Sound(e, list, lvl)
    if not IsValid(e) or not list then return end
    if type(list) ~= "table" then list = { list } end
    local have = {}
    for _, s in ipairs(list) do if not LC.SoundExists or LC.SoundExists(s) then have[#have + 1] = s end end
    if #have > 0 then e:EmitSound(Pick(have), lvl or 65) end
end

local function Sparks(pos)
    if not EffectData then return end
    local fx = EffectData()
    fx:SetOrigin(pos)
    util.Effect("Sparks", fx, true, true)
end

-- Something in their hands: a crate, a letter, a suitcase.
local function DropCarry(npc, st)
    if IsValid(st.carry) then st.carry:Remove() end
    st.carry = nil
    if IsValid(npc) and npc.SetNW2Bool then npc:SetNW2Bool("lc_carry_front", false) end
end

-- Luggage hangs at their side by its handle: upright, its long side pointing
-- the way they walk, its flat side against their leg, the top at the hand.
-- (Hung from the hand bone, a case turned with the wrist and swung flat
-- against the leg.)
local AT_SIDE = {
    ["models/props_c17/suitcase001a.mdl"] = true,
    ["models/props_c17/suitcase_passenger_physics.mdl"] = true,
    -- (a clipboard too: fixed to the hand's attachment it stuck out behind the hand at an angle, the owner's
    -- screenshot of 11 November; like this it hangs from the hand flat against the leg, kept upright.
    -- lc_clipboard_angle no longer turns it.)
    ["models/props_lab/clipboard.mdl"] = true,
}
LC.CarryAtSide = AT_SIDE
local HAND_Z, SIDE_Y = 33, -13 -- the top of what's carried; to their right

-- The turn that lays a model's (longest, middle, thinnest) axes along
-- (forward, up, sideways), by which of its own axes is which.
local UPRIGHT = {
    xyz = Angle(0, 0, 90), xzy = Angle(0, 0, 0), yxz = Angle(270, 0, 90),
    yzx = Angle(0, 90, 0), zxy = Angle(270, 0, 0), zyx = Angle(0, 90, 90),
}

-- v turned by angle a (Source's own order: roll, then pitch, then yaw).
function LC.TurnVector(v, a)
    local p, y, r = math.rad(a.p), math.rad(a.y), math.rad(a.r)
    local sp, cp, sy, cy, sr, cr = math.sin(p), math.cos(p), math.sin(y), math.cos(y), math.sin(r), math.cos(r)
    local fx, fy, fz = cp * cy, cp * sy, -sp
    local lx, ly, lz = sr * sp * cy - cr * sy, sr * sp * sy + cr * cy, sr * cp
    local ux, uy, uz = cr * sp * cy + sr * sy, cr * sp * sy - sr * cy, cr * cp
    return Vector(v.x * fx + v.y * lx + v.z * ux, v.x * fy + v.y * ly + v.z * uy, v.x * fz + v.y * lz + v.z * uz)
end

-- Where and how a side-carried model sits on its carrier: local pos, angles.
function LC.CarrySideHold(mins, maxs)
    local size = { x = maxs.x - mins.x, y = maxs.y - mins.y, z = maxs.z - mins.z }
    local axes = { "x", "y", "z" }
    table.sort(axes, function(a, b) return size[a] > size[b] end)
    local ang = UPRIGHT[axes[1] .. axes[2] .. axes[3]] or Angle(0, 0, 0)
    local mid = (mins + maxs) * 0.5
    local target = Vector(2, SIDE_Y, HAND_Z - size[axes[2]] / 2)
    return target - LC.TurnVector(mid, ang), ang
end

-- What's carried in both hands, out in front: boxes and crates.
function LC.CarryInFront(model)
    local m = string.lower(model or "")
    return (string.find(m, "box", 1, true) or string.find(m, "crate", 1, true) or string.find(m, "cardboard", 1, true)) and true or false
end

-- Held in one hand: some things need turning to sit right in it (a clipboard the right way
-- up: lc_clipboard_angle, pitch yaw roll, to tune it).
local cvClipAng = CreateConVar("lc_clipboard_angle", "0 0 180", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "How a clipboard carried in one hand is turned in it (pitch yaw roll); 0 0 0 was upside down")
local function HandAngle(model)
    local m = string.lower(model or "")
    if string.find(m, "clipboard", 1, true) then
        local p, y, r = string.match(cvClipAng:GetString(), "^%s*(%S+)%s+(%S+)%s+(%S+)")
        return Angle(tonumber(p) or 0, tonumber(y) or 0, tonumber(r) or 180)
    end
    return Angle(0, 0, 0)
end
LC.CarryHandAngle = HandAngle

local function Carry(npc, st, model)
    DropCarry(npc, st)
    local e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    e:SetPos(npc:GetPos() + Vector(0, 0, 40))
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_NONE) end
    if e.SetParent and AT_SIDE[string.lower(model)] and e.OBBMins then
        e:SetParent(npc)
        local pos, ang = LC.CarrySideHold(e:OBBMins(), e:OBBMaxs())
        if e.SetLocalPos then e:SetLocalPos(pos) end
        if e.SetLocalAngles then e:SetLocalAngles(ang) end
        -- each player's game draws it hanging from the hand as the arm swings,
        -- kept upright (cl_livingcity.lua); this spot at the hip is the fallback
        if e.SetNW2Angle then
            e:SetNW2Vector("lc_hold_off", pos - Vector(2, SIDE_Y, HAND_Z))
            e:SetNW2Angle("lc_hold_ang", ang)
            e:SetNW2Bool("lc_hold_side", true)
        end
    elseif e.SetParent and LC.CarryInFront(model) and e.OBBMins then
        -- a box or a crate: held out in front in both hands, not swinging from one like luggage
        -- (each player's game bends the arms under it: cl_livingcity.lua)
        e:SetParent(npc)
        local mins, maxs = e:OBBMins(), e:OBBMaxs()
        local mid = (mins + maxs) * 0.5
        if e.SetLocalPos then e:SetLocalPos(Vector(14 + (maxs.x - mins.x) / 2, 0, 42) - mid) end
        if e.SetLocalAngles then e:SetLocalAngles(Angle(0, 0, 0)) end
        -- where the hands go: either side of the box, near its front edge, within an arm's reach
        -- (the right one; the left mirrors it)
        if npc.SetNW2Vector then npc:SetNW2Vector("lc_carry_hand", Vector(14 + math.min((maxs.x - mins.x) * 0.3, 8), -((maxs.y - mins.y) / 2 + 1), 44)) end
        if npc.SetNW2Bool then npc:SetNW2Bool("lc_carry_front", true) end
    elseif e.SetParent then
        local att = npc.LookupAttachment and npc:LookupAttachment("anim_attachment_RH") or 0
        if att and att > 0 then
            e:SetParent(npc, att)
            if e.SetLocalPos then e:SetLocalPos(Vector(4, -3, 0)) end
        else
            e:SetParent(npc)
            if e.SetLocalPos then e:SetLocalPos(Vector(16, 0, 40)) end
        end
        if e.SetLocalAngles then e:SetLocalAngles(HandAngle(model)) end
    end
    e.lcCarried = true
    st.carry = e
    return e
end
LC.NPCCarry, LC.NPCDropCarry = Carry, DropCarry

-- Animations: the first one the model has plays (sv_livingcity.lua, LC.PlayGesture).
local CROUCH = { "ACT_PICKUP_GROUND", "ACT_COVER_LOW", "crouchidle" }
local REACH  = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND" }
local HEAL   = { "ACT_CIT_HEAL", "heal", "ACT_PICKUP_GROUND" }
local BENCH  = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND" }
local KNOCK  = { "ACT_PICKUP_RACK", "Wave_close", "wave" }

local SPARK = { "ambient/energy/spark1.wav", "ambient/energy/spark2.wav", "ambient/energy/spark3.wav", "ambient/energy/spark4.wav" }
local METAL = { "physics/metal/metal_solid_impact_soft1.wav", "physics/metal/metal_solid_impact_soft2.wav", "physics/metal/metal_solid_impact_soft3.wav" }
local CARD  = { "physics/cardboard/cardboard_box_impact_soft1.wav", "physics/cardboard/cardboard_box_impact_soft2.wav", "physics/cardboard/cardboard_box_impact_soft3.wav" }
local SCRUB = { "ambient/water/water_spray1.wav" }
local BODY  = { "physics/body/body_medium_impact_soft1.wav", "physics/body/body_medium_impact_soft3.wav", "physics/body/body_medium_impact_soft5.wav" }

------------------------------------------------------------------------
-- The work itself
------------------------------------------------------------------------

local function SetDoing(npc, text) if IsValid(npc) then LC.SetNPCStr(npc, "lc_doing", text or "") end end

local function Drop(npc, st, finished)
    local w = st and st.npcWork
    if not w then return end
    st.npcWork = nil
    if w.key and claims[w.key] == npc then claims[w.key] = nil end
    if IsValid(npc) then DropCarry(npc, st) end
    if w.onEnd then
        local ok, err = pcall(w.onEnd, npc, st, w, finished == true)
        if not ok and LC.Error then LC.Error("npc work " .. tostring(w.id), err) end
    end
    SetDoing(npc, "")
    if finished then
        hook.Run("LivingCityNPCWorkFinished", npc, st, w.id)
        Stats.finished = Stats.finished + 1
        local b = Stats.byTask[w.id] or { started = 0, finished = 0 }
        b.finished = b.finished + 1
        Stats.byTask[w.id] = b
    else
        Stats.dropped = Stats.dropped + 1
    end
end
LC.NPCWorkDrop = Drop

local function Idle(npc, st, now, secs)
    if IsValid(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
    LC.SetState(npc, st, "idle")
    st.untilT = now + (secs or math.Rand(3, 6))
end

-- A step's pos or face: a value, or a function that works it out (and may say nil).
local function Val(x, npc, st, w)
    if type(x) == "function" then return x(npc, st, w) end
    return x
end

local Begin
-- Head for the next step.
local function GoStep(npc, st, now)
    local w = st.npcWork
    local s = w and w.steps[w.i]
    if not s then Drop(npc, st, true) Idle(npc, st, now, math.Rand(4, 12)) return true end
    if s.check and not s.check(npc, st, w) then Drop(npc, st) Idle(npc, st, now) return false end
    local pos = Val(s.pos, npc, st, w)
    if not pos then Drop(npc, st) Idle(npc, st, now) return false end
    if not s.infest and LC.InInfest and LC.InInfest(pos) then Drop(npc, st) Idle(npc, st, now) return false end -- (nobody works inside an infestation, but the cleanup crew)
    w.at = pos
    SetDoing(npc, s.doing or w.label)
    if s.onGo then s.onGo(npc, st, w) end
    local face = Val(s.face, npc, st, w)
    local yaw = face and (face - pos):Angle().y or npc:GetAngles().y
    if npc:GetPos():DistToSqr(pos) < 60 * 60 then return Begin(npc, st, now) end
    if not LC.GoTo(npc, st, pos, s.run, { kind = "npcwork", pos = pos, yaw = yaw }) then
        Drop(npc, st)
        Idle(npc, st, now)
        return false
    end
    return true
end

-- Arrived: do it for a while.
function Begin(npc, st, now)
    local w = st.npcWork
    if not w then st.untilT = now + 2 return end
    local s = w.steps[w.i]
    -- whatever they came for may be gone by the time they get there (fixed, taken, removed)
    if not s or (s.check and not s.check(npc, st, w)) then
        Drop(npc, st)
        return Idle(npc, st, now)
    end
    local face = Val(s.face, npc, st, w)
    if face and LC.Face then LC.Face(npc, face) end
    LC.SetState(npc, st, "working")
    st.untilT = now + (s.secs or 4)
    w.nextAnim = now + 0.3
    if s.onArrive then s.onArrive(npc, st, w) end
    return true
end

function LC.NPCWorkArrive(npc, st, now) return Begin(npc, st, now) end

function LC.NPCWorkThink(npc, st, now)
    local w = st.npcWork
    if not w or LC.Event == "curfew" or LC.Event == "lockdown" then
        Drop(npc, st)
        return Idle(npc, st, now, 0.5)
    end
    local s = w.steps[w.i]
    if not s or (s.check and not s.check(npc, st, w)) then
        Drop(npc, st)
        return Idle(npc, st, now)
    end
    if now >= (w.nextAnim or 0) then
        w.nextAnim = now + (s.every or 3.5)
        if s.anim and LC.PlayGesture then LC.PlayGesture(npc, s.anim, 3) end
        if s.sound then Sound(npc, s.sound, s.lvl) end
        if s.tick then s.tick(npc, st, w, now) end
    end
    if now < st.untilT then return end
    if s.done then
        local ok, err = pcall(s.done, npc, st, w)
        if not ok and LC.Error then LC.Error("npc work " .. tostring(w.id), err) end
    end
    if st.npcWork ~= w then return end -- the step ended the work itself
    w.i = w.i + 1
    if w.i > #w.steps then
        Drop(npc, st, true)
        return Idle(npc, st, now, math.Rand(4, 12))
    end
    LC.SetState(npc, st, "idle")
    GoStep(npc, st, now)
end

-- Start a plan on an NPC (a task's find, or a dispatch).
local function Start(npc, st, now, task, plan)
    if plan.point then -- somewhere to sit and work, the usual way (sv_livingcity.lua)
        LC.Claim(npc, st, plan.point)
        SetDoing(npc, plan.doing or task.label)
        if not LC.GoTo(npc, st, plan.point.pos, false, plan.point) then LC.Release(npc, st) SetDoing(npc, "") return false end
        return true
    end
    local w = { id = task.id, label = plan.doing or task.label, key = plan.key, steps = plan.steps, i = 1, onEnd = plan.onEnd, data = plan.data or {} }
    if w.key then claims[w.key] = npc end
    st.npcWork = w
    Stats.started = Stats.started + 1
    local b = Stats.byTask[task.id] or { started = 0, finished = 0 }
    b.started = b.started + 1
    Stats.byTask[task.id] = b
    if plan.onStart then plan.onStart(npc, st, w) end
    return GoStep(npc, st, now)
end

-- Where a plan first takes them (a point, or its first step), for the Combine-zone check.
local function PlanBarred(npc, st, plan)
    if not LC.CitizenBarredAt then return false end
    local pos = plan.point and plan.point.pos
    if not pos and plan.steps and plan.steps[1] then
        local ok, p = pcall(Val, plan.steps[1].pos, npc, st, { data = plan.data or {}, steps = plan.steps, i = 1 })
        pos = ok and p or nil
    end
    return pos ~= nil and OffLimits(npc, st, pos)
end

-- Something for this NPC to do, from their job. Called when they choose
-- what to do next (sv_livingcity.lua).
function LC.NPCWorkChoose(npc, st, now)
    if not cvOn:GetBool() or st.questLock or st.test or st.role ~= "citizen" then return false end
    local job = st.profile and st.profile.job
    local list = job and TASKS[job]
    if not list or #list == 0 then return false end
    if LC.Event == "curfew" or LC.Event == "lockdown" then return false end
    if LC.Event == "rations" and job ~= "kitchen" and math.random() < 0.5 then return false end
    -- by the clock: busiest in the morning, the night shift only at night (sv_livingcity_rhythm.lua)
    local mul = LC.RhythmWorkMul and LC.RhythmWorkMul(job) or 1
    if mul <= 0 or math.random() * 100 >= cvPct:GetFloat() * mul then return false end
    -- the urgent ones first (something broken, someone down), then the rest, by weight
    local order = {}
    for _, t in ipairs(list) do order[#order + 1] = { t = t, w = (t.urgent and 1000 or 0) + math.random() * (t.weight or 1) } end
    table.sort(order, function(a, b) return a.w > b.w end)
    for _, o in ipairs(order) do
        local ok, plan = pcall(o.t.find, npc, st, now)
        if not ok then
            if LC.Error then LC.Error("npc work find " .. o.t.id, plan) end
        elseif plan and (not plan.key or not Claimed(plan.key, npc)) and not PlanBarred(npc, st, plan) then
            return Start(npc, st, now, o.t, plan)
        end
    end
    return false
end

-- Send a particular NPC to do something (a unit to a hijacked screen).
function LC.NPCWorkDispatch(npc, st, id, label, plan)
    if not IsValid(npc) or not st then return false end
    if st.npcWork then Drop(npc, st) end
    return Start(npc, st, CurTime(), { id = id, label = label }, plan)
end

-- Whatever they were doing, they've moved on (sv_livingcity.lua calls this
-- whenever a citizen picks something new; a removed NPC drops it too).
function LC.NPCWorkReset(npc, st)
    if st and st.npcWork then Drop(npc, st) end
    SetDoing(npc, "")
end

local prevRemoved = LC.OnNPCRemoved
function LC.OnNPCRemoved(npc, st)
    if st and st.npcWork then Drop(npc, st) end
    if st then DropCarry(npc, st) end
    if prevRemoved then return prevRemoved(npc, st) end
end

function LC.AddNPCTask(job, task)
    TASKS[job] = TASKS[job] or {}
    for i, t in ipairs(TASKS[job]) do if t.id == task.id then TASKS[job][i] = task return task end end
    table.insert(TASKS[job], task)
    return task
end
local Task = LC.AddNPCTask

------------------------------------------------------------------------
-- Maintenance and Radio Repair: what's broken
------------------------------------------------------------------------

local function FixBroken(job, cls, id, label, what)
    Task(job, { id = id, label = label, urgent = true, find = function(npc, st, now)
        local grace = Grace(job)
        local best, bd
        for _, e in ipairs(LC.EntsOf(cls)) do
            if IsValid(e) and e:GetNW2Bool("lc_broken", false) and now - (e.lcBrokenAt or 0) >= grace
                and not Claimed(id .. e:EntIndex(), npc) and not e.lcStalkerTaken and not OffLimits(npc, st, e:GetPos()) then
                local d = e:GetPos():DistToSqr(npc:GetPos())
                if d < 4000 * 4000 and (not bd or d < bd) then best, bd = e, d end
            end
        end
        if not best then return nil end
        local e = best
        return { key = id .. e:EntIndex(), steps = {
            { pos = function(n) return Beside(Floor(e:GetPos() + UP), n:GetPos(), 44) end, face = function() return e:WorldSpaceCenter() end,
              check = function() return IsValid(e) and e:GetNW2Bool("lc_broken", false) end,
              secs = 10, anim = REACH, sound = SPARK, doing = label,
              tick = function() if math.random() < 0.5 then Sparks(e:WorldSpaceCenter()) end end,
              done = function(n)
                  if LC.RepairStreetFixture and LC.RepairStreetFixture(e) then
                      hook.Run("LivingCityNPCFixed", n, e, what)
                  end
              end },
        } }
    end })
end

FixBroken("maintenance", "lc_streetlight", "lamp", "fixing a streetlight", "streetlight")
FixBroken("radio", "lc_loudspeaker", "speaker", "fixing a loudspeaker", "loudspeaker")

------------------------------------------------------------------------
-- Sanitation
------------------------------------------------------------------------

-- Graffiti gets scrubbed (sv_livingcity_scavenge.lua).
Task("sanitation", { id = "graffiti", label = "scrubbing graffiti", urgent = true, find = function(npc, st, now)
    local grace = Grace("sanitation")
    local best, bd
    for _, t in ipairs(LC.Tags or {}) do
        if now - (t.at or 0) >= grace and not Claimed("tag" .. tostring(t.pos), npc) and not OffLimits(npc, st, t.pos) then
            local d = t.pos:DistToSqr(npc:GetPos())
            if d < 4000 * 4000 and (not bd or d < bd) then best, bd = t, d end
        end
    end
    if not best then return nil end
    local tag = best
    local function Still() for _, t in ipairs(LC.Tags or {}) do if t == tag then return true end end return false end
    return { key = "tag" .. tostring(tag.pos), steps = {
        { pos = function() return Floor(tag.pos + (tag.normal or Vector(0, 0, 0)) * 34 + UP) end, face = tag.pos, check = Still,
          secs = 8, anim = REACH, sound = SCRUB, doing = "scrubbing graffiti",
          done = function(n)
              for i, t in ipairs(LC.Tags or {}) do
                  if t == tag then
                      table.remove(LC.Tags, i)
                      if LC.SendTags then LC.SendTags() end
                      hook.Run("LivingCityTagCleaned", n, t)
                      break
                  end
              end
          end },
    } }
end })

-- Junk left lying in the street: empty cans and bottles, rags. And dead headcrabs (the owner,
-- 7 November: nobody was clearing them), a minute and a half after they die, as the morgue does.
local JUNK = { can_empty = true, bottle_empty = true, cloth = true, ration_wrapper = true }
LC.NPCJunkItems = JUNK
Task("sanitation", { id = "litter", label = "picking up litter", weight = 2, find = function(npc, st, now)
    local best, bd
    for _, e in ipairs(LC.EntsOf("lc_item")) do
        local crab = LC.CrabCarcass and LC.CrabCarcass(e)
        local born = e.lcDroppedAt or (crab and e.lcBorn) or (e.GetCreationTime and e:GetCreationTime()) or now
        if IsValid(e) and ((crab and not e.lcBagging and now - born > 90) or (JUNK[e:GetNW2String("lc_item", "")] and now - born > 300))
            and not e.lcStalkerTaken and not Claimed("item" .. e:EntIndex(), npc) and not Claimed("crab" .. e:EntIndex(), npc)
            and not OffLimits(npc, st, e:GetPos()) then
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 3000 * 3000 and (not bd or d < bd) then best, bd = e, d end
        end
    end
    if not best then return nil end
    local e = best
    return { key = "item" .. e:EntIndex(), steps = {
        { pos = function(n) return Beside(e:GetPos(), n:GetPos(), 30) end, face = function() return e:GetPos() end,
          check = function() return IsValid(e) end, secs = 2.5, anim = CROUCH, doing = "picking up litter",
          done = function() if IsValid(e) then e:Remove() end end },
    } }
end })

-- The bin round: the city's bins, one after another, and the bags to the depot.
local function AllBins()
    local out = {}
    for _, e in ipairs(LC.EntsOf("lc_citybin")) do out[#out + 1] = { pos = e:GetPos(), key = "bin" .. e:EntIndex() } end
    for i, b in ipairs(LC.StaticBins or {}) do out[#out + 1] = { pos = b.pos, key = "sbin" .. i } end
    for i, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("bin") or {}) do out[#out + 1] = { pos = p.pos, key = "pbin" .. i } end
    return out
end
Task("sanitation", { id = "bins", label = "emptying bins", weight = 3, find = function(npc, st, now)
    local fresh = {}
    for _, b in ipairs(Near(AllBins(), npc:GetPos(), 3000)) do
        if now - (recent[b.key] or -1e9) > 900 and not Claimed(b.key, npc) and not OffLimits(npc, st, b.pos) then fresh[#fresh + 1] = b end
    end
    local bin = Nearest(fresh, npc:GetPos())
    if not bin then return nil end
    local steps = {
        { pos = function(n) return Beside(bin.pos, n:GetPos(), 40) end, face = bin.pos, secs = 6, anim = CROUCH, sound = CARD, doing = "emptying the bins",
          done = function(n, s) recent[bin.key] = CurTime() Carry(n, s, "models/props_junk/garbage_bag001a.mdl") end },
    }
    local depot = Nearest(JobPoints("sanitation"), npc:GetPos())
    if depot then
        steps[2] = { pos = depot.pos, secs = 3, anim = CROUCH, sound = CARD, doing = "taking the rubbish to the depot",
            done = function(n, s) DropCarry(n, s) end }
    end
    return { key = bin.key, steps = steps }
end })

------------------------------------------------------------------------
-- Mortuary: hauling the dead (sv_livingcity_mortuary.lua)
------------------------------------------------------------------------

Task("mortuary", { id = "haul", label = "collecting the dead", urgent = true, find = function(npc, st, now)
    if not LC.NearestBodyProcessor or not LC.StartHaulNPC then return nil end
    if LC.MorticiansSuspended and LC.MorticiansSuspended() then return nil end -- (stood down by the Administrator's order)
    local grace = math.min(Grace("mortuary"), 200) -- before the street cleaners take them anyway
    local best, bd
    for _, b in ipairs(LC.Bodies or {}) do
        local e = b.ent
        if IsValid(e) and e.lcBody and not e.lcBody.claimed and not (LC.HauledBy and LC.HauledBy(e)) and now - (b.born or now) >= grace
            and not OffLimits(npc, st, e:GetPos()) then
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 3500 * 3500 and (not bd or d < bd) then best, bd = e, d end
        end
    end
    if not best then return nil end
    local body = best
    local proc = LC.NearestBodyProcessor(body:GetPos())
    if not proc then return nil end
    local function Mine(n) return IsValid(body) and LC.HauledBy(body) == n end
    return {
        key = "body" .. body:EntIndex(),
        onStart = function() body.lcBody.claimed = true end,
        onEnd = function(n)
            if IsValid(body) then
                if LC.HauledBy(body) == n then LC.StopHaul(n, true, true) end
                if body.lcBody then body.lcBody.claimed = nil end
            end
        end,
        steps = {
            { pos = function(n) return Beside(body:GetPos(), n:GetPos(), 34) end, face = function() return body:GetPos() end,
              check = function() return IsValid(body) end, secs = 3, anim = CROUCH, sound = BODY, doing = "collecting the dead",
              done = function(n) LC.StartHaulNPC(n, body) end },
            { pos = function(n) return Beside(proc.pos, n:GetPos(), 70) end, face = proc.pos, check = Mine,
              secs = 3, anim = REACH, doing = "taking the body to " .. proc.name,
              done = function(n) if LC.CremateBody then LC.CremateBody(n, body, proc) end end },
        },
    }
end })

------------------------------------------------------------------------
-- Clinic Medic
------------------------------------------------------------------------

-- Someone down (sv_livingcity_rp.lua): a medic comes running, unless they're wanted, or it's a fight.
local function Revivable(ply, d, now)
    if not IsValid(ply) or not d or IsValid(d.dragger) then return false end
    if now - (d.at or now) < 15 then return false end
    if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then return false end
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) then return false end
    local pos = IsValid(d.rag) and d.rag:GetPos() or ply:GetPos()
    if LC.ZoneAt then
        local z = LC.ZoneAt(pos)
        if z and (z.kind == "rebel" or z.kind == "infest" or z.kind == "combine") then return false end
    end
    return true, pos
end

Task("medic", { id = "revive", label = "helping someone who's down", urgent = true, find = function(npc, st, now)
    local best, bd, bpos
    for ply, d in pairs(LC.Downed or {}) do
        local ok, pos = Revivable(ply, d, now)
        if ok and not Claimed("down" .. ply:EntIndex(), npc) then
            local dd = pos:DistToSqr(npc:GetPos())
            if dd < 3500 * 3500 and (not bd or dd < bd) then best, bd, bpos = ply, dd, pos end
        end
    end
    if not best then return nil end
    local ply = best
    local function Still() local d = LC.Downed[ply] return d ~= nil and (Revivable(ply, d, CurTime())) end
    local function Where() local d = LC.Downed[ply] return d and IsValid(d.rag) and d.rag:GetPos() or bpos end
    return { key = "down" .. ply:EntIndex(), steps = {
        { pos = function(n) return Beside(Where(), n:GetPos(), 34) end, face = Where, run = true, check = Still,
          secs = 6, anim = HEAL, doing = "helping someone who's down",
          done = function(n)
              if LC.Revive and LC.Revive(ply, 30, nil) then
                  local who = LC.NPCStr(n, "lc_pname", "")
                  ply:ChatPrint("[Living City] " .. (who ~= "" and who or "A Union medic") .. ", a Union medic, patches you up enough to stand.")
                  hook.Run("LivingCityNPCRevived", n, ply)
              end
          end },
    } }
end })

-- A wounded citizen.
Task("medic", { id = "patch", label = "treating the wounded", urgent = true, find = function(npc, st, now)
    local best, bd
    for n2, s2 in pairs(LC.NPCs or {}) do
        if n2 ~= npc and IsValid(n2) and s2.role == "citizen" and s2.state ~= "hostile" and n2:Health() > 0
            and n2:Health() < n2:GetMaxHealth() * 0.7 and not Claimed("heal" .. n2:EntIndex(), npc) then
            local d = n2:GetPos():DistToSqr(npc:GetPos())
            if d < 2500 * 2500 and (not bd or d < bd) then best, bd = n2, d end
        end
    end
    if not best then return nil end
    local who = best
    return { key = "heal" .. who:EntIndex(), steps = {
        { pos = function(n) return Beside(who:GetPos(), n:GetPos(), 36) end, face = function() return who:GetPos() end,
          check = function() return IsValid(who) and who:Health() > 0 end, secs = 5, anim = HEAL, doing = "treating the wounded",
          done = function(n) if IsValid(who) then who:SetHealth(who:GetMaxHealth()) hook.Run("LivingCityNPCHealed", n, who) end end },
    } }
end })

-- Clinic duty: and anyone who comes in gets seen to.
Task("medic", { id = "clinic", label = "on duty at the clinic", weight = 2, find = function(npc, st, now)
    local clinic = Nearest(JobPoints("medic"), npc:GetPos(), 4000)
    if not clinic or Claimed("clinic" .. tostring(clinic.pos), npc) then return nil end
    return { key = "clinic" .. tostring(clinic.pos), steps = {
        { pos = clinic.pos, secs = math.Rand(40, 80), anim = BENCH, every = 8, doing = "on duty at the clinic",
          tick = function(n)
              for _, p in ipairs(player.GetAll()) do
                  if p:Alive() and p:Health() < p:GetMaxHealth() and p:GetPos():DistToSqr(n:GetPos()) < 140 * 140
                      and not (LC.PlayerIsWanted and LC.PlayerIsWanted(p)) and not (LC.Downed and LC.Downed[p]) then
                      p:SetHealth(math.min(p:GetMaxHealth(), p:Health() + 10))
                      if LC.Face then LC.Face(n, p:GetPos()) end
                      if (p.lcClinicSaid or 0) < CurTime() then
                          p.lcClinicSaid = CurTime() + 60
                          p:ChatPrint("[Living City] The clinic medic sees to you. (+10 health while you stay close)")
                      end
                  end
              end
          end },
    } }
end })

------------------------------------------------------------------------
-- The ones that carry things
------------------------------------------------------------------------

local function Marked(kind, from)
    local list = LC.PointsOfKind and LC.PointsOfKind(kind) or {}
    local near = Near(list, from, 4000)
    if #near == 0 then return nil end
    return Pick(near).pos
end

-- Where people live: a housing block, or a doorway.
local function Residence(from)
    local blocks = LC.ZonesOfKind and LC.ZonesOfKind("block") or {}
    local near = Near(blocks, from, 4000)
    if #near > 0 and LC.SpotInZone then
        local spot = LC.SpotInZone(Pick(near))
        if spot then return spot end
    end
    return Marked("spawn", from)
end

-- Where Civil Protection is: a checkpoint.
local function Precinct(from)
    local cp = Nearest(LC.PointsOfKind and LC.PointsOfKind("checkpoint") or {}, from, 5000)
    return cp and cp.pos or nil
end

-- A trip: pick something up at A (a workplace, a dock), take it to B.
local function Run(job, id, label, model, from, to, opts)
    opts = opts or {}
    Task(job, { id = id, label = label, weight = opts.weight or 2, find = function(npc, st, now)
        local a = from(npc, st)
        if not a then return nil end
        local b = to(npc, st, a)
        if not b or b:DistToSqr(a) < 150 * 150 then return nil end
        return { steps = {
            { pos = a, secs = opts.loadSecs or 4, anim = CROUCH, sound = opts.sound or CARD, doing = opts.loading or label,
              done = function(n, s) Carry(n, s, model) end },
            { pos = function(n) return Beside(b, n:GetPos(), 30) end, face = b, secs = opts.dropSecs or 3, anim = opts.dropAnim or CROUCH,
              sound = opts.sound or CARD, doing = label,
              done = function(n, s) DropCarry(n, s) if opts.done then opts.done(n, s, b) end end },
        } }
    end })
end

local function Workplace(job) return function(npc) local p = Nearest(JobPoints(job), npc:GetPos(), 4500) return p and p.pos end end
local function Dock(npc) return Marked("dock", npc:GetPos()) end

-- At the workplace for a while, busy.
-- (at the factory line: the nearest spot on a conveyor near the point, to face it)
local function ConveyorFace(pos)
    local best, bd
    for _, c in ipairs(LC.EntsOf and LC.EntsOf("lc_conveyor") or ents.FindByClass("lc_conveyor")) do
        if IsValid(c) then
            local d = c:GetPos():DistToSqr(pos)
            if d < 300 * 300 and (not bd or d < bd) then best, bd = c, d end
        end
    end
    if not best then return nil end
    local b = LC.ConveyorBelt and LC.ConveyorBelt(best)
    if not b then return best:GetPos() end
    local along = math.Clamp((pos - b.origin):Dot(b.dir), -b.len / 2, b.len / 2)
    return b.origin + b.dir * along
end
LC.ConveyorFace = ConveyorFace

-- Something that stays on a work point (a radio on the repair bench): put the point on a
-- table or a bench and the thing sits there on top of it; whoever works it stands at it.
LC.BenchProps = LC.BenchProps or {} -- [point] = prop
local function BenchProp(p, model)
    local e = LC.BenchProps[p]
    if IsValid(e) then return e end
    e = ents.Create("prop_dynamic")
    if not IsValid(e) then return nil end
    e:SetModel(model)
    local tr = util.TraceLine({ start = p.pos + Vector(0, 0, 24), endpos = p.pos - Vector(0, 0, 80), mask = MASK_SOLID })
    local top = (tr and tr.Hit and tr.HitPos) or p.pos
    local lift = e.OBBMins and -e:OBBMins().z or 0
    e:SetPos(top + Vector(0, 0, lift))
    e:SetAngles(Angle(0, p.yaw or 0, 0))
    e:Spawn()
    if e.SetSolid then e:SetSolid(SOLID_VPHYSICS) end
    e.lcBenchProp = true
    LC.BenchProps[p] = e
    return e
end
LC.NPCWorkBenchProp = BenchProp
local function ClearBenchProps()
    for _, e in pairs(LC.BenchProps) do if IsValid(e) then e:Remove() end end
    LC.BenchProps = {}
end
hook.Add("LivingCityLayoutChanged", "LivingCityBenchProps", ClearBenchProps)
hook.Add("LivingCityStopped", "LivingCityBenchProps", ClearBenchProps)

local function Shift(job, id, label, opts)
    opts = opts or {}
    Task(job, { id = id, label = label, weight = opts.weight or 2, find = function(npc, st, now)
        local p = Nearest(JobPoints(job), npc:GetPos(), 4500)
        if not p then return nil end
        -- the thing on the bench: they walk up to it and work on it where it sits (nothing in their hands)
        local thing = opts.bench and BenchProp(p, opts.bench)
        if IsValid(thing) then
            local at = thing:GetPos()
            return { steps = {
                { pos = function(n) return Beside(at, n:GetPos(), 34) end, face = at, secs = math.Rand(opts.min or 30, opts.max or 70),
                  anim = opts.anim or BENCH, sound = opts.sound, every = opts.every or 5, doing = label },
            } }
        end
        -- at the line: by the belt, facing it, beside the point (not wandering off it)
        local belt = opts.belt and ConveyorFace(p.pos)
        if belt then
            return { steps = {
                { pos = function(n) return p.pos + Vector(math.Rand(-12, 12), math.Rand(-12, 12), 0) end, face = belt, secs = math.Rand(opts.min or 30, opts.max or 70),
                  anim = opts.anim or BENCH, sound = opts.sound, lvl = 55, every = opts.every or 5, doing = label },
            } }
        end
        -- a chair or bench near it: they sit and work there
        if opts.sit then
            for _, c in ipairs(LC.FreePoints and LC.FreePoints({ sitchair = true }, npc) or {}) do
                if c.pos:DistToSqr(p.pos) < 500 * 500 then return { point = c, doing = label } end
            end
        end
        return { steps = {
            { pos = function(n) return p.pos + Vector(math.Rand(-40, 40), math.Rand(-40, 40), 0) end, secs = math.Rand(opts.min or 30, opts.max or 70),
              anim = opts.anim or BENCH, sound = opts.sound, every = opts.every or 5, doing = label,
              onArrive = opts.prop and function(n, s) Carry(n, s, opts.prop) end or nil },
        } }
    end })
end

-- Ration Production
Run("kitchen", "supply", "bringing in a crate of sealed packs", "models/props_junk/cardboard_box004a.mdl", Dock, Workplace("kitchen"),
    { loading = "collecting a crate from the dock" })
Shift("kitchen", "cook", "sealing ration packs", { sound = { "ambient/machines/machine1_hit1.wav", "physics/metal/metal_box_impact_soft1.wav" } })

-- Factory
Run("factory", "parts", "carrying parts to the line", "models/props_junk/cardboard_box004a.mdl", Dock, Workplace("factory"),
    { loading = "collecting parts from the dock" })
Run("factory", "station", "moving parts between stations", "models/props_junk/cardboard_box004a.mdl", Workplace("factory"),
    function(npc, st, a) for _, p in ipairs(JobPoints("factory")) do if p.pos:DistToSqr(a) > 150 * 150 then return p.pos end end end)
-- (quiet work at the line: the clanks were heard all over the factory, long after the belt stopped)
Shift("factory", "line", "working the line", { sound = { "physics/metal/metal_box_impact_soft1.wav", "physics/metal/metal_box_impact_soft2.wav" }, every = 12, weight = 3, belt = true })

-- Courier: the mail, door to door
Run("courier", "mail", "delivering the mail", "models/props_lab/clipboard.mdl",
    function(npc) return Workplace("courier")(npc) or npc:GetPos() end,
    function(npc) return Residence(npc:GetPos()) end,
    { loading = "collecting the mail", dropAnim = KNOCK, sound = { "physics/wood/wood_box_impact_soft1.wav" }, weight = 3,
      done = function(n) Sound(n, { "physics/wood/wood_crate_impact_soft2.wav", "physics/wood/wood_crate_impact_soft3.wav" }, 60) end })

-- Intake Processor: luggage, platform to the blocks
Run("porter", "luggage", "carrying someone's luggage", "models/props_c17/suitcase001a.mdl", Workplace("porter"),
    function(npc) return Residence(npc:GetPos()) end, { loading = "collecting luggage from the platform", weight = 3 })
Shift("porter", "platform", "on the platform", { anim = KNOCK, every = 9, min = 25, max = 50 })

-- Records Clerk
Shift("clerk", "filing", "filing records", { sit = true, prop = "models/props_lab/clipboard.mdl", weight = 3 })
Run("clerk", "papers", "taking papers to the checkpoint", "models/props_lab/clipboard.mdl", Workplace("clerk"),
    function(npc) return Precinct(npc:GetPos()) end, { loading = "collecting the day's papers", dropAnim = KNOCK })

-- Uniform Laundry
Shift("laundry", "wash", "running the machines", { sound = { "ambient/machines/laundry_machine1_amb.wav", "ambient/machines/machine1_hit1.wav", "ambient/machines/machine1_hit2.wav" }, every = 9, weight = 3 })
Run("laundry", "uniforms", "delivering pressed uniforms", "models/props_junk/cardboard_box003a.mdl", Workplace("laundry"),
    function(npc) return Precinct(npc:GetPos()) end, { loading = "bundling the pressed uniforms" })

-- Reclamation Crew: rubble to the reclamation point
local function RecyclerPos(npc)
    local r = Nearest(LC.EntsOf("lc_recycler"), npc:GetPos(), 5000, function(e) return e:GetPos() end)
    if r then return r:GetPos() end
    return Workplace("scrap")(npc)
end
Task("scrap", { id = "rubble", label = "clearing rubble", weight = 3, find = function(npc, st, now)
    local piles = {}
    for i, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("rubble") or {}) do
        local key = "rubble" .. i
        if now - (recent[key] or -1e9) > 600 and not Claimed(key, npc) and p.pos:DistToSqr(npc:GetPos()) < 4000 * 4000 then
            piles[#piles + 1] = { pos = p.pos, key = key }
        end
    end
    local pile = Nearest(piles, npc:GetPos())
    if not pile then return nil end
    local dest = RecyclerPos(npc)
    local steps = {
        { pos = function(n) return Beside(pile.pos, n:GetPos(), 36) end, face = pile.pos, secs = 9, anim = CROUCH, sound = METAL, doing = "clearing rubble",
          done = function(n, s) recent[pile.key] = CurTime() Carry(n, s, "models/props_junk/garbage_metalcan002a.mdl") end },
    }
    if dest then
        steps[2] = { pos = function(n) return Beside(dest, n:GetPos(), 40) end, face = dest, secs = 3, anim = CROUCH, sound = METAL,
            doing = "handing in scrap", done = function(n, s) DropCarry(n, s) end }
    end
    return { key = pile.key, steps = steps }
end })
Shift("scrap", "yard", "sorting scrap at the yard", { sound = METAL })

-- Radio Repair, and Maintenance, when nothing's broken: at the bench, in the yard
Shift("radio", "bench", "repairing radios at the bench", { sound = { "buttons/lever7.wav", "buttons/button16.wav" }, bench = "models/props_lab/citizenradio.mdl" })
-- (the radios are on the benches whether anyone's working them or not)
timer.Create("LivingCityRadioBenches", 10, 0, function()
    if not LC.Running then return end
    for _, p in ipairs(JobPoints("radio")) do BenchProp(p, "models/props_lab/citizenradio.mdl") end
end)
Shift("maintenance", "yard", "at the maintenance yard", { sound = METAL })
Shift("sanitation", "depot", "at the sanitation depot", { anim = CROUCH, weight = 1 })

-- Dead headcrabs left lying about: the morgue bags them for the incinerator.
local CRABS = { raw_headcrab = true, raw_fastcrab = true, raw_poisoncrab = true }
LC.CrabCarcass = function(e) return IsValid(e) and e:GetClass() == "lc_item" and CRABS[e:GetNW2String("lc_item", "")] == true end
Task("mortuary", { id = "crabs", label = "bagging dead headcrabs", find = function(npc, st, now)
    local best, bd
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_item") or {}) do
        if LC.CrabCarcass(e) and not e.lcBagging and not e.lcStalkerTaken and now - (e.lcBorn or 0) > 90 -- (a while for a player to pick it up first)
            and not Claimed("item" .. e:EntIndex(), npc) and not OffLimits(npc, st, e:GetPos()) then
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 3000 * 3000 and (not bd or d < bd) then best, bd = e, d end
        end
    end
    if not best then return nil end
    local crab = best
    return {
        key = "crab" .. crab:EntIndex(),
        onStart = function() crab.lcBagging = true end,
        onEnd = function() if IsValid(crab) then crab.lcBagging = nil end end,
        steps = {
            { pos = function(n) return Beside(crab:GetPos(), n:GetPos(), 30) end, face = function() return crab:GetPos() end,
              check = function() return IsValid(crab) end, secs = 2, anim = CROUCH, doing = "bagging a dead headcrab",
              done = function() if IsValid(crab) then crab:Remove() end end },
        },
    }
end })
-- Somebody's mess in the street: sanitation scrubs it up (sv_livingcity_hygiene.lua)
Task("sanitation", { id = "stain", label = "scrubbing up a mess", urgent = true, find = function(npc, st, now)
    local grace = Grace("sanitation")
    local best, bd
    for _, e in ipairs(LC.EntsOf and LC.EntsOf("lc_stain") or {}) do
        if now - (e.lcBorn or 0) >= grace and not e.lcStalkerTaken and not OffLimits(npc, st, e:GetPos()) then
            local d = e:GetPos():DistToSqr(npc:GetPos())
            if d < 4000 * 4000 and (not bd or d < bd) then best, bd = e, d end
        end
    end
    if not best then return nil end
    local mess = best
    return {
        key = "stain" .. mess:EntIndex(),
        steps = {
            { pos = function(n) return Beside(mess:GetPos(), n:GetPos(), 32) end, face = function() return mess:GetPos() end,
              check = function() return IsValid(mess) end, secs = 5, anim = CROUCH, doing = "scrubbing up somebody's mess",
              sound = { "ambient/water/water_splash1.wav", "ambient/water/water_splash2.wav" },
              done = function() if IsValid(mess) then mess:Remove() end end },
        },
    }
end })

Shift("mortuary", "morgue", "at the morgue", { weight = 1 })
Shift("courier", "sorting", "sorting the mail", { weight = 1, prop = "models/props_lab/clipboard.mdl" })

------------------------------------------------------------------------
-- Civil Protection: taking back a hijacked screen
------------------------------------------------------------------------

local function PlayerUnitsOnline()
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and LC.PlayerIsCP and LC.PlayerIsCP(p) then return true end
    end
    return false
end

function LC.NPCRetakeScreens(now)
    now = now or CurTime()
    if not cvOn:GetBool() then return end
    local grace = PlayerUnitsOnline() and 30 or 15
    for _, screen in ipairs(LC.EntsOf("lc_screen")) do
        local untilT = screen:GetNW2Float("lc_hijacked_until", 0)
        local since = screen.lcHijackedAt or (untilT - 60)
        local key = "screen" .. screen:EntIndex()
        if untilT > now and now - since >= grace and not Claimed(key) then
            local best, bd
            for npc, st in pairs(LC.NPCs or {}) do
                if IsValid(npc) and st.role == "cop" and (st.state == "idle" or st.state == "moving") and not st.npcWork
                    and not st.questLock and not st.raid then
                    local d = npc:GetPos():DistToSqr(screen:GetPos())
                    if d < 5000 * 5000 and (not bd or d < bd) then best, bd = npc, d end
                end
            end
            if best then
                local s = screen
                LC.NPCWorkDispatch(best, LC.NPCs[best], "retake", "retaking a hijacked screen", { key = key, steps = {
                    { pos = function(n) return Beside(Floor(s:GetPos() + UP), n:GetPos(), 60) end, face = function() return s:WorldSpaceCenter() end,
                      run = true, check = function() return IsValid(s) and s:GetNW2Float("lc_hijacked_until", 0) > CurTime() end,
                      secs = 5, anim = REACH, sound = SPARK, doing = "retaking a hijacked screen",
                      done = function(n)
                          if not IsValid(s) or s:GetNW2Float("lc_hijacked_until", 0) <= CurTime() then return end
                          s:SetNW2Float("lc_hijacked_until", 0)
                          s:EmitSound("buttons/combine_button2.wav", 70)
                          for _, p in ipairs(player.GetAll()) do
                              if LC.PlayerIsCP and LC.PlayerIsCP(p) then p:ChatPrint("[CP net] A Civil Protection unit has the hijacked screen back under control.")
                              elseif p:GetNW2String("lcf_faction", "") == "resistance" then p:ChatPrint("[Resistance] They cut the broadcast.") end
                          end
                          hook.Run("LivingCityNPCRetookScreen", n, s)
                      end },
                } })
            end
        end
    end
end

timer.Create("LivingCityNPCDispatch", 5, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.NPCRetakeScreens)
    if not ok and LC.Error then LC.Error("npc dispatch", err) end
end)

------------------------------------------------------------------------
-- In the debug report
------------------------------------------------------------------------

function LC.NPCWorkSummary()
    local working, parts = 0, {}
    for npc, st in pairs(LC.NPCs or {}) do if IsValid(npc) and st.npcWork then working = working + 1 end end
    for id, b in pairs(Stats.byTask) do parts[#parts + 1] = string.format("%s %d/%d", id, b.finished, b.started) end
    table.sort(parts)
    return string.format("NPC work: %d at it now; %d started, %d finished, %d dropped. %s", working, Stats.started, Stats.finished,
        Stats.dropped, table.concat(parts, ", "))
end

concommand.Add("lc_npcwork", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local msg = "[Living City] " .. LC.NPCWorkSummary()
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
