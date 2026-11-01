--[[
    Grenades (Living City). Throws the grenades in your pockets: smoke,
    flashbangs, chlorine gas, poison gas bombs, firebombs (and homemade smoke bombs).
      Left click   throw the selected kind
      R            switch kind
    You're handed it whenever you're carrying any, and it goes when you run out.
]]

AddCSLuaFile()

SWEP.PrintName = "Grenades"
SWEP.Author = "Living City"
SWEP.Instructions = "Left click: throw. R: switch between what you're carrying (smoke, flashbang, chlorine, poison gas, firebomb)."
SWEP.Spawnable = false
SWEP.Slot = 4
SWEP.SlotPos = 2
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.UseHands = true
SWEP.HoldType = "grenade"
SWEP.DrawAmmo = false
SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local KINDS = { "smoke", "flash", "gas", "poison", "fire" }
local NAMES = { smoke = "SMOKE", flash = "FLASHBANG", gas = "CHLORINE GAS", poison = "POISON GAS", fire = "FIREBOMB" }

function SWEP:Initialize()
    if self.SetHoldType then self:SetHoldType(self.HoldType) end
end

function SWEP:Kind()
    local k = self:GetNW2String("lcg_kind", "")
    if k ~= "" then return k end
    local owner = self:GetOwner()
    for _, kind in ipairs(KINDS) do
        if IsValid(owner) and owner:GetNW2Int("lcg_" .. kind, 0) > 0 then return kind end
    end
    return "smoke"
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1.3)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if self.SendWeaponAnim then self:SendWeaponAnim(ACT_VM_THROW) end
    if owner.SetAnimation then owner:SetAnimation(PLAYER_ATTACK1) end
    if SERVER and LC and LC.ThrowKind then
        local kind = self:Kind()
        timer.Simple(0.25, function()
            if not IsValid(owner) then return end
            local ok, why = LC.ThrowKind(owner, kind)
            if not ok and why then owner:ChatPrint(why) end
        end)
    end
end

function SWEP:SecondaryAttack() end

function SWEP:Reload()
    if (self.lcNextSwitch or 0) > CurTime() then return end
    self.lcNextSwitch = CurTime() + 0.4
    local owner = self:GetOwner()
    if not IsValid(owner) or not SERVER then return end
    local cur = self:Kind()
    local start = 1
    for i, k in ipairs(KINDS) do if k == cur then start = i end end
    for step = 1, #KINDS do
        local k = KINDS[(start + step - 1) % #KINDS + 1]
        if owner:GetNW2Int("lcg_" .. k, 0) > 0 then
            self:SetNW2String("lcg_kind", k)
            owner:ChatPrint("Grenade: " .. string.lower(NAMES[k]))
            return
        end
    end
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local sel = self:Kind()
    -- only what you're carrying (and the one picked), one row each
    local shown = {}
    for _, k in ipairs(KINDS) do if owner:GetNW2Int("lcg_" .. k, 0) > 0 or k == sel then shown[#shown + 1] = k end end
    local x, y = ScrW() - 220, ScrH() - 50 - #shown * 18
    draw.RoundedBox(4, x, y, 200, 8 + #shown * 18, Color(10, 12, 16, 190))
    local row = 0
    for _, k in ipairs(shown) do
        local n = owner:GetNW2Int("lcg_" .. k, 0)
        local col = (k == sel) and Color(240, 200, 120) or Color(170, 165, 150)
        draw.SimpleText((k == sel and "> " or "  ") .. NAMES[k], "DermaDefaultBold", x + 10, y + 12 + row * 18, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(n), "DermaDefaultBold", x + 190, y + 12 + row * 18, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        row = row + 1
    end
end
