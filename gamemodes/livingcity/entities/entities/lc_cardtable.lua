--[[
    Card table (Living City). Place it with the Living City Editor ("Fixture: card table") in a back room on
    rebel ground; anywhere else it does nothing. E opens one small window: a bet, and high card against the
    house, the house's take going to the Resistance's fund. See sv_livingcity_resistancemoney.lua and
    cl_livingcity_cards.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Card table"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_c17/furnituretable001a.mdl", "models/props_wasteland/cafeteria_table001a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[1]
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.OpenCardTable then LC.OpenCardTable(activator, self) end
    end
end
