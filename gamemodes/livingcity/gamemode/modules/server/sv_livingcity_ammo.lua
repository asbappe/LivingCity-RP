--[[
    Living City: Half-Life 2's ammo limits

    The owner, 13 November: "the gamemode is using the Garry's mod max ammo
    count ... Can we set the ammo limits for all characters/classes/jobs/
    ranks/NPCs/players to the HL2 ammo limits instead".

    Garry's Mod lets anyone carry 9999 of every kind of round (gmod_maxammo).
    With lc_hl2_ammo (1) the server uses each kind's own limit instead
    (gmod_maxammo 0) and sets those limits to Half-Life 2's: pistol 150,
    SMG 225, .357 12, pulse rifle 60, shotgun 30, crossbow 10, grenades 5,
    SMG grenades 3, pulse rifle balls 3, rockets 3. Picking up or being given
    more than that stops at the limit, and anything over it (put back from a
    dream, a story, an older save) is cut down to it. Everyone the same, every
    side, rank and job. (NPCs in Half-Life 2 never run out at all: they
    reload forever, so there's nothing to limit for them.)
]]

if CLIENT then return end

LC = LC or {}

local cvOn = CreateConVar("lc_hl2_ammo", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Half-Life 2's ammo limits (pistol 150, SMG 225, shotgun 30, pulse rifle 60...) instead of Garry's Mod's 9999 of everything")

-- ammo type = { the skill setting that holds its limit, Half-Life 2's limit }
LC.HL2_AMMO = {
    Pistol = { "sk_max_pistol", 150 },
    SMG1 = { "sk_max_smg1", 225 },
    ["357"] = { "sk_max_357", 12 },
    AR2 = { "sk_max_ar2", 60 },
    Buckshot = { "sk_max_buckshot", 30 },
    XBowBolt = { "sk_max_crossbow", 10 },
    Grenade = { "sk_max_grenade", 5 },
    SMG1_Grenade = { "sk_max_smg1_grenade", 3 },
    AR2AltFire = { "sk_max_ar2_altfire", 3 },
    RPG_Round = { "sk_max_rpg_round", 3 },
}

-- The most of a kind of round anyone carries (nil: no limit of ours).
function LC.AmmoMax(ammo)
    if not cvOn:GetBool() then return nil end
    local t = LC.HL2_AMMO[ammo]
    return t and t[2] or nil
end

-- n rounds of a kind, no more than its limit.
function LC.AmmoCapped(ammo, n)
    local m = LC.AmmoMax(ammo)
    n = tonumber(n) or 0
    if m and n > m then return m end
    return n
end

local function Set(name, v)
    local cv = GetConVar and GetConVar(name)
    if not cv then return end
    if tostring(cv:GetString()) ~= tostring(v) then RunConsoleCommand(name, tostring(v)) end
end

function LC.ApplyHL2Ammo()
    if not cvOn:GetBool() then
        Set("gmod_maxammo", 9999) -- (Garry's Mod's own default)
        return
    end
    Set("gmod_maxammo", 0) -- (0: each kind of round's own limit)
    for _, t in pairs(LC.HL2_AMMO) do Set(t[1], t[2]) end
end

-- Anyone over a limit (given rounds some other way) is cut down to it.
function LC.ClampAmmo(ply)
    if not cvOn:GetBool() or not IsValid(ply) or not ply.GetAmmoCount or not ply.SetAmmo then return end
    for ammo, t in pairs(LC.HL2_AMMO) do
        local n = ply:GetAmmoCount(ammo) or 0
        if n > t[2] then ply:SetAmmo(t[2], ammo) end
    end
end

-- Kept that way (the owner, 13 November: "persistent across deaths, respawns, close calls (near deaths) and waking up
-- from dreams"): the limits are the server's own settings, set again at every map start (a map's skill settings can
-- put Half-Life 2's back to something else) and checked every five seconds; and anyone's rounds are cut down to them
-- as they spawn or respawn, are picked up after a close call, and wake from a dream (sv_livingcity_dreams.lua puts
-- their rounds back capped), on top of the five-second check.
LC.ApplyHL2Ammo()
hook.Add("Initialize", "LivingCityHL2Ammo", function() LC.ApplyHL2Ammo() end)
hook.Add("InitPostEntity", "LivingCityHL2Ammo", function() LC.ApplyHL2Ammo() end)
timer.Simple(1, function() LC.ApplyHL2Ammo() end)
local function Soon(ply) timer.Simple(0.5, function() if IsValid(ply) then LC.ClampAmmo(ply) end end) end
hook.Add("PlayerSpawn", "LivingCityHL2Ammo", Soon)
hook.Add("PlayerLoadout", "LivingCityHL2Ammo", Soon)
hook.Add("LivingCityRevived", "LivingCityHL2Ammo", Soon)
hook.Add("LivingCityDreamWoke", "LivingCityHL2Ammo", Soon)
if cvars and cvars.AddChangeCallback then
    cvars.AddChangeCallback("lc_hl2_ammo", function() LC.ApplyHL2Ammo() end, "LivingCityHL2Ammo")
end
timer.Create("LivingCityAmmoClamp", 5, 0, function()
    LC.ApplyHL2Ammo() -- (only touches a setting that's been changed)
    if not cvOn:GetBool() then return end
    for _, p in ipairs(player.GetAll()) do LC.ClampAmmo(p) end
end)
