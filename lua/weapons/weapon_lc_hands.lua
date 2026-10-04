--[[
    Hands (Living City)
    Holstered: nothing in your view, arms at your sides, and nothing to swing.
    Everyone spawns holding them, so a stray click never punches anyone.
    Reload (R): raise your fists, or draw whatever you were last holding.
    !holster, or bind a key to lc_holster, switches back and forth.
]]

AddCSLuaFile()

SWEP.PrintName    = "Hands"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Purpose      = "Keep your hands to yourself."
SWEP.Instructions = "Holstered. R: raise your fists (or draw what you had). Bind a key to lc_holster to switch back and forth."
SWEP.Spawnable    = true
SWEP.AdminOnly    = false

SWEP.Slot         = 0
SWEP.SlotPos      = 0
SWEP.ViewModel    = ""
SWEP.WorldModel   = ""
SWEP.HoldType     = "normal"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:DrawWorldModel() end
function SWEP:PreDrawViewModel() return true end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

function SWEP:Reload()
    if CLIENT then return end
    if (self.nextReload or 0) > CurTime() then return end
    self.nextReload = CurTime() + 0.5
    local owner = self:GetOwner()
    if IsValid(owner) and LC and LC.ToggleHolster then LC.ToggleHolster(owner) end
end
