--[[ Combine data terminal (Living City): the Resistance (Member and up) press
     E on it to download Combine data onto a chip. Place it with the editor,
     best in the nexus or a Combine-only zone. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine data terminal"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true

local MODELS = { "models/props_combine/combine_intmonitor001.mdl", "models/props_combine/combine_interface001.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[1]
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end
-- (E is handled in sv_livingcity_heist.lua, for this and for the map's own Combine consoles)
