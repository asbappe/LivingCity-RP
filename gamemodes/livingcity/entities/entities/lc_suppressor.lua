--[[ The suppression device (Living City): the Overwatch Nexus's mortar (Half-Life 2, Follow Freeman!), placed
     with the editor ("Fixture: the suppression device"). In sociostability BLACK it shells rebels under open sky near
     a Combine zone, one shell at a time (sv_livingcity_collapse.lua), and the shells come from it: a flash and the
     launch sound here, the ring and the incoming whistle where it lands. Rebels can blow it up (the owner, 10 November:
     "the rebels can find it on the map and blow it up to stop the mortar fire"): it sparks and smokes as it goes, and
     destroyed, the shelling stops till the collapse is over. Outside BLACK nothing harms it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "The suppression device"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local MODELS = { "models/props_combine/combine_mortar01a.mdl", "models/props_combine/combine_mortar01b.mdl", "models/props_combine/combine_generator01.mdl" }

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
        if LC and LC.SuppressorHit then LC.SuppressorHit(self, dmg) end
    end
end

if CLIENT then
    local SMOKE = "particle/particle_smokegrenade"
    function ENT:Draw()
        local down = self:GetNW2Bool("lc_power_down", false)
        if down then render.SetColorModulation(0.25, 0.22, 0.25) end
        self:DrawModel()
        if down then render.SetColorModulation(1, 1, 1) end
    end
    function ENT:DrawTranslucent() self:Draw() end
    -- smoke and sparks as it's shot up (the same as her transformers)
    function ENT:Think()
        local stage = self:GetNW2Int("lc_power_smoke", 0)
        if self:GetNW2Bool("lc_power_down", false) then stage = 4 end
        if stage <= 0 then return end
        local now = CurTime()
        if (self.lcNextPuff or 0) > now then return end
        self.lcNextPuff = now + ({ 0.6, 0.3, 0.15, 0.1 })[stage]
        local top = self:LocalToWorld(Vector(math.Rand(-10, 10), math.Rand(-10, 10), self:OBBMaxs().z * 0.8))
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
                    pt:SetColor(60, 58, 62)
                end
                em:Finish()
            end
        end
        if stage >= 2 and math.random() < 0.3 and util.Effect and EffectData then
            local ed = EffectData()
            ed:SetOrigin(self:LocalToWorld(Vector(math.Rand(-16, 16), math.Rand(-16, 16), math.Rand(10, self:OBBMaxs().z))))
            ed:SetMagnitude(1)
            ed:SetScale(1)
            ed:SetRadius(2)
            util.Effect("Sparks", ed)
        end
    end
end
