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

-- Hands up: the arrest pose the models have is authored a step ahead of where the model stands, so
-- the body looked to slide forward and back (the owner, 7 November). The player never moves; the
-- drawing is pulled back by the pose's own offset (its bounds against the standing idle's).
local function PoseShift(ply, name)
    local r = LCA.Resolve(ply, name)
    if not r or not ply.GetSequenceInfo then return nil end
    ply.lcPoseShift = ply.lcPoseShift or {}
    local key = (ply:GetModel() or "") .. "|" .. tostring(r.seq)
    local c = ply.lcPoseShift[key]
    if c == nil then
        c = false
        local info = ply:GetSequenceInfo(r.seq)
        local idle = ply:SelectWeightedSequence(ACT_HL2MP_IDLE)
        local ref = idle and idle > 0 and ply:GetSequenceInfo(idle) or nil
        if istable(info) and info.bbmin and info.bbmax then
            local cx, cy = (info.bbmin.x + info.bbmax.x) / 2, (info.bbmin.y + info.bbmax.y) / 2
            if istable(ref) and ref.bbmin and ref.bbmax then
                cx, cy = cx - (ref.bbmin.x + ref.bbmax.x) / 2, cy - (ref.bbmin.y + ref.bbmax.y) / 2
            end
            if math.abs(cx) > 6 or math.abs(cy) > 6 then c = Vector(cx, cy, 0) end
        end
        ply.lcPoseShift[key] = c
    end
    return c or nil
end
LC_CL.PoseShift = PoseShift

hook.Add("Think", "LivingCityActsShift", function()
    for _, ply in ipairs(player.GetAll()) do
        local shift
        if ply:Alive() and ply:GetNW2Bool("lc_handsup", false) and ply:GetNW2String("lc_act", "") == ""
            and ply:GetVelocity():Length2DSqr() <= 100 then
            shift = PoseShift(ply, "handsup")
        end
        if shift and ply.SetRenderOrigin then
            local ang = ply.GetRenderAngles and ply:GetRenderAngles() or ply:GetAngles()
            ply:SetRenderOrigin(ply:GetPos() - (ang:Forward() * shift.x - ang:Right() * shift.y))
            ply.lcShifted = true
        elseif ply.lcShifted and ply.SetRenderOrigin then
            ply:SetRenderOrigin(nil)
            ply.lcShifted = nil
        end
    end
end)
