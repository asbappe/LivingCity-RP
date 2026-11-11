--[[ A growth in the infestation (Living City, sv_livingcity_cleanup.lua): Xen growth,
     grubs, what the infestation took. It glows a sickly green and gives off spores,
     so the infestation shows from the street. Weedkiller (E) kills it (lc_dead: withered, dark);
     a cleanup worker's hoover takes it away. Fire burns it away. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Infestation growth"
ENT.Author = "Miscount"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(self.lcModel or "models/props_wasteland/antlionhill.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS) -- (walked over, but E and fire still find it)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    self:SetUseType(SIMPLE_USE)
end

if SERVER then
    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() and LC and LC.SprayNest then
            local ok, why = LC.SprayNest(activator, self)
            if not ok and why then activator:ChatPrint(why) end
        end
    end
end

if CLIENT then
    -- the server has a model this game hasn't (a workshop pack not downloaded): a stand-in, never an ERROR
    local STANDINS = { "models/antlion_grub.mdl", "models/props_junk/garbage_bag001a.mdl" }
    local function Has(m)
    if CLIENT and file and file.Exists then return file.Exists(m, "GAME") end -- (a player's own game: ask for the file itself)
    return not util.IsValidModel or util.IsValidModel(m)
end
    function ENT:Draw()
        if Has(self:GetModel()) then self:DrawModel() return end
        if not IsValid(self.lcStandin) and ClientsideModel then
            local m = Has(STANDINS[1]) and STANDINS[1] or STANDINS[2]
            self.lcStandin = ClientsideModel(m, RENDERGROUP_OPAQUE)
            if IsValid(self.lcStandin) then self.lcStandin:SetNoDraw(true) self.lcStandin:SetModelScale(1.6, 0) end
        end
        if IsValid(self.lcStandin) then
            self.lcStandin:SetPos(self:GetPos()) self.lcStandin:SetAngles(self:GetAngles())
            self.lcStandin:SetColor(self:GetColor())
            self.lcStandin:DrawModel()
        end
    end

    -- a slow green pulse, and spores drifting up, while you're near enough to see it
    -- (made once here, not every frame)
    local V_0_0_10 = Vector(0, 0, 10)
    local V_0_0_24 = Vector(0, 0, 24)
    function ENT:Think()
        local me = LocalPlayer()
        if not IsValid(me) or me:GetPos():DistToSqr(self:GetPos()) > 2500 * 2500 then return end
        if self:GetNW2Bool("lc_dead", false) then return end -- (dead: no glow, no spores)
        local t = CurTime()
        local d = DynamicLight and DynamicLight(self:EntIndex())
        if d then
            d.pos = self:GetPos() + V_0_0_24
            d.r, d.g, d.b = 120, 255, 60
            d.brightness = 1 + math.sin(t * 1.7 + self:EntIndex()) * 0.4
            d.size = 170
            d.decay = 400
            d.dietime = t + 0.3
        end
        if (self.lcSporeAt or 0) < t and ParticleEmitter then
            self.lcSporeAt = t + 0.25
            self.lcEmitter = self.lcEmitter or ParticleEmitter(self:GetPos())
            local em = self.lcEmitter
            if em then
                local p = em:Add("particle/particle_glow_04", self:GetPos() + VectorRand() * 25 + V_0_0_10)
                if p then
                    p:SetVelocity(Vector(math.Rand(-6, 6), math.Rand(-6, 6), math.Rand(12, 30)))
                    p:SetDieTime(math.Rand(2.5, 4))
                    p:SetStartAlpha(160) p:SetEndAlpha(0)
                    p:SetStartSize(math.Rand(2, 4)) p:SetEndSize(1)
                    p:SetColor(150, 255, 90)
                    p:SetAirResistance(20)
                end
            end
        end
        self:SetNextClientThink(t + 0.1)
        return true
    end

    function ENT:OnRemove()
        if self.lcEmitter then self.lcEmitter:Finish() self.lcEmitter = nil end
        if IsValid(self.lcStandin) then self.lcStandin:Remove() end
    end
end
