--[[
    Living City (client): the hands of the Infestation Control suits

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
