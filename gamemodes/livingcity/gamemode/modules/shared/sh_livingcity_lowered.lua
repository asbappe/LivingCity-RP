--[[
    Living City: guns carried lowered (the owner, 1 November: one of the lost v2.7 pieces)

    Where it counts (the owner, 2 November): in rebel territory (anyone), and for Civil Protection's
    metrocops and recruits on the Combine's own ground (the Combine don't trust a unit who hasn't been
    through the Overwatch's conditioning). Everywhere else a gun is simply ready. The server marks who
    must carry lowered (lc_carry_lowered, sv_livingcity_streetlife.lua); walking in, your gun goes down.

    There, a gun comes out lowered: pointed at the ground, no crosshair, and it won't fire. Hold R (half a second)
    to raise it, and again to lower it; a left click while it's lowered raises it instead of firing.
    Tapping R still reloads. In your own view it's Half-Life 2's lowered animation where the gun has one
    (the anniversary update's), and tipped down otherwise. Switching weapon lowers it again.

      lc_lowered_weapons 0/1 (1)
]]

LC = LC or {}
LCL = LCL or {}

local cvOn = CreateConVar("lc_lowered_weapons", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Guns are carried lowered until raised (hold R)")
local GUNS = { weapon_pistol = true, weapon_357 = true, weapon_smg1 = true, weapon_ar2 = true, weapon_shotgun = true,
    weapon_crossbow = true, weapon_rpg = true }
LCL.Guns = GUNS
local HOLD = 0.5

function LCL.MustLower(ply) return IsValid(ply) and ply:GetNW2Bool("lc_carry_lowered", false) end
function LCL.Lowered(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not LCL.MustLower(ply) then return false end
    local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
    return IsValid(w) and GUNS[w:GetClass()] == true and not ply:GetNW2Bool("lc_raised", false)
end

function LCL.SetRaised(ply, up)
    if not IsValid(ply) then return end
    ply:SetNW2Bool("lc_raised", up == true)
    if SERVER then ply:EmitSound(up and "weapons/smg1/switch_single.wav" or "weapons/smg1/switch_burst.wav", 50, up and 110 or 90, 0.4) end
end

-- holding R toggles; a click while lowered raises; nothing fires while lowered
hook.Add("StartCommand", "LivingCityLowered", function(ply, cmd)
    if not cvOn:GetBool() or not cmd.KeyDown or not cmd.RemoveKey then return end
    local w = ply:GetActiveWeapon()
    if not IsValid(w) or not GUNS[w:GetClass()] or not LCL.MustLower(ply) then ply.lcRHeld = nil return end
    if cmd:KeyDown(IN_RELOAD) then
        ply.lcRHeld = ply.lcRHeld or CurTime()
        if not ply.lcRDone and CurTime() - ply.lcRHeld > HOLD then
            ply.lcRDone = true
            if SERVER then LCL.SetRaised(ply, not ply:GetNW2Bool("lc_raised", false)) end
        end
    else
        ply.lcRHeld, ply.lcRDone = nil, nil
    end
    if not ply:GetNW2Bool("lc_raised", false) then
        if cmd:KeyDown(IN_ATTACK) and SERVER and (ply.lcRaiseAt or 0) < CurTime() then
            ply.lcRaiseAt = CurTime() + 0.6
            LCL.SetRaised(ply, true)
        end
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end
end)

if SERVER then
    hook.Add("PlayerSwitchWeapon", "LivingCityLowered", function(ply) ply:SetNW2Bool("lc_raised", false) end)
    hook.Add("PlayerSpawn", "LivingCityLowered", function(ply) ply:SetNW2Bool("lc_raised", false) end)
end

if CLIENT then
    -- On rebel ground, or the Combine's for a recruit or metrocop, from the edge in: while a gun is up,
    -- a prompt in the middle of the screen says to lower it; it goes the moment it's down.
    local WHERE = {
        rebel = "Rebel ground: keep your gun lowered, or the fighters open fire.",
        combine = "Overwatch ground: recruits and metrocops carry lowered, or the soldiers open fire.",
    }
    -- (made once here, not every frame)
    local C_0_0_0_200 = Color(0, 0, 0, 200)
    local C_235_235_225_230 = Color(235, 235, 225, 230)
    hook.Add("HUDPaint", "LivingCityLowerPrompt", function()
        local me = LocalPlayer()
        if not IsValid(me) or not cvOn:GetBool() then return end
        local ground = me:GetNW2String("lc_lowered_ground", "")
        if ground == "" or not WHERE[ground] then return end
        local w = me:GetActiveWeapon()
        if not IsValid(w) or not GUNS[w:GetClass()] or LCL.Lowered(me) then return end
        local pulse = 180 + 75 * math.abs(math.sin(CurTime() * 4))
        local x, y = ScrW() / 2, ScrH() * 0.3
        draw.SimpleTextOutlined("LOWER YOUR WEAPON: hold R", "DermaLarge", x, y, Color(255, 200, 80, pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, C_0_0_0_200)
        draw.SimpleTextOutlined(WHERE[ground], "DermaDefaultBold", x, y + 30, C_235_235_225_230, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_200)
    end)

    -- no crosshair while it's down
    hook.Add("HUDShouldDraw", "LivingCityLowered", function(name)
        if name == "CHudCrosshair" and LCL.Lowered(LocalPlayer()) then return false end
    end)
    -- Half-Life 2's lowered animation, kept playing while it's down
    hook.Add("Think", "LivingCityLowered", function()
        local me = LocalPlayer()
        if not IsValid(me) then return end
        local vm = me.GetViewModel and me:GetViewModel()
        if not IsValid(vm) then return end
        if LCL.Lowered(me) then
            local seq = vm:SelectWeightedSequence(ACT_VM_IDLE_LOWERED or 0)
            me.lcLowSeq = (seq and seq > 0) and seq or nil
            if me.lcLowSeq and vm:GetSequence() ~= me.lcLowSeq then vm:SendViewModelMatchingSequence(me.lcLowSeq) end
        end
    end)
    -- no lowered animation: tipped down instead
    hook.Add("CalcViewModelView", "LivingCityLowered", function(wep, vm, oldPos, oldAng, pos, ang)
        local me = LocalPlayer()
        if not LCL.Lowered(me) or me.lcLowSeq then return end
        local a = Angle(ang.p, ang.y, ang.r)
        a:RotateAroundAxis(a:Right(), -28)
        a:RotateAroundAxis(a:Up(), 12)
        return pos - ang:Up() * 4 + ang:Right() * 2, a
    end)
end
