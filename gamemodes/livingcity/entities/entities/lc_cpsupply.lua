--[[
    Civil Protection Commissary (Living City). Place it with the Living City
    Editor ("Fixture: Civil Protection Commissary"), somewhere units go: the
    nexus, a station. A unit presses E and is issued what their rank allows:
    grenades, ammunition for their issued weapons, armour, bandages, and a
    ration now and then. Then the unit counter of the Commissary opens, for
    anything more. Anyone else is turned away. See sv_livingcity_cpsupply.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Civil Protection Commissary"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_combine/combine_interface002.mdl", "models/props_combine/combine_interface001.mdl" }

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
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseCPSupply then LC.UseCPSupply(activator, self) end
    end
end

if CLIENT then
    -- its sign, the Civil Intake terminals' style (cl_livingcity_intake.lua; the owner, 7 November)
    function ENT:Draw()
        self:DrawModel()
        if LC_CL and LC_CL.TerminalSign then LC_CL.TerminalSign(self, "CP COMMISSARY", "Units: your issue is here. Press E") end
    end
end
