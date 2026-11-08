--[[
    Living City: server timing

    Loaded first. Every one of the gamemode's repeating timers (the ones
    named LivingCity...) goes through here, for two reasons:

      Staggering   They are all created together, so the ones that run once a
                   second would all fire on the same frame, a small hitch that
                   everyone on the server sees as NPCs jerking back in unison
                   every second. Each is given its own offset inside its
                   interval instead, so the work is spread across the second
                   (lc_stagger_timers 0 turns it off).
      Timing       how long each one takes, so the slow one can be found:
                   lc_profile (superadmin) lists the costliest, lc_profile
                   reset starts over.
]]

if CLIENT then return end

LC = LC or {}
LC.TimerPerf = LC.TimerPerf or {} -- [id] = { calls, total (seconds), max, last }

local realCreate = LC.RealTimerCreate or timer.Create
LC.RealTimerCreate = realCreate

local cvStagger = CreateConVar("lc_stagger_timers", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED),
    "Spread the city's once-a-second timers across the second instead of firing them all on the same frame")

local function Record(id, dt)
    local p = LC.TimerPerf[id]
    if not p then p = { calls = 0, total = 0, max = 0, last = 0 } LC.TimerPerf[id] = p end
    p.calls, p.total, p.last = p.calls + 1, p.total + dt, dt
    if dt > p.max then p.max = dt end
    if LC.PerfDebugNote then LC.PerfDebugNote(id, dt) end -- (the performance debugger, when on: sh_livingcity_perfdebug.lua)
end

-- The same id always gets the same slot.
local function Offset(id, delay)
    local h = 0
    for i = 1, #id do h = (h * 31 + string.byte(id, i)) % 1000 end
    return h / 1000 * delay * 0.9
end

function timer.Create(id, delay, reps, fn)
    if type(id) == "string" and string.sub(id, 1, 10) == "LivingCity" and type(fn) == "function" and (reps == 0) then
        local inner = fn
        local off = (delay or 0) >= 0.5 and Offset(id, delay) or 0
        fn = function(...)
            if off > 0 and cvStagger:GetBool() and not LC.TestMode then
                local args = { ... }
                timer.Simple(off, function()
                    local t0 = SysTime()
                    inner(unpack(args))
                    Record(id, SysTime() - t0)
                end)
                return
            end
            local t0 = SysTime()
            inner(...)
            Record(id, SysTime() - t0)
        end
    end
    return realCreate(id, delay, reps, fn)
end

concommand.Add("lc_profile", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local function Say(msg) if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end
    if args[1] == "reset" then
        LC.TimerPerf = {}
        return Say("[Living City] Timer timings cleared.")
    end
    local list = {}
    for id, p in pairs(LC.TimerPerf) do list[#list + 1] = { id = id, p = p } end
    table.sort(list, function(a, b) return a.p.total > b.p.total end)
    Say("[Living City] Costliest timers (total ms, per call average, worst, calls):")
    for i = 1, math.min(12, #list) do
        local e = list[i]
        Say(string.format("  %-34s %8.1f total  %6.2f avg  %6.2f worst  %d calls", e.id, e.p.total * 1000,
            e.p.total / math.max(1, e.p.calls) * 1000, e.p.max * 1000, e.p.calls))
    end
    local perf = LC.Perf
    if perf and perf.samples and perf.samples > 0 then
        Say(string.format("  NPC loop: %.2f ms average, %.2f worst, over %d runs", perf.total / perf.samples, perf.max, perf.samples))
    end
end)

------------------------------------------------------------------------
-- Saved player data (PData), read from memory
--
-- Each ply:GetPData is a query on the server's sv.db (two when the key isn't
-- there: GMod looks under the old key name as well), and the city asks for
-- credits, standing, XP and the like many times a second. The first read of
-- each key is kept in memory for that player; writes and removals still go to
-- the database exactly as before, and update the copy in memory, so a read
-- always gives what was last written. (Nothing writes an online player's
-- saved data any other way.)
------------------------------------------------------------------------

local ABSENT = {} -- (remembered as not saved, so a missing key isn't looked up twice every time)

function LC.CachePData(meta)
    if not meta or not meta.GetPData or not meta.SetPData or not meta.RemovePData or meta.lcPDataCached then return false end
    meta.lcPDataCached = true
    local get, set, remove = meta.GetPData, meta.SetPData, meta.RemovePData
    local function Copy(ply)
        local c = ply.lcPData
        if not c then c = {} ply.lcPData = c end
        return c
    end
    meta.GetPData = function(ply, name, default)
        local c, k = Copy(ply), tostring(name)
        local v = c[k]
        if v == nil then
            v = get(ply, name, nil)
            if v == nil then v = ABSENT end
            c[k] = v
        end
        if v == ABSENT then return default end
        return v
    end
    meta.SetPData = function(ply, name, value)
        local r = set(ply, name, value)
        -- (stored as text, as the database does; a write it refused is read from it again)
        Copy(ply)[tostring(name)] = r ~= false and tostring(value) or nil
        return r
    end
    meta.RemovePData = function(ply, name)
        local r = remove(ply, name)
        Copy(ply)[tostring(name)] = r ~= false and ABSENT or nil
        return r
    end
    return true
end
LC.CachePData(FindMetaTable and FindMetaTable("Player"))
