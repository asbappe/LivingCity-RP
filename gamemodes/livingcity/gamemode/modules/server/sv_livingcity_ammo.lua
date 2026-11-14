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

-- How many more rounds of this kind the player can carry: a number, or nil when there is no limit
-- (lc_hl2_ammo 0, or a kind with none). An ammo box isn't loaded into a full pocket.
function LC.AmmoRoom(ply, ammo)
    if not IsValid(ply) or not ammo then return nil end
    local max = LC.AmmoMax and LC.AmmoMax(ammo) or nil
    if not max or max <= 0 then return nil end
    return math.max(0, max - (ply:GetAmmoCount(ammo) or 0))
end

-- A health vial on the ground, E pressed on it at full health: into the pockets, not held out in
-- front (the owner, 13 November: "I press E on it and I just hold it in front of me, never putting
-- it into my pockets"). Hurt, walking over it heals as it always did.
function LC.PocketVial(ply, ent)
    if not (IsValid(ply) and IsValid(ent)) or ent:GetClass() ~= "item_healthvial" or ent.lcPocketed then return false end
    if ply:Health() < ply:GetMaxHealth() then return false end
    if not (LC.GiveItem and LCS and LCS.Items and LCS.Items.health_vial) then return false end
    if not LC.GiveItem(ply, "health_vial", 1) then
        if LC.Notice and (ply.lcVialFullAt or 0) < CurTime() then
            ply.lcVialFullAt = CurTime() + 3
            LC.Notice(ply, "warn", "Pockets full", "No room for the health vial. Make room (F3) and pick it up again.", 4)
        end
        return true
    end
    ent.lcPocketed = true
    ent:Remove()
    ply:EmitSound("items/itempickup.wav", 55)
    if LC.Notice then LC.Notice(ply, "info", "Health vial", "In your pockets (F3), for when you need it.", 4) end
    return true
end
hook.Add("PlayerUse", "LivingCityPocketVial", function(ply, ent)
    if IsValid(ent) and ent:GetClass() == "item_healthvial" and LC.PocketVial(ply, ent) then return false end
end)
hook.Add("AllowPlayerPickup", "LivingCityPocketVial", function(ply, ent)
    if IsValid(ent) and ent:GetClass() == "item_healthvial" and ply:Health() >= ply:GetMaxHealth() then
        LC.PocketVial(ply, ent)
        return false
    end
end)
