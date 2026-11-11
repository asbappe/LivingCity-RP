--[[ Burning barrel (Living City). Place it with the Living City Editor so it saves with the map layout. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Burning barrel"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/oildrum001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    -- flames on top that never go out and never burn anyone
    local fire = ents.Create("env_fire")
    if IsValid(fire) then
        fire:SetPos(self:GetPos() + Vector(0, 0, 46))
        fire:SetKeyValue("firesize", "36")
        fire:SetKeyValue("damagescale", "0")
        fire:SetKeyValue("spawnflags", tostring(1 + 4 + 8 + 16))
        fire:SetParent(self)
        fire:Spawn()
        fire:Fire("StartFire")
        self.lcFlame = fire
    end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if LC.SendInv then LC.SendInv(activator, true) end
    end
end

function ENT:OnRemove()
    if SERVER and IsValid(self.lcFlame) then self.lcFlame:Remove() end
end
