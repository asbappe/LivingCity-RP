--[[ Combine master terminal (Living City): the motherlode. Place it with the
     editor ("Fixture: Combine master terminal"), one in the nexus. A Hacker
     aims the multitool at it and holds on for a full minute; what comes out is
     a master data core (sv_livingcity_heist.lua). Maps that already have a
     masterinterface prop get one for free. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine master terminal"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true

local MODELS = { "models/props_combine/masterinterface.mdl", "models/props_combine/combine_interface001.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or MODELS[#MODELS])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end
-- (the multitool and E are handled in sv_livingcity_heist.lua)
