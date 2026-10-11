--[[
    Living City: Half-Life: Alyx-style Combine models

    When a Combine model pack is installed, the Overwatch wear it: players
    in the Overwatch ranks, and the city's own soldiers. Found by itself
    from what's installed, no list to edit:

      Workshop 3449180606  the first choice: all five Classic Combine
                           variants (soldier, shotgunner, prison guard,
                           shotgunner prison guard, Elite)
      Workshop 2041528484  the fallback: a soldier and the red prison guard

    Which is which comes from each model's name and path ("elite", "prison"
    or "guard", "shotgun"); a pack's NPC models come from its spawnmenu
    entries for npc_combine_s. Anything not found stays Half-Life 2's own
    (metrocops always do). Players who join are sent whichever of the two
    packs the server has mounted.

      lc_combine_models 0      Half-Life 2's models only
      lc_pm_<kind>, lc_npcmodel_<kind>  a model path to use instead, for
                               players and NPCs; kinds: soldier, shotgunner,
                               guard, guard_shotgun, elite
      lc_combine_models_list   what was found (admin)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn = CreateConVar("lc_combine_models", "1", FLAGS, "The Overwatch wear an installed Half-Life: Alyx-style Combine pack (Workshop 3449180606 or 2041528484) when one is found")

local KINDS = { "soldier", "shotgunner", "guard", "guard_shotgun", "elite" }
local cvPM, cvNPC = {}, {}
for _, k in ipairs(KINDS) do
    cvPM[k] = CreateConVar("lc_pm_" .. k, "", FLAGS, "Playermodel for the Overwatch's " .. k .. " (blank: found by itself)")
    cvNPC[k] = CreateConVar("lc_npcmodel_" .. k, "", FLAGS, "NPC model for the city's " .. k .. " soldiers (blank: found by itself)")
end

local PACKS = { ["3449180606"] = true, ["2041528484"] = true }

-- Half-Life 2's own: never "found"
local STOCK = {
    ["models/combine_soldier.mdl"] = true, ["models/combine_super_soldier.mdl"] = true, ["models/combine_soldier_prisonguard.mdl"] = true,
    ["models/player/combine_soldier.mdl"] = true, ["models/player/combine_super_soldier.mdl"] = true, ["models/player/combine_soldier_prisonguard.mdl"] = true,
}

-- What kind of Combine a model is, from its name and path (nil: not one).
function LC.CombineKindOf(text)
    local t = string.lower(text or "")
    if string.find(t, "police", 1, true) or string.find(t, "metro", 1, true) or string.find(t, "strip", 1, true) then return nil end
    if not (string.find(t, "combine", 1, true) or string.find(t, "hla", 1, true) or string.find(t, "alyx", 1, true)
        or string.find(t, "overwatch", 1, true) or string.find(t, "grunt", 1, true)) then return nil end
    local shotgun = string.find(t, "shotgun", 1, true) ~= nil
    if string.find(t, "elite", 1, true) or string.find(t, "super", 1, true) then return "elite" end
    if string.find(t, "prison", 1, true) or string.find(t, "guard", 1, true) then return shotgun and "guard_shotgun" or "guard" end
    if shotgun then return "shotgunner" end
    return "soldier"
end

local found -- { pm = { kind = path }, npc = { kind = path } }

local function Scan()
    found = { pm = {}, npc = {} }
    local pms = {}
    for name, path in pairs(player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}) do pms[#pms + 1] = { name, path } end
    table.sort(pms, function(a, b) return a[2] < b[2] end)
    for _, e in ipairs(pms) do
        local path = string.lower(e[2])
        local kind = not STOCK[path] and LC.CombineKindOf(e[1] .. " " .. path)
        if kind and not found.pm[kind] then found.pm[kind] = e[2] end
    end
    local npcs = {}
    for id, t in pairs(list and list.Get and list.Get("NPC") or {}) do
        if istable(t) and t.Class == "npc_combine_s" and isstring(t.Model) then npcs[#npcs + 1] = { tostring(id) .. " " .. tostring(t.Name or ""), t.Model } end
    end
    table.sort(npcs, function(a, b) return a[2] < b[2] end)
    for _, e in ipairs(npcs) do
        local path = string.lower(e[2])
        local kind = not STOCK[path] and LC.CombineKindOf(e[1] .. " " .. path)
        if kind and not found.npc[kind] then found.npc[kind] = e[2] end
    end
    -- a pack without a shotgunner (or a shotgunner guard) uses its plain one
    for _, set in pairs(found) do
        set.shotgunner = set.shotgunner or set.soldier
        set.guard_shotgun = set.guard_shotgun or set.guard
    end
    return found
end
function LC.RescanCombineModels() found = nil return Scan() end

-- The model for this kind of Combine (nil: Half-Life 2's own).
function LC.CombineModel(kind, forPlayer)
    if not cvOn:GetBool() then return nil end
    local over = (forPlayer and cvPM or cvNPC)[kind]
    if over and over:GetString() ~= "" then return over:GetString() end
    local f = found or Scan()
    return (forPlayer and f.pm or f.npc)[kind]
end

-- A player in an Overwatch rank (the rank says which kind: sh_livingcity_factions.lua)
LC.ModelOverrides = LC.ModelOverrides or {}
LC.ModelOverrides.combine = function(ply)
    if not (LCF and LCF.IsOverwatch and LCF.IsOverwatch(ply)) then return nil end
    local r = LCF.RankOf(ply)
    local kind = r and r.hla
    if not kind then return nil end
    -- half the soldiers and guards carry the shotgun look
    if (kind == "soldier" or kind == "guard") and LCF.UnitNumber and LCF.UnitNumber(ply:SteamID()) % 2 == 0 then
        kind = kind == "soldier" and "shotgunner" or "guard_shotgun"
    end
    return LC.CombineModel(kind, true)
end

-- joining players get the pack the server has
local function SendPacks()
    for _, a in ipairs(engine and engine.GetAddons and engine.GetAddons() or {}) do
        local id = tostring(a.wsid or "")
        if PACKS[id] and a.mounted ~= false and resource and resource.AddWorkshop then resource.AddWorkshop(id) end
    end
end
SendPacks()
hook.Add("InitPostEntity", "LivingCityCombineModels", function() found = nil SendPacks() end)

concommand.Add("lc_combine_models_list", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local f = LC.RescanCombineModels()
    local out = function(s) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, s) else print(s) end end
    for _, k in ipairs(KINDS) do
        out(string.format("%-14s player: %-50s npc: %s", k, LC.CombineModel(k, true) or "(Half-Life 2's)", LC.CombineModel(k, false) or "(Half-Life 2's)"))
    end
end)
