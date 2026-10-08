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
    function ENT:Draw()
        self:DrawModel()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 900 * 900 then return end
        if LC_CL and LC_CL.DrawLawBoard then
            local ang = self:GetAngles()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)
            cam.Start3D2D(self:GetPos() + self:GetForward() * 6 + self:GetUp() * 36, ang, 0.1)
                LC_CL.DrawLawBoard(self)
            cam.End3D2D()
        end
    end
end
