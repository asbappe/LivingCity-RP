--[[
    Living City: driving a dream buggy (sv_livingcity_dreamrally.lua)

    The owner, 10 November: "a Mario kart esque buggy race dream".

    In The Midnight Rally a dreamer drives a small buggy. There is no real vehicle: the dreamer
    is moved as a driver would be, here, the same on the server and on their own game (so it
    feels immediate), from nothing but how they're moving, where they're looking and three
    things the server sets on them:

      lc_kart        driving (this file does nothing otherwise)
      lc_kart_max    the top speed right now (lower off the track or slowed, higher boosted, 0 held at the start)
      lc_kart_spin   spinning out until then (no steering, no throttle)

    Forward accelerates, back brakes and then reverses, and the buggy goes where it was going:
    it turns towards where you look only so fast, less sharply at speed, so a corner taken too
    quickly runs wide. There is no strafing, no jumping and no crouching in a buggy.

    LCK.Step is the whole of it, pure arithmetic (tested in _dev/tests.lua).
]]

LCK = LCK or {}
LCK.Accel = 560    -- (units a second, each second, towards the top speed)
LCK.Brake = 1100   -- (braking)
LCK.Coast = 300    -- (lifting off)
LCK.Turn = 150     -- (degrees a second the buggy's heading comes round to where you look, at rest; less at speed)
LCK.Reverse = 0.3  -- (of the top speed, backwards)
LCK.Scrub = 0.35   -- (speed lost a second, of the top speed, cornering flat out)
LCK.Base = 520     -- (the top speed on the track, nothing helping or hindering)

local function Wrap(a) return (a + math.pi) % (math.pi * 2) - math.pi end

-- One moment of driving. vx, vy: how they're moving. yaw: where they look (radians). throttle: 1, 0 or -1.
-- max: the top speed now. spin: spinning out. Returns the new vx, vy.
function LCK.Step(vx, vy, yaw, throttle, dt, max, spin)
    local spd = math.sqrt(vx * vx + vy * vy)
    local fx, fy = math.cos(yaw), math.sin(yaw)
    local dx, dy = fx, fy
    if spd > 25 then dx, dy = vx / spd, vy / spd end
    if spin or max <= 0 then
        spd = math.max(0, spd - 900 * dt)
        return dx * spd, dy * spd
    end
    local along = dx * fx + dy * fy
    if throttle < 0 then
        if along > 0.2 and spd > 25 then
            spd = math.max(0, spd - LCK.Brake * dt) -- (braking)
        else
            dx, dy = -fx, -fy -- (backing up, the way they're not looking)
            spd = math.min(max * LCK.Reverse, spd + LCK.Accel * 0.6 * dt)
        end
        return dx * spd, dy * spd
    end
    if along < -0.2 and spd > 25 then
        -- rolling backwards: stop first
        spd = math.max(0, spd - LCK.Brake * dt)
        return dx * spd, dy * spd
    end
    -- the heading comes round to where they look, only so fast
    local cur, want = math.atan2(dy, dx), math.atan2(fy, fx)
    local d = Wrap(want - cur)
    local frac = math.min(1, spd / math.max(1, max))
    local step = math.rad(LCK.Turn) * dt * (1.3 - 0.55 * frac)
    cur = cur + math.Clamp(d, -step, step)
    dx, dy = math.cos(cur), math.sin(cur)
    spd = math.max(0, spd - math.min(1, math.abs(d)) * frac * LCK.Scrub * max * dt) -- (a corner costs speed)
    if throttle > 0 then
        if spd < max then spd = math.min(max, spd + LCK.Accel * dt) else spd = math.max(max, spd - 500 * dt) end
    else
        spd = math.max(0, spd - LCK.Coast * dt)
    end
    return dx * spd, dy * spd
end

hook.Add("SetupMove", "LivingCityKart", function(ply, mv)
    if not ply:GetNW2Bool("lc_kart", false) then return end
    local dt = FrameTime()
    local v = mv:GetVelocity()
    local throttle = mv:KeyDown(IN_FORWARD) and 1 or (mv:KeyDown(IN_BACK) and -1 or 0)
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    mv:SetUpSpeed(0)
    mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(bit.bor(IN_JUMP, IN_DUCK))))
    if not ply:OnGround() then return end
    local nx, ny = LCK.Step(v.x, v.y, math.rad(mv:GetAngles().y), throttle, dt,
        ply:GetNW2Float("lc_kart_max", LCK.Base), ply:GetNW2Float("lc_kart_spin", 0) > CurTime())
    -- (the ground's friction takes its share after this: given back here, so the speed set is the speed driven)
    local fr = GetConVar("sv_friction")
    local keep = math.max(0.5, 1 - (fr and fr:GetFloat() or 8) * dt)
    mv:SetVelocity(Vector(nx / keep, ny / keep, v.z))
end)
