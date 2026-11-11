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
local cvOn       = CreateConVar("lc_response", "1", FLAGS, "Escalating response: armed Civil Protection units, Overwatch squads, lockdowns")
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
    LC.DrawPistol(npc, st)
end

-- A metrocop draws (and, the first time, is issued) a pistol; and puts it away.
function LC.DrawPistol(npc, st)
    if not IsValid(npc) then return end
    if not st.hasPistol then
        st.hasPistol = true
        -- (an SMG instead when the Combine are desperate: sv_livingcity_desperation.lua)
        st.sidearm = LC.DesperateSidearm and LC.DesperateSidearm(st) or "weapon_pistol"
        npc:Give(st.sidearm)
    end
    if npc.SelectWeapon then npc:SelectWeapon(st.sidearm or "weapon_pistol") end
end
function LC.HolsterPistol(npc, st)
    if IsValid(npc) and npc.SelectWeapon then npc:SelectWeapon("weapon_stunstick") end
end

-- Judgment waiver (sociostability red): every metrocop on the street has his
-- pistol out, not his stick, until it's lifted.
function LC.WaiverIn() return LC.Socio == "red" end

-- A firefight is no place for a stick (the owner, 11 November: in a raid on the Combine's ground "metrocops
-- were walking around ... holding arrest batons and doing nothing while soldiers and rebels were shooting").
-- A metrocop whose enemy is one of the Resistance's fighters or the infested, or who stands within
-- FIGHT_NEAR of a raid or a sweep under way, has his pistol out until it's over.
local FIGHT_NEAR = 2200
function LC.CopInFirefight(npc)
    local e = npc.GetEnemy and npc:GetEnemy()
    if IsValid(e) and e.IsNPC and e:IsNPC() then
        local es = LC.NPCs and LC.NPCs[e]
        if es and (es.role == "rebel" or es.role == "zombie") then return true end
    end
    local sk = LC.Skirmish
    if sk then
        for _, at in ipairs({ sk.target, sk.zone and (sk.zone.pos or sk.zone.center) }) do
            if at and at.DistToSqr and npc:GetPos():DistToSqr(at) < FIGHT_NEAR * FIGHT_NEAR then return true end
        end
    end
    return false
end

function LC.WaiverArmTick()
    local waiver = LC.WaiverIn()
    for npc, st in pairs(LC.NPCs or {}) do
        if st.role == "cop" and IsValid(npc) then
            local fight = LC.CopInFirefight(npc)
            if fight and not st.fightDrawn then
                st.fightDrawn = true
                LC.DrawPistol(npc, st)
            elseif not fight and st.fightDrawn then
                st.fightDrawn = nil
                if not waiver and not st.armed and st.state ~= "hostile" then LC.HolsterPistol(npc, st) end
            end
            if waiver and not st.waiverDrawn then
                st.waiverDrawn = true
                LC.DrawPistol(npc, st)
            elseif not waiver and st.waiverDrawn then
                st.waiverDrawn = nil
                -- (one still after somebody, or sent by an alarm, keeps it out)
                if not st.armed and not st.fightDrawn and st.state ~= "hostile" then LC.HolsterPistol(npc, st) end
            end
        end
    end
end
hook.Add("LivingCitySocioChanged", "LivingCityWaiverPistols", function() LC.WaiverArmTick() end)
timer.Create("LivingCityWaiverPistols", 3, 0, function()
    if not LC.Running then return end
    local ok, err = pcall(LC.WaiverArmTick)
    if not ok and LC.Log then LC.Log("error", "waiver pistols: " .. tostring(err)) end
end)

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
        ply:ChatPrint("[Overwatch] Alert 2: every Civil Protection unit in the sector has your description. They've drawn their weapons.")
        if LC.RadioNotice then LC.RadioNotice("cp", "Dispatch: all units, suspect " .. ply:Nick() .. " is armed and dangerous. Weapons free.") end
    elseif level == 3 then
        ply:ChatPrint("[Overwatch] Alert 3: Overwatch has been dispatched. Lethal force is authorized.")
        if LC.Announce then LC.Announce("response", "npc/overwatch/cityvoice/f_protectionresponse_1_spkr.wav",
            "Overwatch soldiers have been sent after " .. (ply.GetNW2String and ply:GetNW2String("lc_char", "") ~= "" and ply:GetNW2String("lc_char", "") or ply:Nick()) ..
            ", who is armed and dangerous. Lethal force is authorized. Keep clear.") end
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
    if LC.PlayerIsZombie(ply) then return end -- (the infested are shot on sight anyway, not hunted down as criminals)
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

-- Friendly fire and accidents happen: the first kill in a while is answered
-- lightly (a low alert, a short charge), and only a second one soon after gets
-- the full response.
local FIRST_WINDOW = 600
local function FirstOffense(ply)
    local now = CurTime()
    local keep = {}
    for _, t in ipairs(ply.lcKillTimes or {}) do if now - t < FIRST_WINDOW then keep[#keep + 1] = t end end
    local first = #keep == 0
    keep[#keep + 1] = now
    ply.lcKillTimes = keep
    return first
end

-- The Resistance don't kill the people they say they are fighting for: every
-- civilian killed costs a rank, and XP drops to the bottom of the rank you fall to.
function LC.DemoteForCivilianKill(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:GetNW2String("lcf_faction", "") ~= "resistance" then return false end
    local idx = ply:GetNW2Int("lcf_rank", 1)
    if idx <= 1 then return false end
    local f = LCF and LCF.Get("resistance")
    local ranks = f and f.ranks
    if not ranks or not ranks[idx - 1] then return false end
    ply:SetPData("lcf_xp_resistance", ranks[idx - 1].xp or 0)
    ply:ChatPrint("[Resistance] You killed one of the people you fight for.")
    LC.AddXP(ply, 0, "killed a civilian")
    return true
end

-- Blood on their hands (sv_livingcity_custody.lua: only a killer is made a stalker).
local function CountKill(ply) ply:SetPData("lc_killed", (tonumber(ply:GetPData("lc_killed", 0)) or 0) + 1) end
hook.Add("LivingCityNewCharacter", "LivingCityKillCount", function(ply) ply:RemovePData("lc_killed") end)
hook.Add("PlayerDeath", "LivingCityKillCount", function(victim, _, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and not LC.PlayerIsCP(attacker) and not LC.PlayerIsZombie(attacker) then CountKill(attacker) end
end)

hook.Add("OnNPCKilled", "LivingCityResponse", function(npc, attacker)
    local st = LC.NPCs and LC.NPCs[npc]
    if not st or st.test or not IsValid(attacker) or not attacker:IsPlayer() then return end
    if LC.PlayerIsZombie(attacker) then return end -- (what the infested kill is feeding, not murder)
    if (st.role == "cop" or st.role == "soldier" or st.role == "citizen") and not LC.PlayerIsCP(attacker) then CountKill(attacker) end
    if st.role == "cop" then
        local first = FirstOffense(attacker)
        LC.ReportCrime(attacker, "Murder of a Civil Protection officer", first and 180 or 600)
        LC.AddHeat(attacker, first and 3 or 4, "killed a Civil Protection unit")
    elseif st.role == "soldier" then
        local first = FirstOffense(attacker)
        LC.ReportCrime(attacker, "Murder of an Overwatch soldier", first and 240 or 600)
        LC.AddHeat(attacker, first and 3 or 5, "killed a soldier")
    elseif st.role == "scanner" then
        LC.ReportCrime(attacker, "Destroying city property", 180)
        LC.AddHeat(attacker, 1, "destroyed a scanner")
    elseif st.role == "citizen" and not LC.PlayerIsCP(attacker) then
        local first = FirstOffense(attacker)
        LC.ReportCrime(attacker, "Murder", first and 120 or 400)
        LC.AddHeat(attacker, first and 1 or 2, "killed a citizen")
        LC.DemoteForCivilianKill(attacker)
    end
end)

-- A player citizen killed by a Resistance member costs them the rank as well.
hook.Add("PlayerDeath", "LivingCityResponseCivilian", function(victim, _, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
    if victim:GetNW2String("lcf_faction", "citizen") == "citizen" then LC.DemoteForCivilianKill(attacker) end
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
                    if LC.StartLeaving then LC.StartLeaving(npc, st, false, "a response squad going back") end
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

------------------------------------------------------------------------
-- Response squads: an alarm (a data breach, a prison escape) brings a few
-- units running. They turn up out of sight, a walk away (not on top of you),
-- a few seconds after the alarm, armed, and come for whoever set it off.
-- When it's over they go back where they came from.
--   lc_squad 0/1, lc_squad_cops (2), lc_squad_soldiers (1),
--   lc_squad_delay (5 seconds)
------------------------------------------------------------------------

local cvSquad    = CreateConVar("lc_squad", "1", FLAGS, "Alarms (data breaches, prison escapes) send a small squad of Civil Protection units after whoever set them off")
local cvSqCops   = CreateConVar("lc_squad_cops", "2", FLAGS, "Armed metrocops in a response squad")
local cvSqSold   = CreateConVar("lc_squad_soldiers", "1", FLAGS, "Overwatch soldiers in a response squad")
local cvSqDelay  = CreateConVar("lc_squad_delay", "5", FLAGS, "Seconds after the alarm before the squad comes through the door")

LC.ResponseSquads = LC.ResponseSquads or {} -- [npc] = { untilT, target }

-- Somewhere they can come from: out of sight, a walk away, and a way through to the alarm.
local function AlarmSquadSpot(pos)
    local fallback
    for _ = 1, 40 do
        local p = LC.RandomWanderPos and LC.RandomWanderPos("cop", pos)
        if p then
            local d = p:Distance(pos)
            if d > 350 and d < 1800 and (not LC.NavReachable or LC.NavReachable(p, pos)) then
                if not (LC.IsSeen and LC.IsSeen(p + Vector(0, 0, 40))) then return p end
                fallback = fallback or p
            end
        end
    end
    return fallback
end
LC.AlarmSquadSpot = AlarmSquadSpot

-- extra: more soldiers than usual (the master terminal)
function LC.SendResponseSquad(target, pos, why, extra)
    if not cvSquad:GetBool() or not LC.Running or not LC.SpawnCop then return 0 end
    if not IsValid(target) or not target:IsPlayer() then return 0 end
    local spot = AlarmSquadSpot(pos or target:GetPos())
    if not spot then return 0 end
    local made = {}
    local function Ready(npc, st, gun)
        if not IsValid(npc) then return end
        if gun == "weapon_pistol" then LC.DrawPistol(npc, st) elseif gun and npc.Give then npc:Give(gun) end
        st.unmanaged = true -- (on top of the city's own numbers, not instead of them)
        st.armed = true
        LC.ResponseSquads[npc] = { untilT = CurTime() + 240, target = target }
        made[#made + 1] = npc
        if LC.MakeOneHostile then LC.MakeOneHostile(npc, st, target) end
    end
    local n = 0
    for i = 1, math.max(0, cvSqCops:GetInt()) do
        n = n + 1
        local npc, st = LC.SpawnCop(spot + Vector(math.cos(n) * 40, math.sin(n) * 40, 4))
        Ready(npc, st, "weapon_pistol")
    end
    for i = 1, math.max(0, cvSqSold:GetInt() + (extra or 0)) do
        n = n + 1
        local npc, st = LC.SpawnSoldier(spot + Vector(math.cos(n) * 40, math.sin(n) * 40, 4))
        Ready(npc, st, nil)
    end
    if #made > 0 then
        made[1]:EmitSound("npc/metropolice/vo/allunitsrespondcode3.wav", 80)
        hook.Run("LivingCityResponseSquad", target, made, why)
    end
    return #made
end

-- The alarm goes off; a few seconds later, they come through the door.
function LC.AlarmResponse(target, pos, why, extra)
    timer.Simple(math.max(0, cvSqDelay:GetFloat()), function()
        if IsValid(target) and target:Alive() and not (LC.InCustody and LC.InCustody(target)) then
            LC.SendResponseSquad(target, pos, why, extra)
        end
    end)
end

hook.Add("LivingCityDataBreach", "LivingCityResponseSquad", function(pos, ply, master)
    LC.AlarmResponse(ply, pos, master and "master terminal breach" or "data breach", master and 2 or 0) -- (the master terminal: two more soldiers)
end)
hook.Add("LivingCityEscaped", "LivingCityResponseSquad", function(ply) if IsValid(ply) then LC.AlarmResponse(ply, ply:GetPos(), "escape") end end)

-- When it's over (time's up, or the one they came for is caught, gone or no
-- longer wanted), they leave: out of sight, they're gone.
timer.Create("LivingCityResponseSquads", 10, 0, function()
    local now = CurTime()
    for npc, r in pairs(LC.ResponseSquads) do
        if not IsValid(npc) then
            LC.ResponseSquads[npc] = nil
        else
            local done = now > r.untilT or not IsValid(r.target) or (LC.InCustody and LC.InCustody(r.target))
                or (now > r.untilT - 180 and not LC.PlayerIsWanted(r.target))
            if done and not (LC.IsSeen and LC.IsSeen(npc:GetPos() + Vector(0, 0, 40))) then
                LC.ResponseSquads[npc] = nil
                npc:Remove()
            end
        end
    end
end)

