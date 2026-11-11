--[[
    The hoover (Living City, Infestation Cleanup: sv_livingcity_cleanup.lua)

      Left click (hold), looking at a dead growth: vacuums it up (a couple of seconds). Holds
                 lc_hoover_capacity (3). A live one has to be sprayed dead first (E, weedkiller).
      Right click: seals what's in it in a bag where you stand, only where there's no infestation
                 control barrel near (empty it into one of those: E on it).

    There's no first-person model for it in Half-Life 2 or the hazard props pack, so the hoover
    itself (the pack's, else a stand-in) is drawn in front of you, and in your hands for everyone
    else. lc_hoover_view "forward right up" (yours) moves it in your view (the owner, 7 November:
    about two feet further out than it was, so the pack isn't in your face).
    While it vacuums, the airboat's fan motor runs under its own sounds (the owner, 7 November).
]]

AddCSLuaFile()

SWEP.PrintName    = "Hoover"
SWEP.Author       = "Miscount"
SWEP.Category     = "Miscount"
SWEP.Instructions = "Hold left click on a dead growth to vacuum it up. Empty it into an infestation control barrel (E on it); where there's none, right click seals it in a bag."
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 4
SWEP.SlotPos      = 6
SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/props_junk/gascan001a.mdl" -- (never shown: the hoover is drawn in its place; with none, nothing in the hand was drawn at all)
SWEP.UseHands     = false
SWEP.HoldType     = "physgun"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local PACK = "models/hlvr/combine_hazardprops/combinehazardprops_hoover.mdl"
local STANDIN = "models/props_junk/gascan001a.mdl"
-- (in a player's own game util.IsValidModel only knows models already loaded, and the hoover is drawn there
-- alone, so it always said no and the stand-in showed: the owner, 1 November. The file itself is asked.)
local function Has(m)
    if CLIENT and file and file.Exists then return file.Exists(m, "GAME") end
    return not util.IsValidModel or util.IsValidModel(m)
end
local function Model() return Has(PACK) and PACK or STANDIN end

local REACH, SECS, STEP = 140, 2.4, 0.2
local MOTOR = "vehicles/airboat/fan_motor_fullthrottle_loop1.wav" -- (the airboat's fan motor, added to the hoover's own sounds)

function SWEP:Initialize() self:SetHoldType(self.HoldType) end

-- The motor runs while something is being vacuumed, and stops a moment after (server; everyone near hears it).
local function Motor(self, on)
    if not SERVER then return end
    if on then
        local owner = self:GetOwner()
        if not self.lcMotor and CreateSound and IsValid(owner) then
            self.lcMotor = CreateSound(owner, MOTOR)
            if self.lcMotor then self.lcMotor:PlayEx(0.55, 95) end
        end
        self.lcMotorUntil = CurTime() + 0.45
    elseif self.lcMotor then
        self.lcMotor:Stop()
        self.lcMotor = nil
    end
end

function SWEP:Think()
    if SERVER and self.lcMotor and (self.lcMotorUntil or 0) < CurTime() then Motor(self, false) end
end

local function Aimed(owner)
    local start = owner:GetShootPos()
    local tr = util.TraceLine({ start = start, endpos = start + owner:GetAimVector() * REACH, filter = owner })
    local e = tr.Entity
    if IsValid(e) and e:GetClass() == "lc_nest" then return e end
    -- (a dead growth is low and small: anything of one close to where you're pointing will do)
    for _, n in ipairs(ents.FindInSphere(tr.HitPos, 40)) do if IsValid(n) and n:GetClass() == "lc_nest" then return n end end
    return nil
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + STEP)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC then return end
    local e = Aimed(owner)
    if not e then owner.lcVac = nil owner:SetNW2Float("lc_vac_frac", 0) Motor(self, false) return end
    if not (LC.NestDead and LC.NestDead(e)) then
        if (owner.lcVacTold or 0) < CurTime() then
            owner.lcVacTold = CurTime() + 3
            owner:ChatPrint("It's still alive: spray it with weedkiller first (look at it, E).")
        end
        return
    end
    local v = owner.lcVac
    if not v or v.e ~= e then v = { e = e, t = 0 } owner.lcVac = v end
    v.t = v.t + STEP
    Motor(self, true)
    if (v.snd or 0) < CurTime() then v.snd = CurTime() + 1 owner:EmitSound("ambient/water/water_spray1.wav", 60, 55) end
    owner:SetNW2Float("lc_vac_frac", math.min(1, v.t / SECS))
    if v.t >= SECS then
        owner.lcVac = nil
        owner:SetNW2Float("lc_vac_frac", 0)
        local ok, why = LC.VacuumNest(owner, e)
        if not ok and why then owner:ChatPrint(why) end
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not LC or not LC.BagHoover then return end
    local ok, why = LC.BagHoover(owner)
    if not ok and why then owner:ChatPrint(why) end
end

function SWEP:Holster()
    local owner = self:GetOwner()
    if SERVER and IsValid(owner) then owner.lcVac = nil owner:SetNW2Float("lc_vac_frac", 0) end
    Motor(self, false)
    return true
end

if SERVER then
    function SWEP:OnRemove() Motor(self, false) end
    function SWEP:OnDrop() Motor(self, false) end
end

if CLIENT then
    -- (was "26 11 -15": the owner, 7 November, "the backpack is in my face... move it back about 2 feet". A game
    -- still on exactly the old setting moves to the new one; a position someone chose themselves is left alone.)
    local VIEW_OLD, VIEW_NEW = "26 11 -15", "50 11 -15"
    local cvView = CreateClientConVar("lc_hoover_view", VIEW_NEW, true, false, "Where your hoover sits in your view: forward right up")
    if cvView:GetString() == VIEW_OLD and cvView.SetString then cvView:SetString(VIEW_NEW) end

    local function Prop(self)
        if not IsValid(self.lcProp) and ClientsideModel then
            self.lcProp = ClientsideModel(Model(), RENDERGROUP_OPAQUE)
            if IsValid(self.lcProp) then self.lcProp:SetNoDraw(true) end
        end
        return self.lcProp
    end

    -- no first-person model of its own: the hoover drawn in front of you (the arms model under it is empty;
    -- hiding it outright stopped the hoover being drawn at all)
    function SWEP:PostDrawViewModel()
        local p = Prop(self)
        if not IsValid(p) then return end
        local parts = {}
        for n in string.gmatch(cvView:GetString(), "%-?[%d%.]+") do parts[#parts + 1] = tonumber(n) end
        local f, r, u = parts[1] or 50, parts[2] or 11, parts[3] or -15
        local ang = EyeAngles()
        local bob = math.sin(CurTime() * 6) * ((LocalPlayer():GetNW2Float("lc_vac_frac", 0) > 0) and 0.4 or 0)
        p:SetPos(EyePos() + ang:Forward() * f + ang:Right() * r + ang:Up() * (u + bob))
        local a = Angle(ang.p, ang.y, ang.r)
        a:RotateAroundAxis(a:Up(), 180)
        p:SetAngles(a)
        p:DrawModel()
    end

    function SWEP:DrawWorldModel()
        local p = Prop(self)
        if not IsValid(p) then return end
        local owner = self:GetOwner()
        local bone = IsValid(owner) and owner.LookupBone and owner:LookupBone("ValveBiped.Bip01_R_Hand")
        local m = bone and owner:GetBoneMatrix(bone)
        if m then
            local pos, ang = m:GetTranslation(), m:GetAngles()
            p:SetPos(pos + ang:Forward() * 4 + ang:Right() * 2)
            p:SetAngles(ang)
        else
            p:SetPos(self:GetPos()) p:SetAngles(self:GetAngles())
        end
        p:DrawModel()
    end

    function SWEP:OnRemove() if IsValid(self.lcProp) then self.lcProp:Remove() end end

    -- (made once here, not every frame)
    local C_0_0_0_200 = Color(0, 0, 0, 200)
    local C_220_230_200 = Color(220, 230, 200)
    function SWEP:DrawHUD()
        local me = LocalPlayer()
        local load = me:GetNW2Int("lc_hoover_load", 0)
        local cap = GetConVar("lc_hoover_capacity")
        local text = string.format("Hoover: %d of %d", load, cap and cap:GetInt() or 3)
        local frac = me:GetNW2Float("lc_vac_frac", 0)
        local x, y = ScrW() / 2, ScrH() * 0.62
        draw.SimpleTextOutlined(text, "DermaDefaultBold", x, y, C_220_230_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_200)
        if frac > 0 then
            surface.SetDrawColor(0, 0, 0, 160) surface.DrawRect(x - 80, y + 12, 160, 8)
            surface.SetDrawColor(150, 220, 90, 220) surface.DrawRect(x - 79, y + 13, 158 * frac, 6)
            draw.SimpleTextOutlined("Vacuuming...", "DermaDefault", x, y + 30, C_220_230_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_200)
        end
    end
end
