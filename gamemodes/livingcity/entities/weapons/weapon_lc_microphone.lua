--[[
    Microphone (Living City): the Director of Propaganda's. Left click goes live:
    for up to a minute your voice (and what you type) goes out over every
    loudspeaker and screen in the city, once every fifteen minutes city-wide
    (sv_livingcity_propaganda.lua). Left click again to stop. Anyone holding it
    can use it: the Resistance would love to.
]]

AddCSLuaFile()

SWEP.PrintName    = "Microphone"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Purpose      = "The city's voice."
SWEP.Instructions = "Left click: go live over every loudspeaker and screen (up to a minute; once every fifteen). Hold your voice key and speak, or type."
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 4
SWEP.SlotPos      = 3
SWEP.ViewModel    = ""
SWEP.WorldModel   = "models/props_lab/reciever01d.mdl"
SWEP.HoldType     = "pistol"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:PreDrawViewModel() return true end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC or not LC.ToggleBroadcast then return end
    local ok, why = LC.ToggleBroadcast(owner)
    if not ok and why then owner:ChatPrint(why) end
end

function SWEP:Holster()
    if SERVER and LC and LC.StopBroadcast and IsValid(self:GetOwner()) and LC.LiveSpeaker == self:GetOwner() then LC.StopBroadcast("off air") end
    return true
end

if CLIENT then
    function SWEP:DrawHUD()
        local live = GetGlobal2Entity("lc_live")
        local x, y = ScrW() / 2, ScrH() * 0.8
        if live == LocalPlayer() then
            local left = math.max(0, GetGlobal2Float("lc_live_until", 0) - CurTime())
            draw.SimpleTextOutlined(string.format("ON AIR  %ds   Hold your voice key and speak (or type). Left click to stop.", math.ceil(left)), "DermaDefaultBold", x, y, Color(255, 80, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        else
            local wait = GetGlobal2Float("lc_live_next", 0) - CurTime()
            draw.SimpleTextOutlined(wait > 0 and string.format("MICROPHONE: the transmitter is cooling down (%d:%02d)", math.floor(wait / 60), math.floor(wait % 60))
                or "MICROPHONE: left click to go live over every loudspeaker and screen", "DermaDefault", x, y, Color(220, 210, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        end
    end
end
