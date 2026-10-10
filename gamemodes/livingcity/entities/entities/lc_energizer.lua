--[[ The energizer (Living City): a Combine ball energizer that a stalker
     builds, part by part, in the Nexus (sv_livingcity_stalkerwork.lua).
     Bare frame, then cells, then the housing, then the charge: a slow ball
     of white light turning inside it. lc_built 0..3 says how far along. ]]

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
        self:SetRenderBounds(Vector(-60, -60, -10), Vector(60, 60, 140))
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

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local BALL = Material("effects/ar2_altfire1")
    function ENT:Draw()
        self:DrawModel()
    end
    function ENT:DrawTranslucent()
        local built = self:GetNW2Int("lc_built", 0)
        if built <= 0 then return end
        local t = CurTime()
        local pos = self:WorldSpaceCenter() + Vector(0, 0, 36)
        local size = built >= 3 and (34 + 6 * math.sin(t * 2.2)) or (8 * built)
        local flash = math.max(0, 1 - (t - self:GetNW2Float("lc_flash", -100)) / 2)
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
        if d then
            d.pos = self:WorldSpaceCenter() + Vector(0, 0, 36)
            d.r, d.g, d.b = 150, 210, 255
            d.brightness = 2
            d.decay = 600
            d.size = 220
            d.dietime = CurTime() + 0.2
        end
    end
end
