--[[
    A utility box at a loudspeaker (Living City; the owner, 13 November playtest: "a small box at hip
    height by each loudspeaker point, a black cable from it to the loudspeaker"). Put there by itself
    for every loudspeaker (sv_livingcity_speakerhack.lua), never placed by hand. E on it: a Hacker
    splices the Resistance into the loudspeaker; a unit cuts a splice out; the radio repair crew mends
    a broken loudspeaker from it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Utility box"
ENT.Author = "Miscount"
ENT.Spawnable = false

ENT.Model = "models/props_lab/powerbox02d.mdl"

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(self.Model)
    if util.IsValidModel and not util.IsValidModel(self.Model) then self:SetModel("models/props_c17/consolebox01a.mdl") self:SetModelScale(0.5) end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseUtilityBox then LC.UseUtilityBox(activator, self) end
    end
end

if CLIENT then
    local CABLE = Material("cable/cable2")
    local BLACK = Color(20, 20, 20)
    function ENT:Draw()
        self:DrawModel()
        local sp = self:GetNW2Entity("lc_speaker")
        if not IsValid(sp) then return end
        -- the black cable: up from the box's top to the loudspeaker, sagging a little
        local a = self:GetPos() + self:GetUp() * 8
        local b = sp:GetPos()
        local mid = (a + b) / 2 - Vector(0, 0, 10)
        render.SetMaterial(CABLE)
        render.StartBeam(3)
        render.AddBeam(a, 1.2, 0, BLACK)
        render.AddBeam(mid, 1.2, 0.5, BLACK)
        render.AddBeam(b, 1.2, 1, BLACK)
        render.EndBeam()
    end
    function ENT:DrawTranslucent() self:Draw() end
end
