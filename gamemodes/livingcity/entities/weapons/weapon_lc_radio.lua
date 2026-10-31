--[[
    Radio (Living City)
    Your radio, held up to your mouth: switch to it like your hands or a gun
    (it's next to Hands). While it's up, everything you type in chat and
    everything you say on voice goes out over your radio's band (Freq 7 on a
    Resistance radio, the CP net for units, the Union band on a Union radio),
    and only someone standing right beside you hears you directly. Your hands
    are full: no gun at the same time. R, or switching to anything else, puts
    it away. You have it while you carry a radio (units always do).
]]

AddCSLuaFile()

SWEP.PrintName    = "Radio"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Purpose      = "Talk over your radio."
SWEP.Instructions = "While it's up, your chat and voice go over your radio's band. Only people right beside you hear you directly. R puts it away."
SWEP.Spawnable    = false
SWEP.AdminOnly    = false

SWEP.Slot         = 0
SWEP.SlotPos      = 1
SWEP.ViewModel    = ""
SWEP.WorldModel   = ""
SWEP.HoldType     = "camera" -- (held up near the face)
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local MODEL = "models/props_lab/citizenradio.mdl"
local BANDS = { resistance = "Freq 7", cp = "the CP net", union = "the Union band" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

function SWEP:Deploy()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) and LC and LC.RadioBand then
            local band = LC.RadioBand(owner)
            self:SetNW2String("lc_band", band or "")
            if not band or (LC.Prisoners and LC.Prisoners[owner]) then
                timer.Simple(0, function() if IsValid(owner) and owner:HasWeapon("weapon_lc_hands") then owner:SelectWeapon("weapon_lc_hands") end end)
                return true
            end
            owner:EmitSound(band == "cp" and "npc/metropolice/vo/on1.wav" or "buttons/lightswitch2.wav", 50)
            -- (the radio's static recording, sound/livingcity/radio/static..., for the soft hiss you hear while it's up)
            local static = LC.RadioClip and LC.RadioClip("static")
            self:SetNW2String("lc_static", static or "")
        end
    end
    return true
end

function SWEP:Holster()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then owner:EmitSound(self:GetNW2String("lc_band", "") == "cp" and "npc/metropolice/vo/off1.wav" or "buttons/lightswitch2.wav", 45, 90) end
    end
    return true
end

-- R: put it away (your hands again).
function SWEP:Reload()
    if CLIENT then return end
    if (self.nextReload or 0) > CurTime() then return end
    self.nextReload = CurTime() + 0.5
    local owner = self:GetOwner()
    if IsValid(owner) and owner:HasWeapon("weapon_lc_hands") then owner:SelectWeapon("weapon_lc_hands") end
end

if CLIENT then
    -- A soft hiss of static while the radio is up, just for you: a reminder that what you say is
    -- going out over it. lc_radio_static_volume (0.08) sets how loud (0 turns it off).
    local cvStatic = CreateClientConVar("lc_radio_static_volume", "0.08", true, false, "How loud the soft static is while you hold your radio up (0: off)")
    local hiss, hissPath
    hook.Add("Think", "LivingCityRadioStatic", function()
        local me = LocalPlayer()
        local w = IsValid(me) and me.GetActiveWeapon and me:GetActiveWeapon()
        local up = IsValid(w) and w:GetClass() == "weapon_lc_radio" and me:Alive() and cvStatic:GetFloat() > 0
        local path = up and w:GetNW2String("lc_static", "") or ""
        if up and path ~= "" and CreateSound then
            if not hiss or hissPath ~= path then
                if hiss then hiss:Stop() end
                hiss, hissPath = CreateSound(me, path), path
                if hiss and hiss.SetSoundLevel then hiss:SetSoundLevel(0) end
            end
            if hiss then
                if not hiss:IsPlaying() then hiss:PlayEx(cvStatic:GetFloat(), 100) end -- (it starts again when the file ends)
                hiss:ChangeVolume(math.Clamp(cvStatic:GetFloat(), 0, 1), 0)
            end
        elseif hiss then
            hiss:Stop()
            hiss, hissPath = nil, nil
        end
    end)

    local function Prop(self)
        if not IsValid(self.lcProp) and ClientsideModel then
            self.lcProp = ClientsideModel(MODEL, RENDERGROUP_OPAQUE)
            if IsValid(self.lcProp) then self.lcProp:SetNoDraw(true) end
        end
        return self.lcProp
    end

    -- In everyone else's view: the radio in their right hand, up by the face.
    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        local m = Prop(self)
        if not IsValid(owner) or not IsValid(m) then return end
        local bone = owner.LookupBone and owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if not bone then return end
        local pos, ang = owner:GetBonePosition(bone)
        if not pos then return end
        m:SetModelScale(0.45, 0)
        m:SetPos(pos + ang:Forward() * 4 + ang:Right() * 2)
        m:SetAngles(ang)
        m:SetupBones()
        m:DrawModel()
    end

    -- In your own view: the radio held up, low on the right, and what it does.
    function SWEP:DrawHUD()
        local m = Prop(self)
        if IsValid(m) and cam and cam.Start3D then
            local eye, ang = EyePos(), EyeAngles()
            cam.Start3D(eye, ang, 60)
            m:SetModelScale(0.5, 0)
            m:SetPos(eye + ang:Forward() * 22 + ang:Right() * 9 - ang:Up() * 9)
            local a = Angle(ang.p, ang.y, ang.r)
            a:RotateAroundAxis(a:Up(), 160)
            m:SetAngles(a)
            m:SetupBones()
            m:DrawModel()
            cam.End3D()
        end
        local band = BANDS[self:GetNW2String("lc_band", "")] or "your radio"
        local w, h = ScrW(), ScrH()
        draw.SimpleTextOutlined("RADIO UP: what you type and say goes out on " .. band, "DermaDefaultBold", w / 2, h - 120, Color(150, 220, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        draw.SimpleTextOutlined("Only someone right beside you hears you directly. R puts it away.", "DermaDefault", w / 2, h - 102, Color(220, 220, 210), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end

    function SWEP:OnRemove()
        if IsValid(self.lcProp) then self.lcProp:Remove() end
    end
end
