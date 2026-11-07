--[[
    Living City: rebel life

    The Resistance at home isn't standing about. Each fighter in a rebel zone
    picks something to do, and puts it down the moment they're needed: a
    shout of "Combine!", a fight in the zone, a lookout's warning, someone
    asking them along, a raid. Then they're on their feet, facing the trouble.

      Patrol        a walk round the edge of the zone, stopping to look out
                    (someone's always on it once two or three are home)
      Workbench     at a workbench (the editor's fixture, or one in the map)
                    or the camp table: reaching, tinkering, cleaning a gun
      Crates        going through the supply crates and the boxes lying about
      Garden        tending the pots
      Carrying      a box from one crate to another, or to the workbench
      The fire      sitting round the burning barrel
      Sitting       on a chair at the camp table, a couch, a bench, or the
                    editor's sit, bench and lean points inside the zone
      Sleeping      on a mattress, a bed, or the editor's "Point: bunk" (more
                    of them at night); a shout wakes them

    What's in the zone counts: props you placed and made persistent, the
    dressing (mattresses, couches, crates, the table and chairs, the fire),
    and beds, couches, chairs, workbenches and crates built into the map.

    Scavenging runs: now and then (lc_rebel_errand_minutes, 4, on average,
    for each rebel zone with three or more fighters at home and someone on
    the server) one or two slip out to scavenge at a bin, a junk pile or a
    salvage point within reach, or just somewhere in the streets. They walk,
    not run, and keep out of sight: a unit close and in view, and they back
    off and wait it out (three times, and it's too hot out there: home). They
    search for a while and carry what they found home, into the zone's
    supply crate. A unit who catches them in the open opens fire
    (lc_units_spot_rebels); they fight their way home. lc_rebel_errand
    (admin) sends one out now.

      lc_rebel_life 0/1             home activities (1)
      lc_rebel_errands 0/1          scavenging runs (1)
      lc_rebel_errand_minutes <m>   average minutes between runs, per zone (4)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvLife    = CreateConVar("lc_rebel_life", "1", FLAGS, "Rebels at home keep busy: patrols, the workbench, crates, the garden, the fire, sitting, sleeping")
local cvErrands = CreateConVar("lc_rebel_errands", "1", FLAGS, "Rebels slip out in ones and twos to scavenge, keeping out of sight, and bring it home")
local cvErrandM = CreateConVar("lc_rebel_errand_minutes", "4", FLAGS, "Average minutes between scavenging runs, for each rebel zone")
local cvHeadFlip = CreateConVar("lc_bed_head_flip", "0", FLAGS, "1 turns everyone lying on an editor-placed bed (Fixture: bed) round the other way, if their heads are at the foot end")
local cvBedLift = CreateConVar("lc_rebel_bed_height", "8", FLAGS, "How far above a mattress or bed a sleeping fighter's hips lie (they're settled onto it by this; more if they sink into it, less if they float)")

-- Lying down, settled onto the bed: the lying animations carry their own height (they were made
-- for the game's cots), so the sleeper is moved down until the hips are just on top of it.
local function SettleOnBed(npc, L, topZ)
    if not IsValid(npc) or not IsValid(L.ss) or not npc.LookupBone or not npc.GetBonePosition then return end
    local bone = npc:LookupBone("ValveBiped.Bip01_Pelvis")
    local bp = bone and npc:GetBonePosition(bone)
    if not bp then return end
    local drop = bp.z - (topZ + cvBedLift:GetFloat())
    if drop > 4 and drop < 120 then
        L.ss:SetPos(L.ss:GetPos() - Vector(0, 0, drop))
        npc:SetPos(npc:GetPos() - Vector(0, 0, drop))
        L.settled = drop
    end
end
LC.RebelSettleOnBed = SettleOnBed

local UP = Vector(0, 0, 50)
local function Pick(t) return t[math.random(#t)] end
local function Say(ply, msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end

-- Animations: the first one the model has plays (sv_livingcity.lua, LC.PlayGesture).
local CROUCH = { "ACT_PICKUP_GROUND", "ACT_COVER_LOW", "crouchidle" }
local REACH  = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND" }
local BENCH  = { "ACT_PICKUP_RACK", "ACT_PICKUP_GROUND" }
-- Lying down: whichever of these the model has; failing all of them, sitting on the bed.
local LYING  = { "Lying_Down", "lying_down", "d1_town05_Wounded_Idle_1", "d1_town05_Wounded_Idle_2", "d1_town05_Winston_Down" }

local TOOLS = { "physics/metal/weapon_impact_soft1.wav", "physics/metal/weapon_impact_soft2.wav", "physics/metal/weapon_impact_soft3.wav",
    "physics/metal/metal_solid_impact_soft1.wav", "physics/metal/metal_solid_impact_soft2.wav", "weapons/smg1/switch_single.wav" }
local CRATE = { "physics/wood/wood_box_impact_soft1.wav", "physics/wood/wood_box_impact_soft2.wav", "physics/wood/wood_box_impact_soft3.wav",
    "physics/cardboard/cardboard_box_impact_soft1.wav", "physics/cardboard/cardboard_box_impact_soft2.wav" }
local DIRT  = { "player/footsteps/dirt1.wav", "player/footsteps/dirt2.wav", "player/footsteps/dirt3.wav", "player/footsteps/dirt4.wav" }
local BOXES = { "models/props_junk/cardboard_box004a.mdl", "models/props_junk/cardboard_box003a.mdl" }

local SF_SCRIPT_LOOP_IN_POST_IDLE = 256
local SF_SCRIPT_NO_COMPLAINTS     = 2048
local SF_SCRIPT_ALLOW_DEATH       = 4096
local SS_FLAGS = SF_SCRIPT_LOOP_IN_POST_IDLE + SF_SCRIPT_NO_COMPLAINTS + SF_SCRIPT_ALLOW_DEATH

local claims = {} -- [spot key] = npc

------------------------------------------------------------------------
-- What's in a zone, and what it's good for
------------------------------------------------------------------------

local function KindOfModel(m)
    m = string.lower(m or "")
    if m == "" then return nil end
    if string.find(m, "workbench", 1, true) then return "bench" end
    local rest = LC.RestKindForModel and LC.RestKindForModel(m)
    if rest then return rest end
    if string.find(m, "table", 1, true) or string.find(m, "desk", 1, true) then return "table" end
    for _, pat in ipairs({ "crate", "cardboard_box", "pallet", "oildrum", "footlocker", "item_item_crate" }) do
        if string.find(m, pat, 1, true) then return "crate" end
    end
    return nil
end
LC.RebelThingKind = KindOfModel

local function KeyOf(t)
    if IsValid(t.ent) then return "e" .. t.ent:EntIndex() end
    return string.format("s%d_%d_%d", math.floor(t.pos.x), math.floor(t.pos.y), math.floor(t.pos.z))
end

local function Free(key, npc)
    local c = claims[key]
    if c == nil or c == npc then return true end
    local cst = IsValid(c) and LC.NPCs[c]
    if not cst or not cst.life or (cst.life.key ~= key and cst.life.key2 ~= key) then claims[key] = nil return true end
    return false
end

local spotCache = setmetatable({}, { __mode = "k" })
local PROP_CLASSES = { prop_physics = true, prop_physics_multiplayer = true, prop_dynamic = true, prop_dynamic_override = true }

local function ZoneThings(z)
    local now = CurTime()
    local c = spotCache[z]
    if c and now < c.at then return c.list end
    local list = {}
    local function add(kind, pos, t)
        t = t or {}
        t.kind, t.pos = kind, pos
        t.key = KeyOf(t)
        list[#list + 1] = t
    end
    local function inside(p) return LCZ.Contains(z, p, 0) end
    for _, e in ipairs(ents.FindInSphere(z.pos, (z.r or 300) + 64)) do
        if IsValid(e) and not e:IsPlayer() and not e:IsNPC() and not e.lcCarried and inside(e:GetPos()) then
            local cls = e:GetClass()
            local kind
            if cls == "lc_fire" then kind = "fire"
            elseif cls == "lc_workbench" then kind = "bench"
            elseif cls == "lc_bed" then kind = "bed" -- (the editor's "Fixture: bed": slept in like any other)
            elseif e.lcRebelProp == "pot" then kind = "pot"
            elseif e.lcRebelProp == "cache" then kind = "crate"
            elseif PROP_CLASSES[cls] then kind = KindOfModel(e:GetModel()) end
            if kind then add(kind, e:GetPos(), { ent = e, cache = e.lcRebelProp == "cache" }) end
        end
    end
    for _, s in ipairs(LC.StaticSurfaces or {}) do
        local k = inside(s.pos) and KindOfModel(s.model)
        if k == "bench" or k == "table" then add(k, s.pos, { ang = s.ang }) end
    end
    for _, s in ipairs(LC.StaticRest or {}) do
        if inside(s.pos) then add(s.kind, s.pos, { ang = s.ang }) end
    end
    for _, s in ipairs(LC.StaticJunk or {}) do
        if inside(s.pos) and KindOfModel(s.model) == "crate" then add("crate", s.pos, { ang = s.ang }) end
    end
    -- the editor's own spots inside it: sit, bench and lean points, and bunks
    for _, kind in ipairs({ "sit", "sitchair", "lean", "bunk" }) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(kind) or {}) do
            if inside(p.pos) then add(kind == "bunk" and "bunk" or "point", p.pos, { point = p, yaw = p.yaw or 0 }) end
        end
    end
    spotCache[z] = { at = now + 15, list = list }
    return list
end
LC.RebelZoneThings = ZoneThings

------------------------------------------------------------------------
-- Geometry: where to stand, sit and lie
------------------------------------------------------------------------

local function AxesOf(t)
    local ang = (IsValid(t.ent) and t.ent:GetAngles()) or t.ang or Angle(0, 0, 0)
    local f = Angle(0, ang.y or 0, 0):Forward()
    f.z = 0
    local r = Vector(f.y, -f.x, 0)
    return f, r
end

local function CenterOf(t)
    if IsValid(t.ent) then return t.ent.WorldSpaceCenter and t.ent:WorldSpaceCenter() or t.ent:GetPos() end
    return t.pos + Vector(0, 0, 10)
end

-- Size along the thing's own forward and right (a prop's box; a guess for the map's own).
local function SizeOf(t)
    if IsValid(t.ent) and t.ent.OBBMaxs then
        local d = t.ent:OBBMaxs() - t.ent:OBBMins()
        return math.abs(d.x), math.abs(d.y)
    end
    return 36, 36
end

-- The top of whatever's at c (the seat of a chair, a mattress).
local function SurfaceTop(c)
    local tr = util.TraceLine({ start = c + Vector(0, 0, 70), endpos = c - Vector(0, 0, 60), mask = MASK_SOLID or MASK_NPCSOLID })
    if tr and tr.Hit and not tr.StartSolid then return tr.HitPos end
    return nil
end

local function Floor(p)
    local g = LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 30)) or p
    return g
end

local function Standable(p)
    return p and LC.ClearSpot and LC.ClearSpot(p)
end

-- A spot beside something, on the side the NPC is coming from (sv_livingcity_npcwork.lua).
local function Beside(pos, from, d)
    if LC.NPCWorkBeside then return LC.NPCWorkBeside(pos, from, d) end
    local dir = from - pos
    dir.z = 0
    if dir:LengthSqr() < 1 then dir = Vector(1, 0, 0) end
    dir:Normalize()
    return Floor(pos + dir * (d or 48))
end

-- How far from something's middle to stand beside it: clear of its edge.
local function Reach(t, extra)
    if IsValid(t.ent) and t.ent.OBBMaxs then
        local mn, mx = t.ent:OBBMins(), t.ent:OBBMaxs()
        local r = math.max(math.abs(mn.x), math.abs(mx.x), math.abs(mn.y), math.abs(mx.y))
        return math.Clamp(r, 8, 60) + (extra or 20)
    end
    return 30 + (extra or 20)
end

-- Where to sit on a chair, a couch or a bench: in front of it (the side with
-- nothing at backrest height), facing out. Returns a list of { pos, yaw }.
local function SeatSpots(t)
    local c = CenterOf(t)
    local top = SurfaceTop(c)
    if not top then return {} end
    local f, r = AxesOf(t)
    local sx, sy = SizeOf(t)
    local dirs = { f, r, f * -1, r * -1 }
    local depthOf = { sx, sy, sx, sy }
    local blocked = {}
    for i, d in ipairs(dirs) do
        local len = math.max(10, depthOf[i] * 0.5 + 6)
        local s = Vector(c.x, c.y, top.z + 14)
        local tr = util.TraceLine({ start = s, endpos = s + d * len, mask = MASK_SOLID or MASK_NPCSOLID })
        blocked[i] = tr and tr.Hit and tr.Fraction < 0.95 or false
    end
    local front
    for i = 1, 4 do
        local opp = (i + 1) % 4 + 1
        if blocked[i] and not blocked[opp] then front = opp break end
    end
    if not front then
        if blocked[1] or blocked[2] or blocked[3] or blocked[4] then return {} end -- boxed in: not a seat after all
        front = math.random(1, 4) -- a stool, a bench: either way
    end
    local fd = dirs[front]
    local depth = depthOf[front]
    local length = (front % 2 == 1) and sy or sx
    local along = (front % 2 == 1) and r or f
    local yaw = fd:Angle().y
    local out = {}
    local offsets = (t.kind == "couch" or length > 80) and { -length * 0.22, length * 0.22 } or { 0 }
    for _, o in ipairs(offsets) do
        local p = Floor(Vector(c.x, c.y, top.z) + fd * (depth * 0.5 + 6) + along * o)
        if math.abs(p.z - top.z) < 40 then out[#out + 1] = { pos = p, yaw = yaw } end
    end
    return out
end

-- Where to lie on a bed or a mattress: on top, along it, and where to stand
-- up again beside it.
local function BedSpot(t)
    if t.point then
        local p = t.pos
        local f = Angle(0, t.yaw or 0, 0):Forward()
        local side = Vector(f.y, -f.x, 0)
        local stand
        for _, s in ipairs({ 40, -40, 60, -60 }) do
            local g = Floor(p + side * s)
            if math.abs(g.z - p.z) < 64 and Standable(g) then stand = g break end
        end
        return { top = p, yaw = t.yaw or 0, stand = stand }
    end
    local c = CenterOf(t)
    local top = SurfaceTop(c)
    if not top then return nil end
    local f, r = AxesOf(t)
    local sx, sy = SizeOf(t)
    local long, short, half
    if IsValid(t.ent) then
        if sx >= sy then long, short, half = f, r, sy * 0.5 else long, short, half = r, f, sx * 0.5 end
    else
        -- the map's own bed: which way does the top carry on?
        local function hits(d)
            local n = 0
            for _, sgn in ipairs({ 1, -1 }) do
                local q = Vector(c.x, c.y, top.z) + d * (30 * sgn)
                local tr = util.TraceLine({ start = q + Vector(0, 0, 40), endpos = q - Vector(0, 0, 30), mask = MASK_SOLID or MASK_NPCSOLID })
                if tr and tr.Hit and math.abs(tr.HitPos.z - top.z) < 10 then n = n + 1 end
            end
            return n
        end
        if hits(r) > hits(f) then long, short = r, f else long, short = f, r end
        half = 22
    end
    local stand
    for _, sgn in ipairs({ 1, -1 }) do
        local g = Floor(Vector(c.x, c.y, top.z) + short * ((half + 24) * sgn))
        if math.abs(g.z - top.z) < 64 and Standable(g) then stand = g break end
    end
    -- an editor-placed bed: always the same way along it (lc_bed_head_flip turns it round); anything else, either way
    local fixed = IsValid(t.ent) and t.ent:GetClass() == "lc_bed"
    local yaw = long:Angle().y + (fixed and (cvHeadFlip:GetBool() and 180 or 0) or (math.random() < 0.5 and 180 or 0))
    return { top = top, yaw = yaw, stand = stand }
end

LC.RebelBedSpot = BedSpot

------------------------------------------------------------------------
-- Doing things
------------------------------------------------------------------------

local function SetDoing(npc, text) if IsValid(npc) then npc:SetNW2String("lc_doing", text or "") end end

local function HideGun(npc, L, hide)
    local w = npc.GetActiveWeapon and npc:GetActiveWeapon()
    if IsValid(w) and w.SetNoDraw then
        w:SetNoDraw(hide)
        L.gunHidden = hide or nil
    end
end

local function Sound(npc, list, lvl)
    if IsValid(npc) and list then npc:EmitSound(Pick(list), lvl or 60, math.random(95, 105)) end
end

local function Walking(npc) return npc:IsCurrentSchedule(SCHED_FORCED_GO) or npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) end

-- An animation loop where they are (sitting, lying, leaning). moveTo: 1 walk into place, 4 put there.
local function Loop(npc, L, pos, yaw, entry, loop, moveTo)
    if not LC.MakeSequence or not loop then return false end
    local ok, ss = pcall(LC.MakeSequence, npc, pos, yaw, entry or loop, loop, SS_FLAGS, moveTo or 1, 0)
    if not ok or not IsValid(ss) then return false end
    L.ss = ss
    return true
end

local function SeqFor(npc, candidates)
    for _, c in ipairs(candidates) do
        if string.StartWith(c, "ACT_") then
            local n = LC.BusySeqName and LC.BusySeqName(npc, c)
            if n then return n end
        elseif npc.LookupSequence then
            local seq = npc:LookupSequence(c)
            if seq and seq >= 0 then return c end
        end
    end
    return nil
end

-- One of the citizens' sit, bench or lean animations (sv_livingcity.lua).
local function BusyLoop(npc, L, kind, pos, yaw, moveTo)
    local names = LC.BUSY_ACTS and LC.BUSY_ACTS[kind]
    if not names then return false end
    local loop = LC.BusySeqName and LC.BusySeqName(npc, names[2])
    if not loop then return false end
    local entry = LC.BusySeqName(npc, names[1])
    return Loop(npc, L, pos, yaw, entry, loop, moveTo or 1)
end

-- Any NPC lying down on a bed spot b ({ top, yaw }): L.ss is the animation, L.asleep if lying
-- (failing a lying animation, sitting on the bed). True if either. (Citizens at night: sv_livingcity_rest.lua.)
-- No lying-down animation (Half-Life 2's citizens have none: they sat up on the bed, eyes open, through
-- the mattress, the owner's playtest): a still, sleeping copy of them laid flat along the bed instead,
-- their own model, face, clothes and all, eyes shut, while the real one waits out of sight in its place.
local cvLift = CreateConVar("lc_bed_npc_lift", "9", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "How far above a mattress a sleeping NPC's back lies")
local function LieDouble(npc, L, b)
    if not util.IsValidModel or not npc.SetupBones or not npc.LookupBone then return false end
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return false end
    local ok = pcall(function()
        rag:SetModel(npc:GetModel())
        rag:SetSkin(npc:GetSkin() or 0)
        for i = 0, (npc.GetNumBodyGroups and npc:GetNumBodyGroups() or 1) - 1 do rag:SetBodygroup(i, npc:GetBodygroup(i)) end
        rag:SetPos(npc:GetPos())
        rag:SetAngles(Angle(0, npc:GetAngles().y, 0))
        rag:Spawn()
        rag:Activate()
        rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        -- the standing body, turned onto its back along the bed: its height runs head-ward along the bed,
        -- its front faces the ceiling, the hips over the middle
        npc:SetupBones()
        local head = Angle(0, b.yaw or 0, 0):Forward()
        local m = Matrix()
        m:SetForward(Vector(0, 0, 1)) m:SetUp(head) m:SetRight(Vector(0, 0, 1):Cross(head))
        local lieAng = m:GetAngles()
        local pelvis = npc:LookupBone("ValveBiped.Bip01_Pelvis")
        local pp = pelvis and npc:GetBonePosition(pelvis)
        local hipH = pp and (pp.z - npc:GetPos().z) or 38
        local origin = b.top - head * hipH + Vector(0, 0, cvLift:GetFloat())
        local base, baseAng = npc:GetPos(), Angle(0, npc:GetAngles().y, 0)
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local phys = rag:GetPhysicsObjectNum(i)
            local bone = rag:TranslatePhysBoneToBone(i)
            local bpos, bang = npc:GetBonePosition(bone)
            if IsValid(phys) and bpos then
                local lp, la = WorldToLocal(bpos, bang, base, baseAng)
                local wp, wa = LocalToWorld(lp, la, origin, lieAng)
                phys:SetPos(wp)
                phys:SetAngles(wa)
                phys:EnableMotion(false)
            end
        end
    end)
    if not ok then rag:Remove() return false end
    rag:SetNW2Bool("lc_eyes_shut", true)
    rag.lcSleeper = npc
    L.double = rag
    npc:SetNoDraw(true)
    if npc.SetNotSolid then npc:SetNotSolid(true) end
    npc:CallOnRemove("LivingCityBedDouble", function() if IsValid(rag) then rag:Remove() end end)
    return true
end

-- Up again: the copy goes, the real one's back.
function LC.NPCBedDoubleGone(npc, L)
    if not L or not L.double then return end
    if IsValid(L.double) then L.double:Remove() end
    L.double = nil
    if IsValid(npc) then
        npc:SetNoDraw(false)
        if npc.SetNotSolid then npc:SetNotSolid(false) end
        if npc.RemoveCallOnRemove then npc:RemoveCallOnRemove("LivingCityBedDouble") end
    end
end

-- Hurt in their sleep (the copy shot): the real one feels it, and wakes.
hook.Add("EntityTakeDamage", "LivingCityBedDouble", function(ent, dmg)
    local npc = IsValid(ent) and ent.lcSleeper
    if IsValid(npc) and npc:Health() > 0 then npc:TakeDamageInfo(dmg) return true end
end)

function LC.NPCLieOnBed(npc, L, b)
    local seq = SeqFor(npc, LYING)
    local lying = seq ~= nil and Loop(npc, L, b.top + Vector(0, 0, 1), b.yaw, seq, seq, 4)
    -- (the copy lies there; the real one waits under it, a sitting sequence holding it still)
    local double = not lying and LieDouble(npc, L, b)
    local ok = lying or BusyLoop(npc, L, "sit", b.top + Vector(0, 0, 1), b.yaw, 4)
    if double then lying, ok = true, true end
    if not ok then return false end
    L.onBed = true
    L.asleep = lying == true
    HideGun(npc, L, true)
    if L.asleep then
        npc:SetNW2Bool("lc_eyes_shut", true)
        if not L.double then timer.Simple(0.6, function() SettleOnBed(npc, L, b.top.z) end) end
    end
    return true
end

local function End(npc, st)
    local L = st and st.life
    if not L then return end
    st.life = nil
    if L.key and claims[L.key] == npc then claims[L.key] = nil end
    if L.key2 and claims[L.key2] == npc then claims[L.key2] = nil end
    if L.point and LC.Release then LC.Release(npc, st) end
    if IsValid(L.ss) then
        L.ss:Fire("CancelSequence")
        SafeRemoveEntityDelayed(L.ss, 0.5)
    end
    LC.NPCBedDoubleGone(npc, L)
    if IsValid(npc) then
        if L.gunHidden then HideGun(npc, L, false) end
        if st.carry and LC.NPCDropCarry then LC.NPCDropCarry(npc, st) end
        if L.onBed and L.standAt then npc:SetPos(L.standAt + Vector(0, 0, 4)) end -- (up, and off the bed)
        if L.asleep then npc:SetNW2Bool("lc_eyes_shut", false) end
        SetDoing(npc, "")
        if Walking(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
    end
    st.goingTo = nil
    if st.state == "busy" or st.state == "moving" then LC.SetState(npc, st, "idle") end
end
LC.RebelLifeEnd = End

function LC.RebelAsleep(st) return st and st.life and st.life.asleep == true or false end

local function Claim(npc, L, key)
    if not key then return true end
    if not Free(key, npc) then return false end
    claims[key] = npc
    if not L.key then L.key = key else L.key2 = key end
    return true
end

-- Start an activity: a list of steps, each "go there, then do this for a while".
local function Start(npc, st, now, kind, steps, extra)
    for _, s in ipairs(steps) do
        if s.key and not Free(s.key, npc) then return false end
    end
    local L = extra or {}
    for _, s in ipairs(steps) do if s.key then Claim(npc, L, s.key) end end
    L.kind, L.steps, L.i, L.phase = kind, steps, 1, "go"
    L.giveUp = now + 30
    st.life = L
    return true
end

local function StepSecs(s)
    if type(s.secs) == "table" then return math.Rand(s.secs[1], s.secs[2]) end
    return s.secs or 5
end

local function Finish(npc, st, now)
    End(npc, st)
    st.untilT = now + math.Rand(2, 6)
end

local function RunLife(npc, st, L, now)
    local s = L.steps[L.i]
    if not s then Finish(npc, st, now) return true end
    local pos = npc:GetPos()
    if L.phase == "go" then
        SetDoing(npc, s.going or s.doing or L.doing)
        local near = s.near or 48
        if pos:DistToSqr(s.at) < near * near or (s.direct and pos:DistToSqr(s.at) < 160 * 160 and now > (L.goSince or now) + 6) then
            if Walking(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
            st.goingTo = nil
            L.phase = "do"
            L.untilT = now + StepSecs(s)
            L.nextAnim = now + 0.4
            if s.face then LC.Face(npc, s.face) elseif s.yaw then LC.FaceYaw(npc, s.yaw) end
            LC.SetState(npc, st, "busy")
            SetDoing(npc, s.doing or L.doing)
            if s.onArrive and s.onArrive(npc, st, L, s, now) == false then Finish(npc, st, now) return true end
            return true
        end
        if now > L.giveUp then Finish(npc, st, now) return true end -- (can't get there)
        L.goSince = L.goSince or now
        LC.SetState(npc, st, "moving")
        LC.RebelHeadFor(npc, st, s.at, s.run)
        return true
    end
    -- doing it
    if s.anim and now >= (L.nextAnim or 0) then
        L.nextAnim = now + (s.every or 3.5)
        if LC.PlayGesture then LC.PlayGesture(npc, s.anim, 3) end
        if s.sound then Sound(npc, s.sound, s.lvl) end
    end
    if s.tick then s.tick(npc, st, L, s, now) end
    if now < L.untilT then return true end
    if s.onDone and s.onDone(npc, st, L, s, now) == false then Finish(npc, st, now) return true end
    if st.life ~= L then return true end
    L.i = L.i + 1
    if not L.steps[L.i] then Finish(npc, st, now) return true end
    L.phase, L.goSince = "go", nil
    L.giveUp = now + 30
    return true
end

------------------------------------------------------------------------
-- The activities
------------------------------------------------------------------------

local A = {}

-- A walk round the edge of the zone, looking out at each stop.
function A.patrol(npc, st, z, now)
    local steps = {}
    local n = math.random(3, 5)
    local base = math.random() * math.pi * 2
    for i = 1, n do
        local spot, cramped
        for _ = 1, 6 do
            local a = base + (i - 1) * (math.pi * 2 / n) + math.Rand(-0.3, 0.3)
            local p = z.pos + Vector(math.cos(a), math.sin(a), 0) * z.r * math.Rand(0.55, 0.78)
            local g = Floor(p + Vector(0, 0, 40))
            if g and LCZ.Contains(z, g, -30) and math.abs(g.z - z.pos.z) < (z.h or 160) and Standable(g) then
                -- (a stop with room round it first: not in a doorway, the owner, 7 November)
                if not LC.RoomAround or LC.RoomAround(g) then spot = g break end
                cramped = cramped or g
            end
        end
        spot = spot or cramped or (LC.RoomySpot and LC.RoomySpot(z)) or LC.SpotInZone(z)
        if spot then
            local out = spot - z.pos
            out.z = 0
            if out:LengthSqr() < 1 then out = Vector(1, 0, 0) end
            out:Normalize()
            steps[#steps + 1] = { at = spot, face = spot + out * 400, secs = { 3, 7 }, doing = "on patrol", near = 60, direct = true }
        end
    end
    if #steps < 2 then return false end
    return Start(npc, st, now, "patrol", steps, { doing = "on patrol" })
end

-- At a workbench or the camp table.
function A.work(npc, st, z, now, t)
    local at = Beside(t.pos, npc:GetPos(), Reach(t, 18))
    if not Standable(at) then return false end
    local doing = t.kind == "table" and Pick({ "cleaning a gun", "going over a map", "fixing something" }) or Pick({ "working at the bench", "fixing a gun", "making something" })
    return Start(npc, st, now, "work", { { at = at, face = t.pos, secs = { 25, 60 }, doing = doing, anim = BENCH, sound = TOOLS, every = 4, key = t.key, direct = true } })
end

-- Going through a crate.
function A.sort(npc, st, z, now, t)
    local at = Beside(t.pos, npc:GetPos(), Reach(t, 16))
    if not Standable(at) then return false end
    return Start(npc, st, now, "sort", { { at = at, face = t.pos, secs = { 12, 30 }, doing = Pick({ "going through the crates", "checking the supplies", "counting rounds" }),
        anim = { "ACT_PICKUP_GROUND", "ACT_PICKUP_RACK", "ACT_COVER_LOW" }, sound = CRATE, every = 3.5, key = t.key, direct = true } })
end

-- Tending a pot.
function A.garden(npc, st, z, now, t)
    local at = Beside(t.pos, npc:GetPos(), Reach(t, 16))
    if not Standable(at) then return false end
    return Start(npc, st, now, "garden", { { at = at, face = t.pos, secs = { 15, 30 }, doing = "tending the garden", anim = CROUCH, sound = DIRT, every = 4, key = t.key, direct = true } })
end

-- A box from one crate to somewhere else.
function A.carry(npc, st, z, now, t, things)
    local dests = {}
    for _, o in ipairs(things) do
        if o ~= t and (o.kind == "crate" or o.kind == "bench" or o.kind == "table") and o.pos:DistToSqr(t.pos) > 150 * 150 then dests[#dests + 1] = o end
    end
    local to = #dests > 0 and Pick(dests) or nil
    local toAt = to and Beside(to.pos, t.pos, Reach(to, 16)) or LC.SpotInZone(z)
    local at = Beside(t.pos, npc:GetPos(), Reach(t, 16))
    if not toAt or not Standable(at) then return false end
    local steps = {
        { at = at, face = t.pos, secs = 2, doing = "fetching supplies", anim = CROUCH, every = 5, sound = CRATE, key = t.key, direct = true,
          onDone = function(n, s, L)
              HideGun(n, L, true)
              if LC.NPCCarry then LC.NPCCarry(n, s, Pick(BOXES)) end
          end },
        { at = toAt, face = to and to.pos or nil, secs = 2, going = "carrying supplies", doing = "putting it down", anim = REACH, every = 5, sound = CRATE, direct = true,
          onDone = function(n, s, L)
              if LC.NPCDropCarry then LC.NPCDropCarry(n, s) end
              HideGun(n, L, false)
          end },
    }
    return Start(npc, st, now, "carry", steps)
end

-- Sitting round the fire.
function A.fire(npc, st, z, now, t)
    for slot = 1, 3 do
        local key = t.key .. "_" .. slot
        if Free(key, npc) then
            local a = math.rad(slot * 120 + math.random(-20, 20))
            local spot = Floor(t.pos + Vector(math.cos(a), math.sin(a), 0) * 62 + Vector(0, 0, 30))
            if Standable(spot) and math.abs(spot.z - t.pos.z) < 40 and not (LC.InWalkway and LC.InWalkway(spot, 16))
                and not (LC.InWater and LC.InWater(spot)) then
                local yaw = (t.pos - spot):Angle().y
                return Start(npc, st, now, "fire", { { at = spot, near = 70, yaw = yaw, secs = { 40, 100 }, doing = "warming up by the fire", key = key, direct = true,
                    onArrive = function(n, s, L)
                        if not BusyLoop(n, L, "sit", spot, yaw) then return true end -- (no sitting down: standing by it does)
                        HideGun(n, L, true)
                    end } })
            end
        end
    end
    return false
end

-- On a chair, a couch, a bench.
function A.sit(npc, st, z, now, t)
    for i, sp in ipairs(SeatSpots(t)) do
        local key = t.key .. "_" .. i
        if Free(key, npc) and Standable(sp.pos) then
            return Start(npc, st, now, "sit", { { at = sp.pos, near = 70, yaw = sp.yaw, secs = { 30, 90 }, doing = Pick({ "taking a break", "resting", "sitting down" }), key = key, direct = true,
                onArrive = function(n, s, L)
                    if not BusyLoop(n, L, "sitchair", sp.pos, sp.yaw) then return false end
                    HideGun(n, L, true)
                end } })
        end
    end
    return false
end

-- The editor's sit, bench and lean points inside the zone.
function A.point(npc, st, z, now, t)
    local p = t.point
    if not p or not (LC.IsPointFree and LC.IsPointFree(p, npc)) then return false end
    local ok = Start(npc, st, now, "point", { { at = p.pos, near = 70, yaw = p.yaw or 0, secs = { 30, 80 }, doing = p.kind == "lean" and "leaning on the wall" or "resting", direct = true,
        onArrive = function(n, s, L)
            if not BusyLoop(n, L, p.kind, p.pos, p.yaw or 0) then return false end
            if p.kind ~= "lean" then HideGun(n, L, true) end
        end } }, { point = p })
    if ok and LC.Claim then LC.Claim(npc, st, p) end
    return ok
end

-- Sleeping on a mattress, a bed, a bunk.
function A.sleep(npc, st, z, now, t)
    local b = BedSpot(t)
    if not b then return false end
    local night = LC.IsNight and LC.IsNight()
    local stand = b.stand or Beside(b.top, npc:GetPos(), 40)
    return Start(npc, st, now, "sleep", { { at = stand, near = 60, face = b.top, secs = night and { 150, 360 } or { 60, 180 }, doing = "asleep", going = "turning in", key = t.key, direct = true,
        onArrive = function(n, s, L)
            L.standAt = n:GetPos()
            local seq = SeqFor(n, LYING)
            local lying = seq ~= nil and Loop(n, L, b.top + Vector(0, 0, 1), b.yaw, seq, seq, 4)
            local ok = lying or BusyLoop(n, L, "sit", b.top + Vector(0, 0, 1), b.yaw, 4) -- (no lying down in this model: sitting on the bed, then)
            if not ok then return false end
            L.onBed = true
            L.asleep = lying == true
            SetDoing(n, L.asleep and "asleep" or "resting")
            HideGun(n, L, true)
            if L.asleep then
                n:SetNW2Bool("lc_eyes_shut", true) -- (eyes closed: cl_livingcity_rest.lua)
                timer.Simple(0.6, function() SettleOnBed(n, L, b.top.z) end)
            end
        end } })
end

-- One activity in particular (for tests, and anything that wants a fighter at something).
function LC.RebelLifeDo(npc, st, kind, t)
    local fn = A[kind]
    if not fn or not st or not st.zone then return false end
    if st.life then End(npc, st) end
    return fn(npc, st, st.zone, CurTime(), t, ZoneThings(st.zone)) == true
end

-- Just milling about: the old wander (sv_livingcity_rebels.lua).
local MILL = "mill"

local function Choose(npc, st, now)
    local z = st.zone
    local things = ZoneThings(z)
    local night = LC.IsNight and LC.IsNight() or false
    local home, patrolling = 0, 0
    for n, s in pairs(LC.NPCs) do
        if s.role == "rebel" and s.zone == z and IsValid(n) and not s.raid and not s.follow and not s.errand and not s.post and not s.quartermaster then
            home = home + 1
            if s.life and s.life.kind == "patrol" and n ~= npc then patrolling = patrolling + 1 end
        end
    end
    local opts = {}
    local function opt(w, fn, t) if w > 0 then opts[#opts + 1] = { w = w, fn = fn, t = t } end end
    opt((patrolling == 0 and home >= 2) and 70 or (patrolling < 2 and home >= 4 and 14 or 0), A.patrol)
    for _, t in ipairs(things) do
        if Free(t.key, npc) or t.kind == "fire" or t.kind == "couch" or t.kind == "seat" then
            local k = t.kind
            if k == "bench" then opt(16, A.work, t)
            elseif k == "table" then opt(8, A.work, t)
            elseif k == "crate" then opt(7, A.sort, t) opt(5, A.carry, t)
            elseif k == "pot" then opt(7, A.garden, t)
            elseif k == "fire" then opt(night and 22 or 12, A.fire, t)
            elseif k == "bed" or k == "bunk" then opt(night and 40 or 5, A.sleep, t)
            elseif k == "seat" or k == "couch" then opt(night and 6 or 10, A.sit, t)
            elseif k == "point" then opt(10, A.point, t) end
        end
    end
    opt(12, MILL)
    for _ = 1, 5 do
        if #opts == 0 then return false end
        local total = 0
        for _, o in ipairs(opts) do total = total + o.w end
        local r = math.random() * total
        local pick = opts[#opts]
        for _, o in ipairs(opts) do
            r = r - o.w
            if r <= 0 then pick = o break end
        end
        if pick.fn == MILL then return false end
        local ok, started = pcall(pick.fn, npc, st, z, now, pick.t, things)
        if not ok and LC.Error then LC.Error("rebel life", started) end
        if ok and started then return true end
        for i, o in ipairs(opts) do if o == pick then table.remove(opts, i) break end end
    end
    return false
end

-- Called from the rebels' own think (sv_livingcity_rebels.lua) when they're
-- at home with nothing else on. True: handled.
function LC.RebelLifeThink(npc, st, now)
    if not st.zone or not cvLife:GetBool() or st.test then
        if st.life then End(npc, st) end
        return false
    end
    -- the zone's on alert: on their feet, facing the trouble
    local alert = LC.RebelZoneAlert and LC.RebelZoneAlert(st.zone)
    if alert then
        if st.life then End(npc, st) end
        if now > (st.alertFaceT or 0) then
            st.alertFaceT = now + 2
            if Walking(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
            if alert.pos then LC.Face(npc, alert.pos) end
            SetDoing(npc, "on alert")
        end
        return true
    elseif st.alertFaceT then
        st.alertFaceT = nil
        SetDoing(npc, "")
    end
    local L = st.life
    if not L then
        if st.state == "moving" or now < (st.untilT or 0) then return false end
        if not Choose(npc, st, now) then return false end
        L = st.life
        if not L then return false end
    end
    return RunLife(npc, st, L, now)
end

hook.Add("OnNPCKilled", "LivingCityRebelLife", function(npc)
    local st = LC.NPCs[npc]
    if st and st.life then End(npc, st) end
end)
hook.Add("EntityRemoved", "LivingCityRebelLife", function(e)
    local st = LC.NPCs and LC.NPCs[e]
    if not st or st.role ~= "rebel" then return end
    if st.life then
        local L = st.life
        st.life = nil
        if IsValid(L.ss) then L.ss:Remove() end
    end
    if IsValid(st.carry) then st.carry:Remove() st.carry = nil end
end)

------------------------------------------------------------------------
-- Scavenging runs
------------------------------------------------------------------------

local nextErrand = setmetatable({}, { __mode = "k" }) -- [zone] = time
local function Interval() return math.max(0.25, cvErrandM:GetFloat()) * 60 * math.Rand(0.7, 1.3) end
local lastHaulRadio = 0

-- Somewhere to scavenge, out in the streets within reach of the zone.
local function ScavengeSpot(z)
    local cands = {}
    local function consider(p)
        if not p then return end
        local d = p:Distance(z.pos)
        if d > z.r + 250 and d < z.r + 2600 and not LC.InRebelZone(p) and not (LC.InNoGo and LC.InNoGo(p, "citizen")) then cands[#cands + 1] = p end
    end
    for _, s in ipairs(LC.StaticBins or {}) do consider(s.pos) end
    for _, s in ipairs(LC.StaticJunk or {}) do consider(s.pos) end
    for _, k in ipairs({ "bin", "salvage", "rubble", "citybin" }) do
        for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind(k) or {}) do consider(p.pos) end
    end
    if #cands == 0 then
        for _ = 1, 15 do consider(LC.RandomWanderPos and LC.RandomWanderPos("citizen", z.pos)) end
    end
    if #cands == 0 then return nil end
    -- somewhere no unit is standing, if there's a choice
    local quiet = {}
    for _, p in ipairs(cands) do
        local busy = false
        for n, s in pairs(LC.NPCs) do
            if IsValid(n) and LC.IsSecurity(s) and n:GetPos():DistToSqr(p) < 900 * 900 then busy = true break end
        end
        if not busy then quiet[#quiet + 1] = p end
    end
    local target = Pick(#quiet > 0 and quiet or cands)
    return Beside(target, z.pos, 48), target
end

-- The nearest unit a rebel out in the open can see (or a convincing uniform).
local function UnitNear(npc, range)
    local pos = npc:GetPos()
    local best, bd
    for n, s in pairs(LC.NPCs) do
        if IsValid(n) and (LC.IsSecurity(s) or s.role == "scanner") and n:Health() > 0 then
            local d = n:GetPos():DistToSqr(pos)
            if d < range * range and (not bd or d < bd) and LC.RebelCanSee(npc, n, range) then best, bd = n, d end
        end
    end
    for _, p in ipairs(player.GetAll()) do
        local d = p:GetPos():DistToSqr(pos)
        if d < range * range and (not bd or d < bd) and LC.RebelLooksCombine(p) and LC.RebelCanSee(npc, p, range) then best, bd = p, d end
    end
    return best
end

local function Stalled(npc, E, now, secs)
    local pos = npc:GetPos()
    if not E.lastPos or pos:DistToSqr(E.lastPos) > 40 * 40 then E.lastPos, E.lastMoved = pos, now end
    return now - (E.lastMoved or now) > secs
end

local function StartErrand(z, now)
    now = now or CurTime()
    local home = {}
    for n, s in pairs(LC.NPCs) do
        if IsValid(n) and n:Health() > 0 and s.role == "rebel" and s.zone == z and not s.foe and not s.raid and not s.follow and not s.post
            and not s.quartermaster and not s.errand and not s.returning and not s.test and s.state ~= "event" and not LC.RebelAsleep(s) then
            home[#home + 1] = n
        end
    end
    if #home < 3 then return false, "fewer than three fighters at home" end
    local dest, target = ScavengeSpot(z)
    if not dest then return false, "nowhere to scavenge" end
    local count = (#home >= 4 and math.random() < 0.5) and 2 or 1
    for i = #home, 2, -1 do local j = math.random(i) home[i], home[j] = home[j], home[i] end
    for i = 1, count do
        local npc = home[i]
        local st = LC.NPCs[npc]
        End(npc, st)
        st.errand = { dest = dest + Vector(i == 2 and 40 or 0, i == 2 and 30 or 0, 0), look = target, phase = "out", started = now,
            giveUp = now + 300, hides = 0, zone = z }
        st.unmanaged = true -- (someone else holds the fort while they're out)
        st.untilT = 0
        st.goingTo = nil
        SetDoing(npc, "out scavenging")
    end
    LC.Log("info", string.format("Rebel scavenging run: %d out of %s toward %s", count, tostring(z.pos), tostring(dest)))
    return true
end
LC.StartRebelErrand = StartErrand

-- Called off (asked along, sent on a raid) or in a fight: the box goes down, the gun comes out.
function LC.RebelErrandDrop(npc, st)
    local E = st and st.errand
    if not E then return end
    if IsValid(npc) and LC.NPCDropCarry then LC.NPCDropCarry(npc, st) end
    if E.gunHidden and IsValid(npc) then HideGun(npc, E, false) end
    E.found = 0
end

function LC.RebelErrandEnd(npc, st)
    if not st or not st.errand then return end
    LC.RebelErrandDrop(npc, st)
    st.errand = nil
    SetDoing(npc, "")
end

local function Deliver(npc, st, E, now)
    if IsValid(npc) then
        if LC.NPCDropCarry then LC.NPCDropCarry(npc, st) end
        if E.gunHidden then HideGun(npc, E, false) end
    end
    local found = E.found or 0
    if found <= 0 then return end
    local rp = LC.RebelProps and LC.RebelProps[st.zone]
    local cache = rp and rp.cache
    local added = IsValid(cache) and LC.AddToCache and LC.AddToCache(cache, found) or 0
    if added > 0 and now > lastHaulRadio + 300 and LC.RadioNotice then
        lastHaulRadio = now
        LC.RadioNotice("resistance", string.format("%s is back from a scavenging run: %d meal%s for the stores.", npc:GetNW2String("lc_pname", "One of ours"), added, added == 1 and "" or "s"))
    end
    hook.Run("LivingCityRebelHaul", npc, found)
end

-- Called from the rebels' own think. True: handled.
function LC.RebelErrandThink(npc, st, now)
    local E = st.errand
    if not E then return false end
    local z = st.zone
    if not z then st.errand = nil return false end
    local pos = npc:GetPos()
    if (E.aborted or now > E.giveUp) and E.phase ~= "home" then E.phase = "home" end

    -- keeping out of sight: a unit close and in view, and they back off and wait it out
    if E.phase ~= "home" or not E.aborted then
        local u = UnitNear(npc, E.phase == "search" and 700 or 900)
        if u and now >= (E.hideUntil or 0) then
            if E.phase == "search" then E.phase = "home" end -- (spooked: what they have, home)
            E.hides = E.hides + 1
            if E.hides > 3 then E.phase = "home" end -- too hot out there
            local away = pos - u:GetPos()
            away.z = 0
            if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
            away:Normalize()
            local spot = Floor(pos + away * 280)
            E.hideAt = Standable(spot) and spot or nil
            E.hideUntil = now + math.Rand(6, 10)
            E.lastPos = nil
            SetDoing(npc, "keeping out of sight")
        end
        if E.hideUntil and now >= E.hideUntil then E.hideUntil, E.lastPos = nil, nil end -- (out again)
        if now < (E.hideUntil or 0) then
            if E.hideAt and pos:DistToSqr(E.hideAt) > 60 * 60 and not Stalled(npc, E, now, 4) then
                LC.RebelHeadFor(npc, st, E.hideAt, true)
            elseif Walking(npc) then
                npc:SetSchedule(SCHED_IDLE_STAND)
                st.goingTo = nil
            end
            return true
        end
    end

    if E.phase == "out" then
        SetDoing(npc, "out scavenging")
        LC.SetState(npc, st, "moving")
        if pos:DistToSqr(E.dest) < 80 * 80 or (pos:DistToSqr(E.dest) < 200 * 200 and Stalled(npc, E, now, 5)) then
            E.phase = "search"
            E.untilT = now + math.Rand(10, 20)
            E.nextAnim = now + 0.3
            if Walking(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
            st.goingTo = nil
            LC.Face(npc, E.look or E.dest)
        elseif Stalled(npc, E, now, 15) then
            E.phase = "home" -- (no way through)
        else
            LC.RebelHeadFor(npc, st, E.dest, false)
        end
        return true
    elseif E.phase == "search" then
        SetDoing(npc, "scavenging")
        LC.SetState(npc, st, "busy")
        if now >= (E.nextAnim or 0) then
            E.nextAnim = now + 3.5
            if LC.PlayGesture then LC.PlayGesture(npc, CROUCH, 3) end
            Sound(npc, CRATE, 55)
        end
        if now >= E.untilT then
            E.found = math.random() < 0.75 and math.random(1, 2) or 0
            if E.found > 0 then
                HideGun(npc, E, true)
                if LC.NPCCarry then LC.NPCCarry(npc, st, Pick(BOXES)) end
            end
            E.phase = "home"
            E.lastPos = nil
        end
        return true
    end

    -- home, with whatever they found
    SetDoing(npc, (E.found or 0) > 0 and "bringing back what they found" or "heading home")
    LC.SetState(npc, st, "moving")
    if pos:DistToSqr(z.pos) < (z.r * 0.7) ^ 2 or (E.homeSpot and pos:DistToSqr(E.homeSpot) < 90 * 90 and LCZ.Contains(z, pos, 0)) then
        Deliver(npc, st, E, now)
        st.errand = nil
        st.expires = now + 60 -- (an extra came while they were out: one of them slips away later, unseen)
        SetDoing(npc, "")
        if Walking(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
        st.goingTo = nil
        LC.SetState(npc, st, "idle")
        st.untilT = now + math.Rand(3, 8)
        return true
    end
    E.homeSpot = E.homeSpot or LC.SpotInZone(z) or z.pos
    LC.RebelHeadFor(npc, st, E.homeSpot, E.aborted == true)
    -- stuck on the way, with nobody watching: home all the same
    if Stalled(npc, E, now, 20) and not LC.IsSeen(pos + UP) and not LC.IsSeen(E.homeSpot + UP) then
        npc:SetPos(E.homeSpot + Vector(0, 0, 4))
        E.lastPos = nil
    end
    return true
end

timer.Create("LivingCityRebelErrands", 5, 0, function()
    local ok, err = pcall(function()
        if not LC.Running or not cvErrands:GetBool() or #player.GetAll() == 0 then return end
        local now = CurTime()
        for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
            if not z.grown and (not LC.RebelIsLeader or LC.RebelIsLeader(z)) then -- (one territory, one run at a time)
                local t = nextErrand[z]
                if not t then
                    nextErrand[z] = now + Interval() * math.Rand(0.3, 1)
                elseif now >= t then
                    nextErrand[z] = now + Interval()
                    if LC.Event ~= "lockdown" and not (LC.RebelZoneAlert and LC.RebelZoneAlert(z)) and not (LC.Skirmish and LC.Skirmish.zone == z) then
                        StartErrand(z, now)
                    end
                end
            end
        end
    end)
    if not ok and LC.Error then LC.Error("rebel errands", err) end
end)

concommand.Add("lc_rebel_errand", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if not LC.Running then return Say(ply, "[Living City] Start the city first.") end
    local from = IsValid(ply) and ply:GetPos() or Vector(0, 0, 0)
    local best, bd
    for _, z in ipairs(LC.ZonesOfKind and LC.ZonesOfKind("rebel") or {}) do
        local d = z.pos:DistToSqr(from)
        if not bd or d < bd then best, bd = z, d end
    end
    if not best then return Say(ply, "[Living City] No rebel territory on this map.") end
    local ok, why = StartErrand(best)
    Say(ply, ok and "[Living City] A scavenging run is heading out of the nearest rebel zone." or ("[Living City] Couldn't send one: " .. tostring(why)))
end)

hook.Add("LivingCityStopped", "LivingCityRebelLife", function()
    claims = {}
    nextErrand = setmetatable({}, { __mode = "k" })
end)
