--[[ A skeleton (Living City): the secret ending "Marrow"
     (sv_livingcity_endings.lua). Walks, runs at people and dances; every
     move it makes is the ending's (LC.SkelStep, each server tick), and the
     dance itself is drawn on each screen (cl_livingcity_endings.lua). ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Skeleton"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
    if CLIENT then
        self:SetRenderBounds(Vector(-40, -40, 0), Vector(40, 40, 90))
        return
    end
    self.lcThinks = true -- (it moves itself, every tick)
    self:SetModel(self.lcModel or "models/player/skeleton.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
end

function ENT:Think()
    if SERVER then
        if LC and LC.SkelStep then LC.SkelStep(self, FrameTime()) end
        self:NextThink(CurTime())
        return true
    end
end

function ENT:OnTakeDamage(dmg)
    if LC and LC.SkelHurt then LC.SkelHurt(self, dmg) end
end
