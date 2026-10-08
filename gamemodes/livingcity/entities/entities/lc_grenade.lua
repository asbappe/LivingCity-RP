--[[ A thrown grenade (Living City): smoke, flashbang or chlorine gas. Goes off after a short fuse. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Grenade"
ENT.Author = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/weapons/w_grenade.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    if self.SetCollisionGroup then self:SetCollisionGroup(COLLISION_GROUP_WEAPON) end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    self.lcBlowAt = CurTime() + (self.lcKind == "flash" and 1.6 or 1.2)
    self:NextThink(CurTime())
end

if SERVER then
    function ENT:Think()
        if CurTime() >= (self.lcBlowAt or 0) and not self.lcDone then
            self.lcDone = true
            if LC and LC.Detonate then LC.Detonate(self.lcKind or "smoke", self:GetPos(), self.lcOwner) end
            self:Remove()
            return
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end

    function ENT:PhysicsCollide(data)
        if data.Speed > 120 then self:EmitSound("weapons/hegrenade/he_bounce-1.wav", 60) end
    end
end
