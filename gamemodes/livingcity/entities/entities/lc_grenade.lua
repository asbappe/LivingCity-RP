--[[ A thrown grenade (Living City): smoke, flashbang or chlorine gas. Goes off after a short fuse. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Grenade"
ENT.Author = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    -- the Resistance's firebomb is a bottle with a burning rag; the rest look like grenades
    self:SetModel(self.lcKind == "fire" and "models/props_junk/garbage_glassbottle001a.mdl" or "models/weapons/w_grenade.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    if self.SetCollisionGroup then self:SetCollisionGroup(COLLISION_GROUP_WEAPON) end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    self.lcBlowAt = CurTime() + (self.lcKind == "flash" and 1.6 or 1.2)
    if self.lcKind == "fire" and self.Ignite then self:Ignite(3) end
    self:NextThink(CurTime())
end

if SERVER then
    -- a bottle breaks where it lands
    function ENT:PhysicsCollide(data)
        if self.lcKind == "fire" and not self.lcDone and (data.Speed or 0) > 60 then self.lcBlowAt = 0 end
    end

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
