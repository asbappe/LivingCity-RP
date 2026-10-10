--[[ A bed (Living City): the editor's "Fixture: bed". E on it at night (or
     when you're exhausted) to sleep: sv_livingcity_rest.lua. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Bed"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true

local MODELS = { "models/props_c17/FurnitureBed001a.mdl", "models/props_wasteland/prison_bedframe001b.mdl", "models/props_c17/FurnitureMattress001a.mdl" }

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
        if LC.SleepIn then local ok, why = LC.SleepIn(activator, self) if not ok and why then activator:ChatPrint(why) end end
    end
end
