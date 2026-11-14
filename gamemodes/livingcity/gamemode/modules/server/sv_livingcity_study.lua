--[[
    Living City: the play study (server side)

      The owner, 14 November: the gamemode stands in for other players when none are on, so
      "record how I play, then parse and filter it down to make baselines to influence the
      NPC/AI behaviour ... I could literally be like a model or case-study". Stage 1 (this):
      a recorder and a report. Nothing about any NPC changes by itself: the report goes to the
      code chat, which proposes changes for the owner's OK.

      Only someone who may use the editor (LC.CanEdit) can be studied, only while they have
      switched it on (F4 > Factions > Admin: play study), one at a time. With no study under
      way nothing here is hooked or wrapped.

      Every second it notes WHO the player is (faction, rank or special role), WHERE (the kind
      of zone, and whose ground that is to them: a Rebel on Combine ground is never mixed with
      a unit on the same ground), in WHAT (the city, or a dream, test or not: kept apart), on
      which job, how they move, what they hold, the hour, and who is near (security in sight,
      people about). Between those it writes down what happens: places entered and left, the
      job taken, its stages and how it ended, everything the gamemode itself announces about
      the player (its own LivingCity... events), what they use, hit and say, what they're told,
      and each meeting with security and what they did about it.

      It pauses, and counts none of that time, while the player is: flying (noclip), holding
      the editor's tool, the physics gun or the camera, watching (spectating), out of the game
      window or in the game's menu ("away"), or away from the keys (no key or mouse for
      lc_study_afk seconds, 90, set in the study's window; the quiet time before it was noticed
      is taken out too).

      Kept out of the baselines: a job that failed or was abandoned (it may have been a glitch;
      the owner: "I wouldn't want that data to poison the data set"), and anything the player
      strikes: "Strike the last job" (one that finished but went wrong) or "Strike the last
      5 minutes". It all stays in the log, marked; the report leaves it out and says so.

      The lines go to the player's own computer as they play (cl_livingcity_study.lua), saved in
      garrysmod/data/livingcity/study/<date>_<time>_<faction>/ as log.txt, and report.txt when
      the study is stopped. Nothing is kept on the server.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_study")     -- server > the player: "start", "lines", "report", "end", "status"
util.AddNetworkString("lc_study_act") -- the player > server: start, stop, discard, strike_job, strike_min, input

-- (seconds with no key or mouse before the player counts as away from the keys: lc_study_afk on their own computer, 90)
local function AfkAfter(p)
    return math.max(20, IsValid(p) and p.GetInfoNum and p:GetInfoNum("lc_study_afk", 90) or 90)
end

local S -- the study under way
local MAX_LINES = 60000

function LC.Studying() return S end

local function Now() return CurTime() - S.t0 end

local function Add(kind, text, at)
    if not S or S.total >= MAX_LINES then return end
    S.total = S.total + 1
    text = tostring(text)
    if #text > 600 then text = string.sub(text, 1, 600) .. "..." end
    S.out[#S.out + 1] = { at or Now(), kind, text }
end

-- Something that happened, kept for the report as well as the log.
local function Event(name, text)
    if not S then return end
    S.events[#S.events + 1] = { t = Now(), name = name, key = S.key, zone = S.zone, quest = S.quest and S.quest.n or nil, paused = S.pause ~= nil, cell = S.cell }
    Add("event", name .. (text and text ~= "" and (": " .. text) or ""))
end

------------------------------------------------------------------------
-- Who, where, in what
------------------------------------------------------------------------

local GROUND = { combine = "combine", prison = "combine", rebel = "resistance" } -- whose ground a kind of zone is
local NOT_PLACES = { jogroute = true, waymark = true, dream = true } -- (points that say nothing about what's done there)

local function Who(p)
    local fac = p:GetNW2String("lcf_faction", "")
    if fac == "" then fac = "citizen" end
    local r = LCF and LCF.RankOf and LCF.RankOf(p)
    local rank = r and (r.name or r.id) or nil
    return fac, rank and tostring(rank) or "?"
end

-- Where they stand: the kind of zone, whose ground that is to them, and the nearest thing placed
-- with the editor (a ration line, a checkpoint, a workplace...) within 350 units.
local function Where(p, fac)
    local pos = p:GetPos()
    local z = LC.ZoneAt and LC.ZoneAt(pos)
    local kind = z and tostring(z.kind) or "no zone"
    local side = GROUND[kind]
    if not side and LC.CombineZoneAt and LC.CombineZoneAt(pos) then side = "combine" end
    if not side and LC.RebelZoneAt and LC.RebelZoneAt(pos) then side = "resistance" end
    local mine = (fac == "cp" or fac == "admin") and "combine" or ((fac == "resistance" or fac == "vort") and "resistance") or nil
    local ground = "open ground"
    if side then
        if mine == side then ground = "own ground"
        elseif mine then ground = "the other side's ground"
        else ground = side == "combine" and "the Combine's ground" or "the Resistance's ground" end
    end
    local by, best = nil, 350 * 350
    for _, pt in ipairs(LC.Points or {}) do
        if pt.pos and pt.kind and not NOT_PLACES[pt.kind] then
            local d = pt.pos:DistToSqr(pos)
            if d < best then by, best = tostring(pt.kind), d end
        end
    end
    return kind, ground, by
end

local PAUSE_TOOLS = { gmod_tool = "the editor's tool", weapon_physgun = "the physics gun", gmod_camera = "the camera" }

local function Paused(p)
    if S.away then return "away (out of the game window)" end
    if S.afk then return "away from the keys" end
    if p.GetMoveType and MOVETYPE_NOCLIP and p:GetMoveType() == MOVETYPE_NOCLIP then return "flying (noclip)" end
    local w = p.GetActiveWeapon and p:GetActiveWeapon()
    local tool = IsValid(w) and PAUSE_TOOLS[w:GetClass()]
    if tool then return "holding " .. tool end
    if p.GetObserverMode and (p:GetObserverMode() or 0) ~= 0 and p:Alive() then return "watching (spectating)" end
    return nil
end

local function Mode(p)
    if not p:Alive() then return "dead" end
    if p.InVehicle and p:InVehicle() then return "seated" end
    local v = p.GetVelocity and p:GetVelocity() or Vector(0, 0, 0)
    local speed = math.sqrt(v.x * v.x + v.y * v.y)
    local crouch = p.Crouching and p:Crouching()
    if speed < 8 then return crouch and "crouched still" or "still" end
    if crouch then return "crouch-walking" end
    local walk = p.GetWalkSpeed and p:GetWalkSpeed() or 160
    return speed <= walk + 15 and "walking" or "running"
end

-- Security in sight and people about (the city's own NPCs).
local function Around(p)
    local pos = p:GetPos()
    local secD, secSeen, people, security = nil, false, 0, 0
    for npc, st in pairs(LC.NPCs or {}) do
        if IsValid(npc) and istable(st) then
            local d = pos:Distance(npc:GetPos())
            if d < 900 then
                local sec = st.role == "cop" or st.role == "soldier"
                if sec then
                    local seen = d < 700 and (not p.IsLineOfSightClear or p:IsLineOfSightClear(npc))
                    if seen then
                        security = security + 1
                        if not secD or d < secD then secD = d end
                        secSeen = true
                    end
                elseif d < 500 then
                    people = people + 1
                end
            end
        end
    end
    return secD, secSeen, people, security
end

------------------------------------------------------------------------
-- Sending it to the player
------------------------------------------------------------------------

local function SendLines(kind, lines, info)
    local p = S and S.ply
    if not IsValid(p) then return end
    local from = 1
    repeat
        local bytes, to = 0, from - 1
        while to < #lines and to - from < 80 and bytes < 30000 do
            to = to + 1
            bytes = bytes + #lines[to][3] + 24
        end
        net.Start("lc_study")
        net.WriteString(kind)
        net.WriteString(info or "")
        net.WriteUInt(math.max(0, to - from + 1), 16)
        for i = from, to do
            net.WriteFloat(lines[i][1])
            net.WriteString(lines[i][2])
            net.WriteString(lines[i][3])
        end
        net.Send(p)
        from = to + 1
        info = nil
    until from > #lines
end

local function Flush()
    if not S or #S.out == 0 then return end
    local lines = S.out
    S.out = {}
    SendLines("lines", lines)
end

local function Counted()
    local n = 0
    for _, s in ipairs(S.samples) do if not s.pause then n = n + 1 end end
    return n
end

local function Status(p, note)
    if not IsValid(p) then return end
    local t = { on = S ~= nil and S.ply == p, note = note }
    if t.on then
        t.pause = S.pause
        t.counted = Counted()
        t.total = math.floor(Now())
        t.who = S.key
        t.where = S.zone
        t.struck = #S.struck
        t.quest = S.quest and S.quest.title or nil
        t.lastQuest = S.quests[#S.quests] and S.quests[#S.quests].title or nil
    end
    net.Start("lc_study")
    net.WriteString("status")
    net.WriteString(util.TableToJSON(t) or "{}")
    net.WriteUInt(0, 16)
    net.Send(p)
end

------------------------------------------------------------------------
-- The report
------------------------------------------------------------------------

local function Secs(n)
    n = math.floor(n + 0.5)
    if n >= 3600 then return string.format("%dh %02dm", math.floor(n / 3600), math.floor(n % 3600 / 60)) end
    if n >= 60 then return string.format("%dm %02ds", math.floor(n / 60), n % 60) end
    return n .. "s"
end
local function Pct(a, b) return b > 0 and (math.floor(a / b * 100 + 0.5) .. "%") or "0%" end
local function Median(list)
    if #list == 0 then return 0 end
    table.sort(list)
    return list[math.ceil(#list / 2)]
end
local function Bump(t, k, n) t[k] = (t[k] or 0) + (n or 1) end
local function Top(t, max)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) if t[a] ~= t[b] then return t[a] > t[b] end return tostring(a) < tostring(b) end)
    local out = {}
    for i = 1, math.min(max or #keys, #keys) do out[i] = keys[i] end
    return out
end
local function Shares(t, total, max)
    local parts = {}
    for _, k in ipairs(Top(t, max)) do parts[#parts + 1] = tostring(k) .. " " .. Pct(t[k], total) end
    return table.concat(parts, ", ")
end

-- Is this second kept out (struck, or inside a job that failed or was abandoned)?
local function Barred(t, bars)
    for _, b in ipairs(bars) do if t >= b[1] and t <= b[2] then return b[3] end end
    return nil
end

local function Report(why)
    local o = {}
    local function P(s) o[#o + 1] = { 0, "report", s } end
    local now = Now()
    local bars = {}
    for _, b in ipairs(S.struck) do bars[#bars + 1] = { b.from, b.to, "struck" } end
    for _, q in ipairs(S.quests) do
        if q.outcome == "failed" or q.outcome == "abandoned" then bars[#bars + 1] = { q.from, q.to or now, "a job that " .. (q.outcome == "failed" and "failed" or "was abandoned") } end
    end

    local total, paused, barred, kept = #S.samples, {}, {}, 0
    local groups, order = {}, {}
    for _, s in ipairs(S.samples) do
        local bar = Barred(s.t, bars)
        if s.pause then Bump(paused, s.pause)
        elseif bar then Bump(barred, bar)
        else
            kept = kept + 1
            local gk = s.ctx .. " | " .. s.key
            local g = groups[gk]
            if not g then
                g = { ctx = s.ctx, key = s.key, n = 0, zones = {}, modes = {}, phases = {}, holds = {}, secN = 0, crowd = 0, onJob = 0 }
                groups[gk] = g
                order[#order + 1] = gk
            end
            g.n = g.n + 1
            Bump(g.modes, s.mode) Bump(g.phases, s.phase) Bump(g.holds, s.hold)
            if s.sec then g.secN = g.secN + 1 end
            if s.quest then g.onJob = g.onJob + 1 end
            g.crowd = g.crowd + (s.people or 0)
            local z = g.zones[s.zone]
            if not z then z = { n = 0, modes = {}, visits = {}, secN = 0, onJob = 0, phases = {} } g.zones[s.zone] = z end
            z.n = z.n + 1
            Bump(z.modes, s.mode) Bump(z.phases, s.phase)
            if s.sec then z.secN = z.secN + 1 end
            if s.quest then z.onJob = z.onJob + 1 end
            -- (a visit: seconds in a row in the same zone)
            if z.lastT and s.t - z.lastT < 2.5 then z.visits[#z.visits] = z.visits[#z.visits] + 1 else z.visits[#z.visits + 1] = 1 end
            z.lastT = s.t
        end
    end

    P("LIVING CITY: A PLAY STUDY")
    P(string.format("Player %s, map %s. %s recorded, %s counted. Ended: %s.", S.nick, game.GetMap and game.GetMap() or "?", Secs(total), Secs(kept), tostring(why)))
    P("")
    P("How to read this (for the code chat): one player's real play, as a model for how the city's people might behave. Every table is")
    P("for one WHO (faction and rank) in one WHAT (the city, or a dream) and split by WHERE (the kind of zone, and whose ground it is")
    P("to that player). Never merge rows across factions: a Rebel on the Combine's ground and a unit there are different things.")
    P("Seconds are counted only while the player was really playing (see NOT COUNTED). log.txt has every line behind these numbers.")
    P("")
    P("== NOT COUNTED ==")
    local any = false
    for _, k in ipairs(Top(paused)) do P("  paused, " .. k .. ": " .. Secs(paused[k])) any = true end
    for _, k in ipairs(Top(barred)) do P("  kept out, " .. k .. ": " .. Secs(barred[k])) any = true end
    if not any then P("  nothing: every second counted") end
    for _, b in ipairs(S.struck) do P(string.format("  struck by the player: %.0fs to %.0fs (%s)", b.from, b.to, b.why)) end

    for _, gk in ipairs(order) do
        local g = groups[gk]
        P("")
        P("== " .. string.upper(g.ctx) .. " | " .. g.key .. " (" .. Secs(g.n) .. ") ==")
        P("  moving: " .. Shares(g.modes, g.n))
        P("  time of day: " .. Shares(g.phases, g.n))
        P("  holding: " .. Shares(g.holds, g.n, 6))
        P("  security in sight " .. Pct(g.secN, g.n) .. " of the time; on a job " .. Pct(g.onJob, g.n) .. "; people within 500 units, on average " .. string.format("%.1f", g.crowd / math.max(1, g.n)))
        P("  by place (most time first):")
        local zt = {}
        for k, z in pairs(g.zones) do zt[k] = z.n end
        for _, k in ipairs(Top(zt)) do
            local z = g.zones[k]
            P(string.format("    %s: %s (%s), %d visits, a visit lasts %s (median), longest %s", k, Secs(z.n), Pct(z.n, g.n), #z.visits, Secs(Median(z.visits)), Secs(z.visits[#z.visits] or 0)))
            P("        moving: " .. Shares(z.modes, z.n) .. "; security in sight " .. Pct(z.secN, z.n) .. "; on a job " .. Pct(z.onJob, z.n) .. "; " .. Shares(z.phases, z.n))
        end
    end

    P("")
    P("== JOBS AND STORIES ==")
    if #S.quests == 0 then P("  none taken") end
    for _, q in ipairs(S.quests) do
        local zones, n = {}, 0
        for _, s in ipairs(S.samples) do
            if s.quest == q.n and not s.pause then Bump(zones, s.zone) n = n + 1 end
        end
        local out = q.outcome or "still going when the study ended"
        local keptOut = q.struck and " [STRUCK by the player: not in the tables]" or ((q.outcome == "failed" or q.outcome == "abandoned") and " [kept out of the tables]" or "")
        P(string.format("  [%.0fs] \"%s\" [%s] from %s, as %s: %s, %s of play%s", q.from, q.title, q.id, q.board, q.key, out, Secs(n), keptOut))
        if n > 0 then P("        where: " .. Shares(zones, n, 4)) end
        for _, st in ipairs(q.stages) do P(string.format("        stage %s (%s): %s", tostring(st.i), tostring(st.kind), Secs((st.to or now) - st.from))) end
    end

    P("")
    P("== MEETINGS WITH SECURITY (a unit or soldier in sight, within 700 units) ==")
    local encs = {}
    for _, e in ipairs(S.encounters) do if not e.paused and not Barred(e.from, bars) then encs[#encs + 1] = e end end
    if #encs == 0 then P("  none") end
    local byKey = {}
    for _, e in ipairs(encs) do
        local k = e.key .. " | " .. e.zone
        byKey[k] = byKey[k] or {}
        table.insert(byKey[k], e)
    end
    local ek = {}
    for k in pairs(byKey) do ek[#ek + 1] = k end
    table.sort(ek)
    for _, k in ipairs(ek) do
        local list, did, lens, closest = byKey[k], {}, {}, {}
        for _, e in ipairs(list) do Bump(did, e.did) lens[#lens + 1] = e.secs closest[#closest + 1] = e.closest end
        P(string.format("  %s: %d meetings, lasting %s (median), closest %d units (median); the player: %s", k, #list, Secs(Median(lens)), Median(closest), Shares(did, #list)))
    end
    for _, e in ipairs(encs) do
        P(string.format("    [%.0fs] %s, %s: %s, from %d to %d units (closest %d), %s; %s", e.from, e.key, e.zone, Secs(e.secs), e.first, e.last, e.closest, e.did, Shares(e.modes, e.secs)))
    end

    P("")
    P("== WHERE ON THE MAP (the city only; squares of 256 units, named by the map coordinates of their middle) ==")
    P("  Jumping and crouching may be the map's shape (a ledge, a low gap), not a habit: check the spot before making it a behaviour.")
    local cells, jumps, lows, cellN = {}, {}, {}, 0
    for _, s in ipairs(S.samples) do
        if s.cell and not s.pause and not Barred(s.t, bars) then Bump(cells, s.cell) cellN = cellN + 1 end
    end
    for _, e in ipairs(S.events) do
        if e.cell and not e.paused and not Barred(e.t, bars) then
            if e.name == "jumped" then Bump(jumps, e.cell) elseif e.name == "crouched" then Bump(lows, e.cell) end
        end
    end
    local function Spots(title, t, fmt)
        local parts = {}
        for _, k in ipairs(Top(t, 20)) do parts[#parts + 1] = "(" .. k .. ") " .. fmt(t[k]) end
        P("  " .. title .. ": " .. (#parts > 0 and table.concat(parts, ", ") or "none"))
    end
    Spots("most time", cells, function(n) return Secs(n) .. " " .. Pct(n, cellN) end)
    Spots("jumps", jumps, function(n) return "x" .. n end)
    Spots("crouches", lows, function(n) return "x" .. n end)

    P("")
    P("== WHAT HAPPENED, COUNTED (who | where: event xN) ==")
    local ev = {}
    for _, e in ipairs(S.events) do
        if not e.paused and not Barred(e.t, bars) then
            local k = tostring(e.key) .. " | " .. tostring(e.zone)
            ev[k] = ev[k] or {}
            Bump(ev[k], e.name)
        end
    end
    local kk = {}
    for k in pairs(ev) do kk[#kk + 1] = k end
    table.sort(kk)
    if #kk == 0 then P("  nothing") end
    for _, k in ipairs(kk) do
        local parts = {}
        for _, name in ipairs(Top(ev[k], 40)) do parts[#parts + 1] = name .. (ev[k][name] > 1 and (" x" .. ev[k][name]) or "") end
        P("  " .. k .. ": " .. table.concat(parts, ", "))
    end
    return o
end

------------------------------------------------------------------------
-- Starting and stopping
------------------------------------------------------------------------

local HOOKS = {}
local function Hook(name, fn)
    HOOKS[#HOOKS + 1] = name
    hook.Add(name, "LivingCityStudy", function(...)
        if not S then return end
        local ok, err = pcall(fn, ...)
        if not ok and LC.Error then LC.Error("play study", err) end
        -- (never a return value: the study watches, it decides nothing)
    end)
end

local runWas, runMine, callWas, callMine, noticeWas, noticeMine

local function Stop(why, discard)
    local s = S
    if not s then return end
    timer.Remove("LivingCityStudy")
    if IsValid(s.ply) then
        if s.quest then s.quest.to = Now() end
        if s.enc then s.enc = nil end
        if discard then
            net.Start("lc_study") net.WriteString("end") net.WriteString("discard") net.WriteUInt(0, 16) net.Send(s.ply)
        else
            Add("end", why or "stopped")
            pcall(Flush)
            local ok, lines = pcall(Report, why or "stopped")
            if ok then SendLines("report", lines) elseif LC.Error then LC.Error("play study report", lines) end
            net.Start("lc_study") net.WriteString("end") net.WriteString(ok and "" or "no report") net.WriteUInt(0, 16) net.Send(s.ply)
        end
    end
    S = nil
    for _, name in ipairs(HOOKS) do hook.Remove(name, "LivingCityStudy") end
    HOOKS = {}
    -- (put back only what's still ours: anything wrapped over it since stays, and ours does nothing with no study)
    if runMine and hook.Run == runMine then hook.Run = runWas end
    if callMine and hook.Call == callMine then hook.Call = callWas end
    if noticeMine and LC.Notice == noticeMine then LC.Notice = noticeWas end
    runMine, callMine, noticeMine = nil, nil, nil
    if IsValid(s.ply) then Status(s.ply, discard and "discarded" or "saved") end
end
LC.StudyStop = Stop

-- A few words for anything the gamemode passes along with one of its events.
local function Arg(v)
    local tv = type(v)
    if tv == "string" then return #v > 60 and (string.sub(v, 1, 60) .. "...") or v end
    if tv == "number" then return v == math.floor(v) and tostring(v) or string.format("%.1f", v) end
    if tv == "boolean" then return tostring(v) end
    if tv == "table" then
        local name = v.title or v.name or v.id
        return name ~= nil and tostring(name) or nil
    end
    if IsValid(v) then
        if v == S.ply then return nil end
        if v.IsPlayer and v:IsPlayer() then return "a player" end
        local st = LC.NPCs and LC.NPCs[v]
        return (st and st.role and ("a " .. tostring(st.role))) or v:GetClass()
    end
    return nil
end

local QUIET = { LivingCityInventoryChanged = true, LivingCityThought = true, LivingCityStateChanged = true, LivingCityStockLevel = true, LivingCityLedger = true }

-- One of the gamemode's own events went by: if it's about the player, it's something they did or had done to them.
local function Seen(name, ...)
    if not S or type(name) ~= "string" or string.sub(name, 1, 10) ~= "LivingCity" then return end
    if QUIET[name] or S.inSeen then return end
    local head = string.sub(name, 11, 13)
    if head == "Can" or string.sub(head, 1, 2) == "Is" then return end -- (questions, not happenings)
    local p, mine = S.ply, false
    local n = select("#", ...)
    for i = 1, math.min(n, 6) do
        local v = select(i, ...)
        if v == p then mine = true break end
    end
    if not mine then return end
    S.inSeen = true
    local ok = pcall(function(...)
        local short = string.sub(name, 11)
        local now = Now()
        -- (the same thing many times a minute is said once, then counted quietly)
        local h = S.hot[short]
        if not h or now - h.from > 60 then h = { from = now, n = 0 } S.hot[short] = h end
        h.n = h.n + 1
        local parts = {}
        for i = 1, math.min(n, 6) do
            local a = Arg((select(i, ...)))
            if a then parts[#parts + 1] = a end
        end
        if h.n <= 6 then Event(short, table.concat(parts, ", "))
        else S.events[#S.events + 1] = { t = now, name = short, key = S.key, zone = S.zone, quest = S.quest and S.quest.n or nil, paused = S.pause ~= nil } end
    end, ...)
    S.inSeen = nil
    return ok
end

local function QuestEnd(outcome)
    local q = S.quest
    if not q then return end
    q.to = Now()
    q.outcome = q.outcome or outcome
    local st = q.stages[#q.stages]
    if st and not st.to then st.to = q.to end
    Add("job", "over: \"" .. q.title .. "\" " .. tostring(q.outcome) .. " after " .. Secs(q.to - q.from)
        .. ((q.outcome == "failed" or q.outcome == "abandoned") and " (kept out of the baselines)" or ""))
    S.quest = nil
end

local function Tick()
    if not S then return end
    local p = S.ply
    if not IsValid(p) then Stop("the player left") return end
    local ok, err = pcall(function()
        local now = Now()
        S.ticks = S.ticks + 1

        -- away from the keys: the quiet time before it was noticed is taken out too
        local afkAfter = AfkAfter(p)
        local afk = (S.idleFor or 0) >= afkAfter
        if afk and not S.afk then
            for i = #S.samples, 1, -1 do
                local s = S.samples[i]
                if now - s.t > afkAfter then break end
                s.pause = s.pause or "away from the keys"
            end
        end
        S.afk = afk

        local pause = Paused(p)
        if pause ~= S.pause then
            if pause then Add("pause", pause) else Add("pause", "playing again (was: " .. tostring(S.pause) .. ")") end
            S.pause = pause
        end

        -- who, in what, where
        local fac, rank = Who(p)
        local key = fac .. ", " .. rank
        if key ~= S.key then Add("who", key .. (S.key and (" (was " .. S.key .. ")") or "")) S.key = key end
        local ctx = "the city"
        if p.lcDreaming then
            local d = LC.DreamActive
            local id = d and d.ending or "?"
            ctx = "a dream (" .. tostring(id) .. (d and d.test and ", a test" or "") .. ")"
        end
        if ctx ~= S.ctx then Add("what", "in " .. ctx .. (S.ctx and (" (was in " .. S.ctx .. ")") or "")) S.ctx = ctx end
        local kind, ground, by = Where(p, fac)
        local zone = p.lcDreaming and "the dream" or (kind .. " (" .. ground .. ")" .. (by and (", by a " .. by .. " point") or ""))
        if zone ~= S.zone then
            if not pause then Add("place", zone .. (S.zone and (", after " .. Secs(now - (S.zoneAt or now)) .. " in " .. S.zone) or "")) end
            S.zone, S.zoneAt = zone, now
        end
        local phase = (LC.DayPhase and LC.DayPhase() or "?")
        if phase ~= S.phase then Add("time", phase .. (LC.Hour and string.format(" (%.0f h)", LC.Hour()) or "")) S.phase = phase end

        -- the job
        local q = LC.QuestOf and LC.QuestOf[p]
        if S.quest and (not q or q ~= S.quest.q or q.done) then QuestEnd(S.quest.q.done and "ended" or "abandoned") end
        if q and not S.quest and not q.done then
            local rec = { q = q, n = #S.quests + 1, title = tostring(q.title), id = tostring(q.tmpl and q.tmpl.id or "?"), board = tostring(q.board or "?"), from = now, key = key, stages = {} }
            S.quests[#S.quests + 1] = rec
            S.quest = rec
            Add("job", "taken: \"" .. rec.title .. "\" [" .. rec.id .. "] from " .. rec.board .. (q.desc and (": " .. tostring(q.desc)) or ""))
        end
        if S.quest then
            local st = q.stages and q.stages[q.stage]
            local cur = S.quest.stages[#S.quest.stages]
            if not cur or cur.i ~= q.stage then
                if cur then cur.to = now end
                S.quest.stages[#S.quest.stages + 1] = { i = q.stage, kind = st and st.kind or "?", from = now }
                Add("job", "stage " .. tostring(q.stage) .. " (" .. tostring(st and st.kind or "?") .. ")" .. (st and st.text and (": " .. tostring(st.text)) or ""))
            end
        end

        -- how they move, what they hold, who's about
        local mode = Mode(p)
        local pos = p:GetPos()
        S.cell = nil
        if not p.lcDreaming then S.cell = string.format("%d %d %d", math.floor(pos.x / 256) * 256 + 128, math.floor(pos.y / 256) * 256 + 128, math.floor(pos.z / 128) * 128 + 64) end
        if not pause then
            -- (the trail: where on the map, every five seconds on the move, for laying over the map itself one day)
            if (not S.trailPos or pos:Distance(S.trailPos) > 100) and now - (S.trailAt or -9) >= 5 then
                Add("at", string.format("%d %d %d (%s)", pos.x, pos.y, pos.z, mode))
                S.trailPos, S.trailAt = pos, now
            end
            local low = mode == "crouched still" or mode == "crouch-walking"
            if low and not S.low then Event("crouched", string.format("at %d %d %d", pos.x, pos.y, pos.z)) end
            S.low = low
        end
        local w = p.GetActiveWeapon and p:GetActiveWeapon()
        local hold = IsValid(w) and w:GetClass() or "nothing"
        if hold ~= S.hold then
            if S.hold and not pause then Add("hold", hold) end
            S.hold = hold
        end
        local secD, secSeen, people, security = Around(p)
        S.samples[#S.samples + 1] = { t = now, pause = pause, ctx = ctx, key = key, zone = zone, mode = mode, hold = hold, phase = phase,
            quest = S.quest and S.quest.n or nil, sec = secSeen or nil, people = people, cell = S.cell }

        -- a meeting with security: from first sight until four seconds out of it
        local e = S.enc
        if secSeen and not pause and not p.lcDreaming then
            if not e then
                e = { from = now, first = math.floor(secD), closest = math.floor(secD), last = math.floor(secD), key = key, zone = zone, modes = {}, secs = 0, units = security }
                S.enc = e
                Add("meet", string.format("security in sight: %d of them, the nearest %d units off; the player is %s in %s", security, math.floor(secD), mode, zone))
            end
            e.lastSeen, e.last = now, math.floor(secD)
            e.closest = math.min(e.closest, e.last)
            e.secs = e.secs + 1
            Bump(e.modes, mode)
        elseif e and (pause or now - (e.lastSeen or now) >= 4) then
            S.enc = nil
            local change = e.last - e.first
            local ran = (e.modes.running or 0) > e.secs * 0.4
            e.did = (change > 150 and (ran and "ran off" or "moved away")) or (change < -150 and "closed in")
                or ((e.modes["crouched still"] or 0) + (e.modes["crouch-walking"] or 0) > e.secs * 0.4 and "kept low")
                or ((e.modes.still or 0) > e.secs * 0.6 and "stood their ground") or "carried on"
            e.paused = pause ~= nil
            S.encounters[#S.encounters + 1] = e
            Add("meet", string.format("over after %s: from %d to %d units (closest %d); the player %s", Secs(e.secs), e.first, e.last, e.closest, e.did))
        end

        -- what's networked about them (their job, standing, being wanted...), as it changes
        if S.ticks % 3 == 0 and p.GetNW2VarTable then
            local t = p:GetNW2VarTable()
            if istable(t) then
                local parts = {}
                for k, v in pairs(t) do
                    if istable(v) and v.value ~= nil then v = v.value end
                    local tv = type(v)
                    if type(k) == "string" and string.sub(k, 1, 2) == "lc" and (tv == "string" or tv == "boolean" or tv == "number") then
                        local was = S.nw[k]
                        if was ~= v then
                            S.nw[k] = v
                            local n = (S.nwHot[k] or 0) + 1
                            S.nwHot[k] = n
                            if not S.nwFirst and n <= 8 and (tv ~= "number" or n <= 3) then parts[#parts + 1] = k .. " = " .. tostring(v) end
                        end
                    end
                end
                if S.nwFirst then
                    -- (to begin with: only the words, which say who they are)
                    for k, v in pairs(S.nw) do if type(v) == "string" and v ~= "" and #v < 60 then parts[#parts + 1] = k .. " = " .. v end end
                    S.nwFirst = nil
                end
                table.sort(parts)
                local line = ""
                for _, s in ipairs(parts) do
                    if #line + #s > 480 then Add("about", line) line = "" end
                    line = line .. (#line > 0 and "; " or "") .. s
                end
                if #line > 0 then Add("about", line) end
            end
        end
    end)
    if not ok then
        S.errors = (S.errors or 0) + 1
        if S.errors <= 3 then Add("study", "couldn't look (" .. tostring(err) .. ")") end
    end
    if S and S.ticks % 2 == 0 then pcall(Flush) end
    if S and S.ticks % 5 == 0 then Status(S.ply) end
end

function LC.StudyStart(p)
    if not IsValid(p) then return false, "Nobody to study." end
    if not (LC.CanEdit and LC.CanEdit(p)) then return false, "Only those who may use the Miscount Editor can be studied." end
    if S then return false, S.ply == p and "The study is already on." or "Someone else is being studied." end
    S = { ply = p, nick = p:Nick(), t0 = CurTime(), out = {}, total = 0, samples = {}, events = {}, quests = {}, encounters = {}, struck = {},
        hot = {}, nw = {}, nwHot = {}, nwFirst = true, ticks = 0, idleFor = 0 }
    local fac = Who(p)
    net.Start("lc_study")
    net.WriteString("start")
    net.WriteString(util.TableToJSON({ faction = fac, nick = S.nick, map = game.GetMap and game.GetMap() or "?", t0 = S.t0, afk = AfkAfter(p) }) or "{}")
    net.WriteUInt(0, 16)
    net.Send(p)
    Add("start", "the play study begins")

    Hook("PlayerUse", function(ply, e)
        if ply ~= S.ply or not IsValid(e) or S.pause then return end
        local now = CurTime()
        if S.usedEnt == e and now - (S.usedAt or 0) < 2 then S.usedAt = now return end
        S.usedEnt, S.usedAt = e, now
        Event("used " .. (Arg(e) or e:GetClass()))
    end)
    Hook("KeyPress", function(ply, key)
        if ply ~= S.ply or S.pause or not IN_JUMP or key ~= IN_JUMP then return end
        local now = CurTime()
        if now - (S.jumpAt or 0) < 0.4 then return end
        S.jumpAt = now
        local pos = ply:GetPos()
        Event("jumped", string.format("at %d %d %d", pos.x, pos.y, pos.z))
    end)
    Hook("PlayerSay", function(ply, text)
        if ply ~= S.ply then return end
        text = tostring(text)
        local c = string.sub(text, 1, 1)
        if c == "/" or c == "!" then Event("command " .. (string.match(text, "^(%S+)") or text))
        else Event("said something", text) end
    end)
    Hook("EntityTakeDamage", function(e, dmg)
        if not dmg or S.pause then return end
        local by = dmg.GetAttacker and dmg:GetAttacker()
        local now = CurTime()
        if e == S.ply then
            if now - (S.hurtAt or 0) < 3 then return end
            S.hurtAt = now
            Event("was hit by " .. (IsValid(by) and by ~= e and (Arg(by) or by:GetClass()) or "something"))
        elseif by == S.ply and IsValid(e) and (e:IsNPC() or e:IsPlayer()) then
            if now - (S.hitAt or 0) < 3 then return end
            S.hitAt = now
            local w = S.ply.GetActiveWeapon and S.ply:GetActiveWeapon()
            Event("attacked " .. (Arg(e) or e:GetClass()), IsValid(w) and ("with " .. w:GetClass()) or nil)
        end
    end)
    Hook("OnNPCKilled", function(npc, by)
        if by == S.ply and IsValid(npc) and not S.pause then Event("killed " .. (Arg(npc) or npc:GetClass())) end
    end)
    Hook("PlayerDeath", function(ply, _, by)
        if ply == S.ply then Event("died", IsValid(by) and by ~= ply and ("to " .. (Arg(by) or by:GetClass())) or nil) end
    end)
    Hook("PlayerDisconnected", function(ply)
        if ply == S.ply then Stop("the player left") end
    end)
    Hook("LivingCityQuestComplete", function(ply, q)
        if ply == S.ply and S.quest and S.quest.q == q then S.quest.outcome = "complete" end
    end)
    Hook("LivingCityQuestFailed", function(ply, q)
        if ply == S.ply and S.quest and S.quest.q == q then S.quest.outcome = "failed" end
    end)

    -- The gamemode's own events, and what the player is told.
    runWas, callWas = hook.Run, hook.Call
    runMine = function(name, ...)
        if S then Seen(name, ...) end
        return runWas(name, ...)
    end
    callMine = function(name, gm, ...)
        if S then Seen(name, ...) end
        return callWas(name, gm, ...)
    end
    hook.Run, hook.Call = runMine, callMine
    noticeWas = LC.Notice
    if noticeWas then
        noticeMine = function(ply, kind, title, text, secs, ...)
            if S and not S.pause and (ply == S.ply or (istable(ply) and table.HasValue(ply, S.ply))) then
                pcall(function()
                    local line = "[" .. tostring(kind) .. "] " .. tostring(title) .. ": " .. tostring(text)
                    local now = CurTime()
                    if S.toldLine ~= line or now - (S.toldAt or 0) > 10 then Add("told", line) end
                    S.toldLine, S.toldAt = line, now
                end)
            end
            return noticeWas(ply, kind, title, text, secs, ...)
        end
        LC.Notice = noticeMine
    end

    timer.Create("LivingCityStudy", 1, 0, Tick)
    if LC.Log then LC.Log("info", "Play study: " .. S.nick .. " began") end
    Status(p, "started")
    return true
end

-- Strike a stretch of it: it stays in the log, marked, and the report leaves it out.
function LC.StudyStrike(p, what, arg)
    if not S or S.ply ~= p then return false, "The study isn't on." end
    local now = Now()
    if what == "job" then
        local q = S.quests[#S.quests]
        if not q then return false, "No job has been taken in this study." end
        if q.struck then return false, "\"" .. q.title .. "\" is already struck." end
        q.struck = true
        S.struck[#S.struck + 1] = { from = q.from, to = q.to or now, why = "the job \"" .. q.title .. "\"", quest = q }
        Add("strike", "the job \"" .. q.title .. "\" is struck from the study (" .. Secs((q.to or now) - q.from) .. ")")
        return true, "Struck: \"" .. q.title .. "\"."
    end
    local mins = math.Clamp(math.floor(tonumber(arg) or 5), 1, 60)
    local from = math.max(0, now - mins * 60)
    S.struck[#S.struck + 1] = { from = from, to = now, why = "the last " .. mins .. " minutes" }
    Add("strike", "the last " .. mins .. " minutes are struck from the study")
    return true, "Struck: the last " .. mins .. " minutes."
end

local function Notice(p, kind, text)
    if LC.Notice then LC.Notice(p, kind, "Play study", text, 7) elseif p.ChatPrint then p:ChatPrint("Play study: " .. text) end
end

net.Receive("lc_study_act", function(_, p)
    if not IsValid(p) then return end
    local what, arg = net.ReadString(), net.ReadString()
    if what == "input" then
        if S and S.ply == p then
            local focus, idle = string.match(tostring(arg), "^(%d)|(%d+)")
            S.away = focus == "0"
            S.idleFor = tonumber(idle) or 0
        end
        return
    end
    if not (LC.CanEdit and LC.CanEdit(p)) then Notice(p, "warn", "Only those who may use the Miscount Editor can be studied.") return end
    if what == "status" then Status(p) return end
    if what == "start" then
        local ok, why = LC.StudyStart(p)
        if ok then Notice(p, "info", "On. Play as you mean the city's people to behave. It pauses by itself while you fly, use the editor, or are away. Stop it from F4 > Factions > Admin: play study.")
        else Notice(p, "warn", tostring(why)) end
        return
    end
    if not S or S.ply ~= p then Notice(p, "warn", "The study isn't on.") Status(p) return end
    if what == "stop" then Stop("stopped by the player")
    elseif what == "discard" then Stop("discarded", true) Notice(p, "info", "Discarded: nothing of this session is kept.")
    elseif what == "strike_job" or what == "strike_min" then
        local ok, why = LC.StudyStrike(p, what == "strike_job" and "job" or "min", arg)
        Notice(p, ok and "info" or "warn", tostring(why))
        Status(p)
    end
end)
