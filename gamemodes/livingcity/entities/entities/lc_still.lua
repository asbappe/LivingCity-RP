--[[
    Resistance still (Living City). Place it with the Living City Editor ("Fixture: Resistance still"), in a
    camp or by the lab. A Resistance member presses E with the makings in their pockets and it brews moonshine
    by itself for a few minutes, steaming and hissing quietly while it works; E when it is done takes the
    bottles. See sv_livingcity_resistancemoney.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Resistance still"
ENT.Author = "Miscount"
ENT.Category = "Miscount"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- (the owner, 19 November: "please use models/props_forest/sawmill_boiler.mdl for the moonshine entity prop"; Episode 2's,
-- which Garry's Mod ships; the older boiler and a drum only if a server somehow lacks it)
local MODELS = { "models/props_forest/sawmill_boiler.mdl", "models/props_c17/furnitureboiler001a.mdl", "models/props_c17/oildrum001.mdl" }
ENT.Models = MODELS

function ENT:Initialize()
    if CLIENT then return end
    local m = MODELS[#MODELS]
    for _, c in ipairs(MODELS) do
        if not util.IsValidModel or util.IsValidModel(c) then m = c break end
    end
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
        if IsValid(activator) and activator:IsPlayer() and LC and LC.UseStill then LC.UseStill(activator, self) end
    end
end

if CLIENT then
    -- while it brews: a little steam off the top, and a quiet hiss (nothing to read)
    function ENT:Think()
        local brewing = self:GetNW2Float("lc_brew_done", 0) > CurTime()
        if brewing then
            if not self.lcHiss and CreateSound then
                self.lcHiss = CreateSound(self, "ambient/gas/steam_loop1.wav")
                if self.lcHiss then self.lcHiss:PlayEx(0.18, 80) end
            end
            if (self.lcPuffAt or 0) < CurTime() and ParticleEmitter and LocalPlayer and IsValid(LocalPlayer())
                and LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 1500 * 1500 then
                self.lcPuffAt = CurTime() + 0.35
                local top = self:LocalToWorld(Vector(0, 0, self:OBBMaxs().z))
                local em = ParticleEmitter(top)
                if em then
                    local p = em:Add("particle/particle_smokegrenade", top + VectorRand() * 4)
                    if p then
                        p:SetVelocity(Vector(math.Rand(-6, 6), math.Rand(-6, 6), math.Rand(18, 30)))
                        p:SetDieTime(math.Rand(1.6, 2.4))
                        p:SetStartAlpha(70)
                        p:SetEndAlpha(0)
                        p:SetStartSize(4)
                        p:SetEndSize(18)
                        p:SetColor(225, 225, 225)
                        p:SetRoll(math.Rand(0, 360))
                    end
                    em:Finish()
                end
            end
        elseif self.lcHiss then
            self.lcHiss:Stop()
            self.lcHiss = nil
        end
        if self.SetNextClientThink then self:SetNextClientThink(CurTime() + 0.1) end
        return true
    end
    function ENT:OnRemove()
        if self.lcHiss then self.lcHiss:Stop() self.lcHiss = nil end
    end
end
