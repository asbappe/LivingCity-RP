--[[
    Living City: Combine-only areas

    A "Combine only" zone (editor: Zone > Combine only) marks the nexus, the
    offices, the armory and the prison. Citizens, NPC or player, keep out.
    A player who wanders in gets a countdown to leave (lc_trespass_grace
    seconds); stay, and they're wanted for trespassing. Civil Protection,
    Overwatch, admins, people in custody, and anyone in a convincing
    uniform may be inside.

    Doors by prison cells and inside these zones lock automatically (see
    sv_livingcity_doors.lua).
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvGrace = CreateConVar("lc_trespass_grace", "10", FLAGS, "Seconds a citizen has to leave a Combine-only zone before they're wanted")

local warned = {} -- [ply] = time they become wanted

local function MayEnter(ply)
    if not ply:Alive() then return true end
    if LC.PlayerIsCP(ply) or ply:IsAdmin() and ply:GetNW2Bool("lc_build", false) then return true end
    if LC.InCustody and LC.InCustody(ply) then return true end
    if LC.EscortCovers and LC.EscortCovers(ply) then return true end -- with a Civil Protection escort (sv_livingcity_escort.lua)
    if LC.FoolsSecurity and LC.FoolsSecurity(ply) then return true end
    if LC.PlayerIsZombie(ply) then return true end -- the infested don't read signs
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return true end -- (a stalker is kept there)
    return false
end

function LC.CombineZoneTick(now)
    for _, ply in ipairs(player.GetAll()) do
        local inside = LC.CombineZoneAt and LC.CombineZoneAt(ply:GetPos()) ~= nil
        if inside and not MayEnter(ply) then
            local deadline = warned[ply]
            if not deadline then
                deadline = now + cvGrace:GetFloat()
                warned[ply] = deadline
                ply:SetNW2Float("lc_trespass_until", deadline)
                ply:ChatPrint("[Civil Protection] This is a restricted area. Leave immediately.")
            elseif now > deadline then
                warned[ply] = nil
                ply:SetNW2Float("lc_trespass_until", 0)
                ply:ChatPrint("[Civil Protection] Trespassing in a restricted area. You are now wanted.")
                LC.ReportCrime(ply, "Trespassing in a Combine area", 240)
                if LC.MakeCopsHostile then LC.MakeCopsHostile(ply, ply:GetPos(), 1500) end
            end
        elseif warned[ply] then
            warned[ply] = nil
            ply:SetNW2Float("lc_trespass_until", 0)
        end
    end
end

timer.Create("LivingCityCombineZones", 1, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.CombineZoneTick, CurTime())
    if not ok and LC.Error then LC.Error("security", err) end
end)

hook.Add("PlayerDisconnected", "LivingCityCombineZones", function(ply) warned[ply] = nil end)
hook.Add("PlayerDeath", "LivingCityCombineZones", function(ply) warned[ply] = nil; ply:SetNW2Float("lc_trespass_until", 0) end)

------------------------------------------------------------------------
-- Stuck in a pit, behind a fence, in the map? !stuck puts you back on the street.
------------------------------------------------------------------------

local cvStuck = CreateConVar("lc_stuck_cooldown", "300", FLAGS, "Seconds between uses of !stuck")

function LC.Unstick(ply)
    if not IsValid(ply) or not ply:Alive() then return false, "Not now." end
    if LC.InCustody and LC.InCustody(ply) then return false, "Not while you're in custody." end
    if LC.PlayerIsWanted(ply) then return false, "Not while you're wanted." end
    if (ply.lcStuckNext or 0) > CurTime() then
        return false, string.format("You can use that again in %d seconds.", math.ceil(ply.lcStuckNext - CurTime()))
    end
    local here = ply:GetPos()
    local best, bd
    -- prefer street above where you are (out of the pit), then anywhere that isn't right here
    for pass = 1, 2 do
        for _, pos in ipairs(LC.NodePositions and LC.NodePositions("citizen") or {}) do
            local d = pos:DistToSqr(here)
            local ok = d > 200 * 200 and d < 4000 * 4000 and (pass == 2 or pos.z > here.z + 20)
            if ok and LC.CitizenSpotOK(pos) and (not bd or d < bd) then best, bd = pos, d end
        end
        if best then break end
    end
    best = best or (LC.SafeCitizenSpot and LC.SafeCitizenSpot())
    if not best then return false, "There's nowhere to put you. Ask an admin." end
    ply:SetPos(best + Vector(0, 0, 8))
    ply:SetLocalVelocity(Vector(0, 0, 0))
    ply.lcStuckNext = CurTime() + cvStuck:GetFloat()
    return true
end

local function StuckCommand(ply)
    local ok, why = LC.Unstick(ply)
    if ok then ply:ChatPrint("[Miscount] You pull yourself out and brush yourself off.")
    else ply:ChatPrint("[Miscount] " .. tostring(why)) end
end
concommand.Add("lc_stuck", function(ply) if IsValid(ply) then StuckCommand(ply) end end)
hook.Add("PlayerSay", "LivingCityStuck", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!stuck" then return end
    StuckCommand(ply)
    return ""
end)
