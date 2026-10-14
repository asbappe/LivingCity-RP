--[[ An ichthyosaur (Living City): the secret ending "The Flood"
     (sv_livingcity_endings.lua). Swims under the floodwater the ending
     draws, circles the stage, goes for anyone in the water and leaps at
     anyone near the edge. Every move it makes is the ending's (LC.IcthyStep,
     each server tick): the map has no real water there for the game's own. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ichthyosaur"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
    if CLIENT then
        self:SetRenderBounds(Vector(-140, -60, -40), Vector(140, 60, 60))
        return
    end
    self.lcThinks = true
    self:SetModel("models/ichthyosaur.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-60, -30, -20), Vector(60, 30, 30))
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    local seq = self:LookupSequence("swim")
    if seq and seq >= 0 then self:ResetSequence(seq) end
end

function ENT:Think()
    if SERVER then
        if LC and LC.IcthyStep then LC.IcthyStep(self, FrameTime()) end
        self:NextThink(CurTime())
        return true
    end
end

function ENT:OnTakeDamage(dmg)
    if LC and LC.IcthyHurt then LC.IcthyHurt(self, dmg) end
end
