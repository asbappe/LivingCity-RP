--[[
    Radio transmitter (Living City)
    Your radio transmitter, held up to your mouth: switch to it like your hands or a gun
    (it's next to Hands). While it's up, everything you type in chat and
    everything you say on voice goes out over the frequency it's tuned to: the
    CP net (units) or Freq 7 (a Freq 7 radio and a radio transmitter). Nobody
    transmits on the Union band. Right click switches frequency, for someone
    with both (a Resistance Insider),
    and only someone standing right beside you hears you directly. Your hands
    are full: no gun at the same time. R, or switching to anything else, puts
    it away. You have it while you carry a radio and a radio transmitter (a radio
    alone only listens); units are issued theirs.
]]

AddCSLuaFile()

SWEP.PrintName    = "Radio transmitter"
SWEP.Author       = "Miscount"
SWEP.Category     = "Miscount"
SWEP.Purpose      = "Talk over your radio."
SWEP.Instructions = "While it's up, your chat and voice go over your radio's band. Only people right beside you hear you directly. Left click calls for backup. R puts it away."
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

local MODEL = "models/props_lab/reciever01a.mdl"
local BANDS = { resistance = "Freq 7", cp = "the CP net" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- Left click: call for backup on the band it's on (the owner, 9 November): Freq 7 brings Resistance
-- fighters (LC.RebelCallBackup), the CP net brings units (LC.CallBackup); both join your squad.
function SWEP:PrimaryAttack()
    if CLIENT then return end
    if (self.nextCall or 0) > CurTime() then return end
    self.nextCall = CurTime() + 1
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC then return end
    local band = self:GetNW2String("lc_band", "")
    local ok, why
    if band == "resistance" and LC.RebelCallBackup then ok, why = LC.RebelCallBackup(owner)
    elseif band == "cp" and LC.CallBackup then ok, why = LC.CallBackup(owner)
    else ok, why = false, "Nobody to call on this band." end
    if not ok and why and LC.Notice then LC.Notice(owner, "warn", "Backup", tostring(why), 8) end
end
-- Right click: switch frequency, for someone who can send on more than one (a Resistance Insider:
-- the CP net and Freq 7). Careful which one you're on.
function SWEP:SecondaryAttack()
    if CLIENT then return end
    if (self.nextTune or 0) > CurTime() then return end
    self.nextTune = CurTime() + 0.4
    local owner = self:GetOwner()
    if not IsValid(owner) or not (LC and LC.TuneTransmitter) then return end
    local before = self:GetNW2String("lc_band", "")
    local band = LC.TuneTransmitter(owner)
    self:SetNW2String("lc_band", band or "")
    self:SetNW2Int("lc_bands", #LC.TransmitBands(owner))
    if band ~= before then
        owner:EmitSound("buttons/button16.wav", 50)
        owner:ChatPrint("[Radio] Now transmitting on " .. (BANDS[band] or "nothing") .. ".")
    end
end

function SWEP:Deploy()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) and LC and LC.TransmitBand then
            local band = LC.TransmitBand(owner)
            self:SetNW2String("lc_band", band or "")
            self:SetNW2Int("lc_bands", #LC.TransmitBands(owner))
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
    if not IsValid(owner) then return end
    -- (the same R, still held, reached the hands' own R a moment later and drew the radio straight back out:
    -- the owner, 7 November, "it just flashes and reappears". The hands ignore it until R is let go.)
    -- (and the other way round: the R that drew it out of your hands, still held, put it straight back:
    -- the owner, 11 November, "I cannot get it back out")
    if LC and LC.ReloadHeld and LC.ReloadHeld(owner) then return end
    if LC and LC.HoldReload then LC.HoldReload(owner) end
    if owner:HasWeapon("weapon_lc_hands") then owner:SelectWeapon("weapon_lc_hands") end
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

    -- In your own view: the radio held up, low on the right, and what it does. (The owner, 1 November: it
    -- sat so low it was barely on screen; raised well up. lc_radio_view "forward right up" moves it, yours.)
    local cvView = CreateClientConVar("lc_radio_view", "20 9 -3", true, false, "Where your radio transmitter sits in your view: forward right up")
    -- (made once here, not every frame)
    local C_150_220_150 = Color(150, 220, 150)
    local C_220_220_210 = Color(220, 220, 210)
    function SWEP:DrawHUD()
        local m = Prop(self)
        if IsValid(m) and cam and cam.Start3D then
            local eye, ang = EyePos(), EyeAngles()
            cam.Start3D(eye, ang, 60)
            m:SetModelScale(0.5, 0)
            local v = {}
            for n in string.gmatch(cvView:GetString(), "%-?[%d%.]+") do v[#v + 1] = tonumber(n) end
            m:SetPos(eye + ang:Forward() * (v[1] or 20) + ang:Right() * (v[2] or 9) + ang:Up() * (v[3] or -3))
            local a = Angle(ang.p, ang.y, ang.r)
            a:RotateAroundAxis(a:Up(), 160)
            m:SetAngles(a)
            m:SetupBones()
            m:DrawModel()
            cam.End3D()
        end
        local band = BANDS[self:GetNW2String("lc_band", "")] or "your radio"
        local w, h = ScrW(), ScrH()
        draw.SimpleTextOutlined("TRANSMITTER UP: what you type and say goes out on " .. band, "DermaDefaultBold", w / 2, h - 120, C_150_220_150, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
        draw.SimpleTextOutlined("Only someone right beside you hears you directly. Left click calls for backup. R puts it away." .. (self:GetNW2Int("lc_bands", 1) > 1 and " Right click switches frequency." or ""),
            "DermaDefault", w / 2, h - 102, C_220_220_210, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end

    function SWEP:OnRemove()
        if IsValid(self.lcProp) then self.lcProp:Remove() end
    end
end
