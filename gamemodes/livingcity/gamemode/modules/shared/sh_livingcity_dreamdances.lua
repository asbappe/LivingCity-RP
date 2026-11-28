--[[
    Living City: ActMod's dances are for dreams only (shared)

    The owner, 28 November: ActMod (Workshop 2538387266) and its base (2615656036) are in
    the server's collection, and "the animations should not be available for any players
    except in dreams".

    ActMod asks other addons before it starts an emote (its own hooks, named below). Awake,
    the answer is no, and nothing is said. A dance still going when the dreamer wakes ends
    with the dream. Nothing of ActMod's is changed or copied; without ActMod on the server
    this file does nothing.
]]

LC = LC or {}

-- May this player dance ActMod's dances now? (Only a dreaming player; what is no player is not ours to stop.)
function LC.DreamDanceAllowed(ply)
    if not IsValid(ply) or not ply.IsPlayer or not ply:IsPlayer() then return true end
    if SERVER and LC.Dreaming and LC.Dreaming(ply) then return true end
    return ply:GetNW2Bool("lc_dreaming", false) == true
end

local function Refuse(ply)
    if not LC.DreamDanceAllowed(ply) then return true end
end

-- the server's two (an emote, a gesture), and the client's (its menu and its keys)
for _, name in ipairs({ "ActMod_sv_DontStartAct", "ActMod_sv_DontStartGesture", "ActMod_CantSCAct" }) do
    hook.Add(name, "LivingCityDreamsOnly", Refuse)
end

if SERVER then
    hook.Add("LivingCityDreamWoke", "LivingCityDreamDanceEnds", function(p)
        local am = A_AM and A_AM.ActMod
        if not (am and am.EndAct and IsValid(p) and p.GetNWBool) then return end
        if p:GetNWBool("A_AM.ActMod.IsAct", false) then LC.Try(am.EndAct, am, p) end
    end)
end
