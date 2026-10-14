--[[ A mingebag (Living City): the secret ending "The Harpies"
     (sv_livingcity_endings.lua). The 2007 Garry's Mod default: Dr. Kleiner
     frozen in the reference pose, a physgun stuck at his crotch, sliding.
     Every move it makes is the ending's (LC.MingeStep, each server tick);
     it only stands there and takes hits. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Mingebag"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
    if CLIENT then
        self:SetRenderBounds(Vector(-40, -40, 0), Vector(40, 40, 90))
        return
    end
    self.lcThinks = true -- (it moves itself, every tick)
    self:SetModel(self.lcModel or "models/player/kleiner.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    -- the pose: the model's reference pose (lc_ending_minge_pose), not animating
    local pose = GetConVar("lc_ending_minge_pose") and GetConVar("lc_ending_minge_pose"):GetString() or "ragdoll"
    local seq = self:LookupSequence(pose)
    if not seq or seq < 0 then seq = self:LookupSequence("reference") end
    if seq and seq >= 0 then self:ResetSequence(seq) end
    self:SetCycle(0)
    self:SetPlaybackRate(0)
end

-- The physgun, at the crotch, the way a playermodel held it back then (drawn here,
-- on each player's screen: nothing more to send over the network).
local GUN = "models/weapons/w_physics.mdl"
function ENT:Draw()
    self:DrawModel()
    if not ClientsideModel then return end
    if not IsValid(self.lcGun) then
        self.lcGun = ClientsideModel(GUN, RENDERGROUP_OPAQUE)
        if not IsValid(self.lcGun) then return end
        self.lcGun:SetNoDraw(true)
    end
    local ang = self:GetAngles()
    local pos = self:GetPos() + ang:Up() * 38 + ang:Forward() * 4 - ang:Right() * 2
    local ga = Angle(ang.p, ang.y - 90, ang.r) -- (lying across him, the prongs out to his right)
    self.lcGun:SetPos(pos)
    self.lcGun:SetAngles(ga)
    self.lcGun:SetupBones()
    self.lcGun:DrawModel()
end

function ENT:OnRemove()
    if CLIENT and IsValid(self.lcGun) then self.lcGun:Remove() end
end

function ENT:Think()
    if SERVER then
        if LC and LC.MingeStep then LC.MingeStep(self, FrameTime()) end
        self:NextThink(CurTime())
        return true
    end
end

function ENT:OnTakeDamage(dmg)
    if LC and LC.MingeHurt then LC.MingeHurt(self, dmg) end
end
