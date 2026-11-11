--[[
    Storage crate (Living City). A player sets one down from their pockets
    (a "Storage crate" from the Commissary); only they can open it, and units.
    It stays where it was put, across restarts.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Storage crate"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_junk/wood_crate001a.mdl")
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
