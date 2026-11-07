--[[
    Living City: the lag monitor (server side)

    Staff turn it on in game (C > Help > Lag monitor, or lc_lagwatch in the
    console). While anyone is watching, the server measures, every second:

      - its own frames: ticks done, the longest gap between two (a hitch)
      - the city's NPC loop (Lua) at its slowest this second
      - NPC teleports done by the gamemode's own code, and where in the code
        (an NPC set down somewhere by script snaps on everyone's screen)
      - what the gamemode sent over the network, by message, and how much
      - entities, edicts (the engine's hard limit is 8176), NPCs, asleep
      - each watcher's ping and packet loss

    and sends it to the watchers, whose screen (cl_livingcity_lagwatch.lua)
    adds what their own game sees: frames, how regularly the server's
    updates arrive, and NPCs snapping on screen. Nothing is measured while
    nobody watches.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_lagwatch")
util.AddNetworkString("lc_lagwatch_on")

local watchers = {}  -- [ply] = true
local function Watching() return next(watchers) ~= nil end

local sec = { ticks = 0, worstGap = 0, luaMax = 0, tele = 0, teleBy = {}, netBytes = 0, netBy = {} }
local function Reset()
    sec = { ticks = 0, worstGap = 0, luaMax = 0, tele = 0, teleBy = {}, netBytes = 0, netBy = {} }
end

------------------------------------------------------------------------
-- Teleports of NPCs by script, and where from
------------------------------------------------------------------------

do
    local EM = FindMetaTable and FindMetaTable("Entity")
    if EM and EM.SetPos and not EM.lcLagSetPos then
        local setPos = EM.SetPos
        EM.lcLagSetPos = true
        EM.SetPos = function(self, pos, ...)
            if Watching() and LC.NPCs and LC.NPCs[self] and IsValid(self) and self.GetPos and not self.lcUnseenMove then
                local from = self:GetPos()
                if from and pos and from:DistToSqr(pos) > 48 * 48 then
                    sec.tele = sec.tele + 1
                    local info = debug.getinfo(2, "Sl")
                    local where = info and (string.match(info.short_src or "?", "([^/\\]+)$") or "?") .. ":" .. tostring(info.currentline) or "?"
                    sec.teleBy[where] = (sec.teleBy[where] or 0) + 1
                end
            end
            return setPos(self, pos, ...)
        end
    end
end

------------------------------------------------------------------------
-- What the gamemode sends, by message
------------------------------------------------------------------------

do
    if net and net.Start and not LC.lcLagNet then
        LC.lcLagNet = true
        local start, send, broadcast, sendPVS, sendOmit = net.Start, net.Send, net.Broadcast, net.SendPVS, net.SendOmit
        local current
        net.Start = function(name, ...) current = name return start(name, ...) end
        local function Count(n)
            if not Watching() or not current then return end
            local bytes = (net.BytesWritten and net.BytesWritten() or 0) * (n or 1)
            sec.netBytes = sec.netBytes + bytes
            local b = sec.netBy[current] or { n = 0, bytes = 0 }
            b.n, b.bytes = b.n + (n or 1), b.bytes + bytes
            sec.netBy[current] = b
        end
        net.Send = function(to, ...)
            local n = istable(to) and #to or 1
            Count(n)
            return send(to, ...)
        end
        net.Broadcast = function(...) Count(player.GetCount and player.GetCount() or 1) return broadcast(...) end
        if sendPVS then net.SendPVS = function(...) Count(1) return sendPVS(...) end end
        if sendOmit then net.SendOmit = function(...) Count(math.max(1, (player.GetCount and player.GetCount() or 1) - 1)) return sendOmit(...) end end
    end
end

------------------------------------------------------------------------
-- The server's own frames
------------------------------------------------------------------------

local lastTick
hook.Add("Tick", "LivingCityLagWatch", function()
    if not Watching() then lastTick = nil return end
    local now = SysTime()
    if lastTick then
        local gap = (now - lastTick) * 1000
        if gap > sec.worstGap then sec.worstGap = gap end
    end
    lastTick = now
    sec.ticks = sec.ticks + 1
    local p = LC.Perf
    if p and (p.last or 0) > sec.luaMax then sec.luaMax = p.last end
end)

local function Top(t, key, n)
    local list = {}
    for k, v in pairs(t) do list[#list + 1] = { k = k, v = type(v) == "table" and v[key] or v, n = type(v) == "table" and v.n or v } end
    table.sort(list, function(a, b) return a.v > b.v end)
    local out = {}
    for i = 1, math.min(n, #list) do out[i] = list[i] end
    return out
end

timer.Create("LivingCityLagWatch", 1, 0, function()
    if not Watching() then Reset() return end
    local npcs, asleep = 0, 0
    for npc in pairs(LC.NPCs or {}) do
        if IsValid(npc) then
            npcs = npcs + 1
            if npc.lcAsleep then asleep = asleep + 1 end
        end
    end
    local allNPCs, all = 0, ents.GetAll() -- (one list of every entity a second, not two)
    for _, e in ipairs(all) do if e:IsNPC() then allNPCs = allNPCs + 1 end end
    local data = {
        ticks = sec.ticks, rate = math.floor(1 / engine.TickInterval() + 0.5), worstGap = math.floor(sec.worstGap * 10) / 10,
        luaMax = math.floor(sec.luaMax * 100) / 100, tele = sec.tele, teleBy = Top(sec.teleBy, nil, 3),
        netBytes = sec.netBytes, netBy = Top(sec.netBy, "bytes", 4),
        ents = #all, edicts = ents.GetEdictCount and ents.GetEdictCount() or 0,
        npcs = npcs, allNPCs = allNPCs, asleep = asleep, netcfg = LC.NetSettings and LC.NetSettings() or nil,
    }
    -- sent outside the counting (the monitor doesn't count itself)
    local was = watchers
    watchers = {}
    for ply in pairs(was) do
        if IsValid(ply) then
            data.ping = ply:Ping()
            data.loss = ply.PacketLoss and ply:PacketLoss() or 0
            if LC.SendCompressed then LC.SendCompressed("lc_lagwatch", data, { ply }) end
        end
    end
    watchers = {}
    for ply in pairs(was) do if IsValid(ply) then watchers[ply] = true end end
    Reset()
end)

------------------------------------------------------------------------
-- The network settings big updates need. A busy city's update can be a
-- few KB (lots of NPCs and props changing at once), which is split into
-- several packets; Source sends split packets no faster than
-- net_splitpacket_maxrate, so a low one holds the update back and
-- everything freezes and then jumps (rubber-banding). lc_net_tune 0 leaves
-- the server's own settings alone.
------------------------------------------------------------------------

local cvTune = CreateConVar("lc_net_tune", "1", FCVAR_ARCHIVE, "Raise the server's network rates so big updates aren't held back (rubber-banding)")
local WANT = { net_splitpacket_maxrate = 1048576, sv_maxrate = 0, sv_minrate = 100000 }

function LC.NetSettings()
    local out = {}
    for name in pairs(WANT) do
        local cv = GetConVar(name)
        out[name] = cv and cv:GetString() or "?"
    end
    return out
end

function LC.TuneNet()
    if not cvTune:GetBool() then return end
    for name, want in pairs(WANT) do
        local cv = GetConVar(name)
        if cv then
            local v = cv:GetFloat()
            -- sv_maxrate 0 is "no limit"; anything else under the wanted rate is raised
            local low = (name == "sv_maxrate") and (v ~= 0 and v < 1048576) or (name ~= "sv_maxrate" and v < want)
            if low then
                RunConsoleCommand(name, tostring(want))
                if LC.Log then LC.Log("info", "Network: " .. name .. " raised from " .. cv:GetString() .. " to " .. want .. " (lc_net_tune)") end
            end
        end
    end
end
hook.Add("InitPostEntity", "LivingCityNetTune", function() timer.Simple(1, LC.TuneNet) end)
cvars.AddChangeCallback("lc_net_tune", function() LC.TuneNet() end, "LivingCityNetTune")

local function Allowed(ply) return IsValid(ply) and (ply:IsAdmin() or (LC.CanEdit and LC.CanEdit(ply))) end

net.Receive("lc_lagwatch_on", function(_, ply)
    if not Allowed(ply) then return end
    local on = net.ReadBool()
    watchers[ply] = on or nil
    if LC.Log then LC.Log("info", ply:Nick() .. (on and " started" or " stopped") .. " the lag monitor") end
end)

hook.Add("PlayerDisconnected", "LivingCityLagWatch", function(ply) watchers[ply] = nil end)
