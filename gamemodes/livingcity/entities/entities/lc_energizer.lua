--[[ The stalker's transformer (Living City): a second power transformer a
     stalker builds, part by part, right beside one of the city's own
     (sv_livingcity_stalkerwork.lua). Bare frame, then cells, then the
     housing, then the charge: the current jumps the gap between the two,
     and walking into it kills. lc_built 0..3 says how far along; lc_partner
     is the city's transformer beside it. (Its old name, the energizer, stays
     in the code.) ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Energizer"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODEL = "models/props_combine/combine_generator01.mdl"
local FALLBACK = "models/props_combine/combine_interface001.mdl"

function ENT:Initialize()
    if CLIENT then
        self:SetRenderBounds(Vector(-200, -200, -10), Vector(200, 200, 160)) -- (the arc reaches over to the transformer beside it)
        return
    end
    local m = MODEL
    if util.IsValidModel and not util.IsValidModel(m) then m = FALLBACK end
    self:SetModel(m)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self:SetUseType(SIMPLE_USE)
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseEnergizer then LC.UseEnergizer(activator, self) end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local BALL = Material("effects/ar2_altfire1")
    function ENT:Draw()
        self:DrawModel()
    end
    local ARC = Material("trails/electric")
    -- A jagged line of current from a to b, new every frame.
    local function Arc(a, b, width, col)
        local n = 9
        render.StartBeam(n + 1)
        for i = 0, n do
            local f = i / n
            local p = LerpVector(f, a, b)
            if i > 0 and i < n then p = p + VectorRand() * 7 end
            render.AddBeam(p, width, f * 3 + CurTime() * 6, col)
        end
        render.EndBeam()
    end
    function ENT:DrawTranslucent()
        local built = self:GetNW2Int("lc_built", 0)
        if built <= 0 then return end
        local t = CurTime()
        local partner = self:GetNW2Entity("lc_partner")
        local flash = math.max(0, 1 - (t - self:GetNW2Float("lc_flash", -100)) / 2)
        if built >= 3 and IsValid(partner) then
            -- the current across the gap, at three heights, never still
            local a, b = self:WorldSpaceCenter(), partner:WorldSpaceCenter()
            local dir = (b - a):GetNormalized()
            local ra = math.max(10, (self:OBBMaxs().y - self:OBBMins().y) * 0.5)
            local rb = math.max(10, (partner:OBBMaxs().y - partner:OBBMins().y) * 0.5)
            render.SetMaterial(ARC)
            for _, h in ipairs({ -22, 0, 22 }) do
                Arc(a + dir * ra + Vector(0, 0, h), b - dir * rb + Vector(0, 0, h), 6 + 4 * math.random() + flash * 30, Color(170, 220, 255, 230))
            end
            render.SetMaterial(GLOW)
            render.DrawSprite((a + b) * 0.5, 90 + flash * 400, 90 + flash * 400, Color(150, 210, 255, 90 + 120 * flash))
            return
        end
        local pos = self:WorldSpaceCenter() + Vector(0, 0, 36)
        local size = built >= 3 and (34 + 6 * math.sin(t * 2.2)) or (8 * built)
        render.SetMaterial(GLOW)
        render.DrawSprite(pos, size * 2.4 + flash * 400, size * 2.4 + flash * 400, Color(170, 220, 255, 140 + 110 * flash))
        if built >= 3 then
            render.SetMaterial(BALL)
            render.DrawSprite(pos, size, size, Color(255, 255, 255, 255))
        end
    end
    function ENT:Think()
        if self:GetNW2Int("lc_built", 0) < 3 or not DynamicLight then return end
        local d = DynamicLight(self:EntIndex())
        local partner = self:GetNW2Entity("lc_partner")
        if d then
            d.pos = IsValid(partner) and (self:WorldSpaceCenter() + partner:WorldSpaceCenter()) * 0.5 or (self:WorldSpaceCenter() + Vector(0, 0, 36))
            d.r, d.g, d.b = 150, 210, 255
            d.brightness = 2
            d.decay = 600
            d.size = 220
            d.dietime = CurTime() + 0.2
        end
    end
end
