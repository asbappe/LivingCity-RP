--[[ A mess on the ground (Living City): left where someone soiled themselves
     (sv_livingcity_hygiene.lua). It stays until it's scrubbed up: E on it
     (a Sanitation Worker is paid for it; anyone risks catching something),
     or the city's own sanitation crews get to it. Flies hang over it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "A mess"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    if CLIENT then
        self:SetRenderBounds(Vector(-30, -30, -2), Vector(30, 30, 30))
        return
    end
    self:SetModel("models/hunter/plates/plate05x05.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-18, -18, 0), Vector(18, 18, 4))
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(false)
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC or not LC.CleanStain then return end
        local ok, why = LC.CleanStain(activator, self)
        if not ok and why then activator:ChatPrint(why) end
    end
end

if CLIENT then
    local BLOT = Material("particle/smokesprites_0001")
    local FLY = Color(20, 20, 15, 230)
    local STAIN = Color(70, 45, 20, 235)
    function ENT:Draw() end
    function ENT:DrawTranslucent()
        -- laid along the floor it's on, whatever its slope (its up is the floor's normal; level
        -- for the messes sv_livingcity_hygiene.lua leaves)
        local up = self:GetUp()
        local pos = self:GetPos() + up * 0.5
        render.SetMaterial(BLOT)
        render.DrawQuadEasy(pos, up, 40, 34, STAIN, self:GetAngles().y)
        render.DrawQuadEasy(pos + self:GetForward() * 6 - self:GetRight() * 4 + up * 0.1, up, 22, 18, STAIN, self:GetAngles().y + 70)
        -- flies
        render.SetColorMaterial()
        local t = CurTime()
        for i = 1, 6 do
            local a = t * (2 + i * 0.37) + i * 1.7
            local p = pos + Vector(math.cos(a) * (6 + i * 2), math.sin(a * 1.3) * (6 + i * 2), 6 + math.sin(t * 3 + i) * 4 + i)
            render.DrawSphere(p, 0.5, 4, 4, FLY)
        end
    end
end
