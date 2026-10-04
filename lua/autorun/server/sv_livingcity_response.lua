--[[
    Living City: escalation

    The city answers violence in proportion. Everyone has an alert level,
    built up by what they do and cooling off when no unit has seen them for
    a while:

      1  Wanted. Units nearby come for you, and arrest you if they can.
      2  Every unit in the sector has your description, and they draw their
         pistols. (Killing a unit gets you here straight away.)
      3  Overwatch dispatched: a soldier squad deploys out of sight and hunts
         you down, into rebel territory if need be. Lethal force: no more
         arrests.
      4  A second squad, and the city goes into lockdown.

    Being arrested or killed resets it. Lying low (out of sight of every unit
    for 45 seconds) cools it down, faster in rebel territory.

      assaulting a unit +1 (at most every few seconds)   killing a citizen +2
      killing a metrocop +4   killing a soldier +5   destroying a scanner +1
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_response", "1", FLAGS, "Escalating response: armed units, Overwatch squads, lockdowns")
local cvSoldiers = CreateConVar("lc_response_soldiers", "6", FLAGS, "Most Overwatch soldiers sent after one person")

local THRESHOLDS = { 1, 4, 8, 14 } -- heat needed for alert levels 1..4
local LEVEL_NAMES = { "Wanted", "Sector-wide search", "Overwatch response", "Lockdown" }
LC.ALERT_NAMES = LEVEL_NAMES

function LC.Heat(ply) return IsValid(ply) and ply.lcHeat or 0 end

function LC.AlertLevel(ply)
    local h = LC.Heat(ply)
    local lvl = 0
    for i, t in ipairs(THRESHOLDS) do if h >= t then lvl = i end end
    return lvl
end

local function Publish(ply) ply:SetNW2Int("lc_alert", LC.AlertLevel(ply)) end

local function Responders(ply)
    local out = {}
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.responder == ply then out[#out + 1] = npc end
    end
    return out
end
LC.Responders = Responders

------------------------------------------------------------------------
-- Arming and dispatching
------------------------------------------------------------------------

-- Metrocops carry stunsticks. At alert 2 and up, they draw pistols.
function LC.ArmForAlert(npc, st, target)
    if st.role ~= "cop" or st.armed or not IsValid(target) or not target:IsPlayer() then return end
    if LC.AlertLevel(target) < 2 then return end
    st.armed = true
    npc:Give("weapon_pistol")
    if npc.SelectWeapon then npc:SelectWeapon("weapon_pistol") end
end

-- Somewhere out of sight, a fair way from the target, for a squad to deploy.
local function SquadSpot(ply)
    local origin = ply:GetPos()
    local best
    for _ = 1, 40 do
        local pos = LC.RandomWanderPos("soldier")
        if not pos then break end
        local d = pos:Distance(origin)
        if d > 900 and d < 3500 and not LC.IsSeen(pos + Vector(0, 0, 50)) and LC.ClearSpot(pos) then return pos end
        if not best and d > 600 and not LC.IsSeen(pos + Vector(0, 0, 50)) then best = pos end
    end
    return best
end

function LC.DispatchSquad(ply, n)
    if not LC.Running or not LC.Spawners or not LC.Spawners.soldier then return 0 end
    n = math.min(n, cvSoldiers:GetInt() - #Responders(ply))
    if n <= 0 then return 0 end
    local spot = SquadSpot(ply)
    if not spot then return 0 end
    local made = 0
    for i = 1, n do
        local npc, st = LC.Spawners.soldier(spot + Vector(math.random(-70, 70), math.random(-70, 70), 4))
        if IsValid(npc) then
            st.unmanaged, st.responder, st.leaveAt, st.routeGroup = true, ply, nil, nil
            LC.MakeOneHostile(npc, st, ply)
            made = made + 1
        end
    end
    if made > 0 then
        LC.Log("info", string.format("Overwatch squad of %d dispatched after %s", made, ply:Nick()))
        hook.Run("LivingCitySquadDispatched", ply, made)
    end
    return made
end

local function Escalate(ply, level)
    local name = LEVEL_NAMES[level] or ("Alert " .. level)
    if level >= 2 then
        -- every unit in the sector, guns drawn
        LC.MakeCopsHostile(ply, ply:GetPos(), nil)
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and st.enemy == ply then LC.ArmForAlert(npc, st, ply) end
        end
    end
    if level == 2 then
        ply:ChatPrint("[Overwatch] Alert 2: every unit in the sector has your description. They've drawn their weapons.")
        if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: all units, suspect " .. ply:Nick() .. " is armed and dangerous. Weapons free.") end
    elseif level == 3 then
        ply:ChatPrint("[Overwatch] Alert 3: Overwatch has been dispatched. Lethal force is authorized.")
        if LC.Announce then LC.Announce("response", "npc/overwatch/cityvoice/f_protectionresponse_1_spkr.wav") end
        LC.DispatchSquad(ply, 2)
    elseif level >= 4 then
        ply:ChatPrint("[Overwatch] Alert 4: a second squad, and the sector is locked down.")
        LC.DispatchSquad(ply, 4)
        if LC.StartEvent and LC.Event ~= "lockdown" then LC.StartEvent("lockdown", 4) end
        -- the city's scanners all look for you
        if ply:GetName() == "" then ply:SetName("lc_suspect_" .. ply:EntIndex()) end
        for npc, st in pairs(LC.NPCs or {}) do
            if IsValid(npc) and st.role == "scanner" then
                npc:Fire("SetFollowTarget", ply:GetName())
                st.followEnt, st.nextFollow = ply, CurTime() + 120
            end
        end
    end
    hook.Run("LivingCityAlert", ply, level, name)
end

function LC.AddHeat(ply, n, why)
    if not cvOn:GetBool() or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if LC.PlayerIsCP(ply) or (LC.InCustody and LC.InCustody(ply)) then return end
    local before = LC.AlertLevel(ply)
    ply.lcHeat = math.min(30, LC.Heat(ply) + n)
    ply.lcHeatSeen = CurTime()
    Publish(ply)
    local after = LC.AlertLevel(ply)
    for lvl = before + 1, after do Escalate(ply, lvl) end
end

function LC.ResetHeat(ply)
    if not IsValid(ply) then return end
    ply.lcHeat = 0
    Publish(ply)
end

------------------------------------------------------------------------
-- What raises it
------------------------------------------------------------------------

hook.Add("EntityTakeDamage", "LivingCityResponse", function(victim, dmg)
    local st = LC.NPCs and LC.NPCs[victim]
    local attacker = dmg:GetAttacker()
    if not st or st.test or not (LC.IsSecurity(st) or st.role == "scanner") then return end
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if CurTime() < (attacker.lcNextAssaultHeat or 0) then return end
    attacker.lcNextAssaultHeat = CurTime() + 4
    LC.AddHeat(attacker, 1, "assault")
end)

hook.Add("OnNPCKilled", "LivingCityResponse", function(npc, attacker)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.test or not IsValid(attacker) or not attacker:IsPlayer() then return end
    if st.role == "cop" then
        LC.ReportCrime(attacker, "Murder of a Civil Protection officer", 600)
        LC.AddHeat(attacker, 4, "killed a unit")
    elseif st.role == "soldier" then
        LC.ReportCrime(attacker, "Murder of an Overwatch soldier", 600)
        LC.AddHeat(attacker, 5, "killed a soldier")
    elseif st.role == "scanner" then
        LC.ReportCrime(attacker, "Destroying city property", 180)
        LC.AddHeat(attacker, 1, "destroyed a scanner")
    elseif st.role == "citizen" and not LC.PlayerIsCP(attacker) then
        LC.ReportCrime(attacker, "Murder", 400)
        LC.AddHeat(attacker, 2, "killed a citizen")
    end
end)

-- Arrest or death: it's over.
hook.Add("LivingCityIncarcerated", "LivingCityResponse", function(target)
    if IsValid(target) and target:IsPlayer() then LC.ResetHeat(target) end
end)
hook.Add("PlayerDeath", "LivingCityResponse", function(ply) LC.ResetHeat(ply) end)

------------------------------------------------------------------------
-- Cooling off, and squads going home
------------------------------------------------------------------------

timer.Create("LivingCityResponse", 2, 0, function()
    local ok, err = pcall(function()
        local now = CurTime()
        for _, ply in ipairs(player.GetAll()) do
            local h = LC.Heat(ply)
            if h > 0 then
                if LC.SeenBySecurity and LC.SeenBySecurity(ply, 1500) then
                    ply.lcHeatSeen = now
                elseif now - (ply.lcHeatSeen or now) > 45 and now > (ply.lcHeatCool or 0) then
                    -- lying low; rebel territory cools you off twice as fast
                    local rebel = LC.InRebelZone and LC.InRebelZone(ply:GetPos())
                    ply.lcHeatCool = now + (rebel and 5 or 10)
                    local before = LC.AlertLevel(ply)
                    ply.lcHeat = math.max(0, h - 1)
                    Publish(ply)
                    if LC.AlertLevel(ply) < before then
                        ply:ChatPrint(LC.AlertLevel(ply) == 0 and "[Overwatch] The search for you has been called off."
                            or "[Overwatch] The search is winding down. Alert " .. LC.AlertLevel(ply) .. ".")
                    end
                end
            end
        end
        -- squads stand down when their target is caught, dead, gone, or cooled to below alert 3
        for npc, st in pairs(LC.NPCs or {}) do
            local target = st.responder
            if IsValid(npc) and target ~= nil and not st.withdrawing then
                local done = not IsValid(target) or not target:Alive() or LC.AlertLevel(target) < 3
                    or (LC.InCustody and LC.InCustody(target))
                if done then
                    st.withdrawing = true
                    st.responder = nil
                    if st.state == "hostile" then
                        npc:SetEnemy(NULL)
                        st.enemy = nil
                        LC.SetState(npc, st, "idle")
                    end
                    if LC.StartLeaving then LC.StartLeaving(npc, st, false) end
                elseif st.state ~= "hostile" then
                    LC.MakeOneHostile(npc, st, target) -- they don't give up
                end
            elseif IsValid(npc) and st.withdrawing and not LC.IsSeen(npc:GetPos() + Vector(0, 0, 50)) then
                npc:Remove() -- back to the Nexus
            end
        end
    end)
    if not ok then LC.Error("response", err) end
end)

concommand.Add("lc_setalert", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    local lvl = tonumber(args[2])
    if not target or not lvl then return end
    if lvl <= 0 then return LC.ResetHeat(target) end
    LC.AddHeat(target, math.max(0, (THRESHOLDS[math.min(lvl, #THRESHOLDS)] or 0) - LC.Heat(target)), "set by staff")
end)
