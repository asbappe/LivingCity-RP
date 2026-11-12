--[[
    Evidence locker (Living City). Place it with the Living City Editor
    ("Fixture: evidence locker") so it saves with the map layout. It is a door
    into what Civil Protection has confiscated (sv_livingcity_evidence.lua):
    a unit opens it, anyone else has to pick it or pry it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Evidence locker"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_wasteland/controlroom_storagecloset001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetNW2Bool("lc_evlocker", true)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.EvidenceLockerUse then LC.EvidenceLockerUse(activator, self) end
    end
end
