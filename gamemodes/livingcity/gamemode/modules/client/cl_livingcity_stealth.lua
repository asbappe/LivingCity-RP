--[[
    Living City: keeping out of sight (the server's side: LC.StealthRange in sv_livingcity_quests.lua)

      Crouch to sneak. While you do:
        - a bar at the bottom of the screen says how easily you're seen: crouched
          you're seen at half the distance, creeping slowly less again, and in the
          dark less still (how lit you are is measured here, on your own screen,
          and sent to the server once a second);
        - each Civil Protection unit and soldier near you has his sight shown in
          front of him, as far as he'd see you right now: on the ground (up
          slopes and steps too) with see-through walls about waist high, so you
          can see it from below as well; red if you're in it, faint orange if
          not. Crouched, a unit doesn't see you behind his back.
      lc_stealth_cones 0 turns the painting off (your own setting).
]]

if SERVER then return end

LC_CL = LC_CL or {}

local cvCones = CreateClientConVar("lc_stealth_cones", "1", true, false, "While crouched, show where Civil Protection units and soldiers can see you, on the ground")
local REACH = 900   -- how far a unit sees someone standing in the light (the server's usual distance)
local HALF = 70     -- his view: this many degrees either side of where he faces
local SECURITY = { cop = true, soldier = true }

local light = 1
timer.Create("LivingCityStealthLight", 1, 0, function()
    local me = LocalPlayer()
    if not IsValid(me) or not render or not render.GetLightColor then return end
    local c = render.GetLightColor(me:GetPos() + Vector(0, 0, 32))
    if not c or not c.x then return end
    light = math.Clamp(math.max(c.x, c.y, c.z), 0, 1)
    -- the server only cares whether you're in the dark, the half-dark or the light (the stealth
    -- thresholds): tell it when that changes, and now and then anyway, not every second
    local band = light < 0.06 and 0 or (light < 0.15 and 1 or 2)
    if band == LC_CL.lightBand and CurTime() < (LC_CL.lightSentAt or 0) + 30 then return end
    LC_CL.lightBand, LC_CL.lightSentAt = band, CurTime()
    net.Start("lc_light")
    net.WriteFloat(light)
    net.SendToServer()
end)

-- How far a unit would see you right now (the same sums as the server's)
function LC_CL.StealthFactor()
    local me = LocalPlayer()
    if not IsValid(me) then return 1 end
    local f = 1
    if me:Crouching() then
        f = f * 0.5
        if me:GetVelocity():Length2D() < 60 then f = f * 0.85 end
    end
    if light < 0.06 then f = f * 0.55 elseif light < 0.15 then f = f * 0.75 end
    return f
end

local function On()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() or not me:Crouching() then return false end
    local st = GetConVar("lc_stealth")
    return not st or st:GetBool()
end

local function Units()
    local out, me = {}, LocalPlayer():GetPos()
    for _, e in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(e) and SECURITY[e:GetNW2String("lc_role", "")] and e:GetPos():DistToSqr(me) < 1600 * 1600 then out[#out + 1] = e end
    end
    return out
end

-- Inside this unit's sight just now?
local function Inside(e, pos, r)
    local d = pos - e:GetPos()
    d.z = 0
    if d:LengthSqr() > r * r then return false end
    local f = e:GetForward()
    f.z = 0
    f:Normalize()
    d:Normalize()
    return f:Dot(d) > math.cos(math.rad(HALF))
end
LC_CL.StealthInside = Inside

-- his sight, in 3D: a fan that follows the ground (up a slope, down steps), with walls
-- round it about waist high and a lid, so you can see it from below or from far off,
-- not just from above
local HEIGHT = 48
local cache = {} -- [unit] = { at, r, pts = { ground points } }
local function Ground(p)
    if not util or not util.TraceLine then return p end
    local tr = util.TraceLine({ start = p + Vector(0, 0, 90), endpos = p - Vector(0, 0, 200), mask = MASK_SOLID_BRUSHONLY })
    if tr and tr.Hit and tr.HitPos then return tr.HitPos + Vector(0, 0, 3) end
    return p
end
local function Quad(a, b, c, d, col)
    render.DrawQuad(a, b, c, d, col)
    render.DrawQuad(d, c, b, a, col) -- (and from the other side)
end
local function Fan(e, r, now)
    local c = cache[e]
    if c and now - c.at < 0.25 and math.abs(c.r - r) < 8 then return c end
    local o = e:GetPos() + Vector(0, 0, 3)
    local yaw = e:GetAngles().y
    local segs = 12
    local pts = {}
    for i = 0, segs do
        local a = math.rad(yaw - HALF + (2 * HALF) * i / segs)
        pts[#pts + 1] = Ground(o + Vector(math.cos(a), math.sin(a), 0) * r)
    end
    c = { at = now, r = r, o = o, pts = pts }
    cache[e] = c
    return c
end
LC_CL.StealthFan = Fan
hook.Add("PostDrawTranslucentRenderables", "LivingCityStealthCones", function(_, sky)
    if sky or not cvCones:GetBool() or not On() then return end
    local r = REACH * LC_CL.StealthFactor()
    local me = LocalPlayer():GetPos()
    local now = CurTime()
    if render.SetColorMaterial then render.SetColorMaterial() end
    local up = Vector(0, 0, HEIGHT)
    for _, e in ipairs(Units()) do
        local inside = Inside(e, me, r)
        local floor = inside and Color(255, 40, 40, 45) or Color(255, 150, 40, 18)
        local wall = inside and Color(255, 40, 40, 28) or Color(255, 150, 40, 12)
        local f = Fan(e, r, now)
        local o, pts = f.o, f.pts
        for i = 2, #pts do
            local a, b = pts[i - 1], pts[i]
            Quad(o, a, b, o, floor)                 -- the ground
            Quad(o + up, a + up, b + up, o + up, wall) -- the lid
            Quad(a, b, b + up, a + up, wall)        -- the far edge
        end
        -- the two sides
        Quad(o, pts[1], pts[1] + up, o + up, wall)
        Quad(o, pts[#pts], pts[#pts] + up, o + up, wall)
    end
end)

-- how seen you are, while you sneak
hook.Add("HUDPaint", "LivingCityStealthMeter", function()
    if not On() then return end
    local f = LC_CL.StealthFactor()
    local seen = false
    local r = REACH * f
    local me = LocalPlayer():GetPos()
    for _, e in ipairs(Units()) do if Inside(e, me, r) then seen = true break end end
    local w, h = 220, 34
    local x, y = ScrW() / 2 - w / 2, ScrH() - 120
    draw.RoundedBox(6, x, y, w, h, Color(10, 12, 16, 190))
    local fill = math.Clamp(f, 0, 1)
    local col = seen and Color(230, 60, 50) or (fill < 0.35 and Color(90, 170, 110) or Color(220, 170, 60))
    draw.RoundedBox(4, x + 8, y + 22, (w - 16) * fill, 6, col)
    local word = seen and "A UNIT CAN SEE YOU" or (fill < 0.3 and "IN SHADOW" or (fill < 0.45 and "HARD TO SEE" or "SNEAKING"))
    draw.SimpleText(word, "DermaDefaultBold", x + w / 2, y + 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
