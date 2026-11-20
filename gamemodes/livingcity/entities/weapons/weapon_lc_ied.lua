--[[
    Detonator (Living City). For the IEDs you carry (sv_livingcity_ied.lua).
      Left click    set one on the ground in front of you
      Right click   blow every one of yours that is live
    You are handed it while you carry an IED or have one set.
]]

AddCSLuaFile()

SWEP.PrintName = "Detonator"
SWEP.Author = "Miscount"
SWEP.Instructions = "Left click: set an IED on the ground in front of you. Right click: blow the ones you have set."
SWEP.Spawnable = false
SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"
SWEP.DrawAmmo = false
SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    if self.SetHoldType then self:SetHoldType(self.HoldType) end
end

local function Do(self, fn)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if SERVER and LC and LC[fn] then
        local ok, why = LC[fn](owner)
        -- (a refusal is a dry click, not a line of text: the owner's rule on how much players are given to read)
        if not ok and owner.EmitSound then owner:EmitSound("buttons/button10.wav", 55) end
        if LC.IEDSync then timer.Simple(0.1, function() if IsValid(owner) then LC.IEDSync(owner) end end) end
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)
    Do(self, "IEDPlant")
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.6)
    Do(self, "IEDDetonate")
end
