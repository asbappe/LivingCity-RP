--[[ Radio jammer (Living City): made at a workbench and set down from your
     pockets. While it runs, units' radios nearby are static, request devices
     don't get through, and scanner photographs never reach Civil Protection.
     It beeps. Units smash it with E; anyone can shoot it. ]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Radio jammer"
ENT.Author = "Miscount"
ENT.Spawnable = false

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel("models/props_lab/reciever01b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.lcHP = 30
    self.hiss = CreateSound(self, "ambient/levels/prison/radio_random1.wav")
    if self.hiss then self.hiss:PlayEx(0.4, 90) end
end

if SERVER then
    function ENT:Think()
        self:EmitSound("buttons/blip1.wav", 65, 140)
        self:NextThink(CurTime() + 3)
        return true
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() or not LC or not LC.SmashJammer then return end
        local ok, why = LC.SmashJammer(activator, self)
        if not ok and why then activator:ChatPrint(why) end
    end

    function ENT:OnTakeDamage(dmg)
        self.lcHP = (self.lcHP or 30) - dmg:GetDamage()
        if self.lcHP <= 0 then
            self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75)
            self:Remove()
        end
    end

    function ENT:OnRemove()
        if self.hiss then self.hiss:Stop() end
    end
end

if CLIENT then
    local GLOW = Material("sprites/light_glow02_add")
    -- (made once here, not every frame)
    local C_255_170_40 = Color(255, 170, 40)
    local V_0_0_10 = Vector(0, 0, 10)
    function ENT:Draw()
        self:DrawModel()
        if math.floor(CurTime() * 2) % 2 == 0 then
            render.SetMaterial(GLOW)
            render.DrawSprite(self:GetPos() + V_0_0_10, 12, 12, C_255_170_40)
        end
    end
end
