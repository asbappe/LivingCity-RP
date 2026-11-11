--[[
    Living City: the performance debugger (server side)

    The measuring is sh_livingcity_perfdebug.lua. This turns it on and off
    (staff: C > Help > Performance debugger, or lc_perfdebug in the console),
    adds what only the server knows (each player's ping, packet loss, what
    the gamemode sends them and what waits in their send queue; the city's
    NPC loop and repeating timers; the server's network settings), sends the
    figures every two seconds to staff with the window open, and saves the
    report to data/livingcity/perf/ when it stops (also on Save).

    It turns itself off after lc_perfdebug_minutes (default 30; 0 never),
    so a forgotten one doesn't keep timing every hook all night, and it is
    always off after a restart or map change.
]]

if CLIENT then return end

LC = LC or {}
local P = LC.PerfDebug
if not P then return end

util.AddNetworkString("lc_perfdebug")
util.AddNetworkString("lc_perfdebug_cmd")

local cvSpike = CreateConVar("lc_perfdebug_spike_ms", "60", FCVAR_ARCHIVE,
    "Performance debugger: a server frame this long (ms) or longer is kept as a hitch, with what ran in it")
local cvMinutes = CreateConVar("lc_perfdebug_minutes", "30", FCVAR_ARCHIVE,
    "Performance debugger: turns itself off (and saves its report) after this many minutes; 0 never")

P.DIR = "livingcity/perf"
P.FILES_KEPT = 30
P.SEND_EVERY = 2 -- seconds between figures sent to the window

local watchers = {} -- [ply] = true: has the window open
P.watchers = watchers

local function Allowed(ply) return not IsValid(ply) or ply:IsAdmin() or (LC.CanEdit and LC.CanEdit(ply)) end

local function Staff()
    local out = {}
    for _, p in ipairs(player.GetAll()) do if IsValid(p) and p:IsAdmin() then out[#out + 1] = p end end
    return out
end

local function Tell(text, kind)
    for _, p in ipairs(Staff()) do
        if LC.Notice then LC.Notice(p, kind or "info", "Performance debugger", text) end
    end
    if LC.Log then LC.Log("info", "Performance debugger: " .. text) end
end

local function Round(v, d) local m = 10 ^ (d or 0) return math.floor((v or 0) * m + 0.5) / m end

-- The window's figures: the shared ones and the server's own.
function P.ServerSnapshot()
    local snap = P.Snapshot(25)
    local secs = math.max(1, snap.secs or 1)
    snap.map = game.GetMap and game.GetMap() or "?"
    snap.playerCount = player.GetCount and player.GetCount() or #player.GetAll()
    snap.tickRate = engine.TickInterval and math.floor(1 / engine.TickInterval() + 0.5) or nil
    snap.netcfg = LC.NetSettings and LC.NetSettings() or nil
    local perf = LC.Perf
    if perf and (perf.samples or 0) > 0 then snap.npcLoop = { avg = Round(perf.total / perf.samples, 2), max = Round(perf.max, 2) } end
    local npcs = 0
    for npc in pairs(LC.NPCs or {}) do if IsValid(npc) then npcs = npcs + 1 end end
    snap.cityNPCs = npcs
    snap.players = {}
    local states = LC.Net and LC.Net.players or {}
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            local st = states[p]
            snap.players[#snap.players + 1] = {
                k = p:Nick(), ping = p.Ping and p:Ping() or 0, loss = Round(p.PacketLoss and p:PacketLoss() or 0, 1),
                kbs = Round((P.stats.toPlayer[p:SteamID()] or 0) / 1024 / secs, 2),
                queue = st and st.bytes or 0, loading = (st and st.loading) and "yes" or "no",
            }
        end
    end
    table.sort(snap.players, function(a, b) return (a.queue or 0) * 1000 + a.ping > (b.queue or 0) * 1000 + b.ping end)
    -- the city's repeating timers since the server started (sv_livingcity_perf.lua times them always)
    local ct = {}
    for id, t in pairs(LC.TimerPerf or {}) do
        ct[#ct + 1] = { k = id, n = t.calls, ms = Round(t.total * 1000, 1), avg = Round(t.total / math.max(1, t.calls) * 1000, 3), max = Round(t.max * 1000, 2) }
    end
    table.sort(ct, function(a, b) return a.ms > b.ms end)
    while #ct > 15 do table.remove(ct) end
    snap.cityTimers = ct
    snap.startedBy = P.startedBy
    snap.minutes = cvMinutes:GetInt()
    snap.left = (P.on and cvMinutes:GetInt() > 0 and P.startedAt) and math.max(0, math.floor(cvMinutes:GetInt() * 60 - (SysTime() - P.startedAt))) or nil
    snap.lastFile = P.lastFile
    return snap
end

-- Saved to data/livingcity/perf/perf_<date>_<time>.txt; the oldest go past 30.
function P.Save()
    if not (file and file.Write) then return nil end
    local snap = P.ServerSnapshot()
    local text = P.ReportText(snap)
    if snap.cityTimers and #snap.cityTimers > 0 then
        local L = { "", "The city's repeating timers since the server started:" }
        for _, t in ipairs(snap.cityTimers) do
            L[#L + 1] = string.format("  %s  |  total ms %s, runs %s, avg ms %s, worst ms %s", t.k, t.ms, t.n, t.avg, t.max)
        end
        text = text .. "\n" .. table.concat(L, "\n")
    end
    file.CreateDir(P.DIR)
    local name = P.DIR .. "/perf_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    file.Write(name, text)
    P.lastFile = "garrysmod/data/" .. name
    local old = file.Find(P.DIR .. "/perf_*.txt", "DATA") or {}
    table.sort(old)
    for i = 1, #old - P.FILES_KEPT do file.Delete(P.DIR .. "/" .. old[i]) end
    return P.lastFile, text
end

function P.TurnOn(who)
    P.spikeMs = math.max(5, cvSpike:GetFloat())
    if not P.Start() then return false end
    P.startedBy = IsValid(who) and who:Nick() or "the console"
    local m = cvMinutes:GetInt()
    Tell(P.startedBy .. " turned it on: the server times every hook, timer and net message" .. (m > 0 and (" for up to " .. m .. " minutes.") or " until it's turned off."))
    return true
end

function P.TurnOff(who, why)
    if not P.Stop() then return false end
    local path = P.Save()
    Tell((why or ((IsValid(who) and who:Nick() or "The console") .. " turned it off.")) .. (path and (" Report saved: " .. path) or ""))
    P.SendAll()
    return true
end

local function Send(ply, snap)
    if LC.SendCompressed then LC.SendCompressed("lc_perfdebug", snap, { ply }) end
end

function P.SendAll()
    if not next(watchers) then return end
    local snap = P.ServerSnapshot()
    for ply in pairs(watchers) do
        if IsValid(ply) then Send(ply, snap) else watchers[ply] = nil end
    end
end

local lastSend = 0
P.OnSecond = function(now)
    local m = cvMinutes:GetInt()
    if P.on and m > 0 and P.startedAt and SysTime() - P.startedAt >= m * 60 then
        P.TurnOff(nil, "It turned itself off after " .. m .. " minutes.")
        return
    end
    if now - lastSend >= P.SEND_EVERY then
        lastSend = now
        P.SendAll()
    end
end

cvars.AddChangeCallback("lc_perfdebug_spike_ms", function(_, _, new)
    P.spikeMs = math.max(5, tonumber(new) or 60)
end, "LivingCityPerfDebug")

function P.Command(ply, action, value)
    if not Allowed(ply) then return false end
    if action == "on" then return P.TurnOn(ply)
    elseif action == "off" then return P.TurnOff(ply)
    elseif action == "reset" then
        P.Reset()
        if P.on then P.startedAt = SysTime() end
        P.SendAll()
        return true
    elseif action == "save" then
        local path = P.Save()
        if path and IsValid(ply) and LC.Notice then LC.Notice(ply, "info", "Performance debugger", "Report saved: " .. path) end
        P.SendAll()
        return path ~= nil
    elseif action == "watch" then
        if IsValid(ply) then watchers[ply] = true Send(ply, P.ServerSnapshot()) end
        return true
    elseif action == "unwatch" then
        if IsValid(ply) then watchers[ply] = nil end
        return true
    elseif action == "spike" or action == "minutes" then
        local n = tonumber(value)
        if not n then return false end
        local name = action == "spike" and "lc_perfdebug_spike_ms" or "lc_perfdebug_minutes"
        n = action == "spike" and math.Clamp(math.floor(n), 5, 2000) or math.Clamp(math.floor(n), 0, 1440)
        RunConsoleCommand(name, tostring(n))
        if action == "spike" then P.spikeMs = n end
        if LC.RememberSetting then LC.RememberSetting(name, tostring(n)) end
        timer.Simple(0.1, P.SendAll)
        return true
    end
    return false
end

net.Receive("lc_perfdebug_cmd", function(_, ply)
    if not IsValid(ply) or not Allowed(ply) then return end
    P.Command(ply, net.ReadString(), net.ReadString())
end)

hook.Add("PlayerDisconnected", "LivingCityPerfDebug", function(ply) watchers[ply] = nil end)

-- lc_perfdebug [on | off | reset | save | report]: with nothing, says whether it's on.
concommand.Add("lc_perfdebug", function(ply, _, args)
    if not Allowed(ply) then return end
    local function Say(msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end
    local a = string.lower(args[1] or "")
    if a == "report" then
        local text = P.ReportText(P.ServerSnapshot())
        if IsValid(ply) then
            for line in string.gmatch(text, "[^\n]+") do ply:PrintMessage(HUD_PRINTCONSOLE, line) end
            Say("[Miscount] Performance report printed to your console.")
        else
            print(text)
        end
        return
    end
    if a == "on" or a == "off" or a == "reset" or a == "save" then
        local done = P.Command(ply, a)
        if a == "save" and P.lastFile then Say("[Miscount] Report saved: " .. P.lastFile) end
        if not done and (a == "on" or a == "off") then Say("[Miscount] The performance debugger is already " .. a .. ".") end
        return
    end
    Say("[Miscount] Performance debugger: " .. (P.on and ("on, started by " .. tostring(P.startedBy)) or "off")
        .. ". lc_perfdebug on | off | reset | save | report (or C > Help > Performance debugger).")
end)
