--[[ A bathtub (Living City): the editor's "Fixture: bathtub". E on it to wash:
     sv_livingcity_hygiene.lua. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Bathtub"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true

local MODELS = { "models/props_interiors/BathTub01a.mdl", "models/props_c17/FurnitureBathtub001a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[#MODELS]
    for _, c in ipairs(MODELS) do if not util.IsValidModel or util.IsValidModel(c) then m = c break end end
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
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if LC.UseBath then LC.UseBath(activator) end
    end
end
