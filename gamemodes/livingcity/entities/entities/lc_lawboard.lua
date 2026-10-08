--[[
    Law board (Living City). Place it with the Living City Editor ("Fixture:
    law board"). Shows the city's laws; press E to read them in full.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Law board"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_phx/rt_screen.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.ShowLaws then LC.ShowLaws(activator) end
    end
end

if CLIENT then
    -- The laws go on the glass, sized to it (drawn 640 x 360, like the city
    -- screens), just in front of it. This model is the camera tool's screen:
    -- its glass shows whatever a camera sees, so it's blacked out underneath.
    local function Place(self)
        local mins, maxs = self:GetModelBounds()
        local wide, tall = maxs.y - mins.y, maxs.z - mins.z
        local scale = math.min(wide * 0.86 / 640, tall * 0.84 / 360)
        return self:LocalToWorld(Vector(maxs.x + 0.6, (mins.y + maxs.y) / 2, (mins.z + maxs.z) / 2)), scale
    end

    local function BlankGlass(self)
        self.lcBlanked = true
        for i, m in ipairs(self:GetMaterials() or {}) do
            local l = string.lower(m)
            if string.find(l, "rt", 1, true) or string.find(l, "screen", 1, true) or string.find(l, "camera", 1, true) then
                self:SetSubMaterial(i - 1, "tools/toolsblack")
            end
        end
    end

    function ENT:Draw()
        if not self.lcBlanked then BlankGlass(self) end
        self:DrawModel()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 900 * 900 then return end
        if LC_CL and LC_CL.DrawLawBoard then
            local pos, scale = Place(self)
            local ang = self:GetAngles()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)
            cam.Start3D2D(pos, ang, scale)
                LC_CL.DrawLawBoard(self)
            cam.End3D2D()
        end
    end
end
