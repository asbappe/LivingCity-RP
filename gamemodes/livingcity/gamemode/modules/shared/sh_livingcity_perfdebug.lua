--[[
    Living City: the performance debugger (server and client)

    Off until staff turn it on (C > Help > Performance debugger, or
    lc_perfdebug on in the server console). It goes deeper than the lag
    monitor (which says, live, which kind of lag it is): it says what in the
    code is slow, and keeps it, so a bad evening can be looked at afterwards.
    While on, the server and the game of each staff member with its window
    open time:

      hooks         every hook function (the gamemode's and other addons'),
                    by event and name: calls, total, average, worst
      timers        the city's repeating timers (sv_livingcity_perf.lua), and
                    timers and timer.Simple started while it's on, by where
                    in the code they were started
      net in        each message received: how many, how many bytes, time in
                    its handler, messages nothing handles, and (server) who
                    sent them, with each sender's busiest second
      net out       each message sent: how many, bytes, to how many players
      networked     SetNW / SetNW2 values by name: calls, and how many
                    actually changed something (a change is sent to players)
      frames        each frame's length; a frame of lc_perfdebug_spike_ms or
                    more is a hitch, kept with what ran in it and how much of
                    it was Lua the debugger could see
      census        every 10 seconds: entities by class, Lua memory, so what
                    keeps growing (a leak) shows

    Turned off, every hook, the net handler and the setters are put back as
    they were; what was measured stays until Reset. The server side
    (sv_livingcity_perfdebug.lua) adds players, the send queue and saving the
    report; the window is cl_livingcity_perfdebug.lua.
]]

LC = LC or {}
local P = LC.PerfDebug or {}
LC.PerfDebug = P

P.SELF = "LivingCityPerfDebug"  -- (its own hooks: never timed)
P.SPIKES_KEPT = 30              -- hitches kept, the newest
P.HISTORY_KEPT = 180            -- census points kept (one each 10 s: half an hour)
P.CENSUS_EVERY = 10             -- seconds
P.FLOOD_MSGS = 60               -- messages a second from one player that count as a flood
P.FLOOD_BYTES = 32768           -- or bytes a second

function P.NewStats()
    return {
        t0 = SysTime(), hooks = {}, timers = {}, recv = {}, sent = {}, nw = {}, senders = {}, toPlayer = {},
        frames = { n = 0, total = 0, max = 0, buckets = { 0, 0, 0, 0 } },
        spikes = {}, spikeCount = 0, worstSpike = nil, history = {}, base = nil, last = nil,
        lua = 0, memPeak = 0, allocKB = 0, floods = {},
    }
end

P.stats = P.stats or P.NewStats()
P.on = P.on or false
P.spikeMs = P.spikeMs or 60

local function Short(src)
    return string.match(tostring(src or "?"), "([^/\\]+)$") or "?"
end

-- where in the code: file:line, `level` up from the caller
function P.Where(level)
    local info = debug and debug.getinfo and debug.getinfo((level or 2) + 1, "Sl")
    if not info then return "?" end
    return Short(info.short_src) .. ":" .. tostring(info.currentline or "?")
end

------------------------------------------------------------------------
-- Recording
------------------------------------------------------------------------

local frameItems, frameLua, depth = {}, 0, 0

local function Add(list, key, dt)
    local e = list[key]
    if not e then e = { n = 0, total = 0, max = 0 } list[key] = e end
    e.n, e.total = e.n + 1, e.total + dt
    if dt > e.max then e.max = dt end
    return e
end

-- dt seconds of `kind` (hook, timer, net) under `key`, and toward this frame
local function Note(listName, kind, key, dt)
    Add(P.stats[listName], key, dt)
    local k = kind .. ": " .. key
    frameItems[k] = (frameItems[k] or 0) + dt
    if depth <= 0 then frameLua = frameLua + dt end -- (only the outermost: a hook run inside a timer isn't counted twice)
end

local function Finish(listName, kind, key, t0, ...)
    depth = depth - 1
    Note(listName, kind, key, SysTime() - t0)
    return ...
end

-- The city's repeating timers are timed by sv_livingcity_perf.lua all the time; it passes them on.
function LC.PerfDebugNote(id, dt)
    if not P.on then return end
    Note("timers", "timer", tostring(id), dt)
end

------------------------------------------------------------------------
-- Hooks
------------------------------------------------------------------------

local wrapped = {} -- [event] = { [name] = { orig = fn, wrap = fn } }

local function HookTable()
    return (hook.GetTable and hook.GetTable()) or {}
end

local function Skip(name)
    if isstring(name) then return string.sub(name, 1, #P.SELF) == P.SELF end
    return not (IsValid and IsValid(name)) -- (an object that's gone: the hook library drops it itself)
end

local function HookKey(event, name)
    if isstring(name) then return tostring(event) .. " / " .. name end
    local c = (name and name.GetClass) and name:GetClass() or type(name)
    return tostring(event) .. " / (" .. tostring(c) .. ")"
end

-- ULib keeps a priority for each hook: put it back the same.
local function Priority(event, name)
    if not hook.GetULibTable then return nil end
    local t = hook.GetULibTable()[event]
    for pri, list in pairs(t or {}) do
        if type(list) == "table" and list[name] ~= nil then return pri end
    end
    return nil
end

function P.WrapHook(event, name, fn)
    local key = HookKey(event, name)
    return function(...)
        if not P.on then return fn(...) end
        depth = depth + 1
        local t0 = SysTime()
        return Finish("hooks", "hook", key, t0, fn(...))
    end
end

local function Remember(event, name, fn, w)
    wrapped[event] = wrapped[event] or {}
    wrapped[event][name] = { orig = fn, wrap = w }
end

local function WrapAllHooks(add)
    local todo = {}
    for event, list in pairs(HookTable()) do
        if type(list) == "table" then
            for name, fn in pairs(list) do
                if type(fn) == "function" and not Skip(name) and not (wrapped[event] and wrapped[event][name]) then
                    todo[#todo + 1] = { event, name, fn }
                end
            end
        end
    end
    for _, t in ipairs(todo) do -- (afterwards: not while going through the table)
        local w = P.WrapHook(t[1], t[2], t[3])
        Remember(t[1], t[2], t[3], w)
        add(t[1], t[2], w, Priority(t[1], t[2]))
    end
    return #todo
end

local function UnwrapAllHooks(add)
    local tbl, n = HookTable(), 0
    for event, list in pairs(wrapped) do
        for name, w in pairs(list) do
            -- (only where it's still ours: removed or replaced since, it's left as it is)
            if tbl[event] and tbl[event][name] == w.wrap then
                add(event, name, w.orig, Priority(event, name))
                n = n + 1
            end
        end
    end
    wrapped = {}
    return n
end

------------------------------------------------------------------------
-- Installing and taking out: each thing replaced is put back only if it's
-- still ours (something replaced after it stays, and ours just passes
-- everything through while off).
------------------------------------------------------------------------

local orig = {}   -- [name] = the original
local mine = {}   -- [name] = ours

local function Get(path)
    local t = _G
    for part in string.gmatch(path, "[^%.]+") do
        if type(t) ~= "table" then return nil end
        t = t[part]
    end
    return t
end
local function Set(path, v)
    local tbl, last = string.match(path, "^(.*)%.([^%.]+)$")
    local t = Get(tbl)
    if type(t) == "table" then t[last] = v end
end

local function Install(path, make)
    if mine[path] then return end
    local o = Get(path)
    if type(o) ~= "function" then return end
    orig[path] = o
    mine[path] = make(o)
    Set(path, mine[path])
end

local function Uninstall(path)
    if not mine[path] then return end
    if Get(path) == mine[path] then
        Set(path, orig[path])
        orig[path], mine[path] = nil, nil
    end
end

local current -- (the message being written)

-- a list of players, a player, a number of them, or a recipient filter
local function List(to)
    if to == nil or type(to) == "number" then return nil end
    if istable(to) and not to.SteamID then return to end
    if to.SteamID then return { to } end
    return nil
end

local function Recipients(to)
    if type(to) == "number" then return to end
    local list = List(to)
    if list then return #list end
    if type(to) == "userdata" and to.GetCount then return to:GetCount() end
    return 1
end

local function CountSend(to)
    if not P.on or not current or current == "lc_perfdebug" then return end -- (it doesn't count itself)
    local n = Recipients(to)
    local b = net.BytesWritten and net.BytesWritten() or 0
    local s = P.stats
    local e = s.sent[current]
    if not e then e = { n = 0, bytes = 0, to = 0 } s.sent[current] = e end
    e.n, e.bytes, e.to = e.n + 1, e.bytes + b * n, e.to + n
    if SERVER then
        for _, p in ipairs(List(to) or {}) do
            if IsValid(p) and p.SteamID then
                local id = p:SteamID()
                s.toPlayer[id] = (s.toPlayer[id] or 0) + b
            end
        end
    end
end

-- what came in, by message, and who sent it
local secBy = {} -- [steamid] = { n, bytes, nick } this second

function P.Incoming(len, client)
    local id = net.ReadHeader()
    local name = util.NetworkIDToString(id)
    if not name then return end
    local fn = net.Receivers[string.lower(name)]
    if not P.on then
        if fn then fn((len or 0) - 16, client) end
        return
    end
    local bytes = math.ceil((len or 0) / 8)
    local s = P.stats
    local e = s.recv[name]
    if not e then e = { n = 0, total = 0, max = 0, bytes = 0, unhandled = 0 } s.recv[name] = e end
    e.bytes = e.bytes + bytes
    if SERVER and IsValid(client) and client.SteamID then
        local sid = client:SteamID()
        local c = secBy[sid]
        if not c then c = { n = 0, bytes = 0 } secBy[sid] = c end
        c.n, c.bytes, c.nick = c.n + 1, c.bytes + bytes, client:Nick()
        local t = s.senders[sid]
        if not t then t = { n = 0, bytes = 0, peakN = 0, peakBytes = 0, top = {} } s.senders[sid] = t end
        t.n, t.bytes, t.nick = t.n + 1, t.bytes + bytes, client:Nick()
        t.top[name] = (t.top[name] or 0) + 1
    end
    if not fn then
        e.n, e.unhandled = e.n + 1, e.unhandled + 1
        return
    end
    depth = depth + 1
    local t0 = SysTime()
    fn((len or 0) - 16, client)
    depth = depth - 1
    local dt = SysTime() - t0
    e.n, e.total = e.n + 1, e.total + dt
    if dt > e.max then e.max = dt end
    local k = "net: " .. name
    frameItems[k] = (frameItems[k] or 0) + dt
    if depth <= 0 then frameLua = frameLua + dt end
end

local NW_KINDS = { "Bool", "Int", "Float", "String", "Entity", "Vector", "Angle", "Var" }

local function InstallAll()
    -- hooks added while it's on are timed too
    Install("hook.Add", function(o)
        return function(event, name, fn, ...)
            if P.on and type(fn) == "function" and name ~= nil and not Skip(name) then
                local w = P.WrapHook(event, name, fn)
                Remember(event, name, fn, w)
                return o(event, name, w, ...)
            end
            return o(event, name, fn, ...)
        end
    end)
    WrapAllHooks(orig["hook.Add"] or hook.Add)

    -- timers started while it's on, by where they were started
    Install("timer.Simple", function(o)
        return function(delay, fn, ...)
            if P.on and type(fn) == "function" then
                local where = P.Where(2)
                -- (the city's staggered timers go through timer.Simple and are timed already)
                if not string.find(where, "sv_livingcity_perf", 1, true) then
                    local inner = fn
                    fn = function(...)
                        if not P.on then return inner(...) end
                        depth = depth + 1
                        local t0 = SysTime()
                        return Finish("timers", "timer.Simple", where, t0, inner(...))
                    end
                end
            end
            return o(delay, fn, ...)
        end
    end)
    Install("timer.Create", function(o)
        return function(id, delay, reps, fn, ...)
            local timed = SERVER and isstring(id) and string.sub(id, 1, 10) == "LivingCity" and reps == 0
            if P.on and type(fn) == "function" and not timed then
                local key = tostring(id) .. " (" .. P.Where(2) .. ")"
                local inner = fn
                fn = function(...)
                    if not P.on then return inner(...) end
                    depth = depth + 1
                    local t0 = SysTime()
                    return Finish("timers", "timer", key, t0, inner(...))
                end
            end
            return o(id, delay, reps, fn, ...)
        end
    end)

    -- messages in: our copy of the engine's handler, timed
    if net and net.Incoming and net.ReadHeader and net.Receivers and util and util.NetworkIDToString then
        Install("net.Incoming", function() return P.Incoming end)
    end

    -- messages out
    Install("net.Start", function(o) return function(name, ...) current = name return o(name, ...) end end)
    for _, fname in ipairs({ "Send", "SendOmit", "SendPVS", "SendPAS" }) do
        Install("net." .. fname, function(o)
            return function(to, ...)
                if fname == "Send" then CountSend(to)
                elseif fname == "SendOmit" then CountSend(math.max(1, (player.GetCount and player.GetCount() or 1) - 1))
                else CountSend(nil) end
                return o(to, ...)
            end
        end)
    end
    Install("net.Broadcast", function(o)
        return function(...)
            CountSend(player.GetAll and player.GetAll() or nil)
            return o(...)
        end
    end)
    Install("net.SendToServer", function(o) return function(...) CountSend(nil) return o(...) end end)

    -- networked values: calls, and the ones that changed something
    local EM = FindMetaTable and FindMetaTable("Entity")
    if EM then
        for _, two in ipairs({ "", "2" }) do
            for _, kind in ipairs(NW_KINDS) do
                local setName, getName = "SetNW" .. two .. kind, "GetNW" .. two .. kind
                local get = EM[getName]
                if EM[setName] and get and not mine["Entity." .. setName] then
                    local label = "NW" .. two .. " "
                    local o = EM[setName]
                    orig["Entity." .. setName] = o
                    mine["Entity." .. setName] = function(self, key, value, ...)
                        if P.on then
                            local k = label .. tostring(key)
                            local e = P.stats.nw[k]
                            if not e then e = { calls = 0, changes = 0 } P.stats.nw[k] = e end
                            e.calls = e.calls + 1
                            local okG, old = LC.Try(get, self, key)
                            if not okG or old ~= value then e.changes = e.changes + 1 end
                        end
                        return o(self, key, value, ...)
                    end
                    EM[setName] = mine["Entity." .. setName]
                end
            end
        end
    end
end

local function UninstallAll()
    local EM = FindMetaTable and FindMetaTable("Entity")
    for path, fn in pairs(mine) do
        local m = string.match(path, "^Entity%.(.+)$")
        if m then
            if EM and EM[m] == fn then EM[m] = orig[path] mine[path], orig[path] = nil, nil end
        end
    end
    UnwrapAllHooks(orig["hook.Add"] or hook.Add)
    for path in pairs(mine) do
        if not string.match(path, "^Entity%.") then Uninstall(path) end
    end
end

------------------------------------------------------------------------
-- Frames, hitches, each second, the census
------------------------------------------------------------------------

local function Round(v, d) local m = 10 ^ (d or 0) return math.floor((v or 0) * m + 0.5) / m end

local function TopOf(t, n)
    local list = {}
    for k, v in pairs(t) do list[#list + 1] = { k = k, v = v } end
    table.sort(list, function(a, b) return a.v > b.v end)
    local out = {}
    for i = 1, math.min(n, #list) do out[i] = { k = list[i].k, ms = Round(list[i].v * 1000, 2) } end
    return out
end

-- the length one frame should be (ms)
function P.FrameBase()
    if SERVER then return (engine.TickInterval and engine.TickInterval() or 0.015) * 1000 end
    return 1000 / 60
end

function P.Census()
    local s = P.stats
    local by, all, npcs = {}, ents.GetAll(), 0
    for _, e in ipairs(all) do
        if IsValid(e) then
            local c = e:GetClass()
            by[c] = (by[c] or 0) + 1
            if e.IsNPC and e:IsNPC() then npcs = npcs + 1 end
        end
    end
    local mem = collectgarbage("count")
    local point = {
        t = Round(SysTime() - s.t0), ents = #all, npcs = npcs, mem = Round(mem),
        edicts = SERVER and ents.GetEdictCount and ents.GetEdictCount() or nil,
        players = player.GetCount and player.GetCount() or 0,
    }
    if not s.base then s.base = by end
    s.last = by
    s.history[#s.history + 1] = point
    while #s.history > P.HISTORY_KEPT do table.remove(s.history, 1) end
    return point
end

local lastFrame, lastSecond, lastCensus, lastMem

local function EverySecond(now)
    local s = P.stats
    -- each sender's busiest second, and floods
    for sid, c in pairs(secBy) do
        local t = s.senders[sid]
        if t then
            if c.n > t.peakN then t.peakN = c.n end
            if c.bytes > t.peakBytes then t.peakBytes = c.bytes end
        end
        if c.n >= P.FLOOD_MSGS or c.bytes >= P.FLOOD_BYTES then
            s.floods[#s.floods + 1] = { at = os.date("%H:%M:%S"), who = c.nick or sid, sid = sid, n = c.n, bytes = c.bytes }
            while #s.floods > 20 do table.remove(s.floods, 1) end
        end
    end
    secBy = {}
    -- Lua memory: what was taken since the last second (what the garbage collector freed in between isn't seen)
    local mem = collectgarbage("count")
    if lastMem and mem > lastMem then s.allocKB = s.allocKB + (mem - lastMem) end
    lastMem = mem
    if mem > s.memPeak then s.memPeak = mem end
    if not lastCensus or now - lastCensus >= P.CENSUS_EVERY then
        lastCensus = now
        P.Census()
    end
    if P.OnSecond then P.OnSecond(now) end
end

-- Once a frame (the Think hook below; tests pass `now`).
function P.Frame(now)
    now = now or SysTime()
    depth = 0 -- (a handler that errored never came back down)
    if not P.on then
        lastFrame, lastSecond, lastMem = nil, nil, nil
        frameItems, frameLua = {}, 0
        return
    end
    local s = P.stats
    if lastFrame then
        local ms = (now - lastFrame) * 1000
        local f = s.frames
        f.n, f.total = f.n + 1, f.total + ms
        if ms > f.max then f.max = ms end
        local base = P.FrameBase()
        local b = ms < base * 1.5 and 1 or ms < base * 3 and 2 or ms < base * 6 and 3 or 4
        f.buckets[b] = f.buckets[b] + 1
        if ms >= P.spikeMs then
            local spike = {
                at = os.date("%H:%M:%S"), ms = Round(ms, 1), lua = Round(frameLua * 1000, 1), top = TopOf(frameItems, 6),
                players = player.GetCount and player.GetCount() or 0,
            }
            s.spikes[#s.spikes + 1] = spike
            while #s.spikes > P.SPIKES_KEPT do table.remove(s.spikes, 1) end
            s.spikeCount = s.spikeCount + 1
            if not s.worstSpike or spike.ms > s.worstSpike.ms then s.worstSpike = spike end
            if P.OnSpike then P.OnSpike(spike) end
        end
    end
    s.lua = s.lua + frameLua
    lastFrame = now
    frameItems, frameLua = {}, 0
    if not lastSecond then lastSecond = now end
    if now - lastSecond >= 1 then
        lastSecond = now
        EverySecond(now)
    end
end

hook.Add("Think", P.SELF, function() P.Frame() end)

------------------------------------------------------------------------
-- On, off, reset
------------------------------------------------------------------------

function P.Start()
    if P.on then return false end
    P.Reset() -- (each start measures afresh)
    P.on = true
    P.startedAt = SysTime()
    InstallAll()
    return true
end

function P.Stop()
    if not P.on then return false end
    P.on = false
    UninstallAll()
    P.stats.stoppedAt = SysTime()
    return true
end

function P.Reset()
    P.stats = P.NewStats()
    frameItems, frameLua, secBy = {}, 0, {}
    lastFrame, lastSecond, lastCensus, lastMem = nil, nil, nil, nil
end

function P.Installed() return next(mine) ~= nil end
function P.WrappedHookCount()
    local n = 0
    for _, list in pairs(wrapped) do for _ in pairs(list) do n = n + 1 end end
    return n
end

------------------------------------------------------------------------
-- What it found: a plain table (sent to the window) and a text report
------------------------------------------------------------------------

local function Elapsed(s)
    return math.max(0.001, (P.on and SysTime() or (s.stoppedAt or SysTime())) - s.t0)
end

local function Timed(list, n, secs)
    local out = {}
    for k, e in pairs(list) do
        out[#out + 1] = {
            k = k, n = e.n, ms = Round(e.total * 1000, 1), avg = Round(e.total / math.max(1, e.n) * 1000, 3),
            max = Round(e.max * 1000, 2), pct = Round(e.total / secs * 100, 2), bytes = e.bytes, unhandled = e.unhandled,
        }
    end
    table.sort(out, function(a, b) return a.ms > b.ms end)
    while #out > n do table.remove(out) end
    return out
end

function P.Growth(s)
    local out = {}
    if not (s.base and s.last) then return out end
    for c, now in pairs(s.last) do
        local was = s.base[c] or 0
        if now - was > 0 then out[#out + 1] = { k = c, from = was, to = now, diff = now - was } end
    end
    table.sort(out, function(a, b) return a.diff > b.diff end)
    while #out > 12 do table.remove(out) end
    return out
end

function P.Snapshot(limit)
    local s, n = P.stats, limit or 25
    local secs = Elapsed(s)
    local f = s.frames
    local recv = Timed(s.recv, n, secs)
    for _, r in ipairs(recv) do r.kbs = Round((r.bytes or 0) / 1024 / secs, 2) end
    -- (net in by bytes as well as by time: a big message can be cheap to handle)
    local sent = {}
    for k, e in pairs(s.sent) do sent[#sent + 1] = { k = k, n = e.n, bytes = e.bytes, to = e.to, kbs = Round(e.bytes / 1024 / secs, 2) } end
    table.sort(sent, function(a, b) return a.bytes > b.bytes end)
    while #sent > n do table.remove(sent) end
    local nw = {}
    for k, e in pairs(s.nw) do nw[#nw + 1] = { k = k, calls = e.calls, changes = e.changes, cps = Round(e.changes / secs, 1) } end
    table.sort(nw, function(a, b) return a.calls > b.calls end)
    while #nw > n do table.remove(nw) end
    local senders = {}
    for sid, t in pairs(s.senders) do
        local top, topN = nil, 0
        for m, c in pairs(t.top) do if c > topN then top, topN = m, c end end
        senders[#senders + 1] = { k = t.nick or sid, sid = sid, n = t.n, bytes = t.bytes, peakN = t.peakN, peakBytes = t.peakBytes, top = top }
    end
    table.sort(senders, function(a, b) return a.bytes > b.bytes end)
    while #senders > n do table.remove(senders) end
    local hist = {}
    for i = math.max(1, #s.history - 59), #s.history do hist[#hist + 1] = s.history[i] end
    return {
        side = SERVER and "server" or "client", on = P.on, secs = Round(secs), spikeMs = P.spikeMs,
        frames = { n = f.n, avg = Round(f.total / math.max(1, f.n), 2), max = Round(f.max, 1), buckets = f.buckets, base = Round(P.FrameBase(), 2) },
        luaPct = Round(s.lua / secs * 100, 1),
        hooks = Timed(s.hooks, n, secs), timers = Timed(s.timers, n, secs), recv = recv, sent = sent, nw = nw, senders = senders,
        spikes = s.spikes, spikeCount = s.spikeCount, worstSpike = s.worstSpike, floods = s.floods,
        history = hist, growth = P.Growth(s), mem = Round(collectgarbage("count")), memPeak = Round(s.memPeak),
        allocKBs = Round(s.allocKB / secs, 1), hooksWrapped = P.WrappedHookCount(),
    }
end

-- What stands out, in plain words, worst first.
function P.Findings(snap)
    local out = {}
    local function F(text) out[#out + 1] = text end
    local f = snap.frames or {}
    local slow = (f.buckets and (f.buckets[3] + f.buckets[4])) or 0
    if (f.n or 0) > 0 and slow / f.n > 0.01 then
        F(string.format("%.1f%% of frames took over three times as long as they should (%.0f ms); the worst %.0f ms.", slow / f.n * 100, (f.base or 15) * 3, f.max or 0))
    end
    -- what hitches had in common
    local spikes = snap.spikes or {}
    if #spikes > 0 then
        local count, outside = {}, 0
        for _, sp in ipairs(spikes) do
            if sp.top[1] then count[sp.top[1].k] = (count[sp.top[1].k] or 0) + 1 end
            if (sp.lua or 0) < sp.ms * 0.3 then outside = outside + 1 end
        end
        local best, bestN = nil, 0
        for k, c in pairs(count) do if c > bestN then best, bestN = k, c end end
        if best and bestN >= math.max(2, #spikes * 0.3) then
            F(string.format("%d of the last %d hitches were mostly %s.", bestN, #spikes, best))
        end
        if outside >= math.max(2, #spikes * 0.5) then
            F(string.format("%d of the last %d hitches were mostly outside the Lua it can see: the engine (physics, many entities moving or colliding), map I/O or another addon's code outside a hook.", outside, #spikes))
        end
    end
    local h = snap.hooks and snap.hooks[1]
    if h and h.pct >= 5 then F(string.format("The costliest hook, %s, takes %.1f%% of all time (%.2f ms average, %.1f ms at worst).", h.k, h.pct, h.avg, h.max)) end
    local t = snap.timers and snap.timers[1]
    if t and t.pct >= 3 then F(string.format("The costliest timer, %s, takes %.1f%% of all time (worst %.1f ms).", t.k, t.pct, t.max)) end
    for _, r in ipairs(snap.recv or {}) do
        if (r.unhandled or 0) > 0 then F(string.format("%d %s messages came in with nothing to handle them (an addon removed, or someone sending junk).", r.unhandled, r.k)) break end
    end
    local r = snap.recv and snap.recv[1]
    if r and r.max >= 20 then F(string.format("Handling the message %s took %.0f ms at worst.", r.k, r.max)) end
    local so = snap.sent and snap.sent[1]
    if so and so.kbs >= 16 then F(string.format("The biggest send, %s, is %.1f KB a second (%d sends to %d players in all).", so.k, so.kbs, so.n, so.to)) end
    for _, fl in ipairs(snap.floods or {}) do
        F(string.format("%s sent %d messages (%.1f KB) in one second at %s.", fl.who, fl.n, fl.bytes / 1024, fl.at))
        break
    end
    for _, v in ipairs(snap.nw or {}) do
        if v.calls >= 1000 and v.changes < v.calls * 0.1 then
            F(string.format("%s was set %d times and changed only %d: calls that could be skipped.", v.k, v.calls, v.changes))
            break
        end
    end
    for _, v in ipairs(snap.nw or {}) do
        if (v.cps or 0) >= 50 then F(string.format("%s changes %.0f times a second, each sent to players.", v.k, v.cps)) break end
    end
    local g = snap.growth and snap.growth[1]
    if g and g.diff >= 50 and g.to >= g.from * 1.5 then F(string.format("%s keeps growing: %d at the start, %d now (a leak?).", g.k, g.from, g.to)) end
    local hist = snap.history or {}
    if #hist >= 6 then
        local a, b = hist[1], hist[#hist]
        if b.mem > a.mem * 1.5 and b.mem - a.mem > 50000 then F(string.format("Lua memory went from %.0f MB to %.0f MB.", a.mem / 1024, b.mem / 1024)) end
        if b.edicts and b.edicts > 7000 then F(string.format("%d edicts in use of the engine's 8176: near the limit (the server crashes past it).", b.edicts)) end
    end
    if snap.allocKBs and snap.allocKBs > 20000 then F(string.format("Lua takes %.0f MB of memory a second (garbage to collect: small hitches).", snap.allocKBs / 1024)) end
    if snap.players then
        for _, p in ipairs(snap.players) do
            if (p.queue or 0) > 65536 then F(string.format("%.0f KB waiting to be sent to %s (more than they can be sent).", p.queue / 1024, p.k)) break end
        end
    end
    if #out == 0 then F("Nothing stands out.") end
    return out
end

local function Table(lines, title, rows, cols)
    lines[#lines + 1] = ""
    lines[#lines + 1] = title
    if #rows == 0 then lines[#lines + 1] = "  (nothing)" return end
    for _, r in ipairs(rows) do
        local parts = {}
        for _, c in ipairs(cols) do
            local v = r[c[1]]
            parts[#parts + 1] = c[2] .. " " .. (type(v) == "number" and tostring(v) or tostring(v or "-"))
        end
        lines[#lines + 1] = "  " .. tostring(r.k) .. "  |  " .. table.concat(parts, ", ")
    end
end

function P.ReportText(snap)
    local L = {}
    L[#L + 1] = string.format("Miscount performance report (%s), %s", snap.side or "?", os.date("%Y-%m-%d %H:%M:%S"))
    L[#L + 1] = string.format("Measured for %d s%s. %d hooks timed. Hitch = a frame of %d ms or more.", snap.secs or 0, snap.on and " (still on)" or "", snap.hooksWrapped or 0, snap.spikeMs or 0)
    if snap.map then L[#L + 1] = "Map " .. snap.map .. ", " .. tostring(snap.playerCount or 0) .. " players, tick rate " .. tostring(snap.tickRate or "?") end
    L[#L + 1] = ""
    L[#L + 1] = "What stands out:"
    for _, line in ipairs(P.Findings(snap)) do L[#L + 1] = "  - " .. line end
    local f = snap.frames or {}
    local b = f.buckets or { 0, 0, 0, 0 }
    L[#L + 1] = ""
    L[#L + 1] = string.format("Frames: %d, average %.2f ms (should be %.2f), worst %.1f ms. On time %d, late %d, slow %d, hitch %d. Lua it can see: %.1f%% of the time.",
        f.n or 0, f.avg or 0, f.base or 0, f.max or 0, b[1], b[2], b[3], b[4], snap.luaPct or 0)
    L[#L + 1] = string.format("Lua memory: %.1f MB now, %.1f MB at most; about %.0f KB taken a second.", (snap.mem or 0) / 1024, (snap.memPeak or 0) / 1024, snap.allocKBs or 0)
    if snap.npcLoop then L[#L + 1] = string.format("City NPC loop: %.2f ms average, %.2f ms worst.", snap.npcLoop.avg or 0, snap.npcLoop.max or 0) end
    if snap.netcfg then
        local n = snap.netcfg
        L[#L + 1] = string.format("Server net settings: net_splitpacket_maxrate %s, sv_maxrate %s, sv_minrate %s", tostring(n.net_splitpacket_maxrate), tostring(n.sv_maxrate), tostring(n.sv_minrate))
    end
    Table(L, "Hooks (costliest first):", snap.hooks or {}, { { "ms", "total ms" }, { "pct", "% of time" }, { "n", "calls" }, { "avg", "avg ms" }, { "max", "worst ms" } })
    Table(L, "Timers:", snap.timers or {}, { { "ms", "total ms" }, { "pct", "% of time" }, { "n", "runs" }, { "avg", "avg ms" }, { "max", "worst ms" } })
    Table(L, "Net in:", snap.recv or {}, { { "n", "count" }, { "bytes", "bytes" }, { "kbs", "KB/s" }, { "ms", "handler ms" }, { "max", "worst ms" }, { "unhandled", "unhandled" } })
    Table(L, "Net out:", snap.sent or {}, { { "n", "sends" }, { "to", "to players" }, { "bytes", "bytes" }, { "kbs", "KB/s" } })
    Table(L, "Networked values:", snap.nw or {}, { { "calls", "set" }, { "changes", "changed" }, { "cps", "changes/s" } })
    if snap.senders and #snap.senders > 0 then
        Table(L, "Who sent the server messages:", snap.senders, { { "n", "messages" }, { "bytes", "bytes" }, { "peakN", "busiest second" }, { "peakBytes", "bytes in it" }, { "top", "mostly" } })
    end
    if snap.players then
        Table(L, "Players:", snap.players, { { "ping", "ping" }, { "loss", "loss %" }, { "kbs", "gamemode KB/s to them" }, { "queue", "bytes waiting" }, { "loading", "loading" } })
    end
    Table(L, "Entities that grew since it started:", snap.growth or {}, { { "from", "from" }, { "to", "to" } })
    L[#L + 1] = ""
    L[#L + 1] = string.format("Hitches: %d in all; the last %d:", snap.spikeCount or 0, #(snap.spikes or {}))
    for _, sp in ipairs(snap.spikes or {}) do
        local parts = {}
        for _, t in ipairs(sp.top or {}) do parts[#parts + 1] = t.k .. " " .. t.ms .. " ms" end
        L[#L + 1] = string.format("  %s  %.0f ms (Lua seen %.1f ms, %d players): %s", sp.at, sp.ms, sp.lua, sp.players or 0, #parts > 0 and table.concat(parts, "; ") or "nothing timed")
    end
    if snap.floods and #snap.floods > 0 then
        L[#L + 1] = ""
        L[#L + 1] = "Floods (a player sending a lot in one second):"
        for _, fl in ipairs(snap.floods) do L[#L + 1] = string.format("  %s  %s (%s): %d messages, %d bytes", fl.at, fl.who, fl.sid or "", fl.n, fl.bytes) end
    end
    L[#L + 1] = ""
    L[#L + 1] = "Census (every 10 s, the last 60):"
    for _, h in ipairs(snap.history or {}) do
        L[#L + 1] = string.format("  +%ds  entities %d, NPCs %d, %smemory %.1f MB, players %d", h.t, h.ents, h.npcs or 0, h.edicts and ("edicts " .. h.edicts .. ", ") or "", h.mem / 1024, h.players or 0)
    end
    return table.concat(L, "\n")
end
