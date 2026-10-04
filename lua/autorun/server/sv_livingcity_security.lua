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
    if LC.FoolsSecurity and LC.FoolsSecurity(ply) then return true end
    if LC.PlayerIsZombie(ply) then return true end -- the infested don't read signs
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
