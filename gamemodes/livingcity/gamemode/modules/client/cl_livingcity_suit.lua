--[[
    Living City (client): first-person hands: the Infestation Control suits', and a unit's own

    The workshop pack's hands for its suits sit too far out in front of you, so you see through
    the open ends of the sleeves. While you're wearing one of its suits (models/player/worker_*
    or engineer_*), every weapon's first-person model is drawn a little nearer.
      lc_suit_hands "forward right up" (yours; "-6 0 0" by default): move them yourself.
]]

LC_CL = LC_CL or {}

local cvHands = CreateClientConVar("lc_suit_hands", "-6 0 0", true, false, "How far to move first-person hands while wearing an Infestation Control suit: forward right up")

local function InSuit(ply)
    local m = string.lower(IsValid(ply) and ply:GetModel() or "")
    return string.find(m, "models/player/worker_", 1, true) ~= nil or string.find(m, "models/player/engineer_", 1, true) ~= nil
end
LC_CL.InSuit = InSuit

hook.Add("CalcViewModelView", "LivingCitySuitHands", function(wep, vm, oldPos, oldAng, pos, ang)
    local me = LocalPlayer()
    if not InSuit(me) then return end
    -- (a weapon that places its own model, the radio say, is left to it)
    if IsValid(wep) and (wep.CalcViewModelView or wep.GetViewModelPosition) then return end
    local parts = {}
    for n in string.gmatch(cvHands:GetString(), "%-?[%d%.]+") do parts[#parts + 1] = tonumber(n) end
    local f, r, u = parts[1] or -6, parts[2] or 0, parts[3] or 0
    return pos + ang:Forward() * f + ang:Right() * r + ang:Up() * u, ang
end)

-- A unit's own body as their first-person hands (lc_cp_hands "own", sv_livingcity_factions.lua): everything
-- but the arms and hands shrunk to nothing, so only their own sleeves and gloves show in front of them.
local ARM = { "clavicle", "upperarm", "forearm", "hand", "finger", "ulna", "wrist", "elbow", "bicep" }
local function IsArm(name)
    name = string.lower(name or "")
    if not string.find(name, "_l_", 1, true) and not string.find(name, "_r_", 1, true) then return false end
    for _, a in ipairs(ARM) do if string.find(name, a, 1, true) then return true end end
    return false
end
hook.Add("PreDrawPlayerHands", "LivingCityOwnHands", function(hands, vm, ply, wep)
    if not IsValid(hands) or not hands.GetNW2Bool or not hands:GetNW2Bool("lc_own_hands", false) then return end
    local m = hands:GetModel()
    if hands.lcShrunkFor == m or not hands.GetBoneCount or not hands.ManipulateBoneScale then return end
    hands.lcShrunkFor = m
    for i = 0, hands:GetBoneCount() - 1 do
        hands:ManipulateBoneScale(i, IsArm(hands:GetBoneName(i)) and Vector(1, 1, 1) or Vector(0, 0, 0))
    end
end)
