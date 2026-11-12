--[[
    Arrest Baton (Living City)
    Primary:   strike
    Secondary: arrest the player, citizen or rebel in front of you (they may struggle; then
               cuffed, and walked to the cells: sv_livingcity_arrest.lua)
    Reload:    release the prisoner in front of you, or search the person in front of you
]]

AddCSLuaFile()

SWEP.PrintName    = "Arrest Baton"
SWEP.Author       = "Miscount"
SWEP.Category     = "Miscount"
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

-- Drawn, then held up at rest: the view model's own animations, so the baton is in view (the owner, 12 November:
-- a screenshot with no baton at all, only its glow in the corner).
local function IdleAfter(self, secs) self.lcIdleAt = CurTime() + (secs or 0.6) end
function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    local owner = self:GetOwner()
    local vm = IsValid(owner) and owner.GetViewModel and owner:GetViewModel()
    IdleAfter(self, IsValid(vm) and vm.SequenceDuration and vm:SequenceDuration() or 0.6)
    return true
end
function SWEP:Think()
    if self.lcIdleAt and CurTime() >= self.lcIdleAt then
        self.lcIdleAt = nil
        self:SendWeaponAnim(ACT_VM_IDLE)
    end
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

local function Tell(ply, msg) ply:ChatPrint("[Miscount] " .. msg) end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    self:SetNextPrimaryFire(CurTime() + 0.8)
    owner:SetAnimation(PLAYER_ATTACK1)

    local tr = MeleeTrace(owner)
    if tr.Hit then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        IdleAfter(self, 0.7)
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
        IdleAfter(self, 0.7)
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

-- The charge at the head of it, in your own view (the owner, 11 November: a stunstick picked up off a dead
-- metrocop "has the electric effect ... and I love it. Why can't the arrest baton have that?").
-- (the owner, 12 November: "sparks are in a group of 3 and sitting too far back from the viewmodel", and a
-- screenshot: no baton in view, three big glows in the lower right corner.) Now one small glow with a crackle
-- at the very tip of the baton, following it as it moves: of the stunstick's spark points, the one furthest
-- from the hand. The engine moves a view model's attachment out to where it would sit at your own field of
-- view (for muzzle flashes in the world); drawn over the view model, that put the glow well right of and
-- below the baton, so the point is first put back to the view model's field of view (LC_CL.BatonTipSpace).
if CLIENT then
    LC_CL = LC_CL or {}
    local GLOW = Material("sprites/light_glow02_add")
    local FLARE = Material("effects/blueflare1")
    local POINTS = { "sparkrear" }
    for i = 1, 9 do POINTS[#POINTS + 1] = "spark" .. i .. "a" POINTS[#POINTS + 1] = "spark" .. i .. "b" end
    local WHITE, BLUE = Color(255, 255, 255, 255), Color(160, 205, 255, 255)

    -- Horizontal field of view as the engine draws it (4:3 is the reference).
    local function Scaled(fov)
        local aspect = (ScrW and ScrH and ScrH() > 0) and (ScrW() / ScrH()) or (16 / 9)
        return math.deg(2 * math.atan(math.tan(math.rad(fov) / 2) * aspect / (4 / 3)))
    end
    -- A view model attachment's position, from your field of view back to the view model's (the engine's
    -- FormatViewModelAttachment, the other way round). vmfov: the weapon's ViewModelFOV, if the view can't say.
    function LC_CL.BatonTipSpace(pos, vmfov)
        local vs = render and render.GetViewSetup and render.GetViewSetup() or nil
        local origin = vs and vs.origin or EyePos()
        local ang = vs and vs.angles or EyeAngles()
        local fov = vs and vs.fov
        local vfov = vs and vs.fov_viewmodel
        if not fov or not vfov or vfov <= 0 then
            local me = LocalPlayer()
            fov = Scaled(IsValid(me) and me.GetFOV and me:GetFOV() or 75)
            vfov = Scaled(vmfov or 54)
        end
        local wx, vx = math.tan(math.rad(fov) / 2), math.tan(math.rad(vfov) / 2)
        if wx <= 0 or vx <= 0 then return pos end
        local k = wx / vx
        local f, r, u = ang:Forward(), ang:Right(), ang:Up()
        local d = pos - origin
        return origin + r * (d:Dot(r) / k) + u * (d:Dot(u) / k) + f * d:Dot(f)
    end

    local function At(vm, name)
        local id = vm.LookupAttachment and vm:LookupAttachment(name) or 0
        if not id or id <= 0 then return nil end
        local a = vm:GetAttachment(id)
        return a and a.Pos or nil
    end
    -- The tip: the spark point furthest from the hand (worked out once for the model, while it's in view).
    local tipFor = {}
    local function Tip(vm, vmfov)
        local mdl = vm:GetModel() or ""
        local name = tipFor[mdl]
        if name == nil then
            local hb = vm.LookupBone and vm:LookupBone("ValveBiped.Bip01_R_Hand")
            local hand = hb and vm:GetBonePosition(hb) or EyePos()
            local best, bd = false, -1
            for _, n in ipairs(POINTS) do
                local p = At(vm, n)
                if p then
                    local d = LC_CL.BatonTipSpace(p, vmfov):DistToSqr(hand)
                    if d > bd then best, bd = n, d end
                end
            end
            name = best
            tipFor[mdl] = name
        end
        local p = name and At(vm, name)
        return p and LC_CL.BatonTipSpace(p, vmfov) or nil
    end
    LC_CL.BatonTip = Tip

    function SWEP:PostDrawViewModel(vm)
        if not IsValid(vm) or not render or not render.DrawSprite then return end
        local tip = Tip(vm, self.ViewModelFOV)
        if not tip then return end
        local s = math.Rand(2.2, 3.4)
        render.SetMaterial(GLOW)
        render.DrawSprite(tip, s, s, WHITE)
        if math.random() < 0.5 then -- (the crackle: a flick of blue at the same point)
            local c = math.Rand(0.8, 1.8)
            render.SetMaterial(FLARE)
            render.DrawSprite(tip + VectorRand() * 0.35, c, c, BLUE)
        end
    end
end
