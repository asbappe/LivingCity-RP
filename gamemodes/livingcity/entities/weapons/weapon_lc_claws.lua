--[[
    Zombie Claws (Living City, Infested faction)
    Primary:   swipe
    Secondary: moan
]]

AddCSLuaFile()

SWEP.PrintName    = "Claws"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Instructions = "Primary: swipe. Secondary: moan."
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 0
SWEP.SlotPos      = 5
SWEP.ViewModel    = ""
SWEP.WorldModel   = ""
SWEP.HoldType     = "fist"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:DrawWorldModel() end

local function IsFast(owner)
    return string.find(string.lower(owner:GetModel() or ""), "zombie_fast", 1, true) ~= nil
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local fast = IsFast(owner)
    self:SetNextPrimaryFire(CurTime() + (fast and 0.4 or 0.9))
    owner:SetAnimation(PLAYER_ATTACK1)

    owner:LagCompensation(true)
    local tr = util.TraceHull({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 75,
        filter = owner,
        mins = Vector(-10, -10, -10), maxs = Vector(10, 10, 10),
        mask = MASK_SHOT_HULL,
    })
    owner:LagCompensation(false)

    if tr.Hit then
        self:EmitSound(fast and "NPC_FastZombie.AttackHit" or "Zombie.AttackHit")
        if SERVER and IsValid(tr.Entity) then
            local dmg = DamageInfo()
            dmg:SetDamage(fast and 12 or 25)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageForce(owner:GetAimVector() * 6000)
            dmg:SetDamagePosition(tr.HitPos)
            tr.Entity:TakeDamageInfo(dmg)
        end
    else
        self:EmitSound(fast and "NPC_FastZombie.AttackMiss" or "Zombie.AttackMiss")
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 3)
    local owner = self:GetOwner()
    if IsValid(owner) then self:EmitSound(IsFast(owner) and "NPC_FastZombie.Scream" or "Zombie.Alert") end
end

function SWEP:Reload() end
