--[[
    Arrest Baton (Living City)
    Primary:   strike
    Secondary: arrest the player, citizen or rebel in front of you (they may struggle; then
               cuffed, and walked to the cells: sv_livingcity_arrest.lua)
    Reload:    release the prisoner in front of you, or search the person in front of you
]]

AddCSLuaFile()

SWEP.PrintName    = "Arrest Baton"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Purpose      = "Keep the peace."
SWEP.Instructions = "Primary: strike. Secondary: arrest. Reload: search someone, or release a prisoner."
SWEP.Spawnable    = true
SWEP.AdminOnly    = false

SWEP.Slot         = 0
SWEP.SlotPos      = 4
SWEP.ViewModel    = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel   = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands     = true
SWEP.HoldType     = "melee"
SWEP.DrawAmmo     = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

local function MeleeTrace(owner)
    owner:LagCompensation(true)
    local tr = util.TraceHull({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 72,
        filter = owner,
        mins = Vector(-8, -8, -8), maxs = Vector(8, 8, 8),
        mask = MASK_SHOT_HULL,
    })
    owner:LagCompensation(false)
    return tr
end

local function Tell(ply, msg) ply:ChatPrint("[Living City] " .. msg) end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    self:SetNextPrimaryFire(CurTime() + 0.8)
    owner:SetAnimation(PLAYER_ATTACK1)

    local tr = MeleeTrace(owner)
    if tr.Hit then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:EmitSound("Weapon_StunStick.Melee_Hit")
        if SERVER and IsValid(tr.Entity) then
            local dmg = DamageInfo()
            dmg:SetDamage(15)
            dmg:SetDamageType(DMG_CLUB)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageForce(owner:GetAimVector() * 4000)
            dmg:SetDamagePosition(tr.HitPos)
            tr.Entity:TakeDamageInfo(dmg)
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        self:EmitSound("Weapon_StunStick.Melee_Miss")
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC or not LC.BatonMayArrest then return end

    local ok, why = LC.BatonMayArrest(owner)
    if not ok then return Tell(owner, why) end

    local ent = MeleeTrace(owner).Entity
    if not IsValid(ent) then return end

    if LC.BatonArrest then
        local _, msg = LC.BatonArrest(owner, ent)
        if msg then Tell(owner, msg) end
        return
    end
    if ent:IsPlayer() then
        if LC.PlayerIsCP(ent) and not owner:IsAdmin() then return Tell(owner, "You can't arrest another Civil Protection unit.") end
        local done, err = LC.Incarcerate(ent, GetConVar("lc_prison_time"):GetInt(), "Arrested by " .. owner:Nick(), owner)
        Tell(owner, done and (ent:Nick() .. " is in custody.") or ("Couldn't arrest: " .. tostring(err)))
    elseif LC.NPCs and LC.NPCs[ent] then
        local done, err = LC.ArrestNPC(ent, owner)
        Tell(owner, done and "Citizen detained. They're taken to a cell." or ("Couldn't arrest: " .. tostring(err)))
    end
end

function SWEP:Reload()
    if CLIENT then return end
    if (self.nextReload or 0) > CurTime() then return end
    self.nextReload = CurTime() + 1
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC or not LC.BatonMayArrest or not LC.BatonMayArrest(owner) then return end
    local ent = MeleeTrace(owner).Entity
    if not IsValid(ent) then return end
    if not ent:IsPlayer() then
        if LC.NPCs and LC.NPCs[ent] and LC.StartSearch then
            local ok, why = LC.StartSearch(owner, ent)
            if not ok and why then Tell(owner, why) end
        end
        return
    end
    if LC.Prisoners[ent] then
        LC.ReleasePrisoner(ent)
        Tell(owner, ent:Nick() .. " released.")
    elseif LC.StartSearch then
        local ok, why = LC.StartSearch(owner, ent)
        if not ok and why then Tell(owner, why) end
    end
end
