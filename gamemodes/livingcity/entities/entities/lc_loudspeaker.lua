--[[ Loudspeaker (Living City): placed with the editor ("Street: loudspeaker").
     The city's PA comes out of these. Broken (shot, or worn out), the
     announcements and broadcasts can't be heard near it until the radio
     repair crew fixes it (their "Loudspeakers" shift goes to broken ones first). ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Loudspeaker"
ENT.Author = "Miscount"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_wasteland/speakercluster01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:OnTakeDamage(dmg)
        if dmg:GetDamage() >= 10 and LC and LC.BreakStreetFixture then LC.BreakStreetFixture(self, dmg:GetAttacker()) end
    end
end
