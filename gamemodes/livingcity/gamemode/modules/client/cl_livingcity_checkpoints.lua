--[[
    Living City (client): checkpoint cables

    Each turret and forcefield that runs off a power bank (or a turret off a
    forcefield) has a cable to it, sagging between the two
    (sv_livingcity_checkpoints.lua says which: lc_cable).
]]

LC_CL = LC_CL or {}

local CABLE = Material("cable/cable2")
local SEGS = 12
local DOWN = Vector(0, 0, 1)
local CABLE_COL = Color(70, 70, 76) -- (dark rubber, not bright steel)

local function DrawCable(a, b)
    local len = a:Distance(b)
    if len < 4 then return end
    local sag = math.min(90, len * 0.18)
    render.StartBeam(SEGS + 1)
    for i = 0, SEGS do
        local t = i / SEGS
        render.AddBeam(LerpVector(t, a, b) - DOWN * (sag * 4 * t * (1 - t)), 1.1, t * len / 32, CABLE_COL)
    end
    render.EndBeam()
end
LC_CL.DrawCable = DrawCable

-- Where a cable plugs in: the bottom of a power bank's face, the foot of a forcefield's post.
local function Plug(src)
    if src:GetClass() == "lc_powerbank" then
        local mins, maxs = src:OBBMins(), src:OBBMaxs()
        return src:LocalToWorld(Vector(maxs.x, 0, mins.z + (maxs.z - mins.z) * 0.15))
    end
    return src:GetPos() + Vector(0, 0, 8)
end

local FED = { "npc_turret_floor", "lc_forcefield" }

hook.Add("PostDrawOpaqueRenderables", "LivingCityCables", function(depth, sky)
    if depth or sky then return end
    local eye = EyePos()
    local drew = false
    for _, cls in ipairs(FED) do
        for _, e in ipairs(LC.EntsOf(cls)) do
            if IsValid(e) and e:GetPos():DistToSqr(eye) < 2500 * 2500 then
                local src = e:GetNW2Entity("lc_cable")
                if IsValid(src) and src ~= e then
                    if not drew then render.SetMaterial(CABLE) drew = true end
                    -- into a turret's body, not between its legs; a forcefield's at the foot of its post
                    local from = cls == "npc_turret_floor" and (e:GetPos() + e:GetUp() * 34) or (e:GetPos() + Vector(0, 0, 6))
                    DrawCable(from, Plug(src))
                end
            end
        end
    end
end)
