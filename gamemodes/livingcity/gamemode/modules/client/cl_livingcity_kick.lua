--[[
    Living City (client): the unit's kick (sv_livingcity_kick.lua)

      The key: lc_kick_key (G). F2 > Kick does the same.
      Everyone sees the leg come up: the thigh and knee of whoever kicked are
      bent and straightened in code, so it works on any model with the usual
      Half-Life 2 skeleton (every Civil Protection and Overwatch model).
      In first person you see your own leg: your model, drawn with everything
      but the kicking leg hidden, so it's always the right boot.
]]

LC_CL = LC_CL or {}

local cvKey = CreateClientConVar("lc_kick_key", "g", true, false, "Key for a Civil Protection unit's kick (a letter, or a key name like mouse4)")

local LENGTH = 0.55

function LC_CL.KickKeyName()
    local s = string.Trim(cvKey:GetString() or "")
    return string.upper(s ~= "" and s or "g")
end

-- How the leg bends, t seconds into the kick: thigh forward, knee bent.
-- Chamber, strike (the foot lands at 0.25), back down.
function LC_CL.KickPose(t)
    if t < 0 or t >= LENGTH then return 0, 0 end
    if t < 0.15 then
        local k = t / 0.15
        return -70 * k, 95 * k
    elseif t < 0.3 then
        local k = (t - 0.15) / 0.15
        return -70 - 20 * k, 95 * (1 - k)
    end
    local k = (t - 0.3) / (LENGTH - 0.3)
    return -90 * (1 - k), 0
end

-- Which way each bone turns (the HL2 skeleton's thigh and knee bend on their own yaw).
LC_CL.KickAxes = { thigh = Angle(0, 1, 0), calf = Angle(0, 1, 0) }

local function Pose(ent, t)
    local thigh, calf = LC_CL.KickPose(t)
    local bt = ent:LookupBone("ValveBiped.Bip01_R_Thigh")
    local bc = ent:LookupBone("ValveBiped.Bip01_R_Calf")
    if not bt or not bc then return false end
    ent:ManipulateBoneAngles(bt, LC_CL.KickAxes.thigh * thigh)
    ent:ManipulateBoneAngles(bc, LC_CL.KickAxes.calf * calf)
    return thigh ~= 0 or calf ~= 0
end

-- everyone kicking, as they're drawn
hook.Add("PrePlayerDraw", "LivingCityKick", function(ply)
    local t = CurTime() - ply:GetNW2Float("lc_kick_at", -100)
    if t < LENGTH then
        ply.lcKickPosed = Pose(ply, t)
    elseif ply.lcKickPosed then
        Pose(ply, LENGTH)
        ply.lcKickPosed = nil
    end
end)

------------------------------------------------------------------------
-- Your own leg, in first person
------------------------------------------------------------------------

local leg, legModel
local HIDE = { "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_L_Thigh" } -- (everything above the hips, and the other leg)

local function Leg(me)
    local m = me:GetModel()
    if IsValid(leg) and legModel == m then return leg end
    if IsValid(leg) then leg:Remove() end
    leg = ClientsideModel and ClientsideModel(m, RENDERGROUP_OPAQUE)
    legModel = m
    if not IsValid(leg) then return nil end
    leg:SetNoDraw(true)
    leg.GetPlayerColor = function() return IsValid(me) and me.GetPlayerColor and me:GetPlayerColor() or Vector(1, 1, 1) end
    local seq = leg:LookupSequence("idle_all_01")
    if seq and seq >= 0 then leg:ResetSequence(seq) end
    LC_CL.KickHideUpper(leg)
    return leg
end

-- Only the legs show (the owner, 7 November: the CP mask was in view during the kick). Every bone
-- but the hips and the kicking leg (the right thigh and all below it) is shrunk to nothing, one by
-- one, so the mask, the head, the arms and any extra bones a model has (the HL:Alyx metrocop's)
-- are gone too. A model without the usual skeleton keeps the old way: the spine and the other leg.
function LC_CL.KickHideUpper(ent)
    local pelvis, thigh = ent:LookupBone("ValveBiped.Bip01_Pelvis"), ent:LookupBone("ValveBiped.Bip01_R_Thigh")
    local n = ent.GetBoneCount and ent:GetBoneCount() or 0
    if not (pelvis and thigh and n > 0) then
        for _, name in ipairs(HIDE) do
            local b = ent:LookupBone(name)
            if b then ent:ManipulateBoneScale(b, Vector(0, 0, 0)) end
        end
        return 0
    end
    local hidden = 0
    for b = 0, n - 1 do
        local keep = b == pelvis
        local p = b
        while not keep and p and p >= 0 do -- (the kicking thigh, or something hanging off it)
            if p == thigh then keep = true end
            p = ent:GetBoneParent(p)
        end
        if not keep then
            ent:ManipulateBoneScale(b, Vector(0, 0, 0))
            hidden = hidden + 1
        end
    end
    return hidden
end

hook.Add("PostDrawOpaqueRenderables", "LivingCityKickLeg", function(depth, sky)
    if depth or sky then return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local t = CurTime() - me:GetNW2Float("lc_kick_at", -100)
    if t < 0 or t >= LENGTH or me:ShouldDrawLocalPlayer() then return end
    local l = Leg(me)
    if not IsValid(l) then return end
    local yaw = me:EyeAngles().y
    l:SetPos(me:GetPos() - Angle(0, yaw, 0):Forward() * 6)
    l:SetAngles(Angle(0, yaw, 0))
    l:SetSkin(me:GetSkin())
    for _, bg in ipairs(me:GetBodyGroups() or {}) do l:SetBodygroup(bg.id, me:GetBodygroup(bg.id)) end
    Pose(l, t)
    l:SetupBones()
    l:DrawModel()
end)

------------------------------------------------------------------------
-- The key
------------------------------------------------------------------------

local function KeyCode()
    local s = string.lower(string.Trim(cvKey:GetString()))
    if s == "" or not input or not input.GetKeyCode then return nil end
    local k = input.GetKeyCode(s)
    if k and k > 0 then return k end
    return nil
end

hook.Add("PlayerButtonDown", "LivingCityKick", function(ply, button)
    if not IsFirstTimePredicted() or ply ~= LocalPlayer() then return end
    if button ~= KeyCode() then return end
    if (vgui.GetKeyboardFocus and IsValid(vgui.GetKeyboardFocus())) or (gui.IsGameUIVisible and gui.IsGameUIVisible()) then return end
    if ply:GetNW2String("lcf_faction", "") ~= "cp" then return end
    -- (the same way F2 > Kick sends it. "lc_kick" typed or run on a player's game is the server's on/off
    -- setting of that name, which only prints its value, so the key never kicked: the owner, 11 November)
    if LC_CL.SendAction then LC_CL.SendAction("kick") else RunConsoleCommand("lc_kick") end
end)

------------------------------------------------------------------------
-- Knocked out by a door (sv_livingcity_kick.lua): black for a while, then
-- the room swims, harder than Breen's water
------------------------------------------------------------------------

local function Dizzy(me, now)
    local from, to = me:GetNW2Float("lc_dizzy_from", 0), me:GetNW2Float("lc_dizzy_until", 0)
    if now >= to or now < from - 0.01 then return 0 end
    return math.Clamp((to - now) / 8, 0, 1)
end

hook.Add("HUDPaint", "LivingCityKnockedOut", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local left = me:GetNW2Float("lc_ko_until", 0) - CurTime()
    if left <= 0 then return end
    local a = math.Clamp(left / 1.5, 0, 1) -- (the last moment fades back in)
    surface.SetDrawColor(0, 0, 0, 255 * a)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    if a > 0.5 then
        draw.SimpleText("Out cold", "DermaLarge", ScrW() / 2, ScrH() / 2 - 14, Color(170, 170, 175, 200 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("You come round in %d", math.ceil(left)), "DermaDefault", ScrW() / 2, ScrH() / 2 + 18, Color(140, 140, 145, 200 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

hook.Add("RenderScreenspaceEffects", "LivingCityKnockedOut", function()
    local me = LocalPlayer()
    if not IsValid(me) then return end
    local d = Dizzy(me, CurTime())
    if d <= 0 then return end
    if DrawMotionBlur then DrawMotionBlur(0.08, 0.95 * d, 0.03) end
    if DrawColorModify then
        DrawColorModify({
            ["$pp_colour_addr"] = 0.02 * d, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -0.04 * d, ["$pp_colour_contrast"] = 1 + 0.15 * d,
            ["$pp_colour_colour"] = 1 - 0.6 * d, ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
        })
    end
end)

LC_CL.ViewMods = LC_CL.ViewMods or {}
LC_CL.ViewMods.knocked = { order = 41, fn = function(ply, view)
    local d = Dizzy(ply, CurTime())
    if d <= 0 then return end
    local t = CurTime()
    view.angles = view.angles + Angle(math.sin(t * 1.1) * 5 * d, math.sin(t * 0.7) * 4 * d, math.sin(t * 1.6) * 14 * d)
    view.fov = view.fov + math.sin(t * 0.9) * 9 * d
end }

-- Facing a locked door a kick would open (the server says which: sv_livingcity_kick.lua), a reminder of how,
-- with this player's own kick key and wherever Kick is in F2 right now.
local kickF1, kickKey, kickF1At = nil, nil, 0
-- (made once here, not every frame)
local C_0_0_0_220 = Color(0, 0, 0, 220)
local C_240_230_200 = Color(240, 230, 200)
hook.Add("HUDPaint", "LivingCityKickHint", function()
    local me = LocalPlayer()
    if not IsValid(me) or not IsValid(me:GetNW2Entity("lc_kick_hint")) then return end
    if CurTime() > kickF1At then kickF1At = CurTime() + 1 kickF1, kickKey = nil, nil if LC_CL.QuickSlot then kickF1, kickKey = LC_CL.QuickSlot("kick") end end
    local how = "press " .. LC_CL.KickKeyName()
    if kickF1 then how = how .. " (or " .. (kickKey or "F2") .. " > " .. kickF1 .. ")" end
    draw.SimpleTextOutlined("Locked. To kick it in: " .. how, "DermaDefaultBold", ScrW() / 2, ScrH() * 0.62, C_240_230_200, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, C_0_0_0_220)
end)
