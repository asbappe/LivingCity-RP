--[[
    The City Administrator's tablet (Living City, sv_livingcity_cityadmin.lua)

      Left click   point at someone: your Overwatch bodyguard kills them, at once
      Right click  the office: city events, rations, prices, a job bonus, and acts for citizens
]]

AddCSLuaFile()

SWEP.PrintName    = "Administrator's tablet"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Instructions = "Left click at someone: your bodyguard kills them. Right click: the office."
SWEP.Spawnable    = false
SWEP.AdminOnly    = true

SWEP.Slot         = 0
SWEP.SlotPos      = 3
SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/props_lab/clipboard.mdl"
SWEP.UseHands     = false
SWEP.HoldType     = "slam"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize() self:SetHoldType(self.HoldType) end

local function Aimed(owner)
    local start = owner:GetShootPos()
    local tr = util.TraceLine({ start = start, endpos = start + owner:GetAimVector() * 4000, filter = owner, mask = MASK_SHOT })
    local e = tr.Entity
    if IsValid(e) and (e:IsPlayer() or e:IsNPC()) then return e end
    return nil
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC then return end
    local t = Aimed(owner)
    if not t then return end
    if LC.AdminOrderKill and LC.AdminOrderKill(owner, t) then
        owner:ChatPrint("[Office] \"Neutralize.\" Your bodyguard opens fire.")
    else
        owner:ChatPrint("[Office] You have no bodyguard with you right now.")
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if SERVER and LC and LC.OpenAdminOffice then LC.OpenAdminOffice(self:GetOwner()) end
end

if CLIENT then
    -- (made once here, not every frame)
    local C_220_220_210 = Color(220, 220, 210)
    local C_240_90_80 = Color(240, 90, 80)
    function SWEP:DrawHUD()
        local x, y = ScrW() / 2, ScrH() * 0.72
        local e = LocalPlayer():GetEyeTrace().Entity
        local aimed = IsValid(e) and (e:IsPlayer() or e:IsNPC())
        draw.SimpleTextOutlined(aimed and "LEFT CLICK: ORDER YOUR BODYGUARD TO KILL THEM" or "Right click: the office. Left click at someone: your bodyguard kills them.",
            "DermaDefaultBold", x, y, aimed and C_240_90_80 or C_220_220_210, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end
    function SWEP:DrawWorldModel() if self:GetOwner() == NULL then self:DrawModel() end end
end
