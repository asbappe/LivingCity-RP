--[[
    Living City: every error in one file (server and client)

    What goes wrong while the server runs is kept, grouped and counted, in
    garrysmod/data/livingcity/errors.txt: one entry for each different error,
    with how often, when first and last, where in the code and what was going
    on. It is kept over restarts, so a server left running (even with one
    person standing about) fills it by itself. The owner sends that one file.

    What is caught:
      - Lua errors on the server that come from the gamemode (any line of the
        trace in its files, not only the first);
      - the same on every player's game, sent to the server (one every few
        seconds, a repeat counted once a minute);
      - errors a protected call swallowed (LC.Try, which the gamemode uses
        where it used pcall): the code carried on and nobody was told;
      - what the code reports itself (LC.Error).

    LC.Try(f, ...)       pcall, with the error written down. Never raises.
    LC.ErrorNote(...)    write one down (server: into the list; client: to the server).
    LC.ErrorsText()      (server) the file's text.
    LC.ErrorsCount()     (server) how many different errors are in the list.
    lc_errors            (admins) opens the list with a Copy button. Also F4 > Factions > Admin: errors.
    lc_errors_clear      (superadmins) starts the list again; the old one stays as errors_previous.txt.
]]

LC = LC or {}

local function Clean(v, max)
    local s = (v == nil) and "nil" or tostring(v)
    s = string.gsub(s, "[%z\1-\8\11-\31\127]", "?")
    if #s > max then s = string.sub(s, 1, max) .. "..." end
    return s
end

-- The same error with another entity number or memory address is the same error.
local function Key(msg)
    local k = string.gsub(msg, "%[%d+%]", "[#]")
    k = string.gsub(k, "0x%x+", "0x#")
    return k
end

local function Mentions(text)
    text = string.lower(tostring(text or ""))
    return string.find(text, "livingcity", 1, true) or string.find(text, "living city", 1, true) or string.find(text, "miscount", 1, true)
        or string.find(text, "lc_", 1, true) or string.find(text, "weapon_lc_", 1, true)
end

local function StackText(stack)
    if not istable(stack) then return nil end
    local out = {}
    for i = 1, math.min(#stack, 8) do
        local fr = stack[i]
        if istable(fr) then
            local fn = fr.Function
            out[#out + 1] = string.format("%s:%s%s", tostring(fr.File or "?"), tostring(fr.Line or "?"),
                (fn ~= nil and fn ~= "") and (" in " .. tostring(fn)) or "")
        end
    end
    if #out == 0 then return nil end
    return table.concat(out, "\n")
end

-- Where LC.Try was called from (only looked up for an error not seen before).
local function Caller()
    for lvl = 3, 8 do
        local info = debug.getinfo(lvl, "Sl")
        if not info then return nil end
        if info.currentline and info.currentline > 0 and not string.find(info.short_src or "", "sh_livingcity_errors", 1, true) then
            return tostring(info.short_src) .. ":" .. tostring(info.currentline)
        end
    end
end

-- pcall, and what it swallowed is written down. Writing it down can never
-- raise an error of its own: the caller gets exactly what pcall gave.
local noting = false
local function Tried(ok, ...)
    if not ok and not noting and LC.ErrorNote then
        noting = true
        pcall(LC.ErrorNote, "hidden", (...), nil, nil, 1, Caller)
        noting = false
    end
    return ok, ...
end
function LC.Try(f, ...) return Tried(pcall(f, ...)) end

------------------------------------------------------------------------
-- A player's game: errors go to the server, a few at a time
------------------------------------------------------------------------

if CLIENT then
    local MAX = 60
    local seen, count = {}, 0

    function LC.ErrorNote(realm, msg, stack, _, n, where)
        msg = Clean(msg, 500)
        local key = tostring(realm) .. "|" .. Key(msg)
        local e = seen[key]
        if not e then
            if count >= MAX then return end
            count = count + 1
            if type(where) == "function" then where = where() end
            local text = msg
            if stack and stack ~= "" then text = text .. "\n" .. stack elseif where then text = text .. "\n" .. tostring(where) end
            e = { kind = (realm == "hidden") and "hidden" or "client", text = Clean(text, 900), unsent = 0, nextSend = 0 }
            seen[key] = e
        end
        e.unsent = e.unsent + (n or 1)
    end

    hook.Add("OnLuaError", "LivingCityClientErrors", function(err, _, stack, name)
        if noting then return end
        local st = StackText(stack)
        if not (Mentions(err) or Mentions(st) or Mentions(name)) then return end
        noting = true
        pcall(LC.ErrorNote, "client", err, st)
        noting = false
    end)

    -- One error to the server at a time; the same one again at most once a minute, with how many times since.
    function LC.ErrorsSendOne()
        local now = CurTime()
        for _, e in pairs(seen) do
            if e.unsent > 0 and now >= e.nextSend then
                net.Start("lc_clerror")
                net.WriteString(e.kind)
                net.WriteString(e.text)
                net.WriteUInt(math.min(e.unsent, 65535), 16)
                net.SendToServer()
                e.unsent, e.nextSend = 0, now + 60
                return true
            end
        end
        return false
    end
    timer.Create("LivingCityClientErrors", 3, 0, function() LC.ErrorsSendOne() end)
    return
end

------------------------------------------------------------------------
-- The server: the list, and its file
------------------------------------------------------------------------

util.AddNetworkString("lc_clerror")

local FILE_JSON, FILE_TXT, FILE_OLD = "livingcity/errors.json", "livingcity/errors.txt", "livingcity/errors_previous.txt"
local MAX, MAX_HIDDEN, FORGET = 200, 60, 14 * 86400
LC.ErrorsFile = FILE_TXT

LC.Err = LC.Err or { list = {}, by = {}, since = os.time(), boots = 0, lost = 0 }

local function Load()
    local E = LC.Err
    local raw = file.Read(FILE_JSON, "DATA")
    local t = raw and util.JSONToTable(raw)
    if not istable(t) or not istable(t.list) then return end
    local now = os.time()
    E.since, E.boots, E.lost = tonumber(t.since) or now, tonumber(t.boots) or 0, tonumber(t.lost) or 0
    for _, e in ipairs(t.list) do
        if istable(e) and isstring(e.key) and (now - (tonumber(e.last) or 0)) < FORGET and not E.by[e.key] then
            e.n, e.boot, e.whoSet = tonumber(e.n) or 1, 0, nil
            E.list[#E.list + 1] = e
            E.by[e.key] = e
        end
    end
end
LC.ErrorsLoad = Load
if not LC.Err.loaded then
    LC.Err.loaded = true
    pcall(Load)
    LC.Err.boots = (LC.Err.boots or 0) + 1
end

local function HiddenCount()
    local n = 0
    for _, e in ipairs(LC.Err.list) do if e.realm == "hidden" or e.realm == "client hidden" then n = n + 1 end end
    return n
end

local function Context()
    local players, up = 0, "?"
    pcall(function() players = #player.GetAll() up = string.NiceTime(CurTime()) end)
    return string.format("%d players on, event %s, up %s", players, tostring(LC.Event or "none"), tostring(up))
end

local function LogTail()
    local buf, out = LC.LogBuffer or {}, {}
    for i = math.max(1, #buf - 4), #buf do out[#out + 1] = Clean(buf[i], 200) end
    return out
end

-- realm: "server", "client", "hidden" (a protected call swallowed it), "client hidden" or "caught" (the code reported it).
function LC.ErrorNote(realm, msg, stack, ply, n, where)
    local E = LC.Err
    realm = tostring(realm or "server")
    msg = Clean(msg, 600)
    n = math.max(1, math.floor(tonumber(n) or 1))
    local k = Key(msg)
    local now = os.time()
    local e
    if realm == "caught" then
        -- (reported by the code that caught it: the same error LC.Try has just written down, with a name now)
        e = E.by["hidden|" .. k]
        if e then
            e.told = true
            if isstring(where) and not e.where then e.where = Clean(where, 160) end
            if e.stamp == CurTime() then e.last = now E.dirty = true return e end
        end
    end
    e = e or E.by[realm .. "|" .. k]
    if not e then
        local hidden = realm == "hidden" or realm == "client hidden"
        if #E.list >= MAX or (hidden and HiddenCount() >= MAX_HIDDEN) then
            E.lost = (E.lost or 0) + 1
            E.dirty = true
            return nil
        end
        if type(where) == "function" then where = where() end
        e = { key = realm .. "|" .. k, realm = realm, msg = msg, stack = stack and Clean(stack, 1200) or nil,
            where = where and Clean(where, 160) or nil, n = 0, boot = 0, first = now, ctx = Context(), log = LogTail() }
        E.list[#E.list + 1] = e
        E.by[e.key] = e
        E.dirtyNew = true
    end
    e.n, e.boot, e.last, e.stamp = e.n + n, (e.boot or 0) + n, now, CurTime()
    if IsValid(ply) then
        e.whoSet = e.whoSet or {}
        if not e.whoSet[ply] then
            e.whoSet[ply] = true
            e.players = math.max(tonumber(e.players) or 0, table.Count(e.whoSet))
        end
    end
    E.dirty = true
    return e
end

function LC.ErrorsCount() return #LC.Err.list end

local function When(t)
    local ok, s = pcall(os.date, "%d %b %H:%M", tonumber(t) or 0)
    return ok and s or "?"
end

local LABEL = {
    server = "server", client = "a player's game", caught = "server, caught",
    hidden = "server, swallowed by a protected call", ["client hidden"] = "a player's game, swallowed by a protected call",
}

function LC.ErrorsSorted()
    local list = {}
    for i, e in ipairs(LC.Err.list) do list[i] = e end
    table.sort(list, function(a, b)
        if a.n ~= b.n then return a.n > b.n end
        return (a.first or 0) < (b.first or 0)
    end)
    return list
end

function LC.ErrorsText()
    local E = LC.Err
    local list = LC.ErrorsSorted()
    local total = 0
    for _, e in ipairs(list) do total = total + e.n end
    local out = {}
    out[#out + 1] = "MISCOUNT ERRORS"
    out[#out + 1] = string.format("version %s | map %s | written %s", tostring(LC.VERSION or "?"), game.GetMap(), When(os.time()))
    out[#out + 1] = string.format("%d different, %d in all, since %s (the server has started %d times since)",
        #list, total, When(E.since), E.boots or 0)
    if (E.lost or 0) > 0 then out[#out + 1] = string.format("%d more were not kept (the list was full)", E.lost) end
    if #list == 0 then out[#out + 1] = "" out[#out + 1] = "Nothing has gone wrong." end
    for i, e in ipairs(list) do
        out[#out + 1] = ""
        out[#out + 1] = string.format("#%d  %d times (%d since the server last started) | %s%s%s | first %s | last %s", i, e.n, e.boot or 0,
            LABEL[e.realm] or tostring(e.realm), e.told and ", reported" or "",
            (tonumber(e.players) or 0) > 0 and string.format(" (%d players)", e.players) or "", When(e.first), When(e.last))
        out[#out + 1] = e.msg
        if e.where then out[#out + 1] = "  from " .. e.where end
        if e.stack then
            for line in string.gmatch(e.stack, "[^\n]+") do out[#out + 1] = "  at " .. line end
        end
        if e.ctx then out[#out + 1] = "  then: " .. e.ctx end
        if istable(e.log) and #e.log > 0 then
            out[#out + 1] = "  the log just before:"
            for _, l in ipairs(e.log) do out[#out + 1] = "    " .. tostring(l) end
        end
    end
    return table.concat(out, "\n")
end

function LC.ErrorsSave()
    local E = LC.Err
    E.dirty, E.dirtyNew, E.savedAt = false, false, CurTime()
    local list = {}
    for i, e in ipairs(E.list) do
        list[i] = { key = e.key, realm = e.realm, msg = e.msg, stack = e.stack, where = e.where, n = e.n, first = e.first,
            last = e.last, ctx = e.ctx, log = e.log, players = e.players, told = e.told }
    end
    file.CreateDir("livingcity")
    file.Write(FILE_JSON, util.TableToJSON({ since = E.since, boots = E.boots, lost = E.lost, list = list }))
    file.Write(FILE_TXT, LC.ErrorsText())
end

function LC.ErrorsClear()
    local E = LC.Err
    if #E.list > 0 then file.Write(FILE_OLD, LC.ErrorsText()) end
    E.list, E.by, E.lost, E.since = {}, {}, 0, os.time()
    LC.ErrorsSave()
end

-- A new error is on disk within ten seconds; a count going up, within two minutes.
timer.Create("LivingCityErrorsSave", 10, 0, function()
    local E = LC.Err
    if E.dirtyNew or (E.dirty and CurTime() - (E.savedAt or -1e9) >= 120) then
        local ok, err = pcall(LC.ErrorsSave)
        if not ok then print("[Miscount] the errors file could not be written: " .. tostring(err)) end
    end
end)
hook.Add("ShutDown", "LivingCityErrorsSave", function() if LC.Err.dirty then pcall(LC.ErrorsSave) end end)

-- Lua errors on the server (the hook exists on current Garry's Mod builds)
hook.Add("OnLuaError", "LivingCityCapture", function(err, realm, stack, name)
    if noting then return end
    local st = StackText(stack)
    if not (Mentions(err) or Mentions(st) or Mentions(name)) then return end
    noting = true
    pcall(function()
        local where = ""
        if istable(stack) and stack[1] then where = tostring(stack[1].File or "") .. ":" .. tostring(stack[1].Line or "") end
        if LC.Log then LC.Log("error", string.format("lua %s error: %s (%s)", tostring(realm), tostring(err), where)) end
        LC.ErrorNote("server", err, st)
    end)
    noting = false
end)

-- Errors sent by players' games
local lastClientError = {}
net.Receive("lc_clerror", function(_, ply)
    if not IsValid(ply) then return end
    if (lastClientError[ply] or 0) > CurTime() then return end
    lastClientError[ply] = CurTime() + 2
    local kind = net.ReadString()
    local text = Clean(net.ReadString(), 900)
    local n = net.ReadUInt(16)
    local msg, stack = string.match(text, "^([^\n]*)\n(.*)$")
    msg = msg or text
    if kind ~= "hidden" and not Mentions(text) then return end
    if kind ~= "hidden" and LC.Log then LC.Log("error", "client " .. ply:Nick() .. ": " .. string.sub(msg, 1, 400)) end
    LC.ErrorNote(kind == "hidden" and "client hidden" or "client", msg, stack, ply, n)
end)
hook.Add("PlayerDisconnected", "LivingCityErrorsLeave", function(ply) lastClientError[ply] = nil end)

local function CanRead(ply) return not IsValid(ply) or ply:IsAdmin() or (LC.CanEdit and LC.CanEdit(ply)) end

concommand.Add("lc_errors", function(ply)
    if not CanRead(ply) then return end
    pcall(LC.ErrorsSave)
    local text = LC.ErrorsText()
    if IsValid(ply) then
        LC.SendCompressed("lc_report", { text = text, file = "garrysmod/data/" .. FILE_TXT, errors = true,
            clear = ply:IsSuperAdmin() and #LC.Err.list > 0 or nil }, { ply })
    else
        print(text)
        print("Saved to garrysmod/data/" .. FILE_TXT)
    end
end)

concommand.Add("lc_errors_clear", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    LC.ErrorsClear()
    if not IsValid(ply) then print("[Miscount] The errors list starts again. The old one: garrysmod/data/" .. FILE_OLD) end
end)
