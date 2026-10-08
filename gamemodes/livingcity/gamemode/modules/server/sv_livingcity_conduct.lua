--[[
    Living City: conduct (anti-RDM and anti-combat-logging)

    Every time a player kills another player, the kill is judged. It counts as
    justified when:
      - the victim hurt the killer in the last 30 seconds (self defense)
      - the killer is Civil Protection / Overwatch and the victim was wanted,
        hunted, a zombie, or had hurt a unit recently
      - either side is a zombie (that's what zombies do, and what they're for)
      - both sides are openly at war (hunted Resistance vs Combine)
      - a server hook says so: LivingCityJudgeKill(attacker, victim) -> true/false

    Anything else earns a strike. Strikes expire after lc_strike_decay minutes.
      lc_rdm_strikes_jail strikes: prison (if the map has cells)
      lc_rdm_strikes_kick strikes: kicked
    Admins are told about every strike, with details, and everything is written
    to garrysmod/data/livingcity/conduct_log.txt.

    Combat logging: disconnecting while in a fight, wanted, being chased, or right
    after an unjustified kill is remembered (even across restarts). On return the
    player gets a strike and their wanted status back. Suicide is blocked while
    wanted, jailed, or mid-fight.

    Spawn protection: lc_spawn_protect seconds of immunity after spawning, which
    ends early if you attack someone.

    Chat: !report <message>    Admin: lc_conduct <name>, lc_pardon <name>
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvOn       = CreateConVar("lc_conduct", "1", FLAGS, "Judge player kills and track combat logging")
local cvJail     = CreateConVar("lc_rdm_strikes_jail", "2", FLAGS, "Strikes before an RDM sentence")
local cvKick     = CreateConVar("lc_rdm_strikes_kick", "4", FLAGS, "Strikes before a kick")
local cvDecay    = CreateConVar("lc_strike_decay", "120", FLAGS, "Minutes before a strike expires")
local cvProtect  = CreateConVar("lc_spawn_protect", "8", FLAGS, "Seconds of spawn protection (0 = off)")
local cvWindow   = CreateConVar("lc_combat_window", "30", FLAGS, "Seconds after a fight that you count as in combat")

local hurtBy = {}     -- [victim][attacker] = time attacker last hurt victim
local lastFight = {}  -- [ply] = time of last PvP damage dealt or taken
local lastRDM = {}    -- [ply] = time of their last unjustified kill

local function Admins()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if p:IsAdmin() then out[#out + 1] = p end end
    return out
end

local function TellAdmins(msg)
    for _, p in ipairs(Admins()) do p:ChatPrint("[Conduct] " .. msg) end
    print("[Conduct] " .. msg)
end

local function WriteLog(msg)
    file.CreateDir("livingcity")
    file.Append("livingcity/conduct_log.txt", os.date("%Y-%m-%d %H:%M:%S") .. "  " .. msg .. "\n")
    if LC.Log then LC.Log("info", "conduct: " .. msg) end
end

local function Who(ply)
    return string.format("%s (%s)", ply:Nick(), ply:SteamID())
end

------------------------------------------------------------------------
-- Strikes (stored by SteamID so they survive reconnects and restarts)
------------------------------------------------------------------------

local function LoadStrikes(ply)
    local raw = ply:GetPData("lc_strikes", "")
    local list = raw ~= "" and util.JSONToTable(raw) or {}
    local cutoff = os.time() - cvDecay:GetFloat() * 60
    local fresh = {}
    for _, s in ipairs(list or {}) do
        if (tonumber(s.t) or 0) > cutoff then fresh[#fresh + 1] = s end
    end
    return fresh
end

local function SaveStrikes(ply, list)
    ply:SetPData("lc_strikes", util.TableToJSON(list))
end

function LC.StrikeCount(ply) return #LoadStrikes(ply) end

function LC.ConductSummary(ply)
    return "strikes " .. LC.StrikeCount(ply)
end

function LC.AddStrike(ply, reason)
    local list = LoadStrikes(ply)
    list[#list + 1] = { t = os.time(), why = reason }
    SaveStrikes(ply, list)
    local n = #list
    WriteLog(string.format("STRIKE %d for %s: %s", n, Who(ply), reason))
    TellAdmins(string.format("%s received strike %d: %s", ply:Nick(), n, reason))
    ply:ChatPrint(string.format("[Conduct] Strike %d of %d: %s", n, cvKick:GetInt(), reason))
    hook.Run("LivingCityStrike", ply, n, reason)

    if n >= cvKick:GetInt() then
        WriteLog("KICK " .. Who(ply) .. " after " .. n .. " strikes")
        timer.Simple(1, function() if IsValid(ply) then ply:Kick("Repeated rule violations (random deathmatch / combat logging)") end end)
    elseif n >= cvJail:GetInt() and LC.Incarcerate and LC.PrisonAvailable and LC.PrisonAvailable() then
        LC.Incarcerate(ply, 300, "Conduct violation: " .. reason, nil)
    end
    return n
end

------------------------------------------------------------------------
-- Tracking fights, spawn protection
------------------------------------------------------------------------

hook.Add("PlayerSpawn", "LivingCityConductSpawn", function(ply)
    local secs = cvProtect:GetFloat()
    ply.lcProtectUntil = secs > 0 and CurTime() + secs or 0
    ply:SetNW2Float("lc_protect_until", ply.lcProtectUntil)
end)

hook.Add("EntityTakeDamage", "LivingCityConductDamage", function(victim, dmg)
    if not cvOn:GetBool() or not victim:IsPlayer() then return end
    local attacker = dmg:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
    local now = CurTime()

    -- attacking ends your own spawn protection
    if (attacker.lcProtectUntil or 0) > now then
        attacker.lcProtectUntil = 0
        attacker:SetNW2Float("lc_protect_until", 0)
    end
    if (victim.lcProtectUntil or 0) > now then
        dmg:SetDamage(0)
        return true
    end

    hurtBy[victim] = hurtBy[victim] or {}
    hurtBy[victim][attacker] = now
    lastFight[victim], lastFight[attacker] = now, now
end)

local function InCombat(ply)
    return (lastFight[ply] or -1e9) > CurTime() - cvWindow:GetFloat()
end
LC.InCombat = InCombat

local function BeingChased(ply)
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and st.state == "hostile" and st.enemy == ply then return true end
    end
    return false
end

------------------------------------------------------------------------
-- Judging kills
------------------------------------------------------------------------

local function IsHunted(ply)
    return LC.PlayerIsHunted and LC.PlayerIsHunted(ply) or false
end

local function HurtRecently(victim, by)
    local t = hurtBy[victim] and hurtBy[victim][by]
    return t ~= nil and t > CurTime() - 30
end

local function HurtAnyCPRecently(ply)
    for _, other in ipairs(player.GetAll()) do
        if other ~= ply and LC.PlayerIsCP(other) and HurtRecently(other, ply) then return true end
    end
    return false
end

function LC.JudgeKill(attacker, victim)
    local override = hook.Run("LivingCityJudgeKill", attacker, victim)
    if override ~= nil then return override == true, "server rule" end

    if HurtRecently(attacker, victim) then return true, "self defense" end
    if LC.PlayerIsZombie(attacker) or LC.PlayerIsZombie(victim) then return true, "infestation" end

    local attackerCP, victimCP = LC.PlayerIsCP(attacker), LC.PlayerIsCP(victim)
    if attackerCP and (LC.PlayerIsWanted(victim) or IsHunted(victim) or HurtAnyCPRecently(victim)) then
        return true, "enforcement"
    end
    if victimCP and IsHunted(attacker) then return true, "insurgency" end
    if attackerCP and victimCP then return false, "killed another unit" end

    return false, "no roleplay reason found"
end

hook.Add("PlayerDeath", "LivingCityConductDeath", function(victim, inflictor, attacker)
    if not cvOn:GetBool() then return end
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end

    local ok, why = LC.JudgeKill(attacker, victim)
    local weapon = IsValid(inflictor) and inflictor:GetClass() or "?"
    if IsValid(inflictor) and inflictor == attacker and IsValid(attacker:GetActiveWeapon()) then
        weapon = attacker:GetActiveWeapon():GetClass()
    end
    local dist = math.floor(attacker:GetPos():Distance(victim:GetPos()))
    WriteLog(string.format("KILL %s -> %s with %s at %du: %s (%s)",
        Who(attacker), Who(victim), weapon, dist, ok and "justified" or "UNJUSTIFIED", why))

    if not ok then
        lastRDM[attacker] = CurTime()
        LC.AddStrike(attacker, string.format("killed %s with no roleplay reason (%s, %du)", victim:Nick(), weapon, dist))
        victim:ChatPrint("[Conduct] That kill has been flagged for staff. C > Help > Ask staff for help if there's more to it.")
    end
end)

------------------------------------------------------------------------
-- Combat logging
------------------------------------------------------------------------

hook.Add("CanPlayerSuicide", "LivingCityConductSuicide", function(ply)
    if not cvOn:GetBool() then return end
    if LC.PlayerIsWanted(ply) or InCombat(ply) or (LC.Prisoners and LC.Prisoners[ply]) or BeingChased(ply) then
        ply:ChatPrint("[Conduct] You can't do that right now.")
        return false
    end
end)

-- Leaving isn't always running away: a server restart or a map change, a
-- crash or a dropped connection, or being kicked, don't count. Only someone
-- who chose to disconnect does ("Disconnect by user").
LC.ShuttingDown = LC.ShuttingDown or false
hook.Add("ShutDown", "LivingCityConductLeave", function() LC.ShuttingDown = true end)
if gameevent and gameevent.Listen then
    gameevent.Listen("player_disconnect")
    hook.Add("player_disconnect", "LivingCityConductLeave", function(data)
        local reason = string.lower(tostring(data and data.reason or ""))
        local sid = data and data.networkid
        if LC.ShuttingDown or (reason ~= "" and not string.find(reason, "by user", 1, true)) then
            -- not their choice: whatever was written down on the way out is struck off
            timer.Simple(0, function() if sid and util.RemovePData then util.RemovePData(sid, "lc_combatlog") end end)
        end
    end)
end

hook.Add("PlayerDisconnected", "LivingCityConductLeave", function(ply)
    if not cvOn:GetBool() or LC.ShuttingDown then return end
    local reasons = {}
    if InCombat(ply) then reasons[#reasons + 1] = "mid-fight" end
    if LC.PlayerIsWanted(ply) then reasons[#reasons + 1] = "wanted" end
    if BeingChased(ply) then reasons[#reasons + 1] = "being pursued" end
    if (lastRDM[ply] or -1e9) > CurTime() - 60 then reasons[#reasons + 1] = "right after an unjustified kill" end
    if #reasons == 0 then return end

    local wantedReason = ply:GetNW2String("lc_wanted_reason", "")
    ply:SetPData("lc_combatlog", util.TableToJSON({
        t = os.time(), why = table.concat(reasons, ", "), wanted = LC.PlayerIsWanted(ply), wantedReason = wantedReason,
    }))
    WriteLog(string.format("COMBAT LOG %s: %s", Who(ply), table.concat(reasons, ", ")))
    TellAdmins(string.format("%s disconnected %s. It'll be dealt with if they return.", ply:Nick(), table.concat(reasons, ", ")))
end)

hook.Add("PlayerInitialSpawn", "LivingCityConductReturn", function(ply)
    local raw = ply:GetPData("lc_combatlog", "")
    if raw == "" then return end
    ply:RemovePData("lc_combatlog")
    local rec = util.JSONToTable(raw)
    if not rec or (os.time() - (tonumber(rec.t) or 0)) > 86400 then return end
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        ply:ChatPrint("[Conduct] You left the server " .. tostring(rec.why) .. ". That counts against you.")
        LC.AddStrike(ply, "disconnected " .. tostring(rec.why))
        if rec.wanted then
            LC.ReportCrime(ply, rec.wantedReason ~= "" and rec.wantedReason or "Evading arrest", 300)
        end
    end)
end)

------------------------------------------------------------------------
-- Chat and admin commands
------------------------------------------------------------------------

local nextReport = {}
hook.Add("PlayerSay", "LivingCityConductChat", function(ply, text)
    local msg = string.match(text, "^!report%s+(.+)$")
    if not msg then return end
    if (nextReport[ply] or 0) > CurTime() then
        ply:ChatPrint("[Conduct] Please wait a moment before reporting again.")
        return ""
    end
    nextReport[ply] = CurTime() + 30
    WriteLog(string.format("REPORT from %s: %s", Who(ply), msg))
    TellAdmins(string.format("Report from %s: %s", ply:Nick(), msg))
    ply:ChatPrint("[Conduct] Sent to staff" .. (#Admins() == 0 and " (none online; it's been logged)." or "."))
    return ""
end)

concommand.Add("lc_conduct", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    local function out(m) if IsValid(ply) then ply:ChatPrint(m) else print(m) end end
    if not target then return out("Usage: lc_conduct <name>") end
    local list = LoadStrikes(target)
    out(string.format("%s has %d active strike(s).", target:Nick(), #list))
    for _, s in ipairs(list) do out("  " .. os.date("%H:%M", s.t) .. "  " .. tostring(s.why)) end
end)

-- Wipe someone's strikes (the admin tools' "Clear conduct strikes", lc_pardon).
function LC.PardonStrikes(target)
    if not IsValid(target) then return false end
    SaveStrikes(target, {})
    target:RemovePData("lc_combatlog")
    return true
end

concommand.Add("lc_pardon", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local target = LC.FindPlayer(args[1])
    if not target then return end
    SaveStrikes(target, {})
    WriteLog("PARDON " .. Who(target) .. " by " .. (IsValid(ply) and Who(ply) or "console"))
    target:ChatPrint("[Conduct] Your strikes have been cleared.")
end)

hook.Add("PlayerDisconnected", "LivingCityConductCleanup", function(ply)
    timer.Simple(0, function()
        hurtBy[ply], lastFight[ply], lastRDM[ply], nextReport[ply] = nil, nil, nil, nil
        for _, t in pairs(hurtBy) do t[ply] = nil end
    end)
end)
