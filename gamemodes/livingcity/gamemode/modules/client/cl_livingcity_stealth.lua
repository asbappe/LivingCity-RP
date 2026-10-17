--[[
    Living City: keeping out of sight (the server's side: LC.StealthRange in sv_livingcity_quests.lua)

      Crouch to sneak. While you do:
        - a bar at the bottom of the screen says how easily you're seen: crouched
          you're seen at half the distance, creeping slowly less again, and in the
          dark less still (how lit you are is measured here, on your own screen,
          and sent to the server once a second);
        - each Civil Protection unit and soldier near you has his sight painted
          on the ground in front of him, as far as he'd see you right now: red if
          you're in it, faint orange if not. Crouched, a unit doesn't see you
          behind his back.
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

-- his sight on the ground: a fan of thin triangles
hook.Add("PostDrawTranslucentRenderables", "LivingCityStealthCones", function(_, sky)
    if sky or not cvCones:GetBool() or not On() then return end
    local r = REACH * LC_CL.StealthFactor()
    local me = LocalPlayer():GetPos()
    if render.SetColorMaterial then render.SetColorMaterial() end
    for _, e in ipairs(Units()) do
        local o = e:GetPos() + Vector(0, 0, 3)
        local yaw = e:GetAngles().y
        local col = Inside(e, me, r) and Color(255, 40, 40, 45) or Color(255, 150, 40, 18)
        local segs = 12
        local prev
        for i = 0, segs do
            local a = math.rad(yaw - HALF + (2 * HALF) * i / segs)
            local p = o + Vector(math.cos(a), math.sin(a), 0) * r
            if prev then render.DrawQuad(o, prev, p, o, col) end
            prev = p
        end
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
