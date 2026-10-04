--[[
    Living City: gamemode compatibility

    Detects the gamemode and adapts:
      sandbox    Living City's own systems: built-in wanted status, prisons,
                 and (optionally) the City Factions module for jobs and ranks
      darkrp     CP jobs count as Civil Protection, crimes make you DarkRP-wanted,
                 arrests go to DarkRP's jail, CP door groups count as CP doors
      helix      HL2RP Combine factions (player:IsCombine()) count as Civil Protection
      nutscript  same as Helix
      clockwork  Schema:PlayerIsCombine() counts as Civil Protection

    On any RP gamemode, Living City never unlocks doors on its own and never
    overrides how players use doors.

    Hooks other addons or a schema can use (return nil to fall through):
      LivingCityIsCP(ply)                 -> true / false
      LivingCityIsZombie(ply)             -> true / false
      LivingCityIsWanted(ply)             -> true / false
      LivingCityCrime(ply, reason)        -> true if you handled it
      LivingCityCanUseCPDoor(ply, door)   -> true / false
]]

if CLIENT then return end

LC = LC or {}
LC.LocalWanted = LC.LocalWanted or {} -- [ply] = { untilT, reason }

local detected

local function Detect()
    local meta = FindMetaTable("Player")
    if DarkRP and meta.isCP then return "darkrp" end
    if ix then return "helix" end
    if nut then return "nutscript" end
    if Clockwork then return "clockwork" end
    return "sandbox"
end

function LC.Gamemode()
    if detected then return detected end
    if not GAMEMODE then return "sandbox" end -- too early to tell; don't cache
    detected = Detect()
    return detected
end

function LC.IsRP() return LC.Gamemode() ~= "sandbox" end

-- Running as the Living City gamemode (rather than as an addon on Sandbox).
-- Living City's own systems are used either way; the gamemode just turns
-- them all on and locks Sandbox's building away from regular players.
function LC.InOwnGamemode()
    return (GAMEMODE and GAMEMODE.IsLivingCity == true) or engine.ActiveGamemode() == "livingcity"
end

-- Admins in the gamemode's build mode (or any admin, outside the gamemode).
function LC.IsBuilder(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return false end
    if LC.InOwnGamemode() then return ply:GetNW2Bool("lc_build", false) end
    return true
end

hook.Add("InitPostEntity", "LivingCityDetect", function()
    detected = nil
    print("[Living City] Gamemode support: " .. LC.Gamemode())
end)

------------------------------------------------------------------------
-- Who is who
------------------------------------------------------------------------

function LC.PlayerIsCP(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local override = hook.Run("LivingCityIsCP", ply)
    if override ~= nil then return override == true end

    local gm = LC.Gamemode()
    local ok, res = pcall(function()
        if gm == "darkrp" then return ply:isCP() end
        if gm == "helix" or gm == "nutscript" then return ply.IsCombine and ply:IsCombine() end
        if gm == "clockwork" then return Schema and Schema.PlayerIsCombine and Schema:PlayerIsCombine(ply) end
        return false
    end)
    return ok and res == true
end

function LC.PlayerIsZombie(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return hook.Run("LivingCityIsZombie", ply) == true
end

------------------------------------------------------------------------
-- Wanted status: DarkRP's own, or Living City's built-in one elsewhere
------------------------------------------------------------------------

function LC.PlayerIsWanted(ply)
    if not IsValid(ply) then return false end
    if (ply.lcGraceUntil or 0) > CurTime() then return false end -- just released: a head start
    local override = hook.Run("LivingCityIsWanted", ply)
    if override ~= nil then return override == true end
    if LC.Gamemode() == "darkrp" then
        local ok, res = pcall(function() return ply:isWanted() end)
        return ok and res == true
    end
    local w = LC.LocalWanted[ply]
    return w ~= nil and CurTime() < w.untilT
end

function LC.SetWanted(ply, seconds, reason)
    hook.Run("LivingCityWanted", ply, reason, seconds)
    if LC.Gamemode() == "darkrp" then
        pcall(function() ply:wanted(nil, reason, seconds) end)
        return
    end
    LC.LocalWanted[ply] = { untilT = CurTime() + seconds, reason = reason }
    ply:SetNW2Float("lc_wanted_until", CurTime() + seconds)
    ply:SetNW2String("lc_wanted_reason", reason or "")
end

function LC.ClearWanted(ply)
    if LC.Gamemode() == "darkrp" then
        pcall(function() ply:unWanted(nil) end)
        return
    end
    LC.LocalWanted[ply] = nil
    ply:SetNW2Float("lc_wanted_until", 0)
end

-- Tell the gamemode a crime happened. Returns true if something handled it.
function LC.ReportCrime(ply, reason, seconds)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local handled = hook.Run("LivingCityCrime", ply, reason)
    if handled ~= nil then return handled == true end
    if LC.PlayerIsCP(ply) then return false end
    if LC.Gamemode() == "darkrp" and LC.PlayerIsWanted(ply) then return true end
    LC.SetWanted(ply, seconds or 180, reason)
    return true
end

function LC.PlayerMayUseCPDoor(ply, door)
    local override = hook.Run("LivingCityCanUseCPDoor", ply, door)
    if override ~= nil then return override == true end
    if LC.IsRP() or (LC.FactionsActive and LC.FactionsActive()) then
        if LC.PlayerIsCP(ply) or ply:IsAdmin() then return true end
        -- someone in a stolen uniform: the door reads their biosignal
        return LC.DisguiseDoorCheck ~= nil and LC.DisguiseDoorCheck(ply, door) == true
    end
    return true
end

------------------------------------------------------------------------
-- DarkRP door groups ("Cops and Mayor only" and the like)
------------------------------------------------------------------------

-- True if every team allowed through this door is a Civil Protection team.
function LC.DoorIsCPByGamemode(door)
    if LC.Gamemode() ~= "darkrp" then return false end
    local ok, res = pcall(function()
        local teams = {}
        local group = door:getKeysDoorGroup()
        if group and RPExtraTeamDoors and RPExtraTeamDoors[group] then
            for _, t in ipairs(RPExtraTeamDoors[group]) do teams[t] = true end
        else
            teams = door:getKeysDoorTeams() or {}
        end
        if table.IsEmpty(teams) then return false end
        for t in pairs(teams) do
            if not (GAMEMODE.CivilProtection and GAMEMODE.CivilProtection[t]) then return false end
        end
        return true
    end)
    return ok and res == true
end

-- The tag NPCs should obey: ours first, then whatever the gamemode says.
function LC.EffectiveDoorTag(door)
    return LC.GetDoorTag(door) or (LC.DoorIsCPByGamemode(door) and "cp") or nil
end

------------------------------------------------------------------------
-- Wanted players: nearby security NPCs go after them, and stand down once
-- the wanted status clears.
------------------------------------------------------------------------

local wasWanted = {}

timer.Create("LivingCityWanted", 1, 0, function()
    local now = CurTime()
    for ply, w in pairs(LC.LocalWanted) do
        if not IsValid(ply) or now > w.untilT then
            if IsValid(ply) then ply:SetNW2Float("lc_wanted_until", 0) end
            LC.LocalWanted[ply] = nil
        end
    end
    if not LC.Running then return end
    for _, ply in ipairs(player.GetAll()) do
        local wanted = ply:Alive() and LC.PlayerIsWanted(ply) and not LC.PlayerIsCP(ply)
            and not (LC.Prisoners and LC.Prisoners[ply])
            and not (LC.FoolsSecurity and LC.FoolsSecurity(ply)) -- in a stolen uniform, they don't know you
        if wanted then
            -- the higher the alert, the wider the net
            local alert = LC.AlertLevel and LC.AlertLevel(ply) or 0
            LC.MakeCopsHostile(ply, ply:GetPos(), alert >= 3 and nil or (alert == 2 and 5000 or 1500))
        elseif wasWanted[ply] then
            LC.CalmCops(ply)
        end
        wasWanted[ply] = wanted or nil
    end
end)
