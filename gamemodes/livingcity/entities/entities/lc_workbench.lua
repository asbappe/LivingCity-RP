--[[
    Resistance lab (Living City). Place it with the Living City Editor
    ("Fixture: Resistance lab"), in rebel territory: every rebel base needs
    one for its guns. One of Dr. Kleiner's own lab workstations, and
    a scientist beside it (lc_scientist) who makes guns, ammunition, armour,
    jammers and radios for the Resistance. E on him, or on the bench.
    See sv_livingcity_lab.lua.

    (Its class is still lc_workbench, so a layout with a workbench in it
    keeps working: that workbench is a lab now.)
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Resistance lab"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = true
ENT.AdminOnly = true

-- Dr. Kleiner's own lab workstations first (monitors, kit and all), then a plain desk for the clutter
local KLEINER = { "models/props_lab/workspace003.mdl", "models/props_lab/workspace001.mdl", "models/props_lab/workspace002.mdl" }
local MODELS = { "models/props_wasteland/controlroom_desk001b.mdl", "models/props_c17/FurnitureTable001a.mdl" }

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, k in ipairs(KLEINER) do if not util.IsValidModel or util.IsValidModel(k) then m = k self.lcKleiner = true break end end
    if not m then
        m = MODELS[1]
        if util.IsValidModel and not util.IsValidModel(m) then m = MODELS[2] end
    end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    -- the clutter and the scientist, once it's been set down where it goes
    timer.Simple(0.3, function() if IsValid(self) and LC and LC.SetupLab then LC.SetupLab(self) end end)
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC then return end
        if IsValid(self.lcScientist) and LC.UseScientist then LC.UseScientist(activator, self.lcScientist) end
    end

    function ENT:OnRemove()
        if IsValid(self.lcScientist) then self.lcScientist:Remove() end
        for _, c in ipairs(self.lcClutter or {}) do if IsValid(c) then c:Remove() end end
    end
end
