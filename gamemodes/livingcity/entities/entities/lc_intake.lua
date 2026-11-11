--[[
    Civil Intake terminal (Living City). Place it with the Living City Editor:
    "Fixture: Civil Intake (registration)", "Fixture: Housing Allocation" or
    "Fixture: Labor Assignment". New arrivals register at the first (their
    name, face and description, and a citizen number), are given Union work
    at Labor Assignment (when the map has one), then ask Housing Allocation
    for a room. Press E. See sv_livingcity_intake.lua and sv_livingcity_labor.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Civil Intake terminal"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_combine/combine_interface001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    -- which desk this is (the editor's point kind): "register", "housing" or "labor"
    local k = self.lcFixtureKind
    self:SetNW2String("lc_ikind", (k == "housingterm" and "housing") or (k == "laborterm" and "labor") or "register")
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseIntake then LC.UseIntake(activator, self) end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 700 * 700 then return end
        if LC_CL and LC_CL.DrawIntakeSign then
            local ang = self:GetAngles()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)
            cam.Start3D2D(self:GetPos() + self:GetUp() * 78 + self:GetForward() * 4, ang, 0.08)
                LC_CL.DrawIntakeSign(self)
            cam.End3D2D()
        end
    end
end
