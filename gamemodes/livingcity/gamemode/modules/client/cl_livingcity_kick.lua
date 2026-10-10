--[[
    Living City (client): the unit's kick (sv_livingcity_kick.lua)

      The key: lc_kick_key (G). F1 > Kick does the same.
      Everyone sees the leg come up: the thigh and knee of whoever kicked are
      bent and straightened in code, so it works on any model with the usual
      Half-Life 2 skeleton (every Civil Protection and Overwatch model).
      In first person you see your own leg: your model, drawn with everything
      but the kicking leg hidden, so it's always the right boot.
]]

LC_CL = LC_CL or {}

local cvKey = CreateClientConVar("lc_kick_key", "g", true, false, "Key for a unit's kick (a letter, or a key name like mouse4)")

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
    for _, name in ipairs(HIDE) do
        local b = leg:LookupBone(name)
        if b then leg:ManipulateBoneScale(b, Vector(0, 0, 0)) end
    end
    return leg
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
    RunConsoleCommand("lc_kick")
end)
