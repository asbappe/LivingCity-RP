--[[ The Advisor screen (Living City): placed with the editor ("Fixture: Advisor screen"), in the
     Administrator's office. A Combine monitor with the Advisor's dark shape on it and a slow pulse (red and
     faster while her report is due). E on it: the Administrator's dealings with the Advisors, the same menu
     as her F2 > City orders > The Advisors (sv_livingcity_advisors.lua, cl_livingcity_advisors.lua).
     Anyone else hears it refuse them. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Advisor screen"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- the Combine's own wall monitor (as the city's small Breencast screen has it); the first this install has
local MODELS = { "models/props_combine/combine_intmonitor001.mdl", "models/props_phx/rt_screen.mdl" }
local SCALE = 1.6

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or MODELS[#MODELS])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self:SetModelScale(SCALE, 0)
end

if SERVER then
    function ENT:Use(activator)
        if not (IsValid(activator) and activator:IsPlayer() and LC and LC.AdvisorScreenUse) then return end
        if (activator.lcAdvisorScreenNext or 0) > CurTime() then return end
        activator.lcAdvisorScreenNext = CurTime() + 0.5
        LC.AdvisorScreenUse(activator, self)
    end
end

if CLIENT then
    -- the glass, as lc_screen.lua has it for this monitor: the middle of its front, eight tenths of it
    local function Place(self)
        local mins, maxs = self:GetModelBounds()
        local k = self:GetModelScale() or 1
        mins, maxs = mins * k, maxs * k
        local wide, tall = maxs.y - mins.y, maxs.z - mins.z
        local scale = math.min(wide * 0.8 / 640, tall * 0.8 / 360)
        return self:LocalToWorld(Vector(maxs.x + 0.5, mins.y + wide * 0.5, mins.z + tall * 0.5)), scale
    end

    function ENT:Draw()
        self:DrawModel()
        if self:GetNW2Bool("lc_nopower", false) then return end -- (no power in the district: a dead screen)
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 1000 * 1000 then return end
        if not (LC_CL and LC_CL.DrawAdvisorScreen) then return end
        local pos, scale = Place(self)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        cam.Start3D2D(pos, ang, scale)
            LC_CL.DrawAdvisorScreen(self)
        cam.End3D2D()
    end
end
