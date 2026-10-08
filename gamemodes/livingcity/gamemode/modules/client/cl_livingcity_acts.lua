--[[
    Living City (client): while you hold a pose, the camera pulls back so you
    can see yourself. lc_act_thirdperson 0 keeps it first person.
]]

local cvThird = CreateClientConVar("lc_act_thirdperson", "1", true, false, "Third person while holding a pose (/sit, /kneel...)")

local function Posing(ply)
    return IsValid(ply) and ply:Alive() and ply:GetNW2String("lc_act", "") ~= "" and cvThird:GetBool()
end

-- (one of the camera's steps: cl_livingcity_view.lua)
LC_CL = LC_CL or {}
LC_CL.ViewMods = LC_CL.ViewMods or {}
LC_CL.ViewMods.acts = { order = 20, fn = function(ply, view, ctx)
    if ctx.remote or ctx.vehicle or not Posing(ply) then return end
    local origin, angles = view.origin, view.angles
    local back = angles:Forward() * -95 + angles:Up() * 8
    local tr = util.TraceHull({ start = origin, endpos = origin + back, mins = Vector(-6, -6, -6), maxs = Vector(6, 6, 6), filter = ply, mask = MASK_SOLID_BRUSHONLY })
    view.origin = tr.HitPos
    view.drawviewer = true
    ctx.third = true
end }

hook.Add("ShouldDrawLocalPlayer", "LivingCityActs", function(ply)
    if Posing(ply) then return true end
end)
