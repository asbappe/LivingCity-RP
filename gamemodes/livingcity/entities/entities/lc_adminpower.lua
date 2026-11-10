--[[ The Administrator's power (Living City): placed with the editor ("Her last stand: the Administrator's
     power"). A Combine transformer that powers her bubble shield in her last stand, when the city collapses
     to BLACK (sv_livingcity_collapse.lua). While it stands her shield deflects every bullet, as far as
     lc_black_power_range (1600 units, about 100 feet) from it; destroy it and she can be killed.
     Outside her last stand nothing can harm it. Shot in it, it shows it's working: sparks on every hit,
     smoke from three quarters, heavier smoke and sparks below half (with a small blast as it passes
     half), and a big blast when it goes. A faint purple glow pulses on it while it powers her. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "The Administrator's power"
ENT.Author = "Living City"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_combine/combine_generator01.mdl", "models/props_c17/substation_transformer01a.mdl", "models/props_lab/powerbox01a.mdl" }
local TINT = Color(205, 180, 255)

function ENT:Initialize()
    if CLIENT then return end
    local m
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
    self:SetModel(m or MODELS[#MODELS])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    if self.SetColor then self:SetColor(TINT) end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
    self:SetNW2Float("lc_power_frac", 1)
    self:SetNW2Bool("lc_power_down", false)
    self:SetNW2Int("lc_power_smoke", 0)
end

if SERVER then
    function ENT:GravGunPunt() return false end
    function ENT:GravGunPickupAllowed() return false end
    function ENT:OnTakeDamage(dmg)
        if LC and LC.CollapsePowerHit then LC.CollapsePowerHit(self, dmg) end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    local LIVE = Color(170, 130, 255, 200)
    local SMOKE = "particle/particle_smokegrenade"

    function ENT:Draw()
        local down = self:GetNW2Bool("lc_power_down", false)
        if down then render.SetColorModulation(0.25, 0.22, 0.25) end
        self:DrawModel()
        if down then render.SetColorModulation(1, 1, 1) end
    end

    function ENT:DrawTranslucent()
        self:Draw()
        if self:GetNW2Bool("lc_power_down", false) then return end
        -- (its glow: faint, pulsing, brighter while her last stand is on)
        local on = GetGlobal2Entity("lc_collapse_power") == self
        local top = self:LocalToWorld(Vector(0, 0, self:OBBMaxs().z * 0.85))
        local pulse = 0.55 + 0.45 * math.abs(math.sin(CurTime() * (on and 4 or 1.5)))
        local size = (on and 60 or 26) * pulse
        render.SetMaterial(GLOW)
        render.DrawSprite(top, size, size, Color(LIVE.r, LIVE.g, LIVE.b, (on and 200 or 70) * pulse))
    end

    -- smoke and sparks as it's shot up, more the worse it is
    function ENT:Think()
        local stage = self:GetNW2Int("lc_power_smoke", 0)
        local down = self:GetNW2Bool("lc_power_down", false)
        if down then stage = 4 end
        if stage <= 0 then return end
        local now = CurTime()
        if (self.lcNextPuff or 0) > now then return end
        self.lcNextPuff = now + ({ 0.6, 0.3, 0.15, 0.1 })[stage]
        local top = self:LocalToWorld(Vector(math.Rand(-10, 10), math.Rand(-10, 10), self:OBBMaxs().z * 0.9))
        if ParticleEmitter then
            local em = ParticleEmitter(top)
            if em then
                local pt = em:Add(SMOKE, top)
                if pt then
                    pt:SetVelocity(Vector(math.Rand(-12, 12), math.Rand(-12, 12), math.Rand(40, 80)))
                    pt:SetDieTime(math.Rand(2, 3.5))
                    pt:SetStartAlpha(stage >= 3 and 160 or 90)
                    pt:SetEndAlpha(0)
                    pt:SetStartSize(math.Rand(8, 14))
                    pt:SetEndSize(math.Rand(40, 70))
                    pt:SetColor(stage >= 3 and 40 or 90, stage >= 3 and 38 or 88, stage >= 3 and 42 or 92)
                    pt:SetRoll(math.Rand(0, 360))
                end
                em:Finish()
            end
        end
        if stage >= 2 and math.random() < (stage >= 3 and 0.45 or 0.2) and util.Effect and EffectData then
            local ed = EffectData()
            ed:SetOrigin(self:LocalToWorld(Vector(math.Rand(-16, 16), math.Rand(-16, 16), math.Rand(10, self:OBBMaxs().z))))
            ed:SetMagnitude(1)
            ed:SetScale(1)
            ed:SetRadius(2)
            util.Effect("Sparks", ed)
        end
    end
end
