--[[
    Conveyor belt (Living City). Place it with the Living City Editor
    ("Fixture: factory conveyor") at the factory: the Factory Worker's "On the
    line" shift runs parts along it (sv_livingcity_jobgames.lua). A factory
    with none gets one set up for the shift and taken away after.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Conveyor belt"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODEL = "models/hunter/plates/plate1x6.mdl"

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMaterial("phoenix_storms/metalset_1-2")
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if CLIENT then
    local BELT, STRIPE, EDGE = Color(28, 28, 30), Color(70, 70, 74), Color(150, 120, 40)
    function ENT:Draw()
        self:DrawModel()
        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 1500 * 1500 then return end
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        local alongX = (maxs.x - mins.x) >= (maxs.y - mins.y)
        local len = alongX and (maxs.x - mins.x) or (maxs.y - mins.y)
        local wid = alongX and (maxs.y - mins.y) or (maxs.x - mins.x)
        local ang = self:GetAngles()
        if not alongX then ang:RotateAroundAxis(ang:Up(), 90) end
        local pos = self:LocalToWorld(Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, maxs.z + 0.3))
        -- the belt, its slats sliding along while the line runs
        local k = 4 -- units per 3D2D pixel
        cam.Start3D2D(pos, ang, 1 / k)
            local w, h = len * k, wid * k
            surface.SetDrawColor(BELT)
            surface.DrawRect(-w / 2, -h / 2 + 6, w, h - 12)
            local run = self:GetNW2Bool("lc_running", false)
            local off = run and ((CurTime() * 60 * k) % (40 * k)) or 0
            surface.SetDrawColor(STRIPE)
            for x = -w / 2 - 40 * k + off, w / 2, 40 * k do
                if x > -w / 2 and x + 6 * k < w / 2 then surface.DrawRect(x, -h / 2 + 6, 6 * k, h - 12) end
            end
            surface.SetDrawColor(EDGE)
            surface.DrawRect(-w / 2, -h / 2, w, 6)
            surface.DrawRect(-w / 2, h / 2 - 6, w, 6)
        cam.End3D2D()
    end
end
