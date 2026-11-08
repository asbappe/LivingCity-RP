--[[
    Living City: the city's people's name tags, sent only where they're seen
    (server and client)

    Every NPC used to carry its name (lc_pname), its job (lc_pjob) and what
    it's doing (lc_doing) as engine networked strings. Those ride along in a
    joining player's first full update for every NPC on the map: with about
    100 people that's several KB more on the join, and every change of what
    someone is doing went to every player (docs/dev/network-audit.md).

    Now the server keeps them in a Lua table, and each player's game asks for
    them about once a second: the server answers with the people within
    1500 units, plus any farther one a window or a label on screen is reading
    (an NPC you look at across the square, the Administrator on air), and
    only the values that changed since it last told that player. The game
    keeps them per entity, and every reader goes through LC.NPCStr.

      LC.SetNPCStr(ent, key, value)   (server) set one of the three
      LC.NPCStr(ent, key, default)    (both) read it, the way GetNW2String did:
                                      the default only when it was never set

    Short flags (lc_role, lc_state, the bools and ints) stay engine values.
    Any other key given to these two goes straight to the engine's string.
]]

LC = LC or {}
local S = LC.NPCStrNet or {}
LC.NPCStrNet = S

S.KEYS = { "lc_pname", "lc_pjob", "lc_doing" }
S.ID = { lc_pname = 1, lc_pjob = 2, lc_doing = 3 }
S.RADIUS = 1500       -- units: everyone this close to a player is sent to them
S.EVERY = 1           -- seconds between a game's asks
S.SOON = 0.25         -- seconds: the quickest a game asks again for someone new on screen
S.READ_FOR = 2        -- seconds a read keeps a far entity on the game's list
S.MAX_WANT = 24       -- far entities a game asks after at once
S.MAX_BYTES = 16000   -- about this much in one answer; the rest comes with the next
S.IDX_BITS = 13       -- entity indexes (the engine's MAX_EDICT_BITS)

------------------------------------------------------------------------
-- The server's side
------------------------------------------------------------------------

if SERVER then
    util.AddNetworkString("lc_npcstr_ask")
    util.AddNetworkString("lc_npcstr")

    S.vals = S.vals or {}   -- [ent] = { key = value }  (a value set to "" stays "")
    S.sent = S.sent or {}   -- [ply] = { [ent] = { key = value } }: what that player's game has
    S.gone = S.gone or {}   -- [ply] = { idx, ... }: removed entities their game still holds
    S.last = S.last or {}   -- [ply] = CurTime() of their last ask

    function LC.SetNPCStr(ent, key, value)
        if not IsValid(ent) then return end
        value = tostring(value or "")
        if not S.ID[key] then ent:SetNW2String(key, value) return end
        local t = S.vals[ent]
        if not t then t = {} S.vals[ent] = t end
        t[key] = value
    end

    function LC.NPCStr(ent, key, default)
        if not IsValid(ent) then return default end
        local t = S.ID[key] and S.vals[ent]
        local v = t and t[key]
        if v ~= nil then return v end
        return ent:GetNW2String(key, default) -- (never set here: the engine's, or the default)
    end

    -- What changed for this player, nearest first: { { idx, { {id, value}, ... } }, ... }, gone list
    function S.Changes(ply, want)
        local pos = ply:GetPos()
        local r2 = S.RADIUS * S.RADIUS
        local mine = S.sent[ply]
        if not mine then mine = {} S.sent[ply] = mine end
        local scope = {}
        for ent, t in pairs(S.vals) do
            if IsValid(ent) then
                local idx = ent:EntIndex()
                local d = ent:GetPos():DistToSqr(pos)
                if d <= r2 or (want and want[idx]) then scope[#scope + 1] = { ent = ent, t = t, idx = idx, d = d } end
            else
                S.vals[ent] = nil -- (gone without EntityRemoved: nothing to keep)
            end
        end
        table.sort(scope, function(a, b) return a.d < b.d end)
        local out, bytes = {}, 0
        for _, s in ipairs(scope) do
            local had = mine[s.ent]
            local diff
            for id, key in ipairs(S.KEYS) do
                local v = s.t[key]
                if v ~= nil and (not had or had[key] ~= v) then
                    diff = diff or {}
                    diff[#diff + 1] = { id, v }
                    bytes = bytes + #v + 2
                end
            end
            if diff then
                had = had or {}
                mine[s.ent] = had
                for _, kv in ipairs(diff) do had[S.KEYS[kv[1]]] = kv[2] end
                out[#out + 1] = { s.idx, diff }
                bytes = bytes + 3
                if bytes >= S.MAX_BYTES then break end
            end
        end
        local gone = S.gone[ply] or {}
        S.gone[ply] = nil
        return out, gone
    end

    function S.Answer(ply, want)
        local out, gone = S.Changes(ply, want)
        if #out == 0 and #gone == 0 then return false end
        net.Start("lc_npcstr")
        net.WriteUInt(math.min(#gone, 255), 8)
        for i = 1, math.min(#gone, 255) do net.WriteUInt(gone[i], S.IDX_BITS) end
        net.WriteUInt(#out, 8)
        for _, e in ipairs(out) do
            net.WriteUInt(e[1], S.IDX_BITS)
            net.WriteUInt(#e[2], 2)
            for _, kv in ipairs(e[2]) do
                net.WriteUInt(kv[1], 2)
                net.WriteString(kv[2])
            end
        end
        net.Send(ply)
        return true
    end

    net.Receive("lc_npcstr_ask", function(_, ply)
        if not IsValid(ply) then return end
        local now = CurTime()
        if S.last[ply] and now - S.last[ply] < S.SOON * 0.8 then return end
        S.last[ply] = now
        local n = math.min(net.ReadUInt(6) or 0, S.MAX_WANT)
        local want
        for _ = 1, n do
            local idx = net.ReadUInt(S.IDX_BITS)
            if idx then want = want or {} want[idx] = true end
        end
        S.Answer(ply, want)
    end)

    hook.Add("EntityRemoved", "LivingCityNPCStr", function(ent)
        if S.sent[ent] then S.sent[ent], S.gone[ent], S.last[ent] = nil, nil, nil end
        if not S.vals[ent] then return end
        S.vals[ent] = nil
        local idx = ent:EntIndex()
        for ply, mine in pairs(S.sent) do
            if mine[ent] then
                mine[ent] = nil
                local g = S.gone[ply] or {}
                g[#g + 1] = idx
                S.gone[ply] = g
            end
        end
    end)
    hook.Add("PlayerDisconnected", "LivingCityNPCStr", function(p) S.sent[p], S.gone[p], S.last[p] = nil, nil, nil end)
end

------------------------------------------------------------------------
-- The player's side
------------------------------------------------------------------------

if CLIENT then
    S.cache = S.cache or {}  -- [idx] = { key = value }
    S.read = S.read or {}    -- [idx] = { ent, CurTime() of the last read }
    S.asked = S.asked or {}  -- [idx] = CurTime() it was last asked after by itself
    S.lastAsk, S.soon = S.lastAsk or 0, false

    function LC.NPCStr(ent, key, default)
        if not IsValid(ent) then return default end
        if S.ID[key] then
            local idx = ent:EntIndex()
            local r = S.read[idx]
            if r then r[1], r[2] = ent, CurTime() else S.read[idx] = { ent, CurTime() } end
            local c = S.cache[idx]
            local v = c and c[key]
            if v ~= nil then return v end
            if not c and (S.asked[idx] or -100) < CurTime() - 5 then S.soon = true end
        end
        return ent:GetNW2String(key, default) -- (not here yet: the engine's, or the default)
    end

    -- The far ones (or the ones with no answer yet) read on screen lately, at most MAX_WANT
    function S.Wanted()
        local now, out = CurTime(), {}
        local me = LocalPlayer()
        local pos = IsValid(me) and me:GetPos()
        local far2 = (S.RADIUS * 0.9) ^ 2
        for idx, r in pairs(S.read) do
            if now - r[2] > S.READ_FOR or not IsValid(r[1]) then
                S.read[idx] = nil
            elseif #out < S.MAX_WANT and (not S.cache[idx] or not pos or r[1]:GetPos():DistToSqr(pos) > far2) then
                out[#out + 1] = idx
            end
        end
        return out
    end

    function S.Ask()
        local want = S.Wanted()
        local now = CurTime()
        net.Start("lc_npcstr_ask")
        net.WriteUInt(#want, 6)
        for _, idx in ipairs(want) do
            net.WriteUInt(idx, S.IDX_BITS)
            if not S.cache[idx] then S.asked[idx] = now end
        end
        net.SendToServer()
        S.lastAsk, S.soon = now, false
    end

    function S.Take()
        for _ = 1, net.ReadUInt(8) do S.cache[net.ReadUInt(S.IDX_BITS)] = nil end
        for _ = 1, net.ReadUInt(8) do
            local idx = net.ReadUInt(S.IDX_BITS)
            local c = S.cache[idx]
            if not c then c = {} S.cache[idx] = c end
            for _ = 1, net.ReadUInt(2) do
                local key = S.KEYS[net.ReadUInt(2)]
                local v = net.ReadString()
                if key then c[key] = v end
            end
        end
    end
    net.Receive("lc_npcstr", function() S.Take() end)

    -- (asks only once the game has loaded: LocalPlayer is valid from then on)
    timer.Create("LivingCityNPCStr", S.SOON, 0, function()
        if not IsValid(LocalPlayer()) then return end
        local now = CurTime()
        if now - S.lastAsk >= S.EVERY or (S.soon and now - S.lastAsk >= S.SOON) then S.Ask() end
    end)
end
