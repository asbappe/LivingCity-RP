--[[
    The resupply scanner's crate (Living City; sv_livingcity_radiohq.lua): a supply crate shrunk to a quarter
    of its size, dropped from the scanner. It breaks open when it hits the ground and leaves what's in it
    lying there for the unit (or whoever gets there first).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Resupply crate"
ENT.Author = "Miscount"
ENT.Spawnable = false

local MODEL = "models/items/item_item_crate.mdl"
local SCALE = 0.25

function ENT:Initialize()
    self:SetModel(MODEL)
    self:SetModelScale(SCALE, 0)
    if CLIENT then return end
    -- a box the crate's shrunken size, for physics
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    if self.PhysicsInitBox then self:PhysicsInitBox(mins * SCALE, maxs * SCALE) else self:PhysicsInit(SOLID_VPHYSICS) end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    if self.SetCollisionBounds then self:SetCollisionBounds(mins * SCALE, maxs * SCALE) end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:SetMass(10) phys:Wake() end
    self.lcBreakBy = CurTime() + 8 -- (stuck on something on the way down: it breaks anyway)
    self:NextThink(CurTime())
end

if SERVER then
    function ENT:Break()
        if self.lcBroken then return end
        self.lcBroken = true
        local pos = self:GetPos()
        self:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav", 75)
        local fx = EffectData and EffectData()
        if fx then
            fx:SetOrigin(pos)
            fx:SetScale(0.4)
            fx:SetMagnitude(1)
            util.Effect("WheelDust", fx, true, true)
        end
        if LC and LC.ResupplySpill then LC.ResupplySpill(self, pos) end
        self:Remove()
    end

    function ENT:PhysicsCollide(data)
        if self.lcBroken then return end
        -- it lands: broken open (on the next tick, not in the middle of the physics)
        if (data.Speed or 0) > 40 or (data.HitNormal and data.HitNormal.z < -0.5) then
            timer.Simple(0, function() if IsValid(self) then self:Break() end end)
        end
    end

    function ENT:Think()
        if not self.lcBroken and CurTime() > (self.lcBreakBy or 0) then self:Break() return end
        self:NextThink(CurTime() + 0.5)
        return true
    end
end

if CLIENT then
    function ENT:Draw() self:DrawModel() end
end
