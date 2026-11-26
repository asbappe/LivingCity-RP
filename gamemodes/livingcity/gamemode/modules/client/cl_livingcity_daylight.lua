--[[
    Living City: darker places (the screen's part)

    The owner, 20 November: "I really want the infested quarter to be darker and not
    sunny and even the southern half of the ring should be a bit dimmer". One sun
    lights everything under a map's sky alike, so the difference is made here, on the
    screen of whoever stands there: the server sends where the map's marks are
    (lc_mood_dark, lc_mood_dim: sv_livingcity_daylight.lua), and the nearer you are to
    one the more the picture is darkened and greyed. It comes and goes over a few
    steps' walk, never at once. Nothing is written on the screen.
]]

if SERVER then return end

LC_CL = LC_CL or {}
LC_CL.Moods = LC_CL.Moods or {}

local REACH = { dark = 1500, dim = 1200 }     -- how far a mark is felt (fully within half of it)
local now = { dark = 0, dim = 0 }             -- how much of each you are in, eased

net.Receive("lc_moods", function()
    local list = {}
    for _ = 1, net.ReadUInt(8) do
        local dark = net.ReadBool()
        list[#list + 1] = { kind = dark and "dark" or "dim", pos = net.ReadVector() }
    end
    LC_CL.Moods = list
end)

-- How much of a kind of place this spot is in: 1 within half a mark's reach, falling to 0 at its edge.
function LC_CL.MoodAt(pos, kind)
    local best, reach = 0, REACH[kind] or 1000
    for _, m in ipairs(LC_CL.Moods) do
        if m.kind == kind then
            local d = pos:Distance(m.pos)
            if d < reach then best = math.max(best, math.min(1, (reach - d) / (reach * 0.5))) end
        end
    end
    return best
end

hook.Add("RenderScreenspaceEffects", "LivingCityPlaceMood", function()
    if #LC_CL.Moods == 0 or not DrawColorModify then return end
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local eye = me.EyePos and me:EyePos() or me:GetPos()
    local step = math.min(1, (FrameTime and FrameTime() or 0.02) * 1.5)
    for kind in pairs(now) do
        now[kind] = now[kind] + (LC_CL.MoodAt(eye, kind) - now[kind]) * step
    end
    local dark, dim = now.dark, now.dim * (1 - now.dark)
    if dark < 0.01 and dim < 0.01 then return end
    DrawColorModify({
        ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.008 * dark, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.07 * dark - 0.03 * dim,
        ["$pp_colour_contrast"] = 1 - 0.06 * dark,
        ["$pp_colour_colour"] = 1 - 0.5 * dark - 0.12 * dim,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
    })
end)

------------------------------------------------------------------------
-- The stars. The owner, 20 November, of the painted sky's stock star picture: "looks like a toddler drew some
-- stars". So the server switches that picture off while it paints the sky by the hour (lc_sky_stars), and each
-- client draws its own: some 1,500 fine points of differing brightness and a few brighter ones, the same sky for
-- everyone, built once and drawn in one go behind everything else. They come out as the light goes.
------------------------------------------------------------------------

local STARS, FAR = 1500, 1000
local starMesh, starMat, starsBroken

local function BuildStars()
    if not (Mesh and mesh and mesh.Begin and CreateMaterial) then return false end
    starMat = CreateMaterial("lc_sky_star", "UnlitGeneric", {
        ["$basetexture"] = "sprites/light_glow02", ["$additive"] = "1", ["$vertexcolor"] = "1", ["$vertexalpha"] = "1",
        ["$ignorez"] = "1", ["$nocull"] = "1",
    })
    starMesh = Mesh()
    local seed = 20261120
    local function Rnd() seed = (seed * 1103515245 + 12345) % 2147483648 return seed / 2147483648 end
    mesh.Begin(starMesh, MATERIAL_QUADS, STARS)
    for i = 1, STARS do
        -- anywhere above the horizon and a little below it, evenly over the dome
        local z = Rnd() * 1.08 - 0.08
        local a, flat = Rnd() * math.pi * 2, math.sqrt(math.max(0, 1 - z * z))
        local dir = Vector(math.cos(a) * flat, math.sin(a) * flat, z)
        -- most are faint and small; one in thirty is bright
        local bright = Rnd() < 0.033
        local size = FAR * (bright and (0.0050 + Rnd() * 0.0035) or (0.0018 + Rnd() * 0.0022))
        local glow = bright and 255 or math.floor(70 + Rnd() * 150)
        local warm = Rnd()
        local r, g, b = glow, math.floor(glow * (0.92 + 0.08 * warm)), math.floor(glow * (0.80 + 0.20 * (1 - warm)))
        local right = dir:Cross(math.abs(z) > 0.95 and Vector(1, 0, 0) or Vector(0, 0, 1))
        right:Normalize()
        local up = right:Cross(dir)
        local c = dir * FAR
        for _, v in ipairs({ { -1, -1, 0, 1 }, { -1, 1, 0, 0 }, { 1, 1, 1, 0 }, { 1, -1, 1, 1 } }) do
            mesh.Position(c + right * (size * v[1]) + up * (size * v[2]))
            mesh.TexCoord(0, v[3], v[4])
            mesh.Color(r, g, b, 255)
            mesh.AdvanceVertex()
        end
    end
    mesh.End()
    return true
end

local function HourNow()
    local len = GetGlobal2Float("lc_day_len", 3600)
    return ((CurTime() - GetGlobal2Float("lc_day_zero", 0)) / math.max(1, len) * 24) % 24
end

hook.Add("PostDraw2DSkyBox", "LivingCityStars", function()
    if starsBroken or not GetGlobal2Bool("lc_sky_stars", false) then return end
    local dark = LC_CL.Darkness and LC_CL.Darkness(HourNow()) or 0
    if dark <= 0.02 then return end
    local ok, err = LC.Try(function()
        if not starMesh and not BuildStars() then starsBroken = true return end
        starMat:SetVector("$color", Vector(dark, dark, dark))
        render.OverrideDepthEnable(true, false)
        cam.Start3D(Vector(0, 0, 0), EyeAngles())
        render.SetMaterial(starMat)
        starMesh:Draw()
        cam.End3D()
        render.OverrideDepthEnable(false, false)
    end)
    -- (anything wrong with it: no stars, rather than an error every frame)
    if not ok then
        starsBroken = true
        if LC.Error then LC.Error("stars", err) end
    end
end)
LC_CL.StarsState = function() return starMesh ~= nil, starsBroken == true end

