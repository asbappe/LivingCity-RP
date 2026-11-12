--[[
    The Resistance leader's clipboard (Living City, sv_livingcity_rebelrule.lua)

    The owner, 12 November: "the leader of the resistance can set the mood or
    even rules via their own 'tablet' (aka a clipboard they have as a SWEP with
    paper and checkboxes on it)". Carried by the highest-ranked Resistance
    player on. Left or right click: the paper, as a quick menu (number keys).
]]

AddCSLuaFile()

SWEP.PrintName    = "The cell's clipboard"
SWEP.Author       = "Miscount"
SWEP.Category     = "Miscount"
SWEP.Instructions = "Left click: the cell's rules and mood."
SWEP.Spawnable    = false
SWEP.AdminOnly    = true

SWEP.Slot         = 0
SWEP.SlotPos      = 4
SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/props_lab/clipboard.mdl"
SWEP.UseHands     = false
SWEP.HoldType     = "slam"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize() self:SetHoldType(self.HoldType) end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if SERVER and LC and LC.RebelClipSend then LC.RebelClipSend(self:GetOwner()) end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    if SERVER and LC and LC.RebelClipSend then LC.RebelClipSend(self:GetOwner()) end
end
