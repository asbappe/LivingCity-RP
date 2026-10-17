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
    surface.CreateFont("LCSupplySign", { font = "Trebuchet MS", size = 44, weight = 700 })
    surface.CreateFont("LCSupplySignSmall", { font = "Trebuchet MS", size = 26, weight = 500 })
    local BLUE, INK = Color(120, 190, 255), Color(225, 230, 235)

    function ENT:Draw()
        self:DrawModel()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 600 * 600 then return end
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        local maxs = self:OBBMaxs()
        cam.Start3D2D(self:GetPos() + self:GetUp() * ((maxs and maxs.z or 60) + 14), ang, 0.08)
            draw.RoundedBox(6, -280, -60, 560, 120, Color(8, 16, 26, 230))
            surface.SetDrawColor(BLUE.r, BLUE.g, BLUE.b, 180)
            surface.DrawOutlinedRect(-280, -60, 560, 120, 3)
            draw.SimpleText("CIVIL PROTECTION", "LCSupplySign", 0, -18, BLUE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Commissary: Civil Protection units are issued supplies here", "LCSupplySignSmall", 0, 26, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
