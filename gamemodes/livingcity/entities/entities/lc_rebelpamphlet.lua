--[[ A Resistance pamphlet left lying about (Living City, sv_livingcity_rebelpamphlet.lua). Press E to read it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Resistance pamphlet"
ENT.Author = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/paper01.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-6, -8, -1), Vector(6, 8, 2))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)
    self:SetColor(Color(216, 200, 190))
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.ReadRebelPamphlet then LC.ReadRebelPamphlet(activator, self) end
    end
end

if CLIENT then
    function ENT:Draw() self:DrawModel() end
end
