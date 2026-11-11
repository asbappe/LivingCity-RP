--[[ A city scanner flown from a Combine console (Living City). Not spawnable on
     its own: sv_livingcity_scanner.lua makes one when someone links up. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Linked scanner"
ENT.Author = "Miscount"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH -- the model, and the red glow of its eye

function ENT:Initialize()
    self:SetModel("models/combine_scanner.mdl")
    if CLIENT then return end
    self:PhysicsInitSphere(14, "metal")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableGravity(false)
        phys:SetMass(20)
        phys:Wake()
    end
    self.lcHP = 60
    self.hum = CreateSound(self, "npc/scanner/cbot_fly_loop.wav")
    if self.hum then self.hum:PlayEx(0.5, 100) end
end

if SERVER then
    function ENT:Think()
        if LC and LC.ScannerThink then LC.ScannerThink(self) end
        self:NextThink(CurTime())
        return true
    end

    function ENT:OnTakeDamage(dmg)
        self.lcHP = (self.lcHP or 60) - dmg:GetDamage()
        if self.lcHP <= 0 and LC and LC.EndScannerLink then
            local pilot = self:GetNW2Entity("lc_pilot")
            -- it winks out: a pop of energy and a spark, and nothing left behind. No
            -- debris and no scrap, so nobody risks their neck for parts that aren't there
            -- (it was put up from a console, and could be put up again and again)
            local fx = EffectData()
            fx:SetOrigin(self:GetPos())
            util.Effect("cball_explode", fx, true, true)
            self:EmitSound("npc/scanner/scanner_explode_crash2.wav", 80)
            if IsValid(pilot) then LC.EndScannerLink(pilot, "The scanner was destroyed; the link drops.") end
        end
    end

    function ENT:OnRemove()
        if self.hum then self.hum:Stop() end
    end
end

if CLIENT then
    -- A person is flying this one, and anyone can tell: its camera eye glows red,
    -- and throws a little red light on whatever's near it.
    local GLOW = Material("sprites/light_glow02_add")
    local RED = Color(255, 40, 30)

    local function Eye(self)
        return self:GetPos() + self:GetForward() * 12 + self:GetUp() * -2
    end

    function ENT:Draw()
        -- the pilot sees through it, not the back of it
        if self:GetNW2Entity("lc_pilot") == LocalPlayer() then return end
        self:DrawModel()
    end

    -- (made once here, not every frame)
    local C_255_200_190 = Color(255, 200, 190)
    function ENT:DrawTranslucent()
        if self:GetNW2Entity("lc_pilot") == LocalPlayer() then return end
        local pulse = 0.8 + 0.2 * math.sin(CurTime() * 4)
        render.SetMaterial(GLOW)
        render.DrawSprite(Eye(self), 26 * pulse, 26 * pulse, RED)
        render.DrawSprite(Eye(self), 10, 10, C_255_200_190)
    end

    function ENT:Think()
        if self:GetNW2Entity("lc_pilot") == LocalPlayer() then return end
        local dl = DynamicLight(self:EntIndex() + 4096)
        if dl then
            local p = Eye(self)
            dl.pos = p
            dl.r, dl.g, dl.b = 255, 30, 20
            dl.brightness = 1
            dl.decay = 600
            dl.size = 140
            dl.dietime = CurTime() + 0.2
        end
    end
end
