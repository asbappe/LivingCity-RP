--[[
    The weedkiller sprayer (Living City: Infestation Cleanup and the Groundskeeper)

      Left click (hold), looking at a weed or a live infestation growth: sprays it with weedkiller
                 until it dies (a tuft in a moment, a bush or a growth a few seconds). Needs weedkiller
                 in your pockets (the job issues it, and tops it up).
    E on one still works too. There's no first-person model for a sprayer, so the canister itself is
    drawn in front of you (lc_sprayer_view "forward right up" moves it), and in your hand for others.
]]

AddCSLuaFile()

SWEP.PrintName    = "Weedkiller sprayer"
SWEP.Author       = "Living City"
SWEP.Category     = "Living City"
SWEP.Instructions = "Hold left click on a weed or a glowing infestation growth to spray it dead."
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 4
SWEP.SlotPos      = 5
SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/props_junk/garbage_plasticbottle001a.mdl"
SWEP.UseHands     = false
SWEP.HoldType     = "pistol"
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local MODEL = "models/props_junk/garbage_plasticbottle001a.mdl"
local REACH, STEP = 150, 0.2

function SWEP:Initialize() self:SetHoldType(self.HoldType) end

local function Target(owner)
    local start = owner:GetShootPos()
    local tr = util.TraceLine({ start = start, endpos = start + owner:GetAimVector() * REACH, filter = owner })
    local function ok(e) return IsValid(e) and (e:GetClass() == "lc_weed" or (e:GetClass() == "lc_nest" and not e:GetNW2Bool("lc_dead", false))) end
    if ok(tr.Entity) then return tr.Entity, tr.HitPos end
    for _, e in ipairs(ents.FindInSphere(tr.HitPos, 40)) do if ok(e) then return e, tr.HitPos end end
    return nil, tr.HitPos
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + STEP)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local e, at = Target(owner)
    -- the mist, in everyone's game who sees it
    if CLIENT and IsFirstTimePredicted() and ParticleEmitter then
        local from = owner:GetShootPos() + owner:GetAimVector() * 20 - Vector(0, 0, 8)
        local em = ParticleEmitter(from)
        if em then
            for _ = 1, 4 do
                local p = em:Add("particle/particle_smokegrenade", from)
                if p then
                    p:SetVelocity(owner:GetAimVector() * math.Rand(180, 260) + VectorRand() * 25)
                    p:SetDieTime(math.Rand(0.4, 0.8))
                    p:SetStartAlpha(70) p:SetEndAlpha(0)
                    p:SetStartSize(2) p:SetEndSize(math.Rand(10, 18))
                    p:SetColor(170, 220, 140)
                    p:SetAirResistance(120)
                end
            end
            em:Finish()
        end
    end
    if CLIENT then return end
    if not LC then return end
    if (owner.lcSprayHiss or 0) < CurTime() then owner.lcSprayHiss = CurTime() + 1 owner:EmitSound("ambient/water/water_spray1.wav", 60, 110) end
    if not e then owner.lcSpray = nil owner:SetNW2Float("lc_spray_frac", 0) return end
    if LC.IssueWeedkiller then LC.IssueWeedkiller(owner) end
    if not LC.HasItem(owner, "weedkiller") then
        if (owner.lcSprayTold or 0) < CurTime() then
            owner.lcSprayTold = CurTime() + 3
            owner:ChatPrint("Your sprayer's empty: you need weedkiller (the Union Commissary sells it).")
        end
        return
    end
    local need = e:GetClass() == "lc_weed" and (LC.WeedSpraySecs and LC.WeedSpraySecs(e) or 3) or 4
    local v = owner.lcSpray
    if not v or v.e ~= e then v = { e = e, t = 0 } owner.lcSpray = v end
    v.t = v.t + STEP
    owner:SetNW2Float("lc_spray_frac", math.min(1, v.t / need))
    if v.t >= need then
        owner.lcSpray = nil
        owner:SetNW2Float("lc_spray_frac", 0)
        if e:GetClass() == "lc_weed" then
            if LC.KillWeed then LC.KillWeed(e, owner) end
        elseif LC.KillNest then
            LC.KillNest(e, owner)
        end
    end
end

function SWEP:SecondaryAttack() end

function SWEP:Holster()
    local owner = self:GetOwner()
    if SERVER and IsValid(owner) then owner.lcSpray = nil owner:SetNW2Float("lc_spray_frac", 0) end
    return true
end

if CLIENT then
    local cvView = CreateClientConVar("lc_sprayer_view", "18 9 -10", true, false, "Where your weedkiller sprayer sits in your view: forward right up")

    local function Prop(self)
        if not IsValid(self.lcProp) and ClientsideModel then
            self.lcProp = ClientsideModel(MODEL, RENDERGROUP_OPAQUE)
            if IsValid(self.lcProp) then self.lcProp:SetNoDraw(true) end
        end
        return self.lcProp
    end

    function SWEP:PostDrawViewModel()
        local p = Prop(self)
        if not IsValid(p) then return end
        local parts = {}
        for n in string.gmatch(cvView:GetString(), "%-?[%d%.]+") do parts[#parts + 1] = tonumber(n) end
        local f, r, u = parts[1] or 18, parts[2] or 9, parts[3] or -10
        local ang = EyeAngles()
        p:SetPos(EyePos() + ang:Forward() * f + ang:Right() * r + ang:Up() * u)
        local a = Angle(ang.p, ang.y, ang.r)
        a:RotateAroundAxis(a:Right(), -70) -- (nozzle forward)
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
            p:SetPos(pos + ang:Forward() * 3 + ang:Right() * 1.5)
            p:SetAngles(ang)
        else
            p:SetPos(self:GetPos()) p:SetAngles(self:GetAngles())
        end
        p:DrawModel()
    end

    function SWEP:OnRemove() if IsValid(self.lcProp) then self.lcProp:Remove() end end

    function SWEP:DrawHUD()
        local frac = LocalPlayer():GetNW2Float("lc_spray_frac", 0)
        if frac <= 0 then return end
        local x, y = ScrW() / 2, ScrH() * 0.62
        surface.SetDrawColor(0, 0, 0, 160) surface.DrawRect(x - 80, y + 12, 160, 8)
        surface.SetDrawColor(150, 220, 90, 220) surface.DrawRect(x - 79, y + 13, 158 * frac, 6)
        draw.SimpleTextOutlined("Spraying...", "DermaDefault", x, y + 30, Color(220, 230, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
    end
end
