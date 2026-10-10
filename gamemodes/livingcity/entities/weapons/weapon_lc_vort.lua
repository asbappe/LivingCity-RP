--[[
    Vortessence (Living City, vortigaunts)

    Free vortigaunts:
      Primary:   a bolt of vortessence at what you're looking at (25 shock damage, 3 second recharge)
      Secondary: charge the vest of the person in front of you, or your own (25, 15 second recharge): the vortessence charges a powered vest, it does not heal
    Shackled vortigaunts: the collar holds it in. Nothing happens but a hum.
]]

AddCSLuaFile()

SWEP.PrintName    = "Vortessence"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Instructions = "Primary: a bolt of vortessence. Secondary: charge a vest. (Shackled: the collar holds it in.)"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 0
SWEP.SlotPos      = 7
SWEP.ViewModel    = ""
SWEP.WorldModel   = ""
SWEP.HoldType     = "normal"
SWEP.DrawAmmo     = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local ZAP_SOUND = "npc/vort/attack_shoot.wav"
local CHARGE_SOUND = "npc/vort/attack_charge.wav"
local HEAL_SOUND = "npc/vort/health_charge.wav"
local HUM_SOUND = "npc/vort/vort_foot1.wav"

if game.AddParticles then game.AddParticles("particles/vortigaunt_fx.pcf") end
if PrecacheParticleSystem then PrecacheParticleSystem("vortigaunt_beam") end

function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:DrawWorldModel() end

local function Shackled(ply) return IsValid(ply) and ply:GetNW2String("lcf_faction", "") == "vort" end

local function Tell(ply, msg) if IsValid(ply) and ply.ChatPrint then ply:ChatPrint(msg) end end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 3)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if Shackled(owner) then
        owner:EmitSound(HUM_SOUND, 60)
        return Tell(owner, "The collar holds your vortessence in.")
    end
    owner:EmitSound(CHARGE_SOUND, 70)
    local start = owner:GetShootPos()
    local tr = util.TraceLine({ start = start, endpos = start + owner:GetAimVector() * 700, filter = owner, mask = MASK_SHOT })
    if util.ParticleTracerEx then
        pcall(util.ParticleTracerEx, "vortigaunt_beam", start - Vector(0, 0, 10), tr.HitPos, false, owner:EntIndex(), -1)
    end
    owner:EmitSound(ZAP_SOUND, 80)
    local ent = tr.Entity
    if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
        local dmg = DamageInfo()
        dmg:SetDamage(25)
        dmg:SetDamageType(DMG_SHOCK)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamagePosition(tr.HitPos)
        ent:TakeDamageInfo(dmg)
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if Shackled(owner) then
        owner:EmitSound(HUM_SOUND, 60)
        return Tell(owner, "The collar holds your vortessence in.")
    end
    if (self.nextHeal or 0) > CurTime() then
        return Tell(owner, string.format("Your vortessence is gathering (%ds).", math.ceil(self.nextHeal - CurTime())))
    end
    local tr = util.TraceLine({ start = owner:GetShootPos(), endpos = owner:GetShootPos() + owner:GetAimVector() * 110, filter = owner })
    local target = tr.Entity
    if not (IsValid(target) and target:IsPlayer() and target:Alive()) then target = owner end
    if LC and LC.PlayerIsZombie and LC.PlayerIsZombie(target) then return Tell(owner, "There is nothing left in them to charge.") end
    -- the vortessence charges a vest (sv_livingcity_vest.lua); it doesn't knit flesh
    if not (LC and LC.HasVest and LC.HasVest(target)) then
        return Tell(owner, target == owner and "You wear nothing for the vortessence to charge." or "They wear no vest for the vortessence to charge.")
    end
    if target:Armor() >= LC.VestCap(target) then return Tell(owner, target == owner and "Your vest is full." or "Their vest is full.") end
    self.nextHeal = CurTime() + 15
    local gained = LC.ChargeVest(target, 25)
    owner:EmitSound(HEAL_SOUND, 70)
    if target ~= owner then
        Tell(target, "A warmth runs through your vest. The vortigaunt's hands glow green, and the cells hum.")
        if LC.AddXP then LC.AddXP(owner, 2, "charging with the vortessence") end
        hook.Run("LivingCityVestCharged", owner, target, gained)
    end
end

function SWEP:Reload() end
