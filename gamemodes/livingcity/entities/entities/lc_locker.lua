--[[
    Locker (Living City). Place it with the Living City Editor ("Fixture:
    locker") so it saves with the map layout. The first person to put
    something in it claims it; after that only they can open it (units can).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Locker"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/lockers001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.OpenContainer then LC.OpenContainer(activator, self) end
    end
end
