--[[ The larval extract, dropped (Living City, sv_livingcity_swarm.lua): it lies glowing where its carrier fell or
     its vortigaunt died. Anyone not Combine picks it up (E); a Combine player's E pockets it, and the Combine's
     shots, blows and boots burst it. Episode Two's own essence, three times its size, in a box that shots and the
     use key find (the model itself has no collision). Not spawnable: the gamemode puts it down. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Larval extract"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODEL = "models/props_hive/larval_essence.mdl"

function ENT:Initialize()
    self:SetModel(MODEL)
    if self.SetModelScale then self:SetModelScale(3, 0) end
    if CLIENT then return end
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-8, -8, 0), Vector(8, 8, 14))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
end

if SERVER then
    -- (the gamemode's own hooks answer first, PlayerUse and EntityTakeDamage; these are for the same, and do nothing twice)
    function ENT:Use(activator)
        if LC and LC.Swarm and LC.Swarm.UseExtract then LC.Try(LC.Swarm.UseExtract, activator, self) end
    end
    function ENT:OnTakeDamage(dmg)
        if LC and LC.Swarm and LC.Swarm.HurtExtract then LC.Try(LC.Swarm.HurtExtract, self, dmg) end
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    local GLOW = Color(190, 255, 140)
    function ENT:Draw() self:DrawModel() end
    function ENT:DrawTranslucent()
        if not render then return end
        local s = 30 + 6 * math.sin(CurTime() * 3)
        render.SetMaterial(glow)
        render.DrawSprite(self:GetPos() + Vector(0, 0, 6), s, s, GLOW)
    end
    function ENT:Think()
        if not DynamicLight then return end
        local d = DynamicLight(self:EntIndex())
        if d then
            d.pos = self:GetPos() + Vector(0, 0, 10)
            d.r, d.g, d.b = GLOW.r, GLOW.g, GLOW.b
            d.brightness = 2
            d.Decay = 600
            d.Size = 160
            d.DieTime = CurTime() + 0.3
        end
    end
end
