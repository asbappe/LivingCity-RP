--[[
    Black market dealer (Living City). Place it with the Living City Editor
    ("Fixture: black market dealer") so it saves with the map layout.

    Citizens and the Resistance press E to buy contraband and sell what
    they've picked up. Civil Protection units who press E bust the dealer,
    which disappears for a while.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Black market dealer"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

local MODELS = {
    "models/humans/group03/male_06.mdl", "models/humans/group03/male_08.mdl",
    "models/humans/group03/female_02.mdl", "models/humans/group03/male_03.mdl",
}
local IDLES = { "LineIdle01", "LineIdle02", "idle_subtle", "Idle_Unarmed" }

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(MODELS[math.random(#MODELS)])
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)
    for _, name in ipairs(IDLES) do
        local seq = self:LookupSequence(name)
        if seq and seq >= 0 then
            self:ResetSequence(seq)
            break
        end
    end
end

if SERVER then
    function ENT:Think()
        self:NextThink(CurTime())
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if self:GetNW2Bool("lc_busted", false) then return end
        if LC.PlayerIsCP(activator) then
            if LC.BustDealer then LC.BustDealer(activator, self) end
        elseif LC.OpenMarket then
            LC.OpenMarket(activator)
        end
    end
end

if CLIENT then
    function ENT:Draw()
        if self:GetNW2Bool("lc_busted", false) then return end
        self:DrawModel()
    end
end
