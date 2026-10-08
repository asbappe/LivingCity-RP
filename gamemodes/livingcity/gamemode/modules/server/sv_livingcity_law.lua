--[[
    Living City: who's who, and who's wanted

    The questions every system asks: is this a unit, is this one of the
    infested, is this person wanted. Crimes make you wanted (Living City's own
    wanted status); nearby security comes after the wanted, and stands down
    once it clears.

    Hooks the city's modules answer (return nil to fall through):
      LivingCityIsCP(ply)                 -> true / false (sv_livingcity_factions.lua)
      LivingCityIsZombie(ply)             -> true / false
      LivingCityIsWanted(ply)             -> true / false
      LivingCityCrime(ply, reason)        -> true if handled
      LivingCityCanUseCPDoor(ply, door)   -> true / false
]]

if CLIENT then return end

LC = LC or {}
LC.LocalWanted = LC.LocalWanted or {} -- [ply] = { untilT, reason }

-- Can someone at from see to? Walls block it, and so does smoke (sv_livingcity_crafting.lua).
-- The one check every "does a unit see you" goes through.
function LC.LineOfSight(from, to, filter, target)
    local tr = util.TraceLine({ start = from, endpos = to, mask = MASK_OPAQUE, filter = filter })
    if not (tr.Fraction > 0.97 or (target ~= nil and tr.Entity == target)) then return false end
    return not (LC.SmokeBlocks and LC.SmokeBlocks(from, to))
end

-- Admins in build mode (!build): Sandbox's tools, and the editor.
function LC.IsBuilder(ply)
    return IsValid(ply) and ply:IsAdmin() and ply:GetNW2Bool("lc_build", false)
end

------------------------------------------------------------------------
-- Who is who
------------------------------------------------------------------------

function LC.PlayerIsCP(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return hook.Run("LivingCityIsCP", ply) == true
end

function LC.PlayerIsZombie(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return hook.Run("LivingCityIsZombie", ply) == true
end

------------------------------------------------------------------------
-- Wanted
------------------------------------------------------------------------

function LC.PlayerIsWanted(ply)
    if not IsValid(ply) then return false end
    if (ply.lcGraceUntil or 0) > CurTime() then return false end -- just released: a head start
    local override = hook.Run("LivingCityIsWanted", ply)
    if override ~= nil then return override == true end
    local w = LC.LocalWanted[ply]
    return w ~= nil and CurTime() < w.untilT
end

function LC.SetWanted(ply, seconds, reason)
    hook.Run("LivingCityWanted", ply, reason, seconds)
    LC.LocalWanted[ply] = { untilT = CurTime() + seconds, reason = reason }
    ply:SetNW2Float("lc_wanted_until", CurTime() + seconds)
    ply:SetNW2String("lc_wanted_reason", reason or "")
end

function LC.ClearWanted(ply)
    LC.LocalWanted[ply] = nil
    ply:SetNW2Float("lc_wanted_until", 0)
end

-- A crime happened. Returns true if it counted.
function LC.ReportCrime(ply, reason, seconds)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local handled = hook.Run("LivingCityCrime", ply, reason)
    if handled ~= nil then return handled == true end
    if LC.PlayerIsCP(ply) then return false end
    LC.SetWanted(ply, seconds or 180, reason)
    return true
end

function LC.PlayerMayUseCPDoor(ply, door)
    local override = hook.Run("LivingCityCanUseCPDoor", ply, door)
    if override ~= nil then return override == true end
    if LC.PowerOut and LC.PowerOut[door] then return true end -- the district's power is out: the lock's dead (sv_livingcity_power.lua)
    if LC.PlayerIsCP(ply) or ply:IsAdmin() then return true end
    -- someone in a stolen uniform: the door reads their biosignal
    return LC.DisguiseDoorCheck ~= nil and LC.DisguiseDoorCheck(ply, door) == true
end

-- The tag NPCs obey: the editor's, or the one a door earns by where it is.
function LC.EffectiveDoorTag(door)
    return LC.GetDoorTag(door) or (LC.AutoDoorTag and LC.AutoDoorTag(door)) or nil
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
hook.Add("PlayerDisconnected", "LivingCityWanted", function(ply) wasWanted[ply] = nil end)
