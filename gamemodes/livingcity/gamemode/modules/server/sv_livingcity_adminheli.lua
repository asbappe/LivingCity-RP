--[[
    Living City: the Administrator's attack helicopter

    The owner, 16 November: "an alternative to the APC: An attack helicopter is
    landed/parked nearby with the rotors off; upon assassination attempt, the
    administrator is quickly escorted to the attack helicopter, its rotors turn on
    and it flies the administrator as close as it can to the 'Administrator' door
    entity/point (marked in the editor tool) and she spawns right in front. This
    also could be used to pick her up when she is going to give a speech: she stands
    outside her administrator door and the helicopter flies in out of the far
    reaches of the skybox, hovers as close as it can without colliding with
    everything to her, then she is teleported inside the helicopter and then the
    helicopter goes on to the helicopter landing point next to the speech, and she
    gets out to give her speech."

    The point  the editor's "Point: Administrator's helicopter" (kind adminheli), by
               the speech stand (as near as the APC's point has to be), facing the
               way the helicopter is to face.
    Parked     for as long as an address lasts it stands on its point, rotors still,
               silent. It goes when the address ends.
    The exit   an attempt on her life (sv_livingcity_adminsecurity.lua): the ring
               runs her to it as it runs her to the APC, she is put aboard, the
               rotors start, it lifts, flies over the rooftops to the open sky
               nearest her office door, comes down as low and as near the door as it
               can without touching the world, and she stands in front of her door.
               Badly hit (a close call) she is set down inside her office instead,
               where she faints, as after the shield run. It climbs away and is gone.
    The ride   a player Administrator who calls her address from outside her office
               door is fetched: it comes in from the edge of the sky, hovers by her,
               she is aboard, it flies to its point and sets down, the rotors stop,
               and she is on her feet beside it, facing the stand. Her address does
               not speak before that. If any of it fails she is put there at once.
    Never      an NPC: a prop moved by script along a way checked with traces. It
               attacks nobody, needs no track, and in the air nothing collides with it.

    Nothing here is said to anyone in words: the helicopter is the news.
]]

if CLIENT then return end

LC = LC or {}

local HELI_MODEL = "models/combine_helicopter.mdl"
local HELI_YAW = 0          -- the model's nose against the way its point faces (to turn it: this number)
-- An APC and a helicopter both by the stand: the helicopter takes her, the APC stands by. (The owner has not
-- said which: false here and it is the APC, the helicopter standing by.)
local HELI_FIRST = true
local ROTOR_SOUND = "npc/attack_helicopter/aheli_rotor_loop1.wav"
local ROTOR_SEQS = { "idle", "Idle", "idle01" } -- the model's own sequence that turns its rotors: the first of these it has
local DOOR_SOUND = "doors/door_metal_medium_close1.wav"
local BOARD_OUT = 110       -- she boards, and is set down, this far out from its right side
local SEAT = Vector(0, 0, -30) -- where she rides, from the model's middle (her eyes are 64 above her feet)
local SPIN_SECS = 1.2       -- the rotors turn this long before it lifts
local HOVER_SECS = 1.5      -- it hovers this long by her door before she is set down
local BOARD_SECS = 1        -- and this long by her before she is aboard
local LIFT_SPEED = 380      -- units a second, up and down
local FLY_SPEED = 950       -- and across
local TURN_SPEED = 120      -- degrees a second
local SKY_FAR = 16000       -- the sky is looked for this far up
local SKY_GAP = 48          -- it keeps this far under the sky
local SKY_NONE = 1800       -- (no ceiling found at all: this far up is taken for it)
local CRUISE = 900          -- it flies this far above where it stands (over the rooftops), where the sky allows
local CRUISE_STEP = 350     -- and this much higher at a time when the way is not clear at that height
local CLIMB_LEAST = 350     -- with less sky than this above it, it does not fly
local LIFT_CLEAR = 24       -- (its way up is checked from this far off the ground)
local HOVER_FEET = 140      -- hovering, its belly is this far above her floor at the lowest
local HOVER_OFF = 32        -- and this far off whatever it met coming down
local HOVER_REACH = 2400    -- open sky is looked for this far round her door (or her)
local HOVER_STEP = 160
local FAR_OUT = 12000       -- it comes in from, and leaves for, the edge of the sky: this far at most
local FAR_LEAST = 700       -- (nearer than this is no edge: it comes straight down, or goes straight up)
local DOOR_REACH = 400      -- she is "at her door" within this of it, on the side away from her desk
local DOOR_FRONT = 56       -- she is set down this far in front of it
local RIDE_MAX = 75         -- the ride to the stand takes this long at most: then she is simply put there
local EXIT_MAX = 60         -- the flight out, the same
local SPEAK_AFTER = 6       -- her address speaks no sooner than this after she is on her feet

local P            -- the helicopter parked for an address: { ent, pt, S (its address; nil: kept for the exit under way) }
local R            -- her ride to the stand under way: { her, S, pt, ent, f, t0 }
local Out          -- the one the exit took (A.heli, sv_livingcity_adminsecurity.lua)
local making       -- (the one being made for a ride, until it is known the ride can be flown)
local Flights = {} -- helicopters flying off by themselves
local Seated = {}  -- [her] = what was changed on her when she was put aboard

function LC.AdminHeli() return { parked = P, ride = R, out = Out, flights = Flights, seated = Seated } end

local function Kit() return LC.AdminExfilKit or {} end -- (what the exit lends: sv_livingcity_adminsecurity.lua)
local function ModelOK() return not util.IsValidModel or util.IsValidModel(HELI_MODEL) end
local function Ground(p) return (LC.GroundAt and LC.GroundAt(p + Vector(0, 0, 40))) or p end
local function Note(err) if LC.Error then LC.Error("admin helicopter", err) end end

------------------------------------------------------------------------
-- The world, by traces: where the sky is, and where it can fly without touching anything
------------------------------------------------------------------------

local function Line(a, b, skip)
    return util.TraceLine({ start = a, endpos = b, mask = MASK_SOLID_BRUSHONLY, filter = skip })
end
local function Box(a, b, box, skip)
    return util.TraceHull({ start = a, endpos = b, mins = box.mins, maxs = box.maxs, mask = MASK_SOLID_BRUSHONLY, filter = skip })
end
-- The whole of it fits along the way from a to b.
local function Clear(a, b, box, skip)
    local tr = Box(a, b, box, skip)
    return not (tr and (tr.Hit or tr.StartSolid))
end

-- The height of the sky straight above a spot: nil under a roof.
local function SkyOver(pos, skip)
    local tr = Line(pos + Vector(0, 0, 8), pos + Vector(0, 0, SKY_FAR), skip)
    if not tr or tr.StartSolid then return nil end
    if not tr.Hit then return pos.z + SKY_NONE end
    return tr.HitSky and tr.HitPos.z or nil
end

-- The room it takes: a box round its middle wide enough for its rotor whichever way it faces (slim: its body
-- only, for going straight up and down over its own point, which the owner chose).
local function HullOf(ent)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local r = math.Clamp(math.max(-mins.x, maxs.x, -mins.y, maxs.y), 220, 460)
    local down, up = math.Clamp(-mins.z, 40, 220), math.Clamp(maxs.z, 60, 260)
    local s = r * 0.5
    return { r = r, down = down, up = up, mins = Vector(-r, -r, -down), maxs = Vector(r, r, up),
        slim = { mins = Vector(-s, -s, -down), maxs = Vector(s, s, up) } }
end

-- Standing on its point: its belly on the ground.
local function Rest(pt, hull)
    local g = Ground(pt.pos)
    return Vector(g.x, g.y, g.z + hull.down + 2)
end

-- The heights it may fly at from where it stands: over the rooftops, then higher, at most just under the sky.
local function Heights(from, hull, skip)
    local sky = SkyOver(from, skip)
    if not sky then return {} end
    local top = sky - hull.up - SKY_GAP
    local out = {}
    local z = from.z + CRUISE
    while z < top and #out < 3 do
        out[#out + 1] = z
        z = z + CRUISE_STEP
    end
    if top >= from.z + CLIMB_LEAST then out[#out + 1] = top end
    return out
end

-- The column of open sky over a spot: its top (at the height it flies at) and how low the helicopter can come
-- down it without touching the world (never lower than HOVER_FEET over the floor it is wanted at). Nil where
-- the top is not out in the open under the sky.
local function Column(x, y, floorZ, flyZ, hull, skip)
    local top = Vector(x, y, flyZ)
    if util.IsInWorld and not util.IsInWorld(top) then return nil end
    local up = Line(top, top + Vector(0, 0, SKY_FAR), skip)
    if up and (up.StartSolid or (up.Hit and not up.HitSky)) then return nil end
    local low = Vector(x, y, math.min(flyZ, floorZ + hull.down + HOVER_FEET))
    local tr = Box(top, low, hull, skip)
    if tr and tr.StartSolid then return nil end
    local z = low.z
    if tr and tr.Hit then z = math.min(flyZ, top.z + (low.z - top.z) * (tr.Fraction or 0) + HOVER_OFF) end
    return Vector(x, y, z), top
end

-- The open sky nearest a spot: where it hovers (as low and as near as it gets) and the top of its way down.
-- from: where it comes from at that height: the way between has to be clear.
local function HoverNear(spot, flyZ, hull, from, skip)
    local best, bestTop, bd
    local function Try(x, y)
        local hover, top = Column(x, y, spot.z, flyZ, hull, skip)
        if not hover then return end
        local d = hover:DistToSqr(spot)
        if bd and d >= bd then return end
        if from and not Clear(from, top, hull, skip) then return end
        best, bestTop, bd = hover, top, d
    end
    Try(spot.x, spot.y)
    for ring = 1, math.floor(HOVER_REACH / HOVER_STEP) do
        local r = ring * HOVER_STEP
        if bd and r * r >= bd then break end -- (nothing further out can be nearer)
        local n = math.min(16, 6 + ring * 2)
        for k = 0, n - 1 do
            local a = k / n * math.pi * 2 + ring * 0.5
            Try(spot.x + math.cos(a) * r, spot.y + math.sin(a) * r)
        end
    end
    return best, bestTop
end

-- Its way between where it stands on the ground (base) and the open sky nearest a spot: straight up over base
-- (top), across to over where it hovers (over), and down (hover). Of the heights it may fly at, the one that
-- lets it hover nearest the spot (the lowest, when they are as good). Nil when it cannot fly it untouched.
local function Way(base, spot, hull, skip)
    local best
    for _, z in ipairs(Heights(base, hull, skip)) do
        local top = Vector(base.x, base.y, z)
        if Clear(base + Vector(0, 0, LIFT_CLEAR), top, hull.slim, skip) then
            local hover, over = HoverNear(spot, z, hull, top, skip)
            local d = hover and hover:DistToSqr(spot)
            if d and (not best or d < best.d - 1) then best = { d = d, top = top, over = over, hover = hover } end
        end
    end
    return best
end

-- The edge of the sky: the furthest it can be flown to, straight, from a spot at that height. Nil when boxed in.
local function FarOut(top, hull, skip)
    local best, bd
    for i = 0, 15 do
        local dir = Angle(0, i * 22.5, 0):Forward()
        local tr = Box(top, top + dir * FAR_OUT, hull, skip)
        local d = (tr and tr.StartSolid) and 0 or (FAR_OUT * ((tr and tr.Fraction) or 1) - 32)
        if d >= FAR_LEAST and (not bd or d > bd) then best, bd = top + dir * d, d end
    end
    return best
end

------------------------------------------------------------------------
-- The machine: a prop, its rotors, and who is aboard
------------------------------------------------------------------------

local function Make(pos, yaw)
    if not ModelOK() then return nil end
    local ent = ents.Create("prop_dynamic")
    if not IsValid(ent) then return nil end
    ent:SetModel(HELI_MODEL)
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, yaw + HELI_YAW, 0))
    ent:SetKeyValue("solid", "6")
    ent:Spawn()
    ent.lcAdminHeli = true
    ent.lcRotors = false
    return ent
end

-- Rotors: still and silent on the ground, turning (the model's own sequence) with the engine's sound in the air.
local function Rotors(ent, on)
    if not IsValid(ent) or ent.lcRotors == on then return end
    ent.lcRotors = on
    if on then
        for _, name in ipairs(ROTOR_SEQS) do
            local seq = ent.LookupSequence and ent:LookupSequence(name)
            if seq and seq >= 0 then
                ent:Fire("SetDefaultAnimation", name)
                ent:Fire("SetAnimation", name)
                break
            end
        end
        ent:Fire("SetPlaybackRate", "1")
        ent:EmitSound(ROTOR_SOUND, 100, 100)
    else
        ent:Fire("SetPlaybackRate", "0")
        if ent.StopSound then ent:StopSound(ROTOR_SOUND) end
    end
end

local function Gone(ent)
    if not IsValid(ent) then return end
    Rotors(ent, false)
    ent:Remove()
end

-- She is put aboard: unseen, in nobody's way, and not the game's to move (it would let her fall between two
-- ticks of the flight). mine: the ride to the stand, where nothing else is keeping her from harm.
local function Aboard(her, mine)
    if Seated[her] then return end
    Seated[her] = { mine = mine }
    her.lcAloft = true -- (her own guards wait on the ground: sv_livingcity_cityadmin.lua)
    if her.SetNoDraw then her:SetNoDraw(true) end
    if not her:IsPlayer() then return end
    if her.SetNotSolid then her:SetNotSolid(true) end
    if her.SetMoveType then her:SetMoveType(MOVETYPE_NONE or 0) end
    if mine and her.GodEnable then her:GodEnable() end
end

-- And out again: everything changed on her is given back.
local function Alight(her)
    local seat = Seated[her]
    if not seat then return end
    Seated[her] = nil
    if not IsValid(her) then return end
    her.lcAloft = nil
    if not her:IsPlayer() then return end
    if her.SetMoveType then her:SetMoveType(MOVETYPE_WALK or 2) end
    if her.SetLocalVelocity then her:SetLocalVelocity(Vector(0, 0, 0)) end
    if not seat.mine then return end -- (the exit's own end shows her again and lets her be hurt again)
    if her.SetNoDraw then her:SetNoDraw(false) end
    if her.SetNotSolid then her:SetNotSolid(false) end
    local A = LC.AdminExfil and LC.AdminExfil() or nil
    local C = LC.AdminCloseCallScene and LC.AdminCloseCallScene() or nil
    if her.GodDisable and not (A and A.her == her) and not (C and C.her == her) then her:GodDisable() end
end

------------------------------------------------------------------------
-- A flight: legs flown by the clock
------------------------------------------------------------------------

local function Ease(kind, f)
    if kind == "out" then return 1 - (1 - f) * (1 - f) end
    if kind == "in" then return f * f end
    if kind == "inout" then return f < 0.5 and 2 * f * f or 1 - 2 * (1 - f) * (1 - f) end
    return f
end
local function Secs(a, b, speed, least) return math.max(least, a:Distance(b) / speed) end
local function YawTo(a, b, otherwise)
    local d = b - a
    if d:Length2DSqr() < 1 then return otherwise end
    return d:Angle().y
end

-- One tick of a flight. f: { ent, legs, leg, t0 (when this leg began), yaw, her (aboard, or nil) }. A leg:
-- { a, b, secs, ease, yaw (it turns to face that way), pitch (nose down on the way), hold (it sways),
-- unseen (it may go as soon as nobody sees it), done(f, now) }. False once its last leg is flown.
local function Step(f, now)
    local ent = f.ent
    local leg = f.legs[f.leg]
    if not IsValid(ent) or not leg then return false end
    local dt = math.Clamp(now - (f.last or now), 0, 0.25)
    f.last = now
    local t = leg.secs > 0 and math.Clamp((now - f.t0) / leg.secs, 0, 1) or 1
    local pos = leg.a + (leg.b - leg.a) * Ease(leg.ease, t)
    if leg.hold then pos = pos + Vector(0, 0, math.sin(now * 1.6) * 4) end
    if leg.yaw then
        f.yaw = f.yaw + math.Clamp(math.AngleDifference(leg.yaw, f.yaw), -TURN_SPEED * dt, TURN_SPEED * dt)
    end
    ent:SetPos(pos)
    ent:SetAngles(Angle((leg.pitch or 0) * math.sin(t * math.pi), f.yaw + HELI_YAW, 0))
    if IsValid(f.her) then f.her:SetPos(pos + SEAT) end
    if leg.unseen and t > 0.3 and LC.IsSeen and not LC.IsSeen(pos) then return false end
    if t < 1 then return true end
    f.leg, f.t0 = f.leg + 1, now
    if leg.done then leg.done(f, now) end
    return f.legs[f.leg] ~= nil
end

-- It climbs away to the edge of the sky and is gone (sooner, once nobody can see it).
local function Leave(f, top, hull)
    local ent = f.ent
    if not IsValid(ent) then return end
    local pos = ent:GetPos()
    local far = FarOut(top, hull, ent)
    f.her = nil
    f.legs = { { a = pos, b = top, secs = Secs(pos, top, LIFT_SPEED, 2), ease = "inout" } }
    if far then
        f.legs[2] = { a = top, b = far, secs = Secs(top, far, FLY_SPEED, 3), ease = "in", yaw = YawTo(top, far, f.yaw), pitch = 12, unseen = true }
    end
    f.leg, f.t0 = 1, CurTime()
    Flights[#Flights + 1] = f
end

------------------------------------------------------------------------
-- Its point by the stand, her office door, and standing parked
------------------------------------------------------------------------

-- The helicopter's point by a stand: the nearest, within the reach the APC's point has.
function LC.AdminHeliPoint(stand)
    local reach = Kit().reach or 2000
    local best, bd
    for _, p in ipairs(LC.PointsOfKind and LC.PointsOfKind("adminheli") or {}) do
        local d = p.pos:DistToSqr(stand)
        if d < reach * reach and (not bd or d < bd) then best, bd = p, d end
    end
    return best
end

-- Her office's door (the editor's "Door: Administrator's office" nearest her desk), and her desk.
local function OfficeDoor()
    local desk = LC.PointsOfKind and LC.PointsOfKind("desk")[1]
    if not desk then return nil, nil end
    local door = Kit().door and Kit().door(desk.pos) or nil
    return IsValid(door) and door or nil, desk
end

-- Outside it: the way out of her office from the door (away from her desk), flat.
local function Outward(door, desk)
    local c = door:WorldSpaceCenter()
    local out = Vector(c.x - desk.pos.x, c.y - desk.pos.y, 0)
    if out:LengthSqr() < 1 then return nil end
    out:Normalize()
    return out, c
end

-- It stands on its point, rotors still. ent: the one that has just landed there (none: a new one).
-- S: the address it stands for (nil: kept for the exit under way).
local function Park(pt, ent, S)
    if P and P.ent ~= ent then Gone(P.ent) end
    P = nil
    if not IsValid(ent) then ent = Make(pt.pos, pt.yaw or 0) end
    if not ent then return nil end
    ent:SetPos(Rest(pt, HullOf(ent)))
    ent:SetAngles(Angle(0, (pt.yaw or 0) + HELI_YAW, 0))
    Rotors(ent, false)
    if ent.SetNotSolid then ent:SetNotSolid(false) end
    P = { ent = ent, pt = pt, S = S }
    if S then S.heli = ent end
    return ent
end

------------------------------------------------------------------------
-- The exit: after an attempt, to her office door (called by sv_livingcity_adminsecurity.lua)
------------------------------------------------------------------------

-- Its way from where it stands to the open sky nearest a spot. Nil when there is none it can fly untouched.
local function PlanExit(ent, target)
    local hull = HullOf(ent)
    local rest = ent:GetPos()
    local w = Way(rest, target, hull, ent)
    return w and { hull = hull, rest = rest, top0 = w.top, top1 = w.over, hover = w.hover } or nil
end

local function Take(A)
    if not (P and IsValid(P.ent) and A and IsValid(A.her)) then return false end
    if not HELI_FIRST and IsValid(A.apc) then return false end
    local door, desk = OfficeDoor()
    if not desk then return false end -- (nowhere of hers to fly to)
    local front, out
    if door then
        local c
        out, c = Outward(door, desk)
        if out then front = Ground(c + out * DOOR_FRONT) end
    end
    local target = front or desk.pos
    local plan = PlanExit(P.ent, target)
    if not plan then return false end
    local yaw = P.pt.yaw or 0
    Out = { ent = P.ent, pt = P.pt, plan = plan, front = front, out = out, step = "carry", t0 = CurTime(), yaw = yaw,
        yawEnd = YawTo(plan.hover, target, yaw) }
    A.heli = Out
    P = nil
    return true
end
-- The ring has closed: is there a helicopter to take her? True when it will (the exit's phase is then "heli").
function LC.AdminHeliTake(A)
    local ok, took = LC.Try(Take, A)
    if not ok then Note(took) end
    return ok and took == true
end

-- She is put in: the door, the rotors, and its way out by the clock.
local function Board(A, H, now)
    local her, ent, p = A.her, H.ent, H.plan
    Aboard(her, false)
    ent:EmitSound(DOOR_SOUND, 90, 90)
    Rotors(ent, true)
    if ent.SetNotSolid then ent:SetNotSolid(true) end -- (in the air nothing collides with it)
    local yawGo = YawTo(p.top0, p.top1, H.yaw)
    local legs = {
        { a = p.rest, b = p.rest, secs = SPIN_SECS },
        { a = p.rest, b = p.top0, secs = Secs(p.rest, p.top0, LIFT_SPEED, 2.5), ease = "inout", yaw = yawGo },
    }
    if p.top0:DistToSqr(p.top1) > 1 then
        legs[#legs + 1] = { a = p.top0, b = p.top1, secs = Secs(p.top0, p.top1, FLY_SPEED, 2), ease = "inout", yaw = yawGo, pitch = 10 }
    end
    legs[#legs + 1] = { a = p.top1, b = p.hover, secs = Secs(p.top1, p.hover, LIFT_SPEED, 2.5), ease = "inout", yaw = H.yawEnd }
    legs[#legs + 1] = { a = p.hover, b = p.hover, secs = HOVER_SECS, hold = true, yaw = H.yawEnd }
    H.f = { ent = ent, legs = legs, leg = 1, t0 = now, yaw = H.yaw, her = her }
    H.step = "fly"
end

-- It hovers by her door: she is in front of it (true: she is the exit's to set down instead: badly hit, into her
-- office, where she faints; the city's own, away; with no office door marked, at her desk).
local function Arrive(A, H)
    local her = A.her
    Alight(her)
    if A.closeCall or not H.front or not her:IsPlayer() then return true end
    her:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(H.front + Vector(0, 0, 8))) or H.front)
    if her.SetEyeAngles then her:SetEyeAngles(Angle(0, YawTo(H.out, Vector(0, 0, 0), 0), 0)) end -- (facing her door)
    if her.ScreenFade then her:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(0, 0, 0, 255), 0.8, 0.1) end
    hook.Run("LivingCityAdminMoved", her, H.front)
    return false
end

-- A tick of the exit's "heli" phase. Returns true and how she is to be set down (the exit's Done) when it is
-- over; nothing while it goes on.
function LC.AdminHeliExit(A, now, dt)
    local H, her = A.heli, A.her
    if not (H and IsValid(H.ent)) or now - H.t0 > EXIT_MAX then
        -- (the helicopter is gone, or has been too long about it. Aboard: she is set down as the APC sets her
        -- down. Not yet: the exit thinks again: the APC, the shield run, or the ring holds.)
        if H and H.f then
            Alight(her)
            return true, true
        end
        A.heli, A.phase = nil, "close"
        return
    end
    if H.step == "carry" then
        -- to its side, straight there, through whatever is in the way: as to the APC
        local K = Kit()
        local door = H.ent:GetPos() + Angle(0, H.yaw, 0):Right() * BOARD_OUT
        local pos = her:GetPos()
        local to = door - pos
        to.z = 0
        local d = to:Length()
        if d <= 40 then return Board(A, H, now) end
        local step = math.min(d, (K.speed or 450) * dt)
        local nextPos = Ground(pos + to * (step / d))
        her:SetPos(nextPos)
        if K.ring then K.ring(nextPos, dt) end
        return
    end
    if Step(H.f, now) then return end
    local deliver = Arrive(A, H)
    H.left = true
    Leave(H.f, H.plan.top1, H.plan.hull)
    return true, deliver
end

------------------------------------------------------------------------
-- The ride: from her office door to the stand (asked by sv_livingcity_speech.lua when she calls her address)
------------------------------------------------------------------------

-- Its way: in from the edge of the sky to her, and on to its point by the stand.
local function PlanRide(ent, pt, at)
    local hull = HullOf(ent)
    local pad = Rest(pt, hull)
    local w = Way(pad, at, hull, ent)
    return w and { hull = hull, pad = pad, topL = w.top, topH = w.over, hover = w.hover, far = FarOut(w.over, hull, ent) } or nil
end

-- On her feet beside it, facing the stand.
local function SetDown(her, pt, S)
    local at = Ground(Ground(pt.pos) + Angle(0, pt.yaw or 0, 0):Right() * BOARD_OUT)
    her:SetPos((LC.FreeSpawnPos and LC.FreeSpawnPos(at + Vector(0, 0, 8))) or at)
    if her.SetEyeAngles and S and S.stand then her:SetEyeAngles(Angle(0, YawTo(at, S.stand.pos, pt.yaw or 0), 0)) end
    hook.Run("LivingCityAdminMoved", her, at)
end

-- The ride is over. landed: it set down as meant. Otherwise something failed (too long, she died, the address
-- ended, an attempt on her life): she is put by its point at once, never left aboard, hidden or held.
-- ending: her address is ending this moment (its helicopter goes with it, unless an exit wants it).
local function RideEnd(landed, ending)
    local r = R
    if not r then return end
    R = nil
    local her, S, pt = r.her, r.S, r.pt
    local A = LC.AdminExfil and LC.AdminExfil() or nil
    local exit = A ~= nil and A.her == her
    local live = not ending and LC.SpeechSession ~= nil and LC.SpeechSession() == S
    if IsValid(her) then
        local was = Seated[her] ~= nil
        Alight(her)
        -- (not yet aboard, and her address over: she stays where she stands)
        if her:Alive() and (was or live or exit) then
            SetDown(her, pt, S)
            if exit then A.at = her:GetPos() end -- (the exit began in the air: it goes on from the ground)
        end
    end
    if live or exit then
        Park(pt, r.ent, live and S or nil)
        if live and S.speakAt and S.speakAt < CurTime() + SPEAK_AFTER then S.speakAt = CurTime() + SPEAK_AFTER end
    else
        Gone(r.ent)
    end
end

local function RideThink(now)
    local r = R
    local her, S = r.her, r.S
    if not IsValid(her) or not her:Alive() or not IsValid(r.ent) or now - r.t0 > RIDE_MAX
        or not (LC.SpeechSession and LC.SpeechSession() == S) then
        return RideEnd(false)
    end
    -- (her address waits for her)
    if S.speakAt and S.speakAt < now + SPEAK_AFTER then S.speakAt = now + SPEAK_AFTER end
    if not Step(r.f, now) then return RideEnd(true) end
end

local function Fetch(S)
    local her = S and S.by
    if R or not (IsValid(her) and her:IsPlayer() and her:Alive() and S.stand) then return false end
    local pt = LC.AdminHeliPoint(S.stand.pos)
    if not pt then return false end
    local door, desk = OfficeDoor()
    if not door then return false end
    local out, c = Outward(door, desk)
    local at = her:GetPos()
    if not out or at:DistToSqr(c) > DOOR_REACH * DOOR_REACH or (at - c):Dot(out) <= 0 then return false end -- (not at her door, or inside her office)
    local ent = Make(pt.pos, pt.yaw or 0)
    if not ent then return false end
    making = ent
    local p = PlanRide(ent, pt, at)
    if not p then return false end
    local now = CurTime()
    local yawIn = p.far and YawTo(p.far, p.topH, pt.yaw or 0) or (pt.yaw or 0)
    local yawGo = YawTo(p.topH, p.topL, yawIn)
    local legs = {}
    if p.far then legs[#legs + 1] = { a = p.far, b = p.topH, secs = Secs(p.far, p.topH, FLY_SPEED, 3), ease = "out", yaw = yawIn, pitch = 8 } end
    legs[#legs + 1] = { a = p.topH, b = p.hover, secs = Secs(p.topH, p.hover, LIFT_SPEED, 2.5), ease = "inout" }
    legs[#legs + 1] = { a = p.hover, b = p.hover, secs = BOARD_SECS, hold = true, done = function(f)
        -- she is inside it
        if not (IsValid(her) and her:Alive()) then return end
        Aboard(her, true)
        f.her = her
        her:SetPos(f.ent:GetPos() + SEAT)
        f.ent:EmitSound(DOOR_SOUND, 90, 90)
    end }
    legs[#legs + 1] = { a = p.hover, b = p.topH, secs = Secs(p.hover, p.topH, LIFT_SPEED, 2.5), ease = "inout", yaw = yawGo }
    if p.topH:DistToSqr(p.topL) > 1 then
        legs[#legs + 1] = { a = p.topH, b = p.topL, secs = Secs(p.topH, p.topL, FLY_SPEED, 2), ease = "inout", yaw = yawGo, pitch = 10 }
    end
    legs[#legs + 1] = { a = p.topL, b = p.pad, secs = Secs(p.topL, p.pad, LIFT_SPEED, 2.5), ease = "out", yaw = pt.yaw or 0 }
    ent:SetPos(legs[1].a)
    ent:SetAngles(Angle(0, yawIn + HELI_YAW, 0))
    if ent.SetNotSolid then ent:SetNotSolid(true) end
    Rotors(ent, true)
    R = { her = her, S = S, pt = pt, ent = ent, t0 = now, f = { ent = ent, legs = legs, leg = 1, t0 = now, yaw = yawIn } }
    return true
end
-- She has called her address: is she fetched? True when a helicopter is on its way to her (she is then not put
-- at the stand: it brings her). False: she is put at the stand as ever.
function LC.AdminHeliFetch(S)
    making = nil
    local ok, went = LC.Try(Fetch, S)
    if not ok then Note(went) end
    local coming = ok and went == true
    if not coming and IsValid(making) then making:Remove() end -- (the one made to measure the way with: not needed)
    making = nil
    return coming
end

------------------------------------------------------------------------
-- By the tick, and the hooks
------------------------------------------------------------------------

function LC.AdminHeliThink(now)
    now = now or CurTime()
    local A = LC.AdminExfil and LC.AdminExfil() or nil
    local S = LC.SpeechSession and LC.SpeechSession() or nil
    -- the parked one: its address is gone, or the exit it was kept for is over without it
    if P and (not IsValid(P.ent) or (P.S and P.S ~= S) or (not P.S and not A)) then
        Gone(P.ent)
        P = nil
    end
    -- the one the exit took: the exit is over (she is set down and it is leaving, or it was cut short)
    if Out and not (A and A.heli == Out) then
        if not Out.left then Gone(Out.ent) end
        Out = nil
    end
    if R then RideThink(now) end
    for i = #Flights, 1, -1 do
        local f = Flights[i]
        if not Step(f, now) then
            Gone(f.ent)
            table.remove(Flights, i)
        end
    end
    -- (nobody stays aboard something that no longer flies her)
    for her in pairs(Seated) do
        if not ((R and R.her == her) or (A and A.her == her and A.heli ~= nil)) then Alight(her) end
    end
end

-- Whatever went wrong: nobody is left half way.
local function Bail()
    LC.Try(RideEnd, false)
    R = nil
    for her in pairs(Seated) do LC.Try(Alight, her) end
    for _, f in ipairs(Flights) do LC.Try(Gone, f.ent) end
    Flights = {}
end

hook.Add("Think", "LivingCityAdminHeli", function()
    if not (P or R or Out or Flights[1] or next(Seated)) then return end
    local ok, err = LC.Try(LC.AdminHeliThink, CurTime())
    if not ok then
        Note(err)
        Bail()
    end
end)

-- It stands by for as long as she speaks (unless it is on its way to fetch her: then once it has landed).
hook.Add("LivingCitySpeechCalled", "LivingCityAdminHeli", function(_, S)
    if not (S and S.stand) or (R and R.S == S) then return end
    local pt = LC.AdminHeliPoint(S.stand.pos)
    if not pt then return end
    local ok, err = LC.Try(Park, pt, nil, S)
    if not ok then Note(err) end
end)
-- Her address is over: it goes, as the APC does. With an exit under way it is kept: the exit's to take or leave.
hook.Add("LivingCitySpeechEnded", "LivingCityAdminHeli", function(S)
    local ok, err = LC.Try(function()
        if R and R.S == S then RideEnd(false, true) end
        if not (P and P.S == S) then return end
        if LC.AdminExfil and LC.AdminExfil() then
            P.S = nil
            return
        end
        Gone(P.ent)
        P = nil
    end)
    if not ok then Note(err) end
end)

-- Whoever hits it while it takes her out is one of her attackers, as with the APC (never one of the Combine's
-- own: the exit sees to that). It takes no harm.
hook.Add("EntityTakeDamage", "LivingCityAdminHeli", function(ent, dmg)
    if not (Out and ent == Out.ent) then return end
    local A = LC.AdminExfil and LC.AdminExfil() or nil
    local att = dmg:GetAttacker()
    if A and A.heli == Out and IsValid(att) and (att:IsPlayer() or att:IsNPC()) and LC.AdminAttempt then
        LC.Try(LC.AdminAttempt, A.her, att, "helicopter")
    end
    return true
end)

-- Riding to the stand she cannot move (the exit holds her itself: sv_livingcity_adminsecurity.lua).
hook.Add("StartCommand", "LivingCityAdminHeli", function(ply, cmd)
    local seat = Seated[ply]
    if not (seat and seat.mine) then return end
    cmd:ClearMovement()
    cmd:SetButtons(0)
end)

hook.Add("LivingCityStopped", "LivingCityAdminHeli", function()
    Bail()
    if P then Gone(P.ent) end
    if Out and not Out.left then Gone(Out.ent) end
    P, Out = nil, nil
end)
