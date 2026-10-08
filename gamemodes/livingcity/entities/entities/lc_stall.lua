--[[
    Market stall (Living City). A licensed trader sets one down from their
    pockets and sells from it at their own prices. Press E to see what's on it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Market stall"
ENT.Author = "Living City"
ENT.Category = "Living City"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_c17/FurnitureTable001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.OpenContainer then LC.OpenContainer(activator, self) end
    end
end

if CLIENT then
    -- the sign: whose stall it is
    function ENT:Draw()
        self:DrawModel()
        local owner = self:GetNW2String("lc_owner_name", "")
        if owner == "" or LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 600 * 600 then return end
        cam.Start3D2D(self:GetPos() + Vector(0, 0, 48), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.12)
            draw.RoundedBox(6, -170, -30, 340, 60, Color(20, 22, 26, 220))
            draw.SimpleText(owner .. "'s stall", "DermaLarge", 0, -8, Color(235, 200, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Licensed by the CWU. Press E", "DermaDefault", 0, 16, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
