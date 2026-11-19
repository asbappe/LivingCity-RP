--[[
    Resistance fund screen (Living City). Place it with the Living City Editor ("Fixture: Resistance
    fund screen"), on a table in a rebel camp. The apartment's small TV, showing what the Resistance's
    fund holds, big and plain. E on it: its window, with the fund's record and a way to donate
    (sv_livingcity_fundgear.lua, cl_livingcity_fundtv.lua). Anyone who can reach it can use it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Resistance fund screen"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

local MODEL = "models/props_c17/tv_monitor01.mdl"

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if not (IsValid(activator) and activator:IsPlayer() and LC and LC.FundScreenOpen) then return end
        if (activator.lcFundTVNext or 0) > CurTime() then return end
        activator.lcFundTVNext = CurTime() + 0.5
        LC.FundScreenOpen(activator, self)
    end
end

if CLIENT then
    surface.CreateFont("LCFundTVNum", { font = "Arial", size = 150, weight = 900 })
    surface.CreateFont("LCFundTVSub", { font = "Arial", size = 46, weight = 700 })

    local BG, INK, DIM = Color(8, 14, 10, 255), Color(150, 235, 140), Color(90, 150, 90)
    -- the TV's glass, as lc_screen.lua has it for this model: centre across, centre up, how wide, how tall
    -- (fractions of its front), how far in front of its frontmost point; stretched to fill the glass
    local GLASS = { 0.40, 0.55, 0.70, 0.76, -1.2 }

    local function Place(self)
        local mins, maxs = self:GetModelBounds()
        local k = self:GetModelScale() or 1
        mins, maxs = mins * k, maxs * k
        local wide, tall = maxs.y - mins.y, maxs.z - mins.z
        local sx, sy = wide * GLASS[3] / 640, tall * GLASS[4] / 360
        return self:LocalToWorld(Vector(maxs.x + GLASS[5], mins.y + wide * GLASS[1], mins.z + tall * GLASS[2])), sx, sy / sx
    end

    function ENT:Draw()
        self:DrawModel()
        if self:GetNW2Bool("lc_nopower", false) then return end -- (no power in the district: a dead screen)
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 700 * 700 then return end
        local pos, scale, stretch = Place(self)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        cam.Start3D2D(pos, ang, scale)
            local m = Matrix and cam.PushModelMatrix and Matrix()
            if m then
                m:Scale(Vector(1, stretch, 1))
                cam.PushModelMatrix(m, true)
            end
            draw.RoundedBox(0, -320, -180, 640, 360, BG)
            draw.SimpleText(tostring(GetGlobal2Int("lc_fund", 0)), "LCFundTVNum", 0, -30, INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("credits", "LCFundTVSub", 0, 90, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if m then cam.PopModelMatrix() end
        cam.End3D2D()
    end
end
