--[[
    Living City: The Midnight Rally, your side (sv_livingcity_dreamrally.lua)

    While you drive a dream buggy (lc_kart, sh_livingcity_kart.lua) you watch from behind and a
    little above it, as in a racing game: you are not drawn, only your buggy. Everything else
    (the lap, your place, what you're carrying) is on the dream's usual lines on screen.
]]

LC_CL = LC_CL or {}

LC_CL.KartCamBack, LC_CL.KartCamUp = 170, 78

-- Where the eye is for a driver at pos, looking along ang.
function LC_CL.KartView(pos, ang)
    local flat = Angle(0, ang.y, 0)
    local origin = pos + Vector(0, 0, LC_CL.KartCamUp) - flat:Forward() * LC_CL.KartCamBack
    return origin, Angle(math.Clamp(ang.p, -10, 35) * 0.5 + 9, ang.y, 0)
end

hook.Add("CalcView", "LivingCityDreamRally", function(ply, pos, ang, fov)
    if not IsValid(ply) or not ply:GetNW2Bool("lc_kart", false) then return end
    local origin, angles = LC_CL.KartView(ply:GetPos(), ang)
    return { origin = origin, angles = angles, fov = fov, drawviewer = false }
end)
-- (no hands or weapon floating in front of the buggy)
hook.Add("PreDrawViewModel", "LivingCityDreamRally", function(vm, ply)
    if IsValid(ply) and ply:GetNW2Bool("lc_kart", false) then return true end
end)
