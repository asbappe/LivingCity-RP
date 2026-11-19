--[[
    Living City: sending big and frequent things to players safely (server and client)

    A player's game can only hold so much reliable data waiting to be read
    (about 256 KB). Past that it is dropped with "SendData reliable data too
    big", and if it happens again on joining, the game loops reconnecting. One
    net message also can't be over 64 KB. Everything LC.SendCompressed sends
    (sv_livingcity_data.lua) comes through here (docs/dev/network-audit.md):

      * a send that fits in one message (60 KB or less, compressed) and finds
        nothing waiting for that player goes at once, exactly as it always did;
      * a bigger one goes in pieces of 30 KB that the player's game puts back
        together and hands to the same receiver, as if it came in one message;
      * each player is sent at most about 128 KB at once and 64 KB a second
        after that; the rest waits its turn, in the order it was sent;
      * while a player is still loading in (their game reads nothing yet), sends
        of 16 KB and more, and anything past 64 KB in all, wait until their game
        says it's ready (or 90 seconds, whichever comes first);
      * whole-state messages (the editor's layout, the territory map) go to
        each player at most once a second; a newer one replaces one waiting,
        and the very same state they were just sent isn't sent again.

    LC.SetGlobalLong / LC.GetGlobalLong: a networked global string longer than
    the engine's 511 characters, kept in parts of 500 (the city's laws, the
    Administrator's broadcast on the screens).
]]

LC = LC or {}
local N = LC.Net or {}
LC.Net = N

N.ONE_MAX = 60000      -- bytes: a send this size or smaller goes as one message
N.PIECE = 30000        -- bytes in each piece of a bigger one
N.BURST = 131072       -- bytes a player may be sent at once
N.RATE = 65536         -- bytes a second after that
N.HOLD_BIG = 16384     -- bytes: sends this big wait while the player is loading in
N.LOAD_MAX = 65536     -- bytes a player loading in is sent in all before the rest waits
N.READY_WAIT = 90      -- seconds: how long to wait for a joining game to say it's ready
N.SAME_EVERY = 1       -- seconds between two whole-state messages of a kind to one player
N.QUEUE_MAX = 8388608  -- bytes waiting for one player before new sends are dropped (never in practice)
N.GLOBAL_PART = 500    -- characters in each part of a long global string
N.SAME = N.SAME or { lc_data = true, lc_public = true }

-- data cut into pieces of `size` bytes (at least one piece, maybe empty)
function N.Split(data, size)
    data = tostring(data or "")
    size = math.max(1, math.floor(tonumber(size) or N.PIECE))
    local out = {}
    for i = 1, #data, size do out[#out + 1] = string.sub(data, i, i + size - 1) end
    if #out == 0 then out[1] = "" end
    return out
end

-- Piece i of n of the send called `key`: the whole data once the last piece is in, else nil.
function N.Assemble(store, key, i, n, piece)
    i, n = tonumber(i) or 0, tonumber(n) or 0
    if n <= 1 then return piece end
    if i < 1 or i > n or n > 4096 then return nil end
    local now = (SysTime and SysTime()) or os.time()
    local b = store[key]
    if not b or b.n ~= n or i == 1 then
        for k, old in pairs(store) do if now - (old.at or 0) > 120 then store[k] = nil end end -- (pieces of a send that never finished)
        b = { n = n, got = 0, parts = {}, at = now }
        store[key] = b
    end
    if b.parts[i] then return nil end
    b.parts[i] = piece or ""
    b.got = b.got + 1
    if b.got < n then return nil end
    store[key] = nil
    return table.concat(b.parts, "", 1, n)
end

------------------------------------------------------------------------
-- Long global strings
------------------------------------------------------------------------

function LC.SetGlobalLong(key, text)
    text = tostring(text or "")
    local parts = N.Split(text, N.GLOBAL_PART)
    for i, part in ipairs(parts) do SetGlobal2String(i == 1 and key or (key .. "_" .. i), part) end
    SetGlobal2Int(key .. "_parts", #parts)
end

function LC.GetGlobalLong(key, default)
    local n = tonumber(GetGlobal2Int(key .. "_parts", 0)) or 0
    if n <= 1 then return GetGlobal2String(key, default) end
    local t = { GetGlobal2String(key, "") }
    for i = 2, n do t[i] = GetGlobal2String(key .. "_" .. i, "") end
    return table.concat(t)
end

------------------------------------------------------------------------
-- The server's side
------------------------------------------------------------------------

if SERVER then
    util.AddNetworkString("lc_big")
    util.AddNetworkString("lc_net_ready")

    N.players = N.players or {} -- [ply] = { tokens, at, q, same, sentSame, lastSame, loading, loaded, bytes }
    N.busy = N.busy or {}       -- [ply] = true: something waiting for them

    local function State(p)
        local s = N.players[p]
        if not s then
            s = { tokens = N.BURST, at = CurTime(), q = {}, same = {}, sentSame = {}, lastSame = {}, bytes = 0, loaded = 0 }
            N.players[p] = s
        end
        return s
    end
    N.State = State

    local function Refill(s, now)
        s.tokens = math.min(N.BURST, s.tokens + math.max(0, now - s.at) * N.RATE)
        s.at = now
    end

    local function Loading(s, now)
        if s.loading and now - s.loading > N.READY_WAIT then s.loading = nil end
        return s.loading ~= nil
    end

    -- a game still loading in can't take this yet
    local function TooMuchWhileLoading(s, size)
        return size >= N.HOLD_BIG or s.loaded + size > N.LOAD_MAX
    end

    local function SendOne(msg, data, to)
        net.Start(msg)
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)
        net.Send(to)
    end

    local nextId = 0
    local function SendPiece(p, item)
        if not item.pieces then
            nextId = nextId % 65535 + 1
            item.id, item.pieces, item.i = nextId, N.Split(item.data, N.PIECE), 0
        end
        item.i = item.i + 1
        local piece = item.pieces[item.i]
        net.Start("lc_big")
        net.WriteString(item.msg)
        net.WriteUInt(item.id, 16)
        net.WriteUInt(item.i, 16)
        net.WriteUInt(#item.pieces, 16)
        net.WriteUInt(#piece, 32)
        net.WriteData(piece, #piece)
        net.Send(p)
        return #piece, item.i >= #item.pieces
    end

    local function Enqueue(p, s, msg, data)
        if s.bytes + #data > N.QUEUE_MAX then
            print("[Miscount] Not sending " .. msg .. " to " .. tostring(p) .. ": too much is already waiting for them.")
            return
        end
        s.q[#s.q + 1] = { msg = msg, data = data }
        s.bytes = s.bytes + #data
        N.busy[p] = true
    end

    -- true: it may go to p now (counted against what p may be sent); false: it waits its turn
    function N.Route(p, msg, data, now)
        local s = State(p)
        Refill(s, now)
        if N.SAME[msg] then
            local slot = s.same[msg]
            if slot then slot.data = data return false end
            for _, it in ipairs(s.q) do
                if it.msg == msg and not it.pieces then s.bytes = s.bytes - #it.data + #data it.data, s.lastSame[msg] = data, data return false end
            end
            local last = s.sentSame[msg]
            if last and now - last < N.SAME_EVERY then
                s.same[msg] = { data = data, due = last + N.SAME_EVERY }
                N.busy[p] = true
                return false
            end
            s.sentSame[msg], s.lastSame[msg] = now, data
        end
        local loading = Loading(s, now)
        if #data > N.ONE_MAX or #s.q > 0 or s.tokens <= 0 or (loading and TooMuchWhileLoading(s, #data)) then
            Enqueue(p, s, msg, data)
            return false
        end
        s.tokens = s.tokens - #data
        if loading then s.loaded = s.loaded + #data end
        return true
    end

    local function List(recipients)
        if recipients == nil then return {} end
        if type(recipients) ~= "table" or (recipients[1] == nil and recipients.IsValid) then return { recipients } end
        return recipients
    end

    -- data: already compressed. recipients: a player or a list of them.
    function N.SendData(msg, data, recipients)
        local now, fast, all = CurTime(), {}, true
        for _, p in ipairs(List(recipients)) do
            if IsValid(p) then
                if N.Route(p, msg, data, now) then fast[#fast + 1] = p else all = false end
            end
        end
        if #fast > 0 then SendOne(msg, data, all and recipients or fast) end
    end

    function N.SendCompressed(msg, tbl, recipients)
        local json = util.TableToJSON(tbl)
        local data = json and util.Compress(json)
        if not data then return end
        N.SendData(msg, data, recipients)
    end

    -- what's waiting for p, as much as p may be sent now
    function N.Pump(p, s, now)
        Refill(s, now)
        for msg, slot in pairs(s.same) do
            if now >= slot.due then
                s.same[msg] = nil
                if slot.data ~= s.lastSame[msg] then -- (the very same state again: their game has it already)
                    s.sentSame[msg], s.lastSame[msg] = now, slot.data
                    Enqueue(p, s, msg, slot.data)
                end
            end
        end
        local loading = Loading(s, now)
        while s.q[1] and s.tokens > 0 do
            local item = s.q[1]
            if loading and not item.pieces and TooMuchWhileLoading(s, #item.data) then break end
            if #item.data <= N.ONE_MAX then
                SendOne(item.msg, item.data, p)
                s.tokens = s.tokens - #item.data
                if loading then s.loaded = s.loaded + #item.data end
                table.remove(s.q, 1)
                s.bytes = s.bytes - #item.data
            else
                local sent, done = SendPiece(p, item)
                s.tokens = s.tokens - sent
                if done then table.remove(s.q, 1) s.bytes = s.bytes - #item.data end
            end
        end
        return #s.q > 0 or next(s.same) ~= nil
    end

    function N.PumpAll()
        local now = CurTime()
        for p in pairs(N.busy) do
            local s = N.players[p]
            if not IsValid(p) or not s then
                N.busy[p], N.players[p] = nil, nil
            elseif not N.Pump(p, s, now) then
                N.busy[p] = nil
            end
        end
    end
    timer.Create("LivingCityNetPump", 0.1, 0, function()
        if next(N.busy) == nil then return end
        local ok, err = LC.Try(N.PumpAll)
        if not ok then print("[Miscount] net pump: " .. tostring(err)) end
    end)

    -- joining: big sends wait until the game has loaded (its receivers exist and it reads what it's sent)
    function N.Joining(p)
        if not IsValid(p) or N.READY_WAIT <= 0 then return end
        local s = State(p)
        s.loading, s.loaded = CurTime(), 0
    end
    function N.Ready(p)
        local s = N.players[p]
        if s and s.loading then s.loading = nil if s.q[1] then N.busy[p] = true end end
    end
    hook.Add("PlayerInitialSpawn", "LivingCityNet", function(p) N.Joining(p) end)
    net.Receive("lc_net_ready", function(_, p) N.Ready(p) end)
    hook.Add("PlayerDisconnected", "LivingCityNet", function(p) N.players[p], N.busy[p] = nil, nil end)
end

------------------------------------------------------------------------
-- The player's side
------------------------------------------------------------------------

if CLIENT then
    N.store = N.store or {}

    -- A put-together send handed to its own receiver, which reads it the usual way
    -- (net.ReadUInt for the length, then net.ReadData), as if it came in one message.
    function N.Deliver(msg, data)
        local fn = net.Receivers and net.Receivers[string.lower(msg)]
        if not fn then return false end
        local rU, rD = net.ReadUInt, net.ReadData
        local gaveLen = false
        net.ReadUInt = function() if not gaveLen then gaveLen = true return #data end return 0 end
        net.ReadData = function() return data end
        local ok, err = LC.Try(fn, #data * 8, nil)
        net.ReadUInt, net.ReadData = rU, rD
        if not ok then print("[Miscount] " .. msg .. ": " .. tostring(err)) end
        return ok
    end

    net.Receive("lc_big", function()
        local msg = net.ReadString()
        local id, i, n = net.ReadUInt(16), net.ReadUInt(16), net.ReadUInt(16)
        local len = net.ReadUInt(32)
        local piece = net.ReadData(len) or ""
        local whole = N.Assemble(N.store, msg .. "#" .. tostring(id), i, n, piece)
        if whole then N.Deliver(msg, whole) end
    end)

    -- the game has loaded: the server may send it the big things now
    hook.Add("InitPostEntity", "LivingCityNetReady", function()
        net.Start("lc_net_ready")
        net.SendToServer()
    end)
end
