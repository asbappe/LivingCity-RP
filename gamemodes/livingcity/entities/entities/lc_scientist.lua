--[[
    The Resistance's scientist (Living City). He stands at a Resistance lab
    (lc_workbench), which puts him there; he isn't placed by himself. E on
    him: the Resistance get what he can make, anyone else is shown the door,
    and a unit shuts the lab down. See sv_livingcity_lab.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Resistance scientist"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

local MODELS = { "models/kleiner.mdl", "models/humans/group02/male_02.mdl" }
local IDLES = { "idle_subtle", "LineIdle01", "idle01", "Idle01", "idle_all_01", "idle" }

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[1]
    if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    self:SetModel(m)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)
    local seq
    for _, name in ipairs(IDLES) do
        local s = self:LookupSequence(name)
        if s and s >= 0 then seq = s break end
    end
    if not seq and self.SelectWeightedSequence then
        local s = self:SelectWeightedSequence(ACT_IDLE)
        if s and s >= 0 then seq = s end
    end
    if seq then self:ResetSequence(seq) end
end

if SERVER then
    function ENT:Think()
        self:NextThink(CurTime())
        return true
    end

    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseScientist then LC.UseScientist(activator, self) end
    end
end

if CLIENT then
    function ENT:Draw()
        if self:GetNW2Float("lc_away_until", 0) > CurTime() then return end
        self:DrawModel()
    end
end
