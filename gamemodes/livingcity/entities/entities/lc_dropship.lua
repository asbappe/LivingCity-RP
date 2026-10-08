--[[ Combine dropship (Living City): flown in by sv_livingcity_dropship.lua to
     bring Overwatch soldiers down at a landing zone, or to set a supply
     container down at a loading dock and lift it away again. It's scenery
     that flies: the server moves it along its path; nothing collides with it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Combine dropship"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true -- (the engines and the claws animate)

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(self.lcModel or "models/combine_dropship.mdl")
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(true)
    local seq = self:LookupSequence("idle")
    if seq and seq >= 0 then self:ResetSequence(seq) end
    self.lcRotor = CreateSound and CreateSound(self, "NPC_CombineDropship.RotorLoop") or nil
    if self.lcRotor then self.lcRotor:PlayEx(1, 100) end
end

function ENT:Think()
    if SERVER then self:NextThink(CurTime()) end
    return true
end

function ENT:OnRemove()
    if self.lcRotor then self.lcRotor:Stop() self.lcRotor = nil end
end
