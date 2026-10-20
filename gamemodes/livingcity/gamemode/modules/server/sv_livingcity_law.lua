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

-- Violent: hurt someone (a person, one of the city's people, a unit) in the last two minutes,
-- wanted for something violent, at a sector-wide search or higher, or with a gun in hand.
-- Units shoot at the violent; anyone else wanted they run down and cuff (sv_livingcity.lua).
local GUNS = { weapon_pistol = true, weapon_357 = true, weapon_smg1 = true, weapon_ar2 = true, weapon_shotgun = true,
    weapon_crossbow = true, weapon_rpg = true, weapon_annabelle = true }
LC.ViolentGuns = GUNS
local VIOLENT_WORDS = { "assault", "murder", "kill", "attack", "shoot", "armed", "violen", "weapon", "bomb" }
function LC.Violent(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    if (ply.lcViolentUntil or 0) > CurTime() then return true end
    if LC.AlertLevel and LC.AlertLevel(ply) >= 2 then return true end
    if LC.PlayerIsHunted and LC.PlayerIsHunted(ply) then return true end -- (hunted on sight: Father Grigori, a stalker loose)
    local w = ply.GetActiveWeapon and ply:GetActiveWeapon()
    local cls = IsValid(w) and w.GetClass and w:GetClass()
    return cls ~= nil and GUNS[cls] == true
end
hook.Add("EntityTakeDamage", "LivingCityViolence", function(victim, dmg)
    local a = dmg:GetAttacker()
    if IsValid(a) and a:IsPlayer() and a ~= victim and IsValid(victim) and (victim:IsPlayer() or victim:IsNPC())
        and not (LC.IsMonster and LC.IsMonster(victim)) and dmg:GetDamage() > 0 then
        a.lcViolentUntil = CurTime() + 120
    end
end)

-- A crime happened. Returns true if it counted.
function LC.ReportCrime(ply, reason, seconds)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if LC.EndingSession and LC.EndingSession() then return false end -- (the city's ending: nobody's booked for anything now)
    local handled = hook.Run("LivingCityCrime", ply, reason)
    if handled ~= nil then return handled == true end
    if LC.PlayerIsCP(ply) then return false end
    local r = string.lower(tostring(reason or ""))
    for _, w in ipairs(VIOLENT_WORDS) do if string.find(r, w, 1, true) then ply.lcViolentUntil = CurTime() + 120 break end end
    LC.SetWanted(ply, seconds or 180, reason)
    ply:RemovePData("lc_new_face") -- (wanted again: now they know the new face too)
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
local cvLost = CreateConVar("lc_wanted_lost", "30", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Seconds out of every unit's sight before the units lose track of where a wanted person is (after that, only a unit who sees them comes for them)")

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
            -- they only know where you are while the hunt is hot: a unit sees you now, or one
            -- did in the last lc_wanted_lost seconds (or you've only just become wanted). Out of
            -- sight that long (lying low in rebel territory, slipping away), nobody knows where
            -- you've gone: step out and only a unit who actually sees you comes for you.
            if not wasWanted[ply] then ply.lcWantedSeen = now end
            if LC.SeenBySecurity and LC.SeenBySecurity(ply, 1500) then ply.lcWantedSeen = now end
            if now - (ply.lcWantedSeen or -1e9) <= cvLost:GetFloat() then
                -- the higher the alert, the wider the net
                local alert = LC.AlertLevel and LC.AlertLevel(ply) or 0
                LC.MakeCopsHostile(ply, ply:GetPos(), alert >= 3 and nil or (alert == 2 and 5000 or 1500))
            end
        elseif wasWanted[ply] then
            LC.CalmCops(ply)
        end
        wasWanted[ply] = wanted or nil
    end
end)
hook.Add("PlayerDisconnected", "LivingCityWanted", function(ply) wasWanted[ply] = nil end)
-- Have the units lost track of this wanted person? (Not with Overwatch hunting them: alert 3 and up.)
function LC.WantedLost(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not wasWanted[ply] then return false end
    if LC.AlertLevel and LC.AlertLevel(ply) >= 3 then return false end
    return CurTime() - (ply.lcWantedSeen or CurTime()) > cvLost:GetFloat()
end
